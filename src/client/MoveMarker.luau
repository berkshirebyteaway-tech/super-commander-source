local G=require(script.Parent.Parent.Core.WorldGeometry)
local NukeFx=require(script.Parent.NukeFx)
local RunService=game:GetService("RunService")
local M={}
M.DURATION=.8
function M.mark(world,tile,reduced)
    if not world or not tile or not world.map or not world.folder then return end
    local m=world.map.meta;local x,y,z=G.toWorld(tile,m.width,m.height)
    local ring=NukeFx.telegraph(world.folder,Vector3.new(x,y,z),3*G.scale,Color3.fromRGB(54,226,208));ring.model.Name="MoveMarker"
    if reduced then task.delay(M.DURATION,function()ring.model:Destroy()end);return ring end
    local parts={};for _,p in ipairs(ring.model:GetChildren())do if p:IsA("BasePart")then table.insert(parts,{p,p.Transparency})end end
    local start=os.clock();local connection
    connection=RunService.Heartbeat:Connect(function()
        local k=(os.clock()-start)/M.DURATION
        if k>=1 or not ring.model.Parent then connection:Disconnect();ring.model:Destroy();return end
        local s=1.8-.8*(1-(1-k)^2)
        pcall(function()ring.model:ScaleTo(s)end)
        for _,e in ipairs(parts)do e[1].Transparency=e[2]+(1-e[2])*k*k end
    end)
    return ring
end
return M
