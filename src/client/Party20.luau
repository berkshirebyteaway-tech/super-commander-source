local Players=game:GetService('Players')
local K=require(script.Parent.Kit20)
local S=require(script.Parent.Sheet20)
local Localization=require(script.Parent.Localization)
local C=K.colors
local M={}
local DANGER_TEXT=Color3.fromRGB(255,138,138)
local function commas(n)local s=tostring(math.floor(n or 0));local out=s:reverse():gsub('(%d%d%d)','%1,'):reverse();return (out:gsub('^,',''))end

local function row(parent,fmt,x,y,w,spec)
    local pt,ph=fmt=='pt',fmt=='ph'
    local h=pt and 54 or ph and 40 or 54
    local f=K.make('Frame',parent,{Name='Row_'..spec.id,BackgroundColor3=C.panel,BorderSizePixel=0})
    K.round(f,8);K.box(f,x,y,w,h)
    if pt then K.stroke(f,spec.invite and C.accent or C.line,spec.invite and 2 or 1,0,true)end
    local pad=pt and 11 or ph and 8 or 12;local av=pt and 34 or ph and 28 or 38;local ds=pt and 11 or ph and 9 or 11
    local face=K.avatar(f,'Avatar',spec.userId,av);K.box(face,pad,(h-av)/2,av,av)
    if not pt then local dot=K.make('Frame',f,{Name='Status',BackgroundColor3=spec.dot,BorderSizePixel=0,ZIndex=3});K.round(dot,'pill');K.stroke(dot,C.panel,2);K.box(dot,pad+av-ds+1,(h-av)/2+av-ds+1,ds,ds)end
    local tx=pad+av+(pt and 10 or 12)
    local bw,bh=pt and 72 or ph and 78 or 104,pt and 44 or ph and 30 or 38
    local right=w-pad-bw
    local b
    if spec.action then
        b=K.button(f,'Action',{kind=spec.actionKind or 'plain',text=spec.action,size=pt and 14 or ph and 12 or 14,weight=800},function()if spec.onAction then spec.onAction()end end)
        b:place(right,(h-bh)/2,bw,bh);b.button.ZIndex=4
        if spec.enabled==false then b:setEnabled(false)end
    end
    if spec.decline then
        local dw=K.width('거절',13)+16
        local d=K.button(f,'Decline',{kind='none',text='거절',size=13,weight=800},spec.decline);d.label.TextColor3=DANGER_TEXT;d.ink=DANGER_TEXT
        d:place(right-(pt and 4 or 8)-dw,(h-(pt and 44 or bh))/2,dw,pt and 44 or bh);d.button.ZIndex=4;right-=dw+(pt and 4 or 8)
    end
    local name=K.text(f,'Name',spec.name,pt and 14 or ph and 13 or 16,C.ink,pt and 800 or 700);name:SetAttribute('LocalizationSkip',true)
    local status=K.text(f,'State',spec.status or '',pt and 12 or ph and 11 or 13,C.muted,pt and 700 or 600)
    if pt then
        K.box(name,tx,h/2-15,right-tx-10,16);K.box(status,tx,h/2+1,right-tx-10,14)
    else
        local sw=K.width(status.Text,status.TextSize,status)
        status.TextXAlignment=Enum.TextXAlignment.Right;K.box(status,right-12-sw-2,0,sw+2,h)
        K.box(name,tx,0,math.max(20,right-12-sw-12-tx),h)
    end
    if spec.onProfile then
        local hit=K.make('TextButton',f,{Name='Profile',Text='',BackgroundTransparency=1,AutoButtonColor=false,BorderSizePixel=0,ZIndex=2})
        K.box(hit,0,0,math.max(44,right-8),h);hit.Activated:Connect(function()require(script.Parent.ToyAudio).play('click');spec.onProfile()end)
    end
    return f,h
end

