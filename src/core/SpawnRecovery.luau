local T=if script then require(script.Parent.Terrain)else require('./Terrain')
local Format=if script then require(script.Parent.TeamFormat)else require('./TeamFormat')
local M={}
function M.land(s,id,wanted)
    local p=s.sim.players[id]
    if s.phase~='spawn'or not p or p.kind~='HUMAN'then return nil end
    local w,h=s.map.meta.width,s.map.meta.height
    if type(wanted)~='number'or wanted%1~=0 or wanted<0 or wanted>=w*h then return nil end
    local protected={}
    for _,q in ipairs(s.sim.players)do if q.kind=='HUMAN'and q.spawnTile then protected[q.spawnTile]=true end end
    local area=Format.area(s.map.meta,s.teamCount,p.team)
    local x,y=wanted%w,wanted//w
    local best,rank,distance
    for t=0,w*h-1 do
        local b=s.sim.terrain[t+1]
        if T.isLand(b)and not T.isImpassable(b)then
            local owner=s.sim:owner(t);local donor=s.sim.players[owner]
            local eligible=owner==0 or owner==id or not protected[t]and donor and (donor.kind~='HUMAN'or donor.tiles.size>1)
            if eligible then
                local tier=(owner==id and 0 or owner==0 and 2 or 4)+(area and not Format.inside(area,t,w)and 1 or 0)
                local d=(t%w-x)^2+(t//w-y)^2
                if rank==nil or tier<rank or tier==rank and d<distance then best,rank,distance=t,tier,d end
            end
        end
    end
    if best==nil then return nil end
    if s.sim:owner(best)~=id then s.sim:conquer(id,best)end
    p.spawnTile=best
    if s.spawned then s.spawned[id]=best else s.spawnTile=best end
    s:recordOwnership();s.sim.captured={}
    return best
end
return M
