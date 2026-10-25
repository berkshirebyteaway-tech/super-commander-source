local UI=require(script.Parent.Theme)
local Icons=require(script.Parent.HotbarIcons)
local Style=require(script.Parent.HudStyle)
local Placement=require(script.Parent.Parent.Core.InterfacePlacement)
local C=UI.colors
local M={};M.__index=M
M.HEIGHT=136
M.MIN_WIDTH=640
M.WIDTH=600
M.SHORTCUTS=184
M.PRESETS={.1,.2,.5,1}
M.STOPS={{.01,0},{.1,.1},{.2,.4},{.5,.7},{1,1}}
local Left,Right,Center=Enum.TextXAlignment.Left,Enum.TextXAlignment.Right,Enum.TextXAlignment.Center
function M.new(e,setFraction)
    local self=setmetatable({e=e,wide=false,phone=false,pcScale=1,decor={},phoneDecor={}},M)
    local c=e.controls
    local function keep(o)o.Visible=false;table.insert(self.decor,o);return o end
    self.goldBox=keep(UI.make("Frame",e.hud,{Name="GoldBox",BackgroundColor3=C.bg,BackgroundTransparency=.35,BorderSizePixel=0}));UI.corner(self.goldBox,3)
    self.goldStroke=UI.stroke(self.goldBox,C.gold,1)
    self.coin=Icons.create(self.goldBox,"Gold",18,C.gold);self.coin.Name="Coin"
    self.gain=keep(UI.label(e.hud,"GoldGain","",15,C.good));self.gain.Font=Enum.Font.BuilderSansBold;self.gain.TextWrapped=false;self.gain.TextXAlignment=Right
    self.gain.TextStrokeTransparency=.3;self.gain.TextStrokeColor3=C.bg;self.gain:SetAttribute("LocalizationSkip",true);self.gain.ZIndex=5
    self.attackBox=keep(UI.make("Frame",c,{Name="AttackBox",BackgroundColor3=C.bg,BackgroundTransparency=.35,BorderSizePixel=0}));UI.corner(self.attackBox,3);UI.stroke(self.attackBox,C.line,1)
    self.sword=Icons.create(self.attackBox,"Sword",16,C.ink);self.sword.Name="Sword"
    self.divider=keep(UI.make("Frame",c,{Name="HotbarDivider",BackgroundColor3=C.line,BorderSizePixel=0}))
    self.soldier=Icons.create(e.growthBadge,"Soldier",18,C.accent);self.soldier.Name="RateSoldier";self.soldier.Visible=false;self.soldier.ZIndex=6
    self.barSoldier=Icons.create(e.troopBar,"Soldier",18,C.bg);self.barSoldier.Name="BarSoldier";self.barSoldier.Visible=false;self.barSoldier.ZIndex=6
    self.setFraction=setFraction
    self.presets={}
    for i,v in ipairs(M.PRESETS)do
        local b=UI.make("TextButton",c,{Name="Share"..math.floor(v*100),Text=math.floor(v*100).."%",TextSize=13,Font=Enum.Font.BuilderSansBold,TextColor3=C.ink,
            BackgroundColor3=C.bg,BackgroundTransparency=.35,BorderSizePixel=0,AutoButtonColor=true,Active=true,Visible=false})
        UI.corner(b,3);b:SetAttribute("LocalizationSkip",true);b:SetAttribute("Fraction",v)
        local line=UI.stroke(b,C.line,1)
        b.Activated:Connect(function()require(script.Parent.ToyAudio).play("click");require(script.Parent.TelemetryStep).step("hud","ratioPreset",{value=math.floor(v*100+.5)});setFraction(v)end)
        self.presets[i]={root=b,line=line,value=v}
    end
    return self
