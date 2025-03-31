



FARPCommand = {}
do
    FARPCommand.allFARPS = {}
	FARPCommand.currentIndex = 100000
    FARPCommand.isFARP = true

    function FARPCommand:new(name, range, maxResource)
        local st = StaticObject.getByName(name)
        if not st then return end

        local ab = Airbase.getByName(name)
        if ab then
            if ab:autoCaptureIsOn() then ab:autoCapture(false) end
            ab:setCoalition(2)
        end

        local obj = {}
        obj.name = name
        obj.range = range
        obj.side = 2
        obj.resource = 0
        obj.maxResource = maxResource or 20000
		obj.spendTreshold = 0
        obj.isHeloSpawn = false
        obj.isPlaneSpawn = false
        obj.distToFront = 1
        obj.zone = {
            point = st:getPoint()
        }
        obj.revealTime = 0

        obj.featureBuildings = {}
		
        obj.index = FARPCommand.currentIndex
		FARPCommand.currentIndex = FARPCommand.currentIndex + 1

        local point = st:getPoint()

        local color = {0.7,0.7,0.7,0.3}
		if obj.side == 1 then
			color = {1,0,0,0.3}
		elseif obj.side == 2 then
			color = {0,0,1,0.3}
		end

        trigger.action.circleToAll(-1,3000+obj.index,point, obj.range, color, color, 1)
        
        point.z = point.z + obj.range
        trigger.action.textToAll(-1,2000+obj.index, point, {0,0,0,0.8}, {1,1,1,0.5}, 15, true, '')
		
        setmetatable(obj, self)
		self.__index = self

        obj:start()
        obj:refreshText()
		FARPCommand.allFARPS[obj.name] = obj
        return obj
    end

    function FARPCommand:scheduleRemoval()
        self.isDeleted = true
		trigger.action.setMarkupColor(3000+self.index, {0.3,0.3,0.3,0.3})
		trigger.action.setMarkupColorFill(3000+self.index, {0.3,0.3,0.3,0.3})

        local pl = DependencyManager.get('PlayerLogistics')
        local trackedBuildings = pl.trackedBuildings
        for i,v in pairs(self:getAllFeatureBuildings()) do
            if trackedBuildings[v.name] then
                trackedBuildings[v.name].isDeleted = true
                local st = StaticObject.getByName(v.name) or Group.getByName(v.name)
                if st and st:isExist() then 
                    local pos = nil
                    if st.getPoint then 
                        pos = st:getPoint()
                    elseif st.getSize and st:getSize()>0 and st.getUnit then
                        local stu = st:getUnit(1)
                        pos = stu:getPoint()
                    end

                    if pos then
                        local amount = math.random(250,750)

                        local cname = pl:generateCargoName("Salvage")
                        local ctype = pl:getBoxType(amount)

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

                        pl.trackedBoxes[cname] = {name=cname, amount = amount, type=ctype, origin = origin, lifetime=60*60*2, isSalvage=true}

                        st:destroy() 
                    end
                end
            end
        end

        if trackedBuildings[self.name] then
            trackedBuildings[self.name].isDeleted = true
        end

        self:refreshText()
    end

    function FARPCommand:start()
        timer.scheduleFunction(function(param, time)
            local self = param.context
            self:refreshFeatures()
            if self:hasFeature(PlayerLogistics.buildables.generator) then
                self:addResource(5)
            end

            self:refreshText()
            if not self.isDeleted then
                return time+10
            end
        end, {context = self}, timer.getTime()+1)
    end

	function FARPCommand:clearDrawings()
		if not self.cleared then
			trigger.action.removeMark(2000+self.index)
			trigger.action.removeMark(3000+self.index)
			self.cleared = true
		end
	end

    function FARPCommand:addResource(amount)
		self.resource = self.resource+amount
		self.resource = math.floor(math.min(self.resource, self.maxResource))
        self:refreshText()
    end

    function FARPCommand:removeResource(amount)
		self.resource = self.resource-amount
		self.resource = math.floor(math.max(self.resource, 0))
        self:refreshText()
    end

    function FARPCommand:refreshText()
        if self.isDeleted then
            trigger.action.setMarkupText(2000+self.index, '')
            return
        end

		local color = {0.3,0.3,0.3,1}
		if self.side == 1 then
			color = {0.5,0,0,1}
		elseif self.side == 2 then
			color = {0,0,0.5,1}
		end

		trigger.action.setMarkupColor(2000+self.index, color)

		local label = '['..self.resource..'/'..self.maxResource..']'
        
        local features = {}
        for i,v in pairs(self.featureBuildings) do
            local symbol = FARPCommand.getFeatureSymbol(i)
            table.insert(features, symbol)
        end
        if #features > 0 then
            table.sort(features)
            label = label..'\n'
            for _,v in ipairs(features) do
                label = label..v
            end
        end
        
		if self.side == 1 then
			if self.revealTime > 0 then
				trigger.action.setMarkupText(2000+self.index, self.name..label)
			else
				trigger.action.setMarkupText(2000+self.index, self.name)
			end
		elseif self.side == 2 then
			trigger.action.setMarkupText(2000+self.index, self.name..label)
		elseif self.side == 0 then
			trigger.action.setMarkupText(2000+self.index, ' '..self.name..' ')
		end

        if self.side == 2 and (self.isHeloSpawn or self.isPlaneSpawn) then
			trigger.action.setMarkupTypeLine(3000+self.index, 2)
			trigger.action.setMarkupColor(3000+self.index, {0,1,0,1})
		end

        local st = StaticObject.getByName(self.name)
        local point = st:getPoint()
        trigger.action.setMarkupPositionStart(3000+self.index, point)

        point.z = point.z + self.range
        trigger.action.setMarkupPositionStart(2000+self.index, point)
    end

    function FARPCommand:capture(side)
    end

    function FARPCommand:pushMisOfType(mistype)
	end

    function FARPCommand:criticalOnSupplies()
		return self.resource<=self.spendTreshold
    end

    function FARPCommand.getFeatureSymbol(featureType)
        if featureType == PlayerLogistics.buildables.ammo then
            return ' Ammo'
        elseif featureType == PlayerLogistics.buildables.fuel then
            return ' Fuel'
        elseif featureType == PlayerLogistics.buildables.forklift then
            return ' Lft'
        elseif featureType == PlayerLogistics.buildables.generator then
            return ' Gen'
        elseif featureType == PlayerLogistics.buildables.medtent then
            return ' Med'
        elseif featureType == PlayerLogistics.buildables.radar then
            return ' Rad'
        elseif featureType == PlayerLogistics.buildables.satuplink then
            return ' Sat'
        elseif featureType == PlayerLogistics.buildables.tent then
            return ' Com'
        end

        return ''
    end

    function FARPCommand:getAllFeatureBuildings()
        local st = StaticObject.getByName(self.name)
        if not st then return end

        local trackedBuildings = DependencyManager.get('PlayerLogistics').trackedBuildings

        local pos = st:getPoint()

        local results = {}
        for i,v in pairs(trackedBuildings) do
            if v.type ~= PlayerLogistics.buildables.farp then
                local pos = nil
                local bl = StaticObject.getByName(i)
                if bl and bl:isExist() then
                    pos = bl:getPoint()
                end

                if not pos then 
                    bl = Group.getByName(i)
                    if bl and bl:isExist() and bl:getSize()>0 then
                        pos = bl:getUnit(1):getPoint()
                    end
                end

                if pos then
                    local bfarp = FARPCommand.getFARPOfPoint(pos)
                    if bfarp.name == self.name then
                        table.insert(results, v)
                    end
                end
            end
        end

        return results
    end

    function FARPCommand:refreshFeatures()
        local st = StaticObject.getByName(self.name)
        if not st then return end

        local trackedBuildings = DependencyManager.get('PlayerLogistics').trackedBuildings

        local pos = st:getPoint()

        for i,v in pairs(trackedBuildings) do
            if v.type ~= PlayerLogistics.buildables.farp then
                local pos = nil
                local bl = StaticObject.getByName(i)
                if bl and bl:isExist() then
                    pos = bl:getPoint()
                end

                if not pos then 
                    bl = Group.getByName(i)
                    if bl and bl:isExist() and bl:getSize()>0 then
                        pos = bl:getUnit(1):getPoint()
                    end
                end

                if pos then
                    local bfarp = FARPCommand.getFARPOfPoint(pos)
                    if bfarp and bfarp.name == self.name then
                        self.featureBuildings[v.type]=v.name
                    end
                end
            end
        end
    end

    function FARPCommand:hasFeature(feature)
        local fb = self.featureBuildings[feature]
        if fb then
            local s = StaticObject.getByName(fb)
            if s then return true end
            local g = Group.getByName(fb)
            if g then return true end
        end
    end

    function FARPCommand.getFARPByName(name)
		if not name then return nil end
		return FARPCommand.allFARPS[name]
	end
	
	function FARPCommand.getAllFARPs()
		return FARPCommand.allFARPS
	end
	
	function FARPCommand.getFARPOfUnit(unitname)
		local un = Unit.getByName(unitname)
		
		if not un then 
			return nil
		end
		
		for i,v in pairs(FARPCommand.allFARPS) do
            local farp = StaticObject.getByName(v.name)
            if farp then
                if Utils.isInCircle(un:getPoint(), farp:getPoint(), v.range) then
                    return v
                end
            end
		end
		
		return nil
	end

	function FARPCommand.getClosestFARPToPoint(point)
		local minDist = 9999999
		local closest = nil
		for i,v in pairs(FARPCommand.allFARPS) do
            local farp = StaticObject.getByName(v.name)
            if farp then
                local d = mist.utils.get2DDist(farp:getPoint(), point)
                if d < minDist then
                    minDist = d
                    closest = v
                end
            end
		end
		
		return closest, minDist
	end
	
	function FARPCommand.getFARPOfPoint(point)
		for i,v in pairs(FARPCommand.allFARPS) do
			local farp = StaticObject.getByName(v.name)
            if farp and farp:getPoint() then
                if Utils.isInCircle(point, farp:getPoint(), v.range) then
                    return v
                end
            end
		end
		
		return nil
	end

    function FARPCommand.getFARPOfWeapon(weapon)		
        if not weapon then 
            return nil
        end
        
        return FARPCommand.getFARPOfPoint(weapon:getPoint())
    end
end

