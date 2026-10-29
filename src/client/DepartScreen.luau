local Players=game:GetService('Players')
local Tween=game:GetService('TweenService')
local GuiService=game:GetService('GuiService')
local K=require(script.Parent.Kit20)
local L=require(script.Parent.Localization)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local Tags=require(script.Parent.TagChips)
local C=K.colors
local M={}
local gui,info,since
local STEPS={'전장 잡기','이동','모이기','지도'}
local function make(class,parent,props)return K.make(class,parent,props)end
local function text(parent,name,value,size,color,weight,align)
    local t=make('TextLabel',parent,{Name=name,Text=value,TextSize=size,TextColor3=color,BackgroundTransparency=1,TextXAlignment=align or Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd})
    local f=K.fonts[weight or 800];if f then t.FontFace=f else t.Font=Enum.Font.BuilderSansBold end
    return t
end
local function round(o,r)make('UICorner',o,{CornerRadius=r=='pill'and UDim.new(1,0)or UDim.new(0,r)})end
local function safe()
    local cam=workspace.CurrentCamera;local v=cam and cam.ViewportSize or Vector2.new(1366,768)
    local ok,a=pcall(function()return GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets)end)
    if ok and a and a.Max.X>a.Min.X and a.Max.Y>a.Min.Y then return v,math.max(0,a.Min.X),math.max(0,a.Min.Y),math.max(0,v.X-a.Max.X),math.max(0,v.Y-a.Max.Y)end
    return v,0,0,0,0
end
local function chip(parent,name,value,fill,alpha,ink,h,fs)
    local f=make('Frame',parent,{Name=name,BackgroundColor3=fill,BackgroundTransparency=alpha,BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,h)});round(f,6)
    make('UIPadding',f,{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)})
    local t=text(f,'Text',value,fs,ink,800);t.AutomaticSize=Enum.AutomaticSize.X;t.Size=UDim2.fromOffset(0,h);t.TextTruncate=Enum.TextTruncate.None
    return f
