local Players=game:GetService('Players')
local K=require(script.Parent.Kit20)
local S=require(script.Parent.Sheet20)
local Theme=require(script.Parent.Theme)
local Colors=require(script.Parent.FactionColors)
local Maps=require(game.ReplicatedStorage.FrontierNative.Maps.MapLoader)
local Core=game.ReplicatedStorage.FrontierNative.Core
local Rules=require(Core.CustomBattlefieldRules)
local Copy=require(Core.BattlefieldRules)
local TeamFormat=require(Core.TeamFormat)
local Options=require(Core.MatchOptions)
local C=K.colors
local M={}
local function commas(n)return Theme.commas(math.floor(n or 0))end

function M.chips(r)
    local s=r.settings or {};local out={}
    if r.mode=='coop'or s.nations~='disabled'then table.insert(out,{icon='npc',text=string.format('AI %s',Options.difficultyLabels[s.difficulty or 'Medium']or '보통')})end
    local gold=tonumber(s.startingGold)or 0
    if gold>0 then table.insert(out,{icon='coinGold',color=true,text=gold%10000==0 and string.format('골드 %s만',commas(gold/10000))or string.format('골드 %s',commas(gold))})end
    if s.disableNukes then table.insert(out,{text='핵 없음'})end
    if s.disableAlliances then table.insert(out,{text='동맹 없음'})end
    if r.spawn=='random'then table.insert(out,{icon='target',text='랜덤 스폰'})end
    if s.infiniteGold then table.insert(out,{text='무한 골드'})end
    if s.infiniteTroops then table.insert(out,{text='무한 병력'})end
    if s.instantBuild then table.insert(out,{text='즉시 건설'})end
    for _,k in ipairs(r.modifiers or {})do local name=Copy.modifierLabels[k]
        if name and k~='isRandomSpawn'and not k:match('^startingGold')and k~='isNukesDisabled'and k~='isAlliancesDisabled'then table.insert(out,{text=name})end end
    return out
end
local function modeChipText(r,plan)
    if r.mode=='coop'then return '협동','coop'end
    if r.mode=='teams'then
        if r.teamFormat then return TeamFormat.short(r.teamFormat,plan and plan.count or r.teamCount)or '팀전','teams'end
        return string.format('팀전 %d팀',plan and plan.count or r.teamCount or 2),'teams'
    end
    return '개인전','ffa'
end
local function invite(lobby,q)
    require(script.Parent.ToyAudio).play('click')
    task.spawn(function()local social=game:GetService('SocialService');local ok,can=pcall(function()return social:CanSendGameInviteAsync(Players.LocalPlayer)end)
        if ok and can then local options=Instance.new('ExperienceInviteOptions');options.LaunchData=game.HttpService:JSONEncode({commanderRoom=q.code});pcall(function()social:PromptGameInvite(Players.LocalPlayer,options)end)
        else lobby.notify('코드로 초대')end
    end)
end

local function member(parent,name,m,q,w,h,fs,av,partyIds)
    local me=Players.LocalPlayer.UserId;local small=h<30
    local f=K.make('Frame',parent,{Name=name,BackgroundColor3=C.panel,BorderSizePixel=0,Size=UDim2.fromOffset(w,h)})
    K.round(f,small and 6 or 8);K.stroke(f,m.userId==me and C.accent or C.line,m.userId==me and 2 or 1,0,true)
    local pad=small and 6 or 8
    local face=K.avatar(f,'Avatar',m.userId,av);K.box(face,pad,(h-av)/2,av,av)
    if partyIds[m.userId]and m.userId~=me then local d=small and 7 or 9;local dot=K.make('Frame',f,{Name='Party',BackgroundColor3=C.gold,BorderSizePixel=0,ZIndex=3});K.round(dot,'pill');K.stroke(dot,C.bg,2);K.box(dot,pad-3,(h-av)/2-3,d,d)end
    local host=m.userId==q.hostUserId
    local right=w-pad
    local ready=host or m.ready
    if ready then local is=fs+2;local ck=K.icon(f,'check',is,C.accent,'Ready');K.box(ck,right-is,(h-is)/2,is,is);right-=is+6
    else local ws=math.max(11,fs-2);local t=K.text(f,'Waiting','준비 중',ws,C.muted,700,Enum.TextXAlignment.Right);local tw=K.width('준비 중',ws,t);K.box(t,right-tw-2,0,tw+2,h);right-=tw+8 end
    if host then
        local chh=small and 16 or 20;local cs=small and 10 or 12;local word=w>=170
        local chip=K.make('Frame',f,{Name='Host',BackgroundTransparency=1,BorderSizePixel=0});K.round(chip,4);K.stroke(chip,C.line,1,0,true)
        local ic=K.icon(chip,'campaign',cs,C.ink,'Icon');local cw=small and 8 or 12
        local tw=0;if word then local t=K.text(chip,'Text','방장',small and 11 or 11,C.ink,800);tw=K.width('방장',11,t);K.box(t,(small and 4 or 6)+cs+2,0,tw+2,chh);cw=(small and 4 or 6)+cs+2+tw+(small and 4 or 6)else cw=cs+(small and 8 or 12)end
        K.box(ic,word and (small and 4 or 6)or math.floor((cw-cs)/2),(chh-cs)/2,cs,cs)
        K.box(chip,right-cw,(h-chh)/2,cw,chh);right-=cw+6
    end
    local n=K.text(f,'Name',m.name or '',fs,C.ink,700);n:SetAttribute('LocalizationSkip',true)
    K.box(n,pad+av+(small and 6 or 8),0,math.max(10,right-(pad+av+(small and 6 or 8))),h)
    return f
