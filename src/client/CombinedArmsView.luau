local U=require(script.Parent.Parent.Core.UnitRules)
local G=require(script.Parent.Parent.Core.WorldGeometry)
local Catalog=require(script.Parent.Parent.Core.CosmeticCatalog)
local Models=require(script.Parent.MobileUnits)
local RailMotion=require(script.Parent.RailMotion)
local FactionColors=require(script.Parent.FactionColors)
local HotbarIcons=require(script.Parent.HotbarIcons)
local NukeFx=require(script.Parent.NukeFx)
local NukeSkins=require(script.Parent.NukeSkins)
local Flight=require(script.Parent.Parent.Core.FlightPath)
local Skin=require(script.Parent.SkinMapStyle)
local InterceptFx=require(script.Parent.InterceptFx)
local PoseBatch=require(script.Parent.RenderPoseBatch)
local Probe=require(script.Parent.FrameProbe)
local function glide(v,cf,batch)
    local model=v.model;local rig=v.rig
    if not rig then
        local pivot=model:GetPivot();local inverse=pivot:Inverse();rig={parts={},offsets={}}
        for _,d in ipairs(model:GetDescendants())do if d:IsA('BasePart')then table.insert(rig.parts,d);table.insert(rig.offsets,inverse*d.CFrame)end end
        rig.free=model.PrimaryPart==nil
        local function drop()v.rig=nil end
        rig.added=model.DescendantAdded:Connect(function(d)if d:IsA('BasePart')then if rig.added then rig.added:Disconnect();rig.removed:Disconnect()end;drop()end end)
        rig.removed=model.DescendantRemoving:Connect(function(d)if d:IsA('BasePart')then if rig.added then rig.added:Disconnect();rig.removed:Disconnect()end;drop()end end)
        v.rig=rig
    end
    for i,part in ipairs(rig.parts)do batch:put(part,cf*rig.offsets[i])end
    if rig.free then model.WorldPivot=cf end
end
local function unrig(v)local rig=v.rig;if rig then v.rig=nil;if rig.added then rig.added:Disconnect();rig.removed:Disconnect()end end end
local badgeKinds={Warship={'Warship',24,4},TransportShip={'Transport',16,8},TradeShip={'TradeShip',2,1},Train={false,16,3},AtomBomb={'AtomBomb',26,13},HydrogenBomb={'HydrogenBomb',30,15},MIRV={'MIRV',30,15}}
local danger=Color3.fromRGB(255,82,82)
local ink=Color3.fromRGB(16,22,30)
local function corner(parent,r)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=parent;return c end
local nukeCircle={0,0,1/.9}
local function badge(model,kind,color,trainType,skin,relation)
    local spec=badgeKinds[kind];if not spec then return nil end
    if kind=='Train'and trainType~=nil and trainType~='Engine'then return nil end
    local anchor=model:FindFirstChildWhichIsA("BasePart");if not anchor then return nil end
    local missile=U.nukes[kind]==true
    local small=kind=='TradeShip';local compact=small or kind=='TransportShip'
    local pad=missile and (skin and 16 or 0) or compact and 6 or 10
    local tall=kind=='Train'and 10 or spec[2];if tall~=spec[2]then pad=8 end
    local gui=Instance.new("BillboardGui");gui.Name="UnitBadge";gui.Size=UDim2.fromOffset(tall+pad,tall+pad);gui.AlwaysOnTop=true;gui.LightInfluence=0
    gui.StudsOffsetWorldSpace=Vector3.new(0,missile and 0 or kind=='Train'and .5 or 1.4,0);gui.Adornee=anchor;gui.Enabled=missile;gui.Parent=model
    if kind=='Train'then
        local heading=Instance.new("Frame");heading.Name="Heading";heading.Size=UDim2.fromScale(1,1);heading.BackgroundTransparency=1;heading.Parent=gui
        local body=Instance.new("Frame");body.Name="Disc";body.AnchorPoint=Vector2.new(.5,.5);body.Position=UDim2.fromScale(.5,.5);body.Size=UDim2.fromOffset(tall<spec[2]and 4 or 7,tall);body.BorderSizePixel=0;body.BackgroundColor3=color;body.Parent=heading
        corner(body,spec[3]);local line=Instance.new("UIStroke");line.Color=ink;line.Thickness=1.5;line.Parent=body
        local head=Instance.new("Frame");head.Name="Head";head.AnchorPoint=Vector2.new(.5,0);head.Position=UDim2.new(.5,0,0,0);head.Size=UDim2.new(1,0,0,tall<spec[2]and 3 or 5);head.BorderSizePixel=0;head.BackgroundColor3=Color3.fromRGB(236,243,248);head.Parent=body
        corner(head,spec[3])
        return gui
    end
    local disc=Instance.new("Frame");disc.Name="Disc";disc.AnchorPoint=Vector2.new(.5,.5);disc.Position=UDim2.fromScale(.5,.5);disc.Size=UDim2.fromOffset(spec[2],spec[2]);disc.BorderSizePixel=0;disc.BackgroundColor3=missile and danger or ink;disc.BackgroundTransparency=missile and 0 or small and .3 or .1;disc.ZIndex=2;disc.Parent=gui
    corner(disc,spec[3])
    local line=Instance.new("UIStroke");line.Color=missile and Color3.new(1,1,1) or color;line.Thickness=compact and 1.5 or 2;line.Transparency=small and .25 or 0;line.Parent=disc
    if missile and skin then
        disc.BackgroundColor3=skin.primary:Lerp(skin.accent,.35);line.Color=relation or danger;line.Thickness=2.5
        local layers=Skin.attach({front=disc,back=gui,top=disc,box=1,backScale=spec[2]/(spec[2]+pad),frontZ=2,backZ=1,topZ=4})
        Skin.apply(layers,skin,"Disc",nukeCircle,spec[2],false,false,.5)
        gui:SetAttribute("SkinTier",skin.tier);model:SetAttribute("SkinBadge",true)
        local icon=HotbarIcons.create(disc,spec[1],math.floor(spec[2]*.72),Color3.new(1,1,1));icon.AnchorPoint=Vector2.new(.5,.5);icon.Position=UDim2.fromScale(.5,.5);icon.ZIndex=3
        return gui,layers
    end
    local icon=HotbarIcons.create(disc,spec[1],math.floor(spec[2]*.72),Color3.new(1,1,1));icon.AnchorPoint=Vector2.new(.5,.5);icon.Position=UDim2.fromScale(.5,.5);icon.ZIndex=3
    if not missile then
        local heading=Instance.new("Frame");heading.Name="Heading";heading.Size=UDim2.fromScale(1,1);heading.BackgroundTransparency=1;heading.Visible=false;heading.ZIndex=1;heading.Parent=gui
        local tip=Instance.new("Frame");tip.Name="Pointer";tip.AnchorPoint=Vector2.new(.5,.5);tip.Position=UDim2.new(.5,0,0,compact and 2.5 or 4);tip.Size=UDim2.fromOffset(compact and 4 or 7,compact and 4 or 7);tip.Rotation=45;tip.BorderSizePixel=0;tip.BackgroundColor3=color;tip.ZIndex=1;tip.Parent=heading
        local edge=Instance.new("UIStroke");edge.Color=ink;edge.Thickness=1;edge.Parent=tip
    end
    return gui
