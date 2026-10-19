local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local InputMode=require(script.Parent.InputMode)
local G=require(script.Parent.Parent.Core.WorldGeometry)
local Raster=require(script.Parent.RasterMap)
local Catalog=require(script.Parent.Parent.Core.CosmeticCatalog)
local Buildings=require(script.Parent.BuildingModels)
local Playback=require(script.Parent.TerritoryPlayback)
local Desk=require(script.Parent.DeskScene)
local UnitRules=require(script.Parent.Parent.Core.UnitRules)
local Theme=require(script.Parent.Theme)
local Combined=require(script.Parent.CombinedArmsView)
local FactionColors=require(script.Parent.FactionColors)
local Defense=require(script.Parent.Parent.Core.DefenseCoverage)
local Looks=require(script.Parent.CosmeticLoadouts)
local Art=require(script.Parent.CollectionArt)
local Pattern=require(script.Parent.TerritoryCollection)
local PoseBatch=require(script.Parent.RenderPoseBatch)
local Probe=require(script.Parent.FrameProbe)
local Glints=require(script.Parent.TerritoryGlints)
local M={};M.__index=M
M.detailSwapsPerState=3
M.studio=RunService:IsStudio()
M.info=setmetatable({},{__mode="k"})
local function part(parent,name,size,position,color)
    local p=Instance.new("Part");p.Name=name;p.Size=size;p.Position=position;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Parent=parent;return p
end
function M.new(parent)
    local self=setmetatable({parent=parent,owners={},view={w=1000},chunks={},queue={},units={},yaw=0,tilt=math.rad(89.9),enabled=false,overview=true},M)
    self.playback=Playback.new()
    self.popups={};self.animated={}
    self.combined=Combined.new(self)
    self.folder=Instance.new("Folder");self.folder.Name="FrontierClientView";self.folder.Parent=workspace
    self.infoFor=function(model)return M.info[model]end
    self.readability=require(script.Parent.AvatarReadability).new(self)
    parent:SetAttribute("Renderer","WorldSurfaceTiles")
    RunService:BindToRenderStep("FrontierCamera",Enum.RenderPriority.Camera.Value+1,function(dt) Probe.start("World");self:step(dt);Probe.stop("World") end)
    return self
end
function M:aspect() return math.max(1,self.parent.AbsoluteSize.X)/math.max(1,self.parent.AbsoluteSize.Y) end
function M:isReady()
    if not self.map then return false end
    for _,c in ipairs(self.chunks)do if not c.raster.initialized then return false end end
    return true
end
function M:setMap(map)
    self.readability:release()
    self.combined:reset()
    if self.placementModel then self.placementModel:Destroy();self.placementModel=nil end;self.placementKey=nil
    for _,c in ipairs(self.chunks) do c.raster:destroy();c.part:Destroy() end
    for _,p in pairs(self.units) do p:Destroy() end
    for _,p in pairs(self.collectionSeals or {})do p:Destroy()end;self.collectionSeals={}
    if self.glints then Glints.destroy(self.glints);self.glints=nil end
    for _,p in pairs(self.coverage or {})do p:Destroy()end;self.coverage={}
    self.chunks={};self.chunkIndex={};self.queue={};self.units={};self.map=map;self.overview=true;self.lastRevision=-1;self.styleId=nil;self.playback:reset({});self.smoothDistance=nil;self.cameraImpulse=nil;self.lastStateTick=nil;self.glow={};self.glowCount=0
    local m=map.meta
    if self.desk then self.desk:Destroy() end
    self.desk=Desk.create(self.folder,m);self.popups={};self.animated={}
    for y=0,m.height-1,512 do for x=0,m.width-1,512 do
        local w,h=math.min(512,m.width-x),math.min(512,m.height-y)
        local p=part(self.folder,"Map_"..x.."_"..y,Vector3.new(h*G.scale,.025,w*G.scale),Vector3.new((x+w/2-m.width/2)*G.scale,G.surfaceY+.025,(y+h/2-m.height/2)*G.scale),Color3.fromRGB(31,52,74))
        p.CFrame=p.CFrame*CFrame.Angles(0,-math.pi/2,0)
        local surface=Instance.new("SurfaceGui");surface.Name="Geography";surface.Face=Enum.NormalId.Top;surface.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize;surface.CanvasSize=Vector2.new(w,h);surface.LightInfluence=0;surface.AlwaysOnTop=false;surface.MaxDistance=3000;surface.Parent=p
        local frame=Instance.new("Frame");frame.Size=UDim2.fromScale(1,1);frame.BackgroundTransparency=1;frame.Parent=surface
        local raster=Raster.new(frame,w,h);raster.map=map;raster.view={x=x,y=y,w=w,h=h};raster.owners=self.playback.owners;raster.exactTiles=true;raster.force=true;raster.dirtyTiles={};raster.glow=self.glow
        local chunk={part=p,raster=raster,x=x,y=y,w=w,h=h}
        table.insert(self.chunks,chunk);self.chunkIndex[math.floor(y/512)*math.ceil(m.width/512)+math.floor(x/512)]=chunk
    end end
    self:fit()
