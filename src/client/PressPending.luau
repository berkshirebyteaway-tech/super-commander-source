local RunService=game:GetService('RunService')
local M={}
local SHOW,LIMIT=.2,15
local active,serial,beat=nil,0,nil

local function path(b)
    local out,o={},b
    while o and not(o:IsA('LayerCollector')or o.ClassName=='ScreenGui')do
        local p=o.Parent;if not p then return nil end
        local n=0;for _,c in ipairs(p:GetChildren())do if c.Name==o.Name then n+=1 end;if c==o then break end end
        table.insert(out,1,{o.Name,n});o=p
    end
    return o and out,o
end
local function find(root,list)
    local o=root
    for _,s in ipairs(list)do
        local n,hit=0,nil
        for _,c in ipairs(o:GetChildren())do if c.Name==s[1]then n+=1;if n==s[2]then hit=c;break end end end
        if not hit then return nil end;o=hit
    end
    return o
end
local function apply(b,shown)
    if b:GetAttribute('PendingWas')==nil then
        b:SetAttribute('PendingWas',b:GetAttribute('Enabled')~=false)
        b:SetAttribute('PendingAuto',b.AutoButtonColor);if b:IsA('TextButton')then b:SetAttribute('PendingText',b.TextTransparency)end
        b.Active=false;b.AutoButtonColor=false;if b:IsA('TextButton')then b.TextTransparency=.5 end;b:SetAttribute('Enabled',false)
    end
    local veil=b:FindFirstChild('PressPending')
    if not veil then
        veil=Instance.new('Frame');veil.Name='PressPending';veil.BorderSizePixel=0;veil.Active=false;veil.ZIndex=60
        veil.Size=UDim2.fromScale(1,1);veil.BackgroundColor3=b.BackgroundColor3;veil.BackgroundTransparency=1;veil:SetAttribute('AllowOverlap',true)
        local corner=b:FindFirstChildOfClass('UICorner');if corner then corner:Clone().Parent=veil end
        local pad=b:FindFirstChildOfClass('UIPadding')
        if pad then veil.Position=UDim2.fromOffset(-pad.PaddingLeft.Offset,-pad.PaddingTop.Offset);veil.Size=UDim2.new(1,pad.PaddingLeft.Offset+pad.PaddingRight.Offset,1,pad.PaddingTop.Offset+pad.PaddingBottom.Offset)end
        local ring=Instance.new('Frame');ring.Name='Ring';ring.BackgroundTransparency=1;ring.AnchorPoint=Vector2.new(.5,.5);ring.Position=UDim2.fromScale(.5,.5);ring.Size=UDim2.fromScale(.42,.42);ring.ZIndex=61;ring.Parent=veil
        local aspect=Instance.new('UIAspectRatioConstraint');aspect.DominantAxis=Enum.DominantAxis.Height;aspect.Parent=ring
        local cap=Instance.new('UISizeConstraint');cap.MaxSize=Vector2.new(20,20);cap.Parent=ring
        local round=Instance.new('UICorner');round.CornerRadius=UDim.new(1,0);round.Parent=ring
        local line=Instance.new('UIStroke');line.Thickness=2;line.Color=b:IsA('TextButton')and b.TextColor3 or Color3.new(1,1,1);line.Parent=ring
        local fade=Instance.new('UIGradient');fade.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.6,.2),NumberSequenceKeypoint.new(1,1)});fade.Parent=line
        veil.Parent=b
    end
    veil.BackgroundTransparency=shown and b.BackgroundTransparency or 1;veil.Ring.Visible=shown==true
end
local function clear(b)
    local veil=b:FindFirstChild('PressPending');if veil then veil:Destroy()end
    local was=b:GetAttribute('PendingWas');if was==nil then return end
    local auto,text=b:GetAttribute('PendingAuto'),b:GetAttribute('PendingText')
    b:SetAttribute('PendingWas',nil);b:SetAttribute('PendingAuto',nil);b:SetAttribute('PendingText',nil)
    b.Active=was;b.AutoButtonColor=was and auto~=false;if b:IsA('TextButton')then b.TextTransparency=was and(text or 0)or .5 end;b:SetAttribute('Enabled',was)
end
function M.restore()
    local a=active;if not a then return end
    if a.button and a.button.Parent and a.button:IsDescendantOf(a.root)then return end
    if not a.root.Parent then M.finish(a.token);return end
    a.button=find(a.root,a.path);if a.button then apply(a.button,a.shown)end
end
function M.begin()
    local c=M.current;if not c or os.clock()-c.at>.05 or not c.button.Parent then return nil end
    local list,root=path(c.button);if not list then return nil end
    if active then M.finish(active.token)end
    serial+=1;local token=serial
    active={token=token,path=list,root=root,button=c.button,shown=false}
    apply(c.button,false)
    task.delay(SHOW,function()local a=active;if a and a.token==token then a.shown=true;M.restore();if a.button and a.button.Parent then apply(a.button,true)end end end)
    task.delay(LIMIT,function()M.finish(token)end)
    if not beat then
        local angle=0
        beat=RunService.Heartbeat:Connect(function(dt)
            local a=active;if not a then return end
            M.restore();angle=(angle+dt*360)%360
            local veil=a.button and a.button:FindFirstChild('PressPending');if veil and a.shown then veil.Ring.Rotation=angle end
        end)
    end
    return token
end
function M.finish(token)
    local a=active;if not token or not a or a.token~=token then return end
    active=nil;if beat then beat:Disconnect();beat=nil end
    if a.button and a.button.Parent then clear(a.button)end
end
function M.pending()return active~=nil end
return M
