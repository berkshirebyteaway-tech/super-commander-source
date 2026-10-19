--!native
-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. BotAnnexation.ts (OpenFront fac309ac): Hard & Impossible take tribes
local T=if script then require(script.Parent.Terrain) else require("./Terrain")
local C=if script then require(script.Parent.NationCommon) else require("./NationCommon")
local M={}
local NO_BOTS={}
local function byte(sim,t) local tb=sim.tb;if tb then return buffer.readu8(tb,t) end;return sim.terrain[t+1] end
local function oceanShore(sim,t,w,h)
    if not T.isLand(byte(sim,t)) then return false end
    local x=t%w
    return x~=0 and T.isOcean(byte(sim,t-1)) or x~=w-1 and T.isOcean(byte(sim,t+1)) or t>=w and T.isOcean(byte(sim,t-w)) or t<(h-1)*w and T.isOcean(byte(sim,t+w))
end
local function edge(sim,t,w,h)
    local x=t%w
    if x==0 or x==w-1 or t<w or t>=(h-1)*w then return true end
    return T.isImpassable(byte(sim,t-1)) or T.isImpassable(byte(sim,t+1)) or T.isImpassable(byte(sim,t-w)) or T.isImpassable(byte(sim,t+w))
end
local function attackedBy(w,id)
    local targets={};for _,attack in ipairs(w.sim.players[id].outgoing) do if attack.target~=0 then targets[attack.target]=true end end;return targets
end
local function scanner(w,us)
    local sim=w.sim;local width,height=sim.width,sim.height;local owners=sim.owners;local attackable={}
    local function attackableBot(id)
        local bot=attackable[id]
        if bot==nil then local p=sim.players[id];bot=p~=nil and p.kind=="BOT" and not w:friendly(us,id) and id or false;attackable[id]=bot end
        return bot
    end
    return function(bot,closedOnly,within)
        local s={bot=bot,bordersUs=false,open=false,bots={},has={}};local gaveUp=false
        sim.players[bot].border:forEach(function(t)
            if gaveUp then return end
            if oceanShore(sim,t,width,height) or edge(sim,t,width,height) then s.open=true;gaveUp=closedOnly;return end
            local x=t%width
            for i=1,4 do
                local n
                if i==1 then if t<width then continue end;n=t-width
                elseif i==2 then if t>=(height-1)*width then continue end;n=t+width
                elseif i==3 then if x==0 then continue end;n=t-1
                else if x==width-1 then continue end;n=t+1 end
                local id=owners[n+1]
                if id==bot then continue end
                if id==us then s.bordersUs=true;continue end
                local other=id~=0 and attackableBot(id) or false
                if not other then s.open=true;gaveUp=closedOnly
                elseif within and not within[other] then gaveUp=true
                elseif not s.has[other] then s.has[other]=true;table.insert(s.bots,other) end
                if gaveUp then return end
            end
        end)
        return if gaveUp then nil else s
    end
end
function M.walledIn(w,id,bots)
    local scan=scanner(w,id);local attacking=attackedBy(w,id);local out={}
    for _,bot in ipairs(bots) do
        if attacking[bot] then continue end
        local s=scan(bot,true,NO_BOTS);if s and s.bordersUs then table.insert(out,bot) end
    end
    return out
end
function M.plan(w,id,bots)
    local sim=w.sim;local scan=scanner(w,id);local region,order={},{}
    for _,bot in ipairs(bots) do region[bot]=scan(bot,false);table.insert(order,region[bot]) end
    local front={};for _,bot in ipairs(bots) do if region[bot].bordersUs then table.insert(front,bot) end end
    local behind={}
    for _,bot in ipairs(front) do
        for _,other in ipairs(region[bot].bots) do
            if region[other] or behind[other] then continue end
            behind[other]=true
            local s=scan(other,true);if s then region[other]=s;table.insert(order,s) end
        end
    end
    local attacking=attackedBy(w,id)
    local function tiles(bot) return sim.players[bot].tiles.size end
    local candidates={}
    for _,s in ipairs(order) do if not s.open and #s.bots>0 and not attacking[s.bot] and not C.ownsStructures(w,s.bot) then table.insert(candidates,s) end end
    C.sort(candidates,function(s) return -tiles(s.bot) end)
    local kept,nextToKept,walledIn={},{},{}
    for _,s in ipairs(candidates) do
        if nextToKept[s.bot] then continue end
        kept[s.bot]=true
        local share=tiles(s.bot)/#s.bots
        for _,other in ipairs(s.bots) do nextToKept[other]=true;walledIn[other]=(walledIn[other] or 0)+share end
    end
    local function value(bot) return (tiles(bot)+(walledIn[bot] or 0))/math.max(1,sim.players[bot].troops) end
    local targets={}
    for _,bot in ipairs(bots) do
        local s=region[bot];local walled=s.bordersUs and not s.open and #s.bots==0
        if not kept[bot] and not walled then table.insert(targets,bot) end
    end
    C.sort(targets,function(bot) return -value(bot) end)
    local any=false;for _,bot in ipairs(targets) do if region[bot].bordersUs then any=true;break end end
    if not any then
        local rest={};for _,bot in ipairs(front) do if kept[bot] then table.insert(rest,bot) end end
        for _,bot in ipairs(C.sort(rest,function(bot) return -value(bot) end)) do table.insert(targets,bot) end
    end
    return targets
end
return M
