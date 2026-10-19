local G=require(script.Parent.ToyGeometry)
local M={}
local Neon=Enum.Material.Neon
local function rgb(c)return Color3.fromRGB(table.unpack(c))end
local function prism(h,sat)local f=h%1;return Color3.fromHSV(.45+.47*(1-math.abs(2*f-1)),sat,1)end
local function edge(a,b,back,offset)
    local x=(b-a).Unit;local z=(back-x*back:Dot(x)).Unit;local y=z:Cross(x)
    if y.Y<0 then x,y=-x,-y end
    return CFrame.fromMatrix((a+b)/2+(offset or Vector3.zero),x,y,z)
end
local builders={}
function builders.military(add,anim,dark,trim,accent)
    local R,H,rim,N=3.5,2.5,-1.4,10;local rings={0,.5,.95,1.3}
    local function pt(phi,ang)local r=R*math.cos(phi);return Vector3.new(math.sin(ang)*r,rim+H*math.sin(phi),-math.cos(ang)*r)end
    for i=0,N-1 do
        local ang=(i+.5)/N*math.pi*2;local tangent=Vector3.new(math.cos(ang),0,math.sin(ang))
        local col=i%2==0 and dark:Lerp(trim,.18)or dark:Lerp(trim,.42)
        for j=1,#rings-1 do
            local a,b=pt(rings[j],ang),pt(rings[j+1],ang);local up=(b-a).Unit
            add('Gore',Vector3.new(2*math.pi*R*math.cos(rings[j])/N*1.05,(b-a).Magnitude+.06,.1),CFrame.fromMatrix((a+b)/2,tangent,up,tangent:Cross(up)),col)
        end
        local a=pt(0,ang);local up=(pt(.5,ang)-a).Unit
        add('Skirt',Vector3.new(2*math.pi*R/N*1.06,.3,.14),CFrame.fromMatrix(a+up*.12,tangent,up,tangent:Cross(up)),nil,{tint='full'})
    end
    add('VentCap',Vector3.new(.14,2.0,2.0),CFrame.new(0,rim+H*math.sin(1.3)+.02,0)*CFrame.Angles(0,0,math.pi/2),dark:Lerp(trim,.3),{shape=Enum.PartType.Cylinder})
    add('Vent',Vector3.new(.1,.8,.8),CFrame.new(0,rim+H*math.sin(1.3)+.1,0)*CFrame.Angles(0,0,math.pi/2),trim,{shape=Enum.PartType.Cylinder})
    local anchors={};for k=0,7 do local p=pt(0,(k+.5)/8*math.pi*2);table.insert(anchors,p-Vector3.new(0,.1,0))end
    return {anchors=anchors,crest=CFrame.new(0,rim+H+.05,0)}
end
function builders.stripe(add,anim,dark,trim,accent)
    local anchors={}
    for i=-4,4 do
        local t=i/4.5;local chord=4.7-1.4*t*t
        local cf=CFrame.new(i*1.2,-1.7*t*t,0)*CFrame.Angles(0,0,math.rad(-t*24))
        local a=math.abs(i)
        add('Cell',Vector3.new(1.24,.5,chord),cf,a==2 and accent or a==4 and trim or dark,{tint=i==0 and 'full'or nil,mesh='soft'})
        add('AirIntake',Vector3.new(.9,.22,.06),cf*CFrame.new(0,-.06,-chord/2-.01),dark:Lerp(Color3.new(),.5))
        if a==1 or a==3 then add('Pinstripe',Vector3.new(.14,.04,chord*.92),cf*CFrame.new(i>0 and -.5 or .5,.25,0),trim)end
        if a==2 then add('EdgeGlow',Vector3.new(1.0,.07,.07),cf*CFrame.new(0,.02,chord/2+.02),accent,{glow=true,alpha=.15})end
        if a==2 or a==4 then for _,fore in ipairs({-1,1})do table.insert(anchors,(cf*CFrame.new(0,-.25,fore*chord*.32)).Position)end end
        if a==4 then
            add('Stabilizer',Vector3.new(.08,1.0,2.6),cf*CFrame.new(i>0 and .62 or -.62,-.4,.25),dark)
            add('StabilizerTrim',Vector3.new(.1,.08,2.4),cf*CFrame.new(i>0 and .62 or -.62,-.92,.3),accent)
        end
        if a<=1 then add('TrailingEdge',Vector3.new(1.1,.08,.16),cf*CFrame.new(0,.08,chord/2-.1),trim)end
        if i<4 then
            local u=(i+.5)/4.5;local rc=4.7-1.4*u*u
            add('CellRib',Vector3.new(.06,.56,rc*.98),CFrame.new((i+.5)*1.2,-1.7*u*u,0)*CFrame.Angles(0,0,math.rad(-u*24)),dark:Lerp(trim,.25))
        end
    end
    return {anchors=anchors,crest=CFrame.new(0,.28,0)}