end
local function build()
    if gui then gui:Destroy()end
    local v,l,t,r,b=safe()
    local pt=v.X<600 or v.X<v.Y;local short=not pt and v.Y<500
    local s=math.clamp(math.min(v.X/(pt and 375 or short and 667 or 1366),v.Y/(pt and 667 or short and 375 or 768)),.6,1.6)
    local function n(x)return math.floor(x*s+.5)end
    gui=make('ScreenGui',Players.LocalPlayer:WaitForChild('PlayerGui'),{Name='FrontierDepart',IgnoreGuiInset=true,ScreenInsets=Enum.ScreenInsets.None,ResetOnSpawn=false,DisplayOrder=48,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,AutoLocalize=false})
    pcall(function()gui.ClipToDeviceSafeArea=false end)
    local cover=make('TextButton',gui,{Name='Cover',Text='',AutoButtonColor=false,Active=true,Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0})
    make('UIGradient',cover,{Name='Wash',Rotation=90,Color=ColorSequence.new(Color3.fromRGB(13,27,41),Color3.fromRGB(7,11,16))})
    local r0=info.rules or {}
    local map=K.map(cover,'Map',r0.map,math.floor(v.X),math.floor(v.Y),0,.5);map.ZIndex=1
    for _,o in ipairs(map:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=1 end end
    map.BackgroundTransparency=1
    local side=make('Frame',cover,{Name='Shade',BackgroundColor3=Color3.fromRGB(7,11,16),BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=2})
    make('UIGradient',side,{Rotation=pt and 90 or 0,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.1),NumberSequenceKeypoint.new(.55,.7),NumberSequenceKeypoint.new(1,.35)})})
    local x0,x1=l+(pt and n(20)or n(56)),v.X-r-(pt and n(20)or n(56))
    local y0=t+(pt and n(72)or short and n(28)or n(64))
    local body=make('Frame',cover,{Name='Body',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=3})
    local kfs,tfs,cfs,ch=pt and n(13)or n(15),pt and n(40)or short and n(34)or n(60),pt and n(12)or n(13),pt and n(24)or n(28)
    local kicker=text(body,'Kicker',L.text('출격'),kfs,C.accent,900);K.box(kicker,x0,y0,200,kfs+4)
    local meta=Maps.meta(r0.map)or {}
    local title=text(body,'Title',L.text(meta.label or r0.map or ''),tfs,C.ink,900);title:SetAttribute('LocalizationSkip',true)
    K.box(title,x0,y0+kfs+n(6),x1-x0,tfs+n(6))
    local chips=make('Frame',body,{Name='Chips',BackgroundTransparency=1});K.box(chips,x0,y0+kfs+n(12)+tfs,x1-x0,ch)
    make('UIListLayout',chips,{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,n(6)),SortOrder=Enum.SortOrder.LayoutOrder})
    local teams=r0.mode=='teams'
    chip(chips,'Mode',L.text(teams and '팀전'or '개인전'),teams and Tags.colors.teams or Tags.colors.ffa,.8,teams and Color3.fromRGB(196,176,255)or Color3.fromRGB(142,184,255),ch,cfs).LayoutOrder=1
    local people=info.members or {}
    chip(chips,'People',L.text('사람')..' '..#people,C.raised or C.panel,0,C.ink,ch,cfs).LayoutOrder=2
    if (info.ai or 0)>0 then chip(chips,'AI',string.format('AI %d',info.ai),C.raised or C.panel,0,C.muted,ch,cfs).LayoutOrder=3 end
    local sh,lfs=n(6),pt and n(12)or n(13)
    local sy=v.Y-b-(pt and n(40)or short and n(26)or n(48))-lfs-n(8)-sh
    local steps=make('Frame',body,{Name='Steps',BackgroundTransparency=1});K.box(steps,x0,sy,x1-x0,sh+n(8)+lfs+4)
    local gap=n(10);local sw=math.floor(((x1-x0)-gap*3)/4)
    for i,name in ipairs(STEPS)do
        local f=make('Frame',steps,{Name='Step'..i,BackgroundTransparency=1});K.box(f,(i-1)*(sw+gap),0,sw,sh+n(8)+lfs+4)
        local track=make('Frame',f,{Name='Track',BackgroundColor3=Color3.fromRGB(28,40,54),BorderSizePixel=0});K.box(track,0,0,sw,sh);round(track,'pill')
        local fill=make('Frame',track,{Name='Fill',BackgroundColor3=C.accent,BorderSizePixel=0,Size=UDim2.fromScale(0,1)});round(fill,'pill')
        local label=text(f,'Label',L.text(name),lfs,C.muted,800);label:SetAttribute('Base',L.text(name));K.box(label,0,sh+n(8),sw,lfs+4)
    end
    local fs=pt and n(44)or short and n(40)or n(56);local nfs=pt and n(11)or n(12);local fg=pt and n(10)or n(14)
    local fy=sy-n(pt and 20 or 28)-fs-nfs-n(6)
    local faces=make('Frame',body,{Name='Faces',BackgroundTransparency=1});K.box(faces,x0,fy,x1-x0,fs+nfs+n(8))
    local per=fs+fg;local fit=math.max(1,math.floor((x1-x0+fg)/per));local shown=math.min(#people,fit-((info.ai or 0)>0 and 1 or 0))
    for i=1,shown do local m=people[i]
        local face=make('ImageLabel',faces,{Name='Face',BackgroundColor3=Color3.fromRGB(31,58,77),BorderSizePixel=0,ScaleType=Enum.ScaleType.Crop,ImageTransparency=0})
        face:SetAttribute('UserId',m.userId);round(face,'pill');K.box(face,(i-1)*per,0,fs,fs)
        if m.userId and m.userId>0 then face.Image='rbxthumb://type=AvatarHeadShot&id='..tostring(m.userId)..'&w=150&h=150'end
        make('UIStroke',face,{Name='Ring',Color=C.accent,Thickness=math.max(2,n(3)),ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
        local p=Players:GetPlayerByUserId(m.userId or 0)
        local nm=text(face,'Name',p and p.DisplayName or m.name or '',nfs,C.ink,700,Enum.TextXAlignment.Center);nm:SetAttribute('LocalizationSkip',true)
        nm.Position=UDim2.new(.5,-math.floor(per/2),1,n(6));nm.Size=UDim2.fromOffset(per,nfs+4)
    end
    local rest=#people-shown+(info.ai or 0)
    if rest>0 then
        local more=make('Frame',faces,{Name='More',BackgroundTransparency=1});K.box(more,shown*per,0,fs,fs);round(more,'pill')
        make('UIStroke',more,{Color=C.line,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
        local mt=text(more,'Text','+'..rest,nfs+1,C.muted,800,Enum.TextXAlignment.Center);mt.Size=UDim2.fromScale(1,1)
        local cap=text(more,'Name',#people>shown and ''or 'AI',nfs,C.muted,700,Enum.TextXAlignment.Center);cap.Position=UDim2.new(.5,-math.floor(per/2),1,n(6));cap.Size=UDim2.fromOffset(per,nfs+4)
    end
    for _,o in ipairs(body:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=4 end end
end
local function fill(i)return gui and gui.Cover.Body.Steps:FindFirstChild('Step'..i)end
function M.step(i,to,t)
    if not gui then return end
    for k=1,#STEPS do local s=fill(k);if s then
        local bar=s.Track.Fill;local label=s.Label
        if k<i then bar.Size=UDim2.fromScale(1,1);label.TextColor3=C.ink
        elseif k==i then label.TextColor3=C.accent
            if K.reduced or not t then bar.Size=UDim2.fromScale(to or .5,1)else Tween:Create(bar,TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.fromScale(to or .5,1)}):Play()end
        else bar.Size=UDim2.fromScale(0,1);label.TextColor3=C.muted end
    end end
end
function M.show(room)
    if gui and gui.Enabled then return false end
    info={rules=room.rules,members=room.members or {},ai=room.ai or 0};since=os.clock()
    build();M.step(1,.85,1.2)
    local o=gui.Cover.Body;if not K.reduced then K.appear(o,{dy=16,t=.18})end
    return true
end
function M.shown()return gui~=nil and gui.Enabled end
function M.age()return since and os.clock()-since or 0 end
function M.ride()
    if not gui then return end
    M.step(2,.6,1.5)
    pcall(function()
        local copy=gui:Clone();copy.Enabled=true
        local drawn=copy.Cover:FindFirstChild('Map');if drawn then drawn:Destroy()end
        local s2=copy.Cover.Body.Steps.Step2;s2.Track.Fill.Size=UDim2.fromScale(.6,1)
        for k=1,4 do local s=copy.Cover.Body.Steps['Step'..k];if k<2 then s.Track.Fill.Size=UDim2.fromScale(1,1)elseif k>2 then s.Track.Fill.Size=UDim2.fromScale(0,1)end end
        game:GetService('TeleportService'):SetTeleportGui(copy)
    end)
end
function M.hide()
    if not gui then return end
    local g=gui;gui=nil;info=nil
    if K.reduced then g:Destroy();return end
    local f=TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    for _,o in ipairs(g:GetDescendants())do
        if o:IsA('TextLabel')then Tween:Create(o,f,{TextTransparency=1}):Play()elseif o:IsA('ImageLabel')then Tween:Create(o,f,{ImageTransparency=1}):Play()
        elseif o:IsA('GuiObject')and o.BackgroundTransparency<1 then Tween:Create(o,f,{BackgroundTransparency=1}):Play()end
    end
    task.delay(.14,function()g:Destroy()end)
end
return M
