local M={}
local floor,sin,cos,pi,sqrt,abs,max,min,atan2=math.floor,math.sin,math.cos,math.pi,math.sqrt,math.abs,math.max,math.min,math.atan2
local function wrap(d,P)return (d+P/2)%P-P/2 end
M.motifs={dragonscale=true,facets=true,plumes=true,pixels=true,abyss=true}
function M.install(build,ink,kit)
    local hash,noise,tex,put,bayer=kit.hash,kit.noise,kit.tex,kit.put,kit.bayer
    local function field(P)return {P=P,q={},t={}}end
    local function dab(F,cx,cy,r,t)
        local P,q0,t0,rr=F.P,F.q,F.t,r*r
        for yy=floor(cy-r),floor(cy+r)do local dy=yy+.5-cy;local row=(yy%P)*P
            for xx=floor(cx-r),floor(cx+r)do local dx=xx+.5-cx;local d=dx*dx+dy*dy
                if d<rr then local k=row+xx%P;local q=sqrt(d)/r;local o=q0[k];if not o or q<o then q0[k]=q;t0[k]=t end end
            end
        end
    end
    local function path(F,fn)local t=0;while t<=1 do local x,y,r=fn(t);dab(F,x,y,r,t);t+=max(.0012,r*.33/150)end;local x,y,r=fn(1);dab(F,x,y,r,1)end
    local function rng(seed)local r=seed;return function()r=(r*16807)%2147483647;return r/2147483647 end end
    local function line(map,P,ax,ay,bx,by,r,code)
        local n=max(1,math.ceil(sqrt((bx-ax)^2+(by-ay)^2)/(r*.5)))
        for s=0,n do local cx,cy=ax+(bx-ax)*s/n,ay+(by-ay)*s/n
            for yy=floor(cy-r)-1,floor(cy+r)+1 do for xx=floor(cx-r)-1,floor(cx+r)+1 do
                local dx,dy=xx+.5-cx,yy+.5-cy;if dx*dx+dy*dy<r*r then map[(yy%P)*P+xx%P]=code end
            end end
        end
    end
    function build.dragonscale()
        local P=128;local t=tex(P,P);local F=field(P);local D={}
        local function radius(u)
            return u<.05 and 6 or u<.11 and 6-(u-.05)*36.7 or u<.4 and 3.8+1.4*sin((u-.11)/.29*pi/2)or .7+4.5*(1-(u-.4)/.6)^.8
        end
        for _,d in ipairs({{0,0,1},{188,64,-1}})do
            local ox,oy,sx=d[1],d[2],d[3]
            local function at(u)return ox+sx*(14+104*u),oy+36+14*sin(2*pi*1.15*u+.4)+22*u end
            path(F,function(u)local x,y=at(u);return x,y,radius(u)end)
            local hx,hy=at(0);local nx,ny=at(.02);local fx,fy=hx-nx,hy-ny;local l=sqrt(fx*fx+fy*fy);fx,fy=fx/l,fy/l
            local px,py=-fy,fx
            for _,s in ipairs({-1,1})do
                line(D,P,hx-fx*2+px*s*3,hy-fy*2+py*s*3,hx-fx*11+px*s*7,hy-fy*11+py*s*7,1.1,8)
                local wx,wy=hx+fx*5+px*s*2,hy+fy*5+py*s*2
                for k=1,10 do
                    local ax,ay=wx,wy;wx+=fx*1.3+px*s*(.55+.5*sin(k*.7));wy+=fy*1.3+py*s*(.55+.5*sin(k*.7))
                    line(D,P,ax,ay,wx,wy,.62,8)
                end
                line(D,P,hx+fx*1.2+px*s*2.4,hy+fy*1.2+py*s*2.4,hx+fx*1.2+px*s*2.4,hy+fy*1.2+py*s*2.4,1.25,7)
            end
            for i,u in ipairs({.22,.36,.6,.74})do
                local s=i%2==0 and 1 or -1;local x,y=at(u);local x2,y2=at(u+.01);local ex,ey=x2-x,y2-y;local el=sqrt(ex*ex+ey*ey);ex,ey=ex/el,ey/el
                local qx,qy=-ey*s,ex*s;local r=radius(u);local kx,ky=x+qx*(r+3.2),y+qy*(r+3.2)
                line(D,P,x+qx*r*.6,y+qy*r*.6,kx,ky,1,8)
                for toe=-1,1 do line(D,P,kx,ky,kx+qx*2.4+ex*toe*1.8,ky+qy*2.4+ey*toe*1.8,.6,8)end
            end
            local tx,ty=at(1);local bx,by=at(.98);local ex,ey=tx-bx,ty-by;local el=sqrt(ex*ex+ey*ey);ex,ey=ex/el,ey/el
            for _,a in ipairs({-.6,0,.6})do local c,s=cos(a),sin(a);line(D,P,tx,ty,tx+(ex*c-ey*s)*7,ty+(ey*c+ex*s)*7,1.2,8)end
            local cx,cy=hx+fx*15-px*3,hy+fy*15-py*3
            for yy=floor(cy-7),floor(cy+7)do for xx=floor(cx-7),floor(cx+7)do
                local r=sqrt((xx+.5-cx)^2+(yy+.5-cy)^2);local k=(yy%P)*P+xx%P
                if r<2.3 then D[k]=9 elseif r<4.4 then D[k]=10 elseif r<6.4 and bayer[(yy%4)*4+xx%4+1]<6 and not D[k]then D[k]=10 end
            end end
        end
        local function inBody(x,y)local q=F.q[(y%P)*P+x%P];return q and q<1 end
        local scale={}
        for y=0,15 do for x=0,15 do
            local best,bdx,bdy=1e9,0,0
            for j=y//8-1,y//8+2 do
                local o=(j%2)*8
                for i=(x-o)//16-1,(x-o)//16+1 do
                    local dx,dy=x+.5-(i*16+o),y+.5-j*8
                    if dy>=-1 then local dd=dx*dx+dy*dy;if dd<best then best,bdx,bdy=dd,dx,dy end end
                end
            end
            local r=sqrt(best);scale[y*16+x]=r>=8.2 and 1 or (bdy<2.6 and bdx<-1)and 2 or bdy>5.4 and 3 or 0
        end end
        for y=0,P-1 do for x=0,P-1 do
            local k=y*P+x;local code=D[k]
            if not code then
                local q=F.q[k]
                if q and q<1 then
                    local u=F.t[k];local s=u*150
                    if q>.8 then code=6
                    elseif q<.16 and u>.07 and u<.94 and floor(s)%3~=0 then code=8
                    elseif q<.72 and (s+q*3)%4<1.1 and u>.06 then code=5
                    else code=4 end
                elseif inBody(x-1,y-1)or inBody(x-2,y-2)then code=6
                else code=scale[(y%16)*16+x%16]end
            end
            put(t,x,y,code)
        end end
        return t
    end
    function build.facets()
        local P=128;local t=tex(P,P)
        local gems={{38,38,30,0},{102,98,22,pi/8},{100,30,12,pi/8},{28,104,14,0}}
        local lightA=-3*pi/4
        local map=t.buf
        for y=0,P-1 do for x=0,P-1 do
            local a1,a2=(x+y)%32,(x-y)%32
            buffer.writeu8(map,y*P+x,(a1==0 or a2==0)and 9 or ((x+y)//32+(x-y+128)//32)%2==0 and 10 or 0)
        end end
        local c8,p4=cos(pi/8),pi/4
        for _,g in ipairs(gems)do
            local R=g[3];local B=R+4;local big=R>20;local prong=big and 6.2 or 3.4
            local pr={};for k=0,3 do local pa=g[4]+k*pi/2;pr[k+1]={cos(pa)*R,sin(pa)*R}end
            for y=floor(g[2]-B),floor(g[2]+B)do for x=floor(g[1]-B),floor(g[1]+B)do
                local k=(y%P)*P+x%P;local code=buffer.readu8(map,k)
                local dx,dy=x+.5-g[1],y+.5-g[2];local r=sqrt(dx*dx+dy*dy)
                if r<R+3.2 then
                    local a=(atan2(dy,dx)-g[4])%(2*pi);local m=a%p4;local ro=r*cos(m-pi/8)/c8
                    if ro<R then
                        local s=floor(a/p4);local h=m<pi/8 and 0 or 1;local tw=1-abs(m/(pi/8)-1)
                        local edge=min(m,p4-m)*r<.6
                        if ro>R-1.3 then code=6
                        elseif ro<.42*R then code=ro>.42*R-1.1 and 5 or 1
                        elseif ro<R*(.5+.18*tw)then
                            local b=cos((s+.5)*p4-lightA)
                            code=(edge or abs(ro-R*(.5+.18*tw))<.7)and 5 or (b>.3 and 2 or b>-.4 and 3 or 4)
                        else
                            local b=cos((s*2+h+.5)*pi/8-lightA)
                            code=(edge or abs(m-pi/8)*r<.5)and 5 or (b>.45 and 2 or b>-.25 and 3 or 4)
                        end
                    elseif ro<R+3.2 and bayer[(y%4)*4+x%4+1]<(R+3.2-ro)*4 then code=11 end
                end
                for _,q in ipairs(pr)do local px,py=dx-q[1],dy-q[2];local pd=px*px+py*py;if pd<prong then code=pd<1 and 8 or 7 end end
                if big then
                    local sx,sy=dx+R*.42,dy+R*.42
                    if abs(sx)+abs(sy)<1.3 then code=8 elseif (abs(sx)<.55 and abs(sy)<5.5)or(abs(sy)<.55 and abs(sx)<5.5)then code=5 end
                end
                buffer.writeu8(map,k,code)
            end end
        end
        return t
    end
    function build.plumes()
        local P=128;local t=tex(P,P)
        local motifs={{32,46},{96,110}}
        local feathers={{.17,48,9,1},{.62,40,7.8,2},{1.05,32,6.4,3}}
        local downs={{pi/2,17,4.2},{pi/2-.5,14,3.6},{pi/2+.5,14,3.6}}
        local axes={};for _,f in ipairs(feathers)do for _,side in ipairs({-1,1})do
            table.insert(axes,{side*cos(f[1]),-sin(f[1]),side*4,f[2],f[3],(f[4]-1)*5})
        end end
        for _,f in ipairs(downs)do f[4],f[5]=cos(f[1]),sin(f[1])end
        local rand=rng(611)
        for y=0,P-1 do for x=0,P-1 do
            local code=0;local d4=bayer[(y%4)*4+x%4+1]/16
            local dust=rand();if dust<.026 then code=dust<.01 and 22 or dust<.018 and 23 or 24 end
            for _,c in ipairs(motifs)do
                local dx,dy=wrap(x+.5-c[1],P),wrap(y+.5-c[2],P)
                if dx>-60 and dx<60 and dy>-40 and dy<28 then
                local done=false
                local r2=dx*dx+dy*dy;local r=26
                if dy<-23 and dy>-38 and dx<17 and dx>-17 then
                    local hy=(dy+31)*2.6;local hr=sqrt(dx*dx+hy*hy)
                    if abs(hr-13)<1.3 then code=19;done=true elseif abs(hr-13)<3.4 and d4<.5 then code=20;done=true end
                end
                if r2<676 then r=sqrt(r2)end
                if not done then
                    if r<3.2 then code=16;done=true elseif r<6.5 and d4<(6.5-r)/3.3 then code=17;done=true end
                end
                if not done then
                    for _,f in ipairs(axes)do
                        local ax,ay=f[1],f[2];local lx=dx-f[3]
                        local u=lx*ax+dy*ay
                        if u>=0 and u<=f[4]then
                            local v=abs(-lx*ay+dy*ax)
                            if v<f[5]then
                                local tt=u/f[4];local w=f[5]*sin(pi*min(1,tt^.7))*(tt>.9 and (1-tt)*10*.6+.4 or 1)
                                if v<w then
                                    local base=f[6]
                                    if v>w-1.1 then code=base+3
                                    elseif tt>.84 then code=base+5
                                    elseif v<.6 and tt<.8 then code=base+4
                                    elseif (u*.9-v*1.3)%3.4<1.1 then code=base+2
                                    else code=base+1 end
                                    done=true;break
                                end
                            end
                        end
                    end
                end
                if not done and dy>0 then
                    for _,f in ipairs(downs)do
                        local ax,ay=f[4],f[5];local u=dx*ax+dy*ay
                        if u>=3 and u<=3+f[2]then local v=abs(-dx*ay+dy*ax);local tt=(u-3)/f[2];local w=f[3]*sin(pi*min(1,tt^.8))
                            if v<w then code=v>w-1 and 3 or ((u-v*1.2)%3<1 and 2 or 18);break end
                        end
                    end
                end
                if (code==0 or code>=22)and r<26 then
                    local a=atan2(dy,dx);local ray=(a+pi/12)%(pi/6)-pi/12
                    if r>7 and abs(ray)*r<.55 and dy>-4 then code=21
                    elseif d4<(26-r)/40 then code=17 end
                end
                end
            end
            put(t,x,y,code)
        end end
        return t
    end
    function build.pixels()
        local P=128;local t=tex(P,P);local map={}
        local function set(x,y,c)map[(y%P)*P+x%P]=c end
        for b=0,5 do
            local by=floor(hash(b,1,701)*P);local h=2+floor(hash(b,2,701)*4);local x0=floor(hash(b,3,701)*P);local len=20+floor(hash(b,4,701)*44)
            local shift=4+floor(hash(b,5,701)*8)
            for yy=by,by+h-1 do for xx=x0,x0+len-1 do
                set(xx,yy,yy==by and 4 or yy==by+h-1 and 5 or ((xx+shift)//4)%3==0 and 4 or 14)
            end end
        end
        for c=0,9 do
            local rank=c<5 and 2 or 3
            local cx,cy=floor(hash(c,1,711)*P/4)*4,floor(hash(c,2,711)*P/4)*4
            local w,h=(rank==2 and 8 or 12)+floor(hash(c,3,711)*2)*4,(rank==2 and 4 or 8)+floor(hash(c,4,711)*2)*4
            local fillC,cyan,mag=rank==2 and 6 or 15,rank==2 and 7 or 16,rank==2 and 8 or 17
            local g=hash(c,5,711)<.5 and 3 or -3
            for yy=cy,cy+h-1,2 do set(cx+g,yy,cyan);set(cx+w-1+g,yy,mag)end
            for yy=cy,cy+h-1 do for xx=cx,cx+w-1 do
                set(xx,yy,(xx==cx or yy==cy)and cyan or (xx==cx+w-1 or yy==cy+h-1)and mag or fillC)
            end end
        end
        local cells,cols={},{}
        for j=0,P//4-1 do for i=0,P//4-1 do cells[j*32+i]=hash(i,j,721)end end
        for i=0,P//4-1 do cols[i]=hash(i,0,731)<.28 and floor(hash(i,1,731)*P)or false end
        for y=0,P-1 do for x=0,P-1 do
            local code=map[y*P+x]
            if not code then
                code=y%4==3 and 1 or 0
                local h=cells[(y//4)*32+x//4]
                if h<.012 then code=12 elseif h<.026 then code=13 elseif h<.06 then code=2 elseif h<.094 then code=3 end
                if code<=1 then
                    if (x%32==0 or y%32==0)and (x+y)%4<2 then code=9 end
                    local col=cols[x//4];if col and x%4==1 then
                        local seg=(y+col)%24
                        if seg<14 and seg%3~=2 then code=seg==13 and 11 or 10 end
                    end
                end
            end
            put(t,x,y,code)
        end end
        return t
    end
    function build.abyss()
        local P=128;local t=tex(P,P);local pts={};local F=field(P)
        for j=0,3 do for i=0,3 do table.insert(pts,{i*32+6+hash(i,j,801)*20,j*32+6+hash(i,j,802)*20})end end
        for k,o in ipairs({{18,112,1},{82,60,-1}})do
            local function at(u)local a=u*3.4*pi*o[3];local rr=30*(1-u)+3;return o[1]+o[3]*u*26+cos(a)*rr*.35*o[3],o[2]-u*58+sin(a)*rr*.3 end
            path(F,function(u)local x,y=at(u);return x,y,.8+4.2*(1-u)^.9 end)
        end
        local eyes={}
        for i,p in ipairs(pts)do if hash(i,0,805)<.3 then table.insert(eyes,p)end end
        local sy,sx={},{};for i=0,P-1 do sy[i]=2.6*sin(2*pi*i/32+1.1);sx[i]=2.6*sin(2*pi*i/32+.4)end
        local half={};for a,p in ipairs(pts)do half[a]={};for b,o in ipairs(pts)do local qx,qy=wrap(p[1]-o[1],P),wrap(p[2]-o[2],P);half[a][b]=a~=b and .5/sqrt(qx*qx+qy*qy)or 0 end end
        local rand=rng(811);local buf,Fq,Ft=t.buf,F.q,F.t
        for y=0,P-1 do for x=0,P-1 do
            local d4=bayer[(y%4)*4+x%4+1]/16
            local wx,wy=x+sy[y],y+sx[x]
            local cx,cy=floor(wx/32),floor(wy/32)
            local b1,b2,i1,i2=1e9,1e9,0,0
            for j=cy-1,cy+1 do for i=cx-1,cx+1 do
                local n=(j%4)*4+i%4+1;local p=pts[n]
                local dx,dy=wx-(p[1]+(i-i%4)*32),wy-(p[2]+(j-j%4)*32);local d=dx*dx+dy*dy
                if d<b1 then b2,i2=b1,i1;b1,i1=d,n elseif d<b2 then b2,i2=d,n end
            end end
            local e=(b2-b1)*half[i1][i2]
            local code=e<.65 and 1 or e<1.6 and 2 or (e<2.8 and d4<(2.8-e)/1.6)and 3 or (b1<81 and d4<(9-sqrt(b1))/12)and 4 or 0
            local s=rand();if code~=1 and s<.022 then code=s<.008 and 5 or s<.014 and 6 or s<.018 and 7 or 8 end
            local k=y*P+x;local q=Fq[k]
            if q and q<1 then local u=Ft[k];code=q>.72 and 13 or (q<.42 and (u*90)%3<1.1 and u<.85)and 14 or 12 end
            buffer.writeu8(buf,k,code)
        end end
        for _,p in ipairs(eyes)do for _,side in ipairs({-1,1})do
            local ex0=p[1]+side*4.2
            for y=floor(p[2]-3),floor(p[2]+3)do for x=floor(ex0-5),floor(ex0+5)do
                local k=(y%P)*P+x%P;local q=F.q[k]
                if not (q and q<1)then
                    local ex,ey=(x+.5-ex0)/3,(y+.5-p[2])/1.7;local er=ex*ex+ey*ey
                    if er<1 then put(t,x,y,abs(ex*3)<.6 and 11 or 9)elseif er<2.6 and bayer[(y%4)*4+x%4+1]/16<.6 then put(t,x,y,10)end
                end
            end end
        end end
        return t
    end
    ink.dragonscale={{'trim',.22},{'trim',.11},{'dark',.13},{'gold',.52},{'bright',.74},{'dark',.36},{'hot',.92},{'gold',.68},{'hot',.86},{'trim',.42}}
    ink.facets={{'ice',.2},{'white',.34},{'ice',.2},{'dark',.18},{'white',.52},{'white',.68},{'gold',.74},{'white',.92},{'ice',.09},{'dark',.06},{'ice',.12}}
    ink.plumes={{'white',{.36,.42,.48}},{'white',{.54,.6,.66}},{'trim',{.6,.66,.72}},{'trim',{.68,.74,.8}},{'accent',{.58,.66,.74}},
        {'white',{0,.3,.36}},{'white',{0,.46,.54}},{'trim',{0,.5,.58}},{'trim',{0,.64,.72}},{'accent',{0,.52,.62}},
        {'white',{0,0,.36}},{'white',{0,0,.54}},{'trim',{0,0,.58}},{'trim',{0,0,.72}},{'accent',{0,0,.62}},
        {'white',{.82,.88,.94}},{'trim',{.34,.4,.48}},{'white',{.22,.26,.3}},{'accent',{0,0,.74}},{'violet',{0,0,.34}},
        {'trim',{.22,.3,.38}},{'white',{.36,.44,.52}},{'white',{0,.42,.5}},{'white',{0,0,.5}}}
    ink.pixels={{'dark',.1},{'cyan',{.52,.58,.64}},{'magenta',{.5,.56,.62}},{'cyan',{.62,.68,.74}},{'magenta',{.6,.66,.72}},
        {'black',{0,.36,.44}},{'cyan',{0,.58,.66}},{'magenta',{0,.54,.64}},{'cyan',{0,0,.34}},{'cyan',{0,0,.58}},{'white',{0,0,.86}},
        {'white',{.86,.9,.95}},{'black',{.6,.66,.72}},{'black',{.3,.34,.4}},{'black',{0,0,.44}},{'cyan',{0,0,.66}},{'magenta',{0,0,.64}}}
    ink.abyss={{'trim',{.56,.64,.72}},{'trim',{.28,.34,.4}},{'trim',{.12,.15,.19}},{'base',{.3,.35,.4}},
        {'accent',{.6,.7,.8}},{'trim',{.56,.66,.76}},{'accent',{0,.6,.74}},{'trim',{0,0,.72}},
        {'trim',{.88,.92,.95}},{'accent',{.44,.5,.56}},{'black',{.7,.75,.8}},
        {'base',{0,.46,.54}},{'accent',{0,.44,.56}},{'trim',{0,.58,.7}}}
end
function M.slab(motif,c)
    local add,fill,accent,trim,base,y=c.add,c.fill,c.accent,c.trim,c.base,c.y
    local white=Color3.new(1,1,1);local black=Color3.fromRGB(4,6,10);local anim={}
    local V=Vector3.new
    local function track(p,cf,extra)local e=extra or {};e.p=p;e.home=cf;e.size=p.Size;e.phase=e.phase or 1;table.insert(anim,e);return e end
    local function glass(p,t)p.Transparency=t;p:SetAttribute('BaseTransparency',t);return p end
    local function disc(name,r,h,cf,color,glow,phase)
        cf=cf*CFrame.Angles(0,0,pi/2);local p=add(name,V(h,r*2,r*2),cf,color,glow,phase);p.Shape=Enum.PartType.Cylinder;return p,cf
    end
    local function ball(name,d,cf,color,glow,phase)local p=add(name,Vector3.one*d,cf,color,glow,phase);p.Shape=Enum.PartType.Ball;return p,cf end
    local function live(e,phase)return e.phase<=phase end
    if motif=='dragonscale'then
        local gold,deep=accent,accent:Lerp(Color3.new(),.28);local jade=trim:Lerp(fill,.35);local hot=accent:Lerp(white,.5)
        disc('JadePool',1.05,.012,CFrame.new(0,y+.004,0),base:Lerp(fill,.3))
        for i=0,3 do local a=i*pi/2+pi/4;disc('JadeScale',.62,.014,CFrame.new(cos(a)*1.85,y+.006,sin(a)*1.85),jade)end
        local pearl=ball('Pearl',.36,CFrame.new(0,y+.26,0),hot,true);local pe=track(pearl,pearl.CFrame,{pearl=true})
        glass((disc('PearlGlow',.5,.01,CFrame.new(0,y+.02,0),trim,true)),.45)
        for i=0,1 do local p=add('PearlFlame',V(.07,.05,.34),CFrame.new(0,y+.26,0),gold,true);track(p,p.CFrame,{flame=i})end
        local function spine(at,i)
            local a=at*.5-i*.24;local w=at*2.4-i*.75;local r=1.28+.16*sin(w)
            return V(cos(a)*r,y+.16+.05*cos(w),sin(a)*r)
        end
        local N=12
        for i=0,N-1 do
            local w=.34-i*.017
            track(add('DragonBody',V(w,.11,.38),CFrame.identity,i%2==0 and gold or deep,false),CFrame.identity,{seg=i,w=w})
        end
        local head={{'DragonHead',V(.4,.17,.36),CFrame.new(0,0,0),gold,false},{'DragonSnout',V(.26,.11,.24),CFrame.new(0,-.02,-.26),gold,false}}
        for _,s in ipairs({-1,1})do
            table.insert(head,{'DragonHorn',V(.05,.05,.36),CFrame.new(s*.12,.1,.2)*CFrame.Angles(.35,s*.45,0),hot,true})
            table.insert(head,{'DragonWhisker',V(.03,.03,.5),CFrame.new(s*.13,-.02,-.42)*CFrame.Angles(0,-s*.6,0),trim,true,s})
            table.insert(head,{'DragonEye',V(.09,.09,.09),CFrame.new(s*.13,.08,-.06),trim:Lerp(white,.4),true})
        end
        for _,h in ipairs(head)do track(add(h[1],h[2],h[3],h[4],h[5]),h[3],{head=true,rel=h[3],whisker=h[6]})end
        for i,o in ipairs({{2,-1},{3,1},{7,-1},{8,1}})do track(add('DragonClaw',V(.24,.05,.07),CFrame.identity,hot,true),CFrame.identity,{claw=o[1],side=o[2]})end
        track(add('DragonFin',V(.34,.04,.3),CFrame.identity,trim,true),CFrame.identity,{fin=true})
        local function pose(at,put)
            local pts={};for i=-1,N do pts[i]=spine(at,i)end
            local hf=CFrame.lookAt(pts[0]+(pts[-1]-pts[0])*.4,pts[-1])
            for _,e in ipairs(anim)do
                if e.seg then local a,b=pts[e.seg],pts[e.seg+1];put(e.p,CFrame.lookAt((a+b)/2,a))
                elseif e.head then put(e.p,hf*(e.whisker and e.rel*CFrame.Angles(0,e.whisker*.2*sin(at*3),0)or e.rel))
                elseif e.claw then local a,b=pts[e.claw],pts[e.claw+1];put(e.p,CFrame.lookAt((a+b)/2,a)*CFrame.new(e.side*.2,-.04,0)*CFrame.Angles(0,e.side*.5*sin(at*2.4+e.claw),0))
                elseif e.fin then put(e.p,CFrame.lookAt(pts[N],pts[N-1])*CFrame.new(0,.02,.12)*CFrame.Angles(0,.4*sin(at*2.4),0))
                elseif e.pearl then put(e.p,CFrame.new(0,y+.26+.04*sin(at*1.6),0));e.p.Transparency=.25*(.5+.5*sin(at*2.2))
                elseif e.flame then put(e.p,CFrame.new(0,y+.26,0)*CFrame.Angles(0,at*1.8+e.flame*pi,0)*CFrame.new(0,0,-.24))end
            end
        end
        pose(0,function(p,cf)p.CFrame=cf end);for _,e in ipairs(anim)do e.home=e.p.CFrame end
        return function(at,phase,put)pose(at,put)end
    elseif motif=='facets'then
        local ice,plat=trim,Color3.fromRGB(236,244,255);local gold=accent
        disc('Setting',.78,.03,CFrame.new(0,y+.01,0),gold)
        glass((disc('Culet',1.15,.01,CFrame.new(0,y+.003,0),ice,true)),.55)
        local h0=y+.12;local gem={}
        local function g(p,cf)table.insert(gem,track(p,cf,{gem=true}))end
        local gp,gcf=disc('Girdle',.68,.07,CFrame.new(0,h0,0),plat);gp.Material=Enum.Material.Glass;g(gp,gcf)
        for i=0,1 do local cf=CFrame.new(0,h0+.13,0)*CFrame.Angles(0,i*pi/4,0);local p=add('Table',V(.5,.03,.5),cf,ice:Lerp(white,.35),true);g(p,cf)end
        for i=0,7 do
            local cf=CFrame.Angles(0,i/8*pi*2+pi/8,0)*CFrame.new(0,h0+.08,-.47)*CFrame.Angles(-.42,0,0)
            local p=add('CrownFacet',V(.42,.03,.3),cf,i%2==0 and plat or ice,i%2==1);p.Material=i%2==0 and Enum.Material.Glass or Enum.Material.Neon;g(p,cf)
        end
        for i=0,3 do local cf=CFrame.Angles(0,i*pi/2,0)*CFrame.new(0,h0+.04,-.7);g((ball('Prong',.13,cf,gold)),cf)end
        for _,d in ipairs({{0,0},{pi/2,0},{pi/4,1},{-pi/4,1}})do
            local len=d[2]==1 and 6.5 or 4.7
            add('FacetLine',V(.035,.02,len),CFrame.new(0,y+.008,0)*CFrame.Angles(0,d[1],0),plat:Lerp(fill,.3))
        end
        for i,o in ipairs({{-1.75,-1.75},{1.75,-1.75},{1.75,1.75},{-1.75,1.75}})do
            local cf=CFrame.new(o[1],y+.06,o[2])*CFrame.Angles(0,pi/4,0)
            track(add('CornerGem',V(.3,.12,.3),cf,ice:Lerp(white,.3),true),cf,{corner=i})
        end
        for i=0,1 do track(glass(add('Sweep',V(i==0 and .16 or .4,.02,1),CFrame.new(0,y+.03,0),i==0 and white or ice,true),.3),CFrame.new(0,y+.03,0),{sweep=i})end
        for i,o in ipairs({{-1.1,.9},{1.2,-.95},{.95,1.5}})do for k=0,1 do
            local cf=CFrame.new(o[1],y+.09,o[2])*CFrame.Angles(0,k*pi/2+pi/4,0)
            track(add('Sparkle',V(.04,.03,.42),cf,white,true),cf,{spark=i,k=k})
        end end
        return function(at,phase,put)
            local spin=CFrame.new(0,sin(at*1.2)*.03,0)*CFrame.Angles(0,at*.35,0)
            local k=(at/3.2)%1;local c=-4.7+k*9.4
            for _,e in ipairs(anim)do
                if e.gem then put(e.p,spin*e.home)
                elseif e.corner then e.p.Transparency=.6*(.5+.5*sin(at*2.6+e.corner*1.7))^3
                elseif e.sweep then
                    local cc=c-e.sweep*.35;local len=math.max(.05,math.sqrt(2)*(4.6-abs(cc)))
                    e.p.Size=V(e.size.X,e.size.Y,len);put(e.p,CFrame.new(cc/2,y+.03+e.sweep*.004,cc/2)*CFrame.Angles(0,pi/4,0))
                    e.p.Transparency=(abs(cc)>4.4 and 1 or .2+e.sweep*.35)
                elseif e.spark then local f=(.5+.5*sin(at*3.1+e.spark*2.1))^2;e.p.Size=V(.04,.03,.12+.42*f);e.p.Transparency=.7-.6*f end
            end
        end
    elseif motif=='plumes'then
        local ivory,gold,pink=Color3.fromRGB(246,244,250),trim,accent
        disc('Platform',1,.016,CFrame.new(0,y+.006,0),ivory:Lerp(fill,.35))
        glass((disc('Glow',1.35,.01,CFrame.new(0,y+.002,0),pink,true)),.62)
        local orb=ball('Orb',.5,CFrame.new(0,y+.32,0),white,true);track(orb,orb.CFrame,{orb=true})
        for i=0,3 do local cf=CFrame.Angles(0,i*pi/2+pi/4,0)*CFrame.new(0,y+.012,-1.75);add('Quill',V(.32,.02,1.1),cf,ivory:Lerp(gold,.25))end
        for i=0,3 do local cf=CFrame.Angles(0,i*pi/2,0)*CFrame.new(0,y+.016,-1.55);track(glass(add('Ray',V(.05,.02,1.2),cf,gold,true),.25),cf,{ray=i})end
        for _,w in ipairs({{1,0,4,1.7},{2,-.75,3,1.45},{3,.8,2,1.25}})do
            for _,side in ipairs({-1,1})do
                local sh=CFrame.new(side*.3,y+.18+w[1]*.03,0)*CFrame.Angles(0,-side*(pi/2)+side*w[2]*-1,0)
                local cv=CFrame.new(0,.02,-.25);track(add('Covert',V(.42,.07,.5),sh*cv,ivory:Lerp(gold,.18),false,w[1]),sh*cv,{wing=side,sh=sh,rel=cv,pair=w[1],phase=w[1]})
                for f=0,w[3]-1 do
                    local yaw=(f-(w[3]-1)/2)*.26;local len=w[4]-abs(f-(w[3]-1)/2)*.14
                    local rel=CFrame.Angles(0,yaw,0)*CFrame.new(0,0,-len/2-.12)
                    local col=white:Lerp(gold,.1+f*.06):Lerp(pink,w[1]==3 and .22 or 0)
                    track(add('Feather',V(.2,.035,len),sh*rel,col,false,w[1]),sh*rel,{wing=side,sh=sh,rel=rel,pair=w[1],phase=w[1]})
                end
            end
        end
        for i=0,1 do track(add('Shimmer',V(.12,.12,.12),CFrame.new(0,y+.3,0),pink,true),CFrame.new(0,y+.3,0),{shimmer=i*2-1})end
        for i=0,5 do local cf=CFrame.new(cos(i*1.7)*(1+i%2*.5),y+.2,sin(i*1.7)*(1+i%2*.5));local p=ball('Mote',.1,cf,white,true);track(p,cf,{mote=i})end
        for i=0,7 do
            local cf=CFrame.Angles(0,i/8*pi*2,0)*CFrame.new(0,y+1.12,-.56)
            track(add('Halo',V(.46,.06,.08),cf,pink,true,3),cf,{halo=i,phase=3})
        end
        for i=0,3 do
            local cf=CFrame.Angles(0,i*pi/2+pi/4,0)*CFrame.new(0,y+.8,-1.55)
            track(glass(add('Pillar',V(.16,1.6,.16),cf,pink:Lerp(white,.55),true,3),.35),cf,{pillar=i,phase=3})
        end
        return function(at,phase,put)
            local beat=sin(at*1.6)
            for _,e in ipairs(anim)do
                if e.wing then if live(e,phase)then put(e.p,e.sh*CFrame.Angles(0,e.wing*.12*beat*(e.pair==1 and 1 or -1),.08*e.wing*(.5+.5*beat))*e.rel)end
                elseif e.orb then put(e.p,e.home*CFrame.new(0,.05*sin(at*1.2),0))
                elseif e.ray then put(e.p,CFrame.Angles(0,at*.15,0)*e.home);e.p.Transparency=.2+.4*(.5+.5*sin(at*1.8+e.ray*1.6))
                elseif e.shimmer then local k=(at*.45)%1;local s=e.shimmer;put(e.p,CFrame.new(s*(.35+k*1.6),y+.26,-.15+k*.05));e.p.Transparency=k^3
                elseif e.mote then local k=(at*.22+e.mote*.17)%1;put(e.p,e.home*CFrame.new(sin(at+e.mote)*.1,k*.6,0));e.p.Transparency=k^2*.9
                elseif e.halo then if live(e,phase)then put(e.p,CFrame.new(0,sin(at*1.2)*.04,0)*CFrame.Angles(0,at*.4,0)*e.home)end
                elseif e.pillar then if live(e,phase)then e.p.Transparency=.25+.35*(.5+.5*sin(at*2+e.pillar*1.57))end end
            end
        end
    elseif motif=='pixels'then
        local cyan,mag=trim,accent;local dark=base:Lerp(fill,.2)
        local plate=add('Screen',V(2.6,.02,2.6),CFrame.new(0,y+.006,0),dark);plate.Material=Enum.Material.Glass
        for i=0,17 do local p=add('Pixel',V(.3,.04,.3),CFrame.new(0,y+.03,0),i%3==0 and mag or i%3==1 and cyan or white,true);track(p,p.CFrame,{pixel=i})end
        for i=0,2 do track(glass(add('Scan',V(4.6,.015,.07),CFrame.new(0,y+.04,0),cyan,true),.45),CFrame.new(0,y+.04,0),{scan=i})end
        for i,o in ipairs({{-2.1,-2.1},{2.1,-2.1},{2.1,2.1},{-2.1,2.1}})do
            local cf=CFrame.new(o[1],y+.03,o[2]);track(add('Bracket',V(.5,.03,.08),cf,i%2==0 and cyan or mag,true),cf,{bracket=i})
        end
        for i=0,2 do local p=add('HotPixel',V(.14,.14,.14),CFrame.new(0,y+.08,0),white,true);track(p,p.CFrame,{hot=i})end
        track(add('ErrorBar',V(1.2,.03,.1),CFrame.new(0,y+.05,0),mag,true),CFrame.new(0,y+.05,0),{err=true})
        for i=0,5 do
            local w=.5+(i%3)*.2;local cf=CFrame.new(-1.3+i%3*1.3,y+.07,-.9+(i//3)*1.8)
            track(add('Chunk',V(w,.06,w*.6),cf,i%2==0 and dark:Lerp(cyan,.25)or dark:Lerp(mag,.25),false,2),cf,{chunk=i,phase=2})
        end
        for i=0,1 do track(glass(add('Ghost',V(1,.04,.6),CFrame.new(0,y+.09,0),i==0 and cyan or mag,true,2),.5),CFrame.new(0,y+.09,0),{ghost=i,phase=2})end
        local s=.65
        for i,ax in ipairs({{1,0},{0,1},{0,0}})do for _,a in ipairs({-1,1})do for _,b in ipairs({-1,1})do
            local pos,size
            if ax[1]==1 then pos=V(0,a*s,b*s);size=V(s*2,.04,.04)elseif ax[2]==1 then pos=V(a*s,0,b*s);size=V(.04,s*2,.04)else pos=V(a*s,b*s,0);size=V(.04,.04,s*2)end
            local cf=CFrame.new(pos);track(add('Wire',size,cf,cyan,true,3),cf,{wire=true,phase=3})
        end end end
        for i=0,5 do local cf=CFrame.new(-1.9+i*.76,y+.05,0);track(add('Code',V(.07,.03,.36),cf,i%2==0 and cyan or white,true,3),cf,{code=i,phase=3})end
        local function cell(n,salt)local h=(n*7919+salt*104729)%9973/9973;return h end
        return function(at,phase,put)
            local tick=floor(at*6);local burst=(tick%11)<(phase+1)
            for _,e in ipairs(anim)do
                if e.pixel then
                    local n=tick+e.pixel*13;local gx,gz=floor(cell(n,1)*8)-4,floor(cell(n,2)*8)-4
                    put(e.p,CFrame.new(gx*.3+.15,y+.03+(burst and .04 or 0),gz*.3+.15));e.p.Transparency=cell(n,3)<.25 and .85 or 0
                elseif e.scan then put(e.p,CFrame.new(0,y+.04,((at*.6+e.scan/3)%1)*4.4-2.2))
                elseif e.bracket then local j=burst and (e.bracket%2==0 and .08 or -.08)or 0;put(e.p,e.home*CFrame.new(j,0,0))
                elseif e.hot then local n=tick+e.hot*29;put(e.p,CFrame.new((cell(n,4)-.5)*3.6,y+.08,(cell(n,5)-.5)*3.6));e.p.Transparency=cell(n,6)<.4 and 1 or 0
                elseif e.err then local n=floor(at*2.5);put(e.p,CFrame.new((cell(n,7)-.5)*2.4,y+.05,(cell(n,8)-.5)*3.4))
                elseif e.chunk then if live(e,phase)then local n=floor(at*3)+e.chunk*5;put(e.p,e.home*CFrame.new((cell(n,9)<.4 and (cell(n,10)-.5)*.6 or 0),0,0))end
                elseif e.ghost then if live(e,phase)then put(e.p,CFrame.new((e.ghost*2-1)*(.06+.05*sin(at*9)),y+.09,(cell(tick,11)-.5)*.8))end
                elseif e.wire then if live(e,phase)then put(e.p,CFrame.new(0,y+1.15,0)*CFrame.Angles(at*.5,at*.7,0)*e.home)end
                elseif e.code then if live(e,phase)then put(e.p,CFrame.new(e.home.X,y+.05,((at*.9+e.code*.37)%1)*4.4-2.2))end end
            end
        end
    elseif motif=='abyss'then
        local teal,violet=trim,accent;local deep=base:Lerp(black,.2)
        local pool=disc('Abyss',1.9,.02,CFrame.new(0,y+.01,0),deep);pool.Material=Enum.Material.Glass
        glass((disc('AbyssGlow',2.05,.01,CFrame.new(0,y+.003,0),teal,true)),.62)
        for i=0,11 do local cf=CFrame.new(0,y+.03,0);track(glass(add('Caustic',V(.05,.015,.7),cf,teal,true),.35),cf,{caustic=i})end
        for i=0,9 do local a=i*.63+.4;local cf=CFrame.new(cos(a)*(.9+i%2*.6),y+.04,sin(a)*(.9+i%2*.6));track((ball('Spot',.1,cf,i%2==0 and violet or teal,true)),cf,{spot=i})end
        for i,o in ipairs({{-1.05,.75},{-.8,.75},{.85,-.95},{1.1,-.95}})do
            local cf=CFrame.new(o[1],y+.04,o[2]);track(add('DeepEye',V(.16,.03,.08),cf,teal:Lerp(white,.3),true),cf,{eye=i})
        end
        for i=0,2 do local cf=CFrame.new(-.6+i*.6,y+.05,.3);local p=ball('Bubble',.08,cf,teal:Lerp(white,.4),true);track(p,cf,{bubble=i})end
        for k=0,2 do
            local a=k/3*pi*2+.5
            for s=0,4 do
                local w=.24-s*.04
                track(add('Tentacle',V(w,w,.34),CFrame.identity,s==4 and violet or deep:Lerp(teal,.18+s*.06),s==4,2),CFrame.identity,{tent=k,s=s,a=a,phase=2})
            end
        end
        local eye={{'EyeGlow',.95,.01,y+.03,violet,true},{'Sclera',.7,.03,y+.05,teal:Lerp(white,.55),true},{'Iris',.44,.035,y+.07,violet,true}}
        for _,o in ipairs(eye)do local p,cf=disc(o[1],o[2],o[3],CFrame.new(0,o[4],0),o[5],o[6],3);if o[1]=='EyeGlow'then glass(p,.4)end;track(p,cf,{giant=o[1],phase=3})end
        track(add('Pupil',V(.12,.04,.62),CFrame.new(0,y+.095,0),black,false,3),CFrame.new(0,y+.095,0),{pupil=true,phase=3})
        track(ball('EyeGlint',.12,CFrame.new(-.14,y+.12,-.14),white,true,3),CFrame.new(-.14,y+.12,-.14),{glint=true,phase=3})
        for _,s in ipairs({-1,1})do track(add('Lid',V(1.5,.06,.5),CFrame.new(0,y+.13,s*.85),deep,false,3),CFrame.new(0,y+.13,s*.85),{lid=s,phase=3})end
        return function(at,phase,put)
            for _,e in ipairs(anim)do
                if e.caustic then
                    local a=e.caustic*.524+sin(at*.4+e.caustic)*.5;local r=.5+.9*(.5+.5*sin(at*.3+e.caustic*1.9))
                    put(e.p,CFrame.new(cos(a)*r,y+.03,sin(a)*r)*CFrame.Angles(0,a+at*.2,0));e.p.Transparency=.3+.4*(.5+.5*sin(at*1.3+e.caustic*2.3))
                elseif e.spot then e.p.Transparency=.55*(.5+.5*sin(at*1.4+e.spot*1.3))
                elseif e.eye then local b=(at*.35+(e.eye<=2 and 0 or .5))%1;local o=b<.06 and .15 or 1;e.p.Size=V(.16,.03,.08*o);put(e.p,e.home)
                elseif e.bubble then local k=(at*.4+e.bubble*.33)%1;put(e.p,e.home*CFrame.new(sin(at*2+e.bubble)*.05,k*.5,0));e.p.Transparency=k^2*.9
                elseif e.tent then if live(e,phase)then
                    local sway=sin(at*1.1+e.tent*2.1)*.35;local u=e.s/4
                    local r=1.95-u*.75;local ang=e.a+sway*u+u*u*1.2
                    local h=y+.06+sin(u*pi*.9)*.55
                    local pos=V(cos(ang)*r,h,sin(ang)*r);local u2=(e.s+1)/4;local r2=1.95-u2*.75;local a2=e.a+sway*u2+u2*u2*1.2
                    put(e.p,CFrame.lookAt(pos,V(cos(a2)*r2,y+.06+sin(u2*pi*.9)*.55,sin(a2)*r2)))
                end
                elseif e.lid then if live(e,phase)then local b=(at*.25)%1;local close=b<.05 and (1-abs(b/.05*2-1))or 0;put(e.p,CFrame.new(0,y+.13,e.lid*(.85-.5*close)))end
                elseif e.pupil then if live(e,phase)then local look=sin(at*.5)*.12;put(e.p,CFrame.new(look,y+.095,0));e.p.Size=V(.08+.06*(.5+.5*sin(at*.8)),.04,.62)end
                elseif e.giant=='Iris'then if live(e,phase)then put(e.p,CFrame.new(sin(at*.5)*.08,y+.07,0)*CFrame.Angles(0,0,pi/2))end
                elseif e.glint then if live(e,phase)then e.p.Transparency=.4*(.5+.5*sin(at*2.2))end end
            end
        end
    end
end
return M
