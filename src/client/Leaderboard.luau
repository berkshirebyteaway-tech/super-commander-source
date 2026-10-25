local UI=require(script.Parent.Theme)
local FactionColors=require(script.Parent.FactionColors)
local Honor=require(script.Parent.CommanderHonor)
local Glyphs=require(script.Parent.ActionGlyphs)
local Teams=require(script.Parent.TeamStandings)
local Step=require(script.Parent.TelemetryStep)
local C=UI.colors
local M={};M.__index=M
M.WIDTH=264
M.ROWS=5
M.CHIP=104
local HEADER,COLUMNS,ROW=34,18,24
local Left,Right,Center=Enum.TextXAlignment.Left,Enum.TextXAlignment.Right,Enum.TextXAlignment.Center
local function share(v)v=(v or 0)*100;return string.format(v>=10 and "%.1f%%" or "%.2f%%",v)end
local function text(parent,name,size,color,align,font)
    return UI.make("TextLabel",parent,{Name=name,Text="",TextSize=size,TextColor3=color,Font=font or Enum.Font.BuilderSansMedium,BackgroundTransparency=1,BorderSizePixel=0,
        TextXAlignment=align or Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=12})
end
function M.new(parent,callbacks)
    local self=setmetatable({callbacks=callbacks or {},collapsed=false,rows={},mode="players"},M)
    local W=M.WIDTH
    local f=UI.make("Frame",parent,{Name="Leaderboard",BackgroundColor3=C.panel,BackgroundTransparency=.08,BorderSizePixel=0,Visible=false,Active=true,ZIndex=11,Size=UDim2.fromOffset(W,HEADER)})
    UI.corner(f,3);UI.stroke(f,C.line,1);self.frame=f
    local title=UI.make("TextButton",f,{Name="Title",Text="",BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,ZIndex=12,Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(W-44,HEADER)})
    title.Activated:Connect(function()if self.callbacks.more then self.callbacks.more()end end)
    self.title=title;self.marks={}
    for i,hgt in ipairs({7,11,9})do self.marks[i]=UI.make("Frame",title,{Name="Mark"..i,BackgroundColor3=i==2 and C.accent or C.ice,BorderSizePixel=0,ZIndex=12,Position=UDim2.fromOffset(10+(i-1)*4,22-hgt),Size=UDim2.fromOffset(3,hgt)})end
    local name=text(title,"Label",14,C.ink,Left,Enum.Font.BuilderSansBold);UI.box(name,30,0,60,HEADER);name.Text="순위";self.label=name
    self.count=text(title,"Survivors",12,C.muted,Right);UI.box(self.count,90,0,W-44-90-4,HEADER)
    self.tabs={}
    for i,k in ipairs({{"players","개인",40},{"teams","팀",34}})do
        local b=UI.make("TextButton",f,{Name="Tab_"..k[1],Text=k[2],TextSize=12,Font=Enum.Font.BuilderSansBold,TextColor3=C.muted,BackgroundColor3=C.ink,BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Visible=false,ZIndex=13,Size=UDim2.fromOffset(k[3],22)})
        UI.corner(b,3);UI.stroke(b,C.line,1)
        b.Activated:Connect(function()if self.mode~=k[1]then self.mode=k[1];Step.step("hud","rankMode",{item=k[1]});self:draw();if self.callbacks.changed then self.callbacks.changed()end end end)
        self.tabs[i]={button=b,mode=k[1],width=k[3]}
    end
    self.toggle=UI.button(f,"Toggle","–",function()self.collapsed=not self.collapsed;self:draw();if self.callbacks.changed then self.callbacks.changed()end end)
    self.toggle.TextSize=16;self.toggle.ZIndex=12;UI.box(self.toggle,W-38,4,30,26)
    local cols=UI.make("Frame",f,{Name="Columns",BackgroundTransparency=1,BorderSizePixel=0,ZIndex=12,Position=UDim2.fromOffset(0,HEADER),Size=UDim2.fromOffset(W,COLUMNS)})
    self.columns=cols
    local function caption(n,t,x,w,align)local c=text(cols,n,13,C.muted,align,Enum.Font.BuilderSansBold);UI.box(c,x,0,w,COLUMNS);c.Text=t;return c end
    caption("Rank","#",8,22,Center);self.nameCaption=caption("Name","지휘관",34,120);caption("Land","영토",W-114,54,Right);local troopCap=caption("Troops","병력",W-56,46,Right)
    local mark=Glyphs.create(cols,"troops",13,C.muted);if mark then troopCap.Visible=false;mark.Position=UDim2.fromOffset(W-8-13-6,math.floor((COLUMNS-13)/2))end
    local function row(n)
        local r=UI.make("TextButton",f,{Name=n,Text="",BackgroundColor3=C.raised,BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,ZIndex=12,Size=UDim2.fromOffset(W-8,ROW)})
        UI.corner(r,3)
        local o={root=r,rank=text(r,"Rank",13,C.muted,Center,Enum.Font.BuilderSansBold),dot=UI.make("Frame",r,{Name="Dot",BorderSizePixel=0,ZIndex=12,Position=UDim2.fromOffset(30,8),Size=UDim2.fromOffset(8,8)}),
            name=text(r,"Name",13,C.ink),land=text(r,"Land",13,C.ink,Right,Enum.Font.BuilderSansBold),troops=text(r,"Troops",13,C.muted,Right)}
        UI.corner(o.dot,2);UI.box(o.rank,4,0,22,ROW);UI.box(o.name,49,0,W-8-49-116,ROW);UI.box(o.land,W-8-110,0,54,ROW);UI.box(o.troops,W-8-52,0,46,ROW)
        o.stroke=UI.stroke(r,C.accent,1);o.stroke.Enabled=false
        o.face=UI.make("ImageLabel",r,{Name="Face",BackgroundColor3=C.raised,BorderSizePixel=0,ZIndex=12,Visible=false,Position=UDim2.fromOffset(25,3),Size=UDim2.fromOffset(18,18)});UI.corner(o.face,40)
        r.MouseEnter:Connect(function()if not o.me then r.BackgroundTransparency=.4 end end)
        r.MouseLeave:Connect(function()if not o.me then r.BackgroundTransparency=1 end end)
        r.Activated:Connect(function()if o.faction and self.callbacks.focus then self.callbacks.focus(o.faction)end end)
        return o
    end
    for i=1,M.ROWS do self.rows[i]=row("Row"..i)end
    self.more=text(f,"More",12,C.muted,Center);self.more.Text="•••"
    self.mine=row("Mine")
    return self
