



CommandFunctions = {}

do
    CommandFunctions.jtac = nil

    function CommandFunctions.spawnJtac(zone)
        if CommandFunctions.jtac then
            CommandFunctions.jtac:deployAtZone(zone)
            CommandFunctions.jtac:showMenu()
            CommandFunctions.jtac:setLifeTime(60)
            zone:reveal(60)
            DependencyManager.get("ReconManager"):revealEnemyInZone(zone, nil, 1, 0.5)
        end
    end

    function CommandFunctions.smokeTargets(zone, count)
        local units = {}
        for i,v in pairs(zone.built) do
            local g = Group.getByName(v.name)
            if g and g:isExist() then
                for i2,v2 in ipairs(g:getUnits()) do
                    if v2:isExist() then
                        table.insert(units, v2)
                    end
                end
            else
                local s = StaticObject.getByName(v.name)
                if s and s:isExist() then
                    table.insert(units, s)
                end
            end
        end
        
        local tgts = {}
        for i=1,count,1 do
            if #units > 0 then
                local selected = math.random(1,#units)
                table.insert(tgts, units[selected])
                table.remove(units, selected)
            end
        end
        
        for i,v in ipairs(tgts) do
            local pos = v:getPoint()
            trigger.action.smoke(pos, 1)
        end
    end

    function CommandFunctions.sabotageZone(zone)
        trigger.action.outText("Saboteurs have been dispatched to "..zone.name, 10)
        local delay = math.random(5*60, 7*60)
        local isReveled = zone.revealTime > 0
        timer.scheduleFunction(function(param, time)
            if not param.isRevealed then
                if math.random() < 0.3 then
                    trigger.action.outText("Saboteurs have been caught by the enemy before they could complete their mission", 10)
                    return
                end
            end

            local zone = param.zone
            local units = {}
            for i,v in pairs(zone.built) do
                if v.type == 'upgrade' then
                    local s = StaticObject.getByName(v.name)
                    if s and s:isExist() then
                        table.insert(units, s)
                    end
                end
            end
            
            if #units > 0 then
                local selected = units[math.random(1,#units)]

                timer.scheduleFunction(function(p2, t2)
                    if p2.count > 0 then
                        p2.count = p2.count - 1
                        local offsetPos = {
                            x = p2.pos.x + math.random(-25,25),
                            y = p2.pos.y,
                            z = p2.pos.z + math.random(-25,25)
                        }
            
                        offsetPos.y = land.getHeight({x = offsetPos.x, y = offsetPos.z})
                        trigger.action.explosion(offsetPos, 30)
                        return t2 + 0.05 + (math.random())
                    else
                        trigger.action.explosion(p2.pos, 2000)
                    end
                end, {count = 3, pos = selected:getPoint()}, timer.getTime()+0.5)

                trigger.action.outText("Saboteurs have succesfully triggered explosions at "..zone.name, 10)
            end
        end, { zone = zone , isRevealed = isReveled}, timer.getTime()+delay)
    end

    function CommandFunctions.shellZone(zone, count)
        local minutes = math.random(3,7)
        local seconds = math.random(-30,30)
        local delay = (minutes*60)+seconds

        local isRevealed = zone.revealTime > 0
        trigger.action.outText("Artillery preparing to fire on "..zone.name.." ETA: "..minutes.." minutes", 10)
        
        local positions = {}
        for i,v in pairs(zone.built) do
            local g = Group.getByName(v.name)
            if g and g:isExist() then
                for i2,v2 in ipairs(g:getUnits()) do
                    if v2:isExist() then
                        table.insert(positions, v2:getPoint())
                    end
                end
            else
                local s = StaticObject.getByName(v.name)
                if s and s:isExist() then
                    table.insert(positions, s:getPoint())
                end
            end
        end

        timer.scheduleFunction(function(param, time)
            trigger.action.outText("Artillery firing on "..param.zone.name.." ETA: 30 seconds", 10)
        end, {zone = zone}, timer.getTime()+delay-30)

        timer.scheduleFunction(function(param, time)
            param.count = param.count - 1
            
            local accuracy = 50
            if param.isRevealed then
                accuracy = 10
            end

            local selected = param.positions[math.random(1,#param.positions)]
            local offsetPos = {
                x = selected.x + math.random(-accuracy,accuracy),
                y = selected.y,
                z = selected.z + math.random(-accuracy,accuracy)
            }

            offsetPos.y = land.getHeight({x = offsetPos.x, y = offsetPos.z})

            trigger.action.explosion(offsetPos, 20)

            if param.count > 0 then
                return time+0.05+(math.random()*2)
            else
                trigger.action.outText("Artillery finished firing on "..param.zone.name, 10)
            end
        end, { positions = positions, count = count, zone = zone, isRevealed = isRevealed}, timer.getTime()+delay)
    end
end

