
Group.getByNameBase = Group.getByName

function Group.getByName(name)
    local g = Group.getByNameBase(name)
    if not g then return nil end
    if g:getSize() == 0 then return nil end
    return g
end

