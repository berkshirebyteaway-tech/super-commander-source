local Tracker=require(script.Parent.Parent.Core.FeedbackTracker)
local Catalog=require(script.Parent.Parent.Core.CosmeticCatalog)
local G=require(script.Parent.Parent.Core.WorldGeometry)
local UI=require(script.Parent.Theme)
local Badge=require(script.Parent.FactionBadge)
local Audio=require(script.Parent.ToyAudio)
local Display=require(script.Parent.Parent.Core.MapPresentation)
local NukeFx=require(script.Parent.NukeFx)
local NukeSkins=require(script.Parent.NukeSkins)
local Units=require(script.Parent.Parent.Core.UnitRules)
local L=require(script.Parent.Localization)
local Tween=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local M={};M.__index=M
local goldKinds={conquest=true,rankUp=true,firstCity=true,tiles=true,milestone=true}
local dangerKinds={betrayal=true,assault=true,allianceEnded=true,intercepted=true}
local function cue(kind,fallback,strength,pitch)
    Audio.play(Audio.has and Audio.has(kind)and kind or fallback,strength,pitch)
end
local mint=Color3.fromRGB(54,226,208)
local cream=Color3.fromRGB(191,239,255)
local coral=UI.colors.danger
local messages={detonate={"◇","폭발 확인"},intercept={"⊗","요격 성공"},intercepted={"⊗","로켓 요격당함"},complete={"✓","건설 완료"},upgraded={"↑","업그레이드 완료"},allied={"↔","동맹 연결!"},allianceEnded={"↔","동맹 종료"},eliminated={"◇","세력 붕괴"},milestone={"★","영토 확장!"},tiles={"★","영토 확장!"},conquest={"⚑","정복!"},betrayal={"⚠","배신!"},assault={"⚠","대공세!"},rankUp={"▲","순위 상승!"},firstCity={"★","첫 도시!"},start={"▶","작전 개시"},landing={"⚑","해안 도착!"},shipReady={"⚓","군함 출항!"},support={"↔","보급품 전달"}}
function M.new(parent,world,effects)
    local self=setmetatable({world=world,effects=effects,tracker=Tracker.new(),last={},fronts={},cursor=0,captureCount=0,queue={},feedUntil=0,stamps={}},M)
    local feed=UI.panel(parent,"ToyMoment");feed.ZIndex=12;feed.Visible=false;self.feed=feed
    self.symbol=UI.label(feed,"Symbol","",22,mint);self.symbol.TextXAlignment=Enum.TextXAlignment.Center
    self.title=UI.label(feed,"Title","",14,UI.colors.ink);self.title.Font=Enum.Font.BuilderSansBold
    self.detail=UI.label(feed,"Detail","",14,UI.colors.muted);self.detail.TextTruncate=Enum.TextTruncate.AtEnd;self.detail.TextWrapped=false
    self.scale=UI.make("UIScale",feed,{Scale=1})
    self.confetti=UI.make("Frame",parent,{Name="ResultConfetti",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=19,Visible=false,ClipsDescendants=true})
    self.nukes=NukeFx.new(effects.folder,world)
    world.feedback=self
    return self
end
function M:allow(kind,delay)
    local now=os.clock();if now-(self.last[kind] or -1e9)<delay then return false end
    self.last[kind]=now;return true
end
function M:position(tile)
    if tile==nil or not self.world.map then return nil end
    local m=self.world.map.meta
    if tile<0 or tile>=m.width*m.height then return nil end
    local x,y,z=G.toWorld(tile,m.width,m.height);return Vector3.new(x,y+.2,z)
end
function M:visible(tile)
    if tile==nil or not self.world.map then return false end
    local p=self.world:project(tile,.2);local size=self.world.parent.AbsoluteSize/UI.scale
    return p.X>12 and p.Y>48 and p.X<size.X-12 and p.Y<size.Y-100
end
function M:colors(owner,target)
    local c=Catalog.get(self.style).territory
    return {Badge.color(owner,Color3.fromRGB(table.unpack(c))),target and Badge.color(target) or cream,cream}