end
function builders.glider(add,anim,dark,trim,accent)
    local anchors={};local lights={}
    add('Keel',Vector3.new(1.3,.34,4.0),CFrame.new(0,.1,-.1),dark:Lerp(trim,.1),{mesh='soft'})
    add('NoseLight',Vector3.new(.5,.1,.14),CFrame.new(0,.2,-2.12),trim,{glow=true})
    add('Spine',Vector3.new(.12,.06,3.6),CFrame.new(0,.29,-.1),nil,{tint='full',glow=true})
    for _,s in ipairs({-1,1})do
        local L={Vector3.new(s*.6,.1,-2.1),Vector3.new(s*3.0,-.3,-.3),Vector3.new(s*5.4,-1.3,1.6)}
        local chords={3.4,2.2};local back=Vector3.new(0,0,1)
        for k=1,2 do
            local a,b=L[k],L[k+1];local cf=edge(a,b,back)
            add('WingPanel',Vector3.new((b-a).Magnitude+.1,.22,chords[k]),cf*CFrame.new(0,0,chords[k]/2),dark:Lerp(accent,k==1 and .22 or .32),{mesh='soft'})
            add('Rib',Vector3.new(.07,.05,chords[k]*.9),cf*CFrame.new(0,.13,chords[k]/2),accent,{glow=true,alpha=.45})
            for q=0,2 do table.insert(lights,{add('OutlineLight',Vector3.new((b-a).Magnitude/3-.06,.12,.14),edge(a:Lerp(b,q/3),a:Lerp(b,(q+1)/3),back,Vector3.new(0,.08,0))*CFrame.new(0,0,-.04),accent,{glow=true}),k*3+q})end
            table.insert(lights,{add('TrailLight',Vector3.new((b-a).Magnitude,.09,.1),cf*CFrame.new(0,.06,chords[k]+.02),accent,{glow=true}),k*3+5})
            table.insert(anchors,(cf*CFrame.new(0,-.2,chords[k]*.25)).Position);table.insert(anchors,(cf*CFrame.new(0,-.2,chords[k]*.8)).Position)
        end
        local tip=L[3]+Vector3.new(s*.1,-.3,.95)
        add('Winglet',Vector3.new(.08,.9,1.8),CFrame.new(tip)*CFrame.Angles(0,0,s*.25),dark)
        table.insert(lights,{add('TipLight',Vector3.new(.08,.95,.09),CFrame.new(tip+Vector3.new(0,0,-.9))*CFrame.Angles(0,0,s*.25),trim,{glow=true}),12})
    end
    for _,l in ipairs(lights)do anim(l[1],'chase',{order=l[2],color=l[1].Color})end
    local keep={};for i,p in ipairs(anchors)do if i%4~=0 then table.insert(keep,p)end end
    return {anchors=keep,crest=CFrame.new(0,.35,.2)}
