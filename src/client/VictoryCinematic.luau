local UIS=game:GetService('UserInputService')
local Players=game:GetService('Players')
local G=require(script.Parent.Parent.Core.WorldGeometry)
local UnitRules=require(script.Parent.Parent.Core.UnitRules)
local Step=require(script.Parent.TelemetryStep)
local M={active=false}
M.length=5;M.landAt=4
M.skipAfter=1.2
local function smooth(t)t=math.clamp(t,0,1);return t*t*(3-2*t)end
local function landBox(world,state,mine)
    local m=world.map.meta;local W,H=m.width,m.height;local owners=world.playback.owners
    local s=math.max(2,math.ceil(math.sqrt(W*H/40000)))
    local x0,y0,x1,y1=math.huge,math.huge,-math.huge,-math.huge
    for y=0,H-1,s do local row=y*W;for x=0,W-1,s do if mine[owners[row+x]] then
        if x<x0 then x0=x end;if x>x1 then x1=x end;if y<y0 then y0=y end;if y>y1 then y1=y end end end end
    for _,u in ipairs(state.units or {})do if mine[u.owner] and UnitRules.structures[u.kind]and u.tile then
        local x,y=u.tile%W,math.floor(u.tile/W);x0,x1,y0,y1=math.min(x0,x),math.max(x1,x),math.min(y0,y),math.max(y1,y)end end
    if x0==math.huge then return nil end
    return {x0=x0-s,y0=y0-s,x1=x1+s,y1=y1+s}
