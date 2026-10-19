local M={}
local Display=if script then require(script.Parent.MapPresentation)else require('./MapPresentation')
local candidates={}
for _,dx in ipairs({0,-108,108,-54,54})do for _,dy in ipairs({-12,-46,22,-80,56,90,-114,124,-148,158})do table.insert(candidates,{x=dx,y=dy})end end
table.sort(candidates,function(a,b)local aa,bb=a.x^2+a.y^2,b.x^2+b.y^2;return aa<bb or aa==bb and(a.y<b.y or a.y==b.y and a.x<b.x)end)
function M.place(px,py,w,h,blocks,occupied)
    for _,offset in ipairs(candidates)do
        local x=math.clamp(px+offset.x,54,math.max(54,w-54));local y=py+offset.y
        if y<32 or y>h-4 then continue end
        local clear=true
        for _,r in ipairs(blocks or {})do
            if math.abs(x-r.x)<(100+r.w)/2+4 and math.abs(y-14-r.y)<(28+r.h)/2+4 then clear=false;break end
        end
        if clear and Display.reserve(occupied,x,y-14,100,28,3)then return x,y end
    end
    return nil
end
function M.entries(operations,kinds)
    local out={}
    for _,op in ipairs(operations or {})do
        if op.kind~='land'or op.retreating or op.retreated or not op.troops or op.troops<=0 then continue end
        if op.direction=='outgoing'and op.target==0 then continue end
        if op.direction=='incoming'and kinds and kinds[op.owner]=='BOT'then continue end
        local tiles=op.frontTiles
        if tiles==nil then tiles=op.frontTile~=nil and {op.frontTile}or {}end
        for i,tile in ipairs(tiles)do if i>2 then break end
            table.insert(out,{key=tostring(op.owner)..':'..tostring(op.id)..':'..op.direction..':'..i,id=op.id,tile=tile,troops=op.troops,incoming=op.direction=='incoming'})
        end
    end
    table.sort(out,function(a,b)if a.incoming~=b.incoming then return a.incoming end;if a.troops~=b.troops then return a.troops>b.troops end;return a.key<b.key end)
    return out
end
function M.position(slot,now)
    local t=math.clamp((now-slot.at)/.25,0,1)
    return slot.x+(slot.toX-slot.x)*t,slot.y+(slot.toY-slot.y)*t
end
function M.move(slot,x,y,now)
    if not slot then return {x=x,y=y,toX=x,toY=y,at=now}end
    local cx,cy=M.position(slot,now)
    if (x-cx)^2+(y-cy)^2>200^2 then cx,cy=x,y end
    return {x=cx,y=cy,toX=x,toY=y,at=now}
end
function M.align(tiles,previous,width)
    local out=table.clone(tiles)
    if #out==2 and #previous==2 then
        local function d(a,b)return math.abs(a%width-b%width)+math.abs(math.floor(a/width)-math.floor(b/width))end
        if d(out[1],previous[2])+d(out[2],previous[1])<d(out[1],previous[1])+d(out[2],previous[2])then out[1],out[2]=out[2],out[1]end
    end
    return out
end
return M
