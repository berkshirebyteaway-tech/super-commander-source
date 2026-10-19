local Run=game:GetService('RunService')
local P=require(script.Parent.Parent.Core.PlazaLayout)
local M={}
local function rigOf(model)
    local root=model.PrimaryPart or model:FindFirstChildWhichIsA('BasePart');if not root then return nil end
    local parts,homes={}, {}
    for _,p in ipairs(model:GetDescendants())do if p:IsA('BasePart')then table.insert(parts,p);table.insert(homes,p.CFrame)end end
    return {root=root.CFrame,parts=parts,homes=homes}
end
local function move(rig,delta,list,cfs)
    local m=rig.root*delta*rig.root:Inverse()
    for i,p in ipairs(rig.parts)do table.insert(list,p);table.insert(cfs,m*rig.homes[i])end
end
function M.start(plaza,reduced)
    local center=Vector3.new(P.x,P.y,P.z)
    local marchers,wavers,bobbers,pulses,spinners,sweepers,car,plane={}, {}, {}, {}, {}, {},nil,nil
    local seen={}
    local function add(d)
        if seen[d]then return end
        if d:IsA('Model')then
            if d:GetAttribute('Marcher')then local rig=rigOf(d);if rig then seen[d]=true;rig.phase=(#marchers*1.7)%6.28;rig.group=d:GetAttribute('Group');table.insert(marchers,rig)end
            elseif d:GetAttribute('Orbit')then local rig=rigOf(d);if rig then seen[d]=true;car=rig end
            elseif d:GetAttribute('Glide')then local rig=rigOf(d);if rig then seen[d]=true;plane=rig end end
        elseif d:IsA('BasePart')then
            if d:GetAttribute('Wave')then seen[d]=true;table.insert(wavers,{p=d,home=d.CFrame,phase=#wavers*.9})
            elseif d:GetAttribute('Bob')then seen[d]=true;table.insert(bobbers,{p=d,home=d.CFrame,phase=#bobbers*1.3})
            elseif d:GetAttribute('Pulse')then seen[d]=true;table.insert(pulses,{p=d,base=d.Transparency,phase=#pulses*2.1})
            elseif d:GetAttribute('Spin')then seen[d]=true;table.insert(spinners,{p=d,home=d.CFrame})
            elseif d:GetAttribute('Sweep')then seen[d]=true;table.insert(sweepers,{p=d,home=d.CFrame,range=d:GetAttribute('Sweep')}) end
        end
    end
    task.defer(function()for _,d in ipairs(plaza:GetDescendants())do add(d)end end)
    task.defer(function()pcall(function()require(script.Parent.LobbyHoloMap).attach(plaza)end)end)
    plaza.DescendantAdded:Connect(function(d)task.defer(add,d)end)
    local clock,acc=0,0
    Run.RenderStepped:Connect(function(dt)
        if not plaza.Parent then return end
        local camera=workspace.CurrentCamera
        if not camera or (camera.CFrame.Position-center).Magnitude>420 then return end
        clock+=dt;acc+=dt;if acc<1/30 then return end;acc=0
        local t=clock;local list,cfs={}, {}
        local still=reduced and reduced()
        for _,s in ipairs(marchers)do
            local w=t*(still and 0 or 4)+s.phase
            local delta=CFrame.new(0,math.abs(math.sin(w))*.22,math.sin(w*.5)*.35)*CFrame.Angles(math.sin(w)*.06,0,math.sin(w*.5)*.04)
            move(s,delta,list,cfs)
        end
        if car and not still then
            local a=t*.35;local x,z=math.cos(a)*64,math.sin(a)*40+2
            local heading=CFrame.lookAt(Vector3.zero,Vector3.new(-math.sin(a)*64,0,math.cos(a)*40))
            local target=CFrame.new(center+Vector3.new(x,0,z))*heading*CFrame.Angles(0,-math.pi/2,0)
            local rootHome=car.root
            local m=CFrame.new(target.Position+Vector3.new(0,rootHome.Position.Y-center.Y,0))*target.Rotation*rootHome:Inverse()
            for i,p in ipairs(car.parts)do table.insert(list,p);table.insert(cfs,m*car.homes[i])end
        end
        if plane and not still then
            local a=-t*.22;local pos=center+Vector3.new(math.cos(a)*55,30+math.sin(t*.9)*3,math.sin(a)*34-8)
            local look=CFrame.lookAt(pos,pos+Vector3.new(math.sin(a)*55,0,-math.cos(a)*34))*CFrame.Angles(0,0,math.rad(18))
            local m=look*plane.root.Rotation:Inverse()*CFrame.new(-plane.root.Position)
            for i,p in ipairs(plane.parts)do table.insert(list,p);table.insert(cfs,m*plane.homes[i])end
        end
        for _,f in ipairs(wavers)do table.insert(list,f.p);table.insert(cfs,f.home*CFrame.Angles(0,math.sin(t*3+f.phase)*(still and 0 or .28),0))end
        for _,b in ipairs(bobbers)do table.insert(list,b.p);table.insert(cfs,b.home+Vector3.new(0,still and 0 or math.sin(t*1.4+b.phase)*.45,0))end
        for _,s in ipairs(sweepers)do table.insert(list,s.p);table.insert(cfs,s.home+Vector3.new(still and 0 or math.sin(t*.55)*s.range,0,0))end
        for _,s in ipairs(spinners)do table.insert(list,s.p);table.insert(cfs,s.home*CFrame.Angles(0,still and 0 or t*.8,0))end
        if #list>0 then workspace:BulkMoveTo(list,cfs,Enum.BulkMoveMode.FireCFrameChanged)end
        for _,g in ipairs(pulses)do g.p.Transparency=math.clamp(g.base+(still and 0 or math.sin(t*3+g.phase)*.18),0,1)end
    end)
end
return M
