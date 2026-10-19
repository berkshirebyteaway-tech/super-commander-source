local Rig=require(script.Parent.ParachuteRig)
local C=require(script.Parent.Parent.Core.CosmeticCatalog)
local M={};local previews={};local budget=0;local time=0
game:GetService('RunService').RenderStepped:Connect(function(dt)
    budget+=dt;time+=dt;if budget<1/30 then return end;budget=0
    local count=0
    for view,v in pairs(previews)do
        local shown=view.Parent~=nil and view.AbsoluteSize.X>0;local parent=view.Parent
        while shown and parent and not parent:IsA('LayerCollector')do
            if parent:IsA('GuiObject')then shown=parent.Visible and(not parent.ClipsDescendants or view.AbsolutePosition.Y+view.AbsoluteSize.Y>=parent.AbsolutePosition.Y and view.AbsolutePosition.Y<=parent.AbsolutePosition.Y+parent.AbsoluteSize.Y)end
            parent=parent.Parent
        end
        if shown and(not parent or parent.Enabled)and count<12 then
            count+=1;v.rig:step(CFrame.new(1.35,-.7,0),time,0,1,0,nil,game.Players.LocalPlayer:GetAttribute('CommanderReducedEffects')==true)
        end
    end
end)
function M.create(parent,slot,style,opts)
    if slot=='commanderOrder'then return require(script.Parent.CollectionPreview).create(parent,{style=style,category='motion'})end
    local viewport=Instance.new('ViewportFrame');viewport.Name='WearablePreview';viewport.BackgroundTransparency=1;viewport.Ambient=Color3.fromRGB(150,163,181);viewport.LightColor=Color3.fromRGB(238,244,255);viewport.LightDirection=Vector3.new(-1,-2,-1);viewport.Parent=parent
    local model=Instance.new('Model');model.Name='CommanderPreview';model.Parent=viewport
    local function part(name,size,position,color)
        local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=CFrame.new(position);p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Parent=model;return p
    end
    model.PrimaryPart=part('HumanoidRootPart',Vector3.new(2,2.5,1),Vector3.zero,Color3.fromRGB(54,67,82))
    part('Head',Vector3.one*1.5,Vector3.new(0,2,0),Color3.fromRGB(218,227,236))
    for _,side in ipairs({-1,1})do part((side<0 and 'Left'or 'Right')..'Arm',Vector3.new(.75,2,.75),Vector3.new(side*1.35,.1,0),Color3.fromRGB(70,84,100));part((side<0 and 'Left'or 'Right')..'Leg',Vector3.new(.8,1.8,.8),Vector3.new(side*.5,-2,0),Color3.fromRGB(35,43,55))end
    local camera=Instance.new('Camera');camera.FieldOfView=36;camera.Parent=viewport;viewport.CurrentCamera=camera
    if slot=='commanderStandard'then
        local rig=require(script.Parent.CommanderStandardRig).new(viewport,style,Color3.fromRGB(54,226,208))
        rig:step(CFrame.new(1.35,-.7,0),0,0,1,0)
        previews[viewport]={rig=rig};viewport.Destroying:Once(function()previews[viewport]=nil;rig:destroy()end)
        camera.FieldOfView=26
        if opts and opts.flagOnly then
            model:Destroy()
            local ok,cf,size=pcall(function()return rig.model:GetBoundingBox()end)
            local center=ok and cf.Position+Vector3.new(0,size.Y*.16,0)or Vector3.new(1.9,2,0);local tall=ok and math.max(size.Y*.72,size.X*1.3)or 3.2
            local dist=tall*.5/math.tan(math.rad(camera.FieldOfView*.5))
            camera.CFrame=CFrame.lookAt(center+Vector3.new(dist*.32,dist*.12,dist*.94),center)
        else
            camera.CFrame=CFrame.lookAt(Vector3.new(2.5,2.9,6.5),Vector3.new(2.35,1.77,0))
        end
    elseif slot=='parachute'then
        local rig=Rig.new(model,style,Color3.fromRGB(54,226,208))
        rig:step(CFrame.new(),{visible=true,inflation=1,canopyPitch=0,canopyRoll=0,time=0},true)
        camera.CFrame=CFrame.lookAt(Vector3.new(13,9,21),Vector3.new(0,3,0))
    elseif slot~='vehicle'then
        local rgb=C.get(style).accent;local color=Color3.fromRGB(table.unpack(rgb))
        if style~='classic'then for i=1,9 do
            local p=part('TrailSwatch',Vector3.new(.42,.08,.8),Vector3.new(math.sin(i*.2)*1.6,.1,i*.65),color);p.Transparency=.2+i*.06
        end end
        camera.CFrame=CFrame.lookAt(Vector3.new(7,7,12),Vector3.new(0,0,1.7))
    else
        camera.CFrame=CFrame.lookAt(Vector3.new(7,5,12),Vector3.new(0,0,0))
    end
    return viewport
end
return M
