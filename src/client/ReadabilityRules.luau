local M={}
function M.overlap(a,b)
    return math.max(0,math.min(a.x+a.w,b.x+b.w)-math.max(a.x,b.x))*math.max(0,math.min(a.y+a.h,b.y+b.h)-math.max(a.y,b.y))
end
function M.occludes(avatar,target)
    if not avatar or not target or avatar.depth>=target.depth-.02 then return false end
    local area=math.max(1,target.w*target.h)
    return M.overlap(avatar,target)/area>=.18
end
function M.fade(value,target,dt)
    local v=value+(target-value)*(1-math.exp(-math.max(0,dt)*14))
    return math.abs(v-target)<.002 and target or v
end
return M
