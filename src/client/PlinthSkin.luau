local Style=require(script.Parent.SkinMapStyle)
local M={}
M.N=128
M.turn=0
local plinths={'Plinth'}
local function reach(n,rot)
    if n==0 then return 1,1,0,0 end
    local w,e=0,0;local x0,x1,y0,y1=1,-1,1,-1
    for k=0,n-1 do
        local x,y=math.cos(rot+2*math.pi*k/n),math.sin(rot+2*math.pi*k/n)
        w=math.max(w,math.abs(x));e=math.max(e,math.abs(x),math.abs(y))
        x0,x1,y0,y1=math.min(x0,x),math.max(x1,x),math.min(y0,y),math.max(y1,y)
    end
    return (x1-x0)/2,e,-(x0+x1)/2,-(y0+y1)/2
end
M.margin=1.04
M.minTier=4
local c3=Color3.fromRGB
M.tint={
    solaris_buildings={bezel=c3(214,168,72)},
    crown_buildings={bezel=c3(40,52,110)},
    diamond_buildings={bezel=c3(170,215,255),rim=c3(230,240,255),rim2=c3(150,200,250)},
}
local live=setmetatable({},{__mode='k'})
M.live=live
function M.clear(model)local o=model:FindFirstChild('SkinPlate');if o then o:Destroy()end end
function M.dress(model,kind,style,detailed)
    M.clear(model)
    if detailed==false then return end
    local skin=Style.spec(style);if not skin or skin.tier<M.minTier then return end
    local shape=require(script.Parent.StructureIcons).shapes[kind];if not shape then return end
    local base;for _,name in ipairs(plinths)do base=model:FindFirstChild(name);if base and base:IsA('BasePart')then break end;base=nil end
    if not base then return end
    local cf=model:GetPivot():ToObjectSpace(base.CFrame)
    local size=(cf-cf.Position):VectorToWorldSpace(base.Size)
    local sx=math.abs(size.X);local top=cf.Position.Y+math.abs(size.Y)/2
    local w,e,dx,dz=reach(shape[1],shape[2])
    local R=(sx/2)/w;local canvas=2*e*M.margin*R;local box=2*e*M.margin*.45*shape[3]
    local plate=Instance.new('Part');plate.Name='SkinPlate';plate.Anchored=true;plate.CanCollide=false;plate.CanQuery=false;plate.CanTouch=false
    plate.CastShadow=false;plate.Transparency=1;plate:SetAttribute('BaseTransparency',1)
    plate.Size=Vector3.new(canvas,.02,canvas)
    plate.CFrame=model:GetPivot()*CFrame.new(cf.Position.X+dx*R,top+.012,cf.Position.Z+dz*R)*CFrame.Angles(0,M.turn,0)
    local function decal(layer,motif,color,transparency)
        local img=Style.image(layer,kind,shape,box,motif,M.N);if not img then return end
        local d=Instance.new('Decal');d.Name='Skin'..layer;d.Face=Enum.NormalId.Top;d.Color3=color;d.Transparency=transparency
        local ok=pcall(function()d.TextureContent=Content.fromObject(img)end)
        if ok then d.Parent=plate;return d end
        d:Destroy()
    end
    local tint=M.tint[skin.id]or {}
    local glow=skin.prism and decal('glow',nil,skin.glow,.55)
    decal('bezel',nil,tint.bezel or skin.bezel,skin.bezelAlpha)
    local motif=decal('motif',skin.motif,skin.prism and Style.prism(.75)or skin.motifColor,skin.prism and .1 or skin.motifAlpha)
    decal('rim',nil,tint.rim or skin.rim,.05)
    if skin.double then decal('rim2',nil,tint.rim2 or skin.rim2,.15)end
    if #plate:GetChildren()==0 then plate:Destroy();return end
    plate.Parent=model
    if skin.prism and (motif or glow)then live[plate]={motif=motif,glow=glow}end
    return plate
end
local last=0
function M.step(now,reduced)
    if now-last<1/15 then return end;last=now
    for plate,p in pairs(live)do
        if not plate.Parent then continue end
        if p.motif then p.motif.Color3=reduced and Style.prism(.75)or Style.prism(now*.18+.75)end
        if p.glow then p.glow.Transparency=reduced and .55 or .5+.25*math.sin(now*2.4)end
    end
end
return M
