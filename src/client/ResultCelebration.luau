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
function M.play(parent,state,reduced)
    if current then current:Destroy();current=nil end
    local v=Model.view(state);local p=v.progression
    local promoted=v.status~='practice'and p~=nil and p.title~=nil and p.startTitle~=nil and p.title~=p.startTitle
    local hold=reduced and .8 or (v.won and 2.2 or 1.5)+(promoted and .5 or 0)
    if promoted then M.promoted=state.personalResult and state.personalResult.id end
    M.reduced=reduced==true;M.busyUntil=os.clock()+hold+.3
    local compact=parent.AbsoluteSize.Y/UI.scale<500
    local f=UI.make('TextButton',parent,{Name='ResultMoment',Text='',AutoButtonColor=false,Selectable=false,Active=true,Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(4,7,11),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=80})
    f:SetAttribute('BlocksInput',true)
    current=f;M.layout={compact=compact,mid=compact and -6 or -10}
    local ranked=v.rank~=nil;local drop=ranked and (compact and 30 or 44)or 0;M.layout.drop=drop
    local bandH=(compact and 132 or 188)+drop*2
    local band=UI.make('Frame',f,{Name='Band',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.44),Size=UDim2.new(reduced and 1 or 0,0,0,bandH),BackgroundColor3=Color3.fromRGB(8,12,18),BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true,ZIndex=81})
    UI.make('UIGradient',band,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.22,0),NumberSequenceKeypoint.new(.78,0),NumberSequenceKeypoint.new(1,1)})})
    local lost=not v.won and v.title=='패배';local momentAt=os.clock()
    require(script.Parent.TelemetryStep).step('result','moment',{result=v.won and 'won'or lost and 'lost'or 'complete',value=v.rank,count=v.total,item=promoted and 'promoted'or 'plain'})
    local tint=v.won and UI.colors.accent or lost and UI.colors.danger or UI.colors.muted
    for i,name in ipairs({'EdgeTop','EdgeBottom'})do
        UI.make('Frame',band,{Name=name,AnchorPoint=Vector2.new(.5,i==1 and 0 or 1),Position=UDim2.fromScale(.5,i==1 and 0 or 1),Size=UDim2.new(.7,0,0,2),BackgroundColor3=tint,BackgroundTransparency=.35,BorderSizePixel=0,ZIndex=81})
    end
    local shine=UI.make('Frame',band,{Name='Shine',AnchorPoint=Vector2.new(.5,0),Position=UDim2.fromScale(-.2,0),Size=UDim2.new(.18,0,1,0),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=.9,BorderSizePixel=0,ZIndex=81})
    UI.make('UIGradient',shine,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(1,1)}),Rotation=0})
    local kicker=label(f,'Kicker',v.won and 'V  I  C  T  O  R  Y'or lost and 'D  E  F  E  A  T'or 'M  I  S  S  I  O  N    E  N  D',compact and 14 or 18,tint,true)
    kicker.AutoLocalize=false;kicker:SetAttribute('LocalizationSkip',true)
    local title=label(f,'Title',v.title,compact and 48 or 76,UI.colors.ink,true)
    title.TextStrokeColor3=tint:Lerp(Color3.new(0,0,0),.55);title.TextStrokeTransparency=1
    local scale=UI.make('UIScale',title,{Scale=reduced and 1 or 1.55})
    local line=UI.make('Frame',f,{Name='Line',AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(0,3),BackgroundColor3=tint,BorderSizePixel=0,ZIndex=82})
    local sub=label(f,'Sub',(v.winner and v.winner..'  'or '')..'최고 영토'..string.format(' %.1f%%',v.peak*100),compact and 15 or 18,UI.colors.ink)
    local place=ranked and label(f,'Rank',string.format('%d위 / %d',v.rank,v.total),compact and 28 or 40,v.rank<=3 and UI.colors.gold or UI.colors.ink,true)or nil
    local placeScale=place and UI.make('UIScale',place,{Scale=reduced and 1 or .6})
    local promo=promoted and label(f,'Promotion',string.format('진급! %s Lv. %d',p.title,p.level or 1),compact and 18 or 24,UI.colors.gold,true)or nil
    local mid=compact and -6 or -10
    local function at(o,dy,w,h)o.Position=UDim2.new(.5,0,.44,dy);o.Size=UDim2.fromOffset(w,h)end
    at(kicker,mid-(compact and 44 or 68),500,24);at(title,mid,900,compact and 56 or 86);at(line,mid+(compact and 36 or 52),0,3)
    if place then at(place,mid+(compact and 58 or 84),600,compact and 32 or 46)end
    at(sub,mid+drop+(compact and 52 or 74),600,24);if promo then at(promo,mid+drop+(compact and 78 or 108),600,30)end
    tween(f,.25,{BackgroundTransparency=.3});tween(band,.2,{BackgroundTransparency=.12})
    if not reduced then tween(band,.32,{Size=UDim2.new(1,0,0,bandH)},0,Enum.EasingStyle.Quart)end
    tween(kicker,.3,{TextTransparency=0},.1)
    tween(title,.18,{TextTransparency=0,TextStrokeTransparency=.2},.18);tween(scale,.42,{Scale=1},.18,Enum.EasingStyle.Back)
    if not reduced then tween(shine,.7,{Position=UDim2.fromScale(1.2,0)},.42,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut)end
    tween(line,.36,{Size=UDim2.fromOffset(compact and 220 or 320,3)},.34);tween(sub,.3,{TextTransparency=0},.52)
    if place then tween(place,.2,{TextTransparency=0},.44);tween(placeScale,.38,{Scale=1},.44,Enum.EasingStyle.Back)end
    if promo then tween(promo,.4,{TextTransparency=0},.85);task.delay(.85,function()if current==f then Audio.play('milestone')end end)end
    local finished=false
    local function finish()
        if finished then return end;finished=true;require(script.Parent.TelemetryStep).step('result','momentDone',{duration_ms=(os.clock()-momentAt)*1000})
        M.busyUntil=math.min(M.busyUntil,os.clock()+.3)
        for _,o in ipairs({kicker,title,sub,place or false,promo or f:FindFirstChild('Promotion')or false})do if o then tween(o,.22,{TextTransparency=1,TextStrokeTransparency=1},0,Enum.EasingStyle.Quad,Enum.EasingDirection.In)end end
        tween(scale,.22,{Scale=.94},0,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
        tween(line,.22,{BackgroundTransparency=1});tween(band,.25,{BackgroundTransparency=1});tween(f,.28,{BackgroundTransparency=1})
        for _,o in ipairs(band:GetChildren())do if o:IsA('Frame')then tween(o,.2,{BackgroundTransparency=1})end end
        task.delay(.3,function()f:Destroy();if current==f then current=nil end end)
    end
    task.delay(hold,finish)
    return f
end
function M.promote(id,text)
    if id~=nil and M.promoted==id then return end;M.promoted=id
    local f=current
    if text and f and f.Parent and not f:FindFirstChild('Promotion')then
        local c=M.layout or {compact=false,mid=-10}
        local promo=label(f,'Promotion',text,c.compact and 18 or 24,UI.colors.gold,true)
        promo.Position=UDim2.new(.5,0,.44,c.mid+(c.drop or 0)+(c.compact and 78 or 108));promo.Size=UDim2.fromOffset(600,30);tween(promo,.4,{TextTransparency=0})
        M.busyUntil=math.max(M.busyUntil,os.clock()+.8)
    end
    Audio.play(text and 'milestone'or 'grow')
end
function M.active()return current~=nil and current.Parent~=nil end
function M.cardOpen()
    local o=M.card;if not o or not o.Parent then return false end
    while o and o:IsA('GuiObject')do if not o.Visible then return false end;o=o.Parent end
    return o~=nil and (not o:IsA('LayerCollector')or o.Enabled)
end
return M
