local M={}
local skeletons=setmetatable({},{__mode='k'})
function M.joints(model)return skeletons[model]end
function M.lockVisual(model)
    local hum=model:FindFirstChildOfClass('Humanoid')
    if hum then hum.EvaluateStateMachine=false;hum.AutoRotate=false;hum.AutomaticScalingEnabled=false end
    for _,p in ipairs(model:GetDescendants())do if p:IsA('BasePart')then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false end end
end
function M.clone(source)
    local archivable=source.Archivable;source.Archivable=true
    local ok,model=pcall(function()return source:Clone()end);source.Archivable=archivable
    if not ok or not model then return nil end
    local root=model:FindFirstChild('HumanoidRootPart')
    if not root then model:Destroy();return nil end
    local joints,remove,bones,rigids={},{},{},{}
    for _,o in ipairs(model:GetDescendants())do
        if o:IsA('Motor6D')or o:IsA('Weld')then
            if o.Part0 and o.Part1 then
                local children=joints[o.Part0];if not children then children={};joints[o.Part0]=children end
                table.insert(children,{part=o.Part1,cf=o.C0*o.C1:Inverse()})
            end
            if o:IsA('Motor6D')then table.insert(remove,o)
                if o.Part0 and o.Part1 then table.insert(bones,{part0=o.Part0,part1=o.Part1,pivot=o.C0.Position})end
            end
        elseif o:IsA('AnimationConstraint')and o.Attachment0 and o.Attachment1 then
            local a0,a1=o.Attachment0,o.Attachment1;local p0,p1=a0.Parent,a1.Parent
            if p0 and p1 and p0:IsA('BasePart')and p1:IsA('BasePart')then
                local children=joints[p0];if not children then children={};joints[p0]=children end
                table.insert(children,{part=p1,cf=a0.CFrame*a1.CFrame:Inverse()})
                table.insert(bones,{part0=p0,part1=p1,pivot=a0.Position})
            end
            table.insert(remove,o)
        elseif o:IsA('RigidConstraint')and o.Attachment0 and o.Attachment1 then
            table.insert(rigids,{a0=o.Attachment0,a1=o.Attachment1});table.insert(remove,o)
        elseif o:IsA('LuaSourceContainer')or o:IsA('Sound')or o:IsA('BillboardGui')or o:IsA('Animator')or o:IsA('Constraint')then table.insert(remove,o)
        elseif o:IsA('BasePart')then o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;o.CastShadow=false;o.LocalTransparencyModifier=0 end
    end
    local queue={root};local seen={[root]=true};local head=1
    while head<=#queue and head<=128 do
        local parent=queue[head];head+=1
        for _,child in ipairs(joints[parent]or {})do if not seen[child.part]then
            child.part.CFrame=parent.CFrame*child.cf;seen[child.part]=true;table.insert(queue,child.part)
        end end
    end
    for _,o in ipairs(remove)do o:Destroy()end
    model.PrimaryPart=root;model:PivotTo(CFrame.new())
    local hum=model:FindFirstChildOfClass('Humanoid');if hum then
        hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
        hum.EvaluateStateMachine=false;hum.AutoRotate=false
    end
    M.lockVisual(model)
    skeletons[model]={bones=bones,rigids=rigids,scale=model:GetScale()}
    return model
end
return M