end
function builders.eagle(add,anim,dark,trim,accent,color)
    local bronze=accent:Lerp(dark,.35)
    add('Mantle',Vector3.new(2.2,.36,3.4),CFrame.new(0,.15,-.1),dark,{mesh='soft'})
    add('Crown',Vector3.new(.5,.06,2.8),CFrame.new(0,.35,-.1),nil,{tint='full'})
    add('Head',Vector3.new(.95,.7,1.05),CFrame.new(0,.38,-2.0),trim,{mesh='soft'})
    add('Beak',Vector3.new(.36,.34,.62),CFrame.new(0,.26,-2.68),accent,{wedge=true})
    for _,s in ipairs({-1,1})do add('Eye',Vector3.new(.06,.12,.14),CFrame.new(s*.47,.5,-2.2),accent,{glow=true})end
    for k=-2,2 do
        local yaw=k*.24;local len=2.4-math.abs(k)*.25
        anim(add('TailFeather',Vector3.new(.55,.1,len),CFrame.new(0,.08,1.55)*CFrame.Angles(0,yaw,0)*CFrame.new(0,0,len/2),k==0 and trim or (k%2==0 and accent or bronze)),'tail',{pivot=CFrame.new(0,.08,1.55)})
    end
    for _,s in ipairs({-1,1})do
        local hinge=CFrame.new(s*1.0,.2,-.3)
        local function wing(p)return anim(p,'wing',{pivot=hinge,side=s})end
        for k=0,2 do
            wing(add('Covert',Vector3.new(1.5,.3,1.6),CFrame.new(s*(1.75+k*1.3),.32-k*.06,-.55+k*.15)*CFrame.Angles(0,0,s*-.05),trim,{mesh='soft'}))
        end
        wing(add('ArmGlow',Vector3.new(3.8,.06,.12),CFrame.new(s*3.1,.42,-1.33),accent,{glow=true}))
        wing(add('UnderGlow',Vector3.new(3.6,.05,2.4),CFrame.new(s*3.1,-.06,.3),accent,{glow=true,alpha=.55}))
        for k=0,4 do
            local x=s*(1.5+k*.92);local len=2.7-k*.12
            wing(add('Secondary',Vector3.new(.78,.2,len),CFrame.new(x,.16-k*.04,.1+len/2)*CFrame.Angles(0,s*k*.05,0),k%2==0 and accent or bronze))
        end
        local wrist=Vector3.new(s*5.5,.1,-.4)
        for k=0,4 do
            local theta=-.3+k*.32;local len=3.1-math.abs(k-1.5)*.25
            local cf=CFrame.new(wrist)*CFrame.Angles(0,-s*theta,0)*CFrame.Angles(0,0,s*(-.06+k*.02))*CFrame.new(s*len/2,0,0)
            anim(add('Primary',Vector3.new(len,.12,.5),cf,k%2==0 and trim or accent),'primary',{pivot=hinge,side=s,wrist=CFrame.new(wrist),k=k})
            anim(add('PrimaryTip',Vector3.new(.5,.07,.3),cf*CFrame.new(s*(len/2-.25),.08,0),accent,{glow=true}),'primary',{pivot=hinge,side=s,wrist=CFrame.new(wrist),k=k})
        end
    end
    local anchors={};for _,s in ipairs({-1,1})do for _,p in ipairs({Vector3.new(s*1.2,-.1,-1.3),Vector3.new(s*1.2,-.1,1.2),Vector3.new(s*3.2,-.1,-.9),Vector3.new(s*3.2,-.1,1.3)})do table.insert(anchors,p)end end
    return {anchors=anchors,crest=CFrame.new(0,.42,.4)}
end
function builders.holo(add,anim,dark,trim,accent)
    for i=-1,1 do
        local cf=CFrame.new(i*1.15,-math.abs(i)*.18,0)*CFrame.Angles(0,0,-i*.14)
        add('GlassCell',Vector3.new(1.2,.42,4.0-math.abs(i)*.6),cf,dark:Lerp(trim,.5),{mesh='soft',material=Enum.Material.Glass,alpha=.2})
    end
    add('Spine',Vector3.new(.14,.06,3.8),CFrame.new(0,.24,0),nil,{tint='full',glow=true})
    for _,s in ipairs({-1,1})do
        add('GlassEdge',Vector3.new(.08,.08,3.2),CFrame.new(s*1.72,-.12,0),accent,{glow=true})
        local shoulder=Vector3.new(s*1.85,.05,-.35)
        anim(add('Emitter',Vector3.new(.5,.5,.5),CFrame.new(shoulder),trim,{glow=true,shape=Enum.PartType.Ball}),'prism',{i=0})
        anim(add('EmitterRing',Vector3.new(.06,.9,.9),CFrame.new(shoulder)*CFrame.Angles(0,0,s*.36+math.pi/2),accent,{glow=true,shape=Enum.PartType.Cylinder,alpha=.3}),'prism',{i=2})
        local tiers={{n=4,len=3.8,from=.6,to=1.4,phase=1},{n=4,len=5.7,from=.25,to=1.0,phase=2},{n=3,len=7.6,from=-.05,to=.6,phase=3}}
        local i=0
        for tier,T in ipairs(tiers)do for j=1,T.n do
            i+=1;local phi=T.from+(T.to-T.from)*(j-1)/math.max(1,T.n-1)
            local p=add('LightBlade',Vector3.new(T.len,.06,.72-tier*.1),CFrame.new(shoulder),tier==3 and trim or accent,{glow=true,alpha=.18+tier*.06})
            anim(p,'blade',{shoulder=shoulder,side=s,phi=phi,len=T.len,phase=T.phase,i=i+tier*3})
            if tier==3 then anim(add('BladeSpark',Vector3.one*.36,CFrame.new(shoulder),trim,{glow=true,shape=Enum.PartType.Ball}),'blade',{shoulder=shoulder,side=s,phi=phi,len=T.len*2,phase=3,i=i,spark=true})end
            if j==1 then anim(add('LightMembrane',Vector3.new(T.len*.8,.04,1),CFrame.new(shoulder),accent,{glow=true,alpha=.78}),'membrane',{shoulder=shoulder,side=s,from=T.from,to=T.to,len=T.len,phase=T.phase,i=tier*5})end
        end end
    end
    local anchors={};for _,s in ipairs({-1,1})do for _,p in ipairs({Vector3.new(s*.6,-.25,-1.4),Vector3.new(s*.6,-.25,1.4),Vector3.new(s*1.7,-.3,-1.1),Vector3.new(s*1.7,-.3,1.1)})do table.insert(anchors,p)end end
    return {anchors=anchors,crest=CFrame.new(0,.3,.2)}
