local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local UI=require(script.Parent.Theme)
local Audio=require(script.Parent.ToyAudio)
local BrandMark=require(script.Parent.BrandMark)
local P=require(script.Parent.Parent.Core.PlazaLayout)
local me=game:GetService("Players").LocalPlayer
local M={played=me~=nil and me:GetAttribute("SuperCommanderHop")==true,active=false}
local DURATION=3.4
local function smooth(t) return t*t*(3-2*t) end
local function label(parent,name,text,size,color,mono)
    local l=UI.make("TextLabel",parent,{Name=name,AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1,Text=text,TextSize=size,TextColor3=color,TextTransparency=1,AutoLocalize=false,ZIndex=61})
    UI.display(l,mono);l:SetAttribute("LocalizationSkip",true);return l
end
function M.play(parent,displayName,finalCFrame,focus,onDone)
    if M.played then onDone();return end
    M.played=true;M.active=true
    local Step=require(script.Parent.TelemetryStep);Step.step('lobby','introStart',{result='opened'})
    local GuiService=game:GetService("GuiService");local touchWas=GuiService.TouchControlsEnabled;GuiService.TouchControlsEnabled=false
    local camera=workspace.CurrentCamera;camera.CameraType=Enum.CameraType.Scriptable
    local o=Vector3.new(P.x,P.y,P.z)
    local keys={
        CFrame.lookAt(o+Vector3.new(-30,120,70),o+Vector3.new(0,4,2)),
        CFrame.lookAt(o+Vector3.new(46,34,44),o+Vector3.new(0,30,-120)),
        finalCFrame,
    }
    if require(script.Parent.LobbyStage).attached then
        keys[1]=CFrame.lookAt(o+Vector3.new(0,38,30),o+Vector3.new(0,6,0))
        keys[2]=CFrame.lookAt(o+Vector3.new(20,14,36),o+Vector3.new(0,7,4))
    end
    local overlay=UI.make("Frame",parent,{Name="LobbyIntro",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=60,Active=false})
    local barTop=UI.make("Frame",overlay,{Name="LetterTop",Size=UDim2.new(1,0,0,0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=60})
    local bottom=UI.make("Frame",overlay,{Name="LetterBottom",AnchorPoint=Vector2.new(0,1),Position=UDim2.fromScale(0,1),Size=UDim2.new(1,0,0,0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=60})
    local size=parent.AbsoluteSize;local short=size.Y<500;local portrait=size.X<size.Y
    local ws=portrait and 52 or short and 54 or 84;local ay=portrait and .3 or .42;local cx=portrait and .5 or .58
    local cmdH=math.floor(size.Y*(portrait and .36 or short and .7 or .66))
    local mark=BrandMark.commander(overlay,cmdH);mark.AnchorPoint=Vector2.new(0,1);mark.ImageTransparency=1;mark.ZIndex=59
    local markAt=portrait and UDim2.new(0,-20,.9,6) or UDim2.new(.03,0,.9,12)
    mark.Position=markAt+UDim2.fromOffset(-mark.Size.X.Offset,0)
    if not BrandMark.available(mark)then cx=.5 end
    local ink=Color3.fromRGB(10,8,6)
    local function sticker(name,text,size,fill,rotation,y)
        local s=label(overlay,name,text,size,Color3.fromRGB(17,17,17));s.Position=UDim2.new(cx,0,ay,y);s.Size=UDim2.fromOffset(0,size+12)
        s.AutomaticSize=Enum.AutomaticSize.X;s.BackgroundColor3=fill;s.BackgroundTransparency=1;s.BorderSizePixel=0;s.Rotation=rotation
        UI.make("UIPadding",s,{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12),PaddingTop=UDim.new(0,2)});UI.corner(s,6)
        local stroke=UI.make("UIStroke",s,{Color=ink,Thickness=3,Transparency=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border});return s,stroke
    end
    local kicker,kickerStroke=sticker("Kicker","TAKE THE MAP!",18,Color3.fromRGB(255,216,74),-5,-ws-40)
    pcall(function()kicker.Font=Enum.Font.LuckiestGuy end)
    local top=label(overlay,"TitleTop","SUPER",ws,Color3.fromRGB(255,216,74));top.Position=UDim2.new(cx,0,ay,-math.floor(ws*.5));top.Size=UDim2.fromOffset(640,ws)
    local title=label(overlay,"Title","COMMANDER",ws,Color3.new(1,1,1));title.Position=UDim2.new(cx,0,ay,math.floor(ws*.45));title.Size=UDim2.fromOffset(640,ws)
    for _,o in ipairs({top,title})do BrandMark.word(o,math.max(3,math.floor(ws*.12)));o.Ink.Transparency=1;o.Rotation=-3 end
    local titleScale=UI.make("UIScale",title,{Scale=1.18});local topScale=UI.make("UIScale",top,{Scale=1.25})
    local L=require(script.Parent.Localization)
    local seal,sealStroke=sticker("PledgeSeal","NO PAY-TO-WIN",15,Color3.fromRGB(248,248,244),3,ws+22)
    pcall(function()seal.Font=Enum.Font.FredokaOne end)
    local sub=label(overlay,"Pledge",L.text("과금으로 이기는 게임이 아닙니다. 지금도, 앞으로도."),portrait and 17 or short and 17 or 22,Color3.new(1,1,1));sub.Position=UDim2.new(cx,0,ay,ws+64);sub.Size=UDim2.fromOffset(portrait and size.X-32 or 640,26)
    sub.TextWrapped=true;pcall(function()sub.Font=Enum.Font.FredokaOne end);UI.make("UIStroke",sub,{Name="Ink",Color=ink,Thickness=2.5,Transparency=1})
    local function inkOf(o)return o and o:FindFirstChild("Ink")end
    local function tween(o,t,props,delay,style)
        local tw=TweenService:Create(o,TweenInfo.new(t,style or Enum.EasingStyle.Quint,Enum.EasingDirection.Out,0,false,delay or 0),props);tw:Play();return tw
    end
    camera.CFrame=keys[1]
    task.spawn(function()
        local loading=game:GetService('Players').LocalPlayer:FindFirstChildOfClass('PlayerGui');loading=loading and loading:FindFirstChild('FrontierLoading')
        local held=os.clock();while loading and loading.Parent and os.clock()-held<1.5 do task.wait(.05)end
        tween(barTop,.45,{Size=UDim2.new(1,0,.1,0)});tween(bottom,.45,{Size=UDim2.new(1,0,.1,0)})
        tween(mark,.35,{ImageTransparency=0},.1);tween(mark,.7,{Position=markAt},.1,Enum.EasingStyle.Back)
        tween(kicker,.4,{TextTransparency=0,BackgroundTransparency=0},.35);tween(kickerStroke,.4,{Transparency=0},.35)
        tween(top,.5,{TextTransparency=0},.45);tween(top.Ink,.5,{Transparency=0},.45);tween(topScale,.6,{Scale=1},.45,Enum.EasingStyle.Back)
        tween(title,.6,{TextTransparency=0},.55);tween(title.Ink,.6,{Transparency=0},.55);tween(titleScale,.7,{Scale=1},.55,Enum.EasingStyle.Back)
        tween(seal,.4,{TextTransparency=0,BackgroundTransparency=0},1.0);tween(sealStroke,.4,{Transparency=0},1.0)
        tween(sub,.5,{TextTransparency=0},1.15);tween(sub.Ink,.5,{Transparency=0},1.15)
        task.delay(.55,function()if M.active then Audio.play("stinger");Audio.play("start",.6)end end)
        local started=os.clock();local finished=false;local conn,skip
        local function finish(skipped)
            if finished then return end;finished=true;M.active=false
            Step.step('lobby','intro',{result=skipped and 'skipped'or 'complete',duration_ms=(os.clock()-started)*1000})
            if conn then conn:Disconnect()end;if skip then skip:Disconnect()end
            GuiService.TouchControlsEnabled=touchWas
            camera.CFrame=finalCFrame;camera.Focus=focus;camera.CameraType=Enum.CameraType.Custom
            for _,o in ipairs({top,title,sub})do if o then tween(o,.35,{TextTransparency=1});local s=inkOf(o);if s then tween(s,.35,{Transparency=1})end end end
            for _,o in ipairs({kicker,seal})do tween(o,.35,{TextTransparency=1,BackgroundTransparency=1})end
            tween(kickerStroke,.35,{Transparency=1});tween(sealStroke,.35,{Transparency=1})
            tween(mark,.35,{ImageTransparency=1})
            tween(barTop,.4,{Size=UDim2.new(1,0,0,0)});tween(bottom,.4,{Size=UDim2.new(1,0,0,0)})
            task.delay(.45,function()overlay:Destroy()end)
            onDone()
        end
        local gamePanel=parent:FindFirstChild('Game')
        local function abort()
            if finished then return end;finished=true;M.active=false;M.played=false
            Step.step('lobby','intro',{result='cancelled',duration_ms=(os.clock()-started)*1000})
            if conn then conn:Disconnect()end;if skip then skip:Disconnect()end
            GuiService.TouchControlsEnabled=touchWas;overlay:Destroy()
        end
        conn=RunService.RenderStepped:Connect(function()
            if gamePanel and gamePanel.Visible then abort();return end
            local t=math.clamp((os.clock()-started)/DURATION,0,1)
            local cf
            if t<.55 then cf=keys[1]:Lerp(keys[2],smooth(t/.55)) else cf=keys[2]:Lerp(keys[3],smooth((t-.55)/.45)) end
            camera.CFrame=cf
            if t>=1 then finish()end
        end)
        skip=UIS.InputBegan:Connect(function(input)
            local kind=input.UserInputType
            if kind==Enum.UserInputType.Keyboard or kind==Enum.UserInputType.MouseButton1 or kind==Enum.UserInputType.Touch or kind==Enum.UserInputType.Gamepad1 then finish(true)end
        end)
    end)
end
return M
