local UI=require(script.Parent.Theme)
local C=UI.colors
local M={}
M.colors={
    panel=Color3.fromRGB(13,18,25),chip=Color3.fromRGB(21,28,38),cell=Color3.fromRGB(26,34,46),line=Color3.fromRGB(42,54,70),
    rateBg=Color3.fromRGB(14,44,42),goldBg=Color3.fromRGB(38,31,14),priceBg=Color3.fromRGB(46,37,14),priceOff=Color3.fromRGB(28,34,43),
    fillA=Color3.fromRGB(32,178,163),fillB=Color3.fromRGB(86,236,220),low=Color3.fromRGB(255,166,64),lock=Color3.fromRGB(8,11,15),
}
M.RADIUS=6
local function find(o,class,name)
    for _,c in ipairs(o:GetChildren())do if c:IsA(class)and(not name or c.Name==name)then return c end end
end
function M.round(o,r)
    local c=find(o,'UICorner')or Instance.new('UICorner');c.CornerRadius=UDim.new(0,r or M.RADIUS);c.Parent=o;return c
end
function M.line(o,color,thickness,transparency)
    local s=find(o,'UIStroke')or Instance.new('UIStroke');s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    s.Color=color or M.colors.line;s.Thickness=thickness or 1;s.Transparency=transparency or 0;s.Enabled=true;s.Parent=o;return s
end
function M.chip(o,tone,r)
    o.BackgroundColor3=tone=='rate'and M.colors.rateBg or tone=='gold'and M.colors.goldBg or M.colors.chip
    o.BackgroundTransparency=.06;o.BorderSizePixel=0;M.round(o,r)
    local s=M.line(o,tone=='rate'and C.accent or tone=='gold'and C.gold or M.colors.line,1,tone and .35 or 0)
    return s
end
function M.fill(frame)
    local g=find(frame,'UIGradient','HudFill')
    if not g then g=Instance.new('UIGradient');g.Name='HudFill';g.Parent=frame end
    g.Color=ColorSequence.new(M.colors.fillA,M.colors.fillB);g.Enabled=true;return g
end
function M.pulse(stroke,color)
    if not stroke then return end
    local base=stroke.Color;stroke.Thickness=2;stroke.Transparency=0;if color then stroke.Color=color end
    game:GetService('TweenService'):Create(stroke,TweenInfo.new(.35,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Thickness=1}):Play()
    if color then task.delay(.35,function()stroke.Color=base end)end
end
return M
