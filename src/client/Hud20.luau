local K=require(script.Parent.Kit20)
local Icons=require(script.Parent.HotbarIcons)
local Tween=game:GetService('TweenService')
local C=K.colors
local M={}
M.ENABLED=true
M.PRESETS={.1,.2,.5,1}
local GLASS=Color3.fromRGB(12,17,24);local BAND=Color3.fromRGB(9,13,18);local GOLD_BG=Color3.fromRGB(28,26,18)
local FILL_A,FILL_B=Color3.fromRGB(36,184,169),C.accent

local function parts(cb)
    if cb.v2 then return cb.v2 end
    local e=cb.e;local c=e.controls;local v={}
    cb.v2=v
    v.seg=K.make('Frame',c,{Name='Ratio20',BackgroundColor3=C.bg,BorderSizePixel=0,ZIndex=3,Visible=false});K.round(v.seg,8);v.segStroke=K.stroke(v.seg,C.line,1,0,true)
    v.on=K.make('Frame',v.seg,{Name='On',AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=C.ink,BorderSizePixel=0,ZIndex=4});K.round(v.on,6)
    v.press=K.make('UIScale',v.on,{Name='Press20'})
    local s=e.dispatchSlider;local down=false
    local function to(goal,t,style)
        if v.pressTween then v.pressTween:Cancel();v.pressTween=nil end
        if K.reduced then v.press.Scale=1;return end
        v.pressTween=Tween:Create(v.press,TweenInfo.new(t,style or Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=goal});v.pressTween:Play()
    end
    local function press(i)return i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch end
    s.MouseEnter:Connect(function()if v.seg.Visible and not require(script.Parent.InputMode).touch()then v.segStroke.Color=C.muted end end)
    s.MouseLeave:Connect(function()v.segStroke.Color=C.line end)
    s.InputBegan:Connect(function(i)if press(i)and v.seg.Visible then down=true;to(.96,.05)end end)
    game:GetService('UserInputService').InputEnded:Connect(function(i)
        if not down or not press(i)then return end
        down=false;if K.reduced then v.press.Scale=1;return end
        if v.pressTween then v.pressTween:Cancel()end;v.press.Scale=1.02;to(1,.12,Enum.EasingStyle.Back)
    end)
    v.cells={}
    for i,p in ipairs(M.PRESETS)do
        local l=K.text(v.seg,'P'..i,math.floor(p*100)..'%',12,C.muted,700,Enum.TextXAlignment.Center);l.ZIndex=5;l:SetAttribute('LocalizationSkip',true)
        v.cells[i]=l
    end
    v.line=K.make('Frame',c,{Name='BandLine',BackgroundColor3=C.line,BackgroundTransparency=.2,BorderSizePixel=0,ZIndex=3,Visible=false})
    v.troopText=e.statsTroops
    return v
end
local function hideOld(cb)
    local e=cb.e
    for _,o in ipairs(cb.decor)do o.Visible=false end
    for _,p in ipairs(cb.presets)do p.root.Visible=false end
    for _,m in ipairs(cb.marks or {})do m.Visible=false end
    if cb.strip then cb.strip.Visible=false end;if cb.rateCell then cb.rateCell.Visible=false end
    if cb.touchGold then cb.touchGold.Visible=false end;if cb.growthSurface then cb.growthSurface.Visible=false end
    e.statsLand.Visible=false;e.statsGoldSub.Visible=false;e.troopIcon.Visible=false;e.dispatchIcon.Visible=false;e.goldIcon.Visible=false;e.dockDivider.Visible=false
    e.selectedInfo.Visible=false;e.troopWatermark.Visible=false;e.filledWatermark.Visible=false;e.filledTroops.Visible=false
    e.growthFace.Visible=false;e.growthIcon.Visible=false;e.growthArrow.Visible=false;cb.soldier.Visible=false
    if cb.uiScale then cb.uiScale.Scale=1 end
end
local function oneEdge(cb,pc)
    local e=cb.e;local first=true
    for _,o in ipairs(e.controls:GetChildren())do if o:IsA('UIStroke')then
        if first and pc then o.Enabled=true;o.Color=C.line;o.Transparency=.1;o.Thickness=1 else o.Enabled=false end
        first=false
    end end
    for _,o in ipairs(e.hud:GetChildren())do if o:IsA('UIStroke')then o.Enabled=false end end
