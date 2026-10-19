local Rules=if script then require(script.Parent.BattlefieldRules)else require('./BattlefieldRules')
local Custom=if script then require(script.Parent.CustomBattlefieldRules)else require('./CustomBattlefieldRules')
local Teams=if script then require(script.Parent.TeamLobby)else require('./TeamLobby')
local Flow=if script then require(script.Parent.PlayFlow)else require('./PlayFlow')
local M={}
function M.users(party)return party and party.users or {0}end
function M.assess(f,party,own)
    if not f or not f.rules then return false,'unavailable'end
    local ids=M.users(party);local incoming={};for _,id in ipairs(ids)do incoming[tostring(id)]=true end
    if f.id==own then return true end
    if f.phase=='transferring'or f.teamPlan and f.teamPlan.locked then return false,'locked'end
    if f.kind=='custom'and f.rules.visibility=='invite'then return false,'private'end
    local users,groups,members={}, {},{};local retained=0
    for _,p in ipairs(f.members or {})do
        if incoming[tostring(p.userId)]then retained+=1 else
            table.insert(users,p.userId);groups[tostring(p.userId)]=p.group;table.insert(members,p)
        end
    end
    if (f.count or 0)-retained+#ids>f.rules.maximum then return false,'full'end
    for _,id in ipairs(ids)do table.insert(users,id);groups[tostring(id)]=#ids>1 and 'candidate-party'or nil;table.insert(members,{userId=id,group=groups[tostring(id)]})end
    if f.kind=='official'then
        if not Rules.canFit(f.rules,users,groups)then return false,'teamfull'end
    elseif f.rules.mode=='teams'and not Teams.plan(f.rules,members)then return false,'teamfull'end
    return true
end
function M.pick(fields,party,own)
    local best,score;local grouped=#M.users(party)>1
    for _,f in ipairs(fields or {})do if f.kind=='official'and M.assess(f,party,own)then
        local value=(grouped and f.rules.mode~='teams'and 100000 or 0)+(f.remaining or 10000)-(f.count or 0)*.01
        if not score or value<score or value==score and f.id<best.id then best,score=f,value end
    end end
    return best
end
function M.available(fields,party,own)
    local n=0;for _,f in ipairs(fields or {})do if M.assess(f,party,own)then n+=1 end end;return n
end
function M.coop(map,party,challenge)
    local count=math.clamp(#M.users(party),1,5);local r=Custom.default(map,'coop')
    r.maximum=count;r.visibility='invite';r.aiPerHuman=1;r.aiCount=challenge and math.ceil(count*1.6)or count
    r.settings.difficulty=challenge and 'Hard'or 'Medium'
    if Flow.coopAI(r,count).cap<r.aiCount then r.map='world'end
    return r
end
return M
