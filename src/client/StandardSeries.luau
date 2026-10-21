local D=require(script.Parent.Parent.Core.CollectionDefinitions)
local M={};M.__index=M
local Neon,Metal,Smooth=Enum.Material.Neon,Enum.Material.Metal,Enum.Material.SmoothPlastic
local Ball,Cyl=Enum.PartType.Ball,Enum.PartType.Cylinder
local flat=CFrame.Angles(0,0,math.pi/2);local facing=CFrame.Angles(0,math.pi/2,0)
local TOP=3.34
local tau=math.pi*2
local grade={[4]=Color3.fromRGB(255,207,91),[5]=Color3.fromRGB(214,120,255)}
local function rgb(t)return Color3.fromRGB(t[1],t[2],t[3])end
local function at(x,y,z)return CFrame.new(x,y,z)end
local function palette(id)for _,s in ipairs(D.series)do if s.id==id then return s end end;return D.series[1]end
function M:add(name,size,color,o)
    o=o or {}
    local p=Instance.new('Part');p.Name='Series'..name;p.Size=size;p.Color=color;p.Material=o.material or Smooth;if o.shape then p.Shape=o.shape end
    p.Reflectance=o.reflect or 0;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Transparency=o.alpha or 0;p.Parent=self.model
    table.insert(self.items,{part=p,size=size,phase=o.phase or 1,fx=o.fx,ground=o.ground,alpha=o.alpha or 0,fade=o.fade,pose=o.pose});return p
end
local function emblem(self,a,b)
    for _,side in ipairs({-1,1})do
        self:add('SealMark',a.size,a.color,{shape=a.shape,material=a.material or Metal,pose=function(c)return c.seal*at(0,.6,side*.2)*(a.rot or CFrame.identity)end})
        self:add('SealJewel',b.size,b.color,{shape=b.shape,material=b.material or Neon,pose=function(c)return c.seal*at(0,.6,side*.215)*(b.rot or CFrame.identity)*CFrame.Angles(0,0,c.t*(b.spin or 0))end})
    end
end
local function twinkle(speed,i,low)return function(c)return low+(1-low)*(.5+.5*math.sin(c.t*speed+i*1.9))end end
local themes={}
themes.crown=function(self,pal,navy,pale,gold)
    emblem(self,{size=Vector3.new(.36,.1,.03),color=gold},{size=Vector3.new(.1,.1,.03),color=rgb(pal.secondary),rot=CFrame.Angles(0,0,math.pi/4)})
    self:add('CrownBand',Vector3.new(.1,.36,.36),gold,{shape=Cyl,material=Metal,pose=function()return at(0,TOP+.16,0)*flat end})
    for i=1,5 do self:add('CrownPoint',Vector3.new(.06,.17,.06),gold,{material=Metal,pose=function(c)
        local a=i/5*tau+c.t*.6;return at(math.cos(a)*.15,TOP+.3+.02*math.sin(c.t*3+i),math.sin(a)*.15)*CFrame.Angles(0,-a,0)*CFrame.Angles(0,0,-.32)end})end
    self:add('CrownCap',Vector3.one*.15,navy,{shape=Ball,material=Metal,pose=function()return at(0,TOP+.26,0)end})
    self:add('CrownJewel',Vector3.one*.1,gold,{shape=Ball,material=Neon,pose=function(c)return at(0,TOP+.43+.04*math.sin(c.t*2),0)end})
    self:add('CrownGlow',Vector3.one*.62,gold,{shape=Ball,material=Neon,fx=true,fade=twinkle(1.6,0,.8),pose=function()return at(0,TOP+.3,0)end})
    for i=1,6 do self:add('StarDust',Vector3.one*.05,rgb(pal.secondary),{material=Neon,fx=true,fade=twinkle(4,i,.15),pose=function(c)
        local u=(c.t*.35+i/6)%1;local a=i*1.05+c.t*1.4;return at(math.cos(a)*(.32+u*.2),TOP+u*.75,math.sin(a)*(.32+u*.2))*CFrame.Angles(c.t,c.t*.7,0)end})end
