local UI=require(script.Parent.Theme)
local Style=require(script.Parent.HudStyle)
local Icons=require(script.Parent.OutgameIcons)
local Rules=require(script.Parent.Parent.Core.MatchRulesSummary)
local Step=require(script.Parent.TelemetryStep)
local C=UI.colors
local M={}
local function tracked(id,fn)return fn and function(...)Step.step('match','menuTile',{item=id});return fn(...)end end
local function touch()return require(script.Parent.InputMode).touch()end
local function chipLabel(parent,text,x)
    local t=UI.label(parent,'Chip',text,13,C.ink);t.TextXAlignment=Enum.TextXAlignment.Center;t.TextWrapped=false;t.Font=Enum.Font.BuilderSansBold
    t.BackgroundColor3=Style.colors.cell;t.BackgroundTransparency=0;Style.round(t,10);t.ZIndex=parent.ZIndex+2
    local cw=math.max(48,t.TextBounds.X+18);t.AnchorPoint=Vector2.new(1,.5);t.Position=UDim2.new(1,-(x or 10),.5,0);t.Size=UDim2.fromOffset(cw,24);return t
end
local function danger(b)
    b.TextColor3=C.danger;b.BackgroundColor3=C.danger:Lerp(Style.colors.panel,.86);Style.round(b,8);Style.line(b,C.danger,1.5)
end
local function primary(b)b.TextSize=18;Style.round(b,8)end

local function v2()local ok,H=pcall(require,script.Parent.Hud20);return ok and type(H)=='table'and H.ENABLED==true end
M.v2=v2
local K
function M.modeText(state)
    if not state then return ''end
    local L=require(script.Parent.Localization)
    local ladder=state.ranked=='2v2'and '랭크 2대2'or state.ranked=='1v1'and '랭크 1대1'or state.ranked=='ffa'and '랭크 개인전'or nil
    local cw=type(state.clanwar)=='table'and state.clanwar or {size=2,count=2}
    local war=state.clanwar and ((cw.count or 2)>2 and string.format('클랜전 %d파전 %d인',cw.count,cw.size or 2)or string.format('클랜전 %d대%d',cw.size or 2,cw.size or 2))
    local mode=war or state.queueMode=='custom'and '커스텀'or (state.ranked or state.queueMode=='ranked')and (ladder or '랭크')or state.multiplayer and '공식 전장'or '혼자 하기'
    local difficulty=not(state.clanwar or state.ranked or state.queueMode=='ranked')and require(script.Parent.Parent.Core.MatchOptions).difficultyLabels[(state.settings or {}).difficulty]or ''
    return L.text(mode)..(difficulty~=''and ' '..L.text(difficulty)or '')
end
local function sheet()return require(script.Parent.MatchSheet)end
local function size20(w,h,inset)
    local t=touch();local Placement=require(script.Parent.Parent.Core.InterfacePlacement)
    local fmt=(not t or Placement.tablet(w,h,t))and 'pc'or h>w and 'pt'or 'ph'
    local screenH=h+inset
    if fmt=='pc'then return fmt,math.min(440,w-24),math.min(440,screenH-24)end
    if fmt=='ph'then return fmt,math.min(420,w-24),screenH-16 end
    return fmt,w-24,math.min(460,screenH-24)
