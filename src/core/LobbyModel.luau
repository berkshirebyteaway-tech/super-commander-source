local M={};M.__index=M
M.modes={ffa={name="자유전",min=1,max=20,wait=20},teams={name="팀 대전",min=2,max=20,wait=25},coop={name="연합전",min=1,max=5,wait=15},duel={name="1대1 연습",min=2,max=2,wait=5}}
M.modes.pvp={name="대전",min=2,max=10,wait=60,fullWait=5}
M.modes.coop.wait=3
M.maps={"world","eastasia","europe","france","pangaea","britannia"}
function M.new()return setmetatable({queues={},membership={},votes={},sequence=0,countdowns={},now=0},M)end
function M:clock(mode,now)
    self.now=now
    if mode~='pvp'then return end
    local _,count=self:selection(mode);local cfg=M.modes[mode]
    if count<cfg.min then self.countdowns[mode]=nil;return end
    local deadline=self.countdowns[mode] or now+cfg.wait
    if count>=cfg.max then deadline=math.min(deadline,now+cfg.fullWait)end
    self.countdowns[mode]=deadline
end
function M:join(ids,mode,now)
    local cfg=M.modes[mode]
    if not cfg or #ids<1 or #ids>cfg.max then return false,"참가 인원을 확인하세요."end
    if mode=="duel" and #ids>1 then return false,"1대1은 혼자 신청하세요."end
    if mode=='pvp'and #ids>1 then return false,"대전은 혼자 신청하세요. 친구와는 연합전으로 출발해요."end
    local seen={};for _,id in ipairs(ids)do if seen[id] or self.membership[id] then return false,"이미 참가 대기 중이에요."end;seen[id]=true end
    self.sequence+=1;local group={id=self.sequence,users=table.clone(ids),joined=now,mode=mode}
    self.queues[mode]=self.queues[mode] or {};table.insert(self.queues[mode],group)
    for _,id in ipairs(ids)do self.membership[id]=group end
    self:clock(mode,now)
    return true
end
function M:cancel(id,now)
    local g=self.membership[id];if not g then return end
    for i,v in ipairs(self.queues[g.mode])do if v==g then table.remove(self.queues[g.mode],i);break end end
    for _,u in ipairs(g.users)do self.membership[u]=nil;self.votes[u]=nil end
    self:clock(g.mode,now or self.now)
end
function M:vote(id,map)if self.membership[id] and table.find(M.maps,map)then self.votes[id]=map;return true end;return false end
function M:selection(mode)
    local cfg=M.modes[mode];local groups,count={},0
    for _,g in ipairs(self.queues[mode] or {})do
        if count+#g.users<=cfg.max then table.insert(groups,g);count+=#g.users end
    end
    return groups,count
end
function M:status(id,now)
    local g=self.membership[id];if not g then return nil end
    self:clock(g.mode,now)
    local groups,count=self:selection(g.mode);local cfg=M.modes[g.mode]
    local earliest=groups[1] and groups[1].joined or now
    local deadline=g.mode=='pvp'and self.countdowns[g.mode]or earliest+cfg.wait
    if g.mode=='pvp'and count<cfg.min then deadline=nil end
    return {mode=g.mode,count=count,max=cfg.max,minimum=cfg.min,remaining=deadline and math.max(0,math.ceil(deadline-now))or nil,deadline=deadline,phase=deadline and 'countdown'or 'waiting',vote=self.votes[id] or "world"}
end
function M:take(mode,now)
    local cfg=M.modes[mode];local groups,count=self:selection(mode)
    self:clock(mode,now)
    local deadline=mode=='pvp'and self.countdowns[mode]or groups[1]and groups[1].joined+cfg.wait
    if count<cfg.min or not deadline or (mode=='pvp'or count<cfg.max)and now<deadline then return nil end
    local out={mode=mode,users={},teams={},map="world",queueMode=mode};local votes={};for _,key in ipairs(M.maps)do votes[key]=0 end;local sizes={0,0}
    if mode=="pvp" then
        out.mode=count==2 and "duel"or "ffa"
    end
    if mode=="teams" then table.sort(groups,function(a,b)return #a.users>#b.users or #a.users==#b.users and a.id<b.id end)end
    for _,g in ipairs(groups)do
        local team=mode=="coop" and 1 or mode=="teams" and (sizes[1]<=sizes[2] and 1 or 2) or nil
        if team then sizes[team]+=#g.users end
        for _,id in ipairs(g.users)do table.insert(out.users,id);out.teams[id]=team;votes[self.votes[id] or "world"]+=1 end
    end
    if mode=="teams" and (sizes[1]==0 or sizes[2]==0 or math.abs(sizes[1]-sizes[2])>1)then return nil end
    for _,map in ipairs(M.maps)do if votes[map]>votes[out.map]then out.map=map end end
    for _,g in ipairs(groups)do self:cancel(g.users[1],now)end
    if mode=='pvp'then self.countdowns[mode]=nil;self:clock(mode,now)end
    return out
end
return M
