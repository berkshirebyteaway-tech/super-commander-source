local Tween=game:GetService('TweenService')
local TextService=game:GetService('TextService')
local Theme=require(script.Parent.Theme)
local Icons=require(script.Parent.OutgameIcons)
local M={}
local C=Theme.colors
M.colors=C
C.ally=C.ally or Color3.fromRGB(91,212,107)
C.dim=C.dim or Color3.fromRGB(74,85,102)
C.good2=Color3.fromRGB(180,240,90)
M.rarity={normal=Color3.fromRGB(154,166,184),rare=Color3.fromRGB(76,141,255),epic=Color3.fromRGB(160,107,255),legendary=Color3.fromRGB(245,196,81),mythic=Color3.fromRGB(255,143,216)}
M.team=Color3.fromRGB(139,92,246)
M.reduced=false

local function face(family,weight)local ok,f=pcall(function()return Font.new('rbxasset://fonts/families/'..family..'.json',weight)end);return ok and f or nil end
local W=Enum.FontWeight
M.fonts={
    [400]=face('BuilderSans',W.Regular),[500]=face('BuilderSans',W.Medium),[600]=face('BuilderSans',W.Bold),
    [700]=face('BuilderSans',W.Bold),[800]=face('BuilderSans',W.ExtraBold),[900]=face('BuilderSans',W.Heavy)or face('BuilderSans',W.ExtraBold),
    num=face('Oswald',W.Bold),num600=face('Oswald',W.SemiBold)or face('Oswald',W.Bold),
}
function M.make(class,parent,props)local o=Instance.new(class);for k,v in pairs(props or {})do o[k]=v end;o.Parent=parent;return o end
function M.box(o,x,y,w,h)o.Position=UDim2.fromOffset(math.floor(x+.5),math.floor(y+.5));o.Size=UDim2.fromOffset(math.floor(w+.5),math.floor(h+.5));return o end
function M.even(n)return math.floor(n/2)*2 end
function M.boxCentre(o,x,y,w,h)
    w,h=M.even(math.floor(w+.5)),M.even(math.floor(h+.5))
    o.AnchorPoint=Vector2.new(.5,.5)
    o.Position=UDim2.fromOffset(math.floor(x+.5)+w/2,math.floor(y+.5)+h/2);o.Size=UDim2.fromOffset(w,h)
    return o
end

function M.round(o,r)
    local c=o:FindFirstChildOfClass('UICorner')or M.make('UICorner',o)
    c.CornerRadius=r=='pill'and UDim.new(.5,0)or UDim.new(0,r or 8);return o
end
function M.stroke(o,color,thickness,transparency,inner)
    local s=o:FindFirstChild('Stroke20')
    if not s then s=M.make('UIStroke',o,{Name='Stroke20',ApplyStrokeMode=Enum.ApplyStrokeMode.Border,LineJoinMode=Enum.LineJoinMode.Round})end
    s.Color=color or C.line;s.Thickness=thickness or 1;s.Transparency=transparency or 0
    if inner~=nil then pcall(function()s.BorderStrokePosition=inner and Enum.BorderStrokePosition.Inner or Enum.BorderStrokePosition.Outer end)end
    return s
end
M.innerStroke=pcall(function()local s=Instance.new('UIStroke');s.BorderStrokePosition=Enum.BorderStrokePosition.Inner;s:Destroy()end)
function M.scrollPad(scroll,px)
    px=px or 4
    local p=scroll:FindFirstChild('Pad20')or M.make('UIPadding',scroll,{Name='Pad20'})
    p.PaddingLeft=UDim.new(0,px);p.PaddingRight=UDim.new(0,px);p.PaddingTop=UDim.new(0,px);p.PaddingBottom=UDim.new(0,px);return p
end

function M.panel(parent,name,kind,r,alpha)
    local fill=kind=='raised'and C.raised or kind=='bg'and C.bg or kind=='glass'and Color3.fromRGB(12,17,24)or C.panel
    local p=M.make('Frame',parent,{Name=name or 'Panel',BackgroundColor3=fill,BackgroundTransparency=alpha or(kind=='glass'and .14 or 0),BorderSizePixel=0})
    M.round(p,r or(kind=='glass'and 10 or 8))
    if kind~='bg'then M.stroke(p,C.line,1,kind=='glass'and .1 or 0)end
    return p
end

function M.text(parent,name,text,size,color,weight,align)
    local l=M.make('TextLabel',parent,{Name=name or 'Text',Text=text or '',TextSize=size or 14,TextColor3=color or C.ink,BackgroundTransparency=1,BorderSizePixel=0,
        TextXAlignment=align or Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextWrapped=false,TextTruncate=Enum.TextTruncate.AtEnd})
    local f=M.fonts[weight or 700];if f then l.FontFace=f else l.Font=Enum.Font.BuilderSansBold end
    return l
end
function M.num(parent,name,text,size,color,align)
    local l=M.text(parent,name,text,size,color,700,align);if M.fonts.num then l.FontFace=M.fonts.num end;l:SetAttribute('LocalizationSkip',true);return l
