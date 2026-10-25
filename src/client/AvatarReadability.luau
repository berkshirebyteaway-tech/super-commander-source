local Players=game:GetService('Players')
local Rules=require(script.Parent.ReadabilityRules)
local M={};M.__index=M
local corners={}
for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do table.insert(corners,Vector3.new(x,y,z)*.5)end end end
local function bounds(camera,cf,size)
    local left,top,right,bottom,depth=math.huge,math.huge,-math.huge,-math.huge,math.huge
    for _,v in ipairs(corners)do
        local p=camera:WorldToViewportPoint(cf:PointToWorldSpace(v*size))
        if p.Z<=0 then return nil end
        left=math.min(left,p.X);right=math.max(right,p.X);top=math.min(top,p.Y);bottom=math.max(bottom,p.Y);depth=math.min(depth,p.Z)
    end
    return {x=left,y=top,w=right-left,h=bottom-top,depth=depth}
end
function M.new(world)return setmetatable({world=world,parts={},fade=0,target=0},M)end
function M:release()
    if self.connection then self.connection:Disconnect();self.connection=nil end
    for p,v in pairs(self.parts)do if p.Parent and v.written and math.abs(p.LocalTransparencyModifier-v.written)<.01 then p.LocalTransparencyModifier=v.base end end
    table.clear(self.parts);self.character=nil;self.fade=0;self.target=0;self.blocked=nil
    if self.outline then self.outline:Destroy();self.outline=nil end
end
function M:characterChanged(char)
    self:release();self.character=char;if not char then return end
    local function add(p)if p:IsA('BasePart')then self.parts[p]={base=p.LocalTransparencyModifier<.99 and p.LocalTransparencyModifier or 0}end end
    for _,p in ipairs(char:GetDescendants())do add(p)end
    self.connection=char.DescendantAdded:Connect(add)
end
function M:step(dt)
    local world=self.world;local active=world.enabled and world.map and not world.dropActive and world.lastState and world.lastState.phase=='playing'and not world.lastState.observer
    local char=active and Players.LocalPlayer.Character or nil
    if char~=self.character then self:characterChanged(char)end
    if not char then return end
    local now=os.clock()
    if now>=(self.nextProbe or 0)then
        self.nextProbe=now+.12;self.target=0;self.blocked=nil
        local root=char:FindFirstChild('HumanoidRootPart');local camera=workspace.CurrentCamera
        if root and camera then
            local cf,size=char:GetBoundingBox();local avatar=bounds(camera,cf,size)
            local radius=math.max(size.X,size.Z)*1.3+5;local candidates={}
            for id,model in pairs(world.units)do
                local info=world.infoFor and world.infoFor(model)
                local pos=info and info.Position or model:GetPivot().Position;local delta=pos-root.Position;local distance=delta.X*delta.X+delta.Z*delta.Z
                if distance<radius*radius then table.insert(candidates,{model=model,distance=distance,selected=id==world.readabilityUnit})end
            end
            table.sort(candidates,function(a,b)if a.selected~=b.selected then return a.selected end;return a.distance<b.distance end)
            for i=1,math.min(12,#candidates)do
                local model=candidates[i].model;local info=world.infoFor and world.infoFor(model)
                local extents=info and info.Extents or model:GetExtentsSize()
                local pivot=model:GetPivot();local target=bounds(camera,pivot*CFrame.new(0,extents.Y*.5,0),extents)
                if Rules.occludes(avatar,target)then self.target=.74;self.blocked=model;break end
            end
        end
    end
    self.fade=Rules.fade(self.fade,self.target,dt)
    for p,v in pairs(self.parts)do
        if not p.Parent then self.parts[p]=nil
        else
            local value=math.max(v.base,self.fade)
            if p.LocalTransparencyModifier~=value then p.LocalTransparencyModifier=value end
            v.written=value
        end
    end
    if self.blocked then
        if not self.outline then
            local box=Instance.new('SelectionBox');box.Name='ReadabilityOutline';box.LineThickness=.035;box.SurfaceTransparency=1;box.Color3=Color3.fromRGB(191,239,255);box.Parent=world.folder;self.outline=box
        end
        self.outline.Adornee=self.blocked;self.outline.Visible=true;self.outline.Transparency=.55
    elseif self.outline then self.outline.Visible=false;self.outline.Adornee=nil end
end
return M
