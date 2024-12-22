
ReconManager = {}
do
    ReconManager.groupMenus = {}
    ReconManager.requiredProgress = 5*60
    ReconManager.updateFrequency = 5

    function ReconManager:new()
        local obj = {}
        obj.recondata = {}
        obj.cancelRequests = {}
        obj.reconAreas = {}

        setmetatable(obj, self)
		self.__index = self
		DependencyManager.register("ReconManager", obj)
        obj:init()
        return obj
    end

    function ReconManager:init()
        MenuRegistry.register(7, function(event, context)
            if (event.id == world.event.S_EVENT_PLAYER_ENTER_UNIT or event.id == world.event.S_EVENT_BIRTH) and event.initiator and event.initiator.getPlayerName then
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
                        missionCommands.addCommandForGroup(groupid, 'Report visible', menu, Utils.log(context.delayedDiscoverGroups), context, groupname)
                        
                        local stats = ReconManager.getAircraftStats(event.initiator:getDesc().typeName)
                        if stats and stats.canRecon then
                            missionCommands.addCommandForGroup(groupid, 'Start', menu, Utils.log(context.activateRecon), context, groupname)
                            missionCommands.addCommandForGroup(groupid, 'Cancel', menu, Utils.log(context.cancelRecon), context, groupname)
                            missionCommands.addCommandForGroup(groupid, 'Analyze', menu, Utils.log(context.analyzeData), context, groupname)
                            
                            if stats.uploadRate > 0 then
                                missionCommands.addCommandForGroup(groupid, 'Upload', menu, Utils.log(context.uploadData), context, groupname)
                            end
                        end

                        
                        ReconManager.groupMenus[groupid] = menu
                    end
                end
            end
        end, self)

        timer.scheduleFunction(function(param, time)
            local remaining = {}
            for _, ra in ipairs(param.context.reconAreas) do
                ra.lifetime = ra.lifetime - 5
                if ra.lifetime <= 0 then
                    ra:remove()
                else
                    local shouldkeep = true
                    if ra.group then
                        local deleted = ra:refreshMovingGroup()
                        if deleted then shouldkeep = false end
                    end

                    if shouldkeep then
                        table.insert(remaining, ra) 
                    end
                end
            end

            param.context.reconAreas = remaining
            
            return time+5
        end, {context = self}, timer.getTime()+5)
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
                        if param.lastZone.side == pun:getCoalition() then
                            local msg = param.lastZone.name..' is now friendly.'
                            msg = msg..'\n Discarding data.'
                            trigger.action.outTextForUnit(pun:getID(), msg, 20)
                            param.lastZone = nil
                            closestZone = ZoneCommand.getClosestZoneToPoint(pun:getPoint(), pun:getCoalition(), true)
                        else
                            closestZone = param.lastZone
                        end
                    else
                        closestZone = ZoneCommand.getClosestZoneToPoint(pun:getPoint(), pun:getCoalition(), true)
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

    function ReconManager:uploadData(groupname)
        local gr = Group.getByName(groupname)
        if not gr then return end
        local un = gr:getUnit(1)
        if not un or not un:isExist() then return end
        local player = un:getPlayerName()
        
        local zn = ZoneCommand.getZoneOfUnit(un:getName())
        if not zn then
            zn = CarrierCommand.getCarrierOfUnit(un:getName())
        end

        if not zn then
            zn = FARPCommand.getFARPOfUnit(un:getName())
        end

        local data = self.recondata[groupname]
        if not data then
            trigger.action.outTextForUnit(un:getID(), "No data recorded.", 5)
            return
        end

        if not zn or not Utils.isLanded(un, zn.isCarrier) or zn.side ~= un:getCoalition() then 
            timer.scheduleFunction(function(param, time) 
                local gr = Group.getByName(param.groupname)
                if not gr then return end
                local un = gr:getUnit(1)
                if not un or not un:isExist() then return end

                local data = self.recondata[groupname]
                if not data then return end

                local stats = ReconManager.getAircraftStats(un:getDesc().typeName)

                param.progress = param.progress - stats.uploadRate
                if param.progress <= 0 then
                    param.context:analyzeData(param.groupname, true)
                else
                    if timer.getTime() - param.lastMessageTime > 2 then 
                        local printProgress = string.format("%.2f", math.max(100.0-param.progress, 0.0))

                        trigger.action.outTextForUnit(un:getID(), "Uploading data ["..printProgress.."%]", 2)
                        param.lastMessageTime = timer.getTime()
                    end
                    return time+1
                end
            end, { context = self, groupname = groupname, progress = 100.0, lastMessageTime = timer.getTime()-10}, timer.getTime()+1)
        else
            self:analyzeData(groupname)
        end
    end

    function ReconManager:analyzeData(groupname, ignoreZone)
        local gr = Group.getByName(groupname)
        if not gr then return end
        local un = gr:getUnit(1)
        if not un or not un:isExist() then return end
        local player = un:getPlayerName()
        
        local zn = nil
        if not ignoreZone then
            zn = ZoneCommand.getZoneOfUnit(un:getName())
            if not zn then
                zn = CarrierCommand.getCarrierOfUnit(un:getName())
            end
            
            if not zn then
                zn = FARPCommand.getFARPOfUnit(un:getName())
                if zn and not zn:hasFeature(PlayerLogistics.buildables.satuplink) then
                    trigger.action.outTextForUnit(un:getID(), zn.name..' lacks a Satellite Uplink. Can not analyze recon data.', 10)
                    return
                end
            end

            if not zn or not Utils.isLanded(un, zn.isCarrier) or zn.side ~= un:getCoalition() then 
                trigger.action.outTextForUnit(un:getID(), "Recon data can only be analyzed while landed in a friendly zone.", 5)
                return 
            end
        end

        local data = self.recondata[groupname]
        if data then
            if data.side == un:getCoalition() then
                local msg = data.name..' is now friendly'
                msg = msg..'\n Data discarded.'
                trigger.action.outTextForUnit(un:getID(), msg, 20)
            else
                local wasRevealed = data.revealTime > 60
                data:reveal()

                local stats = ReconManager.getAircraftStats(un:getDesc().typeName)
                local side = 0
                if un:getCoalition() == 1 then 
                    side = 2
                elseif un:getCoalition() == 2 then
                    side = 1
                end

                self:revealEnemyInZone(data, un, side, stats.precission)

                local xp = RewardDefinitions.actions.recon * DependencyManager.get("PlayerTracker"):getPlayerMultiplier(player)
                if wasRevealed then
                    xp = xp/10
                end

                if ignoreZone then
                    local instantxp = math.floor(xp*0.25)
                    local tempxp = math.floor(xp - instantxp)

                    DependencyManager.get("PlayerTracker"):addStat(player, instantxp, PlayerTracker.statTypes.xp)
                    env.info("ReconManager.analyzeData - "..player..' awarded '..tostring(instantxp)..' xp')

                    local msg = '[XP] '..DependencyManager.get("PlayerTracker").stats[player][PlayerTracker.statTypes.xp]..' (+'..instantxp..')'
                    DependencyManager.get("PlayerTracker"):addTempStat(player, tempxp, PlayerTracker.statTypes.xp)
                    msg = msg..'\n+'..tempxp..' XP (unclaimed)'
                    trigger.action.outTextForUnit(un:getID(), msg, 10)
                    env.info("ReconManager.analyzeData - "..player..' awarded '..tostring(tempxp)..' xp (unclaimed)')
                else
                    DependencyManager.get("PlayerTracker"):addStat(player, math.floor(xp), PlayerTracker.statTypes.xp)
                    local msg = '+'..math.floor(xp)..' XP'
                    trigger.action.outTextForUnit(un:getID(), msg, 10)
                end

                local analyzeZoneName = ''
                if zn then
                    analyzeZoneName = zn.name
                end

                DependencyManager.get("MissionTracker"):tallyRecon(player, data.name, analyzeZoneName)
            end

            self.recondata[groupname] = nil
        else
            trigger.action.outTextForUnit(un:getID(), "No data recorded.", 5)
        end
    end

    function ReconManager:delayedDiscoverGroups(groupname)
        local gr = Group.getByName(groupname)
        if not gr then return end
        local un = gr:getUnit(1)
        if not un or not un:isExist() then return end

        trigger.action.outTextForUnit(un:getID(), "Reporting...", 3)

        timer.scheduleFunction(function(param,time)
            param.context:discoverGroups(param.groupname)
        end, {context=self, groupname=groupname}, timer.getTime()+3)
    end

    function ReconManager:discoverGroups(groupname)
        local gr = Group.getByName(groupname)
        if not gr then return end
        local un = gr:getUnit(1)
        if not un or not un:isExist() then return end
        local player = un:getPlayerName()
        
        local stats = ReconManager.getAircraftStats(un:getDesc().typeName)
        local maxDev = stats.maxDeviation or 999

        local ppos = un:getPoint()
        local volume = {
            id = world.VolumeType.SPHERE,
            params = {
                point = {x=ppos.x, z=ppos.z, y=land.getHeight({x = ppos.x, y = ppos.z})},
                radius = stats.minDist*1000
            }
        }

        local groups = {}
        world.searchObjects(Object.Category.UNIT , volume, function(unit, collection)
            if unit and unit:isExist() and unit:getGroup() then 
                collection[unit:getGroup():getName()] = unit:getGroup()
            end

            return true
         end, groups)

        local count = 0
        for i,v in pairs(groups) do
            if i ~= groupname then
                local unitPos = un:getPosition()
                local unitheading = math.deg(math.atan2(unitPos.x.z, unitPos.x.x))
                local bearing = Utils.getBearing(un:getPoint(), v:getUnit(1):getPoint())
                
                local deviation = math.abs(Utils.getHeadingDiff(unitheading, bearing))

                if v:getCoalition()~=un:getCoalition() and deviation <= maxDev then
                    local from = un:getPoint()
                    from.y = from.y+1.5
                    local to = v:getUnit(1):getPoint()
                    to.y = to.y+1.5
                    if land.isVisible(from, to) then
                        local class = self:revealGroup(i, stats.precission*1000, stats.recon_speed*(60*3))
                        if class then 
                            trigger.action.outTextForUnit(un:getID(), class..' reported, bearing '..math.floor(bearing), 20) 
                            count = count + 1
                        end
                    end
                end
            end
        end

        if count == 0 then trigger.action.outTextForUnit(un:getID(), "Nothing to report", 20) end
    end

    function ReconManager:revealGroup(groupname, padding, lifetime)
        local gr = Group.getByName(groupname)
        if not gr or not gr:isExist() or gr:getSize()==0 then return end
        local class = ReconManager.classifyGroup(gr)
        if class == nil then return end

        local ra = ReconArea:new()
        ra.padding = padding
        ra.name = class..'-'..math.fmod(gr:getID(), 10000)

        if lifetime then ra.lifetime = lifetime end

        table.insert(self.reconAreas, ra)
        ra:drawMovingGroup(gr)

        return class
    end

    function ReconManager:revealEnemyInZone(zone, messageUnit, side, accuracy)
        if not accuracy then
            accuracy = 1.0
        end

        for _,bl in pairs(zone.built) do
            if bl.side == side then
                self:createReconArea(bl, zone, 250*accuracy)      
                if messageUnit then trigger.action.outTextForUnit(messageUnit:getID(), bl.display..' discovered at '..zone.name, 20) end
            end
        end
    end

    function ReconManager:createReconArea(product, zone, padding, lifetime, skipMissionTGT)
        local ra = ReconArea:new(zone.name, product.name)
        ra.padding = padding
        local keep = false

        if product.type == ZoneCommand.productTypes.upgrade then
            local tgt = StaticObject.getByName(product.name)
            if tgt then
                if not skipMissionTGT then MissionTargetRegistry.addStrikeTarget(product, zone) end
                local tgp = tgt:getPoint()
                if ra.padding > 30 then
                    tgp.x = tgp.x + math.random(-ra.padding, ra.padding)
                    tgp.z = tgp.z + math.random(-ra.padding, ra.padding)
                end
                ra:addPoint(tgp)
                keep = true
        
                ra.name = product.display..'-'..math.fmod(tgt:getID(), 10000)
            end
        elseif product.type == ZoneCommand.productTypes.defense then
            local tgt = Group.getByName(product.name)
            if tgt then
                local class = ReconManager.classifyGroup(tgt)
                if class then
                    for i,v in ipairs(tgt:getUnits()) do
                        local tgp = v:getPoint()
                        if ra.padding > 30 then
                            tgp.x = tgp.x + math.random(-ra.padding, ra.padding)
                            tgp.z = tgp.z + math.random(-ra.padding, ra.padding)
                        end
                        ra:addPoint(tgp)
                        keep = true
                    end

                    ra.name = class..'-'..math.fmod(tgt:getID(), 10000)
                end
            end
        end

        if keep then
            if lifetime then ra.lifetime = lifetime end
            table.insert(self.reconAreas, ra)
            ra:draw()
        end
    end

    function ReconManager.classifyGroup(group)
        local classes = {
            { class="LORAD", attr="LR SAM" },
            { class="MEDRAD", attr="MR SAM" },
            { class="SHORAD", attr="SR SAM" },
            { class="MANPADS", attr="MANPADS" },
            { class="IR SAM", attr="IR Guided SAM" },
            { class="AAA", attr="AAA" },
            { class="EWR", attr="EWR"},
            { class="ARMOR", attr="Armored vehicles" },
            { class="INFANTRY", attr="Infantry" },
            { class="UNARMED", attr="Unarmed vehicles" },
        }

        local class = nil
        local rank = #classes
        for i,v in ipairs(group:getUnits()) do
            for r,c in ipairs(classes) do
                if r > rank then break end

                if v:hasAttribute(c.attr) then 
                    class = c
                    rank = r
                end
            end
        end

        if class then return class.class end
    end

    function ReconManager.getAircraftStats(aircraftType)
        local stats = ReconManager.aircraftStats[aircraftType]
        if not stats then
            stats = { uploadRate = 0, precission = 1.0, recon_speed = 1, minDist = 5, maxDeviation = 45 }
        end

        return stats
    end

    ReconManager.aircraftStats = {
        ['A-10A'] =         { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45, },
        ['A-10C'] =         { uploadRate = 0.8, precission=0.5, recon_speed = 2,  minDist = 20, maxDeviation = 120 },
        ['A-10C_2'] =       { uploadRate = 1.6, precission=0.5, recon_speed = 2,  minDist = 20, maxDeviation = 120 },
        ['A-4E-C'] =        { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['AJS37'] =         { uploadRate = 0,   precission=0.7, recon_speed = 10, minDist = 10, maxDeviation = 90 },
        ['AV8BNA'] =        { uploadRate = 0,   precission=0.5, recon_speed = 2,  minDist = 20, maxDeviation = 120 },
        ['C-101CC'] =       { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['F-14A-135-GR'] =  { uploadRate = 0,   precission=0.5, recon_speed = 10, minDist = 5,  maxDeviation = 120 },
        ['F-4E-45MC'] =     { uploadRate = 0,   precission=0.5, recon_speed = 5,  minDist = 5,  maxDeviation = 90 },
        ['F-14B'] =         { uploadRate = 0,   precission=0.5, recon_speed = 10, minDist = 5,  maxDeviation = 120 },
        ['F-15C'] =         { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['F-16C_50'] =      { uploadRate = 1.6, precission=0.5, recon_speed = 2,  minDist = 20, maxDeviation = 120 },
        ['F-5E-3'] =        { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['F-86F Sabre'] =   { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['FA-18C_hornet'] = { uploadRate = 1.6, precission=0.5, recon_speed = 2,  minDist = 20, maxDeviation = 120 },
        ['Hercules'] =      { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['J-11A'] =         { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['JF-17'] =         { uploadRate = 1.6, precission=0.5, recon_speed = 2,  minDist = 20, maxDeviation = 120 },
        ['L-39ZA'] =        { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['M-2000C'] =       { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['Mirage-F1BE'] =   { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['Mirage-F1CE'] =   { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['Mirage-F1EE'] =   { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['MiG-15bis'] =     { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['MiG-19P'] =       { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['MiG-21Bis'] =     { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['MiG-29A'] =       { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['MiG-29G'] =       { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['MiG-29S'] =       { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['Su-25'] =         { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['Su-25T'] =        { uploadRate = 0,   precission=0.8, recon_speed = 2,  minDist = 10, maxDeviation = 45 },
        ['Su-27'] =         { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['Su-33'] =         { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        ['T-45'] =          { uploadRate = 0,   precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45 },
        
        ['AH-64D_BLK_II'] = { uploadRate = 1.6, precission=0.3, recon_speed = 5,  minDist = 15, maxDeviation = 120 },
        ['Ka-50'] =         { uploadRate = 0,   precission=0.3, recon_speed = 5,  minDist = 15, maxDeviation = 35  },
        ['Ka-50_3'] =       { uploadRate = 0,   precission=0.3, recon_speed = 5,  minDist = 15, maxDeviation = 35  },
        ['Mi-24P'] =        { uploadRate = 0,   precission=0.5, recon_speed = 5,  minDist = 10, maxDeviation = 60  },
        ['Mi-8MT'] =        { uploadRate = 0,   precission=0.8, recon_speed = 1,  minDist = 5,  maxDeviation = 30  },
        ['SA342L'] =        { uploadRate = 0,   precission=0.3, recon_speed = 5,  minDist = 10, maxDeviation = 120, canRecon=true },
        ['SA342M'] =        { uploadRate = 0,   precission=0.2, recon_speed = 10, minDist = 15, maxDeviation = 120, canRecon=true },
        ['SA342Minigun'] =  { uploadRate = 0,   precission=0.7, recon_speed = 3,  minDist = 5,  maxDeviation = 45, canRecon=true  },
        ['UH-1H'] =         { uploadRate = 0,   precission=0.8, recon_speed = 1,  minDist = 5,  maxDeviation = 30  },
        ['UH-60L'] =        { uploadRate = 0,   precission=0.8, recon_speed = 1,  minDist = 8,  maxDeviation = 45  },
        ['OH-6A'] =         { uploadRate = 0,   precission=0.8, recon_speed = 3,  minDist = 8,  maxDeviation = 45, canRecon=true  },
        ['OH58D'] =         { uploadRate = 5,   precission=0.1, recon_speed = 10, minDist = 15, maxDeviation = 190, canRecon=true },
        ['CH-47Fbl1'] =        { uploadRate = 0,   precission=0.8, recon_speed = 1,  minDist = 5,  maxDeviation = 30  },

        ['M 818'] = 				{ uploadRate = 0,     precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45  },
        ['M-2 Bradley'] = 			{ uploadRate = 1.6,   precission=0.5, recon_speed = 2,  minDist = 5,  maxDeviation = 45  },
        ['M6 Linebacker'] = 		{ uploadRate = 1.6,   precission=0.5, recon_speed = 2,  minDist = 5,  maxDeviation = 45  },
        ['M-113'] = 				{ uploadRate = 0,     precission=1.0, recon_speed = 1,  minDist = 5,  maxDeviation = 45  },
        ['MaxxPro_MRAP'] = 			{ uploadRate = 1.6,   precission=0.8, recon_speed = 5,  minDist = 5,  maxDeviation = 45  },
        ['M1043 HMMWV Armament'] = 	{ uploadRate = 1.6,   precission=0.3, recon_speed = 10, minDist = 5,  maxDeviation = 45  },
        ['Land_Rover_101_FC'] = 	{ uploadRate = 0,     precission=0.8, recon_speed = 1,  minDist = 5,  maxDeviation = 45  },
    }
end

