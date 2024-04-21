
Utils = {}
do
	local JSON = (loadfile('Scripts/JSON.lua'))()

	function Utils.getPointOnSurface(point)
		return {x = point.x, y = land.getHeight({x = point.x, y = point.z}), z= point.z}
	end
	
	function Utils.getTableSize(tbl)
		local cnt = 0
		for i,v in pairs(tbl) do cnt=cnt+1 end
		return cnt
	end

	function Utils.isInArray(value, array)
		for _,v in ipairs(array) do
			if value == v then
				return true
			end
		end
	end

	Utils.cache = {}
	Utils.cache.groups = {}
	function Utils.getOriginalGroup(groupName)
		if Utils.cache.groups[groupName] then
			return Utils.cache.groups[groupName]
		end

		for _,coalition in pairs(env.mission.coalition) do
			for _,country in pairs(coalition.country) do
				local tocheck = {}
				table.insert(tocheck, country.plane)
				table.insert(tocheck, country.helicopter)
				table.insert(tocheck, country.ship)
				table.insert(tocheck, country.vehicle)
				table.insert(tocheck, country.static)

				for _, checkGroup in ipairs(tocheck) do
					for _,item in pairs(checkGroup.group) do
						Utils.cache.groups[item.name] = item
						if item.name == groupName then
							return item
						end
					end
				end
			end
		end
	end
	
	function Utils.getBearing(fromvec, tovec)
		local fx = fromvec.x
		local fy = fromvec.z
		
		local tx = tovec.x
		local ty = tovec.z
		
		local brg = math.atan2(ty - fy, tx - fx)
		
		
		if brg < 0 then
			 brg = brg + 2 * math.pi
		end
		
		brg = brg * 180 / math.pi
		

		return brg
	end

	function Utils.getHeadingDiff(heading1, heading2) -- heading1 + result == heading2
		local diff = heading1 - heading2
		local absDiff = math.abs(diff)
		local complementaryAngle = 360 - absDiff
	
		if absDiff <= 180 then 
			return -diff
		elseif heading1 > heading2 then
			return complementaryAngle
		else
			return -complementaryAngle
		end
	end
	
	function Utils.getAGL(object)
		local pt = object:getPoint()
		return pt.y - land.getHeight({ x = pt.x, y = pt.z })
	end

	function Utils.round(number)
		return math.floor(number+0.5)
	end
	
	function Utils.isLanded(unit, ignorespeed)
		--return (Utils.getAGL(unit)<5 and mist.vec.mag(unit:getVelocity())<0.10)
		
		if ignorespeed then
			return not unit:inAir()
		else
			return (not unit:inAir() and mist.vec.mag(unit:getVelocity())<1)
		end
	end

	function Utils.getEnemy(ofside)
		if ofside == 1 then return 2 end
		if ofside == 2 then return 1 end
	end
	
	function Utils.isGroupActive(group)
		if group and group:getSize()>0 and group:getController():hasTask() then 
			return not Utils.allGroupIsLanded(group, true)
		else
			return false
		end
	end
	
	function Utils.isInAir(unit)
		--return Utils.getAGL(unit)>5
		return unit:inAir()
	end
	
	function Utils.isInZone(unit, zonename)
		local zn = CustomZone:getByName(zonename)
		if zn then
			return zn:isInside(unit:getPosition().p)
		end
		
		return false
	end

	function Utils.isInCircle(point, center, radius)
		local dist = mist.utils.get2DDist(point, center)
		return dist<radius
	end
	
	function Utils.isCrateSettledInZone(crate, zonename)
		local zn = CustomZone:getByName(zonename)
		if zn and crate then
			return (zn:isInside(crate:getPosition().p) and Utils.getAGL(crate)<1)
		end
		
		return false
	end
	
	function Utils.someOfGroupInZone(group, zonename)
		for i,v in pairs(group:getUnits()) do
			if Utils.isInZone(v, zonename) then
				return true
			end
		end
		
		return false
	end
	
	function Utils.allGroupIsLanded(group, ignorespeed)
		for i,v in pairs(group:getUnits()) do
			if not Utils.isLanded(v, ignorespeed) then
				return false
			end
		end
		
		return true
	end
	
	function Utils.someOfGroupInAir(group)
		for i,v in pairs(group:getUnits()) do
			if Utils.isInAir(v) then
				return true
			end
		end
		
		return false
	end
	
	Utils.canAccessFS = true
	function Utils.saveTable(filename, data)
		if not Utils.canAccessFS then 
			return
		end
		
		if not io then
			Utils.canAccessFS = false
			trigger.action.outText('Persistance disabled', 30)
			return
		end
	
		local str = JSON:encode(data)
		-- local str = 'return (function() local tbl = {}'
		-- for i,v in pairs(data) do
		-- 	str = str..'\ntbl[\''..i..'\'] = '..Utils.serializeValue(v)
		-- end
		
		-- str = str..'\nreturn tbl end)()'
	
		local File = io.open(filename, "w")
		File:write(str)
		File:close()
	end
	
	function Utils.serializeValue(value)
		local res = ''
		if type(value)=='number' or type(value)=='boolean' then
			res = res..tostring(value)
		elseif type(value)=='string' then
			res = res..'\''..value..'\''
		elseif type(value)=='table' then
			res = res..'{ '
			for i,v in pairs(value) do
				if type(i)=='number' then
					res = res..'['..i..']='..Utils.serializeValue(v)..','
				else
					res = res..'[\''..i..'\']='..Utils.serializeValue(v)..','
				end
			end
			res = res:sub(1,-2)
			res = res..' }'
		end
		return res
	end
	
	function Utils.loadTable(filename)
		if not Utils.canAccessFS then 
			return
		end
		
		if not lfs then
			Utils.canAccessFS = false
			trigger.action.outText('Persistance disabled', 30)
			return
		end
		
		if lfs.attributes(filename) then
			local File = io.open(filename, "r")
			local str = File:read('*all')
			File:close()

			return JSON:decode(str)
		end
	end
	
	function Utils.merge(table1, table2)
		local result = {}
		for i,v in pairs(table1) do
			result[i] = v
		end
		
		for i,v in pairs(table2) do
			result[i] = v
		end
		
		return result
	end

	function Utils.log(func)
		return function(p1,p2,p3,p4,p5,p6,p7,p8,p9,p10)
			local err, msg = pcall(func,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10)
			if not err then
				env.info("ERROR - callFunc\n"..msg)
				env.info('Traceback\n'..debug.traceback())
			end
		end
	end

	function Utils.getAmmo(group, type)
		local count = 0
		for _, u in ipairs(group:getUnits()) do
			if u:isExist() then
				local ammo = u:getAmmo()
				for i,v in pairs(ammo) do
					if v.desc.typeName == type then
						count = count + v.count
					end
				end
			end
		end

		return count
	end
end



