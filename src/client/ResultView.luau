local UI=require(script.Parent.Theme)
local Model=require(script.Parent.Parent.Core.ResultPresentation)
local Career=require(script.Parent.Parent.Core.CareerRules)
local Icons=require(script.Parent.OutgameIcons)
local L=require(script.Parent.Localization)
local TextService=game:GetService('TextService')
local TweenService=game:GetService('TweenService')
local M={};M.__index=M
local C=UI.colors
local function clock(s)return string.format('%02d:%02d',math.floor(s/60),math.floor(s%60))end
local function set(o,k,v)if o[k]~=v then o[k]=v end end
local actionIcons={Again='deploy',ChooseMode='fields',Spectate='watch',Comrades='friends',Share='invite'}
function M.ladderLine(pr)
    local r=pr and pr.ranked
    if type(r)=='table'then
        local head=L.text(r.ladder=='2v2'and '랭크 2대2'or '랭크 1대1')
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
function M.new(body,compact,recap,relayout)
    local self=setmetatable({body=body,compact=compact,detailsExpanded=false,relayout=relayout,pops={}},M)
    local function text(name,size,color,parent)
        local l=UI.label(parent or body,name,'',size,color);self[name]=l;return l
    end
    self.tiles={}
    for i,name in ipairs({'TileRank','TileShare','TileTime'})do
        local t=UI.make('Frame',body,{Name=name,BackgroundColor3=C.raised,BackgroundTransparency=.08,BorderSizePixel=0});UI.corner(t,3)
        self.tiles[i]=t
        UI.make('Frame',t,{Name='Accent',BackgroundColor3=C.accent,BorderSizePixel=0,Size=UDim2.new(1,0,0,3)})
        table.insert(self.pops,t)
    end
    text('Peak',compact and 28 or 34,C.accent);UI.display(self.Peak);self.Peak.TextWrapped=false;self.Peak.TextXAlignment=Enum.TextXAlignment.Center
    text('PeakLabel',14,C.muted).TextXAlignment=Enum.TextXAlignment.Center
    text('Share',compact and 28 or 34,C.ink);UI.display(self.Share);self.Share.TextWrapped=false;self.Share.TextXAlignment=Enum.TextXAlignment.Center
    text('ShareLabel',14,C.muted).TextXAlignment=Enum.TextXAlignment.Center
    text('Time',compact and 28 or 34,C.ink);UI.display(self.Time);self.Time.TextWrapped=false;self.Time.TextXAlignment=Enum.TextXAlignment.Center
    text('TimeLabel',14,C.muted).TextXAlignment=Enum.TextXAlignment.Center
    for _,o in ipairs({self.Peak,self.PeakLabel,self.Share,self.ShareLabel,self.Time,self.TimeLabel})do table.insert(self.pops,o)end
    self.records={}
    local Hot=require(script.Parent.HotbarIcons)
    for i,k in ipairs({{'conquered','점령한 국가','Crown'},{'troops','총 사용 병력','Soldier'},{'built','지은 건물','City'},{'nukes','사용한 핵','AtomBomb'}})do
        local t=UI.make('Frame',body,{Name='Record_'..k[1],BackgroundColor3=C.raised,BackgroundTransparency=.08,BorderSizePixel=0,Visible=false});UI.corner(t,3)
        local icon=Hot.create(t,k[3],18,k[1]=='nukes'and C.gold or C.ink)
        local value=UI.label(t,'Value','',18,C.ink);value.Font=Enum.Font.BuilderSansBold;value.TextWrapped=false;value:SetAttribute('LocalizationSkip',true)
        local cap=UI.label(t,'Caption',k[2],13,C.muted);cap.TextWrapped=false;cap.TextTruncate=Enum.TextTruncate.AtEnd
        self.records[i]={root=t,key=k[1],icon=icon,value=value,cap=cap};table.insert(self.pops,t)
    end
    text('Winner',14,C.ink).TextTruncate=Enum.TextTruncate.AtEnd;self.Winner.TextWrapped=false
    text('Stats',14,C.ink)
    self.RewardBand=UI.make('Frame',body,{Name='RewardBand',BackgroundColor3=C.gold,BackgroundTransparency=.86,BorderSizePixel=0});UI.corner(self.RewardBand,3)
    UI.stroke(self.RewardBand,C.gold,1).Transparency=.45;table.insert(self.pops,self.RewardBand)
    text('Rewards',22,C.gold).Font=Enum.Font.BuilderSansExtraBold;text('RewardMedals',20,C.gold).Font=Enum.Font.BuilderSansExtraBold
    self.xpIcon=Icons.create(body,'xp',24,C.gold);self.medalIcon=Icons.create(body,'coin',24,C.gold)
    for _,o in ipairs({self.Rewards,self.RewardMedals,self.xpIcon,self.medalIcon})do table.insert(self.pops,o)end
    text('RewardState',14,C.muted)
    text('Ladder',15,C.ink);self.Ladder.Font=Enum.Font.BuilderSansBold;self.Ladder.TextXAlignment=Enum.TextXAlignment.Center;self.Ladder.TextWrapped=false;self.Ladder.TextTruncate=Enum.TextTruncate.AtEnd
    self.Ladder.BackgroundColor3=C.raised;self.Ladder.BackgroundTransparency=.08;self.Ladder:SetAttribute('LocalizationSkip',true);UI.corner(self.Ladder,3);self.ladderLine=UI.stroke(self.Ladder,C.line,1);table.insert(self.pops,self.Ladder)
    self.Growth=UI.panel(body,'Growth');table.insert(self.pops,self.Growth)
    self.Level=UI.label(self.Growth,'Level','',20,C.ink);UI.display(self.Level)
    self.LevelXP=UI.label(self.Growth,'LevelXP','',14,C.muted);self.LevelXP.TextXAlignment=Enum.TextXAlignment.Right
    self.RewardPreview=UI.panel(self.Growth,'RewardPreview')
    self.NextIcon=Icons.create(self.RewardPreview,'reward',28,C.gold)
    self.NextKind=UI.label(self.Growth,'NextKind','',14,C.muted)
    self.NextName=UI.label(self.Growth,'NextName','',16,C.ink);self.NextName.TextWrapped=false;self.NextName.TextTruncate=Enum.TextTruncate.AtEnd
    self.LevelTrack=UI.make('Frame',self.Growth,{Name='Track',BackgroundColor3=C.line,BorderSizePixel=0,ClipsDescendants=true})
    self.LevelFill=UI.make('Frame',self.LevelTrack,{Name='Fill',BackgroundColor3=C.accent,BorderSizePixel=0})
    UI.make('UIGradient',self.LevelFill,{Color=ColorSequence.new(C.accent,C.ice)})
    text('Goal',14,C.muted);text('Bonus',14,C.gold);text('MapRecord',14,C.muted)
    text('Daily',14,C.ink);text('DailyDetail',14,C.muted);text('NewUnlock',14,C.gold)
    self.lines={}
    for i=1,4 do self.lines['Unlock'..i]=text('Unlock'..i,14,C.gold)end
    for i=1,4 do self.lines['Bonus'..i]=text('Bonus'..i,14,C.gold)end
    for i=0,3 do self.lines['Next'..i]=text('Next'..i,14,i==0 and C.muted or C.ink)end
    text('MatchStatus',14,C.ice)
    self.Details=UI.button(body,'Details','상세 기록',function()self:setDetails(not self.detailsExpanded)end)
    self.Recap=UI.button(body,'Recap','전황 보기',recap)
    for _,b in ipairs({self.Details,self.Recap})do b.BackgroundTransparency=.1;UI.stroke(b,C.line,1);table.insert(self.pops,b)end
    self:dressCard()
    return self
