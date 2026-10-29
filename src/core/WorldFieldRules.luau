local M={}
M.seats=20
M.ttl=60;M.renew=10;M.cache=5
M.lockSeconds=30
M.lateSeconds=6*60
M.protocol=1
local function fresh(r,now)return type(r)=='table'and type(r.id)=='string'and r.protocol==M.protocol and (r.updated or 0)+M.ttl>=now end
local function free(r)return math.max(0,(r.seats or M.seats)-(r.humans or 0))end
local function open(r)return r.open~=false end
function M.pick(rows,now,want)
    local best
    for _,r in ipairs(rows or {})do
        if fresh(r,now)and type(r.code)=='string'and open(r)and free(r)>=(want or 1)then
            if not best or (r.humans or 0)>(best.humans or 0)or (r.humans or 0)==(best.humans or 0)and r.id<best.id then best=r end
        end
    end
    return best
end
function M.view(rows,now)
    local r=M.pick(rows,now,1)
    local total=0;for _,row in ipairs(rows or {})do if fresh(row,now)then total+=row.humans or 0 end end
    if not r then return {humans=0,seats=M.seats,online=total}end
    local left=r.ends and r.ends-now>=M.lateSeconds and r.ends-now or nil
    return {humans=r.humans or 0,seats=r.seats or M.seats,left=left,online=total}
end
function M.row(id,code,privateId,rooms,now,capacity)
    local humans,ends,joinable=0,nil,false
    for _,r in ipairs(rooms)do
        humans+=r.humans or 0
        if r.joinable then joinable=true;if not ends or (r.endsAt or 0)>ends then ends=r.endsAt end end
    end
    return {id=id,code=code,privateId=privateId,humans=humans,seats=M.seats,ends=joinable and ends or nil,
        open=joinable or capacity==true,updated=now,protocol=M.protocol}
end
function M.lock(old,job,now)
    if type(old)=='table'and old.by~=job and (old.expires or 0)>now then return nil end
    return {by=job,expires=now+M.lockSeconds}
end
function M.validId(id)return type(id)=='string'and #id>=8 and #id<=64 and id:match('^[%x%-]+$')~=nil end
function M.group(list,self)
    local out={self}
    if type(list)=='table'then for i,v in ipairs(list)do if i>16 or #out>=8 then break end;if type(v)=='number'and v%1==0 and v>0 and v~=self and not table.find(out,v)then table.insert(out,v)end end end
    return out
end
return M
