



ObjFlyToZoneSequence = Objective:new(Objective.types.fly_to_zone_seq)
do
    ObjFlyToZoneSequence.requiredParams = {
        ['waypoints'] = true,
        ['failZones'] = true
    }

    function ObjFlyToZoneSequence:getText()
        local msg = 'Fly route: '
            
        for i,v in ipairs(self.param.waypoints) do
            if v.complete then
                msg = msg..'\n [✓] '..i..'. '..v.zone.name
            else
                msg = msg..'\n --> '..i..'. '..v.zone.name
            end
        end
        return msg
    end

    function ObjFlyToZoneSequence:update()
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
                        self.mission.failureReason = zn.name..' was lost.'
                        break
                    end
                end
            end

            if not self.isFailed then
                local firstWP = nil
                local nextWP = nil
                for i,leg in ipairs(self.param.waypoints) do
                    if not leg.complete then
                        firstWP = leg
                        nextWP = self.param.waypoints[i+1]
                        break
                    end
                end

                if firstWP then
                    local point = firstWP.zone.zone.point
                    local range = 3000 --meters
                    local allInside = true
                    for p,u in pairs(self.mission.players) do
                        if u and u:isExist() then
                            if Utils.isLanded(u,true) then
                                allInside = false
                                break
                            end
                            
                            local pos = u:getPoint()
                            local dist = mist.utils.get2DDist(point, pos)
                            if dist > range then
                                allInside = false
                                break
                            end
                        end
                    end

                    if allInside then
                        firstWP.complete = true
                        self.mission:pushMessageToPlayers(firstWP.zone.name..' reached')
                        if nextWP then
                            self.mission:pushMessageToPlayers('Next point: '..nextWP.zone.name)
                        end
                    end
                else
                    self.isComplete = true
                    return true
                end
            end
        end
    end

    function ObjFlyToZoneSequence:checkFail()
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

