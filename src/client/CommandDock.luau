local UI=require(script.Parent.Theme)
local U=require(script.Parent.Parent.Core.UnitRules)
local Icons=require(script.Parent.HotbarIcons)
local Hints=require(script.Parent.Parent.Core.CommandPresentation)
local Style=require(script.Parent.HudStyle)
local M={};M.__index=M
local C=UI.colors
local K
local short={City="도시",DefensePost="요새",Port="항구",Factory="철도",MissileSilo="발사",SAMLauncher="방공",Warship="군함",AtomBomb="원자",HydrogenBomb="수소",MIRV="다탄두"}
local icons={Warship="⚓",AtomBomb="☢",HydrogenBomb="☢",MIRV="✦"}
function M.new(parent,choose,cancel)
    local self=setmetatable({buttons={},group="all"},M)
    local strip=UI.make("Frame",parent,{Name="CommandDock",BackgroundTransparency=1,BorderSizePixel=0});self.frame=strip
    self.buildTab=UI.button(strip,"CategoryBuild","건설과 무기",function()self:setGroup("all")end)
    self.armsTab=UI.button(strip,"CategoryArms","",function()self:setGroup("all")end);self.armsTab.Visible=false
    self.buildTab.TextSize=12;self.armsTab.TextSize=12
    for i,kind in ipairs(U.buildable) do
        local b=UI.button(strip,"Choose"..kind,"",function()choose(kind)end);b.Text=""
        b.MouseEnter:Connect(function()if self.onInspect then self.onInspect(kind)end end)
        b.MouseLeave:Connect(function()if self.onInspect then self.onInspect(nil)end end)
        local art=Icons.create(b,kind,24,U.structures[kind]and UI.colors.ice or UI.colors.gold);art.Name="BuildingSymbol"
        local name=UI.label(b,"Caption",short[kind],12);name.TextWrapped=false;name.TextTruncate=Enum.TextTruncate.AtEnd
        local cost=UI.label(b,"Cost","",11,UI.colors.gold);cost.TextWrapped=false;UI.box(cost,0,26,64,16);cost.TextXAlignment=Enum.TextXAlignment.Center
        UI.display(cost,true);cost.BackgroundColor3=UI.colors.bg;cost.BackgroundTransparency=.18;UI.corner(cost,2);cost:SetAttribute("LocalizationSkip",true)
        local key=UI.label(b,"Key",tostring(i%10),11,UI.colors.muted);UI.display(key,true);key.TextWrapped=false;key.Visible=false
        local count=UI.label(b,"Count","",12,UI.colors.ink);count.Font=Enum.Font.BuilderSansBold;count.TextWrapped=false;count.Visible=false;count:SetAttribute("LocalizationSkip",true)
        self.buttons[kind]={root=b,cost=cost,name=name,index=i,art=art,key=key,count=count,choose=choose}
        b.MouseEnter:Connect(function()self.hovered=kind;self:tooltip()end)
        b.MouseLeave:Connect(function()if self.hovered==kind then self.hovered=nil;self:tooltip()end end)
    end
    local tip=UI.panel(parent,"HotbarTooltip");tip.Visible=false;tip.ZIndex=30;tip.BackgroundTransparency=.04;UI.stroke(tip,UI.colors.line)
    self.tipTitle=UI.label(tip,"Title","",14,UI.colors.ink);self.tipTitle.Font=Enum.Font.BuilderSansBold;self.tipTitle.TextXAlignment=Enum.TextXAlignment.Center;self.tipTitle.ZIndex=31
    self.tipBody=UI.label(tip,"Body","",13,UI.colors.muted);self.tipBody.TextXAlignment=Enum.TextXAlignment.Center;self.tipBody.ZIndex=31
    self.tipCost=UI.label(tip,"Cost","",14,UI.colors.gold);self.tipCost.Font=Enum.Font.BuilderSansBold;self.tipCost.TextXAlignment=Enum.TextXAlignment.Center;self.tipCost.ZIndex=31
    self.tipCoin=Icons.create(tip,"Gold",14);self.tipCoin.ZIndex=31
    self.tip=tip
    return self
