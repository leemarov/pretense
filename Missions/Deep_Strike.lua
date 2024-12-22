
Deep_Strike = Mission:new()
do
    function Deep_Strike.canCreate()
        return MissionTargetRegistry.strikeTargetsAvailable(1, true)
    end

    function Deep_Strike:getMissionName()
        return 'Deep Strike'
    end

    function Deep_Strike:createObjective()
        env.info("ERROR - Can't create Deep_Strike on demand")
    end

    function Deep_Strike:generateObjectives()
        self.completionType = Mission.completion_type.all
        local description = ''
        local viableZones = {}
       
        local tgt = MissionTargetRegistry.getRandomStrikeTarget(1, true)
        
        if tgt then
            local chozenTarget = tgt.data
            local zn = tgt.zone

            local hit = ObjHitStructure:new()
            hit:initialize(self, {
                target = chozenTarget,
                tgtzone = zn,
                hit = false
            })

            table.insert(self.objectives, hit)

            local kill = ObjDestroyStructure:new()
            kill:initialize(self, {
                target = chozenTarget,
                tgtzone = zn
            })

            table.insert(self.objectives, kill)
            description = description..'   Destroy '..chozenTarget.display..' at '..zn.name
            self.info = {
                targetzone = zn
            }

        end
        self.description = self.description..description
    end
end

