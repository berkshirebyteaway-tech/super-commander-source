local G=require(script.Parent.ToyGeometry)
local V=require(script.Parent.TrailVolume)
local V2=require(script.Parent.TrailVolume2)
local T={};local states=setmetatable({},{__mode='k'})
local function rgb(a)return Color3.fromRGB(table.unpack(a))end
local function hash(n)local x=math.sin(n*12.9898)*43758.5453;return x-math.floor(x)end
local function out(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
T.hash=hash
function T.prism(x,sat)local f=x%1;return Color3.fromHSV(.45+.47*(1-math.abs(2*f-1)),sat or .55,1)end
function T.piece(parent,name,size,color,glow,round)
    local p=G.block(parent,name,size,CFrame.identity,color);p.CastShadow=false
    p.Material=glow and Enum.Material.Neon or Enum.Material.SmoothPlastic
    if round then local m=Instance.new('SpecialMesh');m.MeshType=Enum.MeshType.Sphere;m.Parent=p end
    return p
end
local piece=T.piece
local function seg(p,o,a,b,w,h)
    local d=b-a;local len=d.Magnitude;if len<1e-3 then p.Transparency=1;return end
    p.Size=Vector3.new(w,h,len);p.CFrame=o*CFrame.lookAt((a+b)/2,b,math.abs(d.Unit.Y)>.97 and Vector3.xAxis or Vector3.yAxis)
end
T.kinds={
    puff={life=.8,build=function(e,parent,style)
        e.parts={piece(parent,'TrailDust',Vector3.one,rgb(style.secondary),false,true),piece(parent,'TrailDust',Vector3.one,rgb(style.accent),false,true)}
    end,pose=function(e,o,u,_,k)
        local d=(.15+.32*out(u*1.4))*k;local z=e.side*(.07+.09*u)*k;local a,b=e.parts[1],e.parts[2]
        a.Size=Vector3.new(d,d*.62,d*.86);a.CFrame=o*CFrame.new(.05*k*u,d*.25+.09*k*u,z)
        b.Size=Vector3.new(d*.62,d*.45,d*.56);b.CFrame=o*CFrame.new(-d*.32,d*.3+.13*k*u,z-e.side*d*.36)
        a.Transparency=.28+.7*u^1.3;b.Transparency=.38+.6*u^1.3
    end},
    bolt={life=.9,build=function(e,parent,style)
        e.parts={};local core,glow=rgb(style.secondary),rgb(style.accent)
        for i=1,4 do e.parts[i]=piece(parent,'TrailBolt',Vector3.one,core,true)end
        for i=5,8 do e.parts[i]=piece(parent,'TrailBoltGlow',Vector3.one,glow,true)end
        for i=9,10 do e.parts[i]=piece(parent,'TrailSpark',Vector3.one,core,true,true)end
    end,pose=function(e,o,u,t,k)
        local s=e.seed+math.floor(t*14)*.37;local side=e.side
        local tip=Vector3.new((.15+.4*hash(e.seed+1))*k,(.25+.35*hash(e.seed+2))*k,side*(.35+.35*hash(e.seed+3))*k)
        local pts={Vector3.new(0,.02*k,side*.03*k)}
        for i=1,3 do pts[i+1]=pts[1]:Lerp(tip,i/4)+Vector3.new(hash(s+i)-.5,hash(s+i*2.1)-.5,hash(s+i*3.3)-.5)*.26*k end
        pts[5]=tip
        local fade=u<.75 and math.min(1,(hash(s+9)>.84 and .6 or 0)+u*.4)or 1
        for i=1,4 do
            seg(e.parts[i],o,pts[i],pts[i+1],.034*k,.034*k);e.parts[i].Transparency=fade
            seg(e.parts[i+4],o,pts[i],pts[i+1],.11*k,.11*k);e.parts[i+4].Transparency=.5+fade*.5
        end
        for j,at in ipairs({pts[3],tip})do
            local p=e.parts[8+j];p.Size=Vector3.one*(.06+.04*hash(s+j*5))*k;p.CFrame=o*CFrame.new(at);p.Transparency=fade
        end
    end},
    feather={life=1.6,build=function(e,parent,style)
        e.style=style
        e.parts={piece(parent,'TrailFeather',Vector3.one,rgb(style.accent),true,true),piece(parent,'TrailFeatherCore',Vector3.one,rgb(style.secondary),true,true)}
    end,pose=function(e,o,u,t,k)
        local side=e.side;local h=e.seed;local s=(1-.5*u)*k
        local pos=Vector3.new((.08+.5*u)*k,(.95+.22*math.sin(u*math.pi)-.7*u*u)*k,side*(.42+.35*u)*k)
        local cf=o*CFrame.new(pos)*CFrame.Angles(h*6+u*2*side,h*4+t*1.6*(hash(h)-.5),side*(.6+math.sin(t*5+h*9)*.4))
        local a,b=e.parts[1],e.parts[2]
        a.Size=Vector3.new(.15,.03,.5)*s;b.Size=Vector3.new(.055,.04,.38)*s;a.CFrame=cf;b.CFrame=cf*CFrame.new(0,0,.03*s)
        a.Color=rgb(e.style.accent):Lerp(Color3.fromRGB(236,124,36),u*.8)
        a.Transparency=.15+.83*u^1.6;b.Transparency=.05+.93*u^1.4
    end},
    lick={life=.9,build=function(e,parent,style)
        e.style=style;e.parts={piece(parent,'FlameLick',Vector3.one,rgb(style.accent),true,true),piece(parent,'FlameLickCore',Vector3.one,rgb(style.secondary),true,true)}
    end,pose=function(e,o,u,t,k)
        local h=(.42*(1-u)+.08)*(1+math.sin(t*13+e.seed*5)*.12)*k;local a,b=e.parts[1],e.parts[2]
        local cf=o*CFrame.new(0,h*.45,e.side*.05*k)*CFrame.Angles(0,0,-.25-.2*u)
        a.Size=Vector3.new(.1*k,h,.1*k);a.CFrame=cf;b.Size=Vector3.new(.045*k,h*.62,.045*k);b.CFrame=cf*CFrame.new(0,-h*.12,0)
        a.Color=rgb(e.style.accent):Lerp(Color3.fromRGB(236,124,36),u);a.Transparency=.15+.8*u;b.Transparency=.05+.9*u
    end},
    ember={life=1.1,build=function(e,parent,style)e.parts={piece(parent,'TrailEmber',Vector3.one,rgb(style.secondary),true,true)}end,
    pose=function(e,o,u,t,k)
        local p=e.parts[1];p.Size=Vector3.one*(.06*(1-u)+.015)*k
        p.CFrame=o*CFrame.new((.1+.3*u)*k,(.15+.9*u)*k,(e.side*.25+math.sin(t*4+e.seed*7)*.08)*k);p.Transparency=.1+.85*u
    end},
    star={life=1.3,build=function(e,parent)
        e.parts={piece(parent,'TrailStar',Vector3.one,Color3.new(1,1,1),true),piece(parent,'TrailStar',Vector3.one,Color3.new(1,1,1),true)}
    end,pose=function(e,o,u,t,k)
        local h=e.seed;local tw=(.55+.45*math.abs(math.sin(t*8+h*11)))*(1-.55*u)
        local cf=o*CFrame.new(.12*u*k,(.52+(hash(h)-.5)*.6+.2*u)*k,(hash(h+1)-.5)*.8*k)*CFrame.Angles(t*.8+h,h*5,h*3)
        local c=T.prism(h+t*.35,.4)
        for i,p in ipairs(e.parts)do
            p.Size=i==1 and Vector3.new(.26,.035,.035)*k*tw or Vector3.new(.035,.26,.035)*k*tw;p.CFrame=cf;p.Color=c;p.Transparency=.05+.9*u^1.5
        end
    end},
}
function T.element(kind,parent,style,seed,side)
    local e={kind=kind,seed=seed or 0,side=side or 1,spec=T.kinds[kind]};e.spec.build(e,parent,style);return e
end
function T.pose(e,o,u,t,k)e.spec.pose(e,o,u,t,k)end
function T.hide(e)for _,p in ipairs(e.parts)do p.Transparency=1 end end
local wingSpec={{1.12,.62},{.7,.76},{.28,.68},{-.12,.5}}
function T.wings(parent,style)
    local w={};local accent,trim=rgb(style.accent),rgb(style.secondary)
    for _,side in ipairs({-1,1})do for j,spec in ipairs(wingSpec)do
        table.insert(w,{side=side,j=j,el=spec[1],len=spec[2],vane=piece(parent,'FlameWing',Vector3.one,accent:Lerp(trim,(j-1)*.12),true,true),core=piece(parent,'FlameWingCore',Vector3.one,trim,true,true)})
    end end
    return w
end
function T.poseWings(w,cf,t,k,open)
    for _,f in ipairs(w)do
        local el=f.el*(.45+.55*open)+math.sin(t*3.2-f.j*.4)*.16*open
        local d=Vector3.new(.45+.4*(1-open),math.sin(el),f.side*math.cos(el)*(.25+.75*open)).Unit
        local len=f.len*k*(.3+.7*open);local c=d*len*.52
        local frame=cf*CFrame.lookAt(c,c+d,Vector3.xAxis)
        f.vane.Size=Vector3.new(.16*k,.03*k,len);f.vane.CFrame=frame
        f.core.Size=Vector3.new(.05*k,.04*k,len*.8);f.core.CFrame=frame*CFrame.new(0,0,-.06*len)
        f.vane.Transparency=open<.03 and 1 or .2+(1-open)*.75;f.core.Transparency=open<.03 and 1 or .04+(1-open)*.9
    end
end
function T.cometHead(parent,style)
    local h={core=piece(parent,'CometCore',Vector3.one,Color3.new(1,1,1),true,true),glow=piece(parent,'CometGlow',Vector3.one,rgb(style.accent),true,true),coma=piece(parent,'CometComa',Vector3.one,rgb(style.accent),true,true),halo={}}
    for i=1,6 do h.halo[i]=piece(parent,'CometHalo',Vector3.one,Color3.new(1,1,1),true)end
    return h
end
function T.poseHead(h,cf,t,k,phase,show)
    local beat=1+math.sin(t*7)*.06
    h.core.Size=Vector3.one*.22*k*beat;h.core.CFrame=cf;h.core.Transparency=show and 0 or 1
    h.glow.Size=Vector3.new(.62,.42,.42)*k*beat;h.glow.CFrame=cf*CFrame.new(.08*k,0,0);h.glow.Transparency=show and .4 or 1
    h.glow.Color=T.prism(t*.35,.35)
    h.coma.Size=Vector3.new(1.5,1.25,1.05)*k*beat;h.coma.CFrame=cf*CFrame.new(.05*k,.12*k,0);h.coma.Transparency=(show and phase>=2)and .87 or 1
    for i,p in ipairs(h.halo)do
        local a=i/6*math.pi*2+t*2.4
        p.Size=Vector3.one*.1*k;p.CFrame=cf*CFrame.new(.04*k,math.cos(a)*.4*k,math.sin(a)*.4*k)*CFrame.Angles(.78,.6+t,.78)
        p.Color=T.prism(i/6+t*.3,.5);p.Transparency=(show and phase>=3)and .05 or 1
    end
end
T.cometLength={1.1,1.6,2.1}
local layout=CFrame.Angles(0,math.rad(-15),0)
local function path(s)
    return CFrame.fromMatrix(Vector3.new(s,0,.16*math.sin(s*1.5)),Vector3.new(1,0,.24*math.cos(s*1.5)).Unit,Vector3.yAxis)
end
T.path=path
local function figure(model)
    local steel,dark=Color3.fromRGB(84,96,114),Color3.fromRGB(46,54,66)
    local function b(name,size,cf,color,shape)
        local p=G.block(model,name,size,layout*cf,color);p.Material=Enum.Material.Metal;p.CastShadow=false
        if shape then p.Shape=shape end;return p
    end
    b('TokenBase',Vector3.new(.05,.5,.5),CFrame.new(0,.025,0)*CFrame.Angles(0,0,math.pi/2),dark,Enum.PartType.Cylinder)
    for _,z in ipairs({-.08,.08})do b('TokenLeg',Vector3.new(.14,.42,.13),CFrame.new(0,.26,z),dark)end
    b('TokenBody',Vector3.new(.24,.42,.36),CFrame.new(0,.68,0),steel)
    for _,z in ipairs({-.22,.22})do b('TokenArm',Vector3.new(.12,.38,.1),CFrame.new(0,.68,z),steel)end
    b('TokenHead',Vector3.one*.26,CFrame.new(0,1.04,0),steel,Enum.PartType.Ball)
end
local function ribbon(model,state,name,lane,y,from,to,n,w,h,color,tail,glow,base)
    for i=0,n-1 do
        local f=i/n;local s0,s1=from+(to-from)*f,from+(to-from)*(i+1)/n
        local a=(path(s0)*CFrame.new(0,y,lane)).Position;local b=(path(s1)*CFrame.new(0,y,lane)).Position
        local d=b-a;local wid=w*(1-f*.65)
        local p=piece(model,name,Vector3.new(wid,h,d.Magnitude*1.08),color:Lerp(tail,f),glow)
        p.CFrame=layout*CFrame.lookAt((a+b)/2,b);p.Transparency=(base or 0)+(1-(base or 0))*f*.7
        table.insert(state.ribbons,{part=p,f=f,base=p.Transparency})
    end
end
function T.display(style)
    local model=Instance.new('Model');model.Name='TrailDisplay';model.WorldPivot=CFrame.identity
    local tier=style.tier or 0;local accent,trim=rgb(style.accent),rgb(style.secondary)
    local state={tier=tier,style=style,elements={},ribbons={}};states[model]=state
    figure(model)
    local function stream(kind,n,span,from,life,phase)
        for i=1,n do local e=T.element(kind,model,style,i*1.7+tier,i%2==0 and 1 or -1)
            e.u0=(i-1)/n;e.span=span;e.from=from;e.life=life or e.spec.life;e.phase=phase or 1;table.insert(state.elements,e)
        end
    end
    local themed=V.display[style.theme]or V2.display[style.theme]
    if themed then themed(model,state,style,stream,ribbon)
    elseif tier==0 then ribbon(model,state,'Ribbon',0,.03,.1,2,6,.18,.04,accent,trim,false)
    elseif tier==1 then stream('puff',9,1.9,.05)
    elseif tier==2 then
        for _,lane in ipairs({-.12,.12})do
            ribbon(model,state,'Afterglow',lane,.17,.08,2.5,7,.05,.035,accent,trim,true)
            ribbon(model,state,'AfterglowHalo',lane,.15,.08,2.2,5,.15,.02,accent,trim,true,.66)
        end
        for i=1,4 do local m=piece(model,'AfterglowMote',Vector3.one*(.05-i*.006),trim,true,true)
            m.CFrame=layout*path(.5+i*.45)*CFrame.new(0,.24+hash(i)*.12,(hash(i+3)-.5)*.4);m.Transparency=.2+i*.12
        end
    elseif tier==3 then
        ribbon(model,state,'BoltPath',0,.03,.05,2.3,5,.05,.025,accent,rgb(style.primary),true,.35)
        stream('bolt',4,2.1,.05,1.1)
    elseif tier==4 then
        state.wings=T.wings(model,style)
        stream('feather',6,1.7,0,1.8);stream('ember',8,1.2,.05,1.1);stream('lick',5,1.6,.15,1)
        local light=Instance.new('PointLight');light.Color=accent;light.Range=3;light.Brightness=.6;light.Shadows=false;light.Parent=state.wings[1].core;state.light=light
    else
        state.head=T.cometHead(model,style);state.lanes={};state.core={}
        for i=1,4 do state.core[i]=piece(model,'CometStreak',Vector3.one,Color3.new(1,1,1),true,true)end
        for lane=1,3 do state.lanes[lane]={}
            for i=1,lane==1 and 6 or 14 do state.lanes[lane][i]=piece(model,'CometTail',Vector3.one,accent,true,lane==1)end
        end
        stream('star',10,2.2,.15,1.4,2)
        local light=Instance.new('PointLight');light.Color=accent;light.Range=3;light.Brightness=.6;light.Shadows=false;light.Parent=state.head.core;state.light=light
    end
    model:SetAttribute('CollectionTier',style.tier or 1);model:SetAttribute('CollectionRole','commanderTrail');model:SetAttribute('CollectionStyle',style.id)
    model:SetAttribute('CollectionMotion',tier>=5 and 4 or tier>=4 and 3 or tier>=3 and 1 or 0);model:SetAttribute('CollectionPhases',tier==5 and 3 or 1)
    model:SetAttribute('CollectionParticles',0)
    T.step(model,1.3,false,3);local n=0;for _,p in ipairs(model:GetChildren())do if p:IsA('BasePart')then n+=1 end end
    model:SetAttribute('CollectionGeometry',n)
    return model
end
function T.step(model,age,reduced,phase)
    local state=states[model];if not state then return end
    phase=math.clamp(phase or 1,1,3);local base=model:GetPivot()*layout
    local t=(reduced or state.tier<3)and 1.3 or age
    if state.light then state.light.Enabled=not reduced end
    if state.tier==2 and not reduced then
        for _,r in ipairs(state.ribbons)do r.part.Transparency=math.clamp(r.base+math.sin(age*3-r.f*7)*.1,0,1)end
    end
    if state.vstep then state.vstep(state,base,t,phase,reduced)end
    local length=state.head and T.cometLength[phase]or 0
    for _,e in ipairs(state.elements)do
        local u=(e.u0+t/e.life)%1
        if e.phase>phase then T.hide(e)else T.pose(e,base*path(e.from+u*(length>0 and length-.2 or e.span)),u,t,1)end
    end
    if state.wings then T.poseWings(state.wings,base*CFrame.new(.1,.92,0),t,1,1)end
    if state.head then
        T.poseHead(state.head,base*CFrame.new(.3,.44,0),t,1,phase,true)
        local function at(lane,f)
            local r=(.08+.3*f)*(lane==1 and 0 or 1);local a=f*8-t*5+lane*math.pi
            return path(.34+f*length)*CFrame.new(0,.44+.75*f*f+math.cos(a)*r,math.sin(a)*r)
        end
        for lane,list in ipairs(state.lanes)do
            local n=#list;local hidden=lane>1 and phase<2
            for i,p in ipairs(list)do
                local f=(i-1)/n
                if lane==1 then
                    local th=.5*(1-.7*f);p.Size=Vector3.new(length/n*2.8,th,th*1.3);p.CFrame=base*at(1,f+.5/n)
                    p.Transparency=math.min(1,.3+.5*f)
                else
                    local a,b=at(lane,f).Position,at(lane,i/n).Position;local d=b-a
                    p.Size=Vector3.new(.1*(1-f*.4),.1*(1-f*.4),d.Magnitude+.05);p.CFrame=base*CFrame.lookAt((a+b)/2,b)
                    p.Transparency=hidden and 1 or math.min(1,.02+.75*f^1.5)
                end
                p.Color=lane==1 and Color3.new(1,1,1):Lerp(T.prism(t*.4-f*.9,.7),.35+.6*f)or T.prism(t*.4-f*.9+lane*.17,.75)
            end
        end
        for i,p in ipairs(state.core)do
            local f=(i-1)/#state.core;p.Size=Vector3.new(length*.36,.1*(1-f*.6),.1*(1-f*.6));p.CFrame=base*at(1,(f+.4/#state.core)*.75)
            p.Color=Color3.new(1,1,1):Lerp(rgb(state.style.accent),f);p.Transparency=.05+.5*f
        end
    end
end
V.install(T);V2.install(T)
return T
