



Cameron = AIBase:new() -- chooses a few objectives and focuses on them, requests products it needs, directs cap to zones with enemy aircraft nearby

do
    function Cameron:createState()
        self.objectives = {}
        self.maxObj = 2
        self.otherAssigned = {}
        self.assignedTargets = {}
        self.maxCap = 2
        self.maxBai = 1
        self.maxTicks = 6*60*2 -- 1 tick per 10 seconds 6 ticks per minute, 6*60 ticks per hour

        self.gci = MiniGCI:new(self.side)

        Cameron.misPriorities = {
            [ZoneCommand.missionTypes.patrol] = 1,
            [ZoneCommand.missionTypes.assault] = 2,
            [ZoneCommand.missionTypes.sead] = 3,
            [ZoneCommand.missionTypes.strike] = 4,
            [ZoneCommand.missionTypes.cas] = 5,
            [ZoneCommand.missionTypes.cas_helo] = 6,
            [ZoneCommand.missionTypes.supply_air] = 7,
            [ZoneCommand.missionTypes.supply_convoy] = 8,
            [ZoneCommand.missionTypes.awacs] = 9,
            [ZoneCommand.missionTypes.tanker] = 10,
            [ZoneCommand.missionTypes.supply_transfer] = 11,
        }
    end

    function Cameron:restoreState(state)
        if not state then return end

        for i,v in ipairs(state.objectives) do
            local assigned = {}
            for pn, po in pairs(v.assignedResources) do
                assigned[pn] = ZoneCommand.getZoneByName(po.owner):getProductByName(po.pname)
            end

            table.insert(self.objectives, {
                target = ZoneCommand.getZoneByName(v.target),
                requestedResources = {},
                assignedResources = assigned,
                ticks = v.ticks
            })
        end

        for pn, po in pairs(state.otherAssigned) do
            self.otherAssigned[pn] = ZoneCommand.getZoneByName(po.owner):getProductByName(po.pname)
            self.assignedTargets[pn] = po.tname
        end
    end

    function Cameron:serializeState()
        local state = {
            objectives = {},
            otherAssigned = {}
        }

        for i,v in ipairs(self.objectives) do
            local ob = {
                target = v.target.name,
                assignedResources = {},
                ticks = v.ticks
            }

            for pn,po in pairs(v.assignedResources) do
                ob.assignedResources[pn] = {pname = po.name, owner = po.owner.name}
            end

            table.insert(state.objectives, ob)
        end

        for i,v in pairs(self.otherAssigned) do
            state.otherAssigned[i] = { pname = v.name, owner = v.owner.name, tname = self.assignedTargets[i] }
        end

        return state
    end

    local function isMissionActive(product)
        if not product then return false end

        local g = DependencyManager.get("GroupMonitor"):getGroup(product.name)
        if g then
            if g.returning then return false end

            local gr = Group.getByName(g.product.name)
            if gr and gr:isExist() and gr:getSize()>0 then
                return true
            end
        end

        return false
    end

    function Cameron:makeDecissions()

        local viableAttack = {}
        local viableDefend = {}
        local canBuild = {}
        local needsSupplies = {}
        local friendlyZones = {}
        local viableSupports = {}

        local add = table.insert
        for i,v in pairs(ZoneCommand.getAllZones()) do
            if v.distToFront~=nil then
                if v.side == self.side then
                    if v:canBuild() or v:canMissionBuild() then
                        add(canBuild, v)
                    end

                    if v:needsSupplies(2000) then
                        add(needsSupplies, v)
                    end
                    
                    if v.distToFront~= nil and v.distToFront == 4 then
                        add(viableSupports, v)
                    end
                else
                    if v.distToFront~=nil and v.distToFront == 0 then
                        add(viableAttack, v)
                    end
                end

                if v.distToFront <= 1 and v.side == self.side then
                    add(viableDefend, v)
                end
            end
        end

        table.sort(needsSupplies, function(a,b)
            if a.distToFront~=nil and b.distToFront == nil then
                return true
            elseif a.distToFront == nil and b.distToFront ~= nil then
                return false
            elseif a.distToFront == b.distToFront then
                return a.resource < b.resource
            else
                return a.distToFront<b.distToFront
            end
        end)

        self.gci:refreshRadars()
        self.gci:scanForContacts()

        self:processPlan({
            viableAttack = viableAttack,
            viableDefend = viableDefend,
            canBuild = canBuild,
            needsSupplies = needsSupplies,
            friendlyZones = friendlyZones,
            viableSupports = viableSupports,
        })

        if self.createMissions then
            DependencyManager.get("MissionTracker"):fillEmptySlots()
        end
    end

    function Cameron:processPlan(zones)
        while #self.objectives < self.maxObj and #zones.viableAttack>0 do
            local o = self:createObjective(zones.viableAttack)
            if not o then break end
            table.insert(self.objectives, o)
        end

        local keep = {}
        for _,v in ipairs(self.objectives) do
            local isComplete = self:processObjective(v)
            if not isComplete then
                table.insert(keep, v)
            else
                -- //TODO: reasign resources from completed or abandoned objective
            end
        end
        self.objectives = keep

        local requested = {}
        for _,v in ipairs(self.objectives) do
            for res, amount in pairs(v.requestedResources) do
                requested[res] = requested[res] or 0
                requested[res] = requested[res] + amount
            end
        end
        
        local supportNeeds = self:processSupports(zones.viableSupports)
        for res,amount in pairs(supportNeeds) do
            requested[res] = requested[res] or 0
            requested[res] = requested[res] + amount
        end

        local defenseNeeds = self:processDefense(zones.viableDefend)
        for res,amount in pairs(defenseNeeds) do
            requested[res] = requested[res] or 0
            requested[res] = requested[res] + amount
        end

        self:processBuilds(zones, requested)

        self:processSupplies(zones)

        for i,v in pairs(self.otherAssigned) do
            if not isMissionActive(v) then
                self.otherAssigned[i] = nil
                self.assignedTargets[i] = nil
            end
        end
    end

    local function getMissionOfType(mistype, resourceList, tankerType, pos)
        local all = {}
        for _,v in pairs(resourceList) do
            if v.missionType == mistype then
                if tankerType then
                    if v.variant == tankerType then
                        table.insert(all,v)
                    end
                else
                    table.insert(all,v)
                end
            end
        end

        local closest = nil
        local cdist = 999999999
        for i,v in ipairs(all) do
            local dist = mist.utils.get2DDist(v.owner.zone.point, pos)
            if dist < cdist then
                closest = v
                cdist = dist
            end
        end

        return closest
    end

    local function createMission(objective, type, myside, assigned)
        local activated = false

        if assigned then objective.assignedResources[assigned.name] = nil end

        local res = getMissionOfType(type, StrategicAI.resources[myside], nil, objective.target.zone.point)
        if res then
            local success = false
            if res.missionType == ZoneCommand.missionTypes.assault then
                if res.owner:canAttack(objective.target, 'assault') then
                    success = StrategicAI.activateMission(res, objective.target)
                end
            elseif res.missionType == ZoneCommand.missionTypes.cas_helo then
                if res.owner:canAttack(objective.target, 'cas_helo') then
                    success = StrategicAI.activateMission(res, objective.target)
                end
            else
                success = StrategicAI.activateMission(res, objective.target)
            end

            if success then
                objective.assignedResources[res.name] = res
                activated = true
            end
        else
            objective.requestedResources[type] = (objective.requestedResources[type] or 0) + 1
        end

        return activated
    end

    local function ensureMission(objective, type, myside)
        local activated = false
        local assigned = getMissionOfType(type, objective.assignedResources, nil, objective.target.zone.point)
        if not isMissionActive(assigned) then
            activated = createMission(objective, type, myside, assigned)
        end

        return activated
    end

    function Cameron:processSupports(suportzones)
        if #suportzones == 0 then return {} end

        local needs = {}

        local awacstgt = suportzones[math.random(1,#suportzones)]
        local awacs = getMissionOfType(ZoneCommand.missionTypes.awacs, self.otherAssigned, nil, awacstgt.zone.point)
        if not isMissionActive(awacs) then
            if awacs then self.otherAssigned[awacs.name] = nil end

            local res = getMissionOfType(ZoneCommand.missionTypes.awacs, StrategicAI.resources[self.side], nil, awacstgt.zone.point)
            if res then
                local success = StrategicAI.activateMission(res, awacstgt)
                if success then
                    self.otherAssigned[res.name] = res
                    self.assignedTargets[res.name] = awacstgt.name
                end
            else
                needs[ZoneCommand.missionTypes.awacs] = 1
            end
        end

        local ttypes = { 'Drogue', 'Boom' }
        for _, ttype in ipairs(ttypes) do
            local tankertgt = suportzones[math.random(1,#suportzones)]
            local tanker = getMissionOfType(ZoneCommand.missionTypes.tanker, self.otherAssigned, ttype, tankertgt.zone.point)
            if not isMissionActive(tanker) then
                if tanker then self.otherAssigned[tanker.name] = nil end
                
                local res = getMissionOfType(ZoneCommand.missionTypes.tanker, StrategicAI.resources[self.side], ttype, tankertgt.zone.point)
                if res then
                    local success = StrategicAI.activateMission(res, tankertgt)
                    if success then
                        self.otherAssigned[res.name] = res
                        self.assignedTargets[res.name] = tankertgt.name
                    end
                else
                    needs[ZoneCommand.missionTypes.tanker] = (needs[ZoneCommand.missionTypes.tanker] or 0) + 1
                end
            end
        end

        return needs
    end

    function Cameron:processDefense(defendZones)
        local needs = {}
        local defendCaps = {}
        local defendCas = {}
        for i,v in pairs(self.otherAssigned) do
            if v.missionType == ZoneCommand.missionTypes.patrol then
                if not isMissionActive(v) then
                    self.otherAssigned[v.name] = nil
                    self.assignedTargets[v.name] = nil
                else
                    table.insert(defendCaps, v)
                end
            elseif v.missionType == ZoneCommand.missionTypes.cas then
                if not isMissionActive(v) then
                    self.otherAssigned[v.name] = nil
                    self.assignedTargets[v.name] = nil
                else
                    table.insert(defendCas, v)
                end
            end
        end

        local enemyPerZone = {}
        for i,v in pairs(self.gci:getContacts()) do
            local closest = ZoneCommand.getClosestZoneToPoint(v:getPoint(), self.side)
            if closest then
                enemyPerZone[closest.name] = (enemyPerZone[closest.name] or 0) + 1
            end
        end
            
        local indexed = {}
        for i,v in pairs(enemyPerZone) do
            table.insert(indexed, {name=i, count=v})
        end

        table.sort(indexed, function(a,b) return a.count<b.count end)

        if #indexed > 0 then
            local assignments = {}
            for i=1,self.maxCap do
                local ind = indexed[i]
                if ind then assignments[ind.name] = 'none' end
            end

            local reassign = {}
            for i,v in ipairs(defendCaps) do
                local assigned = self.assignedTargets[v.name]
                if assignments[assigned] == 'none' then
                    assignments[assigned] = v
                else
                    table.insert(reassign, v)
                end
            end

            for i,v in pairs(assignments) do
                if v == 'none' then
                    if #reassign > 0 then
                        local item = reassign[1]
                        if item then
                            local tgtzone = ZoneCommand.getZoneByName(i)
                            local success = AIActivator.reAssignMission(item, tgtzone)

                            if success then
                                --env.info('Cameron - processDefense: reassigning '..item.name..' from '..self.assignedTargets[item.name]..' to '..tgtzone.name)
                                self.otherAssigned[item.name] = item
                                self.assignedTargets[item.name] = tgtzone.name
                                table.remove(reassign, 1)
                            end
                        end
                    end
                end
            end
        end

        -- //TODO: index bai targets

        if #defendCaps < self.maxCap then
            if #indexed > 0 then
                for i=1,(self.maxCap-#defendCaps) do
                    if indexed[i] then
                        local z = ZoneCommand.getZoneByName(indexed[i].name)
                        --env.info('Cameron - processDefense: tgt: '..z.name)

                        local hasAssignment = false
                        for pn, tn in pairs(self.assignedTargets) do
                            if tn==z.name and isMissionActive(self.otherAssigned[pn]) then
                                hasAssignment = true
                                break
                            end
                        end

                        if not hasAssignment then
                            local cap = getMissionOfType(ZoneCommand.missionTypes.patrol, StrategicAI.resources[self.side], nil, z.zone.point)
                            if cap then
                                local success = StrategicAI.activateMission(cap, z)
                                if success then
                                    self.otherAssigned[cap.name] = cap
                                    self.assignedTargets[cap.name] = z.name
                                end
                            else
                                needs[ZoneCommand.missionTypes.patrol] = (needs[ZoneCommand.missionTypes.patrol] or 0) + 1
                            end
                        end
                    end
                end
            end  
        end

        if #defendCas < self.maxBai then
            -- //TODO: activate bai missions or request needs for eached indexed bai target, attempt getting bai from closest possible place
        end

        return needs
    end

    local function pickSupply(target, sources)
        local simulated = target.distToFront > 1
    
        local pick = nil
        for _,n in ipairs(sources) do
            local stype = 'transfer'
            if simulated then
                if n.missionType == ZoneCommand.missionTypes.supply_transfer then
                    stype = 'transfer'
                end
            else
                if n.missionType == ZoneCommand.missionTypes.supply_convoy  then
                    stype = 'convoy'
                elseif n.missionType == ZoneCommand.missionTypes.supply_air then
                    stype = 'air'
                end
            end

            if not pick then
                if n.owner:canSupply(target, stype, n.capacity) then
                    pick = n
                end
            else
                if n.owner:canSupply(target, stype, n.capacity) and n.owner.resource > pick.owner.resource then
                    pick = n
                end
            end
        end

        return pick
    end

    function Cameron:processSupplies(zones)
        local supplyTypes = {
            [ZoneCommand.missionTypes.supply_air] = true,
            [ZoneCommand.missionTypes.supply_convoy] = true,
            [ZoneCommand.missionTypes.supply_transfer] = true,
        }

        local unassignedNeutral = {}
        for i,v in ipairs(zones.viableAttack) do
            if v.side == 0 then
                local assigned = nil
                for prod,target in pairs(self.assignedTargets) do
                    if target == v.name and self.otherAssigned[prod] and supplyTypes[self.otherAssigned[prod].missionType] then
                        assigned = true
                        break
                    end
                end

                if not assigned then
                    for _,o in ipairs(self.objectives) do
                        for _, prod in pairs(o.assignedResources) do
                            if supplyTypes[prod.missionType] and prod.target and prod.target.name == v.name then
                                assigned = true
                                break
                            end
                        end
                    end
                end

                if not assigned then
                    table.insert(unassignedNeutral, v)
                end
            end
        end

        local requests = {}
        for i,v in ipairs(unassignedNeutral) do
            requests[v.name] = 1001
        end

        for i,v in ipairs(zones.friendlyZones) do
            local need = 0

            if v.currentBuild then
                need = need + (v.currentBuild.product.cost - v.currentBuild.progress)
            end

            if v.currentMissionBuild then
                need = need + (v.currentMissionBuild.product.cost - v.currentMissionBuild.progress)
            end

            if v.resource < need then
                requests[v.name] = need - v.resource
            end
        end

        if #zones.needsSupplies > 0 then
            for i,v in pairs(self.otherAssigned) do
                if v.missionType == ZoneCommand.missionTypes.supply_air or v.missionType == ZoneCommand.missionTypes.supply_convoy then
                    local g = DependencyManager.get("GroupMonitor"):getGroup(v.name)
                    if g and g.returning then
                        local gr = Group.getByName(g.product.name)
                        if gr and gr:isExist() and gr:getSize()>0 then
                            local un = gr:getUnit(1)
                            local pos = un:getPoint()
                            local closest = nil
                            local cdist = 9999999
                            for _,z in ipairs(zones.needsSupplies) do
                                if z.side == self.side then
                                    local d = mist.utils.get2DDist(z.zone.point, pos)
                                    if d < cdist then
                                        closest = z
                                        cdist = d
                                    end
                                end
                            end

                            if closest then
                                local success = AIActivator.reAssignMission(v, closest)

                                if success then
                                    self.otherAssigned[v.name] = v
                                    self.assignedTargets[v.name] = closest.name
                                end
                            end
                        end
                    end
                end
            end
        end

        for i,v in pairs(requests) do
            --env.info('Cameron - processSupplies: '..i..' requesting '..v)

            if v<1000 then 
                --env.info('Cameron - processSupplies: '..i..' request denied, not priority')
            else
                local hasAssigned = false
                for name,prod in pairs(self.otherAssigned) do
                    if prod.missionType == ZoneCommand.missionTypes.supply_air or prod.missionType == ZoneCommand.missionTypes.supply_convoy then
                        if i==self.assignedTargets[prod.name] and isMissionActive(prod) then
                            hasAssigned = true
                            break
                        end
                    end
                end

                if not hasAssigned then
                    local z = ZoneCommand.getZoneByName(i)
                    local sources = {}
                    for _,prod in pairs(StrategicAI.resources[self.side]) do
                        if supplyTypes[prod.missionType] then
                            table.insert(sources, prod)
                        end
                    end
                    
                    local pick = pickSupply(z, sources)
                    
                    if pick then
                        local success = StrategicAI.activateMission(pick, z)
                        if success then
                            self.otherAssigned[pick.name] = pick
                            self.assignedTargets[pick.name] = z.name
                        end
                    end
                end
            end
        end

        if #zones.needsSupplies > 0 then 
    
            for _,z in ipairs(zones.needsSupplies) do
                local hasAssigned = false
                for name, prod in pairs(self.otherAssigned) do
                    if prod.missionType == ZoneCommand.missionTypes.supply_air or prod.missionType == ZoneCommand.missionTypes.supply_convoy then
                        if z.name==self.assignedTargets[prod.name] and isMissionActive(prod) then
                            hasAssigned = true
                            break
                        end
                    end
                end

                if not hasAssigned then
                    local sources = {}
                    for _,v in pairs(StrategicAI.resources[self.side]) do
                        if supplyTypes[v.missionType] then
                            table.insert(sources, v)
                        end
                    end
                    
                    local pick = pickSupply(z, sources)
                    
                    if pick then
                        local success = StrategicAI.activateMission(pick, z)
                        if success then
                            self.otherAssigned[pick.name] = pick
                            self.assignedTargets[pick.name] = z.name
                        end
                    end
                end
            end
        end
    end

    local function pickMainBuilds(canBuild)
        for _,z in ipairs(canBuild) do
            if z:canBuild() then
                local canAfford = {
                    upgrades = {},
                    defenses = {},
                    missions = {}
                }
                
                for _,v in ipairs(z.upgrades[z.side]) do
                    local isBuilt = StrategicAI.isProductBuilt(v)

                    if not isBuilt then
                        if z:canBuildProduct(v) then
                            table.insert(canAfford.upgrades, {product = v, reason='upgrade'})
                        end
                    else
                        for _,v2 in ipairs(v.products) do
                            if z:canBuildProduct(v2) then
                                if v2.type == 'mission' then
                                    if v2.missionType == ZoneCommand.missionTypes.supply_transfer then
                                        if z.distToFront > 1 then
                                            table.insert(canAfford.missions, {product = v2, reason='mission'})
                                        end
                                    elseif v2.missionType == ZoneCommand.missionTypes.supply_air or v2.missionType == ZoneCommand.missionTypes.supply_convoy then
                                        if z.distToFront <= 1 then
                                            table.insert(canAfford.missions, {product = v2, reason='mission'})
                                        end
                                    end
                                elseif v2.type=='defense' and z.mode ~='export' and z.mode ~='supply' and v2.cost > 0 then
                                    local g = Group.getByName(v2.name)
                                    if not g then
                                        table.insert(canAfford.defenses, {product = v2, reason='defense'})
                                    elseif g:getSize() < (g:getInitialSize()*math.random(40,100)/100) then
                                        table.insert(canAfford.defenses, {product = v2, reason='repair'})
                                    end
                                end
                            end
                        end
                    end
                end

                table.sort(canAfford.upgrades, function(a,b) return a.product.value > b.product.value end)
                table.sort(canAfford.defenses, function(a,b)
                    if a.reason == 'repair' and b.reason ~= 'repair' then return true end
                    if a.reason ~= 'repair' and b.reason == 'repair' then return false end
                    if a.reason == 'repair' and b.reason == 'repair' then return a.product.cost < b.product.cost end
                end)

                table.sort(canAfford.missions, function(a,b)
                    if a.product.missionType == ZoneCommand.missionTypes.supply_air then
                        if b.product.missionType == ZoneCommand.missionTypes.supply_convoy then return true end
                        if b.product.missionType == ZoneCommand.missionTypes.supply_air then return a.product.cost < b.product.cost end
                        if b.product.missionType == ZoneCommand.missionTypes.supply_transfer then return true end
                    end

                    if a.product.missionType == ZoneCommand.missionTypes.supply_convoy then
                        if b.product.missionType == ZoneCommand.missionTypes.supply_convoy then return a.product.cost < b.product.cost end
                        if b.product.missionType == ZoneCommand.missionTypes.supply_air then return false end
                        if b.product.missionType == ZoneCommand.missionTypes.supply_transfer then return true end
                    end

                    if a.product.missionType == ZoneCommand.missionTypes.supply_transfer then
                        if b.product.missionType == ZoneCommand.missionTypes.supply_convoy then return false end
                        if b.product.missionType == ZoneCommand.missionTypes.supply_air then return false end
                        if b.product.missionType == ZoneCommand.missionTypes.supply_transfer then return a.product.cost < b.product.cost end
                    end
                end)

                if #canAfford.upgrades > 0 then
                    local p = nil
                    for _,u in ipairs(canAfford.upgrades) do
                        if z.resource >= u.product.cost then
                            p = u.product
                            break
                        end
                    end

                    if not p then
                        p = canAfford.upgrades[#canAfford.upgrades].product
                    end

                    z:queueBuild(p)
                else
                    if #canAfford.defenses > 0 then
                        if z.distToFront == 0 or #canAfford.missions == 0 then
                            local p = canAfford.defenses[1]
                            if p.reason == 'repair' then
                                z:queueBuild(p.product, true)
                            else
                                z:queueBuild(p.product)
                            end
                        else
                            if math.random() < 0.4 then
                                local p = canAfford.defenses[1]
                                if p.reason == 'repair' then
                                    z:queueBuild(p.product, true)
                                else
                                    z:queueBuild(p.product)
                                end
                            else
                                local p = canAfford.missions[1]
                                z:queueBuild(p.product)
                            end
                        end
                    elseif #canAfford.missions > 0 then
                        local p = canAfford.missions[1]
                        z:queueBuild(p.product)
                    end
                end
            end
        end
    end

    function Cameron:processBuilds(zones, requested)
        -- local msg = "Cameron - processBuilds: build requests:"
        -- for type, amount in pairs(requested) do
        --     msg = msg..'\n'..type..' - '..amount
        -- end
        -- env.info(msg)

        local canBuild = zones.canBuild
        local canRetask = {}

        for i,v in ipairs(zones.friendlyZones) do
            if v.currentBuild and v.currentBuild.product.type == 'mission' then
                local mistype = v.currentBuild.product.missionType
                if requested[mistype] and requested[mistype] > 0 then
                    requested[mistype] = requested[mistype] - 1
                end
            end

            if v.currentMissionBuild then
                local mistype = v.currentMissionBuild.product.missionType
                if requested[mistype] and requested[mistype] > 0 then
                    requested[mistype] = requested[mistype] - 1
                end

                if not requested[mistype] then
                    table.insert(canRetask, v)
                end
            end
        end

        if requested[ZoneCommand.missionTypes.supply_air] or requested[ZoneCommand.missionTypes.supply_convoy] then
            local remaining = {}

            for _,z in ipairs(canBuild) do
                if z:canBuild() then
                    local prod = nil
                    if requested[ZoneCommand.missionTypes.supply_air] and requested[ZoneCommand.missionTypes.supply_air] > 0 then
                        prod = z:getProductOfType(ZoneCommand.productTypes.mission, ZoneCommand.missionTypes.supply_air)
                    end

                    if not prod and requested[ZoneCommand.missionTypes.supply_convoy] and requested[ZoneCommand.missionTypes.supply_convoy] > 0 then
                        prod = z:getProductOfType(ZoneCommand.productTypes.mission, ZoneCommand.missionTypes.supply_convoy)
                    end

                    if prod and z:canBuildProduct(prod) and z.distToFront <= 1 then
                        z:queueBuild(prod)
                        requested[prod.missionType] = requested[prod.missionType] - 1
                    end
                end

                if z:canBuild() or z:canMissionBuild() then
                    table.insert(remaining, z)
                end
            end

            canBuild = remaining
        end

        local mainResRequests = pickMainBuilds(canBuild)

        local prioritized = {}
        for type,amount in pairs(requested) do
            table.insert(prioritized, {type = type, amount = amount})
        end

        table.sort(prioritized, function(a,b) return Cameron.misPriorities[a.type] < Cameron.misPriorities[b.type] end)

        for i, pr in ipairs(prioritized) do
            local type = pr.type
            local amount = pr.amount
            if amount > 0 then
                for _,z in ipairs(canBuild) do
                    if z:canMissionBuild() then
                        local p = z:getProductOfType('mission', type)
                        if p and z:canBuildProduct(p) then
                            z:queueBuild(p)
                            requested[type] = amount - 1
                        end
                    end
                end
            end
        end

        for _,z in ipairs(canBuild) do
            if z:canMissionBuild() and not z:criticalOnSupplies() then
                local canMission = {}
                for _,v in ipairs(z.upgrades[z.side]) do
                    if StrategicAI.isProductBuilt(v) then
                        for _,v2 in ipairs(v.products) do
                            if z:canBuildProduct(v2) and not StrategicAI.isProductBuilt(v2) and v2.type == 'mission' then 
                                if v2.missionType ~= ZoneCommand.missionTypes.assault or z.distToFront==0 then
                                    if math.random() < ZoneCommand.missionValidChance then
                                        table.insert(canMission, {product = v2, reason='mission'})
                                    end
                                end
                            end
                        end
                    end
                end
            
                if #canMission > 0 then
                    local choice = math.random(1, #canMission)
                    
                    if canMission[choice] then
                        local p = canMission[choice]
                        z:queueBuild(p.product)
                    end
                end
            end
        end

        -- local msg = "Cameron - processBuilds: remaining requests:"
        -- for type, amount in pairs(requested) do
        --     msg = msg..'\n'..type..' - '..amount
        -- end
        -- env.info(msg)
    end

    function Cameron:processObjective(objective)
        --env.info("Cameron - processObjective: procesing target "..objective.target.name)
        objective.requestedResources = {}
        objective.ticks = objective.ticks + 1
        if objective.ticks > self.maxTicks then return true end
        if objective.target.side == self.side then return true end
        if objective.target.distToFront ~=0 then return true end

        for i,v in pairs(objective.assignedResources) do
            if not isMissionActive(v) then
                objective.assignedResources[i] = nil
            end
        end

        if objective.target:hasEnemySAMRadar(self.side) then
            --env.info("Cameron - processObjective: "..objective.target.name.." has radar, requesting sead")
            ensureMission(objective, ZoneCommand.missionTypes.sead, self.side)
            
            --env.info("Cameron - processObjective: "..objective.target.name.." has radar, requesting cas")
            local cas = getMissionOfType(ZoneCommand.missionTypes.cas, objective.assignedResources, nil, objective.target.zone.point)
            local cas_helo = getMissionOfType(ZoneCommand.missionTypes.cas_helo, objective.assignedResources, nil, objective.target.zone.point)
            if not isMissionActive(cas) and not isMissionActive(cas_helo) then
                local activated = createMission(objective, ZoneCommand.missionTypes.cas_helo, self.side, cas_helo)
                if not activated then
                    createMission(objective, ZoneCommand.missionTypes.cas, self.side, cas)
                end
            end

            --env.info("Cameron - processObjective: "..objective.target.name.." has radar, requesting assault")
            ensureMission(objective, ZoneCommand.missionTypes.assault, self.side)
        else
            if objective.target.side ~= 0 and objective.target.side ~= self.side then
                --env.info("Cameron - processObjective: "..objective.target.name.." is enemy, requesting cap")
                ensureMission(objective, ZoneCommand.missionTypes.patrol, self.side)

                if objective.target:hasEnemyDefense(self.side) then
                    --env.info("Cameron - processObjective: "..objective.target.name.." has defenses, requesting cas")
                    local cas = getMissionOfType(ZoneCommand.missionTypes.cas, objective.assignedResources, nil, objective.target.zone.point)
                    local cas_helo = getMissionOfType(ZoneCommand.missionTypes.cas_helo, objective.assignedResources, nil, objective.target.zone.point)

                    if not isMissionActive(cas) and not isMissionActive(cas_helo) then
                        local activated = createMission(objective, ZoneCommand.missionTypes.cas_helo, self.side, cas_helo)
                        if not activated then
                            createMission(objective, ZoneCommand.missionTypes.cas, self.side, cas)
                        end
                    end

                    --env.info("Cameron - processObjective: "..objective.target.name.." has defenses, requesting assault")
                    ensureMission(objective, ZoneCommand.missionTypes.assault, self.side)
                end

                if objective.target:hasEnemyStructure(self.side) then
                    --env.info("Cameron - processObjective: "..objective.target.name.." has structures, requesting sead")
                    ensureMission(objective, ZoneCommand.missionTypes.strike, self.side)
                end
            elseif objective.target.side == 0 then
                --env.info("Cameron - processObjective: "..objective.target.name.." is neutral, requesting cap")
                ensureMission(objective, ZoneCommand.missionTypes.patrol, self.side)

                if objective.target:hasEnemyDefense(self.side) then
                    --env.info("Cameron - processObjective: "..objective.target.name.." has defenses, requesting cas")
                    local cas = getMissionOfType(ZoneCommand.missionTypes.cas, objective.assignedResources, nil, objective.target.zone.point)
                    local cas_helo = getMissionOfType(ZoneCommand.missionTypes.cas_helo, objective.assignedResources, nil, objective.target.zone.point)

                    if not isMissionActive(cas) and not isMissionActive(cas_helo) then
                        local activated = createMission(objective, ZoneCommand.missionTypes.cas_helo, self.side, cas_helo)
                        if not activated then
                            createMission(objective, ZoneCommand.missionTypes.cas, self.side)
                        end
                    end

                    --env.info("Cameron - processObjective: "..objective.target.name.." has defenses, requesting capture")
                    local assault = getMissionOfType(ZoneCommand.missionTypes.assault, objective.assignedResources, nil, objective.target.zone.point)
                    local sup_convoy = getMissionOfType(ZoneCommand.missionTypes.supply_convoy, objective.assignedResources, nil, objective.target.zone.point)
                    local sup_air = getMissionOfType(ZoneCommand.missionTypes.supply_air, objective.assignedResources, nil, objective.target.zone.point)

                    if not isMissionActive(assault) and not isMissionActive(sup_convoy) and not isMissionActive(sup_air) then
                        createMission(objective, ZoneCommand.missionTypes.assault, self.side)
                    end
                else
                    --env.info("Cameron - processObjective: "..objective.target.name.." does not have defenses, requesting capture")
                    local assault = getMissionOfType(ZoneCommand.missionTypes.assault, objective.assignedResources, nil, objective.target.zone.point)
                    local sup_convoy = getMissionOfType(ZoneCommand.missionTypes.supply_convoy, objective.assignedResources, nil, objective.target.zone.point)
                    local sup_air = getMissionOfType(ZoneCommand.missionTypes.supply_air, objective.assignedResources, nil, objective.target.zone.point)

                    if not isMissionActive(sup_convoy) and not isMissionActive(sup_air) and not isMissionActive(assault) then
                        --env.info("Cameron - processObjective: "..objective.target.name.." nothing on route, requesting air supply")
                        local activated = createMission(objective, ZoneCommand.missionTypes.supply_air, self.side)
                        if not activated then
                            --env.info("Cameron - processObjective: "..objective.target.name.." no air, requesting convoy")
                            createMission(objective, ZoneCommand.missionTypes.supply_convoy, self.side)
                        end
                    end
                end
            end
        end
    end

    function Cameron:createObjective(viableAttack)
        local existing = {}
        for _,v in ipairs(self.objectives) do
            existing[v.target.name]=true
        end

        local captureable = {}
        local attackable = {}
        for _,v in ipairs(viableAttack) do
            if not existing[v.name] then
                if v.side == 0 then
                    table.insert(captureable, v)
                elseif v.side ~= self.side then
                    table.insert(attackable, v)
                end
            end
        end

        local pick = nil
        if #captureable > 0 then
            pick = captureable[math.random(1, #captureable)]
        end

        if not pick then
            pick = attackable[math.random(1,#attackable)]
        end

        if pick then
            return {
                target = pick,
                requestedResources = {},
                assignedResources = {},
                ticks = 0
            }
        else
            return
        end
    end
end

