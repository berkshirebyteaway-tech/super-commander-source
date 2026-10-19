local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Themes=require(script.Parent.NukeThemes)
local features=require(script.Parent.Parent.Core.CollectionDefinitions).features
local M={}
local V=Vector3.new
local UP=Vector3.yAxis
local NEON,SMOOTH=Enum.Material.Neon,Enum.Material.SmoothPlastic
local k,out2,out4,hue=Themes.k,Themes.out2,Themes.out4,Themes.hue
local amber,steel,pale=Color3.fromRGB(255,185,56),Color3.fromRGB(70,82,98),Color3.fromRGB(214,222,230)
local function part(parent,name,size,cf,color,material,transparency,shape)
    return Themes.part(parent,name,size,cf,color,material or NEON,transparency,shape)
end
local function trail(parent,name,half,colors,life,transparency,width,emission)
    local a=Instance.new("Attachment");a.Name=name.."A";a.Position=V(-half,0,0);a.Parent=parent
    local b=Instance.new("Attachment");b.Name=name.."B";b.Position=V(half,0,0);b.Parent=parent
    local t=Instance.new("Trail");t.Name=name;t.Attachment0=a;t.Attachment1=b;t.FaceCamera=true;t.Lifetime=life
    t.Color=colors;t.Transparency=transparency;t.WidthScale=width;t.LightEmission=emission;t.MinLength=.05;t.Parent=parent
    return t
end
local function prism(n)
    local keys={};for i=0,n do table.insert(keys,ColorSequenceKeypoint.new(i/n,hue(i/n)))end
    return ColorSequence.new(keys)
end
local phone
local function sparkCap(tier)
    if phone==nil then local ok,r=pcall(function()local U=game:GetService("UserInputService");return U.TouchEnabled and not U.KeyboardEnabled end);phone=ok and r==true end
    local f=features[tier or 0];return f and (phone and f.particlesPhone or f.particlesPC)or 0
end

local live,beat={},nil
local function tick()
    local now=os.clock()
    for h in pairs(live)do
        if not h.model.Parent or h.step(now-h.t0)==false then live[h]=nil;h.model:Destroy()end
    end
    if next(live)==nil and beat then beat:Disconnect();beat=nil end
end
local function track(model,step)
    live[{model=model,step=step,t0=os.clock()}]=true
    if not beat then local ok,c=pcall(function()return RunService.Heartbeat:Connect(tick)end);beat=ok and c or nil end
end
M.live=function()local n=0;for _ in pairs(live)do n+=1 end;return n end

