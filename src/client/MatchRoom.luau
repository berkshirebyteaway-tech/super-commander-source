local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local Tween=game:GetService('TweenService')
local K=require(script.Parent.Kit20)
local Theme=require(script.Parent.Theme)
local L=require(script.Parent.Localization)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local Colors=require(script.Parent.FactionColors)
local Badge=require(script.Parent.BenefitBadge)
local Honor=require(script.Parent.CommanderHonor)
local Audio=require(script.Parent.ToyAudio)
local Step=require(script.Parent.TelemetryStep)
local Tags=require(script.Parent.TagChips)
local Hot=require(script.Parent.HotbarIcons)
local Me=Players.LocalPlayer
local C=K.colors
local M={};M.__index=M
local Z=40
local FFA,FFA_INK=Tags.colors.ffa,Color3.fromRGB(142,184,255)
local TEAM_INK=Color3.fromRGB(196,176,255)
local MOD_ICON={startingGold25M='coin',startingGold5M='coin',startingGold1M='coin',goldMultiplier='coin',isNukesDisabled='hot:AtomBomb',isWaterNukes='hot:AtomBomb',
    isDoomsdayClock='clock',isAlliancesDisabled='hot:Alliance',isSAMsDisabled='hot:SAMLauncher',isPeaceTime='clock',isHardNations='npc',isCrowded='people',isCompact='map',isRandomSpawn='target'}

local function clock(n)local s=math.max(0,math.ceil(n or 0));return string.format('%d:%02d',s//60,s%60)end
local widths={}
local function width(text,size,label)
    local t=L.text(text)or text;local key=t..'|'..size..'|'..(label and label:GetAttribute('Num20')and 'n'or 'w')
    local v=widths[key];if v then return v end
    v=K.width(t,size,label);widths[key]=v;return v
end
local function depthZ(root,base)
    local function walk(o,z)for _,c in ipairs(o:GetChildren())do if c:IsA('GuiObject')then c.ZIndex=c.Name=='Depth'and z-1 or z;walk(c,z+1)else walk(c,z)end end end
    if root:IsA('GuiObject')then root.ZIndex=base end;walk(root,base+1)
end
local function num(parent,name,text,size,color,align)local l=K.num(parent,name,text,size,color,align);l:SetAttribute('Num20',true);return l end
local function chip(parent,name,text,fill,alpha,ink,h,fs,icon,iconColor)
    local f=K.make('Frame',parent,{Name=name,BackgroundColor3=fill,BackgroundTransparency=alpha,BorderSizePixel=0});K.round(f,4)
    local x=6
    if icon then local i=K.icon(f,icon,fs-1,iconColor or ink,'Icon');K.box(i,x,math.floor((h-(fs-1))/2),fs-1,fs-1);x+=fs-1+3 end
    local l=K.text(f,'Text',text,fs,ink,700);local w=width(text,fs,l);K.box(l,x,0,w+2,h)
    local cw=x+w+6;f.Size=UDim2.fromOffset(cw,h);return f,cw
end
local function ruleChip(parent,key,text,ph)
    local h,fs,is,pad,gap=ph and 22 or 28,ph and 11 or 13,ph and 12 or 14,ph and 7 or 10,ph and 4 or 6
    local f=K.make('Frame',parent,{Name='Rule_'..key,BackgroundColor3=C.panel,BorderSizePixel=0});K.round(f,ph and 6 or 8);K.stroke(f,C.line,1,0,true)
    local x=pad;local ik=MOD_ICON[key]
    if ik then
        local i
        if ik=='coin'then i=K.icon(f,'coinGold',is,Color3.new(1,1,1),'Icon')
        elseif ik:sub(1,4)=='hot:'then i=Hot.create(f,ik:sub(5),is,C.ink)
        else i=K.icon(f,ik,is,C.ink,'Icon')end
        K.box(i,x,math.floor((h-is)/2),is,is);x+=is+gap
    end
    local l=K.text(f,'Text',text,fs,key=='more'and C.muted or C.ink,800);local w=width(text,fs,l);K.box(l,x,0,w+2,h)
    local cw=x+w+pad;f.Size=UDim2.fromOffset(cw,h);return f,cw
end
local function pair(parent,name,a,b,size)
    local f=K.make('Frame',parent,{Name=name,BackgroundTransparency=1})
    local la=num(f,'A',a,size,C.ink);local lb=num(f,'B',b,size,C.muted)
    return {frame=f,a=la,b=lb,size=size}
end
local function setPair(p,a,b,right,y,h)
    p.a.Text=a;p.b.Text=b
    local wa,wb=width(a,p.size,p.a),width(b,p.size,p.b)
    K.box(p.frame,right-wa-wb,y,wa+wb+2,h);K.box(p.a,0,0,wa+1,h);K.box(p.b,wa,0,wb+2,h)
    return wa+wb
end

function M.new(root,callbacks)
    local self=setmetatable({root=root,callbacks=callbacks,items={},open=false,minimized=false},M)
    local f=K.make('TextButton',root,{Name='MatchRoom',Text='',AutoButtonColor=false,Active=true,Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0,BorderSizePixel=0,Visible=false,ZIndex=Z})
    self.wash=K.make('UIGradient',f,{Name='Wash',Rotation=90})
    self.frame=f
    UIS.InputBegan:Connect(function(input,processed)
        if processed or not self.open or UIS:GetFocusedTextBox()then return end
        if input.KeyCode==Enum.KeyCode.R then self:press()elseif input.KeyCode==Enum.KeyCode.Escape then self:minimize()end
    end)
    self.sized=root:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()if self.open then self:layout()end end)
    return self
