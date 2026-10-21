local Records=if script then require(script.Parent.MatchRecords)else require('./MatchRecords')
local M={}
M.recent=5
local function n(v)return type(v)=='number'and v==v and math.abs(v)~=math.huge and v or nil end
function M.row(r)
    if type(r)~='table'then return nil end
    return {mode=type(r.mode)=='string'and r.mode or nil,outcome=type(r.outcome)=='string'and r.outcome or nil,place=n(r.place),field=n(r.field),
        top10=r.top10==true or nil,ranked=r.ranked==true or nil,conquered=n(r.conquered)or 0,troops=n(r.troops)or 0,seconds=n(r.seconds)or 0}
end
function M.build(userId,view,ladders)
    local out={userId=userId,level=n(view and view.level)or 1,title=view and type(view.title)=='string'and view.title or nil,
        records=view and view.records or Records.view({}),history={},ranked={}}
    local list=view and type(view.history)=='table'and view.history or {}
    local all,ranked,public=0,0,0
    for _,r in ipairs(list)do
        local row=M.row(r)
        if row then
            local isPublic=not row.ranked and (row.mode=='pvp'or row.mode=='coop')
            if all<M.recent or row.ranked and ranked<M.recent or isPublic and public<M.recent then
                table.insert(out.history,row)
            end
            all+=1;if row.ranked then ranked+=1 end;if isPublic then public+=1 end
        end
    end
    for ladder,v in pairs(type(ladders)=='table'and ladders or {})do
        if type(v)=='table'then
            out.ranked[ladder]={tier=v.tier,tierName=v.tierName,division=v.division,rp=n(v.rp)or 0,games=n(v.games)or 0,wins=n(v.wins)or 0,placing=v.placing==true or nil}
        end
    end
    return out
end
return M
