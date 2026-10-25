local Players=game:GetService('Players')
local StarterGui=game:GetService('StarterGui')
local UI=require(script.Parent.Theme)
local L=require(script.Parent.Localization)
local Honor=require(script.Parent.CommanderHonor)
local Badge=require(script.Parent.BenefitBadge)
local Step=require(script.Parent.TelemetryStep)
local Preload=require(script.Parent.MapPreload)
local Me=Players.LocalPlayer
local C=UI.colors
local M={};M.__index=M
M.row=48
local function skip(o)o:SetAttribute('LocalizationSkip',true);return o end
local function v2()return require(script.Parent.Lobby20).ENABLED end
local function zAll(root,base)
    local function walk(o,z)for _,c in ipairs(o:GetChildren())do if c:IsA('GuiObject')then c.ZIndex=c.Name=='Depth'and z-1 or z;walk(c,z+1)else walk(c,z)end end end
    root.ZIndex=base;walk(root,base+1)
end
function M.attach(cover)
    local self=setmetatable({cover=cover,home=cover,rows={},data=nil,friends={}},M)
    if v2()then self:build20()
    else
    local f=UI.panel(cover,'WaitingRoster');f.ZIndex=36;f.Visible=false;f.BackgroundColor3=C.bg;self.frame=f
    self.head=UI.label(f,'Head','함께 출격하는 지휘관',14,C.accent);self.head.ZIndex=37;UI.display(self.head,true)
    self.count=skip(UI.label(f,'Count','',13,C.muted));self.count.ZIndex=37;self.count.TextXAlignment=Enum.TextXAlignment.Right
    self.list=UI.make('ScrollingFrame',f,{Name='List',BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.line,CanvasSize=UDim2.new(),ZIndex=37,ScrollingDirection=Enum.ScrollingDirection.Y})
    self.foot=UI.label(f,'Foot','',12,C.muted);self.foot.ZIndex=37
    self.map=skip(UI.label(f,'MapProgress','',12,C.ice));self.map.ZIndex=37;self.map.Visible=false
    end
    Preload.changed.Event:Connect(function()self:progress()end)
    if self.v2 then self:card20()else self:card()end
    local remote=script.Parent.Parent:WaitForChild('WaitingRoster')
    remote.OnClientEvent:Connect(function(v)self:set(v)end)
    cover:GetPropertyChangedSignal('Visible'):Connect(function()if not cover.Visible then self:set(nil)end end)
    self.sized=cover:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()self:layout()end)
    Players.PlayerAdded:Connect(function()if self.data then self:draw()end end)
    Players.PlayerRemoving:Connect(function(p)if self.target==p then self:hide()end;if self.data then task.defer(function()self:draw()end)end end)
    return self
end
local function valid(v)
    if type(v)~='table'or type(v.users)~='table'or type(v.arrived)~='table'or #v.users>40 then return false end
    for _,id in ipairs(v.users)do if type(id)~='number'then return false end end
    return true
