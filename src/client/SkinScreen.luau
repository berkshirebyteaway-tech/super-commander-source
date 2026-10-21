local UI=require(script.Parent.ToyUI)
local K=require(script.Parent.SkinShopKit)
local Icons=require(script.Parent.OutgameIcons)
local Items=require(script.Parent.WardrobeItems)
local Flags=require(script.Parent.Flags)
local Launch=require(script.Parent.Parent.Core.LaunchCommerce)
local FlagNames=require(script.Parent.Parent.Core.FlagNamesData)
local M={}
function M.flagName(code)return FlagNames[code]or string.upper(tostring(code))end
M.groups={
    {'지휘관',{{'commanderStandard','깃발'},{'flag','국기'},{'vehicle','탈것'},{'commanderTrail','트레일'}}},
    {'지도',{{'territory','영토'},{'city','건물'},{'projectile','핵'},{'parachute','낙하산'}}},
    {'표현',{{'commanderOrder','지휘 연출'},{'motions','모션'},{'honors','칭호와 명판'}}},
}
local names={};for _,g in ipairs(M.groups)do for _,c in ipairs(g[2])do names[c[1]]=c[2]end end
M.mapSlots={territory=true,city=true,projectile=true,parachute=true}
local Preview=require(script.Parent.CollectionPreview)
local function step(name,data)pcall(function()require(script.Parent.TelemetryClient).step('cosmetics',name,data)end)end
local LEFT=Enum.TextXAlignment.Left;local CENTER=Enum.TextXAlignment.Center
local function current(hub)
    local tab=hub.wardrobeTab or 'items'
    if tab=='honors'or tab=='motions'then return tab end
    hub.slot=require(script.Parent.Parent.Core.CollectionInbox).primary[hub.slot or '']or hub.slot or 'commanderStandard'
    return hub.slot
end
local function open(hub,key)
    if hub.wardrobeTab=='honors'then require(script.Parent.CareerWardrobe).flush(hub)end
    if key=='honors'or key=='motions'then hub.wardrobeTab=key else hub.wardrobeTab='items';hub.slot=key end
    hub.wardrobePick=nil;hub.flagPick=nil;step('skinCategory',{item=key});hub:drawPage()
end
local function worn(hub,key)
    local a=hub.account;local p=a.progress or {}
    if key=='motions'then local n=#((a.preferences or {}).motionLoadout or {});return n>0 and string.format('%d개 장착',n)or '없음'end
    if key=='honors'then local eq=p.career and p.career.equipped or {};return eq.title and eq.title~=''and eq.title~='none'and '칭호 장착'or p.title or '기본'end
    if key=='flag'then return a.flag and M.flagName(a.flag)or '프로필 사진'end
    return (Items.wornName(hub,key))
end
local function scroller(p,name,x,y,w,h,hub,keep)
    local s=UI.make('ScrollingFrame',p,{Name=name,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=UI.colors.line,CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y,Active=true})
    UI.box(s,x,y,w,h)
    UI.make('UIPadding',s,{PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4),PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4)})
    if hub and keep then hub.skinScroll=hub.skinScroll or {}
        local saved=hub.skinScroll[keep];if saved then task.defer(function()if s.Parent then s.CanvasPosition=saved end end)end
        s:GetPropertyChangedSignal('CanvasPosition'):Connect(function()hub.skinScroll[keep]=s.CanvasPosition end)
    end
    return s
