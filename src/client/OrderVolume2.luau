local TAU=math.pi*2
local function ramp(t,a,b)return math.clamp((t-a)/(b-a),0,1)end
local function seg(a,b,w,d,up)
    local v=b-a;local len=v.Magnitude
    if len<1e-4 then return CFrame.new(a),Vector3.new(w,d,.001)end
    up=up or (math.abs(v.Y/len)>.98 and Vector3.xAxis or Vector3.yAxis)
    return CFrame.lookAt((a+b)/2,b,up),Vector3.new(w,d,len)
end
return function(themes,k)
local piece,disc,dash,out,rgb=k.piece,k.disc,k.dash,k.out,k.rgb
themes.ascend=function(rig,s)
    local trim,accent,base=rgb(s.secondary),rgb(s.accent),rgb(s.primary)
    local jade=base:Lerp(trim,.45);local pearl=Color3.fromRGB(255,246,214)
    rig.show=.62
    local function W()return rig.preview and 1 or 1.3 end
    local function H()return rig.preview and 1.6 or 3.9 end
    piece(rig,'DragonPlate',base,false,function(t)local c,sz=disc(.72,.04,.02)();return c,sz*out(t/.12),.05 end,0,1,'cylinder')
    for i=0,13 do local f=i/13
        piece(rig,'DragonSpiral',i%2==0 and trim or jade,true,function(t)
            local g=out((t-f*.25)/.2);local w=(.2+.09*f)*W()*g+.001
            return CFrame.Angles(0,f*TAU*1.2,0)*CFrame.new(0,.045,-(.32+1.15*f)*W())*CFrame.Angles(0,math.pi/4,0),Vector3.new(w,.03,w),g<=0 and 1 or .1
        end,1)
    end
    for i=0,9 do local d=dash(i,10,.05,.7)
        piece(rig,'DragonRing',accent,true,function(t)local c,sz=d(1.62*W()*out(t/.3)+.01);return c,sz*Vector3.new(1,.05,.08),.1 end,2)
    end
    local function lead(t)return .1+.9*out(ramp(t,.06,.58))end
    local function path(s,sec)
        local a=s*TAU*1.5+(rig.preview and 0 or sec*1.3);local r=(.95-.35*s)*W()+(rig.preview and 0 or .07*math.sin(sec*7-s*11))
        return Vector3.new(math.sin(a)*r,.12+s*H(),-math.cos(a)*r)
    end
    for j=0,11 do
        piece(rig,'DragonBody',j%2==0 and trim or jade,j%2==0,function(t,sec)
            local s0=lead(t)-(j+1)*.075;if s0<0 then return CFrame.new(0,.05,0),Vector3.one*.001,1 end
            local c,sz=seg(path(s0,sec),path(s0+.075,sec),(.34-.017*j)*W(),(.3-.015*j)*W())
            return c,sz*Vector3.new(1,1,1.35),0
        end,1,1,'round')
    end
    local function head(t,sec)
        local s0=lead(t);local p=path(s0,sec);local d=(p-path(s0-.04,sec)).Unit;local roar=out(ramp(t,.55,.68))*(1-.5*ramp(t,.85,1))
        return CFrame.lookAt(p,p+d)*CFrame.Angles(.55*roar,0,0),roar
    end
    local function part(name,color,glow,f,shape)
        return piece(rig,name,color,glow,function(t,sec)local h,roar=head(t,sec);local cf,size=f(roar,sec);return h*CFrame.new(cf.Position*W())*cf.Rotation,size*W(),0 end,1,1,shape)
    end
    part('DragonHead',trim,true,function()return CFrame.identity,Vector3.new(.36,.26,.52)end,'round')
    part('DragonJaw',jade,false,function(roar)return CFrame.new(0,-.13,-.06)*CFrame.Angles(-.45*roar,0,0),Vector3.new(.26,.08,.4)end)
    for _,x in ipairs({-1,1})do
        part('DragonHorn',accent,true,function()return seg(Vector3.new(x*.08,.1,.12),Vector3.new(x*.22,.3,.38),.05,.05)end)
        part('DragonWhisker',accent,true,function(_,sec)local sw=rig.preview and 0 or math.sin(sec*8+x)*.08
            return seg(Vector3.new(x*.1,-.04,-.2),Vector3.new(x*.48,-.08+sw,.08),.035,.035)end)
    end
    local orb=piece(rig,'DragonPearl',pearl,true,function(t,sec)
        local p=path(math.min(1.12,lead(t)+.14),sec);local f=1+.5*ramp(t,.55,.62)*(1-ramp(t,.62,.8))
        return CFrame.new(p+Vector3.new(0,.15,0)),Vector3.one*.24*W()*f,0
    end,2,1,'ball')
    for i=0,7 do local d=dash(i+.5,8,.06,.55)
        piece(rig,'DragonRoar',i%2==0 and accent or pearl,true,function(t)
            local g=ramp(t,.58,.95);local c,sz=d((.6+1.3*out(g))*W());return c,sz*Vector3.new(1,.05,.1),g<=0 and 1 or .05+.85*g^2
        end,2)
    end
    rig.lightAt=orb.part