end
local function controlsRow(cb,fmt,ty,troopX,troopW,segX,segW,goldX,goldW,rowH)
    local e=cb.e;local v=parts(cb)
    local fs=fmt=='ph'and 12 or 13;local rs=11;local is=fmt=='ph'and 13 or 14
    local track=e.troopBar;K.box(track,troopX,ty,troopW,rowH);track.ClipsDescendants=false
    track:SetAttribute('V2',true);K.round(track,8)
    local ts=track:FindFirstChildOfClass('UIStroke');if ts then ts.Enabled=false end
    local fill=track:FindFirstChild('Fill');if fill then fill.BackgroundTransparency=1;local g=fill:FindFirstChild('HudFill');if g then g.Enabled=false end end
    cb.barSoldier.Visible=true;K.box(cb.barSoldier,fmt=='pt'and 10 or 7,math.floor((rowH-is)/2),is,is);cb.barSoldier.ZIndex=6
    local rateW=fmt=='ph'and 52 or 58
    local badge=e.growthBadge;K.box(badge,troopX+troopW-rateW-(fmt=='ph'and 7 or 7),ty,rateW,rowH);badge.ZIndex=7
    e.statsTroopsSub.Visible=true;e.statsTroopsSub.TextSize=rs;if K.fonts.num then e.statsTroopsSub.FontFace=K.fonts.num end
    e.statsTroopsSub.TextXAlignment=Enum.TextXAlignment.Right;K.box(e.statsTroopsSub,0,0,rateW,rowH);e.statsTroopsSub.ZIndex=8
    local nx=(fmt=='pt'and 10 or 7)+is+4
    local n=e.statsTroops;n.Visible=true;n.TextSize=fs;if K.fonts.num then n.FontFace=K.fonts.num end;n.TextColor3=C.ink
    n.TextXAlignment=Enum.TextXAlignment.Left;n.TextWrapped=false;n.ZIndex=6;n.TextStrokeColor3=Color3.new(0,0,0);n.TextStrokeTransparency=.6
    K.box(n,nx,0,troopW-nx-rateW-10,rowH)
    v.seg.Visible=true;K.box(v.seg,segX,ty,segW,rowH)
    local pad=3;local cw=(segW-pad*2-3*3)/4
    for i,l in ipairs(v.cells)do l.TextSize=fmt=='ph'and 11 or fmt=='pt'and 13 or 12;K.box(l,pad+(i-1)*(cw+3),pad,cw,rowH-pad*2)end
    v.cellW=cw;v.segH=rowH
    local s=e.dispatchSlider;s.Visible=true;s.ZIndex=6;K.box(s,segX,ty,segW,rowH)
    K.box(e.dispatchTrack,0,0,segW,rowH);e.dispatchTrack.BackgroundTransparency=1;e.dispatchKnob.Visible=false
    local df=e.dispatchTrack:FindFirstChild('Fill');if df then df.Visible=false end
    local gb=cb.goldBox;gb.Visible=true;gb.Parent=e.hud;K.box(gb,goldX,ty,goldW,rowH);K.round(gb,8)
    gb.BackgroundColor3=GOLD_BG;gb.BackgroundTransparency=0
    local gs=gb:FindFirstChildOfClass('UIStroke');if gs then gs.Color=C.gold;gs.Transparency=.45;gs.Thickness=1;cb.goldStroke=gs end
    cb.coin.Visible=false
    if not v.coin then v.coin=K.icon(gb,'coinGold',15,Color3.new(1,1,1),'Coin20')end
    v.coin.Visible=true
    local cs=fmt=='ph'and 14 or 15;local gx=fmt=='pc'and 12 or math.floor(goldW*.2)
    K.box(v.coin,gx,math.floor((rowH-cs)/2),cs,cs);v.coin.ZIndex=gb.ZIndex+1
    local gl=e.statsGold;gl.Parent=gb;gl.Visible=true;gl.TextSize=fs;if K.fonts.num then gl.FontFace=K.fonts.num end;gl.TextColor3=C.gold
    gl.TextXAlignment=Enum.TextXAlignment.Left;gl.TextWrapped=false;K.box(gl,gx+cs+4,0,goldW-gx-cs-6,rowH);gl.ZIndex=gb.ZIndex+1
    K.box(cb.gain,goldX,ty-22,goldW,18);cb.gain.Visible=true;cb.gainBase=cb.gain.Position;cb.gain.TextColor3=C.gold;if K.fonts.num then cb.gain.FontFace=K.fonts.num end;cb.gain.TextSize=13;cb.gain.TextXAlignment=Enum.TextXAlignment.Center
    M.dispatch(cb,cb.sendFraction or .2,true)
end

