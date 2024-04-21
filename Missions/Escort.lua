
Escort = Mission:new()
do    
    function Escort.canCreate()
        local currentTime = timer.getAbsTime()
        for _,gr in pairs(DependencyManager.get("GroupMonitor").groups) do
            if gr.product.side == 2 and gr.product.type == 'mission' and (gr.product.missionType == 'supply_convoy' or gr.product.missionType == 'assault')  then
                local z = gr.target
                if z.distToFront == 0 and z.side~= 2 then
                    if gr.state == nil or gr.state == 'started' or (gr.state == 'enroute' and (currentTime - gr.lastStateTime < 7*60)) then
                        return true
                    end
                end
            end
        end
    end

    function Escort:getMissionName()
        return "Escort convoy"
    end

    function Escort:isUnitTypeAllowed(unit)
        return unit:hasAttribute('Helicopters')
    end

    function Escort:generateObjectives()
        self.completionType = Mission.completion_type.all
        local description = ''

        local currentTime = timer.getAbsTime()
        local viableConvoys = {}
        for _,gr in pairs(DependencyManager.get("GroupMonitor").groups) do
            if gr.product.side == 2 and gr.product.type == 'mission' and (gr.product.missionType == 'supply_convoy' or gr.product.missionType == 'assault')  then
                local z = gr.target
                if z.distToFront == 0 and z.side ~= 2 then
                    if gr.state == nil or gr.state == 'started' or (gr.state == 'enroute' and (currentTime - gr.lastStateTime < 7*60)) then
                        table.insert(viableConvoys, gr)
                    end
                end
            end
        end
        
        if #viableConvoys > 0 then
            local choice = math.random(1,#viableConvoys)
            local convoy = viableConvoys[choice]
            
            local escort = ObjEscortGroup:new()
            escort:initialize(self, {
                maxAmount = 60*7,
                amount = 60*7,
                proxDist = 400,
                target = convoy,
                lastUpdate = timer.getAbsTime()
            })
            
            table.insert(self.objectives, escort)

            local nearzone = ""
            local gr = Group.getByName(convoy.name)
            if gr and gr:getSize()>0 then
                local un = gr:getUnit(1)
                local closest = ZoneCommand.getClosestZoneToPoint(un:getPoint())
                if closest then
                    nearzone = ' near '..closest.name..''
                end
            end

            description = description..'   Escort convoy'..nearzone..' on route to their destination'
            --description = description..'\n   Target will be assigned after accepting mission'

        end

        self.description = self.description..description
    end
end

