local Model=if script then require(game.ReplicatedStorage.FrontierNative.Core.SpawnDrop)else require('../core/SpawnDrop')
local Squad=if script then require(game.ReplicatedStorage.FrontierNative.Core.DropSquad)else require('../core/DropSquad')
local Recovery=if script then require(game.ReplicatedStorage.FrontierNative.Core.SpawnRecovery)else require('../core/SpawnRecovery')
local M={}
local rates={ready=.5,move=.045,land=.15,rally=2}
local function commit(room,id,tile)
    local s=room.session;local p=room.drop.players[id]
    if p.committed then return true end
    local ok
    if room.single then ok=s:spawn(tile);if ok then s.phase='spawn'end
    else ok=s:spawnHuman(id,tile)end
    if not ok then p.landed=false;p.tile=nil;p.reserved=nil;return false end
    p.committed=true
    if room.replayLog then room.replayLog:add(s.sim.ticks,id,'spawn',tile)end
    return true
end
function M.begin(room,roster,now,random,parties)
    room.drop=Model.new(room.session,Squad.assign(roster,parties),now,random);room.spawnUntil=now+Model.readySeconds+Model.seconds
    room.randomSpawn=random==true;room.note='낙하해서 시작 위치를 정하세요.'
    if random then
        for id,p in ipairs(room.drop.players)do local tile=room.drop:randomTile(id)
            if tile then p.reserved=tile;if commit(room,id,tile)then p.x=tile%room.session.map.meta.width;p.y=tile//room.session.map.meta.width end end
        end
    end
end
function M.land(room,id,now)
    local ok,tile=room.drop:land(id,now)
    if ok then ok=commit(room,id,tile)end
    return ok,tile
end
function M.step(room,now,onLand)
    local d=room.drop;if not d or d.finished then return end
    if room.paused then local dt=math.max(0,now-d.lastStep);d.created+=dt;if d.startAt then d.startAt+=dt end;d.lastStep=now;room.spawnUntil=(d.startAt or d.created+Model.readySeconds)+Model.seconds;return end
    for _,p in ipairs(d:step(now,function(id,tile)return commit(room,id,tile)end,function(id,wanted)
        local tile=Recovery.land(room.session,id,wanted)
        if tile then
            d.players[id].committed=true
            if room.replayLog then room.replayLog:add(room.session.sim.ticks,id,'spawnRecovery',wanted)end
        end
        return tile
    end))do if onLand then onLand(p.id,p.tile)end end
    if d.startAt then room.spawnUntil=d.startAt+Model.seconds end
    if d.finished and room.single then room.session.phase='playing' end
    if M.broadcast and now>=(d.nextBroadcast or 0)then d.nextBroadcast=now+.1;M.broadcast(room,now)end
end
function M.bind(pack,entries,onLand)
    local remote=Instance.new('RemoteEvent');remote.Name='DropInput';remote.Parent=pack
    local stream=Instance.new('RemoteEvent');stream.Name='DropState';stream.Parent=pack
    M.broadcast=function(room,now)
        local frame=room.drop:frame(now)
        for _,e in pairs(entries)do if e.room==room and e.player and e.player.Parent and room.drop.players[e.faction]and room.drop.players[e.faction].userId==e.player.UserId then
            stream:FireClient(e.player,e.version,room.drop:snapshot(e.faction,now,frame))
        end end
    end
    remote.OnServerEvent:Connect(function(player,packet)
        local e=entries[player.UserId];local room=e and e.room;local now=os.clock()
        if type(packet)~='table'or not room or room.paused or not room.drop or room.drop.finished or room.session.phase~='spawn'or packet.version~=e.version then return end
        local seat=room.drop.players[e.faction];if not seat or seat.userId~=player.UserId then return end
        local gap=rates[packet.kind];if not gap then return end
        e.dropRate=e.dropRate or {};if now-(e.dropRate[packet.kind]or -1e9)<gap then return end;e.dropRate[packet.kind]=now
        local accepted
        if packet.kind=='ready'then accepted=room.drop:markReady(e.faction,now)
        elseif packet.kind=='move'then accepted=room.drop:input(e.faction,packet.x,packet.y,packet.seq,now)
        elseif packet.kind=='land'then accepted=room.drop:setDiving(e.faction,packet.diving,now)
        elseif packet.kind=='rally'then accepted=room.drop:rally(e.faction,packet.tile,now)end
        if M.telemetry then M.telemetry:dropInput(player,packet,accepted==true)end
    end)
end
return M
