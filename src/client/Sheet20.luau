local K=require(script.Parent.Kit20)
local Tween=game:GetService('TweenService')
local C=K.colors
local M={}
M.BG=Color3.fromRGB(15,21,29)
M.DIM=Color3.fromRGB(3,6,10)
M.PAGE=Color3.fromRGB(7,10,14)
M.MODE={ffa=Color3.fromRGB(142,184,255),teams=Color3.fromRGB(196,176,255),coop=C.ally}
M.MODEFILL={ffa=Color3.fromRGB(59,130,246),teams=Color3.fromRGB(139,92,246),coop=C.ally}
M.SIZE={friends={760,520},custom={860,540},customRules={760,520},customCode={760,520},joinCode={560,320},watch={960,560},board={760,520}}
function M.format(w,h)return w<600 and 'pt'or h<500 and 'ph'or 'pc'end
function M.rect(kind,w,h,fmt,bottom)
    bottom=bottom or 0
    if fmt=='pc'then
        local s=M.SIZE[kind]or M.SIZE.friends
        local sw,sh=math.min(s[1],w-48),math.min(s[2],h-58-16-bottom)
        local sy=math.floor((h-sh)/2+20);sy=math.max(66,math.min(sy,h-bottom-8-sh))
        return math.floor((w-sw)/2),sy,sw,sh
    elseif fmt=='ph'then return 12,50,w-24,h-58-bottom end
    return 0,0,w,h
end
function M.band(h,lift)return 64,h-58-(lift or 0)-8 end

function M.iconButton(parent,name,icon,side,iconSize,fn,color)
    local b=K.button(parent,name,{kind='plain',icon=icon,iconSize=iconSize},fn)
    b.faceStroke.Enabled=false;b.iconColorFixed=true;b.iconImage.ImageColor3=color or C.muted
    b:place(0,0,side,side);return b
end
function M.head(parent,fmt,sw,title,onClose,opts)
    opts=opts or {}
    local pt,ph=fmt=='pt',fmt=='ph'
    local pad=pt and 16 or ph and 12 or 24;local inset=pt and 0 or 1
    local y=pt and 66 or ph and 9 or 15;local rh=pt and 40 or ph and 30 or 40
    local ts=pt and 22 or ph and 18 or 24
    local x0=pad+inset
    local h={pad=pad,y=y,h=rh,x=x0,right=sw-inset-pad,fmt=fmt}
    if opts.back then
        local bs=pt and 40 or ph and 32 or 40
        h.back=M.iconButton(parent,'Back','back',bs,pt and 18 or ph and 16 or 20,opts.back)
        h.back:place(x0,y+(rh-bs)/2,bs,bs);x0+=bs+8
    end
    h.title=K.text(parent,'Title',title,ts,C.ink,800)
    if onClose then
        local xs=pt and 40 or ph and 32 or 40
        h.close=M.iconButton(parent,'Close','x',xs,pt and 18 or ph and 16 or 20,onClose)
        h.close:place(h.right-xs,y+(rh-xs)/2,xs,xs);h.right-=xs+(pt and 8 or 10)
    end
    local tw=K.width(title,ts,h.title)
    K.box(h.title,x0,y,math.min(tw+4,h.right-x0),rh);h.titleEnd=x0+tw+4
    return h
end
function M.headButton(parent,name,fmt,icon,text,fn,count,countKind)
    local pt,ph=fmt=='pt',fmt=='ph'
    local hgt=pt and 40 or ph and 32 or 40;local fs=pt and 13 or ph and 12 or 14;local is=pt and 15 or ph and 14 or 16
    local b=K.button(parent,name,{kind='plain',r=8},fn)
    local x=pt and 11 or 12
    local ic=K.icon(b.face,icon,is,C.ink,'Icon');K.box(ic,x,(hgt-is)/2,is,is);x+=is+6
    local l=K.text(b.face,'Label',text,fs,C.ink,800);local lw=K.width(text,fs,l);K.box(l,x,0,lw+2,hgt);x+=lw+2
    if count then
        x+=4
        local chip,cw=K.chip(b.face,'Count',count,countKind or 'live',{size=11,height=18,icon=false})
        chip.Position=UDim2.fromOffset(x,math.floor((hgt-18)/2));x+=cw
    end
    x+=pt and 11 or 12
    b:place(0,0,x,hgt);b.width=x
    return b,x
