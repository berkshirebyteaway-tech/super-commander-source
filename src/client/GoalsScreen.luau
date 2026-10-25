local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.OutgameIcons)
local Currency=require(script.Parent.CurrencyChip)
local Claims=require(script.Parent.GoalClaims)
local RedDot=require(script.Parent.RedDot)
local Step=require(script.Parent.TelemetryStep)
local M={}
local C=UI.colors
local NARROW=false
local GREEN=Color3.fromRGB(150,214,84)
local DIM=Color3.fromRGB(70,78,92)
local GOLD=Color3.fromRGB(232,184,72)
local TABS={{'campaign','캠페인','캠페인','campaign'},{'challenges','도전과제','도전과제','crest'}}
local ACH_ICON={firstWin='deploy',games10='records',cities25='fields',peak50='watch',coopWin='friends',pvpWin='marshal',streak7='daily',wins10='ranked',maps5='solo',games50='clan'}

local function label(parent,name,text,size,color,x,y,w,h,align)
    local l=UI.label(parent,name,text,size or 14,color or C.ink);UI.box(l,x,y,w,h)
    if align then l.TextXAlignment=align end;return l
end
local function bold(l)l.Font=Enum.Font.BuilderSansBold;return l end
local function fit(l,max,min)l.TextWrapped=false;l.TextScaled=true;UI.make('UITextSizeConstraint',l,{MaxTextSize=max,MinTextSize=min});return l end
local function card(parent,name,x,y,w,h,fill)
    local p=UI.panel(parent,name);UI.box(p,x,y,w,h);p.BackgroundColor3=fill or C.panel;p.BackgroundTransparency=.04;return p
end
local function edge(p,color,thick)local s=p:FindFirstChildOfClass('UIStroke');if s then s.Color=color;s.Thickness=thick or 1;s.Transparency=0 end end
local function bar(parent,name,x,y,w,ratio,color,h)
    local track=UI.corner(UI.make('Frame',parent,{Name=name,BackgroundColor3=C.raised,BorderSizePixel=0}),4);UI.box(track,x,y,w,h or 6)
    UI.corner(UI.make('Frame',track,{Name='Fill',BackgroundColor3=color or C.accent,BorderSizePixel=0,Size=UDim2.fromScale(math.clamp(ratio or 0,0,1),1)}),4)
    return track
end
local function ring(parent,name,x,y,size,ratio,color,thick)
    local f=UI.make('Frame',parent,{Name=name,BackgroundTransparency=1});UI.box(f,x,y,size,size)
    local function circle(p)local c=UI.make('Frame',p,{BackgroundTransparency=1,Size=UDim2.fromOffset(size,size)});UI.corner(c,999)
        local s=Instance.new('UIStroke');s.Thickness=thick or 4;s.Color=color;s.Parent=c;return c,s end
    local _,ts=circle(f);ts.Color=C.raised
    ratio=math.clamp(ratio or 0,0,1)
    for half=0,1 do if (half==0 and ratio>0)or (half==1 and ratio>.5)then
        local clip=UI.make('Frame',f,{Name='Half'..half,BackgroundTransparency=1,ClipsDescendants=true,Position=UDim2.fromOffset(half==0 and size/2 or 0,0),Size=UDim2.fromOffset(size/2,size)})
        local c,s=circle(clip);c.Position=UDim2.fromOffset(half==0 and -size/2 or 0,0);s.Color=color
        local g=Instance.new('UIGradient');g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(.501,1),NumberSequenceKeypoint.new(1,1)})
        if half==0 then g.Rotation=math.min(ratio,.5)/.5*180 else g.Rotation=180+math.clamp(ratio-.5,0,.5)/.5*180 end
        g.Parent=s
    end end
    return f
end
local function crest(parent,x,y,size)
    local f=UI.make('Frame',parent,{Name='Crest',BackgroundTransparency=1});UI.box(f,x,y,size,size)
    for _,v in ipairs({{'crestShield',Color3.fromRGB(40,72,132)},{'crestLaurel',GOLD},{'crestStar',Color3.fromRGB(244,206,92)}})do
        local i=Icons.create(f,v[1],size,v[2]);i.Name=v[1];UI.box(i,0,0,size,size)
    end
    return f
