
ObjDestroyUnitsWithAttributeAtZone = Objective:new(Objective.types.destroy_attr_at_zone)
do
    ObjDestroyUnitsWithAttributeAtZone.requiredParams = {
        ['attr']=true,
        ['amount'] = true,
        ['killed'] = true,
        ['tgtzone'] = true
    }

    function ObjDestroyUnitsWithAttributeAtZone:getText()
        local msg = 'Destroy at '..self.param.tgtzone.name..': '
        for _,v in ipairs(self.param.attr) do
            msg = msg..v..', '
        end
        msg = msg:sub(1,#msg-2)
        msg = msg..'\n Progress: '..self.param.killed..'/'..self.param.amount
        return msg
    end

    function ObjDestroyUnitsWithAttributeAtZone:update()
        if not self.isComplete and not self.isFailed then
            if self.param.killed >= self.param.amount then
                self.isComplete = true
                return true
            end

            local zn = self.param.tgtzone
            if zn.side ~= 1 or not zn:hasUnitWithAttributeOnSide(self.param.attr, 1) then 
                if self.firstFailure == nil then
                    self.firstFailure = timer.getAbsTime()
                else
                    if timer.getAbsTime() - self.firstFailure > 5*60 then
                        self.isFailed = true
                        self.mission.failureReason = zn.name..' no longer has targets matching the description.'
                        return true
                    end
                end
            else
                if self.firstFailure ~= nil then
                    self.firstFailure = nil
                end
            end
        end
    end

    function ObjDestroyUnitsWithAttributeAtZone:checkFail()
        if not self.isComplete and not self.isFailed then
            local zn = self.param.tgtzone
            if zn.side ~= 1 or not zn:hasUnitWithAttributeOnSide(self.param.attr, 1) then 
                self.isFailed = true
            end
        end
    end
end

