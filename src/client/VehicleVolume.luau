local G=require(script.Parent.ToyGeometry)
return function(h)
local glow,wedge,bone,track,console,prism=h.glow,h.wedge,h.bone,h.track,h.console,h.prism
local Metal=Enum.Material.Metal
local function metal(p,r)p.Material=Metal;p.Reflectance=r or .12;return p end
local function ell(m,name,size,cf,color)local p=G.block(m,name,size,cf,color);local k=Instance.new('SpecialMesh');k.MeshType=Enum.MeshType.Sphere;k.Parent=p;return p end
local function noise(n)local x=math.sin(n*12.9898)*43758.5453;return x-math.floor(x)end
local function axisX(c)return CFrame.new(c)*CFrame.Angles(0,0,math.pi/2)end
local function axisZ(c)return CFrame.new(c)*CFrame.Angles(math.pi/2,0,0)end
local function spark(st,p,from,vel,grav,rate,offset)
    p.CastShadow=false;local base=p.Transparency
    return track(st,p,'fn',{fn=function(_,t,_,_,reduced)
        if reduced then p.Transparency=1;return CFrame.new(from)end
        local u=(t*rate+offset)%1;p.Transparency=base+(1-base)*u^1.6
        return CFrame.new(from+vel*u-Vector3.new(0,grav*u*u,0))
    end})
end
local function rider(st,p,rest,joint,need)
    local lc=rest:Inverse()*p.CFrame;local base=p.Transparency
    return track(st,p,'fn',{fn=function(_,t,speed,phase,reduced)
        if need then p.Transparency=need>phase and 1 or base end
        return joint(t,speed,phase,reduced)*lc
    end})
end
local function arc(st,m,a,b,n,color,seed)
    for i=1,n do
        local p=glow(G.block(m,'Arc',Vector3.new(.06,(b-a).Magnitude/n*1.15,.06),CFrame.identity,color))
        track(st,p,'fn',{fn=function(_,t,_,_,reduced)
            local k=math.floor(t*14)+seed
            local function pt(j)if j==0 then return a elseif j==n then return b end
                return a:Lerp(b,j/n)+Vector3.new(noise(k*7+j)-.5,noise(k*13+j)-.5,noise(k*3+j)-.5)*.4 end
            p.Transparency=reduced and 1 or noise(k*5+i)<.18 and .75 or 0
            return bone(pt(i-1),pt(i))
        end})
    end
end
local B={}
function B.crawler(m,st,dark,trim,accent)
    st.body=true
    local shell=dark:Lerp(trim,.22);local pipe=dark:Lerp(trim,.4)
    ell(m,'Carapace',Vector3.new(2.0,.62,2.6),CFrame.new(0,.8,0),dark)
    G.part(m,'DeckPlate',Vector3.new(1.2,.06,1.2),CFrame.new(0,1.1,-.1),shell,'armor')
    ell(m,'Abdomen',Vector3.new(1.7,.85,1.6),CFrame.new(0,.92,1.4),dark)
    G.part(m,'Head',Vector3.new(1.15,.42,.9),CFrame.new(0,.78,-1.55),shell,'key')
    console(m,-1.05,1.5,.85,trim,dark,accent)
    for _,side in ipairs({-1,1})do
        glow(G.block(m,'VenomSeam',Vector3.new(.06,.07,2.1),CFrame.new(side*.96,.84,-.1),accent))
        glow(G.ball(m,'Eye',Vector3.one*.2,CFrame.new(side*.3,.9,-1.98),accent))
        G.part(m,'Mandible',Vector3.new(.12,.12,.62),CFrame.new(side*.3,.6,-2.12)*CFrame.Angles(0,side*.5,0),trim,'armor')
        G.rod(m,'FeedPipe',Vector3.new(side*.7,1.2,1.15),Vector3.new(side*.82,.98,-1.2),.06,pipe)
        local x=side*.45
        local glass=G.cylinder(m,'TankGlass',.28,.9,CFrame.new(x,1.6,1.45),trim);glass.Material=Enum.Material.Glass;glass.Transparency=.5;glass.CastShadow=false
        glow(G.cylinder(m,'TankBrew',.23,.55,CFrame.new(x,1.43,1.45),accent),.2)
        G.cylinder(m,'TankCollar',.32,.12,CFrame.new(x,1.16,1.45),pipe)
        G.cylinder(m,'TankCap',.31,.1,CFrame.new(x,2.08,1.45),dark)
        for i=0,1 do spark(st,glow(G.ball(m,'Bubble',Vector3.one*.11,CFrame.new(x,1.3,1.45),trim)),Vector3.new(x+(i-.5)*.12,1.3,1.45),Vector3.new(0,.68,0),0,.9,i*.5+(side+1)*.12)end
        for fi,fz in ipairs({-.85,0,.85})do
            local leg={hip=Vector3.new(side*.85,.82,fz),rest=Vector3.new(side*2.05,.02,fz*1.5),side=side,fore=fz,l1=1.05,l2=1.3,reach=.45,lift=.4,
                offset=((fi+(side>0 and 1 or 0))%2)*math.pi}
            leg.thigh=G.part(m,'Thigh',Vector3.new(.18,leg.l1,.2),CFrame.identity,shell,'armor')
            leg.shin=G.part(m,'Shin',Vector3.new(.13,leg.l2,.15),CFrame.identity,trim,'armor')
            leg.foot=glow(G.ball(m,'Claw',Vector3.one*.2,CFrame.identity,accent))
            table.insert(st.legs,leg)
        end
    end
    track(st,glow(G.cylinder(m,'VenomPool',1.5,.03,CFrame.new(0,.03,0),accent),.78),'pulse',{rate=2,range=.14,offset=0,ground=true})
