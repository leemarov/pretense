
DEAD = Mission:new()
do
    function DEAD.canCreate()
        for _,zone in pairs(ZoneCommand.getAllZones()) do
            if zone.side == 1 and zone.distToFront and zone.distToFront <=1 and zone:hasUnitWithAttributeOnSide({"Air Defence"}, 1, 4) then
                if not MissionTargetRegistry.isZoneTargeted(zone.name) then
                    return true
                end
            end
        end
    end

    function DEAD:getMissionName()
        return 'DEAD'
    end

    function DEAD:generateObjectives()
        self.completionType = Mission.completion_type.all
        local description = ''
        local viableZones = {}
        for _,zone in pairs(ZoneCommand.getAllZones()) do
            if zone.side == 1 and zone.distToFront <=1 and zone:hasUnitWithAttributeOnSide({"Air Defence"}, 1, 4) then
                if not MissionTargetRegistry.isZoneTargeted(zone.name) then
                    table.insert(viableZones, zone)
                end
            end
        end
        
        if #viableZones > 0 then
            local choice = math.random(1,#viableZones)
            local zn = viableZones[choice]
            
            local kill = ObjDestroyUnitsWithAttributeAtZone:new()
            kill:initialize(self, {
                attr = {"Air Defence"},
                amount = 1,
                killed = 0,
                tgtzone = zn
            })
            table.insert(self.objectives, kill)

            local clear = ObjClearZoneOfUnitsWithAttribute:new()
            clear:initialize(self, {
                attr = {"Air Defence"},
                tgtzone = zn
            })
            table.insert(self.objectives, clear)

            description = description..'   Clear '..zn.name..' of any Air Defenses'
            self.info = {
                targetzone = zn
            }
        end
        self.description = self.description..description
    end
end

