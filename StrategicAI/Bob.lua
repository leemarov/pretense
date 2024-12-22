
Bob = Robert:new() -- same as robert, but doesnt use CAP

do
    function Bob:makeDecissions()
        local viableAttack = {}
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
        self:decideOffensive(viableAttack)
        self:decideSupports(viableSupports)
        self:decideSupplies(needsSupplies)
        
        if self.createMissions then
            DependencyManager.get("MissionTracker"):fillEmptySlots()
        end
    end

    function Bob:decideBuilds(buildableZones)
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
                                if not supplyTypes[v2.missionType] and v2.missionType~=ZoneCommand.missionTypes.patrol then
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
end