end
function M.width(text,size,label)
    local font=label and label.Font or Enum.Font.BuilderSansBold
    local ok,v=pcall(function()
        if label and label.FontFace then
            local p=Instance.new('GetTextBoundsParams');p.Text=text;p.Size=size;p.Font=label.FontFace;p.Width=4096
            return TextService:GetTextBoundsAsync(p).X
        end
        return TextService:GetTextSize(text,size,font,Vector2.new(4096,200)).X
    end)
    return ok and math.ceil(v*1.04)+2 or #text*size*.6
end
function M.fit(l,width,max,min)
    local size=max;while size>min and M.width(l.Text,size,l)>width do size-=1 end;l.TextSize=size;return size
end

function M.icon(parent,key,size,color,name)
    local i=Icons.create(parent,key,size,color);i.Name=name or ('Icon_'..tostring(key));return i
end

local Stops=require(script.Parent.Parent.Core.FillStops)
local function keypoints(parts,track,trackAlpha)
    local times,colors,alphas=Stops.build(parts,track,trackAlpha)
    local cs,ts={},{}
    for i,t in ipairs(times)do cs[i]=ColorSequenceKeypoint.new(t,colors[i]);ts[i]=NumberSequenceKeypoint.new(t,alphas[i])end
    if #cs==1 then cs[2]=ColorSequenceKeypoint.new(1,colors[1]);ts[2]=NumberSequenceKeypoint.new(1,alphas[1]);cs[1]=ColorSequenceKeypoint.new(0,colors[1]);ts[1]=NumberSequenceKeypoint.new(0,alphas[1])end
    return ColorSequence.new(cs),NumberSequence.new(ts)
end
local Bar={};Bar.__index=Bar
function M.fillBar(parent,name,spec)
    spec=spec or {}
    local f=M.make('Frame',parent,{Name=name or 'FillBar',BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0,BorderSizePixel=0})
    M.round(f,spec.r or 'pill')
    local g=M.make('UIGradient',f,{Name='Fill20',Rotation=spec.vertical and -90 or 0})
    local self=setmetatable({frame=f,gradient=g,track=spec.track or C.raised,trackAlpha=spec.trackAlpha or 0,parts=spec.parts,vertical=spec.vertical},Bar)
    if spec.stroke then M.stroke(f,spec.stroke,1,spec.strokeAlpha or 0,true)end
    if spec.text~=nil then self.label=M.num(f,'Value',spec.text,spec.textSize or 12,spec.textColor or C.ink,spec.align or Enum.TextXAlignment.Center);self.label.Size=UDim2.fromScale(1,1);self.label.ZIndex=f.ZIndex+1 end
    self.value=M.make('NumberValue',f,{Name='Progress',Value=spec.p or 0})
    self.value.Changed:Connect(function()self:paint()end)
    self.fill=spec.fill or C.accent;self.fill2=spec.fill2
    self:paint();return self
end
function Bar:paint()
    local parts=self.parts
    if not parts then parts={{p=self.value.Value,color=self.fill,color2=self.fill2}}
    elseif self.scaleParts then
        local k=self.value.Value;local out={};for i,p in ipairs(self.parts)do out[i]={p=p.p*k,color=p.color,color2=p.color2,alpha=p.alpha}end;parts=out end
    local c,t=keypoints(parts,self.track,self.trackAlpha);self.gradient.Color=c;self.gradient.Transparency=t
end
function Bar:set(p,animate)
    self.parts=nil;p=math.clamp(tonumber(p)or 0,0,1)
    if self.tween then self.tween:Cancel();self.tween=nil end
    if animate and not M.reduced then
        local t=type(animate)=='number'and animate or .45
        self.tween=Tween:Create(self.value,TweenInfo.new(t,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Value=p});self.tween:Play()
    else self.value.Value=p;self:paint()end
    return self
end
function Bar:setParts(parts)self.parts=parts;self.scaleParts=false;self:paint();return self end
function Bar:setColors(fill,fill2,track)self.fill=fill or self.fill;self.fill2=fill2;if track then self.track=track end;self:paint();return self end

function M.chip(parent,name,text,kind,opts)
    opts=opts or {}
    local s=opts.size or 12;local h=opts.height or s+10
    local col=kind=='vip'and C.vip or kind=='prime'and C.prime or kind=='live'and C.danger or kind=='campaign'and C.gold or kind=='gold'and C.gold
        or kind=='accent'and C.accent or kind=='ally'and C.ally or kind=='team'and M.team or kind=='danger'and C.danger or kind=='rarity'and(opts.color or M.rarity.normal)or nil
    local filled=opts.filled or kind=='live'or kind=='campaign'
    local f=M.make('Frame',parent,{Name=name or 'Chip',BorderSizePixel=0})
    M.round(f,opts.r or 4)
    if filled then f.BackgroundColor3=col;f.BackgroundTransparency=0
    elseif col then f.BackgroundColor3=col;f.BackgroundTransparency=1-(opts.tint or .14)
    else f.BackgroundColor3=C.raised;f.BackgroundTransparency=0 end
    if not filled and opts.border~=false and (kind=='vip'or kind=='prime'or kind=='level'or kind=='muted'or opts.border)then
        M.stroke(f,col or C.line,1,col and .6 or 0,true)end
    local ink=filled and(kind=='live'and Color3.new(1,1,1)or C.bg)or col or C.muted
    local iconKey=opts.icon;if iconKey==nil then iconKey=(kind=='vip'or kind=='prime'or kind=='level')and 'lock'or kind=='campaign'and 'campaign'or nil end
    local pad=opts.pad or 6;local gap=4;local x=pad
    local icon
    if iconKey then icon=M.icon(f,iconKey,s,opts.iconColor or ink,'Icon');M.box(icon,x,math.floor((h-s)/2),s,s);x+=s+gap end
    local l=M.text(f,'Text',text,s,ink,opts.weight or(filled and 800 or 700))
    if kind=='vip'or kind=='prime'or kind=='level'then l:SetAttribute('LocalizationSkip',kind~='prime')end
    local tw=M.width(text,s,l)
    M.box(l,x,0,tw+2,h)
    local w=x+tw+pad
    f.Size=UDim2.fromOffset(w,h)
    return f,w,h,l,icon
