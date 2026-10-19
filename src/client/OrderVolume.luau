local TAU=math.pi*2
local function ramp(t,a,b)return math.clamp((t-a)/(b-a),0,1)end
local function seg(a,b,w,d,up)
    local v=b-a;local len=v.Magnitude
    if len<1e-4 then return CFrame.new(a),Vector3.new(w,d,.001)end
    up=up or (math.abs(v.Y/len)>.98 and Vector3.xAxis or Vector3.yAxis)
    return CFrame.lookAt((a+b)/2,b,up),Vector3.new(w,d,len)
end
return function(themes,k)
local piece,disc,dash,out,rgb,cool=k.piece,k.disc,k.dash,k.out,k.rgb,k.cool
themes.toxic=function(rig,s)
    local trim,accent,base=rgb(s.secondary),rgb(s.accent),rgb(s.primary)
    local pale=Color3.fromRGB(226,255,196);local murk=accent:Lerp(base,.3)
    rig.show=.46
    piece(rig,'ToxicPlate',base,false,function(t)local c,sz=disc(.52,.04,.02)();return c,sz*out(t/.12),.15 end,0,1,'cylinder')
    piece(rig,'ToxicHub',pale,true,function(t)local c,sz=disc(.07,.05,.05)();return c,sz*out(t/.15),.05 end,0,1,'cylinder')
    for i=0,2 do
        piece(rig,'ToxicTrefoil',accent,true,function(t)return CFrame.Angles(0,i/3*TAU,0)*CFrame.new(0,.05,-.26),Vector3.new(.24,.03,.22)*out(t/.2),.1 end,1)
    end
    for _,b in ipairs({{.62,.3,.24},{1.4,.78,.18},{2.3,.52,.28},{3.1,.86,.16},{3.9,.62,.22},{4.8,.84,.18},{5.6,.46,.2}})do
        piece(rig,'ToxicPuddle',murk,true,function(t)local d=b[3]*2*out((t-.05)/.25)+.001;return CFrame.Angles(0,b[1],0)*CFrame.new(0,.03,-b[2]),Vector3.new(.03,d,d),.22 end,0,1,'cylinder')
    end
    for i=0,11 do
        local a=i*2.4;local r=.42+.5*((i*7)%12)/12;local sz=.16+.14*((i*5)%7)/6;local pop=.55+.4*((i*3)%5)/4;local rise=.25+.5*((i*11)%6)/5
        piece(rig,'ToxicBubble',i%3==0 and pale or i%3==1 and accent or trim,true,function(t,sec)
            local g=out(t/(pop*.6));local burst=t>pop and math.min(1,(t-pop)/.08)or 0
            local y=.12+sz*.5+rise*t+(rig.preview and 0 or math.sin(sec*9+i)*.03)
            return CFrame.Angles(0,a,0)*CFrame.new(0,y,-(rig.preview and r or r+.38)),Vector3.one*(sz*g*(1+.6*burst)+.001),burst>=1 and 1 or .18+.6*burst
        end,3,1,'ball')
    end
    for i=0,7 do local a=i/8*TAU+.2;local h=.45+.2*(i%2)
        local function at(t,y)local H=h*math.sin(ramp(t,.08,.75)*math.pi);local R=(rig.preview and .7 or .95)+.45*out(t/.5)
            return CFrame.Angles(0,a,0)*CFrame.new(0,0,-R)*CFrame.Angles(-.35,0,0)*CFrame.new(0,y(H),0),H
        end
        piece(rig,'ToxicSplash',accent,true,function(t)local c,H=at(t,function(H)return H/2 end);return c,Vector3.new(.12,H+.001,.12),H<.02 and 1 or .1 end,1,1,'round')
        piece(rig,'ToxicDrop',pale,true,function(t)local c,H=at(t,function(H)return H+.06 end);return c,Vector3.one*.13,H<.02 and 1 or .05 end,1,1,'ball')
    end
