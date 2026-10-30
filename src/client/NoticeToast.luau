local Tween=game:GetService('TweenService')
local UI=require(script.Parent.Theme)
local L=require(script.Parent.Localization)
local M={};M.__index=M
local GLASS=Color3.fromRGB(12,17,24)
local function v2()local ok,H=pcall(require,script.Parent.Hud20);return ok and type(H)=='table'and H.ENABLED==true end
local K
local function kit()K=K or require(script.Parent.Kit20);return K end
local function reduced()
    return (K and K.reduced)or game:GetService('Players').LocalPlayer:GetAttribute('CommanderReducedEffects')==true
end
function M.new(root,focus,onDismiss)
    local self=setmetatable({v2=v2()},M)
    local toast=UI.panel(root,'Toast');toast.ZIndex=17;toast.Visible=false;self.frame=toast
    local text=UI.label(toast,'Message','',14);text.Size=UDim2.new(1,-28,1,-12);text.Position=UDim2.fromOffset(14,6);self.text=text
    if self.v2 then self:build20()
    else
        text.TextScaled=true;UI.make('UITextSizeConstraint',text,{MaxTextSize=14,MinTextSize=10})
    end
    local hit=UI.make('TextButton',toast,{Name='Focus',Text='',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=29,AutoButtonColor=false,Visible=false,Active=false})
    hit.Activated:Connect(function()local tile=toast:GetAttribute('FocusTile');if tile then focus(tile)end end)
    self.gesture=require(script.Parent.NoticeGesture).attach(toast,text,onDismiss);toast.Active=true
    return self
end
function M:build20()
    kit()
    local toast,text=self.frame,self.text
    for _,s in ipairs(toast:GetChildren())do if s:IsA('UIStroke')and s.Name~='Stroke20'then s.Enabled=false end end
    toast.BackgroundTransparency=1;K.round(toast,10);K.stroke(toast,K.colors.line,1,.1,true)
    self.glass=K.fillBar(toast,'Glass20',{parts={{p=.01,color=K.colors.accent}},track=GLASS,trackAlpha=.14,r=10})
    self.glass.frame.Size=UDim2.fromScale(1,1);self.glass.frame.ZIndex=1
    self.body=K.make('Frame',toast,{Name='Body20',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=2,Active=false})
    text.Parent=self.body;text.ZIndex=3;text.TextScaled=false;text.TextColor3=K.colors.ink;if K.fonts[700]then text.FontFace=K.fonts[700]end
    text.TextXAlignment=Enum.TextXAlignment.Left;text.TextYAlignment=Enum.TextYAlignment.Center;text.TextTruncate=Enum.TextTruncate.AtEnd
    self.chev=K.icon(self.body,'chev',14,K.colors.muted,'Chev20');self.chev.ZIndex=3;self.chev.Visible=false
    toast:GetPropertyChangedSignal('Size'):Connect(function()self:paint20()end)
end
function M:place(lane,w,h,touch)
    if not self.v2 then UI.box(self.frame,lane.x,lane.y,lane.w,48);return end
    local fmt=require(script.Parent.MatchSheet).format(w,h,touch)
    local y,height=lane.y,fmt=='pc'and 48 or 40
    if lane.x<=12 then
        if fmt=='ph'then y=math.max(y,84)end
        local parent=self.frame.Parent;local chip=parent and parent:FindFirstChild('CampaignTask20')
        if chip and chip.Visible then y=math.max(y,chip.Position.Y.Offset+chip.Size.Y.Offset+6)end
    end
    K.box(self.frame,lane.x,y,lane.w,height)
    self.home=self.frame.Position
end
function M:dodge(sheets)
    local toast=self.frame;if self.home then toast.Position=self.home end
    local sheet;for i=1,4 do local f=sheets[i];if f and f.Parent and f.Visible and f.AbsoluteSize.X>0 then sheet=f;break end end
    local gui=toast:FindFirstAncestorWhichIsA('LayerCollector');if not sheet or not gui or toast.Size.Y.Offset<=0 then return end
    local tp,ts,sp,ss,G=toast.AbsolutePosition,toast.AbsoluteSize,sheet.AbsolutePosition,sheet.AbsoluteSize,gui.AbsoluteSize
    if tp.X>=sp.X+ss.X or tp.X+ts.X<=sp.X or tp.Y>=sp.Y+ss.Y or tp.Y+ts.Y<=sp.Y then return end
    local k=ts.Y/toast.Size.Y.Offset;local gap=8*k
    local gp=gui.AbsolutePosition;local top,bottom,left,right=math.max(gp.Y,0),gp.Y+G.Y,gp.X,gp.X+G.X
    local x,y=tp.X,nil
    if sp.Y-ts.Y-gap>=top+gap then y=sp.Y-ts.Y-gap
    elseif sp.Y+ss.Y+gap+ts.Y<=bottom-gap then y=sp.Y+ss.Y+gap
    elseif sp.X-ts.X-gap>=left+gap then x,y=sp.X-ts.X-gap,tp.Y
    elseif sp.X+ss.X+gap+ts.X<=right-gap then x,y=sp.X+ss.X+gap,tp.Y
    else x,y=sp.X+(ss.X-ts.X)/2,math.min(sp.Y+ss.Y,bottom)-ts.Y-gap end
    if y==sp.Y-ts.Y-gap or y==sp.Y+ss.Y+gap then x=math.clamp(sp.X+(ss.X-ts.X)/2,left+gap,math.max(left+gap,right-ts.X-gap))end
    toast.Position=toast.Position+UDim2.fromOffset(math.floor((x-tp.X)/k),math.floor((y-tp.Y)/k))
end
function M:paint20()
    local toast,text=self.frame,self.text
    local w,h=toast.Size.X.Offset,toast.Size.Y.Offset;if w<=0 or h<=0 then return end
    self.glass:setParts({{p=3/w,color=self.band or K.colors.accent}})
    local right=self.chev.Visible and 32 or 14;local tw=w-15-right
    K.box(text,15,2,tw,h-4);K.box(self.chev,w-26,math.floor((h-14)/2),14,14)
    local msg=L.text(text.Text);local size=h>=48 and 14 or 13
    while size>12 and K.width(msg,size,text)>tw do size-=1 end
    text.TextSize=size;text.TextWrapped=K.width(msg,size,text)>tw
end
function M:appear20()
    local body=self.body
    if self.rise then self.rise:Cancel();self.rise=nil end
    K.fade(self.frame,false,0)
    if reduced()then body.Position=UDim2.new();K.fade(self.frame,true,.12);return end
    body.Position=UDim2.fromOffset(0,6)
    self.rise=Tween:Create(body,TweenInfo.new(.16,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),{Position=UDim2.new()});self.rise:Play()
    K.fade(self.frame,true,.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
end
function M:show(n,touch)
    local toast,text=self.frame,self.text
    if not self.v2 then
        self.gesture.appear()
        text.Text=n.tile and L.text(n.message).."  ›" or n.message;text.TextColor3=n.warning and UI.colors.danger or UI.colors.accent
        text.TextSize=14
    else
        self.band=n.warning and K.colors.danger or K.colors.accent
        text.Text=n.message;self.chev.Visible=n.tile~=nil
        self:paint20();self:appear20()
    end
    toast:SetAttribute('FocusTile',n.tile)
    local hit=toast.Focus;hit.Visible=n.tile~=nil;hit.Active=hit.Visible
    hit.Position=touch and UDim2.new(0,0,.5,-40)or UDim2.new();hit.Size=touch and UDim2.new(1,0,0,80)or UDim2.fromScale(1,1)
end
return M
