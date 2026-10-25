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
function M.banner(parent,name,text,y,w,h)
    if M.touch()then h=math.max(h or 40,48)end
    local b=UI.make('Frame',parent,{Name=name,BackgroundColor3=Style.colors.chip,BorderSizePixel=0,ZIndex=parent.ZIndex+1})
    Style.round(b,8);Style.line(b,Style.colors.line,1);UI.box(b,0,y,w,h or 40)
    local l=UI.label(b,'Text',text,13,C.muted);l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd;UI.box(l,12,0,w-24,h or 40);l.ZIndex=b.ZIndex+1
    return b
end
local function caption(parent,name,text,x,y,w,color)
    local l=UI.label(parent,name,text,13,color or C.muted);l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd;l.ZIndex=parent.ZIndex+1;UI.box(l,x,y,w,22);return l
end
M.caption=caption

local K
local function kit()K=K or require(script.Parent.Kit20);return K end
function M.v2()local ok,H=pcall(require,script.Parent.Hud20);return ok and type(H)=='table'and H.ENABLED==true end
function M.inset()local v=0;pcall(function()v=game:GetService('GuiService'):GetGuiInset().Y/(UI.scale or 1)end);return v end
function M.format(w,h,touch)
    if touch==nil then touch=M.touch()end
    if not touch or Placement.tablet(w,h,touch)then return 'pc'end
    return h>w and 'pt'or 'ph'
end
function M.rect20(w,h,tall)
    local fmt=M.format(w,h);local top=M.inset()
    if fmt=='pc'then
        local sh=math.max(200,math.min(tall and 462 or 380,h-12-104-8))
        return {x=w-12-400,y=0,w=400,h=sh,fmt=fmt}
    elseif fmt=='ph'then
        local sw=math.min(300,w-12-36-8-12)
        return {x=w-12-36-8-sw,y=8-top,w=sw,h=math.max(160,h+top-16),fmt=fmt,phone=true}
    end
    local sh=math.min(tall and 380 or 360,h-40)
    return {x=0,y=h-sh,w=w,h=sh,fmt=fmt,phone=true,portrait=true}
end
function M.paint20(frame,portrait)
    kit()
    for _,s in ipairs(frame:GetChildren())do if s:IsA('UIStroke')and s.Name~='Stroke20'then s.Enabled=false end end
    frame.BackgroundColor3=Color3.fromRGB(12,17,24);frame.BackgroundTransparency=.03
    K.round(frame,portrait and 16 or 12);K.stroke(frame,K.colors.line,1,.1,true)
end
function M.place20(frame,r)
    local pos=UDim2.fromOffset(math.floor(r.x+.5),math.floor(r.y+.5))
    frame.Size=UDim2.fromOffset(math.floor(r.w+.5),math.floor(r.h+.5)+(r.portrait and 16 or 0))
    frame:SetAttribute('Home20',pos);frame:SetAttribute('Sheet20Fmt',r.fmt)
    if frame:GetAttribute('Moving20')==nil then frame.Position=pos end
end
local function slide(frame)local pt=frame:GetAttribute('Sheet20Fmt')=='pt';return pt and 0 or 24,pt and 24 or 0 end
function M.motion20(frame)
    kit()
    if frame:GetAttribute('Motion20')then return end;frame:SetAttribute('Motion20',true)
    frame:GetPropertyChangedSignal('Visible'):Connect(function()
        if not M.v2()or not frame.Visible then return end
        local moving=frame:GetAttribute('Moving20')
        if moving=='in'or moving=='out'then return end
        frame:SetAttribute('Shown20',false);local dx,dy=slide(frame);K.appear(frame,{dx=dx,dy=dy,t=.16})
    end)
end
function M.show20(frame)
    if not M.v2()then frame.Visible=true;return end
    kit()
    if frame.Visible and frame:GetAttribute('Moving20')=='out'then local dx,dy=slide(frame);K.appear(frame,{dx=dx,dy=dy,t=.16});return end
    frame.Visible=true
