local C=if script then require(script.Parent.ConfigConstants) else require("./ConfigConstants")
local M={}
M.range=C.defensePostRange
M.fillDarken=.78;M.checkerDarken=.7
local function cellKey(cx,cy)return cx*65536+cy end
function M.build(units,width,previous)
    local posts={};local keys={}
    for _,u in ipairs(units or {})do if u.kind=="DefensePost"and not u.building then
        table.insert(posts,{x=u.tile%width,y=math.floor(u.tile/width),owner=u.owner,tile=u.tile})
    end end
    table.sort(posts,function(a,b)if a.tile~=b.tile then return a.tile<b.tile end;return a.owner<b.owner end)
    for i,p in ipairs(posts)do keys[i]=p.tile..':'..p.owner end
    local key=table.concat(keys,',')
    if previous and previous.key==key and previous.width==width then return previous end
    local cells={};local r=M.range
    for _,p in ipairs(posts)do
        local own=cells[p.owner];if not own then own={};cells[p.owner]=own end
        local k=cellKey(math.floor(p.x/r),math.floor(p.y/r));local list=own[k];if not list then list={};own[k]=list end
        table.insert(list,p)
    end
    return {key=key,posts=posts,cells=cells,width=width}
end
function M.covered(index,owner,tile)
    local own=index and index.cells[owner];if not own then return false end
    local width=index.width;local x,y=tile%width,math.floor(tile/width);local r=M.range;local r2=r*r
    local cx,cy=math.floor(x/r),math.floor(y/r)
    for i=-1,1 do for j=-1,1 do
        local list=own[cellKey(cx+i,cy+j)]
        if list then for _,p in ipairs(list)do local dx,dy=x-p.x,y-p.y;if dx*dx+dy*dy<=r2 then return true end end end
    end end
    return false
end
function M.checker(tile,width)return (tile%width+math.floor(tile/width))%2==1 end
function M.changed(old,new)
    local seen={};local out={}
    for _,p in ipairs(old and old.posts or {})do seen[p.tile..':'..p.owner]=p end
    for _,p in ipairs(new and new.posts or {})do local k=p.tile..':'..p.owner;if seen[k]then seen[k]=nil else table.insert(out,p)end end
    for _,p in pairs(seen)do table.insert(out,p)end
    return out
end
function M.each(post,width,height,visit)
    local r=M.range;local r2=r*r
    for dy=-r,r do local y=post.y+dy;if y>=0 and y<height then
        for dx=-r,r do local x=post.x+dx;if x>=0 and x<width and dx*dx+dy*dy<=r2 then visit(y*width+x)end end
    end end
end
return M
