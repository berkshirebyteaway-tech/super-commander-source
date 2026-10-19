local Art=require(script.Parent.SkinMapArt)
local M={}
local images={}
local assets
local function rgb(a)return Color3.fromRGB(a[1],a[2],a[3])end
local function prism(h)
    local f=h%1;local tri=1-math.abs(2*f-1)
    return Color3.fromHSV(.45+.47*tri,.72-.6*math.max(0,(tri-.8)/.2),1)
end
M.prism=prism
local specs=setmetatable({},{__mode='k'})
function M.spec(style)
    if not style or not style.tier or not style.series then return nil end
    local s=specs[style];if s then return s end
    local tier=style.tier
    local P,S,A=rgb(style.primary),rgb(style.secondary),rgb(style.accent)
    s={tier=tier,id=style.id,motif=Art.motifs[style.series]or'stripes',primary=P,secondary=S,accent=A,
        rim=tier>=2 and A or S,rim2=S:Lerp(Color3.fromRGB(255,226,150),.5),
        bezel=P,bezelAlpha=0,motifColor=tier>=3 and A:Lerp(Color3.new(1,1,1),.25)or tier==2 and A or S,motifAlpha=({.3,.25,.15,.12,.08})[tier]or .3,
        glow=tier>=2 and A or nil,glowAlpha=tier>=5 and .2 or tier==4 and .3 or tier==3 and .38 or .55,
        double=tier>=4,gem=tier>=4,pulse=tier>=3,shine=tier>=4,prism=tier>=5,orbit=tier>=5}
    if s.prism then s.motifColor=prism(.75);s.motifAlpha=0 end
    specs[style]=s;return s
end
local function image(layer,key,shape,box,motif,size)
    local N=size or Art.N
    local id=layer..'|'..key..'|'..box..'|'..(motif or'')..'|'..N
    if images[id]==nil then
        local ok,img=pcall(function()
            assets=assets or game:GetService('AssetService')
            local im=assets:CreateEditableImage({Size=Vector2.new(N,N)})
            if not im then return nil end
            local px=buffer.create(N*N*4)
            for y=0,N-1 do for x=0,N-1 do
                local o=(y*N+x)*4;local a=Art.alpha(layer,shape,box,x,y,N,motif)
                buffer.writeu8(px,o,255);buffer.writeu8(px,o+1,255);buffer.writeu8(px,o+2,255);buffer.writeu8(px,o+3,math.floor(math.clamp(a,0,1)*255+.5))
            end end
            im:WritePixelsBuffer(Vector2.zero,Vector2.new(N,N),px);return im
        end)
        images[id]=ok and img or false
    end
    return images[id]
end
local function label(parent,name,size,z)
    local l=Instance.new('ImageLabel');l.Name=name;l.AnchorPoint=Vector2.new(.5,.5);l.Position=UDim2.fromScale(.5,.5)
    l.Size=UDim2.fromScale(size,size);l.BackgroundTransparency=1;l.ScaleType=Enum.ScaleType.Stretch;l.ZIndex=z;l.Visible=false;l.Parent=parent;return l
end
function M.attach(o)
    local h={o=o}
    h.glow=label(o.back,'SkinGlow',o.box*Art.glowZoom*(o.backScale or 1),o.backZ or 0)
    local grad=Instance.new('UIGradient');grad.Name='Sweep';grad.Enabled=false;grad.Parent=h.glow;h.glowGrad=grad
    h.bezel=label(o.front,'SkinBezel',o.frontScale or 1,o.frontZ or 1)
    h.motif=label(o.front,'SkinMotif',o.frontScale or 1,o.frontZ or 1)
    h.rim=label(o.front,'SkinRim',o.frontScale or 1,o.frontZ or 1)
    h.rim2=label(o.front,'SkinRim2',o.frontScale or 1,o.frontZ or 1)
    local shine=Instance.new('UIGradient');shine.Name='Shine';shine.Enabled=false;shine.Rotation=25;shine.Parent=h.rim;h.shine=shine
    local gem=Instance.new('Frame');gem.Name='SkinGem';gem.AnchorPoint=Vector2.new(.5,.5);gem.Rotation=45;gem.BorderSizePixel=0;gem.Visible=false;gem.ZIndex=o.topZ or 4;gem.Parent=o.top
    local gemLine=Instance.new('UIStroke');gemLine.Color=Color3.fromRGB(16,22,30);gemLine.Thickness=1;gemLine.Parent=gem;h.gem=gem
    local orbit=Instance.new('Frame');orbit.Name='SkinOrbit';orbit.AnchorPoint=Vector2.new(.5,.5);orbit.Position=UDim2.fromScale(.5,.5);orbit.Size=UDim2.fromScale(1.3,1.3);orbit.BackgroundTransparency=1;orbit.Visible=false;orbit.ZIndex=o.topZ or 4;orbit.Parent=o.top
    local spark=Instance.new('Frame');spark.Name='Spark';spark.AnchorPoint=Vector2.new(.5,.5);spark.Position=UDim2.fromScale(.5,0);spark.Size=UDim2.fromOffset(4,4);spark.BorderSizePixel=0;spark.ZIndex=o.topZ or 4;spark.Parent=orbit
    local round=Instance.new('UICorner');round.CornerRadius=UDim.new(.5,0);round.Parent=spark
    h.orbit=orbit;h.spark=spark
    return h
