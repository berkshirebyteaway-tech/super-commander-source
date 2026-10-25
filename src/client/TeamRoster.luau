local UI=require(script.Parent.Theme)
local Colors=require(script.Parent.FactionColors)
local Me=game.Players.LocalPlayer
local M={};M.__index=M
local function v2()return require(script.Parent.Lobby20).ENABLED end
local Z=50
local function depthZ(root,base)
    local function walk(o,z)for _,c in ipairs(o:GetChildren())do if c:IsA('GuiObject')then c.ZIndex=c.Name=='Depth'and z-1 or z;walk(c,z+1)else walk(c,z)end end end
    if root:IsA('GuiObject')then root.ZIndex=base end;walk(root,base+1)
end
function M.new(parent,callbacks)
    local self=setmetatable({callbacks=callbacks or {}},M)
    if v2()then return self:new20(parent)end
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
function M:new20(parent)
    local K=require(script.Parent.Kit20);local S=require(script.Parent.Sheet20)
    self.v2=true;self.parent=parent
    self.backdrop=K.make('TextButton',parent,{Name='TeamRosterBackdrop',Size=UDim2.fromScale(1,1),Text='',BackgroundColor3=S.DIM,BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,ZIndex=Z,Visible=false})
    self.backdrop.Activated:Connect(function()self:hide()end)
    self.frame=K.make('Frame',parent,{Name='TeamRoster',BackgroundColor3=S.BG,BorderSizePixel=0,Active=true,Visible=false,ZIndex=Z+1})
    K.round(self.frame,12);K.stroke(self.frame,K.colors.line,1)
    return self
end
function M:hide()
    if self.v2 then
        local K=require(script.Parent.Kit20);local Tween=game:GetService('TweenService')
        self.id=nil
        if self.backdrop.Visible then
            local t=Tween:Create(self.backdrop,TweenInfo.new(K.reduced and .12 or .10,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{BackgroundTransparency=1});t:Play()
            t.Completed:Once(function()if not self.id then self.backdrop.Visible=false end end)
        end
        K.leave(self.frame,{dy=self.fmt=='pt'and 24 or 0,t=.10})
        return
    end
    self.frame.Visible=false;self.backdrop.Visible=false;self.id=nil
end
function M:open(field)
    self.id=field.id or field.field
    if self.v2 then
        local K=require(script.Parent.Kit20);local Tween=game:GetService('TweenService')
        local was=self.frame.Visible and self.frame:GetAttribute('Moving20')~='out'
        self.frame.Visible=true;self.backdrop.Visible=true;self.field=nil;self:update(field)
        if not was then
            local alpha=self.fmt=='pt'and .4 or .28
            Tween:Create(self.backdrop,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=alpha}):Play()
            self.frame.Visible=false;self.frame:SetAttribute('Shown20',false);K.rehome(self.frame)
            if self.fmt=='pt'then K.appear(self.frame,{dy=24,t=.16})else K.appear(self.frame,{scaleFrom=.96,t=.16})end
        end
        return
    end
    self.frame.Visible=true;self.backdrop.Visible=true;self:update(field)
end
function M:update(field)
    if not self.frame.Visible then return end
    if not field or (field.id or field.field)~=self.id or not field.teamPlan then self:hide();return end
    local size=self.frame.Parent.AbsoluteSize
    if self.field==field and self.lastSize==size then return end
    self.field=field;self.lastSize=size
    if self.v2 then self:draw20()else self:draw()end
