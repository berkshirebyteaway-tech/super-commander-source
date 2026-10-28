local M={}
M.min,M.max=.5,3
M.kinds={'campaign','solo','official','custom','ranked','daily'}
M.defaultModes='all'
function M.clamp(v)
    v=tonumber(v);if not v or v~=v then return 1 end
    return math.clamp(v,M.min,M.max)
end
function M.kind(selection,single)
    if selection.intro or selection.campaign then return 'campaign'end
    if selection.daily then return 'daily'end
    if selection.ranked or selection.clanwar then return 'ranked'end
    if selection.custom then return 'custom'end
    if single then return 'solo'end
    return 'official'
end
function M.applies(modes,kind)
    if type(modes)~='string'then return false end
    for word in modes:lower():gmatch('[%a]+')do if word=='all'or word==kind then return true end end
    return false
end
function M.forMatch(speed,modes,selection,single)
    speed=M.clamp(speed)
    if speed==1 or not M.applies(modes,M.kind(selection,single))then return nil end
    return speed
end
M.unitMin,M.unitMax=.25,3
M.unitGroups={nuke={'AtomBomb','HydrogenBomb','MIRV','MIRVWarhead'},transport={'TransportShip'},warship={'Warship'}}
function M.unitClamp(v)
    v=tonumber(v);if not v or v~=v then return 1 end
    return math.clamp(v,M.unitMin,M.unitMax)
end
function M.unitsForMatch(factors,modes,selection,single)
    if not M.applies(modes,M.kind(selection,single))then return nil end
    local out,any={},false
    for group in pairs(M.unitGroups)do local f=M.unitClamp(factors[group]);if f~=1 then out[group]=f;any=true end end
    return any and out or nil
end
function M.unitPace(settings)
    local u=type(settings)=='table'and settings.simUnits;if type(u)~='table'then return nil end
    local out,any={},false
    for group,kinds in pairs(M.unitGroups)do local f=tonumber(u[group]);if f and f~=1 then for _,k in ipairs(kinds)do out[k]=f end;any=true end end
    return any and out or nil
end
function M.of(settings)return type(settings)=='table'and tonumber(settings.simSpeed)or 1 end
function M.seconds(settings,ticks)return (ticks or 0)/10/M.of(settings)end
function M.pace(state)return 10*M.of(state and state.settings)end
M.shown=10
return M
