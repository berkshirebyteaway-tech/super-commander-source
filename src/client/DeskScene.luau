local G=require(script.Parent.Parent.Core.WorldGeometry)
local Geo=require(script.Parent.ToyGeometry)
local M={}
local rgb=Color3.fromRGB
local slab,steel,bezel,inset=rgb(13,18,25),rgb(24,33,44),rgb(30,41,54),rgb(9,13,18)
local accent,ice,muted=rgb(54,226,208),rgb(191,239,255),rgb(138,151,168)
function M.create(parent,meta)
    local folder=Instance.new("Folder");folder.Name="ToyDesk";folder.Parent=parent
    local w,d=meta.width*G.scale,meta.height*G.scale;local hx,hz=w/2,d/2;local y=G.surfaceY
    local function b(name,size,pos,color,rotation)
        local shape=(name=='OpsTable'or name=='TableLip'or name=='BezelFrame')and 'board'or 'armor'
        local p=Geo.part(folder,name,Vector3.new(table.unpack(size)),CFrame.new(table.unpack(pos))*CFrame.Angles(0,rotation or 0,0),color,shape)
        p.Material=Enum.Material.Metal;p.Reflectance=.015;return p
    end
    local function face(part,cw,ch,light)
        local gui=Instance.new("SurfaceGui");gui.Name="DeskPrint";gui.Face=Enum.NormalId.Top;gui.CanvasSize=Vector2.new(cw,ch);gui.LightInfluence=light or .2;gui.MaxDistance=4000;gui.Parent=part;return gui
    end
    local function rect(gui,pos,size,color,alpha)
        local r=Instance.new("Frame");r.Position=pos;r.Size=size;r.BackgroundColor3=color;r.BackgroundTransparency=alpha or 0;r.BorderSizePixel=0;r.Parent=gui;return r
    end
    local function text(gui,pos,size,value,ts,color,font,align)
        local t=Instance.new("TextLabel");t.Position=pos;t.Size=size;t.BackgroundTransparency=1;t.Text=value;t.TextSize=ts;t.TextColor3=color
        t.FontFace=font or Font.new("rbxasset://fonts/families/Oswald.json",Enum.FontWeight.Bold);t.TextXAlignment=align or Enum.TextXAlignment.Left;t:SetAttribute("LocalizationSkip",true);t.Parent=gui;return t
    end
    local top=b("OpsTable",{w+150,4.2,d+130},{0,y-4.1,0},slab)
    local grid=face(top,1024,768,.35)
    for i=1,23 do rect(grid,UDim2.fromScale(i/24,0),UDim2.new(0,1,1,0),steel,.55)end
    for i=1,17 do rect(grid,UDim2.fromScale(0,i/18),UDim2.new(1,0,0,1),steel,.55)end
    local vignette=rect(grid,UDim2.fromScale(0,0),UDim2.fromScale(1,1),rgb(4,6,9),0)
    local fade=Instance.new("UIGradient");fade.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.2),NumberSequenceKeypoint.new(.5,1),NumberSequenceKeypoint.new(1,.2)});fade.Parent=vignette
    b("TableLip",{w+152,1.1,d+132},{0,y-6.5,0},inset)
    b('TableEdgeTrim',{w+150,.22,d+130},{0,y-6,0},rgb(53,66,81))
    b("BezelFrame",{w+11,1.2,d+11},{0,y-1.25,0},bezel)
    local rim=b("BezelSignal",{w+7.2,.3,d+7.2},{0,y-.55,0},accent);rim.Material=Enum.Material.Neon;rim.Transparency=.35;rim.CastShadow=false
    b("BezelInset",{w+5.4,.24,d+5.4},{0,y-.28,0},inset)
    for _,z in ipairs({-hz-4.4,hz+4.4})do
        local strip=b("BoardScale",{w-2,.03,1.1},{0,y-.6,z},bezel)
        local gui=face(strip,48,math.max(128,math.floor(w*3)),0)
        local n=math.floor(w/12)
        for i=0,n do rect(gui,UDim2.new(0,0,i/math.max(1,n),0),UDim2.new(i%5==0 and .9 or .45,0,0,1),ice,i%5==0 and .25 or .6)end
    end
    for _,sx in ipairs({-1,1})do for _,sz in ipairs({-1,1})do
        local cx,cz=sx*(hx+6.6),sz*(hz+6.6)
        b("CornerBracketX",{14,.5,1.1},{cx-sx*6.4,y-.45,cz},ice).CastShadow=false
        b("CornerBracketZ",{1.1,.5,14},{cx,y-.45,cz-sz*6.4},ice).CastShadow=false
    end end
    local px,pz=hx*.42,hz+26
    b("MapNamePlaqueBase",{16.4,.5,73},{px,y-1.85,pz},inset,-math.pi/2)
    local edge=b("MapNamePlaqueEdge",{15.2,.12,71.6},{px,y-1.55,pz},accent,-math.pi/2);edge.Material=Enum.Material.Neon;edge.Transparency=.55;edge.CastShadow=false
    local plate=b("MapNamePlaque",{14,.4,70},{px,y-1.4,pz},bezel,-math.pi/2)
    local gui=face(plate,700,140,.15)
    local glass=rect(gui,UDim2.fromOffset(0,0),UDim2.fromScale(1,1),rgb(20,28,38))
    local sheen=Instance.new("UIGradient");sheen.Rotation=90;sheen.Color=ColorSequence.new(rgb(36,48,62),rgb(12,17,24));sheen.Parent=glass
    rect(gui,UDim2.fromOffset(0,0),UDim2.new(1,0,0,2),ice,.55)
    local bar=rect(gui,UDim2.fromOffset(0,0),UDim2.new(0,8,1,0),accent)
    local barFade=Instance.new("UIGradient");barFade.Rotation=90;barFade.Transparency=NumberSequence.new(0,.45);barFade.Parent=bar
    for _,cx in ipairs({0,1})do for _,cy in ipairs({0,1})do
        rect(gui,UDim2.new(cx,cx==1 and -22 or 14,cy,cy==1 and -8 or 6),UDim2.fromOffset(16,2),ice,.35)
    end end
    local name=text(gui,UDim2.fromOffset(32,12),UDim2.new(1,-64,0,62),string.upper(meta.label or meta.key or "THEATER"),48,rgb(238,242,246))
    name.TextStrokeColor3=rgb(4,6,9);name.TextStrokeTransparency=.55
    rect(gui,UDim2.fromOffset(32,80),UDim2.new(1,-64,0,1),muted,.6)
    text(gui,UDim2.fromOffset(32,86),UDim2.new(1,-64,0,40),string.format("THEATER  %d × %d  GRID 50",meta.width or 0,meta.height or 0),24,muted,Font.new("rbxasset://fonts/families/RobotoMono.json"))
    local console=b("StatusConsole",{30,3.2,18},{-hx-36,y-.6,-hz*.35},steel,.12)
    local screen=b("ConsoleScreen",{26,.2,13},{-hx-36,y+1.05,-hz*.35},inset,.12)
    local sg=face(screen,520,260,0)
    for i=0,4 do rect(sg,UDim2.fromOffset(24,30+i*44),UDim2.fromOffset(i%2==0 and 300 or 200,10),accent,.25+i*.12)end
    rect(sg,UDim2.fromOffset(360,30),UDim2.fromOffset(130,130),bezel,.2)
    rect(sg,UDim2.fromOffset(424,30),UDim2.fromOffset(2,130),ice,.5);rect(sg,UDim2.fromOffset(360,94),UDim2.fromOffset(130,2),ice,.5)
    for i,offset in ipairs({-.1,.18})do
        local slate=b("TacticalSlate"..i,{22,1,30},{hx+30+i*4,y-1.3,hz*offset*2},bezel,-.08*i)
        local sgui=face(slate,300,420,0)
        rect(sgui,UDim2.fromOffset(18,18),UDim2.new(1,-36,0,4),i==1 and accent or ice,.3)
        for r=0,6 do rect(sgui,UDim2.fromOffset(18,48+r*46),UDim2.new(1-(r%3)*.18,-36,0,6),muted,.55)end
    end
    for i=0,3 do
        local x=-hx*.6+i*9;local base=CFrame.new(x,y-1.2,-hz-26)
        Geo.cylinder(folder,"PinStem",.35,4,base*CFrame.new(0,1.5,0),muted)
        Geo.ball(folder,"PinHead",Vector3.new(2.2,2.2,2.2),base*CFrame.new(0,3.8,0),i==0 and accent or ice)
    end
    folder:SetAttribute("Theme","WarRoomV2");return folder
