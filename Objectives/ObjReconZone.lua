
ObjReconZone = Objective:new(Objective.types.recon_zone)
do
    ObjReconZone.requiredParams = { 
        ['target'] = true,
        ['failZones'] = true
    }

    function ObjReconZone:getText()
        local msg = 'Conduct a recon mission on '..self.param.target.name..' and return with data to a friendly zone.'

        return msg
    end

    function ObjReconZone:update()
        if not self.isComplete and not self.isFailed then
            if self.param.failZones[1] then
                for _,zn in ipairs(self.param.failZones[1]) do
                    if zn.side ~= 1 then 
                        self.isFailed = true
                        self.mission.failureReason = zn.name..' is no longer controlled by the enemy.'
                        break
                    end
                end
            end

            if self.param.failZones[2] then
                for _,zn in ipairs(self.param.failZones[2]) do
                    if zn.side ~= 2 then 
                        self.isFailed = true
                        break
                    end
                end
            end

            if not self.isFailed then
                if self.param.reconData then
                    self.isComplete = true
                    return true
                end
            end
        end
    end

    function ObjReconZone:checkFail()
        if not self.isComplete and not self.isFailed then
            if self.param.failZones[1] then
                for _,zn in ipairs(self.param.failZones[1]) do
                    if zn.side ~= 1 then 
                        self.isFailed = true
                        break
                    end
                end
            end

            if self.param.failZones[2] then
                for _,zn in ipairs(self.param.failZones[2]) do
                    if zn.side ~= 2 then 
                        self.isFailed = true
                        break
                    end
                end
            end
        end
    end
end

