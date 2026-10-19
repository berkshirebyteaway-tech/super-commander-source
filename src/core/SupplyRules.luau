local Config=if script then require(script.Parent.LaunchCommerce)else require('./LaunchCommerce')
local Catalog=if script then require(script.Parent.SupplyCatalog)else require('./SupplyCatalog')
local Styles=if script then require(script.Parent.CosmeticCatalog)else require('./CosmeticCatalog')
local Reveal=if script then require(script.Parent.SupplyRevealRules)else require('./SupplyRevealRules')
local M={}
local function integer(n)return type(n)=='number'and n==n and n%1==0 and n>=0 and n<=1e12 end
local function copy(t)if type(t)~='table'then return t end;local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r end
function M.new()return {version=1,tickets={basic=0,epic=0,legendary=0,mythic=0},fragments={basic=0,epic=0,legendary=0,mythic=0},owned={},serials={},receipts={},draws={},history={},presets={},drawSequence=0,dailyClub=-1,dailyFree=-1,permanentWelcome=false}end
function M.decode(raw)
    if raw==nil then return M.new()end
    if type(raw)~='table'or raw.version~=1 then return nil,'invalid-commerce'end
    local out=copy(raw);local base=M.new();for k,v in pairs(base)do if out[k]==nil then out[k]=v end end
    for _,k in ipairs({'tickets','fragments','owned','serials','receipts','draws','history','presets'})do if type(out[k])~='table'then return nil,'invalid-commerce'end end
    for kind in pairs(Config.tickets)do
        if not integer(out.tickets[kind]or 0)or not integer(out.fragments[kind]or 0)then return nil,'invalid-commerce'end
        out.tickets[kind]=out.tickets[kind]or 0;out.fragments[kind]=out.fragments[kind]or 0
    end
    if not integer(out.drawSequence)or type(out.dailyClub)~='number'or out.dailyClub~=out.dailyClub or out.dailyClub%1~=0 or type(out.permanentWelcome)~='boolean'then return nil,'invalid-commerce'end
    if type(out.dailyFree)~='number'or out.dailyFree~=out.dailyFree or out.dailyFree%1~=0 then return nil,'invalid-commerce'end
    return out
end
function M.pool(kind,items)
    local ticket=Config.tickets[kind];if not ticket then return nil,'invalid-ticket'end
    local groups={};for _,r in ipairs(Config.rarityOrder)do groups[r]={}end
    local ids={}
    for _,item in ipairs(items or Catalog.items)do
        if item.ready==true and item.season==nil then
            if type(item.id)~='string'or ids[item.id]or not groups[item.rarity]or type(item.name)~='string'or type(item.loadout)~='table'then return nil,'invalid-catalog'end
            if next(item.loadout)==nil then return nil,'invalid-catalog'end
            for slot,style in pairs(item.loadout)do if not Styles.validSlot(slot)or not Styles.styles[style]or Styles.styles[style].access=='free'then return nil,'invalid-catalog'end end
            ids[item.id]=true;table.insert(groups[item.rarity],item)
        end
    end
    local result={};local total=0
    for _,rarity in ipairs(Config.rarityOrder)do if not ticket.rarity or ticket.rarity==rarity then
        if #groups[rarity]==0 then return nil,'collection-not-ready'end
        table.sort(groups[rarity],function(a,b)return a.id<b.id end)
        local groupWeight=ticket.rarity and 1000000 or Config.weights[rarity]
        for _,item in ipairs(groups[rarity])do local probability=groupWeight/1000000/#groups[rarity];total+=probability;table.insert(result,{item=item,probability=probability})end
    end end
    assert(math.abs(total-1)<1e-9,'Supply odds must sum to one')
    return result
end
function M.odds(kind,items)
    local pool,err=M.pool(kind,items);if not pool then return nil,err end
    local out={};for _,row in ipairs(pool)do table.insert(out,{id=row.item.id,name=row.item.name,rarity=row.item.rarity,category=row.item.category,percent=row.probability*100})end;return out