end
function B.jetski(m,st,dark,trim,accent)
    st.float=true;st.body=true;st.rock=.05
    local foam=trim:Lerp(Color3.new(1,1,1),.55);local steel=dark:Lerp(trim,.3)
    G.part(m,'Hull',Vector3.new(1.5,.42,2.9),CFrame.new(0,.5,.3),dark,'soft')
    G.part(m,'Prow',Vector3.new(1.06,.4,1.06),CFrame.new(0,.52,-1.5)*CFrame.Angles(0,math.pi/4,0),dark,'armor')
    wedge(m,'Keel',Vector3.new(.5,.3,1.2),CFrame.new(0,.42,-1.85)*CFrame.Angles(0,0,math.pi),dark)
    G.part(m,'Hood',Vector3.new(1.1,.3,1.2),CFrame.new(0,.82,-1.25)*CFrame.Angles(.12,0,0),trim,'soft')
    glow(G.block(m,'HoodStripe',Vector3.new(.14,.04,1.1),CFrame.new(0,.98,-1.25)*CFrame.Angles(.12,0,0),accent))
    G.part(m,'StandTray',Vector3.new(1.1,.06,1.7),CFrame.new(0,.73,.45),dark:Lerp(Color3.new(),.35),'board')
    G.part(m,'KneePad',Vector3.new(.8,.14,.45),CFrame.new(0,.82,1.4),steel,'soft')
    G.rod(m,'SteerPole',Vector3.new(0,.95,-1.55),Vector3.new(0,1.6,-.95),.06,steel)
    G.part(m,'Handlebar',Vector3.new(1.2,.08,.1),CFrame.new(0,1.62,-.92),trim,'armor')
    glow(G.block(m,'ConsoleScreen',Vector3.new(.36,.18,.05),CFrame.new(0,1.48,-1.06)*CFrame.Angles(-.7,0,0),accent))
    G.cylinder(m,'JetNozzle',.2,.35,axisZ(Vector3.new(0,.42,1.85)),steel)
    glow(G.cylinder(m,'NozzleCore',.14,.05,axisZ(Vector3.new(0,.42,2.03)),accent))
    track(st,glow(G.cylinder(m,'JetPlume',.12,.45,axisZ(Vector3.new(0,.42,2.28)),foam),.4),'pulse',{rate=9,range=.4,offset=0})
    for _,side in ipairs({-1,1})do
        G.block(m,'Grip',Vector3.new(.16,.13,.15),CFrame.new(side*.6,1.62,-.92),dark)
        G.part(m,'Gunwale',Vector3.new(.18,.22,2.6),CFrame.new(side*.7,.74,.3),trim,'armor')
        glow(G.block(m,'HullStripe',Vector3.new(.04,.09,2.4),CFrame.new(side*.76,.52,.1),accent))
        glow(G.block(m,'HoodVent',Vector3.new(.04,.05,.5),CFrame.new(side*.56,.84,-1.2),accent))
        G.part(m,'Sponson',Vector3.new(.14,.16,1.1),CFrame.new(side*.8,.36,.95),trim,'board')
        glow(G.block(m,'Headlight',Vector3.new(.26,.1,.05),CFrame.new(side*.34,.66,-2.05)*CFrame.Angles(-.5,0,0),accent))
        G.rod(m,'GrabHandle',Vector3.new(side*.62,.9,1.25),Vector3.new(side*.62,.9,1.8),.04,trim)
        track(st,glow(wedge(m,'BowSpray',Vector3.new(.12,.6,1.1),CFrame.new(side*.95,.4,-1.2)*CFrame.Angles(0,side*-.55,side*.35),foam),.3),'pulse',{rate=5,range=.45,offset=side})
        track(st,glow(G.block(m,'WakeFoam',Vector3.new(.16,.03,1.8),CFrame.new(side*.55,.07,2.5)*CFrame.Angles(0,side*.3,0),foam),.3),'pulse',{rate=3,range=.4,offset=side*2,ground=true})
    end
    for i=0,6 do spark(st,glow(G.ball(m,'Spray',Vector3.one*(.16+(i%3)*.04),CFrame.new(0,.45,2.1),foam),.2),Vector3.new(0,.45,2.1),Vector3.new(((i%3)-1)*.3,1.4,2.6),1.7,.9,i/7)end
    for i=0,3 do
        local a=math.pi*(.25+i*.5);local p=glow(G.block(m,'Ripple',Vector3.new(1.2,.03,.12),CFrame.new(0,.07,0),foam),.15);p.CastShadow=false
        track(st,p,'fn',{ground=true,fn=function(_,t,_,_,reduced)
            local u=reduced and .5 or (t*.45+i*.25)%1;p.Transparency=.15+.85*u^1.5
            local r=.9+u*1.0;return CFrame.new(math.sin(a)*r,.07,.3+math.cos(a)*r)*CFrame.Angles(0,a,0)
        end})
    end
    track(st,glow(G.cylinder(m,'WaterSheet',1.85,.03,CFrame.new(0,.05,.3),accent),.6),'pulse',{rate=2.2,range=.12,offset=0,ground=true})
