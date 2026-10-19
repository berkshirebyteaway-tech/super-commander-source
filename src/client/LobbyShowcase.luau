local RunService=game:GetService('RunService')
local Players=game:GetService('Players')
local M={active=false}
local saved,savedYaw,conn,hum,rootPart,autoRotate,from,started,lastCF,rig,depthWas
local DISTANCE,LIFT=10.5,.6
local Lighting=game:GetService('Lighting')
local function lightRig(f)
    local model=Instance.new('Model');model.Name='ShowcaseRig'
    local target=f.Position+Vector3.new(0,.4,0)
    for _,l in ipairs({
        {f.LookVector*7-f.RightVector*5+Vector3.new(0,5,0),Color3.fromRGB(255,226,196),2.4,16,48},
        {f.LookVector*7+f.RightVector*6+Vector3.new(0,1.5,0),Color3.fromRGB(170,205,240),.8,16,60},
        {-f.LookVector*5+Vector3.new(0,6,0),Color3.fromRGB(190,232,255),3,14,50},
    })do
        local p=Instance.new('Part');p.Name='ShowcaseLight';p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false;p.Transparency=1;p.Size=Vector3.one*.2
        p.CFrame=CFrame.lookAt(target+l[1],target)
        local s=Instance.new('SpotLight');s.Face=Enum.NormalId.Front;s.Color=l[2];s.Brightness=l[3];s.Range=l[4];s.Angle=l[5];s.Shadows=false;s.Parent=p
        p.Parent=model
    end
    model.Parent=workspace.CurrentCamera
    return model
end
local function focus(on)
    local depth=Lighting:FindFirstChild('LobbyDepth');if not depth then return end
    if on then
        depthWas={depth.FocusDistance,depth.InFocusRadius,depth.FarIntensity}
        depth.FocusDistance=DISTANCE;depth.InFocusRadius=5;depth.FarIntensity=.55
    elseif depthWas then
        depth.FocusDistance,depth.InFocusRadius,depth.FarIntensity=depthWas[1],depthWas[2],depthWas[3];depthWas=nil
    end
end
local function shot(side)
    local f=rootPart.CFrame;local target=f.Position+Vector3.new(0,.2,0)
    local cf=CFrame.lookAt(target+f.LookVector*DISTANCE+Vector3.new(0,LIFT,0),target)
    if side=='right'then cf*=CFrame.new(-3,0,0)elseif side=='up'then cf*=CFrame.new(0,-3.5,4.5)end
    return cf
end
function M.set(show,side,inLobby)
    M.side=side
    if show and not M.active then M.enter()elseif not show and M.active then M.exit(inLobby~=false)end
end
function M.enter()
    local camera=workspace.CurrentCamera;local c=Players.LocalPlayer.Character
    rootPart=c and c:FindFirstChild('HumanoidRootPart');hum=c and c:FindFirstChildOfClass('Humanoid')
    if not rootPart or not hum or camera.CameraType~=Enum.CameraType.Custom then return end
    M.active=true;saved=camera.CFrame;savedYaw=rootPart.CFrame;autoRotate=hum.AutoRotate;hum.AutoRotate=false
    local look=(saved.Position-rootPart.Position)*Vector3.new(1,0,1)
    if look.Magnitude>.1 then rootPart.CFrame=CFrame.lookAt(rootPart.Position,rootPart.Position+look.Unit)end
    rig=lightRig(rootPart.CFrame);focus(true)
    camera.CameraType=Enum.CameraType.Scriptable;from=camera.CFrame;started=os.clock()
    conn=RunService.RenderStepped:Connect(function()
        if not rootPart.Parent then M.exit(false);return end
        local t=math.clamp((os.clock()-started)/.55,0,1);t=t*t*(3-2*t)
        lastCF=from:Lerp(shot(M.side),t);camera.CFrame=lastCF
    end)
end
function M.exit(restoreCamera)
    if not M.active then return end
    M.active=false;if conn then conn:Disconnect();conn=nil end
    if rig then rig:Destroy();rig=nil end;focus(false)
    if hum and hum.Parent then hum.AutoRotate=autoRotate~=false end
    if rootPart and rootPart.Parent and savedYaw and (rootPart.Position-savedYaw.Position).Magnitude<1 then rootPart.CFrame=savedYaw end
    local camera=workspace.CurrentCamera
    if restoreCamera and camera.CameraType==Enum.CameraType.Scriptable and (not lastCF or camera.CFrame==lastCF)then
        camera.CFrame=saved;camera.CameraType=Enum.CameraType.Custom
    end
end
return M
