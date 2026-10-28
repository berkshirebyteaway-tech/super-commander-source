local UI=require(script.Parent.Theme)
local Style=require(script.Parent.HudStyle)
local Audio=require(script.Parent.ToyAudio)
local Speed=require(script.Parent.Parent.Core.GameSpeed)
local Tween=game:GetService('TweenService')
local C=UI.colors
local M={};M.__index=M
M.WIDTH=126
local function clock(seconds)seconds=math.max(0,math.floor(seconds));return string.format('%02d:%02d',math.floor(seconds/60),seconds%60)end
local function share(v)v=(v or 0)*100;return string.format(v>=10 and '%.0f%%'or '%.1f%%',v)end
local function text(parent,name,size,color,align)
    local l=UI.label(parent,name,'',size,color);l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd;l.ZIndex=12
    if align then l.TextXAlignment=align end;return l
end
function M.new(parent,callbacks)
    local self=setmetatable({callbacks=callbacks or {}},M)
    local f=UI.panel(parent,'MatchStatus');f.ZIndex=11;f.Visible=false;f.BackgroundTransparency=.08;self.frame=f
    self.time=text(f,'Clock',18,C.ink,Enum.TextXAlignment.Center);UI.display(self.time,true)
    self.mode=text(f,'Mode',11,C.muted,Enum.TextXAlignment.Center)
    self.heads=UI.panel(parent,'HeadsUp');self.heads.ZIndex=14;self.heads.Visible=false;self.heads.BackgroundColor3=C.bg;self.heads.BackgroundTransparency=.1
    self.headsText=text(self.heads,'Message',15,C.ink,Enum.TextXAlignment.Center);self.headsText.Font=Enum.Font.BuilderSansBold;self.headsText.ZIndex=15
    self.big=UI.label(parent,'FinalCountdown','',72,C.gold);self.big.TextXAlignment=Enum.TextXAlignment.Center;self.big.TextWrapped=false
    self.big.Font=Enum.Font.BuilderSansBold;self.big.ZIndex=16;self.big.Visible=false;self.big.TextStrokeTransparency=.35
    self.bigScale=UI.make('UIScale',self.big,{Scale=1})
    self.speedPill=UI.button(parent,'SpeedPill','×1',function()self.speedOpen=not self.speedOpen;self:layout(self.w,self.h,self.shown,self.compact)end)
    self.speedPill.Visible=false;self.speedPill.ZIndex=12;self.speedPill.TextSize=12
    self.speedOptions={}
    for i,v in ipairs({{.5,'×0.5'},{1,'×1'},{2,'×2'},{4,'최대'}})do
        local b=UI.button(parent,'Speed_'..i,v[2],function()self.speedOpen=false;if self.callbacks.speed then self.callbacks.speed(v[1])end;self:layout(self.w,self.h,self.shown,self.compact)end)
        b.Visible=false;b.ZIndex=12;b.TextSize=12;b:SetAttribute('Speed',v[1]);self.speedOptions[i]=b
    end
    return self
