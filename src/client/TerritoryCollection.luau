local Catalog=require(script.Parent.Parent.Core.CosmeticCatalog)
local Authored=require(script.Parent.TerritoryPatterns)
local M={}
local floor,sin,pi=math.floor,math.sin,math.pi
local band,bxor,rshift=bit32.band,bit32.bxor,bit32.rshift
local function mul(a,b)return ((a*rshift(b,16))%65536*65536+a*band(b,65535))%4294967296 end
local function hash(x,y,s)
    local h=bxor(mul(x+4099,0x27d4eb2d),mul(y+8209,0x165667b1),mul(s,0x9e3779b1))
    h=mul(bxor(h,rshift(h,15)),0x85ebca77);h=mul(bxor(h,rshift(h,13)),0xc2b2ae3d)
    return bxor(h,rshift(h,16))/4294967296
end
local lattice={}
local function lat(i,j,s)local k=s*65536+j*256+i;local v=lattice[k];if not v then v=hash(i,j,s);lattice[k]=v end;return v end
local function noise(x,y,c,p,s)
    local n=p//c;local gx,gy=x/c,y/c;local ix,iy=floor(gx),floor(gy);local fx,fy=gx-ix,gy-iy
    fx=fx*fx*(3-2*fx);fy=fy*fy*(3-2*fy)
    local a,b=lat(ix%n,iy%n,s),lat((ix+1)%n,iy%n,s);local d,e=lat(ix%n,(iy+1)%n,s),lat((ix+1)%n,(iy+1)%n,s)
    return (a+(b-a)*fx)+((d+(e-d)*fx)-(a+(b-a)*fx))*fy
end
local bayer={0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5}
local function tex(w,h)return {w=w,h=h,buf=buffer.create(w*h)}end
local function put(t,x,y,code)buffer.writeu8(t.buf,(y%t.h)*t.w+x%t.w,code)end
local eagle={
    '.....#.....',
    '#...###...#',
    '##..#.#..##',
    '###.###.###',
    '.#########.',
    '..#######..',
    '...#####...',
    '..#.###.#..',
    '.#...#...#.',
}
local build={}
function build.grid()
    local t=tex(32,32)
    for y=0,31 do for x=0,31 do
        local code=0
        if x==0 or y==0 then code=2 elseif x%8==0 or y%8==0 then code=1 end
        if (x<=2 or x>=30)and y==0 or (y<=2 or y>=30)and x==0 then code=3 end
        put(t,x,y,code)
    end end
    return t
end
function build.camo()
    local t=tex(96,96)
    for y=0,95 do for x=0,95 do
        local mx,my=x//2*2,y//2*2
        local n=noise(mx,my,24,96,11)*.62+noise(mx,my,12,96,23)*.38+(hash(mx,my,5)-.5)*.1
        put(t,x,y,n<.34 and 1 or n<.43 and 2 or n>.64 and 3 or 0)
    end end
    return t
end
function build.hex()
    local t=tex(24,14)
    local centers={}
    for i=-1,2 do for j=-1,2 do table.insert(centers,{24*i,14*j});table.insert(centers,{24*i+12,14*j+7})end end
    local function cell(x,y)
        local best,bi,bx,by=1e9,0,0,0
        for i,c in ipairs(centers)do local dx,dy=x+.5-c[1],y+.5-c[2];local d=dx*dx+dy*dy;if d<best then best,bi,bx,by=d,i,dx,dy end end
        return ((centers[bi][1]%24)*100+centers[bi][2]%14),bx,by
    end
    for y=0,13 do for x=0,23 do
        local id,dx,dy=cell(x,y)
        local edge=id~=cell(x+1,y)or id~=cell(x,y+1)
        local norm=math.max(math.abs(dy),math.abs(dx*.866+dy*.5),math.abs(dx*.866-dy*.5))
        put(t,x,y,edge and 1 or norm>4.4 and (dx+dy*1.4<0 and 2 or 3)or 0)
    end end
    for _,c in ipairs(centers)do for k=0,5 do
        local vx,vy=floor(c[1]+8*math.cos(k*pi/3)),floor(c[2]+8*sin(k*pi/3))
        if vx>=-1 and vx<=25 and vy>=-1 and vy<=15 then put(t,vx,vy,4)end
    end end
    return t