end
function M.hide20(frame)
    if not(M.v2()and frame.Visible)then frame.Visible=false;return end
    kit();local dx,dy=slide(frame);K.leave(frame,{dx=dx,dy=dy,t=.10})
end
function M.closing(frame)return frame:GetAttribute('Moving20')=='out'end
local heads=setmetatable({},{__mode='k'})
function M.head20(frame,onClose)
    kit()
    local v=frame:FindFirstChild('Head20')
    if v then return v end
    v=K.make('Frame',frame,{Name='Head20',BackgroundTransparency=1,BorderSizePixel=0,ZIndex=frame.ZIndex+1})
    K.make('Frame',v,{Name='Rule',BackgroundColor3=K.colors.line,BorderSizePixel=0,ZIndex=v.ZIndex})
    local x=K.button(v,'Close20',{kind='none',icon='x',iconSize=18},onClose);x.iconColorFixed=true;x.iconImage.ImageColor3=K.colors.muted
    x.button.ZIndex=v.ZIndex+2;x.face.ZIndex=v.ZIndex+2;x.iconImage.ZIndex=v.ZIndex+3
    heads[frame]=x
    return v
end
function M.placeHead20(frame,w)
    local v=M.head20(frame);local x=heads[frame]
    K.box(v,0,0,w,49);K.box(v.Rule,1,48,w-2,1)
    x:place(w-45,3,44,44)
    return v,x
end
function M.chip20(parent,name,text,on,pad,fn,skip)
    kit()
    local tw=K.width(skip and text or L.text(text),12)
    local w=tw+(pad or 10)*2
    local b=K.button(parent,name,{kind='none',text=text,size=12,weight=700,hit=36},fn)
    if skip then b.label:SetAttribute('LocalizationSkip',true)end
    b.face.BackgroundTransparency=0;b.face.BackgroundColor3=on and K.colors.ink or K.colors.raised;K.round(b.face,'pill')
    b.label.TextColor3=on and K.colors.bg or K.colors.muted;b.button:SetAttribute('On',on==true)
    b.w20=w;return b,w
end
function M.fill20(b,padLeft)
    local l=b.label;if not l then return end
    local x=b.iconImage and b.iconImage.Visible and(b.iconImage.Position.X.Offset+b.iconSize+b.gap)or padLeft or 0
    l.Position=UDim2.fromOffset(x,0);l.Size=UDim2.new(1,-x-(padLeft or 0),1,0)
    l.TextXAlignment=padLeft and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
end

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
    if self.frame.Visible and not M.closing(self.frame)then Step.step('hud','sheetClose',{item=self.page})end
    M.hide20(self.frame);self.page=nil
end
function M:open(page)
    if self.frame.Visible and not M.closing(self.frame)and self.page==page then self:close();return end
    Step.step('hud','sheetOpen',{item=page});self.page=page;M.show20(self.frame)
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
    if M.v2()then
        local r=M.rect20(w,h,true);self.r=r
        M.paint20(self.frame,r.portrait);M.place20(self.frame,r);M.motion20(self.frame)
        M.head20(self.frame,function()self:close()end);M.placeHead20(self.frame,r.w)
        self.head.close.Visible=false
        local t=self.head.title;t.TextSize=16;if K.fonts[800]then t.FontFace=K.fonts[800]end;t.TextColor3=K.colors.ink
        local tw=math.min(K.width(t.Text,16,t),r.w-140);K.box(t,15,0,tw+4,48);t.ZIndex=self.frame.ZIndex+2
        local sub=self.head.sub;sub.TextSize=12;sub.TextColor3=K.colors.muted;K.box(sub,15+tw+10,0,r.w-tw-90,48);sub.ZIndex=self.frame.ZIndex+2
        self.top=57
        if self.frame.Visible and self.drawnW~=r.w then self.signature=nil;self:draw()end
        return
    end
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
    for _,f in ipairs(self.sorted)do if f.kind~='BOT'and(f.tiles or 0)>0 and not f.eliminated then table.insert(list,f);if f.id==1 then mine=#list end end end
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
    if y<bh+40 then caption(body,'Empty','상대 땅 눌러 동맹 요청',0,y,w,C.muted);y+=28 end
    body.CanvasSize=UDim2.fromOffset(0,y+4)
    return 0
