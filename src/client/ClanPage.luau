local Players=game:GetService('Players')
local Market=game:GetService('MarketplaceService')
local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.OutgameIcons)
local V=require(script.Parent.ClanVisuals)
local Telemetry=require(script.Parent.TelemetryClient)
local Rules=require(game.ReplicatedStorage.FrontierNative.Core.ClanRules)
local pack=game.ReplicatedStorage.FrontierNative
local M={}
local C=UI.colors
local skip=V.skip
local Me=Players.LocalPlayer
local function step(name,item)pcall(Telemetry.step,'social',name,item and {item=item}or nil)end
local function ask(lobby,action,a,b,c)
    if lobby.unitBusy then return end;lobby.unitBusy=true;lobby:drawPage()
    task.spawn(function()
        local ok,r=pcall(function()return pack:WaitForChild('ClanRequest',5):InvokeServer(action,a,b,c)end)
        lobby.unitBusy=false
        local good=ok and type(r)=='table'and r.ok
        if good and r.purchase then
            step('clanExtraPrompt');M.extraProduct=r.purchase
            local opened=pcall(function()Market:PromptProductPurchase(Me,r.purchase)end)
            pcall(Telemetry.step,'commerce','prompt',{sku='clanAttend',result=opened and 'opened'or 'failed',reason=opened and 'none'or 'failed'})
        elseif good then
            local had=lobby.unitView and lobby.unitView.unit
            lobby.unitView=r;lobby.unitDraft=nil
            if r.attended then lobby.clanGain=os.clock();step(r.attended=='free'and 'clanAttendFree'or 'clanAttendExtra')end
            if action=='create'then step('clanCreated')elseif (action=='join'or action=='joinId')and r.unit then step('clanJoined',action)
            elseif action=='leave'and had and not r.unit then step('clanLeft')end
        elseif ok and type(r)=='table'and r.reason=='need-token'then
            lobby.unitBusy=false;return ask(lobby,'buyExtra')
        elseif ok and type(r)=='table'then lobby.notify(r.message or '다시 시도해 주세요.',true)
        else lobby.notify('연결 끊김, 다시 시도',true)end
        if action=='read'and not good then lobby.unitReadFailed=true end
        if lobby.page=='clan'then lobby:drawPage()end
    end)
end
Market.PromptProductPurchaseFinished:Connect(function(userId,productId,purchased)
    if userId~=Me.UserId or not M.extraProduct or productId~=M.extraProduct then return end
    M.extraProduct=nil;pcall(Telemetry.step,'clan','extraPrompt',{result=purchased and 'accepted'or 'cancelled'})
    if not purchased then return end
    step('clanExtraPurchased')
    for _,t in ipairs({1.5,4,9,16})do task.delay(t,function()local lobby=M.lobby;if lobby and lobby.page=='clan'then lobby.unitView=nil;lobby:drawPage()end end)end
end)

