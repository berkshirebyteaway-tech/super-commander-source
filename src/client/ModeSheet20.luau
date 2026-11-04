local K=require(script.Parent.Kit20)
local Theme=require(script.Parent.Theme)
local Campaign=require(script.Parent.Parent.Core.CampaignRules)
local Step=require(script.Parent.TelemetryStep)
local Tween=game:GetService('TweenService')
local C=K.colors
local SHEET=Color3.fromRGB(15,21,29)
local M={};M.__index=M
M.MODES={'match','ranked','campaign','solo'}
function M.new(home)
    local l=home.lobby;local self=setmetatable({home=home,lobby=l,open=false,cards={}},M)
    self.frame=K.make('TextButton',l.frame,{Name='ModeSheet',Text='',AutoButtonColor=false,BackgroundColor3=Color3.fromRGB(3,6,10),BackgroundTransparency=.28,BorderSizePixel=0,Size=UDim2.fromScale(1,1),Visible=false,ZIndex=40,Active=true})
    self.frame.Activated:Connect(function()self:close('outside')end)
    return self
end
function M.ranked()return script.Parent.Parent:GetAttribute('LiveRanked1v1')==true end
function M.mode(l)
    local m=l.lobbyMode or 'match'
    if m=='ranked'and not M.ranked()then m='match'end
    return m
end
local function campaignLine(l)
    local p=l.account and l.account.progress or {}
    if require(script.Parent.Lobby20).campaignDone(p)then return '캠페인',nil end
    local cv=type(p.campaign)=='table'and p.campaign or {next=Campaign.stages[1].id}
    local st=Campaign.stage(cv.next)or Campaign.stages[1]
    return st.id..' '..st.name,st
end
function M.matchLine(l)
    local s=l.data;local q=s and s.queue
    local clock=function(n)local v=math.max(0,math.ceil(n));return string.format('%d:%02d',v//60,v%60)end
    if q and q.mode=='pvp'and not q.trophySolo then
        if q.phase=='transferring'then return '이동 중'end
        local left=q.remaining and math.max(0,q.remaining-(os.clock()-(l.queueUpdated or os.clock())))
        local n=q.count or 1
        if q.room and q.room.missing then return '-:--'end
        return left and string.format('%d명  %s',n,clock(left))or string.format('%d명',n)
    end
    for _,f in ipairs(l.deployment and l.deployment.fields or {})do if f.kind~='custom'and f.kind~='world'then
        local n=tonumber(f.count)or 0;if n<=0 then return ''end
        local left=f.remaining and math.max(0,f.remaining-(os.clock()-((l.deployment and l.deployment.updated)or os.clock())))
        return left and string.format('%d명  %s',n,clock(left))or string.format('%d명',n)
    end end
    return ''
end
function M.label(l,mode)
    mode=mode or M.mode(l)
    if mode=='ranked'then return '1대1 랭크'elseif mode=='campaign'then return '캠페인'elseif mode=='solo'then return '싱글플레이'end
    return '매칭'
end
local function card(self,s,key,big)
    local c={key=key,big=big}
    c.frame=K.button(s,'Mode_'..key,{kind='none',r=big and 16 or 12},function()self:pick(key)end)
    c.frame.face.BackgroundColor3=C.panel;c.frame.face.BackgroundTransparency=0;c.frame.baseFill=C.panel;c.frame.baseAlpha=0
    c.frame.faceStroke.Enabled=true;c.frame.faceStroke.Color=C.line;c.frame.faceStroke.Thickness=1;c.frame.faceStroke.Transparency=0;c.frame.baseStroke=C.line
    c.frame.button.ZIndex=42;c.frame.face.ZIndex=42
    c.title=K.text(c.frame.face,'Title','',big and 56 or 17,C.ink,big and 900 or 700);c.title.ZIndex=45
    c.sub=K.text(c.frame.face,'Sub','',big and 26 or 13,C.muted,600);c.sub.ZIndex=45
    self.cards[key]=c
    return c
end
function M:build(fmt)
    if self.built==fmt then return end
    if self.sheet then self.sheet:Destroy()end
    self.built=fmt;self.cards={}
    local s=K.make('Frame',self.frame,{Name='Sheet',BackgroundColor3=SHEET,BorderSizePixel=0,Active=true,ZIndex=41});K.round(s,16);K.stroke(s,C.line,1,0,true);self.sheet=s
    K.make('TextButton',s,{Name='Catch',Text='',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),AutoButtonColor=false,ZIndex=41})
    self.back=K.button(s,'Back',{kind='plain',icon='back',iconSize=18},function()self:close('back')end)
    self.back.faceStroke.Enabled=false;self.back.iconColorFixed=true;self.back.iconImage.ImageColor3=C.muted
    self.back.button.ZIndex=43;self.back.face.ZIndex=43;self.back.iconImage.ZIndex=44
    card(self,s,'match',true);card(self,s,'ranked');card(self,s,'campaign');card(self,s,'solo');card(self,s,'custom')
