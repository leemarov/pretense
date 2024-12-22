
MenuRegistry = {}

do
    MenuRegistry.triggers = {}
    MenuRegistry.unitTriggers = {}

    MenuRegistry.menus = {}
    function MenuRegistry.register(order, registerfunction, context)
        for i=1,order,1 do
            if not MenuRegistry.menus[i] then MenuRegistry.menus[i] = {func = function() end, context = {}} end
        end

        MenuRegistry.menus[order] = {func = registerfunction, context = context}
    end

    local ev = {}
    function ev:onEvent(event)
        MenuRegistry.handleEvent(event)
    end
    
    world.addEventHandler(ev)

    function MenuRegistry.handleEvent(event)
        if event.initiator and event.initiator.isExist and event.initiator:isExist() and event.initiator.getPlayerName and event.initiator:getPlayerName() then
            env.info('MenuRegistry - playerevent type='..event.id)
        end

        if (event.id == world.event.S_EVENT_PLAYER_ENTER_UNIT or
            event.id == world.event.S_EVENT_BIRTH) and event.initiator and event.initiator.isExist and event.initiator:isExist() and event.initiator.getPlayerName then

            local player = event.initiator:getPlayerName()
            if player then
                local lastTrigger = MenuRegistry.triggers[player]
                env.info('MenuRegistry - last trigger time '..tostring(lastTrigger)..' type='..event.id)
                if not lastTrigger or (timer.getTime() - lastTrigger) > 1 then
                    MenuRegistry.triggers[player] = timer.getTime()
                    env.info('MenuRegistry - creating menus for player: '..player)
                    for i,v in ipairs(MenuRegistry.menus) do
                        local err, msg = pcall(v.func, event, v.context)
                        if not err then
                            env.info("MenuRegistry - ERROR :\n"..msg)
                            env.info('Traceback\n'..debug.traceback())
                        end
                    end
                end
            end
        end
    end

    function MenuRegistry.triggerMenusForUnit(unit)
        if unit:isExist() then
            if unit.getPlayerName and unit:getPlayerName() then
                local tr = MenuRegistry.unitTriggers[unit:getID()]
                if not tr then
                    local event = {
                        initiator = unit,
                        id = world.event.S_EVENT_PLAYER_ENTER_UNIT,
                    }
    
                    MenuRegistry.handleEvent(event)
                    MenuRegistry.unitTriggers[unit:getID()] = true
                end
            else
                local tr = MenuRegistry.unitTriggers[unit:getID()]
                if tr then
                    MenuRegistry.unitTriggers[unit:getID()] = false
                end
            end
        end
    end

    function MenuRegistry.showTargetZoneMenu(groupid, name, action, targetside, minDistToFront, data, includeCarriers, onlyRevealed,includeFarps)
		local zones = ZoneCommand.getAllZones()

        if targetside and type(targetside) == 'number' then
            targetside = { targetside }
        end

        local zns = {}
        for i,v in pairs(zones) do
            if not targetside or Utils.isInArray(v.side,targetside) then 
                if not minDistToFront or v.distToFront <= minDistToFront then
                    if not onlyRevealed or v.revealTime>0 then
                        table.insert(zns, v)
                    end
                end
            end
        end

        if includeCarriers then
            for i,v in pairs(CarrierCommand.getAllCarriers()) do
                if not targetside or Utils.isInArray(v.side,targetside) then 
                    table.insert(zns, v)
                end
            end
        end

        if includeFarps then
            for i,v in pairs(FARPCommand.getAllFARPs()) do
                if not targetside or Utils.isInArray(v.side,targetside) then 
                    table.insert(zns, v)
                end
            end
        end

        if #zns == 0 then return false end

        table.sort(zns, function(a,b) return a.name < b.name end)

        local executeAction = function(act, params)
			local err = act(params)
			if not err then
				missionCommands.removeItemForGroup(params.groupid, params.menu)
			end
		end

		local menu = missionCommands.addSubMenuForGroup(groupid, name)
		local sub1 = nil

		local count = 0
		for i,v in ipairs(zns) do
            count = count + 1
            if count<10 then
                missionCommands.addCommandForGroup(groupid, v.name, menu, executeAction, action, {zone = v, menu=menu, groupid=groupid, data=data})
            elseif count==10 then
                sub1 = missionCommands.addSubMenuForGroup(groupid, "More", menu)
                missionCommands.addCommandForGroup(groupid, v.name, sub1, executeAction, action, {zone = v, menu=menu, groupid=groupid, data=data})
            elseif count%9==1 then
                sub1 = missionCommands.addSubMenuForGroup(groupid, "More", sub1)
                missionCommands.addCommandForGroup(groupid, v.name, sub1, executeAction, action, {zone = v, menu=menu, groupid=groupid, data=data})
            else
                missionCommands.addCommandForGroup(groupid, v.name, sub1, executeAction, action, {zone = v, menu=menu, groupid=groupid, data=data})
            end
		end
		
		return menu
    end
end

