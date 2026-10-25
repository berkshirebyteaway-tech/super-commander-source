local UI=require(script.Parent.ToyUI)
local Catalog=require(script.Parent.Parent.Core.CosmeticCatalog)
local Art=require(script.Parent.CollectionArt)
local G=require(script.Parent.ToyGeometry)
local M={};local active={};local now=0
local flags=setmetatable({},{__mode='k'})
local function visible(frame)
    if not frame.Parent or frame.AbsoluteSize.X<1 then return false end
    local p=frame
    while p and not p:IsA('LayerCollector')do
        if p:IsA('GuiObject')then
            if not p.Visible then return false end
            if p.ClipsDescendants and (frame.AbsolutePosition.Y+frame.AbsoluteSize.Y<p.AbsolutePosition.Y or frame.AbsolutePosition.Y>p.AbsolutePosition.Y+p.AbsoluteSize.Y)then return false end
        end;p=p.Parent
    end
    return not p or p.Enabled
end
function M.model(item,role)
    local s=Catalog.get(item.style);local f=item.category
    if f=='commanderStandard'then
        local rig=require(script.Parent.CommanderStandardRig).new(nil,item.style,UI.colors.accent)
        rig:step(CFrame.identity,0,0,1,0,nil,false,3);flags[rig.model]=rig;return rig.model,{flag=rig}
    elseif f=='buildings'then return require(script.Parent.BuildingModels).create(role or 'City',s,2,true)
    elseif f=='nuclear'then
        local Skins=require(script.Parent.NukeSkins);local l=item.loadout
        return require(script.Parent.NukeFx).warhead('HydrogenBomb',Skins.get(l,'projectile'),Skins.get(l,'trail'),UI.colors.accent)
    elseif f=='territory'then return Art.territory(s,UI.colors.accent)
    elseif f=='commanderTrail'then return Art.trailDisplay(s)
    elseif f=='vehicle'then return require(script.Parent.CommanderVehicle).model(s)
    elseif f=='motion'then return require(script.Parent.CommanderOrderFx).model(s)
    elseif f=='parachute'then
        local source=game.Players.LocalPlayer.Character
        if source and source:FindFirstChild('HumanoidRootPart')and (not M.avatar or M.avatar.source~=source)then
            if M.avatar and M.avatar.model then M.avatar.model:Destroy()end
            M.avatar={source=source,model=require(script.Parent.DropAvatar).clone(source)}
        end
        local own=source and M.avatar and M.avatar.source==source and M.avatar.model and M.avatar.model:Clone()
        if own then
            own.Name='Parachutist';require(script.Parent.DropAvatar).lockVisual(own)
            local rig=require(script.Parent.ParachuteRig).new(own,item.style,UI.colors.accent,own)
            local motion={visible=true,inflation=1,landed=false,time=0,speed=.4,steer=0,canopyPitch=0,canopyRoll=0,reducedEffects=true}
            rig:step(CFrame.identity,motion,true);own.WorldPivot=CFrame.identity
            return own,{rig=rig,motion=motion}
        end
        local avatar=Instance.new('Model');avatar.Name='Parachutist'
        local root=G.block(avatar,'HumanoidRootPart',Vector3.one*.1,CFrame.identity,UI.colors.ink);root.Transparency=1;avatar.PrimaryPart=root
        G.block(avatar,'Torso',Vector3.new(1.5,1.6,.7),CFrame.new(0,.4,0),UI.colors.raised)
        G.ball(avatar,'Helmet',Vector3.one*.95,CFrame.new(0,1.8,0),UI.colors.muted)
        for _,side in ipairs({-1,1})do
            G.block(avatar,'Arm',Vector3.new(.4,1.5,.45),CFrame.new(side*1,.55,0)*CFrame.Angles(0,0,side*-.32),UI.colors.muted)
            G.block(avatar,'Leg',Vector3.new(.55,1.5,.55),CFrame.new(side*.43,-1.05,0),UI.colors.raised)
        end
        G.rod(avatar,'FlagPole',Vector3.new(-1.2,-.4,.1),Vector3.new(-1.2,3.2,.1),.045,UI.colors.ice)
        G.block(avatar,'Flag',Vector3.new(1.3,.85,.05),CFrame.new(-.55,2.74,.1),UI.colors.accent)
        local rig=require(script.Parent.ParachuteRig).new(avatar,item.style,UI.colors.accent,avatar)
        local motion={visible=true,inflation=1,landed=false,time=0,speed=.4,steer=0,canopyPitch=0,canopyRoll=0,reducedEffects=true}
        rig:step(CFrame.identity,motion,true);avatar.WorldPivot=CFrame.identity
        return avatar,{rig=rig,motion=motion}
    end
