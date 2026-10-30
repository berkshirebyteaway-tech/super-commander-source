local K=require(script.Parent.Kit20)
local UI=require(script.Parent.Theme)
local Model=require(script.Parent.Parent.Core.ResultPresentation)
local Career=require(script.Parent.Parent.Core.CareerRules)
local L=require(script.Parent.Localization)
local TextService=game:GetService('TextService')
local TweenService=game:GetService('TweenService')
local UIS=game:GetService('UserInputService')
local M={};M.__index=M
local C=K.colors
local CARD=Color3.fromRGB(15,21,29)
local STEEL=Color3.fromRGB(91,122,153)
local function clock(s)return string.format('%02d:%02d',math.floor(s/60),math.floor(s%60))end
local function set(o,k,v)if o[k]~=v then o[k]=v end end
local function commas(n)return UI.commas(math.floor((tonumber(n)or 0)+.5))end
local function width(text,size,label)return K.width(L.text(text)or text,size,label)end
local function robloxRight()
    local ok,v=pcall(function()local s=game:GetService('GuiService');local d=s:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets);local b=s:GetInsetArea(Enum.ScreenInsets.TopbarSafeInsets)
        return (b.Min.X-d.Min.X)/(UI.scale or 1)+8 end)
    return ok and v or 0
end
M.played={}
local GEO={
    pc={p=36,title={y=35,fs=56,h=67},rank={y=108,fs=64,h=64,of=26,ofY=143,ofH=30},stats={y=191,fs=15,h=18,is=16},note={y=219,fs=13,h=18},
        best={h=24,fs=12,is=12,gap=10},reward={y=263,h=78,amt=30,gap=44,chipH=26,chipFs=13,chipIs=14},level={y=363,h=24,fs=16,barH=8},acts=405,
        row1={h=44,invW=174,fs=15,is=17,coin=15,icon=44,iconIs=19},big={y=-103,h=72,lobbyW=170,lobbyFs=20,againFs=24,lobbyIs=18,againIs=20}},
    ph={p=18,title={x=88,y=22,fs=40,h=48,left=true},rank={y=34,fs=56,h=56,of=22,ofY=61,ofH=32,right=true},stats={x=88,y=72,fs=13,h=15,is=14,left=true},note={x=88,y=94,fs=12,h=16,left=true},
        best={h=20,fs=11,is=11,gap=6},reward={y=122,h=54,amt=22,gap=28,chipH=22,chipFs=12,chipIs=12},level={y=190,h=21,fs=14,barH=8},acts=224,
        row1={h=38,invW=158,fs=13,is=15,coin=13,icon=38,iconIs=17},big={y=-72,h=56,lobbyW=150,lobbyFs=17,againFs=20,lobbyIs=18,againIs=20}},
    pt={p=16,title={y=84,fs=48,h=58},rank={y=146,fs=60,h=60,of=22,ofY=177,ofH=32},stats={y=221,fs=13,h=15,is=14},note={y=242,fs=12,h=16},
        best={h=20,fs=11,is=11,gap=8},reward={y=264,h=64,amt=24,gap=24,chipH=24,chipFs=12,chipIs=13},level={y=346,h=21,fs=14,barH=8,xp=true},acts=386,
        row1={h=44,fs=13,is=16,text=true},invite={y=442,h=48,fs=14,is=18,coin=14},big={y=-76,h=60,lobbyW=110,watchW=120,watchIs=18,lobbyFs=17,againFs=22}},
}
function M.geo(fmt,ch)
    local G=GEO[fmt];local base=fmt=='pc'and 560 or fmt=='ph'and 375 or 667
    local k=math.clamp(base-ch,0,60);if k==0 then return G end
    local o=table.clone(G);local function up(name,f)o[name]=table.clone(G[name]);o[name].y=G[name].y-math.floor(k*f)end
    up('title',.3);up('rank',.3);o.rank.ofY=G.rank.ofY-math.floor(k*.3);up('stats',.3);up('note',.3);up('reward',.5);up('level',.6)
    o.acts=G.acts-math.floor(k*.75);if G.invite then up('invite',.75)end
    return o
end
function M.ladderLine(pr)
    local r=pr and pr.ranked
    if type(r)=='table'then
        local head=L.text(r.ladder=='2v2'and '랭크 2대2'or r.ladder=='ffa'and '랭크 개인전'or '랭크 1대1')
        if r.pending then return head..', '..L.text('랭크 점수 계산 중…'),C.muted end
        local d=tonumber(r.delta)or 0;local parts={head,string.format('%s%d RP',d>=0 and '+'or '',d)}
        if r.placing then table.insert(parts,string.format(L.text('배치 경기 %d판 남음'),r.placementLeft or 0))
        elseif r.tierName then table.insert(parts,L.text(r.tierName)..(r.division and ' '..r.division or '')..string.format('  %d RP',r.rp or 0))end
        return table.concat(parts,'  '),d>0 and C.accent or d<0 and C.danger or C.ink
    end
    local c=pr and pr.clanwar
    if type(c)=='table'then
        local pts=tonumber(c.points)or 0
        return L.text(c.won and '클랜전 승리'or '클랜전 패배')..'  '..string.format(L.text('클랜 점수 %s%d'),pts>=0 and '+'or '',pts)..'  '..string.format(L.text('기여 +%d'),tonumber(c.contribution)or 0),c.won and C.accent or C.danger
    end
    return nil
