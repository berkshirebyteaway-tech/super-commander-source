local Players=game:GetService('Players')
local M={}
local stands=setmetatable({},{__mode='k'})
local Stand={}
Stand.__index=function(t,k)
    if k=='Parent'then local m=rawget(t,'Character');return m and m.Parent and Players or nil end
    return Stand[k]
end
function Stand:GetAttribute(k)local m=rawget(self,'Character');return m and m:GetAttribute(k)end
function Stand:IsA(class)return class=='Player'end
local function stand(model)
    local s=stands[model]
    if not s then
        local id=model:GetAttribute('CommanderUserId');local name=model:GetAttribute('CommanderDisplayName')
        if type(id)~='number'or type(name)~='string'then return nil end
        s=setmetatable({UserId=id,DisplayName=name,Name=name,Character=model,ai=true},Stand);stands[model]=s
    end
    return s
end
function M.isAI(player)return type(player)=='table'and rawget(player,'ai')==true end
function M.list()
    local list=Players:GetPlayers()
    local f=workspace:FindFirstChild('RankedAICommanders')
    if f then for _,m in ipairs(f:GetChildren())do local s=stand(m);if s then table.insert(list,s)end end end
    return list
end
return M
