local V=require(script.Parent.ViewMath)
local Finish=require(script.Parent.MapFinish)
local FactionColors=require(script.Parent.FactionColors)
local Theme=require(script.Parent.Theme)
local Collection=require(script.Parent.TerritoryCollection)
local Defense=require(script.Parent.Parent.Core.DefenseCoverage)
local M={};M.__index=M
M.tilesPerDraw=6000
M.smoothBoard=false
local editableAllowed=true
local colors={ocean=Color3.fromRGB(8,19,31),water=Color3.fromRGB(13,30,46),edge=Color3.fromRGB(191,239,255),ours=FactionColors.self,rock=Color3.fromRGB(46,56,68),outside=Color3.fromRGB(6,10,15),glow=Color3.fromRGB(226,255,247)}
local terrainColors=Finish.base
local lift={front={.66,.48},frontier={.32,.18},coast={.16,.06}}
local function edgeKind(self,t,id)
    local m=self.map.meta;local w,h=m.width,m.height;local x=t%w;local wild=false
    local function look(n)
        local o=self.owners[n]
        if o and o~=0 then return o~=id end
        local b=buffer.readu8(self.map.terrain,n)
        if bit32.band(b,128)~=0 and bit32.band(b,31)~=31 then wild=true end
        return false
    end
    if (x>0 and look(t-1)) or (x<w-1 and look(t+1)) or (t>=w and look(t-w)) or (t<(h-1)*w and look(t+w)) then return 'front' end
    return wild and 'frontier' or 'coast'
end
local boardLift=setmetatable({},{__mode='k'})
local pale=Color3.fromRGB(236,246,255)
local function onBoard(tint)
    local k=boardLift[tint]
    if k==nil then
        local h,s=tint:ToHSV();local d=math.abs(((h*360-212)+180)%360-180)
        k=math.max(0,1-d/45)*s;boardLift[tint]=k
    end
    return k
end
local function territory(self,c,id,edge,tile)
    if self.affiliation then local a=self.affiliation[id]or self.affiliation.neutral;if edge then return a end;return c:Lerp(a,.45)end
    local kind=self.factionKinds and self.factionKinds[id]
    local tint=FactionColors.get(id,kind,self.territoryColor or colors.ours)
    local defended=self.defense~=nil and tile~=nil and Defense.covered(self.defense,id,tile)
    if edge then
        local k=tile and edgeKind(self,tile,id) or 'front'
        local e
        if id==1 and self.borderColor then e=k=='front' and self.borderColor or self.borderColor:Lerp(tint,k=='frontier' and .4 or .7)
        else e=tint:Lerp(colors.edge,lift[k][id==1 and 1 or 2])end
        if defended and Defense.checker(tile,self.map.meta.width)then local d=Defense.checkerDarken;e=Color3.new(e.R*d,e.G*d,e.B*d)end
        return e
    end
    local fill=id==1 and .56 or kind=='BOT' and .6 or .5
    local k=onBoard(tint);if k>0 then fill+=.22*k;tint=tint:Lerp(pale,.14*k)end
    if defended then local d=Defense.fillDarken;tint=Color3.new(tint.R*d,tint.G*d,tint.B*d)end
    return Collection.pattern(c:Lerp(tint,fill),tile,self.map.meta.width,self.collectionTiers and self.collectionTiers[id])
end
function M.new(parent,width,height)
    local self=setmetatable({parent=parent,width=width or 448,height=height or 280,pool={},owners={},view={x=0,y=0,w=100,h=100}},M)
    local img
    local ok=editableAllowed and pcall(function()
        img=game:GetService("AssetService"):CreateEditableImage({Size=Vector2.new(self.width,self.height)})
        if img then img:WritePixelsBuffer(Vector2.zero,Vector2.new(1,1),buffer.create(4))end
    end)
    if not ok then editableAllowed=false;if img then img:Destroy();img=nil end end
    if ok and img then
        self.image=img
        local label=Instance.new("ImageLabel");label.Name="MapRaster";label.BackgroundTransparency=1;label.Size=UDim2.fromScale(1,1);label.ResampleMode=Enum.ResamplerMode.Pixelated;label.ImageContent=Content.fromObject(img);label.Parent=parent;self.label=label
    else
        self.width=math.min(self.width,160);self.height=math.min(self.height,100)
        local f=Instance.new("Frame");f.Name="MapRasterFallback";f.Size=UDim2.fromScale(1,1);f.BackgroundTransparency=1;f.Parent=parent;self.label=f
    end
    self.buffer=buffer.create(self.width*self.height*4)
    self.finishBuffer=buffer.create(self.width*self.height*4)
    self.parent:SetAttribute("Renderer",self.image and "EditableImage" or "FrameRuns")
    return self
