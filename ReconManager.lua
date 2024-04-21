
ReconManager = {}
do
    ReconManager.groupMenus = {}
    ReconManager.requiredProgress = 5*60
    ReconManager.updateFrequency = 5

    function ReconManager:new()
        local obj = {}
        obj.recondata = {}
        obj.cancelRequests = {}

        setmetatable(obj, self)
		self.__index = self
		DependencyManager.register("ReconManager", obj)
        obj:init()
        return obj
    end

    function ReconManager:init()
        MenuRegistry:register(7, function(event, context)
            if event.id == world.event.S_EVENT_BIRTH and event.initiator and event.initiator.getPlayerName then
                local player = event.initiator:getPlayerName()
                if player then
                    local groupid = event.initiator:getGroup():getID()
                    local groupname = event.initiator:getGroup():getName()
                    
                    if ReconManager.groupMenus[groupid] then
                        missionCommands.removeItemForGroup(groupid, ReconManager.groupMenus[groupid])
                        ReconManager.groupMenus[groupid] = nil
                    end
    
                    if not ReconManager.groupMenus[groupid] then
                        local menu = missionCommands.addSubMenuForGroup(groupid, 'Recon')
                        missionCommands.addCommandForGroup(groupid, 'Start', menu, Utils.log(context.activateRecon), context, groupname)
                        missionCommands.addCommandForGroup(groupid, 'Cancel', menu, Utils.log(context.cancelRecon), context, groupname)
                        missionCommands.addCommandForGroup(groupid, 'Analyze', menu, Utils.log(context.analyzeData), context, groupname)
    
                        ReconManager.groupMenus[groupid] = menu
                    end
                end
            elseif (event.id == world.event.S_EVENT_PLAYER_LEAVE_UNIT or event.id == world.event.S_EVENT_DEAD) and event.initiator and event.initiator.getPlayerName then
                local player = event.initiator:getPlayerName()
                if player then
                    local groupid = event.initiator:getGroup():getID()
                    
                    if ReconManager.groupMenus[groupid] then
                        missionCommands.removeItemForGroup(groupid, ReconManager.groupMenus[groupid])
                        ReconManager.groupMenus[groupid] = nil
                    end
                end
            end
        end, self)
    end

    function ReconManager:activateRecon(groupname)
        local gr = Group.getByName(groupname)
		if gr then
			local un = gr:getUnit(1)
			if un and un:isExist() then
                timer.scheduleFunction(function(param, time)
                    local cancelRequest = param.context.cancelRequests[param.groupname]
                    if cancelRequest and (timer.getAbsTime() - cancelRequest < 5) then
                        param.context.cancelRequests[param.groupname] = nil
                        return
                    end

                    local shouldUpdateMsg = (timer.getAbsTime() - param.lastUpdate) > ReconManager.updateFrequency

                    local withinParameters = false

                    local pgr = Group.getByName(param.groupname)
                    if not pgr then 
                        return 
                    end
                    local pun = pgr:getUnit(1)
                    if not pun or not pun:isExist() then 
                        return
                    end

                    local closestZone = nil
                    if param.lastZone then
                        if param.lastZone.side == 0 or param.lastZone.side == pun:getCoalition() then
                            local msg = param.lastZone.name..' is no longer controlled by the enemy.'
                            msg = msg..'\n Discarding data.'
                            trigger.action.outTextForUnit(pun:getID(), msg, 20)
                            closestZone = ZoneCommand.getClosestZoneToPoint(pun:getPoint(), Utils.getEnemy(pun:getCoalition()))
                        else
                            closestZone = param.lastZone
                        end
                    else
                        closestZone = ZoneCommand.getClosestZoneToPoint(pun:getPoint(), Utils.getEnemy(pun:getCoalition()))
                    end
                    
                    if not closestZone then
                        return
                    end

                    local stats = ReconManager.getAircraftStats(pun:getDesc().typeName)
                    local currentParameters = {
                        distance = 0,
                        deviation = 0,
                        percent_visible = 0
                    }
                    
                    currentParameters.distance = mist.utils.get2DDist(pun:getPoint(), closestZone.zone.point)

                    local unitPos = pun:getPosition()
                    local unitheading = math.deg(math.atan2(unitPos.x.z, unitPos.x.x))
                    local bearing = Utils.getBearing(pun:getPoint(), closestZone.zone.point)
                    
                    currentParameters.deviation = math.abs(Utils.getHeadingDiff(unitheading, bearing))

                    local unitsCount = 0
                    local visibleCount = 0
                    for _,product in pairs(closestZone.built) do
                        if product.side ~= pun:getCoalition() then
                            local gr = Group.getByName(product.name)
                            if gr then
                                for _,enemyUnit in ipairs(gr:getUnits()) do
                                    unitsCount = unitsCount+1
                                    local from = pun:getPoint()
                                    from.y = from.y+1.5
                                    local to = enemyUnit:getPoint()
                                    to.y = to.y+1.5
                                    if land.isVisible(from, to) then
                                        visibleCount = visibleCount+1
                                    end
                                end 
                            else
                                local st = StaticObject.getByName(product.name)
                                if st then
                                    unitsCount = unitsCount+1
                                    local from = pun:getPoint()
                                    from.y = from.y+1.5
                                    local to = st:getPoint()
                                    to.y = to.y+1.5
                                    if land.isVisible(from, to) then
                                        visibleCount = visibleCount+1
                                    end
                                end
                            end
                        end
                    end
                    
                    if unitsCount > 0 and visibleCount > 0 then
                        currentParameters.percent_visible = visibleCount/unitsCount
                    end

                    if currentParameters.distance < (stats.minDist * 1000) and currentParameters.percent_visible >= 0.5 then
                        if stats.maxDeviation then
                            if currentParameters.deviation <= stats.maxDeviation then
                                withinParameters = true
                            end
                        else
                            withinParameters = true
                        end
                    end

                    if withinParameters then
                        if not param.lastZone then
                            param.lastZone = closestZone
                        end

                        param.timeout = 300

                        local speed = stats.recon_speed * currentParameters.percent_visible
                        param.progress = math.min(param.progress + speed, ReconManager.requiredProgress)

                        if shouldUpdateMsg then
                            local msg = "[Recon: "..param.lastZone.name..']'
                            msg = msg.."\nProgress: "..string.format('%.1f', (param.progress/ReconManager.requiredProgress)*100)..'%\n'
                            msg = msg.."\nVisibility: "..string.format('%.1f', currentParameters.percent_visible*100)..'%'
                            trigger.action.outTextForUnit(pun:getID(), msg, ReconManager.updateFrequency)

                            param.lastUpdate = timer.getAbsTime()
                        end
                    else
                        param.timeout = param.timeout - 1
                        if shouldUpdateMsg then

                            local msg = "[Nearest enemy zone: "..closestZone.name..']'
                            
                            if param.lastZone then
                                msg = "[Recon in progress: "..param.lastZone.name..']'
                                msg = msg.."\nProgress: "..string.format('%.1f', (param.progress/ReconManager.requiredProgress)*100)..'%\n'
                            end
                            
                            if stats.maxDeviation then
                                msg = msg.."\nDeviation: "..string.format('%.1f', currentParameters.deviation)..' deg (under '..stats.maxDeviation..' deg)'
                            end
                            
                            msg = msg.."\nDistance: "..string.format('%.2f', currentParameters.distance/1000)..'km (under '..stats.minDist..' km)'
                            msg = msg.."\nVisibility: "..string.format('%.1f', currentParameters.percent_visible*100)..'% (min 50%)'
                            msg = msg.."\n\nTime left: "..param.timeout..' sec'
                            trigger.action.outTextForUnit(pun:getID(), msg, ReconManager.updateFrequency)

                            param.lastUpdate = timer.getAbsTime()
                        end
                    end

                    if param.progress >= ReconManager.requiredProgress then

                        local msg = "Data recorded for "..param.lastZone.name
                        msg = msg.."\nAnalyze data at a friendly zone to recover results"
                        trigger.action.outTextForUnit(pun:getID(), msg, 20)

                        param.context.recondata[param.groupname] = param.lastZone
                        return
                    end
                    
                    if param.timeout > 0 then
                        return time+1
                    end

                    local msg = "Recon cancelled."
                    if param.progress > 0 then
                        msg = msg.." Data lost."
                    end 
                    trigger.action.outTextForUnit(pun:getID(), msg, 20)

                end, {context = self, groupname = groupname, timeout = 300, progress = 0, lastZone = nil, lastUpdate = timer.getAbsTime()-5}, timer.getTime()+1)
            end
        end
    end

    function ReconManager:cancelRecon(groupname)
        self.cancelRequests[groupname] = timer.getAbsTime()
    end

    function ReconManager:analyzeData(groupname)
        local gr = Group.getByName(groupname)
        if not gr then return end
        local un = gr:getUnit(1)
        if not un or not un:isExist() then return end
        local player = un:getPlayerName()
        
        local zn = ZoneCommand.getZoneOfUnit(un:getName())
        if not zn then
            zn = CarrierCommand.getCarrierOfUnit(un:getName())
        end

        if not zn or not Utils.isLanded(un, zn.isCarrier) then 
            trigger.action.outTextForUnit(un:getID(), "Recon data can only be analyzed while landed in a friendly zone.", 5)
            return 
        end

        local data = self.recondata[groupname]
        if data then
            if data.side == 0 or data.side == un:getCoalition() then
                local msg = param.lastZone.name..' is no longer controlled by the enemy.'
                msg = msg..'\n Data discarded.'
                trigger.action.outTextForUnit(un:getID(), msg, 20)
            else
                local wasRevealed = data.revealTime > 60
                data:reveal()

                if data:hasUnitWithAttributeOnSide({'Buildings'}, 1) then
                    local tgt = data:getRandomUnitWithAttributeOnSide({'Buildings'}, 1)
                    if tgt then
                        MissionTargetRegistry.addStrikeTarget(tgt, data)
                        trigger.action.outTextForUnit(un:getID(), tgt.display..' discovered at '..data.name, 20)
                    end
                end

                local xp = RewardDefinitions.actions.recon * DependencyManager.get("PlayerTracker"):getPlayerMultiplier(player)
                if wasRevealed then
                    xp = xp/10
                end

                DependencyManager.get("PlayerTracker"):addStat(player, math.floor(xp), PlayerTracker.statTypes.xp)
                local msg = '+'..math.floor(xp)..' XP'
                trigger.action.outTextForUnit(un:getID(), msg, 10)

                DependencyManager.get("MissionTracker"):tallyRecon(player, data.name, zn.name)
            end

            self.recondata[groupname] = nil
        else
            trigger.action.outTextForUnit(un:getID(), "No data recorded.", 5)
        end
    end

    function ReconManager.getAircraftStats(aircraftType)
        local stats = ReconManager.aircraftStats[aircraftType]
        if not stats then
            stats = { recon_speed = 1, minDist = 5 }
        end

        return stats
    end

    ReconManager.aircraftStats = {
        ['A-10A'] =         { recon_speed = 1,  minDist = 5,  },
        ['A-10C'] =         { recon_speed = 2,  minDist = 20, },
        ['A-10C_2'] =       { recon_speed = 2,  minDist = 20, },
        ['A-4E-C'] =        { recon_speed = 1,  minDist = 5,  },
        ['AJS37'] =         { recon_speed = 10, minDist = 10, },
        ['AV8BNA'] =        { recon_speed = 2,  minDist = 20, },
        ['C-101CC'] =       { recon_speed = 1,  minDist = 5,  },
        ['F-14A-135-GR'] =  { recon_speed = 10, minDist = 5,  },
        ['F-14B'] =         { recon_speed = 10, minDist = 5,  },
        ['F-15C'] =         { recon_speed = 1,  minDist = 5,  },
        ['F-16C_50'] =      { recon_speed = 2,  minDist = 20, },
        ['F-5E-3'] =        { recon_speed = 1,  minDist = 5,  },
        ['F-86F Sabre'] =   { recon_speed = 1,  minDist = 5,  },
        ['FA-18C_hornet'] = { recon_speed = 2,  minDist = 20, },
        ['Hercules'] =      { recon_speed = 1,  minDist = 5,  },
        ['J-11A'] =         { recon_speed = 1,  minDist = 5,  },
        ['JF-17'] =         { recon_speed = 2,  minDist = 20, },
        ['L-39ZA'] =        { recon_speed = 1,  minDist = 5,  },
        ['M-2000C'] =       { recon_speed = 1,  minDist = 5,  },
        ['Mirage-F1BE'] =   { recon_speed = 1,  minDist = 5,  },
        ['Mirage-F1CE'] =   { recon_speed = 1,  minDist = 5,  },
        ['Mirage-F1EE'] =   { recon_speed = 1,  minDist = 5,  },
        ['MiG-15bis'] =     { recon_speed = 1,  minDist = 5,  },
        ['MiG-19P'] =       { recon_speed = 1,  minDist = 5,  },
        ['MiG-21Bis'] =     { recon_speed = 1,  minDist = 5,  },
        ['MiG-29A'] =       { recon_speed = 1,  minDist = 5,  },
        ['MiG-29G'] =       { recon_speed = 1,  minDist = 5,  },
        ['MiG-29S'] =       { recon_speed = 1,  minDist = 5,  },
        ['Su-25'] =         { recon_speed = 1,  minDist = 5,  },
        ['Su-25T'] =        { recon_speed = 2,  minDist = 10, },
        ['Su-27'] =         { recon_speed = 1,  minDist = 5,  },
        ['Su-33'] =         { recon_speed = 1,  minDist = 5,  },
        ['T-45'] =          { recon_speed = 1,  minDist = 5,  },
        ['AH-64D_BLK_II'] = { recon_speed = 5,  minDist = 15, maxDeviation = 120 },
        ['Ka-50'] =         { recon_speed = 5,  minDist = 15, maxDeviation = 35  },
        ['Ka-50_3'] =       { recon_speed = 5,  minDist = 15, maxDeviation = 35  },
        ['Mi-24P'] =        { recon_speed = 5,  minDist = 10, maxDeviation = 60  },
        ['Mi-8MT'] =        { recon_speed = 1,  minDist = 5,  maxDeviation = 30  },
        ['SA342L'] =        { recon_speed = 5,  minDist = 10, maxDeviation = 120 },
        ['SA342M'] =        { recon_speed = 10, minDist = 15, maxDeviation = 120 },
        ['SA342Minigun'] =  { recon_speed = 2,  minDist = 5,  maxDeviation = 45  },
        ['UH-1H'] =         { recon_speed = 1,  minDist = 5,  maxDeviation = 30  },
        ['UH-60L'] =        { recon_speed = 1,  minDist = 5,  maxDeviation = 30  }
    }
end

