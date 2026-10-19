local M={};M.__index=M
function M.new() return setmetatable({owners={},batches={}},M) end
function M:reset(owners)
    table.clear(self.owners);for t,id in pairs(owners) do self.owners[t]=id end
    self.batches={}
end
function M:push(changes,now)
    if #changes==0 then return end
    table.insert(self.batches,{changes=changes,start=now,index=1})
end
function M:step(now,changed)
    local remaining=4096
    while self.batches[1] and remaining>0 do
        local batch=self.batches[1]
        local count=#batch.changes
        local target=math.min(count,math.ceil(count*math.clamp((now-batch.start)/.1,0,1)))
        while batch.index<=target and remaining>0 do
            local c=batch.changes[batch.index];self.owners[c[1]]=c[2]~=0 and c[2] or nil
            changed(c[1]);batch.index+=1;remaining-=1
        end
        if batch.index>count then table.remove(self.batches,1) else break end
    end
end
return M