end
function M:tooltip()
    local kind=self.hovered;local b=kind and self.buttons[kind];local tip=self.tip
    tip.Visible=b~=nil and self.bar==true and b.root.Visible and self.state~=nil
    if not tip.Visible then return end
    local s=self.state;local cost=s.costs and s.costs[kind];local reason=Hints.prerequisite(s,kind)
    local short=cost and tonumber(cost)>tonumber(s.player.gold)
    self.tipTitle.Text=(U.names[kind]or kind).." ["..tostring(b.index%10).."]"
    self.tipBody.Text=reason or Hints.roles[kind]or ""
    self.tipBody.TextColor3=reason and UI.colors.danger or UI.colors.muted
    self.tipCost.Text=cost and UI.number(cost)or "—"
    self.tipCost.TextColor3=(short or reason or cost==nil)and UI.colors.muted or UI.colors.gold
    local L=require(script.Parent.Localization);local TS=game:GetService("TextService")
    local function tw(label)return TS:GetTextSize(L.text(label.Text),label.TextSize,label.Font,Vector2.new(600,40)).X+2 end
    local titleW,costW,bodyW=tw(self.tipTitle),tw(self.tipCost),self.tipBody.Text~=""and tw(self.tipBody)or 0
    local w=math.max(120,math.ceil(math.max(titleW+12+15+costW,bodyW))+20);local h=bodyW>0 and 46 or 28
    local parent=tip.Parent;local parentPos=parent.AbsolutePosition;local cell=b.root.AbsolutePosition;local ui=UI.scale or 1
    local scale=parent.Size.X.Offset>0 and parent.AbsoluteSize.X/parent.Size.X.Offset or ui;local k=scale/ui
    self.tipScale=self.tipScale or UI.make("UIScale",tip,{Name="Unscale"});self.tipScale.Scale=1/k
    local cx=(cell.X-parentPos.X)/scale+b.root.AbsoluteSize.X/scale/2
    UI.box(tip,math.floor(cx-w/(2*k)),math.floor((cell.Y-parentPos.Y)/scale-(h+6)/k),w,h)
    UI.box(self.tipTitle,10,5,titleW,18);self.tipTitle.TextXAlignment=Enum.TextXAlignment.Left
    UI.box(self.tipCost,w-10-costW,5,costW,18);UI.box(self.tipCoin,w-10-costW-15,7,13,13)
    self.tipCost.TextXAlignment=Enum.TextXAlignment.Right
    self.tipBody.Visible=bodyW>0;UI.box(self.tipBody,10,24,w-20,16);self.tipBody.TextXAlignment=Enum.TextXAlignment.Left
