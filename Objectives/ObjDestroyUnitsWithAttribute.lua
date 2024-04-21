
ObjDestroyUnitsWithAttribute = Objective:new(Objective.types.destroy_attr)
do
    ObjDestroyUnitsWithAttribute.requiredParams = {
        ['attr'] = true,
        ['amount'] = true,
        ['killed'] = true
    }

    function ObjDestroyUnitsWithAttribute:getText()
        local msg = 'Destroy: '
        for _,v in ipairs(self.param.attr) do
            msg = msg..v..', '
        end
        msg = msg:sub(1,#msg-2)
        msg = msg..'\n Progress: '..self.param.killed..'/'..self.param.amount
        return msg
    end

    function ObjDestroyUnitsWithAttribute:update()
        if not self.isComplete and not self.isFailed then
            if self.param.killed >= self.param.amount then
                self.isComplete = true
                return true
            end
        end
    end

    function ObjDestroyUnitsWithAttribute:checkFail()
        -- can not fail
    end
end

