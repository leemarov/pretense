
RadioFrequencyTracker = {}

do
    RadioFrequencyTracker.radios = {}

    function RadioFrequencyTracker.registerRadio(groupname, name, frequency)
        RadioFrequencyTracker.radios[groupname] = {name = name, frequency = frequency}    
    end

    local function radioToString(label, radio)
        local comFreq = '['..label..'] ['
        for i,v in ipairs(radio.freqs) do
            if i>1 then comFreq = comFreq..' ' end
            comFreq = comFreq..string.format("%.3f", v.frequency/1000000)
            if v.modulation == 0 then
                comFreq = comFreq..' AM'
            else
                comFreq = comFreq..' FM'
            end

            if i < #radio.freqs then comFreq = comFreq..' |' end
        end

        return comFreq..']'
    end

    function RadioFrequencyTracker.getRadioFrequencyMessage(side)
        local radios ={}
        for i,v in pairs(RadioFrequencyTracker.radios) do
            local gr = Group.getByName(i) 
            if gr and gr:getCoalition()==side then
                table.insert(radios, v)
            else
                RadioFrequencyTracker.radios[i] = nil
            end
        end

        table.sort(radios, function (a,b) 
            if a.permanent == b.permanent then
                return a.name < b.name 
            else
                return a.permanent
            end
        end)

        local msg = 'Active frequencies:'
        
        msg = msg..'\n  '..radioToString('Command', TransmissionManager.radios.command)
        msg = msg..'\n  '..radioToString('Infantry', TransmissionManager.radios.infantry)
        msg = msg..'\n  '..radioToString('GCI', TransmissionManager.radios.gci)

        for i,v in ipairs(radios) do
            msg = msg..'\n  '..v.name..' ['..v.frequency..']'
        end

        return msg
    end
end


