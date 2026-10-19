local G=require(script.Parent.ToyGeometry)
local M={}
local steel,deck,dark,light=Color3.fromRGB(70,82,98),Color3.fromRGB(48,58,70),Color3.fromRGB(20,26,34),Color3.fromRGB(214,222,230)
local surfaceY=require(script.Parent.Parent.Core.WorldGeometry).surfaceY
local lift={surface=.13,route=.15}
local function wakeTrail(part,name,half,y,z,colors,transparency,width,life,faceCamera)
    task.defer(function()
        if not part or not part.Parent then return end
        local size=part.Size
        local ly=type(y)=='number'and y*size.Y or 0
        if lift[y]then
            local model=part.Parent;local pivot=model:GetPivot().Y
            local ratio=model:GetScale()/(model:GetAttribute('BaseScale')or model:GetScale())
            ly=ratio*(surfaceY+lift[y]-pivot)-(part.Position.Y-pivot)
        end
        local a=Instance.new('Attachment');a.Name=name..'A';a.Position=Vector3.new(-half*size.X,ly,z*size.Z);a.Parent=part
        local b=Instance.new('Attachment');b.Name=name..'B';b.Position=Vector3.new(half*size.X,ly,z*size.Z);b.Parent=part
        local t=Instance.new('Trail');t.Name=name;t.Attachment0=a;t.Attachment1=b;t.FaceCamera=faceCamera==true;t.Lifetime=life
        t.Color=colors;t.Transparency=transparency;t.WidthScale=width;t.LightEmission=.15;t.MinLength=life>5 and .2 or .05;t.Parent=part
    end)
