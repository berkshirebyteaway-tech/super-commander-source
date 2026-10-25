local K=require(script.Parent.Kit20)
local S=require(script.Parent.Sheet20)
local Theme=require(script.Parent.Theme)
local Step=require(script.Parent.TelemetryStep)
local Rules=require(script.Parent.Parent.Core.ComebackRules)
local Tween=game:GetService('TweenService')
local M={}
local C=K.colors
local function now()local ok,t=pcall(function()return workspace:GetServerTimeNow()end);return ok and t or os.time()end
local function inRoom(lobby)return lobby~=nil and(lobby.matchRoom~=nil and lobby.matchRoom.open==true or lobby.inMenu==false or not lobby.frame.Visible)end
function M.when(row,t)
    if row.when=='now'then return '지금 열 수 있어요'end
    if row.when=='next'then return '다음 작전'end
    if not row.at then return '내일'end
    local at,today=os.date('*t',row.at),os.date('*t',math.floor(t))
    local tomorrow=at.year~=today.year or at.yday~=today.yday;local h=at.hour%12;if h==0 then h=12 end
    if at.hour<12 then return string.format(tomorrow and '내일 오전 %d시'or '오늘 오전 %d시',h)end
    return string.format(tomorrow and '내일 오후 %d시'or '오늘 오후 %d시',h)
end
function M.parts(row,t)
    if row.when=='now'then return '무료 보급','지금 열 수 있어요'end
    if row.when=='next'or not row.at then return '내일 보급',M.when(row,t)end
    local at,today=os.date('*t',row.at),os.date('*t',math.floor(t))
    local tomorrow=at.year~=today.year or at.yday~=today.yday;local h=at.hour%12;if h==0 then h=12 end
    return tomorrow and '내일 보급'or '오늘 보급',string.format(at.hour<12 and '오전 %d시'or '오후 %d시',h)
end
local function like(root,lobby)
    if not root or root:FindFirstChild('LikeToast')then return end
    if inRoom(lobby)then local untilAt=os.clock()+1800;while inRoom(lobby)and os.clock()<untilAt do task.wait(.5)end;task.wait(.6)end
    if not root.Parent or root:FindFirstChild('LikeToast')then return end
    local text='👍 재밌었다면 좋아요 눌러 주세요';local fs=15
    local rw=root.AbsoluteSize.X/(Theme.scale or 1)
    local w=math.min(rw-32,K.width(text,fs)+40)
    local t=K.make('Frame',root,{Name='LikeToast',BackgroundColor3=C.raised,BorderSizePixel=0,ZIndex=48});K.round(t,'pill');K.stroke(t,C.gold,1,.3,true)
    K.box(t,(rw-w)/2,rw<600 and 128 or 64,w,44)
    local l=K.text(t,'Text',text,fs,C.ink,800,Enum.TextXAlignment.Center);l.ZIndex=49;K.box(l,14,0,w-28,44)
    Step.step('lobby','likeAsk',{result='shown'})
    K.appear(t,{dy=-12,t=.16})
    task.delay(1.96,function()if t.Parent then K.leave(t,{dy=-8,t=.12},function()t:Destroy()end)end end)
end
local function prompt(kind,root,lobby)
    if kind=='favorite'then
        if inRoom(lobby)then local untilAt=os.clock()+1800;while inRoom(lobby)and os.clock()<untilAt do task.wait(.5)end;task.wait(.6)end
        Step.step('lobby','favoriteAsk',{result='shown'})
        local shown=false;local function after()if not shown then shown=true;task.delay(.6,like,root,lobby)end end
        pcall(function()local s=game:GetService('AvatarEditorService')
            s.PromptSetFavoriteCompleted:Once(function(r)Step.step('lobby','favoriteAsk',{result=r==Enum.AvatarPromptResult.Success and 'accepted'or 'cancelled'});after()end)
            s:PromptSetFavorite(game.PlaceId,Enum.AvatarItemType.Asset,true)end)
        task.delay(12,after)
    end
