local UIS=game:GetService("UserInputService")
local M={};M.__index=M
local function part(parent,name)
    local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Material=Enum.Material.SmoothPlastic;p.Transparency=1;p.Parent=parent;return p
end
function M.new(folder)
    local self=setmetatable({folder=folder,pool={},live={},random=Random.new(4129),limit=UIS.TouchEnabled and 24 or 48},M)
    self.capacity=self.limit
    for i=1,self.limit do
        local b=part(folder,"Shard");local stud=part(folder,"Spark");stud.Shape=Enum.PartType.Ball;stud.Material=Enum.Material.Neon
        table.insert(self.pool,{body=b,stud=stud})
    end
    return self
end
function M:clear()
    for _,v in ipairs(self.live) do v.body.Transparency=1;v.stud.Transparency=1;table.insert(self.pool,v) end
    table.clear(self.live);self.folder:SetAttribute("LiveBricks",0)
end
function M:burst(position,colors,count,force,assemble,priority)
    local r=self.random
    self.limit=math.min(self.capacity,UIS.TouchEnabled and 24 or 48)
    priority=priority or 0
    local need=math.min(count,self.limit)-math.max(0,self.limit-#self.live)
    if priority>0 and need>0 then
        for i=#self.live,1,-1 do local v=self.live[i]
            if (v.priority or 0)<priority then v.body.Transparency=1;v.stud.Transparency=1;table.insert(self.pool,v);table.remove(self.live,i);need-=1;if need<=0 then break end end
        end
    end
    for _=1,math.min(count,#self.pool,math.max(0,self.limit-#self.live)) do
        local v=table.remove(self.pool);local a=r:NextNumber(0,math.pi*2);local size=r:NextNumber(.2,.38)
        local spread=r:NextNumber(.65,1.2)*(force or 1)
        v.origin=position+Vector3.new(r:NextNumber(-.35,.35),.18,r:NextNumber(-.35,.35));v.velocity=Vector3.new(math.cos(a)*spread,spread*2.8,math.sin(a)*spread)
        v.life=r:NextNumber(.42,.58);v.age=0;v.assemble=assemble;v.priority=priority;v.spin=r:NextNumber(-5,5);v.angle=a
        v.body.Size=Vector3.new(size*.95,size*.12,size*.38);v.stud.Size=Vector3.one*size*.3
        v.body.Color=colors[r:NextInteger(1,#colors)];v.stud.Color=(colors[2] or v.body.Color):Lerp(Color3.new(1,1,1),.35)
        table.insert(self.live,v)
    end
end
function M:step(dt)
    self.limit=math.min(self.capacity,UIS.TouchEnabled and 24 or 48)
    while #self.live>self.limit do
        local index=1
        for i,v in ipairs(self.live)do if (v.priority or 0)<(self.live[index].priority or 0)then index=i end end
        local v=table.remove(self.live,index);v.body.Transparency=1;v.stud.Transparency=1;table.insert(self.pool,v)
    end
    for i=#self.live,1,-1 do
        local v=self.live[i];v.age+=dt;local t=v.age/v.life
        if t>=1 then
            v.body.Transparency=1;v.stud.Transparency=1;table.insert(self.pool,v);table.remove(self.live,i)
        else
            local p=v.assemble and (1-t)*v.life or v.age
            local at=v.origin+v.velocity*p-Vector3.new(0,5*p*p,0)
            at=Vector3.new(at.X,math.max(v.origin.Y,at.Y),at.Z)
            local cf=CFrame.new(at)*CFrame.Angles(v.spin*p,v.angle+v.spin*p,v.spin*p*.35)
            v.body.CFrame=cf;v.stud.CFrame=CFrame.new(at-v.velocity.Unit*.12)
            local fade=v.assemble and math.clamp((.16-t)/.16,0,1) or math.clamp((t-.55)/.45,0,1)
            v.body.Transparency=fade;v.stud.Transparency=self.flashes==false and 1 or math.max(fade,math.clamp(t*1.6,0,1))
        end
    end
    self.folder:SetAttribute("LiveBricks",#self.live);self.folder:SetAttribute("BrickLimit",self.limit)
end
return M
