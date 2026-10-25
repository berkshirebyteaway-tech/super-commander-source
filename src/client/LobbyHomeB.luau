local Players=game:GetService('Players')
local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.OutgameIcons)
local BrandMark=require(script.Parent.BrandMark)
local TextService=game:GetService('TextService')
local L=require(script.Parent.Localization)
local Theme=require(script.Parent.Theme)
local function Step()return require(script.Parent.TelemetryStep)end
local Campaign=require(script.Parent.Parent.Core.CampaignRules)
local M={}
M.START_FLOW=true
local function campaignNext(l)
    local p=l.account and l.account.progress or {}
    if not(p.basicsComplete==true or p.tutorial==false or next(p.history or {})~=nil)then return nil end
    local cv=type(p.campaign)=='table'and p.campaign or {stars={},next=Campaign.stages[1].id}
    local stars=cv.stars or {};local s=Campaign.stage(cv.next)
    if not s or (tonumber(stars[s.id])or 0)%2==1 or not Campaign.unlocked({campaign={stars=stars}},s.id)then return nil end
    return s
end
local function textWidth(text,size,font)return TextService:GetTextSize(L.text(text),size,font,Vector2.new(1000,40)).X end
local TILES={{'clan','클랜','clan'},{'ranked','랭크','ranked'},{'friends','친구','friends'},{'watch','관전','watch'}}
local KEEP={friends=true,watch=true}
local function build(home)
    if home.bTiles then return end
    local l=home.lobby;local f=l.frame
    home.bTiles={}
    for _,t in ipairs(TILES)do
        local b=UI.button(f,'Tile_'..t[1],'',function()require(script.Parent.TelemetryStep).step('lobby','homeTile',{item=t[1]});if t[1]=='clan'then l.unitView=nil end;l:openPage(t[1])end)
        b.BackgroundColor3=UI.colors.panel;b.BackgroundTransparency=.12
        local icon=Icons.create(b,t[3],28,UI.colors.ink);icon.Name='Icon'
        local name=UI.label(b,'Name',t[2],13,UI.colors.ink);name.TextXAlignment=Enum.TextXAlignment.Center;name.TextWrapped=false
        local badge=UI.label(b,'Badge','',13,UI.colors.bg);badge.TextXAlignment=Enum.TextXAlignment.Center;badge.Font=Enum.Font.BuilderSansBold;badge.Visible=false;badge.ZIndex=b.ZIndex+3;badge:SetAttribute('AllowOverlap',true)
        UI.corner(badge,999);home.bTiles[t[1]]={button=b,icon=icon,name=name,badge=badge}
    end
    home.bParty=UI.button(f,'PartyBox','',function()l:openPage('friends')end);home.bParty.BackgroundColor3=UI.colors.panel;home.bParty.BackgroundTransparency=.12
    home.bPartyFace=UI.make('ImageLabel',home.bParty,{Name='Avatar',BackgroundColor3=UI.colors.bg,BorderSizePixel=0});UI.corner(home.bPartyFace,40)
    home.bPartyText=UI.label(home.bParty,'Count','',13,UI.colors.ink);home.bPartyText.TextXAlignment=Enum.TextXAlignment.Center;home.bPartyText.TextWrapped=false
    home.bSolo=UI.button(f,'SoloBox','',function()require(script.Parent.TelemetryStep).step('lobby','homeTile',{item='solo'});l.deployment.callbacks.solo()end)
    home.bSolo.BackgroundColor3=UI.colors.panel;home.bSolo.BackgroundTransparency=.12
    do local st=home.bSolo:FindFirstChildOfClass('UIStroke');if st then st.Color=UI.colors.accent;st.Transparency=.35 end end
    home.bSoloIcon=Icons.create(home.bSolo,'solo',28,UI.colors.accent);home.bSoloIcon.Name='Icon'
    home.bSoloText=UI.label(home.bSolo,'Name','혼자 하기',13,UI.colors.ink);home.bSoloText.TextXAlignment=Enum.TextXAlignment.Center;home.bSoloText.TextWrapped=false
    local c={};home.bCamp=c
    c.frame=UI.button(f,'CampaignBadge','',function()local st=home.bCampStage;if not st then return end
        require(script.Parent.TelemetryStep).step('lobby','homeTile',{item='campaign'})
        require(script.Parent.LobbyConfirm).open(l,st.name,st.brief,'출전',function()if not require(script.Parent.CampaignScreen).start(l,st.id)then l:closePage()end end,nil,st.map)end)
    c.frame.BackgroundColor3=UI.colors.bg;c.frame.BackgroundTransparency=.25
    local cs=c.frame:FindFirstChildOfClass('UIStroke');if cs then cs.Color=UI.colors.line;cs.Transparency=.2 end
    c.strip=require(script.Parent.EdgeMask).fit(UI.make('Frame',c.frame,{Name='Strip',BackgroundColor3=UI.colors.gold,BorderSizePixel=0}))
    c.icon=Icons.create(c.frame,'campaign',14,UI.colors.gold);c.icon.Name='Icon'
    for _,k in ipairs({{'kicker','Kicker','캠페인',UI.colors.gold},{'title','Title','',UI.colors.ink}})do
        local t=UI.label(c.frame,k[2],k[3],13,k[4]);t.TextWrapped=false;t.TextTruncate=Enum.TextTruncate.AtEnd;c[k[1]]=t end
    c.kicker.Font=Enum.Font.BuilderSansBold
    local sb=UI.button(f,'SinglePlay','',function()
        Step().step('lobby','homeTile',{item=l.firstLesson and 'lesson'or 'single'})
        if l.firstLesson then l:closePage();l.callbacks.learn()else home.single:show()end
    end,true);sb.Visible=false;home.bSingle={button=sb};sb.BackgroundColor3=Color3.new(1,1,1)
    UI.make('UIGradient',sb,{Name='Sheen',Color=ColorSequence.new(UI.colors.accent,UI.colors.accent:Lerp(UI.colors.ice,.35))})
    do local st=sb:FindFirstChildOfClass('UIStroke');if st then st.Color=UI.colors.ice;st.Thickness=2 end end
    home.bSingle.icon=Icons.create(sb,'solo',36,UI.colors.bg);home.bSingle.icon.Name='Icon'
    home.bSingle.title=UI.label(sb,'Title','싱글 플레이',30,UI.colors.bg);home.bSingle.title.TextWrapped=false;Theme.display(home.bSingle.title)
    home.bSingle.sub=UI.label(sb,'Sub','AI 상대로 바로 한 판',14,UI.colors.bg);home.bSingle.sub.TextWrapped=false;home.bSingle.sub.TextTruncate=Enum.TextTruncate.AtEnd;home.bSingle.sub.Font=Enum.Font.BuilderSans
    home.bSingle.chev=UI.label(sb,'Chevron','›',30,UI.colors.bg);home.bSingle.chev.TextXAlignment=Enum.TextXAlignment.Center
    home.single=require(script.Parent.SinglePlaySheet).new(home)
    local fold=UI.button(f,'StartFold','',function()M.toggleFold(home)end);fold.Visible=false;home.fold=fold
    fold.BackgroundColor3=UI.colors.bg;fold.BackgroundTransparency=.3
    home.foldText=UI.label(fold,'Label','',15,UI.colors.ink);home.foldText.TextXAlignment=Enum.TextXAlignment.Center;home.foldText.TextWrapped=false
