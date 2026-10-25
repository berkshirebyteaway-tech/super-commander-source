local pack=game.ReplicatedStorage.FrontierNative
local H=require(pack.Core.LobbyHall)
local M={}
local rgb=Color3.fromRGB
local Neon,Smooth,Metal,Glass=Enum.Material.Neon,Enum.Material.SmoothPlastic,Enum.Material.Metal,Enum.Material.Glass
M.palette={
    floor=rgb(12,19,27),seam=rgb(22,34,47),dais=rgb(26,36,48),pad=rgb(23,33,44),table=rgb(24,34,45),top=rgb(10,22,34),
    wall=rgb(26,40,56),fin=rgb(40,60,82),deck=rgb(17,27,38),rail=rgb(30,43,57),ceiling=rgb(9,13,18),
    teal=rgb(54,226,208),ice=rgb(150,176,200),blue=rgb(90,168,255),lens=rgb(61,127,204),orbit=rgb(79,143,218),
    core=rgb(8,21,36),balconyGlow=rgb(108,143,191),warm=rgb(255,241,226),cool=rgb(207,224,255),wash=rgb(62,106,158),
}
local C=M.palette
local LOOK={
    L2_Dais={C.dais,Metal},L2_DaisRing={C.teal,Neon},L2_Pad={C.pad,Metal},L2_PadRing={C.ice,Neon,.55},
    L2_Table={C.table,Metal},L2_TableGlass={C.top,Smooth,.15},L2_TableTrim={C.teal,Neon,.35},L2_Lens={C.lens,Neon},
    L2_Globe={C.core,Smooth,.04},L2_GlobeDots={C.blue,Neon,.12},L2_Orbit={C.ice,Neon,.72},
    L2_Wall={C.wall,Smooth},L2_Fin={C.fin,Metal},L2_Balcony={C.deck,Smooth},L2_Rail={C.rail,Metal},
    L2_RailGlass={rgb(32,50,70),Glass,.7},L2_BalconyLight={C.balconyGlow,Neon,.3},L2_BackRim={C.teal,Neon,.5},
    L2_FloorSeamA={C.seam,Smooth},L2_FloorSeamB={C.seam,Smooth},
}
function M.create(parent)
    local model=Instance.new('Model');model.Name='DeskPlaza';model:SetAttribute('ArtVersion','CommandHall2');model.Parent=parent
    local function at(v,rot)return CFrame.new(H.world(v))*(rot or CFrame.identity)end
    local function finish(p,key)
        local look=LOOK[key]
        if look then p.Color=look[1];p.Material=look[2];p.Transparency=look[3] or 0 end
        p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
        if look and (look[2]==Neon or look[2]==Glass)then p.CastShadow=false end
        p.Parent=model;return p
    end
    local fidelity={L2_Balcony=Enum.CollisionFidelity.PreciseConvexDecomposition}
    local templates,loaded,failed={},0,0
    local function template(key)
        if templates[key]==nil then
            local def=H.meshes[key];local mp=false
            if def and def.id then
                local ok,res=pcall(function()return game:GetService('AssetService'):CreateMeshPartAsync(Content.fromUri(def.id),{CollisionFidelity=fidelity[key] or Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Precise})end)
                if ok and res then mp=res;loaded+=1 else failed+=1 end
            end
            templates[key]=mp
        end
        return templates[key]
    end
    local turn=CFrame.Angles(0,math.pi,0)
    local function mesh(key,centre,rot,scale,fallback)
        local t=template(key);local def=H.meshes[key]
        if t then
            local p=t:Clone();p.Name=key;p.Size=def.size*(scale or 1);p.CFrame=at(centre,rot)*turn;return finish(p,key)
        end
        if fallback then local p=fallback();if p then p.Name=key;return finish(p,key)end end
    end
    local function block(size,centre,rot)local p=Instance.new('Part');p.Size=size;p.CFrame=at(centre,rot);p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;return p end
    local function disc(r,h,centre)local p=block(Vector3.new(h,r*2,r*2),centre,CFrame.Angles(0,0,math.pi/2));p.Shape=Enum.PartType.Cylinder;return p end
    local function ball(r,centre)local p=block(Vector3.one*r*2,centre);p.Shape=Enum.PartType.Ball;return p end

    local floor=block(Vector3.new(140,2,140),Vector3.new(0,-1,0));floor.Name='HallFloor';floor.Color=C.floor;floor.Material=Smooth
    floor.Anchored=true;floor.CanCollide=true;floor.CastShadow=false;floor.Parent=model
    local ceiling=disc(H.wallRadius+1,.6,Vector3.new(0,H.height+.3,0));ceiling.Name='HallCeiling';ceiling.Color=C.ceiling;finish(ceiling)
    mesh('L2_FloorSeamA',Vector3.new(0,.005,9.5));mesh('L2_FloorSeamB',Vector3.new(0,.005,9.5))

    local d=H.dais
    mesh('L2_Dais',Vector3.new(d.X,.19,d.Z),nil,1,function()return disc(3.4,.38,Vector3.new(d.X,.19,d.Z))end)
    mesh('L2_DaisRing',Vector3.new(d.X,.41,d.Z),nil,1,function()return disc(2.6,.04,Vector3.new(d.X,.4,d.Z))end)
    for i,pad in ipairs(H.pads)do
        local v=pad.pos
        local p=mesh('L2_Pad',Vector3.new(v.X,.14,v.Z),nil,1,function()return disc(1.75,.28,Vector3.new(v.X,.14,v.Z))end);if p then p.Name='PartyPad'..i end
        mesh('L2_PadRing',Vector3.new(v.X,.3,v.Z),nil,1,function()return disc(1.3,.03,Vector3.new(v.X,.3,v.Z))end)
    end
    mesh('L2_Table',Vector3.new(0,1.555,0),nil,1,function()return disc(5.4,3.11,Vector3.new(0,1.555,0))end)
    mesh('L2_TableGlass',Vector3.new(0,3.13,0));mesh('L2_TableTrim',Vector3.new(0,3.12,0));mesh('L2_Lens',Vector3.new(0,3.2,0))
    local g=H.globe
    local core=mesh('L2_Globe',g,nil,1,function()return ball(H.globeRadius,g)end);if core then core.Name='GlobeCore'end
    local dots=mesh('L2_GlobeDots',g+H.meshes.L2_GlobeDots.offset)
    if dots then dots.Name='GlobeDots';dots:SetAttribute('Breathe',true)
    elseif core then core.Material=Neon;core.Color=C.blue;core.Transparency=.55;core:SetAttribute('Breathe',true)end
    mesh('L2_Orbit',g,CFrame.Angles(math.rad(12),0,0),1.0)
    mesh('L2_Orbit',g,CFrame.Angles(math.rad(74),0,math.rad(-18)),1.138)

    mesh('L2_Wall',Vector3.new(0,23,-16.647),nil,1,function()return nil end)
    local wallMesh=model:FindFirstChild('L2_Wall')
    local fins=0
    for i=0,71 do
        local a=(i+.5)/72*math.pi*2
        if math.sin(a)>=-.35 then
            local r=H.wallRadius-.8;local c=Vector3.new(math.cos(a)*r,23,-math.sin(a)*r)
            if mesh('L2_Fin',c,CFrame.Angles(0,a,0),1,function()return block(Vector3.new(.9,46,2.2),c,CFrame.Angles(0,a,0))end)then fins+=1 end
            if not wallMesh then
                local w=block(Vector3.new(.6,46,2*math.pi*H.wallRadius/72+.2),Vector3.new(math.cos(a)*(H.wallRadius+.3),23,-math.sin(a)*(H.wallRadius+.3)),CFrame.Angles(0,a,0))
                w.Name='WallPanel';w.Color=C.wall;w.Material=Smooth;finish(w)
            end
        end
    end
    local deck=mesh('L2_Balcony',Vector3.new(0,6,-27.565))
    if deck then deck.CanCollide=true
    else
        local inner,outer=42.5,49.2;local r=(inner+outer)/2;local step=4
        for _,arc in ipairs(H.balconyArcs)do
            for a0=arc[1]-4,arc[2]+4-step,step do
                local a=math.rad(a0+step/2)
                local s=block(Vector3.new(outer-inner,.3,r*math.rad(step)+.15),Vector3.new(math.cos(a)*r,H.balconyY-.15,-math.sin(a)*r),CFrame.Angles(0,a,0))
                s.Name='BalconyFallback';s.Color=C.deck;s.Material=Smooth;finish(s)
            end
        end
    end
    mesh('L2_Rail',Vector3.new(0,7.59,-24.31));mesh('L2_RailGlass',Vector3.new(0,6.975,-24.261))
    mesh('L2_BalconyLight',Vector3.new(0,5.45,-24.229));mesh('L2_BackRim',Vector3.new(0,.29,-27.049))

    local function lamp(name,from,to,kind,color,brightness,range,angle,shadows)
        local p=Instance.new('Part');p.Name=name;p.Size=Vector3.one*.2;p.Transparency=1;p.CFrame=CFrame.lookAt(H.world(from),H.world(to))
        finish(p);p.CastShadow=false
        local l=Instance.new(kind);l.Color=color;l.Brightness=brightness;l.Range=range;l.Shadows=shadows==true
        if kind=='SpotLight'then l.Face=Enum.NormalId.Front;l.Angle=angle or 45 end
        l.Parent=p;return l
    end
    lamp('KeyLight',Vector3.new(-6,15,29.5),Vector3.new(0,3.5,12.5),'SpotLight',C.warm,4,42,48,true)
    lamp('PartyKey',Vector3.new(0,18,31.5),Vector3.new(0,2.5,10.5),'SpotLight',rgb(255,244,234),2.2,46,70)
    lamp('FillLight',Vector3.new(10,6,25.5),Vector3.new(0,3,12.5),'SpotLight',C.cool,.9,30,60)
    lamp('RimCentre',Vector3.new(0,7.5,6.5),Vector3.new(0,3.6,13.5),'SpotLight',C.teal,2.4,13,60)
    lamp('RimLeft',Vector3.new(-8,7,4.5),Vector3.new(-8,3.4,11),'SpotLight',C.teal,1.6,13,60)
    lamp('RimRight',Vector3.new(8,7,4.5),Vector3.new(8,3.4,11),'SpotLight',C.teal,1.6,13,60)
    lamp('GlobeSpill',Vector3.new(0,4.2,0),Vector3.new(0,0,0),'PointLight',C.blue,1.6,20)
    for i=0,13 do
        local a=math.rad(12+i*(156/13));local r=H.wallRadius-4
        lamp('WallWash',Vector3.new(math.cos(a)*r,7.6,-math.sin(a)*r),Vector3.new(math.cos(a)*H.wallRadius,30,-math.sin(a)*H.wallRadius),'SpotLight',C.wash,2.6,34,28)
    end
    lamp('BalconyLight',Vector3.new(0,30,-7),Vector3.new(0,7,-41),'SpotLight',rgb(157,182,216),.8,60,80)

    model:SetAttribute('MeshesLoaded',loaded);model:SetAttribute('MeshesFailed',failed);model:SetAttribute('Fins',fins)
    model:SetAttribute('FloorTextCount',0);model:SetAttribute('PartCount',#model:GetDescendants())
    return model
end
return M
