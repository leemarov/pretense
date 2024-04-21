
PlayerLogistics = {}
do
	PlayerLogistics.allowedTypes = {}
	PlayerLogistics.allowedTypes['Mi-24P'] = { supplies = true, personCapacity = 8 }
	PlayerLogistics.allowedTypes['Mi-8MT'] = { supplies = true, personCapacity = 24 }
	PlayerLogistics.allowedTypes['UH-1H'] = { supplies = true, personCapacity = 12}
	PlayerLogistics.allowedTypes['Hercules'] = { supplies = true, personCapacity = 92 }
	PlayerLogistics.allowedTypes['UH-60L'] = { supplies = true, personCapacity = 12 }
	PlayerLogistics.allowedTypes['Ka-50'] = { supplies = false }
	PlayerLogistics.allowedTypes['Ka-50_3'] = { supplies = false }
	PlayerLogistics.allowedTypes['SA342L'] = { supplies = false, personCapacity = 2}
	PlayerLogistics.allowedTypes['SA342M'] = { supplies = false, personCapacity = 2}
	PlayerLogistics.allowedTypes['SA342Minigun'] = { supplies = false, personCapacity = 2}
	PlayerLogistics.allowedTypes['AH-64D_BLK_II'] = { supplies = false }

	PlayerLogistics.infantryTypes = {
		capture = 'capture',
		sabotage = 'sabotage',
		ambush = 'ambush',
		engineer = 'engineer',
		manpads = 'manpads',
		spy = 'spy',
		rapier = 'rapier',
		extractable = 'extractable'
	}

	function PlayerLogistics.getInfantryName(infType)
		if infType==PlayerLogistics.infantryTypes.capture then
			return "Capture Squad"
		elseif infType==PlayerLogistics.infantryTypes.sabotage then
			return "Sabotage Squad"
		elseif infType==PlayerLogistics.infantryTypes.ambush then
			return "Ambush Squad"
		elseif infType==PlayerLogistics.infantryTypes.engineer then
			return "Engineer"
		elseif infType==PlayerLogistics.infantryTypes.manpads then
			return "MANPADS"
		elseif infType==PlayerLogistics.infantryTypes.spy then
			return "Spy"
		elseif infType==PlayerLogistics.infantryTypes.rapier then
			return "Rapier SAM"
		elseif infType==PlayerLogistics.infantryTypes.extractable then
			return "Extracted infantry"
		end

		return "INVALID SQUAD"
	end
	
	function PlayerLogistics:new()
		local obj = {}
		obj.groupMenus = {} -- groupid = path
		obj.carriedCargo = {} -- groupid = source
		obj.carriedInfantry = {} -- groupid = source
		obj.carriedPilots = {} --groupid = source
		obj.registeredSquadGroups = {}
		obj.lastLoaded = {} -- groupid = zonename

		obj.hercTracker = {
			cargos = {},
			cargoCheckFunctions = {}
		}

		obj.hercPreparedDrops = {}
		
		setmetatable(obj, self)
		self.__index = self
		
		obj:start()
		
		DependencyManager.register("PlayerLogistics", obj)
		return obj
	end

	function PlayerLogistics:registerSquadGroup(squadType, groupname, weight, cost, jobtime, extracttime, squadSize, side)
		self.registeredSquadGroups[squadType] = { name=groupname, type=squadType, weight=weight, cost=cost, jobtime=jobtime, extracttime=extracttime, size = squadSize, side=side}
	end
	
	function PlayerLogistics:start()
		if not ZoneCommand then return end
	
        MenuRegistry:register(3, function(event, context)
			if event.id == world.event.S_EVENT_BIRTH and event.initiator and event.initiator.getPlayerName then
				local player = event.initiator:getPlayerName()
				if player then
					local unitType = event.initiator:getDesc()['typeName']
					local groupid = event.initiator:getGroup():getID()
					local groupname = event.initiator:getGroup():getName()
					
					local logistics = context.allowedTypes[unitType]
					if logistics and (logistics.supplies or logistics.personCapacity)then

						if context.groupMenus[groupid] then
							missionCommands.removeItemForGroup(groupid, context.groupMenus[groupid])
							context.groupMenus[groupid] = nil
						end

						if not context.groupMenus[groupid] then
							local size = event.initiator:getGroup():getSize()
							if size > 1 then
								trigger.action.outText('WARNING: group '..groupname..' has '..size..' units. Logistics will only function for group leader', 10)
							end
							
							local cargomenu = missionCommands.addSubMenuForGroup(groupid, 'Logistics')
							if logistics.supplies then
								local supplyMenu = missionCommands.addSubMenuForGroup(groupid, 'Supplies', cargomenu)
								local loadMenu = missionCommands.addSubMenuForGroup(groupid, 'Load', supplyMenu)
								missionCommands.addCommandForGroup(groupid, 'Load 100 supplies', loadMenu, Utils.log(context.loadSupplies), context, {group=groupname, amount=100})
								missionCommands.addCommandForGroup(groupid, 'Load 500 supplies', loadMenu, Utils.log(context.loadSupplies), context, {group=groupname, amount=500})
								missionCommands.addCommandForGroup(groupid, 'Load 1000 supplies', loadMenu, Utils.log(context.loadSupplies), context, {group=groupname, amount=1000})
								missionCommands.addCommandForGroup(groupid, 'Load 2000 supplies', loadMenu, Utils.log(context.loadSupplies), context, {group=groupname, amount=2000})
								missionCommands.addCommandForGroup(groupid, 'Load 5000 supplies', loadMenu, Utils.log(context.loadSupplies), context, {group=groupname, amount=5000})

								local unloadMenu = missionCommands.addSubMenuForGroup(groupid, 'Unload', supplyMenu)
								missionCommands.addCommandForGroup(groupid, 'Unload 100 supplies', unloadMenu, Utils.log(context.unloadSupplies), context, {group=groupname, amount=100})
								missionCommands.addCommandForGroup(groupid, 'Unload 500 supplies', unloadMenu, Utils.log(context.unloadSupplies), context, {group=groupname, amount=500})
								missionCommands.addCommandForGroup(groupid, 'Unload 1000 supplies', unloadMenu, Utils.log(context.unloadSupplies), context, {group=groupname, amount=1000})
								missionCommands.addCommandForGroup(groupid, 'Unload 2000 supplies', unloadMenu, Utils.log(context.unloadSupplies), context, {group=groupname, amount=2000})
								missionCommands.addCommandForGroup(groupid, 'Unload 5000 supplies', unloadMenu, Utils.log(context.unloadSupplies), context, {group=groupname, amount=5000})
								missionCommands.addCommandForGroup(groupid, 'Unload all supplies', unloadMenu, Utils.log(context.unloadSupplies), context, {group=groupname, amount=9999999})
							end

							local sqs = {}
							for sqType,_ in pairs(context.registeredSquadGroups) do
								table.insert(sqs,sqType)
							end
							table.sort(sqs)

							if logistics.personCapacity then
								local infMenu = missionCommands.addSubMenuForGroup(groupid, 'Infantry', cargomenu)
								
								local loadInfMenu = missionCommands.addSubMenuForGroup(groupid, 'Load', infMenu)
								for _,sqType in ipairs(sqs) do
									local menuName =  'Load '..PlayerLogistics.getInfantryName(sqType)
									missionCommands.addCommandForGroup(groupid, menuName, loadInfMenu, Utils.log(context.loadInfantry), context, {group=groupname, type=sqType})
								end

								local unloadInfMenu = missionCommands.addSubMenuForGroup(groupid, 'Unload', infMenu)
								for _,sqType in ipairs(sqs) do
									local menuName =  'Unload '..PlayerLogistics.getInfantryName(sqType)
									missionCommands.addCommandForGroup(groupid, menuName, unloadInfMenu, Utils.log(context.unloadInfantry), context, {group=groupname, type=sqType})
								end
								missionCommands.addCommandForGroup(groupid, 'Unload Extracted squad', unloadInfMenu, Utils.log(context.unloadInfantry), context, {group=groupname, type=PlayerLogistics.infantryTypes.extractable})

								missionCommands.addCommandForGroup(groupid, 'Extract squad', infMenu, Utils.log(context.extractSquad), context, groupname)
								missionCommands.addCommandForGroup(groupid, 'Unload all', infMenu, Utils.log(context.unloadInfantry), context, {group=groupname})

								local csarMenu = missionCommands.addSubMenuForGroup(groupid, 'CSAR', cargomenu)
								missionCommands.addCommandForGroup(groupid, 'Show info (closest)', csarMenu, Utils.log(context.showPilot), context, groupname)
								missionCommands.addCommandForGroup(groupid, 'Smoke marker (closest)', csarMenu, Utils.log(context.smokePilot), context, groupname)
								missionCommands.addCommandForGroup(groupid, 'Flare (closest)', csarMenu, Utils.log(context.flarePilot), context, groupname)
								missionCommands.addCommandForGroup(groupid, 'Extract pilot', csarMenu, Utils.log(context.extractPilot), context, groupname)
								missionCommands.addCommandForGroup(groupid, 'Unload pilots', csarMenu, Utils.log(context.unloadPilots), context, groupname)
							end

							missionCommands.addCommandForGroup(groupid, 'Cargo status', cargomenu, Utils.log(context.cargoStatus), context, groupname)
							missionCommands.addCommandForGroup(groupid, 'Unload Everything', cargomenu, Utils.log(context.unloadAll), context, groupname)
							
							if unitType == 'Hercules' then
								local loadmasterMenu = missionCommands.addSubMenuForGroup(groupid, 'Loadmaster', cargomenu)

								for _,sqType in ipairs(sqs) do
									local menuName =  'Prepare '..PlayerLogistics.getInfantryName(sqType)
									missionCommands.addCommandForGroup(groupid, menuName, loadmasterMenu, Utils.log(context.hercPrepareDrop), context, {group=groupname, type=sqType})
								end

								missionCommands.addCommandForGroup(groupid, 'Prepare Supplies', loadmasterMenu, Utils.log(context.hercPrepareDrop), context, {group=groupname, type='supplies'})
							end
							
							
							context.groupMenus[groupid] = cargomenu
						end
						
						if context.carriedCargo[groupid] then
							context.carriedCargo[groupid] = 0
						end

						if context.carriedInfantry[groupid] then
							context.carriedInfantry[groupid] = {}
						end

						if context.carriedPilots[groupid] then
							context.carriedPilots[groupid] = {}
						end

						if context.lastLoaded[groupid] then
							context.lastLoaded[groupid] = nil
						end

						if context.hercPreparedDrops[groupid] then
							context.hercPreparedDrops[groupid] = nil
						end
					end
				end
			elseif (event.id == world.event.S_EVENT_PLAYER_LEAVE_UNIT or event.id == world.event.S_EVENT_DEAD) and event.initiator and event.initiator.getPlayerName then
                local player = event.initiator:getPlayerName()
				if player then
					local groupid = event.initiator:getGroup():getID()
					
					if context.groupMenus[groupid] then
						missionCommands.removeItemForGroup(groupid, context.groupMenus[groupid])
						context.groupMenus[groupid] = nil
					end
				end
            end
		end, self)

		local ev = {}
		ev.context = self
		function ev:onEvent(event)
			if event.id == world.event.S_EVENT_SHOT and event.initiator and event.initiator:isExist() then
				local unitName = event.initiator:getName()
				local groupId = event.initiator:getGroup():getID()
				local name = event.weapon:getDesc().typeName
				if name == 'weapons.bombs.Generic Crate [20000lb]' then
					local prepared = self.context.hercPreparedDrops[groupId]

					if not prepared then
						prepared = 'supplies'
								
						if self.context.carriedInfantry[groupId] then
							for _,v in ipairs(self.context.carriedInfantry[groupId]) do
								if v.type ~= PlayerLogistics.infantryTypes.extractable then
									prepared = v.type
									break
								end
							end
						end

						env.info('PlayerLogistics - Hercules - auto preparing '..prepared)
					end

					if prepared then
						if prepared == 'supplies' then
							env.info('PlayerLogistics - Hercules - supplies getting dropped')
							local carried = self.context.carriedCargo[groupId]
							local amount = 0
							if carried and carried > 0 then
								amount = 9000
								if carried < amount then
									amount = carried
								end
							end
							
							if amount > 0 then
								self.context.carriedCargo[groupId] = math.max(0,self.context.carriedCargo[groupId] - amount)
								if not self.context.hercTracker.cargos[unitName] then
									self.context.hercTracker.cargos[unitName] = {}
								end
								
								table.insert(self.context.hercTracker.cargos[unitName],{
									object = event.weapon,
									supply = amount,
									lastLoaded = self.context.lastLoaded[groupId],
									unit = event.initiator
								})
								
								env.info('PlayerLogistics - Hercules - '..unitName..' deployed crate with '..amount..' supplies')
								self.context:processHercCargos(unitName)
								self.context.hercPreparedDrops[groupId] = nil
								trigger.action.outTextForUnit(event.initiator:getID(), 'Crate with '..amount..' supplies deployed', 10)
							else
								trigger.action.outTextForUnit(event.initiator:getID(), 'Empty crate deployed', 10)
							end
						else
							env.info('PlayerLogistics - Hercules - searching for prepared infantry')
							local toDrop = nil
							local remaining = {}
							if self.context.carriedInfantry[groupId] then
								for _,v in ipairs(self.context.carriedInfantry[groupId]) do
									if v.type == prepared and toDrop == nil then
										toDrop = v
									else
										table.insert(remaining, v)
									end
								end
							end
							
							
							if toDrop then
								env.info('PlayerLogistics - Hercules - dropping '..toDrop.type)
								if not self.context.hercTracker.cargos[unitName] then
									self.context.hercTracker.cargos[unitName] = {}
								end
								
								table.insert(self.context.hercTracker.cargos[unitName],{
									object = event.weapon,
									squad = toDrop,
									lastLoaded = self.context.lastLoaded[groupId],
									unit = event.initiator
								})
								
								env.info('PlayerLogistics - Hercules - '..unitName..' deployed crate with '..toDrop.type)
								self.context:processHercCargos(unitName)
								self.context.hercPreparedDrops[groupId] = nil
								
								local squadName = PlayerLogistics.getInfantryName(prepared)
								trigger.action.outTextForUnit(event.initiator:getID(), squadName..' crate deployed.', 10)
								self.context.carriedInfantry[groupId] = remaining
								local weight = self.context:getCarriedPersonWeight(event.initiator:getGroup():getName())
								trigger.action.setUnitInternalCargo(event.initiator:getName(), weight)
							else
								trigger.action.outTextForUnit(event.initiator:getID(), 'Empty crate deployed', 10)
							end
						end
					else
						trigger.action.outTextForUnit(event.initiator:getID(), 'Empty crate deployed', 10)
					end
				end
			end
		end
		
		world.addEventHandler(ev)
	end

	function PlayerLogistics:processHercCargos(unitName)
		if not self.hercTracker.cargoCheckFunctions[unitName] then
			env.info('PlayerLogistics - Hercules - start tracking cargos of '..unitName)
			self.hercTracker.cargoCheckFunctions[unitName] = timer.scheduleFunction(function(params, time)
				local reschedule = params.context:checkHercCargo(params.unitName, time)
				if not reschedule then
					params.context.hercTracker.cargoCheckFunctions[params.unitName] = nil
					env.info('PlayerLogistics - Hercules - stopped tracking cargos of '..unitName)
				end
				
				return reschedule
			end, {unitName=unitName, context = self}, timer.getTime() + 0.1)
		end
	end

	function PlayerLogistics:checkHercCargo(unitName, time)
		local cargos = self.hercTracker.cargos[unitName]
		if cargos and #cargos > 0 then
			local remaining = {}
			for _,cargo in ipairs(cargos) do
				if cargo.object and cargo.object:isExist() then
					local alt = Utils.getAGL(cargo.object)
					if alt < 5 then
						self:deliverHercCargo(cargo)
					else
						table.insert(remaining, cargo)
					end
				else
					env.info('PlayerLogistics - Hercules - cargo crashed '..tostring(cargo.supply)..' '..tostring(cargo.squad))
					if cargo.squad then 
						env.info('PlayerLogistics - Hercules - squad crashed '..tostring(cargo.squad.type))
					end

					if cargo.unit and cargo.unit:isExist() then
						if cargo.squad then
							local squadName = PlayerLogistics.getInfantryName(cargo.squad.type)
							trigger.action.outTextForUnit(cargo.unit:getID(), 'Cargo drop of '..cargo.unit:getPlayerName()..' with '..squadName..' crashed', 10)
						elseif cargo.supply then
							trigger.action.outTextForUnit(cargo.unit:getID(), 'Cargo drop of '..cargo.unit:getPlayerName()..' with '..cargo.supply..' supplies crashed', 10)
						end
					end
				end
			end

			if #remaining > 0 then
				self.hercTracker.cargos[unitName] = remaining
				return time + 0.1
			end
		end
	end

	function PlayerLogistics:deliverHercCargo(cargo)
		if cargo.object and cargo.object:isExist() then
			if cargo.supply then
				local zone = ZoneCommand.getZoneOfWeapon(cargo.object)
				if zone then
					zone:addResource(cargo.supply)
					env.info('PlayerLogistics - Hercules - '..cargo.supply..' delivered to '..zone.name)

					self:awardSupplyXP(cargo.lastLoaded, zone, cargo.unit, cargo.supply)
				end
			elseif cargo.squad then
				local pos = Utils.getPointOnSurface(cargo.object:getPoint())
				pos.y = pos.z
				pos.z = nil
				local surface = land.getSurfaceType(pos)
				if surface == land.SurfaceType.LAND or surface == land.SurfaceType.ROAD or surface == land.SurfaceType.RUNWAY then
					local zn = ZoneCommand.getZoneOfPoint(pos)
					
					local lastLoad = cargo.squad.loadedAt
					if lastLoad and zn and zn.side == cargo.object:getCoalition() and zn.name==lastLoad.name then
						if self.registeredSquadGroups[cargo.squad.type] then
							local cost = self.registeredSquadGroups[cargo.squad.type].cost
							zn:addResource(cost)
							zn:refreshText()
							if cargo.unit and cargo.unit:isExist() then
								local squadName = PlayerLogistics.getInfantryName(cargo.squad.type)
								trigger.action.outTextForUnit(cargo.unit:getID(), squadName..' unloaded', 10)
							end
						end
					else
						local error = DependencyManager.get("SquadTracker"):spawnInfantry(self.registeredSquadGroups[cargo.squad.type], pos)
						if not error then
							env.info('PlayerLogistics - Hercules - '..cargo.squad.type..' deployed')
							
							local squadName = PlayerLogistics.getInfantryName(cargo.squad.type)
							
							if cargo.unit and cargo.unit:isExist() and cargo.unit.getPlayerName then
								trigger.action.outTextForUnit(cargo.unit:getID(), squadName..' deployed', 10)
								local player = cargo.unit:getPlayerName()
								local xp = RewardDefinitions.actions.squadDeploy * DependencyManager.get("PlayerTracker"):getPlayerMultiplier(player)
								
								DependencyManager.get("PlayerTracker"):addStat(player, math.floor(xp), PlayerTracker.statTypes.xp)
								
								if zn then
									DependencyManager.get("MissionTracker"):tallyUnloadSquad(player, zn.name, cargo.squad.type)
								else
									DependencyManager.get("MissionTracker"):tallyUnloadSquad(player, '', cargo.squad.type)
								end
								trigger.action.outTextForUnit(cargo.unit:getID(), '+'..math.floor(xp)..' XP', 10)
							end
						end
					end
				else
					env.info('PlayerLogistics - Hercules - '..cargo.squad.type..' dropped on invalid surface '..tostring(surface))
					local cpos = cargo.object:getPoint()
					env.info('PlayerLogistics - Hercules - cargo spot X:'..cpos.x..' Y:'..cpos.y..' Z:'..cpos.z)
					env.info('PlayerLogistics - Hercules - surface spot X:'..pos.x..' Y:'..pos.y)
					local squadName = PlayerLogistics.getInfantryName(cargo.squad.type)
					trigger.action.outTextForUnit(cargo.unit:getID(), 'Cargo drop of '..cargo.unit:getPlayerName()..' with '..squadName..' crashed', 10)
				end
			end

			cargo.object:destroy()
		end
	end

	function PlayerLogistics:hercPrepareDrop(params)
		local groupname = params.group
		local type = params.type
		local gr = Group.getByName(groupname)
		if gr then
			local un = gr:getUnit(1)

			if type == 'supplies' then
				local cargo = self.carriedCargo[gr:getID()]
				if cargo and cargo > 0 then
					self.hercPreparedDrops[gr:getID()] = type
					trigger.action.outTextForUnit(un:getID(), 'Supply drop prepared', 10)
				else
					trigger.action.outTextForUnit(un:getID(), 'No supplies onboard the aircraft', 10)
				end
			else
				local exists = false
				if self.carriedInfantry[gr:getID()] then
					for i,v in ipairs(self.carriedInfantry[gr:getID()]) do
						if v.type == type then
							exists = true
							break
						end
					end
				end
			
				if exists then
					self.hercPreparedDrops[gr:getID()] = type
					local squadName = PlayerLogistics.getInfantryName(type)
					trigger.action.outTextForUnit(un:getID(), squadName..' drop prepared', 10)
				else
					local squadName = PlayerLogistics.getInfantryName(type)
					trigger.action.outTextForUnit(un:getID(), 'No '..squadName..' onboard the aircraft', 10)
				end
			end
		end
	end

	function PlayerLogistics:awardSupplyXP(lastLoad, zone, unit, amount)
		if lastLoad and zone.name~=lastLoad.name and not zone.isCarrier and not lastLoad.isCarrier then
			if unit and unit.isExist and unit:isExist() and unit.getPlayerName then
				local player = unit:getPlayerName()
				local xp = amount*RewardDefinitions.actions.supplyRatio

				local totalboost = 0
				local dist = mist.utils.get2DDist(lastLoad.zone.point, zone.zone.point)
				if dist > 15000 then
					local extradist = math.max(dist - 15000, 85000)
					local kmboost = extradist/85000
					local actualboost = xp * kmboost * 1
					totalboost = totalboost + actualboost
				end

				local both = true
				if zone:criticalOnSupplies() then
					local actualboost = xp * RewardDefinitions.actions.supplyBoost
					totalboost = totalboost + actualboost
				else 
					both = false
				end

				if zone.distToFront == 0 then
					local actualboost = xp * RewardDefinitions.actions.supplyBoost
					totalboost = totalboost + actualboost
				else 
					both = false
				end

				if both then
					local actualboost = xp * 1
					totalboost = totalboost + actualboost
				end

				xp = xp + totalboost

				if lastLoad.distToFront >= zone.distToFront then
					xp = xp * 0.25
				end

				xp = xp * DependencyManager.get("PlayerTracker"):getPlayerMultiplier(player)

				DependencyManager.get("PlayerTracker"):addStat(player, math.floor(xp), PlayerTracker.statTypes.xp)
				DependencyManager.get("MissionTracker"):tallySupplies(player, amount, zone.name)
				trigger.action.outTextForUnit(unit:getID(), '+'..math.floor(xp)..' XP', 10)
			end
		end
	end
	
	function PlayerLogistics.markWithSmoke(zonename)
		local zone = CustomZone:getByName(zonename)
		local p = Utils.getPointOnSurface(zone.point)
		trigger.action.smoke(p, 0)
	end
	
	function PlayerLogistics.getWeight(supplies)
		return math.floor(supplies)
	end

	function PlayerLogistics:getCarriedPersonWeight(groupname)
		local gr = Group.getByName(groupname)
		local un = gr:getUnit(1)
		if un then
			if not PlayerLogistics.allowedTypes[un:getDesc().typeName] then return 0 end
			
			local max = PlayerLogistics.allowedTypes[un:getDesc().typeName].personCapacity

			local pilotWeight = 0
			local squadWeight = 0
			if not self.carriedPilots[gr:getID()] then self.carriedPilots[gr:getID()] = {} end
			local pilots = self.carriedPilots[gr:getID()]
			if pilots then 
				pilotWeight = 100 * #pilots
			end

			if not self.carriedInfantry[gr:getID()] then self.carriedInfantry[gr:getID()] = {} end
			local squads = self.carriedInfantry[gr:getID()]
			if squads then
				for _,squad in ipairs(squads) do 
					squadWeight = squadWeight + squad.weight
				end
			end

			return pilotWeight + squadWeight
		end
	end

	function PlayerLogistics:getOccupiedPersonCapacity(groupname)
		local gr = Group.getByName(groupname)
		local un = gr:getUnit(1)
		if un then
			if not PlayerLogistics.allowedTypes[un:getDesc().typeName] then return 0 end
			if self.carriedCargo[gr:getID()] and self.carriedCargo[gr:getID()] > 0 then return 0 end
			
			local max = PlayerLogistics.allowedTypes[un:getDesc().typeName].personCapacity

			local pilotCount = 0
			local squadCount = 0
			if not self.carriedPilots[gr:getID()] then self.carriedPilots[gr:getID()] = {} end
			local pilots = self.carriedPilots[gr:getID()]
			if pilots then 
				pilotCount = #pilots
			end

			if not self.carriedInfantry[gr:getID()] then self.carriedInfantry[gr:getID()] = {} end
			local squads = self.carriedInfantry[gr:getID()]
			if squads then
				for _,squad in ipairs(squads) do 
					squadCount = squadCount + squad.size
				end
			end

			local total = pilotCount + squadCount

			return total
		end
	end

	function PlayerLogistics:getRemainingPersonCapacity(groupname)
		local gr = Group.getByName(groupname)
		local un = gr:getUnit(1)
		if un then
			if not PlayerLogistics.allowedTypes[un:getDesc().typeName] then return 0 end
			if self.carriedCargo[gr:getID()] and self.carriedCargo[gr:getID()] > 0 then return 0 end
			
			local max = PlayerLogistics.allowedTypes[un:getDesc().typeName].personCapacity

			local total = self:getOccupiedPersonCapacity(groupname)

			return max - total
		end
	end

	function PlayerLogistics:canFitCargo(groupname)
		local gr = Group.getByName(groupname)
		local un = gr:getUnit(1)
		if un then
			if not PlayerLogistics.allowedTypes[un:getDesc().typeName] then return false end
			return self:getOccupiedPersonCapacity(groupname) == 0
		end
	end

	function PlayerLogistics:canFitPersonnel(groupname, toFit)
		local gr = Group.getByName(groupname)
		local un = gr:getUnit(1)
		if un then
			if not PlayerLogistics.allowedTypes[un:getDesc().typeName] then return false end

			return self:getRemainingPersonCapacity(groupname) >= toFit
		end
	end

	function PlayerLogistics:showPilot(groupname)
		local gr = Group.getByName(groupname)
		if gr then
			local un = gr:getUnit(1)
			if un then
				local data = DependencyManager.get("CSARTracker"):getClosestPilot(un:getPoint())
				
				if not data then 
					trigger.action.outTextForUnit(un:getID(), 'No pilots in need of extraction', 10)
					return
				end

				local pos = data.pilot:getUnit(1):getPoint()
				local brg = math.floor(Utils.getBearing(un:getPoint(), data.pilot:getUnit(1):getPoint()))
				local dist = data.dist
				local dstft = math.floor(dist/0.3048)

				local msg = data.name..' requesting extraction'
				msg = msg..'\n\n Distance: '
				if dist>1000 then
					local dstkm = string.format('%.2f',dist/1000)
					local dstnm = string.format('%.2f',dist/1852)
					
					msg = msg..dstkm..'km | '..dstnm..'nm'
				else
					local dstft = math.floor(dist/0.3048)
					msg = msg..math.floor(dist)..'m | '..dstft..'ft'
				end
				
				msg = msg..'\n Bearing: '..brg
				
				trigger.action.outTextForUnit(un:getID(), msg, 10)
			end
		end
	end
	
	function PlayerLogistics:smokePilot(groupname)
		local gr = Group.getByName(groupname)
		if gr then
			local un = gr:getUnit(1)
			if un then
				local data = DependencyManager.get("CSARTracker"):getClosestPilot(un:getPoint())
				
				if not data or data.dist >= 5000 then 
					trigger.action.outTextForUnit(un:getID(), 'No pilots nearby', 10)
					return
				end

				DependencyManager.get("CSARTracker"):markPilot(data)
				trigger.action.outTextForUnit(un:getID(), 'Location of '..data.name..' marked with green smoke.', 10)
			end
		end
	end
	
	function PlayerLogistics:flarePilot(groupname)
		local gr = Group.getByName(groupname)
		if gr then
			local un = gr:getUnit(1)
			if un then
				local data = DependencyManager.get("CSARTracker"):getClosestPilot(un:getPoint())
				
				if not data or data.dist >= 5000 then 
					trigger.action.outTextForUnit(un:getID(), 'No pilots nearby', 10)
					return
				end

				DependencyManager.get("CSARTracker"):flarePilot(data)
				trigger.action.outTextForUnit(un:getID(), data.name..' has deployed a green flare', 10)
			end
		end
	end
	
	function PlayerLogistics:unloadPilots(groupname)
		local gr = Group.getByName(groupname)
		if gr then
			local un = gr:getUnit(1)
			if un then
				local pilots = self.carriedPilots[gr:getID()]
				if not pilots or #pilots==0 then
					trigger.action.outTextForUnit(un:getID(), 'No pilots onboard', 10)
					return
				end

				if Utils.isInAir(un) then
					trigger.action.outTextForUnit(un:getID(), 'Can not unload pilot while in air', 10)
					return
				end
				
				if not self:isCargoDoorOpen(un) then
					trigger.action.outTextForUnit(un:getID(), 'Can not unload pilot while cargo door closed', 10)
					return
				end

				local zn = ZoneCommand.getZoneOfUnit(un:getName())
				if not zn then 
					zn = CarrierCommand.getCarrierOfUnit(un:getName())
				end
				
				if not zn then
					trigger.action.outTextForUnit(un:getID(), 'Can only unload extracted pilots while within a friendly zone', 10)
					return
				end
				
				if zn.side ~= 0 and zn.side ~= un:getCoalition()then
					trigger.action.outTextForUnit(un:getID(), 'Can only unload extracted pilots while within a friendly zone', 10)
					return
				end

				zn:addResource(200*#pilots)
				zn:refreshText()

				if un.getPlayerName then
					local player = un:getPlayerName()

					local xp = #pilots*RewardDefinitions.actions.pilotExtract

					xp = xp * DependencyManager.get("PlayerTracker"):getPlayerMultiplier(player)

					DependencyManager.get("PlayerTracker"):addStat(player, math.floor(xp), PlayerTracker.statTypes.xp)
					DependencyManager.get("MissionTracker"):tallyUnloadPilot(player, zn.name)
					trigger.action.outTextForUnit(un:getID(), '+'..math.floor(xp)..' XP', 10)
				end

				self.carriedPilots[gr:getID()] = {}
				trigger.action.setUnitInternalCargo(un:getName(), 0)
				trigger.action.outTextForUnit(un:getID(), 'Pilots unloaded', 10)
			end
		end
	end
	
	function PlayerLogistics:extractPilot(groupname)
		local gr = Group.getByName(groupname)
		if gr then
			local un = gr:getUnit(1)
			if un then
				if not self:canFitPersonnel(groupname, 1) then
					trigger.action.outTextForUnit(un:getID(), 'Not enough free space onboard. (Need 1)', 10)
					return
				end

				timer.scheduleFunction(function(param,time) 
					local self = param.context
					local un = param.unit
					if not un then return end
					if not un:isExist() then return end
					local gr = un:getGroup()

					local data = DependencyManager.get("CSARTracker"):getClosestPilot(un:getPoint())

					if not data or data.dist > 500 then
						trigger.action.outTextForUnit(un:getID(), 'There is no pilot nearby that needs extraction', 10)
						return
					else
						if not self:isCargoDoorOpen(un) then
							trigger.action.outTextForUnit(un:getID(), 'Cargo door closed', 1)
						elseif Utils.getAGL(un) > 70 then
							trigger.action.outTextForUnit(un:getID(), 'Altitude too high (< 70 m). Current: '..string.format('%.2f',Utils.getAGL(un))..' m', 1)
						elseif mist.vec.mag(un:getVelocity())>5 then
							trigger.action.outTextForUnit(un:getID(), 'Moving too fast (< 5 m/s). Current: '..string.format('%.2f',mist.vec.mag(un:getVelocity()))..' m/s', 1)
						else
							if data.dist > 100 then
								trigger.action.outTextForUnit(un:getID(), 'Too far (< 100m). Current: '..string.format('%.2f',data.dist)..' m', 1)
							else
								if not self.carriedPilots[gr:getID()] then self.carriedPilots[gr:getID()] = {} end
								table.insert(self.carriedPilots[gr:getID()], data.name)
								local player = un:getPlayerName()
								DependencyManager.get("MissionTracker"):tallyLoadPilot(player, data)
								DependencyManager.get("CSARTracker"):removePilot(data.name)
								local weight = self:getCarriedPersonWeight(gr:getName())
								trigger.action.setUnitInternalCargo(un:getName(), weight)
								trigger.action.outTextForUnit(un:getID(), data.name..' onboard. ('..weight..' kg)', 10)
								return
							end
						end
					end

					param.trys = param.trys - 1
					if param.trys > 0 then
						return time+1
					end
				end, {context = self, unit = un, trys = 60}, timer.getTime()+0.1)
			end
		end
	end
	
	function PlayerLogistics:extractSquad(groupname)
		local gr = Group.getByName(groupname)
		if gr then
			local un = gr:getUnit(1)
			if un then

				if Utils.isInAir(un) then
					trigger.action.outTextForUnit(un:getID(), 'Can not load infantry while in air', 10)
					return
				end
				
				if not self:isCargoDoorOpen(un) then
					trigger.action.outTextForUnit(un:getID(), 'Can not load infantry while cargo door closed', 10)
					return
				end

				local squad, distance = DependencyManager.get("SquadTracker"):getClosestExtractableSquad(un:getPoint(), un:getCoalition())
				if squad and distance < 50 then
					local squadgr = Group.getByName(squad.name)
					if squadgr and squadgr:isExist() then
						local sqsize = squadgr:getSize()
						if not self:canFitPersonnel(groupname, sqsize) then
							trigger.action.outTextForUnit(un:getID(), 'Not enough free space onboard. (Need '..sqsize..')', 10)
							return
						end

						if not self.carriedInfantry[gr:getID()] then self.carriedInfantry[gr:getID()] = {} end
						table.insert(self.carriedInfantry[gr:getID()],{type = PlayerLogistics.infantryTypes.extractable, size = sqsize, weight = sqsize * 100})
						
						local weight = self:getCarriedPersonWeight(gr:getName())

						trigger.action.setUnitInternalCargo(un:getName(), weight)
						
						local loadedInfName = PlayerLogistics.getInfantryName(PlayerLogistics.infantryTypes.extractable)
						trigger.action.outTextForUnit(un:getID(), loadedInfName..' onboard. ('..weight..' kg)', 10)
						
						local player = un:getPlayerName()
						DependencyManager.get("MissionTracker"):tallyLoadSquad(player, squad)
						DependencyManager.get("SquadTracker"):removeSquad(squad.name)
						
						squadgr:destroy()
					end
				else
					trigger.action.outTextForUnit(un:getID(), 'There is no infantry nearby that is ready to be extracted.', 10)
				end
			end
		end
	end

	function PlayerLogistics:loadInfantry(params)
		if not ZoneCommand then return end
		
		local gr = Group.getByName(params.group)
		local squadType = params.type
		local squadName = PlayerLogistics.getInfantryName(squadType)
		
		local squadCost = 0
		local squadSize = 999999
		local squadWeight = 0
		if self.registeredSquadGroups[squadType] then
			squadCost = self.registeredSquadGroups[squadType].cost
			squadSize = self.registeredSquadGroups[squadType].size
			squadWeight = self.registeredSquadGroups[squadType].weight
		end
		
		if gr then
			local un = gr:getUnit(1)
			if un then
				if Utils.isInAir(un) then
					trigger.action.outTextForUnit(un:getID(), 'Can not load infantry while in air', 10)
					return
				end
				
				local zn = ZoneCommand.getZoneOfUnit(un:getName())
				if not zn then 
					zn = CarrierCommand.getCarrierOfUnit(un:getName())
				end
				
				if not zn then
					trigger.action.outTextForUnit(un:getID(), 'Can only load infantry while within a friendly zone', 10)
					return
				end
				
				if zn.side ~= un:getCoalition() then
					trigger.action.outTextForUnit(un:getID(), 'Can only load infantry while within a friendly zone', 10)
					return
				end

				if not self:isCargoDoorOpen(un) then
					trigger.action.outTextForUnit(un:getID(), 'Can not load infantry while cargo door closed', 10)
					return
				end

				if zn:criticalOnSupplies() then
					trigger.action.outTextForUnit(un:getID(), 'Can not load infantry, zone is low on resources', 10)
					return
				end

				if zn.resource < zn.spendTreshold + squadCost then
					trigger.action.outTextForUnit(un:getID(), 'Can not afford to load '..squadName..' (Cost: '..squadCost..'). Resources would fall to a critical level.', 10)
					return
				end

				if not self:canFitPersonnel(params.group, squadSize) then
					trigger.action.outTextForUnit(un:getID(), 'Not enough free space on board. (Need '..squadSize..')', 10)
					return
				end
				
				zn:removeResource(squadCost)
				zn:refreshText()
				if not self.carriedInfantry[gr:getID()] then self.carriedInfantry[gr:getID()] = {} end
				table.insert(self.carriedInfantry[gr:getID()],{ type = squadType, size = squadSize, weight = squadWeight, loadedAt = zn })
				self.lastLoaded[gr:getID()] = zn
				
				local weight = self:getCarriedPersonWeight(gr:getName())
				trigger.action.setUnitInternalCargo(un:getName(), weight)
				
				local loadedInfName = PlayerLogistics.getInfantryName(squadType)
				trigger.action.outTextForUnit(un:getID(), loadedInfName..' onboard. ('..weight..' kg)', 10)
			end
		end
	end

	function PlayerLogistics:unloadInfantry(params)
		if not ZoneCommand then return end
		local groupname = params.group
		local sqtype = params.type
		
		local gr = Group.getByName(groupname)
		if gr then
			local un = gr:getUnit(1)
			if un then
				if Utils.isInAir(un) then
					trigger.action.outTextForUnit(un:getID(), 'Can not unload infantry while in air', 10)
					return
				end

				if not self:isCargoDoorOpen(un) then
					trigger.action.outTextForUnit(un:getID(), 'Can not unload infantry while cargo door closed', 10)
					return
				end

				local carriedSquads = self.carriedInfantry[gr:getID()]
				if not carriedSquads or #carriedSquads == 0 then
					trigger.action.outTextForUnit(un:getID(), 'No infantry onboard', 10)
					return
				end
				
				local toUnload = carriedSquads
				local remaining = {}
				if sqtype then
					toUnload = {}
					local sqToUnload = nil
					for _,sq in ipairs(carriedSquads) do
						if sq.type == sqtype and not sqToUnload then
							sqToUnload = sq
						else
							table.insert(remaining, sq)
						end
					end

					if sqToUnload then toUnload = { sqToUnload } end
				end

				if #toUnload == 0 then
					if sqtype then
						local squadName = PlayerLogistics.getInfantryName(sqtype)
						trigger.action.outTextForUnit(un:getID(), 'No '..squadName..' onboard.', 10)
					else
						trigger.action.outTextForUnit(un:getID(), 'No infantry onboard.', 10)
					end

					return
				end
				
				local zn = ZoneCommand.getZoneOfUnit(un:getName())
				if not zn then 
					zn = CarrierCommand.getCarrierOfUnit(un:getName())
				end

				for _, sq in ipairs(toUnload) do
					local squadName = PlayerLogistics.getInfantryName(sq.type)
					local lastLoad = sq.loadedAt
					if lastLoad and zn and zn.side == un:getCoalition() and zn.name==lastLoad.name then
						if self.registeredSquadGroups[sq.type] then
							local cost = self.registeredSquadGroups[sq.type].cost
							zn:addResource(cost)
							zn:refreshText()
							trigger.action.outTextForUnit(un:getID(), squadName..' unloaded', 10)
						end
					else
						if sq.type == PlayerLogistics.infantryTypes.extractable then
							if not zn then
								trigger.action.outTextForUnit(un:getID(), 'Can only unload extracted infantry while within a friendly zone', 10)
								table.insert(remaining, sq)
							elseif zn.side ~= un:getCoalition() then
								trigger.action.outTextForUnit(un:getID(), 'Can only unload extracted infantry while within a friendly zone', 10)
								table.insert(remaining, sq)
							else
								trigger.action.outTextForUnit(un:getID(), 'Infantry recovered', 10)
								zn:addResource(200)
								zn:refreshText()
								
								if un.getPlayerName then
									local player = un:getPlayerName()
									local xp = RewardDefinitions.actions.squadExtract * DependencyManager.get("PlayerTracker"):getPlayerMultiplier(player)
			
									DependencyManager.get("PlayerTracker"):addStat(player, math.floor(xp), PlayerTracker.statTypes.xp)
									DependencyManager.get("MissionTracker"):tallyUnloadSquad(player, zn.name, sq.type)
									trigger.action.outTextForUnit(un:getID(), '+'..math.floor(xp)..' XP', 10)
								end
							end
						elseif self.registeredSquadGroups[sq.type] then
							local pos = Utils.getPointOnSurface(un:getPoint())
		
							local error = DependencyManager.get("SquadTracker"):spawnInfantry(self.registeredSquadGroups[sq.type], pos)
							
							if not error then
								trigger.action.outTextForUnit(un:getID(), squadName..' deployed', 10)
		
								if un.getPlayerName then
									local player = un:getPlayerName()
									local xp = RewardDefinitions.actions.squadDeploy * DependencyManager.get("PlayerTracker"):getPlayerMultiplier(player)
				
									DependencyManager.get("PlayerTracker"):addStat(player, math.floor(xp), PlayerTracker.statTypes.xp)

									if zn then
										DependencyManager.get("MissionTracker"):tallyUnloadSquad(player, zn.name, sq.type)
									else
										DependencyManager.get("MissionTracker"):tallyUnloadSquad(player, '', sq.type)
									end
									trigger.action.outTextForUnit(un:getID(), '+'..math.floor(xp)..' XP', 10)
								end
							else
								trigger.action.outTextForUnit(un:getID(), 'Failed to deploy squad, no suitable location nearby', 10)
								table.insert(remaining, sq)
							end
						else
							trigger.action.outText("ERROR: SQUAD TYPE NOT REGISTERED", 60)
						end
					end
				end
				
				self.carriedInfantry[gr:getID()] = remaining
				local weight = self:getCarriedPersonWeight(groupname)
				trigger.action.setUnitInternalCargo(un:getName(), weight)
			end
		end
	end

	function PlayerLogistics:unloadAll(groupname)
		local gr = Group.getByName(groupname)
		if gr then 
			local un = gr:getUnit(1)
			if un then
				local cargo = self.carriedCargo[gr:getID()]
				local squad = self.carriedInfantry[gr:getID()]
				local pilot = self.carriedPilots[gr:getID()]

				if cargo and cargo>0 then
					self:unloadSupplies({group=groupname, amount=9999999})
				end

				if squad and #squad>0 then
					self:unloadInfantry({group=groupname})
				end

				if pilot and #pilot>0 then
					self:unloadPilots(groupname)
				end
			end
		end
	end
	
	function PlayerLogistics:cargoStatus(groupName)
		local gr = Group.getByName(groupName)
		if gr then
			local un = gr:getUnit(1)
			if un then
				local onboard = self.carriedCargo[gr:getID()]
				if onboard and onboard > 0 then
					local weight = self.getWeight(onboard)
					trigger.action.outTextForUnit(un:getID(), onboard..' supplies onboard. ('..weight..' kg)', 10)
				else
					local msg = ''
					local squads = self.carriedInfantry[gr:getID()]
					if squads and #squads>0 then
						msg = msg..'Squads:\n'

						for _,squad in ipairs(squads) do
							local infName = PlayerLogistics.getInfantryName(squad.type)
							msg = msg..'  \n'..infName..' (Size: '..squad.size..')'
						end
					end

					local pilots = self.carriedPilots[gr:getID()]
					if pilots and #pilots>0 then
						msg = msg.."\n\nPilots:\n"
						for i,v in ipairs(pilots) do
							msg = msg..'\n '..v
						end

					end
					
					local max = PlayerLogistics.allowedTypes[un:getDesc().typeName].personCapacity
					local occupied = self:getOccupiedPersonCapacity(groupName)

					msg = msg..'\n\nCapacity: '..occupied..'/'..max
					
					msg = msg..'\n('..self:getCarriedPersonWeight(groupName)..' kg)'

					if un:getDesc().typeName == 'Hercules' then
						local preped = self.hercPreparedDrops[gr:getID()]
						if preped then
							if preped == 'supplies' then
								msg = msg..'\nSupplies prepared for next drop.'
							else
								local squadName = PlayerLogistics.getInfantryName(preped)
								msg = msg..'\n'..squadName..' prepared for next drop.'
							end
						end
					end

					trigger.action.outTextForUnit(un:getID(), msg, 10)
				end
			end
		end
	end

	function PlayerLogistics:isCargoDoorOpen(unit)
		if unit then
			local tp = unit:getDesc().typeName
			if tp == "Mi-8MT" then
				if unit:getDrawArgumentValue(86) == 1 then return true end
				if unit:getDrawArgumentValue(38) > 0.85 then return true end
			elseif tp == "UH-1H" then
				if unit:getDrawArgumentValue(43) == 1 then return true end
				if unit:getDrawArgumentValue(44) == 1 then return true end
			elseif tp == "Mi-24P" then
				if unit:getDrawArgumentValue(38) == 1 then return true end
				if unit:getDrawArgumentValue(86) == 1 then return true end
			elseif tp == "Hercules" then
				if unit:getDrawArgumentValue(1215) == 1 and unit:getDrawArgumentValue(1216) == 1 then return true end
			elseif tp == "UH-60L" then
				if unit:getDrawArgumentValue(401) == 1 then return true end
				if unit:getDrawArgumentValue(402) == 1 then return true end
			elseif tp == "SA342Mistral" then
				if unit:getDrawArgumentValue(34) == 1 then return true end
				if unit:getDrawArgumentValue(38) == 1 then return true end
			elseif tp == "SA342L" then
				if unit:getDrawArgumentValue(34) == 1 then return true end
				if unit:getDrawArgumentValue(38) == 1 then return true end
			elseif tp == "SA342M" then
				if unit:getDrawArgumentValue(34) == 1 then return true end
				if unit:getDrawArgumentValue(38) == 1 then return true end
			elseif tp == "SA342Minigun" then
				if unit:getDrawArgumentValue(34) == 1 then return true end
				if unit:getDrawArgumentValue(38) == 1 then return true end
			else
				return true
			end
		end
	end
	
	function PlayerLogistics:loadSupplies(params)
		if not ZoneCommand then return end
		
		local groupName = params.group
		local amount = params.amount
		
		local gr = Group.getByName(groupName)
		if gr then
			local un = gr:getUnit(1)
			if un then
				if not self:canFitCargo(groupName) then
					trigger.action.outTextForUnit(un:getID(), 'Can not load cargo. Personnel onboard.', 10)
					return
				end

				if Utils.isInAir(un) then
					trigger.action.outTextForUnit(un:getID(), 'Can not load supplies while in air', 10)
					return
				end
				
				local zn = ZoneCommand.getZoneOfUnit(un:getName())
				if not zn then 
					zn = CarrierCommand.getCarrierOfUnit(un:getName())
				end

				if not zn then
					trigger.action.outTextForUnit(un:getID(), 'Can only load supplies while within a friendly zone', 10)
					return
				end
				
				if zn.side ~= un:getCoalition() then
					trigger.action.outTextForUnit(un:getID(), 'Can only load supplies while within a friendly zone', 10)
					return
				end

				if not self:isCargoDoorOpen(un) then
					trigger.action.outTextForUnit(un:getID(), 'Can not load supplies while cargo door closed', 10)
					return
				end

				if zn:criticalOnSupplies() then
					trigger.action.outTextForUnit(un:getID(), 'Can not load supplies, zone is low on resources', 10)
					return
				end

				if zn.resource < zn.spendTreshold + amount then
					trigger.action.outTextForUnit(un:getID(), 'Can not load supplies if resources would fall to a critical level.', 10)
					return
				end

				local carried = self.carriedCargo[gr:getID()] or 0
				if amount > zn.resource then
					amount = zn.resource
				end
				
				zn:removeResource(amount)
				zn:refreshText()
				self.carriedCargo[gr:getID()] = carried + amount
				self.lastLoaded[gr:getID()] = zn
				local onboard = self.carriedCargo[gr:getID()]
				local weight = self.getWeight(onboard)

				if un:getDesc().typeName == "Hercules" then
					local loadedInCrates = 0
					local ammo = un:getAmmo()
					if ammo then 
						for _,load in ipairs(ammo) do
							if load.desc.typeName == 'weapons.bombs.Generic Crate [20000lb]' then
								loadedInCrates = 9000 * load.count
							end
						end
					end

					local internal = 0
					if weight > loadedInCrates then
						internal = weight - loadedInCrates
					end

					trigger.action.setUnitInternalCargo(un:getName(), internal)
				else
					trigger.action.setUnitInternalCargo(un:getName(), weight)
				end

				trigger.action.outTextForUnit(un:getID(), amount..' supplies loaded', 10)
				trigger.action.outTextForUnit(un:getID(), onboard..' supplies onboard. ('..weight..' kg)', 10)
			end
		end
	end
	
	function PlayerLogistics:unloadSupplies(params)
		if not ZoneCommand then return end
		
		local groupName = params.group
		local amount = params.amount
		
		local gr = Group.getByName(groupName)
		if gr then
			local un = gr:getUnit(1)
			if un then
				if Utils.isInAir(un) then
					trigger.action.outTextForUnit(un:getID(), 'Can not unload supplies while in air', 10)
					return
				end
				
				local zn = ZoneCommand.getZoneOfUnit(un:getName())
				if not zn then 
					zn = CarrierCommand.getCarrierOfUnit(un:getName())
				end
				
				if not zn then
					trigger.action.outTextForUnit(un:getID(), 'Can only unload supplies while within a friendly zone', 10)
					return
				end
				
				if zn.side ~= 0 and zn.side ~= un:getCoalition()then
					trigger.action.outTextForUnit(un:getID(), 'Can only unload supplies while within a friendly zone', 10)
					return
				end

				if not self:isCargoDoorOpen(un) then
					trigger.action.outTextForUnit(un:getID(), 'Can not unload supplies while cargo door closed', 10)
					return
				end

				if not self.carriedCargo[gr:getID()] or self.carriedCargo[gr:getID()] == 0 then
					trigger.action.outTextForUnit(un:getID(), 'No supplies loaded', 10)
					return
				end
				
				local carried = self.carriedCargo[gr:getID()]
				if amount > carried then
					amount = carried
				end
				
				self.carriedCargo[gr:getID()] = carried-amount
				zn:addResource(amount)

				local lastLoad = self.lastLoaded[gr:getID()]
				self:awardSupplyXP(lastLoad, zn, un, amount)

				zn:refreshText()
				local onboard = self.carriedCargo[gr:getID()]
				local weight = self.getWeight(onboard)
			
				if un:getDesc().typeName == "Hercules" then
					local loadedInCrates = 0
					local ammo = un:getAmmo()
					for _,load in ipairs(ammo) do
						if load.desc.typeName == 'weapons.bombs.Generic Crate [20000lb]' then
							loadedInCrates = 9000 * load.count
						end
					end

					local internal = 0
					if weight > loadedInCrates then
						internal = weight - loadedInCrates
					end
					
					trigger.action.setUnitInternalCargo(un:getName(), internal)
				else
					trigger.action.setUnitInternalCargo(un:getName(), weight)
				end

				trigger.action.outTextForUnit(un:getID(), amount..' supplies unloaded', 10)
				trigger.action.outTextForUnit(un:getID(), onboard..' supplies remaining onboard. ('..weight..' kg)', 10)
			end
		end
	end
end

