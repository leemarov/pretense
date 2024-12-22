
ManpadsSquad = SquadBase:new()

do 
    function ManpadsSquad:new(data)
        local obj = SquadBase:new(data)
		setmetatable(obj, self)
		self.__index = self
		return obj
    end

    function ManpadsSquad:processWorking()
        local gr = Group.getByName(self.name)
        if not gr then return true end
		if gr:getSize()==0 then 
			gr:destroy()
			return true
		end

        if self.remainingStateTime <=0 then
            env.info('SquadTracker - '..self.name..'('..self.data.type..') job complete, heading to extract')

            self:processExtract()
        end
    end
end