end
function M:fit()
    if not self.map then return end
    self.overview=true;self.targetTile=nil
    local halfX,halfZ=self.map.meta.width*G.scale/2,self.map.meta.height*G.scale/2
    local tan=math.tan(math.rad(25));local aspect=self:aspect()
    local distance=math.max(halfX/(tan*aspect*.85),math.sin(self.tilt)*halfZ/(tan*.7))+math.cos(self.tilt)*halfZ
    self.view.w=distance*(2*tan*aspect)/G.scale;self:clamp()
end
function M:setStyle(id)
    if self.styleId==id then return end
    self.styleId=id;local style=Catalog.get(id)
    for _,c in ipairs(self.chunks) do c.raster.territoryColor=Color3.fromRGB(table.unpack(style.territory));c.raster.borderColor=Color3.fromRGB(table.unpack(style.border));c.raster.force=true end
    for _,p in pairs(self.units) do p:Destroy() end;self.units={};self.animated={};self:draw()
end
function M:clamp()
    if not self.map then return end
    self.view.w=math.clamp(self.view.w,70,math.max(self.map.meta.width,self.map.meta.height*self:aspect())*2.1)
    self.view.h=self.view.w/self:aspect()
end
function M:follow() self.overview=false;self.targetTile=nil;self.view.w=180;self:clamp() end
function M:focusAt(tile,preserveZoom) self.overview=false;self.targetTile=tile;if not preserveZoom then self.view.w=180 end;self:clamp() end
function M:zoom(factor)
    if self.dropActive then self.dropZoom=math.clamp((self.dropZoom or 1)*factor,.55,4);return end
    self.view.w*=factor;self:clamp()
end
function M:impulse(strength)
    if self.reducedEffects or self.cameraShake==false then return end
    local p=self.cameraImpulse;local left=p and p.strength*(1-math.min(1,p.age/p.duration))^2 or 0
    strength=math.min(.6,math.max(strength,left))
    self.cameraImpulse={age=0,strength=strength,duration=.25+strength*.9,fov=strength>=.3 and strength*7 or 0}
end
M.glowCap=1500
M.rasterBudget=.003
M.sealsFull=12
function M:groundAt(pos)
    local ray=workspace.CurrentCamera:ScreenPointToRay(pos.X,pos.Y)
    if ray.Direction.Y>=-.0001 then return nil end
    local distance=(G.surfaceY-ray.Origin.Y)/ray.Direction.Y
    if distance<0 then return nil end
    return ray.Origin+ray.Direction*distance
end
function M:tileAt(pos)
    if not self.map then return nil end
    local at=self:groundAt(pos);if not at then return nil end
    return G.toTile(at.X,at.Z,self.map.meta.width,self.map.meta.height)
end
function M:dragAvatar(from,to)
    if self.dropActive or not self.map then return end
    local char=Players.LocalPlayer.Character;local hrp=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or hrp.Anchored or (hum and hum.WalkSpeed==0) then return end
    local a,b=self:groundAt(from),self:groundAt(to);if not a or not b then return end
    local origin=hrp.Position
    if self.overview or self.targetTile then
        local f=self.focus or origin;origin=Vector3.new(f.X,origin.Y,f.Z);self.overview=false;self.targetTile=nil
    end
    local d=Vector3.new(a.X-b.X,0,a.Z-b.Z)
    local halfX,halfZ=self.map.meta.width*G.scale/2,self.map.meta.height*G.scale/2
    local at=Vector3.new(math.clamp(origin.X+d.X,-halfX,halfX),origin.Y,math.clamp(origin.Z+d.Z,-halfZ,halfZ))
    if d.Magnitude>.05 then self.dragHeading=d.Unit end
    char:PivotTo(CFrame.new(at)*hrp.CFrame.Rotation);hrp.AssemblyLinearVelocity=Vector3.zero
end
function M:project(tile,height,allowOffscreen)
    return self:projectXY(tile%self.map.meta.width,math.floor(tile/self.map.meta.width),height,allowOffscreen)
end
function M:signalPoint(tile)
    local x,y,z=G.toWorld(tile,self.map.meta.width,self.map.meta.height);local world=Vector3.new(x,y+.2,z)
    local camera=self.frameCamera or workspace.CurrentCamera;local screen=camera:WorldToScreenPoint(world)
    if screen.Z>=0 then return (Vector2.new(screen.X,screen.Y)-(self.frameOrigin or self.parent.AbsolutePosition))/Theme.scale end
    local p=camera.CFrame:PointToObjectSpace(world);local d=Vector2.new(p.X,-p.Y)
    if d.Magnitude<.001 then d=Vector2.new(0,1)end
    local size=self.parent.AbsoluteSize/Theme.scale
    return size*.5+d.Unit*math.max(size.X,size.Y)*2
