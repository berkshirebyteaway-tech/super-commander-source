local M={};M.__index=M
M.piece=24000
M.gap=.35
function M.new(remote,maps,store,ports)
    ports=ports or {}
    local self=setmetatable({remote=remote,maps=maps,store=store,sending={},have={},
        wait=ports.wait or task.wait,spawn=ports.spawn or task.spawn},M)
    if remote.OnServerEvent then remote.OnServerEvent:Connect(function(p,msg)self:confirm(p,msg)end)end
    return self
end
local function tag(key,fnv)return key..'/'..tostring(fnv)end
local function note(self,player,step,data)if self.log then pcall(self.log,player,step,data)end end
function M:arrive(player,rules)
    local key=type(rules)=='table'and rules.map
    if type(key)~='string'or not(rules.settings and rules.settings.mapSize=='normal')or not self.maps.hasNormal(key)then return end
    local meta=self.maps.sized(key,'normal')
    local id=player.UserId;local want=tag(key,meta.fnv32)
    if self.have[id]==want or self.sending[id]and self.sending[id].tag==want then return end
    local job={tag=want,at=os.clock()};self.sending[id]=job
    self.spawn(function()
        if not self.store:ensure(key)then if self.sending[id]==job then self.sending[id]=nil end;note(self,player,'mapPreloadSent',{map_key=key,result='failed',reason='storage_unavailable'});return end
        local parts=self.maps.normalParts(key)
        if not parts or self.sending[id]~=job then return end
        for i,part in ipairs(parts)do
            local pieces=math.max(1,math.ceil(#part/M.piece))
            for j=1,pieces do
                if self.sending[id]~=job or player.Parent==nil then return end
                local last=i==#parts and j==pieces
                if last then job.sent=true end
                self.remote:FireClient(player,{key=key,fnv=meta.fnv32,part=i,parts=#parts,piece=j,pieces=pieces,data=string.sub(part,(j-1)*M.piece+1,j*M.piece)})
                if not last then self.wait(M.gap)end
            end
        end
        if job.sent then note(self,player,'mapPreloadSent',{item=key,map_key=key,value=#parts,elapsed_seconds=os.clock()-job.at,result='complete'})end
    end)
end
function M:confirm(player,msg)
    local id=player.UserId;local job=self.sending[id]
    if type(msg)~='table'then return end
    if msg.missing then if msg.missing~=true or not self.have[id]then return end;self.have[id]=nil;self.misses=self.misses or {};local n=(self.misses[id]or 0)+1;self.misses[id]=n;if n<=3 then note(self,player,'mapPreloadMissing',{count=n,result='retry'})end;if self.missing then self.missing(player)end;return end
    if job and job.sent and type(msg.done)=='string'and msg.done==job.tag then self.have[id]=job.tag;self.sending[id]=nil;note(self,player,'mapPreloadConfirmed',{value=os.clock()-job.at,result='ok'})end
end
function M:pack(e,s,map)
    local id=e.player.UserId
    local want=tag(map.meta.key,map.meta.fnv32)
    if self.have[id]==want then s.mapStreamed=map.meta.fnv32 else s.mapPacked=map.packed;self.sending[id]=nil end
end
function M:settle(cfg,key,official)
    if cfg.mapSize=='normal'and not self.store:ensure(key)then
        cfg.mapSize=nil
        if official and cfg.bots==400 then cfg.bots=100 end
        return false
    end
    return true
end
function M:leave(player)local id=player.UserId;self.sending[id]=nil;self.have[id]=nil;if self.misses then self.misses[id]=nil end end
return M
