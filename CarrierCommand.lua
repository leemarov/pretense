
CarrierCommand = {}
do
    CarrierCommand.allCarriers = {}
	CarrierCommand.currentIndex = 6000
    CarrierCommand.isCarrier = true

	CarrierCommand.supportTypes = {
		strike = 'Strike',
		cap = 'CAP',
		awacs = 'AWACS',
		tanker = 'Tanker',
		transport = 'Transport',
		mslstrike = 'Cruise Missiles'
	}

	CarrierCommand.supportStates = {
		takeoff = 'takeoff',
		inair = 'inair',
		landed = 'landed',
		none = 'none'
	}

	CarrierCommand.blockedDespawnTime = 10*60
	CarrierCommand.recoveryReduction = 0.8
	CarrierCommand.landedDespawnTime = 10
    
    function CarrierCommand:new(name, range, navmap, radioConfig, maxResource)
        local unit = Unit.getByName(name)
        if not unit then return end

        local obj = {}
        obj.name = name
        obj.range = range
        obj.side = unit:getCoalition()
        obj.resource = maxResource or 30000
        obj.maxResource = maxResource or 30000
		obj.spendTreshold = 500
        obj.revealTime = 0
        obj.isHeloSpawn = true
        obj.isPlaneSpawn = true
		obj.supportFlights = {}
		obj.extraSupports = {}
		obj.weaponStocks = {}
		
		obj.navigation = {
			currentWaypoint = nil,
			waypoints = {},
			loop = true
		}

		obj.navmap = navmap
        
        obj.tacan = radioConfig.tacan
        obj.icls = radioConfig.icls
        obj.acls = radioConfig.acls
        obj.link4 = radioConfig.link4
        obj.radio = radioConfig.radio

        obj.spawns = {}
		for i,v in pairs(mist.DBs.groupsByName) do
			if v.units[1].skill == 'Client' then
				local pos3d = {
					x = v.units[1].point.x,
					y = 0,
					z = v.units[1].point.y
				}
				
				if Utils.isInCircle(pos3d, unit:getPoint(), obj.range)then
					table.insert(obj.spawns, {name=i})
				end
			end
		end

        obj.index = CarrierCommand.currentIndex
		CarrierCommand.currentIndex = CarrierCommand.currentIndex + 1

        local point = unit:getPoint()

        local color = {0.7,0.7,0.7,0.3}
		if obj.side == 1 then
			color = {1,0,0,0.3}
		elseif obj.side == 2 then
			color = {0,0,1,0.3}
		end

        trigger.action.circleToAll(-1,3000+obj.index,point, obj.range, color, color, 1)
        
        point.z = point.z + obj.range
        trigger.action.textToAll(-1,2000+obj.index, point, {0,0,0,0.8}, {1,1,1,0.5}, 15, true, '')
		
        setmetatable(obj, self)
		self.__index = self

        obj:start()
        obj:refreshText()
        obj:refreshSpawnBlocking()
		CarrierCommand.allCarriers[obj.name] = obj
        return obj
    end

	function CarrierCommand:setupRadios()
		local unit = Unit.getByName(self.name)
		TaskExtensions.setupCarrier(unit, self.icls, self.acls, self.tacan, self.link4, self.radio)
	end

    function CarrierCommand:start()
		self:setupRadios()

        timer.scheduleFunction(function(param, time)
            local self = param.context
            local unit = Unit.getByName(self.name)
            if not unit then
				self:clearDrawings()
				local gr = Group.getByName(self.name)
				if gr and gr:isExist() then
					TaskExtensions.stopCarrier(gr)
				end
				return
			end
			
			self:updateNavigation()
			self:updateSupports()
            self:refreshText()
            return time+10
        end, {context = self}, timer.getTime()+1)
    end

	function CarrierCommand:clearDrawings()
		if not self.cleared then
			trigger.action.removeMark(2000+self.index)
			trigger.action.removeMark(3000+self.index)
			self.cleared = true
		end
	end

	function CarrierCommand:updateSupports()
		for _, data in pairs(self.supportFlights) do
			self:processAir(data)
		end

		
		for wep, stock in pairs(self.weaponStocks) do
			local gr = Unit.getByName(self.name):getGroup()
			local realstock = Utils.getAmmo(gr, wep)
			self.weaponStocks[wep] = math.min(stock, realstock)	
		end
	end

	local function setState(group, state)
		group.state = state
		group.lastStateTime = timer.getAbsTime()
	end

	local function isAttack(group)
		if group.type == CarrierCommand.supportTypes.cap then return true end
		if group.type == CarrierCommand.supportTypes.strike then return true end
	end

	local function hasWeapons(group)
		for _,un in ipairs(group:getUnits()) do
			local wps = un:getAmmo()
			if wps then
				for _,w in ipairs(wps) do
					if w.desc.category ~= 0 and w.count > 0 then
						return true
					end
				end
			end
		end
	end

	function CarrierCommand:processAir(group)
		local carrier = Unit.getByName(self.name)
		if not carrier or not carrier:isExist() then return end

		local gr = Group.getByName(group.name)
		if not gr or not gr:isExist() then
			if group.state ~= CarrierCommand.supportStates.none then
				setState(group, CarrierCommand.supportStates.none)
				group.returning = false
				env.info('CarrierCommand: processAir ['..group.name..'] does not exist state=none')
			end
			return
		end
		
		if gr:getSize() == 0 then
			gr:destroy()
			setState(group, CarrierCommand.supportStates.none)
			group.returning = false
			env.info('CarrierCommand: processAir ['..group.name..'] has no members state=none')
			return
		end

		if group.state == CarrierCommand.supportStates.none then
			setState(group, CarrierCommand.supportStates.takeoff)
			env.info('CarrierCommand: processAir ['..group.name..'] started existing state=takeoff')
		elseif group.state == CarrierCommand.supportStates.takeoff then
			if timer.getAbsTime() - group.lastStateTime > CarrierCommand.blockedDespawnTime then
				if gr and gr:getSize()>0 and gr:getUnit(1):isExist() then
					local frUnit = gr:getUnit(1)
					local cz = CarrierCommand.getCarrierOfUnit(frUnit:getName())
					if Utils.allGroupIsLanded(gr, cz ~= nil) then
						env.info('CarrierCommand: processAir ['..group.name..'] is blocked, despawning')
						local frUnit = gr:getUnit(1)
						if frUnit then
							local firstUnit = frUnit:getName()
							local z = ZoneCommand.getZoneOfUnit(firstUnit)
							if not z then 
								z = CarrierCommand.getCarrierOfUnit(firstUnit)
							end
							if z then
								z:addResource(group.cost)
								env.info('CarrierCommand: processAir ['..z.name..'] has recovered ['..group.cost..'] from ['..group.name..']')
							end
						end

						gr:destroy()
						setState(group, CarrierCommand.supportStates.none)
						group.returning = false
						env.info('CarrierCommand: processAir ['..group.name..'] has been removed due to being blocked state=none')
						return
					end
				end
			elseif gr and Utils.someOfGroupInAir(gr) then
				env.info('CarrierCommand: processAir ['..group.name..'] is in the air state=inair')
				setState(group, CarrierCommand.supportStates.inair)
			end
		elseif group.state == CarrierCommand.supportStates.inair then
			if gr and gr:getSize()>0 and gr:getUnit(1) and gr:getUnit(1):isExist() then
				local frUnit = gr:getUnit(1)
				local cz = CarrierCommand.getCarrierOfUnit(frUnit:getName())
				if Utils.allGroupIsLanded(gr, cz ~= nil) then
					env.info('CarrierCommand: processAir ['..group.name..'] has landed state=landed')
					setState(group, CarrierCommand.supportStates.landed)

					local unit = gr:getUnit(1)
					if unit then
						local firstUnit = unit:getName()
						local z = ZoneCommand.getZoneOfUnit(firstUnit)
						if not z then 
							z = CarrierCommand.getCarrierOfUnit(firstUnit)
						end
						
						if group.type == CarrierCommand.supportTypes.transport then
							if z then
								z:capture(gr:getCoalition())
								z:addResource(group.cost)
								env.info('CarrierCommand: processAir ['..group.name..'] has supplied ['..z.name..'] with ['..group.cost..']')
							end
						else
							if z and z.side == gr:getCoalition() then
								local percentSurvived = gr:getSize()/gr:getInitialSize()
								local torecover = math.floor(group.cost * percentSurvived * CarrierCommand.recoveryReduction)
								z:addResource(torecover)
								env.info('CarrierCommand: processAir ['..z.name..'] has recovered ['..torecover..'] from ['..group.name..']')
							end
						end
					else
						env.info('CarrierCommand: processAir ['..group.name..'] size ['..gr:getSize()..'] has no unit 1')
					end
				else
					if isAttack(group) and not group.returning then
						if not hasWeapons(gr) then
							env.info('CarrierCommand: processAir ['..group.name..'] size ['..gr:getSize()..'] has no weapons outside of shells')
							group.returning = true

							local point = carrier:getPoint()
							TaskExtensions.landAtAirfield(gr, {x=point.x, y=point.z})
							local cnt = gr:getController()
							cnt:setOption(0,4) -- force ai hold fire
							cnt:setOption(1, 4) -- force reaction on threat to allow abort
						end
					elseif group.type == CarrierCommand.supportTypes.transport then
						if not group.returning and group.target and group.target.side ~= self.side and group.target.side ~= 0 then
							group.returning = true
							local point = carrier:getPoint()
							TaskExtensions.landAtPointFromAir(gr,  {x=point.x, y=point.z}, group.altitude)
							env.info('CarrierCommand: processAir ['..group.name..'] returning home due to invalid target')
						end
					end
				end
			end
		elseif group.state == CarrierCommand.supportStates.landed then
			if timer.getAbsTime() - group.lastStateTime > CarrierCommand.landedDespawnTime then
				if gr then
					gr:destroy()
					setState(group, CarrierCommand.supportStates.none)
					group.returning = false
					env.info('CarrierCommand: processAir ['..group.name..'] despawned after landing state=none')
					return true
				end
			end
		end
	end

	function CarrierCommand:setWaypoints(wplist)
		self.navigation.waypoints = wplist
		self.navigation.currentWaypoint = nil
		self.navigation.nextWaypoint = 1
		self.navigation.loop = #wplist > 1
	end

	function CarrierCommand:updateNavigation()
		local unit = Unit.getByName(self.name)

		if self.navigation.nextWaypoint then
			local dist = 0
			if self.navigation.currentWaypoint then
				local tgzn = self.navigation.waypoints[self.navigation.currentWaypoint]
				local point = CustomZone:getByName(tgzn).point
				dist = mist.utils.get2DDist(unit:getPoint(), point)
			end

			if dist<2000 then
				self.navigation.currentWaypoint = self.navigation.nextWaypoint

				local tgzn = self.navigation.waypoints[self.navigation.currentWaypoint]
				local point = CustomZone:getByName(tgzn).point
				env.info("CarrierCommand - sending "..self.name.." to "..tgzn.." x"..point.x.." z"..point.z)
				TaskExtensions.carrierGoToPos(unit:getGroup(), point)

				if self.navigation.loop then
					self.navigation.nextWaypoint = self.navigation.nextWaypoint + 1
					if self.navigation.nextWaypoint > #self.navigation.waypoints then
						self.navigation.nextWaypoint = 1
					end
				else
					self.navigation.nextWaypoint = nil
				end
			end
		else
			local dist = 9999999
			if self.navigation.currentWaypoint then
				local tgzn = self.navigation.waypoints[self.navigation.currentWaypoint]
				local point = CustomZone:getByName(tgzn).point
				dist = mist.utils.get2DDist(unit:getPoint(), point)
			end

			if dist<2000 then
				env.info("CarrierCommand - "..self.name.." stopping after reached waypoint")
				TaskExtensions.stopCarrier(unit:getGroup())
				self.navigation.currentWaypoint = nil
			end
		end
	end

	function CarrierCommand:addSupportFlight(name, cost, type, data)
		self.supportFlights[name] = { 
			name = name, 
			cost = cost, 
			type = type, 
			target = nil,
			state = CarrierCommand.supportStates.none, 
			lastStateTime = timer.getAbsTime(),
			carrier = self
		}

		for i,v in pairs(data) do
			self.supportFlights[name][i] = v
		end

		local gr = Group.getByName(name)
		if gr then gr:destroy() end
	end

	function CarrierCommand:addExtraSupport(name, cost, type, data)
		self.extraSupports[name] = { 
			name = name, 
			cost = cost, 
			type = type, 
			target = nil,
			carrier = self
		}

		for i,v in pairs(data) do
			self.extraSupports[name][i] = v
		end
	end

	function CarrierCommand:setWPStock(wpname, amount)
		self.weaponStocks[wpname] = amount
	end

	function CarrierCommand:callExtraSupport(data, groupname)
		local playerGroup = Group.getByName(groupname)
		if not playerGroup then return end

		if self.resource < data.cost then
			trigger.action.outTextForGroup(playerGroup:getID(), self.name..' does not have enough resources for '..data.name, 10)
			return
		end

		local cru = Unit.getByName(self.name)
		if not cru or not cru:isExist() then return end

		local crg = cru:getGroup()

		local ammo = self.weaponStocks[data.wpType] or 0
		if ammo < data.salvo then
			trigger.action.outTextForGroup(playerGroup:getID(), data.name..' is not available at this time.', 10)
			return
		end

		local success = MenuRegistry.showTargetZoneMenu(playerGroup:getID(), "Select "..data.name..'('..data.type..") target", function(params)
			local cru = Unit.getByName(params.data.carrier.name)
			if not cru or not cru:isExist() then return end
			local crg = cru:getGroup()

			TaskExtensions.fireAtTargets(crg, params.zone.built, params.data.salvo)
			if params.data.carrier.weaponStocks[params.data.wpType] then
				params.data.carrier.weaponStocks[params.data.wpType] = params.data.carrier.weaponStocks[params.data.wpType] - params.data.salvo
			end
		end, 1, nil, data, nil, true)

		if success then
			self:removeResource(data.cost)
			trigger.action.outTextForGroup(playerGroup:getID(), 'Select target for '..data.name..' ('..data.type..') from radio menu.', 10)
		else
			trigger.action.outTextForGroup(playerGroup:getID(), 'No valid targets for '..data.name..' ('..data.type..')', 10)
		end
	end

	function CarrierCommand:callSupport(data, groupname)
		local playerGroup = Group.getByName(groupname)
		if not playerGroup then return end

		if Group.getByName(data.name) and (timer.getAbsTime() - data.lastStateTime < 60*60) then 
			trigger.action.outTextForGroup(playerGroup:getID(), data.name..' tasking is not available at this time.', 10)
			return
		end

		if self.resource < data.cost then
			trigger.action.outTextForGroup(playerGroup:getID(), self.name..' does not have enough resources to deploy '..data.name, 10)
			return
		end
		
		local targetCoalition = nil
		local minDistToFront = nil
		local includeCarriers = nil
		local onlyRevealed = nil

		if data.type == CarrierCommand.supportTypes.strike then
			targetCoalition = 1
			onlyRevealed = true
		elseif data.type == CarrierCommand.supportTypes.cap then
			minDistToFront = 1
			includeCarriers = true
		elseif data.type == CarrierCommand.supportTypes.awacs then
			targetCoalition = 2
			includeCarriers = true
		elseif data.type == CarrierCommand.supportTypes.tanker then
			targetCoalition = 2
			includeCarriers = true
		elseif data.type == CarrierCommand.supportTypes.transport then
			targetCoalition = {0,2}
		end
		
		local success = MenuRegistry.showTargetZoneMenu(playerGroup:getID(), "Select "..data.name..'('..data.type..") target", function(params)
			CarrierCommand.spawnSupport(params.data, params.zone)
			trigger.action.outTextForGroup(params.groupid, params.data.name..'('..params.data.type..') heading to '..params.zone.name, 10)
		end, targetCoalition, minDistToFront, data, includeCarriers, onlyRevealed)

		if success then
			self:removeResource(data.cost)
			trigger.action.outTextForGroup(playerGroup:getID(), 'Select target for '..data.name..' ('..data.type..') from radio menu.', 10)
		else
			trigger.action.outTextForGroup(playerGroup:getID(), 'No valid targets for '..data.name..' ('..data.type..')', 10)
		end
	end

	local function getDefaultPos(savedData)
		local action = 'Turning Point'
		local speed = 250

		local vars = {
			groupName = savedData.name,
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

	function CarrierCommand.spawnSupport(data, target, saveData)
		data.target = target

		if saveData then
			mist.teleportToPoint(getDefaultPos(saveData))
			data.state = saveData.state
			data.lastStateTime = timer.getAbsTime() - saveData.lastStateDuration
			data.returning = saveData.returning
		else
			mist.respawnGroup(data.name, true)
		end

		if data.type == CarrierCommand.supportTypes.strike then
			CarrierCommand.dispatchStrike(data, saveData~=nil)
		elseif data.type == CarrierCommand.supportTypes.cap then
			CarrierCommand.dispatchCap(data, saveData~=nil)
		elseif data.type == CarrierCommand.supportTypes.awacs then
			CarrierCommand.dispatchAwacs(data, saveData~=nil)
		elseif data.type == CarrierCommand.supportTypes.tanker then
			CarrierCommand.dispatchTanker(data, saveData~=nil)
		elseif data.type == CarrierCommand.supportTypes.transport then
			CarrierCommand.dispatchTransport(data, saveData~=nil)
		end
	end

	function CarrierCommand.dispatchStrike(data, isReactivated)
		timer.scheduleFunction(function(param)
			local gr = Group.getByName(param.data.name)
			local homePos = nil
			local carrier = Unit.getByName(param.data.carrier.name)
			if carrier and isReactivated then
				homePos = { homePos = carrier:getPoint() }
			end
			env.info('CarrierCommand - sending '..param.data.name..' to '..param.data.target.name)
			
			local targets = {}
			for i,v in pairs(param.data.target.built) do
				if v.type == 'upgrade' and v.side ~= gr:getCoalition() then
					local tg = TaskExtensions.getTargetPos(v.name)
					table.insert(targets, tg)
				end
			end

			if #targets == 0 then 
				gr:destroy()
				return 
			end

			local choice = targets[math.random(1, #targets)]
			TaskExtensions.executePinpointStrikeMission(gr, choice, AI.Task.WeaponExpend.ALL, param.data.altitude, homePos, carrier:getID())
		end, {data = data}, timer.getTime()+1)
	end

	function CarrierCommand.dispatchCap(data, isReactivated)
		timer.scheduleFunction(function(param)
			local gr = Group.getByName(param.data.name)

			local homePos = nil
			local carrier = Unit.getByName(param.data.carrier.name)
			if carrier and isReactivated  then
				homePos = { homePos = carrier:getPoint() }
			end

			local point = nil
			if param.data.target.isCarrier then
				point = Unit.getByName(param.data.target.name):getPoint()
			else
				point = trigger.misc.getZone(param.data.target.name).point
			end

			TaskExtensions.executePatrolMission(gr, point, param.data.altitude, param.data.range, homePos, carrier:getID())
		end, {data = data}, timer.getTime()+1)
	end

	function CarrierCommand.dispatchAwacs(data, isReactivated)		
		timer.scheduleFunction(function(param)
			local gr = Group.getByName(param.data.name)

			local homePos = nil
			local carrier = Unit.getByName(param.data.carrier.name)
			if carrier and isReactivated  then
				homePos = { homePos = carrier:getPoint() }
			end
			
			local un = gr:getUnit(1)
			if un then 
				local callsign = un:getCallsign()
				RadioFrequencyTracker.registerRadio(param.data.name, '[AWACS] '..callsign, param.data.freq..' AM')
			end

			local point = nil
			if param.data.target.isCarrier then
				point = Unit.getByName(param.data.target.name):getPoint()
			else
				point = trigger.misc.getZone(param.data.target.name).point
			end

			TaskExtensions.executeAwacsMission(gr, point, param.data.altitude, param.data.freq, homePos, carrier:getID())
		end, {data = data}, timer.getTime()+1)
	end

	function CarrierCommand.dispatchTanker(data, isReactivated)
		timer.scheduleFunction(function(param)
			local gr = Group.getByName(param.data.name)

			local homePos = nil
			local carrier = Unit.getByName(param.data.carrier.name)
			if carrier and isReactivated  then
				homePos = { homePos = carrier:getPoint() }
			end

			local un = gr:getUnit(1)
			if un then 
				local callsign = un:getCallsign()
				RadioFrequencyTracker.registerRadio(param.data.name, '[Tanker(Drogue)] '..callsign, param.data.freq..' AM | TCN '..param.data.tacan..'X')
			end
			
			local point = nil
			if param.data.target.isCarrier then
				point = Unit.getByName(param.data.target.name):getPoint()
			else
				point = trigger.misc.getZone(param.data.target.name).point
			end

			TaskExtensions.executeTankerMission(gr, point, param.data.altitude, param.data.freq, param.data.tacan, homePos, carrier:getID())
		end, {data = data}, timer.getTime()+1)
	end

	function CarrierCommand.dispatchTransport(data, isReactivated)
		timer.scheduleFunction(function(param)
			local gr = Group.getByName(param.data.name)

			local supplyPoint = trigger.misc.getZone(param.data.target.name..'-hsp')
			if not supplyPoint then
				supplyPoint = trigger.misc.getZone(param.data.target.name)
			end
			
			local point = { x=supplyPoint.point.x, y = supplyPoint.point.z}
			TaskExtensions.landAtPoint(gr, point, param.data.altitude, true)
		end, {data = data}, timer.getTime()+1)
	end

	function CarrierCommand:showInformation(groupname)
		local gr = Group.getByName(groupname)
        if gr then 
			local msg = '['..self.name..']'
			if self.radio then msg = msg..'\n Radio: '..string.format('%.3f',self.radio/1000000)..' AM' end
			if self.tacan then msg = msg..'\n TACAN: '..self.tacan.channel..'X ('..self.tacan.callsign..')' end
			if self.link4 then msg = msg..'\n Link4: '..string.format('%.3f',self.link4/1000000) end
			if self.icls then msg = msg..'\n ICLS: '..self.icls end

			if Utils.getTableSize(self.supportFlights) > 0 then
				local flights = {}
				for _, data in pairs(self.supportFlights) do
					if (data.state == CarrierCommand.supportStates.none or (timer.getAbsTime()-data.lastStateTime >= 60*60)) and data.cost <= self.resource then
						table.insert(flights, data)
					end
				end
				
				table.sort(flights, function(a,b) return a.name<b.name end)
				
				if #flights > 0 then
					msg = msg..'\n\n Available for tasking:'
					for _,data in ipairs(flights) do
						msg = msg..'\n    '..data.name..' ('..data.type..') ['..data.cost..']'
					end
				end
			end

			if Utils.getTableSize(self.extraSupports) > 0 then
				local extras = {}
				for _, data in pairs(self.extraSupports) do
					if data.cost <= self.resource then
						if data.type == CarrierCommand.supportTypes.mslstrike then
							local cru = Unit.getByName(self.name)
							if cru and cru:isExist() then
								local crg = cru:getGroup()
								local remaining = self.weaponStocks[data.wpType] or 0
								if remaining > data.salvo then
									table.insert(extras, data)
								end
							end
						end
					end
				end
				
				table.sort(extras, function(a,b) return a.name<b.name end)
				
				if #extras > 0 then
					msg = msg..'\n\n Other:'
					for _,data in ipairs(extras) do
						if data.type == CarrierCommand.supportTypes.mslstrike then
							local cru = Unit.getByName(self.name)
							if cru and cru:isExist() then
								local crg = cru:getGroup()
								local remaining = self.weaponStocks[data.wpType] or 0
								if remaining > data.salvo then
									remaining = math.floor(remaining/data.salvo)
									msg = msg..'\n    '..data.name..' ('..data.type..') ['..data.cost..'] ('..remaining..' left)'
								end
							end
						end
					end
				end
			end

            trigger.action.outTextForGroup(gr:getID(), msg, 20)
		end
	end

    function CarrierCommand:addResource(amount)
		self.resource = self.resource+amount
		self.resource = math.floor(math.min(self.resource, self.maxResource))
        self:refreshSpawnBlocking()
        self:refreshText()
    end

    function CarrierCommand:removeResource(amount)
		self.resource = self.resource-amount
		self.resource = math.floor(math.max(self.resource, 0))
        self:refreshSpawnBlocking()
        self:refreshText()
    end

    function CarrierCommand:refreshSpawnBlocking()
		for _,v in ipairs(self.spawns) do
			trigger.action.setUserFlag(v.name, self.resource < Config.carrierSpawnCost)
		end
	end

    function CarrierCommand:refreshText()		
        local build = ''
		local mBuild = ''
		
		local status=''
		if self:criticalOnSupplies() then
			status = '(!)'
		end

		local color = {0.3,0.3,0.3,1}
		if self.side == 1 then
			color = {0.7,0,0,1}
		elseif self.side == 2 then
			color = {0,0,0.7,1}
		end

		trigger.action.setMarkupColor(2000+self.index, color)

		local label = '['..self.resource..'/'..self.maxResource..']'..status..build..mBuild

		if self.side == 1 then
			if self.revealTime > 0 then
				trigger.action.setMarkupText(2000+self.index, self.name..label)
			else
				trigger.action.setMarkupText(2000+self.index, self.name)
			end
		elseif self.side == 2 then
			trigger.action.setMarkupText(2000+self.index, self.name..label)
		elseif self.side == 0 then
			trigger.action.setMarkupText(2000+self.index, ' '..self.name..' ')
		end

        if self.side == 2 and (self.isHeloSpawn or self.isPlaneSpawn) then
			trigger.action.setMarkupTypeLine(3000+self.index, 2)
			trigger.action.setMarkupColor(3000+self.index, {0,1,0,1})
		end

        local unit = Unit.getByName(self.name)
        local point = unit:getPoint()
        trigger.action.setMarkupPositionStart(3000+self.index, point)

        point.z = point.z + self.range
        trigger.action.setMarkupPositionStart(2000+self.index, point)
    end

    function CarrierCommand:capture(side)
    end

    function CarrierCommand:criticalOnSupplies()
		return self.resource<=self.spendTreshold
    end

    function CarrierCommand.getCarrierByName(name)
		if not name then return nil end
		return CarrierCommand.allCarriers[name]
	end
	
	function CarrierCommand.getAllCarriers()
		return CarrierCommand.allCarriers
	end
	
	function CarrierCommand.getCarrierOfUnit(unitname)
		local un = Unit.getByName(unitname)
		
		if not un then 
			return nil
		end
		
		for i,v in pairs(CarrierCommand.allCarriers) do
            local carrier = Unit.getByName(v.name)
            if carrier then
                if Utils.isInCircle(un:getPoint(), carrier:getPoint(), v.range) then
                    return v
                end
            end
		end
		
		return nil
	end

	function CarrierCommand.getClosestCarrierToPoint(point)
		local minDist = 9999999
		local closest = nil
		for i,v in pairs(CarrierCommand.allCarriers) do
            local carrier = Unit.getByName(v.name)
            if carrier then
                local d = mist.utils.get2DDist(carrier:getPoint(), point)
                if d < minDist then
                    minDist = d
                    closest = v
                end
            end
		end
		
		return closest, minDist
	end
	
	function CarrierCommand.getCarrierOfPoint(point)
		for i,v in pairs(CarrierCommand.allCarriers) do
			local carrier = Unit.getByName(v.name)
            if carrier then
                if Utils.isInCircle(point, carrier:getPoint(), v.range) then
                    return v
                end
            end
		end
		
		return nil
	end

	CarrierCommand.groupMenus = {}
	MenuRegistry:register(6, function(event, context)
		if event.id == world.event.S_EVENT_BIRTH and event.initiator and event.initiator.getPlayerName then
			local player = event.initiator:getPlayerName()
			if player then
				local groupid = event.initiator:getGroup():getID()
				local groupname = event.initiator:getGroup():getName()
				
				if CarrierCommand.groupMenus[groupid] then
					missionCommands.removeItemForGroup(groupid, CarrierCommand.groupMenus[groupid])
					CarrierCommand.groupMenus[groupid] = nil
				end

				if not CarrierCommand.groupMenus[groupid] then
					
					local menu = missionCommands.addSubMenuForGroup(groupid, 'Naval Command')

					local sorted = {}
					for cname, carrier in pairs(CarrierCommand.getAllCarriers()) do
						local cr = Unit.getByName(carrier.name)
						if cr then
							table.insert(sorted, carrier)
						end
					end

					table.sort(sorted, function(a,b) return a.name < b.name end)

					for _,carrier in ipairs(sorted) do
						local crunit =  Unit.getByName(carrier.name)
						if crunit and crunit:isExist() then
							local subm = missionCommands.addSubMenuForGroup(groupid, carrier.name, menu)
							missionCommands.addCommandForGroup(groupid, 'Information', subm, Utils.log(carrier.showInformation), carrier, groupname)

							local rank =  DependencyManager.get("PlayerTracker"):getPlayerRank(player)

							if rank and rank.allowCarrierSupport and Utils.getTableSize(carrier.supportFlights) > 0 then
								local supm = missionCommands.addSubMenuForGroup(groupid, "Support", subm)
								local flights = {}
								for _, data in pairs(carrier.supportFlights) do
									table.insert(flights, data)
								end

								table.sort(flights, function(a,b) return a.name<b.name end)

								for _, data in ipairs(flights) do
									local name = data.name..' ('..data.type..') ['..data.cost..']'
									missionCommands.addCommandForGroup(groupid, name, supm, Utils.log(carrier.callSupport), carrier, data, groupname)
								end

								local extras = {}
								for _, data in pairs(carrier.extraSupports) do
									table.insert(extras, data)
								end

								table.sort(extras, function(a,b) return a.name<b.name end)
								for _, data in ipairs(extras) do
									local name = data.name..' ('..data.type..') ['..data.cost..']'
									missionCommands.addCommandForGroup(groupid, name, supm, Utils.log(carrier.callExtraSupport), carrier, data, groupname)
								end
							end

							if rank and rank.allowCarrierCommand then
								local navm = missionCommands.addSubMenuForGroup(groupid, "Navigation", subm)
								for _,wp in ipairs(carrier.navmap) do
									local wpm = missionCommands.addSubMenuForGroup(groupid, wp.name, navm)
									if #wp.waypoints > 1 then
										missionCommands.addCommandForGroup(groupid, 'Patrol Area', wpm, Utils.log(carrier.setWaypoints), carrier, wp.waypoints, groupname)
									end
									
									missionCommands.addCommandForGroup(groupid, 'Go to '..wp.name, wpm, Utils.log(carrier.setWaypoints), carrier, {wp.name}, groupname)
									for _,subwp in ipairs(wp.waypoints) do
										missionCommands.addCommandForGroup(groupid, 'Go to '..subwp, wpm, Utils.log(carrier.setWaypoints), carrier, {subwp}, groupname)
									end
								end
							end
						end
					end

					CarrierCommand.groupMenus[groupid] = menu
				end
			end
		elseif (event.id == world.event.S_EVENT_PLAYER_LEAVE_UNIT or event.id == world.event.S_EVENT_DEAD) and event.initiator and event.initiator.getPlayerName then
			local player = event.initiator:getPlayerName()
			if player then
				local groupid = event.initiator:getGroup():getID()
				
				if CarrierCommand.groupMenus[groupid] then
					missionCommands.removeItemForGroup(groupid, CarrierCommand.groupMenus[groupid])
					CarrierCommand.groupMenus[groupid] = nil
				end
			end
		end
	end, nil)
end

