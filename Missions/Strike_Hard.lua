
Strike_Hard = Mission:new()
do
    function Strike_Hard.canCreate()
        for _,zone in pairs(ZoneCommand.getAllZones()) do
            if zone.side == 1 and zone.distToFront and zone.distToFront <=1 and zone:hasUnitWithAttributeOnSide({"Buildings"}, 1, 3) then
                if not MissionTargetRegistry.isZoneTargeted(zone.name) then
                    return true
                end
            end
        end
    end

    function Strike_Hard:getMissionName()
        return 'Strike'
    end

    function Strike_Hard:generateObjectives()
        self.completionType = Mission.completion_type.all
        local description = ''
        local viableZones = {}
        for _,zone in pairs(ZoneCommand.getAllZones()) do
            if zone.side == 1 and zone.distToFront == 0 and zone:hasUnitWithAttributeOnSide({"Buildings"}, 1, 3) then
                if not MissionTargetRegistry.isZoneTargeted(zone.name) then
                    table.insert(viableZones, zone)
                end
            end
        end

        if #viableZones == 0 then
            for _,zone in pairs(ZoneCommand.getAllZones()) do
                if zone.side == 1 and zone.distToFront == 1 and zone:hasUnitWithAttributeOnSide({"Buildings"}, 1, 3) then
                    if not MissionTargetRegistry.isZoneTargeted(zone.name) then
                        table.insert(viableZones, zone)
                    end
                end
            end
        end
        
        if #viableZones > 0 then
            local choice = math.random(1,#viableZones)
            local zn = viableZones[choice]
            
            local kill = ObjDestroyUnitsWithAttributeAtZone:new()
            kill:initialize(self, { 
                attr = {"Buildings"},
                amount = 1,
                killed = 0,
                tgtzone = zn
            })

            table.insert(self.objectives, kill)

            local clear = ObjClearZoneOfUnitsWithAttribute:new()
            clear:initialize(self, {
                attr = {"Buildings"},
                tgtzone = zn
            })
            table.insert(self.objectives, clear)

            description = description..'   Destroy every structure at '..zn.name
            self.info = {
                targetzone = zn
            }
        end
        self.description = self.description..description
    end
end

