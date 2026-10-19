local Players=if script then game:GetService('Players')else nil
local Run=if script then game:GetService('RunService')else nil
local M={};M.__index=M
M.size=100;M.shown=10;M.writeEvery=120;M.readEvery=120
function M.new(clock)
    local self=setmetatable({players=Players,cache={},names={},memory={},pending={},sent={},lastWrite={},clock=clock or os.time,localMode=Run:IsStudio()or game.GameId==0},M)
    return self
end
function M:store(season)
    local scope='s'..tostring(season)
    if self.localMode then
        local mem=self.memory[scope]or {};self.memory[scope]=mem
        return {UpdateAsync=function(_,k,fn)local v=fn(mem[k]);if v then mem[k]=v end;return v end,
            GetSortedAsync=function(_,_,n)local list={};for k,v in pairs(mem)do table.insert(list,{key=k,value=v})end;table.sort(list,function(a,b)return a.value>b.value end)
                return {GetCurrentPage=function()return {table.unpack(list,1,math.min(#list,n or M.size))}end}end}
    end
    return game:GetService('DataStoreService'):GetOrderedDataStore('SuperCommanderSeason_v1',scope)
end
function M:note(userId,season,score)
    if type(score)~='number'or score<=0 or type(season)~='number'then return end
    local key=userId..':'..season
    if (self.sent[key]or 0)>=score then return end
    self.pending[key]={userId=userId,season=season,score=math.floor(score)}
    if self.clock()-(self.lastWrite[userId]or -math.huge)>=M.writeEvery then self:flush(userId)end
end
function M:flush(userId)
    for key,v in pairs(self.pending)do if v.userId==userId then
        self.pending[key]=nil;self.lastWrite[userId]=self.clock()
        local ok=pcall(function()self:store(v.season):UpdateAsync(tostring(userId),function(old)
            if type(old)=='number'and old>=v.score then return nil end;return v.score end)end)
        if ok then self.sent[key]=math.max(self.sent[key]or 0,v.score)else self.pending[key]=self.pending[key]or v end
    end end
end
function M:leave(userId)
    self:flush(userId);self.lastWrite[userId]=nil
    for key in pairs(self.sent)do if key:match('^'..userId..':')then self.sent[key]=nil end end
end
local function name(self,id)
    if self.names[id]then return self.names[id]end
    local p=self.players and self.players:GetPlayerByUserId(id)
    local n=p and p.DisplayName
    if not n then local ok,v=pcall(function()return self.players:GetNameFromUserIdAsync(id)end);if not ok or type(v)~='string'then return '#'..id end;n=v end
    self.names[id]=n;return n
end
function M:board(userId,season,myScore)
    local now=self.clock();local c=self.cache[season]
    if (not c or now-c.at>M.readEvery)and not self.reading and now>=(self.retryAt or -math.huge)then
        self.reading=true
        local ok,page=pcall(function()return self:store(season):GetSortedAsync(false,M.size):GetCurrentPage()end)
        self.reading=nil
        if ok then
            local rows={};for i,entry in ipairs(page)do local id=tonumber(entry.key);if id then table.insert(rows,{rank=i,userId=id,score=entry.value})end end
            c={at=now,rows=rows};self.cache={[season]=c}
        else self.retryAt=now+15 end
    end
    if not c then return {season=season,rows={},unavailable=true}end
    local top={};local mine
    for _,r in ipairs(c.rows)do
        if r.userId==userId then mine=r.rank end
        if r.rank<=M.shown then table.insert(top,{rank=r.rank,userId=r.userId,score=r.score,name=name(self,r.userId)})end
    end
    if myScore and myScore>0 then
        local rank=1;for _,r in ipairs(c.rows)do if r.userId~=userId and r.score>myScore then rank+=1 end end
        if rank<=M.size then mine=rank else mine=nil end
    end
    local last=c.rows[M.size]
    return {season=season,rows=top,myRank=mine,cutoff=#c.rows>=M.size and last and last.score or nil,size=#c.rows}
end
return M