end
function M:update(state)
    self.state=state
    if state then
        local ladder=state.ranked=='2v2'and '랭크 2대2'or state.ranked=='1v1'and '랭크 1대1'or state.ranked=='ffa'and '랭크 개인전'or nil
        local cw=type(state.clanwar)=='table'and state.clanwar or {size=2,count=2}
        local war=state.clanwar and ((cw.count or 2)>2 and string.format('클랜전 %d파전 %d인',cw.count,cw.size or 2)or string.format('클랜전 %d대%d',cw.size or 2,cw.size or 2))
        local mode=war or state.queueMode=='custom'and '커스텀'or (state.ranked or state.queueMode=='ranked')and (ladder or '랭크')or state.multiplayer and '공식 전장'or '혼자 하기'
        local difficulty=not(state.clanwar or state.ranked or state.queueMode=='ranked')and require(script.Parent.Parent.Core.MatchOptions).difficultyLabels[(state.settings or {}).difficulty]or ''
        self.mode.Text=self.lastMinute and self.mode.Text or require(script.Parent.Localization).text(mode)..(difficulty~=''and ' '..require(script.Parent.Localization).text(difficulty)or '')
    end
    if state and self.speedShown~=state.speed then self.speedShown=state.speed;local v=state.speed or 1
        self.speedPill.Text=v>=4 and '최대'or ('×'..v);if self.speedCap then self.speedCap.Text=self.speedPill.Text end
        for _,b in ipairs(self.speedOptions)do local on=b:GetAttribute('Speed')==v;b.BackgroundColor3=on and C.accent or C.raised;b.TextColor3=on and C.bg or C.ink end
    end
    local playing=state~=nil and state.phase=='playing'and state.tick~=nil
    if not playing and self.countShown and self.countShown<=2 and state and (state.phase=='won'or state.phase=='lost')then
        self.countShown=nil;self:flash('시간 종료',C.ink,1.8)
        Audio.play(Audio.has and Audio.has('timeUp')and 'timeUp'or 'stinger',.9)
    end
    self.active=playing;if not playing then self.heads.Visible=false;return end
    if self.match~=state.version then self.match=state.version;self.warned=false;self.nearWin={};self.overtimeAt=nil;self.headsUntil=nil end
    local settings=state.settings or {};local pace=Speed.pace(state);Speed.shown=pace;local seconds=(state.tick or 0)/pace
    local limit=settings.maxTimerValue
    self.remaining=limit and limit*60-seconds or nil
    self.time.Text=clock(self.remaining or seconds)
    self.lastMinute=self.remaining~=nil and self.remaining<=60
    local final=self.remaining~=nil and self.remaining>0 and self.remaining<=10 and not state.paused
    local n=final and math.ceil(self.remaining)or nil
    if n~=self.countShown then
        self.countShown=n
        if n then self:flash(tostring(n),n<=3 and C.danger or C.gold,.95);Audio.play('countdown',1,n<=3 and 1.3 or 1)end
    end
    if self.lastMinute and not self.warned and self.remaining>0 then
        self.warned=true;if self.callbacks.notify then self.callbacks.notify('1분 뒤 경기가 끝나요. 영토가 가장 넓은 쪽이 승리',true)end
    elseif self.remaining and self.remaining>60 then self.warned=false end
    if not self.lastMinute then self.time.TextColor3=state.paused and C.muted or C.ink end
    local teams,myTeam={},state.player and state.player.team
    for _,f in ipairs(state.factions or {})do if f.team~=nil and not f.eliminated and (f.share or 0)>0 then
        local t=teams[f.team];if not t then t={team=f.team,share=0};teams[f.team]=t end;t.share+=f.share
    end end
    local list={};for _,t in pairs(teams)do table.insert(list,t)end
    table.sort(list,function(a,b)if (a.team==myTeam)~=(b.team==myTeam)then return a.team==myTeam end;return a.share>b.share end)
    local threshold=(state.winThreshold or 80)/100
    self.nearWin=self.nearWin or {};local near=threshold*.7
    local function announce(key,mine,name,value)
        if self.nearWin[key]then return end;self.nearWin[key]=true
        local text=mine and string.format('승리가 가까워요. 영토 %s / 승리 %s',share(value),share(threshold))
            or string.format('%s, 승리에 가까워요 (영토 %s / 승리 %s)',name,share(value),share(threshold))
        self:headsUp(text,5,mine and C.gold or C.danger)
        if self.callbacks.notify then self.callbacks.notify(text,not mine)end
    end
    if #list>=2 then for _,t in ipairs(list)do if t.share>=near then announce('team'..tostring(t.team),t.team==myTeam,'상대 팀',t.share)end end
    else for _,f in ipairs(state.factions or {})do if not f.eliminated and (f.share or 0)>=near then announce(f.id,f.id==1,f.name,f.share)end end end
    local overtime=settings.overtime and settings.overtime.enabled and threshold<.8
    if overtime and not self.overtimeAt then self.overtimeAt=state.tick;self:headsUp('연장전  승리 기준 매분 -2%p',5)end
    local immunity=settings.spawnImmunityDuration or 50
    self.peace=immunity>50 and state.tick<immunity and (immunity-state.tick)/pace or nil
    self.traitorLeft=nil
    for _,f in ipairs(state.factions or {})do if f.id==1 and f.traitor and f.traitorUntil then self.traitorLeft=(f.traitorUntil-state.tick)/pace end end
    if not(self.traitorLeft and self.traitorLeft>0)then self.traitorLeft=nil end
    if state.paused and state.multiplayer then self.headsText.Text='방장이 경기를 일시정지했어요';self.headsText.TextColor3=C.gold;self.headsFixed=true
    elseif self.peace then self.headsText.Text=(state.multiplayer and '평화 시간, 지휘관끼리 공격 금지  'or '평화 시간, 핵 발사 금지  ')..clock(self.peace);self.headsText.TextColor3=C.gold;self.headsFixed=true
    elseif self.traitorLeft then self.headsText.Text='배신자, 방어 약화  '..clock(self.traitorLeft);self.headsText.TextColor3=C.danger;self.headsFixed=true
    elseif state.doomsday then
        local required=state.doomsday.required or 0;local owned=state.player and state.player.tiles or 0
        self.headsText.Text=string.format('종말 시계  필요 %s칸  내 영토 %s칸',UI.number(required),UI.number(owned))
        self.headsText.TextColor3=owned<required and C.danger or C.muted;self.headsFixed=true
    else self.headsFixed=false end
