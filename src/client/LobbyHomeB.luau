local Players=game:GetService('Players')
local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.OutgameIcons)
local BrandMark=require(script.Parent.BrandMark)
local TextService=game:GetService('TextService')
local L=require(script.Parent.Localization)
local Campaign=require(script.Parent.Parent.Core.CampaignRules)
local M={}
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
end
local function bar(p,x,y,w,h)
    UI.box(p.frame,x,y,w,h);UI.box(p.strip,0,0,3,h)
    UI.box(p.icon,12,(h-14)/2,14,14);local kw=math.min(90,math.ceil(textWidth(p.kicker.Text,13,p.kicker.Font))+12)
    UI.box(p.kicker,32,0,kw,h);UI.box(p.title,32+kw,0,w-kw-40,h);p.kicker.TextSize=13;p.title.TextSize=13
    p.kicker.TextXAlignment=Enum.TextXAlignment.Left;p.title.TextXAlignment=Enum.TextXAlignment.Left
end
local function dailyParts(home)
    home.dailySub.Visible=false;home.dailyReward.Visible=false;home.dailyKicker.Font=Enum.Font.BuilderSansBold
    return {frame=home.daily,strip=home.dailyStrip,icon=home.dailyIcon,kicker=home.dailyKicker,title=home.dailyTitle}
