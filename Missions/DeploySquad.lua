
DeploySquad = Mission:new()
do
    function DeploySquad.canCreate()
        for _,zone in pairs(ZoneCommand.getAllZones()) do
            if zone.distToFront and zone.distToFront == 0 then
                if not MissionTargetRegistry.isZoneTargeted(zone.name) then
                    return true
                end
            end
        end
    end

    function DeploySquad:getMissionName()
        return 'Deploy infantry'
    end

    function DeploySquad:isInstantReward()
        local friendlyDeployments = {
            [PlayerLogistics.infantryTypes.engineer] = true,
        }

        if self.objectives and self.objectives[1] then
            local sqType = self.objectives[1].param.squadType
            if friendlyDeployments[sqType] then
                return true
            end
        end

        return false
    end
    
    function DeploySquad:isUnitTypeAllowed(unit)
        if PlayerLogistics then
            local unitType = unit:getDesc()['typeName']
            return PlayerLogistics.allowedTypes[unitType] and PlayerLogistics.allowedTypes[unitType].personCapacity
        end
    end

    function DeploySquad:createObjective()
        self.completionType = Mission.completion_type.all
        local description = ''


        local tgt = ZoneCommand.getZoneByName(self.target)
        if tgt then
            local squadType = nil

            if tgt.side == 0 then
                squadType = PlayerLogistics.infantryTypes.capture
            elseif tgt.side == 1 then
                if math.random()>0.5 then
                    squadType = PlayerLogistics.infantryTypes.sabotage
                else
                    squadType = PlayerLogistics.infantryTypes.spy
                end
            elseif tgt.side == 2 then
                squadType = PlayerLogistics.infantryTypes.engineer
            end

            local deploy = ObjDeploySquad:new()
            deploy:initialize(self, {
                squadType = squadType,
                targetZone = tgt,
                requiredZoneSide = tgt.side,
                unloadedType = nil,
                unloadedAt = nil
            })
            table.insert(self.objectives, deploy)

            local infName = PlayerLogistics.getInfantryName(squadType)

            description = description..'   Deploy '..infName..' to '..tgt.name
            
            self.info = {
                targetzone = tgt
            }
        end
        self.description = self.description..description
    end

    function DeploySquad:generateObjectives()
        self.completionType = Mission.completion_type.all
        local description = ''

        local viableZones = {}
        for _,zone in pairs(ZoneCommand.getAllZones()) do
            if zone.distToFront and zone.distToFront == 0 then
                if not MissionTargetRegistry.isZoneTargeted(zone.name) then
                    table.insert(viableZones, zone)
                end
            end
        end

        if #viableZones > 0 then
            local tgt = viableZones[math.random(1,#viableZones)]
            if tgt then
                local squadType = nil

                if tgt.side == 0 then
                    squadType = PlayerLogistics.infantryTypes.capture
                elseif tgt.side == 1 then
                    if math.random()>0.5 then
                        squadType = PlayerLogistics.infantryTypes.sabotage
                    else
                        squadType = PlayerLogistics.infantryTypes.spy
                    end
                elseif tgt.side == 2 then
                    squadType = PlayerLogistics.infantryTypes.engineer
                end

                local deploy = ObjDeploySquad:new()
                deploy:initialize(self, {
                    squadType = squadType,
                    targetZone = tgt,
                    requiredZoneSide = tgt.side,
                    unloadedType = nil,
                    unloadedAt = nil
                })
                table.insert(self.objectives, deploy)

                local infName = PlayerLogistics.getInfantryName(squadType)

                description = description..'   Deploy '..infName..' to '..tgt.name
                
                self.info = {
                    targetzone = tgt
                }
            end
        end
        self.description = self.description..description
    end
end

