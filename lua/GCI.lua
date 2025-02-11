



GCI = {}

do
    function GCI:new(side)
        local o = {}
        o.side = side
        o.tgtSide = 0
        if side == 1 then
            o.tgtSide = 2
        elseif side == 2 then
            o.tgtSide = 1
        end

        o.radars = {}
        o.players = {}
        o.radarTypes = {
            'SAM SR',
            'EWR',
            'AWACS'
        }

        o.groupMenus = {}

        setmetatable(o, self)
		self.__index = self

        o:start()

		DependencyManager.register("GCI", o)
		return o
    end

    local function getCenter(unitslist)
        local center = { x=0,y=0,z=0}
        local count = 0
        for _,u in pairs(unitslist) do
            if u and u:isExist() then
                local up = u:getPoint()
                center = {
                    x = center.x + up.x,
                    y = center.y + up.y,
                    z = center.z + up.z,
                }
                count = count + 1
            end
        end

        center.x = center.x / count
        center.y = center.y / count
        center.z = center.z / count

        return center
    end

    function GCI:registerPlayer(name, unit, warningRadius, metric)
        if warningRadius > 0 then
            local msg = "Warning radius set to "..warningRadius
            if metric then
                msg=msg.."km" 
            else
                msg=msg.."nm"
            end
            
            local wRadius = 0
            if metric then
                wRadius = warningRadius * 1000
            else
                wRadius = warningRadius * 1852
            end

            local callsign = DependencyManager.get("PlayerTracker"):getPlayerConfig(name).gci_callsign
            
            self.players[name] = {
                unit = unit, 
                warningRadius = wRadius,
                metric = metric,
                callsign = callsign,
                lastTransmit = timer.getAbsTime() - 60
            }
            
            trigger.action.outTextForUnit(unit:getID(), msg, 10)
            DependencyManager.get("PlayerTracker"):setPlayerConfig(name, "gci_warning_radius", warningRadius)
            DependencyManager.get("PlayerTracker"):setPlayerConfig(name, "gci_metric", metric)
        else
            self.players[name] = nil
            trigger.action.outTextForUnit(unit:getID(), "GCI Reports disabled", 10)
            DependencyManager.get("PlayerTracker"):setPlayerConfig(name, "gci_warning_radius", nil)
            DependencyManager.get("PlayerTracker"):setPlayerConfig(name, "gci_metric", nil)
        end
    end

    function GCI:setCallsign(name, unit, cname)
        local uid = unit:getID()
        
        local ptr = DependencyManager.get('PlayerTracker')
        local csign = ptr:generateCallsign(cname)
        ptr:setPlayerConfig(name, 'gci_callsign', csign)
        
        trigger.action.outTextForUnit(uid, "GCI callsign set to "..PlayerTracker.callsignToString(csign), 10)

        if not self.players[name] then return end
        self.players[name].callsign = csign
    end

    function GCI:start()
        MenuRegistry.register(4, function(event, context)
			if (event.id == world.event.S_EVENT_PLAYER_ENTER_UNIT or event.id == world.event.S_EVENT_BIRTH) and event.initiator and event.initiator.getPlayerName then
				local player = event.initiator:getPlayerName()
				if player then
					local groupid = event.initiator:getGroup():getID()
                    local groupname = event.initiator:getGroup():getName()
                    local unit = event.initiator
					
                    if context.groupMenus[groupid] then
                        missionCommands.removeItemForGroup(groupid, context.groupMenus[groupid])
                        context.groupMenus[groupid] = nil
                    end

                    if not context.groupMenus[groupid] then
                        
                        local menu = missionCommands.addSubMenuForGroup(groupid, 'GCI')
                        local setWR = missionCommands.addSubMenuForGroup(groupid, 'Set Warning Radius', menu)
                        local kmMenu = missionCommands.addSubMenuForGroup(groupid, 'KM', setWR)
                        local nmMenu = missionCommands.addSubMenuForGroup(groupid, 'NM', setWR)

                        missionCommands.addCommandForGroup(groupid, '10 KM',  kmMenu, Utils.log(context.registerPlayer), context, player, unit, 10, true)
                        missionCommands.addCommandForGroup(groupid, '25 KM',  kmMenu, Utils.log(context.registerPlayer), context, player, unit, 25, true)
                        missionCommands.addCommandForGroup(groupid, '50 KM',  kmMenu, Utils.log(context.registerPlayer), context, player, unit, 50, true)
                        missionCommands.addCommandForGroup(groupid, '100 KM', kmMenu, Utils.log(context.registerPlayer), context, player, unit, 100, true)
                        missionCommands.addCommandForGroup(groupid, '150 KM', kmMenu, Utils.log(context.registerPlayer), context, player, unit, 150, true)

                        missionCommands.addCommandForGroup(groupid, '5 NM',  nmMenu, Utils.log(context.registerPlayer), context, player, unit, 5, false)
                        missionCommands.addCommandForGroup(groupid, '10 NM', nmMenu, Utils.log(context.registerPlayer), context, player, unit, 10, false)
                        missionCommands.addCommandForGroup(groupid, '25 NM', nmMenu, Utils.log(context.registerPlayer), context, player, unit, 25, false)
                        missionCommands.addCommandForGroup(groupid, '50 NM', nmMenu, Utils.log(context.registerPlayer), context, player, unit, 50, false)
                        missionCommands.addCommandForGroup(groupid, '80 NM', nmMenu, Utils.log(context.registerPlayer), context, player, unit, 80, false)
                        missionCommands.addCommandForGroup(groupid, 'Disable Warning Radius', menu, Utils.log(context.registerPlayer), context, player, unit, 0, false)

                        
                        local gcicsignmenu = missionCommands.addSubMenuForGroup(groupid, 'Callsign', menu)

                        local sub1 = gcicsignmenu
                        local count = 0
                        for i,v in ipairs(PlayerTracker.callsigns) do
                            count = count + 1
                            if count%9==1 and count>1 then
                                sub1 = missionCommands.addSubMenuForGroup(groupid, "More", sub1)
                                missionCommands.addCommandForGroup(groupid, v, sub1, Utils.log(context.setCallsign), context, player, unit, v)
                            else
                                missionCommands.addCommandForGroup(groupid, v, sub1, Utils.log(context.setCallsign), context, player, unit, v)
                            end
                        end

                        context.groupMenus[groupid] = menu
                    end
				end

            end
		end, self)

        timer.scheduleFunction(function(param, time)
            local self = param.context
            local allunits = coalition.getGroups(self.side)
  
            local radars = {}
            for _,g in ipairs(allunits) do
                for _,u in ipairs(g:getUnits()) do
                    for _,a in ipairs(self.radarTypes) do
                        if u:hasAttribute(a) then
                            table.insert(radars, u)
                            break
                        end
                    end
                end
            end

            self.radars = radars
            env.info("GCI - tracking "..#radars.." radar enabled units")

            return time+10
        end, {context = self}, timer.getTime()+1)

        timer.scheduleFunction(function(param, time)
            local self = param.context

            local plyCount = 0
            for i,v in pairs(self.players) do
                if not v.unit or not v.unit:isExist() then
                    self.players[i] = nil
                else
                    plyCount = plyCount + 1
                end
            end

            env.info("GCI - reporting to "..plyCount.." players")
            if plyCount >0 then
                local dect = {}
                local dcount = 0
                for _,u in ipairs(self.radars) do
                    if u:isExist() then
                        local detected = u:getController():getDetectedTargets(Controller.Detection.RADAR)
                        for _,d in ipairs(detected) do
                            if d and d.object and d.object.isExist and d.object:isExist() and 
                                Object.getCategory(d.object) == Object.Category.UNIT and
                                d.object.getCoalition and
                                d.object:getCoalition() == self.tgtSide then
                                    
                                if not dect[d.object:getName()] then
                                    dect[d.object:getName()] = d.object
                                    dcount = dcount + 1
                                end
                            end
                        end
                    end
                end
                
                env.info("GCI - aware of "..dcount.." enemy units")

                local minsep = 1500
                local minaltsep = 500
                local dectgroups = {}
                local assignedUnits = {}
                for nm,dt in pairs(dect) do
                    for gnm, gdt in pairs(dectgroups) do
                        if gdt.leader and gdt.leader:isExist() and dt and dt:isExist() then
                            if gdt.leader:getDesc().typeName == dt:getDesc().typeName then
                                local dist = mist.utils.get2DDist(gdt.center, dt:getPoint())
                                if dist < minsep and math.abs(gdt.center.y-dt:getPoint().y)<minaltsep then
                                    gdt.units[nm] = dt
                                    gdt.center = getCenter(gdt.units)
                                    assignedUnits[nm] = true
                                    break
                                end
                            end
                        end
                    end

                    if not assignedUnits[nm] then
                        dectgroups[nm] = { leader = dt, units={}, center = {}}
                        dectgroups[nm].units[nm] = dt
                        dectgroups[nm].center = getCenter(dectgroups[nm].units)
                        assignedUnits[nm] = true
                    end
                end

                for name, data in pairs(self.players) do
                    if data.unit and data.unit:isExist() then
                        local closeUnits = {}

                        local wr = data.warningRadius
                        if wr > 0 then
                            for _,dtg in pairs(dectgroups) do
                                local dt = dtg.leader
                                if dt:isExist() then
                                    local tgtPnt = dtg.center
                                    local dist = mist.utils.get2DDist(data.unit:getPoint(), tgtPnt)
                                    if dist <= wr then
                                        local brg = math.floor(Utils.getBearing(data.unit:getPoint(), tgtPnt))

                                        local myPos = data.unit:getPosition()
                                        local tgtPos = dt:getPosition()
                                        local tgtHeading = math.deg(math.atan2(tgtPos.x.z, tgtPos.x.x))
                                        local tgtBearing = Utils.getBearing(tgtPos.p, myPos.p)
            
                                        local diff = math.abs(Utils.getHeadingDiff(tgtBearing, tgtHeading))
                                        local aspect = ''
                                        local priority = 1
                                        if diff <= 30 then
                                            aspect = "Hot"
                                            priority = 1
                                        elseif diff <= 60 then
                                            aspect = "Flanking"
                                            priority = 1
                                        elseif diff <= 120 then
                                            aspect = "Beaming"
                                            priority = 2
                                        else
                                            aspect = "Cold"
                                            priority = 3
                                        end

                                        local type = "UNKN"
                                        if dt:hasAttribute("Helicopters") then
                                            type = "HELO"
                                        elseif dt:hasAttribute("Planes") then
                                            type = "FXWG"
                                        end

                                        table.insert(closeUnits, {
                                            type = type, --dt:getDesc().typeName,
                                            bearing = brg,
                                            range = dist,
                                            altitude = tgtPnt.y,
                                            score = dist*priority,
                                            aspect = aspect,
                                            size = Utils.getTableSize(dtg.units)
                                        })
                                    end
                                end
                            end
                        end

                        env.info("GCI - "..#closeUnits.." enemy units within "..wr.."m of "..name)
                        if #closeUnits > 0 then
                            table.sort(closeUnits, function(a, b) return a.range < b.range end)
                            local strcallsign = DependencyManager.get("PlayerTracker").callsignToString(data.callsign)
                            local msg = "GCI Report for ["..strcallsign.."]:\n"
                            local count = 0
                            local callouts = {}
                            for _,tgt in ipairs(closeUnits) do
                                if data.metric then
                                    local km = tgt.range/1000
                                    if km < 1 then
                                        msg = msg..'\n'..tgt.type..'  MERGED'
                                    else
                                        msg = msg..'\n'..tgt.type
                                        msg = msg..'  BRA: '..tgt.bearing..' for '
                                        msg = msg..Utils.round(km)..'km at '
                                        msg = msg..(Utils.round(tgt.altitude/250)*250)..'m, '
                                        msg = msg..tostring(tgt.aspect)
                                        if tgt.size > 1 then msg = msg..',    GROUP of '..tgt.size end
                                    end
                                else
                                    local nm = tgt.range/1852
                                    if nm < 1 then
                                        msg = msg..'\n'..tgt.type..'  MERGED'
                                    else
                                        msg = msg..'\n'..tgt.type
                                        msg = msg..'  BRA: '..tgt.bearing..' for '
                                        msg = msg..Utils.round(nm)..'nm at '
                                        msg = msg..(Utils.round((tgt.altitude/0.3048)/1000)*1000)..'ft, '
                                        msg = msg..tostring(tgt.aspect)
                                        if tgt.size > 1 then msg = msg..',    GROUP of '..tgt.size end
                                    end
                                end
                                
                                if tgt.aspect == "Hot" and data.lastTransmit < (timer.getAbsTime()-Config.gciRadioTimeout) and #callouts <= Config.gciMaxCallouts then
                                    local miles = Utils.round(tgt.range/1852)
                                    local angels = Utils.round((tgt.altitude/0.3048)/1000)
                                    table.insert(callouts, {
                                        type = tgt.type,
                                        size = tgt.size,
                                        bearing = tgt.bearing,
                                        miles = miles,
                                        angels = angels
                                    })
                                end

                                count = count + 1
                                if count >= 10 then break end
                            end

                            if #callouts > 0 then
                                local sourcePos = data.unit:getPoint()

                                for i,call in ipairs(callouts) do
                                    if i==1 then
                                        TransmissionManager.gciCallout(TransmissionManager.radios.gci, data.callsign, call.type, call.size, call.bearing, call.miles, call.angels, sourcePos)
                                    else
                                        TransmissionManager.gciCallout(TransmissionManager.radios.gci, nil, call.type, call.size, call.bearing, call.miles, call.angels, sourcePos)
                                    end 
                                end

                                data.lastTransmit = timer.getAbsTime()
                            end
                            
                            if DependencyManager.get("PlayerTracker"):getPlayerConfig(name).gciTextReports then
                                trigger.action.outTextForUnit(data.unit:getID(), msg, 19)
                            end
                        end
                    else
                        self.players[name] = nil
                    end
                end
            end

            return time+20
        end, {context = self}, timer.getTime()+6)
    end
end

