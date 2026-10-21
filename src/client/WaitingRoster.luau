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
function M.attach(cover)
    local self=setmetatable({cover=cover,home=cover,rows={},data=nil,friends={}},M)
    local f=UI.panel(cover,'WaitingRoster');f.ZIndex=36;f.Visible=false;f.BackgroundColor3=C.bg;self.frame=f
    self.head=UI.label(f,'Head','함께 출격하는 지휘관',14,C.accent);self.head.ZIndex=37;UI.display(self.head,true)
    self.count=skip(UI.label(f,'Count','',13,C.muted));self.count.ZIndex=37;self.count.TextXAlignment=Enum.TextXAlignment.Right
    self.list=UI.make('ScrollingFrame',f,{Name='List',BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.line,CanvasSize=UDim2.new(),ZIndex=37,ScrollingDirection=Enum.ScrollingDirection.Y})
    self.foot=UI.label(f,'Foot','',12,C.muted);self.foot.ZIndex=37
    self.map=skip(UI.label(f,'MapProgress','',12,C.ice));self.map.ZIndex=37;self.map.Visible=false
    Preload.changed.Event:Connect(function()self:progress()end)
    self:card()
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
    if not v then self.frame.Visible=false;self:hide();self:restore();return end
    if first then Step.step('queue','waitingRoster',{result='shown',value=#v.users})end
    self.frame.Visible=true;self:layout();self:draw()
end
function M:host(target)
    target=target or self.home;if self.cover==target then return end
    self:restore();self.cover=target;self.frame.Parent=target;self.c.frame.Parent=target
    self.sized:Disconnect();self.sized=target:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()self:layout()end)
    self:layout()
end
function M:layout()
    local size=self.cover.AbsoluteSize;local w,h=size.X,size.Y
    local side=w>h and (h<560 or self.cover~=self.home)
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
    local r=self.rows[i];if r then return r end
    local b=UI.make('TextButton',self.list,{Name='Row'..i,Text='',AutoButtonColor=true,BackgroundColor3=C.raised,BackgroundTransparency=.35,BorderSizePixel=0,ZIndex=38})
    UI.corner(b,3)
    local level=skip(UI.label(b,'Level','',13,C.bg));level.ZIndex=40;level.BackgroundColor3=C.accent;level.BackgroundTransparency=0
    level.TextXAlignment=Enum.TextXAlignment.Center;level.Font=Enum.Font.BuilderSansExtraBold;UI.corner(level,3)
    local name=skip(UI.label(b,'Name','',15,C.ink));name.ZIndex=39;name.TextWrapped=false;name.TextTruncate=Enum.TextTruncate.AtEnd
    local sub=UI.label(b,'Sub','',12,C.muted);sub.ZIndex=39;sub.TextWrapped=false;sub.TextTruncate=Enum.TextTruncate.AtEnd
    local badge=Badge.create(b,16);badge.root.ZIndex=40;for _,o in ipairs(badge.root:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=40 end end
    r={button=b,level=level,name=name,sub=sub,badge=badge}
    b.Activated:Connect(function()if r.player then self:show(r.player)end end)
    self.rows[i]=r;return r
end
function M:draw()
    local v=self.data;if not v then return end
    local width=self.list.AbsoluteSize.X-6
    local order={};local arrived={};for _,id in ipairs(v.arrived)do arrived[id]=true end
    for _,id in ipairs(v.users)do if id==Me.UserId then table.insert(order,id)end end
    for _,id in ipairs(v.users)do if id~=Me.UserId and arrived[id]then table.insert(order,id)end end
    for _,id in ipairs(v.users)do if not arrived[id]then table.insert(order,id)end end
    for i,id in ipairs(order)do
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
        UI.box(r.name,70,5,width-84-(bw>0 and bw+6 or 0),22)
        local worn=h and h.title~=''and h.title~=h.rank
        r.sub.Text=h and (worn and h.rank..'  '..h.title or h.rank)or ''
        UI.box(r.sub,70,26,width-84,18)
    end
    for i=#order+1,#self.rows do self.rows[i].button.Visible=false;self.rows[i].player=nil end
    self.list.CanvasSize=UDim2.fromOffset(0,#order*(M.row+4))
    self.count.Text=string.format(L.text('%d/%d명 접속'),#v.arrived,#v.users)
    local foot
    if v.ai and v.ai>0 then foot=string.format(L.text('AI 지휘관 %d명이 빈자리를 채워요'),v.ai)
    elseif v.mode=='teams'then foot=L.text('팀은 출발할 때 나눠요')else foot=''end
    self.foot.Text=foot
    self:progress()
end
function M:progress()
    local v=self.data
    if not v or v.big~=true then self.map.Visible=false;return end
    local share=Preload.progress(v.map)
    self.map.Visible=share~=nil;if share==nil then return end
    if share==1 then self.map.Text=L.text('큰 지도 준비 완료');self.map.TextColor3=C.accent
    else self.map.Text=string.format(L.text('큰 지도 받는 중 %d%%'),math.floor(share*100));self.map.TextColor3=C.ice end
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
    self:fill();c.frame.Visible=true
end
function M:fill()
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
    local worn=h and h.title~=''and h.title~=h.rank
    c.rank.Text=h and (worn and string.format('Lv. %d  %s  %s',h.level,h.rank,h.title)or string.format('Lv. %d  %s',h.level,h.rank))or ''
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
    self:fill()
end
function M:hide()self.target=nil;self.c.frame.Visible=false end
return M