end
function M:setMap(map)
    buffer.fill(self.finishBuffer,0,0)
    self.map=map;self.view=V.fit(map.meta.width,map.meta.height,math.max(1,self.parent.AbsoluteSize.X)/math.max(1,self.parent.AbsoluteSize.Y))
end
function M:setPreview(map)
    self:setMap(map);local corner=buffer.readu8(map.terrain,0)
    self.outside=terrainColors[bit32.band(corner,128)==0 and corner or 63];self.parent.BackgroundColor3=self.outside
end
function M:aspect() return math.max(1,self.parent.AbsoluteSize.X)/math.max(1,self.parent.AbsoluteSize.Y) end
function M:clamp() if self.map then V.clamp(self.view,self.map.meta.width,self.map.meta.height,self:aspect()) end end
function M:fit() if self.map then self.view=V.fit(self.map.meta.width,self.map.meta.height,self:aspect()) end end
function M:zoom(factor,u,v)
    if self.map then V.zoom(self.view,factor,u or .5,v or .5,self.map.meta.width,self.map.meta.height,self:aspect()) end
end
function M:tileAt(pos)
    if not self.map then return nil end
    local p=pos-self.parent.AbsolutePosition;local s=self.parent.AbsoluteSize
    return V.tileAt(self.view,p.X/s.X,p.Y/s.Y,self.map.meta.width,self.map.meta.height)
end
function M:project(tile)
    local m=self.map.meta
    local size=self.parent.AbsoluteSize/Theme.scale
    return Vector2.new((tile%m.width+.5-self.view.x)/self.view.w*size.X,(math.floor(tile/m.width)+.5-self.view.y)/self.view.h*size.Y)
end
function M:scratch(bytes)
    self.scratchBuffers=self.scratchBuffers or {}
    local value=self.scratchBuffers[bytes]
    if not value then value=buffer.create(bytes);self.scratchBuffers[bytes]=value;self.scratchAllocations=(self.scratchAllocations or 0)+1 end
    return value
