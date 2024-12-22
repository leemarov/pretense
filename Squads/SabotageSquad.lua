
SabotageSquad = SquadBase:new()

do 
    function SabotageSquad:new(data)
        local obj = SquadBase:new(data)
		setmetatable(obj, self)
		self.__index = self
		return obj
    end

    function SabotageSquad:processWorking()
        local gr = Group.getByName(self.name)
        if not gr then return true end
		if gr:getSize()==0 then 
			gr:destroy()
			return true
		end

        if self.remainingStateTime <=0 then
            env.info('SquadTracker - '..self.name..'('..self.data.type..') job complete, heading to extract')

            local zn = ZoneCommand.getZoneOfPoint(self.position)
            if zn and zn.side ~= gr:getCoalition() and zn.side ~= 0 then
                zn:sabotage(1500, self.position)
                env.info('SquadTracker - '..self.name..'('..self.data.type..') sabotaged '..zn.name)
            else
                env.info('SquadTracker - '..self.name..'('..self.data.type..') not in zone, cant sabotage')
            end

            self:processExtract()
        end
    end
    
    function SabotageSquad:isAtTarget()
        local gr = Group.getByName(self.name)
        if not gr then return end
		if gr:getSize()==0 then return end

        local zn = ZoneCommand.getZoneOfPoint(self.position)
        if zn and zn.side ~= gr:getCoalition() and zn.side ~= 0 then
            return true
        end
    end
end

