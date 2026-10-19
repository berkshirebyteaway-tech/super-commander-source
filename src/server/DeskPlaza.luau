local P=require(game.ReplicatedStorage.FrontierNative.Core.PlazaLayout)
local M={create=require(script.Parent.ToyShowroom).create}
function M.spawn(userId)
    local a=(math.abs(userId)%12)/12*math.pi*2
    return CFrame.lookAt(Vector3.new(P.x+math.cos(a)*4,P.y+5,P.z+P.spawnZ+math.sin(a)*3),Vector3.new(P.x,P.y+5,P.z))
end
return M
