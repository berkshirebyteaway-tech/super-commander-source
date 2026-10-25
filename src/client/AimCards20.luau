local K=require(script.Parent.Kit20)
local UI=require(script.Parent.Theme)
local U=require(script.Parent.Parent.Core.UnitRules)
local Hot=require(script.Parent.HotbarIcons)
local Step=require(script.Parent.TelemetryStep)
local L=require(script.Parent.Localization)
local C=K.colors
local M={}
local function touch()return require(script.Parent.InputMode).touch()end
local function format(w,h)
    local t=touch()
    if not t or require(script.Parent.Parent.Core.InterfacePlacement).tablet(w,h,t)then return 'pc'end
    return h>w and 'pt'or 'ph'
end
local function glass(f)
    for _,s in ipairs(f:GetChildren())do if s:IsA('UIStroke')and s.Name~='Stroke20'then s.Enabled=false end end
    f.BackgroundColor3=Color3.fromRGB(12,17,24);f.BackgroundTransparency=.06;K.round(f,12);K.stroke(f,C.line,1,.1,true)
end
local function rises(f)
    if f:GetAttribute('Rise20')then return end;f:SetAttribute('Rise20',true)
    f:GetPropertyChangedSignal('Visible'):Connect(function()
        if f.Visible and f:GetAttribute('Moving20')~='in'then f:SetAttribute('Shown20',false);K.appear(f,{dy=8,t=.12,style=Enum.EasingStyle.Quad})end
    end)
end
function M.ghost(f,dx,dy,t)
    if K.reduced or not f.Visible then return end
    local g=f:Clone();g.Name=f.Name..'Ghost';g.Parent=f.Parent;g.Active=false;g:SetAttribute('Moving20',nil);g:SetAttribute('Shown20',true)
    for _,o in ipairs(g:GetDescendants())do if o:IsA('GuiButton')then o.Active=false end end
    g:SetAttribute('Home20',g.Position);K.leave(g,{dx=dx or 0,dy=dy or 8,t=t or .08},function()g:Destroy()end)
end
local function text(parent,name,s,size,color,weight)local l=K.text(parent,name,s,size,color,weight);l.ZIndex=parent.ZIndex+2;return l end
local function row(card,w,h,parts,buttons)
    local x=12
    K.box(parts.icon,x,math.floor((h-parts.iconSize)/2),parts.iconSize,parts.iconSize);x+=parts.iconSize+10
    local nw=K.width(L.text(parts.name.Text),15,parts.name)
    local sw=parts.sub and parts.sub.Visible and K.width(parts.sub.Text,11,parts.sub)or 0
    local colW=math.max(nw,sw)+4
    if parts.sub and parts.sub.Visible then
        local top=math.floor((h-34)/2);K.box(parts.name,x,top,colW,19);K.box(parts.sub,x,top+20,colW,14)
    else K.box(parts.name,x,0,colW,h)end
    x+=colW+10
    K.box(parts.coin,x,math.floor((h-15)/2),15,15);x+=15+5
    local pw=K.width(parts.price.Text,15,parts.price)+4;K.box(parts.price,x,0,pw,h);x+=pw
    local right=w-4
    for _,b in ipairs(buttons)do if b.button.Visible then
        right-=b.bw;b:place(right,math.floor((h-b.bh)/2),b.bw,b.bh);right-=8
    end end
    local room=right-x;if room<0 then parts.name.Size=UDim2.fromOffset(math.max(20,colW+room),parts.name.Size.Y.Offset)end
end