end
local function rowH20(r)return r.fmt=='ph'and 40 or 44 end
local function row20(parent,name,y,w,h,band,dim)
    local parts=band and {{p=3/w,color=dim and band:Lerp(K.colors.panel,.5)or band}}or {}
    local r=K.fillBar(parent,name,{parts=parts,track=K.colors.panel,r=8}).frame
    K.box(r,0,y,w,h);r.ZIndex=parent.ZIndex+1;r.Active=true;return r
end
local function word20(parent,name,text,size,color,weight,x,y,w,h,align)
    local l=K.text(parent,name,text,size,color,weight,align);l.ZIndex=parent.ZIndex+1;K.box(l,x,y,w,h);return l
end
local function num20(parent,name,text,size,color,x,y,w,h,align)
    local l=K.num(parent,name,text,size,color,align);l.ZIndex=parent.ZIndex+1;K.box(l,x,y,w,h);return l
end
local function face20(parent,f,size,x,y,ring)
    local id=f and f.userId;local a=K.avatar(parent,'Face',id and id>0 and id or nil,size,ring,ring and 2 or nil)
    a.ZIndex=parent.ZIndex+1;a.Position=UDim2.fromOffset(x,y);return a
end
local function act20(parent,name,text,kind,x,h,bw,on,fn)
    local b=K.button(parent,name,{kind=(kind=='ally'or kind=='allyo')and 'none'or kind,text=text,size=13,weight=800,hit=h},fn)
    b:setEnabled(on)
    if on and kind=='ally'then b.face.BackgroundTransparency=0;b.face.BackgroundColor3=K.colors.ally;b.label.TextColor3=K.colors.bg
    elseif on and kind=='allyo'then
        b.face.BackgroundTransparency=.92;b.face.BackgroundColor3=K.colors.ally;b.faceStroke.Enabled=true;b.faceStroke.Color=K.colors.ally;b.faceStroke.Transparency=.3
        b.baseStroke=K.colors.ally;b.label.TextColor3=K.colors.ally
    end
    b:place(x,math.floor((h-30)/2),bw,30);b.button.ZIndex=parent.ZIndex+2;b.face.ZIndex=parent.ZIndex+2;M.fill20(b);if b.label then b.label.ZIndex=parent.ZIndex+3 end
    return b
end
local function columns20(body,y,w,second,landX)
    local cols=K.make('Frame',body,{Name='Columns',BackgroundTransparency=1,BorderSizePixel=0,ZIndex=body.ZIndex+1});K.box(cols,0,y,w,20)
    local m=K.colors.muted
    word20(cols,'Rank','#',11,m,700,10,0,24,20,Enum.TextXAlignment.Center);word20(cols,'Name',second,11,m,700,44,0,120,20)
    word20(cols,'Land','영토',11,m,700,landX,0,56,20,Enum.TextXAlignment.Right);word20(cols,'Troops','병력',11,m,700,w-62,0,52,20,Enum.TextXAlignment.Right)
end
local function focusRow(row,fn)
    row.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then fn()end end)
