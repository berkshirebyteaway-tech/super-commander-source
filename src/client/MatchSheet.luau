local UI=require(script.Parent.Theme)
local Style=require(script.Parent.HudStyle)
local Placement=require(script.Parent.Parent.Core.InterfacePlacement)
local Icons=require(script.Parent.OutgameIcons)
local Step=require(script.Parent.TelemetryStep)
local L=require(script.Parent.Localization)
local Teams=require(script.Parent.TeamStandings)
local C=UI.colors
local SKY=Color3.fromRGB(110,190,255)
local M={SKY=SKY};M.__index=M

function M.touch()return require(script.Parent.InputMode).touch()end
function M.rect(w,h,touch,bottom)
    if touch and not Placement.desk(w,h,touch) and h>=w then
        local top=84;local limit=math.min(bottom or h-152,h-12)
        return {x=12,y=top,w=w-24,h=math.max(180,limit-top-12),phone=true}
    end
    if Placement.phone(w,h,touch)then
        local width=math.min(300,w-24-56)
        return {x=w-56-width,y=8,w=width,h=math.max(140,h-Placement.PHONE_HUD-4-8),phone=true}
    end
    local width=math.min(400,w-24);local s=Placement.shortcuts(w,h,touch)
    local limit=math.min(s.FavoriteEmojis.y,bottom or h)-12
    return {x=w-width-20,y=84,w=width,h=math.max(180,limit-84)}
end
function M.paint(frame)
    frame.BackgroundColor3=Style.colors.panel;frame.BackgroundTransparency=.04;Style.round(frame,10);Style.line(frame,Style.colors.line,1)
end
function M.frame(parent,name)
    local f=UI.panel(parent,name);f.ZIndex=24;f.Visible=false;f.Active=true;f:SetAttribute('HudSolid',true);M.paint(f);return f
end
function M.header(frame,title,onClose)
    local t=UI.label(frame,'Title',title,18);t.Font=Enum.Font.BuilderSansBold;t.TextWrapped=false;t.TextTruncate=Enum.TextTruncate.AtEnd;t.ZIndex=frame.ZIndex+1
    local sub=UI.label(frame,'Count','',13,C.muted);sub.TextWrapped=false;sub.ZIndex=frame.ZIndex+1
    local x=UI.button(frame,'Close','×',onClose);x.TextSize=20;x.ZIndex=frame.ZIndex+2
    x.BackgroundColor3=Style.colors.chip;Style.round(x,8);Style.line(x,Style.colors.line,1)
    return {title=t,sub=sub,close=x}
end
function M.placeHeader(h,width,touch,titleWidth)
    local cs=touch and 48 or 40
    UI.box(h.close,width-cs-10,touch and 2 or 8,cs,cs)
    UI.box(h.title,16,8,math.min(titleWidth or 200,width-cs-40),40)
    local tw=math.min(game:GetService('TextService'):GetTextSize(h.title.Text,18,h.title.Font,Vector2.new(999,40)).X,width-cs-120)
    h.title.Size=UDim2.fromOffset(tw+4,40);UI.box(h.sub,24+tw,8,math.max(40,width-cs-48-tw),40)
    return touch and 52 or 56
end
function M.chip(parent,name,text,fn,on,touch)
    local b=UI.button(parent,name,'',fn);b.BackgroundTransparency=1;b.ZIndex=parent.ZIndex+1
    local pill=UI.make('Frame',b,{Name='Pill',BorderSizePixel=0,AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,0,.5,0),Size=UDim2.new(1,0,0,touch and 34 or 30),ZIndex=b.ZIndex})
    Style.round(pill,15)
    local l=UI.label(pill,'Text',text,13);l.TextXAlignment=Enum.TextXAlignment.Center;l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd;l.Size=UDim2.fromScale(1,1);l.ZIndex=b.ZIndex+1;l.Font=Enum.Font.BuilderSansBold
    M.setChip(b,on);return b
end
function M.setChip(b,on)
    local pill=b:FindFirstChild('Pill');if not pill then return end
    pill.BackgroundColor3=on and C.ink or Style.colors.chip;pill.Text.TextColor3=on and C.bg or C.ink
    Style.line(pill,on and C.ink or Style.colors.line,1);b:SetAttribute('On',on==true)
