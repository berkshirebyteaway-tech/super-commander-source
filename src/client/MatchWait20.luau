local K=require(script.Parent.Kit20)
local L=require(script.Parent.Localization)
local Step=require(script.Parent.TelemetryStep)
local Audio=require(script.Parent.ToyAudio)
local Me=game:GetService('Players').LocalPlayer
local C=K.colors
local M={}
local function depth(root,z)
    if root.ZIndex~=z then root.ZIndex=z end;for _,o in ipairs(root:GetChildren())do if o:IsA('GuiObject')then depth(o,z+1)end end
end
local function clock(n)local s=math.max(0,math.ceil(n or 0));return string.format('%d:%02d',s//60,s%60)end
function M.is(q)return q~=nil and q.mode=='pvp'and type(q.rules)=='table'and q.rules.pending==true end
function M.stop(room)room.matchUI=nil end
local function build(room,W,H,key)
    if room.content then room.content:Destroy()end
    for _,smoke in pairs(room.smoke or {})do smoke.Visible=false end
    room.wash.Parent=nil;room.frame.BackgroundColor3=C.bg;room.key=nil
    local pt=W<600;local ph=not pt and H<500
    local f=K.make('Frame',room.frame,{Name='MatchWait',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Active=false})
    room.content=f
    local ui={key=key,pt=pt,ph=ph,W=W,H=H};room.matchUI=ui;room.ui=nil
    local mw=math.min(W,math.floor(H*2));local mh=math.floor(mw/2)
    local map=K.map(f,'World','world',mw,mh,0,.72);map.BackgroundTransparency=1;K.box(map,(W-mw)/2,(H-mh)/2,mw,mh)
    local insets=room.callbacks.insets and room.callbacks.insets()or {}
    local top=math.max(pt and 120 or ph and 34 or 110,(insets.top or 0)+(pt and 56 or 12))
    local lfs=pt and 15 or ph and 14 or 18
    ui.label=K.text(f,'Label','매칭 중',lfs,C.muted,700,Enum.TextXAlignment.Center);K.box(ui.label,0,top,W,lfs+6)
    local cfs=pt and 64 or ph and 48 or 84
    ui.clockY=top+lfs+(ph and 8 or 16);ui.clockFs=cfs
    ui.clock=K.num(f,'Clock','-:--',cfs,C.ink,Enum.TextXAlignment.Center);K.box(ui.clock,0,ui.clockY,W,cfs+4)
    local nfs=pt and 15 or ph and 14 or 17
    ui.count=K.text(f,'Count','',nfs,C.muted,700,Enum.TextXAlignment.Center);K.box(ui.count,0,ui.clockY+cfs+(ph and 2 or 8),W,nfs+6)
    ui.facesY=ui.clockY+cfs+nfs+(ph and 16 or 36);ui.face=pt and 52 or ph and 44 or 64;ui.gap=pt and 10 or 12
    ui.faces=K.make('Frame',f,{Name='Faces',BackgroundTransparency=1});K.box(ui.faces,0,ui.facesY,W,ui.face+4)
    local bw,bh=pt and W-32 or ph and 180 or 220,pt and 52 or ph and 44 or 52
    local bottom=pt and 34 or ph and 14 or 36
    ui.cancel=K.button(f,'Cancel',{kind='plain',text='취소',size=pt and 17 or 16,weight=700,hit=48},function()
        if room.busy then return end;Audio.play('click');Step.step('queue','cancel',{item='match',value=room.since and math.floor(os.clock()-room.since)or nil});room.callbacks.leave()end)
    ui.cancel:place((W-bw)/2,H-bottom-bh,bw,bh)
    depth(room.frame,40)
end
local function paintFaces(ui,members)
    local ids={};for _,m in ipairs(members or {})do table.insert(ids,m.userId)end
    if #ids==0 then ids={Me.UserId}end
    for i,id in ipairs(ids)do if id==Me.UserId and i>1 then table.remove(ids,i);table.insert(ids,1,Me.UserId);break end end
    local sig=table.concat(ids,',');if ui.facesSig==sig then return end;ui.facesSig=sig
    for _,o in ipairs(ui.faces:GetChildren())do o:Destroy()end
    local per=ui.face+ui.gap;local fit=math.max(1,math.floor((ui.W-32+ui.gap)/per));local shown=#ids>fit and fit-1 or #ids
    local total=(#ids>fit and fit or #ids)*per-ui.gap;local x0=math.floor((ui.W-total)/2)
    for i=1,shown do local id=ids[i];local mine=id==Me.UserId
        local face=K.make('ImageLabel',ui.faces,{Name='Face',BackgroundColor3=C.raised,BorderSizePixel=0,ScaleType=Enum.ScaleType.Crop,AutoLocalize=false})
        face.Image='rbxthumb://type=AvatarHeadShot&id='..tostring(id)..'&w=150&h=150';K.round(face,12)
        K.stroke(face,mine and C.accent or C.line,mine and 2 or 1,0,true);K.box(face,x0+(i-1)*per,0,ui.face,ui.face)
    end
    if #ids>shown then
        local more=K.make('Frame',ui.faces,{Name='More',BackgroundTransparency=1});K.round(more,12);K.stroke(more,C.line,1,0,true);K.box(more,x0+shown*per,0,ui.face,ui.face)
        local t=K.num(more,'Text','+'..tostring(#ids-shown),ui.pt and 15 or 17,C.muted,Enum.TextXAlignment.Center);t.Size=UDim2.fromScale(1,1)
    end
end
function M.layout(room,W,H)
    local q=room.q;if not M.is(q)then return end
    local inset=room.callbacks.insets and room.callbacks.insets()or {}
    local key=math.floor(W)..':'..math.floor(H)..':'..L.getLocale()..':'..math.floor(inset.top or 0)
    if not room.matchUI or room.matchUI.key~=key or not room.content or room.content.Name~='MatchWait'then build(room,W,H,key)end
    if room.q~=q or not room.open then room.layoutPending=true;return end
    local ui=room.matchUI;local r=q.room or {}
    local alone=r.missing~=nil
    local remaining=math.max(0,room.remaining or 0)
    local text=alone and '-:--'or clock(remaining)
    if ui.clock.Text~=text then ui.clock.Text=text end
    ui.clock.TextColor3=alone and C.muted or C.ink
    local secs=math.ceil(remaining)
    if not alone and ui.lastSecond and secs<ui.lastSecond and secs<=5 and secs>0 then Audio.play('countdown')end
    ui.lastSecond=not alone and secs or nil
    local n=q.count or 1;local people=alone and '1명 더 오면 출발'or n>=2 and string.format('%d명',n)or ''
    if ui.count.Text~=people then ui.count.Text=people end
    paintFaces(ui,q.members)
    ui.cancel:setEnabled(not room.busy and not q.locked,true)
    depth(room.frame,40)
end
function M.update(room,q,options)
    local previous=room.q
    if not M.is(previous)or previous.field~=q.field then
        room.since=os.clock();room.minimized=false;room.departed=nil
        Step.step('queue','roomOpen',{value=q.count,item='match'})
    end
    local was=M.is(previous)and previous.field==q.field and previous.room
    if was and was.missing and q.room and not q.room.missing then Step.step('queue','roomPaired',{value=room.since and math.floor(os.clock()-room.since)or nil,count=q.count})end
    room.q=q;room.remaining=options.remaining;room.elapsed=options.elapsed or 0;room.reduced=options.reduced;room.busy=options.busy
    room:show(options.menu~=false and not options.page and not room.minimized)
    if room.open then room:layout()end
end
return M
