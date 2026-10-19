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
local Squad=require(script.Parent.Parent.Core.DropSquad)
local SquadView=require(script.Parent.DropSquadView)
local Catalog=require(script.Parent.Parent.Core.CosmeticCatalog)
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
    self.land=UI.button(self.frame,'Land','빠른 하강',function()self:landNow('button')end,true)
    self.overview=UI.panel(parent,'DropOverview');self.overview.ZIndex=19;self.overview.Visible=false
    self.mapFrame=UI.make('Frame',self.overview,{Name='Map',BackgroundColor3=UI.colors.ocean,BorderSizePixel=0,ClipsDescendants=true})
    self.raster=Raster.new(self.mapFrame,180,110);self.blips={}
    self.cinematic=Cinematic.new(parent)
    self.spectacle=Spectacle.new(parent)
    self.landing=require(script.Parent.LandingIndicator).new(parent)
    self.standards={}
    self.squad=SquadView.new(parent);self.party={};self.positions={}
    self.rallyButton=UI.button(parent,'DropRally','집결',function()
        if not self.active or not self.drop or self.state.paused then return end
        local pose=self.poses[1];local meta=self.world.map.meta;if not pose then return end
        local tile=math.clamp(math.floor(pose.y),0,meta.height-1)*meta.width+math.clamp(math.floor(pose.x),0,meta.width-1)
        require(script.Parent.TelemetryStep).step('drop','rallySent',{});self.remote:FireServer({kind='rally',version=self.version,tile=tile})
    end);self.rallyButton.ZIndex=23;self.rallyButton.Visible=false;self.rallyBlips={}
    UI.make('UIPadding',self.rallyButton,{PaddingLeft=UDim.new(0,18)})
    local icon=UI.make('Frame',self.rallyButton,{Name='RallyIcon',Position=UDim2.fromOffset(10,12),Size=UDim2.fromOffset(16,20),BackgroundTransparency=1,ZIndex=24})
    UI.make('Frame',icon,{Name='Pole',Size=UDim2.fromOffset(2,18),BackgroundColor3=UI.colors.ice,BorderSizePixel=0,ZIndex=24})
    UI.make('Frame',icon,{Name='Flag',Position=UDim2.fromOffset(2,0),Size=UDim2.fromOffset(10,7),BackgroundColor3=UI.colors.ice,BorderSizePixel=0,ZIndex=24})
    return self
end
function M:landNow(source)
    if self.state and self.active and self.land.Visible and self.land:GetAttribute('Enabled')~=false then
        local diving=not self.diving;self.diving=diving;require(script.Parent.TelemetryStep).step('drop','dive',{item=source or 'other',stage=diving and 'start'or 'stop'})
        self.remote:FireServer({kind='land',version=self.state.version,diving=diving})
    end
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
    for _,fx in pairs(self.trails or {})do fx:destroy()end;self.trails={}
    self.folder:ClearAllChildren();self.models={};self.rigs={};self.marks={};self.poses={};self.plane=nil;self.reticle=nil;self.cameraCF=nil;self.spectacleMe=nil;self.dropFov=nil;self.camDive=nil;self.camNear=nil
    self.visibility:clear();self.poseBatch:clear()
    self.frame.Visible=false;self.overview.Visible=false;self.world.dropActive=false;self.world.dropCamera=nil;self.active=false;self.readySent=false;self.diving=nil
    for _,b in pairs(self.blips)do b:Destroy()end;self.blips={}
    self.drop=nil
    self.qaMove=nil
    self.pending={};self.pendingHead=1;self.queued={}
