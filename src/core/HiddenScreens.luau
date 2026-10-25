local M={}
local function on(attr)
    local ok,v=pcall(function()return game.ReplicatedStorage.FrontierNative:GetAttribute(attr)end)
    return ok and v==true
end
function M.ranked()return on('LiveRankedScreen')end
function M.season()return on('LiveSeasonScreen')end
return M
