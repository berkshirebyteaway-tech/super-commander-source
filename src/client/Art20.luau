local K=require(script.Parent.Kit20)
local M={}
local cache={}
local N=96

local function shieldPoints()
    local pts={Vector2.new(24,3),Vector2.new(41,9),Vector2.new(41,21)}
    local function cubic(p0,p1,p2,p3)
        for i=1,12 do local t=i/12;local u=1-t;table.insert(pts,p0*u*u*u+p1*3*u*u*t+p2*3*u*t*t+p3*t*t*t)end
    end
    cubic(Vector2.new(41,21),Vector2.new(41,32),Vector2.new(33.5,39.5),Vector2.new(24,44))
    cubic(Vector2.new(24,44),Vector2.new(14.5,39.5),Vector2.new(7,32),Vector2.new(7,21))
    table.insert(pts,Vector2.new(7,9))
    return pts
end
local function segDist(p,a,b)
    local ab=b-a;local t=math.clamp((p-a):Dot(ab)/math.max(1e-6,ab:Dot(ab)),0,1);return (a+ab*t-p).Magnitude
end
local function editable(size)
    local ok,img=pcall(function()return game:GetService('AssetService'):CreateEditableImage({Size=size})end)
    return ok and img or nil
end
local function shieldMasks()
    if cache.shield~=nil then return cache.shield end
    cache.shield=false
    local fillImg,strokeImg=editable(Vector2.new(N,N)),editable(Vector2.new(N,N))
    if not fillImg or not strokeImg then return false end
    local pts=shieldPoints();local n=#pts;local k=N/48
    local fb,sb=buffer.create(N*N*4),buffer.create(N*N*4)
    for y=0,N-1 do
        for x=0,N-1 do
            local p=Vector2.new((x+.5)/k,(y+.5)/k)
            local d=math.huge;local inside=false
            for i=1,n do
                local a,b=pts[i],pts[i%n+1]
                d=math.min(d,segDist(p,a,b))
                if (a.Y>p.Y)~=(b.Y>p.Y)and p.X<(b.X-a.X)*(p.Y-a.Y)/(b.Y-a.Y)+a.X then inside=not inside end
            end
            local sd=inside and -d or d
            local fa=math.clamp(.5-sd*k,0,1);local sa=math.clamp(.5-(math.abs(sd)-1.25)*k,0,1)
            local o=(y*N+x)*4
            buffer.writeu32(fb,o,0x00FFFFFF+math.floor(fa*255+.5)*0x1000000)
            buffer.writeu32(sb,o,0x00FFFFFF+math.floor(sa*255+.5)*0x1000000)
        end
    end
    local ok=pcall(function()fillImg:WritePixelsBuffer(Vector2.zero,Vector2.new(N,N),fb);strokeImg:WritePixelsBuffer(Vector2.zero,Vector2.new(N,N),sb)end)
    cache.shield=ok and {fill=fillImg,stroke=strokeImg}or false
    return cache.shield
end
local function image(parent,name,img,color,alpha)
    local l=K.make('ImageLabel',parent,{Name=name,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ImageColor3=color,ImageTransparency=alpha or 0,ScaleType=Enum.ScaleType.Stretch})
    pcall(function()l.ImageContent=Content.fromObject(img)end)
    return l
end
function M.shield(parent,name,size,color,tag)
    local f=K.make('Frame',parent,{Name=name or 'Emblem',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromOffset(size,size)})
    local masks=shieldMasks()
    if masks then
        image(f,'Fill',masks.fill,color,.82)
        image(f,'Edge',masks.stroke,color,0)
        local ts=math.max(11,math.floor(size*12/48+.5))
        local t=K.num(f,'Tag',tag~=''and tag or '····',ts,color,Enum.TextXAlignment.Center)
        K.box(t,0,math.floor(size*23.6/48-ts/2-3+.5),size,ts+6);t.TextTruncate=Enum.TextTruncate.None
    else
        local i=K.icon(f,'clan',size,color,'Icon');K.box(i,0,0,size,size)
    end
    return f
end

local function glowMask()
    if cache.glow~=nil then return cache.glow end
    cache.glow=false
    local G=64;local img=editable(Vector2.new(G,G));if not img then return false end
    local b=buffer.create(G*G*4)
    for y=0,G-1 do for x=0,G-1 do
        local dx,dy=(x+.5)/G*2-1,(y+.5)/G*2-1;local a=math.clamp(1-math.sqrt(dx*dx+dy*dy),0,1)
        buffer.writeu32(b,(y*G+x)*4,0x00FFFFFF+math.floor(a*255+.5)*0x1000000)
    end end
    local ok=pcall(function()img:WritePixelsBuffer(Vector2.zero,Vector2.new(G,G),b)end)
    cache.glow=ok and img or false
    return cache.glow
end
function M.glow(parent,name,color,alpha)
    local img=glowMask()
    local l=K.make('ImageLabel',parent,{Name=name or 'Glow',BackgroundTransparency=1,BorderSizePixel=0,ImageColor3=color,ImageTransparency=1-(alpha or .45),ScaleType=Enum.ScaleType.Stretch,Active=false})
    if img then pcall(function()l.ImageContent=Content.fromObject(img)end)else l.Visible=false end
    return l
end
return M
