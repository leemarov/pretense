



ObjEscortGroup = Objective:new(Objective.types.escort)
do
    ObjEscortGroup.requiredParams = {
        ['maxAmount']=true,
        ['amount'] = true,
        ['proxDist']= true,
        ['target'] = true,
        ['lastUpdate']= true
    }

    function ObjEscortGroup:getText()
        local msg = 'Stay in close proximity of the convoy'

        local gr = Group.getByName(self.param.target.name)
        if gr and gr:getSize()>0 then
            local grunit = gr:getUnit(1)
            local lat,lon,alt = coord.LOtoLL(grunit:getPoint())
            local mgrs = coord.LLtoMGRS(coord.LOtoLL(grunit:getPoint()))
            msg = msg..'\n DDM:  '.. mist.tostringLL(lat,lon,3)
            msg = msg..'\n DMS:  '.. mist.tostringLL(lat,lon,2,true)
            msg = msg..'\n MGRS: '.. mist.tostringMGRS(mgrs, 5)
        end
        
        local prg = math.floor(((self.param.maxAmount - self.param.amount)/self.param.maxAmount)*100)
        msg = msg.. '\n Progress: '..prg..'%'
        return msg
    end

    function ObjEscortGroup:update()
        if not self.isComplete and not self.isFailed then
            local gr = Group.getByName(self.param.target.name)
            if not gr or gr:getSize()==0 then
                self.isFailed = true
                self.mission.failureReason = 'Group has been destroyed.'
                return true
            end
            local grunit = gr:getUnit(1)

            if self.param.target.state == 'atdestination' or self.param.target.state == 'siege' then
                for name, unit in pairs(self.mission.players) do
                    if unit and unit:isExist() then
                        local dist = mist.utils.get3DDist(unit:getPoint(), grunit:getPoint())
                        if dist < self.param.proxDist then
                            self.isComplete = true
                            break
                        end
                    end
                end

                if not self.isComplete then 
                    self.isFailed = true 
                    self.mission.failureReason = 'Group has reached its destination without an escort.'
                end
            end

            if not self.isComplete and not self.isFailed then
                local plycount = Utils.getTableSize(self.mission.players)
                if plycount == 0 then plycount = 1 end
                local updateFrequency = 5 -- seconds
                local shouldUpdateMsg = (timer.getAbsTime() - self.param.lastUpdate) > updateFrequency
                for name, unit in pairs(self.mission.players) do
                    if unit and unit:isExist() then
                        local dist = mist.utils.get3DDist(unit:getPoint(), grunit:getPoint())
                        if dist < self.param.proxDist then
                            self.param.amount = self.param.amount - (1/plycount)

                            if shouldUpdateMsg then
                                local prg = string.format('%.1f',((self.param.maxAmount - self.param.amount)/self.param.maxAmount)*100)
                                trigger.action.outTextForUnit(unit:getID(), 'Progress: '..prg..'%', updateFrequency)
                            end
                        else
                            if shouldUpdateMsg then
                                local m = 'Distance: '
                                if dist>1000 then
                                    local dstkm = string.format('%.2f',dist/1000)
                                    local dstnm = string.format('%.2f',dist/1852)

                                    m = m..dstkm..'km | '..dstnm..'nm'
                                else
                                    local dstft = math.floor(dist/0.3048)
                                    m = m..math.floor(dist)..'m | '..dstft..'ft'
                                end

                                m = m..'\nBearing: '..math.floor(Utils.getBearing(unit:getPoint(), grunit:getPoint()))
                                trigger.action.outTextForUnit(unit:getID(), m, updateFrequency)
                            end
                        end
                    end
                end

                if shouldUpdateMsg then
                    self.param.lastUpdate = timer.getAbsTime()
                end
            end

            if self.param.amount <= 0 then
                self.isComplete = true
                return true
            end
        end
    end

    function ObjEscortGroup:checkFail()
        if not self.isComplete and not self.isFailed then
            local tg = self.param.target
            local gr = Group.getByName(tg.name)
            if not gr or gr:getSize() == 0 then
                self.isFailed = true
            end

            if self.mission.state == Mission.states.new then
                if tg.state == 'enroute' and (timer.getAbsTime() - tg.lastStateTime) >= 7*60 then
                    self.isFailed = true
                end
            end
        end
    end
end

