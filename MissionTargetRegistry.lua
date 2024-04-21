
MissionTargetRegistry = {}
do
    MissionTargetRegistry.playerTargetZones = {}

    function MissionTargetRegistry.addZone(zone)
        MissionTargetRegistry.playerTargetZones[zone] = true
    end

    function MissionTargetRegistry.removeZone(zone)
        MissionTargetRegistry.playerTargetZones[zone] = nil
    end

    function MissionTargetRegistry.isZoneTargeted(zone)
        return MissionTargetRegistry.playerTargetZones[zone] ~= nil
    end

    MissionTargetRegistry.baiTargets = {}

    function MissionTargetRegistry.addBaiTarget(target)
        MissionTargetRegistry.baiTargets[target.name] = target
        env.info('MissionTargetRegistry - bai target added '..target.name)
    end

    function MissionTargetRegistry.baiTargetsAvailable(coalition)
        local targets = {}
        for i,v in pairs(MissionTargetRegistry.baiTargets) do
            if v.product.side == coalition then
                local tgt = Group.getByName(v.name)

                if not tgt or not tgt:isExist() or tgt:getSize()==0 then
                    MissionTargetRegistry.removeBaiTarget(v)
                elseif not v.state or v.state ~= 'enroute' then
                    MissionTargetRegistry.removeBaiTarget(v)
                else
                    table.insert(targets, v)
                end
            end
        end

        return #targets > 0
    end

    function MissionTargetRegistry.getRandomBaiTarget(coalition)
        local targets = {}
        for i,v in pairs(MissionTargetRegistry.baiTargets) do
            if v.product.side == coalition then
                local tgt = Group.getByName(v.name)

                if not tgt or not tgt:isExist() or tgt:getSize()==0 then
                    MissionTargetRegistry.removeBaiTarget(v)
                elseif not v.state or v.state ~= 'enroute' then
                    MissionTargetRegistry.removeBaiTarget(v)
                else
                    table.insert(targets, v)
                end
            end
        end

        if #targets == 0 then return end

        local dice = math.random(1,#targets)
        
        return targets[dice]
    end

    function MissionTargetRegistry.removeBaiTarget(target)
        MissionTargetRegistry.baiTargets[target.name] = nil
        env.info('MissionTargetRegistry - bai target removed '..target.name)
    end

    MissionTargetRegistry.strikeTargetExpireTime = 60*60
    MissionTargetRegistry.strikeTargets = {}

    function MissionTargetRegistry.addStrikeTarget(target, zone)
        MissionTargetRegistry.strikeTargets[target.name] = {data=target, zone=zone, addedTime = timer.getAbsTime()}
        env.info('MissionTargetRegistry - strike target added '..target.name)
    end

    function MissionTargetRegistry.strikeTargetsAvailable(coalition, isDeep)
        for i,v in pairs(MissionTargetRegistry.strikeTargets) do
            if v.data.side == coalition then
                local tgt = StaticObject.getByName(v.data.name)
                if not tgt then tgt = Group.getByName(v.data.name) end

                if not tgt or not tgt:isExist() then
                    MissionTargetRegistry.removeStrikeTarget(v)
                elseif timer.getAbsTime() - v.addedTime > MissionTargetRegistry.strikeTargetExpireTime then
                    MissionTargetRegistry.removeStrikeTarget(v)
                elseif not isDeep or v.zone.distToFront >= 2 then
                    return true
                end
            end
        end

        return false
    end

    function MissionTargetRegistry.getRandomStrikeTarget(coalition, isDeep)
        local targets = {}
        for i,v in pairs(MissionTargetRegistry.strikeTargets) do
            if v.data.side == coalition then
                local tgt = StaticObject.getByName(v.data.name)
                if not tgt then tgt = Group.getByName(v.data.name) end

                if not tgt or not tgt:isExist() then
                    MissionTargetRegistry.removeStrikeTarget(v)
                elseif timer.getAbsTime() - v.addedTime > MissionTargetRegistry.strikeTargetExpireTime then
                    MissionTargetRegistry.removeStrikeTarget(v)
                elseif not isDeep or v.zone.distToFront >= 2 then
                    table.insert(targets, v)
                end
            end
        end

        if #targets == 0 then return end

        local dice = math.random(1,#targets)

        return targets[dice]
    end

    function MissionTargetRegistry.getAllStrikeTargets(coalition)
        local targets = {}
        for i,v in pairs(MissionTargetRegistry.strikeTargets) do
            if v.data.side == coalition then
                local tgt = StaticObject.getByName(v.data.name)
                if not tgt then tgt = Group.getByName(v.data.name) end

                if not tgt or not tgt:isExist() then
                    MissionTargetRegistry.removeStrikeTarget(v)
                elseif timer.getAbsTime() - v.addedTime > MissionTargetRegistry.strikeTargetExpireTime then
                    MissionTargetRegistry.removeStrikeTarget(v)
                else
                    table.insert(targets, v)
                end
            end
        end

        return targets
    end

    function MissionTargetRegistry.removeStrikeTarget(target)
        MissionTargetRegistry.strikeTargets[target.data.name] = nil
        env.info('MissionTargetRegistry - strike target removed '..target.data.name)
    end

    MissionTargetRegistry.extractableSquads = {}

    function MissionTargetRegistry.addSquad(squad)
        MissionTargetRegistry.extractableSquads[squad.name] = squad
        env.info('MissionTargetRegistry - squad added '..squad.name)
    end

    function MissionTargetRegistry.squadsReadyToExtract(onside)
        for i,v in pairs(MissionTargetRegistry.extractableSquads) do
            local gr = Group.getByName(i)
            if gr and gr:isExist() and gr:getSize() > 0 and gr:getCoalition() == onside then
                return true
            end
        end

        return false
    end

    function MissionTargetRegistry.getRandomSquad(onside)
        local targets = {}
        for i,v in pairs(MissionTargetRegistry.extractableSquads) do
            local gr = Group.getByName(i)
            if gr and gr:isExist() and gr:getSize() > 0 and gr:getCoalition() == onside then
                table.insert(targets, v)
            end
        end

        if #targets == 0 then return end

        local dice = math.random(1,#targets)

        return targets[dice]
    end

    function MissionTargetRegistry.removeSquad(squad)
        MissionTargetRegistry.extractableSquads[squad.name] = nil
        env.info('MissionTargetRegistry - squad removed '..squad.name)
    end

    MissionTargetRegistry.extractablePilots = {}

    function MissionTargetRegistry.addPilot(pilot)
        MissionTargetRegistry.extractablePilots[pilot.name] = pilot
        env.info('MissionTargetRegistry - pilot added '..pilot.name)
    end

    function MissionTargetRegistry.pilotsAvailableToExtract()
        for i,v in pairs(MissionTargetRegistry.extractablePilots) do
            if v.pilot:isExist() and v.pilot:getSize() > 0 and v.remainingTime > 30*60 then
                return true
            end
        end

        return false
    end

    function MissionTargetRegistry.getRandomPilot()
        local targets = {}
        for i,v in pairs(MissionTargetRegistry.extractablePilots) do
            if v.pilot:isExist() and v.pilot:getSize() > 0 and v.remainingTime > 30*60 then
                table.insert(targets, v)
            end
        end

        if #targets == 0 then return end

        local dice = math.random(1,#targets)

        return targets[dice]
    end

    function MissionTargetRegistry.removePilot(pilot)
        MissionTargetRegistry.extractablePilots[pilot.name] = nil
        env.info('MissionTargetRegistry - pilot removed '..pilot.name)
    end
end

