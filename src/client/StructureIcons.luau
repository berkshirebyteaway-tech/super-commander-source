local UI=require(script.Parent.Theme)
local Colors=require(script.Parent.FactionColors)
local Pixels=require(script.Parent.StructureGlyphPixels)
local Display=require(script.Parent.Parent.Core.MapPresentation)
local NativeGlyph=require(script.Parent.StructureGlyph)
local Skin=require(script.Parent.SkinMapStyle)
local SkinArt=require(script.Parent.SkinMapArt)
local Looks=require(script.Parent.CosmeticLoadouts)
local Catalog=require(script.Parent.Parent.Core.CosmeticCatalog)
local M={};M.__index=M
M.priority={MissileSilo=6,SAMLauncher=5,Port=4,City=3,Factory=2,DefensePost=1}
M.letters={MissileSilo="M",SAMLauncher="A",Port="P",City="C",Factory="F",DefensePost="D"}
M.roofHeight={City=5.0,DefensePost=3.6,Port=4.5,Factory=2.7,MissileSilo=4.9,SAMLauncher=3.9}
for k,v in pairs(M.roofHeight)do M.roofHeight[k]=v*.88 end
M.lotTiles=10.5;M.tacticalPixels=48;M.chipPixels=32
M.sizeScale=1.44;M.dotsZoom=1.2;M.limit=320
M.restyleBudget=.002
local amber=Color3.fromRGB(255,82,82)
local warned={}
local images={}
local function glyph(kind)
    if images[kind]==nil then
        local ok,img=pcall(function()
            local hex=Pixels[kind];if not hex then return nil end
            local image=game:GetService("AssetService"):CreateEditableImage({Size=Vector2.new(48,48)})
            if not image then return nil end
            local pixels=buffer.create(48*48*4)
            for i=0,48*48-1 do buffer.writeu32(pixels,i*4,tonumber(string.sub(hex,i*8+1,i*8+8),16))end
            image:WritePixelsBuffer(Vector2.zero,Vector2.new(48,48),pixels);return image
        end)
        images[kind]=ok and img or false
    end
    return images[kind]
end
M.shapes={City={0,0,1},Port={5,math.pi/2,1.08},Factory={6,math.pi/6,1.08},DefensePost={8,0,1},SAMLauncher={4,0,1.4},MissileSilo={3,math.pi/2,1.55}}
M.shapeBox=1.55
M.skinSlot=function(kind)return kind=="City"and"city"or"defensePost"end
M.skinLift={};for kind,spec in pairs(M.shapes)do M.skinLift[kind]=.45*spec[3]*SkinArt.top(spec[1],spec[2])end
M.skinHz=30
local shapes={}
local function shape(kind)
    if shapes[kind]==nil then
        local ok,set=pcall(function()
            local spec=M.shapes[kind];if not spec then return nil end
            local n,rot,scale=spec[1],spec[2],spec[3]
            local N=64;local R=N*.45*scale/M.shapeBox;local an=n>0 and math.pi/n or 0
            local assets=game:GetService("AssetService")
            local function paint(alpha)
                local image=assets:CreateEditableImage({Size=Vector2.new(N,N)})
                if not image then error("no image")end
                local pixels=buffer.create(N*N*4)
                for y=0,N-1 do for x=0,N-1 do
                    local px,py=x+.5-N/2,y+.5-N/2;local r=math.sqrt(px*px+py*py);local d
                    if n==0 then d=r-R else
                        local a=math.atan2(py,px)-rot;a=(a+an)%(2*an)-an
                        d=r*math.cos(a)-R*math.cos(an)
                    end
                    local o=(y*N+x)*4
                    buffer.writeu8(pixels,o,255);buffer.writeu8(pixels,o+1,255);buffer.writeu8(pixels,o+2,255)
                    buffer.writeu8(pixels,o+3,math.floor(math.clamp(alpha(d),0,1)*255+.5))
                end end
                image:WritePixelsBuffer(Vector2.zero,Vector2.new(N,N),pixels);return image
            end
            local function ring(width)return function(d)return math.clamp(.5-d,0,1)*math.clamp(d+width+.5,0,1)end end
            return {fill=paint(function(d)return .5-d end),edge=paint(ring(3)),threat=paint(ring(5))}
        end)
        shapes[kind]=ok and set or false
    end
    return shapes[kind]
