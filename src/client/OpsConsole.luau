local Players=game:GetService('Players')
local Tween=game:GetService('TweenService')
local UI=require(script.Parent.ToyUI)
local Rules=require(script.Parent.Parent.Core.OpsRules)
local Step=require(script.Parent.TelemetryStep)
local C=UI.colors
local M={}
local st={open=false,gui=nil,status=nil,user=nil,query='',flashText='',flashMinutes=15,duration='1d',reason='cheat',note='',armed=nil,busy=false,last=nil}
local stateNames={normal='평소',warn='업데이트 예고 중',gated='새 경기 멈춤',closing='업데이트 대기',outdated='새 버전으로 옮기는 중',maintenance='점검 중'}
local draw
local function remote()return script.Parent.Parent:FindFirstChild('OpsRequest')end
local function call(action,args,after)
    if st.busy then return end
    local r=remote();if not r then st.last={ok=false,text='운영 연결을 찾지 못했어요.'};draw();return end
    st.busy=true;draw()
    task.spawn(function()
        local ok,res=pcall(function()return r:InvokeServer(action,args)end)
        st.busy=false
        res=ok and type(res)=='table'and res or {ok=false,message='응답이 없어요.'}
        if res.message then st.last={ok=res.ok==true,text=res.message}end
        if after then after(res)end
        Step.step('ops','console',{item=action,result=res.ok and 'ok'or 'failed'})
        if st.open then draw()end
    end)
end
local function refresh()call('status',nil,function(res)if res.ok then st.status=res end end)end
local function label(parent,name,text,size,color,x,y,w,h)
    local l=UI.label(parent,name,text,size,color);UI.box(l,x,y,w,h);l.AutoLocalize=false;l.TextWrapped=true;return l
end
local function button(parent,name,text,fn,x,y,w,h,primary,color)
    local b=UI.button(parent,name,text,fn,primary);UI.box(b,x,y,w,h or 48);b.TextSize=14;b.AutoLocalize=false
    if color then b.BackgroundColor3=color:Lerp(C.raised,.55);local e=b:FindFirstChildOfClass('UIStroke');if e then e.Color=color end end
    UI.enabled(b,not st.busy);return b
end
local function chip(parent,name,text,on,fn,x,y,w)
    local b=UI.button(parent,name,text,fn);UI.box(b,x,y,w,48);b.TextSize=14;b.AutoLocalize=false
    b.BackgroundColor3=on and C.accent:Lerp(C.raised,.6)or C.raised;b.TextColor3=on and C.ink or C.muted
    local e=b:FindFirstChildOfClass('UIStroke');if e then e.Color=on and C.accent or C.line end
    return b
end
local function input(parent,name,text,placeholder,x,y,w,onChange)
    local box=UI.make('TextBox',parent,{Name=name,Text=text,PlaceholderText=placeholder,ClearTextOnFocus=false,TextSize=15,Font=Enum.Font.BuilderSansMedium,TextColor3=C.ink,PlaceholderColor3=C.muted,
        BackgroundColor3=C.bg,BackgroundTransparency=.2,BorderSizePixel=0,TextXAlignment=Enum.TextXAlignment.Left,ClipsDescendants=true})
    UI.box(box,x,y,w,48);UI.corner(box,3);UI.stroke(box,C.line,1);UI.make('UIPadding',box,{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)});box.AutoLocalize=false
    box:GetPropertyChangedSignal('Text'):Connect(function()onChange(box.Text)end)
    return box
end
local function section(body,title,y,w)
    local head=label(body,'Section_'..title,title,13,C.gold,0,y,w,20);head.Font=Enum.Font.BuilderSansBold;return y+26
