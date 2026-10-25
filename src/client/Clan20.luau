local Players=game:GetService('Players')
local Tween=game:GetService('TweenService')
local K=require(script.Parent.Kit20)
local Theme=require(script.Parent.Theme)
local Art=require(script.Parent.Art20)
local Pop=require(script.Parent.Pop20)
local V=require(script.Parent.ClanVisuals)
local Telemetry=require(script.Parent.TelemetryClient)
local Rules=require(game.ReplicatedStorage.FrontierNative.Core.ClanRules)
local War=require(game.ReplicatedStorage.FrontierNative.Core.ClanWarRules)
local C=K.colors
local M={}
local Me=Players.LocalPlayer
local skip=V.skip
local function ask(lobby,...)require(script.Parent.ClanPage).ask(lobby,...)end
local function step(name,item)pcall(Telemetry.step,'social',name,item and {item=item}or nil)end
local function mix(a,b,t)return a:Lerp(b,t)end
local function num(n)return Theme.commas(math.floor(tonumber(n)or 0))end

local GEO={
    pc={L=40,R=40,bannerY=80,bannerH=104,emblem=72,emX=25,nameFs=26,tagFs=16,attendW=170,attendH=56,attendFs=18,attendPad=24,
        tabY=204,tabH=44,tabFs=15,gridY=266,cols=3,gapX=12,gapY=12,rowH=62,av=40,avX=15,avGap=12,dot=11,cellFs=15,crownFs=12,valFs=15,check=16,cpad=15,valGap=13,bottom=24,
        bandY=80,bandH=60,bandIcon=22,bandFs=16,bandLink=15,bandPad=18,toolsY=158,toolsH=44,toolsFs=15,toolsIcon=16,listY=220,listH=62,listStep=70,
        em=42,rowFs=16,colFs=15,joinW=96,joinH=40,joinFs=14,rowPad=16},
    ph={L=16,R=16,bannerY=54,bannerH=66,emblem=46,emX=13,nameFs=18,tagFs=13,attendW=108,attendH=44,attendFs=15,attendPad=13,
        tabY=130,tabH=32,tabFs=12,gridY=172,cols=2,gapX=6,gapY=6,rowH=42,av=28,avX=9,avGap=8,dot=9,cellFs=12,crownFs=11,valFs=12,check=13,cpad=9,valGap=9,bottom=8,
        bandY=54,bandH=44,bandIcon=18,bandFs=13,bandLink=12,bandPad=12,toolsY=108,toolsH=32,toolsFs=12,toolsIcon=14,listY=150,listH=44,listStep=48,
        em=34,rowFs=13,colFs=12,joinW=70,joinH=30,joinFs=12,rowPad=10},
    pt={L=16,R=16,bannerY=68,bannerH=96,emblem=44,emX=13,nameFs=17,tagFs=13,attendW=84,attendH=44,attendFs=15,attendPad=13,
        tabY=174,tabH=40,tabFs=14,gridY=224,cols=2,gapX=8,gapY=6,rowH=48,av=30,avX=9,avGap=8,dot=9,cellFs=13,crownFs=11,valFs=0,check=15,cpad=9,valGap=9,bottom=66,
        bandY=68,bandH=48,bandIcon=20,bandFs=14,bandLink=13,bandPad=12,toolsY=126,toolsH=44,toolsFs=14,toolsIcon=15,listY=180,listH=56,listStep=62,
        em=36,rowFs=14,colFs=12,joinW=64,joinH=44,joinFs=14,rowPad=10},
}

local function inline(parent,x,h,parts,gap,center,w)
    local objs={};local total=0
    for i,p in ipairs(parts)do
        local o,pw,txt
        if p.robux then o=K.make('ImageLabel',parent,{Name='Robux'..i,BackgroundTransparency=1,Image='rbxasset://textures/ui/common/robux.png',ImageColor3=p.color or C.muted,ScaleType=Enum.ScaleType.Fit});pw=p.size
        elseif p.icon then o=K.icon(parent,p.icon,p.size,p.color,'Icon'..i);pw=p.size
        elseif p.num then o=K.num(parent,'Num'..i,p.num,p.size,p.color);pw=K.width(p.num,p.size,o);txt=true
        else o=K.text(parent,'Text'..i,p.text,p.size,p.color,p.weight or 800);pw=K.width(p.text,p.size,o);txt=true;if p.raw then skip(o)end end
        objs[i]={o=o,w=pw,s=p.size,txt=txt};total+=pw+(i>1 and(p.gap or gap or 6)or 0)
    end
    if center then x=math.floor(x+(w-total)/2)end
    for i,e in ipairs(objs)do
        if i>1 then x+=parts[i].gap or gap or 6 end
        if e.txt then K.box(e.o,x,0,e.w+2,h)else K.box(e.o,x,math.floor((h-e.s)/2+.5),e.s,e.s)end
        x+=e.w
    end
    return objs,total
end
local function painted(parent,name,look,cb)
    local b=K.button(parent,name,{kind='none',r=look.r or 8},cb)
    local f,st=b.face,b.faceStroke
    f.BackgroundColor3=look.fill or C.raised;f.BackgroundTransparency=look.alpha or 0
    st.Enabled=look.stroke~=nil;if look.stroke then st.Color=look.stroke;st.Thickness=look.thick or 1;st.Transparency=look.strokeAlpha or 0 end
    b.baseFill=f.BackgroundColor3;b.baseAlpha=f.BackgroundTransparency;b.baseStroke=st.Color
    return b
end
local function dim(b)
    b:setEnabled(false,true)
    for _,d in ipairs(b.face:GetDescendants())do if d:IsA('TextLabel')then d.TextTransparency=.5 elseif d:IsA('ImageLabel')then d.ImageTransparency=.5 end end
end
local function onlineDot(parent,x,y,s,on)
    local d=K.make('Frame',parent,{Name='Online',BackgroundColor3=on and C.good2 or C.dim,BorderSizePixel=0});K.round(d,'pill');K.stroke(d,C.panel,2);K.box(d,x,y,s,s)
    d.Visible=on==true;return d
end
local function square(parent,size,iconSize,col,r)
    local f=K.make('Frame',parent,{Name='ClanSquare',BackgroundColor3=col,BorderSizePixel=0});K.round(f,r or 10);f.Size=UDim2.fromOffset(size,size)
    local i=K.icon(f,'clan',iconSize,C.bg,'Icon');K.box(i,math.floor((size-iconSize)/2),math.floor((size-iconSize)/2),iconSize,iconSize)
    return f
end
local function scroller(root,name,x,y,w,h)
    local s=K.make('ScrollingFrame',root,{Name=name,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.line,ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.fromOffset(0,0)})
    K.box(s,x-4,y-4,w+8,h+8);K.scrollPad(s,4);return s
end
local function appearRows(rows,first)
    if not first then return end
    for i,o in ipairs(rows)do if i<=6 then K.appear(o,{dy=8,t=.14,delay=(i-1)*.03})end end
