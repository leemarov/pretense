
ObjSupplyZone = Objective:new(Objective.types.supply)
do
    ObjSupplyZone.requiredParams = {
        ['amount']=true,
        ['delivered']=true,
        ['tgtzone']=true
    }

    function ObjSupplyZone:getText()
        local msg = 'Deliver '..self.param.amount..' to '..self.param.tgtzone.name..': '
        msg = msg..'\n Progress: '..self.param.delivered..'/'..self.param.amount
        return msg
    end

    function ObjSupplyZone:update()
        if not self.isComplete and not self.isFailed then
            if self.param.delivered >= self.param.amount then
                self.isComplete = true
                return true
            end

            local zn = self.param.tgtzone
            if zn.side ~= 2 then 
                self.isFailed = true
                self.mission.failureReason = zn.name..' was lost.'
                return true
            end
        end
    end

    function ObjSupplyZone:checkFail()
        if not self.isComplete and not self.isFailed then
            local zn = self.param.tgtzone
            if zn.side ~= 2 then 
                self.isFailed = true
                return true
            end
        end
    end
end

