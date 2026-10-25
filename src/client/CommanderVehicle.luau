local G=require(script.Parent.ToyGeometry)
local C=require(script.Parent.Parent.Core.CosmeticCatalog)
local Art=require(script.Parent.CollectionArt)
local M={};local states=setmetatable({},{__mode='k'})
M.riders=setmetatable({},{__mode='k'})
local Neon=Enum.Material.Neon
local function rgb(c)return Color3.fromRGB(table.unpack(c))end
local function prism(h)local f=h%1;return Color3.fromHSV(.45+.47*(1-math.abs(2*f-1)),.55,1)end
local function glow(p,alpha)p.Material=Neon;p.CastShadow=false;if alpha then p.Transparency=alpha;p:SetAttribute('BaseTransparency',alpha)end;return p end
local function wedge(m,name,size,cf,color)
    local p=Instance.new('WedgePart');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=Enum.Material.SmoothPlastic
    p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=m;return p
end
local function bone(a,b)
    local up=(b-a).Unit;local z=math.abs(up.Z)>.95 and Vector3.xAxis or Vector3.zAxis;local right=up:Cross(z).Unit
    return CFrame.fromMatrix((a+b)/2,right,up,right:Cross(up))
end
local function track(st,p,kind,extra)local a=extra or {};a.part=p;a.home=p.CFrame;a.kind=kind;a.base=p.Transparency;table.insert(st.anim,a);return p end
local function classic(m,dark,trim,accent)
    G.part(m,'ArmouredDeck',Vector3.new(2.5,.24,3.2),CFrame.new(0,.62,0),dark,'armor')
    G.part(m,'Nose',Vector3.new(1.8,.3,.8),CFrame.new(0,.72,-1.5)*CFrame.Angles(-.16,0,0),trim,'armor')
    G.part(m,'ConsolePost',Vector3.new(.16,.86,.16),CFrame.new(0,1.12,-1.12)*CFrame.Angles(-.22,0,0),trim,'armor')
    G.part(m,'ConsoleBar',Vector3.new(.92,.11,.13),CFrame.new(0,1.55,-1.22),trim,'armor')
    glow(G.block(m,'ConsoleScreen',Vector3.new(.44,.24,.05),CFrame.new(0,1.4,-1.14)*CFrame.Angles(-.55,0,0),accent))
    for _,side in ipairs({-1,1})do
        G.block(m,'OwnerStripe',Vector3.new(.12,.035,2.5),CFrame.new(side*.8,.77,0),accent)
        for _,z in ipairs({-1,1})do G.cylinder(m,'Wheel',.36,.2,CFrame.new(side*1.17,.35,z)*CFrame.Angles(0,0,math.pi/2),dark)end
    end
end
local function console(m,z,y,width,trim,dark,accent)
    G.part(m,'ConsolePost',Vector3.new(.14,y-.6,.14),CFrame.new(0,(y+.6)/2,z+.1)*CFrame.Angles(-.22,0,0),trim,'armor')
    G.part(m,'ConsoleBar',Vector3.new(width,.1,.12),CFrame.new(0,y,z),trim,'armor')
    for _,side in ipairs({-1,1})do G.block(m,'Grip',Vector3.new(.16,.13,.15),CFrame.new(side*width/2,y,z),dark)end
    return glow(G.block(m,'ConsoleScreen',Vector3.new(.42,.22,.05),CFrame.new(0,y-.17,z+.1)*CFrame.Angles(-.55,0,0),accent))
