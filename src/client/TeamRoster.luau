local UI=require(script.Parent.Theme)
local Colors=require(script.Parent.FactionColors)
local Me=game.Players.LocalPlayer
local M={};M.__index=M
function M.new(parent,callbacks)
    local self=setmetatable({callbacks=callbacks or {}},M)
    self.backdrop=UI.make('TextButton',parent,{Name='TeamRosterBackdrop',Size=UDim2.fromScale(1,1),Text='',BackgroundColor3=UI.colors.bg,BackgroundTransparency=.45,BorderSizePixel=0,AutoButtonColor=false,ZIndex=30,Visible=false})
    self.backdrop.Activated:Connect(function()self:hide()end)
    self.frame=UI.panel(parent,'TeamRoster');self.frame.ZIndex=31;self.frame.Visible=false;self.frame.Active=true;self.frame.BackgroundTransparency=.03
    self.title=UI.label(self.frame,'Title','팀 편성',18,UI.colors.ink);self.title.ZIndex=32;self.title.Font=Enum.Font.BuilderSansBold
    self.close=UI.button(self.frame,'Close','×',function()self:hide()end);self.close.ZIndex=32
    self.hint=UI.label(self.frame,'Hint','',13,UI.colors.muted);self.hint.ZIndex=32
    self.body=UI.make('ScrollingFrame',self.frame,{Name='Members',BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=UI.colors.line,ScrollingDirection=Enum.ScrollingDirection.Y,ZIndex=32,CanvasSize=UDim2.fromOffset(0,0)})
    self.footer=UI.make('Frame',self.frame,{Name='Choices',BackgroundTransparency=1,ZIndex=32})
    return self
end
function M:hide()self.frame.Visible=false;self.backdrop.Visible=false;self.id=nil end
function M:open(field)self.id=field.id or field.field;self.frame.Visible=true;self.backdrop.Visible=true;self:update(field)end
function M:update(field)
    if not self.frame.Visible then return end
    if not field or (field.id or field.field)~=self.id or not field.teamPlan then self:hide();return end
    local size=self.frame.Parent.AbsoluteSize
    if self.field==field and self.lastSize==size then return end
    self.field=field;self.lastSize=size;self:draw()
end
function M:draw()
    local f=self.field;local plan=f and f.teamPlan;if not plan then return end
    local size=self.frame.Parent.AbsoluteSize/UI.scale;local width=math.min(400,size.X-24);local height=math.min(520,size.Y-16)
    UI.box(self.frame,(size.X-width)/2,8,width,height);UI.box(self.title,12,6,width-72,32);UI.box(self.close,width-52,2,44,44)
    self.hint.Text=plan.locked and '팀 확정, 출발 준비 중'or plan.selectable and '팀을 바꾸면 모두 다시 준비해요.'or '자동 배정, 출발 전에 확인하세요.'
    self.hint.TextColor3=plan.locked and UI.colors.gold or UI.colors.muted;UI.box(self.hint,12,42,width-24,32)
    self.body:ClearAllChildren();self.footer:ClearAllChildren()
    local choose=plan.selectable and self.callbacks.choose and self.callbacks.canChoose and self.callbacks.canChoose(self.id)and not plan.locked
    local columns=math.min(6,math.floor((width-20)/48));local rows=choose and math.ceil((plan.count+1)/columns)or 0
    local footerH=choose and rows*48+20 or 24;UI.box(self.body,10,78,width-20,height-86-footerH);UI.box(self.footer,10,height-footerH-8,width-20,footerH)
    local ownTeam=plan.teams[tostring(Me.UserId)];local y=0
    for team=1,plan.count do
        local color=Colors.team(team,ownTeam);local count=plan.counts[team]or plan.counts[tostring(team)]or 0
        local title=UI.label(self.body,'Team'..team,string.format('%d팀',team),15,color);title.ZIndex=33;title.Font=Enum.Font.BuilderSansBold;UI.box(title,4,y,width-40,28);y+=30
        local shown=0
        for _,m in ipairs(f.members or {})do if plan.teams[tostring(m.userId)]==team then
            shown+=1;local row=UI.panel(self.body,'Member'..m.userId);row.ZIndex=33;UI.box(row,2,y,width-28,44)
            if m.userId==Me.UserId then row.BackgroundColor3=UI.colors.accent:Lerp(UI.colors.panel,.9)end
            local face=UI.make('ImageLabel',row,{Name='Avatar',Image='rbxthumb://type=AvatarHeadShot&id='..m.userId..'&w=150&h=150',BackgroundTransparency=1,ZIndex=34});UI.box(face,6,6,32,32)
            local name=UI.label(row,'Name',m.name or '',14,UI.colors.ink);name.ZIndex=34;name.TextWrapped=false;name.TextTruncate=Enum.TextTruncate.AtEnd;name:SetAttribute('LocalizationSkip',true);UI.box(name,46,0,width-150,44)
            local ready=UI.label(row,'Ready',m.ready and '준비 완료'or '',12,UI.colors.accent);ready.ZIndex=34;UI.box(ready,width-104,0,68,44);y+=48
        end end
        local ai=plan.aiCounts and (plan.aiCounts[team]or plan.aiCounts[tostring(team)])or 0
        if ai>0 or f.rules.teamFormat=='HumansVsNations'and team==2 then local text=UI.label(self.body,'AI'..team,ai>0 and string.format('AI 지휘관 %d명',ai)or 'AI 국가',13,UI.colors.muted);text.ZIndex=33;UI.box(text,8,y,width-44,28);y+=30
        elseif shown==0 then local empty=UI.label(self.body,'Empty'..team,'모집 중',12,UI.colors.muted);empty.ZIndex=33;UI.box(empty,8,y,width-44,26);y+=28 end
        y+=8
    end
    self.body.CanvasSize=UDim2.fromOffset(0,y)
    if choose then
        local selected=0;for _,m in ipairs(f.members or {})do if m.userId==Me.UserId then selected=m.team or 0;break end end
        local bw=math.floor((width-20-(columns-1)*4)/columns)
        for team=0,plan.count do local b=UI.button(self.footer,'Choose'..team,team==0 and '자동'or string.format('%d팀',team),function()self.callbacks.choose(team,f.revision,self.id)end,selected==team);b.ZIndex=33;b.TextSize=13;UI.box(b,(team%columns)*(bw+4),(team//columns)*48,bw,44)end
    else local note=UI.label(self.footer,'Fixed','경기 시작 후 팀은 고정돼요.',12,UI.colors.muted);note.ZIndex=33;UI.box(note,2,0,width-24,24)end
end
return M