end
local function screenAngle(frame,direction)
    return math.deg(math.atan2(direction:Dot(frame.RightVector),direction:Dot(frame.UpVector)))
end
local presentation
local function MapPresentation()presentation=presentation or require(script.Parent.Parent.Core.MapPresentation);return presentation end
local good,gold=Color3.fromRGB(180,240,90),Color3.fromRGB(245,196,81)
local function hull(model)
    local anchor=model:FindFirstChildWhichIsA("BasePart");if not anchor then return nil end
    local gui=Instance.new("BillboardGui");gui.Name="HullBar";gui.Size=UDim2.fromOffset(30,9);gui.AlwaysOnTop=true;gui.LightInfluence=0
    gui.StudsOffsetWorldSpace=Vector3.new(0,1.4,0);gui.SizeOffset=Vector2.new(0,1.9);gui.Adornee=anchor;gui.Parent=model
    local track=Instance.new("Frame");track.Name="Track";track.Size=UDim2.fromOffset(30,4);track.BorderSizePixel=0;track.BackgroundColor3=Color3.fromRGB(11,15,20);track.BackgroundTransparency=.15;track.Parent=gui
    local fill=Instance.new("Frame");fill.Name="Fill";fill.Size=UDim2.fromScale(1,1);fill.BorderSizePixel=0;fill.BackgroundColor3=good;fill.Parent=track
    local pips={}
    for i=1,3 do local p=Instance.new("Frame");p.Name="Veteran"..i;p.Position=UDim2.fromOffset(9+(i-1)*5,6);p.Size=UDim2.fromOffset(3,3);p.BorderSizePixel=0;p.BackgroundColor3=gold;p.Visible=false;p.Parent=gui;pips[i]=p end
    return {gui=gui,fill=fill,pips=pips}
end
local function dress(h,u)
    local ratio=math.clamp((u.health or 0)/math.max(1,u.maxHealth or 1),0,1)
    if h.ratio~=ratio then h.ratio=ratio;h.fill.Size=UDim2.fromScale(ratio,1);h.fill.BackgroundColor3=ratio>.5 and good or ratio>.25 and gold or danger end
    local vet=u.veterancy or 0
    if h.vet~=vet then h.vet=vet;for i,p in ipairs(h.pips)do p.Visible=i<=vet end end
end
local M={};M.__index=M
function M.new(world) return setmetatable({world=world,units={},dying={},rails={},effectsSeen=0,railView=require(script.Parent.RailView).new(world)},M) end
function M:unitFolder()
    if not self.folder then local f=Instance.new('Folder');f.Name='CombinedArms';f.Parent=self.world.folder;self.folder=f end
    return self.folder