end
local function categories(hub,root,x,y,w,h,slim,key)
    local panel=K.panel(root,'Categories',x,y,w,h);local list=scroller(panel,'List',0,6,w,h-12,hub,'categories');hub.collectionRows=list
    local cy=4;local rh=slim and 48 or 50;local rx=slim and (w-48)/2 or 6;local rw=slim and 48 or w-12
    for _,g in ipairs(M.groups)do
        if not slim then K.text(list,'Group_'..g[1],g[1],16,cy,w-24,22,13,UI.colors.muted);cy+=24
        elseif cy>4 then UI.box(UI.make('Frame',list,{Name='Divider',BackgroundColor3=UI.colors.line,BorderSizePixel=0}),12,cy+2,w-24,1);cy+=6 end
        for _,c in ipairs(g[2])do
            local id=c[1];local on=id==key
            local b=UI.button(list,'Slot_'..id,'',function()if not on then open(hub,id)end end);UI.box(b,rx,cy,rw,rh);K.round(b,6)
            b.BackgroundColor3=on and UI.colors.line or UI.colors.panel;b.BackgroundTransparency=on and 0 or 1
            local e=b:FindFirstChildOfClass('UIStroke');if e then e.Enabled=false end
            if on then K.round(UI.make('Frame',b,{Name='Picked',BackgroundColor3=UI.colors.ink,BorderSizePixel=0}),2);b.Picked.Size=UDim2.fromOffset(3,rh-16);b.Picked.Position=UDim2.fromOffset(0,8)end
            local gs=slim and 24 or 24;local glyph=K.glyph(b,id,gs,on and UI.colors.accent or UI.colors.accent:Lerp(UI.colors.muted,.35))
            glyph.Position=UDim2.fromOffset(slim and (rw-gs)/2 or 12,(rh-gs)/2)
            if not slim then
                K.text(b,'Name',c[2],46,5,w-64,22,15,on and UI.colors.ink or UI.colors.ink:Lerp(UI.colors.muted,.3),LEFT,K.heavy)
                K.text(b,'Worn',worn(hub,id),46,26,w-64,18,13,UI.colors.muted)
            end
            cy+=rh+2
        end
        cy+=4
    end
    list.CanvasSize=UDim2.fromOffset(0,cy)
    if slim and cy>h then local more=K.text(panel,'More','▾',0,h-16,w,14,13,UI.colors.muted,CENTER);more.ZIndex=3 end
end
local function ticks(p,w,h)
    for _,c in ipairs({{0,0,1,1},{1,0,-1,1},{0,1,1,-1},{1,1,-1,-1}})do
        local x=c[1]*w+c[3]*6;local y=c[2]*h+c[4]*6
        UI.box(UI.make('Frame',p,{Name='Tick',AnchorPoint=Vector2.new(c[1],c[2]),BackgroundColor3=UI.colors.ink,BackgroundTransparency=.2,BorderSizePixel=0,ZIndex=4}),x,y,14,2)
        UI.box(UI.make('Frame',p,{Name='Tick',AnchorPoint=Vector2.new(c[1],c[2]),BackgroundColor3=UI.colors.ink,BackgroundTransparency=.2,BorderSizePixel=0,ZIndex=4}),x,y,2,14)
    end
end
local function source(e,key)
    if e.none then return '기본값'end
    if e.supply then return '보급 상자에서 얻음'end
    if e.level then return e.level>1 and string.format('Lv.%d 해금',e.level)or '기본 지급'end
    if e.rarity=='rare'then return '출시 기념'end
    return '기본 지급'
end
local function actionBar(hub,root,bar,e,shop,w,h,slim)
    for _,o in ipairs(bar:GetChildren())do if not o:IsA('UICorner')and not o:IsA('UIStroke')then o:Destroy()end end
    local a=hub.account;local p=a.progress or {};local openSlots=a.billing and a.billing.benefits and a.billing.benefits.loadoutSlots or Launch.freeLoadouts
    local active=p.activeLoadout;if type(active)~='number'or active>openSlots then active=nil end
    local cs=48;local two=w<8+4*52+84+8;local x=slim and 8 or 12;local cy=two and 4 or (h-cs)/2
    if not slim and w>=72+4*56+24+120 then K.text(bar,'PresetLabel','프리셋',14,0,54,h,14,UI.colors.muted);x=72 end
    for i=1,4 do
        local index,locked=i,i>openSlots;local saved=p.loadouts and p.loadouts[tostring(i)]~=nil
        local b
        b=UI.button(bar,'Preset'..i,locked and ''or tostring(i),function()
            if locked then step('presetLocked',{item='slot'..index,sku='permanent',result='unavailable'})
                K.bubble(b,root,'커맨더 프라임이 있어야 쓸 수 있어요','상점에서 보기 ›',function()hub:openPage('shop')end);return end
            if active==index or shop.busy then return end
            step('presetPick',{item='slot'..index,value=saved and 1 or 0,result='selected'});shop:run(function()shop:request('useLoadout',index)end)
        end);UI.box(b,x,cy,cs,cs);K.round(b,6);b.TextSize=slim and 15 or 17;b.Font=K.heavy
        b.BackgroundColor3=active==index and UI.colors.raised or UI.colors.panel
        local edge=b:FindFirstChildOfClass('UIStroke');if edge then edge.Color=active==index and UI.colors.ink or UI.colors.line;edge.Thickness=active==index and 2 or 1 end
        if locked then UI.box(Icons.create(b,'lock',14,UI.colors.muted),cs/2-7,cs/2-7,14,14)elseif not saved and active~=index then b.TextColor3=UI.colors.muted end
        x+=cs+(slim and 4 or 8)
    end
    local bw=two and w-16 or slim and w-x-4 or math.min(220,w-x-24);local bx=two and 8 or w-bw-(slim and 8 or 12);local bh=slim and 48 or 56;local by=two and cs+12 or (h-bh)/2;local tight=bw<130
    local label,primary,enabled,fn
    if e.worn then label,enabled='장착 중',false
    elseif e.owned then label,primary,enabled,fn='장착',true,not shop.busy,function()step('equip',{item=e.id});e.equip()end
    elseif e.supply then label,enabled,fn=tight and '보급 상자 ›'or '보급 상자에서 얻기 ›',true,function()step('toShop',{item=e.id});hub:openPage('shop')end
    else label,enabled=e.level and string.format(tight and 'Lv.%d 해금'or 'Lv.%d에 열려요',e.level)or '잠겨 있어요',false end
    local b=UI.button(bar,primary and 'Equip'or e.supply and not e.owned and 'GetSupply'or 'EquipState',label,fn or function()end,primary);UI.box(b,bx,by,bw,bh);K.round(b,8)
    b.TextSize=tight and 15 or slim and 16 or 19;b.Font=K.heavy;UI.enabled(b,enabled)
    if primary then UI.make('UIGradient',b,{Rotation=90,Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(205,215,214))})
    elseif not enabled then b.BackgroundColor3=UI.colors.panel;b.TextColor3=UI.colors.muted end