end
local function sweepPoints(world,mine)
    local m=world.map.meta;local W,H=m.width,m.height;local owners=world.playback.owners
    local s=math.max(2,math.ceil(math.sqrt(W*H/40000)))
    local pts,inner={},{};local k=3*s
    local function own(x,y)return x>=0 and y>=0 and x<W and y<H and mine[owners[y*W+x]]end
    for y=0,H-1,s do local row=y*W;for x=0,W-1,s do if mine[owners[row+x]]then local p=Vector2.new(x,y);table.insert(pts,p)
        if own(x-k,y)and own(x+k,y)and own(x,y-k)and own(x,y+k)then table.insert(inner,p)end end end end
    if #pts==0 then return {}end
    if #inner>=3 then pts=inner end
    local function far(from)local best,bd=pts[1],-1;for _,p in ipairs(pts)do local d=(p-from).Magnitude;if d>bd then best,bd=p,d end end;return best end
    local a=far(pts[math.floor(#pts/2)+1]);local b=far(a)
    local c,cd=a,-1;for _,p in ipairs(pts)do local d=math.min((p-a).Magnitude,(p-b).Magnitude);if d>cd then c,cd=p,d end end
    if (a-b).Magnitude<s*6 then return {a}end
    return {a,c,b}
end
local function along(points,u)
    local n=#points;if n==1 then return points[1]end
    local f=math.clamp(u,0,1)*(n-1);local i=math.min(n-1,math.floor(f)+1);local t=f-(i-1)
    local p0,p1,p2,p3=points[math.max(1,i-1)],points[i],points[i+1],points[math.min(n,i+2)]
    return .5*((2*p1)+(-p0+p2)*t+(2*p0-5*p1+4*p2-p3)*t*t+(-p0+3*p1-3*p2+p3)*t*t*t)
end
local function cframe(shot)
    local h=math.cos(shot.tilt)*shot.d
    local eye=shot.focus+Vector3.new(math.sin(shot.yaw)*h,math.sin(shot.tilt)*shot.d,math.cos(shot.yaw)*h)
    return CFrame.lookAt(eye,shot.focus)
end
local function mix(a,b,t)
    return {focus=a.focus:Lerp(b.focus,t),d=a.d+(b.d-a.d)*t,tilt=a.tilt+(b.tilt-a.tilt)*t,yaw=a.yaw+(b.yaw-a.yaw)*t}
end
function M.play(world,state,reduced,land,done)
    if M.active or not world or not world.map or not state or state.phase~='won'or state.observer then return false end
    local pack=script.Parent.Parent;if pack:GetAttribute('LiveVictoryCinematic')==false then return false end
    local mine={[1]=true};local box=landBox(world,state,mine)
    if not box then mine={};for _,f in ipairs(state.factions or {})do if f.teammate then mine[f.id]=true end end;box=next(mine)and landBox(world,state,mine)end
    if not box then return false end
    local m=world.map.meta;local W,H=m.width,m.height
    local cam=workspace.CurrentCamera;local aspect=world:aspect()
    local function centre(x,y)return Vector3.new((x+.5-W/2)*G.scale,G.surfaceY,(y+.5-H/2)*G.scale)end
    local bw,bh=box.x1-box.x0+1,box.y1-box.y0+1
    local span=math.max(bw,bh*aspect)*1.18
    local fitD=math.max(40,span*G.scale/(2*math.tan(math.rad(25))*aspect))
    local start={focus=world.focus or centre(W/2,H/2),d=(cam.CFrame.Position-(world.focus or cam.Focus.Position)).Magnitude,tilt=world.tilt,yaw=world.yaw}
    local whole={focus=centre((box.x0+box.x1)/2,(box.y0+box.y1)/2),d=fitD,tilt=world.tilt,yaw=world.yaw}
    local mapD=math.max(40,math.max(W,H*aspect)*1.04*G.scale/(2*math.tan(math.rad(25))*aspect))
    local map={focus=centre(W/2,H/2),d=mapD,tilt=world.tilt,yaw=world.yaw}
    local hold={focus=map.focus,d=mapD*1.04,tilt=world.tilt,yaw=world.yaw}
    local route={}
    if not reduced then for _,p in ipairs(sweepPoints(world,mine))do table.insert(route,centre(p.X,p.Y))end end
    local flyD=math.clamp(fitD*.34,40,130);local flyTilt=math.rad(54)
    local function fly(u)return {focus=along(route,u),d=flyD,tilt=flyTilt,yaw=world.yaw+(u-.5)*.5}end
    local share=state.player and state.player.share
    if not share then for _,f in ipairs(state.factions or {})do if f.id==1 then share=f.share end end end
    local tint=Color3.fromRGB(table.unpack(require(script.Parent.Parent.Core.CosmeticCatalog).get(state.style).territory))
    local length=reduced and .6 or M.length;local landAt=reduced and .1 or M.landAt
    M.active=true
    local t0=os.clock();local hidden={};local hid=false;local landed=false;local finished=false
    local guiParent=Players.LocalPlayer:WaitForChild('PlayerGui')
    local sinkGui=Instance.new('ScreenGui');sinkGui.Name='VictoryCinematic';sinkGui.IgnoreGuiInset=true;sinkGui.DisplayOrder=1000
    sinkGui.ResetOnSpawn=false;sinkGui.ScreenInsets=Enum.ScreenInsets.None
    local sink=Instance.new('TextButton');sink.Name='Skip';sink.Text='';sink.BackgroundTransparency=1;sink.Size=UDim2.fromScale(1,1)
    sink.AutoButtonColor=false;sink.Selectable=false;sink.Parent=sinkGui;sinkGui.Parent=guiParent
    local bandGui=Instance.new('ScreenGui');bandGui.Name='VictoryBand';bandGui.DisplayOrder=5;bandGui.ResetOnSpawn=false
    bandGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;bandGui.Parent=guiParent
    local sc=require(script.Parent.Theme).scale or 1;bandGui:SetAttribute('UIScale',sc);require(script.Parent.FullBleed).watch(bandGui)
    local band=Instance.new('Frame');band.Name='Main';band.BackgroundTransparency=1;band.Size=UDim2.fromScale(1/sc,1/sc);band.Parent=bandGui
    local bs=Instance.new('UIScale');bs.Scale=sc;bs.Parent=band
    if not reduced then band.Size=UDim2.fromScale(1/sc,1.55/sc)end
    local function hideUi()
        for _,g in ipairs(guiParent:GetChildren())do if g:IsA('ScreenGui')and g~=sinkGui and g~=bandGui and g.Enabled then g.Enabled=false;table.insert(hidden,g)end end
    end
    local function showUi()for _,g in ipairs(hidden)do if g.Parent then g.Enabled=true end end;table.clear(hidden)end
    local conns={}
    local function finish(skipped)
        if finished then return end;finished=true;M.active=false
        for _,c in ipairs(conns)do c:Disconnect()end
        local last=world.cinemaCamera;world.cinemaCamera=nil
        if last then world.dropExitCamera={cf=last.cf,at=os.clock()}end
        showUi();sinkGui:Destroy();task.delay(1.5,function()bandGui:Destroy()end)
        Step.step('result','cinematic',{result=skipped and 'skipped'or 'complete',value=math.floor((os.clock()-t0)*10)/10,total=#route})
        if not landed and not skipped then landed=true;pcall(land)end
        pcall(done)
    end
    table.insert(conns,sink.Activated:Connect(function()if os.clock()-t0>M.skipAfter then finish(true)end end))
    table.insert(conns,UIS.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.Keyboard and os.clock()-t0>M.skipAfter then finish(true)end
    end))
    local counted,flashed,lit=false,false,false
    local Lighting=game:GetService('Lighting')
    local grade=Instance.new('ColorCorrectionEffect');grade.Name='VictoryFlash';grade.TintColor=Color3.new(1,1,1);grade.Parent=Lighting
    table.insert(conns,{Disconnect=function()grade:Destroy()end})
    local function light()
        local spot={neutral=Color3.fromRGB(18,24,32)};for id in pairs(mine)do spot[id]=false end;world:spotlight(spot)
    end
    table.insert(conns,{Disconnect=function()if lit then pcall(world.spotlight,world,nil)end end})
    local function flash()
        local TS=game:GetService('TweenService');grade.TintColor=Color3.new(1,1,1):Lerp(tint,.45);grade.Brightness=.3
        TS:Create(grade,TweenInfo.new(.55,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Brightness=0,TintColor=Color3.new(1,1,1)}):Play()
    end
    local function countUp()
        local UI=require(script.Parent.Theme);local L=require(script.Parent.Localization)
        local l=UI.label(band,'Share','',30,tint);UI.display(l);l.AnchorPoint=Vector2.new(.5,.5);l.Position=UDim2.fromScale(.5,.53)
        l.Size=UDim2.fromOffset(320,44);l.TextXAlignment=Enum.TextXAlignment.Center;l.TextWrapped=false;l.ZIndex=90
        local from=os.clock();local goal=math.floor(share*100+.5)
        local c;c=game:GetService('RunService').RenderStepped:Connect(function()
            local u=smooth((os.clock()-from)/.8);l.Text=L.text('영토')..' '..math.floor(goal*u+.5)..'%'
            if u>=1 or not l.Parent then c:Disconnect()end
        end)
    end
    local lastDetail=0
    table.insert(conns,game:GetService('RunService').RenderStepped:Connect(function()
        local t=os.clock()-t0
        if t>=length then finish(false);return end
        if t>=.4 and not hid and not landed then hid=true;hideUi()end
        if not landed and t>=landAt then landed=true;pcall(land,band)end
        if not reduced and share and t>=3 and not counted then counted=true;pcall(countUp)end
        if not reduced and t>=.4 and not lit then lit=true;pcall(light)end
        if not reduced and t>=3.3 and not flashed then flashed=true;pcall(flash)end
        local shot
        if reduced then shot=whole
        elseif t<.4 then shot=start
        elseif #route==0 then shot=t<2.8 and mix(start,whole,smooth((t-.4)/2.4))or mix(whole,map,smooth((t-2.8)/1.2))
        elseif t<2.8 then
            local u=smooth((t-.4)/2.4);local s=fly(u)
            shot=t<1 and mix(start,s,smooth((t-.4)/.6))or s
        elseif t<4 then shot=mix(fly(1),map,smooth((t-2.8)/1.2))
        else shot=mix(map,hold,(t-4)/(length-4))end
        local cf=cframe(shot)
        world.cinemaCamera={cf=cf,focus=shot.focus}
        if os.clock()-lastDetail>.25 and world.lastState then lastDetail=os.clock();pcall(world.setState,world,world.lastState)end
    end))
    return true
end
return M