end
function M:flash(text,color,seconds)
    local token=(self.bigToken or 0)+1;self.bigToken=token
    self.big.Text=text;self.big.TextColor3=color;self.big.TextSize=#text>3 and 54 or 72;self.big.Visible=true
    if not self.reduced then self.bigScale.Scale=1.35;Tween:Create(self.bigScale,TweenInfo.new(.25,Enum.EasingStyle.Back),{Scale=1}):Play()end
    task.delay(seconds,function()if self.bigToken==token then self.big.Visible=false end end)
end
function M:headsUp(message,seconds,color)
    self.headsText.Text=message;self.headsText.TextColor3=color or C.gold;self.headsUntil=os.clock()+(seconds or 4)
end
function M:layout20(w,h,show,compact)
    local K=require(script.Parent.Kit20)
    self.shown=show==true;self.frame.Visible=self.shown and self.active==true
    local touch=require(script.Parent.InputMode).touch()
    local pc=not touch or require(script.Parent.Parent.Core.InterfacePlacement).tablet(w,h,touch)
    local portrait=touch and w<h
    local inset=0;pcall(function()inset=game:GetService('GuiService'):GetGuiInset().Y/(UI.scale or 1)end)
    local s=self.state;local solo=s~=nil and not s.multiplayer and self.active==true and self.shown
    local fh=pc and 48 or 28;local ts=pc and 26 or 15
    local chipW,chipH=pc and 27 or 21,pc and 26 or 18
    local cw=pc and(solo and 130 or 91)or(solo and 79 or 53)
    local y=math.max(4,math.floor((pc and 58 or portrait and 58 or 50)-inset))
    local f=self.frame;K.box(f,12,y,cw,fh);K.round(f,pc and 10 or 8)
    f.BackgroundColor3=Color3.fromRGB(12,17,24);f.BackgroundTransparency=.14
    self.edge=self.edge or f:FindFirstChildOfClass('UIStroke')
    if self.edge and not self.lastMinute then self.edge.Color=K.colors.line;self.edge.Transparency=.1;self.edge.Thickness=1 end
    self.mode.Visible=false
    local tx=pc and 15 or 9;if K.fonts.num then self.time.FontFace=K.fonts.num end;self.time.TextSize=ts
    self.time.TextXAlignment=Enum.TextXAlignment.Left;K.box(self.time,tx,0,cw-tx,fh)
    local chip=self.chip20 or K.make('Frame',f,{Name='Speed20',BackgroundColor3=K.colors.raised,BorderSizePixel=0,ZIndex=13});self.chip20=chip;K.round(chip,4)
    local ctext=self.chipText20 or K.num(chip,'Text','×1',pc and 13 or 11,K.colors.muted,Enum.TextXAlignment.Center);self.chipText20=ctext;ctext.Size=UDim2.fromScale(1,1);ctext.ZIndex=14
    chip.Visible=solo==true
    local chipX=pc and 88 or 50;K.box(chip,chipX,math.floor((fh-chipH)/2),chipW,chipH);ctext.TextSize=pc and 13 or 11
    local speed=s and s.speed or 1;ctext.Text=speed>=4 and '최대'or ('×'..speed);if speed>=4 then K.box(chip,chipX,math.floor((fh-chipH)/2),pc and 36 or 28,chipH)end
    local hit=pc and 44 or 36
    self.speedPill.Visible=solo==true;self.speedPill.Text='';self.speedPill.BackgroundTransparency=1;self.speedPill.ZIndex=15
    UI.box(self.speedPill,12+chipX+chipW/2-hit/2,y+fh/2-hit/2,hit,hit)
    if self.speedFace then self.speedFace.Visible=false end
    local by=y+fh+6
    for i,b in ipairs(self.speedOptions)do
        b.Visible=solo==true and self.speedOpen==true
        local on=b:GetAttribute('Speed')==speed;b.BackgroundColor3=on and K.colors.ink or K.colors.raised;b.TextColor3=on and K.colors.bg or K.colors.ink;b.TextSize=13;K.round(b,8)
        local bw,bh=pc and 52 or 48,pc and 32 or 36
        UI.box(b,12+(i-1)*(bw+6),by,bw,bh)
    end
    local hw=math.min(420,w-32);K.round(self.heads,10);self.heads.BackgroundColor3=Color3.fromRGB(12,17,24);self.heads.BackgroundTransparency=.14
    UI.box(self.heads,(w-hw)/2,compact and math.max(124,math.floor(h*.3))or math.max(184,math.floor(h*.24)),hw,36);UI.box(self.headsText,10,0,hw-20,36)
    UI.box(self.big,(w-360)/2,math.floor(h*.38)-45,360,90);if K.fonts.num then self.big.FontFace=K.fonts.num end