end
function M:set(v)
    if v~=nil and not valid(v)then return end
    local first=v and (not self.data or self.data.match~=v.match)
    self.data=v
    if not v then self.frame.Visible=false;self:hide();self:restore();self.shownMatch=nil;return end
    if first then Step.step('queue','waitingRoster',{result='shown',value=#v.users})end
    local was=self.frame.Visible
    self.frame.Visible=true;self:layout();self:draw()
    if self.v2 and not was then
        local K=require(script.Parent.Kit20)
        self.frame.Visible=false;self.frame:SetAttribute('Shown20',false);K.rehome(self.frame)
        K.appear(self.frame,{dx=self.side and 16 or 0,dy=self.side and 0 or 16,t=.18})
    end
end
function M:host(target)
    target=target or self.home;if self.cover==target then return end
    self:restore();self.cover=target;self.frame.Parent=target;self.c.frame.Parent=target
    self.sized:Disconnect();self.sized=target:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()self:layout()end)
    self:layout()
end
function M:layout()
    local size=self.cover.AbsoluteSize;local w,h=size.X,size.Y
    if self.v2 then w,h=w/(UI.scale or 1),h/(UI.scale or 1)end
    local side=w>h and (h<560 or self.cover~=self.home)
    self.side=side
    local f=self.frame
    if side then
        local width=math.min(340,math.floor(w*.46))
        f.AnchorPoint=Vector2.new(1,0);f.Position=UDim2.new(1,-16,0,48);f.Size=UDim2.new(0,width,1,-64)
        for _,name in ipairs({'Kicker','Title','Track','Hint'})do
            local o=self.cover:FindFirstChild(name);if o then
                if not o:GetAttribute('RosterX')then o:SetAttribute('RosterX',o.Position.X.Scale);o:SetAttribute('RosterW',o.Size.X.Offset)end
                o.Position=UDim2.new(0,math.floor((w-width-16)/2),o.Position.Y.Scale,o.Position.Y.Offset)
                if name~='Track'then o.Size=UDim2.new(0,w-width-48,o.Size.Y.Scale,o.Size.Y.Offset)end
            end
        end
    else
        self:restore()
        local width=math.min(440,w-32)
        f.AnchorPoint=Vector2.new(.5,0);f.Position=UDim2.new(.5,0,.5,88);f.Size=UDim2.new(0,width,.5,-104)
    end
    if self.v2 then if not(f:GetAttribute('Moving20'))then f:SetAttribute('Home20',f.Position)end;self:layout20();return end
    local fw=f.AbsoluteSize.X
    UI.box(self.head,12,8,fw-110,20);UI.box(self.count,fw-98,8,86,20)
    local big=self.data and self.data.big==true
    self.list.Position=UDim2.fromOffset(6,32);self.list.Size=UDim2.new(1,-12,1,big and -78 or -58)
    self.map.Position=UDim2.new(0,12,1,-44);self.map.Size=UDim2.new(1,-24,0,18)
    self.foot.Position=UDim2.new(0,12,1,-24);self.foot.Size=UDim2.new(1,-24,0,18)
    if self.data then self:draw()end
end
function M:restore()
    for _,name in ipairs({'Kicker','Title','Track','Hint'})do
        local o=self.cover:FindFirstChild(name)
        if o and o:GetAttribute('RosterX')~=nil then
            o.Position=UDim2.new(o:GetAttribute('RosterX'),0,o.Position.Y.Scale,o.Position.Y.Offset)
            if name~='Track'then o.Size=UDim2.new(1,o:GetAttribute('RosterW'),o.Size.Y.Scale,o.Size.Y.Offset)end
            o:SetAttribute('RosterX',nil);o:SetAttribute('RosterW',nil)
        end
    end
end
function M:rowFor(i)
    if self.v2 then return self:rowFor20(i)end
    local r=self.rows[i];if r then return r end
    local b=UI.make('TextButton',self.list,{Name='Row'..i,Text='',AutoButtonColor=true,BackgroundColor3=C.raised,BackgroundTransparency=.35,BorderSizePixel=0,ZIndex=38})
    UI.corner(b,3)
    local level=skip(UI.label(b,'Level','',13,C.bg));level.ZIndex=40;level.BackgroundColor3=C.accent;level.BackgroundTransparency=0
    level.TextXAlignment=Enum.TextXAlignment.Center;level.Font=Enum.Font.BuilderSansExtraBold;UI.corner(level,3)
    local name=skip(UI.label(b,'Name','',15,C.ink));name.ZIndex=39;name.TextWrapped=false;name.TextTruncate=Enum.TextTruncate.AtEnd
    local badge=Badge.create(b,16);badge.root.ZIndex=40;for _,o in ipairs(badge.root:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=40 end end
    r={button=b,level=level,name=name,badge=badge}
    b.Activated:Connect(function()if r.player then self:show(r.player)end end)
    self.rows[i]=r;return r
end
local function order(v)
    local out={};local arrived={};for _,id in ipairs(v.arrived)do arrived[id]=true end
    for _,id in ipairs(v.users)do if id==Me.UserId then table.insert(out,id)end end
    for _,id in ipairs(v.users)do if id~=Me.UserId and arrived[id]then table.insert(out,id)end end
    for _,id in ipairs(v.users)do if not arrived[id]then table.insert(out,id)end end
    return out,arrived
end
function M:draw()
    local v=self.data;if not v then return end
    if self.v2 then self:draw20();return end
    local width=self.list.AbsoluteSize.X-6
    local list,arrived=order(v)
    for i,id in ipairs(list)do
        local r=self:rowFor(i);local p=arrived[id]and Players:GetPlayerByUserId(id)or nil
        r.player=p;r.button.Visible=true;UI.box(r.button,0,(i-1)*(M.row+4),width,M.row)
        r.button.Active=p~=nil and p~=Me
        local h=p and Honor.of(p)
        r.level.Text=h and ('Lv.'..h.level)or '…';UI.box(r.level,8,12,52,24)
        r.level.BackgroundColor3=h and (p==Me and C.accent or C.ice)or C.line
        local clan=p and p:GetAttribute('CommanderClan');clan=type(clan)=='string'and clan~=''and clan or nil
        r.name.Text=p and (clan and string.format('[%s] %s',clan,p.DisplayName)or p.DisplayName)or L.text('접속 중')
        r.name.TextColor3=p and C.ink or C.muted
        Badge.update(r.badge,p and p:GetAttribute('CommanderPermanent')==true,p and p:GetAttribute('CommanderVIP')==true)
        local bw=Badge.width(r.badge)
        r.badge.root.Position=UDim2.fromOffset(width-10-bw,16)
        UI.box(r.name,70,13,width-84-(bw>0 and bw+6 or 0),22)
    end
    for i=#list+1,#self.rows do self.rows[i].button.Visible=false;self.rows[i].player=nil end
    self.list.CanvasSize=UDim2.fromOffset(0,#list*(M.row+4))
    self.count.Text=string.format(L.text('%d/%d명 접속'),#v.arrived,#v.users)
    self.foot.Text=''
    self:progress()
end
function M:progress()
    local v=self.data
    if not v or v.big~=true then self.map.Visible=false;if self.mapBar then self.mapBar.frame.Visible=false end;return end
    local share=Preload.progress(v.map)
    self.map.Visible=share~=nil;if self.mapBar then self.mapBar.frame.Visible=share~=nil end;if share==nil then return end
    if share==1 then self.map.Text=L.text('큰 지도 준비 완료');self.map.TextColor3=C.accent
    else self.map.Text=string.format(L.text('큰 지도 받는 중 %d%%'),math.floor(share*100));self.map.TextColor3=C.ice end
    if self.mapBar then self.map.TextColor3=share==1 and C.accent or C.muted;self.mapBar:setColors(C.accent);self.mapBar:set(share,true)end
end
function M:card()
    local f=UI.panel(self.cover,'WaitingCard');f.ZIndex=45;f.Visible=false;f.BackgroundColor3=C.bg;f.BackgroundTransparency=.04
    f.AnchorPoint=Vector2.new(.5,.5);f.Position=UDim2.fromScale(.5,.5);f.Size=UDim2.fromOffset(320,200)
    local c={frame=f}
    c.strip=require(script.Parent.EdgeMask).fit(UI.make('Frame',f,{Name='Strip',BackgroundColor3=C.accent,BorderSizePixel=0,ZIndex=46}));UI.box(c.strip,0,0,320,3)
    c.avatar=UI.make('ImageLabel',f,{Name='Avatar',BackgroundColor3=C.raised,BorderSizePixel=0,ZIndex=46});UI.corner(c.avatar,3);UI.box(c.avatar,14,16,64,64)
    c.name=skip(UI.label(f,'Name','',18,C.ink));UI.box(c.name,90,14,216,24)
    c.badge=Badge.create(f,18);c.badge.root.ZIndex=47;for _,o in ipairs(c.badge.root:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=47 end end
    c.handle=skip(UI.label(f,'Handle','',12,C.muted));UI.box(c.handle,90,38,216,16)
    c.rank=skip(UI.label(f,'Rank','',13,C.gold));UI.box(c.rank,90,56,216,18)
    c.unit=UI.label(f,'Unit','',12,C.muted);UI.box(c.unit,90,74,216,16)
    for _,o in ipairs({c.name,c.handle,c.rank,c.unit})do o.TextXAlignment=Enum.TextXAlignment.Left;o.TextTruncate=Enum.TextTruncate.AtEnd;o.TextWrapped=false;o.ZIndex=46 end
    c.friend=UI.button(f,'Friend','친구 요청',function()self:friend()end,true);UI.box(c.friend,14,140,190,48);c.friend.ZIndex=46
    c.close=UI.button(f,'Close','닫기',function()self:hide()end);UI.box(c.close,212,140,94,48);c.close.ZIndex=46
    self.c=c
end
function M:show(p)
    if not p or p==Me then return end
    self.target=p;local c=self.c
    c.avatar.Image='rbxthumb://type=AvatarHeadShot&id='..p.UserId..'&w=150&h=150'
    if self.friends[p.UserId]==nil then
        task.spawn(function()local ok,yes=pcall(function()return Me:IsFriendsWith(p.UserId)end);self.friends[p.UserId]=ok and yes or false;if self.target==p then self:fill()end end)
    end
    Step.step('social','commanderCard',{result='shown',item='waitingRoster'})
    local was=c.frame.Visible
    self:fill();c.frame.Visible=true
    if self.v2 and not was then
        local K=require(script.Parent.Kit20);c.frame.Visible=false;c.frame:SetAttribute('Shown20',false);K.rehome(c.frame)
        K.appear(c.frame,{scaleFrom=.96,t=.16})
    end
end
function M:fill()
    if self.v2 then self:fill20();return end
    local p=self.target;local c=self.c;if not p then return end
    local h=Honor.of(p)
    local clan=p:GetAttribute('CommanderClan');clan=type(clan)=='string'and clan~=''and clan or nil
    c.name.Text=clan and string.format('[%s] %s',clan,p.DisplayName)or p.DisplayName
    local permanent,club=p:GetAttribute('CommanderPermanent')==true,p:GetAttribute('CommanderVIP')==true
    Badge.update(c.badge,permanent,club);local bw=Badge.width(c.badge)
    c.badge.root.Position=UDim2.fromOffset(306-bw,17);c.name.Size=UDim2.fromOffset(bw>0 and 210-bw or 216,24)
    local caption=Badge.caption(permanent,club)
    c.handle.Text='@'..p.Name..(caption~=''and '  '..L.text(caption)or '')
    c.handle.TextColor3=Badge.color(permanent,club)
    c.rank.Text=h and string.format('Lv. %d',h.level)or ''
    local mine=Me:GetAttribute('CommanderClan')
    c.unit.Text=clan and (clan==mine and '같은 클랜'or '클랜 소속')or '클랜 없음'
    c.unit.TextColor3=clan and clan==mine and C.accent or C.muted
    local plate=h and h.plate;c.strip.BackgroundColor3=plate and Honor.edge(plate)or C.accent
    local friend=self.friends[p.UserId]
    c.friend.Text=friend and '이미 친구'or self.sent==p and '요청 보냄'or '친구 요청'
    UI.enabled(c.friend,friend==false and self.sent~=p)
end
function M:friend()
    local p=self.target;if not p then return end
    self.sent=p;Step.step('social','friendRequest',{result='opened',item='waitingRoster'})
    pcall(function()StarterGui:SetCore('PromptSendFriendRequest',p)end)
    if self.v2 and self.c.friendB then require(script.Parent.Kit20).confirm(self.c.friendB,true)end
    self:fill()
end
function M:hide()
    self.target=nil
    if self.v2 then require(script.Parent.Kit20).leave(self.c.frame,{t=.10});return end
    self.c.frame.Visible=false
end

function M:build20()
    local K=require(script.Parent.Kit20);local KC=K.colors
    self.v2=true
    local f=K.make('Frame',self.cover,{Name='WaitingRoster',BackgroundColor3=Color3.fromRGB(15,21,29),BackgroundTransparency=.04,BorderSizePixel=0,Visible=false,Active=true,ZIndex=36})
    K.round(f,12);K.stroke(f,KC.line,1);self.frame=f
    self.head=K.text(f,'Head','함께 출격하는 지휘관',15,KC.ink,800)
    self.count=K.make('Frame',f,{Name='Count',BackgroundTransparency=1,BorderSizePixel=0})
    self.countA=K.num(self.count,'A','',16,KC.ink);self.countB=K.num(self.count,'B','',16,KC.muted)
    self.list=K.make('ScrollingFrame',f,{Name='List',BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=KC.line,CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y,Active=true})
    K.scrollPad(self.list,4)
    self.foot=K.text(f,'Foot','',12,KC.muted,700);self.foot.Visible=false
    self.map=K.text(f,'MapProgress','',12,KC.muted,700);skip(self.map);self.map.Visible=false
    self.mapBar=K.fillBar(f,'MapBar',{p=0,fill=KC.accent,track=KC.raised});self.mapBar.frame.Visible=false
    zAll(f,36)
end
function M:layout20()
    local K=require(script.Parent.Kit20)
    local s=UI.scale or 1;local fw=self.frame.AbsoluteSize.X/s
    if fw<=0 then fw=340 end
    local pad=14
    K.box(self.head,pad,8,fw-pad*2-80,32)
    self.headW=fw
    local big=self.data and self.data.big==true
    local bottom=big and 40 or 8
    self.list.Position=UDim2.fromOffset(pad-4,44);self.list.Size=UDim2.new(1,-(pad-4)*2,1,-(44+bottom))
    self.map.Position=UDim2.new(0,pad,1,-34);self.map.Size=UDim2.new(1,-pad*2,0,16)
    self.mapBar.frame.Position=UDim2.new(0,pad,1,-14);self.mapBar.frame.Size=UDim2.new(1,-pad*2,0,4)
    if self.data then self:draw()end
end
function M:rowFor20(i)
    local r=self.rows[i];if r then return r end
    local K=require(script.Parent.Kit20);local KC=K.colors
    local b=K.button(self.list,'Row'..i,{kind='none',r=8,sound=false},function()local rr=self.rows[i];if rr and rr.player and rr.player~=Me then require(script.Parent.ToyAudio).play('click');self:show(rr.player)end end)
    b.minHit=0
    local face=b.face;face.BackgroundColor3=KC.panel;face.BackgroundTransparency=0;b.faceStroke.Enabled=true;b.faceStroke.Color=KC.line;b.faceStroke.Transparency=0
    b.baseFill=KC.panel;b.baseAlpha=0;b.baseStroke=KC.line
    local av=K.avatar(face,'Avatar',nil,32)
    local name=K.text(face,'Name','',14,KC.ink,700);skip(name)
    local level=K.num(face,'Level','',12,KC.muted)
    local badge=Badge.create(face,16)
    r={b=b,button=b.button,face=face,avatar=av,name=name,level=level,badge=badge}
    self.rows[i]=r;return r
end
function M:draw20()
    local K=require(script.Parent.Kit20);local KC=K.colors
    local v=self.data
    local s=UI.scale or 1;local width=self.list.AbsoluteSize.X/s-8
    if width<=0 then width=(self.headW or 340)-28-8 end
    local list,arrived=order(v)
    local fresh=self.shownMatch~=v.match;self.shownMatch=v.match
    local appear={}
    local rh=M.row;local gap=6
    for i,id in ipairs(list)do
        local r=self:rowFor20(i);local p=arrived[id]and Players:GetPlayerByUserId(id)or nil
        local came=r.player==nil and p~=nil and not fresh
        r.player=p;r.button.Visible=true;r.b:place(0,(i-1)*(rh+gap),width,rh)
        local me=p==Me
        r.b.faceStroke.Color=me and KC.accent or KC.line;r.b.faceStroke.Thickness=me and 2 or 1;r.b.baseStroke=r.b.faceStroke.Color
        pcall(function()r.b.faceStroke.BorderStrokePosition=Enum.BorderStrokePosition.Inner end)
        local h=p and Honor.of(p)
        if r.uid~=id then r.uid=id;r.avatar.Image='rbxthumb://type=AvatarHeadShot&id='..id..'&w=150&h=150'end
        r.avatar.ImageTransparency=p and 0 or .55
        K.stroke(r.avatar,h and h.plate and Honor.edge(h.plate)or KC.line,h and h.plate and 2 or 1)
        K.box(r.avatar,10,(rh-32)/2,32,32)
        local clan=p and p:GetAttribute('CommanderClan');clan=type(clan)=='string'and clan~=''and clan or nil
        r.name.Text=p and (clan and string.format('[%s] %s',clan,p.DisplayName)or p.DisplayName)or L.text('접속 중')
        r.name.TextColor3=p and KC.ink or KC.muted
        r.level.Text=h and ('Lv '..h.level)or '';r.level.Visible=h~=nil
        Badge.update(r.badge,p and p:GetAttribute('CommanderPermanent')==true,p and p:GetAttribute('CommanderVIP')==true)
        local bw=Badge.width(r.badge)
        r.badge.root.Position=UDim2.fromOffset(width-12-bw,math.floor((rh-16)/2))
        local tx=52;local nw=width-tx-12-(bw>0 and bw+8 or 0)
        if h then K.box(r.name,tx,7,nw,18);K.box(r.level,tx,26,nw,15)else K.box(r.name,tx,0,nw,rh)end
        if fresh and i<=6 then table.insert(appear,r.button)end
        if came then K.punch(r.avatar,.9,.14)end
    end
    for i=#list+1,#self.rows do self.rows[i].button.Visible=false;self.rows[i].player=nil end
    self.list.CanvasSize=UDim2.fromOffset(0,#list*(rh+gap)-gap+8)
    local a,b=tostring(#v.arrived),' / '..tostring(#v.users)
    self.countA.Text=a;self.countB.Text=b
    local wa,wb=K.width(a,16,self.countA),K.width(b,16,self.countB)
    local fw=self.headW or 340
    K.box(self.count,fw-14-wa-wb-2,8,wa+wb+2,32);K.box(self.countA,0,0,wa+1,32);K.box(self.countB,wa,0,wb+2,32)
    self.foot.Text=''
    zAll(self.frame,36)
    self:progress()
    if #appear>0 and not K.reduced then for k,o in ipairs(appear)do K.rehome(o);o:SetAttribute('Shown20',false);K.appear(o,{dy=8,t=.14,delay=(k-1)*.03})end end
end
function M:card20()
    local K=require(script.Parent.Kit20);local KC=K.colors
    local W,Hh=320,214
    local f=K.make('Frame',self.cover,{Name='WaitingCard',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(W,Hh),BackgroundColor3=Color3.fromRGB(15,21,29),BorderSizePixel=0,Visible=false,Active=true,ZIndex=45})
    K.round(f,12);K.stroke(f,KC.line,1)
    local c={frame=f}
    c.avatar=K.avatar(f,'Avatar',nil,64,KC.accent,2);K.box(c.avatar,18,18,64,64)
    c.name=K.text(f,'Name','',18,KC.ink,800);skip(c.name);K.box(c.name,96,18,206,24)
    c.badge=Badge.create(f,18)
    c.handle=K.text(f,'Handle','',12,KC.muted,700);skip(c.handle);K.box(c.handle,96,44,206,16)
    c.rank=K.num(f,'Rank','',14,KC.ink);K.box(c.rank,96,64,80,18)
    c.unit=K.text(f,'Unit','',12,KC.muted,800)
    c.friendB=K.button(f,'Friend',{kind='pri',text='친구 요청',size=16,weight=800},function()self:friend()end)
    c.friendB:place(18,Hh-18-48,184,48);c.friend=c.friendB.button
    c.closeB=K.button(f,'Close',{kind='plain',text='닫기',size=15,weight=800},function()self:hide()end)
    c.closeB:place(210,Hh-18-48,92,48);c.close=c.closeB.button
    zAll(f,45)
    self.c=c
end
function M:fill20()
    local K=require(script.Parent.Kit20);local KC=K.colors
    local p=self.target;local c=self.c;if not p then return end
    local h=Honor.of(p)
    local clan=p:GetAttribute('CommanderClan');clan=type(clan)=='string'and clan~=''and clan or nil
    c.name.Text=clan and string.format('[%s] %s',clan,p.DisplayName)or p.DisplayName
    local permanent,club=p:GetAttribute('CommanderPermanent')==true,p:GetAttribute('CommanderVIP')==true
    Badge.update(c.badge,permanent,club);local bw=Badge.width(c.badge)
    c.badge.root.Position=UDim2.fromOffset(302-bw,21);c.name.Size=UDim2.fromOffset(bw>0 and 198-bw or 206,24)
    local caption=Badge.caption(permanent,club)
    c.handle.Text='@'..p.Name..(caption~=''and '  '..L.text(caption)or '')
    c.handle.TextColor3=Badge.color(permanent,club)
    c.rank.Text=h and string.format('Lv %d',h.level)or ''
    c.avatar.Image='rbxthumb://type=AvatarHeadShot&id='..p.UserId..'&w=150&h=150'
    local plate=h and h.plate;K.stroke(c.avatar,plate and Honor.edge(plate)or KC.accent,2)
    local mine=Me:GetAttribute('CommanderClan')
    local word=clan and (clan==mine and '같은 클랜'or '클랜 소속')or '클랜 없음'
    if c.unitChip then c.unitChip:Destroy()end
    local chip=K.chip(c.frame,'UnitChip',word,clan and clan==mine and 'accent'or 'muted',{size=12,height=22,icon=clan and 'clan'or false})
    chip.Position=UDim2.fromOffset(96,(h and 88 or 66));c.unitChip=chip
    c.unit.Text=word;c.unit.Visible=false
    local friend=self.friends[p.UserId]
    c.friendB:setText(friend and '이미 친구'or self.sent==p and '요청 보냄'or '친구 요청')
    c.friendB:setEnabled(friend==false and self.sent~=p)
    zAll(c.frame,45)
end
return M
