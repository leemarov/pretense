
Recon = Mission:new()
do
    function Recon.canCreate()
        local zoneNum = 0
        for _,zone in pairs(ZoneCommand.getAllZones()) do
            if zone.side == 1 and zone.distToFront == 0 and zone.revealTime == 0 then 
                return true
            end
        end
    end

    function Recon:getMissionName()
        return 'Recon'
    end

    function Recon:isUnitTypeAllowed(unit)
        return true
    end

    function Recon:isInstantReward()
        return true
    end

    function Recon:generateObjectives()
        self.completionType = Mission.completion_type.any
        local description = ''
        local viableZones = {}
        local secondaryViableZones = {}
        for _,zone in pairs(ZoneCommand.getAllZones()) do
            if zone.side == 1 and zone.distToFront == 0 and zone.revealTime == 0 then
                table.insert(viableZones, zone)
            end
        end

        if #viableZones > 0 then
            local choice1 = math.random(1,#viableZones)
            local zn1 = viableZones[choice1]

            local recon = ObjReconZone:new()
            recon:initialize(self, {
                target = zn1,
                failZones = {
                    [1] = {zn1}
                }
            })

            table.insert(self.objectives, recon)
            description = description..'   Observe enemies at '..zn1.name..'\n'
        end

        self.description = self.description..description
    end
end