end
function M:layout(w,h,show,compact)
    self.w,self.h,self.compact=w,h,compact
    if require(script.Parent.Hud20).ENABLED then return self:layout20(w,h,show,compact)end
    self.shown=show==true;self.frame.Visible=self.shown and self.active==true
    local touch=require(script.Parent.InputMode).touch()
    local phone=touch and h<500 and w>h and w>=560;self.phone=phone
    Style.round(self.frame,phone and 10 or 8);self.frame.BackgroundColor3=Style.colors.panel;self.frame.BackgroundTransparency=.08
    self.edge=self.edge or self.frame:FindFirstChildOfClass('UIStroke')
    local s0=self.state;local solo0=s0~=nil and not s0.multiplayer
    local tall=touch and not phone and w<h and w<600
    local cw=phone and (solo0 and 118 or 76)or tall and 112 or M.WIDTH
    if phone then
        UI.box(self.frame,8,8,cw,36);UI.box(self.time,8,0,62,36);self.time.TextSize=19;self.time.TextXAlignment=Enum.TextXAlignment.Left;self.mode.Visible=false
    elseif tall then
        UI.box(self.frame,12,8,cw,48);UI.box(self.time,6,2,cw-12,26);self.time.TextSize=22;self.time.TextXAlignment=Enum.TextXAlignment.Center
        self.mode.Visible=true;UI.box(self.mode,4,28,cw-8,16);self.mode.TextSize=11
    else
        UI.box(self.frame,12,8,cw,62);UI.box(self.time,6,4,cw-12,32);self.time.TextSize=26;self.time.TextXAlignment=Enum.TextXAlignment.Center
        self.mode.Visible=true;UI.box(self.mode,4,38,cw-8,18);self.mode.TextSize=13
    end
    local hw=math.min(420,w-32)
    UI.box(self.heads,(w-hw)/2,compact and math.max(124,math.floor(h*.3))or math.max(184,math.floor(h*.24)),hw,36);UI.box(self.headsText,10,0,hw-20,36)
    UI.box(self.big,(w-360)/2,math.floor(h*.38)-45,360,90)
    local s=self.state;local solo=s~=nil and not s.multiplayer and self.active==true and self.shown
    local ph=touch and 48 or 24;local pw=touch and 52 or 44;local py=8+62+6;local px=12
    if phone then ph,pw,py,px=48,48,2,8+118-48 end
    local portrait=touch and not phone and w<h and w<600
    if portrait then ph,pw,py,px=48,52,8,12+cw+6 end
    local speed=s and s.speed or 1
    self.speedPill.Visible=solo==true;self.speedPill.Text=speed>=4 and '최대'or ('×'..speed)
    UI.box(self.speedPill,px,py,pw,ph);self.speedPill.TextSize=13
    local face=self.speedFace or UI.make('Frame',self.speedPill,{Name='Face',BackgroundColor3=Style.colors.chip,BorderSizePixel=0,ZIndex=11,Active=false});self.speedFace=face
    self.speedPill.BackgroundTransparency=1;Style.round(face,phone and 8 or 6);Style.line(face,Style.colors.line,1)
    local fh=portrait and ph or phone and 26 or 24;UI.box(face,phone and 3 or 0,(ph-fh)/2,pw-(phone and 6 or 0),fh)
    face.BackgroundColor3=portrait and Style.colors.panel or Style.colors.chip;face.BackgroundTransparency=portrait and .08 or 0;if portrait then Style.round(face,8)end
    local cap=self.speedCap or UI.label(face,'Caption','',13,C.ink);self.speedCap=cap;cap.Size=UDim2.fromScale(1,1);cap.Position=UDim2.new();cap.TextXAlignment=Enum.TextXAlignment.Center
    cap.Font=Enum.Font.BuilderSansBold;cap.TextSize=portrait and 17 or 13;cap.ZIndex=13;cap:SetAttribute('LocalizationSkip',true);cap.Text=self.speedPill.Text;self.speedPill.TextTransparency=1
    for i,b in ipairs(self.speedOptions)do
        b.Visible=solo==true and self.speedOpen==true
        local on=b:GetAttribute('Speed')==speed;b.BackgroundColor3=on and C.ink or Style.colors.chip;b.TextColor3=on and C.bg or C.ink;b.TextSize=13;Style.round(b,6)
        if portrait then UI.box(b,12+(i-1)*(52+6),py+ph+6,52,48)else UI.box(b,(phone and 8+118 or 12+pw)+6+(i-1)*(pw+4),py,pw,ph)end
    end