end
local Volume=require(script.Parent.ParachuteVolume)
for key,build in pairs(Volume.builders)do builders[key]=build end
local Meshes=require(script.Parent.CosmeticMeshes)
local CANOPY=CFrame.new(0,-7.7,.25)
function M.meshBuild(rig,canopy,style)
    local list=Meshes.build(canopy,style.id,{origin=CANOPY,colors={primary=rgb(style.primary),secondary=rgb(style.secondary),accent=rgb(style.accent)}})
    if not list then return nil end
    rig.anims={};local tier=style.tier or 1;local lo,hi
    for _,r in ipairs(list)do
        local p=r.part;p.CastShadow=false;table.insert(rig.parts,{part=p,alpha=0})
        local hue=Meshes.prismatic(r,tier)
        if r.kind or r.phase or hue then table.insert(rig.anims,{part=p,home=r.home,kind='mesh',r=r,hue=hue,rate=tier>=5 and 1.3 or 1})end
        if not r.kind then
            local h=p.Size/2
            for _,x in ipairs({-1,1})do for _,z in ipairs({-1,1})do for _,y in ipairs({-1,1})do
                local v=r.home*Vector3.new(h.X*x,h.Y*y,h.Z*z);lo=lo and lo:Min(v)or v;hi=hi and hi:Max(v)or v
            end end end
        end
    end
    lo=lo or Vector3.new(-2,-1,-2);hi=hi or Vector3.new(2,1,2)
    local w,d,y=(hi.X-lo.X)/2,(hi.Z-lo.Z)/2,lo.Y+.12;local cx,cz=(hi.X+lo.X)/2,(hi.Z+lo.Z)/2
    local crest=Meshes.crestKind(style.id,tier,'parachute')
    if crest then
        local n=#list;Meshes.crest(canopy,list,crest,CFrame.new(cx,hi.Y,cz),math.clamp(math.max(w,d)*.36,1.4,2.6),rgb(style.accent))
        for i=n+1,#list do local r=list[i];table.insert(rig.parts,{part=r.part,alpha=0})
            local a={part=r.part,home=r.home,kind='mesh',r=r,hue=Meshes.prismatic(r,tier),rate=tier>=5 and 1.3 or 1}
            if tier==5 and i==n+1 then local l=Instance.new('PointLight');l.Name='CollectionLight';l.Range=12;l.Brightness=1.4;l.Shadows=false;l.Color=r.part.Color;l.Parent=r.part;a.light=l end
            table.insert(rig.anims,a)
        end
    end
    if #rig.anims==0 then rig.anims=nil end
    local anchors={};for _,sx in ipairs({-1,1})do for _,k in ipairs({.25,.55})do for _,sz in ipairs({-1,1})do table.insert(anchors,Vector3.new(cx+sx*w*k,y,cz+sz*d*.42))end end end
    canopy:SetAttribute('MeshItem',style.id)
    return {anchors=anchors,crest=CFrame.new(0,hi.Y,0),mesh=true}