end
local function scout(m,st,dark,trim,accent)
    G.part(m,'ScoutDeck',Vector3.new(1.5,.14,3.2),CFrame.new(0,.6,0),dark,'board')
    G.block(m,'GripTape',Vector3.new(1.22,.02,2.4),CFrame.new(0,.68,.05),dark:Lerp(Color3.new(),.4))
    G.part(m,'NoseKick',Vector3.new(1.36,.13,.75),CFrame.new(0,.74,-1.9)*CFrame.Angles(.42,0,0),trim,'board')
    G.part(m,'TailKick',Vector3.new(1.36,.13,.6),CFrame.new(0,.72,1.82)*CFrame.Angles(-.4,0,0),trim,'board')
    for _,z in ipairs({-1.05,1.05})do
        G.block(m,'Truck',Vector3.new(1.32,.1,.18),CFrame.new(0,.44,z),trim)
        for _,side in ipairs({-1,1})do G.cylinder(m,'Wheel',.22,.2,CFrame.new(side*.7,.24,z)*CFrame.Angles(0,0,math.pi/2),dark)end
    end
    console(m,-1.35,1.55,.9,trim,dark,accent)
    G.part(m,'LampHousing',Vector3.new(.62,.22,.2),CFrame.new(0,.86,-2.2)*CFrame.Angles(.42,0,0),dark,'armor')
    glow(G.block(m,'Headlamp',Vector3.new(.44,.11,.04),CFrame.new(0,.87,-2.31)*CFrame.Angles(.42,0,0),accent))
    for _,side in ipairs({-1,1})do G.part(m,'SidePod',Vector3.new(.24,.24,1.2),CFrame.new(side*.86,.62,.45),trim,'armor')end
    G.rod(m,'Mast',Vector3.new(.6,.72,1.5),Vector3.new(.6,2.7,1.62),.035,trim)
    G.part(m,'ScanDish',Vector3.new(.62,.3,.62),CFrame.new(.6,2.05,1.5)*CFrame.Angles(-1.1,0,0),trim,'dish')
    G.block(m,'Pennant',Vector3.new(.03,.26,.5),CFrame.new(.6,2.55,1.88),accent)
    G.ball(m,'MastTip',Vector3.one*.13,CFrame.new(.6,2.72,1.62),accent)
end
local function armored(m,st,dark,trim,accent)
    G.part(m,'ArmouredDeck',Vector3.new(2.3,.3,3.5),CFrame.new(0,.62,0),dark,'armor')
    G.block(m,'TreadPlate',Vector3.new(1.8,.04,1.8),CFrame.new(0,.78,-.2),dark:Lerp(trim,.25)).Material=Enum.Material.DiamondPlate
    wedge(m,'Glacis',Vector3.new(2.3,.5,1.0),CFrame.new(0,.62,-2.25),trim)
    G.part(m,'EngineDeck',Vector3.new(2.0,.36,.95),CFrame.new(0,.92,1.25),dark,'armor')
    for i=-2,2 do G.block(m,'Grille',Vector3.new(.08,.05,.8),CFrame.new(i*.3,1.12,1.25),dark:Lerp(Color3.new(),.5))end
    G.part(m,'RamBar',Vector3.new(2.7,.24,.26),CFrame.new(0,.36,-2.72),trim,'armor')
    for _,side in ipairs({-1,1})do
        G.part(m,'SideSkirt',Vector3.new(.2,.66,3.9),CFrame.new(side*1.34,.5,-.1)*CFrame.Angles(0,0,side*.24),trim,'armor')
        glow(G.block(m,'ArmourSeam',Vector3.new(.07,.07,3.5),CFrame.new(side*1.25,.84,-.1),accent))
        for _,z in ipairs({-1.2,0,1.2})do
            G.part(m,'ArmourTile',Vector3.new(.12,.34,1.0),CFrame.new(side*1.47,.5,z-.1)*CFrame.Angles(0,0,side*.24),dark,'armor')
            G.cylinder(m,'Wheel',.3,.22,CFrame.new(side*1.02,.3,z)*CFrame.Angles(0,0,math.pi/2),dark:Lerp(Color3.new(),.35))
        end
        glow(G.block(m,'Headlamp',Vector3.new(.3,.12,.05),CFrame.new(side*.72,.75,-2.66)*CFrame.Angles(-.46,0,0),accent))
        glow(G.block(m,'TailLight',Vector3.new(.34,.1,.05),CFrame.new(side*.8,.74,1.88),accent))
        G.cylinder(m,'Exhaust',.1,.6,CFrame.new(side*.78,1.3,1.55),dark:Lerp(Color3.new(),.4))
        for i=0,1 do G.cylinder(m,'SmokeLauncher',.08,.36,CFrame.new(side*(.86+i*.2),.95,-1.5)*CFrame.Angles(-.7,0,side*-.35),dark)end
    end
    G.part(m,'RearPlate',Vector3.new(2.3,.42,.22),CFrame.new(0,.66,1.76),trim,'armor')
    console(m,-1.25,1.5,.92,trim,dark,accent)
    G.part(m,'GunShield',Vector3.new(1.4,.62,.12),CFrame.new(0,1.18,-1.62)*CFrame.Angles(-.28,0,0),trim,'armor')
    glow(G.block(m,'VisionSlit',Vector3.new(.7,.06,.04),CFrame.new(0,1.3,-1.69)*CFrame.Angles(-.28,0,0),accent))
    G.rod(m,'WhipAntenna',Vector3.new(-.9,.8,1.6),Vector3.new(-1.0,2.6,1.75),.03,trim)
