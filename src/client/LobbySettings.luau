local UI=require(script.Parent.ToyUI)
local Rows=require(script.Parent.SettingsRows)
local M={}
function M.draw(hub,body,w)
    hub.pageTitle.Text='설정'
    local shop=hub.callbacks.shop();local a=hub.account or {};local p=a.preferences or {};local y=0
    local function saved(r)if r and r.ok~=false and shop.notify then shop.notify('저장됨',false)end end
    y=Rows.heading(body,'화면',y,w)
    for _,v in ipairs({{'reducedEffects','간소한 이펙트',p.reducedEffects==true},{'cameraShake','화면 흔들림',p.cameraShake~=false},{'mapFlashes','지도 섬광',p.mapFlashes~=false}})do
        y=Rows.toggle(body,v[1],v[2],v[3],y,w,function(on)require(script.Parent.TelemetryStep).step('settings','toggle',{item=v[1],result=on and 'active'or 'inactive'});shop:run(function()saved(shop:request('preference',v[1],on))end)end,a.ready==true and not shop.busy)
    end
    local opacityLabel=UI.label(body,'HudOpacity','경기 패널 배경',14);UI.box(opacityLabel,8,y,w-16,24);y+=32
    for i,v in ipairs({1,.75,.5,.25})do
        local b=UI.button(body,'HudOpacity'..i,(v*100)..'%',function()require(script.Parent.TelemetryStep).step('settings','hudOpacity',{value=v*100});shop:run(function()saved(shop:request('preference','hudOpacity',v))end)end,(p.hudOpacity or 1)==v)
        UI.box(b,(i-1)*(w+6)/4,y,(w-18)/4,48);UI.enabled(b,a.ready==true and not shop.busy)
    end;y+=60
    y=Rows.heading(body,'음성 채팅',y+10,w)
    local VipLock=require(script.Parent.VipLock)
    y=Rows.toggle(body,'voiceTeamOnly','경기 중 팀끼리만 듣기',p.voiceTeamOnly~=false,y,w,function(on)
        if not VipLock.allows('voice')then VipLock.open('voice');hub:drawPage();return end
        require(script.Parent.TelemetryStep).step('settings','toggle',{item='voiceTeamOnly',result=on and 'active'or 'inactive'})
        shop:run(function()saved(shop:request('preference','voiceTeamOnly',on))end)
    end,a.ready==true and not shop.busy)
    if not VipLock.allows('voice')then
        local row=body:FindFirstChild('voiceTeamOnlyRow')
        if row then
            for _,o in ipairs(row:GetDescendants())do if o:IsA('TextLabel')then o.TextColor3=UI.colors.muted end;if o.Name=='Switch'then o.BackgroundTransparency=.6 end end
            local tag=VipLock.tag(row,w-4-52-16-30,19);tag.ZIndex=row.ZIndex+5
        end
    end
    y=Rows.heading(body,'사운드',y+10,w)
    local label=UI.label(body,'Volume','효과음 음량',14);UI.box(label,8,y,w-16,24);y+=32
    for i,v in ipairs({{'off','끔'},{.5,'작게'},{1,'보통'},{1.5,'크게'}})do
        local on=v[1]=='off'and p.soundsMuted==true or v[1]~='off'and p.soundsMuted~=true and (p.sfxVolume or 1)==v[1]
        local b=UI.button(body,'Volume'..i,v[2],function()require(script.Parent.TelemetryStep).step('settings','volume',{item=v[1]=='off'and 'off'or 'on',value=v[1]=='off'and 0 or v[1]*100});shop:run(function()
            if v[1]=='off'then saved(shop:request('preference','soundsMuted',true))
            else saved(shop:request('preference','sfxVolume',v[1]));require(script.Parent.ToyAudio).play('confirm')end
        end)end,on);UI.box(b,(i-1)*(w+6)/4,y,(w-18)/4,48);UI.enabled(b,a.ready==true and not shop.busy)
    end;y+=60
    y=Rows.heading(body,'언어',y,w)
    local me=game.Players.LocalPlayer;local locale=me:GetAttribute('ToyfrontLocale')or 'auto'
    for i,v in ipairs({{'auto','자동'},{'ko-kr','한국어'},{'en-us','English'}})do
        local b=UI.button(body,'Language'..i,v[2],function()require(script.Parent.TelemetryStep).step('settings','language',{item=(v[1]:gsub('-','_'))});me:SetAttribute('ToyfrontLocale',v[1]~='auto'and v[1]or nil);if a.ready==true then shop:run(function()shop:request('preference','language',v[1])end)end;hub:drawPage()end,locale==v[1]);UI.box(b,(i-1)*(w+6)/3,y,(w-12)/3,48)
    end;y+=60
    y=Rows.heading(body,'도움말',y,w)
    for _,v in ipairs({{'Help','조작 도움말',hub.callbacks.help},{'Tutorial','첫 작전 다시 하기',function()require(script.Parent.LobbyConfirm).open(hub,'첫 작전','5분 연습 경기로 점령과 병력 기초를 다시 배워요. 참가 대기 중이면 먼저 취소해 주세요.','시작',function()hub:closePage();hub.callbacks.learn()end,'preferences')end},{'Credits','크레딧',hub.callbacks.credits}})do
        local b=UI.button(body,v[1],v[2],v[3]);UI.box(b,2,y,w-4,48);y+=56
    end
    body.CanvasSize=UDim2.fromOffset(0,y+8)
end
return M
