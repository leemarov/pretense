



AssaultSquad = SquadBase:new()

do 
    function AssaultSquad:new(data)
        local obj = SquadBase:new(data)
		setmetatable(obj, self)
		self.__index = self
		return obj
    end

    function AssaultSquad:processWorking()
        local gr = Group.getByName(self.name)
        if not gr then return true end
		if gr:getSize()==0 then 
			gr:destroy()
			return true
		end

        if self.remainingStateTime <=0 then
            env.info('SquadTracker - '..self.name..'('..self.data.type..') job complete, heading to extract')
            self:processExtract()
        else
            if not self.assault then self.assault = { target = nil, effort = 0, extract = false, ammo = Utils.getAmmoCount(gr)} end

            if not self.assault.target or not self.assault.target:isExist() or self.assault.target:getSize() == 0 or self.assault.effort <=0 then
                local tz, dist = ZoneCommand.getClosestZoneToPoint(self.position, Utils.getEnemy(gr:getCoalition()))
                if tz and dist < 5000+tz.zone.radius then
                    local targets = {}
                    for i,v in pairs(tz.built) do
                        if v.type == ZoneCommand.productTypes.defense and v.side ~= gr:getCoalition() then 
                            local tgr = Group.getByName(v.name)
                            if tgr and tgr:isExist() and tgr:getSize()>0 then
                                local tdist = mist.utils.get2DDist(self.position, tgr:getUnit(1):getPoint())
                                table.insert(targets, {group = tgr, dist=tdist})
                            end
                        end
                    end

                    if #targets>0 then
                        table.sort(targets, function(a,b) return a.dist<b.dist end)
                        local tgt = targets[1].group

                        TaskExtensions.assaultGroup(gr, tgt)
                        self.assault.target = tgt
                        self.assault.effort = 60
                        DependencyManager.get("SquadTracker"):playSound(self, 'engaging')
                        env.info('SquadTracker - '..self.name..'('..self.data.type..') picked target '..tgt:getName())
                    else
                        self.assault.extract = true
                        env.info('SquadTracker - '..self.name..'('..self.data.type..') no target, exfil')
                    end
                else
                    self.assault.extract = true
                    env.info('SquadTracker - '..self.name..'('..self.data.type..') no zone, exfil')
                end
            else
                if self.assault.effort > 0 then
                    self.assault.effort = self.assault.effort - 1
                end

                if self.assault.effort < 30 then
                    if Utils.getAmmoCount(gr) == self.assault.ammo then
                        self.assault.effort = 0
                    end
                end

                self.assault.ammo = Utils.getAmmoCount(gr)
            end

            if Utils.getAmmoCount(gr)==0 then
                self.assault.extract = true
            end

            if self.assault.extract then
                env.info('SquadTracker - '..self.name..'('..self.data.type..') exfiltrating')
                if self.deployPos and gr and gr:isExist() and gr:getSize()>0 then TaskExtensions.sendToPoint(gr, self.deployPos) end
                self.state = 'exfil'
                self.remainingStateTime = SquadTracker.exfilTime
            end
        end
    end
end

