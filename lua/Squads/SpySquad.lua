



SpySquad = SquadBase:new()

do 
    function SpySquad:new(data)
        local obj = SquadBase:new(data)
		setmetatable(obj, self)
		self.__index = self
		return obj
    end

    function SpySquad:processWorking()
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
                zn:reveal()

                if zn.neighbours then
                    for _,v in pairs(zn.neighbours) do
                        if v.side ~= gr:getCoalition() and v.side ~= 0 then
                            v:reveal()
                            if v:hasUnitWithAttributeOnSide({'Buildings'}, v.side) then
                                local tgt = v:getRandomUnitWithAttributeOnSide({'Buildings'}, v.side)
                                if tgt then
                                    MissionTargetRegistry.addStrikeTarget(tgt, v)
                                end
                            end
                        end
                    end
                end

                env.info('SquadTracker - '..self.name..'('..self.data.type..') infiltrated into '..zn.name)
            else
                env.info('SquadTracker - '..self.name..'('..self.data.type..') not in zone, cant infiltrate')
            end

            self:processExtract()
        end
    end
    
    function SpySquad:isAtTarget()
        local gr = Group.getByName(self.name)
        if not gr then return end
		if gr:getSize()==0 then return end

        local zn = ZoneCommand.getZoneOfPoint(self.position)
        if zn and zn.side ~= gr:getCoalition() and zn.side ~= 0 then
            return true
        end
    end
end

