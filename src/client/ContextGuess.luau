local Snap=require(script.Parent.BuildSnap)
local M={seen={}}
local NUKES={"AtomBomb","HydrogenBomb","MIRV"}
local function mine(state,kind)
    local n=0;for _,u in ipairs(state.units or {})do if u.kind==kind and (u.owner or 1)==1 and u.active~=false then n+=1 end end;return n
end
function M.remember(owner,r)if type(r)=='table'then M.seen[owner or 0]=r end end
function M.reset()M.seen={}end
function M.context(state,tile,owner,info,rules)
    local key=tostring(owner or 0);local attack=state.attackTargets and state.attackTargets[key]==true
    local out={attack=attack,transport=false,warship=false,rockets=false}
    if info and not info.land then out.warship=not rules.disabled(state.settings,"Warship")and mine(state,"Port")>0;return out end
    local nuke=false;for _,k in ipairs(NUKES)do if not rules.disabled(state.settings,k)then nuke=true end end
    out.rockets=nuke and mine(state,"MissileSilo")>0
    if not rules.disabled(state.settings,"TransportShip")then
        local last=M.seen[owner or 0];local landing=if last and last.transport~=nil then (last.transport or last.transportFull)==true else not attack
        local full=mine(state,"TransportShip")>=3
        out.transport=landing and not full;out.transportFull=landing and full
    end
    out.attackRoute=attack and 'land' or 'transport'
    return out
end
function M.buildables(state,tile,owners,map,rules,kinds)
    if not map then return nil end
    local m=map.meta;local ctx={width=m.width,height=m.height,terrain=map.terrain,owners=owners,units=state.units,structures=rules.structures,upgradable=rules.upgradable}
    local out={}
    for _,k in ipairs(kinds)do local at=Snap.find(k,tile,ctx);out[k]={valid=at~=nil,tile=at,guess=true}end
    return out
end
return M
