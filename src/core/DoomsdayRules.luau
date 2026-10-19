-- SPDX-License-Identifier: AGPL-3.0-only
local M={}
M.config={warnSeconds=30,drainStartPercent=2,drainMaxPercent=5,drainRampSeconds=90,drainFloorPercent=5,floorStartPercent=40,floorDecaySeconds=90,rotDeathSeconds=150,rotGrainSeconds=10,rotSpecklePercent=15,warshipDrainStartPercent=1,warshipDrainMaxPercent=50,warshipDrainCurveExponent=8}
local schedules={normal={168,54},slow={240,70},fast={102,31},veryfast={36,8}}
local function schedule(p) return schedules[p.speed] or schedules.normal,p.teamGame and {300,600,1000,1500,2100,2800,3500} or {200,400,700,1100,1700,2500,3500} end
function M.basis(p,elapsed)
    if elapsed<=600 then return 0 end
    local s,levels=schedule(p);local t,prev=elapsed-600,0
    for i,target in ipairs(levels) do
        if t<s[1] then return prev+math.floor((target-prev)*t/s[1]) end;t-=s[1]
        local pause=i==#levels and 0 or s[2];if t<pause then return target end;t-=pause;prev=target
    end;return levels[#levels]
end
function M.required(p,land,elapsed) return land<=0 and 0 or math.floor(M.basis(p,elapsed)*land/10000) end
function M.floor(maximum,t,c)
    c=c or M.config;t=math.max(0,t);local span=c.floorStartPercent-c.drainFloorPercent
    local pct=span>0 and c.floorDecaySeconds>0 and t<c.floorDecaySeconds and c.floorStartPercent-math.floor(span*t/c.floorDecaySeconds) or c.drainFloorPercent
    return math.floor(maximum*pct/100)
end
function M.drain(maximum,t,c,exponent)
    c=c or M.config;t=math.max(0,t);exponent=exponent or 1;local r=c.drainRampSeconds;local span=c.drainMaxPercent-c.drainStartPercent;local pct=c.drainMaxPercent
    if r>0 and t<r then
        local grown=math.floor(span*t/r)
        if exponent>1 then local ratio=math.floor(t*1000000/r);local acc=1000000;for _=1,exponent do acc=math.floor(acc*ratio/1000000) end;grown=math.floor(span*acc/1000000) end
        pct=c.drainStartPercent+grown
    end;return math.max(1,math.floor(maximum*pct/100))
end
function M.quota(tiles,under,c) c=c or M.config;return (tiles<=0 or c.rotDeathSeconds<=0) and 0 or math.ceil(tiles/math.max(1,c.rotDeathSeconds-under)) end
local function imul(a,b)
    return bit32.band(bit32.band(a,65535)*bit32.band(b,65535)+(bit32.rshift(a,16)*bit32.band(b,65535)+bit32.band(a,65535)*bit32.rshift(b,16))%65536*65536,0xffffffff)
end
function M.speckle(x,y,salt) return bit32.rshift(bit32.band(imul(x,3242174889)+imul(y,2447445413)+imul(salt,0x9e3779b9),0xffffffff),16)%65536 end
function M.front(tile,salt)
    local h=bit32.bxor(imul(tile,0x27d4eb2d),imul(salt,0x9e3779b9));h=bit32.bxor(h,bit32.rshift(h,15));h=imul(h,0x2545f491);h=bit32.bxor(h,bit32.rshift(h,13));return bit32.rshift(h,16)%65536
end
return M
