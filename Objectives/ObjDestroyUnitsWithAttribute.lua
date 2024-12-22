
ObjDestroyUnitsWithAttribute = Objective:new(Objective.types.destroy_attr)
do
    ObjDestroyUnitsWithAttribute.requiredParams = {
        ['attr'] = true,
        ['amount'] = true,
        ['killed'] = true,
        ['hits'] = true
    }

    function ObjDestroyUnitsWithAttribute:getText()
        local hits = self.param.hits or 0
        local progress = math.min(self.param.killed + math.floor(hits/2), self.param.amount)

        local msg = 'Destroy: '
        for _,v in ipairs(self.param.attr) do
            msg = msg..v..', '
        end
        msg = msg:sub(1,#msg-2)
        msg = msg..'\n Progress: '..progress..'/'..self.param.amount
        return msg
    end

    function ObjDestroyUnitsWithAttribute:update()
        if not self.isComplete and not self.isFailed then
            local hits = self.param.hits or 0
            local progress = math.min(self.param.killed + math.floor(hits/2), self.param.amount)
            if progress >= self.param.amount then
                self.isComplete = true
                return true
            end
        end
    end

    function ObjDestroyUnitsWithAttribute:checkFail()
        -- can not fail
    end
end

