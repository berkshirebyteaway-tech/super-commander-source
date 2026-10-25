local M={}
function M.pick(state,info,f,owner)
    if not state or state.phase~='playing'or state.paused or not info or not info.land then return false end
    owner=owner or 0;if owner==1 or f and (f.allied or f.teammate)then return false end
    return state.attackTargets~=nil and state.attackTargets[tostring(owner)]==true
end
return M