end
themes.jackpot=function(rig,s)
    local trim,accent,base=rgb(s.secondary),rgb(s.accent),rgb(s.primary)
    local white=Color3.fromRGB(248,252,255)
    rig.show=.66
    local function W()return rig.preview and 1 or 1.3 end
    local function JH()return rig.preview and 1.45 or 3.6 end
    piece(rig,'JackpotPlate',base,false,function(t)local c,sz=disc(.64,.04,.02)();return c,sz*out(t/.12),.05 end,0,1,'cylinder')
    for i=0,11 do local d=dash(i,12,.05,.72)
        piece(rig,'JackpotSetting',accent,false,function(t)local c,sz=d(.7*W()*out(t/.25)+.01);return c,sz*Vector3.new(1,.06,.09),0 end,2)
    end
    for i=0,7 do local a=(i+.5)/8*TAU
        piece(rig,'JackpotStone',i%2==0 and white or trim,true,function(t)
            local g=out((t-.32)/.2);local w=.28*W()*g+.001
            return CFrame.Angles(0,a,0)*CFrame.new(0,.07,-1.32*W())*CFrame.Angles(0,math.pi/4,0),Vector3.new(w,.07,w),g<=0 and 1 or .05
        end,1)
        piece(rig,'JackpotRay',white,true,function(t,sec)
            local g=out((t-.35)/.3);local c,sz=seg(Vector3.new(0,.05,-.8*W()),Vector3.new(0,.05,-(.8+.95*g)*W()),.05,.025)
            return CFrame.Angles(0,i/8*TAU,0)*c,sz,g<=0 and 1 or(not rig.preview and math.sin(sec*11+i*2)>.5)and .6 or .12
        end,1)
    end
    piece(rig,'JackpotJet',trim,true,function(t)local h=JH()*out(t/.22)*(1-.75*ramp(t,.55,.9))+.001;return CFrame.new(0,h/2,0),Vector3.new(h,.3*W(),.3*W()),.55 end,0,1,'cylinder')
    for i=0,13 do local l=(i%7)*.035+(i>=7 and .08 or 0);local a=i*2.4;local peak=.6+.35*((i*5)%4)/3
        piece(rig,'JackpotGem',i%4==0 and accent or i%2==0 and white or trim,true,function(t)
            local u=rig.preview and .2+.6*((i*3)%7)/6 or ramp(t,l,l+.42);local y=.1+JH()*peak*4*u*(1-u);local r=(.15+1.17*u)*W()
            return CFrame.Angles(0,a,0)*CFrame.new(0,y,-r)*CFrame.Angles(.78+u*6,u*4,.78),Vector3.new(.15,.2,.15)*W(),(u<=0 or u>=1)and 1 or .05
        end,3)
    end
    local function gem(name,color,cf,size)
        return piece(rig,name,color,true,function(t,sec)
            local g=(.4+.6*out(t/.3))*W();local y=.4+(JH()-.35)*out(t/.3)*(1-.55*ramp(t,.55,.9))
            return CFrame.new(0,y,0)*CFrame.Angles(0,rig.preview and 0 or sec*2.6,0)*CFrame.new(cf.Position*g)*cf.Rotation,size*g,0
        end,2)
    end
    local top=gem('JackpotBrilliant',white,CFrame.new(0,-.12,0)*CFrame.Angles(math.pi/4,0,math.pi/4),Vector3.one*.34)
    gem('JackpotTable',trim,CFrame.new(0,.1,0)*CFrame.Angles(0,math.pi/4,0),Vector3.new(.5,.1,.5))
    for i=0,2 do local a=i/3*TAU+.5;local t0=.45+i*.12
        for b=0,1 do
            piece(rig,'JackpotTwinkle',white,true,function(t)
                local f=rig.preview and 1 or math.sin(ramp(t,t0,t0+.2)*math.pi);return CFrame.Angles(0,a,0)*CFrame.new(0,.3,-1.32*W())*CFrame.Angles(0,b*math.pi/2+math.pi/4,0),Vector3.new(.62*f+.001,.04,.04)*W(),f<=0 and 1 or .05
            end,1)
        end
    end
    rig.lightAt=top.part