end
local function hover(m,st,dark,trim,accent)
    G.part(m,'Fuselage',Vector3.new(.95,.42,3.4),CFrame.new(0,.78,.2),dark,'soft')
    G.part(m,'NoseCone',Vector3.new(.7,.32,1.5),CFrame.new(0,.78,-2.1)*CFrame.Angles(.12,0,0),trim,'key')
    glow(G.block(m,'NoseLight',Vector3.new(.08,.05,1.2),CFrame.new(0,.95,-2.05)*CFrame.Angles(.12,0,0),accent))
    G.part(m,'Cowl',Vector3.new(1.05,.52,.9),CFrame.new(0,1.08,-1.35)*CFrame.Angles(.2,0,0),trim,'armor')
    local glass=G.block(m,'Windscreen',Vector3.new(.92,.5,.05),CFrame.new(0,1.46,-1.5)*CFrame.Angles(-.7,0,0),trim);glass.Material=Enum.Material.Glass;glass.Transparency=.35;glass.CastShadow=false
    G.part(m,'Handlebar',Vector3.new(1.36,.08,.1),CFrame.new(0,1.4,-1.05),trim,'armor')
    for _,side in ipairs({-1,1})do G.block(m,'Grip',Vector3.new(.16,.13,.15),CFrame.new(side*.68,1.4,-1.05),dark)end
    glow(G.block(m,'ConsoleScreen',Vector3.new(.4,.18,.05),CFrame.new(0,1.27,-1.02)*CFrame.Angles(-.9,0,0),accent))
    for _,side in ipairs({-1,1})do
        G.part(m,'FootBoard',Vector3.new(.5,.08,1.5),CFrame.new(side*.68,.56,.2),trim,'armor')
        G.part(m,'Fairing',Vector3.new(.16,.4,2.4),CFrame.new(side*.52,.84,-.35)*CFrame.Angles(0,side*.06,0),dark,'armor')
        glow(G.block(m,'FairingLight',Vector3.new(.05,.06,2.0),CFrame.new(side*.61,.92,-.35)*CFrame.Angles(0,side*.06,0),accent))
        for i,z in ipairs({-1.3,1.3})do
            local x=side*(i==1 and 1.0 or 1.08);local r=i==1 and .34 or .4
            G.block(m,'Pylon',Vector3.new(math.abs(x)-.35,.12,.3),CFrame.new(side*(math.abs(x)+.35)/2,.66,z),dark)
            G.cylinder(m,'ThrusterHousing',r,.3,CFrame.new(x,.6,z),dark)
            glow(G.cylinder(m,'ThrusterRim',r+.04,.06,CFrame.new(x,.76,z),accent))
            G.cylinder(m,'ThrusterCap',r*.55,.08,CFrame.new(x,.78,z),trim)
            glow(G.cylinder(m,'ThrusterCore',r*.8,.05,CFrame.new(x,.44,z),accent))
            track(st,glow(G.cylinder(m,'ThrusterPlume',r*.7,.3,CFrame.new(x,.26,z),accent),.6),'pulse',{rate=6,range=.3,offset=i+side})
        end
    end
    G.cylinder(m,'MainNozzle',.3,.5,CFrame.new(0,.82,2.05)*CFrame.Angles(math.pi/2,0,0),trim)
    glow(G.cylinder(m,'NozzleCore',.22,.06,CFrame.new(0,.82,2.32)*CFrame.Angles(math.pi/2,0,0),accent))
    track(st,glow(G.cylinder(m,'NozzleFlame',.15,.5,CFrame.new(0,.82,2.57)*CFrame.Angles(math.pi/2,0,0),accent),.45),'pulse',{rate=9,range=.35,offset=0})
    wedge(m,'TailFin',Vector3.new(.08,.55,.8),CFrame.new(0,1.22,1.6),trim)