function M.interceptor(warhead,trailSkin,owner)
    local tier=warhead and warhead.tier or 0
    local skinned=warhead~=nil and (warhead.collection~=nil or tier>0)
    local body=skinned and warhead.body or pale
    local nose=skinned and warhead.nose or pale
    local fins=skinned and (tier>=4 and warhead.trim or warhead.fins) or steel
    local glow=skinned and warhead.glow or amber
    local model=Instance.new("Model");model.Name="SAMMissile"
    local s=.62
    part(model,"Airframe",V(1.3*s,.2*s,.2*s),CFrame.new(0,0,.05*s)*CFrame.Angles(0,math.pi/2,0),body,SMOOTH,0,"cyl")
    part(model,"Nose",V(.22,.22,.42)*s,CFrame.new(0,0,-.72*s),tier>=2 and glow or nose,tier>=2 and NEON or SMOOTH,0,"ell")
    part(model,"OwnerBand",V(.16*s,.215*s,.215*s),CFrame.new(0,0,-.28*s)*CFrame.Angles(0,math.pi/2,0),owner or pale,SMOOTH,0,"cyl")
    for i=0,3 do part(model,"Fin",V(.04*s,.4*s,.3*s),CFrame.new(0,0,.55*s)*CFrame.Angles(0,0,i*math.pi/2+math.pi/4)*CFrame.new(0,.2*s,0),fins,tier>=4 and NEON or SMOOTH,0)end
    local tail=part(model,"Exhaust",V(.3,.3,.3)*s,CFrame.new(0,0,.75*s),glow,NEON,0,"ball")
    local core=trailSkin and trailSkin.core or Color3.fromRGB(255,236,170)
    local hot=trailSkin and trailSkin.hot or amber
    local smoke=trailSkin and trailSkin.smoke or Color3.fromRGB(176,180,188)
    trail(tail,"CoreTrail",.16,tier>=5 and prism(5) or ColorSequence.new(core,hot),.5,NumberSequence.new(0,1),NumberSequence.new(1,.25),1)
    trail(tail,"SmokeTrail",.22,ColorSequence.new(smoke),2.4,
        NumberSequence.new({NumberSequenceKeypoint.new(0,.5),NumberSequenceKeypoint.new(.2,.45),NumberSequenceKeypoint.new(1,1)}),
        NumberSequence.new({NumberSequenceKeypoint.new(0,.6),NumberSequenceKeypoint.new(1,2.6)}),0)
    if skinned and tier>=3 then
        local ribbon=trailSkin and (trailSkin.ribbon or trailSkin.hot) or glow
        trail(tail,"Ribbon",.07,ColorSequence.new(core,ribbon),.85,NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}),NumberSequence.new(1,.4),1)
        local light=Instance.new("PointLight");light.Name="EngineLight";light.Color=warhead.light or glow;light.Brightness=1.6;light.Range=4;light.Shadows=false;light.Parent=tail
    end
    if skinned and tier>=4 then
        local cap=sparkCap(tier)
        if cap>0 then
            local e=Instance.new("ParticleEmitter");e.Name="Sparks"
            e.Color=ColorSequence.new(warhead.trim or glow,trailSkin and (trailSkin.ember or trailSkin.star or trailSkin.ribbon) or glow)
            e.LightEmission=1;e.Size=NumberSequence.new(.22,0);e.Lifetime=NumberRange.new(.25,.45);e.Speed=NumberRange.new(.5,1.5)
            e.SpreadAngle=Vector2.new(180,180);e.Rate=math.min(40,cap/4);e.Transparency=NumberSequence.new(0,1);e.Parent=tail
        end
    end
    if skinned and tier>=5 then
        part(model,"Halo",V(.03*s,.62*s,.62*s),CFrame.new(0,0,.1*s)*CFrame.Angles(0,math.pi/2,0),warhead.trim or glow,NEON,.55,"cyl")
    end
    for _,p in ipairs(model:GetChildren())do if p:IsA("BasePart")then p.CastShadow=false end end
    model:SetAttribute("MobileUnit",true);model:SetAttribute("InterceptorTier",skinned and tier or 0)
    model.WorldPivot=CFrame.identity
    return model
end
function M.setReduced(model,reduced)
    for _,t in ipairs(model:GetDescendants())do
        if t:IsA("Trail")then t.Enabled=not reduced or t.Name=="CoreTrail";if not t:GetAttribute("FullLife")then t:SetAttribute("FullLife",t.Lifetime)end;t.Lifetime=reduced and .12 or t:GetAttribute("FullLife")
        elseif t:IsA("ParticleEmitter")then t.Enabled=not reduced
        elseif t:IsA("PointLight")then t.Enabled=not reduced end
    end
end

