
RadioFrequencyTracker = {}

do
    RadioFrequencyTracker.radios = {}

    function RadioFrequencyTracker.registerRadio(groupname, name, frequency)
        RadioFrequencyTracker.radios[groupname] = {name = name, frequency = frequency}    
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

        table.sort(radios, function (a,b) return a.name < b.name end)

        local msg = 'Active frequencies:'
        for i,v in ipairs(radios) do
            msg = msg..'\n  '..v.name..' ['..v.frequency..']'
        end

        return msg
    end
end


