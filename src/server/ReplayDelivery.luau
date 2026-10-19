local Index=if script then require(script.Parent.ReplayIndex)else require('./ReplayIndex')
local M={};M.__index=M
local function idValid(id)return type(id)=='string'and #id>0 and #id<=44 and not id:find('[^%w%-%._:]')end
function M.new(owner)return setmetatable({owner=owner,a=owner.a,jobs={},busy={},scanAt=-math.huge},M)end
function M:count()local n=0;for _ in pairs(self.jobs)do n+=1 end;self.owner.pending=n end
function M:save(id,data,rows)
    if not idValid(id)then return false end
    if self.jobs[id]then return true end
    local list={};for uid,row in pairs(rows)do table.insert(list,{userId=uid,row=row})end
    self.jobs[id]={document={schema=1,id=id,data=data,rows=list,recordedAt=self.a.now and self.a.now()or nil},indexed={}};self:count()
    self.a.spawn(function()self:drain(id)end);return true
end
function M:attempt(fn,recovery)
    for i=1,3 do
        if recovery then
            if self.a.clock()>=(self.scanUntil or 0)or (self.scanOps or 0)>=48 then return false end
            if self.a.recoveryReady and not self.a.recoveryReady()then return false end
            self.scanOps=(self.scanOps or 0)+1
        end
        local ok,value=pcall(fn);if ok then return true,value end
        if i<3 then (self.a.wait or function()end)(i*2)end
    end
    return false
end
function M:drain(id)
    local job=self.jobs[id];if not job or self.busy[id]then return end;self.busy[id]=true
    local ok,err=pcall(function()
        local doc=job.document
        if doc and not job.persisted then
            local bodyOk,bodySize=pcall(self.a.size,doc.data)
            local sized,overhead=pcall(self.a.size,{schema=doc.schema,id=id,data={},rows=doc.rows,recordedAt=doc.recordedAt})
            if not sized or not bodyOk or bodySize>self.owner.limit or bodySize+overhead-2>4000000 then self.jobs[id]=nil;return end
            assert(self:attempt(function()self.a.set('pend:'..id,doc)end),'replay-intent-pending');job.persisted=true
        end
        if not doc then
            local read,value=self:attempt(function()return self.a.get('pend:'..id)end,job.recovery);assert(read,'replay-intent-read')
            if value==nil then self.jobs[id]=nil;return end;doc=value
        end
        assert(type(doc)=='table'and doc.schema==1 and doc.id==id and type(doc.rows)=='table'and type(doc.data)=='table','invalid-replay-intent')
        if not job.bodySaved then
            assert(self:attempt(function()self.a.set('match:'..id,doc.data)end,job.recovery),'replay-body-pending');job.bodySaved=true
            if self.owner.missing then self.owner.missing[id]=nil end
        end
        for _,entry in ipairs(doc.rows)do
            local uid=entry.userId
            if not job.indexed[uid]then
                local stale,confirmed
                local version=self.owner.listVersions[uid]or 0
                local indexed=self:attempt(function()
                    self.a.update('user:'..uid,function(old)confirmed,stale=Index.merge(old,entry.row,doc.recordedAt);return confirmed end)
                end,job.recovery)
                assert(indexed,'replay-index-pending');job.indexed[uid]=true
                self.owner:indexed(uid,confirmed,version)
                if self.a.remove then for _,old in ipairs(stale or {})do
                    if job.recovery then self:attempt(function()self.a.remove('match:'..old)end,true)
                    else pcall(self.a.remove,'match:'..old)end
                end end
            end
        end
        assert(self:attempt(function()
            if self.a.remove then self.a.remove('pend:'..id)else self.a.set('pend:'..id,nil)end
        end,job.recovery),'replay-ack-pending')
        self.jobs[id]=nil
    end)
    if self.jobs[id]and job.persisted then job.document=nil end
    self.busy[id]=nil;self:count();self.lastError=not ok and tostring(err)or nil
end
function M:retry()for id,job in pairs(self.jobs)do if not job.recovery then self.a.spawn(function()self:drain(id)end)end end end
function M:scan()
    if self.scanning or not self.a.pendingPages or self.a.clock()<self.scanAt then return end
    self.scanAt=self.a.clock()+60;self.scanning=true
    local ok,err=pcall(function()
        if self.a.claimRecovery and not self.a.claimRecovery()then self.pages=nil;self.pageAt=1;return end
        local pages=self.pages or self.a.pendingPages();self.pages=pages
        self.scanUntil=self.a.clock()+75;self.scanOps=0
        local page=pages:GetCurrentPage();local at=self.pageAt or 1;local count=0
        while at<=#page and count<2 and not self.closing do
            local entry=page[at];local id=type(entry.KeyName)=='string'and entry.KeyName:match('^pend:(.+)$')
            if idValid(id)and not self.jobs[id]then
                self.jobs[id]={persisted=true,indexed={},recovery=true};self:count();self:drain(id);count+=1
                self.jobs[id]=nil;self:count()
            end
            at+=1
        end
        if at>#page then
            self.pageAt=1
            if pages.IsFinished then self.pages=nil else pages:AdvanceToNextPageAsync()end
        else self.pageAt=at end
    end)
    self.scanning=false;if not ok then self.pages=nil;self.pageAt=1;self.scanError=tostring(err)else self.scanError=nil end
end
function M:start()
    self.a.spawn(function()
        while not self.closing do
            self:retry();self.a.spawn(function()self:scan()end);self.a.wait(12)
        end
    end)
    self.a.bindClose(function()
        self.closing=true;local finish=self.a.clock()+24
        repeat self:retry();self.a.wait(.25)until not next(self.jobs)and not next(self.busy)or self.a.clock()>=finish
    end)
end
return M
