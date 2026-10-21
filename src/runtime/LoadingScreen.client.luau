local Players=game:GetService("Players")
local RF=game:GetService("ReplicatedFirst")
local TweenService=game:GetService("TweenService")
local me=Players.LocalPlayer
local playerGui=me:WaitForChild("PlayerGui")
playerGui.ScreenOrientation=Enum.ScreenOrientation.LandscapeSensor
local korean=tostring(me.LocaleId or ""):sub(1,2)=="ko"
local bg,line,ink,muted,accent=Color3.fromRGB(11,15,20),Color3.fromRGB(38,50,65),Color3.fromRGB(238,242,246),Color3.fromRGB(138,151,168),Color3.fromRGB(54,226,208)
local edge=accent:Lerp(Color3.fromRGB(191,239,255),.55)
local function font(family,weight)local ok,f=pcall(function()return Font.new("rbxasset://fonts/families/"..family..".json",weight or Enum.FontWeight.Bold)end)return ok and f or nil end
local function make(class,parent,props)local o=Instance.new(class);for k,v in pairs(props)do o[k]=v end;o.Parent=parent;return o end
local view=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
local narrow=view.X<600
local short=view.Y<480
local gui=make("ScreenGui",playerGui,{Name="FrontierLoading",DisplayOrder=50,IgnoreGuiInset=true,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local cover=make("Frame",gui,{Name="Cover",Size=UDim2.fromScale(1,1),BackgroundColor3=bg,BorderSizePixel=0})
do
    pcall(function()gui.ClipToDeviceSafeArea=false end)
    local strips={}
    for _,side in ipairs({"Left","Right","Top","Bottom"})do strips[side]=make("Frame",cover,{Name="SafeAreaBleed"..side,BackgroundColor3=bg,BorderSizePixel=0})end
    local function place()
        local v=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.zero
        local ok,a=pcall(function()return game:GetService("GuiService"):GetInsetArea(gui.ScreenInsets)end)
        local l,t,r,b
        if ok and a and a.Max.X>a.Min.X then l,t,r,b=math.max(0,a.Min.X),math.max(0,a.Min.Y),math.max(0,v.X-a.Max.X),math.max(0,v.Y-a.Max.Y)
        else local s=gui.AbsoluteSize;local w,h=math.max(0,v.X-s.X),math.max(0,v.Y-s.Y);l,t,r,b=w,h,w,h end
        strips.Left.Position=UDim2.fromOffset(-l,-t);strips.Left.Size=UDim2.new(0,l,1,t+b)
        strips.Right.Position=UDim2.new(1,0,0,-t);strips.Right.Size=UDim2.new(0,r,1,t+b)
        strips.Top.Position=UDim2.fromOffset(0,-t);strips.Top.Size=UDim2.new(1,0,0,t)
        strips.Bottom.Position=UDim2.fromScale(0,1);strips.Bottom.Size=UDim2.new(1,0,0,b)
    end
    place();gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place);gui:GetPropertyChangedSignal("AbsolutePosition"):Connect(place)
    if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(place)end
end
for i=1,23 do make("Frame",cover,{Name="GridV",Position=UDim2.fromScale(i/24,0),Size=UDim2.new(0,1,1,0),BackgroundColor3=line,BackgroundTransparency=.7,BorderSizePixel=0})end
for i=1,11 do make("Frame",cover,{Name="GridH",Position=UDim2.fromScale(0,i/12),Size=UDim2.new(1,0,0,1),BackgroundColor3=line,BackgroundTransparency=.7,BorderSizePixel=0})end
local shade=make("Frame",cover,{Name="Vignette",Size=UDim2.fromScale(1,1),BackgroundColor3=bg,BackgroundTransparency=0,BorderSizePixel=0})
make("UIGradient",shade,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(.5,.9),NumberSequenceKeypoint.new(1,.05)}),Rotation=90})
local mask={"..XXX....",".XXXXX...","XXXXXXXX.","XXXXXXXXX",".XXXXXXXX",".XXXXXXX.","..XXXXXX.","...XXXX..","....XX..."}
local cell=(narrow or short) and (short and 8 or 9) or 11
local markH=cell*9
local brandSize=narrow and math.clamp(math.floor(view.X*.105),32,44) or short and 44 or 60
local oathH=(narrow or short) and 0 or 32
local meterY=(short and 86 or 92)+oathH
local column=make("Frame",cover,{Name="Column",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,.47,0),Size=UDim2.new(1,-32,0,markH+brandSize+40+meterY),BackgroundTransparency=1})
local mark=make("Frame",column,{Name="Mark",AnchorPoint=Vector2.new(.5,0),Position=UDim2.fromScale(.5,0),Size=UDim2.fromOffset(cell*9,cell*9),BackgroundTransparency=1})
local tiles,order={}, {}
for y=1,9 do for x=1,9 do if mask[y]:sub(x,x)=="X"then
    tiles[y*10+x]=make("Frame",mark,{Name="Tile",Position=UDim2.fromOffset((x-1)*cell,(y-1)*cell),Size=UDim2.fromOffset(cell-1,cell-1),BackgroundColor3=line,BackgroundTransparency=.35,BorderSizePixel=0})
