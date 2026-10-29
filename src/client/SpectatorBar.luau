local UI=require(script.Parent.Theme)
local Model=require(script.Parent.Parent.Core.ResultPresentation)
local L=require(script.Parent.Localization)
local M={};M.__index=M
local function v2()local ok,H=pcall(require,script.Parent.Hud20);return ok and type(H)=='table'and H.ENABLED==true end
function M.new(parent,callbacks)
    local self=setmetatable({callbacks=callbacks},M)
    self.frame=UI.panel(parent,'SpectatorBar');self.frame.ZIndex=23;self.frame.Visible=false
    self.title=UI.label(self.frame,'Title','관전',14,UI.colors.ice)
    self.name=UI.label(self.frame,'Target','',16);self.name.TextWrapped=false;self.name.TextTruncate=Enum.TextTruncate.AtEnd;self.name:SetAttribute('LocalizationSkip',true)
    self.stats=UI.label(self.frame,'Stats','',14,UI.colors.muted)
    self.previous=UI.button(self.frame,'Previous','‹',function()self:select(-1)end)
    self.next=UI.button(self.frame,'Next','›',function()self:select(1)end)
    self.result=UI.button(self.frame,'Result','결과',function()if self.observer then callbacks.leave()else callbacks.result()end end)
    self.speed=UI.button(self.frame,'Speed','×1',function()
        local r=self.observer and self.observer.replay;if not r then return end
        local nextSpeed=({[1]=2,[2]=4,[4]=1})[r.speed]or 1;self.speed.Text=string.format('×%d',nextSpeed);callbacks.speed(nextSpeed)
    end);self.speed.Visible=false
    return self
end
function M:select(direction)
    self.dir20=direction
    if self.observer then
        local f=Model.spectatorTarget(self.list or {},1,direction)
        if f and f.id~=1 then self.name.Text=L.nation(f);self.callbacks.watch(f.matchId)end
        return
    end
    local f=Model.spectatorTarget(self.list or {},self.targetId,direction)
    self.targetId=f and f.id or nil;self:refresh(true)
