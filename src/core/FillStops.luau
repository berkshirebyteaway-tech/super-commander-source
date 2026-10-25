local M={}
function M.build(parts,track,trackAlpha)
    local runs={};local last=0
    for _,part in ipairs(parts)do
        local p=math.clamp(tonumber(part.p)or 0,0,1)
        if p>last+.0005 then table.insert(runs,{last,p,part.color,part.color2 or part.color,part.alpha or 0});last=p end
    end
    if last<.9995 then table.insert(runs,{last,1,track,track,trackAlpha or 0})
    elseif #runs>0 then runs[#runs][2]=1 end
    local times,colors,alphas={},{},{}
    local function push(t,c,a)
        if #times>0 and t<=times[#times]then t=times[#times]+.0002 end
        if t>1 then t=1 end
        if #times>0 and t<=times[#times]then return end
        table.insert(times,t);table.insert(colors,c);table.insert(alphas,a)
    end
    for i,r in ipairs(runs)do
        if #times>=18 then break end
        local a,b=r[1],r[2]
        push(i==1 and 0 or a,r[3],r[5])
        push(i==#runs and 1 or math.max(a+.0002,b-.001),r[4],r[5])
    end
    if times[#times]<1 then times[#times]=1 end
    return times,colors,alphas
end
return M
