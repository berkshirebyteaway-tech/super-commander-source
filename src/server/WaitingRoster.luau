local M={};M.__index=M
function M.new(remote,ports)
    ports=ports or {}
    return setmetatable({remote=remote,matches={},of={},find=ports.find or function(id)return game:GetService('Players'):GetPlayerByUserId(id)end},M)
end
local function ids(members,departed)
    local out={};for uid in pairs(members or {})do local n=tonumber(uid);if n and not departed[n]then table.insert(out,n)end end
    table.sort(out);return out
end
function M:arrive(player,hint,m)
    if type(hint)~='string'or type(m)~='table'or type(m.rules)~='table'then return end
    local old=self.of[player.UserId];if old and old~=hint then self:leave(player)end
    local match=self.matches[hint]or {arrived={},departed={}}
    match.departed[player.UserId]=nil
    match.users=ids(m.members,match.departed);match.rules=m.rules;match.arrived[player.UserId]=true
    self.matches[hint]=match;self.of[player.UserId]=hint
    self:send(hint)
end
function M:view(hint)
    local match=self.matches[hint];if not match then return nil end
    local r=match.rules;local arrived={}
    for _,id in ipairs(match.users)do if match.arrived[id]then table.insert(arrived,id)end end
    local ai=nil
    if not r.aiPerHuman then
        if r.settings and r.settings.humansVsNations then ai=#match.users elseif r.mode=='ffa'then ai=math.max(0,(r.maximum or #match.users)-#match.users)end
    end
    return {match=hint,users=match.users,arrived=arrived,maximum=r.maximum,mode=r.mode,map=r.map,ai=ai,
        teamFormat=r.teamFormat,special=r.special==true,big=r.settings and r.settings.mapSize=='normal'or nil}
end
function M:send(hint)
    local v=self:view(hint);if not v then return end
    for _,id in ipairs(v.arrived)do local p=self.find(id);if p then self.remote:FireClient(p,v)end end
end
function M:leave(player)
    local hint=self.of[player.UserId];if not hint then return end
    self.of[player.UserId]=nil
    local match=self.matches[hint];if not match then return end
    match.arrived[player.UserId]=nil;match.departed[player.UserId]=true
    local users={};for _,id in ipairs(match.users)do if id~=player.UserId then table.insert(users,id)end end;match.users=users
    if next(match.arrived)==nil then self.matches[hint]=nil else self:send(hint)end
end
function M:close(hint)
    local match=self.matches[hint];if not match then return end
    for id in pairs(match.arrived)do self.of[id]=nil end
    self.matches[hint]=nil
end
return M
