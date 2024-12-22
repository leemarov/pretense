
AIBase = {}

do
    function AIBase:new(side, createMissions)
        local obj = {}
        obj.side = side
        obj.createMissions = createMissions
        setmetatable(obj, self)
		self.__index = self
        
        obj:createState()
        return obj
    end

    function AIBase:makeDecissions()
    end

    function AIBase:serializeState()
    end

    function AIBase:restoreState(state)
    end

    function AIBase:createState()
    end
end