function M.draw(lobby,body,w)
    M.lobby=lobby
    lobby.pageTitle.Text='클랜'
    local cw=w-10
    local compact=cw<560
    local y=0
    local function text(parent,name,value,size,color,x,yy,width,height,raw)
        local l=UI.label(parent,name,value,size or 14,color);l.TextWrapped=true;UI.box(l,x,yy,width,height);if raw then skip(l)end;return l
    end
    local function one(l)l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd;return l end
    local function action(parent,name,label,fn,primary,x,yy,width,height)
        local b=UI.button(parent,name,label,fn,primary);UI.box(b,x,yy,width,height or 44);UI.enabled(b,not lobby.unitBusy);b.TextSize=15;return b
    end
    local function card(name,height,accent)
        local p=UI.panel(body,name);p.BackgroundColor3=C.raised;p.BackgroundTransparency=.15;UI.box(p,2,y,cw,height)
        if accent then UI.make('Frame',p,{Name='Strip',BackgroundColor3=accent,BorderSizePixel=0,Size=UDim2.new(0,3,1,0)})end
        return p
    end
    local function input(parent,name,placeholder,value,x,yy,width,mono)
        local box=UI.make('TextBox',parent,{Name=name,Text=value or '',PlaceholderText=placeholder,ClearTextOnFocus=false,TextSize=16,Font=Enum.Font.BuilderSansMedium,TextColor3=C.ink,PlaceholderColor3=C.muted,BackgroundColor3=C.bg,BackgroundTransparency=.15,BorderSizePixel=0,TextXAlignment=Enum.TextXAlignment.Left})
        UI.corner(box,3);UI.stroke(box,C.line,1);UI.make('UIPadding',box,{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)})
        if mono then UI.display(box,true);box.TextSize=18 end
        local edge=box:FindFirstChildOfClass('UIStroke')
        box.Focused:Connect(function()edge.Color=C.accent end);box.FocusLost:Connect(function()edge.Color=C.line end)
        UI.box(box,x,yy,width,44);return box
    end
    local function tabs(list,current,set)
        local n=#list;local gap=6;local tw=(cw-gap*(n-1))/n
        for i,t in ipairs(list)do
            local on=current==t[1]
            local b=UI.button(body,'ClanTab_'..t[1],t[2],function()if not on then set(t[1]);step('clanTab',t[1]);body.CanvasPosition=Vector2.zero;lobby:drawPage()end end,on)
            UI.box(b,2+(i-1)*(tw+gap),y,tw,48);b.TextSize=compact and 13 or 15
            if t[3]then local ic=Icons.create(b,t[3],16,on and C.bg or C.muted);ic.Name='TabIcon';UI.box(ic,10,16,16,16);if not compact then UI.make('UIPadding',b,{PaddingLeft=UDim.new(0,18)})else ic.Visible=false end end
        end
        y+=56
    end
    local function boardRows(rows,mine,kind,emptyText,joinable)
        local v=lobby.unitView;local state=v and (kind=='war'and v.warState or v.topState)
        if #rows==0 and state=='loading'then
            local p=card('BoardLoading',56);text(p,'Loading','순위 불러오는 중…',14,C.muted,16,6,cw-32,44);y+=64;return
        elseif #rows==0 and state=='failed'then
            local p=card('BoardFailed',56);text(p,'Failed','순위를 불러오지 못했어요',14,C.muted,16,6,cw-160,44)
            action(p,'BoardRetry','새로 고침',function()ask(lobby,'read')end,false,cw-132,6,120,44);y+=64;return
        end
        if #rows==0 then
            local p=card('BoardEmpty',56);text(p,'Empty',emptyText,14,C.muted,16,6,cw-32,44);y+=64;return
        end
        for _,r in ipairs(rows)do
            local isMine=mine==r.id
            local row=UI.panel(body,'Board_'..r.rank..'_'..r.id);row.BackgroundTransparency=isMine and .05 or .25;UI.box(row,2,y,cw,56)
            if isMine then row:FindFirstChildOfClass('UIStroke').Color=V.color(r.color)end;V.hover(row)
            V.rank(row,r.rank,10,14,28)
            local e=V.emblem(row,'Emblem',r.tag,r.color,44);UI.box(e,46,6,44,44)
            local right=compact and 96 or 220;local joinW=joinable and 84 or 0
            local nm=one(skip(UI.label(row,'Name',r.name,16,C.ink)));UI.box(nm,98,7,cw-98-right-joinW-8,24)
            local sub=kind=='war'and string.format('[%s]  Lv %d  %d승 %d패',r.tag,r.level,r.wins or 0,r.losses or 0)or string.format('[%s]  Lv %d  %d/%d명',r.tag,r.level,r.count or 0,Rules.maxMembers)
            local sl=one(skip(UI.label(row,'Sub',sub,12,C.muted)));UI.box(sl,98,30,cw-98-right-joinW-8,20)
            local valueText=kind=='war'and string.format('%s점',UI.number(r.value))or UI.number(r.value)
            local v=skip(UI.label(row,'Value',valueText,compact and 16 or 20,M.valueColor(r.rank)));v.TextXAlignment=Enum.TextXAlignment.Right;UI.display(v);UI.box(v,cw-right-joinW-10,8,right,26)
            local cap=UI.label(row,'ValueCap',kind=='war'and '클랜전 점수'or '누적 기여',11,C.muted);cap.TextXAlignment=Enum.TextXAlignment.Right;UI.box(cap,cw-right-joinW-10,32,right,16)
            if joinable then
                local full=(r.count or 0)>=Rules.maxMembers
                local j=action(row,'JoinClan',full and '정원 마감'or '가입',function()ask(lobby,'joinId',r.id)end,true,cw-joinW-8,10,joinW,36)
                j.TextSize=14;if full or not joinable.prime then UI.enabled(j,false)end
            end
            y+=62
        end
    end
    local v=lobby.unitView
    if not v then
        local p=card('StatusCard',64,C.muted)
        if lobby.unitReadFailed and not lobby.unitBusy then
            text(p,'Failed','클랜 정보 불러오기 실패',14,C.muted,16,10,cw-32,44)
            y+=72;action(body,'Retry','다시 불러오기',function()lobby.unitReadFailed=false;ask(lobby,'read')end,true,2,y,cw);y+=52
        else
            text(p,'Loading','클랜 정보 불러오는 중…',14,C.muted,16,10,cw-32,44)
            if not lobby.unitBusy then ask(lobby,'read')end;y+=72
        end
        body.CanvasSize=UDim2.fromOffset(0,y);return
    end
    if not lobby.clanSeen then lobby.clanSeen=true;step('clanOpened',v.unit and 'member'or 'guest')end
    local u=v.unit
    if u and lobby.clanMark and u.isLeader then
        lobby.pageTitle.Text='클랜 마크 꾸미기'
        local back=action(body,'MarkBack','‹  클랜으로',function()lobby.clanMark=nil;body.CanvasPosition=Vector2.zero;lobby:drawPage()end,false,2,y,compact and 132 or 150);y+=56
        local bh=compact and 150 or 200
        local banner=V.banner(body,'MarkBanner',u.color);UI.box(banner,2,y,cw,bh)
        local es=compact and 112 or 152
        local emblem=V.emblem(banner,'MarkPreview',u.tag,u.color,es);UI.box(emblem,(cw-es)/2,(bh-es)/2,es,es)
        y+=bh+12
        local head=UI.label(body,'MarkHead','엠블럼 색',16,C.ink);UI.box(head,4,y,200,24);y+=30
        M.swatches(body,u.color,function(i)if i~=u.color then step('clanMarkColor',tostring(i));ask(lobby,'color',i)end end,2,y,cw,48);y+=60
        local hint=UI.label(body,'MarkHint','클랜장만 바꿀 수 있어요. 고르면 모든 클랜원에게 바로 보여요',13,C.muted);hint.TextWrapped=true;UI.box(hint,4,y,cw-8,40);y+=48
        body.CanvasSize=UDim2.fromOffset(0,y);return
    end
    lobby.clanMark=nil
    if u then
        local bh=compact and 196 or 176
        local banner=V.banner(body,'ClanBanner',u.color);UI.box(banner,2,y,cw,bh)
        local es=compact and 84 or 120
        local emblem=V.emblem(banner,'ClanEmblem',u.tag,u.color,es);UI.box(emblem,compact and 12 or 22,compact and 14 or (bh-es)/2,es,es)
        local lv=UI.pill(banner,'ClanLevel',string.format('Lv %d',u.level),V.color(u.color));UI.display(lv);lv.TextSize=14
        UI.box(lv,(compact and 12 or 22)+es/2-30,(compact and 14 or (bh-es)/2)+es-8,60,22);lv.ZIndex=3
        local tx=(compact and 12 or 22)+es+(compact and 12 or 22)
        local tw=cw-tx-16
        local markW=u.isLeader and (compact and 112 or 150)or 0
        local name=one(skip(UI.label(banner,'ClanName',u.name,compact and 22 or 30,C.ink)));UI.display(name);UI.box(name,tx,compact and 12 or 18,tw-(markW>0 and markW+8 or 0),compact and 30 or 38)
        if u.isLeader then
            local mark=action(banner,'ClanMark',compact and '마크 꾸미기'or '클랜 마크 꾸미기',function()lobby.clanMark=true;step('clanMarkOpened');body.CanvasPosition=Vector2.zero;lobby:drawPage()end,false,cw-markW-12,compact and 8 or 14,markW,44)
            mark.TextSize=compact and 13 or 14;mark.ZIndex=4
        end
        local info=string.format('[%s]  클랜원 %d/%d  기여 %s  클랜전 %s',u.tag,u.count,v.maxMembers,u.rank and string.format('%d위',u.rank)or '순위 밖',u.war.rank and string.format('%d위',u.war.rank)or '순위 밖')
        local il=skip(UI.label(banner,'ClanInfo',info,13,C.muted));il.TextWrapped=true;UI.box(il,tx,compact and 44 or 58,compact and markW>0 and tw-markW-8 or tw,compact and 36 or 20)
        local frac=u.levelCost and math.clamp(u.levelXp/u.levelCost,0,1)or 1
        local key=u.id..':'..u.level..':'..u.levelXp;local from=lobby.clanBarKey~=key and (lobby.clanBarFrom or 0)or nil;lobby.clanBarKey=key;lobby.clanBarFrom=frac
        local by=compact and 92 or 92
        local barText=u.levelCost and string.format('다음 레벨까지 %s / %s',UI.number(u.levelXp),UI.number(u.levelCost))or '최고 레벨 달성'
        local bl=skip(UI.label(banner,'LevelText',barText,12,C.ink));UI.box(bl,tx,by,tw,18)
        local bar=V.bar(banner,'LevelBar',frac,V.color(u.color),from);UI.box(bar,tx,by+20,tw,12)
        local total=skip(UI.label(banner,'ClanXp',string.format('누적 기여 %s',UI.number(u.xp)),12,C.muted));UI.box(total,tx,by+36,tw*.6,18)
        local code=skip(UI.make('TextLabel',banner,{Name='ClanCode',Text='CODE  '..u.code,TextSize=14,TextColor3=C.accent,Font=Enum.Font.BuilderSansBold,BackgroundColor3=C.bg,BackgroundTransparency=.2,BorderSizePixel=0,TextXAlignment=Enum.TextXAlignment.Center}))
        UI.display(code,true);UI.corner(code,3);UI.stroke(code,C.accent,1);UI.box(code,cw-146-12,bh-36,146,26)
        y+=bh+10
        local a=v.attend
        local strip=card('AttendStrip',compact and 150 or 96,C.gold)
        local ic=Icons.create(strip,'daily',22,C.gold);ic.Name='AttendIcon';UI.box(ic,16,14,22,22)
        local head=UI.label(strip,'AttendHead','오늘의 출석',16,C.ink);UI.box(head,46,10,200,28)
        local doneCount=(a.free and 1 or 0)+a.extra
        for i=1,1+a.extraMax do
            local on=i<=doneCount
            local pip=UI.make('Frame',strip,{Name='Pip'..i,Rotation=45,BackgroundColor3=on and (i==1 and C.accent or C.gold)or C.bg,BorderSizePixel=0})
            UI.corner(pip,2);UI.stroke(pip,i==1 and C.accent or C.gold,1);UI.box(pip,46+(i-1)*20,46,11,11)
        end
        local mineText=string.format('내 기여 %s  클랜전 %s',UI.number(a.total),UI.number(a.warTotal))
        local ml=skip(UI.label(strip,'MyContribution',mineText,12,C.muted));UI.box(ml,46+(1+a.extraMax)*20+6,40,compact and cw-200 or 260,22)
        local bw=compact and cw-28 or 300;local bx=compact and 14 or cw-14-bw;local byy=compact and 74 or 26
        local left=a.extraMax-a.extra;local price=v.product and v.product.price
        local stage=not a.free and 'free'or left>0 and 'extra'or 'done'
        local label=stage=='free'and '출석 체크'or stage=='done'and '출석 완료'
            or a.tokens>0 and string.format('추가 출석 체크  보관 %d (%d/%d)',a.tokens,left,a.extraMax)
            or v.product and v.product.studio and string.format('추가 출석 체크  Studio 무료 (%d/%d)',left,a.extraMax)
            or string.format('추가 출석 체크  %s Robux (%d/%d)',price and tostring(price)or '—',left,a.extraMax)
        local attendB=action(strip,stage=='free'and 'AttendFree'or 'AttendExtra',label,function()ask(lobby,'attend',stage=='free'and 'free'or 'extra')end,stage=='free',bx,byy,bw,44)
        if stage=='extra'then attendB.TextColor3=C.gold;local es2=attendB:FindFirstChildOfClass('UIStroke');if es2 then es2.Color=C.gold;es2.Transparency=.3 end end
        if stage=='done'then UI.enabled(attendB,false)end
        if stage=='extra'and a.tokens==0 and v.product and not v.product.studio then local live=v.product.available==true;pcall(Telemetry.offerSeen,'clanAttend','clanStrip',live and 'shown'or 'unavailable',live and 'none'or 'sales_disabled')end
        local hint=UI.label(strip,'AttendHint',string.format('무료 하루 1번, Robux로 %d번 더, 1번에 기여 +%d',a.extraMax,a.amount),11,C.muted)
        UI.box(hint,compact and 14 or 46,compact and 124 or 66,compact and cw-28 or 300,18)
        if lobby.clanGain and os.clock()-lobby.clanGain<.6 then lobby.clanGain=nil;V.float(strip,'+'..a.amount,bx+20,byy-6,C.gold)end
        y+=(compact and 150 or 96)+10
        lobby.clanTab=lobby.clanTab or 'members'
        tabs({{'members','클랜원','friends'},{'board','클랜 순위','ranked'},{'war','클랜전','medal'}},lobby.clanTab,function(t)lobby.clanTab=t end)
        if lobby.clanTab=='members'then
            if not compact then
                local hdr=UI.make('Frame',body,{Name='MemberHeader',BackgroundTransparency=1});UI.box(hdr,2,y,cw,20)
                local cols={{'지휘관',62,200,0},{'이번 주',cw-330,90,1},{'누적 기여',cw-232,100,1},{'오늘',cw-124,60,2}}
                for _,c in ipairs(cols)do local l=UI.label(hdr,'Col_'..c[1],c[1],11,C.muted);UI.box(l,c[2],0,c[3],20);l.TextXAlignment=c[4]==1 and Enum.TextXAlignment.Right or c[4]==2 and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left end
                y+=22
            end
            for i,m in ipairs(u.members)do
                local mine=m.userId==Me.UserId
                local line=UI.panel(body,'Member'..m.userId);line.BackgroundTransparency=mine and .05 or .25;UI.box(line,2,y,cw,56)
                if mine then line:FindFirstChildOfClass('UIStroke').Color=C.accent end;V.hover(line)
                local n=skip(UI.label(line,'Order',tostring(i),13,C.muted));n.TextXAlignment=Enum.TextXAlignment.Center;UI.box(n,4,18,20,20)
                local face=UI.make('ImageLabel',line,{Name='Avatar',BackgroundColor3=C.bg,BorderSizePixel=0,Image='rbxthumb://type=AvatarHeadShot&id='..m.userId..'&w=150&h=150'});UI.corner(face,40);UI.box(face,26,10,36,36)
                UI.stroke(face,m.leader and C.gold or C.line,m.leader and 2 or 1)
                local dot=UI.make('Frame',line,{Name='Online',BackgroundColor3=m.online and C.good or C.muted,BorderSizePixel=0});UI.corner(dot,40);UI.box(dot,52,36,10,10);UI.stroke(dot,C.panel,2)
                local nameW=compact and cw-72-90 or cw-330-72-8
                local l=one(skip(UI.label(line,'Name',m.name,15,mine and C.accent or C.ink)));UI.box(l,72,m.leader and 6 or 10,nameW,22)
                if m.leader then local crown=UI.pill(line,'Leader','★ 클랜장',C.gold);UI.box(crown,72,30,62,18);crown.TextSize=11
                elseif not compact then local s=UI.label(line,'Role','클랜원',11,C.muted);UI.box(s,72,32,80,16)end
                if compact then
                    local stats=skip(UI.label(line,'Stats',string.format('이번 주 %s  누적 %s',UI.number(m.week),UI.number(m.total)),12,C.muted));UI.box(stats,m.leader and 140 or 72,30,cw-72-100,18)
                    local today=UI.pill(line,'Today',m.today and '출석'or '미출석',m.today and C.accent or C.raised);UI.box(today,cw-62,18,52,20)
                else
                    local wk=skip(UI.label(line,'Week',UI.number(m.week),17,m.week>0 and C.gold or C.muted));wk.TextXAlignment=Enum.TextXAlignment.Right;UI.display(wk);UI.box(wk,cw-330,16,90,24)
                    local tt=skip(UI.label(line,'Total',UI.number(m.total),15,C.ink));tt.TextXAlignment=Enum.TextXAlignment.Right;UI.box(tt,cw-232,16,100,24)
                    local today=UI.pill(line,'Today',m.today and '✓ 출석'or '—',m.today and C.accent or C.raised);UI.box(today,cw-124,18,60,20)
                end
                if u.isLeader and not m.leader then
                    local armed=lobby.clanArmed
                    local kx=compact and cw-62-8 or cw-56
                    if not compact then
                        local menu=UI.button(line,'MemberMenu','⋯',function()lobby.clanArmed=armed~=m.userId and m.userId or nil;lobby:drawPage()end);UI.box(menu,cw-52,12,42,32);menu.TextSize=18;UI.enabled(menu,not lobby.unitBusy)
                    end
                    if armed==m.userId then
                        local pr=UI.button(line,'Promote','클랜장 위임',function()lobby.clanArmed=nil;require(script.Parent.LobbyConfirm).open(lobby,'클랜장 위임','클랜장을 넘기면 되돌릴 수 없어요. 이 클랜원에게 넘길까요?','넘기기',function()lobby:openPage('clan');ask(lobby,'promote',m.userId)end)end);UI.box(pr,kx-200,12,96,32);pr.TextSize=12;UI.enabled(pr,not lobby.unitBusy)
                        local k=UI.button(line,'Kick','내보내기',function()lobby.clanArmed=nil;require(script.Parent.LobbyConfirm).open(lobby,'내보내기','내보낸 클랜원은 7일 동안 다시 가입할 수 없어요. 내보낼까요?','내보내기',function()lobby:openPage('clan');ask(lobby,'kick',m.userId)end)end);UI.box(k,kx-98,12,90,32);k.TextSize=12;k.TextColor3=C.danger;UI.enabled(k,not lobby.unitBusy)
                    elseif compact then
                        local menu=UI.button(line,'MemberMenu','⋯',function()lobby.clanArmed=m.userId;lobby:drawPage()end);UI.box(menu,cw-62-48,12,40,32);menu.TextSize=18;UI.enabled(menu,not lobby.unitBusy)
                    end
                end
                y+=62
            end
            local hint=UI.label(body,'MembersHint','이번 주 기여 순. 기여는 출석과 클랜전으로 쌓여요. 코드로 클랜원 초대',12,C.muted);UI.box(hint,4,y,cw-8,20);y+=28
        elseif lobby.clanTab=='board'then
            local head=UI.label(body,'BoardHead','출석과 클랜전으로 쌓은 클랜 기여 순위',13,C.muted);UI.box(head,4,y,cw-8,20);y+=26
            boardRows(v.top or {},u.id,'xp','아직 기록 없음. 오늘 출석으로 첫 기여를 쌓아 보세요')
        else
            M.warCard(lobby,body,v,u,cw,compact,function(dy)y+=dy end,function()return y end,card,text,action)
            boardRows(v.war.top or {},u.id,'war','이번 달 클랜전 기록 없음')
        end
        y+=6
        local leave=action(body,'LeaveClan',u.isLeader and u.count>1 and '클랜 나가기, 최고참이 클랜장 승계'or '클랜 나가기',function()
            if lobby.clanLeaveArmed then lobby.clanLeaveArmed=nil;ask(lobby,'leave')else lobby.clanLeaveArmed=true;lobby:drawPage()end
        end,false,2,y,cw)
        if lobby.clanLeaveArmed then leave.Text='한 번 더 누르면 클랜을 나가요'end
        leave.TextColor3=C.danger;local ls=leave:FindFirstChildOfClass('UIStroke');if ls then ls.Color=C.danger;ls.Transparency=.4 end;y+=52
    else
        local bh=compact and 176 or 166
        local banner=V.banner(body,'ClanPitch',7);UI.box(banner,2,y,cw,bh)
        local es=compact and 72 or 104
        local e=V.emblem(banner,'PitchEmblem','CLAN',7,es);UI.box(e,compact and 12 or 22,compact and 14 or (bh-es)/2,es,es)
        local tx=(compact and 12 or 22)+es+(compact and 12 or 22);local tw=cw-tx-16
        local t=UI.label(banner,'PitchTitle','클랜',compact and 24 or 30,C.ink);UI.display(t);UI.box(t,tx,compact and 10 or 16,tw,34)
        local s=UI.label(banner,'PitchLine','최대 100명, 매일 출석으로 클랜 레벨 1~100, 매달 클랜전 순위',13,C.muted);UI.box(s,tx,compact and 44 or 52,tw,compact and 36 or 20)
        local by=compact and 92 or 84
        if v.prime then
            local okPill=UI.pill(banner,'PrimeOwned','✓ 커맨더 프라임, 클랜을 만들거나 가입할 수 있어요',C.gold);UI.box(okPill,tx,by,math.min(tw,330),24);okPill.TextSize=12
        else
            local lock=Icons.create(banner,'lock',14,C.gold);lock.Name='PrimeLock';UI.box(lock,tx,by+5,14,14)
            local need=UI.label(banner,'PrimeNeed','커맨더 프라임 보유자만 클랜을 만들고 가입할 수 있어요',13,C.gold);UI.box(need,tx+20,by,tw-20,24)
            local go=action(banner,'ViewPrime','커맨더 프라임 보기',function()step('clanPrimeView');lobby:openPage('benefits')end,true,tx,by+30,math.min(tw,220),48)
        end
        y+=bh+10
        lobby.clanGuestTab=lobby.clanGuestTab or 'find'
        tabs({{'find','클랜 찾기','clan'},{'create','클랜 만들기','reward'},{'war','클랜전 순위','medal'}},lobby.clanGuestTab,function(t)lobby.clanGuestTab=t end)
        local d=lobby.unitDraft or {};lobby.unitDraft=d
        if lobby.clanGuestTab=='find'then
            local join=card('JoinCard',64,C.accent)
            local code=input(join,'JoinCode','초대 코드 6자리',d.code,14,10,cw-28-130-8,true);code:GetPropertyChangedSignal('Text'):Connect(function()d.code=code.Text end)
            local jb=action(join,'JoinByCode','코드로 가입',function()ask(lobby,'join',code.Text)end,true,cw-14-130,8,130,48)
            if not v.prime then UI.enabled(jb,false)end
            y+=72
            local head=UI.label(body,'FindHead','기여 상위 클랜, 바로 가입할 수 있어요',13,C.muted);UI.box(head,4,y,cw-8,20);y+=26
            boardRows(v.top or {},nil,'xp','아직 클랜이 없어요. 첫 클랜을 만들어 보세요',{prime=v.prime})
        elseif lobby.clanGuestTab=='create'then
            local h=compact and 330 or 250
            local create=card('CreateCard',h,C.gold)
            d.color=Rules.validColor(d.color)or 1
            local preview=V.emblem(create,'CreatePreview',d.tag and d.tag~=''and string.upper(d.tag)or '',d.color,compact and 72 or 120)
            local px=compact and 14 or 18;UI.box(preview,px,compact and 14 or 22,compact and 72 or 120,compact and 72 or 120)
            local fx=compact and 14 or 160;local fy=compact and 98 or 18;local fw=cw-fx-14
            local pname=one(skip(UI.label(create,'NamePreview','',compact and 18 or 22,C.ink)));UI.display(pname);UI.box(pname,compact and 98 or fx,compact and 30 or fy,compact and cw-112 or fw,30)
            local function refresh()pname.Text=d.name and d.name~=''and d.name or '클랜 이름';pname.TextColor3=d.name and d.name~=''and C.ink or C.muted end
            local nameY=compact and fy or fy+38
            local name=input(create,'ClanNameInput','클랜 이름 (2~16자)',d.name,fx,nameY,fw)
            local tagBox=input(create,'ClanTagInput','약칭 (2~4자)',d.tag,fx,nameY+52,compact and fw or 150,true)
            name:GetPropertyChangedSignal('Text'):Connect(function()d.name=name.Text;refresh()end)
            tagBox:GetPropertyChangedSignal('Text'):Connect(function()d.tag=tagBox.Text
                local t2=preview:FindFirstChild('Tag');if t2 then t2.Text=d.tag~=''and string.upper(d.tag)or '····'end end)
            refresh()
            local swy=compact and nameY+104 or nameY+52;local swx=compact and fx or fx+160
            M.swatches(create,d.color,function(i)d.color=i;lobby:drawPage()end,swx,swy,compact and fw or fw-160)
            local make=action(create,'CreateClan',v.prime and '클랜 만들기'or '커맨더 프라임 보유자만 만들 수 있어요',function()if v.prime then ask(lobby,'create',name.Text,tagBox.Text,d.color)end end,v.prime,fx,h-58,fw)
            if not v.prime then UI.enabled(make,false)end
            y+=h+8
            local hint=UI.label(body,'CreateHint','이름과 약칭은 모두에게 보여요. 클랜장이 클랜 마크를 꾸밀 수 있어요',12,C.muted);UI.box(hint,4,y,cw-8,20);y+=28
        else
            M.warCard(lobby,body,v,nil,cw,compact,function(dy)y+=dy end,function()return y end,card,text,action)
            boardRows(v.war.top or {},nil,'war','이번 달 클랜전 기록 없음')
        end
    end
    if v.studio then
        y+=6
        local t=UI.label(body,'DevTitle','DEV: Studio 전용, 정지하면 초기화',12,C.gold);UI.box(t,4,y,cw-8,20);y+=24
        local list={{'xp','기여 +5,000'},{'reset','출석 초기화'},{'war','클랜전 승'},{'warLoss','클랜전 패'}}
        local bw=(cw-18)/4
        for i,b in ipairs(list)do
            local btn=UI.button(body,'ClanDev_'..b[1],b[2],function()if b[1]=='warLoss'then ask(lobby,'dev','war','loss')else ask(lobby,'dev',b[1])end end)
            UI.box(btn,2+(i-1)*(bw+6),y,bw,36);btn.TextSize=12;UI.enabled(btn,not lobby.unitBusy)
        end
        y+=44
    end
    y+=4;action(body,'RefreshClan','새로 고침',function()ask(lobby,'read')end,false,2,y,cw,48);y+=56
    body.CanvasSize=UDim2.fromOffset(0,y+8)