end
function M.lock(parent,what,x,y,size)
    local kind=what=='VIP'and 'vip'or what=='프라임'and 'prime'or 'level'
    local c,w,h=M.chip(parent,'Lock',what,kind,{size=size or 12});c.Position=UDim2.fromOffset(x or 0,y or 0);return c,w,h
end

function M.dot(host,name,on,cx,cy,size)
    local d=host:FindFirstChild(name)
    if not on then
        if d and d.Visible then local s=d:FindFirstChild('Scale');if s and not M.reduced then local t=Tween:Create(s,TweenInfo.new(.1,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Scale=0});t:Play();t.Completed:Once(function()if d:GetAttribute('On')==false then d.Visible=false end end)else d.Visible=false end end
        if d then d:SetAttribute('On',false)end
        return d
    end
    size=size or 10
    if not d then
        d=M.make('Frame',host,{Name=name,AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=C.danger,BorderSizePixel=0,ZIndex=math.max(40,host.ZIndex+3),Active=false,Visible=false})
        M.round(d,'pill');M.stroke(d,C.bg,2);M.make('UIScale',d,{Name='Scale'});d:SetAttribute('AllowOverlap',true);d:SetAttribute('RedDot',true)
    end
    d.Size=UDim2.fromOffset(size,size);d.Position=UDim2.fromOffset(cx,cy)
    local was=d:GetAttribute('On')==true;d:SetAttribute('On',true);d.Visible=true
    if not was and not M.reduced then local s=d.Scale;s.Scale=0
        local a=Tween:Create(s,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=1.15});a:Play()
        a.Completed:Once(function()if d:GetAttribute('On')then Tween:Create(s,TweenInfo.new(.08,Enum.EasingStyle.Quad),{Scale=1}):Play()end end)
    elseif d:FindFirstChild('Scale')then d.Scale.Scale=1 end
    return d
end

local Button={};Button.__index=Button
local function kindLook(b,kind)
    local f=b.face;local st=b.faceStroke
    f.BackgroundTransparency=0;st.Enabled=true;st.Thickness=1;st.Transparency=0;b.shade.Visible=false
    if kind=='pri'then f.BackgroundColor3=C.accent;st.Enabled=false;b.shade.Visible=true;b.ink=C.bg
    elseif kind=='out'then f.BackgroundColor3=C.accent;f.BackgroundTransparency=.94;st.Color=C.accent;st.Thickness=2;b.ink=C.ink
    elseif kind=='goldo'then f.BackgroundColor3=C.gold;f.BackgroundTransparency=.92;st.Color=C.gold;st.Thickness=2;b.ink=C.gold
    elseif kind=='ghost'then f.BackgroundTransparency=1;st.Enabled=false;b.ink=C.muted
    elseif kind=='dis'then f.BackgroundColor3=C.raised;st.Color=C.line;b.ink=C.dim
    elseif kind=='glass'then f.BackgroundColor3=Color3.fromRGB(12,17,24);f.BackgroundTransparency=.14;st.Color=C.line;st.Transparency=.1;b.ink=C.ink
    elseif kind=='dangero'then f.BackgroundColor3=C.danger;f.BackgroundTransparency=.94;st.Color=C.danger;st.Thickness=1;st.Transparency=.3;b.ink=C.danger
    elseif kind=='none'then f.BackgroundTransparency=1;st.Enabled=false;b.ink=C.ink
    else f.BackgroundColor3=C.raised;st.Color=C.line;b.ink=C.ink end
    b.baseFill=f.BackgroundColor3;b.baseAlpha=f.BackgroundTransparency;b.baseStroke=st.Color
    if b.label then b.label.TextColor3=b.ink end
    if b.iconImage and not b.iconColorFixed then b.iconImage.ImageColor3=b.ink end
