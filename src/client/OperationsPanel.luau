local UI=require(script.Parent.Theme)
local Icons=require(script.Parent.UIIcons)
local P=require(script.Parent.Parent.Core.OperationPresentation)
local M={};M.__index=M
function M.new(parent,renderer,send,expand)
    local self=setmetatable({rows={},renderer=renderer,send=send},M)
    self.frame=UI.make('ScrollingFrame',parent,{Name='Operations',BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=UI.colors.line,CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.Y,ZIndex=12,Visible=false})
    self.peek=UI.button(parent,'OperationsPeek','',function()expand();self.frame.CanvasPosition=Vector2.zero end)
    self.peek.ZIndex=16;self.peek.TextSize=14;self.peek.Visible=false
    return self
end
function M:update(state,factions)
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
        local compact=not require(script.Parent.InputMode).touch();local rh=compact and 28 or 44;local step=compact and 32 or 48
        if row.compact~=compact then row.compact=compact
            if compact then
                row.frame.Size=UDim2.new(1,-5,0,rh);UI.box(row.arrow,2,0,18,rh);row.arrow.TextSize=16
                UI.box(row.icon,22,7,14,14);row.amount.TextSize=14;row.amount.Font=Enum.Font.BuilderSansBold;UI.box(row.amount,38,0,52,rh)
                row.target.TextSize=13;row.target.TextColor3=UI.colors.ink;row.target.Position=UDim2.fromOffset(92,0);row.target.Size=UDim2.new(1,-92-58,0,rh)
                row.status.TextSize=12;row.status.Position=UDim2.new(1,-56,0,0);row.status.Size=UDim2.fromOffset(52,rh)
                row.cancel.TextSize=18;row.cancel.Position=UDim2.new(1,-rh,0,0);row.cancel.Size=UDim2.fromOffset(rh,rh)
            else
                row.frame.Size=UDim2.new(1,-5,0,44);UI.box(row.arrow,0,0,28,44);row.arrow.TextSize=22
                UI.box(row.icon,32,22,18,18);row.amount.TextSize=16;row.amount.Font=Enum.Font.BuilderSansMedium;row.amount.Position=UDim2.fromOffset(54,20);row.amount.Size=UDim2.new(1,-120,0,22)
                row.target.TextSize=14;row.target.Position=UDim2.fromOffset(32,2);row.target.Size=UDim2.new(1,-36,0,18)
                row.status.TextSize=14;row.status.Position=UDim2.new(1,-60,0,21);row.status.Size=UDim2.fromOffset(56,20)
                row.cancel.TextSize=23;row.cancel.Position=UDim2.new(1,-44,0,0);row.cancel.Size=UDim2.fromOffset(44,44)
            end
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
