



CSARTracker = {}
do
	function CSARTracker:new()
		local obj = {}
		obj.activePilots = {}
		setmetatable(obj, self)
		self.__index = self
		
		obj:start()

		DependencyManager.register("CSARTracker", obj)
		return obj
	end

    function CSARTracker:start()
		if not ZoneCommand then return end

        local ev = {}
		ev.context = self
		function ev:onEvent(event)
			if event.id == world.event.S_EVENT_LANDING_AFTER_EJECTION then
                if event.initiator and event.initiator:isExist() then
                    if event.initiator:getCoalition() == 2 then
                        local z = ZoneCommand.getZoneOfPoint(event.initiator:getPoint())
                        if not z then
                            local name = self.context:generateCallsign()
                            if name then
                                local pos = {
                                    x = event.initiator:getPoint().x,
                                    y = event.initiator:getPoint().z
                                }

                                if pos.x ~= 0 and pos.y ~= 0 then
                                    local srfType = land.getSurfaceType(pos)
                                    if srfType ~= land.SurfaceType.WATER and srfType ~= land.SurfaceType.SHALLOW_WATER then
                                        local gr = Spawner.createPilot(name, pos)
                                        self.context:addPilot(name, gr)
                                        TransmissionManager.pilotCallout(TransmissionManager.radios.guard, event.initiator:getPoint())
                                    end
                                end
                            end
                        end
                    end

                    event.initiator:destroy()
                end
			end
		end
		
		world.addEventHandler(ev)

        timer.scheduleFunction(function(param, time)
            for i,v in pairs(param.context.activePilots) do
                v.remainingTime = v.remainingTime - 10
                if not v.pilot:isExist() or v.remainingTime <=0 then
                    param.context:removePilot(i)
                end
            end
			
			return time+10
		end, {context = self}, timer.getTime()+1)
    end

    function CSARTracker:markPilot(data)
        local pilot = data.pilot
        if pilot:isExist() then
            local pos = pilot:getUnit(1):getPoint()
            local p = Utils.getPointOnSurface(pos)
            p.x = p.x + math.random(-5,5)
            p.z = p.z + math.random(-5,5)
            trigger.action.smoke(p, trigger.smokeColor.Green)
        end
    end

    function CSARTracker:flarePilot(data)
        local pilot = data.pilot
        if pilot:isExist() then
            local pos = pilot:getUnit(1):getPoint()
            local p = Utils.getPointOnSurface(pos)
            trigger.action.signalFlare(p, trigger.flareColor.Green, math.random(1,360))
        end
    end

    function CSARTracker:removePilot(name)
        local data = self.activePilots[name]
        if data.pilot and data.pilot:isExist() then data.pilot:destroy() end

        MissionTargetRegistry.removePilot(data)
        self.activePilots[name] = nil
    end

    function CSARTracker:addPilot(name, pilot)
        self.activePilots[name] = {pilot = pilot, name = name, remainingTime = 45*60}
        MissionTargetRegistry.addPilot(self.activePilots[name])
    end

    function CSARTracker:restorePilot(save)         
        local gr = Spawner.createPilot(save.name, save.pos)
        
        self.activePilots[save.name] = {
            pilot = gr, 
            name = save.name, 
            remainingTime = save.remainingTime
        }
        
        MissionTargetRegistry.addPilot(self.activePilots[save.name])       
    end

    function CSARTracker:getClosestPilot(toPosition)
        local minDist = 99999999
        local data = nil
        local name = nil

        for i,v in pairs(self.activePilots) do
            if v.pilot:isExist() and v.pilot:getSize()>0 and v.pilot:getUnit(1):isExist() and v.remainingTime > 0 then
                local dist = mist.utils.get2DDist(toPosition, v.pilot:getUnit(1):getPoint())
                if dist<minDist then
                    minDist = dist
                    data = v
                end
            else
                self:removePilot(i)
            end
        end

        if data then
            return {name=data.name, pilot=data.pilot, remainingTime = data.remainingTime, dist=minDist}
        end
    end

    CSARTracker.pilotCallsigns = {
        adjectives = {"Agile", "Voyager", "Sleek", "Fierce", "Nimble", "Daring", "Swift", "Fearless", "Dynamic", "Rapid", "Brave", "Stealthy", "Eagle", "Thunder", "Roaring", "Jade", "Lion", "Crimson", "Mighty", "Phoenix"},
        nouns = {"Pancake", "Noodle", "Potato", "Banana", "Wombat", "Penguin", "Llama", "Cabbage", "Kangaroo", "Giraffe", "Walrus", "Pickle", "Donut", "Hamburger", "Toaster", "Teapot", "Unicorn", "Rainbow", "Dragon", "Sasquatch"}
    }

    function CSARTracker:generateCallsign()
        local adjective = self.pilotCallsigns.adjectives[math.random(1,#self.pilotCallsigns.adjectives)]
        local noun = self.pilotCallsigns.nouns[math.random(1,#self.pilotCallsigns.nouns)]

        local callsign = adjective..noun

        if self.activePilots[callsign] then
            for i=1,1000,1 do
                local try = callsign..'-'..i
                if not self.activePilots[try] then
                    callsign = try
                    break
                end
            end
        end

        if not self.activePilots[callsign] then
            return callsign
        end
    end
end