end
function M.band(span)
    return Display.band(span)
end
function M.new(layer)
    local root=UI.make("Frame",layer,{Name="StructureIcons",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=1})
    return setmetatable({root=root,pool={},used=0},M)
end
function M:badge(i)
    local b=self.pool[i]
    if b then return b end
    local f=UI.make("Frame",self.root,{Name="Structure"..i,AnchorPoint=Vector2.new(.5,.5),BorderSizePixel=0,ZIndex=1})
    UI.corner(f,3);local stroke=UI.stroke(f,UI.colors.bg,1)
    local shadow=UI.make("ImageLabel",f,{Name="GlyphShadow",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,1,.5,1),Size=UDim2.fromScale(.74,.74),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,ImageColor3=UI.colors.bg,ZIndex=2,Visible=false})
    local icon=UI.make("ImageLabel",f,{Name="Glyph",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.74,.74),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,ZIndex=3})
    local letter=UI.make("TextLabel",f,{Name="Letter",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,TextSize=11,Visible=false,ZIndex=2,AutoLocalize=false})
    UI.display(letter,true);letter:SetAttribute("LocalizationSkip",true)
    local level=UI.make("TextLabel",f,{Name="Level",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,0),Size=UDim2.fromOffset(24,16),BackgroundTransparency=1,TextColor3=Color3.new(1,1,1),TextStrokeColor3=Color3.fromRGB(8,12,18),TextStrokeTransparency=0,TextSize=14,ZIndex=5,Visible=false,AutoLocalize=false})
    UI.display(level,true);level:SetAttribute("LocalizationSkip",true)
    local native=UI.make('Frame',f,{Name='NativeGlyph',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.78,.78),BackgroundTransparency=1,ZIndex=2,Visible=false})
    local outline=UI.make('ImageLabel',f,{Name='Shape',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(M.shapeBox,M.shapeBox),BackgroundTransparency=1,ZIndex=1,Visible=false})
    local edge=UI.make('ImageLabel',outline,{Name='Edge',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=2})
    local track=UI.make('Frame',f,{Name='StatusTrack',Position=UDim2.new(0,0,1,2),Size=UDim2.new(1,0,0,3),BorderSizePixel=0,BackgroundColor3=UI.colors.bg})
    local fill=UI.make('Frame',track,{Name='StatusFill',Size=UDim2.fromScale(1,1),BorderSizePixel=0,BackgroundColor3=UI.colors.gold})
    local skin=Skin.attach({front=outline,back=f,top=f,box=M.shapeBox,frontZ=1,backZ=0,topZ=4})
    b={frame=f,stroke=stroke,icon=icon,shadow=shadow,letter=letter,level=level,native=native,track=track,fill=fill,shape=outline,edge=edge,skin=skin,phase=(i*.6180339)%1*6};self.pool[i]=b;return b
end
function M:animate(renderer)
    local now=os.clock()
    if self.skinAt and now-self.skinAt<1/M.skinHz then return end
    self.skinAt=now
    local reduced=renderer and renderer.reducedEffects==true
    for _,i in ipairs(self.drawnSlots or {})do local b=self.pool[i];if b and b.skin.animated then Skin.step(b.skin,now,reduced,b.phase)end end
