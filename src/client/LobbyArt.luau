local Models=require(script.Parent.BuildingModels)
local C=require(script.Parent.Parent.Core.CosmeticCatalog)
local M={}
function M.new(parent,mode)
    local v=Instance.new('ViewportFrame');v.Name='ToyIllustration';v.BackgroundTransparency=1;v.Ambient=Color3.fromRGB(120,132,150);v.LightColor=Color3.fromRGB(220,235,255);v.LightDirection=Vector3.new(-1,-2,-1);v.Parent=parent
    local cam=Instance.new('Camera');cam.FieldOfView=32;cam.CFrame=CFrame.lookAt(Vector3.new(10,10,14),Vector3.new(0,1,0));cam.Parent=v;v.CurrentCamera=cam
    local function toy(kind,style,x,z,scale)
        local m=Models.create(kind,C.get(style),1,false);m:ScaleTo(scale or 1);m:PivotTo(CFrame.new(x,0,z));m.Parent=v
    end
    if mode=='single'then toy('City','classic',0,0,1.4)
    elseif mode=='pvp'then toy('DefensePost','classic',-2,0);toy('DefensePost','copper',2,0)
    else toy('City','classic',-1.8,0);toy('DefensePost','arctic',2,0);toy('MissileSilo','copper',0,-4,.7)end
    return v
end
return M