end
M.folded=false
function M.foldable()local UIS=game:GetService('UserInputService');return M.START_FLOW and UIS.TouchEnabled and not UIS.MouseEnabled end
function M.toggleFold(home)
    local l=home.lobby;local T=game:GetService('TweenService');local moving={home.bSingle.button,home.start}
    Step().step('lobby',M.folded and 'unfoldStart'or 'foldStart',{})
    if not M.folded then
        local info=TweenInfo.new(.16,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
        for _,o in ipairs(moving)do T:Create(o,info,{Position=o.Position+UDim2.fromOffset(0,220)}):Play()end
        task.delay(.16,function()M.folded=true;l:layout()end)
    else
        M.folded=false;l:layout()
        local info=TweenInfo.new(.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
        for _,o in ipairs(moving)do local final=o.Position;o.Position=final+UDim2.fromOffset(0,220);T:Create(o,info,{Position=final}):Play()end
    end
end
local function foldStack(home,q,ox,oy,ow,oh,cx,cy,cw)
    local b=home.fold;local can=M.foldable();b.Visible=can;if not can then return end
    local st=b:FindFirstChildOfClass('UIStroke')
    if M.folded then
        home.bSingle.button.Visible=false;home.start.Visible=false;home.notice.Visible=false
        UI.box(b,cx,cy,cw,48);home.foldText.Text=q and '대기 중  ▲'or '시작  ▲';home.foldText.TextColor3=UI.colors.accent
        if st then st.Color=UI.colors.accent;st.Transparency=.2 end
    else
        UI.box(b,ox,oy,ow,oh);home.foldText.Text='▼';home.foldText.TextColor3=UI.colors.ink
        if st then st.Color=UI.colors.line;st.Transparency=.2 end
    end
    UI.box(home.foldText,0,0,b.Size.X.Offset,b.Size.Y.Offset)
end
local function singleBox(home,x,y,w,h,big,bare)
    local b=home.bSingle;b.button.Visible=true;UI.box(b.button,x,y,w,h)
    local is=big and 40 or 30;UI.box(b.icon,big and 18 or 14,(h-is)/2,is,is);b.icon.Visible=not bare
    local tx=bare and 16 or (big and 18 or 14)+is+(big and 14 or 10);local tw=w-tx-40
    UI.box(b.title,tx,(h-(big and 40 or 32))/2,tw,big and 40 or 32);b.title.TextSize=big and 30 or h<70 and 20 or 24
    b.sub.Visible=false
    UI.box(b.chev,w-36,0,28,h);b.chev.TextSize=big and 30 or 24
end
local function multiLook(home,q)
    local on=M.START_FLOW and not q;local st=home.start:FindFirstChildOfClass('UIStroke')
    local sheen=home.start:FindFirstChild('Sheen');if sheen then sheen.Enabled=not on end
    home.start.BackgroundColor3=on and UI.colors.panel or Color3.new(1,1,1);home.start.BackgroundTransparency=on and .08 or 0
    if st then st.Color=on and UI.colors.accent or UI.colors.ice;st.Thickness=2;st.Transparency=on and .25 or 0 end
    home.title.TextColor3=on and UI.colors.ink or UI.colors.bg;home.sub.TextColor3=on and UI.colors.muted or UI.colors.bg
end
local function multiCaption(l)
    local d=l.deployment;local n,people=0,0
    for _,f in ipairs(d and d.fields or (l.data and l.data.battlefields and l.data.battlefields.fields)or {})do
        if f.kind~='custom'then n+=1;people+=tonumber(f.count)or 0 end
    end
    if n==0 then return '공식 전장을 찾는 중…'end
    return people>0 and string.format('공식 전장 %d곳, %d명 대기',n,people)or string.format('공식 전장 %d곳 열림',n)
end
local function bar(p,x,y,w,h)
    UI.box(p.frame,x,y,w,h);UI.box(p.strip,0,0,3,h)
    UI.box(p.icon,12,(h-14)/2,14,14);local kw=math.min(90,math.ceil(textWidth(p.kicker.Text,13,p.kicker.Font))+12)
    UI.box(p.kicker,32,0,kw,h);UI.box(p.title,32+kw,0,w-kw-40,h);p.kicker.TextSize=13;p.title.TextSize=13
    p.kicker.TextXAlignment=Enum.TextXAlignment.Left;p.title.TextXAlignment=Enum.TextXAlignment.Left
end
local function soloBox(home,x,y,w,h,iconSize,iconY,textH)
    home.bSolo.Visible=true;UI.box(home.bSolo,x,y,w,h);UI.box(home.bSoloIcon,(w-iconSize)/2,iconY,iconSize,iconSize);UI.box(home.bSoloText,0,h-textH,w,20)
    home.bSoloText.TextSize=textWidth(home.bSoloText.Text,13,home.bSoloText.Font)>w-6 and 11 or 13
end
local function dailyParts(home)
    home.dailySub.Visible=false;home.dailyReward.Visible=false;home.dailyKicker.Font=Enum.Font.BuilderSansBold
    return {frame=home.daily,strip=home.dailyStrip,icon=home.dailyIcon,kicker=home.dailyKicker,title=home.dailyTitle}
end
local function campaignState(home)
    if M.START_FLOW then home.daily.Visible=false;home.bCamp.frame.Visible=false;home.bCampStage=nil;return false,false end
    local st=not home.lobby.firstLesson and campaignNext(home.lobby)or nil;home.bCampStage=st
    local showDaily=home:available('daily')and not home.listOpen
    home.daily.Visible=showDaily;home.bCamp.frame.Visible=st~=nil
    if st then home.bCamp.title.Text=st.name;require(script.Parent.TelemetryStep).once('campaign:bar','campaign','barShown',{item='stage_'..tostring(st.id):gsub('%-','_'),result='shown'})end
    return showDaily,st~=nil
end
local function badges(home)
    local l=home.lobby;local s=l.data or {}
    local season=s.ranked and s.ranked.season
    local friends=(s.invites and #s.invites or 0);for _,fr in ipairs(l.onlineFriends or {})do if fr.PlaceId==game.PlaceId then friends+=1 end end
    local live=s.live and #s.live or 0
    local seasonText=type(season)=='table'and season.label or nil
    local set={ranked=seasonText and {seasonText,UI.colors.gold,true}or nil,friends=friends>0 and {tostring(friends),UI.colors.gold}or nil,watch=live>0 and {'LIVE',UI.colors.danger}or nil}
    for key,t in pairs(home.bTiles)do local v=set[key];t.badge.Visible=v~=nil
        if v then t.badge.Text=v[1];t.badge.BackgroundColor3=v[2];t.badge.BackgroundTransparency=0;t.badge.TextColor3=key=='watch'and UI.colors.ink or UI.colors.bg end end
end
local function partyFaces(home,bw,bh,fs)
    local party=home.lobby.data and home.lobby.data.party;local users=party and party.users or {}
    home.startFaces=home.startFaces or UI.make('Frame',home.start,{Name='PartyFaces',BackgroundTransparency=1})
    local shown=#users>1;home.startFaces.Visible=shown;if not shown then return end
    local n=math.min(3,#users);local step=fs-8;local fw=fs+(n-1)*step+(#users>3 and 30 or 0)
    UI.box(home.startFaces,bw-16-fw-18,(bh-fs)/2,fw,fs)
    for i=1,3 do local f=home.startFaces:FindFirstChild('Face'..i)
        if not f then f=UI.make('ImageLabel',home.startFaces,{Name='Face'..i,BackgroundColor3=UI.colors.bg,BorderSizePixel=0,ZIndex=home.start.ZIndex+1});UI.corner(f,40);UI.stroke(f,UI.colors.accent,2)end
        f.Visible=i<=n;if i<=n then UI.box(f,(i-1)*step,0,fs,fs);local img='rbxthumb://type=AvatarHeadShot&id='..tostring(users[i])..'&w=150&h=150';if f.Image~=img then f.Image=img end end
    end
    local more=home.startFaces:FindFirstChild('More')or UI.label(home.startFaces,'More','',13,UI.colors.ink)
    more.Visible=#users>3;more.Text='+'..(#users-3);UI.box(more,fs+(n-1)*step+4,0,26,fs)
    home.title.Size=UDim2.fromOffset(math.min(home.title.Size.X.Offset,bw-16-fw-26-16),home.title.Size.Y.Offset)
    home.sub.Size=UDim2.fromOffset(math.min(home.sub.Size.X.Offset,bw-16-fw-26-16),home.sub.Size.Y.Offset)
end
function M.layout(home,w,h,short,q,lift,portrait)
    if portrait then M.portrait(home,w,h,q,lift);home.single:layout(w,h,true,false,math.max(8,(home.lobby.topbarHeight or 0)+4));return end
    local l=home.lobby;build(home);require(script.Parent.LobbyJump).set(nil);home.toggleSpot=nil
    local pad=short and 12 or 24
    local colW=short and math.min(262,w-pad*2-4*56-24)or 400
    if M.START_FLOW then colW=short and math.min(320,w-pad*2-4*56-24)or 480 end
    local x=w-pad-colW;local half=(colW-10)/2
    local dh=short and 58 or 76;local pw=short and 64 or 84;local dy=h-pad-dh-lift
    local px=M.START_FLOW and half+10 or pw+8
    home.start.Visible=true;UI.box(home.start,x+px,dy,colW-px,dh)
    UI.box(home.title,16,short and 6 or 10,colW-px-32,short and 28 or 36);home.title.TextSize=M.START_FLOW and (short and 20 or 24)or short and 24 or 30
    UI.box(home.sub,16,short and 34 or 46,colW-px-32,short and 18 or 20);home.sub.TextSize=13
    home.mark.Visible=false
    if home.pulse then home.pulse:Pause();if home.glow then home.glow.Transparency=1 end end
    multiLook(home,q)
    if M.START_FLOW then home.bSolo.Visible=false;home.bParty.Visible=false;partyFaces(home,half,dh,short and 28 or 36)
    else home.bParty.Visible=true;UI.box(home.bParty,x-8-pw,dy,pw,dh)
    soloBox(home,x,dy,pw,dh,short and 28 or 36,short and 6 or 10,short and 22 or 26)end
    local fs=short and 28 or 36;UI.box(home.bPartyFace,(pw-fs)/2,short and 6 or 10,fs,fs);UI.box(home.bPartyText,0,dh-(short and 22 or 26),pw,20)
    local party=l.data and l.data.party;local users=party and party.users or {Players.LocalPlayer.UserId}
    local face='rbxthumb://type=AvatarHeadShot&id='..tostring(users[1])..'&w=150&h=150';if home.bPartyFace.Image~=face then home.bPartyFace.Image=face end
    home.bPartyText.Text=string.format('파티 %d/5',#users)
    local showDaily,showCamp=campaignState(home)
    if M.START_FLOW then
        home.fieldPreview:layoutRows(x,0,colW,52,false);home.fieldPreview.more.Visible=false
        local sh=dh;local sy=dy;singleBox(home,x,sy,half,sh,false,short)
        do local V=require(script.Parent.VipLock);local spot=Vector2.new(x-12,sy)
            if V.spot~=spot then V.spot=spot;if V.wanted~=nil then V.hqPill(V.wanted)end end end
        if home.notice.Visible then local nh=short and 30 or 58;local ny=sy-8-nh
            if ny<l.profile.Position.Y.Offset+l.profile.Size.Y.Offset+8 then home.notice.Visible=false else UI.box(home.notice,x,ny,colW,nh)
                if short then
                    UI.box(home.noticeStrip,0,0,3,nh);UI.box(home.noticeIcon,12,(nh-14)/2,14,14);home.noticeKicker.Visible=false
                    UI.box(home.noticeText,32,0,colW-40,nh);home.noticeText.TextWrapped=false;home.noticeText.TextYAlignment=Enum.TextYAlignment.Center;home.noticeText.TextSize=12
                end
            end
        end
        foldStack(home,q,x-8-48,sy,48,sh,x+colW-124,dy+dh-48,124)
    else
        local rowH=short and 52 or 60;local mh=short and 48 or 40
        if short then
            local top=l.profile.Position.Y.Offset+l.profile.Size.Y.Offset+8
            local function fits()local extra=(showDaily and 42 or 0)+(home.notice.Visible and 38 or 0)+(showCamp and 42 or 0)
                for _,s in ipairs({{52,48},{48,48},{48,44},{46,44},{46,40}})do
                    rowH,mh=s[1],s[2];if dy-8-mh-8-(rowH*3+16)-extra>=top then return true end
                end end
            if not fits()and showDaily then showDaily=false;home.daily.Visible=false end
            if not fits()and showCamp then showCamp=false;home.bCamp.frame.Visible=false;fits()end
        end
        local rowsFit=not short or dy-8-mh-8-(rowH*3+16)-(home.daily.Visible and 38 or 0)-(home.notice.Visible and 38 or 0)>=l.profile.Position.Y.Offset+l.profile.Size.Y.Offset+8
        local more=home.fieldPreview.more
        local rowsH=home.fieldPreview:layoutRows(x,0,colW,rowH,rowsFit)
        local listY=dy-8-mh
        more.Parent=l.frame;more.Visible=true;UI.box(more,x,listY,colW,mh);more.TextSize=14;more.ZIndex=home.start.ZIndex
        local ry=listY-8-rowsH;home.fieldPreview.frame.Position=UDim2.fromOffset(x,ry)
        do local V=require(script.Parent.VipLock);local spot=Vector2.new(x-12,ry)
            if V.spot~=spot then V.spot=spot;if V.wanted~=nil then V.hqPill(V.wanted)end end end
        local by=ry-8
        local bh=short and 30 or 32
        if showDaily then by-=bh;bar(dailyParts(home),x,by,colW,bh);by-=8 end
        if showCamp then by-=bh;bar(home.bCamp,x,by,colW,bh);by-=8 end
        if home.notice.Visible then local nh=short and 30 or 58;by-=nh;UI.box(home.notice,x,by,colW,nh)
            if short then
                UI.box(home.noticeStrip,0,0,3,nh);UI.box(home.noticeIcon,12,(nh-14)/2,14,14);home.noticeKicker.Visible=false
                UI.box(home.noticeText,32,0,colW-40,nh);home.noticeText.TextWrapped=false;home.noticeText.TextYAlignment=Enum.TextYAlignment.Center;home.noticeText.TextSize=12
            end
        end
    end
    local tw,th=short and 52 or 80,short and 58 or 80;local tg=8
    local creditH=short and 18 or 20;local tileBottom=h-lift-creditH-10
    if l.copyright.Visible then UI.box(l.copyright,pad,h-lift-creditH-2,math.min(300,w-colW-pad*3),creditH);l.copyright.TextSize=12;l.copyright.TextXAlignment=Enum.TextXAlignment.Left end
    badges(home)
    local rk=require(script.Parent.Parent.Core.HiddenScreens).ranked()
    local i=0
    for _,t in ipairs(TILES)do local tile=home.bTiles[t[1]]
        tile.button.Visible=(t[1]~='ranked'or rk)and(not M.START_FLOW or KEEP[t[1]]==true);if tile.button.Visible then i+=1 end
        UI.box(tile.button,pad+(i-1)*(tw+tg),tileBottom-th,tw,th)
        local is=short and 22 or 28;UI.box(tile.icon,(tw-is)/2,short and 8 or 14,is,is)
        UI.box(tile.name,0,th-(short and 22 or 28),tw,20)
        tile.name.TextSize=textWidth(t[2],13,tile.name.Font)>tw-4 and 11 or 13
        local size=13;local tx=textWidth(tile.badge.Text,size,tile.badge.Font)
        if tx+12>tw then size=11;tx=textWidth(tile.badge.Text,size,tile.badge.Font)end
        tile.badge.TextSize=size;local bw=math.clamp(math.ceil(tx)+12,22,tw);UI.box(tile.badge,tw-bw+6,-8,bw,20)
    end
    home.party.Visible=false;home.partyOptions.Visible=false;l.mission.Visible=false;home.goalStrip.Visible=false;home.hq.Visible=home.hq.Visible and not short
    if home.hq.Visible then UI.box(home.hq,pad,tileBottom-th-40,280,32)end
    if l.motions.Visible then UI.box(l.motions,pad,tileBottom-th-(short and 52 or 60),short and 84 or 104,short and 44 or 48)end
    if l.motions.Visible then
        local mp,ms=l.motions.Position,l.motions.Size
        local right=mp.X.Offset+ms.X.Offset;if home.hq.Visible then right=math.max(right,pad+280)end
        home.toggleSpot=Vector2.new(right+8,mp.Y.Offset+ms.Y.Offset-48)
    else home.toggleSpot=Vector2.new(pad,tileBottom-th-8-48)end
    home.single:layout(w,h,false,short,short and 52 or 0)
end
function M.portrait(home,w,h,q,lift)
    local l=home.lobby;build(home)
    local pad=12;local x=pad;local colW=w-pad*2
    local left=pad;local y0=math.max(8,(l.topbarHeight or 0)+4)
    local px=w-146-pad;l.profile.Visible=true;UI.box(l.profile,px,y0,146,44)
    local room=px-8-left;local markW=BrandMark.available(home.brandMark)and 42 or 0
    if room<166+markW-4 then markW=0 end
    home.brandMark.Visible=markW>0
    UI.box(l.header,left,y0,166+math.max(0,markW-4),44);UI.box(l.brandTop,8+markW,4,180,12);UI.box(l.brand,8+markW,14,180,28)
    if markW>0 then UI.box(home.brandMark,2,1,markW,markW)end
    l.header.Visible=room>=166
    local tw,th,tg=52,58,6;local ty=y0+52
    local showDaily,showCamp=campaignState(home)
    badges(home)
    local i=0
    local rk=require(script.Parent.Parent.Core.HiddenScreens).ranked()
    for _,t in ipairs(TILES)do local tile=home.bTiles[t[1]];tile.button.Visible=t[1]~='clan'and (t[1]~='ranked'or rk)and(not M.START_FLOW or KEEP[t[1]]==true)
        if tile.button.Visible then i+=1;UI.box(tile.button,pad+(i-1)*(tw+tg),ty,tw,th)end
        UI.box(tile.icon,(tw-22)/2,8,22,22);UI.box(tile.name,0,th-22,tw,20)
        tile.name.TextSize=textWidth(t[2],13,tile.name.Font)>tw-4 and 11 or 13
        local size=13;local tx=textWidth(tile.badge.Text,size,tile.badge.Font)
        if tx+12>tw then size=11;tx=textWidth(tile.badge.Text,size,tile.badge.Font)end
        tile.badge.TextSize=size;local bw=math.clamp(math.ceil(tx)+12,22,tw);UI.box(tile.badge,tw-bw+6,-8,bw,20)
    end
    local tilesRight=pad+i*tw+math.max(0,i-1)*tg
    if l.motions.Visible then UI.box(l.motions,w-pad-76,ty+5,76,48)end
    local eye=48;local ex=w-pad-76-8-eye
    home.toggleSpot=ex>=tilesRight+8 and Vector2.new(ex,ty+5)or Vector2.new(w-pad-eye,ty+th+6)
    local dh,pw=58,64;local credit=l.copyright.Visible and 20 or 0;local dy=h-56-lift-8-credit-dh
    if credit>0 then UI.box(l.copyright,pad,dy+dh+3,math.min(220,colW),18);l.copyright.TextSize=12;l.copyright.TextXAlignment=Enum.TextXAlignment.Left end
    local half=(colW-10)/2
    local sx=M.START_FLOW and half+10-(pw+8)or pw+8
    home.start.Visible=true;UI.box(home.start,x+sx+pw+8,dy,colW-sx-pw-8,dh)
    UI.box(home.title,16,6,colW-sx-pw-8-32,28);home.title.TextSize=M.START_FLOW and 20 or 24
    UI.box(home.sub,16,34,colW-sx-pw-8-32,18);home.sub.TextSize=12
    if M.START_FLOW then home.bSolo.Visible=false else soloBox(home,x+sx,dy,pw,dh,28,6,22)end
    home.mark.Visible=false
    if home.pulse then home.pulse:Pause();if home.glow then home.glow.Transparency=1 end end
    multiLook(home,q)
    home.bParty.Visible=not M.START_FLOW;UI.box(home.bParty,x,dy,pw,dh);if M.START_FLOW then partyFaces(home,half,dh,28)end
    UI.box(home.bPartyFace,(pw-28)/2,6,28,28);UI.box(home.bPartyText,0,dh-22,pw,20)
    local party=l.data and l.data.party;local users=party and party.users or {Players.LocalPlayer.UserId}
    local face='rbxthumb://type=AvatarHeadShot&id='..tostring(users[1])..'&w=150&h=150';if home.bPartyFace.Image~=face then home.bPartyFace.Image=face end
    home.bPartyText.Text=string.format('파티 %d/5',#users)
    local by
    if M.START_FLOW then
        home.fieldPreview:layoutRows(x,0,colW,52,false);home.fieldPreview.more.Visible=false
        local sh=dh;local sy=dy;singleBox(home,x,sy,half,sh,false,half<190);by=sy-8
        if home.notice.Visible then local nh=30;by-=nh;UI.box(home.notice,x,by,colW,nh)
            UI.box(home.noticeStrip,0,0,3,nh);UI.box(home.noticeIcon,12,(nh-14)/2,14,14);home.noticeKicker.Visible=false
            UI.box(home.noticeText,32,0,colW-40,nh);home.noticeText.TextWrapped=false;home.noticeText.TextYAlignment=Enum.TextYAlignment.Center;home.noticeText.TextSize=12
            by-=8
        end
        foldStack(home,q,x+colW-64,by-52,64,48,x+colW-124,dy+dh-48,124)
    else
        local top=ty+th+(home.toggleSpot.Y>ty+th and 60 or 10)
        local rowH,mh=52,48
        local barH=44
        local function stack()return 8+rowH+(home.notice.Visible and 38 or 0)+(showDaily and barH+8 or 0)+(showCamp and barH+8 or 0)end
        local function fits()for _,s in ipairs({{52,48},{48,48},{48,44},{46,44}})do rowH,mh=s[1],s[2];if dy-stack()-96>=top then return true end end end
        if not fits()and showDaily then showDaily=false;home.daily.Visible=false end
        if not fits()and showCamp then showCamp=false;home.bCamp.frame.Visible=false end
        if not fits()and home.notice.Visible then home.notice.Visible=false;fits()end
        local more=home.fieldPreview.more
        local rowsH=home.fieldPreview:layoutRows(x,0,colW,rowH,true,true)
        for _,c in pairs(home.fieldPreview.cards)do if c.row and c.place then
            local tx=c.title.Position.X.Offset;local tw2=math.min(120,colW-tx-124)
            c.title.Size=UDim2.fromOffset(tw2,c.title.Size.Y.Offset);c.row.x=tx+tw2+6;c.row.w=colW-tx-tw2-6-108;c.place()
        end end
        local ry=dy-8-rowsH;home.fieldPreview.frame.Position=UDim2.fromOffset(x,ry)
        more.Parent=l.frame;more.Visible=true;UI.box(more,x+colW-100,ry+(rowH-44)/2,96,44);more.TextSize=13;more.ZIndex=home.start.ZIndex+6
        by=ry-8
        if home.notice.Visible then local nh=30;by-=nh;UI.box(home.notice,x,by,colW,nh)
            UI.box(home.noticeStrip,0,0,3,nh);UI.box(home.noticeIcon,12,(nh-14)/2,14,14);home.noticeKicker.Visible=false
            UI.box(home.noticeText,32,0,colW-40,nh);home.noticeText.TextWrapped=false;home.noticeText.TextYAlignment=Enum.TextYAlignment.Center;home.noticeText.TextSize=12
            by-=8
        end
        if showDaily then by-=barH;bar(dailyParts(home),x,by,colW,barH);by-=8 end
        if showCamp then by-=barH;bar(home.bCamp,x,by,colW,barH);by-=8 end
    end
    do local V=require(script.Parent.VipLock);local spot=Vector2.new(w-pad,ty+th+(home.toggleSpot.Y>ty+th and 62 or 8))
        if V.spot~=spot then V.spot=spot;if V.wanted~=nil then V.hqPill(V.wanted)end end end
    home.party.Visible=false;home.partyOptions.Visible=false;l.mission.Visible=false;home.goalStrip.Visible=false
    if home.hq.Visible then UI.box(home.hq,x,by-32,math.min(colW,280),32);by-=40 end
    local s=require(script.Parent.Theme).scale or 1;local origin=l.frame.AbsolutePosition
    require(script.Parent.LobbyJump).set(not require(script.Parent.LobbyUIToggle).hidden and origin+Vector2.new(w-pad-70,by-70)*s or nil)
end
function M.caption(home,title,sub,q,follower)
    local fp=home.fieldPreview;local l=home.lobby
    if not fp.rows or q or follower or l.firstLesson or home.mode~='quick'or (l.data and l.data.rejoin)then return title,sub end
    if M.START_FLOW then return '멀티 출전',multiCaption(l)end
    return '출전','빠른 시작, 지금 열린 게임에 바로'
end
function M.hide(home)
    require(script.Parent.LobbyJump).set(nil);home.toggleSpot=nil
    if not home.bTiles then return end
    do local V=require(script.Parent.VipLock);if V.spot then V.spot=nil;if V.wanted~=nil then V.hqPill(V.wanted)end end end
    for _,t in pairs(home.bTiles)do t.button.Visible=false end;home.bParty.Visible=false;home.bSolo.Visible=false;home.mark.Visible=true;if home.fold then home.fold.Visible=false end
    home.bSingle.button.Visible=false;home.single.open=false;home.single.frame.Visible=false
    home.bCamp.frame.Visible=false
    local fp=home.fieldPreview;if fp.more.Parent~=fp.frame then fp.more.Parent=fp.frame end
    if home.pulse and not home.reduced then home.pulse:Play()end
    home.fieldPreview:leaveRows()
end
return M
