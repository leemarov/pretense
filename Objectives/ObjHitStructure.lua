
ObjHitStructure = Objective:new(Objective.types.hit_structure)
do
    ObjHitStructure.requiredParams = {
        ['target']=true,
        ['tgtzone']=true,
        ['hit']=true
    }

    function ObjHitStructure:getText()
        local msg = 'Hit '..self.param.target.display..' at '..self.param.tgtzone.name..'\n'
            
        local point = nil
        local st = StaticObject.getByName(self.param.target.name)
        if st then
            point = st:getPoint()
        else
            st = Group.getByName(self.param.target.name)
            if st and st:getSize()>0 then
                point = st:getUnit(1):getPoint()
            end
        end
        
        if point then
            local lat,lon,alt = coord.LOtoLL(point)
            local mgrs = coord.LLtoMGRS(coord.LOtoLL(point))
            msg = msg..'\n DDM:  '.. mist.tostringLL(lat,lon,3)
            msg = msg..'\n DMS:  '.. mist.tostringLL(lat,lon,2,true)
            msg = msg..'\n MGRS: '.. mist.tostringMGRS(mgrs, 5)
            msg = msg..'\n Altitude: '..math.floor(alt)..'m'..' | '..math.floor(alt*3.280839895)..'ft'
        end

        return msg
    end

    function ObjHitStructure:update()
        if not self.isComplete and not self.isFailed then
            if self.param.hit then
                self.isComplete = true
                return true
            end

            local target = self.param.target
            local exists = false
            local st = StaticObject.getByName(target.name)
            if st then
                exists = true
            else
                st = Group.getByName(target.name)
                if st and st:getSize()>0 then
                    exists = true
                end
            end

            if not exists then
                if not self.firstFailure then
                    self.firstFailure = timer.getAbsTime()
                end
            end

            if self.firstFailure and (timer.getAbsTime() - self.firstFailure > 1*60) then
                self.isFailed = true
                self.mission.failureReason = 'Structure was destoyed before it got hit.'
                return true
            end
        end
    end

    function ObjHitStructure:checkFail()
        if not self.isComplete and not self.isFailed then
            local target = self.param.target
            local exists = false
            local st = StaticObject.getByName(target.name)
            if st then
                exists = true
            else
                st = Group.getByName(target.name)
                if st and st:getSize()>0 then
                    exists = true
                end
            end

            if not exists then 
                self.isFailed = true
            end
        end
    end
end

