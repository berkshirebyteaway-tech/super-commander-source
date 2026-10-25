local M={}
local TWO_PI=2*math.pi
local EPS=1e-6
M.DASH=12;M.GAP=6;M.SPEED=14
local function norm(a)
    a=a%TWO_PI;if a<0 then a+=TWO_PI end;return a
end
function M.merge(intervals)
    local flat={}
    for _,it in ipairs(intervals)do
        if it[2]-it[1]>=TWO_PI-EPS then return {{0,TWO_PI}}end
        local s,e=norm(it[1]),norm(it[2])
        if e<s then table.insert(flat,{s,TWO_PI});table.insert(flat,{0,e})else table.insert(flat,{s,e})end
    end
    if #flat==0 then return flat end
    table.sort(flat,function(a,b)return a[1]<b[1]end)
    local out={};local cur={flat[1][1],flat[1][2]}
    for i=2,#flat do local it=flat[i]
        if it[1]<=cur[2]+EPS then cur[2]=math.max(cur[2],it[2])else table.insert(out,cur);cur={it[1],it[2]}end
    end
    table.insert(out,cur);return out
end
function M.uncovered(circles,i)
    local a=circles[i];local covered={}
    for j,b in ipairs(circles)do if j~=i and b.group==a.group then
        local dx,dy=b.x-a.x,b.y-a.y;local dSq=dx*dx+dy*dy
        if dSq<=EPS then
            if b.r>a.r+EPS or (math.abs(b.r-a.r)<=EPS and j<i)then return {}end
        else
            local diff=b.r-a.r
            if diff>=0 and dSq<=diff*diff+EPS then return {}end
            local maxDist=a.r+b.r
            if dSq<maxDist*maxDist-EPS and not(diff<0 and dSq<=diff*diff)then
                local d=math.sqrt(dSq)
                local cosPhi=(a.r*a.r+dSq-b.r*b.r)/(2*a.r*d)
                local phi=math.acos(math.clamp(cosPhi,-1,1));local theta=math.atan2(dy,dx)
                table.insert(covered,{theta-phi,theta+phi})
            end
        end
    end end
    local merged=M.merge(covered)
    if #merged==0 then return {{0,TWO_PI}}end
    local out={};local cursor=0
    for _,it in ipairs(merged)do
        if it[1]>cursor+EPS then table.insert(out,{cursor,it[1]})end
        cursor=math.max(cursor,it[2])
    end
    if cursor<TWO_PI-EPS then table.insert(out,{cursor,TWO_PI})end
    return out
end
function M.arcs(circles)
    local out={};for i=1,#circles do out[i]=M.uncovered(circles,i)end;return out
end
function M.dashes(a0,a1,r,phase,out,dash,gap)
    dash=dash or M.DASH;gap=gap or M.GAP;local period=dash+gap;local n=0
    if r<=0 or a1<=a0 then return 0 end
    local s0,s1=a0*r,a1*r
    local k=math.floor((s0+phase)/period)
    while true do
        local ds=k*period-phase;if ds>=s1 then break end
        local de=ds+dash
        local cs,ce=math.max(ds,s0),math.min(de,s1)
        if ce>cs then n+=1;out[2*n-1]=cs/r;out[2*n]=ce/r end
        k+=1
    end
    return n
end
return M