end

function M.modeChip(parent,name,text,color,fill,h,size,tint)
    local f=K.make('Frame',parent,{Name=name or 'Mode',BackgroundColor3=fill or color,BackgroundTransparency=1-(tint or .2),BorderSizePixel=0})
    K.round(f,4)
    local l=K.text(f,'Text',text,size,color,700);local tw=K.width(text,size,l)
    K.box(l,6,0,tw+2,h);f.Size=UDim2.fromOffset(tw+12,h)
    return f,tw+12
end

local Seg={};Seg.__index=Seg
local function numberCell(self,b,it)
    local spec=it.input
    K.round(b,6)
    local dash=K.dashBox(b,'Dash',C.line,0,6,1);dash.ZIndex=2
    local solid=K.stroke(b,C.accent,1,0,true);solid.Enabled=false
    local box=K.make('TextBox',b,{Name='Input',Text=it[2],PlaceholderText='직접',ClearTextOnFocus=false,TextSize=self.size,TextColor3=C.ink,PlaceholderColor3=C.muted,
        BackgroundTransparency=1,BorderSizePixel=0,TextXAlignment=Enum.TextXAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=3})
    local font=K.fonts[700];if font then box.FontFace=font end
    local digits=#tostring(spec.max)
    local function preset(n)for _,x in ipairs(self.items)do if x[1]==n and not x.input then return n end end;return nil end
    local before
    local cell={button=b,label=box,id=it[1],input=true,width=spec.width or 64}
    function cell.show(on)
        if not on and not box:IsFocused()and box.Text~=''then box.Text=''end
        solid.Enabled=on;dash.Visible=not on
    end
    box.Focused:Connect(function()before=self.selected end)
    box:GetPropertyChangedSignal('Text'):Connect(function()
        local d=box.Text:gsub('%D',''):sub(1,digits);if d~=box.Text then box.Text=d;return end
        if box:IsFocused()then if d==''then self:select(before,false)else self:select(preset(tonumber(d))or it[1],false)end end
    end)
    box.FocusLost:Connect(function()
        if not box:IsDescendantOf(game)then return end
        local n=tonumber(box.Text)
        if not n then box.Text='';self:select(before,false);return end
        n=math.clamp(math.floor(n),spec.min,spec.max)
        local p=preset(n);box.Text=p and ''or tostring(n);self:select(p or it[1],false)
        require(script.Parent.ToyAudio).play('click')
        if self.onPick then self.onPick(n)end
    end)
    return cell
end
function M.segment(parent,name,items,selected,onPick,opts)
    opts=opts or {}
    local f=K.make('Frame',parent,{Name=name or 'Segment',BackgroundColor3=C.bg,BorderSizePixel=0})
    K.round(f,8);K.stroke(f,C.line,1,0,true)
    local ind=K.make('Frame',f,{Name='On',BackgroundColor3=C.raised,BorderSizePixel=0,Active=false})
    K.round(ind,6);K.stroke(ind,C.line,1,0,true)
    local self=setmetatable({frame=f,on=ind,items=items,selected=selected,cells={},size=opts.size or 13,onPick=onPick,guard=opts.guard,lockSize=opts.lockSize or 11},Seg)
    for i,it in ipairs(items)do
        local b=K.make('TextButton',f,{Name='Cell_'..tostring(it[1]),Text='',BackgroundTransparency=1,AutoButtonColor=false,BorderSizePixel=0,ZIndex=2})
        if it.input then self.cells[i]=numberCell(self,b,it);continue end
        local l=K.text(b,'Label',it[2],self.size,C.muted,700,Enum.TextXAlignment.Center);l.ZIndex=3
        if it[2]:match('^%d+$')then l:SetAttribute('LocalizationSkip',true)end
        local chip;if it.lock then chip=K.lock(b,it.lock,0,0,self.lockSize);chip.ZIndex=3;for _,d in ipairs(chip:GetDescendants())do if d:IsA('GuiObject')then d.ZIndex=4 end end end
        b.Activated:Connect(function()
            if self.guard and self.guard(it[1])==false then K.refuse(f,chip);return end
            if self.selected==it[1]then return end
            require(script.Parent.ToyAudio).play('click')
            self:select(it[1],true);if self.onPick then self.onPick(it[1])end
        end)
        self.cells[i]={button=b,label=l,chip=chip,id=it[1]}
    end
    return self
