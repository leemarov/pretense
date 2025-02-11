



ObjExtractSquad = Objective:new(Objective.types.extract_squad)
do
    ObjExtractSquad.requiredParams = {
        ['target']=true,
        ['loadedBy']=false,
        ['lastUpdate']= true
    }

    function ObjExtractSquad:getText()
        local infName = PlayerLogistics.getInfantryName(self.param.target.data.type)
        local msg = 'Extract '..infName..' '..self.param.target.name..'\n'
        
        if not self.param.loadedBy then
            local gr = Group.getByName(self.param.target.name)
            if gr and gr:getSize()>0 then
                local point = gr:getUnit(1):getPoint()

                local lat,lon,alt = coord.LOtoLL(point)
                local mgrs = coord.LLtoMGRS(coord.LOtoLL(point))
                msg = msg..'\n DDM:  '.. mist.tostringLL(lat,lon,3)
                msg = msg..'\n DMS:  '.. mist.tostringLL(lat,lon,2,true)
                msg = msg..'\n MGRS: '.. mist.tostringMGRS(mgrs, 5)
                msg = msg..'\n Altitude: '..math.floor(alt)..'m'..' | '..math.floor(alt*3.280839895)..'ft'
            end
        end

        return msg
    end

    function ObjExtractSquad:update()
        if not self.isComplete and not self.isFailed then

            if self.param.loadedBy then
                self.isComplete = true
                return true
            else
                local target = self.param.target
                
                local gr = Group.getByName(target.name)
                if not gr or gr:getSize()==0 then
                    self.isFailed = true
                    self.mission.failureReason = 'Squad was not rescued in time, and went MIA.'
                    return true
                end
            end

            local updateFrequency = 5 -- seconds
            local shouldUpdateMsg = (timer.getAbsTime() - self.param.lastUpdate) > updateFrequency
            if shouldUpdateMsg then
                for name, unit in pairs(self.mission.players) do
                    if unit and unit:isExist() then
                        local gr = Group.getByName(self.param.target.name)
                        local un = gr:getUnit(1)
                        local dist = mist.utils.get3DDist(unit:getPoint(), un:getPoint())
                        local m = 'Distance: '
                        if dist>1000 then
                            local dstkm = string.format('%.2f',dist/1000)
                            local dstnm = string.format('%.2f',dist/1852)

                            m = m..dstkm..'km | '..dstnm..'nm'
                        else
                            local dstft = math.floor(dist/0.3048)
                            m = m..math.floor(dist)..'m | '..dstft..'ft'
                        end

                        m = m..'\nBearing: '..math.floor(Utils.getBearing(unit:getPoint(), un:getPoint()))           
                        trigger.action.outTextForUnit(unit:getID(), m, updateFrequency)
                    end
                end

                self.param.lastUpdate = timer.getAbsTime()
            end
        end
    end

    function ObjExtractSquad:checkFail()
        if not self.isComplete and not self.isFailed then
            local target = self.param.target
                
            local gr = Group.getByName(target.name)
            if not gr or not gr:isExist() or gr:getSize()==0 then
                self.isFailed = true
                return true
            end
        end
    end
end

