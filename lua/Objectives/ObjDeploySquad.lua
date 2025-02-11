



ObjDeploySquad = Objective:new(Objective.types.deploy_squad)
do
    ObjDeploySquad.requiredParams = {
        ['squadType']=true,
        ['targetZone']=true,
        ['requiredZoneSide']=true,
        ['unloadedType']=false,
        ['unloadedAt']=false
    }

    function ObjDeploySquad:getText()
        local infName = PlayerLogistics.getInfantryName(self.param.squadType)
        local msg = 'Deploy '..infName..' at '..self.param.targetZone.name
        return msg
    end

    function ObjDeploySquad:update()
        if not self.isComplete and not self.isFailed then

            if self.param.unloadedType and self.param.unloadedAt then
                if self.param.targetZone.name == self.param.unloadedAt then
                    if self.param.squadType == self.param.unloadedType then
                        self.isComplete = true
                        return true
                    end
                end
            end

            if self.param.targetZone.side ~= self.param.requiredZoneSide then
                self.isFailed = true

                local side = ''
                if self.param.requiredZoneSide == 0 then side = 'neutral' 
                elseif self.param.requiredZoneSide == 1 then side = 'controlled by Red'
                elseif self.param.requiredZoneSide == 2 then side = 'controlled by Blue'
                end

                self.mission.failureReason = self.param.targetZone.name..' is no longer '..side
                return true
            end
        end
    end

    function ObjDeploySquad:checkFail()
        if not self.isComplete and not self.isFailed then
            if self.param.targetZone.side ~= self.param.requiredZoneSide then
                self.isFailed = true
                return true
            end
        end
    end
end

