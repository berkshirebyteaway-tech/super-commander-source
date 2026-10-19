local Policy=if script then require(script.Parent.CountryPolicy)else require('./CountryPolicy')
local M={}
function M.opponents(meta,difficulty)
    local n=({Easy=3,Medium=5,Hard=7,Impossible=9})[difficulty]or 5
    local land=meta.landTiles or 150000
    return math.clamp(n+(land<60000 and -1 or land>400000 and 1 or 0),2,10)
end
function M.goal(meta,difficulty)
    difficulty=({Easy=true,Medium=true,Hard=true,Impossible=true})[difficulty]and difficulty or 'Medium'
    return {difficulty=difficulty,nations=M.opponents(meta,difficulty),bots=math.clamp(math.floor((meta.landTiles or 150000)/2500),24,120),
        startingGold=0,goldMultiplier=1,customAllianceDuration=5,maxTimerValue=15,
        infiniteGold=false,infiniteTroops=false,instantBuild=false}
end
function M.resolve(meta,settings)
    local s=table.clone(settings)
    if s.nations=='default'and #Policy.filter(meta.key,meta.nations or {})==0 then s.nations=M.opponents(meta,s.difficulty)end
    return s
end
function M.empty(meta,settings)
    local s=M.resolve(meta,settings)
    local n=type(s.nations)=='number'and s.nations or s.nations=='default'and #(meta.nations or {})or 0
    return n==0 and (s.bots or 0)==0
end
return M
