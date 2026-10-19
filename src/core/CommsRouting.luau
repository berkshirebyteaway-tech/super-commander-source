local M={}
function M.active(e)
    local room=e and e.room;local s=room and room.session;local p=s and s.sim.players[e.faction]
    return s~=nil and p~=nil and (s.phase=='spawn'or s.phase=='playing'and p.tiles.size>0)and not s.resources[e.faction].forfeited
end
function M.allowed(from,to,scope,target)
    if not from or not to then return false end
    if scope=='lobby'then return from.room==nil and to.room==nil end
    if not from.room or from.room~=to.room then return false end
    if scope=='spectators'then return not M.active(from)and not M.active(to)end
    if not M.active(from)or not M.active(to)then return false end
    if scope=='all'then return true end
    local s=from.room.session;local a,b=s.sim.players[from.faction],s.sim.players[to.faction]
    if scope=='team'then return a.team~=nil and a.team==b.team end
    if scope=='allies'then return from.faction==to.faction or s:friendly(from.faction,to.faction)end
    if scope=='player'then return from==to or to.faction==target end
    return false
end
return M
