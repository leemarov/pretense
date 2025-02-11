



StrategicAI = {}

do
    StrategicAI.resources = {
        [1] = {},
        [2] = {}
    }

    function StrategicAI.start()
        env.info("StrategicAI - starting")
        StrategicAI.blueAI = Cameron:new(2, true)
        StrategicAI.redAI = Cameron:new(1)
        timer.scheduleFunction(function(param,time)
            env.info('StrategicAI - culling invalid resources')

            for i,v in ipairs(StrategicAI.resources) do
                for i2,v2 in pairs(v) do
                    if v2.owner.side ~= v2.side then
                        v[i2] = nil
                        env.info('StrategicAI - removed '..v2.name..' as owner zone is no longer same side')
                    end
                end
            end

            env.info('StrategicAI - making decissions')
            StrategicAI.blueAI:makeDecissions()
            StrategicAI.redAI:makeDecissions()

            return time + 10
        end, nil, timer.getTime()+10)
    end

    function StrategicAI.activateMission(product, target)
		env.info('StrategicAI.activateMission - activating mission '..product.name..'('..product.display..')')
        local success = AIActivator.activateMission(product, target)
        if success then
            StrategicAI.resources[product.side][product.name] = nil
        else
		    env.info('StrategicAI.activateMission - failed to activate '..product.name..'('..product.display..')')
        end

        return success
	end

    function StrategicAI.isProductBuilt(product)
        local u = Group.getByName(product.name)
		if not u then u = StaticObject.getByName(product.name) end

        if u then return true end
        
        if StrategicAI.getResourceByName(product.name, product.side) then return true end
    end

    function StrategicAI.getResourceByName(name, side)
        if side then
            return StrategicAI.resources[side][name] 
        end

        if StrategicAI.resources[1][name] then return StrategicAI.resources[1][name] end
        if StrategicAI.resources[2][name] then return StrategicAI.resources[2][name] end
    end

    function StrategicAI.pushResource(product)
        env.info("StrategicAI - new mission available to deploy: "..product.name)
        local restable = StrategicAI.resources[product.side]
        restable[product.name] = product
    end

    function StrategicAI.tapResource(product)
        StrategicAI.resources[product.side][name]=nil
        env.info("StrategicAI - "..product.name.." tapped for use")
    end
end