end
function M:deny(kind)
    require(script.Parent.TelemetryStep).step('hud','buildDenied',{kind=kind,item=require(script.Parent.TelemetryStep).code(kind)})
    local b=self.buttons[kind];if not b then return end
    local Tween=game:GetService("TweenService");local root=b.root
    local base=root:GetAttribute("DenyBase") or root.Position;root:SetAttribute("DenyBase",base)
    if self.v2 then
        K=K or require(script.Parent.Kit20)
        if b.priceTween then b.priceTween:Cancel()end
        local back=b.cost.TextColor3;b.cost.TextColor3=C.danger
        b.priceTween=Tween:Create(b.cost,TweenInfo.new(.25,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{TextColor3=back});b.priceTween:Play()
        if K.reduced then root:SetAttribute("DenyBase",nil);return end
        task.spawn(function()
            for _,dx in ipairs({-3,3,-2,2,0})do root.Position=base+UDim2.fromOffset(dx,0);task.wait(.035)end
            root.Position=base;root:SetAttribute("DenyBase",nil)
        end)
        return
    end
    if self.bar then
        b.cost.BackgroundColor3=Style.colors.priceOff:Lerp(UI.colors.ink,.35)
        Tween:Create(b.cost,TweenInfo.new(.3,Enum.EasingStyle.Quad),{BackgroundColor3=Style.colors.priceOff}):Play()
    else
        root.BackgroundColor3=UI.colors.danger
        Tween:Create(root,TweenInfo.new(.45),{BackgroundColor3=UI.colors.panel}):Play()
    end
    task.spawn(function()
        for _,dx in ipairs({-5,5,-3,3,0})do root.Position=base+UDim2.fromOffset(dx,0);task.wait(.035)end
        root.Position=base;root:SetAttribute("DenyBase",nil)
    end)
end
function M:setGroup(group)
    local previous=self.group;self.group="all"
    if self.width then self:layout(self.x,self.y,self.width,self.touch) end
    if self.onGroup then self.onGroup(self.group,previous) end
end
function M:shape(width,touch)
    local n=#U.buildable;local fold=touch and 1 or 0
    local one=(width-fold*47-(n-1)*3)/n
    if not self.grid and one>=(touch and 42 or 44)then return n,1,fold end
    return math.ceil((n+fold)/2),2,fold
end
function M:height(width,touch)
    if self.bar then return self.barHeight or 66 end
    if self.compact then return 48 end
    local _,rows=self:shape(width,touch);return rows==1 and 44 or 92
end
function M:barSize()return not self.phone and self.barText or 13 end
function M:barLayout(x,y,width)
    local list=U.buildable;local phone=self.phone==true;local gap=phone and 4 or 4
    local cell=math.floor((width-(#list-1)*gap)/#list);local h=self.barHeight or 66
    UI.box(self.frame,x,y,width,h);self.buildTab.Visible=false;self.armsTab.Visible=false
    local start=math.floor((width-(#list*cell+(#list-1)*gap))/2)
    local small=phone or h<60;local flat=h<44;local icon=math.min(flat and 20 or small and 22 or 26,cell-18);local strip=flat and 15 or small and 17 or 19
    local reach=phone and self.reach and self.reach>h and self.reach-h or 0
    for kind,b in pairs(self.buttons)do
        b.root.AnchorPoint=Vector2.zero;M.unfeel(b)
        local index=table.find(list,kind);b.root.Visible=index~=nil;b.name.Visible=false;b.cost.Visible=index~=nil
        if index and self.coverX and x+start+(index-1)*(cell+gap)+cell>self.coverX then b.root.Visible=false;index=nil end
        if index then
            local chosen=kind==self.selected
            UI.box(b.root,start+(index-1)*(cell+gap),chosen and -(small and 4 or 6)or 0,cell,h)
            b.key.Visible=not phone;UI.box(b.key,6,3,14,15);b.key.TextSize=self:barSize();b.key.TextXAlignment=Enum.TextXAlignment.Left
            local n=tonumber(b.count.Text)
            if phone then
                b.count.Visible=n~=nil and n>=1;UI.box(b.count,cell-14,-6,20,20);b.count.TextXAlignment=Enum.TextXAlignment.Center
            else
                b.count.Visible=b.count.Text~="";UI.box(b.count,cell-26,3,20,15);b.count.TextXAlignment=Enum.TextXAlignment.Right
            end
            UI.box(b.art,math.floor((cell-icon)/2),flat and 2 or small and 6 or 18,icon,icon)
            UI.box(b.cost,3,h-strip-(flat and 1 or 3),cell-6,strip);b.cost.TextSize=self:barSize()
        end
    end
    for kind,b in pairs(self.buttons)do
        if reach>0 and not b.reach then
            local r=UI.make('TextButton',b.root,{Name='Reach',Text='',BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Active=true,Selectable=false})
            r.Activated:Connect(function()if b.root:GetAttribute('Enabled')~=false and b.root.Visible then require(script.Parent.ToyAudio).play('click');b.choose(kind)end end)
            b.reach=r
        end
        if b.reach then b.reach.Visible=reach>0;if reach>0 then UI.box(b.reach,0,-reach,b.root.Size.X.Offset,reach)end end
    end
    self.frame:SetAttribute('Compact',false);self.frame:SetAttribute("NoScroll",true);self.frame:SetAttribute("Category","all");self.frame:SetAttribute("CellWidth",cell)
end
function M:paintBar(kind,b,unavailable,chosen)
    local S=Style.colors
    b.root.BackgroundColor3=S.cell;b.root.BackgroundTransparency=.04;Style.round(b.root,6)
    b.edge=b.edge or Style.line(b.root,S.line,1)
    b.edge.Color=chosen and UI.colors.accent or S.line;b.edge.Thickness=chosen and 2 or 1;b.edge.Transparency=0
    b.cost.BackgroundColor3=unavailable and S.priceOff or S.priceBg;b.cost.BackgroundTransparency=0;Style.round(b.cost,4)
    b.cost.TextColor3=unavailable and UI.colors.muted or UI.colors.gold
    if not b.sansCost then b.sansCost=true;b.cost.FontFace=Font.fromEnum(Enum.Font.BuilderSansBold);b.key.FontFace=Font.fromEnum(Enum.Font.BuilderSansBold)end
    b.key.TextColor3=chosen and UI.colors.accent or UI.colors.muted
    if self.phone then
        b.count.BackgroundColor3=UI.colors.ink;b.count.BackgroundTransparency=0;b.count.TextColor3=UI.colors.bg;b.count.ZIndex=b.root.ZIndex+3
        if not b.countRound then b.countRound=Style.round(b.count,10)end
        b.countRound.CornerRadius=UDim.new(0,10)
    else
        b.count.BackgroundTransparency=1;b.count.TextColor3=unavailable and UI.colors.muted or UI.colors.ink
        if b.countRound then b.countRound.CornerRadius=UDim.new(0,0)end
    end
    local punching=os.clock()<(b.punchUntil or 0)
    if not punching then b.count.TextSize=self:barSize()end
    Icons.tint(b.art,UI.colors.ink)
    if b.art:IsA("ImageLabel")then b.art.ImageTransparency=unavailable and not chosen and .45 or 0 end
    local p=self.progress and self.progress[kind]
    if p and not b.buildLine then b.buildLine=UI.make('Frame',b.cost,{Name='Building',BackgroundColor3=UI.colors.gold,BorderSizePixel=0,ZIndex=b.cost.ZIndex+1});Style.round(b.buildLine,1)end
    if b.buildLine then b.buildLine.Visible=p~=nil;if p then b.buildLine.Size=UDim2.new(p,0,0,2);b.buildLine.Position=UDim2.fromOffset(0,0)end end
    local n=tonumber(b.count.Text)or 0
    if b.lastCount and n>b.lastCount then
        b.punchUntil=os.clock()+.26;require(script.Parent.Kit20).punch(b.count,1.2,.24)
        Style.pulse(b.edge,UI.colors.accent)
    end
    b.lastCount=n
end
local OFF=Color3.fromRGB(20,27,36);local CHOSEN=Color3.fromRGB(18,58,56)
function M:layout2(x,y,width)
    K=K or require(script.Parent.Kit20)
    local v=self.v2;local list=U.buildable;local kind=v.kind
    local open=kind~='pt'or v.open
    local rows=kind=='pt'and 2 or 1
    UI.box(self.frame,x,y,width,open and (v.ch*rows+(rows-1)*v.gap)or 0)
    self.armsTab.Visible=false
    local tab=self.buildTab;tab.Visible=kind=='pt'
    if kind=='pt'then
        local t=v.toggle;tab.Parent=self.frame.Parent;tab.Text='';UI.box(tab,t.x,t.y,t.w,t.h);tab.ZIndex=6
        K.round(tab,8);tab.BackgroundColor3=C.raised;tab.BackgroundTransparency=0
        local st=tab:FindFirstChildOfClass('UIStroke');if st then st.Color=v.open and C.accent or C.line;st.Thickness=v.open and 2 or 1;st.Transparency=0 end
        self.tabIcon=self.tabIcon or Icons.create(tab,'City',15,C.ink);self.tabIcon.Name='BuildIcon';UI.box(self.tabIcon,18,5,15,15);Icons.tint(self.tabIcon,v.open and C.accent or C.ink);self.tabIcon.ZIndex=7
        self.tabWord=self.tabWord or K.text(tab,'Word','건설',11,C.ink,800,Enum.TextXAlignment.Center);UI.box(self.tabWord,0,21,t.w,13);self.tabWord.ZIndex=7
        self:readyMark(self.ready and not v.open and t.w or nil)
    end
    for kindName,b in pairs(self.buttons)do
        local index=table.find(list,kindName);b.root.Visible=index~=nil and open
        if b.reach then b.reach.Visible=false end
        if index and open then
            local col=(index-1)%v.cols;local row=(index-1)//v.cols
            local cx=math.floor(col*(v.cw+v.gap)+.5);local cw=math.floor((col+1)*(v.cw+v.gap)-v.gap+.5)-cx
            local ax,ay=math.floor(cw/2),math.floor(v.ch/2)
            b.root.AnchorPoint=Vector2.new(ax/cw,ay/v.ch);UI.box(b.root,cx+ax,row*(v.ch+v.gap)+ay,cw,v.ch)
            K.round(b.root,kind=='ph'and 7 or 8);self:feel2(kindName,b)
            b.key.Visible=kind=='pc'and not v.touch;b.name.Visible=kind=='pt';b.cost.Visible=true
            for _,l in ipairs({b.key,b.cost,b.count})do if K.fonts.num then l.FontFace=K.fonts.num end;l.BackgroundTransparency=1 end
            local pc=b.cost:FindFirstChildOfClass('UICorner');if pc then pc.CornerRadius=UDim.new(0,0)end
            if kind=='pc'then
                UI.box(b.key,6,4,10,15);b.key.TextSize=10;b.key.TextXAlignment=Enum.TextXAlignment.Left
                UI.box(b.art,math.floor((cw-15)/2),3,15,15)
                UI.box(b.cost,0,19,cw,15);b.cost.TextSize=10;b.cost.TextXAlignment=Enum.TextXAlignment.Center
                local n=tonumber(b.count.Text)or 0;b.count.Visible=n>=1;b.count.TextSize=11;UI.box(b.count,cw-14,4,10,15);b.count.TextXAlignment=Enum.TextXAlignment.Right
            elseif kind=='ph'then
                local pw=math.min(cw-30,K.width(b.cost.Text,10,b.cost)+2);local gx=math.floor((cw-(15+3+pw))/2)
                UI.box(b.art,gx,math.floor((v.ch-15)/2),15,15);UI.box(b.cost,gx+18,math.floor((v.ch-15)/2),pw,15);b.cost.TextSize=10;b.cost.TextXAlignment=Enum.TextXAlignment.Left
                local n=tonumber(b.count.Text)or 0;b.count.Visible=n>=1;b.count.TextSize=11;UI.box(b.count,cw-12,1,10,12);b.count.TextXAlignment=Enum.TextXAlignment.Right
            else
                UI.box(b.art,math.floor((cw-17)/2),2,17,17)
                b.name.TextSize=11;b.name.Font=Enum.Font.BuilderSansBold;b.name.TextXAlignment=Enum.TextXAlignment.Center;UI.box(b.name,0,20,cw,13)
                UI.box(b.cost,0,34,cw,16);b.cost.TextSize=11;b.cost.TextXAlignment=Enum.TextXAlignment.Center
                local n=tonumber(b.count.Text)or 0;b.count.Visible=n>=1;b.count.TextSize=11;UI.box(b.count,cw-14,3,10,13);b.count.TextXAlignment=Enum.TextXAlignment.Right
            end
            if self.state then self:paint2(kindName,b)end
        end
    end
    self.frame:SetAttribute('Compact',kind=='pt'and not v.open);self.frame:SetAttribute('NoScroll',true);self.frame:SetAttribute('Category','all');self.frame:SetAttribute('CellWidth',v.cw)
end
local Tween=game:GetService('TweenService')
function M:feel2(kindName,b)
    if b.feel then return end
    local s=K.make('UIScale',b.root,{Name='Press20'});b.feel=s
    local function to(v,t,style)
        if b.feelTween then b.feelTween:Cancel();b.feelTween=nil end
        if K.reduced then s.Scale=1;return end
        b.feelTween=Tween:Create(s,TweenInfo.new(t,style or Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=v});b.feelTween:Play()
    end
    local function live()return self.v2~=nil and b.root.Visible and b.root:GetAttribute('Enabled')~=false end
    local function press(i)return i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch end
    local function repaint()if self.v2 then self:paint2(kindName,b)end end
    b.root.MouseEnter:Connect(function()
        if not live()or require(script.Parent.InputMode).touch()then return end
        b.hover=true;if not b.down then to(1.02,.08)end;repaint()
    end)
    b.root.MouseLeave:Connect(function()local was=b.hover or b.down;b.hover=false;b.down=false;if was then to(1,.08);repaint()end end)
    b.root.InputBegan:Connect(function(i)
        if not press(i)or not live()then return end
        b.down=true;to(.96,.05);repaint()
    end)
    b.root.InputEnded:Connect(function(i)
        if not press(i)or not b.down then return end
        b.down=false;repaint()
        if K.reduced then s.Scale=1;return end
        if b.feelTween then b.feelTween:Cancel()end;s.Scale=1.02;to(b.hover and 1.02 or 1,.12,Enum.EasingStyle.Back)
    end)
end
function M.unfeel(b)
    if b.feel then b.feel.Scale=1 end;b.hover=false;b.down=false
    local tint=b.root:FindFirstChild('PressFeedback');if tint then tint.Visible=true end
end
function M:paint2(kindName,b)
    K=K or require(script.Parent.Kit20)
    local unavailable=b.root:GetAttribute('Affordable')==false;local chosen=kindName==self.selected
    b.root.AutoButtonColor=false;local tint=b.root:FindFirstChild('PressFeedback');if tint then tint.Visible=false end
    local fill=chosen and CHOSEN or unavailable and OFF or C.raised
    if b.down then fill=fill:Lerp(Color3.new(1,1,1),.08)end
    b.root.BackgroundColor3=fill;b.root.BackgroundTransparency=0
    local edge=chosen and C.accent or b.hover and C.muted or C.line
    local st=K.stroke(b.root,edge,chosen and 2 or 1,(not chosen and unavailable and not b.hover)and .4 or 0,true)
    if b.edge and b.edge~=st then b.edge.Enabled=false end
    local dim=K.colors.dim
    Icons.tint(b.art,unavailable and not chosen and dim or C.ink);if b.art:IsA('ImageLabel')then b.art.ImageTransparency=0 end
    b.cost.TextColor3=unavailable and not chosen and dim or C.gold
    b.name.TextColor3=unavailable and not chosen and dim or C.ink
    b.key.TextColor3=chosen and C.accent or C.muted
    b.count.TextColor3=unavailable and dim or C.ink
    if chosen and b.wasChosen~=true then K.punch(b.art,1.08,.1)end
    b.wasChosen=chosen
    local n=tonumber(b.count.Text)or 0
    if b.lastCount and n>b.lastCount then K.punch(b.art,1.08,.14)end
    b.lastCount=n
end
function M:layout(x,y,width,touch)
    self.x=x;self.y=y;self.width=width;self.touch=touch
    if self.v2 then return self:layout2(x,y,width)end
    if self.bar then return self:barLayout(x,y,width)end
    for _,b in pairs(self.buttons)do b.root.AnchorPoint=Vector2.zero;M.unfeel(b);b.key.Visible=false;b.count.Visible=false;b.name.Visible=true;b.cost.Visible=true;if b.reach then b.reach.Visible=false end end
    if self.tip then self.tip.Visible=false end
    UI.box(self.frame,x,y,width,self:height(width,touch))
    self.armsTab.Visible=false;self.buildTab.TextSize=14
    self.buildTab.BackgroundColor3=UI.colors.raised;self.buildTab.TextColor3=UI.colors.ink
    if self.compact then
        local bw=math.min(116,width);local bh=bw<100 and 44 or 48
        self.buildTab.Visible=true;self.buildTab.Text=bw<100 and '건설'or '건설과 무기';UI.box(self.frame,x,y,bw,bh);UI.box(self.buildTab,0,0,bw,bh)
        for _,b in pairs(self.buttons)do b.root.Visible=false end
        self:readyMark(bw)
        self.frame:SetAttribute('Compact',true);self.frame:SetAttribute('Category','all');return
    end
    self:readyMark(nil)
    self.frame:SetAttribute('Compact',false)
    local list=U.buildable;local columns,rows,fold=self:shape(width,touch)
    self.buildTab.Visible=fold==1;self.buildTab.Text='접기 ▾';self.buildTab.TextSize=11
    local cell
    if rows==1 then
        cell=(width-fold*47-(#list-1)*3)/#list
        UI.box(self.buildTab,0,0,44,44)
    else
        cell=math.floor((width-(columns-1)*3)/columns)
        UI.box(self.buildTab,0,0,cell,44)
    end
    for kind,b in pairs(self.buttons)do
        local index=table.find(list,kind);b.root.Visible=index~=nil
        if index then
            if rows==1 then UI.box(b.root,fold*47+(index-1)*(cell+3),0,cell,44)
            else local slot=index-1+fold;UI.box(b.root,slot%columns*(cell+3),math.floor(slot/columns)*48,cell,44)end
            UI.box(b.art,(cell-18)/2,2,18,18);UI.box(b.name,1,19,cell-2,13);UI.box(b.cost,1,31,cell-2,12)
            b.name.TextSize=11;b.name.TextXAlignment=Enum.TextXAlignment.Center;b.cost.TextSize=11
        end
    end
    self.cell=cell;self.frame:SetAttribute("NoScroll",true);self.frame:SetAttribute("Category","all");self.frame:SetAttribute("CellWidth",cell)
end
function M:readyMark(bw)
    local tab=self.buildTab;local on=bw~=nil and self.ready==true
    if not self.readyDot then
        self.readyDot=UI.make('Frame',tab,{Name='ReadyDot',BackgroundColor3=UI.colors.gold,BorderSizePixel=0,Active=false,ZIndex=tab.ZIndex+2})
        UI.make('UICorner',self.readyDot,{CornerRadius=UDim.new(.5,0)})
    end
    self.readyDot.Visible=on;if on then UI.box(self.readyDot,bw-12,5,7,7)end
    tab:SetAttribute('Ready',on)
end
function M:update(state,selected)
    self.state=state
    local owned={}
    for _,u in ipairs(state.units or {})do if (u.owner or 1)==1 and u.active~=false and (U.structures[u.kind]or u.kind=="Warship")then owned[u.kind]=(owned[u.kind]or 0)+(u.kind=="Warship"and 1 or u.level or 1)end end
    self.progress={}
    for _,u in ipairs(state.units or {})do if (u.owner or 1)==1 and u.building and u.duration then
        local p=math.clamp(1-(u.remaining or 0)/math.max(1,u.duration),0,1);if p>(self.progress[u.kind]or -1)then self.progress[u.kind]=p end
    end end
    for kind,b in pairs(self.buttons) do
        local cost=state.costs and state.costs[kind]
        local reason=Hints.prerequisite(state,kind)
        local short=tonumber(cost or 0)>(tonumber(state.player.gold)or 0)
        local unavailable=reason~=nil or cost==nil or short
        b.cost.Text=cost and UI.number(cost):gsub("%.0+([KMB])$","%1"):gsub("(%.[1-9])0([KMB])$","%1%2")or "—"
        b.count.Text=(U.structures[kind]or kind=="Warship")and tostring(owned[kind]or 0)or ""
        b.root:SetAttribute("Owned",owned[kind]or 0)
        b.cost.TextColor3=unavailable and UI.colors.muted or UI.colors.gold
        b.cost.TextSize=self.bar and self:barSize()or 11;b.cost.TextTruncate=Enum.TextTruncate.AtEnd
        b.root:SetAttribute("Affordable",not unavailable)
        b.root:SetAttribute("Cost",cost)
        b.root:SetAttribute('Requirement',reason);b.root:SetAttribute('Role',Hints.roles[kind])
        for _,o in ipairs(b.art:GetDescendants())do if o:IsA("ViewportFrame")then o.ImageTransparency=short and .55 or 0 end end
        if b.art:IsA("ViewportFrame")then b.art.ImageTransparency=short and .55 or 0 end
        UI.enabled(b.root,state.phase=="playing" and not state.paused and not U.disabled(state.settings,kind))
        if self.v2 then self.selected=selected;self:paint2(kind,b)
        elseif self.bar then self:paintBar(kind,b,unavailable,kind==selected)
        else
        if b.edge then b.edge.Enabled=false end
        if b.sansCost then b.sansCost=nil;UI.display(b.cost,true);UI.display(b.key,true)end
        b.cost.BackgroundColor3=UI.colors.bg;b.cost.BackgroundTransparency=.18;b.count.BackgroundTransparency=1
        b.root.BackgroundColor3=kind==selected and UI.colors.accent or UI.colors.panel
        b.key.TextColor3=kind==selected and UI.colors.bg or UI.colors.muted
        b.count.TextColor3=kind==selected and UI.colors.bg or unavailable and UI.colors.muted or UI.colors.ink
        b.root.BackgroundTransparency=0;Style.round(b.root,3)
        b.name.TextColor3=kind==selected and UI.colors.bg or UI.colors.ink
        local ink=kind==selected and UI.colors.bg or unavailable and UI.colors.muted or U.structures[kind]and UI.colors.ice or UI.colors.gold
        Icons.tint(b.art,ink)
        if b.art:IsA("ImageLabel")then b.art.ImageTransparency=unavailable and kind~=selected and .45 or 0 end
        end
    end
    self.selected=selected
    local ready=false
    if state.phase=="playing" and not state.paused then
        for kind,b in pairs(self.buttons)do if b.root:GetAttribute("Affordable")and not U.disabled(state.settings,kind)then ready=true;break end end
    end
    self.ready=ready
    UI.enabled(self.buildTab,state.phase=="playing" and not state.paused);UI.enabled(self.armsTab,state.phase=="playing" and not state.paused)
    if self.width then self:layout(self.x,self.y,self.width,self.touch) end
    if self.hovered then self:tooltip()end
end
return M