end
function M.button(parent,name,opts,callback)
    opts=opts or {}
    local hit=M.make('TextButton',parent,{Name=name or 'Button20',Text='',BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Active=true,Selectable=true})
    local f=M.make('Frame',hit,{Name='Face',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(1,1),BorderSizePixel=0,Active=false})
    M.round(f,opts.r or 8)
    local scale=M.make('UIScale',f,{Name='Press'})
    local st=M.make('UIStroke',f,{Name='Stroke20',ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Thickness=1})
    pcall(function()st.BorderStrokePosition=Enum.BorderStrokePosition.Inner end)
    local shade=M.make('Frame',f,{Name='Depth',BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0,Size=UDim2.fromScale(1,1),BorderSizePixel=0,Active=false,Visible=false})
    M.round(shade,opts.r or 8)
    shade.ZIndex=f.ZIndex
    local b=setmetatable({button=hit,face=f,scale=scale,faceStroke=st,shade=shade,kind=opts.kind or 'plain',enabled=true,minHit=opts.hit or 44},Button)
    b.shadeGradient=M.make('UIGradient',shade,{Rotation=90})
    if opts.icon then b.iconImage=M.icon(f,opts.icon,opts.iconSize or 20,nil,'Icon');b.iconImage.ZIndex=f.ZIndex+1 end
    if opts.text then b.label=M.text(f,'Label',opts.text,opts.size or 16,nil,opts.weight or 800,Enum.TextXAlignment.Center);b.label.ZIndex=f.ZIndex+1 end
    b.gap=opts.gap or 8;b.iconSize=opts.iconSize or 20;b.size=opts.size or 16
    kindLook(b,b.kind)
    local hover=false
    local function to(v,t,style,dir)
        if M.reduced then scale.Scale=1;return end
        if b.pressTween then b.pressTween:Cancel()end
        b.pressTween=Tween:Create(scale,TweenInfo.new(t,style,dir or Enum.EasingDirection.Out),{Scale=v});b.pressTween:Play()
    end
    local function bright(on)
        if b.kind=='pri'then f.BackgroundColor3=on and b.baseFill:Lerp(Color3.new(1,1,1),.08)or b.baseFill
        elseif b.kind~='ghost'and b.kind~='none'then f.BackgroundTransparency=on and math.max(0,b.baseAlpha-.06)or b.baseAlpha end
    end
    hit.MouseEnter:Connect(function()if not b.enabled then return end;hover=true;if b.kind~='pri'and st.Enabled then st.Color=b.kind=='plain'and C.muted or b.baseStroke end;if not b.pressed then to(1.02,.08,Enum.EasingStyle.Quad)end end)
    hit.MouseLeave:Connect(function()hover=false;st.Color=b.baseStroke;if b.pressed then b.pressed=false;bright(false)end;to(1,.08,Enum.EasingStyle.Quad)end)
    hit.InputBegan:Connect(function(i)
        if not b.enabled then return end
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            b.pressed=true;if M.reduced then scale.Scale=1 else if b.pressTween then b.pressTween:Cancel()end;scale.Scale=.96 end;bright(true)
        end
    end)
    hit.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            if not b.pressed then return end;b.pressed=false;bright(false)
            if M.reduced then scale.Scale=1;return end
            scale.Scale=1.02;to(hover and 1.02 or 1,.12,Enum.EasingStyle.Back)
        end
    end)
    hit.Activated:Connect(function()
        if not b.enabled then
            if b.onRefuse then b.onRefuse()end
            M.refuse(b);return
        end
        if opts.sound~=false then require(script.Parent.ToyAudio).play(opts.sound or 'click')end
        local P=require(script.Parent.PressPending);P.current={button=hit,at=os.clock()}
        if callback then callback(b)end
        P.current=nil
    end)
    return b
end
function Button:place(x,y,w,h)
    local hw,hh=math.max(w,self.minHit),math.max(h,self.minHit)
    M.box(self.button,x-(hw-w)/2,y-(hh-h)/2,hw,hh)
    self.face.Size=UDim2.fromOffset(w,h);self.face.Position=UDim2.fromOffset(hw/2,hh/2)
    self.w,self.h=w,h
    local cut=math.clamp(1-3/math.max(h,1),0,1)
    self.shadeGradient.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(math.max(0,cut-.001),1),NumberSequenceKeypoint.new(cut,.82),NumberSequenceKeypoint.new(1,.82)})
    self:layoutContent();return self
end
function Button:layoutContent(align,padLeft)
    local w,h=self.w or 0,self.h or 0;if w<=0 then return end
    local iw=self.iconImage and self.iconSize or 0;local lw=self.label and math.min(M.width(self.label.Text,self.label.TextSize,self.label),w-16-(iw>0 and iw+self.gap or 0))or 0
    local total=iw+(iw>0 and lw>0 and self.gap or 0)+lw
    local x=align=='left'and(padLeft or 16)or math.floor((w-total)/2)
    if self.iconImage then M.box(self.iconImage,x,(h-iw)/2,iw,iw);x+=iw+self.gap end
    if self.label then M.box(self.label,x,0,math.max(lw+2,w-x-6),h);self.label.TextXAlignment=Enum.TextXAlignment.Left end
end
function Button:setText(t)if self.label and self.label.Text~=t then self.label.Text=t;self:layoutContent()end;return self end
function Button:setKind(kind)if self.kind~=kind then self.kind=kind;kindLook(self,kind)end;return self end
function Button:setEnabled(on,keepLook)
    on=on~=false;if self.enabled==on then return self end
    self.enabled=on;self.button:SetAttribute('Enabled',on)
    if not keepLook then if on then kindLook(self,self.kind)else local k=self.kind;kindLook(self,'dis');self.kind=k end end
    return self
end
function Button:destroy()self.button:Destroy()end

