local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local RunService=game:GetService("RunService")
local M={active=0,budget=12}
local UP=Vector3.yAxis
local FLAT=CFrame.Angles(0,0,math.pi/2)
local FLASH,FIRE,EMBER=Color3.fromRGB(255,244,214),Color3.fromRGB(255,150,58),Color3.fromRGB(214,92,40)
local SMOKE,SOOT,FOAM=Color3.fromRGB(104,108,116),Color3.fromRGB(56,60,66),Color3.fromRGB(214,236,248)

local function piece(parent,name,shape,size,cf,color,material,transparency)
    local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
    p.Material=material or Enum.Material.Neon;p.Color=color;p.Transparency=transparency or 0
    if shape=="sphere"then local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
    elseif shape=="cylinder"then p.Shape=Enum.PartType.Cylinder end
    p.Size=size;p.CFrame=cf;p.Parent=parent;return p
end
local function tween(o,time,goal,style,delay,direction)
    local t=TweenService:Create(o,TweenInfo.new(time,style or Enum.EasingStyle.Quad,direction or Enum.EasingDirection.Out,0,false,delay or 0),goal);t:Play();return t
end
local function claim(hold)
    if M.active>=M.budget then return false end
    M.active+=1;task.delay(hold,function()M.active=math.max(0,M.active-1)end);return true
end
local function folderOf(model)return model and model.Parent or workspace end

local function burst(parent,at,size,debrisColor,parts,smoke,scorch)
    local model=Instance.new("Model");model.Name="Destruction";model.Parent=parent
    local s=math.max(.6,size)
    local flash=piece(model,"Flash","sphere",Vector3.one*s*.35,CFrame.new(at+UP*s*.3),FLASH,Enum.Material.Neon,.15)
    tween(flash,.1,{Size=Vector3.one*s*.95});tween(flash,.26,{Transparency=1},Enum.EasingStyle.Quad,.06)
    local light=Instance.new("PointLight");light.Color=FIRE;light.Shadows=false;light.Range=math.min(20,s*4);light.Brightness=4;light.Parent=flash
    tween(light,.55,{Brightness=0})
    for i=1,3 do
        local a=i*2.1;local off=Vector3.new(math.cos(a),0,math.sin(a))*s*.14
        local ball=piece(model,"Fireball","sphere",Vector3.one*s*.3,CFrame.new(at+off+UP*s*.25),i==2 and EMBER or FIRE,Enum.Material.Neon,.05)
        tween(ball,.5,{Size=Vector3.one*s*(.55+i*.12),CFrame=CFrame.new(at+off*1.5+UP*s*(.4+i*.1))},Enum.EasingStyle.Quart,(i-1)*.04)
        tween(ball,.4,{Transparency=1,Color=SMOKE},Enum.EasingStyle.Quad,.22+(i-1)*.04)
    end
    for i=1,parts do
        local a=i/parts*math.pi*2+math.random()*.5;local out=Vector3.new(math.cos(a),0,math.sin(a))
        local chunk=piece(model,"Debris","block",Vector3.new(.22,.16,.2)*s*(.6+math.random()*.5),CFrame.new(at+UP*s*.3),debrisColor,Enum.Material.SmoothPlastic,0)
        local land=at+out*s*(.7+math.random()*.6)+UP*.05
        local apex=at:Lerp(land,.5)+UP*s*(.5+math.random()*.4)
        tween(chunk,.22,{CFrame=CFrame.new(apex)*CFrame.Angles(math.random()*3,math.random()*3,0)},Enum.EasingStyle.Quad)
        tween(chunk,.3,{CFrame=CFrame.new(land)*CFrame.Angles(math.random()*6,math.random()*6,0)},Enum.EasingStyle.Quad,.22,Enum.EasingDirection.In)
        tween(chunk,.6,{Transparency=1},Enum.EasingStyle.Quad,1.1)
    end
    for i=1,smoke do
        local drift=Vector3.new(math.cos(i*2.4),0,math.sin(i*2.4))*s*.25
        local puff=piece(model,"Smoke","sphere",Vector3.one*s*.3,CFrame.new(at+UP*s*.4),i==1 and SOOT or SMOKE,Enum.Material.SmoothPlastic,.5)
        tween(puff,1.9,{Size=Vector3.one*s*(.75+i*.18),CFrame=CFrame.new(at+drift+UP*s*(.9+i*.3))},Enum.EasingStyle.Quad,.15+(i-1)*.1)
        tween(puff,1.2,{Transparency=1},Enum.EasingStyle.Quad,.6+(i-1)*.1)
    end
    if scorch then
        local mark=piece(model,"Scorch","cylinder",Vector3.new(.04,s*1.1,s*1.1),CFrame.new(at+UP*.03)*FLAT,SOOT,Enum.Material.SmoothPlastic,.35)
        tween(mark,1.6,{Transparency=1},Enum.EasingStyle.Quad,1.6)
    end
    Debris:AddItem(model,3.4)
    return model
end
local function ring(parent,at,from,to,color,time)
    local r=piece(parent,"Shockwave","cylinder",Vector3.new(.05,from,from),CFrame.new(at)*FLAT,color,Enum.Material.Neon,.2)
    tween(r,time,{Size=Vector3.new(.05,to,to),Transparency=1},Enum.EasingStyle.Quart)
    Debris:AddItem(r,time+.1)
    return r
