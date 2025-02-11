




CustomZone = {}
do
	function CustomZone:getByName(name)
		local obj = {}
		obj.name = name
		
		local zd = nil
		for _,v in ipairs(env.mission.triggers.zones) do
			if v.name == name then
				zd = v
				break
			end
		end
		
		if not zd then
			return nil
		end
		
		obj.type = zd.type -- 2 == quad, 0 == circle
		if obj.type == 2 then
			obj.vertices = {}
			for _,v in ipairs(zd.verticies) do
				local vertex = {
					x = v.x,
					y = 0,
					z = v.y
				}
				table.insert(obj.vertices, vertex)
			end
		end
		
		obj.radius = zd.radius
		obj.point = {
			x = zd.x,
			y = 0,
			z = zd.y
		}
		
		setmetatable(obj, self)
		self.__index = self
		return obj
	end
	
	function CustomZone:isQuad()
		return self.type==2
	end
	
	function CustomZone:isCircle()
		return self.type==0
	end
	
	function CustomZone:isInside(point)
		if self:isCircle() then
			local dist = mist.utils.get2DDist(point, self.point)
			return dist<self.radius
		elseif self:isQuad() then
			return mist.pointInPolygon(point, self.vertices)
		end
	end
	
	function CustomZone:draw(id, border, background)
		if self:isCircle() then
			trigger.action.circleToAll(-1,id,self.point, self.radius,border,background,1)
		elseif self:isQuad() then
			trigger.action.quadToAll(-1,id,self.vertices[4], self.vertices[3], self.vertices[2], self.vertices[1],border,background,1)
		end
	end
	
	function CustomZone:getRandomSpawnZone()
		local spawnZones = {}
		for i=1,100,1 do
			local zname = self.name..'-'..i
			if trigger.misc.getZone(zname) then
				table.insert(spawnZones, zname)
			else
				break
			end
		end
		
		if #spawnZones == 0 then return nil end
		
		local choice = math.random(1, #spawnZones)
		return spawnZones[choice]
	end
	
	function CustomZone:spawnGroup(product, acceptedSurface)
		local spname = self.name
		local spawnzone = nil
		
		if not spawnzone then
			spawnzone = self:getRandomSpawnZone()
		end
		
		if spawnzone then
			spname = spawnzone
		end

		if not acceptedSurface then
			acceptedSurface = {
				[land.SurfaceType.LAND] = true
			}
		end
		
		local pnt = mist.getRandomPointInZone(spname)
		for i=1,500,1 do
			if acceptedSurface[land.getSurfaceType(pnt)] then
				break
			end

			pnt = mist.getRandomPointInZone(spname)
		end

		local template = product.template
		if product.templates then
			template = product.templates[math.random(1, #product.templates)]
		end

		local newgr = Spawner.createObject(product.name, template, pnt, product.side, nil, nil, acceptedSurface, spname)

		return newgr
	end
end