end
themes.dragon=function(self,pal,deep,jade,gold)
    local pearl=Color3.fromRGB(236,250,244)
    emblem(self,{size=Vector3.new(.03,.3,.3),color=gold,shape=Cyl,rot=facing},{size=Vector3.one*.13,color=pearl,shape=Ball})
    local function coil(k,t)local a=k*1.25-t*1.6;local r=.14+.02*math.sin(t*2+k);return Vector3.new(math.cos(a)*r,-.4+k*.42,math.sin(a)*r)end
    for k=1,8 do self:add('DragonCoil',Vector3.new(.12-k*.004,.12-k*.004,.26),k%3==0 and gold or jade,{material=Metal,pose=function(c)
        local p=coil(k,c.t);return CFrame.lookAt(p,coil(k+.5,c.t))end})end
    self:add('DragonHead',Vector3.new(.17,.14,.28),gold,{material=Metal,pose=function(c)local p=coil(9,c.t);return CFrame.lookAt(p,p+(p-coil(8.5,c.t))+Vector3.new(0,.08,0))end})
    for _,side in ipairs({-1,1})do self:add('DragonHorn',Vector3.new(.03,.03,.15),gold,{material=Metal,pose=function(c)
        local p=coil(9,c.t);return CFrame.lookAt(p,p+(p-coil(8.5,c.t)))*at(side*.05,.07,.1)*CFrame.Angles(.5,side*.3,0)end})end
    self:add('DragonPearl',Vector3.one*.14,pearl,{shape=Ball,material=Neon,pose=function(c)return at(math.cos(c.t*1.2)*.12,TOP+.32+.04*math.sin(c.t*2.4),math.sin(c.t*1.2)*.12)end})
    self:add('PearlGlow',Vector3.one*.42,rgb(pal.secondary),{shape=Ball,material=Neon,fx=true,fade=twinkle(1.4,0,.76),pose=function(c)return at(math.cos(c.t*1.2)*.12,TOP+.32,math.sin(c.t*1.2)*.12)end})
    for i=1,2 do self:add('JadeMist',Vector3.one*.06,rgb(pal.secondary),{material=Neon,fx=true,fade=twinkle(3,i,.2),pose=function(c)
        local u=(c.t*.3+i/2)%1;return at(math.cos(i*3+c.t)*.3,.6+u*2.6,math.sin(i*3+c.t)*.3)end})end
end
themes.diamond=function(self,pal,platinum,ice,gold)
    local white=Color3.fromRGB(240,248,255)
    emblem(self,{size=Vector3.new(.26,.26,.03),color=platinum,rot=CFrame.Angles(0,0,math.pi/4)},{size=Vector3.new(.12,.12,.03),color=ice,rot=CFrame.Angles(0,0,math.pi/4)})
    local function gem(c)return at(0,TOP+.38,0)*CFrame.Angles(0,c.t*.8,0)end
    self:add('Gem',Vector3.one*.3,ice,{reflect=.35,alpha=.15,pose=function(c)return gem(c)*CFrame.Angles(math.atan(1/math.sqrt(2)),0,math.pi/4)end})
    self:add('GemCore',Vector3.one*.15,white,{shape=Ball,material=Neon,pose=function(c)return gem(c)end})
    self:add('Girdle',Vector3.new(.04,.4,.4),platinum,{shape=Cyl,material=Metal,pose=function(c)return gem(c)*at(0,-.02,0)*flat end})
    for i=1,4 do self:add('Prong',Vector3.new(.04,.26,.04),gold,{material=Metal,pose=function(c)return gem(c)*CFrame.Angles(0,i*math.pi/2,0)*at(.17,-.12,0)*CFrame.Angles(0,0,.35)end})end
    self:add('GemGlow',Vector3.one*.58,ice,{shape=Ball,material=Neon,fx=true,fade=twinkle(1.8,0,.8),pose=function()return at(0,TOP+.38,0)end})
    for i=1,6 do self:add('Twinkle',Vector3.new(.025,.16,.025),i%2==0 and white or ice,{material=Neon,fx=true,fade=function(c)return math.max(.1,1-math.max(0,math.sin(c.t*2.6+i*1.7))^3)end,pose=function(c)
        local a=i*1.9;return at(math.cos(a)*.42,TOP+.1+(i%3)*.22,math.sin(a)*.42)*CFrame.Angles(0,0,c.t*2+i)end})end
