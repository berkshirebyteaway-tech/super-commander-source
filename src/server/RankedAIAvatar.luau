local Players=game:GetService('Players')
local Core=game.ReplicatedStorage:WaitForChild('FrontierNative'):WaitForChild('Core')
local AI=require(Core.RankedAI)
local M={}
M.faceSeconds=120
M.animations={idle='rbxassetid://507766666',walk='rbxassetid://507777826',run='rbxassetid://507767714'}
local function color(rgb)return Color3.fromRGB(rgb[1],rgb[2],rgb[3])end
function M.description(look,plain)
    local d=Instance.new('HumanoidDescription')
    local c=AI.colors(look);local skin,shirt,pants=color(c.skin),color(c.shirt),color(c.pants)
    d.HeadColor=skin;d.TorsoColor=shirt;d.LeftLegColor=pants;d.RightLegColor=pants
    d.LeftArmColor=c.sleeve and shirt or skin;d.RightArmColor=c.sleeve and shirt or skin
    local w=AI.wardrobe
    if not plain then
        if (look.hair or 0)>0 and w.hair[look.hair]then d.HairAccessory=tostring(w.hair[look.hair])end
        if (look.top or 0)>0 and w.shirts[look.top]then d.Shirt=w.shirts[look.top]end
        if (look.bottom or 0)>0 and w.pants[look.bottom]then d.Pants=w.pants[look.bottom]end
        if (look.face or 0)>0 and w.faces[look.face]then d.Face=w.faces[look.face];d.Head=w.classicHead end
        if (look.hat or 0)>0 and w.hats[look.hat]then d.HatAccessory=tostring(w.hats[look.hat])end
    end
    return d
end
function M.build(look,name)
    local ok,model=pcall(function()return Players:CreateHumanoidModelFromDescription(M.description(look,false),Enum.HumanoidRigType.R15)end)
    if not ok then ok,model=pcall(function()return Players:CreateHumanoidModelFromDescription(M.description(look,true),Enum.HumanoidRigType.R15)end)end
    if not ok or not model then warn('Ranked AI body failed: '..tostring(model));return nil end
    model.Name=name
    local hum=model:FindFirstChildOfClass('Humanoid')
    if hum then hum.DisplayName=name;hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;hum.NameDisplayDistance=0 end
    local animate=model:FindFirstChild('Animate');if animate then animate:Destroy()end
    return model
end
local function faces()
    local f=game.ReplicatedStorage:FindFirstChild('RankedAIFaces')
    if not f then f=Instance.new('Folder');f.Name='RankedAIFaces';f.Parent=game.ReplicatedStorage end
    return f
end
function M.faceName(userId)return 'AI'..tostring(math.abs(userId))end
function M.face(plan,model)
    local folder=faces();local key=M.faceName(plan.userId)
    if folder:FindFirstChild(key)then return end
    local body=model or M.build(plan.look,plan.name);if not body then return end
    local copy=model and model:Clone()or body
    for _,o in ipairs(copy:GetDescendants())do if o:IsA('Script')or o:IsA('LocalScript')or o:IsA('BillboardGui')then o:Destroy()end end
    copy.Name=key;copy:SetAttribute('Expires',os.time()+M.faceSeconds);copy.Parent=folder
end
function M.sweep(keep)
    local folder=game.ReplicatedStorage:FindFirstChild('RankedAIFaces');if not folder then return end
    local now=os.time()
    for _,m in ipairs(folder:GetChildren())do if not(keep and keep[m.Name])and (m:GetAttribute('Expires')or 0)<now then m:Destroy()end end
end
return M
