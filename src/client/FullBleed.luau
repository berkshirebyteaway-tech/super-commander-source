local M={}
local SIDES={'Left','Right','Top','Bottom'}
local watched=setmetatable({},{__mode='k'})
local GuiService=game:GetService('GuiService')
function M.insets(gui)
    local view=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.zero
    local ok,area=pcall(function()return GuiService:GetInsetArea(gui.ScreenInsets)end)
    if ok and area and area.Max.X>area.Min.X and area.Max.Y>area.Min.Y then
        local okAll,all=pcall(function()return GuiService:GetInsetArea(Enum.ScreenInsets.None)end)
        local x0,y0,x1,y1=0,0,view.X,view.Y
        if okAll and all and all.Max.X>all.Min.X and all.Max.Y>all.Min.Y then x0,y0,x1,y1=all.Min.X,all.Min.Y,all.Max.X,all.Max.Y end
        return math.max(0,area.Min.X-x0),math.max(0,area.Min.Y-y0),math.max(0,x1-area.Max.X),math.max(0,y1-area.Max.Y)
    end
    if gui.ScreenInsets==Enum.ScreenInsets.None then return 0,0,0,0 end
    local size=gui.AbsoluteSize;local w,h=math.max(0,view.X-size.X),math.max(0,view.Y-size.Y)
    return w,h,w,h
end
local insets=M.insets
function M.place(strips,l,t,r,b,scale,rows)
    l,t,r,b=l/scale,t/scale,r/scale,b/scale
    if rows==false then
        strips.Left.Position=UDim2.fromOffset(-l,-t);strips.Left.Size=UDim2.new(0,l,1,t+b)
        strips.Right.Position=UDim2.new(1,0,0,-t);strips.Right.Size=UDim2.new(0,r,1,t+b)
        strips.Top.Position=UDim2.fromOffset(0,-t);strips.Top.Size=UDim2.new(1,0,0,t)
        strips.Bottom.Position=UDim2.fromScale(0,1);strips.Bottom.Size=UDim2.new(1,0,0,b)
    else
        strips.Top.Position=UDim2.fromOffset(-l,-t);strips.Top.Size=UDim2.new(1,l+r,0,t)
        strips.Bottom.Position=UDim2.new(0,-l,1,0);strips.Bottom.Size=UDim2.new(1,l+r,0,b)
        strips.Left.Position=UDim2.fromOffset(-l,0);strips.Left.Size=UDim2.new(0,l,1,0)
        strips.Right.Position=UDim2.fromScale(1,0);strips.Right.Size=UDim2.new(0,r,1,0)
    end
