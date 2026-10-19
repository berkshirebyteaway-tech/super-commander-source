local UI=require(script.Parent.Theme)
local M={};M.__index=M
function M.new(parent)
    local self=setmetatable({parent=parent},M)
    local f=UI.make('Frame',parent,{Name='LandingTarget',Size=UDim2.fromOffset(38,38),AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1,BorderSizePixel=0,Visible=false,ZIndex=18});self.frame=f
    local ring=UI.make('Frame',f,{Name='Ring',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0});UI.corner(ring,999);self.stroke=UI.stroke(ring,UI.colors.accent,2)
    self.center=UI.make('Frame',f,{Name='Center',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(6,6),BackgroundColor3=UI.colors.accent,BorderSizePixel=0});UI.corner(self.center,999)
    self.caption=UI.label(f,'Caption','착륙 지점',12,UI.colors.ink);UI.box(self.caption,-41,40,120,20);self.caption.TextXAlignment=Enum.TextXAlignment.Center;self.caption.TextStrokeTransparency=.15
    return self
end
function M:hide()self.frame.Visible=false end
function M:step(at,color,visible,valid)
    self.frame.Visible=visible;if not visible then return end
    local p=workspace.CurrentCamera:WorldToScreenPoint(at)
    local origin=self.parent.AbsolutePosition;local size=self.parent.AbsoluteSize/UI.scale
    local x,y=(p.X-origin.X)/UI.scale,(p.Y-origin.Y)/UI.scale
    if p.Z<0 then x=size.X-x;y=size.Y-y end
    self.frame.Position=UDim2.fromOffset(math.clamp(x,28,math.max(28,size.X-28)),math.clamp(y,76,math.max(76,size.Y-156)))
    self.stroke.Color=color;self.center.BackgroundColor3=color
    local text=valid==false and '자동 배치'or '착륙 지점'
    if self.caption.Text~=text then self.caption.Text=text end
end
return M
