local UI=require(script.Parent.Theme)
local Geometry=require(script.Parent.RailGeometry)
local G=require(script.Parent.Parent.Core.WorldGeometry)
local FactionColors=require(script.Parent.FactionColors)
local M={};M.__index=M
local steel=Color3.fromRGB(151,166,179);local sleeper=Color3.fromRGB(48,56,65)
M.RAIL_MIN_ZOOM=3;M.RAIL_FADE_RANGE=2
function M.fade(pixelsPerTile)
    local start=M.RAIL_MIN_ZOOM-M.RAIL_FADE_RANGE
    return math.floor(math.clamp((pixelsPerTile-start)/M.RAIL_FADE_RANGE,0,1)*10+.5)/10
end
function M.new(world)
    local root=UI.make('Frame',world.parent,{Name='RailNetwork',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ClipsDescendants=true,ZIndex=1})
    return setmetatable({world=world,root=root,pool={},details={},segments={},graph={},geometry={},detailSelection={},lines={},visibleCount=0},M)
end
M.LOT_RADIUS=4.6;M.STATION_REACH=2
M.DETAIL=false;M.MINE=Color3.fromRGB(240,244,248);M.UNOWNED=Color3.fromRGB(150,156,163)
local structures={City=true,Factory=true}
function M:stations(state)
    local n,sum=0,0
    for _,u in ipairs(state.units or {})do if structures[u.kind]then n+=1;sum+=u.id end end
    if self.stationKey==n..':'..sum then return end
    self.stationKey=n..':'..sum;self.trims={};self.camera=nil
    local w=self.world.map and self.world.map.meta.width or 1;local grid={}
    for _,u in ipairs(state.units or {})do if structures[u.kind]then
        local x,y=u.tile%w,math.floor(u.tile/w);local key=math.floor(x/8)*65536+math.floor(y/8)
        local list=grid[key];if not list then list={};grid[key]=list end;table.insert(list,{x,y})
    end end
    self.stationGrid=grid
end
function M:trimmed(tile)
    local v=self.trims and self.trims[tile];if v~=nil then return v end
    local w=self.world.map.meta.width;local x,y=tile%w,math.floor(tile/w);local r=M.STATION_REACH;v=false
    for cx=math.floor((x-r)/8),math.floor((x+r)/8)do for cy=math.floor((y-r)/8),math.floor((y+r)/8)do
        for _,p in ipairs(self.stationGrid and self.stationGrid[cx*65536+cy]or {})do
            if math.abs(p[1]-x)<=r and math.abs(p[2]-y)<=r then v=true end
        end
    end end
    if self.trims then self.trims[tile]=v end;return v
end
function M:update(state)
    if self.world.map then self:stations(state)end
    local kinds=self.kinds or {};self.kinds=kinds;for _,f in ipairs(state.factions or {})do kinds[f.id]=f.kind end
    if self.version==state.version and self.revision==state.railRevision then return end
    self.version=state.version;self.revision=state.railRevision
    local rails=state.rails;local slice={deadline=0}
    self.job={slice=slice,co=coroutine.create(function()return Geometry.index(rails,slice)end)}
end
M.SLICE=.002
function M:pump()
    local job=self.job;if not job then return end
    local Probe=require(script.Parent.FrameProbe);Probe.start('Units.railIndex')
    job.slice.deadline=os.clock()+M.SLICE
    local ok,graph,segments=coroutine.resume(job.co)
    Probe.stop('Units.railIndex')
    if not ok then self.job=nil;warn('RailView index: '..tostring(graph));return end
    if coroutine.status(job.co)~='dead'then return end
    self.job=nil;self.graph,self.segments=graph,segments;self.camera=nil
    table.clear(self.geometry);self.detailSelection=nil
end
function M:between(a,b)return Geometry.between(self.graph,a,b)end
function M:reset()
    self.shades=nil;self.kinds=nil;self.job=nil
    self.version=nil;self.revision=nil;self.camera=nil;table.clear(self.segments);table.clear(self.graph);table.clear(self.geometry);self.detailSelection=nil
    for i,p in ipairs(self.pool)do p.Visible=false;if self.lines[i]then self.lines[i].visible=false end end;self.visibleCount=0
    for _,p in ipairs(self.details)do p:Destroy()end;table.clear(self.details)
end
function M:detail(index,name,size,cf,color,metal)
    local p=self.details[index]
    if not p then
        p=Instance.new('Part');p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
        p.Parent=self.world.folder;self.details[index]=p
    end
    p.Name=name;p.Transparency=0;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=metal and Enum.Material.Metal or Enum.Material.SmoothPlastic
    self.detailWrites=(self.detailWrites or 0)+1
end
function M:segmentGeometry(index)
    local data=self.geometry[index];if data then return data end
    local s=self.segments[index];local meta=self.world.map.meta
    local ax,ay,az=G.toWorld(s[1],meta.width,meta.height);local bx,by,bz=G.toWorld(s[2],meta.width,meta.height)
    local first,last=Vector3.new(ax,ay+.10,az),Vector3.new(bx,by+.10,bz)
    local length=(last-first).Magnitude
    data={length=length,cf=length>.001 and CFrame.lookAt((first+last)/2,last)or CFrame.new(first),ties=math.max(1,math.floor(length/.55))}
    self.geometry[index]=data;return data