end
function M:fits(w,touch,h)return Placement.desk(w,h or 0,touch)and w>=M.MIN_WIDTH end
function M:place(w,h,touch)
    local H20=require(script.Parent.Hud20)
    if H20.ENABLED then
        if self:fits(w,touch,h)then return H20.pc(self,w,h)end
        if self:phoneFits(w,h,touch)then return H20.phone(self,w,h)end
        if touch and h>w then return H20.portrait(self,w,h)end
        if touch then return H20.phone(self,w,h)end
        return H20.pc(self,w,h)
    end
    if self:fits(w,touch,h)then return self:layout(w,h)end
    if self:phoneFits(w,h,touch)then return self:phoneLayout(w,h)end
    self:restore()
end
function M:phoneFits(w,h,touch)return touch==true and h<500 and w>h and w>=560 end
function M:ratio(f)
    if not self.phone then return (f-.01)/.99 end
    local s=M.STOPS
    for i=2,#s do if f<=s[i][1]then local a,b=s[i-1],s[i];return a[2]+(f-a[1])/(b[1]-a[1])*(b[2]-a[2])end end
    return 1
end
function M:wheel(fraction,z)
    if self.v2 and self.v2.fmt then return require(script.Parent.Hud20).wheel(fraction,z)end
    return math.floor((fraction+(z>0 and .1 or -.1))*100+.5)/100
end
function M:fraction(x,width)
    if self.v2 and self.v2.fmt then return require(script.Parent.Hud20).fraction(self,x,width)end
    local t=math.clamp(x/math.max(1,width),0,1)
    if not self.phone then return math.clamp(math.floor(t*99+1+.5),1,100)/100 end
    local s=M.STOPS
    for i=2,#s do if math.abs(t-s[i][2])<=.04 then return s[i][1]end end
    for i=2,#s do if t<=s[i][2]then local a,b=s[i-1],s[i];local f=a[1]+(t-a[2])/(b[2]-a[2])*(b[1]-a[1]);return math.clamp(math.floor(f*100+.5),1,100)/100 end end
    return 1
end
function M:tone()
    local e=self.e;local falling=e.growthBadge:GetAttribute('Trend')=='falling'
    e.growthFace.BackgroundColor3=Style.colors.chip
    e.growthFace.BackgroundTransparency=.06
    local trend=e.growthBadge:GetAttribute('Trend')
    e.statsTroopsSub.TextColor3=falling and C.recruitmentSlow or trend=='rising'and C.recruitmentGrow or C.muted
    local edge=e.growthFace:FindFirstChildOfClass('UIStroke');if edge then edge.Color=e.statsTroopsSub.TextColor3 end
    if self.soldier then Icons.tint(self.soldier,e.statsTroopsSub.TextColor3)end
end
function M:skin()
    local e=self.e
    Style.chip(e.growthFace,'rate')
    local track=e.troopBar;Style.chip(track,nil);track.ClipsDescendants=true
    local fill=track:FindFirstChild('Fill');if fill then Style.fill(fill);Style.round(fill,6);fill.BackgroundColor3=Color3.new(1,1,1)end
    self.goldStroke=Style.chip(self.goldBox,'gold')
    Style.chip(self.attackBox,nil);self.attackBox.BackgroundTransparency=1
    local edge=self.attackBox:FindFirstChildOfClass('UIStroke');if edge then edge.Enabled=false end;self.sword.Visible=false
    e.statsTroopsSub.Font=Enum.Font.BuilderSansBold
    e.statsGold.TextColor3=C.gold
    e.growthIcon.Visible=false;e.growthArrow.Visible=false;self.soldier.Visible=true
    e.troopWatermark.Visible=false;e.filledWatermark.Visible=false
    self:tone()
    e.statsTroops:SetAttribute('AllowOverlap',true);e.filledTroops:SetAttribute('AllowOverlap',true)
    local knob=e.dispatchKnob;knob.BackgroundColor3=C.ink;Style.line(knob,C.accent,2);knob.ZIndex=4
    local trackLine=e.dispatchTrack;trackLine.BackgroundColor3=Style.colors.line
    local dfill=trackLine:FindFirstChild('Fill');if dfill then dfill.BackgroundColor3=C.accent end
