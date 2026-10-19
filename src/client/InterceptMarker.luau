local TweenService=game:GetService("TweenService")
local L=require(script.Parent.Localization)
local M={}
local danger,white,ink=Color3.fromRGB(255,82,82),Color3.fromRGB(245,248,250),Color3.fromRGB(16,22,30)
local tones={
    mine={Color3.fromRGB(54,226,208),"요격 성공"},
    hit={danger,"요격당함"},
    ally={Color3.fromRGB(191,239,255),"아군 요격"},
    other={Color3.fromRGB(191,239,255),"요격"},
}
M.tones=tones
M.cap=6;local live=0
local recent={}
local function tween(o,t,goal,style,delay)
    local tw=TweenService:Create(o,TweenInfo.new(t,style or Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,delay or 0),goal);tw:Play();return tw
end
local function frame(parent,name,size)
    local f=Instance.new("Frame");f.Name=name;f.AnchorPoint=Vector2.new(.5,.5);f.Position=UDim2.fromScale(.5,.5);f.Size=size;f.BorderSizePixel=0;f.BackgroundTransparency=1;f.Parent=parent;return f
end
local function ring(parent,name,color,thickness)
    local f=frame(parent,name,UDim2.fromOffset(18,18));local c=Instance.new("UICorner");c.CornerRadius=UDim.new(.5,0);c.Parent=f
    local s=Instance.new("UIStroke");s.Color=color;s.Thickness=thickness;s.Parent=f;return f,s
end
local function label(mark)
    return L.text(mark.text)..(mark.count>1 and " ×"..mark.count or "")
end
local function play(mark,reduced)
    mark.epoch+=1;local epoch=mark.epoch
    for _,tw in ipairs(mark.fades)do tw:Cancel()end;table.clear(mark.fades)
    for _,b in ipairs(mark.bars)do b[1].BackgroundTransparency=0;b[2].Transparency=0 end
    mark.label.TextTransparency=0;mark.label.TextStrokeTransparency=.15
    if not reduced then
        mark.pop.Scale=mark.count>1 and 1.35 or 1.7;tween(mark.pop,.28,{Scale=1},Enum.EasingStyle.Back)
        local outer,outerLine=ring(mark.stage,"Burst",mark.color,4);tween(outer,.7,{Size=UDim2.fromOffset(96,96)},Enum.EasingStyle.Quart);tween(outerLine,.7,{Thickness=0,Transparency=1},Enum.EasingStyle.Quad,.1)
        local inner,innerLine=ring(mark.stage,"Shock",white,2.5);tween(inner,.5,{Size=UDim2.fromOffset(64,64)},Enum.EasingStyle.Quart,.06);tween(innerLine,.5,{Transparency=1},Enum.EasingStyle.Quad,.12)
        task.delay(.8,function()outer:Destroy();inner:Destroy()end)
        mark.label.Position=UDim2.new(.5,0,0,80);tween(mark.label,.35,{Position=UDim2.new(.5,0,0,74)},Enum.EasingStyle.Quart)
    end
    local hold=reduced and 1.1 or .85
    for _,b in ipairs(mark.bars)do table.insert(mark.fades,tween(b[1],.5,{BackgroundTransparency=1},nil,hold));table.insert(mark.fades,tween(b[2],.5,{Transparency=1},nil,hold))end
    table.insert(mark.fades,tween(mark.label,.5,{TextTransparency=1,TextStrokeTransparency=1},nil,hold))
    mark.untilAt=os.clock()+hold+.6
    task.delay(hold+.6,function()
        if mark.epoch~=epoch then return end
        if recent[mark.tone]==mark then recent[mark.tone]=nil end
        live=math.max(0,live-1);mark.anchor:Destroy()
    end)
end
function M.show(folder,position,reduced,tone)
    if not position then return end
    tone=tones[tone]and tone or "other"
    local last=recent[tone]
    if last and last.anchor.Parent and os.clock()<last.untilAt-.3 and (last.anchor.Position-position).Magnitude<24 then
        last.count+=1;last.label.Text=label(last);play(last,reduced);return last.gui
    end
    if live>=M.cap then return end
    live+=1
    local color,text=tones[tone][1],tones[tone][2]
    local anchor=Instance.new("Part");anchor.Name="InterceptMark";anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.CastShadow=false
    anchor.Transparency=1;anchor.Size=Vector3.one*.05;anchor.Position=position;anchor.Parent=folder or workspace
    local gui=Instance.new("BillboardGui");gui.Name="Mark";gui.Size=UDim2.fromOffset(140,104);gui.AlwaysOnTop=true;gui.LightInfluence=0;gui.MaxDistance=1e5;gui.Parent=anchor
    gui:SetAttribute("Tone",tone)
    local stage=frame(gui,"Stage",UDim2.fromOffset(96,96));stage.Position=UDim2.new(.5,0,0,48)
    local cross=frame(stage,"Cross",UDim2.fromOffset(30,30));local pop=Instance.new("UIScale");pop.Scale=1;pop.Parent=cross
    local bars={}
    for i,angle in ipairs({45,-45})do
        local bar=frame(cross,"Bar"..i,UDim2.fromOffset(32,6));bar.Rotation=angle;bar.BackgroundColor3=white;bar.BackgroundTransparency=0
        local edge=Instance.new("UIStroke");edge.Color=color;edge.Thickness=1.5;edge.Parent=bar;bars[i]={bar,edge}
    end
    local textLabel=Instance.new("TextLabel");textLabel.Name="Label";textLabel.AnchorPoint=Vector2.new(.5,0);textLabel.Position=UDim2.new(.5,0,0,74);textLabel.Size=UDim2.fromOffset(140,20)
    textLabel.BackgroundTransparency=1;textLabel.Font=Enum.Font.BuilderSansBold;textLabel.TextSize=14;textLabel.TextColor3=tone=="other"and white or color;textLabel.TextStrokeColor3=ink;textLabel.TextStrokeTransparency=.15
    textLabel.AutoLocalize=false;textLabel.Parent=gui
    local mark={anchor=anchor,gui=gui,stage=stage,pop=pop,bars=bars,label=textLabel,color=color,text=text,tone=tone,count=1,epoch=0,fades={},untilAt=0}
    textLabel.Text=label(mark)
    recent[tone]=mark
    play(mark,reduced)
    return gui
end
return M
