local Campaign=if script then require(script.Parent.CampaignRules)else require('./CampaignRules')
local Lobby=if script then require(script.Parent.LobbyModel)else require('./LobbyModel')
local Solo=if script then require(script.Parent.SoloChallenge)else require('./SoloChallenge')
local M={}
M.difficulties={'Easy','Medium','Hard','Impossible'}
function M.pool(difficulty)
    if difficulty=='Easy'then
        local out={};for _,s in ipairs(Campaign.stages)do if s.chapter==1 and not table.find(out,s.map)then table.insert(out,s.map)end end
        return out
    end
    return Lobby.maps
end
M.rookieGames=5
function M.rookie(progress)
    local st=type(progress)=='table'and progress.stats or {};local n=0
    for _,k in ipairs({'single','pvp','coop'})do n+=tonumber((st[k]or {}).games)or 0 end
    return n<M.rookieGames
end
function M.valid(difficulty)return table.find(M.difficulties,difficulty)~=nil end
function M.pick(difficulty,rng)
    local pool=M.pool(difficulty);rng=rng or Random.new()
    return pool[rng:NextInteger(1,#pool)]
end
function M.settings(meta,difficulty)return Solo.goal(meta,difficulty)end
return M