end
local function statusBlock(body,y,w)
    local s=st.status
    if not s then return label(body,'StatusWait','상태를 불러오는 중이에요.',14,C.muted,0,y,w,22)and y+30 end
    local lines={
        string.format('지금: %s%s',stateNames[s.state]or s.state,s.manual and ' (maintenance 켜짐)'or ''),
        string.format('서버 닫기 closeAt: %s',s.closeAt and s.closeText or (s.rawClose~=''and '형식 오류, 예: 2026-10-20 21:00'or '없음')),
        string.format('다시 열기 reopenAt: %s',s.reopenAt and s.reopenText or (s.rawReopen~=''and '형식 오류이거나 closeAt보다 빨라요'or '없음')),
    }
    if s.closeAt and s.closeAt>s.now then table.insert(lines,string.format('닫기까지 %s',Rules.duration(s.closeAt-s.now)))end
    table.insert(lines,string.format('이 서버: %s  버전 %d  접속 %d명%s',s.server=='HQ'and '로비'or '경기',s.version or 0,#s.players,s.live and ''or '  (Studio)'))
    if s.latest and s.version and s.latest>s.version then table.insert(lines,string.format('새 버전 %d이 나와서 경기가 끝난 지휘관부터 옮겨요',s.latest))end
    local text=table.concat(lines,'\n')
    local box=label(body,'Status',text,14,C.ink,0,y,w,#lines*20+4);box.TextYAlignment=Enum.TextYAlignment.Top
    y+=#lines*20+10
    button(body,'OpsRefresh','새로고침',refresh,0,y,120)
    local hint=label(body,'ScheduleHint','일정은 Creator Hub의 Configs에서 정해요. closeAt, reopenAt, maintenance, ticker',12,C.muted,128,y,w-128,48)
    hint.TextYAlignment=Enum.TextYAlignment.Center
    return y+56
end
local function flashBlock(body,y,w)
    input(body,'FlashText',st.flashText,'모든 서버 맨 위에 보일 한 줄',0,y,w,function(t)st.flashText=t end);y+=56
    local opts={5,15,60};local cw=math.floor((w-16)/3)
    for i,m in ipairs(opts)do chip(body,'FlashMin'..m,string.format('%d분',m),st.flashMinutes==m,function()st.flashMinutes=m;draw()end,(i-1)*(cw+8),y,cw)end
    y+=56
    local half=math.floor((w-8)/2)
    button(body,'FlashSend','모든 서버에 보내기',function()call('flash',{text=st.flashText,minutes=st.flashMinutes})end,0,y,half,48,true)
    button(body,'FlashClear','공지 내리기',function()call('flash',{clear=true})end,half+8,y,w-half-8)
    y+=56
    local s=st.status
    if s and s.flash~=''then label(body,'FlashNow',string.format('지금 보이는 공지: %s',s.flash),13,C.muted,0,y,w,20);y+=26 end
    return y
end
local function userBlock(body,y,w)
    input(body,'UserQuery',st.query,'이름 또는 유저 번호',0,y,w-108,function(t)st.query=t end)
    button(body,'UserFind','찾기',function()st.armed=nil;call('lookup',{query=st.query},function(res)st.user=res.ok and res.user or nil end)end,w-100,y,100,48,true)
    y+=56
    local s=st.status
    if s and #s.players>0 then
        local cw=math.max(120,math.floor((w-16)/3));local cols=math.max(1,math.floor((w+8)/(cw+8)));cw=math.floor((w-(cols-1)*8)/cols)
        for i,row in ipairs(s.players)do
            local b=chip(body,'Here'..row.id,row.display..(row.inMatch and '  경기 중'or ''),st.user and st.user.id==row.id,function()st.query=tostring(row.id);st.armed=nil;call('lookup',{query=tostring(row.id)},function(res)st.user=res.ok and res.user or nil end)end,(i-1)%cols*(cw+8),y+math.floor((i-1)/cols)*56,cw)
            b.TextTruncate=Enum.TextTruncate.AtEnd
        end
        y+=math.ceil(#s.players/cols)*56
    end
    local u=st.user;if not u then return y end
    y+=4
    label(body,'UserName',string.format('%s  (%d)%s',u.name,u.id,u.here and '  이 서버 접속 중'or ''),16,C.ink,0,y,w,24);y+=28
    if u.historyUnavailable then label(body,'UserHistory','정지 기록을 불러오지 못했어요.',13,C.muted,0,y,w,20);y+=24
    elseif #u.history==0 then label(body,'UserHistory','정지 기록이 없어요.',13,C.muted,0,y,w,20);y+=24
    else for i,h in ipairs(u.history)do
        local kind=h.ban and (h.duration and h.duration<0 and '영구 정지'or string.format('정지 %s',Rules.duration(h.duration or 0)))or '정지 풀림'
        label(body,'UserHistory'..i,string.format('%s  %s  %s',h.start:sub(1,10),kind,h.reason),13,C.muted,0,y,w,20);y+=22
    end;y+=4 end
    local cw=math.floor((w-24)/4)
    for i,d in ipairs(Rules.banOrder)do chip(body,'BanFor'..d,Rules.banLabel[d],st.duration==d,function()st.duration=d;st.armed=nil;draw()end,(i-1)*(cw+8),y,cw)end
    y+=56
    local rw=math.max(150,math.floor((w-16)/3));local cols=math.max(1,math.floor((w+8)/(rw+8)));rw=math.floor((w-(cols-1)*8)/cols)
    for i,r in ipairs(Rules.reasons)do local b=chip(body,'BanWhy'..r.id,r.ko,st.reason==r.id,function()st.reason=r.id;st.armed=nil;draw()end,(i-1)%cols*(rw+8),y+math.floor((i-1)/cols)*56,rw);b.TextTruncate=Enum.TextTruncate.AtEnd end
    y+=math.ceil(#Rules.reasons/cols)*56
    input(body,'BanNote',st.note,'메모 (운영자만 봐요)',0,y,w,function(t)st.note=t end);y+=56
    local third=math.floor((w-16)/3)
    button(body,'UserKick','내보내기',function()call('kick',{userId=u.id})end,0,y,third)
    local armed=st.armed==u.id
    button(body,'UserBan',armed and string.format('%s 정지 확인',Rules.banLabel[st.duration])or '정지',function()
        if not armed then st.armed=u.id;st.last={ok=true,text=string.format('한 번 더 누르면 %s를 %s 정지해요.',u.name,Rules.banLabel[st.duration])};draw();return end
        st.armed=nil;call('ban',{userId=u.id,duration=st.duration,reason=st.reason,note=st.note},function(res)if res.ok then st.note='';call('lookup',{query=tostring(u.id)},function(r2)st.user=r2.ok and r2.user or st.user end)end end)
    end,third+8,y,third,48,false,C.danger)
    button(body,'UserUnban','정지 풀기',function()call('unban',{userId=u.id},function(res)if res.ok then call('lookup',{query=tostring(u.id)},function(r2)st.user=r2.ok and r2.user or st.user end)end end)end,(third+8)*2,y,w-(third+8)*2)
    return y+56
end
draw=function()
    local gui=st.gui;if not gui or not st.open then return end
    local panel=gui.Panel.Frame;local body=panel.Body
    for _,c in ipairs(body:GetChildren())do if not c:IsA('UIPadding')then c:Destroy()end end
    local w=math.floor(body.AbsoluteSize.X/math.max(.5,panel.Pop.Scale))-14;st.width=w
    local last=st.last
    panel.Note.Text=st.busy and '처리 중이에요.'or last and ((last.ok and '✓ 'or '✕ ')..last.text)or '운영자만 보는 화면이에요.'
    panel.Note.TextColor3=last and not st.busy and (last.ok and C.recruitmentGrow or C.danger)or C.muted
    local y=4
    y=section(body,'상태',y,w);y=statusBlock(body,y,w)+8
    y=section(body,'지금 공지',y,w);y=flashBlock(body,y,w)+8
    y=section(body,'유저 관리',y,w);y=userBlock(body,y,w)+8
    body.CanvasSize=UDim2.fromOffset(0,y)
end
local function close()
    if not st.gui or not st.open then return end
    st.open=false;local gui=st.gui
    Tween:Create(gui.Dim.Shade,TweenInfo.new(.14),{BackgroundTransparency=1}):Play()
    Tween:Create(gui.Panel.Frame.Pop,TweenInfo.new(.14,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Scale=.96}):Play()
    task.delay(.14,function()if not st.open then gui.Dim.Enabled=false;gui.Panel.Enabled=false end end)
end
local function build()
    local root=Players.LocalPlayer:WaitForChild('PlayerGui')
    local dim=UI.make('ScreenGui',root,{Name='OpsConsoleDim',ResetOnSpawn=false,DisplayOrder=72,IgnoreGuiInset=true,ScreenInsets=Enum.ScreenInsets.None,AutoLocalize=false,Enabled=false})
    require(script.Parent.FullBleed).watch(dim)
    local shade=UI.make('TextButton',dim,{Name='Shade',Text='',AutoButtonColor=false,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1)})
    shade.Activated:Connect(close)
    local holder=UI.make('ScreenGui',root,{Name='OpsConsole',ResetOnSpawn=false,DisplayOrder=73,ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets,AutoLocalize=false,Enabled=false})
    local panel=UI.panel(holder,'Frame');panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5);panel.BackgroundTransparency=.04
    panel.Size=UDim2.new(1,-24,1,-24);UI.make('UISizeConstraint',panel,{MaxSize=Vector2.new(620,760)})
    UI.make('UIScale',panel,{Name='Pop',Scale=.96})
    local band=require(script.Parent.EdgeMask).fit(UI.make('Frame',panel,{Name='Band',BackgroundColor3=C.gold,BorderSizePixel=0,Size=UDim2.new(1,0,0,3),Active=false}))
    local title=UI.label(panel,'Title','운영',20,C.ink);UI.box(title,16,12,200,30);UI.display(title);title.AutoLocalize=false
    local x=UI.button(panel,'OpsClose','✕',close);x.AnchorPoint=Vector2.new(1,0);x.Position=UDim2.new(1,-8,0,8);x.Size=UDim2.fromOffset(48,48);x.TextSize=18
    local note=UI.make('TextLabel',panel,{Name='Note',Text='',TextSize=13,Font=Enum.Font.BuilderSansBold,TextColor3=C.muted,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,
        TextWrapped=true,Position=UDim2.fromOffset(16,56),Size=UDim2.new(1,-32,0,34)})
    note.AutoLocalize=false
    local body=UI.make('ScrollingFrame',panel,{Name='Body',BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(16,96),Size=UDim2.new(1,-24,1,-104),ScrollBarThickness=6,
        ScrollBarImageColor3=C.line,CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y})
    UI.make('UIPadding',body,{PaddingRight=UDim.new(0,8)})
    body:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
        if st.open and math.abs(math.floor(body.AbsoluteSize.X/math.max(.5,panel.Pop.Scale))-14-(st.width or 0))>2 then draw()end
    end)
    band.Active=false
    st.gui={Dim=dim,Panel=holder}
end
function M.open()
    if Players.LocalPlayer:GetAttribute('OpsAdmin')~=true then return end
    if not st.gui then build()end
    st.open=true;st.last=nil;st.armed=nil;local gui=st.gui
    gui.Dim.Enabled=true;gui.Panel.Enabled=true
    gui.Dim.Shade.BackgroundTransparency=1;Tween:Create(gui.Dim.Shade,TweenInfo.new(.18),{BackgroundTransparency=.35}):Play()
    gui.Panel.Frame.Pop.Scale=.96;Tween:Create(gui.Panel.Frame.Pop,TweenInfo.new(.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
    Step.step('ops','console',{item='open',result='shown'})
    task.defer(draw);refresh()
end
M.close=close
function M.toggle()if st.open then close()else M.open()end end
return M