end
function M.todayLine(v)
    if v.status=='practice'then return nil end
    local sp=v.supply
    if type(sp)=='table'and type(sp.steps)=='table'and sp.step and sp.steps[sp.step]then
        return {name=string.format('보급 %d/%d',sp.step,#sp.steps),coins=sp.steps[sp.step],kind='supply'}
    end
    if type(v.daily)=='table'and v.daily.paid then return {name='오늘의 도전',coins=v.daily.paid,kind='dailyOp'}end
    return nil
end

local function look(face,kind)
    local st=face:FindFirstChild('Stroke20');local shade=face:FindFirstChild('Depth');local ink
    face.BackgroundTransparency=0;st.Enabled=true;st.Thickness=1;st.Transparency=0;shade.Visible=false
    if kind=='pri'then face.BackgroundColor3=C.accent;st.Enabled=false;shade.Visible=true;ink=C.bg
    elseif kind=='goldo'then face.BackgroundColor3=C.gold;face.BackgroundTransparency=.92;st.Color=C.gold;st.Thickness=2;ink=C.gold
    else face.BackgroundColor3=C.raised;st.Color=C.line;ink=C.ink end
    face:SetAttribute('Kind20',kind);face:SetAttribute('BaseAlpha',face.BackgroundTransparency)
    return ink
end
local function adopt(b,kind)
    local face=b:FindFirstChild('Face20')
    if face then look(face,kind);return face end
    b:SetAttribute('Text20',b.Text);b.Text='';b.BackgroundTransparency=1;b.AutoButtonColor=false
    for _,o in ipairs(b:GetChildren())do if o:IsA('GuiObject')then o:SetAttribute('Hidden20',o.Visible);o.Visible=false end end
    face=K.make('Frame',b,{Name='Face20',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BorderSizePixel=0,Active=false});K.round(face,8)
    local scale=K.make('UIScale',face,{Name='Press'})
    local st=K.make('UIStroke',face,{Name='Stroke20',ApplyStrokeMode=Enum.ApplyStrokeMode.Border});pcall(function()st.BorderStrokePosition=Enum.BorderStrokePosition.Inner end)
    local shade=K.make('Frame',face,{Name='Depth',BackgroundColor3=Color3.new(0,0,0),Size=UDim2.fromScale(1,1),BorderSizePixel=0,Active=false,Visible=false});K.round(shade,8)
    K.make('UIGradient',shade,{Name='Band',Rotation=90})
    look(face,kind)
    local hover,pressed=false,false;local tw
    local function to(v,t,style)if K.reduced then scale.Scale=1;return end;if tw then tw:Cancel()end;tw=TweenService:Create(scale,TweenInfo.new(t,style,Enum.EasingDirection.Out),{Scale=v});tw:Play()end
    local function bright(on)
        local k=face:GetAttribute('Kind20');local a=face:GetAttribute('BaseAlpha')or 0
        if k=='pri'then face.BackgroundColor3=on and C.accent:Lerp(Color3.new(1,1,1),.08)or C.accent else face.BackgroundTransparency=on and math.max(0,a-.06)or a end
    end
    b.MouseEnter:Connect(function()hover=true;if face:GetAttribute('Kind20')=='plain'then st.Color=C.muted end;if not pressed then to(1.02,.08,Enum.EasingStyle.Quad)end end)
    b.MouseLeave:Connect(function()hover=false;if face:GetAttribute('Kind20')=='plain'then st.Color=C.line end;if pressed then pressed=false;bright(false)end;to(1,.08,Enum.EasingStyle.Quad)end)
    b.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        pressed=true;if tw then tw:Cancel()end;scale.Scale=K.reduced and 1 or .96;bright(true)end end)
    b.InputEnded:Connect(function(i)if(i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch)and pressed then
        pressed=false;bright(false);if K.reduced then return end;scale.Scale=1.02;to(hover and 1.02 or 1,.12,Enum.EasingStyle.Back)end end)
    return face
end
local function unadopt(b)
    if not b or not b.Parent then return end
    local face=b:FindFirstChild('Face20');if not face then return end
    face:Destroy();b.Text=b:GetAttribute('Text20')or b.Text;b.BackgroundTransparency=0;b:SetAttribute('Text20',nil)
    for _,o in ipairs(b:GetChildren())do if o:IsA('GuiObject')and o:GetAttribute('Hidden20')~=nil then o.Visible=o:GetAttribute('Hidden20');o:SetAttribute('Hidden20',nil)end end
end
local function content(face,ink,icon,iconSize,text,fs,amount,amountSize,align)
    local key=table.concat({tostring(icon),iconSize or 0,text or '',fs or 0,tostring(amount),amountSize or 0,tostring(align),tostring(ink)},'|')
    local w,h=face.Size.X.Offset,face.Size.Y.Offset;key=key..w..'x'..h
    if face:GetAttribute('Content20')==key then
        for _,o in ipairs(face:GetChildren())do if o:GetAttribute('Part20')then
            if o:IsA('TextLabel')then o.TextColor3=ink elseif o.Name=='Amount'then local val=o:FindFirstChild('Value');if val then val.TextColor3=C.gold end
            elseif o.Name=='Reward'then local val=o:FindFirstChild('Value');if val then val.TextColor3=Color3.fromRGB(58,42,0)end end end end
        return
    end
    face:SetAttribute('Content20',key)
    for _,o in ipairs(face:GetChildren())do if o:GetAttribute('Part20')then o:Destroy()end end
    local badge=align=='badge'and amount;if badge then amount=nil;align=nil end
    local parts={}
    if icon then local i=K.icon(face,icon,iconSize,ink,'Icon');i:SetAttribute('Part20',true);table.insert(parts,{o=i,w=iconSize,h=iconSize})end
    local label
    if text and text~=''then label=K.text(face,'Label',text,fs,ink,800);label:SetAttribute('Part20',true)
        local room=w-16-(icon and iconSize+8 or 0)-(amount and 70 or 0);local tw=width(text,fs,label)
        if tw>room then K.fit(label,room,fs,math.max(11,fs-6));tw=math.min(room,width(label.Text,label.TextSize,label))end
        table.insert(parts,{o=label,w=tw+2,h=h})end
    if amount then local a,aw=K.amount(face,'Amount','coin',amount,amountSize,C.gold);a:SetAttribute('Part20',true);table.insert(parts,{o=a,w=aw,h=amountSize})end
    local total=0;for i,p in ipairs(parts)do total+=p.w+(i>1 and(p.o.Name=='Amount'and 8 or 8)or 0)end
    local x=align=='left'and 12 or math.floor((w-total)/2)
    local r,rw;if badge then local pop=not face:GetAttribute('BadgePopped');face:SetAttribute('BadgePopped',true)
        r,rw=K.rewardBadge(face,'Reward',badge,amountSize,w,0,face.ZIndex+5,pop,8);r:SetAttribute('Part20',true)
        local free=w-(rw-6)-6;if x+total>free then x=math.max(10,math.floor((free-total)/2))end end
    for i,p in ipairs(parts)do if i>1 then x+=8 end
        if p.o.Name=='Amount'and align=='left'then x=w-12-p.w end
        K.box(p.o,x,math.floor((h-p.h)/2),p.w,p.h);x+=p.w end
    if label then label.TextColor3=ink end
end
local function place(b,x,y,w,h)
    local hw,hh=math.max(w,44),math.max(h,44)
    K.box(b,x-(hw-w)/2,y-(hh-h)/2,hw,hh)
    local face=b:FindFirstChild('Face20');if face then face.Size=UDim2.fromOffset(w,h);face.Position=UDim2.fromOffset(hw/2,hh/2)
        local cut=math.clamp(1-3/math.max(h,1),0,1)
        face.Depth.Band.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(math.max(0,cut-.001),1),NumberSequenceKeypoint.new(cut,.82),NumberSequenceKeypoint.new(1,.82)})end
end