end
function M.nameplate(parent,code,slim)
    local k=slim and 1.6 or 2.2
    local plate=K.round(UI.make('Frame',parent,{Name='Nameplate',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.48),BackgroundColor3=UI.colors.bg,BackgroundTransparency=.1,BorderSizePixel=0,ZIndex=3}),6)
    UI.stroke(plate,UI.colors.line,1)
    local name=game.Players.LocalPlayer.DisplayName
    local tw=K.width(name,math.floor(14*k),K.heavy);local pw=math.floor(9*k+3*k+7*k+24*k+7*k+tw+9*k);local ph=math.floor(34*k)
    plate.Size=UDim2.fromOffset(pw,ph)
    UI.make('Frame',plate,{Name='Signal',BackgroundColor3=UI.colors.accent,BorderSizePixel=0,Position=UDim2.fromOffset(9*k,(ph-22*k)/2),Size=UDim2.fromOffset(3*k,22*k),ZIndex=4})
    local x=9*k+3*k+7*k
    if code then local f=UI.make('Frame',plate,{Name='Flag',BackgroundTransparency=1,ZIndex=4});UI.box(f,x,(ph-16*k)/2,24*k,16*k);Flags.apply(f,code)
    else
        local i=K.round(UI.make('ImageLabel',plate,{Name='Headshot',BackgroundColor3=UI.colors.raised,BorderSizePixel=0,ScaleType=Enum.ScaleType.Crop,ZIndex=4,
            Image='rbxthumb://type=AvatarHeadShot&id='..game.Players.LocalPlayer.UserId..'&w=150&h=150'}),99);UI.box(i,x,(ph-24*k)/2,24*k,24*k);UI.stroke(i,UI.colors.accent,1.5)
    end
    local l=K.text(plate,'Name',name,x+24*k+7*k,0,tw+4,ph,math.floor(14*k),UI.colors.ink,LEFT,K.heavy);l.ZIndex=4;l.AutoLocalize=false
    return plate
end
local function frameOrder(v,zoom)
    local c=Preview.contextOf(v);if not c then return end
    local m=math.max(c.bounds.X,c.bounds.Z);if m<=0 then return end
    local bottom=c.center.Y-c.bounds.Y/2
    local h=math.min(c.bounds.Y,m*.6)
    c.center=Vector3.new(c.center.X,bottom+h/2,c.center.Z);c.bounds=Vector3.new(m,h,m);c.zoom=zoom;c.viewSize=nil