end
function M.face(parent,userId,size,x,y)
    local i=UI.make('ImageLabel',parent,{Name='Face',BackgroundColor3=Style.colors.cell,BorderSizePixel=0,ZIndex=parent.ZIndex+1,
        Image=userId and userId>0 and ('rbxthumb://type=AvatarHeadShot&id='..userId..'&w=150&h=150')or ''})
    UI.box(i,x or 0,y or 0,size,size);Style.round(i,size//2);return i
end
function M.lock(parent,size,color)
    local i=Icons.create(parent,'lock',size or 12,color or C.muted);i.ZIndex=parent.ZIndex+2;return i
end
function M.banner(parent,name,text,feature,y,w,h)
    local VipLock=require(script.Parent.VipLock)
    if M.touch()then h=math.max(h or 40,48)end
    local b=UI.button(parent,name,'',function()VipLock.offer(feature)end);b.BackgroundColor3=Style.colors.chip;b.ZIndex=parent.ZIndex+1
    Style.round(b,8);Style.line(b,Style.colors.line,1);UI.box(b,0,y,w,h or 40)
    local lock=M.lock(b,13,C.muted);UI.box(lock,12,((h or 40)-13)/2,13,13)
    local l=UI.label(b,'Text',text,13,C.muted);l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd;UI.box(l,32,0,w-32-86,h or 40);l.ZIndex=b.ZIndex+1
    local link=UI.label(b,'More','VIP 보기 ›',13,SKY);link.Font=Enum.Font.BuilderSansBold;link.TextXAlignment=Enum.TextXAlignment.Right;link.TextWrapped=false;UI.box(link,w-92,0,80,h or 40);link.ZIndex=b.ZIndex+1
    return b
end
local function caption(parent,name,text,x,y,w,color)
    local l=UI.label(parent,name,text,13,color or C.muted);l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd;l.ZIndex=parent.ZIndex+1;UI.box(l,x,y,w,22);return l
end
M.caption=caption

function M.new(panel,a,send)
    local self=setmetatable({panel=panel,a=a,send=send,page=nil,state=nil,factions={},sorted={}},M)
    self.controls=panel:FindFirstChild('Controls')
    self.frame=M.frame(panel,'MatchSheet')
    self.head=M.header(self.frame,'',function()self:close()end)
    self.body=UI.make('ScrollingFrame',self.frame,{Name='Body',BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.line,CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y,ZIndex=25})
    self.pinned=UI.make('Frame',self.frame,{Name='Pinned',BackgroundTransparency=1,BorderSizePixel=0,ZIndex=25})
    self.members={
        {frame=a.quick.frame,hide=function()a.quick:hide()end},
        {frame=a.tactical.frame,hide=function()a.tactical:hide()end},
        {frame=a.eventLog.panel,hide=function()a.eventLog:toggle(false)end},
        {frame=self.frame,hide=function()self:close()end},
    }
    for _,m in ipairs(self.members)do m.frame:GetPropertyChangedSignal('Visible'):Connect(function()
        if m.frame.Visible then for _,o in ipairs(self.members)do if o~=m and o.frame.Visible then o.hide()end end end
        if self.relayout then task.defer(self.relayout)end
    end)end
    a.eventLog.sheet=self
    local Invite=require(script.Parent.InviteToast)
    Invite.parent=panel;Invite.inMatch=function()return self.state~=nil and self.state.phase~='menu'end
    Invite.changed=function()if self.relayout then task.defer(self.relayout)end end
    return self
end
function M:any()for _,m in ipairs(self.members)do if m.frame.Visible then return true end end;return false end
function M:closeAll()for _,m in ipairs(self.members)do if m.frame.Visible then m.hide()end end end
function M:outside()self:closeAll()end
function M:comms(tab,id)
    local a=self.a
    if tab=='motion'then
        local VipLock=require(script.Parent.VipLock)
        if not VipLock.allows('motion')then return VipLock.open('motion',false,a.motionShortcut)end
    end
    if a.quick.frame.Visible and a.quick.mode==tab and id==nil then a.quick:hide();return end
    a.chat.openQuick(tab,id)
end
function M:close()
    if self.frame.Visible then Step.step('hud','sheetClose',{item=self.page})end
    self.frame.Visible=false;self.page=nil
end
function M:open(page)
    if self.frame.Visible and self.page==page then self:close();return end
    Step.step('hud','sheetOpen',{item=page});self.page=page;self.frame.Visible=true
    self.body.CanvasPosition=Vector2.zero;self.signature=nil;self:draw()
end
function M:key(input,shift)
    local k=input.KeyCode;local quick=self.a.quick.frame.Visible
    if self:any()and (k==Enum.KeyCode.X or k==Enum.KeyCode.Escape)then self:closeAll();return true end
    if quick then
        local tab=k==Enum.KeyCode.Z and 'emoji'or k==Enum.KeyCode.M and 'motion'or k==Enum.KeyCode.R and not shift and 'messages'or nil
        if tab then self:comms(tab)end
        return true
    end
    return false
end
function M:update(state,factions,sorted)
    self.state=state;self.factions=factions or {};self.sorted=sorted or {}
    if state.phase=='menu'then self:close();return end
    if self.frame.Visible then self:draw()end
end
function M:layout(w,h,touch)
    self.w,self.h,self.touch=w,h,touch
    self.controls=self.controls or self.panel:FindFirstChild('Controls')
    local wheel=self.a.motionWheel
    if wheel and not wheel.sheet then wheel.sheet=function()
        if not self.state or self.state.phase=='menu'then return false end
        if self.state.phase=='playing'and not self.state.observer and not self.state.eliminated then self:comms('motion')end;return true
    end end
    local bottom=self.controls and self.controls.Visible and self.controls.Position.Y.Offset or nil
    local r=M.rect(w,h,touch,bottom);self.r=r
    UI.box(self.frame,r.x,r.y,r.w,r.h)
    self.top=M.placeHeader(self.head,r.w,touch)
    if self.frame.Visible and self.drawnW~=r.w then self.signature=nil;self:draw()end
end
local function relation(f)
    return f.teammate and '같은 팀'or f.allied and '동맹'or nil
end
function M:drawRanks(w)
    local s=self.state;local list={};local mine
    for _,f in ipairs(self.sorted)do if (f.tiles or 0)>0 and not f.eliminated then table.insert(list,f);if f.id==1 then mine=#list end end end
    self.head.title.Text='순위';self.head.sub.Text=string.format('%d명',#list)
    local phone=self.r.phone;local y=0;local body=self.body
    local teamGame=Teams.active(s);if not teamGame then self.rankMode=nil end
    if teamGame then
        local ch=self.touch and 48 or 34
        for i,k in ipairs({{'players','개인'},{'teams','팀'}})do
            local b=M.chip(body,'RankTab_'..k[1],k[2],function()
                if (self.rankMode or 'players')==k[1]then return end
                self.rankMode=k[1];Step.step('hud','rankMode',{item=k[1]});self.signature=nil;self.body.CanvasPosition=Vector2.zero;self:draw()
            end,(self.rankMode or 'players')==k[1],self.touch)
            UI.box(b,(i-1)*76,y,72,ch)
        end
        y+=ch+6
        if self.rankMode=='teams'then return self:drawTeams(w,y)end
    end
    if not phone and s.player then
        local p=s.player;local t=math.floor((s.tick or 0)/10)
        local line=caption(body,'Economy',string.format('내 생산  병력 +%s/s  골드 +%s/s',UI.troops(p.growth or 0),UI.number(p.income or 0)),0,y,w-90,C.muted)
        caption(body,'Clock',string.format('경기 %02d:%02d',t//60,t%60),w-88,y,86,C.muted).TextXAlignment=Enum.TextXAlignment.Right
        line.Name='Economy';y+=28
    end
    local cols=UI.make('Frame',body,{Name='Columns',BackgroundTransparency=1,ZIndex=26});UI.box(cols,0,y,w,20)
    caption(cols,'Rank','#',4,0,20);caption(cols,'Name','지휘관',32,-1,120);local land=caption(cols,'Land','영토',w-130,0,64);land.TextXAlignment=Enum.TextXAlignment.Right
    local troops=caption(cols,'Troops','병력',w-58,0,54);troops.TextXAlignment=Enum.TextXAlignment.Right;y+=22
    local rowH=phone and 30 or 34
    local function row(parent,f,rank,yy,me)
        local r=UI.make('Frame',parent,{Name=me and 'Mine'or 'Row'..rank,BackgroundColor3=me and Style.colors.rateBg or Style.colors.cell,BackgroundTransparency=me and .06 or 1,BorderSizePixel=0,Active=true,ZIndex=26})
        UI.box(r,0,yy,w,rowH-2);Style.round(r,6);if me then Style.line(r,C.accent,1,.3)end
        local rk=caption(r,'Rank',tostring(rank),4,(rowH-24)/2,24,me and C.accent or rank<=3 and C.gold or C.muted);rk.Font=Enum.Font.BuilderSansBold
        local face=M.face(r,f.userId,22,30,(rowH-2-22)/2);if f.allied and not me then Style.line(face,SKY,1.5)end
        local nw=w-30-28-136
        local name=caption(r,'Name',me and '나'or L.nation(f),58,(rowH-24)/2,nw,me and C.accent or C.ink);name.Font=Enum.Font.BuilderSansBold;name:SetAttribute('LocalizationSkip',not me)
        local tag=relation(f);if tag and not me then local n=math.min(name.TextBounds.X,nw-40);local t=caption(r,'Ally',tag,62+n,(rowH-24)/2,40,SKY);t.Font=Enum.Font.BuilderSansBold end
        if not phone then
            local track=UI.make('Frame',r,{Name='LandBar',BackgroundColor3=Style.colors.line,BorderSizePixel=0,ZIndex=27});UI.box(track,w-178,(rowH-2)/2-2,44,4);Style.round(track,2)
            local fill=UI.make('Frame',track,{Name='Fill',BackgroundColor3=me and C.accent or C.ink,BackgroundTransparency=me and 0 or .35,BorderSizePixel=0,ZIndex=28,Size=UDim2.new(math.clamp((f.share or 0)/math.max(.0001,(list[1]and list[1].share or 1)),0,1),0,1,0)});Style.round(fill,2)
        end
        local v=(f.share or 0)*100
        local l=caption(r,'Land',string.format(v>=10 and '%.1f%%'or '%.2f%%',v),w-130,(rowH-24)/2,64,C.ink);l.TextXAlignment=Enum.TextXAlignment.Right
        local tr=caption(r,'Troops',UI.troops(f.troops or 0),w-62,(rowH-24)/2,56,C.ink);tr.TextXAlignment=Enum.TextXAlignment.Right
        r.InputBegan:Connect(function(i)if (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch)and f.labelTile and self.a.focusTile then Step.step('hud','rankFocus',{value=rank});self.a.focusTile(f.labelTile)end end)
        return r
    end
    for i,f in ipairs(list)do if f.id~=1 then row(body,f,i,y,false);y+=rowH end end
    body.CanvasSize=UDim2.fromOffset(0,y+4)
    for _,o in ipairs(self.pinned:GetChildren())do o:Destroy()end
    if mine then row(self.pinned,list[mine],mine,0,true)end
    return mine and rowH+6 or 0
end
function M:drawTeams(w,y)
    local s=self.state;local list=Teams.build(s,self.sorted);local mine
    for i,t in ipairs(list)do if t.mine then mine=i end end
    self.head.title.Text='순위';self.head.sub.Text=string.format('%d개 팀',#list)
    local phone=self.r.phone;local body=self.body
    local cols=UI.make('Frame',body,{Name='Columns',BackgroundTransparency=1,ZIndex=26});UI.box(cols,0,y,w,20)
    caption(cols,'Rank','#',4,0,20);caption(cols,'Name','팀',32,-1,120);local land=caption(cols,'Land','영토',w-130,0,64);land.TextXAlignment=Enum.TextXAlignment.Right
    local troops=caption(cols,'Troops','병력',w-58,0,54);troops.TextXAlignment=Enum.TextXAlignment.Right;y+=22
    local rowH=phone and 30 or 34
    local function row(parent,t,rank,yy,me)
        local r=UI.make('Frame',parent,{Name=me and 'MyTeam'or 'Team'..rank,BackgroundColor3=me and Style.colors.rateBg or Style.colors.cell,BackgroundTransparency=me and .06 or 1,BorderSizePixel=0,Active=true,ZIndex=26})
        UI.box(r,0,yy,w,rowH-2);Style.round(r,6);if me then Style.line(r,C.accent,1,.3)end
        local rk=caption(r,'Rank',tostring(rank),4,(rowH-24)/2,24,me and C.accent or rank<=3 and C.gold or C.muted);rk.Font=Enum.Font.BuilderSansBold
        local dot=UI.make('Frame',r,{Name='TeamColor',BackgroundColor3=t.color,BorderSizePixel=0,ZIndex=27});UI.box(dot,34,(rowH-2-12)/2,12,12);Style.round(dot,6)
        local nw=w-30-28-136
        local name=caption(r,'Name',string.format('%s  %d명',t.name,t.alive),58,(rowH-24)/2,nw,me and C.accent or C.ink);name.Font=Enum.Font.BuilderSansBold
        if not phone then
            local track=UI.make('Frame',r,{Name='LandBar',BackgroundColor3=Style.colors.line,BorderSizePixel=0,ZIndex=27});UI.box(track,w-178,(rowH-2)/2-2,44,4);Style.round(track,2)
            local fill=UI.make('Frame',track,{Name='Fill',BackgroundColor3=t.color,BorderSizePixel=0,ZIndex=28,Size=UDim2.new(math.clamp(t.share/math.max(.0001,(list[1]and list[1].share or 1)),0,1),0,1,0)});Style.round(fill,2)
        end
        local v=t.share*100
        local l=caption(r,'Land',string.format(v>=10 and '%.1f%%'or '%.2f%%',v),w-130,(rowH-24)/2,64,C.ink);l.TextXAlignment=Enum.TextXAlignment.Right
        local tr=caption(r,'Troops',UI.troops(t.troops),w-62,(rowH-24)/2,56,C.ink);tr.TextXAlignment=Enum.TextXAlignment.Right
        r.InputBegan:Connect(function(i)
            if (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch)and self.a.focusTile then
                for _,f in ipairs(self.sorted)do if f.team==t.team and f.kind~='BOT'and not f.eliminated and (f.tiles or 0)>0 then
                    if f.labelTile then Step.step('hud','rankFocus',{value=rank,item='team'});self.a.focusTile(f.labelTile)end;break
                end end
            end
        end)
        return r
    end
    for i,t in ipairs(list)do if not t.mine then row(body,t,i,y,false);y+=rowH end end
    body.CanvasSize=UDim2.fromOffset(0,y+4)
    for _,o in ipairs(self.pinned:GetChildren())do o:Destroy()end
    if mine then row(self.pinned,list[mine],mine,0,true)end
    return mine and rowH+6 or 0
end
function M:drawDiplomacy(w)
    local s=self.state;local d=s.diplomacy or {};local body=self.body;local y=0;local touch=self.touch
    local bh=touch and 48 or 36;local send=self.send
    self.head.title.Text='외교';self.head.sub.Text=''
    local enemies,blocked=0,0
    for _,f in ipairs(self.sorted)do if f.id~=1 and f.kind~='BOT'and not f.allied and not f.teammate and (f.tiles or 0)>0 then enemies+=1;if f.embargoed then blocked+=1 end end end
    local stopped=enemies>0 and blocked==enemies
    caption(body,'TradeTitle','적과 교역',0,y+(bh-22)/2,w-150,C.ink)
    local seg=UI.make('Frame',body,{Name='Trade',BackgroundColor3=Style.colors.chip,BorderSizePixel=0,ZIndex=26});UI.box(seg,w-140,y,140,bh+4);Style.round(seg,8);Style.line(seg,Style.colors.line,1)
    for i,k in ipairs({{'TradeOn','계속',false},{'TradeOff','중단',true}})do
        local b=UI.button(seg,k[1],k[2],function()Step.step('match','embargoAll',{item=k[3]and 'stop'or 'resume'});send('embargoAll',k[3])end)
        UI.box(b,2+(i-1)*68,2,66,bh);b.TextSize=14;Style.round(b,6);b.ZIndex=27
        local on=stopped==k[3];b.BackgroundColor3=on and Style.colors.cell:Lerp(C.ink,.12)or Style.colors.chip;b.BackgroundTransparency=on and 0 or 1;b.TextColor3=on and C.ink or C.muted
    end
    y+=bh+16
    local function section(name,text)caption(body,name,text,0,y,w,C.muted);y+=26 end
    local function nation(parent,f,one,width)
        local rh=bh+12;M.face(parent,f and f.userId,32,parent.BackgroundTransparency>=1 and 0 or 10,(rh-32)/2)
        local x=parent.BackgroundTransparency>=1 and 42 or 50
        local n=caption(parent,'Name',L.nation(f),x,one and (rh-22)/2 or rh/2-21,width-x,C.ink);n.Font=Enum.Font.BuilderSansBold;n:SetAttribute('LocalizationSkip',true)
        UI.fit(n,width-x,14,11)
        return n
    end
    local function action(parent,name,text,x,yy,bw,fn,primary,color)
        local b=UI.button(parent,name,text,fn,primary);UI.box(b,x,yy,bw,bh);b.TextSize=14;Style.round(b,6);b.ZIndex=parent.ZIndex+1
        if not primary then b.BackgroundColor3=Style.colors.chip;Style.line(b,color or Style.colors.line,1);b.TextColor3=color or C.ink end
        UI.enabled(b,s.phase=='playing'and not s.paused);return b
    end
    local incoming=d.incoming or {}
    if #incoming>0 then
        section('IncomingTitle',string.format('받은 요청 %d',#incoming))
        for _,r in ipairs(incoming)do
            local card=UI.make('Frame',body,{Name='Request'..r.from,BackgroundColor3=Style.colors.rateBg,BackgroundTransparency=.3,BorderSizePixel=0,ZIndex=26});UI.box(card,0,y,w,bh+12);Style.round(card,8);Style.line(card,C.accent,1,.5)
            local edge=require(script.Parent.EdgeMask).fit(UI.make('Frame',card,{Name='Edge',BackgroundColor3=C.accent,BorderSizePixel=0,ZIndex=27}));UI.box(edge,0,8,3,bh-4)
            nation(card,self.factions[r.from]or {name=r.name},false,w-170)
            local left=math.max(0,math.ceil(((r.expires or 0)-(s.tick or 0))/10))
            caption(card,'Detail',string.format('동맹 요청 %d초',left),50,(bh+12)/2+1,w-220,C.muted)
            local id=r.from;local bw=touch and 70 or 64
            action(card,'Reject','거절',w-bw-6,6,bw,function()send('alliance','reject',id)end)
            action(card,'Accept','수락',w-bw*2-12,6,bw,function()send('alliance','accept',id)end,true)
            y+=bh+18
        end
    end
    local allies={};for _,f in ipairs(self.sorted)do if f.allied and not f.teammate and f.id~=1 and (f.tiles or 0)>0 then table.insert(allies,f)end end
    if #allies>0 then
        section('AlliesTitle',string.format('동맹 %d',#allies))
        local total=((s.settings and s.settings.customAllianceDuration)or 5)*600
        for _,f in ipairs(allies)do
            local rowF=UI.make('Frame',body,{Name='Ally'..f.id,BackgroundTransparency=1,ZIndex=26});UI.box(rowF,0,y,w,bh+12)
            local bw=touch and 56 or 64;local x=w-bw
            local left=math.max(0,(f.allianceExpires or 0)-(s.tick or 0));local ending=left<=300
            local id=f.id
            action(rowF,'SendTroops','병력',x,6,bw,function()send('support','troops',id)end);x-=bw+6
            action(rowF,'SendGold','골드',x,6,bw,function()send('support','gold',id)end);x-=bw+6
            if ending then action(rowF,'Extend','연장',x-4,6,bw+4,function()send('alliance','extend',id)end,false,C.gold);x-=bw+10 end
            local n=nation(rowF,f,false,x-6);n.Size=UDim2.fromOffset(x-56,20)
            local track=UI.make('Frame',rowF,{Name='TimeLeft',BackgroundColor3=Style.colors.line,BorderSizePixel=0,ZIndex=27});UI.box(track,42,(bh+12)/2+10,math.max(30,x-104),4);Style.round(track,2)
            local fill=UI.make('Frame',track,{Name='Fill',BackgroundColor3=ending and C.gold or SKY,BorderSizePixel=0,ZIndex=28,Size=UDim2.new(math.clamp(left/math.max(1,total),0,1),0,1,0)});Style.round(fill,2)
            local sec=math.ceil(left/10);caption(rowF,'Left',string.format('%d:%02d',sec//60,sec%60),math.max(84,x-56),(bh+12)/2+1,52,ending and C.gold or C.muted)
            local wait=math.ceil(f.donationAvailableIn or 0)
            for _,b in ipairs(rowF:GetChildren())do if b.Name=='SendGold'then UI.enabled(b,b.Active and f.canDonateGold and wait<=0)elseif b.Name=='SendTroops'then UI.enabled(b,b.Active and f.canDonateTroops and wait<=0)end end
            y+=bh+12
        end
    end
    local outgoing=d.outgoing or {}
    if #outgoing>0 then
        section('OutgoingTitle',string.format('보낸 요청 %d',#outgoing))
        for _,r in ipairs(outgoing)do
            local rowF=UI.make('Frame',body,{Name='Sent'..r.to,BackgroundTransparency=1,ZIndex=26});UI.box(rowF,0,y,w,bh+12)
            nation(rowF,self.factions[r.to]or {name=r.name},true,w-130)
            local wl=caption(rowF,'Waiting','응답 기다리는 중',w-128,(bh+12-22)/2,126,C.muted);wl.TextXAlignment=Enum.TextXAlignment.Right
            y+=bh+12
        end
    end
    local others={};local asked={};for _,r in ipairs(outgoing)do asked[r.to]=true end;for _,r in ipairs(incoming)do asked[r.from]=true end
    for _,f in ipairs(self.sorted)do if f.id~=1 and not f.allied and not f.teammate and f.kind~='BOT'and (f.tiles or 0)>0 and not asked[f.id]then table.insert(others,f)end end
    if #others>0 then
        section('OthersTitle',string.format('다른 국가 %d',#others))
        local off=s.settings and (s.settings.disableAlliances or s.settings.customAllianceDuration==0)
        for _,f in ipairs(others)do
            local rowF=UI.make('Frame',body,{Name='Nation'..f.id,BackgroundTransparency=1,ZIndex=26});UI.box(rowF,0,y,w,bh+12)
            local bw=touch and 96 or 88
            local v=(f.share or 0)*100;local share=string.format(v>=10 and '%.1f%%'or '%.2f%%',v)
            if self.r.phone then
                nation(rowF,f,false,w-bw-8);caption(rowF,'Share',share,42,(bh+12)/2+1,w-bw-50,C.muted)
            else
                nation(rowF,f,true,w-bw-62)
                local sl=caption(rowF,'Share',share,w-bw-58,(bh+12-22)/2,50,C.muted);sl.TextXAlignment=Enum.TextXAlignment.Right
            end
            local id=f.id;local b=action(rowF,'RequestAlliance','동맹 요청',w-bw,6,bw,function()send('alliance','request',id)end)
            if off then UI.enabled(b,false)end
            local more=UI.button(rowF,'Detail','',function()self.a.tactical:open(id)end);more.BackgroundTransparency=1;UI.box(more,0,0,w-bw-8,bh+12);more.ZIndex=26
            y+=bh+12
        end
    end
    if y<bh+40 then caption(body,'Empty','지도에서 상대 땅을 누르면 동맹을 요청할 수 있어요.',0,y,w,C.muted);y+=28 end
    body.CanvasSize=UDim2.fromOffset(0,y+4)
    return 0
end
function M:signatureOf()
    local s=self.state;local parts={self.page,self.r and self.r.w,tostring(self.touch),s.phase,tostring(s.paused)}
    for _,f in ipairs(self.sorted)do table.insert(parts,table.concat({f.id,(f.tiles or 0)>0 and 1 or 0,tostring(f.allied),tostring(f.embargoed),tostring(f.canDonateGold),tostring(f.canDonateTroops),math.ceil(f.donationAvailableIn or 0)>0 and 1 or 0},','))end
    if self.page=='ranks'then table.insert(parts,s.tick and s.tick//10 or 0);table.insert(parts,self.rankMode or 'players')
    else
        local d=s.diplomacy or {};for _,r in ipairs(d.incoming or {})do table.insert(parts,'i'..r.from..':'..math.ceil(((r.expires or 0)-(s.tick or 0))/10))end
        for _,r in ipairs(d.outgoing or {})do table.insert(parts,'o'..r.to)end
        for _,f in ipairs(self.sorted)do if f.allied then table.insert(parts,'a'..math.ceil(((f.allianceExpires or 0)-(s.tick or 0))/10))end end
    end
    return table.concat(parts,'|')
end
function M:draw()
    if not self.frame.Visible or not self.state or not self.r then return end
    local sig=self:signatureOf();if sig==self.signature then return end;self.signature=sig
    local scroll=self.body.CanvasPosition
    for _,o in ipairs(self.body:GetChildren())do o:Destroy()end
    for _,o in ipairs(self.pinned:GetChildren())do o:Destroy()end
    local w=self.r.w-32;self.drawnW=self.r.w
    local pinned=self.page=='ranks'and self:drawRanks(w)or self:drawDiplomacy(w)
    local top=self.top or 56
    UI.box(self.body,16,top,w+6,self.r.h-top-8-pinned);UI.box(self.pinned,16,self.r.h-8-pinned+4,w,pinned)
    self.body.CanvasPosition=scroll
    M.placeHeader(self.head,self.r.w,self.touch)
end

function M:cards(w,h,obscured)
    local a=self.a;local inbox=a.inbox;local renew=a.renewal
    local list={}
    if inbox and (inbox.request or inbox.expired)and inbox.panel.Visible then table.insert(list,inbox.panel)end
    if renew and renew.current and renew.panel.Visible then table.insert(list,renew.panel)end
    local Invite=require(script.Parent.InviteToast)
    if Invite.current and Invite.current.Parent then if Invite.paint then Invite.paint(w)end;table.insert(list,Invite.current)end
    local phone=Placement.phone(w,h,self.touch)
    local status=a.matchStatus and a.matchStatus.frame
    local y=phone and 52 or 108
    if status and status.Visible and not phone then y=math.max(y,status.Position.Y.Offset+status.Size.Y.Offset+(a.matchStatus.speedPill and a.matchStatus.speedPill.Visible and 34 or 8))end
    local more=#list-1
    for i,p in ipairs(list)do
        p.Visible=i==1 and not obscured
        if i==1 then p.Position=UDim2.fromOffset(phone and 8 or 12,y)end
    end
    if inbox and inbox.peek then inbox.peek.Visible=false end
    self.more=self.more or (function()
        local b=UI.make('TextLabel',self.panel,{Name='CardsMore',Text='',TextSize=13,Font=Enum.Font.BuilderSansBold,TextColor3=C.ink,BackgroundColor3=Style.colors.cell,BorderSizePixel=0,ZIndex=30,Visible=false})
        Style.round(b,11);Style.line(b,Style.colors.line,1);b:SetAttribute('AllowOverlap',true);b:SetAttribute('LocalizationSkip',true);return b
    end)()
    local top=list[1];local count=more+(inbox and inbox.count and math.max(0,inbox.count-1)or 0)
    self.more.Visible=top~=nil and top.Visible and count>0
    if self.more.Visible then self.more.Text='+'..count;UI.box(self.more,top.Position.X.Offset+top.Size.X.Offset-30,y-9,34,22)end
    if a.chat and a.chat.feed and top and top.Visible then a.chat.feed.Visible=false end
    return top and top.Visible
end
function M:qa(value)
    local a=self.a
    if value=='close'then self:closeAll()
    elseif value=='ranks'or value=='diplomacy'then self:open(value)
    elseif value=='log'then a.eventLog:toggle(true)
    elseif value=='messages'or value=='emoji'or value=='chat'or value=='motion'then a.chat.openQuick(value)end
    return {page=self.page,quick=a.quick.frame.Visible and a.quick.mode,log=a.eventLog.panel.Visible,detail=a.tactical.frame.Visible,any=self:any()}
end
return M
