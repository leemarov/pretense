
Supply_Easy = Mission:new()
do
    function Supply_Easy.canCreate()
        for _,zone in pairs(ZoneCommand.getAllZones()) do
            if zone.side == 2 and zone.distToFront and zone.distToFront <=1 and zone:criticalOnSupplies() then
                return true
            end
        end
    end

    function Supply_Easy:getMissionName()
        return "Supply delivery"
    end

    function Supply_Easy:isInstantReward()
        return true
    end

    function Supply_Easy:isUnitTypeAllowed(unit)
        if PlayerLogistics then
            local unitType = unit:getDesc()['typeName']
            return PlayerLogistics.allowedTypes[unitType] and PlayerLogistics.allowedTypes[unitType].supplies
        end
    end

    function Supply_Easy:createObjective()
        self.completionType = Mission.completion_type.all
        local description = ''
        
        local zn = ZoneCommand.getZoneByName(self.target)
        
        local deliver = ObjSupplyZone:new()
        deliver:initialize(self, {
            amount = math.random(2,6)*250,
            delivered = 0,
            tgtzone = zn
        })
        
        table.insert(self.objectives, deliver)
        description = description..'   Deliver '..deliver.param.amount..' of supplies to '..zn.name
        self.info = {
            targetzone = zn
        }

        self.description = self.description..description
    end

    function Supply_Easy:generateObjectives()
        self.completionType = Mission.completion_type.all
        local description = ''

        local viableZones = {}
        for _,zone in pairs(ZoneCommand.getAllZones()) do
            if zone.side == 2 and zone.distToFront <=1 and zone:criticalOnSupplies() then
                table.insert(viableZones, zone)
            end
        end
        
        if #viableZones > 0 then
            local choice = math.random(1,#viableZones)
            local zn = viableZones[choice]
            
            local deliver = ObjSupplyZone:new()
            deliver:initialize(self, {
                amount = math.random(2,6)*250,
                delivered = 0,
                tgtzone = zn
            })
            
            table.insert(self.objectives, deliver)
            description = description..'   Deliver '..deliver.param.amount..' of supplies to '..zn.name
            self.info = {
                targetzone = zn
            }
        end

        self.description = self.description..description
    end
end