end
function build.eagle()
    local t=tex(40,32);local mask={}
    local function on(x,y)return mask[(y%32)*40+x%40]==true end
    for _,o in ipairs({{4,3},{24,19}})do for r,row in ipairs(eagle)do for col=1,#row do
        if row:sub(col,col)=='#'then mask[((o[2]+r-1)%32)*40+(o[1]+col-1)%40]=true end
    end end end
    for y=0,31 do for x=0,39 do
        local code=0
        if on(x,y)then code=on(x,y-1)and 2 or 4
        elseif on(x-1,y-1)then code=3
        elseif on(x+1,y)or on(x-1,y)or on(x,y+1)or on(x,y-1)then code=5
        elseif (x-y)%10==0 then code=1 end
        put(t,x,y,code)
    end end
    return t
end
function build.stars()
    local P=128;local t=tex(P,P)
    for y=0,P-1 do for x=0,P-1 do
        local v=sin(2*pi*(x+2*y)/P+1.2*sin(2*pi*(2*x-y)/P))
        local violet=sin(2*pi*(x-y)/P+.6)>.15
        local d=bayer[(y%4)*4+x%4+1]/16
        local code=0
        if v>.86 and (x+y//3)%3~=0 or v>.97 then code=violet and 4 or 2 elseif v>.58 or v>.3 and d<(v-.3)/.28 then code=violet and 3 or 1 end
        local dust=hash(x,y,90);if dust<.03 then code=dust<.01 and 12 or dust<.02 and 13 or 14 end
        put(t,x,y,code)
    end end
    local C=16;local n=P//C;local stars={}
    for j=0,n-1 do for i=0,n-1 do
        local r=hash(i,j,71);stars[j*n+i]={x=i*C+3+floor(hash(i,j,72)*10),y=j*C+3+floor(hash(i,j,73)*10),rank=r<.45 and 1 or r<.72 and 2 or 3,big=hash(i,j,74)<.45}
    end end
    local function star(i,j)return stars[(j%n)*n+i%n]end
    local function link(a,b,rank)
        local ax,ay=a.x,a.y;local bx,by=b.x+(b.x<a.x-P/2 and P or 0),b.y+(b.y<a.y-P/2 and P or 0)
        local steps=math.max(math.abs(bx-ax),math.abs(by-ay))
        for s=2,steps-2 do if s%2==0 then put(t,floor(ax+(bx-ax)*s/steps+.5),floor(ay+(by-ay)*s/steps+.5),4+rank)end end
    end
    for j=0,n-1 do for i=0,n-1 do
        local a=star(i,j)
        for k,o in ipairs({{1,0,.45},{0,1,.35},{1,1,.2}})do
            if hash(i,j,80+k)<o[3]then local b=star(i+o[1],j+o[2]);link(a,b,math.max(a.rank,b.rank))end
        end
    end end
    for _,s in pairs(stars)do
        if s.big then for _,d in ipairs({{1,0},{-1,0},{0,1},{0,-1}})do put(t,s.x+d[1],s.y+d[2],s.rank==1 and 11 or 15)end end
        put(t,s.x,s.y,7+s.rank)
    end
    return t
end
local textures={}
local function texture(motif)
    local t=textures[motif];if t==nil then t=build[motif]and build[motif]()or false;textures[motif]=t end;return t
end
local LIGHT,DARK=Color3.fromRGB(236,246,255),Color3.fromRGB(4,8,14)
local function rgb(a,fallback)return a and Color3.fromRGB(a[1],a[2],a[3])or fallback end
local ink={
    grid={{'light',.08},{'light',.15},{'light',.24}},
    camo={{'dark',.22},{'dark',.1},{'light',.12}},
    hex={{'light',.2},{'light',.08},{'dark',.13},{'accent',.5}},
    eagle={{'gold',.1},{'gold',.5},{'dark',.3},{'bright',.66},{'dark',.16}},
    stars={{'ice',{.18,.23,.28}},{'ice',{.32,.4,.48}},{'violet',{.3,.36,.42}},{'violet',{.48,.56,.64}},
        {'ice',{.36,.4,.46}},{'ice',{0,.4,.46}},{'ice',{0,0,.46}},
        {'ice',{.82,.88,.94}},{'ice',{0,.84,.92}},{'ice',{0,0,.9}},{'ice',{.5,.58,.68}},
        {'ice',{.3,.36,.44}},{'ice',{0,.34,.42}},{'ice',{0,0,.4}},{'ice',{0,.5,.6}}},
}
require(script.Parent.TerritoryVolume).install(build,ink,{hash=hash,noise=noise,tex=tex,put=put,bayer=bayer})
require(script.Parent.TerritoryVolume2).install(build,ink,{hash=hash,noise=noise,tex=tex,put=put,bayer=bayer})
require(script.Parent.TerritoryFlat).install(build,ink,{hash=hash,noise=noise,tex=tex,put=put,bayer=bayer})
local decoded={}
local function authored(set,name)
    local key=set..name;local t=decoded[key];if t then return t end
    local src=Authored[set][name];if not src then return nil end
    t={w=src.w,h=src.h,buf=buffer.create(src.w*src.h)};local s,buf=src.rle,t.buf
    local i,o,n,last=1,0,#src.rle,0
    while i<=n do
        local b=string.byte(s,i)
        if b>=65 and b<=90 then
            local c=0;while i<=n do b=string.byte(s,i);if b<65 or b>90 then break end;c=c*26+b-65;i+=1 end
            buffer.fill(buf,o,last,c);o+=c
        else last=b<=57 and b-48 or b-87;buffer.writeu8(buf,o,last);o+=1;i+=1 end
    end
    decoded[key]=t;return t
end
local specs={}
local function inks(s,table_,tones,phase)
    for code=1,35 do s.to[code]=LIGHT;s.k[code]=0 end
    for code,i in pairs(table_)do s.to[code]=tones[i[1]]or LIGHT;s.k[code]=type(i[2])=='table'and i[2][phase]or i[2]end
end
function M.spec(style,phase)
    local skin=style and style.id and Authored.skins[style.id]
    local motif=style and style.motif;if not skin and(not motif or not ink[motif])then return nil end
    phase=math.clamp(phase or 1,1,3);local key=tostring(style.id)..':'..phase
    local s=specs[key];if s then return s end
    local t=skin and authored('motifs',skin.motif)or texture(motif);if not t then return nil end
    local accent,trim=rgb(style.accent,LIGHT),rgb(style.secondary,LIGHT)
    local tones={light=LIGHT,dark=DARK,accent=accent,gold=accent,bright=trim:Lerp(accent,.35),ice=trim,teal=accent,violet=Color3.fromRGB(206,184,255),
        base=rgb(style.primary,DARK),trim=trim,hot=trim:Lerp(LIGHT,.4),fire=accent,white=LIGHT,black=Color3.fromRGB(3,3,9),corona=trim,
        cyan=Color3.fromRGB(120,236,255),magenta=Color3.fromRGB(236,130,255),
        pink=rgb(Authored.tones.pink),orchid=rgb(Authored.tones.orchid),gleam=rgb(Authored.tones.gleam)}
    s={motif=skin and skin.motif or motif,tier=style.tier,phase=phase,w=t.w,h=t.h,buf=t.buf,to={},k={}}
    if skin then
        inks(s,skin.ink,tones,phase)
        local b=authored('bands',skin.band)
        if b then s.band={w=b.w,h=b.h,buf=b.buf,to={},k={}};inks(s.band,skin.bandInk,tones,phase)end
    else for code,i in ipairs(ink[motif])do s.to[code]=tones[i[1]];s.k[code]=type(i[2])=='table'and i[2][phase]or i[2]end end
    specs[key]=s;return s
end
function M.bandRow(owned,x,y,rows)
    for k=2,rows+1 do
        if not(owned(x-k,y)and owned(x+k,y)and owned(x,y-k)and owned(x,y+k))then return k-2 end
    end
    return nil
end
local series={'carbon','cobalt','pulse','solaris','parallax'}
local function fallback(tier)return series[tier]and M.spec(Catalog.get(series[tier]..'_territory'),1)end
function M.pattern(c,tile,width,spec,row)
    if not spec or not tile then return c end
    if type(spec)~='table'then spec=fallback(spec);if not spec then return c end end
    local w=spec.w;local x=tile%width;local y=(tile-x)//width
    local b=row and spec.band
    if b then
        local code=buffer.readu8(b.buf,row*b.w+(x+y)%b.w)
        if code~=0 then local k=b.k[code];if k>0 then return c:Lerp(b.to[code],k)end end
    end
    local code=buffer.readu8(spec.buf,(y%spec.h)*w+x%w)
    if code==0 then return c end
    local k=spec.k[code];if not k or k==0 then return c end
    return c:Lerp(spec.to[code],k)
end
M.texture=texture
return M
