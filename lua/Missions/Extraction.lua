



Extraction = Mission:new()
do
    function Extraction.canCreate()
        return MissionTargetRegistry.squadsReadyToExtract(2)
    end

    function Extraction:getMissionName()
        return 'Extraction'
    end

    function Extraction:isInstantReward()
        return true
    end
    
    function Extraction:isUnitTypeAllowed(unit)
        if PlayerLogistics then
            local unitType = unit:getDesc()['typeName']
            return PlayerLogistics.allowedTypes[unitType] and PlayerLogistics.allowedTypes[unitType].personCapacity
        end
    end

    function Extraction:generateObjectives()
        env.info("ERROR - Can't create Extraction on demand")
    end

    function Extraction:generateObjectives()
        self.completionType = Mission.completion_type.all
        local description = ''
        
        if MissionTargetRegistry.squadsReadyToExtract(2) then
            local tgt = MissionTargetRegistry.getRandomSquad(2)
            if tgt then
                local extract = ObjExtractSquad:new()
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

                local infName = PlayerLogistics.getInfantryName(tgt.data.type)

                
                local nearzone = ''
                local gr = Group.getByName(tgt.name)
                if gr and gr:isExist() and gr:getSize()>0 then
                    local un = gr:getUnit(1)
                    local closest = ZoneCommand.getClosestZoneToPoint(un:getPoint())
                    if closest then
                        nearzone = ' near '..closest.name..''
                    end
                    --local mgrs = coord.LLtoMGRS(coord.LOtoLL(un:getPoint()))
                    --local grid = mist.tostringMGRS(mgrs, 2):gsub(' ','')
                    --description = description..' ['..grid..']'
                end

                description = description..'   Extract '..infName..nearzone..' to a friendly zone'
            end
        end
        self.description = self.description..description
    end
end