end
function Seg:place(x,y,w,h)
    K.box(self.frame,x,y,w,h);self.w,self.h=w,h
    local n=#self.items;local pad,gap=3,3
    local fixed,nf=0,0;for _,c in ipairs(self.cells)do if c.width then fixed+=c.width;nf+=1 end end
    local cw=(w-pad*2-gap*(n-1)-fixed)/math.max(1,n-nf)
    local cx=pad
    for _,c in ipairs(self.cells)do
        local width=c.width or cw
        K.box(c.button,cx,pad,width,h-pad*2);c.x,c.w=math.floor(cx+.5),math.floor(width+.5);cx+=width+gap
        c.label.TextSize=self.size
        if c.input then
            local dash=c.button:FindFirstChild('Dash');if dash then dash.Size=UDim2.fromOffset(c.w,h-pad*2)end
            K.box(c.label,0,0,width,h-pad*2)
        elseif c.chip then
            local tw=K.width(c.label.Text,self.size,c.label);local chw=c.chip.Size.X.Offset;local chh=c.chip.Size.Y.Offset
            local x0=math.floor((cw-tw-5-chw)/2)
            K.box(c.label,x0,0,tw+2,h-pad*2);c.label.TextXAlignment=Enum.TextXAlignment.Left
            c.chip.Position=UDim2.fromOffset(x0+tw+5,math.floor((h-pad*2-chh)/2))
        else K.box(c.label,0,0,cw,h-pad*2)end
    end
    self.cw=cw;self:select(self.selected,false);return self
end
function Seg:select(id,animate)
    self.selected=id;local cur
    for _,c in ipairs(self.cells)do
        local on=c.id==id;c.label.TextColor3=on and C.ink or C.muted
        if c.input then c.show(on)elseif on then cur=c end
    end
    self.on.Visible=cur~=nil
    if not self.cw or not cur then return end
    local goal=UDim2.fromOffset(cur.x,3)
    self.on.Size=UDim2.fromOffset(cur.w,self.h-6)
    if animate and not K.reduced then Tween:Create(self.on,TweenInfo.new(.16,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut),{Position=goal}):Play()else self.on.Position=goal end
end
function Seg:enable(on)
    self.enabled=on~=false
    for _,c in ipairs(self.cells)do c.button.Active=self.enabled;c.button.AutoButtonColor=false;c.label.TextTransparency=self.enabled and 0 or .5 end
end

function M.switch(parent,name,on,w,h,knob,inset,locked)
    local f=K.make('Frame',parent,{Name=name or 'Switch',BorderSizePixel=0,Size=UDim2.fromOffset(w,h)})
    K.round(f,'pill');local st=K.stroke(f,C.line,1,0,true)
    local k=K.make('Frame',f,{Name='Knob',BorderSizePixel=0,Size=UDim2.fromOffset(knob,knob)});K.round(k,'pill')
    local self={frame=f,knob=k,stroke=st,locked=locked==true}
    function self.set(v,animate)
        if self.locked then v=false end
        f.BackgroundColor3=v and C.accent or C.raised;st.Color=v and C.accent or C.line;k.BackgroundColor3=v and C.bg or self.locked and C.dim or C.muted
        local goal=UDim2.fromOffset(v and w-inset-knob or inset,math.floor((h-knob)/2))
        if animate and not K.reduced then Tween:Create(k,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=goal}):Play()else k.Position=goal end
    end
    self.set(on==true,false)
    return self
end

function M.scroll(parent,name,x,y,w,h)
    local s=K.make('ScrollingFrame',parent,{Name=name or 'List',BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.line,
        CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.Y,Active=true,ElasticBehavior=Enum.ElasticBehavior.WhenScrollable})
    K.box(s,x-4,y-4,w+8,h+8);K.scrollPad(s,4)
    return s