end
function M:text(n)return self.pcScale<1 and math.max(n,Placement.PC_TEXT)or n end
function M:layout(w,h)
    local e=self.e;local H=M.HEIGHT;self.wide=true;self:leavePhone()
    for _,o in ipairs(self.decor)do o.Visible=true end
    self:skin()
    local s=Placement.PC_HUD;self.pcScale=s;local room=math.ceil(M.SHORTCUTS*Placement.PC_SCALE)
    local W=math.floor(math.min(M.WIDTH*Placement.PC_HUD_WIDE,w-12-room)/s);local sw=math.floor(W*s)
    local x=math.max(6,math.min(math.floor((w-sw)/2),w-room-sw));local pad=8
    self:scaleTo(s);UI.box(e.controls,x,h-math.ceil(H*s)-8,W,H);UI.box(e.hud,0,0,W,40)
    Style.round(e.controls,8);e.controls.BackgroundColor3=Style.colors.panel;e.controls.BackgroundTransparency=.08
    local line=e.controls:FindFirstChildOfClass('UIStroke');if line then line.Enabled=true;line.Color=Style.colors.line end
    e.statsLand.Visible=false;e.statsGoldSub.Visible=false;e.troopIcon.Visible=false
    e.dispatchIcon.Visible=false;e.goldIcon.Visible=false;e.dockDivider.Visible=false
    local y1,h1=8,32
    local rateW,goldW=104,116;local barX=pad+rateW+6;local barW=W-pad*2-rateW-goldW-12
    local badge=e.growthBadge
    UI.box(badge,pad,y1,rateW,h1);UI.box(e.growthFace,0,0,rateW,h1);e.growthFace.Visible=true
    e.statsTroopsSub.TextSize=self:text(15);self:group(self.soldier,e.statsTroopsSub,rateW,h1,16)
    local track=e.troopBar
    UI.box(track,barX,y1,barW,h1)
    for _,number in ipairs({e.statsTroops,e.filledTroops})do
        UI.box(number,28,0,barW-56,h1);number.TextSize=self:text(17);number.TextXAlignment=Center;number.Font=Enum.Font.BuilderSansBold;number.TextWrapped=false
    end
    self.barSoldier.Visible=true;UI.box(self.barSoldier,10,(h1-16)/2,16,16)
    e.filledTroops.Visible=true
    UI.box(self.goldBox,W-pad-goldW,y1,goldW,h1)
    e.statsGold.Parent=self.goldBox;e.statsGold.TextSize=self:text(16);e.statsGold.Font=Enum.Font.BuilderSansBold;e.statsGold.Visible=true
    self:group(self.coin,e.statsGold,goldW,h1,16)
    UI.box(self.gain,W-pad-goldW,y1-24,goldW-4,20);self.gainBase=self.gain.Position
    local y2,h2=y1+h1+6,28;local shareW=52
    UI.box(self.attackBox,pad,y2,shareW,h2);self.attackBox.Visible=true
    e.selectedInfo.Parent=self.attackBox;e.selectedInfo.Visible=true;UI.box(e.selectedInfo,0,0,shareW,h2)
    e.selectedInfo.TextSize=self:text(16);e.selectedInfo.TextXAlignment=Enum.TextXAlignment.Center;e.selectedInfo.TextColor3=C.ink;e.selectedInfo.TextScaled=false;self:amountLimit(self:text(16))
    e.selectedInfo.Text=math.floor((self.sendFraction or .2)*100+.5)..'%'
    for _,p in ipairs(self.presets)do p.root.Visible=false end
    local sx=pad+shareW+6;e.dispatchSlider.Visible=true;UI.box(e.dispatchSlider,sx,y2-4,W-pad-sx,h2+8)
    local tw=W-pad-sx-20;UI.box(e.dispatchTrack,10,(h2+8)/2-3,tw,6);e.dispatchKnob.Size=UDim2.fromOffset(16,16)
    self:ensureMarks()
    for i,m in ipairs(self.marks)do m.Visible=true;UI.box(m,math.floor(self:ratio(M.PRESETS[i])*tw)-1,-3,2,12)end
    local y3=y2+h2+8
    UI.box(self.divider,pad,y3-4,W-pad*2,1);self.divider.BackgroundColor3=Style.colors.line;self.divider.BackgroundTransparency=.4
    e.dock.compact=false;e.dock.grid=false;e.dock.bar=true;e.dock.phone=false;e.dock.barHeight=48;e.dock.reach=nil;e.dock.barText=self:text(13);e.dock:layout(pad,y3,W-pad*2,false)
    local menu=e.pauseButton;menu.Parent=e.controls;UI.box(menu,W+6,H-44,44,44);menu.TextSize=12
    return {x=x,width=sw,height=math.ceil(H*s)}
