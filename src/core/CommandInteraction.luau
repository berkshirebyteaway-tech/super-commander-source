local M={};M.__index=M
M.labels={attack='공격',transport='상륙',build='건설',upgrade='강화',spawn='정착',moveWarship='군함 이동',moveWarships='군함 이동',retaliate='반격',cancelTransport='복귀',alliance='외교',support='지원'}
local diagonal,hex=math.sqrt(.5),math.sqrt(3)/2
M.factionSlots={{'Confirm',0,0},{'SupportTroops',0,0},{'Details',0,-1},{'Transport',1,0},{'Alliance',0,1},{'Rockets',-1,0},{'SupportGold',-1,0},{'Signals',-diagonal,diagonal},{'Emojis',diagonal,diagonal}}
M.minorSlots={Signals=true,Emojis=true}
M.landSlots={{'Confirm',0,-1},{'Alliance',-1,0},{'BuildCity',0,-1},{'BuildPost',-1,0},{'Demolish',-1,0},{'SupportGold',-1,0},{'SupportTroops',0,1},{'Transport',1,0},{'OpenBuild',1,0},{'Rockets',-1,0},{'UpgradeMax',0,1},
    {'RingCity',0,-1},{'RingFactory',hex,-.5},{'RingPort',hex,.5},{'RingDefensePost',0,1},{'RingMissileSilo',-hex,.5},{'RingSAMLauncher',-hex,-.5},{'RingWarship',0,0}}
M.ringKinds={'City','Factory','Port','DefensePost','MissileSilo','SAMLauncher'}
function M.radialGeometry(width,height)
    local short=height<400;local compact=width<600 or height<500
    local size=short and 44 or compact and 52 or 58
    local big=short and 56 or compact and 60 or 66
    local radius=short and 78 or compact and 86 or 96
    return {size=size,big=big,radius=radius,diameter=radius*2+size+8,closeX=diagonal,closeY=-diagonal,
        icon=math.floor(size*.53),bigIcon=math.floor(big*.58),minor=math.max(44,math.floor(size*.8))}
end
function M.sameTarget(a,b)
    if not a or not b or a.tile==nil or b.tile==nil or a.kind~=b.kind or a.owner~=b.owner or a.allied~=b.allied or a.unit~=b.unit or a.mode~=b.mode then return false end
    if a.tile==b.tile then return true end
    return a.x~=nil and b.x~=nil and (a.x-b.x)^2+(a.y-b.y)^2<28^2
end
function M.sameSelection(request,selection,tile,mode,unit)
    return request~=nil and request.selection==selection and request.tile==tile and request.mode==mode and request.unit==unit
end
function M.new()return setmetatable({requests={}},M)end
function M.touchTracker()return setmetatable({touches={},positions={},touchCount=0,multiple=false},M)end
function M:pinchDistance()
    if self.touchCount~=2 then return nil end
    local a,b;for id in pairs(self.touches)do local p=self.positions[id];if not p then return nil end;if not a then a=p else b=p end end
    return a and b and math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)or nil
end
function M:beginTouch(id,eligible,x,y)
    if not eligible then return false end
    if not self.touches[id]then self.touches[id]=true;self.touchCount+=1 end
    if x and y then self.positions[id]={x=x,y=y}end
    self.distance=self:pinchDistance()
    if self.touchCount>1 then self.multiple=true end
    return not self.multiple
end
function M:moveTouch(id,x,y)
    if not self.touches[id]then return nil end
    local p=self.positions[id];if p then p.x=x;p.y=y else self.positions[id]={x=x,y=y}end
    local distance=self:pinchDistance();local previous=self.distance;self.distance=distance
    if distance and previous and distance>8 and previous>8 then return previous/distance end
    return nil
end
function M:endTouch(id)
    if self.touches[id]then self.touches[id]=nil;self.positions[id]=nil;self.touchCount-=1;self.distance=self:pinchDistance()end
    if self.touchCount==0 then self.multiple=false end
end
function M:remainingTouch()
    if self.touchCount~=1 then return nil end
    local id=next(self.touches);return id,self.positions[id]
end
function M:cancelTouches()table.clear(self.touches);table.clear(self.positions);self.touchCount=0;self.multiple=false;self.distance=nil end
function M:track(id,request,now)
    request.at=now;self.requests[id]=request
    if M.labels[request.action]then self.latest=id;self.notice=nil end
end
function M:complete(result,version,now)
    local r=self.requests[result.requestId]
    if not r or r.action~=result.action or r.version~=result.version or result.version~=version then return nil end
    self.requests[result.requestId]=nil
    if result.requestId==self.latest then
        self.latest=nil;self.notice={action=r.action,phase=result.ok and 'accepted'or 'refused',message=result.message,untilTime=now+(result.ok and .9 or 3)}
    end
    return r
end
function M:expire(id,now)
    local r=self.requests[id];if not r or now-r.at<8 then return nil end
    self.requests[id]=nil
    if id==self.latest then self.latest=nil;self.notice={action=r.action,phase='unknown',untilTime=now+4}end
    return r
end
function M:status(now)
    local r=self.latest and self.requests[self.latest]
    if r and now-r.at>=.22 then return {action=r.action,phase='pending'}end
    if self.notice and now<self.notice.untilTime then return self.notice end
end
function M:reset()table.clear(self.requests);self.latest=nil;self.notice=nil end
return M