end
function M.valueColor(rank)return V.medals[rank]or C.accent end
function M.swatches(parent,current,pick,x,y,width,max)
    local n=#Rules.colors;local size=math.min(max or 36,(width-(n-1)*8)/n)
    for i=1,n do
        local col=V.color(i)
        local b=UI.make('TextButton',parent,{Name='Swatch'..i,Text='',AutoButtonColor=true,BackgroundTransparency=1})
        UI.box(b,x+(i-1)*(size+8),y,size,size)
        local dmd=UI.make('Frame',b,{Name='Diamond',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(size*.62,size*.62),Rotation=45,BackgroundColor3=col,BorderSizePixel=0,Active=false})
        UI.corner(dmd,2);local s=UI.stroke(dmd,i==current and C.ink or col:Lerp(Color3.new(0,0,0),.3),i==current and 2 or 1)
        b.Activated:Connect(function()pick(i)end)
    end
end
function M.warCard(lobby,body,v,u,cw,compact,advance,getY,card,text,action)
    local war=v.war
    local h=compact and 190 or 150
    local p=card('ClanWarCard',h,C.danger)
    local ic=Icons.create(p,'medal',22,C.danger);ic.Name='WarIcon';UI.box(ic,16,14,22,22)
    local head=UI.label(p,'WarHead',(war.n or 0)==0 and '프리시즌 클랜전'or string.format('시즌 %d 클랜전',war.n),18,C.ink);UI.display(head);UI.box(head,46,10,220,28)
    local left=skip(UI.label(p,'WarLeft',string.format('초기화까지 %s',V.time(war.remaining or 0)),12,C.muted));UI.box(left,46,36,240,18)
    if u then
        local rec=skip(UI.label(p,'WarRecord',string.format('%s점  %d승 %d패  %s',UI.number(u.war.points),u.war.wins,u.war.losses,u.war.rank and string.format('%d위',u.war.rank)or '순위 밖'),compact and 16 or 20,C.ink))
        UI.display(rec);rec.TextXAlignment=compact and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right;UI.box(rec,compact and 16 or cw-16-340,compact and 60 or 14,340,28)
    end
    local rules=string.format('같은 클랜 2명 파티 대 다른 클랜 2명, 원작 규칙. 승리 +%d점, 기여 +%d (각자 개인 기여에도 기록). 패배 %d점, 기여 없음',war.winPoints,war.winContribution,war.lossPoints)
    local rl=UI.label(p,'WarRules',rules,12,C.muted);rl.TextWrapped=true;UI.box(rl,16,compact and 92 or 60,cw-32,compact and 40 or 36)
    local queue=lobby.clanWarQueue
    local label=not u and '클랜에 가입하면 참가할 수 있어요'or queue and '클랜원 1명과 클랜전 찾기'or '클랜전은 랭크전과 함께 열려요'
    local b=action(p,'FindClanWar',label,function()if queue and u then step('clanWarQueue');queue(lobby)end end,u~=nil and queue~=nil,16,h-56,cw-32)
    if not(u and queue)then UI.enabled(b,false)end
    advance(h+8)
end
return M
