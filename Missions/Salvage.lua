
Salvage = Mission:new()
do
    function Salvage.canCreate()
        local plcontext = DependencyManager.get("PlayerLogistics")
        for cname, cdata in pairs(plcontext.trackedBoxes) do
            local cobj = StaticObject.getByName(cname)
            if cdata.isSalvage and cdata.lifetime >=30*60 and cobj and cobj:isExist() and Utils.isLanded(cobj) then
                return true
            end
        end

        return false
    end

    function Salvage:getMissionName()
        return 'Salvage'
    end

    function Salvage:isInstantReward()
        return true
    end
    
    function Salvage:isUnitTypeAllowed(unit)
        if PlayerLogistics then
            local unitType = unit:getDesc()['typeName']
            return PlayerLogistics.allowedTypes[unitType] and PlayerLogistics.allowedTypes[unitType].sling
        end
    end

    function Salvage:createObjective()
        env.info("ERROR - Can't create Salvage on demand")
    end

    function Salvage:generateObjectives()
        self.completionType = Mission.completion_type.all
        local description = ''
        
        local plcontext = DependencyManager.get("PlayerLogistics")
        local viableBoxes = {}
        for cname, cdata in pairs(plcontext.trackedBoxes) do
            local cobj = StaticObject.getByName(cname) or Unit.getByName(cname)
            if cdata.isSalvage and cdata.lifetime >=30*60 and cobj and cobj:isExist() and Utils.isLanded(cobj) then
                table.insert(viableBoxes, {data = cdata, object = cobj})
            end
        end

        if #viableBoxes>0 then
            local tgt = viableBoxes[math.random(1,#viableBoxes)]
            if tgt then
                local recover = ObjRecoverCrate:new()
                recover:initialize(self, {
                    target = tgt,
                    unpackedAt = nil
                })
                table.insert(self.objectives, recover)

                local nearzone = ""
                local closest = ZoneCommand.getClosestZoneToPoint(tgt.object:getPoint())
                if closest then
                    nearzone = ' near '..closest.name
                end

                description = description..'   Recover abandoned crate'..nearzone..' to a friendly zone'
            end
        end
        self.description = self.description..description
    end
end