end
themes.eclipse=function(self,pal,dark,pale,violet)
    emblem(self,{size=Vector3.new(.03,.3,.3),color=dark,shape=Cyl,rot=facing},{size=Vector3.one*.08,color=violet,shape=Ball,rot=at(.1,.1,0)})
    local sun=at(0,TOP+.44,0)
    self:add('BlackSun',Vector3.new(.05,.6,.6),dark,{shape=Cyl,material=Metal,pose=function()return sun*facing end})
    self:add('Corona',Vector3.new(.03,.76,.76),violet,{shape=Cyl,material=Neon,fade=function(c)return .05+.25*(.5+.5*math.sin(c.t*2))end,pose=function()return sun*at(0,0,-.03)*facing end})
    for i=1,8 do self:add('CoronaRay',Vector3.new(.04,.26,.02),violet,{material=Neon,fade=twinkle(3,i,.05),pose=function(c)
        local a=i*math.pi/4+c.t*.4;return sun*at(math.cos(a)*.48,math.sin(a)*.48,-.02)*CFrame.Angles(0,0,a-math.pi/2)end})end
    for i=1,4 do self:add('Streamer',Vector3.new(.035,.5,.02),violet,{material=Neon,phase=3,fade=twinkle(2,i,.1),pose=function(c)
        local a=i*math.pi/2+math.pi/4-c.t*.25;return sun*at(math.cos(a)*.62,math.sin(a)*.62,-.025)*CFrame.Angles(0,0,a-math.pi/2)end})end
    self:add('TopCorona',Vector3.new(.02,1.0,1.0),violet,{shape=Cyl,material=Neon,phase=2,alpha=.45,pose=function()return at(0,TOP+.18,0)*flat end})
    self:add('TopUmbra',Vector3.new(.03,.6,.6),dark,{shape=Cyl,material=Metal,phase=2,pose=function()return at(0,TOP+.2,0)*flat end})
    for i=1,6 do self:add('UmbraShard',Vector3.new(.07,.2,.07),pale,{material=Neon,phase=i%2==0 and 3 or 2,pose=function(c)
        local a=i/6*tau-c.t*.3;return sun*at(math.cos(a)*.74,math.sin(a)*.74,0)*CFrame.Angles(0,c.t,a)end})end
    for i=1,8 do self:add('EclipseMote',Vector3.one*.05,i%2==0 and pale or violet,{material=Neon,fx=true,fade=twinkle(3.5,i,.15),pose=function(c)
        local a=i/8*tau+c.t*.9;return at(math.cos(a)*.55,TOP+.44+math.sin(a*2)*.2,math.sin(a)*.55)end})end
end
themes.seraph=function(self,pal,ivory,goldPale,pink)
    emblem(self,{size=Vector3.new(.24,.24,.03),color=goldPale,rot=CFrame.Angles(0,0,math.pi/4)},{size=Vector3.one*.1,color=pink,shape=Ball})
    self:add('SeraphCore',Vector3.one*.2,ivory,{shape=Ball,material=Neon,pose=function(c)return at(0,TOP+.3+.03*math.sin(c.t*2),0)end})
    self:add('SeraphGlow',Vector3.one*.46,goldPale,{shape=Ball,material=Neon,fx=true,fade=twinkle(1.5,0,.78),pose=function()return at(0,TOP+.3,0)end})
    for k=1,3 do for _,side in ipairs({-1,1})do
        local function root(c)return at(side*.08,TOP+.32-(k-1)*.12,0)*CFrame.Angles(.7,0,0)*CFrame.Angles(0,0,side*((.45-(k-1)*.4)+math.sin(c.t*3+k)*.18))end
        self:add('Wing',Vector3.new(.42,.11,.035),ivory,{phase=k,pose=function(c)return root(c)*at(side*.22,0,0)end})
        self:add('WingTip',Vector3.new(.4,.08,.03),goldPale,{phase=k,material=Metal,pose=function(c)return root(c)*at(side*.42,0,0)*CFrame.Angles(0,0,side*.28)*at(side*.18,0,0)end})
    end end
    for i=1,8 do self:add('Halo',Vector3.new(.05,.04,.25),pink,{material=Neon,phase=3,pose=function(c)
        local a=i/8*tau+c.t*.5;local p=Vector3.new(math.cos(a)*.3,TOP+.64,math.sin(a)*.3);return CFrame.lookAt(p,p+Vector3.new(-math.sin(a),0,math.cos(a)))end})end
    for i=1,8 do self:add('Feather',Vector3.new(.1,.02,.05),ivory,{fx=true,fade=function(c)local u=(c.t*.22+i/8)%1;return u>.8 and .1+(u-.8)*4.5 or .1 end,pose=function(c)
        local u=(c.t*.22+i/8)%1;return at(math.sin(i*2.1)*.5+.2*math.sin(c.t*1.5+i),TOP+.4-u*4.2,math.cos(i*1.7)*.4)*CFrame.Angles(math.sin(c.t*2+i)*.6,i,math.sin(c.t*1.7+i)*.5)end})end
