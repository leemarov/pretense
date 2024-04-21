
ObjBombInsideZone = Objective:new(Objective.types.bomb_in_zone)
do
    ObjBombInsideZone.requiredParams = {
        ['targetZone'] = true,
        ['max'] = true,
        ['required'] = true,
        ['dropped'] = true,
        ['isFinishStarted'] = true,
        ['bonus'] = true
    }

    function ObjBombInsideZone:getText()
        local msg = 'Bomb runways at '..self.param.targetZone.name..'\n'

        local ratio = self.param.dropped/self.param.required
        local percent = string.format('%.1f',ratio*100)

        msg = msg..'\n  Runway bombed: '..percent..'%\n'

        msg = msg..'\n  Cluster bombs do not deal enough damage to complete this mission'

        return msg
    end

    function ObjBombInsideZone:update()
        if not self.isComplete and not self.isFailed then
            if self.param.targetZone.side ~= 1 then
                self.isFailed = true
                self.mission.failureReason = self.param.targetZone.name..' is no longer controlled by the enemy.'
            end

            if not self.param.isFinishStarted then
                if self.param.dropped >= self.param.required then
                    self.param.isFinishStarted = true
                    timer.scheduleFunction(function(o)
                        o.isComplete = true
                    end, self, timer.getTime()+5)
                end
            end
        end
    end

    function ObjBombInsideZone:checkFail()
        if not self.isComplete and not self.isFailed then
            if self.param.targetZone.side ~= 1 then
                self.isFailed = true
            end
        end
    end
end