end
function B.magmabike(m,st,dark,trim,accent)
    local iron=dark:Lerp(Color3.new(),.4)
    G.part(m,'EngineBlock',Vector3.new(.85,.62,1.3),CFrame.new(0,.62,.05),dark,'armor')
    glow(G.block(m,'LavaBelly',Vector3.new(.6,.06,1.1),CFrame.new(0,.29,.05),accent))
    G.part(m,'FuelTank',Vector3.new(.8,.42,1.05),CFrame.new(0,1.05,-.95),dark,'soft')
    glow(G.block(m,'TankStripe',Vector3.new(.12,.04,.9),CFrame.new(0,1.27,-.95),accent))
    G.part(m,'Handlebar',Vector3.new(1.35,.08,.1),CFrame.new(0,1.62,-1.0),trim,'armor')
    G.part(m,'LampHousing',Vector3.new(.5,.3,.5),CFrame.new(0,1.2,-1.62)*CFrame.Angles(-1.35,0,0),iron,'dish')
    glow(G.ball(m,'Headlamp',Vector3.one*.26,CFrame.new(0,1.2,-1.7),trim))
    G.part(m,'Saddle',Vector3.new(.7,.28,.9),CFrame.new(0,1.0,1.08),iron,'key')
    G.part(m,'FrontFender',Vector3.new(.55,.1,.9),CFrame.new(0,1.33,-1.85)*CFrame.Angles(.3,0,0),dark,'armor')
    G.part(m,'RearFender',Vector3.new(.55,.1,1.1),CFrame.new(0,1.32,1.75)*CFrame.Angles(-.25,0,0),dark,'armor')
    glow(G.block(m,'TailLight',Vector3.new(.4,.08,.05),CFrame.new(0,1.22,2.32)*CFrame.Angles(-.25,0,0),accent))
    for _,side in ipairs({-1,1})do
        glow(G.block(m,'LavaCrack',Vector3.new(.04,.42,.06),CFrame.new(side*.43,.62,-.25)*CFrame.Angles(.5,0,0),accent))
        glow(G.block(m,'LavaCrack',Vector3.new(.04,.06,.72),CFrame.new(side*.43,.48,.28)*CFrame.Angles(.25,0,0),accent))
        G.part(m,'FootBoard',Vector3.new(.42,.08,1.0),CFrame.new(side*.62,.38,.05),iron,'armor')
        G.rod(m,'Fork',Vector3.new(side*.3,.62,-1.75),Vector3.new(side*.24,1.6,-1.05),.06,trim)
        G.block(m,'Grip',Vector3.new(.16,.13,.15),CFrame.new(side*.68,1.62,-1.0),iron)
        G.part(m,'SwingArm',Vector3.new(.1,.14,1.4),CFrame.new(side*.3,.62,.95),iron,'armor')
        G.rod(m,'Exhaust',Vector3.new(side*.5,.45,.35),Vector3.new(side*.55,.82,2.0),.09,iron)
        glow(G.cylinder(m,'ExhaustGlow',.1,.06,CFrame.new(side*.55,.82,2.02)*CFrame.Angles(math.pi/2-.22,0,0),accent))
        for i=0,1 do spark(st,glow(G.ball(m,'Ember',Vector3.one*.13,CFrame.new(side*.55,.85,2.05),i==0 and accent or trim)),Vector3.new(side*.55,.85,2.05),Vector3.new(side*.25,.95,.9),1.1,1.3,i*.5+side*.13)end
    end
    for _,z in ipairs({-1.75,1.7})do
        local c=Vector3.new(0,.62,z);local hub=CFrame.new(c)*CFrame.Angles(0,math.pi/2,0)
        G.cylinder(m,'Tire',.62,.42,axisX(c),iron)
        glow(G.cylinder(m,'LavaFace',.5,.44,axisX(c),accent))
        G.cylinder(m,'Hub',.17,.5,axisX(c),dark)
        for k=0,2 do track(st,G.block(m,'Spoke',Vector3.new(.48,.07,.92),CFrame.new(c)*CFrame.Angles(k*math.pi/3,0,0),iron),'spin',{pivot=hub,rate=-7})end
        for j,a in ipairs({.5,1.05})do
            local d=Vector3.new(0,math.sin(a),math.cos(a))
            track(st,glow(wedge(m,'Flame',Vector3.new(.4,.12,.9-j*.15),CFrame.lookAt(c+d*.62+Vector3.new(0,.04,.38),c+d*.62+Vector3.new(0,.3,1.2)),j==1 and accent or trim),.1),'pulse',{rate=8+j*3,range=.5,offset=z+j})
        end
        glow(G.cylinder(m,'TreadGlow',.64,.12,axisX(c),accent),.55)
    end
