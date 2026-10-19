local M={}
local Display=require(script.Parent.Parent.Core.MapPresentation)
local rgb=Color3.fromRGB
M.outside=rgb(6,10,15)
local ocean,lake,grid=rgb(16,40,60),rgb(22,50,70),rgb(30,62,84)
local coastLand,coastSea=rgb(86,108,130),rgb(36,82,106)
local blocked,blockedHatch,blockedCut=rgb(13,15,19),rgb(19,22,27),rgb(30,37,47)
M.base={}
for b=0,255 do
    local mag=bit32.band(b,31);local c
    if bit32.band(b,128)==0 then c=(bit32.band(b,32)~=0 and ocean or lake):Lerp(coastSea,math.max(0,1-mag/12)*.18)
    elseif mag==31 then c=blocked
    elseif mag<10 then c=rgb(38,60,84):Lerp(rgb(42,64,88),mag/9)
    elseif mag<20 then c=rgb(66,78,102):Lerp(rgb(70,82,106),(mag-10)/9)
    else c=rgb(92,106,130):Lerp(rgb(102,116,140),(mag-20)/10)end
    M.base[b]=c
end
function M.color(map,t)
    local w,h=map.meta.width,map.meta.height;local x,y=t%w,math.floor(t/w);local data=map.terrain
    local b=buffer.readu8(data,t);local land=bit32.band(b,128)~=0;local c=M.base[b]
    local spacing=Display.gridStep(w,h)
    local function sample(dx,dy)
        if x+dx<0 or x+dx>=w or y+dy<0 or y+dy>=h then return 0 end
        return buffer.readu8(data,t+dy*w+dx)
    end
    local n,west,s,e=sample(0,-1),sample(-1,0),sample(0,1),sample(1,0)
    if land and bit32.band(b,31)==31 then
        return (x+y)%24<1 and blockedHatch or blocked
    end
    if land then
        if bit32.band(n,128)==0 or bit32.band(west,128)==0 or bit32.band(s,128)==0 or bit32.band(e,128)==0 then return coastLand end
        if bit32.band(n,159)==159 or bit32.band(west,159)==159 or bit32.band(s,159)==159 or bit32.band(e,159)==159 then return blockedCut end
        local mag=bit32.band(b,31)
        local slope=math.clamp((mag-bit32.band(n,31)+mag-bit32.band(west,31))*.004,-.03,.03)
        if slope>0 then c=c:Lerp(rgb(120,138,156),slope*4)elseif slope<0 then c=c:Lerp(rgb(24,30,38),-slope*4)end
        if x%spacing==0 or y%spacing==0 then c=c:Lerp(grid,.06)end
    else
        if bit32.band(n,128)~=0 or bit32.band(west,128)~=0 or bit32.band(s,128)~=0 or bit32.band(e,128)~=0 then return coastSea end
        if x%spacing==0 or y%spacing==0 then return c:Lerp(grid,.42)end
        local waveX=x%spacing
        if waveX>=spacing/3 and waveX<=spacing/3+10 and (y+math.abs(waveX-math.floor(spacing/3)-5)/2)%math.max(16,spacing/2)<1 then c=c:Lerp(coastSea,.3)end
    end
    return c
end
return M
