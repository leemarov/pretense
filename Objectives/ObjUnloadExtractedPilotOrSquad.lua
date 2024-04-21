
ObjUnloadExtractedPilotOrSquad = Objective:new(Objective.types.unloaded_pilot_or_squad)
do
    ObjUnloadExtractedPilotOrSquad.requiredParams = {
        ['targetZone']=false,
        ['extractObjective']=true,
        ['unloadedAt']=false
    }

    function ObjUnloadExtractedPilotOrSquad:getText()
        local msg = 'Drop off personnel '
        if self.param.targetZone then
            msg = msg..'at '..self.param.targetZone.name..'\n'
        else
            msg = msg..'at a friendly zone\n'
        end

        return msg
    end

    function ObjUnloadExtractedPilotOrSquad:update()
        if not self.isComplete and not self.isFailed then

            if self.param.extractObjective.isComplete and self.param.unloadedAt then
                if self.param.targetZone then
                    if self.param.unloadedAt == self.param.targetZone.name then
                        self.isComplete = true
                        return true
                    else
                        self.isFailed = true
                        self.mission.failureReason = 'Personnel dropped off at wrong zone.'
                        return true
                    end
                else
                    self.isComplete = true
                    return true
                end
            end

            if self.param.extractObjective.isFailed then
                self.isFailed = true
                return true
            end

            if self.param.targetZone and self.param.targetZone.side ~= 2 then
                self.isFailed = true
                self.mission.failureReason = self.param.targetZone.name..' was lost.'
                return true
            end
        end
    end

    function ObjUnloadExtractedPilotOrSquad:checkFail()
        if not self.isComplete and not self.isFailed then

            if self.param.extractObjective.isFailed then
                self.isFailed = true
                return true
            end

            if self.param.targetZone and self.param.targetZone.side ~= 2 then
                self.isFailed = true
                return true
            end
        end
    end
end