end
function M:step(hidden,covered)
    self.frame.Visible=self.shown==true and self.active==true and not hidden
    local solo=self.frame.Visible and self.state~=nil and not self.state.multiplayer
    if self.speedPill.Visible~=solo then self.speedPill.Visible=solo;for _,b in ipairs(self.speedOptions)do b.Visible=solo and self.speedOpen==true end end
    local last=self.lastMinute and self.active
    if last then
        if require(script.Parent.Hud20).ENABLED then self.time.TextColor3=C.gold
        else local pulse=(math.sin(os.clock()*4)+1)/2;self.time.TextColor3=C.gold:Lerp(C.ink,pulse*.25)end
    end
    if self.edge and self.goldEdge~=last then
        self.goldEdge=last;self.edge.Color=last and C.gold or Style.colors.line;self.edge.Transparency=last and 0 or .35;self.edge.Thickness=last and 1.5 or 1
    end
    if last and not self.phone then self.mode.Text=require(script.Parent.Localization).text('1분 남음');self.mode.TextColor3=C.gold
    elseif self.mode.TextColor3==C.gold then self.mode.TextColor3=C.muted end
    local timed=self.headsUntil~=nil and os.clock()<self.headsUntil
    self.heads.Visible=self.active==true and not hidden and (self.headsFixed or timed)==true
end
return M