end
local function share(v)v=(v or 0)*100;return string.format(v>=10 and '%.1f%%'or '%.2f%%',v)end
M.RANK_PIN=5
function M:drawRanks20(w)
    local s=self.state;local list={};local mine
    for _,f in ipairs(self.sorted)do if f.kind~='BOT'and(f.tiles or 0)>0 and not f.eliminated then table.insert(list,f);if f.id==1 then mine=#list end end end
    self.head.title.Text='순위';self.head.sub.Text=string.format('%d명',#list)
    local r=self.r;local phone=r.fmt~='pc';local y=0;local body=self.body;local rh=rowH20(r)
    local teamGame=Teams.active(s);if not teamGame then self.rankMode=nil end
    if teamGame then
        local x=0
        for _,k in ipairs({{'players','개인'},{'teams','팀'}})do
            local b,bw=M.chip20(body,'RankTab_'..k[1],k[2],(self.rankMode or 'players')==k[1],12,function()
                if (self.rankMode or 'players')==k[1]then return end
                self.rankMode=k[1];Step.step('hud','rankMode',{item=k[1]});self.signature=nil;self.body.CanvasPosition=Vector2.zero;self:draw()
            end)
            b:place(x,5,bw,30);M.fill20(b);b.button.ZIndex=body.ZIndex+2;x+=bw+6
        end
        y+=40
        if self.rankMode=='teams'then return self:drawTeams20(w,y)end
    end
    if not phone and s.player then
        local p=s.player
        word20(body,'Economy',string.format('내 생산  병력 +%s/s  골드 +%s/s',UI.troops(p.growth or 0),UI.number(p.income or 0)),12,K.colors.muted,700,2,y,w-4,24)
        y+=28
    end
    local landX=w-118;columns20(body,y,w,'지휘관',landX);y+=22
    local Colors=require(script.Parent.FactionColors);local top=list[1]and list[1].share or 1
    local function row(parent,f,rank,yy,me)
        local band=me and K.colors.accent or f.teammate and K.team or f.allied and K.colors.ally or nil
        local rw=row20(parent,me and 'Mine'or 'Row'..rank,yy,w,rh,band)
        if me then K.stroke(rw,K.colors.accent,1,.55,true)end
        num20(rw,'Rank',tostring(rank),13,me and K.colors.accent or K.colors.muted,10,0,24,rh,Enum.TextXAlignment.Center)
        face20(rw,f,24,42,math.floor((rh-24)/2),Colors.get(f.id,f.kind))
        local right=phone and landX-8 or landX-56;local tag=not me and relation(f);local chip,cw
        if tag then chip,cw=K.chip(rw,'Ally',L.text(tag),f.teammate and 'team'or 'ally',{size=11,height=18});chip.ZIndex=rw.ZIndex+1;chip.Text.ZIndex=rw.ZIndex+2;chip.Text:SetAttribute('LocalizationSkip',true)end
        local room=right-74-(cw and cw+6 or 0)
        local name=word20(rw,'Name',me and '나'or L.nation(f),13,me and K.colors.accent or K.colors.ink,800,74,0,room,rh)
        name:SetAttribute('LocalizationSkip',not me);K.fit(name,room,13,11)
        if chip then chip.Position=UDim2.fromOffset(74+math.min(K.width(name.Text,name.TextSize,name)+2,room)+6,math.floor((rh-18)/2))end
        if not phone then
            local bar=K.fillBar(rw,'LandBar',{p=math.clamp((f.share or 0)/math.max(.0001,top),0,1),fill=me and K.colors.accent or K.colors.muted,track=K.colors.line})
            K.box(bar.frame,landX-46,math.floor(rh/2)-2,40,4);bar.frame.ZIndex=rw.ZIndex+1
        end
        num20(rw,'Land',share(f.share),13,K.colors.ink,landX,0,56,rh,Enum.TextXAlignment.Right)
        num20(rw,'Troops',UI.troops(f.troops or 0),13,K.colors.ink,w-62,0,52,rh,Enum.TextXAlignment.Right)
        focusRow(rw,function()if f.labelTile and self.a.focusTile then Step.step('hud','rankFocus',{value=rank});self.a.focusTile(f.labelTile)end end)
        return rw
    end
    local pin=mine~=nil and mine>M.RANK_PIN
    for i,f in ipairs(list)do if f.id~=1 or not pin then row(body,f,i,y,f.id==1);y+=rh+4 end end
    body.CanvasSize=UDim2.fromOffset(0,y+4)
    for _,o in ipairs(self.pinned:GetChildren())do o:Destroy()end
    if pin then row(self.pinned,list[mine],mine,0,true)end
    return pin and rh+6 or 0
end
function M:drawTeams20(w,y)
    local s=self.state;local list=Teams.build(s,self.sorted);local mine
    for i,t in ipairs(list)do if t.mine then mine=i end end
    self.head.title.Text='순위';self.head.sub.Text=string.format('%d개 팀',#list)
    local r=self.r;local phone=r.fmt~='pc';local body=self.body;local rh=rowH20(r)
    local landX=w-118;columns20(body,y,w,'팀',landX);y+=22
    local top=list[1]and list[1].share or 1
    local function row(parent,t,rank,yy,me)
        local rw=row20(parent,me and 'MyTeam'or 'Team'..rank,yy,w,rh,t.color)
        if me then K.stroke(rw,K.colors.accent,1,.55,true)end
        num20(rw,'Rank',tostring(rank),13,me and K.colors.accent or K.colors.muted,10,0,24,rh,Enum.TextXAlignment.Center)
        local dot=K.make('Frame',rw,{Name='TeamColor',BackgroundColor3=t.color,BorderSizePixel=0,ZIndex=rw.ZIndex+1});K.round(dot,'pill');K.box(dot,48,math.floor((rh-12)/2),12,12)
        local room=(phone and landX-8 or landX-56)-70
        local name=word20(rw,'Name',string.format('%s  %d명',t.name,t.alive),13,me and K.colors.accent or K.colors.ink,800,70,0,room,rh);K.fit(name,room,13,11)
        if not phone then
            local bar=K.fillBar(rw,'LandBar',{p=math.clamp(t.share/math.max(.0001,top),0,1),fill=t.color,track=K.colors.line})
            K.box(bar.frame,landX-46,math.floor(rh/2)-2,40,4);bar.frame.ZIndex=rw.ZIndex+1
        end
        num20(rw,'Land',share(t.share),13,K.colors.ink,landX,0,56,rh,Enum.TextXAlignment.Right)
        num20(rw,'Troops',UI.troops(t.troops),13,K.colors.ink,w-62,0,52,rh,Enum.TextXAlignment.Right)
        focusRow(rw,function()
            if not self.a.focusTile then return end
            for _,f in ipairs(self.sorted)do if f.team==t.team and f.kind~='BOT'and not f.eliminated and (f.tiles or 0)>0 then
                if f.labelTile then Step.step('hud','rankFocus',{value=rank,item='team'});self.a.focusTile(f.labelTile)end;break
            end end
        end)
        return rw
    end
    local pin=mine~=nil and mine>M.RANK_PIN
    for i,t in ipairs(list)do if not t.mine or not pin then row(body,t,i,y,t.mine==true);y+=rh+4 end end
    body.CanvasSize=UDim2.fromOffset(0,y+4)
    for _,o in ipairs(self.pinned:GetChildren())do o:Destroy()end
    if pin then row(self.pinned,list[mine],mine,0,true)end
    return pin and rh+6 or 0
end
function M:drawDiplomacy20(w)
    local s=self.state;local d=s.diplomacy or {};local body=self.body;local y=0;local send=self.send
    local r=self.r;local rh=rowH20(r);local touch=self.touch;local playing=s.phase=='playing'and not s.paused
    local ink,muted=K.colors.ink,K.colors.muted
    self.head.title.Text='외교';self.head.sub.Text=''
    local enemies,blocked=0,0
    for _,f in ipairs(self.sorted)do if f.id~=1 and f.kind~='BOT'and not f.allied and not f.teammate and (f.tiles or 0)>0 then enemies+=1;if f.embargoed then blocked+=1 end end end
    local stopped=enemies>0 and blocked==enemies
    local sh=touch and 42 or 36
    word20(body,'TradeTitle','적과 교역',13,ink,800,2,y,w-150,sh)
    local seg=K.segment(body,'Trade',{{'on','계속'},{'off','중단'}},stopped and 'off'or 'on',function(id)
        local stop=id=='off';Step.step('match','embargoAll',{item=stop and 'stop'or 'resume'});send('embargoAll',stop)
    end,{size=13})
    seg:place(w-140,y,140,sh);seg.frame.ZIndex=body.ZIndex+1
    y+=sh+14
    local function section(name,text)word20(body,name,text,12,muted,700,2,y,w-4,22);y+=24 end
    local function name2(rw,f,width)
        local n=word20(rw,'Name',L.nation(f),13,ink,800,48,math.floor(rh/2)-17,width,18);n:SetAttribute('LocalizationSkip',true);K.fit(n,width,13,11);return n
    end
    local incoming=d.incoming or {}
    if #incoming>0 then
        section('IncomingTitle',string.format('받은 요청 %d',#incoming))
        for _,q in ipairs(incoming)do
            local rw=row20(body,'Request'..q.from,y,w,rh,K.colors.ally)
            local f=self.factions[q.from]or {name=q.name};face20(rw,f,28,12,math.floor((rh-28)/2))
            local id=q.from;local bw=touch and 64 or 60
            act20(rw,'Reject','거절','plain',w-bw-6,rh,bw,playing,function()send('alliance','reject',id)end)
            act20(rw,'Accept','수락','ally',w-bw*2-12,rh,bw,playing,function()send('alliance','accept',id)end)
            local width=w-bw*2-12-8-48;name2(rw,f,width)
            local left=math.max(0,math.ceil(((q.expires or 0)-(s.tick or 0))/10))
            word20(rw,'Detail',string.format('동맹 요청 %d초',left),11,muted,700,48,math.floor(rh/2)+1,width,15)
            y+=rh+4
        end
        y+=6
    end
    local allies={};for _,f in ipairs(self.sorted)do if f.allied and not f.teammate and f.id~=1 and (f.tiles or 0)>0 then table.insert(allies,f)end end
    if #allies>0 then
        section('AlliesTitle',string.format('동맹 %d',#allies))
        local total=((s.settings and s.settings.customAllianceDuration)or 5)*600
        for _,f in ipairs(allies)do
            local rw=row20(body,'Ally'..f.id,y,w,rh,K.colors.ally);face20(rw,f,28,12,math.floor((rh-28)/2))
            local left=math.max(0,(f.allianceExpires or 0)-(s.tick or 0));local ending=left<=300
            local id=f.id;local bw=touch and 56 or 52;local x=w-bw-6
            local ready=playing and math.ceil(f.donationAvailableIn or 0)<=0
            act20(rw,'SendTroops','병력','plain',x,rh,bw,ready and f.canDonateTroops==true,function()send('support','troops',id)end);x-=bw+6
            act20(rw,'SendGold','골드','plain',x,rh,bw,ready and f.canDonateGold==true,function()send('support','gold',id)end);x-=bw+6
            if ending then act20(rw,'Extend','연장','allyo',x-4,rh,bw+4,playing,function()send('alliance','extend',id)end);x-=bw+10 end
            local width=math.max(40,x-8-48);name2(rw,f,width)
            local sec=math.ceil(left/10)
            local bar=K.fillBar(rw,'TimeLeft',{p=math.clamp(left/math.max(1,total),0,1),fill=ending and muted or K.colors.ally,track=K.colors.line})
            K.box(bar.frame,48,math.floor(rh/2)+6,math.max(16,width-44),4);bar.frame.ZIndex=rw.ZIndex+1
            num20(rw,'Left',string.format('%d:%02d',sec//60,sec%60),11,ending and ink or muted,48+width-40,math.floor(rh/2),40,15,Enum.TextXAlignment.Right)
            y+=rh+4
        end
        y+=6
    end
    local outgoing=d.outgoing or {}
    if #outgoing>0 then
        section('OutgoingTitle',string.format('보낸 요청 %d',#outgoing))
        for _,q in ipairs(outgoing)do
            local rw=row20(body,'Sent'..q.to,y,w,rh,K.colors.ally,true)
            local f=self.factions[q.to]or {name=q.name};face20(rw,f,28,12,math.floor((rh-28)/2))
            local n=word20(rw,'Name',L.nation(f),13,ink,800,48,0,w-48-140,rh);n:SetAttribute('LocalizationSkip',true);K.fit(n,w-48-140,13,11)
            word20(rw,'Waiting','응답 기다리는 중',12,muted,700,w-136,0,124,rh,Enum.TextXAlignment.Right)
            y+=rh+4
        end
        y+=6
    end
    local others={};local asked={};for _,q in ipairs(outgoing)do asked[q.to]=true end;for _,q in ipairs(incoming)do asked[q.from]=true end
    for _,f in ipairs(self.sorted)do if f.id~=1 and not f.allied and not f.teammate and f.kind~='BOT'and (f.tiles or 0)>0 and not asked[f.id]then table.insert(others,f)end end
    if #others>0 then
        section('OthersTitle',string.format('다른 국가 %d',#others))
        local off=s.settings and (s.settings.disableAlliances or s.settings.customAllianceDuration==0)
        for _,f in ipairs(others)do
            local rw=row20(body,'Nation'..f.id,y,w,rh,nil);local bw=touch and 96 or 88;local id=f.id
            local more=K.make('TextButton',rw,{Name='Detail',Text='',BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,ZIndex=rw.ZIndex+1})
            K.box(more,0,0,w-bw-12,rh);more.Activated:Connect(function()self.a.tactical:open(id)end)
            face20(rw,f,28,12,math.floor((rh-28)/2))
            if r.fmt=='ph'then
                name2(rw,f,w-bw-12-56);num20(rw,'Share',share(f.share),11,muted,48,math.floor(rh/2)+1,w-bw-12-56,15)
            else
                local n=word20(rw,'Name',L.nation(f),13,ink,800,48,0,w-bw-12-48-60,rh);n:SetAttribute('LocalizationSkip',true);K.fit(n,w-bw-12-48-60,13,11)
                num20(rw,'Share',share(f.share),12,muted,w-bw-12-56,0,50,rh,Enum.TextXAlignment.Right)
            end
            act20(rw,'RequestAlliance','동맹 요청','allyo',w-bw-6,rh,bw,playing and not off,function()send('alliance','request',id)end)
            y+=rh+4
        end
    end
    if #incoming+#allies+#outgoing+#others==0 then
        word20(body,'Empty','상대 땅 눌러 동맹 요청',13,muted,700,0,y+8,w,40,Enum.TextXAlignment.Center);y+=56
    end
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
    if not self.frame.Visible or M.closing(self.frame)or not self.state or not self.r then return end
    local sig=self:signatureOf();if sig==self.signature then return end;self.signature=sig
    local scroll=self.body.CanvasPosition
    for _,o in ipairs(self.body:GetChildren())do o:Destroy()end
    for _,o in ipairs(self.pinned:GetChildren())do o:Destroy()end
    local w=self.r.w-32;self.drawnW=self.r.w
    local v2=M.v2();if v2 then kit()end
    local pinned
    if self.page=='ranks'then pinned=v2 and self:drawRanks20(w)or self:drawRanks(w)
    else pinned=v2 and self:drawDiplomacy20(w)or self:drawDiplomacy(w)end
    local top=self.top or 56
    UI.box(self.body,16,top,w+6,self.r.h-top-8-pinned);UI.box(self.pinned,16,self.r.h-8-pinned+4,w,pinned)
    self.body.CanvasPosition=scroll
    if M.v2()then
        local t=self.head.title;local tw=math.min(K.width(t.Text,16,t),self.r.w-140);K.box(t,15,0,tw+4,48);K.box(self.head.sub,15+tw+10,0,self.r.w-tw-90,48)
        K.scrollPad(self.body,2)
    else M.placeHeader(self.head,self.r.w,self.touch)end
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
    local chip=self.panel:FindFirstChild('CampaignTask20');if chip and chip.Visible then y=math.max(y,chip.Position.Y.Offset+chip.Size.Y.Offset+6)end
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
