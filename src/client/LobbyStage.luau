local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local Lighting=game:GetService('Lighting')
local H=require(script.Parent.Parent.Core.LobbyHall)
local me=Players.LocalPlayer
local M={active=false,stand={}}
local plaza,opts,clock,hidden,names=nil,nil,0,{},{}
local folder

local function shape()
    local camera=workspace.CurrentCamera;local v=camera and camera.ViewportSize or Vector2.new(16,9)
    local aspect=v.X/math.max(1,v.Y);local w,t=H.shots.wide,H.shots.tall
    return math.clamp((w.aspect-aspect)/(w.aspect-t.aspect),0,1)
end
function M.shot()
    local k=shape();local w,t=H.shots.wide,H.shots.tall
    local pos=w.pos:Lerp(t.pos,k);local look=w.look:Lerp(t.look,k)
    return CFrame.lookAt(H.world(pos),H.world(look)),w.fov+(t.fov-w.fov)*k
end
function M.focus()return CFrame.new(H.world(H.dais+Vector3.new(0,3,0)))end
function M.commanderRoot()local s=M.stand[1];return s and s.clone and s.clone:FindFirstChild('HumanoidRootPart')end

local SHOWN={ParticleEmitter=true,Beam=true,Trail=true,PointLight=true,SpotLight=true,SurfaceLight=true,BillboardGui=true}
local function hide(c)
    if hidden[c]then return end;local saved={}
    for _,o in ipairs(c:GetDescendants())do
        if o:IsA('BasePart')or o:IsA('Decal')then o.LocalTransparencyModifier=1
        elseif SHOWN[o.ClassName]and o.Enabled then saved[o]=true;o.Enabled=false end
    end
    hidden[c]=saved
end
local function show(c)
    local saved=hidden[c];if not saved then return end;hidden[c]=nil
    if not c.Parent then return end
    for _,o in ipairs(c:GetDescendants())do if o:IsA('BasePart')or o:IsA('Decal')then o.LocalTransparencyModifier=0 end end
    for o in pairs(saved)do if o.Parent then o.Enabled=true end end
end
local function quietNames(on)
    for _,p in ipairs(Players:GetPlayers())do
        local tag=p.Character and p.Character:FindFirstChild('CommanderName')
        if tag and tag:IsA('BillboardGui')then
            if on and tag.Enabled then names[tag]=true;tag.Enabled=false elseif not on and names[tag]then tag.Enabled=true end
        end
    end
    if not on then table.clear(names)end
end

local function standIn(c)
    local was=c.Archivable;c.Archivable=true;local ok,clone=pcall(function()return c:Clone()end);c.Archivable=was
    if not ok or not clone then return nil end
    for _,o in ipairs(clone:GetDescendants())do
        if o:IsA('LuaSourceContainer')or o:IsA('Sound')or o:IsA('BillboardGui')or o:IsA('Animator')or o:IsA('ForceField')then o:Destroy()
        elseif o:IsA('BasePart')then o.CanCollide=false;o.CanQuery=false;o.CanTouch=false;o.Anchored=false;o.LocalTransparencyModifier=0;o.Massless=true
        elseif o:IsA('Decal')then o.LocalTransparencyModifier=0 end
    end
    local hum=clone:FindFirstChildOfClass('Humanoid')
    if hum then hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;hum.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff;hum.BreakJointsOnDeath=false end
    local root=clone:FindFirstChild('HumanoidRootPart');if root then root.Anchored=true;root.Transparency=1 end
    clone.Name='StandIn';return clone
end
local function joints(real,clone)
    local list={}
    for _,m in ipairs(real:GetDescendants())do
        if m:IsA('Motor6D')and m.Parent then
            local host=clone:FindFirstChild(m.Parent.Name,true);local twin=host and host:FindFirstChild(m.Name)
            if twin and twin:IsA('Motor6D')then table.insert(list,{m,twin})end
        end
    end
    return list
end
local function feetOn(clone,spot,yaw)
    local hum=clone:FindFirstChildOfClass('Humanoid');local root=clone:FindFirstChild('HumanoidRootPart');if not root then return end
    local lift=hum and hum.RigType==Enum.HumanoidRigType.R15 and hum.HipHeight+root.Size.Y/2 or 3*clone:GetScale()
    local at=H.world(spot);local face=CFrame.lookAt(at,at+Vector3.new(0,0,1))*CFrame.Angles(0,math.rad(-(yaw or 0)),0)
    clone:PivotTo(face*CFrame.new(0,lift,0))
end

local function release(i)
    local s=M.stand[i];if not s then return end;M.stand[i]=nil
    if s.watch then for _,c in ipairs(s.watch)do c:Disconnect()end end
    if s.clone then s.clone:Destroy()end
    if s.real then show(s.real)end