end
function M.canvas(s,height)s.CanvasSize=UDim2.fromOffset(0,math.max(0,math.ceil(height))+8)end

function M.stagger(list,first)
    if not first or K.reduced then return end
    for i,o in ipairs(list)do if i>6 then break end;K.rehome(o);o:SetAttribute('Shown20',false);K.appear(o,{dy=8,t=.14,delay=(i-1)*.03})end
end

function M.map(parent,name,key,w,h,r)
    local m=K.map(parent,name or 'Map',key,w,h,r)
    return m
end

local menuState={}
function M.closeMenu(now)
    local m=menuState.cur;menuState.cur=nil;if not m then return end
    m.catch:Destroy()
    if now or K.reduced then m.panel:Destroy();return end
    K.leave(m.panel,{dy=-6,t=.08},function()m.panel:Destroy()end)
end
function M.menu(lobby,anchor,items,opts)
    M.closeMenu(true);opts=opts or {}
    local root=lobby.frame;local scale=require(script.Parent.Theme).scale or 1
    local catch=K.make('TextButton',root,{Name='Menu20Catch',Text='',BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Size=UDim2.fromScale(1,1),ZIndex=60})
    catch.Activated:Connect(function()M.closeMenu()end)
    local fs=opts.size or 14;local rh=opts.rowH or 44;local pad=14
    local w=opts.width or 0
    for _,it in ipairs(items)do w=math.max(w,pad+(it.icon and 18+8 or 0)+K.width(it.text,fs)+pad+(it.value and K.width(it.value,fs)+12 or 0))end
    w=K.even(math.ceil(w)+1);local h=K.even(#items*rh+9)
    local p=K.make('Frame',root,{Name='Menu20',BackgroundColor3=C.raised,BorderSizePixel=0,ZIndex=61,Active=true})
    K.round(p,8);K.stroke(p,C.line,1,0,true)
    local ap=(anchor.AbsolutePosition-root.AbsolutePosition)/scale;local as=anchor.AbsoluteSize/scale
    local RW,RH=root.AbsoluteSize.X/scale,root.AbsoluteSize.Y/scale
    local x=math.clamp(ap.X+as.X-w,8,math.max(8,RW-w-8));local y=ap.Y+as.Y+6
    if y+h>RH-8 then y=math.max(8,ap.Y-h-6)end
    K.boxCentre(p,x,y,w,h)
    for i,it in ipairs(items)do
        local ry=4+(i-1)*rh
        local row
        if it.fn then
            row=K.make('TextButton',p,{Name='Item'..i,Text='',BackgroundColor3=C.ink,BackgroundTransparency=1,AutoButtonColor=false,BorderSizePixel=0,ZIndex=62})
            row.MouseEnter:Connect(function()row.BackgroundTransparency=.95 end);row.MouseLeave:Connect(function()row.BackgroundTransparency=1 end)
            row.Activated:Connect(function()require(script.Parent.ToyAudio).play('click');M.closeMenu();it.fn()end)
        else row=K.make('Frame',p,{Name='Line'..i,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=62})end
        K.round(row,6);K.box(row,4,ry,w-8,rh)
        local tx=pad-4
        if it.icon then local ic=K.icon(row,it.icon,18,it.iconColor or C.muted,'Icon');ic.ZIndex=63;K.box(ic,tx,(rh-18)/2,18,18);tx+=26 end
        local t=K.text(row,'Text',it.text,fs,it.muted and C.muted or it.ink or C.ink,it.muted and 700 or 800);t.ZIndex=63;K.box(t,tx,0,w-8-tx-pad+4,rh)
        if it.value then local v=K.text(row,'Value',it.value,fs,C.muted,700,Enum.TextXAlignment.Right);v.ZIndex=63;K.box(v,tx,0,w-8-tx-pad+4,rh)end
        if it.check then local c=K.icon(row,'check',16,C.accent,'Check');c.ZIndex=63;K.box(c,w-8-pad+4-16,(rh-16)/2,16,16)end
    end
    menuState.cur={panel=p,catch=catch}
    K.appear(p,{dy=-6,scaleFrom=.96,t=.12})
    return p
end
return M