end
function M.dropView(folder,on,sea)
    if not folder or not folder.Parent then return end
    if on==(folder:GetAttribute("DropHidden")==true)then return end
    folder:SetAttribute("DropHidden",on)
    local sheet=folder:FindFirstChild("DropSea")
    for _,o in ipairs(folder:GetDescendants())do
        if sheet and(o==sheet or o:IsDescendantOf(sheet))then continue end
        if o:IsA("BasePart")then
            o.LocalTransparencyModifier=on and 1 or 0
            if on then o:SetAttribute("DropShadow",o.CastShadow);o.CastShadow=false
            elseif o:GetAttribute("DropShadow")~=nil then o.CastShadow=o:GetAttribute("DropShadow");o:SetAttribute("DropShadow",nil)end
        elseif o:IsA("SurfaceGui")then o.Enabled=not on end
    end
    if on and not sheet then
        sheet=Instance.new("Model");sheet.Name="DropSea"
        for i=-1,1 do for j=-1,1 do
            local p=Instance.new("Part");p.Name="Sea";p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
            p.Material=Enum.Material.SmoothPlastic;p.Color=rgb(8,19,31);p.Size=Vector3.new(2048,.2,2048);p.CFrame=CFrame.new(i*2048,G.surfaceY-1.1,j*2048);p.Parent=sheet
            local gui=Instance.new("SurfaceGui");gui.Name="SeaPrint";gui.Face=Enum.NormalId.Top;gui.CanvasSize=Vector2.new(8,8);gui.LightInfluence=0;gui.MaxDistance=10000;gui.Parent=p
            local fill=Instance.new("Frame");fill.Name="Fill";fill.Size=UDim2.fromScale(1,1);fill.BorderSizePixel=0;fill.BackgroundColor3=rgb(8,19,31);fill.Parent=gui
        end end
        sheet.Parent=folder
    end
    if sheet then
        for _,p in ipairs(sheet:GetChildren())do
            if p:IsA("BasePart")then
                if sea then p.Color=sea end;p.LocalTransparencyModifier=on and 0 or 1
                local gui=p:FindFirstChild("SeaPrint")
                if gui then gui.Enabled=on;local fill=gui:FindFirstChild("Fill");if fill and sea then fill.BackgroundColor3=sea end end
            end
        end
    end
end
return M
