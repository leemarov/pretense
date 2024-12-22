
ObjRecoverCrate = Objective:new(Objective.types.recover_crate)
do
    ObjRecoverCrate.requiredParams = {
        ['target']=true,
        ['unpackedAt']=false
    }

    function ObjRecoverCrate:getText()
        local msg = 'Recover '..self.param.target.data.name..'\n'
            
        if self.param.target.object:isExist() then
                
            local point = self.param.target.object:getPoint()

            local lat,lon,alt = coord.LOtoLL(point)
            local mgrs = coord.LLtoMGRS(coord.LOtoLL(point))
            msg = msg..'\n DDM:  '.. mist.tostringLL(lat,lon,3)
            msg = msg..'\n DMS:  '.. mist.tostringLL(lat,lon,2,true)
            msg = msg..'\n MGRS: '.. mist.tostringMGRS(mgrs, 5)
            msg = msg..'\n Altitude: '..math.floor(alt)..'m'..' | '..math.floor(alt*3.280839895)..'ft'
        end

        return msg
    end

    function ObjRecoverCrate:update()
        if not self.isComplete and not self.isFailed then
            if self.param.unpackedAt then
                self.isComplete = true
                return true
            end

            if not self.param.target.object:isExist() then
                self.isFailed = true
                self.mission.failureReason = 'Crate was not recovered in time.'
                return true
            end
        end
    end

    function ObjRecoverCrate:checkFail()
        if not self.isComplete and not self.isFailed then
            if not self.param.target.object:isExist() then
                self.isFailed = true
                return true
            end
        end
    end
end