end
local function opened(hub,key)return hub.goalsOpen~=nil and hub.goalsOpen[key]==true end
local function foldRow(hub,parent,key,text,x,y,w)
    local on=opened(hub,key)
    local b=UI.button(parent,'Fold_'..key,'',function()hub.goalsOpen=hub.goalsOpen or {};hub.goalsOpen[key]=not on;Step.step('goals','fold',{item=key,result=on and 'closed'or 'opened'});hub:drawPage()end,false)
    UI.box(b,x,y,w,48);b.BackgroundColor3=C.panel;b.BackgroundTransparency=.3
    fit(label(b,'Text',text,14,C.ink,14,0,w-130,48),14,10)
    label(b,'Toggle',on and '접기 ▴'or '펼치기 ▾',14,GOLD,w-114,0,100,48,Enum.TextXAlignment.Right)
    return b
end
local function claimDots(p)
    local ach=false;for _,c in ipairs(Claims.list(p))do if c.source=='achievement'then ach=true end end
    return {challenges=ach}
end

local function rung(hub,parent,a,n,kind,x,y,w,h,phone)
    local p=hub.account.progress or {};local shop=hub.callbacks.shop()
    local ratio=a.target>0 and math.min(1,a.progress/a.target)or 0;local won=kind=='done'or kind=='claim';local dim=kind=='far'
    local c=card(parent,'Achievement_'..a.id,x,y,w,h,kind=='current'and Color3.fromRGB(24,40,42)or kind=='claim'and Color3.fromRGB(44,38,20)or kind=='done'and Color3.fromRGB(32,30,22)or nil)
    if kind=='current'then edge(c,C.accent,2)elseif kind=='claim'then edge(c,GOLD,2)elseif kind=='done'then edge(c,GOLD:Lerp(C.panel,.5))end
    if dim then c.BackgroundTransparency=.5 end
    label(c,'Step',tostring(n),13,dim and DIM or C.muted,6,0,26,h,Enum.TextXAlignment.Center)
    local is=kind=='current'and (phone and 44 or 52)or 34
    local r=ring(c,'Ring',36,(h-is)/2,is,won and 1 or ratio,won and GOLD or C.accent,3)
    local ic=Icons.create(r,ACH_ICON[a.id]or 'medal',is*.5,dim and C.muted or won and GOLD or C.ink);UI.box(ic,is*.25,is*.25,is*.5,is*.5)
    local big=kind=='current';local tx=36+is+12;local rw=kind=='claim'and 104 or big and 128 or 96
    local nm=bold(label(c,'Name',a.name,big and (phone and 16 or 18)or 15,dim and C.muted or C.ink,tx,big and 10 or 8,w-tx-rw-8,24));nm.TextWrapped=false;nm.TextTruncate=Enum.TextTruncate.AtEnd
    local d=label(c,'Detail',a.detail,13,C.muted,tx,big and 38 or 32,big and w-tx-12 or w-tx-rw-8,big and 34 or 20);d.TextWrapped=big;d.TextYAlignment=Enum.TextYAlignment.Top;if not big then d.TextTruncate=Enum.TextTruncate.AtEnd end
    if kind=='claim'then
        Claims.dot(c,true);local b;b=Claims.button(c,'ClaimAchievement','받기',function()Step.step('goals','claim',{item=a.id});Claims.claim(hub,'a:'..a.id,b)end);UI.box(b,w-96,(h-48)/2,84,48);UI.enabled(b,not shop.busy)
    elseif kind=='done'then
        label(c,'Done',string.format('+%d 코인',a.medals),13,GOLD,w-rw,0,rw-12,h,Enum.TextXAlignment.Right)
    elseif big then
        Currency.create(c,'medal',a.medals,w-120,8,108,26)
        local go=UI.button(c,'Go','출전',function()Step.step('goals','towerGo',{item=a.id});hub:closePage()end,true);UI.box(go,w-120,h-60,108,48);go.TextSize=17
        bold(label(c,'Value',string.format('%d / %d',a.progress,a.target),14,C.ink,tx,h-50,w-tx-136,20))
        bar(c,'Progress',tx,h-24,w-tx-136,ratio,GOLD,8)
    else
        Currency.create(c,'medal',a.medals,w-88,8,76,22)
        label(c,'Value',string.format('%d/%d',a.progress,a.target),13,dim and C.muted or C.ink,w-88,32,76,20,Enum.TextXAlignment.Right)
    end
    return c
