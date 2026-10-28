local UI=require(script.Parent.Theme)
local G=require(script.Parent.Parent.Core.WorldGeometry)
local Colors=require(script.Parent.FactionColors)
local Raster=require(script.Parent.RasterMap)
local Terrain=require(script.Parent.Parent.Core.Terrain)
local Motion=require(script.Parent.Parent.Core.DropMotion)
local Rig=require(script.Parent.ParachuteRig)
local Cinematic=require(script.Parent.DropCinematic)
local Spectacle=require(script.Parent.DropSpectacle)
local Layout=require(script.Parent.DropLayout)
local Avatar=require(script.Parent.DropAvatar)
local CommanderTrail=require(script.Parent.CommanderTrail)
local Visibility=require(script.Parent.CharacterVisibility)
local PoseBatch=require(script.Parent.RenderPoseBatch)
local TeamMarks=require(script.Parent.DropTeamMarks)
local Teams=require(script.Parent.TeamStandings)
local Squad=require(script.Parent.Parent.Core.DropSquad)
local SquadView=require(script.Parent.DropSquadView)
local Catalog=require(script.Parent.Parent.Core.CosmeticCatalog)
local Desk=require(script.Parent.DeskScene)
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local Actions=game:GetService('ContextActionService')
local Me=Players.LocalPlayer
local M={};M.__index=M
local function part(parent,name,size,cf,color,shape)
    local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=Enum.Material.SmoothPlastic
    p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;if shape then p.Shape=shape end;p.Parent=parent;return p
end
function M.new(parent,world,touch)
    local self=setmetatable({world=world,touch=touch,models={},rigs={},visibility=Visibility.new(),poseBatch=PoseBatch.new(),poses={},flagTurn={},sequence=0,pending={},pendingHead=1,queued={}},M)
    self.remote=game.ReplicatedStorage.FrontierNative:WaitForChild('DropInput')
    self.streamConnection=game.ReplicatedStorage.FrontierNative:WaitForChild('DropState').OnClientEvent:Connect(function(version,d)
        if self.active and version==self.version and (not self.drop or d.elapsed>=self.drop.elapsed)then
            if d.active then self:accept(d)else self.drop=d;self.finishedVersion=version;self:clear()end
        end
    end)
    self.folder=Instance.new('Folder');self.folder.Name='CommanderDrop';self.folder.Parent=workspace
    self.frame=UI.panel(parent,'DropControls');self.frame.ZIndex=20;self.frame.Visible=false
    self.title=UI.label(self.frame,'Title','',17,UI.colors.ink);self.title.Font=Enum.Font.BuilderSansBold
    self.hint=UI.label(self.frame,'Hint','',14,UI.colors.muted)
    self.teamTag=UI.label(self.frame,'Team','',14,UI.colors.ink);self.teamTag.Font=Enum.Font.BuilderSansBold;self.teamTag.TextWrapped=false;self.teamTag.Visible=false
    self.land=UI.button(self.frame,'Land','지금 내리기',function()self:landNow('button')end,true)
    self.overview=UI.panel(parent,'DropOverview');self.overview.ZIndex=19;self.overview.Visible=false
    self.mapFrame=UI.make('Frame',self.overview,{Name='Map',BackgroundColor3=UI.colors.ocean,BorderSizePixel=0,ClipsDescendants=true})
    self.raster=Raster.new(self.mapFrame,180,110);self.blips={}
    self.cinematic=Cinematic.new(parent)
    self.spectacle=Spectacle.new(parent)
    self.landing=require(script.Parent.LandingIndicator).new(parent)
    self.standards={}
    self.squad=SquadView.new(parent);self.party={};self.positions={}
    local K=require(script.Parent.Kit20)
    self.rally20=K.button(parent,'DropRally',{kind='out',text='모여라',icon='people',size=15,weight=800,r=12},function()
        if not self.active or not self.drop or self.state.paused or os.clock()<(self.rallyAt or 0)+2 then return end
        local pose=self.poses[1];local meta=self.world.map.meta;if not pose then return end
        local tile=math.clamp(math.floor(pose.y),0,meta.height-1)*meta.width+math.clamp(math.floor(pose.x),0,meta.width-1)
        self.rallyAt=os.clock()
        require(script.Parent.TelemetryStep).step('drop','rallySent',{});self.remote:FireServer({kind='rally',version=self.version,tile=tile})
    end)
    self.rallyButton=self.rally20.button;self.rallyButton.ZIndex=23;self.rallyButton.Visible=false;self.rallyBlips={};self.rallyLayer=parent
    self.refuse=UI.make('Frame',parent,{Name='PickRefused',Size=UDim2.fromOffset(28,28),AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1,Visible=false,ZIndex=18})
    UI.corner(self.refuse,999);UI.stroke(self.refuse,UI.colors.muted,2)
    return self
end
function M:landNow(source)
    if self.state and self.active and self.land.Visible and self.land:GetAttribute('Enabled')~=false then
        if self.diving then return end;self.diving=true;require(script.Parent.TelemetryStep).step('drop','dive',{item=source or 'other',stage='start'})
        self.remote:FireServer({kind='land',version=self.state.version,diving=true})
    end
end
function M:pick(tile,owner)
    local d=self.drop;local own=self.own
    if not tile or not self.active or not d or not own or d.preparing or d.random or self.state.paused or self.introActive or self.diving then return end
    if own.landed or (self.elapsed or 0)<d.planeSeconds or (self.elapsed or 0)>=(own.plunge or d.seconds)then return end
    local meta=self.world.map.meta;local b=self.world.map.terrain and buffer.readu8(self.world.map.terrain,tile)or 0
    if not Terrain.isLand(b)or Terrain.isImpassable(b)or owner~=nil and owner~=0 and owner~=1 then
        self.refusedAt=os.clock();self.refusedTile=tile;require(script.Parent.ToyAudio).play('error',.5,1);return
    end
    self.picked={tile=tile,at=os.clock()};self.pickQueued=tile
    if not self.firstPick then self.firstPick=true;require(script.Parent.TelemetryStep).step('drop','firstSteer',{duration_ms=math.max(0,(self.elapsed or 0)-d.planeSeconds)*1000,item=self.touch()and 'tap'or 'click'})end