end
function B.arcboard(m,st,dark,trim,accent)
    st.float=true;st.body=true
    local white=trim:Lerp(Color3.new(1,1,1),.4)
    G.part(m,'HoverDeck',Vector3.new(1.7,.16,3.3),CFrame.new(0,.74,0),dark,'board')
    G.block(m,'GripPanel',Vector3.new(1.3,.02,2.2),CFrame.new(0,.83,0),dark:Lerp(Color3.new(),.45))
    G.part(m,'NoseKick',Vector3.new(1.5,.14,.7),CFrame.new(0,.86,-1.85)*CFrame.Angles(.38,0,0),trim,'board')
    G.part(m,'TailKick',Vector3.new(1.5,.14,.6),CFrame.new(0,.84,1.8)*CFrame.Angles(-.36,0,0),trim,'board')
    for _,f in ipairs({-1,1})do
        local pts={Vector3.new(-.4,.85,f*.7),Vector3.new(.12,.85,f*.98),Vector3.new(-.1,.85,f*1.1),Vector3.new(.38,.85,f*1.42)}
        for i=1,3 do local a,b=pts[i],pts[i+1];glow(G.block(m,'BoltInlay',Vector3.new(.08,.02,(b-a).Magnitude+.06),CFrame.lookAt((a+b)/2,b),accent))end
        glow(G.cylinder(m,'Emitter',.3,.05,CFrame.new(0,.64,f*1.0),accent))
        arc(st,m,Vector3.new(0,.6,f*1.0),Vector3.new(f*.55,.02,f*1.35),3,white,f*31)
    end
    for _,side in ipairs({-1,1})do
        G.part(m,'Rail',Vector3.new(.1,.12,3.1),CFrame.new(side*.86,.76,0),trim,'armor')
        glow(G.block(m,'EdgeSeam',Vector3.new(.04,.05,2.9),CFrame.new(side*.9,.68,0),accent))
        local x=side*.62
        G.cylinder(m,'CoilPost',.07,.8,CFrame.new(x,1.2,1.25),dark)
        for i,r in ipairs({.2,.17,.14})do metal(G.cylinder(m,'CoilRing',r,.06,CFrame.new(x,.98+i*.18,1.25),trim))end
        local ball=glow(G.ball(m,'CoilBall',Vector3.one*.26,CFrame.new(x,1.66,1.25),accent))
        track(st,ball,'pulse',{rate=17,range=.35,offset=side})
        G.cylinder(m,'NubPost',.06,.4,CFrame.new(side*.55,1.0,-1.25),dark)
        glow(G.ball(m,'NubBall',Vector3.one*.16,CFrame.new(side*.55,1.22,-1.25),white))
    end
    arc(st,m,Vector3.new(-.62,1.7,1.25),Vector3.new(.62,1.7,1.25),3,white,7)
    track(st,glow(G.cylinder(m,'StaticGlow',1.4,.03,CFrame.new(0,.04,0),accent),.75),'pulse',{rate=6,range=.15,offset=0,ground=true})
