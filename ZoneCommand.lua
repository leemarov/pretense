
ZoneCommand = {}
do
	ZoneCommand.currentZoneIndex = 1000
	ZoneCommand.allZones = {}
	ZoneCommand.buildSpeed = Config.buildSpeed
	ZoneCommand.supplyBuildSpeed = Config.supplyBuildSpeed
	ZoneCommand.missionValidChance = 0.9
	ZoneCommand.missionBuildSpeedReduction = Config.missionBuildSpeedReduction
	ZoneCommand.revealTime = 0
	ZoneCommand.staticRegistry = {}

	ZoneCommand.modes = {
		normal = 'normal',
		supply = 'supply',
		export = 'export'
	}
	
	ZoneCommand.productTypes = {
		upgrade = 'upgrade',
		mission = 'mission',
		defense = 'defense'
	}
	
	ZoneCommand.missionTypes = {
		supply_air = 'supply_air',
		supply_convoy = 'supply_convoy',
		cas = 'cas',
		cas_helo = 'cas_helo',
		strike = 'strike',
		patrol = 'patrol',
		sead = 'sead',
		assault = 'assault',
		bai = 'bai',
		supply_transfer = 'supply_transfer',
		awacs = 'awacs',
		tanker = 'tanker'
	}
	
	function ZoneCommand:new(zonename)
		local obj = {}
		obj.name = zonename
		obj.side = 0
		obj.resource = 0
		obj.resourceChange = 0
		obj.maxResource = 20000
		obj.spendTreshold = 5000
		obj.keepActive = false
		obj.boostScale = 1.0
		obj.extraBuildResources = 0
		obj.reservedMissions = {}
		obj.isHeloSpawn = false
		obj.isPlaneSpawn = false
		obj.spawnSurface = nil
		
		obj.zone = CustomZone:getByName(zonename)
		obj.products = {}
		obj.mode = 'normal' 
		--[[
			normal: buys whatever it can
			supply: buys only supply missions
			export: supply mode, but also sells all defense groups from the zone
		]]--
		obj.index = ZoneCommand.currentZoneIndex
		ZoneCommand.currentZoneIndex = ZoneCommand.currentZoneIndex + 1
		
		obj.built = {}
		obj.income = 0
		
		--group restrictions
		obj.spawns = {}
		for i,v in pairs(mist.DBs.groupsByName) do
			if v.units[1].skill == 'Client' then
				local zn = obj.zone
				local pos3d = {
					x = v.units[1].point.x,
					y = 0,
					z = v.units[1].point.y
				}
				
				if zn and zn:isInside(pos3d) then
					local coa = 0
					if v.coalition=='blue' then
						coa = 2
					elseif v.coalition=='red' then
						coa = 1
					end
					
					table.insert(obj.spawns, {name=i, side=coa})
				end
			end
		end
		
		--draw graphics
		local color = {0.7,0.7,0.7,0.3}
		if obj.side == 1 then
			color = {1,0,0,0.3}
		elseif obj.side == 2 then
			color = {0,0,1,0.3}
		end
		
		obj.zone:draw(obj.index, color, color)
		
		local point = obj.zone.point

		if obj.zone:isCircle() then
			point = {
				x = obj.zone.point.x,
				y = obj.zone.point.y,
				z = obj.zone.point.z + obj.zone.radius
			}
		elseif obj.zone:isQuad() then
			local largestZ = obj.zone.vertices[1].z
			local largestX = obj.zone.vertices[1].x
			for i=2,4,1 do
				if obj.zone.vertices[i].z > largestZ then
					largestZ = obj.zone.vertices[i].z
					largestX = obj.zone.vertices[i].x
				end
			end
			
			point = {
				x = largestX,
				y = obj.zone.point.y,
				z = largestZ
			}
		end
		
		--trigger.action.textToAll(1,1000+obj.index,point, {0,0,0,0.8}, {1,1,1,0.5}, 15, true, '')
		--trigger.action.textToAll(2,2000+obj.index,point, {0,0,0,0.8}, {1,1,1,0.5}, 15, true, '')
		trigger.action.textToAll(-1,2000+obj.index,point, {0,0,0,0.8}, {1,1,1,0.5}, 15, true, '') --show blue to all
		setmetatable(obj, self)
		self.__index = self
		
		obj:refreshText()
		obj:start()
		obj:refreshSpawnBlocking()
		ZoneCommand.allZones[obj.name] = obj
		return obj
	end
	
	function ZoneCommand:refreshSpawnBlocking()
		for _,v in ipairs(self.spawns) do
			local isDifferentSide = v.side ~= self.side
			local noResources = self.resource < Config.zoneSpawnCost

			trigger.action.setUserFlag(v.name, isDifferentSide or noResources)
		end
	end
	
	function ZoneCommand.setNeighbours()
		local conManager = DependencyManager.get("ConnectionManager")
		for name,zone in pairs(ZoneCommand.allZones) do
			local neighbours = conManager:getConnectionsOfZone(name)
			zone.neighbours = {}
			for _,zname in ipairs(neighbours) do
				zone.neighbours[zname] = ZoneCommand.getZoneByName(zname)
			end
		end
	end
	
	function ZoneCommand.getZoneByName(name)
		if not name then return nil end
		return ZoneCommand.allZones[name]
	end
	
	function ZoneCommand.getAllZones()
		return ZoneCommand.allZones
	end
	
	function ZoneCommand.getZoneOfUnit(unitname)
		local un = Unit.getByName(unitname)
		
		if not un then 
			return nil
		end
		
		for i,v in pairs(ZoneCommand.allZones) do
			if Utils.isInZone(un, i) then
				return v
			end
		end
		
		return nil
	end
	
	function ZoneCommand.getZoneOfWeapon(weapon)
		if not weapon then 
			return nil
		end
		
		for i,v in pairs(ZoneCommand.allZones) do
			if Utils.isInZone(weapon, i) then
				return v
			end
		end
		
		return nil
	end

	function ZoneCommand.getClosestZoneToPoint(point, side)
		local minDist = 9999999
		local closest = nil
		for i,v in pairs(ZoneCommand.allZones) do
			if not side or side == v.side then
				local d = mist.utils.get2DDist(v.zone.point, point)
				if d < minDist then
					minDist = d
					closest = v
				end
			end
		end
		
		return closest, minDist
	end
	
	function ZoneCommand.getZoneOfPoint(point)
		for i,v in pairs(ZoneCommand.allZones) do
			local z = CustomZone:getByName(i)
			if z and z:isInside(point) then
				return v
			end
		end
		
		return nil
	end

	function ZoneCommand:boostProduction(amount)
		self.extraBuildResources = self.extraBuildResources + amount
		env.info('ZoneCommand:boostProduction - '..self.name..' production boosted by '..amount..' to a total of '..self.extraBuildResources)
	end

	function ZoneCommand:sabotage(explosionSize, sourcePoint)
		local minDist = 99999999
		local closest = nil
		for i,v in pairs(self.built) do
			if v.type == 'upgrade' then
				local st = StaticObject.getByName(v.name)
				if not st then st = Group.getByName(v.name) end
				local pos = st:getPoint()

				local d = mist.utils.get2DDist(pos, sourcePoint)
				if d < minDist then
					minDist = d;
					closest = pos
				end
			end
		end

		if closest then
			trigger.action.explosion(closest, explosionSize)
			env.info('ZoneCommand:sabotage - Structure has been sabotaged at '..self.name)
		end

		local damagedResources = math.random(2000,5000)
		self:removeResource(damagedResources)
		self:refreshText()
	end
	
	function ZoneCommand:refreshText()
		local build = ''
		if self.currentBuild then
			local job = ''
			local display = self.currentBuild.product.display
			if self.currentBuild.product.type == 'upgrade' then
				job = display
			elseif self.currentBuild.product.type == 'defense' then
				if self.currentBuild.isRepair then
					job = display..' (repair)'
				else
					job = display
				end
			elseif self.currentBuild.product.type == 'mission' then
				job = display
			end
			
			build = '\n['..job..' '..math.min(math.floor((self.currentBuild.progress/self.currentBuild.product.cost)*100),100)..'%]'
		end

		local mBuild = ''
		if self.currentMissionBuild then
			local job = ''
			local display = self.currentMissionBuild.product.display
			job = display
			
			mBuild = '\n['..job..' '..math.min(math.floor((self.currentMissionBuild.progress/self.currentMissionBuild.product.cost)*100),100)..'%]'
		end
		
		local status=''
		if self.side ~= 0 and self:criticalOnSupplies() then
			status = '(!)'
		end

		local color = {0.3,0.3,0.3,1}
		if self.side == 1 then
			color = {0.7,0,0,1}
		elseif self.side == 2 then
			color = {0,0,0.7,1}
		end

		--trigger.action.setMarkupColor(1000+self.index, color)
		trigger.action.setMarkupColor(2000+self.index, color)

		local label = '['..self.resource..'/'..self.maxResource..']'..status..build..mBuild

		if self.side == 1 then
			--trigger.action.setMarkupText(1000+self.index, self.name..label)

			if self.revealTime > 0 then
				trigger.action.setMarkupText(2000+self.index, self.name..label)
			else
				trigger.action.setMarkupText(2000+self.index, self.name)
			end
		elseif self.side == 2 then
			--if self.revealTime > 0 then
			--	trigger.action.setMarkupText(1000+self.index, self.name..label)
			--else
			--	trigger.action.setMarkupText(1000+self.index, self.name)
			--end
			trigger.action.setMarkupText(2000+self.index, self.name..label)
		elseif self.side == 0 then
			--trigger.action.setMarkupText(1000+self.index, ' '..self.name..' ')
			trigger.action.setMarkupText(2000+self.index, ' '..self.name..' ')
		end
	end
	
	function ZoneCommand:setSide(side)
		self.side = side
		self:refreshSpawnBlocking()

		if side == 0 then
			self.revealTime = 0
		end

		local color = {0.7,0.7,0.7,0.3}
		if self.side==1 then
			color = {1,0,0,0.3}
		elseif self.side==2 then
			color = {0,0,1,0.3}
		end
		
		trigger.action.setMarkupColorFill(self.index, color)
		trigger.action.setMarkupColor(self.index, color)
		trigger.action.setMarkupTypeLine(self.index, 1)

		if self.side == 2 and (self.isHeloSpawn or self.isPlaneSpawn) then
			trigger.action.setMarkupTypeLine(self.index, 2)
			trigger.action.setMarkupColor(self.index, {0,1,0,1})
		end

		self:refreshText()

		if self.airbaseName then
			local ab = Airbase.getByName(self.airbaseName)
			if ab then
				if ab:autoCaptureIsOn() then ab:autoCapture(false) end
				ab:setCoalition(self.side)
			else
				for i=1,10,1 do
					local ab = Airbase.getByName(self.airbaseName..'-'..i)
					if ab then
						if ab:autoCaptureIsOn() then ab:autoCapture(false) end
						ab:setCoalition(self.side)
					end
				end
			end
		end
	end
	
	function ZoneCommand:addResource(amount)
		self.resource = self.resource+amount
		self.resource = math.floor(math.min(self.resource, self.maxResource))
		self:refreshSpawnBlocking()
	end
	
	function ZoneCommand:removeResource(amount)
		self.resource = self.resource-amount
		self.resource = math.floor(math.max(self.resource, 0))
		self:refreshSpawnBlocking()
	end

	function ZoneCommand:reveal(time)
		local revtime = 30
		if time then
			revtime = time
		end

		self.revealTime = 60*revtime
		self:refreshText()
	end
	
	function ZoneCommand:needsSupplies(sendamount)
		return self.resource + sendamount<self.maxResource
	end
	
	function ZoneCommand:criticalOnSupplies()
		return self.resource<=self.spendTreshold
	end
	
	function ZoneCommand:capture(side, isSetup)
		if self.side == 0 then
			if not isSetup then
				local sidetxt = "Neutral"
				if side == 1 then
					sidetxt = "Red"
				elseif side == 2 then
					sidetxt = "Blue"
				end

				trigger.action.outText(self.name.." has been captured by "..sidetxt, 15)
			end
			self:setSide(side)
			local p = self.upgrades[side][1]
			self:instantBuild(p)
			if not isSetup then
				for i,v in pairs(p.products) do
					if v.cost < 0 then
						self:instantBuild(v)
					end
				end
			end
		end
	end
	
	function ZoneCommand:instantBuild(product)
		if product.type == 'defense' or product.type == 'upgrade' then
			env.info('ZoneCommand: instantBuild ['..product.name..']')
			if self.built[product.name] == nil then
				self.zone:spawnGroup(product, self.spawnSurface)
				self.built[product.name] = product
			end
		elseif product.type == 'mission' then
			self:reserveMission(product)
			timer.scheduleFunction(function (param, tme)
				param.context:unReserveMission(param.product)
				if param.context:isMissionValid(param.product) then
					param.context:activateMission(param.product)
				end
			end, {context = self, product = product}, timer.getTime()+math.random(3,10))
		end
	end
	
	function ZoneCommand:fullUpgrade(resourcePercentage)
		if not resourcePercentage then resourcePercentage = 0.25 end
		self.resource = math.floor(self.maxResource*resourcePercentage)
		self:fullBuild()
	end

	function ZoneCommand:fullBuild(useCost)
		if self.side ~= 1 and self.side ~= 2 then return end

		for i,v in ipairs(self.upgrades[self.side]) do
			if useCost then
				local cost = v.cost * useCost
				if self.resource >= cost then
					self:removeResource(cost)
				else
					break
				end
			end

			self:instantBuild(v)

			for i2,v2 in ipairs(v.products) do
				if (v2.type == 'defense' or v2.type=='upgrade') and v2.cost > 0 then
					if useCost then
						local cost = v2.cost * useCost
						if self.resource >= cost then
							self:removeResource(cost)
						else
							break
						end
					end

					self:instantBuild(v2)
				end
			end
		end
	end
	
	function ZoneCommand:start()
		timer.scheduleFunction(function(param, time)
			local self = param.context
			local initialRes = self.resource
			
			--generate income
			if self.side ~= 0 then
				self:addResource(self.income)
			end
			
			--untrack destroyed zone upgrades
			for i,v in pairs(self.built) do
				local u = Group.getByName(i)
				if u and u:getSize() == 0 then
					u:destroy()
					self.built[i] = nil
				end
				
				if not u then
					u = StaticObject.getByName(i)
					if u and u:getLife()<1 then
						u:destroy()
						self.built[i] = nil
					end
				end
				
				if not u then 
					self.built[i] = nil
				end
			end
			
			--upkeep costs for defenses
			for i,v in pairs(self.built) do
				if v.type == 'defense' and v.upkeep then
					v.strikes = v.strikes or 0
					if self.resource >= v.upkeep then
						self:removeResource(v.upkeep)
						v.strikes = 0
					else
						if v.strikes < 6 then
							v.strikes = v.strikes+1
						else
							local u = Group.getByName(i)
							if u then 
								v.strikes = nil
								u:destroy()
								self.built[i] = nil
							end
						end
					end
				elseif v.type == 'upgrade' and v.income then
					self:addResource(v.income)
				end
			end
			
			--check if zone should be reverted to neutral
			local hasUpgrade = false
			for i,v in pairs(self.built) do
				if v.type=='upgrade' then
					hasUpgrade = true
					break
				end
			end
			
			if not hasUpgrade and self.side ~= 0 then
				local sidetxt = "Neutral"
				if self.side == 1 then
					sidetxt = "Red"
				elseif self.side == 2 then
					sidetxt = "Blue"
				end

				trigger.action.outText(sidetxt.." has lost control of "..self.name, 15)

				self:setSide(0)
				self.mode = 'normal'
				self.currentBuild = nil
				self.currentMissionBuild = nil
			end
			
			--sell defenses if export mode
			if self.side ~= 0 and self.mode == 'export' then
				for i,v in pairs(self.built) do
					if v.type=='defense' then
						local g = Group.getByName(i)
						if g then g:destroy() end
						self:addResource(math.floor(v.cost/2))
						self.built[i] = nil
					end
				end
			end
			
			self:verifyBuildValid()
			self:chooseBuild()
			self:progressBuild()
			
			self.resourceChange = self.resource - initialRes
			self:refreshText()
			
			--use revealTime resource
			if self.revealTime > 0 then
				self.revealTime = math.max(0,self.revealTime-10)
			end

			return time+10
		end, {context = self}, timer.getTime()+1)
	end
	
	function ZoneCommand:verifyBuildValid()
		if self.currentBuild then
			if self.side == 0 then
				self.currentBuild = nil 
				env.info('ZoneCommand:verifyBuildValid - stopping build, zone is neutral')
			end

			if self.mode == 'export' or self.mode == 'supply' then 
				if not (self.currentBuild.product.type == ZoneCommand.productTypes.upgrade or 
					self.currentBuild.product.missionType == ZoneCommand.missionTypes.supply_air or 
					self.currentBuild.product.missionType == ZoneCommand.missionTypes.supply_convoy or
					self.currentBuild.product.missionType == ZoneCommand.missionTypes.supply_transfer) then 
					env.info('ZoneCommand:verifyBuildValid - stopping build, mode is '..self.mode..' but mission is not supply')
					self.currentBuild = nil 
				end
			end
			
			if self.currentBuild and (self.currentBuild.product.type == 'defense' or self.currentBuild.product.type == 'mission') then
				for i,v in ipairs(self.upgrades[self.currentBuild.side]) do
					for i2,v2 in ipairs(v.products) do
						if v2.name == self.currentBuild.product.name then
							local g = Group.getByName(v.name)
							if not g then g = StaticObject.getByName(v.name) end
							
							if not g then 
								env.info('ZoneCommand:verifyBuildValid - stopping build, required upgrade no longer exists')
								self.currentBuild = nil 
								break
							end
						end
					end
					
					if not self.currentBuild then
						break
					end
				end
			end
		end

		if self.currentMissionBuild then
			if self.side == 0 then
				self.currentMissionBuild = nil 
				env.info('ZoneCommand:verifyBuildValid - stopping mission build, zone is neutral')
			end

			if (self.mode == 'export' and not self.keepActive) or self.mode == 'supply' then 
				env.info('ZoneCommand:verifyBuildValid - stopping mission build, mode is '..self.mode..'')
				self.currentMissionBuild = nil
			end
			
			if self.currentMissionBuild and self.currentMissionBuild.product.type == 'mission' then
				for i,v in ipairs(self.upgrades[self.currentMissionBuild.side]) do
					for i2,v2 in ipairs(v.products) do
						if v2.name == self.currentMissionBuild.product.name then
							local g = Group.getByName(v.name)
							if not g then g = StaticObject.getByName(v.name) end
							
							if not g then 
								env.info('ZoneCommand:verifyBuildValid - stopping mission build, required upgrade no longer exists')
								self.currentMissionBuild = nil 
								break
							end
						end
					end
					
					if not self.currentMissionBuild then
						break
					end
				end
			end
		end
	end
	
	function ZoneCommand:chooseBuild()
		local treshhold = self.spendTreshold
		--local treshhold = 0
		if self.side ~= 0 and self.currentBuild == nil then
			local canAfford = {}
			for _,v in ipairs(self.upgrades[self.side]) do
				local u = Group.getByName(v.name)
				if not u then u = StaticObject.getByName(v.name) end
				
				if not u then
						table.insert(canAfford, {product = v, reason='upgrade'})
				elseif u ~= nil then
					for _,v2 in ipairs(v.products) do
						if v2.type == 'mission'  then 
							if self.resource > treshhold and
								(v2.missionType == ZoneCommand.missionTypes.supply_air or 
								v2.missionType == ZoneCommand.missionTypes.supply_convoy or 
								v2.missionType == ZoneCommand.missionTypes.supply_transfer) then
								if self:isMissionValid(v2) and math.random() < ZoneCommand.missionValidChance then
									table.insert(canAfford, {product = v2, reason='mission'})
									if v2.bias then
										for _=1,v2.bias,1 do
											table.insert(canAfford, {product = v2, reason='mission'})
										end
									end
								end
							end
						elseif v2.type=='defense' and self.mode ~='export' and self.mode ~='supply' and v2.cost > 0 then
							local g = Group.getByName(v2.name)
							if not g then
								table.insert(canAfford, {product = v2, reason='defense'})
							elseif g:getSize() < (g:getInitialSize()*math.random(40,100)/100) then
								table.insert(canAfford, {product = v2, reason='repair'})
							end
						end
					end
				end
			end
			
			if #canAfford > 0 then
				local choice = math.random(1, #canAfford)
				
				if canAfford[choice] then
					local p = canAfford[choice]
					if p.reason == 'repair' then
						self:queueBuild(p.product, self.side, true)
					else
						self:queueBuild(p.product, self.side)
					end
				end
			end
		end

		if self.side ~= 0 and self.currentMissionBuild == nil then
			local canMission = {}
			for _,v in ipairs(self.upgrades[self.side]) do
				local u = Group.getByName(v.name)
				if not u then u = StaticObject.getByName(v.name) end
				if u ~= nil then
					for _,v2 in ipairs(v.products) do
						if v2.type == 'mission' then 
							if v2.missionType ~= ZoneCommand.missionTypes.supply_air and 
								v2.missionType ~= ZoneCommand.missionTypes.supply_convoy and 
								v2.missionType ~= ZoneCommand.missionTypes.supply_transfer then
								if self:isMissionValid(v2) and math.random() < ZoneCommand.missionValidChance then
									table.insert(canMission, {product = v2, reason='mission'})
									if v2.bias then
										for _=1,v2.bias,1 do
											table.insert(canMission, {product = v2, reason='mission'})
										end
									end
								end
							end
						end
					end
				end
			end

			if #canMission > 0 then
				local choice = math.random(1, #canMission)
				
				if canMission[choice] then
					local p = canMission[choice]
					self:queueBuild(p.product, self.side)
				end
			end
		end
	end
	
	function ZoneCommand:progressBuild()
		if self.currentBuild and self.currentBuild.side ~= self.side then
			env.info('ZoneCommand:progressBuild '..self.name..' - stopping build, zone changed owner')
			self.currentBuild = nil
		end

		if self.currentMissionBuild and self.currentMissionBuild.side ~= self.side then
			env.info('ZoneCommand:progressBuild '..self.name..' - stopping mission build, zone changed owner')
			self.currentMissionBuild = nil
		end
		
		if self.currentBuild then
			if self.currentBuild.product.type == 'mission' and not self:isMissionValid(self.currentBuild.product) then
				env.info('ZoneCommand:progressBuild '..self.name..' - stopping build, mission no longer valid')
				self.currentBuild = nil
			else
				local cost = self.currentBuild.product.cost
				if self.currentBuild.isRepair then
					cost = math.floor(self.currentBuild.product.cost/2)
				end
				
				if self.currentBuild.progress < cost then
					if self.currentBuild.isRepair and not Group.getByName(self.currentBuild.product.name) then
						env.info('ZoneCommand:progressBuild '..self.name..' - stopping build, group to repair no longer exists')
						self.currentBuild = nil
					else
						if self.currentBuild.isRepair then
							local gr = Group.getByName(self.currentBuild.product.name)
							if gr and self.currentBuild.unitcount and gr:getSize() < self.currentBuild.unitcount then
								env.info('ZoneCommand:progressBuild '..self.name..' - restarting build, group to repair has casualties')
								self.currentBuild.unitcount = gr:getSize()
								self:addResource(self.currentBuild.progress)
								self.currentBuild.progress = 0
							end
						end

						local step = math.floor(ZoneCommand.buildSpeed * self.boostScale)
						if self.currentBuild.product.type == ZoneCommand.productTypes.mission then
							if self.currentBuild.product.missionType == ZoneCommand.missionTypes.supply_air or
								self.currentBuild.product.missionType == ZoneCommand.missionTypes.supply_convoy or
								self.currentBuild.product.missionType == ZoneCommand.missionTypes.supply_transfer then
								step = math.floor(ZoneCommand.supplyBuildSpeed * self.boostScale)

								if self.currentBuild.product.missionType == ZoneCommand.missionTypes.supply_transfer then
									step = math.floor(step*2)
								end
							end
						end
						
						if step > self.resource then step = 1 end
						if step <= self.resource then
							self:removeResource(step)
							self.currentBuild.progress = self.currentBuild.progress + step

							if self.extraBuildResources > 0 then
								local extrastep = step
								if self.extraBuildResources < extrastep then
									extrastep = self.extraBuildResources
								end

								self.extraBuildResources = math.max(self.extraBuildResources - extrastep, 0)
								self.currentBuild.progress = self.currentBuild.progress + extrastep
								
								env.info('ZoneCommand:progressBuild - '..self.name..' consumed '..extrastep..' extra resources, remaining '..self.extraBuildResources)
							end
						end
					end
				else
					if self.currentBuild.product.type == 'mission' then
						if self:isMissionValid(self.currentBuild.product) then
							self:activateMission(self.currentBuild.product)
						else
							self:addResource(self.currentBuild.product.cost)
						end
					elseif self.currentBuild.product.type == 'defense' or self.currentBuild.product.type=='upgrade' then
						if self.currentBuild.isRepair then
							if Group.getByName(self.currentBuild.product.name) then
								self.zone:spawnGroup(self.currentBuild.product, self.spawnSurface)
							end
						else
							self.zone:spawnGroup(self.currentBuild.product, self.spawnSurface)
						end
						
						self.built[self.currentBuild.product.name] = self.currentBuild.product
					end
					
					self.currentBuild = nil
				end
			end
		end

		if self.currentMissionBuild then
			if self.currentMissionBuild.product.type == 'mission' and not self:isMissionValid(self.currentMissionBuild.product) then
				env.info('ZoneCommand:progressBuild '..self.name..' - stopping build, mission no longer valid')
				self.currentMissionBuild = nil
			else
				local cost = self.currentMissionBuild.product.cost
				
				if self.currentMissionBuild.progress < cost then
					local step = math.floor(ZoneCommand.buildSpeed * self.boostScale)

					if step > self.resource then step = 1 end

					local progress = step*self.missionBuildSpeedReduction
					local reducedCost = math.max(1, math.floor(progress))
					if reducedCost <= self.resource then
						self:removeResource(reducedCost)
						self.currentMissionBuild.progress = self.currentMissionBuild.progress + progress
					end
				else
					if self:isMissionValid(self.currentMissionBuild.product) then
						self:activateMission(self.currentMissionBuild.product)
					else
						self:addResource(self.currentMissionBuild.product.cost)
					end
					
					self.currentMissionBuild = nil
				end
			end
		end
	end
	
	function ZoneCommand:queueBuild(product, side, isRepair, progress)
		if product.type ~= ZoneCommand.productTypes.mission or 
			(product.missionType == ZoneCommand.missionTypes.supply_air or
			product.missionType == ZoneCommand.missionTypes.supply_convoy or
			product.missionType == ZoneCommand.missionTypes.supply_transfer) then
				
			local unitcount = nil
			if isRepair then
				local g = Group.getByName(product.name)
				if g then
					unitcount = g:getSize()
					env.info('ZoneCommand:queueBuild - '..self.name..' '..product.name..' has '..unitcount..' units')
				end
			end
			
			self.currentBuild = { product = product, progress = (progress or 0), side = side, isRepair = isRepair, unitcount = unitcount}
			env.info('ZoneCommand:queueBuild - '..self.name..' chose '..product.name..'('..product.display..') as its build')
		else
			self.currentMissionBuild = { product = product, progress = (progress or 0), side = side}
			env.info('ZoneCommand:queueBuild - '..self.name..' chose '..product.name..'('..product.display..') as its mission build')
		end
	end

	function ZoneCommand:reserveMission(product)
		self.reservedMissions[product.name] = product
	end

	function ZoneCommand:unReserveMission(product)
		self.reservedMissions[product.name] = nil
	end

	function ZoneCommand:isMissionValid(product)
		if Group.getByName(product.name) then return false end

		if self.reservedMissions[product.name] then
			return false
		end

		if product.missionType == ZoneCommand.missionTypes.supply_convoy then
			if self.distToFront == nil then return false end

			for _,tgt in pairs(self.neighbours) do
				if self:isSupplyMissionValid(product, tgt) then 
					return true 
				end
			end
		elseif product.missionType == ZoneCommand.missionTypes.supply_transfer then
			if self.distToFront == nil then return false end 
			for _,tgt in pairs(self.neighbours) do
				if self:isSupplyTransferMissionValid(product, tgt) then 
					return true 
				end
			end
		elseif product.missionType == ZoneCommand.missionTypes.supply_air then
			if self.distToFront == nil then return false end

			for _,tgt in pairs(self.neighbours) do
				if self:isSupplyMissionValid(product, tgt) then 
					return true 
				else
					for _,subtgt in pairs(tgt.neighbours) do
						if subtgt.name ~= self.name and self:isSupplyMissionValid(product, subtgt) then
							local dist = mist.utils.get2DDist(self.zone.point, subtgt.zone.point)
							if dist < 50000 then
								return true
							end
						end
					end
				end
			end
		elseif product.missionType == ZoneCommand.missionTypes.assault then
			if self.mode ~= ZoneCommand.modes.normal then return false end
			for _,tgt in pairs(self.neighbours) do
				if self:isAssaultMissionValid(product, tgt) then 
					return true 
				end
			end
		elseif product.missionType == ZoneCommand.missionTypes.cas then
			if self.mode ~= ZoneCommand.modes.normal and not self.keepActive then return false end

			for _,tgt in pairs(ZoneCommand.getAllZones()) do
				if self:isCasMissionValid(product, tgt) then 
					return true 
				end
			end
		elseif product.missionType == ZoneCommand.missionTypes.cas_helo then
			if self.mode ~= ZoneCommand.modes.normal and not self.keepActive then return false end

			for _,tgt in pairs(self.neighbours) do
				if self:isCasMissionValid(product, tgt) then 
					return true 
				end
			end
		elseif product.missionType == ZoneCommand.missionTypes.strike then
			if self.mode ~= ZoneCommand.modes.normal and not self.keepActive then return false end

			for _,tgt in pairs(ZoneCommand.getAllZones()) do
				if self:isStrikeMissionValid(product, tgt) then 
					return true 
				end
			end
		elseif product.missionType == ZoneCommand.missionTypes.sead then
			if self.mode ~= ZoneCommand.modes.normal and not self.keepActive then return false end

			for _,tgt in pairs(ZoneCommand.getAllZones()) do
				if self:isSeadMissionValid(product, tgt) then 
					return true 
				end
			end
		elseif product.missionType == ZoneCommand.missionTypes.patrol then
			if self.mode ~= ZoneCommand.modes.normal and not self.keepActive then return false end

			for _,tgt in pairs(ZoneCommand.getAllZones()) do
				if self:isPatrolMissionValid(product, tgt) then 
					return true 
				end
			end
		elseif product.missionType == ZoneCommand.missionTypes.bai then
			if self.mode ~= ZoneCommand.modes.normal and not self.keepActive then return false end

			for _,tgt in pairs(DependencyManager.get("GroupMonitor").groups) do
				if self:isBaiMissionValid(product, tgt) then 
					return true
				end	
			end
		elseif product.missionType == ZoneCommand.missionTypes.awacs then
			if self.mode ~= ZoneCommand.modes.normal and not self.keepActive then return false end
			for _,tgt in pairs(ZoneCommand.getAllZones()) do
				if self:isAwacsMissionValid(product, tgt) then 
					return true
				end	
			end
		elseif product.missionType == ZoneCommand.missionTypes.tanker then
			if self.mode ~= ZoneCommand.modes.normal and not self.keepActive then return false end
			if not self.distToFront or self.distToFront == 0 then return false end
			for _,tgt in pairs(ZoneCommand.getAllZones()) do
				if self:isTankerMissionValid(product, tgt) then 
					return true
				end	
			end
		end
	end

	function ZoneCommand:activateMission(product)
		if product.missionType == ZoneCommand.missionTypes.supply_convoy then
			self:activateSupplyConvoyMission(product)
		elseif product.missionType == ZoneCommand.missionTypes.assault then
			self:activateAssaultMission(product)
		elseif product.missionType == ZoneCommand.missionTypes.supply_air then
			self:activateAirSupplyMission(product)
		elseif product.missionType == ZoneCommand.missionTypes.supply_transfer then
			self:activateSupplyTransferMission(product)
		elseif product.missionType == ZoneCommand.missionTypes.cas then
			self:activateCasMission(product)
		elseif product.missionType == ZoneCommand.missionTypes.cas_helo then
			self:activateCasMission(product, true)
		elseif product.missionType == ZoneCommand.missionTypes.strike then
			self:activateStrikeMission(product)
		elseif product.missionType == ZoneCommand.missionTypes.sead then
			self:activateSeadMission(product)
		elseif product.missionType == ZoneCommand.missionTypes.patrol then
			self:activatePatrolMission(product)
		elseif product.missionType == ZoneCommand.missionTypes.bai then
			self:activateBaiMission(product)
		elseif product.missionType == ZoneCommand.missionTypes.awacs then
			self:activateAwacsMission(product)
		elseif product.missionType == ZoneCommand.missionTypes.tanker then
			self:activateTankerMission(product)
		end

		env.info('ZoneCommand:activateMission - '..self.name..' activating mission '..product.name..'('..product.display..')')
	end

	function ZoneCommand:reActivateMission(savedData)
		local product = self:getProductByName(savedData.productName)

		if product.missionType == ZoneCommand.missionTypes.supply_convoy then
			self:reActivateSupplyConvoyMission(product, savedData)
		elseif product.missionType == ZoneCommand.missionTypes.assault then
			self:reActivateAssaultMission(product, savedData)
		elseif product.missionType == ZoneCommand.missionTypes.supply_air then
			self:reActivateAirSupplyMission(product, savedData)
		elseif product.missionType == ZoneCommand.missionTypes.supply_transfer then
			self:reActivateSupplyTransferMission(product, savedData)
		elseif product.missionType == ZoneCommand.missionTypes.cas then
			self:reActivateCasMission(product, nil, savedData)
		elseif product.missionType == ZoneCommand.missionTypes.cas_helo then
			self:reActivateCasMission(product, true, savedData)
		elseif product.missionType == ZoneCommand.missionTypes.strike then
			self:reActivateStrikeMission(product, savedData)
		elseif product.missionType == ZoneCommand.missionTypes.sead then
			self:reActivateSeadMission(product, savedData)
		elseif product.missionType == ZoneCommand.missionTypes.patrol then
			self:reActivatePatrolMission(product, savedData)
		elseif product.missionType == ZoneCommand.missionTypes.bai then
			self:reActivateBaiMission(product, savedData)
		elseif product.missionType == ZoneCommand.missionTypes.awacs then
			self:reActivateAwacsMission(product, savedData)
		elseif product.missionType == ZoneCommand.missionTypes.tanker then
			self:reActivateTankerMission(product, savedData)
		end

		env.info('ZoneCommand:reActivateMission - '..self.name..' reactivating mission '..product.name..'('..product.display..')')
	end

	local function getDefaultPos(savedData, isAir)
		local action = 'Off Road'
		local speed = 0
		if isAir then
			action = 'Turning Point'
			speed = 250
		end

		local vars = {
			groupName = savedData.productName,
			point = savedData.position,
			action = 'respawn',
			heading = savedData.heading,
			initTasks = false,
			route = { 
				[1] = {
					alt = savedData.position.y,
					type = 'Turning Point',
					action = action,
					alt_type = 'BARO',
					x = savedData.position.x,
					y = savedData.position.z,
					speed = speed
				}
			}
		}

		return vars
	end

	local function teleportToPos(groupName, pos)
		if pos.y == nil then
			pos.y = land.getHeight({ x = pos.x, y = pos.z })
		end

		local vars = {
			groupName = groupName,
			point = pos,
			action = 'respawn',
			initTasks = false
		}

		mist.teleportToPoint(vars)
	end

	function ZoneCommand:reActivateSupplyConvoyMission(product, savedData)
		local zone = ZoneCommand.getZoneByName(savedData.lastMission.zoneName)

		local supplyPoint = trigger.misc.getZone(zone.name..'-sp')
		if not supplyPoint then
			supplyPoint = trigger.misc.getZone(zone.name)
		end
		if supplyPoint then 
			mist.teleportToPoint(getDefaultPos(savedData, false))
			DependencyManager.get("GroupMonitor"):registerGroup(product, zone, self, savedData)

			product.lastMission = {zoneName = zone.name}
			timer.scheduleFunction(function(param)
				local gr = Group.getByName(param.name)
				TaskExtensions.moveOnRoadToPoint(gr, param.point)
			end, {name=product.name, point={ x=supplyPoint.point.x, y = supplyPoint.point.z}}, timer.getTime()+1)
		end
	end
	
	function ZoneCommand:reActivateAssaultMission(product, savedData)
		local zone = ZoneCommand.getZoneByName(savedData.lastMission.zoneName)

		local supplyPoint = trigger.misc.getZone(zone.name..'-sp')
		if not supplyPoint then
			supplyPoint = trigger.misc.getZone(zone.name)
		end
		if supplyPoint then 
			mist.teleportToPoint(getDefaultPos(savedData, false))
			DependencyManager.get("GroupMonitor"):registerGroup(product, zone, self, savedData)

			local tgtPoint = trigger.misc.getZone(zone.name)

			if tgtPoint then 
				product.lastMission = {zoneName = zone.name}
				timer.scheduleFunction(function(param)
					local gr = Group.getByName(param.name)
					TaskExtensions.moveOnRoadToPointAndAssault(gr, param.point, param.targets)
				end, {name=product.name, point={ x=tgtPoint.point.x, y = tgtPoint.point.z}, targets=zone.built}, timer.getTime()+1)
			end
		end
	end
	
	function ZoneCommand:reActivateAirSupplyMission(product, savedData)
		local zone = ZoneCommand.getZoneByName(savedData.lastMission.zoneName)

		mist.teleportToPoint(getDefaultPos(savedData, true))
		DependencyManager.get("GroupMonitor"):registerGroup(product, zone, self, savedData)

		local supplyPoint = trigger.misc.getZone(zone.name..'-hsp')
		if not supplyPoint then
			supplyPoint = trigger.misc.getZone(zone.name)
		end

		if supplyPoint then 
			product.lastMission = {zoneName = zone.name}
			local alt = DependencyManager.get("ConnectionManager"):getHeliAlt(self.name, zone.name)
			timer.scheduleFunction(function(param)
				local gr = Group.getByName(param.name)
				TaskExtensions.landAtPoint(gr, param.point, param.alt)
			end, {name=product.name, point={ x=supplyPoint.point.x, y = supplyPoint.point.z}, alt = alt}, timer.getTime()+1)
		end
	end
	
	function ZoneCommand:reActivateSupplyTransferMission(product, savedData)
		-- not needed
	end
	
	function ZoneCommand:reActivateCasMission(product, isHelo, savedData)
		local zone = ZoneCommand.getZoneByName(savedData.lastMission.zoneName)

		mist.teleportToPoint(getDefaultPos(savedData, true))
		DependencyManager.get("GroupMonitor"):registerGroup(product, zone, self, savedData)

		local homePos = trigger.misc.getZone(savedData.homeName).point

		if zone then 
			product.lastMission = {zoneName = zone.name}
			timer.scheduleFunction(function(param)
				local gr = Group.getByName(param.prod.name)
				if param.helo then
					TaskExtensions.executeHeloCasMission(gr, param.targets, param.prod.expend, param.prod.altitude, {homePos = homePos})
				else
					TaskExtensions.executeCasMission(gr, param.targets, param.prod.expend, param.prod.altitude, {homePos = homePos})
				end
			end, {prod=product, targets=zone.built, helo = isHelo, homePos = homePos}, timer.getTime()+1)
		end
	end
	
	function ZoneCommand:reActivateStrikeMission(product, savedData)
		local zone = ZoneCommand.getZoneByName(savedData.lastMission.zoneName)

		mist.teleportToPoint(getDefaultPos(savedData, true))

		DependencyManager.get("GroupMonitor"):registerGroup(product, zone, self, savedData)

		local homePos = trigger.misc.getZone(savedData.homeName).point

		if zone then 
			product.lastMission = {zoneName = zone.name}
			timer.scheduleFunction(function(param)
				local gr = Group.getByName(param.prod.name)
				TaskExtensions.executeStrikeMission(gr, param.targets, param.prod.expend, param.prod.altitude, {homePos = homePos})
			end, {prod=product, targets=zone.built, homePos = homePos}, timer.getTime()+1)
		end
	end
	
	function ZoneCommand:reActivateSeadMission(product, savedData)
		local zone = ZoneCommand.getZoneByName(savedData.lastMission.zoneName)

		mist.teleportToPoint(getDefaultPos(savedData, true))
		DependencyManager.get("GroupMonitor"):registerGroup(product, zone, self, savedData)

		local homePos = trigger.misc.getZone(savedData.homeName).point

		if zone then 
			product.lastMission = {zoneName = zone.name}
			timer.scheduleFunction(function(param)
				local gr = Group.getByName(param.prod.name)
				TaskExtensions.executeSeadMission(gr, param.targets, param.prod.expend, param.prod.altitude, {homePos = homePos})
			end, {prod=product, targets=zone.built, homePos = homePos}, timer.getTime()+1)
		end
	end
	
	function ZoneCommand:reActivatePatrolMission(product, savedData)

		local zn1 = ZoneCommand.getZoneByName(savedData.lastMission.zone1name)

		mist.teleportToPoint(getDefaultPos(savedData, true))
		DependencyManager.get("GroupMonitor"):registerGroup(product, zn1, self, savedData)

		local homePos = trigger.misc.getZone(savedData.homeName).point

		if zn1 then 
			product.lastMission = {zone1name = zn1.name}
			timer.scheduleFunction(function(param)
				local gr = Group.getByName(param.prod.name)

				local point = trigger.misc.getZone(param.zone1.name).point

				TaskExtensions.executePatrolMission(gr, point, param.prod.altitude, param.prod.range, {homePos = param.homePos})
			end, {prod=product, zone1 = zn1, homePos = homePos}, timer.getTime()+1)
		end
	end
	
	function ZoneCommand:reActivateBaiMission(product, savedData)
		local targets = {}
		local hasTarget = false
		for _,tgt in pairs(DependencyManager.get("GroupMonitor").groups) do
			if self:isBaiMissionValid(product, tgt) then 
				targets[tgt.product.name] = tgt.product
				hasTarget = true
			end	
		end
		
		local homePos = trigger.misc.getZone(savedData.homeName).point

		if hasTarget then 
			mist.teleportToPoint(getDefaultPos(savedData, true))
			DependencyManager.get("GroupMonitor"):registerGroup(product, nil, self, savedData)

			product.lastMission = { active = true }
			timer.scheduleFunction(function(param)
				local gr = Group.getByName(param.prod.name)
				TaskExtensions.executeBaiMission(gr, param.targets, param.prod.expend, param.prod.altitude, {homePos = param.homePos})
			end, {prod=product, targets=targets, homePos = homePos}, timer.getTime()+1)
		end
	end
	
	function ZoneCommand:reActivateAwacsMission(product, savedData)
		
		local zone = ZoneCommand.getZoneByName(savedData.lastMission.zoneName)
		local homePos = trigger.misc.getZone(savedData.homeName).point

		mist.teleportToPoint(getDefaultPos(savedData, true))
		DependencyManager.get("GroupMonitor"):registerGroup(product, nil, self, savedData)
		timer.scheduleFunction(function(param)
			local gr = Group.getByName(param.prod.name)
			if gr then
				local un = gr:getUnit(1)
				if un then 
					local callsign = un:getCallsign()
					RadioFrequencyTracker.registerRadio(param.prod.name, '[AWACS] '..callsign, param.prod.freq..' AM')
				end

				local point = trigger.misc.getZone(param.target.name).point
				product.lastMission = { zoneName = param.target.name }
				TaskExtensions.executeAwacsMission(gr, point, param.prod.altitude, param.prod.freq, {homePos = param.homePos})
			end
		end, {prod=product, target=zone, homePos = homePos}, timer.getTime()+1)
	end
	
	function ZoneCommand:reActivateTankerMission(product, savedData)

		local zone = ZoneCommand.getZoneByName(savedData.lastMission.zoneName)

		local homePos = trigger.misc.getZone(savedData.homeName).point
		mist.teleportToPoint(getDefaultPos(savedData, true))
		DependencyManager.get("GroupMonitor"):registerGroup(product, zone, self, savedData)
		
		timer.scheduleFunction(function(param)
			local gr = Group.getByName(param.prod.name)
			if gr then
				local un = gr:getUnit(1)
				if un then 
					local callsign = un:getCallsign()
					RadioFrequencyTracker.registerRadio(param.prod.name, '[Tanker('..param.prod.variant..')] '..callsign, param.prod.freq..' AM | TCN '..param.prod.tacan..'X')
				end

				local point = trigger.misc.getZone(param.target.name).point
				product.lastMission = { zoneName = param.target.name }
				TaskExtensions.executeTankerMission(gr, point, param.prod.altitude, param.prod.freq, param.prod.tacan, {homePos = param.homePos})
			end
		end, {prod=product, target=zone, homePos = homePos}, timer.getTime()+1)
	end

	function ZoneCommand:isBaiMissionValid(product, tgtgroup)
		if product.side == tgtgroup.product.side then return false end
		if tgtgroup.product.type ~= ZoneCommand.productTypes.mission then return false end
		if tgtgroup.product.missionType == ZoneCommand.missionTypes.assault then return true end
		if tgtgroup.product.missionType == ZoneCommand.missionTypes.supply_convoy then return true end
	end

	function ZoneCommand:activateBaiMission(product)
		--{name = product.name, lastStateTime = timer.getAbsTime(), product = product, target = target}
		local targets = {}
		local hasTarget = false
		for _,tgt in pairs(DependencyManager.get("GroupMonitor").groups) do
			if self:isBaiMissionValid(product, tgt) then 
				targets[tgt.product.name] = tgt.product
				hasTarget = true
			end	
		end

		if hasTarget then 
			local og = Utils.getOriginalGroup(product.name)
			if og then
				teleportToPos(product.name, {x=og.x, z=og.y})
				env.info("ZoneCommand - activateBaiMission teleporting to OG pos")
			else
				mist.respawnGroup(product.name, true)
				env.info("ZoneCommand - activateBaiMission fallback to respawnGroup")
			end

			DependencyManager.get("GroupMonitor"):registerGroup(product, nil, self)

			product.lastMission = { active = true }
			timer.scheduleFunction(function(param)
				local gr = Group.getByName(param.prod.name)
				TaskExtensions.executeBaiMission(gr, param.targets, param.prod.expend, param.prod.altitude)
			end, {prod=product, targets=targets}, timer.getTime()+1)

			env.info("ZoneCommand - "..product.name.." targeting convoys")
		end
	end

	local function prioritizeSupplyTargets(a,b)
		--if a:criticalOnSupplies() and not b:criticalOnSupplies() then return true end
		--if b:criticalOnSupplies() and not a:criticalOnSupplies() then return false end

		if a.distToFront~=nil and b.distToFront == nil then
			return true
		elseif a.distToFront == nil and b.distToFront ~= nil then
			return false
		elseif a.distToFront == b.distToFront then
			return a.resource < b.resource
		else
			return a.distToFront<b.distToFront
		end
	end

	function ZoneCommand:activateSupplyTransferMission(product)
		local tgtzones = {}
		for _,v in pairs(self.neighbours) do
			if (v.side == 0 or v.side==product.side) then
				table.insert(tgtzones, v)
			end
		end
		
		if #tgtzones == 0 then 
			env.info('ZoneCommand:activateSupplyTransferMission - '..self.name..' no valid tgtzones')
			return 
		end

		table.sort(tgtzones, prioritizeSupplyTargets)

		for i,v in ipairs(tgtzones) do
			if self:isSupplyTransferMissionValid(product, v) then
				-- virtual resourse transfer to save some performance
				v:addResource(product.cost)
				env.info('ZoneCommand:activateSupplyTransferMission - '..self.name..' transfered '..product.cost..' to '..v.name)
				break
			end
		end
	end

	function ZoneCommand:activateAirSupplyMission(product) 
		local tgtzones = {}
		for _,v in pairs(self.neighbours) do
			if (v.side == 0 or v.side==product.side) then
				table.insert(tgtzones, v)

				for _,v2 in pairs(v.neighbours) do
					if v2.name~=self.name and (v2.side == 0 or v2.side==product.side) then
						local dist = mist.utils.get2DDist(self.zone.point, v2.zone.point)
						if dist < 50000 then
							table.insert(tgtzones, v2)
						end
					end
				end
			end
		end
		
		if #tgtzones == 0 then 
			env.info('ZoneCommand:activateAirSupplyMission - '..self.name..' no valid tgtzones')
			return 
		end

		table.sort(tgtzones, prioritizeSupplyTargets)
		local viablezones = {}
		for _,v in ipairs(tgtzones) do
			viablezones[v.name] = v
		end

		if BattlefieldManager and BattlefieldManager.priorityZones[self.side] then
			local prioZone = BattlefieldManager.priorityZones[self.side]
			if prioZone.side == 0 and viablezones[prioZone.name] and self:isSupplyMissionValid(product, prioZone) then
				tgtzones = { prioZone }
			end
		end

		for i,v in ipairs(tgtzones) do
			if self:isSupplyMissionValid(product, v) then

				local og = Utils.getOriginalGroup(product.name)
				if og then
					teleportToPos(product.name, {x=og.x, z=og.y})
					env.info("ZoneCommand - activateAirSupplyMission teleporting to OG pos")
				else
					mist.respawnGroup(product.name, true)
					env.info("ZoneCommand - activateAirSupplyMission fallback to respawnGroup")
				end

				DependencyManager.get("GroupMonitor"):registerGroup(product, v, self)

				local supplyPoint = trigger.misc.getZone(v.name..'-hsp')
				if not supplyPoint then
					supplyPoint = trigger.misc.getZone(v.name)
				end

				if supplyPoint then 
					product.lastMission = {zoneName = v.name}

					local alt = DependencyManager.get("ConnectionManager"):getHeliAlt(self.name, v.name)
					timer.scheduleFunction(function(param)
						local gr = Group.getByName(param.name)
						TaskExtensions.landAtPoint(gr, param.point, param.alt )
					end, {name=product.name, point={ x=supplyPoint.point.x, y = supplyPoint.point.z}, alt = alt}, timer.getTime()+1)

					env.info("ZoneCommand - "..product.name.." targeting "..v.name)
				end

				break
			end
		end
	end

	function ZoneCommand:isSupplyTransferMissionValid(product, target)
		if target.side == 0 then
			return false
		end

		if target.side == self.side then 
			if self.distToFront <= 1 or target.distToFront <= 1 then return false end -- skip transfer missions if close to front

			if not target.distToFront or not self.distToFront then
				return false
			end
			
			if target:needsSupplies(product.cost) and target.distToFront < self.distToFront then
				return true
			end
			
			if target:criticalOnSupplies() and self.distToFront<=target.distToFront then
				return true
			end

			if target:criticalOnSupplies() and target.mode == 'normal' then 
				return true
			end
		end
	end

	function ZoneCommand:isSupplyMissionValid(product, target)
		if product.missionType == ZoneCommand.missionTypes.supply_convoy then
			if DependencyManager.get("ConnectionManager"):isRoadBlocked(self.name, target.name) then
				return false
			end
		end
		
		if not self.distToFront then return false end
		if not target.distToFront then return false end
		
		if target.side == 0 then
			return true
		end

		if target.side == self.side then 
			if self.distToFront > 1 and target.distToFront > 1 then return false end -- skip regular missions if not close to front

			if self.mode == 'normal' and self.distToFront == 0  and target.distToFront == 0 then
				return target:needsSupplies(product.cost*0.5)
			end
			
			if target:needsSupplies(product.cost*0.5) and target.distToFront < self.distToFront then
				return true
			elseif target:criticalOnSupplies() and self.distToFront>=target.distToFront then
				return true
			end

			if target.mode == 'normal' and target:needsSupplies(product.cost*0.5) then 
				return true
			end
		end
	end

	function ZoneCommand:activateSupplyConvoyMission(product)
		local tgtzones = {}
		for _,v in pairs(self.neighbours) do
			if (v.side == 0 or v.side==product.side) then
				table.insert(tgtzones, v)
			end
		end
		
		if #tgtzones == 0 then 
			env.info('ZoneCommand:activateSupplyConvoyMission - '..self.name..' no valid tgtzones')
			return 
		end

		table.sort(tgtzones, prioritizeSupplyTargets)

		if BattlefieldManager and BattlefieldManager.priorityZones[self.side] then
			local prioZone = BattlefieldManager.priorityZones[self.side]
			if prioZone.side == 0 and self.neighbours[prioZone.name] and self:isSupplyMissionValid(product, prioZone) then
				tgtzones = { prioZone }
			end
		end

		for i,v in ipairs(tgtzones) do
			if self:isSupplyMissionValid(product, v) then

				local supplyPoint = trigger.misc.getZone(v.name..'-sp')
				if not supplyPoint then
					supplyPoint = trigger.misc.getZone(v.name)
				end
				
				if supplyPoint then 

					local og = Utils.getOriginalGroup(product.name)
					if og then
						teleportToPos(product.name, {x=og.x, z=og.y})
						env.info("ZoneCommand - activateSupplyConvoyMission teleporting to OG pos")
					else
						mist.respawnGroup(product.name, true)
						env.info("ZoneCommand - activateSupplyConvoyMission fallback to respawnGroup")
					end

					DependencyManager.get("GroupMonitor"):registerGroup(product, v, self)

					product.lastMission = {zoneName = v.name}
					timer.scheduleFunction(function(param)
						local gr = Group.getByName(param.name)
						TaskExtensions.moveOnRoadToPoint(gr, param.point)
					end, {name=product.name, point={ x=supplyPoint.point.x, y = supplyPoint.point.z}}, timer.getTime()+1)
					
					env.info("ZoneCommand - "..product.name.." targeting "..v.name)
				end

				break
			end
		end
	end

	function ZoneCommand:isAssaultMissionValid(product, target)

		if product.missionType == ZoneCommand.missionTypes.assault then
			if DependencyManager.get("ConnectionManager"):isRoadBlocked(self.name, target.name) then
				return false
			end
		end

		if target.side ~= product.side and target.side ~= 0 then
			return true
		end
	end

	function ZoneCommand:activateAssaultMission(product)
		local tgtzones = {}
		for _,v in pairs(self.neighbours) do
			table.insert(tgtzones, {zone = v, rank = math.random()})
		end

		table.sort(tgtzones, function(a,b) return a.rank < b.rank end)

		local sorted = {}
		for i,v in ipairs(tgtzones) do
			table.insert(sorted, v.zone)
		end
		tgtzones = sorted

		if BattlefieldManager and BattlefieldManager.priorityZones[self.side] then
			local prioZone = BattlefieldManager.priorityZones[self.side]
			if self.neighbours[prioZone.name] and self:isAssaultMissionValid(product, prioZone) then
				tgtzones = { prioZone }
			end
		end

		for i,v in ipairs(tgtzones) do
			if self:isAssaultMissionValid(product, v) then

				local og = Utils.getOriginalGroup(product.name)
				if og then
					teleportToPos(product.name, {x=og.x, z=og.y})
					env.info("ZoneCommand - activateAssaultMission teleporting to OG pos")
				else
					mist.respawnGroup(product.name, true)
					env.info("ZoneCommand - activateAssaultMission fallback to respawnGroup")
				end

				DependencyManager.get("GroupMonitor"):registerGroup(product, v, self)

				local tgtPoint = trigger.misc.getZone(v.name)

				if tgtPoint then 
					product.lastMission = {zoneName = v.name}
					timer.scheduleFunction(function(param)
						local gr = Group.getByName(param.name)
						TaskExtensions.moveOnRoadToPointAndAssault(gr, param.point, param.targets)
					end, {name=product.name, point={ x=tgtPoint.point.x, y = tgtPoint.point.z}, targets=v.built}, timer.getTime()+1)

					env.info("ZoneCommand - "..product.name.." targeting "..v.name)
				end

				break
			end
		end
	end
	
	function ZoneCommand:isAwacsMissionValid(product, target)
		if target.side ~= product.side then return false end
		if target.name == self.name then return false end
		if not target.distToFront or target.distToFront ~= 4 then return false end
		
		return true
	end

	function ZoneCommand:activateAwacsMission(product)
		local tgtzones = {}
		for _,v in pairs(ZoneCommand.getAllZones()) do
			if self:isAwacsMissionValid(product, v) then
				table.insert(tgtzones, v)
			end
		end

		local choice1 = math.random(1,#tgtzones)
		local zn = tgtzones[choice1]

		local og = Utils.getOriginalGroup(product.name)
		if og then
			teleportToPos(product.name, {x=og.x, z=og.y})
			env.info("ZoneCommand - activateAwacsMission teleporting to OG pos")
		else
			mist.respawnGroup(product.name, true)
			env.info("ZoneCommand - activateAwacsMission fallback to respawnGroup")
		end

		DependencyManager.get("GroupMonitor"):registerGroup(product, zn, self)

		timer.scheduleFunction(function(param)
			local gr = Group.getByName(param.prod.name)
			if gr then
				local un = gr:getUnit(1)
				if un then 
					local callsign = un:getCallsign()
					RadioFrequencyTracker.registerRadio(param.prod.name, '[AWACS] '..callsign, param.prod.freq..' AM')
				end

				local point = trigger.misc.getZone(param.target.name).point
				product.lastMission = { zoneName = param.target.name }
				TaskExtensions.executeAwacsMission(gr, point, param.prod.altitude, param.prod.freq)
				
			end
		end, {prod=product, target=zn}, timer.getTime()+1)

		env.info("ZoneCommand - "..product.name.." targeting "..zn.name)
	end

	function ZoneCommand:isTankerMissionValid(product, target)
		if target.side ~= product.side then return false end
		if target.name == self.name then return false end
		if not target.distToFront or target.distToFront ~= 4 then return false end
		
		return true
	end

	function ZoneCommand:activateTankerMission(product)

		local tgtzones = {}
		for _,v in pairs(ZoneCommand.getAllZones()) do
			if self:isTankerMissionValid(product, v) then
				table.insert(tgtzones, v)
			end
		end

		local choice1 = math.random(1,#tgtzones)
		local zn = tgtzones[choice1]
		table.remove(tgtzones, choice1)

		local og = Utils.getOriginalGroup(product.name)
		if og then
			teleportToPos(product.name, {x=og.x, z=og.y})
			env.info("ZoneCommand - activateTankerMission teleporting to OG pos")
		else
			mist.respawnGroup(product.name, true)
			env.info("ZoneCommand - activateTankerMission fallback to respawnGroup")
		end

		DependencyManager.get("GroupMonitor"):registerGroup(product, zn, self)

		timer.scheduleFunction(function(param)
			local gr = Group.getByName(param.prod.name)
			if gr then
				local un = gr:getUnit(1)
				if un then 
					local callsign = un:getCallsign()
					RadioFrequencyTracker.registerRadio(param.prod.name, '[Tanker('..param.prod.variant..')] '..callsign, param.prod.freq..' AM | TCN '..param.prod.tacan..'X')
				end

				local point = trigger.misc.getZone(param.target.name).point
				product.lastMission = { zoneName = param.target.name }
				TaskExtensions.executeTankerMission(gr, point, param.prod.altitude, param.prod.freq, param.prod.tacan)
			end
		end, {prod=product, target=zn}, timer.getTime()+1)
		
		env.info("ZoneCommand - "..product.name.." targeting "..zn.name)
	end

	function ZoneCommand:isPatrolMissionValid(product, target)
		--if target.side ~= product.side then return false end
		if target.name == self.name then return false end
		if not target.distToFront or target.distToFront > 1 then return false end
		if target.side ~= product.side and target.side ~= 0 then return false end
		local dist = mist.utils.get2DDist(self.zone.point, target.zone.point)
		if dist > 150000 then return false end
		
		return true
	end

	function ZoneCommand:activatePatrolMission(product)
		local tgtzones = {}
		for _,v in pairs(ZoneCommand.getAllZones()) do
			if self:isPatrolMissionValid(product, v) then
				table.insert(tgtzones, v)
			end
		end

		local choice1 = math.random(1,#tgtzones)
		local zn1 = tgtzones[choice1]

		if BattlefieldManager and BattlefieldManager.priorityZones[self.side] then
			local prioZone = BattlefieldManager.priorityZones[self.side]
			if self:isPatrolMissionValid(product, prioZone) then
				zn1 = prioZone
			end
		end

		local og = Utils.getOriginalGroup(product.name)
		if og then
			teleportToPos(product.name, {x=og.x, z=og.y})
			env.info("ZoneCommand - activatePatrolMission teleporting to OG pos")
		else
			mist.respawnGroup(product.name, true)
			env.info("ZoneCommand - activatePatrolMission fallback to respawnGroup")
		end

		DependencyManager.get("GroupMonitor"):registerGroup(product, zn1, self)

		if zn1 then 
			product.lastMission = {zone1name = zn1.name}
			timer.scheduleFunction(function(param)
				local gr = Group.getByName(param.prod.name)

				local point = trigger.misc.getZone(param.zone1.name).point

				TaskExtensions.executePatrolMission(gr, point, param.prod.altitude, param.prod.range)
			end, {prod=product, zone1 = zn1}, timer.getTime()+1)

			env.info("ZoneCommand - "..product.name.." targeting "..zn1.name)
		end
	end

	function ZoneCommand:isSeadMissionValid(product, target)
		if target.side == 0 then return false end
		if not target.distToFront or target.distToFront > 1 then return false end
		
		--if MissionTargetRegistry.isZoneTargeted(target.name) then return false end

		return target:hasEnemySAMRadar(product)
	end

	function ZoneCommand:hasEnemySAMRadar(product)
		if product.side == 1 then
			return self:hasSAMRadarOnSide(2)
		elseif product.side == 2 then
			return self:hasSAMRadarOnSide(1)
		end
	end

	function ZoneCommand:hasSAMRadarOnSide(side)
		for i,v in pairs(self.built) do
			if v.type == ZoneCommand.productTypes.defense and v.side == side then 
				local gr = Group.getByName(v.name)
				if gr then
					for _,unit in ipairs(gr:getUnits()) do
						if unit:hasAttribute('SAM SR') or unit:hasAttribute('SAM TR') then
							return true
						end
					end
				end
			end
		end
	end

	function ZoneCommand:hasRunway()
		local zones = self:getRunwayZones()
		return #zones > 0
	end

	function ZoneCommand:getRunwayZones()
		local runways = {}
		for i=1,10,1 do
			local name = self.name..'-runway-'..i
			local zone = trigger.misc.getZone(name)
			if zone then 
				runways[i] = {name = name, zone = zone}
			else
				break
			end
		end

		return runways
	end

	function ZoneCommand:getRandomUnitWithAttributeOnSide(attributes, side)
		local available = {}
		for i,v in pairs(self.built) do
			if v.type == ZoneCommand.productTypes.upgrade and v.side == side then
				local st = StaticObject.getByName(v.name)
				if st then
					for _,a in ipairs(attributes) do
						if a == "Buildings" and ZoneCommand.staticRegistry[v.name] then -- dcs does not consider all statics buildings so we compensate
							table.insert(available, v)
						end
					end
				end
			elseif v.type == ZoneCommand.productTypes.defense and v.side == side then 
				local gr = Group.getByName(v.name)
				if gr then
					for _,unit in ipairs(gr:getUnits()) do
						for _,a in ipairs(attributes) do
							if unit:hasAttribute(a) then
								table.insert(available, v)
							end
						end
					end
				end
			end
		end

		if #available > 0 then
			return available[math.random(1, #available)]
		end
	end

	function ZoneCommand:hasUnitWithAttributeOnSide(attributes, side, amount)
		local count = 0

		for i,v in pairs(self.built) do
			if v.type == ZoneCommand.productTypes.upgrade and v.side == side then
				local st = StaticObject.getByName(v.name)
				if st and st:isExist() then
					for _,a in ipairs(attributes) do
						if a == "Buildings" and ZoneCommand.staticRegistry[v.name] then -- dcs does not consider all statics buildings so we compensate
							if amount==nil then
								return true
							else
								count = count + 1
								if count >= amount then return true end
							end
						end
					end
				end
			elseif v.type == ZoneCommand.productTypes.defense and v.side == side then 
				local gr = Group.getByName(v.name)
				if gr then
					for _,unit in ipairs(gr:getUnits()) do
						if unit:isExist() then
							for _,a in ipairs(attributes) do
								if unit:hasAttribute(a) then
									if amount==nil then
										return true
									else
										count = count + 1
										if count >= amount then return true end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	function ZoneCommand:getUnitCountWithAttributeOnSide(attributes, side)
		local count = 0

		for i,v in pairs(self.built) do
			if v.type == ZoneCommand.productTypes.upgrade and v.side == side then
				local st = StaticObject.getByName(v.name)
				if st then
					for _,a in ipairs(attributes) do
						if a == "Buildings" and ZoneCommand.staticRegistry[v.name] then
							count = count + 1
							break
						end
					end
				end
			elseif v.type == ZoneCommand.productTypes.defense and v.side == side then 
				local gr = Group.getByName(v.name)
				if gr then
					for _,unit in ipairs(gr:getUnits()) do
						for _,a in ipairs(attributes) do
							if unit:hasAttribute(a) then
								count = count + 1
								break
							end
						end
					end
				end
			end
		end

		return count
	end

	function ZoneCommand:activateSeadMission(product)
		local tgtzones = {}
		for _,v in pairs(ZoneCommand.getAllZones()) do
			if self:isSeadMissionValid(product, v) then
				table.insert(tgtzones, v)
			end
		end
		
		local choice = math.random(1,#tgtzones)
		local target = tgtzones[choice]

		if BattlefieldManager and BattlefieldManager.priorityZones[self.side] then
			local prioZone = BattlefieldManager.priorityZones[self.side]
			if self:isSeadMissionValid(product, prioZone) then
				target = prioZone
			end
		end

		local og = Utils.getOriginalGroup(product.name)
		if og then
			teleportToPos(product.name, {x=og.x, z=og.y})
			env.info("ZoneCommand - activateSeadMission teleporting to OG pos")
		else
			mist.respawnGroup(product.name, true)
			env.info("ZoneCommand - activateSeadMission fallback to respawnGroup")
		end

		DependencyManager.get("GroupMonitor"):registerGroup(product, target, self)

		if target then 
			product.lastMission = {zoneName = target.name}
			timer.scheduleFunction(function(param)
				local gr = Group.getByName(param.prod.name)
				TaskExtensions.executeSeadMission(gr, param.targets, param.prod.expend, param.prod.altitude)
			end, {prod=product, targets=target.built}, timer.getTime()+1)
			
			env.info("ZoneCommand - "..product.name.." targeting "..target.name)
		end
	end

	function ZoneCommand:isStrikeMissionValid(product, target)
		if target.side == 0 then return false end
		if target.side == product.side then return false end
		if not target.distToFront or target.distToFront > 0 then return false end

		if target:hasEnemySAMRadar(product) then return false end

		--if MissionTargetRegistry.isZoneTargeted(target.name) then return false end

		for i,v in pairs(target.built) do
			if v.type == ZoneCommand.productTypes.upgrade and v.side ~= product.side then 
				return true
			end
		end
	end

	function ZoneCommand:activateStrikeMission(product)
		local tgtzones = {}
		for _,v in pairs(ZoneCommand.getAllZones()) do
			if self:isStrikeMissionValid(product, v) then
				table.insert(tgtzones, v)
			end
		end
		
		local choice = math.random(1,#tgtzones)
		local target = tgtzones[choice]

		if BattlefieldManager and BattlefieldManager.priorityZones[self.side] then
			local prioZone = BattlefieldManager.priorityZones[self.side]
			if self:isStrikeMissionValid(product, prioZone) then
				target = prioZone
			end
		end

		local og = Utils.getOriginalGroup(product.name)
		if og then
			teleportToPos(product.name, {x=og.x, z=og.y})
			env.info("ZoneCommand - activateStrikeMission teleporting to OG pos")
		else
			mist.respawnGroup(product.name, true)
			env.info("ZoneCommand - activateStrikeMission fallback to respawnGroup")
		end

		DependencyManager.get("GroupMonitor"):registerGroup(product, target, self)

		if target then 
			product.lastMission = {zoneName = target.name}
			timer.scheduleFunction(function(param)
				local gr = Group.getByName(param.prod.name)
				TaskExtensions.executeStrikeMission(gr, param.targets, param.prod.expend, param.prod.altitude)
			end, {prod=product, targets=target.built}, timer.getTime()+1)
			
			env.info("ZoneCommand - "..product.name.." targeting "..target.name)
		end
	end

	function ZoneCommand:isCasMissionValid(product, target)
		if target.side == product.side then return false end
		if not target.distToFront or target.distToFront > 0 then return false end

		if target:hasEnemySAMRadar(product) then return false end

		--if MissionTargetRegistry.isZoneTargeted(target.name) then return false end
		
		for i,v in pairs(target.built) do
			if v.type == ZoneCommand.productTypes.defense and v.side ~= product.side then 
				return true
			end
		end
	end

	function ZoneCommand:activateCasMission(product, ishelo)
		local viablezones = {}
		if ishelo then
			viablezones = self.neighbours
		else
			viablezones = ZoneCommand.getAllZones()
		end

		local tgtzones = {}
		for _,v in pairs(viablezones) do
			if self:isCasMissionValid(product, v) then
				table.insert(tgtzones, v)
			end
		end
		
		local choice = math.random(1,#tgtzones)
		local target = tgtzones[choice]

		if BattlefieldManager and BattlefieldManager.priorityZones[self.side] then
			local prioZone = BattlefieldManager.priorityZones[self.side]
			if viablezones[prioZone.name] and self:isCasMissionValid(product, prioZone) then
				target = prioZone
			end
		end

		local og = Utils.getOriginalGroup(product.name)
		if og then
			teleportToPos(product.name, {x=og.x, z=og.y})
			env.info("ZoneCommand - activateCasMission teleporting to OG pos")
		else
			mist.respawnGroup(product.name, true)
			env.info("ZoneCommand - activateCasMission fallback to respawnGroup")
		end

		DependencyManager.get("GroupMonitor"):registerGroup(product, target, self)

		if target then 
			product.lastMission = {zoneName = target.name}
			timer.scheduleFunction(function(param)
				local gr = Group.getByName(param.prod.name)
				if param.helo then
					TaskExtensions.executeHeloCasMission(gr, param.targets, param.prod.expend, param.prod.altitude)
				else
					TaskExtensions.executeCasMission(gr, param.targets, param.prod.expend, param.prod.altitude)
				end
			end, {prod=product, targets=target.built, helo = ishelo}, timer.getTime()+1)

			env.info("ZoneCommand - "..product.name.." targeting "..target.name)
		end
	end
	
	function ZoneCommand:defineUpgrades(upgrades)
		self.upgrades = upgrades
		
		for side,sd in ipairs(self.upgrades) do
			for _,v in ipairs(sd) do
				v.side = side
				
				local cat = TemplateDB.getData(v.template)
				if cat.dataCategory == TemplateDB.type.static then
					ZoneCommand.staticRegistry[v.name] = true
				end
				
				for _,v2 in ipairs(v.products) do
					v2.side = side

					if v2.type == "mission" then
						local gr = Group.getByName(v2.name)
						
						if not gr then
							if v2.missionType ~= ZoneCommand.missionTypes.supply_transfer then
								env.info("ZoneCommand - ERROR declared group does not exist in mission: ".. v2.name)
							end
						else
							gr:destroy() 
						end
					end
				end
			end
		end
	end
	
	function ZoneCommand:getProductByName(name)
		for i,v in ipairs(self.upgrades) do
			for i2,v2 in ipairs(v) do
				if v2.name == name then
					return v2
				else
					for i3,v3 in ipairs(v2.products) do
						if v3.name == name then 
							return v3
						end
					end
				end
			end
		end

		return nil
	end

	function ZoneCommand:cleanup()
		local zn = trigger.misc.getZone(self.name)
		local pos =  {
			x = zn.point.x, 
			y = land.getHeight({x = zn.point.x, y = zn.point.z}), 
			z= zn.point.z
		}
		local radius = zn.radius*2
		world.removeJunk({id = world.VolumeType.SPHERE,params = {point = pos, radius = radius}})
	end
end