end
function M.create(kind,style,ownerColor,trainType)
    if kind=='Train'then return require(script.Parent.TrainModel).create(trainType,ownerColor or Color3.fromRGB(table.unpack(style.territory or style.primary)))end
    local model=Instance.new("Model");model.Name=kind
    local owner=ownerColor or Color3.fromRGB(table.unpack(style.territory or style.primary))
    local signal=Color3.fromRGB(table.unpack(style.accent))
    local function block(name,x,y,z,sx,sy,sz,c) return G.block(model,name,Vector3.new(sx,sy,sz),CFrame.new(x,y,z),c) end
    local function wedge(name,x,y,z,sx,sy,sz,c,rot)
        local w=Instance.new("WedgePart");w.Name=name;w.Size=Vector3.new(sx,sy,sz);w.CFrame=CFrame.new(x,y,z)*(rot or CFrame.identity);w.Color=c;w.Material=Enum.Material.SmoothPlastic
        w.Anchored=true;w.CanCollide=false;w.CanTouch=false;w.CanQuery=false;w.Parent=model;return w
    end
    if kind=="TransportShip" or kind=="TradeShip" or kind=="Warship" then
        local hull=kind=="TransportShip" and owner:Lerp(steel,.2) or steel
        block("Hull",0,.22,.15,1.0,.44,2.3,hull)
        wedge("Bow",0,.22,-1.3,1.0,.44,.6,hull,CFrame.Angles(0,math.pi,0))
        block("OwnerStripe",0,.4,.15,1.04,.08,2.32,owner)
        block("Deck",0,.47,.15,.86,.06,2.2,deck)
        if kind=="Warship" then
            block("Superstructure",0,.75,.35,.6,.5,.75,steel)
            block("BridgeGlass",0,.9,-.03,.5,.1,.02,signal).Material=Enum.Material.Neon
            G.cylinder(model,"Turret",.22,.16,CFrame.new(0,.58,-.65),steel)
            G.rod(model,"Barrel",Vector3.new(0,.62,-.75),Vector3.new(0,.64,-1.45),.06,dark)
            G.cylinder(model,"TurretAft",.18,.14,CFrame.new(0,.57,.95),steel)
            G.rod(model,"Mast",Vector3.new(0,1.0,.4),Vector3.new(0,1.75,.4),.03,light)
            block("Radar",0,1.6,.4,.4,.05,.12,light)
        elseif kind=="TradeShip" then
            block("Cabin",0,.8,.95,.7,.6,.5,light)
            for i=1,3 do block("Container"..i,0,.68,-.75+(i-1)*.5,.7,.36,.42,i==2 and owner or steel:Lerp(light,.3)) end
        else
            block("Cabin",0,.75,.9,.7,.5,.55,steel)
            block("LandingRamp",0,.52,-.6,.7,.1,.9,deck)
            for i=1,4 do block("Squad"..i,i%2==0 and .2 or -.2,.62,i<3 and -.75 or -.4,.18,.24,.18,owner:Lerp(dark,.3)) end
        end
        local hullPart=model:FindFirstChild("Hull")
        wakeTrail(hullPart,'Wake',.42,'surface',.48,ColorSequence.new(Color3.fromRGB(226,242,250),owner:Lerp(Color3.fromRGB(226,242,250),.55)),
            NumberSequence.new({NumberSequenceKeypoint.new(0,.25),NumberSequenceKeypoint.new(.4,.55),NumberSequenceKeypoint.new(1,1)}),
            NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,2.6)}),kind=="Warship"and 2.2 or 1.8)
        if kind=="TransportShip"then
            wakeTrail(hullPart,'Route',.2/1.0,'route',.45,ColorSequence.new(owner),NumberSequence.new(.41),NumberSequence.new(1),20)
        end
        block('StatusBeacon',0,1.03,.8,.16,.06,.12,light)
    elseif kind=="Shell" then
        local s=G.ball(model,"Shell",Vector3.one*.22,CFrame.identity,Color3.fromRGB(255,185,56));s.Material=Enum.Material.Neon
    else
        local size=kind=="HydrogenBomb" and 1.6 or kind=="MIRV" and 1.4 or kind=="SAMMissile" and .6 or kind=="MIRVWarhead" and .5 or 1
        G.rod(model,"Airframe",Vector3.new(0,0,-size*.8),Vector3.new(0,0,size*.7),size*.2,light)
        G.ball(model,"Nose",Vector3.new(.4,.4,.7)*size,CFrame.new(0,0,-size*.85),light)
        G.rod(model,"OwnerBand",Vector3.new(0,0,-size*.35),Vector3.new(0,0,-size*.15),size*.21,owner)
        for i=0,3 do G.block(model,"Fin",Vector3.new(size*.04,size*.42,size*.35),CFrame.new(0,0,size*.55)*CFrame.Angles(0,0,i*math.pi/2)*CFrame.new(0,size*.25,0),steel) end
        local tail=G.ball(model,"Exhaust",Vector3.one*size*.3,CFrame.new(0,0,size*.78),Color3.fromRGB(255,185,56));tail.Material=Enum.Material.Neon
        local half=(kind=="AtomBomb"or kind=="HydrogenBomb"or kind=="MIRV")and .35 or .12
        local a=Instance.new("Attachment");a.Position=Vector3.new(-half,0,0);a.Parent=tail
        local b=Instance.new("Attachment");b.Position=Vector3.new(half,0,0);b.Parent=tail
        local trail=Instance.new("Trail");trail.Attachment0=a;trail.Attachment1=b;trail.FaceCamera=true;trail.Lifetime=.55;trail.Color=ColorSequence.new(Color3.fromRGB(255,185,56),light);trail.Transparency=NumberSequence.new(0,1);trail.Parent=tail
    end
    for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") then p.CastShadow=false;if p.Name=='Mast'or p.Name=='Barrel'or p.Name=='CargoRoof'or p.Name=='Radar'then p.Material=Enum.Material.Metal;p.Reflectance=.025 end end end
    if kind=="Warship"then model:ScaleTo(1.35)elseif kind=="TransportShip"then model:ScaleTo(.85)elseif kind=="TradeShip"then model:ScaleTo(.07)end;model:SetAttribute('BaseScale',model:GetScale())
    model:SetAttribute("MobileUnit",true);return model
end
return M
