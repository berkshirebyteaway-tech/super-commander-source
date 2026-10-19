local M={enabled=true}
M.freeEmojis={'🕊️','🏳️','❤️','🥰','👏','😤','🤡'}
M.freePhrases={['coordinate.ack']=true,['coordinate.decline']=true}
M.matchText=true
function M.freeEmoji(e)return table.find(M.freeEmojis,e)~=nil end
function M.active()
    if not M.enabled then return false end
    local ok,v=pcall(function()return game.ReplicatedStorage.FrontierNative:GetAttribute('VipCommsOpen')end)
    return not ok or v~=true
end
function M.allows(kind,value,vip)
    if vip==true or not M.active()then return true end
    if kind=='signal'or kind=='target'then return true end
    if kind=='emoji'then return M.freeEmoji(value)end
    if kind=='quickChat'then local key=type(value)=='table'and value.key or value;return M.freePhrases[key]==true end
    return false
end
function M.emojiOrder(list)
    local out={};for _,e in ipairs(list)do if M.freeEmoji(e)then table.insert(out,e)end end
    for _,e in ipairs(list)do if not M.freeEmoji(e)then table.insert(out,e)end end
    return out
end
function M.isVip(player)
    local ok,v=pcall(function()return player:GetAttribute('CommanderVIP')end);return ok and v==true
end
function M.listeners(e,entries,vip,teamOnly,Routing)
    local out={};if not vip and M.active()then return out end
    local scope
    if not e.room then scope='lobby'
    elseif not Routing.active(e)then scope='spectators'
    elseif not teamOnly then scope='all'
    else local p=e.room.session.sim.players[e.faction];scope=p and p.team~=nil and 'team'or 'allies'end
    for _,o in pairs(entries)do
        if o~=e and o.player and Routing.allowed(e,o,scope,e.faction)then table.insert(out,o.player.UserId)end
    end
    table.sort(out);return out
end
return M
