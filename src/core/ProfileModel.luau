local C=if script then require(script.Parent.CosmeticCatalog) else require("./CosmeticCatalog")
local O=if script then require(script.Parent.OutgameRules)else require('./OutgameRules')
local Policy=if script then require(script.Parent.CountryPolicy)else require('./CountryPolicy')
local Favorites=if script then require(script.Parent.EmojiFavorites)else require('./EmojiFavorites')
local Supply=if script then require(script.Parent.SupplyRules)else require('./SupplyRules')
local Standard=if script then require(script.Parent.CommanderStandardRules)else require('./CommanderStandardRules')
local Motions=if script then require(script.Parent.MotionLoadout)else require('./MotionLoadout')
local P={version=2}
function P.validFlag(f) return type(f)=="string" and string.match(f,"^%l%l$")~=nil and not Policy.hiddenFlags[f] end
function P.validVolume(v) return type(v)=="number" and v>=.25 and v<=1.5 end
function P.validOpacity(v) return v==1 or v==.75 or v==.5 or v==.25 end
function P.validNumber(key,v) if key=='hudOpacity' then return P.validOpacity(v) end;if key=='musicVolume'and v==0 then return true end;return P.validVolume(v) end
P.languages={["ko-kr"]=true,["en-us"]=true}
function P.decode(raw)
    if raw==nil then return {version=P.version,commanderStandard=Standard.default,loadout=C.loadout(C.default),preferences={reducedEffects=false,soundsMuted=false,cameraShake=true,mapFlashes=true,voiceTeamOnly=true,sfxVolume=1,musicVolume=1,hudOpacity=1,emojiFavorites={},motionLoadout={"wave"}},outgame=O.new(),commerce=Supply.new()} end
    if type(raw)~="table" or(raw.version~=1 and raw.version~=P.version)then return nil,"unsupported-profile" end
    if type(raw.loadout)~="table" or type(raw.preferences)~="table" then return nil,"invalid-profile" end
    if raw.version==P.version and(type(raw.commerce)~='table'or type(raw.outgame)~='table')then return nil,'invalid-profile'end
    local out={version=P.version,loadout=C.loadout(C.default),preferences={reducedEffects=false,soundsMuted=false,cameraShake=true,mapFlashes=true,voiceTeamOnly=true,sfxVolume=1,musicVolume=1,hudOpacity=1}}
    for _,slot in ipairs(C.slots) do if C.styles[raw.loadout[slot]] then out.loadout[slot]=raw.loadout[slot] end end
    for key,default in pairs(out.preferences) do local v=raw.preferences[key];if type(v)==type(default) and (type(v)=="boolean" or P.validNumber(key,v)) then out.preferences[key]=v end end
    out.preferences.emojiFavorites=Favorites.copy(raw.preferences.emojiFavorites)
    if P.languages[raw.preferences.language] then out.preferences.language=raw.preferences.language end
    if P.validFlag(raw.flag) then out.flag=raw.flag end
    local progress,err=O.decode(raw.outgame);if not progress then return nil,err end;out.outgame=progress
    out.preferences.motionLoadout=Motions.copy(raw.preferences.motionLoadout,O.level(progress.xp))
    local commerce,why=Supply.decode(raw.commerce);if not commerce then return nil,why end;out.commerce=commerce
    out.commanderStandard=Standard.effective(raw.commanderStandard,O.level(progress.xp),commerce.owned)
    return out
end
function P.patch(raw,patch)
    local decoded,err=P.decode(raw);if not decoded then return nil,err end
    local out=raw and table.clone(raw) or decoded
    out.version=P.version
    out.commerce=decoded.commerce;out.outgame=decoded.outgame
    out.loadout=table.clone(decoded.loadout);out.preferences=table.clone(decoded.preferences)
    out.commanderStandard=decoded.commanderStandard or Standard.default
    if patch.commanderStandard~=nil then
        if not Standard.owns(patch.commanderStandard,O.level(decoded.outgame.xp),decoded.commerce.owned)then return nil,'locked-standard'end
        out.commanderStandard=patch.commanderStandard
    end
    for slot,id in pairs(patch.loadout or {}) do
        if not C.validSlot(slot) or not C.styles[id] then return nil,"invalid-loadout" end
        out.loadout[slot]=id
    end
    for key,value in pairs(patch.preferences or {}) do
        if key=='motionLoadout'then
            if not Motions.valid(value,O.level(decoded.outgame.xp))then return nil,'invalid-preference'end
            out.preferences[key]=table.clone(value);continue
        end
        if key=='language'then
            if value~='auto'and not P.languages[value]then return nil,'invalid-preference'end
            out.preferences.language=value~='auto'and value or nil;continue
        end
        if key=='emojiFavorites'then
            if not Favorites.valid(value)then return nil,'invalid-preference'end
            out.preferences[key]=table.clone(value);continue
        end
        if decoded.preferences[key]==nil or type(value)~=type(decoded.preferences[key]) or (type(value)=="number" and not P.validNumber(key,value)) then return nil,"invalid-preference" end
        out.preferences[key]=value
    end
    if patch.flag==false then out.flag=nil
    elseif patch.flag~=nil then if not P.validFlag(patch.flag) then return nil,"invalid-flag" end;out.flag=patch.flag end
    if patch.loadout or patch.commanderStandard~=nil then P.syncPreset(out)end
    return out
end
function P.effective(profile,owned)
    local result=C.loadout(C.default)
    for _,slot in ipairs(C.slots) do
        local id=profile.loadout[slot]
        if C.styles[id] and O.owns(profile.outgame or O.new(),owned,id,slot) then result[slot]=id end
    end
    return result
end
function P.effectiveStandard(profile)return Standard.effective(profile.commanderStandard,O.level(profile.outgame.xp),type(profile.commerce)=='table'and profile.commerce.owned or nil)end
function P.syncPreset(profile)
    local o=profile.outgame;local n=o and o.activeLoadout
    if type(n)~='number'or n%1~=0 or n<1 or n>12 then return profile end
    local saved=table.clone(profile.loadout);saved.commanderStandard=P.effectiveStandard(profile);o.loadouts[tostring(n)]=saved
    return profile
end
return P