end
local function lockPop(lobby,anchor,what)
    local n,colors,split=Pop.primeTickets()
    Pop.lock('clan',anchor,what=='create'and '커맨더 프라임이 있어야 만들 수 있어요'or '커맨더 프라임이 있어야 가입할 수 있어요','보기',function()step('clanPrimeView');lobby:openPage('benefits')end,C.prime,
        n>0 and {icons=colors,text=string.format('뽑기권 %d장',n),sub=split}or nil)
end

local function joinButton(ctx,parent,r,x,y,g,prime)
    local lobby=ctx.lobby;local full=(r.count or 0)>=Rules.maxMembers
    local b
    if full then b=K.button(parent,'JoinClan',{kind='dis',text='정원 마감',size=g.joinFs,weight=800},function()end);b:setEnabled(false)
    elseif not prime then
        b=painted(parent,'JoinClan',{fill=C.raised,stroke=C.line},function()end)
        b:setEnabled(false,true);b.onRefuse=function()lockPop(lobby,b.face,'join')end
    else b=K.button(parent,'JoinClan',{kind='plain',text='가입',size=g.joinFs,weight=800},function()ask(lobby,'joinId',r.id)end)end
    b:place(x,y,g.joinW,g.joinH)
    if not full and not prime then inline(b.face,0,g.joinH,{{icon='lock',size=g.joinFs,color=C.prime},{text='가입',size=g.joinFs,color=C.muted}},4,true,g.joinW)end
    if lobby.unitBusy and prime and not full then b:setEnabled(false)end
    return b
end
local function clanRow(ctx,parent,r,y,w,opts)
    local g=ctx.g;local fmt=ctx.fmt;local col=V.color(r.color);local h=g.listH
    local mine=opts.mine~=nil and opts.mine==r.id
    local row=K.make('Frame',parent,{Name='Clan_'..tostring(r.rank or 0)..'_'..tostring(r.id),BackgroundColor3=C.panel,BorderSizePixel=0});K.round(row,8);K.box(row,0,y,w,h)
    if mine then K.stroke(row,C.accent,1,.4,true)end
    local x=g.rowPad
    if opts.rank then
        local medal=V.medals[r.rank]
        local rk=K.num(row,'Rank',tostring(r.rank or ''),g.colFs,medal or C.muted,Enum.TextXAlignment.Center);K.box(rk,x-4,0,fmt=='pc'and 30 or 24,h);x+=fmt=='pc'and 30 or 22
    end
    if fmt=='pt'then local sq=square(row,g.em,20,col,8);sq.Position=UDim2.fromOffset(x,math.floor((h-g.em)/2))
    else local e=Art.shield(row,'Emblem',g.em,col,r.tag or '');e.Position=UDim2.fromOffset(x,math.floor((h-g.em)/2))end
    x+=g.em+(fmt=='pc'and 16 or 10)
    local right=w-g.rowPad
    if opts.join then joinButton(ctx,row,r,right-g.joinW,math.floor((h-g.joinH)/2),g,opts.join.prime);right-=g.joinW+(fmt=='pc'and 16 or 10)end
    local war=opts.kind=='war'
    if fmt=='pt'then
        if not opts.join then
            local color=V.medals[r.rank]or C.accent
            local v=war and K.text(row,'Value',string.format('%s점',num(r.value)),15,color,800,Enum.TextXAlignment.Right)or K.num(row,'Value',num(r.value),15,color,Enum.TextXAlignment.Right)
            K.box(v,right-110,0,110,h);right-=118
        end
        local nm=skip(K.text(row,'Name',r.name or '',g.rowFs,C.ink,800));K.box(nm,x,math.floor(h/2)-19,right-x,20)
        local sub=K.make('Frame',row,{Name='Sub',BackgroundTransparency=1});K.box(sub,x,math.floor(h/2)+2,right-x,16)
        local parts={{num='Lv '..tostring(r.level or 1),size=12,color=C.muted}}
        if war then table.insert(parts,{text=string.format('%d승 %d패',r.wins or 0,r.losses or 0),size=12,color=C.muted,weight=700,gap=10})
        else table.insert(parts,{num=string.format('%d/%d',r.count or 0,Rules.maxMembers),size=12,color=C.muted,gap=10})end
        inline(sub,0,16,parts,10)
        return row
    end
    local cols={}
    if opts.join then
        if fmt=='pc'then table.insert(cols,1,{w=44,num='#'..tostring(r.rank or '-'),color=C.gold})end
    else
        local color=V.medals[r.rank]or C.accent
        if war then table.insert(cols,{w=fmt=='pc'and 110 or 80,text=string.format('%s점',num(r.value)),color=color,right=true})
        else table.insert(cols,{w=fmt=='pc'and 110 or 80,num=num(r.value),color=color,right=true})end
    end
    if war then table.insert(cols,1,{w=fmt=='pc'and 110 or 80,text=string.format('%d승 %d패',r.wins or 0,r.losses or 0)})
    else table.insert(cols,1,{w=fmt=='pc'and 84 or 60,icon=true,num=string.format('%d/%d',r.count or 0,Rules.maxMembers)})end
    table.insert(cols,1,{w=fmt=='pc'and 60 or 40,num='Lv '..tostring(r.level or 1)})
    local gap=fmt=='pc'and 16 or 10
    local cx=right
    for i=#cols,1,-1 do cx-=cols[i].w;cols[i].x=cx;cx-=gap end
    for i,c in ipairs(cols)do
        local holder=K.make('Frame',row,{Name='Col'..i,BackgroundTransparency=1});K.box(holder,c.x,0,c.w,h)
        local parts={}
        if c.icon then table.insert(parts,{icon='people',size=g.colFs,color=C.muted})end
        if c.text then table.insert(parts,{text=c.text,size=g.colFs,color=c.color or C.muted,weight=c.color and 800 or 700})else table.insert(parts,{num=c.num,size=g.colFs,color=c.color or C.muted,gap=5})end
        if c.right then local _,tw=inline(holder,0,h,parts,5);for _,o in ipairs(holder:GetChildren())do o.Position+=UDim2.fromOffset(c.w-tw,0)end
        else inline(holder,0,h,parts,5)end
    end
    local nmW=cx-x
    local nm=skip(K.text(row,'Name',r.name or '',g.rowFs,C.ink,800));local nw=math.min(K.width(nm.Text,g.rowFs,nm)+2,nmW-(opts.rank and 60 or 0));K.box(nm,x,0,math.max(20,nw),h)
    if opts.rank and r.tag then local t=K.num(row,'Tag','['..r.tag..']',g.colFs-2,C.muted);K.box(t,x+nw+8,0,60,h)end
    return row
