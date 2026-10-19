local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.OutgameIcons)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local M={}
function M.signature(list)
    local parts={};for _,m in ipairs(list or {})do table.insert(parts,m.id..':'..m.alive..':'..m.watchers..':'..m.minutes..':'..tostring(m.leader))end
    return table.concat(parts,'|')
end
function M.loadReplays(lobby)
    if lobby.replaysLoading or lobby.replaysAt and os.clock()-lobby.replaysAt<60 then return end
    lobby.replaysLoading=true
    task.spawn(function()
        local ok,r=pcall(function()return game.ReplicatedStorage.FrontierNative.LobbyRequest:InvokeServer('replays')end)
        lobby.replaysLoading=false;lobby.replaysAt=os.clock();lobby.replays=ok and type(r)=='table'and r.replays or {}
        require(script.Parent.TelemetryStep).step('spectate','replays',{count=#lobby.replays,result=ok and 'ok'or 'failed'})
        if lobby.page=='watch'then lobby:drawPage()end
    end)
end
local function replays(lobby,p,w,y)
    M.loadReplays(lobby)
    local head=UI.label(p,'ReplayHeader','내 공식전 다시보기',15,UI.colors.ink);UI.box(head,6,y,w-12,28);y+=34
    local list=lobby.replays
    if not list then local l=UI.label(p,'ReplayLoading','불러오는 중…',13,UI.colors.muted);UI.box(l,6,y,w-12,24);return y+32 end
    if #list==0 then local l=UI.label(p,'ReplayEmpty','공식전을 끝까지 마치면 저장',13,UI.colors.muted);l.TextWrapped=true;UI.box(l,6,y,w-12,40);return y+48 end
    for i,r in ipairs(list)do
        local row=UI.panel(p,'Replay'..i);row.BackgroundColor3=UI.colors.raised;UI.box(row,2,y,w-4,60)
        local mapName=(Maps.meta(r.map)or {}).label or r.map
        local t=UI.label(row,'Title',mapName..' '..(r.mode or '개인전'),15,UI.colors.ink);t.TextWrapped=false;t.TextTruncate=Enum.TextTruncate.AtEnd;UI.box(t,12,6,w-140,24)
        local sub=UI.label(row,'Sub',string.format(r.outcome=='won'and '승리 %d분'or '패배 %d분',r.minutes or 0),13,r.outcome=='won'and UI.colors.good or UI.colors.muted);UI.box(sub,12,30,w-140,22)
        local b=UI.button(row,'Watch','다시보기',function()require(script.Parent.TelemetryStep).step('spectate','watch',{item='replay',value=i});lobby:closePage();lobby:request('replay',r.id)end);UI.box(b,w-124,8,112,44)
        y+=68
    end
    return y
end
function M.draw(lobby,p,w)
    lobby.pageTitle.Text='관전과 다시보기'
    local source=lobby.data and lobby.data.live or {}
    lobby.liveSignature=M.signature(source)
    local list,order=table.clone(source),{};for i,m in ipairs(source)do order[m]=i end
    table.sort(list,function(a,b)if (a.friend==true)~=(b.friend==true)then return a.friend==true end;return order[a]<order[b]end)
    require(script.Parent.TelemetryStep).change('liveList','spectate','liveList',{value=#list,result=#list==0 and 'unavailable'or 'shown'})
    local y=0
    local Lock=require(script.Parent.VipLock);local locked=not Lock.allows('spectate')
    local intro=UI.label(p,'Intro',locked and '실시간 관전은 VIP 클럽 혜택, 다시보기는 무료'or '공식전 실시간 관전, 자리 차지 없음, 관전자 채팅',13,locked and UI.colors.gold or UI.colors.muted)
    intro.TextWrapped=true;UI.box(intro,6,y,w-12,40);y+=48
    if #list==0 then
        local icon=Icons.create(p,'watch',30,UI.colors.muted);UI.box(icon,math.floor(w/2)-15,y+6,30,30);if Icons.available(icon)then icon.ImageTransparency=.35 end
        local empty=UI.label(p,'Empty','진행 중 공식전 없음',16,UI.colors.ink);empty.TextXAlignment=Enum.TextXAlignment.Center;UI.box(empty,6,y+40,w-12,28);y+=80
        local official=UI.button(p,'Official','공식 전장 참가',function()lobby:closePage();lobby.deployment:open('official')end,true);UI.box(official,2,y,w-4,48);y+=60
        p.CanvasSize=UDim2.fromOffset(0,replays(lobby,p,w,y));return
    end
    local narrow=w<420
    for i,m in ipairs(list)do
        local card=UI.panel(p,'Live'..i);card.BackgroundColor3=UI.colors.raised;UI.box(card,2,y,w-4,narrow and 112 or 88)
        local mapName=(Maps.meta(m.map)or {}).label or m.map
        local title=UI.label(card,'Title',mapName..' '..(m.mode or '개인전'),16,UI.colors.ink);title.TextWrapped=false;title.TextTruncate=Enum.TextTruncate.AtEnd
        local sub=UI.label(card,'Sub',m.spawning and string.format('지휘관 %d/%d  국가 %d  시작 위치 고르는 중',m.alive or 0,m.humans or 0,m.nations or 0)or string.format('지휘관 %d/%d  국가 %d  %d분째',m.alive or 0,m.humans or 0,m.nations or 0,m.minutes or 0),13,UI.colors.muted)
        sub.TextWrapped=false;sub.TextTruncate=Enum.TextTruncate.AtEnd
        local lead=UI.label(card,'Leader',m.leader and string.format('선두 %s %.1f%%',require(script.Parent.Localization).text(m.leader),(m.leaderShare or 0)*100)or '',13,UI.colors.gold)
        lead.TextWrapped=false;lead.TextTruncate=Enum.TextTruncate.AtEnd;lead:SetAttribute('LocalizationSkip',true)
        local watch=UI.button(card,'Watch',m.watchers>0 and string.format('관전 %d',m.watchers)or '관전',function()
            if locked then require(script.Parent.TelemetryStep).step('spectate','watchLocked',{item='live',value=i,result='rejected',reason='subscription_required'});Lock.open('spectate');return end
            require(script.Parent.TelemetryStep).step('spectate','watch',{item='live',value=i,count=m.watchers});lobby:closePage();lobby:request('spectate',m.id)end,true)
        local bw=narrow and w-24 or 112
        UI.box(title,12,6,w-(narrow and 28 or 144),24);UI.box(sub,12,32,w-(narrow and 28 or 144),20);UI.box(lead,12,54,w-(narrow and 28 or 144),20)
        if narrow then UI.box(watch,10,62,bw,44);lead.Visible=false else UI.box(watch,w-128,22,bw,44)end
        if m.friend then local chip=UI.pill(card,'Friend','친구',UI.colors.accent);UI.box(chip,narrow and w-80 or w-196,6,56,22);chip.TextSize=13 end
        if i==1 and not m.spawning then
            local ribbon=UI.make('Frame',card,{Name='Live',BackgroundColor3=UI.colors.danger,BorderSizePixel=0,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-6,0,-8),Size=UDim2.fromOffset(58,20),ZIndex=card.ZIndex+3});UI.corner(ribbon,3)
            local lt=UI.label(ribbon,'Text','LIVE',13,UI.colors.ink);lt.Font=Enum.Font.BuilderSansBold;UI.box(lt,18,0,38,20);lt.ZIndex=ribbon.ZIndex+1;lt:SetAttribute('LocalizationSkip',true)
            local dot=UI.make('Frame',ribbon,{Name='Dot',BackgroundColor3=UI.colors.ink,BorderSizePixel=0,Position=UDim2.fromOffset(7,6),Size=UDim2.fromOffset(8,8),ZIndex=ribbon.ZIndex+1});UI.corner(dot,40)
            game:GetService('TweenService'):Create(dot,TweenInfo.new(.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{BackgroundTransparency=.7}):Play()
            ribbon:SetAttribute('AllowOverlap',true)
        else watch.BackgroundColor3=UI.colors.raised;watch.TextColor3=UI.colors.ink end
        if locked then watch.BackgroundColor3=UI.colors.raised;watch.TextColor3=UI.colors.muted;watch:SetAttribute('Locked',true);local tag=Lock.tag(watch,0,0);tag.AnchorPoint=Vector2.new(1,0);tag.Position=UDim2.new(1,6,0,-6)end
        y+=(narrow and 112 or 88)+8
    end
    p.CanvasSize=UDim2.fromOffset(0,replays(lobby,p,w,y+8))
end
return M
