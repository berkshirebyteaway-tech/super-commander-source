local M={}
local floor,sin,cos,pi,sqrt,abs,max,min=math.floor,math.sin,math.cos,math.pi,math.sqrt,math.abs,math.max,math.min
local function wrap(d,P)return (d+P/2)%P-P/2 end
function M.install(build,ink,kit)
    local hash,noise,tex,put,bayer=kit.hash,kit.noise,kit.tex,kit.put,kit.bayer
    function build.ripple()
        local P=64;local t=tex(P,P);local pools={}
        for j=0,1 do for i=0,1 do
            table.insert(pools,{x=i*32+7+floor(hash(i,j,201)*18),y=j*32+7+floor(hash(i,j,202)*18),r=3.6+hash(i,j,203)*2.6})
        end end
        for y=0,P-1 do for x=0,P-1 do
            local code,ring=0,9;local near=1e9
            for _,p in ipairs(pools)do
                local dx,dy=wrap(x+.5-p.x,P),wrap(y+.5-p.y,P);local d=sqrt(dx*dx+dy*dy);near=min(near,d-p.r)
                if d<p.r-1.1 then code=(dx+p.r*.38)^2+(dy+p.r*.38)^2<1.6 and 8 or 1
                elseif d<p.r+.25 then code=2 end
                for k=1,3 do if abs(d-(p.r+2.4*k))<.6 then ring=min(ring,k)end end
            end
            if code==0 then
                if ring<9 then code=ring+2
                elseif near<7 and hash(x,y,205)<.05 then code=6
                elseif noise(x,y,16,P,207)>.6 and bayer[(y%4)*4+x%4+1]<10 then code=7 end
            end
            put(t,x,y,code)
        end end
        return t
    end
    function build.waves()
        local W,H=64,24;local t=tex(W,H)
        local function crest(x,k)local o=(k%2)*16;return 12*k+3+2.3*sin(2*pi*(x+o)/32)+.9*sin(4*pi*(x+o)/32+1.3)end
        for y=0,H-1 do for x=0,W-1 do
            local u=99
            for k=-1,2 do local d=y-crest(x,k);if d>=0 and d<u then u=d end end
            local d=bayer[(y%4)*4+x%4+1]/16
            local code=u<1 and 1 or u<2 and 2 or u<4 and 3 or (u<7.5 and d<(7.5-u)/3.5)and 4 or u>9.6 and 5 or 0
            if u>8.5 and u<10.4 and hash(x,y,301)<.16 then code=6 end
            put(t,x,y,code)
        end end
        return t
    end
    function build.cracks()
        local P=60;local t=tex(P,P);local pts={}
        for j=0,2 do for i=0,2 do table.insert(pts,{i*20+4+hash(i,j,401)*12,j*20+4+hash(i,j,402)*12})end end
        for y=0,P-1 do for x=0,P-1 do
            local best={}
            for _,p in ipairs(pts)do
                local dx,dy=wrap(x+.5-p[1],P),wrap(y+.5-p[2],P);local d=dx*dx+dy*dy
                table.insert(best,{d,dx,dy});if #best>3 then table.sort(best,function(a,b)return a[1]<b[1]end);best[4]=nil end
            end
            table.sort(best,function(a,b)return a[1]<b[1]end)
            local function gap(a,b)local sx,sy=a[2]-b[2],a[3]-b[3];return (b[1]-a[1])/(2*sqrt(sx*sx+sy*sy))end
            local e,e3=gap(best[1],best[2]),gap(best[1],best[3])
            local code
            if e<1.2 and e3<1.9 then code=8
            elseif e<.5 then code=1 elseif e<1.2 then code=2 elseif e<2.2 then code=3
            elseif e<3.3 and bayer[(y%4)*4+x%4+1]<8 then code=4
            else code=sqrt(best[1][1])<6 and 5 or hash(x,y,405)<.03 and 6 or 7 end
            put(t,x,y,code)
        end end
        return t
    end
    function build.bolts()
        local P=64;local t=tex(P,P);local core={}
        local function mark(x,y,c)local k=(y%P)*P+x%P;if not core[k]or core[k]>c then core[k]=c end end
        local function line(ax,ay,bx,by,c)
            local n=max(abs(bx-ax),abs(by-ay))
            for s=0,n do mark(floor(ax+(bx-ax)*s/n+.5),floor(ay+(by-ay)*s/n+.5),c)end
        end
        for b,o in ipairs({{10,3},{42,35}})do
            local x,y=o[1],o[2];local branchAt=2+b%2
            for s=1,6 do
                local nx,ny=x+(s%2==1 and 1 or -1)*(4+floor(hash(b,s,411)*3))+2,y+6+floor(hash(b,s,412)*2)
                line(x,y,nx,ny,1)
                if s==branchAt then
                    local bx,by=nx-7,ny+6;line(nx,ny,bx,by,4);line(bx,by,bx-2,by+6,4)
                end
                x,y=nx,ny
            end
            for _,d in ipairs({{0,0},{1,0},{-1,0},{0,1},{0,-1}})do mark(o[1]+d[1],o[2]+d[2],1)end
        end
        for y=0,P-1 do for x=0,P-1 do
            local code=core[y*P+x]
            if not code then
                local near=9
                for dy=-2,2 do for dx=-2,2 do if core[((y+dy)%P)*P+(x+dx)%P]then near=min(near,max(abs(dx),abs(dy)))end end end
                if near==1 then code=2 elseif near==2 then code=3
                elseif (x+2*y)%13==0 and hash((x+2*y)//13,y//5,415)<.45 then code=5
                elseif noise(x,y,32,P,416)<.38 and bayer[(y%4)*4+x%4+1]<9 then code=6
                else code=0 end
            end
            put(t,x,y,code)
        end end
        return t
    end
    local crown={'.*...*...*.','.#..###..#.','##..###..##','###.###.###','###########','#o#o#o#o#o#','###########'}
    function build.crown()
        local P=40;local t=tex(P,P);local mask={}
        for _,o in ipairs({{15,-3},{-5,17}})do for r,row in ipairs(crown)do for c=1,#row do
            local ch=row:sub(c,c);if ch~='.'then mask[((o[2]+r-1)%P)*P+(o[1]+c-1)%P]=ch end
        end end end
        local function at(x,y)return mask[(y%P)*P+x%P]end
        for y=0,P-1 do for x=0,P-1 do
            local m=at(x,y);local code=0
            if m=='*'then code=9 elseif m=='o'then code=10
            elseif m then code=at(x,y-1)and 5 or 6
            elseif at(x-1,y-1)then code=7
            elseif at(x+1,y)or at(x-1,y)or at(x,y+1)or at(x,y-1)then code=8
            else
                local a,b=(x+y)%P,(x-y)%P;local e=min(a,P-a,b,P-b)
                local stud=min(abs(wrap(x,P))+abs(wrap(y,P)),abs(wrap(x-20,P))+abs(wrap(y-20,P)))
                if stud<=1 then code=3 elseif e==0 then code=1 elseif e==3 and x%2==0 then code=2
                elseif (abs(wrap(x-20,P))+abs(wrap(y,P)))<20 then code=4 end
            end
            put(t,x,y,code)
        end end
        return t
    end
    function build.feathers()
        local W,H=40,28;local t=tex(W,H);local L,R=24,7.5
        for y=0,H-1 do for x=0,W-1 do
            local code=0
            for k=2,-1,-1 do
                local cy=14*k;local cx=10+10*(k%2)
                for c=-1,2 do
                    local fx=c*20+cx;local dx=wrap(x+.5-fx,W);local dy=(y+.5)-cy
                    if dy>=0 and dy<=L then
                        local tt=dy/L;local w=R*sin(pi*min(1,tt^.75))
                        if abs(dx)<w then
                            local ex,ey=dx,(tt-.74)*L
                            local er=sqrt(ex*ex+ey*ey)
                            if abs(dx)>w-1.1 then code=1
                            elseif er<1.4 then code=8 elseif er<2.7 then code=9
                            elseif abs(dx)<.6 and tt<.62 then code=7
                            else local barb=(dy-abs(dx)*.9)%3<1.1
                                code=tt<.3 and 2 or tt<.55 and (barb and 4 or 3) or (barb and 6 or 5)end
                        end
                    end
                end
            end
            put(t,x,y,code)
        end end
        return t
    end
    function build.eclipse()
        local P=80;local t=tex(P,P)
        local suns={{20,20},{60,60}};local crescents={{60,20,1},{20,60,-1}};local R=7
        for y=0,P-1 do for x=0,P-1 do
            local code=0;local d4=bayer[(y%4)*4+x%4+1]/16
            local dust=hash(x,y,501);if dust<.028 then code=dust<.01 and 13 or dust<.019 and 14 or 15 end
            local a,b=wrap(x-y,P),wrap(x+y,P)
            if (abs(a)<.6 or abs(b)<.6)and (x+y*3)%6<3 then local h=floor(((x+y)%40)/13.4);code=10+h end
            for _,s in ipairs(suns)do
                local dx,dy=wrap(x+.5-s[1],P),wrap(y+.5-s[2],P);local d=sqrt(dx*dx+dy*dy)
                local ang=math.atan2(dy,dx);local ray=(ang+pi/8)%(pi/4)-pi/8;local rd=abs(ray)*d
                local rank=floor((ang+pi/8)/(pi/4)+8)%2==0 and 5 or 6
                if d<R then code=1
                elseif d<R+1.3 then code=2
                elseif d<R+3 then code=3
                elseif rd<.75 and d<R+(rank==5 and 9 or 14)then code=rank
                elseif d<R+7.5 and d4<(R+7.5-d)/4.5 then code=4 end
                local fx,fy=dx+R*.74,dy+R*.74
                if abs(fx)+abs(fy)<1.2 then code=7 elseif (abs(fx)<.6 and abs(fy)<3.6)or(abs(fy)<.6 and abs(fx)<3.6)then code=8 end
            end
            for _,c in ipairs(crescents)do
                local dx,dy=wrap(x+.5-c[1],P),wrap(y+.5-c[2],P);local d=sqrt(dx*dx+dy*dy)
                local mx,my=dx-2.2*c[3],dy+1.2;local md=sqrt(mx*mx+my*my)
                if d<4.6 then code=md<4.2 and 1 or 9 elseif d<5.6 and code==0 then code=3 end
            end
            put(t,x,y,code)
        end end
        return t
    end
    ink.ripple={{'base',.4},{'accent',.58},{'accent',.36},{'accent',.22},{'accent',.12},{'accent',.42},{'base',.14},{'hot',.62}}
    ink.waves={{'hot',.62},{'trim',.42},{'accent',.3},{'accent',.15},{'dark',.15},{'hot',.36}}
    ink.cracks={{'hot',.58},{'fire',.5},{'fire',.22},{'fire',.08},{'dark',.22},{'fire',.3},{'dark',.13},{'hot',.8}}
    ink.bolts={{'white',.78},{'accent',.46},{'accent',.2},{'trim',.58},{'light',.09},{'dark',.13}}
    ink.crown={{'gold',.44},{'gold',.24},{'hot',.78},{'base',.2},{'gold',.56},{'bright',.74},{'dark',.32},{'dark',.18},{'hot',.92},{'base',.62}}
    ink.feathers={{'dark',.3},{'gold',.06},{'trim',.26},{'trim',.14},{'fire',.46},{'fire',.3},{'hot',.6},{'hot',.88},{'fire',.68}}
    ink.eclipse={{'black',{.6,.68,.78}},{'corona',{.74,.84,.92}},{'violet',{.42,.5,.58}},{'violet',{.2,.3,.4}},
        {'corona',{.3,.44,.56}},{'magenta',{0,.32,.5}},{'white',{.7,.85,.95}},{'cyan',{.36,.56,.72}},{'corona',{.56,.66,.76}},
        {'cyan',{.14,.3,.5}},{'violet',{.14,.3,.5}},{'magenta',{.14,.3,.5}},
        {'corona',{.22,.3,.38}},{'corona',{0,.28,.36}},{'corona',{0,0,.34}}}
end
local function hsv(at,i)return Color3.fromHSV(.45+.47*(.5+.5*sin((at*.11+i*.13)*pi*2)),.7,.95)end
function M.slab(motif,c)
    local add,fill,accent,trim,base,y=c.add,c.fill,c.accent,c.trim,c.base,c.y
    local white=Color3.new(1,1,1);local anim={}
    local function track(p,cf,extra)local e=extra or {};e.p=p;e.home=cf;e.size=p.Size;e.phase=e.phase or 1;table.insert(anim,e);return e end
    local function glass(p,t)p.Transparency=t;p:SetAttribute('BaseTransparency',t);return p end
    local function seg(name,a,b,w,h,color,glow,phase)
        local cf=CFrame.lookAt((a+b)/2,b);return add(name,Vector3.new(w,h,(b-a).Magnitude),cf,color,glow,phase),cf
    end
    local function disc(name,r,h,cf,color,glow,phase)
        cf=cf*CFrame.Angles(0,0,pi/2);local p=add(name,Vector3.new(h,r*2,r*2),cf,color,glow,phase);p.Shape=Enum.PartType.Cylinder;return p,cf
    end
    local function ball(name,d,cf,color,glow,phase)local p=add(name,Vector3.one*d,cf,color,glow,phase);p.Shape=Enum.PartType.Ball;return p,cf end
    local V=Vector3.new
    if motif=='ripple'then
        local sludge=base:Lerp(fill,.25)
        local pools={{-1.15,-1.05,.55},{1.2,1.1,.45},{-1.6,1.5,.3},{1.6,-1.5,.26}}
        for i,o in ipairs(pools)do
            disc('PoolRim',o[3],.012,CFrame.new(o[1],y+.03,o[2]),accent,true)
            disc('Pool',o[3]-.07,.014,CFrame.new(o[1],y+.036,o[2]),sludge)
            if i<3 then ball('Glint',.13,CFrame.new(o[1]-o[3]*.38,y+.05,o[2]-o[3]*.38),trim:Lerp(white,.4),true)end
        end
        local span=.7
        for _,o in ipairs({{1,0},{1,1/3},{1,2/3},{2,.15},{2,.65}})do
            local pl=pools[o[1]];local e={ripple=true,cx=pl[1],cz=pl[2],r0=pl[3],off=o[2]}
            local ring,cf=disc('Ripple',pl[3]+.1,.002,CFrame.new(pl[1],y+.003,pl[2]),accent,true);track(ring,cf,e)
            e.mask=disc('RippleMask',pl[3]+.05,.002,CFrame.new(pl[1],y+.005,pl[2]),fill)
        end
        for i,o in ipairs({{-1.05,-.95},{-1.3,-1.2},{1.25,1.05},{-1.55,1.45},{1.15,1.2}})do
            local p,cf=ball('Bubble',.09,CFrame.new(o[1],y+.07,o[2]),accent:Lerp(white,.25),true);track(p,cf,{bubble=true,off=i*.29})
        end
        return function(at,phase,put)
            for _,e in ipairs(anim)do
                if e.ripple then
                    local k=(at*.3+e.off)%1;local r=e.r0+.04+k*span;local h=y+.002+(e.r0+span-r)*.03
                    e.p.Size=V(.002,r*2,r*2);e.mask.Size=V(.002,(r-.045)*2,(r-.045)*2)
                    local rot=CFrame.Angles(0,0,pi/2)
                    put(e.p,CFrame.new(e.cx,h,e.cz)*rot);put(e.mask,CFrame.new(e.cx,h+.006,e.cz)*rot)
                    e.p.Transparency=.08+k^1.5*.85
                else
                    local k=(at*.45+e.off)%1
                    put(e.p,e.home*CFrame.new(math.sin(at*3+e.off*9)*.03,k*.42,0));e.p.Transparency=k^2*.9
                end
            end
        end
    elseif motif=='waves'then
        local foam,face=trim:Lerp(white,.3),accent:Lerp(fill,.42)
        local n=5;local x0,x1=-2.25,2.25
        local function crest(x,e,at)return e.z0+.2*sin(2.4*x-1.5*at+e.row*2.1)+.07*sin(5.1*x-2.3*at+e.row)end
        local function pose(e,at)
            local xa,xb=x0+(x1-x0)*e.i/n,x0+(x1-x0)*(e.i+1)/n
            local a,b=V(xa,y,crest(xa,e,at)),V(xb,y,crest(xb,e,at))
            if e.face then a+=V(0,0,.17);b+=V(0,0,.17)else a+=V(0,.02,0);b+=V(0,.02,0)end
            return CFrame.lookAt((a+b)/2,b),(b-a).Magnitude+(e.face and .02 or .04)
        end
        for r=0,2 do for i=0,n-1 do for _,f in ipairs({true,false})do
            local e={row=r,i=i,z0=-1.55+r*1.55,face=f};local cf,len=pose(e,0)
            track(add(f and 'WaveFace' or 'WaveCrest',f and V(.34,.025,len)or V(.07,.04,len),cf,f and face or foam,not f),cf,e)
        end end end
        return function(at,phase,put)
            for _,e in ipairs(anim)do local cf,len=pose(e,at);e.p.Size=V(e.size.X,e.size.Y,len);put(e.p,cf)end
        end
    elseif motif=='cracks'then
        local basalt=fill:Lerp(Color3.fromRGB(30,20,16),.45);local hot=trim:Lerp(white,.25)
        for r=0,2 do add('Basalt',V(.95,.03,.95*math.sqrt(3)),CFrame.new(.05,y+.003,0)*CFrame.Angles(0,r*pi/3,0),basalt)end
        local J={V(-1.2,0,-1.1),V(.45,0,-1.45),V(1.5,0,-.35),V(1.05,0,1.2),V(-.6,0,1.35),V(-1.6,0,.25)}
        local outer={V(-2.35,0,-1.95),V(.75,0,-2.35),V(2.35,0,-1.0),V(1.6,0,2.35),V(-1.0,0,2.35),V(-2.35,0,.75)}
        local k=0
        for i=1,6 do
            local a,b=J[i]+V(0,y+.02,0),J[i%6+1]+V(0,y+.02,0)
            k+=1;local p,cf=seg('LavaGlow',a,b,.14,.02,accent,true);glass(p,.2);track(p,cf,{glow=true,k=k})
            seg('LavaCore',a+V(0,.012,0),b+V(0,.012,0),.045,.02,hot,true)
            k+=1;local q,cf2=seg('LavaGlow',a,outer[i]+V(0,y+.02,0),.11,.02,accent,true);glass(q,.2);track(q,cf2,{glow=true,k=k})
            ball('LavaNode',.15,CFrame.new(a+V(0,.015,0)),hot,true)
        end
        for i,o in ipairs({{-1.6,-.6},{.9,-1.4},{-.4,1.3}})do
            local p=ball('Ember',.08,CFrame.new(o[1],y+.06,o[2]),trim,true);track(p,p.CFrame,{ember=true,off=i*.29})
        end
        return function(at,phase,put)
            for _,e in ipairs(anim)do
                if e.glow then e.p.Transparency=.08+.42*(.5+.5*sin(at*2.2-e.k*.7))
                else local q=(at*.38+e.off)%1;put(e.p,e.home*CFrame.new(sin(at*2+e.off*7)*.06,q*.6,0));e.p.Transparency=q^1.5*.95 end
            end
        end
    elseif motif=='bolts'then
        local core=trim:Lerp(white,.45)
        local function bolt(sign,id)
            local pts={V(-1.95,0,-2.3),V(-1.3,0,-1.7),V(-1.75,0,-1.05),V(-1.05,0,-.45),V(-1.5,0,.25),V(-.9,0,.9),V(-1.3,0,1.6)}
            local function at(v,h)return V(v.X*sign,y+h,v.Z*sign)end
            for i=1,#pts-1 do
                local p,cf=seg('BoltSheath',at(pts[i],.01),at(pts[i+1],.01),.26,.02,accent,true);glass(p,.4);track(p,cf,{bolt=id,sheath=true})
                local q,cf2=seg('Bolt',at(pts[i],.025),at(pts[i+1],.025),.085,.025,core,true);track(q,cf2,{bolt=id})
            end
            local f={V(-1.05,0,-.45),V(-.5,0,-.2),V(-.3,0,.35)}
            for i=1,2 do local q,cf=seg('BoltFork',at(f[i],.025),at(f[i+1],.025),.06,.025,core,true);track(q,cf,{bolt=id})end
            local s=ball('Strike',.22,CFrame.new(at(pts[#pts],.03)),core,true);track(s,s.CFrame,{bolt=id,strike=true})
        end
        bolt(1,0);bolt(-1,.5)
        return function(at,phase,put)
            for _,e in ipairs(anim)do
                local f=(at*.6+e.bolt)%1;local flash=f<.06 and 0 or f<.12 and .45 or f<.18 and .1 or 1
                if e.strike then e.p.Transparency=.15+.8*math.min(1,flash)
                elseif e.sheath then e.p.Transparency=.25+.5*math.min(1,flash)
                else e.p.Transparency=.05+.4*math.min(1,flash);put(e.p,e.home*CFrame.new(flash<1 and sin(at*41)*.02 or 0,0,0))end
            end
        end
    elseif motif=='crown'then
        local gold,deep=accent,accent:Lerp(Color3.new(),.25);local navy=base:Lerp(fill,.15)
        add('Damask',V(2.3,.03,2.3),CFrame.new(0,y+.002,0)*CFrame.Angles(0,pi/4,0),navy)
        for _,d in ipairs({1,-1})do for _,c0 in ipairs({-1.7,1.7})do
            local ts={};for _,x in ipairs({-2.35,2.35})do local z=(c0-x)/d;if math.abs(z)<=2.35 then table.insert(ts,V(x,0,z))end end
            for _,z in ipairs({-2.35,2.35})do local x=c0-d*z;if math.abs(x)<=2.35 then table.insert(ts,V(x,0,z))end end
            seg('Trellis',ts[1]+V(0,y+.012,0),ts[2]+V(0,y+.012,0),.05,.02,gold)
        end end
        for _,o in ipairs({{1.7,0},{-1.7,0},{0,1.7},{0,-1.7}})do ball('Stud',.16,CFrame.new(o[1],y+.03,o[2]),trim:Lerp(white,.3),true)end
        local h0=y+.12;local R=.72;local parts={}
        local function crownPart(p,cf)table.insert(parts,track(p,cf,{crown=true}))end
        for i=0,7 do
            local a=i/8*pi*2;local cf=CFrame.new(0,h0+.11,0)*CFrame.Angles(0,a,0)*CFrame.new(0,0,-R)
            crownPart(add('CrownBand',V(2*R*math.tan(pi/8)+.02,.26,.08),cf,i%2==0 and gold or deep),cf)
        end
        crownPart(ball('Velvet',1.15,CFrame.new(0,h0+.2,0),navy:Lerp(Color3.fromRGB(40,52,110),.5)))
        for i=0,3 do
            local a=i/4*pi*2+pi/8;local cf=CFrame.new(0,h0+.4,0)*CFrame.Angles(0,a,0)*CFrame.new(0,0,-R+.02)*CFrame.Angles(-.18,0,0)
            crownPart(add('CrownPoint',V(.2,.42,.07),cf*CFrame.Angles(0,0,pi/4),gold),cf*CFrame.Angles(0,0,pi/4))
            local jcf=cf*CFrame.new(0,.31,0);local j=ball('TipJewel',.17,jcf,trim:Lerp(white,.35),true);table.insert(parts,track(j,jcf,{crown=true,jewel=i}))
            local bcf=CFrame.new(0,h0+.11,0)*CFrame.Angles(0,a+pi/4,0)*CFrame.new(0,0,-R-.045);crownPart(ball('BandJewel',.12,bcf,Color3.fromRGB(70,110,255),true),bcf)
        end
        crownPart(ball('Orb',.24,CFrame.new(0,h0+.74,0),gold),CFrame.new(0,h0+.74,0))
        local ccf=CFrame.new(0,h0+.94,0);crownPart(add('Cross',V(.06,.2,.06),ccf,trim:Lerp(white,.3),true),ccf)
        return function(at,phase,put)
            local spin=CFrame.new(0,math.sin(at*1.3)*.05,0)*CFrame.Angles(0,at*.45,0)
            for _,e in ipairs(anim)do
                if e.crown then put(e.p,spin*e.home);if e.jewel then e.p.Transparency=.5*(.5+.5*sin(at*3+e.jewel*1.6))^4 end end
            end
        end
    elseif motif=='feathers'then
        local hot=trim:Lerp(white,.3)
        add('PhoenixBody',V(.34,.14,.9),CFrame.new(0,y+.12,.05),accent:Lerp(trim,.3))
        add('PhoenixBreast',V(.26,.1,.5),CFrame.new(0,y+.2,-.2)*CFrame.Angles(.25,0,0),trim)
        ball('PhoenixHead',.38,CFrame.new(0,y+.26,-.64),trim)
        add('PhoenixCrest',V(.06,.08,.42),CFrame.new(0,y+.36,-.5)*CFrame.Angles(.55,0,0),hot,true)
        for _,side in ipairs({-1,1})do
            local sh=CFrame.new(side*.14,y+.16,-.12)
            for i=0,4 do
                local len=({1.95,1.85,1.65,1.42,1.18})[i+1]
                local rel=CFrame.new(side*i*.06,0,i*.12)*CFrame.Angles(0,-side*pi/2+side*(.5-i*.2),0)
                local home,tip=rel*CFrame.new(0,0,-len/2),rel*CFrame.new(0,.012,-len+.12)
                track(add('WingFeather',V(.34-i*.02,.04,len),sh*home,trim:Lerp(accent,.15+i*.2)),sh*home,{wing=side,sh=sh,i=i,rel=home})
                track(add('FeatherFlame',V(.24,.06,.5),sh*tip,i%2==0 and accent or hot,true),sh*tip,{wing=side,sh=sh,i=i,rel=tip})
            end
        end
        local tb=CFrame.new(0,y+.1,.45)
        for i=-1,1 do
            local cf=CFrame.Angles(0,i*.42,0);local len=1.75-math.abs(i)*.3
            local home,tip=cf*CFrame.new(0,0,len/2),cf*CFrame.new(0,.012,len-.02)
            track(add('TailFeather',V(.2,.04,len),tb*home,accent),tb*home,{tail=i,rel=home})
            track(add('TailFlame',V(.2,.05,.5),tb*tip,hot,true),tb*tip,{tail=i,rel=tip})
        end
        for i=0,3 do
            local cf=CFrame.Angles(0,i*pi/2,0)*CFrame.new(i%2==0 and .9 or -.9,y+.16,-2.32)
            local p=add('EdgeFlame',V(.5,.28,.06),cf,i%2==0 and accent or trim,true);glass(p,.2);track(p,cf,{edge=i})
        end
        return function(at,phase,put)
            local beat=sin(at*1.9)
            for _,e in ipairs(anim)do
                if e.wing then put(e.p,e.sh*CFrame.Angles(0,0,e.wing*(.55+.2*beat)*(1-e.i*.06))*e.rel)
                elseif e.tail then put(e.p,tb*CFrame.Angles(0,sin(at*1.3)*.16,0)*e.rel)
                elseif e.edge then
                    local f=.5+.5*sin(at*5.3+e.edge*1.9);e.p.Size=V(.5,.18+.18*f,.06);put(e.p,e.home*CFrame.new(0,.09*f-.05,0));e.p.Transparency=.1+.35*(1-f)
                end
            end
        end
    elseif motif=='eclipse'then
        local corona,violet=trim,Color3.fromRGB(206,184,255);local black=Color3.fromRGB(6,6,12)
        local function sun(name,r,h,x,z,phase)local p=disc(name,r,h,CFrame.new(x,y+.02,z),corona,true,phase);return p end
        glass((disc('Glow',1.2,.02,CFrame.new(0,y+.006,0),violet,true,1)),.55);glass((disc('Glow2',1.65,.015,CFrame.new(0,y+.002,0),accent,true,2)),.72)
        sun('Sun',.74,.04,0,0)
        local moon,mcf=disc('Moon',.68,.07,CFrame.new(0,y+.06,0),black);moon.Material=Enum.Material.Glass;local me=track(moon,mcf,{moon=true})
        for i=0,9 do
            local cf=CFrame.Angles(0,i/10*pi*2,0)*CFrame.new(0,y+.05,-.86)
            local p=add('Corona',V(.38,.03,.07),cf,corona:Lerp(white,.3),true);track(p,cf,{ring=i})
        end
        for i=0,5 do
            local cf=CFrame.Angles(0,i/6*pi*2,0)*CFrame.new(0,y+.04,-1.25)
            local p=add('Ray',V(.06,.025,.55),cf,violet,true,2);track(p,cf,{ray=i,phase=2})
        end
        for i=0,5 do
            local cf=CFrame.Angles(0,(i+.5)/6*pi*2,0)*CFrame.new(0,y+.035,-1.62)
            local p=add('Streamer',V(.05,.02,1.05),cf,hsv(0,i),true,3);glass(p,.15);track(p,cf,{streamer=i,phase=3})
        end
        local fcf=CFrame.new(-.5,y+.1,-.5);ball('Flare',.2,fcf,white,true,3)
        local scf=CFrame.new(-.5,y+.1,-.5)*CFrame.Angles(0,pi/4,0);local sp=add('FlareSpike',V(.04,.03,.9),scf,Color3.fromRGB(120,236,255),true,3);track(sp,scf,{spike=true,phase=3})
        for i,o in ipairs({{-1.85,-1.85},{1.85,-1.85},{1.85,1.85},{-1.85,1.85}})do
            local p=sun('MiniSun',.3,.03,o[1],o[2]);track(p,p.CFrame,{mini=i})
            local m,mc=disc('MiniMoon',.27,.05,CFrame.new(o[1]+(i%2==0 and .07 or -.07),y+.05,o[2]-.04),black);m.Material=Enum.Material.Glass
        end
        local offsets={V(.42,0,-.2),V(.16,0,-.08),V(0,0,0)}
        return function(at,phase,put)
            for _,e in ipairs(anim)do
                if e.moon then put(e.p,CFrame.new(offsets[phase]+V(sin(at*.6)*.04,0,cos(at*.6)*.03))*e.home)
                elseif e.ring then put(e.p,CFrame.Angles(0,at*.3,0)*e.home);e.p.Transparency=.15*(.5+.5*sin(at*2+e.ring))
                elseif e.ray then if e.phase<=phase then local k=.5+.5*sin(at*1.7+e.ray*1.1);e.p.Size=V(.06,.025,.4+.3*k);put(e.p,CFrame.Angles(0,-at*.12,0)*e.home*CFrame.new(0,0,-.1*k))end
                elseif e.streamer then if e.phase<=phase then e.p.Color=hsv(at,e.streamer);put(e.p,CFrame.Angles(0,-at*.2,0)*e.home)end
                elseif e.spike then if e.phase<=phase then e.p.Transparency=.6*(.5+.5*sin(at*2.6))end
                elseif e.mini then e.p.Transparency=.25*(.5+.5*sin(at*1.5+e.mini))end
            end
        end
    else
        return require(script.Parent.TerritoryVolume2).slab(motif,c)
    end
end
return M