end
function M:moment(kind,name)
    local spec=messages[kind];if not spec then return end
    if Display.enqueue(self.queue,kind,name,os.clock())and(Display.noticePriority[kind]or 0)>(self.feedPriority or 0)then self.feedUntil=0 end
end
function M:connection(a,b,kind,tint)
    local source=self.factions and self.factions[a];local target=self.factions and self.factions[b]
    local start=source and self:position(source.labelTile);local finish=target and self:position(target.labelTile)
    if start and finish and(self:visible(source.labelTile)or self:visible(target.labelTile))then self.effects:connection(start,finish,tint,kind)end
end
function M:reset()
    self.floatEpoch=(self.floatEpoch or 0)+1;self.floats=0
    self.effects:clear();Audio.reset();table.clear(self.last);table.clear(self.queue)
    self.fronts={};self.captureCount=0;self.captureTile=nil;self.rank=nil;self.gained=0;self.gainTile=nil;self.feed.Visible=false;self.feedUntil=0;self.feedPriority=0;self.combo=0;self.lastPop=nil
    self.confetti:ClearAllChildren();self.confetti.Visible=false;self.celebrateUntil=nil
    self.world.cameraImpulse=nil
end
function M:outcome(won)
    self.feed:SetAttribute("Outcome",won and "victory" or "defeat")
    if won then self.effects:pose(game.Players.LocalPlayer.Character,"victory") end
    if self.effects.reduced or not won then return end
    self.confetti:ClearAllChildren();self.confetti.Visible=true;self.celebrateUntil=os.clock()+2.1
    local r=Random.new(763);local count=UIS.TouchEnabled and 14 or 26
    for i=1,count do
        local p=UI.make("Frame",self.confetti,{Name="PaperBrick",AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(r:NextInteger(5,9),r:NextInteger(9,15)),Position=UDim2.fromScale(i%2==0 and -.02 or 1.02,.62),Rotation=r:NextNumber(-25,25),BorderSizePixel=0,BackgroundColor3=({mint,cream,coral})[i%3+1]});UI.corner(p,2)
        Tween:Create(p,TweenInfo.new(r:NextNumber(1.3,1.9),Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.fromScale(r:NextNumber(.05,.95),r:NextNumber(.02,.4)),Rotation=r:NextNumber(-240,240),BackgroundTransparency=1}):Play()
    end
end
function M:concerns(owner,tile)
    if owner==1 then return true end
    local tileOwner=tile and self.world.owners and self.world.owners[tile]
    if tileOwner==1 then return true end
    if tile and ((self.lost and self.lost[tile])or(self.lostBefore and self.lostBefore[tile]))then return true end
    local f=self.factions and (self.factions[owner]or tileOwner and self.factions[tileOwner])
    return f~=nil and (f.allied==true or f.teammate==true)