end
function M:destroy()
    if self.destroyed then return end;self.destroyed=true;self:clear()
    self.streamConnection:Disconnect();self.raster:destroy();self.cinematic.gui:Destroy();self.spectacle:destroy();self.landing.frame:Destroy();self.squad:destroy()
    self.frame:Destroy();self.overview:Destroy();self.folder:Destroy();self.rallyButton:Destroy()
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
    self.frame.Visible=not obscured and not shot.active;self.overview.Visible=not obscured and not shot.active
    if not self.readySent and self.world:isReady()then self.readySent=true;require(script.Parent.TelemetryClient).emit('drop_render_ready',{result='ready',version=self.version,spawn_style=d.random and 'random'or 'selected',duration_ms=(os.clock()-self.telemetryAt)*1000});self.remote:FireServer({kind='ready',version=self.version})end
    local own=d.players[1];for _,p in ipairs(d.players)do if p.id==1 then own=p;break end end
    local hum=Me.Character and Me.Character:FindFirstChildOfClass('Humanoid');local move=self.qaMove or hum and hum.MoveDirection or Vector3.zero
    if UIS:GetFocusedTextBox()or obscured then move=Vector3.zero end
    if not d.preparing and not d.random and not own.landed and elapsed>=d.planeSeconds and os.clock()>=(self.nextInput or 0)then
        self.nextInput=os.clock()+.1;self.sequence=math.max(self.sequence+1,(d.sequence or 0)+1)
        self.remote:FireServer({kind='move',version=self.version,x=move.X,y=move.Z,seq=self.sequence})
        if not self.steered and (move.X~=0 or move.Z~=0)then self.steered=true;require(script.Parent.TelemetryStep).step('drop','firstSteer',{duration_ms=math.max(0,elapsed-d.planeSeconds)*1000,item=touch and 'touch'or 'keys'})end
    end
    local meta=self.world.map.meta;local height=math.clamp(math.max(meta.width,meta.height)*G.scale*.65,110,620)
    if not d.preparing and elapsed<d.planeSeconds+.8 then
        if not self.plane then self:makePlane()end
        local x=(own.x+.5-meta.width/2)*G.scale;local z=(own.y+.5-meta.height/2)*G.scale
        self.plane:PivotTo(CFrame.new(x-6+elapsed*34,G.surfaceY+height+27,z+5))
    elseif self.plane then self.plane:Destroy();self.plane=nil end
    for id,pose in pairs(self.poses)do
        local p=pose.target;local tx,ty=p.x,p.y
        if id==1 and not own.landed and not d.random and elapsed>=d.planeSeconds then tx=math.clamp(tx+move.X*d.speed*age,0,meta.width-1);ty=math.clamp(ty+move.Z*d.speed*age,0,meta.height-1)end
        local px,py=pose.x,pose.y
        local alpha=1-math.exp(-dt*18);pose.x+=(tx-pose.x)*alpha;pose.y+=(ty-pose.y)*alpha
        local fallAge=math.max(0,math.min(math.clamp(elapsed-d.elapsed,0,.4),elapsed-d.planeSeconds))
        local falling=math.max(0,(p.altitude or 1)-fallAge*(p.diving and d.diveMultiplier or 1)/(d.seconds-d.planeSeconds))
        pose.altitude+=(falling-pose.altitude)*(1-math.exp(-dt*24));if p.landed then pose.altitude=0 end
        pose.shown=math.max(0,(pose.altitude-.05)/.95)
        local touched=p.landed or not d.preparing and pose.seenAirborne and pose.shown<=0
        local x,z=(pose.x+.5-meta.width/2)*G.scale,(pose.y+.5-meta.height/2)*G.scale
        self.positions[id]=Vector3.new(x,G.surfaceY+4+height*Motion.height(pose.shown),z)
        local airborne=not d.preparing and not p.landed
        local frameDt=math.max(dt,.001)
        local motion=pose.motion:step(dt,{altitude=pose.altitude,airborne=airborne,landed=touched,diving=p.diving,paused=self.state.paused,reduced=self.world.reducedEffects,
            vx=math.clamp((pose.x-px)/frameDt/d.speed,-1,1),vz=math.clamp((pose.y-py)/frameDt/d.speed,-1,1)})
        motion.introT=shot.active and math.clamp(elapsed/2,0,1)or nil;motion.reducedEffects=self.world.reducedEffects==true
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
            local distance=(58+pose.altitude*18)*(self.world.dropZoom or 1)*(1-(reduced and 0 or .16*(motion.cameraKick or 0)/1.8))*(1-.4*self.camNear)
            local viewport=workspace.CurrentCamera.ViewportSize
            local matchDistance=math.max(24,180*G.scale/(2*math.tan(math.rad(25))*viewport.X/math.max(1,viewport.Y)))
            local settle=math.clamp(1-Motion.height(pose.shown)/.07,0,1);settle=settle*settle*(3-2*settle)
            distance+=(matchDistance-distance)*settle;focus=focus:Lerp(Vector3.new(x,G.surfaceY,z),settle)
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
        heading=self.spectacleMe and self.spectacleMe.heading or 0,obscured=obscured,paused=self.state.paused,flashes=self.world.mapFlashes~=false})
    local title=d.preparing and '전장 준비 중' or own.landed and string.format('착륙 완료, %d초 후 시작',left)or string.format('낙하 %d초',left)
    local hint=own.landed and (own.fallback and '유효한 육지에 자동 배치했어요.'or '모두 같은 시각에 전투를 시작해요.')or d.random and (touch and '착륙지 고정'or '랜덤 시작이라 착륙 위치는 정해져 있어요.')or touch and ''or 'WASD 착륙지 조절  Space 하강 속도'
    local land=self.diving and '천천히 하강'or '빠른 하강'
    if self.lastTitle~=title then self.lastTitle=title;self.title.Text=title end
    if self.lastHint~=hint then self.lastHint=hint;self.hint.Text=hint end
    self.hint.Visible=hint~=''
    if self.lastLand~=land then self.lastLand=land;self.land.Text=land end
    self.land.Visible=not d.random and not own.landed and not d.preparing;UI.enabled(self.land,elapsed>=3 and not self.state.paused)
    local size=self.frame.Parent.AbsoluteSize/UI.scale;local r=Layout.of(size.X,size.Y,touch,meta.width,meta.height)
    local panel=r.panel;UI.box(self.frame,panel.x,panel.y,panel.w,panel.h)
    UI.box(self.title,r.title.x,r.title.y,touch and r.title.w or panel.w-(self.land.Visible and 120 or 24),r.title.h);self.title.TextSize=touch and 15 or 17
    UI.box(self.hint,r.hint.x,r.hint.y,self.land.Visible and r.hint.w or panel.w-24,r.hint.h);self.hint.TextWrapped=true;self.hint.TextSize=14
    UI.box(self.land,r.land.x,r.land.y,r.land.w,r.land.h)
    self.land.TextSize=14
    local mw,mh=r.mini.w-8,r.mini.h-8
    UI.box(self.overview,r.mini.x,r.mini.y,r.mini.w,r.mini.h);UI.box(self.mapFrame,4,4,mw,mh)
    local hasPeers=false;for _,p in ipairs(d.players)do if p.id~=1 and (self.party[p.id]or self.ownTeam~=nil and p.team==self.ownTeam)then hasPeers=true;break end end
    self.rallyButton.Visible=hasPeers and not obscured and not shot.active and not d.preparing
    if self.rallyButton.Visible and self.rallyShownVersion~=self.version then self.rallyShownVersion=self.version;require(script.Parent.TelemetryStep).step('drop','rallyShown',{})end
    UI.enabled(self.rallyButton,not self.state.paused);UI.box(self.rallyButton,touch and size.X-144 or r.mini.x,r.mini.y+r.mini.h+8,touch and 80 or 88,44);self.rallyButton.TextSize=14
    local markerMini={x=r.mini.x,y=r.mini.y,w=r.mini.w,h=r.mini.h+(hasPeers and 52 or 0)}
    self.squad:step(self.party,self.positions,workspace.CurrentCamera,touch,markerMini,not obscured and not shot.active)
    local signals={}
    for _,signal in ipairs(d.rallies or {})do
        signals[signal.userId]=true;local b=self.rallyBlips[signal.userId]
        if not b then
            b=UI.make('Frame',self.mapFrame,{Name='Rally_'..signal.userId,Size=UDim2.fromOffset(14,18),AnchorPoint=Vector2.new(0,1),BackgroundTransparency=1,ZIndex=23})
            UI.make('Frame',b,{Name='Pole',Size=UDim2.fromOffset(2,18),BackgroundColor3=UI.colors.ice,BorderSizePixel=0,ZIndex=23})
            local cloth=UI.make('Frame',b,{Name='Flag',Position=UDim2.fromOffset(2,0),Size=UDim2.fromOffset(11,8),BackgroundColor3=UI.colors.ice,BorderSizePixel=0,ZIndex=24});UI.stroke(cloth,UI.colors.bg,1)
            self.rallyBlips[signal.userId]=b;if signal.userId~=Me.UserId then require(script.Parent.TelemetryStep).step('drop','rallyReceived',{})end
        end
        b.Position=UDim2.fromScale((signal.tile%meta.width+.5)/meta.width,(signal.tile//meta.width+.5)/meta.height)
    end
    for uid,b in pairs(self.rallyBlips)do if not signals[uid]then b:Destroy();self.rallyBlips[uid]=nil end end
    if self.miniWidth~=mw then self.miniWidth=mw;self.raster:fit();self.raster:draw()end
end
return M
