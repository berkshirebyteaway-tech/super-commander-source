local TweenService=game:GetService('TweenService')
local UI=require(script.Parent.Theme)
local Audio=require(script.Parent.ToyAudio)
local Model=require(script.Parent.Parent.Core.ResultPresentation)
local M={busyUntil=0,reduced=false}
local current
local function tween(o,t,props,delay,style,direction)
    local tw=TweenService:Create(o,TweenInfo.new(t,style or Enum.EasingStyle.Quint,direction or Enum.EasingDirection.Out,0,false,delay or 0),props);tw:Play();return tw
end
local function label(parent,name,text,size,color,display)
    local l=UI.label(parent,name,text,size,color);l.AnchorPoint=Vector2.new(.5,.5);l.TextXAlignment=Enum.TextXAlignment.Center
    l.TextWrapped=false;l.TextTransparency=1;l.ZIndex=82;if display then UI.display(l)end;return l
end
local function play20(parent,state,reduced,v)
    local K=require(script.Parent.Kit20)
    local C=K.colors
    local hold=1;M.reduced=reduced==true;M.busyUntil=os.clock()+hold+.3
    local compact=parent.AbsoluteSize.Y/UI.scale<500
    local f=UI.make('TextButton',parent,{Name='ResultMoment',Text='',AutoButtonColor=false,Selectable=false,Active=true,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=80})
    f:SetAttribute('BlocksInput',true);current=f;M.layout={compact=compact,mid=0,drop=0}
    local dim=K.make('Frame',f,{Name='Dim',BackgroundColor3=Color3.fromRGB(4,7,11),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=80,Active=false,Position=UDim2.new(0,-200,0,-200),Size=UDim2.new(1,400,1,400)})
    local lost=not v.won and v.title=='패배'
    require(script.Parent.TelemetryStep).step('result','moment',{result=v.won and 'won'or lost and 'lost'or 'complete',value=v.rank,count=v.total,item='plain'})
    lost=lost or not v.won and v.title=='탈락'
    local bh=compact and 120 or 160
    local band=K.make('Frame',f,{Name='Band',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.44),Size=UDim2.new(1,0,0,bh),BackgroundColor3=Color3.fromRGB(8,12,18),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=81})
    K.make('UIGradient',band,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.22,.05),NumberSequenceKeypoint.new(.78,.05),NumberSequenceKeypoint.new(1,1)})})
    local ts,rs=compact and 48 or 68,compact and 22 or 28
    local ranked=v.rank~=nil
    local title=K.text(f,'Title',v.title,ts,v.won and C.accent or C.ink,800,Enum.TextXAlignment.Center);title.AnchorPoint=Vector2.new(.5,.5);title.ZIndex=82;title.TextTransparency=1
    local place=ranked and K.num(f,'Rank',string.format('%d위 / %d',v.rank,v.total),rs,C.gold,Enum.TextXAlignment.Center)or nil
    local block=ts+(ranked and 4+rs or 0)
    title.Position=UDim2.new(.5,0,.44,math.floor(-block/2+ts/2));title.Size=UDim2.fromOffset(900,ts+8)
    if place then place.AnchorPoint=Vector2.new(.5,.5);place.ZIndex=82;place.TextTransparency=1;place.Position=UDim2.new(.5,0,.44,math.floor(block/2-rs/2));place.Size=UDim2.fromOffset(600,rs+8)end
    local function tw(o,t,props,delay,style,dir)
        local x=TweenService:Create(o,TweenInfo.new(t,style or Enum.EasingStyle.Quad,dir or Enum.EasingDirection.Out,0,false,delay or 0),props);x:Play();return x
    end
    tw(dim,.18,{BackgroundTransparency=.45});tw(band,.18,{BackgroundTransparency=0},0,Enum.EasingStyle.Cubic)
    tw(title,.12,{TextTransparency=0},.18)
    if not reduced then local s=K.make('UIScale',title,{Scale=1.06});tw(s,.16,{Scale=1},.18,Enum.EasingStyle.Cubic)end
    if place then
        tw(place,.1,{TextTransparency=0},.32)
        if not reduced then local s=K.make('UIScale',place,{Scale=1.3});tw(s,.18,{Scale=1},.32,Enum.EasingStyle.Back)end
    end
    if lost and not reduced then
        local edge=K.make('Frame',f,{Name='EdgeGlow',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=81,Active=false})
        for i,spec in ipairs({{0,0,1,0,90},{0,1,1,0,-90},{0,0,0,1,0},{1,0,0,1,180}})do
            local horizontal=spec[3]==1
            local e=K.make('Frame',edge,{Name='Edge'..i,BackgroundColor3=C.danger,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=81,
                AnchorPoint=Vector2.new(spec[1],spec[2]),Position=UDim2.fromScale(spec[1],spec[2]),Size=horizontal and UDim2.new(1,0,0,90)or UDim2.new(0,90,1,0)})
            K.make('UIGradient',e,{Rotation=spec[5],Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.55),NumberSequenceKeypoint.new(1,1)})})
            tw(e,.12,{BackgroundTransparency=0});tw(e,.18,{BackgroundTransparency=1},.12,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
        end
    end
    local at=os.clock();local finished=false
    local function finish()
        if finished then return end;finished=true
        require(script.Parent.TelemetryStep).step('result','momentDone',{duration_ms=(os.clock()-at)*1000})
        M.busyUntil=math.min(M.busyUntil,os.clock()+.3)
        for _,o in ipairs({title,place or false})do if o then tw(o,.2,{TextTransparency=1},0,Enum.EasingStyle.Quad,Enum.EasingDirection.In)end end
        tw(band,.2,{BackgroundTransparency=1},0,Enum.EasingStyle.Quad,Enum.EasingDirection.In);tw(dim,.2,{BackgroundTransparency=1},0,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
        task.delay(.22,function()f:Destroy();if current==f then current=nil end end)
    end
    task.delay(hold,finish)
    return f
end
function M.play(parent,state,reduced)
    if current then current:Destroy();current=nil end
    local v=Model.view(state)
    local ok20,H20=pcall(require,script.Parent.Hud20)
    if ok20 and H20.ENABLED then return play20(parent,state,reduced,v)end
    local hold=reduced and .8 or 1
    M.reduced=reduced==true;M.busyUntil=os.clock()+hold+.3
    local compact=parent.AbsoluteSize.Y/UI.scale<500
    local f=UI.make('TextButton',parent,{Name='ResultMoment',Text='',AutoButtonColor=false,Selectable=false,Active=true,Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(4,7,11),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=80})
    f:SetAttribute('BlocksInput',true)
    current=f;M.layout={compact=compact,mid=compact and -6 or -10}
    local ranked=v.rank~=nil;local drop=ranked and (compact and 30 or 44)or 0;M.layout.drop=drop
    local bandH=(compact and 100 or 140)+drop*2
    local band=UI.make('Frame',f,{Name='Band',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.44),Size=UDim2.new(reduced and 1 or 0,0,0,bandH),BackgroundColor3=Color3.fromRGB(8,12,18),BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true,ZIndex=81})
    UI.make('UIGradient',band,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.22,0),NumberSequenceKeypoint.new(.78,0),NumberSequenceKeypoint.new(1,1)})})
    local lost=not v.won and v.title=='패배';local momentAt=os.clock()
    require(script.Parent.TelemetryStep).step('result','moment',{result=v.won and 'won'or lost and 'lost'or 'complete',value=v.rank,count=v.total,item='plain'})
    local tint=v.won and UI.colors.accent or lost and UI.colors.danger or UI.colors.muted
    for i,name in ipairs({'EdgeTop','EdgeBottom'})do
        UI.make('Frame',band,{Name=name,AnchorPoint=Vector2.new(.5,i==1 and 0 or 1),Position=UDim2.fromScale(.5,i==1 and 0 or 1),Size=UDim2.new(.7,0,0,2),BackgroundColor3=tint,BackgroundTransparency=.35,BorderSizePixel=0,ZIndex=81})
    end
    local title=label(f,'Title',v.title,compact and 48 or 76,UI.colors.ink,true)
    title.TextStrokeColor3=tint:Lerp(Color3.new(0,0,0),.55);title.TextStrokeTransparency=1
    local scale=UI.make('UIScale',title,{Scale=reduced and 1 or 1.55})
    local line=UI.make('Frame',f,{Name='Line',AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(0,3),BackgroundColor3=tint,BorderSizePixel=0,ZIndex=82})
    local place=ranked and label(f,'Rank',string.format('%d위 / %d',v.rank,v.total),compact and 28 or 40,v.rank<=3 and UI.colors.gold or UI.colors.ink,true)or nil
    local placeScale=place and UI.make('UIScale',place,{Scale=reduced and 1 or .6})
    local mid=compact and -6 or -10
    local function at(o,dy,w,h)o.Position=UDim2.new(.5,0,.44,dy);o.Size=UDim2.fromOffset(w,h)end
    at(title,mid,900,compact and 56 or 86);at(line,mid+(compact and 36 or 52),0,3)
    if place then at(place,mid+(compact and 58 or 84),600,compact and 32 or 46)end
    tween(f,.25,{BackgroundTransparency=.3});tween(band,.2,{BackgroundTransparency=.12})
    if not reduced then tween(band,.32,{Size=UDim2.new(1,0,0,bandH)},0,Enum.EasingStyle.Quart)end
    tween(title,.18,{TextTransparency=0,TextStrokeTransparency=.2},.18);tween(scale,.42,{Scale=1},.18,Enum.EasingStyle.Back)
    tween(line,.36,{Size=UDim2.fromOffset(compact and 220 or 320,3)},.34)
    if place then tween(place,.2,{TextTransparency=0},.44);tween(placeScale,.38,{Scale=1},.44,Enum.EasingStyle.Back)end
    local finished=false
    local function finish()
        if finished then return end;finished=true;require(script.Parent.TelemetryStep).step('result','momentDone',{duration_ms=(os.clock()-momentAt)*1000})
        M.busyUntil=math.min(M.busyUntil,os.clock()+.3)
        for _,o in ipairs({title,place or false})do if o then tween(o,.22,{TextTransparency=1,TextStrokeTransparency=1},0,Enum.EasingStyle.Quad,Enum.EasingDirection.In)end end
        tween(scale,.22,{Scale=.94},0,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
        tween(line,.22,{BackgroundTransparency=1});tween(band,.25,{BackgroundTransparency=1});tween(f,.28,{BackgroundTransparency=1})
        for _,o in ipairs(band:GetChildren())do if o:IsA('Frame')then tween(o,.2,{BackgroundTransparency=1})end end
        task.delay(.3,function()f:Destroy();if current==f then current=nil end end)
    end
    task.delay(hold,finish)
    return f
end
function M.levelUp(id)
    if id~=nil and M.leveled==id then return end;M.leveled=id
    Audio.play('milestone')
end
function M.active()return current~=nil and current.Parent~=nil end
function M.cardOpen()
    local o=M.card;if not o or not o.Parent then return false end
    while o and o:IsA('GuiObject')do if not o.Visible then return false end;o=o.Parent end
    return o~=nil and (not o:IsA('LayerCollector')or o.Enabled)
end
return M