end
local function skiff(m,st,dark,trim,accent)
    G.part(m,'Hull',Vector3.new(2.1,.5,3.6),CFrame.new(0,.66,.3),dark,'armor')
    G.part(m,'Prow',Vector3.new(1.45,.48,1.45),CFrame.new(0,.68,-1.55)*CFrame.Angles(0,math.pi/4,0),dark,'armor')
    G.block(m,'Keel',Vector3.new(.14,.12,2.4),CFrame.new(0,.95,-1.6),trim)
    for _,side in ipairs({-1,1})do
        G.part(m,'GoldRail',Vector3.new(.16,.2,3.4),CFrame.new(side*1.04,.98,.3),trim,'armor')
        glow(G.block(m,'HullLight',Vector3.new(.05,.08,2.6),CFrame.new(side*1.07,.62,.3),accent))
        G.part(m,'ProwRail',Vector3.new(.14,.18,1.5),CFrame.new(side*.52,.96,-2.05)*CFrame.Angles(0,side*-.78,0),trim,'armor')
        local a=.42;local dir=Vector3.new(side*math.cos(a),0,math.sin(a));local yaw=CFrame.Angles(0,-side*a,side*.06)
        local root=Vector3.new(side*1.0,.86,.15)
        G.part(m,'Wing',Vector3.new(3.4,.14,1.4),CFrame.new(root+dir*1.7)*yaw,trim,'armor')
        G.part(m,'WingUnder',Vector3.new(3.1,.1,1.2),CFrame.new(root+dir*1.5+Vector3.new(0,-.08,.6))*yaw,dark:Lerp(trim,.35),'armor')
        glow(G.block(m,'WingEdge',Vector3.new(3.4,.07,.1),CFrame.new(root+dir*1.7+Vector3.new(0,.03,-.72))*yaw,accent))
        for i=1,3 do G.block(m,'WingRib',Vector3.new(.08,.05,1.1),CFrame.new(root+dir*(i*.95)+Vector3.new(0,.08,.05))*yaw,accent)end
        G.part(m,'Winglet',Vector3.new(.1,.75,.9),CFrame.new(side*4.1,1.2,1.75)*CFrame.Angles(0,0,side*-.3),trim,'armor')
        track(st,glow(G.ball(m,'WingtipLight',Vector3.one*.16,CFrame.new(side*4.22,1.58,1.75),accent)),'blink',{offset=side})
        local x=side*1.55;local y=1.12
        G.cylinder(m,'Nacelle',.36,1.6,CFrame.new(x,y,1.55)*CFrame.Angles(math.pi/2,0,0),trim)
        G.cylinder(m,'NacelleBand',.38,.2,CFrame.new(x,y,1.9)*CFrame.Angles(math.pi/2,0,0),dark)
        G.cylinder(m,'IntakeRing',.42,.16,CFrame.new(x,y,.72)*CFrame.Angles(math.pi/2,0,0),dark)
        local hub=CFrame.new(x,y,.8)
        for b=0,2 do track(st,G.block(m,'FanBlade',Vector3.new(.62,.07,.04),hub*CFrame.Angles(0,0,b*math.pi*2/3),trim),'spin',{pivot=hub,rate=side*9})end
        glow(G.cylinder(m,'ExhaustCore',.27,.06,CFrame.new(x,y,2.37)*CFrame.Angles(math.pi/2,0,0),accent))
        track(st,glow(G.cylinder(m,'Plume',.16,.8,CFrame.new(x,y,2.8)*CFrame.Angles(math.pi/2,0,0),accent),.35),'pulse',{rate=11,range=.3,offset=side})
        track(st,glow(G.cylinder(m,'PlumeOuter',.27,.5,CFrame.new(x,y,2.65)*CFrame.Angles(math.pi/2,0,0),trim),.7),'pulse',{rate=7,range=.2,offset=side*2})
        G.block(m,'Pylon',Vector3.new(.7,.14,.8),CFrame.new(side*1.15,.98,1.5),dark)
    end
    console(m,-1.25,1.5,.96,trim,dark,accent)
    glow(G.block(m,'HoloTable',Vector3.new(.9,.04,.5),CFrame.new(0,1.08,-1.85),accent),.3)
    G.rod(m,'PennantMast',Vector3.new(-.82,.9,1.75),Vector3.new(-.82,2.9,1.8),.04,trim)
    local hinge=CFrame.new(-.82,2.6,1.8)
    track(st,G.block(m,'Pennant',Vector3.new(.04,.5,.95),hinge*CFrame.new(0,0,.5),accent),'wave',{pivot=hinge})
    track(st,glow(G.cylinder(m,'HoverGlow',1.25,.04,CFrame.new(0,.1,.3),accent),.65),'pulse',{rate=3,range=.15,offset=0,ground=true})
