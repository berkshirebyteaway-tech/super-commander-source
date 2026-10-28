local UIS=game:GetService('UserInputService')
local Players=game:GetService('Players')
local G=require(script.Parent.Parent.Core.WorldGeometry)
local UnitRules=require(script.Parent.Parent.Core.UnitRules)
local Step=require(script.Parent.TelemetryStep)
local M={active=false}
M.length=8;M.landAt=6.6
M.skipAfter=1.2
local rank={City=0,Port=1,MissileSilo=2,Factory=3,SAMLauncher=4,DefensePost=5}
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
local function pickLots(world,state,mine)
    local W=world.map.meta.width;local list={}
    for _,u in ipairs(state.units or {})do if mine[u.owner] and UnitRules.structures[u.kind]and u.tile then table.insert(list,u)end end
    table.sort(list,function(a,b)
        local la,lb=a.level or 1,b.level or 1;local ca,cb=a.kind=='City'and 1 or 0,b.kind=='City'and 1 or 0
        if ca~=cb then return ca>cb end;if la~=lb then return la>lb end
        if rank[a.kind]~=rank[b.kind]then return rank[a.kind]<rank[b.kind]end;return (a.id or 0)<(b.id or 0)
    end)
    local out={}
    for _,u in ipairs(list)do
        local far=true;for _,o in ipairs(out)do
            local dx,dy=u.tile%W-o.tile%W,math.floor(u.tile/W)-math.floor(o.tile/W);if dx*dx+dy*dy<400 then far=false;break end end
        if far and #out>=1 and u.kind==out[1].kind then for _,v in ipairs(list)do if v.kind~=u.kind and not table.find(out,v)then far=false;break end end end
        if far then table.insert(out,u)end
        if #out>=3 then break end
    end
    if #out<3 then for _,u in ipairs(list)do if #out>=3 then break end;if not table.find(out,u)then table.insert(out,u)end end end
    return out
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
    local up={focus=whole.focus,d=fitD*1.08,tilt=world.tilt,yaw=world.yaw}
    local shots={}
    if not reduced then
        for i,u in ipairs(pickLots(world,state,mine))do
            local x,y,z=G.toWorld(u.tile,W,H);local f=Vector3.new(x,y,z)
            local yaw=world.yaw+(i%2==0 and -.35 or .35)
            table.insert(shots,{a={focus=f,d=34,tilt=math.rad(52),yaw=yaw-.18},b={focus=f,d=30,tilt=math.rad(48),yaw=yaw+.18}})
        end
    end
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
        Step.step('result','cinematic',{result=skipped and 'skipped'or 'complete',value=math.floor((os.clock()-t0)*10)/10,total=#shots})
        if not landed then landed=true;pcall(land)end
        pcall(done)
    end
    table.insert(conns,sink.Activated:Connect(function()if os.clock()-t0>M.skipAfter then finish(true)end end))
    table.insert(conns,UIS.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.Keyboard and os.clock()-t0>M.skipAfter then finish(true)end
    end))
    local lastDetail=0
    table.insert(conns,game:GetService('RunService').RenderStepped:Connect(function()
        local t=os.clock()-t0
        if t>=length then finish(false);return end
        if t>=.6 and not hid and not landed then hid=true;hideUi()end
        if not landed and t>=landAt then landed=true;pcall(land,band)end
        local shot
        if reduced then shot=whole
        elseif t<.6 then shot=start
        elseif t<2.6 then shot=mix(start,whole,smooth((t-.6)/2))
        elseif #shots>0 and t<6.2 then
            local per=3.6/#shots;local i=math.min(#shots,math.floor((t-2.6)/per)+1);local u=(t-2.6-(i-1)*per)/per
            local s=shots[i];local prev=i==1 and whole or shots[i-1].b
            shot=u<.35 and mix(prev,s.a,smooth(u/.35))or mix(s.a,s.b,(u-.35)/.65)
        else
            local from=#shots>0 and shots[#shots].b or whole
            shot=mix(from,up,smooth((t-6.2)/1.2))
        end
        local cf=cframe(shot)
        world.cinemaCamera={cf=cf,focus=shot.focus}
        if os.clock()-lastDetail>.25 and world.lastState then lastDetail=os.clock();pcall(world.setState,world,world.lastState)end
    end))
    return true
end
return M