end
function B.chariot(m,st,dark,trim,accent)
    local gold=accent;local navy=dark
    G.part(m,'ChariotFloor',Vector3.new(1.9,.16,1.9),CFrame.new(0,.72,.05),navy,'armor')
    local shield=CFrame.new(0,1.2,-.98)*CFrame.Angles(-.18,0,0)
    G.part(m,'ShieldFront',Vector3.new(1.2,.95,.14),shield,navy,'armor')
    metal(G.part(m,'ShieldRim',Vector3.new(1.3,.1,.2),shield*CFrame.new(0,.5,0),gold,'armor'),.2)
    metal(G.block(m,'CrestBand',Vector3.new(.56,.12,.06),shield*CFrame.new(0,-.08,-.09),gold),.2)
    for i=-1,1 do metal(G.block(m,'CrestPoint',Vector3.new(.13,.13,.05),shield*CFrame.new(i*.2,.06+(i==0 and .05 or 0),-.09)*CFrame.Angles(0,0,math.pi/4),gold),.2)end
    glow(G.ball(m,'CrestJewel',Vector3.one*.13,shield*CFrame.new(0,-.08,-.14),trim))
    console(m,-.7,1.48,1.0,trim,navy,gold)
    metal(G.cylinder(m,'Axle',.08,2.5,axisX(Vector3.new(0,.7,.2)),gold),.2)
    for _,side in ipairs({-1,1})do
        G.part(m,'ShieldWing',Vector3.new(.8,.8,.14),CFrame.new(side*.8,1.1,-.66)*CFrame.Angles(-.12,-side*1.0,0),navy,'armor')
        G.part(m,'SideWall',Vector3.new(.14,.55,1.25),CFrame.new(side*1.0,1.05,.25),navy,'armor')
        metal(G.part(m,'WallRim',Vector3.new(.2,.1,1.3),CFrame.new(side*1.0,1.35,.25),gold,'armor'),.2)
        glow(G.ball(m,'Lantern',Vector3.one*.2,CFrame.new(side*1.12,1.5,-.42),trim))
        local c=Vector3.new(side*1.32,.7,.2);local hub=CFrame.new(c)*CFrame.Angles(0,math.pi/2,0)
        metal(G.cylinder(m,'WheelRim',.7,.12,axisX(c),gold),.2)
        G.cylinder(m,'WheelFace',.58,.14,axisX(c),navy)
        for k=0,2 do track(st,metal(G.block(m,'Spoke',Vector3.new(.18,.07,1.18),CFrame.new(c)*CFrame.Angles(k*math.pi/3,0,0),gold),.2),'spin',{pivot=hub,rate=-5})end
        glow(G.cylinder(m,'WheelHub',.13,.24,axisX(c),gold))
        metal(G.rod(m,'Shaft',Vector3.new(side*.45,.7,-.9),Vector3.new(side*.58,1.5,-2.45),.05,gold),.2)
        G.rod(m,'Rein',Vector3.new(side*.5,1.48,-.7),Vector3.new(side*.2,2.45,-4.05),.025,trim)
        spark(st,glow(G.ball(m,'StarDust',Vector3.one*.14,CFrame.new(c),trim)),Vector3.new(side*1.32,.15,.75),Vector3.new(side*.15,.9,1.5),.5,.8,side*.25)
    end
    metal(G.rod(m,'BannerMast',Vector3.new(.82,.8,.9),Vector3.new(.82,3.3,.9),.045,gold),.2)
    glow(G.ball(m,'Finial',Vector3.one*.2,CFrame.new(.82,3.36,.9),gold))
    local hinge=CFrame.new(.82,2.95,.9)
    track(st,G.block(m,'Banner',Vector3.new(.04,.72,1.05),hinge*CFrame.new(0,-.1,.55),navy),'wave',{pivot=hinge})
    track(st,glow(G.block(m,'BannerStripe',Vector3.new(.05,.12,1.05),hinge*CFrame.new(0,-.36,.55),gold)),'wave',{pivot=hinge})
    local k=1.2;local function at(x,y,z)return CFrame.new(x*k,y*k,z*k)end
    local H0=CFrame.new(0,1.45*k,-3.0)
    local function horse(t,speed,_,reduced)
        if reduced then return H0 end
        local s=math.clamp(speed/10,0,1)
        return H0*CFrame.new(0,math.abs(math.sin(t*8))*.1*s+math.sin(t*2)*.02,0)*CFrame.Angles(math.sin(t*8)*.05*s,0,0)
    end
    rider(st,metal(G.part(m,'HorseBody',Vector3.new(.75,.75,1.7)*k,H0,gold,'soft'),.2),H0,horse)
    rider(st,G.part(m,'Barding',Vector3.new(.86,.32,1.1)*k,H0*at(0,.26,.1),navy,'armor'),H0,horse)
    rider(st,metal(ell(m,'HorseChest',Vector3.new(.72,.8,.7)*k,H0*at(0,.12,-.8),gold),.2),H0,horse)
    rider(st,metal(G.part(m,'HorseNeck',Vector3.new(.4,.95,.48)*k,H0*at(0,.68,-1.05)*CFrame.Angles(-.55,0,0),gold,'armor'),.2),H0,horse)
    rider(st,metal(G.part(m,'HorseHead',Vector3.new(.38,.42,.85)*k,H0*at(0,1.12,-1.5)*CFrame.Angles(-.5,0,0),gold,'key'),.2),H0,horse)
    for _,side in ipairs({-1,1})do rider(st,glow(G.ball(m,'HorseEye',Vector3.one*.1*k,H0*at(side*.18,1.2,-1.45),trim)),H0,horse)end
    rider(st,glow(G.block(m,'Mane',Vector3.new(.08,.95,.22)*k,H0*at(0,.82,-.9)*CFrame.Angles(-.55,0,0),trim)),H0,horse)
    rider(st,G.part(m,'Tail',Vector3.new(.14,.75,.2)*k,H0*at(0,.0,1.0)*CFrame.Angles(.65,0,0),navy,'armor'),H0,function(t,speed,p,reduced)
        return horse(t,speed,p,reduced)*at(0,.25,.85)*CFrame.Angles(0,reduced and 0 or math.sin(t*5)*.25,0)*at(0,-.25,-.85)end)
    for _,side in ipairs({-1,1})do for _,fore in ipairs({-1,1})do
        local hip=at(side*.24,-.28,fore*.6);local off=fore<0 and 0 or math.pi;off+=side*.4
        local function upper(t,speed,p,reduced)
            local s=reduced and 0 or math.clamp(speed/10,0,1)
            return horse(t,speed,p,reduced)*hip*CFrame.Angles(math.sin(t*8+off)*(.08+.55*s),0,0)
        end
        local function lower(t,speed,p,reduced)
            local s=reduced and 0 or math.clamp(speed/10,0,1)
            return upper(t,speed,p,reduced)*at(0,-.55,0)*CFrame.Angles(-math.max(0,math.sin(t*8+off+.8))*.9*s*fore,0,0)
        end
        local r1=H0*hip;local r2=r1*at(0,-.55,0)
        rider(st,metal(G.part(m,'HorseThigh',Vector3.new(.2,.6,.24)*k,r1*at(0,-.27,0),gold,'armor'),.2),r1,upper)
        rider(st,metal(G.part(m,'HorseShin',Vector3.new(.15,.5,.18)*k,r2*at(0,-.25,0),trim,'armor'),.2),r2,lower)
        rider(st,glow(G.block(m,'Hoof',Vector3.new(.22,.1,.24)*k,r2*at(0,-.53,0),gold)),r2,lower)
    end end
    track(st,glow(G.cylinder(m,'RoyalGlow',1.6,.03,CFrame.new(0,.03,.1),gold),.8),'pulse',{rate=2,range=.12,offset=0,ground=true})