local function entries(lobby)
    local s=lobby.data;local me=Players.LocalPlayer.UserId;local list={}
    if not s then return list,0 end
    for _,invite in ipairs(s.invites or {})do
        Localization.addName(invite.name)
        table.insert(list,{id='Accept'..invite.from,userId=invite.from,name=invite.name,status='초대 받음',dot=C.gold,invite=true,action='수락',actionKind='out',
            onAction=function()lobby:request('accept',invite.from)end,decline=function()lobby:request('decline',invite.from)end})
    end
    local here={};for _,pl in ipairs(Players:GetPlayers())do here[pl.UserId]=true end
    local playing,online={},{}
    for _,f in ipairs(lobby.onlineFriends or {})do
        if not here[f.VisitorId]then
            Localization.addName(f.DisplayName or f.UserName)
            if f.PlaceId==game.PlaceId and type(f.GameId)=='string'and f.GameId~=''then table.insert(playing,f)elseif #online<8 then table.insert(online,f)end
        end
    end
    local count=0
    for _,f in ipairs(playing)do count+=1
        table.insert(list,{id='Follow'..f.VisitorId,userId=f.VisitorId,name=f.DisplayName or f.UserName,status='플레이 중',dot=C.accent,action='같이 하기',actionKind='out',onAction=function()lobby:follow(f)end})
    end
    local party=s.party or {users={me}};local sent={};for _,to in ipairs(s.sent or {})do sent[to]=true end
    for _,player in ipairs(s.players or {})do if player.userId~=me and not table.find(party.users,player.userId)then count+=1
        local pl=Players:GetPlayerByUserId(player.userId);Localization.addName(player.name)
        table.insert(list,{id='Invite'..player.userId,userId=player.userId,name=player.name,status=sent[player.userId]and '초대 보냄'or player.busy and '경기 중'or '로비',
            dot=player.busy and C.accent or C.good2,action='초대',enabled=not sent[player.userId]and not player.busy,onAction=function()lobby:request('invite',player.userId)end,
            onProfile=pl and function()require(script.Parent.CommanderProfile).open(lobby,pl,'server')end or nil})
    end end
    for _,f in ipairs(online)do count+=1
        table.insert(list,{id='InviteFriend'..f.VisitorId,userId=f.VisitorId,name=f.DisplayName or f.UserName,status='온라인',dot=C.good2,action='초대',onAction=function()lobby:invite(f.VisitorId)end})
    end
    return list,count
end

local function seat(root,lobby,fmt,x,y,size,id,anchorName)
    local me=Players.LocalPlayer.UserId;local s=lobby.data;local party=s and s.party
    local grouped=party and #party.users>1
    local holder=K.make('TextButton',root,{Name=anchorName,Text='',BackgroundTransparency=1,AutoButtonColor=false,BorderSizePixel=0})
    K.box(holder,x,y,size,size)
    if id then
        local face=K.avatar(holder,'Face',id,size,id==me and C.accent or C.ink,2)
        local st=face:FindFirstChild('Stroke20');if st then st.Transparency=id==me and 0 or .6 end
        local status=s and s.partyStatus and s.partyStatus[tostring(id)]
        if status and status~='hq'and status~='ready'then face.ImageTransparency=.45 end
        if grouped and party.leader==id then local c=K.icon(holder,'crown',size>60 and 18 or 14,C.gold,'Leader');local cs=size>60 and 18 or 14;K.box(c,size-cs+2,-2,cs,cs);c.ZIndex=3 end
        if id~=me then
            holder.Activated:Connect(function()
                require(script.Parent.ToyAudio).play('click')
                local pl=Players:GetPlayerByUserId(id);local items={}
                local labels={away='다른 서버',loading='불러오는 중',results='결과 화면',match='경기 중',queued='대기 중',ready='준비',hq='로비'}
                table.insert(items,{text=pl and pl.DisplayName or '지휘관',value=party.leader==id and '방장'or labels[status or 'hq']or '로비',muted=false})
                if pl then table.insert(items,{text='전적',icon='records',fn=function()require(script.Parent.CommanderProfile).open(lobby,pl,'party')end})end
                if party.leader==me then table.insert(items,{text='내보내기',icon='x',fn=function()lobby:request('kick',id)end})end
                S.menu(lobby,holder,items)
            end)
        end
    else
        local ring=K.icon(holder,'dashRing',size,C.muted,'Seat');ring.ImageTransparency=.55;K.box(ring,0,0,size,size)
        local ps=math.floor(size*.36+.5);local plus=K.icon(holder,'plus',ps,C.muted,'Plus');K.box(plus,(size-ps)/2,(size-ps)/2,ps,ps)
        holder.Activated:Connect(function()require(script.Parent.ToyAudio).play('click');lobby:invite()end)
    end
    return holder
