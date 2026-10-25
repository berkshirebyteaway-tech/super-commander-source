local UI=require(script.Parent.ToyUI)
local G=require(script.Parent.ToyGeometry)
local Audio=require(script.Parent.ToyAudio)
local Score=require(script.Parent.SupplyAudio)
local Preview=require(script.Parent.CollectionPreview)
local ShardGauge=require(script.Parent.ShardGauge)
local Art=require(script.Parent.CollectionArt)
local Launch=require(script.Parent.Parent.Core.LaunchCommerce)
local Rules=require(script.Parent.Parent.Core.SupplyLandingRules)
local Mesh=require(script.Parent.SupplyCrateMesh)
local Players=game:GetService('Players');local Run=game:GetService('RunService')
local Actions=game:GetService('ContextActionService');local Lighting=game:GetService('Lighting')
local Input=game:GetService('UserInputService')
local M={};local played={};local current;local stage
local rgb=Color3.fromRGB
local O=CFrame.new(5200,0,5200)
local grades=Mesh.grades
local steel,dark,trim,teal=rgb(44,54,68),rgb(24,30,39),rgb(70,84,100),rgb(54,226,208)
local olive,oliveTrim,amber=rgb(46,52,50),rgb(70,77,74),rgb(236,170,56)
local function sweep(f)return(Rules.mythicLight(f))end
local function prism(t,i)return Mesh.mythic(t,i)end
local gradeColor=Mesh.gradeColor
local rainbow=Mesh.rainbow
local function ease(u)u=math.clamp(u,0,1);return u*u*(3-2*u)end
local function lerp(a,b,u)return a+(b-a)*u end
local function glow(p,c)p.Material=Enum.Material.Neon;p.Color=c;p.CastShadow=false;return p end
local function attach(parent,pos)local a=Instance.new('Attachment');a.Position=pos or Vector3.zero;a.Parent=parent;return a end
local function emitter(parent,props)local e=Instance.new('ParticleEmitter');e.Enabled=false;for k,v in pairs(props)do e[k]=v end;e.Parent=parent;return e end

local function buildStage()
    local m=Instance.new('Model');m.Name='SupplyLandingStage'
    local function b(name,size,cf,color,mat)
        local p=G.block(m,name,size,O*cf,color);p.Material=mat or Enum.Material.Metal;p.CastShadow=false;return p
    end
    b('Apron',Vector3.new(1400,1,1400),CFrame.new(0,-.5,0),rgb(17,21,28),Enum.Material.Concrete)
    b('Runway',Vector3.new(46,.06,620),CFrame.new(0,.03,-340),rgb(24,29,37),Enum.Material.Asphalt)
    for i=1,26 do b('RunwayMark',Vector3.new(1.2,.04,9),CFrame.new(0,.08,-44-i*22),rgb(78,92,108),Enum.Material.SmoothPlastic)end
    for i=0,24 do for _,s in ipairs({-1,1})do glow(b('EdgeLight',Vector3.new(.5,.35,.5),CFrame.new(s*24,.18,-34-i*24),teal),i%2==0 and teal or rgb(191,239,255))end end
    local pad=G.cylinder(m,'Pad',22,.4,O*CFrame.new(0,.2,0),rgb(33,41,52));pad.Material=Enum.Material.DiamondPlate;pad.CastShadow=false
    local rim=G.cylinder(m,'PadRim',22.7,.22,O*CFrame.new(0,.12,0),teal);glow(rim,teal).Transparency=.35
    G.cylinder(m,'PadRing',14,.42,O*CFrame.new(0,.22,0),rgb(56,68,84)).CastShadow=false
    G.cylinder(m,'PadInner',13.3,.44,O*CFrame.new(0,.23,0),rgb(33,41,52)).CastShadow=false
    for i=0,15 do local a=i/16*math.pi*2
        glow(b('PadLight',Vector3.new(.55,.3,.55),CFrame.new(math.cos(a)*20.6,.48,math.sin(a)*20.6),teal),i%4==0 and rgb(191,239,255)or teal)
    end
    for _,a in ipairs({0,math.pi/2})do b('PadCross',Vector3.new(15,.05,1.1),CFrame.Angles(0,a,0)+Vector3.new(0,.45,0),rgb(50,60,74),Enum.Material.Concrete)end
    for i=-5,5 do local a=math.pi/2+i*.12
        b('BlastWall',Vector3.new(9.4,6,1.6),CFrame.new(math.cos(a)*64,3,math.sin(a)*64)*CFrame.Angles(0,-a+math.pi/2,0),rgb(30,37,47),Enum.Material.Concrete)
    end
    for _,x in ipairs({-92,92})do
        b('Hangar',Vector3.new(64,22,44),CFrame.new(x,11,128),rgb(26,32,41))
        b('HangarRoof',Vector3.new(66,3,46),CFrame.new(x,23,128)*CFrame.Angles(0,0,x>0 and .06 or -.06),rgb(36,44,56))
        glow(b('HangarDoorSlit',Vector3.new(40,.5,.3),CFrame.new(x,9,105.8),rgb(255,207,120)),rgb(255,207,120)).Transparency=.25
    end
    local mast=b('RadarMast',Vector3.new(1.2,34,1.2),CFrame.new(-52,17,74),trim)
    glow(b('MastBeacon',Vector3.new(1,1,1),CFrame.new(-52,34.6,74),rgb(255,72,72)),rgb(255,72,72))
    local beacon=Instance.new('PointLight');beacon.Color=rgb(255,72,72);beacon.Range=14;beacon.Brightness=1.4;beacon.Parent=mast
    b('RadarDish',Vector3.new(7,.5,2.4),CFrame.new(-52,31,74),rgb(56,68,84))
    for _,x in ipairs({-30,30})do
        b('FloodTower',Vector3.new(.9,17,.9),CFrame.new(x,8.5,34),trim)
        local head=glow(b('FloodHead',Vector3.new(3,1.4,1),CFrame.new(x,17.4,33.4)*CFrame.Angles(-.5,0,0),rgb(232,240,255)),rgb(232,240,255))
        local s=Instance.new('SpotLight');s.Face=Enum.NormalId.Front;s.Angle=70;s.Range=70;s.Brightness=1.9;s.Color=rgb(222,232,248);s.Shadows=true;s.Parent=head
        head.CFrame=CFrame.lookAt(head.Position,(O*CFrame.new(x*-.15,0,-4)).Position)
    end
    m:SetAttribute('AppearanceOnly',true)
    return m
end

local function blockCrate()
    local c=Instance.new('Model');c.Name='SupplyCrate'
    local root=G.block(c,'Root',Vector3.one*.2,CFrame.new(),dark);root.Transparency=1;c.PrimaryPart=root
    local parts={root=root,seams={},lamps={},doors={}}
    G.part(c,'Body',Vector3.new(6,4.2,4.4),CFrame.new(0,2.35,0),olive,'armor').Material=Enum.Material.Metal
    for _,x in ipairs({-2.95,2.95})do for _,z in ipairs({-2.15,2.15})do G.block(c,'Post',Vector3.new(.5,4.7,.5),CFrame.new(x,2.35,z),oliveTrim).Material=Enum.Material.Metal end end
    for _,y in ipairs({.35,4.4})do G.block(c,'Rail',Vector3.new(6.5,.42,4.9),CFrame.new(0,y,0),oliveTrim).Material=Enum.Material.Metal
        G.block(c,'HazardTrim',Vector3.new(6.2,.12,.06),CFrame.new(0,y,-2.47),amber).CastShadow=false end
    for _,z in ipairs({-1.5,1.5})do G.block(c,'Skid',Vector3.new(6.8,.3,.7),CFrame.new(0,.08,z),dark)end
    for _,x in ipairs({-3.22,3.22})do
        local band=G.block(c,'SideBand',Vector3.new(.12,3.5,4.0),CFrame.new(x,2.35,0),rgb(40,46,44));band.Material=Enum.Material.Metal
        G.label(band,'SUPPLY',rgb(226,196,128),x>0 and Enum.NormalId.Right or Enum.NormalId.Left,64)
    end
    for _,x in ipairs({-2.7,2.7})do table.insert(parts.seams,glow(G.block(c,'Seam',Vector3.new(.1,3.7,.1),CFrame.new(x,2.35,-2.42),grades[1]),grades[1]))end
    table.insert(parts.seams,glow(G.block(c,'TopSeam',Vector3.new(5.6,.1,.1),CFrame.new(0,4.18,-2.42),grades[1]),grades[1]))
    for i,side in ipairs({-1,1})do
        local hinge=CFrame.new(side*2.9,2.3,-2.36)
        local door=G.block(c,'Door',Vector3.new(2.84,3.7,.28),hinge*CFrame.new(-side*1.44,0,0),rgb(54,61,58));door.Material=Enum.Material.Metal
        local rib=G.block(c,'DoorRib',Vector3.new(2.2,.22,.12),hinge*CFrame.new(-side*1.44,-1.2,-.16),oliveTrim)
        parts.doors[i]={part=door,hinge=hinge,side=side,home=hinge:ToObjectSpace(door.CFrame),rib=rib,ribHome=hinge:ToObjectSpace(rib.CFrame)}
    end
    parts.plate=G.block(c,'SealPlate',Vector3.new(4.4,.95,.2),CFrame.new(0,3.3,-2.6),dark)
    for i=1,4 do
        local lamp=G.cylinder(c,'SealLamp',.3,.16,CFrame.new(1.65-(i-1)*1.1,3.3,-2.74)*CFrame.Angles(math.pi/2,0,0),rgb(40,48,58))
        lamp.Material=Enum.Material.SmoothPlastic;lamp.CastShadow=false;parts.lamps[i]=lamp
    end
    parts.inner=glow(G.block(c,'InnerGlow',Vector3.new(5.3,3.5,3.6),CFrame.new(0,2.35,.1),grades[1]),grades[1]);parts.inner.Transparency=1
    parts.light=Instance.new('PointLight');parts.light.Range=16;parts.light.Brightness=0;parts.light.Shadows=false;parts.light.Parent=parts.inner
    parts.smoke=emitter(root,{Color=ColorSequence.new(grades[1]),LightEmission=.25,Lifetime=NumberRange.new(1.1,1.7),Rate=34,
        Speed=NumberRange.new(1,3),Size=NumberSequence.new({NumberSequenceKeypoint.new(0,1.6),NumberSequenceKeypoint.new(1,5.5)}),
        Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.35),NumberSequenceKeypoint.new(1,1)}),SpreadAngle=Vector2.new(18,18),EmissionDirection=Enum.NormalId.Top})
    c.WorldPivot=CFrame.identity
    return c,parts