function M.refuse(target,lockChip,silent)
    local f=type(target)=='table'and target.face or target
    if not silent then require(script.Parent.ToyAudio).play('error')end
    if not f or M.reduced then return end
    local base=f:GetAttribute('ShakeBase');if not base then base=f.Position;f:SetAttribute('ShakeBase',base)end
    local token=(f:GetAttribute('ShakeToken')or 0)+1;f:SetAttribute('ShakeToken',token)
    task.spawn(function()
        for _,dx in ipairs({-6,5,-3,2,0})do
            if f:GetAttribute('ShakeToken')~=token then return end
            f.Position=base+UDim2.fromOffset(dx,0);task.wait(.035)
        end
        if f:GetAttribute('ShakeToken')==token then f.Position=base;f:SetAttribute('ShakeBase',nil)end
    end)
    if lockChip then M.punch(lockChip,1.08,.14)end
end
function M.punch(o,from,t)
    if M.reduced or not o then return end
    local s=o:FindFirstChild('Punch')or M.make('UIScale',o,{Name='Punch'})
    s.Scale=from or 1.06;Tween:Create(s,TweenInfo.new(t or .14,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
end
function M.confirm(b,silent)
    if not silent then require(script.Parent.ToyAudio).play('confirm')end
    if M.reduced then return end
    local s=b.scale;if b.pressTween then b.pressTween:Cancel()end
    s.Scale=1.06;b.pressTween=Tween:Create(s,TweenInfo.new(.14,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1});b.pressTween:Play()
end

local PROPS={Frame={'BackgroundTransparency'},TextLabel={'BackgroundTransparency','TextTransparency'},TextButton={'BackgroundTransparency','TextTransparency'},
    TextBox={'BackgroundTransparency','TextTransparency'},ImageLabel={'BackgroundTransparency','ImageTransparency'},ImageButton={'BackgroundTransparency','ImageTransparency'},
    ScrollingFrame={'BackgroundTransparency','ScrollBarImageTransparency'},UIStroke={'Transparency'}}
local function each(o,fn)fn(o);for _,d in ipairs(o:GetDescendants())do fn(d)end end
local function rest(o,prop)
    local key='Rest20_'..prop;local v=o:GetAttribute(key)
    if v==nil then v=o[prop];o:SetAttribute(key,v)end;return v
end
function M.rememberRest(o)each(o,function(d)local ps=PROPS[d.ClassName];if ps then for _,p in ipairs(ps)do d:SetAttribute('Rest20_'..p,d[p])end end end)end
function M.fade(o,visible,t,style,dir)
    if not o then return end
    t=t==0 and 0 or(M.reduced and .12 or(t or .12))
    local info=t>0 and TweenInfo.new(t,style or Enum.EasingStyle.Quad,dir or(visible and Enum.EasingDirection.Out or Enum.EasingDirection.In))
    each(o,function(d)local ps=PROPS[d.ClassName];if ps then
        for _,p in ipairs(ps)do local goal=visible and rest(d,p)or 1;if not visible then rest(d,p)end
            if t<=0 then d[p]=goal else Tween:Create(d,info,{[p]=goal}):Play()end end end end)
end
function M.appear(o,opt)
    opt=opt or {}
    local t=opt.t or .16
    local base=opt.home or o:GetAttribute('Home20')or o.Position;o:SetAttribute('Home20',base)
    local fresh=not o.Visible or o:GetAttribute('Moving20')==nil and o:GetAttribute('Shown20')~=true
    if fresh then if not opt.noFade then M.fade(o,false,0)end;if not M.reduced then o.Position=base+UDim2.fromOffset(opt.dx or 0,opt.dy or 0)end end
    o.Visible=true;o:SetAttribute('Moving20','in');o:SetAttribute('Shown20',true)
    if o:IsA('GuiButton')then o.Active=true end
    local function go()
        if o:GetAttribute('Moving20')~='in'then return end
        if M.reduced then o.Position=base;if not opt.noFade then M.fade(o,true,.12)end
        else
            Tween:Create(o,TweenInfo.new(t,opt.style or Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),{Position=base}):Play()
            if opt.scaleFrom then local s=o:FindFirstChild('Pop20')or M.make('UIScale',o,{Name='Pop20'});if fresh then s.Scale=opt.scaleFrom end
                Tween:Create(s,TweenInfo.new(t,opt.scaleStyle or Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),{Scale=1}):Play()end
            if not opt.noFade then M.fade(o,true,t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)end
        end
        task.delay(t,function()if o:GetAttribute('Moving20')=='in'then o:SetAttribute('Moving20',nil)end end)
    end
    if opt.delay and opt.delay>0 and not M.reduced then task.delay(opt.delay,go)else go()end
end
function M.leave(o,opt,done)
    opt=opt or {}
    if not o or not o.Visible then if done then done()end;return end
    local t=opt.t or .10
    if o:IsA('GuiButton')then o.Active=false end;o.Interactable=false
    o:SetAttribute('Moving20','out')
    local base=o:GetAttribute('Home20')or o.Position;o:SetAttribute('Home20',base)
    if not M.reduced then Tween:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=base+UDim2.fromOffset(opt.dx or 0,opt.dy or 0)}):Play()end
    if not opt.noFade then M.fade(o,false,t)end
    task.delay(M.reduced and .12 or t,function()
        if o:GetAttribute('Moving20')=='out'then o.Visible=false;o.Position=base;o:SetAttribute('Moving20',nil);o:SetAttribute('Shown20',false);if o:IsA('GuiButton')then o.Active=true end end
        o.Interactable=true
        if done then done()end
    end)
