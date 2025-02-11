



TransmissionManager = {}

do
    TransmissionManager.baseStation = {x = -355923, z=618060, y = 10000 }

    TransmissionManager.radios = {
        command = { 
            queue={}, freqs = 
            {
                { frequency = 262.5E6, modulation = 0, power=500 },
                { frequency = 122.5E6, modulation = 0, power=500 },
                { frequency = 032E6, modulation = 1, power=500 }, -- needs squelch off for some reason
            }
        },
        infantry = { 
            queue={}, 
            freqs = {
                { frequency = 263.5E6, modulation = 0, power=10 },
                { frequency = 123.5E6, modulation = 0, power=10 },
                { frequency = 033E6, modulation = 1, power=10 }, -- needs squelch off for some reason
            }
        },
        gci = { 
            queue={},
            freqs = {
                { frequency = 264.5E6, modulation = 0, power=500 },
                { frequency = 124.5E6, modulation = 0, power=500 },
                { frequency = 034E6, modulation = 1, power=500 }, -- needs squelch off for some reason
            }
        },
        guard = {
            queue={},
            freqs = {
                { frequency = 243.0E6, modulation = 0, power=500 },
                { frequency = 121.5E6, modulation = 0, power=500 },
            }
        }
    }

    function TransmissionManager.queueTransmission(key, radio, pos, group)
        if not Config.useRadio then return end

        local instant = #radio.queue == 0
        if instant then table.insert(radio.queue, {key='generic.noise', pos=pos, group=group}) end

        table.insert(radio.queue, {key=key, pos=pos, group=group})

        if instant then
            TransmissionManager.playNext(radio)
        end
    end

    function TransmissionManager.queueMultiple(keys, radio, pos, group)
        for _,key in ipairs(keys) do
            TransmissionManager.queueTransmission(key, radio, pos, group)
        end
    end

    function TransmissionManager.resolveKey(key)
        local trsnd = TransmissionManager.sounds[key]
        if not trsnd then return { url = '', length=0.5 } end

        local url = trsnd.url
        local length = trsnd.length

        return { url='Sounds/'..url, length=length }
    end

    function TransmissionManager.playNext(radio)
        if #radio.queue > 0 then
            local trm = radio.queue[1]

            local sound = TransmissionManager.resolveKey(trm.key)

            local pos = TransmissionManager.baseStation
            if trm.pos then
                pos = trm.pos
            elseif trm.group then
                local gr = Group.getByName(trm.group)
                if gr and gr:isExist() and gr:getSize()>0 then 
                    pos = gr:getUnit(1):getPoint()
                end
            end

            pos.y = pos.y + 10

            for _,fr in ipairs(radio.freqs) do
                env.info("TransmissionManager - "..sound.url..' '..tostring(fr.frequency)..' '..tostring(fr.modulation))
                trigger.action.radioTransmission(sound.url, pos, fr.modulation, false, fr.frequency, fr.power)
            end

            timer.scheduleFunction(function(param,time)
                table.remove(param.queue, 1)
                TransmissionManager.playNext(param)
            end, radio, timer.getTime()+sound.length)
        end
    end

    function TransmissionManager.pilotCallout(radio, pos)
        local variant = math.random(1,5)
        local callout = math.random(1,5)

        local key = 'pilots.extracting.'..variant..'.call.'..callout

        TransmissionManager.queueTransmission(key, radio, pos)

        if math.random() < 0.05 then
            TransmissionManager.queueTransmission('pilots.extracting.'..variant..'.call.quip.1', radio, pos)
        end
    end

    function TransmissionManager.gciCallout(radio, callsign, targetType, size, heading, miles, angels, sourcePos)
        local calls = ''
        if callsign then
            calls = {
                'gci.callsigns.'..callsign.name,
                'gci.numbers.'..callsign.num1,
                'gci.numbers.'..callsign.num2,
            }
        else
            calls = {
                'generic.noise'
            }
        end

        if targetType == "HELO" then
            table.insert(calls, 'gci.callout.helo')
        elseif targetType == "FXWG" then
            table.insert(calls, 'gci.callout.fixedwing')
        end

        if size > 1 then
            table.insert(calls, 'gci.callout.groupof')
            table.insert(calls, 'gci.numbers.'..size)
        end

        table.insert(calls, 'gci.callout.bra')

        local hstr = tostring(heading)
        for i=1,#hstr do
            local n = hstr:sub(i,i)
            table.insert(calls, 'gci.numbers.'..n)
        end

        table.insert(calls, 'gci.callout.for')

        local mstr = tostring(miles)
        for i=1,#mstr do
            local n = mstr:sub(i,i)
            table.insert(calls, 'gci.numbers.'..n)
        end
        
        table.insert(calls, 'gci.callout.miles')
        table.insert(calls, 'gci.callout.atangels')

        local astr = tostring(angels)
        for i=1,#astr do
            local n = astr:sub(i,i)
            table.insert(calls, 'gci.numbers.'..n)
        end

        TransmissionManager.queueMultiple(calls, radio, sourcePos)
    end

    TransmissionManager.sounds = {
        ['generic.noise'] = { url='generic.noise.ogg',  length=0.70 },

        -- nato phonetic
        ['zones.names.Alpha'] =     { url='zones.names.nato/zones.names.Alpha.ogg',      length=0.54},
        ['zones.names.Bravo'] =     { url='zones.names.nato/zones.names.Bravo.ogg',      length=0.54},
        ['zones.names.Charlie'] =   { url='zones.names.nato/zones.names.Charlie.ogg',    length=0.49},
        ['zones.names.Delta'] =     { url='zones.names.nato/zones.names.Delta.ogg',      length=0.49},
        ['zones.names.Echo'] =      { url='zones.names.nato/zones.names.Echo.ogg',       length=0.49},
        ['zones.names.Foxtrot'] =   { url='zones.names.nato/zones.names.Foxtrot.ogg',    length=0.60},
        ['zones.names.Golf'] =      { url='zones.names.nato/zones.names.Golf.ogg',       length=0.56},
        ['zones.names.Hotel'] =     { url='zones.names.nato/zones.names.Hotel.ogg',      length=0.63},
        ['zones.names.India'] =     { url='zones.names.nato/zones.names.India.ogg',      length=0.52},
        ['zones.names.Juliett'] =   { url='zones.names.nato/zones.names.Juliet.ogg',     length=0.61},
        ['zones.names.Kilo'] =      { url='zones.names.nato/zones.names.Kilo.ogg',       length=0.48},
        ['zones.names.Lima'] =      { url='zones.names.nato/zones.names.Lima.ogg',       length=0.46},
        ['zones.names.Mike'] =      { url='zones.names.nato/zones.names.Mike.ogg',       length=0.40},
        ['zones.names.November'] =  { url='zones.names.nato/zones.names.November.ogg',   length=0.60},
        ['zones.names.Oscar'] =     { url='zones.names.nato/zones.names.Oscar.ogg',      length=0.50},
        ['zones.names.Papa'] =      { url='zones.names.nato/zones.names.Papa.ogg',       length=0.46},
        ['zones.names.Quebec'] =    { url='zones.names.nato/zones.names.Quebec.ogg',     length=0.59},
        ['zones.names.Romeo'] =     { url='zones.names.nato/zones.names.Romeo.ogg',      length=0.57},
        ['zones.names.Sierra'] =    { url='zones.names.nato/zones.names.Sierra.ogg',     length=0.57},
        ['zones.names.Tango'] =     { url='zones.names.nato/zones.names.Tango.ogg',      length=0.54},
        ['zones.names.Uniform'] =   { url='zones.names.nato/zones.names.Uniform.ogg',    length=0.70},
        ['zones.names.Victor'] =    { url='zones.names.nato/zones.names.Victor.ogg',     length=0.46},
        ['zones.names.Whiskey'] =   { url='zones.names.nato/zones.names.Whiskey.ogg',    length=0.50},
        ['zones.names.XRay'] =      { url='zones.names.nato/zones.names.XRay.ogg',       length=0.60},
        ['zones.names.Yankee'] =    { url='zones.names.nato/zones.names.Yankee.ogg',     length=0.51},
        ['zones.names.Zulu'] =      { url='zones.names.nato/zones.names.Zulu.ogg',       length=0.47},

        -- locations
        ['zones.names.Babugent'] =      { url='zones.names.caucasus/zones.names.Babugent.ogg',   length=0.51},
        ['zones.names.Batumi'] =        { url='zones.names.caucasus/zones.names.Batumi.ogg',     length=0.64},
        ['zones.names.Beslan'] =        { url='zones.names.caucasus/zones.names.Beslan.ogg',     length=0.58},
        ['zones.names.Cherkessk'] =     { url='zones.names.caucasus/zones.names.Cherkessk.ogg',  length=0.71},
        ['zones.names.Digora'] =        { url='zones.names.caucasus/zones.names.Digora.ogg',     length=0.59},
        ['zones.names.Gudauta'] =       { url='zones.names.caucasus/zones.names.Gudauta.ogg',    length=0.51},
        ['zones.names.Humara'] =        { url='zones.names.caucasus/zones.names.Humara.ogg',     length=0.54},
        ['zones.names.Kislovodsk'] =    { url='zones.names.caucasus/zones.names.Kislovodsk.ogg', length=0.84},
        ['zones.names.Kobuleti'] =      { url='zones.names.caucasus/zones.names.Kobuleti.ogg',   length=0.67},
        ['zones.names.Kutaisi'] =       { url='zones.names.caucasus/zones.names.Kutaisi.ogg',    length=0.75},
        ['zones.names.Lentehi'] =       { url='zones.names.caucasus/zones.names.Lentehi.ogg',    length=0.64},
        ['zones.names.Malgobek'] =      { url='zones.names.caucasus/zones.names.Malgobek.ogg',   length=0.73},
        ['zones.names.Mineralnye'] =    { url='zones.names.caucasus/zones.names.Mineralnye.ogg', length=0.76},
        ['zones.names.Mozdok'] =        { url='zones.names.caucasus/zones.names.Mozdok.ogg',     length=0.65},
        ['zones.names.Nalchik'] =       { url='zones.names.caucasus/zones.names.Nalchik.ogg',    length=0.57},
        ['zones.names.Ochamchira'] =    { url='zones.names.caucasus/zones.names.Ochamchira.ogg', length=0.82},
        ['zones.names.Oni'] =           { url='zones.names.caucasus/zones.names.Oni.ogg',        length=0.39},
        ['zones.names.Prohladniy'] =    { url='zones.names.caucasus/zones.names.Prohladniy.ogg', length=0.66},
        ['zones.names.Senaki'] =        { url='zones.names.caucasus/zones.names.Senaki.ogg',     length=0.62},
        ['zones.names.Sochi'] =         { url='zones.names.caucasus/zones.names.Sochi.ogg',      length=0.55},
        ['zones.names.Sukhumi'] =       { url='zones.names.caucasus/zones.names.Sukhumi.ogg',    length=0.56},
        ['zones.names.Tallyk'] =        { url='zones.names.caucasus/zones.names.Tallyk.ogg',     length=0.51},
        ['zones.names.Terek'] =         { url='zones.names.caucasus/zones.names.Terek.ogg',      length=0.55},
        ['zones.names.Tyrnyauz'] =      { url='zones.names.caucasus/zones.names.Tyrnyauz.ogg',   length=0.75},
        ['zones.names.Unal'] =          { url='zones.names.caucasus/zones.names.Unal.ogg',       length=0.54},
        ['zones.names.Zugdidi'] =       { url='zones.names.caucasus/zones.names.Zugdidi.ogg',    length=0.63},

        ['zones.names.Acre'] =          { url='zones.names.syria/zones.names.Acre.ogg',           length=0.40},
        ['zones.names.Al Assad'] =      { url='zones.names.syria/zones.names.AlAssad.ogg',        length=0.75},
        ['zones.names.Al Dumayr'] =     { url='zones.names.syria/zones.names.AlDumayr.ogg',       length=0.82},
        ['zones.names.Al Qusayr'] =     { url='zones.names.syria/zones.names.AlQusayr.ogg',       length=0.79},
        ['zones.names.Al Qutayfah'] =   { url='zones.names.syria/zones.names.AlQutayfah.ogg',     length=0.85},
        ['zones.names.An Nasiriyah'] =  { url='zones.names.syria/zones.names.AnNasiriyah.ogg',    length=0.94},
        ['zones.names.Ar Rastan'] =     { url='zones.names.syria/zones.names.ArRastan.ogg',       length=0.86},
        ['zones.names.Baniyas'] =       { url='zones.names.syria/zones.names.Baniyas.ogg',        length=0.70},
        ['zones.names.Beirut'] =        { url='zones.names.syria/zones.names.Beirut.ogg',         length=0.58},
        ['zones.names.Beit Shean'] =    { url='zones.names.syria/zones.names.BeitShean.ogg',      length=0.80},
        ['zones.names.Busra'] =         { url='zones.names.syria/zones.names.Busra.ogg',          length=0.53},
        ['zones.names.Damascus'] =      { url='zones.names.syria/zones.names.Damascus.ogg',       length=0.79},
        ['zones.names.Duma'] =          { url='zones.names.syria/zones.names.Duma.ogg',           length=0.42},
        ['zones.names.Elkorum'] =       { url='zones.names.syria/zones.names.Elkorum.ogg',        length=0.73},
        ['zones.names.El Taebah'] =     { url='zones.names.syria/zones.names.ElTaebah.ogg',       length=0.73},
        ['zones.names.Et Turra'] =      { url='zones.names.syria/zones.names.EtTurra.ogg',        length=0.62},
        ['zones.names.Ghabagheb'] =     { url='zones.names.syria/zones.names.Ghabagheb.ogg',      length=0.71},
        ['zones.names.Hama'] =          { url='zones.names.syria/zones.names.Hama.ogg',           length=0.42},
        ['zones.names.Hawash'] =        { url='zones.names.syria/zones.names.Hawash.ogg',         length=0.70},
        ['zones.names.Homs'] =          { url='zones.names.syria/zones.names.Homs.ogg',           length=0.56},
        ['zones.names.Hussein'] =       { url='zones.names.syria/zones.names.Hussein.ogg',        length=0.65},
        ['zones.names.Irbid'] =         { url='zones.names.syria/zones.names.Irbid.ogg',          length=0.44},
        ['zones.names.Jabah'] =         { url='zones.names.syria/zones.names.Jabah.ogg',          length=0.48},
        ['zones.names.Jasim'] =         { url='zones.names.syria/zones.names.Jasim.ogg',          length=0.65},
        ['zones.names.Khalkhalah'] =    { url='zones.names.syria/zones.names.Khalkhalah.ogg',     length=0.63},
        ['zones.names.Khan Alsheh'] =   { url='zones.names.syria/zones.names.KhanAlsheh.ogg',     length=0.86},
        ['zones.names.Khirbet'] =       { url='zones.names.syria/zones.names.Khirbet.ogg',        length=0.62},
        ['zones.names.Kiryat'] =        { url='zones.names.syria/zones.names.Kiryat.ogg',         length=0.50},
        ['zones.names.Madaya'] =        { url='zones.names.syria/zones.names.Madaya.ogg',         length=0.61},
        ['zones.names.Marj'] =          { url='zones.names.syria/zones.names.Marj.ogg',           length=0.55},
        ['zones.names.Mezzeh'] =        { url='zones.names.syria/zones.names.Mezzeh.ogg',         length=0.48},
        ['zones.names.Muhradah'] =      { url='zones.names.syria/zones.names.Muhradah.ogg',       length=0.66},
        ['zones.names.Naqoura'] =       { url='zones.names.syria/zones.names.Naqoura.ogg',        length=0.61},
        ['zones.names.Nebatieh'] =      { url='zones.names.syria/zones.names.Nebatieh.ogg',       length=0.66},
        ['zones.names.Palmyra'] =       { url='zones.names.syria/zones.names.Palmyra.ogg',        length=0.66},
        ['zones.names.Qaraoun'] =       { url='zones.names.syria/zones.names.Qaraoun.ogg',        length=0.65},
        ['zones.names.Ramat David'] =   { url='zones.names.syria/zones.names.RamatDavid.ogg',     length=0.86},
        ['zones.names.Rayak'] =         { url='zones.names.syria/zones.names.Rayak.ogg',          length=0.58},
        ['zones.names.Rene'] =          { url='zones.names.syria/zones.names.Rene.ogg',           length=0.44},
        ['zones.names.Rosh Pina'] =     { url='zones.names.syria/zones.names.RoshPina.ogg',       length=0.73},
        ['zones.names.Saida'] =         { url='zones.names.syria/zones.names.Saida.ogg',          length=0.58},
        ['zones.names.Sayqal'] =        { url='zones.names.syria/zones.names.Sayqal.ogg',         length=0.64},
        ['zones.names.Shayrat'] =       { url='zones.names.syria/zones.names.Shayrat.ogg',        length=0.58},
        ['zones.names.Tartus'] =        { url='zones.names.syria/zones.names.Tartus.ogg',         length=0.57},
        ['zones.names.Thalah'] =        { url='zones.names.syria/zones.names.Thalah.ogg',         length=0.44},
        ['zones.names.Tiberias'] =      { url='zones.names.syria/zones.names.Tiberias.ogg',       length=0.91},
        ['zones.names.Tiyas'] =         { url='zones.names.syria/zones.names.Tiyas.ogg',          length=0.57},
        ['zones.names.Tripoli'] =       { url='zones.names.syria/zones.names.Tripoli.ogg',        length=0.58},
        ['zones.names.Tyre'] =          { url='zones.names.syria/zones.names.Tyre.ogg',           length=0.47},
        ['zones.names.Wujah'] =         { url='zones.names.syria/zones.names.Wujah.ogg',          length=0.47},
        
        -- generic zones
        ['zones.names.Distillery'] =    { url='zones.names.misc/zones.names.Distillery.ogg',     length=0.66},
        ['zones.names.Factory'] =       { url='zones.names.misc/zones.names.Factory.ogg',        length=0.59},
        ['zones.names.Farm'] =          { url='zones.names.misc/zones.names.Farm.ogg',           length=0.50},
        ['zones.names.Intel Center'] =  { url='zones.names.misc/zones.names.IntelCenter.ogg',    length=0.86},
        ['zones.names.Mine'] =          { url='zones.names.misc/zones.names.Mine.ogg',           length=0.42},
        ['zones.names.Oil Fields'] =    { url='zones.names.misc/zones.names.OilFields.ogg',      length=0.70},
        ['zones.names.Power Plant'] =   { url='zones.names.misc/zones.names.PowerPlant.ogg',     length=0.69},
        ['zones.names.Racetrack'] =     { url='zones.names.misc/zones.names.Racetrack.ogg',      length=0.55},
        ['zones.names.Refinery'] =      { url='zones.names.misc/zones.names.Refinery.ogg',       length=0.66},
        ['zones.names.Weapon Depot'] =  { url='zones.names.misc/zones.names.WeaponDepot.ogg',    length=0.76},
        
        -- zone events
        ['zones.events.lostbythem.1'] =     { url='zones.events/zones.events.lostbythem.1.ogg',      length=1.60 },-- "the enemy has lost control of ..."
        ['zones.events.lostbythem.2'] =     { url='zones.events/zones.events.lostbythem.2.ogg',      length=2.16 },-- "... is no longer under the enemys control"
        ['zones.events.lost.1'] =           { url='zones.events/zones.events.lost.1.ogg',            length=1.01 },-- "we've lost control of ..."
        ['zones.events.lost.2'] =           { url='zones.events/zones.events.lost.2.ogg',            length=1.80 },-- "... is no longer under our control"
        ['zones.events.capturedbyus.1'] =   { url='zones.events/zones.events.capturedbyus.1.ogg',    length=0.65}, -- "we've captured ...", 
        ['zones.events.capturedbyus.2'] =   { url='zones.events/zones.events.capturedbyus.2.ogg',    length=0.97}, -- "... has been seccured"
        ['zones.events.capturedbythem.1'] = { url='zones.events/zones.events.capturedbythem.1.ogg',  length=1.17}, -- "The enemy has captured ..."
        ['zones.events.capturedbythem.2'] = { url='zones.events/zones.events.capturedbythem.2.ogg',  length=1.54}, -- "... has been captured by the enemy"
        ['zones.events.underattack.1'] =    { url='zones.events/zones.events.underattack.1.ogg',     length=1.94}, -- "... is under attack by ground forces", 
        ['zones.events.underattack.2'] =    { url='zones.events/zones.events.underattack.2.ogg',     length=1.76}, -- "Enemy ground forces are attacking ..."
        
        -- squads
        ['squads.capture.working'] =            { url='squads/squads.capture.working.ogg',             length=1.76}, -- "Capture squad, Securing the area."
        ['squads.capture.extracting'] =         { url='squads/squads.capture.extracting.ogg',          length=1.99}, --"Capture squad, Requesting extraction."

        ['squads.sabotage.working'] =           { url='squads/squads.sabotage.working.ogg',            length=2.01}, -- "Saboteurs, Planting explosives."
        ['squads.sabotage.extracting'] =        { url='squads/squads.sabotage.extracting.ogg',         length=2.06}, -- "Saboteurs, Requesting extraction."
        ['squads.sabotage.missioncomplete'] =   { url='squads/squads.sabotage.missioncomplete.ogg',    length=2.58}, --"Sabotage complete, heading to extraction."

        ['squads.ambush.working'] =             { url='squads/squads.ambush.working.ogg',              length=1.59}, -- "Ambush squad, digging in."
        ['squads.ambush.extracting'] =          { url='squads/squads.ambush.extracting.ogg',           length=2.37}, --"Ambush squad requesting extraction."

        ['squads.engineer.working'] =           { url='squads/squads.engineer.working.ogg',            length=1.64}, -- "Engineers, Reporting for duty."
        ['squads.engineer.extracting'] =        { url='squads/squads.engineer.extracting.ogg',         length=1.87}, -- "Engineers, requesting extraction."

        ['squads.manpads.working'] =            { url='squads/squads.manpads.working.ogg',             length=2.27}, -- "Stinger squad, setting up defensive positions."
        ['squads.manpads.extracting'] =         { url='squads/squads.manpads.extracting.ogg',          length=1.85}, -- "Stinger squad, requesting extraction."

        ['squads.spy.working'] =                { url='squads/squads.spy.working.ogg',                 length=2.24}, -- "Agent in position, obtaining intelligence."
        ['squads.spy.extracting'] =             { url='squads/squads.spy.extracting.ogg',              length=1.65}, -- "Spy, requesting extraction."
        ['squads.spy.missioncomplete'] =        { url='squads/squads.spy.missioncomplete.ogg',         length=2.12}, -- "Intelligence obtained, heading to extract."

        ['squads.rapier.working'] =             { url='squads/squads.rapier.working.ogg',              length=1.07}, -- "Rapier operational."
        ['squads.rapier.extracting'] =          { url='squads/squads.rapier.extracting.ogg',           length=2.0}, -- "Rapier crew, requesting extraction."

        ['squads.assault.working'] =            { url='squads/squads.assault.working.ogg',             length=1.27}, -- "Assault squad, ready"
        ['squads.assault.engaging'] =           { url='squads/squads.assault.engaging.ogg',            length=2.17}, -- "Assault squad, engaging the enemy"
        ['squads.assault.extracting'] =         { url='squads/squads.assault.extracting.ogg',          length=2.17}, -- "Assault squad, requesting extraction."

        -- csar
        ['pilots.extracting.1.call.1'] = { url='pilots/pilots.extracting.1.call.1.ogg', length=2.24},
        ['pilots.extracting.1.call.2'] = { url='pilots/pilots.extracting.1.call.2.ogg', length=4.36},
        ['pilots.extracting.1.call.3'] = { url='pilots/pilots.extracting.1.call.3.ogg', length=4.58},
        ['pilots.extracting.1.call.4'] = { url='pilots/pilots.extracting.1.call.4.ogg', length=4.93},
        ['pilots.extracting.1.call.5'] = { url='pilots/pilots.extracting.1.call.5.ogg', length=3.75},
        ['pilots.extracting.1.call.quip.1'] = { url='pilots/pilots.extracting.1.call.quip.1.ogg', length=1.43},

        ['pilots.extracting.2.call.1'] = { url='pilots/pilots.extracting.2.call.1.ogg', length=2.24},
        ['pilots.extracting.2.call.2'] = { url='pilots/pilots.extracting.2.call.2.ogg', length=4.60},
        ['pilots.extracting.2.call.3'] = { url='pilots/pilots.extracting.2.call.3.ogg', length=4.50},
        ['pilots.extracting.2.call.4'] = { url='pilots/pilots.extracting.2.call.4.ogg', length=5.56},
        ['pilots.extracting.2.call.5'] = { url='pilots/pilots.extracting.2.call.5.ogg', length=4.10},
        ['pilots.extracting.2.call.quip.1'] = { url='pilots/pilots.extracting.2.call.quip.1.ogg', length=1.72},

        ['pilots.extracting.3.call.1'] = { url='pilots/pilots.extracting.3.call.1.ogg', length=2.36},
        ['pilots.extracting.3.call.2'] = { url='pilots/pilots.extracting.3.call.2.ogg', length=4.92},
        ['pilots.extracting.3.call.3'] = { url='pilots/pilots.extracting.3.call.3.ogg', length=5.05},
        ['pilots.extracting.3.call.4'] = { url='pilots/pilots.extracting.3.call.4.ogg', length=5.68},
        ['pilots.extracting.3.call.5'] = { url='pilots/pilots.extracting.3.call.5.ogg', length=3.81},
        ['pilots.extracting.3.call.quip.1'] = { url='pilots/pilots.extracting.3.call.quip.1.ogg', length=1.48},

        ['pilots.extracting.4.call.1'] = { url='pilots/pilots.extracting.4.call.1.ogg', length=2.24},
        ['pilots.extracting.4.call.2'] = { url='pilots/pilots.extracting.4.call.2.ogg', length=4.54},
        ['pilots.extracting.4.call.3'] = { url='pilots/pilots.extracting.4.call.3.ogg', length=4.90},
        ['pilots.extracting.4.call.4'] = { url='pilots/pilots.extracting.4.call.4.ogg', length=5.57},
        ['pilots.extracting.4.call.5'] = { url='pilots/pilots.extracting.4.call.5.ogg', length=3.99},
        ['pilots.extracting.4.call.quip.1'] = { url='pilots/pilots.extracting.4.call.quip.1.ogg', length=1.74},
        
        ['pilots.extracting.5.call.1'] = { url='pilots/pilots.extracting.5.call.1.ogg', length=2.36},
        ['pilots.extracting.5.call.2'] = { url='pilots/pilots.extracting.5.call.2.ogg', length=4.65},
        ['pilots.extracting.5.call.3'] = { url='pilots/pilots.extracting.5.call.3.ogg', length=4.89},
        ['pilots.extracting.5.call.4'] = { url='pilots/pilots.extracting.5.call.4.ogg', length=5.44},
        ['pilots.extracting.5.call.5'] = { url='pilots/pilots.extracting.5.call.5.ogg', length=3.92},
        ['pilots.extracting.5.call.quip.1'] = { url='pilots/pilots.extracting.5.call.quip.1.ogg', length=1.71},

        --gci
        
        ['gci.numbers.0'] = { url='gci/gci.numbers.0.ogg', length=0.61},
        ['gci.numbers.1'] = { url='gci/gci.numbers.1.ogg', length=0.41},
        ['gci.numbers.2'] = { url='gci/gci.numbers.2.ogg', length=0.41},
        ['gci.numbers.3'] = { url='gci/gci.numbers.3.ogg', length=0.42},
        ['gci.numbers.4'] = { url='gci/gci.numbers.4.ogg', length=0.51},
        ['gci.numbers.5'] = { url='gci/gci.numbers.5.ogg', length=0.48},
        ['gci.numbers.6'] = { url='gci/gci.numbers.6.ogg', length=0.52},
        ['gci.numbers.7'] = { url='gci/gci.numbers.7.ogg', length=0.56},
        ['gci.numbers.8'] = { url='gci/gci.numbers.8.ogg', length=0.40},
        ['gci.numbers.9'] = { url='gci/gci.numbers.9.ogg', length=0.51},

        ['gci.callsigns.Caveman'] = { url='gci/gci.callsigns.Caveman.ogg', length=0.69},
        ['gci.callsigns.Casper'] = { url='gci/gci.callsigns.Casper.ogg', length=0.66},
        ['gci.callsigns.Banjo'] = { url='gci/gci.callsigns.Banjo.ogg', length=0.72},
        ['gci.callsigns.Boomer'] = { url='gci/gci.callsigns.Boomer.ogg', length=0.48},
        ['gci.callsigns.Shaft'] = { url='gci/gci.callsigns.Shaft.ogg', length=0.57},
        ['gci.callsigns.Wookie'] = { url='gci/gci.callsigns.Wookie.ogg', length=0.53},
        ['gci.callsigns.Tiny'] = { url='gci/gci.callsigns.Tiny.ogg', length=0.52},
        ['gci.callsigns.Tool'] = { url='gci/gci.callsigns.Tool.ogg', length=0.47},
        ['gci.callsigns.Trash'] = { url='gci/gci.callsigns.Trash.ogg', length=0.53},
        ['gci.callsigns.Orca'] = { url='gci/gci.callsigns.Orca.ogg', length=0.53},
        ['gci.callsigns.Irish'] = { url='gci/gci.callsigns.Irish.ogg', length=0.61},
        ['gci.callsigns.Flex'] = { url='gci/gci.callsigns.Flex.ogg', length=0.53},
        ['gci.callsigns.Grip'] = { url='gci/gci.callsigns.Grip.ogg', length=0.39},
        ['gci.callsigns.Dice'] = { url='gci/gci.callsigns.Dice.ogg', length=0.52},
        ['gci.callsigns.Duck'] = { url='gci/gci.callsigns.Duck.ogg', length=0.40},
        ['gci.callsigns.Poet'] = { url='gci/gci.callsigns.Poet.ogg', length=0.50},
        ['gci.callsigns.Jack'] = { url='gci/gci.callsigns.Jack.ogg', length=0.47},
        ['gci.callsigns.Lego'] = { url='gci/gci.callsigns.Lego.ogg', length=0.58},
        ['gci.callsigns.Hurl'] = { url='gci/gci.callsigns.Hurl.ogg', length=0.44},
        ['gci.callsigns.Spin'] = { url='gci/gci.callsigns.Spin.ogg', length=0.57},

        -- 'Trash 1 1, fixed-wing, group of 2, bra: 3 4 6, for: 2 5 miles, at angels 3'
        ['gci.callout.helo'] = { url='gci/gci.callout.helo.ogg', length=0.82}, -- "helo"
        ['gci.callout.fixedwing'] = { url='gci/gci.callout.fixedwing.ogg', length=1.0}, -- "fixed wing"
        ['gci.callout.groupof'] = { url='gci/gci.callout.groupof.ogg', length=0.60}, -- "group of"
        ['gci.callout.bra'] = { url='gci/gci.callout.bra.ogg', length=0.81}, -- "bra"
        ['gci.callout.for'] = { url='gci/gci.callout.for.ogg', length=0.44}, -- "for"
        ['gci.callout.miles'] = { url='gci/gci.callout.miles.ogg', length=0.7}, -- "miles"
        ['gci.callout.atangels'] = { url='gci/gci.callout.atangels.ogg', length=0.58}, -- "at angels"
    }
end