end
themes.descent=function(rig,s)
    local trim,accent,base=rgb(s.secondary),rgb(s.accent),rgb(s.primary)
    rig.show=.7
    local function W()return rig.preview and 1 or 1.25 end
    local function SY()return rig.preview and 1.05 or 2.55 end
    local function pearl(c,sec,i)if rig.preview then return nil end;return c:Lerp(accent,.18+.16*math.sin(sec*3+i))end
    piece(rig,'SeraphPlate',base,false,function(t)local c,sz=disc(.6,.04,.02)();return c,sz*out(t/.12),.1 end,0,1,'cylinder')
    for i=0,11 do local a=i/12*TAU
        piece(rig,'SeraphCircle',i%2==0 and base or trim,true,function(t,sec)
            local g=out((t-.04)/.3);local c,sz=seg(Vector3.new(0,.05,-.55*W()),Vector3.new(.18*g,.05,-(.55+.7*g)*W()),.2*W(),.03)
            return CFrame.Angles(0,a,0)*c,sz,g<=0 and 1 or .12,i%2==0 and pearl(base,sec,i)or nil
        end,1)
    end
    piece(rig,'SeraphLight',trim,true,function(t)local h=SY()*1.6*out(t/.3)+.001;return CFrame.new(0,h/2,0),Vector3.new(h,.22*W(),.22*W()),.72 end,0,1,'cylinder')
    for kk=0,2 do local lift=({.12,.42,-.2})[kk+1];local span=({1,.86,.72})[kk+1];local sweep=({0,.32,-.28})[kk+1]
        for _,side in ipairs({-1,1})do
            for j=0,4 do
                piece(rig,'SeraphWing',j%2==0 and base or trim,true,function(t,sec)
                    local sp=out((t-.08-kk*.1)/.35);local fl=rig.preview and 0 or math.sin(sec*6+kk)*.12*sp
                    local th=.12+sp*(1.5-j*.2-sweep);local d=Vector3.new(side*math.sin(th),lift+fl,math.cos(th)).Unit
                    local S=Vector3.new(side*.14,SY()+kk*.06*(lift>0 and 1 or -1),.22)
                    local c,sz=seg(S,S+d*(1.3-.13*j)*span*W(),(.2-.02*j)*W(),.035,Vector3.yAxis)
                    return c,sz,sp<=0 and 1 or j==0 and .38 or .1+.05*j,pearl(j%2==0 and base or trim,sec,j+kk)
                end,1,kk+1)
            end
        end
    end
    for i=0,7 do
        piece(rig,'SeraphRay',trim,true,function(t)
            local g=out((t-.2)/.35);local c,sz=seg(Vector3.new(0,.05,-1.32*W()),Vector3.new(0,.05,-(1.32+.75*g)*W()),.05,.025)
            return CFrame.Angles(0,(i+.5)/8*TAU,0)*c,sz,g<=0 and 1 or .15
        end,2,2)
    end
    for i=0,5 do local a=i/6*TAU+.4
        piece(rig,'SeraphPlume',base,true,function(t,sec)
            local u=ramp(t,.2+(i%3)*.08,.95);local r=(.6+.8*u)*W()
            return CFrame.Angles(0,a+u*1.4,0)*CFrame.new(0,.1+SY()*(1-u),-r)*CFrame.Angles(.3,u*5,math.sin(u*9)*.5),Vector3.new(.08,.02,.28)*W(),u<=0 and 1 or .1+.6*ramp(t,.75,1),pearl(base,sec,i)
        end,2,2)
    end
    for i=0,11 do local d=dash(i,12,0,.66)
        piece(rig,'SeraphHalo',accent,true,function(t,sec)
            local u=rig.preview and .55 or out(ramp(t,.28,.78));local y=(SY()*2.2+.3)*(1-u)+.08;local c,sz=d((.55+1.0*u)*W())
            return CFrame.new(0,y,0)*c,sz*Vector3.new(1,.07,.11)*(1+.3*u),.05,not rig.preview and Color3.fromHSV(.865+.045*math.sin(sec*3+i*.52),.48,1)or nil
        end,2,3)
    end
    rig.lightAt=rig.items[14].part
