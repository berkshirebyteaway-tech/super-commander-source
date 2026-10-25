local UI=require(script.Parent.Theme)
local Icons=require(script.Parent.UIIcons)
local P=require(script.Parent.Parent.Core.OperationPresentation)
local M={};M.__index=M
function M.new(parent,renderer,send,expand)
    local self=setmetatable({rows={},renderer=renderer,send=send},M)
    self.frame=UI.make('ScrollingFrame',parent,{Name='Operations',BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=UI.colors.line,CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.Y,ZIndex=12,Visible=false})
    self.frame:SetAttribute('HudLeft',true)
    self.peek=UI.button(parent,'OperationsPeek','',function()expand();self.frame.CanvasPosition=Vector2.zero end)
    self.peek.ZIndex=16;self.peek.TextSize=14;self.peek.Visible=false
    return self
end
local K
local ICON={['↓']='fold',['↑']='up',['↗']='up',['↩']='back'}
function M:update20(state,factions)
    K=K or require(script.Parent.Kit20)
    local list=P.items(state.operations,factions);local alive={};local incoming=0
    local panel=self.frame.Parent;local controls=panel:FindFirstChild('Controls')
    local w,h=panel.AbsoluteSize.X/(UI.scale or 1),panel.AbsoluteSize.Y/(UI.scale or 1)
    local touch=require(script.Parent.InputMode).touch();local Placement=require(script.Parent.Parent.Core.InterfacePlacement)
    local fmt=(not touch or Placement.tablet(w,h,touch))and 'pc'or h<w and 'ph'or 'pt'
    local rh,rw,maxRows=fmt=='pt'and 26 or 22,fmt=='pc'and 210 or fmt=='ph'and 196 or 204,fmt=='ph'and 3 or 4
    local gap=3
    local x=fmt=='pc'and controls and controls.Position.X.Offset or (fmt=='pt'and 10 or 12)
    local bottom=(controls and controls.Visible and controls.Position.Y.Offset or h)-8
    local shown=self.expanded and #list or math.min(#list,maxRows)
    local boxH=math.max(rh,shown*(rh+gap)-gap)
    self.frame.ScrollingEnabled=false;self.frame.ScrollBarThickness=0;self.frame.ClipsDescendants=false
    self.box20={x,bottom-boxH,rw,boxH};self.placing=true;UI.box(self.frame,x,bottom-boxH,rw,boxH);self.placing=false;self.step=rh+gap
    if not self.guard20 then self.guard20=true;local function keep()if self.placing or not self.box20 or not require(script.Parent.Hud20).ENABLED then return end;local b=self.box20;self.placing=true;UI.box(self.frame,b[1],b[2],b[3],b[4]);self.placing=false end
        self.frame:GetPropertyChangedSignal('Position'):Connect(keep);self.frame:GetPropertyChangedSignal('Size'):Connect(keep)end
    local fs=fmt=='pc'and 12 or 11;local ns=11;local ss=fmt=='pc'and 11 or 10;local is=fmt=='pc'and 12 or 11
    for i,item in ipairs(list)do
        local key=item.key;alive[key]=true;local row=self.rows[key];local fresh=false
        if not row then
            fresh=true;row={}
            row.frame=K.make('Frame',self.frame,{Name='Order_'..key,BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=12})
            K.round(row.frame,6);row.edge=K.stroke(row.frame,K.colors.line,1,.1,true)
            row.band=K.make('UIGradient',row.frame,{Name='Band'})
            row.focus=K.make('TextButton',row.frame,{Name='Focus',Text='',BackgroundTransparency=1,AutoButtonColor=false,ZIndex=13})
            row.focus.Activated:Connect(function()
                local op=row.item and row.item.operation
                if op and op.frontTile~=nil then require(script.Parent.TelemetryStep).step('match','opFocus',{item=row.item.incoming and 'incoming'or 'outgoing'});self.renderer:focusAt(op.frontTile,true)end
            end)
            row.icon=K.icon(row.focus,'up',is,K.colors.accent,'Dir');row.icon.ZIndex=14
            row.amount=K.num(row.focus,'Troops','',fs,K.colors.accent);row.amount.ZIndex=14
            row.target=K.text(row.focus,'Target','',ns,K.colors.ink,700);row.target.ZIndex=14
            row.status=K.text(row.focus,'Status','',ss,K.colors.accent,800,Enum.TextXAlignment.Right);row.status.ZIndex=14
            row.cancel=K.make('TextButton',row.frame,{Name='Cancel',Text='',BackgroundTransparency=1,AutoButtonColor=false,ZIndex=14})
            row.x=K.icon(row.cancel,'x',is,K.colors.muted,'X');row.x.ZIndex=15
            row.cancel.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then row.x.ImageColor3=K.colors.danger end end)
            row.cancel.InputEnded:Connect(function()row.x.ImageColor3=K.colors.muted end)
            row.cancel.Activated:Connect(function()local current=row.item;if current and current.canCancel then require(script.Parent.ToyAudio).play('click');self.send(current.cancelAction,current.operation.id)end end)
            self.rows[key]=row
        end
        row.item=item;if item.incoming then incoming+=1 end
        local returning=item.arrow=='↩'
        local color=returning and K.colors.muted or item.incoming and K.colors.danger or K.colors.accent
        row.frame.Visible=i<=shown
        local slot=shown-i;K.box(row.frame,0,slot*(rh+gap),rw,rh)
        local p=3/rw
        row.frame.BackgroundColor3=Color3.new(1,1,1)
        row.band.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,color),ColorSequenceKeypoint.new(p,color),ColorSequenceKeypoint.new(math.min(1,p+.001),Color3.fromRGB(12,17,24)),ColorSequenceKeypoint.new(1,Color3.fromRGB(12,17,24))})
        row.band.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(p,0),NumberSequenceKeypoint.new(math.min(1,p+.001),.12),NumberSequenceKeypoint.new(1,.12)})
        row.frame.BackgroundTransparency=0
        local cx=item.canCancel and rh or 0
        K.box(row.focus,0,0,rw-cx,rh)
        K.box(row.icon,fmt=='pc'and 11 or 9,math.floor((rh-is)/2),is,is);require(script.Parent.OutgameIcons).set(row.icon,ICON[item.arrow]or 'up');row.icon.ImageColor3=color
        row.amount.TextSize=fs;row.amount.Text=UI.troops(item.operation.troops);row.amount.TextColor3=color;K.box(row.amount,fmt=='pc'and 29 or 24,0,40,rh)
        row.target.TextSize=ns;row.target.Text=item.target;K.box(row.target,fmt=='pc'and 73 or 62,0,rw-cx-(fmt=='pc'and 73 or 62)-34,rh)
        row.status.TextSize=ss;row.status.Text=item.status;row.status.TextColor3=color;K.box(row.status,rw-cx-34,0,28,rh)
        row.cancel.Visible=item.canCancel;K.box(row.cancel,rw-rh,0,rh,rh);K.box(row.x,math.floor((rh-is)/2),math.floor((rh-is)/2),is,is)
        row.cancel.Active=not state.paused;row.focus.Active=item.operation.frontTile~=nil
        row.frame:SetAttribute('FrontTile',item.operation.frontTile);row.frame:SetAttribute('Direction',item.operation.direction)
        if fresh and not K.reduced then
            K.rehome(row.frame);row.frame:SetAttribute('Shown20',false);K.appear(row.frame,{dy=8,t=.12,noFade=true})
            if item.incoming then row.edge.Color=K.colors.danger;row.edge.Transparency=0;task.delay(.3,function()if row.edge.Parent then row.edge.Color=K.colors.line;row.edge.Transparency=.1 end end)end
        end
    end
    local more=#list-shown
    self.more20=self.more20 or K.button(self.frame,'More20',{kind='glass',text='',size=11,weight=800,hit=32},function()self.expanded=not self.expanded;self:update20(self.lastState,self.lastFactions)end)
    self.more20.button.Visible=more>0 or self.expanded==true
    if self.more20.button.Visible then self.more20:setText(self.expanded and '접기'or '+'..more);self.more20:place(rw+4,boxH-rh,32,rh)end
    for key,row in pairs(self.rows)do if not alive[key]then local f=row.frame;self.rows[key]=nil
        if K.reduced then f:Destroy()else K.leave(f,{t=.15,noFade=false},function()f:Destroy()end)end end end
    if #list<=maxRows then self.expanded=false end
    self.frame.Visible=#list>0
    if incoming>0 and (self.frame:GetAttribute('IncomingCount')or 0)==0 then require(script.Parent.TelemetryStep).step('match','underAttack',{count=incoming})end
    self.frame:SetAttribute('OrderCount',#list);self.frame:SetAttribute('IncomingCount',incoming)
    self.peek.Visible=false
end
function M:update(state,factions)
    self.lastState,self.lastFactions=state,factions
    if require(script.Parent.Hud20).ENABLED then return self:update20(state,factions)end
    local list=P.items(state.operations,factions);local alive={};local incoming=0
    for i,item in ipairs(list)do
        local key=item.key;alive[key]=true;local row=self.rows[key]
        if not row then
            row={}
            row.frame=UI.panel(self.frame,'Order_'..key);row.frame.Size=UDim2.new(1,-5,0,44)
            row.focus=UI.button(row.frame,'Focus','',function()
                local op=row.item and row.item.operation
                if op and op.frontTile~=nil then require(script.Parent.TelemetryStep).step('match','opFocus',{item=row.item.incoming and 'incoming'or 'outgoing'});self.renderer:focusAt(op.frontTile,true)end
            end);row.focus.BackgroundTransparency=1
            row.arrow=UI.label(row.focus,'Direction','',22);row.arrow.TextXAlignment=Enum.TextXAlignment.Center;UI.box(row.arrow,0,0,28,44)
            row.target=UI.label(row.focus,'Target','',14);row.target.TextWrapped=false;row.target.TextTruncate=Enum.TextTruncate.AtEnd;row.target.Position=UDim2.fromOffset(32,2);row.target.Size=UDim2.new(1,-36,0,18)
            row.icon=Icons.create(row.focus,'troops',18);UI.box(row.icon,32,22,18,18)
            row.amount=UI.label(row.focus,'Troops','',16);row.amount.Position=UDim2.fromOffset(54,20);row.amount.Size=UDim2.new(1,-120,0,22)
            row.status=UI.label(row.focus,'Status','',14);row.status.TextXAlignment=Enum.TextXAlignment.Right;row.status.Position=UDim2.new(1,-60,0,21);row.status.Size=UDim2.fromOffset(56,20)
            row.cancel=UI.button(row.frame,'Cancel','×',function()
                local current=row.item;if current and current.canCancel then self.send(current.cancelAction,current.operation.id)end
            end);row.cancel.TextSize=23;row.cancel.Position=UDim2.new(1,-44,0,0);row.cancel.Size=UDim2.fromOffset(44,44);row.cancel.BackgroundTransparency=1;row.cancel.TextColor3=UI.colors.danger
            self.rows[key]=row
        end
        row.item=item;if item.incoming then incoming+=1 end
        local color=item.incoming and UI.colors.danger or UI.colors.accent
        local touch=require(script.Parent.InputMode).touch();local rh=touch and 36 or 28;local step=touch and 40 or 32
        if row.rh~=rh then row.rh=rh
            local amountW=touch and 42 or 52;local statusW=touch and 36 or 56
            row.frame.Size=UDim2.new(1,-5,0,rh);UI.box(row.arrow,2,0,18,rh);row.arrow.TextSize=16
            UI.box(row.icon,22,(rh-14)/2,14,14);row.amount.TextSize=14;row.amount.Font=Enum.Font.BuilderSansBold;UI.box(row.amount,38,0,amountW,rh)
            local tx=40+amountW;row.target.TextSize=13;row.target.TextColor3=UI.colors.ink;row.target.Position=UDim2.fromOffset(tx,0);row.target.Size=UDim2.new(1,-tx-statusW-2,0,rh)
            row.status.TextSize=12;row.status.Position=UDim2.new(1,-statusW,0,0);row.status.Size=UDim2.fromOffset(statusW-4,rh)
            row.cancel.TextSize=touch and 20 or 18;row.cancel.Position=UDim2.new(1,-rh,0,0);row.cancel.Size=UDim2.fromOffset(rh,rh)
        end
        local base=math.max(0,self.frame.Size.Y.Offset-#list*step+(step-rh))
        row.frame.Position=UDim2.fromOffset(0,base+(i-1)*step);self.step=step
        row.focus.Size=UDim2.new(1,item.canCancel and -rh or 0,0,rh)
        row.arrow.Text=item.arrow;row.arrow.TextColor3=color;row.target.Text=item.target;row.amount.Text=UI.troops(item.operation.troops);row.amount.TextColor3=color;row.status.Text=item.status;row.status.TextColor3=color
        row.icon.ImageColor3=color
        row.cancel.Visible=item.canCancel;UI.enabled(row.cancel,not state.paused)
        UI.enabled(row.focus,item.operation.frontTile~=nil)
        row.frame:SetAttribute('FrontTile',item.operation.frontTile);row.frame:SetAttribute('Direction',item.operation.direction)
    end
    for key,row in pairs(self.rows)do if not alive[key]then row.frame:Destroy();self.rows[key]=nil end end
    self.frame.CanvasSize=UDim2.fromOffset(0,#list*(self.step or 48));self.frame.Visible=#list>0
    if incoming>0 and (self.frame:GetAttribute('IncomingCount')or 0)==0 then require(script.Parent.TelemetryStep).step('match','underAttack',{count=incoming})end
    self.frame:SetAttribute('OrderCount',#list);self.frame:SetAttribute('IncomingCount',incoming)
    self.peek.Text='↕ '..#list;self.peek.TextColor3=incoming>0 and UI.colors.danger or UI.colors.accent
end
return M
