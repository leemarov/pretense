
SquadTracker = {}
do
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

        self.activeInfantrySquads[save.name] = {
            name = save.name, 
            position = save.position, 
            state = save.state, 
            remainingStateTime=save.remainingStateTime, 
            shouldDiscover = save.discovered,
            discovered = save.discovered,
            data = save.data
        }

        if save.state == "extractReady" then
            MissionTargetRegistry.addSquad(self.activeInfantrySquads[save.name])
        end
        
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
        self.activeInfantrySquads[groupname] = {name = groupname, position = position, state = "deployed", remainingStateTime=0, data = infantryData}
        
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
            if v.state == 'extractReady' and v.data.side == onside then
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
            return squad, minDist
        end
    end

    --[[
        infantry states:
            deployed - just spawned not processed yet
            working - started main activity, last until jobtime elapses
            extractReady - job completed waiting for extract, lasts until extracttime elapses
            mia - missing in action, extracttime elapsed without extraction, group is forever lost
            complete - mission complete no extraction necessary
            extracted - squad was loaded into a player helicopter
    ]] 
    function SquadTracker:processInfantrySquad(squad)
        local gr = Group.getByName(squad.name)
        if not gr then return true end
		if gr:getSize()==0 then 
			gr:destroy()
			return true
		end

        squad.remainingStateTime = squad.remainingStateTime - 10

        if squad.state == 'deployed' then
            env.info('SquadTracker - '..squad.name..'('..squad.data.type..') started working for '..squad.data.jobtime..' seconds')
            squad.state = 'working'
            squad.remainingStateTime = squad.data.jobtime
        elseif squad.state == 'working' then
            if squad.remainingStateTime <=0 then
                env.info('SquadTracker - '..squad.name..'('..squad.data.type..') job complete, waiting '..squad.data.extracttime..' seconds for extract')
                
                if squad.data.type == PlayerLogistics.infantryTypes.capture then
                    local zn = ZoneCommand.getZoneOfPoint(squad.position)
                    if zn and zn.side == 0 then
                        squad.state = "complete"
                        squad.remainingStateTime = 0
                        zn:capture(gr:getCoalition())
                        gr:destroy()
                        env.info('SquadTracker - '..squad.name..'('..squad.data.type..') no extraction required, deleting')
                        return true
                    else
                        env.info('SquadTracker - '..squad.name..'('..squad.data.type..') not in zone, cant capture')
                    end
                elseif squad.data.type == PlayerLogistics.infantryTypes.engineer then
                    local zn = ZoneCommand.getZoneOfPoint(squad.position)
                    if zn and zn.side == gr:getCoalition() then
                        zn:boostProduction(3000)
                        squad.state = "complete"
                        squad.remainingStateTime = 0
                        gr:destroy()
                        env.info('SquadTracker - '..squad.name..'('..squad.data.type..') no extraction required, deleting')
                        return true
                    else
                        env.info('SquadTracker - '..squad.name..'('..squad.data.type..') not in zone, cant boost')
                    end
                elseif squad.data.type == PlayerLogistics.infantryTypes.sabotage then
                    local zn = ZoneCommand.getZoneOfPoint(squad.position)
                    if zn and zn.side ~= gr:getCoalition() and zn.side ~= 0 then
                        zn:sabotage(1000, squad.position)
                        env.info('SquadTracker - '..squad.name..'('..squad.data.type..') sabotaged '..zn.name)
                    else
                        env.info('SquadTracker - '..squad.name..'('..squad.data.type..') not in zone, cant sabotage')
                    end
                elseif squad.data.type == PlayerLogistics.infantryTypes.spy then
                    local zn = ZoneCommand.getZoneOfPoint(squad.position)
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

                        env.info('SquadTracker - '..squad.name..'('..squad.data.type..') infiltrated into '..zn.name)
                    else
                        env.info('SquadTracker - '..squad.name..'('..squad.data.type..') not in zone, cant infiltrate')
                    end
                elseif squad.data.type == PlayerLogistics.infantryTypes.ambush then
                    local cnt = gr:getController()
                    cnt:setCommand({ 
                        id = 'SetInvisible', 
                        params = { 
                            value = false 
                        } 
                    })
                end

                squad.state = 'extractReady'
                squad.remainingStateTime = squad.data.extracttime
                MissionTargetRegistry.addSquad(squad)
			else
                if squad.data.type == PlayerLogistics.infantryTypes.ambush then
                    if not squad.discovered then
                        local frcnt = gr:getUnit(1):getController()
                        local targets = frcnt:getDetectedTargets()
                        local isTargetClose = false
                        if #targets > 0 then
                            for _,tgt in ipairs(targets) do
                                if tgt.visible and tgt.object then
                                    if tgt.object.isExist and tgt.object:isExist() and tgt.object.getCoalition and tgt.object:getCoalition()~=gr:getCoalition() and 
                                    Object.getCategory(tgt.object) == 1 then
                                        local dist = mist.utils.get3DDist(gr:getUnit(1):getPoint(), tgt.object:getPoint())
                                        if dist < 100 then
                                            isTargetClose = true
                                            break
                                        end
                                    end
                                end
                            end
                        end
                        
                        if isTargetClose then
                            squad.discovered = true
                            local cnt = gr:getController()
                            cnt:setCommand({ 
                                id = 'SetInvisible',
                                params = { 
                                    value = false 
                                }
                            })
                        end
                    elseif squad.shouldDiscover then
                        squad.shouldDiscover = nil
                        local cnt = gr:getController()
                        cnt:setCommand({ 
                            id = 'SetInvisible',
                            params = { 
                                value = false 
                            }
                        })
                    end
                end
            end
        elseif squad.state == 'extractReady' then
            if squad.remainingStateTime <= 0 then
                env.info('SquadTracker - '..squad.name..'('..squad.data.type..') extract time elapsed, group MIA')
                squad.state = 'mia'
                squad.remainingStateTime = 0
			    gr:destroy()
                MissionTargetRegistry.removeSquad(squad)
                return true
            end

            if not squad.lastMarkerDeployedTime then
                squad.lastMarkerDeployedTime = timer.getAbsTime() - (10*60)
            end

            if timer.getAbsTime() - squad.lastMarkerDeployedTime > (5*60) then
                if gr:getSize()>0 then
                    local unPos = gr:getUnit(1):getPoint()
                    local p = Utils.getPointOnSurface(unPos)
                    p.x = p.x + math.random(-5,5)
                    p.z = p.z + math.random(-5,5)
		            trigger.action.smoke(p, trigger.smokeColor.Blue)
                    squad.lastMarkerDeployedTime = timer.getAbsTime()
                end
            end
        end
    end
end

