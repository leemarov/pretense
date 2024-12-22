
CSAR = Mission:new()
do
    function CSAR.canCreate()
        return MissionTargetRegistry.pilotsAvailableToExtract()
    end

    function CSAR:getMissionName()
        return 'CSAR'
    end

    function CSAR:isInstantReward()
        return true
    end

    function CSAR:isUnitTypeAllowed(unit)
        if PlayerLogistics then
            local unitType = unit:getDesc()['typeName']
            return PlayerLogistics.allowedTypes[unitType] and PlayerLogistics.allowedTypes[unitType].personCapacity and PlayerLogistics.allowedTypes[unitType].personCapacity > 0
        end
    end

    function CSAR:createObjective()
        env.info("ERROR - Can't create CSAR on demand")
    end

    function CSAR:generateObjectives()
        self.completionType = Mission.completion_type.all
        local description = ''
        
        if MissionTargetRegistry.pilotsAvailableToExtract() then
            local tgt = MissionTargetRegistry.getRandomPilot()
            
            local extract = ObjExtractPilot:new()
            extract:initialize(self, {
                target = tgt,
                loadedBy = nil,
                lastUpdate = timer.getAbsTime()
            })
            table.insert(self.objectives, extract)

            local unload = ObjUnloadExtractedPilotOrSquad:new()
            unload:initialize(self, {
                extractObjective = extract
            })
            table.insert(self.objectives, unload)

            local nearzone = ''
            local closest = ZoneCommand.getClosestZoneToPoint(tgt.pilot:getUnit(1):getPoint())
            if closest then
                nearzone = ' near '..closest.name..''
            end

            description = description..'   Rescue '..tgt.name..nearzone..' and deliver them to a friendly zone'
            --local mgrs = coord.LLtoMGRS(coord.LOtoLL(tgt.pilot:getUnit(1):getPoint()))
            --local grid = mist.tostringMGRS(mgrs, 2):gsub(' ','')
            --description = description..' ['..grid..']'
        end
        self.description = self.description..description
    end
end