end
function M:pan(dt,move,top,viewport,ax,az,meta)
    local drag=self.world.dropPan;self.world.dropPan=nil
    if not drag and move.Magnitude<.01 then return end
    local cam=workspace.CurrentCamera.CFrame;local perPixel=2*top*math.tan(math.rad(Layout.wideFov/2))/math.max(1,viewport.Y)
    local right=Vector3.new(cam.RightVector.X,0,cam.RightVector.Z);local up=Vector3.new(cam.UpVector.X,0,cam.UpVector.Z)
    if right.Magnitude<.01 or up.Magnitude<.01 then return end
    local look=self.look or Vector2.new(ax,az);local delta=Vector3.zero
    if drag then delta-=(right.Unit*drag.X-up.Unit*drag.Y)*perPixel end
    if move.Magnitude>.01 then delta+=move*perPixel*viewport.Y*.9*dt end
    local hx,hz=meta.width*G.scale/2,meta.height*G.scale/2
    self.look=Vector2.new(math.clamp(look.X+delta.X,-hx,hx),math.clamp(look.Y+delta.Z,-hz,hz))
end
function M:clear()
    self.steered=nil;self.squad:clear();self.party={};self.positions={}
    self.rallyButton.Visible=false;for _,b in pairs(self.rallyBlips)do b:Destroy()end;self.rallyBlips={}
    self.cinematic:clear();self.spectacle:clear();self.introActive=false;self.cinematicMemory=nil;self.landing:hide()
    for _,v in pairs(self.standards)do v:destroy()end;self.standards={};self.flagTurn={};self.clockState=nil
    Actions:UnbindAction('CommanderDropLand')
    if self.active then
        local tile
        for _,p in ipairs(self.drop and self.drop.players or {})do if p.id==1 and p.tile then tile=p.tile;break end end
        local pose=self.poses[1];local meta=self.world.map and self.world.map.meta
        if not tile and pose and pose.target and pose.target.tile then tile=pose.target.tile end
        if not tile and pose and meta then tile=math.clamp(math.floor(pose.y),0,meta.height-1)*meta.width+math.clamp(math.floor(pose.x),0,meta.width-1)end
        if tile then self.world:focusAt(tile);self.world.smoothDistance=nil;self.world.focus=nil end
        if self.cameraCF then self.world.dropExitCamera={cf=self.cameraCF,at=os.clock()}end
    end
    if self.deskHidden then Desk.dropView(self.deskHidden,false);self.deskHidden=nil end
    for _,fx in pairs(self.trails or {})do fx:destroy()end;self.trails={}
    self.folder:ClearAllChildren();self.models={};self.rigs={};self.marks={};self.poses={};self.plane=nil;self.reticle=nil;self.cameraCF=nil;self.spectacleMe=nil;self.dropFov=nil;self.camDive=nil;self.camNear=nil;self.camWide=nil
    self.visibility:clear();self.poseBatch:clear()
    if self.land20 then self.land20.button.Visible=false end
    self.frame.Visible=false;self.overview.Visible=false;self.world.dropActive=false;self.world.dropCamera=nil;self.active=false;self.readySent=false;self.diving=nil
    for _,b in pairs(self.blips)do b:Destroy()end;self.blips={}
    self.drop=nil
    self.qaMove=nil;self.world.dropSteer=nil;self.world.dropPan=nil;self.world.dropSpan=nil
    self.picked=nil;self.pickQueued=nil;self.firstPick=nil;self.look=nil;self.liftWeight=nil;self.wideTop=nil;self.own=nil;self.elapsed=nil;self.refuse.Visible=false
    if self.folder.Parent~=workspace then self.folder.Parent=workspace end
    self.pending={};self.pendingHead=1;self.queued={}
end
function M:destroy()
    if self.destroyed then return end;self.destroyed=true;self:clear()
    self.streamConnection:Disconnect();self.raster:destroy();self.cinematic.gui:Destroy();self.spectacle:destroy();self.landing.frame:Destroy();self.squad:destroy()
    self.frame:Destroy();self.overview:Destroy();self.folder:Destroy();self.rallyButton:Destroy();self.refuse:Destroy()
end
function M:color(p)
    if p.team~=nil then return Colors.team(p.team,self.ownTeam)end
    return Colors.get(p.id,'HUMAN',Color3.fromRGB(table.unpack(Catalog.get(self.state and self.state.cosmetics and self.state.cosmetics.territory or self.state and self.state.style).territory)))
