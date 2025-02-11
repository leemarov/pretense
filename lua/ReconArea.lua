



ReconArea = {}
do
    ReconArea.currentIndex = 80000
    ReconArea.defaultLifetime = 60*60

    function ReconArea:new(zoneName, productName)
        local obj = {}
        obj.name = ""
        obj.points = {}
        obj.lifetime = ReconArea.defaultLifetime
        obj.padding = 250

        obj.zonename = zoneName
        obj.productname = productName

        obj.index = ReconArea.currentIndex
		ReconArea.currentIndex = ReconArea.currentIndex + 1

        setmetatable(obj, self)
		self.__index = self
        return obj
    end

    function ReconArea:getCenterAndRadius()
        local center = { x=0, z=0}

        for _,point in ipairs(self.points) do
            center.x = center.x + point.x
            center.z = center.z + point.z
        end

        center.x = center.x/#self.points
        center.z = center.z/#self.points

        local maxdist = 0
        for _,point in ipairs(self.points) do
            local dist = mist.utils.get2DDist(center, point)
            maxdist = math.max(maxdist, dist)
        end

        return center, maxdist
    end

    function ReconArea:refreshMovingGroup()
        if not self.group or not self.group:isExist() or self.group:getSize() == 0 then 
            self:remove()
            return true
        end

        self.points = {}
        for i,v in ipairs(self.group:getUnits()) do
            self:addPoint(v:getPoint())
        end

        local center, maxdist = self:getCenterAndRadius()
        
        trigger.action.setMarkupPositionStart(self.index, center)
        trigger.action.setMarkupRadius(self.index, maxdist+self.padding)
        trigger.action.setMarkupPositionStart(self.index+10000, {x = center.x, z = center.z+maxdist+self.padding})
    end

    function ReconArea:drawMovingGroup(group)
        if not group or not group:isExist() or group:getSize() == 0 then return end
        
        self.group = group

        self.points = {}
        for i,v in ipairs(group:getUnits()) do
            self:addPoint(v:getPoint())
        end

        local center, maxdist = self:getCenterAndRadius()
        local border = {0,0,0,0.7}
        local background = {1,1,1,0.05}
        trigger.action.circleToAll(-1,self.index, center, maxdist + self.padding, border, background, 3)
        trigger.action.textToAll(-1, self.index+10000, {x = center.x, z = center.z+maxdist+self.padding}, {0,0,0,0.7}, {0,0,0,0}, 15, true, self.name)
    end

    function ReconArea:draw()
        local square = {
            left = 0,
            right = 0,
            top = 0,
            bottom = 0,
        }

        if self.points[1] then
            local p = self.points[1]
            square.left = p.z
            square.right = p.z
            square.top = p.x
            square.bottom = p.x
        end

        for _,point in ipairs(self.points) do
            if point.x < square.bottom then square.bottom = point.x end
            if point.x > square.top then square.top = point.x end
            if point.z < square.left then square.left = point.z end
            if point.z > square.right then square.right = point.z end
        end

        square.bottom = square.bottom - self.padding
        square.top = square.top + self.padding
        square.left = square.left - self.padding
        square.right = square.right + self.padding
        
        local border = {0,0,0,0.7}
        local background = {1,1,1,0.05}

		trigger.action.quadToAll(-1,self.index, 
            {x = square.top, z = square.left},
            {x = square.top, z = square.right},
            {x = square.bottom, z = square.right},
            {x = square.bottom, z = square.left},
            border,background,3)

        trigger.action.textToAll(-1, self.index+10000, {x = square.top, z = square.left}, {0,0,0,0.7}, {0,0,0,0}, 15, true, self.name)
    end

    function ReconArea:remove()
        trigger.action.removeMark(self.index)
        trigger.action.removeMark(self.index+10000)
    end

    function ReconArea:addPoint(point)
        table.insert(self.points, point)
    end
end