local trophyControls={adopt=adopt,place=place,content=content}
function M.new(body,compact,recap,relayout)
    local self=setmetatable({body=body,compact=compact,detailsExpanded=false,relayout=relayout,recap=recap,seq={}},M)
    self.root=K.make('Frame',body,{Name='Result20',BackgroundTransparency=1,Size=UDim2.fromScale(0,0)})
    local function text(name,size,color,weight,align)local l=K.text(body,name,'',size,color,weight or 700,align);self[name]=l;return l end
    text('Outcome',56,C.accent,800,Enum.TextXAlignment.Center)
    self.RankRow=K.make('Frame',body,{Name='RankRow',BackgroundTransparency=1})
    self.Rank=K.num(self.RankRow,'Rank','',64,C.gold);self.Rank:SetAttribute('LocalizationSkip',false);self.Of=K.num(self.RankRow,'Of','',26,C.muted)
    self.Stars=K.make('Frame',self.RankRow,{Name='Stars',BackgroundTransparency=1,Visible=false})
    self.StatsRow=K.make('Frame',body,{Name='StatsRow',BackgroundTransparency=1})
    self.peakIcon=K.icon(self.StatsRow,'map',16,C.muted,'MapIcon');self.Peak=K.text(self.StatsRow,'Peak','',15,C.muted,700)
    self.Sep=K.text(self.StatsRow,'Sep','|',15,C.muted,700);self.Sep.TextTransparency=.65;self.Sep:SetAttribute('LocalizationSkip',true)
    self.timeIcon=K.icon(self.StatsRow,'clock',16,C.muted,'ClockIcon');self.Time=K.num(self.StatsRow,'Time','',15,C.muted)
    text('Note',13,C.muted,700,Enum.TextXAlignment.Center);self.Note:SetAttribute('LocalizationSkip',true)
    self.Best=K.make('Frame',body,{Name='BestChip',BackgroundColor3=C.gold,BackgroundTransparency=.88,BorderSizePixel=0,Visible=false});K.round(self.Best,4)
    self.bestIcon=K.icon(self.Best,'star',12,C.gold,'Icon');self.BestText=K.text(self.Best,'Text','개인 최고',12,C.gold,700)
    self.RewardBand=K.make('Frame',body,{Name='RewardBand',BackgroundColor3=C.panel,BorderSizePixel=0});K.round(self.RewardBand,10)
    self.xpAmt=K.make('Frame',self.RewardBand,{Name='XP',BackgroundTransparency=1});self.xpIcon=K.icon(self.xpAmt,'xpStar',30,Color3.new(1,1,1),'Icon')
    self.Rewards=K.num(self.xpAmt,'Value','+0',30,C.ink)
    self.coinAmt=K.make('Frame',self.RewardBand,{Name='Coins',BackgroundTransparency=1});self.medalIcon=K.icon(self.coinAmt,'coinGold',30,Color3.new(1,1,1),'Icon')
    self.RewardMedals=K.num(self.coinAmt,'Value','+0',30,C.gold)
    self.Today=K.make('Frame',self.RewardBand,{Name='TodayChip',BackgroundColor3=C.gold,BackgroundTransparency=.88,BorderSizePixel=0,Visible=false});K.round(self.Today,4)
    self.todayIcon=K.icon(self.Today,'chest',14,C.gold,'Icon');self.TodayName=K.text(self.Today,'Text','',13,C.gold,700)
    self.RewardState=K.text(self.RewardBand,'State','',14,C.muted,700,Enum.TextXAlignment.Center)
    self.Growth=K.make('Frame',body,{Name='Growth',BackgroundTransparency=1})
    self.Level=K.num(self.Growth,'Level','',16,C.ink)
    self.bar=K.fillBar(self.Growth,'Track',{p=0,fill=C.accent,fill2=Color3.fromRGB(122,245,232),track=C.raised});self.LevelTrack=self.bar.frame
    self.LevelXP=K.num(self.Growth,'Next','',16,C.muted,Enum.TextXAlignment.Right)
    self.records={}
    local Hot=require(script.Parent.HotbarIcons)
    for i,k in ipairs({{'conquered','점령한 국가','Crown'},{'troops','총 사용 병력','Soldier'},{'built','지은 건물','City'},{'nukes','사용한 핵','AtomBomb'}})do
        local t=K.panel(body,'Record_'..k[1],'raised',8);t.Visible=false;K.stroke(t,C.line,1,0,true)
        local icon=Hot.create(t,k[3],18,k[1]=='nukes'and C.gold or C.ink)
        local value=K.num(t,'Value','',18,C.ink)
        local cap=K.text(t,'Caption',k[2],13,C.muted,700)
        self.records[i]={root=t,key=k[1],icon=icon,value=value,cap=cap}
    end
    text('Winner',14,C.ink,700);text('Stats',14,C.ink,700)
    text('Ladder',14,C.ink,700);self.Ladder:SetAttribute('LocalizationSkip',true)
    text('NextKind',13,C.muted,700);text('NextName',14,C.ink,700)
    self.NextIcon=K.icon(body,'records',20,C.gold,'NextIcon')
    text('Goal',14,C.muted,700);text('Bonus',14,C.gold,700);text('MapRecord',14,C.muted,700)
    text('Daily',14,C.ink,700);text('DailyDetail',14,C.muted,700);text('NewUnlock',14,C.gold,700)
    text('Campaign',14,C.gold,700);text('CampaignTask',14,C.muted,700);text('CampaignLearned',14,C.accent,700)
    self.lines={}
    for i=1,4 do self.lines['Unlock'..i]=text('Unlock'..i,14,C.gold,700)end
    for i=0,3 do self.lines['Next'..i]=text('Next'..i,14,i==0 and C.muted or C.ink,700)end
    text('MatchStatus',14,C.ice,700);text('Tomorrow',14,C.gold,700)
    for _,n in ipairs({'Bonus','Tomorrow'})do self[n].TextWrapped=true;self[n].TextTruncate=Enum.TextTruncate.None end
    self.recapButton=K.button(body,'Recap',{kind='plain',text='전황 보기',size=14,icon='history',iconSize=16},function()if self.recap then self.recap()end end)
    self.Recap=self.recapButton.button
    self.inks={Winner=C.ink,Stats=C.ink,NextKind=C.muted,NextName=C.ink,Goal=C.muted,Bonus=C.gold,MapRecord=C.muted,Daily=C.ink,DailyDetail=C.muted,NewUnlock=C.gold,
        Campaign=C.gold,CampaignTask=C.muted,CampaignLearned=C.accent,MatchStatus=C.ice,Tomorrow=C.gold,Unlock1=C.gold,Unlock2=C.gold,Unlock3=C.gold,Unlock4=C.gold,
        Next0=C.muted,Next1=C.ink,Next2=C.ink,Next3=C.ink}
    self:dressCard()
    self.skipConn=UIS.InputBegan:Connect(function(i)
        if not self.seqStart or self.seqDone or os.clock()<self.seqStart then return end
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.Keyboard then self:skip()end
    end)
    self.root.Destroying:Once(function()self:teardown()end)
    return self
end
function M:dressCard()
    local body=self.body;local card=body.Parent;if not card or self.card then return end
    local actions=card:FindFirstChild('ResultActions');if not actions then return end
    self.card=card;self.actions=actions
    local title=card:FindFirstChild('Title');local close=card:FindFirstChild('Close');local corner=card:FindFirstChildOfClass('UICorner');local stroke=card:FindFirstChildOfClass('UIStroke')
    local modal=card.Parent
    self.saved={title=title and title.Visible,close=close and close.Visible,corner=corner and corner.CornerRadius,stroke=stroke and {stroke.Color,stroke.Thickness,stroke.Transparency},
        card={card.BackgroundColor3,card.BackgroundTransparency},modal=modal and modal:IsA('GuiObject')and {modal.BackgroundColor3,modal.BackgroundTransparency}or nil,
        body={body.ScrollBarThickness}}
    self.titleObj,self.closeObj,self.modal=title,close,modal
    local glow=K.make('CanvasGroup',card,{Name='Glow20',BackgroundTransparency=1,BorderSizePixel=0,ZIndex=0,Active=false,GroupTransparency=0})
    K.make('UIGradient',glow,{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.7,.75),NumberSequenceKeypoint.new(1,1)})})
    local g=K.make('Frame',glow,{Name='Light',BackgroundColor3=C.accent,BackgroundTransparency=.7,BorderSizePixel=0,Size=UDim2.fromScale(1,1)})
    K.make('UIGradient',g,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.15,.85),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(.85,.85),NumberSequenceKeypoint.new(1,1)})})
    self.glow=glow;self.glowLight=g
    require(script.Parent.FullBleed).edge(card)
    self.details=K.button(card,'Details20',{kind='plain',icon='records',iconSize=19,text=nil},function()self:setDetails(not self.detailsExpanded)end)
    self.detailsText=K.button(card,'DetailsText20',{kind='plain',icon='records',iconSize=16,text='상세 기록',size=13,gap=6},function()self:setDetails(not self.detailsExpanded)end)
    for _,b in ipairs({self.details,self.detailsText})do b.iconColorFixed=true;b.iconImage.ImageColor3=C.muted end
end
function M:teardown()
    if self.trophyResult then require(script.Parent.TrophyResultView).destroy(self)end
    if self.skipConn then self.skipConn:Disconnect();self.skipConn=nil end
    if self.counter then self.counter:Disconnect();self.counter=nil end
    local s=self.saved;if not s then return end
    local card=self.card
    for _,o in ipairs({self.glow,self.details and self.details.button,self.detailsText and self.detailsText.button})do if o and o.Parent then o:Destroy()end end
    if card and card.Parent then
        local corner=card:FindFirstChildOfClass('UICorner');if corner and s.corner then corner.CornerRadius=s.corner end
        local stroke=card:FindFirstChildOfClass('UIStroke');if stroke and s.stroke then stroke.Color,stroke.Thickness,stroke.Transparency=s.stroke[1],s.stroke[2],s.stroke[3]end
        card.BackgroundColor3,card.BackgroundTransparency=s.card[1],s.card[2]
    end
    if self.titleObj and self.titleObj.Parent then self.titleObj.Visible=s.title~=false end
    if self.closeObj and self.closeObj.Parent then unadopt(self.closeObj);self.closeObj.Visible=s.close~=false end
    if self.modal and self.modal.Parent and s.modal then self.modal.BackgroundColor3,self.modal.BackgroundTransparency=s.modal[1],s.modal[2]end
    if self.body and self.body.Parent then self.body.ScrollBarThickness=s.body[1]end
    self.saved=nil