end
local function thumb(c,kind,value,w,h,r)
    local key=kind..':'..tostring(value)..':'..w..'x'..h
    if c.thumbKey==key then return end;c.thumbKey=key
    if c.thumb then c.thumb:Destroy()end
    if kind=='map'then c.thumb=K.map(c.frame.face,'Thumb',value,w,h,r)
    else
        c.thumb=K.make('Frame',c.frame.face,{Name='Thumb',BackgroundColor3=Color3.fromRGB(20,24,30),BorderSizePixel=0,Size=UDim2.fromOffset(w,h)});K.round(c.thumb,r)
        local is=math.floor(math.min(w,h)*.56);local ic=K.icon(c.thumb,value,is,kind=='gold'and C.gold or C.muted,'Icon');K.box(ic,(w-is)/2,(h-is)/2,is,is);ic.ZIndex=44
    end
    c.thumb.ZIndex=43;for _,o in ipairs(c.thumb:GetDescendants())do if o:IsA('GuiObject')and o.ZIndex<44 then o.ZIndex=44 end end
end
function M:refresh()
    if not self.built then return end
    local l=self.lobby;local mode=M.mode(l)
    local cs=self.cards
    cs.match.title.Text='매칭';cs.match.sub.Text=M.matchLine(l)
    cs.ranked.title.Text='1대1 랭크'
    local tr=l.data and l.data.ranked and l.data.ranked.trophySolo
    cs.ranked.sub.Text=tr and tr.t and Theme.commas(tr.t)or '';cs.ranked.sub.TextColor3=C.gold
    local line=campaignLine(l);cs.campaign.title.Text=line;cs.campaign.sub.Text='캠페인'
    if line=='캠페인'then cs.campaign.sub.Text='모든 작전 완료'end
    cs.solo.title.Text='싱글플레이';cs.solo.sub.Text=''
    local rooms=0;for _,f in ipairs(l.deployment and l.deployment.fields or {})do if f.kind=='custom'then rooms+=1 end end
    cs.custom.title.Text='커스텀';cs.custom.sub.Text=rooms>0 and string.format('방 %d개',rooms)or ''
    for key,c in pairs(cs)do local on=key==mode
        c.frame.faceStroke.Color=on and C.accent or C.line;c.frame.faceStroke.Thickness=on and 2 or 1;c.frame.baseStroke=c.frame.faceStroke.Color
        c.frame:setEnabled(not l.busy,true)
    end
end
function M:pick(key)
    local l=self.lobby;require(script.Parent.ToyAudio).play('click')
    Step.step('lobby','modePick',{item=key})
    if key=='custom'then self:close('custom');l.deployment:open('custom');l:layout();return end
    if key=='ranked'and not M.ranked()then return end
    l.lobbyMode=key;self:close('pick')
    require(script.Parent.Lobby20).start(self.home,key)
end
function M:show()
    if self.open then return end;self.open=true;self.frame.Visible=true;self.entering=true
    Step.step('lobby','modeOpen',{item=M.mode(self.lobby)})
    self.lobby:layout()
end
function M:close(why)
    if not self.open then return end;self.open=false
    if why~='pick'and why~='custom'then Step.step('lobby','modeClose',{result=why or 'x'})end
    local s=self.sheet
    if s and not K.reduced then
        local portrait=self.built=='pt'
        K.leave(s,{dx=portrait and 0 or 24,dy=portrait and 24 or 0,t=portrait and .10 or .12,noFade=true},function()if not self.open then self.frame.Visible=false end end)
        Tween:Create(self.frame,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{BackgroundTransparency=1}):Play()
    else self.frame.Visible=false end
    self.lobby:layout()
end
local function placeSmall(c,x,y,w,h,fmt)
    c.frame:place(x,y,w,h)
    local pad=fmt=='pc'and 10 or 8;local th=h-pad*2;local tw=math.min(math.floor(w*.42),math.floor(th*1.5))
    local key=c.key
    if key=='match'then return end
    if key=='ranked'then thumb(c,'gold','crestLaurel',tw,th,8)
    elseif key=='custom'then thumb(c,'icon','custom',tw,th,8)
    elseif key=='campaign'then local _,st=campaignLine(c.lobby);thumb(c,'map',st and st.map or 'world',tw,th,8)
    else thumb(c,'map','world',tw,th,8)end
    K.box(c.thumb,pad,pad,tw,th)
    local fs=fmt=='pc'and 17 or fmt=='ph'and 14 or 15;local ss=fmt=='pc'and 13 or 12
    c.title.TextSize=fs;c.sub.TextSize=ss
    local tx=pad+tw+(fmt=='pc'and 16 or 10);local hasSub=c.sub.Text~=''
    local block=hasSub and fs+4+ss+2 or fs+4;local ty=math.floor((h-block)/2)
    K.box(c.title,tx,ty,w-tx-pad,fs+4);K.fit(c.title,w-tx-pad,fs,math.max(11,fs-4))
    c.sub.Visible=hasSub;if hasSub then K.box(c.sub,tx,ty+fs+6,w-tx-pad,ss+2)end