end
function M:dressCard()
    local card=self.body.Parent;if not card or self.card then return end
    self.card=card
    local title=card:FindFirstChild('Title');local close=card:FindFirstChild('Close');local stroke=card:FindFirstChildOfClass('UIStroke')
    local saved={title=title and {TextSize=title.TextSize,FontFace=title.FontFace,TextColor3=title.TextColor3,ZIndex=title.ZIndex},
        close=close and {ZIndex=close.ZIndex},stroke=stroke and {Color=stroke.Color,Thickness=stroke.Thickness}}
    local banner=UI.make('Frame',card,{Name='ResultBanner',BackgroundColor3=C.accent,BackgroundTransparency=.55,BorderSizePixel=0,Size=UDim2.new(1,0,0,64),ZIndex=2});UI.corner(banner,3)
    self.bannerGradient=UI.make('UIGradient',banner,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.55,.55),NumberSequenceKeypoint.new(1,1)})})
    for i=1,3 do UI.make('Frame',banner,{Name='Stripe'..i,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(0,150+i*16,.5,0),Size=UDim2.fromOffset(6,96),Rotation=24,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=.9,BorderSizePixel=0,ZIndex=2})end
    banner.ClipsDescendants=true
    self.bannerRule=UI.make('Frame',card,{Name='ResultBannerRule',BackgroundColor3=C.accent,BorderSizePixel=0,Position=UDim2.fromOffset(0,63),Size=UDim2.new(1,0,0,2),ZIndex=2})
    local seal=UI.make('TextLabel',card,{Name='PledgeSeal',Text='NO PAY-TO-WIN',TextSize=12,TextColor3=C.accent,BackgroundColor3=C.bg,BackgroundTransparency=.2,AnchorPoint=Vector2.new(1,.5),AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,22),Font=Enum.Font.BuilderSansBold,BorderSizePixel=0,ZIndex=3,AutoLocalize=false})
    seal:SetAttribute('LocalizationSkip',true);UI.display(seal,true);UI.corner(seal,3);UI.make('UIPadding',seal,{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)});UI.stroke(seal,C.accent,1)
    self.seal=seal;self.banner=banner
    if title then title.ZIndex=3;UI.display(title)end
    if close then close.ZIndex=3 end
    self.Peak.Destroying:Once(function()
        banner:Destroy();self.bannerRule:Destroy();seal:Destroy()
        if title and saved.title then for k,v in pairs(saved.title)do pcall(function()title[k]=v end)end end
        if close and saved.close then close.ZIndex=saved.close.ZIndex end
        if stroke and saved.stroke then stroke.Color=saved.stroke.Color;stroke.Thickness=saved.stroke.Thickness end
    end)
