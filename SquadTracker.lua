
SquadTracker = {}
do
    SquadTracker.infilTime = 10*60
    SquadTracker.exfilTime = 10*60

	function SquadTracker:new()
		local obj = {}
		obj.activeInfantrySquads = {}
		setmetatable(obj, self)
		self.__index = self
		
		obj:start()
        
		DependencyManager.register("SquadTracker", obj)
		return obj
	end

    SquadTracker.infantryCallsigns = {
        adjectives = {"Sapphire", "Emerald", "Whisper", "Vortex", "Blaze", "Nova", "Silent", "Zephyr", "Radiant", "Shadow", "Lively", "Dynamo", "Dusk", "Rapid", "Stellar", "Tundra", "Obsidian", "Cascade", "Zenith", "Solar"},
        nouns = {"Journey", "Quasar", "Galaxy", "Moonbeam", "Comet", "Starling", "Serenade", "Raven", "Breeze", "Echo", "Avalanche", "Harmony", "Stardust", "Horizon", "Firefly", "Solstice", "Labyrinth", "Whisper", "Cosmos", "Mystique"}
    }

    function SquadTracker:generateCallsign()
        local adjective = self.infantryCallsigns.adjectives[math.random(1,#self.infantryCallsigns.adjectives)]
        local noun = self.infantryCallsigns.nouns[math.random(1,#self.infantryCallsigns.nouns)]

        local callsign = adjective..noun

        if self.activeInfantrySquads[callsign] then
            for i=1,1000,1 do
                local try = callsign..'-'..i
                if not self.activeInfantrySquads[try] then
                    callsign = try
                    break
                end
            end
        end

        if not self.activeInfantrySquads[callsign] then
            return callsign
        end
    end

    function SquadTracker:restoreInfantry(save)

        Spawner.createObject(save.name, save.data.name, save.position, save.side, 20, 30,{
            [land.SurfaceType.LAND] = true, 
            [land.SurfaceType.ROAD] = true,
            [land.SurfaceType.RUNWAY] = true,
        })

        self.activeInfantrySquads[save.name] = SquadBase.create({
            name = save.name, 
            position = save.position, 
            deployPos = save.deployPos,
            targetPos = save.targetPos,
            state = save.state, 
            remainingStateTime=save.remainingStateTime, 
            shouldDiscover = save.discovered,
            discovered = save.discovered,
            data = save.data
        })

        if save.state == "extractReady" then
            MissionTargetRegistry.addSquad(self.activeInfantrySquads[save.name])
        end

        timer.scheduleFunction(function(param, time)
            if param.squad.state == "infil" then
                local tgzone = param.context:getTarget(param.squad)
                if tgzone then
                    local gr = Group.getByName(param.squad.name)
                    if gr then TaskExtensions.sendToPoint(gr, tgzone.zone.point) end
                end
            elseif param.state == "exfil" then
                local gr = Group.getByName(param.squad.name)
                if gr then TaskExtensions.sendToPoint(gr, param.squad.deployPos) end
            end
        end, {squad = self.activeInfantrySquads[save.name], context = self}, timer.getTime()+2)
        
        env.info('SquadTracker - '..save.name..'('..save.data.type..') restored')
    end

    function SquadTracker:spawnInfantry(infantryData, position)
        local callsign = self:generateCallsign()
        if callsign then
            Spawner.createObject(callsign, infantryData.name, position, infantryData.side, 20, 30,{
                [land.SurfaceType.LAND] = true, 
                [land.SurfaceType.ROAD] = true,
                [land.SurfaceType.RUNWAY] = true,
            })

            self:registerInfantry(infantryData, callsign, position)
        end
    end

    function SquadTracker:registerInfantry(infantryData, groupname, position)
        self.activeInfantrySquads[groupname] = SquadBase.create({name = groupname, deployPos = position, position = position, state = "deployed", remainingStateTime=0, data = infantryData})
        
        env.info('SquadTracker - '..groupname..'('..infantryData.type..') deployed')
    end
	
    function SquadTracker:start()
		if not ZoneCommand then return end

        timer.scheduleFunction(function(param, time)
			local self = param.context
			
			for i,v in pairs(self.activeInfantrySquads) do
                local remove = self:processInfantrySquad(v)
                if remove then
                    MissionTargetRegistry.removeSquad(v)
                    self.activeInfantrySquads[v.name] = nil
                end
			end
			
			return time+10
		end, {context = self}, timer.getTime()+1)
    end

    function SquadTracker:removeSquad(squadname)
        local squad = self.activeInfantrySquads[squadname]
        if squad then
            MissionTargetRegistry.removeSquad(squad)
            squad.state = 'extracted'
            squad.remainingStateTime = 0
            self.activeInfantrySquads[squadname] = nil
        end
    end

    function SquadTracker:getClosestExtractableSquad(sourcePoint, onside)
        local minDist = 99999999
        local squad = nil

        for i,v in pairs(self.activeInfantrySquads) do
            if v.state == 'extractReady' or v.state == "exfil" and v.data.side == onside then
                local gr = Group.getByName(v.name)
                if gr and gr:getSize()>0 then
                    local dist = mist.utils.get2DDist(sourcePoint, gr:getUnit(1):getPoint())
                    if dist<minDist then
                        minDist = dist
                        squad = v
                    end
                end
            end
        end

        if squad then
            local gr = Group.getByName(squad.name)
            if gr and gr:getSize()>0 then
                for i,v in ipairs(gr:getUnits()) do
                    local dist = mist.utils.get2DDist(sourcePoint, v:getPoint())
                    if dist < minDist then minDist = dist end
                end
            end
            return squad, minDist
        end
    end
    
    function SquadTracker:getTarget(squad)
        local gr = Group.getByName(squad.name)
        if not gr then return end
		if gr:getSize()==0 then return end

        return self:getTargetZone(squad.position, squad.data.type, gr:getCoalition())
    end

    function SquadTracker:getTargetZone(position, type, squadside)
        if type == PlayerLogistics.infantryTypes.capture then
            local zn, dist = ZoneCommand.getClosestZoneToPoint(position, 0)
            if zn and dist < 2000+zn.zone.radius then
                return zn
            end
        elseif type == PlayerLogistics.infantryTypes.engineer then
            local zn, dist = ZoneCommand.getClosestZoneToPoint(position, squadside)
            if zn and dist < 2000+zn.zone.radius then
                return zn
            end
        elseif type == PlayerLogistics.infantryTypes.sabotage then
            local zn, dist = ZoneCommand.getClosestZoneToPoint(position, Utils.getEnemy(squadside))
            if zn and dist < 2000+zn.zone.radius then
                return zn
            end
        elseif type == PlayerLogistics.infantryTypes.spy then
            local zn, dist = ZoneCommand.getClosestZoneToPoint(position, Utils.getEnemy(squadside))
            if zn and dist < 2000+zn.zone.radius then
                return zn
            end
        elseif type == PlayerLogistics.infantryTypes.ambush then
        elseif type == PlayerLogistics.infantryTypes.assault then
        elseif type == PlayerLogistics.infantryTypes.manpads then
        elseif type == PlayerLogistics.infantryTypes.rapier then
        end
    end

    function SquadTracker:playSound(squad, state)
        local pos = { 
            x = squad.position.x,
            y = squad.position.y + 200,
            z = squad.position.z,
        }

        local type = squad.data.type
        TransmissionManager.queueTransmission('squads.'..type..'.'..state, TransmissionManager.radios.infantry, pos)
    end

    function SquadTracker:processInfantrySquad(squad)
        return squad:process()
    end
end

