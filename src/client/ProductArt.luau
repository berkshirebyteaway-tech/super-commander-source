local G=require(script.Parent.ToyGeometry)
local Art=require(script.Parent.CollectionArt)
local M={}
local rgb=Color3.fromRGB
M.colors={club=rgb(191,239,255),permanent=rgb(245,196,81)}
local DARK=rgb(22,28,38)
local function metal(p,reflect)p.Material=Enum.Material.Metal;p.Reflectance=reflect or .1;p.CastShadow=false;return p end
local function neon(p)p.Material=Enum.Material.Neon;p.CastShadow=false;return p end
local function glass(p,t)p.Material=Enum.Material.Glass;p.Transparency=t or .18;p.Reflectance=.25;p.CastShadow=false;return p end
local function key(m,cf,color)
    metal(G.block(m,'Key',Vector3.new(1.5,.12,2.3),cf,DARK:Lerp(color,.25)),.15)
    neon(G.block(m,'KeyStripe',Vector3.new(1.52,.14,.26),cf*CFrame.new(0,0,-.6),color))
    neon(G.block(m,'KeyEdge',Vector3.new(.1,.14,2.32),cf*CFrame.new(-.72,0,0),color))
    neon(G.block(m,'KeyEdge',Vector3.new(.1,.14,2.32),cf*CFrame.new(.72,0,0),color))
end
local function stand(m,accent)
    metal(G.cylinder(m,'Stand',3.2,.5,CFrame.new(0,.25,0),DARK),.05)
    metal(G.cylinder(m,'StandTop',2.7,.2,CFrame.new(0,.6,0),DARK:Lerp(accent,.15)),.2)
    neon(G.cylinder(m,'StandRing',3.25,.12,CFrame.new(0,.52,0),accent))
end
local function club()
    local m=Instance.new('Model');m.Name='Product_club';local ice=M.colors.club;stand(m,ice)
    metal(G.cylinder(m,'Column',.5,1.6,CFrame.new(0,1.4,0),DARK:Lerp(ice,.2)),.2)
    local at=CFrame.new(0,3.6,0)
    glass(G.block(m,'Gem',Vector3.new(2.4,2.4,2.4),at*CFrame.Angles(math.rad(45),0,math.rad(35)),ice))
    glass(G.block(m,'Gem',Vector3.new(2.4,2.4,2.4),at*CFrame.Angles(0,math.rad(45),math.rad(45)),ice))
    neon(G.ball(m,'GemCore',Vector3.new(1.3,1.3,1.3),at,rgb(150,230,255)))
    key(m,CFrame.new(-2.9,3.2,.4)*CFrame.Angles(math.rad(70),math.rad(20),math.rad(-18)),rgb(54,226,208))
    local bubble=CFrame.new(2.8,4.4,.2)*CFrame.Angles(0,math.rad(-25),0)
    local b=G.part(m,'Chat',Vector3.new(2,1.3,.5),bubble,rgb(236,244,250),'soft');b.CastShadow=false
    G.block(m,'ChatTail',Vector3.new(.45,.45,.45),bubble*CFrame.new(-.55,-.72,0)*CFrame.Angles(0,0,math.rad(45)),rgb(236,244,250)).CastShadow=false
    for i=-1,1 do neon(G.ball(m,'ChatDot',Vector3.new(.26,.26,.26),bubble*CFrame.new(i*.5,0,-.27),rgb(54,226,208)))end
    local board=CFrame.new(2.3,1.9,-1)*CFrame.Angles(math.rad(-28),math.rad(-30),0)
    metal(G.block(m,'Board',Vector3.new(2.4,.16,1.7),board,DARK:Lerp(ice,.12)),.15)
    neon(G.block(m,'BoardRim',Vector3.new(2.5,.06,1.8),board*CFrame.new(0,-.06,0),ice))
    for i,c in ipairs({rgb(54,226,208),rgb(173,119,255),rgb(245,196,81),rgb(120,200,255)})do
        local x=((i-1)%2-.5)*1.05;local z=(math.floor((i-1)/2)-.5)*.75
        local tile=G.block(m,'Tile',Vector3.new(.95,.08,.62),board*CFrame.new(x,.11,z),c);tile.Material=Enum.Material.SmoothPlastic;tile.CastShadow=false
    end
    metal(G.block(m,'FlagPole',Vector3.new(.06,.9,.06),board*CFrame.new(.55,.55,.3),rgb(220,226,232)),.3)
    neon(G.block(m,'FlagCloth',Vector3.new(.42,.26,.04),board*CFrame.new(.77,.86,.3),rgb(54,226,208)))
    m.WorldPivot=CFrame.identity
    Art.apply(m,{id='product_club',tier=4,accent={191,239,255},secondary={120,200,255}},'crate',at,2.6)
    local light=Instance.new('PointLight');light.Name='ProductGlow';light.Color=ice;light.Range=10;light.Brightness=1.3;light.Shadows=false;light.Parent=m.GemCore
    return m
