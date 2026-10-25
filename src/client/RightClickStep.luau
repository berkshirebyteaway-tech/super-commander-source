local Step=require(script.Parent.TelemetryStep)
local M={}
function M.note(s,secondary)
    if type(s)~='table'then return end
    local stage=type(s.campaign)=='string'and(('s'..s.campaign):gsub('%-','_'))or 'match'
    local kind=secondary and 'right'or 'left'
    Step.once('menuOpened:'..kind..':'..tostring(s.version),'match','menuOpened',{result=kind,item=stage,value=tonumber(s.tick)or 0})
end
return M