end
function M.open(lobby,rows,thenFavorite)
    if lobby.root:FindFirstChild('ComebackCard')then return end
    local sc=Theme.scale or 1
    local W,H=lobby.root.AbsoluteSize.X/sc,lobby.root.AbsoluteSize.Y/sc
    local fmt=S.format(W,H);local pt,ph=fmt=='pt',fmt=='ph'
    local box=rows[1];local openNow=box.when=='now'
    local title,chipText=M.parts(box,now())
    local alpha=pt and .22 or .28
    local dim=K.make('TextButton',lobby.root,{Name='ComebackDim',Text='',AutoButtonColor=false,BackgroundColor3=S.DIM,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=44})
    Tween:Create(dim,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=alpha}):Play()
    local cw,ch=K.even(pt and W-32 or ph and 300 or 400),pt and 330 or ph and 300 or 420
    local card=K.make('Frame',lobby.root,{Name='ComebackCard',BackgroundColor3=S.BG,BorderSizePixel=0,ZIndex=45,Active=true})
    K.round(card,14);K.stroke(card,C.line,1)
    K.boxCentre(card,math.floor((W-cw)/2),pt and math.floor((H-ch)/2)or ph and 56 or math.floor((H-ch)/2+20),cw,ch)
    local cs=pt and 140 or ph and 110 or 170;local crateH=math.floor(cs*.86)
    local ts=pt and 22 or ph and 18 or 24;local pad=pt and 16 or ph and 14 or 28
    local titleY,crateY,chipY
    if pt then crateY=26;titleY=crateY+crateH+8;chipY=titleY+ts+12
    else titleY=pad;crateY=titleY+ts+5+(ph and 6 or 12)+(ph and 0 or 6);chipY=crateY+crateH+(ph and 6 or 12)-(ph and 6 or 10)end
    local t=K.text(card,'Title',title,ts,C.ink,800,Enum.TextXAlignment.Center);t.ZIndex=46;K.box(t,pad,titleY,cw-pad*2,ts+5)
    local chs=pt and 16 or ph and 13 or 16;local chh=pt and 30 or ph and 24 or 30
    if openNow and not pt then crateH=chipY+chh-crateY;cs=math.min(cw-pad*2,math.floor(crateH/.86))end
    pcall(function()local v=require(script.Parent.CollectionPreview).create(card,nil,{crate='basic',name='Crate',direction=Vector3.new(-.42,.5,-1).Unit,fill=.92});K.box(v,(cw-cs)/2,crateY,cs,crateH);v.ZIndex=46 end)
    if not openNow then
        local chip,chw=K.chip(card,'When',chipText,'gold',{size=chs,height=chh,icon='clock',filled=true,weight=800})
        chip.Position=UDim2.fromOffset(math.floor((cw-chw)/2),chipY);chip.ZIndex=47;for _,o in ipairs(chip:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=48;if o:IsA('ImageLabel')then o.ImageColor3=C.bg end end end
    end
    Step.step('lobby','comebackCard',{item=openNow and 'open'or 'tomorrow',result='shown'})
    K.appear(card,{scaleFrom=.96,t=.16})
    local closed=false
    local function close(how)
        if closed then return end;closed=true;Step.step('lobby','comebackCard',{result='closed',reason=how})
        dim.Active=false
        K.leave(card,{t=.10},function()card:Destroy()end)
        local s=card:FindFirstChild('Pop20');if s and not K.reduced then Tween:Create(s,TweenInfo.new(.10,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Scale=.96}):Play()end
        task.delay(K.reduced and 0 or .08,function()Tween:Create(dim,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{BackgroundTransparency=1}):Play();task.delay(.13,function()dim:Destroy()end)end)
        if thenFavorite then task.delay(1,prompt,'favorite',lobby.root,lobby)end
    end
    local bh=pt and 52 or ph and 42 or 56
    local main=K.button(card,'Main',{kind='pri',text=openNow and '상자 열러 가기'or '알겠어요',size=pt and 18 or ph and 15 or 18,icon=nil},function(b)
        if openNow then K.confirm(b,true);close('shop');lobby:openPage('shop')
        elseif card:GetAttribute('Notify')then
            K.confirm(b,true);Step.step('lobby','comebackOptIn',{result='opened'})
            task.spawn(function()local s=game:GetService('ExperienceNotificationService')
                pcall(function()s.OptInPromptClosed:Once(function()Step.step('lobby','comebackOptIn',{result='closed'})end)end)
                pcall(function()s:PromptOptIn()end)end)
            close('notify')
        else close('ok')end
    end)
    main.button.ZIndex=47
    local later
    local function place(withLater)
        if pt then main:place(16,ch-16-bh,cw-32,bh)
        elseif withLater then local lw=ph and 80 or 110;later.button.Visible=true;later:place(pad,ch-pad-bh,lw,bh);main:place(pad+lw+10,ch-pad-bh,cw-pad*2-lw-10,bh)
        else if later then later.button.Visible=false end;main:place(pad,ch-pad-bh,cw-pad*2,bh)end
    end
    if pt then
        local x=S.iconButton(card,'Later','x',40,18,function()close('later')end);x:place(cw-10-40,10,40,40);x.button.ZIndex=47
    else
        later=K.button(card,'Later',{kind='ghost',text='닫기',size=ph and 13 or 16,weight=800},function()close('later')end);later.button.ZIndex=47
    end
    place(false)
    dim.Activated:Connect(function()close('outside')end)
    local size=lobby.root.AbsoluteSize
    task.spawn(function()while card.Parent and not closed do
        if (lobby.root.AbsoluteSize-size).Magnitude>2 then close('resize');break end
        local hide=inRoom(lobby);card.Visible=not hide;dim.Visible=not hide;task.wait(.25)end end)
    if not openNow then task.spawn(function()
        local s=game:GetService('ExperienceNotificationService');local okCall,can=pcall(function()return s:CanPromptOptInAsync()end)
        if okCall and can and not closed then card:SetAttribute('Notify',true)
            main:setText('알림 받기')
            local is=pt and 18 or ph and 16 or 18
            if not main.iconImage then main.iconImage=K.icon(main.face,'bell',is,C.bg,'Icon');main.iconImage.ZIndex=main.face.ZIndex+1;main.iconSize=is end
            place(true)
        end
        Step.step('lobby','comebackOptIn',{result=okCall and can and 'shown'or 'unavailable'})
    end)else place(true)end
    return card
end
function M.watch(lobby,before,p)
    local game1,win1=Rules.firstGame(before,p),Rules.favorite(before,p)
    if not game1 and not win1 then return end
    if lobby.comebackWaiting then return end;lobby.comebackWaiting=true
    task.spawn(function()
        local Intro=require(script.Parent.LobbyIntro);local untilAt=os.clock()+1800
        local function ready()return lobby.frame.Parent and lobby.frame.Visible and lobby.inMenu~=false and not Intro.active and not lobby.firstLesson and not lobby.page and not inRoom(lobby)
            and not lobby.root:FindFirstChild('CheckInCelebration')and not require(script.Parent.ResultCelebration).cardOpen()end
        while lobby.frame.Parent and os.clock()<untilAt do
            task.wait(.5)
            if ready()then task.wait(.8);if ready()then
                lobby.comebackWaiting=false
                local a=lobby.account or {};local billing=a.billing or {}
                if game1 then M.open(lobby,Rules.rows(a.progress or p,billing.freeDrawAt,now()),win1)else prompt('favorite',lobby.root,lobby)end
                return
            end end
        end
        lobby.comebackWaiting=false
    end)
end
return M