end
local function permanent()
    local m=Instance.new('Model');m.Name='Product_permanent';local gold=M.colors.permanent;stand(m,gold)
    for i,c in ipairs({rgb(173,119,255),rgb(173,119,255),rgb(245,196,81),rgb(157,242,235)})do
        key(m,CFrame.new(0,3.3,1.1)*CFrame.Angles(0,0,math.rad(-42+(i-1)*28))*CFrame.new(0,1.6,0)*CFrame.Angles(math.rad(90),0,0),c)
    end
    local at=CFrame.new(0,3.2,0)
    metal(G.block(m,'Shield',Vector3.new(3,2.6,.42),at*CFrame.new(0,.35,0),gold),.3)
    metal(G.block(m,'ShieldTip',Vector3.new(2.1,2.1,.42),at*CFrame.new(0,-.85,0)*CFrame.Angles(0,0,math.rad(45)),gold),.3)
    metal(G.block(m,'Field',Vector3.new(2.5,2.1,.1),at*CFrame.new(0,.4,-.24),rgb(32,40,96)),.05)
    metal(G.block(m,'FieldTip',Vector3.new(1.6,1.6,.1),at*CFrame.new(0,-.72,-.24)*CFrame.Angles(0,0,math.rad(45)),rgb(32,40,96)),.05)
    for i=0,2 do
        local y=-.55+i*.42
        for _,s in ipairs({-1,1})do metal(G.block(m,'Chevron',Vector3.new(1,.2,.12),at*CFrame.new(s*.36,y,-.32)*CFrame.Angles(0,0,math.rad(s*32)),gold),.35)end
    end
    neon(G.block(m,'Star',Vector3.new(.62,.62,.14),at*CFrame.new(0,.95,-.33)*CFrame.Angles(0,0,math.rad(45)),rgb(255,236,170)))
    local crown=at*CFrame.new(0,2.15,0)
    metal(G.cylinder(m,'CrownBand',1.05,.42,crown,gold),.35)
    for i=0,4 do local a=math.rad(i*72)
        metal(G.block(m,'CrownPoint',Vector3.new(.34,.8,.34),crown*CFrame.new(math.sin(a)*.9,.55,math.cos(a)*.9)*CFrame.Angles(0,a,math.rad(45)),gold),.35)
        neon(G.ball(m,'CrownGem',Vector3.new(.24,.24,.24),crown*CFrame.new(math.sin(a)*.95,.98,math.cos(a)*.95),rgb(255,240,190)))
    end
    m.WorldPivot=CFrame.identity
    Art.apply(m,{id='product_permanent',tier=4,accent={245,196,81},secondary={214,168,72}},'crate',at*CFrame.new(0,.4,0),2.8)
    local light=Instance.new('PointLight');light.Name='ProductGlow';light.Color=gold;light.Range=10;light.Brightness=1.3;light.Shadows=false;light.Parent=m.Star
    return m
end
function M.model(sku)return sku=='club'and club()or permanent()end
return M
