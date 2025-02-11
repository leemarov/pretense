



MiniGCI = {}

do
    function MiniGCI:new(side)
        local o = {}
        o.side = side
        o.tgtSide = 0
        if side == 1 then
            o.tgtSide = 2
        elseif side == 2 then
            o.tgtSide = 1
        end

        o.radars = {}
        o.contacts = {}
        o.lastContactsTime = 0
        o.radarTypes = {
            'SAM SR',
            'EWR',
            'AWACS'
        }

        setmetatable(o, self)
		self.__index = self
		return o
    end

    function MiniGCI:refreshRadars()
        local allunits = coalition.getGroups(self.side)

        local radars = {}
        for _,g in ipairs(allunits) do
            for _,u in ipairs(g:getUnits()) do
                for _,a in ipairs(self.radarTypes) do
                    if u:hasAttribute(a) then
                        table.insert(radars, u)
                        break
                    end
                end
            end
        end

        self.radars = radars
    end

    function MiniGCI:scanForContacts()
        local dect = {}
        for _,u in ipairs(self.radars) do
            if u:isExist() then
                local detected = u:getController():getDetectedTargets(Controller.Detection.RADAR)
                for _,d in ipairs(detected) do
                    if d and d.object and d.object.isExist and d.object:isExist() and 
                        Object.getCategory(d.object) == Object.Category.UNIT and
                        d.object.getCoalition and
                        d.object:getCoalition() == self.tgtSide then
                            
                        if not dect[d.object:getName()] then
                            dect[d.object:getName()] = d.object
                        end
                    end
                end
            end
        end

        self.contacts = dect
        self.lastContactsTime = timer.getTime()
    end

    function MiniGCI:getContacts()
        return self.contacts
    end
end

