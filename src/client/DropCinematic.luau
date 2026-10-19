local Intro=require(script.Parent.Parent.Core.DropIntro)
local Audio=require(script.Parent.ToyAudio)
local M={};M.__index=M
function M.new(parent)
    local self=setmetatable({lines={}},M)
    local gui=Instance.new('ScreenGui');gui.Name='DropCinematic';gui.IgnoreGuiInset=true;gui.ScreenInsets=Enum.ScreenInsets.None;gui.ClipToDeviceSafeArea=false;gui.ResetOnSpawn=false;gui.DisplayOrder=7;gui.Enabled=false;gui.Parent=parent:FindFirstAncestorOfClass('PlayerGui')
    self.gui=gui
    for _,name in ipairs({'Top','Bottom'})do
        local f=Instance.new('Frame');f.Name=name;f.BackgroundColor3=Color3.fromRGB(6,10,16);f.BorderSizePixel=0;f.ZIndex=2;f.Parent=gui;self[name]=f
    end
    local promise=Instance.new('TextLabel');promise.Name='EqualStart';promise.AnchorPoint=Vector2.new(.5,1);promise.Position=UDim2.new(.5,0,1,-6)
    promise.Size=UDim2.new(.9,0,0,22);promise.BackgroundTransparency=1;promise.Font=Enum.Font.BuilderSansMedium;promise.TextSize=17
    promise.TextColor3=Color3.fromRGB(214,238,248);promise.TextTransparency=1;promise.Text='모든 지휘관이 같은 조건에서 시작해요.';promise.ZIndex=3;promise.Parent=gui;self.promise=promise
    require(script.Parent.Localization).bind(gui)
    for i=1,10 do
        local f=Instance.new('Frame');f.Name='Slipstream'..i;f.AnchorPoint=Vector2.new(.5,.5);f.BorderSizePixel=0;f.BackgroundColor3=Color3.fromRGB(196,232,246);f.Rotation=-24;f.Parent=gui
        local g=Instance.new('UIGradient');g.Rotation=90;g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,.3),NumberSequenceKeypoint.new(1,1)});g.Parent=f
        self.lines[i]=f
    end
    return self
end
function M:clear()
    self.gui.Enabled=false;self.started=nil;self.revealed=nil
    if self.backdrop then self.backdrop:Destroy();self.backdrop=nil;self.sky=nil end
    if self.touchGui and self.touchGui.Parent then self.touchGui.Enabled=self.touchEnabled end
    self.touchGui=nil;self.touchEnabled=nil
    Audio.stop('dropExit');Audio.stop('dropReveal')
end
function M:skyFrame(camera,shot,obscured)
    if not shot.active or obscured then
        if self.backdrop then self.backdrop:Destroy();self.backdrop=nil;self.sky=nil end
        return
    end
    if not self.backdrop then
        local p=Instance.new('Part');p.Name='DropPortraitSky';p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Transparency=1;p.Size=Vector3.new(4000,2600,.1);p.Parent=workspace;self.backdrop=p
        local g=Instance.new('SurfaceGui');g.Face=Enum.NormalId.Back;g.CanvasSize=Vector2.new(1200,800);g.LightInfluence=0;g.Parent=p
        local f=Instance.new('Frame');f.Size=UDim2.fromScale(1,1);f.BorderSizePixel=0;f.BackgroundColor3=Color3.new(1,1,1);f.Parent=g;self.sky=f
        local gradient=Instance.new('UIGradient');gradient.Rotation=90
        gradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(10,20,42)),ColorSequenceKeypoint.new(.48,Color3.fromRGB(43,92,126)),ColorSequenceKeypoint.new(.76,Color3.fromRGB(115,165,182)),ColorSequenceKeypoint.new(1,Color3.fromRGB(226,216,180))});gradient.Parent=f
    end
    self.backdrop.CFrame=camera*CFrame.new(0,0,-900)
    self.sky.BackgroundTransparency=math.clamp(shot.reveal*2,0,1)
end
function M:frame(elapsed,reduced,obscured,paused)
    local shot=Intro.sample(elapsed,reduced)
    self.gui.Enabled=shot.active and not obscured
    if shot.active then
        if not self.started then
            self.started=true
            if elapsed<.7 and not paused and not obscured then Audio.play('dropExit',.65)end
        end
        if elapsed>=1.05 and not self.revealed then self.revealed=true;if not paused and not obscured then Audio.play('dropReveal',.5)end end
        if not self.touchGui then
            local g=self.gui.Parent:FindFirstChild('TouchGui')
            if g and g:IsA('ScreenGui')then self.touchGui=g;self.touchEnabled=g.Enabled;g.Enabled=false end
        end
        if self.touchGui and self.touchGui.Enabled then self.touchEnabled=true;self.touchGui.Enabled=false end
        self.Top.Size=UDim2.fromScale(1,shot.bars)
        self.Bottom.Size=UDim2.fromScale(1,shot.bars);self.Bottom.Position=UDim2.fromScale(0,1-shot.bars)
        local show=math.clamp((elapsed-.15)/.3,0,1)*math.clamp(1-shot.reveal*1.6,0,1)
        self.promise.TextTransparency=1-show;self.promise.Visible=show>.01
        for i,f in ipairs(self.lines)do
            local side=i%2==0 and 1 or -1
            local y=(i*.173+elapsed*.8)%1
            f.Position=UDim2.fromScale(.5+side*(.35+(i%3)*.045),y)
            f.Size=UDim2.new(0,1,0,32+(i%4)*13);f.BackgroundTransparency=1-shot.streaks*.32
        end
    elseif self.touchGui then
        if self.touchGui.Parent then self.touchGui.Enabled=self.touchEnabled end
        self.touchGui=nil;self.touchEnabled=nil
    end
    return shot
end
function M.camera(shot,avatarCF,headPosition,chase,focus,aspect,reduced,memory,dt)
    local distance=math.max(10,10/math.max(.5,math.min(1,aspect)))
    local front=avatarCF.LookVector
    local right=avatarCF.RightVector
    local r=shot.reveal
    if r==1 then return chase,focus end
    local offset=front*distance+right*distance*(.36+.22*(1-shot.pose))+Vector3.new(0,2,0)
    if reduced then offset=Vector3.new(distance*.45,5,-distance)end
    local portrait=CFrame.lookAt(Vector3.zero,offset.Unit)
    local center=headPosition
    if memory and not reduced then
        local delta=math.min(dt or 1/60,.1)
        memory.center=memory.center and memory.center:Lerp(headPosition,1-math.exp(-delta*8))or headPosition
        local lag=memory.center-headPosition;if lag.Magnitude>2 then lag=lag.Unit*2 end
        center=headPosition+lag*(1-r)^2
        memory.orbit=memory.orbit and memory.orbit:Lerp(portrait,1-math.exp(-delta*7))or portrait
        portrait=memory.orbit
    end
    local chaseOffset=chase.Position-focus
    local orbit=portrait:Lerp(CFrame.lookAt(Vector3.zero,chaseOffset.Unit),r)
    local radius=offset.Magnitude+(chaseOffset.Magnitude-offset.Magnitude)*r*r
    local target=center:Lerp(focus,r)
    local pos=target+orbit.LookVector*radius
    return CFrame.lookAt(pos,target),target
end
return M
