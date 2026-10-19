local Format=if script then require(script.Parent.TeamFormat)else require('./TeamFormat')
local Formation=if script then require(script.Parent.PartyFormation)else require('./PartyFormation')
local M={}
function M.count(r,n)
    if r.mode=='coop'then return 1 end
    if r.teamFormat==Format.humansVsNations then return 2 end
    return Format.size[r.teamFormat]and math.max(2,math.ceil(n/Format.size[r.teamFormat]))or r.teamCount or 2
end
function M.plan(r,members)
    local out={teams={},count=M.count(r,#members),selectable=r.mode=='teams'and r.teamFormat~=Format.humansVsNations and r.teamAssignment=='select',used=0,counts={}}
    out.capacity=r.teamFormat==Format.humansVsNations and r.maximum or Format.size[r.teamFormat]or math.ceil(r.maximum/out.count)
    local list=table.clone(members);table.sort(list,function(a,b)return a.userId<b.userId end)
    for t=1,out.count do out.counts[t]=0 end
    local grouped=false;local users,groups={},{}
    for _,p in ipairs(list)do table.insert(users,p.userId);groups[tostring(p.userId)]=p.group;grouped=grouped or p.group~=nil end
    if grouped and r.mode=='teams'and r.teamFormat~=Format.humansVsNations then
        local assigned=Formation.split(users,groups,out.capacity*out.count,out.count,Format.size[r.teamFormat]~=nil)
        if not assigned then return nil end
        if not out.selectable then
            for _,p in ipairs(list)do local t=assigned[p.userId];out.teams[p.userId]=t;out.counts[t]+=1 end
            for _,n in ipairs(out.counts)do if n>0 then out.used+=1 end end
            out.needsOpponent=out.used<2;return out
        end
        local blocks,order={},{}
        for _,p in ipairs(list)do local key=p.group or 'solo:'..p.userId
            if not blocks[key]then blocks[key]={};table.insert(order,key)end;table.insert(blocks[key],p)
        end
        table.sort(order,function(a,b)return #blocks[a]>#blocks[b]or #blocks[a]==#blocks[b]and blocks[a][1].userId<blocks[b][1].userId end)
        for _,key in ipairs(order)do local block=blocks[key];local t=block[1].team
            if not t or t<1 or t>out.count or out.counts[t]+#block>out.capacity then t=nil end
            if not t then for team=1,out.count do if out.counts[team]+#block<=out.capacity and (not t or out.counts[team]<out.counts[t])then t=team end end end
            if not t then return nil end
            for _,p in ipairs(block)do out.teams[p.userId]=t;out.counts[t]+=1 end
        end
        for _,n in ipairs(out.counts)do if n>0 then out.used+=1 end end
        out.needsOpponent=out.used<2;return out
    end
    if out.selectable then for _,p in ipairs(list)do
        local t=p.team
        if type(t)=='number'and t%1==0 and t>=1 and t<=out.count and out.counts[t]<out.capacity then out.teams[p.userId]=t;out.counts[t]+=1 end
    end end
    for i,p in ipairs(list)do if not out.teams[p.userId]then
        local t
        if r.mode=='coop'or r.teamFormat==Format.humansVsNations then t=1
        elseif not out.selectable then t=Format.size[r.teamFormat]and (i-1)//Format.size[r.teamFormat]+1 or (i-1)%math.min(out.count,#list)+1
        else for team=1,out.count do if out.counts[team]<out.capacity and (not t or out.counts[team]<out.counts[t])then t=team end end end
        if not t then return nil end
        out.teams[p.userId]=t;out.counts[t]+=1
    end end
    for _,v in ipairs(out.counts)do if v>0 then out.used+=1 end end
    out.needsOpponent=r.mode=='teams'and r.teamFormat~=Format.humansVsNations and out.used<2
    return out
end
function M.choose(r,members,id,team)
    local p=M.plan(r,members)
    if not p or not p.selectable then return false,'automatic'end
    if type(team)~='number'or team%1~=0 or team<0 or team>p.count then return false,'team'end
    local found=false;local explicit=0;local group
    for _,m in ipairs(members)do if m.userId==id then found=true;group=m.group end end
    local moving=0;for _,m in ipairs(members)do if m.userId==id or group and m.group==group then moving+=1 elseif m.team==team then explicit+=1 end end
    if not found then return false,'stale'end
    if team>0 and explicit+moving>p.capacity then return false,'teamfull'end
    return true
end
function M.view(r,members,assigned,locked)
    local p=M.plan(r,members);if not p then return nil end
    if assigned then p.teams={};p.counts=table.create(p.count,0);for _,m in ipairs(members)do local t=assigned[tostring(m.userId)]or assigned[m.userId];if t then p.teams[m.userId]=t;p.count=math.max(p.count,t);p.counts[t]=(p.counts[t]or 0)+1 end end end
    local teams={};for id,t in pairs(p.teams)do teams[tostring(id)]=t end
    p.teams=teams;p.locked=locked==true
    return p
end
return M