end
function M:ensureMarks()
    if self.marks then return end;self.marks={}
    for i=1,#M.PRESETS do self.marks[i]=UI.make("Frame",self.e.dispatchTrack,{Name="Mark"..i,BackgroundColor3=Style.colors.line,BorderSizePixel=0,ZIndex=2,Visible=false})end
end
function M:presetsIn(x,y,w,h,touch,pc,only)
    local n=#self.presets;local gap=touch and 1 or 6;local chip=touch and 48 or 46
    local both=not only and w>=n*chip+(n-1)*gap+(touch and 96 or 80)
    if not both then chip=math.floor((w-(n-1)*gap)/n)end
    if touch and chip<48 then gap=0;chip=math.floor(w/n)end
    local ch=math.min(h,touch and 48 or 28);local cy=y+math.floor((h-ch)/2)
    for i,p in ipairs(self.presets)do p.root.Visible=true;UI.box(p.root,x+(i-1)*(chip+gap),cy,chip,ch);p.root.TextSize=pc and self:text(chip<38 and 13 or 15)or chip<38 and 13 or 15 end
    self.e.dispatchSlider.Visible=both
    local used=n*chip+n*gap
    return {x=x+used,y=y,w=math.max(0,w-used),h=h}
end
function M:group(icon,label,w,h,size)
    self.groups=self.groups or {}
    local g={icon=icon,w=w,h=h,size=size};local first=self.groups[label]==nil;self.groups[label]=g
    local function place()
        local g=self.groups[label];if not g or not (self.wide or self.phone)then return end
        local tw=math.min(label.TextBounds.X,g.w-g.size-14);local x=math.max(4,math.floor((g.w-(g.size+5+tw))/2))
        UI.box(g.icon,x,(g.h-g.size)/2,g.size,g.size);UI.box(label,x+g.size+5,0,g.w-x-g.size-7,g.h);label.TextXAlignment=Left
    end
    if first then label:GetPropertyChangedSignal('TextBounds'):Connect(place)end
    place()
end
function M:amountLimit(n)
    local k=self.e.selectedInfo:FindFirstChildOfClass('UITextSizeConstraint');if k then k.MaxTextSize=n end
end
function M:goldChip(x,y,w,h)
    local e=self.e
    if not self.touchGold then self.touchGold=UI.make("Frame",e.hud,{Name="GoldSurface",BackgroundColor3=C.bg,BackgroundTransparency=.35,BorderSizePixel=0,ZIndex=0});UI.corner(self.touchGold,3);self.touchStroke=UI.stroke(self.touchGold,C.gold,1)end
    self.touchGold.Visible=true;UI.box(self.touchGold,x,y,w,h)
    e.statsGold.Parent=e.hud;UI.box(e.statsGold,x+4,y,w-8,h);e.statsGold.Font=Enum.Font.BuilderSansBold
end
function M:touchPlates(r)
    local e=self.e
    if self.touchGold then self.touchGold.Visible=false end
    if self.growthSurface then self.growthSurface.Visible=false end
    if not r then return end
    local py,ph,gw=r.plate.y,r.plate.h,r.growth.w
    if not self.growthSurface then self.growthSurface=UI.make("Frame",e.growthBadge,{Name="GrowthSurface",BackgroundColor3=C.bg,BackgroundTransparency=.35,BorderSizePixel=0,ZIndex=0});UI.corner(self.growthSurface,3)end
    self.growthSurface.Visible=true;UI.box(self.growthSurface,0,py,gw,ph)
    UI.box(e.growthFace,0,py,gw,ph)
    UI.box(e.growthIcon,3,py+(ph-12)/2,12,12);UI.box(e.growthArrow,16,py,13,ph);e.growthArrow.TextSize=16
    UI.box(e.statsTroopsSub,29,py,gw-31,ph)
    self:goldChip(r.gold.x,py,r.gold.w,ph)