end
function M:refreshDetails(selection)
    local previous=self.detailSelection
    local same=previous and #selection==#previous
    if same then for i,v in ipairs(selection)do if previous[i]~=v then same=false;break end end end
    if same then return end
    self.detailSelection=selection
    local count,ties=0,0
    for _,index in ipairs(selection)do
        local data=self:segmentGeometry(index);local length,cf=data.length,data.cf
        if length>.001 then
            for _,x in ipairs({-.15,.15})do
                count+=1;self:detail(count,'RailSteel',Vector3.new(.045,.045,length),cf*CFrame.new(x,0,0),steel,true)
            end
            for i=0,data.ties-1 do
                if ties>=160 then break end
                ties+=1;count+=1
                self:detail(count,'RailSleeper',Vector3.new(.46,.035,.10),cf*CFrame.new(0,-.035,(i+.5)/data.ties*length-length/2),sleeper,false)
            end
        end
    end
    for i=count+1,#self.details do self.details[i].Transparency=1 end
end
function M:tint(s)
    local owners=self.world.playback and self.world.playback.owners or self.world.owners or {};local mapW=self.world.map.meta.width
    local a,b=s[1],s[2];local mid=math.floor((a//mapW+b//mapW)/2)*mapW+math.floor((a%mapW+b%mapW)/2)
    local o=owners[mid]or 0
    if o==1 then return M.MINE end
    if o==0 then return M.UNOWNED end
    local shades=self.shades or {};self.shades=shades
    local c=shades[o];if not c then c=FactionColors.get(o,(self.kinds or {})[o]):Lerp(Color3.new(0,0,0),.25);shades[o]=c end
    return c
end
function M:step()
    self:pump()
    local camera=workspace.CurrentCamera
    if not camera or not self.world.map then return end
    local size=self.root.AbsoluteSize/UI.scale;local origin=self.root.AbsolutePosition
    local span=self.world.liveW or self.world.view.w
    local near=M.DETAIL and span<=240
    local fade=M.fade(size.X/math.max(span,1))
    if self.camera==camera.CFrame and self.size==size and self.fov==camera.FieldOfView and self.viewport==camera.ViewportSize and self.origin==origin and self.scale==UI.scale and self.near==near and self.fade==fade then
        local owned=self.world.lastRevision
        if owned~=self.owned and os.clock()-(self.tintAt or 0)>=1 then
            self.owned=owned;self.tintAt=os.clock()
            for i=1,self.visibleCount do local line=self.lines[i];local c=line.seg and self:tint(self.segments[line.seg]);if c and line.color~=c then self.pool[i].BackgroundColor3=c;line.color=c end end
        end
        return
    end
    self.camera=camera.CFrame;self.size=size;self.fov=camera.FieldOfView;self.viewport=camera.ViewportSize;self.origin=origin;self.scale=UI.scale;self.near=near;self.fade=fade;self.owned=self.world.lastRevision;self.tintAt=os.clock()
    local width=math.clamp(size.X/math.max(span,1),1,3)

    self.root.Visible=fade>0
    if fade<=0 then
        for i=1,self.visibleCount do self.pool[i].Visible=false;self.lines[i].visible=false end;self.visibleCount=0
        self:refreshDetails({});return
    end
    local count=0;local selected={};local projected={};local lot=M.LOT_RADIUS*size.X/math.max(span,1)
    local function project(tile)
        local point=projected[tile]
        if not point then point=self.world:project(tile,.18,true);projected[tile]=point end
        return point
    end
    for index,s in ipairs(self.segments)do
        local a,b=project(s[1]),project(s[2])
        if math.max(a.X,b.X)<0 or math.min(a.X,b.X)>size.X or math.max(a.Y,b.Y)<0 or math.min(a.Y,b.Y)>size.Y then continue end
        local d=b-a;if d.Magnitude<.4 or d.Magnitude>5000 then continue end
        local cutA,cutB=self:trimmed(s[1])and lot or 0,self:trimmed(s[2])and lot or 0
        if cutA+cutB>0 then
            if cutA+cutB>=d.Magnitude-.4 then continue end
            local u=d.Unit;a,b=a+u*cutA,b-u*cutB;d=b-a
        end
        count+=1;local p=self.pool[count]
        if not p then p=UI.make('Frame',self.root,{Name='Rail',BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(183,198,210),BackgroundTransparency=.24,AnchorPoint=Vector2.new(.5,.5),ZIndex=1});self.pool[count]=p end
        local line=self.lines[count];if not line then line={};self.lines[count]=line end
        local position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2);local length=d.Magnitude;local rotation=math.deg(math.atan2(d.Y,d.X))
        if not line.visible then p.Visible=true;line.visible=true end
        if line.position~=position then p.Position=position;line.position=position end
        if not line.length or math.abs(line.length-length)>.0001 or line.width~=width then p.Size=UDim2.fromOffset(length,width);line.length=length;line.width=width end
        line.seg=index;local color=self:tint(s);if line.color~=color then p.BackgroundColor3=color;line.color=color end
        if not line.rotation or math.abs(line.rotation-rotation)>.00001 then p.Rotation=rotation;line.rotation=rotation end
        if line.near~=near or line.fade~=fade then p.BackgroundTransparency=1-(1-(near and .72 or .24))*fade;line.near=near;line.fade=fade end
        if near and #selected<64 then table.insert(selected,index)end
        if count>=1600 then break end
    end
    for i=count+1,self.visibleCount do self.pool[i].Visible=false;self.lines[i].visible=false end;self.visibleCount=count
    self:refreshDetails(selected)
end
return M