end
local function emptySeat(parent,name,text,w,h,fs,fn,icon)
    local b=K.make('TextButton',parent,{Name=name,Text='',BackgroundTransparency=1,AutoButtonColor=false,BorderSizePixel=0,Size=UDim2.fromOffset(w,h),Active=fn~=nil})
    local d=K.dashBox(b,'Dash',C.muted,.6,h<30 and 6 or 8,1);d.Size=UDim2.fromOffset(w,h)
    local tw=K.width(text,fs);local is=icon and fs+2 or 0;local x=math.floor((w-tw-(icon and is+5 or 0))/2)
    if icon then local ic=K.icon(b,icon,is,C.muted,'Icon');K.box(ic,x,(h-is)/2,is,is);x+=is+5 end
    local t=K.text(b,'Text',text,fs,C.muted,700);K.box(t,x,0,tw+2,h)
    if fn then b.Activated:Connect(function()require(script.Parent.ToyAudio).play('click');fn()end)end
    return b
end

function M.draw(lobby,body)
    for _,o in ipairs(body:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
    local sc=Theme.scale or 1;local W,H=lobby.root.AbsoluteSize.X/sc,lobby.root.AbsoluteSize.Y/sc
    local fmt=S.format(W,H);local pt,ph=fmt=='pt',fmt=='ph'
    local page=K.make('Frame',body,{Name='Page20',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromOffset(W,H)})
    local first=lobby.first20=='room';lobby.first20=nil
    local q=lobby.data and lobby.data.queue;if q and q.mode~='custom'then q=nil end
    local me=Players.LocalPlayer.UserId
    lobby.room20={}
    local backX=pt and 16 or ph and math.max(84,(lobby.topbarLeft or 12)+72)or 40
    local backY=pt and 64 or ph and 8 or 40;local backH=pt and 40 or ph and 32 or 40;local bfs=pt and 14 or ph and 13 or 15;local bis=pt and 18 or ph and 16 or 18
    local back=K.button(page,'Back',{kind='ghost',icon='back',iconSize=bis,text='로비',size=bfs,weight=800,gap=4},function()lobby:closePage()end)
    local bw=bis+4+K.width('로비',bfs)+2+(ph and 8 or 0);back:place(backX,backY,bw,backH);back:layoutContent('left',ph and 4 or 0)
    local L=pt and 16 or ph and 16 or 40;local lw=pt and W-32 or ph and 250 or 420
    if not q then
        local t=K.text(page,'Ended','모집 마감',pt and 24 or ph and 20 or 30,C.ink,800);K.box(t,L,pt and 108 or ph and 44 or 92,lw,pt and 29 or ph and 24 or 36)
        return
    end
    local r=q.rules or Rules.default('world','ffa');local plan=q.teamPlan
    local ty=pt and 108 or ph and 44 or 92;local ts=pt and 24 or ph and 20 or 30;local th=pt and 29 or ph and 24 or 36
    local mapName=(Maps.meta(r.map)or {}).label or r.map
    local title=K.text(page,'Title',mapName,ts,C.ink,800);local tw=K.width(mapName,ts,title)
    local chH=pt and 20 or ph and 20 or 24;local chFs=pt and 11 or ph and 11 or 13;local cg=pt and 8 or ph and 6 or 10
    K.box(title,L,ty,math.min(tw+2,lw-120),th)
    local cx=L+math.min(tw+2,lw-120)+cg
    local c1,w1=S.modeChip(page,'Custom','커스텀',C.ink,C.line,chH,chFs,.2);c1.Position=UDim2.fromOffset(cx,ty+(th-chH)/2);cx+=w1+(ph and 5 or 10)
    local mt,mk=modeChipText(r,plan);local c2=S.modeChip(page,'ModeChip',mt,S.MODE[mk],S.MODEFILL[mk],chH,chFs,.2);c2.Position=UDim2.fromOffset(cx,ty+(th-chH)/2)
    local sy=pt and 144 or ph and 74 or 138;local sh=pt and 22 or ph and 22 or 28
    local host=q.hostUserId==me
    local gearS=sh;local rowRight=L+lw-(host and gearS+8 or 0)
    local list=M.chips(r)
    local fs=pt and 11 or ph and 11 or 13;local is=pt and 12 or ph and 12 or 14;local pad=pt and 7 or ph and 7 or 10;local gap=pt and 5 or ph and 4 or 6;local rr=pt and 6 or ph and 6 or 8
    local function detail(anchor)
        local items={}
        for _,c in ipairs(list)do table.insert(items,{text=c.text,icon=c.icon})end
        table.insert(items,{text=string.format('최대 %d명',r.maximum)})
        table.insert(items,{text=Rules.rewardMode(r)=='custom'and '자유 규칙 / 연습 기록'or '일반 기록 / 랭킹 점수 제외',muted=true})
        S.menu(lobby,anchor,items,{rowH=pt and 40 or 36,size=pt and 13 or 13})
    end
    local chipRow=K.make('TextButton',page,{Name='Rules',Text='',BackgroundTransparency=1,AutoButtonColor=false,BorderSizePixel=0})
    K.box(chipRow,L,sy,rowRight-L,sh)
    chipRow.Activated:Connect(function()require(script.Parent.ToyAudio).play('click');detail(chipRow)end)
    local x=0;local shown=0
    local function chip(c,width)
        local f=K.make('Frame',chipRow,{Name='Rule'..(shown+1),BackgroundColor3=C.panel,BorderSizePixel=0,Active=false})
        K.round(f,rr);K.stroke(f,C.line,1,0,true);K.box(f,x,0,width,sh)
        local tx=pad
        if c.icon then local ic=K.icon(f,c.icon,is,c.color and Color3.new(1,1,1)or C.ink,'Icon');K.box(ic,pad,(sh-is)/2,is,is);tx+=is+(pt and 4 or ph and 4 or 6)end
        local t=K.text(f,'Text',c.text,fs,c.muted and C.muted or C.ink,800);K.box(t,tx,0,width-tx-pad+2,sh)
        x+=width+gap
    end
    local avail=rowRight-L
    local widths={};for i,c in ipairs(list)do widths[i]=pad+(c.icon and is+(pt and 4 or ph and 4 or 6)or 0)+K.width(c.text,fs)+pad end
    local plusW=function(n)return pad*2+K.width('+'..n,fs)end
    for i,c in ipairs(list)do
        local rest=#list-i
        local need=widths[i]+(rest>0 and gap+plusW(rest)or 0)
        if x+need<=avail then chip(c,widths[i]);shown+=1 else break end
    end
    if shown<#list then chip({text='+'..(#list-shown),muted=true},plusW(#list-shown))end
    if #list==0 then chip({text=Rules.rewardMode(r)=='custom'and '자유 규칙'or '일반 규칙',muted=true},pad*2+K.width(Rules.rewardMode(r)=='custom'and '자유 규칙'or '일반 규칙',fs))end
    if host then
        local g=K.button(page,'EditRules',{kind='none',r=rr,icon='settings',iconSize=pt and 13 or ph and 13 or 16},function()require(script.Parent.CustomDeployment).begin(lobby,true)end)
        g.faceStroke.Enabled=true;g.faceStroke.Color=C.line;g.baseStroke=C.line;g.iconColorFixed=true;g.iconImage.ImageColor3=C.muted
        g:place(L+lw-gearS,sy,gearS,gearS)
    end
    local by,bh=pt and H-58-8-56+8 or ph and H-16-52 or H-40-68,pt and 56 or ph and 52 or 68
    local my=pt and 178 or ph and 102 or 174
    local mh=pt and math.floor((W-32)*.2+.5)+2 or by-(ph and 8 or 24)-(ph and 62 or 96)-my+2
    local map=K.map(page,'Map',r.map,lw+2,mh,8);K.box(map,L,my,lw+2,mh);K.stroke(map,C.line,1,0,true)
    local cy=my+mh+(pt and 8 or ph and 6 or 18)
    local ls=pt and 11 or ph and 11 or 13;local cs=pt and 24 or ph and 24 or 40
    local codeText=tostring(q.code or '')
    if #codeText==8 then codeText=codeText:sub(1,4)..' '..codeText:sub(5)end
    local codeL=K.num(page,'Code',codeText,cs,C.ink);local cw=K.width(codeText,cs,codeL)
    local codeY=cy+ls+2+(pt and 2 or ph and 2 or 4)
    local cis=pt and 16 or ph and 16 or 24;local cic=K.icon(page,'code',cis,C.muted,'CodeIcon');K.box(cic,L,codeY+math.floor((cs-cis)/2),cis,cis)
    K.box(codeL,L+cis+(pt and 6 or ph and 6 or 8),codeY,cw+2,cs)
    local others,ready=0,0;for _,m in ipairs(q.members or {})do if m.userId~=q.hostUserId then others+=1;if m.ready then ready+=1 end end end
    local barW=pt and 70 or ph and 70 or 160;local rfs=pt and 13 or ph and 13 or 18
    local barY=codeY+cs-6;local ry=barY-8-(rfs+8)
    local rn=K.num(page,'ReadyCount',string.format('%d / %d',ready,others),rfs,C.accent);local rnw=K.width(rn.Text,rfs,rn)
    K.box(rn,L+lw-rnw-1,ry,rnw+1,rfs+8)
    local rw=K.text(page,'ReadyWord','준비',rfs-(pt and 0 or ph and 0 or 2),C.accent,800);local rww=K.width('준비',rw.TextSize,rw)
    K.box(rw,L+lw-rnw-1-6-rww-2,ry,rww+2,rfs+8)
    local bar=K.fillBar(page,'ReadyBar',{p=others>0 and ready/others or 0,fill=C.accent,track=C.raised});K.box(bar.frame,L+lw-barW,barY,barW,6)
    lobby.room20.bar=bar
    local lw1=pt and 96 or ph and 76 or 110
    local leave=K.button(page,'Leave',{kind='plain',text='나가기',size=pt and 16 or ph and 14 or 17,weight=800},function()require(script.Parent.CustomDeployment).secondary(lobby)end)
    leave:place(L,by,lw1,bh);if not pt then leave.label.TextColor3=C.muted;leave.ink=C.muted end
    local go=K.button(page,'Start',{kind='pri',text='시작',size=pt and 22 or ph and 22 or 28,weight=800},function(b)if b.enabled then K.confirm(b,true)end;require(script.Parent.CustomDeployment).primary(lobby)end)
    go:place(L+lw1+(pt and 8 or ph and 8 or 12),by,lw-lw1-(pt and 8 or ph and 8 or 12),bh)
    lobby.room20.leave=leave;lobby.room20.go=go
    local gx,gw,gy
    if pt then gx,gw,gy=16,W-32,cy+56 else gx=L+lw+(ph and 16 or 40);gw=W-gx-(ph and 16 or 40);gy=ph and 48 or 42 end
    local hh=pt and 32 or ph and 28 or 36;local hfs=pt and 13 or ph and 13 or 16;local nfs=pt and 15 or ph and 15 or 20
    local hl=K.text(page,'RosterTitle','지휘관',hfs,C.ink,800);local hw=K.width('지휘관',hfs,hl);K.box(hl,gx,gy,hw+2,hh)
    local n1=K.num(page,'Count',tostring(q.count or #(q.members or {})),nfs,C.ink);local n1w=K.width(n1.Text,nfs,n1);K.box(n1,gx+hw+10,gy,n1w+1,hh)
    local n2=K.num(page,'Max',' / '..tostring(q.max or r.maximum),nfs,C.muted);K.box(n2,gx+hw+10+n1w,gy,80,hh)
    local ifs=pt and 13 or ph and 12 or 14;local iis=pt and 14 or ph and 13 or 16
    local inv=K.button(page,'Invite',{kind='plain',icon='people',iconSize=iis,text='친구 초대',size=ifs,weight=800,gap=5},function()invite(lobby,q)end)
    local iw=(pt and 10 or ph and 8 or 12)*2+iis+5+K.width('친구 초대',ifs)+2;inv:place(gx+gw-iw,gy,iw,hh)
    local rosterTop=gy+hh+(pt and 8 or ph and 6 or 14)
    local rosterBottom=pt and by-12 or H-(ph and 8 or 24)
    local scroll=S.scroll(page,'Roster',gx,rosterTop,gw,rosterBottom-rosterTop)
    local partyIds={};local party=lobby.data and lobby.data.party
    if party and #party.users>1 then for _,id in ipairs(party.users)do partyIds[id]=true end end
    local rows={};local y=0
    local selectable=plan and plan.selectable and not plan.locked
    if plan and plan.count and plan.count>1 then
        local myTeam=plan.teams[tostring(me)]
        local order={};for t=1,plan.count do table.insert(order,t)end
        table.sort(order,function(a,b)if (a==myTeam)~=(b==myTeam)then return a==myTeam end;return a<b end)
        local cap=TeamFormat.fixedSize(r.teamFormat)or math.ceil((q.max or r.maximum)/plan.count)
        local hvn=r.teamFormat=='HumansVsNations'
        local cols=pt and 1 or 2;local tg=pt and 8 or ph and 8 or 16;local tw2=math.floor((gw-tg*(cols-1))/cols)
        local colY={}
        for i,t in ipairs(order)do
            local col=(i-1)%cols;local x0=col*(tw2+tg);local y0=colY[col]or 0
            local mine=t==myTeam
            local box=K.make('Frame',scroll,{Name='Team'..t,BackgroundColor3=mine and C.accent or C.panel,BackgroundTransparency=mine and .93 or .4,BorderSizePixel=0})
            K.round(box,pt and 10 or ph and 8 or 10);K.stroke(box,mine and C.accent or C.line,1,mine and .65 or 0,true)
            local ip=pt and 9 or ph and 6 or 9;local ipy=pt and 8 or ip
            local headH=pt and 20 or ph and 22 or 30;local rowH=pt and 32 or ph and 28 or 48;local rg=pt and 5 or ph and 4 or 8
            local tfs=pt and 13 or ph and 12 or 15;local mfs=pt and 12 or ph and 11 or 14;local av=pt and 22 or ph and 20 or 32
            local inner=tw2-ip*2
            local tb=K.make('Frame',box,{Name='Bar',BackgroundColor3=Colors.team(t,myTeam)or C.line,BorderSizePixel=0});K.round(tb,'pill');K.box(tb,ip+2,ipy+4,4,headH-8)
            if mine then tb.BackgroundColor3=C.accent end
            local tn=K.text(box,'Name',mine and '우리 팀'or hvn and (t==1 and '사람 팀'or '국가 팀')or string.format('%d팀',t),tfs,mine and C.accent or C.ink,900);K.box(tn,ip+12,ipy,inner-60,headH)
            local members={};for _,m in ipairs(q.members or {})do if plan.teams[tostring(m.userId)]==t then table.insert(members,m)end end
            local cn=K.num(box,'Count',string.format('%d',#members),tfs,C.ink,Enum.TextXAlignment.Right);local cm=K.num(box,'Cap',' / '..cap,tfs,C.muted)
            local cmw=K.width(' / '..cap,tfs,cm);K.box(cm,ip+inner-2-cmw,ipy,cmw+1,headH);K.box(cn,ip+inner-2-cmw-40,ipy,40,headH)
            if selectable and not mine then
                local hit=K.make('TextButton',box,{Name='Choose',Text='',BackgroundTransparency=1,AutoButtonColor=false,Size=UDim2.new(1,0,0,headH+ipy)})
                hit.Activated:Connect(function()require(script.Parent.ToyAudio).play('click');lobby:request('customTeam',{team=t,revision=q.revision})end)
            end
            local yy=ipy+headH+rg
            local gridCols=pt and 2 or 1;local mw=gridCols==2 and math.floor((inner-6)/2)or inner
            for k,m in ipairs(members)do
                local rowF=member(box,'Member'..m.userId,m,q,mw,rowH,mfs,av,partyIds)
                local gc=(k-1)%gridCols;rowF.Position=UDim2.fromOffset(ip+gc*(mw+6),yy+((k-1)//gridCols)*(rowH+rg))
                table.insert(rows,rowF)
            end
            yy+=math.ceil(#members/gridCols)*(rowH+rg)
            local ai=plan.aiCounts and (plan.aiCounts[t]or plan.aiCounts[tostring(t)])or 0
            local open=math.max(0,cap-#members)
            if not pt and (ai>0 or open>0)then
                local eh=ph and 24 or 40
                local seat=emptySeat(box,'Open',ai>0 and string.format('AI +%d',ai)or string.format('빈자리 %d',open),inner,eh,ph and 11 or 13,selectable and not mine and ai==0 and function()lobby:request('customTeam',{team=t,revision=q.revision})end or nil,ai>0 and 'npc'or nil)
                seat.Position=UDim2.fromOffset(ip,yy);yy+=eh+rg
            end
            local boxH=yy-rg+ipy
            K.box(box,x0,y0,tw2,boxH);colY[col]=y0+boxH+tg
        end
        for _,v in pairs(colY)do y=math.max(y,v)end
    else
        local cols=pt and 2 or ph and 2 or 3;local g=pt and 8 or ph and 6 or 10
        local tw2=math.floor((gw-g*(cols-1))/cols);local th2=pt and 36 or ph and 34 or 52
        local mfs=pt and 13 or ph and 12 or 15;local av=pt and 24 or ph and 24 or 36
        local list2=q.members or {}
        for k,m in ipairs(list2)do
            local rowF=member(scroll,'Member'..m.userId,m,q,tw2,th2,mfs,av,partyIds)
            rowF.Position=UDim2.fromOffset(((k-1)%cols)*(tw2+g),((k-1)//cols)*(th2+g));table.insert(rows,rowF)
        end
        local open=math.max(0,(q.max or r.maximum)-#list2);local n=#list2
        if open>0 then local seat=emptySeat(scroll,'Open',string.format('빈자리 %d',open),tw2,th2,pt and 13 or ph and 12 or 13,nil);seat.Position=UDim2.fromOffset((n%cols)*(tw2+g),(n//cols)*(th2+g));n+=1 end
        y=math.ceil(n/cols)*(th2+g)
    end
    S.canvas(scroll,y)
    local seen=lobby.room20Seen
    if first or not seen then S.stagger(rows,first)
    else for _,rowF in ipairs(rows)do local id=tonumber(rowF.Name:match('%d+$'))
        if id and not seen[id]and not K.reduced then K.appear(rowF,{scaleFrom=.9,t=.14});require(script.Parent.ToyAudio).play('pop')end end end
    lobby.room20Seen={};for _,m in ipairs(q.members or {})do lobby.room20Seen[m.userId]=true end
    M.footer(lobby)
end
function M.footer(lobby)
    local r=lobby.room20;if not r or not r.go then return end
    local q=lobby.data and lobby.data.queue;if q and q.mode~='custom'then q=nil end
    local me=Players.LocalPlayer.UserId;local host=q and q.hostUserId==me
    local others=require(script.Parent.CustomDeployment).canLaunch(q)
    local n=q and q.remaining and math.max(0,math.ceil(q.remaining-(os.clock()-(lobby.queueUpdated or os.clock()))))
    local text=not q and '방 모집 종료'or q.phase=='transferring'and '전장으로 이동 중…'or n and (n>0 and string.format('%d초 뒤 출발',n)or '출발 중…')or host and (others and '시작'or '준비 대기')or q.ready and '준비 완료'or '준비'
    r.go:setText(text)
    local on=q~=nil and not lobby.busy and not q.locked and not q.remaining and q.phase~='transferring'and (not host or others)
    r.go:setKind(on and 'pri'or 'dis');r.go:setEnabled(on,true)
    r.leave:setEnabled(q~=nil and not lobby.busy and not q.locked)
    if q and r.bar then local o,rd=0,0;for _,m in ipairs(q.members or {})do if m.userId~=q.hostUserId then o+=1;if m.ready then rd+=1 end end end
        local p=o>0 and rd/o or 0;if r.barP~=p then r.bar:set(p,r.barP~=nil);r.barP=p end end
end
return M