end
function M:projectXY(x,y,height,allowOffscreen)
    local world=Vector3.new((x+.5-self.map.meta.width/2)*G.scale,G.surfaceY+(height or .1),(y+.5-self.map.meta.height/2)*G.scale)
    local screen,visible=(self.frameCamera or workspace.CurrentCamera):WorldToScreenPoint(world)
    if (not visible and not allowOffscreen) or screen.Z<0 then return Vector2.new(-2000,-2000) end
    return (Vector2.new(screen.X,screen.Y)-(self.frameOrigin or self.parent.AbsolutePosition))/Theme.scale
end
function M:draw()
    if not self.map then return end
    for _,c in ipairs(self.chunks) do
        if not c.pending and (c.raster.force or c.raster.paintRow~=nil or not c.raster.initialized or next(c.raster.dirtyTiles)) then c.pending=true;table.insert(self.queue,c) end
    end
end
function M:updateOwnership(state)
    if state.ownershipRevision<=self.lastRevision then return end
    self.lastRevision=state.ownershipRevision
    if state.owned then self.playback:reset(self.owners);for _,c in ipairs(self.chunks) do c.raster.force=true end
    else self.playback:push(state.captured or {},os.clock()) end
    self:draw()
end
function M:markTerritory(t)
    local w,h=self.map.meta.width,self.map.meta.height
    local function mark(tile)
        if tile<0 or tile>=w*h then return end
        local c=self.chunkIndex[math.floor(math.floor(tile/w)/512)*math.ceil(w/512)+math.floor(tile%w/512)]
        if c then c.raster.dirtyTiles[tile]=true end
    end
    mark(t);mark(t-w);mark(t+w);if t%w>0 then mark(t-1) end;if t%w<w-1 then mark(t+1) end
    if self.glow and self.playback.owners[t]==1 and not self.reducedEffects and self.mapFlashes~=false and (self.glow[t] or self.glowCount<M.glowCap) then
        if not self.glow[t] then self.glowCount+=1 end;self.glow[t]=os.clock()
    end
end
local portDirections={{0,1},{1,0},{-1,0},{0,-1},{1,1},{-1,1},{1,-1},{-1,-1}}
function M:structureFrame(kind,tile)
    local w,h=self.map.meta.width,self.map.meta.height
    local x,y,z=G.toWorld(tile,w,h);local frame=CFrame.new(x,y,z)
    local terrain=self.map.terrain
    if kind~="Port"or not terrain then return frame end
    local tx,ty=tile%w,math.floor(tile/w)
    for distance=1,14 do for _,d in ipairs(portDirections)do
        local nx,ny=tx+d[1]*distance,ty+d[2]*distance
        if nx>=0 and ny>=0 and nx<w and ny<h and bit32.band(buffer.readu8(terrain,ny*w+nx),128)==0 then
            return frame*CFrame.Angles(0,math.atan2(d[1],d[2]),0)
        end
    end end
    return frame
end
function M:setPlacement(preview,kind,rangeTile)
    if not self.map then return end
    local tile=preview and preview.tile;local valid=preview and preview.valid
    local key=tostring(tile)..":"..tostring(valid)..":"..tostring(kind)..":"..tostring(rangeTile)
    if self.placementKey==key then return end;self.placementKey=key
    local w,h=self.map.meta.width,self.map.meta.height
    local shape=tostring(tile and kind)..":"..tostring(rangeTile~=nil)
    if self.placementShape~=shape or not self.placementModel then
        self.placementShape=shape;self.placementColor=nil
        if self.placementModel then self.placementModel:Destroy() end
        local model=Instance.new("Model");model.Name="PlacementPreview";model.Parent=self.folder;self.placementModel=model
        if tile and (UnitRules.structures[kind] or kind=="Warship") then
            local base=part(model,"Footprint",Vector3.new(4,.12,4),Vector3.zero,Color3.new(1,1,1));base.Material=Enum.Material.Neon;base.Transparency=.45
            if UnitRules.structures[kind] then
                local ghost=Buildings.resize(Buildings.create(kind,Catalog.get(self.styleId),1,false));ghost.Name="BuildingGhost";ghost.Parent=model
                for _,piece in ipairs(ghost:GetChildren())do if piece:IsA("BasePart")then piece:SetAttribute("Base",piece.Color);piece.Transparency=.62;piece.CastShadow=false end end
            end
        end
        if rangeTile then
            local radius=30*G.scale
            for i=1,48 do
                local a,b=(i-1)/48*math.pi*2,i/48*math.pi*2
                local start=Vector3.new(math.cos(a)*radius,0,math.sin(a)*radius);local finish=Vector3.new(math.cos(b)*radius,0,math.sin(b)*radius)
                local p=part(model,"DefenseRange",Vector3.new(.08,.08,(finish-start).Magnitude),(start+finish)/2,Color3.fromRGB(245,196,81));p.Material=Enum.Material.Neon;p.Transparency=.25
                p:SetAttribute("Offset",CFrame.lookAt((start+finish)/2,finish))
            end
        end
    end
    local model=self.placementModel
    local base=model:FindFirstChild("Footprint")
    if tile and base then
        local x,y,z=G.toWorld(tile,w,h);base.Position=Vector3.new(x,y+.2,z)
        local ghost=model:FindFirstChild("BuildingGhost");if ghost then ghost:PivotTo(self:structureFrame(kind,tile))end
        local color=valid and Color3.fromRGB(54,226,208) or Color3.fromRGB(255,82,82)
        if self.placementColor~=color then
            self.placementColor=color;base.Color=color
            if ghost then for _,piece in ipairs(ghost:GetChildren())do local c=piece:GetAttribute("Base");if c then piece.Color=c:Lerp(color,.55)end end end
        end
    end
    if rangeTile then
        local x,y,z=G.toWorld(rangeTile,w,h);local centre=CFrame.new(x,y+.13,z)
        for _,p in ipairs(model:GetChildren())do local o=p:GetAttribute("Offset");if o then p.CFrame=centre*o end end
    end
