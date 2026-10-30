local Rules=if script then require(script.Parent.RankedRules)else require('./RankedRules')
local M={}
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
function M.view(r)
    if type(r)~='table'then return nil end
    if r.pending or not finite(r.t)or not finite(r.before)or not finite(r.delta)then return {pending=true}end
    local tier=Rules.trophyTier(r.t);local i=table.find(Rules.trophyTiers,tier);local nextTier=Rules.trophyTiers[i+1]
    local span=nextTier and nextTier.min-tier.min
    return {pending=false,t=r.t,before=r.before,delta=r.delta,tier=r.tier or tier.id,
        beforeTier=Rules.trophyTier(r.before).id,min=tier.min,nextAt=nextTier and nextTier.min,nextTier=nextTier and nextTier.id,
        progress=span and math.clamp((r.t-tier.min)/span,0,1)or 1,
        priorProgress=span and math.clamp((r.before-tier.min)/span,0,1)or 1,
        promoted=Rules.trophyTier(r.before).min<tier.min}
end
return M