end
local ROW_PITCH=Vector2.new(6.2,6.6)
function M.buildingRow(item,roles)
    local s=Catalog.get(item.style);local row=Instance.new('Model');row.Name='BuildingRow'
    local list={}
    for i,role in ipairs(roles)do
        local m=require(script.Parent.BuildingModels).create(role,s,2,true);m.Name=role;m.Parent=row;list[i]=m
    end
    row.WorldPivot=CFrame.identity
    return row,{row=list,cols=0}
end
local function layRow(extra,cols)
    if extra.cols==cols then return false end;extra.cols=cols
    local list=extra.row;local rows=math.ceil(#list/cols)
    for i,m in ipairs(list)do
        local c,r=(i-1)%cols,(i-1)//cols
        m:PivotTo(CFrame.new((c-(cols-1)/2)*ROW_PITCH.X,0,(r-(rows-1)/2)*ROW_PITCH.Y))
    end
    return true
end
function M.pod(tier)
    local model=Instance.new('Model');model.Name='SupplyPod';local series=require(script.Parent.Parent.Core.CollectionDefinitions).series[tier or 1]
    local s=Catalog.get(series.id..'_buildings');local c=Color3.fromRGB(table.unpack(s.accent));local dark=UI.colors.raised
    G.block(model,'ArmouredCase',Vector3.new(3.7,2.2,2.6),CFrame.new(0,1.2,0),dark)
    local lid=G.block(model,'Lid',Vector3.new(4,.35,2.8),CFrame.new(0,2.5,0),Color3.fromRGB(table.unpack(s.secondary)))
    for _,x in ipairs({-1.25,1.25})do
        G.block(model,'Band',Vector3.new(.18,2.2,2.64),CFrame.new(x,1.2,0),c)
        G.block(model,'Foot',Vector3.new(.65,.2,.85),CFrame.new(x,.05,0),UI.colors.muted)
    end
    local lock=G.block(model,'Seal',Vector3.new(.7,.7,.12),CFrame.new(0,1.4,1.36),c);lock.Material=Enum.Material.Neon
    model.WorldPivot=CFrame.identity;Art.apply(model,s,'pod',CFrame.new(0,.05,0),1.7)
    return model,lid
end
function M.visibleBounds(model)
    local lo,hi
    for _,p in ipairs(model:GetDescendants())do
        if p:IsA('BasePart')and p.Transparency<.95 then
            local cf,s=p.CFrame,p.Size*.5
            for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
                local v=cf*Vector3.new(s.X*x,s.Y*y,s.Z*z)
                lo=lo and lo:Min(v)or v;hi=hi and hi:Max(v)or v
            end end end
        end
    end
    if not lo then return model:GetBoundingBox()end
    return CFrame.new((lo+hi)/2),hi-lo
end
function M.create(parent,item,options)
    options=options or {};local frame=UI.make('ViewportFrame',parent,{Name=options.name or 'CollectionPreview',BackgroundTransparency=1,Ambient=Color3.fromRGB(148,162,185),LightColor=Color3.fromRGB(241,246,255),LightDirection=Vector3.new(-1,-2,-1)})
    local world=Instance.new('WorldModel');world.Parent=frame
    local model,extra
    if options.pod then model,extra=M.pod(options.tier)elseif options.crate then model=require(script.Parent.SupplyCrateArt).model(options.crate)elseif options.product then model=require(script.Parent.ProductArt).model(options.product)
    elseif options.roles and item and item.category=='buildings'then model,extra=M.buildingRow(item,options.roles);layRow(extra,3)
    else model,extra=M.model(item,options.role)end
    local row=type(extra)=='table'and extra.row or nil
    model.Parent=world
    if model:FindFirstChildOfClass('Humanoid')then require(script.Parent.DropAvatar).lockVisual(model)end
    local camera=Instance.new('Camera');camera.FieldOfView=34;camera.Parent=frame;frame.CurrentCamera=camera
    local bounds,size=M.visibleBounds(model);local center=bounds.Position;local reach=math.max(size.X,size.Y,size.Z)*1.65
    if options.crate then local d=math.sqrt(size.X^2+size.Z^2);size=Vector3.new(d,size.Y,d)end
    local direction=options.direction or row and Vector3.new(.25,.78,1).Unit or (item and item.category=='parachute')and Vector3.new(.3,.25,1).Unit or Vector3.new(.8,.72,1).Unit
    camera.CFrame=CFrame.lookAt(center+direction*reach,center)
    local context={frame=frame,world=world,model=model,camera=camera,extra=extra,item=item,base=model:GetPivot(),manual=options.manual,reduced=options.reduced,started=now,center=center,bounds=size,direction=direction,crate=options.crate,
        fill=options.crate and type(options.fill)=='number'and math.clamp(options.fill,.3,1)or nil}
    active[frame]=context
    frame.Destroying:Once(function()active[frame]=nil end)
    local cat=item and not(options.pod or options.crate or options.product)and item.category
    if row then
        local function refit()local b,sz=M.visibleBounds(model);context.center=b.Position;context.bounds=sz;context.viewSize=nil end
        for i,m in ipairs(row)do require(script.Parent.CosmeticMeshes).watchModel(item.style..'/'..options.roles[i],m,refit)end
        return frame,context
    end
    local key=cat and(cat=='buildings'and item.style..'/'..(options.role or 'City')or(cat=='nuclear'or cat=='vehicle'or cat=='parachute'or cat=='motion')and item.style)
    if key then require(script.Parent.CosmeticMeshes).watchModel(key,model,function()
        if cat=='motion'then
            local fresh=M.model(item,options.role);fresh:PivotTo(model:GetPivot());fresh.Parent=world;model:Destroy()
            model=fresh;context.model=fresh;context.base=CFrame.identity
        end
        local pivot=model:GetPivot();model:PivotTo(context.base)
        local b,sz=M.visibleBounds(model);context.center=b.Position;context.bounds=sz;context.viewSize=nil
        model:PivotTo(pivot)
    end)end
    return frame,context
end
function M.step(context,age,phase)
    local sz=context.frame.AbsoluteSize
    if sz.X>0 and sz.Y>0 and context.viewSize~=sz then
        context.viewSize=sz
        local extra=context.extra
        if type(extra)=='table'and extra.row then
            local aspect=sz.X/sz.Y;local n=#extra.row
            if layRow(extra,aspect>=2.4 and n or aspect>=1 and math.ceil(n/2)or math.min(n,2))then
                local b,bsz=M.visibleBounds(context.model);context.center=b.Position;context.bounds=bsz
            end
        end
        local d=context.direction;local right=d:Cross(Vector3.yAxis).Unit;local up=right:Cross(d).Unit
        local tanY=math.tan(math.rad(context.camera.FieldOfView/2));local tanX=tanY*sz.X/sz.Y;local distance=0
        if context.fill then
            local f=context.fill;local r=context.bounds.X*.5;local hy=context.bounds.Y*.5
            for i=0,23 do local a=i*math.pi/12;for _,y in ipairs({-1,1})do
                local corner=Vector3.new(math.cos(a)*r,y*hy,math.sin(a)*r);local depth=corner:Dot(d)
                distance=math.max(distance,math.abs(corner:Dot(up))/(tanY*f)+depth,math.abs(corner:Dot(right))/(tanX*f)+depth)
            end end
        else
            for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
                local corner=context.bounds*Vector3.new(x,y,z)*.5;local depth=corner:Dot(d)
                distance=math.max(distance,math.abs(corner:Dot(up))/tanY+depth,math.abs(corner:Dot(right))/tanX+depth)
            end end end
            distance*=context.zoom or 1.06
        end
        context.camera.CFrame=CFrame.lookAt(context.center+context.direction*distance,context.center)
    end
    local model=context.model;local reduced=context.reduced or game.Players.LocalPlayer:GetAttribute('CommanderReducedEffects')==true
    local flag=type(context.extra)=='table'and context.extra.flag or flags[model]
    if flag then
        local grip=flag.lastGrip or CFrame.identity;local pivot=model:GetPivot()
        if context.manual then if context.flagPivot and pivot~=context.flagPivot then grip=pivot*context.flagPivot:Inverse()*grip end
        else grip=CFrame.Angles(0,reduced and 0 or math.sin(age*.22)*.2,0)end
        flag:step(grip,age,0,model:GetScale(),0,nil,reduced,phase or 1+math.floor(age/2)%3);context.flagPivot=model:GetPivot()
    elseif context.extra and type(context.extra)=='table'and context.extra.rig then
        local motion=context.extra.motion;motion.time=age;motion.canopyRoll=reduced and 0 or math.sin(age*.8)*.035;motion.reducedEffects=true
        context.extra.rig:step(CFrame.identity,motion,true)
        Art.step(context.extra.rig.canopy,age,reduced,phase or 1+math.floor(age/2)%3)
    elseif type(context.extra)=='table'and context.extra.row then
        local ph=phase or 1+math.floor(age/2)%3;local Skins=require(script.Parent.BuildingRoleSkins)
        for _,m in ipairs(context.extra.row)do Art.step(m,age,reduced,ph);Skins.step(m,age,reduced)end
    else
        if not context.manual then model:PivotTo(context.base*CFrame.Angles(0,reduced and 0 or math.sin(age*.22)*.2,0))end
        Art.step(model,age,reduced,phase or 1+math.floor(age/2)%3)
        if context.crate and not context.manual then require(script.Parent.SupplyCrateArt).step(model,context.base,age,reduced)end
        if context.item and context.item.category=='buildings'then require(script.Parent.BuildingRoleSkins).step(model,age,reduced)end
        if context.item and context.item.category=='vehicle'then require(script.Parent.CommanderVehicle).step(model,age,reduced and 0 or 6,reduced,phase or 1+math.floor(age/2)%3)end
        if context.item and context.item.category=='commanderTrail'then
            require(script.Parent.TrailThemes).step(model,age,reduced,phase or 1+math.floor(age/2)%3)
        end
    end
end
M.sliceMs=3
local turn=0
local Probe=require(script.Parent.FrameProbe)
local stepShown
game:GetService('RunService').RenderStepped:Connect(function(dt)
    now+=dt
    local shown={}
    for frame,c in pairs(active)do if not frame.Parent then active[frame]=nil elseif not c.manual and visible(frame)then table.insert(shown,{frame=frame,c=c,area=frame.AbsoluteSize.X*frame.AbsoluteSize.Y})end end
    if #shown==0 then return end
    Probe.start('Preview');stepShown(shown);Probe.stop('Preview')
end)
stepShown=function(shown)
    table.sort(shown,function(a,b)return a.area>b.area end)
    local started=os.clock();M.step(shown[1].c,now-shown[1].c.started)
    local rest=#shown-1;if rest<=0 then return end
    turn=turn%rest
    for i=0,rest-1 do
        local e=shown[2+(turn+i)%rest]
        if (os.clock()-started)*1000>M.sliceMs then turn=(turn+i)%rest;return end
        M.step(e.c,now-e.c.started)
    end
end
function M.count()local n=0;for _ in pairs(active)do n+=1 end;return n end
function M.contextOf(frame)return active[frame]end
return M