function M.lock(adornee,color,reduced)
    if not adornee then return nil end
    local gui=Instance.new("BillboardGui");gui.Name="InterceptLock";gui.Size=UDim2.fromOffset(46,46);gui.AlwaysOnTop=true;gui.LightInfluence=0;gui.MaxDistance=1e5;gui.Adornee=adornee
    local stage=Instance.new("Frame");stage.Name="Stage";stage.AnchorPoint=Vector2.new(.5,.5);stage.Position=UDim2.fromScale(.5,.5);stage.Size=UDim2.fromScale(1,1);stage.BackgroundTransparency=1;stage.Rotation=reduced and 0 or 45;stage.Parent=gui
    local scale=Instance.new("UIScale");scale.Scale=reduced and 1 or 1.9;scale.Parent=stage
    local bars={}
    for i=0,3 do
        local sx,sy=i%2==0 and 0 or 1,i<2 and 0 or 1
        for j=0,1 do
            local b=Instance.new("Frame");b.Name="Bracket";b.BorderSizePixel=0;b.BackgroundColor3=color;b.AnchorPoint=Vector2.new(sx,sy)
            b.Position=UDim2.fromScale(sx,sy);b.Size=j==0 and UDim2.fromOffset(13,3) or UDim2.fromOffset(3,13);b.Parent=stage
            local edge=Instance.new("UIStroke");edge.Color=Color3.fromRGB(16,22,30);edge.Thickness=1;edge.Transparency=.35;edge.Parent=b
            table.insert(bars,b)
        end
    end
    local dot=Instance.new("Frame");dot.Name="Pip";dot.AnchorPoint=Vector2.new(.5,.5);dot.Position=UDim2.fromScale(.5,.5);dot.Size=UDim2.fromOffset(4,4);dot.Rotation=45;dot.BorderSizePixel=0;dot.BackgroundColor3=color;dot.Parent=stage
    gui.Parent=adornee
    if not reduced then
        TweenService:Create(scale,TweenInfo.new(.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
        TweenService:Create(stage,TweenInfo.new(.22,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Rotation=0}):Play()
        task.delay(.24,function()
            if not gui.Parent then return end
            TweenService:Create(scale,TweenInfo.new(.16,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Scale=.82}):Play()
            for _,b in ipairs(bars)do TweenService:Create(b,TweenInfo.new(.16,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{BackgroundTransparency=.45}):Play()end
        end)
    end
    return gui
end

local launches=0
function M.launch(folder,position,trailSkin,reduced)
    if reduced or launches>=6 then return end
    launches+=1;task.delay(1.2,function()launches=math.max(0,launches-1)end)
    local model=Instance.new("Model");model.Name="SAMLaunch";model.Parent=folder or workspace
    local core=trailSkin and trailSkin.core or Color3.fromRGB(255,236,170)
    local smoke=trailSkin and trailSkin.smoke or Color3.fromRGB(176,180,188)
    local flash=part(model,"Flash",V(.5,.5,.5),CFrame.new(position+UP*.4),core,NEON,0,"ell")
    local puffs={}
    for i=1,3 do puffs[i]=part(model,"Puff",V(.5,.5,.5),CFrame.new(position+UP*.3),smoke,SMOOTH,.35,"ell")end
    track(model,function(t)
        local f=out2(k(t,0,.22));flash.Size=Vector3.one*(.5+1.3*f);flash.Transparency=f
        for i,p in ipairs(puffs)do
            local a=out2(k(t,0,1.1));local dir=V(math.cos(i*2.1),.5,math.sin(i*2.1))
            p.CFrame=CFrame.new(position+UP*.3+dir*.9*a);p.Size=Vector3.one*(.5+1.1*a);p.Transparency=.35+.65*out2(k(t,.35,1.1))
        end
        return t<1.15
    end)
end

local full,bursts=0,0
function M.kill(folder,position,killer,victim,victimTrail,weapon,reduced,zoom)
    if reduced or not position or bursts>=10 then return end
    local light=weapon=="MIRVWarhead" and full>=2 or full>=4
    if not light then full+=1;task.delay(1.4,function()full=math.max(0,full-1)end)end
    bursts+=1;task.delay(1.45,function()bursts=math.max(0,bursts-1)end)
    local cam=workspace.CurrentCamera
    if not zoom and cam then
        local dist=(cam.CFrame.Position-position).Magnitude
        local perStud=cam.ViewportSize.Y/math.max(1e-3,2*dist*math.tan(math.rad(cam.FieldOfView)/2))
        zoom=70/math.max(1e-3,7.4*perStud)
    end
    local z=math.clamp(zoom or 1,1,6)
    local tier=killer and killer.tier or 0
    local flashC=killer and killer.flash or Color3.fromRGB(255,244,214)
    local fireC=killer and killer.fire or Color3.fromRGB(255,150,58)
    local coreC=killer and killer.core or Color3.fromRGB(255,238,186)
    local ringC=killer and (killer.ring or killer.shock) or Color3.fromRGB(255,236,204)
    local model=Instance.new("Model");model.Name="Interception";model.Parent=folder or workspace
    local facing=cam and CFrame.lookAt(position,cam.CFrame.Position).Rotation or CFrame.identity
    local flash=part(model,"Flash",V(.4,.4,.4)*z,CFrame.new(position),flashC,NEON,0,"ell")
    if not light then local l=Instance.new("PointLight");l.Color=flashC;l.Range=10*z;l.Brightness=3;l.Shadows=false;l.Parent=flash end
    local fire=part(model,"Fireball",V(.3,.3,.3)*z,CFrame.new(position),fireC,NEON,0,"ell")
    local rings={}
    local function ring(n,color,delay,reach,th)
        local list={};for i=1,n do list[i]=part(model,"Ring",V(th,th,th*2.4)*z,CFrame.new(position),typeof(color)=="function"and color(i/n)or color,NEON,0)end
        table.insert(rings,{list=list,delay=delay,reach=reach*z})
    end
    ring(light and 8 or 12,tier>=5 and hue or ringC,0,3.4,.16)
    if not light and tier>=3 then ring(10,coreC,.08,2.3,.12)end
    local parts={}
    if not light then
        local w=victim or {}
        local tones={w.body or pale,w.fins or steel,w.trim or w.nose or pale,w.glow or amber}
        local n=weapon=="MIRVWarhead"and 2 or weapon=="HydrogenBomb"and 5 or 4
        local smokeC=victimTrail and victimTrail.smoke or Color3.fromRGB(120,124,132)
        local seed=(position.X*7.31+position.Z*3.17)%1
        for i=1,n do
            local a=(i/n+seed)*math.pi*2;local dir=V(math.cos(a),.35+.5*Themes.hash(i,seed*91),math.sin(a))
            local size=(i==1 and V(.6,.22,.22)or V(.3,.08,.34)*(0.7+Themes.hash(i+3,seed*37)*.6))*z
            local shard=part(model,"Shard",size,CFrame.new(position),tones[(i-1)%#tones+1],i==4 and NEON or SMOOTH,0,i==1 and"cyl"or nil)
            if i<=2 then trail(shard,"Smoke",.08*z,ColorSequence.new(smokeC),.9,NumberSequence.new(.35,1),NumberSequence.new(1,2.2),0)end
            table.insert(parts,{p=shard,v=dir*(2.6+1.4*Themes.hash(i+7,seed*13))*z,spin=V(Themes.hash(i,1)*9-4.5,Themes.hash(i,2)*9-4.5,Themes.hash(i,3)*9-4.5)})
        end
        if tier>=4 then
            for i=1,8 do
                local a=i/8*math.pi*2;local c=tier>=5 and hue(i/8)or (killer.ember or fireC)
                local e=part(model,"Ember",V(.12,.12,.12)*z,CFrame.new(position),c,NEON,0,"ball")
                table.insert(parts,{p=e,v=V(math.cos(a)*2.2,1.6+(i%3)*.6,math.sin(a)*2.2)*z,spin=Vector3.zero,ember=true})
            end
        end
    end
    local puff=not light and part(model,"Smoke",V(.4,.4,.4)*z,CFrame.new(position),victimTrail and victimTrail.smoke or Color3.fromRGB(110,114,122),SMOOTH,.5,"ell")
    local g=9*z
    track(model,function(t)
        local f=out4(k(t,0,.16));flash.Size=Vector3.one*z*(.4+2*f);flash.Transparency=out2(k(t,.05,.24))
        local l=flash:FindFirstChildOfClass("PointLight");if l then l.Brightness=3*(1-k(t,0,.4))end
        local b=out2(k(t,0,.32));fire.Size=Vector3.one*z*(.3+1.3*b);fire.Color=fireC:Lerp(coreC,k(t,.1,.35));fire.Transparency=out2(k(t,.14,.42))
        for _,r in ipairs(rings)do
            local e=out4(k(t,r.delay,r.delay+.45));local n=#r.list
            for i,p in ipairs(r.list)do
                local a=i/n*math.pi*2;local off=facing*V(math.cos(a),math.sin(a),0)*(.3*z+r.reach*e)
                p.CFrame=CFrame.lookAt(position+off,position+off*2);p.Transparency=k(t,r.delay+.12,r.delay+.5)
            end
        end
        for _,d in ipairs(parts)do
            local tt=math.min(t,1.3)
            local pos=position+d.v*tt-UP*(.5*g*tt*tt)
            d.p.CFrame=CFrame.new(pos)*CFrame.Angles(d.spin.X*tt,d.spin.Y*tt,d.spin.Z*tt)
            d.p.Transparency=d.ember and k(t,.4,.9) or k(t,1,1.35)
        end
        if puff then local a=out2(k(t,.08,1.4));puff.Size=Vector3.one*z*(.4+1.6*a);puff.CFrame=CFrame.new(position+UP*.5*z*a);puff.Transparency=.5+.5*k(t,.4,1.4)end
        return t<1.45
    end)
    model:SetAttribute("Light",light);model:SetAttribute("KillerTier",tier)
    return model
end
return M