end
function M.draw(raw,kind,currency,requestId,entropy,medals,paidAllowed,now,items,sequence,actor)
    local c,err=M.decode(raw);if not c then return nil,err end
    if type(requestId)~='string'or #requestId<8 or #requestId>80 or not requestId:match('^[%w%-]+$')then return nil,'invalid-request'end
    if c.draws[requestId]then
        local prior=c.draws[requestId];if prior.kind~=kind or prior.currency~=currency or prior.sequence~=sequence then return nil,'invalid-request'end
        return c,copy(prior),medals
    end
    if not integer(sequence)or sequence~=c.drawSequence+1 then return nil,'stale-draw'end
    local pool,why=M.pool(kind,items);if not pool then return nil,why end
    if not integer(medals)or type(entropy)~='number'or entropy~=entropy or entropy<0 or entropy>=1 then return nil,'invalid-request'end
    if currency=='medals'then if kind~='basic'then return nil,'invalid-currency'end;if medals<Config.medalDrawCost then return nil,'insufficient-medals'end;medals-=Config.medalDrawCost
    elseif currency=='free'then if kind~='basic'then return nil,'invalid-currency'end;local day=math.floor(now/86400);if c.dailyFree>=day then return nil,'free-draw-used'end;c.dailyFree=day
    elseif currency=='ticket'then if paidAllowed~=true then return nil,'paid-random-restricted'end;if c.tickets[kind]<1 then return nil,'insufficient-tickets'end;c.tickets[kind]-=1
    else return nil,'invalid-currency'end
    local selected=pool[#pool].item;local sum=0;for _,row in ipairs(pool)do sum+=row.probability;if entropy<sum then selected=row.item;break end end
    local duplicate=c.owned[selected.id]==true;c.owned[selected.id]=true
    local result={requestId=requestId,id=selected.id,name=selected.name,rarity=selected.rarity,kind=kind,currency=currency,sequence=sequence,duplicate=duplicate,time=now};c.drawSequence=sequence
    if selected.rarity=='mythic'and actor then
        c.serials[selected.id]=c.serials[selected.id]or Reveal.serial(actor,sequence);result.serial=c.serials[selected.id]
    end
    if duplicate then
        if currency=='medals'or currency=='free'then result.medals=math.floor(Config.medalDrawCost*.2);medals+=result.medals
        else c.fragments[kind]+=1;result.fragments=1;if c.fragments[kind]>=5 then local n=math.floor(c.fragments[kind]/5);c.tickets[kind]+=n;c.fragments[kind]%=5;result.refundTickets=n end;result.fragmentCount=c.fragments[kind]end
    end
    c.draws[requestId]=result;table.insert(c.history,1,copy(result));while #c.history>30 do local old=table.remove(c.history);c.draws[old.requestId]=nil end
    return c,result,medals
end
function M.grant(raw,receiptId,kind,count)
    local c,err=M.decode(raw);if not c then return nil,err end
    if type(receiptId)~='string'or #receiptId<1 or #receiptId>100 or not Config.tickets[kind]or not integer(count)or count<1 or count>100 then return nil,'invalid-request'end
    if c.receipts[receiptId]then return c,'already-granted'end
    c.tickets[kind]+=count;c.receipts[receiptId]={kind=kind,count=count};return c
end
function M.welcome(raw)
    local c,err=M.decode(raw);if not c then return nil,err end
    if c.permanentWelcome then return c end
    for kind,n in pairs(Config.permanent.welcome)do c.tickets[kind]+=n end;c.permanentWelcome=true;return c
end
function M.daily(raw,subscribed,now)
    local c,err=M.decode(raw);if not c then return nil,err end
    local day=math.floor(now/86400)
    if subscribed~=true or c.dailyClub>=day then return c,0 end
    c.dailyClub=day;c.tickets.basic+=Config.clubDailyTickets;return c,Config.clubDailyTickets
end
function M.freeDrawAt(c)return c.dailyFree>=0 and (c.dailyFree+1)*86400 or 0 end
function M.ownedLoadout(raw,id,items)
    local item=Catalog.find(id,items);if not item or not raw or raw.owned[id]~=true then return nil end;return copy(item.loadout)
end
return M
