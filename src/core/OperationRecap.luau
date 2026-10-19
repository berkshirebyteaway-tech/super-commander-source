local M={};M.__index=M
local priority={settled=5,attack=1,city=2,allied=3,support=2,nuclear=4,underAttack=3,won=5,lost=5,forfeit=5,expired=5}
function M.new()return setmetatable({points={},events={},lastEvent={},period=50,elapsed=0},M)end
function M:record(kind,value)
    if not priority[kind]then return end
    if self.elapsed-(self.lastEvent[kind]or -1e9)<(kind=='attack'and 30 or 15)then return end
    self.lastEvent[kind]=self.elapsed
    if #self.events>=12 then
        local index,lowest=nil,math.huge
        for i,event in ipairs(self.events)do if event.kind~='settled'and priority[event.kind]<lowest then index=i;lowest=priority[event.kind]end end
        if not index or lowest>priority[kind]then return end;table.remove(self.events,index)
    end
    table.insert(self.events,{seconds=math.floor(self.elapsed),kind=kind,value=value})
end
function M:sample(tick,share,force)
    self.start=self.start or tick;self.elapsed=math.max(0,(tick-self.start)/10)
    if not force and self.next and tick<self.next then return end
    local last=self.points[#self.points]
    if last and last[1]==self.elapsed then last[2]=share;return end
    if #self.points>=96 then
        local compact={};for i=1,#self.points,2 do table.insert(compact,self.points[i])end
        self.points=compact;self.period*=2
    end
    table.insert(self.points,{self.elapsed,math.clamp(share,0,1)});self.next=tick+self.period
end
function M:command(action,value)
    if action=='spawn'then self:record('settled')
    elseif action=='attack'or action=='transport'then self:record('attack')
    elseif action=='nuclear'then self:record('nuclear',value)
    elseif action=='support'and (value=='gold'or value=='troops')then self:record('support',value)
    elseif action=='alliance'and value=='accept'then self:record('allied')end
end
function M:view()
    local points,events={},{}
    for _,p in ipairs(self.points)do table.insert(points,table.clone(p))end
    for _,e in ipairs(self.events)do table.insert(events,table.clone(e))end
    return {points=points,events=events}
end
return M
