local G=require(script.Parent.Parent.Core.WorldGeometry)
local UI=require(script.Parent.Theme)
local Tween=game:GetService("TweenService")
local M={};M.__index=M
M.SECONDS=2;M.MAX=6
function M.new(world,folder)
    return setmetatable({world=world,folder=folder,live={},count=0},M)
end
function M:show(sender,tile,text,reduced)
    local map=self.world.map;if not map or not tile then return end
    local old=self.live[sender];if old then old:Destroy();self.live[sender]=nil;self.count-=1 end
    if self.count>=M.MAX then return end
    local x,y,z=G.toWorld(tile,map.meta.width,map.meta.height)
    local anchor=Instance.new("Part");anchor.Name="EmojiBubble";anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false
    anchor.Transparency=1;anchor.Size=Vector3.one*.05;anchor.Position=Vector3.new(x,y+.2,z);anchor.Parent=self.folder
    local b=Instance.new("BillboardGui");b.Size=UDim2.fromOffset(46,42);b.SizeOffset=Vector2.new(0,1.2);b.AlwaysOnTop=true;b.MaxDistance=600;b.LightInfluence=0;b.Parent=anchor
    local card=Instance.new("Frame");card.Size=UDim2.fromScale(1,1);card.BackgroundColor3=UI.colors.bg;card.BackgroundTransparency=.12;card.BorderSizePixel=0;card.Parent=b;UI.corner(card,3)
    local s=Instance.new("UIStroke");s.Color=UI.colors.line;s.Thickness=1;s.Parent=card
    local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Size=UDim2.fromScale(1,1);t.Text=text;t.TextSize=24;t.Font=Enum.Font.BuilderSans;t.AutoLocalize=false;t:SetAttribute("LocalizationSkip",true);t.Parent=card
    local scale=Instance.new("UIScale");scale.Scale=reduced and 1 or .6;scale.Parent=card
    if not reduced then Tween:Create(scale,TweenInfo.new(.2,Enum.EasingStyle.Back),{Scale=1}):Play()end
    self.live[sender]=anchor;self.count+=1
    task.delay(M.SECONDS,function()
        if self.live[sender]==anchor then self.live[sender]=nil;self.count-=1 end
        anchor:Destroy()
    end)
end
function M:clear()
    for _,a in pairs(self.live)do a:Destroy()end;self.live={};self.count=0
end
return M
