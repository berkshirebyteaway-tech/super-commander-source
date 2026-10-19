local UI=require(script.Parent.ToyUI)
local L=require(script.Parent.Localization)
local M={};local watching=false
function M.watch()
    if watching then return end;watching=true
    local remote=game.ReplicatedStorage.FrontierNative:WaitForChild('SupplyCelebration')
    local seen={};local order={};local shown
    remote.OnClientEvent:Connect(function(data)
        if type(data)~='table'or seen[data.key]then return end
        seen[data.key]=true;table.insert(order,data.key);if #order>100 then seen[table.remove(order,1)]=nil end
        if game.Players.LocalPlayer:GetAttribute('FrontierRoom')then return end
        if require(script.Parent.LobbyIntro).active then return end
        if shown then shown:Destroy()end
        local gui=UI.make('ScreenGui',game.Players.LocalPlayer.PlayerGui,{Name='SupplyCelebration',ResetOnSpawn=false,DisplayOrder=30,IgnoreGuiInset=false})
        shown=gui;local f=UI.panel(gui,'Notice');f.AnchorPoint=Vector2.new(.5,0);f.Position=UDim2.new(.5,0,0,18);f.Size=UDim2.new(.8,0,0,54)
        local limit=Instance.new('UISizeConstraint');limit.MaxSize=Vector2.new(580,54);limit.Parent=f
        local color=require(script.Parent.SupplyReveal).colors[data.rarity];f:FindFirstChildOfClass('UIStroke').Color=color
        local label=UI.label(f,'Award',data.name..', '..L.text(data.item),14,color);UI.box(label,12,4,math.min(560,workspace.CurrentCamera.ViewportSize.X*.8-24),46);label.AutoLocalize=false
        task.delay(4,function()if shown==gui then shown=nil end;gui:Destroy()end)
    end)
end
return M