end end end
local pole=math.max(2,math.floor(cell/4))
local flag=make("Frame",mark,{Name="Flag",AnchorPoint=Vector2.new(0,1),Position=UDim2.fromOffset(math.floor(cell*4.5)-1,math.floor(cell*4.5)),Size=UDim2.fromOffset(pole,0),BackgroundColor3=Color3.fromRGB(220,230,238),BorderSizePixel=0})
local cloth=make("Frame",flag,{Name="Cloth",Position=UDim2.fromOffset(pole,0),Size=UDim2.fromOffset(math.floor(cell*3),math.floor(cell*1.9)),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0})
make("UIGradient",cloth,{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,accent),ColorSequenceKeypoint.new(.35,accent:Lerp(Color3.new(1,1,1),.18)),ColorSequenceKeypoint.new(.7,accent:Lerp(bg,.25)),ColorSequenceKeypoint.new(1,accent)})})
make("TextLabel",cloth,{Name="Star",Text="★",TextSize=math.floor(cell*1.5),TextColor3=ink,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Font=Enum.Font.BuilderSansBold})
TweenService:Create(flag,TweenInfo.new(.55,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(pole,math.floor(cell*4))}):Play()
do local seen,queue={[55]=true},{55}
    while #queue>0 do local k=table.remove(queue,1);table.insert(order,k)
        for _,d in ipairs({-10,10,-1,1})do local n=k+d;if tiles[n]and not seen[n]then seen[n]=true;table.insert(queue,n)end end
    end
end
local taken={}
local function paint(count)
    for i=1,#order do taken[order[i]]=i<=count end
    for k,t in pairs(tiles)do
        if taken[k]then
            local frontier=not(taken[k-10]and taken[k+10]and taken[k-1]and taken[k+1])
            t.BackgroundColor3=frontier and edge or accent;t.BackgroundTransparency=frontier and 0 or .4
        else t.BackgroundColor3=line;t.BackgroundTransparency=.35 end
    end
end
local function text(name,value,size,color,y,face,parent)
    local t=make("TextLabel",parent or column,{Name=name,Text=value,TextSize=size,TextColor3=color,BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,y),Size=UDim2.new(1,0,0,size+10),Font=Enum.Font.BuilderSansBold,TextXAlignment=Enum.TextXAlignment.Center})
    if face then t.FontFace=face end;return t
