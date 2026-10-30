local Players=game:GetService('Players')
local K=require(script.Parent.Kit20)
local Pop=require(script.Parent.Pop20)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local C=K.colors
local M={}
local shown
local function close()if shown then shown=nil;Pop.closeOwner('partyAsk')end end
local function answer(lobby,ask,accept)
    close()
    require(script.Parent.TelemetryStep).step('social','partyAnswer',{result=accept and 'accepted'or 'declined',item=ask.kind=='world'and 'world'or 'official'})
    if accept and ask.kind=='world'then require(script.Parent.TransitionVeil).show('전장 준비 중…')end
    lobby:request('partyAnswer',{id=ask.id,accept=accept})
end
function M.update(lobby)
    local s=lobby.data;local party=s and s.party;local ask=party and party.ask
    local mine=ask and #party.users>1 and party.leader==Players.LocalPlayer.UserId and lobby.inMenu~=false and not s.inMatch
    if not mine then close();return end
    if shown and shown.id==ask.id then return end
    close()
    local fmt=require(script.Parent.Lobby20).format(lobby.root.AbsoluteSize.X/(require(script.Parent.Theme).scale or 1),lobby.root.AbsoluteSize.Y/(require(script.Parent.Theme).scale or 1))
    local pad=fmt=='pc'and 18 or 14;local w=fmt=='pc'and 400 or 340;local face=fmt=='ph'and 40 or 48;local mapW,mapH=face*1.4,face
    local bh=fmt=='ph'and 40 or 46;local h=pad+mapH+14+bh+pad
    local entry={id=ask.id,at=os.clock()};shown=entry
    local label=ask.kind=='world'and '난입전'or (Maps.meta(ask.map)or {}).label or tostring(ask.map or '')
    local kind=ask.kind=='world'and '개인전'or ask.mode=='teams'and '팀전'or '개인전'
    Pop.sheet('partyAsk','PartyAsk20',w,h,function(p,_,pw)
        local a=K.avatar(p,'Asker',ask.from,face,C.accent,2);a.Position=UDim2.fromOffset(pad,pad)
        local chev=K.icon(p,'chev',16,C.muted,'Chevron');K.box(chev,pad+face+6,pad+(face-16)/2,16,16)
        local mx=pad+face+28
        local m=ask.kind=='world'and K.make('Frame',p,{Name='Map',BackgroundColor3=C.accent,BorderSizePixel=0,Size=UDim2.fromOffset(mapW,mapH)})or K.map(p,'Map',ask.map,mapW,mapH,6)
        if ask.kind=='world'then K.round(m,6);local g=K.icon(m,'globe',22,C.bg,'Globe');K.box(g,(mapW-22)/2,(mapH-22)/2,22,22)end
        m.Position=UDim2.fromOffset(mx,pad)
        local tx=mx+mapW+12
        local t=K.text(p,'Title',string.format('%s  %s',ask.name or '',label),fmt=='ph'and 15 or 17,C.ink,800);t.TextTruncate=Enum.TextTruncate.AtEnd;K.box(t,tx,pad+mapH/2-22,pw-tx-pad,22)
        local sub=K.text(p,'Seats',string.format('%s %d / %d',kind,ask.count or 0,ask.max or 0),13,C.muted,700);K.box(sub,tx,pad+mapH/2+2,pw-tx-pad,18)
        local y=pad+mapH+14;local bw=math.floor((pw-pad*2-10)*.36)
        local no=K.button(p,'Decline',{kind='plain',text='거절',size=fmt=='ph'and 15 or 16,weight=800},function()answer(lobby,ask,false)end);no:place(pad,y,bw,bh)
        local go=K.button(p,'Go',{kind='pri',text='가기',size=fmt=='ph'and 15 or 16,weight=800},function()answer(lobby,ask,true)end);go:place(pad+bw+10,y,pw-pad*2-bw-10,bh)
        local bar=K.make('Frame',go.face,{Name='Timer',BackgroundColor3=C.bg,BackgroundTransparency=.55,BorderSizePixel=0,AnchorPoint=Vector2.new(0,1),Position=UDim2.fromScale(0,1),Size=UDim2.new(1,0,0,3),ZIndex=go.face.ZIndex+2})
        local seconds=ask.seconds or 10
        if not K.reduced then game:GetService('TweenService'):Create(bar,TweenInfo.new(seconds,Enum.EasingStyle.Linear),{Size=UDim2.new(0,0,0,3)}):Play()end
        entry.bar=bar
    end,function()if shown==entry then shown=nil end end)
    require(script.Parent.ToyAudio).play('request')
    require(script.Parent.TelemetryStep).step('social','partyAskShown',{item=ask.kind=='world'and 'world'or 'official'})
    task.delay((ask.seconds or 10)+.3,function()if shown==entry then close()end end)
end
return M