end
function M:defenseCoverage(state,kinds)
    local m=self.map.meta;local w,h=m.width,m.height
    local previous=self.defenseMap==self.map and self.defenseIndex or nil
    local index=Defense.build(state.units,w,previous)
    if index~=previous then
        local cw=math.ceil(w/512)
        for _,post in ipairs(Defense.changed(previous,index))do Defense.each(post,w,h,function(t)
            local c=self.chunkIndex[math.floor(math.floor(t/w)/512)*cw+math.floor(t%w/512)];if c then c.raster.dirtyTiles[t]=true end
        end)end
        self.defenseIndex=index;self.defenseMap=self.map
    end
    for _,c in ipairs(self.chunks)do c.raster.defense=index end
end
function M:highlightKind(kind)
    if self.highlightKey==kind then return end;self.highlightKey=kind
    for _,b in ipairs(self.highlights or {})do b:Destroy()end;self.highlights={}
    if not kind then return end
    for id,model in pairs(self.units)do if model.Name==kind..id and model:GetAttribute("Owner")==1 then
        local box=Instance.new("SelectionBox");box.Name="KindHighlight";box.Adornee=model;box.Color3=Color3.fromRGB(54,226,208);box.LineThickness=.06;box.SurfaceTransparency=1;box.Parent=model;table.insert(self.highlights,box)
    end end
end
M.affiliationColors={self=Color3.new(0,1,0),ally=Color3.new(1,1,0),neutral=Color3.new(.502,.502,.502),enemy=Color3.new(1,0,0)}
function M:affiliationFor(state)
    local c=M.affiliationColors;local out={neutral=c.neutral,[1]=c.self};local key={}
    for _,f in ipairs(state and state.factions or {})do if f.id~=1 then local col=(f.allied or f.teammate)and c.ally or f.embargoed and c.enemy or nil;if col then out[f.id]=col;table.insert(key,f.id..(col==c.ally and 'a'or 'e'))end end end
    return out,table.concat(key,',')
end
function M:setAltView(on)
    if (self.altView==true)==(on==true)then return end;self.altView=on==true;require(script.Parent.TelemetryStep).step('map_ui','altView',{result=self.altView and 'active'or 'inactive'});self.affiliationKey=nil;self:applyAffiliation()
end
function M:applyAffiliation()
    local table_,key=nil,'off';if self.altView then table_,key=self:affiliationFor(self.lastState)end
    if key==self.affiliationKey then return end;self.affiliationKey=key
    for _,c in ipairs(self.chunks or {})do c.raster.affiliation=table_;c.raster.force=true end