end
themes.tide=function(rig,s)
    local trim,accent,base=rgb(s.secondary),rgb(s.accent),rgb(s.primary)
    local foam=Color3.fromRGB(236,252,255);local deep=accent:Lerp(base,.35)
    rig.show=.5
    local function H(t)return(rig.preview and 1.45 or 3.4)*out(t/.4)end
    piece(rig,'TidePlate',base,false,function(t)local c,sz=disc(.5,.04,.02)();return c,sz*out(t/.12),.15 end,0,1,'cylinder')
    for i=0,7 do local f=i/7
        piece(rig,'TideSpout',i%2==0 and accent or trim:Lerp(accent,.5),true,function(t,sec)
            local h=H(t);local a=f*TAU*1.25+(rig.preview and 0 or sec*4)
            return CFrame.Angles(0,a,0)*CFrame.new(0,.12+h*f*.92,-(.5-.14*f))*CFrame.Angles(0,0,.6),Vector3.new(.28,h/3+.06,.07),.18
        end,1)
    end
    for i=0,5 do local a=i/6*TAU+.4
        local function ends(t)local h=H(t)+.1;local k2=out((t-.15)/.4)
            return Vector3.new(0,h+.3*k2,-.3-.3*k2),Vector3.new(0,h+.22*k2-.6*k2*k2,-.32-.62*k2),k2
        end
        piece(rig,'TideSpray',trim,true,function(t)local p0,p1,k2=ends(t);local c,sz=seg(p0,p1,.09,.09);return CFrame.Angles(0,a,0)*c,sz,k2<=0 and 1 or .3 end,2,1,'round')
        piece(rig,'TideFoam',foam,true,function(t)local _,p1,k2=ends(t);return CFrame.Angles(0,a,0)*CFrame.new(p1),Vector3.one*(.15*k2+.001),k2<=0 and 1 or .05 end,2,1,'ball')
    end
    for i=0,9 do local a=i/10*TAU
        local function wall(t)local R=.75+.6*out(t/.55);return R,(.42+.08*math.sin(i*1.7))*out(t/.3)*(1-.35*ramp(t,.6,1))end
        piece(rig,'TideWave',i%2==0 and accent or deep,true,function(t)local R,h=wall(t)
            return CFrame.Angles(0,a,0)*CFrame.new(0,0,-R)*CFrame.Angles(-.55,0,0)*CFrame.new(0,h/2,0),Vector3.new(TAU*R/10*.94,h+.001,.1),.12
        end,1)
        piece(rig,'TideCap',foam,true,function(t)local R,h=wall(t)
            return CFrame.Angles(0,a,0)*CFrame.new(0,0,-R)*CFrame.Angles(-.55,0,0)*CFrame.new(0,h+.02,-.05),Vector3.new(TAU*R/10*.9,.07,.15),h<.02 and 1 or .05
        end,1)
    end