end
M.PHONE={strip=48,bar=48,face=38,gap=4,scale=Placement.PHONE_SCALE}
function M:phoneLayout(w,h)
    local e=self.e;local P=M.PHONE;self.phone=true;self.wide=false;self.pcScale=1
    for _,o in ipairs(self.decor)do o.Visible=false end
    self:skin()
    local s=P.scale;local pad=8;local W=require(script.Parent.Parent.Core.InterfacePlacement).phoneHudWidth(w)
    local H=P.bar+P.gap+P.strip;local x=math.floor((w-W*s)/2)
    self:scaleTo(s);UI.box(e.controls,x,math.floor(h-H*s-6),W,H)
    e.controls.BackgroundTransparency=1;local line=e.controls:FindFirstChildOfClass('UIStroke');if line then line.Enabled=false end
    if not self.strip then
        self.strip=UI.make("Frame",e.controls,{Name="PhoneStrip",BorderSizePixel=0,ZIndex=0});table.insert(self.phoneDecor,self.strip)
        self.rateCell=UI.make("Frame",e.troopBar,{Name="RateCell",BorderSizePixel=0,ZIndex=5});table.insert(self.phoneDecor,self.rateCell)
    end
    self:ensureMarks()
    for _,o in ipairs(self.phoneDecor)do o.Visible=true end
    for _,m in ipairs(self.marks)do m.Visible=true end
    Style.chip(self.strip,nil,8);self.strip.BackgroundColor3=Style.colors.panel;self.strip.BackgroundTransparency=.06
    local sy=P.bar+P.gap;UI.box(self.strip,0,sy,W,P.strip)
    UI.box(e.hud,0,sy,W,P.strip)
    e.statsLand.Visible=false;e.statsGoldSub.Visible=false;e.troopIcon.Visible=false;e.dispatchIcon.Visible=false;e.goldIcon.Visible=false;e.dockDivider.Visible=false
    if self.touchGold then self.touchGold.Visible=false end
    if self.growthSurface then self.growthSurface.Visible=false end
    local ih=34;local iy=(P.strip-ih)/2
    local goldW=88;local shareW=0;local rateW=92;local g=4
    local presetW=#self.presets*48+(#self.presets-1)
    local barW=W-pad*2-goldW-presetW-g*2
    local sliderX=pad+barW+g;local sliderW=W-pad-goldW-g-sliderX
    local trackX=pad+rateW+g;local trackW=barW-rateW-g
    local track=e.troopBar;UI.box(track,trackX,iy,trackW,ih)
    self.badgeZ=self.badgeZ or e.growthBadge.ZIndex;e.growthBadge.ZIndex=6
    UI.box(e.growthBadge,pad,0,rateW,P.strip);UI.box(e.growthFace,0,iy,rateW,ih);e.growthFace.Visible=true
    Style.chip(e.growthFace,'rate',8);self.soldier.Visible=true;self.rateCell.Visible=false
    e.statsTroopsSub.TextSize=15;self:group(self.soldier,e.statsTroopsSub,rateW,P.strip,16);self:tone()
    for _,number in ipairs({e.statsTroops,e.filledTroops})do
        UI.box(number,8,0,trackW-16,ih);number.TextSize=16;number.TextXAlignment=Center;number.Font=Enum.Font.BuilderSansBold;number.TextWrapped=false
    end
    self.barSoldier.Visible=false
    e.filledTroops.Visible=false;e.statsTroops.ZIndex=6;e.statsTroops.TextStrokeColor3=Color3.new(0,0,0);e.statsTroops.TextStrokeTransparency=.35
    UI.box(self.attackBox,pad+barW+g,sy+iy,shareW,ih);self.attackBox.Visible=false
    e.selectedInfo.Parent=self.attackBox;e.selectedInfo.Visible=false;UI.box(e.selectedInfo,0,0,shareW,ih)
    e.selectedInfo.TextSize=15;e.selectedInfo.TextXAlignment=Center;e.selectedInfo.TextColor3=C.ink;e.selectedInfo.TextScaled=false;self:amountLimit(15)
    e.selectedInfo.LineHeight=.9
    for _,m in ipairs(self.marks)do m.Visible=false end
    for _,l in ipairs(self.tickLabels or {})do l.Visible=false end
    self:presetsIn(sliderX,sy,sliderW,P.strip,true);e.dispatchSlider.Visible=false
    for _,p in ipairs(self.presets)do p.root.ZIndex=4 end
    UI.box(self.goldBox,W-pad-goldW,iy,goldW,ih);self.goldBox.Visible=true
    e.statsGold.Parent=self.goldBox;e.statsGold.TextSize=16;e.statsGold.Font=Enum.Font.BuilderSansBold;e.statsGold.Visible=true
    self:group(self.coin,e.statsGold,goldW,ih,16)
    UI.box(self.gain,W-pad-goldW,-22,goldW-4,20);self.gain.Visible=true;self.gainBase=self.gain.Position
    e.dock.compact=false;e.dock.grid=false;e.dock.bar=true;e.dock.phone=true;e.dock.barHeight=P.face;e.dock.reach=P.bar;e.dock:layout(0,P.bar-P.face,W,true)
    return {x=x,width=math.floor(W*s),height=math.ceil(H*s)}