end
function M:setState(state)
    self.enabled=state and state.phase~="menu"
    if not self.enabled then return end
    self.lastState=state;if self.altView then self:applyAffiliation()end
    local loadouts=Looks.all(state);local tiers={};local signature=''
    local shares={};for _,f in ipairs(state.factions or {})do shares[f.id]=f.share end
    for id,l in pairs(loadouts)do local style=Catalog.forSlot(l,'territory');local ph=Art.phase(style,shares[id]or 0,false);tiers[id]=Pattern.spec(style,ph);signature..=tostring(id)..':'..tostring(l.territory)..ph..';'end
    local glint={};for id,l in pairs(loadouts)do local style=Catalog.forSlot(l,'territory');if (style.tier or 0)>=4 and (shares[id]or 0)>0 then glint[id]=Glints.styleFor(style,Art.phase(style,shares[id],false),shares[id])end end
    if M.studio and self.qaGlints then glint=self.qaGlints(state,glint)end
    self.glints=self.glints or Glints.new(self.folder);Glints.setOwners(self.glints,glint)
    local styleChanged=signature~=self.collectionSignature;self.collectionSignature=signature
    local kinds={};for _,f in ipairs(state.factions or {})do kinds[f.id]=f.kind end
    local recolor=FactionColors.setTeams(state.factions,state.player and state.player.team,state.version)
    for _,c in ipairs(self.chunks)do
        if not c.raster.factionKinds or recolor then c.raster.force=true end
        c.raster.factionKinds=kinds
        c.raster.collectionTiers=tiers;if styleChanged then c.raster.force=true end
    end
    self.paused=state.paused
    Probe.start('Snapshot.units');self.combined:update(state);Probe.stop('Snapshot.units')
    local alive={};local swaps=0;local animated={}
    for _,u in ipairs(state.units or {}) do
        if not UnitRules.structures[u.kind] then continue end
        local skinId=(loadouts[u.owner]or {})[u.kind=="City"and 'city'or 'defensePost']or 'classic'
        local style=Catalog.get(skinId)
        alive[u.id]=true
        local model=self.units[u.id]
        local info=model and M.info[model]
        local x,y,z=G.toWorld(u.tile,self.map.meta.width,self.map.meta.height)
        local distance=(workspace.CurrentCamera.CFrame.Position-Vector3.new(x,y,z)).Magnitude
        local detailed=distance<(info and info.Detailed and 125 or 100)
        if info and info.Detailed~=detailed and info.SkinId==skinId and info.VisualLevel==math.min(u.level,3)and info.Owner==u.owner then
            if swaps>=M.detailSwapsPerState then detailed=info.Detailed else swaps+=1 end
        end
        local existed=model~=nil
        local wasBuilding=info and info.Building
        if model and (info.SkinId~=skinId or info.VisualLevel~=math.min(u.level,3)or info.Detailed~=detailed or info.Owner~=u.owner) then model:Destroy();self.units[u.id]=nil;model=nil end
        if not model then
            local ownerColor=FactionColors.get(u.owner,kinds[u.owner],Color3.fromRGB(table.unpack(Catalog.get(self.styleId).territory)))
            model=Buildings.resize(Buildings.create(u.kind,style,u.level,detailed,ownerColor));model.Name=u.kind..u.id;model:SetAttribute("SkinId",skinId);model:SetAttribute("Owner",u.owner);model.Parent=self.folder;self.units[u.id]=model
            model:PivotTo(self:structureFrame(u.kind,u.tile))
            info={SkinId=skinId,Owner=u.owner,VisualLevel=model:GetAttribute("VisualLevel"),Detailed=model:GetAttribute("Detailed"),Radar=model:GetAttribute("RadarLocal")~=nil,Extents=model:GetExtentsSize(),Position=Vector3.new(x,y,z),Light=model:FindFirstChild('CollectionLight',true)};M.info[model]=info
            if info.Light then Art.light(model,false)end
        end
        if not self.reducedEffects and not u.building and (wasBuilding or not existed and self.lastStateTick and (u.assemblyStartedTick or u.createdTick or -1)>=self.lastStateTick) then
            self.popups[model]={base=model:GetPivot(),elapsed=0}
        end
        if info.Building~= (u.building==true)then
            for _,p in ipairs(model:GetChildren()) do if p:IsA("BasePart") then p.Transparency=math.max(p:GetAttribute("BaseTransparency")or 0,u.building and .55 or 0)end end
            model:SetAttribute("Building",u.building==true);info.Building=u.building==true
        end
        Buildings.state(model,u)
        if style.tier==5 then
            local phase=Art.phase(style,shares[u.owner]or 0,u.inCombat==true)
            if info.Phase~=phase then info.Phase=phase;model:SetAttribute('CollectionPhase',phase)end
        end
        if info.Radar or (style.tier or 0)>=3 then table.insert(animated,{model=model,distance=distance,id=u.id})end
    end
    for id,model in pairs(self.units) do if not alive[id] then if self.lastStateTick then require(script.Parent.DestructionFx).building(model,self.reducedEffects==true)else model:Destroy()end;self.units[id]=nil end end
    table.sort(animated,function(a,b)return a.distance==b.distance and a.id<b.id or a.distance<b.distance end)
    self.animated={};for i=1,math.min(32,#animated)do self.animated[i]=animated[i].model end
    local lit={};for _,model in ipairs(self.animated)do local i=M.info[model];if i and i.Light then lit[model]=true;if not (self.litModels and self.litModels[model])then Art.light(model,true)end end end
    for model in pairs(self.litModels or {})do if not lit[model]and model.Parent then Art.light(model,false)end end
    self.litModels=lit
    self.collectionSeals=self.collectionSeals or {};local sealAlive={}
    for _,f in ipairs(state.factions or {})do
        local style=Catalog.forSlot(loadouts[f.id],'territory');local tile=f.labelTile
        if type(tile)=='number'and (style.tier or 0)>=1 and not style.flat then
            sealAlive[f.id]=true;local seal=self.collectionSeals[f.id]
            if seal and seal:GetAttribute('CollectionStyle')~=style.id then seal:Destroy();seal=nil end
            if not seal then seal=Art.territory(style,FactionColors.get(f.id,f.kind));seal:ScaleTo(.28);seal.Parent=self.folder;self.collectionSeals[f.id]=seal end
            if seal:GetAttribute('SealTile')~=tile then seal:SetAttribute('SealTile',tile);local x,y,z=G.toWorld(tile,self.map.meta.width,self.map.meta.height);seal:PivotTo(CFrame.new(x,y+.05,z))end
            local phase=Art.phase(style,f.share or 0,false);if seal:GetAttribute('CollectionPhase')~=phase then seal:SetAttribute('CollectionPhase',phase)end
        end
    end
    for id,seal in pairs(self.collectionSeals)do if not sealAlive[id]then seal:Destroy();self.collectionSeals[id]=nil end end
    self:defenseCoverage(state,kinds)
    if self.highlightKey then local kind=self.highlightKey;self.highlightKey=nil;self:highlightKind(kind)end
    self.lastStateTick=state.tick
end
function M:stepDragWalk(dt,char,hrp,hum)
    local speed=0
    if self.dragging and hrp and self.dragLast then local delta=hrp.Position-self.dragLast;speed=Vector2.new(delta.X,delta.Z).Magnitude/math.max(dt,1/240) end
    self.dragLast=hrp and hrp.Position
    self.dragSpeed=(self.dragSpeed or 0)+(speed-(self.dragSpeed or 0))*(1-math.exp(-dt*12))
    if self.dragHeading and hrp and not hrp.Anchored then
        local look=hrp.CFrame.LookVector;local want=CFrame.lookAt(Vector3.zero,self.dragHeading)
        local rot=hrp.CFrame.Rotation:Lerp(want,1-math.exp(-dt*16))
        char:PivotTo(CFrame.new(hrp.Position)*rot)
        if look:Dot(self.dragHeading)>.999 or not self.dragging and self.dragSpeed<.5 then self.dragHeading=nil end
    end
    if self.walkChar~=char then
        if self.walkTrack then self.walkTrack:Stop(0);self.walkTrack=nil end
        self.walkChar=char
        local folder=char and char:FindFirstChild("Animate");local value=folder and folder:FindFirstChild("run")
        local clip=value and value:FindFirstChildWhichIsA("Animation");local animator=hum and hum:FindFirstChildOfClass("Animator")
        if clip and animator then
            local ok,track=pcall(function()return animator:LoadAnimation(clip)end)
            if ok and track then track.Priority=Enum.AnimationPriority.Movement;track.Looped=true;self.walkTrack=track end
        end
    end
    local track=self.walkTrack;if not track then return end
    local walking=self.dragSpeed>2 and hum~=nil and hum.MoveDirection.Magnitude<.01 and not self.dropActive
    if walking then
        if not track.IsPlaying then track:Play(.15) end
        track:AdjustSpeed(math.clamp(self.dragSpeed/22,.75,2.2))
    elseif track.IsPlaying then track:Stop(.2) end
end
function M:step(dt)
    self.frameCamera=workspace.CurrentCamera;self.frameOrigin=self.parent.AbsolutePosition
    if not self.enabled or not self.map then self.readability:step(dt);if self.walkTrack and self.walkTrack.IsPlaying then self.walkTrack:Stop(.2)end;return end
    self.visualTime=(self.visualTime or 0)+(self.paused and 0 or dt)
    local batch=self.poseBatch or PoseBatch.new();self.poseBatch=batch
    Probe.start('World.seals')
    local view=self.frameCamera.ViewportSize;local seals,depths=self.sealList or {},self.sealDepth or {};table.clear(seals);self.sealList=seals;self.sealDepth=depths
    for _,seal in pairs(self.collectionSeals or {})do local p=self.frameCamera:WorldToViewportPoint(seal:GetPivot().Position);if p.Z>0 and p.X>-160 and p.Y>-160 and p.X<view.X+160 and p.Y<view.Y+160 then table.insert(seals,seal);depths[seal]=p.Z end end
    if #seals>M.sealsFull then table.sort(seals,function(a,b)return depths[a]<depths[b]end)end
    self.sealFrame=((self.sealFrame or 0)+1)%8
    local lit=self.sealLit or setmetatable({},{__mode='k'});self.sealLit=lit;local slots=self.sealSlot or setmetatable({},{__mode='k'});self.sealSlot=slots
    local perDepth=1.34*view.Y/(2*math.tan(math.rad(self.frameCamera.FieldOfView/2)))
    for i,seal in ipairs(seals)do
        local full=i<=M.sealsFull;local every=full and 1 or perDepth/depths[seal]<6 and 8 or 4
        if lit[seal]~=full then lit[seal]=full;Art.light(seal,full)end
        local slot=slots[seal];if not slot then slot=(self.sealSlots or 0)+1;self.sealSlots=slot;slots[seal]=slot end
        if every==1 or (slot+self.sealFrame)%every==0 then Art.step(seal,self.visualTime,self.reducedEffects,seal:GetAttribute('CollectionPhase'),batch)end
    end
    table.clear(depths)
    Probe.stop('World.seals')
    if self.animationTime~=self.visualTime or self.animationReduced~=self.reducedEffects or self.animationList~=self.animated then
        self.animationTime=self.visualTime;self.animationReduced=self.reducedEffects;self.animationList=self.animated
        for _,model in ipairs(self.animated)do if model.Parent then Buildings.animate(model,self.visualTime,self.reducedEffects,batch)end end
    end
    if not pcall(batch.flush,batch)then batch:clear()end
    for model,p in pairs(self.popups) do
        p.elapsed+=dt;local t=math.min(1,p.elapsed/.48)
        if not model.Parent then self.popups[model]=nil
        elseif t==1 or self.reducedEffects then model:PivotTo(p.base);self.popups[model]=nil
        else local lift=1.2*(1-t)^2+.2*math.sin(t*math.pi*3)*(1-t);model:PivotTo(p.base*CFrame.new(0,lift,0)) end
    end
    local char=Players.LocalPlayer.Character;local hrp=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
    local ownName=char and char:FindFirstChild("CommanderName");if ownName then ownName.Enabled=false end
    if hum then
        if not UIS:IsKeyDown(Enum.KeyCode.Space) then self.hopSpent=false
        elseif hum:GetState()==Enum.HumanoidStateType.Jumping or hum:GetState()==Enum.HumanoidStateType.Freefall then self.hopSpent=true end
        local canJump=not self.dropActive and not self.hopSpent and hrp~=nil and not hrp.Anchored and hum.WalkSpeed>0 and not InputMode.touch()
        if hum:GetStateEnabled(Enum.HumanoidStateType.Jumping)~=canJump then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,canJump) end
    end
    self:stepDragWalk(dt,char,hrp,hum)
    if not self.dropActive and hum and hum.MoveDirection.Magnitude>.01 then
        self.targetTile=nil
        if self.overview then self:follow() end
    end
    local target=self.overview and Vector3.new(0,G.surfaceY,0) or (hrp and Vector3.new(hrp.Position.X,G.surfaceY,hrp.Position.Z) or Vector3.new(0,G.surfaceY,0))
    if self.targetTile then local x,y,z=G.toWorld(self.targetTile,self.map.meta.width,self.map.meta.height);target=Vector3.new(x,y,z) end
    self.focus=(self.focus and not self.dragging) and self.focus:Lerp(target,math.min(1,dt*14)) or target
    local camera=workspace.CurrentCamera;camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=50
    local distance=math.max(24,self.view.w*G.scale/(2*math.tan(math.rad(25))*self:aspect()))
    local goal=distance
    self.smoothDistance=self.smoothDistance and self.smoothDistance+(distance-self.smoothDistance)*(1-math.exp(-dt*15)) or distance;distance=self.smoothDistance
    self.liveW=self.view.w*distance/math.max(goal,1e-3)
    local horizontal=math.cos(self.tilt)*distance
    local offset=Vector3.new(math.sin(self.yaw)*horizontal,math.sin(self.tilt)*distance,math.cos(self.yaw)*horizontal)
    camera.CFrame=CFrame.lookAt(self.focus+offset,self.focus);camera.Focus=CFrame.new(self.focus)
    if self.cameraImpulse then
        local p=self.cameraImpulse;p.age+=dt;local t=p.age/p.duration
        if t>=1 or self.reducedEffects or self.cameraShake==false then self.cameraImpulse=nil
        else
            local fade=(1-t)^2;local amount=p.strength*fade*distance*.022
            camera.CFrame*=CFrame.new(math.sin(p.age*47)*amount,math.sin(p.age*61+1.3)*amount*.6,0)*CFrame.Angles(0,0,math.sin(p.age*37)*p.strength*fade*.012)
            if p.fov>0 then local u=math.min(1,p.age/.4);camera.FieldOfView=50+p.fov*(u<.15 and u/.15 or (1-(u-.15)/.85)^2) end
        end
    end
    if self.dropActive and self.dropCamera then
        camera.CFrame=self.dropCamera.cf;camera.Focus=CFrame.new(self.dropCamera.focus);camera.FieldOfView=self.dropCamera.fov or 50
        self.focus=self.dropCamera.focus
    elseif self.dropExitCamera then
        local t=math.clamp((os.clock()-self.dropExitCamera.at)/.4,0,1)
        camera.CFrame=self.dropExitCamera.cf:Lerp(camera.CFrame,t*t*(3-2*t))
        if t==1 then self.dropExitCamera=nil end
    end
    Probe.start('World.units');self.combined:step();Probe.stop('World.units')
    self.readability:step(dt)
    self.playback:step(os.clock(),function(t) self:markTerritory(t) end)
    if self.glints then Glints.step(self.glints,self.paused and 0 or dt,camera,self.map.meta.width,self.map.meta.height,self.playback.owners,self.reducedEffects or self.dropActive)end
    if self.glowCount>0 and os.clock()>=(self.glowNext or 0) then
        local now=os.clock();local w=self.map.meta.width;local cw=math.ceil(w/512);self.glowNext=now+.1
        for t,at in pairs(self.glow) do
            if now-at>=.4 then self.glow[t]=nil;self.glowCount-=1 end
            local c=self.chunkIndex[math.floor(math.floor(t/w)/512)*cw+math.floor(t%w/512)];if c then c.raster.dirtyTiles[t]=true end
        end
    end
    self:draw()
    Probe.start('World.raster')
    local started=os.clock()
    repeat
        local c=table.remove(self.queue,1)
        if not c then break end
        c.pending=false;c.raster.deadline=started+M.rasterBudget;c.raster:draw()
    until os.clock()-started>M.rasterBudget
    Probe.stop('World.raster')
    if M.studio then
        self.parent:SetAttribute("RasterWorkMs",(os.clock()-started)*1000)
        local n=0;for _,chunk in ipairs(self.chunks) do n+=chunk.raster.borderCount or 0 end;self.parent:SetAttribute("BorderPixels",n)
    end