end
local function seqAt(seq,x,lerp)
    local k=seq.Keypoints
    for i=1,#k-1 do if x<=k[i+1].Time then local a,b=k[i],k[i+1];return lerp(a.Value,b.Value,(x-a.Time)/math.max(1e-6,b.Time-a.Time))end end
    return k[#k].Value
end
local function num(a,b,f)return a+(b-a)*f end
local function col(a,b,f)return a:Lerp(b,f)end
function M.gradientSides(g)
    local rot=math.round(g.Rotation)%360
    if rot==90 then return true,{Top=0,Bottom=1}elseif rot==270 then return true,{Top=1,Bottom=0}
    elseif rot==0 then return false,{Left=0,Right=1}elseif rot==180 then return false,{Left=1,Right=0}end
    return nil
end
function M.gradientAt(o,g,x)
    local c=seqAt(g.Color,x,col);local a=seqAt(g.Transparency,x,num);local base=o.BackgroundColor3
    return Color3.new(base.R*c.R,base.G*c.G,base.B*c.B),1-(1-o.BackgroundTransparency)*(1-a)
end
function M.isBackdrop(o,gui)
    if not(o:IsA('Frame')or o:IsA('TextButton')or o:IsA('ImageButton')or o:IsA('ImageLabel'))then return false end
    if o.BackgroundTransparency>=1 or o:FindFirstChildOfClass('UIGradient')then return false end
    local a,b=o.AbsolutePosition-gui.AbsolutePosition,o.AbsoluteSize-gui.AbsoluteSize
    return math.abs(a.X)<=2 and math.abs(a.Y)<=2 and math.abs(b.X)<=2 and math.abs(b.Y)<=2
end
local function fullScale(o)
    local s=o.Size
    return s.X.Scale==1 and s.Y.Scale==1 and s.X.Offset==0 and s.Y.Offset==0
end
function M.watch(gui)
    if gui:GetAttribute('FullBleed')then return end
    gui:SetAttribute('FullBleed',true)
    pcall(function()gui.ClipToDeviceSafeArea=false end)
    local tracked={}
    local function scale()return gui:GetAttribute('UIScale')or 1 end
    local function stripZ(o)return gui.ZIndexBehavior==Enum.ZIndexBehavior.Sibling and -100 or o.ZIndex end
    local function update(o)
        local entry=tracked[o];if not entry then return end
        local l,t,r,b=0,0,0,0;local on=false
        if entry.edge then
            local L,T,R,B=insets(gui)
            local a,z=o.AbsolutePosition-gui.AbsolutePosition,o.AbsolutePosition+o.AbsoluteSize-gui.AbsolutePosition-gui.AbsoluteSize
            if o.BackgroundTransparency<1 and o.AbsoluteSize.X>0 and o.AbsoluteSize.Y>0 then
                l=math.abs(a.X)<=2 and L or 0;t=math.abs(a.Y)<=2 and T or 0;r=math.abs(z.X)<=2 and R or 0;b=math.abs(z.Y)<=2 and B or 0
            end
            on=l+t+r+b>0
        elseif M.isBackdrop(o,gui)then l,t,r,b=insets(gui);on=true end
        local grad=o:FindFirstChildOfClass('UIGradient');local rows,at=true,nil
        if grad and entry.edge then rows,at=M.gradientSides(grad);if rows==nil then on=false end end
        if on and not entry.strips then
            entry.strips={}
            for _,side in ipairs(SIDES)do
                entry.strips[side]=Instance.new('Frame')
                local s=entry.strips[side];s.Name='SafeAreaBleed'..side;s.BorderSizePixel=0;s.Active=o.Active;s.ZIndex=stripZ(o);s.Parent=o
            end
            if o.ClipsDescendants then o.ClipsDescendants=false end
        end
        if entry.strips then
            for _,s in pairs(entry.strips)do s.Visible=on end
            if on then
                M.place(entry.strips,l,t,r,b,scale(),rows)
                for side,s in pairs(entry.strips)do
                    s.BackgroundColor3=o.BackgroundColor3;s.BackgroundTransparency=o.BackgroundTransparency;s.ZIndex=stripZ(o)
                    local copy=s:FindFirstChildOfClass('UIGradient')
                    if grad and at and at[side]then
                        s.BackgroundColor3,s.BackgroundTransparency=M.gradientAt(o,grad,at[side]);if copy then copy:Destroy()end
                    elseif grad then
                        copy=copy or Instance.new('UIGradient');copy.Color=grad.Color;copy.Transparency=grad.Transparency;copy.Rotation=grad.Rotation;copy.Offset=grad.Offset;copy.Parent=s
                    end
                end
            end
        end
    end
    local function consider(o)
        if tracked[o]or not o:IsA('GuiObject')or o.Name:match('^SafeAreaBleed')then return end
        local edge=o:GetAttribute('FullBleedEdge')==true
        if not edge and not fullScale(o)then
            if not tracked['size'..tostring(o)]then
                tracked['size'..tostring(o)]=o:GetPropertyChangedSignal('Size'):Connect(function()if fullScale(o)then consider(o)end end)
            end
            return
        end
        local entry={links={},edge=edge};tracked[o]=entry
        table.insert(entry.links,o:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()update(o)end))
        table.insert(entry.links,o:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()update(o)end))
        table.insert(entry.links,o:GetPropertyChangedSignal('BackgroundTransparency'):Connect(function()update(o)end))
        table.insert(entry.links,o:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()update(o)end))
        if edge then
            local g=o:FindFirstChildOfClass('UIGradient')
            if g then for _,p in ipairs({'Transparency','Color','Rotation'})do table.insert(entry.links,g:GetPropertyChangedSignal(p):Connect(function()update(o)end))end end
        end
        table.insert(entry.links,o.AncestryChanged:Connect(function()
            if not o:IsDescendantOf(gui)then for _,c in ipairs(entry.links)do c:Disconnect()end;tracked[o]=nil end
        end))
        update(o)
    end
    local function refresh()for o in pairs(tracked)do if typeof(o)=='Instance'then update(o)end end end
    for _,o in ipairs(gui:GetDescendants())do consider(o)end
    gui.DescendantAdded:Connect(consider)
    gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(refresh)
    gui:GetPropertyChangedSignal('AbsolutePosition'):Connect(refresh)
    gui:GetAttributeChangedSignal('UIScale'):Connect(refresh)
    gui:GetPropertyChangedSignal('ScreenInsets'):Connect(refresh)
    local outside={}
    pcall(function()table.insert(outside,GuiService:GetPropertyChangedSignal('TopbarInset'):Connect(refresh))end)
    if workspace.CurrentCamera then table.insert(outside,workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(refresh))end
    gui.Destroying:Connect(function()for _,c in ipairs(outside)do c:Disconnect()end;watched[gui]=nil end)
    watched[gui]=consider
    return refresh
end
function M.edge(o)
    o:SetAttribute('FullBleedEdge',true)
    local gui=o:FindFirstAncestorOfClass('ScreenGui');local consider=gui and watched[gui]
    if consider then consider(o)end
    return o
end
return M