end
function M:refresh(force)
    local previous=self.targetId
    local f=Model.spectatorTarget(self.list or {},self.observer and 1 or self.targetId)
    self.targetId=f and f.id or nil;self.frame:SetAttribute('TargetId',self.targetId)
    self.name.Text=f and L.nation(f) or L.text('전체 전장')
    local replay=self.observer and self.observer.replay
    local function clock(ticks)local t=math.floor((ticks or 0)/10);return string.format('%d:%02d',t//60,t%60)end
    local watched=self.observer and self.observer.ended or replay and string.format('다시보기 %s / %s',clock(replay.tick),clock(replay.endTick))or f and string.format('영토 %.1f%%  병력 %s',f.share*100,UI.troops(f.troops))or '남은 전장'
    self.stats.Text=watched
    UI.enabled(self.previous,#(self.list or {})>1);UI.enabled(self.next,#(self.list or {})>1)
    if self.observer then
        local key=f and f.matchId
        if self.frame.Visible and f and key~=self.focused then self.focused=key;self.callbacks.focus(f.labelTile,true)end
    elseif self.frame.Visible and f then self.callbacks.focus(f.labelTile,force or previous~=f.id)end
    if v2()then self:refresh20(f,self.state)end
end
function M:update(state,hidden)
    self.state=state
    if not state or state.version~=self.version then self.targetId=nil;self.focused=nil;self.version=state and state.version end
    self.observer=state and state.observer
    self.list=state and Model.spectators(state)or {}
    local replay=self.observer and self.observer.replay
    self.speed.Visible=replay~=nil;if replay then self.speed.Text=string.format('×%d',replay.speed or 1)end
    self.title.Text=replay and '다시보기'or self.observer and (self.observer.count and self.observer.count>1 and string.format('관전 %d명',self.observer.count)or '관전 중')or '관전'
    self.result.Text=self.observer and '나가기'or '결과'
    self.frame.Visible=state~=nil and state.multiplayer==true and state.phase=='lost'and (not state.matchEnded or self.observer~=nil)and not hidden
    if self.frame.Visible then self:refresh()end
end
local K
local function rank(state,f)
    if not(state and f)then return nil end
    local list={};for _,x in ipairs(state.factions or {})do if x.kind~='BOT'and not x.eliminated and (x.tiles or 0)>0 then table.insert(list,x)end end
    table.sort(list,function(a,b)return (a.share or 0)>(b.share or 0)end)
    for i,x in ipairs(list)do if x==f or x.id==f.id then return i end end
    return nil
end
function M:parts20()
    if self.v20 then return self.v20 end
    K=K or require(script.Parent.Kit20)
    local f=self.frame;local v={};self.v20=v
    for _,o in ipairs(f:GetChildren())do if o:IsA('GuiObject')then o:SetAttribute('V1',true)end;if o:IsA('UIStroke')and o.Name~='Stroke20'then o.Enabled=false end end
    f.BackgroundColor3=Color3.fromRGB(12,17,24);f.BackgroundTransparency=.06;K.round(f,12);K.stroke(f,K.colors.line,1,.1,true)
    local function btn(name,opts,fn)local b=K.button(f,name,opts,fn);b.button.ZIndex=f.ZIndex+2;b.face.ZIndex=f.ZIndex+2;if b.label then b.label.ZIndex=f.ZIndex+3 end;if b.iconImage then b.iconImage.ZIndex=f.ZIndex+3 end;return b end
    v.prev=btn('Previous20',{kind='plain',icon='back',iconSize=18},function()self:select(-1)end)
    v.next=btn('Next20',{kind='plain',icon='chev',iconSize=18},function()self:select(1)end)
    v.result=btn('Result20',{kind='plain',text='결과',size=14,weight=800},function()self.callbacks.result()end)
    v.leave=btn('Leave20',{kind='plain',text='나가기',size=14,weight=800},function()self.callbacks.leave()end)
    v.speed=btn('Speed20',{kind='plain',text='×1',size=13,weight=800},function()
        local r=self.observer and self.observer.replay;if not r then return end
        local nextSpeed=({[1]=2,[2]=4,[4]=1})[r.speed]or 1;self.speed.Text=string.format('×%d',nextSpeed);self.callbacks.speed(nextSpeed)
    end)
    v.speed.label:SetAttribute('LocalizationSkip',true)
    v.who=K.make('Frame',f,{Name='Who20',BackgroundTransparency=1,BorderSizePixel=0,ZIndex=f.ZIndex+2})
    v.square=K.make('Frame',v.who,{Name='Colour',BorderSizePixel=0,ZIndex=v.who.ZIndex+1});K.round(v.square,2)
    v.name=K.text(v.who,'Name','',15,K.colors.ink,800);v.name.ZIndex=v.who.ZIndex+1;v.name:SetAttribute('LocalizationSkip',true)
    v.rank=K.num(v.who,'Rank','',13,K.colors.muted);v.rank.ZIndex=v.who.ZIndex+1
    v.eye=K.icon(f,'watch',15,K.colors.muted,'Eye20');v.eye.ZIndex=f.ZIndex+2
    v.count=K.num(f,'Count20','',13,K.colors.muted);v.count.ZIndex=f.ZIndex+2
    v.rule=K.make('Frame',f,{Name='Rule20',BackgroundColor3=K.colors.line,BorderSizePixel=0,ZIndex=f.ZIndex+1})
    f:GetPropertyChangedSignal('Visible'):Connect(function()
        if f.Visible then if f:GetAttribute('Moving20')~='in'then f:SetAttribute('Shown20',false);K.appear(f,{dy=12,t=.18})end
        elseif not K.reduced and f.Parent then
            local g=f:Clone();g.Name='SpectatorGhost';g.Parent=f.Parent;g.Visible=true;g:SetAttribute('Moving20',nil);g:SetAttribute('Home20',f:GetAttribute('Home20')or f.Position)
            for _,o in ipairs(g:GetDescendants())do if o:IsA('GuiButton')then o.Active=false end end
            K.leave(g,{dy=12,t=.12},function()g:Destroy()end)
        end
    end)
    return v
end
function M:refresh20(f,state)
    local v=self:parts20()
    for _,o in ipairs(self.frame:GetChildren())do if o:GetAttribute('V1')then o.Visible=false end end
    local name=f and require(script.Parent.Localization).nation(f)or require(script.Parent.Localization).text('전체 전장')
    local changed=v.name.Text~=name
    v.name.Text=name
    v.square.BackgroundColor3=f and require(script.Parent.FactionColors).get(f.id,f.kind)or K.colors.muted;v.square.Visible=f~=nil
    local r=rank(state,f);v.rank.Text=r and require(script.Parent.Localization).text(string.format('%d위',r))or '';v.rank.Visible=r~=nil
    local replay=self.observer and self.observer.replay
    local function clock(ticks)local t=math.floor((ticks or 0)/10);return string.format('%d:%02d',t//60,t%60)end
    local n=self.observer and self.observer.count
    v.count.Text=replay and string.format('%s / %s',clock(replay.tick),clock(replay.endTick))or n and tostring(n)or ''
    v.eye.Visible=not replay and n~=nil;v.count.Visible=v.count.Text~=''
    v.speed.button.Visible=replay~=nil;if replay then v.speed:setText(string.format('×%d',replay.speed or 1))end
    v.result.button.Visible=self.observer==nil
    v.prev:setEnabled(#(self.list or {})>1);v.next:setEnabled(#(self.list or {})>1)
    if self.w20 then self:layout20(self.w20)end
    if changed and self.lastName20~=nil and self.frame.Visible then
        v.who:SetAttribute('Shown20',false);K.rehome(v.who);K.appear(v.who,{dx=12*(self.dir20 or 1),t=.12})
    end
    self.lastName20=name
end
function M:layout20(width)
    local v=self:parts20();self.w20=width
    local f=self.frame;local height=f.Parent and f.Parent.AbsoluteSize.Y/(UI.scale or 1)or 768
    local touch=require(script.Parent.InputMode).touch()
    local fmt=(not touch or require(script.Parent.Parent.Core.InterfacePlacement).tablet(width,height,touch))and 'pc'or height>width and 'pt'or 'ph'
    local pt=fmt=='pt';local bw=fmt=='pc'and 560 or fmt=='ph'and math.min(480,width-24)or width-20;local bh=pt and 112 or 56
    local pos=UDim2.fromOffset(math.floor((width-bw)/2),math.floor(height-(fmt=='pc'and 20 or pt and 14 or 10)-bh))
    f.Size=UDim2.fromOffset(bw,bh);f:SetAttribute('Home20',pos);if f:GetAttribute('Moving20')==nil then f.Position=pos end
    local rw=v.rank.Visible and K.width(v.rank.Text,13,v.rank)+2 or 0
    local function who(cap)
        local nw=math.max(0,math.min(K.width(v.name.Text,15,v.name)+2,cap-(v.square.Visible and 18 or 0)-(rw>0 and 8+rw or 0)))
        K.box(v.square,0,math.floor((44-10)/2),10,10);K.box(v.name,v.square.Visible and 18 or 0,0,nw,44);K.box(v.rank,(v.square.Visible and 18 or 0)+nw+8,0,rw,44)
        return (v.square.Visible and 18 or 0)+nw+(rw>0 and 8+rw or 0)
    end
    local side=pt and 48 or 44
    v.prev:place(7,6,side,44)
    local rb=fmt=='pc'and 84 or fmt=='ph'and 64 or 96
    if pt then
        v.next:place(bw-7-side,6,side,44)
        local ww=who(bw-140)
        local whoPos=UDim2.fromOffset(math.floor((bw-ww)/2),6);v.who.Size=UDim2.fromOffset(ww,44)
        if v.who:GetAttribute('Moving20')==nil then v.who.Position=whoPos end;v.who:SetAttribute('Home20',whoPos)
        K.box(v.rule,1,56,bw-2,1);v.rule.Visible=true
        local x=bw-7;v.leave:place(x-rb,63,rb,44);x-=rb+8
        if v.result.button.Visible then v.result:place(x-rb,63,rb,44);x-=rb+8 end
        if v.speed.button.Visible then v.speed:place(x-56,63,56,44)end
        local cx=14;if v.eye.Visible then K.box(v.eye,cx,56+21,15,15);cx+=21 end;K.box(v.count,cx,56,160,56)
    else
        v.rule.Visible=false
        local x=bw-7;v.leave:place(x-rb,6,rb,44);x-=rb+8
        if v.result.button.Visible then v.result:place(x-rb,6,rb,44);x-=rb+8 end
        if v.speed.button.Visible then v.speed:place(x-56,6,56,44);x-=56+8 end
        local cwid=v.count.Visible and K.width(v.count.Text,13,v.count)+2 or 0
        if v.count.Visible then K.box(v.count,x-cwid,0,cwid,56)end
        if v.eye.Visible then K.box(v.eye,x-cwid-6-15,math.floor((56-15)/2),15,15)end
        local reserve=self.observer and self.observer.replay and K.width('00:00 / 00:00',13,v.count)+2 or v.eye.Visible and 21+K.width('00',13,v.count)+2 or cwid
        local slot=fmt=='pc'and 220 or 180
        local nextX=math.max(7+side+8,math.min(7+side+8+slot+8,x-(reserve>0 and reserve+6 or 0)-8-side))
        v.next:place(nextX,6,side,44)
        local ww=who(nextX-8-(7+side+8))
        local whoPos=UDim2.fromOffset(7+side+8+math.floor((nextX-8-(7+side+8)-ww)/2),6);v.who.Size=UDim2.fromOffset(ww,44)
        if v.who:GetAttribute('Moving20')==nil then v.who.Position=whoPos end;v.who:SetAttribute('Home20',whoPos)
    end
    for _,b in ipairs({v.result,v.leave,v.speed})do require(script.Parent.MatchSheet).fill20(b)end
end
function M:layout(width)
    if v2()then return self:layout20(width)end
    local w=math.min(440,width-24);UI.box(self.frame,(width-w)/2,8,w,88)
    UI.box(self.title,12,4,84,24);UI.box(self.name,100,4,w-112,24)
    UI.box(self.previous,8,36,44,44);UI.box(self.next,60,36,44,44);UI.box(self.result,w-80,36,72,44)
    local speedW=self.speed.Visible and 64 or 0;if self.speed.Visible then UI.box(self.speed,w-80-speedW,36,56,44)end
    UI.box(self.stats,112,34,w-200-speedW,48)
end
return M
