local Rules=require(script.Parent.Parent.Core.CommanderStandardRules)
local G=require(script.Parent.ToyGeometry)
local Meshes=require(script.Parent.CosmeticMeshes)
local M={};M.__index=M
local steel=Color3.fromRGB(91,110,128);local white=Color3.fromRGB(224,239,249)
local function part(parent,name,size,color)
    local p=Instance.new('Part');p.Name=name;p.Size=size;p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Parent=parent;return p
end
function M.new(parent,id,color)
    local self=setmetatable({definition=Rules.find(id)or Rules.items[1],cloth={},trims={},wings={},effects={},logos={}},M)
    self.model=Instance.new('Model');self.model.Name='CommanderStandard';self.model:SetAttribute('AppearanceOnly',true);self.model:SetAttribute('Style',self.definition.id)
    self.pole=part(self.model,'Pole',Vector3.new(.09,4.25,.09),steel);self.model.PrimaryPart=self.pole
    self.pole.Material=Enum.Material.Metal
    self.grip=part(self.model,'Grip',Vector3.new(.15,.5,.15),Color3.fromRGB(28,38,49))
    self.tip=part(self.model,'CommandCore',Vector3.new(.22,.22,.12),white)
    for i=1,self.definition.finial-1 do self.wings[i]=part(self.model,'Crest'..i,Vector3.new(.12,.3,.1),steel)end
    for i=1,5 do self.cloth[i]=part(self.model,'Cloth'..i,Vector3.new(.44,1.24,.045),color)end
    for i=1,self.definition.trim do self.trims[i]=part(self.model,'ServiceBand'..i,Vector3.new(.044,1.18,.054),white)end
    self.seal=part(self.model,'Seal',Vector3.new(1.22,1.18,.052),color)
    self.seal.Transparency=1
    local logoColor=self.definition.crest>=6 and Color3.fromRGB(247,221,156)or white
    local template=G.templates['standard'..self.definition.crest]
    for _,side in ipairs({-1,1})do
        if template then
            local p=template:Clone();p.Name='LevelEmblem';p.Material=Enum.Material.SmoothPlastic;p.Color=logoColor;p.Size=Vector3.new(1.22,1.18,.012)
            p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false;p.Parent=self.model
            table.insert(self.logos,{part=p,side=side,size=p.Size,cf=CFrame.identity})
        else
            for _,s in ipairs(Rules.emblem(self.definition.id))do
                local size=Vector3.new(s[3]*1.22,s[4]*1.18,.012)
                local p=part(self.model,'LevelEmblemStroke',size,logoColor)
                table.insert(self.logos,{part=p,side=side,size=size,cf=CFrame.new((s[1]-.5)*1.22,(.5-s[2])*1.18,0)*CFrame.Angles(0,0,-math.rad(s[5]))})
            end
        end
    end
    if self.definition.effect>0 then
        for i=1,self.definition.effect==2 and 8 or 4 do
            local p=part(self.model,'CrestGlint'..i,Vector3.one*.055,white);p.Material=Enum.Material.Neon;self.effects[i]=p
        end
    end
    self.model:SetAttribute('PartBudget',template and 24 or 80);self.model:SetAttribute('LogoMesh',template~=nil);self.model:SetAttribute('LogoStrokes',#Rules.emblem(self.definition.id));self.model:SetAttribute('CrestLevel',self.definition.crest);self.model:SetAttribute('EffectLevel',self.definition.effect)
    self.model:SetAttribute('UnlockLevel',self.definition.level);self.model.Parent=parent
    local id=self.definition.id
    if Meshes.standardReady(id)then self:meshFit()
    else for _,key in ipairs(Meshes.standardKeys(id))do Meshes.watchModel(key,self.model,function()if not self.mesh and Meshes.standardReady(id)then self:meshFit();self.scale=nil;local f=self.fade;self.fade=nil;self:step(self.lastGrip or CFrame.new(),0,0,self.lastScale or 1,f or 0)end end)end end
    self:recolor(color);self:step(CFrame.new(),0,0,1,0);return self
end
function M:meshFit()
    for _,p in ipairs({self.pole,self.grip,self.tip})do p:Destroy()end
    for _,list in ipairs({self.wings,self.trims})do for _,p in ipairs(list)do p:Destroy()end;table.clear(list)end
    self.mesh={};self.team={}
    for _,key in ipairs(Meshes.standardKeys(self.definition.id))do
        for _,r in ipairs(Meshes.build(self.model,key)or {})do
            r.part.CastShadow=false;r.size=r.part.Size;table.insert(self.mesh,r)
            if r.tint=='team'then table.insert(self.team,r.part)end
            if r.def.name=='Pole'then self.pole=r.part;self.model.PrimaryPart=r.part end
        end
    end
    self.model:SetAttribute('MeshHardware',true)
    if self.color then for _,p in ipairs(self.team)do p.Color=self.color end end
end
function M:recolor(color)
    if self.color==color then return end;self.color=color
    for _,p in ipairs(self.cloth)do p.Color=color end;self.seal.Color=color
    for _,p in ipairs(self.team or {})do p.Color=color end
end
function M:step(grip,time,speed,scale,fade,batch,reduced)
    local s=math.clamp(scale or 1,.65,2);local d=self.definition
    local base=grip*CFrame.Angles(-.3,0,-.055-math.min(speed or 0,20)*.002)
    local nextFade=fade or 0;local fadeChanged=self.fade~=nextFade;self.fade=nextFade
    local function place(p,localCF)
        local cf=base*CFrame.new(localCF.Position*s)*localCF.Rotation
        if batch then batch:put(p,cf)else p.CFrame=cf end
        if fadeChanged then p.LocalTransparencyModifier=nextFade end
    end
    self.lastGrip,self.lastScale=grip,scale
    if self.scale~=s then
        self.scale=s;self.seal.Size=Vector3.new(1.22,1.18,.052)*s
        if self.mesh then for _,r in ipairs(self.mesh)do r.part.Size=r.size*s end
        else self.pole.Size=Vector3.new(.09,4.25,.09)*s;self.grip.Size=Vector3.new(.15,.5,.15)*s;self.tip.Size=Vector3.new(.22,.22,.12)*(.9+d.finial*.1)*s end
        for _,p in ipairs(self.trims)do p.Size=Vector3.new(.044,1.18,.054)*s end
        for _,p in ipairs(self.wings)do p.Size=Vector3.new(.12,.3,.1)*s end
        for i,p in ipairs(self.cloth)do local h=i==5 and(d.cut=='forked'and .80 or d.cut=='crown'and 1.0 or 1.12)or 1.24;p.Size=Vector3.new(.44,h,.045)*s end
        for _,p in ipairs(self.effects)do p.Size=Vector3.one*.055*s end
        for _,v in ipairs(self.logos)do v.part.Size=v.size*s end
    end
    if self.mesh then for _,r in ipairs(self.mesh)do place(r.part,r.kind and not reduced and Meshes.motion(r,time or 0,0,1)*r.home or r.home)end
    else place(self.pole,CFrame.new(0,1.12,0));place(self.grip,CFrame.new());place(self.tip,CFrame.new(0,3.32,0)*CFrame.Angles(0,0,math.pi/4))end
    for i,p in ipairs(self.wings)do local side=i==1 and -1 or 1;place(p,CFrame.new(side*.17,3.24,0)*CFrame.Angles(0,0,side*-.4))end
    local wind=reduced and 0 or math.min(.24,.045+(speed or 0)*.004);local t=time or 0
    for i,p in ipairs(self.cloth)do
        local x=(i-.5)*.43+.05
        local y=2.44+(i<=2 and .07 or 0);if i==5 then y+=.12 end
        place(p,CFrame.new(x,y,math.sin(t*3.8-i*.55)*wind*i/5)*CFrame.Angles(math.sin(t*3.8-i*.55)*wind,0,0))
    end
    for i,p in ipairs(self.trims)do place(p,CFrame.new(.13+(i-1)*.11,2.48,-.008))end
    local sealWave=math.sin(t*3.8-3*.55)*wind
    local sealCF=CFrame.new(1.05,2.47,.04+sealWave*3/5)*CFrame.Angles(sealWave,0,0)
    place(self.seal,sealCF)
    for _,v in ipairs(self.logos)do place(v.part,sealCF*CFrame.new(0,0,v.side*.18)*v.cf)end
    for i,p in ipairs(self.effects)do
        local a=t*(d.effect==2 and .65 or .35)+(i-1)/#self.effects*math.pi*2
        place(p,sealCF*CFrame.new(math.cos(a)*.65,math.sin(a)*.62,-.065))
        p.Transparency=reduced and 1 or .42+.25*(.5+.5*math.sin(t*2+i))
    end
end
function M:destroy()if self.model then self.model:Destroy();self.model=nil end end
return M
