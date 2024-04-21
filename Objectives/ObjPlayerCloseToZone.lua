
ObjPlayerCloseToZone = Objective:new(Objective.types.player_close_to_zone)
do
    ObjPlayerCloseToZone.requiredParams = {
        ['target']=true,
        ['range'] = true,
        ['amount']= true,
        ['maxAmount'] = true,
        ['lastUpdate']= true
    }

    function ObjPlayerCloseToZone:getText()
        local msg = 'Patrol area around '..self.param.target.name

        local prg = math.floor(((self.param.maxAmount - self.param.amount)/self.param.maxAmount)*100)
        msg = msg.. '\n Progress: '..prg..'%'
        return msg
    end

    function ObjPlayerCloseToZone:update()
        if not self.isComplete and not self.isFailed then

            if self.param.target.side ~= 2 then
                self.isFailed = true
                self.mission.failureReason = self.param.target.name..' was lost.'
                return true
            end

            local plycount = Utils.getTableSize(self.mission.players)
            if plycount == 0 then plycount = 1 end
            local updateFrequency = 5 -- seconds
            local shouldUpdateMsg = (timer.getAbsTime() - self.param.lastUpdate) > updateFrequency
            for name, unit in pairs(self.mission.players) do
                if unit and unit:isExist() and Utils.isInAir(unit) then
                    local dist = mist.utils.get2DDist(unit:getPoint(), self.param.target.zone.point)
                    if dist < self.param.range then
                        self.param.amount = self.param.amount - (1/plycount)

                        if shouldUpdateMsg then
                            local prg = string.format('%.1f',((self.param.maxAmount - self.param.amount)/self.param.maxAmount)*100)
                            trigger.action.outTextForUnit(unit:getID(), '['..self.param.target.name..'] Progress: '..prg..'%', updateFrequency)
                        end
                    end
                end
            end

            if shouldUpdateMsg then
                self.param.lastUpdate = timer.getAbsTime()
            end

            if self.param.amount <= 0 then
                self.isComplete = true
                for name, unit in pairs(self.mission.players) do
                    if unit and unit:isExist() and Utils.isInAir(unit) then
                        trigger.action.outTextForUnit(unit:getID(), '['..self.param.target.name..'] Complete', updateFrequency)
                    end
                end
                return true
            end
        end
    end

    function ObjPlayerCloseToZone:checkFail()
        if not self.isComplete and not self.isFailed then
            if self.param.target.side ~= 2 then
                self.isFailed = true
            end
        end
    end
end

