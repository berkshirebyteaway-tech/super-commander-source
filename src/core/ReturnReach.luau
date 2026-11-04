local M={}
local CHAPTER1={'1-1','1-2','1-3','1-4','1-5'}
M.chapter1=CHAPTER1
local function won(stars,id)return (math.floor(tonumber(stars[id])or 0))%2==1 end
function M.reach(stars,pvp)
    stars=type(stars)=='table'and stars or {}
    local base='none'
    for i,id in ipairs(CHAPTER1)do if won(stars,id)then base='op'..i end end
    if base=='op5'then for id,m in pairs(stars)do if type(id)=='string'and not id:match('^1%-')and (math.floor(tonumber(m)or 0))%2==1 then base='ch2p';break end end end
    return (tonumber(pvp)or 0)>0 and base..'_mp'or base
end
function M.raise(reach,stageId)
    if type(stageId)~='string'then return reach end
    local mp=type(reach)=='string'and reach:match('_mp$')~=nil
    local base=type(reach)=='string'and reach:gsub('_mp$','')or 'none'
    local rank={none=0,op1=1,op2=2,op3=3,op4=4,op5=5,ch2p=6}
    local new=base
    for i,id in ipairs(CHAPTER1)do if id==stageId then new='op'..i end end
    if not stageId:match('^1%-')and stageId:match('^%d')then new=(rank[base]or 0)>=5 and 'ch2p'or base end
    if (rank[new]or 0)<(rank[base]or 0)then new=base end
    return mp and new..'_mp'or new
end
function M.withMultiplayer(reach)reach=type(reach)=='string'and reach or 'none';return reach:match('_mp$')and reach or reach..'_mp'end
function M.day(firstAt,now)
    if type(firstAt)~='number'then return 'd0'end
    local d=math.floor(math.max(0,(now or os.time())-firstAt)/86400)
    return d==0 and 'd0'or d==1 and 'd1'or d<7 and 'd2_6'or 'd7p'
end
return M