end
function B.phoenix(m,st,dark,trim,accent)
    st.float=true;st.body=true
    local flame=accent;local gold=trim;local ember=dark:Lerp(accent,.25)
    ell(m,'BirdBody',Vector3.new(1.5,.75,2.7),CFrame.new(0,.72,.15),dark)
    ell(m,'Breast',Vector3.new(1.2,.85,1.05),CFrame.new(0,.82,-1.0),gold)
    ell(m,'Neck',Vector3.new(.62,1.35,.64),CFrame.new(0,1.35,-1.62)*CFrame.Angles(-.35,0,0),ember)
    local head=CFrame.new(0,2.02,-1.98)
    local function nod(t,_,_,reduced)return reduced and head or head*CFrame.Angles(math.sin(t*1.6)*.08,math.sin(t*.9)*.12,0)end
    rider(st,G.ball(m,'Head',Vector3.one*.7,head,dark),head,nod)
    rider(st,metal(wedge(m,'Beak',Vector3.new(.24,.22,.6),head*CFrame.new(0,-.06,-.55)*CFrame.Angles(0,0,math.pi),gold),.2),head,nod)
    for _,side in ipairs({-1,1})do rider(st,glow(G.ball(m,'Eye',Vector3.one*.13,head*CFrame.new(side*.25,.08,-.22),gold)),head,nod)end
    for i=-1,1 do
        local p=glow(G.block(m,'Crest',Vector3.new(.08,.9-math.abs(i)*.2,.16),head*CFrame.new(i*.12,.5,.32)*CFrame.Angles(.75,0,i*.3),i==0 and gold or flame))
        p.CastShadow=false;rider(st,p,head,function(t,s,ph,r)p.Transparency=r and 0 or (math.sin(t*9+i)*.5+.5)*.35;return nod(t,s,ph,r)end)
    end
    glow(G.ball(m,'HeartGem',Vector3.one*.22,CFrame.new(0,1.0,-1.5),gold))
    metal(G.part(m,'HarnessBar',Vector3.new(1.0,.08,.1),CFrame.new(0,1.5,-1.15),gold,'armor'),.2)
    for _,side in ipairs({-1,1})do
        G.block(m,'Grip',Vector3.new(.15,.13,.15),CFrame.new(side*.5,1.5,-1.15),dark)
        G.rod(m,'Rein',Vector3.new(side*.42,1.5,-1.2),Vector3.new(side*.18,1.75,-1.9),.025,gold)
        metal(G.part(m,'Talon',Vector3.new(.16,.4,.2),CFrame.new(side*.35,.28,-.2)*CFrame.Angles(.4,0,0),gold,'armor'),.2)
        local sh=CFrame.new(side*.7,.95,-.1)*CFrame.Angles(0,0,side*.14);local wr0=sh*CFrame.new(side*1.55,0,0)
        local function shoulder(t,_,_,reduced)return reduced and sh or sh*CFrame.Angles(0,0,side*math.sin(t*3.4)*.42)end
        local function wrist(t,s,ph,reduced)
            if reduced then return wr0 end
            return shoulder(t,s,ph,reduced)*CFrame.new(side*1.55,0,0)*CFrame.Angles(0,0,side*math.sin(t*3.4-.7)*.38)
        end
        local yaw=CFrame.Angles(0,-side*.1,0)
        rider(st,G.part(m,'WingArm',Vector3.new(1.6,.12,1.0),sh*CFrame.new(side*.8,0,0)*yaw,dark,'board'),sh,shoulder)
        rider(st,glow(G.block(m,'WingFlameEdge',Vector3.new(1.6,.1,.12),sh*CFrame.new(side*.8,.04,-.5)*yaw,flame)),sh,shoulder)
        for k=0,2 do
            rider(st,G.part(m,'Covert',Vector3.new(.44,.06,.95),sh*CFrame.new(side*(.32+k*.48),.08,.22)*CFrame.Angles(0,-side*.08*k,0),gold,'board'),sh,shoulder)
            local p=glow(G.block(m,'Secondary',Vector3.new(.3,.05,1.35),sh*CFrame.new(side*(.36+k*.46),-.02,.95)*CFrame.Angles(0,-side*(.06+.07*k),0),k==1 and gold or flame),.1)
            p.CastShadow=false;rider(st,p,sh,shoulder)
        end
        local wy=CFrame.Angles(0,-side*.3,0)
        rider(st,G.part(m,'WingHand',Vector3.new(1.3,.1,.8),wr0*CFrame.new(side*.6,0,.1)*wy,dark,'board'),wr0,wrist)
        rider(st,G.part(m,'HandCovert',Vector3.new(1.1,.08,.45),wr0*CFrame.new(side*.5,.06,-.12)*wy,ember,'board'),wr0,wrist)
        for i=1,5 do
            local a=-side*(i-1)*.27;local len=1.35+(i==3 and .55 or (i==2 or i==4)and .35 or 0)
            local p=glow(G.block(m,'Primary',Vector3.new(len,.05,.24),wr0*CFrame.new(side*(1.0+(5-i)*.08),.02,.15+i*.1)*CFrame.Angles(0,a,0)*CFrame.new(side*len/2,0,0),i%2==0 and gold or flame))
            p.CastShadow=false;rider(st,p,wr0,wrist)
        end
    end
    local root=CFrame.new(0,.85,1.35)
    local function tail(t,_,_,reduced)return reduced and root or root*CFrame.Angles(math.sin(t*2.6)*.1,math.sin(t*1.9)*.18,0)end
    for i=-2,2 do
        local p=glow(G.block(m,'TailPlume',Vector3.new(.26,.05,2.5-math.abs(i)*.3),root*CFrame.Angles(.15,i*.26,0)*CFrame.new(0,0,1.2-math.abs(i)*.15),i%2==0 and flame or gold))
        p.CastShadow=false;rider(st,p,root,tail)
    end
    for _,side in ipairs({-1,1})do
        local p=glow(G.block(m,'TailStreamer',Vector3.new(.1,.04,3.2),root*CFrame.Angles(.08,side*.12,0)*CFrame.new(0,-.06,1.65),gold),.35);p.CastShadow=false
        rider(st,p,root,function(t,s,ph,r)return tail(t,s,ph,r)*(r and CFrame.identity or CFrame.Angles(0,math.sin(t*3+side)*.08,0))end)
    end
    for i=0,4 do
        local from=Vector3.new(((i%3)-1)*1.8,.9,.6+i*.25)
        spark(st,glow(G.ball(m,'Ember',Vector3.one*.14,CFrame.new(from),i%2==0 and flame or gold)),from,Vector3.new(0,1.1,1.0),.3,.8,i/5)
    end
    track(st,glow(G.cylinder(m,'FireGlow',1.7,.03,CFrame.new(0,.03,.2),flame),.78),'pulse',{rate=3,range=.14,offset=0,ground=true})
