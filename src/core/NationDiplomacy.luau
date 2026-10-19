-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. NationAllianceBehavior / NationEmojiBehavior, pinned e02eeba.
local C=if script then require(script.Parent.NationCommon) else require("./NationCommon")
local M={};M.__index=M
function M.new(ai) return setmetatable({ai=ai,last={},sent={}},M) end
function M:eligible(target,limit)
    local a=self.ai
    if target==0 then return true end
    if a.world.sim.players[target].kind~="HUMAN" then return false end
    if limit then
        local previous=self.last[target] or -300
        if a.world.sim.ticks-previous<=300 then return false end
        self.last[target]=a.world.sim.ticks
    end
    return true
end
function M:emoji(target,choices)
    local a=self.ai;local tick=a.world.sim.ticks
    if not self:eligible(target,false) or tick-(self.sent[target] or -math.huge)<50 then return end
    local emoji=a.random:randElement(choices);self.sent[target]=tick
    if a.world.aiEmoji then a.world:aiEmoji(a.id,target,emoji) end
end
function M:maybeEmoji(target,choices) if self:eligible(target,true) then self:emoji(target,choices) end end
function M:attackEmoji(target)
    if not self:eligible(target,true) then return end
    local a=self.ai;local neutral=a.world:relation(a.id,target)>=0
    if a.random:chance(neutral and 2 or 4) then self:emoji(target,{neutral and "😈" or "😡"}) end
end
function M:casual()
    local a=self.ai;local w,p,r=a.world,a.player,a.random;local tick=w.sim.ticks+100
    if r:chance(16) and #p.incoming>0 and C.sum(p.incoming)>=p.troops*3 then self:emoji(0,{"💀","🆘","😱","🥺","😭","😞","🫡","👋"}) end
    if r:chance(8) and p.troops>0 then
        for _,attack in ipairs(p.incoming) do
            if w.sim.players[attack.owner].kind=="HUMAN" and attack.troops<p.troops*.1 then
                local choices=r:chance(2) and {"❓","🤡"} or {"🥱"}
                if self:eligible(attack.owner,true) then self:emoji(attack.owner,choices) end
            end
        end
    end
    if r:chance(300) then
        local largest=nil;for id,other in ipairs(w.sim.players) do if other.tiles.size>0 and (not largest or other.tiles.size>w.sim.players[largest].tiles.size) then largest=id end end
        if largest==a.id then self:emoji(0,{"👑","🥇","💪"}) end
    end
    if r:chance(250) then
        local humans={};for _,id in ipairs(C.allies(w,a.id)) do if w.sim.players[id].kind=="HUMAN" then table.insert(humans,id) end end
        if #humans>0 then local id=r:randElement(humans);self:emoji(id,r:chance(3) and {"❤️","😊","🥰"} or {"🤝","😇","💪"}) end
    end
    if r:chance(3) then
        for id,other in ipairs(w.sim.players) do
            if other.tiles.size>0 and other.kind=="HUMAN" and other.isTraitor and self:mocker(id)==a.id then self:emoji(id,{"🤡","🤦‍♂️"}) end
        end
    end
    if tick>=6000 and r:chance(10000) then
        local ids={};for id,other in ipairs(w.sim.players) do if other.kind=="HUMAN" and other.tiles.size>0 and other.tiles.size<w.map.meta.landTiles*.01 then table.insert(ids,id) end end
        if #ids>0 then self:emoji(r:randElement(ids),{"🐀"}) end
    end
    if tick<=600 and r:chance(250) then
        local ids={};for _,id in ipairs(w:nearby(a.id)) do if id~=0 and w.sim.players[id].kind=="HUMAN" then table.insert(ids,id) end end
        if #ids>0 then self:emoji(r:randElement(ids),{"👋"}) end
    end
end
local function level(v) return v< -50 and 0 or v<0 and 1 or v<50 and 2 or 3 end
function M:mocker(traitor)
    local w=self.ai.world;local best,worst=nil,nil
    for id,p in ipairs(w.sim.players) do
        if p.kind~="NATION" or p.tiles.size==0 or w:friendly(id,traitor) then continue end
        local v=level(w:relation(id,traitor));if best==nil or v<worst then best,worst=id,v end
    end
    return best