end
function M:size()local s=Theme.scale or 1;return self.root.AbsoluteSize.X/s,self.root.AbsoluteSize.Y/s end
function M.format(w,h)return w<600 and 'pt'or h<500 and 'ph'or 'pc'end

function M:press()
    local q=self.q;if not q or not q.room or self.busy then return end
    if q.room.state=='go'and not self:mine()then return end
    local want=not self:mine();self.pressed=true;self.pending={want=want,until_=os.clock()+4}
    local b=self.ui and self.ui.ready
    if want then if b then K.confirm(b);self:sweep()else Audio.play('confirm')end else Audio.play('click')end
    self.callbacks.ready(want);if self.open then self:draw()end
end
function M:mine()
    local q=self.q;local p=self.pending
    if p and (q.ready==p.want or os.clock()>p.until_)then self.pending=nil;p=nil end
    if p then return p.want end
    return q.ready==true
end
function M:quit()
    local q=self.q;local b=self.ui and self.ui.leave
    if q and q.room and q.room.state=='go'and os.clock()>(self.confirmUntil or 0)then
        self.confirmUntil=os.clock()+3
        if b then b:setText('정말 나가기?');b.label.TextColor3=C.gold end
        task.delay(3.05,function()if os.clock()>=(self.confirmUntil or 0)and self.ui and self.ui.leave==b and b then b:setText('나가기');b.label.TextColor3=self.ui.leaveInk end end)
        return
    end
    self.confirmUntil=nil;self.callbacks.leave()
end
function M:minimize()
    if not self.q then return end
    self.minimized=true;self:show(false,true)
    Step.step('queue','roomMinimized',{value=self.since and math.floor(os.clock()-self.since)or nil})
end
function M:restore()self.minimized=false;if self.q then self:show(true)end end
function M:show(on,animate)
    if self.open==on then return end
    self.open=on
    local f=self.frame
    if on then
        f.Visible=true;self.key=nil;self:layout()
        if self.content and not K.reduced then
            self.content:SetAttribute('Shown20',false);K.rehome(self.content);K.appear(self.content,{dy=16,t=.18})
            f.BackgroundTransparency=1;Tween:Create(f,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=0}):Play()
        else f.BackgroundTransparency=0 end
    else
        if animate and self.content and not K.reduced then
            K.leave(self.content,{dy=16,t=.12},function()if not self.open then f.Visible=false end end)
            Tween:Create(f,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{BackgroundTransparency=1}):Play()
        else f.Visible=false end
    end
    if self.callbacks.shown then self.callbacks.shown(on)end
end
function M:update(q,options)
    options=options or {}
    self.reduced=options.reduced;self.busy=options.busy
    local room=q and q.mode=='pvp'and q.room and not options.practice and q.phase~='transferring'and q.phase~='recovering'and q or nil
    if not room then
        if self.q then self:closed(q)end
        self.q=nil;self:show(false);return
    end
    if not self.q or self.q.field~=room.field then self.since=os.clock();self.minimized=false;self.pressed=false;self.lastGo=nil;self.pending=nil;self.seen=nil
        Step.step('queue','roomOpen',{value=room.count,item=room.rules.mode})
    end
    self.q=room;self.remaining=options.remaining;self.elapsed=options.elapsed or 0
    self:show(options.menu~=false and not options.page and not self.minimized)
    if self.open then self:layout()end
end
function M:closed(next)
    if not next then Step.step('queue','roomLeave',{value=self.since and math.floor(os.clock()-self.since)or nil,result=self.q.room and self.q.room.state or nil})end
end

function M:kind()
    local q=self.q;local r=q.rules or {}
    local plan=q.teamPlan;local teams=r.mode=='teams'and plan~=nil and plan.teams~=nil
    local mods={}
    if r.special then
        for _,k in ipairs(Tags.modifierOrder)do if type(r.modifiers)=='table'and table.find(r.modifiers,k)then table.insert(mods,k)end end
        if r.spawn=='random'and not table.find(mods,'isRandomSpawn')then table.insert(mods,'isRandomSpawn')end
    end
    return teams,r.special==true,mods
end
function M:layout()
    if not self.q then return end
    local w,h=self:size();if w<1 then return end
    local fmt=M.format(w,h);local teams,special,mods=self:kind();local r=self.q.rules or {}
    local count=teams and(self.q.teamPlan.count or r.teamCount or 2)or 0
    local key=table.concat({fmt,math.floor(w),math.floor(h),tostring(teams),tostring(special),table.concat(mods,','),tostring(r.map),count,tostring(r.teamFormat),L.getLocale(),tostring(self.callbacks.insets and self.callbacks.insets().left or 12)},'|')
    if self.key~=key then self.key=key;self:build(fmt,w,h,teams,special,mods,count)end
    self:draw()
