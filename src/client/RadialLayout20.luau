local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local Theme=require(script.Parent.Theme)
local G=require(script.Parent.Parent.Core.WorldGeometry)
local Input=require(script.Parent.Parent.Core.CommandInteraction)
local Commands=require(script.Parent.Parent.Core.CommandPresentation)
local M={};M.__index=M
M.PAN=.18
M.SETTLE=.2
M.FADE=.1
local K
local function kit()K=K or require(script.Parent.Kit20);return K end
function M.new(o)
    local self=setmetatable({o=o},M)
    for _,b in ipairs({o.confirm,o.alliance,o.gold,o.troops,o.transport,o.rockets})do
        b.Activated:Connect(function()if b:GetAttribute('Enabled')==false then self:why(b)end end)
    end
    return self
end
function M:why(b)
    local reason=b:GetAttribute('Why20')
    if type(reason)=='string'and reason~=''then self.o.notify(reason,true)end
end
function M:press(b,run)
    if b and b:GetAttribute('Enabled')==false then self:why(b);return end
    if run then run()end
end
function M:fill(state,f,context,route)
    local o=self.o;local live=not state.paused
    local function set(b,on,reason)
        Theme.enabled(b,on and live);b.Active=true
        b:SetAttribute('Why20',live and not on and reason or nil)
    end
    local ally=f~=nil and f.allied
    o.sheet:SetAttribute('Ring20',f and 'nation'or 'land')
    if ally then
        local wait=(f.donationAvailableIn or 0)>0
        for _,b in ipairs({o.gold,o.troops})do
            b.Active=true;b:SetAttribute('Why20',live and b:GetAttribute('Enabled')==false and(wait and '지원 대기'or '지금은 지원할 수 없어요')or nil)
        end
        o.rockets.Visible=false
    else
        o.confirm.Visible=true
        set(o.confirm,(context.attack or context.transport and route=='transport')==true,context.transportFull and route=='transport'and '수송선 3/3'or '닿는 길이 없어요')
        o.rockets.Visible=true
        set(o.rockets,context.rockets==true,Commands.prerequisite(state,'AtomBomb')and Commands.prerequisite(state,'HydrogenBomb')and Commands.prerequisite(state,'MIRV')or '발사대 필요')
    end
    o.transport.Visible=true
    set(o.transport,context.transport==true and not ally,ally and '동맹에게는 수송할 수 없어요'or context.transportFull and '수송선 3/3'
        or Commands.prerequisite(state,'TransportShip')or '닿는 해안이 없어요')
    o.transport:SetAttribute('Route20',not ally and route=='transport'and context.transport==true)
    o.alliance.Visible=f~=nil
    if f and not ally then
        local off=state.settings.disableAlliances or state.settings.customAllianceDuration==0
        set(o.alliance,not off and not f.requested,off and '이 전장에선 불가'or '응답 대기')
    elseif f then o.alliance.Active=true;o.alliance:SetAttribute('Why20',nil)end
    o.detail.Visible=f~=nil;o.signal.Visible=f~=nil;o.emoji.Visible=f~=nil
end
function M:cells(kind,g,anchor,flipX,flipY)
    local out={}
    for _,s in ipairs(Input.fixedSlots(kind,g,flipX,flipY))do
        local b=s[1]~='Empty'and self.o.sheet:FindFirstChild(s[1])
        if b and b.Visible then
            local centre=s[2]==0 and s[3]==0
            local size=centre and g.big or Input.minorSlots[s[1]]and g.minor or g.size
            table.insert(out,{x=anchor.X+s[2]*g.radius-size/2,y=anchor.Y+s[3]*g.radius-size/2,w=size,h=size+(centre and 0 or 16)})
        end
    end
    local reach=(kind=='nation'and math.max(g.radius+g.face/2,g.low+g.minorFace/2)or g.radius+g.face/2)+8
    table.insert(out,{x=anchor.X-reach,y=anchor.Y-reach,w=reach*2,h=reach*2,disc=true})
    return out
end
local function body()
    local char=Players.LocalPlayer.Character
    return char and char:FindFirstChild('HumanoidRootPart'),char and char:FindFirstChildOfClass('Humanoid')
end
function M:room(shift)
    local r=self.o.renderer;local hrp,hum=body()
    if not r.map or r.dropActive or not hrp or hrp.Anchored or(hum and hum.WalkSpeed==0)then return false end
    local from=r.parent.AbsolutePosition+r.parent.AbsoluteSize/2
    local a,b=r:groundAt(from),r:groundAt(from+shift*Theme.scale)
    if not a or not b then return false end
    local origin=(r.overview or r.targetTile)and r.focus or hrp.Position
    local halfX,halfZ=r.map.meta.width*G.scale/2,r.map.meta.height*G.scale/2
    return math.abs(origin.X+a.X-b.X)<=halfX and math.abs(origin.Z+a.Z-b.Z)<=halfZ
end
function M:drag(step)
    local r=self.o.renderer;local hrp=body()
    local from=r.parent.AbsolutePosition+r.parent.AbsoluteSize/2
    local riding=hrp~=nil and not(r.overview or r.targetTile)and r.focus~=nil
    local before=hrp and hrp.Position
    r:dragAvatar(from,from+step*Theme.scale)
    if riding and hrp and before then local moved=hrp.Position-before;r.focus+=Vector3.new(moved.X,0,moved.Z)end
