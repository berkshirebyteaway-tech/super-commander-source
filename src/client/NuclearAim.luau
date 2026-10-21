local UI=require(script.Parent.Theme)
local Aim=require(script.Parent.Parent.Core.NuclearAimModel)
local U=require(script.Parent.Parent.Core.UnitRules)
local G=require(script.Parent.Parent.Core.WorldGeometry)
local Commands=require(script.Parent.Parent.Core.CommandPresentation)
local Telemetry=require(script.Parent.TelemetryClient)
local Sketch=require(script.Parent.RailSketch)
local Rail=require(script.Parent.RailView)
local M={};M.__index=M
function M.new(parent,renderer,callbacks)
    local self=setmetatable({renderer=renderer,callbacks=callbacks,pool={},marks={},generation=0,up=true},M)
    self.overlay=UI.make('Frame',parent,{Name='StrategicRanges',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=6,ClipsDescendants=true})
    self.bar=UI.panel(parent,'NuclearAim');self.bar.ZIndex=22;self.bar.Visible=false;self.bar.BackgroundTransparency=.04
    self.title=UI.label(self.bar,'Title','',15,UI.colors.accent)
    self.hint=UI.label(self.bar,'Hint','',14,UI.colors.muted)
    self.fireButton=UI.button(self.bar,'Fire','목표를 고정하세요',function()self:fire()end,true)
    self.flipButton=UI.button(self.bar,'Flip','반전',function()if self.kind~='MIRV'then self.up=not self.up;require(script.Parent.TelemetryStep).step('match','nukeFlip',{kind=self.kind});self:recalculate(true)end end);self.flipButton.TextSize=12
    self.cancelButton=UI.button(self.bar,'Cancel','×',function()self:stop();callbacks.cancel()end)
    self.amountButton=UI.button(self.bar,'Amount','×1',function()self:cycleAmount()end);self.amountButton.TextSize=13
    return self
end
function M:start(kind)
    self:stop();self.kind=kind;self.up=true;self.amount=1;self.active=true;self.bar.Visible=true;self:status()
    self.telemetryAt=os.clock();self.telemetryFired=false;self.telemetryRisk=nil;Telemetry.emit('nuclear_aim_started',{kind=kind,stage='start'})
