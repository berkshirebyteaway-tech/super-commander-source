local Run=game:GetService('RunService')
local Core=game.ReplicatedStorage:WaitForChild('FrontierNative'):WaitForChild('Core')
local Geometry=require(Core.WorldGeometry)
local Scale=require(Core.CommanderScale)
local Drop=require(Core.SpawnDrop)
local Terrain=require(Core.Terrain)
local Avatar=require(script.Parent.RankedAIAvatar)
local M={}
M.walkSpeed=34
local function folder()
    local f=workspace:FindFirstChild('RankedAICommanders')
    if not f then f=Instance.new('Folder');f.Name='RankedAICommanders';f.Parent=workspace end
    return f
end
local function rand(a,b)return a+math.random()*(b-a)end
function M.begin(room,seat,dropService)
    local plan=room.rankedAI;if not plan then return end
    local now=os.clock()
    room.aiCommander={plan=plan,seat=seat,drop=dropService,readyAt=now+rand(.8,2.6),picks=math.random()<.3 and 2 or 1,picked=0}
    task.spawn(function()
        local model=Avatar.build(plan.look,plan.name);local a=room.aiCommander
        if not model or not a or room.closedAI then if model then model:Destroy()end;return end
        local hum=model:FindFirstChildOfClass('Humanoid');local root=model:FindFirstChild('HumanoidRootPart')
        if not hum or not root then model:Destroy();return end
        hum.WalkSpeed=M.walkSpeed;hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
        model:SetAttribute('FrontierRoom',room.id);model:SetAttribute('CommanderUserId',plan.userId);model:SetAttribute('CommanderDisplayName',plan.name)
        model:SetAttribute('CommanderLevel',math.clamp(3+math.floor(plan.t/60)+math.random(0,6),2,40));model:SetAttribute('ToyfrontGrowth',1)
        for _,o in ipairs(model:GetDescendants())do if o:IsA('BasePart')then o.CollisionGroup='FrontierCommanders'end end
        model:PivotTo(CFrame.new(0,Geometry.surfaceY+4,0));root.Anchored=true
        model:SetAttribute('ToyfrontBaseScale',model:GetScale())
        model.Parent=folder()
        pcall(function()for _,o in ipairs(model:GetDescendants())do if o:IsA('BasePart')then o:SetNetworkOwner(nil)end end end)
        local animator=hum:FindFirstChildOfClass('Animator')or Instance.new('Animator',hum)
        local tracks={}
        for k,id in pairs(Avatar.animations)do local anim=Instance.new('Animation');anim.AnimationId=id;local ok,t=pcall(animator.LoadAnimation,animator,anim);if ok then t.Looped=true;tracks[k]=t end end
        if tracks.idle then tracks.idle:Play()end
        hum.Running:Connect(function(speed)
            local moving=speed>.5
            if tracks.run then if moving and not tracks.run.IsPlaying then tracks.run:Play(.2);if tracks.idle then tracks.idle:Stop(.2)end elseif not moving and tracks.run.IsPlaying then tracks.run:Stop(.2);if tracks.idle then tracks.idle:Play(.2)end end end
        end)
        a.model=model;a.hum=hum;a.root=root
        Avatar.face(plan,model)
    end)
end
local function ownTileNear(s,seat,center,radius)
    local w,h=s.map.meta.width,s.map.meta.height
    for _=1,12 do
        local x=center%w+math.random(-radius,radius);local y=center//w+math.random(-radius,radius)
        if x>=0 and y>=0 and x<w and y<h then local t=y*w+x
            if s.sim:owner(t)==seat and Terrain.isLand(s.sim.terrain[t+1])then return t end
        end
    end
    return nil
end
local function place(a,s,tile)
    if not a.model or not tile then return end
    local x,y,z=Geometry.toWorld(tile,s.map.meta.width,s.map.meta.height)
    a.root.Anchored=false;a.model:PivotTo(CFrame.new(x,y+4,z));a.root.AssemblyLinearVelocity=Vector3.zero;a.home=tile
end
function M.step(room,now,dt)
    local a=room.aiCommander;if not a then return end
    local s=room.session;local d=room.drop
    if s.phase=='spawn'and d and not d.finished then
        if not a.ready and now>=a.readyAt then a.ready=true;d:markReady(a.seat,now)end
        if d.startAt and not a.pickAt then a.pickAt=d.startAt+Drop.planeSeconds+rand(1.2,5)end
        if a.pickAt and a.picked<a.picks and now>=a.pickAt then
            local tile=d:randomTile(a.seat)
            if a.picked>0 then tile=require(Core.SpawnRules).random(s,'ai-repick-'..tostring(a.plan.key),tostring(now),d.players[a.seat].area)or tile end
            if tile and a.drop.pick(room,a.seat,tile,now)then a.picked+=1;place(a,s,tile)end
            a.pickAt=now+rand(1.5,3)
        end
        return
    end
    if not a.model or not a.hum then return end
    local p=s.sim.players[a.seat];if not p then return end
    a.hum.WalkSpeed=room.paused and 0 or M.walkSpeed
    if not a.home then local tile=s.spawned and s.spawned[a.seat]or p.spawnTile;if tile then place(a,s,tile);a.nextMove=now+rand(1,3)end;return end
    a.scaleAt=(a.scaleAt or 0)+dt
    if a.scaleAt>=.3 then local elapsed=a.scaleAt;a.scaleAt=0
        local old=a.model:GetAttribute('ToyfrontGrowth')or 1
        local scale=Scale.approach(old,Scale.target(p.tiles.size,s:landTiles(),p.troops),elapsed)
        if math.abs(scale-old)>=.002 then a.model:SetAttribute('ToyfrontGrowth',scale);pcall(function()a.model:ScaleTo((a.model:GetAttribute('ToyfrontBaseScale')or 1)*scale)end)end
    end
    if p.tiles.size==0 or room.endedAt then return end
    if now>=(a.nextMove or 0)then
        local here=Geometry.toTile(a.root.Position.X,a.root.Position.Z,s.map.meta.width,s.map.meta.height)or a.home
        local radius=math.clamp(math.floor(6+math.sqrt(p.tiles.size)/3),6,40)
        local tile=ownTileNear(s,a.seat,here,radius)or ownTileNear(s,a.seat,a.home,radius)
        if tile then local x,y,z=Geometry.toWorld(tile,s.map.meta.width,s.map.meta.height);a.hum:MoveTo(Vector3.new(x,y+2,z))end
        a.nextMove=now+(math.random()<.35 and rand(5,10)or rand(1.5,4))
    end
    local at=a.root.Position;local hx,hz=s.map.meta.width*Geometry.scale/2-1,s.map.meta.height*Geometry.scale/2-1
    if math.abs(at.X)>hx or math.abs(at.Z)>hz or at.Y<Geometry.surfaceY-2 then place(a,s,a.home)end
end
function M.sweep(rooms)
    local live={}
    for _,room in ipairs(rooms)do if room.aiCommander then live[room.id]=true end end
    local f=workspace:FindFirstChild('RankedAICommanders')
    if f then for _,m in ipairs(f:GetChildren())do if not live[m:GetAttribute('FrontierRoom')]then m:Destroy()end end end
    Avatar.sweep()
end
function M.close(room)
    room.closedAI=true;local a=room.aiCommander;if a and a.model then a.model:Destroy()end
end
if Run:IsStudio()then M.debug=true end
return M