end
function M:layout(w,h,portrait,short)
    if not self.open then if not(self.sheet and self.sheet:GetAttribute('Moving20')=='out')then self.frame.Visible=false end;return end
    local fmt=portrait and 'pt'or short and 'ph'or 'pc'
    self:build(fmt);self.frame.Visible=true
    self.frame.ZIndex=fmt=='pt'and 28 or 40
    for _,c in pairs(self.cards)do c.lobby=self.lobby end
    self:refresh()
    local s=self.sheet;local sx,sy,sw,sh,pad
    if fmt=='pc'then sw,sh=math.min(1080,w-48),math.min(600,h-120);sx,sy=(w-sw)/2,(h-sh)/2+24;pad=24
    elseif fmt=='ph'then sw,sh=w-24,h-58;sx,sy=12,50;pad=12
    else sx,sy,sw=0,104,w;sh=h-58-sy;pad=12 end
    K.box(s,sx,sy,sw,fmt=='pt'and sh+16 or sh)
    local bs=fmt=='pc'and 40 or 34
    self.back:place(pad,pad-(fmt=='pc'and 4 or 2),bs,bs)
    local top=pad+bs+(fmt=='pc'and 12 or 8)
    local m=self.cards.match
    local list={}
    for _,k in ipairs({'ranked','campaign','solo','custom'})do if k~='ranked'or M.ranked()then table.insert(list,self.cards[k])end end
    self.cards.ranked.frame.button.Visible=M.ranked()
    local gap=fmt=='pc'and 12 or 8
    local bx,by,bw,bh
    if fmt=='pt'then
        bx,by,bw=pad,top,sw-pad*2;local rows=math.ceil(#list/2);local ch=64
        bh=math.max(160,sh-top-pad-rows*(ch+gap))
        local cw=math.floor((bw-gap)/2)
        for i,c in ipairs(list)do local col=(i-1)%2;local row=(i-1)//2
            local x=bx+col*(cw+gap);local wdt=(i==#list and col==0)and bw or cw
            placeSmall(c,x,by+bh+gap+row*(ch+gap),wdt,ch,fmt)end
    else
        local rw=fmt=='pc'and math.floor((sw-pad*2-gap)*.36)or math.floor((sw-pad*2-gap)*.46)
        bx,by,bw,bh=pad,top,sw-pad*2-gap-rw,sh-top-pad
        local rx=bx+bw+gap
        if fmt=='pc'then local ch=math.floor((bh-gap*(#list-1))/#list)
            for i,c in ipairs(list)do placeSmall(c,rx,by+(i-1)*(ch+gap),rw,ch,fmt)end
        else local cw=math.floor((rw-gap)/2);local rows=math.ceil(#list/2);local ch=math.floor((bh-gap*(rows-1))/rows)
            for i,c in ipairs(list)do local col=(i-1)%2;local row=(i-1)//2;local wdt=(i==#list and col==0)and rw or cw
                placeSmall(c,rx+col*(cw+gap),by+row*(ch+gap),wdt,ch,fmt)end
        end
    end
    m.frame:place(bx,by,bw,bh)
    local mp=fmt=='pc'and 32 or fmt=='ph'and 16 or 18
    thumb(m,'map','world',bw-2,bh-2,15);K.box(m.thumb,1,1,bw-2,bh-2)
    if not m.fade then m.fade=K.fadeBox(m.frame.face,'Fade',Color3.fromRGB(8,10,14),.85,.15,15,.55,.7);m.fade.ZIndex=44 end
    K.box(m.fade,1,1,bw-2,bh-2)
    local ts=fmt=='pc'and 56 or fmt=='ph'and 30 or 36;local ss=fmt=='pc'and 26 or fmt=='ph'and 16 or 18
    m.title.TextSize=ts;m.sub.TextSize=ss
    local hasSub=m.sub.Text~=''
    local ty=bh-mp-(hasSub and ss+8 or 0)-ts-6
    K.box(m.title,mp,ty,bw-mp*2,ts+6);m.sub.Visible=hasSub;if hasSub then K.box(m.sub,mp,ty+ts+8,bw-mp*2,ss+4)end
    if self.entering then self.entering=false
        self.frame.BackgroundTransparency=1;Tween:Create(self.frame,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=.28}):Play()
        s:SetAttribute('Shown20',false);K.rehome(s)
        if fmt=='pt'then K.appear(s,{dy=24,t=.16,noFade=true})else K.appear(s,{dx=24,t=.18,noFade=true})end
    end
end
return M