function M.pc(cb,w,h)
    local e=cb.e;hideOld(cb);parts(cb)
    cb.wide=true;cb.phone=false;cb.pcScale=1;cb.v2.fmt='pc'
    local W,H=460,84
    local touch=require(script.Parent.InputMode).touch();local s=touch and 1.25 or 1
    local c=e.controls;local sc=c:FindFirstChild('Tablet20')or K.make('UIScale',c,{Name='Tablet20'});sc.Scale=s
    local room=12+48*2+8+12
    local x=math.floor((w-W*s)/2);if x+W*s>w-room then x=math.max(12,math.floor(w-room-W*s))end
    K.box(c,x,math.floor(h-12-H*s),W,H);K.round(c,10);c.BackgroundColor3=GLASS;c.BackgroundTransparency=.10
    oneEdge(cb,true)
    cb.v2.line.Visible=false
    K.box(e.hud,0,0,W,40)
    controlsRow(cb,'pc',8,8,218,232,136,374,80,28)
    local d=e.dock;d.v2={kind='pc',cw=41,ch=36,cols=10,gap=4,touch=require(script.Parent.InputMode).touch()};d.compact=false;d.grid=false;d.bar=true;d.phone=false
    d:layout(8,42,W-16,false)
    e.pauseButton.Parent=c.Parent
    return {x=x,width=math.ceil(W*s),height=math.ceil(H*s)}
end
function M.phone(cb,w,h)
    local e=cb.e;hideOld(cb);parts(cb)
    cb.phone=true;cb.wide=false;cb.pcScale=1;cb.v2.fmt='ph'
    local sc=e.controls:FindFirstChild('Tablet20');if sc then sc.Scale=1 end
    local H=69
    local c=e.controls;K.box(c,0,h-H,w,H);K.round(c,0);c.BackgroundColor3=BAND;c.BackgroundTransparency=.08
    oneEdge(cb,false)
    local v=cb.v2;v.line.Visible=true;K.box(v.line,0,0,w,1)
    K.box(e.hud,0,0,w,H)
    local pad=12;local troopW=232;local goldW=96;local segX=pad+troopW+4;local goldX=w-pad-goldW
    controlsRow(cb,'ph',38,pad,troopW,segX,goldX-4-segX,goldX,goldW,26)
    local d=e.dock;d.v2={kind='ph',cw=(w-pad*2-9*4)/10,ch=30,cols=10,gap=4};d.compact=false;d.grid=false;d.bar=true;d.phone=true
    d:layout(pad,4,w-pad*2,true)
    e.pauseButton.Parent=c.Parent
    return {x=0,width=w,height=H}
end
function M.portrait(cb,w,h)
    local e=cb.e;hideOld(cb);parts(cb)
    cb.phone=false;cb.wide=false;cb.portrait=true;cb.pcScale=1;cb.v2.fmt='pt'
    local sc=e.controls:FindFirstChild('Tablet20');if sc then sc.Scale=1 end
    local d=e.dock;local open=d.compact==false
    local gridH=open and 2*52+6+8 or 0
    local H=96+gridH
    local c=e.controls;K.box(c,0,h-H,w,H);K.round(c,0);c.BackgroundColor3=BAND;c.BackgroundTransparency=.08
    oneEdge(cb,false)
    local v=cb.v2;v.line.Visible=true;K.box(v.line,0,0,w,1)
    K.box(e.hud,0,0,w,H)
    local pad=10;local goldW=96;local troopX=pad+50+6;local goldX=w-pad-goldW
    local r1=gridH+8
    controlsRow(cb,'pt',r1,troopX,goldX-6-troopX,pad,w-pad*2,goldX,goldW,36)
    K.box(v.seg,pad,r1+42,w-pad*2,36);local cw=(w-pad*2-6-9)/4
    for i,l in ipairs(v.cells)do K.box(l,3+(i-1)*(cw+3),3,cw,30)end;v.cellW=cw;v.segH=36
    K.box(e.dispatchSlider,pad,r1+42,w-pad*2,36);K.box(e.dispatchTrack,0,0,w-pad*2,36)
    d.v2={kind='pt',cw=(w-pad*2-4*6)/5,ch=52,cols=5,gap=6,toggle={x=pad,y=r1,w=50,h=36},open=open}
    d.bar=open;d.phone=true
    d:layout(pad,8,w-pad*2,true)
    e.pauseButton.Parent=c.Parent
    M.dispatch(cb,cb.sendFraction or .2,true)
    return {x=0,width=w,height=H}
end