end
themes.flare=function(rig,s)
    local trim,accent,base=rgb(s.secondary),rgb(s.accent),rgb(s.primary)
    local core=Color3.fromRGB(255,236,170);local deep=Color3.fromRGB(255,176,52)
    rig.show=.5
    piece(rig,'FlarePlate',base,false,function(t)local c,sz=disc(.72,.04,.02)();return c,sz*out(t/.12),.05 end,0,1,'cylinder')
    for i=0,5 do local a=i/6*TAU+.3;local x=i%2==0 and .13 or -.13
        local path={Vector3.new(0,.05,-.3),Vector3.new(x,.05,-.55),Vector3.new(-x*.4,.05,-.8)}
        for j=1,2 do
            piece(rig,'FlareCrack',j==1 and core or accent,true,function(t)
                local w=rig.preview and 1 or 1.4;local g=out((t-(j-1)*.1)/.2);local c,sz=seg(path[j]*w,(path[j]:Lerp(path[j+1],g))*w,.045,.025);return CFrame.Angles(0,a,0)*c,sz,g<=0 and 1 or .05
            end)
        end
    end
    local function FH()return rig.preview and 1.3 or 2.6 end
    for i=0,11 do local inner=i>=8;local a=inner and (i-8)/4*TAU+.4 or i/8*TAU
        piece(rig,'FlareTongue',inner and core or i%2==0 and accent or deep,true,function(t,sec)
            local h=FH()*(inner and .62 or .75+.25*((i*3)%4)/3)*out(t/.3)*(rig.preview and 1 or 1+.18*math.sin(sec*14+i*1.3))
            return CFrame.Angles(0,a,0)*CFrame.new(0,.05,(inner and -.24 or -.42)-(rig.preview and 0 or .4))*CFrame.Angles(inner and .1 or .2,0,0)*CFrame.new(0,h/2,0),Vector3.new(inner and .18 or .21,h+.001,inner and .15 or .17),inner and .05 or .12
        end,3,1,'round')
    end
    for i=0,11 do local a0=i*2.4;local sp=.6+.4*((i*7)%5)/4
        piece(rig,'FlareEmber',i%3==0 and core or trim,true,function(t)
            local u=math.clamp(t*sp*1.3-(i%4)*.05,0,1);local a=a0+u*2.2
            return CFrame.Angles(0,a,0)*CFrame.new(0,.2+(rig.preview and 1.5 or 3.2)*u,-((rig.preview and .4 or .8)+.6*u))*CFrame.Angles(u*5,u*4,0),Vector3.one*(.1*(1-u*.5)),u<=0 and 1 or .05+.6*u^2
        end,3)
    end
end
themes.strike=function(rig,s)
    local trim,accent,base=rgb(s.secondary),rgb(s.accent),rgb(s.primary)
    local white=Color3.fromRGB(242,247,255);local cloud=Color3.fromRGB(64,74,104)
    rig.show=.42
    local function TZ()return rig.preview and -1.7 or -2.3 end
    local function CY()return rig.preview and 2.3 or 5.2 end
    piece(rig,'StrikePlate',base,false,function(t)local c,sz=disc(.45,.04,.02)();return c,sz*out(t/.12),.15 end,0,1,'cylinder')
    for i=0,7 do
        piece(rig,'StrikeArc',i%2==0 and white or accent,true,function(t,sec)
            local fl=rig.preview and 0 or((math.floor(sec*30)+i)%3==0 and .8 or 0)
            return CFrame.Angles(0,i/8*TAU,0)*CFrame.new(0,.14,-.56)*CFrame.Angles(0,0,i%2==0 and .55 or -.55),Vector3.new(.5,.05,.05)*out(t/.15),.05+fl
        end,1)
    end
    for _,p in ipairs({{0,0,0,.72},{.4,-.06,.1,.5},{-.38,-.04,-.08,.56},{.12,.12,-.3,.46},{-.12,.1,.3,.5}})do
        piece(rig,'StrikeCloud',cloud,false,function(t)return CFrame.new(p[1],CY()+p[2],TZ()+p[3]),Vector3.new(p[4]*1.5,p[4]*.7,p[4]*1.2)*out(t/.2)+Vector3.one*.001,.08 end,0,1,'round')
    end
    local zig={{0,0},{.24,.08},{-.14,-.06},{.2,.1},{-.16,0},{.07,-.05},{0,0}}
    local function node(j)local z=zig[j];return Vector3.new(z[1],(CY()-.25)*(1-(j-1)/6)+.04,TZ()+z[2])end
    local function lit(t,sec,j)
        if t<.1 or t>.66 or j>ramp(t,.1,.2)*6+.999 then return 1 end
        return(not rig.preview and math.floor(sec*24)%4==3)and .7 or 0
    end
    for j=1,6 do
        piece(rig,'StrikeBolt',white,true,function(t,sec)local c,sz=seg(node(j),node(j+1),.09,.09);return c,sz,lit(t,sec,j)end)
        piece(rig,'StrikeGlow',accent,true,function(t,sec)local c,sz=seg(node(j),node(j+1),.22,.22);return c,sz,math.max(.6,lit(t,sec,j))end)
    end
    for _,f in ipairs({{3,Vector3.new(.45,-.35,.1),Vector3.new(.64,-.78,-.05)},{4,Vector3.new(-.42,-.3,-.12),Vector3.new(-.56,-.64,.08)}})do
        for j=1,2 do
            piece(rig,'StrikeFork',accent,true,function(t,sec)
                local o=node(f[1]);local c,sz=seg(j==1 and o or o+f[2],j==1 and o+f[2] or o+f[3],.06,.06);return c,sz,lit(t,sec,f[1]+1)
            end)
        end
    end
    piece(rig,'StrikeScorch',base:Lerp(Color3.new(),.5),false,function(t)local d=.95*out((t-.12)/.15)+.001;return CFrame.new(0,.03,TZ()),Vector3.new(.03,d,d),.1 end,0,1,'cylinder')
    piece(rig,'StrikeFlash',white,true,function(t)local f=ramp(t,.12,.2)*(1-.6*ramp(t,.3,.7));return CFrame.new(0,.15,TZ()),Vector3.one*(.5*f+.001),t<.12 and 1 or .1+.5*ramp(t,.4,.9)end,0,1,'ball')
    for i=0,7 do local a=i/8*TAU+.2
        piece(rig,'StrikeSpark',i%2==0 and white or accent,true,function(t)
            local g=out((t-.14)/.3);local r0=.2+.25*g;local c,sz=seg(Vector3.new(0,.06,-r0),Vector3.new(0,.1+.12*g,-(r0+.25+.35*g*(i%2==0 and 1 or .6))),.05,.04)
            return CFrame.new(0,0,TZ())*CFrame.Angles(0,a,0)*c,sz,g<=0 and 1 or .05+.7*ramp(t,.5,1)
        end)
    end
