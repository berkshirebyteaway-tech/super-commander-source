local U=if script then require(script.Parent.UnitRules) else require("./UnitRules")
local M={};M.__index=M
M.milestones={.05,.1,.2,.3,.5}
M.tileMilestones={100,250,500,1000}
function M.threat(troops,myTroops,attackerKind)
    local ratio=(troops or 0)/math.max(1,myTroops or 0)
    if ratio>=.3 then return "assault" end
    if ratio<.05 or attackerKind=="BOT" then return "minor" end
    return "attack"
end
function M.new() return setmetatable({},M) end
function M:update(s)
    if s.ownershipOnly then return {} end
    local baseline=self.version~=s.version or not self.phase or self.phase=="menu"
    if baseline then self.factions={};self.units={};self.operations={};self.requests={};self.lastEffect=0;self.milestone=0;self.tileMilestone=0;self.cities=nil end
    local out={};local function emit(kind,fields) fields=fields or {};fields.kind=kind;table.insert(out,fields) end
    local factions={};local units={};local operations={};local requests={};local landTroops={}
    for _,f in ipairs(s.factions or {}) do
        factions[f.id]={id=f.id,name=f.name,tiles=f.tiles,allied=f.allied,eliminated=f.eliminated,labelTile=f.labelTile,kind=f.kind,traitor=f.traitor}
        local old=self.factions[f.id]
        if not baseline and old and f.id~=1 then
            local betrayed=not f.allied and old.allied and f.traitor==true and not old.traitor
            if f.allied~=old.allied then emit(f.allied and "allied" or betrayed and "betrayal" or "allianceEnded",{name=f.name,tile=f.labelTile,owner=f.id}) end
        end
    end
    if not baseline and self.phase=="playing" then
        for id,old in pairs(self.factions) do
            local f=factions[id]
            if id~=1 and old.tiles>0 and not old.eliminated and (not f or f.tiles==0 or f.eliminated) then emit("eliminated",{name=old.name,tile=old.labelTile,owner=id}) end
        end
    end
    local share=s.player and s.player.share or 0
    local reached=0;for i,v in ipairs(M.milestones)do if share>=v then reached=i end end
    if baseline then self.milestone=reached
    elseif self.phase=="playing" and s.phase=="playing" and reached>self.milestone then
        self.milestone=reached;emit("milestone",{share=M.milestones[reached],tile=s.player.labelTile,owner=1})
    end
    local tiles=s.player and s.player.tiles or 0
    local tileReached=0;for i,v in ipairs(M.tileMilestones)do if tiles>=v then tileReached=i end end
    if baseline then self.tileMilestone=tileReached
    elseif self.phase=="playing" and s.phase=="playing" and tileReached>self.tileMilestone then
        self.tileMilestone=tileReached;emit("tiles",{tiles=M.tileMilestones[tileReached],tile=s.player.labelTile,owner=1})
    end
    local cities=0
    for _,u in ipairs(s.units or {}) do
        if not U.structures[u.kind] then continue end
        units[u.id]={building=u.building,level=u.level,owner=u.owner}
        if u.owner==1 and u.kind=="City" and not u.building then cities+=1 end
        local old=self.units[u.id]
        if not baseline and u.owner==1 and not u.building then
            if (old and old.owner==1 and old.building) or (not old and (u.assemblyStartedTick or u.createdTick or -1)>=(self.tick or 0)) then
                emit("complete",{tile=u.tile,name=U.names[u.kind],id=u.id,unit=u.kind,first=u.kind=="City" and self.cities==0 or nil})
            elseif old and old.owner==1 and u.level>old.level then emit("upgraded",{tile=u.tile,name=U.names[u.kind],id=u.id}) end
        end
    end
    for _,op in ipairs(s.operations or {}) do
        if op.retreating or op.retreated then continue end
        local key=(op.kind or "land")..":"..op.id;operations[key]=true
        local merged=op.kind=="land" and op.direction=="outgoing" and self.landTroops and self.landTroops[op.target] or 0
        if op.kind=="land" and op.direction=="outgoing" then landTroops[op.target]=(landTroops[op.target] or 0)+op.troops end
        if not baseline and not self.operations[key] and op.direction=="outgoing" and op.troops-merged>0 then emit("sortie",{troops=op.troops-merged,tile=op.frontTile,owner=1}) end
        if not baseline and not self.operations[key] and op.direction=="incoming" then
            local attacker=factions[op.owner]
            emit("incoming",{owner=op.owner,tile=op.frontTile,troops=op.troops,threat=M.threat(op.troops,s.player and s.player.troops,attacker and attacker.kind),name=attacker and attacker.name})
        end
    end
    for _,u in ipairs(s.units or {}) do
        if U.nukes[u.kind] and u.owner~=1 and u.target==1 then
            local key="rocket:"..u.id;operations[key]=true
            if not baseline and not self.operations[key] then emit("rocketWarning",{tile=u.targetTile}) end
        end
    end
    for _,r in ipairs(s.diplomacy and s.diplomacy.incoming or {}) do
        local key=tostring(r.from)..":"..r.created;requests[key]=true
        if not baseline and not self.requests[key] then emit("request",{name=r.name,owner=r.from}) end
    end
    for _,e in ipairs(s.unitEffects or {}) do
        if e.id>self.lastEffect then
            self.lastEffect=e.id
            if not baseline and (s.tick or 0)-(e.tick or 0)<=15 then
                if e.kind~="trade" or e.owner==1 then local copy=table.clone(e);copy.weapon=e.weapon;emit(e.kind,copy) end
            end
        end
    end
    if not baseline and self.phase~=s.phase then
        if s.phase=="won" or s.phase=="lost" then emit(s.phase=="won" and "victory" or "defeat",{tile=s.player and s.player.labelTile})
        elseif s.phase=="playing" and self.phase=="spawn" then emit("start",{tile=s.player and s.player.labelTile}) end
    end
    self.version=s.version;self.phase=s.phase;self.tick=s.tick
    self.cities=cities
    self.factions=factions;self.units=units;self.operations=operations;self.landTroops=landTroops;self.requests=requests
    return out
end
return M