function M.dispatch(cb,fraction,instant)
    local v=cb.v2;if not v or not v.cellW then return end
    local idx,best=1,math.huge
    for i,p in ipairs(M.PRESETS)do local d=math.abs(math.log(p)-math.log(math.max(.01,fraction)));if d<best then best=d;idx=i end end
    local exact=math.abs(M.PRESETS[idx]-fraction)<.005
    for i,l in ipairs(v.cells)do
        local on=i==idx
        l.Text=on and not exact and (math.floor(fraction*100+.5)..'%')or (math.floor(M.PRESETS[i]*100)..'%')
        l.TextColor3=on and C.bg or C.muted
    end
    local ow,oh=math.floor(v.cellW+.5),v.segH-6;local ax,ay=math.floor(ow/2),math.floor(oh/2)
    local goal=UDim2.fromOffset(math.floor(3+(idx-1)*(v.cellW+3)+.5)+ax,3+ay)
    v.on.AnchorPoint=Vector2.new(ax/math.max(1,ow),ay/math.max(1,oh));v.on.Size=UDim2.fromOffset(ow,oh)
    if instant or K.reduced or v.lastIdx==nil then v.on.Position=goal
    elseif v.lastIdx~=idx then Tween:Create(v.on,TweenInfo.new(.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=goal}):Play()end
    v.lastIdx=idx
    local sheet=cb.e.controls.Parent and cb.e.controls.Parent:FindFirstChild('ActionSheet')
    local n=sheet and sheet.Visible and sheet:FindFirstChild('Confirm')and sheet.Confirm:FindFirstChild('Num20')
    if n and n.Visible and cb.myTroops then n.Text=require(script.Parent.Theme).troops(fraction*cb.myTroops)end
end
function M.fraction(cb,x,width)
    local t=math.clamp(x/math.max(1,width),0,1)
    local centres={.125,.375,.625,.875}
    for i,cx in ipairs(centres)do if math.abs(t-cx)<=.25*.3 then return M.PRESETS[i]end end
    local stops={{0,.01},{.125,.1},{.375,.2},{.625,.5},{.875,1},{1,1}}
    for i=2,#stops do local a,b=stops[i-1],stops[i];if t<=b[1]then local f=a[2]+(t-a[1])/(b[1]-a[1])*(b[2]-a[2]);return math.clamp(math.floor(f*100+.5),1,100)/100 end end
    return 1
end
function M.update(cb,s)
    if not cb.v2 or not cb.v2.fmt then return end
    local e=cb.e;local trend=e.growthBadge:GetAttribute('Trend')
    local p=s and s.player
    local full=p and (tonumber(p.cap)or 0)>0 and (tonumber(p.troops)or 0)>=(tonumber(p.cap)or 0)*.999
    if full then
        local want='최대';if e.statsTroopsSub.Text~=want then e.statsTroopsSub.Text=want end
        e.statsTroopsSub.TextColor3=C.muted
    else
        local text=e.statsTroopsSub.Text:gsub('^[▲▼]%s*','')
        local arrow=trend=='rising'and '▲ 'or trend=='falling'and '▼ 'or ''
        local want=arrow..text;if e.statsTroopsSub.Text~=want then e.statsTroopsSub.Text=want end
        e.statsTroopsSub.TextColor3=trend=='falling'and C.recruitmentSlow or trend=='rising'and C.accent or C.muted
    end
    if p then local ratio=(tonumber(p.troops)or 0)/math.max(1,tonumber(p.cap)or 1);Icons.tint(cb.barSoldier,ratio>.06 and C.bg or C.ink)end
end
function M.paintTroops(track,home,away,low)
    local g=track:FindFirstChild('Bar20')
    if not g then g=K.make('UIGradient',track,{Name='Bar20'});track.BackgroundColor3=Color3.new(1,1,1);track.BackgroundTransparency=0 end
    local a,b=low and Color3.fromRGB(255,166,64)or FILL_A,low and Color3.fromRGB(255,190,110)or FILL_B
    local Stops=require(script.Parent.Parent.Core.FillStops)
    local times,colors,alphas=Stops.build({{p=home,color=a,color2=b},{p=home+away,color=b:Lerp(C.raised,.5)}},C.raised,0)
    local cs,ts={},{}
    for i,t in ipairs(times)do cs[i]=ColorSequenceKeypoint.new(t,colors[i]);ts[i]=NumberSequenceKeypoint.new(t,alphas[i])end
    g.Color=ColorSequence.new(cs);g.Transparency=NumberSequence.new(ts)
end
return M