end
local function listState(ctx,parent,y,w,rows,kind,emptyText)
    local v=ctx.v;local state=v and(kind=='war'and v.warState or v.topState)
    if #rows>0 then return nil end
    local h=ctx.g.listH
    local p=K.panel(parent,'BoardState','card',8);K.box(p,0,y,w,h);p.BackgroundTransparency=.3
    local text=state=='loading'and '순위 불러오는 중…'or state=='failed'and '순위를 불러오지 못했어요'or emptyText
    local t=K.text(p,'Text',text,ctx.fmt=='ph'and 12 or 14,C.muted,700);K.box(t,16,0,w-160,h)
    if state=='failed'then local b=K.button(p,'BoardRetry',{kind='plain',text='새로 고침',size=13},function()ask(ctx.lobby,'read')end);b:place(w-12-110,math.floor((h-36)/2),110,36)end
    return y+h+8
end
local function listRows(ctx,parent,y,w,rows,opts,out)
    local after=listState(ctx,parent,y,w,rows,opts.kind,opts.empty or '기록 없음');if after then return after end
    for _,r in ipairs(rows)do local row=clanRow(ctx,parent,r,y,w,opts);if out then table.insert(out,row)end;y+=ctx.g.listStep end
    return y
end

local function warCard(ctx,parent,y,w,u)
    local v,lobby,fmt=ctx.v,ctx.lobby,ctx.fmt;local war=v.war or {}
    local pt=fmt=='pt';local fs=fmt=='pc'and 1 or 0
    local h=pt and 176 or fmt=='pc'and 128 or 104
    local p=K.panel(parent,'ClanWarCard','card',10);K.box(p,0,y,w,h)
    local pad=fmt=='pc'and 18 or 12
    local ic=K.icon(p,'medal',fmt=='pc'and 22 or 18,C.gold,'WarIcon');K.box(ic,pad,pad,fmt=='pc'and 22 or 18,fmt=='pc'and 22 or 18)
    local tx=pad+(fmt=='pc'and 30 or 24)
    local head=K.text(p,'WarHead',(war.n or 0)==0 and '프리시즌 클랜전'or string.format('시즌 %d 클랜전',war.n),fmt=='pc'and 18 or 15,C.ink,800);K.box(head,tx,pad-2,w-tx-pad,24)
    local left=skip(K.text(p,'WarLeft',string.format('초기화까지 %s',V.time(war.remaining or 0)),fmt=='pc'and 13 or 12,C.muted,600));K.box(left,tx,pad+22,w-tx-pad,16)
    local ry=pad+46
    if u and u.war then
        local rec=skip(K.text(p,'WarRecord',string.format('%s점  %d승 %d패  %s',num(u.war.points),u.war.wins or 0,u.war.losses or 0,u.war.rank and string.format('%d위',u.war.rank)or '순위 밖'),fmt=='pc'and 18 or 15,C.ink,800,pt and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right))
        if pt then K.box(rec,pad,ry,w-pad*2,20);ry+=26 else K.box(rec,w-pad-360,pad-2,360,24)end
    end
    local rules=string.format('%d~%d인 파티  최대 %d클랜  승리 +%d~%d  패배 %d  기여 +%d',
        War.minSize,War.maxSize,War.maxClans,War.winFor(War.minClans,War.minSize),War.winFor(War.maxClans,War.maxSize),war.lossPoints or War.lossPoints,war.winContribution or War.winContribution)
    local rl=K.text(p,'WarRules',rules,fmt=='pc'and 13 or 11,C.muted,600);rl.TextWrapped=pt;rl.TextTruncate=pt and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd
    K.box(rl,pad,ry,pt and w-pad*2 or w-pad*2-260,pt and 30 or 16);ry+=pt and 34 or 22
    local party=lobby.data and lobby.data.party;local n=party and type(party.users)=='table'and #party.users or 1
    local fits=n>=War.minSize and n<=War.maxSize
    local sl=K.text(p,'WarParty',string.format('파티 %d / %d~%d',n,War.minSize,War.maxSize),fmt=='pc'and 13+fs or 12,fits and C.ink or C.muted,700);K.box(sl,pad,ry,200,18)
    local queue=lobby.clanWarQueue
    local label=not u and '클랜 가입 필요'or not queue and '곧 열려요'or fits and string.format('%d대%d 클랜전 찾기',n,n)or string.format('파티 %d~%d명 필요',War.minSize,War.maxSize)
    local can=u~=nil and queue~=nil and fits
    local b=K.button(p,'FindClanWar',{kind='out',text=label,size=fmt=='pc'and 16 or 14,icon='swords',iconSize=fmt=='pc'and 18 or 15},function()
        if queue and u and fits then step('clanWarQueue','p'..tostring(n));queue(lobby)end end)
    local bh=fmt=='pc'and 48 or pt and 44 or 40
    if pt then b:place(pad,h-pad-bh,w-pad*2,bh)else b:place(w-pad-(fmt=='pc'and 240 or 190),h-pad-bh,fmt=='pc'and 240 or 190,bh)end
    if not can or lobby.unitBusy then b:setEnabled(false)end
    return y+h+12
end

local function infoRow(p,y,w,pad,label,value,color,isNum)
    local l=K.text(p,'Label_'..label,label,14,C.muted,700);K.box(l,pad,y,w-pad*2,28)
    local v=isNum~=false and K.num(p,'Value_'..label,value,15,color or C.ink,Enum.TextXAlignment.Right)or skip(K.text(p,'Value_'..label,value,14,color or C.ink,800,Enum.TextXAlignment.Right))
    K.box(v,pad,y,w-pad*2,28);return y+30