end
local function stage(hub,root,view,e,key)
    local panel=view.stage;for _,o in ipairs(panel:GetChildren())do if not o:IsA('UICorner')and not o:IsA('UIStroke')then o:Destroy()end end
    local w,h,slim=view.sw,view.sh,view.slim;local onMap=hub.skinMapView==true and not slim and M.mapSlots[key]==true
    local color=K.rarity[e.rarity or 'normal']or K.rarity.normal
    UI.make('UIGradient',panel,{Rotation=125,Color=ColorSequence.new(color:Lerp(UI.colors.bg,.78),UI.colors.panel)})
    if not slim then ticks(panel,w,h)end
    local pad=slim and 12 or 26;local ty=slim and 10 or 24
    if e.rarity and (e.grade or e.level or e.rarity~='normal')then
        K.chip(panel,'Grade',Launch.rarityNames[e.rarity],color,pad,ty,slim and 24 or 26,true,13);ty+=(slim and 28 or 32)
    end
    local name=K.text(panel,'Name',e.name,pad,ty,w-pad*2-(slim and 0 or 150),slim and 26 or 36,slim and 20 or 28,UI.colors.ink,LEFT,K.heavy);name.ZIndex=3;ty+=slim and 26 or 38
    if not slim then
        local L=require(script.Parent.Localization);local src=K.text(panel,'Source',L.text(names[key]or '')..', '..L.text(source(e,key)),pad,ty,w-pad*2,22,15,UI.colors.ink:Lerp(UI.colors.muted,.35));src.ZIndex=3;src:SetAttribute('LocalizationSkip',true);ty+=26
        if M.mapSlots[key]then
            K.text(panel,'Fair','외형만 바뀌어요. 병력과 전투 성능은 모두 같아요.',pad,ty,w-pad*2,20,13,UI.colors.muted).ZIndex=3;ty+=26
            K.switch(panel,'PreviewMode',{{id='solo',text='단독'},{id='map',text='지도 위'}},onMap and 2 or 1,function(i)hub.skinMapView=i==2;step('previewMode',{item=i==2 and 'map'or 'solo'});stage(hub,root,view,e,key)end,w-pad-120,pad-4,120,36,14).ZIndex=5
        end
    elseif M.mapSlots[key]then K.text(panel,'Fair','외형만 바뀌어요',pad,h-28,w-pad*2,20,13,UI.colors.muted).ZIndex=3 end
    local top=slim and ty or ty+4;local bottom=slim and (M.mapSlots[key]and 30 or 10)or 16
    local holder=UI.make('Frame',panel,{Name='Look',BackgroundTransparency=1,ZIndex=2});UI.box(holder,pad,top,w-pad*2,math.max(40,h-top-bottom))
    if key=='flag'then M.nameplate(holder,e.flagCode,slim)
    elseif onMap and e.item then local v=require(script.Parent.SkinMapScene).create(holder,e.item);v.Size=UDim2.fromScale(1,1);v.ZIndex=2
    elseif e.preview then local v=e.preview(holder,key~='commanderStandard');v.Size=UDim2.fromScale(1,1);v.Position=UDim2.new();v.ZIndex=2
        if key=='commanderOrder'then local c=Preview.contextOf(v);if c then c.zoom=.72;c.viewSize=nil end end
    end
    actionBar(hub,root,view.bar,e,view.shop,view.bw,view.bh,slim)
