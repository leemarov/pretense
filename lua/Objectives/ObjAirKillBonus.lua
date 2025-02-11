



ObjAirKillBonus = Objective:new(Objective.types.air_kill_bonus)
do
    ObjAirKillBonus.requiredParams = {
        ['attr'] = true,
        ['bonus'] = true,
        ['count'] = true,
        ['linkedObjectives'] = true
    }

    function ObjAirKillBonus:getText()
        local msg = 'Destroy: '
        for _,v in ipairs(self.param.attr) do
            msg = msg..v..', '
        end
        msg = msg:sub(1,#msg-2)
        msg = msg..'\n Kills increase mission reward (Ends when other objectives are completed)'
        msg = msg..'\n   Kills: '..self.param.count
        return msg
    end

    function ObjAirKillBonus:update()
        if not self.isComplete and not self.isFailed then
            local allcomplete = true
            for _,obj in pairs(self.param.linkedObjectives) do
                if obj.isFailed then self.isFailed = true end
                if not obj.isComplete then allcomplete = false end
            end

            self.isComplete = allcomplete
        end
    end

    function ObjAirKillBonus:checkFail()
        if not self.isComplete and not self.isFailed then
            local allcomplete = true
            for _,obj in pairs(self.param.linkedObjectives) do
                if obj.isFailed then self.isFailed = true end
                if not obj.isComplete then allcomplete = false end
            end

            self.isComplete = allcomplete
        end
    end
end

