local M={}
function M.soloTakesLast(rooms,preparing,maxRooms)
    local n=preparing or 0
    for _,r in ipairs(rooms)do
        if r.casual and not r.endedAt then return false end
        if not(r.intro or r.practice)then n+=1 end
    end
    return n>=maxRooms-1
end
return M
