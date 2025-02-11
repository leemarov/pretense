



ConnectionManager = {}
do
	ConnectionManager.currentLineIndex = 5000
	function ConnectionManager:new()
		local obj = {}
		obj.connections = {}
		obj.zoneConnections = {}
		obj.heliAlts = {}
		obj.blockedRoads = {}
		setmetatable(obj, self)
		self.__index = self

		DependencyManager.register("ConnectionManager", obj)
		return obj
	end

	function ConnectionManager:addConnection(f, t, blockedRoad, heliAlt)
		local i = ConnectionManager.currentLineIndex
		ConnectionManager.currentLineIndex = ConnectionManager.currentLineIndex + 1
		
		table.insert(self.connections, {from=f, to=t, index=i})
		self.zoneConnections[f] = self.zoneConnections[f] or {}
		self.zoneConnections[t] = self.zoneConnections[t] or {}
		self.zoneConnections[f][t] = true
		self.zoneConnections[t][f] = true
		
		if heliAlt then
			self.heliAlts[f] = self.heliAlts[f] or {}
			self.heliAlts[t] = self.heliAlts[t] or {}
			self.heliAlts[f][t] = heliAlt
			self.heliAlts[t][f] = heliAlt
		end

		if blockedRoad then
			self.blockedRoads[f] = self.blockedRoads[f] or {}
			self.blockedRoads[t] = self.blockedRoads[t] or {}
			self.blockedRoads[f][t] = true
			self.blockedRoads[t][f] = true
		end

		local from = CustomZone:getByName(f)
		local to = CustomZone:getByName(t)

		if not from then env.info("ConnectionManager - addConnection: missing zone "..f) end
		if not to then env.info("ConnectionManager - addConnection: missing zone "..t) end
		
		if blockedRoad then
			trigger.action.lineToAll(-1, i, from.point, to.point, {1,1,1,0.5}, 3)
		else
			trigger.action.lineToAll(-1, i, from.point, to.point, {1,1,1,0.5}, 2)
		end
	end
	
	function ConnectionManager:getConnectionsOfZone(zonename)
		if not self.zoneConnections[zonename] then return {} end
		
		local connections = {}
		for i,v in pairs(self.zoneConnections[zonename]) do
			table.insert(connections, i)
		end
		
		return connections
	end

	function ConnectionManager:isRoadBlocked(f,t)
		if self.blockedRoads[f] then 
			return self.blockedRoads[f][t]
		end

		if self.blockedRoads[t] then 
			return self.blockedRoads[t][f]
		end
	end

	function ConnectionManager:getHeliAltSimple(f,t)
		if self.heliAlts[f] then 
			if self.heliAlts[f][t] then
				return self.heliAlts[f][t]
			end
		end

		if self.heliAlts[t] then 
			if self.heliAlts[t][f] then
				return self.heliAlts[t][f]
			end
		end
	end

	function ConnectionManager:getHeliAlt(f,t)
		local alt = self:getHeliAltSimple(f,t)
		if alt then return alt end

		if self.heliAlts[f] then 
			local max = -1
			for zn,_ in pairs(self.heliAlts[f]) do
				local alt = self:getHeliAltSimple(f, zn)
				if alt then
					if alt > max then
						max = alt
					end
				end

				alt = self:getHeliAltSimple(zn, t)
				if alt then
					if alt > max then
						max = alt
					end
				end
			end
			
			if max > 0 then return max end
		end

		if self.heliAlts[t] then 
			local max = -1
			for zn,_ in pairs(self.heliAlts[t]) do
				local alt = self:getHeliAltSimple(t, zn)
				if alt then
					if alt > max then
						max = alt
					end
				end

				alt = self:getHeliAltSimple(zn, f)
				if alt then
					if alt > max then
						max = alt
					end
				end
			end

			if max > 0 then return max end
		end
	end
end

