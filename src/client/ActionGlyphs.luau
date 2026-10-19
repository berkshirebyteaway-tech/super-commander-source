local M={};local cache={}
local N,R=64,2.6
local sqrt,abs,max,min=math.sqrt,math.abs,math.max,math.min
local function seg(px,py,ax,ay,bx,by)
    local dx,dy=bx-ax,by-ay;local t=math.clamp(((px-ax)*dx+(py-ay)*dy)/(dx*dx+dy*dy),0,1)
    local x,y=px-ax-dx*t,py-ay-dy*t;return sqrt(x*x+y*y)
end
local function circle(px,py,cx,cy)local x,y=px-cx,py-cy;return sqrt(x*x+y*y)end
local function poly(px,py,pts)
    local d=math.huge;local inside=true;local n=#pts
    local sign=0
    for i=1,n do
        local a,b=pts[i],pts[i%n+1]
        d=min(d,seg(px,py,a[1],a[2],b[1],b[2]))
        local cross=(b[1]-a[1])*(py-a[2])-(b[2]-a[2])*(px-a[1])
        if cross~=0 then local s=cross>0 and 1 or -1;if sign==0 then sign=s elseif s~=sign then inside=false end end
    end
    return inside and -d or d
end
local function lines(px,py,list)local d=math.huge;for _,l in ipairs(list)do d=min(d,seg(px,py,l[1],l[2],l[3],l[4]))end;return d-R end
local function ring(px,py,cx,cy,r)return abs(circle(px,py,cx,cy)-r)-R end
local shapes={}
shapes.attack=function(x,y)
    return min(lines(x,y,{{19,45,49,15},{14,38,26,50},{19,45,12,52}}),lines(x,y,{{45,45,15,15},{50,38,38,50},{45,45,52,52}}))
end
shapes.transport=function(x,y)
    return min(lines(x,y,{{10,38,54,38},{10,38,18,50},{18,50,46,50},{46,50,54,38}}),lines(x,y,{{32,30,32,12},{24,20,32,12},{40,20,32,12}}))
end
shapes.build=function(x,y)
    return min(lines(x,y,{{17,49,35,31}}),poly(x,y,{{27,23},{39,11},{53,25},{41,37}})-.5)
end
shapes.demolish=function(x,y)
    return min(shapes.build(x,y),lines(x,y,{{12,12,52,52}}))
end
shapes.gold=function(x,y)
    return min(ring(x,y,32,32,21),lines(x,y,{{32,21,32,43},{26,26,38,26},{26,38,38,38}}))
end
shapes.troops=function(x,y)
    local dome=max(circle(x,y,32,38)-18,y-38)
    return min(dome,lines(x,y,{{9,40,55,40},{20,46,44,46}}))
end
shapes.detail=function(x,y)
    return min(ring(x,y,32,32,22),lines(x,y,{{32,30,32,44}}),circle(x,y,32,21)-3.6)
end
shapes.signal=function(x,y)
    return min(lines(x,y,{{20,11,20,54}}),poly(x,y,{{22,13},{48,22},{22,32}})-.5)
end
shapes.emoji=function(x,y)
    local smile=max(ring(x,y,32,32,12),35-y)
    return min(ring(x,y,32,32,22),circle(x,y,24,26)-3.6,circle(x,y,40,26)-3.6,smile)
end
shapes.alliance=function(x,y)
    return min(ring(x,y,24,32,12),ring(x,y,40,32,12))
end
shapes.rockets=function(x,y)
    local body=lines(x,y,{{20,44,42,22}})-3
    return min(body,poly(x,y,{{40,16},{50,14},{48,24}})-.5,lines(x,y,{{20,44,12,44},{20,44,20,52},{26,38,18,34},{26,38,30,46}}))
end
shapes.upgrade=function(x,y)
    return lines(x,y,{{18,36,32,22},{32,22,46,36},{18,50,32,36},{32,36,46,50}})
end
M.kinds={};for k in pairs(shapes)do table.insert(M.kinds,k)end
function M.raster(kind)
    local f=shapes[kind];if not f then return nil end
    local alpha=buffer.create(N*N)
    for py=0,N-1 do for px=0,N-1 do
        local d=f(px+.5,py+.5);buffer.writeu8(alpha,py*N+px,math.floor(math.clamp(.5-d,0,1)*255+.5))
    end end
    return alpha
end
local function image(kind)
    if cache[kind]~=nil then return cache[kind]end
    local ok,img=pcall(function()
        local alpha=M.raster(kind);if not alpha then return nil end
        local editable=game:GetService('AssetService'):CreateEditableImage({Size=Vector2.new(N,N)});if not editable then return nil end
        local pixels=buffer.create(N*N*4)
        for i=0,N*N-1 do buffer.writeu8(pixels,i*4,255);buffer.writeu8(pixels,i*4+1,255);buffer.writeu8(pixels,i*4+2,255);buffer.writeu8(pixels,i*4+3,buffer.readu8(alpha,i))end
        editable:WritePixelsBuffer(Vector2.zero,Vector2.new(N,N),pixels);return editable
    end)
    cache[kind]=ok and img or false;return cache[kind]
end
function M.create(parent,kind,size,color)
    local img=image(kind);if not img then return nil end
    local label=Instance.new('ImageLabel');label.Name='Glyph_'..kind;label.BackgroundTransparency=1;label.Size=UDim2.fromOffset(size,size)
    label.ScaleType=Enum.ScaleType.Fit;label.ImageContent=Content.fromObject(img);label.ImageColor3=color or Color3.new(1,1,1)
    label:SetAttribute('Available',true);label.ZIndex=parent.ZIndex+1;label.Parent=parent;return label
end
function M.swap(old,kind,tint)
    if not old then return old end
    local glyph=M.create(old.Parent,kind,math.max(old.Size.Y.Offset,26));if not glyph then return old end
    glyph.Position=old.Position;glyph.ZIndex=old.ZIndex;glyph.Visible=old.Visible;if tint then glyph:SetAttribute('Tint',tint)end
    old:Destroy();return glyph
end
return M
