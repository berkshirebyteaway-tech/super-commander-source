local Run=game:GetService('RunService')
local M={}
local function seq(...)local keys={};local list={...};for i,c in ipairs(list)do table.insert(keys,ColorSequenceKeypoint.new((i-1)/(#list-1),c))end;return ColorSequence.new(keys)end
local rgb=Color3.fromRGB
M.tiers={
    {color=rgb(196,204,214),font=Enum.Font.BuilderSansMedium},
    {color=rgb(110,180,255),font=Enum.Font.BuilderSansBold},
    {color=rgb(178,140,255),font=Enum.Font.BuilderSansBold,gradient=seq(rgb(214,190,255),rgb(150,104,246)),edge=rgb(44,22,86)},
    {color=rgb(245,196,81),font=Enum.Font.BuilderSansBold,gradient=seq(rgb(255,240,176),rgb(245,196,81),rgb(214,140,36)),edge=rgb(72,44,6),motion='sheen'},
    {color=rgb(157,242,235),font=Enum.Font.BuilderSansExtraBold,gradient=seq(rgb(80,240,220),rgb(120,200,255),rgb(176,128,255),rgb(236,110,230),rgb(80,240,220)),edge=rgb(24,12,48),motion='flow'},
}
function M.color(tier)local t=M.tiers[tier or 0];return t and t.color or nil end
local live=setmetatable({},{__mode='k'})
local clock=0
local connection
local function step(dt)
    clock+=dt
    local s=(clock%4)/4;local sheen=Vector2.new(0,s<.4 and math.sin(s/.4*math.pi)*.18 or 0)
    local flow=Vector2.new(math.sin(clock*.9)*.35,0)
    for g,motion in pairs(live)do
        if not g.Parent then live[g]=nil
        else local offset=motion=='flow'and flow or sheen;if g.Offset~=offset then g.Offset=offset end end
    end
    if next(live)==nil and connection then connection:Disconnect();connection=nil end
end
local function watch(g,motion)
    live[g]=motion
    if not connection then connection=Run.Heartbeat:Connect(step)end
end
function M.apply(label,tier,muted)
    local t=M.tiers[tier or 0]
    local g=label:FindFirstChild('TierGradient');local s=label:FindFirstChild('TierEdge')
    if not t then
        if g then live[g]=nil;g:Destroy()end;if s then s:Destroy()end
        label.Font=Enum.Font.BuilderSansMedium;if muted then label.TextColor3=muted end;return
    end
    label.Font=t.font
    if t.gradient then
        label.TextColor3=Color3.new(1,1,1)
        if not g then g=Instance.new('UIGradient');g.Name='TierGradient';g.Parent=label end
        g.Color=t.gradient;g.Rotation=t.motion=='sheen'and 90 or 0;g.Offset=Vector2.zero
        if t.motion then watch(g,t.motion)else live[g]=nil end
    else
        label.TextColor3=t.color
        if g then live[g]=nil;g:Destroy()end
    end
    if t.edge then
        if not s then s=Instance.new('UIStroke');s.Name='TierEdge';s.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual;s.Parent=label end
        s.Color=t.edge;s.Thickness=1;s.Transparency=.2
    elseif s then s:Destroy()end
end
return M