end
local function clanSheet(ctx)
    local lobby,v=ctx.lobby,ctx.v;local u=v.unit;local a=v.attend
    if u.isLeader then step('clanMarkOpened')end
    local pad=18;local w=380
    local rows=8
    local h=pad+48+12+rows*30+(u.isLeader and 64 or 0)+12+44+8+44+(v.studio and 52 or 0)+pad
    Pop.sheet('clan','ClanSheet',w,h,function(p,close,pw)
        local col=V.color(u.color)
        local em=Art.shield(p,'Emblem',48,col,u.tag or '');em.Position=UDim2.fromOffset(pad,pad)
        local nm=skip(K.text(p,'Name',u.name or '',19,C.ink,800));K.box(nm,pad+60,pad+2,pw-pad*2-60-36,24)
        local tg=K.num(p,'Tag','['..tostring(u.tag or '')..']',13,C.muted);K.box(tg,pad+60,pad+26,120,20)
        local x=K.button(p,'Close',{kind='ghost',icon='x',iconSize=18},function()close()end);x:place(pw-pad-26+4,pad,26,26)
        local y=pad+48+12
        y=infoRow(p,y,pw,pad,'레벨','Lv '..tostring(u.level or 1))
        y=infoRow(p,y,pw,pad,'다음 레벨까지',u.levelCost and string.format('%s / %s',num(u.levelXp),num(u.levelCost))or '최고 레벨 달성',nil,u.levelCost~=nil)
        y=infoRow(p,y,pw,pad,'누적 기여',num(u.xp))
        y=infoRow(p,y,pw,pad,'기여 순위',u.rank and string.format('%d위',u.rank)or '순위 밖',C.gold,false)
        y=infoRow(p,y,pw,pad,'클랜전 순위',u.war and u.war.rank and string.format('%d위',u.war.rank)or '순위 밖',nil,false)
        y=infoRow(p,y,pw,pad,'내 기여',string.format('%s / %s',num(a.total),num(a.warTotal)))
        y=infoRow(p,y,pw,pad,'오늘 출석',string.format('%d / %d',(a.free and 1 or 0)+(a.extra or 0),1+(a.extraMax or 0)))
        y=infoRow(p,y,pw,pad,'초대 코드',tostring(u.code or ''),C.accent)
        if u.isLeader then
            y+=6
            local hl=K.text(p,'ColorHead','엠블럼 색',13,C.muted,700);K.box(hl,pad,y,120,18);y+=22
            local n=#Rules.colors;local s=30;local gap=math.floor((pw-pad*2-n*s)/(n-1))
            for i=1,n do
                local c=V.color(i);local on=i==u.color
                local sw=painted(p,'Swatch'..i,{fill=c,stroke=on and C.ink or mix(c,C.bg,.3),thick=on and 2 or 1,r='pill'},function()
                    if i~=u.color then step('clanMarkColor',tostring(i));close();ask(lobby,'color',i)end end)
                sw.minHit=36;sw:place(pad+(i-1)*(s+gap),y,s,s)
                if lobby.unitBusy then sw:setEnabled(false,true)end
            end
            y+=36
        end
        y+=12
        local rf=K.button(p,'RefreshClan',{kind='plain',text='새로 고침',size=15,icon='restore',iconSize=16},function()close();ask(lobby,'read')end);rf:place(pad,y,pw-pad*2,44);y+=52
        local armed=false
        local leaveText=u.isLeader and(u.count or 1)>1 and '클랜 나가기, 최고참이 클랜장 승계'or '클랜 나가기'
        local lv;lv=K.button(p,'LeaveClan',{kind='plain',text=leaveText,size=15},function()
            if armed then close();ask(lobby,'leave')else armed=true;lv:setText('한 번 더 누르면 클랜을 나가요');lv.label.TextColor3=C.ink end end)
        lv:place(pad,y,pw-pad*2,44);lv.label.TextColor3=C.muted;y+=52
        if lobby.unitBusy then rf:setEnabled(false);lv:setEnabled(false)end
        if v.studio then
            local list={{'xp','기여 +5,000'},{'reset','출석 초기화'},{'war','클랜전 승'},{'warLoss','클랜전 패'}}
            local bw=(pw-pad*2-18)/4
            for i,b in ipairs(list)do
                local d=K.button(p,'ClanDev_'..b[1],{kind='ghost',text=b[2],size=12},function()if b[1]=='warLoss'then ask(lobby,'dev','war','loss')else ask(lobby,'dev',b[1])end end)
                d:place(pad+(i-1)*(bw+6),y,bw,36);d.label.TextColor3=C.gold
            end
        end
    end)
end
local function mateSheet(ctx,m)
    local lobby=ctx.lobby;local pad=18;local w=340;local h=pad+44+16+44+10+44+pad
    Pop.sheet('clan','MateSheet',w,h,function(p,close,pw)
        local av=K.avatar(p,'Avatar',m.userId,44);av.Position=UDim2.fromOffset(pad,pad)
        local nm=skip(K.text(p,'Name',m.name or '',17,C.ink,800));K.box(nm,pad+56,pad,pw-pad*2-56-36,44)
        local x=K.button(p,'Close',{kind='ghost',icon='x',iconSize=18},function()close()end);x:place(pw-pad-26+4,pad+9,26,26)
        local y=pad+44+16
        local pr=K.button(p,'Promote',{kind='plain',text='클랜장 위임',size=15,icon='crown',iconSize=16},function()close()
            require(script.Parent.LobbyConfirm).open(lobby,'클랜장 위임','되돌릴 수 없어요','넘기기',function()lobby:openPage('clan');ask(lobby,'promote',m.userId)end)end)
        pr:place(pad,y,pw-pad*2,44);y+=54
        local k=K.button(p,'Kick',{kind='dangero',text='내보내기',size=15},function()close()
            require(script.Parent.LobbyConfirm).open(lobby,'내보내기','7일 동안 재가입 불가','내보내기',function()lobby:openPage('clan');ask(lobby,'kick',m.userId)end)end)
        k:place(pad,y,pw-pad*2,44)
        if lobby.unitBusy then pr:setEnabled(false);k:setEnabled(false)end
    end)
end
local function createSheet(ctx)
    local lobby=ctx.lobby;local d=lobby.unitDraft or {};lobby.unitDraft=d
    d.color=Rules.validColor(d.color)or 1
    local pad=18;local w=380;local h=pad+64+16+44+10+44+16+36+20+52+pad
    Pop.sheet('clan','CreateSheet',w,h,function(p,close,pw)
        local t=K.text(p,'Title','클랜 만들기',20,C.ink,800);K.box(t,pad+76,pad+6,pw-pad*2-76-36,26)
        local x=K.button(p,'Close',{kind='ghost',icon='x',iconSize=18},function()close()end);x:place(pw-pad-26+4,pad,26,26)
        local preview
        local function paint()
            if preview then preview:Destroy()end
            local tag=Rules.validTag(d.tag or '')or ''
            preview=Art.shield(p,'Preview',64,V.color(d.color),tag);preview.Position=UDim2.fromOffset(pad,pad)
        end
        local pn=skip(K.text(p,'NamePreview','',15,C.muted,700));K.box(pn,pad+76,pad+34,pw-pad*2-76,22)
        local function refresh()pn.Text=d.name and d.name~=''and d.name or '';paint()end
        local y=pad+64+16
        local function input(name,placeholder,value,yy,mono)
            local f=K.make('Frame',p,{Name=name..'Box',BackgroundColor3=C.bg,BorderSizePixel=0});K.round(f,8);local st=K.stroke(f,C.line,1,0,true);K.box(f,pad,yy,pw-pad*2,44)
            local box=K.make('TextBox',f,{Name=name,Text=value or '',PlaceholderText=placeholder,ClearTextOnFocus=false,TextSize=mono and 17 or 15,TextColor3=C.ink,PlaceholderColor3=C.dim,BackgroundTransparency=1,BorderSizePixel=0,TextXAlignment=Enum.TextXAlignment.Left})
            box.FontFace=mono and K.fonts.num or K.fonts[600];K.box(box,12,0,pw-pad*2-24,44)
            box.Focused:Connect(function()st.Color=C.accent end);box.FocusLost:Connect(function()st.Color=C.line end)
            return box
        end
        local name=input('ClanNameInput','클랜 이름 (2~16자)',d.name,y);y+=54
        local tag=input('ClanTagInput','약칭 (2~4자)',d.tag,y,true);y+=60
        name:GetPropertyChangedSignal('Text'):Connect(function()d.name=name.Text;refresh()end)
        tag:GetPropertyChangedSignal('Text'):Connect(function()d.tag=tag.Text;refresh()end)
        local n=#Rules.colors;local s=30;local gap=math.floor((pw-pad*2-n*s)/(n-1));local swatches={}
        local function ring()for i,sw in ipairs(swatches)do sw.faceStroke.Color=i==d.color and C.ink or mix(V.color(i),C.bg,.3);sw.faceStroke.Thickness=i==d.color and 2 or 1;sw.baseStroke=sw.faceStroke.Color end end
        for i=1,n do
            local sw=painted(p,'Swatch'..i,{fill=V.color(i),stroke=C.line,r='pill'},function()d.color=i;ring();refresh()end)
            sw.minHit=36;sw:place(pad+(i-1)*(s+gap),y,s,s);swatches[i]=sw
        end
        ring();y+=36+20
        local make=K.button(p,'CreateClan',{kind='pri',text='클랜 만들기',size=17},function(b)K.confirm(b,true);close();ask(lobby,'create',name.Text,tag.Text,d.color)end)
        make:place(pad,y,pw-pad*2,52);if lobby.unitBusy then make:setEnabled(false)end
        refresh()
    end)
