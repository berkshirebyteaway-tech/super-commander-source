local Core=game.ReplicatedStorage.FrontierNative.Core
local Schema=require(Core.TelemetrySchema)
local P={}
function P.code(v)
 if type(v)=='number'then v=tostring(v)end;if type(v)~='string'then return nil end
 local s=v:gsub('[^%w_]','_'):gsub('^[^%a]+','');s=s:sub(1,40)
 return Schema.code(s)
end
local function rarity(r)return Schema.enum('rarity',r,'other')end
local function keys(t)local out={};if type(t)=='table'then for k,v in pairs(t)do if v then out[k]=true end end end;return out end
local function count(t)local n=0;if type(t)=='table'then for _ in pairs(t)do n+=1 end end;return n end
local Career
local function unlocked(o)
 Career=Career or require(Core.CareerRules)
 local ok,titles,plates=pcall(function()local O=require(Core.OutgameRules);return Career.unlocked(o,O.level(o.xp))end)
 return ok and titles or {},ok and plates or {}
end
function P.outgame(log,player,before,after,sku)
 if not(log and player and type(before)=='table'and type(after)=='table')then return end
 local s0=type(before.season)=='table'and before.season or {};local s1=type(after.season)=='table'and after.season or {}
 if s1.id and (s1.id~=s0.id and (s1.tier or 0)>0 or s1.id==s0.id and (s1.tier or 0)>(s0.tier or 0))then
  log:flow(player,'season','tierUp',{item=P.code(s1.id),value=s1.tier,count=(s1.tier or 0)-(s1.id==s0.id and s0.tier or 0),result='granted'})
 end
 local r0=keys(before.seasonRewards);for id in pairs(keys(after.seasonRewards))do if not r0[id]then log:flow(player,'season','reward',{item=P.code(id),result='granted'})end end
 local a0=keys(before.achievements)
 for key in pairs(keys(after.achievements))do if not a0[key]then
  local kind,id=tostring(key):match('^(%a+):(.+)$')
  log:flow(player,'goals',kind=='a'and 'achievement'or kind=='win'and 'firstWinMode'or kind=='map'and 'firstWinMap'or 'badge',{item=P.code(id or key),result='granted'})
 end end
 local rc0=type(before.receipts)=='table'and before.receipts or {}
 for key,r in pairs(type(after.receipts)=='table'and after.receipts or {})do if type(r)=='table'and type(r.parts)=='table'then
  local old=type(rc0[key])=='table'and type(rc0[key].parts)=='table'and rc0[key].parts or {}
  for kind,e in pairs(r.parts)do local o=old[kind]or {x=0,m=0};local dx,dm=(e.x or 0)-(o.x or 0),(e.m or 0)-(o.m or 0)
   if dx>0 or dm>0 then log:flow(player,'goals','grant',{item=P.code(kind),value=dx,amount=dm,result='granted'})end
  end
 end end
 local g0=type(before.goalClaims)=='table'and before.goalClaims or {};local g1=type(after.goalClaims)=='table'and after.goalClaims or {}
 local waiting=count(g1);local seen=log.claimSeen;if not seen then seen=setmetatable({},{__mode='k'});log.claimSeen=seen end;seen[player]=seen[player]or {}
 for key,c in pairs(g1)do if not g0[key]then seen[player][key]=os.time();log:flow(player,'goals','claimReady',{item=P.code(type(c)=='table'and c.source)or 'other',value=type(c)=='table'and tonumber(c.medals)or 0,total=waiting,result='pending'})end end
 for key,c in pairs(g0)do if not g1[key]then local at=seen[player][key];seen[player][key]=nil
  log:flow(player,'goals','claimed',{item=P.code(type(c)=='table'and c.source)or 'other',value=at and os.time()-at or nil,total=waiting,result='granted'})end end
 if (after.xp or 0)~=(before.xp or 0)or count(after.seasonRewards)~=count(before.seasonRewards)or count(after.mastery)~=count(before.mastery)
  or (after.comradeDays and after.comradeDays.count)~=(before.comradeDays and before.comradeDays.count)or (after.dailyOp and after.dailyOp.days)~=(before.dailyOp and before.dailyOp.days)then
  local t0,p0=unlocked(before);local t1,p1=unlocked(after)
  for id in pairs(t1)do if not t0[id]then log:flow(player,'progression','titleUnlock',{item=P.code(id),result='granted'})end end
  for id in pairs(p1)do if not p0[id]then log:flow(player,'progression','plateUnlock',{item=P.code(id),result='granted'})end end
 end
 local st0={};for _,id in ipairs(type(before.sets)=='table'and before.sets or {})do st0[id]=true end;local st1=type(after.sets)=='table'and after.sets or {}
 for _,id in ipairs(st1)do if not st0[id]then log:flow(player,'progression','setComplete',{item=P.code(id),total=#st1,result='granted'})end end
 local e0=type(before.equipped)=='table'and before.equipped or {};local e1=type(after.equipped)=='table'and after.equipped or {}
 if e1.title~=e0.title then log:flow(player,'progression','titleEquip',{item=P.code(e1.title)or 'rankName',result='ok'})end
 if e1.plate~=e0.plate then log:flow(player,'progression','plateEquip',{item=P.code(e1.plate)or 'none',result='ok'})end
 local o0=keys(before.ownedSlots)
 for key in pairs(keys(after.ownedSlots))do if not o0[key]then log:flow(player,'cosmetics','unlock',{item=P.code(tostring(key):match(':(.+)$')or key),sku=Schema.enum('sku',sku,'other'),result='granted'})end end
 local c0=before.comradeDays and before.comradeDays.count or 0;local c1=after.comradeDays and after.comradeDays.count or 0
 if c1>c0 then log:flow(player,'social','comradeDay',{value=c1,result='granted'})end
 local d0=before.dailyOp and before.dailyOp.days or 0;local d1=after.dailyOp and after.dailyOp.days or 0
 if d1>d0 then log:flow(player,'goals','dailyOpDay',{value=d1,result='granted'})end
end
function P.draw(log,player,value,result)
 if not(log and player and type(result)=='table')then return end
 local kind=Schema.enum('sku',type(value)=='table'and value.kind,'other');local r=rarity(result.rarity)
 local currency=result.currency=='medals'and 'Medals'or Schema.enum('currency',kind,'none')
 log:flow(player,'gacha','draw',{sku=kind,currency=currency,item=P.code(result.id),rarity=r,first_use=result.duplicate~=true,result='granted'})
 if result.currency=='ticket'then log:flow(player,'gacha','ticketSpend',{sku=kind,currency=currency,value=1,result='ok'});if log.benefit then log:benefit(player,kind,'draw')end end
 local paid=type(value)=='table'and value.currency;if paid=='free'or paid=='medals'then log:flow(player,'gacha',paid=='free'and 'freeDraw'or 'coinDraw',{sku=kind,rarity=r,result='granted'})end
 if result.duplicate then
  if result.medals then log:flow(player,'gacha','dupRefundCoins',{sku=kind,item=P.code(result.id),rarity=r,value=result.medals,result='granted'})end
  if result.fragments then log:flow(player,'gacha','shard',{sku=kind,item=P.code(result.id),rarity=r,value=result.fragmentCount or 0,result='granted'})end
  if result.refundTickets then log:flow(player,'gacha','shardTicket',{sku=kind,value=result.refundTickets,result='granted'})end
 else log:flow(player,'gacha','newSkin',{sku=kind,item=P.code(result.id),rarity=r,result='granted'})end
 if result.serial then log:flow(player,'gacha','mythicSerial',{sku=kind,item=P.code(result.id),rarity='mythic',result='granted'})end
end
function P.wallet(c)
 if type(c)~='table'then return nil end
 local t,f=0,0;for _,n in pairs(type(c.tickets)=='table'and c.tickets or {})do t+=tonumber(n)or 0 end
 for _,n in pairs(type(c.fragments)=='table'and c.fragments or {})do f+=tonumber(n)or 0 end
 return {tickets=t,fragments=f}
end
function P.commerce(log,player,before,after,transaction,sku)
 local a=P.wallet(after);if not(log and player and before and a)then return end
 if a.tickets~=before.tickets then log:economy(player,a.tickets-before.tickets,a.tickets,transaction or 'Gameplay',sku or 'supply','Tickets')end
 if a.fragments~=before.fragments then log:economy(player,a.fragments-before.fragments,a.fragments,transaction or 'Gameplay',sku or 'supply','Shards')end
end
function P.safe(fn,...)local ok,err=pcall(fn,...);if not ok then warn('TelemetryProgress',err)end end
return P
