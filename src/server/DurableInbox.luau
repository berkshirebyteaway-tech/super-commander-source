local M={};M.__index=M
local function clone(t)local out={};for k,v in pairs(t or {})do out[k]=v end;return out end
local function revision(e)return type(e)=='table'and type(e.id)=='string'and #e.id>0 and #e.id<=128 and type(e.revision)=='number'and e.revision==e.revision and e.revision%1==0 and e.revision>0 and e.revision<2^53 end
local function items(raw)
    if raw==nil then return {} end
    assert(type(raw)=='table'and (raw.schema==nil or raw.schema==1)and type(raw.items)=='table','unsupported-inbox')
    for key,r in pairs(raw.items)do assert(type(r)=='table'and revision(r.event)and key==r.event.id,'invalid-inbox')end
    return clone(raw.items)
end
function M.new(store,apply,validate,now)
    return setmetatable({store=store,apply=apply,validate=validate,now=now or os.time,pending={},busy={},reading={},recovery={},errors={},metrics={persisted=0,applied=0,recovered=0,failures=0}},M)
end
function M:record(id,event)
    if not revision(event)or self.validate and not self.validate(event)then return false,'invalid-event'end
    local list=self.pending[id]or {};self.pending[id]=list
    local old=list[event.id];if not old or event.revision>old.revision then list[event.id]=event end
    return true
end
function M:recover(id)
    if self.reading[id]then return false end;self.reading[id]=true;self.recovery[id]=true
    local ok,err=pcall(function()
        local records=items(self.store:GetAsync(tostring(id)))
        for _,r in pairs(records)do if not r.paid then assert(not self.validate or self.validate(r.event),'invalid-event')end end
        for _,r in pairs(records)do if not r.paid then self:record(id,r.event);self.metrics.recovered+=1 end end
    end)
    self.reading[id]=nil
    if ok then self.recovery[id]=nil;self.errors[id]=nil else self.errors[id]=tostring(err);self.metrics.failures+=1 end
    return ok
end
function M:drain(id)
    if self.busy[id]or not self.pending[id]then return false end;self.busy[id]=true
    local ok,err=pcall(function()
        while self.pending[id]and next(self.pending[id])do
            local eventId,event=next(self.pending[id]);local now=self.now();local unpaid
            local saved=self.store:UpdateAsync(tostring(id),function(raw)
                local out=items(raw);local prior=out[eventId];unpaid={}
                if not prior or event.revision>prior.event.revision then out[eventId]={event=event,paid=false}end
                local paid={}
                for key,r in pairs(out)do if not r.paid then unpaid[key]=true end;if r.paid then
                    if (r.paidAt or 0)<now-30*86400 then out[key]=nil else table.insert(paid,{key=key,time=r.paidAt or 0})end
                end end
                table.sort(paid,function(a,b)return a.time<b.time or a.time==b.time and a.key<b.key end)
                for i=1,math.max(0,#paid-256)do out[paid[i].key]=nil end
                return {schema=1,items=out}
            end)
            assert(saved and saved.items,'intent-unconfirmed');self.metrics.persisted+=1
            local stored=saved.items[eventId]
            if stored and not stored.paid then
                assert(not self.validate or self.validate(stored.event),'invalid-event')
                local applied,reason=self.apply(id,stored.event,unpaid);assert(applied,reason or 'apply-pending');self.metrics.applied+=1
                local ack=self.store:UpdateAsync(tostring(id),function(raw)
                    if raw==nil then return nil end
                    local out=items(raw);local current=out[eventId]
                    if current and current.event.revision==stored.event.revision then out[eventId]={event={id=eventId,revision=stored.event.revision},paid=true,paidAt=self.now()}end
                    return {schema=1,items=out}
                end)
                assert(ack,'ack-unconfirmed')
            end
            if self.pending[id][eventId]==event then self.pending[id][eventId]=nil end
        end
    end)
    if self.pending[id]and not next(self.pending[id])then self.pending[id]=nil end
    self.busy[id]=nil
    if ok then self.errors[id]=nil else self.errors[id]=tostring(err);self.metrics.failures+=1 end
    return ok,err
end
function M:stopRecovering(id)self.recovery[id]=nil;if not self.pending[id]then self.errors[id]=nil end end
function M:status(id)return {pending=self.pending[id]~=nil,recovering=self.recovery[id]==true,busy=self.busy[id]==true}end
return M
