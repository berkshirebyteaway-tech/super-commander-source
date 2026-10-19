local Players=game:GetService("Players")
local M={}
M.step=.01
function M.target(c)
    local base=c:GetAttribute("ToyfrontBaseScale");if type(base)~="number"or base<=0 then return nil end
    local growth=c:GetAttribute("ToyfrontGrowth");if type(growth)~="number"or growth<=0 then growth=1 end
    return base*growth,base
end
function M.apply(c)
    if not c.Parent or not c:FindFirstChild("HumanoidRootPart")then return end
    local want,base=M.target(c);if not want then return end
    local ok,now=pcall(function()return c:GetScale()end);if not ok then return end
    if math.abs(want-now)<1e-4 or want~=base and math.abs(want-now)<M.step*base then return end
    pcall(function()c:ScaleTo(want)end)
end
function M.start()
    if M.started then return end;M.started=true
    local function character(c)
        c:GetAttributeChangedSignal("ToyfrontGrowth"):Connect(function()M.apply(c)end)
        c:GetAttributeChangedSignal("ToyfrontBaseScale"):Connect(function()M.apply(c)end)
        task.spawn(function()c:WaitForChild("HumanoidRootPart",10);M.apply(c)end)
    end
    local function watch(player)
        player.CharacterAdded:Connect(character)
        if player.Character then character(player.Character)end
    end
    for _,p in ipairs(Players:GetPlayers())do watch(p)end
    Players.PlayerAdded:Connect(watch)
end
return M