end
function M:draw()
    if not self.map then return end
    local m,v,W,H=self.map.meta,self.view,self.width,self.height
    if self.exactTiles and self.image then
        if M.smoothBoard and not self.smoothed then self.smoothed=true;self.label.ResampleMode=Enum.ResamplerMode.Default end
        local outline=self.outline or {};local borders=self.borderCount or 0
        local function pixel(t)
            local xx,yy=t%m.width-v.x,math.floor(t/m.width)-v.y
            if xx<0 or yy<0 or xx>=W or yy>=H then return end
            local at=(yy*W+xx)*4;local cache=self.finishBuffer
            if buffer.readu8(cache,at+3)==0 then
                local paint=Finish.color(self.map,t)
                buffer.writeu8(cache,at,math.floor(paint.R*255+.5));buffer.writeu8(cache,at+1,math.floor(paint.G*255+.5));buffer.writeu8(cache,at+2,math.floor(paint.B*255+.5));buffer.writeu8(cache,at+3,255)
            end
            local c=Color3.fromRGB(buffer.readu8(cache,at),buffer.readu8(cache,at+1),buffer.readu8(cache,at+2));local edge=false
            if self.owners[t] then edge=V.ownerBoundary(self.owners,t,m.width,m.height);c=territory(self,c,self.owners[t],edge,t) end
            local lit=self.glow and self.glow[t];if lit then local k=1-(os.clock()-lit)/.4;if k>0 then c=c:Lerp(colors.glow,.55*k) end end
            if self.map.fallout and self.map.fallout[t] then c=c:Lerp(Color3.fromRGB(154,162,74),((t%m.width)+math.floor(t/m.width))%5<2 and .78 or .42) end
            if edge and not outline[t] then borders+=1 elseif not edge and outline[t] then borders-=1 end
            outline[t]=edge and true or nil
            buffer.writeu8(self.buffer,at,math.floor(c.R*255+.5));buffer.writeu8(self.buffer,at+1,math.floor(c.G*255+.5));buffer.writeu8(self.buffer,at+2,math.floor(c.B*255+.5));buffer.writeu8(self.buffer,at+3,255)
        end
        if self.force or not self.initialized and self.paintRow==nil then self.paintRow=0;self.force=false end
        if self.paintRow then
            local y=self.paintRow;local rows=0;local deadline=self.initialized and self.deadline or math.huge
            repeat for xx=0,W-1 do pixel((y+rows+v.y)*m.width+xx+v.x) end;rows+=1 until rows>=16 or y+rows>=H or rows>=4 and os.clock()>deadline
            local strip=self:scratch(W*rows*4);buffer.copy(strip,0,self.buffer,y*W*4,W*rows*4)
            self.image:WritePixelsBuffer(Vector2.new(0,y),Vector2.new(W,rows),strip)
            self.paintRow=y+rows
            if self.paintRow>=H then self.paintRow=nil;self.initialized=true end
        else
            local blocks={};local columns=math.ceil(W/32);local dirty=self.dirtyTiles or {};local left=M.tilesPerDraw
            local deadline=self.deadline or math.huge
            for t in pairs(dirty) do
                if left<=0 or left%64==0 and os.clock()>deadline then break end;left-=1;dirty[t]=nil
                pixel(t)
                local x,y=t%m.width-v.x,math.floor(t/m.width)-v.y
                if x>=0 and y>=0 and x<W and y<H then blocks[math.floor(y/32)*columns+math.floor(x/32)]=true end
            end
            self.dirtyTiles=dirty
            for key in pairs(blocks) do
                local x,y=(key%columns)*32,math.floor(key/columns)*32
                local bw,bh=math.min(32,W-x),math.min(32,H-y);local patch=self:scratch(bw*bh*4)
                for row=0,bh-1 do buffer.copy(patch,row*bw*4,self.buffer,((y+row)*W+x)*4,bw*4) end
                self.image:WritePixelsBuffer(Vector2.new(x,y),Vector2.new(bw,bh),patch)
            end
        end
        self.outline=outline;self.borderCount=borders;if self.borderShown~=borders then self.borderShown=borders;self.parent:SetAttribute("BorderPixels",borders)end
        return
    end
    local samples,tiles,bytes={},{},{}
    for y=0,H-1 do
        local yy=math.floor(v.y+(y+.5)/H*v.h)
        for x=0,W-1 do
            local xx=math.floor(v.x+(x+.5)/W*v.w);local i=y*W+x+1
            if xx>=0 and yy>=0 and xx<m.width and yy<m.height then
                local t=yy*m.width+xx;tiles[i]=t;bytes[i]=buffer.readu8(self.map.terrain,t);samples[i]=self.owners[t] or 0
            else samples[i]=0 end
        end
    end
    local runs=0;local outline=0
    for y=0,H-1 do
        local previous,startX=nil,0
        local function flush(x,c)
            runs+=1;local p=self.pool[runs]
            if not p then p=Instance.new("Frame");p.Name="TerrainRun";p.BorderSizePixel=0;p.Parent=self.label;self.pool[runs]=p end
            p.Visible=true;p.BackgroundColor3=c;p.Position=UDim2.fromScale(startX/W,y/H);p.Size=UDim2.new((x-startX)/W,1,1/H,1)
        end
        for x=0,W-1 do
            local i=y*W+x+1;local b=bytes[i];local c=b and (self.image and Finish.color(self.map,tiles[i])or terrainColors[b])or self.outside or colors.outside
            if samples[i]~=0 then
                local edge=(x==0 or samples[i-1]~=samples[i]) or (x==W-1 or samples[i+1]~=samples[i]) or (y==0 or samples[i-W]~=samples[i]) or (y==H-1 or samples[i+W]~=samples[i])
                if v.w/W<1 then edge=V.ownerBoundary(self.owners,tiles[i],m.width,m.height) end
                c=territory(self,c,samples[i],edge,tiles[i]);if edge then outline+=1 end
            end
            if self.image then
                local at=(i-1)*4;buffer.writeu8(self.buffer,at,math.floor(c.R*255+.5));buffer.writeu8(self.buffer,at+1,math.floor(c.G*255+.5));buffer.writeu8(self.buffer,at+2,math.floor(c.B*255+.5));buffer.writeu8(self.buffer,at+3,255)
            elseif previous and c~=previous then flush(x,previous);startX=x end
            previous=c
        end
        if not self.image and previous then flush(W,previous) end
    end
    if self.image then self.image:WritePixelsBuffer(Vector2.zero,Vector2.new(W,H),self.buffer)
    else for i=runs+1,#self.pool do self.pool[i].Visible=false end end
    self.borderCount=outline;self.parent:SetAttribute("BorderPixels",outline)
    self.initialized=true;self.force=false;self.dirtyTiles={}
end
function M:destroy()
    if self.image then self.image:Destroy() end;self.label:Destroy()
    self.scratchBuffers=nil
end
return M
