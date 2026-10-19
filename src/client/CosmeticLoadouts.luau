local Players=game:GetService('Players')
local C=require(script.Parent.Parent.Core.CosmeticCatalog)
local M={}
local seen={}
function M.all(state)
    local out={}
    for _,f in ipairs(state.factions or {})do
        local player=f.userId and Players:GetPlayerByUserId(f.userId)or f.id==1 and not f.userId and Players.LocalPlayer
        if f.id==1 and (not f.userId or player==Players.LocalPlayer)then out[f.id]=state.cosmetics
        elseif player then local loadout={};for _,slot in ipairs(C.slots)do local id=player:GetAttribute('CommanderCosmetic_'..slot);if C.styles[id]then loadout[slot]=id end end;out[f.id]=loadout;seen[f.userId]=loadout
        elseif f.userId and seen[f.userId]then out[f.id]=seen[f.userId]end
    end
    return out
end
function M.of(state,owner)return M.all(state)[owner]end
return M
