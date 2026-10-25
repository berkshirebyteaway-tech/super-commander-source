local UIS=game:GetService('UserInputService')
local RunService=game:GetService('RunService')
local UI=require(script.Parent.Theme)
local Telemetry=require(script.Parent.TelemetryClient)
local M={};M.__index=M
M.hidden=false
local function eye(parent)
    local g=UI.make('Frame',parent,{Name='Eye',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(18,11),BackgroundTransparency=1,Active=false})
    local lid=UI.make('Frame',g,{Name='Lid',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Active=false});UI.make('UICorner',lid,{CornerRadius=UDim.new(1,0)})
    local edge=UI.make('UIStroke',lid,{Color=UI.colors.ink,Thickness=1.6})
    local pupil=UI.make('Frame',g,{Name='Pupil',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(5,5),BackgroundColor3=UI.colors.ink,BorderSizePixel=0,Active=false});UI.make('UICorner',pupil,{CornerRadius=UDim.new(1,0)})
    local slash=UI.make('Frame',g,{Name='Slash',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(22,2),Rotation=-35,BackgroundColor3=UI.colors.ink,BorderSizePixel=0,Visible=false,Active=false})
    return {edge=edge,pupil=pupil,slash=slash}
end
function M.new(lobby)
    local self=setmetatable({lobby=lobby,hiddenSet={}},M)
    local b=UI.button(lobby.frame,'HideLobbyUI','',function()self:set(not M.hidden,'button')end)
    b.ZIndex=31;b.BackgroundColor3=UI.colors.bg;b.BackgroundTransparency=.35
    local s=b:FindFirstChildOfClass('UIStroke');if s then s.Color=UI.colors.line;s.Transparency=.2 end
    self.button=b;self.glyph=eye(b)
    self.key=UIS.InputBegan:Connect(function(input,processed)
        if processed or UIS:GetFocusedTextBox()or input.KeyCode~=Enum.KeyCode.U then return end
        if self.button.Parent and (self.allowed or M.hidden)then self:set(not M.hidden,'key')end
    end)
    local t=0
    self.tick=RunService.Heartbeat:Connect(function(dt)
        if not lobby.frame.Parent then self.tick:Disconnect();self.key:Disconnect();return end
        t+=dt;if t<.2 then return end;t=0
        if M.hidden then self:enforce()end
    end)
    return self
end
function M:keep(o)return o==self.button or o==self.lobby.copyright end
function M:enforce()
    for _,o in ipairs(self.lobby.frame:GetChildren())do
        if o:IsA('GuiObject')and o.Visible and not self:keep(o)then self.hiddenSet[o]=true;o.Visible=false end
    end
end
function M:restore()
    for o in pairs(self.hiddenSet)do if o.Parent then o.Visible=true end end
    table.clear(self.hiddenSet)
end
function M:set(hide,source)
    if hide==M.hidden then return end
    M.hidden=hide
    Telemetry.step('lobby',hide and 'hideUI' or 'showUI',{source=source})
    if hide then require(script.Parent.LobbyJump).set(nil);self:enforce()else self:restore();self.lobby:layout()end
    self:paint()
end
function M:paint()
    local g=self.glyph;local hide=M.hidden
    g.slash.Visible=hide;g.edge.Color=hide and UI.colors.muted or UI.colors.ink;g.pupil.BackgroundColor3=hide and UI.colors.muted or UI.colors.ink
    self.button.BackgroundTransparency=hide and .55 or .35
end
function M:apply(w,h,home,lift,spot)
    local short=h<500;local narrow=w<600
    if require(script.Parent.LobbyHomeB).START_FLOW then
        if M.hidden then M.hidden=false;self:restore()end;self.allowed=false;self.button.Visible=false;return
    end
    self.allowed=home==true
    if M.hidden and not home then M.hidden=false;table.clear(self.hiddenSet);self:paint()end
    local touch=UIS.TouchEnabled and not UIS.MouseEnabled
    local size=spot and 48 or (touch or short)and 32 or 30
    local x,y
    if spot then x,y=spot.X,spot.Y
    elseif narrow then x,y=w-12-76-8-size,82
    elseif short then x,y=238,h-size-2-(lift or 0)
    else x,y=w-24-size,h-72-8-size end
    UI.box(self.button,x,y,size,size)
    self.button.Visible=home==true or M.hidden
    self:paint()
    if M.hidden then self:enforce()end
end
return M