end
function M:scaleTo(s)
    if not self.uiScale then
        if s==1 then return end
        self.uiScale=UI.make("UIScale",self.e.controls,{Name="PhoneScale"})
    end
    self.uiScale.Scale=s
end
function M:shrink(x,full,w,h,screenH)
    local s=Placement.TOUCH_SCALE;if s>=1 then return x,w,h end;self:scaleTo(s)
    local sw,sh=math.floor(w*s),math.ceil(h*s);local sx=x+math.floor((full-sw)/2)
    UI.box(self.e.controls,sx,screenH-sh-8,w,h)
    return sx,sw,sh
end
function M:leavePhone()
    self.pcScale=1;self:scaleTo(1)
    if not self.phone then return end;self.phone=false
    local e=self.e;e.filledTroops.Visible=true;e.statsTroops.ZIndex=3;e.statsTroops.TextStrokeTransparency=1
    for _,o in ipairs(self.phoneDecor)do o.Visible=false end
    for _,m in ipairs(self.marks or {})do m.Visible=false end
    for _,p in ipairs(self.presets)do p.root.Parent=e.controls;p.root.Text=math.floor(p.value*100).."%";p.line.Enabled=true;p.root.BackgroundTransparency=.35 end
    e.selectedInfo.TextXAlignment=Left;e.selectedInfo.LineHeight=1;e.dock.phone=false;self:amountLimit(12)
    if self.badgeZ then e.growthBadge.ZIndex=self.badgeZ end
    e.statsGold.Parent=e.hud;e.selectedInfo.Parent=e.controls
    local line=e.controls:FindFirstChildOfClass('UIStroke');if line then line.Enabled=true end
