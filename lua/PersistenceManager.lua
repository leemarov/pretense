



PersistenceManager = {}

do

    function PersistenceManager:new(path)
        local obj = {
            path = path,
            data = nil
        }

        setmetatable(obj, self)
		self.__index = self
        return obj
    end

    function PersistenceManager:restore()
        self:restoreZones()
        self:restoreAIMissions()
        self:restoreCsar()
        self:restoreSquads()
        self:restoreCarriers()
        self:restoreTrackedBoxes()
        self:restoreFarps()
        self:restoreHumanResource()
        self:restoreStrategy()
        self:restorePlayerVehicles()
        
        timer.scheduleFunction(function(param)
            param:restoreStrikeTargets()
            param:restoreReconAreas()
        end, self, timer.getTime()+5)
    end
    
    function PersistenceManager:restorePlayerVehicles()
        local save = self.data
        if save.playerVehicles then
            DependencyManager.get("PlayerLogistics"):restorePlayerVehicles(save.playerVehicles)
        end
    end

    function PersistenceManager:restoreStrategy()
        local save = self.data
        if save.strategy then 
            StrategicAI.redAI:restoreState(save.strategy.red)
            StrategicAI.blueAI:restoreState(save.strategy.blue)
        end
    end

    function PersistenceManager:restoreHumanResource()
        local save = self.data
        if save.humanResource then
            DependencyManager.get("PlayerLogistics").humanResource = save.humanResource
        end
    end

    function PersistenceManager:restoreFarps()
        local save = self.data
        if save.trackedBuildings then
            for i,v in ipairs(save.trackedBuildings) do
                Spawner.createObject(v.name, v.type, v.pos, v.side, 0, 0, {
                    [land.SurfaceType.LAND] = true, 
                    [land.SurfaceType.ROAD] = true,
                    [land.SurfaceType.RUNWAY] = true
                })

                DependencyManager.get("PlayerLogistics").trackedBuildings[v.name] = { name=v.name, type=v.type }
            end

            timer.scheduleFunction(function(param, time)
                for i,v in ipairs(save.trackedBuildings) do
                    if v.type == PlayerLogistics.buildables.farp then
                        if v.warehouse then
                            WarehouseManager.restore(v.name, v.warehouse)
                        end

                        if v.resource then
                            local f = FARPCommand:new(v.name, 500)
                            f.resource = v.resource
                            DependencyManager.get("PlayerLogistics").trackedBuildings[v.name].farp = f
                        end
                    end
                end
            end, save.trackedBuildings, timer.getTime()+2)
        end
    end

    function PersistenceManager:restoreTrackedBoxes()
        local save = self.data
        if save.trackedBoxes then
            for _,v in ipairs(save.trackedBoxes) do
                DependencyManager.get("PlayerLogistics"):restoreBox(v)
            end
        end
    end

    function PersistenceManager:restoreZones()
        local save = self.data
        for i,v in pairs(save.zones) do
            local z = ZoneCommand.getZoneByName(i)
            if z then
                z:setSide(v.side)
                z.resource = v.resource
                z.revealTime = v.revealTime
                z.extraBuildResources = v.extraBuildResources
                z.sabotageDebt = v.sabotageDebt or 0
                z.mode = v.mode
                z.distToFront = v.distToFront
                z.closestEnemyDist = v.closestEnemyDist
                for name,data in pairs(v.built) do
                    local pr = z:getProductByName(name)
                    z:instantBuild(pr)
    
                    if pr.type == 'defense' and type(data) == "table" then
                        local unitTypes = {}
                        for _,typeName in ipairs(data) do
                            if not unitTypes[typeName] then 
                                unitTypes[typeName] = 0
                            end
                            unitTypes[typeName] = unitTypes[typeName] + 1
                        end
    
                        timer.scheduleFunction(function(param, time)
                            local gr = Group.getByName(param.name)
                            if gr then
                                local types = param.data
                                local toKill = {}
                                for _,un in ipairs(gr:getUnits()) do
                                    local tp = un:getDesc().typeName
                                    if types[tp] and types[tp] > 0 then
                                        types[tp] = types[tp] - 1
                                    else
                                        table.insert(toKill, un)
                                    end
                                end
    
                                for _,un in ipairs(toKill) do
                                    un:destroy()
                                end
                            end
                        end, {data=unitTypes, name=name}, timer.getTime()+2)
                    end
                end
                
                if v.currentBuild then
                    local pr = z:getProductByName(v.currentBuild.name)
                    z:queueBuild(pr, v.currentBuild.isRepair, v.currentBuild.progress)
                end
    
                if v.currentMissionBuild then
                    local pr = z:getProductByName(v.currentMissionBuild.name)
                    z:queueBuild(pr, false, v.currentMissionBuild.progress)
                end
                
                z:refreshText()
            end
        end

        if save.missionResources then
            for i,v in ipairs(save.missionResources) do
                for i2,v2 in pairs(v) do
                    local z = ZoneCommand.getZoneByName(v2.ownername)
                    local prod = z:getProductByName(v2.prodname)

                    StrategicAI.pushResource(prod)
                end
            end
        end
    end

    function PersistenceManager:restoreAIMissions()
        local save = self.data
        local instantBuildStates = {
            ['uninitialized'] = true,
            ['takeoff'] = true,
        }
    
        local reActivateStates = {
            ['inair'] = true,
            ['enroute'] = true,
            ['atdestination'] = true,
            ['siege'] = true
        }
    
        for i,v in pairs(save.activeGroups) do
            if v.homeName then
                if instantBuildStates[v.state] then
                    local z = ZoneCommand.getZoneByName(v.homeName)
                    if z then
                        local pr = z:getProductByName(v.productName)
                        if z.side == pr.side then
                            z:instantBuild(pr)
                        end
                    end
                elseif v.lastMission and reActivateStates[v.state] then
                    timer.scheduleFunction(function(param, time)
                        local z = ZoneCommand.getZoneByName(param.ownerName)
                        local p = z:getProductByName(param.productName)
                        AIActivator.activateMission(p, nil, v)
                    end, v, timer.getTime()+3)
                end
            end
        end
    end

    function PersistenceManager:restoreCsar()
        local save = self.data
        if save.csarTracker then
            for i,v in pairs(save.csarTracker) do
                DependencyManager.get("CSARTracker"):restorePilot(v)
            end
        end
    end

    function PersistenceManager:restoreSquads()
        local save = self.data
        if save.squadTracker then
            for i,v in pairs(save.squadTracker) do
                local sdata = nil
                if v.isAISpawned then
                    if v.type == PlayerLogistics.infantryTypes.ambush then
                        sdata = GroupMonitor.aiSquads.ambush[v.side]
                    else 
                        sdata = GroupMonitor.aiSquads.manpads[v.side]
                    end
                else
                    sdata = DependencyManager.get("PlayerLogistics").registeredSquadGroups[v.type]
                end

                if sdata then
                    v.data = sdata
                    DependencyManager.get("SquadTracker"):restoreInfantry(v)
                end
            end
        end
    end

    function PersistenceManager:restoreStrikeTargets()
        local save = self.data
        if save.strikeTargets then
            for i,v in pairs(save.strikeTargets) do
                local zone = ZoneCommand.getZoneByName(v.zname)
                local product = zone:getProductByName(v.pname)

                MissionTargetRegistry.strikeTargets[i] = {
                    data = product,
                    zone = zone,
                    addedTime = timer.getAbsTime() - v.elapsedTime,
                    isDeep = isDeep
                }
            end
        end
    end

    function PersistenceManager:restoreReconAreas()
        local save = self.data
        if save.reconAreas then
            for i,v in pairs(save.reconAreas) do
                if v.gname then
                    local gr = Group.getByName(v.gname)
                    DependencyManager.get("ReconManager"):revealGroup(v.gname, v.padding, v.lifetime)
                else
                    local zone = ZoneCommand.getZoneByName(v.zname)
                    local product = zone:getProductByName(v.pname)
                    DependencyManager.get("ReconManager"):createReconArea(product, zone, v.padding, v.lifetime, true)
                end
            end
        end
    end

    function PersistenceManager:restoreCarriers()
        local save = self.data
        if save.carriers then
            for i,v in pairs(save.carriers) do
                local carrier = CarrierCommand.getCarrierByName(v.name)
                if carrier then 
                    carrier.resource = math.min(v.resource, carrier.maxResource)
                    carrier.weaponStocks = v.weaponStocks or {}

                    local group = Group.getByName(v.name)
                    if group then
                        local vars = {
                            groupName = group:getName(),
                            point = v.position.p,
                            action = 'teleport',
                            heading = math.atan2(v.position.x.z, v.position.x.x),
                            initTasks = false,
                            route = {}
                        }
                
                        mist.teleportToPoint(vars)

                        timer.scheduleFunction(function(param, time)
                            param:setupRadios()
                        end, carrier, timer.getTime()+3)

                        carrier.navigation.waypoints = v.navigation.waypoints
                        carrier.navigation.currentWaypoint = nil
                        carrier.navigation.nextWaypoint = v.navigation.currentWaypoint
                        carrier.navigation.loop = v.navigation.loop

                        if v.supportFlightStates then
                            for sfsName, sfsData in pairs(v.supportFlightStates) do
                                local sflight = carrier.supportFlights[sfsName]
                                if sflight then
                                    if sfsData.state == CarrierCommand.supportStates.inair and sfsData.targetName and sfsData.position then
                                        local zn = ZoneCommand.getZoneByName(sfsData.targetName)
                                        if not zn then 
                                            zn = CarrierCommand.getCarrierByName(sfsData.targetName)
                                        end

                                        if not zn then 
                                            zn = FARPCommand.getFARPByName(sfsData.targetName)
                                        end

                                        if zn then
                                            CarrierCommand.spawnSupport(sflight, zn, sfsData)
                                        end
                                    elseif sfsData.state == CarrierCommand.supportStates.takeoff and sfsData.targetName then
                                        local zn = ZoneCommand.getZoneByName(sfsData.targetName)
                                        if not zn then 
                                            zn = CarrierCommand.getCarrierByName(sfsData.targetName)
                                        end
                                        
                                        if not zn then 
                                            zn = FARPCommand.getFARPByName(sfsData.targetName)
                                        end

                                        if zn then
                                            CarrierCommand.spawnSupport(sflight, zn)
                                        end
                                    end
                                end
                            end
                        end

                        if v.aliveGroupMembers then
                            timer.scheduleFunction(function(param, time)
                                local g = Group.getByName(param.name)
                                if not g then return end
                                local grMembers = g:getUnits()
                                local liveMembers = {}
                                for _, agm in ipairs(param.aliveGroupMembers) do
                                    liveMembers[agm] = true
                                end

                                for _, gm in ipairs(grMembers) do
                                    if not liveMembers[gm:getName()] then
                                        gm:destroy()
                                    end
                                end
                            end, v, timer.getTime()+4)
                        end
                    end
                end
            end
        end
    end

    function PersistenceManager:canRestore()
        if self.data == nil then return false end
        
        local redExist = false
        local blueExist = false
        for _,z in pairs(self.data.zones) do
            if z.side == 1 and not redExist then redExist = true end
            if z.side == 2 and not blueExist then blueExist = true end

            if redExist and blueExist then break end
        end

        if not redExist or not blueExist then return false end

        return true
    end

    function PersistenceManager:load()
        self.data = Utils.loadTable(self.path)
    end

    function PersistenceManager:save()
        local tosave = {}
        
        tosave.zones = {}
        for i,v in pairs(ZoneCommand.getAllZones()) do
        
            tosave.zones[i] = {
                name = v.name,
                side = v.side,
                resource = v.resource,
                mode = v.mode,
                distToFront = v.distToFront,
                closestEnemyDist = v.closestEnemyDist,
                extraBuildResources = v.extraBuildResources,
                sabotageDebt = v.sabotageDebt,
                revealTime = v.revealTime,
                built = {}
            }
            
            for n,b in pairs(v.built) do
                if b.type == 'defense' then
                    local typeList = {}
                    local gr = Group.getByName(b.name)
                    if gr then
                        for _,unit in ipairs(gr:getUnits()) do
                            table.insert(typeList, unit:getDesc().typeName)
                        end

                        tosave.zones[i].built[n] = typeList
                    end
                else
                    tosave.zones[i].built[n] = true
                end
                
            end
            
            if v.currentBuild then
                tosave.zones[i].currentBuild = {
                    name = v.currentBuild.product.name, 
                    progress = v.currentBuild.progress,
                    side = v.currentBuild.side,
                    isRepair = v.currentBuild.isRepair
                }
            end

            if v.currentMissionBuild then
                tosave.zones[i].currentMissionBuild = {
                    name = v.currentMissionBuild.product.name, 
                    progress = v.currentMissionBuild.progress,
                    side = v.currentMissionBuild.side
                }
            end
        end

        tosave.missionResources = {}
        for i,v in ipairs(StrategicAI.resources) do
            tosave.missionResources[i] = {}
            for i2,v2 in pairs(v) do
                tosave.missionResources[i][i2] = {prodname = v2.name, ownername = v2.owner.name}
            end
        end

        tosave.activeGroups = {}
        for i,v in pairs(DependencyManager.get("GroupMonitor").groups) do
            tosave.activeGroups[i] = {
                productName = v.product.name,
                ownerName = v.product.owner.name,
                type = v.product.missionType
            }

            local gr = Group.getByName(v.product.name)
            if gr and gr:getSize()>0 then
                local un = gr:getUnit(1)
                if un then 
                    tosave.activeGroups[i].position = un:getPoint()
                    tosave.activeGroups[i].lastMission = v.product.lastMission
                    tosave.activeGroups[i].heading = math.atan2(un:getPosition().x.z, un:getPosition().x.x)
                end
            end

            if v.spawnedSquad then
                tosave.activeGroups[i].spawnedSquad = true
            end

            if v.target then
                tosave.activeGroups[i].targetName = v.target.name
            end

            if v.home then
                tosave.activeGroups[i].homeName = v.home.name
            end

            if v.state then
                tosave.activeGroups[i].state = v.state
                tosave.activeGroups[i].lastStateDuration = timer.getAbsTime() - v.lastStateTime
            else
                tosave.activeGroups[i].state = 'uninitialized'
                tosave.activeGroups[i].lastStateDuration = 0
            end
        end

        tosave.csarTracker = {}

        for i,v in pairs(DependencyManager.get("CSARTracker").activePilots) do
            if v.pilot:isExist() and v.pilot:getSize()>0 and v.remainingTime>60 then
                tosave.csarTracker[i] = {
                    name = v.name,
                    remainingTime = v.remainingTime,
                    pos = v.pilot:getUnit(1):getPoint()
                }
            end
        end

        tosave.squadTracker = {}

        for i,v in pairs(DependencyManager.get("SquadTracker").activeInfantrySquads) do
            tosave.squadTracker[i] = {
                state = v.state,
                remainingStateTime = v.remainingStateTime,
                position = v.position,
                deployPos = v.deployPos,
                targetPos = v.targetPos,
                name = v.name,
                type = v.data.type,
                side = v.data.side,
				isAISpawned = v.data.isAISpawned,
                discovered = v.discovered
            }
        end

        tosave.humanResource = DependencyManager.get("PlayerLogistics").humanResource

        tosave.carriers = {}
        for cname,cdata in pairs(CarrierCommand.getAllCarriers()) do
            local group = Group.getByName(cdata.name)
            if group and group:isExist() then

                tosave.carriers[cname] = {
                    name = cdata.name,
                    resource = cdata.resource,
                    position = group:getUnit(1):getPosition(),
                    navigation = cdata.navigation,
                    supportFlightStates = {},
                    weaponStocks = cdata.weaponStocks,
                    aliveGroupMembers = {}
                }

                for _, gm in ipairs(group:getUnits()) do
                    table.insert(tosave.carriers[cname].aliveGroupMembers, gm:getName())
                end

                for spname, spdata in pairs(cdata.supportFlights) do
                    tosave.carriers[cname].supportFlightStates[spname] = {
                        name = spdata.name, 
                        state = spdata.state,
                        lastStateDuration = timer.getAbsTime() - spdata.lastStateTime,
                        returning = spdata.returning
                    }

                    if spdata.target then
                        tosave.carriers[cname].supportFlightStates[spname].targetName = spdata.target.name
                    end

                    if spdata.state == CarrierCommand.supportStates.inair then
                        local spgr = Group.getByName(spname)
                        if spgr and spgr:isExist() and spgr:getSize()>0 then
                            local spun = spgr:getUnit(1)
                            if spun and spun:isExist() then
                                tosave.carriers[cname].supportFlightStates[spname].position = spun:getPoint()
                                tosave.carriers[cname].supportFlightStates[spname].heading = math.atan2(spun:getPosition().x.z, spun:getPosition().x.x)
                            end
                        end
                    end
                end
            end
        end

        tosave.strikeTargets = {}
        for i,v in pairs(MissionTargetRegistry.strikeTargets) do
            tosave.strikeTargets[i] = { pname = v.data.name, zname = v.zone.name, elapsedTime = timer.getAbsTime() - v.addedTime, isDeep = v.isDeep }
        end

        tosave.reconAreas = {}
        for i,v in ipairs(DependencyManager.get("ReconManager").reconAreas) do
            if v.group then
                table.insert(tosave.reconAreas,{
                    gname = v.group:getName(),
                    padding = v.padding,
                    lifetime = v.lifetime
                })
            else
                table.insert(tosave.reconAreas,{
                    zname = v.zonename,
                    pname = v.productname,
                    padding = v.padding,
                    lifetime = v.lifetime
                })
            end
        end

        tosave.trackedBoxes = {}
        for i,v in pairs(DependencyManager.get("PlayerLogistics").trackedBoxes) do
            if v.lifetime > 0 then
                local box = StaticObject.getByName(i) or Unit.getByName(i)
                if box and box:isExist() and Utils.isLanded(box) then
                    local p = box:getPoint()

                    table.insert(tosave.trackedBoxes, {
                        name = v.name,
                        amount = v.amount, 
                        origin = v.origin.name,
                        side = box:getCoalition(),
                        type = v.type,
                        pos = { x = p.x, y = p.z },
                        lifetime = v.lifetime,
                        content = v.content,
                        convert = v.convert,
                        isSalvage = v.isSalvage
                    })
                end
            end
        end

        tosave.trackedBuildings = {}
        for i,v in pairs(DependencyManager.get("PlayerLogistics").trackedBuildings) do
            if not v.isDeleted then
                local bl = StaticObject.getByName(i)
                if bl and bl:isExist() then
                    local p = bl:getPoint()

                    local wh = nil
                    if v.type == PlayerLogistics.buildables.farp then
                        wh = WarehouseManager.toString(v.name)
                    end

                    local res = nil
                    if v.farp then res = v.farp.resource end

                    table.insert(tosave.trackedBuildings, {
                        name = v.name,
                        side = bl:getCoalition(),
                        type = v.type,
                        pos = { x = p.x, y = p.z },
                        warehouse = wh,
                        resource = res
                    })
                else
                    local g = Group.getByName(i)
                    if g and g:isExist() and g:getSize()>0 then
                        local p = g:getUnit(1):getPoint()

                        table.insert(tosave.trackedBuildings, {
                            name = v.name,
                            side = g:getCoalition(),
                            type = v.type,
                            pos = { x = p.x, y = p.z }
                        })
                    end
                end
            end
        end

        tosave.strategy = {
            red = StrategicAI.redAI:serializeState(),
            blue = StrategicAI.blueAI:serializeState()
        }

        tosave.playerVehicles = {}
        for i,v in pairs(DependencyManager.get("PlayerLogistics").trackedPlayerVehicles) do
            local g = Group.getByName(i)
            if g and g:isExist() and g:getSize() > 0 then
                local u = g:getUnit(1)
                local pl = DependencyManager.get("PlayerLogistics")


                local carry = {}
                if pl.carriedCargo[g:getID()] then carry.carriedCargo = pl.carriedCargo[g:getID()] end
                if pl.carriedInfantry[g:getID()] then 
                    carry.carriedInfantry = {}
                    for i,v in ipairs(pl.carriedInfantry[g:getID()]) do
                        local inf = {
                            type = v.type,
                            weight = v.weight,
                            size = v.size,
                        }

                        if v.loadedAt then inf.loadedAt = v.loadedAt.name end

                        table.insert(carry.carriedInfantry, inf)
                    end
                end
                if pl.carriedPilots[g:getID()] then carry.carriedPilots = pl.carriedPilots[g:getID()] end
                if pl.carriedBoxes[g:getID()] then carry.carriedBoxes = pl.carriedBoxes[g:getID()] end

                tosave.playerVehicles[i] = { 
                    name = v.name, 
                    template = v.template, 
                    side = v.side, 
                    pos = u:getPoint(),
                    carry = carry,
                    mp = v.mp
                }
            end
        end

        Utils.saveTable(self.path, tosave)
    end
end

