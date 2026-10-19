local Players=if script then game:GetService('Players')else nil
local Run=if script then game:GetService('RunService')else nil
local Daily=if script then require(game.ReplicatedStorage.FrontierNative.Core.DailyOperation)else require('../core/DailyOperation')
local Flight=if script then require(script.Parent.ReadFlight)else require('./ReadFlight')
local M={};M.__index=M
M.size=20
function M.new()
    local self=setmetatable({players=Players,cache={},names={},memory={},localMode=Run:IsStudio()or game.GameId==0},M)
    return self
end
function M:store(day,map)
    local scope=day..':'..(map or Daily.of(day).map)
    if self.localMode then
        local mem=self.memory[scope]or {};self.memory[scope]=mem
        return {UpdateAsync=function(_,k,fn)local v=fn(mem[k]);if v then mem[k]=v end;return v end,
            GetSortedAsync=function()local list={};for k,v in pairs(mem)do table.insert(list,{key=k,value=v})end;table.sort(list,function(a,b)return a.value>b.value end)
                return {GetCurrentPage=function()return {table.unpack(list,1,math.min(#list,M.size))}end}end}
    end
    return game:GetService('DataStoreService'):GetOrderedDataStore('SuperCommanderDaily_v1',scope)
end
function M:submit(userId,day,score,map)
    if type(score)~='number'or score~=score or score<0 or score>=math.huge then return false end
    local ok=pcall(function()self:store(day,type(map)=='string'and map or nil):UpdateAsync(tostring(userId),function(old)
        if type(old)=='number'and old>=score then return nil end;return math.floor(score)end)end)
    if ok then
        self.generation=(self.generation or 0)+1;self.retryAt=nil
        local c=self.cache[day];if c then c.at=-math.huge end
    end
    return ok
end
local function name(self,id)
    if self.names[id]then return self.names[id]end
    local p=self.players:GetPlayerByUserId(id)
    local n=p and p.DisplayName
    if not n then local ok,v=pcall(function()return self.players:GetNameFromUserIdAsync(id)end);if not ok or type(v)~='string'then return '#'..id end;n=v end
    self.names[id]=n;return n
end
function M:board(userId,now)
    local day=Daily.day(now);local c=self.cache[day]
    if not(c and now-c.at<=60)and now>=(self.retryAt or -math.huge)then
        self.readFlights=self.readFlights or {}
        if not(self.readFlights[day]and c)then
            local ok,result=Flight.run(self.readFlights,day,self.readWait,function()
                local good,value=pcall(self.readBoard,self,userId,now)
                if good and value and not value.unavailable then return value end
                self.retryAt=now+5;error('daily-board-unavailable')
            end)
            if not ok or not result then self.retryAt=now+5 end
        end
    end
    c=self.cache[day];local rows=c and c.rows or {};local mine
    for _,r in ipairs(rows)do if r.userId==userId then mine=r.rank end end
    return {day=day,rows=rows,myRank=mine,unavailable=not c or now-c.at>60 or nil}
end
function M:readBoard(userId,now)
    local day=Daily.day(now)
    for _=1,3 do
        local c=self.cache[day]
        if c and now-c.at<=60 then return {day=day,rows=c.rows}end
        local generation=self.generation or 0
        local ok,page=pcall(function()return self:store(day):GetSortedAsync(false,M.size):GetCurrentPage()end)
        if not ok then return {day=day,rows={},unavailable=true}end
        local rows={}
        for i,entry in ipairs(page)do local id=tonumber(entry.key);if id then table.insert(rows,{rank=i,userId=id,name=name(self,id),score=entry.value,label=Daily.label(entry.value)})end end
        if generation~=(self.generation or 0)then continue end
        self.cache={[day]={at=now,rows=rows}}
        local kept={};for _,r in ipairs(rows)do if self.names[r.userId]then kept[r.userId]=self.names[r.userId]end end;self.names=kept
        return {day=day,rows=rows}
    end
    return {day=day,unavailable=true}
end

return M