end
local function card(hub,grid,e,x,y,cw,ch,slim,pick)
    local color=K.rarity[e.rarity or 'normal']or K.rarity.normal
    local b=UI.button(grid,'Item_'..e.id,'',function()pick(e)end);UI.box(b,x,y,cw,ch);K.round(b,8);b.ClipsDescendants=true
    b.BackgroundColor3=UI.colors.panel;b:SetAttribute('Owned',e.owned==true);if e.key then b:SetAttribute('CollectionKey',e.key)end
    UI.make('UIGradient',b,{Rotation=90,Color=ColorSequence.new(color:Lerp(UI.colors.panel,.72),UI.colors.panel)})
    K.round(UI.make('Frame',b,{Name='GradeStripe',BackgroundColor3=color,BorderSizePixel=0,Position=UDim2.fromOffset(2,0),Size=UDim2.new(1,-4,0,4)}),2)
    local nameH=slim and 40 or 46
    if e.flagCode then local fw=math.min(48,cw*.5);local f=UI.make('Frame',b,{Name='Flag',BackgroundTransparency=1});UI.box(f,(cw-fw)/2,(ch-nameH-fw*.66)/2+4,fw,fw*.66);Flags.apply(f,e.flagCode)
    elseif e.id=='none'and e.preview then local s=math.min(40,cw*.45);local v=e.preview(b,false);UI.box(v,(cw-s)/2,(ch-nameH-s)/2+4,s,s);K.round(v,99)
    elseif e.preview then local v=e.preview(b,false);UI.box(v,6,10,cw-12,ch-nameH-14)
        if e.item and e.item.category=='motion'then frameOrder(v,.92)end
        if not e.owned and v:IsA('ViewportFrame')then v.ImageColor3=Color3.fromRGB(150,156,166);v.ImageTransparency=.3 end end
    local dot=K.round(UI.make('Frame',b,{Name='GradeDot',BackgroundColor3=color,BorderSizePixel=0}),99);UI.box(dot,10,ch-nameH+6,8,8)
    K.text(b,'Name',e.name,24,ch-nameH-2,cw-30,22,slim and 13 or 14,e.owned and UI.colors.ink or UI.colors.ink:Lerp(UI.colors.muted,.4),LEFT,K.heavy)
    local state,sc,lock
    if e.worn then state,sc='✓ 장착 중',UI.colors.accent
    elseif e.owned then state,sc='보유',UI.colors.muted
    elseif e.supply then state,sc='보급 상자',UI.colors.muted
    else state,sc,lock=e.level and string.format('Lv.%d 해금',e.level)or '잠김',UI.colors.muted,true end
    local sx=10;if lock then UI.box(Icons.create(b,'lock',12,UI.colors.muted),10,ch-20,12,12);sx=26 end
    K.text(b,'State',state,sx,ch-24,cw-sx-6,20,13,sc,LEFT,e.worn and K.heavy or nil)
    if e.worn then local t=K.round(UI.make('Frame',b,{Name='WornCheck',BackgroundColor3=UI.colors.accent,BorderSizePixel=0}),99);UI.box(t,cw-28,10,20,20)
        UI.box(Icons.create(t,'check',14,UI.colors.bg),3,3,14,14)end
    local edge=b:FindFirstChildOfClass('UIStroke');if edge then edge.Color=UI.colors.line;edge.Thickness=1 end
    local ring=K.round(UI.make('Frame',b,{Name='Selected',BackgroundTransparency=1,Position=UDim2.fromOffset(2,2),Size=UDim2.new(1,-4,1,-4),ZIndex=6,Visible=false}),7)
    UI.make('UIStroke',ring,{Color=UI.colors.ink,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
    return b
end
local function select(view,e)
    for id,b in pairs(view.cards)do local r=b:FindFirstChild('Selected');if r then r.Visible=id==e.id end end
end
local function flagEntries(hub,shop)
    local a=hub.account;local out={{id='none',name='프로필 사진',owned=true,worn=a.flag==nil,rarity='normal',equip=function()shop:run(function()shop:request('flag',false)end)end,
        preview=function(parent)local i=UI.make('ImageLabel',parent,{Name='Headshot',BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,Image='rbxthumb://type=AvatarHeadShot&id='..game.Players.LocalPlayer.UserId..'&w=150&h=150'});return i end}}
    local codes={};if Flags.atlas then for code in pairs(Flags.atlas.index)do if FlagNames[code]then table.insert(codes,code)end end end
    table.sort(codes,function(x,y)return M.flagName(x)<M.flagName(y)end)
    for _,code in ipairs(codes)do table.insert(out,{id=code,name=M.flagName(code),flagCode=code,owned=true,worn=a.flag==code,rarity='normal',equip=function()shop:run(function()shop:request('flag',code)end)end})end
    return out
end
function M.draw(hub,body,shop)
    local inset=body:FindFirstChild('ContentInset');if inset then inset:Destroy()end
    body.CanvasSize=UDim2.new();body.CanvasPosition=Vector2.zero
    local W,H=body.Size.X.Offset,body.Size.Y.Offset;if W<10 then return end
    local slim=H<420;local key=current(hub);local gap=slim and 8 or 16
    hub.collectionBody=nil;hub.collectionRows=nil
    require(script.Parent.TelemetryStep).once('skinScreen','cosmetics','skinScreen',{item=key})
    local portrait=W<600;if portrait then slim=true end
    local lw=slim and 60 or W<1100 and 184 or 212
    categories(hub,body,0,0,lw,H,slim,key)
    local x0=lw+gap;local rest=W-x0
    if key=='honors'or key=='motions'then
        local panel=K.panel(body,'Expression',x0,0,rest,H)
        K.text(panel,'Title',names[key],16,10,rest-32,28,slim and 17 or 20,UI.colors.ink,LEFT,K.heavy)
        local s=scroller(panel,'List',12,46,rest-24,H-56,hub,key);hub.collectionBody=s
        s:GetPropertyChangedSignal('CanvasPosition'):Connect(function()require(script.Parent.CollectionBadges).schedule(hub)end)
        if key=='honors'then local y=require(script.Parent.CareerWardrobe).draw(hub,s,rest-36,0,shop);s.CanvasSize=UDim2.fromOffset(0,y+8)
        else require(script.Parent.MotionsPage).draw(hub,s,rest-36,0)end
        return
    end
    local cols=slim and 2 or 3;local cw=slim and 112 or (W<1100 and 132 or 150);local cg=slim and 8 or 10;local pad=slim and 10 or 16
    local rw=cols*cw+(cols-1)*cg+pad*2;local center=rest-rw-gap
    if center<(slim and 220 or 360)then cw=math.max(slim and 100 or 112,math.floor((rest-gap-(slim and 220 or 360)-pad*2-(cols-1)*cg)/cols));rw=cols*cw+(cols-1)*cg+pad*2;center=rest-rw-gap end
    local ry,rh2=0,H
    if portrait then center=rest;rw=rest;cw=math.floor((rw-pad*2-cg)/2)end
    local ch=slim and 124 or math.floor(cw*188/150)
    local list=key=='flag'and flagEntries(hub,shop)or Items.entries(hub,key,shop)
    if key=='flag'then cols=slim and 3 or 5;cw=math.floor((rw-pad*2-(cols-1)*cg)/cols);ch=slim and 84 or math.floor(cw*.9)end
    local only=hub.ownedOnly==true;local owned=0;for _,e in ipairs(list)do if e.owned then owned+=1 end end
    local shown={};for _,e in ipairs(list)do if not only or e.owned then table.insert(shown,e)end end
    local pickId=key=='flag'and hub.flagPick or hub.wardrobePick;local cur
    for _,e in ipairs(list)do if e.id==pickId then cur=e end end
    if not cur then for _,e in ipairs(list)do if e.worn then cur=e end end end
    cur=cur or list[1];if not cur then return end
    local bh=slim and 56 or 72;local sh=H-bh-(slim and 0 or 16)
    local stageH=slim and H-bh or sh
    if portrait then bh=112;stageH=math.floor(H*.4);ry=stageH+bh+gap;rh2=H-ry end
    local stagePanel=K.panel(body,'Stage',x0,0,center,stageH);stagePanel.ClipsDescendants=true
    local bar=K.panel(body,'ActionBar',x0,slim and stageH or sh+16,center,bh);if slim then bar.BackgroundTransparency=1;bar.UIStroke.Enabled=false end
    local view={stage=stagePanel,bar=bar,sw=center,sh=stageH,bw=center,bh=bh,slim=slim,shop=shop,cards={}};hub.skinView=view
    stage(hub,body,view,cur,key)
    local right=K.panel(body,'Collection',portrait and x0 or x0+center+gap,ry,rw,rh2)
    K.text(right,'Title',names[key],pad,slim and 6 or 12,rw*.5,28,slim and 16 or 20,UI.colors.ink,LEFT,K.heavy)
    local tw=K.width(names[key],slim and 16 or 20,K.heavy)
    K.text(right,'Owned',key=='flag'and string.format('%d개',#list-1)or string.format('%d / %d 보유',owned,#list),pad+tw+10,slim and 6 or 12,rw*.5,28,slim and 13 or 14,UI.colors.muted)
    local hy=slim and 38 or 52
    if key~='flag'then
        if slim then hy=50 end
        K.switch(right,'OwnedFilter',{{id='all',text='전체'},{id='owned',text='보유만'}},only and 2 or 1,function(i)hub.ownedOnly=i==2;step('ownedFilter',{value=i==2 and 1 or 0});hub:drawPage()end,rw-pad-(slim and 112 or 120),slim and 4 or 10,slim and 112 or 120,slim and 40 or 34,slim and 13 or 14)
    end
    local grid=scroller(right,'Grid',pad-4,hy,rw-pad*2+11,rh2-hy-pad,hub,'grid:'..key);hub.collectionBody=grid
    local function pick(e)
        if key=='flag'then hub.flagPick=e.id else hub.wardrobePick=e.id end;step('previewOpened',{item=e.id})
        select(view,e);stage(hub,body,view,e,key)
    end
    for i,e in ipairs(shown)do view.cards[e.id]=card(hub,grid,e,(i-1)%cols*(cw+cg),math.floor((i-1)/cols)*(ch+cg),cw,ch,slim,pick)end
    grid.CanvasSize=UDim2.fromOffset(0,math.ceil(#shown/cols)*(ch+cg)+8)
    select(view,cur)
    grid:GetPropertyChangedSignal('CanvasPosition'):Connect(function()require(script.Parent.CollectionBadges).schedule(hub)end)
end
return M