end
function M:paintCard(v)
    local card=self.card;if not card then return end
    local lost=not v.won and v.title=='패배'
    local tint=v.won and C.accent or lost and C.danger or C.muted
    set(self.banner,'BackgroundColor3',tint);set(self.bannerRule,'BackgroundColor3',tint)
    local title=card:FindFirstChild('Title')
    if title then set(title,'TextColor3',C.ink);set(title,'TextSize',self.compact and 28 or 34)end
    local stroke=card:FindFirstChildOfClass('UIStroke');if stroke then set(stroke,'Color',tint);set(stroke,'Thickness',2)end
    local w=card.AbsoluteSize.X/UI.scale
    self.seal.Visible=w>=400;self.seal.Position=UDim2.new(1,-86,0,32);set(self.seal,'TextColor3',C.accent)
    for _,t in ipairs(self.tiles)do set(t.Accent,'BackgroundColor3',tint)end
end
function M:dressActions()
    local card=self.card;local actions=card and card:FindFirstChild('ResultActions');if not actions then return end
    for _,b in ipairs(actions:GetChildren())do if b:IsA('TextButton')then
        local primary=b.Name=='Again'
        if not b:GetAttribute('GameDressed')then
            b:SetAttribute('GameDressed',true)
            UI.make('Frame',b,{Name='Lip',AnchorPoint=Vector2.new(0,1),Position=UDim2.fromScale(0,1),Size=UDim2.new(1,0,0,4),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=primary and .55 or .45,BorderSizePixel=0,Active=false})
            UI.make('UIGradient',b,{Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(214,222,230)),Rotation=90})
            if primary then UI.stroke(b,C.ice,1).Transparency=.5 else UI.stroke(b,C.line,1)end
            b.Font=Enum.Font.BuilderSansExtraBold
            local key=actionIcons[b.Name]
            if key then local icon=Icons.create(b,key,20,primary and C.bg or C.ink);icon.Name='ActionIcon';icon.AnchorPoint=Vector2.new(0,.5)end
            table.insert(self.pops,b)
        end
        local icon=b:FindFirstChild('ActionIcon')
        if icon then
            local bw=b.AbsoluteSize.X/UI.scale;local tw=TextService:GetTextSize(b.Text,b.TextSize,b.Font,Vector2.new(1000,44)).X
            local room=bw>=110 and tw+28<=bw-12;icon.Visible=room and Icons.available(icon)
            local padLeft=icon.Visible and 28 or 0
            if icon.Visible then icon.Position=UDim2.new(.5,-math.floor(tw/2)-28,.5,-1)end
            local pad=b:FindFirstChild('IconRoom')or UI.make('UIPadding',b,{Name='IconRoom'})
            set(pad,'PaddingLeft',UDim.new(0,padLeft))
            local lip=b:FindFirstChild('Lip');if lip then set(lip,'Position',UDim2.new(0,-padLeft,1,0));set(lip,'Size',UDim2.new(1,padLeft,0,4))end
        end
        if primary then set(b,'TextSize',math.max(b.TextSize,16))end
    end end
