



PlayerTracker = {}
do
    PlayerTracker.savefile = 'player_stats_v2.0.json'
    PlayerTracker.statTypes = {
        xp = 'XP',
        cmd = "CMD",
        survivalBonus = "SB"
    }

    PlayerTracker.cmdShopTypes = {
        smoke = 'smoke',
        jtac = 'jtac',
        bribe1 = 'bribe1',
        bribe2 = 'bribe2',
        artillery = 'artillery',
        sabotage1 = 'sabotage1',
    }

    PlayerTracker.cmdShopPrices = {
        [PlayerTracker.cmdShopTypes.smoke] = 1,
        [PlayerTracker.cmdShopTypes.jtac] = 20,
        [PlayerTracker.cmdShopTypes.bribe1] = 10,
        [PlayerTracker.cmdShopTypes.bribe2] = 15,
        [PlayerTracker.cmdShopTypes.artillery] = 40,
        [PlayerTracker.cmdShopTypes.sabotage1] = 30,
    }

    PlayerTracker.callsigns = { 'Caveman', 'Casper', 'Banjo', 'Boomer', 'Shaft', 'Wookie', 'Tiny', 'Tool', 'Trash', 'Orca', 'Irish', 'Flex', 'Grip', 'Dice', 'Duck', 'Poet', 'Jack', 'Lego', 'Hurl', 'Spin' }
    table.sort(PlayerTracker.callsigns)

	function PlayerTracker:new()
		local obj = {}
        obj.stats = {}
        obj.config = {}
        obj.tempStats = {}
        obj.groupMenus = {}
        obj.groupShopMenus = {}
        obj.groupTgtMenus = {}
        obj.playerEarningMultiplier = {}

        if lfs then 
            local dir = lfs.writedir()..'Missions/Saves/'
            lfs.mkdir(dir)
            PlayerTracker.savefile = dir..PlayerTracker.savefile
            env.info('Pretense - Player stats file path: '..PlayerTracker.savefile)
        end

        local save = Utils.loadTable(PlayerTracker.savefile)
        if save then 
            obj.stats = save.stats or {}
            obj.config = save.config or {}
        end

		setmetatable(obj, self)
		self.__index = self
		
        obj:init()

		DependencyManager.register("PlayerTracker", obj)
		return obj
	end

    function PlayerTracker:init()
        local ev = {}
        ev.context = self
        function ev:onEvent(event)
            if not event.initiator then return end
            if not event.initiator.getPlayerName then return end
            if not event.initiator.getCoalition then return end

            local player = event.initiator:getPlayerName()
            if not player then return end
            
            local blocked = false
            if event.id==world.event.S_EVENT_BIRTH then
                if event.initiator and Object.getCategory(event.initiator) == Object.Category.UNIT and 
                    (Unit.getCategoryEx(event.initiator) == Unit.Category.AIRPLANE or Unit.getCategoryEx(event.initiator) == Unit.Category.HELICOPTER)  then
                    
                        local pname = event.initiator:getPlayerName()
                        if pname then
                            local un = event.initiator

                            local zn = ZoneCommand.getZoneOfUnit(un:getName())
                            if not zn then CarrierCommand.getCarrierOfUnit(un:getName()) end
                            if not zn then FARPCommand.getFARPOfUnit(un:getName()) end

                            if zn then
                                local isDifferentSide = zn.side ~= un:getCoalition()
                                local isNotSuported = zn.side == 1
                                local noResources = zn.resource < Config.zoneSpawnCost

                                local gr = event.initiator:getGroup()
                                if isDifferentSide or noResources or isNotSuported then
                                    blocked = true

                                    for i,v in pairs(net.get_player_list()) do
                                        if net.get_name(v) == pname then
                                            net.send_chat_to('Can not spawn as '..gr:getName()..' in enemy/neutral zone or zone without enough resources' , v)
                                            timer.scheduleFunction(function(param, time)
                                                net.force_player_slot(param, 0, '')
                                            end, v, timer.getTime()+0.1)
                                            break
                                        end
                                    end

                                    trigger.action.outTextForGroup(gr:getID(), 'Can not spawn as '..gr:getName()..' in enemy/neutral zone or zone without enough resources',5)
                                    if event.initiatior and event.initiator:isExist() then 
                                        event.initiator:destroy()
                                    end
                                end
                            end
                        end
                end
            end

            if event.id == world.event.S_EVENT_BIRTH and not blocked then
                -- init stats for player if not exist
                if not self.context.stats[player] then
                    self.context.stats[player] = {}
                end

                -- reset temp track for player
                self.context.tempStats[player] = nil

                local minutes = 0
                local multiplier = 1.0
                if self.context.stats[player][PlayerTracker.statTypes.survivalBonus] ~= nil then
                    minutes = self.context.stats[player][PlayerTracker.statTypes.survivalBonus]
                    multiplier = PlayerTracker.minutesToMultiplier(minutes)
                end

                self.context.playerEarningMultiplier[player] = { spawnTime = timer.getAbsTime(), unit = event.initiator, multiplier = multiplier, minutes = minutes }

                local config = self.context:getPlayerConfig(player)
                if config.gci_warning_radius then
                    local gci = DependencyManager.get("GCI")
                    gci:registerPlayer(player, event.initiator, config.gci_warning_radius, config.gci_metric)
                end
            end

            if event.id == world.event.S_EVENT_KILL then
                local target = event.target
                
                if not target then return end
                if not target.getCoalition then return end
                
                if target:getCoalition() == event.initiator:getCoalition() then return end
                
                local xpkey = PlayerTracker.statTypes.xp
                local award = PlayerTracker.getXP(target)

                award = math.floor(award * self.context:getPlayerMultiplier(player))

                local instantxp = math.floor(award*0.25)
                local tempxp = award - instantxp

                self.context:addStat(player, instantxp, PlayerTracker.statTypes.xp)
                local msg = '[XP] '..self.context.stats[player][xpkey]..' (+'..instantxp..')'
                env.info("PlayerTracker.kill - "..player..' awarded '..tostring(instantxp)..' xp')
                
                self.context:addTempStat(player, tempxp, PlayerTracker.statTypes.xp)
                msg = msg..'\n+'..tempxp..' XP (unclaimed)'
                env.info("PlayerTracker.kill - "..player..' awarded '..tostring(tempxp)..' xp (unclaimed)')

                trigger.action.outTextForUnit(event.initiator:getID(), msg, 5)
            end

            if event.id==world.event.S_EVENT_EJECTION then
				self.context.stats[player] = self.context.stats[player] or {}
                local ts = self.context.tempStats[player]
                if ts then
                    local un = event.initiator
                    local key = PlayerTracker.statTypes.xp
                    local xp = self.context.tempStats[player][key]
                    if xp then
                        xp = xp * self.context:getPlayerMultiplier(player)
                        trigger.action.outTextForUnit(un:getID(), 'Ejection. 30\% XP claimed', 5)
                        self.context:addStat(player, math.floor(xp*0.3), PlayerTracker.statTypes.xp)
                        trigger.action.outTextForUnit(un:getID(), '[XP] '..self.context.stats[player][key]..' (+'..math.floor(xp*0.3)..')', 5)
                    end
                    
                    self.context.tempStats[player] = nil
                end
			end

            if event.id==world.event.S_EVENT_TAKEOFF then
                local un = event.initiator
                env.info('PlayerTracker - '..player..' took off in '..tostring(un:getID())..' '..un:getName())
                if self.context.stats[player][PlayerTracker.statTypes.survivalBonus] ~= nil then
                    self.context.stats[player][PlayerTracker.statTypes.survivalBonus] = nil
                    trigger.action.outTextForUnit(un:getID(), 'Taken off, survival bonus no longer secure.', 10)
                end

                local zn = ZoneCommand.getZoneOfUnit(un:getName())
                if not zn then zn = CarrierCommand.getCarrierOfUnit(un:getName()) end
                if not zn then zn = FARPCommand.getFARPOfUnit(un:getName()) end

                if zn then
                    local cost = Config.zoneSpawnCost
                    if zn.isCarrier then cost = Config.carrierSpawnCost end
                    if zn.isFARP then cost = 0 end

                    zn:removeResource(cost)
                end
			end

            if event.id==world.event.S_EVENT_ENGINE_SHUTDOWN then
                local un = event.initiator
                local zn = ZoneCommand.getZoneOfUnit(un:getName())
                if not zn then 
                    zn = CarrierCommand.getCarrierOfUnit(un:getName())
                end
                
                if not zn then 
                    zn = FARPCommand.getFARPOfUnit(un:getName())
                    if zn and not zn:hasFeature(PlayerLogistics.buildables.satuplink) then
                        trigger.action.outTextForUnit(un:getID(), zn.name..' lacks a Satellite Uplink. Can not secure survival bonus.', 10)
                        return
                    end
                end

                if un and un:isExist() and zn and zn.side == un:getCoalition() then
                    env.info('PlayerTracker - '..player..' has shut down engine of '..tostring(un:getID())..' '..un:getName()..' at '..zn.name)
                    self.context.stats[player][PlayerTracker.statTypes.survivalBonus] = self.context:getPlayerMinutes(player)
                    self.context:save()
                    trigger.action.outTextForUnit(un:getID(), 'Engines shut down. Survival bonus secured.', 10)
                    env.info('PlayerTracker - '..player..' secured survival bonus of '..self.context.stats[player][PlayerTracker.statTypes.survivalBonus]..' minutes')
                end
			end

            if event.id==world.event.S_EVENT_LAND then
                self.context:validateLanding(event.initiator, player)
			end
        end

		world.addEventHandler(ev)
        self:periodicSave()
        self:menuSetup()

        timer.scheduleFunction(function(params, time)
            local players = params.context.playerEarningMultiplier
            for i,v in pairs(players) do
                if v.unit.isExist and v.unit:isExist() then
                    if v.multiplier < 5.0 and v.unit and v.unit:isExist() and Utils.isInAir(v.unit) then
                        v.minutes = v.minutes + 1
                        v.multiplier = PlayerTracker.minutesToMultiplier(v.minutes)
                    end
                end
            end

            return time+60
        end, {context = self}, timer.getTime()+60)
    end

    function PlayerTracker:validateLanding(unit, player, manual)
        local un = unit
        local zn = ZoneCommand.getZoneOfUnit(unit:getName())
        if not zn then 
            zn = CarrierCommand.getCarrierOfUnit(unit:getName())
        end
        
        if not zn then 
            zn = FARPCommand.getFARPOfUnit(unit:getName())
        end

        env.info('PlayerTracker - '..player..' landed in '..tostring(un:getID())..' '..un:getName())
        if un and zn and zn.side == un:getCoalition() then
            trigger.action.outTextForUnit(unit:getID(), "Wait 10 seconds to validate landing...", 10)
            timer.scheduleFunction(function(param, time)
                local un = param.unit
                if not un or not un:isExist() then return end
                
                local player = param.player
                local isLanded = Utils.isLanded(un, true)
                local zn = ZoneCommand.getZoneOfUnit(un:getName())
                if not zn then 
                    zn = CarrierCommand.getCarrierOfUnit(un:getName())
                end
                
                if not zn then 
                    zn = FARPCommand.getFARPOfUnit(unit:getName())
                    if zn and not zn:hasFeature(PlayerLogistics.buildables.satuplink) then
                        trigger.action.outTextForUnit(unit:getID(), zn.name..' lacks a Satellite Uplink', 10)
                        return
                    end
                end

                env.info('PlayerTracker - '..player..' checking if landed: '..tostring(isLanded))

                if zn and isLanded then
                    if not manual then
                        if zn.isCarrier then
                            zn:addResource(Config.carrierSpawnCost)
                        else
                            zn:addResource(Config.zoneSpawnCost)
                        end
                    end

                    if param.context.tempStats[player] then 
                        if zn and zn.side == un:getCoalition() then
                            param.context.stats[player] = param.context.stats[player] or {}
                            
                            trigger.action.outTextForUnit(un:getID(), 'Rewards claimed', 5)
                            for _,key in pairs(PlayerTracker.statTypes) do
                                local value = param.context.tempStats[player][key]
                                env.info("PlayerTracker.landing - "..player..' redeeming '..tostring(value)..' '..key)
                                if value then 
                                    param.context:commitTempStat(player, key)
                                    trigger.action.outTextForUnit(un:getID(), key..' +'..value..'', 5)
                                end
                            end

                            param.context:save()
                        end
                    end
                end
            end, {player = player, unit = unit, context = self}, timer.getTime()+10)
        end
    end

    function PlayerTracker:addTempStat(player, amount, stattype)
        self.tempStats[player] = self.tempStats[player] or {}
        self.tempStats[player][stattype] = self.tempStats[player][stattype] or 0
        self.tempStats[player][stattype] = self.tempStats[player][stattype] + amount
    end

    function PlayerTracker:addStat(player, amount, stattype)
        self.stats[player] = self.stats[player] or {}
        self.stats[player][stattype] = self.stats[player][stattype] or 0

        if stattype == PlayerTracker.statTypes.xp then
            local cur = self:getRank(self.stats[player][stattype])
            if cur then 
                local nxt = self:getRank(self.stats[player][stattype] + amount)
                if nxt and cur.rank < nxt.rank then
                    trigger.action.outText(player..' has leveled up to rank: '..nxt.name, 10)
                    if nxt.cmdAward and nxt.cmdAward > 0 then
                        self:addStat(player, nxt.cmdAward, PlayerTracker.statTypes.cmd)
                        trigger.action.outText(player.." awarded "..nxt.cmdAward.." CMD tokens", 10)
                        env.info("PlayerTracker.addStat - Awarded "..player.." "..nxt.cmdAward.." CMD tokens for rank up to "..nxt.name)
                    end
                end
            end
        end

        self.stats[player][stattype] = self.stats[player][stattype] + amount
    end

    function PlayerTracker:commitTempStat(player, statkey)
        local value = self.tempStats[player][statkey]
        if value then 
            self:addStat(player, value, statkey)

            self.tempStats[player][statkey] = nil
        end
    end

    function PlayerTracker:addRankRewards(player, unit, isTemp)
        local rank = self:getPlayerRank(player)
        if not rank then return end

        local cmdChance = rank.cmdChance
        if cmdChance > 0 then 

            local tkns = 0
            for i=1,rank.cmdTrys,1 do
                local die = math.random()
                if die <= cmdChance then 
                    tkns = tkns + 1
                end
            end

            if tkns > 0 then
                if isTemp then
                    self:addTempStat(player, tkns, PlayerTracker.statTypes.cmd)
                else
                    self:addStat(player, tkns, PlayerTracker.statTypes.cmd)
                end

                local msg = ""
                if isTemp then
                    msg = '+'..tkns..' CMD (unclaimed)'
                else
                    msg = '[CMD] '..self.stats[player][PlayerTracker.statTypes.cmd]..' (+'..tkns..')'
                end

                trigger.action.outTextForUnit(unit:getID(), msg, 5)
                env.info("PlayerTracker.addRankRewards - Awarded "..player.." "..tkns.." CMD tokens with chance "..cmdChance)
            end
        end
    end

    function PlayerTracker.getXP(unit)
        local xp = 30

        if unit:hasAttribute('Planes') then xp = xp + 20 end
        if unit:hasAttribute('Helicopters') then xp = xp + 20 end
        if unit:hasAttribute('Infantry') then xp = xp + 10 end
        if unit:hasAttribute('SAM SR') then xp = xp + 15 end
        if unit:hasAttribute('SAM TR') then xp = xp + 15 end
        if unit:hasAttribute('IR Guided SAM') then xp = xp + 10 end
        if unit:hasAttribute('Ships') then xp = xp + 20 end
        if unit:hasAttribute('Buildings') then xp = xp + 30 end
        if unit:hasAttribute('Tanks') then xp = xp + 10 end

        return xp
    end

    function PlayerTracker:menuSetup()
        
        MenuRegistry.register(1, function(event, context)
			if (event.id == world.event.S_EVENT_PLAYER_ENTER_UNIT or event.id == world.event.S_EVENT_BIRTH) and event.initiator and event.initiator.getPlayerName then
				local player = event.initiator:getPlayerName()
				if player then
					local groupid = event.initiator:getGroup():getID()
                    local groupname = event.initiator:getGroup():getName()
					
                    if context.groupMenus[groupid] then
                        missionCommands.removeItemForGroup(groupid, context.groupMenus[groupid])
                        context.groupMenus[groupid] = nil
                    end

                    if not context.groupMenus[groupid] then
                        
                        local menu = missionCommands.addSubMenuForGroup(groupid, 'Player')
                        missionCommands.addCommandForGroup(groupid, 'Stats', menu, Utils.log(context.showGroupStats), context, groupname)
                        missionCommands.addCommandForGroup(groupid, 'Frequencies', menu, Utils.log(context.showFrequencies), context, groupname)
                        missionCommands.addCommandForGroup(groupid, 'Validate Landing', menu, Utils.log(context.validateLandingMenu), context, groupname)

                        local cmenu = missionCommands.addSubMenuForGroup(groupid, 'Config', menu)
                        local missionWarningMenu = missionCommands.addSubMenuForGroup(groupid, 'No mission warning', cmenu)
                        missionCommands.addCommandForGroup(groupid, 'Activate', missionWarningMenu, Utils.log(context.setNoMissionWarning), context, groupname, true)
                        missionCommands.addCommandForGroup(groupid, 'Deactivate', missionWarningMenu, Utils.log(context.setNoMissionWarning), context, groupname, false)

                        local missionWarningMenu = missionCommands.addSubMenuForGroup(groupid, 'GCI Text reports', cmenu)
                        missionCommands.addCommandForGroup(groupid, 'Activate', missionWarningMenu, Utils.log(context.setGCITextReports), context, groupname, true)
                        missionCommands.addCommandForGroup(groupid, 'Deactivate', missionWarningMenu, Utils.log(context.setGCITextReports), context, groupname, false)
                        
                        context.groupMenus[groupid] = menu
                    end
				end
            end
		end, self)

        MenuRegistry.register(5, function(event, context)
			if (event.id == world.event.S_EVENT_PLAYER_ENTER_UNIT or event.id == world.event.S_EVENT_BIRTH) and event.initiator and event.initiator.getPlayerName then
				local player = event.initiator:getPlayerName()
				if player then
                    local rank = context:getPlayerRank(player)
                    if not rank then return end

                    local groupid = event.initiator:getGroup():getID()
                    local groupname = event.initiator:getGroup():getName()

                    if context.groupShopMenus[groupid] then
                        missionCommands.removeItemForGroup(groupid, context.groupShopMenus[groupid])
                        context.groupShopMenus[groupid] = nil
                    end
                    
                    if context.groupTgtMenus[groupid] then
                        missionCommands.removeItemForGroup(groupid, context.groupTgtMenus[groupid])
                        context.groupTgtMenus[groupid] = nil
                    end

                    if not context.groupShopMenus[groupid] then
                        
                        local menu = missionCommands.addSubMenuForGroup(groupid, 'Command & Control')
                        missionCommands.addCommandForGroup(groupid, 'Deploy Smoke ['..PlayerTracker.cmdShopPrices[PlayerTracker.cmdShopTypes.smoke]..' CMD]', menu, Utils.log(context.buyCommand), context, groupname, PlayerTracker.cmdShopTypes.smoke)
                        missionCommands.addCommandForGroup(groupid, 'Hack enemy comms ['..PlayerTracker.cmdShopPrices[PlayerTracker.cmdShopTypes.bribe1]..' CMD]', menu, Utils.log(context.buyCommand), context, groupname, PlayerTracker.cmdShopTypes.bribe1)
                        missionCommands.addCommandForGroup(groupid, 'Bribe enemy officer ['..PlayerTracker.cmdShopPrices[PlayerTracker.cmdShopTypes.bribe2]..' CMD]', menu, Utils.log(context.buyCommand), context, groupname, PlayerTracker.cmdShopTypes.bribe2)
                        missionCommands.addCommandForGroup(groupid, 'Shell zone with artillery ['..PlayerTracker.cmdShopPrices[PlayerTracker.cmdShopTypes.artillery]..' CMD]', menu, Utils.log(context.buyCommand), context, groupname, PlayerTracker.cmdShopTypes.artillery)
                        missionCommands.addCommandForGroup(groupid, 'Sabotage enemy zone ['..PlayerTracker.cmdShopPrices[PlayerTracker.cmdShopTypes.sabotage1]..' CMD]', menu, Utils.log(context.buyCommand), context, groupname, PlayerTracker.cmdShopTypes.sabotage1)
                        
                        if CommandFunctions.jtac then
                            missionCommands.addCommandForGroup(groupid, 'Deploy JTAC ['..PlayerTracker.cmdShopPrices[PlayerTracker.cmdShopTypes.jtac]..' CMD]', menu, Utils.log(context.buyCommand), context, groupname, PlayerTracker.cmdShopTypes.jtac)
                        end

                        context.groupShopMenus[groupid] = menu
                    end
				end
            end
		end, self)
		
        DependencyManager.get("MarkerCommands"):addCommand('stats',function(event, _, state) 
            local unit = nil
            if event.initiator then 
                unit = event.initiator
            elseif world.getPlayer() then
                unit = world.getPlayer()
            end

            if not unit then return false end

            state:showGroupStats(unit:getGroup():getName())
            return true
        end, false, self)

        DependencyManager.get("MarkerCommands"):addCommand('freqs',function(event, _, state) 
            local unit = nil
            if event.initiator then 
                unit = event.initiator
            elseif world.getPlayer() then
                unit = world.getPlayer()
            end

            if not unit then return false end

            state:showFrequencies(unit:getGroup():getName())
            return true
        end, false, self)
    end

    function PlayerTracker:setNoMissionWarning(groupname, active)
        local gr = Group.getByName(groupname)
        if gr and gr:getSize()>0 then 
            local un = gr:getUnit(1)
            if un then
                local player = un:getPlayerName()
                if player then
                    self:setPlayerConfig(player, "noMissionWarning", active)
                end
            end
        end
    end   
    
    function PlayerTracker:setGCITextReports(groupname, active)
        local gr = Group.getByName(groupname)
        if gr and gr:getSize()>0 then 
            local un = gr:getUnit(1)
            if un then
                local player = un:getPlayerName()
                if player then
                    self:setPlayerConfig(player, "gciTextReports", active)
                end
            end
        end
    end

    function PlayerTracker:buyCommand(groupname, itemType)
        local gr = Group.getByName(groupname)
        if gr and gr:getSize()>0 then 
            local un = gr:getUnit(1)
            if un then
                local player = un:getPlayerName()
                local cost = PlayerTracker.cmdShopPrices[itemType]
                local cmdTokens = self.stats[player][PlayerTracker.statTypes.cmd]

                if cmdTokens and cost <= cmdTokens then
                    local canPurchase = true

                    if self.groupTgtMenus[gr:getID()] then
                        missionCommands.removeItemForGroup(gr:getID(), self.groupTgtMenus[gr:getID()])
                        self.groupTgtMenus[gr:getID()] = nil
                    end

                    if itemType == PlayerTracker.cmdShopTypes.smoke then

                        self.groupTgtMenus[gr:getID()] = MenuRegistry.showTargetZoneMenu(gr:getID(), "Smoke Marker target", function(params) 
                            CommandFunctions.smokeTargets(params.zone, 5)
                            trigger.action.outTextForGroup(params.groupid, "Targets marked at "..params.zone.name.." with red smoke", 5)
                        end, 1, 1, nil, nil, true)

                        if self.groupTgtMenus[gr:getID()] then
                            trigger.action.outTextForGroup(gr:getID(), "Select target from radio menu",10)
                        else
                            trigger.action.outTextForGroup(gr:getID(), "No valid targets available",10)
                            canPurchase = false
                        end

                    elseif itemType == PlayerTracker.cmdShopTypes.jtac then

                        self.groupTgtMenus[gr:getID()] = MenuRegistry.showTargetZoneMenu(gr:getID(), "JTAC target", function(params) 

                            CommandFunctions.spawnJtac(params.zone)
                            trigger.action.outTextForGroup(params.groupid, "Reaper orbiting "..params.zone.name,5)

                        end, 1, 1)

                        if self.groupTgtMenus[gr:getID()] then
                            trigger.action.outTextForGroup(gr:getID(), "Select target from radio menu",10)
                        else
                            trigger.action.outTextForGroup(gr:getID(), "No valid targets available",10)
                            canPurchase = false
                        end

                    elseif itemType== PlayerTracker.cmdShopTypes.bribe1 then

                        timer.scheduleFunction(function(params, time)
                            local count = 0
                            for i,v in pairs(ZoneCommand.getAllZones()) do
                                if v.side == 1 and v.distToFront <= 1 then
                                    if math.random()<0.5 then
                                        v:reveal()
                                        DependencyManager.get("ReconManager"):revealEnemyInZone(v, nil, 1, 1)
                                        count = count + 1
                                    end
                                end
                            end
                            if count > 0 then
                                trigger.action.outTextForGroup(params.groupid, "Intercepted enemy communications have revealed information on "..count.." enemy zones",20)
                            else
                                trigger.action.outTextForGroup(params.groupid, "No useful information has been intercepted",20)
                            end
                        end, {groupid=gr:getID()}, timer.getTime()+60)

                        trigger.action.outTextForGroup(gr:getID(), "Attempting to intercept enemy comms...",60)

                    elseif itemType == PlayerTracker.cmdShopTypes.bribe2 then
                        timer.scheduleFunction(function(params, time)
                            local count = 0
                            for i,v in pairs(ZoneCommand.getAllZones()) do
                                if v.side == 1 then
                                    if math.random()<0.5 then
                                        v:reveal()
                                        DependencyManager.get("ReconManager"):revealEnemyInZone(v, nil, 1, 0.5)
                                        count = count + 1
                                    end
                                end
                            end

                            if count > 0 then
                                trigger.action.outTextForGroup(params.groupid, "Bribed officer has shared intel on "..count.." enemy zones",20)
                            else
                                trigger.action.outTextForGroup(params.groupid, "Bribed officer has stopped responding to attempted communications.",20)
                            end
                        end, {groupid=gr:getID()}, timer.getTime()+(60*5))
                        
                        trigger.action.outTextForGroup(gr:getID(), "Bribe has been transfered to enemy officer. Waiting for contact...",20)
                    elseif itemType == PlayerTracker.cmdShopTypes.artillery then
                        self.groupTgtMenus[gr:getID()] = MenuRegistry.showTargetZoneMenu(gr:getID(), "Artillery target", function(params)
                            CommandFunctions.shellZone(params.zone, 50)
                        end, 1, 1)

                        if self.groupTgtMenus[gr:getID()] then
                            trigger.action.outTextForGroup(gr:getID(), "Select target from radio menu",10)
                        else
                            trigger.action.outTextForGroup(gr:getID(), "No valid targets available",10)
                            canPurchase = false
                        end

                    elseif itemType == PlayerTracker.cmdShopTypes.sabotage1 then
                        self.groupTgtMenus[gr:getID()] = MenuRegistry.showTargetZoneMenu(gr:getID(), "Sabotage target", function(params)
                            CommandFunctions.sabotageZone(params.zone)
                        end, 1, 1)

                        if self.groupTgtMenus[gr:getID()] then
                            trigger.action.outTextForGroup(gr:getID(), "Select target from radio menu",10)
                        else
                            trigger.action.outTextForGroup(gr:getID(), "No valid targets available",10)
                            canPurchase = false
                        end
                    end
                    
                    if canPurchase then
                        self.stats[player][PlayerTracker.statTypes.cmd] = self.stats[player][PlayerTracker.statTypes.cmd] - cost
                    end
                else
                    trigger.action.outTextForUnit(un:getID(), "Insufficient CMD to buy selected item", 5)
                end
            end
        end
    end

    function PlayerTracker:showFrequencies(groupname)
        local gr = Group.getByName(groupname)
        if gr then 
            for i,v in pairs(gr:getUnits()) do
                if v.getPlayerName and v:getPlayerName() then
                    local message = RadioFrequencyTracker.getRadioFrequencyMessage(gr:getCoalition())
                    trigger.action.outTextForUnit(v:getID(), message, 20)
                end
            end
        end
    end

    function PlayerTracker:validateLandingMenu(groupname)
        local gr = Group.getByName(groupname)
        if gr then 
            for i,v in pairs(gr:getUnits()) do
                if v.getPlayerName and v:getPlayerName() then
                    self:validateLanding(v, v:getPlayerName(), true)
                end
            end
        end
    end

    function PlayerTracker:showGroupStats(groupname)
        local gr = Group.getByName(groupname)
        if gr then 
            for i,v in pairs(gr:getUnits()) do
                if v.getPlayerName and v:getPlayerName() then
                    local player = v:getPlayerName()
                    local message = '['..player..']\n'
                    
                    local stats = self.stats[player]
                    if stats then
                        local xp = stats[PlayerTracker.statTypes.xp]
                        if xp then
                            local rank, nextRank = self:getRank(xp)
                            
                            message = message ..'\nXP: '..xp

                            if rank then
                                message = message..'\nRank: '..rank.name

                                if rank.cmdChance > 0 then
                                    message = message..'\nCMD rolls per mission: '..rank.cmdTrys
                                    message = message..'\nCMD chance per roll: '..math.floor(rank.cmdChance*100)..'%'
                                end
                            end

                            if nextRank then
                                message = message..'\nXP needed for promotion: '..(nextRank.requiredXP-xp)
                                if rank then
                                    message = message..'\nPromotion rewards:'

                                    if rank.cmdTrys == 0 and nextRank.cmdTrys > 0 then
                                        message = message..'\n  Command and Control unlocked'
                                    end

                                    if nextRank.cmdAward and nextRank.cmdAward>0 then
                                        message = message..'\n  +'..nextRank.cmdAward..' CMD'
                                    end
                                    
                                    if nextRank.cmdTrys > rank.cmdTrys then
                                        message = message..'\n  CMD rolls per mission: +'..(nextRank.cmdTrys-rank.cmdTrys)
                                    end
                                
                                    if nextRank.cmdChance > rank.cmdChance then
                                        message = message..'\n  CMD chance per roll: +'..math.floor((nextRank.cmdChance-rank.cmdChance)*100)..'%'
                                    end

                                    if rank.allowCarrierSupport ~= nextRank.allowCarrierSupport then
                                        message = message..'\n  Carrier support unlocked'
                                    end

                                    if rank.allowCarrierCommand ~= nextRank.allowCarrierCommand then
                                        message = message..'\n  Carrier command unlocked'
                                    end

                                    message = message..'\n\n'
                                end
                            end
                        end

                        local multiplier = self:getPlayerMultiplier(player)
                        if multiplier then
                            message = message..'\nSurvival XP multiplier: '..string.format("%.2f", multiplier)..'x'
                            
                            if stats[PlayerTracker.statTypes.survivalBonus] ~= nil then
                                message = message..' [SECURED]'
                            end
                        end

                        local cmd = stats[PlayerTracker.statTypes.cmd]
                        if cmd then
                            message = message ..'\n\nCMD: '..cmd
                        end
                    end

                    local tstats = self.tempStats[player]
                    if tstats then
                        message = message..'\n'
                        local tempxp =  tstats[PlayerTracker.statTypes.xp]
                        if tempxp and tempxp > 0 then
                            message = message .. '\nUnclaimed XP: '..tempxp
                        end

                        local tempcmd =  tstats[PlayerTracker.statTypes.cmd]
                        if tempcmd and tempcmd > 0 then
                            message = message .. '\nUnclaimed CMD: '..tempcmd
                        end
                    end

                    trigger.action.outTextForUnit(v:getID(), message, 10)
                end
            end
        end
    end

    function PlayerTracker:setPlayerConfig(player, setting, value)
        local cfg = self:getPlayerConfig(player)
        cfg[setting] = value
    end

    function PlayerTracker.callsignToString(callsign)
        return callsign.name..' '..callsign.num1..'-'..callsign.num2
    end

    local function isCallsignTaken(choice, config)
        for i,v in pairs(config) do
            if PlayerTracker.callsignToString(v.gci_callsign) == PlayerTracker.callsignToString(choice) then
                return true
            end
        end
    end

    function PlayerTracker:generateCallsign(forcename)
        local choice = ''
        if forcename then
            choice = { name = forcename, num1=1, num2=1 }
        else
            choice = { name = PlayerTracker.callsigns[math.random(1,#PlayerTracker.callsigns)], num1=1, num2=1 }
            
            if isCallsignTaken(choice, self.config) then
                for i=1,10,1 do
                    choice = { name = PlayerTracker.callsigns[math.random(1,#PlayerTracker.callsigns)], num1=1, num2=1 }
                    if not isCallsignTaken(choice, self.config) then
                        break
                    end
                end
            end
        end 

        while isCallsignTaken(choice, self.config) do
            if choice.num2 < 9 then 
                choice.num2 = choice.num2 + 1 
            elseif choice.num1 < 9 then
                choice.num1 = choice.num1 + 1
                choice.num2 = 1
            else
                break
            end
        end

        return choice
    end

    function PlayerTracker:getPlayerConfig(player)
        if not self.config[player] then
            self.config[player] = {
                noMissionWarning = false,
                gciTextReports = true,
                gci_warning_radius = nil,
                gci_metric = nil,
                gci_callsign = self:generateCallsign()
            }
        end

        return self.config[player]
    end

    function PlayerTracker:periodicSave()
        timer.scheduleFunction(function(param, time)
            param:save()
            return time+60
        end, self, timer.getTime()+60)
    end

    function PlayerTracker:save()
        local tosave = {}
        tosave.stats = self.stats
        tosave.config = self.config
        
        tosave.zones = {}
        tosave.zones.red = {}
        tosave.zones.blue = {}
        tosave.zones.neutral = {}
        for i,v in pairs(ZoneCommand.getAllZones()) do
            if v.side == 1 then
                table.insert(tosave.zones.red,v.name)
            elseif v.side == 2 then
                table.insert(tosave.zones.blue,v.name)
            elseif v.side == 0 then
                table.insert(tosave.zones.neutral,v.name)
            end
        end

        tosave.players = {}
        for i,v in ipairs(coalition.getPlayers(2)) do
            if v and v:isExist() and v.getPlayerName then
                table.insert(tosave.players, {name=v:getPlayerName(), unit=v:getDesc().typeName})
            end
        end

        Utils.saveTable(PlayerTracker.savefile, tosave)
        env.info("PlayerTracker - state saved")
    end

    PlayerTracker.ranks = {}
    PlayerTracker.ranks[1] =  { rank=1,  name='E-1 Airman basic',           requiredXP = 0,        cmdChance = 0,       cmdAward=0,     cmdTrys=0}
    PlayerTracker.ranks[2] =  { rank=2,  name='E-2 Airman',                 requiredXP = 2000,     cmdChance = 0,       cmdAward=0,     cmdTrys=0}
    PlayerTracker.ranks[3] =  { rank=3,  name='E-3 Airman first class',     requiredXP = 4500,     cmdChance = 0,       cmdAward=0,     cmdTrys=0}
    PlayerTracker.ranks[4] =  { rank=4,  name='E-4 Senior airman',          requiredXP = 7700,     cmdChance = 0,       cmdAward=0,     cmdTrys=0}
    PlayerTracker.ranks[5] =  { rank=5,  name='E-5 Staff sergeant',         requiredXP = 11800,    cmdChance = 0.01,    cmdAward=1,     cmdTrys=1}
    PlayerTracker.ranks[6] =  { rank=6,  name='E-6 Technical sergeant',     requiredXP = 17000,    cmdChance = 0.01,    cmdAward=5,     cmdTrys=10}
    PlayerTracker.ranks[7] =  { rank=7,  name='E-7 Master sergeant',        requiredXP = 23500,    cmdChance = 0.03,    cmdAward=5,     cmdTrys=10}
    PlayerTracker.ranks[8] =  { rank=8,  name='E-8 Senior master sergeant', requiredXP = 31500,    cmdChance = 0.06,    cmdAward=10,    cmdTrys=10}
    PlayerTracker.ranks[9] =  { rank=9,  name='E-9 Chief master sergeant',  requiredXP = 42000,    cmdChance = 0.10,    cmdAward=10,    cmdTrys=10}
    PlayerTracker.ranks[10] = { rank=10, name='O-1 Second lieutenant',      requiredXP = 52800,    cmdChance = 0.14,    cmdAward=20,    cmdTrys=15}
    PlayerTracker.ranks[11] = { rank=11, name='O-2 First lieutenant',       requiredXP = 66500,    cmdChance = 0.20,    cmdAward=20,    cmdTrys=15}
    PlayerTracker.ranks[12] = { rank=12, name='O-3 Captain',                requiredXP = 82500,    cmdChance = 0.27,    cmdAward=25,    cmdTrys=15, allowCarrierSupport=true}
    PlayerTracker.ranks[13] = { rank=13, name='O-4 Major',                  requiredXP = 101000,   cmdChance = 0.34,    cmdAward=25,    cmdTrys=20, allowCarrierSupport=true}
    PlayerTracker.ranks[14] = { rank=14, name='O-5 Lieutenant colonel',     requiredXP = 122200,   cmdChance = 0.43,    cmdAward=25,    cmdTrys=20, allowCarrierSupport=true}
    PlayerTracker.ranks[15] = { rank=15, name='O-6 Colonel',                requiredXP = 146300,   cmdChance = 0.52,    cmdAward=30,    cmdTrys=20, allowCarrierSupport=true}
    PlayerTracker.ranks[16] = { rank=16, name='O-7 Brigadier general',      requiredXP = 173500,   cmdChance = 0.63,    cmdAward=35,    cmdTrys=25, allowCarrierSupport=true, allowCarrierCommand=true}
    PlayerTracker.ranks[17] = { rank=17, name='O-8 Major general',          requiredXP = 204000,   cmdChance = 0.74,    cmdAward=40,    cmdTrys=25, allowCarrierSupport=true, allowCarrierCommand=true}
    PlayerTracker.ranks[18] = { rank=18, name='O-9 Lieutenant general',     requiredXP = 238000,   cmdChance = 0.87,    cmdAward=45,    cmdTrys=25, allowCarrierSupport=true, allowCarrierCommand=true}
    PlayerTracker.ranks[19] = { rank=19, name='O-10 General',               requiredXP = 275700,   cmdChance = 0.95,    cmdAward=50,    cmdTrys=30, allowCarrierSupport=true, allowCarrierCommand=true}

    function PlayerTracker:getPlayerRank(playername)
        if self.stats[playername] then
            local xp = self.stats[playername][PlayerTracker.statTypes.xp]
            if xp then
                return self:getRank(xp)
            end
        end
    end

    function PlayerTracker:getPlayerMultiplier(playername)
        if self.playerEarningMultiplier[playername] then
            return self.playerEarningMultiplier[playername].multiplier
        end

        return 1.0
    end

    function PlayerTracker:getPlayerMinutes(playername)
        if self.playerEarningMultiplier[playername] then
            return self.playerEarningMultiplier[playername].minutes
        end

        return 0
    end

    function PlayerTracker.minutesToMultiplier(minutes)
        local multi = 1.0
        if minutes > 10 and minutes <= 60 then
            multi = 1.0 + ((minutes-10)*0.05)
        elseif minutes > 60 then
            multi = 1.0 + (50*0.05) + ((minutes - 60)*0.025)
        end

        return math.min(multi, 5.0)
    end

    function PlayerTracker:getRank(xp)
        local rank = nil
        local nextRank = nil
        for _, rnk in ipairs(PlayerTracker.ranks) do
            if rnk.requiredXP <= xp then
                rank = rnk
            else
                nextRank = rnk
                break
            end
        end

        return rank, nextRank
    end
end