end
themes.hack=function(rig,s)
    local trim,accent,base=rgb(s.secondary),rgb(s.accent),rgb(s.primary)
    local pale=Color3.fromRGB(224,252,255)
    rig.show=.7
    local function W()return rig.preview and 1 or 1.3 end
    local function TZ()return rig.preview and -1.5 or -2 end
    local function HY()return rig.preview and .9 or 1.9 end
    local function ring(i)return CFrame.Angles(0,i/16*TAU,0)*CFrame.new(0,.08,-1.35*W())end
    piece(rig,'HackPlate',base,false,function(t)local c,sz=disc(.72,.04,.02)();return c,sz*out(t/.12),.08 end,0,1,'cylinder')
    for i=0,15 do
        piece(rig,'HackPixel',i%2==0 and trim or accent,true,function(t,sec)
            local on=t>i/16*.18;local j=not rig.preview and (math.floor(sec*12)+i*7)%9==0 and .14 or 0
            return ring(i)*CFrame.new(j,0,-j),Vector3.new(.17,.06,.17)*W(),on and .05 or 1
        end,1)
    end
    for i=0,3 do
        piece(rig,'HackScan',trim,true,function(t,sec)
            local z=rig.preview and(i-1.5)*.32 or((sec*1.6+i*.25)%1)*2.6-1.3;local hide=not rig.preview and (math.floor(sec*20)+i)%4==0
            return CFrame.new(0,.07,z*W()),Vector3.new(1.3*W(),.02,.035),(hide or t<.05)and 1 or .45
        end,1)
    end
    local rows={'X','XX','XXX','XXXX','XXXXX','XXX','..XX','..XX'};local cells={}
    for r,row in ipairs(rows)do for c=1,#row do if row:sub(c,c)=='X'then table.insert(cells,{c-1,r-1,c==1 or c==#row})end end end
    local cell=.17
    local function at(t,n,i)
        local l=.08+(i%11)*.022;local u=ramp(t,l,l+.3);if not rig.preview then u=math.floor(u*6+.5)/6 end
        local press=ramp(t,.56,.6)*(1-ramp(t,.64,.72));local y=HY()-(HY()-.18)*press
        local goal=Vector3.new((n[1]-.8)*cell*W(),y,TZ()+(n[2]*cell+.06)*W())
        return ring(i%16).Position:Lerp(goal,u),u,press
    end
    for i,n in ipairs(cells)do
        piece(rig,'HackCursor',n[3] and pale or trim,true,function(t)
            local p,u,press=at(t,n,i);return CFrame.new(p),Vector3.new(cell*.92,.07,cell*.92)*W()*(1-.12*press),(t<.08)and 1 or u<1 and .3 or .02
        end,1)
    end
    for e=0,3 do
        piece(rig,'HackClick',accent,true,function(t)
            local g=ramp(t,.6,.95);local h=(.2+.75*out(g))*W()
            return CFrame.new(0,.07,TZ())*CFrame.Angles(0,e*math.pi/2,0)*CFrame.new(0,0,-h),Vector3.new(2*h,.04,.05),g<=0 and 1 or .05+.85*g^2
        end,1)
    end
    for q=0,7 do local n=cells[q*3+1]
        piece(rig,'HackSplit',accent,true,function(t,sec)
            local p,u=at(t,n,q*3+1);local f=not rig.preview and (math.floor(sec*15)+q)%3==0
            return CFrame.new(p+Vector3.new(.07,.02,.05)*W()),Vector3.new(cell*.92,.05,cell*.92)*W(),(t<.08 or f)and 1 or u<1 and .55 or .35
        end,2,2)
    end
    for e=0,7 do local top=e>=4
        piece(rig,'HackWire',trim,true,function(t,sec)
            local g=out((t-.12)/.3);local h=(top and .7 or 1.05)*W()*g+.001;local y=top and(rig.preview and 1.5 or 3.4)or .06
            return CFrame.new(0,y,0)*CFrame.Angles(0,e*math.pi/2+(rig.preview and 0 or sec*.9)*(top and -1 or 1),0)*CFrame.new(0,0,-h),Vector3.new(2*h,.035,.035),g<=0 and 1 or .2
        end,2,3)
    end
    for i=0,7 do local a=(i%4+.5)/4*TAU;local R=(i<4 and 1.05 or .7)*1.414
        piece(rig,'HackCode',i%2==0 and trim or accent,true,function(t,sec)
            local H=rig.preview and 1.5 or 3.4;local f=rig.preview and (i*.37)%1 or(sec*1.8+i*.37)%1
            return CFrame.Angles(0,a,0)*CFrame.new(0,H*(1-f)+.1,-R*W()*(1-.25*(1-f))),Vector3.new(.09,.3,.09)*W(),t<.15 and 1 or .2
        end,2,3)
    end
    rig.lightAt=rig.items[22].part
