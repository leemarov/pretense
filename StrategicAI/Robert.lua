
Robert = AIBase:new() -- randomly assignes builds and tasking, same as old Pretense AI

do
    function Robert:createState()
        self.deployChance = 0.7
    end

    function Robert:makeDecissions()
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
                    if v.distToFront~=nil and v.distToFront <= 1 then
                        add(viableAttack, v)
                    end
                end

                if v.distToFront <= 1 then
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

        self:decideBuilds(canBuild)
        self:decideDefensive(viableDefend)
        self:decideOffensive(viableAttack)
        self:decideSupports(viableSupports)
        self:decideSupplies(needsSupplies)

        if self.createMissions then
            DependencyManager.get("MissionTracker"):fillEmptySlots()
        end
    end

    function Robert:decideBuilds(buildableZones)
        local supplyTypes = {
            [ZoneCommand.missionTypes.supply_air] = true,
            [ZoneCommand.missionTypes.supply_convoy] = true,
            [ZoneCommand.missionTypes.supply_transfer] = true,
        }

        for _,z in ipairs(buildableZones) do
            if z:canBuild() then
                local canAfford = {}
                for _,v in ipairs(z.upgrades[z.side]) do
                    local isBuilt = StrategicAI.isProductBuilt(v)

                    if not isBuilt then
                        if z:canBuildProduct(v) then
                            table.insert(canAfford, {product = v, reason='upgrade'})
                        end
                    else
                        for _,v2 in ipairs(v.products) do
                            if z:canBuildProduct(v2) then
                                if v2.type == 'mission' and not z:criticalOnSupplies() then
                                    if v2.missionType == ZoneCommand.missionTypes.supply_transfer then
                                        if z.distToFront > 1 then
                                            table.insert(canAfford, {product = v2, reason='mission'})
                                        end
                                    elseif v2.missionType == ZoneCommand.missionTypes.supply_air or v2.missionType == ZoneCommand.missionTypes.supply_convoy then
                                        if z.distToFront <= 1 then
                                            table.insert(canAfford, {product = v2, reason='mission'})
                                        end
                                    end
                                elseif v2.type=='defense' and z.mode ~='export' and z.mode ~='supply' and v2.cost > 0 then
                                    local g = Group.getByName(v2.name)
                                    if not g then
                                        table.insert(canAfford, {product = v2, reason='defense'})
                                    elseif g:getSize() < (g:getInitialSize()*math.random(40,100)/100) then
                                        table.insert(canAfford, {product = v2, reason='repair'})
                                    end
                                end
                            end
                        end
                    end
                end

                if #canAfford > 0 then
                    local choice = math.random(1, #canAfford)
                    
                    if canAfford[choice] then
                        local p = canAfford[choice]
                        if p.reason == 'repair' then
                            z:queueBuild(p.product, true)
                        else
                            z:queueBuild(p.product)
                        end
                    end
                end
            end

            if z:canMissionBuild() and not z:criticalOnSupplies() then
                local canMission = {}
                for _,v in ipairs(z.upgrades[z.side]) do
                    if StrategicAI.isProductBuilt(v) then
                        for _,v2 in ipairs(v.products) do
                            if z:canBuildProduct(v2) and not StrategicAI.isProductBuilt(v2) and v2.type == 'mission' then 
                                if not supplyTypes[v2.missionType] then
                                    if v2.missionType ~= ZoneCommand.missionTypes.assault or z.distToFront==0 then
                                        if math.random() < ZoneCommand.missionValidChance then
                                            table.insert(canMission, {product = v2, reason='mission'})
                                        end
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
    end

    function Robert:decideSupplies(zonesToSupply)
        if #zonesToSupply == 0 then return end

        local supplyTypes = {
            [ZoneCommand.missionTypes.supply_air] = true,
            [ZoneCommand.missionTypes.supply_convoy] = true,
            [ZoneCommand.missionTypes.supply_transfer] = true,
        }

        for _,z in ipairs(zonesToSupply) do
            local sources = {}
            for _,v in pairs(StrategicAI.resources[self.side]) do
                if supplyTypes[v.missionType] then
                    table.insert(sources, v)
                end
            end
            
            local simulated = z.distToFront > 1

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
                    if n.owner:canSupply(z, stype, n.capacity) then
                        pick = n
                    end
                else
                    if n.owner:canSupply(z, stype, n.capacity) and n.owner.resource > pick.owner.resource then
                        pick = n
                    end
                end
            end

            if pick then
                StrategicAI.activateMission(pick, z)
            end
        end
    end

    function Robert:decideDefensive(zonesToDefend)
        if #zonesToDefend == 0 then return end

        for _,v in pairs(StrategicAI.resources[self.side]) do
            if math.random() < self.deployChance then
                if v.missionType == ZoneCommand.missionTypes.patrol then
                    local choice = zonesToDefend[math.random(1, #zonesToDefend)]
                    StrategicAI.activateMission(v, choice)
                end
            end
        end
    end

    function Robert:decideOffensive(zonesToAttack)
        if #zonesToAttack == 0 then return end

        local captureable = {}
        local attackable = {}
        for _,v in ipairs(zonesToAttack) do
            if v.side == 0 then
                table.insert(captureable, v)
            elseif v.side ~= self.side then
                table.insert(attackable, v)
            end
        end

        for _,v in pairs(StrategicAI.resources[self.side]) do
            if math.random() < self.deployChance then
                if v.missionType == ZoneCommand.missionTypes.supply_air then
                    local viable = {}
                    for _, z in ipairs(captureable) do
                        if v.owner:canSupply(z, 'air', v.capacity) then
                            table.insert(viable, z)
                        end
                    end

                    if #viable > 0 then
                        StrategicAI.activateMission(v, viable[math.random(1,#viable)])
                    end
                elseif v.missionType == ZoneCommand.missionTypes.supply_convoy then
                    local viable = {}
                    for _, z in ipairs(captureable) do
                        if v.owner:canSupply(z, 'convoy', v.capacity) then
                            table.insert(viable, z)
                        end
                    end

                    if #viable > 0 then
                        StrategicAI.activateMission(v, viable[math.random(1,#viable)])
                    end
                elseif v.missionType == ZoneCommand.missionTypes.cas then
                    if math.random() < 0.3 then
                        local tggroups = {}
                        for _,tgt in pairs(DependencyManager.get("GroupMonitor").groups) do
                            if v.side ~= tgt.product.side and 
                                (tgt.product.missionType == ZoneCommand.missionTypes.assault or tgt.product.missionType == ZoneCommand.missionTypes.supply_convoy) then 
                                    local gr = Group.getByName(tgt.name)
                                    if gr and gr:isExist() and gr:getSize()>0 then
                                        local un = gr:getUnit(1)
                                        if un and un:isExist() then
                                            local dist = mist.utils.get2DDist(v.owner.zone.point, un:getPoint())
                                            if dist < 60000 then
                                                table.insert(tggroups, {product = v, dist = dist})
                                            end
                                        end
                                    end
                            end
                        end

                        table.sort(tggroups, function(a,b)
                            return a.dist < b.dist
                        end)

                        local targets = {}
                        local count = 0
                        for i,v in ipairs(tggroups) do
                            targets[v.product.name] = v.product
                            count = count + 1
                            if count >=3 then break end
                        end

                        if count > 0 then
                            StrategicAI.activateMission(v, { baiTargets = targets})
                        end
                    else
                        local viable = {}
                        for _,z in ipairs(attackable) do
                            if z.distToFront == 0 and not z:hasEnemySAMRadar(v.side) and z:hasEnemyDefense(v.side) then
                            table.insert(viable, z)
                            end
                        end

                        if #viable > 0 then
                            StrategicAI.activateMission(v, viable[math.random(1,#viable)])
                        end
                    end
                elseif v.missionType == ZoneCommand.missionTypes.cas_helo then
                    local viable = {}
                    for _,z in ipairs(attackable) do
                        if z.distToFront == 0 and not z:hasEnemySAMRadar(v.side) and z:hasEnemyDefense(v.side) and v.owner:canAttack(z, 'cas_helo') then
                        table.insert(viable, z)
                        end
                    end
                    
                    if #viable > 0 then
                        StrategicAI.activateMission(v, viable[math.random(1,#viable)])
                    end
                elseif v.missionType == ZoneCommand.missionTypes.strike then
                    local viable = {}
                    for _,z in ipairs(attackable) do
                        if z.distToFront == 0 and not z:hasEnemySAMRadar(v.side) and z:hasEnemyStructure(v.side) then
                        table.insert(viable, z)
                        end
                    end
                    
                    if #viable > 0 then
                        StrategicAI.activateMission(v, viable[math.random(1,#viable)])
                    end
                elseif v.missionType == ZoneCommand.missionTypes.sead then
                    local viable = {}
                    for _,z in ipairs(attackable) do
                        if z.distToFront <= 1 and z:hasEnemySAMRadar(v.side) then
                        table.insert(viable, z)
                        end
                    end
                    
                    if #viable > 0 then
                        StrategicAI.activateMission(v, viable[math.random(1,#viable)])
                    end
                elseif v.missionType == ZoneCommand.missionTypes.assault then
                    local viable = {}
                    for _,z in ipairs(attackable) do
                        if v.owner:isNeighbour(z) and not DependencyManager.get("ConnectionManager"):isRoadBlocked(v.owner.name, z.name) then
                        table.insert(viable, z)
                        end
                    end
                    
                    if #viable > 0 then
                        StrategicAI.activateMission(v, viable[math.random(1,#viable)])
                    end
                end
            end
        end
    end

    function Robert:decideSupports(zonesToSupport)
        if #zonesToSupport == 0 then return end

        for _,v in pairs(StrategicAI.resources[self.side]) do
            if math.random() < self.deployChance then
                if v.missionType == ZoneCommand.missionTypes.awacs or v.missionType == ZoneCommand.missionTypes.tanker then
                    local choice = zonesToSupport[math.random(1, #zonesToSupport)]
                    StrategicAI.activateMission(v, choice)
                end
            end
        end
    end
end

