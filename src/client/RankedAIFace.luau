local Replicated=game:GetService('ReplicatedStorage')
local M={}
function M.headshot(userId)return userId and userId>0 and 'rbxthumb://type=AvatarHeadShot&id='..tostring(userId)..'&w=150&h=150'or ''end
function M.isAI(userId)return type(userId)=='number'and userId<=-1000000 end
local function clear(label)local v=label:FindFirstChild('AIFace');if v then v:Destroy()end;label:SetAttribute('AIFace',nil)end
local function draw(label,source)
    local view=Instance.new('ViewportFrame');view.Name='AIFace';view.Size=UDim2.fromScale(1,1);view.BackgroundTransparency=1
    view.ZIndex=label.ZIndex;view.Ambient=Color3.fromRGB(170,170,170);view.LightColor=Color3.fromRGB(255,255,255);view.LightDirection=Vector3.new(-.4,-1,-.6)
    local corner=label:FindFirstChildOfClass('UICorner');if corner then corner:Clone().Parent=view end
    local model=source:Clone();model.Parent=view
    local head=model:FindFirstChild('Head')
    local camera=Instance.new('Camera');camera.FieldOfView=26;camera.Parent=view;view.CurrentCamera=camera
    if head then local at=head.Position+Vector3.new(0,.05,0);camera.CFrame=CFrame.lookAt(at+head.CFrame.LookVector*3.4+Vector3.new(0,.25,0),at)end
    view.Parent=label
end
function M.apply(label,userId)
    if not M.isAI(userId)then
        if label:GetAttribute('AIFace')then clear(label)end
        local image=M.headshot(userId);if label.Image~=image then label.Image=image end
        return false
    end
    if label:GetAttribute('AIFace')==userId then return true end
    clear(label);label.Image='';label:SetAttribute('AIFace',userId)
    local key='AI'..tostring(math.abs(userId))
    task.spawn(function()
        local folder=Replicated:WaitForChild('RankedAIFaces',10);local source=folder and folder:WaitForChild(key,10)
        if source and label.Parent and label:GetAttribute('AIFace')==userId and not label:FindFirstChild('AIFace')then draw(label,source)end
    end)
    return true
end
return M