end
function M:reset()
    self.railView:reset()
    for _,v in pairs(self.units) do if v.ring then v.ring.model:Destroy()end;if v.cosmeticTrail then v.cosmeticTrail:destroy()end;v.model:Destroy() end;for _,v in pairs(self.rails) do v:Destroy() end
    for _,v in ipairs(self.dying)do if v.cosmeticTrail then v.cosmeticTrail:destroy()end;v.model:Destroy()end
    self.units={};self.dying={};self.pending=nil;self.skipped={};self.tradeCount=0;self.tradeKeep=1;self.rails={};self.effectsSeen=0;self.terrainRevision=-1;self.fallout={}
    if self.folder then self.folder:Destroy();self.folder=nil end;self.lastStep=nil
end
function M:position(tile,kind)
    local m=self.world.map.meta;local x,y,z=G.toWorld(tile,m.width,m.height)
    return Vector3.new(x,y+(U.nukes[kind] and 5 or kind=="SAMMissile" and 4 or kind=="Shell" and 1.6 or .12),z)
end
local ships={Warship=true,TransportShip=true,TradeShip=true}
M.unitBudget=.003
M.tradeCap=60
local function rank(id)return ((tonumber(id)or 0)*.6180339887)%1 end
function M:thinned(kind,owner,group)
    if kind=='TradeShip'then return owner~=1 and rank(group)>=(self.tradeKeep or 1)end
    return kind=='Train'and rank(group)>=(self.trainKeep or 1)
end
function M:thin()
    local zoom=math.clamp((700-(self.world.liveW or self.world.view.w))/450,0,1);self.trainKeep=zoom>0 and zoom or -1
    local count=self.tradeCount or 0
    if count<=M.tradeCap then self.tradeKeep=1;return end
    local base=M.tradeCap/count
    self.tradeKeep=base+(1-base)*zoom
end
function M:drain(budget)
    local started=os.clock();local p=self.pending
    Probe.start('Units.loop')
    if p then
        while p.i<=#p.list do
            local u=p.list[p.i];p.i+=1
            self:apply(u,p.ctx)
            if os.clock()-started>budget then break end
        end
        if p.i>#p.list then self.pending=nil end
    end
    Probe.stop('Units.loop')
    Probe.start('Units.remove')
    local dying=self.dying
    while #dying>0 and os.clock()-started<=budget do self:remove(table.remove(dying),nil)end
    Probe.stop('Units.remove')