end
function M:build(fmt,W,H,teams,special,mods,teamCount)
    if self.content then self.content:Destroy()end
    self.items={};self.rosterSig=nil;self.seen=nil;self.drawnReady=nil
    local q=self.q;local r=q.rules or {}
    local pc,ph,pt=fmt=='pc',fmt=='ph',fmt=='pt'
    self.wash.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(13,27,41)),ColorSequenceKeypoint.new(1,Color3.fromRGB(7,11,16))})
    self.wash.Transparency=NumberSequence.new(0)
    self.smoke=self.smoke or {}
    local specs={{x=pt and .5 or .34,y=pt and .32 or .55,w=pt and 1.6 or 1.1,h=pt and .8 or 1.2,rot=0,col=Color3.fromRGB(23,50,74),keys={0,1,.5,.05,1,1}},
        {x=.5,y=pt and .62 or .74,w=1.7,h=.4,rot=-8,col=Color3.fromRGB(58,74,92),keys={0,1,.16,.9,.32,.97,.5,.86,.7,.96,.86,.9,1,1}}}
    for i,spec in ipairs(specs)do
        local s=self.smoke[i]or K.make('CanvasGroup',self.frame,{Name='Smoke'..i,BackgroundTransparency=1,BorderSizePixel=0,Active=false,ZIndex=0})
        self.smoke[i]=s;s.AnchorPoint=Vector2.new(.5,.5);s.Position=UDim2.fromScale(spec.x,spec.y);s.Size=UDim2.fromScale(spec.w,spec.h);s.Rotation=spec.rot
        if not s:FindFirstChild('Edge')then K.make('UIGradient',s,{Name='Edge',Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(1,1)})})end
        local fill=s:FindFirstChild('Fill')or K.make('Frame',s,{Name='Fill',BorderSizePixel=0,Size=UDim2.fromScale(1,1),Active=false})
        fill.BackgroundColor3=spec.col
        local g=fill:FindFirstChild('Haze')or K.make('UIGradient',fill,{Name='Haze'})
        local seq={};for k=1,#spec.keys,2 do table.insert(seq,NumberSequenceKeypoint.new(spec.keys[k],spec.keys[k+1]))end
        g.Transparency=NumberSequence.new(seq)
    end
    local c=K.make('Frame',self.frame,{Name='Room20',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Active=false})
    self.content=c
    local ui={fmt=fmt,W=W,H=H,teams=teams,special=special}
    self.ui=ui
    local L0,lw,ty,by
    local inset=self.callbacks.insets and self.callbacks.insets()or {left=12}
    if pc then L0,lw,ty,by=40,420,92,H-108
    elseif ph then L0,lw,ty,by=16,250,44,H-68
    else L0,lw,ty,by=16,W-32,108,H-114 end
    if ph then ty=math.max(ty,math.floor(inset.top or 0)+6)end
    ui.L,ui.lw=L0,lw
    local bfs,bis,bh=pc and 15 or ph and 13 or 14,pc and 18 or ph and 16 or 18,ph and 32 or 40
    local back=K.button(c,'Back',{kind='ghost',text='로비',size=bfs,icon='back',iconSize=bis,gap=4,weight=800},function()self:minimize()end)
    local bw=bis+4+width('로비',bfs,back.label)+(ph and 8 or 0)
    local top=math.floor(inset.top or 0)+8
    back:place(pc and 40 or ph and math.max(84,math.floor(inset.left or 0))or 16,pc and math.max(40,top)or ph and 8 or math.max(64,top),bw,bh)
    back.button.Visible=false
    ui.back=back
    local tfs,th=pc and 30 or ph and 20 or 24,pc and 36 or ph and 24 or 29
    local meta=Maps.meta(r.map)or {}
    local title=K.text(c,'Title',L.text(meta.label or r.map or ''),tfs,C.ink,800);title:SetAttribute('LocalizationSkip',true)
    local tw=math.min(width(title.Text,tfs,title),lw-120);K.box(title,L0,ty,tw+2,th)
    local small=ph or pt and special
    local chH,chFs=small and 20 or pt and 22 or 24,small and 11 or pt and 12 or 13
    local cx=L0+tw+(pt and special and 8 or 10);local cyy=ty+math.floor((th-chH)/2)
    if special then local s,sw=chip(c,'Special','특수',C.ink,0,C.bg,chH,chFs,'star',C.bg);K.box(s,cx,cyy,sw,chH);cx+=sw+(pt and 8 or 10)end
    local modeText,modeFill,modeInk,modeAlpha
    if r.mode=='teams'then modeText=r.teamFormat=='HumansVsNations'and '사람 대 국가'or string.format('팀전 %d팀',teamCount>0 and teamCount or r.teamCount or 2);modeFill,modeInk,modeAlpha=K.team,TEAM_INK,.8
    else modeText='개인전';modeFill,modeInk,modeAlpha=FFA,FFA_INK,special and .8 or .82 end
    local mc,mw2=chip(c,'Mode',modeText,modeFill,modeAlpha,modeInk,chH,chFs);K.box(mc,cx,cyy,mw2,chH)
    local subH=0
    if special and #mods>0 then
        local sy=pc and ty+46 or ph and ty+30 or 145;local x=L0;local gap=pc and 6 or 4
        for i,k in ipairs(mods)do
            local f,cw=ruleChip(c,k,Tags.modifierShort[k]or k,not pc)
            if x+cw>L0+lw-(#mods>i and 40 or 0)then f:Destroy()
                local more,mw3=ruleChip(c,'more','+'..tostring(#mods-i+1),not pc);K.box(more,x,sy,mw3,pc and 28 or 22);break end
            K.box(f,x,sy,cw,pc and 28 or 22);x+=cw+gap
        end
        subH=pc and 34 or 26
    end
    local my,mh,cy,nfs,lfs,lh,ndy,barW,barH,rfs,rh,rosterY
    if pc then my=ty+48+subH;mh=by-24-96-my;cy=my+mh+20;nfs,lfs,lh,ndy=64,13,15,17;barW,barH,rfs,rh=180,6,20,30
    elseif ph then my=ty+32+subH;mh=by-8-62-my;cy=my+mh+8;nfs,lfs,lh,ndy=36,11,13,15;barW,barH,rfs,rh=110,6,15,22
    else
        local mw=W-32
        if special then my=178;mh=math.floor(mw*(teams and .22 or .26)+.5);cy=my+mh+10;nfs=teams and 40 or 44;rosterY=cy+(teams and 70 or 74)
        elseif teams then my=148;mh=math.floor(mw*.22+.5);cy=my+mh+10;nfs=40;rosterY=cy+70
        else my=148;mh=math.floor(mw*.34+.5);cy=my+mh+12;nfs=52;rosterY=cy+84 end
        lfs,lh,ndy=12,14,16;barW,barH,rfs,rh=150,8,13,20
    end
    local map=K.map(c,'Map',r.map,lw,mh,8);K.box(map,L0+1,my+1,lw,mh);K.stroke(map,C.line,1,0,false)
    ui.map=map
    local cap=K.text(c,'Until','출발까지',lfs,C.muted,700);K.box(cap,L0,cy,160,lh)
    local big=num(c,'Clock','0:00',nfs,C.ink);K.box(big,L0,cy+ndy,200,nfs);ui.clock=big;ui.clockY,ui.clockFs=cy+ndy,nfs
    local barY=cy+ndy+nfs-barH
    ui.bar=K.fillBar(c,'ReadyBar',{p=0,fill=C.accent,track=C.raised});K.box(ui.bar.frame,L0+lw-barW,barY,barW,barH)
    ui.readyY,ui.readyH,ui.readyFs=barY-6-rh,rh,rfs
    ui.readyWord=K.text(c,'ReadyWord','레디',rfs,pt and C.ink or C.accent,800)
    ui.readyN=num(c,'ReadyN','0',rfs,C.accent);ui.readyM=num(c,'ReadyM',' / 0',rfs,pt and C.muted or C.accent)
    local bH=pc and 68 or ph and 52 or 56;local leaveW=pc and 110 or ph and 76 or 96;local gap=pc and 12 or 8
    ui.leaveInk=pt and C.ink or C.muted
    local leave=K.button(c,'Leave',{kind='plain',text='나가기',size=pc and 17 or ph and 14 or 16,weight=800},function()self:quit()end)
    leave:place(L0,by,leaveW,bH);leave.label.TextColor3=ui.leaveInk;ui.leave=leave
    local ready=K.button(c,'Ready',{kind='pri',text='레디',size=pc and 28 or ph and 22 or 22,weight=800,sound=false},function()self:press()end)
    ready:place(L0+leaveW+gap,by,lw-leaveW-gap,bH);ui.ready=ready
    local gx,gy,gw,top,bottom
    if pc then gx=L0+lw+40;gw=W-gx-40;gy=48;top=teams and gy+40 or special and gy+40 or gy+44;bottom=H-40
    elseif ph then gx=L0+lw+16;gw=W-gx-16;gy=52;top=teams and gy or gy+28;bottom=H-10
    else gx=16;gw=W-32;top=rosterY;bottom=by-8 end
    ui.gx,ui.gw,ui.top=gx,gw,top
    if not pt and not(ph and teams)then
        local hfs=pc and 16 or 13;local hh=pc and 30 or 22
        local head=K.text(c,'Commanders','지휘관',hfs,C.ink,800);K.box(head,gx,gy,160,hh)
        ui.count=pair(c,'Count','0',' / 0',pc and 20 or 15);ui.countY,ui.countH,ui.countRight=gy,hh,gx+gw
    end
    local s=K.make('ScrollingFrame',c,{Name='Roster',Active=true,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.line,
        CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true})
    K.box(s,gx-4,top-4,gw+8,math.max(40,bottom-top+8));K.scrollPad(s,4)
    ui.list=s;ui.listH=bottom-top
    depthZ(self.frame,Z)
end

function M:draw()
    local q=self.q;local ui=self.ui;if not q or not ui then return end
    local room=q.room;local go=room.state=='go';local full=room.reason=='full'and go
    local remaining=math.max(0,(self.remaining or 0))
    local limit=room.limit and math.max(0,room.limit-self.elapsed)or remaining
    local counting=go or remaining<=10
    local secs=math.ceil(remaining)
    local big=ui.clock
    big.Text=counting and clock(remaining)or clock(limit)
    big.TextColor3=counting and(full and C.gold or C.accent)or C.ink
    K.box(big,ui.L,ui.clockY,width(big.Text,ui.clockFs,big)+2,ui.clockFs)
    if counting and self.lastSecond and secs<self.lastSecond and secs<=5 and secs>0 then Audio.play('countdown')end
    self.lastSecond=secs
    if go and not self.lastGo then self.lastGo=true;Audio.play('confirm');K.punch(big,1.1,.14)
        Step.step('queue','roomCountdown',{value=math.floor(os.clock()-(self.since or os.clock())),item=room.reason,count=q.count})end
    local mine=self:mine();local n=q.count
    local readyN=math.max(0,room.ready+(mine and 1 or 0)-(q.ready and 1 or 0))
    ui.bar:set(n>0 and readyN/n or 0,self.drawnReady~=nil and readyN~=self.drawnReady);self.drawnReady=readyN
    local right=ui.L+ui.lw;local fs=ui.readyFs
    ui.readyN.Text=tostring(readyN);ui.readyM.Text=' / '..tostring(n)
    local wm,wn,ww=width(ui.readyM.Text,fs,ui.readyM),width(ui.readyN.Text,fs,ui.readyN),width('레디',fs,ui.readyWord)
    K.box(ui.readyM,right-wm-1,ui.readyY,wm+2,ui.readyH);K.box(ui.readyN,right-wm-wn-1,ui.readyY,wn+2,ui.readyH);K.box(ui.readyWord,right-wm-wn-ww-(ui.fmt=='pt'and 4 or 6),ui.readyY,ww+2,ui.readyH)
    local b=ui.ready;local kind=mine and 'out'or 'pri'
    if b.kind~=kind then b:setEnabled(true);b:setKind(kind)end
    b:setText(mine and '✓ 레디'or '레디')
    b:setEnabled(not(go and not mine)and not self.busy,self.busy and not(go and not mine))
    ui.leave:setEnabled(not self.busy,true)
    if ui.count then setPair(ui.count,tostring(q.count),' / '..tostring(q.max or q.count),ui.countRight,ui.countY,ui.countH)end
    self:roster()
end
function M:sweep()
    local b=self.ui and self.ui.ready;if not b or K.reduced then return end
    local g=b.face:FindFirstChild('Sweep20')or K.make('UIGradient',b.face,{Name='Sweep20'})
    g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.499,0),NumberSequenceKeypoint.new(.5,1),NumberSequenceKeypoint.new(1,1)})
    g.Offset=Vector2.new(-.5,0);g.Enabled=true
    local t=Tween:Create(g,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Offset=Vector2.new(.5,0)});t:Play()
    t.Completed:Once(function()g.Enabled=false end)