end
themes.glitch=function(self,pal,black,cyan,magenta)
    local function jitter(c,i)return math.sin(math.floor(c.t*6+i)*12.9898)*43758.5%1 end
    emblem(self,{size=Vector3.new(.28,.28,.03),color=black},{size=Vector3.new(.12,.12,.03),color=cyan,rot=at(.05,-.04,0)})
    self:add('GlitchCube',Vector3.one*.3,black,{material=Metal,pose=function(c)return at(0,TOP+.32,0)*CFrame.Angles(0,math.floor(c.t*4)*math.pi/8,0)end})
    for i,col in ipairs({cyan,magenta})do local side=i==1 and -1 or 1;self:add('CubeSplit',Vector3.one*.31,col,{material=Neon,alpha=.55,pose=function(c)
        return at(side*(.04+math.abs(jitter(c,i))*.05),TOP+.32,side*.03)*CFrame.Angles(0,math.floor(c.t*4)*math.pi/8,0)end})end
    for i,col in ipairs({cyan,magenta})do local side=i==1 and -1 or 1;self:add('ClothSplit',Vector3.new(2.16,1.24,.02),col,{material=Neon,fade=function(c)return jitter(c,i)>.6 and .62 or .86 end,pose=function(c)
        local k=c.cloth[3];return k.cf*at(side*(.04+(jitter(c,i)>.6 and .06 or 0)),.03,side*.035)end})end
    for i=1,12 do self:add('Pixel',Vector3.new(.1,.1,.04),i%2==0 and magenta or cyan,{material=Neon,phase=i<=8 and 1 or i<=10 and 2 or 3,fade=function(c)return .05+((c.t*.5+i/12)%1)*.9 end,pose=function(c)
        local u=(c.t*.5+i/12)%1;return at(2.15+u*.7,1.95+((i*.37)%1)*1.1-u*u*.6,((i*.53)%1-.5)*.2+u*.15)*CFrame.Angles(0,0,math.floor(u*4)*math.pi/4)end})end
    for i=1,4 do self:add('CodeBlock',Vector3.new(.05,.12,.02),i%2==0 and cyan or magenta,{material=Neon,phase=2,fx=true,pose=function(c)
        local u=(c.t*.45+i/4)%1;return at(-.09*(i%2==0 and 1 or -1),-.8+u*4,.06)end})end
    local wire={{0,.64,2.18,.03},{0,-.64,2.18,.03},{1.08,0,.03,1.3},{-1.08,0,.03,1.3},{0,0,.03,2.5,.53},{0,0,.03,2.5,-.53}}
    for _,w in ipairs(wire)do self:add('Wire',Vector3.new(w[3],w[4],.02),cyan,{material=Neon,phase=3,alpha=.25,pose=function(c)return c.cloth[3].cf*at(w[1],w[2]+.03,.03)*CFrame.Angles(0,0,w[5] and w[5]*-2.4 or 0)end})end
end
themes.leviathan=function(self,pal,abyss,teal,violet)
    local flesh=Color3.fromRGB(22,58,86)
    emblem(self,{size=Vector3.new(.32,.18,.04),color=teal,shape=Ball,material=Neon},{size=Vector3.new(.08,.15,.04),color=violet,shape=Ball,material=Neon})
    self:add('AbyssKnob',Vector3.one*.3,abyss,{shape=Ball,material=Metal,pose=function()return at(0,TOP+.24,0)end})
    self:add('AbyssVeil',Vector3.one*.56,teal,{shape=Ball,material=Neon,fx=true,fade=twinkle(1.2,0,.82),pose=function()return at(0,TOP+.24,0)end})
    for _,side in ipairs({-1,1})do self:add('AbyssEye',Vector3.one*.07,teal,{shape=Ball,material=Neon,fade=function(c)return(c.t*.4+side*.1)%1>.94 and .9 or 0 end,pose=function()return at(side*.07,TOP+.27,.13)end})end
    for j=1,3 do
        local function seg(k,t)local a=j*2.09+k*.9+math.sin(t*1.3+j)*.3;local r=k>=4 and .26 or .16;return Vector3.new(math.cos(a)*r,-.6+k*.6+j*.18+(k>=4 and .1*math.sin(t*2+j)or 0),math.sin(a)*r)end
        for k=1,4 do self:add('Tentacle',Vector3.new(.13-k*.018,.13-k*.018,.42),k==4 and teal or flesh,{material=k==4 and Neon or Metal,phase=j==1 and 1 or 2,pose=function(c)
            local p=seg(k,c.t);return CFrame.lookAt(p,seg(k+.6,c.t))end})end
    end
    local function eye(c)return at(0,TOP+.74,0)*CFrame.Angles(-.5,0,0)end
    self:add('GiantEye',Vector3.new(.52,.34,.2),teal,{shape=Ball,material=Neon,phase=3,pose=function(c)return eye(c)end})
    self:add('GiantIris',Vector3.new(.24,.24,.06),violet,{shape=Ball,material=Neon,phase=3,pose=function(c)return eye(c)*at(math.sin(c.t*.7)*.1,0,.09)end})
    self:add('GiantPupil',Vector3.new(.05,.2,.04),abyss,{material=Metal,phase=3,pose=function(c)return eye(c)*at(math.sin(c.t*.7)*.1,0,.12)end})
    for i=1,8 do self:add('Bubble',Vector3.one*.06,teal,{shape=Ball,material=Neon,fx=true,alpha=.4,fade=function(c)return .3+((c.t*.3+i/8)%1)*.6 end,pose=function(c)
        local u=(c.t*.3+i/8)%1;return at(math.cos(i*2.4)*(.25+u*.25)+.05*math.sin(c.t*3+i),-.8+u*4.6,math.sin(i*2.4)*(.25+u*.25))end})end