end
local function campaignState(home)
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
function M.layout(home,w,h,short,q,lift,portrait)
    if portrait then return M.portrait(home,w,h,q,lift)end
    local l=home.lobby;build(home);require(script.Parent.LobbyJump).set(nil);home.toggleSpot=nil
    local pad=short and 12 or 24
    local colW=short and math.min(262,w-pad*2-4*56-24)or 400;local x=w-pad-colW
    local dh=short and 58 or 76;local pw=short and 64 or 84;local dy=h-pad-dh-lift
    home.start.Visible=true;UI.box(home.start,x+pw+8,dy,colW-pw-8,dh)
    UI.box(home.title,16,short and 6 or 10,colW-pw-8-32,short and 28 or 36);home.title.TextSize=short and 24 or 30
    UI.box(home.sub,16,short and 34 or 46,colW-pw-8-32,short and 18 or 20);home.sub.TextSize=13
    home.mark.Visible=false
    if home.pulse then home.pulse:Pause();if home.glow then home.glow.Transparency=1 end end
    home.bParty.Visible=true;UI.box(home.bParty,x,dy,pw,dh)
    local fs=short and 28 or 36;UI.box(home.bPartyFace,(pw-fs)/2,short and 6 or 10,fs,fs);UI.box(home.bPartyText,0,dh-(short and 22 or 26),pw,20)
    local party=l.data and l.data.party;local users=party and party.users or {Players.LocalPlayer.UserId}
    local face='rbxthumb://type=AvatarHeadShot&id='..tostring(users[1])..'&w=150&h=150';if home.bPartyFace.Image~=face then home.bPartyFace.Image=face end
    home.bPartyText.Text=string.format('파티 %d/5',#users)
    local showDaily,showCamp=campaignState(home)
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
    local tw,th=short and 52 or 80,short and 58 or 80;local tg=8
    local creditH=short and 18 or 20;local tileBottom=h-lift-creditH-10
    if l.copyright.Visible then UI.box(l.copyright,pad,h-lift-creditH-2,math.min(300,w-colW-pad*3),creditH);l.copyright.TextSize=12;l.copyright.TextXAlignment=Enum.TextXAlignment.Left end
    badges(home)
    for i,t in ipairs(TILES)do local tile=home.bTiles[t[1]]
        tile.button.Visible=true;UI.box(tile.button,pad+(i-1)*(tw+tg),tileBottom-th,tw,th)
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
    for _,t in ipairs(TILES)do local tile=home.bTiles[t[1]];tile.button.Visible=t[1]~='clan'
        if tile.button.Visible then i+=1;UI.box(tile.button,pad+(i-1)*(tw+tg),ty,tw,th)end
        UI.box(tile.icon,(tw-22)/2,8,22,22);UI.box(tile.name,0,th-22,tw,20)
        tile.name.TextSize=textWidth(t[2],13,tile.name.Font)>tw-4 and 11 or 13
        local size=13;local tx=textWidth(tile.badge.Text,size,tile.badge.Font)
        if tx+12>tw then size=11;tx=textWidth(tile.badge.Text,size,tile.badge.Font)end
        tile.badge.TextSize=size;local bw=math.clamp(math.ceil(tx)+12,22,tw);UI.box(tile.badge,tw-bw+6,-8,bw,20)
    end
    local tilesRight=pad+3*tw+2*tg
    if l.motions.Visible then UI.box(l.motions,w-pad-76,ty+5,76,48)end
    local eye=48;local ex=w-pad-76-8-eye
    home.toggleSpot=ex>=tilesRight+8 and Vector2.new(ex,ty+5)or Vector2.new(w-pad-eye,ty+th+6)
    local dh,pw=58,64;local credit=l.copyright.Visible and 20 or 0;local dy=h-56-lift-8-credit-dh
    if credit>0 then UI.box(l.copyright,pad,dy+dh+3,math.min(220,colW),18);l.copyright.TextSize=12;l.copyright.TextXAlignment=Enum.TextXAlignment.Left end
    home.start.Visible=true;UI.box(home.start,x+pw+8,dy,colW-pw-8,dh)
    UI.box(home.title,16,6,colW-pw-8-32,28);home.title.TextSize=24
    UI.box(home.sub,16,34,colW-pw-8-32,18);home.sub.TextSize=13
    home.mark.Visible=false
    if home.pulse then home.pulse:Pause();if home.glow then home.glow.Transparency=1 end end
    home.bParty.Visible=true;UI.box(home.bParty,x,dy,pw,dh)
    UI.box(home.bPartyFace,(pw-28)/2,6,28,28);UI.box(home.bPartyText,0,dh-22,pw,20)
    local party=l.data and l.data.party;local users=party and party.users or {Players.LocalPlayer.UserId}
    local face='rbxthumb://type=AvatarHeadShot&id='..tostring(users[1])..'&w=150&h=150';if home.bPartyFace.Image~=face then home.bPartyFace.Image=face end
    home.bPartyText.Text=string.format('파티 %d/5',#users)
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
    local by=ry-8
    if home.notice.Visible then local nh=30;by-=nh;UI.box(home.notice,x,by,colW,nh)
        UI.box(home.noticeStrip,0,0,3,nh);UI.box(home.noticeIcon,12,(nh-14)/2,14,14);home.noticeKicker.Visible=false
        UI.box(home.noticeText,32,0,colW-40,nh);home.noticeText.TextWrapped=false;home.noticeText.TextYAlignment=Enum.TextYAlignment.Center;home.noticeText.TextSize=12
        by-=8
    end
    if showDaily then by-=barH;bar(dailyParts(home),x,by,colW,barH);by-=8 end
    if showCamp then by-=barH;bar(home.bCamp,x,by,colW,barH);by-=8 end
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
    return '출전','빠른 시작, 지금 열린 게임에 바로'
end
function M.hide(home)
    require(script.Parent.LobbyJump).set(nil);home.toggleSpot=nil
    if not home.bTiles then return end
    do local V=require(script.Parent.VipLock);if V.spot then V.spot=nil;if V.wanted~=nil then V.hqPill(V.wanted)end end end
    for _,t in pairs(home.bTiles)do t.button.Visible=false end;home.bParty.Visible=false;home.mark.Visible=true
    home.bCamp.frame.Visible=false
    local fp=home.fieldPreview;if fp.more.Parent~=fp.frame then fp.more.Parent=fp.frame end
    if home.pulse and not home.reduced then home.pulse:Play()end
    home.fieldPreview:leaveRows()
end
return M