end
local function tower(hub,body,list,x,y,w,phone)
    local p=hub.account.progress or {}
    local order=table.clone(list)
    table.sort(order,function(a,b)if a.medals~=b.medals then return a.medals<b.medals end;if a.target~=b.target then return a.target<b.target end;return a.id<b.id end)
    local num,open,claim,done={},{},{},{}
    for i,a in ipairs(order)do num[a.id]=i
        if Claims.pending(p,'a:'..a.id)then table.insert(claim,a)elseif a.done then table.insert(done,a)else table.insert(open,a)end end
    local lw=phone and w or math.min(w,860);local lx=x+(w-lw)/2;local rx,rw=lx+28,lw-28;local gap=8;local rh=phone and 56 or 60
    local nodes={}
    local function place(a,kind,h)rung(hub,body,a,num[a.id],kind,rx,y,rw,h,phone);table.insert(nodes,{y=y+h/2,kind=kind});y+=h+gap end
    local top=y
    if #open>3 then
        local up=opened(hub,'achUp')
        foldRow(hub,body,'achUp',string.format('▲ %d칸 더',#open-3),rx,y,rw);y+=48+gap
        if up then for i=#open,4,-1 do place(open[i],'far',rh)end end
    end
    for i=math.min(#open,3),2,-1 do place(open[i],i==3 and 'far'or 'next',rh)end
    if open[1]then place(open[1],'current',phone and 132 or 124)end
    for _,a in ipairs(claim)do place(a,'claim',64)end
    if #open==0 and #claim==0 and #list>0 then
        local c=card(body,'TowerTop',rx,y,rw,64,Color3.fromRGB(44,38,20));edge(c,GOLD,2);table.insert(nodes,{y=y+32,kind='done'})
        bold(label(c,'Text','꼭대기까지 모두 올랐어요',16,GOLD,16,0,rw-32,64,Enum.TextXAlignment.Center));y+=64+gap
    end
    if #done>0 then
        local fy=y;foldRow(hub,body,'achDone',string.format('✓ 깬 칸 %d개',#done),rx,y,rw);table.insert(nodes,{y=fy+24,kind='fold'});y+=48+gap
        if opened(hub,'achDone')then for i=#done,1,-1 do place(done[i],'done',rh)end end
    end
    if #nodes>0 then
        local line=UI.make('Frame',body,{Name='TowerRail',BackgroundColor3=C.line,BorderSizePixel=0});UI.box(line,lx+11,math.min(top+24,nodes[1].y),2,math.max(0,nodes[#nodes].y-math.min(top+24,nodes[1].y)))
        for i,nd in ipairs(nodes)do
            local sz=nd.kind=='current'and 14 or 10
            local col=nd.kind=='current'and C.accent or (nd.kind=='claim'or nd.kind=='done'or nd.kind=='fold')and GOLD or nd.kind=='far'and DIM or C.line:Lerp(C.ink,.3)
            local dot=UI.corner(UI.make('Frame',body,{Name='TowerNode'..i,BackgroundColor3=col,BorderSizePixel=0}),999);UI.box(dot,lx+12-sz/2,nd.y-sz/2,sz,sz)
        end
    end
    return y
end
local function drawChallenges(hub,body,x,w,y,phone)
    local p=hub.account.progress or {};local list=p.achievementList or {}
    local done,left=0,0;for _,a in ipairs(list)do if a.done then done+=1 else left+=a.medals end end
    local lw=phone and w or math.min(w,860);local lx=x+(w-lw)/2;local cw=left>0 and 112 or 0
    bold(label(body,'Count',string.format('%d / %d',done,#list),16,C.ink,lx,y,64,32))
    bar(body,'Progress',lx+70,y+12,lw-70-cw-(cw>0 and 10 or 0),done/math.max(1,#list),GOLD,8)
    if left>0 then Currency.create(body,'medal',left,lx+lw-cw,y+4,cw,24)end
    y+=32+14
    return tower(hub,body,list,x,y,w,phone)
end

function M.defaultTab(hub)
    local p=hub.account and hub.account.progress or {};local Campaign=require(script.Parent.Parent.Core.CampaignRules)
    for _,st in ipairs(Campaign.stages)do if not Campaign.cleared(p,st.id)then return 'campaign'end end
    return 'challenges'
end
function M.keep(hub,body)
    local s=body:FindFirstChild('GoalsScroll')
    if s and s:IsA('ScrollingFrame')and hub.goalsScrollTab then hub.goalsKeep={tab=hub.goalsScrollTab,pos=s.CanvasPosition}end
end
function M.draw(hub,body,shop)
    if require(script.Parent.Lobby20).ENABLED then require(script.Parent.Goals20).draw(hub,body,shop);return end
    local p=hub.account.progress or {}
    for _,o in ipairs(body:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
    local W,H=body.Size.X.Offset,body.Size.Y.Offset
    if W<10 then W,H=body.AbsoluteSize.X/(UI.scale or 1),body.AbsoluteSize.Y/(UI.scale or 1)end
    local rawW,rawH=W,H;local pad=body:FindFirstChild('ContentInset')
    if pad then W-=pad.PaddingLeft.Offset+pad.PaddingRight.Offset;H-=pad.PaddingTop.Offset+pad.PaddingBottom.Offset end
    hub.goalsDrawn=Vector2.new(body.Size.X.Offset,body.Size.Y.Offset)
    if not hub.goalsResize then hub.goalsResize=body:GetPropertyChangedSignal('Size'):Connect(function()
        if hub.page~='missions'then return end
        local now=Vector2.new(body.Size.X.Offset,body.Size.Y.Offset)
        if hub.goalsDrawn and (now-hub.goalsDrawn).Magnitude>1 and not hub.goalsRedraw then hub.goalsRedraw=true
            task.defer(function()hub.goalsRedraw=nil;if hub.page=='missions'then hub:drawPage()end end)end
    end)end
    local phone=rawH<460 or rawW<760
    NARROW=phone and W<560 and H>W
    hub.goalTab=hub.goalTab or M.defaultTab(hub)
    if not ({campaign=1,challenges=1})[hub.goalTab]then hub.goalTab='challenges'end
    local screen=hub.goalTab=='campaign'and 'campaign'or 'goals';if hub.goalScreen~=screen then hub.goalScreen=screen;Step.emit('screen_viewed',{screen=screen,result='shown'})end
    local dots=claimDots(p)
    local cv=p.campaign or {};local done=0;for _,x in ipairs(p.achievementList or {})do if x.done then done+=1 end end
    local subs={campaign=string.format('별 %d/%d',cv.total or 0,require(script.Parent.Parent.Core.CampaignRules).maxStars),challenges=string.format('%d/%d 달성',done,#(p.achievementList or {}))}
    local function pick(key)if hub.goalTab~=key then hub.goalTab=key;Step.step('goals','tab',{item=key});hub:drawPage()end end
    local x0,top,cw=0,0,W
    if NARROW then
        local tw=(W-(#TABS-1)*8)/#TABS
        for i,t in ipairs(TABS)do
            local on=hub.goalTab==t[1]
            local b=UI.button(body,'GoalTab_'..t[1],'',function()pick(t[1])end,false);UI.box(b,(i-1)*(tw+8),0,tw,56)
            b.BackgroundColor3=on and C.raised:Lerp(C.ink,.12)or C.panel
            local st=b:FindFirstChildOfClass('UIStroke');if st then st.Color=on and C.ink or C.line;st.Transparency=on and .3 or 0 end
            if on then local mark=UI.make('Frame',b,{Name='Mark',BackgroundColor3=C.ink,BorderSizePixel=0});UI.box(mark,12,53,tw-24,3)end
            local ic;if t[4]=='crest'then ic=crest(b,(tw-24)/2,6,24)else ic=Icons.create(b,t[4],24,t[4]=='medal'and GOLD or C.accent);UI.box(ic,(tw-24)/2,6,24,24)end;RedDot.onIcon(b,ic)
            local tn=label(b,'Name',t[3],13,on and C.ink or C.muted,2,32,tw-4,18,Enum.TextXAlignment.Center);tn.TextScaled=true;UI.make('UITextSizeConstraint',tn,{MaxTextSize=13,MinTextSize=9})
            Claims.dot(b,dots[t[1]]==true)
        end
        top=66
    elseif phone then
        local rail=card(body,'GoalRail',0,0,72,H-4);rail.ZIndex=2
        for i,t in ipairs(TABS)do
            local on=hub.goalTab==t[1]
            local b=UI.button(rail,'GoalTab_'..t[1],'',function()pick(t[1])end,false);UI.box(b,6,6+(i-1)*((H-16)/#TABS),60,(H-16)/#TABS-6)
            b.BackgroundColor3=on and C.raised:Lerp(C.ink,.12)or C.panel;b.BackgroundTransparency=on and 0 or 1
            local edgeS=b:FindFirstChildOfClass('UIStroke');if edgeS then edgeS.Enabled=false end
            if on then local mark=UI.make('Frame',b,{Name='Mark',BackgroundColor3=C.ink,BorderSizePixel=0});UI.box(mark,0,8,3,(H-16)/#TABS-22)end
            local bh=(H-16)/#TABS-6
            local ic;if t[4]=='crest'then ic=crest(b,16,bh/2-24,28)else ic=Icons.create(b,t[4],28,t[4]=='medal'and GOLD or C.accent);UI.box(ic,16,bh/2-24,28,28)end;RedDot.onIcon(b,ic)
            local tn=label(b,'Name',t[3],13,on and C.ink or C.muted,2,bh/2+8,56,18,Enum.TextXAlignment.Center);tn.TextScaled=true;UI.make('UITextSizeConstraint',tn,{MaxTextSize=13,MinTextSize=9})
            Claims.dot(b,dots[t[1]]==true)
        end
        x0,cw=84,W-84
    else
        local tw=(W-(#TABS-1)*16)/#TABS
        for i,t in ipairs(TABS)do
            local on=hub.goalTab==t[1]
            local b=UI.button(body,'GoalTab_'..t[1],'',function()pick(t[1])end,false);UI.box(b,(i-1)*(tw+16),0,tw,64)
            b.BackgroundColor3=on and C.raised:Lerp(C.ink,.1)or C.panel;local st=b:FindFirstChildOfClass('UIStroke');if st then st.Color=on and C.ink or C.line;st.Transparency=on and .3 or 0 end
            local ic;if t[4]=='crest'then ic=crest(b,16,14,36)else ic=Icons.create(b,t[4],32,t[4]=='medal'and GOLD or C.accent);UI.box(ic,18,16,32,32)end;RedDot.onIcon(b,ic)
            local tn=bold(label(b,'Name',t[2],18,C.ink,64,10,tw-74,24));tn.TextWrapped=false;tn.TextScaled=true;UI.make('UITextSizeConstraint',tn,{MaxTextSize=18,MinTextSize=13})
            local ts=label(b,'Sub',subs[t[1]],13,on and C.ink or C.muted,64,34,tw-74,20);ts.TextWrapped=false;ts.TextTruncate=Enum.TextTruncate.AtEnd
            Claims.dot(b,dots[t[1]]==true)
        end
        top=80
    end
    local scroll=UI.make('ScrollingFrame',body,{Name='GoalsScroll',BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=C.line,ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.fromOffset(0,0)})
    UI.box(scroll,x0,top,cw,H-top)
    local inner=cw-10;local y=0
    if hub.goalTab=='campaign'then y=require(script.Parent.CampaignScreen).draw(hub,scroll,0,inner,y,phone)
    else y=drawChallenges(hub,scroll,0,inner,y,phone)end
    scroll.CanvasSize=UDim2.fromOffset(0,y+12)
    local keep=hub.goalsKeep;hub.goalsKeep=nil;hub.goalsScrollTab=hub.goalTab
    if hub.campaignScrollTop then hub.campaignScrollTop=nil elseif keep and keep.tab==hub.goalTab then scroll.CanvasPosition=keep.pos end
    Step.once('goalsView:'..hub.goalTab,'goals','view',{item=hub.goalTab})
end
return M