end
text("Kicker",korean and "슈퍼 커맨더" or "TAKE THE MAP",narrow and 13 or 14,accent,markH+22,font("BuilderMono")or font("RobotoMono"))
text("Brand","SUPER COMMANDER",brandSize,ink,markH+40,font("Oswald"))
local seal=make("TextLabel",column,{Name="Seal",Text="NO PAY-TO-WIN",TextSize=12,TextColor3=accent,BackgroundColor3=bg,BackgroundTransparency=.2,AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,markH+brandSize+56),AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,24),Font=Enum.Font.BuilderSansBold})
make("UIPadding",seal,{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)});make("UIStroke",seal,{Color=accent,Thickness=1.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border});make("UICorner",seal,{CornerRadius=UDim.new(0,3)})
local sealFace=font("BuilderMono")or font("RobotoMono");if sealFace then seal.FontFace=sealFace end
if oathH>0 then text("Oath",korean and "무기는 팔지 않습니다. 돈이 아니라 전략으로 이깁니다." or "We don't sell weapons. Outthink. Don't outspend.",14,muted,markH+brandSize+88,font("BuilderSans",Enum.FontWeight.Medium))end
local barW=narrow and 260 or 340
local meter=make("Frame",column,{Name="Meter",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,markH+brandSize+meterY),Size=UDim2.fromOffset(barW,40),BackgroundTransparency=1})
local status=make("TextLabel",meter,{Name="Status",Text=korean and "작전 본부에 연결하는 중" or "Connecting to command",TextSize=14,TextColor3=muted,BackgroundTransparency=1,Size=UDim2.new(1,-48,0,20),Font=Enum.Font.BuilderSansMedium,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd})
local percent=make("TextLabel",meter,{Name="Percent",Text="0%",TextSize=13,TextColor3=accent,BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.fromScale(1,0),Size=UDim2.fromOffset(48,20),Font=Enum.Font.BuilderSansBold,TextXAlignment=Enum.TextXAlignment.Right})
local mono=font("BuilderMono")or font("RobotoMono");if mono then percent.FontFace=mono end
local track=make("Frame",meter,{Name="Track",Position=UDim2.fromOffset(0,28),Size=UDim2.new(1,0,0,2),BackgroundColor3=line,BorderSizePixel=0})
local fill=make("Frame",track,{Name="Fill",Size=UDim2.fromScale(0,1),BackgroundColor3=accent,BorderSizePixel=0})
local tips=korean and {
    "도시는 완공 레벨마다 병력 상한을 25,000 늘려 줘요",
    "적은 병력으로 확장하면 국경을 지킬 병력이 남아요",
    "병력이 상한에 가까울수록 충원이 느려져요",
    "요새는 반경 30칸 안의 방어를 강화해요",
    "같은 땅을 한 번 더 누르면 바로 공격해요",
} or {
    "Each finished city level raises your troop cap by 25,000",
    "Expand with a small share and keep troops on the border",
    "Reinforcement slows as troops near the cap",
    "A fort hardens every tile within 30",
    "Tap the same land again to attack at once",
}
local tipRow=make("Frame",cover,{Name="Tip",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,(narrow or short) and -36 or -48),Size=UDim2.new(1,-32,0,24),BackgroundTransparency=1})
make("UIListLayout",tipRow,{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Center,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})
local chip=make("TextLabel",tipRow,{Name="Chip",LayoutOrder=1,Text="TIP",TextSize=11,TextColor3=bg,BackgroundColor3=accent,BorderSizePixel=0,Size=UDim2.fromOffset(34,18),Font=Enum.Font.BuilderSansBold})
if mono then chip.FontFace=mono end;make("UICorner",chip,{CornerRadius=UDim.new(0,2)})
local tipText=make("TextLabel",tipRow,{Name="Text",LayoutOrder=2,Text=tips[math.random(1,#tips)],TextSize=narrow and 13 or 14,TextColor3=muted,BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,20),Font=Enum.Font.BuilderSansMedium})
make("TextLabel",cover,{Name="Copyright",Text="© OpenFront and Contributors",TextSize=12,TextColor3=muted,BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,(narrow or short) and -12 or -18),Size=UDim2.new(1,-32,0,16),Font=Enum.Font.BuilderSansMedium,TextXAlignment=Enum.TextXAlignment.Center})
pcall(function()RF:RemoveDefaultLoadingScreen()end)
local hopped=false
pcall(function()
    local TS=game:GetService("TeleportService")
    if TS:GetArrivingTeleportGui()~=nil or TS:GetLocalPlayerTeleportData()~=nil then me:SetAttribute("SuperCommanderHop",true);hopped=true end
    local was=TS:GetArrivingTeleportGui();was=was and was:FindFirstChild("Status",true)
    if was and was:IsA("TextLabel")and was.Text~=""then status.Text=was.Text end
end)
pcall(function()
    paint(math.floor(#order*.2+.5))
    local hop=gui:Clone();hop.Name="FrontierTeleport";hop.Enabled=false
    paint(0)
    local hm=hop.Cover.Column
    hm.Mark.Flag.Size=UDim2.fromOffset(pole,math.floor(cell*4))
    hm.Meter.Status.Text=korean and "전선으로 이동하는 중" or "Moving to the front";hm.Meter.Percent.Text="20%"
    hm.Meter.Track.Fill.Size=UDim2.fromScale(.2,1)
    local oath=hm:FindFirstChild("Oath");if oath then oath.Text=korean and "과금으로 이기는 게임이 아닙니다. 지금도, 앞으로도." or "No pay-to-win. Not now. Not ever.";oath.TextColor3=ink end
    local ride=hop:Clone();ride.Enabled=true
    hop.Parent=playerGui
    game:GetService("TeleportService"):SetTeleportGui(ride)
end)
local alive,target,shown=true,.2,hopped and .2 or 0
local function advance(to,message)target=math.max(target,to);if message then status.Text=message end end
task.spawn(function()
    while alive do
        if shown<target then shown=math.min(target,shown+(target>=1 and .05 or .02))end
        paint(math.floor(#order*shown+.5));fill.Size=UDim2.fromScale(shown,1);percent.Text=math.floor(shown*100+.5).."%"
        task.wait(.03)
    end
end)
task.spawn(function()
    local i=1
    while alive do task.wait(4.5);if not alive then break end;i=i%#tips+1;tipText.Text=tips[i]end
end)
local started=os.clock()
advance(.35)
if not game:IsLoaded() then game.Loaded:Wait() end
local loadedAt=os.clock()
advance(.75,korean and "지휘 화면을 준비하는 중" or "Preparing the war room")
local ui=playerGui:WaitForChild("FrontierNativeUI",math.max(1,25-(os.clock()-started)))
while ui and ui:GetAttribute("Phase")==nil and os.clock()-started<25 do task.wait(.05)end
pcall(function()me:SetAttribute('LoadCoverStages',string.format('%d,%d,%d,%d',math.floor((loadedAt-started)*1000),math.floor((os.clock()-started)*1000),ui and 1 or 0,os.clock()-started>=25 and 1 or 0))end)
task.wait()
if ui and ui:GetAttribute("Loading")==true then
    local held,off=os.clock(),nil
    while ui.Parent and os.clock()-held<90 do
        if ui:GetAttribute("Loading")==true then off=nil elseif not off then off=os.clock()elseif os.clock()-off>=.3 then break end
        local map=ui:GetAttribute("LoadingMap")
        status.Text=(korean and "전장을 준비하는 중" or "Preparing the front")..(type(map)=="string"and map~=""and "  /  "..map or "")
        target=math.max(target,.75+.2*(1-math.exp(-(os.clock()-held)/15)))
        task.wait(.05)
    end
end
advance(1,korean and "출격 준비 완료" or "Ready")
local finishing=os.clock()
while shown<1 and os.clock()-finishing<1 do task.wait(.03)end
gui:SetAttribute("Lifting",true);task.wait()
task.wait(.25)
alive=false
local fade=TweenInfo.new(.35,Enum.EasingStyle.Quad)
for _,o in ipairs(cover:GetDescendants())do
    if o:IsA("TextLabel")then TweenService:Create(o,fade,{TextTransparency=1,BackgroundTransparency=1}):Play()
    elseif o:IsA("Frame")then TweenService:Create(o,fade,{BackgroundTransparency=1}):Play()
    elseif o:IsA("UIStroke")then TweenService:Create(o,fade,{Transparency=1}):Play()end
end
TweenService:Create(cover,fade,{BackgroundTransparency=1}):Play()
task.wait(.4)
gui:Destroy()
