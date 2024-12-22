
AmbushSquad = SquadBase:new()

do 
    function AmbushSquad:new(data)
        local obj = SquadBase:new(data)
		setmetatable(obj, self)
		self.__index = self
		return obj
    end

    function AmbushSquad:processWorking()
        local gr = Group.getByName(self.name)
        if not gr then return true end
		if gr:getSize()==0 then 
			gr:destroy()
			return true
		end

        if self.remainingStateTime <=0 then
            env.info('SquadTracker - '..self.name..'('..self.data.type..') job complete, heading to extract')
            
            local cnt = gr:getController()
            cnt:setCommand({ 
                id = 'SetInvisible', 
                params = { 
                    value = false 
                } 
            })

            self:processExtract()
        else
            if not self.discovered then
                local frcnt = gr:getUnit(1):getController()
                local targets = frcnt:getDetectedTargets()
                local isTargetClose = false
                if #targets > 0 then
                    for _,tgt in ipairs(targets) do
                        if tgt.visible and tgt.object then
                            if tgt.object.isExist and tgt.object:isExist() and tgt.object.getCoalition and tgt.object:getCoalition()~=gr:getCoalition() and 
                            Object.getCategory(tgt.object) == 1 then
                                local dist = mist.utils.get3DDist(gr:getUnit(1):getPoint(), tgt.object:getPoint())
                                if dist < 100 then
                                    isTargetClose = true
                                    break
                                end
                            end
                        end
                    end
                end
                
                if isTargetClose then
                    self.discovered = true
                    local cnt = gr:getController()
                    cnt:setCommand({ 
                        id = 'SetInvisible',
                        params = { 
                            value = false 
                        }
                    })
                end
            elseif self.shouldDiscover then
                self.shouldDiscover = nil
                local cnt = gr:getController()
                cnt:setCommand({ 
                    id = 'SetInvisible',
                    params = { 
                        value = false 
                    }
                })
            end
        end
    end
end