end

local function attendButton(ctx,parent,x,y)
    local lobby,v,g,fmt=ctx.lobby,ctx.v,ctx.g,ctx.fmt;local a=v.attend
    local left=a.extraMax-a.extra;local price=v.product and v.product.price
    local stage=not a.free and 'free'or left>0 and 'extra'or 'done'
    local fs=g.attendFs
    local b=K.button(parent,stage=='free'and 'AttendFree'or stage=='done'and 'AttendDone'or 'AttendExtra',{kind=stage=='free'and 'pri'or stage=='extra'and 'goldo'or 'dis'},function()
        ask(lobby,'attend',stage=='free'and 'free'or 'extra')end)
    b:place(x,y,g.attendW,g.attendH)
    local w,h=g.attendW,g.attendH
    if stage=='free'then inline(b.face,0,h,{{icon='check',size=fs,color=C.bg},{text='출석',size=fs,color=C.bg}},6,true,w)
    elseif stage=='done'then inline(b.face,0,h,{{icon='check',size=fs,color=C.dim},{text='출석',size=fs,color=C.dim}},6,true,w);b:setEnabled(false,true)
    else
        local s=fmt=='pt'and 13 or fs
        local parts={{text='추가 출석',size=s,color=C.gold}}
        if a.tokens>0 then table.insert(parts,{num='×'..tostring(a.tokens),size=s,color=C.gold,gap=5})
        elseif not(v.product and v.product.studio)then
            table.insert(parts,{robux=true,size=s-1,color=C.gold,gap=6});table.insert(parts,{num=price and tostring(price)or '-',size=s,color=C.gold,gap=3})
        end
        inline(b.face,0,h,parts,5,true,w)
        if a.tokens==0 and v.product and not v.product.studio then local live=v.product.available==true;pcall(Telemetry.offerSeen,'clanAttend','clanStrip',live and 'shown'or 'unavailable',live and 'none'or 'sales_disabled')end
    end
    if lobby.unitBusy and stage~='done'then dim(b)end
    if lobby.clanGain and os.clock()-lobby.clanGain<.6 then
        lobby.clanGain=nil;K.confirm(b)
        local f=K.num(parent,'FloatGain','+'..tostring(a.amount),18,C.gold,Enum.TextXAlignment.Center);K.box(f,x,y-22,w,22);f.ZIndex=b.face.ZIndex+5
        if K.reduced then task.delay(.6,function()f:Destroy()end)else
            local tw=Tween:Create(f,TweenInfo.new(.6,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=f.Position-UDim2.fromOffset(0,14),TextTransparency=1});tw.Completed:Once(function()f:Destroy()end);tw:Play()end
    end
    return b
