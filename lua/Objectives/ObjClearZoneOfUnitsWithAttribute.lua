



ObjClearZoneOfUnitsWithAttribute = Objective:new(Objective.types.clear_attr_at_zone)
do
    ObjClearZoneOfUnitsWithAttribute.requiredParams = {
        ['attr'] = true,
        ['tgtzone'] = true
    }

    function ObjClearZoneOfUnitsWithAttribute:getText()
        local msg = 'Clear '..self.param.tgtzone.name..' of: '
        for _,v in ipairs(self.param.attr) do
            msg = msg..v..', '
        end
        msg = msg:sub(1,#msg-2)
        msg = msg..'\n Progress: '..self.param.tgtzone:getUnitCountWithAttributeOnSide(self.param.attr, 1)..' left'
        return msg
    end

    function ObjClearZoneOfUnitsWithAttribute:update()
        if not self.isComplete and not self.isFailed then
            local zn = self.param.tgtzone
            if zn.side ~= 1 or not zn:hasUnitWithAttributeOnSide(self.param.attr, 1) then 
                self.isComplete = true
                return true
            end
        end
    end

    function ObjClearZoneOfUnitsWithAttribute:checkFail()
        -- can not fail
    end
end

