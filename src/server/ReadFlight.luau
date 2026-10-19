local M={}
function M.run(flights,key,wait,read)
    wait=wait or (if script then task.wait else coroutine.yield)
    local active=flights[key]
    if active then
        if (active.waiters or 0)>=128 then return false,'busy'end
        active.waiters=(active.waiters or 0)+1
        repeat wait(.05)until active.done
        active.waiters-=1
        return table.unpack(active.result,1,active.result.n)
    end
    local flight={};flights[key]=flight
    local result=table.pack(pcall(read))
    flight.result=result;flight.done=true
    if flights[key]==flight then flights[key]=nil end
    return table.unpack(result,1,result.n)
end
return M
