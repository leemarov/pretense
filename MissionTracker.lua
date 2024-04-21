
MissionTracker = {}
do
    MissionTracker.maxMissionCount = {
        [Mission.types.cap_easy] = 2,
        [Mission.types.cap_medium] = 1,
        [Mission.types.cas_easy] = 2,
        [Mission.types.cas_medium] = 1,
        [Mission.types.cas_hard] = 1,
        [Mission.types.sead] = 3,
        [Mission.types.supply_easy] = 3,
        [Mission.types.supply_hard] = 1,
        [Mission.types.strike_veryeasy] = 2,
        [Mission.types.strike_easy] = 1,
        [Mission.types.strike_medium] = 3,
        [Mission.types.strike_hard] = 1,
        [Mission.types.dead] = 1,
        [Mission.types.escort] = 2,
        [Mission.types.tarcap] = 1,
        [Mission.types.deep_strike] = 3,
        [Mission.types.recon] = 3,
        [Mission.types.bai] = 1,
        [Mission.types.anti_runway] = 2,
        [Mission.types.csar] = 1,
        [Mission.types.extraction] = 1,
        [Mission.types.deploy_squad] = 3,
    }

    if Config.missions then
        for i,v in pairs(Config.missions) do
            if MissionTracker.maxMissionCount[i] then
                MissionTracker.maxMissionCount[i] = v
            end
        end
    end

    MissionTracker.missionBoardSize = Config.missionBoardSize or 15

	function MissionTracker:new()
		local obj = {}
        obj.groupMenus = {}
        obj.missionIDPool = {}
        obj.missionBoard = {}
        obj.activeMissions = {}
		
		setmetatable(obj, self)
		self.__index = self

        DependencyManager.get("MarkerCommands"):addCommand('list', function(event, _, state) 
            if event.initiator then
                state:printMissionBoard(event.initiator:getID(), nil, event.initiator:getGroup():getName())
            elseif world.getPlayer() then
                local unit = world.getPlayer()
                state:printMissionBoard(unit:getID(), nil, event.initiator:getGroup():getName())
            end
            return true
        end, nil, obj)

        DependencyManager.get("MarkerCommands"):addCommand('help', function(event, _, state) 
            if event.initiator then
                state:printHelp(event.initiator:getID())
            elseif world.getPlayer() then
                local unit = world.getPlayer()
                state:printHelp(unit:getID())
            end
            return true
        end, nil, obj)

        DependencyManager.get("MarkerCommands"):addCommand('active', function(event, _, state) 
            if event.initiator then
                state:printActiveMission(event.initiator:getID(), nil, event.initiator:getPlayerName())
            elseif world.getPlayer() then
                state:printActiveMission(nil, nil, world.getPlayer():getPlayerName())
            end
            return true
        end, nil, obj)

        DependencyManager.get("MarkerCommands"):addCommand('accept',function(event, code, state) 
            local numcode = tonumber(code)
            if not numcode or numcode<1000 or numcode > 9999 then return false end

            local player = ''
            local unit = nil
            if event.initiator then 
                player = event.initiator:getPlayerName()
                unit = event.initiator
            elseif world.getPlayer() then
                player = world.getPlayer():getPlayerName()
                unit = world.getPlayer()
            end

            return state:activateMission(numcode, player, unit)
        end, true, obj)

        DependencyManager.get("MarkerCommands"):addCommand('join',function(event, code, state) 
            local numcode = tonumber(code)
            if not numcode or numcode<1000 or numcode > 9999 then return false end

            local player = ''
            local unit = nil
            if event.initiator then 
                player = event.initiator:getPlayerName()
                unit = event.initiator
            elseif world.getPlayer() then
                player = world.getPlayer():getPlayerName()
                unit = world.getPlayer()
            end

            return state:joinMission(numcode, player, unit)
        end, true, obj)

        DependencyManager.get("MarkerCommands"):addCommand('leave',function(event, _, state) 
            local player = ''
            if event.initiator then 
                player = event.initiator:getPlayerName()
            elseif world.getPlayer() then
                player = world.getPlayer():getPlayerName()
            end

            return state:leaveMission(player)
        end, nil, obj)

        obj:menuSetup()
		obj:start()
        
		DependencyManager.register("MissionTracker", obj)
		return obj
	end

    function MissionTracker:menuSetup()
        MenuRegistry:register(2, function(event, context)
            if event.id == world.event.S_EVENT_BIRTH and event.initiator and event.initiator.getPlayerName then
				local player = event.initiator:getPlayerName()
				if player then
					local groupid = event.initiator:getGroup():getID()
                    local groupname = event.initiator:getGroup():getName()

                    if context.groupMenus[groupid] then
                        missionCommands.removeItemForGroup(groupid, context.groupMenus[groupid])
                        context.groupMenus[groupid] = nil
                    end

                    if not context.groupMenus[groupid] then
                        local menu = missionCommands.addSubMenuForGroup(groupid, 'Missions')
                        missionCommands.addCommandForGroup(groupid, 'List Missions', menu, Utils.log(context.printMissionBoard), context, nil, groupid, groupname)
                        missionCommands.addCommandForGroup(groupid, 'Active Mission', menu, Utils.log(context.printActiveMission), context, nil, groupid, nil, groupname)
                        
                        local dial = missionCommands.addSubMenuForGroup(groupid, 'Dial Code', menu)
                        for i1=1,5,1 do
                            local digit1 = missionCommands.addSubMenuForGroup(groupid, i1..'___', dial)
                            for i2=1,5,1 do
                                local digit2 = missionCommands.addSubMenuForGroup(groupid, i1..i2..'__', digit1)
                                for i3=1,5,1 do
                                    local digit3 = missionCommands.addSubMenuForGroup(groupid, i1..i2..i3..'_', digit2)
                                    for i4=1,5,1 do
                                        local code = tonumber(i1..i2..i3..i4)
                                        local digit4 = missionCommands.addCommandForGroup(groupid, i1..i2..i3..i4, digit3, Utils.log(context.activateOrJoinMissionForGroup), context, code, groupname)
                                    end
                                end
                            end
                        end
                        
                        local leavemenu = missionCommands.addSubMenuForGroup(groupid, 'Leave Mission', menu)
                        missionCommands.addCommandForGroup(groupid, 'Confirm to leave mission', leavemenu, Utils.log(context.leaveMission), context, player)
                        missionCommands.addCommandForGroup(groupid, 'Cancel', leavemenu, function() end)

                        missionCommands.addCommandForGroup(groupid, 'Help', menu, Utils.log(context.printHelp), context, nil, groupid)
                        
                        context.groupMenus[groupid] = menu
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
    end

    function MissionTracker:printHelp(unitid, groupid)
        local msg = 'Missions can only be accepted or joined while landed at a friendly zone.\n'
        msg = msg.. 'Rewards from mission completion need to be claimed by landing at a friendly zone.\n\n'
        msg = msg.. 'Accept mission:\n'
        msg = msg.. ' Each mission has a 4 digit code listed next to its name.\n To accept a mission, either dial its code from the mission radio menu,\n or create a marker on the map and set its text to:\n'
        msg = msg.. '   accept:code\n'
        msg = msg.. ' (ex. accept:4126)\n\n'
        msg = msg.. 'Join mission:\n'
        msg = msg.. ' You can team up with other players, by joining a mission they already accepted.\n'
        msg = msg.. ' Missions can only be joined if all players who are already part of that mission\n have not taken off yet.\n'
        msg = msg.. ' When a mission is completed each player has to land to claim their reward individually.\n'
        msg = msg.. ' To join a mission, ask for the join code from a player who is already part of the mission,\n dial it in from the mission radio menu,\n or create a marker on the map and set its text to:\n'
        msg = msg.. '   join:code\n'
        msg = msg.. ' (ex. join:4126)\n\n'
        msg = msg.. 'Map marker commands:\n'
        msg = msg.. ' list - displays mission board\n'
        msg = msg.. ' accept:code - accepts mission with corresponding code\n'
        msg = msg.. ' join:code - joins other players mission with corresponding code\n'
        msg = msg.. ' active - displays active mission\n'
        msg = msg.. ' leave - leaves active mission\n'
        msg = msg.. ' help - displays this message'

        if unitid then
            trigger.action.outTextForUnit(unitid, msg, 30)
        elseif groupid then
            trigger.action.outTextForGroup(groupid, msg, 30)
        else
            --trigger.action.outText(msg, 30)
        end
    end

    function MissionTracker:printActiveMission(unitid, groupid, playername, groupname)
        if not playername and groupname then
            env.info('MissionTracker - printActiveMission: '..tostring(groupname)..' requested group print.')
            local gr = Group.getByName(groupname)
            for i,v in ipairs(gr:getUnits()) do
                if v.getPlayerName and v:getPlayerName() then 
                    self:printActiveMission(v:getID(), gr:getID(), v:getPlayerName())
                end
            end
            return
        end

        local mis = nil
        for i,v in pairs(self.activeMissions) do
            for pl,un in pairs(v.players) do
                if pl == playername then
                    mis = v
                    break
                end
            end

            if mis then break end
        end

        local msg = ''
        if mis then
            msg = mis:getDetailedDescription()
        else
            msg = 'No active mission'
        end

        if unitid then
            trigger.action.outTextForUnit(unitid, msg, 30)
        elseif groupid then
            trigger.action.outTextForGroup(groupid, msg, 30)
        else
            --trigger.action.outText(msg, 30)
        end
    end

    function MissionTracker:printMissionBoard(unitid, groupid, groupname)
        local gr = Group.getByName(groupname)
        local un = gr:getUnit(1)

        local msg = 'Mission Board\n'
        local empty = true
        local invalidCount = 0
        for i,v in pairs(self.missionBoard) do
            if v:isUnitTypeAllowed(un) then
                empty = false
                msg = msg..'\n'..v:getBriefDescription()..'\n'
            else
                invalidCount = invalidCount + 1
            end
        end

        if empty then 
            msg = msg..'\n No missions available'
        end

        if invalidCount > 0 then
            msg = msg..'\n'..invalidCount..' additional missions are not compatible with current aircraft\n'
        end

        if unitid then
            trigger.action.outTextForUnit(unitid, msg, 30)
        elseif groupid then
            trigger.action.outTextForGroup(groupid, msg, 30)
        else
            --trigger.action.outText(msg, 30)
        end
    end

    function MissionTracker:getNewMissionID()
        if #self.missionIDPool == 0 then
            for i=1111,5555,1 do 
                if not tostring(i):find('[06789]') then
                    if not self.missionBoard[i] and not self.activeMissions[i] then
                        table.insert(self.missionIDPool, i)
                    end
                end
            end
        end
        
        local choice = math.random(1,#self.missionIDPool)
        local newId = self.missionIDPool[choice]
        table.remove(self.missionIDPool,choice)
        return newId
    end
	
	function MissionTracker:start()
        timer.scheduleFunction(function(params, time)
            for i,v in ipairs(coalition.getPlayers(2)) do
                if v and v:isExist() and not Utils.isInAir(v) and v.getPlayerName and v:getPlayerName() then
                    local player = v:getPlayerName()
                    local cfg = DependencyManager.get("PlayerTracker"):getPlayerConfig(player)
                    if cfg.noMissionWarning == true then
                        local hasMis = false
                        for _,mis in pairs(params.context.activeMissions) do
                            if mis.players[player] then
                                hasMis = true
                                break
                            end
                        end

                        if not hasMis then
                            trigger.action.outTextForUnit(v:getID(), "No mission selected", 9)
                        end
                    end
                end
            end

            return time+10
        end, {context = self}, timer.getTime()+10)

        timer.scheduleFunction(function(param, time)
            for code,mis in pairs(param.missionBoard) do
                if timer.getAbsTime() - mis.lastStateTime > mis.expireTime then
                    param.missionBoard[code].state = Mission.states.failed
                    param.missionBoard[code] = nil
                    env.info('Mission code'..code..' expired.')
                else
                    mis:updateIsFailed()
                    if mis.state == Mission.states.failed then
                        param.missionBoard[code]=nil
                        env.info('Mission code'..code..' canceled due to objectives failed')
                        trigger.action.outTextForCoalition(2,'Mission ['..mis.missionID..'] '..mis.name..' was cancelled',5)
                    end
                end
            end

            local misCount = Utils.getTableSize(param.missionBoard)
            local toGen = MissionTracker.missionBoardSize-misCount
            if toGen > 0 then
                local validMissions = {}
                for _,v in pairs(Mission.types) do
                    if self:canCreateMission(v) then
                        table.insert(validMissions,v)
                    end
                end

                if #validMissions > 0  then
                    for i=1,toGen,1 do
                        if #validMissions > 0 then
                            local choice = math.random(1,#validMissions)
                            local misType = validMissions[choice]
                            table.remove(validMissions, choice)
                            param:generateMission(misType)
                        else
                            break
                        end
                    end
                end
            end

            return time+1
        end, self, timer.getTime()+1)

        timer.scheduleFunction(function(param, time)
            for code,mis in pairs(param.activeMissions) do
                -- check if players exist and in same unit as when joined
                -- remove from mission if false
                for pl,un in pairs(mis.players) do
                    if not un or
                        not un:isExist() then

                        mis:removePlayer(pl)
                        env.info('Mission code'..code..' removing player '..pl..', unit no longer exists')
                    end
                end
                
                -- check if mission has 0 players, delete mission if true
                if not mis:hasPlayers() then
                    param.activeMissions[code]:updateState(Mission.states.failed)
                    param.activeMissions[code] = nil
                    env.info('Mission code'..code..' canceled due to no players')
                else
                    --check if mission objectives can still be completed, cancel mission if not
                    mis:updateIsFailed()
                    mis:updateIsCompleted()

                    if mis.state == Mission.states.preping then
                        --check if any player in air and move to comencing if true
                        for pl,un in pairs(mis.players) do
                            if Utils.isInAir(un) then
                                mis:updateState(Mission.states.comencing)
                                mis:pushMessageToPlayers(mis.name..' mission is starting')
                                break
                            end
                        end
                    elseif mis.state == Mission.states.comencing then
                        --check if all players in air and move to active if true
                        --if all players landed, move to preping
                        local allInAir = true
                        local allLanded = true
                        for pl,un in pairs(mis.players) do
                            if Utils.isInAir(un) then
                                allLanded = false
                            else
                                allInAir = false
                            end
                        end

                        if allLanded then
                            mis:updateState(Mission.states.preping)
                            mis:pushMessageToPlayers(mis.name..' mission is in the prep phase')
                        end

                        if allInAir then
                            mis:updateState(Mission.states.active)
                            mis:pushMessageToPlayers(mis.name..' mission has started')
                            local missionstatus = mis:getDetailedDescription()
                            mis:pushMessageToPlayers(missionstatus)
                        end
                    elseif mis.state == Mission.states.active then
                        mis:updateObjectives()
                    elseif mis.state == Mission.states.completed then
                        local isInstant = mis:isInstantReward()
                        if isInstant then
                            mis:pushMessageToPlayers(mis.name..' mission complete.', 60)
                        else
                            mis:pushMessageToPlayers(mis.name..' mission complete. Land to claim rewards.', 60)
                        end 

                        for _,reward in ipairs(mis.rewards) do
                            for p,_ in pairs(mis.players) do
                                local finalAmount = reward.amount
                                if reward.type == PlayerTracker.statTypes.xp then
                                    finalAmount = math.floor(finalAmount * DependencyManager.get("PlayerTracker"):getPlayerMultiplier(p))
                                end

                                if isInstant then
                                    DependencyManager.get("PlayerTracker"):addStat(p, finalAmount, reward.type)
                                    mis:pushMessageToPlayer(p, '+'..reward.amount..' '..reward.type)
                                else
                                    DependencyManager.get("PlayerTracker"):addTempStat(p, finalAmount, reward.type)
                                end
                            end
                        end

                        for p,u in pairs(mis.players) do
                            DependencyManager.get("PlayerTracker"):addRankRewards(p,u, not isInstant)
                        end

                        mis:pushSoundToPlayers("success.ogg")
                        param.activeMissions[code] = nil
                        env.info('Mission code'..code..' removed due to completion')
                    elseif mis.state == Mission.states.failed then
                        local msg = mis.name..' mission failed.'
                        if mis.failureReason then
                            msg = msg..'\n'..mis.failureReason
                        end

                        mis:pushMessageToPlayers(msg, 60)

                        mis:pushSoundToPlayers("fail.ogg")
                        param.activeMissions[code] = nil
                        env.info('Mission code'..code..' removed due to failure')
                    end
                end
            end

            return time+1
        end, self, timer.getTime()+1)

        local ev = {}
		ev.context = self
		function ev:onEvent(event)
			if event.id == world.event.S_EVENT_KILL and event.initiator and event.target and event.initiator.getPlayerName then
				local player = event.initiator:getPlayerName()
				if player and 
                    event.initiator:isExist() and
                    event.initiator.getCoalition and 
                    event.target.getCoalition and 
                    event.initiator:getCoalition() ~= event.target:getCoalition() then
					    self.context:tallyKill(player, event.target)
				end
			end

            if event.id == world.event.S_EVENT_SHOT and event.initiator and event.weapon and event.initiator.getPlayerName then
                local player = event.initiator:getPlayerName()
				if player and event.initiator:isExist() and event.weapon:isExist() then
                    self.context:tallyWeapon(player, event.weapon)
                end
            end
		end
		
		world.addEventHandler(ev)
	end

    function MissionTracker:generateMission(misType)
        local misid = self:getNewMissionID()
        env.info('MissionTracker - generating mission type ['..misType..'] id code['..misid..']')
        
        local newmis = nil
        if misType == Mission.types.cap_easy then
            newmis = CAP_Easy:new(misid, misType)
        elseif misType == Mission.types.cap_medium then
            newmis = CAP_Medium:new(misid, misType)
        elseif misType == Mission.types.cas_easy then
            newmis = CAS_Easy:new(misid, misType)
        elseif misType == Mission.types.cas_medium then
            newmis = CAS_Medium:new(misid, misType)
        elseif misType == Mission.types.cas_hard then
            newmis = CAS_Hard:new(misid, misType)
        elseif misType == Mission.types.sead then
            newmis = SEAD:new(misid, misType)
        elseif misType == Mission.types.supply_easy then
            newmis = Supply_Easy:new(misid, misType)
        elseif misType == Mission.types.supply_hard then
            newmis = Supply_Hard:new(misid, misType)
        elseif misType == Mission.types.strike_veryeasy then
            newmis = Strike_VeryEasy:new(misid, misType)
        elseif misType == Mission.types.strike_easy then
            newmis = Strike_Easy:new(misid, misType)
        elseif misType == Mission.types.strike_medium then
            newmis = Strike_Medium:new(misid, misType)
        elseif misType == Mission.types.strike_hard then
            newmis = Strike_Hard:new(misid, misType)
        elseif misType == Mission.types.deep_strike then
            newmis = Deep_Strike:new(misid, misType)
        elseif misType == Mission.types.dead then
            newmis = DEAD:new(misid, misType)
        elseif misType == Mission.types.escort then
            newmis = Escort:new(misid, misType)
        elseif misType == Mission.types.tarcap then
            newmis = TARCAP:new(misid, misType, self.activeMissions)
        elseif misType == Mission.types.recon then
            newmis = Recon:new(misid, misType)
        elseif misType == Mission.types.bai then
            newmis = BAI:new(misid, misType)
        elseif misType == Mission.types.anti_runway then
            newmis = Anti_Runway:new(misid, misType)
        elseif misType == Mission.types.csar then
            newmis = CSAR:new(misid, misType)
        elseif misType == Mission.types.extraction then
            newmis = Extraction:new(misid, misType)
        elseif misType == Mission.types.deploy_squad then
            newmis = DeploySquad:new(misid, misType)
        end

        if not newmis then return end

        if #newmis.objectives == 0 then return end

        self.missionBoard[misid] = newmis
        env.info('MissionTracker - generated mission id code'..misid..' \n'..newmis.description)
        trigger.action.outTextForCoalition(2,'New mission available: '..newmis.name,5)
    end

    function MissionTracker:tallyWeapon(player, weapon)
        for _,m in pairs(self.activeMissions) do
            if m.players[player] then
                if m.state == Mission.states.active then
                    if Weapon.getCategoryEx(weapon) == Weapon.Category.BOMB then
                        timer.scheduleFunction(function (params, time)
                            if not params.weapon:isExist() then
                                return nil -- weapon despawned
                            end

                            local alt = Utils.getAGL(params.weapon)
                            if alt < 5 then 
                                params.mission:tallyWeapon(params.weapon)
                                return nil
                            end

                            if alt < 20 then
                                return time+0.01
                            end

                            return time+0.1
                        end, {player = player, weapon = weapon, mission = m}, timer.getTime()+0.1)
                    end
                end
            end
        end
    end

    function MissionTracker:tallyKill(player,kill)
        env.info("MissionTracker - tallyKill: "..player.." killed "..kill:getName())
        for _,m in pairs(self.activeMissions) do
            if m.players[player] then
                if m.state == Mission.states.active then
                    m:tallyKill(kill)
                end
            end
        end
    end

    function MissionTracker:tallySupplies(player, amount, zonename)
        env.info("MissionTracker - tallySupplies: "..player.." delivered "..amount.." of supplies to "..zonename)
        for _,m in pairs(self.activeMissions) do
            if m.players[player] then
                if m.state == Mission.states.active then
                    m:tallySupplies(amount, zonename)
                end
            end
        end
    end

    function MissionTracker:tallyLoadPilot(player, pilot)
        env.info("MissionTracker - tallyLoadPilot: "..player.." loaded pilot "..pilot.name)
        for _,m in pairs(self.activeMissions) do
            if m.players[player] then
                if m.state == Mission.states.active then
                    m:tallyLoadPilot(player, pilot)
                end
            end
        end
    end

    function MissionTracker:tallyUnloadPilot(player, zonename)
        env.info("MissionTracker - tallyUnloadPilot: "..player.." unloaded pilots at "..zonename)
        for _,m in pairs(self.activeMissions) do
            if m.players[player] then
                if m.state == Mission.states.active then
                    m:tallyUnloadPilot(player, zonename)
                end
            end
        end
    end

    function MissionTracker:tallyLoadSquad(player, squad)
        env.info("MissionTracker - tallyLoadSquad: "..player.." loaded squad "..squad.name)
        for _,m in pairs(self.activeMissions) do
            if m.players[player] then
                if m.state == Mission.states.active then
                    m:tallyLoadSquad(player, squad)
                end
            end
        end
    end

    function MissionTracker:tallyUnloadSquad(player, zonename, squadType)
        env.info("MissionTracker - tallyUnloadSquad: "..player.." unloaded "..squadType.." squad at "..zonename)
        for _,m in pairs(self.activeMissions) do
            if m.players[player] then
                if m.state == Mission.states.active then
                    m:tallyUnloadSquad(player, zonename, squadType)
                end
            end
        end
    end

    function MissionTracker:tallyRecon(player, targetzone, analyzezonename)
        env.info("MissionTracker - tallyRecon: "..player.." analyzed "..targetzone.." recon data at "..analyzezonename)
        for _,m in pairs(self.activeMissions) do
            if m.players[player] then
                if m.state == Mission.states.active then
                    m:tallyRecon(player, targetzone, analyzezonename)
                end
            end
        end
    end

    function MissionTracker:activateOrJoinMissionForGroup(code, groupname)
        if groupname then
            env.info('MissionTracker - activateOrJoinMissionForGroup: '..tostring(groupname)..' requested activate or join '..code)
            local gr = Group.getByName(groupname)
            for i,v in ipairs(gr:getUnits()) do
                if v.getPlayerName and v:getPlayerName() then 
                    local mis = self.activeMissions[code]
                    if mis then 
                        self:joinMission(code, v:getPlayerName(), v)
                    else
                        self:activateMission(code, v:getPlayerName(), v)
                    end
                    return
                end
            end
        end
    end

    function MissionTracker:activateMission(code, player, unit)
        if Config.restrictMissionAcceptance then
            if not unit or not unit:isExist() or not Utils.isLanded(unit, true) then 
                if unit and unit:isExist() then trigger.action.outTextForUnit(unit:getID(), 'Can only accept mission while landed', 5) end
                return false 
            end

            local zn = ZoneCommand.getZoneOfUnit(unit:getName())
            if not zn then 
                zn = CarrierCommand.getCarrierOfUnit(unit:getName())
            end

            if not zn or zn.side ~= unit:getCoalition() then 
                trigger.action.outTextForUnit(unit:getID(), 'Can only accept mission while inside friendly zone', 5)
                return false 
            end
        end

        for c,m in pairs(self.activeMissions) do
            if m:getPlayerUnit(player) then 
                trigger.action.outTextForUnit(unit:getID(), 'A mission is already active.', 5)
                return false 
            end
        end

        local mis = self.missionBoard[code]
        if not mis then 
            trigger.action.outTextForUnit(unit:getID(), 'Invalid mission code', 5)
            return false 
        end

        if mis.state ~= Mission.states.new then
            trigger.action.outTextForUnit(unit:getID(), 'Invalid mission.', 5)
            return false 
        end

        if not mis:isUnitTypeAllowed(unit) then
            trigger.action.outTextForUnit(unit:getID(), 'Current aircraft type is not compatible with this mission.', 5)
            return false
        end

        self.missionBoard[code] = nil
        
        trigger.action.outTextForCoalition(2,'Mission ['..mis.missionID..'] '..mis.name..' was accepted by '..player,5)
        mis:updateState(Mission.states.preping)
        mis.missionID = self:getNewMissionID()
        mis:addPlayer(player, unit)

        mis:pushMessageToPlayers(mis.name..' accepted.\nJoin code: ['..mis.missionID..']')

        env.info('Mission code'..code..' changed to code'..mis.missionID)
        env.info('Mission code'..mis.missionID..' accepted by '..player)
        self.activeMissions[mis.missionID] = mis
        return true
    end

    function MissionTracker:joinMission(code, player, unit)
        if Config.restrictMissionAcceptance then
            if not unit or not unit:isExist() or not Utils.isLanded(unit, true) then 
                if unit and unit:isExist() then trigger.action.outTextForUnit(unit:getID(), 'Can only join mission while landed', 5) end
                return false
            end

            local zn = ZoneCommand.getZoneOfUnit(unit:getName())
            if not zn then 
                zn = CarrierCommand.getCarrierOfUnit(unit:getName())
            end

            if not zn or zn.side ~= unit:getCoalition() then 
                trigger.action.outTextForUnit(unit:getID(), 'Can only join mission while inside friendly zone', 5)
                return false
            end
        end
       
        for c,m in pairs(self.activeMissions) do
            if m:getPlayerUnit(player) then 
                trigger.action.outTextForUnit(unit:getID(), 'A mission is already active.', 5)
                return false 
            end
        end

        local mis = self.activeMissions[code]
        if not mis then 
            trigger.action.outTextForUnit(unit:getID(), 'Invalid mission code', 5)
            return false 
        end

        if mis.state ~= Mission.states.preping then
            trigger.action.outTextForUnit(unit:getID(), 'Mission can only be joined if its members have not taken off yet.', 5)
            return false 
        end

        if not mis:isUnitTypeAllowed(unit) then
            trigger.action.outTextForUnit(unit:getID(), 'Current aircraft type is not compatible with this mission.', 5)
            return false
        end
        
        mis:addPlayer(player, unit)
        mis:pushMessageToPlayers(player..' has joined mission '..mis.name)
        env.info('Mission code'..code..' joined by '..player)
        return true
    end

    function MissionTracker:leaveMission(player)
        for _,mis in pairs(self.activeMissions) do
            if mis:getPlayerUnit(player) then
                mis:pushMessageToPlayers(player..' has left mission '..mis.name)
                mis:removePlayer(player)
                env.info('Mission code'..mis.missionID..' left by '..player)
                if not mis:hasPlayers() then
                    self.activeMissions[mis.missionID]:updateState(Mission.states.failed)
                    self.activeMissions[mis.missionID] = nil
                    env.info('Mission code'..mis.missionID..' canceled due to all players leaving')
                end

                break
            end
        end
        
        return true
    end

    function MissionTracker:canCreateMission(misType)
        if not MissionTracker.maxMissionCount[misType] then return false end
        
        local missionCount = 0
        for i,v in pairs(self.missionBoard) do
            if v.type == misType then missionCount = missionCount + 1 end
        end

        for i,v in pairs(self.activeMissions) do
            if v.type == misType then missionCount = missionCount + 1 end
        end

        if missionCount >= MissionTracker.maxMissionCount[misType] then return false end

        if misType == Mission.types.cap_easy then
            return CAP_Easy.canCreate()
        elseif misType == Mission.types.cap_medium then
            return CAP_Medium.canCreate()
        elseif misType == Mission.types.cas_easy then
            return CAS_Easy.canCreate()
        elseif misType == Mission.types.cas_medium then
            return CAS_Medium.canCreate()
        elseif misType == Mission.types.sead then
            return SEAD.canCreate()
        elseif misType == Mission.types.dead then
            return DEAD.canCreate()
        elseif misType == Mission.types.cas_hard then
            return CAS_Hard.canCreate()
        elseif misType == Mission.types.supply_easy then
            return Supply_Easy.canCreate()
        elseif misType == Mission.types.supply_hard then
            return Supply_Hard.canCreate()
        elseif misType == Mission.types.strike_veryeasy then
            return Strike_VeryEasy.canCreate()
        elseif misType == Mission.types.strike_easy then
            return Strike_Easy.canCreate()
        elseif misType == Mission.types.strike_medium then
            return Strike_Medium.canCreate()
        elseif misType == Mission.types.strike_hard then
            return Strike_Hard.canCreate()
        elseif misType == Mission.types.deep_strike then
            return Deep_Strike.canCreate()
        elseif misType == Mission.types.escort then
            return Escort.canCreate()
        elseif misType == Mission.types.tarcap then
            return TARCAP.canCreate(self.activeMissions)
        elseif misType == Mission.types.recon then
            return Recon.canCreate()
        elseif misType == Mission.types.bai then
            return BAI.canCreate()
        elseif misType == Mission.types.anti_runway then
            return Anti_Runway.canCreate()
        elseif misType == Mission.types.csar then
            return CSAR.canCreate()
        elseif misType == Mission.types.extraction then
            return Extraction.canCreate()
        elseif misType == Mission.types.deploy_squad then
            return DeploySquad.canCreate()
        end

        return false
    end

end