end
function M.rehome(o)o:SetAttribute('Home20',o.Position)end

local rollers=setmetatable({},{__mode='k'})
function M.roll(label,from,to,fmt,chip,t)
    fmt=fmt or function(n)return Theme.commas(math.floor(n+.5))end
    local r=rollers[label]
    if not r then
        r={value=M.make('NumberValue',label,{Name='Roll20'})};rollers[label]=r
        r.value.Changed:Connect(function()label.Text=r.fmt(r.value.Value)end)
    end
    r.fmt=fmt;if r.tween then r.tween:Cancel();r.tween=nil end
    if M.reduced or from==nil or from==to then r.value.Value=to;label.Text=fmt(to);return end
    r.value.Value=from
    r.tween=Tween:Create(r.value,TweenInfo.new(t or .45,t and t<=.2 and Enum.EasingStyle.Linear or Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Value=to});r.tween:Play()
    if chip and to>from then r.tween.Completed:Once(function(state)if state==Enum.PlaybackState.Completed then M.punch(chip,1.12,.16)end end)end
end

local Seg={};Seg.__index=Seg
function M.segment(parent,name,items,selected,onPick,opts)
    opts=opts or {}
    local f=M.make('Frame',parent,{Name=name or 'Segment',BackgroundColor3=C.bg,BorderSizePixel=0})
    M.round(f,opts.r or 8);M.stroke(f,C.line,1,0,true)
    local ind=M.make('Frame',f,{Name='On',BackgroundColor3=C.raised,BorderSizePixel=0,Active=false})
    M.round(ind,opts.innerR or 6);M.stroke(ind,C.line,1,0,true)
    local self=setmetatable({frame=f,on=ind,items=items,selected=selected,cells={},size=opts.size or 13,iconSize=opts.iconSize or 16,iconOn=opts.iconOn or C.gold,onPick=onPick},Seg)
    for i,it in ipairs(items)do
        local b=M.make('TextButton',f,{Name='Cell_'..tostring(it[1]),Text='',BackgroundTransparency=1,AutoButtonColor=false,BorderSizePixel=0,ZIndex=ind.ZIndex+1})
        local l=M.text(b,'Label',it[2],self.size,C.muted,700,Enum.TextXAlignment.Center);l.Size=UDim2.fromScale(1,1);l.ZIndex=b.ZIndex+1
        local icon;if it[3]then icon=M.icon(b,it[3],self.iconSize,C.muted,'Icon');icon.ZIndex=b.ZIndex+1 end
        b.Activated:Connect(function()
            if self.selected==it[1]then return end
            require(script.Parent.ToyAudio).play('click')
            self:select(it[1],true);if self.onPick then self.onPick(it[1])end
        end)
        self.cells[i]={button=b,label=l,icon=icon,id=it[1]}
    end
    return self
end
function Seg:place(x,y,w,h)
    M.box(self.frame,x,y,w,h);self.w,self.h=w,h
    local n=#self.items;local pad,gap=3,3;local cw=(w-pad*2-gap*(n-1))/n
    for i,c in ipairs(self.cells)do M.box(c.button,pad+(i-1)*(cw+gap),pad,cw,h-pad*2)
        c.label.TextSize=self.size
        if c.icon then
            local tw=M.width(c.label.Text,self.size,c.label);local is=self.iconSize;local total=is+6+tw;local x0=math.floor((cw-total)/2)
            M.box(c.icon,x0,(h-pad*2-is)/2,is,is);M.box(c.label,x0+is+6,0,tw+2,h-pad*2);c.label.TextXAlignment=Enum.TextXAlignment.Left
        end
    end
    self.cw=cw;self:select(self.selected,false);return self
end
function Seg:select(id,animate)
    self.selected=id;local idx=1
    for i,c in ipairs(self.cells)do local on=c.id==id;if on then idx=i end;c.label.TextColor3=on and C.ink or C.muted;if c.icon then c.icon.ImageColor3=on and self.iconOn or C.muted end end
    if not self.cw then return end
    local goal=UDim2.fromOffset(math.floor(3+(idx-1)*(self.cw+3)+.5),3);local size=UDim2.fromOffset(math.floor(self.cw+.5),self.h-6)
    self.on.Size=size
    if animate and not M.reduced then Tween:Create(self.on,TweenInfo.new(.16,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut),{Position=goal}):Play()else self.on.Position=goal end
end

function M.amount(parent,name,kind,text,size,color,opts)
    opts=opts or {}
    local f=M.make('Frame',parent,{Name=name or 'Amount',BackgroundTransparency=1,BorderSizePixel=0})
    local key=kind=='coin'and 'coinGold'or kind=='xp'and 'xpStar'or kind=='ticket'and 'ticket'or kind
    local icon=M.icon(f,key,size,kind=='ticket'and(opts.color or M.rarity.epic)or(kind=='coin'or kind=='xp')and Color3.new(1,1,1)or color,'Icon')
    local l=M.num(f,'Value',text,size,color or C.ink)
    local tw=M.width(text,size,l)
    M.box(icon,0,0,size,size);M.box(l,size+5,0,tw+2,size)
    local w=size+5+tw;f.Size=UDim2.fromOffset(w,size);return f,w,l,icon
