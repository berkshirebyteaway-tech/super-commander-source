local M={}
local SIDES={'Left','Right','Top','Bottom'}
local GuiService=game:GetService('GuiService')
function M.insets(gui)
    local view=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.zero
    local ok,area=pcall(function()return GuiService:GetInsetArea(gui.ScreenInsets)end)
    if ok and area and area.Max.X>area.Min.X and area.Max.Y>area.Min.Y then
        return math.max(0,area.Min.X),math.max(0,area.Min.Y),math.max(0,view.X-area.Max.X),math.max(0,view.Y-area.Max.Y)
    end
    if gui.ScreenInsets==Enum.ScreenInsets.None then return 0,0,0,0 end
    local size=gui.AbsoluteSize;local w,h=math.max(0,view.X-size.X),math.max(0,view.Y-size.Y)
    return w,h,w,h
end
local insets=M.insets
function M.place(strips,l,t,r,b,scale)
    l,t,r,b=l/scale,t/scale,r/scale,b/scale
    strips.Left.Position=UDim2.fromOffset(-l,-t);strips.Left.Size=UDim2.new(0,l,1,t+b)
    strips.Right.Position=UDim2.new(1,0,0,-t);strips.Right.Size=UDim2.new(0,r,1,t+b)
    strips.Top.Position=UDim2.fromOffset(0,-t);strips.Top.Size=UDim2.new(1,0,0,t)
    strips.Bottom.Position=UDim2.fromScale(0,1);strips.Bottom.Size=UDim2.new(1,0,0,b)
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
    local function update(o)
        local entry=tracked[o];if not entry then return end
        local on=M.isBackdrop(o,gui)
        if on and not entry.strips then
            entry.strips={}
            for _,side in ipairs(SIDES)do
                entry.strips[side]=Instance.new('Frame')
                local s=entry.strips[side];s.Name='SafeAreaBleed'..side;s.BorderSizePixel=0;s.Active=o.Active;s.ZIndex=o.ZIndex;s.Parent=o
            end
            if o.ClipsDescendants then o.ClipsDescendants=false end
        end
        if entry.strips then
            for _,s in pairs(entry.strips)do s.Visible=on end
            if on then
                local l,t,r,b=insets(gui);M.place(entry.strips,l,t,r,b,scale())
                for _,s in pairs(entry.strips)do s.BackgroundColor3=o.BackgroundColor3;s.BackgroundTransparency=o.BackgroundTransparency;s.ZIndex=o.ZIndex end
            end
        end
    end
    local function consider(o)
        if tracked[o]or not o:IsA('GuiObject')or o.Name:match('^SafeAreaBleed')then return end
        if not fullScale(o)then
            if not tracked['size'..tostring(o)]then
                tracked['size'..tostring(o)]=o:GetPropertyChangedSignal('Size'):Connect(function()if fullScale(o)then consider(o)end end)
            end
            return
        end
        local entry={links={}};tracked[o]=entry
        table.insert(entry.links,o:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()update(o)end))
        table.insert(entry.links,o:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()update(o)end))
        table.insert(entry.links,o:GetPropertyChangedSignal('BackgroundTransparency'):Connect(function()update(o)end))
        table.insert(entry.links,o:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()update(o)end))
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
    gui.Destroying:Connect(function()for _,c in ipairs(outside)do c:Disconnect()end end)
    return refresh
end
return M