end
function M:model(p)
    local player=p.userId and Players:GetPlayerByUserId(p.userId);local source=player and player.Character
    local available=source and source:FindFirstChild('HumanoidRootPart')
    local old=self.models[p.id];if old then if old:GetAttribute('Placeholder')and available then self.rigs[p.id]:destroy();old:Destroy();self.rigs[p.id]=nil;if self.standards[p.id]then self.standards[p.id]:destroy();self.standards[p.id]=nil end;self.flagTurn[p.id]=nil else self.rigs[p.id]:recolor(self:color(p));return old end end
    local model=available and Avatar.clone(source)
    if not model then
        model=Instance.new('Model');model:SetAttribute('Placeholder',true);local body=part(model,'Body',Vector3.new(2,2.5,1),CFrame.new(),UI.colors.raised)
        part(model,'Head',Vector3.one*1.5,CFrame.new(0,2,0),UI.colors.ice,Enum.PartType.Ball);model.PrimaryPart=body
    end
    local color=self:color(p)
    model:ScaleTo(1.15);model.Name='Drop_'..p.id;model.Parent=self.folder
    Avatar.lockVisual(model)
    local h=model:FindFirstChildOfClass('Humanoid')
    model:SetAttribute('GroundHeight',math.max(3,h and h.HipHeight+model.PrimaryPart.Size.Y*.5 or 3))
    local player=p.userId and Players:GetPlayerByUserId(p.userId)
    local own=p.id==1 and self.state.cosmetics or nil
    self.rigs[p.id]=Rig.new(model,own and own.parachute or player and player:GetAttribute('CommanderParachuteStyle')or p.parachuteSkin,color,self.folder,true)
    self.trails=self.trails or {};self.trails[p.id]=CommanderTrail.attach(model,own and own.commanderTrail or player and player:GetAttribute('CommanderTrailStyle')or 'classic')
    if p.id==1 then
        local lightAt=Instance.new('Attachment');lightAt.Name='FillPosition';lightAt.Position=Vector3.new(0,3,3);lightAt.Parent=model.PrimaryPart
        local fill=Instance.new('PointLight');fill.Name='DropFill';fill.Color=Color3.fromRGB(226,238,248);fill.Brightness=2.5;fill.Range=14;fill.Shadows=false;fill.Parent=lightAt
    end
    local tag=Instance.new('BillboardGui');tag.Name='Name';tag.Size=UDim2.fromOffset(160,26);tag.StudsOffsetWorldSpace=Vector3.new(0,6,0);tag.AlwaysOnTop=true;tag.LightInfluence=0;tag.MaxDistance=10000;tag.Parent=model.PrimaryPart
    local name=UI.label(tag,'Name',p.name or '',14,color);name.Size=UDim2.fromScale(1,1);name.TextXAlignment=Enum.TextXAlignment.Center;name.TextStrokeColor3=UI.colors.bg;name.TextStrokeTransparency=.15;name.Font=Enum.Font.BuilderSansBold;name:SetAttribute('LocalizationSkip',true)
    self.standards[p.id]=require(script.Parent.CommanderStandardRig).new(self.folder,player and player:GetAttribute('CommanderStandardStyle')or 'recruit',color)
    self.marks=self.marks or {};if self.marks[p.id]then self.marks[p.id]:destroy()end
    self.marks[p.id]=TeamMarks.new(self.folder,p.id,color,p.team~=nil and self.rigs[p.id].skin.collection~=nil,p.id==1)
    self.models[p.id]=model;return model
end
function M:makePlane()
    local m=Instance.new('Model');m.Name='TransportPlane'
    local hull=Color3.fromRGB(74,88,105);local edge=Color3.fromRGB(153,175,191)
    local body=part(m,'Fuselage',Vector3.new(24,3.6,4.5),CFrame.new(),hull,Enum.PartType.Ball);m.PrimaryPart=body
    part(m,'CargoSpine',Vector3.new(13,3,3.8),CFrame.new(-1,0,0),hull)
    part(m,'WingSpar',Vector3.new(4,.32,28),CFrame.new(-1,.6,0),hull)
    for side=-1,1,2 do
        part(m,'SweptWing',Vector3.new(7,.3,10),CFrame.new(-1,.65,side*8)*CFrame.Angles(0,side*.23,0),hull)
        part(m,'WingEdge',Vector3.new(.18,.15,10),CFrame.new(2.2,.86,side*8)*CFrame.Angles(0,side*.23,0),edge)
        part(m,'Winglet',Vector3.new(2.6,1.5,.18),CFrame.new(-2,1.2,side*13.9),hull)
        part(m,'Tailplane',Vector3.new(3,.24,5.8),CFrame.new(-9,1.2,side*3.3)*CFrame.Angles(0,side*.2,0),hull)
        part(m,'TailFin',Vector3.new(3.3,4,.2),CFrame.new(-9.3,2.5,side*1.6)*CFrame.Angles(-side*.15,0,0),hull)
        for _,z in ipairs({5.2,9.5})do
            part(m,'Turbofan',Vector3.new(6.2,2,2),CFrame.new(.3,-.65,side*z),hull,Enum.PartType.Cylinder)
            part(m,'IntakeRim',Vector3.new(.25,2.1,2.1),CFrame.new(3.4,-.65,side*z),edge,Enum.PartType.Cylinder)
            part(m,'Intake',Vector3.new(.27,1.6,1.6),CFrame.new(3.57,-.65,side*z),UI.colors.bg,Enum.PartType.Cylinder)
            part(m,'TurbineHub',Vector3.new(.3,.55,.55),CFrame.new(3.74,-.65,side*z),hull,Enum.PartType.Cylinder)
        end
        part(m,'Callsign',Vector3.new(4,.22,.06),CFrame.new(-6,.3,side*2),UI.colors.accent)
        local nav=part(m,'Navigation',Vector3.new(.35,.15,.35),CFrame.new(-1,1.8,side*14),UI.colors.ice);nav.Material=Enum.Material.Neon
    end
    part(m,'Cockpit',Vector3.new(4.5,1.3,3.2),CFrame.new(7.3,1.2,0),Color3.fromRGB(29,65,83),Enum.PartType.Ball)
    part(m,'NoseStripe',Vector3.new(3,.15,2),CFrame.new(8.3,1.8,0),edge)
    m.Parent=self.folder;self.plane=m
