local UI=require(script.Parent.Theme)
local Receipt=require(script.Parent.ActionReceipt)
local Layout=require(script.Parent.Parent.Core.InterfacePlacement)
local M={};M.__index=M
function M.new(parent,flow)
    local self=setmetatable({flow=flow},M)
    self.frame=UI.panel(parent,'CommandFeedback');self.frame.ZIndex=23;self.frame.Visible=false
    self.bar=require(script.Parent.EdgeMask).fit(UI.make('Frame',self.frame,{Name='State',Size=UDim2.new(0,3,1,0),BackgroundColor3=UI.colors.accent,BorderSizePixel=0}))
    self.title=UI.label(self.frame,'Action','',14);self.title.Font=Enum.Font.BuilderSansBold;self.title.TextWrapped=false;self.title.TextTruncate=Enum.TextTruncate.AtEnd
    self.text=UI.label(self.frame,'Message','',14);self.text.TextWrapped=false;self.text.TextTruncate=Enum.TextTruncate.AtEnd
    self.phase=UI.label(self.frame,'Phase','',18);self.phase.TextXAlignment=Enum.TextXAlignment.Center
    return self
end
function M:begin(id,action,version,description,now)
    if not description then return end
    require(script.Parent.ToyAudio).press(action,description)
    self.current={id=id,action=action,version=version,description=description,at=now or os.clock(),phase='input'}
    if self.icon then self.icon:Destroy()end
    self.icon=require(script.Parent.HotbarIcons).create(self.frame,description.icon,20,UI.colors.ice)
    self:layout(self.w or 800,self.h or 600)
end
function M:result(result,version,now)
    local n=self.current;if not Receipt.accepts(n,result,version)then return end
    n.phase=result.ok and 'accepted'or 'refused';n.message=result.message;n.expires=(now or os.clock())+(result.ok and .85 or 3)
end
function M:reset()self.current=nil;self.lastPhase=nil;self.frame.Visible=false end
function M:layout(w,h,anchorX,blocks)
    self.w=w;self.h=h;if blocks then self.blocks=blocks end
    local n=self.current
    local p=Layout.command(w,h)
    p.h=n and n.phase=='refused'and 88 or 48
    UI.box(self.frame,p.x,p.y,p.w,p.h);UI.box(self.title,36,2,p.w-66,22);UI.box(self.text,36,24,p.w-48,p.h-28);UI.box(self.phase,p.w-28,2,24,22)
    if self.icon then UI.box(self.icon,10,14,20,20)end
end
function M:step(hidden)
    local n=self.current;local now=os.clock()
    if n and not n.expires and now-n.at>=8 then n.phase='unknown';n.expires=now+4 end
    if n and not n.expires and now-n.at>=.22 then n.phase='pending'end
    local useful=n and (n.phase=='refused'or n.phase=='unknown'or not n.expires and now-n.at>=1)
    self.frame.Visible=not hidden and useful==true and (not n.expires or now<n.expires);if not self.frame.Visible then return end
    if self.lastPhase~=n.phase then self.lastPhase=n.phase;self:layout(self.w,self.h)end
    local d=n.description
    self.title.Text=d.title..(d.target~=''and ' → '..d.target or '')
    self.text.TextWrapped=n.phase=='refused';self.text.TextTruncate=n.phase=='refused'and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd
    self.text.Text=n.phase=='refused'and (n.message or '실행 실패')or n.phase=='unknown'and '응답 지연'or (d.quantity~=''and d.quantity..' 'or '')..(n.phase=='accepted'and '지시 전달'or n.phase=='pending'and '요청 중…'or '입력 확인')
    self.phase.Text=n.phase=='accepted'and '✓'or n.phase=='refused'and '!'or n.phase=='unknown'and '?'or '···'
    local color=n.phase=='accepted'and UI.colors.good or n.phase=='refused'and UI.colors.danger or n.phase=='unknown'and UI.colors.gold or UI.colors.accent
    self.bar.BackgroundColor3=color;self.text.TextColor3=color
    self.frame:SetAttribute('Phase',n.phase)
end
return M
