
TaskExtensions = {}
do
	function TaskExtensions.getAttackTask(targetName, expend, altitude)
		local tgt = Group.getByName(targetName)
		if tgt then
			return { 
				id = 'AttackGroup', 
				params = { 
					groupId = tgt:getID(),
					expend = expend,
					weaponType = Weapon.flag.AnyWeapon,
					groupAttack = true,
					altitudeEnabled = (altitude ~= nil),
					altitude = altitude
				} 
			}
		else
			tgt = StaticObject.getByName(targetName)
			if not tgt then tgt = Unit.getByName(targetName) end
			if tgt then
				return { 
					id = 'AttackUnit', 
					params = { 
						unitId = tgt:getID(),
						expend = expend,
						weaponType = Weapon.flag.AnyWeapon,
						groupAttack = true,
						altitudeEnabled = (altitude ~= nil),
						altitude = altitude
					} 
				}
			end
		end
	end

	function TaskExtensions.getTargetPos(targetName)
		local tgt = StaticObject.getByName(targetName)
		if not tgt then tgt = Unit.getByName(targetName) end
		if tgt then
			return tgt:getPoint()
		end
	end

	function TaskExtensions.getDefaultWaypoints(startPos, task, tgpos, reactivated, landUnitID)
		local defwp = {
			id='Mission',
			params = {
				route = {
					airborne = true,
					points = {}
				}  
			}
		}

		if reactivated then
			table.insert(defwp.params.route.points, {
				type= AI.Task.WaypointType.TURNING_POINT,
				x = reactivated.currentPos.x,
				y = reactivated.currentPos.z,
				speed = 257,
				action = AI.Task.TurnMethod.FLY_OVER_POINT,
				alt = 4572,
				alt_type = AI.Task.AltitudeType.BARO, 
				task = task
			})
		else
			table.insert(defwp.params.route.points, {
				type= AI.Task.WaypointType.TAKEOFF,
				x = startPos.x,
				y = startPos.z,
				speed = 0,
				action = AI.Task.TurnMethod.FIN_POINT,
				alt = 0,
				alt_type = AI.Task.AltitudeType.RADIO
			})

			table.insert(defwp.params.route.points, {
				type= AI.Task.WaypointType.TURNING_POINT,
				x = startPos.x,
				y = startPos.z,
				speed = 257,
				action = AI.Task.TurnMethod.FLY_OVER_POINT,
				alt = 4572,
				alt_type = AI.Task.AltitudeType.BARO, 
				task = task
			})
		end

		if tgpos then
			table.insert(defwp.params.route.points, {
				type= AI.Task.WaypointType.TURNING_POINT,
				x = tgpos.x,
				y = tgpos.z,
				speed = 257,
				action = AI.Task.TurnMethod.FLY_OVER_POINT,
				alt = 4572,
				alt_type = AI.Task.AltitudeType.BARO,
				task = task
			})
		end

		if landUnitID then
			table.insert(defwp.params.route.points, {
				type= AI.Task.WaypointType.LAND,
				linkUnit = landUnitID,
				helipadId = landUnitID,
				x = startPos.x,
				y = startPos.z,
				speed = 257,
				action = AI.Task.TurnMethod.FIN_POINT,
				alt = 0,
				alt_type = AI.Task.AltitudeType.RADIO
			})
		else
			table.insert(defwp.params.route.points, {
				type= AI.Task.WaypointType.LAND,
				x = startPos.x,
				y = startPos.z,
				speed = 257,
				action = AI.Task.TurnMethod.FIN_POINT,
				alt = 0,
				alt_type = AI.Task.AltitudeType.RADIO
			})
		end

		return defwp
	end

	function TaskExtensions.executeSeadMission(group,targets, expend, altitude, reactivated)
		if not group then return end
		if not group:isExist() or group:getSize()==0 then return end
		local startPos = group:getUnit(1):getPoint()

		if reactivated then
			reactivated.currentPos = startPos
			startPos = reactivated.homePos
		end

		local expCount = AI.Task.WeaponExpend.ALL
		if expend then
			expCount = expend
		end
		
		local alt = 4572
		if altitude then
			alt = altitude/3.281
		end

		local viable = {}
		for i,v in pairs(targets) do
			if v.type == 'defense' and v.side ~= group:getCoalition() then
				local gr = Group.getByName(v.name)
				for _,unit in ipairs(gr:getUnits()) do
					if unit:hasAttribute('SAM SR') or unit:hasAttribute('SAM TR') then
						table.insert(viable, unit:getName())
					end
				end
			end
		end

		local attack = {
			id = 'ComboTask',
			params = {
				tasks = {
					{ 
						id = 'EngageTargets', 
						params = {  
						  targetTypes = {'SAM SR', 'SAM TR'}
						} 
					}
				}
			}
		}

		for i,v in ipairs(viable) do
			local task = TaskExtensions.getAttackTask(v, expCount, alt)
			table.insert(attack.params.tasks, task)
		end

		local firstunitpos = nil
		local tgt = viable[1]
		if tgt then 
			firstunitpos = Unit.getByName(tgt):getPoint()
		end
		
		local mis = TaskExtensions.getDefaultWaypoints(startPos, attack, firstunitpos, reactivated)

		group:getController():setTask(mis)
		TaskExtensions.setDefaultAG(group)
	end

	function TaskExtensions.executeStrikeMission(group, targets, expend, altitude, reactivated, landUnitID)
		if not group then return end
		if not group:isExist() or group:getSize()==0 then return end
		local startPos = group:getUnit(1):getPoint()

		if reactivated then
			reactivated.currentPos = startPos
			startPos = reactivated.homePos
		end

		local expCount = AI.Task.WeaponExpend.ALL
		if expend then
			expCount = expend
		end
		
		local alt = 4572
		if altitude then
			alt = altitude/3.281
		end

		local attack = {
			id = 'ComboTask',
			params = {
				tasks = {
				}
			}
		}

		for i,v in pairs(targets) do
			if v.type == 'upgrade' and v.side ~= group:getCoalition() then
				local task = TaskExtensions.getAttackTask(v.name, expCount, alt)
				table.insert(attack.params.tasks, task)
			end
		end

		local mis = TaskExtensions.getDefaultWaypoints(startPos, attack, nil, reactivated, landUnitID)

		group:getController():setTask(mis)
		TaskExtensions.setDefaultAG(group)
	end

	function TaskExtensions.executePinpointStrikeMission(group, targetPos, expend, altitude, reactivated, landUnitID)
		if not group then return end
		if not group:isExist() or group:getSize()==0 then return end
		local startPos = group:getUnit(1):getPoint()

		if reactivated then
			reactivated.currentPos = startPos
			startPos = reactivated.homePos
		end

		local expCount = AI.Task.WeaponExpend.ALL
		if expend then
			expCount = expend
		end
		
		local alt = 4572
		if altitude then
			alt = altitude/3.281
		end

		local attack = {
			id = 'Bombing', 
			params = { 
				point = {
					x = targetPos.x, 
					y = targetPos.z
				},
				attackQty = 1,
				weaponType = Weapon.flag.AnyBomb,
				expend = expCount,
				groupAttack = true, 
				altitude = alt,
				altitudeEnabled = (altitude ~= nil),
			} 
		}

		local diff = {
			x = targetPos.x - startPos.x,
			z = targetPos.z - startPos.z
		}

		local tp = {
			x = targetPos.x - diff.x*0.5,
			z = targetPos.z - diff.z*0.5
		}

		local mis = TaskExtensions.getDefaultWaypoints(startPos, attack, tp, reactivated, landUnitID)

		group:getController():setTask(mis)
		TaskExtensions.setDefaultAG(group)
	end

	function TaskExtensions.executeCasMission(group, targets, expend, altitude, reactivated)
		if not group then return end
		if not group:isExist() or group:getSize()==0 then return end
		local startPos = group:getUnit(1):getPoint()

		if reactivated then
			reactivated.currentPos = startPos
			startPos = reactivated.homePos
		end

		local attack = {
			id = 'ComboTask',
			params = {
				tasks = {
				}
			}
		}

		local expCount = AI.Task.WeaponExpend.ONE
		if expend then
			expCount = expend
		end
		
		local alt = 4572
		if altitude then
			alt = altitude/3.281
		end

		for i,v in pairs(targets) do
			if v.type == 'defense' then
				local g = Group.getByName(i)
				if g and g:getCoalition()~=group:getCoalition() then
					local task = TaskExtensions.getAttackTask(i, expCount, alt)
					table.insert(attack.params.tasks, task)
				end
			end
		end

		local mis = TaskExtensions.getDefaultWaypoints(startPos, attack, nil, reactivated)

		group:getController():setTask(mis)
		TaskExtensions.setDefaultAG(group)
	end

	function TaskExtensions.executeBaiMission(group, targets, expend, altitude, reactivated)
		if not group then return end
		if not group:isExist() or group:getSize()==0 then return end
		local startPos = group:getUnit(1):getPoint()

		if reactivated then
			reactivated.currentPos = startPos
			startPos = reactivated.homePos
		end

		local attack = {
			id = 'ComboTask',
			params = {
				tasks = {
					{ 
						id = 'EngageTargets', 
						params = {  
						  targetTypes = {'Vehicles'}
						} 
					}
				}
			}
		}

		local expCount = AI.Task.WeaponExpend.ONE
		if expend then
			expCount = expend
		end
		
		local alt = 4572
		if altitude then
			alt = altitude/3.281
		end

		for i,v in pairs(targets) do
			if v.type == 'mission' and (v.missionType == 'assault' or v.missionType == 'supply_convoy') then
				local g = Group.getByName(i)
				if g and g:getSize()>0 and g:getCoalition()~=group:getCoalition() then
					local task = TaskExtensions.getAttackTask(i, expCount, alt)
					table.insert(attack.params.tasks, task)
				end
			end
		end

		local mis = TaskExtensions.getDefaultWaypoints(startPos, attack, nil, reactivated)

		group:getController():setTask(mis)
		TaskExtensions.setDefaultAG(group)
	end

	function TaskExtensions.heloEngageTargets(group, targets, expend)
		if not group then return end
		if not group:isExist() or group:getSize()==0 then return end
		local startPos = group:getUnit(1):getPoint()

		local attack = {
			id = 'ComboTask',
			params = {
				tasks = {
				}
			}
		}

		local expCount = AI.Task.WeaponExpend.ONE
		if expend then
			expCount = expend
		end
		
		for i,v in pairs(targets) do
			local task = { 
				id = 'AttackUnit', 
				params = { 
					unitId = v:getID(),
					expend = expend,
					weaponType = Weapon.flag.AnyWeapon,
					groupAttack = true
				} 
			}

			table.insert(attack.params.tasks, task)
		end

		group:getController():pushTask(attack)
	end

	function TaskExtensions.executeHeloCasMission(group, targets, expend, altitude, reactivated)
		if not group then return end
		if not group:isExist() or group:getSize()==0 then return end
		local startPos = group:getUnit(1):getPoint()

		if reactivated then
			reactivated.currentPos = startPos
			startPos = reactivated.homePos
		end

		local attack = {
			id = 'ComboTask',
			params = {
				tasks = {
				}
			}
		}

		local expCount = AI.Task.WeaponExpend.ONE
		if expend then
			expCount = expend
		end
		
		local alt = 61
		if altitude then
			alt = altitude/3.281
		end

		for i,v in pairs(targets) do
			if v.type == 'defense' then
				local g = Group.getByName(i)
				if g and g:getCoalition()~=group:getCoalition() then
					local task = TaskExtensions.getAttackTask(i, expCount, alt)
					table.insert(attack.params.tasks, task)
				end
			end
		end

		local land = {
			id='Land',
			params = {
				point = {x = startPos.x, y=startPos.z}
			}
		}

		local mis = {
			id='Mission',
			params = {
				route = {
					airborne = true,
					points = {}
				}  
			}
		}

		if reactivated then
			table.insert(mis.params.route.points, {
				type= AI.Task.WaypointType.TURNING_POINT,
				x = reactivated.currentPos.x+1000,
				y = reactivated.currentPos.z+1000,
				speed = 257,
				action = AI.Task.TurnMethod.FLY_OVER_POINT,
				alt = alt,
				alt_type = AI.Task.AltitudeType.RADIO, 
				task = attack
			})
		else
			table.insert(mis.params.route.points, {
				type= AI.Task.WaypointType.TAKEOFF,
				x = startPos.x,
				y = startPos.z,
				speed = 0,
				action = AI.Task.TurnMethod.FIN_POINT,
				alt = 0,
				alt_type = AI.Task.AltitudeType.RADIO,
			})

			table.insert(mis.params.route.points, {
				type= AI.Task.WaypointType.TURNING_POINT,
				x = startPos.x+1000,
				y = startPos.z+1000,
				speed = 257,
				action = AI.Task.TurnMethod.FLY_OVER_POINT,
				alt = alt,
				alt_type = AI.Task.AltitudeType.RADIO, 
				task = attack
			})
		end

		table.insert(mis.params.route.points, {
			type= AI.Task.WaypointType.TURNING_POINT,
			x = startPos.x,
			y = startPos.z,
			speed = 257,
			action = AI.Task.TurnMethod.FIN_POINT,
			alt = alt,
			alt_type = AI.Task.AltitudeType.RADIO, 
			task = land
		})
		
		group:getController():setTask(mis)
		TaskExtensions.setDefaultAG(group)
	end

	function TaskExtensions.executeTankerMission(group, point, altitude, frequency, tacan, reactivated, landUnitID)
		if not group then return end
		if not group:isExist() or group:getSize()==0 then return end
		local startPos = group:getUnit(1):getPoint()
		if reactivated then
			reactivated.currentPos = startPos
			startPos = reactivated.homePos
		end
		
		local alt = 4572
		if altitude then
			alt = altitude/3.281
		end

		local freq = 259500000
		if frequency then
			freq = math.floor(frequency*1000000)
		end

		local setfreq = {
			id = 'SetFrequency', 
			params = { 
				frequency = freq,
				modulation = 0
			} 
		}

		local setbeacon = {
			id = 'ActivateBeacon', 
			params = { 
				type = 4, -- TACAN type
				system = 4, -- Tanker TACAN
				name = 'tacan task', 
				callsign = group:getUnit(1):getCallsign():sub(1,3), 
				frequency = tacan,
				AA = true,
				channel = tacan,
				bearing = true,
				modeChannel = "X"
			} 
		}

		local distFromPoint = 20000
		local theta = math.random() * 2 * math.pi
  
		local dx = distFromPoint * math.cos(theta)
		local dy = distFromPoint * math.sin(theta)

		local pos1 = {
			x = point.x + dx,
			y = point.z + dy
		}

		local pos2 = {
			x = point.x - dx,
			y = point.z - dy
		}

		local orbit_speed = 97
		local travel_speed = 450

		local orbit = { 
			id = 'Orbit', 
			params = { 
				pattern = AI.Task.OrbitPattern.RACE_TRACK,
				point = pos1,
   				point2 = pos2,
				speed = orbit_speed,
				altitude = alt
			}
		}

		local script = {
			id = "WrappedAction",
			params = {
				action = {
					id = "Script",
					params = 
					{
						command = "trigger.action.outTextForCoalition("..group:getCoalition()..", 'Tanker on station. "..(freq/1000000).." AM', 15)",
					}
				}
			}
		}

		local tanker = {
			id = 'Tanker', 
			params = { 
			}
		}

		local task = {
			id='Mission',
			params = {
				route = {
					airborne = true,
					points = {}
				}
			}
		}

		if reactivated then
			table.insert(task.params.route.points, {
				type= AI.Task.WaypointType.TURNING_POINT,
				x = pos1.x,
				y = pos1.y,
				speed = travel_speed,
				action = AI.Task.TurnMethod.FLY_OVER_POINT,
				alt = alt,
				alt_type = AI.Task.AltitudeType.BARO,
				task = tanker
			})
		else
			table.insert(task.params.route.points, {
				type= AI.Task.WaypointType.TAKEOFF,
				x = startPos.x,
				y = startPos.z,
				speed = 0,
				action = AI.Task.TurnMethod.FIN_POINT,
				alt = 0,
				alt_type = AI.Task.AltitudeType.RADIO,
				task = tanker
			})
		end

		table.insert(task.params.route.points, {
			type= AI.Task.WaypointType.TURNING_POINT,
			x = pos1.x,
			y = pos1.y,
			speed = orbit_speed,
			action = AI.Task.TurnMethod.FLY_OVER_POINT,
			alt = alt,
			alt_type = AI.Task.AltitudeType.BARO,
			task = {
				id = 'ComboTask',
				params = {
					tasks = {
						script
					}
				}
			}
		})

		table.insert(task.params.route.points, {
			type= AI.Task.WaypointType.TURNING_POINT,
			x = pos2.x,
			y = pos2.y,
			speed = orbit_speed,
			action = AI.Task.TurnMethod.FLY_OVER_POINT,
			alt = alt,
			alt_type = AI.Task.AltitudeType.BARO,
			task = {
				id = 'ComboTask',
				params = {
					tasks = {
						orbit
					}
				}
			}
		})

		if landUnitID then
			table.insert(task.params.route.points, {
				type= AI.Task.WaypointType.LAND,
				linkUnit = landUnitID,
				helipadId = landUnitID,
				x = startPos.x,
				y = startPos.z,
				speed = travel_speed,
				action = AI.Task.TurnMethod.FIN_POINT,
				alt = 0,
				alt_type = AI.Task.AltitudeType.RADIO
			})
		else
			table.insert(task.params.route.points, {
				type= AI.Task.WaypointType.LAND,
				x = startPos.x,
				y = startPos.z,
				speed = travel_speed,
				action = AI.Task.TurnMethod.FIN_POINT,
				alt = 0,
				alt_type = AI.Task.AltitudeType.RADIO
			})
		end
			
		group:getController():setTask(task)
		group:getController():setOption(AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.PASSIVE_DEFENCE)
		group:getController():setCommand(setfreq)
		group:getController():setCommand(setbeacon)
	end

	function TaskExtensions.executeAwacsMission(group, point, altitude, frequency, reactivated, landUnitID)
		if not group then return end
		if not group:isExist() or group:getSize()==0 then return end
		local startPos = group:getUnit(1):getPoint()
		if reactivated then
			reactivated.currentPos = startPos
			startPos = reactivated.homePos
		end
		
		local alt = 4572
		if altitude then
			alt = altitude/3.281
		end

		local freq = 259500000
		if frequency then
			freq = math.floor(frequency*1000000)
		end

		local setfreq = {
			id = 'SetFrequency', 
			params = { 
				frequency = freq,
				modulation = 0
			} 
		}

		local distFromPoint = 10000
		local theta = math.random() * 2 * math.pi
  
		local dx = distFromPoint * math.cos(theta)
		local dy = distFromPoint * math.sin(theta)

		local pos1 = {
			x = point.x + dx,
			y = point.z + dy
		}

		local pos2 = {
			x = point.x - dx,
			y = point.z - dy
		}

		local orbit = { 
			id = 'Orbit', 
			params = { 
				pattern = AI.Task.OrbitPattern.RACE_TRACK,
				point = pos1,
   				point2 = pos2,
				altitude = alt
			}
		}

		local script = {
			id = "WrappedAction",
			params = {
				action = {
					id = "Script",
					params = 
					{
						command = "trigger.action.outTextForCoalition("..group:getCoalition()..", 'AWACS on station. "..(freq/1000000).." AM', 15)",
					}
				}
			}
		}


		local awacs = {
			id = 'ComboTask',
			params = {
				tasks = {
					{
						id = "WrappedAction",
						params = 
						{
							action = 
							{
								id = "EPLRS",
								params = {
									value = true,
									groupId = group:getID(),
								}
							}
						}
					},
					{
						id = 'AWACS', 
						params = { 
						}	
					}
				}
			}
		}

		local task = {
			id='Mission',
			params = {
				route = {
					airborne = true,
					points = {}
				}  
			}
		}

		if reactivated then
			table.insert(task.params.route.points, {
				type= AI.Task.WaypointType.TURNING_POINT,
				x = pos1.x,
				y = pos1.y,
				speed = 257,
				action = AI.Task.TurnMethod.FLY_OVER_POINT,
				alt = alt,
				alt_type = AI.Task.AltitudeType.BARO,
				task = awacs
			})
		else
			table.insert(task.params.route.points, {
				type= AI.Task.WaypointType.TAKEOFF,
				x = startPos.x,
				y = startPos.z,
				speed = 0,
				action = AI.Task.TurnMethod.FIN_POINT,
				alt = 0,
				alt_type = AI.Task.AltitudeType.RADIO,
				task = awacs
			})
		end
			
		table.insert(task.params.route.points, {
			type= AI.Task.WaypointType.TURNING_POINT,
			x = pos1.x,
			y = pos1.y,
			speed = 257,
			action = AI.Task.TurnMethod.FLY_OVER_POINT,
			alt = alt,
			alt_type = AI.Task.AltitudeType.BARO,
			task = {
				id = 'ComboTask',
				params = {
					tasks = {
						script
					}
				}
			}
		})

		table.insert(task.params.route.points, {
			type= AI.Task.WaypointType.TURNING_POINT,
			x = pos2.x,
			y = pos2.y,
			speed = 257,
			action = AI.Task.TurnMethod.FLY_OVER_POINT,
			alt = alt,
			alt_type = AI.Task.AltitudeType.BARO,
			task = {
				id = 'ComboTask',
				params = {
					tasks = {
						orbit
					}
				}
			}
		})

		if landUnitID then
			table.insert(task.params.route.points, {
				type= AI.Task.WaypointType.LAND,
				linkUnit = landUnitID,
				helipadId = landUnitID,
				x = startPos.x,
				y = startPos.z,
				speed = 257,
				action = AI.Task.TurnMethod.FIN_POINT,
				alt = 0,
				alt_type = AI.Task.AltitudeType.RADIO
			})
		else
			table.insert(task.params.route.points, {
				type= AI.Task.WaypointType.LAND,
				x = startPos.x,
				y = startPos.z,
				speed = 257,
				action = AI.Task.TurnMethod.FIN_POINT,
				alt = 0,
				alt_type = AI.Task.AltitudeType.RADIO
			})
		end
		
		group:getController():setTask(task)
		group:getController():setOption(AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.PASSIVE_DEFENCE)
		group:getController():setCommand(setfreq)
	end
	
	function TaskExtensions.executePatrolMission(group, point, altitude, range, reactivated, landUnitID)
		if not group then return end
		if not group:isExist() or group:getSize()==0 then return end
		local startPos = group:getUnit(1):getPoint()

		if reactivated then
			reactivated.currentPos = startPos
			startPos = reactivated.homePos
		end

		local rng = 25 * 1852
		if range then
			rng = range * 1852
		end
		
		local alt = 4572
		if altitude then
			alt = altitude/3.281
		end

		local search = { 
			id = 'EngageTargets',
			params = {
				maxDist = rng,
				targetTypes = { 'Planes', 'Helicopters' }
			} 
		}

		local distFromPoint = 10000
		local theta = math.random() * 2 * math.pi
  
		local dx = distFromPoint * math.cos(theta)
		local dy = distFromPoint * math.sin(theta)

		local p1 = {
			x = point.x + dx,
			y = point.z + dy
		}

		local p2 = {
			x = point.x - dx,
			y = point.z - dy
		}

		local orbit = {
			id = 'Orbit',
			params = {
				pattern = AI.Task.OrbitPattern.RACE_TRACK,
				point = p1,
				point2 = p2,
				speed = 154,
				altitude = alt
			}
		}

		local task = {
			id='Mission',
			params = {
				route = {
					airborne = true,
					points = {}
				}  
			}
		}

		if not reactivated then
			table.insert(task.params.route.points, {
				type= AI.Task.WaypointType.TAKEOFF,
				x = startPos.x,
				y = startPos.z,
				speed = 0,
				action = AI.Task.TurnMethod.FIN_POINT,
				alt = 0,
				alt_type = AI.Task.AltitudeType.RADIO,
				task = search
			})
		else
			table.insert(task.params.route.points, {
				type= AI.Task.WaypointType.TURNING_POINT,
				x = reactivated.currentPos.x,
				y = reactivated.currentPos.z,
				speed = 257,
				action = AI.Task.TurnMethod.FIN_POINT,
				alt = alt,
				alt_type = AI.Task.AltitudeType.BARO,
				task = search
			})
		end

		table.insert(task.params.route.points, {
			type= AI.Task.WaypointType.TURNING_POINT,
			x = p1.x,
			y = p1.y,
			speed = 257,
			action = AI.Task.TurnMethod.FLY_OVER_POINT,
			alt = alt,
			alt_type = AI.Task.AltitudeType.BARO
		})

		table.insert(task.params.route.points, {
			type= AI.Task.WaypointType.TURNING_POINT,
			x = p2.x,
			y = p2.y,
			speed = 257,
			action = AI.Task.TurnMethod.FLY_OVER_POINT,
			alt = alt,
			alt_type = AI.Task.AltitudeType.BARO,
			task = orbit
		})

		if landUnitID then
			table.insert(task.params.route.points, {
				type= AI.Task.WaypointType.LAND,
				linkUnit = landUnitID,
				helipadId = landUnitID,
				x = startPos.x,
				y = startPos.z,
				speed = 257,
				action = AI.Task.TurnMethod.FIN_POINT,
				alt = 0,
				alt_type = AI.Task.AltitudeType.RADIO
			})
		else
			table.insert(task.params.route.points, {
				type= AI.Task.WaypointType.LAND,
				x = startPos.x,
				y = startPos.z,
				speed = 257,
				action = AI.Task.TurnMethod.FIN_POINT,
				alt = 0,
				alt_type = AI.Task.AltitudeType.RADIO
			})
		end
		
		group:getController():setTask(task)
		TaskExtensions.setDefaultAA(group)
	end

	function TaskExtensions.setDefaultAA(group)
		group:getController():setOption(AI.Option.Air.id.PROHIBIT_AG, true)
		group:getController():setOption(AI.Option.Air.id.JETT_TANKS_IF_EMPTY, true)
		group:getController():setOption(AI.Option.Air.id.PROHIBIT_JETT, true)
		group:getController():setOption(AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE)
		group:getController():setOption(AI.Option.Air.id.MISSILE_ATTACK, AI.Option.Air.val.MISSILE_ATTACK.MAX_RANGE)

		local weapons = 268402688  -- AnyMissile
		group:getController():setOption(AI.Option.Air.id.RTB_ON_OUT_OF_AMMO, weapons)
	end

	function TaskExtensions.setDefaultAG(group)
		--group:getController():setOption(AI.Option.Air.id.PROHIBIT_AA, true)
		group:getController():setOption(AI.Option.Air.id.JETT_TANKS_IF_EMPTY, true)
		group:getController():setOption(AI.Option.Air.id.PROHIBIT_JETT, true)
		group:getController():setOption(AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE)

		local weapons = 2147485694 + 30720 + 4161536 -- AnyBomb + AnyRocket + AnyASM
		group:getController():setOption(AI.Option.Air.id.RTB_ON_OUT_OF_AMMO, weapons)
	end

	function TaskExtensions.stopAndDisperse(group)
		if not group then return end
		if not group:isExist() or group:getSize()==0 then return end
		local pos = group:getUnit(1):getPoint()
		group:getController():setTask({
			id='Mission',
			params = {
				route = {
					points = {
						[1] = {
							type= AI.Task.WaypointType.TURNING_POINT,
							x = pos.x,
							y = pos.z,
							speed = 1000,
							action = AI.Task.VehicleFormation.OFF_ROAD
						},
						[2] = {
							type= AI.Task.WaypointType.TURNING_POINT,
							x = pos.x+math.random(25),
							y = pos.z+math.random(25),
							speed = 1000,
							action = AI.Task.VehicleFormation.DIAMOND
						},
					}
				}  
			}
        })
	end

	function TaskExtensions.moveOnRoadToPointAndAssault(group, point, targets, detour)
		if not group or not point then return end
		if not group:isExist() or group:getSize()==0 then return end
		local startPos = group:getUnit(1):getPoint()

		local srx, sry = land.getClosestPointOnRoads('roads', startPos.x, startPos.z)
		local erx, ery = land.getClosestPointOnRoads('roads', point.x, point.y)

		local mis = {
			id='Mission',
			params = {
				route = {
					points = {}
				}  
			}
		}

		if detour then
			local detourPoint = {x = startPos.x, y = startPos.z}

			local direction = {
				x = erx - startPos.x,
				y = ery - startPos.y
			}

			local magnitude = (direction.x^2 + direction.y^2) ^ 0.5
			if magnitude > 0.0 then
				direction.x = direction.x / magnitude
				direction.y = direction.y / magnitude

				local scale = math.random(250,500)
				direction.x = direction.x * scale
				direction.y = direction.y * scale

				detourPoint.x = detourPoint.x + direction.x
				detourPoint.y = detourPoint.y + direction.y
			else
				detourPoint.x = detourPoint.x + math.random(-500,500)
				detourPoint.y = detourPoint.y + math.random(-500,500)
			end
				
			table.insert(mis.params.route.points, {
				type= AI.Task.WaypointType.TURNING_POINT,
				x = detourPoint.x,
				y = detourPoint.y,
				speed = 1000,
				action = AI.Task.VehicleFormation.OFF_ROAD
			})

			srx, sry = land.getClosestPointOnRoads('roads', detourPoint.x, detourPoint.y)
		end

		
		table.insert(mis.params.route.points, {
			type= AI.Task.WaypointType.TURNING_POINT,
			x = srx,
			y = sry,
			speed = 1000,
			action = AI.Task.VehicleFormation.ON_ROAD
		})

		table.insert(mis.params.route.points, {
			type= AI.Task.WaypointType.TURNING_POINT,
			x = erx,
			y = ery,
			speed = 1000,
			action = AI.Task.VehicleFormation.ON_ROAD
		})

		table.insert(mis.params.route.points, {
			type= AI.Task.WaypointType.TURNING_POINT,
			x = point.x,
			y = point.y,
			speed = 1000,
			action = AI.Task.VehicleFormation.DIAMOND
		})
	

		for i,v in pairs(targets) do
			if v.type == 'defense' then
				local group = Group.getByName(v.name)
				if group then
					for i,v in ipairs(group:getUnits()) do
						local unpos = v:getPoint()
						local pnt = {x=unpos.x, y = unpos.z}
	
						table.insert(mis.params.route.points, {
							type= AI.Task.WaypointType.TURNING_POINT,
							x = pnt.x,
							y = pnt.y,
							speed = 10,
							action = AI.Task.VehicleFormation.DIAMOND
						})
					end
				end
			end
		end
		
		group:getController():setTask(mis)
	end
	
	function TaskExtensions.moveOnRoadToPoint(group, point, detour) -- point = {x,y}
		if not group or not point then return end
		if not group:isExist() or group:getSize()==0 then return end
		local startPos = group:getUnit(1):getPoint()
		
		local srx, sry = land.getClosestPointOnRoads('roads', startPos.x, startPos.z)
		local erx, ery = land.getClosestPointOnRoads('roads', point.x, point.y)

		local mis = {
			id='Mission',
			params = {
				route = {
					points = {
					}
				}  
			}
		}

		if detour then
			local detourPoint = {x = startPos.x, y = startPos.z}

			local direction = {
				x = erx - startPos.x,
				y = ery - startPos.y
			}

			local magnitude = (direction.x^2 + direction.y^2) ^ 0.5
			if magnitude > 0.0 then
				direction.x = direction.x / magnitude
				direction.y = direction.y / magnitude

				local scale = math.random(250,1000)
				direction.x = direction.x * scale
				direction.y = direction.y * scale

				detourPoint.x = detourPoint.x + direction.x
				detourPoint.y = detourPoint.y + direction.y
			else
				detourPoint.x = detourPoint.x + math.random(-500,500)
				detourPoint.y = detourPoint.y + math.random(-500,500)
			end
				
			table.insert(mis.params.route.points, {
				type= AI.Task.WaypointType.TURNING_POINT,
				x = detourPoint.x,
				y = detourPoint.y,
				speed = 1000,
				action = AI.Task.VehicleFormation.OFF_ROAD
			})

			srx, sry = land.getClosestPointOnRoads('roads', detourPoint.x, detourPoint.y)
		end

		table.insert(mis.params.route.points, {
			type= AI.Task.WaypointType.TURNING_POINT,
			x = srx,
			y = sry,
			speed = 1000,
			action = AI.Task.VehicleFormation.ON_ROAD
		})

		table.insert(mis.params.route.points, {
			type= AI.Task.WaypointType.TURNING_POINT,
			x = erx,
			y = ery,
			speed = 1000,
			action = AI.Task.VehicleFormation.ON_ROAD
		})

		table.insert(mis.params.route.points, {
			type= AI.Task.WaypointType.TURNING_POINT,
			x = point.x,
			y = point.y,
			speed = 1000,
			action = AI.Task.VehicleFormation.OFF_ROAD
		})

		group:getController():setTask(mis)
	end
	
	function TaskExtensions.landAtPointFromAir(group, point, alt)
		if not group or not point then return end
		if not group:isExist() or group:getSize()==0 then return end
		local startPos = group:getUnit(1):getPoint()

		local atype = AI.Task.AltitudeType.RADIO
		if alt then
			atype = AI.Task.AltitudeType.BARO
		else
			alt = 500
		end

		local land = {
			id='Land',
			params = {
				point = point
			}
		}
		
		local mis = {
			id='Mission',
			params = {
				route = {
					airborne = true,
					points = {
						[1] = {
							type= AI.Task.WaypointType.TURNING_POINT,
							x = startPos.x,
							y = startPos.z,
							speed = 500,
							action = AI.Task.TurnMethod.FIN_POINT,
							alt = alt,
							alt_type = atype
						},
						[2] = {
							type= AI.Task.WaypointType.TURNING_POINT,
							x = point.x,
							y = point.y,
							speed = 257,
							action = AI.Task.TurnMethod.FIN_POINT,
							alt = alt,
							alt_type = atype, 
							task = land
						}
					}
				}  
			}
		}
		
		group:getController():setTask(mis)
	end

	function TaskExtensions.landAtPoint(group, point, alt, skiptakeoff) -- point = {x,y}
		if not group or not point then return end
		if not group:isExist() or group:getSize()==0 then return end
		local startPos = group:getUnit(1):getPoint()

		local atype = AI.Task.AltitudeType.RADIO
		if alt then
			atype = AI.Task.AltitudeType.BARO
		else
			alt = 500
		end
		
		local land = {
			id='Land',
			params = {
				point = point
			}
		}

		local mis = {
			id='Mission',
			params = {
				route = {
					airborne = true,
					points = {}
				}  
			}
		}

		if not skiptakeoff then
			table.insert(mis.params.route.points,{
				type = AI.Task.WaypointType.TAKEOFF,
				x = startPos.x,
				y = startPos.z,
				speed = 0,
				action = AI.Task.TurnMethod.FIN_POINT,
				alt = alt,
				alt_type = atype
			})
		end
		
		table.insert(mis.params.route.points,{
			type = AI.Task.WaypointType.TURNING_POINT,
			x = point.x,
			y = point.y,
			speed = 257,
			action = AI.Task.TurnMethod.FIN_POINT,
			alt = alt,
			alt_type = atype, 
			task = land
		})
		
		group:getController():setTask(mis)
	end

	function TaskExtensions.landAtAirfield(group, point) -- point = {x,y}
		if not group or not point then return end
		if not group:isExist() or group:getSize()==0 then return end
		
		local mis = {
			id='Mission',
			params = {
				route = {
					airborne = true,
					points = {
						[1] = {
							type= AI.Task.WaypointType.TURNING_POINT,
							x = point.x,
							y = point.z,
							speed = 257,
							action = AI.Task.TurnMethod.FIN_POINT,
							alt = 4572,
							alt_type = AI.Task.AltitudeType.BARO
						},
						[2] = {
							type= AI.Task.WaypointType.LAND,
							x = point.x,
							y = point.z,
							speed = 257,
							action = AI.Task.TurnMethod.FIN_POINT,
							alt = 0,
							alt_type = AI.Task.AltitudeType.RADIO
						}
					}
				}  
			}
		}
		
		group:getController():setTask(mis)
	end

	function TaskExtensions.fireAtTargets(group, targets, amount)
		if not group then return end
		if not group:isExist() or group:getSize() == 0 then return end

		local units = {}
		for i,v in pairs(targets) do
			local g = Group.getByName(v.name)
			if g then
				for i2,v2 in ipairs(g:getUnits()) do
					table.insert(units, v2)
				end
			else
				local s = StaticObject.getByName(v.name)
				if s then
					table.insert(units, s)
				end
			end
		end
		
		if #units == 0 then
			return
		end
		
		local selected = {}
		for i=1,amount,1 do
			if #units == 0 then 
				break
			end
			
			local tgt = math.random(1,#units)
			
			table.insert(selected, units[tgt])
			table.remove(units, tgt)
		end
		
		while #selected < amount do
			local ind = math.random(1,#selected)
			table.insert(selected, selected[ind])
		end
		
		for i,v in ipairs(selected) do
			local unt = v
			if unt then
				local target = {}
				target.x = unt:getPosition().p.x
				target.y = unt:getPosition().p.z
				target.radius = 100
				target.expendQty = 1
				target.expendQtyEnabled = true
				local fire = {id = 'FireAtPoint', params = target}
				
				group:getController():pushTask(fire)
			end
		end
	end

	function TaskExtensions.carrierGoToPos(group, point)
		if not group or not point then return end
		if not group:isExist() or group:getSize()==0 then return end
		
		local mis = {
			id='Mission',
			params = {
				route = {
					airborne = true,
					points = {
						[1] = {
							type= AI.Task.WaypointType.TURNING_POINT,
							x = point.x,
							y = point.z,
							speed = 50,
							action = AI.Task.TurnMethod.FIN_POINT
						}
					}
				}  
			}
		}
		
		group:getController():setTask(mis)
	end

	function TaskExtensions.stopCarrier(group)
		if not group then return end
		if not group:isExist() or group:getSize()==0 then return end
		local point = group:getUnit(1):getPoint()

		group:getController():setTask({
			id='Mission',
			params = {
				route = {
					airborne = false,
					points = {
						[1] = {
							type= AI.Task.WaypointType.TURNING_POINT,
							x = point.x,
							y = point.z,
							speed = 0,
							action = AI.Task.TurnMethod.FIN_POINT
						}
					}
				}  
			}
		})
	end

	function TaskExtensions.setupCarrier(unit, icls, acls, tacan, link4, radio)
		if not unit then return end
		if not unit:isExist() then return end

		local commands = {}
		if icls then
			table.insert(commands, { 
				id = 'ActivateICLS', 
				params = {
				  type = 131584,
				  channel = icls, 
				  unitId = unit:getID(), 
				  name = "ICLS "..icls, 
				} 
			})
		end

		if acls then
			table.insert(commands, { 
				id = 'ActivateACLS', 
				params = {
				  unitId = unit:getID(), 
				  name = "ACLS",
				}
			})
		end

		if tacan then
			table.insert(commands, { 
				id = 'ActivateBeacon', 
				params = { 
				  type = 4, 
				  system = 4, 
				  name = "TACAN "..tacan.channel, 
				  callsign = tacan.callsign, 
				  frequency = tacan.channel, 
				  channel = tacan.channel,
				  bearing = true,
				  modeChannel = "X"
				}
			})
		end

		if link4 then
			table.insert(commands, { 
				id = 'ActivateLink4', 
				params = {
				  unitId = unit:getID(),
				  frequency = link4, 
				  name = "Link4 "..link4, 
				}
			})
		end

		if radio then
			table.insert(commands, {
				id = "SetFrequency",
				params = {
				   power = 100,
				   modulation = 0,
				   frequency = radio,
				}
			})
		end

		for i,v in ipairs(commands) do
			unit:getController():setCommand(v)
		end

		unit:getGroup():getController():setOption(AI.Option.Ground.id.AC_ENGAGEMENT_RANGE_RESTRICTION, 30)
	end
end