end
function M:update(state)
    local d=state and state.drop
    if state and self.finishedVersion==state.version then self.state=state;return end
    if not d or not d.active then if self.active then self:clear()end;self.state=state;return end
    if not self.active or self.version~=state.version then self:clear();self.active=true;self.version=state.version;self.sequence=0;self.telemetryAt=os.clock()
        Actions:BindActionAtPriority('CommanderDropLand',function(_,inputState)
            if UIS:GetFocusedTextBox()or self.obscured then return Enum.ContextActionResult.Pass end
            if inputState==Enum.UserInputState.Begin then self:landNow('key')end
            return Enum.ContextActionResult.Sink
        end,false,Enum.ContextActionPriority.High.Value,Enum.KeyCode.Space)
        self.world:fit();self.world.yaw=0;self.world.tilt=math.rad(89.9);self.world.dropZoom=1
        local edge=math.max(self.world.map.meta.width,self.world.map.meta.height)*G.scale;local height=math.clamp(edge*.65,110,620)
        self.entryCamera=CFrame.lookAt(Vector3.new(0,G.surfaceY+height+80,edge*.25),Vector3.new(0,G.surfaceY+height*.2,0))
        self.raster:setPreview(require(script.Parent.Parent.Maps.MapLoader).preview(self.world.map.meta.key))
        Desk.dropView(self.world.desk,true,self.raster.outside);self.deskHidden=self.world.desk
        task.defer(function()self.raster:fit();self.raster:draw()end)
        self.spectacle:begin(self.folder,self.world.reducedEffects==true,self.touch()or UIS.TouchEnabled and not UIS.KeyboardEnabled)
    end
    self.state=state;self.world.dropActive=true;self.ownTeam=state.player and state.player.team
    if not self.drop or d.elapsed>=self.drop.elapsed then self:accept(d)end
end
function M:accept(d)
    self.drop=d;self.receivedAt=os.clock()
    self.party=Squad.members(d.players)
    Colors.setTeams(d.players,self.ownTeam,self.version)
    for _,p in ipairs(d.players)do
        local pose=self.poses[p.id]or {x=p.x,y=p.y,altitude=p.altitude or 1,motion=Motion.new((p.userId or p.matchId or p.id)%4096)};pose.target=p;self.poses[p.id]=pose
        local model=self.models[p.id];local user=p.userId and Players:GetPlayerByUserId(p.userId);local c=user and user.Character
        local missing=not model or model:GetAttribute('Placeholder')and c and c:FindFirstChild('HumanoidRootPart')
        if p.id==1 then self:model(p)
        elseif missing and not self.queued[p.id]then self.queued[p.id]=true;table.insert(self.pending,p.id)
        elseif model then self.rigs[p.id]:recolor(self:color(p))end
        if p.id==1 then self.diving=p.diving end
        if not self.blips[p.id]then local b=UI.make('Frame',self.mapFrame,{Name='Commander_'..p.id,Size=UDim2.fromOffset(p.id==1 and 8 or 6,p.id==1 and 8 or 6),AnchorPoint=Vector2.new(.5,.5),BorderSizePixel=0,BackgroundColor3=self:color(p),ZIndex=21});UI.corner(b,99);UI.stroke(b,UI.colors.bg,1);self.blips[p.id]=b end
        local blip=self.blips[p.id];local member=self.party[p.id];local n=blip:FindFirstChild('PartyNumber')
        if member and not n then n=UI.label(blip,'PartyNumber','',10,UI.colors.bg);n.Name='PartyNumber';n.Size=UDim2.fromScale(1,1);n.TextXAlignment=Enum.TextXAlignment.Center;n.ZIndex=22;n:SetAttribute('LocalizationSkip',true)end
        blip.Size=UDim2.fromOffset(member and 14 or p.id==1 and 8 or 6,member and 14 or p.id==1 and 8 or 6)
        if n then n.Visible=member~=nil;n.Text=member and tostring(member.index)or ''end
        if c then self.visibility:hide(c)end
    end