end
function M:apply(u,ctx)
    local state,loadouts,kinds,own=ctx.state,ctx.loadouts,ctx.kinds,ctx.own;local now=os.clock()
    local v=self.units[u.id];local pos=self:position(u.tile,u.kind)
    if v and v.owner~=u.owner and not v.missile then if v.ring then v.ring.model:Destroy()end;if v.cosmeticTrail then v.cosmeticTrail:destroy()end;v.model:Destroy();self.units[u.id]=nil;v=nil end
    local missile=U.nukes[u.kind]==true
    if missile and u.sourceTile and u.targetTile then pos=self:arc(u,pos) end
    if not v then
        Probe.start('Units.create')
        local color=FactionColors.get(u.owner,kinds[u.owner],own)
        local model
        if missile then
            local loadout=loadouts[u.owner]
            model=NukeFx.warhead(u.kind,NukeSkins.get(loadout,"projectile"),NukeSkins.get(loadout,"trail"),color)
            NukeFx.setReduced(model,self.world.reducedEffects==true)
        elseif u.kind=="SAMMissile"then
            local loadout=loadouts[u.owner]
            model=InterceptFx.interceptor(NukeSkins.get(loadout,"projectile"),NukeSkins.get(loadout,"trail"),color)
            InterceptFx.setReduced(model,self.world.reducedEffects==true)
        else model=Models.create(u.kind,Catalog.get(u.owner==1 and (state.cosmetics or {}).projectile or "classic"),color,u.trainType)end
        model.Name=u.kind..u.id;model.Parent=self:unitFolder();model:PivotTo(CFrame.new(pos));v={model=model,to=pos,from=pos,at=now,owner=u.owner,id=u.id,group=u.engine or u.id};self.units[u.id]=v
        if u.kind=="SAMMissile"then self:launchInterceptor(v,u,state,loadouts,now)end
        if u.kind=='Train'and self.skipped and self.skipped[u.id]then model.Parent=nil;v.waiting=true end
        local skin=missile and Skin.spec(Catalog.forSlot(loadouts[u.owner],"projectile"))or nil
        v.trail=not missile and not v.homing and model:FindFirstChildWhichIsA("Trail",true)or nil;v.badge,v.skin=badge(model,u.kind,color,u.trainType,skin,missile and self:relation(u,state)or nil);v.missile=missile
        if missile then local e=model:GetExtentsSize();v.length=math.max(e.X,e.Y,e.Z)end
        v.pointer=v.badge and v.badge:FindFirstChild("Heading")or nil
        if u.targetTile and u.kind~="MIRVWarhead" and missile then v.ring=self:targetRing(u,state,skin) end
        if (u.kind=="AtomBomb"or u.kind=="HydrogenBomb")and u.sourceTile and u.targetTile then self:follow(v,u,now) end
        if u.kind=="Warship"then v.hull=hull(model)end
        if (ships[u.kind]or u.kind=='Train')and not self.world.reducedEffects and not(self.skipped and self.skipped[u.id])then v.baseScale=model:GetScale();v.grow=0;model:ScaleTo(v.baseScale*.55)end
        if u.kind=="TransportShip"and u.owner==1 and u.targetTile then
            local m=self.world.map.meta;local x,y,z=G.toWorld(u.targetTile,m.width,m.height)
            v.ring=NukeFx.telegraph(self:unitFolder(),Vector3.new(x,y,z),6*G.scale,Color3.fromRGB(54,226,208),true)
        end
        Probe.stop('Units.create')
    end
    if v.hull and u.health then dress(v.hull,u)end
    if not missile and not v.homing and u.kind~='TradeShip'and u.kind~='Train'then
        local id=(loadouts[u.owner]or {}).commanderTrail or 'classic'
        v.trailWant=id~='classic'and id or nil
        if v.cosmeticTrail and v.cosmeticTrailId~=id then v.cosmeticTrail:destroy();v.cosmeticTrail=nil;v.cosmeticTrailId=nil end
    end
    if v.hidden then
        v.hidden=nil;unrig(v);v.from=pos;v.to=pos;v.at=0;v.settled=true;v.shownPos=pos;v.posed=nil;v.tile=u.tile
        v.model:PivotTo(CFrame.lookAt(pos,pos+(v.direction or Vector3.new(0,0,-1))))
        if u.kind=='Train'then v.waiting=true else v.model.Parent=self:unitFolder()end
    end
    if v.path then self:advance(v,u,now)
    elseif v.homing then v.homing.serverP=self:progress(v.homing,u.tile)
    elseif (pos-v.to).Magnitude>.001 then
        v.from=v.shownPos or v.model:GetPivot().Position;v.to=pos;v.at=now;v.settled=false
        if (pos-v.from).Magnitude>.001 then v.direction=(pos-v.from).Unit end
        if u.kind=='Train'then
            local tiles=v.tile and self.railView:between(v.tile,u.tile)
            v.railRoute=tiles and RailMotion.route(v.from,tiles,function(tile)return self:position(tile,'Train')end)or nil
        end
    end
    v.tile=u.tile;v.kind=u.kind
    local attrs=v.attrs;if not attrs then attrs={};v.attrs=attrs end
    local status=MapPresentation().status(u,state.tick or 0)
    if attrs.Owner~=u.owner then attrs.Owner=u.owner;v.model:SetAttribute("Owner",u.owner)end
    if attrs.Troops~=u.troops then attrs.Troops=u.troops;v.model:SetAttribute("Troops",u.troops)end
    if attrs.Health~=u.health then attrs.Health=u.health;v.model:SetAttribute("Health",u.health)end
    if attrs.DisplayStatus~=status then attrs.DisplayStatus=status;v.model:SetAttribute('DisplayStatus',status)end
    if v.beacon==nil then v.beacon=v.model:FindFirstChild('StatusBeacon')or false end
    local warn=status=='damaged'or u.inCombat==true
    if v.beacon and v.beaconWarn~=warn then v.beaconWarn=warn;v.beacon.Color=warn and Color3.fromRGB(255,185,56)or Color3.fromRGB(191,239,255)end
    if v.trail then
        local id=(loadouts[u.owner]or {}).commanderTrail or 'classic'
        if v.trailStyle~=id then local style=Catalog.get(id);v.trail.Color=ColorSequence.new(Color3.fromRGB(255,185,56),Color3.fromRGB(table.unpack(style.accent)));v.trailStyle=id end
        local reduced=self.world.reducedEffects==true
        if v.trailReduced~=reduced then v.trailReduced=reduced;v.trail.Enabled=not reduced;v.trail.Lifetime=reduced and .1 or v.missile and u.kind~="MIRVWarhead" and 2.2 or .55 end
    end
    if v.homing then local reduced=self.world.reducedEffects==true;if v.reduced~=reduced then v.reduced=reduced;InterceptFx.setReduced(v.model,reduced)end end
    if not v.trail and not v.missile and not v.homing then local reduced=self.world.reducedEffects==true;if v.wakeReduced~=reduced then local t=v.model:FindFirstChild("Wake",true)or v.model:FindFirstChild("RailDust",true);v.wakeTries=(v.wakeTries or 0)+1;if t or v.wakeTries>4 then v.wakeReduced=reduced;if t then t.Enabled=not reduced end end end end
