
Objective = {}

do
    Objective.types = {
        fly_to_zone_seq = 'fly_to_zone_seq',            -- any of playerlist inside [zone] in sequence
        recon_zone = 'recon_zone',                           -- within X km, facing Y angle +-, % of enemy units in LOS progress faster
        destroy_attr = 'destroy_attr',                  -- any of playerlist kill event on target with any of [attribute]
        destroy_attr_at_zone = 'destroy_attr_at_zone',  -- any of playerlist kill event on target at [zone] with any of [attribute]
        clear_attr_at_zone = 'clear_attr_at_zone',      -- [zone] does not have any units with [attribute]
        destroy_structure = 'destroy_structure',        -- [structure] is killed by any player (getDesc().displayName or getDesc().typeName:gsub('%.','') must match)
        destroy_group = 'destroy_group',                -- [group] is missing from mission AND any player killed unit from group at least once
        supply = 'supply',                              -- any of playerlist unload [amount] supply at [zone]
        extract_pilot = 'extract_pilot',                  -- players extracted specific ejected pilots
        extract_squad = 'extract_squad',                  -- players extracted specific squad
        unloaded_pilot_or_squad = 'unloaded_pilot_or_squad', -- unloaded pilot or squad
        deploy_squad = 'deploy_squad',                  --deploy squad at zone
        escort = 'escort',                              -- escort convoy
        protect = 'protect',                            -- protect other mission
        air_kill_bonus = 'air_kill_bonus',               -- award bonus for air kills
        bomb_in_zone = 'bomb_in_zone',                     -- bombs tallied inside zone
        player_close_to_zone = 'player_close_to_zone' -- player is close to point
    }

    function Objective:new(type)

		local obj = {
            type = type,
            mission = nil,
            param = {},
            isComplete = false,
            isFailed = false
        }

		setmetatable(obj, self)
		self.__index = self

		return obj
    end

    function Objective:initialize(mission, param)
        self.mission = mission
        self:validateParameters(param)
        self.param = param
    end

    function Objective:getType()
        return self.type
    end

    function Objective:validateParameters(param)
        for i,v in pairs(self.requiredParams) do
            if v and param[i] == nil then
                env.error("Objective - missing parameter: "..i..' in '..self:getType(), true)
            end
        end
    end

    -- virtual
    Objective.requiredParams = {}

    function Objective:getText()
        env.error("Objective - getText not implemented")
        return "NOT IMPLEMENTED"
    end

    function Objective:update()
        env.error("Objective - update not implemented")
    end

    function Objective:checkFail()
        env.error("Objective - checkFail not implemented")
    end
    --end virtual
end

