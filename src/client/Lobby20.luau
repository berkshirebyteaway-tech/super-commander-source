local Players=game:GetService('Players')
local Tween=game:GetService('TweenService')
local K=require(script.Parent.Kit20)
local Theme=require(script.Parent.Theme)
local BrandMark=require(script.Parent.BrandMark)
local Campaign=require(script.Parent.Parent.Core.CampaignRules)
local C=K.colors
local M={}
M.ENABLED=true
local TABS={{'play','플레이','deploy'},{'missions','목표','missions'},{'wardrobe','스킨','wardrobe'},{'shop','상점','reward'},{'clan','클랜','clan'}}
local OWNER={missions='missions',wardrobe='wardrobe',motions='wardrobe',shop='shop',supply='shop',benefits='shop',clan='clan',
    friends='play',custom='play',customRules='play',customCode='play',joinCode='play',watch='play',multiplayer='play'}
local function format(w,h)if w<600 then return 'pt'elseif h<500 then return 'ph'else return 'pc'end end
M.format=format
function M.campaignDone(p)
    p=p or {};local last=Campaign.stages[#Campaign.stages]
    return last~=nil and Campaign.cleared(p,last.id)
end
local function campaignNext(l)
    local p=l.account and l.account.progress or {}
    if l.firstLesson then return nil end
    if not(p.basicsComplete==true or p.tutorial==false or next(p.history or {})~=nil)then return nil end
    if M.campaignDone(p)then return nil end
    local s=Campaign.stage(Campaign.nextStage(p));return s
end

local function build(home)
    if home.c20 then return home.c20 end
    local l=home.lobby;local f=l.frame
    local c={tabs={}};home.c20=c
    c.bar=K.make('Frame',f,{Name='TopBar20',BackgroundColor3=Color3.fromRGB(6,9,13),BackgroundTransparency=0,BorderSizePixel=0,ZIndex=29,Active=false})
    K.make('UIGradient',c.bar,{Rotation=90,Transparency=NumberSequence.new(.08,.28)})
    c.barLine=K.make('Frame',c.bar,{Name='Line',BackgroundColor3=C.line,BackgroundTransparency=.4,BorderSizePixel=0,ZIndex=29})
    local FullBleed=require(script.Parent.FullBleed);FullBleed.edge(c.bar)
    c.thumb=K.make('Frame',f,{Name='ThumbBar20',BackgroundColor3=Color3.fromRGB(6,9,13),BackgroundTransparency=.04,BorderSizePixel=0,ZIndex=29,Active=true,Visible=false})
    c.thumbLine=K.make('Frame',c.thumb,{Name='Line',BackgroundColor3=C.line,BackgroundTransparency=.2,BorderSizePixel=0,ZIndex=29})
    FullBleed.edge(c.thumb)
    c.logo=K.make('Frame',f,{Name='Logo20',BackgroundTransparency=1,ZIndex=31,Active=false})
    c.super=K.text(c.logo,'Super','SUPER',11,Color3.fromRGB(255,216,74),700);c.commander=K.text(c.logo,'Commander','COMMANDER',22,C.ink,700)
    for _,o in ipairs({c.super,c.commander})do o.ZIndex=31;o:SetAttribute('LocalizationSkip',true);o.TextTruncate=Enum.TextTruncate.None;Theme.display(o);BrandMark.word(o,o==c.super and 1.5 or 2.5)end
    c.super.TextColor3=Color3.fromRGB(255,216,74);c.commander.TextColor3=Color3.new(1,1,1)
    for i,t in ipairs(TABS)do
        local b=K.make('TextButton',f,{Name='Tab20_'..t[1],Text='',BackgroundTransparency=1,AutoButtonColor=false,BorderSizePixel=0,ZIndex=31})
        local icon=K.icon(b,t[3],22,C.muted,'Icon');icon.ZIndex=32
        local word=K.text(b,'Word',t[2],13,C.muted,600,Enum.TextXAlignment.Center);word.ZIndex=32;word.TextTruncate=Enum.TextTruncate.None
        b.Activated:Connect(function()
            require(script.Parent.ToyAudio).play('click')
            if t[1]=='play'then l:closePage();if l.deployment then l.deployment:setOpen(false)end;l:layout()
            elseif l.page==t[1]then return else l:openPage(t[1])end
        end)
        c.tabs[i]={key=t[1],button=b,icon=icon,word=word}
    end
    c.mark=K.make('Frame',f,{Name='TabMark20',BackgroundColor3=C.accent,BorderSizePixel=0,ZIndex=32,Active=false});K.round(c.mark,2)
    local p=l.profile;c.profile=p
    for _,o in ipairs(p:GetChildren())do if o:IsA('GuiObject')and o.Name~='PressFeedback'then o.Visible=false;o:SetAttribute('Hidden20',true)end end
    p.Text='';K.round(p,8);local ps=p:FindFirstChildOfClass('UIStroke');if ps then ps.Color=C.line;ps.Transparency=0;ps.Thickness=1 end
    p.BackgroundColor3=C.panel;p.BackgroundTransparency=.15;p.AutoButtonColor=false
    c.avatar=K.avatar(p,'Avatar20',Players.LocalPlayer.UserId,30);c.avatar.ZIndex=p.ZIndex+1
    c.level=K.num(p,'Level20','Lv 1',14,C.ink);c.level.ZIndex=p.ZIndex+1
    c.coins=K.make('Frame',p,{Name='Coins20',BackgroundTransparency=1,ZIndex=p.ZIndex+1})
    c.coinIcon=K.icon(c.coins,'coinGold',14,Color3.new(1,1,1),'Icon');c.coinValue=K.num(c.coins,'Value','0',14,C.ink,Enum.TextXAlignment.Right)
    c.xp=K.fillBar(p,'XP20',{p=0,fill=C.accent,track=C.raised})
    p.ChildAdded:Connect(function(o)if o:IsA('GuiObject')and not o.Name:find('20')and o.Name~='PressFeedback'and o.Name~='RewardPulse'then o.Visible=false;o:SetAttribute('Hidden20',true)end end)
    c.gear=K.button(f,'Gear20',{kind='glass',icon='settings',iconSize=20},function()l:openPage('preferences')end)
    c.gear.face.BackgroundColor3=C.panel;c.gear.face.BackgroundTransparency=.15;c.gear.faceStroke.Transparency=0;c.gear.baseFill=C.panel;c.gear.baseAlpha=.15
    c.gear.iconColorFixed=true;c.gear.iconImage.ImageColor3=C.muted;c.gear.button.ZIndex=31;c.gear.face.ZIndex=31;c.gear.iconImage.ZIndex=32
    return c
end

function M.sideInsets(l)
    local gui=l.frame and l.frame:FindFirstAncestorOfClass('ScreenGui');if not gui then return 0,0,0 end
    local ok,a,_,c,d=pcall(require(script.Parent.FullBleed).insets,gui);if not ok then return 0,0,0 end
    local s=gui:GetAttribute('UIScale')or 1
    return a/s,c/s,d/s
end
local sign
function M.hallSign(on)
    if not sign or not sign[1].Parent then
        local h=workspace:FindFirstChild('HQHeader',true);sign=h and {h,h.Parent and h.Parent:FindFirstChild('HQHeaderFrame')}or nil
    end
    if not sign or sign.on==on then return end
    sign.on=on
    for i=1,2 do local p=sign[i];if p and p:IsA('BasePart')then p.LocalTransparencyModifier=on and 0 or 1
        for _,g in ipairs(p:GetChildren())do if g:IsA('SurfaceGui')then g.Enabled=on end end end end
end
function M.chrome(home,w,h,lift)
    local l=home.lobby;local c=build(home);local d=l.deployment
    local fmt=format(w,h);local menu=l.inMenu~=false;local open=d~=nil and d.expanded and not l.page
    l.nav.Visible=false;l.settingsButton.Visible=false;l.help.Visible=false;l.header.Visible=false
    if home.brandMark then home.brandMark.Visible=false end
    M.hallSign(fmt~='pt')
    local FULL=require(script.Parent.LobbyHome).FULL
    local covered=fmt=='ph'and l.page~=nil and not FULL[l.page]and l.page~='motions'
    local show=menu and l.frame.Visible and not(open and fmt~='pc')and not covered
    local barH=fmt=='pc'and 58 or fmt=='ph'and 46 or 0
    c.bar.Visible=show and fmt~='pt';c.thumb.Visible=show and fmt=='pt'
    local il,ir=M.sideInsets(l)
    if fmt~='pt'then K.box(c.bar,-il,0,w+il+ir,barH);K.box(c.barLine,0,barH-1,w+il+ir,1)end
    local onHome=menu and not l.page and not open
    c.logo.Visible=show and(fmt=='pc'or fmt=='pt'and onHome)
    local logoX=math.max(24,math.floor((l.topbarLeft or 12)+4))
    if fmt=='pc'then K.box(c.logo,logoX,11,160,36);K.box(c.super,0,0,160,11);K.box(c.commander,0,11,180,25);c.super.TextSize=11;c.commander.TextSize=22
    else K.box(c.logo,16,70,150,32);K.box(c.super,0,0,150,10);K.box(c.commander,0,10,170,22);c.super.TextSize=10;c.commander.TextSize=20 end
    local p=c.profile;p.Visible=show;local pw,ph,py,px,av,fs,inner
    if fmt=='pc'then pw,ph,py=212,42,8;px=w-pw-72;av,fs,inner=30,14,9
    elseif fmt=='ph'then pw,ph,py=128,36,5;px=w-pw-56;av,fs,inner=26,12,7
    else pw,ph,py=150,40,12;px=w-12-40-8-pw;av,fs,inner=28,13,7 end
    K.box(p,px,py,pw,ph);p.ZIndex=31
    local tx=inner+av+(fmt=='pc'and 10 or 7)
    K.box(c.avatar,inner,(ph-av)/2,av,av)
    c.level.TextSize=fs;K.box(c.level,tx,fmt=='pc'and 7 or 6,60,fs+7)
    local cw=K.width(c.coinValue.Text,fs,c.coinValue)
    c.coinValue.TextSize=fs;K.box(c.coins,pw-inner-(fs+5+cw),fmt=='pc'and 7 or 6,fs+5+cw,fs+7);K.box(c.coinIcon,0,math.floor((fs+7-fs)/2)+1,fs,fs);K.box(c.coinValue,fs+5,0,cw+1,fs+7)
    K.box(c.xp.frame,tx,ph-(fmt=='pc'and 10 or fmt=='ph'and 9 or 10),pw-tx-inner,4)
    for _,o in ipairs(p:GetChildren())do if o:GetAttribute('Hidden20')then o.Visible=false end end
    local g=fmt=='pc'and 42 or fmt=='ph'and 36 or 40
    c.gear.button.Visible=show
    c.gear:place(fmt=='pc'and w-60 or fmt=='ph'and w-48 or w-12-40,py,g,g);c.gear.iconSize=fmt=='pc'and 20 or 18;c.gear:layoutContent()
    local lit=l.page and OWNER[l.page]or(not l.page and 'play')or nil
    local n=#TABS;local tw,tx0,ty,tabH
    if fmt=='pc'then
        local left,right=logoX+K.width('COMMANDER',22,c.commander)+16,px-16;tw=math.min(96,math.floor((right-left)/n));tabH=barH
        if tw<56 then c.logo.Visible=false;left=math.max(24,(l.topbarLeft or 12)+16);tw=math.min(96,math.floor((right-left)/n))end
        tx0=math.clamp(math.floor((w-tw*n)/2),left,math.max(left,right-tw*n));ty=0
    elseif fmt=='ph'then
        tw=58;tabH=barH;tx0=math.max(92,(l.topbarLeft or 12)+16);ty=0
        if tx0+tw*n>px-8 then tw=math.max(48,math.floor((px-8-tx0)/n))end
    else tw=(w-16)/n;tabH=58;tx0=8;ty=h-58-(lift or 0);K.box(c.thumb,0,ty,w,58+(lift or 0));K.box(c.thumbLine,0,0,w,1)end
    local is=fmt=='ph'and 18 or 22;local wordSize=fmt=='pc'and 13 or 11
    local dots=M.dots(l)
    for i,t in ipairs(c.tabs)do
        local on=t.key==lit;local x=tx0+(i-1)*tw
        t.button.Visible=show;K.box(t.button,x,ty,tw,tabH)
        local iy=fmt=='pc'and 9 or fmt=='ph'and 7 or 10;local wy=fmt=='pc'and 34 or fmt=='ph'and 27 or 35
        K.box(t.icon,(tw-is)/2,iy,is,is);t.icon.ImageColor3=on and C.accent or C.muted
        t.word.TextSize=wordSize;K.box(t.word,0,wy,tw,wordSize+2);t.word.TextColor3=on and C.ink or C.muted
        t.word.FontFace=K.fonts[on and 800 or 600]or t.word.FontFace
        local ds=fmt=='pc'and 10 or fmt=='ph'and 8 or 9
        K.dot(t.button,'Dot20',dots[t.key]==true,math.floor((tw-is)/2)+is+7-ds/2,iy-4+ds/2,ds)
    end
    local li;for i,t in ipairs(c.tabs)do if t.key==lit then li=i end end
    c.mark.Visible=show and li~=nil
    if li then
        local mw=math.floor(tw*(fmt=='pt'and .4 or .44)+.5);local mx=math.floor(tx0+(li-1)*tw+(tw-mw)/2+.5)
        local my=fmt=='pt'and ty or barH-3
        local goal=UDim2.fromOffset(mx,my);c.mark.Size=UDim2.fromOffset(mw,3)
        if c.markLit and c.markLit~=lit and c.markFmt==fmt and not K.reduced then Tween:Create(c.mark,TweenInfo.new(.16,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut),{Position=goal}):Play()else c.mark.Position=goal end
        c.markLit=lit;c.markFmt=fmt
    end
    return fmt=='pt'and 64 or barH,fmt=='pt'and 58 or 0
end

function M.insets(w,h,lift)local fmt=format(w,h);return fmt=='pc'and 58 or fmt=='ph'and 46 or 64,fmt=='pt'and 58+(lift or 0)or(lift or 0)end
function M.dots(l)
    local p=l.account and l.account.progress
    local ok,status=pcall(function()return require(script.Parent.CollectionBadges).status(l)end);status=ok and status or {}
    local free=require(script.Parent.FreeDraw).ready(l.account and l.account.billing)
    return {missions=require(script.Parent.GoalClaims).count(p)>0,wardrobe=status.wardrobe~=nil,shop=free or status.shop~=nil,clan=M.clanDot(l)}
end
function M.clanDot(l)
    local Me=game:GetService('Players').LocalPlayer
    local unit=Me:GetAttribute('CommanderClan');if type(unit)~='string'or unit==''then return false end
    local v=l.unitView
    if not l.unitBusy and l.page~='clan'and not l.clanPeeking and (not v or os.clock()-(l.clanPeekAt or 0)>1800)then
        l.clanPeeking=true;l.clanPeekAt=os.clock()
        task.spawn(function()
            local ok,r=pcall(function()return game.ReplicatedStorage.FrontierNative:WaitForChild('ClanRequest',5):InvokeServer('read')end)
            l.clanPeeking=false
            if ok and type(r)=='table'and r.ok and not l.unitBusy and l.page~='clan'then l.unitView=r;if l.layout then l:layout()end end
        end)
    end
    local a=v and v.unit and v.attend
    return a~=nil and a.free~=true
end

local function door(f,name,filled,iconKey,label,onPress)
    local b=K.button(f,name,{kind=filled and 'pri'or 'none',r=10},onPress)
    local d={b=b}
    if filled then
        b.face.BackgroundColor3=Color3.new(1,1,1);b.baseFill=Color3.new(1,1,1)
        K.make('UIGradient',b.face,{Name='Door',Rotation=90,Color=ColorSequence.new(Color3.fromRGB(91,240,224),C.accent)})
    else
        b.face.BackgroundColor3=C.panel;b.face.BackgroundTransparency=.08;b.baseFill=C.panel;b.baseAlpha=.08
        b.faceStroke.Enabled=true;b.faceStroke.Color=C.accent;b.faceStroke.Thickness=2;b.faceStroke.Transparency=0;b.baseStroke=C.accent
    end
    d.icon=K.icon(b.face,iconKey,30,filled and C.bg or C.accent,'DoorIcon')
    d.title=K.text(b.face,'Title',label,25,filled and C.bg or C.ink,800);d.title.TextTruncate=Enum.TextTruncate.AtEnd
    d.capDot=K.make('Frame',b.face,{Name='CapDot',BackgroundColor3=C.good2,BorderSizePixel=0,Visible=false});K.round(d.capDot,'pill')
    d.cap=K.text(b.face,'Caption','',13,C.muted,700);d.cap.Visible=false
    d.chev=K.icon(b.face,'chev',22,filled and C.bg or C.muted,'Chevron')
    for _,o in ipairs({d.icon,d.title,d.capDot,d.cap,d.chev})do o.ZIndex=b.face.ZIndex+2 end
    return d
end
local function buildFloor(home)
    local c=build(home);if c.floor then return c end
    local l=home.lobby;local f=l.frame;c.floor=true
    if not home.single then home.single=require(script.Parent.SinglePlaySheet).new(home)end
    c.single=door(f,'SingleDoor20',true,'solo','싱글 플레이',function()
        require(script.Parent.TelemetryStep).step('lobby','homeTile',{item=l.firstLesson and 'lesson'or 'single'})
        M.confirm(c.single.b)
        if l.firstLesson then require(script.Parent.PressPending).begin();l:closePage();l.callbacks.learn()else home.single:show()end
    end)
    c.multi=door(f,'MultiDoor20',false,'fields','멀티 출전',function()
        require(script.Parent.TelemetryStep).step('lobby','homeTile',{item='multi'})
        home:go()
    end)
    c.multi.b.onRefuse=function()end
    c.cancel=K.button(c.multi.b.face,'Cancel20',{kind='plain',text='취소',size=14,weight=800},function()local d=l.deployment;if d and d.callbacks.cancel then d.callbacks.cancel()end end)
    c.cancel.button.Visible=false
    c.tag=K.chip(f,'CampaignTag20','캠페인 1-1','campaign',{size=13});c.tag.ZIndex=c.single.b.face.ZIndex+4
    for _,o in ipairs(c.tag:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=c.tag.ZIndex+1 end end
    c.halloween=K.chip(f,'HalloweenTag20','🎃 0/5','gold',{size=13,filled=true,icon=false});c.halloween.BackgroundColor3=Color3.fromRGB(255,140,40)
    c.halloween.ZIndex=c.multi.b.face.ZIndex+4;c.halloween.Visible=false
    for _,o in ipairs(c.halloween:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=c.halloween.ZIndex+1 end end
    c.party=K.button(f,'PartyPill20',{kind='none',r=10},function()l:openPage('friends')end)
    c.party.face.BackgroundColor3=C.panel;c.party.face.BackgroundTransparency=.15;c.party.baseFill=C.panel;c.party.baseAlpha=.15
    c.party.faceStroke.Enabled=true;c.party.faceStroke.Color=C.line;c.party.faceStroke.Transparency=0;c.party.baseStroke=C.line
    c.seats={}
    for i=1,5 do
        local s={}
        s.ring=K.icon(c.party.face,'dashRing',42,C.muted,'Seat'..i);s.ring.ImageTransparency=.55
        s.plus=K.icon(c.party.face,'plus',18,C.muted,'Plus'..i)
        s.face=K.avatar(c.party.face,'Face'..i,nil,42,C.accent,2)
        for _,o in ipairs({s.ring,s.plus,s.face})do o.ZIndex=c.party.face.ZIndex+2 end
        c.seats[i]=s
    end
    local fc,_,_,fl,fi=K.chip(c.party.face,'Online','0','accent',{size=14,icon='friends'});c.friends=fc
    c.friends.BackgroundColor3=C.good;if fl then fl.TextColor3=C.good end;if fi then fi.ImageColor3=C.good end
    c.friends.ZIndex=c.party.face.ZIndex+2
    c.fold=K.button(f,'Fold20',{kind='none',r=8,icon='fold',iconSize=18},function()M.toggleFold(home)end)
    c.fold.face.BackgroundColor3=Color3.fromRGB(6,9,13);c.fold.face.BackgroundTransparency=.45;c.fold.baseFill=c.fold.face.BackgroundColor3;c.fold.baseAlpha=.45
    c.fold.iconColorFixed=true;c.fold.iconImage.ImageColor3=C.muted
    c.notice=K.make('Frame',f,{Name='Notice20',BackgroundColor3=C.bg,BackgroundTransparency=.25,BorderSizePixel=0,Visible=false});K.round(c.notice,8);K.stroke(c.notice,C.line,1,0,true)
    c.noticeIcon=K.icon(c.notice,'notice',14,C.accent,'Icon');c.noticeText=K.text(c.notice,'Text','',12,C.ink,700)
    return c
end
function M.confirm(b)K.confirm(b,true)end

M.folded=false
function M.toggleFold(home)
    local c=home.c20;M.folded=not M.folded
    require(script.Parent.TelemetryStep).step('lobby',M.folded and 'foldStart'or 'unfoldStart',{})
    for _,o in ipairs({c.single.b.button,c.multi.b.button,c.party.button,c.tag,c.halloween})do
        if M.folded then K.leave(o,{dy=16,t=.12})end
    end
    if M.folded then task.delay(.13,function()home.lobby:layout()end)else home.lobby:layout();M.enter(home,true)end
end

function M.refresh(home)
    local c=home.c20;if not c then return end
    local l=home.lobby;local acct=l.account or {};local p=acct.progress or {}
    local lv='Lv '..tostring(p.level or 1);if c.level.Text~=lv then c.level.Text=lv end
    local coins=Theme.commas(math.floor(tonumber(p.medals)or 0));if c.coinValue.Text~=coins then local was=tonumber((c.coinValue.Text:gsub(',','')));
        if was and c.coinsSeen then K.roll(c.coinValue,was,tonumber(p.medals)or 0,nil,c.coins)else c.coinValue.Text=coins end;c.coinsSeen=true;c.layoutDirty=true end
    local ratio=(p.nextXP==0)and 1 or (tonumber(p.currentXP)or 0)/math.max(1,tonumber(p.nextXP)or 100)
    if c.xpRatio~=ratio then c.xp:set(ratio,c.xpRatio~=nil);c.xpRatio=ratio end
    if not c.floor then return end
    local s=l.data;local q=s and s.queue;local party=s and s.party;local me=Players.LocalPlayer.UserId
    local follower=party and #party.users>1 and party.leader~=me
    local title,cap='멀티 출전',nil
    if q or follower or(s and s.rejoin)then title=home.title.Text
        if q then
            local left=q.remaining and math.max(0,q.remaining-(os.clock()-(l.queueUpdated or os.clock())))
            cap=q.phase=='transferring'and '이동 중'or q.mode=='custom'and string.format('%d/%d명',q.count or 0,q.max or 0)or left and string.format('출발 %d:%02d',math.ceil(left)//60,math.ceil(left)%60)or '곧 출발'
        elseif follower then cap=string.format('파티 %d명',#party.users)
        else local r=s.rejoin;cap=(require(script.Parent.Parent.Maps.MapLoader).meta(r.map)or {}).label or tostring(r.map or '')end
    else
        local n,people=0,0
        for _,f in ipairs(l.deployment and l.deployment.fields or {})do if f.kind~='custom'then n+=1;people+=tonumber(f.count)or 0 end end
        cap=n==0 and '전장 찾는 중'or people>0 and string.format('%d명 대기',people)or string.format('전장 %d곳',n)
    end
    local m=c.multi;if m.title.Text~=title then m.title.Text=title;c.layoutDirty=true end
    if m.cap.Text~=cap then m.cap.Text=cap;c.layoutDirty=true end
    m.b:setEnabled(home.start:GetAttribute('Enabled')~=false,true)
    m.title.TextTransparency=m.b.enabled and 0 or .45
    c.cancelWanted=q~=nil and q.phase~='transferring'
    c.cancel:setEnabled(not l.busy and not(q and q.locked))
    local st=campaignNext(l);c.stage=st
    if st then local t=string.format('캠페인 %s',st.id);local l2=c.tag:FindFirstChild('Text');if l2 and l2.Text~=t then l2.Text=t;c.layoutDirty=true end end
    local hv=require(script.Parent.Parent.Core.HalloweenEvent).view(acct.billing and acct.billing.owned,workspace:GetServerTimeNow(),script.Parent.Parent:GetAttribute('HalloweenEndsAt'),acct.billing and acct.billing.halloween)
    local hw=hv.live and not hv.granted
    if hw then local t=string.format('🎃 %d/%d',hv.progress,hv.total);local l2=c.halloween:FindFirstChild('Text');if l2 and l2.Text~=t then l2.Text=t;c.layoutDirty=true end end
    if c.halloweenWanted~=hw then c.halloweenWanted=hw;c.layoutDirty=true
        if hw then require(script.Parent.TelemetryStep).once('halloween:tag','event','halloweenTag',{result='shown'})end end
    if hv.granted then pcall(require(script.Parent.HalloweenGift).check,l)end
    local users=party and party.users or {me};local key=table.concat(users,',')
    if c.partyKey~=key then c.partyKey=key;c.layoutDirty=true
        for i,seat in ipairs(c.seats)do local id=users[i]
            if id then local img='rbxthumb://type=AvatarHeadShot&id='..tostring(id)..'&w=150&h=150';if seat.face.Image~=img then seat.face.Image=img end
                local st2=seat.face:FindFirstChild('Stroke20');if st2 then st2.Color=id==me and C.accent or C.ink;st2.Transparency=id==me and 0 or .6 end end
            seat.id=id
        end
    end
    local online=0;for _,fr in ipairs(l.onlineFriends or {})do if fr.IsOnline~=false then online+=1 end end
    local ot=tostring(online);local tl=c.friends:FindFirstChild('Text');if tl and tl.Text~=ot then tl.Text=ot;c.layoutDirty=true end
    c.online=online
    local text=home.noticeOperator and home.noticeText.Text or ''
    if c.noticeText.Text~=text then c.noticeText.Text=text;c.layoutDirty=true end
    if c.layoutDirty and c.placed then c.layoutDirty=false;task.defer(function()if l.frame.Parent then l:layout()end end)end
end

local function rechip(chip,size)
    local t=chip:FindFirstChild('Text');local icon=chip:FindFirstChild('Icon');if not t then return chip.Size.X.Offset end
    local h=chip.Size.Y.Offset;local x=6;if icon then K.box(icon,6,math.floor((h-size)/2),size,size);x=6+size+4 end
    t.TextSize=size;local tw=K.width(t.Text,size,t);K.box(t,x,0,tw+2,h);local w=x+tw+6;chip.Size=UDim2.fromOffset(w,h);return w
end
local function placeDoor(d,x,y,w,h,fmt,showChev,cap)
    d.b:place(x,y,w,h)
    local pad=fmt=='pc'and 20 or fmt=='ph'and 14 or 12;local is=fmt=='pc'and 30 or 24;local gap=fmt=='pc'and 14 or fmt=='ph'and 10 or 8
    local fs=fmt=='pc'and 25 or fmt=='ph'and 19 or 18;local cs=fmt=='pt'and 11 or fmt=='ph'and 11 or 13;local chev=fmt=='pc'and 22 or 18
    K.box(d.icon,pad,(h-is)/2,is,is)
    local tx=pad+is+gap;local tw=w-tx-(showChev and pad+chev+6 or pad)
    d.title.TextSize=fs;d.chev.Visible=showChev;if showChev then K.box(d.chev,w-pad-chev,(h-chev)/2,chev,chev)end
    local hasCap=cap~=nil and cap~=''
    local lineH=fs+5;local capH=cs+2
    local block=hasCap and lineH+2+capH or lineH;local ty=math.floor((h-block)/2)
    K.box(d.title,tx,ty,tw,lineH);K.fit(d.title,tw,fs,math.max(14,fs-6))
    d.cap.Visible=hasCap;d.capDot.Visible=hasCap
    if hasCap then local dot=fmt=='pt'and 6 or 7;K.box(d.capDot,tx,ty+lineH+2+(capH-dot)/2,dot,dot);d.cap.TextSize=cs;K.box(d.cap,tx+dot+(fmt=='pt'and 5 or 6),ty+lineH+2,tw-dot-6,capH)end
end
local function Icons20(b,key)if b.iconImage then require(script.Parent.OutgameIcons).set(b.iconImage,key)end end
function M.home(home,w,h,short,q,lift,portrait)
    local l=home.lobby;local c=buildFloor(home);local fmt=format(w,h)
    if home.bTiles then for _,t in pairs(home.bTiles)do t.button.Visible=false end end
    local old={home.bParty or false,home.bSolo or false,home.bCamp and home.bCamp.frame or false,home.bSingle and home.bSingle.button or false,home.fold or false,home.start,home.notice,home.party,home.partyOptions,home.daily,home.goalStrip or false,home.select,home.list,home.quick,l.mission,l.motions,l.friends}
    for i=1,17 do local o=old[i];if o then o.Visible=false end end
    if home.queueCancel then home.queueCancel.Visible=false end
    home.mark.Visible=false;if home.pulse then home.pulse:Pause()end
    home.fieldPreview:layoutRows(0,0,100,52,false);home.fieldPreview.more.Visible=false
    require(script.Parent.LobbyJump).set(nil);home.toggleSpot=nil
    local foldable=fmt~='pc'
    local folded=foldable and M.folded
    local dw,dh,g,R,B
    if fmt=='pc'then dw,dh,g,R,B=250,88,12,28,28 elseif fmt=='ph'then dw,dh,g,R,B=196,66,8,16,14 else dh,g,R=64,8,16;dw=math.floor((w-R*2-g)/2)end
    local y=fmt=='pt'and(h-58-(lift or 0)-8-dh)or(h-B-dh-(lift or 0))
    local x2=w-R-dw;local x1=fmt=='pt'and R or x2-g-dw
    local show=not folded
    c.single.b.button.Visible=show;c.multi.b.button.Visible=show
    placeDoor(c.single,x1,y,dw,dh,fmt,fmt~='pt',nil)
    local queued=c.cancelWanted==true
    placeDoor(c.multi,x2,y,dw,dh,fmt,fmt~='pt'and not queued,c.multi.cap.Text)
    c.cancel.button.Visible=show and queued
    if queued then local bw=fmt=='pc'and 72 or 60;local bh=fmt=='pc'and 40 or 34;c.cancel:place(dw-bw-(fmt=='pc'and 14 or 10),(dh-bh)/2,bw,bh)
        c.cancel.button.ZIndex=c.multi.b.face.ZIndex+3;c.cancel.face.ZIndex=c.cancel.button.ZIndex;if c.cancel.label then c.cancel.label.ZIndex=c.cancel.button.ZIndex+1 end end
    c.tag.Visible=show and c.stage~=nil
    if c.tag.Visible then local ts=fmt=='pc'and 13 or fmt=='ph'and 11 or 12;local th=fmt=='pc'and 24 or fmt=='ph'and 20 or 22
        c.tag.Size=UDim2.fromOffset(c.tag.Size.X.Offset,th);local tw=rechip(c.tag,ts)
        local icon=c.tag:FindFirstChild('Icon');if icon then local is=fmt=='pc'and 14 or fmt=='ph'and 12 or 13;K.box(icon,6,math.floor((th-is)/2),is,is);local t=c.tag:FindFirstChild('Text');K.box(t,6+is+4,0,K.width(t.Text,ts,t)+2,th);tw=6+is+4+K.width(t.Text,ts,t)+6;c.tag.Size=UDim2.fromOffset(tw,th)end
        K.box(c.tag,x1+(fmt=='pt'and 10 or 12),y-(fmt=='pc'and 13 or 11),tw,th)end
    c.halloween.Visible=show and c.halloweenWanted==true
    if c.halloween.Visible then local ts=fmt=='pc'and 13 or fmt=='ph'and 11 or 12;local th=fmt=='pc'and 24 or fmt=='ph'and 20 or 22
        c.halloween.Size=UDim2.fromOffset(c.halloween.Size.X.Offset,th);local tw=rechip(c.halloween,ts)
        K.box(c.halloween,x2+(fmt=='pt'and 10 or 12),y-(fmt=='pc'and 13 or 11),tw,th)end
    local tablet=fmt=='pc'and require(script.Parent.InputMode).touch()
    local seat=fmt=='pc'and 42 or fmt=='ph'and 34 or 40;local open=tablet and 2 or fmt=='pc'and 4 or fmt=='ph'and 1 or 2
    local pad=fmt=='pc'and 10 or 8;local sg=fmt=='pc'and 8 or fmt=='ph'and 6 or 8;local pillH=seat+(fmt=='pt'and 12 or fmt=='pc'and 18 or 16)
    local users=0;for _,s in ipairs(c.seats)do if s.id then users+=1 end end
    local seats=math.min(5,math.max(users+open,1+open));if users>=5 then seats=5 end
    local x=pad
    for i,s in ipairs(c.seats)do
        local on=i<=seats;s.face.Visible=on and s.id~=nil;s.ring.Visible=on and s.id==nil;s.plus.Visible=on and s.id==nil
        if on then local sy=(pillH-seat)/2;K.box(s.face,x,sy,seat,seat);K.box(s.ring,x,sy,seat,seat);local ps=math.floor(seat*.42+.5);K.box(s.plus,x+(seat-ps)/2,sy+(seat-ps)/2,ps,ps);x+=seat+sg end
    end
    c.friends.Visible=(c.online or 0)>0
    if c.friends.Visible then local fh=fmt=='pc'and 26 or fmt=='ph'and 22 or 24;local fs=fmt=='pc'and 14 or fmt=='ph'and 12 or 13
        c.friends.Size=UDim2.fromOffset(0,fh);local fw=rechip(c.friends,fs);x+=2;K.box(c.friends,x-sg+sg,(pillH-fh)/2,fw,fh);x+=fw+sg end
    local pillW=x-sg+pad
    local py=fmt=='pt'and(y-12-pillH)or(h-B-pillH-(lift or 0))
    c.party.button.Visible=show;c.party:place(tablet and 168 or fmt=='pc'and 28 or 16,py,pillW,pillH)
    if tablet and show then
        local s=l.frame.AbsoluteSize.X/math.max(1,w);local origin=l.frame.AbsolutePosition
        require(script.Parent.LobbyJump).set(origin+Vector2.new(x2+dw-70,y-70-16)*s)
    end
    c.fold.button.Visible=foldable
    if foldable then
        Icons20(c.fold,folded and 'up'or 'fold')
        if folded then c.fold:place(w-16-44,(fmt=='pt'and h-58-(lift or 0)-8 or h-14-(lift or 0))-44,44,44)
        elseif fmt=='ph'then c.fold:place(x2+dw-40,y-40,40,32)
        else c.fold:place(w-16-44,py+4,44,44)end
    end
    local cr=l.copyright;cr.Visible=true;cr.TextSize=11;cr.TextColor3=C.muted;cr.TextTransparency=.4;cr.TextXAlignment=Enum.TextXAlignment.Left
    if fmt=='pt'then K.box(cr,16,104,220,16)elseif fmt=='ph'then K.box(cr,16,h-13,220,13)else K.box(cr,28,h-21,240,16)end
    local nt=c.noticeText.Text;c.notice.Visible=nt~=''
    if c.notice.Visible then local nw=math.min(w-32,K.width(nt,12,c.noticeText)+44);local ny=fmt=='pc'and 70 or fmt=='ph'and 54 or 112
        K.box(c.notice,(w-nw)/2,ny,nw,28);K.box(c.noticeIcon,12,7,14,14);K.box(c.noticeText,32,0,nw-42,28)end
    if home.hq and home.hqWanted and not q then home.hq.Visible=true;K.box(home.hq,fmt=='pt'and 16 or 24,fmt=='pc'and 70 or fmt=='ph'and 54 or 128,260,32)elseif home.hq then home.hq.Visible=false end
    do local V=require(script.Parent.VipLock);local spot=Vector2.new(x1-12,y)
        if V.spot~=spot then V.spot=spot;if V.wanted~=nil then V.hqPill(V.wanted)end end end
    c.placed=true
    if not c.homeShown then c.homeShown=true;M.enter(home,false)end
    if portrait then home.single:layout(w,h,true,false,math.max(8,(l.topbarHeight or 0)+4))else home.single:layout(w,h,false,short,short and 52 or 0)end
end
function M.enter(home,quick)
    local c=home.c20;if not c or not c.floor then return end
    local list={c.party.button,c.single.b.button,c.multi.b.button,c.tag,c.halloween}
    for i,o in ipairs(list)do if o.Visible then K.rehome(o);K.appear(o,{dy=16,t=.18,delay=quick and 0 or(i-1)*.04})end end
end
function M.hide(home)
    local c=home.c20;if not c or not c.floor then return end
    for _,o in ipairs({c.single.b.button,c.multi.b.button,c.party.button,c.tag,c.halloween,c.fold.button,c.notice,c.cancel.button})do o.Visible=false end
    c.homeShown=false
    local V=require(script.Parent.VipLock);if V.spot then V.spot=nil;if V.wanted~=nil then V.hqPill(V.wanted)end end
    if home.single then home.single.open=false;home.single.frame.Visible=false end
    home.fieldPreview:leaveRows()
end
return M