end
function M:emit(e)
    local kind=e.kind;local pos=self:position(e.tile);local visible=pos and self:visible(e.tile)
    local tint=(kind=="incoming" or kind=="allianceEnded" or kind=="defeat") and coral or mint
    self.feed:SetAttribute("LastEvent",kind);self.feed:SetAttribute("Events_"..kind,(self.feed:GetAttribute("Events_"..kind) or 0)+1)
    if kind=="complete" or kind=="upgraded" then
        Audio.play(kind=="upgraded"and "upgrade"or "complete")
        if e.first then self:moment("firstCity","병력 상한이 늘었어요") else self:moment(kind,e.name) end
        if visible then self.effects:bricks(pos,self:colors(1),6,1.5,true,1);self.effects:ring(pos,e.first and UI.colors.gold or cream,3,1,"build");self.effects:stamp(pos,e.first and "첫 도시!" or kind=="complete" and "✓ 건설 완료" or "↑ 레벨 업",e.first and UI.colors.gold or cream) end
    elseif kind=="rocketWarning" then
        Audio.play(kind);self:buzz("explosion")
        if self:allow("warningCamera",3) then self.world:impulse(.13) end
    elseif kind=="incoming" then
        if e.threat=="assault" then
            cue("assault","rocketWarning");self:moment("assault",(e.name and e.name.." " or "").."병력 "..UI.troops(e.troops or 0));self:buzz("explosion")
            if self:allow("warningCamera",2) then self.world:impulse(.2) end
        elseif e.threat~="minor" then
            Audio.play(kind)
            if self:allow("warningCamera",3) then self.world:impulse(.13) end
        end
    elseif kind=="victory" or kind=="defeat" then
        Audio.play(kind);self:outcome(kind=="victory")
    elseif kind=="detonate" and pos then
        local p=self.world:project(e.tile,.2);local size=self.world.parent.AbsoluteSize/UI.scale
        local seen=p.X>-260 and p.Y>-260 and p.X<size.X+260 and p.Y<size.Y+260
        if seen then
            local inner=Units.magnitude(e.weapon or "AtomBomb")
            self.nukes:detonate(pos,e.weapon or "AtomBomb",e.radius or 30,inner,NukeSkins.get(self.loadouts and self.loadouts[e.owner],"impact"),self.effects.reduced)
            if e.weapon~="MIRVWarhead"then self:moment(kind,Units.names[e.weapon]or e.weapon or '')end
            local heavy=e.weapon=="HydrogenBomb"
            if self:allow("blastCamera",e.weapon=="MIRVWarhead"and .6 or .2)then self.world:impulse(heavy and .6 or e.weapon=="MIRVWarhead"and .15 or .35)end
        end
        if self:concerns(e.owner,e.tile)and self:allow("blastSound",.15)then Audio.play((e.weapon=="HydrogenBomb"or e.weapon=="MIRVWarhead")and "nuke"or kind,.8)
        elseif seen and self:allow("blastSound",.15)then Audio.play("distant",e.weapon=="HydrogenBomb"and 1 or .8)
        end
    elseif kind=="intercept" then
        local air=self.world.combined and self.world.combined:rocketPosition(e.unit)
        if visible then
            local at=air or pos+Vector3.yAxis*4
            local loadout=function(id)return self.loadouts and self.loadouts[id]end
            local mine,hit=e.owner==1,e.target==1
            local tone=mine and "mine" or hit and "hit" or self:concerns(e.owner,nil) and "ally" or "other"
            local ground=Vector3.new(at.X,pos.Y,at.Z)
            self.effects:ring(ground,mine and mint or hit and coral or cream,1.6,3,"intercept")
            require(script.Parent.InterceptFx).kill(self.world.folder,at,NukeSkins.get(loadout(e.owner),"impact"),NukeSkins.get(loadout(e.target),"projectile"),NukeSkins.get(loadout(e.target),"trail"),e.weapon,self.effects.reduced)
            require(script.Parent.InterceptMarker).show(self.world.folder,at,self.effects.reduced,tone)
            if hit then self:moment("intercepted",Units.names[e.weapon]or e.weapon or '')elseif tone~="other"then self:moment(kind,Units.names[e.weapon]or e.weapon or '')end
            if mine then Audio.play(kind,.7,1.08);task.delay(.12,function()Audio.play("confirm",.5,1.3)end)
            elseif hit then Audio.play(kind,.7,.8)
            elseif self:concerns(e.owner,e.tile)then Audio.play(kind,.6)end
        end
    elseif kind=="shell" then
        if visible then
            local style=Catalog.forSlot(e.owner==1 and self.cosmetics or nil,"impact")
            local colors={Color3.fromRGB(table.unpack(style.primary)),Color3.fromRGB(table.unpack(style.accent)),cream}
            self.effects:bricks(pos,colors,5,1.6,false,0)
            self.effects:ring(pos,colors[2],1.6,0,nil)
            if self:concerns(e.owner,e.tile)then Audio.play(kind,.6)end
        end
    elseif kind=="launch" then
        if e.owner==1 then Audio.play(kind,.7) end
        if visible then self.nukes:launch(pos,NukeSkins.get(self.loadouts and self.loadouts[e.owner],"trail"),self.effects.reduced)end
    elseif kind=="trainLost" then
        if visible then require(script.Parent.DestructionFx).train(self.world.folder,pos,self.effects.reduced)end
    elseif kind=="trade" then
        if e.owner==1 and self.onGold then self.onGold(e.gold)end
        if e.owner==1 and visible and self:allow("trade",2.5) then Audio.play("trade");self.effects:stamp(pos,"+"..UI.number(e.gold),cream) end
    elseif kind=="conquest" then
        if e.owner==1 then
            local f=self.factions and self.factions[e.target];local tile=f and f.labelTile;local at=tile and self:position(tile)
            if self.onGold then self.onGold(e.gold)end
            cue("conquest","complete",.75,1);self:moment("conquest",f and f.name or '')
            if at and self:visible(tile)then
                self.effects:stamp(at,"⚑",UI.colors.gold);self.effects:ring(at,UI.colors.gold,4,1)
                self.effects:bricks(at,{UI.colors.gold,cream,mint},8,2.2)
            end
            if self:allow("conquestCamera",1.5)then self.world:impulse(.1)end
        end
    elseif kind=="landing" or kind=="shipReady" then
        if e.owner==1 then Audio.play("complete");self:moment(kind,e.returning and "부대가 복귀했어요" or "새 작전이 시작돼요") end
        if visible then self.effects:ring(pos,mint,2.4);self.effects:bricks(pos,self:colors(e.owner),6,1.6) end
    elseif kind=="milestone" then
        local percent=math.floor(e.share*100+.5)
        if not self.obscured then Audio.play("milestone",.6)end;self:moment(kind,string.format("영토 %d%% 확보",percent))
        if visible then self.effects:ring(pos,cream,4);self.effects:bricks(pos,self:colors(1),10,2.2);self.effects:stamp(pos,string.format("★ %d%%!",percent),cream) end
        if self:allow("milestoneCamera",4) then self.world:impulse(.08) end
    elseif kind=="sortie" then
        if visible and (e.troops or 0)>0 then self:float(pos,'↑ '..UI.troops(e.troops),cream,'troops')end
    elseif kind=="tiles" then
        if not self.obscured then Audio.play("milestone",.5)end;self:moment(kind,string.format("%s칸 확보",UI.number(e.tiles)))
        if visible then self.effects:ring(pos,UI.colors.gold,3);self.effects:stamp(pos,string.format("★ %s칸",UI.number(e.tiles)),UI.colors.gold) end
    elseif kind=="betrayal" then
        cue("betrayal","allianceEnded",1,.8);self:moment(kind,(e.name or "").." 동맹을 깼어요");self:connection(1,e.owner,"allianceEnded",coral);self:buzz("collision")
        local f=self.factions and self.factions[e.owner];local at=f and f.labelTile and self:position(f.labelTile)
        if at and self:visible(f.labelTile)then self.effects:stamp(at,"⚠ 배신!",coral);self.effects:ring(at,coral,4,1);self.effects:flash(at,coral)end
        if self:allow("warningCamera",2) then self.world:impulse(.14) end
    elseif kind=="eliminated" then
        local f=self.factions and self.factions[e.owner]
        if f and (f.allied or f.teammate)then self:moment(kind,e.name)end
        local mine=f and (f.allied or f.teammate)
        if visible then self.effects:bricks(pos,self:colors(e.owner),12,2.4);self.effects:ring(pos,mine and coral or cream,3.2);if mine then self.effects:stamp(pos,"붕괴",coral)end end
    elseif kind=="support" then
        if e.target==1 and e.resource=="gold" and self.onGold then self.onGold(e.amount)end
        if e.owner==1 or e.target==1 then Audio.play("allied");self:moment(kind,(e.resource=="gold" and "골드 "..UI.number(e.amount) or "병력 "..UI.troops(e.amount)));self:connection(e.owner,e.target,kind,mint) end
    else
        Audio.play(kind);self:moment(kind,e.name)
        if kind=='allied'or kind=='allianceEnded'then self:connection(1,e.owner==1 and e.target or e.owner,kind,tint)end
        if visible and (kind=="allied" or kind=="start") then self.effects:ring(pos,tint,3);self.effects:stamp(pos,kind=="allied" and "↔ 동맹" or "작전 개시",tint) end
    end
