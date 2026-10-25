local Model=if script then require(game.ReplicatedStorage.FrontierNative.Core.LiveMatchModel)else require('../core/LiveMatchModel')
local M={};M.__index=M
local function adapter(config)
    local run=game:GetService('RunService');local teleport=game:GetService('TeleportService')
    local live=config.globalPvpEnabled and not run:IsStudio()
    local map=live and game:GetService('MemoryStoreService'):GetSortedMap('SuperCommanderLiveMatches_v1')
    return {live=live,time=os.time,spawn=task.spawn,
        write=function(entry)map:SetAsync(entry.id,entry,Model.ttl,math.max(0,1e6-(entry.watchers*1000+entry.alive)))end,
        remove=function(id)map:RemoveAsync(id)end,
        read=function()local out={};for _,row in ipairs(map:GetRangeAsync(Enum.SortDirection.Ascending,200))do table.insert(out,row.value)end;return out end,
        send=function(p,code,id)local o=Instance.new('TeleportOptions');o.ReservedServerAccessCode=code;o:SetTeleportData({superCommanderSpectate=id});teleport:TeleportAsync(config.matchPlaceId,{p},o)end,
        failed=live and teleport.TeleportInitFailed or nil,place=config.matchPlaceId}
end
function M.new(config,callbacks,dependencies)
    local a=dependencies or adapter(config)
    local self=setmetatable({a=a,callbacks=callbacks,rows={},readAt=-math.huge,published={},sending={}},M)
    if a.failed then a.failed:Connect(function(p,_,_,place)
        if place==a.place and self.sending[p.UserId]then self.sending[p.UserId]=nil;self.callbacks.notify(p.UserId,'관전 불가')end
    end)end
    return self
end
function M:sync(rooms)
    local now=self.a.time();local seen={}
    for _,room in ipairs(rooms)do
        if Model.listed(room)then
            seen[room.globalMatch]=true
            local last=self.published[room.globalMatch]
            if not last or now-last>=Model.renew then
                self.published[room.globalMatch]=now
                local entry=Model.entry(room,now)
                if self.a.live then self.a.spawn(function()pcall(self.a.write,entry)end)end
            end
        end
    end
    for id in pairs(self.published)do if not seen[id]then
        self.published[id]=nil
        if self.a.live then self.a.spawn(function()pcall(self.a.remove,id)end)end
    end end
end
function M:list(rooms,exclude)
    local now=self.a.time()
    if not self.a.live then
        local rows={};for _,room in ipairs(rooms)do if Model.listed(room)then table.insert(rows,Model.entry(room,now))end end
        return Model.public(rows,now,exclude)
    end
    if now-self.readAt>=Model.cache and now>=(self.retryAt or -math.huge)and not self.reading then
        self.reading=true
        self.a.spawn(function()
            local ok,rows=pcall(self.a.read)
            if ok then self.rows=rows;self.readAt=self.a.time();self.retryAt=nil else self.retryAt=self.a.time()+5 end
            self.reading=false
        end)
    end
    return Model.public(self.rows,now,exclude)
end
function M:mine(rooms,userId)
    local now=self.a.time()
    local rows,localIds={},{}
    for _,room in ipairs(rooms)do
        if room.globalMatch then localIds[room.globalMatch]=true end
        if Model.listed(room)then table.insert(rows,Model.entry(room,now))end
    end
    if self.a.live then for _,row in ipairs(self.rows or {})do if not localIds[row.id]then table.insert(rows,row)end end end
    return Model.mine(rows,userId,now)
end
function M:send(p,id)
    if not self.a.live then return false,'끝난 경기'end
    local row;for _,r in ipairs(self.rows)do if r.id==id then row=r;break end end
    if not row or type(row.code)~='string'or (row.updated or 0)+Model.ttl<self.a.time()then return false,'끝난 경기'end
    if self.sending[p.UserId]and self.a.time()-self.sending[p.UserId]<20 then return false,'경기로 이동 중이에요.'end
    self.sending[p.UserId]=self.a.time()
    local ok=pcall(self.a.send,p,row.code,id)
    if not ok then self.sending[p.UserId]=nil;return false,'관전 실패'end
    return true,'관전하러 가는 중…'
end
function M:leaving(id)self.sending[id]=nil end
return M
