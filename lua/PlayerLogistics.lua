



PlayerLogistics = {}
do
	PlayerLogistics.allowedTypes = {}
	PlayerLogistics.allowedTypes['Mi-24P'] = { supplies = true, sling = true, personCapacity = 8, boxCapacity=2 }
	PlayerLogistics.allowedTypes['Mi-8MT'] = { supplies = true, sling = true, personCapacity = 24, boxCapacity=4 }
	PlayerLogistics.allowedTypes['UH-1H'] = { supplies = true, sling = true, personCapacity = 12, boxCapacity=1}
	PlayerLogistics.allowedTypes['Hercules'] = { supplies = true, sling = false, personCapacity = 92, boxCapacity=20 }
	PlayerLogistics.allowedTypes['UH-60L'] = { supplies = true, sling = true, personCapacity = 12, boxCapacity=2}
	PlayerLogistics.allowedTypes['Ka-50'] = { supplies = false, sling = false}
	PlayerLogistics.allowedTypes['Ka-50_3'] = { supplies = false, sling = false}
	PlayerLogistics.allowedTypes['SA342L'] = { supplies = true, sling = false, personCapacity = 1}
	PlayerLogistics.allowedTypes['SA342M'] = { supplies = true, sling = false, personCapacity = 1}
	PlayerLogistics.allowedTypes['SA342Minigun'] = { supplies = true, sling = false, personCapacity = 1}
	PlayerLogistics.allowedTypes['OH-6A'] = { supplies = true, sling = true, personCapacity = 4, boxCapacity=1}
	PlayerLogistics.allowedTypes['AH-64D_BLK_II'] = { supplies = false, sling = false}
	PlayerLogistics.allowedTypes['OH58D'] = { supplies = false, sling = false}
	PlayerLogistics.allowedTypes['CH-47Fbl1'] = { supplies = true, sling = true, personCapacity = 33}

	PlayerLogistics.allowedTypes['M 818'] = 				{ isCA = true, supplies = false, sling=true, personCapacity = 12, boxCapacity=4}
	PlayerLogistics.allowedTypes['M-2 Bradley'] = 			{ isCA = true, supplies = false, sling=true, personCapacity = 6, boxCapacity=1}
	PlayerLogistics.allowedTypes['M6 Linebacker'] = 		{ isCA = true, supplies = false, sling=true, personCapacity = 6, boxCapacity=1}
	PlayerLogistics.allowedTypes['M-113'] = 				{ isCA = true, supplies = false, sling=true, personCapacity = 12, boxCapacity=1}
	PlayerLogistics.allowedTypes['MaxxPro_MRAP'] = 			{ isCA = true, supplies = false, sling=true, personCapacity = 10, boxCapacity=1}
	PlayerLogistics.allowedTypes['M1043 HMMWV Armament'] = 	{ isCA = true, supplies = false, sling=true, personCapacity = 6, boxCapacity=1}
	PlayerLogistics.allowedTypes['Land_Rover_101_FC'] = 	{ isCA = true, supplies = false, sling=true, personCapacity = 4, boxCapacity=2}

	PlayerLogistics.groundVehicles = {
		['truck'] = 	{ price =  100, template='player-truck',  		label='truck', isCW = true },
		['truck2'] = 	{ price =  50, 	template='player-truck-small',  label='truck', isCW = true },
		['brad'] = 		{ price = 1500, template='player-brad',  		label='ifv'},
		['bradaa'] = 	{ price = 2000, template='player-bradaa',  		label='ifv'   },
		['mlrs'] = 		{ price = 3500, template='player-mlrs', 		label='arty'  },
		['abrams'] = 	{ price = 2500, template='player-abrams', 		label='tank'  },
		['mrap'] = 		{ price = 1000, template='player-mrap',  		label='apc'   },
		['hmvaa'] = 	{ price = 1500, template='player-hmaa',  		label='sam'   },
		['patton'] = 	{ price = 2000, template='player-m60', 			label='tank', 	isCW = true  },
		['m113'] = 		{ price = 1000, template='player-m113',  		label='apc', 	isCW = true   },
		['hmv'] = 		{ price = 500, 	template='player-hm',  			label='sup', 	isCW = true   },
		['gepard'] =	{ price = 1500, template='player-gepard',  		label='aaa', 	isCW = true   },
		['arty'] = 		{ price = 2500, template='player-arty', 		label='arty', 	isCW = true  }
	}

	PlayerLogistics.startingMP = 10800

	PlayerLogistics.hercVehicles = {
		['weapons.bombs.APC M1043 HMMWV Armament Air [7023lb]'] = 	{ tag='hmv', hasChute=true},
		['weapons.bombs.APC M113 Air [21624lb]'] = 					{ tag='m113', hasChute=true},
		['weapons.bombs.SAM Avenger M1097 Air [7200lb]'] = 			{ tag='hmvaa', hasChute=true},
		['weapons.bombs.APC M1043 HMMWV Armament Skid [6912lb]'] =  { tag='hmv', hasChute=false},
		['weapons.bombs.APC M113 Skid [21494lb]'] = 				{ tag='m113', hasChute=false},
		['weapons.bombs.SAM Avenger M1097 Skid [7090lb]'] = 		{ tag='hmvaa', hasChute=false},
		['weapons.bombs.IFV M2A2 Bradley [34720lb]'] = 				{ tag='brad', hasChute=false},
		['weapons.bombs.Transport M818 [16000lb]'] = 				{ tag='truck', hasChute=false},
		['weapons.bombs.SAM LINEBACKER [34720lb]'] = 				{ tag='bradaa', hasChute=false},
	}

	PlayerLogistics.infantryTypes = {
		capture = 'capture',
		sabotage = 'sabotage',
		ambush = 'ambush',
		engineer = 'engineer',
		manpads = 'manpads',
		spy = 'spy',
		rapier = 'rapier',
		assault = 'assault',
		extractable = 'extractable'
	}

	PlayerLogistics.buildables = {
		farp = 'farp-pad',
		fuel = 'fuel-barrels',
		ammo = 'ammo-boxes',
		medtent = 'tent_2',
		tent = 'tent_1',
		generator = 'hesco_gen',
		radar = 'hawksr',
		satuplink = 'hawkpcp',
		forklift = 'forklift'
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
		elseif infType==PlayerLogistics.infantryTypes.assault then
			return "Assault Squad"
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
		obj.carriedBoxes = {} -- groupid = source
		obj.registeredSquadGroups = {}
		obj.lastLoaded = {} -- groupid = zonename

		obj.trackedPlayerVehicles = {}

		obj.hercTracker = {
			cargos = {},
			cargoCheckFunctions = {}
		}

		obj.hercPreparedDrops = {}

		obj.trackedBoxes = {}
		obj.trackedBuildings = {}

		obj.humanResource = {
			max = 15,
			current = 10,
			progress = 0,
			spawncost = 60*30
		}
		
		setmetatable(obj, self)
		self.__index = self
		
		obj:start()
		
		DependencyManager.register("PlayerLogistics", obj)
		return obj
	end

	function PlayerLogistics:restorePlayerVehicles(savedVehicles)
		for i,v in pairs(savedVehicles) do
		
			local result = Spawner.createPlayerVehicle(v.template.template, v.name, v.pos, v.side)
			if result then
				self.trackedPlayerVehicles[v.name] = { name = v.name, template = v.template, side = v.side, mp = v.mp}

				if v.carry.carriedInfantry then
					for i,v in ipairs(v.carry.carriedInfantry) do
						if v.loadedAt then
							local zn = ZoneCommand.getZoneByName(v.loadedAt)
							if not zn then
								zn = FARPCommand.getFARPByName(v.loadedAt)
							end

							if not zn then
								zn = CarrierCommand.getCarrierByName(v.loadedAt)
							end

							v.loadedAt = zn
						end
					end
				end

				timer.scheduleFunction(function(param,time)
					local g = Group.getByName(param.data.name)
					if g then
						param.context.carriedCargo[g:getID()] = param.data.carry.carriedCargo
						param.context.carriedInfantry[g:getID()]  = param.data.carry.carriedInfantry
						param.context.carriedPilots[g:getID()]  = param.data.carry.carriedPilots
						param.context.carriedBoxes[g:getID()]  = param.data.carry.carriedBoxes
					end
				end, {context = self, data = v}, timer.getTime()+1)
			end
		end
	end

	function PlayerLogistics:registerSquadGroup(squadType, groupname, weight, cost, jobtime, extracttime, squadSize, side)
		self.registeredSquadGroups[squadType] = { name=groupname, type=squadType, weight=weight, cost=cost, jobtime=jobtime, extracttime=extracttime, size = squadSize, side=side}
	end
	
	function PlayerLogistics:start()
		if not ZoneCommand then return end
	
        MenuRegistry.register(3, function(event, context)
			if (event.id == world.event.S_EVENT_PLAYER_ENTER_UNIT or event.id == world.event.S_EVENT_BIRTH) and event.initiator and event.initiator.getPlayerName then
				local player = event.initiator:getPlayerName()
				if player then
					local unitType = event.initiator:getDesc()['typeName']
					local groupid = event.initiator:getGroup():getID()
					local groupname = event.initiator:getGroup():getName()
					
					local logistics = context.allowedTypes[unitType]
					
					if logistics and (logistics.supplies or logistics.sling or logistics.personCapacity) then
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
								missionCommands.addCommandForGroup(groupid, 'Unload as fuel (1:1)', unloadMenu, Utils.log(context.unloadSupplies), context, {group=groupname, amount=1000, convert='fuel'})
								missionCommands.addCommandForGroup(groupid, 'Unload as munitions (50:1)', unloadMenu, Utils.log(context.unloadSupplies), context, {group=groupname, amount=1000, convert='ammo'})
							end

							if logistics.sling or logistics.boxCapacity then
								local crateMenu = missionCommands.addSubMenuForGroup(groupid, 'Crates', cargomenu)


								local supMenu = missionCommands.addSubMenuForGroup(groupid, 'Supply', crateMenu)
								missionCommands.addCommandForGroup(groupid, 'Supply Crate (500)', supMenu, Utils.log(context.packSupplies), context, {group=groupname, amount=500})
								missionCommands.addCommandForGroup(groupid, 'Supply Crate (1000)', supMenu, Utils.log(context.packSupplies), context, {group=groupname, amount=1000})
								missionCommands.addCommandForGroup(groupid, 'Supply Crate (2000)', supMenu, Utils.log(context.packSupplies), context, {group=groupname, amount=2000})
								missionCommands.addCommandForGroup(groupid, 'Fuel Crate (1000)', supMenu, Utils.log(context.packSupplies), context, {group=groupname, amount=1000, convert='fuel'})
								missionCommands.addCommandForGroup(groupid, 'Munitions Crate (1000)', supMenu, Utils.log(context.packSupplies), context, {group=groupname, amount=1000, convert='ammo'})
								
								local farpMenu = missionCommands.addSubMenuForGroup(groupid, 'FARP', crateMenu)
								missionCommands.addCommandForGroup(groupid, 'Landing pad (2000)', farpMenu, Utils.log(context.packSupplies), context, {group=groupname, amount=2000, content=PlayerLogistics.buildables.farp})
								missionCommands.addCommandForGroup(groupid, 'Radar (2000)', farpMenu, Utils.log(context.packSupplies), context, {group=groupname, amount=2000, content=PlayerLogistics.buildables.radar})
								missionCommands.addCommandForGroup(groupid, 'Ammo Cache (500)', farpMenu, Utils.log(context.packSupplies), context, {group=groupname, amount=500, content=PlayerLogistics.buildables.ammo})
								missionCommands.addCommandForGroup(groupid, 'Fuel Cache (500)', farpMenu, Utils.log(context.packSupplies), context, {group=groupname, amount=500, content=PlayerLogistics.buildables.fuel})
								missionCommands.addCommandForGroup(groupid, 'Field hospital (1000)', farpMenu, Utils.log(context.packSupplies), context, {group=groupname, amount=1000, content=PlayerLogistics.buildables.medtent})
								missionCommands.addCommandForGroup(groupid, 'Command center (1500)', farpMenu, Utils.log(context.packSupplies), context, {group=groupname, amount=1500, content=PlayerLogistics.buildables.tent})
								missionCommands.addCommandForGroup(groupid, 'Generator (2000)', farpMenu, Utils.log(context.packSupplies), context, {group=groupname, amount=2000, content=PlayerLogistics.buildables.generator})
								missionCommands.addCommandForGroup(groupid, 'Satellite Uplink (1000)', farpMenu, Utils.log(context.packSupplies), context, {group=groupname, amount=1000, content=PlayerLogistics.buildables.satuplink})
								missionCommands.addCommandForGroup(groupid, 'Fork Lift (1000)', farpMenu, Utils.log(context.packSupplies), context, {group=groupname, amount=1000, content=PlayerLogistics.buildables.forklift})
								
								missionCommands.addCommandForGroup(groupid, 'Unpack Crate', crateMenu, Utils.log(context.unpackSupplies), context, {group=groupname})
								
								missionCommands.addCommandForGroup(groupid, 'Load Crate', crateMenu, Utils.log(context.loadClosestCrate), context, groupname)
								missionCommands.addCommandForGroup(groupid, 'Unload Crate', crateMenu, Utils.log(context.unloadCrates), context, groupname)
								if not logistics.isCA then
									missionCommands.addCommandForGroup(groupid, 'Pickup guidance(closest)', crateMenu, Utils.log(context.startSlingGuidance), context, groupname)
								end
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
									local menuName =  'Load '..PlayerLogistics.getInfantryName(sqType)..'('..context.registeredSquadGroups[sqType].size..')'
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

							if logistics.personCapacity or logistics.supplies then
								missionCommands.addCommandForGroup(groupid, 'Status', cargomenu, Utils.log(context.cargoStatus), context, groupname)
								missionCommands.addCommandForGroup(groupid, 'Unload Everything', cargomenu, Utils.log(context.unloadAll), context, groupname)
							end
							
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
						
						if not logistics.isCA then
							if context.carriedCargo[groupid] then
								context.carriedCargo[groupid] = 0
							end
							
							if context.carriedBoxes[groupid] then
								context.carriedBoxes[groupid] = {}
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
						end
							
						if context.hercPreparedDrops[groupid] then
							context.hercPreparedDrops[groupid] = nil
						end
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

				if PlayerLogistics.hercVehicles[name] then
					local veh = PlayerLogistics.hercVehicles[name]
					local pv = PlayerLogistics.groundVehicles[veh.tag]

					local carried = self.context.carriedCargo[groupId]
					if carried and carried >= pv.price then
						self.context.carriedCargo[groupId] = math.max(0,self.context.carriedCargo[groupId] - pv.price)
					else
						event.weapon:destroy()
						return
					end
						
					if veh.hasChute then
						if not self.context.hercTracker.cargos[unitName] then
							self.context.hercTracker.cargos[unitName] = {}
						end
						
						table.insert(self.context.hercTracker.cargos[unitName],{
							object = event.weapon,
							vehicle = veh,
							lastLoaded = self.context.lastLoaded[groupId],
							unit = event.initiator
						})
						
						env.info('PlayerLogistics - Hercules - '..unitName..' deployed '..veh.tag)
						self.context:processHercCargos(unitName)
					else
						if Utils.getAGL(event.weapon) > 5 then
							event.weapon:destroy()
						else
							local pos = Utils.getPointOnSurface(event.weapon:getPoint())
							local num = math.floor(timer.getTime())
							local rand = math.random(100,999)
							local name = 'player-'..pv.label..num..rand
							local result = Spawner.createPlayerVehicle(pv.template, name, pos, 2)
							if result then
								self.context.trackedPlayerVehicles[name] = { name = name, template = pv, side = 2, mp = PlayerLogistics.startingMP}
							end
						end
					end
				end
			end
		end
		
		world.addEventHandler(ev)

		timer.scheduleFunction(function(param,time)
			for i,v in pairs(param.context.trackedBoxes) do
				v.lifetime = v.lifetime - 10
				if v.lifetime <= 0 then
					local box = StaticObject.getByName(i) or Unit.getByName(i)
					if box then
						if Utils.isLanded(box) then
							local zn = ZoneCommand.getZoneOfPoint(box:getPoint())
							if not zn then zn = FARPCommand.getFARPOfPoint(box:getPoint()) end

							if zn then 
								zn:addResource(v.amount)
								zn:refreshText()
							end

							box:destroy() 
						else
							v.lifetime = 15*60
						end
					end
					param.context.trackedBoxes[v] = nil
				end
			end

			if param.context.humanResource.current < param.context.humanResource.max then
				param.context.humanResource.progress = param.context.humanResource.progress + 60
			end

			if param.context.humanResource.progress >= param.context.humanResource.spawncost then
				param.context.humanResource.progress = 0
				param.context.humanResource.current = param.context.humanResource.current + 1
			end

			for i,v in pairs(param.context.trackedPlayerVehicles) do
				local g = Group.getByName(v.name)
				if g and g:isExist() and g:getSize()>0 then
					local u = g:getUnit(1)

					MenuRegistry.triggerMenusForUnit(u)

					local zn = ZoneCommand.getZoneOfPoint(u:getPoint())
					if not zn then 
						zn = FARPCommand.getFARPOfPoint(u:getPoint())
					end

					local hadMessage = false
					if zn and zn.side == u:getCoalition() then
						local amount = 60*5
						local cost = amount/10

						if v.mp < PlayerLogistics.startingMP and zn.resource > cost then
							v.mp = math.min(v.mp + amount, PlayerLogistics.startingMP)
							zn:removeResource(cost)
							
							local msg = 'Vehicle Maintenance: '..string.format("%.0f", (math.max(v.mp,0)/PlayerLogistics.startingMP)*100)..'%'
							trigger.action.outTextForUnit(u:getID(), msg, 9)
							hadMessage = true
						end
					else
						v.mp = math.max(v.mp - 10, 0)
					end

					if v.mp <= 60*30 and not hadMessage then
						local msg = 'Vehicle Maintenance: '..string.format("%.0f", (math.max(v.mp,0)/PlayerLogistics.startingMP)*100)..'%'

						msg = msg..'\n Enter a friendly zone to recover'

						trigger.action.outTextForUnit(u:getID(), msg, 9)
					end
					
					if v.mp <= 0 and math.random()<0.05 then
						local msg = 'Vehicle broke down'
						trigger.action.outTextForUnit(u:getID(), msg, 10)
						trigger.action.explosion(u:getPoint(), 20)
					end
				else
					param.context.trackedPlayerVehicles[i] = nil
				end
			end

			return time+10
		end, {context = self}, timer.getTime()+10)

		DependencyManager.get("MarkerCommands"):addCommand('remove', function(event, _, state)
			local z = FARPCommand.getFARPOfPoint(event.pos)
			if z then 
				z:scheduleRemoval()
				return true
			end
		end, false, self)

        DependencyManager.get("MarkerCommands"):addCommand('spawn',function(event, item, state)
			if not item then return false end

			local z = ZoneCommand.getZoneOfPoint(event.pos)
			if not z then 
				z = FARPCommand.getFARPOfPoint(event.pos) 
				if z and not z:hasFeature(PlayerLogistics.buildables.tent) then
					return false
				end
			end

			if not z then return false end
			if z.side ~= 2 then return false end
			if z:criticalOnSupplies() then return false end

			local options = {}
			for i,v in pairs(PlayerLogistics.groundVehicles) do
				if Config.isColdWar then
					if v.isCW then
						options[i] = v
					end
				else
					options[i] = v
				end
			end

			if item == 'ls' then
				local sortedop = {}
				for i,v in pairs(options) do
					v.name = i
					table.insert(sortedop, v)
				end

				table.sort(sortedop, function(a,b) return a.name < b.name end)

				local m = ''
				for i,v in pairs(sortedop) do
					m = m..'\nspawn:'..v.name..' ['..v.price..']'
				end

				trigger.action.outText(m,10)
				return false
			end

			local op = options[item]

			if op and z.resource >= op.price then
				local num = math.floor(timer.getTime())
				local rand = math.random(100,999)
				local name = 'player-'..op.label..num..rand
				local result = Spawner.createPlayerVehicle(op.template, name, event.pos, 2)
				if result then
					z:removeResource(op.price)
					z:refreshText()
					state.trackedPlayerVehicles[name] = { name = name, template = op, side = 2, mp = PlayerLogistics.startingMP}
					return true
				end
			end
        end, true, self)
	end

	function PlayerLogistics:processHercCargos(unitName)
		if not self.hercTracker.cargoCheckFunctions[unitName] then
			env.info('PlayerLogistics - Hercules - start tracking cargos of '..unitName)
			self.hercTracker.cargoCheckFunctions[unitName] = timer.scheduleFunction(function(params, time)
				local reschedule = params.context:checkHercCargo(params.unitName, time)
				if not reschedule then
					params.context.hercTracker.cargoCheckFunctions[params.unitName] = nil
					env.info('PlayerLogistics - Hercules - stopped tracking cargos of '..params.unitName)
				end
				
				return reschedule
			end, {unitName=unitName, context = self}, timer.getTime()+0.1)
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
					env.info('PlayerLogistics - Hercules - cargo crashed '..tostring(cargo.supply))
					if cargo.squad then 
						env.info('PlayerLogistics - Hercules - squad crashed '..tostring(cargo.squad.type))
					end

					if cargo.vehicle then 
						env.info('PlayerLogistics - Hercules - vehicle crashed '..tostring(cargo.vehicle.tag))
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
				if not zone then zone = FARPCommand.getFARPOfWeapon(cargo.object) end
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
					if not zn then FARPCommand.getFARPOfPoint(pos) end
					
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
			elseif cargo.vehicle then
				local pos = Utils.getPointOnSurface(cargo.object:getPoint())
				pos.y = pos.z
				pos.z = nil
				local surface = land.getSurfaceType(pos)
				if surface == land.SurfaceType.LAND or surface == land.SurfaceType.ROAD or surface == land.SurfaceType.RUNWAY then
					local pv = PlayerLogistics.groundVehicles[cargo.vehicle.tag]
					local pos = Utils.getPointOnSurface(cargo.object:getPoint())
					local num = math.floor(timer.getTime())
					local rand = math.random(100,999)
					local name = 'player-'..pv.label..num..rand
					local result = Spawner.createPlayerVehicle(pv.template, name, pos, 2)
					if result then
						self.trackedPlayerVehicles[name] = { name = name, template = pv, side = 2, mp = PlayerLogistics.startingMP}
					end
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

	function PlayerLogistics:getCarriedBoxWeight(groupname)
		local gr = Group.getByName(groupname)
		local un = gr:getUnit(1)
		if un then
			if not PlayerLogistics.allowedTypes[un:getDesc().typeName] then return 0 end
			
			local max = PlayerLogistics.allowedTypes[un:getDesc().typeName].boxCapacity

			if not self.carriedBoxes[gr:getID()] then self.carriedBoxes[gr:getID()] = {} end
			local boxes = self.carriedBoxes[gr:getID()]
			local weight = 0
			for i,v in ipairs(boxes) do
				weight = weight + PlayerLogistics.getWeight(v.amount)
			end

			return weight
		end
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
				pilotWeight = 70 * #pilots
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
			if self.carriedBoxes[gr:getID()] and #self.carriedBoxes[gr:getID()] > 0 then return 0 end
			
			local max = PlayerLogistics.allowedTypes[un:getDesc().typeName].personCapacity

			local total = self:getOccupiedPersonCapacity(groupname)

			return max - total
		end
	end

	function PlayerLogistics:canFitBoxes(groupname)
		local gr = Group.getByName(groupname)
		local un = gr:getUnit(1)
		if un then
			if not PlayerLogistics.allowedTypes[un:getDesc().typeName] then return false end
			if not PlayerLogistics.allowedTypes[un:getDesc().typeName].boxCapacity then return false end
			if self:getOccupiedPersonCapacity(groupname) > 0 then return false end
			if self.carriedCargo[gr:getID()] and self.carriedCargo[gr:getID()] > 0 then return 0 end

			local carried = 0
			if self.carriedBoxes[gr:getID()] then
				carried = #self.carriedBoxes[gr:getID()]
			end
			
			return carried  < PlayerLogistics.allowedTypes[un:getDesc().typeName].boxCapacity
		end
	end

	function PlayerLogistics:canFitCargo(groupname)
		local gr = Group.getByName(groupname)
		local un = gr:getUnit(1)
		if un then
			if not PlayerLogistics.allowedTypes[un:getDesc().typeName] then return false end
			if self:getOccupiedPersonCapacity(groupname) > 0 then return false end
			if self.carriedBoxes[gr:getID()] and #self.carriedBoxes[gr:getID()] > 0 then return false end

			return true
		end
	end

	function PlayerLogistics:canFitPersonnel(groupname, toFit)
		local gr = Group.getByName(groupname)
		local un = gr:getUnit(1)
		if un then
			if not PlayerLogistics.allowedTypes[un:getDesc().typeName] then return false end
			if self.carriedBoxes[gr:getID()] and #self.carriedBoxes[gr:getID()] > 0 then return false end

			return self:getRemainingPersonCapacity(groupname) >= toFit
		end
	end

	function PlayerLogistics:getClosestBox(pos, dist)
		if not dist then dist = 500 end
		local closest = nil
		local mindist = 99999
		for i,v in pairs(self.trackedBoxes) do
			local obj = StaticObject.getByName(i) or Unit.getByName(i)
			if obj and obj:isExist() then
				local d = mist.utils.get2DDist(obj:getPoint(), pos)
				if d<=dist and d<=mindist then
					mindist = d
					closest = v
				end
			end
		end

		return closest
	end

	function PlayerLogistics:unloadCrates(groupname, all)
		local gr = Group.getByName(groupname)
		local un = gr:getUnit(1)
		if not self.carriedBoxes[gr:getID()] then self.carriedBoxes[gr:getID()] = {} end

		if not self:isCargoDoorOpen(un) then
			trigger.action.outTextForUnit(un:getID(), 'Can not unload crates while cargo door closed', 10)
			return
		end

		if un then
			if #self.carriedBoxes[gr:getID()] == 0 then
				trigger.action.outTextForUnit(un:getID(), 'No crates onboard', 10)
				return
			end

			if all then
				for i,v in ipairs(self.carriedBoxes[gr:getID()]) do
					local unitPos = un:getPosition()
					local unitheading = math.atan2(unitPos.x.z, unitPos.x.x)

					local ahead = 15
					local area = 5
		
					local vec = {
						x = unitPos.x.x * ahead,
						z = unitPos.x.z * ahead
					}
		
					local offset = un:getPoint()
					offset.x = offset.x + vec.x
					offset.y = offset.z + vec.z
					offset.z = nil
		
					offset.x = offset.x + math.random(-area,area)
					offset.y = offset.y + math.random(-area,area)

					v.pos = offset
					self:restoreBox(v)
					trigger.action.outTextForUnit(un:getID(), 'Unloaded '..v.name, 10)
				end
				
				self.carriedBoxes[gr:getID()] = {}
			else
				local v = self.carriedBoxes[gr:getID()][1]
				local unitPos = un:getPosition()
				local unitheading = math.atan2(unitPos.x.z, unitPos.x.x)

				local ahead = 15
				local area = 5
	
				local vec = {
					x = unitPos.x.x * ahead,
					z = unitPos.x.z * ahead
				}
	
				local offset = un:getPoint()
				offset.x = offset.x + vec.x
				offset.y = offset.z + vec.z
				offset.z = nil
	
				offset.x = offset.x + math.random(-area,area)
				offset.y = offset.y + math.random(-area,area)

				v.pos = offset
				self:restoreBox(v)
				trigger.action.outTextForUnit(un:getID(), 'Unloaded '..v.name, 10)

				table.remove(self.carriedBoxes[gr:getID()], 1)
			end

			local w = self:getCarriedBoxWeight(groupname)
			trigger.action.setUnitInternalCargo(un:getName(), w)
		end
	end
	
	function PlayerLogistics:loadClosestCrate(groupname)
		local gr = Group.getByName(groupname)
		local un = gr:getUnit(1)
		
		if not self.carriedBoxes[gr:getID()] then self.carriedBoxes[gr:getID()] = {} end

		if not self:isCargoDoorOpen(un) then
			trigger.action.outTextForUnit(un:getID(), 'Can not load crates while cargo door closed', 10)
			return
		end

		if un then
			local box = self:getClosestBox(un:getPoint(), 20)

			if box then
				local unitType = un:getDesc()['typeName']
				local logistics = self.allowedTypes[unitType]
				if not self:canFitBoxes(groupname) then
					trigger.action.outTextForUnit(un:getID(), 'Not enough free space onboard.', 10)
					return
				end
				
				local obj = StaticObject.getByName(box.name) or Unit.getByName(box.name)
				if obj then
					table.insert(self.carriedBoxes[gr:getID()], {
                        name = box.name,
                        amount = box.amount, 
                        origin = box.origin.name,
                        side = un:getCoalition(),
                        type = box.type,
                        pos = {},
                        lifetime = box.lifetime,
                        content = box.content,
                        convert = box.convert,
                        isSalvage = box.isSalvage
                    })

					self.trackedBoxes[box.name] = nil
					obj:destroy() 
					trigger.action.outTextForUnit(un:getID(), 'Loaded '..box.name, 10)
					local w = self:getCarriedBoxWeight(groupname)
					trigger.action.setUnitInternalCargo(un:getName(), w)
				end
			else
				trigger.action.outTextForUnit(un:getID(), 'No crates nearby.', 10)
			end
		end
	end

	function PlayerLogistics:startSlingGuidance(groupname)
		local gr = Group.getByName(groupname)
		local un = gr:getUnit(1)
		if un then
			local box = self:getClosestBox(un:getPoint())

			if box then
				trigger.action.outTextForUnit(un:getID(), 'Starting Guidance on '..box.name, 10)

				timer.scheduleFunction(function(param,time)
					local pu = param.unit
					local c = StaticObject.getByName(param.box.name)
					
					if not pu or not pu:isExist() or not c or not c:isExist() or not Utils.isLanded(c) then 
						return 
					end

					local dist = mist.utils.get2DDist(pu:getPoint(), c:getPoint())
					if dist > 500 then return end
					
					param.context:printSlingGuidance(pu,c)
					param.timeout = param.timeout - 1
					return time+1
				end, {box = box, unit = un, timeout = 300, context = self}, timer.getTime()+1)
			else
				trigger.action.outTextForUnit(un:getID(), 'No crates nearby.', 10)
			end
		end
	end

	function PlayerLogistics:printSlingGuidance(unit, cargo)
		local upos = unit:getPoint()
		local cpos = cargo:getPoint()

		local slingoffset = PlayerLogistics.slingPos[unit:getDesc().typeName]

		local altdif = math.abs(upos.y-cpos.y)

		local origin = {
			x = upos.x,
			y = upos.z
		}

		local tgt = {
			x = cpos.x,
			y = cpos.z
		}

		local bearing = math.deg(math.atan2(unit:getPosition().x.z, unit:getPosition().x.x))
		if bearing < 0 then
			bearing = 360+bearing
		end
		
		local localvec = Utils.toLocalVector(origin, tgt)

		local offset = Utils.rotateVector(localvec, bearing)
		

		if slingoffset then
			offset.x = offset.x + slingoffset.fwd
		end

		local msg = ''

		local vright = false
		if offset.x < -1 then 
			msg = " "..math.floor(math.abs(offset.x)).."m\n↓↓↓\n\n\n"
		elseif offset.x > 1 then
			msg = "↑↑↑\n "..math.floor(math.abs(offset.x)).."m\n\n\n"
		else
			msg = "↓↓↓\n  X \n↑↑↑\n\n"
			vright = true
		end
		
		local hright = false
		if offset.y < -1 then 
			right = "" 
			msg = msg.."← ← ← "..math.floor(math.abs(offset.y)).."m"
		elseif offset.y > 1 then
			msg = msg..""..math.floor(math.abs(offset.y)).."m → → →"
		else
			msg = msg.."→ → → X ← ← ←"
			hright = true
		end

		if vright and hright then
			msg =      "      ↓ ↓ ↓\n"
			msg = msg.."→ → → X ← ← ←\n"
			msg = msg.."      ↑ ↑ ↑"
		end

		msg = msg..'\n\n↥ '..math.floor(altdif)..'m ↥'

		trigger.action.outTextForUnit(unit:getID(), msg, 1)
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
					zn = FARPCommand.getFARPOfUnit(un:getName())
					if zn and not zn:hasFeature(PlayerLogistics.buildables.medtent) then
						trigger.action.outTextForUnit(un:getID(), zn.name..' lacks a Field Hospital. Can not offload pilots.', 10)
						return
					end
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

				self.humanResource.current = self.humanResource.current + #pilots

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

				if Utils.isLanded(un, true) then
					local data = DependencyManager.get("CSARTracker"):getClosestPilot(un:getPoint())
					if data and data.dist < 25 then
						self:embarkPilot(gr, un, data)
						return
					else
						trigger.action.outTextForUnit(un:getID(), 'Wait for pilot to board.', 10)
						local pilotgr = Group.getByName(data.name)
						if pilotgr and pilotgr:isExist() then
							TaskExtensions.sendToPoint(pilotgr, un:getPoint())
						end

						timer.scheduleFunction(function(param, time)
							local un = param.player
							local self = param.context
							local pilot = param.pilot
							local gr = un:getGroup()

							if Utils.isInAir(un) then 
								trigger.action.outTextForUnit(un:getID(), 'Extraction aborted. Took off', 10)
								return 
							end

							if not self:isCargoDoorOpen(un) then
								trigger.action.outTextForUnit(un:getID(), 'Extraction aborted. Cargo door closed', 10)
								return
							end

							local pilotgr = Group.getByName(pilot.name)
							if not pilotgr or not pilotgr:isExist() then
								trigger.action.outTextForUnit(un:getID(), 'Extraction aborted. Pilot is MIA.', 10)
								return 
							end

							local psize = pilotgr:getSize()
							if not self:canFitPersonnel(gr:getName(), psize) then
								trigger.action.outTextForUnit(un:getID(), 'Not enough free space onboard. (Need '..psize..')', 10)
								return
							end

							local pPos = un:getPoint()
							local sPos = pilotgr:getUnit(1):getPoint()

							local dist = mist.utils.get2DDist(pPos, sPos)

							if dist < 25 then
								self:embarkPilot(gr, un, pilot)
								return
							else
								return time+5
							end
						end, {context = self, pilot = data, player = un}, timer.getTime()+5)
					end
				else
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
								if data.dist > 25 then
									trigger.action.outTextForUnit(un:getID(), 'Too far (< 25m). Current: '..string.format('%.2f',data.dist)..' m', 1)
								else
									self:embarkPilot(gr, un, data)
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
	end

	function PlayerLogistics:embarkPilot(gr, un, data)
		if not self.carriedPilots[gr:getID()] then self.carriedPilots[gr:getID()] = {} end
		table.insert(self.carriedPilots[gr:getID()], data.name)
		local player = un:getPlayerName()
		DependencyManager.get("MissionTracker"):tallyLoadPilot(player, data)
		DependencyManager.get("CSARTracker"):removePilot(data.name)
		local weight = self:getCarriedPersonWeight(gr:getName())
		trigger.action.setUnitInternalCargo(un:getName(), weight)
		trigger.action.outTextForUnit(un:getID(), data.name..' onboard. ('..weight..' kg)', 10)
	end

	function PlayerLogistics:embarkSquad(gr, un, sqsize, squadgr, squad)
		if not self.carriedInfantry[gr:getID()] then self.carriedInfantry[gr:getID()] = {} end

		table.insert(self.carriedInfantry[gr:getID()],{type = PlayerLogistics.infantryTypes.extractable, size = sqsize, weight = sqsize * 70})
		
		local weight = self:getCarriedPersonWeight(gr:getName())

		trigger.action.setUnitInternalCargo(un:getName(), weight)
		
		local loadedInfName = PlayerLogistics.getInfantryName(PlayerLogistics.infantryTypes.extractable)
		trigger.action.outTextForUnit(un:getID(), loadedInfName..' onboard. ('..weight..' kg)', 10)
		
		local player = un:getPlayerName()
		DependencyManager.get("MissionTracker"):tallyLoadSquad(player, squad)
		DependencyManager.get("SquadTracker"):removeSquad(squad.name)
		
		squadgr:destroy()
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
				if squad and distance < 300 then
					local squadgr = Group.getByName(squad.name)
					if squadgr and squadgr:isExist() then
						local sqsize = squadgr:getSize()
						if not self:canFitPersonnel(groupname, sqsize) then
							trigger.action.outTextForUnit(un:getID(), 'Not enough free space onboard. (Need '..sqsize..')', 10)
							return
						end

						if distance < 25 then
							self:embarkSquad(gr, un, sqsize, squadgr, squad)
						else
							trigger.action.outTextForUnit(un:getID(), 'Wait for squad to board.', 10)
							TaskExtensions.sendToPoint(squadgr, un:getPoint())
							timer.scheduleFunction(function(param, time)
								local un = param.player
								local self = param.context
								local squad = param.squad

								if not un then return end
								
								local gr = un:getGroup()

								if Utils.isInAir(un) then 
									trigger.action.outTextForUnit(un:getID(), 'Extraction aborted. Took off', 10)
									return 
								end

								if not self:isCargoDoorOpen(un) then
									trigger.action.outTextForUnit(un:getID(), 'Extraction aborted. Cargo door closed', 10)
									return
								end

								local squadgr = Group.getByName(squad.name)
								if not squadgr or not squadgr:isExist() then
									trigger.action.outTextForUnit(un:getID(), 'Extraction aborted. Squad is MIA.', 10)
									return 
								end

								local sqsize = squadgr:getSize()
								if not self:canFitPersonnel(gr:getName(), sqsize) then
									trigger.action.outTextForUnit(un:getID(), 'Not enough free space onboard. (Need '..sqsize..')', 10)
									return
								end

								local pPos = un:getPoint()
								
								local sPos = squadgr:getUnit(1):getPoint()

								local dist = mist.utils.get2DDist(pPos, sPos)
								for i,v in ipairs(squadgr:getUnits()) do
									local d = mist.utils.get2DDist(pPos, v:getPoint())
									if d<dist then dist = d end
								end

								if dist < 25 then
									self:embarkSquad(gr, un, sqsize, squadgr, squad)
									return
								else
									return time+5
								end
							end, {context = self, squad = squad, player = un}, timer.getTime()+5)
						end
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
					zn = FARPCommand.getFARPOfUnit(un:getName())
					if zn and not zn:hasFeature(PlayerLogistics.buildables.tent) then
						trigger.action.outTextForUnit(un:getID(), zn.name..' lacks a Command Center. Can not load infantry.', 10)
						return
					end
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

				if squadSize > self.humanResource.current then
					trigger.action.outTextForUnit(un:getID(), 'Can not load infantry, not enough available personnel. [Need: '..squadSize..', Available: '..self.humanResource.current..']', 10)
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

				self.humanResource.current = math.max(self.humanResource.current - squadSize, 0)

				if not self.carriedInfantry[gr:getID()] then self.carriedInfantry[gr:getID()] = {} end
				table.insert(self.carriedInfantry[gr:getID()],{ type = squadType, size = squadSize, weight = squadWeight, loadedAt = zn })
				self.lastLoaded[gr:getID()] = zn
				
				local weight = self:getCarriedPersonWeight(gr:getName())
				trigger.action.setUnitInternalCargo(un:getName(), weight)
				
				local loadedInfName = PlayerLogistics.getInfantryName(squadType)
				trigger.action.outTextForUnit(un:getID(), loadedInfName..' onboard. ('..weight..' kg) '..self.humanResource.current..' personnel remaining.', 10)
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
				
				if not zn then 
					zn = FARPCommand.getFARPOfUnit(un:getName())
					if zn and not zn:hasFeature(PlayerLogistics.buildables.tent) then
						trigger.action.outTextForUnit(un:getID(), zn.name..' lacks a Command Center. Can not unload infantry.', 10)
						zn = nil
					end
				end

				for _, sq in ipairs(toUnload) do
					local squadName = PlayerLogistics.getInfantryName(sq.type)
					local lastLoad = sq.loadedAt
					if lastLoad and zn and zn.side == un:getCoalition() and zn.name==lastLoad.name then
						if self.registeredSquadGroups[sq.type] then
							local cost = self.registeredSquadGroups[sq.type].cost
							zn:addResource(cost)
							zn:refreshText()

							self.humanResource.current = self.humanResource.current + sq.size
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

								self.humanResource.current = self.humanResource.current + sq.size
								
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
										local z = DependencyManager.get("SquadTracker"):getTargetZone(pos, sq.type, un:getCoalition())
										local name = ''
										if z then name = z.name end
										DependencyManager.get("MissionTracker"):tallyUnloadSquad(player, name, sq.type)
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
				local boxes = self.carriedBoxes[gr:getID()]

				if cargo and cargo>0 then
					self:unloadSupplies({group=groupname, amount=9999999})
				end

				if squad and #squad>0 then
					self:unloadInfantry({group=groupname})
				end

				if pilot and #pilot>0 then
					self:unloadPilots(groupname)
				end

				if boxes and #boxes>0 then
					self:unloadCrates(groupname, true)
				else
					self:unpackSupplies({group = groupname}, true, true)
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
					
					local logisticsStats = PlayerLogistics.allowedTypes[un:getDesc().typeName]
					if logisticsStats then
						local max = logisticsStats.personCapacity
						if max then
							local occupied = self:getOccupiedPersonCapacity(groupName)

							msg = msg..'\n\nPersonell Capacity: '..occupied..'/'..max
							
							msg = msg..'\n('..self:getCarriedPersonWeight(groupName)..' kg)'
						end

						if logisticsStats.boxCapacity then
							local boxes = self.carriedBoxes[gr:getID()] or {}
							msg = msg..'\n\nCrate Capacity: '..#boxes..'/'..logisticsStats.boxCapacity
							if boxes and #boxes>0 then
								msg = msg.."\n\nCrates:\n"
								for i,v in ipairs(boxes) do
									msg = msg..'\n '..v.name..'('..v.amount..' kg)'
								end
							end
							msg = msg..'\n('..self:getCarriedBoxWeight(groupName)..' kg)'
						end
					end

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

					msg = msg..'\n\nPersonnel ready for deployment: '..self.humanResource.current

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
			elseif tp == "CH-47Fbl1" then
				if unit:getDrawArgumentValue(86) > 0.85 then return true end
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
			elseif tp == "OH-6A" then
                if unit:getDrawArgumentValue(35) >= 0.3 then return true end
                if unit:getDrawArgumentValue(105) >= 0.3 then return true end
                if unit:getDrawArgumentValue(106) >= 0.3 then return true end
                if unit:getDrawArgumentValue(107) >= 0.3 then return true end
                if unit:getDrawArgumentValue(108) >= 0.3 then return true end
                if unit:getDrawArgumentValue(109) >= 0.3 then return true end
                if unit:getDrawArgumentValue(110) >= 0.3 then return true end
			else
				return true
			end
		end
	end

	function PlayerLogistics:unpackSupplies(params, supressNoBoxesMsg, all)
		local groupName = params.group

		local gr = Group.getByName(groupName)
		local un = gr:getUnit(1)
		if un then
			local boxes = {}

			for cname, cdata in pairs(self.trackedBoxes) do
				local cobj = StaticObject.getByName(cname) or Unit.getByName(cname)
				if cobj and cobj:isExist() and Utils.isLanded(cobj) then
					local dist = mist.utils.get3DDist(un:getPoint(), cobj:getPoint())
					if dist < 50  then 
						table.insert(boxes, {data = cdata, obj = cobj, dist = dist})
					end
				end
			end

			table.sort(boxes, function(a,b) return a.dist < b.dist end)

			if not supressNoBoxesMsg and #boxes == 0 then
				trigger.action.outTextForUnit(un:getID(), 'No packed supplies found nearby', 10)
				return
			end

			for _,v in ipairs(boxes) do
				
				local lastLoad = v.data.origin
				if v.data.content then
					local zn = ZoneCommand.getZoneOfPoint(v.obj:getPoint())
					if not zn and v.data.content == PlayerLogistics.buildables.farp then
						zn = FARPCommand.getFARPOfPoint(v.obj:getPoint())
					end

					if zn then
						zn:addResource(v.data.amount)
						zn:refreshText()
					
						trigger.action.outTextForUnit(un:getID(), v.data.amount..' supplies unpacked from '..v.data.name, 10)
					else
						trigger.action.outTextForUnit(un:getID(), 'Unpacked '..v.data.name, 10)

						local name = self:generateBuildingName(v.data.content)

						local p = {
							x = v.obj:getPoint().x,
							y = v.obj:getPoint().z
						}

						Spawner.createObject(name, v.data.content, p, v.obj:getCoalition(), 0, 0, {
							[land.SurfaceType.LAND] = true, 
							[land.SurfaceType.ROAD] = true,
							[land.SurfaceType.RUNWAY] = true
						})

						self.trackedBuildings[name] = { name=name, type=v.data.content }

						if v.data.content == PlayerLogistics.buildables.farp then
							timer.scheduleFunction(function(param, time)
								local f = FARPCommand:new(param.name, 500)
								param.context.trackedBuildings[param.name].farp = f
							end, {name = name, context = self}, timer.getTime()+2)
						else
							timer.scheduleFunction(function(param, time)
								local f = FARPCommand.getFARPOfPoint(param.pos)
								if f then f:refreshFeatures() end
							end, {pos = v.obj:getPoint()}, timer.getTime()+2)
						end
					end
				else
					if v.data.convert then
						local farp = FARPCommand.getFARPOfPoint(v.obj:getPoint())
						if not farp then
							trigger.action.outTextForUnit(un:getID(), 'Can only unpack fuel and ammo crates near a FARP', 10)
							return
						end

						self:unloadToFarp(un, farp, v.data.amount, v.data.convert)
					else
						local zn = ZoneCommand.getZoneOfPoint(v.obj:getPoint())
						if not zn then zn = FARPCommand.getFARPOfPoint(v.obj:getPoint()) end

						if not zn or zn.side ~= un:getCoalition() then
							trigger.action.outTextForUnit(un:getID(), v.data.name..' can only be unpacked within a friendly zone.', 10)
							return
						end

						self:awardSupplyXP(lastLoad, zn, un, v.data.amount)
						zn:addResource(v.data.amount)
						zn:refreshText()
						
						trigger.action.outTextForUnit(un:getID(), v.data.amount..' supplies unpacked from '..v.data.name, 10)
						DependencyManager.get("MissionTracker"):tallyUnpackCrate(un:getPlayerName(), zn.name, v.data)
					end
				end

				v.obj:destroy()
				self.trackedBoxes[v.data.name] = nil

				if not all then	break end
			end
		end
	end
	
	function PlayerLogistics:packSupplies(params)
		local groupName = params.group
		local amount = params.amount
		local content = params.content
		local convert = params.convert
		local free = params.free

		local gr = Group.getByName(groupName)
		local un = gr:getUnit(1)
		if un then
			if Utils.isInAir(un) then
				if free then
					trigger.action.outTextForUnit(un:getID(), 'Can not unload crates while in air.', 10)
				else
					trigger.action.outTextForUnit(un:getID(), 'Can not request crates while in air.', 10)
				end
				return
			end
			
			local zn = ZoneCommand.getZoneOfUnit(un:getName())

			if not zn and not free then 
				zn = FARPCommand.getFARPOfUnit(un:getName())
				if zn and not zn:hasFeature(PlayerLogistics.buildables.forklift) then
					trigger.action.outTextForUnit(un:getID(), zn.name..' lacks a Forklift. Can not request crates.', 10)
					return
				end
			end

			if not zn and not free then
				trigger.action.outTextForUnit(un:getID(), 'Can only request crates whithin a friendly zone', 10)
				return
			end
			
			if zn.side ~= un:getCoalition() and not free  then
				trigger.action.outTextForUnit(un:getID(), 'Can only request crates whithin a friendly zone', 10)
				return
			end

			if zn:criticalOnSupplies() and not free  then
				trigger.action.outTextForUnit(un:getID(), 'Can not request crate, zone is low on resources', 10)
				return
			end

			if zn.resource < zn.spendTreshold + amount and not free  then
				trigger.action.outTextForUnit(un:getID(), 'Can not request crate if resources would fall to a critical level.', 10)
				return
			end

			local unitPos = un:getPosition()

			local ahead = 15
			local area = 5

			local vec = {
				x = unitPos.x.x * ahead,
				z = unitPos.x.z * ahead
			}

			local offset = un:getPoint()
			offset.x = offset.x + vec.x
			offset.y = offset.z + vec.z
			offset.z = nil

			offset.x = offset.x + math.random(-area,area)
			offset.y = offset.y + math.random(-area,area)

			local boxcontent = self:getBoxContent(content)

			if convert == 'ammo' then
				boxcontent = 'Munitions'
			elseif convert == 'fuel' then
				boxcontent = 'Fuel'	
			end

			local cname = self:generateCargoName(boxcontent)
			local boxtype = self:getBoxType(amount)
			Spawner.createCrate(cname, boxtype, offset, un:getCoalition(), 1, 15, amount)
			if not free then
				zn:removeResource(amount)
				zn:refreshText()
			end

			self.trackedBoxes[cname] = {name=cname, amount = amount, origin=zn, type=boxtype, lifetime = 5*60*60, content=content, convert=convert}
			trigger.action.outTextForUnit(un:getID(), amount..' supplies packed in '..cname..' ahead of you.', 10)
		end
	end

	function PlayerLogistics:getBoxContent(content)
		local boxcontent = 'Supply'
		if content == PlayerLogistics.buildables.farp then
			boxcontent = "Landing pad"
		elseif content == PlayerLogistics.buildables.ammo then
			boxcontent = "Ammo Cache"
		elseif content == PlayerLogistics.buildables.fuel then
			boxcontent = "Fuel Cache"
		elseif content == PlayerLogistics.buildables.medtent then
			boxcontent = "Field Hospital"
		elseif content == PlayerLogistics.buildables.tent then
			boxcontent = "Command Center"
		elseif content == PlayerLogistics.buildables.generator then
			boxcontent = "Generator"
		elseif content == PlayerLogistics.buildables.radar then
			boxcontent = "Radar"
		elseif content == PlayerLogistics.buildables.satuplink then
			boxcontent = "Sat Uplink"
		elseif content == PlayerLogistics.buildables.forklift then
			boxcontent = "Forklift"
		end

		return boxcontent
	end

	function PlayerLogistics:restoreBox(data)
		Spawner.createCrate(data.name, data.type, data.pos, data.side, 1, 15, data.amount)
		local org = ZoneCommand.getZoneByName(data.origin)
		if not org then 
			org = {
				name='locally sourced', 
				isCarrier=false, 
				zone={ 
					point = {
						x=data.pos.x, 
						z=data.pos.y, 
						y=land.getHeight({ x = data.pos.x, y = data.pos.y }) 
					}
				},
				distToFront = 0
			}
		end
		self.trackedBoxes[data.name] = {name=data.name, amount = data.amount, origin=org, type=data.type, lifetime = data.lifetime, content = data.content, convert=data.convert, isSalvage=data.isSalvage}
	end

	PlayerLogistics.cargotypes = {
		["cargonet"] = {min = 100, max = 10000},
		["barrels"] = {min = 100, max = 480},
		["ammo_box"] = {min = 1000, max = 2000}
	}

	function PlayerLogistics:getBoxType(amount)
		local viable = {}
		for i,v in pairs(PlayerLogistics.cargotypes) do
			if amount <= v.max and amount >= v.min then
				table.insert(viable, i)
			end
		end

		if #viable == 0 then return "cargonet" end

		return viable[math.random(1,#viable)]
	end

	PlayerLogistics.cargoNames = {}
	PlayerLogistics.cargoNames.adjectives = {"Stealthy", "Agile", "Robust", "Tactical", "Strategic", "Armored", "Clandestine", "Swift", "Fortified", "Covert"}
	PlayerLogistics.cargoNames.nouns = {"Supply", "Crate", "Package", "Container", "Shipment", "Depot", "Cache", "Stockpile", "Arsenal", "Cargo"}

	function PlayerLogistics:generateCargoName(content)
        local adjective = self.cargoNames.adjectives[math.random(1,#self.cargoNames.adjectives)]
        local noun = self.cargoNames.nouns[math.random(1,#self.cargoNames.nouns)]

        local cname = adjective..noun..'('..content..')'

        if self.trackedBoxes[cname] then
            for i=1,1000,1 do
                local try = cname..'-'..i
                if not self.trackedBoxes[try] then
                    cname = try
                    break
                end
            end
        end

        if not self.trackedBoxes[cname] then
            return cname
        end
    end

	PlayerLogistics.farpNames = {"Able", "Baker", "Dog", "Easy", "Fox", "George", "How", "Item", "Jig", "King", "Love", "Nan", "Oboe", "Peter", "Queen", "Roger", "Sugar", "Tare", "Uncle", "William", "Yoke", "Zebra"}
	function PlayerLogistics:generateBuildingName(type)

		if type == PlayerLogistics.buildables.farp then
			type = 'FARP'
		end

        local name = self.farpNames[math.random(1,#self.farpNames)]..'('..type..')'

		if self.trackedBuildings[name] then
			for i=1,1000,1 do
				local try = name..'-'..i
				if not self.trackedBuildings[name] then
					name = try
					break
				end
			end
		end

		if not self.trackedBuildings[name] then
			return name
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

				if not self:canFitBoxes(groupName) then
					trigger.action.outTextForUnit(un:getID(), 'Can not load cargo. Boxes onboard.', 10)
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
					zn = FARPCommand.getFARPOfUnit(un:getName())
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

	function PlayerLogistics:unloadToFarp(playerunit, farp, amount, convert)
		if convert == 'ammo' then
			local divider = 50
			if farp:hasFeature(PlayerLogistics.buildables.ammo) then divider = 25 end

			amount = math.floor(amount/divider)
			WarehouseManager.addAllWeapons(farp.name, amount)
			trigger.action.outTextForUnit(playerunit:getID(), 'FARP supplied with '..amount..' munitions', 10)
		elseif convert == 'fuel' then
			local divider = 1
			if farp:hasFeature(PlayerLogistics.buildables.fuel) then divider = 0.5 end
			amount = math.floor(amount/divider)

			WarehouseManager.addAllFuel(farp.name, amount)
			trigger.action.outTextForUnit(playerunit:getID(), 'FARP supplied with '..amount..'L fuel', 10)
		end
	end

	function PlayerLogistics:unloadSupplies(params)
		if not ZoneCommand then return end
		
		local groupName = params.group
		local amount = params.amount
		local convert = params.convert
		
		local gr = Group.getByName(groupName)
		if gr then
			local un = gr:getUnit(1)
			if un then
				if Utils.isInAir(un) then
					trigger.action.outTextForUnit(un:getID(), 'Can not unload supplies while in air', 10)
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

				local zn = nil
				local farp = nil
				if convert then
					farp = FARPCommand.getFARPOfUnit(un:getName())
					if not farp then
						trigger.action.outTextForUnit(un:getID(), 'Can only unload fuel and ammo while while landed at a FARP', 10)
						return
					end
				else
					zn = ZoneCommand.getZoneOfUnit(un:getName())
					if not zn then 
						zn = CarrierCommand.getCarrierOfUnit(un:getName())
					end

					if not zn then 
						zn = FARPCommand.getFARPOfUnit(un:getName())
					end
					
					if not zn then
						trigger.action.outTextForUnit(un:getID(), 'Can only unload supplies while within a friendly zone', 10)
						return
					end
					
					if zn.side ~= 0 and zn.side ~= un:getCoalition()then
						trigger.action.outTextForUnit(un:getID(), 'Can only unload supplies while within a friendly zone', 10)
						return
					end
				end

				local carried = self.carriedCargo[gr:getID()]
				if amount > carried then
					amount = carried
				end
				
				self.carriedCargo[gr:getID()] = carried-amount

				if convert then
					self:unloadToFarp(un, farp, amount, convert)
				else
					zn:addResource(amount)
					zn:refreshText()

					local lastLoad = self.lastLoaded[gr:getID()]
					self:awardSupplyXP(lastLoad, zn, un, amount)
				end
				
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

	PlayerLogistics.slingPos = {}
	PlayerLogistics.slingPos['Mi-24P'] = { fwd = -1.0 }
	--PlayerLogistics.slingPos['Mi-8MT'] = { }
	--PlayerLogistics.slingPos['UH-1H'] = { }
	PlayerLogistics.slingPos['UH-60L'] = { fwd = -2}
	PlayerLogistics.slingPos['OH-6A'] = { fwd = -2 }
	--PlayerLogistics.slingPos['CH-47ph'] = { }
end

