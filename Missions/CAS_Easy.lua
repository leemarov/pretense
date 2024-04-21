
CAS_Easy = Mission:new()
do
    function CAS_Easy.canCreate()
        return true
    end

    function CAS_Easy:getMissionName()
        return 'CAS'
    end

    function CAS_Easy:generateObjectives()
        self.completionType = Mission.completion_type.all
        local description = ''
        
        local kills = ObjDestroyUnitsWithAttribute:new()
        kills:initialize(self, {
            attr = {'Ground Units'},
            amount = math.random(3,6),
            killed = 0 
        })

        table.insert(self.objectives, kills)
        description = description..'   Destroy '..kills.param.amount..' Ground Units'
        self.description = self.description..description
    end
end

