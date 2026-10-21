local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.OutgameIcons)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local Raster=require(script.Parent.RasterMap)
local Step=require(script.Parent.TelemetryStep)
local M={}
M.PICTURE={128,72}
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
        Step.step('spectate','replays',{count=#lobby.replays,result=ok and 'ok'or 'failed'})
        if lobby.page=='watch'then lobby:drawPage()end
    end)
end
function M.playable(row,place)return type(row)=='table'and row.place~=nil and row.place==place end
function M.ago(at,now)
    if type(at)~='number'then return ''end
    local s=math.max(0,now-at)
    if s<60 then return '방금 전'end
    if s<3600 then return string.format('%d분 전',s//60)end
    if s<86400 then return string.format('%d시간 전',s//3600)end
    return string.format('%d일 전',s//86400)
end
function M.release(lobby,keep)
    local pool=lobby.watchRasters;if not pool then return end
    for _,e in ipairs(pool)do if keep then e.raster.label.Parent=nil else e.raster:destroy()end end
    if not keep then lobby.watchRasters=nil end
end
local function paintQueue(lobby)
    if lobby.watchPainting then return end
    lobby.watchPainting=true
    task.spawn(function()
        local beat=game:GetService('RunService').Heartbeat;beat:Wait()
        while lobby.watchRasters do
            local job;for _,e in ipairs(lobby.watchRasters)do if e.dirty and e.raster.label.Parent then job=e;break end end
            if not job then break end
            job.dirty=false;local ok=pcall(function()job.raster:fit();job.raster:draw()end);job.raster.label.Visible=ok
            beat:Wait()
        end
        lobby.watchPainting=false
    end)
end
local function picture(lobby,parent,slot,key,x,y,w,h)
    local frame=UI.make('Frame',parent,{Name='Map',BackgroundColor3=UI.colors.ocean,BorderSizePixel=0,ClipsDescendants=true});UI.box(frame,x,y,w,h);UI.corner(frame,3)
    lobby.watchRasters=lobby.watchRasters or {}
    local e=lobby.watchRasters[slot]
    if not e then e={raster=Raster.new(frame,M.PICTURE[1],M.PICTURE[2])};lobby.watchRasters[slot]=e end
    local r=e.raster;r.parent=frame;r.label.Parent=frame
    local ok=key and pcall(function()if e.key~=key then r:setPreview(Maps.preview(key));e.key=key;e.dirty=true end end)
    if ok then frame.BackgroundColor3=r.outside or UI.colors.ocean;if e.size~=w..'x'..h then e.size=w..'x'..h;e.dirty=true end end
    r.label.Visible=ok==true and not e.dirty
    paintQueue(lobby)
    return frame
end
local function tabs(lobby,p,w,y,current,liveCount,locked)
    local list={{'live',liveCount>0 and string.format('실시간 관전 %d',liveCount)or '실시간 관전',locked and 'lock'or 'watch'},
        {'replays',lobby.replays and #lobby.replays>0 and string.format('내 다시보기 %d',#lobby.replays)or '내 다시보기','records'}}
    local gap=6;local tw=(w-4-gap)/2;local size=w<420 and 14 or 15
    for i,t in ipairs(list)do
        local on=current==t[1]
        local b=UI.button(p,'WatchTab_'..t[1],t[2],function()if not on then lobby.watchTab=t[1];Step.step('spectate','tab',{item=t[1]});p.CanvasPosition=Vector2.zero;lobby:drawPage()end end,on)
        UI.box(b,2+(i-1)*(tw+gap),y,tw,48);b.TextSize=size
        local textW=game:GetService('TextService'):GetTextSize(require(script.Parent.Localization).text(b.Text),size,b.Font,Vector2.new(1000,48)).X
        local start=math.max(8,(tw-textW-22)/2)
        UI.make('UIPadding',b,{PaddingLeft=UDim.new(0,22)})
        local ic=Icons.create(b,t[3],16,on and UI.colors.bg or (t[3]=='lock'and UI.colors.vip or UI.colors.muted));ic.Name='TabIcon';UI.box(ic,start-22,16,16,16)
    end
    return y+56
end
local function vipBanner(p,w,y,Lock)
    local narrow=w<420;local h=narrow and 106 or 72
    local b=UI.panel(p,'VipBanner');b.BackgroundColor3=UI.colors.raised;UI.box(b,2,y,w-4,h)
    local edge=b:FindFirstChildOfClass('UIStroke');if edge then edge.Color=UI.colors.vip;edge.Transparency=.55 end
    local ic=Icons.create(b,'lock',22,UI.colors.vip);UI.box(ic,14,narrow and 15 or 25,22,22)
    local tw=narrow and w-64 or w-64-160
    local t=UI.label(b,'Title','실시간 관전은 VIP 클럽 전용이에요',15,UI.colors.vip);t.TextWrapped=false;t.TextTruncate=Enum.TextTruncate.AtEnd;UI.box(t,46,narrow and 14 or 24,tw,24)
    local go=UI.button(b,'Club','VIP 클럽 보기',function()Step.step('spectate','vipBanner',{result='opened'});Lock.offer('spectate')end,true)
    if narrow then UI.box(go,10,h-58,w-24,48)else UI.box(go,w-4-152,12,140,48)end
    return y+h+8
end
local function replays(lobby,p,w,y)
    M.loadReplays(lobby)
    local list=lobby.replays
    if not list then local l=UI.label(p,'ReplayLoading','불러오는 중…',13,UI.colors.muted);UI.box(l,6,y,w-12,24);return y+32 end
    if #list==0 then
        local icon=Icons.create(p,'records',30,UI.colors.muted);UI.box(icon,math.floor(w/2)-15,y+6,30,30);if Icons.available(icon)then icon.ImageTransparency=.35 end
        local l=UI.label(p,'ReplayEmpty','공식전을 끝까지 마치면 저장',15,UI.colors.ink);l.TextXAlignment=Enum.TextXAlignment.Center;UI.box(l,6,y+40,w-12,24)
        local s=UI.label(p,'ReplayKeep','최근 10경기를 다시 볼 수 있어요',13,UI.colors.muted);s.TextXAlignment=Enum.TextXAlignment.Center;UI.box(s,6,y+66,w-12,20)
        return y+96
    end
    local narrow=w<420;local place,now=game.PlaceVersion,os.time()
    local pw,ph=narrow and 84 or 112,narrow and 56 or 64;local h=ph+(narrow and 20 or 24);local bw=narrow and 64 or 112
    for i,r in ipairs(list)do
        local row=UI.panel(p,'Replay'..i);row.BackgroundColor3=UI.colors.raised;UI.box(row,2,y,w-4,h)
        picture(lobby,row,i,r.map,10,(h-ph)/2,pw,ph)
        local tx=10+pw+12;local tw=w-4-tx-bw-20
        local mapName=(Maps.meta(r.map)or {}).label or r.map
        local t=UI.label(row,'Title',narrow and mapName or mapName..' '..(r.mode or '개인전'),15,UI.colors.ink);t.TextWrapped=false;t.TextTruncate=Enum.TextTruncate.AtEnd
        local sub=UI.label(row,'Sub',string.format(r.outcome=='won'and '승리 %d분'or '패배 %d분',r.minutes or 0),13,r.outcome=='won'and UI.colors.good or UI.colors.muted);sub.TextWrapped=false
        local ago=UI.label(row,'Ago',M.ago(r.at,now),13,UI.colors.muted);ago.TextWrapped=false;ago.TextTruncate=Enum.TextTruncate.AtEnd
        local ly=narrow and 6 or 10;UI.box(t,tx,ly,tw,22);UI.box(sub,tx,ly+22,tw,20);UI.box(ago,tx,ly+42,tw,20)
        if narrow then
            local sw=math.ceil(game:GetService('TextService'):GetTextSize(require(script.Parent.Localization).text(sub.Text),13,sub.Font,Vector2.new(1000,20)).X)+8
            local mode=UI.label(row,'Mode',r.mode or '개인전',13,UI.colors.muted);mode.TextWrapped=false;mode.TextTruncate=Enum.TextTruncate.AtEnd;UI.box(mode,tx+sw,ly+22,math.max(0,tw-sw),20);UI.box(sub,tx,ly+22,math.min(sw,tw),20)
        end
        local ok=M.playable(r,place)
        local b=UI.button(row,'Watch',ok and (narrow and '보기'or '다시보기')or '지난 버전',function()
            if not ok then Step.step('spectate','replayOld',{item='replay',value=i,result='rejected',reason='version'});if lobby.notify then lobby.notify('업데이트 전 경기라 다시 볼 수 없어요.',false)end;return end
            Step.step('spectate','watch',{item='replay',value=i});lobby:closePage();lobby:request('replay',r.id)end,ok)
        UI.box(b,w-4-bw-10,(h-48)/2,bw,48)
        if not ok then b.BackgroundColor3=UI.colors.raised;b.TextColor3=UI.colors.muted;t.TextColor3=UI.colors.muted end
        y+=h+8
    end
    return y
end
local function live(lobby,p,w,y,list,locked,Lock)
    if #list==0 then
        local icon=Icons.create(p,'watch',30,UI.colors.muted);UI.box(icon,math.floor(w/2)-15,y+6,30,30);if Icons.available(icon)then icon.ImageTransparency=.35 end
        local empty=UI.label(p,'Empty','진행 중 공식전 없음',16,UI.colors.ink);empty.TextXAlignment=Enum.TextXAlignment.Center;UI.box(empty,6,y+40,w-12,28);y+=80
        local official=UI.button(p,'Official','공식 전장 참가',function()lobby:closePage();lobby.deployment:open('official')end,true);UI.box(official,2,y,w-4,48)
        return y+60
    end
    local narrow=w<420
    local pw,ph=narrow and 104 or 128,narrow and 60 or 72
    local h=narrow and ph+20+56 or ph+24
    for i,m in ipairs(list)do
        local card=UI.panel(p,'Live'..i);card.BackgroundColor3=UI.colors.raised;UI.box(card,2,y,w-4,h)
        picture(lobby,card,i,m.map,narrow and 10 or 12,narrow and 10 or 12,pw,ph)
        local tx=(narrow and 10 or 12)+pw+12;local tw=narrow and w-4-tx-10 or w-4-tx-140
        local mapName=(Maps.meta(m.map)or {}).label or m.map
        local title=UI.label(card,'Title',mapName..' '..(m.mode or '개인전'),16,UI.colors.ink);title.TextWrapped=false;title.TextTruncate=Enum.TextTruncate.AtEnd
        local sub=UI.label(card,'Sub',m.spawning and string.format('지휘관 %d/%d  국가 %d  시작 위치 고르는 중',m.alive or 0,m.humans or 0,m.nations or 0)or string.format('지휘관 %d/%d  국가 %d  %d분째',m.alive or 0,m.humans or 0,m.nations or 0,m.minutes or 0),13,UI.colors.muted)
        sub.TextWrapped=false;sub.TextTruncate=Enum.TextTruncate.AtEnd
        local lead=UI.label(card,'Leader',m.leader and string.format('선두 %s %.1f%%',require(script.Parent.Localization).text(m.leader),(m.leaderShare or 0)*100)or '',13,UI.colors.gold)
        lead.TextWrapped=false;lead.TextTruncate=Enum.TextTruncate.AtEnd;lead:SetAttribute('LocalizationSkip',true)
        local ty=narrow and 8 or 12;UI.box(title,tx,ty,tw,24);UI.box(sub,tx,ty+26,tw,20);UI.box(lead,tx,ty+48,tw,20)
        local label=locked and 'VIP 전용'or m.watchers>0 and string.format('관전 %d',m.watchers)or '관전'
        local watch=UI.button(card,'Watch',label,function()
            if locked then Step.step('spectate','watchLocked',{item='live',value=i,result='rejected',reason='subscription_required'});Lock.open('spectate');return end
            Step.step('spectate','watch',{item='live',value=i,count=m.watchers});lobby:closePage();lobby:request('spectate',m.id)end,true)
        if narrow then UI.box(watch,10,h-58,w-24,48)else UI.box(watch,w-4-124,(h-48)/2,112,48)end
        if m.friend then local chip=UI.pill(card,'Friend','친구',UI.colors.accent);UI.box(chip,narrow and 14 or 16,narrow and 14 or 16,44,20);chip.TextSize=12;chip.ZIndex=card.ZIndex+3 end
        if i==1 and not m.spawning then
            local ribbon=UI.make('Frame',card,{Name='Live',BackgroundColor3=UI.colors.danger,BorderSizePixel=0,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-6,0,-8),Size=UDim2.fromOffset(58,20),ZIndex=card.ZIndex+3});UI.corner(ribbon,3)
            local lt=UI.label(ribbon,'Text','LIVE',13,UI.colors.ink);lt.Font=Enum.Font.BuilderSansBold;UI.box(lt,18,0,38,20);lt.ZIndex=ribbon.ZIndex+1;lt:SetAttribute('LocalizationSkip',true)
            local dot=UI.make('Frame',ribbon,{Name='Dot',BackgroundColor3=UI.colors.ink,BorderSizePixel=0,Position=UDim2.fromOffset(7,6),Size=UDim2.fromOffset(8,8),ZIndex=ribbon.ZIndex+1});UI.corner(dot,40)
            game:GetService('TweenService'):Create(dot,TweenInfo.new(.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{BackgroundTransparency=.7}):Play()
            ribbon:SetAttribute('AllowOverlap',true)
        else watch.BackgroundColor3=UI.colors.raised;watch.TextColor3=UI.colors.ink end
        if locked then
            watch.BackgroundColor3=UI.colors.raised;watch.TextColor3=UI.colors.vip;watch:SetAttribute('Locked',true)
            local s=watch:FindFirstChildOfClass('UIStroke');if s then s.Color=UI.colors.vip;s.Transparency=.5 end
            local tag=Lock.tag(watch,0,0);tag.AnchorPoint=Vector2.new(1,0);tag.Position=UDim2.new(1,6,0,-6)
        end
        y+=h+8
    end
    return y
end
function M.draw(lobby,p,w)
    lobby.pageTitle.Text='관전과 다시보기'
    local source=lobby.data and lobby.data.live or {}
    lobby.liveSignature=M.signature(source)
    local list,order=table.clone(source),{};for i,m in ipairs(source)do order[m]=i end
    table.sort(list,function(a,b)if (a.friend==true)~=(b.friend==true)then return a.friend==true end;return order[a]<order[b]end)
    Step.change('liveList','spectate','liveList',{value=#list,result=#list==0 and 'unavailable'or 'shown'})
    local Lock=require(script.Parent.VipLock);local locked=not Lock.allows('spectate')
    M.loadReplays(lobby)
    local tab=lobby.watchTab or 'live'
    local y=tabs(lobby,p,w,0,tab,#list,locked)
    if tab=='replays'then p.CanvasSize=UDim2.fromOffset(0,replays(lobby,p,w,y)+8);return end
    if locked then y=vipBanner(p,w,y,Lock)
    else local intro=UI.label(p,'Intro','공식전 실시간 관전, 자리 차지 없음, 관전자 채팅',13,UI.colors.muted);intro.TextWrapped=true;UI.box(intro,6,y,w-12,24);y+=32 end
    p.CanvasSize=UDim2.fromOffset(0,live(lobby,p,w,y,list,locked,Lock)+8)
end
return M
