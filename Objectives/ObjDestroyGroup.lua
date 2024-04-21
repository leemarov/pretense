
ObjDestroyGroup = Objective:new(Objective.types.destroy_group)
do
    ObjDestroyGroup.requiredParams = {
        ['target'] = true,
        ['targetUnitNames'] = true,
        ['lastUpdate'] = true
    }

    function ObjDestroyGroup:getText()
        local msg = 'Destroy '..self.param.target.product.display..' before it reaches its destination.\n'

        local gr = Group.getByName(self.param.target.name)
        if gr and gr:getSize()>0 then
            local killcount = 0
            for i,v in pairs(self.param.targetUnitNames) do
                if v == true then
                    killcount = killcount + 1
                end
            end

            msg = msg..'\n     '..gr:getSize()..' units remaining. (killed '..killcount..')\n'
            for name, unit in pairs(self.mission.players) do
                if unit and unit:isExist() then
                    local tgtUnit = gr:getUnit(1)
                    local dist = mist.utils.get2DDist(unit:getPoint(), tgtUnit:getPoint())
                    
                    local m = '\n     '..name..': Distance: '
                    m = m..string.format('%.2f',dist/1000)..'km'
                    m = m..' Bearing: '..math.floor(Utils.getBearing(unit:getPoint(), tgtUnit:getPoint()))
                    msg = msg..m
                end
            end
        end

        return msg
    end

    function ObjDestroyGroup:update()
        if not self.isComplete and not self.isFailed then
            local target = self.param.target
            local exists = false
            local gr = Group.getByName(target.name)

            if gr and gr:getSize() > 0 then
                local updateFrequency = 5 -- seconds
                local shouldUpdateMsg = (timer.getAbsTime() - self.param.lastUpdate) > updateFrequency

                if shouldUpdateMsg then
                    for _, unit in pairs(self.mission.players) do
                        if unit and unit:isExist() then
                            local tgtUnit = gr:getUnit(1)
                            local dist = mist.utils.get2DDist(unit:getPoint(), tgtUnit:getPoint())
                            local dstkm = string.format('%.2f',dist/1000)
                            local dstnm = string.format('%.2f',dist/1852)

                            local m = 'Distance: '
                            m = m..dstkm..'km | '..dstnm..'nm'

                            m = m..'\nBearing: '..math.floor(Utils.getBearing(unit:getPoint(), tgtUnit:getPoint()))
                            trigger.action.outTextForUnit(unit:getID(), m, updateFrequency)
                        end
                    end
                    
                    self.param.lastUpdate = timer.getAbsTime()
                end
            elseif target.state == 'enroute' then
                for i,v in pairs(self.param.targetUnitNames) do
                    if v == true then
                        self.isComplete = true
                        return true
                    end
                end

                self.isFailed = true
                self.mission.failureReason = 'Convoy was killed by someone else.'
                return true
            else
                self.isFailed = true
                self.mission.failureReason = 'Convoy has reached its destination.'
                return true
            end
        end
    end

    function ObjDestroyGroup:checkFail()
        if not self.isComplete and not self.isFailed then
            local target = self.param.target
            local gr = Group.getByName(target.name)

            if target.state ~= 'enroute' or not gr or gr:getSize() == 0 then
                self.isFailed = true
            end
        end
    end
end