end
function M.draw20(ctx)
    K=K or require(script.Parent.Kit20)
    local body,s,a=ctx.body,ctx.state,ctx.act;local C2=K.colors
    M.ctx20=ctx;M.affiliation20={on=ctx.altView==true,toggle=a.affiliation}
    if body.Parent and body.Parent.Parent then M.watch20(body.Parent.Parent,body.Parent)end
    local cam=body.Parent and body.Parent.Parent and body.Parent.Parent.AbsoluteSize/(UI.scale or 1)or Vector2.new(1366,768)
    local inset=0;pcall(function()inset=game:GetService('GuiService'):GetGuiInset().Y/(UI.scale or 1)end)
    local fmt,cw=size20(cam.X,cam.Y,inset)
    local w=cw-34;local y=0;local ph=fmt=='ph'
    for _,o in ipairs(body:GetChildren())do if not o:IsA('UIPadding')then o:Destroy()end end
    local resume=K.button(body,'Resume',{kind='pri',text='계속 플레이',size=18,weight=800},tracked('Resume',a.resume))
    resume:place(0,y,w,ph and 48 or 56);sheet().fill20(resume);y+=(ph and 48 or 56)+10
    local tiles={
        {'Guide','플레이 방법','info',a.guide},
        {'Settings','설정','settings',a.settings},
        {'Ranks','순위','records',a.ranks},
        {'Diplomacy','외교','Alliance',a.diplomacy},
        {'World','전체 지도','map',a.world},
        {'Home','내 지휘관','locate',a.home},
    }
    if s.multiplayer and s.canPause then table.insert(tiles,{'HostPause',s.paused and '모두 재개'or '모두 일시정지','clock',a.hostPause})end
    local cols=ph and 3 or 2;local gap=8;local tw=math.floor((w-gap*(cols-1))/cols);local th=ph and 50 or 58
    for i,tile in ipairs(tiles)do
        local col=(i-1)%cols;local row=(i-1)//cols
        local b=K.button(body,tile[1],{kind='plain',text=tile[2],size=14,weight=800,icon=tile[3]~='Alliance'and tile[3]or 'info',iconSize=18,gap=8},tracked(tile[1],tile[4]))
        if tile[3]=='Alliance'then
            b.iconImage:Destroy();b.iconImage=require(script.Parent.HotbarIcons).create(b.face,'Alliance',18,C2.muted);b.iconImage.Name='Icon'
        end
        b.iconColorFixed=true;if b.iconImage:IsA('ImageLabel')then b.iconImage.ImageColor3=C2.muted end;b.iconImage.ZIndex=b.face.ZIndex+1
        b:place(col*(tw+gap),y+row*(th+gap),tw,th);b:layoutContent('left',13);sheet().fill20(b,13)
        if tile[1]=='Diplomacy'then K.dot(b.face,'Dot20',(ctx.inboxCount or 0)>0,tw-14,14,8)end
    end
    y+=math.ceil(#tiles/cols)*(th+gap)-gap+10
    if ctx.rulesOpen then
        local lines=Rules.lines(s.settings)
        local l=K.text(body,'Rules',#lines>0 and table.concat(lines,'\n')or '클래식 규칙',13,C2.muted,600);l.TextWrapped=true;l.TextYAlignment=Enum.TextYAlignment.Top
        local hgt=math.max(1,#lines)*18+4;K.box(l,4,y,w-8,hgt);y+=hgt+10
    end
    local leave=K.button(body,'Leave',{kind='plain',text='로비로 나가기',size=15,weight=800},tracked('Leave',a.leave))
    leave:place(0,y,w,ph and 44 or 52);sheet().fill20(leave);y+=ph and 44 or 52
    body.CanvasSize=UDim2.fromOffset(0,y+2);M.content20=y
    return y
end
local OWN={pause=true,leave=true,demolish=true,feedback=true,help=true}
local CONFIRM={leave=true,demolish=true}
function M.frame20(f)
    if not v2()then return end
    K=K or require(script.Parent.Kit20)
    local card,modal=f.card,f.modal
    if not modal.Visible or f.mode==nil then return end
    local inMatch=f.state~=nil and f.state.phase~='menu'
    local own=OWN[f.mode]==true and inMatch
    local bleed=modal:FindFirstChild('Bleed20')
    if own and not bleed then
        bleed=K.make('Frame',modal,{Name='Bleed20',BackgroundColor3=Color3.fromRGB(4,7,11),BackgroundTransparency=.34,BorderSizePixel=0,ZIndex=0,Active=false,
            Position=UDim2.new(0,-200,0,-200),Size=UDim2.new(1,400,1,400)})
    end
    if bleed then bleed.Visible=own end
    modal.BackgroundTransparency=own and 1 or .34
    local close=card:FindFirstChild('Close20')
    local corner=card:FindFirstChildOfClass('UICorner')
    if not own then
        if close then close.Visible=false end;f.close.Visible=true
        local chip=card:FindFirstChild('Mode20');if chip then chip.Visible=false end
        if f.mode~=nil and modal.Visible and card:GetAttribute('V1Alpha')~=nil then
            card.BackgroundColor3=card:GetAttribute('V1Color');card.BackgroundTransparency=card:GetAttribute('V1Alpha');card:SetAttribute('V1Alpha',nil)
            if corner then corner.CornerRadius=UDim.new(card:GetAttribute('V1CornerScale')or 0,card:GetAttribute('V1CornerOffset')or 3)end
            for _,s in ipairs(card:GetChildren())do if s:IsA('UIStroke')then s.Enabled=s.Name~='Stroke20'end end
        end
        return
    end
    M.watch20(modal,card)
    if card:GetAttribute('V1Alpha')==nil then
        card:SetAttribute('V1Alpha',card.BackgroundTransparency);card:SetAttribute('V1Color',card.BackgroundColor3)
        if corner then card:SetAttribute('V1CornerScale',corner.CornerRadius.Scale);card:SetAttribute('V1CornerOffset',corner.CornerRadius.Offset)end
    end
    for _,s in ipairs(card:GetChildren())do if s:IsA('UIStroke')and s.Name~='Stroke20'then s.Enabled=false end end
    card.BackgroundColor3=Color3.fromRGB(12,17,24);card.BackgroundTransparency=0;K.round(card,12);K.stroke(card,K.colors.line,1,.1,true).Enabled=true
    card.ZIndex=math.max(card.ZIndex,2)
    if not close then
        M.close20=K.button(card,'Close20',{kind='none',icon='x',iconSize=18},function()if M.ctx20 and M.ctx20.act then M.ctx20.act.resume()end end)
        M.close20.iconColorFixed=true;M.close20.iconImage.ImageColor3=K.colors.muted;close=M.close20.button
    end
    if f.mode~='pause'then
        local chip=card:FindFirstChild('Mode20');if chip then chip.Visible=false end
        if CONFIRM[f.mode]and M.confirmH then
            f.close.Visible=false;close.Visible=false
            local inset=0;pcall(function()inset=game:GetService('GuiService'):GetGuiInset().Y/(UI.scale or 1)end)
            local cw=card.Size.X.Offset;local ch=53+M.confirmH+12
            K.box(card,math.floor((f.w-cw)/2),math.floor((f.h+inset-ch)/2-inset),cw,ch);K.box(f.body,15,51,cw-30,ch-51-12)
            return
        end
        f.close.Visible=false;close.Visible=true;close.ZIndex=card.ZIndex+3
        M.close20:place(card.Size.X.Offset-49,5,44,44)
        return
    end
    local inset=0;pcall(function()inset=game:GetService('GuiService'):GetGuiInset().Y/(UI.scale or 1)end)
    local _,cw,ch=size20(f.w,f.h,inset)
    if M.content20 then ch=math.min(f.h+inset-16,53+M.content20+16)end
    local x=math.floor((f.w-cw)/2);local y=math.floor((f.h+inset-ch)/2-inset)
    K.box(card,x,y,cw,ch)
    f.title.Text='메뉴';f.title.TextSize=20;if K.fonts[800]then f.title.FontFace=K.fonts[800]end;f.title.TextXAlignment=Enum.TextXAlignment.Left
    local L=require(script.Parent.Localization)
    local titleW=K.width(L.text('메뉴'),20,f.title);K.box(f.title,17,1,titleW+4,52)
    f.close.Visible=false;close.Visible=true;close.ZIndex=card.ZIndex+3
    M.close20:place(cw-49,5,44,44)
    local chip=card:FindFirstChild('Mode20')
    local text=M.modeText(f.state)
    if not chip then
        local b=K.button(card,'Mode20',{kind='none',text=text,size=12,weight=700,hit=44},function()if M.ctx20 and M.ctx20.act and M.ctx20.act.toggleRules then M.ctx20.act.toggleRules()end end)
        b.face.BackgroundTransparency=0;b.face.BackgroundColor3=K.colors.raised;K.round(b.face,4);b.label.TextColor3=K.colors.muted
        chip=b.button;M.chip20=b
    end
    local b=M.chip20;b:setText(text)
    local tw=K.width(L.text(text),12,b.label)+12;local left=17+titleW;local right=cw-49
    b:place(math.floor(left+(right-left-tw)/2),15,tw,24);sheet().fill20(b);chip.Visible=true;chip.ZIndex=card.ZIndex+3
    K.box(f.body,15,51,cw-30,ch-51-14);K.scrollPad(f.body,2)
end
function M.watch20(modal,card)
    if modal:GetAttribute('Watch20')then return end;modal:SetAttribute('Watch20',true)
    local Tween=game:GetService('TweenService')
    modal:GetPropertyChangedSignal('Visible'):Connect(function()
        if not v2()or K.reduced then return end
        local bleed=modal:FindFirstChild('Bleed20');if not(bleed and bleed.Visible)then return end
        if modal.Visible then
            local s=card:FindFirstChild('Pop20')or K.make('UIScale',card,{Name='Pop20'});s.Scale=.96
            Tween:Create(s,TweenInfo.new(.16,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),{Scale=1}):Play()
            K.fade(card,false,0);K.fade(card,true,.16,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out)
            bleed.BackgroundTransparency=1;Tween:Create(bleed,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=.34}):Play()
        else
            local ghost=K.make('Frame',modal.Parent,{Name='MenuGhost20',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=modal.ZIndex,Active=false})
            local b2=bleed:Clone();b2.Parent=ghost;local c2=card:Clone();c2.Parent=ghost
            for _,o in ipairs(c2:GetDescendants())do if o:IsA('GuiButton')then o.Active=false end end
            local s=c2:FindFirstChild('Pop20')or K.make('UIScale',c2,{Name='Pop20'})
            Tween:Create(s,TweenInfo.new(.10,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Scale=.96}):Play()
            K.fade(c2,false,.10)
            task.delay(.08,function()Tween:Create(b2,TweenInfo.new(.10,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{BackgroundTransparency=1}):Play()end)
            task.delay(.2,function()ghost:Destroy()end)
        end
    end)
end
function M.draw(ctx)
    if v2()then return M.draw20(ctx)end
    local body,s,a=ctx.body,ctx.state,ctx.act
    local w=math.max(240,ctx.width)-14;local y=0;local t=touch();local compact=ctx.compact==true
    if not compact and not s.multiplayer then local d=UI.label(body,'Description','Ⅱ  일시정지',13,C.gold);d.Font=Enum.Font.BuilderSansBold;UI.box(d,4,y,w,22);y+=30 end
    local resume=UI.button(body,'Resume','계속 플레이',tracked('Resume',a.resume),true);UI.box(resume,4,y,w,compact and 48 or t and 52 or 56);primary(resume);y+=resume.Size.Y.Offset+(compact and 8 or 12)
    local tiles={
        {'Guide','플레이 방법','missions',a.guide},
        {'Settings','설정','settings',a.settings},
        {'Ranks','순위','ranked',a.ranks},
        {'Diplomacy','외교','friends',a.diplomacy,(ctx.inboxCount or 0)>0 and string.format('요청 %d',ctx.inboxCount)or nil},
        {'World','전체 지도','fields',a.world},
        {'Home','내 지휘관으로','deploy',a.home},
        {'Affiliation','소속 보기','marshal',a.affiliation,ctx.altView and '켜짐'or '꺼짐'},
    }
    if s.multiplayer and s.canPause then table.insert(tiles,{'HostPause',s.paused and '모두 재개'or '모두 일시정지','daily',a.hostPause,'방장'})end
    local cols=compact and (ctx.width>=560 and 4 or 3)or t and ctx.width>=520 and 3 or 2;local gap=8;local tw=(w-gap*(cols-1))/cols;local th=48
    for i,tile in ipairs(tiles)do
        local b=UI.button(body,tile[1],tile[2],tracked(tile[1],tile[4]));local col=(i-1)%cols;local row=(i-1)//cols
        UI.box(b,4+col*(tw+gap),y+row*(th+gap),tw,th);b.TextSize=compact and 13 or 14;b.TextXAlignment=Enum.TextXAlignment.Left
        b.BackgroundColor3=Style.colors.chip;Style.round(b,8);Style.line(b,Style.colors.line,1)
        local pl=compact and 38 or 44;UI.make('UIPadding',b,{PaddingLeft=UDim.new(0,pl),PaddingRight=UDim.new(0,tile[5]and (compact and 52 or 72)or 8)})
        local icon=Icons.create(b,tile[3],20,C.ink);UI.box(icon,12-pl,(th-20)/2,20,20)
        b.TextTruncate=Enum.TextTruncate.AtEnd;b.TextWrapped=false
        if tile[5]then local inset=compact and 46 or 62;local chip=chipLabel(b,tile[5],-inset);chip.Position=UDim2.new(1,inset,.5,0);if compact then chip.Size=UDim2.fromOffset(40,24)end end
    end
    y+=math.ceil(#tiles/cols)*(th+gap)+4
    local lines=Rules.lines(s.settings)
    local rules=UI.button(body,'RulesToggle',#lines>0 and string.format(ctx.rulesOpen and '이번 판 규칙 %d개 접기'or '이번 판 규칙 %d개 ›',#lines)or (ctx.rulesOpen and '이번 판 규칙 클래식 접기'or '이번 판 규칙 클래식 ›'),tracked('RulesToggle',a.toggleRules));UI.box(rules,4,y,compact and w/2-8 or w,48)
    rules.BackgroundTransparency=1;rules.TextXAlignment=Enum.TextXAlignment.Left;rules.TextSize=14;rules.TextColor3=C.muted;rules.TextTruncate=Enum.TextTruncate.AtEnd
    local edge=rules:FindFirstChildOfClass('UIStroke');if edge then edge.Enabled=false end
    local leave=UI.button(body,'Leave','로비로 나가기',tracked('Leave',a.leave));danger(leave)
    if compact then UI.box(leave,w/2+4,y,w/2,48);y+=56 else y+=52 end
    if ctx.rulesOpen then
        local l=UI.label(body,'Rules',#lines>0 and table.concat(lines,'\n')or '클래식 규칙',13,C.muted);UI.box(l,8,y,w-8,math.max(1,#lines)*20+4);l.TextYAlignment=Enum.TextYAlignment.Top
        y+=math.max(1,#lines)*20+12
    end
    if not compact then
        local rule=UI.make('Frame',body,{Name='ExitRule',BackgroundColor3=C.line,BorderSizePixel=0});UI.box(rule,4,y,w,1);y+=13
        UI.box(leave,4,y,w,48);y+=56
    end
    body.CanvasSize=UDim2.fromOffset(0,y);return y
end
function M.confirm(body,width,text,safe,safeFn,risky,riskyFn,names)
    local w=math.max(240,width)-14
    local bw=(w-10)/2;local bh=touch()and 52 or 48
    if v2()then
        K=K or require(script.Parent.Kit20)
        local y=12
        if text and text~=''then local d=K.text(body,'Description',text,13,C.muted,600);d.TextWrapped=true;d.TextTruncate=Enum.TextTruncate.None;K.box(d,4,4,w,20);y=36 end
        local a=K.button(body,names and names[1]or 'Cancel',{kind='pri',text=safe,size=16},safeFn);a:place(4,y,bw,bh);sheet().fill20(a)
        local b=K.button(body,names and names[2]or 'Confirm',{kind='plain',text=risky,size=16},riskyFn);b:place(14+bw,y,bw,bh);sheet().fill20(b)
        M.confirmH=y+bh+4;body.CanvasSize=UDim2.fromOffset(0,M.confirmH);return M.confirmH
    end
    local d=UI.label(body,'Description',text,14,C.muted);d.TextYAlignment=Enum.TextYAlignment.Top;UI.box(d,4,0,w,64)
    local a=UI.button(body,names and names[1]or 'Cancel',safe,safeFn,true);UI.box(a,4,76,bw,bh);Style.round(a,8)
    local b=UI.button(body,names and names[2]or 'Confirm',risky,riskyFn);UI.box(b,14+bw,76,bw,bh);danger(b)
    body.CanvasSize=UDim2.fromOffset(0,76+bh+4);return 76+bh+4
end
function M.settings(ctx)
    local body=ctx.body;local w=math.max(260,ctx.width)-14;local y=0;local shop=ctx.shop;local prefs=ctx.prefs or {}
    local busy=not ctx.ready or shop and shop.busy
    local function section(text)local l=UI.label(body,'Section'..y,text,13,require(script.Parent.MatchSheet).SKY);l.Font=Enum.Font.BuilderSansBold;UI.box(l,4,y,w,24);y+=28 end
    local function line()local r=UI.make('Frame',body,{Name='Rule'..y,BackgroundColor3=Style.colors.line,BorderSizePixel=0});UI.box(r,4,y-5,w,1)end
    local function toggle(key,title,hint,on,fn)
        local h=hint and 52 or 44
        local l=UI.label(body,key..'Title',title,15,C.ink);l.Font=Enum.Font.BuilderSansBold;UI.box(l,4,y+(hint and 4 or 0),w-80,hint and 22 or h)
        if hint then local s=UI.label(body,key..'Hint',hint,13,C.muted);UI.box(s,4,y+26,w-80,20)end
        local b=UI.button(body,'Toggle_'..key,'',fn);UI.box(b,w-64,y+(h-48)/2,68,48);b.BackgroundTransparency=1;local st=b:FindFirstChildOfClass('UIStroke');if st then st.Enabled=false end
        local track=UI.make('Frame',b,{Name='Track',BackgroundColor3=on and C.accent or Style.colors.cell,BorderSizePixel=0,ZIndex=b.ZIndex+1});UI.box(track,10,12,48,24);Style.round(track,12);Style.line(track,on and C.accent or Style.colors.line,1)
        local knob=UI.make('Frame',track,{Name='Knob',BackgroundColor3=on and C.bg or C.muted,BorderSizePixel=0,ZIndex=b.ZIndex+2});UI.box(knob,on and 28 or 4,4,16,16);Style.round(knob,8)
        b:SetAttribute('On',on==true);UI.enabled(b,not busy or key=='players'or key=='affiliation');y+=h+10;line()
    end
    local function segmented(key,title,items,current,fn)
        local l=UI.label(body,key..'Title',title,15,C.ink);l.Font=Enum.Font.BuilderSansBold;UI.box(l,4,y,w*.35,44)
        local narrow=w<#items*72+120;if narrow then y+=44 end
        local sw=narrow and w or math.min(w*.62,#items*86);local seg=UI.make('Frame',body,{Name=key,BackgroundColor3=Style.colors.chip,BorderSizePixel=0});UI.box(seg,w-sw+4,y-4,sw,52);Style.round(seg,8);Style.line(seg,Style.colors.line,1)
        for i,it in ipairs(items)do
            local on=current==it[1]
            local b=UI.button(seg,key..'_'..tostring(it[1]),it[2],function()fn(it[1])end);UI.box(b,2+(i-1)*(sw-4)/#items,2,math.floor((sw-4)/#items-2),48);b.TextSize=14;Style.round(b,6)
            b.BackgroundColor3=on and Style.colors.cell:Lerp(C.ink,.14)or Style.colors.chip;b.BackgroundTransparency=on and 0 or 1;b.TextColor3=on and C.ink or C.muted
            local st=b:FindFirstChildOfClass('UIStroke');if st then st.Enabled=false end;if key~='Language'then UI.enabled(b,not busy)end
        end
        y+=60;line()
    end
    local function pref(key,value)if shop then shop:run(function()shop:request('preference',key,value)end)end end
    section('화면')
    toggle('reducedEffects','간소한 이펙트',nil,prefs.reducedEffects==true,function()pref('reducedEffects',not prefs.reducedEffects)end)
    toggle('cameraShake','화면 흔들림',nil,prefs.cameraShake~=false,function()pref('cameraShake',prefs.cameraShake==false)end)
    toggle('mapFlashes','지도 번쩍임',nil,prefs.mapFlashes~=false,function()pref('mapFlashes',prefs.mapFlashes==false)end)
    segmented('HudOpacity','패널 배경',{{1,'100%'},{.75,'75%'},{.5,'50%'},{.25,'25%'}},prefs.hudOpacity or 1,function(v)
        if v==(prefs.hudOpacity or 1)then return end
        Step.step('settings','hudOpacity',{value=v*100});pref('hudOpacity',v)
    end)
    section('소리와 언어')
    local volume=prefs.soundsMuted and 'off'or prefs.sfxVolume or 1
    segmented('SoundVolume','효과음',{{'off','끔'},{.5,'작게'},{1,'보통'},{1.5,'크게'}},volume,function(v)
        if not shop or v==volume then return end
        shop:run(function()
            if v=='off'then shop:request('preference','soundsMuted',true);return end
            shop:request('preference','sfxVolume',v)
            if ctx.play then ctx.play('confirm')end
        end)
    end)
    segmented('Language','언어',{{'auto','자동'},{'ko-kr','한국어'},{'en-us','English'}},ctx.language or 'auto',function(v)ctx.setLanguage(v)end)
    if not ctx.lobby then
        local aff=v2()and M.affiliation20
        if aff and aff.toggle then
            toggle('affiliation','소속 보기',nil,aff.on,function()aff.on=not aff.on;aff.toggle();if ctx.redraw then ctx.redraw()end end)
        end
        local ok,on=pcall(function()return game.StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)end)
        toggle('players','Roblox 접속자 목록',nil,ok and on,function()
            pcall(function()game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,not game.StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList))end)
            Step.step('settings','playerList',{});if ctx.redraw then ctx.redraw()end
        end)
    else
        local credits=UI.button(body,'Credits','크레딧과 라이선스',ctx.credits);UI.box(credits,4,y,w,48);credits.BackgroundColor3=Style.colors.chip;Style.round(credits,8);y+=56
    end
    body.CanvasSize=UDim2.fromOffset(0,y);return y
end
function M.help(ctx)
    if ctx.tab=='buildings'then
        local w=math.max(260,ctx.width)-14
        local back=UI.button(ctx.body,'HelpBack','‹ 한눈에 보기',function()ctx.setTab('basic')end);UI.box(back,4,0,160,44);Style.round(back,8)
        local y=M.catalog(ctx.body,52,w,ctx.style);ctx.body.CanvasSize=UDim2.fromOffset(0,y);return y
    end
    return require(script.Parent.HelpSheet).draw(ctx)
end
function M.catalog(body,y,w,style)
    local Catalog=require(script.Parent.BuildingCatalog);local Models=require(script.Parent.BuildingModels);local look=require(script.Parent.Parent.Core.CosmeticCatalog).get(style)
    for _,e in ipairs(Catalog)do
        local f=UI.make('Frame',body,{Name='Building'..e.kind,BackgroundColor3=Style.colors.chip,BorderSizePixel=0});UI.box(f,4,y,w,132);Style.round(f,10);Style.line(f,Style.colors.line,1)
        local p=Models.preview(f,e.kind,look);UI.box(p,8,8,104,116)
        local n=UI.label(f,'Name',e.name,15,C.ink);n.Font=Enum.Font.BuilderSansBold;UI.box(n,124,8,w-136,24)
        local r=UI.label(f,'Role',e.role,13,C.ink);r.TextYAlignment=Enum.TextYAlignment.Top;UI.box(r,124,34,w-136,38)
        local s=UI.label(f,'Status',e.ready and '현재 건설 가능'or '이 모드에선 불가',13,e.ready and C.good or C.muted);UI.box(s,124,74,w-136,20)
        local d=UI.label(f,'Story',e.detail or '',13,C.muted);d.TextTruncate=Enum.TextTruncate.AtEnd;d.TextYAlignment=Enum.TextYAlignment.Top;UI.box(d,124,96,w-136,32)
        y+=140
    end
    return y
end
return M