end

function M.avatar(parent,name,userId,size,ring,ringWidth)
    local img=M.make('ImageLabel',parent,{Name=name or 'Avatar',BackgroundColor3=Color3.fromRGB(31,58,77),BorderSizePixel=0,ScaleType=Enum.ScaleType.Crop})
    M.round(img,'pill');if ring then M.stroke(img,ring,ringWidth or 2)end
    if userId then img.Image='rbxthumb://type=AvatarHeadShot&id='..tostring(userId)..'&w=150&h=150'end
    img.Size=UDim2.fromOffset(size or 30,size or 30);return img
end

function M.screenRoot(hub,body,name)
    local root=hub.root;local s=Theme.scale or 1
    local w,h=root.AbsoluteSize.X/s,root.AbsoluteSize.Y/s
    local card=hub.pageCard;local cx,cy=card.Position.X.Offset,card.Position.Y.Offset
    local bx,by=body.Position.X.Offset,body.Position.Y.Offset
    local pad=body:FindFirstChild('ContentInset');local pl,pt=pad and pad.PaddingLeft.Offset or 0,pad and pad.PaddingTop.Offset or 0
    local f=M.make('Frame',body,{Name=name or 'Screen20',BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(-(cx+bx+pl),-(cy+by+pt)),Size=UDim2.fromOffset(w,h)})
    local fmt=w<600 and 'pt'or h<500 and 'ph'or 'pc'
    return f,w,h,fmt
end

local dashImages={}
local function dashImage(vertical)
    local key=vertical and 'v'or 'h'
    if dashImages[key]==nil then
        local ok,img=pcall(function()
            local size=vertical and Vector2.new(1,6)or Vector2.new(6,1)
            local e=game:GetService('AssetService'):CreateEditableImage({Size=size});local b=buffer.create(24)
            for i=0,5 do buffer.writeu32(b,i*4,i<3 and 0xFFFFFFFF or 0x00FFFFFF)end
            e:WritePixelsBuffer(Vector2.zero,size,b);return e
        end)
        dashImages[key]=ok and img or false
    end
    return dashImages[key]
end
function M.dashBox(parent,name,color,alpha,r,thick)
    local f=M.make('Frame',parent,{Name=name or 'Dashed',BackgroundTransparency=1,BorderSizePixel=0})
    thick=thick or 1;r=r or 8
    local edges={}
    for _,side in ipairs({'Top','Bottom','Left','Right'})do
        local v=side=='Left'or side=='Right';local img=dashImage(v)
        local e=M.make('ImageLabel',f,{Name=side,BackgroundTransparency=1,ScaleType=Enum.ScaleType.Tile,TileSize=UDim2.fromOffset(v and thick or 6,v and 6 or thick),ImageColor3=color or C.line,ImageTransparency=alpha or 0,ResampleMode=Enum.ResamplerMode.Pixelated})
        if img then e.ImageContent=Content.fromObject(img)else e.Image='';e.BackgroundTransparency=alpha or 0;e.BackgroundColor3=color or C.line end
        edges[side]=e
    end
    local function place()
        local w,h=f.Size.X.Offset,f.Size.Y.Offset
        M.box(edges.Top,r,0,math.max(0,w-r*2),thick);M.box(edges.Bottom,r,h-thick,math.max(0,w-r*2),thick)
        M.box(edges.Left,0,r,thick,math.max(0,h-r*2));M.box(edges.Right,w-thick,r,thick,math.max(0,h-r*2))
    end
    f:GetPropertyChangedSignal('Size'):Connect(place);place()
    return f
end

function M.ring(parent,name,size,ratio,color,thick,track)
    local f=M.make('Frame',parent,{Name=name or 'Ring',BackgroundTransparency=1,Size=UDim2.fromOffset(size,size)})
    thick=thick or 6
    local function circle(p)local c=M.make('Frame',p,{BackgroundTransparency=1,Size=UDim2.fromOffset(size-thick,size-thick),Position=UDim2.fromOffset(thick/2,thick/2)});M.round(c,'pill')
        local s=M.make('UIStroke',c,{Thickness=thick});return c,s end
    local _,ts=circle(f);ts.Color=track or C.raised
    ratio=math.clamp(ratio or 0,0,1)
    for half=0,1 do if (half==0 and ratio>0)or (half==1 and ratio>.5)then
        local clip=M.make('Frame',f,{Name='Half'..half,BackgroundTransparency=1,ClipsDescendants=true,Position=UDim2.fromOffset(half==0 and size/2 or 0,0),Size=UDim2.fromOffset(size/2,size)})
        local c,s=circle(clip);c.Position=UDim2.fromOffset((half==0 and -size/2 or 0)+thick/2,thick/2);s.Color=color or C.accent
        local g=M.make('UIGradient',s,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(.501,1),NumberSequenceKeypoint.new(1,1)})})
        if half==0 then g.Rotation=math.min(ratio,.5)/.5*180 else g.Rotation=180+math.clamp(ratio-.5,0,.5)/.5*180 end
    end end
    return f
end

