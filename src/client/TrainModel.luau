local G=require(script.Parent.ToyGeometry)
local M={}
local steel=Color3.fromRGB(95,112,128)
local dark=Color3.fromRGB(27,35,45)
local trim=Color3.fromRGB(176,190,200)
local glass=Color3.fromRGB(37,70,88)
local function build(role,color)
    role=role or 'Engine'
    local model=Instance.new('Model');model.Name='Train';model:SetAttribute('TrainType',role)
    local function b(n,size,pos,c,shape)
        local p=shape and G.part(model,n,Vector3.new(unpack(size)),CFrame.new(unpack(pos)),c,shape)or G.block(model,n,Vector3.new(unpack(size)),CFrame.new(unpack(pos)),c)
        p.CastShadow=false;return p
    end
    local root=b('MotionRoot',{.05,.05,.05},{0,0,0},dark);root.Transparency=1;model.PrimaryPart=root
    b('Underframe',{.80,.16,1.62},{0,.23,0},dark,'armor')
    for _,z in ipairs({-.55,.55})do
        b('Bogie',{.83,.18,.36},{0,.16,z},dark)
        for _,x in ipairs({-.43,.43})do
            local p=G.cylinder(model,'Wheel',.15,.11,CFrame.new(x,.15,z)*CFrame.Angles(0,0,-math.pi/2),dark)
            p.CastShadow=false;p.Material=Enum.Material.Metal
        end
    end
    for _,z in ipairs({-.90,.90})do b('Coupler',{.17,.10,.16},{0,.22,z},trim)end
    if role=='Carriage'then
        b('FreightBody',{.72,.52,1.45},{0,.58,0},color:Lerp(steel,.62),'armor')
        b('CargoRoof',{.74,.07,1.48},{0,.87,0},trim,'armor')
        for _,x in ipairs({-.375,.375})do b('OwnerStripe',{.025,.12,1.36},{x,.58,0},color)end
        for _,z in ipairs({-.53,0,.53})do b('RoofRib',{.72,.035,.055},{0,.925,z},steel)end
    else
        b('EngineBody',{.74,.57,1.35},{0,.60,.12},steel,'armor')
        b('Cab',{.74,.67,.57},{0,.66,-.47},color:Lerp(steel,.18),'armor')
        local nose=Instance.new('WedgePart');nose.Name='SlopedNose';nose.Size=Vector3.new(.74,.38,.26);nose.CFrame=CFrame.new(0,.49,-.84)*CFrame.Angles(0,math.pi,0)
        nose.Color=color;nose.Material=Enum.Material.SmoothPlastic;nose.Anchored=true;nose.CanCollide=false;nose.CanTouch=false;nose.CanQuery=false;nose.CastShadow=false;nose.Parent=model
        b('Windscreen',{.58,.20,.03},{0,.82,-.765},glass)
        b('CabRoof',{.79,.065,.66},{0,1.02,-.43},trim,'armor')
        b('EngineRoof',{.57,.05,.78},{0,.91,.34},dark,'armor')
        for _,x in ipairs({-.38,.38})do
            b('OwnerStripe',{.025,.14,1.22},{x,.55,.15},color)
            b('SideWindow',{.025,.19,.25},{x,.81,-.48},glass)
        end
        for _,z in ipairs({.10,.32,.54})do b('Vent',{.48,.035,.055},{0,.955,z},steel)end
        for _,x in ipairs({-.24,.24})do
            local lamp=b('Headlamp',{.10,.07,.025},{x,.46,-.972},role=='TailEngine'and color:Lerp(trim,.65)or Color3.fromRGB(245,228,181))
            lamp.Material=Enum.Material.Neon
        end
        b('Pilot',{.72,.10,.06},{0,.27,-.94},trim)
    end
    model:ScaleTo(.25)
    if role=='TailEngine'then
        for _,p in ipairs(model:GetDescendants())do if p:IsA('BasePart')and p~=root then p.CFrame=CFrame.Angles(0,math.pi,0)*p.CFrame end end
    end
    model:SetAttribute('MobileUnit',true);model:SetAttribute('BodyLength',.74)
    return model
end
local templates={}
function M.create(role,color)
    role=role or 'Engine'
    local key=role=='Carriage'and 'Carriage'or role=='TailEngine'and 'TailEngine'or 'Engine'
    local template=templates[key]
    if not template then template=build(key,Color3.new(1,1,1));templates[key]=template end
    local model=template:Clone();model:SetAttribute('TrainType',role)
    for _,p in ipairs(model:GetChildren())do if p:IsA('BasePart')then
        if p.Name=='OwnerStripe'or p.Name=='SlopedNose'then p.Color=color
        elseif p.Name=='FreightBody'then p.Color=color:Lerp(steel,.62)
        elseif p.Name=='Cab'then p.Color=color:Lerp(steel,.18)
        elseif p.Name=='Headlamp'and key=='TailEngine'then p.Color=color:Lerp(trim,.65)end
    end end
    return model
end
function M.templateCount()local n=0;for _ in pairs(templates)do n+=1 end;return n end
return M
