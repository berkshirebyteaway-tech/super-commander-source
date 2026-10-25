local UI=require(script.Parent.Theme)
local L=require(script.Parent.Localization)
local M={};M.__index=M
M.WINDOW=300
function M.new(parent,callbacks)
    local self=setmetatable({callbacks=callbacks or {},ignored={},asked={}},M)
    local p=UI.panel(parent,'AllianceRenewal');p.ZIndex=18;p.Visible=false;self.panel=p
    self.title=UI.label(p,'Title','동맹 만료 임박',14,UI.colors.gold)
    self.detail=UI.label(p,'Detail','',13)
    self.renew=UI.button(p,'Renew','연장',function()
        local c=self.current;if not c then return end
        require(script.Parent.TelemetryStep).step('match','renewAsk',{});self.asked[c.key]=true;self.callbacks.send('alliance','extend',c.f.id);self:update(self.state)
    end,true)
    self.ignore=UI.button(p,'Ignore','무시',function()local c=self.current;if c then require(script.Parent.TelemetryStep).step('match','renewIgnore',{});self.ignored[c.key]=true;self:update(self.state)end end)
    self.focus=UI.button(p,'Focus','보기',function()local c=self.current;if c and c.f.labelTile then self.callbacks.focus(c.f.labelTile)end end)
    return self
end
local V2=require(script.Parent.Hud20).ENABLED
function M:items20(list)
    local items={}
    for _,c in ipairs(list or {})do
        local key=c.key
        table.insert(items,{key='renew:'..key,kind='renew',name=L.nation(c.f),userId=c.f.userId,ratio=math.clamp(c.left/M.WINDOW,0,1),
            asked=self.asked[key]==true,enabled=self.state and not self.state.paused,
            accept=function()if self.asked[key]then return end;require(script.Parent.TelemetryStep).step('match','renewAsk',{});self.asked[key]=true;self.callbacks.send('alliance','extend',c.f.id);self:update(self.state)end,
            decline=function()require(script.Parent.TelemetryStep).step('match','renewIgnore',{});self.ignored[key]=true;self:update(self.state)end,
            inspect=function()if c.f.labelTile then self.callbacks.focus(c.f.labelTile)end end})
    end
    require(script.Parent.Requests20).set('renew',items)
end
function M:update(state)
    self.state=state;self.current=nil
    if not state or state.phase~='playing'or state.tick==nil then self.count=0;if V2 then self:items20(nil)end;return end
    if self.version~=state.version then self.version=state.version;self.ignored={};self.asked={}end
    local list={}
    for _,f in ipairs(state.factions or {})do
        local left=f.allied and not f.teammate and f.allianceExpires and f.allianceExpires-state.tick
        if left and left>0 and left<=M.WINDOW then
            local key=f.id..':'..f.allianceExpires
            if not self.ignored[key]then table.insert(list,{f=f,left=left,key=key})end
        end
    end
    table.sort(list,function(a,b)return a.left<b.left end)
    self.count=#list;self.current=list[1]
    if self.current and self.current.key~=self.shownKey then self.shownKey=self.current.key;require(script.Parent.TelemetryStep).step('match','renewShown',{count=#list})end
    if V2 then self:items20(list)end
    local c=self.current;if not c then return end
    self.title.Text=L.text('%s와 동맹이 곧 끝나요'):format(L.nation(c.f))
    local asked=self.asked[c.key]==true;local sec=math.ceil(c.left/10)
    self.detail.Text=L.text('%d:%02d 남음, '):format(sec//60,sec%60)..L.text(asked and '내 연장 ✓  상대 대기'or '서로 연장')
    self.detail:SetAttribute('LocalizationSkip',true)
    UI.enabled(self.renew,not asked and not state.paused)
end
function M:layout(w,h,obscured,battle)
    if V2 then self.panel.Visible=false;return end
    self.panel.Visible=self.current~=nil and not obscured
    if not self.avatar then
        self.avatar=UI.make('ImageLabel',self.panel,{Name='Avatar',BackgroundColor3=UI.colors.raised,BorderSizePixel=0,ZIndex=self.panel.ZIndex+1})
        self.edge=require(script.Parent.EdgeMask).fit(UI.make('Frame',self.panel,{Name='Edge',BackgroundColor3=UI.colors.gold,BorderSizePixel=0,ZIndex=self.panel.ZIndex+1}))
        self.bar=UI.make('Frame',self.panel,{Name='TimeLeft',BackgroundColor3=UI.colors.gold,BorderSizePixel=0,ZIndex=self.panel.ZIndex+1})
    end
    local c=self.current;local f=c and c.f
    self.avatar.Image=f and f.userId and f.userId>0 and ('rbxthumb://type=AvatarHeadShot&id='..f.userId..'&w=150&h=150')or ''
    self.avatar.Visible=self.avatar.Image~=''
    require(script.Parent.DiplomacyInbox).card(self.panel,{edge=self.edge,avatar=self.avatar,name=self.title,line=self.detail,bar=self.bar,fraction=c and c.left/M.WINDOW or 1,
        buttons={self.renew,self.focus,self.ignore},color=UI.colors.gold},w)
    self.title:SetAttribute('LocalizationSkip',true)
end
return M
