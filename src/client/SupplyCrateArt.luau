local G=require(script.Parent.ToyGeometry)
local Mesh=require(script.Parent.SupplyCrateMesh)
local Meshes=require(script.Parent.CosmeticMeshes)
local Art=require(script.Parent.CollectionArt)
local M={}
local rgb=Color3.fromRGB
M.tier={basic=1,epic=3,legendary=4,mythic=5}
M.colors=Mesh.box
local bodies={basic=rgb(66,74,70),epic=rgb(40,36,58),legendary=rgb(58,48,30),mythic=rgb(34,46,58)}
local trims={basic=rgb(70,77,74),epic=rgb(78,64,112),legendary=rgb(214,168,72),mythic=rgb(206,226,240)}
local function metal(p,reflect)p.Material=Enum.Material.Metal;p.Reflectance=reflect or .05;p.CastShadow=false;return p end
local function neon(p,c)p.Material=Enum.Material.Neon;p.Color=c;p.CastShadow=false;return p end
local function blocks(m,kind)
    local tier=M.tier[kind];local accent=M.colors[kind];local body=bodies[kind];local trim=trims[kind]
    metal(G.part(m,'Body',Vector3.new(6,4.2,4.4),CFrame.new(0,2.35,0),body,'armor'))
    for _,x in ipairs({-2.95,2.95})do for _,z in ipairs({-2.15,2.15})do metal(G.block(m,'Post',Vector3.new(.5,4.7,.5),CFrame.new(x,2.35,z),trim))end end
    for _,y in ipairs({.35,4.4})do metal(G.block(m,'Rail',Vector3.new(6.5,.42,4.9),CFrame.new(0,y,0),trim))end
    for _,z in ipairs({-1.5,1.5})do metal(G.block(m,'Skid',Vector3.new(6.8,.3,.7),CFrame.new(0,.08,z),rgb(24,30,39)))end
    for _,side in ipairs({-1,1})do metal(G.block(m,'Door',Vector3.new(2.84,3.7,.28),CFrame.new(side*1.46,2.3,-2.36),body:Lerp(trim,.18)))end
    neon(G.block(m,'Seam',Vector3.new(.12,3.7,.1),CFrame.new(0,2.3,-2.52),accent),accent)
    for _,x in ipairs({-2.7,2.7})do neon(G.block(m,'EdgeSeam',Vector3.new(.1,3.7,.1),CFrame.new(x,2.35,-2.42),accent),accent)end
    metal(G.block(m,'SealPlate',Vector3.new(4.4,.95,.2),CFrame.new(0,3.3,-2.6),rgb(24,30,39)))
    for i=1,4 do neon(G.cylinder(m,'SealLamp',.3,.16,CFrame.new(1.65-(i-1)*1.1,3.3,-2.74)*CFrame.Angles(math.pi/2,0,0),accent),accent)end
    metal(G.block(m,'HazardTrim',Vector3.new(6.2,.12,.06),CFrame.new(0,.35,-2.47),rgb(236,170,56)))
    if tier>=3 then
        for _,x in ipairs({-3,3})do for _,z in ipairs({-2.2,2.2})do metal(G.block(m,'CornerCap',Vector3.new(.9,.9,.9),CFrame.new(x,4.45,z)*CFrame.Angles(0,math.pi/4,0),trim),.1)end end
        for _,z in ipairs({-2.3,2.3})do neon(G.block(m,'LidBand',Vector3.new(5.4,.14,.14),CFrame.new(0,4.66,z),accent),accent)end
        for _,x in ipairs({-3.1,3.1})do neon(G.block(m,'LidBand',Vector3.new(.14,.14,3.6),CFrame.new(x,4.66,0),accent),accent)end
    end
    if tier>=4 then
        for _,side in ipairs({-1,1})do metal(G.block(m,'DoorPlate',Vector3.new(2.2,2.4,.08),CFrame.new(side*1.46,2,-2.53),trim),.2)end
        metal(G.block(m,'Crest',Vector3.new(1.6,1.6,.3),CFrame.new(0,5.2,0)*CFrame.Angles(0,0,math.pi/4),trim),.25)
        neon(G.block(m,'CrestCore',Vector3.new(.7,.7,.34),CFrame.new(0,5.2,0)*CFrame.Angles(0,0,math.pi/4),accent),accent)
    end
    m.WorldPivot=CFrame.identity
    local style={id='crate_'..kind,tier=tier,accent={math.floor(accent.R*255),math.floor(accent.G*255),math.floor(accent.B*255)},
        secondary={math.floor(trim.R*255),math.floor(trim.G*255),math.floor(trim.B*255)}}
    Art.apply(m,style,'crate',CFrame.new(0,4.7,0),2.6)
    if tier>=4 then local light=Instance.new('PointLight');light.Name='CrateGlow';light.Color=accent;light.Range=9;light.Brightness=tier>=5 and 1.4 or 1;light.Shadows=false;light.Parent=m.Body end
end
function M.model(kind)
    kind=M.tier[kind]and kind or 'basic'
    local m=Instance.new('Model');m.Name='SupplyCrate_'..kind;m.WorldPivot=CFrame.identity
    m:SetAttribute('CrateKind',kind)
    if Mesh.shopModel(m,kind)then return m end
    blocks(m,kind)
    Meshes.watchModel(Mesh.crateKey(kind),m,function()
        local pivot=m:GetPivot()
        for _,c in ipairs(m:GetChildren())do c:Destroy()end
        m.WorldPivot=CFrame.identity
        if Mesh.shopModel(m,kind)then m:PivotTo(pivot)end
    end)
    return m
end
function M.step(model,base,age,reduced)return Mesh.shopStep(model,base,age,reduced)end
return M