end
local function banner(ctx,u)
    local root,g,W,fmt,v=ctx.root,ctx.g,ctx.W,ctx.fmt,ctx.v
    local bw=W-g.L-g.R;local bh=g.bannerH;local col=V.color(u.color)
    local f=K.make('Frame',root,{Name='ClanBanner',BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0});K.round(f,10);K.box(f,g.L,g.bannerY,bw,bh);K.stroke(f,C.line,1,0)
    if fmt=='pt'then K.make('UIGradient',f,{Rotation=30,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,mix(C.panel,col,.18)),ColorSequenceKeypoint.new(.6,C.panel),ColorSequenceKeypoint.new(1,C.panel)})})
    else K.make('UIGradient',f,{Rotation=0,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,mix(C.panel,col,.12)),ColorSequenceKeypoint.new(.55,C.panel),ColorSequenceKeypoint.new(1,C.panel)})})end
    local ax=bw-g.attendPad-g.attendW
    local hit=K.make('TextButton',f,{Name='ClanInfo',Text='',BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false});K.box(hit,0,0,ax-8,fmt=='pt'and 62 or bh)
    hit.Activated:Connect(function()require(script.Parent.ToyAudio).play('click');clanSheet(ctx)end)
    local nameX,nameY,nameH
    if fmt=='pt'then
        local sq=square(f,44,24,col,10);sq.Position=UDim2.fromOffset(13,15)
        nameX,nameY,nameH=67,18,22
    else
        local e=Art.shield(f,'ClanEmblem',g.emblem,col,u.tag or '');e.Position=UDim2.fromOffset(g.emX,math.floor((bh-g.emblem)/2))
        nameX=g.emX+g.emblem+(fmt=='pc'and 20 or 12);nameY=fmt=='pc'and 22 or 12;nameH=g.nameFs+5
    end
    local maxName=ax-12-nameX-K.width('[WWWW]',g.tagFs)-40
    local nm=skip(K.text(f,'ClanName',u.name or '',g.nameFs,C.ink,800));local nw=math.min(K.width(nm.Text,g.nameFs,nm)+2,maxName);K.box(nm,nameX,nameY,nw,nameH)
    local tg=K.num(f,'ClanTag','['..tostring(u.tag or '')..']',g.tagFs,C.muted);local tw=K.width(tg.Text,g.tagFs,tg);K.box(tg,nameX+nw+(fmt=='pc'and 10 or 6),nameY,tw+1,nameH)
    local more=K.icon(f,'more',fmt=='pc'and 18 or 16,C.muted,'More');local ms=fmt=='pc'and 18 or 16;K.box(more,nameX+nw+(fmt=='pc'and 10 or 6)+tw+8,nameY+math.floor((nameH-ms)/2)+1,ms,ms)
    local frac=u.levelCost and math.clamp((u.levelXp or 0)/math.max(1,u.levelCost),0,1)or 1
    local key=tostring(u.id)..':'..tostring(u.level)..':'..tostring(u.levelXp);local from=ctx.lobby.clanBarKey~=key and ctx.lobby.clanBarFrom or nil
    ctx.lobby.clanBarKey=key;ctx.lobby.clanBarFrom=frac
    if fmt=='pt'then
        local sub=K.make('Frame',f,{Name='Sub',BackgroundTransparency=1});K.box(sub,67,41,ax-8-67,16)
        local parts={{num='Lv '..tostring(u.level or 1),size=12,color=C.muted},{num=string.format('%d/%d',u.count or 0,v.maxMembers or Rules.maxMembers),size=12,color=C.muted,gap=10}}
        if u.rank then table.insert(parts,{num='#'..tostring(u.rank),size=12,color=C.muted,gap=10})end
        inline(sub,0,16,parts,10)
        local today=0;for _,m in ipairs(u.members or {})do if m.today then today+=1 end end
        local lt=string.format('%d/%d',today,math.max(1,u.count or #(u.members or {})))
        local l=K.num(f,'TodayCount',lt,12,C.muted,Enum.TextXAlignment.Right);local lw=K.width(lt,12,l);K.box(l,bw-13-lw-1,68,lw+1,18)
        local bar=K.fillBar(f,'TodayBar',{p=today/math.max(1,u.count or 1),fill=col,track=C.raised});K.box(bar.frame,13,74,bw-13-lw-1-8-13,6)
    else
        local ry=fmt=='pc'and 61 or 37;local rh=fmt=='pc'and 22 or 17;local fs=fmt=='pc'and 15 or 12
        local row=K.make('Frame',f,{Name='Stats',BackgroundTransparency=1});K.box(row,nameX,ry,ax-12-nameX,rh)
        local lv=K.num(row,'Level','Lv '..tostring(u.level or 1),fs,C.ink);local lw=K.width(lv.Text,fs,lv);K.box(lv,0,0,lw+1,rh)
        local barW=fmt=='pc'and 220 or 110
        local bar=K.fillBar(row,'LevelBar',{p=from or frac,fill=col,track=C.raised});K.box(bar.frame,lw+12,math.floor((rh-6)/2),barW,6)
        if from and from~=frac then task.defer(function()bar:set(frac,true)end)end
        if fmt=='pc'then
            local x=lw+12+barW+12
            local pi=K.icon(row,'people',14,C.muted,'People');K.box(pi,x,math.floor((rh-14)/2),14,14);x+=14+12
            local a=K.num(row,'Count',tostring(u.count or 0),fs,C.ink);local aw=K.width(a.Text,fs,a);K.box(a,x,0,aw+1,rh)
            local b=K.num(row,'Max','/'..tostring(v.maxMembers or Rules.maxMembers),fs,C.muted);local bw2=K.width(b.Text,fs,b);K.box(b,x+aw,0,bw2+1,rh);x+=aw+bw2+12
            if u.rank then local r=K.num(row,'Rank','#'..tostring(u.rank),fs,C.gold);K.box(r,x,0,60,rh)end
        end
    end
    attendButton(ctx,f,ax,fmt=='pc'and 24 or fmt=='ph'and 11 or 15)
    return f
end
local function mateCell(ctx,parent,m,u,x,y,w)
    local g,fmt=ctx.g,ctx.fmt;local mine=m.userId==Me.UserId;local h=g.rowH
    local tools=u.isLeader and not m.leader
    local f
    if tools then
        local b=K.button(parent,'Member'..tostring(m.userId),{kind='none',r=8},function()mateSheet(ctx,m)end);b:place(x,y,w,h)
        f=b.face;f.BackgroundColor3=C.panel;f.BackgroundTransparency=0;b.baseFill=C.panel;b.baseAlpha=0
        b.faceStroke.Enabled=true;b.faceStroke.Thickness=1;b.faceStroke.Color=C.line;b.faceStroke.Transparency=0;b.baseStroke=C.line
        ctx.cells[#ctx.cells+1]=b.button
    else
        f=K.make('Frame',parent,{Name='Member'..tostring(m.userId),BackgroundColor3=C.panel,BorderSizePixel=0});K.round(f,8);K.box(f,x,y,w,h)
        if m.leader then K.stroke(f,C.gold,1,.6,true)elseif mine then K.stroke(f,C.accent,1,.4,true)else K.stroke(f,C.line,1,0,true)end
        ctx.cells[#ctx.cells+1]=f
    end
    local av=K.avatar(f,'Avatar',m.userId,g.av);K.box(av,g.avX,math.floor((h-g.av)/2),g.av,g.av)
    onlineDot(f,g.avX+g.av-g.dot+1,math.floor((h+g.av)/2)-g.dot+1,g.dot,m.online)
    local nx=g.avX+g.av+g.avGap
    local cx=w-g.cpad-g.check
    if m.today then local ck=K.icon(f,'check',g.check,C.accent,'Today');K.box(ck,cx,math.floor((h-g.check)/2),g.check,g.check)end
    local right=cx-g.valGap
    if g.valFs>0 then
        local vt=num(m.total);local vl=K.num(f,'Total',vt,g.valFs,C.muted,Enum.TextXAlignment.Right);local vw=K.width(vt,g.valFs,vl);K.box(vl,right-vw-1,0,vw+1,h);right-=vw+8
    end
    local crown=m.leader and fmt~='ph'
    local nm=skip(K.text(f,'Name',m.name or '',g.cellFs,C.ink,700));K.box(nm,nx,crown and(fmt=='pc'and 12 or 8)or 0,right-nx,crown and g.cellFs+6 or h)
    if crown then
        local row=K.make('Frame',f,{Name='Leader',BackgroundTransparency=1});K.box(row,nx,fmt=='pc'and 33 or 25,right-nx,g.crownFs+3)
        inline(row,0,g.crownFs+3,{{icon='crown',size=g.crownFs,color=C.gold},{text='클랜장',size=g.crownFs,color=C.gold}},4)
    end
end
local function memberScreen(ctx)
    local lobby,v,g,root,W,H,fmt=ctx.lobby,ctx.v,ctx.g,ctx.root,ctx.W,ctx.H,ctx.fmt;local u=v.unit
    banner(ctx,u)
    lobby.clanTab=lobby.clanTab or 'members'
    local prev=lobby.clan20Tab;lobby.clan20Tab=lobby.clanTab
    local seg=K.segment(root,'ClanTabs',{{'members','클랜원'},{'board','클랜 순위'},{'war','클랜전'}},prev or lobby.clanTab,function(id)
        if lobby.clanTab~=id then lobby.clanTab=id;step('clanTab',id);lobby:drawPage()end end,{size=g.tabFs})
    seg:place(g.L,g.tabY,fmt=='pt'and W-g.L-g.R or(fmt=='pc'and 420 or 280),g.tabH)
    if prev and prev~=lobby.clanTab then seg:select(lobby.clanTab,true)end
    local top=g.gridY;local bottom=H-g.bottom;local w=W-g.L-g.R
    local sc=scroller(root,'ClanList',g.L,top,w,bottom-top)
    local y=0;local rows={}
    ctx.cells={}
    if lobby.clanTab=='members'then
        local cw=(w-(g.cols-1)*g.gapX)/g.cols
        for i,m in ipairs(u.members or {})do
            local c=(i-1)%g.cols;local r=math.floor((i-1)/g.cols)
            mateCell(ctx,sc,m,u,math.floor(c*(cw+g.gapX)+.5),r*(g.rowH+g.gapY),math.floor(cw+.5))
        end
        rows=ctx.cells
        y=math.ceil(#(u.members or {})/g.cols)*(g.rowH+g.gapY)
    elseif lobby.clanTab=='board'then
        y=listRows(ctx,sc,0,w,v.top or {},{kind='xp',mine=u.id,rank=true},rows)
    else
        y=warCard(ctx,sc,0,w,u)
        y=listRows(ctx,sc,y,w,(v.war and v.war.top)or {},{kind='war',mine=u.id,rank=true},rows)
    end
    sc.CanvasSize=UDim2.fromOffset(0,y+8)
    if prev and prev~=lobby.clanTab then
        local order={members=1,board=2,war=3};K.appear(sc,{dx=(order[lobby.clanTab]or 1)>(order[prev]or 1)and 24 or -24,t=.16})
    else appearRows(rows,ctx.first)end
end

local function primeBand(ctx)
    local lobby,v,g,root,W,fmt=ctx.lobby,ctx.v,ctx.g,ctx.root,ctx.W,ctx.fmt
    local w=W-g.L-g.R;local h=g.bandH;local owned=v.prime==true
    local face
    if owned then face=K.make('Frame',root,{Name='PrimeBand',BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0});K.round(face,10);K.box(face,g.L,g.bandY,w,h);K.stroke(face,C.prime,1,.6,true)
    else
        local b=painted(root,'PrimeBand',{fill=Color3.new(1,1,1),stroke=C.prime,strokeAlpha=.6,r=10},function()step('clanPrimeView');lobby:openPage('benefits')end)
        b:place(g.L,g.bandY,w,h);face=b.face
    end
    K.make('UIGradient',face,{Rotation=0,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,mix(C.panel,C.prime,.10)),ColorSequenceKeypoint.new(.6,C.panel),ColorSequenceKeypoint.new(1,C.panel)})})
    inline(face,g.bandPad,h,{{icon='marshal',size=g.bandIcon,color=C.prime},{text=owned and '커맨더 프라임'or '클랜은 커맨더 프라임',size=g.bandFs,color=C.ink,gap=fmt=='pc'and 12 or 10}},12)
    local right=K.make('Frame',face,{Name='Right',BackgroundTransparency=1});K.box(right,w-g.bandPad-160,0,160,h)
    local parts=owned and {{icon='check',size=g.bandLink,color=C.prime},{text='보유',size=g.bandLink,color=C.prime,gap=4}}or {{text='보기',size=g.bandLink,color=C.prime},{icon='chev',size=g.bandLink+1,color=C.prime,gap=3}}
    local objs,tw=inline(right,0,h,parts,4);for _,e in ipairs(objs)do e.o.Position+=UDim2.fromOffset(160-tw,0)end
    return face
end
local function filtered(v,query)
    local q=string.lower(query or ''):gsub('^%s+',''):gsub('%s+$','')
    local rows=v.top or {}
    if q==''then return rows,nil end
    local out={}
    for _,r in ipairs(rows)do if string.find(string.lower(r.name or ''),q,1,true)or string.find(string.lower(r.tag or ''),q,1,true)then table.insert(out,r)end end
    return out,Rules.validCode((query:gsub('%s','')))
end
local function codeRow(ctx,parent,code,y,w)
    local g,fmt,lobby,v=ctx.g,ctx.fmt,ctx.lobby,ctx.v
    local row=K.make('Frame',parent,{Name='JoinCode',BackgroundColor3=C.panel,BorderSizePixel=0});K.round(row,8);K.box(row,0,y,w,g.listH);K.stroke(row,C.accent,1,.6,true)
    local holder=K.make('Frame',row,{Name='Code',BackgroundTransparency=1});K.box(holder,g.rowPad,0,w-g.rowPad*2-g.joinW-10,g.listH)
    inline(holder,0,g.listH,{{icon='code',size=fmt=='pc'and 22 or 18,color=C.accent},{text='초대 코드',size=g.rowFs,color=C.ink,gap=fmt=='pc'and 16 or 10},{num=code,size=g.rowFs,color=C.accent,gap=8}},8)
    local b
    if v.prime then b=K.button(row,'JoinByCode',{kind='plain',text='가입',size=g.joinFs,weight=800},function()ask(lobby,'join',code)end)
        if lobby.unitBusy then b:setEnabled(false)end
    else b=painted(row,'JoinByCode',{fill=C.raised,stroke=C.line},function()end);b:setEnabled(false,true);b.onRefuse=function()lockPop(lobby,b.face,'join')end end
    b:place(w-g.rowPad-g.joinW,math.floor((g.listH-g.joinH)/2),g.joinW,g.joinH)
    if not v.prime then inline(b.face,0,g.joinH,{{icon='lock',size=g.joinFs,color=C.prime},{text='가입',size=g.joinFs,color=C.muted}},4,true,g.joinW)end
    return row
end
local function guestList(ctx,sc,w,query,animate)
    for _,o in ipairs(sc:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
    local lobby,v,g=ctx.lobby,ctx.v,ctx.g
    local rows,code=filtered(v,query)
    local y=0;local shown={}
    if code then table.insert(shown,codeRow(ctx,sc,code,y,w));y+=g.listStep end
    local state=v.topState
    if #rows==0 and state~='loading'and state~='failed'then
        if (query:gsub('%s',''))~=''then
            if not code then
                local t=K.text(sc,'NoMatch','찾는 클랜이 없어요',14,C.muted,700,Enum.TextXAlignment.Center);K.box(t,0,y,w,g.listH);y+=g.listH+8
            end
        elseif #(v.top or {})==0 then
            local prime=v.prime==true;local h=g.listH
            local mk=painted(sc,'EmptyCreate',{fill=C.panel},function()createSheet(ctx)end);mk:place(0,y,w,h)
            local fs=ctx.fmt=='ph'and 13 or 15;local is=ctx.fmt=='ph'and 14 or 16
            local objs,tw=inline(mk.face,0,h,{{icon='plus',size=is,color=C.ink},{text='클랜 만들기',size=fs,color=C.ink}},6,true,w)
            if not prime then
                local chip,lw,lh=K.chip(mk.face,'Lock','프라임','prime',{size=11,height=ctx.fmt=='pc'and 20 or 18})
                for _,e in ipairs(objs)do e.o.Position-=UDim2.fromOffset(math.floor((8+lw)/2),0)end
                chip.Position=UDim2.fromOffset(math.floor((w-tw)/2)-math.floor((8+lw)/2)+tw+8,math.floor((h-lh)/2))
                mk:setEnabled(false,true);mk.onRefuse=function()K.punch(chip,1.08,.14);lockPop(lobby,mk.face,'create')end
            elseif lobby.unitBusy then mk:setEnabled(false)end
            table.insert(shown,mk.button);y+=g.listStep
        end
    else
        y=listRows(ctx,sc,y,w,rows,{kind='xp',join={prime=v.prime==true},empty='찾는 클랜이 없어요'},shown)
    end
    local open=lobby.clanGuestWar==true
    local fold=K.button(sc,'WarFold',{kind='none',r=8},function()lobby.clanGuestWar=not open;step('clanTab',open and 'find'or 'war');lobby:drawPage()end)
    fold:place(0,y,w,ctx.fmt=='ph'and 36 or 40)
    local d=K.dashBox(fold.face,'Dash',C.line,0,8,1);d.Size=UDim2.fromOffset(w,ctx.fmt=='ph'and 36 or 40)
    inline(fold.face,0,ctx.fmt=='ph'and 36 or 40,{{icon='medal',size=15,color=C.muted},{text='클랜전 순위',size=13,color=C.muted},{icon=open and 'up'or 'chev',size=14,color=C.muted}},6,true,w)
    y+=(ctx.fmt=='ph'and 36 or 40)+8
    if open then
        y=warCard(ctx,sc,y,w,nil)
        y=listRows(ctx,sc,y,w,(v.war and v.war.top)or {},{kind='war',rank=true})
    end
    if v.studio then
        local list={{'xp','기여 +5,000'},{'reset','출석 초기화'},{'war','클랜전 승'},{'warLoss','클랜전 패'}}
        local bw=(w-18)/4
        for i,b in ipairs(list)do
            local dv=K.button(sc,'ClanDev_'..b[1],{kind='ghost',text=b[2],size=12},function()if b[1]=='warLoss'then ask(lobby,'dev','war','loss')else ask(lobby,'dev',b[1])end end)
            dv:place((i-1)*(bw+6),y,bw,36);dv.label.TextColor3=C.gold
        end
        y+=44
    end
    sc.CanvasSize=UDim2.fromOffset(0,y+8)
    appearRows(shown,animate)
end
local function guestScreen(ctx)
    local lobby,v,g,root,W,H,fmt=ctx.lobby,ctx.v,ctx.g,ctx.root,ctx.W,ctx.H,ctx.fmt
    local d=lobby.unitDraft or {};lobby.unitDraft=d
    primeBand(ctx)
    local w=W-g.L-g.R;local h=g.toolsH;local y=g.toolsY
    local prime=v.prime==true
    local cs=g.toolsIcon;local fs=g.toolsFs;local pad=fmt=='pc'and 16 or 10
    local create=painted(root,'CreateClan',{fill=C.raised,stroke=C.line},function()createSheet(ctx)end)
    local objs,cwText=inline(create.face,pad,h,{{icon='plus',size=cs,color=C.ink},{text='만들기',size=fs,color=C.ink}},6)
    local cw=pad+cwText+pad
    if not prime then
        local chip,lockW,lockH=K.chip(create.face,'Lock','프라임','prime',{size=11,height=fmt=='pc'and 20 or 18})
        local last=objs[#objs];chip.Position=UDim2.fromOffset(last.o.Position.X.Offset+last.w+8,math.floor((h-lockH)/2))
        cw+=8+lockW
        create:setEnabled(false,true)
        create.onRefuse=function()K.punch(chip,1.08,.14);lockPop(lobby,create.face,'create')end
    end
    create:place(g.L+w-cw,y,cw,h)
    if lobby.unitBusy and prime then create:setEnabled(false)end
    local sw=w-cw-(fmt=='pt'and 8 or 10)
    local sf=K.make('Frame',root,{Name='Search',BackgroundColor3=C.bg,BorderSizePixel=0});K.round(sf,8);local st=K.stroke(sf,C.line,1,0,true);K.box(sf,g.L,y,sw,h)
    local si=K.icon(sf,'watch',cs,C.dim,'Icon');K.box(si,12,math.floor((h-cs)/2),cs,cs)
    local box=K.make('TextBox',sf,{Name='ClanSearch',Text=d.search or '',PlaceholderText='클랜 이름, 초대 코드',ClearTextOnFocus=false,TextSize=fs,TextColor3=C.ink,PlaceholderColor3=C.dim,
        BackgroundTransparency=1,BorderSizePixel=0,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
    local rs=32;local ri=math.max(0,math.floor((h-rs)/2))
    local rf=K.button(sf,'RefreshClan',{kind='none',icon='restore',iconSize=fmt=='ph'and 14 or 16},function()ask(lobby,'read')end)
    rf.iconColorFixed=true;rf.iconImage.ImageColor3=C.muted;rf:place(sw-ri-rs,ri,rs,rs)
    if lobby.unitBusy then rf:setEnabled(false,true);rf.iconImage.ImageTransparency=.5 end
    box.FontFace=K.fonts[600];K.box(box,12+cs+8,0,sw-12-cs-8-ri-rs-4,h)
    box.Focused:Connect(function()st.Color=C.accent end);box.FocusLost:Connect(function()st.Color=C.line end)
    local top=g.listY;local bottom=H-g.bottom
    local sc=scroller(root,'ClanList',g.L,top,w,bottom-top)
    guestList(ctx,sc,w,d.search or '',ctx.first)
    box:GetPropertyChangedSignal('Text'):Connect(function()
        if d.search==box.Text then return end
        d.search=box.Text;guestList(ctx,sc,w,d.search,false)end)
end

function M.draw(lobby,body,_w)
    for _,o in ipairs(body:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
    body.CanvasSize=UDim2.fromOffset(0,0)
    local first=Pop.watch(lobby,'clan')
    local root,W,H,fmt=K.screenRoot(lobby,body,'Clan20')
    local v=lobby.unitView
    if not v then
        local failed=lobby.unitReadFailed and not lobby.unitBusy
        local t=K.text(root,'Status',failed and '클랜 정보 불러오기 실패'or '클랜 정보 불러오는 중…',15,C.muted,700,Enum.TextXAlignment.Center);K.box(t,0,math.floor(H/2)-44,W,32)
        if failed then
            local b=K.button(root,'Retry',{kind='out',text='다시 불러오기',size=16},function()lobby.unitReadFailed=false;ask(lobby,'read')end)
            b:place(math.floor((W-200)/2),math.floor(H/2),200,48)
        elseif not lobby.unitBusy then ask(lobby,'read')end
        return
    end
    if not lobby.clanSeen then lobby.clanSeen=true;step('clanOpened',v.unit and 'member'or 'guest')end
    lobby.clanMark=nil
    local ctx={lobby=lobby,v=v,root=root,W=W,H=H,fmt=fmt,g=GEO[fmt],first=first}
    if v.unit then memberScreen(ctx)else guestScreen(ctx)end
end
return M
