local UI=require(script.Parent.Theme)
local Model=require(script.Parent.Parent.Core.ResultPresentation)
local L=require(script.Parent.Localization)
local M={};M.__index=M
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
    local watched=self.observer and self.observer.ended or replay and string.format('다시보기 %s / %s',clock(replay.tick),clock(replay.endTick))or f and string.format('영토 %.1f%%  병력 %s',f.share*100,UI.troops(f.troops))or '남은 전장을 확인하세요'
    self.stats.Text=watched
    UI.enabled(self.previous,#(self.list or {})>1);UI.enabled(self.next,#(self.list or {})>1)
    if self.observer then
        local key=f and f.matchId
        if self.frame.Visible and f and key~=self.focused then self.focused=key;self.callbacks.focus(f.labelTile,true)end
    elseif self.frame.Visible and f then self.callbacks.focus(f.labelTile,force or previous~=f.id)end
end
function M:update(state,hidden)
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
function M:layout(width)
    local w=math.min(440,width-24);UI.box(self.frame,(width-w)/2,8,w,88)
    UI.box(self.title,12,4,84,24);UI.box(self.name,100,4,w-112,24)
    UI.box(self.previous,8,36,44,44);UI.box(self.next,60,36,44,44);UI.box(self.result,w-80,36,72,44)
    local speedW=self.speed.Visible and 64 or 0;if self.speed.Visible then UI.box(self.speed,w-80-speedW,36,56,44)end
    UI.box(self.stats,112,34,w-200-speedW,48)
end
return M
