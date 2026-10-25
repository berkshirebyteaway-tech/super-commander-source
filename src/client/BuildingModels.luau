local Geo=require(script.Parent.ToyGeometry)
local Display=require(script.Parent.Parent.Core.MapPresentation)
local Themes=require(script.Parent.BuildingThemes)
local M={}
local function rgb(a)return Color3.fromRGB(table.unpack(a))end
local dark=Color3.fromRGB(22,29,38)
local slab=Color3.fromRGB(46,57,70)
local ice=Color3.fromRGB(211,223,235)
local amber=Color3.fromRGB(255,185,56)
local warm=Color3.fromRGB(255,206,128)
local crane=Color3.fromRGB(238,174,46)
local steel=Color3.fromRGB(172,184,198)
local water=Color3.fromRGB(34,104,142)
local roles={City="skyline",DefensePost="star-bastion",Port="gantry-crane",Factory="rail-train",MissileSilo="vertical-missile",SAMLauncher="radar-launcher"}
M.roles=roles
local blocks
M.previewOrder={"City","Port","MissileSilo","Factory","DefensePost","SAMLauncher"}
function M.create(kind,style,level,detail,ownerColor)
    level=math.clamp(level or 1,1,3);local detailed=detail~=false
    if not roles[kind]then error("Unknown building model: "..tostring(kind))end
    if Themes.has(style)then
        local model=Themes.create(kind,style,level,detailed,ownerColor)
        for _,p in ipairs(model:GetChildren())do if p:IsA("BasePart")then
            if p.Size.Magnitude<.7 then p.CastShadow=false end
            if p.Name=="RadarDish"then model:SetAttribute("RadarLocal",p.CFrame)end
        end end
        model:SetAttribute("VisualLevel",level);model:SetAttribute("Detailed",detailed);model:SetAttribute("Theme","WarRoomV4")
        model:SetAttribute("RoleSilhouette",roles[kind]);model:SetAttribute("PartCount",#model:GetChildren());return model
    end
    if style.access=="free"and not style.tier and Themes.defaultKey(kind)then
        local model=Themes.createDefault(kind,level,detailed,ownerColor or rgb(style.territory or style.accent),function()return blocks(kind,style,level,detailed,ownerColor)end)
        if model:GetAttribute("MeshItem")then
            model:SetAttribute("VisualLevel",level);model:SetAttribute("Detailed",detailed);model:SetAttribute("Theme","WarRoomV4")
            model:SetAttribute("RoleSilhouette",roles[kind]);model:SetAttribute("PartCount",#model:GetChildren())
        end
        return model
    end
    return blocks(kind,style,level,detailed,ownerColor)
end
blocks=function(kind,style,level,detailed,ownerColor)
    local model=Instance.new("Model");model.Name=kind
    local body=rgb(style.primary):Lerp(ice,style.tier and style.tier>=3 and .24 or .45)
    local trim=rgb(style.secondary);local signal=rgb(style.accent)
    local owner=ownerColor or rgb(style.territory or style.accent)
    local socket=owner:Lerp(dark,.45)
    local deck=slab:Lerp(owner,.2)
    local function cf(x,y,z)return CFrame.new(x,y,z)end
    local function b(name,size,pos,color,rotation,shape)
        local frame=cf(table.unpack(pos))*(rotation or CFrame.identity)
        if shape then return Geo.part(model,name,Vector3.new(table.unpack(size)),frame,color,shape)end
        return Geo.block(model,name,Vector3.new(table.unpack(size)),frame,color)
    end
    local function lit(name,size,pos,color,rotation)
        local p=b(name,size,pos,color,rotation);p.Material=Enum.Material.Neon;p.Transparency=.08;p.CastShadow=false;return p
    end
    local function metal(p)p.Material=Enum.Material.Metal;p.Reflectance=.03;return p end
    local function cyl(name,r,h,pos,color,rotation)return Geo.cylinder(model,name,r,h,cf(table.unpack(pos))*(rotation or CFrame.identity),color)end
    local function rod(name,a,c,r,color)return Geo.rod(model,name,Vector3.new(table.unpack(a)),Vector3.new(table.unpack(c)),r,color)end
    local floor=.31
    Geo.shadow(model,0,0,2.25).Color=dark
    if kind=="MissileSilo"then
        cyl("ConcretePad",2.05,.26,{0,.13,0},socket)
        cyl("PadTop",1.88,.05,{0,.285,0},deck)
    elseif kind=="Port"then
        b("ConcretePad",{4.3,.3,1.9},{0,.15,-1.2},socket,nil,"armor")
        b("PadTop",{4.1,.05,1.72},{0,.305,-1.2},deck,nil,"board")
    else
        b("ConcretePad",{4.2,.26,4.2},{0,.13,0},socket,nil,"armor")
        b("PadTop",{3.86,.05,3.86},{0,.285,0},deck,nil,"board")
    end
    model.ConcretePad.Material=Enum.Material.Concrete
    local front=kind=="Port"and -.25 or kind=="MissileSilo"and 1.72 or 2.02
    b("OwnerBand",{kind=="MissileSilo"and 1.5 or 2.3,.09,.1},{0,.28,front+.03},owner)
    lit("StatusBeacon",{.34,.08,.18},{kind=="MissileSilo"and -1.0 or -1.6,.33,front-.1},ice)
    if kind=="City"then
        local hero=2.3+.5*(level-1)
        local towers={{-.6,-.55,1.3,1.3,hero},{.85,-.85,1.0,1.0,1.7+.4*(level-1)},{.8,.78,1.05,1.0,1.15+.3*(level-1)}}
        if level>=2 then table.insert(towers,{-1.0,1.05,.95,.85,.9+.25*(level-2)})end
        for i,t in ipairs(towers)do
            local x,z,w,depth,height=table.unpack(t)
            b("TowerBlock"..i,{w,height,depth},{x,floor+height/2,z},body,nil,"armor")
            if detailed then
                b("TowerCap"..i,{w+.07,.12,depth+.07},{x,floor+height+.06,z},trim,nil,"armor")
                for _,s in ipairs({-1,1})do lit("Window",{w*.17,height*.72,.04},{x+s*w*.2,floor+height*.5,z+depth/2+.02},warm)end
            else
                lit("Window",{w*.56,height*.7,.04},{x,floor+height*.5,z+depth/2+.02},warm)
            end
        end
        b("TowerCrown",{.8,.42,.8},{-.6,floor+hero+.33,-.55},body:Lerp(trim,.25),nil,"armor")
        if detailed then
            lit("Window",{.04,hero*.72,1.3*.17},{-.6+.65+.02,floor+hero*.5,-.55+.26},warm)
            lit("Window",{.04,hero*.72,1.3*.17},{-.6+.65+.02,floor+hero*.5,-.55-.26},warm)
            rod("Spire",{-.6,floor+hero+.54,-.55},{-.6,floor+hero+1.0,-.55},.045,trim)
        end
    elseif kind=="DefensePost"then
        local h=.72+.18*(level-1);local s=3.3
        if detailed then b("Courtyard",{2.5,.04,2.5},{0,floor+.02,0},deck:Lerp(dark,.35),nil,"board")end
        for _,side in ipairs({-1,1})do
            b("Wall",{s-.9,h,.42},{0,floor+h/2,side*(s/2-.21)},body,nil,"armor")
            b("Wall",{.42,h,s-.9},{side*(s/2-.21),floor+h/2,0},body,nil,"armor")
        end
        for _,c in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}})do
            b("Bastion",{1.0,h+.2,1.0},{c[1]*1.5,floor+(h+.2)/2,c[2]*1.5},body:Lerp(trim,.18),CFrame.Angles(0,math.rad(45),0),"armor")
            if detailed then b("BastionCap",{.82,.08,.82},{c[1]*1.5,floor+h+.24,c[2]*1.5},trim,CFrame.Angles(0,math.rad(45),0))end
        end
        local keep=1.05+.22*(level-1)
        cyl("BunkerCore",.74,keep,{0,floor+keep/2,0},body:Lerp(trim,.1))
        b("TurretHead",{.72,.3,.72},{0,floor+keep+.27,0},body,nil,"armor")
        if detailed then
            cyl("KeepRim",.8,.12,{0,floor+keep+.06,0},trim)
            rod("TurretBarrel",{.15,floor+keep+.3,.15},{.85,floor+keep+.36,.85},.08,dark)
        end
        if level>=2 then b("Gatehouse",{1.1,h+.34,.62},{0,floor+(h+.34)/2,s/2-.21},body:Lerp(trim,.22),nil,"armor")
            if detailed then b("GateDoor",{.5,.42,.04},{0,floor+.21,s/2+.11},dark)end
        end
        if level>=3 and detailed then for _,x in ipairs({-1.5,1.5})do
            cyl("BastionGun",.24,.2,{x,floor+h+.3,1.5},body)
            rod("BastionBarrel",{x,floor+h+.34,1.5},{x+.42*math.sign(x),floor+h+.38,1.92},.05,dark)
        end end
        metal(rod("FlagPole",{-1.5,floor+h+.2,-1.5},{-1.5,floor+h+1.7,-1.5},.045,trim))
        b("Flag",{.86,.5,.05},{-1.5+.45,floor+h+1.43,-1.5},owner:Lerp(ice,.08))
    elseif kind=="Port"then
        b("Basin",{4.3,.06,2.5},{0,.03,.95},water)
        for _,s in ipairs({-1,1})do b("Pier",{.42,.26,2.4},{s*1.94,.13,.95},deck,nil,"armor")end
        local H=2.45+.25*(level-1);local top=.33+H
        if detailed then for _,x in ipairs({-.55,.55})do for _,z in ipairs({-1.6,-.42})do metal(rod("CraneLeg",{x,.33,z},{x,top,z},.075,crane))end end
        else for _,x in ipairs({-.55,.55})do metal(b("CraneLeg",{.15,H,1.33},{x,.33+H/2,-1.01},crane))end end
        metal(b("CranePortal",{1.32,.2,1.4},{0,top,-1.01},crane,nil,"armor"))
        metal(b("CraneBoom",{.34,.24,4.05},{0,top+.22,.12},crane,nil,"armor"))
        b("CraneHouse",{.78,.44,.72},{0,top+.56,-1.2},ice,nil,"armor")
        if detailed then rod("CraneCable",{0,top+.1,1.35},{0,.95,1.35},.03,dark)end
        local hull=Color3.fromRGB(78,90,108)
        b("Hull",{2.55,.42,.86},{-.2,.25,1.15},hull,nil,"armor")
        cyl("Bow",.43,.42,{1.07,.25,1.15},hull)
        b("Bridge",{.42,.52,.66},{-1.2,.72,1.15},ice,nil,"armor")
        for i,c in ipairs({owner:Lerp(ice,.12),trim,crane})do
            if detailed or i<3 then b("Container",{.62,.3,.66},{-.72+i*.66,.61,1.15},c,nil,"armor")end
        end
        if detailed then
            b("QuayCargo",{.95,.34,.55},{-1.45,.5,-1.45},owner:Lerp(body,.35),nil,"armor")
            b("QuayCargo",{.95,.34,.55},{1.45,.5,-1.45},trim,nil,"armor")
        end
        if level>=2 and detailed then for i,c in ipairs({trim,owner:Lerp(ice,.12)})do b("Container",{.62,.3,.66},{-.72+i*.66,.91,1.15},c,nil,"armor")end end
        if level>=3 then
            for _,z in ipairs({-1.6,-.42})do metal(b("CraneLeg",{.16,H*.78,.16},{-1.45,.33+H*.39,z},crane))end
            metal(b("CraneBoom2",{.28,.2,3.4},{-1.45,.33+H*.78+.1,-.05},crane,nil,"armor"))
        end
    elseif kind=="Factory"then
        for _,z in ipairs({.95,-.2})do
            b("Ballast",{5.5,.06,.66},{.5,floor+.03,z},Color3.fromRGB(70,76,88))
            for _,s in ipairs({-1,1})do metal(b("Rail",{5.5,.07,.07},{.5,floor+.095,z+s*.21},steel))end
        end
        metal(b("ExitGate",{.26,.16,2.15},{2.12,floor+1.02,.375},trim,nil,"armor"))
        b("ExitGateBand",{.27,.05,1.6},{2.12,floor+1.12,.375},owner)
        if detailed then for _,z in ipairs({-.7,1.45})do metal(rod("ExitGatePost",{2.12,floor,z},{2.12,floor+.96,z},.06,steel))end end
        b("Locomotive",{1.5,.56,.6},{.62,floor+.43,.95},ice,nil,"armor")
        b("LocoStripe",{1.52,.13,.62},{.62,floor+.4,.95},owner)
        b("TrainCab",{.52,.3,.62},{.1,floor+.86,.95},trim,nil,"armor")
        b("LocoNose",{.3,.36,.54},{1.5,floor+.33,.95},slab,nil,"armor")
        if detailed then lit("Headlight",{.05,.12,.26},{1.66,floor+.38,.95},warm)end
        b("CargoWagon",{1.05,.46,.58},{-.75,floor+.38,.95},body,nil,"armor")
        b("ContainerWagon",{1.0,.52,.6},{-1.85,floor+.41,.95},crane,nil,"armor")
        b("Platform",{3.6,.18,.55},{0,floor+.09,-1.0},deck:Lerp(trim,.3),nil,"armor")
        if level>=2 then
            b("TankWagon",{1.3,.4,.5},{1.05,floor+.33,-.2},trim:Lerp(body,.4),nil,"armor")
            b("ShuntEngine",{.8,.48,.52},{-.15,floor+.37,-.2},ice,nil,"armor")
        end
        if level>=3 then b("PlatformCanopy",{3.2,.08,.72},{0,floor+1.0,-1.02},trim,nil,"armor")
            if detailed then for _,x in ipairs({-1.4,1.4})do metal(rod("CanopyPost",{x,floor+.18,-1.2},{x,floor+.98,-1.2},.04,steel))end end
        end
        if detailed then
            lit("SignalLamp",{.12,.18,.12},{-1.95,floor+.75,-.75},amber)
            metal(rod("SignalPost",{-1.95,floor,-.75},{-1.95,floor+.7,-.75},.045,steel))
        end
    elseif kind=="MissileSilo"then
        cyl("HazardRing",1.35,.04,{0,floor+.01,0},amber)
        cyl("RingInner",1.12,.05,{0,floor+.015,0},deck:Lerp(dark,.3))
        b("LaunchWell",{1.9,.06,1.9},{0,floor+.04,-.1},Color3.fromRGB(12,16,22))
        for _,s in ipairs({-1,1})do
            local door=b("HatchDoor",{1.9,.1,.62},{0,floor+.17,-.1+s*1.27},trim,CFrame.Angles(-s*math.rad(24),0,0),"armor")
            local stripe=b("HatchStripe",{1.76,.02,.1},{0,0,0},amber);stripe.CFrame=door.CFrame*cf(0,.06,s*.18)
        end
        local spots=level==1 and {{0,0}}or level==2 and {{-.5,.05},{.5,.05}}or {{-.56,.32},{.56,.32},{0,-.6}}
        local r=level==1 and .34 or .29;local length=level==1 and 2.75 or 2.45
        cyl("SiloCollar",level==1 and .72 or .92,.3,{0,floor+.15,0},trim)
        for i,spot in ipairs(spots)do
            local x,z=spot[1],spot[2];local suffix=i==1 and ""or tostring(i)
            cyl("Missile"..suffix,r,length,{x,floor+.3+length/2,z},ice)
            Geo.ball(model,"MissileNose"..suffix,Vector3.new(r*2,r*2,r*2),cf(x,floor+.3+length,z),ice)
            if detailed then rod("MissileTip"..suffix,{x,floor+.3+length+r*.55,z},{x,floor+.3+length+r*1.8,z},.065,ice)end
            cyl("MissileBand",r+.006,.22,{x,floor+.3+length*.78,z},owner)
        end
        if level==1 and detailed then
            for i=0,3 do
                b("MissileFin",{.08,.55,.36},{0,0,0},body).CFrame=cf(0,floor+.62,0)*CFrame.Angles(0,i*math.pi/2+math.pi/4,0)*cf(0,0,.44)
            end
        end
        b("ServiceTower",{.34,3.0,.34},{-1.32,floor+1.5,-.55},slab,nil,"armor")
        if detailed then for _,y in ipairs({1.4,2.35})do metal(b("ServiceArm",{.62,.09,.12},{-.98,floor+y,-.45},steel))end end
    elseif kind=="SAMLauncher"then
        b("Chassis",{1.95,.36,1.55},{.5,floor+.18,.5},body,nil,"armor")
        if detailed then for _,s in ipairs({-1,1})do b("Stabilizer",{.16,.12,1.9},{.5+s*1.08,floor+.06,.5},trim)end end
        cyl("Turntable",.5,.16,{.5,floor+.44,.5},trim)
        local pack=cf(.5,floor+.95,.42)*CFrame.Angles(math.rad(-40),0,0)
        Geo.part(model,"LauncherTube",Vector3.new(1.18,.22,1.0),pack*cf(0,-.38,-.1),body:Lerp(dark,.3),"armor")
        local columns=level==1 and {-.29,.29}or {-.44,0,.44}
        if level>=2 and detailed then Geo.part(model,"LauncherWing",Vector3.new(1.5,.22,1.0),pack*cf(0,-.38,-.1),body:Lerp(dark,.3),"armor")end
        if not detailed then
            Geo.part(model,"Tube",Vector3.new(#columns*.44+.1,.84,1.5),pack*cf(0,.14,0),trim,"armor")
            Geo.block(model,"MissileCap",Vector3.new(#columns*.44-.04,.7,.05),pack*cf(0,.14,.76),dark)
        end
        for _,x in ipairs(detailed and columns or {})do for _,y in ipairs({-.08,.36})do
            local tube=Geo.cylinder(model,"Tube",.21,1.6,pack*cf(x,y,0)*CFrame.Angles(math.pi/2,0,0),trim)
            tube.Material=Enum.Material.SmoothPlastic
            Geo.cylinder(model,"MissileCap",.15,.04,pack*cf(x,y,.81)*CFrame.Angles(math.pi/2,0,0),dark)
        end end
        b("RadarCabin",{1.0,.55,.9},{-1.05,floor+.275,-.95},trim:Lerp(body,.35),nil,"armor")
        rod("RadarMast",{-1.05,floor+.55,-.95},{-1.05,floor+1.55,-.95},.09,trim)
        local span=level>=3 and 2.0 or 1.75
        local dish=Geo.part(model,"RadarDish",Vector3.new(span,.5,span),cf(-1.05,floor+1.8,-.95)*CFrame.Angles(math.rad(48),math.rad(28),0),ice,"dish")
        metal(dish)
    else model:Destroy();error("Unknown building model: "..tostring(kind))end
    if level>=2 then b("LevelStripe",{.36+.22*(level-2),.07,.13},{kind=="MissileSilo"and 1.0 or 1.36,.33,front-.1},Color3.fromRGB(245,196,81))end
    for _,p in ipairs(model:GetChildren())do if p:IsA("BasePart")then
        if p.Size.Magnitude<.7 then p.CastShadow=false end
        if p.Name=="RadarDish"then model:SetAttribute("RadarLocal",p.CFrame)end
    end end
    require(script.Parent.RoofReadability).apply(model,kind,detailed)
    local tier=style.tier or 0
    if tier>=3 then
        if kind=='City'then
            for i=0,2 do local a=i*math.pi*2/3
                local fin=b('SkylineBlade',{.15,1.6,.38},{-.6+math.cos(a)*.76,1.65,-.55+math.sin(a)*.76},trim,CFrame.Angles(0,-a,math.rad(-10)),'armor');metal(fin)
            end
        elseif kind=='DefensePost'then
            for _,s in ipairs({-1,1})do metal(b('CitadelShield',{.2,.85,1.1},{s*1.6,.95,0},trim,CFrame.Angles(0,0,s*.12),'armor'))end
        elseif kind=='Port'then
            for _,s in ipairs({-1,1})do metal(b('CraneWing',{.68,.14,1.2},{s*.6,3.25,-1},trim,CFrame.Angles(0,0,s*.18),'armor'))end
        elseif kind=='Factory'then metal(b('TerminalRoof',{2.7,.12,.85},{-.4,1.45,-1.1},trim,nil,'armor'))
        elseif kind=='MissileSilo'then
            for _,s in ipairs({-1,1})do metal(b('GantryFin',{.1,.9,.42},{-1.32+s*.24,2.8,-.55},trim,CFrame.Angles(0,0,s*.18),'armor'))end
        elseif kind=='SAMLauncher'then metal(b('RadarFairing',{.85,.12,.85},{-1.05,1.06,-.95},trim,nil,'armor'))end
    end
    local crowns={City={-.6,floor+2.3+.5*(level-1)+.58,-.55,.72},DefensePost={0,floor+1.05+.22*(level-1)+.48,0,.67},Port={0,3.25,-1,.67},Factory={-.4,1.47,-1.1,.68},MissileSilo={-1.32,3.35,-.55,.43},SAMLauncher={.5,1.75,.6,.6}}
    local crown=crowns[kind];require(script.Parent.CollectionArt).apply(model,style,kind,CFrame.new(crown[1],crown[2],crown[3]),crown[4])
    require(script.Parent.BuildingRoleSkins).apply(model,kind,style)
    model.WorldPivot=CFrame.new();model:SetAttribute("VisualLevel",level);model:SetAttribute("Detailed",detailed);model:SetAttribute("Theme","WarRoomV4")
    model:SetAttribute("RoleSilhouette",roles[kind]);model:SetAttribute("PartCount",#model:GetChildren());return model
end
function M.state(model,u)
    local status=Display.status(u,0)
    local changed=model:GetAttribute("DisplayStatus")~=status or model:GetAttribute("ReadyMissiles")~=u.readyMissiles
    if not changed then return end
    model:SetAttribute("DisplayStatus",status);model:SetAttribute("ReadyMissiles",u.readyMissiles)
    local lamp=model:FindFirstChild("StatusBeacon")
    if lamp then lamp.Color=(status=="building"or status=="reloading"or status=="deleting")and amber or ice;lamp.Transparency=.08 end
    for i=1,3 do
        local suffix=i==1 and ""or tostring(i)
        local missile=model:FindFirstChild("Missile"..suffix)
        if missile then
            local ready=u.readyMissiles==nil or u.readyMissiles>=i
            for _,name in ipairs({"Missile","MissileNose","MissileTip"})do local p=model:FindFirstChild(name..suffix);if p then p.Color=ready and (p:GetAttribute("ReadyColor")or ice)or slab end end
        end
    end
end
function M.animate(model,at,reduced,batch)
    require(script.Parent.CollectionArt).step(model,at,reduced,model:GetAttribute('CollectionPhase'),batch)
    require(script.Parent.BuildingRoleSkins).step(model,at,reduced,batch)
    local dish=model:FindFirstChild("RadarDish");local localFrame=model:GetAttribute("RadarLocal")
    if dish and localFrame then
        local aim=model:GetPivot()*CFrame.new(localFrame.Position)*CFrame.Angles(0,reduced and 0 or at*.55,0)*(localFrame-localFrame.Position)
        local feed=model:FindFirstChild('RadarFeed')
        if batch then batch:put(dish,aim);if feed then batch:put(feed,aim*model:GetAttribute('RadarFeedOffset'))end
        else dish.CFrame=aim;if feed then feed.CFrame=aim*model:GetAttribute('RadarFeedOffset')end end
    end
end
M.modelScale=.88
function M.resize(model,scale)
    scale=scale or M.modelScale;if scale==1 then return model end
    model:ScaleTo(model:GetScale()*scale)
    local dish=model:FindFirstChild("RadarDish");if dish and model:GetAttribute("RadarLocal")then model:SetAttribute("RadarLocal",model:GetPivot():ToObjectSpace(dish.CFrame))end
    return model
end
function M.preview(parent,kind,style)
    local frame=Instance.new("ViewportFrame");frame.Name="BuildingPreview";frame.Size=UDim2.fromOffset(70,62);frame.BackgroundTransparency=1
    frame.Ambient=Color3.fromRGB(150,163,181);frame.LightColor=Color3.fromRGB(238,244,255);frame.LightDirection=Vector3.new(-1,-2,-1);frame.Parent=parent
    local camera=Instance.new("Camera");camera.FieldOfView=34;camera.CFrame=CFrame.lookAt(Vector3.new(6.4,6.6,7.6),Vector3.new(0,1.35,0));camera.Parent=frame;frame.CurrentCamera=camera
    local model=M.create(kind,style,kind=="City"and 2 or 1,true);model.Parent=frame;return frame
end
Themes.prefetchDefault()
return M
