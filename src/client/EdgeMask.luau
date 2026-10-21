local M={}
local function cornerRadius(p,k)
    local c=p:FindFirstChildOfClass('UICorner');if not c then return 0 end
    local size=p.AbsoluteSize
    local r=c.CornerRadius.Offset*k+c.CornerRadius.Scale*math.min(size.X,size.Y)
    return math.min(r,math.min(size.X,size.Y)/2)
end
local function off(g,own)if own then g.Enabled=false else g.Transparency=NumberSequence.new(0)end end
local function update(strip,g,own)
    local p=strip.Parent
    if not(p and p:IsA('GuiObject'))then off(g,own);return end
    local a,b=strip.AbsolutePosition,strip.AbsoluteSize
    local pa,pb=p.AbsolutePosition,p.AbsoluteSize
    if b.X<=0 or b.Y<=0 then return end
    local c=p:FindFirstChildOfClass('UICorner')
    local key=string.format('%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%s',a.X-pa.X,a.Y-pa.Y,b.X,b.Y,pb.X,pb.Y,c and tostring(c.CornerRadius)or'-')
    if strip:GetAttribute('EdgeMaskKey')==key then return end;strip:SetAttribute('EdgeMaskKey',key)
    local vertical=b.Y>=b.X
    local thin=vertical and strip.Size.X or strip.Size.Y
    local k=thin.Offset>0 and thin.Scale==0 and(vertical and b.X or b.Y)/thin.Offset or 1
    local r=cornerRadius(p,k)
    local gap
    if vertical then gap=math.min(a.X-pa.X,pa.X+pb.X-(a.X+b.X))else gap=math.min(a.Y-pa.Y,pa.Y+pb.Y-(a.Y+b.Y))end
    gap=math.max(0,gap)
    local reach=gap<r and r-math.sqrt(math.max(0,r*r-(r-gap)^2))or 0
    local len=vertical and b.Y or b.X
    local head=vertical and reach-(a.Y-pa.Y)or reach-(a.X-pa.X)
    local tail=vertical and reach-(pa.Y+pb.Y-(a.Y+b.Y))or reach-(pa.X+pb.X-(a.X+b.X))
    head=math.clamp(head/len,0,.45);tail=math.clamp(tail/len,0,.45)
    if reach<.5 or(head==0 and tail==0)then off(g,own);return end
    local keys={}
    if head>0 then table.insert(keys,NumberSequenceKeypoint.new(0,1));table.insert(keys,NumberSequenceKeypoint.new(head,1));table.insert(keys,NumberSequenceKeypoint.new(head+.002,0))
    else table.insert(keys,NumberSequenceKeypoint.new(0,0))end
    if tail>0 then table.insert(keys,NumberSequenceKeypoint.new(1-tail-.002,0));table.insert(keys,NumberSequenceKeypoint.new(1-tail,1));table.insert(keys,NumberSequenceKeypoint.new(1,1))
    else table.insert(keys,NumberSequenceKeypoint.new(1,0))end
    g.Rotation=vertical and 90 or 0;g.Transparency=NumberSequence.new(keys);g.Enabled=true
end
function M.fit(strip)
    if strip:GetAttribute('EdgeMask')then return strip end
    strip:SetAttribute('EdgeMask',true)
    local g=strip:FindFirstChildOfClass('UIGradient');local own=g==nil
    if own then g=Instance.new('UIGradient');g.Name='EdgeMask';g.Parent=strip end
    local function run()update(strip,g,own)end
    strip:GetPropertyChangedSignal('AbsoluteSize'):Connect(run)
    strip:GetPropertyChangedSignal('AbsolutePosition'):Connect(run)
    strip:GetPropertyChangedSignal('Parent'):Connect(run)
    run();task.defer(run)
    return strip
end
return M
