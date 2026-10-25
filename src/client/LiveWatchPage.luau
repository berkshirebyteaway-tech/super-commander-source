local K=require(script.Parent.Kit20)
local S=require(script.Parent.Sheet20)
local Theme=require(script.Parent.Theme)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local Raster=require(script.Parent.RasterMap)
local Step=require(script.Parent.TelemetryStep)
local C=K.colors
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
local function picture(lobby,parent,slot,key,x,y,w,h,r)
    local frame=K.make('Frame',parent,{Name='Map',BackgroundColor3=C.ocean,BorderSizePixel=0});K.box(frame,x,y,w,h);K.round(frame,r)
    lobby.watchRasters=lobby.watchRasters or {}
    local e=lobby.watchRasters[slot]
    if not e then e={raster=Raster.new(frame,M.PICTURE[1],M.PICTURE[2])};lobby.watchRasters[slot]=e end
    local rs=e.raster;rs.parent=frame;rs.label.Parent=frame;K.round(rs.label,r)
    local ok=key and pcall(function()if e.key~=key then rs:setPreview(Maps.preview(key));e.key=key;e.dirty=true end end)
    if ok then frame.BackgroundColor3=rs.outside or C.ocean;if e.size~=w..'x'..h then e.size=w..'x'..h;e.dirty=true end end
    rs.label.Visible=ok==true and not e.dirty
    paintQueue(lobby)
    return frame
end