end
local function fill(o,f,rank,ownColor)
    o.faction=f;o.root.Visible=f~=nil;if not f then return end
    local mine=f.id==1;o.me=mine
    o.rank.Text=tostring(rank);o.rank.TextColor3=mine and C.accent or rank==1 and C.gold or C.muted
    o.dot.BackgroundColor3=FactionColors.get(f.id,f.kind,ownColor)
    local face=f.userId and f.userId>0 and ('rbxthumb://type=AvatarHeadShot&id='..f.userId..'&w=150&h=150')or ''
    if o.face.Image~=face then o.face.Image=face end;o.face.Visible=face~='';o.dot.Visible=face==''
    o.name.Text=f.name or "";o.name.TextColor3=mine and C.accent or C.ink
    local h=Honor.of(f);Honor.pill(o.name,h and h.plate,4)
    o.land.Text=share(f.share);o.troops.Text=UI.troops(f.troops)
    o.root.BackgroundTransparency=mine and .2 or 1
end
local function fillTeam(o,t,rank,factions)
    o.faction=nil;o.root.Visible=t~=nil;if not t then return end
    local mine=t.mine;o.me=mine
    for _,f in ipairs(factions)do if f.team==t.team and f.kind~="BOT"and not f.eliminated and (f.tiles or 0)>0 then o.faction=f;break end end
    o.rank.Text=tostring(rank);o.rank.TextColor3=mine and C.accent or rank==1 and C.gold or C.muted
    o.face.Visible=false;o.dot.Visible=true;o.dot.BackgroundColor3=t.color
    o.name.Text=string.format("%s  %d명",t.name,t.alive);o.name.TextColor3=mine and C.accent or C.ink
    Honor.pill(o.name,nil)
    o.land.Text=share(t.share);o.troops.Text=UI.troops(t.troops)
    o.root.BackgroundTransparency=mine and .2 or 1
