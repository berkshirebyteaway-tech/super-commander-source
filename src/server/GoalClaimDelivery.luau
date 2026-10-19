local Core=game.ReplicatedStorage.FrontierNative.Core
local Rules=require(Core.GoalClaimRules)
local Profile=require(Core.ProfileModel)
local Fresh=require(script.Parent.FreshStore)
local M={}
function M.claim(accounts,id,key,now,mult)
    local operation=game:GetService('HttpService'):GenerateGUID(false);local got
    local profile,err=accounts:updateProgress(id,function(p)
        local out,info=Rules.apply(p.outgame,key,now,mult,operation);if not out then return nil,info end
        got=info;p.outgame=out;return p
    end,'Gameplay','goalClaim')
    if not profile and err=='storage-unavailable'then
        local repo=accounts.repo;local storedKey=tostring(id)
        if repo:acquire(storedKey)then
            local ok,decoded,proof=pcall(function()
                local p=Profile.decode(Fresh.read(repo.store,storedKey))
                return p,p and Rules.proof(p.outgame,operation)
            end)
            if ok and proof then repo.loaded[storedKey]=decoded;profile=decoded;got=proof;err=nil end
            repo.busy[storedKey]=nil
            if ok and proof then
                local player=game:GetService('Players'):GetPlayerByUserId(id);local a=player and accounts.accounts[player]
                if a then
                    a.profile=profile;accounts:publish(player,a)
                    pcall(accounts.analytics.flow,accounts.analytics,player,'goals','claimRecovered',{count=proof.count,value=proof.medals,result='granted'})
                end
            end
        end
    end
    return profile,profile and got or nil,err
end
return M