local function card(lobby,parent,i,m,x,y,w,h,fmt,locked,Lock)
    local pt,ph=fmt=='pt',fmt=='ph'
    local band=pt and 44 or ph and 42 or 58
    local f=K.make('TextButton',parent,{Name='Live'..i,Text='',AutoButtonColor=false,BackgroundColor3=C.panel,BorderSizePixel=0});K.round(f,pt and 10 or 8);K.box(f,x,y,w,h)
    local edge=K.stroke(f,C.line,1,0,true);edge.ZIndex=4
    local map=picture(lobby,f,i,m.map,0,0,w,h-band,pt and 10 or 8)
    map.ZIndex=1
    local cs,ch=pt and 11 or ph and 11 or 12,pt and 20 or ph and 18 or 22
    local live=K.chip(f,'Live','LIVE','live',{size=cs,height=ch,icon=false});live.Position=UDim2.fromOffset(8,8);live.ZIndex=3
    for _,o in ipairs(live:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=4 end end
    if m.friend then local fc=K.chip(f,'Friend','친구','accent',{size=cs,height=ch,icon=false});fc.Position=UDim2.fromOffset(8+live.Size.X.Offset+6,8);fc.ZIndex=3 end
    if locked then local lk=K.lock(f,'VIP',0,8,11);lk.Position=UDim2.fromOffset(w-8-lk.Size.X.Offset,8);lk.ZIndex=3;for _,o in ipairs(lk:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=4 end end end
    local mapName=(Maps.meta(m.map)or {}).label or m.map
    local pad=pt and 12 or ph and 8 or 12
    local by=h-band
    if pt then
        local ns=14;local n=K.text(f,'Title',mapName,ns,C.ink,800);local nw=K.width(mapName,ns,n);n.ZIndex=3;K.box(n,pad+1,by,math.min(nw+2,w-120),band)
        local md=K.text(f,'Mode',m.mode or '개인전',12,C.muted,800);md.ZIndex=3;K.box(md,pad+1+math.min(nw+2,w-120)+4,by,w-pad*2-nw-90,band)
        local cnt=K.num(f,'Count',string.format('%d',m.alive or 0),13,C.muted,Enum.TextXAlignment.Right);cnt.ZIndex=3
        local word=K.text(f,'People','명',12,C.muted,700);word.ZIndex=3;local ww=K.width('명',12,word)
        K.box(word,w-pad-ww-2,by,ww+2,band);K.box(cnt,w-pad-ww-2-60,by,60,band)
    else
        local ns=ph and 12 or 15;local ms=ph and 11 or 12
        local n=K.text(f,'Title',mapName,ns,C.ink,800);n.ZIndex=3;K.box(n,pad,by+(ph and 5 or 8),w/2,ns+4)
        local md=K.text(f,'Mode',m.mode or '개인전',ms,C.muted,600);md.ZIndex=3;K.box(md,pad,by+(ph and 5 or 8)+ns+4,w/2,ms+3)
        local a=K.num(f,'Alive',tostring(m.alive or 0),ns,C.ink);local hm=K.num(f,'Humans','/'..tostring(m.humans or 0),ns,C.muted)
        a.ZIndex=3;hm.ZIndex=3
        local hw=K.width(hm.Text,ns,hm);local aw=K.width(a.Text,ns,a)
        K.box(hm,w-pad-hw-1,by+(ph and 3 or 5),hw+1,ns+7);K.box(a,w-pad-hw-aw-1,by+(ph and 3 or 5),aw+1,ns+7)
        local t=K.text(f,'Minutes',m.spawning and '시작 전'or string.format('%d분',m.minutes or 0),ms,C.muted,700,Enum.TextXAlignment.Right);t.ZIndex=3
        K.box(t,w/2,by+(ph and 5 or 8)+ns+4,w/2-pad,ms+3)
    end
    f.Activated:Connect(function()
        if locked then Step.step('spectate','watchLocked',{item='live',value=i,result='rejected',reason='subscription_required'});require(script.Parent.ToyAudio).play('error');Lock.open('spectate');return end
        require(script.Parent.ToyAudio).play('click')
        Step.step('spectate','watch',{item='live',value=i,count=m.watchers});lobby:closePage();lobby:request('spectate',m.id)
    end)
    return f
end
local function replayRow(lobby,parent,i,r,y,w,fmt,place,now)
    local pt,ph=fmt=='pt',fmt=='ph'
    local h=pt and 76 or ph and 50 or 72
    local f=K.make('Frame',parent,{Name='Replay'..i,BackgroundColor3=C.panel,BorderSizePixel=0});K.round(f,pt and 10 or 8);K.box(f,0,y,w,h);K.stroke(f,C.line,1,0,true)
    local mw,mh=pt and 72 or ph and 60 or 104,pt and 52 or ph and 36 or 54;local pad=pt and 11 or ph and 9 or 13
    picture(lobby,f,i,r.map,pad,(h-mh)/2,mw,mh,pt and 6 or 4)
    local ok=M.playable(r,place)
    local bw,bh=pt and 76 or ph and 84 or 104,pt and 44 or ph and 30 or 38
    local b=K.button(f,'Watch',{kind=ok and 'out'or 'plain',text=ok and '다시보기'or '지난 버전',size=pt and 14 or ph and 12 or 14,weight=800},function()
        if not ok then Step.step('spectate','replayOld',{item='replay',value=i,result='rejected',reason='version'});if lobby.notify then lobby.notify('이전 버전 경기',false)end;return end
        Step.step('spectate','watch',{item='replay',value=i});lobby:closePage();lobby:request('replay',r.id)end)
    b:place(w-pad-bw,(h-bh)/2,bw,bh);if not ok then b.label.TextColor3=C.muted;b.ink=C.muted end
    local tx=pad+mw+(pt and 10 or ph and 10 or 16);local tw=w-pad-bw-12-tx
    local ns=pt and 15 or ph and 13 or 17;local ss=pt and 12 or ph and 11 or 13
    local n=K.text(f,'Title',(Maps.meta(r.map)or {}).label or r.map,ns,ok and C.ink or C.muted,800);K.box(n,tx,h/2-ns-1,tw,ns+3)
    local won=r.outcome=='won'
    local sub=K.text(f,'Sub',string.format(won and '승리 %d분'or '패배 %d분',r.minutes or 0),ss,won and C.good2 or C.muted,700);local sw=K.width(sub.Text,ss,sub);K.box(sub,tx,h/2+2,sw+2,ss+3)
    local ago=K.text(f,'Ago',(r.mode or '개인전')..'  '..M.ago(r.at,now),ss,C.muted,600);K.box(ago,tx+sw+10,h/2+2,math.max(0,tw-sw-10),ss+3)
    return f,h
end

function M.draw(lobby,p,_w)
    for _,o in ipairs(p:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
    local sc=Theme.scale or 1;local W,H=lobby.root.AbsoluteSize.X/sc,lobby.root.AbsoluteSize.Y/sc
    local fmt=S.format(W,H);local pt,ph=fmt=='pt',fmt=='ph'
    local sw,sh=p.Size.X.Offset,p.Size.Y.Offset
    local root=K.make('Frame',p,{Name='Page20',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromOffset(sw,sh)})
    local first=lobby.first20=='watch';lobby.first20=nil
    local source=lobby.data and lobby.data.live or {}
    lobby.liveSignature=M.signature(source)
    local list,order=table.clone(source),{};for i,m in ipairs(source)do order[m]=i end
    table.sort(list,function(a,b)if (a.friend==true)~=(b.friend==true)then return a.friend==true end;return order[a]<order[b]end)
    Step.change('liveList','spectate','liveList',{value=#list,result=#list==0 and 'unavailable'or 'shown'})
    local Lock=require(script.Parent.VipLock);local locked=not Lock.allows('spectate')
    M.loadReplays(lobby)
    local tab=lobby.watchTab or 'live'
    local lift=0;do local d=lobby.deployment;local q=lobby.data and lobby.data.queue;if q and d and d.bar and d.bar.Visible then lift=(d.barHeight or 48)+8 end end
    local _,CB=S.band(H,lift)
    local p0=pt and 16 or ph and 12 or 24;local inset=pt and 0 or 1;local x0=p0+inset;local w=pt and sw-32 or sw-2*x0
    local rows={}
    if tab=='replays'then
        local head=S.head(root,fmt,sw,'내 다시보기',function()lobby:back()end,{back=function()lobby.watchTab='live';Step.step('spectate','tab',{item='live'});lobby:drawPage()end})
        local top=head.y+head.h+(pt and 8 or ph and 6 or 18)
        local bottom=pt and CB or sh-(ph and 12 or 24)
        local scroll=S.scroll(root,'Replays',x0,top,w,bottom-top)
        local replays=lobby.replays
        local y=0
        if not replays then local l=K.text(scroll,'ReplayLoading','불러오는 중…',14,C.muted,700,Enum.TextXAlignment.Center);K.box(l,0,8,w,30);y=46
        elseif #replays==0 then local l=K.text(scroll,'ReplayEmpty','저장한 경기 없음  최근 10판',15,C.muted,700,Enum.TextXAlignment.Center);K.box(l,0,8,w,30);y=46
        else local place,now=game.PlaceVersion,os.time()
            for i,r in ipairs(replays)do local f,h=replayRow(lobby,scroll,i,r,y,w,fmt,place,now);table.insert(rows,f);y+=h+(pt and 6 or ph and 5 or 10)end end
        S.canvas(scroll,y);S.stagger(rows,first)
        return
    end
    local head=S.head(root,fmt,sw,'관전',function()lobby:back()end)
    local ls=pt and 13 or ph and 13 or 15
    local liveL=K.num(root,'LiveCount',string.format('LIVE %d',#list),ls,C.muted,Enum.TextXAlignment.Right);K.box(liveL,head.right-120,head.y,120,head.h)
    local rh=pt and 52 or ph and 36 or 48
    local function replayLink(y)
        local b=K.button(root,'Replays',{kind='none',r=pt and 10 or 8},function()lobby.watchTab='replays';Step.step('spectate','tab',{item='replays'});lobby:drawPage()end)
        b.face.BackgroundColor3=pt and C.raised or C.panel;b.face.BackgroundTransparency=0;b.baseFill=b.face.BackgroundColor3;b.baseAlpha=0
        b:place(x0,y,w,rh)
        local is=pt and 18 or ph and 16 or 18;local ip=pt and 12 or 14
        local ic=K.icon(b.face,'replay',is,C.accent,'Icon');K.box(ic,ip,(rh-is)/2,is,is)
        local t=K.text(b.face,'Label','내 다시보기',pt and 14 or ph and 13 or 15,C.ink,800);K.box(t,ip+is+10,0,w-ip-is-80,rh)
        local chev=K.icon(b.face,'chev',16,C.muted,'Chevron');K.box(chev,w-ip-16,(rh-16)/2,16,16)
        local n=lobby.replays and #lobby.replays or nil
        if n then local c=K.num(b.face,'Count',tostring(n),pt and 13 or ph and 12 or 14,C.muted,Enum.TextXAlignment.Right);K.box(c,w-ip-16-10-40,0,40,rh)end
        for _,o in ipairs(b.face:GetChildren())do if o:IsA('GuiObject')and o.Name~='Depth'then o.ZIndex=b.face.ZIndex+1 end end
    end
    local top=pt and head.y+head.h+8 or ph and 47 or 73
    if #list==0 then
        local ey=top+(pt and 40 or ph and 30 or 70)
        local icon=K.icon(root,'watch',30,C.muted,'EmptyIcon');icon.ImageTransparency=.35;K.box(icon,math.floor(sw/2)-15,ey,30,30)
        local e=K.text(root,'Empty','진행 중 공식전 없음',pt and 15 or 16,C.ink,800,Enum.TextXAlignment.Center);K.box(e,x0,ey+38,w,24)
        local go=K.button(root,'Official',{kind='pri',text='공식 전장 참가',size=pt and 16 or 15},function()lobby:closePage();lobby.deployment:open('official')end)
        go:place(math.floor((sw-220)/2),ey+74,220,pt and 48 or 44)
        replayLink(pt and CB-rh or ey+74+(pt and 48 or 44)+(ph and 12 or 24))
        return
    end
    if pt then
        local ch=128;local scroll=S.scroll(root,'Live',x0,top,w,CB-rh-8-top)
        local y=0
        for i,m in ipairs(list)do table.insert(rows,card(lobby,scroll,i,m,0,y,w,ch,fmt,locked,Lock));y+=ch+8 end
        S.canvas(scroll,y-8)
        replayLink(CB-rh)
    else
        local cols,gap=3,ph and 8 or 14;local chh=ph and 118 or 178
        local cw=math.floor((w-(cols-1)*gap)/cols)
        local maxRows=ph and 1 or 2;local need=math.ceil(#list/cols);local shownRows=math.min(maxRows,math.max(1,need))
        local areaH=shownRows*chh+(shownRows-1)*gap
        local scroll=S.scroll(root,'Live',x0,top,w,areaH)
        for i,m in ipairs(list)do table.insert(rows,card(lobby,scroll,i,m,((i-1)%cols)*(cw+gap),((i-1)//cols)*(chh+gap),i%cols==0 and w-(cols-1)*(cw+gap)or cw,chh,fmt,locked,Lock))end
        S.canvas(scroll,need*(chh+gap)-gap)
        replayLink(top+areaH+(ph and 10 or 18))
    end
    S.stagger(rows,first)
end
return M
