--!native
-- SPDX-License-Identifier: AGPL-3.0-only
local S=if script then require(script.Parent.WaterSearch)else require('./WaterSearch')
local M={};M.__index=M
function M.new(g)return setmetatable({grid=g},M)end
local function trace(g,a,b,minMag,collect)
    local W=g.width;local x,y,tx,ty=a%W,a//W,b%W,b//W;local dx,dy=math.abs(tx-x),math.abs(ty-y)
    local sx,sy=if x<tx then 1 else -1,if y<ty then 1 else -1;local err=dx-dy;local out=collect and {}or nil;local iterations=0
    local function pass(t)local byte=buffer.readu8(g.terrain,t);return bit32.band(byte,128)==0 and bit32.band(byte,31)>=minMag end
    while true do
        iterations+=1;if iterations>100001 then return nil end
        local t=y*W+x;if not pass(t)then return nil end;if out then table.insert(out,t)end
        if x==tx and y==ty then return out or true end
        local e2=2*err;local moveX,moveY=e2>-dy,e2<dx
        if moveX and moveY then
            x+=sx;err-=dy
            if not pass(y*W+x)then
                x-=sx;err+=dy;y+=sy;err+=dx
                if not pass(y*W+x)then return nil end;if out then table.insert(out,y*W+x)end
                x+=sx;err-=dy
            else if out then table.insert(out,y*W+x)end;y+=sy;err+=dx end
        else if moveX then x+=sx;err-=dy end;if moveY then y+=sy;err+=dx end end
    end
end
function M:los(path,minMag)
    if #path<=2 then return path end
    local out={path[1]};local current=1
    while current<#path do
        local lo,hi,farthest=current+1,#path,current+1
        while lo<=hi do local mid=(lo+hi)//2
            if trace(self.grid,path[current],path[mid],minMag,false)then farthest=mid;lo=mid+1 else hi=mid-1 end
        end
        if farthest>current+1 then local points=trace(self.grid,path[current],path[farthest],0,true)
            if points then for i=2,#points-1 do table.insert(out,points[i])end end
        end
        current=farthest;if current<#path then table.insert(out,path[current])end
    end
    table.insert(out,path[#path]);return out
end
function M:refine(a,b)
    self.scratch=self.scratch or S.scratch(10000)
    local g=self.grid;local ax,ay,bx,by=a%g.width,a//g.width,b%g.width,b//g.width
    return S.bounded(g,self.scratch,a,b,math.max(0,math.min(ax,bx)-10),math.min(g.width-1,math.max(ax,bx)+10),math.max(0,math.min(ay,by)-10),math.min(g.height-1,math.max(ay,by)+10))
end
function M:smooth(path)
    if not path or #path==0 then return nil end
    local out=self:los(path,2);local index,d=1,0
    while index<#out and d<50 do d+=S.distance(self.grid,out[index],out[index+1]);index+=1 end
    if index>2 then local segment=self:refine(out[1],out[index]);if segment then
        local result={};for i=1,#segment-1 do table.insert(result,segment[i])end;for i=index,#out do table.insert(result,out[i])end;out=result
    end end
    index,d=#out,0
    while index>1 and d<50 do d+=S.distance(self.grid,out[index],out[index-1]);index-=1 end
    if index<#out-1 then local segment=self:refine(out[#out],out[index]);if segment then
        local result={};for i=1,index-1 do table.insert(result,out[i])end;for i=#segment,1,-1 do table.insert(result,segment[i])end;out=result
    end end
    return self:los(out,3)
end
return M
