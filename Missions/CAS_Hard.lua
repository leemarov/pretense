
CAS_Hard = Mission:new()
do
    function CAS_Hard.canCreate()
        for _,zone in pairs(ZoneCommand.getAllZones()) do
            if zone.side == 1 and zone.distToFront and zone.distToFront <=1 and zone:hasUnitWithAttributeOnSide({"Ground Units"}, 1, 6) then
                if not MissionTargetRegistry.isZoneTargeted(zone.name) then
                    return true
                end
            end
        end
    end

    function CAS_Hard:getMissionName()
        return 'CAS'
    end

    function CAS_Hard:generateObjectives()
        self.completionType = Mission.completion_type.all
        local description = ''
        local viableZones = {}
        for _,zone in pairs(ZoneCommand.getAllZones()) do
            if zone.side == 1 and zone.distToFront == 0 and zone:hasUnitWithAttributeOnSide({"Ground Units"}, 1, 6) then
                if not MissionTargetRegistry.isZoneTargeted(zone.name) then
                    table.insert(viableZones, zone)
                end
            end
        end

        if #viableZones == 0 then
            for _,zone in pairs(ZoneCommand.getAllZones()) do
                if zone.side == 1 and zone.distToFront == 1 and zone:hasUnitWithAttributeOnSide({"Ground Units"}, 1, 6) then
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
                attr = {"Ground Units"},
                amount = 1,
                killed = 0,
                tgtzone = zn
            })
            table.insert(self.objectives, kill)

            local clear = ObjClearZoneOfUnitsWithAttribute:new()
            clear:initialize(self, {
                attr = {"Ground Units"},
                tgtzone = zn
            })
            table.insert(self.objectives, clear)

            description = description..'   Clear '..zn.name..' of ground units'
            self.info = {
                targetzone = zn
            }
        end
        self.description = self.description..description
    end
end