end
local function build(i,player)
    local c=player.Character;if not c or not c:FindFirstChild('HumanoidRootPart')then return end
    local clone=standIn(c);if not clone then return end
    local s={player=player,real=c,clone=clone,dirty=false,watch={}}
    s.map=joints(c,clone)
    local spot,yaw=H.dais,0;if i>1 then local pad=H.pads[i-1];spot,yaw=pad.pos,pad.yaw end
    feetOn(clone,spot,yaw);if i==1 and M.hold then clone:PivotTo(M.hold)end;clone.Parent=folder
    local function touched()s.dirty=true end
    table.insert(s.watch,c.DescendantAdded:Connect(function(o)if not o:IsA('Sound')and not o:IsA('LuaSourceContainer')then touched()end end))
    table.insert(s.watch,c.DescendantRemoving:Connect(function(o)if o:IsA('Accessory')or o:IsA('Clothing')or o:IsA('BasePart')or o:IsA('Decal')then touched()end end))
    hide(c);M.stand[i]=s
    s.skin={};for _,o in ipairs(c:GetDescendants())do if o:IsA('BasePart')or o:IsA('Decal')then table.insert(s.skin,o)end end
end
local function cast()
    local list={me}
    local party=opts.party and opts.party()
    if party and party.users and #party.users>1 then
        for _,u in ipairs(party.users)do
            if u~=me.UserId and #list<1+#H.pads then local p=Players:GetPlayerByUserId(u);if p then table.insert(list,p)end end
        end
    end
    return list
end
local function sync()
    local want=cast()
    for i=1,1+#H.pads do
        local p=want[i];local s=M.stand[i]
        if s and (s.player~=p or s.real~=(p and p.Character)or not s.real.Parent or s.dirty)then release(i);s=nil end
        if p and not s then build(i,p)end
    end
    local keep={}
    for _,s in pairs(M.stand)do keep[s.real]=true end
    local crowd={}
    for _,p in ipairs(Players:GetPlayers())do
        local c=p.Character;if c and not keep[c]and c:GetAttribute('BalconySlot')then table.insert(crowd,c)end
    end
    table.sort(crowd,function(a,b)return a:GetAttribute('BalconySlot')<b:GetAttribute('BalconySlot')end)
    for i=H.balconyShown+1,#crowd do keep[crowd[i]]=true;hide(crowd[i])end
    for c in pairs(hidden)do if not keep[c]then show(c)end end
    quietNames(true)
end
local function owned()
    if require(script.Parent.LobbyIntro).active or require(script.Parent.LobbyShowcase).active then return false end
    local ok,busy=pcall(function()return require(script.Parent.SupplyCinematic).playing()end)
    return not(ok and busy)
end
local function stop()
    if not M.active then return end;M.active=false
    for i in pairs(M.stand)do release(i)end
    for c in pairs(hidden)do show(c)end
    quietNames(false)
    local depth=Lighting:FindFirstChild('LobbyDepth');if depth and M.depthWas then depth.FocusDistance,depth.InFocusRadius,depth.FarIntensity=table.unpack(M.depthWas);M.depthWas=nil end
end
local function start()
    if M.active then return end;M.active=true;clock=0
    local depth=Lighting:FindFirstChild('LobbyDepth')
    if depth then
        M.depthWas={depth.FocusDistance,depth.InFocusRadius,depth.FarIntensity}
        local cf=M.shot();depth.FocusDistance=(cf.Position-H.world(H.dais)).Magnitude;depth.InFocusRadius=16;depth.FarIntensity=.5;depth.NearIntensity=0
    end
    sync()
end
function M.take()
    local camera=workspace.CurrentCamera;local cf,fov=M.shot()
    camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=cf;camera.FieldOfView=fov;camera.Focus=M.focus()
end
function M.attach(model,o)
    if model:GetAttribute('ArtVersion')~='CommandHall2'then return false end
    plaza,opts=model,o or {}
    folder=Instance.new('Folder');folder.Name='LobbyStage';folder.Parent=workspace
    local breathe={}
    local function add(d)if d:IsA('BasePart')and d:GetAttribute('Breathe')then table.insert(breathe,{p=d,base=d.Transparency})end end
    for _,d in ipairs(plaza:GetDescendants())do add(d)end;plaza.DescendantAdded:Connect(add)
    local acc=0
    RunService:BindToRenderStep('LobbyStage',Enum.RenderPriority.Camera.Value+1,function(dt)
        if not plaza.Parent then return end
        local menu=opts.menu and opts.menu()
        if not menu then stop();return end
        start()
        if owned()then
            local camera=workspace.CurrentCamera;local cf,fov=M.shot()
            if camera.CameraType~=Enum.CameraType.Scriptable then camera.CameraType=Enum.CameraType.Scriptable end
            camera.CFrame=cf;camera.FieldOfView=fov
        end
        for _,s in pairs(M.stand)do
            for _,j in ipairs(s.map)do j[2].Transform=j[1].Transform end
            for _,o in ipairs(s.skin)do if o.LocalTransparencyModifier<1 then o.LocalTransparencyModifier=1 end end
        end
        clock+=dt;acc+=dt
        if acc>=.5 then acc=0;sync()end
        local still=opts.reduced and opts.reduced()
        for _,b in ipairs(breathe)do b.p.Transparency=math.clamp(b.base+(still and 0 or math.sin(clock*math.pi/2)*.1),0,1)end
    end)
    M.attached=true
    return true
end
return M