end
themes.coronation=function(rig,s)
    local trim,accent,base=rgb(s.secondary),rgb(s.accent),rgb(s.primary)
    local white=Color3.fromRGB(255,248,226);local navy=base:Lerp(Color3.fromRGB(84,104,230),.8);local jewel=Color3.fromRGB(96,128,255)
    rig.show=.75
    piece(rig,'CoronaPlate',base,false,function(t)local c,sz=disc(.66,.04,.02)();return c,sz*out(t/.12),.05 end,0,1,'cylinder')
    for i=0,9 do local d=dash(i,10,.05,.7)
        piece(rig,'CoronaTrim',accent,true,function(t)local c,sz=d(.76*out(t/.3)+.01);return c,sz*Vector3.new(1,.05,.08),.1 end,2)
    end
    local function CH(t)local q=out(t/.5);return rig.preview and 2.75-1.2*q or 7.6-2.9*q end
    local function g0()return rig.preview and 1 or 1.45 end
    piece(rig,'CoronaBeam',accent,true,function(t)local h=CH(t);return CFrame.new(0,h/2,0),Vector3.new(h,.42*g0(),.42*g0()),rig.preview and .78 or .86 end,0,1,'cylinder')
    local function PH()return rig.preview and 1.25 or 2.6 end;local function BR()return rig.preview and .98 or 1.4 end;local function fw()return rig.preview and 1 or 1.4 end
    for i=0,3 do local a=(i+.5)/4*TAU
        local function frame(t)return CFrame.Angles(0,a,0)*CFrame.new(0,0,-BR()),PH()*out(t/.3)end
        piece(rig,'CoronaPole',trim,false,function(t)local f,h=frame(t);return f*CFrame.new(0,h/2,0),Vector3.new(.06,h+.001,.06),0 end)
        piece(rig,'CoronaFinial',accent,true,function(t)local f,h=frame(t);return f*CFrame.new(0,h+.05,0),Vector3.one*.15,h<.05 and 1 or 0 end,0,1,'ball')
        for j=0,1 do
            piece(rig,j==0 and 'CoronaFlag'or'CoronaHem',j==0 and navy or accent,j==1,function(t,sec)
                local f,h=frame(t);local w=.55*fw()*out((t-.22)/.35)+.001;local wave=rig.preview and .25 or .25+math.sin(sec*6+i)*.25
                return f*CFrame.new(0,h-(j==0 and .3 or .52)*fw(),0)*CFrame.Angles(0,wave,0)*CFrame.new(w/2+.03,0,0),Vector3.new(w,(j==0 and .46 or .08)*fw(),j==0 and .03 or .05),w<.02 and 1 or 0
            end)
        end
    end
    local function crown(name,color,glow,cf,size,shape)
        piece(rig,name,color,glow,function(t,sec)
            local g=(.55+.45*out(t/.4))*g0();local spin=rig.preview and 0 or sec*1.4
            return CFrame.new(0,CH(t),0)*CFrame.Angles(0,spin,0)*CFrame.new(cf.Position*g)*cf.Rotation,size*g,0
        end,2,1,shape)
    end
    for i=0,7 do local a=i/8*TAU;local tall=i%2==0
        crown('CoronaBand',accent,false,CFrame.Angles(0,a,0)*CFrame.new(0,0,-.36),Vector3.new(.3,.17,.06))
        crown('CoronaPoint',accent,false,CFrame.Angles(0,a,0)*CFrame.new(0,.08+(tall and .18 or .11),-.37)*CFrame.Angles(-.15,0,0)*CFrame.Angles(0,0,math.pi/4),Vector3.new(tall and .2 or .15,tall and .2 or .15,.05))
        if tall then crown('CoronaTip',white,true,CFrame.Angles(0,a,0)*CFrame.new(0,.36,-.4),Vector3.one*.12,'ball')
        else crown('CoronaJewel',jewel,true,CFrame.Angles(0,a,0)*CFrame.new(0,0,-.4),Vector3.new(.1,.1,.04))end
    end
    crown('CoronaOrb',white,true,CFrame.new(0,.12,0),Vector3.one*.26,'ball')
    rig.lightAt=rig.items[#rig.items].part
end
themes.rise=function(rig,s)
    local trim,accent,base=rgb(s.secondary),rgb(s.accent),rgb(s.primary)
    local core=Color3.fromRGB(255,244,206);local flame=Color3.fromRGB(255,150,40)
    rig.show=.72
    local function PH(t)return rig.preview and .35+1.5*out(t/.45)or .4+4.2*out(t/.45)end
    local function g1()return rig.preview and 1 or 1.9 end
    piece(rig,'PhoenixPlate',base,false,function(t)local c,sz=disc(.6,.04,.02)();return c,sz*out(t/.12),.05 end,0,1,'cylinder')
    for i=0,9 do
        piece(rig,'PhoenixFlame',i%2==0 and accent or flame,true,function(t,sec)
            local h=(rig.preview and .42 or .75)*out(t/.25)*(1-.5*ramp(t,.55,1))*(rig.preview and 1 or 1+.2*math.sin(sec*13+i))
            return CFrame.Angles(0,i/10*TAU,0)*CFrame.new(0,.04,rig.preview and -.72 or -1)*CFrame.Angles(-.3,0,0)*CFrame.new(0,h/2,0),Vector3.new(.26,h+.001,.2),.12
        end,1,1,'round')
    end
    piece(rig,'PhoenixColumn',accent,true,function(t)local h=PH(t);return CFrame.new(0,h/2,0),Vector3.new(h,.42*g1(),.42*g1()),rig.preview and .78 or .86 end,0,1,'cylinder')
    local function bird(name,color,f,shape)
        piece(rig,name,color,true,function(t,sec)
            local sp=out((t-.18)/.4);local fl=rig.preview and 0 or math.sin(sec*7)*.25*sp
            local cf,size=f(t,sec,sp,fl);local g=(.6+.4*out(t/.3))*g1()
            return CFrame.new(0,PH(t),0)*CFrame.new(cf.Position*g)*cf.Rotation,size*g,0
        end,2,1,shape)
    end
    bird('PhoenixBody',accent,function()return CFrame.Angles(-.25,0,0),Vector3.new(.28,.56,.3)end,'round')
    bird('PhoenixHeart',core,function()return CFrame.new(0,.02,-.1),Vector3.one*.18 end,'ball')
    bird('PhoenixHead',trim,function()return CFrame.new(0,.36,-.14),Vector3.one*.2 end,'ball')
    bird('PhoenixBeak',core,function()return CFrame.new(0,.33,-.28)*CFrame.Angles(-.3,0,0),Vector3.new(.06,.06,.16)end)
    for c=-1,1 do bird('PhoenixCrest',c==0 and core or accent,function()return seg(Vector3.new(c*.03,.42,-.12),Vector3.new(c*.1,.74-math.abs(c)*.08,.14),.05,.02)end)end
    for _,side in ipairs({-1,1})do
        local S=Vector3.new(side*.12,.12,.02);local up=Vector3.new(0,-.6,-.8)
        for j=0,6 do
            bird('PhoenixFeather',flame:Lerp(trim,j/6),function(_,_,sp,fl)
                local phi=(-1.35+j*.06)+((.05+j*.2)-(-1.35+j*.06))*sp+fl
                local d=Vector3.new(side*math.cos(phi),math.sin(phi),.18).Unit
                return seg(S,S+d*(.95-j*.07),.11,.03,up)
            end)
        end
        for j=0,1 do
            bird('PhoenixCovert',core,function(_,_,sp,fl)
                local phi=-1.2+(1.8+j*.45)*sp*(.55+j*.25)+fl;local d=Vector3.new(side*math.cos(phi),math.sin(phi),.12).Unit
                return seg(S,S+d*(.42-j*.06),.2,.04,up)
            end)
        end
    end
    for k2=0,4 do
        bird('PhoenixTail',k2%2==0 and accent or flame,function(_,sec)
            local sw=rig.preview and 0 or math.sin(sec*5+k2)*.12
            local d=Vector3.new((k2-2)*.28+sw,-1,.55).Unit;local T=Vector3.new(0,-.22,.1)
            return seg(T,T+d*(.75+.15*(2-math.abs(k2-2))),.08,.03,Vector3.new(0,0,-1))
        end)
    end
    for i=0,5 do
        piece(rig,'PhoenixEmber',i%2==0 and core or trim,true,function(t)
            local a=i/6*TAU+t*3;local y=PH(t)*(.2+.55*((i*.37)%1));local r=(rig.preview and .38 or .8)+.2*((i*.61)%1)
            return CFrame.Angles(0,a,0)*CFrame.new(0,y,-r)*CFrame.Angles(t*4,i,0),Vector3.one*.09,.05+.5*ramp(t,.6,1)
        end,3)
    end
    rig.lightAt=rig.items[14].part
end
themes.totality=function(rig,s)
    local trim,accent,base=rgb(s.secondary),rgb(s.accent),rgb(s.primary)
    local white=Color3.fromRGB(246,244,255)
    local function top(t)return rig.preview and .3+2.0*out(t/.4)or .4+4.2*out(t/.4)end
    local function g2()return rig.preview and 1 or 1.35 end
    piece(rig,'EclipseUmbra',base,false,function(t)local d=(rig.preview and 3.2 or 4.4)*out(t/.35)+.001;return CFrame.new(0,.02,0),Vector3.new(.03,d,d),.22 end,0,1,'cylinder')
    for i=0,11 do local d=dash(i,12,.05,.6)
        piece(rig,'EclipsePenumbra',trim:Lerp(accent,(i%2)*.6),true,function(t,sec)
            local c,sz=d((rig.preview and 1.72 or 2.3)*out(t/.35)+.01);return c,sz*Vector3.new(1,.06,.1),.05,not rig.preview and cool(i/12-sec*.3,.4)or nil
        end,1)
    end
    for i=0,5 do local a=i/6*TAU+TAU/12
        piece(rig,'EclipseRay',cool(i/6),true,function(t,sec)
            local g=out((t-.25)/.35);local c,sz=seg(Vector3.new(0,.05,-.45),Vector3.new(0,.05,-(.45+1.2*g)),.06,.03)
            return CFrame.Angles(0,a,0)*c,sz,g<=0 and 1 or .1,not rig.preview and cool(i/6+sec*.4)or nil
        end,4,3)
    end
    piece(rig,'EclipseBeam',accent,true,function(t)local h=top(t);return CFrame.new(0,h/2,0),Vector3.new(h,.14*g2(),.14*g2()),.65 end,0,1,'cylinder')
    local function sun(name,color,glow,f,mode,phase,shape)
        return piece(rig,name,color,glow,function(t,sec)
            local g=(.45+.55*out(t/.35))*g2();local cf,size,tr,col=f(t,sec)
            return CFrame.new(0,top(t),0)*CFrame.Angles(0,rig.preview and 0 or sec*.6,0)*CFrame.new(cf.Position*g)*cf.Rotation,size*g,tr or 0,col
        end,mode or 2,phase or 1,shape)
    end
    local disk=sun('EclipseSun',Color3.fromRGB(6,6,12),false,function()return CFrame.identity,Vector3.one*1.05 end,2,1,'ball')
    disk.part.Material=Enum.Material.Glass;disk.part.Reflectance=.3
    for i=0,11 do local d=dash(i,12,0,.86)
        sun('EclipseRim',white,true,function()local c,sz=d(.58);return CFrame.Angles(.15,0,0)*c,sz*Vector3.new(1,.1,.08)end)
    end
    for i=0,9 do local a=i/10*TAU;local d=Vector3.new(math.cos(a),({.28,-.16,.06})[i%3+1],math.sin(a)).Unit
        sun('EclipseCorona',white:Lerp(accent,(i%2)*.35),true,function()return seg(d*.6,d*(1+.18*(i%3)),.08,.05)end)
    end
    for i=0,5 do local a=(i+.5)/6*TAU;local d=Vector3.new(math.cos(a),(i%2==0 and .22 or -.12),math.sin(a)).Unit
        sun('EclipseStreamer',accent,true,function(t,sec)
            local c,sz=seg(d*.6,d*(1.5+.25*(i%2)),.05,.05);return c,sz,.15,not rig.preview and cool(i/6+sec*.35,.55)or nil
        end,2,2)
    end
    local rim=Vector3.new(.55,.45,-.7).Unit*.55
    sun('EclipseDiamond',white,true,function()return CFrame.new(rim),Vector3.one*.24 end,2,1,'ball')
    for j=0,1 do sun('EclipseFlare',white,true,function()return CFrame.new(rim)*CFrame.Angles(0,.6,j*math.pi/2),Vector3.new(1,.035,.035),.1 end)end
    for i=0,5 do
        sun('EclipseGlint',i%2==0 and cool(0,.6) or cool(.5,.55),true,function(t,sec)
            local a=i/6*TAU+(rig.preview and 0 or sec*1.2)
            return CFrame.Angles(0,a,0)*CFrame.new(0,math.sin(i*2.1)*.3,-1.25)*CFrame.Angles(0,math.pi/4,.3),Vector3.new(.11,.32,.11),.05,not rig.preview and cool(i/6+sec*.5)or nil
        end,2,2)
    end
    for i=0,7 do local d=dash(i,8,0,.55)
        sun('EclipseHalo',trim:Lerp(accent,.35),true,function(t,sec)
            local c,sz=d(1.7*out((t-.2)/.3)+.01);return CFrame.Angles(.3,0,0)*c,sz*Vector3.new(1,.07,.1),.05,not rig.preview and cool(i/8-sec*.5,.3)or nil
        end,2,3)
    end
    rig.lightAt=rig.items[#rig.items-16].part
end
end
