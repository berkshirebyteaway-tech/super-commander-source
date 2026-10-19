local M={}
function M.isReady(party,id)
    local ready=party and party.ready
    return ready~=nil and (ready[id]==true or ready[tostring(id)]==true)
end
function M.readyCount(party)
    local count=0
    for _,id in ipairs(party and party.users or {})do
        if id==party.leader or M.isReady(party,id)then count+=1 end
    end
    return count
end
local function blocks(users,groups)
    local lookup,list={},{}
    for _,id in ipairs(users)do
        local key=groups and groups[tostring(id)]
        key=key and 'party:'..key or 'solo:'..tostring(id)
        if not lookup[key]then lookup[key]={users={},first=id};table.insert(list,lookup[key])end
        local b=lookup[key];table.insert(b.users,id);b.first=math.min(b.first,id)
    end
    table.sort(list,function(a,b)return #a.users>#b.users or #a.users==#b.users and a.first<b.first end)
    return list
end
local function solve(users,groups,maximum,balanced)
    if #users>maximum then return nil end
    local cap=maximum//2;local list=blocks(users,groups)
    local ways={[0]={}}
    for i,b in ipairs(list)do
        if #b.users>cap then return nil end
        local nextWays={}
        for n=0,cap do local path=ways[n];if not path then continue end
            nextWays[n]=nextWays[n]or path
            if n+#b.users<=cap and not nextWays[n+#b.users]then
                local added=table.clone(path);added[i]=true;nextWays[n+#b.users]=added
            end
        end
        ways=nextWays
    end
    local first,last=math.max(0,#users-cap),math.min(cap,#users)
    if balanced then
        if #users<2 or #list<2 then return nil end
        first=math.floor(#users/2);last=math.ceil(#users/2)
    end
    for n=first,last do local path=ways[n]
        if path then
            local teams={};for i,b in ipairs(list)do for _,id in ipairs(b.users)do teams[id]=path[i]and 1 or 2 end end
            return teams
        end
    end
    return nil
end
local function spread(users,groups,maximum,count,balanced,pack)
    if #users>maximum then return nil end
    local cap=maximum//count;local list=blocks(users,groups);local sizes={};for t=1,count do sizes[t]=0 end
    local teams={}
    for _,b in ipairs(list)do
        local best
        for t=1,count do
            if sizes[t]+#b.users<=cap and (not best or (if pack then sizes[t]>sizes[best]else sizes[t]<sizes[best]))then best=t end
        end
        if not best then return nil end
        sizes[best]+=#b.users;for _,id in ipairs(b.users)do teams[id]=best end
    end
    if balanced then
        if #users<2 or #list<2 then return nil end
        local low,high,used=math.huge,0,0
        for t=1,count do if sizes[t]>0 or not pack then low=math.min(low,sizes[t]);high=math.max(high,sizes[t]);used+=1 end end
        if used<2 or high-low>1 then return nil end
    end
    return teams
end
local function place(users,groups,maximum,count,balanced,pack)
    count=count or 2
    if count==2 and not pack then return solve(users,groups,maximum,balanced)end
    return spread(users,groups,maximum,count,balanced,pack)
end
function M.fits(users,groups,maximum,count,pack)return place(users,groups,maximum,count,false,pack)~=nil end
function M.teams(users,groups,maximum,count,pack)return place(users,groups,maximum,count,true,pack)end
function M.split(users,groups,maximum,count,pack)return place(users,groups,maximum,count,false,pack)end
return M
