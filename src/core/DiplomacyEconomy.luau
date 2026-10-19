-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. Luau adaptation of pinned DonateGoldExecution,
local B=if script then require(script.Parent.BigNat) else require("./BigNat")
local R=if script then require(script.Parent.PseudoRandom) else require("./PseudoRandom")
local C=if script then require(script.Parent.ConfigConstants) else require("./ConfigConstants")
local M={};M.__index=M
local ZERO={0}
function M.goldRelation(gold,tick,difficulty,spawnTicks)
    local chunk=({Easy=2500,Medium=5000,Hard=12500,Impossible=25000})[difficulty]
    local adjusted=math.floor(chunk+chunk*(tick/(3000+(spawnTicks or 100)))+.5)
    for chunks=20,1,-1 do if B.compare(gold,B.fromNumber(adjusted*chunks))>=0 then return chunks*5 end end
    return 0
end
function M.troopThreshold(random,cap,difficulty)
    local divisor=({Easy={13,11},Medium={11,9},Hard={9,7},Impossible={7,5}})[difficulty]
    return random:nextInt(cap/divisor[1],cap/divisor[2])
end
function M.new(world) return setmetatable({world=world,pending={},active={},last={},events={},nextEvent=0},M) end
function M:remaining(a,b,tick)
    local last=(self.last[a] or {})[b]
    return last and math.max(0,100-((tick or self.world.sim.ticks)-last)) or 0
end
function M:canDonate(a,b,kind,tick)
    local w=self.world;local p,q=w.sim.players[a],w.sim.players[b]
    if not p or not q or a==b or p.tiles.size==0 or q.tiles.size==0 or not w:friendly(a,b) then return false end
    if q.kind=="HUMAN" and w.settings[kind=="gold" and "donateGold" or "donateTroops"]==false then return false end
    return self:remaining(a,b,tick)==0
end
function M:hasEmbargo(a,b) return (self.world.resources[a].embargo or {})[b]~=nil end
function M:canTrade(a,b) return a~=b and not self:hasEmbargo(a,b) and not self:hasEmbargo(b,a) end
function M:embargoAll(owner,enabled)
    local w=self.world;local p=w.sim.players[owner];local r=w.resources[owner]
    if w.phase~="playing" or not p or p.tiles.size==0 or type(enabled)~="boolean" then return false,"진행 중인 경기에서 사용할 수 있어요." end
    if w.sim.ticks-(r.lastEmbargoAll or -1)<100 then return false,"전체 금수는 10초마다 바꿀 수 있어요." end
    local found=false
    for id,q in ipairs(w.sim.players) do if id~=owner and q.kind~="BOT" and not (p.team and p.team==q.team) and not w:friendly(owner,id,true) then
        found=true;self:embargo(owner,id,enabled,false,w.sim.ticks)
    end end
    if not found then return false,"교역을 끊을 적이 없어요." end
    r.lastEmbargoAll=w.sim.ticks;return true,enabled and "적과 교역을 중단했어요." or "적과 교역을 재개했어요."
end
function M:embargo(a,b,enabled,temporary,tick)
    local r=self.world.resources[a];r.embargo=r.embargo or {}
    local previous=r.embargo[b]
    if enabled then
        if previous and (previous==true or not previous.temporary) then return end
        r.embargo[b]={created=tick,temporary=temporary==true}
    else r.embargo[b]=nil end
end
function M:endTemporary(a,b)
    local r=self.world.resources[a];local e=r.embargo and r.embargo[b]
    if type(e)=="table" and e.temporary then r.embargo[b]=nil end
end
function M:expireTemporary(a,tick)
    local r=self.world.resources[a];if not r.embargo then return end
    for b,e in pairs(r.embargo) do if type(e)=="table" and e.temporary and tick-e.created>C.temporaryEmbargoDuration then r.embargo[b]=nil end end
