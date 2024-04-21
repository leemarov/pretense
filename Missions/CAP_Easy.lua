
CAP_Easy = Mission:new()
do
    function CAP_Easy.canCreate()
        local zoneNum = 0
        for _,zone in pairs(ZoneCommand.getAllZones()) do
            if zone.side == 2 and zone.distToFront == 0 then 
                zoneNum = zoneNum + 1
            end

            if zoneNum >= 2 then return true end
        end
    end

    function CAP_Easy:getMissionName()
        return 'CAP'
    end

    function CAP_Easy:isUnitTypeAllowed(unit)
        return unit:hasAttribute('Planes')
    end

    function CAP_Easy:generateObjectives()
        self.completionType = Mission.completion_type.any
        local description = ''
        local viableZones = {}
        for _,zone in pairs(ZoneCommand.getAllZones()) do
            if zone.side == 2 and zone.distToFront == 0 then
                table.insert(viableZones, zone)
            end
        end
        
        if #viableZones >= 2 then
            local choice1 = math.random(1,#viableZones)
            local zn1 = viableZones[choice1]

            local patrol1 = ObjPlayerCloseToZone:new()
            patrol1:initialize(self, {
                target = zn1,
                range = 20000,
                amount = 15*60,
                maxAmount = 15*60,
                lastUpdate = 0
            })

            table.insert(self.objectives, patrol1)
            description = description..'   Patrol airspace near '..zn1.name..'\n   OR\n'
        end

        local kills = ObjDestroyUnitsWithAttribute:new()
        kills:initialize(self, {
            attr = {'Planes', 'Helicopters'},
            amount = math.random(2,4),
            killed = 0 
        })

        table.insert(self.objectives, kills)
        description = description..'   Kill '..kills.param.amount..' aircraft'
        self.description = self.description..description
    end
end

