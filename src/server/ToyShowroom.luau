local pack=game.ReplicatedStorage.FrontierNative
local P=require(pack.Core.PlazaLayout)
local Geo=require(pack.Client.ToyGeometry)
local Terrain=require(pack.Core.Terrain)
local Maps=require(pack.Maps.MapLoader)
local FlagAtlas=require(pack.Client.FlagAtlas)
local M={}
local rgb=Color3.fromRGB
local palette={
    deck=rgb(34,42,54),steel=rgb(48,60,76),steelLight=rgb(78,92,110),wall=rgb(30,37,48),inset=rgb(12,17,24),
    ink=rgb(238,242,246),muted=rgb(138,151,168),line=rgb(38,50,65),
    teal=rgb(54,226,208),azure=rgb(59,130,246),violet=rgb(139,92,246),amber=rgb(255,185,56),gold=rgb(245,196,81),ice=rgb(191,239,255),lime=rgb(180,240,90),
    sea=rgb(8,19,31),land=rgb(60,73,88),
}
M.palette=palette
local function oswald(weight)
    local ok,f=pcall(function()return Font.new("rbxasset://fonts/families/Oswald.json",weight or Enum.FontWeight.Bold)end);return ok and f or nil
end
function M.create(parent,onMode)
    local model=Instance.new('Model');model.Name='DeskPlaza';model:SetAttribute('ArtVersion','CommandHQ2');model.Parent=parent
    local origin=Vector3.new(P.x,P.y,P.z)
    local function cf(x,y,z)return CFrame.new(origin+Vector3.new(x,y,z))end
    local function block(name,size,pos,color,collide,rotation,material,parentModel)
        local p=Geo.block(parentModel or model,name,Vector3.new(table.unpack(size)),cf(table.unpack(pos))*(rotation or CFrame.identity),color)
        p.CanCollide=collide==true;if material then p.Material=material end;return p
    end
    local function neon(name,size,pos,color,alpha,rotation)
        local p=block(name,size,pos,color,false,rotation,Enum.Material.Neon);p.Transparency=alpha or .2;p.CastShadow=false;return p
    end
    local function cyl(name,r,h,x,y,z,color,collide)local p=Geo.cylinder(model,name,r,h,cf(x,y,z),color);p.CanCollide=collide==true;return p end
    local function rod(name,a,b,r,color,target)return Geo.rod(target or model,name,origin+Vector3.new(table.unpack(a)),origin+Vector3.new(table.unpack(b)),r,color)end
    local function surface(p,face,ppx)
        local gui=Instance.new('SurfaceGui');gui.Name='Print';gui.Face=face or Enum.NormalId.Front;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=ppx or 12;gui.LightInfluence=0;gui.MaxDistance=320;gui.Parent=p
        return gui
    end
    local function text(gui,name,value,size,color,pos,dim,display,align)
        local t=Instance.new('TextLabel');t.Name=name;t.BackgroundTransparency=1;t.Position=pos or UDim2.fromOffset(0,0);t.Size=dim or UDim2.fromScale(1,1)
        t.Font=Enum.Font.BuilderSansBold;if display then local f=oswald();if f then t.FontFace=f end end
        t.TextScaled=false;t.TextWrapped=true;t.TextSize=math.min(100,size or 40);t.Text=value;t.TextColor3=color or palette.ink;t.TextXAlignment=align or Enum.TextXAlignment.Center;t.Parent=gui
        return t
    end
    local function rect(gui,pos,dim,color,alpha)
        local f=Instance.new('Frame');f.Position=pos;f.Size=dim;f.BackgroundColor3=color;f.BackgroundTransparency=alpha or 0;f.BorderSizePixel=0;f.Parent=gui;return f
    end
    local MESH={
        wall={mesh=125365072526785,tex=nil,color=rgb(44,54,68),material=Enum.Material.Metal,size=Vector3.new(30,25.094,4.624)},
        console={mesh=138254590508571,tex=75163347490155,size=Vector3.new(17.667,16.887,10)},
        chair={mesh=135564428959182,tex=76252976632803,size=Vector3.new(3,4.933,2.966)},
    }
    local templates={}
    local function meshPart(name,key,cframe,scale,collide)
        local def=MESH[key]
        if templates[key]==nil then
            local ok,mp=pcall(function()return game:GetService('AssetService'):CreateMeshPartAsync(Content.fromUri('rbxassetid://'..def.mesh),{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Automatic})end)
            if ok and mp then
                if def.tex then pcall(function()mp.TextureID='rbxassetid://'..def.tex end)else mp.Color=def.color or palette.steel;mp.Material=def.material or Enum.Material.Metal end
                mp.Anchored=true;mp.CanCollide=false;mp.CanTouch=false;mp.CanQuery=false;mp.CastShadow=true
            end
            templates[key]=ok and mp or false
        end
        local t=templates[key];if not t then return nil end
        local p=t:Clone();p.Name=name;p.Size=def.size*scale;p.CFrame=cframe;p.CanCollide=collide==true;p.Parent=model
        return p
    end
    local function light(kind,parentPart,color,brightness,range,angle,face)
        local l=Instance.new(kind);l.Color=color;l.Brightness=brightness;l.Range=range;if angle then l.Angle=angle end;if face then l.Face=face end;l.Shadows=kind=='SpotLight';l.Parent=parentPart;return l
    end

    local deck=block('DeckFloor',{520,4,360},{0,-2,-10},palette.deck,true,nil,Enum.Material.Metal);deck.CastShadow=false
    local grid=surface(deck,Enum.NormalId.Top,2)
    for i=0,52 do rect(grid,UDim2.fromOffset(i*20,0),UDim2.new(0,1,1,0),palette.line,i%5==0 and .1 or .74)end
    for i=0,36 do rect(grid,UDim2.fromOffset(0,i*20),UDim2.new(1,0,0,1),palette.line,i%5==0 and .1 or .74)end
    deck.Reflectance=.04
    block('HallFloor',{900,4,900},{0,-62,0},palette.inset,false)
    local backWall=block('BackWall',{420,90,6},{0,43,-128},palette.wall,false,nil,Enum.Material.Concrete)
    local wash=Instance.new('SurfaceLight');wash.Face=Enum.NormalId.Back;wash.Angle=80;wash.Range=40;wash.Brightness=1.2;wash.Color=rgb(150,200,230);wash.Parent=backWall
    wash.Enabled=false
    for _,x in ipairs({-172,172})do block('SideWall',{6,90,320},{x,43,-10},palette.wall,false,nil,Enum.Material.Concrete)end
    block('HallCeiling',{352,2,310},{0,89,15},rgb(16,21,28),false).CastShadow=false
    for i=-4,4 do block('CeilingBeam',{2.4,3,310},{i*40,86.5,15},rgb(32,41,52),false,nil,Enum.Material.Metal).CastShadow=false end
    for i=0,7 do block('CeilingBeam',{352,3,2.4},{0,86.5,-118+i*40},rgb(32,41,52),false,nil,Enum.Material.Metal).CastShadow=false end
    local clad=0
    for i=0,13 do for row=0,1 do
        if meshPart('WallPanel','wall',cf(-195+i*30,12.55+row*25.1,-125.6),1)then clad+=1 end
    end end
    for _,side in ipairs({-1,1})do for i=0,7 do
        if meshPart('WallPanel','wall',cf(side*166.7,12.55,-105+i*30)*CFrame.Angles(0,side<0 and math.pi/2 or -math.pi/2,0),1)then clad+=1 end
    end end
    model:SetAttribute('WallPanels',clad)
    if clad==0 then
        wash.Enabled=true
        for i=-6,6 do
            block('WallRib',{4,90,3},{i*30,43,-124.5},palette.steel,false)
            neon('WallStrip',{14,.6,.4},{i*30+15,6,-124.6},palette.teal,.55)
        end
        for _,x in ipairs({-168.5,168.5})do for i=-4,4 do block('SideRib',{3,90,4},{x,43,-10+i*32},palette.steel,false)end end
    end
    local header=block('HQHeader',{120,14,1},{0,64,-122},palette.inset,false)
    block('HQHeaderFrame',{122.4,15.6,.6},{0,64,-122.7},rgb(58,70,86),false,nil,Enum.Material.Metal)
    local hg=surface(header,Enum.NormalId.Back,8)
    text(hg,'Kicker','S  U  P  E  R',26,palette.teal,UDim2.fromOffset(0,2),UDim2.new(1,0,0,26),true)
    text(hg,'Title','COMMANDER',100,palette.ink,UDim2.fromOffset(0,22),UDim2.new(1,0,0,70),true)
    rect(hg,UDim2.new(.5,-120,0,94),UDim2.fromOffset(240,3),palette.teal)
    do
        local board=block('BigBoard',{200,40,1},{0,34,-121.5},palette.inset,false)
        block('BigBoardFrame',{202,.5,1.2},{0,54.2,-121.5},palette.steelLight,false,nil,Enum.Material.Metal);block('BigBoardFrame',{202,.5,1.2},{0,13.8,-121.5},palette.steelLight,false,nil,Enum.Material.Metal)
        local g=surface(board,Enum.NormalId.Back,6)
        for i=0,24 do rect(g,UDim2.fromOffset(i*50,0),UDim2.new(0,1,1,0),palette.line,.6)end
        for i=0,4 do rect(g,UDim2.fromOffset(0,i*60),UDim2.new(1,0,0,1),palette.line,.6)end
        rect(g,UDim2.fromOffset(0,0),UDim2.fromOffset(900,240),rgb(6,11,17),.1)
        for _,c in ipairs({{24,20,1,1},{876,20,-1,1},{24,220,1,-1},{876,220,-1,-1}})do
            rect(g,UDim2.fromOffset(c[3]>0 and c[1] or c[1]-40,c[4]>0 and c[2] or c[2]-2),UDim2.fromOffset(40,2),palette.steelLight,.3)
            rect(g,UDim2.fromOffset(c[3]>0 and c[1] or c[1]-2,c[4]>0 and c[2] or c[2]-40),UDim2.fromOffset(2,40),palette.steelLight,.3)
        end
        rect(g,UDim2.fromOffset(920,0),UDim2.new(0,2,1,0),palette.teal,.4)
        for i=0,5 do
            local y=58+i*29;local col=({palette.teal,palette.azure,palette.violet,palette.amber,palette.teal,palette.ice})[i+1]
            rect(g,UDim2.fromOffset(940,y),UDim2.fromOffset(8,18),col,0)
            rect(g,UDim2.fromOffset(956,y+5),UDim2.fromOffset(60+((i*53)%160),8),col,.35)
        end
    end

    local mapW,mapD=104,52;local mapX,mapZ=0,2;local top=4
    local base=block('HoloTableBase',{mapW+4,top-1,mapD+4},{mapX,(top-1)/2,mapZ},palette.steel,true,nil,Enum.Material.Metal);base.Transparency=1;base.CastShadow=false
    block('HoloTablePlinth',{mapW+18,.3,mapD+18},{mapX,.15,mapZ},rgb(40,50,63),false,nil,Enum.Material.Metal).CastShadow=false
    block('TableFloorField',{mapW+40,.04,mapD+40},{mapX,.02,mapZ},rgb(24,31,41),false,nil,Enum.Material.Metal).CastShadow=false
    for _,k in ipairs({{mapW+40,.5,mapX,mapZ-mapD/2-20},{mapW+40,.5,mapX,mapZ+mapD/2+20},{.5,mapD+40,mapX-mapW/2-20,mapZ},{.5,mapD+40,mapX+mapW/2+20,mapZ}})do
        block('TableFloorKerb',{k[1],.08,k[2]},{k[3],.05,k[4]},rgb(84,98,116),false,nil,Enum.Material.Metal).CastShadow=false
    end
    local gunmetal,bezelSteel=rgb(58,70,86),rgb(88,102,120)
    block('TablePedestal',{mapW-14,2.4,mapD-14},{mapX,1.5,mapZ},palette.inset,false,nil,Enum.Material.Metal)
    block('TableFoot',{mapW-8,.6,mapD-8},{mapX,.6,mapZ},gunmetal,false,nil,Enum.Material.Metal).CastShadow=false
    for _,sx in ipairs({-1,1})do for _,sz in ipairs({-1,1})do
        block('TableLeg',{5,2.3,5},{mapX+sx*(mapW/2-3),1.45,mapZ+sz*(mapD/2-3)},gunmetal,false,nil,Enum.Material.Metal)
        block('TableLegFoot',{6.4,.5,6.4},{mapX+sx*(mapW/2-3),.55,mapZ+sz*(mapD/2-3)},bezelSteel,false,nil,Enum.Material.Metal).CastShadow=false
    end end
    block('TableApron',{mapW+7,1.3,mapD+7},{mapX,top-1.65,mapZ},gunmetal,false,nil,Enum.Material.Metal)
    block('TableApronSeam',{mapW+7.3,.14,mapD+7.3},{mapX,top-1.05,mapZ},palette.inset,false).CastShadow=false
    block('HoloTableTop',{mapW+8,1,mapD+8},{mapX,top-.5,mapZ},rgb(30,38,49),true,nil,Enum.Material.Metal)
    neon('HoloTableRim',{mapW+8.2,.08,mapD+8.2},{mapX,top-.98,mapZ},palette.teal,.78)
    for _,b in ipairs({{mapW+8,mapZ-mapD/2-2,0},{mapW+8,mapZ+mapD/2+2,0},{mapD,mapX-mapW/2-2,1},{mapD,mapX+mapW/2+2,1}})do
        local len,at,ns=b[1],b[2],b[3]==1
        local size=ns and {4,.55,len} or {len,.55,4}
        local pos=ns and {at,top+.27,mapZ} or {mapX,top+.27,at}
        block('TableBezel',size,pos,bezelSteel,false,nil,Enum.Material.Metal).CastShadow=false
        local inner=ns and {at-(at>mapX and 1.75 or -1.75),top+.6,mapZ} or {mapX,top+.6,at-(at>mapZ and 1.75 or -1.75)}
        block('TableBevel',ns and {.5,.12,len} or {len,.12,.5},inner,rgb(120,136,154),false,nil,Enum.Material.Metal).CastShadow=false
    end
    neon('TableScreenLine',{mapW+.3,.05,mapD+.3},{mapX,top+.02,mapZ},palette.ice,.86)
    for _,sz in ipairs({-1,1})do
        local z=mapZ+sz*(mapD/2+5.2)
        rod('TableRail',{mapX-mapW/2+3,top-.45,z},{mapX+mapW/2-3,top-.45,z},.22,bezelSteel).CastShadow=false
        for i=0,6 do local x=mapX-mapW/2+3+i*(mapW-6)/6
            rod('TableRailPost',{x,top-1.6,mapZ+sz*(mapD/2+3.6)},{x,top-.45,z},.16,gunmetal).CastShadow=false
        end
    end
    for _,e in ipairs({{-1,palette.teal},{1,palette.violet}})do
        local x=mapX+e[1]*(mapW/2+6.4)
        block('TablePodBody',{4.4,3.6,18},{x,1.8,mapZ},gunmetal,false,nil,Enum.Material.Metal)
        local face=block('TablePod',{4.6,.4,17},{x,3.75,mapZ},palette.inset,false,CFrame.Angles(0,0,math.rad(e[1]*-16)))
        local g=surface(face,Enum.NormalId.Top,8)
        rect(g,UDim2.fromOffset(4,4),UDim2.new(0,3,1,-8),e[2],.2)
        for i=0,4 do rect(g,UDim2.fromOffset(14,14+i*26),UDim2.fromOffset(i%2==0 and 14 or 9,4),e[2],.45+i*.08)end
    end
    block('MapSea',{mapW,.1,mapD},{mapX,top+.05,mapZ},palette.sea,false).CastShadow=false
    local ok,preview=pcall(function()return Maps.preview('world')end)
    local landCells=0
    if ok and preview then
        local pw,ph=preview.meta.width,preview.meta.height;local cols,rows=64,32;local cw,cd=mapW/cols,mapD/rows
        local function land(cx,cy)
            local x=math.floor((cx+.5)/cols*pw);local y=math.floor((cy+.5)/rows*ph)
            return Terrain.isLand(buffer.readu8(preview.terrain,y*pw+x))
        end
        local function owner(cx,cy)
            local u=cx/cols;local n=(cx*928371+cy*1237)%17
            if n==0 then return palette.land end
            return u<.36 and palette.teal or u<.62 and palette.azure or palette.violet
        end
        for cy=0,rows-1 do
            local start,color=nil,nil
            for cx=0,cols do
                local isLand=cx<cols and land(cx,cy);local c=isLand and owner(cx,cy)or nil
                if c~=color or not isLand then
                    if start and color then
                        local width=(cx-start)*cw;local x=mapX-mapW/2+(start*cw)+width/2;local z=mapZ-mapD/2+(cy+.5)*cd
                        local cell=Geo.block(model,'Territory',Vector3.new(width,.2,cd),cf(x,top+.2,z),color);cell.CastShadow=false
                        if color~=palette.land then cell.Material=Enum.Material.Neon;cell.Transparency=.42 end
                        landCells+=1
                    end
                    start=isLand and cx or nil;color=c
                end
            end
        end
    end
    model:SetAttribute('MapCells',landCells)
    for _,f in ipairs({{-34,-6,palette.teal},{4,-2,palette.azure},{34,6,palette.violet}})do
        rod('PinStem',{f[1],top,f[2]},{f[1],top+6,f[2]},.2,palette.steelLight)
        local head=Geo.ball(model,'PinHead',Vector3.new(2.2,2.2,2.2),cf(f[1],top+6.8,f[2]),f[3]);head.Material=Enum.Material.Neon;head:SetAttribute('Bob',true)
        local ring=neon('PinRing',{5,.08,5},{f[1],top+.36,f[2]},f[3],.5);ring.Shape=Enum.PartType.Cylinder;ring.Size=Vector3.new(.08,5,5);ring.CFrame=cf(f[1],top+.36,f[2])*CFrame.Angles(0,0,math.pi/2)
    end
    local function radar(name,size,y,color,alpha)
        local p=block(name,{size,.1,size},{mapX,y,mapZ},color,false);p.Transparency=1;p.CastShadow=false;p:SetAttribute('Spin',true)
        for _,face in ipairs({Enum.NormalId.Top,Enum.NormalId.Bottom})do
            local g=Instance.new('SurfaceGui');g.Name='Radar';g.Face=face;g.CanvasSize=Vector2.new(700,700);g.LightInfluence=0;g.MaxDistance=400;g.Parent=p
            local circle=rect(g,UDim2.fromScale(.5,.5),UDim2.fromOffset(660,660),color,1);circle.AnchorPoint=Vector2.new(.5,.5)
            local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(.5,0);corner.Parent=circle
            local s=Instance.new('UIStroke');s.Color=color;s.Thickness=4;s.Transparency=alpha;s.Parent=circle
            for i=0,35 do
                local a=i/36*math.pi*2;local tick=rect(g,UDim2.fromOffset(350+math.cos(a)*312,350+math.sin(a)*312),UDim2.fromOffset(i%9==0 and 6 or 3,i%9==0 and 34 or 16),color,alpha)
                tick.AnchorPoint=Vector2.new(.5,.5);tick.Rotation=math.deg(a)+90
            end
            local sweep=rect(g,UDim2.fromOffset(350,348),UDim2.fromOffset(330,4),color,alpha+.15)
            local fade=Instance.new('UIGradient');fade.Transparency=NumberSequence.new(0,1);fade.Rotation=180;fade.Parent=sweep
        end
        return p
    end
    radar('RadarHalo',44,top+21,palette.teal,.25)
    local world=Geo.ball(model,'HoloWorld',Vector3.new(9,9,9),cf(mapX,top+21,mapZ),palette.teal);world.Material=Enum.Material.ForceField;world.CastShadow=false;world:SetAttribute('Spin',true)
    local core=Geo.ball(model,'HoloWorldCore',Vector3.new(2.4,2.4,2.4),cf(mapX,top+21,mapZ),palette.teal);core.Material=Enum.Material.Neon;core.Transparency=.6;core.CastShadow=false;core:SetAttribute('Pulse',true)
    neon('HoloColumn',{.8,17.5,.8},{mapX,top+8.75,mapZ},palette.teal,.55):SetAttribute('Pulse',true)
    local scan=neon('TableScan',{.6,.12,mapD+2},{mapX,top+.4,mapZ},palette.teal,.62);scan:SetAttribute('Sweep',mapW/2-1)
    local tableSpot=block('TableLightRig',{2,2,2},{mapX,44,mapZ},palette.steel,false);tableSpot.Transparency=1
    light('SpotLight',tableSpot,rgb(200,230,255),3,60,70,Enum.NormalId.Bottom)
    for _,p in ipairs({{-60,30},{60,30},{-60,-20},{60,-20},{0,50}})do
        local a=block('FillLight',{1,1,1},{p[1],34,p[2]},palette.steel,false);a.Transparency=1
        light('PointLight',a,rgb(190,215,240),1.4,60)
    end

    local modeZ=-50
    local function station(id,title,sub,x,color,glyph)
        local screen=block('SignNote_'..id,{30,17,.8},{x,22,modeZ-21},palette.inset,false)
        neon('ScreenEdge_'..id,{30.6,.3,.9},{x,13.3,modeZ-21},color,.45)
        block('ScreenBezel_'..id,{31.6,18.2,.5},{x,22,modeZ-21.5},rgb(58,70,86),false,nil,Enum.Material.Metal)
        local g=surface(screen,Enum.NormalId.Back,12)
        rect(g,UDim2.fromOffset(0,0),UDim2.new(0,8,1,0),color)
        text(g,'Glyph',glyph,72,color,UDim2.fromOffset(30,22),UDim2.fromOffset(90,90),true)
        rect(g,UDim2.new(0,30,1,-26),UDim2.new(1,-60,0,4),color,.5)
        for _,dx in ipairs({-14,14})do block('ScreenPost',{1.2,30,1.2},{x+dx,15,modeZ-21.6},palette.steel,false)end
        if not meshPart('StationConsole','console',cf(x,7.6,modeZ-8),.9,true)then
            block('ConsoleDesk',{22,4,7},{x,2,modeZ-8},palette.steel,true,nil,Enum.Material.Metal)
            local deskTop=block('ConsoleTop',{22,.4,7},{x,4.2,modeZ-8},palette.inset,false,CFrame.Angles(math.rad(-12),0,0))
            local dg=surface(deskTop,Enum.NormalId.Top,8)
            for i=0,3 do rect(dg,UDim2.fromOffset(14,10+i*12),UDim2.fromOffset(i%2==0 and 90 or 60,5),color,.35+i*.12)end
        end
        local spotAnchor=block('ConsoleLight',{1,1,1},{x,30,modeZ-4},color,false);spotAnchor.Transparency=1
        light('SpotLight',spotAnchor,color,2.2,60,48,Enum.NormalId.Bottom)
        local pad=block('ModePad_'..id,{18,.5,8},{x,.25,modeZ+16},palette.steel,true,nil,Enum.Material.Metal)
        neon('ModeGlow_'..id,{18.4,.1,8.4},{x,.08,modeZ+16},color,.45):SetAttribute('Pulse',true)
        for i=0,2 do
            for _,s in ipairs({-1,1})do
                neon('PadChevron_'..id,{4.4,.06,.5},{x+s*1.4,.53,modeZ+18.4-i*2.2},color,.2,CFrame.Angles(0,s*math.rad(40),0)):SetAttribute('Pulse',true)
            end
        end
        return screen,pad
    end
    station('single','혼자 하기','AI 국가를 상대로 바로 시작',-62,palette.teal,'◎')
    station('pvp','공식 전장','클래식 PvP, 개인전, 팀전',0,palette.azure,'⚔')
    station('coop','협동','친구와 함께 AI 국가 상대',62,palette.lime,'◇')

    do
        local x,z=-82,10
        for i=-1,1 do
            block('Locker',{7,16,5},{x+i*7.4,8,z-6},palette.steel,true,nil,Enum.Material.Metal)
            neon('LockerStrip',{.4,12,.3},{x+i*7.4+2.8,8,z-3.4},i==0 and palette.teal or palette.line,i==0 and .2 or .6)
            for v=0,1 do block('LockerVent',{4.6,.3,.1},{x+i*7.4-.4,13.6-v*.8,z-3.47},palette.inset,false)end
            block('LockerPlate',{3,1.2,.1},{x+i*7.4-.4,10.6,z-3.47},palette.steelLight,false)
            block('LockerDoor',{6,14.4,.06},{x+i*7.4,8,z-3.48},rgb(40,50,63),false,nil,Enum.Material.Metal)
            block('LockerBevel',{7,.7,.7},{x+i*7.4,15.75,z-3.5},palette.steelLight,false,CFrame.Angles(math.rad(45),0,0),Enum.Material.Metal)
        end
        block('LockerPlinth',{24,.6,7},{x,.3,z-6},palette.inset,false,nil,Enum.Material.Metal)
        block('LockerCap',{23.4,.5,5.6},{x,16.25,z-6},palette.steelLight,false,nil,Enum.Material.Metal)
        local sign=block('WardrobeNote',{20,5,.4},{x,19.5,z-3.6},palette.inset,false)
        block('WardrobeNoteFrame',{21,6,.3},{x,19.5,z-3.95},rgb(58,70,86),false,nil,Enum.Material.Metal)
        local g=surface(sign,Enum.NormalId.Back,12)
        rect(g,UDim2.fromOffset(0,0),UDim2.new(0,6,1,0),palette.teal)
        local bench=block('LockerBench',{18,2,4},{x,1,z+2},palette.steel,true)
        local anchor=block('BayLight',{1,1,1},{x,30,z},palette.teal,false);anchor.Transparency=1;light('SpotLight',anchor,rgb(170,230,225),1.6,45,60,Enum.NormalId.Bottom)
    end
    do
        local x,z=84,30
        block('RecordsCabinet',{16,14,6},{x,7,z-4},palette.steel,true,nil,Enum.Material.Metal)
        block('RecordsPlinth',{17,.6,7},{x,.3,z-4},palette.inset,false,nil,Enum.Material.Metal)
        block('RecordsCap',{16.6,.5,6.6},{x,14.25,z-4},palette.steelLight,false,nil,Enum.Material.Metal)
        for d=0,2 do
            block('RecordsDrawer',{15,.15,.1},{x,3.6+d*3.6,z-.96},palette.inset,false)
            block('RecordsHandle',{3,.4,.3},{x,5.4+d*3.6,z-.86},palette.steelLight,false,nil,Enum.Material.Metal)
        end
        block('RecordsFrame',{15,10,.3},{x,19,z-1.55},palette.steelLight,false,nil,Enum.Material.Metal)
        local screen=block('RecordsNote',{14,9,.4},{x,19,z-1.2},palette.inset,false)
        local g=surface(screen,Enum.NormalId.Back,12)
        rect(g,UDim2.fromOffset(0,0),UDim2.new(1,0,0,6),palette.gold)
        local medal=Geo.ball(model,'RecordsMedal',Vector3.new(3,3,.6),cf(x,16.6+9,z-1),palette.gold);medal.Material=Enum.Material.Neon;medal:SetAttribute('Spin',true)
    end

    for i=0,6 do neon('GuideDash',{.8,.06,3},{0,.04,43-i*5},rgb(70,140,150),.78)end
    do
        local z=P.spawnZ
        local plate=cyl('CommandDais',9,.6,0,.3,z,palette.steel,true);plate.Material=Enum.Material.Metal
        local rim=cyl('CommandDaisRim',9.25,.14,0,.07,z,palette.teal,false);rim.Material=Enum.Material.Neon;rim.Transparency=.72;rim.CastShadow=false
        local inlay=block('CommandDaisInlay',{17,.05,17},{0,.63,z},palette.steel,false);inlay.Transparency=1;inlay.CastShadow=false
        local g=Instance.new('SurfaceGui');g.Name='Inlay';g.Face=Enum.NormalId.Top;g.CanvasSize=Vector2.new(600,600);g.LightInfluence=.3;g.MaxDistance=260;g.Parent=inlay
        for _,ring in ipairs({{576,5,.2},{392,2,.55}})do
            local c=rect(g,UDim2.fromScale(.5,.5),UDim2.fromOffset(ring[1],ring[1]),palette.teal,1);c.AnchorPoint=Vector2.new(.5,.5)
            local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(.5,0);corner.Parent=c
            local stroke=Instance.new('UIStroke');stroke.Color=palette.teal;stroke.Thickness=ring[2];stroke.Transparency=ring[3];stroke.Parent=c
        end
        for i=0,3 do
            local a=i*math.pi/2;local tick=rect(g,UDim2.fromOffset(300+math.cos(a)*240,300+math.sin(a)*240),UDim2.fromOffset(6,40),palette.teal,.15)
            tick.AnchorPoint=Vector2.new(.5,.5);tick.Rotation=math.deg(a)+90
        end
        local key=block('DaisKeyLight',{1,1,1},{0,22,z+14},palette.steel,false,CFrame.lookAt(Vector3.zero,Vector3.new(0,-19,-14)));key.Transparency=1
        light('SpotLight',key,rgb(255,226,196),3.4,44,34,Enum.NormalId.Front)
        local rimLight=block('DaisRimLight',{1,1,1},{0,16,z-12},palette.steel,false,CFrame.lookAt(Vector3.zero,Vector3.new(0,-11.5,12)));rimLight.Transparency=1
        light('SpotLight',rimLight,rgb(150,214,255),2.4,30,40,Enum.NormalId.Front).Shadows=false
    end

    do
        local board=block('LiveBoard',{24,15,.6},{-128,30,-121.4},palette.inset,false)
        block('LiveBoardFrame',{25.4,16.4,.5},{-128,30,-121.8},palette.steel,false,nil,Enum.Material.Metal)
        neon('LiveBoardEdge',{25.4,.3,.6},{-128,21.9,-121.4},palette.teal,.35)
        local gui=Instance.new('SurfaceGui');gui.Name='Live';gui.Face=Enum.NormalId.Back;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=12;gui.LightInfluence=0;gui.MaxDistance=200;gui.Parent=board
        local note=rect(gui,UDim2.fromOffset(12,12),UDim2.new(1,-24,0,52),palette.steel,0);note.Name='StatsNote'
        rect(note,UDim2.fromOffset(0,0),UDim2.new(0,5,1,0),palette.teal)
        local paper=rect(gui,UDim2.fromOffset(12,74),UDim2.new(1,-24,1,-86),palette.inset,0);paper.Name='LeadersNote'
    end

    for _,x in ipairs({-64,0,64})do for _,z in ipairs({-36,18})do
        local panel=neon('CeilingPanel',{33,.3,4.2},{x,58.4,z},rgb(118,146,170),.8)
        block('CeilingPanelHousing',{35.6,1.6,6.4},{x,59.3,z},rgb(32,41,52),false,nil,Enum.Material.Metal).CastShadow=false
        for _,dz in ipairs({-3.05,3.05})do block('CeilingPanelLip',{35.6,.5,.3},{x,58.25,z+dz},rgb(58,70,86),false,nil,Enum.Material.Metal).CastShadow=false end
        for i=1,4 do block('CeilingLouver',{.25,.7,4.4},{x-16.5+i*6.6,58.05,z},rgb(24,31,40),false,nil,Enum.Material.Metal).CastShadow=false end
        for _,dx in ipairs({-15,15})do rod('PanelHanger',{x+dx,60.1,z},{x+dx,88,z},.12,palette.steel)end
        light('PointLight',panel,rgb(190,215,240),.9,45)
        light('SpotLight',panel,rgb(200,225,250),1.6,58,55,Enum.NormalId.Bottom)
    end end
    do
        local pool={};local skip={aq=true,eu=true,un=true,bv=true,cp=true,dg=true,hm=true,ic=true,gs=true,xk=true}
        for code in pairs(FlagAtlas.index)do if not skip[code]then table.insert(pool,code)end end
        table.sort(pool);local rng=Random.new()
        local codes={}
        for i=1,8 do local pick;repeat pick=pool[rng:NextInteger(1,#pool)]until not table.find(codes,pick);codes[i]=pick end
        local flags={}
        local function offset(code)local index=FlagAtlas.index[code];return Vector2.new(index%FlagAtlas.columns*FlagAtlas.cell.X,math.floor(index/FlagAtlas.columns)*FlagAtlas.cell.Y)end
        for i,code in ipairs(codes)do
            local side=i<=4 and -1 or 1;local z=-78+((i-1)%4)*42
            local banner=block('NationBanner_'..i,{.4,24,14},{side*167.6,44,z},palette.inset,false)
            block('BannerRod',{1,1,16},{side*167.4,56.6,z},palette.steelLight,false)
            local g=Instance.new('SurfaceGui');g.Name='Flag';g.Face=side<0 and Enum.NormalId.Right or Enum.NormalId.Left;g.CanvasSize=Vector2.new(280,480);g.LightInfluence=.6;g.MaxDistance=360;g.Parent=banner
            local index=FlagAtlas.index[code]
            if index then
                local img=Instance.new('ImageLabel');img.Size=UDim2.new(1,-24,0,198);img.Position=UDim2.fromOffset(12,12);img.BackgroundTransparency=1;img.ScaleType=Enum.ScaleType.Stretch;img.Image=FlagAtlas.image
                img.ImageRectSize=FlagAtlas.cell;img.ImageRectOffset=offset(code);img.Parent=g;flags[i]=img
            end
            rect(g,UDim2.fromOffset(12,222),UDim2.new(1,-24,0,4),palette.teal,.3)
            for r=0,5 do rect(g,UDim2.fromOffset(12,246+r*36),UDim2.new(1,-24-((r*37)%90),0,10),palette.line,.2)end
        end
        task.spawn(function()
            local TweenService=game:GetService('TweenService');local fade=TweenInfo.new(.35)
            while task.wait(4)do
                local i=rng:NextInteger(1,#codes);local img=flags[i]
                if img and not img.Parent then break end
                if img then
                    local pick;repeat pick=pool[rng:NextInteger(1,#pool)]until not table.find(codes,pick)
                    codes[i]=pick
                    local t=TweenService:Create(img,fade,{ImageTransparency=1});t:Play();t.Completed:Wait()
                    img.ImageRectOffset=offset(pick);TweenService:Create(img,fade,{ImageTransparency=0}):Play()
                end
            end
        end)
    end
    local stations=0
    for _,side in ipairs({-1,1})do
        for i=0,2 do
            local z=-64+i*30;local x=side*130
            if meshPart('OperatorConsole','console',cf(x,6.35,z)*CFrame.Angles(0,side<0 and math.pi/2 or -math.pi/2,0),.75)then stations+=1
                meshPart('OperatorChair','chair',cf(side*123.4,2.72,z)*CFrame.Angles(0,side<0 and -math.pi/2 or math.pi/2,0),1.1)
            else
                block('ServerRack',{8,24,12},{x,12,z},palette.steel,true,nil,Enum.Material.Metal)
                block('RackFace',{.3,20,10},{x-side*4.1,12,z},palette.inset,false)
            end
        end
    end
    model:SetAttribute('OperatorConsoles',stations)
    require(pack.Client.WorldDressing).plaza(model,origin)

    local hw,hd=P.width/2,P.depth/2
    for _,v in ipairs({{0,-hd,P.width,1},{0,hd,P.width,1},{-hw,0,1,P.depth},{hw,0,1,P.depth}})do
        local wall=block('SafetyRail',{v[3],40,v[4]},{v[1],20,v[2]},palette.ink,true);wall.Transparency=1
    end
    for _,p in ipairs(model:GetDescendants())do if p:IsA('BasePart')and p.Size.Magnitude<6 then p.CastShadow=false end end
    model:SetAttribute('FloorTextCount',0);model:SetAttribute('PartCount',#model:GetDescendants())
    return model
end
return M