end
function M.build(rig,canopy,style)
    local mesh=style.id and Meshes.ready(style.id)and M.meshBuild(rig,canopy,style)
    if mesh then return mesh end
    local dark,trim,accent=rgb(style.primary),rgb(style.secondary),rgb(style.accent)
    rig.anims={}
    local function add(name,size,cf,color,o)
        o=o or {}
        local p
        if o.mesh then p=G.part(canopy,name,size,cf,color or rig.color or accent,o.mesh)
        else p=Instance.new(o.wedge and 'WedgePart' or 'Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color or accent;p.Parent=canopy end
        if o.shape then p.Shape=o.shape;p.Size=size end
        p.Material=o.glow and Neon or o.material or Enum.Material.SmoothPlastic
        p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
        local alpha=o.alpha or 0;p.Transparency=alpha
        table.insert(rig.parts,{part=p,tint=o.tint,alpha=alpha});return p
    end
    local function anim(p,kind,data)data=data or {};data.part=p;data.home=p.CFrame;data.kind=kind;table.insert(rig.anims,data);return p end
    local build=builders[style.theme]or({builders.military,builders.stripe,builders.glider,builders.eagle,builders.holo})[style.tier or 1]
    local spec=build(add,anim,dark,trim,accent)
    if #rig.anims==0 then rig.anims=nil end
    return spec
end
function M.step(rig,t,reduced,phase,inflation,place)
    local shown=math.clamp(math.min(phase,rig.canopy:GetAttribute('CollectionPhase')or phase),1,3)
    local key=phase*1000+shown*100+math.floor(inflation*20)
    if reduced then if rig.rest==key then return end;rig.rest=key;t=0 else rig.rest=nil end
    local root=rig.root.CFrame;local scale=rig.scale or 1
    local open=math.clamp((inflation-.55)/.45,0,1)
    local spread=reduced and open or open*(.3+.7*math.clamp(.5+.9*math.sin(t*.6),0,1))
    local beat=reduced and 0 or math.sin(t*1.7)
    for _,a in ipairs(rig.anims)do
        local p=a.part;local cf=a.home;local k=a.kind
        if k=='wing'then cf=a.pivot*CFrame.Angles(0,0,a.side*(.5+beat*.14))*a.pivot:Inverse()*cf
        elseif k=='primary'then
            local flex=CFrame.Angles(0,0,a.side*(.5+beat*.14))*a.pivot:Inverse()*a.wrist*CFrame.Angles(0,0,a.side*(.1+beat*.1))*a.wrist:Inverse()*a.pivot*CFrame.Angles(0,-a.side*math.sin(t*1.7-.6)*(reduced and 0 or .05)*(a.k-2),0)
            cf=a.pivot*flex*a.pivot:Inverse()*cf
        elseif k=='tail'then cf=a.pivot*CFrame.Angles(0,reduced and 0 or math.sin(t*1.1)*.08,0)*a.pivot:Inverse()*cf
        elseif k=='chase'then
            local w=reduced and 0 or math.max(0,math.sin(t*3.2-a.order*.55))^6
            p.Color=a.color:Lerp(Color3.new(1,1,1),w*.65);p.Transparency=(1-w)*.25
        elseif k=='prism'then if not reduced then p.Color=prism(t*.06+a.i*.1,.45)end
        elseif k=='membrane'then
            local u=Vector3.new(a.side,.36,0).Unit;local v=Vector3.new(0,.42,.9).Unit;local face=Vector3.new(0,.75,.66);local fold=Vector3.new(a.side*.12,.45,.88).Unit
            local function dir(phi)return(u*math.cos(phi)+v*math.sin(phi)):Lerp(fold,1-spread).Unit end
            local d0,d1=dir(a.from),dir(a.to);local d=(d0+d1).Unit;local width=(d0-d1).Magnitude*a.len*.5+.05
            p.Size=Vector3.new(a.len*.8,.04,width)*scale
            cf=CFrame.fromMatrix(a.shoulder+d*a.len*.45,d,(face-d*face:Dot(d)).Unit)
            p.Transparency=a.phase>phase and 1 or .6+(1-spread)*.2
            if not reduced then p.Color=prism(t*.05+a.i*.035,.5)end
        elseif k=='blade'then
            local u=Vector3.new(a.side,.36,0).Unit;local v=Vector3.new(0,.42,.9).Unit;local face=Vector3.new(0,.75,.66)
            local d=(u*math.cos(a.phi)+v*math.sin(a.phi)):Lerp(Vector3.new(a.side*.12,.45,.88).Unit,1-spread).Unit
            cf=CFrame.fromMatrix(a.shoulder+d*a.len/2,d,(face-d*face:Dot(d)).Unit)
            p.Transparency=a.phase>phase and 1 or math.clamp(.12+a.phase*.08+(1-spread)*.2,0,.9)
            if not reduced then p.Color=prism(t*.05+a.i*.035,a.spark and .15 or .4)end
        elseif k=='mesh'then
            local r=a.r
            if r.kind and not reduced then cf=Meshes.motion(r,t,0,a.rate)*cf end
            if r.phase then p.Transparency=r.phase>shown and 1 or 0 end
            if a.hue and not reduced then p.Color=Meshes.prism(t*.06+r.index*.07)end
            if a.light then a.light.Color=p.Color end
        elseif Volume.kinds[k]then cf=Volume.kinds[k](a,p,t,reduced,shown,scale,open)
        end
        place(p,root*CFrame.new(cf.Position*scale)*cf.Rotation)
    end
end
return M
