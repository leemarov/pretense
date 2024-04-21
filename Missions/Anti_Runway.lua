
Anti_Runway = Mission:new()
do
    function Anti_Runway.canCreate()
        for _,zone in pairs(ZoneCommand.getAllZones()) do
            if zone.side == 1 and zone.distToFront <=2 and zone:hasRunway() then
                    return true
            end
        end
    end

    function Anti_Runway:getMissionName()
        return 'Runway Attack'
    end

    function Anti_Runway:generateObjectives()
        self.completionType = Mission.completion_type.all
        local description = ''
        local viableZones = {}
       
        local tgts = {}
        for _,zone in pairs(ZoneCommand.getAllZones()) do
            if zone.side == 1 and zone.distToFront <=2 and zone:hasRunway() then
                if not MissionTargetRegistry.isZoneTargeted(zone.name) then
                    table.insert(tgts, zone)
                end
            end
        end
        
        if #tgts > 0 then
            local tgt = tgts[math.random(1,#tgts)]

            local rewardDef = RewardDefinitions.missions[self.type]

            local bomb = ObjBombInsideZone:new()
            bomb:initialize(self,{
                targetZone = tgt,
                max = 20,
                required = 5,
                dropped = 0,
                isFinishStarted = false,
                bonus = {
                    [PlayerTracker.statTypes.xp] = rewardDef.xp.boost
                }
            })

            table.insert(self.objectives, bomb)
            description = description..'   Bomb runway at '..bomb.param.targetZone.name
        end
        self.description = self.description..description
    end
end