end
function M.layoutActions(_actions,_w,cs,short)return short and 135 or 124+math.max(0,(cs or 44)-44)end
function M:setDetails(open)
    require(script.Parent.TelemetryStep).step('result','details',{result=open and 'opened'or 'closed'})
    self.detailsExpanded=open==true
    if not open then self.body.CanvasPosition=Vector2.zero end
    if self.state then self:update(self.state,self.width)end
    if open and self.detailsY then self.body.CanvasPosition=Vector2.new(0,math.max(0,self.detailsY-8))end
    if self.relayout then self.relayout()end
end

function M:format()
    local host=self.modal or self.body.Parent;local s=UI.scale or 1
    local w,h=(host and host.AbsoluteSize.X or 0)/s,(host and host.AbsoluteSize.Y or 0)/s
    if not self.card then w=math.max(240,self.width or w);return 'pt',w,math.max(h,667)end
    return (w<600 and 'pt'or h<500 and 'ph'or 'pc'),w,h
end
function M:update(state,screenWidth)
    self.state=state;self.width=screenWidth
    if self.telemetryVersion~=state.version and require(script.Parent.TelemetryClient).visible(self.body)then self.telemetryVersion=state.version;require(script.Parent.TelemetryClient).emit('result_viewed',{stage='shown',version=state.version,result=state.personalResult and state.personalResult.outcome or 'unknown'})end
    local v=Model.view(state);self.view=v
    local details=self.detailsExpanded
    self.body:SetAttribute('RecordStatus',v.status);self.body:SetAttribute('ResultOutcome',state.personalResult and state.personalResult.outcome or '')
    self.body:SetAttribute('DetailsExpanded',details)
    require(script.Parent.ResultCelebration).card=self.Rewards
    self.openedAt=self.openedAt or os.clock();self.resultId=state.personalResult and state.personalResult.id
    if state.personalResult and state.personalResult.trophySolo then
        return require(script.Parent.TrophyResultView).update(self,state,v,trophyControls)
    end
    local fmt,W,H=self:format();self.fmt=fmt
    local cw,ch,cx,cy=W,H,0,0
    if fmt=='pc'then local inset=0;pcall(function()inset=game:GetService('GuiService'):GetGuiInset().Y/(UI.scale or 1)end)
        cw,ch=600,math.min(560,H-24);cx,cy=math.floor((W-cw)/2),math.max(12-inset,math.floor((H+inset-ch)/2-inset))end
    local G=M.geo(fmt,ch)
    local lift=0;if fmt~='pc'and self.modal then lift=math.max(0,-self.modal.AbsolutePosition.Y)/(UI.scale or 1)end
    self.cw,self.ch=cw,ch
    self:paintCard(v,fmt,cw,ch,cx,cy)
    local p=G.p;local inner=cw-p*2
    local won=v.won
    local tint=won and C.accent or v.title=='중단'and C.muted or C.ink
    local lx=fmt=='ph'and math.max(88,math.floor(robloxRight()))or p
    local o=self.Outcome;o.Text=v.title;o.TextColor3=tint;o.TextSize=G.title.fs
    if G.title.left then o.TextXAlignment=Enum.TextXAlignment.Left;K.box(o,lx,G.title.y+lift,math.max(120,cw-lx-200),G.title.h)
    else o.TextXAlignment=Enum.TextXAlignment.Center;K.box(o,0,G.title.y+lift,cw,G.title.h)end
    local cp=v.campaign;local R=G.rank;local rank=cp==nil and v.rank or nil
    self.Rank.Visible=rank~=nil;self.Of.Visible=rank~=nil;self.Stars.Visible=cp~=nil
    self.RankRow.Visible=rank~=nil or cp~=nil
    if rank then
        self.Rank.Text=string.format('%d위',v.rank);self.Rank.TextSize=R.fs;self.Rank.TextColor3=v.rank<=3 and C.gold or C.ink
        self.Of.Text=string.format('/ %d',v.total);self.Of.TextSize=R.of
        local rw,ow=width(self.Rank.Text,R.fs,self.Rank),width(self.Of.Text,R.of,self.Of)
        local total=rw+8+ow;local x0=R.right and(cw-p-total)or math.floor((cw-total)/2)
        K.box(self.RankRow,x0,R.y+lift,total+4,R.ofY-R.y+R.ofH)
        K.box(self.Rank,0,0,rw+2,R.h);K.box(self.Of,rw+8,R.ofY-R.y,ow+2,R.ofH)
    elseif cp then
        local Campaign=require(script.Parent.Parent.Core.CampaignRules);local n=Campaign.count and Campaign.count(cp.stars)or 0
        local s=math.floor(R.h*.6);local total=s*3+12;local x0=R.right and(cw-p-total)or math.floor((cw-total)/2)
        K.box(self.RankRow,x0,R.y+lift,total,R.h);K.box(self.Stars,0,0,total,R.h)
        if self.starsDrawn~=n..'|'..s then self.starsDrawn=n..'|'..s;for _,c in ipairs(self.Stars:GetChildren())do c:Destroy()end
            for i=1,3 do local st=K.icon(self.Stars,i<=n and 'starFill'or 'star',s,i<=n and C.gold or C.dim,'Star'..i);K.box(st,(i-1)*(s+6),math.floor((R.h-s)/2),s,s)end end
    end
    local S=G.stats;local peak=(v.peak>0 and v.peak<.0005 and '<0.1%'or string.format('%.1f%%',v.peak*100))
    self.Peak.Text=string.format('최고 영토 %s',peak);self.Time.Text=clock(v.seconds)
    for _,l in ipairs({self.Peak,self.Sep,self.Time})do l.TextSize=S.fs;l.TextColor3=C.muted end
    local pw,tw,sw=width(self.Peak.Text,S.fs,self.Peak),width(self.Time.Text,S.fs,self.Time),width('|',S.fs,self.Sep)
    local total=S.is+8+pw+14+sw+14+S.is+8+tw;local sx=S.left and lx or math.floor((cw-total)/2)
    local sy=S.y+lift;local srowY=v.rank==nil and cp==nil and not S.left and(R.y+lift+math.floor((R.h-S.h)/2))or sy
    K.box(self.StatsRow,sx,srowY,total+4,S.h)
    local x=0;K.box(self.peakIcon,x,math.floor((S.h-S.is)/2),S.is,S.is);x+=S.is+8;K.box(self.Peak,x,0,pw+2,S.h);x+=pw+14
    K.box(self.Sep,x,0,sw+2,S.h);x+=sw+14;K.box(self.timeIcon,x,math.floor((S.h-S.is)/2),S.is,S.is);x+=S.is+8;K.box(self.Time,x,0,tw+2,S.h)
    local note,noteColor,noteKey=self:noteLine(v,state)
    local N=G.note
    local Bc=G.best;local pb=v.personalBest==true;self.Best.Visible=pb
    local noteY=N.y+lift;local push=0
    if pb then
        local bt=self.BestText;bt.TextSize=Bc.fs;bt.TextColor3=C.gold;self.bestIcon.ImageColor3=C.gold
        local btw=width(bt.Text,Bc.fs,bt);local chipW=8+Bc.is+4+btw+8
        local bx,by
        if fmt=='ph'then bx=cw-p-chipW;by=math.min(R.ofY+R.ofH+6,G.reward.y-Bc.h-2)+lift
        else bx=math.floor((cw-chipW)/2);by=srowY+S.h+Bc.gap end
        K.box(self.Best,bx,by,chipW,Bc.h);K.box(self.bestIcon,8,math.floor((Bc.h-Bc.is)/2),Bc.is,Bc.is);K.box(self.BestText,8+Bc.is+4,0,btw+2,Bc.h)
        if fmt~='ph'then
            local function need(withNote)
                local bottom=by+Bc.h;if withNote then noteY=math.max(N.y+lift,bottom+4);bottom=noteY+N.h end
                return math.max(0,bottom+(fmt=='pt'and 8 or 10)-(G.reward.y+lift))
            end
            push=need(note~=nil)
            if note and fmt=='pc'and G.level.y+G.level.h+push>G.acts-6 then note,noteKey=nil,nil;noteY=N.y+lift;push=need(false)end
        end
    end
    if push>0 then
        G=table.clone(G)
        for _,k in ipairs({'reward','level','invite'})do if G[k]then G[k]=table.clone(G[k]);G[k].y+=push end end
        if fmt=='pt'then G.acts+=push end
    end
    self.noteKey=noteKey
    self.Note.Visible=note~=nil
    if note then self.Note.Text=note;self.Note.TextColor3=noteColor;self.Note.TextSize=N.fs
        if N.left then self.Note.TextXAlignment=Enum.TextXAlignment.Left;K.box(self.Note,lx,noteY,cw-lx-p,N.h)
        else self.Note.TextXAlignment=Enum.TextXAlignment.Center;K.box(self.Note,p,noteY,inner,N.h)end end
    self:rewards(v,G.reward,p,inner,lift)
    self:level(v,G.level,p,inner,lift)
    local bodyH=(self.card and G.acts or 9999)-8
    local y=G.level.y+lift+G.level.h+20
    self.detailsY=y
    y=self:detailLines(v,state,y,p,inner,details)
    local mainBottom=G.level.y+lift+G.level.h+4
    if self.card then
        K.box(self.body,0,0,cw,bodyH+lift)
        self.body.CanvasSize=UDim2.fromOffset(0,details and y+8 or math.min(mainBottom,bodyH+lift))
        self.body.ScrollBarThickness=details and 3 or 0
        self:buttons(v,fmt,G,cw,ch,p,lift)
    else self.body.CanvasSize=UDim2.fromOffset(0,details and y+8 or mainBottom)end
    self:intro(v)
    return v
