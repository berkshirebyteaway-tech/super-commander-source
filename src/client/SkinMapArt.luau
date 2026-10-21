--!strict
local M={}
M.N=64
M.motifs={carbon='stripes',cobalt='frost',pulse='scan',venom='bubbles',tidal='waves',ember='cracks',storm='bolts',
    solaris='lattice',crown='crown',phoenix='chevrons',parallax='rings',eclipse='rays',
    dragon='scales',diamond='facets',seraph='feathers',glitch='pixels',leviathan='tentacles'}
local function clamp(x:number,a:number,b:number):number return math.clamp(x,a,b)end
local function frac(x:number):number return x-math.floor(x)end
local function hash(a:number,b:number):number local x=math.sin(a*12.9898+b*78.233)*43758.5453;return x-math.floor(x)end
M.hash=hash
function M.sdf(n:number,rot:number,R:number,px:number,py:number):number
    local r=math.sqrt(px*px+py*py)
    if n==0 then return r-R end
    local an=math.pi/n
    local a=math.atan2(py,px)-rot;a=(a+an)%(2*an)-an
    return r*math.cos(a)-R*math.cos(an)
end
function M.top(n:number,rot:number):number
    if n==0 then return 1 end
    local an=math.pi/n;local a=-math.pi/2-rot;a=(a+an)%(2*an)-an
    return math.cos(an)/math.cos(a)
end
local function band(d:number,a:number,b:number):number return clamp(d-a+.5,0,1)*clamp(b-d+.5,0,1)end
local function lines(t:number,period:number,w:number):number
    local f=math.abs(frac(t/period)-.5)*period
    return clamp(w/2-(period/2-f)+.5,0,1)
end
function M.motif(name:string,px:number,py:number,N:number):number
    local s=N/64
    local x,y=px/s,py/s
    local r=math.sqrt(x*x+y*y);local a=math.atan2(y,x)
    if name=='stripes'then return lines(x+y,9,3.6)
    elseif name=='frost'then
        local cx,cy=math.floor(x/6),math.floor(y/6);local ox,oy=hash(cx,cy)*4+1,hash(cy,cx+7)*4+1
        local dx,dy=x-cx*6-ox,y-cy*6-oy;return clamp(1.6-math.sqrt(dx*dx+dy*dy),0,1)*(hash(cx+3,cy)>.35 and 1 or 0)
    elseif name=='scan'then return lines(y,4,1.4)
    elseif name=='bubbles'then
        local cx,cy=math.floor(x/9),math.floor(y/9);local rr=1.6+hash(cx,cy)*2.2
        local dx,dy=x-cx*9-4.5,y-cy*9-4.5;return band(math.sqrt(dx*dx+dy*dy)-rr,-1.1,0)
    elseif name=='waves'then return lines(y+math.sin(x*.42)*2.2,7,2)
    elseif name=='cracks'then
        local w=math.abs(math.sin(x*.31+math.sin(y*.23)*2.4)+math.sin(y*.37+x*.11))
        return clamp(1.2-w*3.2,0,1)
    elseif name=='bolts'then
        local zig=math.abs(frac(y/6)-.5)*6
        return lines(x+zig,11,2)
    elseif name=='lattice'then return math.max(lines(x+y,10,1.4),lines(x-y,10,1.4))
    elseif name=='crown'then
        local l=math.max(lines(x+y,12,1.2),lines(x-y,12,1.2))
        local gx,gy=frac((x+y)/24+.5)-.5,frac((x-y)/24+.5)-.5
        return math.max(l,clamp(2.2-math.sqrt(gx*gx+gy*gy)*24*.75,0,1))
    elseif name=='chevrons'then return lines(y+math.abs(x)*.9,8,2.6)
    elseif name=='rings'then return lines(r,6,1.6)
    elseif name=='scales'then
        local yy=y+math.sin(x*.2)*2;local row=math.floor(yy/6);local cx=x+(row%2)*4
        local dx,dy=(cx%8)-4,(yy%6)-6;return band(math.sqrt(dx*dx+dy*dy)-4,-1.2,0)
    elseif name=='facets'then
        return math.max(lines(x,11,1.1),lines(x*.5+y*.866,11,1.1),lines(x*.5-y*.866,11,1.1))
    elseif name=='feathers'then
        local t=a/(math.pi*2)*12;local f=math.abs(frac(t)-.5)*2;return lines(r+f*5,5,1.5)
    elseif name=='pixels'then
        local cx,cy=math.floor(x/4),math.floor(y/4);return hash(cx,cy)>.62 and 1 or 0
    elseif name=='tentacles'then
        local arm=math.abs(frac(a/(math.pi*2)*6+r*.035)-.5)*2
        return math.max(clamp(1.6-arm*7,0,1),lines(r,9,1)*.6)
    elseif name=='rays'then return clamp(1-math.abs(frac(a/(math.pi*2)*16)-.5)*2*3+.6,0,1)*clamp(r/6,0,1)
    end
    return 0
end
M.glowZoom=1.7
M.bezel={-6.6,-1.5}
function M.alpha(layer:string,spec:{number},box:number,x:number,y:number,N:number,motif:string?):number
    local zoom=layer=='glow'and M.glowZoom or 1
    local R=N*.45*spec[3]/box/zoom
    local px,py=x+.5-N/2,y+.5-N/2
    local d=M.sdf(spec[1],spec[2],R,px,py)
    local s=N/64
    if layer=='bezel'then return band(d,M.bezel[1]*s,M.bezel[2]*s)
    elseif layer=='rim'then return band(d,(M.bezel[1]-1.3)*s,(M.bezel[1]+.2)*s)
    elseif layer=='rim2'then return band(d,-4.7*s,-3.7*s)
    elseif layer=='glow'then
        local G=R*.55
        if d<=0 then return clamp(1+d/(R*.25),.35,1)end
        return clamp(1-d/G,0,1)^2
    elseif layer=='motif'then
        return band(d,M.bezel[1]*s,M.bezel[2]*s)*M.motif(motif or 'stripes',px,py,N)
    end
    return 0
end
return M