end
function M:draw()
    local f=self.field;local plan=f and f.teamPlan;if not plan then return end
    local size=self.frame.Parent.AbsoluteSize/UI.scale;local width=math.min(400,size.X-24);local height=math.min(520,size.Y-16)
    UI.box(self.frame,(size.X-width)/2,8,width,height);UI.box(self.title,12,6,width-72,32);UI.box(self.close,width-52,2,44,44)
    self.hint.Text=plan.locked and '팀 확정'or ''
    self.hint.TextColor3=plan.locked and UI.colors.gold or UI.colors.muted;UI.box(self.hint,12,42,width-24,32)
    self.body:ClearAllChildren();self.footer:ClearAllChildren()
    local choose=plan.selectable and self.callbacks.choose and self.callbacks.canChoose and self.callbacks.canChoose(self.id)and not plan.locked
    local columns=math.min(6,math.floor((width-20)/48));local rows=choose and math.ceil((plan.count+1)/columns)or 0
    local footerH=choose and rows*48+20 or 24;UI.box(self.body,10,78,width-20,height-86-footerH);UI.box(self.footer,10,height-footerH-8,width-20,footerH)
    local ownTeam=plan.teams[tostring(Me.UserId)];local y=0
    local hvn=f.rules and f.rules.teamFormat=='HumansVsNations'
    for team=1,plan.count do
        local color=Colors.team(team,ownTeam);local count=plan.counts[team]or plan.counts[tostring(team)]or 0
        local title=UI.label(self.body,'Team'..team,hvn and (team==1 and '사람 팀'or '국가 팀')or string.format('%d팀',team),15,color);title.ZIndex=33;title.Font=Enum.Font.BuilderSansBold;UI.box(title,4,y,width-40,28);y+=30
        local shown=0
        for _,m in ipairs(f.members or {})do if plan.teams[tostring(m.userId)]==team then
            shown+=1;local row=UI.panel(self.body,'Member'..m.userId);row.ZIndex=33;UI.box(row,2,y,width-28,44)
            if m.userId==Me.UserId then row.BackgroundColor3=UI.colors.accent:Lerp(UI.colors.panel,.9)end
            local face=UI.make('ImageLabel',row,{Name='Avatar',Image='rbxthumb://type=AvatarHeadShot&id='..m.userId..'&w=150&h=150',BackgroundTransparency=1,ZIndex=34});UI.box(face,6,6,32,32)
            local name=UI.label(row,'Name',m.name or '',14,UI.colors.ink);name.ZIndex=34;name.TextWrapped=false;name.TextTruncate=Enum.TextTruncate.AtEnd;name:SetAttribute('LocalizationSkip',true);UI.box(name,46,0,width-150,44)
            local ready=UI.label(row,'Ready',m.ready and '준비 완료'or '',12,UI.colors.accent);ready.ZIndex=34;UI.box(ready,width-104,0,68,44);y+=48
        end end
        local ai=plan.aiCounts and (plan.aiCounts[team]or plan.aiCounts[tostring(team)])or 0
        if ai>0 or f.rules.teamFormat=='HumansVsNations'and team==2 then local text=UI.label(self.body,'AI'..team,hvn and (ai>0 and string.format('어려운 국가 %d명',ai)or '사람 수만큼 어려운 국가')or ai>0 and string.format('AI 지휘관 %d명',ai)or 'AI 국가',13,UI.colors.muted);text.ZIndex=33;UI.box(text,8,y,width-44,28);y+=30
        elseif shown==0 then local empty=UI.label(self.body,'Empty'..team,'모집 중',12,UI.colors.muted);empty.ZIndex=33;UI.box(empty,8,y,width-44,26);y+=28 end
        y+=8
    end
    self.body.CanvasSize=UDim2.fromOffset(0,y)
    if choose then
        local selected=0;for _,m in ipairs(f.members or {})do if m.userId==Me.UserId then selected=m.team or 0;break end end
        local bw=math.floor((width-20-(columns-1)*4)/columns)
        for team=0,plan.count do local b=UI.button(self.footer,'Choose'..team,team==0 and '자동'or string.format('%d팀',team),function()self.callbacks.choose(team,f.revision,self.id)end,selected==team);b.ZIndex=33;b.TextSize=13;UI.box(b,(team%columns)*(bw+4),(team//columns)*48,bw,44)end
    end
end
function M:draw20()
    local K=require(script.Parent.Kit20);local S=require(script.Parent.Sheet20);local C=K.colors
    local f=self.field;local plan=f and f.teamPlan;if not plan then return end
    local scale=UI.scale or 1;local W,H=self.frame.Parent.AbsoluteSize.X/scale,self.frame.Parent.AbsoluteSize.Y/scale
    local fmt=S.format(W,H);self.fmt=fmt;local pt,ph=fmt=='pt',fmt=='ph'
    local root=self.frame
    for _,o in ipairs(root:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
    local choose=plan.selectable and self.callbacks.choose and self.callbacks.canChoose and self.callbacks.canChoose(self.id)and not plan.locked
    local hvn=f.rules and f.rules.teamFormat=='HumansVsNations'
    local ownTeam=plan.teams[tostring(Me.UserId)]
    local pad=pt and 16 or ph and 12 or 20
    local width=pt and W or K.even(math.min(460,W-(ph and 24 or 48)))
    local headH=pt and 56 or ph and 46 or 60
    local cellH=pt and 44 or ph and 36 or 40
    local items={{0,'자동'}};for t=1,plan.count do table.insert(items,{t,hvn and (t==1 and '사람 팀'or '국가 팀')or string.format('%d팀',t)})end
    local segment=choose and #items<=6
    local cols=segment and #items or math.max(1,math.min(4,math.floor((width-pad*2+8)/96)))
    local footH=choose and (segment and cellH or math.ceil(#items/cols)*(cellH+8)-8)+pad+(pt and 8 or 0) or 0
    local inner=width-pad*2
    local rowH=pt and 44 or ph and 40 or 44;local teamHead=pt and 32 or ph and 28 or 32;local gap=pt and 10 or 8
    local blocks={};local contentH=0
    for team=1,plan.count do
        local list={};for _,m in ipairs(f.members or {})do if plan.teams[tostring(m.userId)]==team then table.insert(list,m)end end
        table.sort(list,function(a,b)return (a.userId==Me.UserId and 0 or 1)<(b.userId==Me.UserId and 0 or 1)end)
        local ai=plan.aiCounts and (plan.aiCounts[team]or plan.aiCounts[tostring(team)])or 0
        local aiText
        if ai>0 or f.rules.teamFormat=='HumansVsNations'and team==2 then aiText=hvn and (ai>0 and string.format('어려운 국가 %d명',ai)or '사람 수만큼 어려운 국가')or ai>0 and string.format('AI 지휘관 %d명',ai)or 'AI 국가'end
        local empty=#list==0 and not aiText
        local h=6+teamHead+#list*(rowH+4)+(aiText and (pt and 40 or 36)+4 or 0)+(empty and 28 or 0)+6
        table.insert(blocks,{team=team,list=list,ai=aiText,empty=empty,h=h,mine=ownTeam~=nil and team==ownTeam,count=plan.counts[team]or plan.counts[tostring(team)]or #list})
        contentH+=h+gap
    end
    contentH=math.max(0,contentH-gap)
    table.sort(blocks,function(a,b)if a.mine~=b.mine then return a.mine end;return a.team<b.team end)
    local maxH=pt and math.floor(H*.86) or ph and H-16 or math.min(600,H-96)
    local height=math.min(maxH,headH+contentH+8+footH+pad)
    if pt then height=math.max(height,math.floor(H*.5))else height=K.even(height)end
    local x,y=math.floor((W-width)/2),pt and H-height or math.floor((H-height)/2)+(ph and 0 or 20)
    if not pt then y=math.max(ph and 8 or 66,y)end
    K.round(root,pt and 16 or 12)
    local bh=height+(pt and 16 or 0)
    root.AnchorPoint=pt and Vector2.zero or Vector2.new(.5,.5)
    local goal=pt and UDim2.fromOffset(x,y)or UDim2.fromOffset(x+width/2,y+bh/2)
    if root:GetAttribute('Moving20')then root:SetAttribute('Home20',goal)else root.Position=goal;root:SetAttribute('Home20',goal)end
    root.Size=UDim2.fromOffset(width,bh)
    local title=K.text(root,'Title','팀 편성',pt and 20 or ph and 18 or 22,C.ink,800);local tw=K.width('팀 편성',title.TextSize,title)
    K.box(title,pad,pt and 10 or ph and 6 or 10,tw+4,40)
    if plan.locked then
        local chip=K.chip(root,'Hint','팀 확정','muted',{size=12,height=24,icon='lock'})
        chip.Position=UDim2.fromOffset(pad+tw+12,(pt and 10 or ph and 6 or 10)+8)
    end
    local close=S.iconButton(root,'Close','x',40,18,function()self:hide()end)
    close:place(width-pad-40+(pt and 0 or 4),pt and 10 or ph and 6 or 10,40,40)
    local listTop=headH;local listBottom=height-(choose and footH or pad)
    local scroll=S.scroll(root,'Members',pad,listTop,inner,listBottom-listTop)
    local cy=0;local made={}
    for _,b in ipairs(blocks)do
        local panel=K.make('Frame',scroll,{Name='Team'..b.team,BorderSizePixel=0});K.round(panel,10);K.box(panel,0,cy,inner,b.h)
        panel.BackgroundColor3=b.mine and C.accent or C.panel;panel.BackgroundTransparency=b.mine and .93 or .4
        K.stroke(panel,b.mine and C.accent or C.line,1,b.mine and .65 or 0,true)
        local color=Colors.team(b.team,ownTeam)
        local bar=K.make('Frame',panel,{Name='Bar',BackgroundColor3=b.mine and C.accent or color,BorderSizePixel=0});K.round(bar,'pill');K.box(bar,12,6+math.floor((teamHead-18)/2),4,18)
        local name=hvn and (b.team==1 and '사람 팀'or '국가 팀')or string.format('%d팀',b.team)
        local tl=K.text(panel,'Name',name,pt and 15 or ph and 13 or 15,b.mine and C.accent or C.ink,900);K.box(tl,24,6,inner-90,teamHead)
        local cnt=K.num(panel,'Count',tostring(b.count),pt and 15 or ph and 13 or 15,C.muted,Enum.TextXAlignment.Right);K.box(cnt,inner-72,6,60,teamHead)
        local ry=6+teamHead
        for _,m in ipairs(b.list)do
            local me=m.userId==Me.UserId
            local r=K.make('Frame',panel,{Name='Member'..m.userId,BackgroundColor3=C.panel,BorderSizePixel=0});K.round(r,8);K.box(r,8,ry,inner-16,rowH)
            K.stroke(r,me and C.accent or C.line,me and 2 or 1,0,true)
            local av=pt and 30 or ph and 26 or 30;local a=K.avatar(r,'Avatar',m.userId,av);K.box(a,8,math.floor((rowH-av)/2),av,av)
            local nl=K.text(r,'Name',m.name or '',pt and 14 or ph and 13 or 14,C.ink,700);nl:SetAttribute('LocalizationSkip',true);K.box(nl,8+av+8,0,inner-16-8-av-8-34,rowH)
            local ck=K.icon(r,'check',16,C.accent,'Ready');K.box(ck,inner-16-12-16,math.floor((rowH-16)/2),16,16);ck.Visible=m.ready==true
            ry+=rowH+4
        end
        if b.ai then
            local d=K.dashBox(panel,'AI'..b.team,C.muted,.6,8,1);local ah=pt and 40 or 36;K.box(d,8,ry,inner-16,ah)
            local ic=K.icon(d,'npc',16,C.muted,'Icon');K.box(ic,12,math.floor((ah-16)/2),16,16)
            local tl2=K.text(d,'Text',b.ai,pt and 13 or 12,C.muted,700);K.box(tl2,36,0,inner-16-48,ah)
            ry+=ah+4
        elseif b.empty then
            local e=K.text(panel,'Empty'..b.team,'모집 중',12,C.muted,700);K.box(e,14,ry,inner-28,24)
        end
        table.insert(made,panel);cy+=b.h+gap
    end
    S.canvas(scroll,cy-gap)
    if choose then
        local selected=0;for _,m in ipairs(f.members or {})do if m.userId==Me.UserId then selected=m.team or 0;break end end
        local fy=height-footH
        local line=K.make('Frame',root,{Name='FootLine',BackgroundColor3=C.line,BackgroundTransparency=.4,BorderSizePixel=0});K.box(line,0,fy,width,1)
        local by=fy+math.floor(pad/2)+(pt and 4 or 0)
        if segment then
            local seg=S.segment(root,'Choices',items,selected,function(team)self.callbacks.choose(team,f.revision,self.id)end,{size=pt and 14 or 13})
            seg:place(pad,by,inner,cellH)
            for i,c in ipairs(seg.cells)do c.button.Name='Choose'..tostring(items[i][1])end
        else
            local holder=K.make('Frame',root,{Name='Choices',BackgroundTransparency=1});K.box(holder,pad,by,inner,footH)
            local cw=math.floor((inner-(cols-1)*8)/cols)
            for i,it in ipairs(items)do
                local on=it[1]==selected
                local b=K.button(holder,'Choose'..tostring(it[1]),{kind=on and 'out'or 'plain',text=it[2],size=13,weight=800},function()self.callbacks.choose(it[1],f.revision,self.id)end)
                b:place(((i-1)%cols)*(cw+8),((i-1)//cols)*(cellH+8),cw,cellH)
            end
        end
    end
    depthZ(root,Z+1)
    if self.staggered~=self.id then self.staggered=self.id;if not K.reduced then for i,o in ipairs(made)do if i>6 then break end;K.appear(o,{dy=8,t=.14,delay=(i-1)*.03})end end end
end
return M
