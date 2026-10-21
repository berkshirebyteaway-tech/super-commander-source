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
    local overlay=UI.make("Frame",parent,{Name="LobbyIntro",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=60,Active=false})
    local top=UI.make("Frame",overlay,{Name="LetterTop",Size=UDim2.new(1,0,0,0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=60})
    local bottom=UI.make("Frame",overlay,{Name="LetterBottom",AnchorPoint=Vector2.new(0,1),Position=UDim2.fromScale(0,1),Size=UDim2.new(1,0,0,0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,ZIndex=60})
    local kicker=label(overlay,"Kicker","S  U  P  E  R",20,UI.colors.accent);kicker.Position=UDim2.new(.5,0,.42,-34);kicker.Size=UDim2.fromOffset(400,26)
    local title=label(overlay,"Title","COMMANDER",64,UI.colors.ink);title.Position=UDim2.fromScale(.5,.42);title.Size=UDim2.fromOffset(600,72)
    local titleScale=UI.make("UIScale",title,{Scale=1.18})
    local short=parent.AbsoluteSize.Y<500;local ms=short and 52 or 88
    local mark=BrandMark.create(overlay,ms);mark.AnchorPoint=Vector2.new(.5,.5);mark.Position=UDim2.new(.5,0,.42,(short and -50 or -53)-ms/2);mark.ImageTransparency=1;mark.ZIndex=61
    local markScale=UI.make("UIScale",mark,{Scale=1.35})
    local line=UI.make("Frame",overlay,{Name="Line",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,.42,44),Size=UDim2.fromOffset(0,3),BackgroundColor3=UI.colors.accent,BorderSizePixel=0,ZIndex=61})
    local L=require(script.Parent.Localization)
    local seal=label(overlay,"PledgeSeal","NO PAY-TO-WIN",12,UI.colors.accent,true);seal.Position=UDim2.new(.5,0,.42,66);seal.Size=UDim2.fromOffset(0,24)
    seal.AutomaticSize=Enum.AutomaticSize.X;seal.BackgroundColor3=UI.colors.bg;seal.BackgroundTransparency=1;seal.BorderSizePixel=0
    UI.make("UIPadding",seal,{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)});UI.corner(seal,3)
    local sealStroke=UI.make("UIStroke",seal,{Color=UI.colors.accent,Thickness=1.5,Transparency=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
    local sub=label(overlay,"Pledge",L.text("과금으로 이기는 게임이 아닙니다. 지금도, 앞으로도."),short and 15 or 18,UI.colors.ink);sub.Position=UDim2.new(.5,0,.42,short and 96 or 102);sub.Size=UDim2.fromOffset(640,24)
    sub.Font=Enum.Font.BuilderSansBold
    local skill=not short and label(overlay,"Skill",L.text("돈이 아니라 전략으로 이깁니다."),15,UI.colors.muted)or nil
    if skill then skill.Position=UDim2.new(.5,0,.42,128);skill.Size=UDim2.fromOffset(640,22)end
    local function tween(o,t,props,delay,style)
        local tw=TweenService:Create(o,TweenInfo.new(t,style or Enum.EasingStyle.Quint,Enum.EasingDirection.Out,0,false,delay or 0),props);tw:Play();return tw
    end
    camera.CFrame=keys[1]
    task.spawn(function()
        local loading=game:GetService('Players').LocalPlayer:FindFirstChildOfClass('PlayerGui');loading=loading and loading:FindFirstChild('FrontierLoading')
        local held=os.clock();while loading and loading.Parent and os.clock()-held<1.5 do task.wait(.05)end
        tween(top,.45,{Size=UDim2.new(1,0,.1,0)});tween(bottom,.45,{Size=UDim2.new(1,0,.1,0)})
        tween(mark,.45,{ImageTransparency=0},.15);tween(markScale,.6,{Scale=1},.15,Enum.EasingStyle.Back)
        tween(kicker,.5,{TextTransparency=0},.35)
        tween(title,.6,{TextTransparency=0},.55);tween(titleScale,.7,{Scale=1},.55)
        tween(line,.6,{Size=UDim2.fromOffset(300,3)},.85)
        tween(seal,.4,{TextTransparency=0,BackgroundTransparency=.2},1.0);tween(sealStroke,.4,{Transparency=0},1.0)
        tween(sub,.5,{TextTransparency=0},1.15);if skill then tween(skill,.5,{TextTransparency=0},1.3)end
        task.delay(.55,function()if M.active then Audio.play("stinger");Audio.play("start",.6)end end)
        local started=os.clock();local finished=false;local conn,skip
        local function finish(skipped)
            if finished then return end;finished=true;M.active=false
            Step.step('lobby','intro',{result=skipped and 'skipped'or 'complete',duration_ms=(os.clock()-started)*1000})
            if conn then conn:Disconnect()end;if skip then skip:Disconnect()end
            GuiService.TouchControlsEnabled=touchWas
            camera.CFrame=finalCFrame;camera.Focus=focus;camera.CameraType=Enum.CameraType.Custom
            for _,o in ipairs({kicker,title,sub,skill or false})do if o then tween(o,.35,{TextTransparency=1})end end
            tween(seal,.35,{TextTransparency=1,BackgroundTransparency=1});tween(sealStroke,.35,{Transparency=1})
            tween(mark,.35,{ImageTransparency=1})
            tween(line,.35,{BackgroundTransparency=1});tween(top,.4,{Size=UDim2.new(1,0,0,0)});tween(bottom,.4,{Size=UDim2.new(1,0,0,0)})
            task.delay(.45,function()overlay:Destroy()end)
            onDone()
        end
        conn=RunService.RenderStepped:Connect(function()
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
