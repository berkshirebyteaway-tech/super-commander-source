-- SPDX-License-Identifier: AGPL-3.0-only
local R=if script then require(script.Parent.PseudoRandom) else require("./PseudoRandom")
local M={}
local function round(x) return math.floor(x+.5) end
local function subdivide(ax,ay,bx,by,cx,cy,dx,dy,depth,st)
    local dist=math.abs(bx-ax)+math.abs(by-ay)+math.abs(cx-bx)+math.abs(cy-by)+math.abs(dx-cx)+math.abs(dy-cy)
    if dist<=256 or depth>=10 then
        local ex,ey=ax-st.x,ay-st.y;st.accum+=math.floor(math.sqrt(ex*ex+ey*ey));st.x=ax;st.y=ay
        if st.spacing then while st.accum>=st.spacing do table.insert(st.points,{x=math.floor((ax+128)/256),y=math.floor((ay+128)/256)});st.accum-=st.spacing end end
        return
    end
    local abx,aby=math.floor((ax+bx)/2),math.floor((ay+by)/2)
    local bcx,bcy=math.floor((bx+cx)/2),math.floor((by+cy)/2)
    local cdx,cdy=math.floor((cx+dx)/2),math.floor((cy+dy)/2)
    local abcX,abcY=math.floor((abx+bcx)/2),math.floor((aby+bcy)/2)
    local bcdX,bcdY=math.floor((bcx+cdx)/2),math.floor((bcy+cdy)/2)
    local mx,my=math.floor((abcX+bcdX)/2),math.floor((abcY+bcdY)/2)
    subdivide(ax,ay,abx,aby,abcX,abcY,mx,my,depth+1,st)
    subdivide(mx,my,bcdX,bcdY,cdx,cdy,dx,dy,depth+1,st)
end
function M.controls(w,h,src,dst,up,unbounded)
    local x,y=src%w,math.floor(src/w);local tx,ty=dst%w,math.floor(dst/w);local dx,dy=tx-x,ty-y
    local height=math.max(math.sqrt(dx*dx+dy*dy)/3,50)*(up==false and 1 or -1)
    local cy1,cy2=y+dy/4+height,y+dy*3/4+height
    if not unbounded then cy1=math.clamp(cy1,0,h-1);cy2=math.clamp(cy2,0,h-1) end
    return {{x=x,y=y},{x=x+dx/4,y=cy1},{x=x+dx*3/4,y=cy2},{x=tx,y=ty}}
end
function M.curve(p,speed)
    local st={x=round(p[1].x)*256,y=round(p[1].y)*256,accum=0,points={}}
    if speed then st.spacing=math.max(256,round(speed*256));table.insert(st.points,{x=round(p[1].x),y=round(p[1].y)}) end
    subdivide(st.x,st.y,round(p[2].x)*256,round(p[2].y)*256,round(p[3].x)*256,round(p[3].y)*256,round(p[4].x)*256,round(p[4].y)*256,0,st)
    local endpoint={x=round(p[4].x),y=round(p[4].y)}
    if speed then local last=st.points[#st.points];if not last or last.x~=endpoint.x or last.y~=endpoint.y then table.insert(st.points,endpoint) end;return st.points end
    local dx,dy=endpoint.x*256-st.x,endpoint.y*256-st.y;return (st.accum+math.floor(math.sqrt(dx*dx+dy*dy)))/256
end
function M.parabola(w,h,src,dst,speed,up)
    local points=M.curve(M.controls(w,h,src,dst,up),speed);local tiles={}
    for _,p in ipairs(points) do table.insert(tiles,p.y*w+p.x) end;return tiles
end
function M.mirvSpeed(w,h,src,dst)
    local ideal=M.curve(M.controls(w,h,src,dst,true,true))/15;local ticks=1400;local it=math.floor(ideal*100)
    if it>1400 then local diff=it-1400;ticks+=math.floor(math.sqrt(diff))*14+math.floor(diff*10/100)
    elseif it<1400 then ticks-=math.floor(math.sqrt(1400-it))*10 end
    ticks=math.max(100,ticks);local length=round(M.curve(M.controls(w,h,src,dst))*256)
    return math.max(1,math.floor((length*100+math.floor(ticks/2))/ticks)/256)
end
function M.air(width,src,dst,seed)
    local random=R.new(seed);local path={src};local x,y=src%width,math.floor(src/width);local tx,ty=dst%width,math.floor(dst/width)
    while x~=tx or y~=ty do
        local ratio=math.floor(1+math.abs(ty-y)/(math.abs(tx-x)+1))
        if x==tx then y+=y<ty and 1 or -1 elseif y==ty then x+=x<tx and 1 or -1
        elseif random:chance(ratio) then x+=x<tx and 1 or -1 else y+=y<ty and 1 or -1 end
        table.insert(path,y*width+x)
    end;return path
end
return M