end
function M:update(state)
    if not self.world.map then return end
    Probe.start('Units.rail');local loadouts=require(script.Parent.CosmeticLoadouts).all(state)
    self.railView:update(state);Probe.stop('Units.rail')
    local alive={};local now=os.clock()
    local gap=now-(self.lastUpdate or now);self.lastUpdate=now
    if gap>.12 and gap<1.2 then self.span=(self.span or .3)*.7+gap*.3 end
    local kinds={};for _,f in ipairs(state.factions or {})do kinds[f.id]=f.kind end
    local own=Color3.fromRGB(table.unpack(Catalog.get(state.style).territory))
    local queue,later={},{}
    local camera=workspace.CurrentCamera;local size=camera and camera.ViewportSize
    local trade,trainSize=0,{}
    for _,u in ipairs(state.units or {})do
        if u.kind=='TradeShip'and u.owner~=1 then trade+=1
        elseif u.kind=='Train'then local g=u.engine or u.id;trainSize[g]=(trainSize[g]or 0)+1 end
    end
    self.trainSize=trainSize
    self.tradeCount=trade;self:thin()
    local skipped=self.skipped or {};self.skipped=skipped
    for _,u in ipairs(state.units or {}) do
        if U.structures[u.kind] then continue end
        alive[u.id]=true;local v=self.units[u.id]
        if self:thinned(u.kind,u.owner,u.engine or u.id)then
            if not v then skipped[u.id]=true end;continue
        end
        local urgent=U.nukes[u.kind]==true or u.kind=='SAMMissile'or u.kind=='Shell'or not camera
        if not urgent then
            local sp=camera:WorldToViewportPoint(v and v.shownPos or self:position(u.tile,u.kind))
            urgent=sp.Z>0 and sp.X>-80 and sp.Y>-80 and sp.X<size.X+80 and sp.Y<size.Y+80
        end
        table.insert(urgent and queue or later,u)
    end
    table.move(later,1,#later,#queue+1,queue)
    self.pending={list=queue,i=1,ctx={state=state,loadouts=loadouts,kinds=kinds,own=own}}
    Probe.start('Units.remove')
    for id,v in pairs(self.units) do
        if not alive[id] then
            self.units[id]=nil
            if v.missile or v.homing or v.hull or not(ships[v.kind]or v.kind=='Train')then self:remove(v,alive)
            else table.insert(self.dying,v)end
        end
    end
    for id in pairs(skipped)do if not alive[id]then skipped[id]=nil end end
    Probe.stop('Units.remove')
    self:drain(M.unitBudget)
    local changed=false
    if self.terrainRevision~=state.terrainRevision then
        self.terrainRevision=state.terrainRevision
        for _,v in ipairs(state.terrainChanges or {}) do buffer.writeu8(self.world.map.terrain,v[1],v[2]);self.world:markTerritory(v[1]);changed=true end
    end
    local fallout={};for _,tile in ipairs(state.fallout or {}) do fallout[tile]=true;if not self.fallout[tile] then self.world:markTerritory(tile) end end
    for tile in pairs(self.fallout or {}) do if not fallout[tile] then self.world:markTerritory(tile) end end
    self.fallout=fallout;self.world.map.fallout=fallout
    if changed then for _,c in ipairs(self.world.chunks) do buffer.fill(c.raster.finishBuffer,0,0) end end
end
local function peak(w,src,dst)
    local dx,dy=src%w-dst%w,math.floor(src/w)-math.floor(dst/w);return math.clamp(math.sqrt(dx*dx+dy*dy)/3*G.scale,4,90)
end
function M:visibleAltitude(height)
    local cameraHeight=workspace.CurrentCamera.CFrame.Position.Y-G.surfaceY
    return math.min(height,math.max(2,cameraHeight*.48))
end
function M:arc(u,pos)
    local m=self.world.map.meta;local w=m.width
    local function d(a,b)local dx,dy=a%w-b%w,math.floor(a/w)-math.floor(b/w);return math.sqrt(dx*dx+dy*dy)end
    local gone,left=d(u.sourceTile,u.tile),d(u.tile,u.targetTile);local t=gone/math.max(1,gone+left)
    return pos+Vector3.new(0,self:visibleAltitude(peak(w,u.sourceTile,u.targetTile)*4*t*(1-t)),0)
end
function M:follow(v,u,now)
    local m=self.world.map.meta
    for _,up in ipairs({true,false})do
        local path=Flight.parabola(m.width,m.height,u.sourceTile,u.targetTile,U.nukeSpeed(u.kind),up)
        for i,t in ipairs(path)do if t==u.tile then
            v.path=path;v.index=i;v.indexAt=now;v.rate=10;v.shown=i;v.peak=peak(m.width,u.sourceTile,u.targetTile);return
        end end
    end
end
function M:advance(v,u,now)
    if v.path[v.index]==u.tile then return end
    for j=v.index+1,#v.path do if v.path[j]==u.tile then
        local dt=now-v.indexAt;if dt>.05 and v.index>1 then v.rate=math.clamp(v.rate*.5+(j-v.index)/dt*.5,2,80)end
        v.index=j;v.indexAt=now;v.settled=false;return
    end end
    v.path=nil
end
function M:pathPoint(v,i)
    local m=self.world.map.meta;local n=#v.path;i=math.clamp(i,1,n)
    local i0=math.floor(i);local f=i-i0;local a,b=v.path[i0],v.path[math.min(n,i0+1)]
    local ax,ay,az=G.toWorld(a,m.width,m.height);local bx,_,bz=G.toWorld(b,m.width,m.height)
    local t=(i-1)/math.max(1,n-1)
    return Vector3.new(ax+(bx-ax)*f,ay+.8+self:visibleAltitude(v.peak*4*t*(1-t)),az+(bz-az)*f)
end
function M:launchInterceptor(v,u,state,loadouts,now)
    local src=u.tile
    for _,o in ipairs(state.units or {})do if o.id==u.sourceUnit then src=o.tile;break end end
    local launch=self:position(src,"SAMLauncher")+Vector3.new(0,.6,0)
    local m=self.world.map.meta;local w=m.width
    local dx,dy=src%w-(u.targetTile or src)%w,math.floor(src/w)-math.floor((u.targetTile or src)/w)
    v.homing={launch=launch,t0=now,T=math.max(.3,math.sqrt(dx*dx+dy*dy)/120),target=u.targetUnit,src=src,dst=u.targetTile or u.tile,p=0,
        fallback=self:position(u.targetTile or u.tile,"SAMMissile")}
    v.model:PivotTo(CFrame.new(launch));local e=v.model:GetExtentsSize();v.length=math.max(e.X,e.Y,e.Z)
    local reduced=self.world.reducedEffects==true
    InterceptFx.launch(self:unitFolder(),launch-Vector3.new(0,.5,0),NukeSkins.get(loadouts[u.owner],"trail"),reduced)
    local target=self.units[u.targetUnit]
    local allied=false;for _,f in ipairs(state.factions or {})do if f.id==u.owner then allied=f.allied==true or f.teammate==true;break end end
    local color=u.owner==1 and Color3.fromRGB(54,226,208)or target and target.owner==1 and danger or allied and Color3.fromRGB(191,239,255)or nil
    if target and color then v.lock=InterceptFx.lock(target.model:FindFirstChild("Exhaust")or target.model:FindFirstChildWhichIsA("BasePart"),color,reduced)end
    if u.owner==1 then require(script.Parent.ToyAudio).play("launch",.35,1.7)end
end
function M:progress(h,tile)
    local w=self.world.map.meta.width
    local function d(a,b)local dx,dy=a%w-b%w,math.floor(a/w)-math.floor(b/w);return math.sqrt(dx*dx+dy*dy)end
    local total=d(h.src,h.dst);return total>0 and math.clamp(d(h.src,tile)/total,0,1)or 1
end
function M:home(v,now)
    local h=v.homing
    h.p=math.max(h.p,math.clamp((now-h.t0)/h.T,0,1),h.serverP or 0)
    local target=self.units[h.target]
    local aim=target and target.model.Parent and target.model:GetPivot().Position or h.fallback;h.aim=aim
    local function at(p)local e=p^1.6;return h.launch:Lerp(aim,e)+Vector3.new(0,math.min(6,(aim-h.launch).Magnitude*.16)*4*e*(1-e),0)end
    local pos=at(h.p);local ahead=at(math.min(1,h.p+.04))
    local direction=(ahead-pos).Magnitude>1e-3 and (ahead-pos).Unit or v.direction or Vector3.new(0,1,0)
    v.direction=direction;v.model:PivotTo(CFrame.lookAt(pos,pos+direction,math.abs(direction.Y)>.98 and Vector3.zAxis or Vector3.yAxis))
end
function M:removeInterceptor(v,alive)
    if v.lock then v.lock:Destroy();v.lock=nil end
    local h=v.homing;local tail=v.model:FindFirstChild("Exhaust")
    if tail and not self.world.reducedEffects then
        if h.aim and not (alive and alive[h.target])then v.model:PivotTo(CFrame.lookAt(h.aim,h.aim+(v.direction or Vector3.yAxis)))end
        tail.Parent=self:unitFolder();tail.Transparency=1
        for _,c in ipairs(tail:GetChildren())do if c:IsA("PointLight")or c:IsA("ParticleEmitter")then c:Destroy()end end
        task.delay(.08,function()for _,t in ipairs(tail:GetChildren())do if t:IsA("Trail")then t.Enabled=false end end end)
        game:GetService("Debris"):AddItem(tail,3)
    end
    v.model:Destroy()
end
function M:rocketPosition(id)
    local v=id and self.units[id];if v and v.missile and v.model.Parent then return v.model:GetPivot().Position end
    local f=id and self.fallen and self.fallen[id];return f and f.pos or nil
end
function M:relation(u,state)
    local f;for _,o in ipairs(state.factions or {})do if o.id==u.owner then f=o;break end end
    return u.owner==1 and Color3.fromRGB(54,226,208)or f and (f.allied or f.teammate)and Color3.fromRGB(245,196,81)or danger
end
function M:targetRing(u,state,skin)
    local m=self.world.map.meta;local x,y,z=G.toWorld(u.targetTile,m.width,m.height);local _,outer=U.magnitude(u.kind)
    return NukeFx.telegraph(self:unitFolder(),Vector3.new(x,y,z),outer*G.scale,self:relation(u,state),true,skin)
end
M.missilePixels={AtomBomb=38,HydrogenBomb=46,MIRV=46,MIRVWarhead=14,SAMMissile=22}
function M:missileSize(v,camera)
    local pos=v.model:GetPivot().Position;local dist=(camera.CFrame.Position-pos).Magnitude
    local perStud=camera.ViewportSize.Y/math.max(1e-3,2*dist*math.tan(math.rad(camera.FieldOfView)/2))
    local base=(v.length or 2)*perStud;local scale=v.missileScale or 1
    local want=math.clamp((M.missilePixels[v.kind]or 32)/math.max(base,1e-3),1,v.kind=='MIRVWarhead'and 2.5 or 8)
    if math.abs(want-scale)/scale>.12 then scale=want;v.missileScale=want;v.model:ScaleTo(want)end
    return base*scale
end
function M:remove(v,alive)
    if v.cosmeticTrail then v.cosmeticTrail:destroy();v.cosmeticTrail=nil end
    if v.ring then v.ring.model:Destroy()end
    if v.homing then self:removeInterceptor(v,alive);return end
    if v.missile and v.id then
        local fallen=self.fallen or {};self.fallen=fallen;local now=os.clock()
        fallen[v.id]={pos=v.model:GetPivot().Position,at=now}
        for id,f in pairs(fallen)do if now-f.at>4 then fallen[id]=nil end end
    end
    if v.hull then v.hull.gui.Enabled=false end
    if v.model.Name:sub(1,7)=="Warship" then require(script.Parent.DestructionFx).warship(v.model,self.world.reducedEffects==true);return end
    local tail=v.missile and v.model:FindFirstChild("Exhaust")
    if tail and not self.world.reducedEffects then
        tail.Parent=self:unitFolder();tail.Transparency=1;local light=tail:FindFirstChild("EngineLight");if light then light:Destroy()end
        for _,t in ipairs(tail:GetChildren())do if t:IsA("Trail")then t.Enabled=false end end
        game:GetService("Debris"):AddItem(tail,7)
    end
    v.model:Destroy()
end
function M:visible(v,pos,t,view)
    if t>=1 or not view or not v.posed then v.posed=pos;v.posedLook=v.heading and v.heading.LookVector;return true end
    local sp=view.camera:WorldToViewportPoint(pos);local size=view.size
    if sp.Z<0 or sp.X<-80 or sp.Y<-80 or sp.X>size.X+80 or sp.Y>size.Y+80 then return false end
    local look=v.heading and v.heading.LookVector
    if (pos-v.posed).Magnitude*view.perStud<.33 and not(look and v.posedLook and look:Dot(v.posedLook)<.99985)then return false end
    v.posed=pos;v.posedLook=look;return true
end
M.trailCap=16;M.trailPick=.25;M.trailAttachPerFrame=3
function M:pickTrails(view,now)
    if now>=(self.trailPickAt or 0)then
        self.trailPickAt=now+M.trailPick
        local list={};local size=view and view.size
        if size then
            local cx,cy=size.X/2,size.Y/2
            for _,v in pairs(self.units)do
                if v.trailWant and v.model.Parent then
                    local sp=view.camera:WorldToViewportPoint(v.shownPos or v.to)
                    if sp.Z>0 and sp.X>-40 and sp.Y>-40 and sp.X<size.X+40 and sp.Y<size.Y+40 then
                        local d=(sp.X-cx)^2+(sp.Y-cy)^2;if v.owner==1 then d-=1e12 end
                        table.insert(list,{v=v,d=d})
                    end
                end
            end
            table.sort(list,function(a,b)return a.d<b.d end)
        end
        local keep={};for i=1,math.min(M.trailCap,#list)do keep[list[i].v]=true end
        for _,v in pairs(self.units)do
            if v.cosmeticTrail and not keep[v]then v.cosmeticTrail:destroy();v.cosmeticTrail=nil;v.cosmeticTrailId=nil end
        end
        self.trailQueue={};for i=1,math.min(M.trailCap,#list)do local v=list[i].v;if not v.cosmeticTrail then table.insert(self.trailQueue,v)end end
    end
    local queue=self.trailQueue;if not queue then return end
    for _=1,M.trailAttachPerFrame do
        local v=table.remove(queue,1);if not v then break end
        if v.trailWant and v.model.Parent and not v.cosmeticTrail then
            v.cosmeticTrailId=v.trailWant;v.cosmeticTrail=require(script.Parent.CommanderTrail).attach(v.model,v.trailWant)
        end
    end
end
function M:step()
    self.railView:step()
    if self.pending or #self.dying>0 then self:drain(M.unitBudget)end
    local now=os.clock();local dt=now-(self.lastStep or now);self.lastStep=now
    local far=self.world.view.w>140;local reduced=self.world.reducedEffects==true
    local camera=workspace.CurrentCamera;local turn=camera and camera.CFrame.Rotation
    local reaim=far and turn~=self.pointerTurn;if far then self.pointerTurn=turn end
    local batch=self.moveBatch or PoseBatch.new();self.moveBatch=batch
    local view=camera and {camera=camera,size=camera.ViewportSize,perStud=camera.ViewportSize.X/math.max(1,(self.world.liveW or self.world.view.w)*G.scale)}
    Probe.start('Units.trails');self:pickTrails(view,now);Probe.stop('Units.trails')
    local pixelsPerTile=view and view.size.X/math.max(1,self.world.liveW or self.world.view.w)or 99
    local stride=M.everyFrame and 1 or pixelsPerTile<2 and 3 or pixelsPerTile<4 and 2 or 1
    self.frameNo=((self.frameNo or 0)+1)%6
    self:thin();local hides=0
    local trains={}
    for _,v in pairs(self.units)do if v.kind=='Train'then local g=v.group or v.id;local t=trains[g];if not t then t={};trains[g]=t end;table.insert(t,v)end end
    for g,list in pairs(trains)do
        if self:thinned('Train',nil,g)then
            if hides<40 then for _,v in ipairs(list)do if not v.hidden then hides+=1;v.hidden=true;v.waiting=nil;unrig(v);v.model.Parent=nil end end end
        else
            local ready=#list>=((self.trainSize or {})[g]or 0)
            for _,v in ipairs(list)do if v.hidden then ready=false;break end end
            if ready then for _,v in ipairs(list)do if v.waiting then v.waiting=nil;v.model.Parent=self:unitFolder()end end end
        end
    end
    for _,v in pairs(self.units) do
        if v.kind=='Train'and(v.hidden or v.waiting)then continue end
        if v.kind=='TradeShip'then
            if self:thinned(v.kind,v.owner,v.group or v.id)then
                if not v.hidden and hides<40 then hides+=1;v.hidden=true;unrig(v);v.model.Parent=nil end
                continue
            elseif v.hidden then continue end
        end
        local udt=dt
        if stride>1 and not(v.missile or v.homing or v.path or v.ring or v.grow)then
            if (tonumber(v.id)or 0)%stride~=self.frameNo%stride then continue end
            udt=dt*stride
        end
        if v.cosmeticTrail then v.cosmeticTrail:step(not v.settled,reduced)end
        local showBadge=far
        if v.missile then showBadge=camera~=nil and self:missileSize(v,camera)<16 end
        if v.badge and v.badge.Enabled~=showBadge then v.badge.Enabled=showBadge;if showBadge then v.pointerAngle=nil end end
        if v.skin and showBadge and v.skin.animated then Skin.step(v.skin,now,reduced)end
        if far and v.pointer and (reaim or not v.settled or v.pointerAngle==nil)then
            local direction=v.kind=='Train'and v.heading and v.heading.LookVector or v.direction
            if direction then
                local angle=screenAngle(camera.CFrame,Vector3.new(direction.X,0,direction.Z))
                if not v.pointerAngle or math.abs((angle-v.pointerAngle+180)%360-180)>2 then v.pointerAngle=angle;v.pointer.Rotation=angle end
                if not v.pointer.Visible then v.pointer.Visible=true end
            else v.pointerAngle=false end
        end
        if v.ring then NukeFx.stepTelegraph(v.ring,now,dt,reduced)end
        if v.missile and v.reduced~=reduced then v.reduced=reduced;NukeFx.setReduced(v.model,reduced)end
        if v.path then
            local ahead=v.index>1 and math.min(v.rate*(now-v.indexAt),v.rate*.5)or 0
            local i=math.max(v.shown,math.min(#v.path,v.index+ahead));local pos=self:pathPoint(v,i)
            local next=self:pathPoint(v,math.min(#v.path,i+.25));local direction=(next-pos).Magnitude>1e-3 and (next-pos).Unit or v.direction or Vector3.new(0,0,-1)
            v.shown=i;v.direction=direction;v.model:PivotTo(CFrame.lookAt(pos,pos+direction))
            require(script.Parent.CollectionArt).step(v.model,now,reduced,3)
            continue
        end
        if v.homing then if camera then self:missileSize(v,camera)end;self:home(v,now);continue end
        if v.grow then
            v.grow=math.min(1,v.grow+dt/.3);local u=v.grow-1;local e=1+2.4*u*u*u+1.4*u*u
            unrig(v);v.model:ScaleTo(v.baseScale*(.55+.45*e));if v.grow>=1 then v.grow=nil;v.model:ScaleTo(v.baseScale)end
        end
        if v.settled then continue end
        local t=math.clamp((now-v.at)/((self.span or .3)*1.1),0,1);local pos=v.from:Lerp(v.to,t);local direction=v.direction or Vector3.new(0,0,-1)
        if v.kind=='Train'then
            if v.railRoute then local facing;pos,facing=RailMotion.sample(v.railRoute,t);direction=facing or direction end
            local desired=CFrame.lookAt(pos,pos+direction)
            v.heading=(v.heading or desired):Lerp(desired,1-math.exp(-udt*12))
            local cf=CFrame.new(pos)*v.heading.Rotation;v.shownPos=pos
            if v.grow then v.model:PivotTo(cf)elseif self:visible(v,pos,t,view)then glide(v,cf,batch)end
        elseif ships[v.kind]then
            local desired=CFrame.lookAt(pos,pos+direction)
            v.heading=(v.heading or desired):Lerp(desired,1-math.exp(-udt*8))
            local cf=CFrame.new(pos)*v.heading.Rotation;v.shownPos=pos
            if v.grow then v.model:PivotTo(cf)elseif self:visible(v,pos,t,view)then glide(v,cf,batch)end
        elseif v.missile or v.grow then v.model:PivotTo(CFrame.lookAt(pos,pos+direction))
        else v.shownPos=pos;if self:visible(v,pos,t,view)then glide(v,CFrame.lookAt(pos,pos+direction),batch)end end
        if v.missile then require(script.Parent.CollectionArt).step(v.model,now,reduced,3)end
        if t>=1 and not(ships[v.kind]and v.heading and v.heading.LookVector:Dot(direction)<.999)then v.settled=true end
    end
    if not pcall(batch.flush,batch)then batch:clear()end
end
return M
