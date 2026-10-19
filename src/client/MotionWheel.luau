local UI=require(script.Parent.Theme)
local Loadout=require(script.Parent.Parent.Core.MotionLoadout)
local Icons=require(script.Parent.OutgameIcons)
local Motions=require(script.Parent.MotionsPage)
local M={};M.__index=M
function M.new(parent,account,allowed)
    local self=setmetatable({account=account,allowed=allowed},M)
    self.frame=UI.panel(parent,'MotionWheel');self.frame.ZIndex=29;self.frame.Size=UDim2.fromOffset(286,286);self.frame.AnchorPoint=Vector2.new(.5,.5);self.frame.Position=UDim2.fromScale(.5,.5);self.frame.Visible=false
    local close=UI.button(self.frame,'Close','×',function()self.frame.Visible=false end);UI.box(close,121,121,44,44)
    self.buttons={}
    for i=1,6 do
        local angle=-math.pi/2+(i-1)*math.pi/3
        local b=UI.button(self.frame,'Slot'..i,'',function()local m=self.buttons[i].motion;if m then require(script.Parent.TelemetryStep).step('character','motionWheel',{item=require(script.Parent.TelemetryStep).code(m.id),value=i});Motions.play(m);self.frame.Visible=false end end)
        UI.box(b,143+math.cos(angle)*96-40,143+math.sin(angle)*96-32,80,64)
        local name=UI.label(b,'Name','',11);UI.box(name,3,36,74,22);name.TextXAlignment=Enum.TextXAlignment.Center
        local icon=Icons.create(b,'reward',24,UI.colors.accent);UI.box(icon,28,8,24,24);icon.Visible=false
        self.buttons[i]={button=b,label=name,icon=icon}
    end
    game:GetService('UserInputService').InputBegan:Connect(function(input,processed)
        if processed or game:GetService('UserInputService'):GetFocusedTextBox()then return end
        if input.KeyCode==Enum.KeyCode.M then self:toggle()
        elseif self.frame.Visible and (input.KeyCode==Enum.KeyCode.X or input.KeyCode==Enum.KeyCode.Escape)then self.frame.Visible=false end
    end)
    return self
end
function M:toggle()
    if self.frame.Visible then self.frame.Visible=false;return end
    if self.sheet and self.sheet()then return end
    if not self.allowed()then return end
    local VipLock=require(script.Parent.VipLock);if not VipLock.allows('motion')then return VipLock.open('motion')end
    local a=self.account()or {};local list=Loadout.copy((a.preferences or {}).motionLoadout,(a.progress or {}).level or 1)
    for i,b in ipairs(self.buttons)do
        b.motion=Loadout.find(list[i]);b.label.Text=b.motion and b.motion.name or '비어 있음';UI.enabled(b.button,b.motion~=nil)
        b.icon.Visible=b.motion~=nil;if b.motion then Icons.set(b.icon,Motions.icons[b.motion.id]or 'reward')end
    end
    self.frame.Visible=true
end
function M:step()if self.frame.Visible and not self.allowed()then self.frame.Visible=false end end
return M
