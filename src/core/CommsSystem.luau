local Catalog=if script then require(script.Parent.CommsCatalog) else require("./CommsCatalog")
local Random=if script then require(script.Parent.PseudoRandom) else require("./PseudoRandom")
local M={};M.__index=M
M.messages={help="도와주세요!",attack="함께 공격해요!",defend="이곳을 지켜주세요!",peace="서로 공격하지 말아요.",thanks="고마워요!",trade="교역을 함께해요."}
M.emojis=Catalog.emojis
M.catalog={};for _,message in ipairs(Catalog.messages) do M.catalog[message.key]=message end
function M.new(w) return setmetatable({w=w,events={},nextId=0,lastEmoji={},lastChat={},lastTarget={},targets={}},M) end
function M:emit(kind,from,to,text,target)
    self.nextId+=1;table.insert(self.events,{id=self.nextId,kind=kind,from=from,to=to,text=text,target=target,tick=self.w.sim.ticks})
    if #self.events>64 then table.remove(self.events,1) end
end
function M:command(owner,kind,target,value)
    local w=self.w;local p,q=w.sim.players[owner],w.sim.players[target]
    if w.phase~="playing" or not p or p.tiles.size==0 or not (kind=="emoji" and target==0) and (not q or target==owner or q.tiles.size==0) then return false,"활동 중인 상대 부대를 선택하세요." end
    local key=owner..":"..target;local now=w.sim.ticks
    if kind=="target" then
        if w:friendly(owner,target) then return false,"동맹을 공동 목표로 지정할 수 없어요." end
        if self.lastTarget[owner] and now-self.lastTarget[owner]<150 then return false,"공동 목표 표시는 15초마다 보낼 수 있어요." end
        self.lastTarget[owner]=now;table.insert(self.targets,{owner=owner,target=target,tick=now})
        w:changeRelation(target,owner,-40);self:emit(kind,owner,0,"공동 공격 목표",target)
    elseif kind=="emoji" then
        if not table.find(M.emojis,value) then return false,"등록된 표정만 보낼 수 있어요." end
        if p.kind=="HUMAN" then
            self.emojiLog=self.emojiLog or {};local log=self.emojiLog[key] or {};local recent={}
            for _,t in ipairs(log) do if now-t<50 then table.insert(recent,t) end end
            if #recent>=5 then self.emojiLog[key]=recent;return false,"표정은 상대별 5초에 5개까지 보낼 수 있어요." end
            table.insert(recent,now);self.emojiLog[key]=recent
        elseif self.lastEmoji[key] and now-self.lastEmoji[key]<50 then return false,"표정은 상대별 5초마다 보낼 수 있어요." end
        self.lastEmoji[key]=now;w:aiEmoji(owner,target,value);self:emit(kind,owner,target,value)
        self:respond(owner,target,value)
    elseif kind=="quickChat" then
        local keyValue=type(value)=="table" and value.key or value
        local entry=M.catalog[keyValue];local message=entry and entry.text or M.messages[keyValue]
        local subject=type(value)=="table" and value.target or nil
        if not message then return false,"등록된 메시지를 선택하세요." end
        if entry and entry.requiresTarget and (type(subject)~="number" or subject%1~=0 or not w.sim.players[subject]) then return false,"메시지에서 언급할 부대를 선택하세요." end
        if self.lastChat[key] and now-self.lastChat[key]<30 then return false,"메시지는 상대별 3초마다 보낼 수 있어요." end
        self.lastChat[key]=now;self:emit(kind,owner,target,message,entry and entry.requiresTarget and subject or nil)
    else return false,"알 수 없는 소통 명령이에요." end
    return true,"전달했어요."
end
function M:respond(sender,recipient,emoji)
    local w=self.w;local p=w.sim.players[recipient];local key=recipient..":"..sender;local now=w.sim.ticks
    if not p or p.kind~="NATION" or self.lastEmoji[key] and now-self.lastEmoji[key]<50 then return end
    local choices
    if emoji=="😤" then w:changeRelation(recipient,sender,-100);choices={"😤","😡","🤡","😞","😭"}
    elseif emoji=="🤡" then w:changeRelation(recipient,sender,-10);choices={"❓","🤡"}
    elseif table.find({"🕊️","🏳️","❤️","🥰","👏"},emoji) then
        if w.settings.difficulty=="Easy" then w:changeRelation(recipient,sender,15) end
        choices=w:relation(sender,recipient)>=0 and {"❤️","😊","🥰"} or {"❓","🤡"}
    end
    if choices then
        local reply=Random.new(now):randElement(choices);self.lastEmoji[key]=now
        self:emit("emoji",recipient,sender,reply)
        if w.nations[recipient] then w.nations[recipient].diplomacy.sent[sender]=now end
    end
end
function M:forPlayer(viewer,swap)
    swap=swap or function(id)return id end;local events,targets={},{}
    for _,e in ipairs(self.events) do if (not self.w.chatManaged or self.w.sim.players[e.from].kind~='HUMAN')and self.w.sim.ticks-e.tick<=100 and (e.from==viewer or e.to==viewer or e.kind=="emoji" and e.to==0 or e.kind=="target" and self.w:friendly(viewer,e.from)) then
        local out=table.clone(e);out.from=swap(out.from);out.to=swap(out.to);if out.target then out.target=swap(out.target) end;table.insert(events,out)
    end end
    local p=self.w.sim.players[viewer];local r=(self.w.resources or {})[viewer]or {}
    for _,t in ipairs(self.targets) do if p.tiles.size>0 and not r.forfeited and self.w.sim.ticks-t.tick<100 and (t.owner==viewer or self.w:friendly(viewer,t.owner)) then table.insert(targets,{owner=swap(t.owner),target=swap(t.target),tick=t.tick}) end end
    return {events=events,targets=targets}
end
return M
