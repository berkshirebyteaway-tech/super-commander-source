local FactionColors=require(script.Parent.FactionColors)
local L=require(script.Parent.Localization)
local M={}
local function hvn(state)
    local s=state and state.settings
    return s~=nil and (s.humansVsNations==true or s.teamFormat=='HumansVsNations')
end
function M.label(team,state)
    if team==nil then return nil end
    local ko=tostring(L.getLocale()):sub(1,2)=='ko'
    if hvn(state)then if team==1 then return ko and '사람 팀'or 'Humans'elseif team==2 then return ko and '국가 팀'or 'Nations'end end
    return string.format(ko and '%d팀'or 'Team %d',team)
end
function M.myTeam(state)return state and state.player and state.player.team end
function M.active(state)
    if not state then return false end
    if M.myTeam(state)~=nil then return true end
    local first;for _,f in ipairs(state.factions or {})do if f.team~=nil and f.kind~='BOT'then
        if first==nil then first=f.team elseif f.team~=first then return true end
    end end
    return false
end
function M.of(f,state)
    if not f or f.team==nil or f.kind=='BOT'or not M.active(state)then return nil end
    return M.label(f.team,state)
end
function M.build(state,factions)
    local myTeam=M.myTeam(state);local byTeam,list={},{}
    for _,f in ipairs(factions or (state and state.factions)or {})do
        if f.team~=nil and f.kind~='BOT'then
            local t=byTeam[f.team]
            if not t then
                t={team=f.team,name=M.label(f.team,state),color=FactionColors.team(f.team,myTeam),mine=f.team==myTeam,alive=0,members=0,share=0,troops=0,gold=0}
                byTeam[f.team]=t;table.insert(list,t)
            end
            t.members+=1
            if not f.eliminated and (f.tiles or 0)>0 then t.alive+=1;t.share+=f.share or 0;t.troops+=f.troops or 0;t.gold+=f.gold or 0 end
        end
    end
    table.sort(list,function(a,b)if a.share~=b.share then return a.share>b.share end;return a.team<b.team end)
    return list
end
return M