end

function M:members()
    local q=self.q;local order={}
    for _,m in ipairs(q.members or {})do
        if m.userId==Me.UserId then m=table.clone(m);m.ready=self:mine();m.me=true;table.insert(order,1,m)else table.insert(order,m)end
    end
    return order
end
local function levelOf(m)
    local p=Players:GetPlayerByUserId(m.userId);local h=p and Honor.of(p)
    return h and h.level or m.level,p
end
local ROW={
    pc_s={h=52,av=36,fs=15,ck=17},ph_s={h=34,av=24,fs=12,ck=14},pt_s={h=36,av=24,fs=13,ck=15},
    pc_t={h=48,av=32,fs=14,ck=16},ph_t={h=26,av=18,fs=11,ck=13},pt_t={h=34,av=24,fs=13,ck=15},
    pt_0={h=40,av=28,fs=13,ck=16},
}
function M:plan()
    local q=self.q;local ui=self.ui;local fmt=ui.fmt;local gw=ui.gw
    local list=self:members();local items={};local H=0
    local function add(it)table.insert(items,it);H=math.max(H,it.y+it.h)end
    local aiAll=q.ai or math.max(0,(q.max or #list)-#list)
    if not ui.teams then
        if fmt~='pt'and not ui.special then
            local cols,gap,th=fmt=='pc'and 4 or 3,fmt=='pc'and 10 or 6,fmt=='pc'and 60 or 40
            local tw=math.floor((gw-(cols-1)*gap)/cols)
            for i,m in ipairs(list)do add({key='u'..m.userId,kind='tile',m=m,x=((i-1)%cols)*(tw+gap),y=((i-1)//cols)*(th+gap),w=tw,h=th})end
            if aiAll>0 then local i=#list+1;add({key='ai',kind='ai',n=aiAll,x=((i-1)%cols)*(tw+gap),y=((i-1)//cols)*(th+gap),w=tw,h=th,fs=fmt=='pc'and 15 or 12,is=fmt=='pc'and 16 or 14})end
        else
            local cols=fmt=='pc'and 3 or 2;local gap=fmt=='pc'and 10 or 6
            local spec=fmt=='pt'and(ui.special and ROW.pt_s or ROW.pt_0)or ROW[fmt..'_s']
            local step=fmt=='pt'and(ui.special and 42 or 46)or spec.h+gap
            local tw=math.floor((gw-(cols-1)*(fmt=='pt'and 8 or gap))/cols);local cg=fmt=='pt'and 8 or gap
            for i,m in ipairs(list)do add({key='u'..m.userId,kind='row',m=m,spec=spec,x=((i-1)%cols)*(tw+cg),y=((i-1)//cols)*step,w=(i-1)%cols==cols-1 and gw-(cols-1)*(tw+cg)or tw,h=spec.h})end
            if aiAll>0 then local i=#list+1;local left=fmt=='pt'and not ui.special
                add({key='ai',kind='ai',n=aiAll,left=left,x=((i-1)%cols)*(tw+cg),y=((i-1)//cols)*step,w=(i-1)%cols==cols-1 and gw-(cols-1)*(tw+cg)or tw,h=spec.h,fs=spec.fs,is=left and 20 or spec.fs+2,alpha=left and .6 or .65})end
        end
        return items,H
    end
    local plan=q.teamPlan;local count=plan.count or q.rules.teamCount or 2;local map=plan.teams or {}
    local own=map[tostring(Me.UserId)]
    local groups={};for t=1,count do groups[t]={team=t,list={}}end
    for _,m in ipairs(list)do local t=map[tostring(m.userId)]or 1;if groups[t]then table.insert(groups[t].list,m)end end
    local order={};if own and groups[own]then table.insert(order,groups[own])end
    local k=0
    for t=1,count do if t~=own then k+=1;groups[t].color=Colors.teamPalette[(k-1)%#Colors.teamPalette+1];table.insert(order,groups[t])end end
    if own and groups[own]then groups[own].color=Colors.self;groups[own].mine=true end
    local per=plan.capacity or math.ceil((q.max or 2)/count)
    for _,g in ipairs(order)do g.ai=plan.aiCounts and plan.aiCounts[g.team]or math.max(0,per-#g.list);g.per=per end
    if fmt=='pt'then
        local g=order[1];local spec=ROW.pt_t;local cw=math.floor((gw-16-2-6)/2)
        local cells=#g.list+(g.ai>0 and 1 or 0);local rows=math.max(1,math.ceil(cells/2))
        local boxH=1+8+22+6+rows*(34+6)-6+8+1
        add({key='col'..g.team,kind='col',g=g,x=0,y=0,w=gw,h=boxH,head=22,headFs=14,pad=8,barH=14})
        for i,m in ipairs(g.list)do add({key='u'..m.userId,kind='row',m=m,spec=spec,x=9+((i-1)%2)*(cw+6),y=9+22+6+((i-1)//2)*40,w=cw,h=34})end
        if g.ai>0 then local i=#g.list+1;add({key='ai'..g.team,kind='ai',n=g.ai,x=9+((i-1)%2)*(cw+6),y=9+22+6+((i-1)//2)*40,w=cw,h=34,fs=13,is=15,alpha=.65})end
        local y=boxH+8
        for i=2,#order do local o=order[i];add({key='line'..o.team,kind='line',g=o,x=0,y=y,w=gw,h=34});y+=38 end
        return items,H
    end
    local perRow=fmt=='pc'and 4 or 2;local cg=fmt=='pc'and 12 or 8;local cw=math.floor((gw-cg*(perRow-1))/perRow)
    local pad=fmt=='pc'and 8 or 5;local headH=fmt=='pc'and 30 or 22;local gap=fmt=='pc'and 8 or 4
    local spec=ROW[fmt..'_t'];local aiH=fmt=='pc'and 40 or 24;local rw=cw-2-pad*2
    local y0,rowMax=0,0
    for i,g in ipairs(order)do
        local col=(i-1)%perRow;if col==0 and i>1 then y0+=rowMax+(fmt=='pc'and 12 or 6);rowMax=0 end
        local x=col*(cw+cg);local h=1+pad+headH+gap+#g.list*(spec.h+gap)+(g.ai>0 and aiH or -gap)+pad+1
        rowMax=math.max(rowMax,h)
        add({key='col'..g.team,kind='col',g=g,x=x,y=y0,w=cw,h=h,head=headH,headFs=fmt=='pc'and 15 or 12,pad=pad,barH=headH-8})
        local ry=y0+1+pad+headH+gap
        for _,m in ipairs(g.list)do add({key='u'..m.userId,kind='row',m=m,spec=spec,x=x+1+pad,y=ry,w=rw,h=spec.h});ry+=spec.h+gap end
        if g.ai>0 then add({key='ai'..g.team,kind='ai',n=g.ai,x=x+1+pad,y=ry,w=rw,h=aiH,fs=fmt=='pc'and 14 or 11,is=fmt=='pc'and 16 or 13,alpha=.65})end
    end
    return items,H
end
function M:tile(it)
    local pc=self.ui.fmt=='pc'
    local f=K.make('Frame',self.ui.list,{Name='Seat',BorderSizePixel=0});K.round(f,8);local st=K.stroke(f,C.line,1,0,true)
    local av=pc and 40 or 28;local a=K.avatar(f,'Avatar',nil,av);K.box(a,pc and 11 or 7,math.floor((it.h-av)/2),av,av)
    local ck=K.make('Frame',a,{Name='Ready',BackgroundColor3=C.accent,BorderSizePixel=0,Visible=false});K.round(ck,'pill');K.stroke(ck,C.bg,2,0,true)
    local cs=pc and 18 or 14;K.box(ck,av-cs+4,av-cs+4,cs,cs)
    local ci=K.icon(ck,'check',pc and 11 or 8,C.bg,'Icon');K.box(ci,(cs-(pc and 11 or 8))/2,(cs-(pc and 11 or 8))/2,pc and 11 or 8,pc and 11 or 8)
    local dot=K.make('Frame',a,{Name='Party',BackgroundColor3=C.gold,BorderSizePixel=0,Visible=false});K.round(dot,'pill');K.stroke(dot,C.bg,2,0,true);K.box(dot,-3,-3,pc and 9 or 7,pc and 9 or 7)
    local tx=(pc and 11 or 7)+av+(pc and 10 or 7)
    local name=K.text(f,'Name','',pc and 15 or 12,C.ink,700);name:SetAttribute('LocalizationSkip',true)
    local lv=num(f,'Level','',pc and 12 or 11,C.muted)
    K.box(name,tx,pc and 12 or 4,it.w-tx-8,pc and 18 or 15);K.box(lv,tx,pc and 31 or 20,it.w-tx-8,pc and 17 or 14)
    local badge=it.w>=150 and Badge.create(f,18)or nil
    return {frame=f,stroke=st,avatar=a,check=ck,party=dot,name=name,level=lv,tx=tx,badge=badge,pc=pc}
end
function M:paintTile(t,it)
    local m=it.m;local level,p=levelOf(m)
    local me=m.me==true;local ready=m.ready==true
    t.frame.BackgroundColor3=ready and C.accent or C.panel;t.frame.BackgroundTransparency=ready and .9 or 0
    t.stroke.Color=me and C.accent or ready and C.accent or C.line;t.stroke.Transparency=(not me and ready)and .65 or 0;t.stroke.Thickness=me and 2 or 1
    if t.uid~=m.userId then t.uid=m.userId;t.avatar.Image=m.userId>0 and ('rbxthumb://type=AvatarHeadShot&id='..m.userId..'&w=150&h=150')or ''end
    t.check.Visible=ready;t.party.Visible=m.group~=nil
    t.name.Text=p and p.DisplayName or m.name or '';t.level.Text=level and ('Lv '..tostring(level))or ''
    local bw=0
    if t.badge then Badge.update(t.badge,p and p:GetAttribute('CommanderPermanent')==true,p and p:GetAttribute('CommanderVIP')==true);bw=Badge.width(t.badge)
        if bw>0 then t.badge.root.Position=UDim2.fromOffset(it.w-8-bw,t.pc and 12 or 4)end end
    K.box(t.name,t.tx,t.pc and 12 or 4,math.max(20,it.w-t.tx-8-(bw>0 and bw+6 or 0)),t.pc and 18 or 15)
end
function M:row(it)
    local s=it.spec;local small=it.h<30
    local f=K.make('Frame',self.ui.list,{Name='Seat',BackgroundColor3=C.panel,BorderSizePixel=0});K.round(f,small and 6 or 8);local st=K.stroke(f,C.line,1,0,true)
    local pad=small and 7 or 9;local a=K.avatar(f,'Avatar',nil,s.av);K.box(a,pad,math.floor((it.h-s.av)/2),s.av,s.av)
    local dot=K.make('Frame',a,{Name='Party',BackgroundColor3=C.gold,BorderSizePixel=0,Visible=false});K.round(dot,'pill');K.stroke(dot,C.bg,2,0,true)
    local ds=small and 7 or 9;K.box(dot,-3,-3,ds,ds)
    local ck=K.icon(f,'check',s.ck,C.accent,'Ready')
    local name=K.text(f,'Name','',s.fs,C.ink,700);name:SetAttribute('LocalizationSkip',true)
    local badge=it.w>=150 and Badge.create(f,18)or nil
    return {frame=f,stroke=st,avatar=a,check=ck,party=dot,name=name,badge=badge,tx=pad+s.av+(small and 6 or 8),pad=pad}
end
function M:paintRow(t,it)
    local m=it.m;local s=it.spec;local _,p=levelOf(m)
    local me=m.me==true
    t.stroke.Color=me and C.accent or C.line;t.stroke.Thickness=me and 2 or 1
    if t.uid~=m.userId then t.uid=m.userId;t.avatar.Image=m.userId>0 and ('rbxthumb://type=AvatarHeadShot&id='..m.userId..'&w=150&h=150')or ''end
    t.party.Visible=m.group~=nil;t.check.Visible=m.ready==true
    local right=it.w-t.pad-(s.ck)
    K.box(t.check,right,math.floor((it.h-s.ck)/2),s.ck,s.ck)
    local bw=0
    if t.badge then Badge.update(t.badge,p and p:GetAttribute('CommanderPermanent')==true,p and p:GetAttribute('CommanderVIP')==true);bw=Badge.width(t.badge)
        if bw>0 then t.badge.root.Position=UDim2.fromOffset(right-6-bw,math.floor((it.h-18)/2))end end
    t.name.Text=p and p.DisplayName or m.name or ''
    K.box(t.name,t.tx,0,math.max(20,right-8-(bw>0 and bw+6 or 0)-t.tx),it.h)
end
function M:ai(it)
    local f=K.dashBox(self.ui.list,'AI',C.muted,it.alpha or .7,it.h<30 and 6 or 8,1)
    local i=K.icon(f,'npc',it.is,C.muted,'Icon')
    local l
    if it.left then l=K.text(f,'Text','',it.fs,C.muted,800)else l=num(f,'Text','',it.fs,C.muted)end
    return {frame=f,icon=i,label=l}
end
function M:paintAI(t,it)
    t.label.Text=string.format('AI +%d',it.n)
    local tw=width(t.label.Text,it.fs,t.label);local gap=it.left and 8 or 5
    local x=it.left and 9 or math.floor((it.w-(it.is+gap+tw))/2)
    K.box(t.icon,x,math.floor((it.h-it.is)/2),it.is,it.is);K.box(t.label,x+it.is+gap,0,tw+2,it.h)
end
function M:col(it)
    local g=it.g
    local f=K.make('Frame',self.ui.list,{Name='Team',BorderSizePixel=0});K.round(f,self.ui.fmt=='ph'and 8 or 10)
    local st=K.stroke(f,C.line,1,0,true)
    local bar=K.make('Frame',f,{Name='Bar',BorderSizePixel=0});K.round(bar,'pill')
    local name=K.text(f,'Name','',it.headFs,C.ink,900)
    local cnt=pair(f,'Count','',' / ',it.headFs)
    return {frame=f,stroke=st,bar=bar,name=name,count=cnt,g=g}
end
function M:paintCol(t,it)
    local g=it.g;local mine=g.mine==true
    t.frame.BackgroundColor3=mine and C.accent or C.panel;t.frame.BackgroundTransparency=mine and .93 or .4
    t.stroke.Color=mine and C.accent or C.line;t.stroke.Transparency=mine and .65 or 0
    t.bar.BackgroundColor3=g.color or C.muted
    local x=1+it.pad+2;local hy=1+it.pad
    K.box(t.bar,x,hy+math.floor((it.head-it.barH)/2),4,it.barH)
    t.name.Text=mine and '우리 팀'or string.format('%d팀',g.team);t.name.TextColor3=mine and C.accent or C.ink
    K.box(t.name,x+10,hy,it.w-x-60,it.head)
    setPair(t.count,tostring(#g.list),' / '..tostring(g.per),it.w-1-it.pad-2,hy,it.head)
end
function M:line(it)
    local f=K.make('Frame',self.ui.list,{Name='TeamLine',BackgroundColor3=C.panel,BorderSizePixel=0});K.round(f,8);K.stroke(f,C.line,1,0,true)
    local bar=K.make('Frame',f,{Name='Bar',BorderSizePixel=0});K.round(bar,'pill');K.box(bar,11,7,4,20)
    local name=K.text(f,'Name','',13,C.ink,900);K.box(name,23,0,36,34)
    local faces=K.make('Frame',f,{Name='Faces',BackgroundTransparency=1});K.box(faces,61,6,150,22)
    local cnt=pair(f,'Count','',' / ',14)
    local ai=K.text(f,'AI','',11,C.muted,700)
    return {frame=f,bar=bar,name=name,faces=faces,count=cnt,ai=ai}
end
function M:paintLine(t,it)
    local g=it.g
    t.bar.BackgroundColor3=g.color or C.muted;t.name.Text=string.format('%d팀',g.team)
    local sig=table.concat((function()local o={};for _,m in ipairs(g.list)do table.insert(o,tostring(m.userId))end;return o end)(),',')
    if t.facesSig~=sig then t.facesSig=sig;for _,o in ipairs(t.faces:GetChildren())do o:Destroy()end
        for i,m in ipairs(g.list)do if i>6 then break end
            local a=K.avatar(t.faces,'Face'..i,m.userId>0 and m.userId or nil,22);K.stroke(a,C.panel,2,0,false);K.box(a,(i-1)*16,0,22,22)end
        depthZ(t.faces,t.faces.ZIndex)end
    local aiText=string.format('AI %d',g.ai);t.ai.Text=aiText;t.ai.Visible=g.ai>0
    local aw=g.ai>0 and width(aiText,11,t.ai)or 0;K.box(t.ai,it.w-11-aw,0,aw+2,34)
    setPair(t.count,tostring(#g.list),' / '..tostring(g.per),it.w-11-(aw>0 and aw+8 or 0),0,34)
    local names={};for _,m in ipairs(g.list)do table.insert(names,tostring(m.name or ''))end
    if not t.names then t.names=K.text(t.frame,'Names','',12,C.ink,700);t.names.TextTruncate=Enum.TextTruncate.AtEnd;t.names:SetAttribute('LocalizationSkip',true)end
    local fw=#g.list>0 and 22+(math.min(#g.list,6)-1)*16+6 or 0;local right=it.w-11-(aw>0 and aw+8 or 0)-width(tostring(#g.list)..' / '..tostring(g.per),14,t.names)-8
    t.names.Text=table.concat(names,', ');t.names.Visible=#names>0;K.box(t.names,61+fw,0,math.max(0,right-61-fw),34)
    t.faces.Visible=#g.list>0
end
function M:roster()
    local ui=self.ui;local items,H=self:plan()
    local parts={tostring(ui.gw)}
    for _,it in ipairs(items)do
        local m,g=it.m,it.g
        table.insert(parts,table.concat({it.key,it.x,it.y,it.w,it.h,tostring(it.n),m and tostring(m.ready)or '',m and tostring(m.group)or '',m and tostring(m.name)or '',m and tostring(m.level)or '',
            g and table.concat({g.ai,g.per,#g.list,tostring(g.mine)},':')or ''},'/'))
    end
    local sig=table.concat(parts,'|')
    if sig==self.rosterSig then return end;self.rosterSig=sig
    local first=self.seen==nil;self.seen=self.seen or {}
    local keep={};local built=false
    for _,it in ipairs(items)do
        keep[it.key]=true
        local t=self.items[it.key]
        if t and t.kind~=it.kind then t.ui.frame:Destroy();t=nil end
        local fresh=t==nil
        if fresh then
            local o=it.kind=='tile'and self:tile(it)or it.kind=='row'and self:row(it)or it.kind=='ai'and self:ai(it)or it.kind=='col'and self:col(it)or self:line(it)
            t={kind=it.kind,ui=o};self.items[it.key]=t;built=true
        end
        local f=t.ui.frame
        if it.kind=='tile'then self:paintTile(t.ui,it)elseif it.kind=='row'then self:paintRow(t.ui,it)elseif it.kind=='ai'then self:paintAI(t.ui,it)
        elseif it.kind=='col'then self:paintCol(t.ui,it)else self:paintLine(t.ui,it)end
        local goal=UDim2.fromOffset(it.x,it.y)
        f.Size=UDim2.fromOffset(it.w,it.h)
        if fresh then
            f.Position=goal;f:SetAttribute('Home20',goal)
            local person=it.m~=nil
            if person and not first and not self.seen[it.key]and not it.m.me then K.appear(f,{t=.14,scaleFrom=.9});Audio.play('pop')end
        elseif f.Position~=goal and f:GetAttribute('Moving20')~='out'then
            f:SetAttribute('Home20',goal)
            if K.reduced then f.Position=goal else Tween:Create(f,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=goal}):Play()end
        end
        if it.m then self.seen[it.key]=true end
    end
    for key,t in pairs(self.items)do if not keep[key]then
        self.items[key]=nil;local f=t.ui.frame
        if t.kind=='tile'or t.kind=='row'then self.seen[key]=nil;K.leave(f,{t=.10},function()f:Destroy()end)else f:Destroy()end
    end end
    ui.list.CanvasSize=UDim2.fromOffset(0,H+8)
    if built then depthZ(ui.list,ui.list.ZIndex)end
end
return M