end
function M:paintCard(v,fmt,cw,ch,cx,cy)
    local card=self.card;if not card then return end
    local corner=card:FindFirstChildOfClass('UICorner')or K.make('UICorner',card);corner.CornerRadius=UDim.new(0,fmt=='pc'and 14 or 0)
    local stroke=card:FindFirstChildOfClass('UIStroke');if stroke then set(stroke,'Color',C.line);set(stroke,'Thickness',1);set(stroke,'Transparency',fmt=='pc'and 0 or 1)end
    set(card,'BackgroundColor3',fmt=='pc'and CARD or Color3.fromRGB(9,13,18))
    set(card,'BackgroundTransparency',fmt=='pc'and 0 or .06)
    K.box(card,cx,cy,cw,ch)
    if self.modal and self.modal:IsA('GuiObject')then set(self.modal,'BackgroundColor3',Color3.fromRGB(5,8,12));set(self.modal,'BackgroundTransparency',fmt=='pt'and .2 or .38)end
    if self.titleObj then self.titleObj.Visible=false end
    local glowH=fmt=='pc'and 220 or fmt=='ph'and 150 or 260
    local top=0
    if fmt~='pc'and cy<=0 then
        local gui=card:FindFirstAncestorOfClass('ScreenGui')
        local ok,_,t=pcall(require(script.Parent.FullBleed).insets,gui);if ok and t then top=t/(gui:GetAttribute('UIScale')or 1)end
    end
    K.box(self.glow,0,-top,cw,glowH+top);K.round(self.glow,fmt=='pc'and 14 or 0)
    local won=v.won;local steel=not won and v.title~='중단'
    self.glowLight.BackgroundColor3=won and C.accent or steel and STEEL or C.muted;self.glowLight.BackgroundTransparency=won and .7 or steel and .78 or .9
    local hide=self.actions and self.actions:FindFirstChild('Spectate')~=nil
    if self.closeObj then self.closeObj.Visible=not hide end
end
function M:noteLine(v,state)
    local ladder,color=M.ladderLine(state.personalResult)
    if ladder then return ladder,color,'Ladder'end
    local cp=v.campaign
    if cp then
        local Campaign=require(script.Parent.Parent.Core.CampaignRules);local st=Campaign.stage(cp.id);local t=st and st.task
        local line=cp.taskDone and string.format('✓ %s',cp.task)or t and t.key=='growthGreen'and string.format('%s  지금 %d%%',cp.task,cp.taskValue or 0)
            or t and t.kind~='zero'and t.kind~='share'and t.n>1 and string.format('%s  %d/%d',cp.task,cp.taskValue or 0,t.n)or cp.task
        if line then return L.text(line),cp.taskDone and C.accent or C.muted,'CampaignTask'end
    end
    if v.tomorrow and v.settled then return L.text(v.tomorrow),C.gold,'Tomorrow'end
    local short=({practice='연습, 보상 없음',training='연습 기록',pending='저장 중…',unavailable='저장 재시도 중…',['local']='Studio 임시 기록'})[v.status]
    if short and (v.xp>0 or v.medals>0)then return L.text(short),C.muted,'RewardState'end
    return nil