end
local function walker(m,st,dark,trim,accent)
    G.part(m,'Chassis',Vector3.new(2.0,.42,2.5),CFrame.new(0,.82,0),dark,'armor')
    G.part(m,'Cowl',Vector3.new(1.6,.5,.8),CFrame.new(0,1.12,-1.35)*CFrame.Angles(.15,0,0),trim,'armor')
    wedge(m,'Glacis',Vector3.new(1.6,.42,.6),CFrame.new(0,.82,-1.55),dark)
    glow(G.block(m,'Visor',Vector3.new(1.1,.14,.06),CFrame.new(0,1.2,-1.76)*CFrame.Angles(.15,0,0),accent))
    console(m,-.95,1.55,.9,trim,dark,accent)
    G.cylinder(m,'Reactor',.42,.5,CFrame.new(0,1.12,1.0),dark)
    track(st,glow(G.cylinder(m,'ReactorBand',.45,.12,CFrame.new(0,1.2,1.0),accent)),'prism')
    G.cylinder(m,'ReactorCap',.3,.1,CFrame.new(0,1.42,1.0),trim)
    G.rod(m,'SensorMast',Vector3.new(-.75,1.0,1.0),Vector3.new(-.75,2.3,1.1),.035,trim)
    G.part(m,'SensorDish',Vector3.new(.5,.24,.5),CFrame.new(-.75,1.9,1.05)*CFrame.Angles(-1.0,0,0),trim,'dish')
    track(st,glow(G.ball(m,'SensorTip',Vector3.one*.14,CFrame.new(-.75,2.32,1.1),accent)),'blink',{offset=1})
    G.part(m,'RearSkirt',Vector3.new(1.6,.3,.12),CFrame.new(0,.72,1.3),trim,'armor')
    for _,side in ipairs({-1,1})do
        G.part(m,'SidePlate',Vector3.new(.16,.4,2.2),CFrame.new(side*1.02,.95,0)*CFrame.Angles(0,0,side*.2),trim,'armor')
        G.rod(m,'CoolantLine',Vector3.new(side*.42,1.15,1.0),Vector3.new(side*.9,.98,.92),.05,dark:Lerp(trim,.3))
        glow(G.block(m,'Headlamp',Vector3.new(.24,.1,.05),CFrame.new(side*.55,.9,-1.86)*CFrame.Angles(-.5,0,0),accent))
        G.cylinder(m,'ExhaustPort',.12,.3,CFrame.new(side*.6,1.0,1.38)*CFrame.Angles(math.pi/2,0,0),dark)
        glow(G.cylinder(m,'ExhaustGlow',.08,.04,CFrame.new(side*.6,1.0,1.54)*CFrame.Angles(math.pi/2,0,0),accent))
        track(st,G.part(m,'WeaponPod',Vector3.new(.36,.34,.9),CFrame.new(side*.95,1.42,-.85),trim,'armor'),'phase',{phase=2})
        track(st,glow(G.block(m,'PodMuzzle',Vector3.new(.24,.2,.04),CFrame.new(side*.95,1.42,-1.31),accent)),'phase',{phase=2})
        track(st,G.part(m,'DorsalFin',Vector3.new(.08,.6,.8),CFrame.new(side*.42,1.5,1.0)*CFrame.Angles(.35,0,side*.25),trim,'armor'),'phase',{phase=3})
        for _,fore in ipairs({-1,1})do
            local hip=Vector3.new(side*1.05,.92,fore*.95)
            G.ball(m,'Hip',Vector3.one*.5,CFrame.new(hip),trim)
            G.part(m,'HipGuard',Vector3.new(.5,.12,.62),CFrame.new(hip+Vector3.new(0,.3,0))*CFrame.Angles(0,0,side*-.3),dark,'armor')
            local leg={hip=hip,rest=Vector3.new(side*2.7,.02,fore*2.3),side=side,fore=fore,l1=1.65,l2=1.95,offset=(side==fore)and 0 or math.pi}
            leg.thigh=G.part(m,'Thigh',Vector3.new(.3,leg.l1,.34),CFrame.identity,trim,'armor')
            leg.shin=G.part(m,'Shin',Vector3.new(.24,leg.l2,.3),CFrame.identity,trim,'armor')
            leg.strip=glow(G.block(m,'ShinLight',Vector3.new(.06,leg.l2*.7,.06),CFrame.identity,accent))
            leg.knee=glow(G.ball(m,'Knee',Vector3.one*.3,CFrame.identity,accent))
            leg.foot=G.part(m,'FootPad',Vector3.new(.66,.16,.66),CFrame.identity,dark,'armor')
            table.insert(st.legs,leg)
        end
    end
    track(st,glow(G.cylinder(m,'Aura',2.2,.04,CFrame.new(0,.06,0),accent),.8),'phase',{phase=3,ground=true})