end
local shown=setmetatable({},{__mode='k'})
local function setImage(l,img)
    if not img then l.Visible=false;return false end
    if shown[l]~=img then l.ImageContent=Content.fromObject(img);shown[l]=img end
    return true
end
function M.apply(h,skin,key,shape,px,dots,faded,lift)
    h.skin=skin;h.px=px;h.faded=faded
    local box=h.o.box
    local show=skin~=nil
    local fade=faded and .45 or 0
    local glowOn=show and skin.glow~=nil and (not dots or skin.tier>=3)
    if glowOn and setImage(h.glow,image('glow',key,shape,box,nil,h.o.N))then
        h.glow.Visible=true;h.glow.ImageColor3=skin.glow;h.glow.ImageTransparency=math.min(1,skin.glowAlpha+fade+(dots and .15 or 0))
    else h.glow.Visible=false end
    h.glowGrad.Enabled=glowOn and skin.prism==true
    if h.glowGrad.Enabled then
        h.glowGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,prism(0)),ColorSequenceKeypoint.new(.33,prism(.3)),ColorSequenceKeypoint.new(.66,prism(.6)),ColorSequenceKeypoint.new(1,prism(.9))})
    end
    local detail=show and not dots
    if detail and setImage(h.bezel,image('bezel',key,shape,box,nil,h.o.N))then
        h.bezel.Visible=true;h.bezel.ImageColor3=skin.bezel;h.bezel.ImageTransparency=math.min(1,skin.bezelAlpha+fade)
    else h.bezel.Visible=false end
    if detail and setImage(h.motif,image('motif',key,shape,box,skin.motif,h.o.N))then
        h.motif.Visible=true;h.motif.ImageColor3=skin.motifColor;h.motif.ImageTransparency=math.min(1,skin.motifAlpha+fade)
    else h.motif.Visible=false end
    if detail and setImage(h.rim,image('rim',key,shape,box,nil,h.o.N))then
        h.rim.Visible=true;h.rim.ImageColor3=skin.rim;h.rim.ImageTransparency=math.min(1,.05+fade)
    else h.rim.Visible=false end
    h.shine.Enabled=h.rim.Visible and skin.shine==true
    if h.shine.Enabled then
        h.shine.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),ColorSequenceKeypoint.new(.42,Color3.new(1,1,1)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(255,255,235)),ColorSequenceKeypoint.new(.58,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))})
        h.shine.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.25),NumberSequenceKeypoint.new(.42,.25),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(.58,.25),NumberSequenceKeypoint.new(1,.25)})
    end
    if detail and skin.double and setImage(h.rim2,image('rim2',key,shape,box,nil,h.o.N))then
        h.rim2.Visible=true;h.rim2.ImageColor3=skin.rim2;h.rim2.ImageTransparency=math.min(1,.15+fade)
    else h.rim2.Visible=false end
    local gemOn=detail and skin.gem==true and px>=16
    h.gem.Visible=gemOn
    if gemOn then
        local g=math.max(5,math.floor(px*.26+.5));h.gem.Size=UDim2.fromOffset(g,g)
        h.gem.Position=UDim2.new(.5,0,.5,-math.floor(px*(lift or .5)+.5))
        h.gem.BackgroundColor3=skin.accent;h.gem.BackgroundTransparency=fade
    end
    h.orbit.Visible=detail and skin.orbit==true and px>=16
    if h.orbit.Visible then h.spark.BackgroundColor3=Color3.new(1,1,1);local d=math.max(3,math.floor(px*.13+.5));h.spark.Size=UDim2.fromOffset(d,d)end
    h.animated=show and (skin.pulse or skin.shine or skin.prism)or false
    if not h.animated then h.orbit.Rotation=0 end
    return h.animated
end
function M.step(h,now,reduced,phase)
    local skin=h.skin;if not skin or not h.animated then return end
    local t=now+(phase or 0)
    if reduced then
        if h.glow.Visible and skin.pulse then h.glow.ImageTransparency=math.min(1,skin.glowAlpha+(h.faded and .45 or 0))end
        return
    end
    local fade=h.faded and .45 or 0
    if skin.pulse then
        local wave=.5+.5*math.sin(t*(skin.tier>=4 and 3.2 or 2.4))
        if h.glow.Visible then h.glow.ImageTransparency=math.min(1,skin.glowAlpha+fade+.22*(1-wave))
        elseif h.motif.Visible then h.motif.ImageTransparency=math.min(1,skin.motifAlpha+fade+.2*(1-wave))end
    end
    if h.shine.Enabled then h.shine.Offset=Vector2.new(((t*.55)%1.6)-.8,0)end
    if skin.prism then
        local c=prism(t*.18);if h.rim.Visible then h.rim.ImageColor3=c end
        if h.rim2.Visible then h.rim2.ImageColor3=prism(t*.18+.5)end
        if h.gem.Visible then h.gem.BackgroundColor3=prism(t*.18+.25)end
        if h.motif.Visible then h.motif.ImageColor3=prism(t*.18+.75)end
        if h.glowGrad.Enabled then h.glowGrad.Rotation=(t*60)%360 end
        if h.orbit.Visible then h.orbit.Rotation=(t*90)%360 end
    end
end
function M.hide(h)
    h.skin=nil;h.animated=false
    h.glow.Visible=false;h.bezel.Visible=false;h.motif.Visible=false;h.rim.Visible=false;h.rim2.Visible=false;h.gem.Visible=false;h.orbit.Visible=false
end
return M
