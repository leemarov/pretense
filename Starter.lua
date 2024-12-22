
Starter = {}
do
    Starter.neutralChance = 0.1

    function Starter.start(zones)
        if Starter.shouldRandomize() then
            Starter.randomize(zones)
        else
            Starter.normalStart(zones)
        end
    end

    function Starter.randomize(zones)
        local startZones = {}
        for _,z in pairs(zones) do
            if z.isHeloSpawn and z.isPlaneSpawn then
                table.insert(startZones, z)
            end
        end

        if #startZones > 0 then
            local sz = startZones[math.random(1,#startZones)]

            sz:capture(2, true)
            Starter.captureNeighbours(sz, math.random(1,3))
        end

        for _,z in pairs(zones) do
            if z.side == 0 then 
                if math.random() > Starter.neutralChance then
                    z:capture(1,true)
                end
            end

            if z.side ~= 0 then
                z:fullUpgrade(math.random(1,30)/100)
            end
        end
    end

    function Starter.captureNeighbours(zone, stepsLeft)
        if stepsLeft > 0 then
            for _,v in pairs(zone.neighbours) do
                if v.side == 0 then
                    if math.random() > Starter.neutralChance then
                        v:capture(2,true)
                    end
                    Starter.captureNeighbours(v, stepsLeft-1)
                end
            end
        end
    end

    function Starter.shouldRandomize()
        if lfs then
            local filename = lfs.writedir()..'Missions/Saves/randomize.lua'
            if lfs.attributes(filename) then
                return true
            end
		end
    end

    function Starter.normalStart(zones)
        for _,z in pairs(zones) do
            local i = z.initialState
            if i then
                if i.side and i.side ~= 0 then
                    z:capture(i.side, true)
                    z:fullUpgrade()
                    z:boostProduction(math.random(1,200))
                end
            else
                z:setSide(0)
            end
        end
    end
end

