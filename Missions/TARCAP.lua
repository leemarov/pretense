
TARCAP = Mission:new()
do
    TARCAP.relevantMissions = {
        Mission.types.cas_hard,
        Mission.types.dead,
        Mission.types.sead,
        Mission.types.strike_easy,
        Mission.types.strike_hard
    }

    function TARCAP:new(id, type, activeMissions)
        self = Mission.new(self, id, type)
        self:generateObjectivesOverload(activeMissions)
		return self
	end

    function TARCAP.canCreate(activeMissions)
        for _,mis in pairs(activeMissions) do
            for _,tp in ipairs(TARCAP.relevantMissions) do
                if mis.type == tp then return true end
            end
        end
    end

    function TARCAP:getMissionName()
        return 'TARCAP'
    end

    function TARCAP:isUnitTypeAllowed(unit)
        return unit:hasAttribute('Planes')
    end

    function TARCAP:generateObjectivesOverload(activeMissions)
        self.completionType = Mission.completion_type.any
        local description = ''
        local viableMissions = {}
        for _,mis in pairs(activeMissions) do
            for _,tp in ipairs(TARCAP.relevantMissions) do
                if mis.type == tp then
                    table.insert(viableMissions, mis)
                    break
                end
            end
        end
        
        if #viableMissions >= 1 then
            local choice = math.random(1,#viableMissions)
            local mis = viableMissions[choice]

            local protect = ObjProtectMission:new()
            protect:initialize(self, {
                mis = mis
            })

            table.insert(self.objectives, protect)
            description = description..'   Prevent enemy aircraft from interfering with friendly '..mis:getMissionName()..' mission'
            if mis.info and mis.info.targetzone then
                description = description..' at '..mis.info.targetzone.name
            end

            local rewardDef = RewardDefinitions.missions[self.type]

            local kills = ObjAirKillBonus:new()
            kills:initialize(self, {
                attr = {'Planes'},
                bonus = {
                    [PlayerTracker.statTypes.xp] = rewardDef.xp.boost
                },
                count = 0,
                linkedObjectives = {protect}
            })
    
            table.insert(self.objectives, kills)
            
            description = description..'\n   Aircraft kills increase reward'
        end

        self.description = self.description..description
    end
end