end
function B.throne(m,st,dark,trim,accent)
    st.float=true;st.body=true
    local obsidian=dark:Lerp(accent,.06);local pale=trim
    local orb=ell(m,'BlackSun',Vector3.new(2.4,1.0,2.4),CFrame.new(0,.55,0),dark);orb.Material=Enum.Material.Glass;orb.Reflectance=.3
    local corona=glow(G.cylinder(m,'CoronaSheet',1.45,.03,CFrame.new(0,.55,0),accent),.4)
    track(st,corona,'pulse',{rate=1.6,range=.2,offset=0})
    metal(G.cylinder(m,'Dais',.86,.08,CFrame.new(0,1.04,0),obsidian),.25)
    glow(G.cylinder(m,'DaisRim',.92,.04,CFrame.new(0,1.0,0),pale))
    local function ring(n,R,tilt,w,need,colorFn)
        local frame=CFrame.new(0,.55,0)*tilt
        for i=0,n-1 do
            local th=i/n*math.pi*2;local p=glow(G.block(m,'LightRing',Vector3.new(R*2*math.pi/n*.9,.07,.09),frame*CFrame.Angles(0,th,0)*CFrame.new(0,0,-R),colorFn and colorFn(0,i)or pale))
            p.CastShadow=false
            track(st,p,'fn',{fn=function(_,t,_,phase,reduced)
                p.Transparency=need>phase and 1 or 0
                if colorFn and not reduced then p.Color=colorFn(t,i)end
                local r=R*(.9+.05*phase)
                return frame*CFrame.Angles(0,th+(reduced and 0 or t*w),0)*CFrame.new(0,0,-r)
            end})
        end
    end
    ring(12,1.6,CFrame.identity,.35,1)
    ring(10,1.9,CFrame.Angles(.38,0,.1),-.5,2,function(t,i)return prism(t*.06+i*.05)end)
    ring(10,2.15,CFrame.Angles(-.2,0,-.42),.42,3,function(t,i)return prism(t*.06+.5+i*.05)end)
    local back=CFrame.new(0,2.0,.95)*CFrame.Angles(.1,0,0)
    metal(G.part(m,'ThroneBack',Vector3.new(1.4,2.1,.22),back,obsidian,'armor'),.25)
    glow(G.block(m,'BackSeam',Vector3.new(.06,1.8,.04),back*CFrame.new(0,0,-.12),accent))
    for _,side in ipairs({-1,1})do
        metal(G.part(m,'Pillar',Vector3.new(.18,2.5,.3),back*CFrame.new(side*.78,.15,0),pale,'armor'),.2)
        track(st,glow(G.block(m,'Finial',Vector3.new(.2,.42,.2),back*CFrame.new(side*.78,1.6,0)*CFrame.Angles(0,math.pi/4,0),accent)),'prism')
        metal(G.part(m,'Armrest',Vector3.new(.26,.2,1.0),CFrame.new(side*1.0,1.45,.25),obsidian,'armor'),.25)
        G.part(m,'ArmPost',Vector3.new(.16,.42,.16),CFrame.new(side*1.0,1.17,.6),pale,'armor')
        track(st,glow(G.block(m,'ArmCrystal',Vector3.new(.16,.32,.16),CFrame.new(side*1.0,1.66,-.28)*CFrame.Angles(0,math.pi/4,0),accent)),'prism')
        local root=back*CFrame.new(side*.85,.6,.12)
        for j=1,2 do
            local p=glow(G.block(m,'LightWing',Vector3.new(.08,1.5-j*.25,.36),root,accent:Lerp(pale,.25*j)),.25);p.CastShadow=false
            track(st,p,'fn',{fn=function(_,t,_,phase,reduced)
                p.Transparency=phase<2 and 1 or .25
                local open=(phase>=3 and 1.25 or .8)*j*.55+(phase>=3 and not reduced and math.sin(t*2.2+j)*.06 or 0)
                return root*CFrame.Angles(0,0,-side*open)*CFrame.new(0,(1.5-j*.25)/2,0)
            end})
        end
    end
    local halo=CFrame.new(0,4.35,1.15)*CFrame.Angles(math.pi/2+.1,0,0)
    G.cylinder(m,'HaloDisc',.5,.14,halo,dark)
    glow(G.cylinder(m,'HaloRing',.62,.05,halo,pale))
    for i=0,7 do
        local p=glow(G.block(m,'SunRay',Vector3.new(.06,.42-(i%2)*.14,.04),CFrame.identity,pale));p.CastShadow=false
        track(st,p,'fn',{fn=function(_,t,_,phase,reduced)
            p.Transparency=phase<3 and 1 or 0
            return halo*CFrame.Angles(0,i/8*math.pi*2+(reduced and 0 or t*.3),0)*CFrame.new(0,.04,-.92)*CFrame.Angles(math.pi/2,0,0)
        end})
    end
    for i=0,3 do
        local p=glow(G.ball(m,'Glint',Vector3.one*.17,CFrame.new(0,.55,-1.3),accent));p.CastShadow=false
        track(st,p,'fn',{fn=function(_,t,_,phase,reduced)
            p.Transparency=(reduced or phase<3)and 1 or 0;if not reduced then p.Color=prism(t*.08+i*.25)end
            local a=i/4*math.pi*2+t*.9
            return CFrame.new(math.cos(a)*1.35,.55+math.sin(t*1.7+i*1.6)*.35,math.sin(a)*1.35)
        end})
    end
    local shade=G.cylinder(m,'EclipseShadow',1.6,.02,CFrame.new(0,.02,0),Color3.new());shade.Transparency=.45;shade.CastShadow=false;shade:SetAttribute('BaseTransparency',.45)
    track(st,shade,'still',{ground=true})
end
return B
end