end
function M:restore()
    if self.v2 then self.v2.fmt=nil;self.v2.seg.Visible=false;if self.v2.ratePlate then self.v2.ratePlate.Visible=false end;self.v2.line.Visible=false;self.e.dock.v2=nil;self.e.troopBar:SetAttribute('V2',false);self.portrait=false
        local g=self.e.troopBar:FindFirstChild('Bar20');if g then g:Destroy()end
        local fill=self.e.troopBar:FindFirstChild('Fill');if fill then fill.BackgroundTransparency=0 end
        if self.v2.coin then self.v2.coin.Visible=false end;self.coin.Visible=true
        self.e.dispatchKnob.Visible=true;self.e.dispatchTrack.BackgroundTransparency=0;local df=self.e.dispatchTrack:FindFirstChild('Fill');if df then df.Visible=true end end
    local was=self.wide or self.phone
    self:leavePhone()
    if not was then return end;self.wide=false
    local e=self.e
    for _,o in ipairs(self.decor)do o.Visible=false end
    for _,m in ipairs(self.marks or {})do m.Visible=false end
    self.soldier.Visible=false;self.barSoldier.Visible=false
    Style.round(e.growthFace,3);Style.round(e.troopBar,3);Style.round(e.controls,3);e.controls.BackgroundColor3=C.panel
    e.statsGold.Parent=e.hud;e.selectedInfo.Parent=e.controls
    e.growthFace.Visible=true;e.growthFace.BackgroundTransparency=.82;e.growthArrow.Visible=true;e.growthArrow.TextSize=20;e.growthIcon.Visible=true
    local track=e.troopBar;track.ClipsDescendants=true;track.BackgroundColor3=C.raised
    local line=track:FindFirstChildOfClass("UIStroke");if line then line.Enabled=true;line.Color=C.line;line.Transparency=0 end
    local fill=track:FindFirstChild('Fill');if fill then fill.BackgroundColor3=C.accent;local g=fill:FindFirstChild('HudFill');if g then g.Enabled=false end end
    e.filledTroops.Visible=not self.phone;e.troopWatermark.Visible=true;e.filledWatermark.Visible=true
    e.statsLand.Visible=false;e.statsGoldSub.Visible=false;e.statsTroops.RichText=false
    e.statsGoldSub.TextColor3=C.muted;e.statsGoldSub.Font=Enum.Font.BuilderSansMedium;e.statsGold.Font=Enum.Font.BuilderSansMedium
    e.selectedInfo.TextColor3=C.ink;e.selectedInfo.TextXAlignment=Left;self:amountLimit(12)
    e.statsGold.TextXAlignment=Center;e.statsTroopsSub.TextXAlignment=Center
    e.dock.bar=false;if e.dock.width then e.dock:layout(e.dock.x,e.dock.y,e.dock.width,e.dock.touch)end
end
function M:update(s,ownColor)
    if self.gainUntil and os.clock()>self.gainUntil then self.gainUntil=nil;self.gain.Text=""end
    local p=s and s.player
    if self.v2 and self.v2.fmt then
        self.troopVersion=s and s.version;self.lastGold=p and tonumber(p.gold)or self.lastGold;self.myTroops=p and tonumber(p.troops)or self.myTroops
        require(script.Parent.Hud20).update(self,s);return
    end
    if p and (self.wide or self.phone)then
        local e=self.e;self:tone()
        Icons.tint(self.soldier,e.statsTroopsSub.TextColor3)
        local ratio=(tonumber(p.troops)or 0)/math.max(1,tonumber(p.cap)or 1)
        Icons.tint(self.barSoldier,ratio>.08 and C.bg or C.ink)
        if s.phase=='playing'and not s.paused and s.version==self.troopVersion then self:troopChange(tonumber(p.troops)or 0,tonumber(p.cap)or 1)else self.lastTroops=nil end
        self.troopVersion=s.version
        local fill=self.e.troopBar:FindFirstChild('Fill');local g=fill and fill:FindFirstChild('HudFill')
        if g then local low=ratio<=.15 and (p.tiles or 0)>0;g.Color=low and ColorSequence.new(Style.colors.low,Style.colors.low:Lerp(C.ink,.2))or ColorSequence.new(Style.colors.fillA,Style.colors.fillB)end
    end
