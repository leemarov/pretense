



Strike_VeryEasy = Mission:new()
do
    function Strike_VeryEasy.canCreate()
        return true
    end

    function Strike_VeryEasy:getMissionName()
        return 'Strike'
    end

    function Strike_VeryEasy:createObjective()
        env.info("ERROR - Can't create Strike_VeryEasy on demand")
    end

    function Strike_VeryEasy:generateObjectives()
        self.completionType = Mission.completion_type.all
        local description = ''
        
        local kills = ObjDestroyUnitsWithAttribute:new()
        kills:initialize(self, {
            attr = {'Buildings'},
            amount = 1,
            killed = 0,
            hits = 0
        })

        table.insert(self.objectives, kills)
        description = description..'   Destroy '..kills.param.amount..' building'
        self.description = self.description..description
    end
end