end
local edges={crown={'accent','primary'},dragon={'secondary','accent'},diamond={'primary','secondary'},eclipse={'primary','accent',Neon},seraph={'primary','secondary'},glitch={'secondary','accent',Neon},leviathan={'secondary','primary',Neon}}
function M.new(rig)
    local d=rig.definition;local pal=palette(d.series);local tier=d.tier or 4
    local self=setmetatable({rig=rig,model=rig.model,items={},tier=tier,c={t=0,ph=1}},M)
    local e=edges[d.series]or edges.crown;local a,b=rgb(pal[e[1]]),rgb(pal[e[2]])
    for i=1,5 do for n,y in ipairs({1,-1})do
        local top=(i+n)%2==0;self:add('Edge',Vector3.new(.45,.07,.058),top and a or b,{material=top and e[3]or Metal,pose=function(c)local k=c.cloth[i];return k.cf*at(0,y*(k.h/2-.02),0)end})
    end end
    local acc=rgb(pal.accent)
    for _,side in ipairs({-1,1})do for _,y in ipairs({.6,-.6})do
        self:add('SealFrame',Vector3.new(1.28,.055,.02),acc,{material=Metal,pose=function(c)return c.seal*at(0,y,side*.17)end})
    end end
    self:add('Collar',Vector3.new(.12,.3,.3),acc,{shape=Cyl,material=Metal,pose=function()return at(0,TOP,0)*flat end})
    self:add('GroundDisc',Vector3.new(.04,3,3),rgb(pal.primary),{shape=Cyl,ground=true,alpha=.66,pose=function()return at(0,.03,0)*flat end})
    self:add('GroundMark',Vector3.new(.9,.03,.9),acc,{material=Neon,ground=true,alpha=.5,pose=function(c)return at(0,.06,0)*CFrame.Angles(0,math.pi/4+c.t*.3,0)end})
    if tier==5 then self:add('GroundGrade',Vector3.new(.03,3.2,3.2),grade[5],{shape=Cyl,material=Neon,ground=true,phase=2,fade=function(c)return .55+.15*math.sin(c.t*2)end,pose=function()return at(0,.015,0)*flat end})end
    for _,p in ipairs(rig.trims)do p.Color=acc end
    local build=themes[d.series]or themes.crown;build(self,pal,rgb(pal.primary),rgb(pal.secondary),acc)
    self.model:SetAttribute('Series',d.series);self.model:SetAttribute('SeriesParts',#self.items);self.model:SetAttribute('CollectionPhases',tier==5 and 3 or 1)
    return self
end
function M:step(place,s,t,reduced,phase,seal,cloth,ground)
    if self.scale~=s then self.scale=s;for _,v in ipairs(self.items)do v.part.Size=v.size*s end end
    local c=self.c;c.t=reduced and 0 or t;c.ph=self.tier==5 and math.clamp(phase or 1,1,3)or 1;c.seal=seal;c.cloth=cloth
    if self.phase~=c.ph then self.phase=c.ph;self.model:SetAttribute('CollectionPhase',c.ph)end
    for _,v in ipairs(self.items)do
        local a=(v.phase>c.ph or v.fx and reduced)and 1 or v.fade and v.fade(c)or v.alpha
        if v.shown~=a then v.shown=a;v.part.Transparency=a end
        place(v.part,v.pose(c),v.ground and ground or nil)
    end
end
function M:count()return #self.items end
return M
