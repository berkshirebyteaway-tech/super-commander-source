local V={};local T
local function rgb(a)return Color3.fromRGB(table.unpack(a))end
local function out(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
local function piece(...)return T.piece(...)end
local function hash(n)return T.hash(n)end
local deep=Color3.fromRGB(236,124,36)
local function glintHue(x,sat)return Color3.fromHSV(.5+.28*(.5+.5*math.sin(x)),sat or .5,1)end
local function seg(p,o,a,b,w,h)
    local d=b-a;local len=d.Magnitude;if len<1e-3 then p.Transparency=1;return end
    p.Size=Vector3.new(w,h,len);p.CFrame=o*CFrame.lookAt((a+b)/2,b,math.abs(d.Unit.Y)>.97 and Vector3.xAxis or Vector3.yAxis)
end
V.kinds={
    miasma={life=1.4,build=function(e,parent,style)
        local acc,trim,dark=rgb(style.accent),rgb(style.secondary),rgb(style.primary)
        e.parts={piece(parent,'ToxicPool',Vector3.one,acc,true,true),piece(parent,'ToxicCloud',Vector3.one,acc:Lerp(dark,.3),false,true),
            piece(parent,'ToxicCloud',Vector3.one,trim:Lerp(acc,.4),false,true),piece(parent,'ToxicCore',Vector3.one,acc,true,true),
            piece(parent,'ToxicBubble',Vector3.one,trim,true,true)}
    end,pose=function(e,o,u,t,k)
        local h,z=e.seed,e.side*.06*k;local pool,bub=e.parts[1],e.parts[5]
        local r=(.16+.14*out(u*3))*k;pool.Size=Vector3.new(r*1.7,.02*k,r*1.3);pool.CFrame=o*CFrame.new(0,.012*k,z);pool.Transparency=.3+.7*u^1.2
        for i=2,4 do local c=e.parts[i];local f=math.clamp(u*1.2-(i-2)*.14,0,1)
            local d=(.12+.34*out(f))*k*(i==4 and .55 or 1);local a=h*3+i*2.1+t*1.4
            c.Size=Vector3.new(d,d*.82,d)
            c.CFrame=o*CFrame.new(math.cos(a)*.08*k*f+.06*k*u,(.07+.5*f*(.5+.25*i))*k,z+math.sin(a)*.1*k*f)
            c.Transparency=f<=0 and 1 or i==4 and .5+.5*f^1.2 or .22+.78*f^1.4
        end
        local b=u/.6
        if b<1 then bub.Size=Vector3.one*(.04+.05*b)*k;bub.CFrame=o*CFrame.new(math.sin(t*6+h)*.03*k,(.05+.42*b)*k,z+.04*k);bub.Transparency=.1
        else b=(u-.6)/.15;bub.Size=Vector3.one*(.1+.12*b)*k;bub.Transparency=b>=1 and 1 or .55+.45*b end
    end},
    splash={life=.9,build=function(e,parent,style)
        local white,acc=rgb(style.secondary):Lerp(Color3.new(1,1,1),.5),rgb(style.accent)
        e.parts={}
        for i=1,4 do e.parts[i]=piece(parent,'SprayDrop',Vector3.one,i%2==0 and white or acc:Lerp(white,.4),true,true)end
        for i=5,6 do e.parts[i]=piece(parent,'SprayJet',Vector3.one,acc:Lerp(white,.3),true,true)end
        e.parts[7]=piece(parent,'SprayMist',Vector3.one,white,true,true)
    end,pose=function(e,o,u,_,k)
        local h,side=e.seed,e.side
        for i=1,4 do local p=e.parts[i]
            local v=Vector3.new(.25+.5*hash(h+i*1.3),.7+.5*hash(h+i*2.7),side*(i>2 and -.3 or 1)*(.12+.45*hash(h+i*3.9)))
            local pos=Vector3.new(v.X*u,math.max(.02,v.Y*u-1.15*u*u),v.Z*u)*k;local vel=Vector3.new(v.X,v.Y-2.3*u,v.Z)
            local d=(.09-.04*u)*k;p.Size=Vector3.new(d,d,d*2.1);p.CFrame=o*CFrame.lookAt(pos,pos+vel)
            p.Transparency=.05+.95*u^2
        end
        local hs=.5*math.sin(math.pi*math.min(1,u*1.4))*k+.01
        for j,s in ipairs({-1,1})do local p=e.parts[4+j]
            p.Size=Vector3.new(.07*k,hs,.07*k);p.CFrame=o*CFrame.new(.06*k,0,s*.06*k)*CFrame.Angles(-s*(.45+.4*u),0,-.5)*CFrame.new(0,hs*.5,0)
            p.Transparency=.25+.75*u
        end
        local m=e.parts[7];local d=(.18+.4*out(u))*k;m.Size=Vector3.new(d*1.3,d*.7,d);m.CFrame=o*CFrame.new(.12*k*u,(.12+.15*u)*k,0);m.Transparency=.55+.45*u
    end},
    print={life=2.2,build=function(e,parent,style)
        e.style=style;local hot=rgb(style.secondary)
        e.parts={piece(parent,'EmberSole',Vector3.one,hot,true,true),piece(parent,'EmberToe',Vector3.one,hot,true,true),
            piece(parent,'EmberGlow',Vector3.one,rgb(style.accent),true,true),piece(parent,'EmberSpark',Vector3.one,hot,true,true),piece(parent,'EmberFlame',Vector3.one,rgb(style.accent),true,true)}
    end,pose=function(e,o,u,t,k)
        local side=e.side;local z=side*.09*k;local st=e.style
        local c=u<.35 and rgb(st.secondary):Lerp(rgb(st.accent),u/.35)or rgb(st.accent):Lerp(Color3.fromRGB(78,62,54),(u-.35)/.65)
        local foot=o*CFrame.new(0,.014*k,z)*CFrame.Angles(0,side*.12,0)
        local sole,toe,glow=e.parts[1],e.parts[2],e.parts[3]
        sole.Size=Vector3.new(.3,.03,.14)*k;sole.CFrame=foot*CFrame.new(.07*k,0,0);toe.Size=Vector3.new(.13,.03,.16)*k;toe.CFrame=foot*CFrame.new(-.14*k,0,0)
        sole.Color=c;toe.Color=c;sole.Transparency=.02+.5*u^2;toe.Transparency=.02+.5*u^2
        local fl=1+math.sin(t*11+e.seed*7)*.08
        glow.Size=Vector3.new(.46,.012,.26)*k*fl;glow.CFrame=foot*CFrame.new(-.02*k,-.004*k,0);glow.Color=rgb(st.accent):Lerp(deep,u)
        glow.Transparency=math.min(1,.62+.5*u)
        local p=e.parts[4];local f=(u*2.6+hash(e.seed+4))%1
        p.Size=Vector3.one*(.05*(1-f)+.014)*k;p.Color=rgb(st.secondary):Lerp(rgb(st.accent),f)
        p.CFrame=foot*CFrame.new((-.05+.1*hash(e.seed+9)+.08*f)*k,(.04+.6*f)*k,math.sin(t*5+e.seed)*.05*k*f);p.Transparency=u>.8 and 1 or .05+.95*f
        local fh=math.max(0,1-u/.6)*(.36+.08*math.sin(t*14+e.seed*3))*k;local fl2=e.parts[5]
        fl2.Size=Vector3.new(.1*k,fh+.01,.1*k);fl2.CFrame=foot*CFrame.new(-.02*k,fh*.45,0)*CFrame.Angles(0,0,-.3);fl2.Color=rgb(st.accent):Lerp(rgb(st.secondary),.3)
        fl2.Transparency=fh<.01 and 1 or .15+.6*u
    end},
    ghost={life=1,build=function(e,parent,style)
        local core,glow=rgb(style.secondary),rgb(style.accent);e.parts={}
        glow=glow:Lerp(Color3.fromRGB(70,120,255),.35)
        e.parts[1]=piece(parent,'StaticHead',Vector3.one,core,true,true);e.parts[2]=piece(parent,'StaticBody',Vector3.one,glow,true)
        for i=3,4 do e.parts[i]=piece(parent,'StaticLeg',Vector3.one,glow,true)end
        for i=5,6 do e.parts[i]=piece(parent,'StaticArc',Vector3.one,core,true)end
        for i=7,8 do e.parts[i]=piece(parent,'StaticSpark',Vector3.one,core,true,true)end
    end,pose=function(e,o,u,t,k)
        local g=math.floor(t*12);local s=e.seed;local z0=e.side*.2*k
        local dz=hash(s+g)>.7 and (hash(s+g*1.7)-.5)*.12*k or 0
        local a=math.min(1,.28+.68*u+(hash(s+g*2.3)>.86 and .3 or 0))
        local root=o*CFrame.new(0,0,z0+dz)
        local head,body=e.parts[1],e.parts[2]
        head.Size=Vector3.one*.26*k;head.CFrame=root*CFrame.new(0,1.02*k,0);head.Transparency=a
        body.Size=Vector3.new(.24,.42,.36)*k;body.CFrame=root*CFrame.new(0,.66*k,0)*CFrame.new(0,0,dz*.6);body.Transparency=math.min(1,a+.08)
        for j,lz in ipairs({-.08,.08})do local p=e.parts[2+j];p.Size=Vector3.new(.12,.42,.12)*k;p.CFrame=root*CFrame.new(0,.21*k,lz*k);p.Transparency=math.min(1,a+.08)end
        local fade=u<.8 and math.min(1,(hash(s+g*3.1)>.8 and .5 or 0)+u*.5)or 1
        local from=Vector3.new(0,.45*k,z0+dz);local to=Vector3.new(.55*k,.03*k,-z0)
        local mid=from:Lerp(to,.5)+Vector3.new(hash(s+g*4.3)-.5,hash(s+g*5.9)-.5,hash(s+g*6.1)-.5)*.3*k
        seg(e.parts[5],o,from,mid,.035*k,.035*k);seg(e.parts[6],o,mid,to,.035*k,.035*k)
        e.parts[5].Transparency=fade;e.parts[6].Transparency=fade
        for j,at in ipairs({mid,to})do local p=e.parts[6+j];p.Size=Vector3.one*(.06+.05*hash(s+g+j))*k;p.CFrame=o*CFrame.new(at);p.Transparency=fade end
    end},
    stardust={life=1.6,build=function(e,parent,style)
        local gold,pale=rgb(style.accent),rgb(style.secondary);e.style=style
        e.parts={piece(parent,'Stardust',Vector3.one,gold,true),piece(parent,'Stardust',Vector3.one,gold,true),piece(parent,'StardustMote',Vector3.one,pale,true,true)}
    end,pose=function(e,o,u,t,k)
        local h=e.seed;local tw=(.6+.4*math.abs(math.sin(t*7+h*9)))*(1-.45*u)
        local pos=Vector3.new(.15*u*k,(.1+.7*out(u)+.06*math.sin(t*3+h))*k,(e.side*(.12+.3*hash(h))+math.sin(t*2+h*4)*.12*u)*k)
        local cf=o*CFrame.new(pos)*CFrame.Angles(t*1.5+h,h*3,0)
        local c=rgb(e.style.accent):Lerp(rgb(e.style.secondary),hash(h+2)*.6+.3*u)
        for i=1,2 do local p=e.parts[i];p.Size=(i==1 and Vector3.new(.26,.03,.03)or Vector3.new(.03,.26,.03))*k*tw;p.CFrame=cf;p.Color=c;p.Transparency=.05+.9*u^1.5 end
        local m=e.parts[3];m.Size=Vector3.one*.09*k*tw;m.CFrame=cf;m.Transparency=.45+.55*u
    end},
    glint={life=.9,build=function(e,parent)
        e.parts={piece(parent,'EclipseGlint',Vector3.one,Color3.new(1,1,1),true),piece(parent,'EclipseGlintFlare',Vector3.one,Color3.new(1,1,1),true)}
    end,pose=function(e,o,u,t,k)
        local h=e.seed;local tw=(.5+.5*math.abs(math.sin(t*9+h*7)))*(1-.5*u)
        local cf=o*CFrame.new(.12*u*k,(.42+.22*hash(h)+.3*u)*k,e.side*(.26+.3*u)*k)*CFrame.Angles(t*2+h,.785,.785)
        local a,b=e.parts[1],e.parts[2];local c=glintHue(h*2+t*1.5,.5)
        a.Size=Vector3.one*.09*k*tw;a.CFrame=cf;a.Color=c;a.Transparency=.05+.9*u^1.4
        b.Size=Vector3.new(.34,.018,.018)*k*tw;b.CFrame=CFrame.new(cf.Position)*o.Rotation*CFrame.Angles(0,0,t*3+h)
        b.Color=c;b.Transparency=.15+.85*u^1.2
    end},
    eclipseRing={life=1.4,build=function(e,parent)
        e.parts={};for i=1,8 do e.parts[i]=piece(parent,'EclipseRing',Vector3.one,Color3.new(1,1,1),true)end
    end,pose=function(e,o,u,t,k)
        local r=(.16+.3*out(u*2.5)+.14*math.max(0,u-.6))*k;local fade=u<.55 and .05 or .05+.95*((u-.55)/.45)^1.2
        local c=o*CFrame.new(0,.42*k,0);local spin=t*1.1+e.seed
        for i,p in ipairs(e.parts)do
            local a0,a1=spin+(i-1)/8*math.pi*2,spin+i/8*math.pi*2
            seg(p,c,Vector3.new(0,math.cos(a0)*r,math.sin(a0)*r),Vector3.new(0,math.cos(a1)*r,math.sin(a1)*r),.055*k,.055*k)
            p.Color=glintHue(i/8*math.pi*2+t*2+e.seed,.45);p.Transparency=fade
        end
    end},
}
function V.cape(parent,style)
    local navy,gold=Color3.fromRGB(58,72,186),rgb(style.accent),rgb(style.accent);local c={panels={},trims={},stars={}}
    for i=1,7 do
        c.panels[i]=piece(parent,'CapePanel',Vector3.one,navy:Lerp(rgb(style.primary),i/12),false);c.panels[i].Material=Enum.Material.SmoothPlastic
        c.trims[i*2-1]=piece(parent,'CapeTrim',Vector3.one,gold,true);c.trims[i*2]=piece(parent,'CapeTrim',Vector3.one,gold,true)
        c.stars[i]=piece(parent,'CapeStar',Vector3.one,rgb(style.secondary),true)
    end
    c.hem=piece(parent,'CapeHem',Vector3.one,gold,true);c.clasps={piece(parent,'CapeClasp',Vector3.one,gold,true,true),piece(parent,'CapeClasp',Vector3.one,gold,true,true)}
    return c
end
local function capeAt(f,t,open)
    local hang,fly=.92-.86*f,.92-.64*f+.1*math.sin(f*6-t*5)*f
    return Vector3.new(.13+f*(.25+1.25*open),hang+(fly-hang)*open,math.sin(f*3.2-t*2.6)*.24*f*f)
end
function V.poseCape(c,cf,t,k,open)
    local hidden=open<.03;local n=#c.panels
    local function edges(f)
        local p,q=capeAt(f,t,open),capeAt(math.min(1,f+.02),t,open)-capeAt(math.max(0,f-.02),t,open)
        local right=q:Cross(Vector3.yAxis);right=right.Magnitude>1e-4 and right.Unit or Vector3.zAxis;local w=.19+.27*f
        local droop=Vector3.new(0,-.06*f-.03,0);local flap=math.sin(f*8-t*7)*.04*f
        return p*k,(p-right*w+droop+Vector3.new(0,flap,0))*k,(p+right*w+droop-Vector3.new(0,flap,0))*k,w*2*k
    end
    local c0,l0,r0,w0=edges(0)
    for i=1,n do
        local c1,l1,r1,w1=edges(i/n);local fr=cf*CFrame.lookAt((c0+c1)/2,c1);local len=(c1-c0).Magnitude*1.12;local w=(w0+w1)/2
        c.panels[i].Size=Vector3.new(w,.025*k,len);c.panels[i].CFrame=fr
        seg(c.trims[i*2-1],cf,l0,l1,.04*k,.04*k);seg(c.trims[i*2],cf,r0,r1,.04*k,.04*k)
        local st=c.stars[i];local tw=.8+.2*math.sin(t*5+i*1.9);st.Size=Vector3.new(.1,.02,.1)*k*tw;st.CFrame=fr*CFrame.new(0,.018*k,0)*CFrame.Angles(0,math.pi/4,0)
        for _,p in ipairs({c.panels[i],c.trims[i*2-1],c.trims[i*2]})do p.Transparency=hidden and 1 or 0 end
        st.Transparency=hidden and 1 or .1+.3*(1-tw)*4
        if i==n then seg(c.hem,cf,l1,r1,.06*k,.05*k);c.hem.Transparency=hidden and 1 or 0 end
        c0,l0,r0,w0=c1,l1,r1,w1
    end
    for j,s in ipairs({-1,1})do local p=c.clasps[j];p.Size=Vector3.one*.09*k;p.CFrame=cf*CFrame.new(.12*k,.9*k,s*.17*k);p.Transparency=hidden and 1 or 0 end
end
local plumeSpec={{0,2.3},{-1,1.85},{1,1.85}}
function V.plumes(parent,style)
    local list={}
    for _,spec in ipairs(plumeSpec)do local pl={j=spec[1],len=spec[2],vanes={},cores={}}
        for i=1,6 do pl.vanes[i]=piece(parent,'PhoenixPlume',Vector3.one,rgb(style.accent),true);pl.cores[i]=piece(parent,'PhoenixPlumeCore',Vector3.one,rgb(style.secondary),true)end
        pl.eye=piece(parent,'PhoenixEye',Vector3.one,rgb(style.accent),true,true);pl.pupil=piece(parent,'PhoenixEyeCore',Vector3.one,rgb(style.secondary),true,true)
        table.insert(list,pl)
    end
    return {plumes=list,style=style}
end
local function plumeAt(j,L,f,t,open)
    local len=L*(.35+.65*open)
    return Vector3.new(.16+f*len*.9,.6+(.5*math.sin(f*math.pi)-.5*f^1.5+.15*f^4)*(.3+.7*open)+math.sin(f*6-t*5+j)*.07*f,
        j*(.06+.5*f)*(.4+.6*open)+math.sin(f*4-t*3.4+j*1.3)*.12*f)
end
function V.posePlumes(ph,cf,t,k,open)
    local hidden=open<.03;local acc,trim=rgb(ph.style.accent),rgb(ph.style.secondary)
    for _,pl in ipairs(ph.plumes)do local n=#pl.vanes;local fr,len
        for i=1,n do
            local f0,f1=(i-1)/n,i/n;local a,b=plumeAt(pl.j,pl.len,f0,t,open)*k,plumeAt(pl.j,pl.len,f1,t,open)*k
            len=(b-a).Magnitude*1.08;fr=cf*CFrame.lookAt((a+b)/2,b);local fm=(f0+f1)/2;local w=(.17-.08*fm)*k
            local v,c=pl.vanes[i],pl.cores[i];local fl=math.sin(t*9+i*1.7+pl.j)*.08
            v.Size=Vector3.new(w,.03*k,len);v.CFrame=fr;v.Color=trim:Lerp(acc,math.clamp(fm*2+fl,0,1)):Lerp(deep,math.clamp(fm*1.4-.45,0,1))
            c.Size=Vector3.new(w*.36,.045*k,len*.92);c.CFrame=fr;c.Color=Color3.new(1,1,1):Lerp(trim,.4+fm*.6)
            v.Transparency=hidden and 1 or .05+.25*fm;c.Transparency=hidden and 1 or .05+.4*fm
        end
        local beat=1+math.sin(t*4+pl.j*2)*.08;local tip=fr*CFrame.new(0,0,-len/2-.12*k)
        pl.eye.Size=Vector3.new(.24,.03,.34)*k*beat;pl.eye.CFrame=tip;pl.eye.Color=acc:Lerp(deep,.35)
        pl.pupil.Size=Vector3.new(.1,.05,.15)*k*beat;pl.pupil.CFrame=tip*CFrame.new(0,.008*k,0)
        pl.eye.Transparency=hidden and 1 or .08;pl.pupil.Transparency=hidden and 1 or 0
    end
end
function V.disc(parent,style)
    local d={black=piece(parent,'EclipseDisc',Vector3.one,Color3.fromRGB(6,6,12),false,true),corona=piece(parent,'EclipseCorona',Vector3.one,rgb(style.secondary),true,true),
        outer=piece(parent,'EclipseCoronaOuter',Vector3.one,rgb(style.accent),true,true),glint=piece(parent,'EclipseDiamond',Vector3.one,Color3.new(1,1,1),true,true),
        flares={piece(parent,'EclipseFlare',Vector3.one,Color3.new(1,1,1),true),piece(parent,'EclipseFlare',Vector3.one,Color3.new(1,1,1),true)},rays={},style=style}
    d.black.Material=Enum.Material.Glass;d.black.Reflectance=.25
    for i=1,8 do d.rays[i]=piece(parent,'EclipseRay',Vector3.one,rgb(style.secondary),true)end
    return d
end
function V.poseDisc(d,cf,t,k,phase,show)
    k*=1.25
    local beat=1+.04*math.sin(t*2.4);local trim,acc=rgb(d.style.secondary),rgb(d.style.accent)
    d.black.Size=Vector3.new(.05,.5,.5)*k;d.black.CFrame=cf*CFrame.new(.035*k,0,0);d.black.Transparency=show and 0 or 1
    d.corona.Size=Vector3.new(.03,.62,.62)*k*beat;d.corona.CFrame=cf;d.corona.Transparency=show and .04 or 1
    local o=.78+.14*phase;d.outer.Size=Vector3.new(.02,o,o)*k*beat;d.outer.CFrame=cf*CFrame.new(-.02*k,0,0);d.outer.Transparency=show and (phase>=2 and .55 or .78)or 1
    for i,p in ipairs(d.rays)do
        local a=i/8*math.pi*2+t*.3;local L=(.1+.1*phase+.05*math.sin(t*3+i*2.3))*k*(i%2==0 and 1 or .6);local r0=.29*k
        local dir=Vector3.new(0,math.cos(a),math.sin(a))
        seg(p,cf,dir*r0,dir*(r0+L),.03*k*(1+.3*(phase-1)),.02*k);p.Color=trim:Lerp(acc,i%2*.6);p.Transparency=show and .12 or 1
    end
    local g=t*.55;local at=cf*CFrame.new(.05*k,math.cos(g)*.26*k,math.sin(g)*.26*k)
    d.glint.Size=Vector3.one*.11*k*(1+.3*math.sin(t*9));d.glint.CFrame=at;d.glint.Transparency=show and 0 or 1
    for i,p in ipairs(d.flares)do
        p.Size=(i==1 and Vector3.new(.02,.48,.02)or Vector3.new(.02,.02,.32))*k*(1+.25*math.sin(t*9));p.CFrame=at;p.Color=glintHue(t*1.4+i*1.5,.4);p.Transparency=show and .08 or 1
    end
end
V.display={
    toxic=function(model,state,style,stream,ribbon)
        ribbon(model,state,'ToxicSlick',0,.015,.05,2.1,5,.24,.02,rgb(style.accent),rgb(style.primary),true,.5)
        stream('miasma',7,2,.05,1.6)
    end,
    spray=function(model,state,style,stream)
        state.wake={};local foam=rgb(style.secondary):Lerp(Color3.new(1,1,1),.4)
        for _,lane in ipairs({-1,1})do for i=1,4 do
            table.insert(state.wake,{part=piece(model,'SprayWake',Vector3.one,foam:Lerp(rgb(style.accent),i/5),true),lane=lane,i=i})
        end end
        stream('splash',5,2,.05,1)
        state.vstep=function(s,base,t)
            for _,w in ipairs(s.wake)do local f0,f1=(w.i-1)/4,w.i/4
                local function at(f)return (T.path(.12+f*2.2)*CFrame.new(0,.02,w.lane*(.07+.22*f))).Position end
                local a,b=at(f0),at(f1);w.part.Size=Vector3.new(.08*(1-f0*.5),.02,(b-a).Magnitude*1.05);w.part.CFrame=base*CFrame.lookAt((a+b)/2,b)
                w.part.Transparency=math.clamp(.15+.6*f0+math.sin(t*6-f0*9)*.12,0,1)
            end
        end
    end,
    embers=function(_,_,_,stream)stream('print',8,2.2,.05,2.2)end,
    static=function(_,_,_,stream)stream('ghost',5,2.2,.12,1.2)end,
    stardust=function(model,state,style,stream)
        state.cape=V.cape(model,style);stream('stardust',10,1.6,.45,1.6)
        local light=Instance.new('PointLight');light.Color=rgb(style.accent);light.Range=3;light.Brightness=.6;light.Shadows=false;light.Parent=state.cape.clasps[1];state.light=light
        state.vstep=function(s,base,t)V.poseCape(s.cape,base,t,1,1)end
    end,
    phoenix=function(model,state,style,stream)
        state.plumes=V.plumes(model,style);stream('feather',4,1.6,.3,1.8);stream('ember',8,1.4,.25,1.2)
        local light=Instance.new('PointLight');light.Color=rgb(style.accent);light.Range=3;light.Brightness=.7;light.Shadows=false;light.Parent=state.plumes.plumes[1].eye;state.light=light
        state.vstep=function(s,base,t)V.posePlumes(s.plumes,base,t,1,1)end
    end,
    eclipse=function(model,state,style,stream)
        state.disc=V.disc(model,style);state.band={}
        local ink=Color3.fromRGB(12,10,22);local trim=rgb(style.secondary)
        for i=1,8 do local plate=piece(model,'EclipseBand',Vector3.one,ink,false);plate.Material=Enum.Material.Glass;plate.Reflectance=.2
            state.band[i]={plate=plate,edges={piece(model,'EclipseEdge',Vector3.one,trim,true),piece(model,'EclipseEdge',Vector3.one,trim,true)},
                sheath=piece(model,'EclipseSheath',Vector3.one,rgb(style.accent),true,true)}
        end
        for i=1,3 do local e=T.element('eclipseRing',model,style,i*2.3,1);e.u0=(i-1)/3;e.span=2;e.from=.45;e.life=3;e.phase=i==1 and 2 or 3;table.insert(state.elements,e)end
        stream('glint',6,2,.35,1)
        local light=Instance.new('PointLight');light.Color=rgb(style.accent);light.Range=3.5;light.Brightness=.8;light.Shadows=false;light.Parent=state.disc.corona;state.light=light
        state.vstep=function(s,base,t,phase)
            local L=V.bandLength[phase];for _,e in ipairs(s.elements)do e.span=L-(e.kind=='eclipseRing'and .45 or .3)end
            V.poseDisc(s.disc,base*CFrame.new(.22,1.32,0)*CFrame.Angles(0,0,math.rad(25)),t,1,phase,true)
            local n=#s.band
            local function at(f)return (T.path(.3+f*L)*CFrame.new(0,.56-.22*f+.05*math.sin(f*5-t*2),0)).Position end
            for i,b in ipairs(s.band)do
                local f0,f1=(i-1)/n,i/n;local fm=(f0+f1)/2;local a,c=at(f0),at(f1);local len=(c-a).Magnitude*1.04
                local pulse=math.max(0,math.sin(fm*9-t*6))
                local fr=base*CFrame.lookAt((a+c)/2,c)*CFrame.Angles(0,0,math.sin(fm*4-t*1.8)*.6);local w=.78*(1-.45*fm)
                b.plate.Size=Vector3.new(w,.03,len);b.plate.CFrame=fr;b.plate.Transparency=.02+.5*fm^2
                b.sheath.Size=Vector3.new(w*1.45,.26*(1-.4*fm),len*1.35);b.sheath.CFrame=fr;b.sheath.Color=rgb(s.style.accent):Lerp(glintHue(t+fm*3,.5),.3*pulse)
                b.sheath.Transparency=math.min(1,.74+.2*fm-.1*pulse)
                for j,sd in ipairs({-1,1})do local p=b.edges[j];p.Size=Vector3.new(.05,.05,len);p.CFrame=fr*CFrame.new(sd*w/2,0,0)
                    p.Color=trim:Lerp(glintHue(t*1.2+fm*4+j,.6),.25+.6*pulse);p.Transparency=.04+.6*fm^1.5
                end
            end
        end
    end,
}
V.bandLength={1.3,1.9,2.5}
V.specs={
    toxic={pieces={{kind='miasma',every=.15,life=1.4,cap=8}}},
    spray={pieces={{kind='splash',every=.1,life=.8,cap=7}}},
    embers={pieces={{kind='print',every=.2,life=2,cap=10}}},
    static={pieces={{kind='ghost',every=.18,life=.9,cap=5,at=.45}}},
    stardust={pieces={{kind='stardust',every=.1,life=1.4,cap=10,at=.9}}},
    phoenix={pieces={{kind='feather',every=.2,life=1.2,cap=5},{kind='ember',every=.12,life=1,cap=8,at=.6}}},
    eclipse={pieces={{kind='glint',every=.12,life=.8,cap=6,at=.3},{kind='eclipseRing',every=.8,life=1.4,cap=3,phase=2,at=.5},{kind='eclipseRing',every=.8,life=1.4,cap=3,phase=3,at=.9}}},
}
function V.attach(self,theme,trail,emitter,fx)
    local skin,k=self.style,self.k;local feet=-self.foot;local accent,trim,dark=rgb(skin.accent),rgb(skin.secondary),rgb(skin.primary)
    local s={};self.vol=s
    s.attached={};local function keep(list)for _,p in ipairs(list)do table.insert(self.spawned,p);table.insert(s.attached,p)end end
    if theme=='toxic'then
        trail('ToxicSlick',Vector3.new(0,feet+.02*k,.05*k),Vector3.new(0,feet+.09*k,.05*k),.7,ColorSequence.new(accent,dark),.4,.6)
        emitter('ToxicBubbles',Vector3.new(0,feet+.1*k,.1*k),14,1.2,.06*k,.4*k,ColorSequence.new(trim,accent),Vector3.new(0,.9*k,0))
    elseif theme=='spray'then
        for _,x in ipairs({-.15*k,.15*k})do trail('SprayWake',Vector3.new(x,feet+.02*k,.05*k),Vector3.new(x,feet+.07*k,.05*k),.55,ColorSequence.new(Color3.new(1,1,1),accent),.15,.4)end
        emitter('SprayMist',Vector3.new(0,feet+.12*k,.15*k),22,.6,.09*k,1.2*k,ColorSequence.new(trim,accent),Vector3.new(0,-3*k,0))
    elseif theme=='embers'then
        trail('EmberGlow',Vector3.new(0,feet+.01*k,.05*k),Vector3.new(0,feet+.05*k,.05*k),.6,ColorSequence.new(accent,deep),.45,.5)
        emitter('FootEmbers',Vector3.new(0,feet+.06*k,.1*k),16,1,.05*k,.5*k,ColorSequence.new(trim,accent),Vector3.new(0,.7*k,0))
    elseif theme=='static'then
        trail('StaticLine',Vector3.new(0,feet+.03*k,.05*k),Vector3.new(0,feet+.08*k,.05*k),.35,ColorSequence.new(trim,accent),.1,.3)
        emitter('StaticSparks',Vector3.new(0,feet+.4*k,.05*k),20,.35,.06*k,2.5*k,ColorSequence.new(trim,accent),Vector3.new(0,-2*k,0))
    elseif theme=='stardust'then
        trail('StardustPath',Vector3.new(0,feet+.02*k,.3*k),Vector3.new(0,feet+.06*k,.3*k),.7,ColorSequence.new(trim,accent),.3,.4)
        emitter('StardustSparkle',Vector3.new(0,feet+.8*k,.3*k),18,1.2,.07*k,.4*k,ColorSequence.new(trim,accent),Vector3.new(0,-.3*k,0))
        s.cape=V.cape(fx,skin);keep(s.cape.panels);keep(s.cape.trims);keep(s.cape.stars);keep(s.cape.clasps);keep({s.cape.hem})
    elseif theme=='phoenix'then
        trail('PhoenixFire',Vector3.new(0,feet+.55*k,.15*k),Vector3.new(0,feet+.72*k,.15*k),.55,ColorSequence.new(trim,deep),.3,.3)
        emitter('PhoenixEmbers',Vector3.new(0,feet+.7*k,.3*k),26,1,.06*k,.6*k,ColorSequence.new(trim,accent),Vector3.new(0,.8*k,0))
        s.plumes=V.plumes(fx,skin)
        for _,pl in ipairs(s.plumes.plumes)do keep(pl.vanes);keep(pl.cores);keep({pl.eye,pl.pupil})end
    elseif theme=='eclipse'then
        local y=feet+.42*k;local w=.3*k;s.y=y;s.w=w;s.twist={}
        local band,b0,b1=trail('EclipseBand',Vector3.new(-w,y,.2*k),Vector3.new(w,y,.2*k),.5,ColorSequence.new(Color3.fromRGB(8,6,16),Color3.fromRGB(30,20,56)),.05,.5)
        band.FaceCamera=false;band.LightEmission=0;table.insert(s.twist,{b0,-1,0});table.insert(s.twist,{b1,1,0})
        for _,sd in ipairs({-1,1})do local _,a0,a1=trail('EclipseCorona',Vector3.new(sd*w,y-.03*k,.2*k),Vector3.new(sd*w,y+.03*k,.2*k),.5,ColorSequence.new(trim,accent),0,.3)
            table.insert(s.twist,{a0,sd,-.03*k});table.insert(s.twist,{a1,sd,.03*k})end
        trail('EclipseVeil',Vector3.new(0,y-.3*k,.25*k),Vector3.new(0,y+.3*k,.25*k),.6,ColorSequence.new(accent,trim),.7,.6)
        emitter('EclipseGlints',Vector3.new(0,y,.3*k),20,.9,.07*k,.6*k,ColorSequence.new(glintHue(0,.5),glintHue(math.pi,.5)))
        s.disc=V.disc(fx,skin);keep({s.disc.black,s.disc.corona,s.disc.outer,s.disc.glint});keep(s.disc.flares);keep(s.disc.rays)
    end
end
function V.step(self,body,now,moving,reduced,phase)
    local s=self.vol;local k=self.k;local open=self.open
    if not body and not s.folded then s.folded=true
        for _,p in ipairs(s.attached)do p.Transparency=1 end
    elseif body then s.folded=nil end
    if s.cape and body then V.poseCape(s.cape,body,now,k,open)end
    if s.plumes and body then V.posePlumes(s.plumes,body,now,k,open)end
    if s.disc then
        if body then V.poseDisc(s.disc,body*CFrame.new(.22*k,1.32*k,0)*CFrame.Angles(0,0,math.rad(25)),now,k,phase,open>.3)end
        local life=reduced and .22 or ({.5,.95,1.45})[phase]
        for i,t in ipairs(self.trails)do
            t.Lifetime=life*(i==4 and .8 or 1);if i==4 then t.Enabled=moving and not reduced and phase>=3 end
        end
        local tw=reduced and 0 or math.sin(now*1.8)*.5;local c,sn=math.cos(tw),math.sin(tw)
        for _,a in ipairs(s.twist)do local x,dy=a[2]*s.w,a[3];a[1].Position=Vector3.new(x*c-dy*sn,s.y+x*sn+dy*c,.2*k)end
    end
end
function V.install(themes)T=themes;for name,kind in pairs(V.kinds)do T.kinds[name]=kind end end
return V