end
function M:update(s,factions)
    if self.version~=s.version then self:reset();self.version=s.version end
    self.active=s.phase~="menu" and s.phase~="spawn";self.paused=s.paused or s.phase~="playing"
    self.style=s.style;self.cosmetics=s.cosmetics
    self.loadouts=require(script.Parent.CosmeticLoadouts).all(s)
    self.effects.roomId=s.roomId
    self.fronts=s.battlefronts or {};self.effects.folder:SetAttribute("FrontierCount",#self.fronts)
    for _,f in pairs(factions or {}) do f.combatState=nil end
    local own=s.player;if own then own.combatState=nil end
    for _,op in ipairs(s.operations or {}) do
        if op.retreating or op.retreated then continue end
        if own and (not own.combatState or op.direction=="incoming") then own.combatState=op.direction end
        local f=factions and factions[op.direction=="incoming" and op.owner or op.target]
        if f then f.combatState=op.direction=="incoming" and "attacking" or "defending" end
    end
    self.factions=table.clone(factions or {});self.factions[1]=s.player
    for _,e in ipairs(self.tracker:update(s)) do self:emit(e) end
    if s.phase=="menu" then self:reset() end
end
function M:capture(s,owners,revision)
    if not self.active or self.paused or s.owned or s.version~=self.version or s.baseRevision~=revision or (s.ownershipRevision or 0)<=revision then return end
    self.lostBefore=self.lost;self.lost={}
    for _,c in ipairs(s.captured or {}) do
        if owners[c[1]]==1 and c[2]~=1 then self.lost[c[1]]=true end
        if c[2]==1 and owners[c[1]]~=1 then
            self.captureCount+=1;self.gained=(self.gained or 0)+1
            if self:visible(c[1]) then self.captureTile=c[1];self.gainTile=c[1] end
        end
    end
end
function M:layout(w,h,obscured,board)
    self.obscured=obscured
    local phone=h<500;local width=phone and math.min(330,w-360)or math.min(520,w-24)
    local x=phone and 300 or math.floor((w-width)/2);local y=phone and 50 or 72
    if phone and width<220 then width=math.min(330,w-24);x=math.floor((w-width)/2)end
    UI.box(self.feed,x,y,width,44);self.feedBase=self.feed.Position
    local Style=require(script.Parent.HudStyle);Style.round(self.feed,8)
    if not self.toneBar then
        self.toneBar=UI.make('Frame',self.feed,{Name='Tone',BorderSizePixel=0,ZIndex=self.feed.ZIndex+1});Style.round(self.toneBar,2)
        self.edge=self.feed:FindFirstChildOfClass('UIStroke')
    end
    UI.box(self.toneBar,0,6,4,32)
    UI.box(self.symbol,12,7,30,30);UI.box(self.title,48,0,width-150,44);self.title.TextSize=15;self.title.TextWrapped=false;self.title.TextTruncate=Enum.TextTruncate.AtEnd
    UI.box(self.detail,width-108,0,98,44);self.detail.TextSize=13;self.detail.TextXAlignment=Enum.TextXAlignment.Right
end
local GOOD={conquest=true,rankUp=true,firstCity=true,tiles=true,milestone=true,complete=true,upgraded=true,allied=true,intercept=true,landing=true}
local ICON={complete='City',firstCity='City',upgraded='City',allied='Alliance',allianceEnded='Alliance',rankUp='Crown',conquest='Crown',milestone='Crown',tiles='Crown',
    intercept='SAMLauncher',intercepted='SAMLauncher',detonate='AtomBomb',betrayal='Traitor',assault='Sword',landing='Transport',shipReady='Warship',support='Gold'}
function M:paintNotice(kind)
    local tone=dangerKinds[kind]and coral or GOOD[kind]and UI.colors.good or UI.colors.ice
    if self.toneBar then self.toneBar.BackgroundColor3=tone end
    self.feed.BackgroundColor3=UI.colors.panel:Lerp(tone,.14);self.feed.BackgroundTransparency=.04
    if self.edge then self.edge.Color=tone;self.edge.Transparency=.55 end
    if self.noticeIcon then self.noticeIcon:Destroy();self.noticeIcon=nil end
    local key=ICON[kind]
    if key then
        local ok,icon=pcall(function()return require(script.Parent.HotbarIcons).create(self.feed,key,22,tone)end)
        if ok and icon then self.noticeIcon=icon;icon.Position=UDim2.fromOffset(16,11);icon.ZIndex=self.feed.ZIndex+1;self.symbol.Text=''end
    end
    self.symbol.TextColor3=tone;self.title.TextColor3=dangerKinds[kind]and coral or UI.colors.ink
    if not self.effects.reduced then
        local base=self.feedBase or self.feed.Position;self.feed.Position=base-UDim2.fromOffset(0,12)
        Tween:Create(self.feed,TweenInfo.new(.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=base}):Play()
        if dangerKinds[kind]and self.edge then self.edge.Transparency=0
            Tween:Create(self.edge,TweenInfo.new(.18,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,3,true),{Transparency=.8}):Play()
        end
    end
end
function M:step(dt)
    local started=os.clock();local now=started
    if self.celebrateUntil and (now>self.celebrateUntil or self.effects.reduced) then self.confetti:ClearAllChildren();self.confetti.Visible=false;self.celebrateUntil=nil end
    if not self.active then self.feed.Visible=false;return end
    if self.feedUntil<=now and #self.queue>0 then
        local e=table.remove(self.queue,1)
        if now-e.at<8 then
            local spec=messages[e.kind];self.symbol.Text=spec[1];self.title.Text=spec[2]
            local tone=goldKinds[e.kind]and UI.colors.gold or dangerKinds[e.kind]and coral or nil
            self.symbol.TextColor3=tone or mint;self.title.TextColor3=tone or UI.colors.ink;self.detail.Text=e.count>1 and string.format("%s 외 %d건",e.name or "지도를 눌러 작전을 시작하세요",e.count-1)or e.name or "지도를 눌러 작전을 시작하세요"
            self.feedUntil=now+(dangerKinds[e.kind]and 3.2 or 1.6+.8);self.feedPriority=e.priority;self.feed:SetAttribute('NoticePriority',e.priority)
            self:paintNotice(e.kind)
            self.detail.Text=e.count>1 and string.format('외 %d건',e.count-1)or ''
            self.title.Text=self.title.Text..(e.name and e.name~=''and ' '..e.name or '')
        end
    end
    self.feed.Visible=not self.obscured and now<self.feedUntil
    if self.paused then return end
    if self.captureCount>=3 and self:allow("capturePop",UIS.TouchEnabled and .6 or .45) then
        self.combo=(self.lastPop and now-self.lastPop<=1.6) and self.combo+1 or 1;self.lastPop=now
        if self.captureTile and self:visible(self.captureTile) then
            local pos=self:position(self.captureTile)
            self.effects:bricks(pos,self:colors(1),2,.8)
            Audio.play("pop",.8,1+math.min(self.combo,12)*.05)
            if self.combo==6 or self.combo==12 or self.combo%24==0 then
                local label=self.combo>=24 and "대륙 장악" or self.combo>=12 and "연속 점령" or "전선 돌파"
                self.effects:stamp(pos,string.format("%s x%d",label,self.combo),mint);self.effects:ring(pos,mint,2.2)
                Audio.play("combo",.9,1+math.min(self.combo,24)*.02)
            end
            self.feed:SetAttribute("CaptureBursts",(self.feed:GetAttribute("CaptureBursts") or 0)+1)
        end
        self.feed:SetAttribute("CaptureCombo",self.combo)
        self.captureCount=0;self.captureTile=nil
    end
    if (self.gained or 0)>=5 and self:allow("gainFloat",1.1)then
        if self.gainTile and self:visible(self.gainTile)then self:float(self:position(self.gainTile),string.format(L.text("+%s칸"),UI.number(self.gained)),mint)end
        self.gained=0;self.gainTile=nil
    end
    if not self.effects.reduced and #self.fronts>0 and self:allow("fronts",UIS.TouchEnabled and .3 or .2) then
        local shown=0
        for _=1,math.min(#self.fronts,24) do
            self.cursor=self.cursor%#self.fronts+1;local f=self.fronts[self.cursor]
            if self:visible(f.tile) then
                local p=self:position(f.tile);self.effects:bricks(p,self:colors(f.owner,f.target),3,1.4)
                shown+=1;if f.owner==1 or f.target==1 then Audio.play("block",.65)end
                if shown>=(UIS.TouchEnabled and 1 or 2) then break end
            end
        end
    end
    self.feed:SetAttribute("StepMs",(os.clock()-started)*1000)
end
function M:float(position,text,tint,iconKind)
    if not position or (self.floats or 0)>=3 then return end;self.floats=(self.floats or 0)+1
    local epoch=self.floatEpoch
    local anchor=Instance.new("Part");anchor.Name="ToyFloat";anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.Transparency=1;anchor.Size=Vector3.one*.05;anchor.Position=position;anchor.Parent=self.effects.folder
    local b=Instance.new("BillboardGui");b.Size=UDim2.fromOffset(110,24);b.StudsOffsetWorldSpace=Vector3.new(0,1.4,0);b.MaxDistance=400;b.LightInfluence=0;b.Parent=anchor
    local t=Instance.new("TextLabel");t.BackgroundTransparency=1;t.Size=UDim2.fromScale(1,1);t.Text=text;t.TextColor3=tint;t.TextStrokeColor3=UI.colors.bg;t.TextStrokeTransparency=.2;t.Font=Enum.Font.BuilderSansBold;t.TextSize=15;t.AutoLocalize=false;t:SetAttribute("LocalizationSkip",true);t.Parent=b
    if iconKind then local icon=require(script.Parent.HotbarIcons).create(b,'Soldier',16,tint);icon.Position=UDim2.fromOffset(0,4);t.Position=UDim2.fromOffset(18,0);t.Size=UDim2.new(1,-18,1,0)end
    if not self.effects.reduced then
        Tween:Create(b,TweenInfo.new(.9,Enum.EasingStyle.Quad),{StudsOffsetWorldSpace=Vector3.new(0,3,0)}):Play()
        Tween:Create(t,TweenInfo.new(.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In,0,false,.5),{TextTransparency=1,TextStrokeTransparency=1}):Play()
    end
    task.delay(.95,function()anchor:Destroy();if epoch==self.floatEpoch then self.floats=math.max(0,self.floats-1)end end)
end
function M:buzz(kind)
    if self.effects.reduced or self.world.cameraShake==false or not self:allow("haptic",.8) then return end
    pcall(function()
        local h=Instance.new("HapticEffect");h.Type=kind=="collision" and Enum.HapticEffectType.GameplayCollision or Enum.HapticEffectType.GameplayExplosion
        h.Parent=self.feed;h:Play();task.delay(1,function()h:Destroy()end)
    end)
end
function M:ranked(rank,total)
    if not self.active or self.paused or not rank then self.rank=rank;return end
    local before=self.rank;self.rank=rank
    if before and rank<before and (rank==1 or rank<=3 and before>3) and self:allow(rank==1 and "rankFirst" or "rankTop3",20) then
        if not self.obscured then cue("rankUp","milestone",1,rank==1 and 1.2 or 1.08)end;self:moment("rankUp",rank==1 and "1위로 올라섰어요" or string.format("%d위, 상위 3",rank))
        self:buzz("explosion")
    end
end
function M:result(parent,won)
    local header=UI.panel(parent,"ToyResultSeal");UI.box(header,0,0,parent.AbsoluteSize.X/UI.scale-12,72);header.Size=UDim2.new(1,-12,0,72)
    header.BackgroundColor3=won and Color3.fromRGB(54,226,208):Lerp(UI.colors.bg,.72) or UI.colors.raised
    local color=won and UI.colors.gold or UI.colors.muted
    local key=UI.make("Frame",header,{Name="MedalKey",Size=UDim2.fromOffset(48,48),Position=UDim2.fromOffset(12,12),BackgroundColor3=color,BorderSizePixel=0});UI.corner(key,3)
    local icon=UI.label(key,"Symbol",won and "★" or "+",30,UI.colors.bg);icon.Size=UDim2.fromScale(1,1);icon.TextXAlignment=Enum.TextXAlignment.Center
    local title=UI.label(header,"Title",won and "승리" or "작전 실패",20,color);UI.box(title,74,10,260,27);title.Size=UDim2.new(1,-84,0,27)
    local sub=UI.label(header,"Subtitle",won and "전 영토를 장악했어요." or "다음 작전을 준비하세요.",12,UI.colors.muted);UI.box(sub,74,39,260,22);sub.Size=UDim2.new(1,-84,0,22)
end
return M