end
function M:xpText(n)return '+'..commas(n)end
function M:coinText(n)return '+'..commas(n)end
function M:rewards(v,R,p,inner,lift)
    local band=self.RewardBand;K.box(band,p+1,R.y+lift,inner-2,R.h)
    local rewardVisible=v.xp>0 or v.medals>0
    self.xpAmt.Visible=rewardVisible;self.coinAmt.Visible=v.medals>0
    local short=({practice='연습, 보상 없음',training='연습 기록',pending='저장 중…',unavailable='저장 재시도 중…',['local']='Studio 임시 기록'})[v.status]
    self.RewardState.Visible=not rewardVisible;self.RewardState.Text=short or '보상 없음';self.RewardState.TextSize=R.chipFs+2
    self.Rewards.TextColor3=C.ink;self.RewardMedals.TextColor3=C.gold;self.TodayName.TextColor3=C.gold;self.RewardState.TextColor3=C.muted
    K.box(self.RewardState,0,0,inner-2,R.h)
    local items={}
    local a=R.amt
    if rewardVisible then
        local xt=self:xpText(v.xp);local xw=width(xt,a,self.Rewards)
        self.Rewards.TextSize=a;K.box(self.xpIcon,0,0,a,a);K.box(self.Rewards,a+5,0,xw+2,a);self.xpAmt.Size=UDim2.fromOffset(a+5+xw+2,a);table.insert(items,{o=self.xpAmt,w=a+5+xw,h=a})
        if not self.animDone and not self.counting then self.Rewards.Text=self.played and xt or self:xpText(0)elseif self.animDone then self.Rewards.Text=xt end
    end
    if v.medals>0 then
        local mt=self:coinText(v.medals);local mw=width(mt,a,self.RewardMedals)
        self.RewardMedals.TextSize=a;K.box(self.medalIcon,0,0,a,a);K.box(self.RewardMedals,a+5,0,mw+2,a);self.coinAmt.Size=UDim2.fromOffset(a+5+mw+2,a);table.insert(items,{o=self.coinAmt,w=a+5+mw,h=a})
        if not self.animDone and not self.counting then self.RewardMedals.Text=self.played and mt or self:coinText(0)elseif self.animDone then self.RewardMedals.Text=mt end
    end
    local t=M.todayLine(v);self.Today.Visible=t~=nil and rewardVisible
    if t and rewardVisible then
        self.todayIcon.Visible=t.kind=='supply';self.TodayName.Text=t.kind=='supply'and t.name or '✓ '..t.name;self.TodayName.TextSize=R.chipFs
        local nw=width(self.TodayName.Text,R.chipFs,self.TodayName);local ix=t.kind=='supply'and R.chipIs+4 or 0
        K.box(self.todayIcon,6,math.floor((R.chipH-R.chipIs)/2),R.chipIs,R.chipIs);K.box(self.TodayName,6+ix,0,nw+2,R.chipH)
        local w=6+ix+nw+6;self.Today.Size=UDim2.fromOffset(w,R.chipH);table.insert(items,{o=self.Today,w=w,h=R.chipH})
        if t.kind=='supply'then require(script.Parent.TelemetryStep).once('supply:'..tostring(self.resultId),'result','supplyShown',{value=v.supply.n or 0,position=v.supply.step,total=#v.supply.steps})end
    end
    local total=0;for i,it in ipairs(items)do total+=it.w+(i>1 and R.gap or 0)end
    local x=math.floor((inner-2-total)/2)
    for _,it in ipairs(items)do it.o.Position=UDim2.fromOffset(x,math.floor((R.h-it.h)/2));x+=it.w+R.gap end
    self.rewardItems=items
end
function M:level(v,Lv,p,inner,lift)
    local pr=v.progression;local show=pr~=nil and v.status~='practice'
    self.Growth.Visible=show;if not show then return end
    K.box(self.Growth,p,Lv.y+lift,inner,Lv.h)
    local up=(pr.level or 1)>(pr.startLevel or pr.level or 1)
    local shown=self.shownLevel or((up and not self.leveled)and pr.startLevel or pr.level or 1)
    if self.animDone or self.played then shown=pr.level or 1 end
    self.Level.Text=string.format('Lv %d',shown);self.Level.TextSize=Lv.fs;self.Level.TextColor3=(up and self.leveled)and C.gold or C.ink
    local lw=width(self.Level.Text,Lv.fs,self.Level)
    local right
    if Lv.xp then right=(pr.nextXP or 0)==0 and '' or string.format('%s / %s',commas(pr.currentXP or 0),commas(pr.nextXP))
    else right=(pr.nextXP or 0)==0 and '' or tostring(shown+1)end
    self.LevelXP.Text=right;self.LevelXP.TextSize=Lv.xp and 13 or Lv.fs;self.LevelXP.TextColor3=C.muted
    local rw=right~=''and width(right,self.LevelXP.TextSize,self.LevelXP)or 0
    K.box(self.Level,0,0,lw+2,Lv.h);K.box(self.LevelXP,inner-rw-2,0,rw+2,Lv.h)
    local bx=lw+(Lv.xp and 10 or 12);local bw=inner-bx-(rw>0 and rw+(Lv.xp and 10 or 12)or 0)
    K.box(self.LevelTrack,bx,math.floor((Lv.h-Lv.barH)/2),bw,Lv.barH)
    local fill=(pr.nextXP or 0)==0 and 1 or math.clamp((pr.currentXP or 0)/math.max(1,pr.nextXP),0,1)
    self.target=self.target or {};self.target.fill=fill
    self.target.from=(pr.startNextXP or 0)>0 and math.clamp((pr.startCurrentXP or 0)/pr.startNextXP,0,1)or nil
    self.target.levels=math.max(0,(pr.level or 1)-(pr.startLevel or pr.level or 1))
    if self.animDone or self.played then self.bar:set(fill)elseif not self.counting then self.bar:set(self.target.from or(up and 0 or fill))end
end

function M:detailLines(v,state,y,p,w,details)
    local function line(name,value,color)
        local l=self[name]or self.lines[name];l.Visible=value~=nil and details
        if value and details then
            l.Text=value;l.TextColor3=color or self.inks[name]or C.ink
            local h=l.TextWrapped and math.max(22,TextService:GetTextSize(L.text(value),l.TextSize,Enum.Font.BuilderSansBold,Vector2.new(w,10000)).Y+6)or 22
            K.box(l,p,y,w,h);y+=h+6
        end
    end
    local rec=v.records;local gap=8;local rw=math.floor((w-3*gap)/4);local rh=52
    for i,r in ipairs(self.records)do
        r.root.Visible=details and rec~=nil
        if rec and details then
            local n=rec[r.key]or 0;r.value.Text=r.key=='troops'and UI.troops(n)or tostring(math.floor(n));r.value.TextColor3=C.ink;r.cap.TextColor3=C.muted
            K.box(r.root,p+(i-1)*(rw+gap),y,rw,rh);K.box(r.icon,10,8,18,18);K.box(r.value,34,4,rw-40,26);K.fit(r.value,rw-40,18,11);K.box(r.cap,10,rh-22,rw-16,18)
        end
    end
    if rec and details then y+=rh+10 end
    line('Winner',v.winner)
    line('MatchStatus',nil)
    local ladder,lc=M.ladderLine(state.personalResult);line('Ladder',self.noteKey~='Ladder'and ladder or nil,lc)
    local cp=v.campaign
    if cp then local Campaign=require(script.Parent.Parent.Core.CampaignRules)
        line('Campaign',string.format('캠페인 %s %s  %s',cp.id,cp.name,Campaign.starText(cp.stars))..(cp.best~=cp.stars and string.format('  최고 %s',Campaign.starText(cp.best))or ''))
        line('CampaignTask',self.noteKey~='CampaignTask'and cp.task or nil)
        local lesson=require(script.Parent.Parent.Core.CampaignLessons).of(cp.id)
        line('CampaignLearned',lesson and lesson.learned and string.format('배운 것  %s%s',lesson.learned,cp.taskDone and '  ✓'or '')or nil)
    else line('Campaign',nil);line('CampaignTask',nil);line('CampaignLearned',nil)end
    line('Tomorrow',self.noteKey~='Tomorrow'and v.settled and v.tomorrow or nil)
    line('Daily',v.daily~=nil and v.status~='practice'and string.format('오늘의 도전 %s',v.daily.score)or nil)
    line('Stats',string.format('도시 %d  지원 %d  참여 %s',v.cities,v.supports,clock(v.seconds)))
    line('Bonus',v.base and v.message or v.rewardNote..'\n'..v.message)
    local parts=v.status~='practice'and v.bonus and v.bonus.parts or nil;local rows={}
    if details and v.status~='practice'then
        if v.base then table.insert(rows,{name=v.rewardNote,xp=v.base.xp,medals=v.base.medals})end
        for i=1,4 do if parts and parts[i]then table.insert(rows,Model.partRow(parts[i]))end end
        if not parts and v.bonus and (v.bonus.xp>0 or v.bonus.medals>0)then table.insert(rows,{name='보너스',xp=v.bonus.xp,medals=v.bonus.medals})end
    end
    y=self:rewardRows(rows,y,p,w)
    local pr=v.progression;local grow=pr~=nil and v.status~='practice'
    local reward,nextAt
    if grow and details then nextAt=(pr.level or 1)+1;while nextAt<100 and not Career.levelReward(nextAt)do nextAt+=1 end;reward=Career.levelReward(nextAt)end
    self.NextIcon.Visible=reward~=nil;self.NextKind.Visible=reward~=nil;self.NextName.Visible=reward~=nil
    if reward then
        self.NextIcon.ImageColor3=reward.color and Color3.fromRGB(table.unpack(reward.color))or C.gold
        K.box(self.NextIcon,p,y+8,20,20);self.NextKind.Text=string.format('Lv. %d 명판',nextAt);self.NextName.Text=reward.name or ''
        K.box(self.NextKind,p+28,y,w-28,18);K.box(self.NextName,p+28,y+18,w-28,20);y+=44
    end
    local unlocked={}
    if grow and self.animDone then
        if pr.unlocks then unlocked=pr.unlocks elseif pr.startLevel then for _,r in ipairs(Career.between(pr.startLevel,pr.level or 1))do table.insert(unlocked,string.format('새 보상 %s',Career.rewardLabel(r.reward)))end end
    end
    if #unlocked>0 then require(script.Parent.TelemetryStep).once('unlocks:'..tostring(self.resultId),'result','unlocks',{value=#unlocked})end
    line('NewUnlock',#unlocked>0 and string.format('새 보상 %d개',#unlocked)or nil)
    local m=grow and pr.mastery
    line('MapRecord',m and (pr.conquest and string.format('이 지도 %d승 / %d판  최고 %.1f%%  정복 %d/5',m.wins,m.games,m.peak*100,pr.conquest)or string.format('이 지도 %d승 / %d판  최고 %.1f%%',m.wins,m.games,m.peak*100))or nil)
    line('DailyDetail',v.daily~=nil and v.status~='practice'and string.format('오늘의 도전  이번 기록 %s  오늘 최고 %s',v.daily.score,v.daily.best)or nil)
    for i=1,4 do line('Unlock'..i,i<=3 and unlocked[i]or i==4 and (#unlocked==4 and unlocked[4]or #unlocked>4 and string.format('외 %d개, 기록에서 장착',#unlocked-3))or nil)end
    local goals=grow and pr.career and pr.career.goals or {}
    line('Next0',#goals>0 and '다음 목표'or nil)
    for i=1,3 do line('Next'..i,goals[i])end
    local g=v.status~='practice'and v.goal
    local value=g and (g.seconds and string.format('%d/%d분',math.floor(g.value/60),g.target/60)or string.format('%d/%d',g.value,g.target))
    line('Goal',g and string.format(g.weekly and '이번 주 %s  %s'or '오늘의 목표 %s  %s',g.name,value)or nil)
    self.Recap.Visible=details
    if details then self.recapButton:place(p,y+4,w,44);y+=56 end
    return y
end
function M:rewardRows(rows,y,p,w)
    self.rows=self.rows or {}
    for i,r in ipairs(self.rows)do r.root.Visible=rows[i]~=nil end
    for i,row in ipairs(rows)do
        local r=self.rows[i]
        if not r then
            local root=K.make('Frame',self.body,{Name='RewardRow'..i,BackgroundTransparency=1});r={root=root}
            r.name=K.text(root,'Name','',14,C.muted,700)
            r.xp=K.amount(root,'XP','xp','',14,C.ink);r.coin=K.amount(root,'Coins','coin','',14,C.gold)
            self.rows[i]=r
        end
        r.root.Visible=true;K.box(r.root,p,y,w,24);r.name.Text=row.name;r.name.TextColor3=C.muted
        r.xp.Value.TextColor3=C.ink;r.coin.Value.TextColor3=C.gold
        local cw=76
        for c,k in ipairs({'xp','coin'})do
            local n=k=='xp'and row.xp or row.medals;local f=r[k]
            f.Visible=n>0
            if n>0 then local l=f:FindFirstChild('Value');l.Text='+'..commas(n);local tw=width(l.Text,14,l);K.box(l,19,0,tw+2,14);K.box(f,w-(3-c)*cw,5,19+tw+2,14)end
        end
        K.box(r.name,0,0,math.max(40,w-2*cw-4),24)
        y+=28
    end
    return y
end

function M:buttons(v,fmt,G,cw,ch,p,lift)
    local a=self.actions;if not a then return end
    local ay=G.acts+lift;K.box(a,0,ay,cw,ch-ay)
    local again,lobby=a:FindFirstChild('Again'),a:FindFirstChild('ChooseMode')
    local spectate,comrades=a:FindFirstChild('Spectate'),a:FindFirstChild('Comrades')
    local Invite=require(script.Parent.FriendInviteCard);local inviteAsk=v.won and v.invite or nil
    local inviteButton=a:FindFirstChild('Invite');if inviteButton and inviteButton:GetAttribute('Ask')~=(inviteAsk~=nil)then Invite.set(inviteButton,inviteAsk)end
    local slot=Invite.slot(a)
    local B=G.big;local by=(B.y<0 and ch+B.y or B.y+lift)-ay
    local bigWatch=v.continuing and spectate or nil
    local leftW=bigWatch and(B.watchW or B.lobbyW)or B.lobbyW;local bgap=fmt=='ph'and 10 or fmt=='pt'and 8 or 12
    if v.nextStage and lobby and again and not bigWatch then
        local f=adopt(again,'plain');place(again,p,by,B.lobbyW,B.h);content(f,C.ink,nil,nil,v.nextStage,B.lobbyFs)
        f=adopt(lobby,'pri');place(lobby,p+B.lobbyW+bgap,by,cw-p*2-B.lobbyW-bgap,B.h);content(f,C.bg,B.againIs and 'back'or nil,B.againIs,L.text('로비'),B.againFs)
    else
        if bigWatch then local f=adopt(bigWatch,'plain');place(bigWatch,p,by,leftW,B.h);content(f,C.ink,'watch',B.watchIs or B.lobbyIs,L.text('관전'),B.lobbyFs)
        elseif lobby then local f=adopt(lobby,'plain');place(lobby,p,by,B.lobbyW,B.h);content(f,C.ink,B.lobbyIs and 'back'or nil,B.lobbyIs,L.text('로비'),B.lobbyFs)end
        if again then
            local f=adopt(again,'pri');place(again,p+leftW+bgap,by,cw-p*2-leftW-bgap,B.h)
            local t=again:GetAttribute('Text20')or ''
            local party=t=='파티장과 함께 준비'or t==L.text('파티장과 함께 준비')
            if (v.campaign or v.casual and not party) and v.again then t=v.again;again:SetAttribute('Text20',t)end
            if t=='같은 설정으로 한 판 더'then t='한 판 더'end
            content(f,C.bg,B.againIs and 'restore'or nil,B.againIs,L.text(t),B.againFs)
        end
    end
    local R1=G.row1
    local watch=not bigWatch and(spectate or self.closeObj)or nil
    local icons={}
    if bigWatch and lobby and fmt=='pt'then table.insert(icons,{b=lobby,icon='back',text='로비'})
        if comrades and slot and slot.Name~='Invite'then slot.Visible=false;slot=nil end end
    if slot and slot.Name~='Invite'then table.insert(icons,{b=slot,icon='share',text='공유'});slot=nil end
    if watch and watch.Parent then table.insert(icons,{b=watch,icon=spectate and 'watch'or 'map',text=spectate and '관전'or '지도 보기'})end
    if comrades then table.insert(icons,{b=comrades,icon='friends',text='함께한 지휘관'})end
    table.insert(icons,{kit=fmt=='pt'and self.detailsText or self.details,icon='records',text='상세 기록'})
    self.details.button.Visible=fmt~='pt';self.detailsText.button.Visible=fmt=='pt'
    self.detailsText:setText(self.detailsExpanded and '상세 접기'or '상세 기록')
    for _,b in ipairs({self.details,self.detailsText})do b:setKind(self.detailsExpanded and 'out'or 'plain');b.iconImage.ImageColor3=self.detailsExpanded and C.accent or C.muted end
    if R1.text then
        local n=#icons;local bw=math.floor((cw-p*2-8*(n-1))/n)
        for i,it in ipairs(icons)do local x=p+(i-1)*(bw+8);local w=i==n and cw-p-x or bw
            if it.kit then it.kit:place(x,ay,w,R1.h);it.kit.label.TextSize=R1.fs;it.kit:layoutContent()
            else local f=adopt(it.b,'plain');place(it.b,x,it.b.Parent==a and 0 or ay,w,R1.h);content(f,C.ink,it.icon,R1.is,L.text(it.text),R1.fs)end end
        if slot then local I=G.invite;local ask=slot.Name=='Invite'
            local f=adopt(slot,ask and 'goldo'or 'plain');place(slot,p,I.y+lift-ay,cw-p*2,I.h);K.round(f,10)
            content(f,ask and C.gold or C.ink,ask and 'invite'or 'share',I.is,L.text(ask and '친구 초대'or '결과 공유'),I.fs,ask and v.invite and '+'..commas(v.invite.coins)or nil,I.coin,'badge')end
    else
        local x=cw-p
        for i=#icons,1,-1 do local it=icons[i];x-=R1.icon
            if it.kit then it.kit:place(x,ay,R1.icon,R1.icon);it.kit.iconSize=R1.iconIs;it.kit:layoutContent()
            else local f=adopt(it.b,'plain');place(it.b,x,it.b.Parent==a and 0 or ay,R1.icon,R1.icon);content(f,C.muted,it.icon,R1.iconIs,nil,nil)end
            x-=8 end
        if bigWatch and lobby then local f=adopt(lobby,'plain');local lw=math.max(R1.h,R1.is+8+width('로비',R1.fs)+28)
            place(lobby,p,0,lw,R1.h);content(f,C.ink,'back',R1.is,L.text('로비'),R1.fs)end
        if slot then local ask=slot.Name=='Invite'
            local f=adopt(slot,ask and 'goldo'or 'plain')
            local w=ask and R1.invW or math.min(R1.invW,x-p)
            place(slot,p,0,w,R1.h)
            content(f,ask and C.gold or C.ink,ask and 'invite'or 'share',R1.is,L.text(ask and '친구 초대'or '결과 공유'),R1.fs,ask and v.invite and '+'..commas(v.invite.coins)or nil,R1.coin,'badge')end
    end
end

function M:intro(v)
    if self.introStarted then return end;self.introStarted=true
    local Moment=require(script.Parent.ResultCelebration)
    local key=tostring(self.resultId or (self.state and self.state.version)or 'local')
    if M.played[key]then self.played=true;self.animDone=true;self.seqDone=true;self:update(self.state,self.width);return end
    M.played[key]=true
    self.reducedFx=Moment.reduced or K.reduced
    local parts={self.Outcome,self.RankRow,self.StatsRow,self.Note,self.Best,self.RewardBand,self.Growth}
    for _,o in ipairs(parts)do K.fade(o,false,0)end
    local scales={}
    local function scaleOf(o,from)local s=o:FindFirstChild('Punch')or K.make('UIScale',o,{Name='Punch'});s.Scale=self.reducedFx and 1 or from;table.insert(scales,s);return s end
    local won=v.won==true
    local title,rank=scaleOf(self.Outcome,won and .9 or 1),scaleOf(self.RankRow,won and 1.3 or 1)
    local items={};for _,it in ipairs(self.rewardItems or {})do table.insert(items,scaleOf(it.o,.6))end
    self.seqScales=scales
    local t0=math.max(os.clock(),Moment.busyUntil-.2);self.seqStart=t0
    local function at(dt,fn)task.delay(math.max(0,t0+dt-os.clock()),function()if not self.seqDone and self.root.Parent then fn()end end)end
    local function pop(s,t,style)if self.reducedFx then return end;local tw=TweenService:Create(s,TweenInfo.new(t,style,Enum.EasingDirection.Out),{Scale=1});tw:Play()end
    if self.reducedFx then
        at(0,function()for _,o in ipairs(parts)do K.fade(o,true,.12)end end)
    else
        if won then
            at(0,function()K.fade(self.Outcome,true,.18);pop(title,.18,Enum.EasingStyle.Cubic)end)
            at(.14,function()K.fade(self.RankRow,true,.08);pop(rank,.18,Enum.EasingStyle.Back);if self.RankRow.Visible then require(script.Parent.ToyAudio).play('pop')end end)
        else
            at(0,function()K.fade(self.Outcome,true,.16)end)
            at(.14,function()K.fade(self.RankRow,true,.16)end)
        end
        at(.22,function()K.fade(self.StatsRow,true,.14);K.fade(self.Note,true,.14);K.fade(self.Best,true,.14)end)
        at(.26,function()K.fade(self.RewardBand,true,.14)end)
        for i,s in ipairs(items)do at(.30+(i-1)*.04,function()pop(s,.14,Enum.EasingStyle.Back)end)end
        at(.46,function()K.fade(self.Growth,true,.14)end)
    end
    at(1.2,function()self.seqDone=true end)
    self:tryCount()
end
function M:tryCount()
    local v=self.view;if self.counting or self.animDone or not v then return end
    local ready=v.settled or os.clock()-(self.openedAt or os.clock())>=3
    if not ready then task.delay(.5,function()if self.root.Parent and self.state then self:update(self.state,self.width);self:tryCount()end end);return end
    local p=self.Growth.Visible and v.progression or nil
    self.counting=true
    local levels=p and self.target and self.target.levels or 0
    local Step=require(script.Parent.TelemetryStep)
    if self.reducedFx or self.skipped or (v.xp<=0 and v.medals<=0 and levels==0)then
        self.animDone=true;self.counting=false;Step.step('result','rewardsShown',{value=v.xp,count=v.medals,reason='skipped'})
        if levels>0 then self:levelUp(p)end;self:update(self.state,self.width);return
    end
    local fill=self.target and self.target.fill;local from=fill
    if p and fill then from=self.target.from or (p.nextXP or 0)>0 and (levels>0 and 0 or math.max(0,fill-v.xp/math.max(1,p.nextXP)))or fill end
    self.Rewards.Text=self:xpText(0);self.RewardMedals.Text=self:coinText(0);if from then self.bar:set(from)end
    local start=math.max(os.clock(),(self.seqStart or os.clock())+.42);local nSpan=.45;local bSpan=levels>0 and .6 or .5;local bStart=start+.13
    local traded=false
    self.finish=function(skipped)
        if self.counter then self.counter:Disconnect();self.counter=nil end
        if self.animDone then return end;self.animDone=true;self.counting=false
        Step.step('result','rewardsShown',{value=v.xp,count=v.medals,reason=skipped and 'skipped'or 'completed'})
        if levels>0 and not self.leveled then self:levelUp(p)end
        self.shownLevel=nil;if self.state then self:update(self.state,self.width)end
    end
    self.counter=game:GetService('RunService').Heartbeat:Connect(function()
        if not self.root.Parent then self.counter:Disconnect();return end
        local now=os.clock();local g=self.view
        local tn=math.clamp((now-start)/nSpan,0,1);local en=1-(1-tn)^4
        if tn>0 then self.Rewards.Text=self:xpText(g.xp*en);self.RewardMedals.Text=self:coinText(g.medals*en)end
        if tn>=1 and not traded then traded=true;require(script.Parent.ToyAudio).play('trade')
            if not K.reduced then K.punch(self.xpAmt,1.12,.16);if self.coinAmt.Visible then K.punch(self.coinAmt,1.12,.16)end end end
        local tb=math.clamp((now-bStart)/bSpan,0,1);local eb=1-(1-tb)^4
        if from and self.target.fill and tb>0 then
            local pos=from+(levels+self.target.fill-from)*eb;local lv=math.min(math.floor(pos),levels)
            self.bar:set(math.clamp(pos-lv,0,1))
            if lv>0 and not self.leveled then self:levelUp(p)end
        end
        if tn>=1 and tb>=1 then self.finish(false)end
    end)
end
function M:skip()
    if self.trophyResult then require(script.Parent.TrophyResultView).skip(self);return end
    if self.seqDone then return end;self.seqDone=true;self.skipped=true
    for _,s in ipairs(self.seqScales or {})do s.Scale=1 end
    for _,o in ipairs({self.Outcome,self.RankRow,self.StatsRow,self.Note,self.Best,self.RewardBand,self.Growth})do K.fade(o,true,0)end
    if self.finish and not self.animDone then self.finish(true)end
end
function M:levelUp(p)
    if self.leveled or not p then return end;self.leveled=true
    require(script.Parent.TelemetryStep).step('result','levelUp',{value=p.level,count=(p.level or 1)-(p.startLevel or p.level or 1),result='ok'})
    require(script.Parent.ResultCelebration).levelUp(self.resultId)
    self.shownLevel=p.level;self.Level.Text=string.format('Lv %d',p.level or 1);self.Level.TextColor3=C.gold
    if not self.reducedFx then K.punch(self.Level,1.25,.2)end
end
return M
