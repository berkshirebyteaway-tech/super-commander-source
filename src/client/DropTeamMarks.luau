local M={};M.__index=M
local function make(class,parent,props)local o=Instance.new(class);for k,v in pairs(props)do o[k]=v end;o.Parent=parent;return o end
local function disc(parent,name,size,fill,edge,thickness)
    local f=make('Frame',parent,{Name=name,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(size,size),BackgroundTransparency=fill,BorderSizePixel=0})
    make('UICorner',f,{CornerRadius=UDim.new(.5,0)})
    local s=edge and make('UIStroke',f,{Thickness=thickness,Transparency=edge})
    return f,s
end
local function mark(folder,name)
    local part=make('Part',nil,{Name=name,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Transparency=1,Size=Vector3.new(6,.05,6)})
    local surface=make('SurfaceGui',part,{Face=Enum.NormalId.Top,CanvasSize=Vector2.new(200,200),LightInfluence=0,AlwaysOnTop=true})
    part.Parent=folder;return part,surface
end
M.glowSize=6.5;M.ringSpan=13.5
function M.new(folder,id,color,team,own)
    local self=setmetatable({team=team,own=own,shownGlow=nil,shownRing=nil},M)
    self.glow,self.glowGui=mark(folder,'TeamGlow_'..id)
    self.outer=disc(self.glowGui,'Outer',1,.93);self.mid=disc(self.glowGui,'Mid',.7,.89);self.core,self.edge=disc(self.glowGui,'Core',.42,.85,.7,4)
    if team and not own then
        self.ring,self.ringGui=mark(folder,'TeamRing_'..id)
        self.ringFill,self.ringEdge=disc(self.ringGui,'Band',.9,.9,.35,6)
        self.wave,self.waveEdge=disc(self.ringGui,'Wave',.9,1,1,6)
    end
    self:recolor(color);self:show(false,false);return self
end
function M:recolor(color)
    if self.color==color then return end;self.color=color
    for _,f in ipairs({self.outer,self.mid,self.core,self.ringFill,self.wave})do f.BackgroundColor3=color end
    self.edge.Color=color;if self.ringEdge then self.ringEdge.Color=color;self.waveEdge.Color=color end
end
function M:show(glow,ring)
    ring=ring and self.ring~=nil
    if self.shownGlow~=glow then self.shownGlow=glow;self.glowGui.Enabled=glow end
    if self.ring and self.shownRing~=ring then self.shownRing=ring;self.ringGui.Enabled=ring end
end
function M:step(body,floor,canopy,inflation,yaw,t,reduced,batch,obscured)
    local function place(p,cf)if batch then batch:put(p,cf)else p.CFrame=cf end end
    local ring=canopy~=nil and (inflation or 0)>.35
    self:show(not obscured,ring and not obscured)
    if obscured then return end
    local breath=reduced and 0 or math.sin(t*2.1)*.5+.5
    self.outer.BackgroundTransparency=.93-.03*breath
    place(self.glow,yaw.Rotation+Vector3.new(body.X,math.max(floor+.15,body.Y-.6),body.Z))
    if self.shownRing then
        local span=M.ringSpan*math.clamp(inflation,0,1)
        if not self.span or math.abs(self.span-span)>.15 then self.span=span;self.ring.Size=Vector3.new(span,.05,span)end
        place(self.ring,canopy.Rotation+canopy.Position)
        if reduced then self.waveEdge.Transparency=1
        else local phase=(t*.45)%1;local s=.9+.1*phase;self.wave.Size=UDim2.fromScale(s,s);self.waveEdge.Transparency=.35+.65*phase end
    end
end
function M:destroy()self.glow:Destroy();if self.ring then self.ring:Destroy()end end
return M
