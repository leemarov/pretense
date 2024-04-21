
CarrierMap = {}
do
	CarrierMap.currentIndex = 15000
    function CarrierMap:new(zoneList)

        local obj = {}
        obj.zones = {}

        for i,v in ipairs(zoneList) do
            local zn = CustomZone:getByName(v)

            local id = CarrierMap.currentIndex
            CarrierMap.currentIndex = CarrierMap.currentIndex + 1
            
            zn:draw(id, {1,1,1,0.2}, {1,1,1,0.2})
            obj.zones[v] = {zone = zn, waypoints = {}}

            for subi=1,1000,1 do
                local subname = v..'-'..subi
                if CustomZone:getByName(subname) then
                    table.insert(obj.zones[v].waypoints, subname)
                else
                    break
                end
            end

            id = CarrierMap.currentIndex
            CarrierMap.currentIndex = CarrierMap.currentIndex + 1

            trigger.action.textToAll(-1, id , zn.point, {0,0,0,0.8}, {1,1,1,0}, 15, true, v)
            for i,wps in ipairs(obj.zones[v].waypoints) do
                id = CarrierMap.currentIndex
                CarrierMap.currentIndex = CarrierMap.currentIndex + 1
                local point = CustomZone:getByName(wps).point
                trigger.action.textToAll(-1, id, point, {0,0,0,0.8}, {1,1,1,0}, 10, true, wps)
            end
        end

        setmetatable(obj, self)
		self.__index = self

        return obj
    end

    function CarrierMap:getNavMap()
        local map = {}
        for nm, zn in pairs(self.zones) do
            table.insert(map, {name = zn.zone.name, waypoints = zn.waypoints})
        end

        table.sort(map, function(a,b) return a.name < b.name end)
        return map
    end
end