end
function M:update(state,sorted,ownColor)
    self.state=state;self.ownColor=ownColor
    self.teamGame=Teams.active(state);self.teams=self.teamGame and Teams.build(state,sorted)or nil;self.sorted=sorted or {}
    if not self.teamGame then self.mode="players"end
    local alive,mineAt={},nil
    for _,f in ipairs(sorted or {})do if f.kind~='BOT'and(f.tiles or 0)>0 and not f.eliminated then table.insert(alive,f);if f.id==1 then mineAt=#alive end end end
    self.alive=alive;self.mineAt=mineAt
    self.frame:SetAttribute("Survivors",#alive);self.frame:SetAttribute("MyRank",mineAt or 0)
    self:draw()
end
local K
local GLASS=Color3.fromRGB(12,17,24)
function M:draw20()
    K=K or require(script.Parent.Kit20)
    local alive=self.alive or {};local mineAt=self.mineAt;local f=self.frame
    f.BackgroundColor3=GLASS;f.BackgroundTransparency=.14;K.round(f,self.compact and 8 or 10)
    local st=f:FindFirstChildOfClass('UIStroke');if st then st.Color=K.colors.line;st.Transparency=.1 end
    for _,m in ipairs(self.marks)do m.Visible=false end
    self.columns.Visible=false;self.more.Visible=false
    self.icon20=self.icon20 or K.icon(self.title,'records',14,K.colors.accent,'Icon20')
    if self.compact then
        self.toggle.Visible=false;for _,t in ipairs(self.tabs)do t.button.Visible=false end;self.mine.root.Visible=false;self.label.Visible=false
        for _,o in ipairs(self.rows)do o.root.Visible=false end
        UI.box(self.title,0,0,76,26);K.box(self.icon20,11,8,11,11);self.icon20.Size=UDim2.fromOffset(11,11)
        self.count.RichText=true;if K.fonts.num then self.count.FontFace=K.fonts.num end
        self.count.Text=mineAt and string.format('#%d<font color="#8A97A8" size="11"> /%d</font>',mineAt,#alive)or string.format('<font color="#8A97A8">%d</font>',#alive)
        self.count.TextXAlignment=Left;self.count.TextSize=13;self.count.TextColor3=K.colors.ink;UI.box(self.count,26,0,48,26)
        self.height=26;f.Size=UDim2.fromOffset(76,26);return
    end
    local W=232
    self.toggle.Visible=true;self.toggle.Text='';self.toggle.BackgroundTransparency=1
    local ts=self.toggle:FindFirstChildOfClass('UIStroke');if ts then ts.Enabled=false end
    self.chev20=self.chev20 or K.icon(self.toggle,'fold',14,K.colors.muted,'Chev20')
    UI.box(self.toggle,W-36,0,36,36);K.box(self.chev20,11,11,14,14);self.chev20.Rotation=self.collapsed and 180 or 0
    self.label.Visible=true;self.label.Text='순위';self.label.TextSize=13;self.label.FontFace=K.fonts[800]or self.label.FontFace
    UI.box(self.title,0,0,W-40,36);K.box(self.icon20,11,14,14,14);UI.box(self.label,31,13,40,17)
    self.count.RichText=false;if K.fonts.num then self.count.FontFace=K.fonts.num end;self.count.TextSize=12;self.count.TextColor3=K.colors.muted;self.count.TextXAlignment=Left
    self.count.Text=tostring(#alive);UI.box(self.count,59,13,60,17)
    local tabs=self.teamGame==true and not self.collapsed;local tx=96
    for _,t in ipairs(self.tabs)do local b=t.button;b.Visible=tabs
        if tabs then local on=self.mode==t.mode;UI.box(b,tx,8,t.width,20);tx+=t.width+4;b.BackgroundTransparency=on and 0 or 1;b.TextColor3=on and K.colors.bg or K.colors.muted;K.round(b,4)end end
    if tabs and self.mode=='teams'then self.count.Visible=false else self.count.Visible=true end
    local y=36
    local INSET=6
    local function row20(o,item,rank,pinned,lit)
        o.root.Visible=item~=nil;if not item then return end
        local h=pinned and 26 or 22;local plate=pinned or lit==true
        local ox=plate and INSET or 0;local rw=plate and W-INSET*2 or W
        UI.box(o.root,ox,y,rw,h);K.round(o.root,6)
        o.root.BackgroundColor3=K.colors.accent;o.root.BackgroundTransparency=plate and .9 or 1
        o.stroke.Enabled=plate;o.stroke.Color=K.colors.accent;o.stroke.Transparency=.45;o.stroke.Thickness=1
        for _,l in ipairs({o.rank,o.land})do if K.fonts.num then l.FontFace=K.fonts.num end;l.TextSize=12 end
        o.rank.TextXAlignment=Left;UI.box(o.rank,11-ox,0,18,h);o.rank.TextColor3=plate and K.colors.accent or K.colors.muted
        o.dot.Position=UDim2.fromOffset(31-ox,math.floor((h-8)/2));o.dot.Size=UDim2.fromOffset(8,8)
        o.face.Size=UDim2.fromOffset(16,16);o.face.Position=UDim2.fromOffset(27-ox,math.floor((h-16)/2))
        if not pinned then o.face.Visible=false;o.dot.Visible=true end
        o.name.TextSize=12;o.name.FontFace=K.fonts[plate and 800 or 700]or o.name.FontFace;o.name.TextColor3=K.colors.ink
        UI.box(o.name,47-ox,0,W-47-50-11,h)
        o.land.TextColor3=K.colors.ink;UI.box(o.land,W-11-46-ox,0,46,h)
        o.troops.Visible=false
        y+=h
    end
    if tabs and self.mode=='teams'then
        local list=self.teams or {};local mine
        for i,t in ipairs(list)do if t.mine then mine=i end end
        for i,o in ipairs(self.rows)do local t=not self.collapsed and list[i]or nil;fillTeam(o,t,i,self.sorted);row20(o,t,i,false,i==mine)end
        self.mine.root.Visible=false
        if not self.collapsed and mine and mine>M.ROWS then y+=6;fillTeam(self.mine,list[mine],mine,self.sorted);row20(self.mine,list[mine],mine,true,true)end
    else
        for i,o in ipairs(self.rows)do local fct=not self.collapsed and alive[i]or nil;fill(o,fct,i,self.ownColor);row20(o,fct,i,false,i==mineAt)end
        self.mine.root.Visible=false
        if not self.collapsed and mineAt and mineAt>M.ROWS then y+=6;fill(self.mine,alive[mineAt],mineAt,self.ownColor);row20(self.mine,alive[mineAt],mineAt,true)end
    end
    self.height=self.collapsed and 36 or y+9
    f.Size=UDim2.fromOffset(W,self.height)
end
function M:draw()
    if require(script.Parent.Hud20).ENABLED then return self:draw20()end
    local alive=self.alive or {};local mineAt=self.mineAt
    if self.compact then
        self.toggle.Visible=false;self.columns.Visible=false;for _,t in ipairs(self.tabs)do t.button.Visible=false end;self.more.Visible=false;self.mine.root.Visible=false;self.label.Visible=false
        for _,o in ipairs(self.rows)do o.root.Visible=false end
        local ch=self.chipH or 44
        UI.box(self.title,0,(ch-48)/2,M.CHIP,48)
        for i,m in ipairs(self.marks)do local hgt=({7,11,9})[i];m.Position=UDim2.fromOffset(12+(i-1)*4,29.5-hgt)end
        self.count.Text=mineAt and string.format("#%d / %d",mineAt,#alive)or string.format("생존 %d",#alive)
        self.count.TextXAlignment=Center;self.count.TextSize=15;self.count.Font=Enum.Font.BuilderSansBold;self.count.TextColor3=mineAt and C.ink or C.muted
        UI.box(self.count,28,0,M.CHIP-34,48)
        self.height=ch;self.frame.Size=UDim2.fromOffset(M.CHIP,ch);return
    end
    self.toggle.Visible=true;self.label.Visible=true;UI.box(self.title,0,0,M.WIDTH-44,HEADER)
    local tabs=self.teamGame==true and not self.collapsed;local tx=66
    for _,t in ipairs(self.tabs)do
        local b=t.button;b.Visible=tabs
        if tabs then local on=self.mode==t.mode;UI.box(b,tx,6,t.width,22);tx+=t.width+4
            b.BackgroundTransparency=on and 0 or 1;b.TextColor3=on and C.bg or C.muted end
    end
    for i,m in ipairs(self.marks)do local hgt=({7,11,9})[i];m.Position=UDim2.fromOffset(10+(i-1)*4,22-hgt)end
    self.count.TextXAlignment=Right;self.count.TextSize=12;self.count.Font=Enum.Font.BuilderSansMedium;self.count.TextColor3=C.muted;UI.box(self.count,90,0,M.WIDTH-44-90-4,HEADER)
    self.toggle.Text=self.collapsed and "+" or "–"
    self.count.Text=self.collapsed and mineAt and string.format("#%d / %d",mineAt,#alive) or string.format("생존 %d",#alive)
    if tabs then UI.box(self.count,tx,0,M.WIDTH-44-tx-4,HEADER)end
    self.columns.Visible=not self.collapsed;self.more.Visible=false;self.mine.root.Visible=false
    local y=HEADER+COLUMNS
    if tabs and self.mode=="teams"then
        self.nameCaption.Text="팀";local list=self.teams or {};local mine
        for i,t in ipairs(list)do if t.mine then mine=i end end
        self.count.Text=string.format("%d개 팀",#list)
        for i,o in ipairs(self.rows)do
            local t=list[i];fillTeam(o,t,i,self.sorted);o.stroke.Enabled=false
            if t then UI.box(o.root,4,y,M.WIDTH-8,ROW);y+=ROW end
        end
        if mine and mine>M.ROWS then
            fillTeam(self.mine,list[mine],mine,self.sorted);self.mine.stroke.Enabled=true;UI.box(self.mine.root,4,y+2,M.WIDTH-8,ROW);y+=ROW+2
        end
        self.height=y+6;self.frame.Size=UDim2.fromOffset(M.WIDTH,self.height);return
    end
    self.nameCaption.Text="지휘관"
    for i,o in ipairs(self.rows)do
        local f=not self.collapsed and alive[i] or nil;fill(o,f,i,self.ownColor);o.stroke.Enabled=false
        if f then UI.box(o.root,4,y,M.WIDTH-8,ROW);y+=ROW end
    end
    if not self.collapsed and mineAt and mineAt>M.ROWS then
        self.more.Visible=mineAt>M.ROWS+1;if self.more.Visible then UI.box(self.more,0,y,M.WIDTH,12);y+=12 end
        fill(self.mine,alive[mineAt],mineAt,self.ownColor);self.mine.stroke.Enabled=true;UI.box(self.mine.root,4,y+2,M.WIDTH-8,ROW);y+=ROW+2
    end
    self.height=self.collapsed and HEADER or y+6
    self.frame.Size=UDim2.fromOffset(M.WIDTH,self.height)
end
function M:layout(w,h,show,compact)
    if require(script.Parent.Hud20).ENABLED then
        local touch=require(script.Parent.InputMode).touch()
        local pc=not touch or require(script.Parent.Parent.Core.InterfacePlacement).tablet(w,h,touch)
        local small=not pc or w<900
        if small~=self.compact then self.compact=small end;self:draw()
        self.frame.Visible=show==true
        local inset=0;pcall(function()inset=game:GetService('GuiService'):GetGuiInset().Y/(UI.scale or 1)end)
        if small then local portrait=h>w;UI.box(self.frame,w-12-36-6-76,math.floor((portrait and 17 or 13)-inset),76,26)
        else UI.box(self.frame,w-232-12,math.max(4,math.floor(58-inset)),232,self.height or 36)end
        return
    end
    local compactIn=compact
    compact=compact==true or w<900 or h<500
    if compact~=self.compact then self.compact=compact;self:draw()end
    self.frame.Visible=show==true
    local phone=compactIn==true and h<500 and w>h and w>=560
    local Style=require(script.Parent.HudStyle)
    Style.round(self.frame,phone and 10 or 8);self.frame.BackgroundColor3=Style.colors.panel
    if compact then
        local ch=phone and 36 or 44;self.chipH=ch
        UI.box(self.frame,w-M.CHIP-12-(phone and 48 or 0),8,M.CHIP,ch);UI.box(self.title,0,(ch-48)/2,M.CHIP,48);UI.box(self.count,28,0,M.CHIP-34,48)
        for i,m in ipairs(self.marks)do local hgt=({7,11,9})[i];m.Position=UDim2.fromOffset(12+(i-1)*4,29.5-hgt)end
    else UI.box(self.frame,w-M.WIDTH-12,8,M.WIDTH,self.height or HEADER)end
end
return M
