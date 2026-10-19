local Rules=if script then require(game.ReplicatedStorage.FrontierNative.Core.RankedRules)else require('../core/RankedRules')
local Fresh=if script then require(script.Parent.FreshStore)else require('./FreshStore')
local M={};M.__index=M
function M.new(service)return setmetatable({s=service,pending={},busy={}},M)end
function M:read(id)
    local c=self.s.careers
    if c.store then return Fresh.read(c.store,tostring(id))end
    return c.profiles[id]
end
local function ladder(p,e)return Rules.seasonLadder(p and p.ranked,e.season,e.ladder)end
function M:add(id,season,name)
    local list=self.pending[id]or {};self.pending[id]=list
    list[season..':'..name]={season=season,ladder=name}
end
function M:queue(id,season,name)
    if self.s.local_ then return end;self:add(id,season,name)
    self.s.a.spawn(function()self:drain(id)end)
end
function M:drain(id)
    if self.busy[id]or not self.pending[id]then return end;self.busy[id]=true
    local todo=table.clone(self.pending[id])
    local ok=pcall(function()
        for _=1,3 do
            local before=self:read(id);local wrote={}
            for key,e in pairs(todo)do
                local l=ladder(before,e)
                if not l or (l.placement or 0)>0 then todo[key]=nil;if self.pending[id][key]==e then self.pending[id][key]=nil end
                else self.s:store(e.season,e.ladder):SetAsync(tostring(id),l.rp);wrote[key]=l end
            end
            if not next(wrote)then break end
            local after=self:read(id)
            for key,l in pairs(wrote)do
                local e=todo[key];local current=ladder(after,e)
                if current and current.rp==l.rp and current.games==l.games then
                    todo[key]=nil;if self.pending[id][key]==e then self.pending[id][key]=nil end
                    local c=self.s.boards[e.season..e.ladder];if c then c.at=-math.huge end
                end
            end
            if not next(todo)then break end
        end
    end)
    self.busy[id]=nil
    if not next(self.pending[id])then self.pending[id]=nil end
    return ok
end
function M:retry()for id in pairs(self.pending)do self.s.a.spawn(function()self:drain(id)end)end end
function M:recover(id,p)
    if self.s.local_ then return end
    local r=p and p.ranked;if not r then return end
    local function add(season)
        for _,name in ipairs(Rules.ladders)do local l=Rules.seasonLadder(r,season,name)
            if l and (l.placement or 0)<=0 then self:add(id,season,name)end
        end
    end
    add(r.season);for season in pairs(r.archived or {})do add(season)end
    if self.pending[id]then self.s.a.spawn(function()self:drain(id)end)end
end
return M