end
function M:update(state,renderer,size,factionKinds,ownColor,hidden,selected)
    local tick=state and state.tick
    if self.snapshot~=state or self.snapshotTick~=tick or self.selected~=selected or self.hidden~=hidden then
        self.snapshot=state;self.snapshotTick=tick;self.selected=selected;self.hidden=hidden
        local list={}
        if not hidden and state and state.units then for _,u in ipairs(state.units)do if M.priority[u.kind]then table.insert(list,u)end end end
        table.sort(list,function(a,b)return Display.order(a,b,selected)end)
        local factions={};for _,f in ipairs(state and state.factions or {})do factions[f.id]=f end
        local ok,looks=pcall(Looks.all,state or {});self.looks=ok and looks or {}
        self.ordered=list;self.factions=factions;self.snapshotBuilds=(self.snapshotBuilds or 0)+1
    end
    local list=self.ordered or {};local factions=self.factions or {};local looks=self.looks or {}
    self:animate(renderer)
    local span=renderer.liveW or renderer.view and renderer.view.w or 200
    local camera=workspace.CurrentCamera and workspace.CurrentCamera.CFrame
    local view=renderer.view and string.format('%.3f:%.3f:%.3f',renderer.view.x or 0,renderer.view.y or 0,span)or ''
    if self.frameKey and self.frameBuilds==self.snapshotBuilds and self.frameCamera==camera and self.frameView==view and self.frameSize==size then return end
    self.frameKey=true;self.frameBuilds=self.snapshotBuilds;self.frameCamera=camera;self.frameView=view;self.frameSize=size
    local band,px=M.band(span);px=math.floor(px*M.sizeScale+.5)
    local dots=band=='far'and size.X/math.max(span,1)<M.dotsZoom
    if dots then px=math.max(9,math.floor(px*.6))end
    local lotPixels=size.X/math.max(span,1)*M.lotTiles
    local tactical=band=="close" or band=="mid" and lotPixels>=M.tacticalPixels
    if tactical then px=M.chipPixels end
    local bandKey=tactical and band..":tactical" or dots and "far:dots" or band
    self.root:SetAttribute("Tactical",tactical)
    local occupied=Display.occupancy(48);local count=0;self.hits={}
    local slotOf=self.slotOf or {};local taken={};local placed={}
    for _,u in ipairs(list)do
        if count>=M.limit then break end
        local roof=M.roofHeight[u.kind]or 4.4
        local p=renderer:project(u.tile,tactical and roof or roof*.4,true)
        local bounds=renderer.annotationBounds or {left=0,top=0,right=size.X,bottom=size.Y}
        if p.X<bounds.left-px or p.Y<bounds.top-px or p.X>bounds.right+px or p.Y>bounds.bottom+px then continue end
        local levelVisible=not dots and (u.level or 1)>=2
        if not Display.reserve(occupied,p.X,p.Y,px*.5,px*.5,0)then continue end
        count+=1;table.insert(self.hits,{id=u.id,x=p.X,y=p.Y,size=px,width=px+(levelVisible and 8 or 0),height=px+(levelVisible and 16 or 8),offset=levelVisible and -6 or 0})
        local slot=slotOf[u.id];if slot and self.pool[slot]and not taken[slot]then taken[slot]=true else slot=nil end
        table.insert(placed,{u=u,p=p,levelVisible=levelVisible,order=count,slot=slot})
    end
    local free=1;local slots={};local newSlotOf={};local deadline=os.clock()+M.restyleBudget;local deferred=false
    for _,e in ipairs(placed)do if not e.slot then while taken[free]do free+=1 end;taken[free]=true;e.slot=free end end
    for _,e in ipairs(placed)do
        local u,p,levelVisible=e.u,e.p,e.levelVisible
        table.insert(slots,e.slot);newSlotOf[u.id]=e.slot
        local b=self:badge(e.slot);local f=b.frame
        f.Visible=true;f.Position=UDim2.fromOffset(p.X,p.Y)
        if f.ZIndex~=M.limit+1-e.order then f.ZIndex=M.limit+1-e.order end
        local color=Colors.get(u.owner,factionKinds[u.owner],ownColor)
        local threat=Display.threat(u,factions)
        local status,progress=Display.status(u,state and state.tick or 0)
        local skinId=(looks[u.owner]or {})[M.skinSlot(u.kind)]or"classic"
        local changed=b.unit~=u.id or b.kind~=u.kind or b.owner~=u.owner or b.color~=color or b.building~=u.building or b.threat~=threat or b.unitLevel~=u.level or b.status~=status or b.progress~=progress or b.hasMissiles~=(u.readyMissiles~=nil) or b.skinId~=skinId
        if not changed and b.band~=bandKey and os.clock()>deadline then deferred=true
        elseif changed or b.band~=bandKey then
        local ok,err=pcall(function()
        b.unit=u.id;b.kind=u.kind;b.owner=u.owner;b.color=color;b.building=u.building;b.threat=threat;b.band=bandKey;b.unitLevel=u.level;b.status=status;b.progress=progress;b.hasMissiles=u.readyMissiles~=nil;b.skinId=skinId
        self.styleUpdates=(self.styleUpdates or 0)+1
        f.Size=UDim2.fromOffset(px,px)
        f.BackgroundColor3=color;f.BackgroundTransparency=u.building and .5 or 0
        local art=shape(u.kind);b.shape.Visible=art and true or false;b.stroke.Enabled=not art
        if art then
            f.BackgroundTransparency=1
            if b.shape:GetAttribute("Kind")~=u.kind then b.shape.ImageContent=Content.fromObject(art.fill);b.shape:SetAttribute("Kind",u.kind)end
            b.edge.ImageContent=Content.fromObject(threat and art.threat or art.edge)
            b.shape.ImageColor3=color;b.shape.ImageTransparency=u.building and .5 or 0
            b.edge.ImageColor3=threat and amber or u.owner==1 and UI.colors.ice or UI.colors.bg
            b.edge.ImageTransparency=(threat or u.owner==1) and 0 or .35
        end
        Skin.apply(b.skin,art and Skin.spec(Catalog.get(skinId))or nil,u.kind,M.shapes[u.kind],px,dots,u.building==true,M.skinLift[u.kind])
        local glyphScale=art and u.kind=="MissileSilo" and .6 or .74
        b.icon.Size=UDim2.fromScale(glyphScale,glyphScale);b.native.Size=UDim2.fromScale(glyphScale+.04,glyphScale+.04)
        local light=(color.R*.299+color.G*.587+color.B*.114)>.55
        local ink=Color3.new(1,1,1)
        local image=glyph(u.kind)
        b.icon.Visible=not dots and image~=false and image~=nil;b.letter.Visible=false;b.native.Visible=not dots and not b.icon.Visible
        if b.native.Visible then if b.native:GetAttribute('Kind')~=u.kind then NativeGlyph.draw(b.native,u.kind,ink)else NativeGlyph.paint(b.native,ink)end end
        if b.icon.Visible and b.icon:GetAttribute("Kind")~=u.kind then b.icon.ImageContent=Content.fromObject(image);b.shadow.ImageContent=Content.fromObject(image);b.icon:SetAttribute("Kind",u.kind)end
        b.icon.ImageColor3=ink;b.icon.ImageTransparency=u.building and .4 or 0
        b.shadow.Visible=b.icon.Visible and light;b.shadow.Size=b.icon.Size;b.shadow.ImageTransparency=u.building and .7 or .35
        b.letter.Text=M.letters[u.kind];b.letter.TextColor3=ink
        b.stroke.Color=threat and amber or u.owner==1 and UI.colors.ice or UI.colors.bg
        b.stroke.Thickness=threat and 2 or u.owner==1 and 1.5 or 1;b.stroke.Transparency=(threat or u.owner==1) and 0 or .35
        b.level.Visible=levelVisible;b.level.Text=tostring(u.level or 1)
        if levelVisible then
            local text=math.max(13,math.floor(px*.6+.5));b.level.TextSize=text;b.level.Size=UDim2.fromOffset(text*2,text)
            b.level.Position=UDim2.fromScale(.5,.5-(art and M.skinLift[u.kind]or .5)-.12)
        end
        b.track.Visible=(band~='far'or u.id==selected)and (status~='ready'or u.readyMissiles~=nil);b.fill.Size=UDim2.fromScale(progress,1)
        b.fill.BackgroundColor3=(status=='deleting'or status=='damaged')and UI.colors.danger or status=='building'and UI.colors.gold or UI.colors.ice
        f:SetAttribute('UnitId',u.id);f:SetAttribute('Status',status);f:SetAttribute('Progress',progress);f:SetAttribute('Threat',threat)
        f:SetAttribute("Kind",u.kind);f:SetAttribute("Owner",u.owner)
        end)
        if not ok and not warned[tostring(err)]then warned[tostring(err)]=true;warn("StructureIcons badge: "..tostring(err))end
        end
    end
    for i,b in ipairs(self.pool)do if not taken[i]then b.frame.Visible=false end end
    self.slotOf=newSlotOf;self.drawnSlots=slots;self.drawn=count
    if deferred then self.frameKey=nil end
    self.root:SetAttribute("Band",band);self.root:SetAttribute("Visible",count);self.root:SetAttribute("Total",#list)
end
function M:hit(pos,touch)
    local best,distance
    for _,h in ipairs(self.hits or {})do
        local reach=math.max(h.size/2,touch and 22 or 14);local dx,dy=pos.X-h.x,pos.Y-h.y
        if math.abs(dx)<=reach and math.abs(dy)<=reach then local d=dx*dx+dy*dy;if not distance or d<distance then best=h.id;distance=d end end
    end
    return best
end
return M
