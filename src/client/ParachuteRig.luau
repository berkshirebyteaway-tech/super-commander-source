local Styles=require(script.Parent.ParachuteStyles)
local M={};M.__index=M
local function part(parent,name,size,cf,color,material,shape)
    local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.Fabric
    p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
    if shape then p.Shape=shape end;p.Parent=parent;return p
end
local function attachment(parent,name,pos)local a=Instance.new('Attachment');a.Name=name;a.Position=pos;a.Parent=parent;return a end
function M.new(avatar,skin,color,renderParent,articulated)
    local self=setmetatable({avatar=avatar,skin=Styles.get(skin),parts={},cords={},limbs={},accessories={}},M)
    local folder=Instance.new('Model');folder.Name='ParachuteRig';folder.Parent=renderParent or avatar;self.model=folder
    local canopy=Instance.new('Model');canopy.Name='Parafoil';canopy.Parent=folder;self.canopy=canopy
    local root=part(canopy,'RigRoot',Vector3.one*.1,CFrame.new(),color);root.Transparency=1;canopy.PrimaryPart=root;self.root=root
    local harness=part(folder,'Harness',Vector3.new(1.35,1.9,.35),CFrame.new(0,.1,.6),Color3.fromRGB(29,38,49),Enum.Material.Fabric);self.harness=harness
    local anchors={};self.preview=renderParent==nil or renderParent==avatar
    if self.skin.collection then
        local spec=require(script.Parent.ParachuteCanopies).build(self,canopy,self.skin.collection);anchors=spec.anchors;self.crest=spec.crest;self.meshed=spec.mesh
    else
        for i=-4,4 do
            local t=i/4;local y=-1.8*t*t;local z=.25*math.abs(t)
            local cf=CFrame.new(i*1.12,y,z)*CFrame.Angles(0,math.rad(t*7),math.rad(-t*21))
            local p=part(canopy,'AirCell_'..i,Vector3.new(1.32,.32,4.9-1.2*t*t),cf,color,self.skin.material,Enum.PartType.Ball)
            local band=(i==0 or math.abs(i)==3)and 'band'or 'full'
            self.parts[#self.parts+1]={part=p,tint=band}
            local membrane=part(canopy,'FabricPanel_'..i,Vector3.new(1.2,.10,p.Size.Z*.86),cf*CFrame.new(0,-.08,.08),color,self.skin.material)
            self.parts[#self.parts+1]={part=membrane,tint=band}
            local intake=part(canopy,'AirIntake_'..i,Vector3.new(.78,.18,.07),cf*CFrame.new(0,-.10,-p.Size.Z*.46),color:Lerp(Color3.new(0,0,0),.55),self.skin.material,Enum.PartType.Ball)
            self.parts[#self.parts+1]={part=intake,tint='intake'}
        end
        for side=-1,1,2 do for fore=-1,1,2 do for _,span in ipairs({2.25,4.05})do table.insert(anchors,Vector3.new(side*span,-1.8*(span/4.48)^2,fore*1.55))end end end
    end
    local risers={}
    for side=-1,1,2 do for fore=-1,1,2 do risers[side*2+fore]=attachment(harness,'Riser',Vector3.new(side*.6,.72,fore*.08))end end
    for _,at in ipairs(anchors)do
        local lower=risers[(at.X<0 and -2 or 2)+(at.Z<0 and -1 or 1)];local upper=attachment(root,'Suspension',at)
        local b=Instance.new('Beam');b.Name='Suspension';b.Attachment0=lower;b.Attachment1=upper;b.Width0=.035;b.Width1=.018;b.FaceCamera=true;b.Segments=3;b.LightInfluence=1;b.Transparency=NumberSequence.new(.12);b.Color=ColorSequence.new(self.skin.line);b.Enabled=false;b.Parent=folder;self.cords[#self.cords+1]=b
    end
    if self.skin.collection and not self.meshed then
        require(script.Parent.CollectionArt).apply(canopy,self.skin.collection,'parachute',self.crest or CFrame.new(0,.18,0),3.7)
        local Meshes=require(script.Parent.CosmeticMeshes);local key=self.skin.collection.id
        if key and Meshes.has(key)then Meshes.watchModel(key,folder,function()self:meshSwap()end)end
    end
    for _,joint in ipairs(avatar:GetDescendants())do if joint:IsA('Weld')and joint.Part0 and joint.Part1 and joint.Part1:IsDescendantOf(avatar)then
        table.insert(self.accessories,{part=joint.Part1,parent=joint.Part0,home=joint.Part0.CFrame:ToObjectSpace(joint.Part1.CFrame)})
    end end
    local base=avatar:GetPivot()
    for _,p in ipairs(avatar:GetDescendants())do if p:IsA('BasePart')and not p:IsDescendantOf(folder)then
        local side=p.Name:find('Left')and -1 or p.Name:find('Right')and 1
        if side then local arm=p.Name:find('Arm')or p.Name:find('Hand');local leg=p.Name:find('Leg')or p.Name:find('Foot')
            if arm or leg then self.limbs[#self.limbs+1]={part=p,home=base:ToObjectSpace(p.CFrame),side=side,arm=arm~=nil,pivot=Vector3.new(side*(arm and 1.05 or .52),arm and 1.05 or -.75,0)}end
        end
    end end
    if articulated then self.pose=require(script.Parent.DropPose).new(avatar)end
    if self.pose then
        local body={[self.pose.root]=true};for _,j in ipairs(self.pose.order)do body[j.part1]=true end
        local list={}
        for _,w in ipairs(avatar:GetDescendants())do if w:IsA('Weld')and w.Part0 and w.Part1 and w.Part0:IsDescendantOf(avatar)and w.Part1:IsDescendantOf(avatar)then
            if body[w.Part1]and not body[w.Part0]then table.insert(list,{part=w.Part0,parent=w.Part1,home=w.C1*w.C0:Inverse()})
            elseif body[w.Part0]and not body[w.Part1]then table.insert(list,{part=w.Part1,parent=w.Part0,home=w.C0*w.C1:Inverse()})end
        end end
        for _,r in ipairs(require(script.Parent.DropAvatar).joints(avatar).rigids or {})do
            local p0,p1=r.a0.Parent,r.a1.Parent
            if p0 and p1 and p0:IsA('BasePart')and p1:IsA('BasePart')then
                if body[p1]and not body[p0]then table.insert(list,{part=p0,parent=p1,home=r.a1.CFrame*r.a0.CFrame:Inverse()})
                elseif body[p0]and not body[p1]then table.insert(list,{part=p1,parent=p0,home=r.a0.CFrame*r.a1.CFrame:Inverse()})end
            end
        end
        self.accessories=list
    end
    self:recolor(color);self:setVisible(false);return self
end
function M:recolor(color)
    if self.color==color then return end;self.color=color
    for _,cell in ipairs(self.parts)do local t=cell.tint
        if t=='intake'then cell.part.Color=color:Lerp(Color3.new(0,0,0),.55)elseif t=='band'then cell.part.Color=color:Lerp(self.skin.trim,.32)elseif t=='full'then cell.part.Color=color end
    end
    self.model:SetAttribute('FactionTint',color);self.model:SetAttribute('SkinId',self.skin.id)
end
function M:setVisible(value)
    if self.visible==value then return end;self.visible=value
    for _,c in ipairs(self.parts)do c.part.Transparency=value and(c.alpha or 0)or 1 end
    for _,b in ipairs(self.cords)do b.Enabled=value end
    for _,l in ipairs(self.canopy:GetDescendants())do if l:IsA('PointLight')and l.Name=='CollectionLight'then l.Enabled=value end end
    self.harness.Transparency=value and 0 or 1
    self.canopy:SetAttribute('CollectionHidden',not value)
    if self.skin.collection then require(script.Parent.CollectionArt).step(self.canopy,0,true,1)end
end
function M:step(cf,motion,airborne,flightFrame,batch)
    local function place(part,at)if batch then batch:put(part,at)else part.CFrame=at end end
    self:setVisible(motion.visible)
    if self.visible then
        local scale=math.max(.035,motion.inflation)
        if not self.scale or math.abs(scale-self.scale)>.001 then self.canopy:ScaleTo(scale);self.scale=scale end
        local collapsed=motion.landed and math.min(1,(motion.landAge or 0)/.38)or 0
        self.canopy:PivotTo((flightFrame or cf)*CFrame.new(collapsed*2.5,7.7-collapsed*5.8,-.25)*CFrame.Angles(motion.canopyPitch,0,motion.canopyRoll+collapsed*.65))
        if self.skin.collection then
            local phase=(motion.landed or (motion.inflation or 0)>.98)and 3 or (motion.inflation or 0)>.5 and 2 or 1
            local reduced=motion.reducedEffects==true
            if self.preview then local lp=game:GetService('Players').LocalPlayer;reduced=lp~=nil and lp:GetAttribute('CommanderReducedEffects')==true end
            if self.anims then require(script.Parent.ParachuteCanopies).step(self,motion.time or 0,reduced,phase,math.min(1,motion.inflation or 0),place)end
            require(script.Parent.CollectionArt).step(self.canopy,motion.time or 0,motion.reducedEffects==true,phase,batch)
            if not self.collectionSound and motion.inflation>.9 then self.collectionSound=true
                if not motion.reducedEffects and self.avatar:GetAttribute('UserId')==game.Players.LocalPlayer.UserId then require(script.Parent.CollectionArt).sound(self.skin.collection)end
            end
        end
        place(self.harness,cf*CFrame.new(0,.1,.6))
        local slack=(1-math.min(1,scale))*.7
        if self.slack~=slack then for _,b in ipairs(self.cords)do b.CurveSize0=slack;b.CurveSize1=-slack end;self.slack=slack end
    end
    local deployed=math.min(1,motion.inflation)
    if self.pose then
        self.pose:step(motion,airborne);self.pose:apply(cf,place)
        if self.visible then place(self.harness,self.pose.frames[self.pose.root]*CFrame.new(0,.1,.6))end
    else for _,limb in ipairs(self.limbs)do
        local pivot=CFrame.new(limb.pivot);local bend
        if not airborne then bend=CFrame.new()
        elseif limb.arm then bend=CFrame.Angles(-.28-(motion.speed or 0)*.22+limb.side*(motion.steer or 0)*.16,0,limb.side*(1.08+deployed*.9))
        else bend=CFrame.Angles(.24+deployed*.38+math.sin(motion.time*4.8+limb.side*1.6)*(.06+(motion.speed or 0)*.16),0,limb.side*(.14+(motion.speed or 0)*.08))end
        place(limb.part,cf*pivot*bend*pivot:Inverse()*limb.home)
    end end
    for _,a in ipairs(self.accessories)do if a.part.Parent and a.parent.Parent then place(a.part,(batch and batch:get(a.parent)or a.parent.CFrame)*a.home)end end
    if not self.lastInflation or math.abs(motion.inflation-self.lastInflation)>.01 then self.model:SetAttribute('Inflation',motion.inflation);self.lastInflation=motion.inflation end
end
function M:fade(alpha)
    alpha=math.clamp(alpha,0,1)
    if self.fadeAlpha and math.abs(self.fadeAlpha-alpha)<.02 then return end;self.fadeAlpha=alpha
    if not self.fadeParts then self.fadeParts={};for _,p in ipairs(self.canopy:GetDescendants())do if p:IsA('BasePart')then table.insert(self.fadeParts,p)end end end
    for _,p in ipairs(self.fadeParts)do p.LocalTransparencyModifier=alpha end
end
function M:meshSwap()
    local canopy=self.canopy;local root=self.root;local scale=canopy:GetScale()
    for _,p in ipairs(canopy:GetChildren())do if p:IsA('BasePart')and p~=root then p:Destroy()end end
    self.parts={};local spec=require(script.Parent.ParachuteCanopies).meshBuild(self,canopy,self.skin.collection);if not spec then return end
    self.meshed=true;self.crest=spec.crest;self.fadeParts=nil
    for _,c in ipairs(self.parts)do local p=c.part
        p.CFrame=root.CFrame*CFrame.new(p.CFrame.Position*scale)*p.CFrame.Rotation;p.Size*=scale
        p.Transparency=self.visible and(c.alpha or 0)or 1
        local l=p:FindFirstChild('CollectionLight');if l then l.Enabled=self.visible==true end
    end
    local groups,used={},{};for _,at in ipairs(spec.anchors)do local k=(at.X<0 and 'L'or 'R')..(at.Z<0 and 'F'or 'B');groups[k]=groups[k]or {};table.insert(groups[k],at)end
    for _,a in ipairs(root:GetChildren())do if a:IsA('Attachment')and a.Name=='Suspension'then
        local p=a.Position;local k=(p.X<0 and 'L'or 'R')..(p.Z<0 and 'F'or 'B');local g=groups[k]
        if g then used[k]=(used[k]or 0)%#g+1;a.Position=g[used[k]]*scale end
    end end
    self.rest=nil;local color=self.color;self.color=nil;self:recolor(color)
end
function M:destroy()self.model:Destroy()end
return M