end
function M:setDetails(open)
    require(script.Parent.TelemetryStep).step('result','details',{result=open and 'opened'or 'closed'})
    self.detailsExpanded=open==true
    if not open then self.body.CanvasPosition=Vector2.zero end
    if self.state then self:update(self.state,self.width)end
    if open then self.body.CanvasPosition=Vector2.new(0,math.max(0,self.Details.Position.Y.Offset-8))end
    if self.relayout then self.relayout()end
end
function M:enter()
    if self.entered then return end;self.entered=true
    local Moment=require(script.Parent.ResultCelebration)
    if Moment.reduced then return end
    local list={}
    for _,o in ipairs(self.pops)do if o.Parent then local s=o:FindFirstChild('Pop')or UI.make('UIScale',o,{Name='Pop'});s.Scale=.82;table.insert(list,s)end end
    task.delay(math.max(0,Moment.busyUntil-os.clock()-.2),function()
        for i,s in ipairs(list)do if s.Parent then
            local step=math.min(8,i)
            TweenService:Create(s,TweenInfo.new(.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out,0,false,step*.035),{Scale=1}):Play()
        end end
    end)
end
function M:update(state,width)
    self.state=state;self.width=width
    if self.telemetryVersion~=state.version and require(script.Parent.TelemetryClient).visible(self.body)then self.telemetryVersion=state.version;require(script.Parent.TelemetryClient).emit('result_viewed',{stage='shown',version=state.version,result=state.personalResult and state.personalResult.outcome or 'unknown'})end
    local v=Model.view(state);local compact=self.compact;local w=math.max(232,width-12)
    local details=self.detailsExpanded
    self.body:SetAttribute('RecordStatus',v.status);self.body:SetAttribute('ResultOutcome',state.personalResult and state.personalResult.outcome or '')
    self.body:SetAttribute('DetailsExpanded',details)
    self:paintCard(v)
    require(script.Parent.ResultCelebration).card=self.Rewards
    local tiles={}
    if v.rank then table.insert(tiles,{self.Peak,self.PeakLabel,string.format('%d위',v.rank),string.format('%d명 중 순위',v.total),v.rank<=3 and C.gold or C.accent})end
    table.insert(tiles,{v.rank and self.Share or self.Peak,v.rank and self.ShareLabel or self.PeakLabel,(v.peak>0 and v.peak<.0005 and '<0.1%'or string.format('%.1f%%',v.peak*100)),'최고 영토',v.rank and C.ink or C.accent})
    table.insert(tiles,{self.Time,self.TimeLabel,clock(v.seconds),'작전 시간',C.ink})
    self.Share.Visible=v.rank~=nil;self.ShareLabel.Visible=v.rank~=nil
    local gap=8;local tw=math.floor((w-(#tiles-1)*gap)/#tiles);local th=compact and 70 or 80;local ty=3
    local valueSize=math.clamp(math.floor(tw/4.4),20,compact and 28 or 34)
    for i,t in ipairs(self.tiles)do
        local row=tiles[i];t.Visible=row~=nil
        if row then
            local x=4+(i-1)*(tw+gap);UI.box(t,x,ty,tw,th)
            local value,caption=row[1],row[2];value.Text=row[3];caption.Text=row[4];value.TextColor3=row[5];value.TextSize=valueSize
            UI.box(value,x+4,ty+8,tw-8,th-34);UI.box(caption,x+4,ty+th-26,tw-8,20)
        end
    end
    local y=ty+th+10
    local rec=v.records;local rw=math.floor((w-3*gap)/4);local rh=compact and 50 or 56
    for i,r in ipairs(self.records)do
        r.root.Visible=rec~=nil
        if rec then
            local n=rec[r.key]or 0
            r.value.Text=r.key=='troops'and UI.troops(n)or tostring(math.floor(n))
            UI.box(r.root,4+(i-1)*(rw+gap),y,rw,rh);UI.box(r.icon,10,8,18,18);UI.box(r.value,34,4,rw-40,26);UI.box(r.cap,10,rh-22,rw-16,18)
        end
    end
    if rec then y+=rh+10 end
    self.Winner.Visible=details and v.winner~=nil
    if self.Winner.Visible then self.Winner.Text=v.winner;UI.box(self.Winner,4,y,w,20);y+=24 end
    self.openedAt=self.openedAt or os.clock();self.resultId=state.personalResult and state.personalResult.id
    local ready=v.settled or os.clock()-self.openedAt>=3
    local settled=self.animDone==true;self.target={xp=v.xp,medals=v.medals}
    if settled then self.Rewards.Text=string.format('+%d XP',v.xp);self.RewardMedals.Text=string.format('+%d 코인',v.medals)
    elseif not self.counting then self.Rewards.Text='+0 XP';self.RewardMedals.Text=string.format('+%d 코인',0)end
    local rewardVisible=v.xp>0 or v.medals>0
    self.Rewards.Visible=rewardVisible;self.xpIcon.Visible=rewardVisible;self.RewardBand.Visible=rewardVisible
    self.RewardMedals.Visible=v.medals>0;self.medalIcon.Visible=v.medals>0
    if rewardVisible then
        local xw=TextService:GetTextSize(string.format('+%d XP',v.xp),self.Rewards.TextSize,self.Rewards.Font,Vector2.new(w,30)).X+10
        local mw=TextService:GetTextSize(L.text(string.format('+%d 코인',v.medals)),self.RewardMedals.TextSize,self.RewardMedals.Font,Vector2.new(1000,30)).X+10
        local wrap=v.medals>0 and 16+30+xw+24+30+mw>w
        local bh=wrap and 76 or 44
        UI.box(self.RewardBand,4,y,w,bh)
        local total=30+xw+(v.medals>0 and not wrap and 24+30+mw or 0)
        local x=wrap and 16 or 4+math.floor((w-total)/2)
        UI.box(self.xpIcon,x,y+10,24,24);UI.box(self.Rewards,x+30,y+7,xw,30)
        local mx=wrap and 16 or x+30+xw+24;local my=y+(wrap and 34 or 0)
        UI.box(self.medalIcon,mx,my+10,24,24);UI.box(self.RewardMedals,mx+30,my+7,mw,30);y+=bh+8
    end
    local ladder,ladderColor=M.ladderLine(state.personalResult);self.Ladder.Visible=ladder~=nil
    if ladder then self.Ladder.Text=ladder;self.Ladder.TextColor3=ladderColor;self.ladderLine.Color=ladderColor==C.ink and C.line or ladderColor;UI.box(self.Ladder,4,y,w,30);y+=38 end
    local short=({practice='연습, 보상 없음',training='연습 기록',pending='저장 중…',unavailable='저장 재시도 중…',['local']='Studio 임시 기록'})[v.status]
    self.RewardState.Visible=short~=nil
    if short then self.RewardState.Text=short;self.RewardState.TextXAlignment=Enum.TextXAlignment.Center;UI.box(self.RewardState,4,y,w,20);y+=24 end
    local p=v.progression;self.Growth.Visible=p~=nil and v.status~='practice'
    if self.Growth.Visible then
        local gx=4;local gy=y+2
        local gh=compact and 96 or 104
        UI.box(self.Growth,gx,gy,w,gh)
        local up=(p.level or 1)>(p.startLevel or p.level or 1)
        if up and self.animDone and not self.leveled then self.leveled=true;self:levelUp(p)end
        local level=up and not self.leveled and p.startLevel or p.level or 1
        self.Level.Text=string.format('Lv. %d',level);self.Level.TextColor3=up and self.leveled and C.gold or C.ink
        local start=up and not self.leveled and p.startNextXP
        self.LevelXP.Text=start and string.format('%d / %d XP',p.startCurrentXP or 0,p.startNextXP)or (p.nextXP or 0)==0 and '최고 레벨'or string.format('%d / %d XP',p.currentXP or 0,p.nextXP or 0)
        UI.box(self.Level,12,8,84,26);UI.box(self.LevelXP,96,8,w-108,26)
        local reward=Career.levelReward((p.level or 1)+1)
        self.RewardPreview.Visible=reward~=nil;self.NextKind.Visible=reward~=nil;self.NextName.Visible=reward~=nil
        if reward then
            UI.box(self.RewardPreview,12,38,42,42);UI.box(self.NextIcon,7,7,28,28)
            Icons.set(self.NextIcon,reward.kind=='plate'and 'records'or 'ranked')
            self.NextIcon.ImageColor3=reward.color and Color3.fromRGB(table.unpack(reward.color))or C.gold
            self.NextKind.Text=string.format(reward.kind=='plate'and 'Lv. %d 명판'or 'Lv. %d 칭호',(p.level or 1)+1)
            self.NextName.Text=reward.name or ''
            UI.box(self.NextKind,66,36,w-78,20);UI.box(self.NextName,66,56,w-78,24)
        end
        local fill=(p.nextXP or 0)==0 and 1 or math.clamp((p.currentXP or 0)/math.max(1,p.nextXP),0,1);self.target.fill=fill
        self.target.from=(p.startNextXP or 0)>0 and math.clamp((p.startCurrentXP or 0)/p.startNextXP,0,1)or nil;self.target.levels=math.max(0,(p.level or 1)-(p.startLevel or p.level or 1))
        UI.box(self.LevelTrack,12,gh-16,w-24,6)
        if settled then self.LevelFill.Size=UDim2.fromScale(fill,1)elseif not self.counting then self.LevelFill.Size=UDim2.fromScale(self.target.from or (up and 0 or fill),1)end
        y=gy+gh+8
    end
    local unlocked={}
    if self.Growth.Visible and settled then
        if p.unlocks then unlocked=p.unlocks elseif p.startLevel then for _,r in ipairs(Career.between(p.startLevel,p.level or 1))do table.insert(unlocked,string.format('새 보상 %s',Career.rewardLabel(r.reward)))end end
    end
    self.NewUnlock.Visible=details and #unlocked>0
    if #unlocked>0 then require(script.Parent.TelemetryStep).once('unlocks:'..tostring(self.resultId),'result','unlocks',{value=#unlocked})end
    if self.NewUnlock.Visible then self.NewUnlock.Text=string.format('새 보상 %d개',#unlocked);UI.box(self.NewUnlock,4,y,w,20);y+=24 end
    self.Daily.Visible=details and v.daily~=nil and v.status~='practice'
    if self.Daily.Visible then self.Daily.Text=string.format('오늘의 작전 %s',v.daily.score);UI.box(self.Daily,4,y,w,24);y+=28 end
    self.MatchStatus.Visible=v.continuing
    if v.continuing then self.MatchStatus.Text='경기 진행 중, 관전 가능';UI.box(self.MatchStatus,4,y,w,24);y+=28 end
    self.Details.Text=details and '상세 접기'or '상세 기록'
    self.Recap.Visible=true
    UI.box(self.Details,4,y,(w-8)/2,44);UI.box(self.Recap,4+(w+8)/2,y,(w-8)/2,44);y+=52
    local function line(name,value)
        local l=self[name]or self.lines[name];l.Visible=value~=nil
        if value then
            l.Text=value
            local h=math.max(24,TextService:GetTextSize(L.text(value),l.TextSize,l.Font,Vector2.new(w,10000)).Y+6)
            UI.box(l,4,y,w,h);y+=h+6
        end
    end
    line('Stats',details and string.format('도시 %d  지원 %d  참여 %s',v.cities,v.supports,clock(v.seconds))or nil)
    line('Bonus',details and v.rewardNote..'\n'..v.message or nil)
    local parts=v.status~='practice'and v.bonus and v.bonus.parts or nil
    for i=1,4 do line('Bonus'..i,details and parts and parts[i]and Model.partLine(parts[i])or nil)end
    if details and v.status~='practice'and not parts and v.bonus and (v.bonus.xp>0 or v.bonus.medals>0)then line('Bonus1',string.format('보너스 +%d XP  +%d 코인',v.bonus.xp,v.bonus.medals))end
    local m=self.Growth.Visible and p.mastery
    line('MapRecord',details and m and (p.conquest and string.format('이 지도 %d승 / %d판  최고 %.1f%%  정복 %d/5',m.wins,m.games,m.peak*100,p.conquest)or string.format('이 지도 %d승 / %d판  최고 %.1f%%',m.wins,m.games,m.peak*100))or nil)
    line('DailyDetail',details and self.Daily.Visible and string.format('오늘의 작전  이번 기록 %s  오늘 최고 %s',v.daily.score,v.daily.best)or nil)
    for i=1,4 do line('Unlock'..i,details and (i<=3 and unlocked[i]or i==4 and (#unlocked==4 and unlocked[4]or #unlocked>4 and string.format('외 %d개, 기록에서 장착',#unlocked-3)))or nil)end
    local goals=self.Growth.Visible and p.career and p.career.goals or {}
    line('Next0',details and #goals>0 and '다음 목표'or nil)
    for i=1,3 do line('Next'..i,details and goals[i]or nil)end
    local g=v.status~='practice'and v.goal
    local value=g and (g.seconds and string.format('%d/%d분',math.floor(g.value/60),g.target/60)or string.format('%d/%d',g.value,g.target))
    line('Goal',details and g and string.format(g.weekly and '이번 주 %s  %s'or '오늘의 목표 %s  %s',g.name,value)or nil)
    self.body.CanvasSize=UDim2.fromOffset(0,y+4)
    self:dressActions();self:enter()
    if not self.counting and ready then self:count(v,self.Growth.Visible and p or nil)end
    return v
end
function M:levelUp(p)
    if self.leveledUp or not p then return end;self.leveledUp=true
    local promoted=p.title and p.startTitle and p.title~=p.startTitle
    require(script.Parent.TelemetryStep).step('result','levelUp',{value=p.level,count=(p.level or 1)-(p.startLevel or p.level or 1),result=promoted and 'granted'or 'ok'})
    require(script.Parent.ResultCelebration).promote(self.resultId,promoted and string.format('진급! %s Lv. %d',p.title,p.level or 1)or nil)
    local scale=self.Level:FindFirstChild('Pulse')or UI.make('UIScale',self.Level,{Name='Pulse'});scale.Scale=1.25
    TweenService:Create(scale,TweenInfo.new(.45,Enum.EasingStyle.Back),{Scale=1}):Play()
    if self.state then task.defer(function()if self.Level.Parent then self:update(self.state,self.width)end end)end
end
local function punch(o)
    local s=o:FindFirstChild('Punch')or UI.make('UIScale',o,{Name='Punch'});s.Scale=1.18
    TweenService:Create(s,TweenInfo.new(.28,Enum.EasingStyle.Back),{Scale=1}):Play()
end
function M:count(v,p)
    local Moment=require(script.Parent.ResultCelebration);self.counting=true
    local levels=p and self.target.levels or 0
    if Moment.reduced or (v.xp<=0 and v.medals<=0 and levels==0)then
        self.animDone=true;require(script.Parent.TelemetryStep).step('result','rewardsShown',{value=v.xp,count=v.medals,reason='skipped'});self.Rewards.Text=string.format('+%d XP',v.xp);self.RewardMedals.Text=string.format('+%d 코인',v.medals)
        if p and self.target.fill then self.LevelFill.Size=UDim2.fromScale(self.target.fill,1)end;return
    end
    local fill=self.target.fill;local from=fill
    if p and fill then from=self.target.from or (p.nextXP or 0)>0 and (levels>0 and 0 or math.max(0,fill-v.xp/math.max(1,p.nextXP)))or fill end
    self.Rewards.Text=string.format('+%d XP',0);self.RewardMedals.Text=string.format('+%d 코인',0)
    if from then self.LevelFill.Size=UDim2.fromScale(from,1)end
    local span=levels>0 and 1.3 or math.clamp(.6+math.log10(math.max(1,v.xp+v.medals))*.15,.6,1.1)
    local start=math.max(os.clock(),Moment.busyUntil)+.25;local conn
    conn=game:GetService('RunService').Heartbeat:Connect(function()
        if not self.Rewards.Parent then conn:Disconnect();return end
        local t=math.clamp((os.clock()-start)/span,0,1);local e=1-(1-t)^5;local g=self.target
        if t<=0 then return end
        self.Rewards.Text=string.format('+%d XP',math.floor(g.xp*e+.5));self.RewardMedals.Text=string.format('+%d 코인',math.floor(g.medals*e+.5))
        if from and g.fill then
            local pos=from+(levels+g.fill-from)*e;local lv=math.min(math.floor(pos),levels)
            self.LevelFill.Size=UDim2.fromScale(math.clamp(pos-lv,0,1),1)
            if lv>0 and not self.leveled then self.leveled=true;self:levelUp(p)end
        end
        if t>=1 then
            conn:Disconnect();self.animDone=true;require(script.Parent.TelemetryStep).step('result','rewardsShown',{value=v.xp,count=v.medals,reason='completed'});if levels>0 and not self.leveled then self.leveled=true;self:levelUp(p)end
            punch(self.Rewards);if self.RewardMedals.Visible then punch(self.RewardMedals)end
            pcall(function()require(script.Parent.ToyAudio).play('grow')end)
        end
    end)
end
return M
