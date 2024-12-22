
EngineerSquad = SquadBase:new()

do 
    function EngineerSquad:new(data)
        local obj = SquadBase:new(data)
		setmetatable(obj, self)
		self.__index = self
		return obj
    end

    function EngineerSquad:processWorking()
        local gr = Group.getByName(self.name)
        if not gr then return true end
		if gr:getSize()==0 then 
			gr:destroy()
			return true
		end

        if self.remainingStateTime <=0 then
            env.info('SquadTracker - '..self.name..'('..self.data.type..') job complete, heading to extract')
            
            local zn = ZoneCommand.getZoneOfPoint(self.position)
            if zn and zn.side == gr:getCoalition() then
                zn:boostProduction(3000)
                self.state = "complete"
                self.remainingStateTime = 0
                gr:destroy()
                
                local pl = DependencyManager.get("PlayerLogistics")
                pl.humanResource.current = pl.humanResource.current + self.data.size

                env.info('SquadTracker - '..self.name..'('..self.data.type..') no extraction required, deleting')
                return true
            else
                env.info('SquadTracker - '..self.name..'('..self.data.type..') not in zone, cant boost')
            end

            self:processExtract()
        end
    end

    function EngineerSquad:isAtTarget()
        local gr = Group.getByName(self.name)
        if not gr then return end
		if gr:getSize()==0 then return end

        local zn = ZoneCommand.getZoneOfPoint(self.position)
        if zn and zn.side == gr:getCoalition() then
            return true
        end
    end
end

