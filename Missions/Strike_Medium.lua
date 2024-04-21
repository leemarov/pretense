
Strike_Medium = Mission:new()
do
    function Strike_Medium.canCreate()
        return MissionTargetRegistry.strikeTargetsAvailable(1, false)
    end

    function Strike_Medium:getMissionName()
        return 'Strike'
    end

    function Strike_Medium:generateObjectives()
        self.completionType = Mission.completion_type.all
        local description = ''
        local viableZones = {}
       
        local tgt = MissionTargetRegistry.getRandomStrikeTarget(1, false)
        
        if tgt then
            local chozenTarget = tgt.data
            local zn = tgt.zone

            local kill = ObjDestroyStructure:new()
            kill:initialize(self, {
                target = chozenTarget,
                tgtzone = zn,
                killed = false
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