function M.line(parent,name,x1,y1,x2,y2,thick,color,alpha)
    local dx,dy=x2-x1,y2-y1;local len=math.sqrt(dx*dx+dy*dy)
    local l=M.make('Frame',parent,{Name=name or 'Line',AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=color or C.gold,BackgroundTransparency=alpha or 0,BorderSizePixel=0,Active=false,
        Position=UDim2.fromOffset((x1+x2)/2,(y1+y2)/2),Size=UDim2.fromOffset(len+thick,thick),Rotation=math.deg(math.atan2(dy,dx))})
    M.round(l,'pill');return l
end
function M.curve(parent,name,p0,p1,p2,p3,thick,color,alpha,dotted,gap)
    local holder=M.make('Frame',parent,{Name=name or 'Curve',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Active=false})
    local function at(t)local u=1-t;return p0*u*u*u+p1*3*u*u*t+p2*3*u*t*t+p3*t*t*t end
    local pts={at(0)};local lens={0};local total=0
    for i=1,48 do local p=at(i/48);total+=(p-pts[#pts]).Magnitude;table.insert(pts,p);table.insert(lens,total)end
    local function point(d)for i=2,#lens do if lens[i]>=d then local k=(d-lens[i-1])/math.max(.001,lens[i]-lens[i-1]);return pts[i-1]:Lerp(pts[i],k)end end;return pts[#pts]end
    if dotted then
        local step=gap or 10;local d=step/2
        while d<total do local p=point(d);local s=thick
            local dot=M.make('Frame',holder,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(p.X,p.Y),Size=UDim2.fromOffset(s,s),BackgroundColor3=color,BackgroundTransparency=alpha or 0,BorderSizePixel=0});M.round(dot,'pill')
            d+=step end
    else
        local n=math.clamp(math.floor(total/8),6,40);local prev=point(0)
        for i=1,n do local p=point(total*i/n);M.line(holder,'Seg'..i,prev.X,prev.Y,p.X,p.Y,thick,color,alpha);prev=p end
    end
    return holder
end

function M.map(parent,name,key,w,h,r,dim)
    local f=M.make('Frame',parent,{Name=name or 'Map',BackgroundColor3=C.ocean,BorderSizePixel=0,Size=UDim2.fromOffset(w,h)})
    M.round(f,r or 6)
    if key and require(script.Parent.Parent.Maps.MapLoader).meta(key)then
        local Raster=require(script.Parent.RasterMap);local Maps=require(script.Parent.Parent.Maps.MapLoader)
        local ras=Raster.new(f,math.min(256,math.max(64,math.floor(w))),math.min(160,math.max(40,math.floor(h))));ras:setPreview(Maps.preview(key))
        local img=f:FindFirstChild('MapRaster');if img then M.round(img,r or 6)end
        task.defer(function()if f.Parent then
            local mw,mh=ras.map and ras.map.meta.width,ras.map and ras.map.meta.height;local aspect=w/math.max(1,h)
            if mw and mh then local vw=math.min(mw,mh*aspect);ras.view={x=(mw-vw)/2,y=(mh-vw/aspect)/2,w=vw,h=vw/aspect}else ras:fit()end
            ras:draw();local i2=f:FindFirstChild('MapRaster');if i2 then M.round(i2,r or 6)end end end)
        f.Destroying:Once(function()ras:destroy()end)
    end
    if dim then local d=M.make('Frame',f,{Name='Dim',BackgroundColor3=Color3.fromRGB(8,10,14),BackgroundTransparency=1-dim,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=f.ZIndex+1});M.round(d,r or 6)end
    return f
end
function M.fadeBox(parent,name,color,topA,bottomA,r,mid,midA)
    local f=M.make('Frame',parent,{Name=name or 'Fade',BackgroundColor3=color or Color3.fromRGB(8,10,14),BorderSizePixel=0,Size=UDim2.fromScale(1,1)})
    M.round(f,r or 10)
    local keys={NumberSequenceKeypoint.new(0,1-topA)};if mid then table.insert(keys,NumberSequenceKeypoint.new(mid,1-(midA or topA)))end;table.insert(keys,NumberSequenceKeypoint.new(1,1-bottomA))
    M.make('UIGradient',f,{Rotation=90,Transparency=NumberSequence.new(keys)});return f
end

function M.scrim(name,alpha,display)
    local pg=game:GetService('Players').LocalPlayer:WaitForChild('PlayerGui')
    local g=pg:FindFirstChild(name or 'Scrim20')
    if not g then
        g=M.make('ScreenGui',pg,{Name=name or 'Scrim20',ResetOnSpawn=false,IgnoreGuiInset=true,ScreenInsets=Enum.ScreenInsets.None,DisplayOrder=display or 40,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
        M.make('Frame',g,{Name='Dim',Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(4,7,11),BackgroundTransparency=1,BorderSizePixel=0,Active=false})
    end
    local d=g.Dim;d:SetAttribute('Alpha',alpha or .45);return g,d
end
function M.scrimShow(name,on,alpha,t)
    local _,d=M.scrim(name,alpha);local goal=on and(alpha or d:GetAttribute('Alpha')or .45)or 1
    d.Active=on;Tween:Create(d,TweenInfo.new(M.reduced and .12 or(t or .12),Enum.EasingStyle.Quad,on and Enum.EasingDirection.Out or Enum.EasingDirection.In),{BackgroundTransparency=goal}):Play()
    return d
end

return M
