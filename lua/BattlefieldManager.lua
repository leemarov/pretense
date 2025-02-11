



BattlefieldManager = {}
do
	BattlefieldManager.closeOverride = 27780 -- 15nm
	BattlefieldManager.farOverride = Config.maxDistFromFront -- default 100nm
	BattlefieldManager.boostScale = {[0] = 1.0, [1]=1.0, [2]=1.0}
	BattlefieldManager.noRedZones = false
	BattlefieldManager.noBlueZones = false
	
	function BattlefieldManager:new()
		local obj = {}
		
		setmetatable(obj, self)
		self.__index = self
		obj:start()
		return obj
	end
	
	function BattlefieldManager:start()
		timer.scheduleFunction(function(param, time)
			local self = param.context
			
			local zones = ZoneCommand.getAllZones()
			local torank = {}
			
			--reset ranks and define frontline
			for name,zone in pairs(zones) do
				zone.distToFront = nil
				zone.closestEnemyDist = nil
				
				if zone.neighbours then
					for nName, nZone in pairs(zone.neighbours) do
						if zone.side ~= nZone.side then
							zone.distToFront = 0
						end
					end
				end
				
				--set dist to closest enemy
				for name2,zone2 in pairs(zones) do
					if zone.side ~= zone2.side then
						local dist = mist.utils.get2DDist(zone.zone.point, zone2.zone.point)
						if not zone.closestEnemyDist or dist < zone.closestEnemyDist then
							zone.closestEnemyDist = dist
						end
					end
				end
			end
			
			for name,zone in pairs(zones) do
				if zone.distToFront == 0 then
					for nName, nZone in pairs(zone.neighbours) do
						if nZone.distToFront == nil then
							table.insert(torank, nZone)
						end
					end
				end
			end

			-- build ranks of every other zone
			while #torank > 0 do
				local nexttorank = {}
				for _,zone in ipairs(torank) do
					if not zone.distToFront then
						local minrank = 999
						for nName,nZone in pairs(zone.neighbours) do
							if nZone.distToFront then
								if nZone.distToFront<minrank then
									minrank = nZone.distToFront
								end
							else
								table.insert(nexttorank, nZone)
							end
						end
						zone.distToFront = minrank + 1
					end
				end
				torank = nexttorank
			end
			
			for name, zone in pairs(zones) do
				if zone.keepActive then
					if zone.closestEnemyDist and zone.closestEnemyDist > BattlefieldManager.farOverride and zone.distToFront > 3 then
						zone.mode = ZoneCommand.modes.export
					else
						if zone.mode ~= ZoneCommand.modes.normal then
							zone:fullBuild(1.0)
						end
						zone.mode = ZoneCommand.modes.normal
					end
				else
					if not zone.distToFront or zone.distToFront == 0 or (zone.closestEnemyDist and zone.closestEnemyDist < BattlefieldManager.closeOverride) then
						if zone.mode ~= ZoneCommand.modes.normal then
							zone:fullBuild(1.0)
						end
						zone.mode = ZoneCommand.modes.normal
					elseif zone.distToFront == 1 then
						zone.mode = ZoneCommand.modes.supply
					elseif zone.distToFront > 1 then
						zone.mode = ZoneCommand.modes.export
					end
				end

				zone.boostScale = self.boostScale[zone.side]
			end
			
			return time+60
		end, {context = self}, timer.getTime()+1)

		timer.scheduleFunction(function(param, time)
			local self = param.context
			
			local zones = ZoneCommand.getAllZones()
			
			local noRed = true
			local noBlue = true
			for name, zone in pairs(zones) do
				if zone.side == 1 then
					noRed = false
				elseif zone.side == 2 then
					noBlue = false
				end

				if not noRed and not noBlue then
					break
				end
			end

			if noRed then
				BattlefieldManager.noRedZones = true
			end

			if noBlue then
				BattlefieldManager.noBlueZones = true
			end
			
			return time+10
		end, {context = self}, timer.getTime()+1)

		timer.scheduleFunction(function(param, time)
			local x = math.random(-50,50) -- the lower limit benefits blue, higher limit benefits red, adjust to increase limit of random boost variance, default (-50,50)
			local boostIntensity = Config.randomBoost -- adjusts the intensity of the random boost variance, default value = 0.0004
			local factor = (x*x*x*boostIntensity)/100  -- the farther x is the higher the factor, negative beneifts blue, pozitive benefits red
			param.context.boostScale[1] = 1.0+factor
			param.context.boostScale[2] = 1.0-factor

			local red = 0
			local blue = 0
			for i,v in pairs(ZoneCommand.getAllZones()) do
				if v.side == 1 then
					red = red + 1
				elseif v.side == 2 then
					blue = blue + 1
				end

				--v:cleanup()
			end

			-- push factor towards coalition with less zones (up to 0.5)
			local multiplier = Config.lossCompensation -- adjust this to boost losing side production(higher means losing side gains more advantage) (default 1.25)
			local total = red + blue
			local redp = (0.5-(red/total))*multiplier
			local bluep = (0.5-(blue/total))*multiplier

			-- cap factor to avoid increasing difficulty until the end
			redp = math.min(redp, 0.15)
			bluep = math.max(bluep, -0.15)

			param.context.boostScale[1] = param.context.boostScale[1] + redp
			param.context.boostScale[2] = param.context.boostScale[2] + bluep

			--limit to numbers above 0
			param.context.boostScale[1] = math.max(0.01,param.context.boostScale[1])
			param.context.boostScale[2] = math.max(0.01,param.context.boostScale[2])

			env.info('BattlefieldManager - power red = '..param.context.boostScale[1])
			env.info('BattlefieldManager - power blue = '..param.context.boostScale[2])

			return time+(60*30)
		end, {context = self}, timer.getTime()+1)
	end
end