end
function M:troopChange(troops,cap)
    local before=self.lastTroops;self.lastTroops=troops
    if not before or troops>=before then return end
    local drop=before-troops;if drop<math.max(1,before*.01)then return end
    local TweenService=game:GetService('TweenService');local track=self.e.troopBar
    local sent=before*(self.sendFraction or 0)
    if sent>0 and math.abs(drop-sent)<=before*.05 then
        local f=UI.label(track.Parent,'Departure','−'..UI.troops(drop),15,C.ink);f.Font=Enum.Font.BuilderSansBold;f.TextWrapped=false
        f.TextXAlignment=Enum.TextXAlignment.Center;f.ZIndex=8;f.TextStrokeTransparency=.4;f.TextStrokeColor3=C.bg;f:SetAttribute('LocalizationSkip',true);f:SetAttribute('AllowOverlap',true)
        local x=track.Position.X.Offset+track.Size.X.Offset*math.clamp(troops/math.max(1,cap),.1,.9)
        UI.box(f,x-40,track.Position.Y.Offset-4,80,22)
        TweenService:Create(f,TweenInfo.new(.7,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=f.Position-UDim2.fromOffset(0,24),TextTransparency=1,TextStrokeTransparency=1}):Play()
        task.delay(.75,function()f:Destroy()end)
    else
        local w=track.AbsoluteSize.X/(UI.scale or 1)
        local slice=UI.make('Frame',track,{Name='Hit',BackgroundColor3=C.danger,BorderSizePixel=0,ZIndex=5})
        UI.box(slice,w*math.clamp(troops/math.max(1,cap),0,1),0,math.max(3,w*drop/math.max(1,cap)),track.Size.Y.Offset)
        TweenService:Create(slice,TweenInfo.new(.6,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.fromOffset(0,track.Size.Y.Offset),BackgroundTransparency=.4}):Play()
        task.delay(.65,function()slice:Destroy()end)
    end
end
function M:goldGain(amount)
    if not amount then return end
    if self.v2 and self.v2.fmt then
        local g=self.gain;local base=self.gainBase or g.Position
        g.Text='+'..UI.number(amount);g.TextTransparency=0;g.Position=base
        if self.gainTween then self.gainTween:Cancel()end
        if not require(script.Parent.Kit20).reduced then
            self.gainTween=game:GetService('TweenService'):Create(g,TweenInfo.new(.6,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=base-UDim2.fromOffset(0,8),TextTransparency=1});self.gainTween:Play()
        else self.gainTween=game:GetService('TweenService'):Create(g,TweenInfo.new(.6),{TextTransparency=1});self.gainTween:Play()end
        local bal=self.lastGold or 0
        if (tonumber(amount)or 0)>=math.max(1,bal)*.1 then require(script.Parent.Kit20).punch(self.goldBox,1.08,.16)end
        return
    end
    if not self.wide and not self.phone and self.touchGold and self.touchGold.Visible then
        local s=self.touchStroke;s.Thickness=2;s.Transparency=0
        game:GetService("TweenService"):Create(s,TweenInfo.new(.4,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Thickness=1}):Play()
        return
    end
    if not self.wide and not self.phone then return end
    self.gain.Text="+"..UI.number(amount);self.gainUntil=os.clock()+2
    local base=self.gainBase or self.gain.Position;self.gain.Position=base+UDim2.fromOffset(0,4)
    game:GetService("TweenService"):Create(self.gain,TweenInfo.new(.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=base}):Play()
    Style.pulse(self.goldStroke)
end
function M:dispatch(fraction)
    self.sendFraction=fraction
    self.ratioToken=(self.ratioToken or 0)+1;local token=self.ratioToken
    task.delay(1.5,function()if token==self.ratioToken then require(script.Parent.TelemetryStep).change('ratio','hud','ratioSet',{value=math.floor(fraction*100+.5)})end end)
    if self.v2 and self.v2.fmt then require(script.Parent.Hud20).dispatch(self,fraction);return end
    if self.wide or self.phone then self.e.selectedInfo.Text=math.floor(fraction*100+.5)..'%'end
    if self.phone then
        local r=self:ratio(fraction);local fill=self.e.dispatchTrack:FindFirstChild('Fill')
        if fill then fill.Size=UDim2.fromScale(r,1)end;self.e.dispatchKnob.Position=UDim2.fromScale(r,.5)
    end
    for i,p in ipairs(self.presets)do
        local on=math.abs(p.value-fraction)<.005
        do
            p.root.BackgroundColor3=on and C.ink or Style.colors.chip;p.root.BackgroundTransparency=on and 0 or .06
            p.root.TextColor3=on and C.bg or C.ink;p.line.Enabled=not on;p.line.Color=Style.colors.line
            Style.round(p.root,6)
        end
    end
end
return M