function M.nuke(self)
    if self.n20 then return self.n20 end
    local bar=self.bar;local n={};self.n20=n
    for _,o in ipairs(bar:GetChildren())do if o:IsA('GuiObject')then o.Visible=false;o:SetAttribute('V1',true)end end
    n.icon=Hot.create(bar,'AtomBomb',22,C.danger);n.icon.ZIndex=bar.ZIndex+2;n.iconSize=22
    n.name=text(bar,'Name20','',15,C.ink,800);n.sub=text(bar,'Sub20','',11,C.muted,700)
    n.coin=K.icon(bar,'coinGold',15,Color3.new(1,1,1),'Coin20');n.coin.ZIndex=bar.ZIndex+2
    n.price=K.num(bar,'Price20','',15,C.gold);n.price.ZIndex=bar.ZIndex+2
    local function btn(name,opts,fn)local b=K.button(bar,name,opts,fn);b.button.ZIndex=bar.ZIndex+3;b.face.ZIndex=bar.ZIndex+3;if b.label then b.label.ZIndex=bar.ZIndex+4 end;if b.iconImage then b.iconImage.ZIndex=bar.ZIndex+4 end;return b end
    n.fire=btn('Fire20',{kind='none',text='발사',size=16,weight=800,hit=36},function()
        local p=self.plan
        if not touch()then if self.target then self:click(self.target)end;self:status();return end
        if p and #(p.breaks or {})>0 and not(self.arm20 and os.clock()<self.arm20)then
            self.arm20=os.clock()+3;Step.step('match','nukeBreakPrompt',{kind=self.kind,count=#p.breaks})
            self.callbacks.notify('동맹 파기  한 번 더 눌러 발사',true);self:status();return
        end
        self.arm20=nil;self:fire()
    end)
    n.cancel=btn('Cancel20',{kind='plain',icon='x',iconSize=18,hit=36},function()self:stop();self.callbacks.cancel()end)
    n.cancel.iconColorFixed=true;n.cancel.iconImage.ImageColor3=C.muted
    n.flip=btn('Flip20',{kind='plain',text='반전',size=12,weight=800,hit=36},function()
        if self.kind~='MIRV'then self.up=not self.up;Step.step('match','nukeFlip',{kind=self.kind});self:recalculate(true)end
    end)
    n.amount=btn('Amount20',{kind='plain',text='×1',size=13,weight=800,hit=36},function()self:cycleAmount()end)
    glass(bar);rises(bar)
    return n
end
local function paintFire(b,on)
    if on then b.face.BackgroundTransparency=0;b.face.BackgroundColor3=C.danger;b.faceStroke.Enabled=false;b.label.TextColor3=C.ink end
end
function M.nukeStatus(self)
    local n=M.nuke(self);local p=self.plan;local t=touch()
    for _,o in ipairs(self.bar:GetChildren())do if o:GetAttribute('V1')then o.Visible=false end end
    if n.kind~=self.kind and self.kind then
        n.kind=self.kind;n.icon:Destroy();n.icon=Hot.create(self.bar,self.kind,22,C.danger);n.icon.ZIndex=self.bar.ZIndex+2
    end
    n.name.Text=U.names[self.kind]or ''
    n.sub.Text=p and (p.silo and (p.reason and string.format('준비 %d발, %s',p.ready,p.reason)or string.format('준비 %d발',p.ready))or p.reason or '')or (t and '지도 눌러 목표 고정'or '클릭 발사  우클릭 취소')
    n.sub.TextColor3=p and (p.risk or #(p.breaks or {})>0)and C.danger or C.muted;n.sub.Visible=n.sub.Text~=''
    n.price.Text=UI.number(p and p.cost or (self.state and self.state.costs and self.state.costs[self.kind])or 0)
    local stack=self.kind=='AtomBomb'and self:maxAmount()>1
    n.amount.button.Visible=stack;n.amount:setText(self.amountButton.Text)
    n.flip.button.Visible=self.kind~='MIRV';n.flip:setKind(self.up and 'plain'or 'out')
    local ready=p~=nil and p.valid and not self.pending and not(self.state and self.state.paused)
    local can=ready and (not t or self.locked==true and self.checked~=nil)
    local bc=self.breakConfirm;local again=t and self.arm20 and os.clock()<self.arm20 or not t and bc and os.clock()<bc.untilTime
    n.fire:setText(self.pending and '발사 중…'or again and '한 번 더'or stack and self.amount>1 and string.format('×%d 발사',self.amount)or '발사')
    n.fire:setEnabled(can==true);paintFire(n.fire,can==true)
    n.fire.button.Visible=t
    if self.w20 then M.nukeLayout(self)end
end
function M.nukeLayout(self,w,h,dockY)
    local n=M.nuke(self)
    if w then self.w20={w=w,h=h,dockY=dockY}end
    local s=self.w20;if not s then return end
    local fmt=format(s.w,s.h);local pc=fmt=='pc'
    local cw=pc and 380 or fmt=='ph'and 300 or s.w-20;local ch=pc and 60 or 44
    local bh=pc and 44 or 36
    local pos=UDim2.fromOffset(math.floor((s.w-cw)/2),math.floor((s.dockY or s.h)-8-ch))
    self.bar.Size=UDim2.fromOffset(cw,ch);self.bar:SetAttribute('Home20',pos)
    if self.bar:GetAttribute('Moving20')==nil then self.bar.Position=pos end
    n.fire.bw,n.fire.bh=pc and 100 or 72,bh;n.cancel.bw,n.cancel.bh=pc and 48 or 40,bh
    n.flip.bw,n.flip.bh=pc and 52 or 44,bh;n.amount.bw,n.amount.bh=pc and 48 or 40,bh
    row(self.bar,cw,ch,n,{n.fire,n.cancel,n.amount,n.flip})
    for _,b in ipairs({n.fire,n.flip,n.amount})do require(script.Parent.MatchSheet).fill20(b)end
end

local function buildCard(self)
    if self.b20 then return self.b20 end
    local f=self.card or K.make('Frame',self.bar.Parent,{Name='BuildCard20',BorderSizePixel=0,Visible=false,Active=true,ZIndex=22})
    glass(f);rises(f)
    local b={card=f,iconSize=20}
    b.name=text(f,'Name','',15,C.ink,800)
    b.coin=K.icon(f,'coinGold',15,Color3.new(1,1,1),'Coin');b.coin.ZIndex=f.ZIndex+2
    b.price=K.num(f,'Price','',15,C.gold);b.price.ZIndex=f.ZIndex+2
    local function btn(name,opts,fn)local x=K.button(f,name,opts,fn);x.button.ZIndex=f.ZIndex+3;x.face.ZIndex=f.ZIndex+3;if x.label then x.label.ZIndex=f.ZIndex+4 end;return x end
    b.cancel=btn('Cancel',{kind='plain',text='취소',size=14,weight=800,hit=44},function()
        M.ghost(f,0,8,.08);f.Visible=false;self.callbacks.cancel()
    end)
    b.build=btn('Build',{kind='pri',text='짓기',size=15,weight=800,hit=44},function()
        if not(self.preview and self.preview.valid)or not self.callbacks.confirm then return end
        local spot=self.spot20;local dy=-8
        if spot and spot.Visible then local c=f.AbsolutePosition+f.AbsoluteSize/2;local p=spot.AbsolutePosition+spot.AbsoluteSize/2;local d=(p-c);if d.Magnitude>1 then d=d.Unit*16;M.ghost(f,math.floor(d.X),math.floor(d.Y),.12);dy=nil end end
        if dy then M.ghost(f,0,dy,.12)end
        f.Visible=false;self.callbacks.confirm()
    end)
    self.b20=b;return b
end
function M.unpreview(self)
    local c=self.preview20;if not c then return end
    self.preview20=nil;c:SetAttribute('Preview20',nil);c.Interactable=true
end
function M.build(self)
    local guide=self.bar.Parent and self.bar.Parent:FindFirstChild('ActionGuidance')
    local a=self.action
    local want=not self.active and guide~=nil and guide.Visible and a~=nil and a~='inspect'and(U.structures[a]or a=='Warship')and self.selected==nil and self.state~=nil and self.state.phase=='playing'
    if not want and not self.b20 then return end
    local b=buildCard(self);local f=b.card
    if want~=f.Visible then f.Visible=want end
    if guide then
        local st=guide:FindFirstChildOfClass('UIStroke')
        if want then
            if guide:GetAttribute('Bg20')==nil then guide:SetAttribute('Bg20',guide.BackgroundTransparency)end
            guide.BackgroundTransparency=1;if st then st.Enabled=false end
            for _,o in ipairs(guide:GetChildren())do if o:IsA('GuiObject')and o.Visible then o.Visible=false;o:SetAttribute('Hid20',true)end end
        elseif guide:GetAttribute('Bg20')~=nil then
            guide.BackgroundTransparency=guide:GetAttribute('Bg20');guide:SetAttribute('Bg20',nil);if st then st.Enabled=true end
            for _,o in ipairs(guide:GetChildren())do if o:GetAttribute('Hid20')then o:SetAttribute('Hid20',nil);if o.Name~='AllWarships'then o.Visible=true end end end
        end
    end
    if not want then M.unpreview(self);return end
    if b.kind~=a then b.kind=a;if b.icon then b.icon:Destroy()end;b.icon=Hot.create(f,a,20,C.ink);b.icon.ZIndex=f.ZIndex+2 end
    b.name.Text=U.names[a]or a
    b.price.Text=UI.number(self.state.costs and self.state.costs[a]or 0)
    local s=self.w20;if not s then return end
    local fmt=format(s.w,s.h);local pc=fmt=='pc'
    local cw=pc and 360 or fmt=='ph'and 280 or s.w-20;local ch=pc and 60 or 44;local bh=pc and 44 or 36
    local pos=UDim2.fromOffset(math.floor((s.w-cw)/2),math.floor((s.dockY or s.h)-8-ch))
    f.Size=UDim2.fromOffset(cw,ch);f:SetAttribute('Home20',pos);if f:GetAttribute('Moving20')==nil then f.Position=pos end
    b.build.button.Visible=touch()
    local ready=self.preview~=nil and self.preview.valid==true and not self.preview.guess
    if touch()then
        local sh=self.bar.Parent and self.bar.Parent:FindFirstChild('ActionSheet')
        local conf=sh and sh.Visible and sh:FindFirstChild('Confirm')or nil
        if conf and conf~=self.preview20 then M.unpreview(self)end
        if conf then self.preview20=conf;conf:SetAttribute('Preview20',true);conf.Interactable=false end
        ready=conf~=nil and conf.Visible and conf.Active and conf:GetAttribute('Enabled')~=false
    end
    b.build:setEnabled(ready and not self.state.paused)
    b.cancel.bw,b.cancel.bh=pc and 84 or 60,bh;b.build.bw,b.build.bh=pc and 96 or 68,bh
    row(f,cw,ch,b,{b.build,b.cancel})
    for _,x in ipairs({b.cancel,b.build})do require(script.Parent.MatchSheet).fill20(x)end
end
local SPOT={pc={box=40,icon=20},touch={box=36,icon=18}}
function M.spot(self,point)
    local s=self.spot20
    if not point then if s then s.Visible=false end;return end
    local look=touch()and SPOT.touch or SPOT.pc
    if not s then
        s=K.make('Frame',self.overlay,{Name='BuildSpot20',AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(look.box,look.box),BackgroundTransparency=.88,BorderSizePixel=0,ZIndex=7,Active=false})
        K.round(s,8);self.spot20=s
        s:SetAttribute('Dash',true);K.dashBox(s,'Dash',C.accent,0,8,2)
    end
    if s.Size.X.Offset~=look.box then s.Size=UDim2.fromOffset(look.box,look.box);s:SetAttribute('Kind',nil)end
    s.Dash.Size=s.Size
    local ok=self.preview and self.preview.valid~=false
    local col=ok and C.accent or C.danger
    s.BackgroundColor3=col;for _,e in ipairs(s.Dash:GetChildren())do if e:IsA('ImageLabel')then e.ImageColor3=col;e.BackgroundColor3=col end end
    if s:GetAttribute('Kind')~=self.action then
        s:SetAttribute('Kind',self.action);local old=s:FindFirstChild('Icon');if old then old:Destroy()end
        local i=Hot.create(s,self.action,look.icon,col);i.Name='Icon';local at=(look.box-look.icon)/2;K.box(i,at,at,look.icon,look.icon);i.ZIndex=s.ZIndex+1
    end
    local icon=s:FindFirstChild('Icon');if icon then if icon:IsA('ImageLabel')then icon.ImageColor3=col end end
    s.Position=UDim2.fromOffset(math.floor(point.X+.5),math.floor(point.Y+.5));s.Visible=true
end
local REST=.25
local function over(f)
    if not f or not f.Visible then return false end
    local m=game:GetService('UserInputService'):GetMouseLocation()-game:GetService('GuiService'):GetGuiInset()
    local p,s=f.AbsolutePosition,f.AbsoluteSize
    return m.X>=p.X and m.X<p.X+s.X and m.Y>=p.Y and m.Y<p.Y+s.Y
end
function M.pointer(self)
    if touch()then return end
    local now=os.clock()
    local onBar=self.active and over(self.bar)
    if onBar and not self.over20 and self.target and not self.pending then
        local t=now-(self.targetAt or 0)>=REST and self.target or self.rest or self.target
        if t~=self.target then self.target=t;self.targetAt=now;self.locked=false;self.checked=nil;self.breakConfirm=nil;self:recalculate(false)end
    end
    self.over20=onBar
    local b=self.b20;if not b then return end
    local f=b.card;local tile=f.Visible and self.preview and self.preview.tile or nil
    if not f.Visible then b.tile=nil;b.at=nil;b.rest=nil;b.over=false;return end
    local onCard=over(f)
    if not onCard and not b.over and tile~=b.tile then
        if b.tile and now-(b.at or now)>=REST then b.rest=b.tile end;b.tile=tile;b.at=now
    end
    if onCard and not b.over then
        local t=b.tile and now-(b.at or now)>=REST and b.tile or b.rest or b.tile
        if t and t~=tile and self.callbacks.aim then self.callbacks.aim(t)end
    end
    b.over=onCard
end
return M
