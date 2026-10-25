local K=require(script.Parent.Kit20)
local Theme=require(script.Parent.Theme)
local M={}
local C=K.colors
M.GLASS=Color3.fromRGB(12,17,24)
M.DANGER_BG=Color3.fromRGB(40,12,14)
M.DANGER_INK=Color3.fromRGB(255,138,138)
function M.enabled()return require(script.Parent.Hud20).ENABLED end
function M.fmt(w,h)
    local touch=require(script.Parent.InputMode).touch()
    if not touch or require(script.Parent.Parent.Core.InterfacePlacement).tablet(w,h,touch)then return 'pc'end
    return w<h and 'pt'or 'ph'
end
function M.size(o)local s=Theme.scale or 1;local a=o and o.AbsoluteSize or Vector2.new(1366,768);return a.X/s,a.Y/s end
function M.inset()local v=0;pcall(function()v=game:GetService('GuiService'):GetGuiInset().Y/(Theme.scale or 1)end);return v end
function M.y(mock)return math.floor(mock-M.inset()+.5)end
function M.clock(panel,fmt)
    local f=panel and panel:FindFirstChild('MatchStatus')
    if f and f.Visible then return f.Position.Y.Offset,f.Position.Y.Offset+f.Size.Y.Offset end
    local top=math.max(4,M.y(fmt=='ph'and 50 or 58));return top,top+(fmt=='pc'and 48 or 28)
end

M.column={card=false,cardBottom=0,band=false,bandBottom=0,rocket=false}
local watchers={}
function M.watch(fn)table.insert(watchers,fn)end
local function changed(what)for _,fn in ipairs(watchers)do task.spawn(fn,what)end end
function M.setCard(on,bottom)
    local c=M.column;on=on==true;bottom=on and math.floor(bottom or 0)or 0
    if c.card==on and c.cardBottom==bottom then return end
    c.card=on;c.cardBottom=bottom;changed('card')
end
function M.setBand(on,bottom)
    local c=M.column;on=on==true;bottom=on and math.floor(bottom or 0)or 0
    if c.band==on and c.bandBottom==bottom then return end
    c.band=on;c.bandBottom=bottom;changed('band')
end
function M.setRocket(on)if M.column.rocket~=(on==true)then M.column.rocket=on==true;changed('rocket')end end
function M.bandTop(panel,fmt)
    local c=M.column
    if c.card then return c.cardBottom+6 end
    if fmt=='pt'then return(M.clock(panel,fmt))end
    return M.y(fmt=='pc'and 12 or 10)
end
function M.columnBottom()local c=M.column;return math.max(c.card and c.cardBottom or 0,c.band and c.bandBottom or 0)end

function M.glass(parent,name,r,alpha,z)
    local f=K.make('Frame',parent,{Name=name,BackgroundColor3=M.GLASS,BackgroundTransparency=1-(alpha or .94),BorderSizePixel=0,ZIndex=z or 1})
    K.round(f,r or 10);K.stroke(f,C.line,1,.1,true);return f
end
local CK,NK=ColorSequenceKeypoint.new,NumberSequenceKeypoint.new
function M.edge(frame,color,px,fill,fillAlpha,width)
    local g=frame:FindFirstChild('Edge20')or K.make('UIGradient',frame,{Name='Edge20'})
    frame.BackgroundColor3=Color3.new(1,1,1);g.Enabled=true
    local w=width or frame.Size.X.Offset;if w<=0 then w=frame.AbsoluteSize.X/(Theme.scale or 1)end
    local p=math.clamp((px or 3)/math.max(1,w),.002,.99);local a=1-(fillAlpha or .94)
    local key=tostring(color)..'|'..tostring(fill)..'|'..p..'|'..a
    if g:GetAttribute('Key')==key then return g end;g:SetAttribute('Key',key)
    g.Color=ColorSequence.new({CK(0,color),CK(p-.001,color),CK(p,fill or M.GLASS),CK(1,fill or M.GLASS)})
    g.Transparency=NumberSequence.new({NK(0,0),NK(p-.001,0),NK(p,a),NK(1,a)})
    return g
end
function M.sweep(frame,color,p,fill,fillAlpha)
    local g=frame:FindFirstChild('Edge20')or K.make('UIGradient',frame,{Name='Edge20'})
    p=math.clamp(p,.002,.998);local a=1-(fillAlpha or .94);g:SetAttribute('Key',nil)
    g.Color=ColorSequence.new({CK(0,color),CK(p-.001,color),CK(p,fill or M.GLASS),CK(1,fill or M.GLASS)})
    g.Transparency=NumberSequence.new({NK(0,0),NK(p-.001,0),NK(p,a),NK(1,a)})
end

local Ring={};Ring.__index=Ring
function M.ring(parent,name,size,thick,color,track)
    local f=K.make('Frame',parent,{Name=name or 'Ring20',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromOffset(size,size)})
    local function circle(p,x)
        local c=K.make('Frame',p,{Name='Circle',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromOffset(size-thick*2,size-thick*2),Position=UDim2.fromOffset(x+thick,thick)})
        K.round(c,'pill');local s=K.make('UIStroke',c,{Thickness=thick,ApplyStrokeMode=Enum.ApplyStrokeMode.Border});return c,s
    end
    local _,ts=circle(f,0);ts.Color=track or C.line
    local self=setmetatable({frame=f,halves={},ratio=-1},Ring)
    for half=0,1 do
        local clip=K.make('Frame',f,{Name='Half'..half,BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true,Position=UDim2.fromOffset(half==0 and size/2 or 0,0),Size=UDim2.fromOffset(size/2,size)})
        local _,s=circle(clip,half==0 and -size/2 or 0);s.Color=color or C.ally
        local g=K.make('UIGradient',s,{Transparency=NumberSequence.new({NK(0,0),NK(.5,0),NK(.501,1),NK(1,1)})})
        self.halves[half+1]={clip=clip,stroke=s,gradient=g}
    end
    self:set(1,color);return self
end
function Ring:set(ratio,color)
    ratio=math.clamp(tonumber(ratio)or 0,0,1)
    if color and color~=self.color then self.color=color;for _,h in ipairs(self.halves)do h.stroke.Color=color end end
    local r=math.floor(ratio*360+.5)/360;if r==self.ratio then return end;self.ratio=r
    local a,b=self.halves[1],self.halves[2]
    a.clip.Visible=r>0;a.gradient.Rotation=math.min(r,.5)/.5*180
    b.clip.Visible=r>.5;b.gradient.Rotation=180+math.clamp(r-.5,0,.5)/.5*180
end

function M.orig(parent,key,size,color,name)
    local i=require(script.Parent.HotbarIcons).create(parent,key,size,color);i.Name=name or ('Orig_'..key);return i
end
function M.tint(icon,color)require(script.Parent.HotbarIcons).tint(icon,color)end
local widths,count={},0
function M.width(text,size,label)
    local key=text..'\0'..size..'\0'..tostring(label and label.FontFace and label.FontFace.Family..label.FontFace.Weight.Name or '')
    local v=widths[key];if v then return v end
    v=K.width(text,size,label);if count>512 then widths={};count=0 end;widths[key]=v;count+=1;return v
end
return M
