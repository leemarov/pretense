



GroupMonitor = {}
do
	GroupMonitor.blockedDespawnTime = 10*60 --used to despawn aircraft that are stuck taxiing for some reason
	GroupMonitor.landedDespawnTime = 10
	GroupMonitor.atDestinationDespawnTime = 2*60
	GroupMonitor.recoveryReduction = 0.8 -- reduce recovered resource from landed missions by this amount to account for maintenance

	GroupMonitor.siegeExplosiveTime = 5*60 -- how long until random upgrade is detonated in zone
	GroupMonitor.siegeExplosiveStrength = 1000 -- detonation strength

	GroupMonitor.timeBeforeSquadDeploy = 10*60
	GroupMonitor.squadChance = 0.001
	GroupMonitor.ambushChance = 0.7

	GroupMonitor.aiSquads = {
		ambush = {
			[1] = {
				name='ambush-squad-red', 
				type=PlayerLogistics.infantryTypes.ambush,
				weight = 900,
				cost= 300,
				jobtime= 60*60*2,
				extracttime= 0,
				size = 5,
				side = 1,
				isAISpawned = true
			},
			[2] = {
				name='ambush-squad', 
				type=PlayerLogistics.infantryTypes.ambush,
				weight = 900,
				cost= 300,
				jobtime= 60*60,
				extracttime= 60*60,
				size = 5,
				side = 2,
				isAISpawned = true
			},
		},
		manpads = {
			[1] = {
				name='manpads-squad-red',
				type=PlayerLogistics.infantryTypes.manpads, 
				weight = 900,
				cost= 500,
				jobtime= 60*60*2,
				extracttime= 0,
				size = 5, 
				side= 1,
				isAISpawned = true
			},
			[2] = {
				name='manpads-squad',
				type=PlayerLogistics.infantryTypes.manpads, 
				weight = 900,
				cost= 500,
				jobtime= 60*60,
				extracttime= 60*60,
				size = 5, 
				side= 2,
				isAISpawned = true
			}
		},
		assault = {
			[1] = {
				name='assault-squad-red',
				type=PlayerLogistics.infantryTypes.assault, 
				weight = 600,
				cost= 600,
				jobtime= 60*120,
				extracttime= 0,
				size = 6, 
				side= 1,
				isAISpawned = true
			},
			[2] = {
				name='assault-squad',
				type=PlayerLogistics.infantryTypes.assault, 
				weight = 600,
				cost= 600,
				jobtime= 60*120,
				extracttime= 60*60,
				size = 6, 
				side= 2,
				isAISpawned = true
			}
		}
	}

	function GroupMonitor:new()
		local obj = {}
		obj.groups = {}
		obj.supplySpawners = {}
		setmetatable(obj, self)
		self.__index = self
		
		obj:start()

		DependencyManager.register("GroupMonitor", obj)
		return obj
	end

	function GroupMonitor.isAirAttack(misType)
		if misType == ZoneCommand.missionTypes.cas then return true end
		if misType == ZoneCommand.missionTypes.cas_helo then return true end
		if misType == ZoneCommand.missionTypes.strike then return true end
		if misType == ZoneCommand.missionTypes.patrol then return true end
		if misType == ZoneCommand.missionTypes.sead then return true end
	end

	function GroupMonitor.hasWeapons(group)
		for _,un in ipairs(group:getUnits()) do
			local wps = un:getAmmo()
			if wps then
				for _,w in ipairs(wps) do
					if w.desc.category ~= 0 and w.count > 0 then
						return true
					end
				end
			end
		end
	end

	function GroupMonitor:sendHome(trackedGroup)
		if trackedGroup.home == nil then 
			env.info("GroupMonitor - sendHome "..trackedGroup.name..' does not have home set')
			return
		end

		if trackedGroup.returning then return end


		local gr = Group.getByName(trackedGroup.name)
		if gr then
			if trackedGroup.product.missionType == ZoneCommand.missionTypes.cas_helo then
				local hsp = trigger.misc.getZone(trackedGroup.home.name..'-hsp')
				if not hsp then
					hsp = trigger.misc.getZone(trackedGroup.home.name)
				end

				local alt = DependencyManager.get("ConnectionManager"):getHeliAlt(trackedGroup.target.name, trackedGroup.home.name)
				TaskExtensions.landAtPointFromAir(gr, {x=hsp.point.x, y=hsp.point.z}, alt)
			else
				local homeZn = trigger.misc.getZone(trackedGroup.home.name)
				TaskExtensions.landAtAirfield(gr, {x=homeZn.point.x, y=homeZn.point.z})
			end
			
			local cnt = gr:getController()
			cnt:setOption(0,4) -- force ai hold fire
			cnt:setOption(1, 4) -- force reaction on threat to allow abort
			
			trackedGroup.returning = true
			env.info('GroupMonitor - sendHome ['..trackedGroup.name..'] returning home')
		end
	end
	
	function GroupMonitor:registerGroup(product, target, home, savedData)
		self.groups[product.name] = {name = product.name, lastStateTime = timer.getAbsTime(), product = product, target = target, home = home, stuck_marker = 0}

		if savedData and savedData.state and savedData.state ~= 'uninitialized' then
			env.info('GroupMonitor - registerGroup ['..product.name..'] restored state '..savedData.state..' dur:'..savedData.lastStateDuration)
			self.groups[product.name].state = savedData.state
			self.groups[product.name].lastStateTime = timer.getAbsTime() - savedData.lastStateDuration
			self.groups[product.name].spawnedSquad = savedData.spawnedSquad
		end
	end
	
	function GroupMonitor:start()
        local ev = {}
        ev.context = self
        function ev:onEvent(event)
            if not event.initiator or not event.initiator.getName or not event.initiator.getPoint then return end
            if event.id==world.event.S_EVENT_DEAD or event.id==world.event.S_EVENT_CRASH then
				local name = event.initiator:getName()
				if name and self.context.supplySpawners[name] then
					if math.random() <= Config.salvageChance then
						local pos = event.initiator:getPoint()
						local amount = self.context.supplySpawners[name]

						local cname = DependencyManager.get('PlayerLogistics'):generateCargoName("Salvage")
						local ctype = DependencyManager.get('PlayerLogistics'):getBoxType(amount)

						local spos = {
							x = pos.x + math.random(-15,15),
							y = pos.z + math.random(-15,15)
						}

						Spawner.createCrate(cname, ctype, spos, 2, 1, 15, amount)

						local origin = {
							name='locally sourced', 
							isCarrier=false, 
							zone={ point=pos },
							distToFront = 0
						}

						DependencyManager.get('PlayerLogistics').trackedBoxes[cname] = {name=cname, amount = amount, type=ctype, origin = origin, lifetime=60*60*2, isSalvage=true}
					end
				end
			end
        end

		world.addEventHandler(ev)

		timer.scheduleFunction(function(param, time)
			local self = param.context
			
			for i,v in pairs(self.groups) do
				local isDead = false
				if v.product.missionType == 'supply_convoy' or v.product.missionType == 'assault' then
					isDead = self:processSurface(v)
					if isDead then 
						MissionTargetRegistry.removeBaiTarget(v) --safety measure in case group is dead
					end
				else
					isDead = self:processAir(v)
				end
				
				if isDead then
					self.groups[i] = nil
				end
			end
			
			return time+10
		end, {context = self}, timer.getTime()+1)
	end

	function GroupMonitor:getGroup(name)
		return self.groups[name]
	end
	
	function GroupMonitor:processSurface(group) -- states: [started, enroute, atdestination, siege]
		local gr = Group.getByName(group.name)
		if not gr then return true end
		if gr:getSize()==0 then 
			gr:destroy()
			return true
		end
		
		if not group.state then 
			group.state = 'started'
			group.lastStateTime = timer.getAbsTime()
			env.info('GroupMonitor: processSurface ['..group.name..'] starting')
		end
		
		if group.state =='started' then
			if gr then
				local firstUnit = gr:getUnit(1):getName()
				local z = ZoneCommand.getZoneOfUnit(firstUnit)
				if not z then 
					z = CarrierCommand.getCarrierOfUnit(firstUnit)
				end
				
				if not z then
					env.info('GroupMonitor: processSurface ['..group.name..'] is enroute')
					group.state = 'enroute'
					group.lastStateTime = timer.getAbsTime()
					MissionTargetRegistry.addBaiTarget(group)
				elseif timer.getAbsTime() - group.lastStateTime > GroupMonitor.blockedDespawnTime then
					env.info('GroupMonitor: processSurface ['..group.name..'] despawned due to blockage')
					gr:destroy()
					StrategicAI.pushResource(group.product)
					return true
				end
			end
		elseif group.state =='enroute' then
			if gr then
				if group.product.missionType=='supply_convoy' then
					for _,ssu in ipairs(gr:getUnits()) do
						self.supplySpawners[ssu:getName()] = group.product.capacity/gr:getInitialSize()
					end
				end

				local firstUnit = gr:getUnit(1):getName()
				local z = ZoneCommand.getZoneOfUnit(firstUnit)
				if not z then 
					z = CarrierCommand.getCarrierOfUnit(firstUnit)
				end
				
				if z and (z.name==group.target.name or z.name==group.home.name) then
					MissionTargetRegistry.removeBaiTarget(group)
					
					if group.product.missionType == 'supply_convoy' then
						env.info('GroupMonitor: processSurface ['..group.name..'] has arrived at destination')
						group.state = 'atdestination'
						group.lastStateTime = timer.getAbsTime()
						z:capture(gr:getCoalition())
						local percentSurvived = gr:getSize()/gr:getInitialSize()
						local todeliver = math.floor(group.product.capacity * percentSurvived)
						z:addResource(todeliver)
						z:pushMisOfType(group.product.missionType) 
						env.info('GroupMonitor: processSurface ['..group.name..'] has supplied ['..z.name..'] with ['..todeliver..']')
					elseif group.product.missionType == 'assault' then
						if z.side == gr:getCoalition() then
							env.info('GroupMonitor: processSurface ['..group.name..'] has arrived at destination')
							group.state = 'atdestination'
							group.lastStateTime = timer.getAbsTime()
							local percentSurvived = gr:getSize()/gr:getInitialSize()
							z:pushMisOfType(group.product.missionType)
							env.info('GroupMonitor: processSurface ['..z.name..'] has recovered mission ['..group.product.missionType..'] from ['..group.name..']')
						elseif z.side == 0 then
							env.info('GroupMonitor: processSurface ['..group.name..'] has arrived at destination')
							group.state = 'atdestination'
							group.lastStateTime = timer.getAbsTime()
							z:capture(gr:getCoalition())
							env.info('GroupMonitor: processSurface ['..group.name..'] has captured ['..z.name..']')
							z:pushMisOfType(group.product.missionType) 
						elseif z.side ~= gr:getCoalition() and z.side ~= 0  then
							env.info('GroupMonitor: processSurface ['..group.name..'] starting siege')
							group.state = 'siege'
							group.lastStateTime = timer.getAbsTime()
						end
					end
				else
					if group.product.missionType == 'supply_convoy' then
						if not group.returning and group.target and group.target.side ~= group.product.side and group.target.side ~= 0 then
							local supplyPoint = trigger.misc.getZone(group.home.name..'-sp')
							if not supplyPoint then
								supplyPoint = trigger.misc.getZone(group.home.name)
							end
	
							if supplyPoint then 
								group.returning = true
								env.info('GroupMonitor: processSurface ['..group.name..'] returning home')
								TaskExtensions.moveOnRoadToPoint(gr,  {x=supplyPoint.point.x, y=supplyPoint.point.z})
							end
						elseif GroupMonitor.isStuck(group) then
							env.info('GroupMonitor: processSurface ['..group.name..'] is stuck, trying to get unstuck')

							local tgtname = group.target.name
							if group.returning then 
								tgtname = group.home.name
							end

							local supplyPoint = trigger.misc.getZone(tgtname..'-sp')
							if not supplyPoint then
								supplyPoint = trigger.misc.getZone(tgtname)
							end
							TaskExtensions.moveOnRoadToPoint(gr,  {x=supplyPoint.point.x, y=supplyPoint.point.z}, true)
							
							group.unstuck_attempts = group.unstuck_attempts or 0
							group.unstuck_attempts = group.unstuck_attempts + 1

							if group.unstuck_attempts >= 5 then
								env.info('GroupMonitor: processSurface ['..group.name..'] is stuck, trying to get unstuck by teleport')
								group.unstuck_attempts = 0
								local frUnit = gr:getUnit(1)
								local pos = frUnit:getPoint()

								mist.teleportToPoint({
									groupName = group.name,
									action = 'teleport',
									initTasks = false,
									point = {x=pos.x+math.random(-25,25), y=pos.y, z = pos.z+math.random(-25,25)}
								})

								timer.scheduleFunction(function(params, time)
									local group = params.gr
									local tgtname = group.target.name
									if group.returning then 
										tgtname = group.home.name
									end
									local gr = Group.getByName(group.name)
									local supplyPoint = trigger.misc.getZone(tgtname..'-sp')
									if not supplyPoint then
										supplyPoint = trigger.misc.getZone(tgtname)
									end

									TaskExtensions.moveOnRoadToPoint(gr,  {x=supplyPoint.point.x, y=supplyPoint.point.z}, true)
								end, {gr = group}, timer.getTime()+2)
							end
						end
					elseif group.product.missionType == 'assault' then
						local frUnit = gr:getUnit(1)
						if frUnit then
							local skipDetection = false
							if group.lastStarted and (timer.getAbsTime() - group.lastStarted) < (30) then
								skipDetection = true
							else
								group.lastStarted = nil
							end

							local shouldstop = false
							if not skipDetection then
								local controller = frUnit:getController()
								local targets = controller:getDetectedTargets()

								if #targets > 0 then
									for _,tgt in ipairs(targets) do
										if tgt.visible and tgt.object then
											if tgt.object.isExist and tgt.object:isExist() and tgt.object.getCoalition and tgt.object:getCoalition()~=frUnit:getCoalition() and 
												Object.getCategory(tgt.object) == 1 then
												local dist = mist.utils.get3DDist(frUnit:getPoint(), tgt.object:getPoint())
												if dist < 700 then
													if not group.isstopped then
														env.info('GroupMonitor: processSurface ['..group.name..'] stopping to engage targets')
														TaskExtensions.stopAndDisperse(gr)
														group.isstopped = true
														group.lastStopped = timer.getAbsTime()
													end
													shouldstop = true
													break
												end
											end
										end
									end
								end
							end

							if group.lastStopped then
								if (timer.getAbsTime() - group.lastStopped) > (3*60) then
								env.info('GroupMonitor: processSurface ['..group.name..'] override stop, waited too long')
									shouldstop = false
									group.lastStarted = timer.getAbsTime()
								end
							end

							if not shouldstop and group.isstopped then
								env.info('GroupMonitor: processSurface ['..group.name..'] resuming mission')
								local tp = {
									x = group.target.zone.point.x,
									y = group.target.zone.point.z
								}

								TaskExtensions.moveOnRoadToPointAndAssault(gr, tp, group.target.built)
								group.isstopped = false
								group.lastStopped = nil
							end

							if not shouldstop and not group.isstopped then
								if GroupMonitor.isStuck(group) then
									env.info('GroupMonitor: processSurface ['..group.name..'] is stuck, trying to get unstuck')
									local tp = {
										x = group.target.zone.point.x,
										y = group.target.zone.point.z
									}

									TaskExtensions.moveOnRoadToPointAndAssault(gr, tp, group.target.built, true)

									group.unstuck_attempts = group.unstuck_attempts or 0
									group.unstuck_attempts = group.unstuck_attempts + 1

									if group.unstuck_attempts >= 5 then
										env.info('GroupMonitor: processSurface ['..group.name..'] is stuck, trying to get unstuck by teleport')
										group.unstuck_attempts = 0
										local pos = frUnit:getPoint()

										mist.teleportToPoint({
											groupName = group.name,
											action = 'teleport',
											initTasks = false,
											point = {x=pos.x+math.random(-25,25), y=pos.y, z = pos.z+math.random(-25,25)}
										})

										timer.scheduleFunction(function(params, time)
											local group = params.group
											local gr = Group.getByName(gr)
											local tp = {
												x = group.target.zone.point.x,
												y = group.target.zone.point.z
											}
		
											TaskExtensions.moveOnRoadToPointAndAssault(gr, tp, group.target.built, true)
										end, {gr = group}, timer.getTime()+2)
									end
								elseif group.unstuck_attempts and group.unstuck_attempts > 0 then
									group.unstuck_attempts = 0
								end
							end

							if not group.spawnedSquad and group.target:hasEnemyDefense(gr:getCoalition()) then
								local pos = gr:getUnit(1):getPoint()
								local tgdist = mist.utils.get2DDist(pos, group.target.zone.point)
								if tgdist < 500+group.target.zone.radius then
									local squadData = GroupMonitor.aiSquads.assault[gr:getCoalition()]
									local num = math.random(1,3)
									for i=1,num do
										DependencyManager.get("SquadTracker"):spawnInfantry(squadData, pos)
										env.info('GroupMonitor: processSurface ['..group.name..'] has deployed '..squadData.type..' squad')
									end
									group.spawnedSquad = true
								end
							end

							local timeElapsed = timer.getAbsTime() - group.lastStateTime
							if not group.spawnedSquad and timeElapsed > GroupMonitor.timeBeforeSquadDeploy then
								
								local die = math.random()
								if die < GroupMonitor.squadChance then
									local pos = gr:getUnit(1):getPoint()
									local squadData = nil
									if math.random() > GroupMonitor.ambushChance then
										squadData = GroupMonitor.aiSquads.manpads[gr:getCoalition()]
									else
										squadData = GroupMonitor.aiSquads.ambush[gr:getCoalition()]
									end

									DependencyManager.get("SquadTracker"):spawnInfantry(squadData, pos)
									env.info('GroupMonitor: processSurface ['..group.name..'] has deployed '..squadData.type..' squad')
									group.spawnedSquad = true
								end
							end
						end
					end
				end
			end
		elseif group.state == 'atdestination' then
			if timer.getAbsTime() - group.lastStateTime > GroupMonitor.atDestinationDespawnTime then
				
				if gr then
					local firstUnit = gr:getUnit(1):getName()
					local z = ZoneCommand.getZoneOfUnit(firstUnit)
					if not z then 
						z = CarrierCommand.getCarrierOfUnit(firstUnit)
					end
					if z and z.side == 0 then
						env.info('GroupMonitor: processSurface ['..group.name..'] is at neutral zone')
						z:capture(gr:getCoalition())
						env.info('GroupMonitor: processSurface ['..group.name..'] has captured ['..z.name..']')
					else
						env.info('GroupMonitor: processSurface ['..group.name..'] starting siege')
						group.state = 'siege'
						group.lastStateTime = timer.getAbsTime()
					end

					env.info('GroupMonitor: processSurface ['..group.name..'] despawned after arriving at destination')
					gr:destroy()
					return true
				end
			end
		elseif group.state == 'siege' then
			if group.product.missionType ~= 'assault' then 
				group.state = 'atdestination'
				group.lastStateTime = timer.getAbsTime()
			else
				if timer.getAbsTime() - group.lastStateTime > GroupMonitor.siegeExplosiveTime then
					if gr then
						local firstUnit = gr:getUnit(1):getName()
						local z = ZoneCommand.getZoneOfUnit(firstUnit)
						local success = false
						
						if z then
							for i,v in pairs(z.built) do
								if v.type == 'upgrade' and v.side ~= gr:getCoalition() then
									local st = StaticObject.getByName(v.name)
									if not st then st = Group.getByName(v.name) end
									local pos = st:getPoint()
									trigger.action.explosion(pos, GroupMonitor.siegeExplosiveStrength)
									group.lastStateTime = timer.getAbsTime()
									success = true
									env.info('GroupMonitor: processSurface ['..group.name..'] detonating structure at '..z.name)
									--trigger.action.outTextForCoalition(z.side, z.name..' is under attack by ground forces', 10)
									
									if z.side == 2 then
										local sourcePos = {
											x = z.zone.point.x,
											y = 9144,
											z = z.zone.point.z,
										}

										if math.random()>0.5 then
											TransmissionManager.queueMultiple({'zones.names.'..z.name, 'zones.events.underattack.1'}, TransmissionManager.radios.command, sourcePos)
										else
											TransmissionManager.queueMultiple({'zones.events.underattack.2','zones.names.'..z.name}, TransmissionManager.radios.command, sourcePos)
										end
									end

									break
								end
							end
						end

						if not success then
							env.info('GroupMonitor: processSurface ['..group.name..'] no targets to detonate, switching to atdestination')
							group.state = 'atdestination'
							group.lastStateTime = timer.getAbsTime()
						end
					end
				end
			end
		end
	end

	function GroupMonitor.isStuck(group)
		if Config.disableUnstuck then return false end
		
		local gr = Group.getByName(group.name)
		if not gr then return false end
		if gr:getSize() == 0 then return false end

		local un = gr:getUnit(1)
		if un and un:isExist() and mist.vec.mag(un:getVelocity()) >= 0.01 and group.stuck_marker > 0 then
			group.stuck_marker = 0
			group.unstuck_attempts = 0
			env.info('GroupMonitor: isStuck ['..group.name..'] is moving, reseting stuck marker velocity='..mist.vec.mag(un:getVelocity()))
		end

		if un and un:isExist() and mist.vec.mag(un:getVelocity()) < 0.01 then
			group.stuck_marker = group.stuck_marker + 1
			env.info('GroupMonitor: isStuck ['..group.name..'] is not moving, increasing stuck marker to '..group.stuck_marker..' velocity='..mist.vec.mag(un:getVelocity()))

			if group.stuck_marker >= 3 then
				group.stuck_marker = 0
				env.info('GroupMonitor: isStuck ['..group.name..'] is stuck')
				return true
			end
		end

		return false
	end
	
	function GroupMonitor:processAir(group)-- states: [takeoff, inair, landed]
		local gr = Group.getByName(group.name)
		if not gr then return true end
		if not gr:isExist() or gr:getSize()==0 then 
			gr:destroy()
			return true
		end
		--[[
		if group.product.missionType == 'cas' or group.product.missionType == 'cas_helo' or group.product.missionType == 'strike' or group.product.missionType == 'sead' then
			if MissionTargetRegistry.isZoneTargeted(group.target) and group.product.side == 2 and not group.returning then 
				env.info('GroupMonitor - mission ['..group.name..'] to ['..group.target..'] canceled due to player mission')

				GroupMonitor.sendHome(group)
			end
		end
		]]--
		
		if not group.state then 
			group.state = 'takeoff' 
			env.info('GroupMonitor: processAir ['..group.name..'] taking off')
		end
		
		if group.state =='takeoff' then
			if timer.getAbsTime() - group.lastStateTime > GroupMonitor.blockedDespawnTime then
				if gr and gr:getSize()>0 and gr:getUnit(1) and gr:getUnit(1):isExist() then
					local frUnit = gr:getUnit(1)
					local cz = CarrierCommand.getCarrierOfUnit(frUnit:getName())
					if Utils.allGroupIsLanded(gr, cz ~= nil) then
						env.info('GroupMonitor: processAir ['..group.name..'] is blocked, despawning')
						local frUnit = gr:getUnit(1)
						if frUnit then
							local firstUnit = frUnit:getName()
							local z = ZoneCommand.getZoneOfUnit(firstUnit)
							if not z then 
								z = CarrierCommand.getCarrierOfUnit(firstUnit)
							end
							if z then
								StrategicAI.pushResource(group.product)
								env.info('GroupMonitor: processAir ['..z.name..'] has recovered resource from ['..group.name..']')
							end
						end

						gr:destroy()
						return true
					end
				end
			elseif gr and Utils.someOfGroupInAir(gr) then
				env.info('GroupMonitor: processAir ['..group.name..'] is in the air')
				group.state = 'inair'
				group.lastStateTime = timer.getAbsTime()
			end
		elseif group.state =='inair' then
			if gr then
				if group.product.missionType=='supply_air' then
					for _,ssu in ipairs(gr:getUnits()) do
						self.supplySpawners[ssu:getName()] = group.product.capacity/gr:getInitialSize()
					end
				end

				local unit = gr:getUnit(1)
				if not unit or not unit.isExist or not unit:isExist() then return end
				
				local cz = CarrierCommand.getCarrierOfUnit(unit:getName())
				if Utils.allGroupIsLanded(gr, cz ~= nil) then
					env.info('GroupMonitor: processAir ['..group.name..'] has landed')
					group.state = 'landed'
					group.lastStateTime = timer.getAbsTime()

					if unit then
						local firstUnit = unit:getName()
						local z = ZoneCommand.getZoneOfUnit(firstUnit)
						if not z then 
							z = CarrierCommand.getCarrierOfUnit(firstUnit)
						end
						
						if group.product.missionType == 'supply_air' then
							if z then
								z:capture(gr:getCoalition())
								z:addResource(group.product.capacity)
								z:pushMisOfType(group.product.missionType) 
								env.info('GroupMonitor: processAir ['..group.name..'] has supplied ['..z.name..'] with ['..group.product.capacity..']')
							end
						else
							if z and z.side == gr:getCoalition() then
								local percentSurvived = gr:getSize()/gr:getInitialSize()
								local torecover = math.floor(group.product.cost * percentSurvived * GroupMonitor.recoveryReduction)
								z:pushMisOfType(group.product.missionType) 
								env.info('GroupMonitor: processAir ['..z.name..'] has recovered product ['..group.product.missionType..'] from ['..group.name..']')
							end
						end
					else
						env.info('GroupMonitor: processAir ['..group.name..'] size ['..gr:getSize()..'] has no unit 1')
					end
				else
					if GroupMonitor.isAirAttack(group.product.missionType) and not group.returning then
						if not GroupMonitor.hasWeapons(gr) then
							env.info('GroupMonitor: processAir ['..group.name..'] size ['..gr:getSize()..'] has no weapons outside of shells')
							self:sendHome(group)
						elseif group.product.missionType == ZoneCommand.missionTypes.cas_helo then 
							local frUnit = gr:getUnit(1)
							local controller = frUnit:getController()
							local targets = controller:getDetectedTargets()

							local tgtToEngage = {}
							if #targets > 0 then
								for _,tgt in ipairs(targets) do
									if tgt.visible and tgt.object and tgt.object.isExist and tgt.object:isExist() then
										if Object.getCategory(tgt.object) == Object.Category.UNIT and 
											tgt.object.getCoalition and tgt.object:getCoalition()~=frUnit:getCoalition() and 
											Unit.getCategoryEx(tgt.object) == Unit.Category.GROUND_UNIT then

											local dist = mist.utils.get3DDist(frUnit:getPoint(), tgt.object:getPoint())
											if dist < 2000 then
												table.insert(tgtToEngage, tgt.object)
											end
										end
									end
								end
							end

							if not group.isengaging and #tgtToEngage > 0 then
								env.info('GroupMonitor: processAir ['..group.name..'] engaging targets')
								TaskExtensions.heloEngageTargets(gr, tgtToEngage, group.product.expend)
								group.isengaging = true
								group.startedEngaging = timer.getAbsTime()
							elseif group.isengaging and #tgtToEngage == 0 and group.startedEngaging and (timer.getAbsTime() - group.startedEngaging) > 60*5 then
								env.info('GroupMonitor: processAir ['..group.name..'] resuming mission')
								if group.returning then
									group.returning = nil
									self:sendHome(group)
								else
									if group.target then
										local homePos = group.home.zone.point
										TaskExtensions.executeHeloCasMission(gr, group.target.built, group.product.expend, group.product.altitude, {homePos = homePos})
									end
								end
								group.isengaging = false
							end
						end
					elseif group.product.missionType == 'supply_air' then
						if not group.returning and group.target and group.target.side ~= group.product.side and group.target.side ~= 0 then
							local supplyPoint = trigger.misc.getZone(group.home.name..'-hsp')
							if not supplyPoint then
								supplyPoint = trigger.misc.getZone(group.home.name)
							end

							if supplyPoint then 
								group.returning = true
								local alt = DependencyManager.get("ConnectionManager"):getHeliAlt(group.target.name, group.home.name)
								TaskExtensions.landAtPointFromAir(gr,  {x=supplyPoint.point.x, y=supplyPoint.point.z}, alt)
								env.info('GroupMonitor: processAir ['..group.name..'] returning home')
							end
						end
					end
				end
			end
		elseif group.state =='landed' then
			if timer.getAbsTime() - group.lastStateTime > GroupMonitor.landedDespawnTime then
				if gr then
					env.info('GroupMonitor: processAir ['..group.name..'] despawned after landing')
					gr:destroy()
					return true
				end
			end
		end
	end
end