end

local function buildCrate(kind)
    local m,c=Mesh.cineCrate(kind,dark,glow,emitter,{Color=ColorSequence.new(grades[1]),LightEmission=.25,Lifetime=NumberRange.new(1.1,1.7),Rate=34,
        Speed=NumberRange.new(1,3),Size=NumberSequence.new({NumberSequenceKeypoint.new(0,1.6),NumberSequenceKeypoint.new(1,5.5)}),
        Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.35),NumberSequenceKeypoint.new(1,1)}),SpreadAngle=Vector2.new(18,18),EmissionDirection=Enum.NormalId.Top})
    if m then return m,c end
    return blockCrate()
end

local function blockChute(crateRoot)
    local m=Instance.new('Model');m.Name='SupplyChute'
    local hub=G.block(m,'Hub',Vector3.one*.3,CFrame.new(),dark);hub.Transparency=1;m.PrimaryPart=hub
    local gores={}
    for i=0,7 do local a=i/8*math.pi*2
        local g=G.block(m,'Gore',Vector3.new(4.4,.28,6.2),CFrame.Angles(0,a,0)*CFrame.new(0,-1.1,-4.3)*CFrame.Angles(.55,0,0),grades[1])
        g.Material=Enum.Material.Fabric;g.CastShadow=false;gores[#gores+1]=g
    end
    local vent=G.ball(m,'Vent',Vector3.new(2.6,1.2,2.6),CFrame.new(0,.3,0),dark);vent.CastShadow=false
    local lines={}
    for _,x in ipairs({-2.6,2.6})do for _,z in ipairs({-1.9,1.9})do
        local a0=attach(crateRoot,Vector3.new(x,4.6,z));local a1=attach(hub,Vector3.new(x*1.9,-2.6,z*2.6))
        local beam=Instance.new('Beam');beam.Attachment0=a0;beam.Attachment1=a1;beam.Width0=.06;beam.Width1=.06;beam.FaceCamera=true
        beam.Color=ColorSequence.new(rgb(150,166,184));beam.LightInfluence=1;beam.Parent=m;lines[#lines+1]=beam
    end end
    m.WorldPivot=CFrame.identity
    return m,gores,lines,vent
end

local function buildChute(crateRoot,cp)
    local m,gores,trims,hub=Mesh.chute()
    if not m then local bm,g,l,v=blockChute(crateRoot);return bm,g,l,{v},11.8 end
    local lines={}
    local points=cp.anchors and cp.anchors.chute
    for _,a in ipairs(points or {{-2.6,4.6,-1.9},{2.6,4.6,-1.9},{-2.6,4.6,1.9},{2.6,4.6,1.9}})do
        local at=Vector3.new(a[1],a[2],a[3])
        local a0=attach(crateRoot,at);local a1=attach(hub,Mesh.lineTop(at))
        local beam=Instance.new('Beam');beam.Attachment0=a0;beam.Attachment1=a1;beam.Width0=.06;beam.Width1=.06;beam.FaceCamera=true
        beam.Color=ColorSequence.new(rgb(150,166,184));beam.LightInfluence=1;beam.Parent=m;lines[#lines+1]=beam
    end
    return m,gores,lines,trims,Mesh.chuteLift
end

local function blockAircraft(kind)
    local m=Instance.new('Model');m.Name='SupplyAircraft';local lights={}
    local body=rgb(84,94,110)
    if kind=='stealth'then
        for _,s in ipairs({-1,1})do
            G.block(m,'Wing',Vector3.new(34,1.3,11),CFrame.Angles(0,s*.62,0)*CFrame.new(s*15,0,4),rgb(20,24,31)).Material=Enum.Material.Metal
            lights[#lights+1]=glow(G.block(m,'TrailingEdge',Vector3.new(30,.3,.4),CFrame.Angles(0,s*.62,0)*CFrame.new(s*15,0,9.6),grades[5]),grades[5])
        end
        G.block(m,'Spine',Vector3.new(6,2.4,16),CFrame.new(0,.6,0),rgb(24,29,37)).Material=Enum.Material.Metal
    elseif kind=='fighter'then
        G.block(m,'Fuselage',Vector3.new(1.8,1.4,15),CFrame.new(),body).Material=Enum.Material.Metal
        for _,s in ipairs({-1,1})do
            G.block(m,'Wing',Vector3.new(8,.35,5.5),CFrame.new(s*4,0,2.5)*CFrame.Angles(0,s*-.45,0),body).Material=Enum.Material.Metal
            G.block(m,'Fin',Vector3.new(.3,2.6,2.6),CFrame.new(s*.8,1.4,6)*CFrame.Angles(0,0,s*.3),body)
        end
        lights[#lights+1]=glow(G.block(m,'Afterburner',Vector3.new(1.2,1.2,.8),CFrame.new(0,0,7.8),grades[4]),grades[4])
    else
        G.cylinder(m,'Fuselage',3.1,46,CFrame.Angles(math.pi/2,0,0),body).Material=Enum.Material.Metal
        G.ball(m,'Nose',Vector3.new(6.2,6.2,8),CFrame.new(0,0,-23),body).Material=Enum.Material.Metal
        G.block(m,'Wing',Vector3.new(66,1,9),CFrame.new(0,2.4,-2),body).Material=Enum.Material.Metal
        G.block(m,'Tailplane',Vector3.new(22,.8,5),CFrame.new(0,2,21),body).Material=Enum.Material.Metal
        G.block(m,'Fin',Vector3.new(1,10,7),CFrame.new(0,7,20),body).Material=Enum.Material.Metal
        for _,x in ipairs({-22,-12,12,22})do G.cylinder(m,'Engine',1.25,5.5,CFrame.new(x,.9,-3.5)*CFrame.Angles(math.pi/2,0,0),rgb(36,43,54))end
        glow(G.block(m,'WingtipRed',Vector3.new(.6,.6,.6),CFrame.new(-33,2.4,-2),rgb(255,72,72)),rgb(255,72,72))
        glow(G.block(m,'WingtipGreen',Vector3.new(.6,.6,.6),CFrame.new(33,2.4,-2),rgb(72,255,140)),rgb(72,255,140))
        lights[#lights+1]=glow(G.block(m,'TailLight',Vector3.new(1.6,1.6,1.6),CFrame.new(0,12.2,23),grades[1]),grades[1])
        lights[#lights+1]=glow(G.block(m,'TailStripe',Vector3.new(.4,6,.4),CFrame.new(0,7.5,23.6),grades[1]),grades[1])
        lights[#lights+1]=glow(G.block(m,'BellyBeacon',Vector3.new(1.2,.5,1.2),CFrame.new(0,-3.1,0),grades[1]),grades[1])
        G.block(m,'RampOpen',Vector3.new(4.6,.4,7),CFrame.new(0,-2.6,25)*CFrame.Angles(.35,0,0),rgb(36,43,54))
    end
    for _,p in ipairs(m:GetDescendants())do if p:IsA('BasePart')then p.CastShadow=false end end
    local core=m:FindFirstChildWhichIsA('BasePart');local fill=Instance.new('PointLight');fill.Range=kind=='fighter'and 18 or 46;fill.Brightness=kind=='stealth'and .3 or 2.2;fill.Color=rgb(206,222,245);fill.Shadows=false;fill.Parent=core
    m.WorldPivot=CFrame.identity
    return m,lights
end

local function hideHud(keep)
    local hidden={}
    for _,g in ipairs(Players.LocalPlayer.PlayerGui:GetChildren())do
        if g:IsA('ScreenGui')and g.Enabled and not keep[g.Name]then g.Enabled=false;table.insert(hidden,g)end
    end
    return hidden
end

local function buildAircraft(kind)
    local m,lights,extra=Mesh.aircraft(kind)
    if m then
        local core=m:FindFirstChild('Body');local fill=Instance.new('PointLight');fill.Range=kind=='fighter'and 18 or 46;fill.Brightness=kind=='stealth'and .3 or 2.2;fill.Color=rgb(206,222,245);fill.Shadows=false;fill.Parent=core
        return m,lights,extra
    end
    return blockAircraft(kind)
end

function M.playing()return current~=nil end
function M.stop()
    local s=current;if not s then return end;current=nil
    pcall(function()Run:UnbindFromRenderStep('SupplyCinematic')end)
    Actions:UnbindAction('SupplyCinematicHold');Actions:UnbindAction('SupplyCinematicSink')
    for _,c in ipairs(s.connections)do c:Disconnect()end
    local camera=workspace.CurrentCamera
    if camera then camera.CameraType=s.saved.type;camera.CameraSubject=s.saved.subject;camera.FieldOfView=s.saved.fov;if s.saved.type==Enum.CameraType.Scriptable then camera.CFrame=s.saved.cf end end
    for _,g in ipairs(s.hidden)do if g.Parent then g.Enabled=true end end
    if s.touch~=nil then game:GetService('GuiService').TouchControlsEnabled=s.touch end
    for _,o in ipairs(s.cleanup)do if o then o:Destroy()end end
    if stage then stage.Parent=nil end
    for _,key in ipairs({'supplyDelivery','supplySeal','request','supply_normal','supply_rare','supply_epic','supply_legendary','supply_mythic'})do Audio.stop(key)end;Score.stop()
    task.defer(function()
        local me=Players.LocalPlayer;if current or me:GetAttribute('FrontierRoom')then return end
        if require(script.Parent.LobbyIntro).active or require(script.Parent.LobbyShowcase).active then return end
        local P=require(script.Parent.Parent.Core.PlazaLayout);local cam=workspace.CurrentCamera;if not cam then return end
        local target=Vector3.new(P.x,P.y+4.5,P.z+P.spawnZ);local hum=me.Character and me.Character:FindFirstChildOfClass('Humanoid')
        cam.CameraType=Enum.CameraType.Custom;cam.CameraSubject=hum;cam.FieldOfView=60
        me.CameraMinZoomDistance=26;me.CameraMaxZoomDistance=26;cam.CFrame=CFrame.lookAt(target+Vector3.new(0,6.6,25.1),target);cam.Focus=CFrame.new(target)
        task.delay(.3,function()if not current then me.CameraMinZoomDistance=P.minZoom;me.CameraMaxZoomDistance=P.maxZoom end end)
    end)
end

function M.play(shop,result,item,onDone)
    local player=Players.LocalPlayer;local camera=workspace.CurrentCamera
    if not camera or not result or player:GetAttribute('FrontierRoom')then return false end
    local key=tostring(result.requestId or result.serial or result.id)
    if played[key]then return false end;played[key]=true
    M.stop()
    local prefs=(shop and shop.account and shop.account.preferences)or {}
    local reduced=prefs.reducedEffects==true or player:GetAttribute('CommanderReducedEffects')==true
    local shake=not reduced and prefs.cameraShake~=false;local flashes=not reduced and prefs.mapFlashes~=false
    local plan=Rules.floor(Rules.pick(result.rarity,key),result.kind);local tier=plan.tier
    local skippable=not Rules.unskippable(result)
    local L=Rules.ladder;local has=Rules.features(tier);local category=item.category
    local phone=Input.TouchEnabled and not Input.MouseEnabled
    if not stage then stage=buildStage()end;stage.Parent=workspace
    local s={connections={},cleanup={},saved={type=camera.CameraType,subject=camera.CameraSubject,cf=camera.CFrame,fov=camera.FieldOfView},hidden=hideHud({SupplyCinematic=true,SupplyReveal=true})}
    s.touch=game:GetService('GuiService').TouchControlsEnabled;game:GetService('GuiService').TouchControlsEnabled=false
    current=s
    local function own(o)table.insert(s.cleanup,o);return o end
    Mesh.prefetch()
    local crate,cp=buildCrate(result.kind);own(crate).Parent=workspace
    local chute,gores,lines,trims,chuteLift=buildChute(cp.root,cp);own(chute).Parent=workspace
    local meshChute=chuteLift~=11.8
    local planeKind=plan.stealth and 'stealth'or 'transport'
    local plane,planeLights,planeExtra=buildAircraft(planeKind);own(plane).Parent=workspace
    local escorts={}
    if plan.escort and not plan.stealth then for _,side in ipairs({-1,1})do local f,l,x=buildAircraft('fighter');own(f).Parent=workspace;table.insert(escorts,{model=f,side=side,lights=l,mesh=x~=nil})end end
    if planeExtra then Mesh.paintLights(planeLights,plan.plane,0,-1)else for _,p in ipairs(planeLights)do p.Color=gradeColor(plan.plane)end end
    local avatarPos=Vector3.new(8,0,30)
    pcall(function()
        local source=player.Character;if not(source and source:FindFirstChild('HumanoidRootPart'))then return end
        local Drop=require(script.Parent.DropAvatar);local a=Drop.clone(source);if not a then return end
        own(a).Parent=workspace;Drop.lockVisual(a)
        a:PivotTo(O*CFrame.lookAt(avatarPos,Vector3.new(0,0,0)));local cf,size=a:GetBoundingBox()
        a:PivotTo(a:GetPivot()+Vector3.new(0,O.Y-(cf.Y-size.Y/2),0))
        s.avatar=a;s.avatarLift=a:GetPivot().Y-O.Y;s.avatarParts={}
        for _,p in ipairs(a:GetDescendants())do if p:IsA('BasePart')then table.insert(s.avatarParts,p)end end
    end)
    local model,extra=Preview.model(item);own(model)
    local itemSize=4;local itemOffset=CFrame.identity;local itemHeight=4;local itemScale=1;local rigMid,rigHalf=0,0
    do
        model:PivotTo(CFrame.identity);local _,size=Preview.visibleBounds(model);local big=math.max(size.X,size.Y,size.Z)
        if not(extra and extra.rig)and big>0 then local k=math.clamp(4.6/big,.4,3.2);pcall(function()model:ScaleTo(model:GetScale()*k)end);itemSize=big*k;itemScale=k else itemSize=big end
        if not(extra and extra.rig)then model:PivotTo(CFrame.identity);local bcf,bsize=Preview.visibleBounds(model);itemOffset=CFrame.new(-bcf.X,-(bcf.Y-bsize.Y/2),-bcf.Z);itemHeight=bsize.Y end
        if extra and extra.rig then local bcf,bsize=Preview.visibleBounds(model);rigMid=bcf.Y;rigHalf=bsize.Y/2 end
        if model:FindFirstChildOfClass('Humanoid')then require(script.Parent.DropAvatar).lockVisual(model)end
    end
    local demo={scale=model:GetScale(),tiles={},edges={}}
    if category=='territory'then
        for _,p in ipairs(model:GetChildren())do if p:IsA('BasePart')then
            local at=p.Position/(.95*itemScale)
            if p.Name=='Land'then table.insert(demo.tiles,{part=p,ring=math.floor(math.max(math.abs(at.X),math.abs(at.Z))+.5),color=p.Color})
            elseif p.Name=='Frontier'or p.Name=='FrontierPost'then table.insert(demo.edges,{part=p,post=p.Name=='FrontierPost'})end
        end end
    elseif category=='nuclear'then
        pcall(function()require(script.Parent.NukeFx).setReduced(model,reduced)end)
        demo.trails={};for _,t in ipairs(model:GetDescendants())do if t:IsA('Trail')then table.insert(demo.trails,{trail=t,on=t.Enabled});t.Enabled=false end end
    end
    local itemContext={frame={AbsoluteSize=Vector2.zero},model=model,item=item,manual=true,reduced=reduced}
    local ring=own(G.cylinder(nil,'ShockRing',1,.12,O*CFrame.new(0,.5,0),grades[1]));glow(ring,grades[1]);ring.Transparency=1;ring.Parent=workspace
    local function fadeRing()if s.ringAt then local k2=math.clamp((os.clock()-s.ringClock)/.5,0,1);local r=lerp(6,20,k2);ring.Size=Vector3.new(.12,r,r);ring.CFrame=O*CFrame.new(0,.5,0)*CFrame.Angles(0,0,math.pi/2);ring.Transparency=lerp(.2,1,k2);if k2>=1 then s.ringAt=nil end end end
    local dustAt=own(G.block(workspace,'DustSource',Vector3.one*.2,O*CFrame.new(0,.4,0),dark));dustAt.Transparency=1
    local dust=emitter(dustAt,{Color=ColorSequence.new(rgb(120,132,150)),LightEmission=.1,Lifetime=NumberRange.new(.8,1.5),Speed=NumberRange.new(10,18),
        Size=NumberSequence.new({NumberSequenceKeypoint.new(0,1.2),NumberSequenceKeypoint.new(1,4)}),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.45),NumberSequenceKeypoint.new(1,1)}),
        SpreadAngle=Vector2.new(80,8),EmissionDirection=Enum.NormalId.Top,Drag=4})
    local flare=own(G.ball(workspace,'Flare',Vector3.one*.9,O*CFrame.new(0,-10,0),grades[4]));glow(flare,grades[4]);flare.Transparency=1
    local flareLight=Instance.new('PointLight');flareLight.Range=40;flareLight.Brightness=0;flareLight.Color=grades[4];flareLight.Parent=flare
    local pillar=own(G.cylinder(workspace,'GradePillar',1.7,420,O*CFrame.new(0,210,0),grades[1]));glow(pillar,grades[1]);pillar.Transparency=1
    local aurora={}
    if tier>=5 then for i=1,reduced and 3 or 6 do
        local a=(i-3.5)*.26;local slab=own(G.block(workspace,'Aurora',Vector3.new(34,84,.2),O*CFrame.new(math.sin(a)*150,62,math.cos(a)*150)*CFrame.Angles(0,a,0),dark))
        slab.Transparency=1;slab.CastShadow=false
        local sg=Instance.new('SurfaceGui');sg.Face=Enum.NormalId.Front;sg.LightInfluence=0;sg.Brightness=2.2;sg.CanvasSize=Vector2.new(64,160);sg.Parent=slab
        local cols={};local edge={.75,.45,.2,.2,.45,.75}
        for c=1,#edge do
            local sheet=Instance.new('Frame');sheet.Size=UDim2.fromScale(1/#edge,1);sheet.Position=UDim2.fromScale((c-1)/#edge,0);sheet.BorderSizePixel=0;sheet.BackgroundColor3=grades[5];sheet.BackgroundTransparency=1;sheet.Parent=sg
            local fall=Instance.new('UIGradient');fall.Rotation=90;fall.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.2),NumberSequenceKeypoint.new(.75,.7),NumberSequenceKeypoint.new(1,1)});fall.Parent=sheet
            cols[c]={frame=sheet,edge=edge[c]}
        end
        aurora[i]={part=slab,a=a,cols=cols}
    end end
    local lightAnchor=own(G.block(workspace,'ItemLight',Vector3.one*.2,O*CFrame.new(0,-20,0),dark));lightAnchor.Transparency=1
    local itemLight=Instance.new('PointLight');itemLight.Range=10;itemLight.Brightness=0;itemLight.Shadows=false;itemLight.Parent=lightAnchor
    local fxAnchor=own(G.block(workspace,'RevealFx',Vector3.new(math.max(2,itemSize*.9),.2,math.max(2,itemSize*.9)),O*CFrame.new(0,-20,0),dark));fxAnchor.Transparency=1
    local revealFx={}
    for _,e in ipairs(Rules.particles)do if tier>=e.from then
        local rate=(phone and e.phone or e.pc)*(reduced and .4 or 1)
        local props
        if e.name=='Sparks'then props={Color=tier>=5 and rainbow or ColorSequence.new(gradeColor(tier)),LightEmission=1,Lifetime=NumberRange.new(1.2,e.life),
            Speed=NumberRange.new(4,8),Drag=1.6,Acceleration=Vector3.new(0,-3,0),SpreadAngle=Vector2.new(35,35),EmissionDirection=Enum.NormalId.Top,
            Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(1,0)})}
        elseif e.name=='Motes'then props={Color=ColorSequence.new(UI.colors.gold),LightEmission=.9,Lifetime=NumberRange.new(1.8,e.life),
            Speed=NumberRange.new(.5,1.5),Acceleration=Vector3.new(0,.8,0),SpreadAngle=Vector2.new(60,60),EmissionDirection=Enum.NormalId.Top,RotSpeed=NumberRange.new(-60,60),
            Size=NumberSequence.new(.22),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,.15),NumberSequenceKeypoint.new(1,1)})}
        else props={Color=rainbow,LightEmission=1,Lifetime=NumberRange.new(1.6,e.life),Speed=NumberRange.new(2,5),Drag=.8,SpreadAngle=Vector2.new(180,180),
            Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-120,120),Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.32),NumberSequenceKeypoint.new(1,.05)})}end
        props.Rate=rate;table.insert(revealFx,emitter(fxAnchor,props))
    end end
    local shards={}
    if has.shatter then for i=1,10 do
        local p=own(G.block(workspace,'GoldShard',Vector3.new(.5,.36,.08),O*CFrame.new(0,-20,0),UI.colors.gold));glow(p,UI.colors.gold);p.Transparency=1
        local a=(i/10)*math.pi*2;shards[i]={part=p,dir=Vector3.new(math.cos(a)*1.4,1.2+math.sin(a*3)*.6,-2.2-math.abs(math.sin(a))),spin=(i%2==0 and 1 or -1)*(4+i*.3)}
    end end
    local grade=Instance.new('ColorCorrectionEffect');grade.Name='SupplyCinematicGrade';grade.Brightness=-.04;grade.Contrast=.1;grade.Parent=Lighting;own(grade)
    local serialPlate
    if result.serial and has.serial then
        serialPlate=own(G.block(workspace,'SerialPlate',Vector3.new(3.8,.85,.12),O*CFrame.new(0,-20,0),rgb(64,76,92)));serialPlate.Material=Enum.Material.Metal
        local gui=G.label(serialPlate,result.serial,grades[tier],Enum.NormalId.Front,58);gui.LightInfluence=0
        for _,d in ipairs(gui:GetDescendants())do if d:IsA('TextLabel')then d.AutoLocalize=false end end
    end
    local gui=own(UI.make('ScreenGui',player.PlayerGui,{Name='SupplyCinematic',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=74,ZIndexBehavior=Enum.ZIndexBehavior.Sibling}))
    require(script.Parent.FullBleed).watch(gui)
    require(script.Parent.Localization).bind(gui)
    local shield=UI.make('TextButton',gui,{Name='HoldShield',Text='',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,AutoButtonColor=false})
    local bars={}
    for i,anchor in ipairs({0,1})do bars[i]=UI.make('Frame',gui,{Name='Letterbox',AnchorPoint=Vector2.new(0,anchor),Position=UDim2.fromScale(0,anchor),Size=UDim2.fromScale(1,0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0})end
    local caption=UI.label(gui,'Beat','',15,UI.colors.muted);caption.AnchorPoint=Vector2.new(.5,0);caption.Position=UDim2.new(.5,0,.06,0);caption.Size=UDim2.fromOffset(420,26);caption.TextXAlignment=Enum.TextXAlignment.Center
    caption.TextStrokeTransparency=.55
    local gradeLabel=UI.label(gui,'Grade','',34,grades[1]);gradeLabel.AnchorPoint=Vector2.new(.5,1);gradeLabel.Position=UDim2.new(.5,0,.8,0);gradeLabel.Size=UDim2.fromOffset(520,42);gradeLabel.TextXAlignment=Enum.TextXAlignment.Center;gradeLabel.TextTransparency=1;gradeLabel.TextStrokeTransparency=.4
    local nameLabel=UI.label(gui,'ItemName',item.name,20,UI.colors.ink);nameLabel.AnchorPoint=Vector2.new(.5,0);nameLabel.Position=UDim2.new(.5,0,.8,4);nameLabel.Size=UDim2.fromOffset(520,28);nameLabel.TextXAlignment=Enum.TextXAlignment.Center;nameLabel.TextTransparency=1;nameLabel.TextStrokeTransparency=.5
    local hold=UI.make('Frame',gui,{Name='SealGauge',AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,.9,0),Size=UDim2.fromOffset(4*58-8,48),BackgroundTransparency=1,Visible=false})
    local hint=UI.label(hold,'Hint','길게 눌러 열기',13,UI.colors.ink);UI.box(hint,-60,0,4*58-8+120,20);hint.TextXAlignment=Enum.TextXAlignment.Center;hint.TextStrokeTransparency=.5
    local fills={}
    for i=1,4 do
        local slot=UI.corner(UI.make('Frame',hold,{Name='Seal'..i,BackgroundColor3=rgb(30,37,47),BorderSizePixel=0}),2);UI.box(slot,(i-1)*58,30,50,8);UI.stroke(slot,UI.colors.line,1)
        fills[i]=UI.corner(UI.make('Frame',slot,{Name='Fill',BackgroundColor3=UI.colors.ink,BorderSizePixel=0,Size=UDim2.fromScale(0,1)}),2)
    end
    local skip=UI.button(gui,'Skip','건너뛰기',function()if current==s then s.skipRequested=true end end);skip.AnchorPoint=Vector2.new(1,0);skip.Position=UDim2.new(1,-16,0,16);skip.Size=UDim2.fromOffset(104,40);skip.TextSize=13;skip.BackgroundTransparency=.35;skip.Visible=false
    local hud=player.PlayerGui:FindFirstChild('FrontierNativeUI');hud=hud and hud:FindFirstChild('Main');hud=hud and hud:FindFirstChildOfClass('UIScale')
    for _,o in ipairs({caption,gradeLabel,nameLabel,hold,skip})do UI.make('UIScale',o,{Name='Scale20',Scale=math.max(1,hud and hud.Scale or UI.scale or 1)})end
    local edges={}
    if has.vignette then for i,spec in ipairs({{0,0,1,.18,90},{0,1,1,.18,-90},{0,0,.12,1,0},{1,0,.12,1,180}})do
        local f=UI.make('Frame',gui,{Name='GradeEdge',AnchorPoint=Vector2.new(spec[1],spec[2]),Position=UDim2.fromScale(spec[1],spec[2]),Size=UDim2.fromScale(spec[3],spec[4]),BackgroundColor3=grades[1],BackgroundTransparency=1,BorderSizePixel=0,ZIndex=0})
        UI.make('UIGradient',f,{Rotation=spec[5],Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})});edges[i]=f
    end end
    local flash
    if has.prismFlash then
        flash=UI.make('Frame',gui,{Name='PrismFlash',Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=5})
        UI.make('UIGradient',flash,{Color=rainbow,Rotation=35})
    end
    local stamp=UI.label(gui,'DuplicateStamp','중복',30,rgb(176,186,198));stamp.AnchorPoint=Vector2.new(.5,0);stamp.Position=UDim2.new(.5,0,.8,34);stamp.Size=UDim2.fromOffset(160,40)
    stamp.TextXAlignment=Enum.TextXAlignment.Center;stamp.Rotation=-6;stamp.TextTransparency=1;stamp.TextStrokeTransparency=1
    local counter=UI.label(gui,'RefundCounter','',22,UI.colors.gold);counter.AnchorPoint=Vector2.new(1,0);counter.Position=UDim2.new(1,-24,0,70);counter.Size=UDim2.fromOffset(260,32)
    counter.TextXAlignment=Enum.TextXAlignment.Right;counter.TextTransparency=1;counter.TextStrokeTransparency=1
    local coins={}
    local function press(down)
        if down then s.holding=true;s.pressAt=s.clock
        else if s.holding and s.clock-(s.pressAt or s.clock)<.2 then s.auto=true end;s.holding=false end
    end
    table.insert(s.connections,shield.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then press(true)end end))
    table.insert(s.connections,shield.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then press(false)end end))
    Actions:BindActionAtPriority('SupplyCinematicHold',function(_,state,input)
        if input.KeyCode==Enum.KeyCode.Backspace or input.KeyCode==Enum.KeyCode.ButtonB then if state==Enum.UserInputState.Begin and skip.Visible then s.skipRequested=true end
        elseif state==Enum.UserInputState.Begin then press(true)elseif state==Enum.UserInputState.End then press(false)end
        return Enum.ContextActionResult.Sink
    end,false,3000,Enum.KeyCode.Space,Enum.KeyCode.Return,Enum.KeyCode.ButtonA,Enum.KeyCode.Backspace,Enum.KeyCode.ButtonB)
    Actions:BindActionAtPriority('SupplyCinematicSink',function()return Enum.ContextActionResult.Sink end,false,3000,
        Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right,Enum.KeyCode.E,Enum.KeyCode.G,Enum.KeyCode.Thumbstick1)

    camera.CameraType=Enum.CameraType.Scriptable
    s.clock=0;s.beat='request';s.beatAt=0;s.lit=0;s.charge=0;s.signal=math.min(Rules.boxTier[result.kind]or 1,tier)
    if cp.mesh then cp.sig={g=s.signal,prev=s.signal,at=-10}else for _,p in ipairs(cp.seams)do p.Color=gradeColor(s.signal,0)end end
    local beats={request=.9,flyover=2,descent=2.1,landing=tier>=3 and not reduced and 1.4 or .9,open=.7}
    local revealLength=Rules.reveal[result.rarity][1]
    local announced={}
    local function once(name,fn)if not announced[name]then announced[name]=true;fn()end end
    local function setSignal(g)
        g=math.max(g,s.signal);s.signal=g
        if cp.mesh then Mesh.signal(cp,g,s.clock)else for _,p in ipairs(cp.seams)do p.Color=gradeColor(g,s.clock)end end
    end
    local function go(name)s.beat=name;s.beatAt=s.clock end
    local function cam(pos,look,fov)
        local shakeOffset=Vector3.zero
        if s.shake and s.shake>0 then shakeOffset=Vector3.new(math.noise(s.clock*24,1)*s.shake,math.noise(s.clock*24,2)*s.shake,0)end
        camera.CFrame=O*CFrame.lookAt(pos+shakeOffset,look);camera.FieldOfView=fov
    end
    local done=false
    local function finish()
        if done then return end;done=true;skip.Visible=false;shield.Visible=false
        Actions:UnbindAction('SupplyCinematicHold');Actions:UnbindAction('SupplyCinematicSink')
        if onDone then task.defer(onDone)end
    end
    local function toReveal(short)
        s.short=short;if short then revealLength=Rules.reveal[result.rarity][2]end
        hold.Visible=false;chute.Parent=nil;cp.smoke.Enabled=false
        crate:PivotTo(O);setSignal(tier)
        for i,g in ipairs(plan.seals)do local lamp=cp.lamps[i];lamp.Material=Enum.Material.Neon;lamp.Color=gradeColor(g,s.clock,i)end
        Score.stop();go('open');s.openAt=s.clock
    end
    if not Score.cue('request')then Audio.play('request',.7)end
    caption.Text='보급 요청'

    Run:BindToRenderStep('SupplyCinematic',Enum.RenderPriority.Camera.Value+5,function(dt)
        if current~=s then return end
        if not gui.Parent or player:GetAttribute('FrontierRoom')then M.stop();return end
        if camera.CameraType~=Enum.CameraType.Scriptable then camera.CameraType=Enum.CameraType.Scriptable end
        local rate=1;local now=os.clock()
        if s.beat=='landing'and not reduced and s.clock-s.beatAt<L.slowmo[tier]then rate=.35 end
        if s.freezeUntil and now<s.freezeUntil then rate=0 end
        if M.galleryHold then rate=0 end
        if flash then flash.BackgroundTransparency=(flashes and s.flashAt)and lerp(.12,1,math.clamp((now-s.flashAt)/.55,0,1))or 1;if flash:FindFirstChildOfClass('UIGradient')then flash:FindFirstChildOfClass('UIGradient').Rotation=35+now*40 end end
        s.clock+=math.min(dt,1/15)*rate
        local t=s.clock;local u=t-s.beatAt
        skip.Visible=skippable and not done and t>.8 and s.beat~='open'and not s.short
        if s.skipRequested then s.skipRequested=false
            if s.beat=='reveal'then
                s.short=true;s.freezeUntil=nil;revealLength=math.min(revealLength,math.max(u+.3,Rules.reveal[result.rarity][2]))
            elseif s.beat~='open'then toReveal(true)end
        end
        if #coins>0 then
            local landed=0;local size=gui.AbsoluteSize;local goal=Vector2.new(size.X-60,86)
            for _,c in ipairs(coins)do
                local k=math.clamp((now-c.at)/.6,0,1)
                local goal=s.gauge and ShardGauge.cellCenter(s.gauge,s.gaugeSlot)-gui.AbsolutePosition or goal
                if k>=1 then landed+=1;c.frame.Visible=false
                elseif now>=c.at then
                    local e=k*k*(3-2*k);local mid=c.from:Lerp(goal,.5)+c.bend
                    local p=c.from:Lerp(mid,e):Lerp(mid:Lerp(goal,e),e);c.frame.Visible=true;c.frame.Position=UDim2.fromOffset(p.X,p.Y);c.frame.Rotation=k*360*c.spin
                end
            end
            if landed~=s.coinsLanded then s.coinsLanded=landed;counter.Text=s.counterText(landed/#coins);counter.TextSize=landed<#coins and 25 or 22
                if s.gauge and landed==#coins then
                    ShardGauge.set(s.gauge,s.gaugeSlot,true);if result.refundTickets then s.gaugeResetAt=now+1.1 end
                end
            end
            if s.gaugeResetAt and now>=s.gaugeResetAt then s.gaugeResetAt=nil;ShardGauge.set(s.gauge,result.fragmentCount or 0,true)end
            local fade=math.clamp((now-(s.coinsDone or math.huge))/.6,0,1);counter.TextTransparency=fade;counter.TextStrokeTransparency=lerp(.4,1,fade)
            if s.gauge then s.gauge.root.GroupTransparency=math.max(fade,1-math.clamp((now-s.dupAt)/.25,0,1))end
            if landed==#coins and not s.coinsDone then s.coinsDone=now+1.6 end
        end
        if s.shatterAt and #shards>0 then
            local age=now-s.shatterAt
            for i,sh in ipairs(shards)do
                if age>.95 then sh.part.Transparency=1
                else
                    local p=Vector3.new(1.65-((i-1)%4)*1.1,3.3,-2.75)+sh.dir*age*(reduced and 3 or 6)+Vector3.new(0,-9*age*age,0)
                    sh.part.CFrame=O*CFrame.new(p)*CFrame.Angles(age*sh.spin,age*sh.spin*.7,0)
                    sh.part.Transparency=math.clamp((age-.35)/.6,0,1);sh.part.Color=UI.colors.gold:Lerp(prism(age,i),math.clamp(age*1.6,0,1))
                end
            end
        end
        local pz=210-150*(t-beats.request)
        local alt=plan.stealth and 40 or 50
        plane:PivotTo(O*CFrame.new(0,alt+math.sin(t*.8)*.6,pz))
        for _,e in ipairs(escorts)do e.model:PivotTo(O*CFrame.new(e.side*20,alt+5+math.sin(t*1.3+e.side),pz+16));if e.mesh then Mesh.paintLights(e.lights,plan.plane,t)end end
        if planeExtra then Mesh.poseRamp(planeExtra,plane:GetPivot(),Mesh.rampAngle(pz));Mesh.paintLights(planeLights,plan.plane,t,s.sweepAt and t-s.sweepAt or -1)end
        local planeVisible=s.beat=='request'or s.beat=='flyover'or s.beat=='descent'
        plane.Parent=planeVisible and workspace or nil;for _,e in ipairs(escorts)do e.model.Parent=planeVisible and workspace or nil end
        local avatarEye=avatarPos+Vector3.new(0,4.8,0)
        if s.beat=='request'then
            caption.Text='보급 요청'
            crate:PivotTo(O*CFrame.new(0,-40,0));chute.Parent=nil
            if plan.stealth then grade.Brightness=lerp(-.04,-.12,ease(u/beats.request));grade.TintColor=Color3.new(1,1,1):Lerp(rgb(196,206,255),ease(u/beats.request))end
            cam(avatarEye+Vector3.new(3.2,1.4,7.6)-Vector3.new(0,0,u*1.2),Vector3.new(-2,6+u*6,-34),62)
            if u>=beats.request then go('flyover');s.sweepAt=t;if not Score.cue('flyover')then Audio.play('supplyDelivery',.9)end end
        elseif s.beat=='flyover'then
            caption.Text=plan.stealth and '저공 비행'or plan.escort and '호위 편대 접근'or '수송기 접근'
            local planePos=Vector3.new(0,alt,pz)
            local released=pz<=0
            if released then
                local fall=math.max(0,-pz/150);crate:PivotTo(O*CFrame.new(0,alt-6-4.9*fall*fall,0))
                once('release',function()cp.smoke.Color=ColorSequence.new(gradeColor(plan.chute,t));cp.smoke.Enabled=true;cp.smoke.Rate=reduced and 12 or 34 end)
            else crate:PivotTo(O*CFrame.new(0,-40,0))end
            local look=released and crate:GetPivot().Position-O.Position+Vector3.new(0,2,0)or planePos+Vector3.new(0,-4,-10)
            local base=avatarEye+Vector3.new(2.6,1.2,6.2)
            s.look=s.look and s.look:Lerp(look,math.min(1,dt*6))or look
            cam(base,s.look,lerp(66,58,ease(u/beats.flyover)))
            if u>=beats.flyover then go('descent');setSignal(plan.chute);Score.cue('chute',plan.chute)end
        elseif s.beat=='descent'then
            caption.Text='낙하'
            local k=math.clamp(u/beats.descent,0,1);local y=lerp(alt-8,0,1-(1-k)^1.15)
            local sway=math.sin(t*1.7)*.06*(1-k)
            chute.Parent=workspace
            local open=math.clamp(u/.35,0,1)
            if cp.mesh then
                crate:PivotTo(O*CFrame.new(0,y,0)*Mesh.descentPose(cp.tier,t,u,k))
                if meshChute then chute:ScaleTo(lerp(.6,1,ease(math.clamp(u/.4,0,1))))end
                chute:PivotTo(O*CFrame.new(0,y+4.6+(chuteLift-4.6)*open,0)*CFrame.Angles(0,Mesh.descentYaw(u,k),0))
            else
                crate:PivotTo(O*CFrame.new(0,y,0)*CFrame.Angles(0,0,sway))
                chute:PivotTo(O*CFrame.new(0,y+4.6+(chuteLift-4.6)*open,0)*CFrame.Angles(0,t*.4,sway))
            end
            for i,g in ipairs(gores)do g.Color=gradeColor(plan.chute,t,i);g.Transparency=1-open end;for _,v in ipairs(trims)do v.Transparency=1-open end
            for _,l in ipairs(lines)do l.Transparency=NumberSequence.new(1-open*.85)end
            local camPos=Vector3.new(lerp(26,17,k),lerp(18,4,ease(k)),lerp(-40,-24,k))
            cam(camPos,Vector3.new(0,y+6*(1-k)+3,0),lerp(56,52,k))
            if u>=beats.descent then
                go('landing');s.landAt=t;cp.smoke.Enabled=false;dust.Color=ColorSequence.new(rgb(120,132,150):Lerp(gradeColor(plan.land,t),.35));dust:Emit(reduced and 14 or 46)
                ring.Color=gradeColor(plan.land,t);ring.Size=Vector3.new(.12,2,2);ring.Transparency=.1;setSignal(plan.land)
                if not Score.cue('landing',plan.land)then Audio.play('supplySeal',.9,.8)end;s.shake=shake and .45 or 0
                if plan.land>plan.chute then for i,g in ipairs(gores)do g.Color=gradeColor(plan.land,t,i)end end
            end
        elseif s.beat=='landing'then
            caption.Text=plan.land>plan.chute and '착지, 신호 상승'or '착지'
            if cp.mesh then crate:PivotTo(O*Mesh.landingPose(cp.tier,u))else crate:PivotTo(O*CFrame.new(0,math.max(0,math.sin(math.min(1,u/.25)*math.pi)*.25),0))end
            local k=math.clamp(u/.7,0,1);local r=lerp(2,46,ease(k))
            ring.Size=Vector3.new(.12,r,r);ring.CFrame=O*CFrame.new(0,.5,0)*CFrame.Angles(0,0,math.pi/2);ring.Transparency=lerp(.1,1,k)
            local c=math.clamp(u/.6,0,1);chute:PivotTo(O*CFrame.new(0,chuteLift-9*c,-4*c)*CFrame.Angles(-1.1*c,0,.2*c))
            for _,g in ipairs(gores)do g.Transparency=c end;for _,v in ipairs(trims)do v.Transparency=c end;for _,l in ipairs(lines)do l.Transparency=NumberSequence.new(.15+.85*c)end
            if plan.flare then
                once('flare',function()flare.Color=gradeColor(plan.land,t);flareLight.Color=flare.Color;flare.Transparency=0 end)
                local fy=2+u*24;flare.CFrame=O*CFrame.new(1.2,fy,1);flareLight.Brightness=reduced and .6 or 2.4
            end
            s.shake=(s.shake or 0)*math.exp(-dt*7)
            cam(Vector3.new(lerp(13,11,k),1.6,lerp(-18,-16,k)),Vector3.new(0,2.2+(plan.flare and math.min(u*10,8)or 0),0),48)
            if u>=beats.landing then go('seal');chute.Parent=nil;hold.Visible=true;s.charge=0;s.lit=0;s.shake=0 end
        elseif s.beat=='seal'then
            caption.Text='봉인 해제'
            if plan.flare then flare.CFrame=O*CFrame.new(1.2,26+math.sin(t)*.5,1)end
            local k=ease(math.clamp(u/1.1,0,1))
            cam(Vector3.new(lerp(7,0,k),lerp(4.6,3.7,k),lerp(-18,-12.5,k)),Vector3.new(0,2.8,-2.4),lerp(54,50,k))
            local n=#plan.seals
            if s.holding or s.auto then
                local need=Rules.lampHold[s.lit+1]or .3;local step=math.min(dt,1/15)/need
                local stall=Rules.lampStall;if s.lit+1==stall.lamp and s.lit<n and s.charge>=stall.from and s.charge<stall.to then step*=stall.rate end
                s.charge+=step
                if s.lit<n then fills[s.lit+1].Size=UDim2.fromScale(math.min(1,s.charge),1);fills[s.lit+1].BackgroundColor3=gradeColor(math.max(s.signal,1),t)end
                if s.charge>=1 then
                    s.charge=0
                    if s.lit<n then
                        s.lit+=1;local g=plan.seals[s.lit];local lamp=cp.lamps[s.lit]
                        lamp.Material=Enum.Material.Neon;lamp.Color=gradeColor(g,t,s.lit);fills[s.lit].BackgroundColor3=lamp.Color;fills[s.lit].Size=UDim2.fromScale(1,1)
                        local up=g>s.signal;local crack=has.shatter and g==5 and s.signal==4;setSignal(g)
                        s.jitterAt=t;if s.lit==4 then s.liftAt=t;s.pulseAt=t end
                        if crack then s.shatterAt=os.clock();Score.cue('shatter')end
                        if Score.cue('lamp',g,s.lit)then if up and not crack then Score.cue('upgrade',g)end else Audio.play('supplySeal',up and .9 or .65,1+s.lit*.14)end
                        if up then ring.Color=gradeColor(g,t);ring.Size=Vector3.new(.12,6,6);ring.Transparency=.2;s.ringAt=t;s.ringClock=os.clock();s.shake=shake and .2 or 0 end
                    end
                    if s.lit>=n then go('pause')end
                end
            end
            if n==0 and(s.holding or s.auto)and s.charge>.99 then go('pause')end
            if cp.mesh and s.liftAt then crate:PivotTo(O*CFrame.new(0,.08*math.sin(math.pi*math.clamp((t-s.liftAt)/.4,0,1)),0))end
            fadeRing()
            s.shake=(s.shake or 0)*math.exp(-dt*8)
        elseif s.beat=='pause'then
            hold.Visible=false;setSignal(tier)
            fadeRing()
            cp.inner.Color=gradeColor(tier,t);cp.light.Color=cp.inner.Color;cp.light.Brightness=lerp(0,1.2,math.clamp(u/.35,0,1))
            cam(Vector3.new(0,3.7,-12.5),Vector3.new(0,2.8,-2.4),50)
            if cp.mesh then crate:PivotTo(O);for _,d in ipairs(cp.doors)do d.part.CFrame=O*d.hinge*CFrame.new(0,0,-.03*ease(math.clamp(u/.35,0,1)))*d.home end end
            if u>=.35 then go('open');s.openAt=t end
        elseif s.beat=='open'then
            caption.Text=''
            fadeRing()
            local k=ease(math.clamp(u/beats.open,0,1))
            for _,d in ipairs(cp.doors)do
                if d.dir then d.part.CFrame=O*d.hinge*CFrame.Angles(0,d.dir*math.rad(Mesh.doorAngle(u)),0)*d.home
                else
                    local swing=d.hinge*CFrame.Angles(0,d.side*k*1.9,0)
                    d.part.CFrame=O*swing*d.home;d.rib.CFrame=O*swing*d.ribHome
                end
            end
            cp.inner.Transparency=cp.mesh and lerp(1,.15,math.clamp((k-.2)/.8,0,1))or lerp(1,.15,k);cp.inner.Color=gradeColor(tier,t);cp.light.Color=cp.inner.Color;cp.light.Brightness=lerp(1.2,3,k)
            once('fanfare',function()if Score.cue('open')then Score.cue('reveal',tier)else Audio.play('supply_'..result.rarity,.85)end;if tier>=4 and not reduced then for _,b in ipairs(bars)do b:TweenSize(UDim2.fromScale(1,.09),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,.5,true)end end end)
            cam(Vector3.new(0,3.7,lerp(-12.5,-14,k)),Vector3.new(0,3.4,0),50)
            if u>=beats.open then go('reveal');model.Parent=workspace end
        elseif s.beat=='reveal'then
            fadeRing()
            local f=math.clamp(u/revealLength,0,1)
            local rise=ease(math.clamp(u/(s.short and .35 or 1),0,1))
            local rig=extra and extra.rig
            local sinkAt=s.short and .35 or 1.1
            local sink=ease(math.clamp((u-sinkAt)/1.2,0,1))
            if sink>0 then once('sink',function()Score.cue('sink')end)end
            local depth=cp.height and cp.height+.2 or 4.9;s.sink=sink
            crate:PivotTo(O*CFrame.new(0,-depth*sink,0))
            local h=rig and lerp(1.6,4.6+itemSize*.5,rise)-3.2*sink or lerp(lerp(1.2,6.4,rise),1.5,sink)
            s.crownTop=(rig and h+itemSize*.5 or h+itemHeight)+.6+depth*sink
            local baseY=rig and h or h+itemHeight/2
            local spin=t*(reduced and .25 or .55)
            local phase=tier==5 and math.min(3,1+math.floor(f*3.2))or 1
            once('revealFx',function()
                for _,e in ipairs(revealFx)do e.Enabled=true end
                if has.shake then if shake then s.shake=.22 else s.punch=now end end
            end)
            s.shake=(s.shake or 0)*math.exp(-dt*5)
            local frame=O*CFrame.new(0,h,0)*CFrame.Angles(0,spin,0)
            local d=u-sinkAt-1;local focus;local reach=0;local wide=0;local lift=0
            if(category=='vehicle'or category=='commanderTrail')and d>0 then
                local R=category=='vehicle'and 4.2 or 3.4;local w=2*math.pi/4.4
                local th=d<.8 and w*d*d/1.6 or w*(d-.4)
                local y=category=='vehicle'and lerp(h,.45,ease(d/.5))or h
                local p=Vector3.new(math.sin(th)*R,y,(1-math.cos(th))*R)
                frame=O*CFrame.lookAt(p,p+Vector3.new(math.cos(th),0,math.sin(th)))
                local rider=category=='vehicle'and s.avatar~=nil
                focus=Vector3.new(0,rider and 3.2 or baseY,R*.6);reach=R*.6+(rider and 4 or 0);lift=rider and 4.5 or 0
                if tier==5 then phase=math.min(3,1+math.floor(d/.7))end
                once('drive',function()Score.cue('drive')end)
                if category=='vehicle'and s.avatar then
                    s.avatar:PivotTo(frame*itemOffset*CFrame.new(0,.74*itemScale,.15*itemScale)+Vector3.new(0,s.avatarLift,0))
                    local fade=1-math.clamp(d/.3,0,1);if s.avatarFade~=fade then s.avatarFade=fade;for _,p2 in ipairs(s.avatarParts)do p2.LocalTransparencyModifier=fade end end
                end
            elseif category=='nuclear'and d>0 then
                local Fx=require(script.Parent.NukeFx)
                local q=d%7.2;local cycle=math.floor(d/7.2)
                if demo.cycle~=cycle then demo.cycle=cycle;demo.flags={}end
                local function flag(name,fn)if not demo.flags[name]then demo.flags[name]=true;fn()end end
                local T=Vector3.new(15,.3,9);local S=Vector3.new(0,h+1.2,0)
                if not demo.fx then
                    demo.folder=own(Instance.new('Folder'));demo.folder.Name='SupplyDemoFx';demo.folder.Parent=workspace
                    for i=0,8 do
                        local c=i==4 and UI.colors.accent or(i%2==0 and rgb(64,98,128)or rgb(48,66,86))
                        local tile=G.block(demo.folder,'DemoLand',Vector3.new(4.7,.08,4.7),O*CFrame.new(T.X+(i%3-1)*4.9,.12,T.Z+(math.floor(i/3)-1)*4.9),c)
                        tile.Material=Enum.Material.SmoothPlastic;tile.CastShadow=false
                    end
                    local Skins=require(script.Parent.NukeSkins);demo.trail=Skins.get(item.loadout,'trail');demo.impact=Skins.get(item.loadout,'impact')
                    demo.fx=Fx.new(demo.folder)
                end
                if q<.9 then
                    flag('aim',function()model.Parent=workspace;demo.tele=Fx.telegraph(demo.folder,(O*CFrame.new(T)).Position,6.4,gradeColor(tier,t))end)
                    local k=ease(q/.9);frame=O*CFrame.new(0,h+k*1.2,0)*CFrame.Angles(0,spin*(1-k),0)*CFrame.Angles(math.pi/2*k,0,0)
                elseif q<2.5 then
                    flag('launch',function()demo.fx:launch((O*CFrame.new(0,.4,0)).Position,demo.trail,reduced);for _,tr in ipairs(demo.trails)do tr.trail.Enabled=tr.on end end)
                    local k=(q-.9)/1.6;local apex=8
                    local p=S:Lerp(T,k)+Vector3.new(0,4*apex*k*(1-k),0);local v=(T-S)+Vector3.new(0,4*apex*(1-2*k),0)
                    frame=O*CFrame.lookAt(p,p+v);wide=ease(math.clamp((q-.9)/.5,0,1))
                else
                    flag('boom',function()
                        for _,tr in ipairs(demo.trails)do tr.trail.Enabled=false end;model.Parent=nil
                        if demo.tele then demo.tele.model:Destroy();demo.tele=nil end
                        demo.fx:detonate((O*CFrame.new(T)).Position,'HydrogenBomb',16,6,demo.impact,reduced);Score.cue('impact')
                        if shake then s.shake=.3 end
                    end)
                    if q<5.6 then wide=1-ease(math.clamp((q-4.8)/.8,0,1))
                    else flag('return',function()model.Parent=workspace end);frame=O*CFrame.new(0,lerp(h-2.5,h,ease((q-5.6)/1.6)),0)*CFrame.Angles(0,spin,0)end
                end
                if demo.tele then Fx.stepTelegraph(demo.tele,now,dt,reduced)end
            elseif category=='territory'then
                local grow=(u-.3)*2.6
                for _,tl in ipairs(demo.tiles)do
                    local on=tl.ring<=grow;tl.part.Transparency=on and 0 or 1
                    if on and d>0 then local wave=((d*1.1)%3.4)-.4;tl.part.Color=tl.color:Lerp(gradeColor(tier,t),math.max(0,1-math.abs(tl.ring-wave))*.45)end
                end
                for _,e in ipairs(demo.edges)do e.part.Transparency=grow>=(e.post and 3.6 or 3)and 0 or 1 end
            elseif category=='motion'and d>0 then
                frame=O*CFrame.new(0,lerp(h,.45,ease(d/.4)),0)*CFrame.Angles(0,spin*.35,0)
                local age=d%1.15;local live=age<.65
                local sc=demo.scale*(live and .8+.2*ease(age/.15)or .8)
                if math.abs((demo.lastScale or 0)-sc)>.002 then demo.lastScale=sc;pcall(function()model:ScaleTo(sc)end)end
                local fade=live and math.max(0,(age-.38)/.27)or 1
                if not demo.parts then demo.parts={};for _,p2 in ipairs(model:GetDescendants())do if p2:IsA('BasePart')then table.insert(demo.parts,p2)end end end
                for _,p2 in ipairs(demo.parts)do p2.LocalTransparencyModifier=fade end
                if tier==5 then phase=math.min(3,1+math.floor(age/.2))end
                if s.avatar then
                    focus=Vector3.new(0,2.6,0);reach=5
                    s.avatar:PivotTo(frame+Vector3.new(0,s.avatarLift+.06,0))
                    local a2=1-math.clamp(d/.3,0,1);if s.avatarFade~=a2 then s.avatarFade=a2;for _,p2 in ipairs(s.avatarParts)do p2.LocalTransparencyModifier=a2 end end
                end
            elseif rig and d>0 then
                local q=d%6;local up=q<1.2 and ease(q/1.2)or q<5 and 1-ease((q-1.2)/3.8)or 0
                local a2=q*.9;local r=2.6*up
                frame=O*CFrame.new(math.cos(a2)*r,h+9*up,math.sin(a2)*r)*CFrame.Angles(0,spin*.3-a2*.5,0)
                extra.motion.canopyRoll=reduced and 0 or math.sin(q*1.3)*.06*up
            end
            local pivot=rig and frame or frame*itemOffset
            if rig then
                model:PivotTo(pivot);extra.motion.time=t;extra.rig:step(pivot,extra.motion,true);Art.step(extra.rig.canopy,t,reduced,phase)
                once('rigBounds',function()local bcf,bsize=Preview.visibleBounds(model);rigMid=pivot:PointToObjectSpace(bcf.Position).Y;rigHalf=bsize.Y/2 end)
            else
                model:PivotTo(pivot);pcall(Preview.step,itemContext,t,phase)
            end
            local itemPos=frame.Position-O.Position
            local itemCenter=Vector3.new(itemPos.X,rig and itemPos.Y+rigMid or itemPos.Y+itemHeight/2,itemPos.Z)
            itemLight.Color=gradeColor(tier,t);itemLight.Brightness=lerp(0,.7,rise);lightAnchor.CFrame=O*CFrame.new(itemCenter+Vector3.new(0,itemSize*.6,-itemSize*.8))
            fxAnchor.CFrame=O*CFrame.new(itemPos+Vector3.new(0,.2,0))
            cp.inner.Color=gradeColor(tier,t);cp.light.Color=cp.inner.Color;cp.light.Brightness=lerp(3,0,sink)
            if tier>=5 then setSignal(5);for i,l in ipairs(cp.lamps)do l.Color=gradeColor(5,t,i)end end
            if has.beam then local w=L.beam[tier];pillar.Color=gradeColor(tier,t);pillar.Size=Vector3.new(420,w,w);pillar.CFrame=O*CFrame.new(0,baseY+itemSize*.7+212,0)*CFrame.Angles(0,0,math.pi/2);pillar.Transparency=lerp(1,has.goldPillar and .5 or .7,math.clamp(u/.6,0,1))end
            if #edges>0 then
                local k=math.clamp(u/.6,0,1)*(done and .6 or 1);local pulse=.5+.5*math.sin(t*2.2)
                local strong=(s.flashAt and not flashes)and math.max(0,1-(now-s.flashAt)/.8)or 0
                for i,e in ipairs(edges)do e.BackgroundColor3=gradeColor(tier,t,i);e.BackgroundTransparency=lerp(1,lerp(.8,.68,pulse)-.45*strong,k)end
            end
            if tier>=5 then
                grade.Brightness=lerp(grade.Brightness,-.1,math.min(1,dt*3));grade.TintColor=grade.TintColor:Lerp(rgb(200,210,255),math.min(1,dt*3));grade.Contrast=.08
                for i,a in ipairs(aurora)do local fade=math.clamp(u/1.4,0,1);for c,col in ipairs(a.cols)do col.frame.BackgroundColor3=Color3.fromHSV(sweep(t*.06+i*.11+c*.012),.7,1);col.frame.BackgroundTransparency=lerp(1,.3+col.edge*.7,fade)end;a.part.CFrame=O*CFrame.new(math.sin(a.a)*150,62+math.sin(t*.7+i)*3,math.cos(a.a)*150)*CFrame.Angles(0,a.a+math.sin(t*.3+i)*.08,math.sin(t*.4+i)*.1)end
            end
            if has.freeze and not s.short and u>=1.8 then once('freeze',function()
                if not reduced then s.freezeUntil=now+Rules.freeze end
                s.flashAt=now;if flashes then grade.Brightness=.35 end;Score.cue('freeze')
            end)end
            local serialAt=s.short and .3 or 2.9
            if serialPlate and u>serialAt then
                once('serial',function()if not Score.cue('serial')then Audio.play('supplySeal',.8,1.6)end end)
                serialPlate.CFrame=O*CFrame.new(0,lerp(.5,1.3,math.clamp((u-serialAt)/.3,0,1)),-3.4)*CFrame.Angles(.25,0,0)
            end
            gradeLabel.Text=Launch.rarityNames[result.rarity];gradeLabel.TextColor3=gradeColor(tier,t);gradeLabel.TextTransparency=1-math.clamp((u-.3)/.4,0,1);nameLabel.TextTransparency=gradeLabel.TextTransparency
            if result.duplicate and not s.dupAt and u>=math.max(s.short and .3 or 1.2,revealLength-1.3)then
                s.dupAt=now;s.coinsLanded=-1
                s.counterText=function(k)
                    if result.testing then return '중복 (테스트)'end
                    if result.currency=='medals'or result.medals then return string.format('+%d 코인',math.floor((result.medals or 180)*k+.5))end
                    if k>=1 and result.refundTickets then return string.format('뽑기권 +%d',result.refundTickets)end
                    return ''
                end
                local coinRefund=result.testing or result.currency=='medals'or result.medals~=nil
                local shardColor=require(script.Parent.SupplyCrateArt).colors[result.kind]or UI.colors.ice
                if not coinRefund then
                    counter.TextColor3=shardColor;counter.Position=UDim2.new(1,-24,0,106)
                    s.gauge=ShardGauge.create(gui,shardColor,22);s.gauge.root.AnchorPoint=Vector2.new(1,0);s.gauge.root.Position=UDim2.new(1,-24,0,64);s.gauge.root.ZIndex=5;s.gauge.root.GroupTransparency=1
                    s.gaugeSlot=result.refundTickets and 5 or math.max(result.fragmentCount or 1,1)
                    ShardGauge.set(s.gauge,s.gaugeSlot-1,false)
                end
                local n=not coinRefund and 1 or reduced and math.min(6,L.coins[tier])or L.coins[tier]
                local sp=camera:WorldToViewportPoint((O*CFrame.new(itemCenter)).Position);local from=Vector2.new(sp.X,sp.Y)
                for i=1,n do
                    local coin
                    if coinRefund then
                        coin=UI.corner(UI.make('Frame',gui,{Name='RefundCoin',Size=UDim2.fromOffset(20,20),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=UI.colors.gold,BorderSizePixel=0,Visible=false,ZIndex=6}),10)
                        UI.stroke(coin,rgb(150,108,40),2)
                    else
                        coin=UI.make('Frame',gui,{Name='RefundShard',Size=UDim2.fromOffset(24,24),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=shardColor,BorderSizePixel=0,Visible=false,ZIndex=6})
                        UI.stroke(coin,shardColor:Lerp(Color3.new(1,1,1),.6),2)
                    end
                    table.insert(coins,{frame=coin,from=from+Vector2.new(math.random(-30,30),math.random(-20,20)),bend=Vector2.new(math.random(-160,60),math.random(-160,-40)),at=now+.05+(i-1)*(.5/n),spin=math.random()<.5 and 1 or -1})
                end
                Score.cue('coins',1,n)
            end
            if s.dupAt then
                local k=math.clamp((now-s.dupAt)/.25,0,1)
                stamp.TextTransparency=done and 1 or 1-k;stamp.TextStrokeTransparency=done and 1 or lerp(1,.4,k);stamp.TextSize=math.floor(lerp(44,30,k))
            end
            local a=-math.pi/2+L.orbit[tier]*ease(f)+(done and (t-s.doneAt)*.08 or 0)
            local flat=not rig and itemHeight<itemSize*.4
            local center=Vector3.new(0,rig and itemCenter.Y or baseY,0)
            if focus then center=focus:Lerp(Vector3.new(itemCenter.X,focus.Y,itemCenter.Z),.25)end
            local fov=(has.letterbox and 44 or 48)-L.zoom[tier]*ease(f)
            local radius=(flat and math.max(9.5,itemSize*2.2)or math.max(11,itemSize*2.6))+reach
            if rig then radius=math.max(radius,rigHalf*1.25/(math.tan(math.rad(fov/2))*(has.letterbox and .82 or 1)))end
            local pos=center+Vector3.new(math.cos(a)*radius,(flat and radius*.62 or 2.2)+lift,math.sin(a)*radius)
            if has.crane and not s.short then local c=ease(math.clamp(u/1.8,0,1));pos=pos:Lerp(Vector3.new(0,34,-26),1-c)end
            local look=center-Vector3.new(0,flat and 0 or .9,0)
            if wide>0 then pos=pos:Lerp(Vector3.new(-12,9,-20),wide);look=look:Lerp(Vector3.new(7.5,5,4.5),wide)end
            if s.punch then fov-=5*math.max(0,1-(now-s.punch)/.5)end
            cam(pos,look,fov)
            if f>=1 and not done then s.doneAt=t;gradeLabel.TextTransparency=1;nameLabel.TextTransparency=1;finish()end
            if done then gradeLabel.TextTransparency=1;nameLabel.TextTransparency=1;caption.Text=''end
        end
        if cp.mesh then
            Mesh.cineStep(cp,crate:GetPivot(),{t=t,beat=s.beat,reduced=reduced,tier=tier,openAt=s.openAt,sealPress=s.beat=='seal'and s.holding,
                jitterAt=s.jitterAt,landAt=s.landAt,pulseAt=s.pulseAt,sink=s.beat=='reveal'and s.sink or 0,crownTop=s.beat=='reveal'and s.crownTop or nil})
        end
    end)
    return true
end
function M.preview(rarity,itemId,key,duplicate,auto,sequence,kind)
    if not Run:IsStudio()then return false end
    local item=require(script.Parent.Parent.Core.SupplyCatalog).find(itemId);if not item then return false end
    local started=M.play(nil,{rarity=rarity,id=itemId,name=item.name,requestId=key or ('studio-'..os.clock()),serial='SC-STUDIO',duplicate=duplicate~=false,sequence=sequence,kind=kind or 'basic'},item,nil)
    if started and auto and current then current.auto=true end
    return started
end
function M.debugState()local s=current;return s and{beat=s.beat,clock=s.clock,lit=s.lit,signal=s.signal,short=s.short==true,frozen=s.freezeUntil~=nil and os.clock()<s.freezeUntil}end
return M
