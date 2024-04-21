
Spawner = {}

do
    function Spawner.createPilot(name, pos)
        local groupData = Spawner.getData("pilot-replacement", name, pos, nil, 5, {
            [land.SurfaceType.LAND] = true, 
            [land.SurfaceType.ROAD] = true,
            [land.SurfaceType.RUNWAY] = true,
        })

        return coalition.addGroup(country.id.CJTF_BLUE, Group.Category.GROUND, groupData)
    end

    function Spawner.createObject(name, objType, pos, side, minDist, maxDist, surfaceTypes, zone)
        if zone then
            zone = CustomZone:getByName(zone) -- expand zone name to CustomZone object
        end

        local data = Spawner.getData(objType, name, pos, minDist, maxDist, surfaceTypes, zone)

        if not data then return end

        local cnt = country.id.CJTF_BLUE
        if side == 1 then
            cnt = country.id.CJTF_RED
        end

        if data.dataCategory == TemplateDB.type.static then
            return coalition.addStaticObject(cnt, data)
        elseif data.dataCategory == TemplateDB.type.group then
            return coalition.addGroup(cnt, Group.Category.GROUND, data)
        end
    end

    function Spawner.getUnit(unitType, name, pos, skill, minDist, maxDist, surfaceTypes, zone)
        local nudgedPos = nil
		for i=1,500,1 do
            nudgedPos = mist.getRandPointInCircle(pos, maxDist, minDist)
           
            if zone then
                if zone:isInside(nudgedPos) and surfaceTypes[land.getSurfaceType(nudgedPos)] then
                    break
                end
            else
                if surfaceTypes[land.getSurfaceType(nudgedPos)] then
                    break
                end
            end

            if i==500 then env.info('Spawner - ERROR: failed to find good location') end
		end

        return {
            ["type"] = unitType,
            ["skill"] = skill,
            ["coldAtStart"] = false,
            ["x"] = nudgedPos.x,
            ["y"] = nudgedPos.y,
            ["name"] = name,
            ['heading'] = math.random()*math.pi*2,
            ["playerCanDrive"] = false
        }
    end

    function Spawner.getData(objtype, name, pos, minDist, maxDist, surfaceTypes, zone)
        if not maxDist then maxDist = 150 end
        if not surfaceTypes then surfaceTypes = { [land.SurfaceType.LAND]=true } end

        local data = TemplateDB.getData(objtype)
        if not data then 
            env.info("Spawner - ERROR: cant find group data "..tostring(objtype).." for group name "..name)
            return
        end

        local spawnData = {}

        if data.dataCategory == TemplateDB.type.static then
            if not surfaceTypes[land.getSurfaceType(pos)] then
                for i=1,500,1 do
                    pos = mist.getRandPointInCircle(pos, maxDist)

                    if zone then
                        if zone:isInside(pos) and surfaceTypes[land.getSurfaceType(pos)] then
                            break
                        end
                    else
                        if surfaceTypes[land.getSurfaceType(pos)] then
                            break
                        end
                    end
                    
                    if i==500 then env.info('Spawner - ERROR: failed to find good location') end
                end
            end

            spawnData = {
                ["type"] = data.type,
                ["name"] = name,
                ["shape_name"] = data.shape,
                ["category"] = data.category,
                ["x"] = pos.x,
                ["y"] = pos.y,
                ['heading'] = math.random()*math.pi*2
            }
        elseif data.dataCategory== TemplateDB.type.group then
            spawnData = {
                ["units"] = {},
                ["name"] = name,
                ["task"] = "Ground Nothing",
                ["route"] = {
                    ["points"]={
                        {
                            ["x"] = pos.x,
                            ["y"] = pos.y,
                            ["action"] = "Off Road",
                            ["speed"] = 0,
                            ["type"] = "Turning Point",
                            ["ETA"] = 0,
                            ["formation_template"] = "",
                            ["task"] = Spawner.getDefaultTask(data.invisible)
                        }
                    }
                }
            }

            if data.minDist then
                minDist = data.minDist
            end

            if data.maxDist then
                maxDist = data.maxDist
            end
            
            for i,v in ipairs(data.units) do
                table.insert(spawnData.units, Spawner.getUnit(v, name.."-"..i, pos, data.skill, minDist, maxDist, surfaceTypes, zone))
            end
        end

        spawnData.dataCategory = data.dataCategory
            
        return spawnData
    end

    function Spawner.getDefaultTask(invisible)
        local defTask =  {
            ["id"] = "ComboTask",
            ["params"] = 
            {
                ["tasks"] = 
                {
                    [1] = 
                    {
                        ["enabled"] = true,
                        ["auto"] = false,
                        ["id"] = "WrappedAction",
                        ["number"] = 1,
                        ["params"] = 
                        {
                            ["action"] = 
                            {
                                ["id"] = "Option",
                                ["params"] = 
                                {
                                    ["name"] = 9,
                                    ["value"] = 2,
                                },
                            },
                        },
                    }, 
                    [2] = 
                    {
                        ["enabled"] = true,
                        ["auto"] = false,
                        ["id"] = "WrappedAction",
                        ["number"] = 2,
                        ["params"] = 
                        {
                            ["action"] = 
                            {
                                ["id"] = "Option",
                                ["params"] = 
                                {
                                    ["name"] = 0,
                                    ["value"] = 0,
                                }
                            }
                        }
                    }
                }
            }
        }

        if invisible then 
            table.insert(defTask.params.tasks, {
                ["number"] = 3,
                ["auto"] = false,
                ["id"] = "WrappedAction",
                ["enabled"] = true,
                ["params"] = 
                {
                    ["action"] = 
                    {
                        ["id"] = "SetInvisible",
                        ["params"] = 
                        {
                            ["value"] = true,
                        }
                    }
                }
            })
        end
        
        return defTask
    end
end