end
function M:stop()
    if self.bound then RunService:UnbindFromRenderStep(self.bound);self.bound=nil end
    self.o.sheet:SetAttribute('Pan20',nil)
end
function M:pan(shift,tile,anchor)
    local o=self.o;local r=o.renderer
    self:stop()
    local offset=anchor-r:project(tile,.1,true)
    local total=kit().reduced and 0 or M.PAN
    local start,done=os.clock(),0
    o.guard:hold(total+M.SETTLE)
    o.sheet:SetAttribute('Pan20',true)
    self.bound='Ring20Pan'
    RunService:BindToRenderStep(self.bound,Enum.RenderPriority.Camera.Value+2,function()
        if not o.sheet.Visible then self:stop();return end
        local t=os.clock()-start
        local p=total>0 and math.min(1,t/total)or 1;p=1-(1-p)*(1-p)
        if p>done then self:drag(shift*(p-done));done=p end
        o.anchor(r:project(tile,.1,true)+offset)
        if t>=total+M.SETTLE then self:stop()end
    end)
end
function M:placeholder(kind,g,slots)
    local sheet=self.o.sheet;local e=sheet:FindFirstChild('Empty20')
    if kind~='land'then if e then e.Visible=false end;return end
    kit()
    if not e then
        e=K.make('Frame',sheet,{Name='Empty20',BackgroundTransparency=1,BorderSizePixel=0,Active=false})
        for i=1,12 do K.round(K.make('Frame',e,{Name='Dot'..i,BackgroundColor3=K.colors.line,BackgroundTransparency=.2,BorderSizePixel=0,Active=false}),'pill')end
    end
    local slot;for _,s in ipairs(slots)do if s[1]=='Empty'then slot=s end end
    local f=g.face;local c=sheet.Size.X.Offset/2
    e.Visible=slot~=nil;e.ZIndex=sheet.ZIndex+1
    if not slot then return end
    K.box(e,c+slot[2]*g.radius-f/2,c+slot[3]*g.radius-f/2,f,f)
    for i=1,12 do
        local a=i*math.pi/6;local d=e:FindFirstChild('Dot'..i)
        d.ZIndex=e.ZIndex;K.box(d,f/2+math.cos(a)*(f/2-2)-2,f/2+math.sin(a)*(f/2-2)-2,4,4)
    end
end
function M:plan(kind,g,anchor,blocks,w,h,tile,revision)
    local key=kind..':'..tostring(tile)..':'..tostring(revision)
    if self.key~=key and tile then
        self.key=key;self.flipX,self.flipY=false,false;self.o.sheet:SetAttribute('Open20',key)
        local limit=math.floor(math.min(w,h)/2)
        local sx,sy=Input.ringShift(self:cells(kind,g,anchor,false,false),blocks,w,h,limit)
        if sx~=0 or sy~=0 then
            if sy>0 and not self:room(Vector2.new(0,sy))then self.flipY=true end
            if sx<0 and not self:room(Vector2.new(sx,0))then self.flipX=true end
            if self.flipX or self.flipY then sx,sy=Input.ringShift(self:cells(kind,g,anchor,self.flipX,self.flipY),blocks,w,h,limit)end
            if sx~=0 or sy~=0 then self:pan(Vector2.new(sx,sy),tile,anchor)end
        end
        self.blockCount=#blocks
    elseif tile and #blocks>(self.blockCount or 0)and not self.bound then
        self.blockCount=#blocks
        local limit=math.floor(math.min(w,h)/2)
        local sx,sy=Input.ringShift(self:cells(kind,g,anchor,self.flipX,self.flipY),blocks,w,h,limit)
        if sy>0 and not self:room(Vector2.new(0,sy))and not self.flipY then self.flipY=true;sx,sy=Input.ringShift(self:cells(kind,g,anchor,false,true),blocks,w,h,limit)end
        if (sx~=0 or sy~=0)and self:room(Vector2.new(sx,sy))then self:pan(Vector2.new(sx,sy),tile,anchor)end
    end
    local slots=Input.fixedSlots(kind,g,self.flipX,self.flipY)
    self:placeholder(kind,g,slots)
    return slots
end
function M:close()
    local sheet=self.o.sheet
    self:stop();self.key=nil
    local e=sheet:FindFirstChild('Empty20')
    local fade=sheet.Visible and sheet.BackgroundTransparency>=1 and require(script.Parent.Hud20).ENABLED
    local ghost=fade and sheet:Clone()
    if e then e.Visible=false end
    if not ghost then return end
    ghost.Name='RingFade20';ghost.Active=false;ghost.Parent=sheet.Parent
    local info=TweenInfo.new(M.FADE,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    for _,o in ipairs(ghost:GetDescendants())do
        local goal={}
        if o:IsA('GuiObject')then
            o.Active=false;pcall(function()o.Interactable=false end)
            if o.BackgroundTransparency<1 then goal.BackgroundTransparency=1 end
        end
        if o:IsA('GuiButton')then o.AutoButtonColor=false end
        if o:IsA('TextLabel')or o:IsA('TextButton')then goal.TextTransparency=1;goal.TextStrokeTransparency=1 end
        if o:IsA('ImageLabel')or o:IsA('ImageButton')or o:IsA('ViewportFrame')then goal.ImageTransparency=1 end
        if o:IsA('UIStroke')then goal.Transparency=1 end
        if next(goal)then Tween:Create(o,info,goal):Play()end
    end
    task.delay(M.FADE+.02,function()ghost:Destroy()end)
end
return M
