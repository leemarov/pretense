



ZoneCommand = {}
do
	ZoneCommand.currentZoneIndex = 1000
	ZoneCommand.allZones = {}
	ZoneCommand.buildSpeed = Config.buildSpeed
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
		obj.sabotageDebt = 0
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
		ZoneCommand.allZones[obj.name] = obj
		return obj
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

	function ZoneCommand.getClosestZoneToPoint(point, side, invert)
		local minDist = 9999999
		local closest = nil
		for i,v in pairs(ZoneCommand.allZones) do
			if not side or (not invert and side == v.side) or (invert and side ~= v.side) then
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

	function ZoneCommand:getProductOfType(type, mistype)
		local prods = {}
		for i,v in ipairs(self.upgrades) do
			if v.type == type then 
				prods[v.name] = v
			end

			for i2,v2 in ipairs(v) do
				for i3,v3 in ipairs(v2.products) do
					if v3.type == type then
						if mistype then 
							if v3.missionType == mistype then
								prods[v3.name] = v3
							end
						else
							prods[v3.name] = v3
						end
					end
				end
			end
		end

		for _,v in pairs(prods) do
			if not StrategicAI.isProductBuilt(v) then
				return v
			end
		end
	end

	function ZoneCommand:pushMisOfType(mistype) 
		local aimises = {}
		for i,v in ipairs(self.upgrades) do
			for i2,v2 in ipairs(v) do
				for i3,v3 in ipairs(v2.products) do
					if v3.type == 'mission' then 
						if v3.missionType == mistype then
							aimises[v3.name] = v3
						end
					end
				end
			end
		end

		for _,v in pairs(aimises) do
			if not StrategicAI.isProductBuilt(v) then
				StrategicAI.pushResource(v)
				break
			end
		end
	end

	function ZoneCommand:canSupply(target, type, amount)
		if target.side~=0 and self.side ~= target.side then return false end

		if self:criticalOnSupplies() then return false end

		--if self.resource - amount <= self.spendTreshold then return false end

		if target.side ~= 0 then
			if target:criticalOnSupplies() then
				if self.distToFront < target.distToFront then return false end
			else
				if self.distToFront <= target.distToFront then return false end
			end

			if (self.resource*2) < target.resource then return false end
		end
		
		if self.resource < amount then return false end
		
		if type=='air' then
			local dist = mist.utils.get2DDist(self.zone.point, target.zone.point)
			if dist > 50000 then return false end
		elseif type=='convoy' then
			if not self.neighbours[target.name] then return false end
			if DependencyManager.get("ConnectionManager"):isRoadBlocked(self.name, target.name) then return false end
		elseif type=='transfer' and target.side == self.side then
			if not self.neighbours[target.name] then return false end
		end

		return true
	end

	function ZoneCommand:canAttack(target, type)
		if target.side == self.side then return false end

		if type=='assault' then
			if not self.neighbours[target.name] then return false end
			if DependencyManager.get("ConnectionManager"):isRoadBlocked(self.name, target.name) then return false end
		elseif type=='cas_helo' then
			local dist = mist.utils.get2DDist(self.zone.point, target.zone.point)
			if dist > 50000 then return false end
		end

		return true
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
		self.sabotageDebt = damagedResources
		self:refreshText()
	end

	local function missionToSymbol(type)
		if type == ZoneCommand.missionTypes.supply_transfer then return 'x' end
		if type == ZoneCommand.missionTypes.supply_air then return 's' end
		if type == ZoneCommand.missionTypes.supply_convoy then return 's' end
		if type == ZoneCommand.missionTypes.assault then return 't' end
		if type == ZoneCommand.missionTypes.awacs then return 'a' end
		if type == ZoneCommand.missionTypes.cas then return 'c' end
		if type == ZoneCommand.missionTypes.cas_helo then return 'c' end
		if type == ZoneCommand.missionTypes.patrol then return 'f' end
		if type == ZoneCommand.missionTypes.sead then return 'r' end
		if type == ZoneCommand.missionTypes.strike then return 'b' end
		if type == ZoneCommand.missionTypes.tanker then return 'g' end

		return 'o'
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

		if self.sabotageDebt > 0 then
			build = '\n[Sabotaged]'
			mBuild = ''
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

		local readyToDeploy = ''
		if Config.showInventory and self.side ~= 0 then
			for i,v in pairs(StrategicAI.resources[self.side]) do
				if v.owner.name == self.name then
					readyToDeploy = readyToDeploy..missionToSymbol(v.missionType)
				end
			end
		end

		--trigger.action.setMarkupColor(1000+self.index, color)
		trigger.action.setMarkupColor(2000+self.index, color)

		local label = '['..self.resource..'/'..self.maxResource..']'..status..build..mBuild

		if #readyToDeploy > 0 then
			label = label..'\n'..readyToDeploy
		end

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
	end
	
	function ZoneCommand:removeResource(amount)
		self.resource = self.resource-amount
		self.resource = math.floor(math.max(self.resource, 0))
	end

	function ZoneCommand:reveal(time)
		local revtime = 60
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

				--trigger.action.outText(self.name.." has been captured by "..sidetxt, 15)
				
				local sourcePos = {
					x = self.zone.point.x,
					y = 9144,
					z = self.zone.point.z,
				}

				if side == 1 then
					if math.random()>0.5 then
						TransmissionManager.queueMultiple({'zones.events.capturedbythem.1','zones.names.'..self.name}, TransmissionManager.radios.command, sourcePos)
					else
						TransmissionManager.queueMultiple({'zones.names.'..self.name,'zones.events.capturedbythem.2'}, TransmissionManager.radios.command, sourcePos)
					end
				elseif side == 2 then
					if math.random()>0.5 then
						TransmissionManager.queueMultiple({'zones.events.capturedbyus.1','zones.names.'..self.name}, TransmissionManager.radios.command, sourcePos)
					else
						TransmissionManager.queueMultiple({'zones.names.'..self.name, 'zones.events.capturedbyus.2'}, TransmissionManager.radios.command, sourcePos)
					end
				end
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

				--trigger.action.outText(sidetxt.." has lost control of "..self.name, 15)
				local sourcePos = {
					x = self.zone.point.x,
					y = 9144,
					z = self.zone.point.z,
				}

				if self.side == 2 then
					if math.random()>0.5 then
						TransmissionManager.queueMultiple({'zones.events.lost.1', 'zones.names.'..self.name}, TransmissionManager.radios.command, sourcePos)
					else
						TransmissionManager.queueMultiple({'zones.names.'..self.name, 'zones.events.lost.2'}, TransmissionManager.radios.command, sourcePos)
					end
				elseif self.side == 1 then
					if math.random()>0.5 then
						TransmissionManager.queueMultiple({'zones.events.lostbythem.1', 'zones.names.'..self.name}, TransmissionManager.radios.command, sourcePos)
					else
						TransmissionManager.queueMultiple({'zones.names.'..self.name, 'zones.events.lostbythem.2'}, TransmissionManager.radios.command, sourcePos)
					end
				end

				self:setSide(0)
				self.sabotageDebt = 0
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
	
	function ZoneCommand:progressBuild()
		self:progressMainBuild()
		self:progressMissionBuild()
	end

	function ZoneCommand:progressMainBuild()
		if not self.currentBuild then return end

		if self.currentBuild and self.currentBuild.product.side ~= self.side then
			env.info('ZoneCommand:progressBuild '..self.name..' - stopping build, zone changed owner')
			self.currentBuild = nil
			return
		end

		if not self:canBuildProduct(self.currentBuild.product) then 
			env.info('ZoneCommand:progressBuild '..self.name..' - stopping build, zone lost ability to build current product')
			self.currentBuild = nil
			return
		end

		if self.currentBuild then
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
					if step > self.resource then step = 1 end
					
					if step <= self.resource then
						self:removeResource(step)

						if self.sabotageDebt > 0 then
							self.sabotageDebt = math.max(self.sabotageDebt - step, 0)
							env.info('ZoneCommand:progressBuild - '..self.name..' consumed '..step..' resources for sabotage repair, remaining '..self.sabotageDebt)
						else
							local actualStep = step
							if self.currentBuild.product.type == 'mission' then
								local progress = step*self.missionBuildSpeedReduction
								actualStep = math.max(1, math.floor(progress))
							end

							self.currentBuild.progress = self.currentBuild.progress + actualStep
							
							if self.extraBuildResources > 0 then
								local extrastep = step
								if self.extraBuildResources < extrastep then
									extrastep = self.extraBuildResources
								end
								
								self.extraBuildResources = math.max(self.extraBuildResources - extrastep, 0)

								local actualExtraStep = extrastep
								if self.currentBuild.product.type == 'mission' then
									local progress = extrastep*self.missionBuildSpeedReduction
									actualExtraStep = math.max(1, math.floor(progress))
								end
								self.currentBuild.progress = self.currentBuild.progress + actualExtraStep
								
								env.info('ZoneCommand:progressBuild - '..self.name..' consumed '..extrastep..' extra resources, remaining '..self.extraBuildResources)
							end
						end
					end
				end
			else
				if self.currentBuild.product.type == 'mission' then
					StrategicAI.pushResource(self.currentBuild.product)
				elseif self.currentBuild.product.type == 'defense' or self.currentBuild.product.type == 'upgrade' then
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

	function ZoneCommand:progressMissionBuild()
		if not self.currentMissionBuild then return end

		if self.sabotageDebt > 0 then return end

		if self.currentMissionBuild and self.currentMissionBuild.product.side ~= self.side then
			env.info('ZoneCommand:progressBuild '..self.name..' - stopping mission build, zone changed owner')
			self.currentMissionBuild = nil
			return
		end

		if not self:canBuildProduct(self.currentMissionBuild.product) then 
			env.info('ZoneCommand:progressBuild '..self.name..' - stopping build, zone lost ability to build current product')
			self.currentMissionBuild = nil
			return
		end

		local cost = self.currentMissionBuild.product.cost
			
		if self.currentMissionBuild.progress < cost then
			local step = math.floor(ZoneCommand.buildSpeed * self.boostScale)

			if step > self.resource then step = 1 end

			local progress = step*self.missionBuildSpeedReduction
			local reducedCost = math.max(1, math.floor(progress))
			if reducedCost <= self.resource and self.sabotageDebt == 0 then
				self:removeResource(reducedCost)
				self.currentMissionBuild.progress = self.currentMissionBuild.progress + progress
			end
		else
			StrategicAI.pushResource(self.currentMissionBuild.product)
			self.currentMissionBuild = nil
		end
	end
	
	function ZoneCommand:queueBuild(product, isRepair, progress)

		local mainQueueTypes = {
			[ZoneCommand.productTypes.upgrade] = true,
			[ZoneCommand.productTypes.defense] = true,
		}
		
		local supplyTypes = {
			[ZoneCommand.missionTypes.supply_air] = true,
			[ZoneCommand.missionTypes.supply_convoy] = true,
			[ZoneCommand.missionTypes.supply_transfer] = true,
		}

		if not self:canBuildProduct(product) then return false end
		
		if mainQueueTypes[product.type] or (product.type==ZoneCommand.productTypes.mission and supplyTypes[product.missionType]) and self.currentBuild==nil then
			local unitcount = nil
			if isRepair then
				local g = Group.getByName(product.name)
				if g then
					unitcount = g:getSize()
					env.info('ZoneCommand:queueBuild - '..self.name..' '..product.name..' has '..unitcount..' units')
				end
			end

			self.currentBuild = { product = product, progress = (progress or 0), isRepair = isRepair, unitcount = unitcount}
			env.info('ZoneCommand:queueBuild - '..self.name..' starting '..product.name..'('..product.display..') as its build')
			return true
		elseif product.type == ZoneCommand.productTypes.mission and not supplyTypes[product.missionType] and self.currentMissionBuild==nil then
			self.currentMissionBuild = { product = product, progress = (progress or 0)}
			env.info('ZoneCommand:queueBuild - '..self.name..' starting '..product.name..'('..product.display..') as its mission build')
			return true
		end
	end

	function ZoneCommand:requirementsMet(product)
		for _,v in ipairs(self.upgrades[self.side]) do
			local u = Group.getByName(v.name)
			if not u then u = StaticObject.getByName(v.name) end
			
			if not u then
				if v.name == product.name then
					return true
				end
			elseif u ~= nil then
				for _,v2 in ipairs(v.products) do
					if v2.name == product.name then
						return true
					end
				end
			end
		end

		return false
	end

	function ZoneCommand:canBuildProduct(product)
		if product.side ~= self.side then return false end

		if product.type == ZoneCommand.productTypes.upgrade then
			if self.built[product.name] == nil then return self:requirementsMet(product) end
		elseif product.type == ZoneCommand.productTypes.defense then
			if self.built[product.name] == nil then
				return self:requirementsMet(product)
			else
				local g = Group.getByName(product.name)
				if g and g:isExist() and g:getSize() < g:getInitialSize() then
					return self:requirementsMet(product)
				end
			end
		elseif product.type == ZoneCommand.productTypes.mission then
			if not StrategicAI.isProductBuilt(product) then
				return self:requirementsMet(product)
			end
		end

		return false
	end

	function ZoneCommand:canBuild()
		if not self.currentBuild then return true end
	end

	function ZoneCommand:canMissionBuild()
		if not self.keepActive and self.mode ~= 'normal' then return false end
		if self.currentMissionBuild then return false end

		return true
	end

	function ZoneCommand:isNeighbour(zone)
		return self.neighbours[zone.name] ~= nil
	end

	function ZoneCommand:hasEnemySAMRadar(myside)
		if myside == 1 then
			return self:hasSAMRadarOnSide(2)
		elseif myside == 2 then
			return self:hasSAMRadarOnSide(1)
		end
	end

	function ZoneCommand:hasEnemyDefense(myside)
		for i,v in pairs(self.built) do
			if v.type == ZoneCommand.productTypes.defense and v.side ~= myside then 
				return true
			end
		end
	end

	function ZoneCommand:hasEnemyStructure(myside)
		for i,v in pairs(self.built) do
			if v.type == ZoneCommand.productTypes.upgrade and v.side ~= myside then 
				return true
			end
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
	
	function ZoneCommand:defineUpgrades(upgrades)
		self.upgrades = upgrades
		
		for side,sd in ipairs(self.upgrades) do
			for _,v in ipairs(sd) do
				v.side = side
				v.owner = self
				
				local cat = nil
				if v.template then
					cat = TemplateDB.getData(v.template)
				elseif v.templates then
					cat = TemplateDB.getData(v.templates[1])
				end

				if cat.dataCategory == TemplateDB.type.static then
					ZoneCommand.staticRegistry[v.name] = true
				end
				
				for _,v2 in ipairs(v.products) do
					v2.side = side
					v2.owner = self

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

	function ZoneCommand:getAllProducts()
		local flatList = {}
		for i,v in ipairs(self.upgrades) do
			for i2,v2 in ipairs(v) do
				flatList[v2.name] = v2
				for i3,v3 in ipairs(v2.products) do
					flatList[v3.name] = v3
				end
			end
		end

		return flatList
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