end
function M:queue(a,b,kind,amount)
    local w=self.world
    if w.phase~="playing" or not w.resources[a] or not w.resources[b] or a==b then return false,"활동 중인 상대를 선택하세요." end
    if kind=="gold" or kind=="troops" then
        if not self:canDonate(a,b,kind) then return false,"동맹에게만 지원할 수 있어요. 같은 상대에게는 10초마다 보낼 수 있어요." end
        if amount~=nil and (type(amount)~="number" or amount~=amount or amount<=0 or amount>9007199254740991) then return false,"지원량이 올바르지 않아요." end
        if kind=="gold" and B.compare(w:getGold(a),ZERO)==0 then return false,"보낼 골드가 없어요." end
        if kind=="troops" and (w.sim.players[a].troops<1 or w:maxTroops(b)<=w.sim.players[b].troops) then return false,"상대의 병력이 최대이거나 보낼 병력이 없어요." end
    elseif kind~="embargoStart" and kind~="embargoStop" then return false,"지원 명령이 올바르지 않아요." end
    for _,list in ipairs({self.pending,self.active}) do
        for _,o in ipairs(list) do if o.a==a and o.b==b then return false,"이 상대에게 보낸 명령을 처리 중이에요." end end
    end
    table.insert(self.pending,{a=a,b=b,kind=kind,amount=amount});return true,"외교 명령을 보냈어요."
end
function M:record(o,amount,tick,relation)
    local w=self.world
    self.last[o.a]=self.last[o.a] or {};self.last[o.a][o.b]=tick
    self.nextEvent+=1
    local event={id=self.nextEvent,from=o.a,to=o.b,kind=o.kind,amount=amount,tick=tick,relation=relation}
    table.insert(self.events,event);if #self.events>16 then table.remove(self.events,1) end
    if w.unitSystem then w.unitSystem:effect("support",w.sim.players[o.b].spawnTile,o.a,{target=o.b,amount=amount,resource=o.kind}) end
    if relation>0 then w:changeRelation(o.b,o.a,relation) end
    local text=string.format(o.kind=="gold" and "%s → %s 골드 %s 지원" or "%s → %s 병력 %s 지원",w.resources[o.a].name,w.resources[o.b].name,tostring(amount))
    w:notify(o.a,text,"donation");w:notify(o.b,text,"donation")
end
function M:step(tick)
    local w=self.world
    for _,o in ipairs(self.active) do
        if o.kind=="embargoStart" or o.kind=="embargoStop" then
            self:embargo(o.a,o.b,o.kind=="embargoStart",false,tick)
            w:notify(o.a,string.format(o.kind=="embargoStart" and "%s에 무역 금수를 적용했어요." or "%s의 무역 금수를 해제했어요.",w.resources[o.b].name),"diplomacy")
        elseif o.kind=="gold" then
            if self:canDonate(o.a,o.b,o.kind,tick) and B.compare(o.amount,ZERO)>0 then
                local balance=w:getGold(o.a);local removed=B.compare(balance,o.amount)<0 and balance or o.amount
                if B.compare(removed,ZERO)>0 then
                    w:setGold(o.a,B.subtract(balance,removed));w:setGold(o.b,B.add(w:getGold(o.b),removed))
                    self:record(o,B.toString(removed),tick,M.goldRelation(o.amount,tick+100,w.settings.difficulty or "Medium"))
                end
            end
        elseif o.amount>0 then
            local minimum=M.troopThreshold(o.random,w:maxTroops(o.b),w.settings.difficulty or "Medium")
            if self:canDonate(o.a,o.b,o.kind,tick) then
                local removed=w.sim:removeTroops(o.a,o.amount)
                if removed>0 then w.sim:addTroops(o.b,removed);self:record(o,tostring(removed),tick,o.amount>=minimum and 50 or 0) end
            end
        end
    end
    self.active={}
    for _,o in ipairs(self.pending) do
        o.random=R.new(tick+100)
        if o.kind=="gold" then o.amount=o.amount and B.fromNumber(math.floor(o.amount)) or B.divideSmall(w:getGold(o.a),3)
        elseif o.kind=="troops" then o.amount=math.min(o.amount or math.floor(w.sim.players[o.a].troops/3),w:maxTroops(o.b)-w.sim.players[o.b].troops) end
        table.insert(self.active,o)
    end
    self.pending={}
end
return M
