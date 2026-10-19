local M={};M.__index=M
M.version=1;M.maxEntries=60000;M.keep=10;M.speeds={1,2,4}
local function clean(v,depth)
    local t=type(v)
    if t=="number"then return (v==v and math.abs(v)<math.huge)and v or nil end
    if t=="string"then return #v<=1000 and v or nil end
    if t=="boolean"then return v end
    if t=="table"and depth<2 then
        local out={};local n=0
        for k,x in pairs(v)do n+=1;if n>200 then break end
            if type(k)=="string"or type(k)=="number"and k%1==0 and k>=1 then out[k]=clean(x,depth+1)end
        end
        return out
    end
    return nil
end
function M.new(header)return setmetatable({header=header,log={},count=0},M)end
function M:add(t,f,a,v,x)
    if self.count>=M.maxEntries then self.overflow=true;return end
    self.count+=1;self.log[self.count]={t=t,f=f,a=a,v=clean(v,0),x=clean(x,0)}
end
function M:finish(endTick,winner)
    return {v=M.version,header=self.header,log=self.log,endTick=endTick,winner=winner,truncated=self.overflow==true}
end
function M.playable(data,place)
    return type(data)=="table"and data.v==M.version and data.truncated~=true and type(data.header)=="table"and type(data.log)=="table"and data.header.place==place
end
function M.cursor(data)return {data=data,i=1}end
function M.feed(cursor,s,apply)
    local log=cursor.data.log
    while cursor.i<=#log do
        local e=log[cursor.i]
        if (e.t or 0)>s.sim.ticks then break end
        cursor.i+=1;pcall(apply,s,e)
    end
end
function M.row(id,header,seconds,outcome,mode)
    return {id=id,map=header.map,mode=mode,at=header.started,minutes=math.floor((seconds or 0)/60),outcome=outcome,place=header.place}
end
function M.remember(list,row)
    local out={row};for _,r in ipairs(type(list)=="table"and list or {})do if #out>=M.keep then break end;if type(r)=="table"and r.id~=row.id then table.insert(out,r)end end
    return out
end
function M.prune(list,row)
    local out,stale={},{}
    for _,r in ipairs(M.remember(list,row))do
        if type(row.place)=="number"and type(r)=="table"and r~=row and not(type(r.place)=="number"and r.place>=row.place)then
            if type(r.id)=="string"then table.insert(stale,r.id)end
        else table.insert(out,r)end
    end
    return out,stale
end
return M
