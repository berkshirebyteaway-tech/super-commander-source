local UI=require(script.Parent.Theme)
local Style=require(script.Parent.HudStyle)
local Icons=require(script.Parent.OutgameIcons)
local Rules=require(script.Parent.Parent.Core.MatchRulesSummary)
local Step=require(script.Parent.TelemetryStep)
local C=UI.colors
local M={}
local function tracked(id,fn)return fn and function(...)Step.step('match','menuTile',{item=id});return fn(...)end end
local function touch()return require(script.Parent.InputMode).touch()end
local function chipLabel(parent,text,x)
    local t=UI.label(parent,'Chip',text,13,C.ink);t.TextXAlignment=Enum.TextXAlignment.Center;t.TextWrapped=false;t.Font=Enum.Font.BuilderSansBold
    t.BackgroundColor3=Style.colors.cell;t.BackgroundTransparency=0;Style.round(t,10);t.ZIndex=parent.ZIndex+2
    local cw=math.max(48,t.TextBounds.X+18);t.AnchorPoint=Vector2.new(1,.5);t.Position=UDim2.new(1,-(x or 10),.5,0);t.Size=UDim2.fromOffset(cw,24);return t
end
local function danger(b)
    b.TextColor3=C.danger;b.BackgroundColor3=C.danger:Lerp(Style.colors.panel,.86);Style.round(b,8);Style.line(b,C.danger,1.5)
