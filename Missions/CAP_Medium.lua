
CAP_Medium = Mission:new()
do
    function CAP_Medium.canCreate()
        local zoneNum = 0
        for _,zone in pairs(ZoneCommand.getAllZones()) do
            if zone.side == 2 and zone.distToFront == 0 then 
                zoneNum = zoneNum + 1
            end

            if zoneNum >= 2 then return true end
        end
    end

    function CAP_Medium:getMissionName()
        return 'CAP'
    end

    function CAP_Medium:isUnitTypeAllowed(unit)
        return unit:hasAttribute('Planes')
    end

    function CAP_Medium:createObjective()
        self.completionType = Mission.completion_type.all
        local description = ''
        
        local zn1 = ZoneCommand.getZoneByName(self.target[1])
        local zn2 = ZoneCommand.getZoneByName(self.target[2])

        local patrol1 = ObjPlayerCloseToZone:new()
        patrol1:initialize(self, {
            target = zn1,
            range = 20000,
            amount = 10*60,
            maxAmount = 10*60,
            lastUpdate = 0
        })

        table.insert(self.objectives, patrol1)

        local patrol2 = ObjPlayerCloseToZone:new()
        patrol2:initialize(self, {
            target = zn2,
            range = 20000,
            amount = 10*60,
            maxAmount = 10*60,
            lastUpdate = 0
        })

        table.insert(self.objectives, patrol2)
        description = description..'   Patrol airspace near '..zn1.name..' and '..zn2.name..'\n'

        local rewardDef = RewardDefinitions.missions[self.type]

        local kills = ObjAirKillBonus:new()
        kills:initialize(self, {
            attr = {'Planes', 'Helicopters'},
            bonus = {
                [PlayerTracker.statTypes.xp] = rewardDef.xp.boost
            },
            count = 0,
            linkedObjectives = {patrol1, patrol2}
        })

        table.insert(self.objectives, kills)
        description = description..'   Aircraft kills increase reward'

        self.description = self.description..description
    end

    function CAP_Medium:generateObjectives()
        self.completionType = Mission.completion_type.all
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
            table.remove(viableZones,choice1)
            local choice2 = math.random(1,#viableZones)
            local zn2 = viableZones[choice2]

            local patrol1 = ObjPlayerCloseToZone:new()
            patrol1:initialize(self, {
                target = zn1,
                range = 20000,
                amount = 10*60,
                maxAmount = 10*60,
                lastUpdate = 0
            })

            table.insert(self.objectives, patrol1)

            local patrol2 = ObjPlayerCloseToZone:new()
            patrol2:initialize(self, {
                target = zn2,
                range = 20000,
                amount = 10*60,
                maxAmount = 10*60,
                lastUpdate = 0
            })

            table.insert(self.objectives, patrol2)
            description = description..'   Patrol airspace near '..zn1.name..' and '..zn2.name..'\n'

            local rewardDef = RewardDefinitions.missions[self.type]

            local kills = ObjAirKillBonus:new()
            kills:initialize(self, {
                attr = {'Planes', 'Helicopters'},
                bonus = {
                    [PlayerTracker.statTypes.xp] = rewardDef.xp.boost
                },
                count = 0,
                linkedObjectives = {patrol1, patrol2}
            })

            table.insert(self.objectives, kills)
            description = description..'   Aircraft kills increase reward'
        end

        self.description = self.description..description
    end
end

