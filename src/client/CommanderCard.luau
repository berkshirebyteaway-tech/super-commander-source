local Players=game:GetService('Players')
local StarterGui=game:GetService('StarterGui')
local UI=require(script.Parent.ToyUI)
local Honor=require(script.Parent.CommanderHonor)
local L=require(script.Parent.Localization)
local Badge=require(script.Parent.BenefitBadge)
local Me=Players.LocalPlayer
local M={};M.__index=M
local function skip(o)o:SetAttribute('LocalizationSkip',true);o.AutoLocalize=false;return o end
function M.new(lobby)
    local self=setmetatable({lobby=lobby,prompts={},taps={},friends={}},M)
    local f=UI.panel(lobby.frame,'CommanderCard');self.frame=f
    f.AnchorPoint=Vector2.new(.5,1);f.Position=UDim2.new(.5,0,1,-96);f.Size=UDim2.fromOffset(340,212);f.ZIndex=6;f.Visible=false
    f.BackgroundColor3=UI.colors.bg;f.BackgroundTransparency=.08
    self.strip=require(script.Parent.EdgeMask).fit(UI.make('Frame',f,{Name='Strip',BackgroundColor3=UI.colors.accent,BorderSizePixel=0,ZIndex=6}));UI.box(self.strip,0,0,340,3)
    self.avatar=UI.make('ImageLabel',f,{Name='Avatar',BackgroundColor3=UI.colors.raised,BorderSizePixel=0,ZIndex=6});UI.corner(self.avatar,3);UI.box(self.avatar,14,16,64,64)
    self.name=skip(UI.label(f,'Name','',18,UI.colors.ink));UI.box(self.name,90,14,236,24)
    self.badge=Badge.create(f,20);self.badge.root.ZIndex=7;for _,o in ipairs(self.badge.root:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=7 end end
    self.handle=skip(UI.label(f,'Handle','',12,UI.colors.muted));UI.box(self.handle,90,38,236,16)
    self.rank=skip(UI.label(f,'Rank','',13,UI.colors.gold));UI.box(self.rank,90,56,236,18)
    self.unit=UI.label(f,'Unit','',12,UI.colors.muted);UI.box(self.unit,90,74,236,16)
    for _,o in ipairs({self.name,self.handle,self.rank,self.unit})do o.TextXAlignment=Enum.TextXAlignment.Left;o.TextTruncate=Enum.TextTruncate.AtEnd;o.ZIndex=6 end
    self.profile=UI.button(f,'Profile','전적 보기',function()local p=self.target;if p then self:hide();require(script.Parent.CommanderProfile).open(self.lobby,p,'plaza')end end,true);UI.box(self.profile,14,96,100,48)
    self.invite=UI.button(f,'Invite','파티 초대',function()self:act('invite')end);UI.box(self.invite,120,96,100,48)
    self.friend=UI.button(f,'Friend','친구 요청',function()self:act('friend')end);UI.box(self.friend,226,96,100,48)
    self.note=UI.label(f,'Note','',12,UI.colors.muted);UI.box(self.note,14,152,226,48);self.note.TextXAlignment=Enum.TextXAlignment.Left
    self.close=UI.button(f,'Close','닫기',function()self:hide()end);UI.box(self.close,246,152,80,48);self.close.TextSize=14
    for _,o in ipairs({self.profile,self.invite,self.friend,self.note,self.close})do o.ZIndex=6 end
    local function watch(p)
        if p==Me then return end
        p.CharacterAdded:Connect(function(c)task.wait(.5);self:attach(p,c)end)
        if p.Character then self:attach(p,p.Character)end
    end
    for _,p in ipairs(Players:GetPlayers())do watch(p)end
    self.added=Players.PlayerAdded:Connect(watch)
    self.removed=Players.PlayerRemoving:Connect(function(p)self.prompts[p]=nil;if self.taps[p]then self.taps[p].gui:Destroy();self.taps[p]=nil end;if self.target==p then self:hide()end end)
    task.spawn(function()
        while lobby.frame.Parent do
            local open=self:inPlaza()
            for p,prompt in pairs(self.prompts)do
                local head=p.Character and p.Character:FindFirstChild('Head');local hidden=head~=nil and head.LocalTransparencyModifier>=1
                if prompt.Parent then prompt.Enabled=open and p:GetAttribute('FrontierRoom')==nil and not hidden else self.prompts[p]=nil end
                self:syncTap(p,prompt.Enabled)
            end
            for _,p in ipairs(Players:GetPlayers())do if p~=Me and not self.prompts[p]and p.Character then self:attach(p,p.Character)end end
            if self.target then if not open or self.target:GetAttribute('FrontierRoom')~=nil then self:hide()else self:fill()end end
            task.wait(.5)
        end
        self.added:Disconnect();self.removed:Disconnect()
    end)
    return self
end
function M:inPlaza()
    local l=self.lobby;local d=l.deployment
    return l.frame.Visible and l.inMenu~=false and not l.page and not(d and d.expanded)and Me:GetAttribute('FrontierRoom')==nil
end
function M:attach(p,c)
    local root=c:FindFirstChild('HumanoidRootPart');if not root or root:FindFirstChild('CommanderCardPrompt')then return end
    local prompt=Instance.new('ProximityPrompt');prompt.Name='CommanderCardPrompt'
    prompt.ActionText=L.text('지휘관 카드');prompt.ObjectText=p.DisplayName;prompt.HoldDuration=0
    prompt.MaxActivationDistance=12;prompt.RequiresLineOfSight=false;prompt.KeyboardKeyCode=Enum.KeyCode.F
    prompt:SetAttribute('LocalizationSkip',true);prompt.Enabled=false;prompt.Parent=root
    prompt.Triggered:Connect(function()require(script.Parent.TelemetryStep).step('social','commanderCard',{result='shown',item='prompt'});self:show(p)end)
    self.prompts[p]=prompt
    local old=self.taps[p];if old then old.gui:Destroy()end
    local gui=Instance.new('BillboardGui');gui.Name='CommanderTap';gui.Active=true;gui.Enabled=false;gui.ResetOnSpawn=false
    gui.Size=UDim2.fromOffset(320,48);gui.StudsOffsetWorldSpace=Vector3.new(0,3.5,0);gui.MaxDistance=60;gui.Adornee=root
    local button=Instance.new('TextButton');button.Name='Tag';button.Text='';button.BackgroundTransparency=1;button.AutoButtonColor=false
    button.AnchorPoint=Vector2.new(.5,.5);button.Position=UDim2.fromScale(.5,.5);button.Size=UDim2.fromOffset(120,38);button.Parent=gui
    button.Activated:Connect(function()if gui.Enabled then require(script.Parent.TelemetryStep).step('social','commanderCard',{result='shown',item='nameTag'});self:show(p)end end)
    gui.Parent=Me:WaitForChild('PlayerGui')
    self.taps[p]={gui=gui,button=button,character=c}
end
function M:syncTap(p,open)
    local t=self.taps[p];if not t then return end
    local c=p.Character;if c~=t.character or not t.gui.Adornee or not t.gui.Adornee.Parent then t.gui.Enabled=false;return end
    local source=c:FindFirstChild('CommanderName');local tag=source and source:FindFirstChild('Honor')
    local shown=open and source~=nil and source.Enabled and tag~=nil
    t.gui.Enabled=shown;if not shown then return end
    t.gui.Size=source.Size;t.gui.StudsOffsetWorldSpace=source.StudsOffsetWorldSpace
    local scale=tag:FindFirstChild('DistanceScale');local k=scale and scale.Scale or 1
    t.button.Size=UDim2.fromOffset(math.max(48,tag.Size.X.Offset*k),math.max(44,tag.Size.Y.Offset*k))
end
function M:show(p)
    self.target=p;self.sent=nil;self.notice=nil
    self.avatar.Image='rbxthumb://type=AvatarHeadShot&id='..p.UserId..'&w=150&h=150'
    if self.friends[p.UserId]==nil then
        task.spawn(function()local ok,yes=pcall(function()return Me:IsFriendsWith(p.UserId)end);self.friends[p.UserId]=ok and yes or false;if self.target==p then self:fill()end end)
    end
    self:fill();self.frame.Visible=true
end
function M:hide()self.target=nil;self.frame.Visible=false end
function M:fill()
    local p=self.target;if not p then return end
    local h=Honor.of(p)
    local unit=p:GetAttribute('CommanderClan');unit=type(unit)=='string'and unit~=''and unit or nil
    self.name.Text=unit and string.format('[%s] %s',unit,p.DisplayName)or p.DisplayName
    local permanent,club=p:GetAttribute('CommanderPermanent')==true,p:GetAttribute('CommanderVIP')==true
    Badge.update(self.badge,permanent,club);local bw=Badge.width(self.badge)
    self.badge.root.Position=UDim2.fromOffset(326-bw,16);self.name.Size=UDim2.fromOffset(bw>0 and 230-bw or 236,24)
    local caption=Badge.caption(permanent,club)
    self.handle.Text='@'..p.Name..(caption~=''and '  '..L.text(caption)or '')
    self.handle.TextColor3=Badge.color(permanent,club)
    self.rank.Text=h and string.format('Lv. %d',h.level)or ''
    local mine=Me:GetAttribute('CommanderClan')
    self.unit.Text=unit and (unit==mine and '같은 클랜'or '클랜 소속')or '클랜 없음'
    self.unit.TextColor3=unit and unit==mine and UI.colors.accent or UI.colors.muted
    local plate=h and h.plate;self.strip.BackgroundColor3=plate and Honor.edge(plate)or UI.colors.accent
    local stroke=self.frame:FindFirstChildOfClass('UIStroke');if stroke then stroke.Color=plate and Honor.edge(plate)or UI.colors.line end
    local s=self.lobby.data;local party=s and s.party;local users=party and party.users or {Me.UserId}
    local together=table.find(users,p.UserId)~=nil
    local leader=not party or #users<=1 or party.leader==Me.UserId
    local busy=false;for _,x in ipairs(s and s.players or {})do if x.userId==p.UserId then busy=x.busy==true end end
    self.invite.Text=together and '같은 파티'or self.sent=='invite'and '초대 보냄'or '파티 초대'
    UI.enabled(self.invite,not together and leader and #users<5 and not busy and self.sent~='invite'and not self.lobby.busy)
    local friend=self.friends[p.UserId]
    self.friend.Text=friend and '이미 친구'or self.sent=='friend'and '요청 보냄'or '친구 요청'
    UI.enabled(self.friend,friend==false and self.sent~='friend')
    local note=together and '함께 출전해요'or self.notice or not leader and '파티 초대는 방장만'or #users>=5 and '파티 최대 5명'or busy and '지금은 경기 중이에요'or ''
    if self.note.Text~=note then self.note.Text=note end
end
function M:act(kind)
    local p=self.target;if not p then return end
    if kind=='invite'then
        self.lobby:request('invite',p.UserId,function()require(script.Parent.TelemetryStep).step('social','commanderInvite',{result='accepted'});if self.target==p then self.sent='invite';self.notice='수락 시 파티 합류';self:fill()end end)
    else self.sent='friend';require(script.Parent.TelemetryStep).step('social','friendRequest',{result='opened'});pcall(function()StarterGui:SetCore('PromptSendFriendRequest',p)end)end
    self:fill()
end
return M