end
function M:bind(callbacks,inputService)
    inputService=inputService or UIS
    local press=nil;local right=nil;local pinching=false;local trackpadScale=1
    local touches=require(script.Parent.Parent.Core.CommandInteraction).touchTracker()
    local function mouse() return inputService:GetMouseLocation()-game:GetService("GuiService"):GetGuiInset() end
    local function drag(p,slop)
        if not press.dragging and (p-press.start).Magnitude>=slop then press.dragging=true;self.dragging=true end
        if press.dragging then self:dragAvatar(press.last,p);press.last=p;if callbacks.changed then callbacks.changed() end end
    end
    inputService.InputBegan:Connect(function(input,processed)
        local p=input.UserInputType==Enum.UserInputType.Touch and Vector2.new(input.Position.X,input.Position.Y) or mouse()
        local eligible=callbacks.enabled()and not processed and not callbacks.blocked(p)
        if input.UserInputType==Enum.UserInputType.Touch then
            touches:beginTouch(input,eligible,p.X,p.Y)
            if touches.touchCount>1 then pinching=true;press=nil;self.dragging=false end
        end
        if not eligible then return end
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch and not touches.multiple then press={input=input,start=p,last=p,dragging=false}
        elseif input.UserInputType==Enum.UserInputType.MouseButton2 then right={start=p,last=p,moved=false,at=os.clock()} end
    end)
    inputService.InputChanged:Connect(function(input,processed)
        if not callbacks.enabled() then return end
        if input.UserInputType==Enum.UserInputType.MouseWheel and not processed and not callbacks.blocked(mouse()) then if not(callbacks.wheel and callbacks.wheel(input.Position.Z))then self:zoom(input.Position.Z>0 and .83 or 1/.83)end
        elseif input.UserInputType==Enum.UserInputType.MouseMovement then
            local p=mouse()
            if right then
                if (p-right.start).Magnitude>9 then right.moved=true end
                if right.moved then self.yaw-=(p.X-right.last.X)*.006;self.tilt=math.clamp(self.tilt+(p.Y-right.last.Y)*.003,math.rad(35),math.rad(89.9)) end
                right.last=p
            elseif press and press.input.UserInputType==Enum.UserInputType.MouseButton1 then drag(p,9)
            elseif callbacks.hover then callbacks.hover(self:tileAt(p),p) end
        elseif input.UserInputType==Enum.UserInputType.Touch then
            local p=Vector2.new(input.Position.X,input.Position.Y);local ratio=touches:moveTouch(input,p.X,p.Y)
            if touches.touchCount==2 and ratio then self:zoom(ratio);if callbacks.changed then callbacks.changed()end
            elseif press and input==press.input and not pinching then drag(p,12)end
        end
    end)
    inputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton2 then
            if right and (not right.moved or os.clock()-right.at<.3) and callbacks.enabled() and not callbacks.blocked(mouse()) then callbacks.select(self:tileAt(mouse()),mouse(),true) end
            right=nil
        end
        if press and (input==press.input or input.UserInputType==Enum.UserInputType.MouseButton1) then
            local p=input.UserInputType==Enum.UserInputType.Touch and Vector2.new(input.Position.X,input.Position.Y) or mouse()
            if not press.dragging and (p-press.start).Magnitude<(input.UserInputType==Enum.UserInputType.Touch and 12 or 9) and not pinching and not touches.multiple and callbacks.enabled() and not callbacks.blocked(p) then callbacks.select(self:tileAt(p),p) end;press=nil;self.dragging=false
        end
        if input.UserInputType==Enum.UserInputType.Touch then
            local wasMultiple=touches.multiple;local tracked=touches.touches[input]
            touches:endTouch(input);pinching=touches.touchCount>1
            if tracked and wasMultiple then
                local id,p=touches:remainingTouch()
                if id and p then local at=Vector2.new(p.x,p.y);press={input=id,start=at,last=at,dragging=true};self.dragging=true end
            end
            if tracked and touches.touchCount==0 then press=nil;self.dragging=false end
        end
    end)
    inputService.TouchPinch:Connect(function(points,scale,_,status,processed)
        if inputService.TouchEnabled then return end
        if status==Enum.UserInputState.End then pinching=false;press=nil;self.dragging=false;return end
        if not callbacks.enabled()or processed then return end
        for _,p in ipairs(points)do if callbacks.blocked(p)then return end end
        if status==Enum.UserInputState.Begin then pinching=true;trackpadScale=scale;press=nil;self.dragging=false
        elseif status==Enum.UserInputState.Change and scale>0 then self:zoom(trackpadScale/scale);trackpadScale=scale end
    end)
    inputService.WindowFocusReleased:Connect(function() press=nil;right=nil;pinching=false;self.dragging=false;touches:cancelTouches() end)
end
return M