end
M.steps={1,2,5}
function M:maxAmount()return math.max(1,self.kind=='AtomBomb'and self.plan and self.plan.readyTotal or 1)end
function M:cycleAmount()
    local max=self:maxAmount();if max<=1 then self.amount=1;self:status();return end
    local slots={};for _,s in ipairs(M.steps)do if s<max then table.insert(slots,s)end end;table.insert(slots,max)
    local i=table.find(slots,self.amount);self.amount=slots[(i or 0)%#slots+1];self:status();require(script.Parent.TelemetryStep).step('match','nukeAmount',{kind=self.kind,value=self.amount})
end
function M:stop()
    if self.active then Telemetry.emit('nuclear_aim_ended',{kind=self.kind,reason=self.telemetryFired and 'completed'or 'cancelled',duration_ms=(os.clock()-(self.telemetryAt or os.clock()))*1000})end
    self.active=false;self.kind=nil;self.locked=nil;self.target=nil;self.plan=nil;self.checked=nil;self.checking=nil;self.pending=nil;self.pendingAt=nil;self.pendingRequest=nil;self.pendingVersion=nil;self.lockedSilo=nil;self.lockedStamp=nil;self.breakConfirm=nil;self.generation+=1;self.bar.Visible=false
end
function M:recalculate(check)
    if not self.active or not self.target or not self.state or not self.map then self:status();return end
    self.plan=Aim.plan(Aim.fromState(self.state,self.map,self.owners),1,self.kind,self.target,self.up)
    if check then
        self.generation+=1;local gen,kind,tile,up,version=self.generation,self.kind,self.target,self.up,self.state.version;self.checked=nil;self.checking=true
        task.delay(4,function()
            if gen~=self.generation or not self.active or not self.checking then return end
            self.generation+=1;self.checking=nil;self.checked=nil;self.locked=false;self:status()
            require(script.Parent.TelemetryStep).step('match','nukeCheck',{kind=kind,result='timeout'});self.callbacks.notify('경로 확인이 늦어졌어요. 목표를 다시 선택하세요.',true)
        end)
        task.spawn(function()
            task.wait(.1)
            if gen~=self.generation or not self.active then return end
            local ok,p=pcall(self.callbacks.preview,kind,tile,version,up)
            if gen~=self.generation or not self.active or self.state.version~=version then return end
            self.checking=nil
            if ok and p.path then
                self.plan=p
                if self.lockedSilo and (self.lockedSilo~=p.silo or self.lockedStamp~=p.relationStamp)then self.locked=false;self.checked=nil;self.callbacks.notify('경로가 바뀌었어요. 목표를 다시 고정하세요.')
                else self.checked=p.valid and {silo=p.silo,relationStamp=p.relationStamp}or nil;self.lockedSilo=p.silo;self.lockedStamp=p.relationStamp end
            else self.locked=false;self.checked=nil;require(script.Parent.TelemetryStep).step('match','nukeCheck',{kind=kind,result='failed'});self.callbacks.notify('목표 확인에 실패했어요. 다시 선택하세요.',true)end
            self:status()
        end)
    elseif self.checked and (self.checked.silo~=self.plan.silo or self.checked.relationStamp~=self.plan.relationStamp)then
        self.checked=nil;self.locked=false;self.callbacks.notify('경로가 바뀌었어요. 목표를 다시 고정하세요.')
    end
    self:status()
end
function M:hover(tile)
    if not self.active or self.pending or self.locked and require(script.Parent.InputMode).touch() or not tile or os.clock()-(self.lastHover or 0)<.05 then return end
    if not require(script.Parent.InputMode).touch() then self.locked=false;self.checked=nil end
    if self.target~=tile then self.target=tile;self.lastHover=os.clock();self:recalculate(false)end
end
function M:click(tile,secondary)
    if secondary then self:stop();self.callbacks.cancel();return end
    if not tile or not self.active or self.pending then return end
    if require(script.Parent.InputMode).touch()then self:lock(tile);return end
    self.target=tile;self.locked=false;self.checked=nil;self:recalculate(false)
    local p=self.plan
    if not p or not p.valid or self.state.paused then self:status();return end
    if #(p.breaks or {})>0 then
        local key=tostring(self.kind)..':'..tostring(tile)..':'..tostring(p.silo)..':'..tostring(p.relationStamp)
        if not self.breakConfirm or self.breakConfirm.key~=key or os.clock()>self.breakConfirm.untilTime then
            self.breakConfirm={key=key,untilTime=os.clock()+3};require(script.Parent.TelemetryStep).step('match','nukeBreakPrompt',{kind=self.kind,count=#p.breaks});self.callbacks.notify('동맹 파기. 같은 목표를 다시 클릭하면 발사해요.',true);return
        end
    end
    self.breakConfirm=nil;self.locked=true;self.checked={silo=p.silo,relationStamp=p.relationStamp};self:fire()
end
function M:lock(tile)
    if not self.active or not tile then return end
    self.target=tile;self.locked=true;self.lockedSilo=nil;self.lockedStamp=nil;self:recalculate(true)
end
function M:status()
    if not self.active then return end
    local risk=self.plan and self.plan.risk==true or false
    if self.telemetryRisk~=risk then self.telemetryRisk=risk;Telemetry.emit('nuclear_aim_warning_changed',{kind=self.kind,warning=risk,stage=risk and 'warning'or 'clear'})end
    local p=self.plan;self.title.Text=U.names[self.kind]..(p and ' '..UI.number(p.cost)..' 골드'or '')
    local touch=require(script.Parent.InputMode).touch()
    self.hint.Text=p and (p.silo and (p.reason and string.format('준비 %d발, %s',p.ready,p.reason)or string.format('준비 %d발',p.ready))or p.reason or '')or (touch and '지도를 눌러 목표를 고정하세요.' or '마우스로 조준, 클릭 발사, 우클릭 취소')
    self.hint.TextColor3=p and (p.risk or #(p.breaks or {})>0)and UI.colors.danger or UI.colors.muted
    self.fireButton.Text=self.pending and '발사 중…'or not touch and (p and p.valid and '클릭해서 발사'or '조준 중')or not self.locked and '목표를 고정하세요'or p and not p.valid and '발사 불가'or not self.checked and (self.checking and '경로 확인 중…'or '목표를 고정하세요')or p and #p.breaks>0 and '동맹 파기 후 발사'or '발사'
    local plain=self.fireButton.Text=='발사'
    local stack=self.kind=='AtomBomb'and self:maxAmount()>1;self.amount=math.min(self.amount or 1,self:maxAmount())
    self.amountButton.Visible=stack;self.amountButton.Text=self.amount>=self:maxAmount()and self.amount>1 and '최대'or '×'..self.amount
    if stack and self.amount>1 and plain then self.fireButton.Text=string.format('×%d 발사',self.amount)end
    if self.width then self:place()end
    self.fireButton.BackgroundColor3=p and #(p.breaks or {})>0 and UI.colors.danger or UI.colors.accent
    UI.enabled(self.fireButton,((not touch or self.locked==true and self.checked~=nil)and p and p.valid and not self.pending and not self.state.paused)==true)
    self.flipButton.Visible=self.kind~='MIRV';self.flipButton.BackgroundColor3=self.up and UI.colors.raised or UI.colors.accent;self.flipButton.TextColor3=self.up and UI.colors.ink or UI.colors.bg
end
function M:fire()
    if not require(script.Parent.InputMode).touch()and not self.checked then self:click(self.target);return end
    if not self.active or not self.locked or not self.checked or not self.plan.valid or self.pending or self.state.paused then return end
    self.pending=true;self.pendingAt=os.clock();self:status()
    self.pendingVersion=self.state.version
    self.pendingRequest=self.callbacks.send('nuclear',self.kind,{tile=self.target,silo=self.checked.silo,up=self.up,relationStamp=self.checked.relationStamp,amount=self.kind=='AtomBomb'and self.amount or nil})
    if not self.pendingRequest then self.pending=nil;self.pendingAt=nil;self.pendingVersion=nil;self:status()end
end
function M:result(r)
    if not Commands.acknowledges(self.pendingRequest,self.pendingVersion,r,'nuclear')then return end
    if r.ok then self.telemetryFired=true end
    self.pending=nil;self.pendingAt=nil;self.pendingRequest=nil;self.pendingVersion=nil
    if not self.active then return end
    self.checked=nil;self.lockedSilo=nil;self.lockedStamp=nil
    if require(script.Parent.InputMode).touch()then
        if r.ok then self:recalculate(true)else self.locked=false;self:status()end
    else self.locked=false;self:recalculate(false)end
end
function M:update(state,map,owners,action,preview,selected,hovered)
    self.drawRevision=(self.drawRevision or 0)+1
    if self.state and self.state.version~=state.version or state.phase~='playing'or state.eliminated then self:stop()end
    self.state=state;self.map=map;self.owners=owners;self.action=action;self.preview=preview;self.selected=selected;self.hovered=hovered
    if self.pendingAt and os.clock()-self.pendingAt>8 then self.pending=nil;self.pendingAt=nil;self.pendingRequest=nil;self.pendingVersion=nil;self.checked=nil;self.locked=false end
    if self.active then self:recalculate(false)end
end
function M:layout(w,h,dockY)
    self.mouseLayout=not require(script.Parent.InputMode).touch()
    if self.mouseLayout then
        local width=math.min(540,w-24)
        UI.box(self.bar,(w-width)/2,math.max(8,(dockY or h)-84),width,72)
        self.width=width;self:place();return
    end
    local compact=h<500;local width=math.min(compact and 342 or 412,w-24)
    UI.box(self.bar,(w-width)/2,compact and 8 or math.max(8,(dockY or h)-128),width,116)
    UI.box(self.title,12,4,width-24,24);self.title.TextSize=15
    UI.box(self.hint,12,28,width-24,34);self.hint.TextSize=14;self.hint.TextWrapped=true;self.hint.TextTruncate=Enum.TextTruncate.AtEnd
    self.width=width;self:place()
end
function M:place()
    self.fireButton.Visible=not self.mouseLayout
    if self.mouseLayout then
        local width=self.width;local extra=self.amountButton.Visible and 52 or 0
        UI.box(self.title,12,5,width-124-extra,24);self.title.TextSize=14
        UI.box(self.hint,12,28,width-124-extra,36);self.hint.TextSize=13;self.hint.TextWrapped=true;self.hint.TextTruncate=Enum.TextTruncate.AtEnd
        UI.box(self.amountButton,width-104-extra,14,44,44);UI.box(self.flipButton,width-104,14,44,44);UI.box(self.cancelButton,width-56,14,44,44);return
    end
    local width,y=self.width,68;local extra=self.amountButton.Visible and 56 or 0
    UI.box(self.fireButton,12,y,width-120-extra,44);UI.box(self.amountButton,width-104-extra,y,44,44);UI.box(self.flipButton,width-104,y,44,44);UI.box(self.cancelButton,width-56,y,44,44)
end
function M:point(x,y)
    local meta=self.map.meta;local p=workspace.CurrentCamera:WorldToScreenPoint(Vector3.new((x-meta.width/2)*G.scale,G.surfaceY+.2,(y-meta.height/2)*G.scale))
    if p.Z<=0 then return nil end
    return (Vector2.new(p.X,p.Y)-self.overlay.AbsolutePosition)/UI.scale
end
function M:tilePoint(t)return self:point(t%self.map.meta.width,math.floor(t/self.map.meta.width))end
function M:line(a,b,color,thickness,dashed,extend,transparency)
    if not a or not b then return end;local d=b-a;if d.Magnitude>4000 or d.Magnitude<.1 then return end
    self.used+=1;local o=self.pool[self.used]
    if not o then o=UI.make('Frame',self.overlay,{Name='Line'..self.used,BorderSizePixel=0,AnchorPoint=Vector2.new(.5,.5),ZIndex=6});self.pool[self.used]=o end
    o.Visible=true;o.BackgroundColor3=color;o.BackgroundTransparency=transparency or dashed and .55 or .12;o.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2);o.Size=UDim2.fromOffset(d.Magnitude+(extend or 0),thickness or 1);o.Rotation=math.deg(math.atan2(d.Y,d.X))
end
function M:ring(tile,radius,color,dashed,thickness)
    local x,y=tile%self.map.meta.width,math.floor(tile/self.map.meta.width);local prior=self:point(x+radius,y)
    for i=1,40 do local a=i*math.pi/20;local p=self:point(x+math.cos(a)*radius,y+math.sin(a)*radius)
        if not dashed or i%2==0 then self:line(prior,p,color,thickness or 1.4,dashed)end;prior=p
    end
end
function M:disc(tile,radius,color)
    local d=self.discPart
    if not d then
        d=Instance.new('Part');d.Name='SamPlacementCover';d.Shape=Enum.PartType.Cylinder;d.Anchored=true;d.CanCollide=false;d.CanQuery=false;d.CanTouch=false;d.CastShadow=false
        d.Material=Enum.Material.SmoothPlastic;self.discPart=d
    end
    local meta=self.map.meta;local x,y,z=G.toWorld(tile,meta.width,meta.height);local size=radius*2*G.scale
    d.Size=Vector3.new(.04,size,size);d.CFrame=CFrame.new(x,y+.09,z)*CFrame.Angles(0,0,math.pi/2);d.Color=color;d.Transparency=.8
    d.Parent=self.renderer.folder;self.discUsed=true
end
function M:railEnd(tile,structure)
    if structure then return structure~='Port' end
    local w=self.map.meta.width;local x,y=tile%w,tile//w;local r=Rail.STATION_REACH
    for _,u in ipairs(self.state and self.state.units or {})do if u.kind=='City'or u.kind=='Factory'then
        if math.abs(u.tile%w-x)<=r and math.abs(u.tile//w-y)<=r then return true end
    end end
    return false
end
function M:railLine(tiles,color,transparency,structure)
    local world=self.renderer;local span=world.liveW or world.view.w
    local perTile=self.overlay.AbsoluteSize.X/UI.scale/math.max(span,1);local width=math.clamp(perTile,1,3)
    local pts=Sketch.trim(Sketch.points(tiles,self.map.meta.width),self:railEnd(tiles[1],structure)and Rail.LOT_RADIUS or 0,self:railEnd(tiles[#tiles])and Rail.LOT_RADIUS or 0)
    if not pts then return end
    local prior=self:point(pts[1].X,pts[1].Y)
    for i=2,#pts do local at=self:point(pts[i].X,pts[i].Y);self:line(prior,at,color,width,false,width,transparency);prior=at end
end
function M:railHint(kind,r)
    if not(kind=='City'or kind=='Port'or kind=='Factory')or not r.tile then return end
    self.lastRails=r.valid and (r.rails or r.railSnap)and {action=kind,tile=r.tile,rails=r.rails,snap=r.railSnap}or nil
    self.drawRevision=(self.drawRevision or 0)+1
end
function M:previewRails(p)
    if not p or not p.tile or not(self.action=='City'or self.action=='Port'or self.action=='Factory')then self.lastRails=nil;return nil end
    if not p.guess then
        self.lastRails=p.valid and (p.rails or p.railSnap)and {action=self.action,tile=p.tile,rails=p.rails,snap=p.railSnap}or nil
        if not p.valid then return nil end
        return p.rails,p.railSnap
    end
    local last=self.lastRails;if not last or last.action~=self.action or p.valid==false then return nil end
    local w=self.map.meta.width;local dx,dy=p.tile%w-last.tile%w,math.floor(p.tile/w)-math.floor(last.tile/w)
    if dx*dx+dy*dy>144 then return nil end
    return last.rails,last.snap
end
function M:mark(tile,value,color)
    local p=self:tilePoint(tile);if not p then return end;self.markUsed+=1;local o=self.marks[self.markUsed]
    if not o then o=UI.label(self.overlay,'Mark'..self.markUsed,'',20);o.TextXAlignment=Enum.TextXAlignment.Center;o.AnchorPoint=Vector2.new(.5,.5);o.TextStrokeTransparency=.3;o.TextStrokeColor3=UI.colors.bg;o.ZIndex=7;self.marks[self.markUsed]=o end
    o.Visible=true;o.Text=value;o.TextColor3=color;UI.box(o,p.X,p.Y,30,30)
end
function M:rangeSeen(kind)
    if not self.state then return end
    if self.telemetryRangeVersion~=self.state.version then self.telemetryRangeVersion=self.state.version;self.telemetryRanges={}end
    if not self.telemetryRanges[kind]then self.telemetryRanges[kind]=true;Telemetry.emit('structure_range_viewed',{kind=kind,stage='shown'})end
end
function M:draw()
    if not self.active and (self.action=='SAMLauncher'or self.action=='DefensePost')then self:rangeSeen(self.action)end
    local camera=workspace.CurrentCamera;local cf=camera.CFrame;local fov=camera.FieldOfView
    local size,origin=self.overlay.AbsoluteSize,self.overlay.AbsolutePosition
    local c=self.drawCache;local selected=self.selected and self.selected.id;local preview=self.preview and self.preview.tile
    if c and c.camera==camera and c.cf==cf and c.fov==fov and c.viewport==camera.ViewportSize and c.size==size and c.origin==origin and c.scale==UI.scale
        and c.revision==self.drawRevision and c.state==self.state and c.tick==(self.state and self.state.tick)and c.map==self.map and c.plan==self.plan and c.active==self.active and c.locked==self.locked
        and c.action==self.action and c.selected==selected and c.preview==preview and c.previewObj==self.preview and c.hovered==self.hovered and c.generation==self.generation then return end
    self.drawCache={camera=camera,cf=cf,fov=fov,viewport=camera.ViewportSize,size=size,origin=origin,scale=UI.scale,revision=self.drawRevision,state=self.state,tick=self.state and self.state.tick,map=self.map,plan=self.plan,
        active=self.active,locked=self.locked,action=self.action,selected=selected,preview=preview,previewObj=self.preview,hovered=self.hovered,generation=self.generation}
    self.used=0;self.markUsed=0;self.discUsed=false
    if self.map and self.state and self.state.phase~='menu'then
        if self.active and self.plan then
            local p=self.plan;for _,sam in ipairs(p.sams)do self:ring(sam.tile,sam.range,UI.colors.danger,sam.building);if sam.intercept then self:mark(sam.intercept,'×',UI.colors.danger)end end
            local path=p.path;local stride=math.max(1,math.ceil(#path/100));local prior=path[1]
            for i=1+stride,#path,stride do local at=path[i];self:line(self:tilePoint(prior),self:tilePoint(at),UI.colors.accent,2);prior=at end
            if prior and path[#path]and prior~=path[#path]then self:line(self:tilePoint(prior),self:tilePoint(path[#path]),UI.colors.accent,2)end
            if p.outer then self:ring(p.target,p.outer,UI.colors.danger,true);self:ring(p.target,p.inner,UI.colors.accent,false)end
            if p.source then self:mark(p.source,'▲',UI.colors.accent)end
            if p.separation then self:mark(p.separation,'◇',UI.colors.ink)end
            self:mark(p.target,self.locked and '⊕'or '+',p.valid and UI.colors.accent or UI.colors.danger)
        else
            local build=self.action=='SAMLauncher'or self.action=='MissileSilo'or self.action=='City'
            for _,u in ipairs(self.state.units or {})do if u.kind=='SAMLauncher'and (build or self.selected and self.selected.id==u.id or self.hovered==u.id)then
                self:rangeSeen('SAMLauncher')
                local friendly=u.owner==1;for _,f in ipairs(self.state.factions or {})do if f.id==u.owner then friendly=f.allied or friendly;break end end
                self:ring(u.tile,u.building and U.samRange(u.level)or U.dynamicSamRange(u,self.state.tick),friendly and UI.colors.accent or UI.colors.danger,u.building)
            end end
            if self.action=='SAMLauncher'and self.preview and self.preview.tile then
                local p=self.preview;local radius=U.samRange(p.upgrade and (p.level or 1)+1 or 1);local color=p.valid==false and UI.colors.danger or UI.colors.accent
                self:disc(p.tile,radius,color);self:ring(p.tile,radius,color,false,2.6)
            end
            if U.structures[self.action]and self.preview and self.preview.tile and self.map then
                local w=self.map.meta.width;local px,py=self.preview.tile%w,self.preview.tile//w;local near={}
                for _,u in ipairs(self.state.units or {})do if U.structures[u.kind]and u.active~=false then
                    local dx,dy=u.tile%w-px,u.tile//w-py;local d=dx*dx+dy*dy;if d<1600 then table.insert(near,{u.tile,d})end
                end end
                table.sort(near,function(a,b)return a[2]<b[2]end)
                for i=1,math.min(6,#near)do self:ring(near[i][1],15,UI.colors.muted,true,1)end
            end
            local rails,snap=self:previewRails(self.preview)
            for _,tiles in ipairs(snap or {})do self:railLine(tiles,Color3.fromRGB(51,217,77),.24)end
            for _,tiles in ipairs(rails or {})do self:railLine(tiles,Rail.MINE,1-(1-.24)*.6,self.action)end
            local defense=self.action=='DefensePost'
            for _,u in ipairs(self.state.units or {})do
                if u.kind=='DefensePost'and (defense or self.selected and self.selected.id==u.id or self.hovered==u.id)then
                    self:rangeSeen('DefensePost')
                    local friendly=u.owner==1
                    for _,f in ipairs(self.state.factions or {})do if f.id==u.owner then friendly=friendly or f.allied or f.teammate;break end end
                    if not defense or friendly then self:ring(u.tile,require(script.Parent.Parent.Core.ConfigConstants).defensePostRange,friendly and UI.colors.accent or UI.colors.danger,u.building)end
                end
            end
            if defense and self.preview and self.preview.tile then self:ring(self.preview.tile,require(script.Parent.Parent.Core.ConfigConstants).defensePostRange,UI.colors.ink,true)end
        end
    end
    for i=self.used+1,#self.pool do self.pool[i].Visible=false end;for i=self.markUsed+1,#self.marks do self.marks[i].Visible=false end
    if self.discPart and not self.discUsed then self.discPart.Parent=nil end
end
return M
