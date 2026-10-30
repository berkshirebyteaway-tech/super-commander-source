local M={};M.__index=M
local function adapter()
    local players=game:GetService('Players')
    return {spawn=task.spawn,wait=task.wait,current=function(p)return p.Parent==players end,
        load=function(p)p:LoadCharacterAsync()end,
        failed=function(_,err)warn('Commander character load failed: '..tostring(err))end}
end
function M.new(dependencies)return setmetatable({a=dependencies or adapter(),pending={},closed=false},M)end
function M:request(player,expected)
    if self.closed or not self.a.current(player)or self.pending[player]then return false end
    if expected and player.Character and player.Character~=expected then return false end
    local previous=player.Character;local token={}
    local function replaced()return player.Character~=nil and player.Character~=previous end
    self.pending[player]=token
    local function current()
        return not self.closed and self.pending[player]==token and self.a.current(player)
    end
    self.a.spawn(function()
        local last
        for attempt=1,3 do
            if not current()or replaced()then break end
            local ok,err=pcall(self.a.load,player)
            if ok then last=nil;break end
            last=err
            if not current()or replaced()then break end
            if attempt<3 then self.a.wait(attempt)end
        end
        if last and current()and not replaced() and self.a.failed then self.a.failed(player,last)end
        if self.pending[player]==token then self.pending[player]=nil end
    end)
    return true
end
function M:forget(player)self.pending[player]=nil end
function M:close()self.closed=true;table.clear(self.pending)end
return M
