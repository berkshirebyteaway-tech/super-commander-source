local M={}
local PartyPlay=if script then require(script.Parent.PartyPlay)else require('./PartyPlay')
function M.select(fields,party,own)
    local out={}
    local function better(a,b)
        if not b then return true end
        local ar,br=a.remaining or math.huge,b.remaining or math.huge
        if ar~=br then return ar<br end
        if a.count~=b.count then return a.count>b.count end
        return a.id<b.id
    end
    for _,f in ipairs(fields or {})do
        if not PartyPlay.assess(f,party,own)then continue end
        local key=f.kind=='custom'and 'custom'or f.kind=='official'and (f.rules.mode=='teams'and 'teams'or f.rules.mode=='ffa'and 'ffa')or nil
        if key and better(f,out[key])then out[key]=f end
    end
    return out
end
return M