end

function M.draw(lobby,body)
    for _,o in ipairs(body:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
    lobby:loadFriends()
    local sw,sh=body.Size.X.Offset,body.Size.Y.Offset
    local W,H=lobby.root.AbsoluteSize.X/require(script.Parent.Theme).scale,lobby.root.AbsoluteSize.Y/require(script.Parent.Theme).scale
    local fmt=S.format(W,H);local pt,ph=fmt=='pt',fmt=='ph'
    local root=K.make('Frame',body,{Name='Page20',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromOffset(sw,sh)})
    local first=lobby.first20=='friends';lobby.first20=nil
    local me=Players.LocalPlayer.UserId;local s=lobby.data;local party=s and s.party or {users={me},leader=me}
    local users=party.users or {me};local grouped=#users>1
    local q=s and s.queue
    local head=S.head(root,fmt,sw,'파티',not pt and function()lobby:back()end or nil)
    if pt then
        local n=K.num(root,'Count',string.format('%d / 5',#users),15,C.muted,Enum.TextXAlignment.Right);K.box(n,head.right-80,head.y,80,head.h)
    end
    local lift=0;do local d=lobby.deployment;if q and d and d.bar and d.bar.Visible then lift=(d.barHeight or 48)+8 end end
    local _,CB=S.band(H,lift)
    local p=pt and 16 or ph and 12 or 24;local inset=pt and 0 or 1
    local y0=pt and 112 or ph and 48+inset or 72+inset
    local ss=pt and 52 or ph and 50 or 72
    local x=p+inset
    for i=1,5 do
        local id=users[i]
        if pt then
            seat(root,lobby,fmt,math.floor(16+(i-1)*(sw-32-ss)/4+.5),y0,ss,id,'Seat'..i)
        else
            local col=ss+16;local sx=x+(i-1)*(col+(ph and 4 or 10))
            local sy=id and y0 or y0+(ph and 7 or 8)
            seat(root,lobby,fmt,sx+8,sy,ss,id,'Seat'..i)
            if id then local pl=Players:GetPlayerByUserId(id)
                local n=K.text(root,'Name'..i,id==me and '나'or(pl and pl.DisplayName or '지휘관'),ph and 11 or 13,C.ink,700,Enum.TextXAlignment.Center)
                if id~=me then n:SetAttribute('LocalizationSkip',pl~=nil)end
                K.box(n,sx,y0+ss+6,col,ph and 13 or 15)
            end
        end
    end
    local medals=lobby.account and lobby.account.progress and lobby.account.progress.career
    local reward=medals and medals.recruitMedals and (medals.recruits or 0)<(medals.recruitCap or math.huge)and medals.recruitMedals or nil
    local bw,bh,bx,by
    if pt then bw,bh,bx,by=sw-32,52,16,y0+64
    else local colH=ss+6+(ph and 13 or 15);bw,bh=ph and 168 or 230,ph and 48 or 60;bx=sw-inset-p-bw;by=y0+math.floor((colH-bh)/2+.5)end
    local fs=pt and 18 or ph and 15 or 18
    local invite=K.button(root,'InviteRoblox',{kind='pri',r=8},function(b)K.confirm(b,true);lobby:invite()end)
    invite:place(bx,by,bw,bh)
    do
        local f=invite.face;local is=pt and 20 or ph and 18 or 20
        local icon=K.icon(f,'invite',is,C.bg,'Icon');local label=K.text(f,'Label','친구 초대',fs,C.bg,800);local lw=K.width('친구 초대',fs,label)
        local gap=pt and 10 or 8;local cx=math.floor((bw-is-gap-lw)/2)
        K.box(icon,cx,(bh-is)/2,is,is);K.box(label,cx+is+gap,0,lw+2,bh)
        for _,o in ipairs(f:GetDescendants())do if o:IsA('GuiObject')and o.Name~='Depth'then o.ZIndex=math.max(o.ZIndex,f.ZIndex+1)end end
        if reward then
            local pop=not lobby.inviteBadgePopped;lobby.inviteBadgePopped=true
            K.rewardBadge(f,'Reward','+'..commas(reward),ph and 13 or 15,bw,0,f.ZIndex+5,pop)
        end
    end
    local ly=pt and y0+130 or ph and y0+ss+36 or y0+ss+52
    if grouped then
        local ay=pt and by+bh+12 or ly;local ah=pt and 44 or ph and 32 or 40
        local afs=pt and 14 or ph and 13 or 14
        local leader=party.leader==me
        local acts={}
        if leader then
            local play=require(script.Parent.Parent.Core.PartyPlay)
            for _,hard in ipairs({false,true})do local r=play.coop(lobby.map,party,hard)
                table.insert(acts,{name=hard and 'PartyHard'or 'PartyCoop',text=string.format(hard and '어려움 %d vs %d'or '협동 %d vs %d',#users,r.aiCount),kind=hard and 'plain'or 'out',fn=function()require(script.Parent.CustomDeployment).party(lobby,hard)end})
            end
        end
        table.insert(acts,{name='LeaveParty',text='파티 나가기',fn=function()lobby:request('leaveParty')end,muted=true,apart=true})
        local x0=pt and 16 or p+inset;local x1=x0+(pt and sw-32 or sw-2*(p+inset))
        local even=pt and (x1-x0-8*(#acts-1))/#acts
        local ax=x0
        for i,a in ipairs(acts)do
            local b=K.button(root,a.name,{kind=a.kind or 'plain',text=a.text,size=afs,weight=800},a.fn)
            local aw=even or math.max(88,K.width(a.text,afs,b.label)+32)
            local bx2=(a.apart and not even)and x1-aw or ax
            b:place(math.floor(bx2),ay,math.floor(aw),ah);ax+=aw+8
            if a.muted then b.label.TextColor3=C.muted;b.ink=C.muted end
            if lobby.busy then b:setEnabled(false)end
        end
        ly=pt and ay+ah+12 or ly+ah+12
    end
    local list,count=entries(lobby)
    local hs=pt and 13 or ph and 12 or 14;local lx=pt and 16 or p+inset;local lw=pt and sw-32 or sw-2*(p+inset)
    local cap=K.text(root,'OnlineHead',string.format('온라인 %d',count),hs,C.muted,800);K.box(cap,lx,ly,160,hs+4)
    local linkX=lx+lw
    local function link(name,icon,text,fn)
        local is=pt and 15 or ph and 14 or 16;local tw=K.width(text,hs)
        local b=K.button(root,name,{kind='none',r=6},fn);local wdt=is+6+tw+2
        local ic=K.icon(b.face,icon,is,C.muted,'Icon');local t=K.text(b.face,'Label',text,hs,C.muted,700)
        b:place(linkX-wdt,ly+math.floor((hs+4-24)/2),wdt,24);K.box(ic,0,(24-is)/2,is,is);K.box(t,is+6,0,tw+2,24)
        linkX-=wdt+12
    end
    link('JoinCode','code',pt and '코드'or '코드 입력',function()lobby:openPage('joinCode')end)
    local tag=Players.LocalPlayer:GetAttribute('CommanderClan')
    link('Clan','clan',tag and string.format('[%s]',tag)or '클랜',function()lobby.unitView=nil;lobby:openPage('clan')end)
    if tag then local l=root:FindFirstChild('Clan');l=l and l:FindFirstChild('Label',true);if l then l:SetAttribute('LocalizationSkip',true)end end
    local top=ly+(pt and 28 or ph and 24 or 32)
    local bottom=pt and CB or sh-(ph and 12 or 24)
    local scroll=S.scroll(root,'Online',lx,top,lw,math.max(40,bottom-top))
    local y=0;local rows={}
    for _,e in ipairs(list)do local f,h=row(scroll,fmt,0,y,lw,e);table.insert(rows,f);y+=h+(pt and 6 or ph and 4 or 8)end
    if #list==0 then
        local e=K.text(scroll,'Empty',lobby.onlineFriends and '접속한 친구 없음'or '불러오는 중…',pt and 14 or 15,C.muted,700,Enum.TextXAlignment.Center);K.box(e,0,8,lw,40);y=56
    end
    S.canvas(scroll,y)
    S.stagger(rows,first)
end
return M
