



SquadBase = {}

do
    function SquadBase:new(data)
        local obj = data or {}
		setmetatable(obj, self)
		self.__index = self
		return obj
    end

    function SquadBase.create(data)
        env.info('squadbase - '..data.data.type)
        if data.data.type == PlayerLogistics.infantryTypes.engineer then
            return EngineerSquad:new(data)
        elseif data.data.type == PlayerLogistics.infantryTypes.ambush then
            return AmbushSquad:new(data)
        elseif data.data.type == PlayerLogistics.infantryTypes.assault then
            return AssaultSquad:new(data)
        elseif data.data.type == PlayerLogistics.infantryTypes.capture then
            return CaptureSquad:new(data)
        elseif data.data.type == PlayerLogistics.infantryTypes.manpads then
            return ManpadsSquad:new(data)
        elseif data.data.type == PlayerLogistics.infantryTypes.rapier then
            return RapierSquad:new(data)
        elseif data.data.type == PlayerLogistics.infantryTypes.sabotage then
            return SabotageSquad:new(data)
        elseif data.data.type == PlayerLogistics.infantryTypes.spy then
            return SpySquad:new(data)
        end
    end

    function SquadBase:startProcess()
        local gr = Group.getByName(self.name)
        if not gr then return true end
		if gr:getSize()==0 then
			gr:destroy()
			return true
		end

        self.position = gr:getUnit(1):getPoint()
        self.remainingStateTime = self.remainingStateTime - 10
    end

    function SquadBase:process()
        local failed = self:startProcess()
        if failed then return true end

        if self.state == 'working' then
            failed = self:processWorking()
            if failed then return true end
        else
            failed = self:processCommon()
            if failed then return true end
        end
    end

    function SquadBase:processCommon()
        local gr = Group.getByName(self.name)
        if not gr then return true end
		if gr:getSize()==0 then 
			gr:destroy()
			return true
		end

        if self.state == 'deployed' then
            self.deployPos = gr:getUnit(1):getPoint()

            if self:isAtTarget() then
                env.info('SquadTracker - '..self.name..'('..self.data.type..') started working for '..self.data.jobtime..' seconds')
                self.state = 'working'
                self.remainingStateTime = self.data.jobtime
                DependencyManager.get("SquadTracker"):playSound(self, 'working')
            else
                local tgzone = DependencyManager.get("SquadTracker"):getTarget(self)
                if tgzone then
                    env.info('SquadTracker - '..self.name..'('..self.data.type..') infiltrating to '..tgzone.name)
                    self.state = 'infil'
                    self.remainingStateTime = SquadTracker.infilTime
                    TaskExtensions.sendToPoint(gr, tgzone.zone.point)
                else
                    env.info('SquadTracker - '..self.name..'('..self.data.type..') extracting')
                    TaskExtensions.stopGroup(gr)

                    local z = ZoneCommand.getZoneOfPoint(gr:getUnit(1):getPoint())
                    if not z then FARPCommand.getFARPOfPoint(gr:getUnit(1):getPoint()) end

                    if z and z.side == gr:getCoalition() then
                        z:addResource(200)
                        local dpl = DependencyManager.get("PlayerLogistics")
                        dpl.humanResource.current = dpl.humanResource.current + gr:getSize()
                        gr:destroy()
                        MissionTargetRegistry.removeSquad(self)
                        return true
                    else
                        self.state = 'extractReady'
                        self.remainingStateTime = self.data.extracttime
                        self.redeploy = true
                        MissionTargetRegistry.addSquad(self)
                        DependencyManager.get("SquadTracker"):playSound(self, 'extracting')
                    end
                end
            end
        elseif self.state == 'infil' then
            if self:isAtTarget() then
                env.info('SquadTracker - '..self.name..'('..self.data.type..') infiltrated and started working for '..self.data.jobtime..' seconds')
                TaskExtensions.stopGroup(gr)
                self.state = 'working'
                self.remainingStateTime = self.data.jobtime
            elseif self.remainingStateTime <= (SquadTracker.infilTime/2) and not self.repathAttempted then
                local tgzone = DependencyManager.get("SquadTracker"):getTarget(self)
                if tgzone then
                    env.info('SquadTracker - '..self.name..'('..self.data.type..') took too long to infil, repathing')
                    TaskExtensions.sendToPoint(gr, tgzone.zone.point)
                end
                self.repathAttempted = true
            elseif self.remainingStateTime <= 0 then
                env.info('SquadTracker - '..self.name..'('..self.data.type..') exfiltrating, took too long to infil')
                if not self.deployPos then self.deployPos = self.position end
                TaskExtensions.sendToPoint(gr, self.deployPos)
                self.state = 'exfil'
                self.remainingStateTime = SquadTracker.exfilTime
            end
        elseif self.state == 'exfil' then
            if not self.deployPos then self.deployPos = self.position end
            local dist = mist.utils.get2DDist(self.position, self.deployPos)
            if dist < 50 or self.remainingStateTime <=0 then
                env.info('SquadTracker - '..self.name..'('..self.data.type..') extracting after reached deployPos or ran out of time, waiting for '..self.data.extracttime..' seconds for extract')
                TaskExtensions.stopGroup(gr)
                
                local z = ZoneCommand.getZoneOfPoint(gr:getUnit(1):getPoint())
                if not z then FARPCommand.getFARPOfPoint(gr:getUnit(1):getPoint()) end
                
                if z and z.side == gr:getCoalition() then
                    z:addResource(200)
                    local dpl = DependencyManager.get("PlayerLogistics")
                    dpl.humanResource.current = dpl.humanResource.current + gr:getSize()
                    gr:destroy()
                    MissionTargetRegistry.removeSquad(self)
                    return true
                else
                    self.state = 'extractReady'
                    self.remainingStateTime = self.data.extracttime
                    MissionTargetRegistry.addSquad(self)
                    DependencyManager.get("SquadTracker"):playSound(self, 'extracting')
                end
            end
        elseif self.state == 'extractReady' then
            if self.remainingStateTime <= 0 then
                env.info('SquadTracker - '..self.name..'('..self.data.type..') extract time elapsed, group MIA')
                self.state = 'mia'
                self.remainingStateTime = 0
			    gr:destroy()
                MissionTargetRegistry.removeSquad(self)
                return true
            end

            if not self.lastMarkerDeployedTime then
                self.lastMarkerDeployedTime = timer.getAbsTime() - (10*60)
            end

            if timer.getAbsTime() - self.lastMarkerDeployedTime > (5*60) then
                if gr:getSize()>0 then
                    local unPos = gr:getUnit(1):getPoint()
                    local p = Utils.getPointOnSurface(unPos)
                    p.x = p.x + math.random(-5,5)
                    p.z = p.z + math.random(-5,5)
		            trigger.action.smoke(p, trigger.smokeColor.Blue)
                    self.lastMarkerDeployedTime = timer.getAbsTime()
                end
            end
        end
    end

    function SquadBase:processExtract()
        local gr = Group.getByName(self.name)
        if not gr then return end
		if gr:getSize()==0 then return end

        env.info('SquadTracker - '..self.name..'('..self.data.type..') exfiltrating')
        if self.deployPos and gr and gr:isExist() and gr:getSize()>0 then TaskExtensions.sendToPoint(gr, self.deployPos) end
        self.state = 'exfil'
        self.remainingStateTime = SquadTracker.exfilTime
        DependencyManager.get("SquadTracker"):playSound(self, 'missioncomplete')
    end

    function SquadBase:isAtTarget()
        local gr = Group.getByName(self.name)
        if not gr then return end
		if gr:getSize()==0 then return end

        return true
    end
end

