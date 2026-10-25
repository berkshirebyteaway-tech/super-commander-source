-- SPDX-License-Identifier: AGPL-3.0-only
local R=if script then require(script.Parent.PseudoRandom) else require("./PseudoRandom")
local M={};M.__index=M
function M.hash(value)
    local h=0
    local function add(c) h=(h*31+c)%4294967296 end
    for _,c in utf8.codes(value) do
        if c>65535 then local n=c-65536;add(55296+math.floor(n/1024));add(56320+n%1024) else add(c) end
    end
    return math.abs(h>=2147483648 and h-4294967296 or h)
end
function M.new(world,id,key)
    local r=R.new(M.hash(key))
    local self=setmetatable({world=world,id=id,random=r,active=true,initialized=false,neighborsNeutral=true},M)
    self.rate=r:nextInt(40,80);self.offset=r:nextInt(0,self.rate)
    self.trigger=r:nextInt(50,60)/100;self.reserve=r:nextInt(30,40)/100;self.expand=r:nextInt(10,20)/100
    return self
end
function M:traitor(includeAllies)
    if self.world.settings.disableAlliances then return nil end
    local candidates={}
    for _,id in ipairs(self.world:nearby(self.id)) do
        if id~=0 and (includeAllies or not self.world:friendly(self.id,id)) and self.world.sim.players[id].isTraitor then table.insert(candidates,id) end
    end
    return #candidates>0 and self.random:randElement(candidates) or nil
end
function M:send(target)
    local w=self.world;local p=w.sim.players[self.id]
    if not w:sharesLandBorder(self.id,target) then
        return w:sendBotTransport(self.id,target,self.reserve,self.expand)
    end
    local ratio=target~=0 and not (w.sim.players[target].kind=="BOT" and w:hasStructures(target)) and self.reserve or self.expand
    local troops=p.troops-w:maxTroops(self.id)*ratio
    if troops<1 then return false end
    w.sim:attack(self.id,target,troops);return true
end
function M:randomAttack()
    local w=self.world;local p=w.sim.players[self.id]
    if p.troops/w:maxTroops(self.id)<self.trigger then return end
    local attacker,largest=nil,0
    for _,a in ipairs(p.incoming) do
        if not w:friendly(self.id,a.owner) and a.troops>largest then attacker=a.owner;largest=a.troops end
    end
    if attacker and self:send(attacker) then return end
    local traitor=self:traitor()
    if traitor and self.random:chance(3) and self:send(traitor) then return end
    for _,id in ipairs(self.random:shuffleArray(w:nearby(self.id))) do
        if id==0 or w:friendly(self.id,id) then continue end
        local kind=w.sim.players[id].kind
        if (kind=="HUMAN" or kind=="NATION") and self.random:chance(2) then continue end
        if self:send(id) then return end
    end
end
function M:tick(tick)
    if not self.active or tick%self.rate~=self.offset then return end
    local w=self.world
    if w.sim.players[self.id].tiles.size==0 then self.active=false;return end
    if not self.initialized then self.initialized=true;self:send(0);return end
    w:acceptBotAlliances(self.id)
    w:deleteBotStructure(self.id)
    local traitor=self:traitor(true)
    if traitor and self.random:chance(w:friendly(self.id,traitor) and 6 or 3) then
        w:breakAlliance(self.id,traitor)
        if self:send(traitor) then return end
    end
    if self.neighborsNeutral then
        if table.find(w:nearby(self.id),0) then
            if self:send(0) then return end
        else self.neighborsNeutral=false end
    end
    self:randomAttack()
end
return M
