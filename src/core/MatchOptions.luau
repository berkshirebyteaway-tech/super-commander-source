-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors, pinned e02eeba. Lobby choices shared by single and custom setup:
local M={}
M.difficulties={{'Easy','쉬움'},{'Medium','보통'},{'Hard','어려움'},{'Impossible','불가능'}}
M.difficultyLabels={Easy='쉬움',Medium='보통',Hard='어려움',Impossible='불가능'}
M.difficultyKeys={'Easy','Medium','Hard','Impossible'}
M.maxNations=400
M.nationSteps={'default','disabled',10,25,50,100,200,400}
function M.validNations(v)
    return v=='default'or v=='disabled'or (type(v)=='number'and v%1==0 and v>=1 and v<=M.maxNations)
end
function M.nextNations(v)
    local i=table.find(M.nationSteps,v)
    if not i and type(v)=='number'then for k,step in ipairs(M.nationSteps)do if type(step)=='number'and step>v then return step end end;return M.nationSteps[1]end
    return M.nationSteps[(i or 0)%#M.nationSteps+1]
end
function M.nationsLabel(v)
    if v=='disabled'then return '없음'end
    if type(v)=='number'then return string.format('%d개국',v)end
    return '지도 기본'
end
return M
