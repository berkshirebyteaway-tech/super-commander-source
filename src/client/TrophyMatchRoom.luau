local K=require(script.Parent.Kit20)
local Theme=require(script.Parent.Theme)
local Cup=require(script.Parent.TrophyIcon)
local Emblem=require(script.Parent.RankEmblem)
local Rules=require(script.Parent.Parent.Core.RankedRules)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local L=require(script.Parent.Localization)
local Step=require(script.Parent.TelemetryStep)
local Tween=game:GetService('TweenService')
local Me=game:GetService('Players').LocalPlayer
local C=K.colors
local M={}
local function depth(root,z)
    if root.ZIndex~=z then root.ZIndex=z end;for _,o in ipairs(root:GetChildren())do if o:IsA('GuiObject')then depth(o,z+1)end end
end
local function skip(o)o.AutoLocalize=false;o:SetAttribute('LocalizationSkip',true);return o end
local function clock(n)local s=math.max(0,math.floor(n));return string.format('%d:%02d',s//60,s%60)end
function M.stop(room)
    local ui=room.trophyUI
    if ui and ui.radarTween then ui.radarTween:Cancel();ui.radarTween=nil end
    if ui and ui.barTween then ui.barTween:Cancel();ui.barTween=nil;ui.deadline=nil end
end
local function dashed(parent,w,h)
    local f=K.make('Frame',parent,{Name='Dashed',Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
    for _,vertical in ipairs({false,true})do
        local length=vertical and h or w
        for offset=6,length-6,12 do for _,side in ipairs({0,1})do
            local d=K.make('Frame',f,{BackgroundColor3=C.accent,BackgroundTransparency=.45,BorderSizePixel=0})
            K.box(d,vertical and (side==0 and 0 or w-1)or offset,vertical and offset or (side==0 and 0 or h-1),vertical and 1 or math.min(6,length-6-offset),vertical and math.min(6,length-6-offset)or 1)
        end end
    end
    return f
end
local function card(parent,name,x,y,w,h,mine,ph,pt)
    local f=K.make('Frame',parent,{Name=name,BackgroundColor3=mine and C.accent or C.panel,BackgroundTransparency=mine and .92 or 0,BorderSizePixel=0})
    K.round(f,8);local stroke=K.stroke(f,mine and C.accent or C.line,mine and 2 or 1,0,true);K.box(f,x,y,w,h)
    local body=K.make('Frame',f,{Name='Body',Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
    local size=ph and 28 or pt and 40 or 48;local faceSize=ph and 24 or pt and 26 or 32
    local nameSize=ph and 14 or 16;local valueSize=ph and 14 or pt and 16 or 18
    local groupHeight=size+8+faceSize+8+24;local ey=math.floor((h-groupHeight)/2)
    local face=skip(K.make('ImageLabel',body,{Name='Avatar',BackgroundColor3=C.raised,BorderSizePixel=0}));K.round(face,'pill')
    local label=skip(K.text(body,'Name','',nameSize,C.ink,800,Enum.TextXAlignment.Left))
    local iy=ey+size+8;local vy=iy+faceSize+8
    local value=K.num(body,'Trophies','',valueSize,C.gold)
    local cup=Cup.create(body,'Cup',ph and 12 or 15,C.gold)
    local empty=K.text(f,'Empty','+1',ph and 26 or 30,C.accent,800,Enum.TextXAlignment.Center);K.box(empty,0,0,w,h)
    return {frame=f,body=body,stroke=stroke,face=face,name=label,value=value,cup=cup,empty=empty,dash=dashed(f,w,h),size=size,ey=ey,w=w,
        nameSize=nameSize,valueSize=valueSize,faceSize=faceSize,iy=iy,vy=vy,cupSize=ph and 12 or 15}
end
local function paintCard(c,data,mine,view,animate)
    local present=data~=nil;c.body.Visible=present;c.empty.Visible=not present;c.dash.Visible=not present;c.stroke.Enabled=present
    c.frame.BackgroundTransparency=not present and .96 or mine and .92 or 0
    if not present then c.userId=nil;return end
    local tier=mine and view and view.tier or Rules.trophyTier(data.t or 0).id
    if not mine then for _,row in ipairs(view and view.board or {})do
        if row.userId==data.userId and Rules.trophyLegend(data.t or 0,row.rank)then tier='legend';break end
    end end
    if c.tier~=tier then
        if c.emblem then c.emblem:Destroy()end
        c.tier=tier;c.emblem=Emblem.create(c.body,'Emblem',c.size,tier,nil);K.box(c.emblem,math.floor((c.w-c.size)/2),c.ey,c.size,c.size)
    end
    local fresh=c.userId~=data.userId;c.userId=data.userId
    local avatar=data.userId and data.userId>0 and 'rbxthumb://type=AvatarHeadShot&id='..tostring(data.userId)..'&w=150&h=150'or ''
    if c.face.Image~=avatar then c.face.Image=avatar end
    local name=data.name or '지휘관';local value=Theme.commas(data.t or 0)
    c.name.Text=name;c.value.Text=value
    if c.nameKey~=name then
        c.nameKey=name
        local nw=math.min(c.w-24-c.faceSize-8,K.width(name,c.nameSize,c.name)+2)
        local nx=math.floor((c.w-c.faceSize-8-nw)/2)
        K.box(c.face,nx,c.iy,c.faceSize,c.faceSize);K.box(c.name,nx+c.faceSize+8,c.iy,nw,c.faceSize)
    end
    if c.valueKey~=value then
        c.valueKey=value
        local vw=math.min(c.w-24-c.cupSize-6,K.width(value,c.valueSize,c.value)+2)
        local vx=math.floor((c.w-c.cupSize-6-vw)/2)
        K.box(c.cup,vx,c.vy+(24-c.cupSize)/2,c.cupSize,c.cupSize);K.box(c.value,vx+c.cupSize+6,c.vy,vw,24)
    end
    if fresh and animate and not K.reduced then
        local scale=c.body:FindFirstChild('Arrival')or K.make('UIScale',c.body,{Name='Arrival'})
        scale.Scale=.94;Tween:Create(scale,TweenInfo.new(.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
    end
end
local function build(room,W,H,key)
    M.stop(room);if room.content then room.content:Destroy()end
    for _,smoke in pairs(room.smoke or {})do smoke.Visible=false end
    room.wash.Parent=nil;room.frame.BackgroundColor3=C.bg
    local pt=W<600;local ph=not pt and H<500
    local insets=room.callbacks.insets and room.callbacks.insets()or {}
    local top=math.max(pt and 78 or 12,insets.top or 0)
    local sw=pt and W-24 or ph and math.min(790,W-32)or math.min(880,W-48)
    local sh=pt and H-top-24 or ph and H-top-12 or math.min(560,H-top-12)
    local x=math.floor((W-sw)/2);local y=pt and top or ph and top or math.max(top,math.floor((H-sh)/2))
    local f=K.make('Frame',room.frame,{Name='TrophyContent',BackgroundColor3=C.panel,BorderSizePixel=0,Active=true})
    room.content=f;K.round(f,14);K.stroke(f,C.line,1,0,true);K.box(f,x,y,sw,sh)
    local ui={key=key,ph=ph};room.trophyUI=ui;room.ui=ui
    local pad=pt and 19 or ph and 17 or 27;local headY=ph and 17 or pt and 19 or 27
    ui.back=K.button(f,'Back',{kind='plain',text='‹ 로비',size=12,hit=48},function()room:minimize()end);ui.back:place(pad,headY,60,32)
    local chip,chipW=K.chip(f,'Ranked',L.text('랭크'),'gold',{size=11,height=22,icon=false})
    chipW=math.max(36,chipW);K.box(chip,pad+70,headY+5,chipW,22)
    local titleX=pad+80+chipW
    ui.title=K.text(f,'Mode','1대1',20,C.ink,800);K.box(ui.title,titleX,headY,65,32)
    ui.map=K.text(f,'Map','',ph and 14 or 16,C.ink,800,Enum.TextXAlignment.Right);K.box(ui.map,titleX+72,headY,math.max(0,sw-pad-titleX-72),32)
    local gap=pt and 46 or 78;local cw=math.floor((sw-pad*2-gap)/2);local cy=ph and 59 or pt and 69 or 79
    local ch=pt and math.min(220,math.max(130,sh-250))or ph and math.min(150,sh-190)or 230
    ui.cards={card(f,'Self',pad,cy,cw,ch,true,ph,pt),card(f,'Opponent',sw-pad-cw,cy,cw,ch,false,ph,pt)}
    ui.vs=skip(K.text(f,'VS','VS',pt and 20 or 26,C.muted,800,Enum.TextXAlignment.Center));K.box(ui.vs,pad+cw,cy,sw-2*(pad+cw),ch)
    local sy=cy+ch+(ph and 12 or 24);local fs=ph and 28 or pt and 30 or 36
    local radarSize=ph and 36 or pt and 48 or 56
    ui.search=K.text(f,'Search','상대 찾는 중',fs,C.ink,800);ui.searchX=pad;ui.searchY=sy
    ui.waited=K.num(f,'Waited','0:00',ph and 20 or pt and 22 or 24,C.muted)
    ui.waitY=sy+9;ui.waitMax=sw-pad-radarSize-76
    ui.waitX={searching=pad+12+K.width(L.text('상대 찾는 중'),fs,ui.search),
        recovering=pad+12+K.width(L.text('상대 다시 찾는 중'),fs,ui.search)}
    ui.count=K.num(f,'Countdown','5',ph and 40 or 50,C.ink);K.box(ui.count,pad,sy-5,58,ph and 52 or 64)
    ui.scale=K.make('UIScale',ui.count,{Name='CountScale'})
    ui.bar=K.fillBar(f,'Departure',{p=1,fill=C.accent,track=C.raised});K.box(ui.bar.frame,pad+64,sy+24,sw-pad*2-64,5)
    ui.radar=K.make('Frame',f,{Name='Radar',BackgroundTransparency=1,BorderSizePixel=0});K.round(ui.radar,'pill');K.stroke(ui.radar,C.accent,1,.45,true);K.box(ui.radar,sw-pad-radarSize,sy+(46-radarSize)/2,radarSize,radarSize)
    ui.radarArm=K.make('Frame',ui.radar,{Name='Sweep',BackgroundTransparency=1,Size=UDim2.fromScale(1,1)})
    local arm=K.make('Frame',ui.radarArm,{BackgroundColor3=C.accent,BackgroundTransparency=.35,BorderSizePixel=0});K.box(arm,radarSize/2-1,3,2,radarSize/2-3)
    ui.leave=K.button(f,'Leave',{kind='plain',text='나가기',size=16,hit=48},function()room:quit()end);ui.leave:place(pad,sh-pad-50,pt and sw-pad*2 or 200,50)
    depth(room.frame,40)
end
function M.layout(room,W,H)
    local q=room.q;if not q or not q.trophySolo then return end
    local inset=room.callbacks.insets and room.callbacks.insets()or {}
    local key=math.floor(W)..':'..math.floor(H)..':'..L.getLocale()..':'..math.floor(inset.top or 0)..':'..math.floor(inset.left or 0)
    if not room.trophyUI or room.trophyUI.key~=key or room.content.Name~='TrophyContent'then build(room,W,H,key)end
    if room.q~=q or not room.open then room.layoutPending=true;return end
    local ui=room.trophyUI;local found=q.phase=='found';local searching=q.phase=='searching'
    local me,opp
    for _,c in ipairs(q.cards or {})do if c.userId==Me.UserId then me=c else opp=c end end
    me=me or {userId=Me.UserId,name=Me.DisplayName,t=room.trophyView and room.trophyView.t or 0}
    paintCard(ui.cards[1],me,true,room.trophyView,false);paintCard(ui.cards[2],found and opp or nil,false,room.trophyView,found)
    ui.map.Text=found and ((Maps.meta(q.rules and q.rules.map)or {}).label or '')or ''
    ui.search.Visible=not found;ui.waited.Visible=not found;ui.radar.Visible=not found
    ui.search.Text=searching and '상대 찾는 중'or '상대 다시 찾는 중'
    ui.waited.Text=clock((q.waited or 0)+(room.elapsed or 0))
    local waitX=math.min(ui.waitMax,ui.waitX[searching and 'searching'or 'recovering'])
    K.box(ui.search,ui.searchX,ui.searchY,math.max(1,waitX-ui.searchX-12),46)
    K.box(ui.waited,waitX,ui.waitY,66,28)
    ui.count.Visible=found;ui.bar.frame.Visible=found
    ui.leave:setEnabled(searching and not room.busy)
    if found then
        local remaining=math.max(0,room.remaining or 0);local count=math.ceil(remaining)
        if ui.lastCount~=count then
            ui.lastCount=count;ui.count.Text=tostring(count)
            if not K.reduced then ui.scale.Scale=.9;Tween:Create(ui.scale,TweenInfo.new(.15,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=1}):Play()else ui.scale.Scale=1 end
        end
        local deadline=os.clock()+remaining
        if not ui.deadline or math.abs(ui.deadline-deadline)>.3 then
            if ui.barTween then ui.barTween:Cancel()end;ui.deadline=deadline
            ui.bar:set(remaining/Rules.trophy.countdown)
            if remaining>0 then ui.barTween=Tween:Create(ui.bar.value,TweenInfo.new(remaining,Enum.EasingStyle.Linear),{Value=0});ui.barTween:Play()end
        end
    elseif ui.barTween then ui.barTween:Cancel();ui.barTween=nil;ui.deadline=nil;ui.lastCount=nil end
    local moving=room.open and not found and not room.reduced and not K.reduced
    if moving and not ui.radarTween then
        ui.radarTween=Tween:Create(ui.radarArm,TweenInfo.new(2,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1),{Rotation=ui.radarArm.Rotation+360});ui.radarTween:Play()
    elseif not moving and ui.radarTween then ui.radarTween:Cancel();ui.radarTween=nil;ui.radarArm.Rotation=0 end
    depth(room.frame,40)
end
function M.update(room,q,options)
    local previous=room.q
    if not previous or not previous.trophySolo or previous.joined~=q.joined then
        room.minimized=false;room.since=os.clock();room.trophyFound=nil;room.trophyDepart=nil
        Step.step('queue','join',{item='r1v1'})
    end
    if q.phase=='found'and room.trophyFound~=q.matchId then
        room.trophyFound=q.matchId;room.minimized=false
        Step.step('queue','found',{item='r1v1',value=q.waited or 0});Step.step('queue','countdown',{item='r1v1',value=q.remaining or 0})
    end
    if q.phase=='transferring'and room.trophyDepart~=q.matchId then room.trophyDepart=q.matchId;Step.step('queue','depart',{item='r1v1'})end
    room.q=q;room.remaining=options.remaining;room.elapsed=options.elapsed or 0;room.trophyView=options.trophy
    room:show(options.menu~=false and not options.page and not room.minimized and q.phase~='transferring')
    if room.open then room:layout()end
end
return M
