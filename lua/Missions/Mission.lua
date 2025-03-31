



Mission = {}
do
    Mission.states = {
        new = 'new',                -- mission was just generated and is listed publicly
        preping = 'preping',        -- mission was accepted by a player, was delisted, and player recieved a join code that can be shared
        comencing = 'comencing',    -- a player that is subscribed to the mission has taken off, join code is invalidated
        active = 'active',          -- all players subscribed to the mission have taken off, objective can now be accomplished
        completed = 'completed',    -- mission objective was completed, players need to land to claim rewards
        failed = 'failed'           -- mission lost all players OR mission objective no longer possible to accomplish
    }

    --[[
        new -> preping -> comencing -> active -> completed
         |      |         |           |-> failed
         |      |         |->failed
         |      |->failed
         |->failed
    --]]

    Mission.types = {
        cap_easy = 'cap_easy',          -- fly over zn A-B-A-B-A-B OR destroy few enemy aircraft 
        cap_medium = 'cap_medium',      -- fly over zn A-B-A-B-A-B AND destroy few enemy aircraft -- push list of aircraft within range of target zones
        tarcap = 'tarcap',              -- protect other mission, air kills increase reward
        --tarcap = 'tarcap',            -- update target mission list after all other missions are in

        cas_easy = 'cas_easy',          -- destroy small amount of ground units
        cas_medium = 'cas_medium',      -- destroy large amount of ground units
        cas_hard = 'cas_hard',          -- destroy all defenses at zone A
        bai = 'bai',                    -- destroy any enemy convoy - show "last" location of convoi (BRA or LatLon) update every 30 seconds
        
        sead = 'sead',                  -- destroy any SAM TR or SAM SR at zone A
        dead = 'dead',                  -- destroy all SAM TR or SAM SR, or IR Guided SAM at zone A
        
        strike_veryeasy = 'strike_veryeasy',   -- destroy 1 building
        strike_easy = 'strike_easy',    -- destroy any structure at zone A
        strike_medium = 'strike_medium',-- destroy specific structure at zone A - show LatLon and Alt in mission description
        strike_hard = 'strike_hard',    -- destroy all structures at zone A and turn it neutral
        deep_strike = 'deep_strike',   -- destroy specific structure taken from strike queue - show LatLon and Alt in mission description

        anti_runway = 'anti_runway',  -- drop at least X anti runway bombs on runway zone (if player unit launches correct weapon, track, if agl>10m check if in zone, tally), define list of runway zones somewhere
        
        supply_easy = 'supply_easy',   -- transfer resources to zone A(low supply)
        supply_hard = 'supply_hard',   -- transfer resources to zone A(low supply), high resource number
        escort = 'escort',              -- follow and protect friendly convoy until they get to target OR 10 minutes pass
        csar = 'csar',                  -- extract specific pilot to friendly zone, track friendly pilots ejected
        recon = 'recon',                -- conduct recon
        extraction = 'extraction',  -- extract a deployed squad to friendly zone, generate mission if squad has extractionReady state
        deploy_squad = 'deploy_squad',  -- deploy squad to zone,
        salvage = 'salvage',  -- recover crate to zone,
    }

    Mission.completion_type = {
        any = 'any',
        all = 'all'
    }

    function Mission.getType(misType)
        if misType == Mission.types.cap_easy then
            return CAP_Easy
        elseif misType == Mission.types.cap_medium then
            return CAP_Medium
        elseif misType == Mission.types.cas_easy then
            return CAS_Easy
        elseif misType == Mission.types.cas_medium then
            return CAS_Medium
        elseif misType == Mission.types.cas_hard then
            return CAS_Hard
        elseif misType == Mission.types.sead then
            return SEAD
        elseif misType == Mission.types.supply_easy then
            return Supply_Easy
        elseif misType == Mission.types.supply_hard then
            return Supply_Hard
        elseif misType == Mission.types.strike_veryeasy then
            return Strike_VeryEasy
        elseif misType == Mission.types.strike_easy then
            return Strike_Easy
        elseif misType == Mission.types.strike_medium then
            return Strike_Medium
        elseif misType == Mission.types.strike_hard then
            return Strike_Hard
        elseif misType == Mission.types.deep_strike then
            return Deep_Strike
        elseif misType == Mission.types.dead then
            return DEAD
        elseif misType == Mission.types.escort then
            return Escort
        elseif misType == Mission.types.recon then
            return Recon
        elseif misType == Mission.types.bai then
            return BAI
        elseif misType == Mission.types.anti_runway then
            return Anti_Runway
        elseif misType == Mission.types.csar then
            return CSAR
        elseif misType == Mission.types.extraction then
            return Extraction
        elseif misType == Mission.types.deploy_squad then
            return DeploySquad
        elseif misType == Mission.types.salvage then
            return Salvage
        end
    end

    function Mission:new(id, type, target)
        local expire = math.random(60*15, 60*30)

		local obj = {
            missionID = id,
            type = type,
            name = '',
            description = '',
            failureReason = nil,
            state = Mission.states.new,
            expireTime = expire,
            lastStateTime = timer.getAbsTime(),
            objectives = {},
            completionType = Mission.completion_type.any,
            rewards = {},
            players = {},
            info = {},
            target = target
        }

		setmetatable(obj, self)
		self.__index = self
		
        if obj.getExpireTime then obj.expireTime = obj:getExpireTime() end
        if obj.getMissionName then obj.name = obj:getMissionName() end

        if obj.target and obj.createObjective then 
            obj:createObjective()
        elseif obj.generateObjectives then 
            obj:generateObjectives() 
        end

        if obj.generateRewards then obj:generateRewards() end

		return obj
	end

    function Mission:updateState(newstate)
        env.info('Mission - code'..self.missionID..' updateState state changed from '..self.state..' to '..newstate)
        self.state = newstate
        self.lastStateTime = timer.getAbsTime()
        if self.state == self.states.preping then
            if self.info.targetzone then
                MissionTargetRegistry.addZone(self.info.targetzone.name)
            end
        elseif self.state == self.states.completed or self.state == self.states.failed then
            if self.info.targetzone then
                MissionTargetRegistry.removeZone(self.info.targetzone.name)
            end
        end
    end

    function Mission:pushMessageToPlayer(player, msg, duration)
        if not duration then
            duration = 10
        end

        for name,un in pairs(self.players) do
            if name == player and un and un:isExist() then
                trigger.action.outTextForUnit(un:getID(), msg, duration)
                break
            end
        end
    end

    function Mission:pushMessageToPlayers(msg, duration)
        if not duration then
            duration = 10
        end

        for _,un in pairs(self.players) do
            if un and un:isExist() then
                trigger.action.outTextForUnit(un:getID(), msg, duration)
            end
        end
    end

    function Mission:pushSoundToPlayers(sound)
        for _,un in pairs(self.players) do
            if un and un:isExist() then
                --trigger.action.outSoundForUnit(un:getID(), sound) -- does not work correctly in multiplayer
                trigger.action.outSoundForGroup(un:getGroup():getID(), sound)
            end
        end
    end

    function Mission:removePlayer(player)
        for pl,un in pairs(self.players) do
            if pl == player then
                self.players[pl] = nil
                break
            end
        end
    end

    function Mission:isInstantReward()
        return false
    end

    function Mission:hasPlayers()
        return Utils.getTableSize(self.players) > 0
    end

    function Mission:getPlayerUnit(player)
        return self.players[player]
    end

    function Mission:addPlayer(player, unit)
        self.players[player] = unit
    end

    function Mission:checkFailConditions()
        if self.state == Mission.states.active then return end

        for _,obj in ipairs(self.objectives) do
            local shouldBreak = obj:checkFail()
            
            if shouldBreak then break end
        end
    end

    function Mission:updateObjectives()
        if self.state ~= self.states.active then return end

        for _,obj in ipairs(self.objectives) do
            local shouldBreak = obj:update()

            if obj.isFailed and self.objectiveFailedCallback then self:objectiveFailedCallback(obj) end
            if not obj.isFailed and obj.isComplete and self.objectiveCompletedCallback then self:objectiveCompletedCallback(obj) end

            if shouldBreak then break end
        end
    end

    function Mission:updateIsFailed()
        self:checkFailConditions()

        local allFailed = true
        for _,obj in ipairs(self.objectives) do
            if self.state == Mission.states.new then
                if obj.isFailed then
                    self:updateState(Mission.states.failed)
                    env.info("Mission code"..self.missionID.." objective cancelled:\n"..obj:getText())
                    break
                end
            end

            if self.completionType == Mission.completion_type.all then
                if obj.isFailed then
                    self:updateState(Mission.states.failed)
                    env.info("Mission code"..self.missionID.." (all) objective failed:\n"..obj:getText())
                    break
                end
            end

            if not obj.isFailed then
                allFailed = false
            end
        end

        if self.completionType == Mission.completion_type.any and allFailed then
            self:updateState(Mission.states.failed)
            env.info("Mission code"..self.missionID.." all objectives failed")
        end
    end

    function Mission:updateIsCompleted()
        if self.completionType == self.completion_type.any then
            for _,obj in ipairs(self.objectives) do
                if obj.isComplete then 
                    self:updateState(self.states.completed)
                    env.info("Mission code"..self.missionID.." (any) objective completed:\n"..obj:getText())
                    break
                end
            end
        elseif self.completionType == self.completion_type.all then
            local allComplete = true
            for _,obj in ipairs(self.objectives) do
                if not obj.isComplete then
                    allComplete = false
                    break
                end
            end

            if allComplete then
                self:updateState(self.states.completed)
                env.info("Mission code"..self.missionID.." all objectives complete")
            end
        end
    end

    function Mission:tallyWeapon(weapon)
        for _,obj in ipairs(self.objectives) do
            if not obj.isComplete and not obj.isFailed then
                if obj.type == ObjBombInsideZone:getType() then
                    for i,v in ipairs(obj.param.targetZone:getRunwayZones()) do
                        if Utils.isInZone(weapon, v.name) then
                            if obj.param.dropped < obj.param.max then
                                obj.param.dropped = obj.param.dropped + 1
                                if obj.param.dropped > obj.param.required then
                                    for _,rew in ipairs(self.rewards) do
                                        if obj.param.bonus[rew.type] then
                                            rew.amount = rew.amount +  obj.param.bonus[rew.type]

                                            if rew.type == PlayerTracker.statTypes.xp then
                                                self:pushMessageToPlayers("Bonus: + "..obj.param.bonus[rew.type]..' XP')
                                            end
                                        end
                                    end
                                end
                            end
                            break
                        end
                    end
                end
            end
        end
    end

    function Mission:tallyHit(hit)
        for _,obj in ipairs(self.objectives) do
            if not obj.isComplete and not obj.isFailed then
                if obj.type == ObjHitStructure:getType() then
                    if obj.param.target.name == hit:getName() then
                        obj.param.hit = true
                    end
                elseif obj.type == ObjDestroyUnitsWithAttribute:getType() then
                    for _,a in ipairs(obj.param.attr) do
                        if a == 'Buildings' and ZoneCommand and ZoneCommand.staticRegistry[hit:getName()] then
                            obj.param.hits = obj.param.hits + 1
                            break
                        end
                    end
                elseif obj.type == ObjDestroyUnitsWithAttributeAtZone:getType() then
                    local zn = obj.param.tgtzone
                    if zn then
                        local validzone = false
                        if Utils.isInZone(hit, zn.name) then
                            validzone = true
                        else
                            for nm,_ in pairs(zn.built) do
                                local gr = Group.getByName(nm)
                                if gr then
                                    for _,un in ipairs(gr:getUnits()) do
                                        if un:getID() == hit:getID() then
                                            validzone = true
                                            break
                                        end
                                    end
                                end

                                if validzone then break end
                            end
                        end
                        
                        if validzone then
                            for _,a in ipairs(obj.param.attr) do
                                if a == 'Buildings' and ZoneCommand and ZoneCommand.staticRegistry[hit:getName()] then
                                    obj.param.hits = obj.param.hits + 1
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    function Mission:tallyKill(kill)
        for _,obj in ipairs(self.objectives) do
            if not obj.isComplete and not obj.isFailed then
                if obj.type == ObjDestroyUnitsWithAttribute:getType() then
                    for _,a in ipairs(obj.param.attr) do
                        if kill:hasAttribute(a) then
                            obj.param.killed = obj.param.killed + 1
                            break
                        elseif a == 'Buildings' and ZoneCommand and ZoneCommand.staticRegistry[kill:getName()] then
                            obj.param.killed = obj.param.killed + 1
                            break
                        end
                    end
                elseif obj.type == ObjDestroyStructure:getType() then
                    if obj.param.target.name == kill:getName() then
                        obj.param.killed = true
                    end
                elseif obj.type == ObjDestroyGroup:getType() then
                    if kill.getName then
                        if obj.param.targetUnitNames[kill:getName()] ~= nil then
                            obj.param.targetUnitNames[kill:getName()] = true
                        end
                    end
                elseif obj.type == ObjAirKillBonus:getType() then
                    for _,a in ipairs(obj.param.attr) do
                        if kill:hasAttribute(a) then
                            for _,rew in ipairs(self.rewards) do
                                if obj.param.bonus[rew.type] then
                                    rew.amount = rew.amount +  obj.param.bonus[rew.type]
                                    obj.param.count = obj.param.count + 1
                                    if rew.type == PlayerTracker.statTypes.xp then
                                        self:pushMessageToPlayers("Reward increased: + "..obj.param.bonus[rew.type]..' XP')
                                    end
                                end
                            end
                            break
                        elseif a == 'Buildings' and ZoneCommand and ZoneCommand.staticRegistry[kill:getName()] then
                            for _,rew in ipairs(self.rewards) do
                                if obj.param.bonus[rew.type] then
                                    rew.amount = rew.amount +  obj.param.bonus[rew.type]
                                    obj.param.count = obj.param.count + 1
                                    
                                    if rew.type == PlayerTracker.statTypes.xp then
                                        self:pushMessageToPlayers("Reward increased: + "..obj.param.bonus[rew.type]..' XP')
                                    end
                                end
                            end
                            break
                        end
                    end
                elseif obj.type == ObjDestroyUnitsWithAttributeAtZone:getType() then
                    local zn = obj.param.tgtzone
                    if zn then
                        local validzone = false
                        if Utils.isInZone(kill, zn.name) then
                            validzone = true
                        else
                            for nm,_ in pairs(zn.built) do
                                local gr = Group.getByName(nm)
                                if gr then
                                    for _,un in ipairs(gr:getUnits()) do
                                        if un:getID() == kill:getID() then
                                            validzone = true
                                            break
                                        end
                                    end
                                end

                                if validzone then break end
                            end
                        end
                        
                        if validzone then
                            for _,a in ipairs(obj.param.attr) do
                                if kill:hasAttribute(a) then
                                    obj.param.killed = obj.param.killed + 1
                                    break
                                elseif a == 'Buildings' and ZoneCommand and ZoneCommand.staticRegistry[kill:getName()] then
                                    obj.param.killed = obj.param.killed + 1
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    function Mission:isUnitTypeAllowed(unit)
        return true
    end

    function Mission:tallySupplies(amount, zonename)
        for _,obj in ipairs(self.objectives) do
            if not obj.isComplete and not obj.isFailed then
                if obj.type == ObjSupplyZone:getType() then
                    if obj.param.tgtzone.name == zonename then
                        obj.param.delivered = obj.param.delivered + amount
                    end
                end
            end
        end
    end

    function Mission:tallyLoadPilot(player, pilot)
        for _,obj in ipairs(self.objectives) do
            if not obj.isComplete and not obj.isFailed then
                if obj.type == ObjExtractPilot:getType() then
                    if obj.param.target.name == pilot.name then
                        obj.param.loadedBy = player
                    end
                end
            end
        end
    end

    function Mission:tallyUnloadPilot(player, zonename)
        for _,obj in ipairs(self.objectives) do
            if not obj.isComplete and not obj.isFailed then
                if obj.type == ObjUnloadExtractedPilotOrSquad:getType() then
                    if obj.param.extractObjective.param.loadedBy == player then
                        obj.param.unloadedAt = zonename
                    end
                end
            end
        end
    end

    function Mission:tallyRecon(player, targetzone, analyzezonename)
        for _,obj in ipairs(self.objectives) do
            if not obj.isComplete and not obj.isFailed then
                if obj.type == ObjReconZone:getType() then
                    if obj.param.target.name == targetzone then
                        obj.param.reconData = targetzone
                    end
                end
            end
        end
    end
    
    function Mission:tallyUnpackCrate(player, zonename, cargo)
        for _,obj in ipairs(self.objectives) do
            if not obj.isComplete and not obj.isFailed then
                if obj.type == ObjRecoverCrate:getType() then
                    if cargo.name == obj.param.target.data.name then
                        obj.param.unpackedAt = zonename
                    end
                end
            end
        end
    end

    function Mission:tallyLoadSquad(player, squad)
        for _,obj in ipairs(self.objectives) do
            if not obj.isComplete and not obj.isFailed then
                if obj.type == ObjExtractSquad:getType() then
                    if obj.param.target.name == squad.name then
                        obj.param.loadedBy = player
                    end
                end
            end
        end
    end

    function Mission:tallyUnloadSquad(player, zonename, unloadedType)
        for _,obj in ipairs(self.objectives) do
            if not obj.isComplete and not obj.isFailed then
                if obj.type == ObjUnloadExtractedPilotOrSquad:getType() then
                    if obj.param.extractObjective.param.loadedBy == player and unloadedType == PlayerLogistics.infantryTypes.extractable then
                        obj.param.unloadedAt = zonename
                    end
                elseif obj.type == ObjDeploySquad:getType() then
                    obj.param.unloadedType = unloadedType
                    obj.param.unloadedAt = zonename
                end
            end
        end
    end

    function Mission:getBriefDescription()
        local msg = '~~~~~'..self.name..' ['..self.missionID..']~~~~~\n'..self.description..'\n'

        msg = msg..' Reward:'

        for _,r in ipairs(self.rewards) do
            msg = msg..' ['..r.type..': '..r.amount..']'
        end

        return msg
    end

    function Mission:generateRewards()
        if not self.type then return end
        
        local rewardDef = RewardDefinitions.missions[self.type]
        
        self.rewards = {}
        table.insert(self.rewards, {
            type = PlayerTracker.statTypes.xp,
            amount = math.random(rewardDef.xp.low,rewardDef.xp.high)*50
        })
    end

    function Mission:getDetailedDescription()
        local msg = '['..self.name..']'

        if self.state == Mission.states.comencing or self.state == Mission.states.preping or (not Config.restrictMissionAcceptance) then
            msg = msg..'\nJoin code ['..self.missionID..']'
        end

        msg = msg..'\nReward:'

        for _,r in ipairs(self.rewards) do
            msg = msg..' ['..r.type..': '..r.amount..']'
        end
        msg = msg..'\n'

        if #self.objectives>1 then
            msg = msg..'\nObjectives: '
            if self.completionType == Mission.completion_type.all then
                msg = msg..'(Complete ALL)\n'
            elseif self.completionType == Mission.completion_type.any then
                msg = msg..'(Complete ONE)\n'
            end
        elseif #self.objectives==1 then
            msg = msg..'\nObjective: \n'
        end

        for i,v in ipairs(self.objectives) do
            local obj = v:getText()
            if v.isComplete then 
                obj = '[✓]'..obj
            elseif v.isFailed then
                obj = '[X]'..obj
            else
                obj = '[ ]'..obj 
            end

            msg = msg..'\n'..obj..'\n'
        end

        msg = msg..'\nPlayers:'
        for i,_ in pairs(self.players) do
            msg = msg..'\n  '..i
        end

        return msg
    end
end

