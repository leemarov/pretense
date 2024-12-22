
BAI = Mission:new()
do
    function BAI.canCreate()
        return MissionTargetRegistry.baiTargetsAvailable(1)
    end

    function BAI:getMissionName()
        return 'BAI'
    end

    function BAI:createObjective()
        self.completionType = Mission.completion_type.all
        local description = ''
        local viableZones = {}
       
        local tgt = DependencyManager.get("GroupMonitor"):getGroup(self.target)
        
        if tgt then
            local gr = Group.getByName(tgt.name)
            if gr and gr:getSize()>0 then
                local units = {}
                for i,v in ipairs(gr:getUnits()) do
                    units[v:getName()] = false
                end

                local kill = ObjDestroyGroup:new() 
                kill:initialize(self, {
                    target = tgt,
                    targetUnitNames = units,
                    lastUpdate = timer.getAbsTime()
                })

                table.insert(self.objectives, kill)

                local nearzone = ""
                local un = gr:getUnit(1)
                local closest = ZoneCommand.getClosestZoneToPoint(un:getPoint())
                if closest then
                    nearzone = ' near '..closest.name..''
                end

                description = description..'   Destroy '..tgt.product.display..nearzone..' before it reaches its destination.'
            end

            MissionTargetRegistry.removeBaiTarget(tgt)
        end
        self.description = self.description..description
    end

    function BAI:generateObjectives()
        self.completionType = Mission.completion_type.all
        local description = ''
        local viableZones = {}
       
        local tgt = MissionTargetRegistry.getRandomBaiTarget(1)
        
        if tgt then

            local gr = Group.getByName(tgt.name)
            if gr and gr:getSize()>0 then
                local units = {}
                for i,v in ipairs(gr:getUnits()) do
                    units[v:getName()] = false
                end

                local kill = ObjDestroyGroup:new() 
                kill:initialize(self, {
                    target = tgt,
                    targetUnitNames = units,
                    lastUpdate = timer.getAbsTime()
                })

                table.insert(self.objectives, kill)

                local nearzone = ""
                local un = gr:getUnit(1)
                local closest = ZoneCommand.getClosestZoneToPoint(un:getPoint())
                if closest then
                    nearzone = ' near '..closest.name..''
                end

                description = description..'   Destroy '..tgt.product.display..nearzone..' before it reaches its destination.'
            end

            MissionTargetRegistry.removeBaiTarget(tgt)
        end
        self.description = self.description..description
    end
end