end
local builders={scout=scout,armored=armored,hover=hover,gunship=skiff,skiff=skiff,walker=walker}
for k,f in pairs(require(script.Parent.VehicleVolume)({glow=glow,wedge=wedge,bone=bone,track=track,console=console,prism=prism}))do builders[k]=f end
for k,f in pairs(require(script.Parent.VehicleVolume2)({glow=glow,wedge=wedge,bone=bone,track=track,console=console,prism=prism}))do builders[k]=f end
local byTier={scout,armored,hover,skiff,walker}
local Meshes=require(script.Parent.CosmeticMeshes)
local function meshFill(m,style)
    local list=Meshes.build(m,style.id,{groundCap=5,colors={primary=rgb(style.primary),secondary=rgb(style.secondary),accent=rgb(style.accent)}})
    if not list then return nil end
    local tier=style.tier or 1;local st={anim={},legs={},tracked={},tier=tier,mesh=true};local rate=tier>=5 and 1.4 or tier>=4 and 1.15 or 1
    local crest=Meshes.crestKind(style.id,tier,'vehicle')
    if crest then
        local lo,hi;for _,r in ipairs(list)do local h=r.part.Size/2;local c=r.home.Position;lo=lo and lo:Min(c-h)or c-h;hi=hi and hi:Max(c+h)or c+h end
        Meshes.crest(m,list,crest,CFrame.new((lo.X+hi.X)/2,lo.Y+.06,(lo.Z+hi.Z)/2),math.max(hi.X-lo.X,hi.Z-lo.Z)*.62,rgb(style.accent))
    end
    for _,r in ipairs(list)do
        local hue=Meshes.prismatic(r,tier)
        if r.kind or r.phase or hue then
            track(st,r.part,'fn',{fn=function(a,time,speed,phase,reduced)
                if r.phase then a.part.Transparency=phase<r.phase and 1 or a.base end
                if hue and not reduced then a.part.Color=Meshes.prism(time*.06+r.index*.07)end
                if r.kind and not reduced then return Meshes.motion(r,time,speed,rate,st)*a.home end
            end})
        end
    end
    m:SetAttribute('MeshItem',style.id)
    return st
end
local function meshSwap(m,style)
    if not states[m]or states[m].mesh then return end
    local pivot,scale=m:GetPivot(),m:GetScale()
    for _,c in ipairs(m:GetChildren())do if c:IsA('BasePart')then c:Destroy()end end
    if scale~=1 then m:ScaleTo(1)end;m.WorldPivot=CFrame.identity
    local st=meshFill(m,style);if not st then return end;states[m]=st
    if scale~=1 then m:ScaleTo(scale)end;m:PivotTo(pivot)
    M.step(m,0,0,true,3)
end
function M.model(style)
    local m=Instance.new('Model');m.Name='CommanderVehicle';m.WorldPivot=CFrame.identity
    local mesh=style.tier and Meshes.ready(style.id)and meshFill(m,style)
    if mesh then
        states[m]=mesh;m:SetAttribute('AppearanceOnly',true);m:SetAttribute('VehicleSkin',style.id)
        M.step(m,0,0,true,3);return m
    end
    if style.tier and Meshes.has(style.id)then Meshes.watchModel(style.id,m,function()meshSwap(m,style)end)end
    local dark=rgb(style.primary);local trim=rgb(style.secondary);local accent=rgb(style.accent);local tier=style.tier or 1
    local st={anim={},legs={},tracked={},tier=tier};states[m]=st
    local build=style.tier and(builders[style.theme]or byTier[tier])
    if build then build(m,st,dark,trim,accent)else classic(m,dark,trim,accent)end
    for _,a in ipairs(st.anim)do st.tracked[a.part]=true end
    for _,l in ipairs(st.legs)do for _,k in ipairs({'thigh','shin','strip','knee','foot'})do if l[k]then st.tracked[l[k]]=true end end end
    if st.body or build==hover or build==skiff or build==walker then
        if not st.body then st.float=build~=walker;st.body=true end
        for _,p in ipairs(m:GetChildren())do if p:IsA('BasePart')and not st.tracked[p]then track(st,p,'still')end end
    end
    local sig=({[4]={CFrame.new(0,.3,.3),1.5},[5]={CFrame.new(0,.3,0),1.6}})[tier]or{CFrame.new(0,.28,0),1.05}
    Art.apply(m,style,'vehicle',sig[1],sig[2])
    m:SetAttribute('AppearanceOnly',true);m:SetAttribute('VehicleSkin',style.id)
    M.step(m,0,0,true,3)
    return m
