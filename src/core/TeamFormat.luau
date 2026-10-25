-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors, pinned e02eeba. Team formats from TeamAssignment.resolveTeamsList /
local R=if script then require(script.Parent.PseudoRandom) else require("./PseudoRandom")
local AI=if script then require(script.Parent.TribeAI) else require("./TribeAI")
local M={}
M.size={Duos=2,Trios=3,Quads=4}
M.humansVsNations="HumansVsNations"
M.weights={{2,10},{3,10},{4,10},{5,10},{6,10},{7,10},{"Duos",5},{"Trios",7.5},{"Quads",7.5},{"HumansVsNations",20}}
M.forceChance=.75
M.labels={Duos="듀오",Trios="트리오",Quads="쿼드",HumansVsNations="사람 대 국가"}
function M.valid(format)
    if type(format)=="number" then return format%1==0 and format>=2 and format<=10 end
    return M.size[format]~=nil or format==M.humansVsNations
end
function M.fixedSize(format)return M.size[format]end
function M.adjust(seats,format)
    if format==nil then return seats end
    if format==M.humansVsNations then return seats//2 end
    local size=M.size[format] or format
    return seats-seats%size
end
function M.perTeam(players,format)
    if format==M.humansVsNations then return players end
    local size=M.size[format];if size then return math.min(size,players)end
    return players//format
end
function M.teams(players,format)
    if format==M.humansVsNations then return 2 end
    local size=M.size[format];if size then return players//size end
    return format
end
function M.supports(players,format)return M.perTeam(players,format)>=2 and M.teams(players,format)>=2 end
function M.resolve(format,seats)
    if type(format)=="number" and not M.supports(M.adjust(seats,format),format)then format=math.max(2,seats//2)end
    if type(format)~="number" and not M.supports(M.adjust(seats,format),format)then
        format=2;if not M.supports(M.adjust(seats,2),2)then format=math.max(2,seats//2)end
    end
    local maximum=math.max(2,M.adjust(seats,format))
    return format,M.teams(maximum,format),maximum
end
function M.count(format,totalPlayers)
    if format==M.humansVsNations then return 2 end
    local size=M.size[format]
    if size then return math.max(2,math.ceil(totalPlayers/size))end
    return format
end
function M.roll(rollForce,rollWeight,special)
    if special and special>=2 and rollForce<M.forceChance then return special end
    local total=0;for _,w in ipairs(M.weights)do total+=w[2]end
    local x=rollWeight*total
    for _,w in ipairs(M.weights)do if x<w[2]then return w[1]end;x-=w[2]end
    return M.weights[1][1]
end
function M.label(format,teams,maximum)
    if format==M.humansVsNations then return string.format("사람 대 국가, 최대 %d명",maximum)end
    local name=M.labels[format]
    if name then return teams and string.format(name.." %d팀",teams)or name end
    return string.format("%d팀, 최대 %d명",teams or format,maximum)
end
function M.short(format,teams)
    if format==M.humansVsNations then return "사람 대 국가" end
    if M.labels[format]then return M.labels[format]end
    return string.format("%d팀",teams or format)
end
function M.area(meta,teamCount,team)
    local areas=meta and meta.spawnAreas and teamCount and meta.spawnAreas[tostring(teamCount)]
    return areas and type(team)=="number" and areas[team] or nil
end
function M.inside(area,tile,width)
    local x,y=tile%width,tile//width
    return x>=area.x and x<area.x+area.w and y>=area.y and y<area.y+area.h
end
function M.placeNations(ids,counts,teamCount,maxTeamSize,pack,seedKey)
    local order=table.clone(ids)
    if #order>0 then order=R.new(AI.hash(seedKey)):shuffleArray(order)end
    local result={}
    for _,id in ipairs(order)do
        local best
        for team=1,teamCount do
            local size=counts[team]or 0
            if size<maxTeamSize and (not best or (if pack then size>(counts[best]or 0)else size<(counts[best]or 0)))then best=team end
        end
        if best then counts[best]=(counts[best]or 0)+1;result[id]=best end
    end
    return result
end
function M.plan(settings,humans,count,mode)
    if mode=="coop" then return {nations=table.create(count,2)} end
    local f=settings.teamFormat
    if mode~="teams" and not (humans==nil and f~=nil) then return nil end
    if f==M.humansVsNations or settings.humansVsNations then return {teamCount=2,human=1,nations=table.create(count,2)} end
    local counts,seated={},0
    if humans then for _,h in ipairs(humans)do seated+=1;if type(h.team)=="number" then counts[h.team]=(counts[h.team]or 0)+1 end end
    else seated=1;counts[1]=1 end
    local teamCount=math.max(settings.teamCount or (f~=nil and M.count(f,seated+count)) or 2,settings.minimumTeamCount or 0)
    if type(settings.nationTeams)=="table" then
        local list={}
        for i=1,count do local t=settings.nationTeams[i];if type(t)=="number" and t%1==0 and t>=1 and t<=teamCount then list[i]=t end end
        return {teamCount=teamCount,human=1,nations=list}
    end
    if f==nil then return {teamCount=teamCount,human=1,nations={}} end
    local size=M.size[f];local ids={};for i=1,count do ids[i]=i end
    return {teamCount=teamCount,human=1,nations=M.placeNations(ids,counts,teamCount,size or math.ceil((seated+count)/teamCount),size~=nil,tostring(settings.seed or "frontier").."-teams")}
end
return M