end
local function primary(b)b.TextSize=18;Style.round(b,8)end
function M.draw(ctx)
    local body,s,a=ctx.body,ctx.state,ctx.act
    local w=math.max(240,ctx.width)-14;local y=0;local t=touch();local compact=ctx.compact==true
    if not compact then local d=UI.label(body,'Description',s.multiplayer and '메뉴를 열어도 경기는 계속돼요'or '메뉴를 열면 경기가 잠시 멈춰요',13,C.muted);UI.box(d,4,y,w,22);y+=30 end
    local resume=UI.button(body,'Resume','계속 플레이',tracked('Resume',a.resume),true);UI.box(resume,4,y,w,compact and 48 or t and 52 or 56);primary(resume);y+=resume.Size.Y.Offset+(compact and 8 or 12)
    local tiles={
        {'Guide','플레이 방법','missions',a.guide},
        {'Settings','설정','settings',a.settings},
        {'Ranks','순위','ranked',a.ranks},
        {'Diplomacy','외교','friends',a.diplomacy,(ctx.inboxCount or 0)>0 and string.format('요청 %d',ctx.inboxCount)or nil},
        {'World','전체 지도','fields',a.world},
        {'Home','내 지휘관으로','deploy',a.home},
        {'Affiliation','소속 보기','marshal',a.affiliation,ctx.altView and '켜짐'or '꺼짐'},
    }
    if s.multiplayer and s.canPause then table.insert(tiles,{'HostPause',s.paused and '모두 재개'or '모두 일시정지','daily',a.hostPause,'방장'})end
    local cols=compact and (ctx.width>=560 and 4 or 3)or t and ctx.width>=520 and 3 or 2;local gap=8;local tw=(w-gap*(cols-1))/cols;local th=48
    for i,tile in ipairs(tiles)do
        local b=UI.button(body,tile[1],tile[2],tracked(tile[1],tile[4]));local col=(i-1)%cols;local row=(i-1)//cols
        UI.box(b,4+col*(tw+gap),y+row*(th+gap),tw,th);b.TextSize=compact and 13 or 14;b.TextXAlignment=Enum.TextXAlignment.Left
        b.BackgroundColor3=Style.colors.chip;Style.round(b,8);Style.line(b,Style.colors.line,1)
        local pl=compact and 38 or 44;UI.make('UIPadding',b,{PaddingLeft=UDim.new(0,pl),PaddingRight=UDim.new(0,tile[5]and (compact and 52 or 72)or 8)})
        local icon=Icons.create(b,tile[3],20,C.ink);UI.box(icon,12-pl,(th-20)/2,20,20)
        b.TextTruncate=Enum.TextTruncate.AtEnd;b.TextWrapped=false
        if tile[5]then local inset=compact and 46 or 62;local chip=chipLabel(b,tile[5],-inset);chip.Position=UDim2.new(1,inset,.5,0);if compact then chip.Size=UDim2.fromOffset(40,24)end end
    end
    y+=math.ceil(#tiles/cols)*(th+gap)+4
    local lines=Rules.lines(s.settings)
    local rules=UI.button(body,'RulesToggle',#lines>0 and string.format(ctx.rulesOpen and '이번 판 규칙 %d개 접기'or '이번 판 규칙 %d개 ›',#lines)or (ctx.rulesOpen and '이번 판 규칙 클래식 접기'or '이번 판 규칙 클래식 ›'),tracked('RulesToggle',a.toggleRules));UI.box(rules,4,y,compact and w/2-8 or w,48)
    rules.BackgroundTransparency=1;rules.TextXAlignment=Enum.TextXAlignment.Left;rules.TextSize=14;rules.TextColor3=C.muted;rules.TextTruncate=Enum.TextTruncate.AtEnd
    local edge=rules:FindFirstChildOfClass('UIStroke');if edge then edge.Enabled=false end
    local leave=UI.button(body,'Leave','로비로 나가기',tracked('Leave',a.leave));danger(leave)
    if compact then UI.box(leave,w/2+4,y,w/2,48);y+=56 else y+=52 end
    if ctx.rulesOpen then
        local l=UI.label(body,'Rules',#lines>0 and table.concat(lines,'\n')or '클래식 규칙',13,C.muted);UI.box(l,8,y,w-8,math.max(1,#lines)*20+4);l.TextYAlignment=Enum.TextYAlignment.Top
        y+=math.max(1,#lines)*20+12
    end
    if not compact then
        local rule=UI.make('Frame',body,{Name='ExitRule',BackgroundColor3=C.line,BorderSizePixel=0});UI.box(rule,4,y,w,1);y+=13
        UI.box(leave,4,y,w,48);y+=56
    end
    body.CanvasSize=UDim2.fromOffset(0,y);return y
end
function M.confirm(body,width,text,safe,safeFn,risky,riskyFn,names)
    local w=math.max(240,width)-14
    local d=UI.label(body,'Description',text,14,C.muted);d.TextYAlignment=Enum.TextYAlignment.Top;UI.box(d,4,0,w,64)
    local bw=(w-10)/2;local bh=touch()and 52 or 48
    local a=UI.button(body,names and names[1]or 'Cancel',safe,safeFn,true);UI.box(a,4,76,bw,bh);Style.round(a,8)
    local b=UI.button(body,names and names[2]or 'Confirm',risky,riskyFn);UI.box(b,14+bw,76,bw,bh);danger(b)
    body.CanvasSize=UDim2.fromOffset(0,76+bh+4);return 76+bh+4
end
function M.settings(ctx)
    local body=ctx.body;local w=math.max(260,ctx.width)-14;local y=0;local shop=ctx.shop;local prefs=ctx.prefs or {}
    local busy=not ctx.ready or shop and shop.busy
    local function section(text)local l=UI.label(body,'Section'..y,text,13,require(script.Parent.MatchSheet).SKY);l.Font=Enum.Font.BuilderSansBold;UI.box(l,4,y,w,24);y+=28 end
    local function line()local r=UI.make('Frame',body,{Name='Rule'..y,BackgroundColor3=Style.colors.line,BorderSizePixel=0});UI.box(r,4,y-5,w,1)end
    local function toggle(key,title,hint,on,fn)
        local h=hint and 52 or 44
        local l=UI.label(body,key..'Title',title,15,C.ink);l.Font=Enum.Font.BuilderSansBold;UI.box(l,4,y+(hint and 4 or 0),w-80,hint and 22 or h)
        if hint then local s=UI.label(body,key..'Hint',hint,13,C.muted);UI.box(s,4,y+26,w-80,20)end
        local b=UI.button(body,'Toggle_'..key,'',fn);UI.box(b,w-64,y+(h-48)/2,68,48);b.BackgroundTransparency=1;local st=b:FindFirstChildOfClass('UIStroke');if st then st.Enabled=false end
        local track=UI.make('Frame',b,{Name='Track',BackgroundColor3=on and C.accent or Style.colors.cell,BorderSizePixel=0,ZIndex=b.ZIndex+1});UI.box(track,10,12,48,24);Style.round(track,12);Style.line(track,on and C.accent or Style.colors.line,1)
        local knob=UI.make('Frame',track,{Name='Knob',BackgroundColor3=on and C.bg or C.muted,BorderSizePixel=0,ZIndex=b.ZIndex+2});UI.box(knob,on and 28 or 4,4,16,16);Style.round(knob,8)
        b:SetAttribute('On',on==true);UI.enabled(b,not busy or key=='players');y+=h+10;line()
    end
    local function segmented(key,title,items,current,fn)
        local l=UI.label(body,key..'Title',title,15,C.ink);l.Font=Enum.Font.BuilderSansBold;UI.box(l,4,y,w*.35,44)
        local narrow=w<#items*72+120;if narrow then y+=44 end
        local sw=narrow and w or math.min(w*.62,#items*86);local seg=UI.make('Frame',body,{Name=key,BackgroundColor3=Style.colors.chip,BorderSizePixel=0});UI.box(seg,w-sw+4,y-4,sw,52);Style.round(seg,8);Style.line(seg,Style.colors.line,1)
        for i,it in ipairs(items)do
            local on=current==it[1]
            local b=UI.button(seg,key..'_'..tostring(it[1]),it[2],function()fn(it[1])end);UI.box(b,2+(i-1)*(sw-4)/#items,2,math.floor((sw-4)/#items-2),48);b.TextSize=14;Style.round(b,6)
            b.BackgroundColor3=on and Style.colors.cell:Lerp(C.ink,.14)or Style.colors.chip;b.BackgroundTransparency=on and 0 or 1;b.TextColor3=on and C.ink or C.muted
            local st=b:FindFirstChildOfClass('UIStroke');if st then st.Enabled=false end;if key~='Language'then UI.enabled(b,not busy)end
        end
        y+=60;line()
    end
    local function pref(key,value)if shop then shop:run(function()shop:request('preference',key,value)end)end end
    section('화면')
    toggle('reducedEffects','간소한 이펙트','폭발과 연기를 줄여요',prefs.reducedEffects==true,function()pref('reducedEffects',not prefs.reducedEffects)end)
    toggle('cameraShake','화면 흔들림',nil,prefs.cameraShake~=false,function()pref('cameraShake',prefs.cameraShake==false)end)
    toggle('mapFlashes','지도 번쩍임','핵이나 폭발 때 화면이 밝아져요',prefs.mapFlashes~=false,function()pref('mapFlashes',prefs.mapFlashes==false)end)
    section('소리와 언어')
    local volume=prefs.soundsMuted and 'off'or prefs.sfxVolume or 1
    segmented('SoundVolume','효과음',{{'off','끔'},{.5,'작게'},{1,'보통'},{1.5,'크게'}},volume,function(v)
        if not shop or v==volume then return end
        shop:run(function()
            if v=='off'then shop:request('preference','soundsMuted',true);return end
            shop:request('preference','sfxVolume',v)
            if ctx.play then ctx.play('confirm')end
        end)
    end)
    segmented('Language','언어',{{'auto','자동'},{'ko-kr','한국어'},{'en-us','English'}},ctx.language or 'auto',function(v)ctx.setLanguage(v)end)
    if not ctx.lobby then
        local ok,on=pcall(function()return game.StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)end)
        toggle('players','Roblox 접속자 목록','Roblox 기본 목록을 보여요',ok and on,function()
            pcall(function()game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,not game.StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList))end)
            Step.step('settings','playerList',{});if ctx.redraw then ctx.redraw()end
        end)
    else
        local credits=UI.button(body,'Credits','크레딧과 라이선스',ctx.credits);UI.box(credits,4,y,w,48);credits.BackgroundColor3=Style.colors.chip;Style.round(credits,8);y+=56
    end
    body.CanvasSize=UDim2.fromOffset(0,y);return y
end
M.helpTabs={{'basic','기본'},{'build','건설과 바다'},{'controls','조작'},{'buildings','건물 도감'}}
function M.help(ctx)
    local body=ctx.body;local w=math.max(260,ctx.width)-14;local y=0;local tab=ctx.tab or 'basic'
    local tw=w/#M.helpTabs
    for i,t in ipairs(M.helpTabs)do
        local b=UI.button(body,'HelpTab_'..t[1],t[2],function()ctx.setTab(t[1])end);UI.box(b,4+(i-1)*tw,y,tw-4,48);b.BackgroundTransparency=1;b.TextSize=14
        local st=b:FindFirstChildOfClass('UIStroke');if st then st.Enabled=false end
        local on=t[1]==tab;b.TextColor3=on and C.ink or C.muted;b.Font=on and Enum.Font.BuilderSansBold or Enum.Font.BuilderSansMedium
        local bar=UI.make('Frame',body,{Name='TabBar'..i,BackgroundColor3=on and C.ink or Style.colors.line,BorderSizePixel=0});UI.box(bar,4+(i-1)*tw,y+48,tw-4,on and 2 or 1)
    end
    y+=62
    if tab=='basic'then
        local cards={{'1','땅 고르고 정착','지도에서 육지를 고르면 내 영토가 생겨요','dot'},{'2','옆 땅 눌러 넓히기','국경 옆 땅이나 상대를 누르면 공격해요','Sword'},{'3','병력은 저절로 차요','병력이 차면 다시 넓혀요. 도시는 상한을 올려요','Soldier'}}
        local narrow=w<480;local short=ctx.short==true;local cw=narrow and w or (w-16)/3;local ch=narrow and 72 or short and 138 or 200
        for i,c in ipairs(cards)do
            local x=narrow and 4 or 4+(i-1)*(cw+8);local yy=narrow and y+(i-1)*(ch+8)or y
            local f=UI.make('Frame',body,{Name='Card'..i,BackgroundColor3=Style.colors.chip,BorderSizePixel=0});UI.box(f,x,yy,cw,ch);Style.round(f,10);Style.line(f,Style.colors.line,1)
            local n=UI.label(f,'Step',c[1],13,C.bg);n.BackgroundColor3=C.accent;n.BackgroundTransparency=0;n.TextXAlignment=Enum.TextXAlignment.Center;n.Font=Enum.Font.BuilderSansBold;Style.round(n,4);UI.box(n,10,10,22,22)
            local art
            if c[4]=='dot'then art=UI.make('Frame',f,{Name='Art',BackgroundColor3=Color3.fromRGB(32,78,92),BorderSizePixel=0});Style.round(art,10);Style.line(art,C.accent,2)
                local dot=UI.make('Frame',art,{Name='Dot',BackgroundColor3=C.accent,BorderSizePixel=0});Style.round(dot,13);dot.AnchorPoint=Vector2.new(.5,.5);dot.Position=UDim2.fromScale(.5,.5);dot.Size=UDim2.fromOffset(narrow and 18 or 30,narrow and 18 or 30)
            else art=require(script.Parent.HotbarIcons).create(f,c[4],narrow and 36 or 72,C.ink)end
            local as=narrow and 44 or short and 52 or 84;art.Size=UDim2.fromOffset(as,as);art.Position=narrow and UDim2.fromOffset(42,(ch-as)/2)or UDim2.fromOffset((cw-as)/2,short and 14 or 36)
            local title=UI.label(f,'Title',c[2],15,C.ink);title.Font=Enum.Font.BuilderSansBold;title.TextWrapped=false;title.TextTruncate=Enum.TextTruncate.AtEnd
            local text=UI.label(f,'Text',c[3],13,C.muted);text.TextYAlignment=Enum.TextYAlignment.Top
            if narrow then UI.box(title,96,10,cw-104,22);UI.box(text,96,34,cw-104,34)
            else title.TextXAlignment=Enum.TextXAlignment.Center;text.TextXAlignment=Enum.TextXAlignment.Center;UI.box(title,8,short and 72 or 130,cw-16,24);UI.box(text,8,short and 98 or 156,cw-16,short and 36 or 40)end
        end
        y+=narrow and 3*(ch+8)or ch+14
        local move=UI.label(body,'Move',ctx.touch and '이동은 조이스틱/드래그, 확대는 두 손가락'or '이동은 WASD/드래그, 확대는 휠/Q/E',13,C.muted);move.TextWrapped=false;move.TextTruncate=Enum.TextTruncate.AtEnd
        local guide=UI.button(body,'ShowGuide',ctx.inLobby and '튜토리얼 다시하기'or '지금 판에서 안내 보기',ctx.guide,true);Style.round(guide,8)
        if w>=480 then UI.box(move,4,y,w-240,48);UI.box(guide,w-226,y,230,48);y+=56
        else UI.box(move,4,y,w,24);y+=28;UI.box(guide,4,y,w,48);y+=56 end
    elseif tab=='build'or tab=='controls'then
        local blocks=tab=='build'and {
            {'건설','아래 건설 바에서 건물을 고르고 내 땅을 누르면 지어요. 도시는 완공 레벨마다 병력 상한을 25,000 늘려요.'},
            {'바다','항구가 있으면 군함과 교역선이 생겨요. 먼 적 해안은 수송 공격(상륙)으로 건너가요.'},
            {'무기','미사일 기지에서 원자폭탄, 수소폭탄과 다탄두를 쏴요. 방공(SAM)은 날아오는 핵을 요격해요.'},
            {'알아두기','빨간 공격 경고를 누르면 전선을 봐요. 동맹 요청은 왼쪽 위 카드에서 수락/거절해요.'},
        }or (ctx.touch and {
            {'지도','한 손가락 드래그로 이동, 두 손가락으로 확대/축소해요.'},
            {'행동','땅을 한 번 누르면 원형 메뉴, 같은 땅을 다시 누르면 가운데 행동을 바로 해요.'},
            {'건설','하단 건설 바를 누르고 내 땅을 눌러요. 군함은 선택 뒤 바다를 눌러 이동해요.'},
        }or {
            {'지도','WASD/드래그 이동, 우클릭 회전, 휠/Q/E 확대, Home 시점 정렬, H 내 지휘관'},
            {'건설과 무기','1~0 건설, C 도시, V 방어 초소, F 확인, X 취소, 휠 클릭 근처 건물 강화'},
            {'공격','T/Shift+휠 공격 비율, G 공격, B 상륙, Shift+R 반격, Shift+F 군함 전체'},
            {'소통','Z 이모지, R 대화, M 모션, L 순위, P 메뉴'},
        })
        for i,b in ipairs(blocks)do
            local h=UI.label(body,'Heading'..i,b[1],15,C.ink);h.Font=Enum.Font.BuilderSansBold;UI.box(h,4,y,w,24)
            local t=UI.label(body,'Body'..i,b[2],14,C.muted);t.TextYAlignment=Enum.TextYAlignment.Top;UI.box(t,4,y+26,w,44);y+=80
        end
    else y=M.catalog(body,y,w,ctx.style)end
    body.CanvasSize=UDim2.fromOffset(0,y);return y
end
function M.catalog(body,y,w,style)
    local Catalog=require(script.Parent.BuildingCatalog);local Models=require(script.Parent.BuildingModels);local look=require(script.Parent.Parent.Core.CosmeticCatalog).get(style)
    for _,e in ipairs(Catalog)do
        local f=UI.make('Frame',body,{Name='Building'..e.kind,BackgroundColor3=Style.colors.chip,BorderSizePixel=0});UI.box(f,4,y,w,132);Style.round(f,10);Style.line(f,Style.colors.line,1)
        local p=Models.preview(f,e.kind,look);UI.box(p,8,8,104,116)
        local n=UI.label(f,'Name',e.name,15,C.ink);n.Font=Enum.Font.BuilderSansBold;UI.box(n,124,8,w-136,24)
        local r=UI.label(f,'Role',e.role,13,C.ink);r.TextYAlignment=Enum.TextYAlignment.Top;UI.box(r,124,34,w-136,38)
        local s=UI.label(f,'Status',e.ready and '현재 건설 가능'or '이 모드에서는 사용할 수 없어요',13,e.ready and C.good or C.muted);UI.box(s,124,74,w-136,20)
        local d=UI.label(f,'Story',e.detail or '',13,C.muted);d.TextTruncate=Enum.TextTruncate.AtEnd;d.TextYAlignment=Enum.TextYAlignment.Top;UI.box(d,124,96,w-136,32)
        y+=140
    end
    return y
end
return M
