local UI=require(script.Parent.Theme)
local Icons=require(script.Parent.UIIcons)
local Rules=require(script.Parent.Parent.Core.FrontlineLabels)
local Display=require(script.Parent.Parent.Core.MapPresentation)
local M={};M.__index=M
local outgoing,incoming=Color3.fromRGB(54,226,208),Color3.fromRGB(255,82,82)
function M.new(layer,renderer)
    return setmetatable({layer=layer,renderer=renderer,slots={},pool={},entries={},previous={}},M)
end
function M:update(state)
    if self.version~=state.version then self.version=state.version;self.slots={};self.previous={}end
    self.hidden=state.phase~='playing'
    local operations={};local current={};local width=self.renderer.map and self.renderer.map.meta.width
    for _,op in ipairs(state.operations or {})do
        local item=table.clone(op);local key=tostring(op.owner)..':'..tostring(op.id)..':'..op.direction
        if width and op.frontTiles then item.frontTiles=Rules.align(op.frontTiles,self.previous[key]or {},width);current[key]=item.frontTiles end
        table.insert(operations,item)
    end
    if state.factions then local kinds={};for _,f in ipairs(state.factions)do kinds[f.id]=f.kind end;self.kinds=kinds end
    self.previous=current;self.entries=Rules.entries(operations,self.kinds)
    local now=os.clock();local live={}
    for _,e in ipairs(self.entries)do
        live[e.key]=true
        local width=self.renderer.map and self.renderer.map.meta.width
        if width then
            local x,y=e.tile%width,math.floor(e.tile/width)
            self.slots[e.key]=Rules.move(self.slots[e.key],x,y,now)
        end
    end
    for key in pairs(self.slots)do if not live[key]then self.slots[key]=nil end end
end
function M:badge(i)
    if self.pool[i]then return self.pool[i]end
    local f=UI.make('Frame',self.layer,{Name='FrontTroops'..i,Size=UDim2.fromOffset(64,22),AnchorPoint=Vector2.new(.5,1),BackgroundColor3=UI.colors.bg,BackgroundTransparency=.22,BorderSizePixel=0,Active=false,ZIndex=15})
    UI.corner(f,3);local stroke=UI.stroke(f,outgoing,1)
    local icon=Icons.create(f,'troops',14);UI.box(icon,6,4,14,14)
    local amount=UI.label(f,'Amount','',14);UI.box(amount,23,0,30,22);amount.Font=Enum.Font.BuilderSansBold;amount.TextWrapped=false;amount:SetAttribute('LocalizationSkip',true)
    local direction=UI.label(f,'Direction','',14);UI.box(direction,53,0,11,22);direction.TextXAlignment=Enum.TextXAlignment.Center;direction:SetAttribute('LocalizationSkip',true)
    local link=UI.make('Frame',self.layer,{Name='FrontLink'..i,BackgroundTransparency=.35,BorderSizePixel=0,AnchorPoint=Vector2.new(.5,.5),ZIndex=14,Active=false})
    local dot=UI.make('Frame',self.layer,{Name='FrontPoint'..i,Size=UDim2.fromOffset(4,4),AnchorPoint=Vector2.new(.5,.5),BorderSizePixel=0,ZIndex=14,Active=false});UI.corner(dot,2)
    local zoom=UI.make('UIScale',f,{Name='ZoomScale',Scale=1})
    local b={frame=f,stroke=stroke,icon=icon,amount=amount,direction=direction,link=link,dot=dot,zoom=zoom};self.pool[i]=b;return b
end
function M.fit(b)
    local tw=math.ceil(game:GetService('TextService'):GetTextSize(b.amount.Text,14,Enum.Font.BuilderSansBold,Vector2.new(200,22)).X)
    UI.box(b.amount,23,0,tw,22);UI.box(b.direction,25+tw,0,11,22);b.frame.Size=UDim2.fromOffset(42+tw,22)
end
local function put(b,key,o,prop,value) if b[key]~=value then b[key]=value;o[prop]=value end end
function M.zoomScale(span)
    local s=math.clamp((180/math.max(span or 180,1))^.35,.75,1)
    return math.floor(s*50+.5)/50
end
function M:step(w,h,hidden,blocks)
    local count=0
    if not(self.hidden or hidden)then
    local occupied=Display.occupancy(48)
    local now=os.clock()
    local zoom=M.zoomScale(self.renderer.liveW or self.renderer.view and self.renderer.view.w)
    for _,e in ipairs(self.entries)do
        if count>=96 then break end
        local slot=self.slots[e.key];local p
        if slot and self.renderer.projectXY then local x,y=Rules.position(slot,now);p=self.renderer:projectXY(x,y,.25)
        else p=self.renderer:project(e.tile,.25)end
        local bounds=self.renderer.annotationBounds or {left=0,top=0,right=w,bottom=h}
        if p.X<bounds.left or p.Y<bounds.top or p.X>bounds.right or p.Y>bounds.bottom then continue end
        local x,y=Rules.place(p.X-bounds.left,p.Y-bounds.top,bounds.right-bounds.left,bounds.bottom-bounds.top,{},occupied)
        if not y then continue end
        x+=bounds.left;y+=bounds.top
        count+=1;local b=self:badge(count);local color=e.incoming and incoming or outgoing
        put(b,'_shown',b.frame,'Visible',true);put(b,'_pos',b.frame,'Position',UDim2.fromOffset(x,y));put(b,'_zoom',b.zoom,'Scale',zoom)
        if b._color~=color then b._color=color;b.stroke.Color=color;b.icon.ImageColor3=color;b.amount.TextColor3=color;b.direction.TextColor3=color;b.link.BackgroundColor3=color;b.dot.BackgroundColor3=color end
        if b._troops~=e.troops then b._troops=e.troops;b.amount.Text=UI.troops(e.troops);b.frame:SetAttribute('Troops',e.troops);M.fit(b)end
        if b._incoming~=e.incoming then b._incoming=e.incoming;b.direction.Text=e.incoming and '↓'or '↑';b.frame:SetAttribute('Direction',e.incoming and 'incoming'or 'outgoing')end
        if b._id~=e.id then b._id=e.id;b.frame:SetAttribute('AttackId',e.id)end
        if b._tile~=e.tile then b._tile=e.tile;b.frame:SetAttribute('FrontTile',e.tile)end
        local endpoint=Vector2.new(x,math.clamp(p.Y,y-28,y));local delta=endpoint-p
        local linked=delta.Magnitude>32
        put(b,'_link',b.link,'Visible',linked);put(b,'_dot',b.dot,'Visible',linked)
        if linked then
            b.link.Position=UDim2.fromOffset((endpoint.X+p.X)/2,(endpoint.Y+p.Y)/2);b.link.Size=UDim2.fromOffset(delta.Magnitude,1);b.link.Rotation=math.deg(math.atan2(delta.Y,delta.X))
            b.dot.Position=UDim2.fromOffset(p.X,p.Y)
        end
    end
    end
    for i=count+1,#self.pool do local b=self.pool[i];put(b,'_shown',b.frame,'Visible',false);put(b,'_link',b.link,'Visible',false);put(b,'_dot',b.dot,'Visible',false)end
    if self._count~=count then self._count=count;self.layer:SetAttribute('FrontTroopLabels',count)end
end
return M
