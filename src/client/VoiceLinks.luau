local Players=game:GetService('Players')
local Me=Players.LocalPlayer
local M={links={}}
local function output()
    if M.output and M.output.Parent then return M.output end
    local ok,o=pcall(function()local d=Instance.new('AudioDeviceOutput');d.Name='CommanderVoiceOut';d.Parent=game:GetService('SoundService');return d end)
    M.output=ok and o or nil;return M.output
end
local function mine(input)
    local function check()if not input.Muted then require(script.Parent.VipLock).micOn()end end
    input:GetPropertyChangedSignal('Muted'):Connect(check)
end
local function link(input)
    if M.links[input]or not input:IsA('AudioDeviceInput')or input.Name~='CommanderVoice'then return end
    if input.Player==Me then if not M.mine then M.mine=input;pcall(mine,input)end;return end
    local out=output();if not out then return end
    local ok,wire=pcall(function()local w=Instance.new('Wire');w.SourceInstance=input;w.TargetInstance=out;w.Parent=out;return w end)
    if not ok then return end
    M.links[input]=wire
    input.Destroying:Once(function()local w=M.links[input];M.links[input]=nil;if w then w:Destroy()end end)
end
local function watch(player)
    for _,c in ipairs(player:GetChildren())do link(c)end
    player.ChildAdded:Connect(link)
end
function M.start()
    if M.started then return end;M.started=true
    for _,p in ipairs(Players:GetPlayers())do watch(p)end
    Players.PlayerAdded:Connect(watch)
end
return M