end
themes.summon=function(rig,s)
    local trim,accent,base=rgb(s.secondary),rgb(s.accent),rgb(s.primary)
    local skin=base:Lerp(trim,.32);local iris=Color3.fromHSV(.78,.5,1)
    rig.show=.6
    local function W()return rig.preview and 1 or 1.3 end
    local water=piece(rig,'AbyssWater',base,false,function(t)local c,sz=disc(.95,.04,.02)();return c,sz*W()*out(t/.15),.12 end,0,1,'cylinder')
    water.part.Material=Enum.Material.Glass;water.part.Reflectance=.25
    for i=0,9 do local d=dash(i,10,.05,.6)
        piece(rig,'AbyssRipple',trim,true,function(t)
            local u=rig.preview and .55 or(t*1.6)%1;local c,sz=d((.5+1.4*u)*W());return c,sz*Vector3.new(1,.04,.07),.1+.85*u^2
        end,2)
    end
    for _,x in ipairs({-1,1})do
        piece(rig,'AbyssEye',trim,true,function(t,sec)
            local o=rig.preview and 1 or math.abs(math.sin(sec*2.3))>.15 and 1 or .15
            return CFrame.new(x*.24*W(),.035,-.95*W())*CFrame.Angles(0,x*.25,0),Vector3.new(.26,.05,.13*o)*W()*out(t/.2)+Vector3.one*.001,.3
        end,1,1,'round')
        piece(rig,'AbyssPupil',accent,true,function(t)return CFrame.new(x*.24*W(),.06,-.95*W()),Vector3.new(.035,.05,.1)*W()*out(t/.2)+Vector3.one*.001,.1 end,1)
    end
    local function pts(i,t,sec)
        local h=out(ramp(t,.1+(i%4)*.04,.5))*(1-out(ramp(t,.72,.97)));local L=(rig.preview and .75 or 1.7)*h
        local p=Vector3.zero;local list={p}
        for kk=0,3 do
            local th=.1+kk*.32+(rig.preview and 0 or math.sin(sec*3.2+i+kk*.8)*.18)
            p=p+Vector3.new(rig.preview and 0 or math.sin(sec*2+i)*.06,math.cos(th),-math.sin(th))*(.42-.07*kk)*L;table.insert(list,p)
        end
        return CFrame.Angles(0,(i+.5)/8*TAU,0)*CFrame.new(0,.03,-1.25*W()),list,h
    end
    for i=0,7 do local ph=i%2==0 and 1 or 2
        for kk=0,3 do
            piece(rig,'AbyssTentacle',kk%2==0 and skin or trim,kk%2==1,function(t,sec)
                local f,list,h=pts(i,t,sec);if h<.02 then return f,Vector3.one*.001,1 end
                local c,sz=seg(list[kk+1],list[kk+2],(.28-.05*kk)*W(),(.24-.045*kk)*W());return f*c,sz*Vector3.new(1,1,1.3),.05
            end,1,ph,'round')
        end
        piece(rig,'AbyssTip',i%2==0 and trim or accent,true,function(t,sec)
            local f,list,h=pts(i,t,sec);return f*CFrame.new(list[5]),Vector3.one*(.13*W()*(rig.preview and 1 or 1+.3*math.sin(sec*8+i))),h<.05 and 1 or .05
        end,1,ph,'ball')
    end
    for side=0,1 do for j=0,3 do
        piece(rig,'AbyssLid',trim,true,function(t)
            local o=out(ramp(t,.32,.58));local x0,x1=-1.9+j*.95,-1.9+(j+1)*.95
            local function z(x)return(side==0 and -1 or 1)*.85*o*(1-(x/1.9)^2)end
            local c,sz=seg(Vector3.new(x0*W(),.06,z(x0)*W()),Vector3.new(x1*W(),.06,z(x1)*W()),.07,.04)
            return c,sz,o<=0 and 1 or .08
        end,1,3)
    end end
    for i=0,7 do local d=dash(i,8,.07,.7)
        piece(rig,'AbyssIris',iris,true,function(t,sec)
            local o=out(ramp(t,.4,.62));local c,sz=d(.72*W()*o+.01)
            return c,sz*Vector3.new(1,.05,.12),o<=0 and 1 or .05,not rig.preview and Color3.fromHSV(.8+.06*math.sin(sec*2.5+i*.8),.5,1)or nil
        end,2,3)
    end
    rig.lightAt=water.part
end
end
