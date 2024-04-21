
ObjProtectMission = Objective:new(Objective.types.protect)
do
    ObjProtectMission.requiredParams = {
        ['mis'] = true
    }

    function ObjProtectMission:getText()
        local msg = 'Prevent enemy aircraft from interfering with '..self.param.mis:getMissionName()..' mission.'

        if self.param.mis.info and self.param.mis.info.targetzone then
            msg = msg..'\n Target zone: '..self.param.mis.info.targetzone.name
        end

        msg = msg..'\n Protect players: '
        for i,v in pairs(self.param.mis.players) do
            msg = msg..'\n  '..i
        end
        
        msg = msg..'\n Mission success depends on '..self.param.mis:getMissionName()..' mission success.'
        return msg
    end

    function ObjProtectMission:update()
        if not self.isComplete and not self.isFailed then
            if self.param.mis.state == Mission.states.failed then 
                self.isFailed = true
                self.mission.failureReason = "Failed to protect players of "..self.param.mis.name.." mission."
            end

            if self.param.mis.state == Mission.states.completed then 
                self.isComplete = true
            end
        end
    end

    function ObjProtectMission:checkFail()
        if not self.isComplete and not self.isFailed then
            if self.param.mis.state == Mission.states.failed then 
                self.isFailed = true
            end

            if self.param.mis.state == Mission.states.completed then 
                if self.mission.state == Mission.states.new or 
                    self.mission.state == Mission.states.preping or 
                    self.mission.state == Mission.states.comencing then
                        
                    self.isFailed = true
                end
            end
        end
    end
end

