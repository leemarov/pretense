
AIActivator = {}

do
	local function teleportToPos(groupName, pos)
		if pos.y == nil then
			pos.y = land.getHeight({ x = pos.x, y = pos.z })
		end

		local vars = {
			groupName = groupName,
			point = pos,
			action = 'respawn',
			initTasks = false
		}

		mist.teleportToPoint(vars)
	end

    local function getDefaultPos(savedData, isAir)
		local action = 'Off Road'
		local speed = 0
		if isAir then
			action = 'Turning Point'
			speed = 250
		end

		local vars = {
			groupName = savedData.productName,
			point = savedData.position,
			action = 'respawn',
			heading = savedData.heading,
			initTasks = false,
			route = { 
				[1] = {
					alt = savedData.position.y,
					type = 'Turning Point',
					action = action,
					alt_type = 'BARO',
					x = savedData.position.x,
					y = savedData.position.z,
					speed = speed
				}
			}
		}

		return vars
	end

    function AIActivator.reAssignMission(product, target)
        local g = DependencyManager.get("GroupMonitor"):getGroup(product.name)
        if not g then return false end
        
        local success = AIActivator.activateMission(product, target, { 
            productName = product.name,
            ownerName = product.owner.name,
            type = product.missionType,
            lastMission = { zoneName = target.name },
            spawnedSquad = g.spawnedSquad,
            targetName = target.name,
            homeName = product.owner.name,
            state = g.state,
            lastStateDuration = g.lastStateTime,
            supressSpawn = true
        })

        return success
    end

    function AIActivator.activateMission(product, target, saveData)
        local homePos = nil
        local deductCost = false

        local supplyTypes = {
            [ZoneCommand.missionTypes.supply_air] = 'air',
            [ZoneCommand.missionTypes.supply_convoy] = 'convoy',
            [ZoneCommand.missionTypes.supply_transfer] = 'transfer',
        }

        if not saveData and supplyTypes[product.missionType] then
            if not product.owner:canSupply(target, supplyTypes[product.missionType], product.capacity) then 
                env.info("AIActivator - activateMission "..product.owner.name.." can not afford "..product.capacity.." for "..product.name)
                return false 
            end
        end
        
        if product.missionType~=ZoneCommand.missionTypes.supply_transfer then
            if saveData then
                if not saveData.supressSpawn then
                    mist.teleportToPoint(getDefaultPos(saveData, true))
                end

                if saveData.lastMission.zoneName then
                    target = ZoneCommand.getZoneByName(saveData.lastMission.zoneName)
                elseif saveData.lastMission.baiTargets then
                    target = { baiTargets = {} }
                    for i,v in pairs(saveData.lastMission.baiTargets) do
                        target.baiTargets[i] = ZoneCommand.getZoneByName(v.ownerName):getProductByName(v.productName)
                    end
                end

                if saveData.homeName then
                    local hPos = trigger.misc.getZone(saveData.homeName).point
                    homePos = {homePos = hPos}
                end
            else
                local og = Utils.getOriginalGroup(product.name)
                if og then
                    teleportToPos(product.name, {x=og.x, z=og.y})
                    env.info("AIActivator - activateMission teleporting to OG pos")
                else
                    mist.respawnGroup(product.name, true)
                    env.info("AIActivator - activateMission fallback to respawnGroup")
                end

                deductCost = true
            end

            
            if target.baiTargets then
                product.lastMission = { baiTargets = {} }
                for i,v in pairs(target.baiTargets) do
                    product.lastMission.baiTargets[i] = { productName=v.name, ownerName=v.owner.name }
                end

                DependencyManager.get("GroupMonitor"):registerGroup(product, nil, product.owner, saveData)
            else
                product.lastMission = {zoneName = target.name}
                DependencyManager.get("GroupMonitor"):registerGroup(product, target, product.owner, saveData)
            end
        end

        if product.missionType==ZoneCommand.missionTypes.supply_convoy then
            AIActivator.activateSupplyConvoyMission(product, target, deductCost)
        elseif product.missionType==ZoneCommand.missionTypes.supply_air then
            AIActivator.activateAirSupplyMission(product, target, deductCost)
        elseif product.missionType==ZoneCommand.missionTypes.supply_transfer then
            AIActivator.activateSupplyTransfer(product, target)
        elseif product.missionType==ZoneCommand.missionTypes.patrol then
            AIActivator.activatePatrolMission(product, target, homePos)
        elseif product.missionType==ZoneCommand.missionTypes.cas then
            if target.baiTargets then
                AIActivator.activateBaiMission(product, target, homePos)
            else
                AIActivator.activateCasMission(product, target, homePos)
            end
        elseif product.missionType==ZoneCommand.missionTypes.cas_helo then
            AIActivator.activateCasMission(product, target, homePos)
        elseif product.missionType==ZoneCommand.missionTypes.sead then
            AIActivator.activateSeadMission(product, target, homePos)
        elseif product.missionType==ZoneCommand.missionTypes.strike then
            AIActivator.activateStrikeMission(product, target, homePos)
        elseif product.missionType==ZoneCommand.missionTypes.assault then
            AIActivator.activateAssaultMission(product, target)
        elseif product.missionType==ZoneCommand.missionTypes.awacs then
            AIActivator.activateAwacsMission(product, target, homePos)
        elseif product.missionType==ZoneCommand.missionTypes.tanker then
            AIActivator.activateTankerMission(product, target, homePos)
        end

        env.info("AIActivator - "..product.missionType.." - "..product.name.." from "..product.owner.name.." targeting "..target.name)

        return true
    end

    function AIActivator.activateTankerMission(product, target, homePos)
        timer.scheduleFunction(function(param)
			local gr = Group.getByName(param.prod.name)
			if gr then
				local un = gr:getUnit(1)
				if un then 
					local callsign = un:getCallsign()
					RadioFrequencyTracker.registerRadio(param.prod.name, '[Tanker('..param.prod.variant..')] '..callsign, param.prod.freq..' AM | TCN '..param.prod.tacan..'X')
				end

				local point = trigger.misc.getZone(param.target.name).point
				product.lastMission = { zoneName = param.target.name }
				TaskExtensions.executeTankerMission(gr, point, param.prod.altitude, param.prod.freq, param.prod.tacan, param.homePos)
			end
		end, {prod=product, target=target, homePos = homePos}, timer.getTime()+1)
    end

    function AIActivator.activateAwacsMission(product, target, homePos)
        timer.scheduleFunction(function(param)
			local gr = Group.getByName(param.prod.name)
			if gr then
				local un = gr:getUnit(1)
				if un then 
					local callsign = un:getCallsign()
					RadioFrequencyTracker.registerRadio(param.prod.name, '[AWACS] '..callsign, param.prod.freq..' AM')
				end

				local point = trigger.misc.getZone(param.target.name).point
				product.lastMission = { zoneName = param.target.name }
				TaskExtensions.executeAwacsMission(gr, point, param.prod.altitude, param.prod.freq, param.homePos)
				
			end
		end, {prod=product, target=target, homePos = homePos}, timer.getTime()+1)
    end

    function AIActivator.activateBaiMission(product, target, homePos)
        timer.scheduleFunction(function(param)
            local gr = Group.getByName(param.prod.name)
            TaskExtensions.executeBaiMission(gr, param.targets, param.prod.expend, param.prod.altitude, param.homePos)
        end, {prod=product, targets=target.baiTargets, homePos = homePos}, timer.getTime()+1)
    end
    
    function AIActivator.activateAssaultMission(product, target)
		local tgtPoint = trigger.misc.getZone(target.name)
        timer.scheduleFunction(function(param)
            local gr = Group.getByName(param.name)
            TaskExtensions.moveOnRoadToPointAndAssault(gr, param.point, param.targets)
        end, {name=product.name, point={ x=tgtPoint.point.x, y = tgtPoint.point.z}, targets=target.built}, timer.getTime()+1)
    end

    function AIActivator.activateStrikeMission(product, target, homePos)
        timer.scheduleFunction(function(param)
            local gr = Group.getByName(param.prod.name)
            TaskExtensions.executeStrikeMission(gr, param.targets, param.prod.expend, param.prod.altitude, param.homePos)
        end, {prod=product, targets=target.built, homePos = homePos}, timer.getTime()+1)
    end
    
    function AIActivator.activateSeadMission(product, target, homePos)
        timer.scheduleFunction(function(param)
            local gr = Group.getByName(param.prod.name)
            TaskExtensions.executeSeadMission(gr, param.targets, param.prod.expend, param.prod.altitude, param.homePos)
        end, {prod=product, targets=target.built, homePos = homePos}, timer.getTime()+1)
    end

    function AIActivator.activateCasMission(product, target, homePos)
        local ishelo = product.missionType == ZoneCommand.missionTypes.cas_helo
        timer.scheduleFunction(function(param)
            local gr = Group.getByName(param.prod.name)
            if param.helo then
                TaskExtensions.executeHeloCasMission(gr, param.targets, param.prod.expend, param.prod.altitude, param.homePos)
            else
                TaskExtensions.executeCasMission(gr, param.targets, param.prod.expend, param.prod.altitude, param.homePos)
            end
        end, {prod=product, targets=target.built, helo = ishelo, homePos = homePos}, timer.getTime()+1)
    end

    function AIActivator.activatePatrolMission(product, target, homePos)
        timer.scheduleFunction(function(param)
            local gr = Group.getByName(param.prod.name)

            local point = trigger.misc.getZone(param.target.name).point

            TaskExtensions.executePatrolMission(gr, point, param.prod.altitude, param.prod.range, param.home)
        end, {prod=product, target = target, home=homePos}, timer.getTime()+1)
    end

    function AIActivator.activateSupplyTransfer(product, target)
        product.owner:removeResource(product.capacity)
        target:addResource(product.capacity)
		env.info('AIActivator - activateSupplyTransfer - '..product.owner.name..' transfered '..product.capacity..' to '..target.name)
    end

    function AIActivator.activateAirSupplyMission(product, target, deductCost)

        local supplyPoint = trigger.misc.getZone(target.name..'-hsp')
        if not supplyPoint then
            supplyPoint = trigger.misc.getZone(target.name)
        end

        if supplyPoint then 
            if deductCost then
                product.owner:removeResource(product.capacity)
            end

            local alt = DependencyManager.get("ConnectionManager"):getHeliAlt(product.owner.name, target.name)
            timer.scheduleFunction(function(param)
                local gr = Group.getByName(param.name)
                TaskExtensions.landAtPoint(gr, param.point, param.alt)
            end, {name=product.name, point={ x=supplyPoint.point.x, y = supplyPoint.point.z}, alt = alt}, timer.getTime()+1)
        end
    end

    function AIActivator.activateSupplyConvoyMission(product, target, deductCost)

        local supplyPoint = trigger.misc.getZone(target.name..'-sp')
        if not supplyPoint then
            supplyPoint = trigger.misc.getZone(target.name)
        end
        
        if supplyPoint then 
            if deductCost then
                product.owner:removeResource(product.capacity)
            end

            product.lastMission = {zoneName = target.name}
            timer.scheduleFunction(function(param)
                local gr = Group.getByName(param.name)
                TaskExtensions.moveOnRoadToPoint(gr, param.point)
            end, {name=product.name, point={ x=supplyPoint.point.x, y = supplyPoint.point.z}}, timer.getTime()+1)
        end
    end
end

