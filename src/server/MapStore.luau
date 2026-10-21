local M={};M.__index=M
M.name='SuperCommanderMaps_v1'
M.waitSeconds=12
M.retrySeconds=60
M.keep=3
function M.new(loader,store,ports)
    ports=ports or {}
    return setmetatable({loader=loader,store=store,cache={},order={},pending={},failed={},
        clock=ports.clock or os.clock,wait=ports.wait or task.wait,spawn=ports.spawn or task.spawn,warn=ports.warn or warn},M)
end
function M:fetch(key)
    local meta=self.loader.sized(key,'normal')
    local ok,value=pcall(function()return self.store:GetAsync(meta.store.key)end)
    local parts=ok and type(value)=='table'and value.v==1 and value.parts or nil
    local checked,terrain=false,nil
    if type(parts)=='table'then checked,terrain=pcall(self.loader.expandChecked,meta,parts)end
    self.pending[key]=nil
    if checked then
        self.cache[key]={parts=parts,terrain=terrain};table.insert(self.order,key)
        while #self.order>M.keep do self.cache[table.remove(self.order,1)]=nil end
    else
        self.failed[key]=self.clock();self.warn('Map store: '..key..' unavailable ('..tostring(ok and (parts and terrain or 'no entry')or value)..')')
    end
end
function M:prefetch(key)
    if not self.loader.stored(key)or self.cache[key]or self.pending[key]then return end
    if self.failed[key]and self.clock()-self.failed[key]<M.retrySeconds then return end
    self.pending[key]=true
    self.spawn(function()local ok,err=pcall(self.fetch,self,key);if not ok then self.pending[key]=nil;self.failed[key]=self.clock();self.warn(err)end end)
end
function M:ensure(key)
    if not self.loader.stored(key)then return true end
    if self.cache[key]then return true end
    self:prefetch(key)
    local started=self.clock()
    while self.pending[key]and self.clock()-started<M.waitSeconds do self.wait(.1)end
    return self.cache[key]~=nil
end
function M:source(meta)
    local c=self.cache[meta.key];if c then return c.parts,c.terrain end
    return nil
end
function M:attach()
    self.loader.storeSource=function(meta)return self:source(meta)end
    return self
end
return M