end
function M:step(dt,obscured)
    if not self.active or not self.drop or not self.world.map then return end
    if self.deskHidden~=self.world.desk then Desk.dropView(self.world.desk,true,self.raster.outside);self.deskHidden=self.world.desk end
    self.visibility:step(os.clock(),Me.Character)
    local d=self.drop;local age=self.state.paused and 0 or math.min(.4,os.clock()-self.receivedAt)
    local began=os.clock();local built=0
    while self.pendingHead<=#self.pending and built<2 and os.clock()-began<.003 do
        local id=self.pending[self.pendingHead];self.pendingHead+=1;self.queued[id]=nil
        local pose=self.poses[id];if pose then self:model(pose.target);built+=1 end
    end
    if self.pendingHead>#self.pending then self.pending={};self.pendingHead=1 end
    local touch=self.touch()or UIS.TouchEnabled and not UIS.KeyboardEnabled
    self.obscured=obscured
    self.clockState=self.clockState or {}
    local elapsed=math.min(d.seconds,Motion.clock(self.clockState,d.preparing and 0 or math.min(d.seconds,d.elapsed+age),dt,d.preparing or self.state.paused));local left=math.max(0,math.ceil(d.seconds-elapsed))
    local shot=self.cinematic:frame(d.preparing and -1 or elapsed,self.world.reducedEffects,obscured,self.state.paused)
    self.introActive=shot.active
    self.frame.Visible=not obscured and not shot.active;self.overview.Visible=false
    if not self.readySent and self.world:isReady()then self.readySent=true;require(script.Parent.TelemetryClient).emit('drop_render_ready',{result='ready',version=self.version,spawn_style=d.random and 'random'or 'selected',duration_ms=(os.clock()-self.telemetryAt)*1000});self.remote:FireServer({kind='ready',version=self.version})end
    local own=d.players[1];for _,p in ipairs(d.players)do if p.id==1 then own=p;break end end
    self.own=own;self.elapsed=elapsed
    local hum=Me.Character and Me.Character:FindFirstChildOfClass('Humanoid');local move=self.qaMove or hum and hum.MoveDirection or Vector3.zero
    if UIS:GetFocusedTextBox()or obscured then move=Vector3.zero end
    local picking=not d.preparing and not d.random and not own.landed and elapsed>=d.planeSeconds and elapsed<(own.plunge or d.seconds)and not shot.active
    if picking and self.pickQueued and os.clock()>=(self.nextPick or 0)then
        self.nextPick=os.clock()+.11;self.remote:FireServer({kind='pick',version=self.version,tile=self.pickQueued});self.pickQueued=nil
    end
    local wantParent=not picking and workspace or nil;if self.folder.Parent~=wantParent then self.folder.Parent=wantParent end
    local meta=self.world.map.meta;local height=math.clamp(math.max(meta.width,meta.height)*G.scale*.65,110,620)
    if not d.preparing and elapsed<d.planeSeconds+.8 then
        if not self.plane then self:makePlane()end
        local x=(own.x+.5-meta.width/2)*G.scale;local z=(own.y+.5-meta.height/2)*G.scale
        self.plane:PivotTo(CFrame.new(x-6+elapsed*34,G.surfaceY+height+27,z+5))
    elseif self.plane then self.plane:Destroy();self.plane=nil end
    for id,pose in pairs(self.poses)do
        local p=pose.target;local tx,ty=p.x,p.y
        local pick=id==1 and self.picked
        if pick then
            local px2,py2=pick.tile%meta.width,pick.tile//meta.width
            if math.floor(p.x)==px2 and math.floor(p.y)==py2 or os.clock()-pick.at>1 then self.picked=nil else tx,ty=px2,py2 end
        end
        local px,py=pose.x,pose.y
        local alpha=1-math.exp(-dt*18);pose.x+=(tx-pose.x)*alpha;pose.y+=(ty-pose.y)*alpha
        if picking or not (p.plunge and elapsed>=p.plunge)and not p.landed then pose.x,pose.y=tx,ty end
        local falling=p.plunge and elapsed>=p.plunge and math.max(0,1-(elapsed-p.plunge)/(d.plungeSeconds or 2))or (p.altitude or 1)
        pose.altitude+=(falling-pose.altitude)*(1-math.exp(-dt*24));if p.landed then pose.altitude=0 end
        pose.shown=math.max(0,(pose.altitude-.05)/.95)
        local touched=p.landed or not d.preparing and pose.seenAirborne and pose.shown<=0
        local x,z=(pose.x+.5-meta.width/2)*G.scale,(pose.y+.5-meta.height/2)*G.scale
        self.positions[id]=Vector3.new(x,G.surfaceY+4+(picking and 0 or height*Motion.height(pose.shown)),z)
        local airborne=not d.preparing and not p.landed
        local frameDt=math.max(dt,.001)
        local motion=pose.motion:step(dt,{altitude=pose.altitude,airborne=airborne,landed=touched,diving=p.diving,paused=self.state.paused,reduced=self.world.reducedEffects,
            vx=math.clamp((pose.x-px)/frameDt/d.speed,-1,1),vz=math.clamp((pose.y-py)/frameDt/d.speed,-1,1)})
        motion.introT=shot.active and math.clamp(elapsed/Cinematic.Intro.seconds,0,1)or nil;motion.reducedEffects=self.world.reducedEffects==true
        motion.near=airborne and math.clamp(1-Motion.height(pose.shown)/.06,0,1)or 0
        local b=self.blips[id];if b then b.Position=UDim2.fromScale((pose.x+.5)/meta.width,(pose.y+.5)/meta.height);b.BackgroundTransparency=p.landed and .35 or 0 end
        local model=self.models[id]
        if model then
        local ground=model:GetAttribute('GroundHeight')or 4
        local position=Vector3.new(x,G.surfaceY+ground+height*Motion.height(pose.shown)+motion.bodyLift,z)
        if shot.active then position+=Vector3.new(-4*shot.pose,shot.lift,shot.drift)end
        local yaw=CFrame.new(position)*CFrame.Angles(0,motion.heading,0)
        local pitch=shot.active and shot.pitch or motion.bodyPitch
        local roll=airborne and (shot.active and shot.roll or motion.bodyRoll)or 0
        local cf=yaw*CFrame.Angles(airborne and pitch or 0,0,roll)
        if airborne and not touched and not shot.active and motion.deployed then
            local h=7.7*math.clamp(motion.inflation or 0,0,1);cf=yaw*CFrame.new(0,h,0)*CFrame.Angles(pitch,0,roll)*CFrame.new(0,-h,0)
        end
        if not picking then
            model:PivotTo(cf)
            if airborne then pose.seenAirborne=true end
            if motion.deployed and not pose.fxDeployed and airborne then pose.fxDeployed=true;self.spectacle:deployed(position+Vector3.new(0,7.7,0),self:color(p),id==1)end
            if touched and not pose.fxLanded and pose.seenAirborne then pose.fxLanded=true;self.spectacle:landed(Vector3.new(x,G.surfaceY,z),self:color(p),id==1)end
            local trail=self.trails and self.trails[id];if trail then trail:step(airborne and not self.state.paused and not shot.active,self.world.reducedEffects)end
            self.rigs[id]:step(cf,motion,airborne,yaw,self.poseBatch)
            local marks=self.marks and self.marks[id]
            if marks then local rig=self.rigs[id];marks:recolor(self:color(p));marks:step(position,G.surfaceY,airborne and rig.visible and rig.canopy:GetPivot()*CFrame.new(0,-.9*math.min(1,motion.inflation or 0),0)or nil,motion.inflation or 0,yaw,elapsed,self.world.reducedEffects==true,self.poseBatch,obscured)end
            if id==1 then self.rigs[id]:fade(not shot.active and airborne and self.world.tilt>math.rad(70)and .55*math.min(1,motion.inflation or 0)or 0)end
            local flag=self.standards[id];local hand=model:FindFirstChild('RightHand')or model:FindFirstChild('Right Arm')
            if flag then
                local handCF=hand and self.poseBatch:get(hand)
                local point=handCF and handCF:PointToWorldSpace(Vector3.new(0,hand.Name=='Right Arm'and -hand.Size.Y*.42 or 0,0))or (cf*CFrame.new(1,-.1,0)).Position
                local orientation=cf.Rotation
                if handCF then
                    local axis,angle=cf.Rotation:ToObjectSpace(handCF.Rotation):ToAxisAngle()
                    if angle==angle and angle>1e-4 and axis.Magnitude>.5 then
                        local turn=self.flagTurn[id]or {};self.flagTurn[id]=turn
                        local x,y,z,a=Motion.heldTurn(turn,axis.X,axis.Y,axis.Z,angle,.3)
                        orientation=cf.Rotation*CFrame.fromAxisAngle(Vector3.new(x,y,z),a)
                    end
                end
                local grip=CFrame.new(point)*orientation
                local turn=self.flagTurn[id]or {};self.flagTurn[id]=turn;turn.wind=(turn.wind or 0)+((airborne and 38 or 0)-(turn.wind or 0))*(1-math.exp(-dt*4))
                flag:recolor(self:color(p));flag:step(grip,elapsed,turn.wind,1.15,obscured and 1 or 0,self.poseBatch)
            end
        end
        if id==1 then
            local tile=math.clamp(math.floor(pose.y),0,meta.height-1)*meta.width+math.clamp(math.floor(pose.x),0,meta.width-1)
            local terrain=self.world.map.terrain and buffer.readu8(self.world.map.terrain,tile)or 128
            local valid=Terrain.isLand(terrain)and not Terrain.isImpassable(terrain)
            local focus=position+Vector3.new(0,1,0)
            local kick=self.world.cameraShake~=false and motion.cameraKick or 0
            local reduced=self.world.reducedEffects==true
            local fall=airborne and 1-math.clamp(motion.inflation or 0,0,1)or 0
            self.camNear=(self.camNear or 0)+(((shot.active or reduced)and 0 or fall)-(self.camNear or 0))*(1-math.exp(-dt*2.2))
            self.camDive=(self.camDive or 0)+((p.diving and 1 or 0)-(self.camDive or 0))*(1-math.exp(-dt*4))
            local distance=(58+pose.altitude*18)*math.max(.55,self.world.dropZoom or 1)*(1-(reduced and 0 or .16*(motion.cameraKick or 0)/1.8))*(1-.4*self.camNear)
            local viewport=workspace.CurrentCamera.ViewportSize
            local matchDistance=math.max(24,180*G.scale/(2*math.tan(math.rad(25))*viewport.X/math.max(1,viewport.Y)))
            local settle=math.clamp(1-Motion.height(pose.shown)/.07,0,1);settle=settle*settle*(3-2*settle)
            distance+=(matchDistance-distance)*settle;focus=focus:Lerp(Vector3.new(x,G.surfaceY,z),settle)
            local wide=airborne and not touched and Layout.wideWeight(Motion.height(pose.shown))or 0
            self.camWide=wide
            if wide>0 then
                local aspect=viewport.X/math.max(1,viewport.Y);local spanX,spanZ=meta.width*G.scale,meta.height*G.scale
                self.liftWeight=(self.liftWeight or 0)+((picking and 0 or 1)-(self.liftWeight or 0))*(1-math.exp(-dt*6))
                local above=(focus.Y-G.surfaceY)*self.liftWeight
                local top=math.min(Layout.wideMaxHeight,math.max(Layout.fitHeight(spanX,spanZ,aspect)*math.clamp(self.world.dropZoom or 1,.25,1.5)+above,above+distance))
                if not picking and self.wideTop then top=math.exp(math.log(self.wideTop)+(math.log(math.max(1,top))-math.log(self.wideTop))*(1-math.exp(-dt*5)))end
                self.wideTop=math.max(1,top)
                if picking then self:pan(dt,move,top,viewport,x,z,meta)end
                local lx,lz=x,z;if self.look then lx,lz=self.look.X,self.look.Y end
                local fx,fz=Layout.wideFocus(lx,lz,spanX,spanZ,top,aspect,nil,not picking and above or nil)
                local h=math.exp(math.log(math.max(1,above+distance))*(1-wide)+math.log(math.max(1,top))*wide)
                focus=focus:Lerp(Vector3.new(fx,G.surfaceY,fz),wide);distance=math.max(8,h-(focus.Y-G.surfaceY))
            end
            self.world.dropSpan=2*distance*math.tan(math.rad((self.dropFov or Layout.wideFov)/2))*viewport.X/math.max(1,viewport.Y)/G.scale
            local horizontal=math.cos(self.world.tilt)*distance
            local offset=Vector3.new(math.sin(self.world.yaw)*horizontal,math.sin(self.world.tilt)*distance,math.cos(self.world.yaw)*horizontal)
            local cf=CFrame.lookAt(focus+offset,focus)
            if shot.active then
                local head=model:FindFirstChild('Head');local hp=head and head.Position or position+Vector3.new(0,2,0)
                local viewport=workspace.CurrentCamera.ViewportSize
                self.cinematicMemory=self.cinematicMemory or {};cf,focus=Cinematic.camera(shot,yaw*CFrame.Angles(shot.pitch,0,0),hp,cf,focus,viewport.X/math.max(1,viewport.Y),self.world.reducedEffects,self.cinematicMemory,dt)
                self.cameraCF=cf
            elseif d.preparing then self.cameraCF=self.entryCamera
            else self.cameraCF=self.cameraCF and self.cameraCF:Lerp(cf,1-math.exp(-dt*12))or cf end
            local fovTarget=shot.active and shot.fov or 50+kick+(reduced and 0 or fall*(5+4*self.camDive))
            self.dropFov=shot.active and fovTarget or (self.dropFov or fovTarget)+(fovTarget-(self.dropFov or fovTarget))*(1-math.exp(-dt*6))
            local shaken=self.cameraCF
            if not reduced and self.world.cameraShake~=false then shaken=shaken*self.spectacle:cameraOffset(fall*.05*(1+self.camDive)*(shot.active and .4 or 1))end
            self.world.dropCamera={cf=shaken,focus=focus,fov=self.dropFov}
            self.spectacleMe={position=position,free=fall,dive=self.camDive,open=math.clamp(motion.inflation or 0,0,1),landed=p.landed==true,heading=motion.heading}
            local camera=workspace.CurrentCamera;camera.CFrame=self.world.dropCamera.cf;camera.Focus=CFrame.new(focus);camera.FieldOfView=self.world.dropCamera.fov
            local fillAt=model.PrimaryPart:FindFirstChild('FillPosition')
            if fillAt then
                local eye=self.world.dropCamera.cf.Position-position;fillAt.WorldPosition=position+(eye.Magnitude>.1 and eye.Unit or Vector3.yAxis)*6
                local fill=fillAt:FindFirstChild('DropFill');if fill then fill.Brightness=2.5-1.3*settle end
            end
            self.landing:step(Vector3.new(x,G.surfaceY+.2,z),valid and UI.colors.accent or UI.colors.gold,not obscured and not shot.active and not own.landed,valid)
            self.cinematic:skyFrame(self.cameraCF,shot,obscured)
        end
        local tag=model.PrimaryPart:FindFirstChild('Name');if tag then tag.Enabled=not shot.active and id~=1 and not self.party[id]end
        end
    end
    self.poseBatch:flush()
    self.spectacle:step(dt,{elapsed=elapsed,planeSeconds=d.planeSeconds,shot=shot,me=self.spectacleMe,camera=self.cameraCF,top=height,surfaceY=G.surfaceY,
        heading=self.spectacleMe and self.spectacleMe.heading or 0,wide=self.camWide or 0,obscured=obscured,paused=self.state.paused,flashes=self.world.mapFlashes~=false})
    local pickLeft=math.max(0,math.ceil((own.plunge or d.seconds)-elapsed));local plunging=own.plunge and elapsed>=own.plunge
    local title=d.preparing and '전장 준비 중' or (own.landed or plunging) and string.format('%d초 뒤 시작',left)or string.format('착륙 위치 고르기 %d초',pickLeft)
    local hint=own.landed and (own.fallback and '유효한 육지에 자동 배치했어요.'or '')or plunging and ''or d.random and (touch and '착륙지 고정'or '랜덤 시작이라 착륙 위치는 정해져 있어요.')or touch and '지도를 눌러 골라요'or '지도를 클릭해 골라요'
    local land='지금 내리기'
    if self.lastTitle~=title then self.lastTitle=title;self.title.Text=title end
    if self.lastHint~=hint then self.lastHint=hint;self.hint.Text=hint end
    self.hint.Visible=hint~=''
    if self.lastLand~=land then self.lastLand=land;self.land.Text=land end
    self.land.Visible=not d.random and not own.landed and not d.preparing and not plunging;UI.enabled(self.land,elapsed>=d.planeSeconds and not self.diving and not self.state.paused)
    local size=self.frame.Parent.AbsoluteSize/UI.scale;local r=Layout.of(size.X,size.Y,touch,meta.width,meta.height)
    local ok20,H20=pcall(require,script.Parent.Hud20)
    if ok20 and H20.ENABLED then
        local Card=require(script.Parent.LandingCard20)
        local landed=own.landed or plunging
        local team=self.ownTeam~=nil and Teams.label(self.ownTeam,self.state)or nil
        Card.card(self.frame,{seconds=not d.preparing and (landed and left or pickLeft)or nil,title=d.preparing and '전장 준비 중'or landed and '곧 시작'or '착륙 위치 고르기',
            hint=own.landed and (own.fallback and '유효한 육지에 자동 배치했어요.'or '')or plunging and ''or d.random and '착륙지 고정'or touch and '지도를 눌러 골라요'or '지도를 클릭해 골라요',
            team=team and string.format('%s 소속',team)or nil,teamColor=team and Colors.team(self.ownTeam,self.ownTeam)or nil},size.X,size.Y,{self.title,self.hint,self.teamTag})
        self.land.Size=UDim2.fromOffset(0,0);self.land.BackgroundTransparency=1;self.land.TextTransparency=1
        Card.button(self.frame.Parent,self,self.frame.Visible and self.land.Visible,self.land:GetAttribute('Enabled')~=false,size.X,size.Y)
    else
    local panel=r.panel;UI.box(self.frame,panel.x,panel.y,panel.w,panel.h)
    UI.box(self.title,r.title.x,r.title.y,touch and r.title.w or panel.w-(self.land.Visible and 120 or 24),r.title.h);self.title.TextSize=touch and 15 or 17
    UI.box(self.hint,r.hint.x,r.hint.y,self.land.Visible and r.hint.w or panel.w-24,r.hint.h);self.hint.TextWrapped=true;self.hint.TextSize=14
    local team=self.ownTeam~=nil and Teams.label(self.ownTeam,self.state)or nil
    local tagText=team and string.format('%s 소속',team)or ''
    if self.teamTag.Text~=tagText then self.teamTag.Text=tagText end
    local tagX=r.title.x+self.title.TextBounds.X+12;local room=(touch and r.title.x+r.title.w or panel.w-(self.land.Visible and 108 or 12))-tagX
    self.teamTag.Visible=team~=nil and room>=60
    if self.teamTag.Visible then self.teamTag.TextColor3=Colors.team(self.ownTeam,self.ownTeam);self.teamTag.TextSize=touch and 13 or 14;UI.box(self.teamTag,tagX,r.title.y,room,r.title.h)end
    UI.box(self.land,r.land.x,r.land.y,r.land.w,r.land.h)
    self.land.TextSize=14
    end
    local mw,mh=r.mini.w-8,r.mini.h-8
    UI.box(self.overview,r.mini.x,r.mini.y,r.mini.w,r.mini.h);UI.box(self.mapFrame,4,4,mw,mh)
    if ok20 and H20.ENABLED then
        if not self.mini20 then
            local K=require(script.Parent.Kit20);self.mini20=true
            self.overview.BackgroundTransparency=1
            for _,s in ipairs(self.overview:GetChildren())do if s:IsA('UIStroke')then s.Enabled=false end end
            K.round(self.mapFrame,8);K.stroke(self.mapFrame,K.colors.line,1,0,true)
            if self.raster.label then K.round(self.raster.label,8)end
        end
        mw,mh=r.mini.w,r.mini.h;UI.box(self.mapFrame,0,0,mw,mh)
    end
    local hasPeers=false;for _,p in ipairs(d.players)do if p.id~=1 and (self.party[p.id]or self.ownTeam~=nil and p.team==self.ownTeam)then hasPeers=true;break end end
    self.rallyButton.Visible=hasPeers and not obscured and not shot.active and not d.preparing
    if self.rallyButton.Visible and self.rallyShownVersion~=self.version then self.rallyShownVersion=self.version;require(script.Parent.TelemetryStep).step('drop','rallyShown',{})end
    local rw=touch and 104 or 116;self.rally20:place(size.X-rw-(touch and 64 or 20),12,rw,44);self.rally20:setEnabled(not self.state.paused and os.clock()>=(self.rallyAt or 0)+2)
    local markerMini={x=r.mini.x,y=r.mini.y,w=r.mini.w,h=r.mini.h+(hasPeers and 52 or 0)}
    self.squad:step(self.party,self.positions,workspace.CurrentCamera,touch,markerMini,not obscured and not shot.active)
    local signals={};local camera=workspace.CurrentCamera;local origin=self.rallyLayer.AbsolutePosition
    for _,signal in ipairs(d.rallies or {})do
        signals[signal.userId]=true;local b=self.rallyBlips[signal.userId]
        local caller;for _,p in ipairs(d.players)do if p.userId==signal.userId then caller=p;break end end
        local color=caller and self:color(caller)or UI.colors.accent
        if not b then
            b=UI.make('Frame',self.rallyLayer,{Name='Rally_'..signal.userId,Size=UDim2.fromOffset(34,34),AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1,ZIndex=19})
            UI.corner(b,999);UI.stroke(b,color,2)
            local dot=UI.make('Frame',b,{Name='Dot',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(8,8),BackgroundColor3=color,BorderSizePixel=0,ZIndex=19});UI.corner(dot,999)
            local text=UI.label(b,'Caption',signal.userId==Me.UserId and '모여라'or string.format('%s 모여라',caller and caller.name or ''),12,UI.colors.ink)
            UI.box(text,-43,36,120,18);text.TextXAlignment=Enum.TextXAlignment.Center;text.TextStrokeTransparency=.15;text.Font=Enum.Font.BuilderSansBold
            b:SetAttribute('Born',os.clock())
            self.rallyBlips[signal.userId]=b;if signal.userId~=Me.UserId then require(script.Parent.TelemetryStep).step('drop','rallyReceived',{});require(script.Parent.ToyAudio).play('click',.6,1.2)end
        end
        local at=Vector3.new((signal.tile%meta.width+.5-meta.width/2)*G.scale,G.surfaceY+.2,(signal.tile//meta.width+.5-meta.height/2)*G.scale)
        local sp,onScreen=camera:WorldToScreenPoint(at)
        b.Visible=onScreen and not obscured and not shot.active
        b.Position=UDim2.fromOffset((sp.X-origin.X)/UI.scale,(sp.Y-origin.Y)/UI.scale)
        local t=(os.clock()-(b:GetAttribute('Born')or 0))%1.2/1.2;local grow=self.world.reducedEffects and 34 or 34+18*t
        b.Size=UDim2.fromOffset(grow,grow);local st=b:FindFirstChildOfClass('UIStroke');if st then st.Transparency=self.world.reducedEffects and 0 or t*.8 end
    end
    for uid,b in pairs(self.rallyBlips)do if not signals[uid]then b:Destroy();self.rallyBlips[uid]=nil end end
    local rt=self.refusedAt and os.clock()-self.refusedAt
    self.refuse.Visible=rt~=nil and rt<.35 and not obscured
    if self.refuse.Visible then
        local tile=self.refusedTile;local at=Vector3.new((tile%meta.width+.5-meta.width/2)*G.scale,G.surfaceY+.2,(tile//meta.width+.5-meta.height/2)*G.scale)
        local sp=camera:WorldToScreenPoint(at);local shake=self.world.reducedEffects and 0 or math.sin(rt*50)*5*(1-rt/.35)
        self.refuse.Position=UDim2.fromOffset((sp.X-origin.X)/UI.scale+shake,(sp.Y-origin.Y)/UI.scale)
    end
    if self.miniWidth~=mw then self.miniWidth=mw;self.raster:fit();self.raster:draw()end
end
return M