end
local function legPose(leg,hip,foot)
    local d=foot-hip;local len=math.min(d.Magnitude,leg.l1+leg.l2-.01);local dir=d.Unit
    local a=(leg.l1^2-leg.l2^2+len^2)/(2*len);local h=math.sqrt(math.max(0,leg.l1^2-a^2))
    local up=(Vector3.yAxis+Vector3.new(leg.side*.35,0,0)-dir*dir:Dot(Vector3.yAxis+Vector3.new(leg.side*.35,0,0))).Unit
    local knee=hip+dir*a+up*h
    return knee
end
function M.step(model,time,speed,reduced,phase)
    local st=states[model];if not st or(#st.anim==0 and #st.legs==0)then return end
    phase=phase or 1;speed=speed or 0
    if reduced then if st.rest==phase then return end;st.rest=phase;time=0;speed=0 else st.rest=nil end
    local pivot=model:GetPivot();local scale=model:GetScale()
    local function put(p,cf)p.CFrame=pivot*CFrame.new(cf.Position*scale)*cf.Rotation end
    local stride=math.clamp(speed/10,0,1)
    local dt=math.clamp(time-(st.clock or time),0,.25);st.clock=time
    if reduced then st.gait,st.wheel,st.leg=0,0,0
    else st.gait=(st.gait or 0)+dt*(6+stride*3);st.wheel=(st.wheel or 0)+dt*math.max(speed,.6);st.leg=(st.leg or 0)+dt*(5+stride*3)end
    local gait=st.gait
    local bob=reduced and 0 or st.float and math.sin(time*2.4)*.07 or #st.legs>0 and(stride*math.abs(math.sin(gait))*.06+math.sin(time*1.6)*.02)or 0
    local lift=CFrame.new(0,bob,0)
    if st.rock and not reduced then lift*=CFrame.Angles(math.sin(time*1.7)*st.rock,0,math.sin(time*1.3+1)*st.rock*.7)end
    for i,a in ipairs(st.anim)do
        local p=a.part;local cf=a.home;local k=a.kind
        if k=='spin'then cf=a.pivot*CFrame.Angles(0,0,time*a.rate)*a.pivot:Inverse()*cf
        elseif k=='wave'then cf=a.pivot*CFrame.Angles(0,math.sin(time*3.2)*.3,0)*a.pivot:Inverse()*cf*CFrame.Angles(0,math.sin(time*3.2-1)*.15,0)
        elseif k=='pulse'then p.Transparency=math.clamp(a.base+(math.sin(time*a.rate+a.offset)*.5+.5)*a.range,0,1)
        elseif k=='blink'then p.Transparency=reduced and 0 or((time*1.3+(a.offset>0 and .5 or 0))%1<.5 and 0 or .8)
        elseif k=='prism'then if not reduced then p.Color=prism(time*.06+i*.05)end
        elseif k=='phase'then p.Transparency=(a.phase>phase)and 1 or a.base
        elseif k=='fn'then cf=a.fn(a,time,speed,phase,reduced)or cf end
        if st.body and not a.ground then cf=lift*cf end
        put(p,cf)
    end
    for _,leg in ipairs(st.legs)do
        local s=gait+leg.offset;local swing=math.sin(s)
        local foot=leg.rest+Vector3.new(0,math.max(0,swing)*(leg.lift or .6)*stride,math.cos(s)*(leg.reach or .7)*stride)
        local hip=leg.hip+Vector3.new(0,bob,0);local knee=legPose(leg,hip,foot)
        put(leg.thigh,bone(hip,knee));local shin=bone(knee,foot);put(leg.shin,shin)
        if leg.strip then put(leg.strip,shin*CFrame.new(leg.side*.13,0,0))end;if leg.knee then put(leg.knee,CFrame.new(knee))end
        put(leg.foot,CFrame.new(foot+Vector3.new(0,.05,0))*CFrame.Angles(math.max(0,swing)*stride*.3,0,0))
        if leg.knee and not reduced then leg.knee.Color=prism(time*.06+leg.side*.1+leg.fore*.2)end
    end
end
local prefetchSlots={'vehicle','parachute','city','defensePost','projectile','commanderOrder'}
function M.watch(context)
    if M.started then return end;M.started=true
    local Players=game:GetService('Players');local states={};local scan=0;local budget=0
    local folder=Instance.new('Folder');folder.Name='CommanderVehicles';folder.Parent=workspace
    game:GetService('RunService').RenderStepped:Connect(function(dt)
        scan+=dt;budget+=dt;local art=budget>=1/30;if art then budget=math.min(budget-1/30,1/30)end
        local now=os.clock();local me=Players.LocalPlayer
        local Stage=require(script.Parent.LobbyStage)
        if scan>=.25 then scan=0;for _,p in ipairs(Players:GetPlayers())do
            local stand=Stage.standFor(p);local c=stand and stand.clone or p.Character;local id=p:GetAttribute('CommanderCosmetic_vehicle')or 'classic';local old=states[p]
            for _,slot in ipairs(prefetchSlots)do Meshes.prefetch(p:GetAttribute('CommanderCosmetic_'..slot))end;Meshes.prefetchStandard(p:GetAttribute('CommanderStandardStyle'))
            if old and(old.character~=c or old.id~=id)then old.model:Destroy();M.riders[old.character]=nil;if old.real then M.riders[old.real]=nil end;states[p]=nil;old=nil end
            local s=C.styles[id]
            if not old and c and c.PrimaryPart and s and s.category=='vehicle'then
                states[p]={character=c,id=id,model=M.model(s),style=s,time=0}
            end
            local v=states[p];if v then local real=stand and stand.real or nil
                if v.real~=real then if v.real then M.riders[v.real]=nil end;v.real=real end
                if real then M.riders[real]=v.visible or nil end
            end
        end end
        local camera=workspace.CurrentCamera;if not camera then return end
        local reduced=me:GetAttribute('CommanderReducedEffects')==true
        for p,v in pairs(states)do
            local c=v.character;local root=c.PrimaryPart;local hum=c:FindFirstChildOfClass('Humanoid')
            if not p.Parent or not c.Parent or not root then v.model:Destroy();M.riders[c]=nil;if v.real then M.riders[v.real]=nil end;states[p]=nil
            else
                local shown=context(p);local point=camera:WorldToViewportPoint(root.Position);local far=(root.Position-camera.CFrame.Position).Magnitude
                local visible=shown and root.LocalTransparencyModifier<.95 and far<180 and point.Z>0 and point.X>=-60 and point.X<=camera.ViewportSize.X+60 and point.Y>=-60 and point.Y<=camera.ViewportSize.Y+60
                if v.visible~=visible then v.visible=visible;v.lastAt=nil;v.artAt=nil;v.model.Parent=visible and folder or nil;M.riders[c]=visible or nil end
                if visible then
                    local floor=.1*2*far*math.tan(math.rad(camera.FieldOfView)/2)/2.6
                    local scale=math.clamp(math.max(root.Size.Y/2,floor),.65,1.6);scale=math.floor(scale*20+.5)/20
                    if v.scale~=scale then v.scale=scale;v.model:ScaleTo(scale)end
                    local leg=c:FindFirstChild('Left Leg');local feet=(hum and hum.HipHeight or 0)+root.Size.Y/2+(leg and leg.Size.Y or 0)
                    v.model:PivotTo(root.CFrame*CFrame.new(0,-feet+.08,0))
                    if art or p==me or far<70 then
                    local step=math.clamp(now-(v.artAt or now-1/30),0,.25);v.artAt=now;v.time+=step
                    local at=root.Position;local last=v.lastAt;v.lastAt=at
                    local raw=last and step>0 and (at-last).Magnitude<40 and Vector3.new(at.X-last.X,0,at.Z-last.Z).Magnitude/step or 0
                    v.speed=(v.speed or raw)+(raw-(v.speed or raw))*(1-math.exp(-step*8))
                    local moving=v.speed>1
                    v.movingFor=moving and(v.movingFor or 0)+step or 0
                    local phase=v.style.tier==5 and math.min(3,1+math.floor(v.movingFor/.7))or 1
                    M.step(v.model,v.time,v.speed/v.scale,reduced,phase)
                    Art.step(v.model,v.time,reduced,phase)
                    end
                end
            end
        end
    end)
    Players.PlayerRemoving:Connect(function(p)local v=states[p];if v then v.model:Destroy();M.riders[v.character]=nil;states[p]=nil end end)
end
return M