end
local function rubble(model)
    local best,volume=Color3.fromRGB(58,64,72),0
    for _,p in ipairs(model:GetDescendants())do
        if p:IsA("BasePart")and p.Transparency<.5 and p.Material~=Enum.Material.Neon then
            local n=p.Name;local v=p.Size.X*p.Size.Y*p.Size.Z
            if v>volume and not(n:find("Pad")or n:find("Owner")or n:find("Shadow")or n:find("Stripe"))then best,volume=p.Color,v end
        end
    end
    return best:Lerp(Color3.new(0,0,0),.25)
end

function M.building(model,reduced)
    if not model or not model.Parent then return end
    if reduced or not claim(2.2) then model:Destroy();return end
    local cf,size=model:GetBoundingBox();local at=Vector3.new(cf.Position.X,cf.Position.Y-size.Y/2,cf.Position.Z)
    local s=math.max(size.X,size.Z);local color=rubble(model)
    burst(folderOf(model),at,s,color,7,3,true)
    ring(folderOf(model),at+UP*.05,s*.4,s*1.9,FIRE,.6)
    task.delay(.08,function()model:Destroy()end)
end

function M.warship(model,reduced)
    if not model or not model.Parent then return end
    local cf,size=model:GetBoundingBox();local at=Vector3.new(cf.Position.X,cf.Position.Y-size.Y/2,cf.Position.Z)
    if reduced or not claim(3.2) then model:Destroy();return end
    local parent=folderOf(model);local s=math.max(size.X,size.Z)*.6
    for _,d in ipairs(model:GetDescendants())do if d:IsA("BillboardGui")or d:IsA("Trail")then d.Enabled=false end end
    burst(parent,at+UP*size.Y*.4,s,Color3.fromRGB(70,82,98),5,2,false)
    ring(parent,at+UP*.04,s*.5,s*3,FOAM,.9)
    local start=model:GetPivot();local length=size.Z;local sinkTime=2.6;local t0=os.clock()
    local parts={};for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then table.insert(parts,{p,p.Transparency})end end
    local conn;conn=RunService.Heartbeat:Connect(function()
        local t=math.clamp((os.clock()-t0)/sinkTime,0,1)
        if not model.Parent then conn:Disconnect();return end
        local e=t*t
        model:PivotTo(start*CFrame.new(0,-size.Y*1.6*e,length*.15*e)*CFrame.Angles(math.rad(-22)*math.min(1,t*1.6),0,math.rad(8)*t))
        if t>.55 then local f=(t-.55)/.45;for _,pt in ipairs(parts)do pt[1].Transparency=pt[2]+(1-pt[2])*f end end
        if t>=1 then conn:Disconnect();model:Destroy()end
    end)
    for i=1,5 do
        task.delay(.5+i*.32,function()
            if not parent.Parent then return end
            local off=Vector3.new((math.random()-.5)*s,0,(math.random()-.5)*s)
            local bubble=piece(parent,"Bubble","sphere",Vector3.one*s*.18,CFrame.new(at+off+UP*.05),FOAM,Enum.Material.Neon,.35)
            tween(bubble,.6,{Size=Vector3.one*s*.4,Transparency=1});Debris:AddItem(bubble,.7)
        end)
    end
end

function M.train(folder,position,reduced,color)
    if reduced or not position or not claim(1.6) then return end
    burst(folder or workspace,position,.8,color or Color3.fromRGB(20,26,34),4,1,false)
end

function M.intercept(folder,position,reduced)
    if reduced or not position or not claim(1.4) then return end
    local parent=folder or workspace
    local model=Instance.new("Model");model.Name="Interception";model.Parent=parent
    local flash=piece(model,"Flash","sphere",Vector3.one*.4,CFrame.new(position),FLASH,Enum.Material.Neon,.1)
    tween(flash,.08,{Size=Vector3.one*1.3});tween(flash,.22,{Transparency=1},Enum.EasingStyle.Quad,.06)
    local light=Instance.new("PointLight");light.Color=FLASH;light.Shadows=false;light.Range=10;light.Brightness=3;light.Parent=flash;tween(light,.4,{Brightness=0})
    local core=piece(model,"Fireball","sphere",Vector3.one*.3,CFrame.new(position),FIRE,Enum.Material.Neon,0)
    tween(core,.3,{Size=Vector3.one*1},Enum.EasingStyle.Quart);tween(core,.3,{Transparency=1,Color=SMOKE},Enum.EasingStyle.Quad,.12)
    for i=1,6 do
        local a=i/6*math.pi*2;local out=Vector3.new(math.cos(a),(i%2==0 and .4 or -.2),math.sin(a))
        local spark=piece(model,"Spark","sphere",Vector3.one*.24,CFrame.new(position),FIRE,Enum.Material.Neon,0)
        tween(spark,.5,{CFrame=CFrame.new(position+out*1.9),Size=Vector3.one*.06,Transparency=1},Enum.EasingStyle.Quart)
    end
    local puff=piece(model,"Smoke","sphere",Vector3.one*.3,CFrame.new(position),SMOKE,Enum.Material.SmoothPlastic,.55)
    tween(puff,1,{Size=Vector3.one*1.4,CFrame=CFrame.new(position+UP*.6)},Enum.EasingStyle.Quad,.15);tween(puff,.8,{Transparency=1},Enum.EasingStyle.Quad,.35)
    ring(model,position,.4,3.6,FLASH,.45)
    Debris:AddItem(model,1.3)
end

return M