end
function M:decision(id,response)
    local a=self.ai;local w,p,r,d=a.world,a.player,a.random,a.difficulty;local other=w.sim.players[id]
    local confused=({Easy=10,Medium=20,Hard=40})[d];if confused and r:chance(confused) then return r:chance(2) end
    local function reject() if response and r:chance(3) then self:emoji(id,{"❓","🤡"}) end;return false end
    if other.isTraitor and r:nextInt(0,100)>=10 then return reject() end
    if C.smart(d) then
        local count=0;for _,pl in ipairs(w.sim.players) do if pl.kind~="BOT" and pl.tiles.size>0 then count+=1 end end
        if #C.allies(w,id)>=count*(d=="Hard" and .5 or .25) then return false end
    end
    if C.leader(w,a.id)==id then return false end
    local threat=d=="Medium" and other.troops>p.troops*2.5 or d=="Hard" and other.troops>p.troops and w:maxTroops(id)>w:maxTroops(a.id)*2 or d=="Impossible" and (other.troops>p.troops*1.5 or other.troops>p.troops and (w:maxTroops(id)>w:maxTroops(a.id)*1.5 or other.tiles.size>p.tiles.size*1.5))
    if threat then if r:chance(6) then self:emoji(id,response and {"❤️","😊","🥰"} or {"🙏","🥺"}) end;return true end
    if C.team(w,a.id) then local odds=({Easy=25,Medium=50,Hard=75})[d];if not odds or r:nextInt(0,100)<odds then return false end end
    local relation=w:relation(a.id,id)
    if relation<0 then return reject() end
    if relation>=50 and (not C.smart(d) or r:nextInt(0,100)>=(d=="Hard" and 17 or 33)) then if r:chance(3) then self:emoji(id,{"🤝"}) end;return true end
    if d=="Medium" then if #C.allies(w,a.id)>=r:nextInt(4,6) then return false end
    elseif C.smart(d) then
        local count,friends,contains=0,0,false
        for _,n in ipairs(w:nearby(a.id)) do if n~=0 and w.sim.players[n].kind~="BOT" then count+=1;if w:friendly(a.id,n) then friends+=1 end;if n==id then contains=true end end end
        if count>=2 and contains then if count<=friends+1 then return false end
        elseif #C.allies(w,a.id)>=(d=="Hard" and r:nextInt(3,5) or r:nextInt(2,4)) then return false end
    end
    if w.sim.ticks<({Easy=3000,Medium=1800,Hard=1800,Impossible=600})[d] and r:nextInt(0,100)>=({Easy=10,Medium=30,Hard=50,Impossible=70})[d] then return true end
    local tr=({Easy=60,Medium=70,Hard=75,Impossible=80})[d];local ti=({Easy=70,Medium=80,Hard=85,Impossible=90})[d]
    local ours,theirs=C.total(p),C.total(other)
    local troops=ours*(r:nextInt(tr,tr+10)/100);local tiles=p.tiles.size*(r:nextInt(ti,ti+10)/100)
    return theirs>troops or other.tiles.size>tiles and theirs>ours*.5
end
function M:requests(enemies)
    local a=self.ai;local w=a.world
    if w.settings.disableAlliances or w.settings.customAllianceDuration==0 then return end
    for _,id in ipairs(enemies) do
        if a.random:chance(30) and (a.difficulty=="Easy" or w.sim.players[id].kind~="BOT") and w:canRequest(a.id,id) and self:decision(id,false) then w:allianceCommand(a.id,id,"request") end
    end
end
function M:respond()
    local a=self.ai;local w=a.world
    if w.settings.disableAlliances or w.settings.customAllianceDuration==0 then return end
    for _,request in ipairs(w:orderedRequests(a.id)) do local yes=request.created>1 and self:decision(request.a,true);w:resolveRequest(a.id,request.a,yes,nil,not yes and "rejected" or nil) end
    for _,alliance in ipairs(w:orderedAlliances(a.id)) do
        if alliance.agreed[alliance.a]~=alliance.agreed[alliance.b] then
            local other=alliance.a==a.id and alliance.b or alliance.a
            if self:decision(other,true) then w:allianceCommand(a.id,other,"extend") end
        end
    end
end
function M:betray(friends,enemies)
    local a=self.ai;local w,p,d=a.world,a.player,a.difficulty
    if w.settings.disableAlliances then return false end
    local juicy=C.juicy(w,friends)
    for _,id in ipairs(friends) do
        local other=w.sim.players[id];local safe=false
        if C.smart(d) and id==juicy then
            local total=C.total(other);for _,enemy in ipairs(enemies) do total+=C.total(w.sim.players[enemy]) end
            if not other.isTraitor then for _,friend in ipairs(friends) do if friend~=id then total+=C.total(w.sim.players[friend]) end end end
            safe=total<p.troops*.33
        end
        if safe or ((d=="Easy" or d=="Medium") and not (d=="Easy" and other.kind=="HUMAN") and p.troops>=other.troops*10) or d~="Easy" and (other.isTraitor and other.troops<p.troops*1.2 or #friends+#enemies==1 and other.troops*3<p.troops) then
            w:breakAlliance(a.id,id);return a:send(id,true)
        end
    end
    return false
end
return M
