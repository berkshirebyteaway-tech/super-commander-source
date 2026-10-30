local Players=game:GetService("Players");Players.CharacterAutoLoads=false
local bootAt=os.clock()
local Run=game:GetService("RunService")
local pack=game.ReplicatedStorage:WaitForChild("FrontierNative")
local services=game.ServerScriptService:WaitForChild("FrontierServices")
local characters=require(services.CharacterLoader).new()
local Session=require(pack.Core.MultiplayerSession)
local RoomSnapshotContext=require(pack.Core.RoomSnapshotContext)
local Single=require(pack.Core.SkirmishSession)
local Lobby=require(pack.Core.LobbyModel)
local Maps=require(pack.Maps.MapLoader)
local Terrain=require(pack.Core.Terrain)
local AttackPresentation=require(pack.Core.AttackPresentation)
local Geometry=require(pack.Core.WorldGeometry)
local StateDelta=require(pack.Core.StateDelta);local PerfStats=require(pack.Core.PerfStats)
local Plaza=require(services.DeskPlaza)
local PlazaLayout=require(pack.Core.PlazaLayout)
local Cosmetics=require(pack.Core.CosmeticCatalog)
local Config=require(services.MultiplayerConfig)
local DropService=require(services.SpawnDropService)
local analytics=require(services.ExperienceAnalytics).new()
DropService.telemetry=analytics
local CommandGate=require(pack.Core.CommandGate)
local CommanderScale=require(pack.Core.CommanderScale)
local careers=require(services.CareerService).new()
local function remote(class,name)local r=Instance.new(class);r.Name=name;r.Parent=pack;return r end
local command=remote("RemoteEvent","Command");local updates=remote("RemoteEvent","State");local results=remote("RemoteEvent","Result")
local experienceReady=remote('RemoteEvent','ExperienceReady')
local read=remote("RemoteFunction","Read");local preview=remote("RemoteFunction","Preview");local visual=remote("RemoteEvent","VisualEvent")
local equip=remote("RemoteFunction","EquipCosmetic");local lobbyRequest=remote("RemoteFunction","LobbyRequest");local lobbyState=remote("RemoteEvent","LobbyState")
local entries,rooms,parties,invites={}, {},{},{}
experienceReady.OnServerEvent:Connect(function(p,version)
    local e=entries[p.UserId]
    if e and e.version==version and not e.room and not e.loading and not e.arriving and analytics.sessions[p]and os.clock()-(e.lastExperienceReady or -1e9)>=1 then
        e.lastExperienceReady=os.clock();analytics:mark(p,'LobbyReady');experienceReady:FireClient(p,version)
    end
end)
local matchChat=require(services.MatchChat).new(entries)
matchChat.telemetry=analytics
matchChat.deliveryRemote=remote('RemoteEvent','CommsDelivery')
local soloTransfer
local commsPrepare=remote('RemoteFunction','CommsPrepare')
commsPrepare.OnServerInvoke=function(p,kind,payload)
    local e=entries[p.UserId];if not e then return {ok=false}end
    local r=matchChat:prepare(e,kind,payload)
    local scope=type(payload)=='table'and type(payload.value)=='table'and payload.value.scope or kind=='emoji'and type(payload)=='table'and payload.target==0 and 'all'or 'unknown'
    analytics:communication(p,kind,scope,r.ok and r.npc and 'accepted'or 'ready',r.ok==true)
    return r
end
local queue=require(services.MatchQueue).new();local serial,visualId,preparing=0,0,0
analytics.resolveField=function(p,id)for _,f in ipairs(queue:directory(p.UserId).fields or {})do if f.id==id then return f end end end
queue.telemetry=analytics
local bigMaps=require(services.MapStream).new(remote("RemoteEvent","MapStream"),Maps,require(services.MapStore).new(Maps,{GetAsync=function(_,key)
    return game:GetService('DataStoreService'):GetDataStore(require(services.MapStore).name):GetAsync(key)end}):attach())
bigMaps.roster=require(services.WaitingRoster).new(remote("RemoteEvent","WaitingRoster"))
bigMaps.log=function(p,step,data)analytics:flow(p,'match',step,data)end
analytics.resolveParty=function(p)return parties[p.UserId]end
local LiveModel=require(pack.Core.LiveMatchModel)
local liveMatches=require(services.LiveMatches).new(Config,{notify=function(id,message)local e=entries[id];if e and e.player.Parent==Players then results:FireClient(e.player,{action='lobby',ok=false,message=message,version=e.version})end end})
local worldField=require(services.WorldField).new(Config,{notify=function(id,message)local e=entries[id];if e and e.player.Parent==Players then e.arriving=nil;results:FireClient(e.player,{action='lobby',ok=false,message=message,version=e.version})end end})
worldField.telemetry=analytics
local Presets=require(pack.Core.SinglePresets)
local QuickSolo=require(pack.Core.QuickSolo)
local defaults=Presets.standard
local Outgame=require(pack.Core.OutgameRules)
local BadgeRules=require(pack.Core.BadgeRules)
local badgeSent={}
local function awardBadges(player,view)
    if not require(services.LiveConfig).enabled('badges')then return end
    local sent=badgeSent[player.UserId]or {};badgeSent[player.UserId]=sent
    local fresh={}
    for _,key in ipairs(BadgeRules.earned(view))do if (sent[key]==nil or sent[key]~=true and os.clock()>=sent[key])and BadgeRules.ids[key]then sent[key]=true;table.insert(fresh,key)end end
    if #fresh==0 then return end
    task.spawn(function()
        local Badges=game:GetService('BadgeService');local owned={}
        for i=1,#fresh,10 do
            local ids={};for j=i,math.min(#fresh,i+9)do table.insert(ids,BadgeRules.ids[fresh[j]])end
            local ok,list=pcall(function()return Badges:CheckUserBadgesAsync(player.UserId,ids)end)
            if ok and type(list)=='table'then for _,id in ipairs(list)do owned[id]=true end end
        end
        for _,key in ipairs(fresh)do
            if not owned[BadgeRules.ids[key]]then
                local ok=pcall(function()Badges:AwardBadge(player.UserId,BadgeRules.ids[key])end);if not ok then sent[key]=os.clock()+60 end
            end
        end
    end)
end
local Participation=require(pack.Core.Participation)
local ResultPresentation=require(pack.Core.ResultPresentation)
local FirstPlay=require(pack.Core.FirstPlay)
local Replay=require(pack.Core.RoomReplay)
local SpawnRules=require(pack.Core.SpawnRules)
local TeamFormat=require(pack.Core.TeamFormat)
local MatchOptions=require(pack.Core.MatchOptions)
local GameSpeed=require(pack.Core.GameSpeed)
local RoomCommands=require(pack.Core.RoomCommands)
local ReplayLog=require(pack.Core.ReplayLog)
local replayStore=require(services.ReplayStore).new()
local accounts=require(services.AccountService).new(function(p,a)
    p:SetAttribute("FrontierStyle",a.cosmetics.commanderOrder)
    if a.ready and a.progress then awardBadges(p,a.progress)end
    local e=entries[p.UserId];if e and a.ready and a.progress and not e.settingsTouched and not e.room then
        e.settings=Outgame.copy(a.progress.single.settings);e.singleMap=a.progress.single.map;e.selectedMode=a.progress.lastMode
        updates:FireClient(p,{phase='menu',version=e.version,settings=e.settings,selectedMap=e.singleMap,controller=p.UserId,loading=false,paused=false})
    end
end)
local ranked=require(services.RankedService).new(careers,accounts,Config)
accounts.rankedOf=function(id)if not careers.profiles[id]or not ranked:allowed()then return nil end;local out={};for _,l in ipairs(require(pack.Core.RankedRules).ladders)do out[l]=ranked:ladderView(id,l)end;return out end
local rewards=require(services.RewardInbox).new(accounts)
analytics:watchInbox('RewardInbox',rewards.worker);analytics:watchInbox('CareerInbox',careers.worker)
local function recordProgress(id,progress)
    if progress.unrecorded then return end
    local e,party=entries[id],parties[id]
    if not progress.party and party and #party.users>1 and e and e.room then
        for _,u in ipairs(party.users)do if u~=id and e.room.members[u]then progress.party=true;break end end
    end
    local mult=progress.benefitXPMultiplier or 1
    pcall(function()local pl=Players:GetPlayerByUserId(id);local a=pl and accounts.accounts[pl];if a and a.ready then mult=math.max(mult,accounts.billing:benefits(a).xpMultiplier or 1)end end)
    local event=progress:event(os.time());event.benefitXPMultiplier=mult;if progress.voided then event.voided=true end
    rewards:record(id,event)
    if progress.ended and e then analytics:observe(e.player,progress,progress.map,progress.mode)end
end
local shuttingDown=false
local function nextVersion()serial+=1;return serial end
local function finite(n)return type(n)=="number" and n==n and math.abs(n)<math.huge end
local function user(id)return Players:GetPlayerByUserId(id)end
local function between(e,worldPreparing)if e and not worldPreparing and worldField:pending(e.player.UserId)then return false end;local r=e and e.room;if not r then return true end;local pr=r.progress and r.progress[e.player.UserId];return r.practice==true or r.endedAt~=nil or pr~=nil and pr.ended==true end
local function partyEntry(p,party)
    if #party.users>1 and party.leader~=p.UserId then return nil,'파티장이 골라요'end
    local ids={p.UserId};for _,uid in ipairs(party.users)do if uid~=p.UserId then table.insert(ids,uid)end end
    for _,uid in ipairs(ids)do local member=entries[uid]
        if not member or not user(uid)or not between(member)or member.loading or member.arriving then return nil,'파티원 경기 중'end
    end
    return ids
end
local function queued(ids,mode)for _,uid in ipairs(ids)do local e=entries[uid];if e then e.queuedAt=os.clock();analytics:queued(e.player,mode,#ids)end end end
local function waited(uid,name,map,mode)
    local e=entries[uid];if not e or not e.queuedAt then return end
    local seconds=math.floor(os.clock()-e.queuedAt);e.queuedAt=nil;analytics:custom(e.player,name,map,mode,seconds)
end
local function group(id)return parties[id] or {leader=id,users={id},ready={},mode='coop'}end
local function queueJoinGuard(ids)
    local leader=user(ids[1]);if not leader then return nil end
    local expected=partyEntry(leader,group(ids[1]));if not expected or #expected~=#ids then return nil end
    local saved={}
    for i,id in ipairs(ids)do
        if expected[i]~=id then return nil end
        local e=entries[id];saved[id]={entry=e,player=e.player,version=e.version,room=e.room,party=parties[id]}
    end
    return function()
        for id,v in pairs(saved)do local e=entries[id]
            if e~=v.entry or user(id)~=v.player or e.version~=v.version or e.room~=v.room
                or e.loading or e.arriving or parties[id]~=v.party or not between(e)then return false end
        end
        local current=partyEntry(leader,group(ids[1]));if not current or #current~=#ids then return false end
        for i,id in ipairs(ids)do if current[i]~=id then return false end end
        return true
    end
end

function worldField:guard(players)
    local lead=players[1];if not lead then return nil end
    local party=group(lead.UserId);if party.leader~=lead.UserId or #party.users~=#players then return nil end
    local saved={}
    for _,p in ipairs(players)do local e=entries[p.UserId]
        if not e or user(p.UserId)~=p or not between(e)or e.loading or e.arriving or not table.find(party.users,p.UserId)then return nil end
        table.insert(saved,{id=p.UserId,player=p,entry=e,version=e.version,room=e.room,party=parties[p.UserId]})
    end
    return function(allowQueued)
        local current=group(lead.UserId)
        if current.leader~=lead.UserId or #current.users~=#saved then return false end
        for _,v in ipairs(saved)do local e=entries[v.id]
            if e~=v.entry or user(v.id)~=v.player or e.version~=v.version or e.room~=v.room
                or e.loading or e.arriving or not between(e,true)or parties[v.id]~=v.party
                or (not allowQueued and queue.membership[v.id])or not table.find(current.users,v.id)then return false end
        end
        return true
    end
end
local function queueRecoveryGuard(id)
    local e=entries[id];local p=user(id);local party=parties[id]
    if not e or not p or #group(id).users~=1 or not between(e)or e.loading then return nil end
    local version,room=e.version,e.room
    return function()
        return entries[id]==e and user(id)==p and e.version==version and e.room==room
            and parties[id]==party and #group(id).users==1 and not e.loading and between(e)
    end
end
local function participants(room,fn)for id in pairs(room.members)do local p=user(id);if p and entries[id] and entries[id].room==room then fn(p,entries[id])end end end
local function observers(room,fn)for id in pairs(room.observers or {})do local p=user(id);local e=entries[id];if p and e and e.room==room and e.observer then fn(p,e)end end end
local function validTile(s,t)return finite(t) and t%1==0 and t>=0 and t<s.map.meta.width*s.map.meta.height end
local function baseState(e)return {phase="menu",version=e.version,settings=e.settings,selectedMap=e.singleMap or 'world',loadingMap=e.loadingMap,loadingCampaign=e.loadingCampaign,controller=e.player.UserId,loading=e.loading==true or e.arriving==true,paused=false}end
local function observerSnapshot(e,full,shared,context)
    local room=e.room;local session=room.session
    e.watch=LiveModel.pick(session,e.watch)
    local s=session:observerState(e.watch,full,shared,context)
    if full then if session.map.packed then bigMaps:pack(e,s,session.map)else s.mapTerrain=session.map.terrain end end
    local a=accounts:sessionView(e.player,false);s.cosmetics=a.cosmetics or Cosmetics.loadout("classic");s.style=s.cosmetics.territory
    s.version=e.version;s.controller=e.player.UserId;s.player.userId=e.player.UserId;s.paused=room.paused==true;s.canPause=false;s.studio=Run:IsStudio()
    s.multiplayer=true;s.roomId=room.id;s.mode=room.mode;s.queueMode=room.queueMode;s.loading=false;s.attackTargets={}
    s.observer.count=room.observerCount or 0;if s.observer.ended then s.observer.ended=LiveModel.ended(session)end
    if room.replay then s.observer.replay={speed=room.replay.speed,tick=session.sim.ticks,endTick=room.replay.endTick}end
    return s
end
local function snapshot(e,full,shared,context)
    e.snapshotSerial=(e.snapshotSerial or 0)+1;local serial=e.snapshotSerial
    local room=e.room;if not room then local s=baseState(e);s.snapshotSerial=serial;return s end
    if e.observer then local s=observerSnapshot(e,full,shared,context);s.snapshotSerial=serial;return s end
    local s=room.single and room.session:state(full) or room.session:stateFor(e.faction,full,shared,context)
    if full then if room.session.map.packed then bigMaps:pack(e,s,room.session.map)else s.mapTerrain=room.session.map.terrain end end
    local progress=room.progress and room.progress[e.player.UserId]
    local a=accounts:sessionView(e.player,progress and progress.ended);s.cosmetics=a.cosmetics or Cosmetics.loadout("classic");s.style=s.cosmetics.territory
    s.version=e.version;s.controller=e.player.UserId;s.player.userId=e.player.UserId;s.paused=room.paused==true;s.speed=room.single and (room.speed or 1)or nil;s.canPause=room.single or room.hostUserId==e.player.UserId;s.studio=Run:IsStudio()
    s.multiplayer=not room.single;s.roomId=room.id;s.mode=room.mode;s.queueMode=room.queueMode;s.customRules=room.customRules;s.note=room.note;s.loading=false
    s.unrecorded=room.unrecorded==true;s.watchers=room.observerCount;s.ranked=room.ranked;s.clanwar=room.clanwar and {size=room.clanwar.size or 2,count=room.clanwar.count or 2}or nil
    s.casual=room.casual or nil;s.intro=room.intro or nil;s.awaitFirst=room.awaitFirst or nil;s.campaign=room.campaign
    s.spawnRemaining=math.max(0,math.ceil((room.spawnUntil or 0)-os.clock()));s.spawnLeft=math.max(0,(room.spawnUntil or 0)-os.clock())
    s.allSpawned=room.allSpawned or nil;s.randomSpawn=room.randomSpawn or nil;s.nextRoundIn=room.endedAt and math.max(0,math.ceil(room.endedAt+Config.resultSeconds-os.clock()))or nil
    s.drop=room.drop and room.session.phase=='spawn'and room.drop.players[e.faction]and room.drop.players[e.faction].userId==e.player.UserId and room.drop:snapshot(e.faction,os.clock())or nil
    local guide=room.guides and room.guides[e.player.UserId]
    if guide then s.guide=guide:view(room.session,e.faction,room.intro)end
    if progress then local xp,medals=Outgame.reward(progress.mode,progress.seconds,progress.outcome)
        if progress.party then xp=math.floor(xp*Outgame.partyBonus+1e-8)end
        if progress.unrecorded then xp=0;medals=0 end
        local pending=rewards.pending[e.player.UserId]and rewards.pending[e.player.UserId][progress.id]~=nil or false
        local account=accounts.accounts[e.player]
        local receipt=account and account.profile and account.profile.outgame.receipts[progress.id]
        s.personalResult={id=progress.id,map=progress.map,mode=progress.mode,seconds=math.floor(progress.seconds),peak=progress.peak,cities=progress.cities,supports=progress.supports,xp=xp,medals=medals,outcome=progress.outcome,pending=pending,final=progress.final==true,unrecorded=progress.unrecorded==true,
            recordStatus=ResultPresentation.recordState(progress,receipt,pending,a.ready,accounts.localMode),
            priorPeak=progress.start and progress.start.peaks and (progress.start.peaks[progress.map]or 0)or nil}
        do local t=progress.tactics or {};local built=0;for _,n in pairs(t.built or {})do built+=n end
            local r=s.personalResult;r.place=progress.place;r.field=progress.total;r.conquered=t.countriesConquered or 0;r.troopsSent=t.troopsSent or 0;r.built=built;r.nukes=t.nukes or 0 end
        if progress.ended and progress.outcome=='won'and not progress.unrecorded and receipt and account then s.personalResult.invite=Outgame.career.inviteAsk(account.profile.outgame,receipt)end
        if receipt and receipt.totalsComplete then s.personalResult.bonus={xp=math.max(0,receipt.grantedXP-receipt.xp),medals=math.max(0,receipt.grantedMedals-receipt.medals),parts=ResultPresentation.bonusParts(receipt)};s.personalResult.granted={xp=receipt.grantedXP,medals=receipt.grantedMedals}end
        if progress.daily then local D=Outgame.dailyOperation;local score=D.score(progress);local d=a.progress and a.progress.dailyOp;local top=math.max(score or -1,d and d.day==progress.daily and d.best or -1)
            s.personalResult.daily={score=D.label(score),best=D.label(top>=0 and top or nil),paid=receipt and receipt.daily==true and type(receipt.parts)=='table'and receipt.parts.dailyOp~=nil and D.medals or nil}end
        if progress.official and a.progress and a.progress.dailySupply then local v=a.progress.dailySupply
            s.personalResult.supply={n=v.n,steps=v.steps,step=receipt and receipt.supply or nil}end
        if progress.campaign then local C=Outgame.campaign;local stage=C.stage(progress.campaign);local saved=a.progress and a.progress.campaign
            local mask=C.stars(stage,progress);local best=bit32.bor(mask,saved and saved.stars and saved.stars[stage.id]or 0)
            local nxt=Replay.campaignNext(room,e.player.UserId,saved)
            s.personalResult.campaign={id=stage.id,name=stage.name,stars=mask,best=best,task=stage.task.label,taskValue=C.taskValue(stage,progress),taskDone=C.taskDone(stage,progress),
                taskLeft=stage.task.kind=='share'and math.max(0,C.shareWindow-(progress.spawnedAt and os.time()-progress.spawnedAt or 0))or nil,next=nxt~=stage.id and nxt or nil}
            if progress.ended then pcall(analytics.flowOnce,analytics,e.player,'campaign:'..tostring(progress.id),'campaign','campaignEnd',{item='stage_'..stage.id:gsub('%-','_'),value=C.count(mask),level=C.count(best),result=progress.outcome=='won'and 'won'or 'lost',map_key=progress.map,active=s.personalResult.campaign.taskDone==true})end
        end
        if progress.ended and a.ready and not progress.unrecorded then
            local view=a.progress
            awardBadges(e.player,view)
            s.personalResult.progression={level=view.level,currentXP=view.currentXP,nextXP=view.nextXP,startLevel=progress.startLevel,conquest=view.conquest[progress.map],career={goals=view.career.goals,next=view.career.next},daily=view.daily,weekly=view.weekly,mastery=view.mastery[progress.map],
                login=room.intro and view.login and {nextReward=view.login.nextReward}or nil,campaignNext=room.intro and view.campaign and view.campaign.next or nil}
            local b=progress.start;if b then local _,cur,nxt=Outgame.level(b.xp);local pr=s.personalResult.progression;pr.startXP=b.xp;pr.startCurrentXP=cur;pr.startNextXP=nxt;pr.unlocks=ResultPresentation.unlocks(b,view)end
        end
        if progress.ended then s.personalResult.recap=progress.recap:view()end
        if progress.ended and room.trophySolo then
            local c=careers.profiles[e.player.UserId];local last=c and c.lastTrophySolo
            if last and last.id==room.id then
                s.personalResult.trophySolo=ranked:trophyScoreView(e.player.UserId)
                s.personalResult.trophySolo.before=last.before;s.personalResult.trophySolo.delta=last.delta
            else s.personalResult.trophySolo={pending=true}end
        elseif progress.ended and room.ranked and not room.clanwar then
            local c=careers.profiles[e.player.UserId];local l=c and c.lastRanked
            if l and l.id==room.id then local v=require(pack.Core.RankedRules).view(c.ranked,l.ladder,os.time())
                s.personalResult.ranked={ladder=l.ladder,delta=l.delta,rp=l.rp,won=l.won,tier=v.tier,tierName=v.tierName,division=v.division,placing=v.placing,placementLeft=v.placementLeft}
            else s.personalResult.ranked={ladder=room.ranked,pending=true}end
        elseif progress.ended and room.clanwar then
            local W=require(pack.Core.ClanWarRules);local won=progress.outcome=='won'
            s.personalResult.clanwar={won=won,points=won and W.winFor(room.clanwar.count or 2,room.clanwar.size or 2)or W.lossPoints,contribution=won and W.winContribution or W.lossContribution}
        end
    end
    if room.single then for _,f in ipairs(s.factions or {})do if f.id==1 then f.userId=e.player.UserId end end end
    s.attackTargets={}
    if s.phase=='playing'then
        local sim=room.session.sim;local owners,tb,w,last=sim.owners,sim.tb,sim.width,(sim.height-1)*sim.width;local me,checked=e.faction,{}
        local function consider(n)
            local target=owners[n+1];if target==me or checked[target]then return end
            local b=if tb then buffer.readu8(tb,n)else sim.terrain[n+1]
            if not Terrain.isLand(b)or Terrain.isImpassable(b)then return end
            checked[target]=true
            if not room.session:friendly(me,target)and not room.session:protectedTarget(me,target)then
                s.attackTargets[tostring(room.single and target or Session.viewId(target,me))]=true
            end
        end
        for _,t in ipairs(sim.players[me].border.dense)do if t~=false then
            local x=t%w
            if t>=w then consider(t-w)end;if t<last then consider(t+w)end;if x~=0 then consider(t-1)end;if x~=w-1 then consider(t+1)end
        end end
    end
    s.snapshotSerial=serial;return s
end
local function sendRoom(room,full)
    local started=os.clock()
    local shared=not room.single and room.session:state(full)or nil
    local context=shared and RoomSnapshotContext.new(room.session)or nil
    participants(room,function(p,e)
        local s=snapshot(e,full,shared,context);e.stateStream=e.stateStream or {};StateDelta.encode(e.stateStream,s,full,e.faction,context and context.encoding);updates:FireClient(p,s)
        local f=p:FindFirstChild("leaderstats");if f then f["점유율"].Value=math.floor(s.player.share*10000)/100;f["병력"].Value=math.floor(s.player.troops/10);f["골드"].Value=tonumber(s.player.gold)or 0 end
    end)
    room.observerFlip=not room.observerFlip
    if full or room.observerFlip then observers(room,function(p,e)e.stateStream=e.stateStream or {};updates:FireClient(p,StateDelta.encode(e.stateStream,snapshot(e,full,shared,context),full,'watch:'..tostring(e.watch),context and context.encoding))end)end
    room.session:ackOwnership()
    PerfStats.add(room,'send',os.clock()-started)
end
local function pushOwnership(room)
    local s=room.session;if s.ownershipRevision<=s.baseRevision then return end
    participants(room,function(p,e)
        updates:FireClient(p,StateDelta.ownershipPacket(s,e.version,e.faction,not room.single and Session.viewId or nil))
    end)
    observers(room,function(p,e)
        updates:FireClient(p,StateDelta.ownershipPacket(s,e.version,e.watch,Session.viewId))
    end)
    s:ackOwnership()
end
local function lobbySnapshot(id)
    local e=entries[id];local roster={};for other,v in pairs(entries)do if v.player.Parent==Players then table.insert(roster,{userId=other,name=v.player.DisplayName,busy=v.room~=nil})end end
    if e then analytics:queueState(e.player,queue:status(id,os.clock()))end
    table.sort(roster,function(a,b)return a.userId<b.userId end)
    local received={};for from,t in pairs(invites[id]or {})do if t>os.clock() and user(from)then table.insert(received,{from=from,name=user(from).DisplayName})end end
    return {serial=os.clock(),queue=queue:status(id,os.clock()),battlefields=queue:directory(id),recentCustom=e and e.recentCustom,inviteRoomCode=e and e.inviteRoomCode,partyHost=e and e.partyHost,partyWait=e and e.partyHost and e.partyFriend and (function()local h=entries[e.partyHost];local hp=user(e.partyHost)
        return {host=e.partyHost,name=hp and hp.DisplayName or nil,reason=not hp and 'notHere'or h and h.room and not h.room.practice and 'inMatch'or queue.membership[e.partyHost]and 'queued'or 'joining'}end)()or nil,privateServer=game.PrivateServerId~=''or nil,career=careers:snapshot(id),ranked=ranked:view(id),clanWar=ranked:clanWarBoard(id),party=group(id),partyStatus=(function()local out={};for _,u in ipairs(group(id).users)do local m=entries[u];local g=group(id)
        out[tostring(u)]=not m and 'away'or m.loading and 'loading'or m.room and not m.room.practice and (between(m)and 'results'or 'match')or queue.membership[u]and 'queued'or g.ready and g.ready[u]and 'ready'or 'hq'end;return out end)(),players=roster,invites=received,sent=(function()local out={};for to,offers in pairs(invites)do if offers[id]and offers[id]>os.clock()then table.insert(out,to)end end;return out end)(),live=liveMatches:list(rooms),rejoin=e and not e.room and liveMatches:mine(rooms,id)or nil,rankedEnabled=Config.rankedEnabled,localMode=careers.localMode,inMatch=e and e.room~=nil,practice=e and e.room and e.room.practice==true,roomCount=#rooms,world=worldField.lobbyView()}
end
local function pushLobby()for id,e in pairs(entries)do if e.player.Parent==Players and between(e)then lobbyState:FireClient(e.player,lobbySnapshot(id))end end end
local function joinFriend(id)
    local e=entries[id];local host=e and e.partyHost;if not host or not e.partyFriend then return end
    if os.clock()>(e.partyHostUntil or 0)then
        e.partyHost=nil;local p=user(id)
        if p then results:FireClient(p,{action='lobby',ok=false,message='다른 서버  친구 목록에서 따라가기',version=e.version})end
        pushLobby();return
    end
    local p,h=user(id),entries[host];if not p or not h or not user(host)then return end
    if e.partyFriend=='hop'and h.hopId~=e.hopId then return end
    if not e.partyHostTold and (h.room and not h.room.practice or queue.membership[host])then
        e.partyHostTold=true;results:FireClient(h.player,{action='lobby',ok=true,message=string.format('%s님이 로비에서 기다려요. 경기가 끝나면 같은 파티가 돼요',p.DisplayName),version=h.version})
    end
    if e.room or e.loading or e.arriving or h.room or h.loading or worldField:pending(id)or worldField:pending(host)or queue.membership[id]or queue.membership[host]then return end
    local target=group(host);e.partyHost=nil
    if parties[id]or #target.users>=5 or table.find(target.users,id)then pushLobby();return end
    parties[host]=target;table.insert(target.users,id);target.ready=target.ready or {};target.ready[id]=true;target.mode='pvp';for _,u in ipairs(target.users)do parties[u]=target end
    if invites[id]then invites[id][host]=nil end
    for _,u in ipairs(target.users)do local pl,en=user(u),entries[u]
        if pl and en then results:FireClient(pl,{action='lobby',ok=true,message=(u==id and user(host).DisplayName or p.DisplayName)..'님과 같은 파티가 됐어요',version=en.version})end
    end
    pushLobby()
end
local function placeCharacter(p,tile,room)
    local c=p.Character;local r=c and c:FindFirstChild("HumanoidRootPart");if not r then return end
    if not room and c:GetAttribute('ToyfrontBaseScale')then if c:GetScale()~=c:GetAttribute('ToyfrontBaseScale')then c:ScaleTo(c:GetAttribute('ToyfrontBaseScale'))end;c:SetAttribute('ToyfrontGrowth',1);c:SetAttribute('ToyfrontGrowthStep',0)end
    local x,y,z=0,Geometry.surfaceY,0
    if room and tile then x,y,z=Geometry.toWorld(tile,room.session.map.meta.width,room.session.map.meta.height)end
    c:PivotTo(room and CFrame.new(x,y+4,z)or Plaza.spawn(p.UserId,c));r.AssemblyLinearVelocity=Vector3.zero;r.Anchored=room==nil
    local hum=c:FindFirstChildOfClass("Humanoid");if hum then hum.WalkSpeed=room and 34 or PlazaLayout.walkSpeed;hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,room==nil)end
end
local function emit(room,p,kind,tile)
    visualId+=1;local a=accounts:snapshot(p);local loadout=a.cosmetics or Cosmetics.loadout("classic");local position
    if tile then position={Geometry.toWorld(tile,room.session.map.meta.width,room.session.map.meta.height)}end
    local packet={schema=1,id=visualId,roomId=room.id,playerId=p.UserId,kind=kind,style=loadout.commanderOrder,position=position,cosmetics=loadout}
    participants(room,function(recipient)visual:FireClient(recipient,packet)end);observers(room,function(recipient)visual:FireClient(recipient,packet)end)
end
DropService.bind(pack,entries,function(room,p,_,tile)emit(room,p,'settle',tile)end)
local Casual={seats=require(pack.Core.WorldFieldRules).seats,minutes=20,maps={'world'},next=1,winSeconds=300,warmTicks=600}
local joinCasual,warmCasual
local function release(e,forfeit)
    local room=e.room;if not room then return end
    local progress=room.progress and room.progress[e.player.UserId]
    local wasOut=progress and progress.ended
    if progress and forfeit and not progress.ended then if room.intro then progress.basicsComplete=true end;progress:finish('forfeit',os.time(),true);recordProgress(e.player.UserId,progress)end
    if forfeit and not room.endedAt and wasOut then analytics:flow(e.player,'spectate','postDeath',{result='left',value=math.max(0,os.time()-(progress.time or os.time())),mode=room.single and 'single'or room.casual and 'pvp'or room.mode})
    elseif forfeit and not room.endedAt then analytics:flow(e.player,'match','leaveMidMatch',{item=type(room.campaign)=='string'and 'stage_'..room.campaign:gsub('%-','_')or nil,mode=room.single and 'single'or room.casual and 'pvp'or room.mode,elapsed_seconds=os.time()-(room.startedAt or os.time()),result='forfeit'})end
    if room.casual then if not room.endedAt then room.session:handBack(e.faction)end;room.members[e.player.UserId]=nil
    elseif forfeit and not room.single and not room.session.winnerId then if room.replayLog then room.replayLog:add(room.session.sim.ticks,e.faction,'forfeit')end;room.session:forfeit(e.faction)end
    if room.customRules then e.recentCustom=Outgame.copy(room.customRules)end
    e.room=nil;e.faction=nil;e.stateStream=nil;e.version=nextVersion();e.player:SetAttribute("FrontierRoom",nil);e.player:SetAttribute('FrontierUnrecorded',nil)
    if not e.settingsTouched then local a=accounts:snapshot(e.player);if a.ready then e.settings=Outgame.copy(a.progress.single.settings);e.singleMap=a.progress.single.map end end
    updates:FireClient(e.player,baseState(e));placeCharacter(e.player,nil,nil)
    local stats=e.player:FindFirstChild("leaderstats");if stats then for _,v in ipairs(stats:GetChildren())do v.Value=0 end end
end
local function unobserve(e,silent)
    local room=e.room;if not room or not e.observer then return end
    if room.observers and room.observers[e.player.UserId]then room.observers[e.player.UserId]=nil;room.observerCount=math.max(0,(room.observerCount or 1)-1)end
    if e.observeAt then analytics:flow(e.player,'spectate','watchEnd',{value=math.max(0,os.time()-e.observeAt),result=room.endedAt and 'complete'or 'left'});e.observeAt=nil end
    e.room=nil;e.observer=nil;e.watch=nil;e.stateStream=nil;e.version=nextVersion();e.player:SetAttribute("FrontierRoom",nil)
    if not silent and e.player.Parent==Players then updates:FireClient(e.player,baseState(e));placeCharacter(e.player,nil,nil)end
end
local function observe(e,room,watch)
    if room.endedAt or room.session.winnerId then return false,'끝난 경기'end
    if (room.observerCount or 0)>=LiveModel.maxObservers then return false,'관전 가득'end
    if e.observer then unobserve(e,true)elseif e.room then release(e,false)end
    room.observers=room.observers or {};room.observers[e.player.UserId]=true;room.observerCount=(room.observerCount or 0)+1
    e.room=room;e.observer=true;e.faction=nil;e.watch=LiveModel.pick(room.session,watch);e.version=nextVersion();e.observeAt=os.time()
    e.player:SetAttribute("FrontierRoom",'watch:'..room.id);e.player:SetAttribute('FrontierUnrecorded',nil)
    placeCharacter(e.player,room.session.sim.players[e.watch]and room.session.sim.players[e.watch].spawnTile,room)
    updates:FireClient(e.player,snapshot(e,true))
    return true
end
local function full(light)local n,k=preparing,0;for _,r in ipairs(rooms)do if r.intro or r.practice then k+=1 else n+=1 end end;return light and k>=Config.maxPracticeRooms or not light and n>=Config.maxRooms end
local function watchReplay(e,id)
    if e.room and not e.room.practice or e.loading or queue.membership[e.player.UserId]then return false,'대기 중'end
    if full(false)then return false,'전장 가득'end
    local Guards=require(pack.Core.AbuseGuards);e.guards=e.guards or {}
    if Guards.blocked(e.guards,'room',os.clock(),Guards.roomWindow,Guards.roomBurst)then return false,"다시 시도"end
    local player,version,previous=e.player,e.version,e.room
    local data=replayStore:load(id)
    if entries[player.UserId]~=e or user(player.UserId)~=player or e.version~=version or e.room~=previous
        or e.loading or e.arriving or queue.membership[player.UserId]then return false,'파티원 상태 변경, 다시 시도'end
    if not data then return false,'다시보기 없음'end
    if not ReplayLog.playable(data,game.PlaceVersion)then return false,'이전 버전 경기'end
    if full(false)then return false,'전장 가득'end
    local h=data.header
    if h.settings and h.settings.mapSize=='normal'then
        e.loading=true;pcall(function()bigMaps.store:ensure(h.map)end);e.loading=false
        if entries[player.UserId]~=e or user(player.UserId)~=player or e.version~=version or e.room~=previous then return false end
        if full(false)then return false,'전장 가득'end
    end
    Guards.count(e.guards,'room',os.clock(),Guards.roomWindow)
    preparing+=1;e.loading=true;e.loadingMap=h.map;updates:FireClient(e.player,baseState(e));task.wait()
    local ok,s=pcall(function()
        local session=Session.new(Maps.load(h.map,h.settings and h.settings.mapSize),Outgame.copy(h.settings),Outgame.copy(h.roster),h.mode)
        session.unitSystem.nav:waterFinder()
        return session
    end)
    preparing-=1;e.loading=false;e.loadingMap=nil
    if entries[player.UserId]~=e or user(player.UserId)~=player or e.version~=version or e.room~=previous then return false end
    if not ok then warn(s);updates:FireClient(e.player,baseState(e));return false,'다시보기 실패'end
    s.chatManaged=true
    for index,flag in ipairs(h.flags or {})do if flag and s.resources[index]then s.resources[index].flag=flag end end
    local room={id='replay-'..game.HttpService:GenerateGUID(false),session=s,single=false,queueMode='replay',mode=h.mode,members={},progress={},progressTimer=0,startedAt=os.time(),spawnUntil=os.clock(),accumulator=0,display=0,knownBuildings={},note='',guides={},joined={},
        replay={cursor=ReplayLog.cursor(data),speed=1,endTick=data.endTick,source=id}}
    ReplayLog.feed(room.replay.cursor,s,RoomCommands.replay)
    table.insert(rooms,room)
    if e.player.Parent~=Players then return false end
    local watching,message=observe(e,room)
    return watching,not watching and message or nil
end
local function createRoom(selection,single)
    for i=#rooms,1,-1 do
        local old=rooms[i];local retained=old.warming or old.replay~=nil and next(old.observers or {})~=nil
        for id in pairs(old.members)do if entries[id]and entries[id].room==old then retained=true;break end end
        if not retained then
            for id,pr in pairs(old.progress)do if not pr.final then pr:finish(pr.outcome or 'serverStop',os.time(),true);recordProgress(id,pr)end end
            observers(old,function(_,e)unobserve(e)end)
            table.remove(rooms,i)
        end
    end
    local ffa=selection.ranked=='ffa'
    if not single and (not selection.ranked or ffa)and not selection.clanwar then
        local kept={};for _,id in ipairs(selection.users)do if user(id)and entries[id]then table.insert(kept,id)end end
        if #kept>=math.max(1,ffa and 4 or selection.customRules and selection.customRules.minimum or 1)and #kept<#selection.users then selection.users=kept end
    end
    local roster={};for _,id in ipairs(selection.users)do local p=user(id);local e=entries[id];if not p or not e or e.room and not e.room.practice or e.loading then return false,"파티원 상태 변경, 다시 시도"end;table.insert(roster,{userId=id,name=p.DisplayName,team=selection.teams[id]})end
    local soloTakesLast=single and not(selection.intro or selection.practice or selection.soloTransfer)and #roster==1 and soloTransfer.a.live
        and require(pack.Core.RoomBudget).soloTakesLast(rooms,preparing,Config.maxRooms)
    if soloTakesLast or full(single and (selection.intro or selection.practice)==true)then
        if single and not selection.practice and not selection.soloTransfer and #roster==1 then
            return soloTransfer:depart(user(roster[1].userId),selection,selection.resumeSettings or entries[roster[1].userId].settings)
        end
        return false,"전장 가득"
    end
    local presets={{bots=40,gold=0,minutes=12},{bots=60,gold=125000,minutes=15},{bots=100,gold=0,minutes=18}}
    local rng=Random.new();local preset=presets[rng:NextInteger(1,#presets)]
    if not selection.official and not selection.custom and (not single or selection.practice)then selection.map=Lobby.maps[rng:NextInteger(1,#Lobby.maps)]end
    local cfg=single and Outgame.copy(selection.resumeSettings or entries[selection.users[1]].settings)or {difficulty="Medium",nations=selection.mode=="coop" and 10 or "disabled",bots=selection.mode=="duel" and 0 or 60,customAllianceDuration=5,startingGold=0,goldMultiplier=1,maxTimerValue=15,overtime={enabled=true,startMinutes=10}}
    cfg.seed=game.HttpService:GenerateGUID(false)
    if not single then cfg.bots=selection.mode=="duel"and 0 or preset.bots;cfg.startingGold=preset.gold;cfg.maxTimerValue=preset.minutes end
    if not single and selection.queueMode=='pvp'and not selection.official then
        local n=#selection.users
        local pool=n<=4 and {'pangaea'}or {'world','eastasia','china'}
        selection.map=pool[rng:NextInteger(1,#pool)]
        cfg.bots=n<=4 and 40 or 80;cfg.startingGold=0;cfg.maxTimerValue=n<=4 and 10 or 15
        cfg.nations=n<=4 and 5-n or "disabled"
        cfg.overtime={enabled=true,startMinutes=n<=4 and 8 or 12}
    end
    if selection.official or selection.custom then cfg=require(pack.Core.OutgameRules).copy(selection.settings);cfg.seed=game.HttpService:GenerateGUID(false)end
    if selection.casual then
        selection.map=selection.casualMap;selection.mode='ffa'
        cfg.difficulty='Medium';cfg.nations=math.max(1,Casual.seats-#selection.users);cfg.bots=60;cfg.startingGold=0;cfg.maxTimerValue=Casual.minutes
        cfg.overtime=nil
    end
    if selection.official and selection.fill and not selection.ranked and not selection.clanwar then
        local Fill=require(pack.Core.BattlefieldRules);local rookies=true
        for _,id in ipairs(selection.users)do
            local pl=user(id);local a=pl and accounts:snapshot(pl);local games=0
            if a and a.ready and a.progress then for _,st in pairs(a.progress.stats or {})do games+=tonumber(st.games)or 0 end else rookies=false end
            if games>=Fill.rookieGames then rookies=false end
        end
        if cfg.difficulty~="Hard" then cfg.difficulty=Fill.difficulty(rookies) end
        if selection.fill.ai>0 then cfg.nations=selection.fill.ai;cfg.nationTeams=selection.fill.teams
        elseif selection.mode=='ffa'then cfg.nations='disabled'end
    end
    if selection.daily then cfg=Outgame.copy(selection.daily.settings);cfg.seed=selection.daily.seed end
    if selection.intro and not selection.unrecorded and not selection.campaign then selection.campaign=Outgame.campaign.introStage end
    if selection.campaign then local seed=cfg.seed;cfg=Outgame.campaign.settings(Outgame.campaign.stage(selection.campaign));cfg.seed=seed end
    if selection.practice then cfg={difficulty="Medium",nations=3,bots=30,startingGold=125000,goldMultiplier=1,customAllianceDuration=5,seed=cfg.seed}end
    if selection.intro then local n=Outgame.campaign.stage(Outgame.campaign.introStage).task.n;cfg={difficulty='Easy',nations=0,bots=20,randomSpawn=true,besideTribes=true,startingGold=0,goldMultiplier=1,customAllianceDuration=5,maxTimerValue=Outgame.campaign.introMinutes,goalConquer=n,seed=cfg.seed}end
    if single then cfg=require(pack.Core.SoloChallenge).resolve(Maps.meta(selection.map),cfg)end
    if not selection.intro and (selection.official or selection.goal or selection.campaign and not Outgame.campaign.stage(selection.campaign).team)then cfg.lastCommanderWins=true end
    if selection.ranked or selection.clanwar then cfg.lastCommanderWins=nil end
    do local Live=require(services.LiveConfig);local modes=Live.get('gameSpeedModes')
        cfg.simSpeed=GameSpeed.forMatch(Live.get('gameSpeed'),modes,selection,single)
        cfg.simUnits=GameSpeed.unitsForMatch({nuke=Live.get('nukeSpeed'),transport=Live.get('transportSpeed'),warship=Live.get('warshipSpeed')},modes,selection,single)
    end
    preparing+=1
    for _,id in ipairs(selection.users)do local e=entries[id];e.loading=true;e.loadingMap=selection.map;e.loadingCampaign=selection.campaign;updates:FireClient(e.player,baseState(e))end
    task.wait()
    local _,settled=pcall(bigMaps.settle,bigMaps,cfg,selection.map,selection.official)
    if settled==false then for _,id in ipairs(selection.users)do local pl=user(id);if pl then pcall(analytics.flow,analytics,pl,'match','mapFallback',{item='compact',map_key=selection.map,result='failed',reason='storage_unavailable'})end end end
    local replaySettings,replayInput
    local ok,s=pcall(function()
        replaySettings=single and Replay.settings(cfg)or nil
        cfg.countryPolicy=true
        replayInput=not single and selection.official and {settings=Outgame.copy(cfg),roster=Outgame.copy(roster)}or nil
        if cfg.mapSize~=nil and (cfg.mapSize~="normal" or not Maps.hasNormal(selection.map))then cfg.mapSize=nil end
        local map=Maps.load(selection.map,cfg.mapSize)
        local session=single and Single.new(map,cfg,roster[1].name)or Session.new(map,cfg,roster,selection.mode)
        session.unitSystem.nav:waterFinder()
        return session
    end)
    if ok then pcall(function()for index,r in ipairs(roster)do local pl=user(r.userId);local acc=pl and accounts:snapshot(pl);if acc and s.resources[index] then s.resources[index].flag=acc.flag end end end)end
    preparing-=1
    for _,id in ipairs(selection.users)do if entries[id]then entries[id].loading=false;entries[id].loadingMap=nil;entries[id].loadingCampaign=nil end end
    for _,id in ipairs(selection.users)do if not user(id)then return false,"참가자 퇴장  준비 취소"end end
    if not ok then warn(s);return false,"경기 준비 실패"end
    local room={id=cfg.seed,session=s,single=single,practice=selection.practice,queueMode=selection.queueMode or selection.mode,mode=selection.mode,members={},progress={},progressTimer=0,startedAt=os.time(),spawnUntil=single and nil or os.clock()+Config.spawnSeconds,accumulator=0,display=0,knownBuildings={},note="육지 선택"}
    if selection.daily then room.id=game.HttpService:GenerateGUID(false);room.daily=selection.daily.day end
    room.campaign=selection.campaign
    if replayInput then
        local flags={};for index in ipairs(roster)do flags[index]=s.resources[index]and s.resources[index].flag or false end
        room.replayLog=ReplayLog.new({map=selection.map,mode=selection.mode,settings=replayInput.settings,roster=replayInput.roster,flags=flags,place=game.PlaceVersion,started=os.time()})
    end
    s.chatManaged=true;room.replaySettings=replaySettings;room.customRules=selection.customRules and Outgame.copy(selection.customRules)or nil
    room.analyticsHumans=#roster
    room.intro=selection.intro==true;room.guides={}
    room.awaitFirst=room.intro or nil
    room.casual=selection.casual==true;room.joined={}
    room.unrecorded=selection.unrecorded==true
    room.hostUserId=selection.custom and selection.hostUserId or nil
    room.globalMatch=selection.globalMatch;room.liveCode=selection.liveCode;room.official=selection.official==true
    room.ranked=selection.ranked;room.ratings=selection.ratings;room.clanwar=selection.clanwar;room.trophySolo=selection.trophySolo
    table.insert(rooms,room)
    for index,r in ipairs(roster)do
        if entries[r.userId].room then release(entries[r.userId],false)end
        local e=entries[r.userId];room.members[r.userId]=index;e.room=room;e.faction=index;e.version=nextVersion();e.player:SetAttribute("FrontierRoom",room.id)
        e.player:SetAttribute('FrontierUnrecorded',room.unrecorded and true or nil)
        local mode=selection.rewardMode or (selection.practice and 'training'or selection.intro and 'single'or single and Outgame.classify(e.settings)or selection.mode=='coop'and 'coop'or 'pvp')
        room.progress[r.userId]=Participation.new(room.id,mode,selection.map,#roster,os.time())
        room.progress[r.userId].unrecorded=room.unrecorded
        room.progress[r.userId].ranked=room.ranked~=nil or nil
        room.progress[r.userId].daily=room.daily;room.progress[r.userId].campaign=room.campaign;room.progress[r.userId].official=room.official or nil
        waited(r.userId,'QueueWait',selection.map,mode)
        analytics:match(e.player,selection.map,room.intro and 'training'or selection.practice and 'practice'or room.ranked and 'ranked'or room.casual and 'world'or mode=='pvp'and (room.official and 'official'or 'custom')or mode,room);if room.daily then analytics:custom(e.player,'DailyOpStarted',selection.map,mode,1)end
        if type(room.campaign)=='string'then pcall(analytics.flow,analytics,e.player,'campaign','start',{item='stage_'..room.campaign:gsub('%-','_'),map_key=selection.map,result='accepted'})end
        local account=accounts:snapshot(e.player);local progress=account.progress
        room.progress[r.userId].benefitXPMultiplier=account.billing.benefits.xpMultiplier
        room.progress[r.userId].startLevel=progress and progress.level or nil;room.progress[r.userId].start=ResultPresentation.baseline(progress)
        if selection.intro or not progress or progress.tutorial~=false and not progress.basicsComplete then room.guides[r.userId]=FirstPlay.new()end
        if e.player.Character then placeCharacter(e.player,nil,room)else characters:request(e.player)end
    end
    for _,saved in pairs(selection.parties or {})do if #saved.users>1 then
        local party={leader=saved.leader,users=table.clone(saved.users),ready={},mode='pvp'}
        for i,id in ipairs(party.users)do if id==party.leader then table.remove(party.users,i);table.insert(party.users,1,id);break end end
        for _,id in ipairs(party.users)do parties[id]=party end
    end end
    DropService.begin(room,roster,os.clock(),selection.spawn=='random'or single and cfg.randomSpawn==true,parties)
    if room.casual then
        for index,r in ipairs(roster)do room.joined[r.userId]=os.time()end
        local seen={};for index,r in ipairs(roster)do local party=parties[r.userId]
            if party and not seen[party]then seen[party]=true;local ids={};for i,o in ipairs(roster)do if table.find(party.users,o.userId)then table.insert(ids,i)end end;s:allyFriends(ids)end end
    end
    for _,r in ipairs(roster)do local party=parties[r.userId];local pr=room.progress[r.userId]
        if party and pr and #party.users>1 then for _,o in ipairs(roster)do if o.userId~=r.userId and table.find(party.users,o.userId)then pr.party=true;break end end end
    end
    sendRoom(room,true);return true
end
local function openRoom(e,selection)
    local Guards=require(pack.Core.AbuseGuards);e.guards=e.guards or {}
    if Guards.blocked(e.guards,'room',os.clock(),Guards.roomWindow,Guards.roomBurst)then return false,"다시 시도"end
    local ok,message=createRoom(selection,true)
    if ok then Guards.count(e.guards,'room',os.clock(),Guards.roomWindow)end
    return ok,message
end
local function casualRoom(count,late)
    for _,r in ipairs(rooms)do if r.casual and not r.warming and not r.endedAt and not r.session.winnerId and (late or os.time()-(r.startedAt or os.time())<(Casual.minutes-6)*60)then
        local free=0;for id in pairs(r.session.nations)do if r.session.sim.players[id].tiles.size>0 then free+=1 end end
        if free>=count and r.session:joinCandidate()then return r end
    end end
end
warmCasual=function(room,ids,claimed)
    local s=room.session;room.warming=true;room.warmed={}
    if s.phase=='spawn'then s:startBattle()end
    for _,id in ipairs(ids)do local e,p=entries[id],user(id);local faction=room.members[id]
        if faction then s:retire(faction);room.members[id]=nil;room.progress[id]=nil;room.joined[id]=nil;room.warmed[id]=true end
        if e and e.room==room and p==e.player then
            claimed[id]={entry=e,player=p,version=e.version,party=parties[id]}
            e.room=nil;e.faction=nil;e.arriving=true;if p then p:SetAttribute('FrontierRoom',nil);updates:FireClient(p,baseState(e))end
        end
    end
    local started=os.clock()
    while s.sim.ticks<Casual.warmTicks and not s.winnerId and not shuttingDown and os.clock()-started<8 do
        local slice=os.clock();repeat s:step()until s.sim.ticks>=Casual.warmTicks or os.clock()-slice>.008
        task.wait()
    end
    room.warming=nil;room.spawnUntil=os.clock()
    room.startedAt=os.time()-math.floor(s.sim.ticks/10/math.max(.1,GameSpeed.of(s.settings)))
    local lead=claimed[ids[1]]
    if lead and entries[ids[1]]==lead.entry and user(ids[1])==lead.player and lead.entry.version==lead.version then
        analytics:flow(lead.player,'world','warm',{value=os.clock()-started,count=#ids,result='complete'})
    end
end
joinCasual=function(ids)
    local saved={}
    for _,id in ipairs(ids)do local e=entries[id]
        if not e or not user(id)or e.loading or e.arriving or worldField:pending(id)then return false,'경기 준비 중'end
        saved[id]={entry=e,player=e.player,version=e.version,room=e.room,party=parties[id]}
        local pr=e.room and e.room.progress[id]
        if e.room and not(e.room.practice or e.room.intro or e.room.endedAt or pr and pr.ended)then return false,'경기 중'end
    end
    for _,id in ipairs(ids)do local cancelled,why=queue:cancel(id,os.clock());if cancelled==false then return false,why end end
    for _,id in ipairs(ids)do local e,v=entries[id],saved[id]
        if e~=v.entry or user(id)~=v.player or e.version~=v.version or e.room~=v.room
            or e.loading or e.arriving or worldField:pending(id)or parties[id]~=v.party then return false,'경기 준비 중'end
    end
    for _,id in ipairs(ids)do local e=entries[id];if e.room then release(e,false)end end
    local room=casualRoom(#ids)
    if not room then
        local map=Casual.maps[Casual.next];Casual.next=Casual.next%#Casual.maps+1
        local created,why=createRoom({users=ids,teams={},mode='ffa',casual=true,casualMap=map},false)
        if created then
            local fresh=entries[ids[1]]and entries[ids[1]].room;local claimed={};local ok,err=pcall(warmCasual,fresh,ids,claimed)
            if not ok then warn('casual warm-up',err);if fresh then fresh.warming=nil end end
            local ready={}
            for _,id in ipairs(ids)do local e,v=entries[id],claimed[id]
                if v and e==v.entry and e.player==v.player and e.version==v.version and not e.room and not e.loading
                    and not worldField:pending(id)and e.arriving==true then
                    e.arriving=nil
                    if not shuttingDown and user(id)==v.player and parties[id]==v.party then table.insert(ready,id)end
                end
            end
            ids=ready
            room=fresh and not fresh.endedAt and fresh or nil;if #ids==0 then return true end
        else room=casualRoom(#ids,true)end
        if not room then return created,why end
    end
    local s=room.session;local factions={};local humans=0;for _ in pairs(room.members)do humans+=1 end
    for _,id in ipairs(ids)do
        local e,p=entries[id],user(id);if not e or not p then continue end;local acc=accounts:snapshot(p)
        local faction=s:takeOver({userId=id,name=p.DisplayName})
        if faction then
            table.insert(factions,faction);humans+=1
            room.members[id]=faction;room.joined[id]=os.time();e.room=room;e.faction=faction;e.version=nextVersion()
            p:SetAttribute('FrontierRoom',room.id);p:SetAttribute('FrontierUnrecorded',nil)
            local pr=Participation.new(room.id..':'..id..':'..os.time(),'pvp',s.map.meta.key,humans,os.time());pr.startLevel=acc.progress and acc.progress.level or nil;pr.start=ResultPresentation.baseline(acc.progress);pr.benefitXPMultiplier=acc.billing.benefits.xpMultiplier;pr.official=room.official or nil;room.progress[id]=pr
            for _,other in pairs(room.progress)do if not other.ended then other.humans=math.max(other.humans or 1,humans)end end
            if not(room.warmed and room.warmed[id])then analytics:match(p,s.map.meta.key,'world',room)end
            local rank=1;local size=s.sim.players[faction].tiles.size;for _,q in ipairs(s.sim.players)do if q.tiles.size>size then rank+=1 end end
            analytics:flow(p,'world','takeover',{value=size,count=rank,total=#s.sim.players})
            if acc.flag then s.resources[faction].flag=acc.flag end
            placeCharacter(p,s.spawned[faction],room)
        end
    end
    local seen={};for _,id in ipairs(ids)do local party=parties[id]
        if party and not seen[party]then seen[party]=true;local list={};local friends={};for _,u in ipairs(party.users)do if room.members[u]and entries[u]and entries[u].room==room then table.insert(list,room.members[u]);table.insert(friends,u)end end
            if #list>1 then s:allyFriends(list);for _,u in ipairs(friends)do if room.progress[u]then room.progress[u].party=true end end end end end
    sendRoom(room,true)
    return #factions>0,#factions>0 and '합류  국가 지휘'or '자리 없음'
end
worldField.rooms=function()
    local out={}
    for _,r in ipairs(rooms)do if r.casual and not r.endedAt and not r.session.winnerId then
        local humans=0;for _ in pairs(r.members)do humans+=1 end
        local started=r.startedAt or os.time()
        table.insert(out,{humans=humans,endsAt=started+Casual.minutes*60,joinable=casualRoom(1)==r})
    end end
    return out
end
worldField.lobbyView=function()
    if worldField.live then return worldField:view()end
    local W=require(pack.Core.WorldFieldRules);local now=os.time()
    return W.view({W.row('local','local',nil,worldField.rooms(),now,true)},now)
end
worldField.groups={}
worldField.seat=function(p,e,together,leader)
    e.arriving=true;updates:FireClient(p,baseState(e))
    task.spawn(function()
        local started=os.clock()
        while os.clock()-started<8 and user(p.UserId)==p do local a=accounts:snapshot(p);if a.ready or not a.loading then break end;task.wait(.1)end
        local sorted=table.clone(together);table.sort(sorted);local key=table.concat(sorted,',')
        local g=worldField.groups[key]or {since=os.clock(),here={},done={}};worldField.groups[key]=g;g.here[p.UserId]=true
        while os.clock()-g.since<4 and user(p.UserId)==p do
            local all=true;for _,id in ipairs(together)do if not g.here[id]then all=false;break end end
            if all or g.done[p.UserId]then break end;task.wait(.2)
        end
        if g.done[p.UserId]then return end
        local ids={};for _,id in ipairs(together)do local m=entries[id]
            if g.here[id]and not g.done[id]and m and user(id)and not m.room then g.done[id]=true;m.arriving=nil;table.insert(ids,id)end end
        task.delay(30,function()if worldField.groups[key]==g then worldField.groups[key]=nil end end)
        if #ids==0 then return end
        if #ids>1 and not parties[ids[1]]then
            local party={leader=table.find(ids,leader)and leader or ids[1],users=table.clone(ids),ready={},mode='pvp'}
            for _,id in ipairs(ids)do if not parties[id]then parties[id]=party end end
        end
        local ok,message=joinCasual(ids)
        local room=ok and entries[ids[1]]and entries[ids[1]].room;local humans=0;if room then for _ in pairs(room.members)do humans+=1 end end
        for _,id in ipairs(ids)do local pl=user(id);local m=entries[id]
            if pl then analytics:flow(pl,'world','arrive',{result=ok and 'accepted'or 'failed',reason=not ok and 'capacity'or nil,value=os.clock()-started,human_count=humans,count=#ids})end
            if pl and m and not ok then updates:FireClient(pl,baseState(m));results:FireClient(pl,{action='lobby',ok=false,message=message or '자리 없음',version=m.version})end
        end
    end)
end
local function saveLobby(e)
    if not accounts:snapshot(e.player).ready then return end
    e.saveRevision=(e.saveRevision or 0)+1
    if e.savingLobby then return end;e.savingLobby=true
    task.spawn(function()
        task.wait(1)
        repeat
            local revision=e.saveRevision;local settings=Outgame.copy(e.settings);local map=e.singleMap or 'world';local mode=e.selectedMode or 'single'
            for attempt=1,3 do
                local saved=accounts:updateProgress(e.player.UserId,function(p)p.outgame.single={map=map,settings=settings};p.outgame.lastMode=mode;return p end)
                if saved then break end;task.wait(attempt)
            end
            if revision==e.saveRevision then break end
        until false
        e.savingLobby=false
    end)
end
local function setting(e,key,value)
    local s=e.settings
    if key=="difficulty" and table.find(MatchOptions.difficultyKeys,value)then s[key]=value
    elseif key=="doomsdayClockSpeed" and table.find({"slow","normal","fast","veryfast"},value)then s[key]=value
    elseif key=="nations" and (value=="default" or value=="disabled" or (finite(value) and MatchOptions.validNations(value)))then s[key]=value
    elseif key=="startingGold" and finite(value) and value%1==0 and value>=0 and value<=1e9 then s[key]=value
    elseif key=="bots" and finite(value) and value%1==0 and value>=0 and value<=400 then s[key]=value
    elseif key=="goldMultiplier" and finite(value) and value>=.1 and value<=1000 then s[key]=value
    elseif (key=="maxTimerValue" or key=="customAllianceDuration" or key=="overtimeStartMinutes")and finite(value) and value%1==0 and value>=0 and value<=(key=="customAllianceDuration" and 15 or 120)then
        if key=="overtimeStartMinutes"then s.overtime={enabled=s.overtime and s.overtime.enabled or false,startMinutes=math.max(1,value)}else s[key]=key=="maxTimerValue" and (value>0 and value or nil)or value end
    elseif key=="overtimeEnabled" and type(value)=="boolean"then s.overtime={enabled=value,startMinutes=s.overtime and s.overtime.startMinutes or 30}
    elseif table.find({"infiniteGold","infiniteTroops","instantBuild","waterNukes","disableNukes","disableAlliances","doomsdayClock","randomSpawn"},key)and type(value)=="boolean"then s[key]=value
    elseif key=="spawnImmunityMinutes" and finite(value) and value%1==0 and value>=0 and value<=10 then s.spawnImmunityDuration=value>0 and value*600 or nil
    elseif key=="disabledUnits" and type(value)=="table" and #value<=11 then
        local list={};for _,kind in ipairs(value)do if type(kind)~="string" or not table.find(require(pack.Core.UnitRules).toggleable,kind) or table.find(list,kind)then return false,"설정 확인"end;table.insert(list,kind)end
        s.disabledUnits=#list>0 and list or nil
    elseif key=="mapSize" and (value=="normal" or value=="compact")then s.mapSize=value=="normal" and "normal" or nil
    elseif key=="teamFormat" and (value=="ffa" or require(pack.Core.TeamFormat).valid(value) and (type(value)~="number" or value<=7))then s[key]=value~="ffa" and value or nil
    else return false,"설정 확인"end
    return true
end
local function handle(p,action,value,extra,requestId,version)
    local e=entries[p.UserId];if not e then return end
    local observedAt=os.clock();local observedDuplicate=false
    if table.find({'start','quick','learn','practiceSolo','daily','campaign'},action)then analytics:requested(p,action=='learn'and 'training'or 'single')end
    local function reply(ok,message)
        analytics:command(p,action,ok,message,requestId,version,observedAt,type(value)=='string'and value or nil,observedDuplicate)
        results:FireClient(p,{action=action,requestId=requestId,ok=ok,message=message,version=e.version})
    end
    if type(action)~="string"or e.loading or e.arriving or worldField:pending(p.UserId)then reply(false,"경기 준비 중");return end
    if not e.room then local held=require(services.OpsService).blocked(action,p);if held then reply(false,held);return end end
    if version~=e.version then reply(false,"다시 시도");return end
    e.commandGate=e.commandGate or CommandGate.new()
    observedDuplicate=type(requestId)=='number'and requestId==requestId and e.commandGate.version==version and requestId<=e.commandGate.request
    if not e.commandGate:accept(os.clock(),requestId,version)then reply(false,"다시 시도");return end
    local room=e.room;local ok,message
    if e.observer then
        if action=="menu"then unobserve(e);ok=true
        elseif action=="replaySpeed"and room.replay and table.find(ReplayLog.speeds,value)then room.replay.speed=value;ok=true
        elseif action=="watch"and finite(value)and value%1==0 and room.session.sim.players[value]and room.session.sim.players[value].kind~="BOT"then
            e.watch=value;placeCharacter(p,room.session.sim.players[value].spawnTile,room);updates:FireClient(p,snapshot(e,true));ok=true
        else ok=false;message="관전 중"end
        reply(ok==true,message);if not e.room then updates:FireClient(p,baseState(e))end;return
    end
    if not room and table.find({'start','quick','setting','preset','daily','campaign'},action)and not accounts:snapshot(p).ready then reply(false,'저장 연결 필요');return end
    if (action=='learn'or action=='practiceSolo')and not room then
        if queue.membership[p.UserId]then reply(false,'대기 중');return end
        if #group(p.UserId).users>1 then reply(false,'첫 연습은 혼자 해볼 수 있어요.');return end
        ok,message=openRoom(e,{users={p.UserId},teams={},mode='training',map='korea',intro=true,unrecorded=action=='practiceSolo'or not accounts:snapshot(p).ready})
    elseif action=="start" and not room and type(value)=="string"and Maps.meta(value)then
        if queue.membership[p.UserId]then reply(false,"대기 중");return end
        if extra=='goal'then
            local cfg=require(pack.Core.SoloChallenge).goal(Maps.meta(value),e.settings.difficulty)
            ok,message=openRoom(e,{users={p.UserId},teams={},mode='single',map=value,resumeSettings=cfg,rewardMode='single',goal=true})
            analytics:flow(p,'solo','goalStart',{map_key=value,result=ok and 'accepted'or 'rejected'})
        else
            e.singleMap=value;e.settingsTouched=true;local savedSettings=Outgame.copy(e.settings)
            task.spawn(function()for attempt=1,3 do if accounts:saveSingle(p,value,savedSettings)then break end;task.wait(attempt)end end)
            ok,message=openRoom(e,{users={p.UserId},teams={},mode="single",map=value})
        end
    elseif action=='quick'and not room and type(value)=='string'and QuickSolo.valid(value)then
        if queue.membership[p.UserId]then reply(false,"대기 중");return end
        local key=QuickSolo.pick(value);local cfg=QuickSolo.settings(Maps.meta(key),value)
        ok,message=openRoom(e,{users={p.UserId},teams={},mode='single',map=key,resumeSettings=cfg,rewardMode='single',quick=true})
        analytics:flow(p,'solo','quickStart',{map_key=key,item=value,result=ok and 'accepted'or 'rejected'})
    elseif action=='daily'and not room then
        if queue.membership[p.UserId]then reply(false,"대기 중");return end
        if not accounts.live.enabled('dailyOp')then reply(false,'오늘의 도전 점검 중');return end
        local Daily=require(pack.Core.DailyOperation);local op=Daily.of(Daily.day(os.time()))
        ok,message=openRoom(e,{users={p.UserId},teams={},mode="single",map=op.map,daily=op,rewardMode='single'})
    elseif action=='campaign'and not room then
        local C=Outgame.campaign;local stage=C.stage(value);local view=(accounts:snapshot(p).progress or {}).campaign
        if queue.membership[p.UserId]then reply(false,"대기 중");return end
        if not stage then ok,message=false,'작전 없음'
        elseif not C.unlocked({campaign=view},stage.id)then ok,message=false,'🔒 앞 작전'
        elseif stage.intro then ok,message=openRoom(e,{users={p.UserId},teams={},mode='training',map=stage.map,intro=true})
        else ok,message=openRoom(e,{users={p.UserId},teams={},mode='single',map=stage.map,campaign=stage.id,rewardMode='single'})end
        analytics:flow(p,'solo','campaignStart',{item=stage and 'stage_'..stage.id:gsub('%-','_')or nil,map_key=stage and stage.map or nil,result=ok and 'accepted'or 'rejected'})
    elseif action=="setting" and not room then ok,message=setting(e,value,extra);if ok then e.settingsTouched=true;saveLobby(e)end
    elseif action=="preset"and not room and type(value)=="string"and Presets[value]then e.settings=Outgame.copy(Presets[value]);e.settingsTouched=true;saveLobby(e);ok=true
    elseif action=="menu" then if room and room.practice then local cancelled,why=queue:cancel(p.UserId,os.clock());if cancelled==false then reply(false,why);return end end;release(e,true);ok=true
    elseif room then
        local s=room.session;local id=e.faction;local actual=function(t)return room.single and t or Session.viewId(t,id)end
        local moved=not room.single and s.spawned~=nil and s.spawned[id]~=nil
        if action=='guide'then room.guides[p.UserId]=FirstPlay.new();ok=true
        elseif action=="pause"then
            if room.single then room.paused=value==true;ok=true
            elseif room.hostUserId==p.UserId and s.phase=="playing"then
                local now=os.clock();if room.pauseFrom then room.pauseSpent=(room.pauseSpent or 0)+now-room.pauseFrom;room.pauseFrom=nil end
                local left=300-(room.pauseSpent or 0)
                if value==true and left<1 then room.paused=false;room.pauseLimit=nil;ok=false;message="일시정지 시간 소진"
                else room.paused=value==true;room.pauseFrom=room.paused and now or nil;room.pauseLimit=room.paused and now+math.min(180,left)or nil;ok=true end
            else ok=false;message="방장 전용"end
        elseif action=="speed"then
            if room.single and (value==.5 or value==1 or value==2 or value==4)then room.speed=value;ok=true else ok=false end
        elseif room.paused then ok=false;message=(room.single or room.hostUserId==e.player.UserId)and "일시정지 중"or "Ⅱ 방장 일시정지"
        elseif action=='spawn'and room.drop and not room.drop.finished then ok=false;message='낙하 중'
        elseif action=="spawn"and not room.single and room.randomSpawn and s.spawned[id]then ok=false;message="랜덤 시작"
        elseif action=="spawn"and value=="auto"and s.phase=="spawn"then
            local tile=SpawnRules.random(s,"quick:"..p.UserId..":"..os.clock(),s.settings.seed or room.id)
            if not tile then ok=false;message="빈 자리 없음"
            else if room.single then ok,message=s:spawn(tile)else ok,message=s:spawnHuman(id,tile)end;if ok then placeCharacter(p,tile,room);if room.replayLog then room.replayLog:add(s.sim.ticks,id,'spawn',tile)end end end
        elseif action=="spawn"and validTile(s,value)then if room.single then ok,message=s:spawn(value)else ok,message=s:spawnHuman(id,value)end;if ok then placeCharacter(p,value,room);if room.replayLog then room.replayLog:add(s.sim.ticks,id,'spawn',value)end end
        elseif s.phase~="playing"or s.sim.players[id].tiles.size==0 or s.resources[id].forfeited then ok=false;message="경기 중에만"
        else
            ok,message=RoomCommands.apply(s,id,room.single,action,value,extra)
            if ok and room.replayLog then local v,x=RoomCommands.record(action,value,extra);room.replayLog:add(s.sim.ticks,id,action,v,x)end
        end
        if ok and table.find({"attack","build","upgrade"},action)then emit(room,p,action,(action=="build"or action=="attack")and extra or nil)end
        if ok and room.awaitFirst and (action=='attack'or action=='transport')then room.awaitFirst=nil end
        if ok and room.progress[p.UserId]then room.progress[p.UserId]:command(action,value,os.time())end
        if ok and action=='attack'and extra and s.sim:owner(extra)>0 and not room.progress[p.UserId].combatOrderLogged then
            room.progress[p.UserId].combatOrderLogged=true;analytics:custom(p,'FirstCombatOrder',s.map.meta.key,room.mode,room.progress[p.UserId].spawnedAt and os.time()-room.progress[p.UserId].spawnedAt or nil)
        end
        if ok and room.guides[p.UserId]then room.guides[p.UserId]:command(action,s.sim.players[id].tiles.size)end
        if ok and action=="spawn"then local tile=s.spawned and s.spawned[id]or room.single and tonumber(value)or nil;if tile then emit(room,p,moved and 'relocate'or 'settle',tile)end end
        if e.room then sendRoom(room,action=="spawn")end
    else ok=false;message="참가 먼저"end
    reply(ok==true,message);if not e.room then updates:FireClient(p,baseState(e))end
end
command.OnServerEvent:Connect(handle)
if Run:IsStudio() then
    local qa=Instance.new("BindableFunction");qa.Name="FrontierGameplayQA";qa.Parent=game.ServerScriptService
    qa.OnInvoke=function(userId,action,args)
        if action=='storageStatus'then
            local function count(t)local n=0;for _ in pairs(t)do n+=1 end;return n end
            return {reward=rewards.worker:status(userId),career=careers.worker:status(userId),rewardMetrics=table.clone(rewards.worker.metrics),careerMetrics=table.clone(careers.worker.metrics),loadedProfiles=count(accounts.repo.loaded),careerProfiles=count(careers.profiles),rooms=#rooms}
        end
        if action=='storageFault'then
            assert(accounts.localMode and careers.localMode,'Local Studio memory only')
            args=args or {};local worker=args.target=='career'and careers.worker or rewards.worker
            worker.qaOriginalUpdate=worker.qaOriginalUpdate or worker.store.UpdateAsync;local original=worker.qaOriginalUpdate
            worker.store.UpdateAsync=function(store,key,fn)
                worker.store.UpdateAsync=original
                if args.after then original(store,key,fn)end
                error('Controlled Studio lost storage acknowledgement')
            end
            return {success=true,target=args.target or 'reward'}
        end
        if action=='storageRetry'then rewards:pulse();careers:flush(userId);return true end
        if action=='storageFixture'then
            assert(accounts.localMode and Run:IsStudio(),'Only local Studio memory');args=args or {};local p=user(userId);assert(p and not entries[userId].room,'Use the lobby')
            local a=accounts.accounts[p];local store=accounts.repo.store;accounts.qaOriginalGet=accounts.qaOriginalGet or store.GetAsync
            if args.kind=='stored'then local cfg=Outgame.copy(Presets.standard);cfg.difficulty='Hard';assert(accounts:saveSingle(p,'japan',cfg))
            elseif args.kind=='loading'then a.loading=true;a.ready=false;accounts:publish(p,a)
            elseif args.kind=='failed'then store.GetAsync=function()error('Controlled Studio storage outage')end;a.loading=false;accounts:load(p)
            elseif args.kind=='recoverable'then store.GetAsync=accounts.qaOriginalGet
            elseif args.kind=='ready'then store.GetAsync=accounts.qaOriginalGet;a.loading=false;accounts:load(p)
            else error('Unknown storage fixture')end
            local snapshot=accounts:snapshot(p);return {ready=snapshot.ready,loading=snapshot.loading,map=snapshot.progress.single.map,settings=snapshot.progress.single.settings,stored=accounts.memory[tostring(userId)]}
        end
        if action=='analytics'then return analytics:diagnostic()end
        if action=='analyticsExercise'then
            local p=assert(user(userId));local before=analytics:diagnostic();local s=analytics.sessions[p];local began=os.clock()
            local n=math.clamp(args and args.count or 1000,1,3000);local base=100000000+(s.qaTelemetrySequence or 0);s.qaTelemetrySequence=base+n
            for i=1,n do analytics:command(p,'attack',i%5~=0,i%5==0 and '골드 부족'or nil,base+i,1,os.clock())end
            analytics:command(p,'attack',true,nil,base+1,1,os.clock());for _,member in ipairs(Players:GetPlayers())do analytics:flushCommands(member,true)end
            local seq=s.clientSeq;local invalid=analytics.health.client_rejected
            analytics:ingest(p,{events={{name='commerce_grant_result',sequence=seq+1,data={result='granted'}}}})
            analytics:ingest(p,{events={{name='player_outcome',sequence=seq+1,data={outcome='won'}}}})
            local first=analytics:emit(p,'benefit_used',{benefit='xp',result='ok',nickname='DO_NOT_STORE',chat='DO_NOT_STORE',receipt='DO_NOT_STORE'},{id='qa-dedup-'..base})
            local second=analytics:emit(p,'benefit_used',{benefit='xp',result='ok'},{id='qa-dedup-'..base})
            analytics:communication(p,'signal','team','ready',true,'qa-ready-'..base)
            analytics:communication(p,'signal','team','accepted',true,'qa-delivery-'..base)
            analytics:communication(p,'signal','team','accepted',true,'qa-delivery-'..base)
            for _,member in ipairs(Players:GetPlayers())do analytics:flushCommands(member,true)end
            local after=analytics:diagnostic();return {beforeSequence=before.records[#before.records].sequence,after=after,commands=n,elapsed_ms=(os.clock()-began)*1000,duplicateSuppressed=second==nil,privateFieldsDropped=first.data.nickname==nil and first.data.chat==nil and first.data.receipt==nil,authorityBlocked=analytics.health.client_rejected-invalid==2 and s.clientSeq==seq}
        end
        if action=='progressFixture'then
            assert(accounts.localMode,'Local Studio memory only');local now=os.time();local day,week=Outgame.day(now),Outgame.week(now)
            local profile,err=accounts:applyProgress(userId,{id='launch-progress-fixture',revision=1,mode='coop',map='world',humans=2,seconds=600,cities=3,supports=12,peak=.22,outcome='won',time=now,final=true,days={[day]={seconds=600,cities=3,finished=1}},weeks={[week]=600},weeklyActions={[week]={cities=3,supports=12}},milestones={}})
            assert(profile,err);return accounts:snapshot(user(userId))
        end
        if action=='devMatch'then local dev=services:FindFirstChild('DevCheats');assert(dev,'경기 치트가 없는 빌드예요.');return require(dev).match(entries[userId],args or {},{send=function(room)sendRoom(room,true)end,lobby=function(e)saveLobby(e);updates:FireClient(e.player,baseState(e))end})end
        local e=entries[userId];local room=e and e.room;assert(room,"Start a solo practice first")
        local s=room.session;args=args or {}
        if action=='perf'then return {map=s.map.meta.key,tick=s.sim.ticks,players=#s.sim.players,units=#(s.units or {}),stats=PerfStats.summary(room,args.reset==true)}end
        if action=="inspect" then return {tick=s.sim.ticks,phase=s.phase,units=s.units,players=#s.sim.players,naval=s.unitSystem.naval.data,progressMode=room.progress[userId]and room.progress[userId].mode,settings=s.settings} end
        if action=='dropState'then return room.drop and room.drop:snapshot(e.faction,os.clock())end
        if action=="pause" then room.paused=args.value~=false
        elseif action=="seed" then
            assert(room.single and #s.sim.players==1,"Use the solo sandbox preset")
            local B=require(pack.Core.BigNat);local enemy=s.sim:addPlayer("HUMAN",500000)
            enemy.name="해상 훈련 부대";s.resources[enemy.id]={gold=B.fromNumber(100000000),constructed={},name=enemy.name,kind="HUMAN",lastDelete=-1}
            s.settings.instantBuild=true;s.settings.infiniteGold=args.realCosts~=true;s.settings.disableNukes=false;s.settings.waterNukes=false
            for id,tile in ipairs({args.home,args.enemy}) do
                assert(validTile(s,tile) and Terrain.isLand(s.sim.terrain[tile+1]),"Choose two land tiles")
                for _,t in ipairs(s:flood(tile,function(t)return s:distance2(t,tile)<args.radius^2 and Terrain.isLand(s.sim.terrain[t+1]) and not Terrain.isImpassable(s.sim.terrain[t+1])end))do s.sim:conquer(id,t)end
                s.sim.players[id].troops=500000;s.sim.players[id].spawnTile=tile
            end
            s.phase="playing";s.sim.ticks=200;room.paused=true;s.spawnTile=args.home;s:recordOwnership();s.sim.captured={};placeCharacter(e.player,args.home,room)
        elseif action=='resources'then
            assert(room.single and #s.sim.players==2,'Use the two-side solo QA fixture')
            for id=1,2 do if args['troops'..id]then s.sim.players[id].troops=args['troops'..id]end;if args['gold'..id]then s:setGold(id,require(pack.Core.BigNat).fromNumber(args['gold'..id]))end end
        elseif action=="advance" then for _=1,math.clamp(args.ticks or 1,1,1000)do s:step()end
        elseif action=="enemyBuild" then s.unitSystem:build(2,args.kind,args.tile)
        elseif action=='forfeit' then
            assert(not room.single,'Use a real multiplayer QA session')
            if room.replayLog then room.replayLog:add(s.sim.ticks,e.faction,'forfeit')end;s:forfeit(e.faction)
        elseif action=='resultEliminate'then
            assert(not room.single and s.phase=='playing','Use a multiplayer result test')
            local enemy;for id,pl in ipairs(s.sim.players)do if id~=e.faction and (pl.team==nil or pl.team~=s.sim.players[e.faction].team) and pl.tiles.size>0 then enemy=id;break end end
            assert(enemy,'Need an actual opposing faction')
            for _,tile in ipairs(s.sim.players[e.faction].tiles:values())do s.sim:conquer(enemy,tile)end
            s:recordOwnership()
        elseif action=='resultEnd'then
            assert(not room.single and s.roster[e.faction],'Use a multiplayer result test')
            s.winnerId=e.faction;s.winnerTeam=s.sim.players[e.faction].team;s.phase='won'
        elseif action=='resultAge'then
            assert(room.endedAt,'End the match first');room.endedAt=os.clock()-180
        elseif action=="feedbackScenario" then
            local outcome=args.kind=='victory'or args.kind=='defeat'
            local pact=args.kind=='ally'or args.kind=='betray'
            assert(room.single and #s.sim.players>=2 and (outcome or pact or #s.sim.players==2),"Use a solo outcome or two-side QA fixture")
            local other=args.id;if pact and not other then for id,pl in ipairs(s.sim.players)do if id~=1 and pl.kind=='NATION'and pl.tiles.size>0 then other=id;break end end end;other=other or 2
            if args.kind=="ally" then s:allianceCommand(other,1,"request");s:step();s:allianceCommand(1,other,"accept");s:step()
            elseif args.kind=="betray" then s:allianceCommand(other,1,"break");s:step()
            elseif args.kind=="incoming" then s.sim:attack(2,1,100000)
            elseif args.kind=="request" then s:allianceCommand(2,1,"request")
            elseif args.kind=="accept" then s:allianceCommand(1,2,"accept")
            elseif args.kind=="eliminate" then for _,tile in ipairs(s.sim.players[2].tiles:values()) do s.sim:conquer(1,tile) end
            elseif args.kind=="victory" or args.kind=="defeat" then s.phase=args.kind=="victory" and "won" or "lost";s.winnerId=args.kind=="victory" and 1 or 2
            elseif args.kind=="impact" then s.unitSystem:effect("detonate",args.tile,2,{radius=20,weapon="AtomBomb"})
            else error("Unknown feedback QA fixture") end
            s:recordOwnership()
        else error("Unknown QA action")end
        sendRoom(room,true);return {phase=s.phase,tick=s.sim.ticks,units=#s.units}
    end
end
read.OnServerInvoke=function(p)
    local e=entries[p.UserId];if not e then return {phase="menu",version=0,settings=defaults}end
    local Guards=require(pack.Core.AbuseGuards);e.guards=e.guards or {}
    if (e.readsWaiting or 0)>=Guards.readQueue then return {busy=true,version=e.version}end
    local delay=Guards.reserve(e.guards,'read',os.clock(),Guards.readInterval)
    if delay>0 then e.readsWaiting=(e.readsWaiting or 0)+1;task.wait(delay);e.readsWaiting-=1 end
    if entries[p.UserId]~=e then return {phase="menu",version=0,settings=defaults}end
    e.stateStream=nil;return snapshot(e,true)
end
preview.OnServerInvoke=function(p,kind,tile,version,options)
    local e=entries[p.UserId];if not e or not e.room or e.observer or e.version~=version or os.clock()-(e.lastPreview or 0)<.08 then return {valid=false,reason="위치 확인 필요"}end
    if type(kind)~="string" or not validTile(e.room.session,tile) then return {valid=false,reason="위치 선택"} end
    e.lastPreview=os.clock()
    if table.find({'AtomBomb','HydrogenBomb','MIRV'},kind)and options and type(options)=='table'then
        return require(pack.Core.NuclearAimModel).plan(e.room.session,e.faction,kind,tile,options.up)
    end
    if kind=="context" then return AttackPresentation.context(e.room.session,e.faction,tile) end
    local function one(k)return e.room.single and e.room.session:preview(k,tile)or e.room.session:previewFor(e.faction,k,tile)end
    if kind=="buildables" then local out={};for _,k in ipairs(require(pack.Core.UnitRules).buildable)do if not require(pack.Core.UnitRules).nukes[k]then local ok,r=pcall(one,k);out[k]=ok and r or {valid=false}end end;return out end
    local r=one(kind);local us=e.room.session.unitSystem
    if type(r)=='table'and r.valid and not r.upgrade and r.tile and us then local ok,g=pcall(us.rail.ghost,us.rail,kind,r.tile);if ok and g then r.rails=g.paths;r.railSnap=g.snap end end
    return r
end
equip.OnServerInvoke=function(p,id,slot)return accounts:equip(p,id,slot)end
local ASK_SECONDS=10
local askSerial=0
local function askLeader(p,party,field,revision)
    local id=p.UserId;local e=entries[id]
    if #party.users<2 or party.leader==id then return {ok=false,message='파티장 전용'}end
    if not between(e)or e.loading then return {ok=false,message='경기 중'}end
    local le=entries[party.leader];if not le or not user(party.leader)or not between(le)or le.loading then return {ok=false,message='방장 경기 중'}end
    local ask={from=id,name=p.DisplayName,field=field,seconds=ASK_SECONDS}
    if field=='world'then
        local w=worldField.lobbyView();if not w then return {ok=false,message='전장 다시 선택'}end
        ask.kind='world';ask.map='world';ask.count=w.humans or 0;ask.max=w.seats or 20
    else
        local f;for _,c in ipairs(queue:directory(id).fields)do if c.id==field then f=c;break end end
        if not f or f.kind=='custom'then return {ok=false,message='전장 다시 선택'}end
        ask.kind=f.kind;ask.revision=revision;ask.map=f.rules.map;ask.mode=f.rules.mode;ask.count=f.count;ask.max=f.rules.maximum
    end
    askSerial+=1;ask.id=askSerial;party.ask=ask
    analytics:flow(p,'social','partyAsk',{result='sent',item=ask.kind=='world'and 'world'or 'official'})
    task.delay(ASK_SECONDS+.5,function()
        if party.ask~=ask then return end
        party.ask=nil
        local m=entries[ask.from];if m and user(ask.from)then results:FireClient(m.player,{action='lobby',ok=false,message='방장 응답 없음',version=m.version});analytics:flow(m.player,'social','partyAsk',{result='timeout'})end
        pushLobby()
    end)
    pushLobby()
    return {ok=true,state=lobbySnapshot(id)}
end
local function lobbyHandle(p,action,value)
    local id=p.UserId;local e=entries[id];if not e then return {ok=false}end
    if action=="read"then return {ok=true,state=lobbySnapshot(id)}end
    if e.arriving or e.loading or worldField:pending(id)then return {ok=false,message='경기 준비 중'}end
    if table.find({'map','selectMode'},action)and not accounts:snapshot(p).ready then return {ok=false,message='저장 연결 필요'}end
    if os.clock()-(e.lastLobby or 0)<.2 then return {ok=false,message="다시 시도"}end;e.lastLobby=os.clock()
    do local held=require(services.OpsService).blocked(action,p);if held then return {ok=false,message=held}end end
    local ok,message=true,nil;local party=group(id);local teleport
    if action=='selectMode'then
        if not table.find({'single','pvp','coop'},value)then return {ok=false}end
        if party.leader~=id and #party.users>1 then return {ok=false,message='파티장 전용'}end
        if e.room and not e.room.practice then return {ok=false,message='경기 중'}end
        local queued=queue.membership[id]
        if queued and queued.mode==value then return {ok=true,state=lobbySnapshot(id)}end
        local cancelled,why=queue:cancel(id,os.clock());if cancelled==false then return {ok=false,message=why}end
        if queued then analytics:queueExit(e.player,'cancelled')end
        if e.room and e.room.practice then release(e,false)end
        if #party.users>1 then party.mode=value;party.ready={}end
        e.selectedMode=value;e.settingsTouched=true;saveLobby(e)
    elseif action=='map'then
        if e.room or type(value)~='string'or not Maps.meta(value)then return {ok=false}end
        e.singleMap=value;e.settingsTouched=true;saveLobby(e)
    elseif action=='partyAsk'then
        if type(value)~='table'or type(value.field)~='string'then return {ok=false}end
        return askLeader(p,party,value.field,finite(value.revision)and value.revision or nil)
    elseif action=='partyAnswer'then
        local ask=party.ask
        if party.leader~=id or type(value)~='table'or not ask or ask.id~=value.id then return {ok=false,message='요청 지남'}end
        party.ask=nil
        local asker=entries[ask.from];local here=asker and user(ask.from)and table.find(party.users,ask.from)
        if value.accept~=true or not here then
            if here then results:FireClient(asker.player,{action='lobby',ok=false,message='방장이 거절했어요',version=asker.version});analytics:flow(asker.player,'social','partyAsk',{result='declined'})end
            pushLobby();return {ok=true,state=lobbySnapshot(id)}
        end
        analytics:flow(asker.player,'social','partyAsk',{result='accepted'})
        if queue.membership[id]then local cancelled,why=queue:cancel(id,os.clock());if cancelled==false then return {ok=false,message=why}end;waited(id,'QueueCancelled')end
        e.lastLobby=nil
        if ask.field=='world'then return lobbyHandle(p,'play')end
        return lobbyHandle(p,'joinField',{field=ask.field,revision=ask.revision})
    elseif action=='ready'then
        if not between(e)or queue.membership[id]then return {ok=false,message='경기 중'}end
        party.ready=party.ready or {};party.ready[id]=not party.ready[id]
    elseif action=='again'then
        local room=e.room;local pr=room and room.progress[id]
        if not room or not pr or not pr.ended then return {ok=false,message='경기 중'}end
        if room.trophySolo and #party.users>1 then return {ok=false,message='혼자일 때만'}end
        if queue.membership[id]then return {ok=false,message='대기 중'}end
        local single,map,mode=room.single,room.session.map.meta.key or e.singleMap,room.queueMode
        if room.daily and not accounts.live.enabled('dailyOp')then return {ok=false,message='오늘의 도전 점검 중'}end
        local repeatSelection=single and Replay.single(room,id,os.time(),(accounts:snapshot(p).progress or {}).campaign)or nil
        if room.trophySolo then
            ok,message=ranked:join(queue,{id},'r1v1',os.clock())
            if ok then release(e,false);queued({id},'ranked')end
        else
        release(e,false)
        if single then ok,message=openRoom(e,repeatSelection)
        elseif room.ranked and not room.clanwar and room.ranked~='2v2'then ok,message=ranked:join(queue,{id},room.trophySolo and 'r1v1'or room.ranked,os.clock());if ok then queued({id},'ranked')end
        else message=mode=='custom'and '규칙 변경, 다시 확인'or '규칙 변경, 다시 확인'end
        end
    elseif action=='customCreate'or action=='customUpdate'or action=='customReady'or action=='customStart'or action=='customLaunch'or action=='customTeam'or action=='joinCode'then
        if e.room or e.loading then return {ok=false,message='경기 중'}end
        if action=='customCreate'or action=='customUpdate'then
            local rules=action=='customCreate'and value or type(value)=='table'and value.rules
            local allowed=accounts.billing:publicCustom(p,rules)
            if not allowed then return {ok=false,message='🔒 VIP 공개 모집'}end
        end
        if action=='customCreate'or action=='joinCode'then
            local ids,why=partyEntry(p,party);if not ids then return {ok=false,message=why}end
            if action=='customCreate'then ok,message=queue:createCustom(id,value,os.clock(),ids)else ok,message=queue:joinCode(id,value,os.clock(),ids)end
            if ok then queued(ids,'custom');for _,uid in ipairs(ids)do local member=entries[uid];if member and member.room and not member.room.practice then release(member,false)end end end
        else ok,message=queue:customCommand(id,action,value)end
    elseif action=='fieldReady'then ok,message=queue:fieldReady(id,type(value)=='table'and value.ready==true)
    elseif action=='ranked'then
        if value~='r1v1'and value~='clanwar'then return {ok=false,message='전장 다시 선택'}end
        if value=='r1v1'and #party.users>1 then return {ok=false,message='혼자일 때만'}end
        if not between(e)or e.loading then return {ok=false,message='경기 중'}end
        local ids,why=partyEntry(p,party);if not ids then return {ok=false,message=why}end
        ok,message=ranked:join(queue,ids,value,os.clock())
        if ok then queued(ids,'ranked');for _,uid in ipairs(ids)do local member=entries[uid];if member and member.room and not member.room.practice then release(member,false)end end end
    elseif action=='joinField'then
        if type(value)=='table'and type(value.field)=='string'and value.field:sub(1,7)=='ranked-'then return {ok=false,message='전장 다시 선택'}end
        if not between(e)or e.loading then return {ok=false,message='경기 중'}end
        local custom=type(value)=='table'and type(value.field)=='string'and value.field:sub(1,7)=='custom-'
        local ids,why=partyEntry(p,party);if not ids then return {ok=false,message=why}end
        local why;ok,message,why=queue:joinField(ids,value,os.clock())
        if not ok and not custom and type(value)=='table'and value.quick==true and (why=='stale'or why=='full'or why=='teamfull'or why=='locked')then
            local others={};for _,f in ipairs(queue:directory(id).fields)do if why=='stale'or f.id~=value.field then table.insert(others,f)end end
            local best=require(pack.Core.PartyPlay).pick(others,party)
            if best then ok,message=queue:joinField(ids,{field=best.id,revision=best.revision},os.clock())end
        end
        if ok and not custom and #ids>1 then party.mode='pvp';party.ask=nil;analytics:flow(p,'social','partyFollow',{count=#ids})end
        if ok then queued(ids,custom and 'custom'or 'official')
            for _,uid in ipairs(ids)do local member=entries[uid];if member and member.room and not member.room.practice then release(member,false)end end
        end
    elseif action=="join"then
        if value~="pvp"and value~="coop"then return {ok=false,message="모드 선택"}end
        if party.leader~=id then return {ok=false,message="파티장이 참가 모드를 선택해요."}end
        for _,u in ipairs(party.users)do if not entries[u]or not between(entries[u])or entries[u].loading then return {ok=false,message="파티원 경기 중"}end end
        ok,message=queue:join(party.users,value,os.clock());if ok then queued(party.users,value)
            for _,uid in ipairs(party.users)do local member=entries[uid];if member and member.room and not member.room.practice then release(member,false)end end
        end
    elseif action=='play'then
        if #party.users>1 and party.leader~=id then return askLeader(p,party,'world')end
        if worldField.live and not worldField.hostId then
            local ids={id};for _,u in ipairs(party.users)do if u~=id then table.insert(ids,u)end end
            local players={}
            for _,u in ipairs(ids)do local m=entries[u];if not m or not user(u)or not between(m)or m.loading or m.arriving then return {ok=false,message='파티원 경기 중'}end;table.insert(players,user(u))end
            local validate=worldField:guard(players);if not validate then return {ok=false,message='파티 상태 바뀜'}end
            for _,u in ipairs(ids)do
                if not validate(true)then return {ok=false,message='파티 상태 바뀜'}end
                local cancelled,why=queue:cancel(u,os.clock());if cancelled==false then return {ok=false,message=why}end
            end
            ok,message=worldField:join(players,validate);teleport=ok or nil
        else ok,message=joinCasual(table.clone(party.users))end
    elseif action=='practice'then
        local waiting=queue.membership[id]
        if not waiting or waiting.mode~='pvp'or e.room or e.loading then return {ok=false}end
        ok,message=openRoom(e,{users={id},teams={},mode='practice',map='thebox',practice=true})
    elseif action=='hq'then
        if game.PrivateServerId==''then return {ok=false,public=true,message='이미 공개 로비'}end
        if #party.users>1 and party.leader~=id then return {ok=false,message='파티장이 로비 복귀를 누르면 함께 이동해요.'}end
        if queue.membership[id]then return {ok=false,message='대기 중'}end
        local players,leader={},party.leader or id
        for _,uid in ipairs(party.users)do local m=entries[uid];if m and user(uid)and between(m)and not queue.membership[uid]then table.insert(players,user(uid))end end
        if #players==0 then return {ok=false,message='대상 없음'}end
        local options=Instance.new('TeleportOptions');options:SetTeleportData({party=#players>1 and leader or nil,hop=#players>1 and game.HttpService:GenerateGUID(false)or nil})
        if not script:GetAttribute('HqFailHook')then script:SetAttribute('HqFailHook',true)
            game:GetService('TeleportService').TeleportInitFailed:Connect(function(pl,why)local m=entries[pl.UserId]
                if not(m and m.hqSending and os.clock()-m.hqSending<30)then return end
                if m.hqOptions and not m.hqRetried then m.hqRetried=true;local o=m.hqOptions
                    task.delay(2,function()if user(pl.UserId)==pl and m.hqSending then local sent=pcall(function()game:GetService('TeleportService'):TeleportAsync(game.PlaceId,{pl},o)end);if sent then return end end;m.hqSending=nil;if user(pl.UserId)then results:FireClient(pl,{action='lobby',ok=false,message='이동 실패',version=m.version})end end);return end
                m.hqSending=nil;results:FireClient(pl,{action='lobby',ok=false,message='이동 실패',version=m.version})
                warn('hq teleport failed',pl.UserId,why)end)
        end
        for _,pl in ipairs(players)do local m=entries[pl.UserId];if m then m.hqSending=os.clock();m.hqOptions=options;m.hqRetried=nil end end
        local sent=pcall(function()game:GetService('TeleportService'):TeleportAsync(game.PlaceId,players,options)end)
        if not sent then for _,pl in ipairs(players)do local m=entries[pl.UserId];if m then m.hqSending=nil end end;return {ok=false,message='이동 실패'}end
        message='공개 로비로 이동해요'
    elseif action=='replays'then
        local rows=replayStore:list(id);return {ok=rows~=nil,replays=rows}
    elseif action=='replay'then
        if type(value)~='string'or #value>64 then return {ok=false}end
        if not accounts.live.enabled('replays')then return {ok=false,message='다시보기 점검 중'}end
        ok,message=watchReplay(e,value)
    elseif action=='spectate'then
        if type(value)~='string'or #value>64 then return {ok=false}end
        if e.room and not e.room.practice or queue.membership[id]then return {ok=false,message='대기 중'}end
        if not accounts.live.enabled('spectate')then return {ok=false,message='관전 점검 중'}end
        local mine=liveMatches:mine(rooms,id)
        if not require(pack.Core.VipComms).allows('spectate',nil,p:GetAttribute('CommanderVIP')==true)and not(mine and mine.id==value)then
            analytics:flow(p,'spectate','vipLocked',{result='rejected',reason='subscription_required'});return {ok=false,vipLocked=true,message='🔒 VIP 관전'}
        end
        local target;for _,r in ipairs(rooms)do if r.globalMatch==value and LiveModel.listed(r)then target=r;break end end
        if target then ok,message=observe(e,target)else ok,message=liveMatches:send(p,value)end
    elseif action=='rejoin'then
        local mine=not e.room and liveMatches:mine(rooms,id)
        if not mine then return {ok=false,message='끝난 경기'}end
        if queue.membership[id]then return {ok=false,message='대기 중'}end
        ok,message=liveMatches:send(p,mine.id);if ok then message='경기로 돌아가는 중…'end
    elseif action=="cancel"then local cancelled,why=queue:cancel(id,os.clock());if cancelled==false then return {ok=false,message=why}end;waited(id,'QueueCancelled');message=why;if #party.users>1 then party.ready={}end;if e.room and e.room.practice then release(e,false)end
    elseif action=="vote"then ok=queue:vote(id,value)
    elseif action=="invite"then
        local function busy(en)return not between(en)end
        local other=finite(value)and entries[value]
        local why=party.leader~=id and '파티장 전용'or #party.users>=5 and '파티 가득 5/5'or busy(e)and '경기 중'
            or queue.membership[id]and '대기 중'or (not other or value==id or not user(value))and '다른 서버'
            or parties[value]and '다른 파티'or busy(other)and '상대 경기 중'
        if why then return {ok=false,message=why}end
        local now=os.clock();local Guards=require(pack.Core.AbuseGuards)
        e.inviteSentAt=e.inviteSentAt or {}
        for target,at in pairs(e.inviteSentAt)do if now-at>=Guards.inviteCooldown then e.inviteSentAt[target]=nil end end
        if e.inviteSentAt[value]then return {ok=false,message='초대 재사용 대기'}end
        e.inviteSentAt[value]=now
        invites[value]=invites[value]or {};invites[value][id]=now+60
        results:FireClient(other.player,{action='invite',ok=true,from=id,name=p.DisplayName,message=string.format('%s님이 파티에 초대했어요',p.DisplayName),version=other.version})
    elseif action=="accept"then
        local offer=invites[id]and invites[id][value];local host=entries[value];local target=group(value);local targetParty=parties[value]
        local function busy(en)return not between(en)end
        if not offer or offer<os.clock()or not host or not user(value)then return {ok=false,message='초대 만료'}end
        if busy(host)or queue.membership[value]or #target.users>=5 then return {ok=false,message='파티 출격 중'}end
        if busy(e)then return {ok=false,message='경기 중'}end
        if parties[id]then return {ok=false,message='이미 파티'}end
        if queue.membership[id]then local cancelled,why=queue:cancel(id,os.clock());if cancelled==false then return {ok=false,message=why}end end
        if entries[id]~=e or user(id)~=p or entries[value]~=host or not user(value)
            or parties[value]~=targetParty or parties[id]or busy(e)or busy(host)
            or e.loading or e.arriving or host.loading or host.arriving
            or queue.membership[id]or queue.membership[value]or #target.users>=5
            or not invites[id]or invites[id][value]~=offer or offer<os.clock()then
            return {ok=false,message='초대 만료'}
        end
        parties[value]=target;table.insert(target.users,id);target.ready=target.ready or {};target.ready[id]=true;target.mode='pvp';for _,u in ipairs(target.users)do parties[u]=target end;invites[id]=nil
        for _,u in ipairs(target.users)do local pl,en=user(u),entries[u]
            if pl and en and u~=id then results:FireClient(pl,{action='lobby',ok=true,message=string.format('%s님이 파티에 합류했어요',p.DisplayName),version=en.version})end
        end
        message=string.format('%s님의 파티에 합류했어요',user(value).DisplayName)
    elseif action=="decline"then
        local offer=invites[id]and invites[id][value];if invites[id]then invites[id][value]=nil end
        local host=finite(value)and entries[value]
        if offer and host and user(value)then results:FireClient(host.player,{action='lobby',ok=false,message=string.format('%s님이 초대를 거절했어요',p.DisplayName),version=host.version})end
    elseif action=="kick"then
        if party.leader~=id or not finite(value)or value==id or not table.find(party.users,value)then return {ok=false,message='파티장 전용'}end
        if queue.membership[value]or queue.membership[id]then return {ok=false,message='대기 중'}end
        table.remove(party.users,table.find(party.users,value));parties[value]=nil;party.ready={}
        if #party.users==1 then parties[party.users[1]]=nil end
        local gone=entries[value];if gone and user(value)then results:FireClient(gone.player,{action='lobby',ok=false,message='파티장이 파티에서 내보냈어요',version=gone.version})end
    elseif action=="leaveParty"then
        local q=parties[id]and party.leader~=id and queue:status(id,os.clock());local back=q and q.field and q.mode=='pvp'and not q.ladder and q.field:sub(1,7)~='custom-'and q.field
        local cancelled,why=queue:cancel(id,os.clock());if cancelled==false then return {ok=false,message=why}end
        if parties[id]then for i,u in ipairs(party.users)do if u==id then table.remove(party.users,i);break end end;parties[id]=nil
            party.ready={};if #party.users==1 then parties[party.users[1]]=nil elseif #party.users>1 then party.leader=party.users[1]end end
        local rest={};for _,u in ipairs(back and party.users or {})do if entries[u]and user(u)and between(entries[u])then table.insert(rest,u)end end
        if #rest>0 then for _,f in ipairs(queue:directory(rest[1]).fields)do if f.id==back then
            if queue:joinField(rest,{field=f.id,revision=f.revision},os.clock())then queued(rest,'official')else local le=entries[rest[1]];results:FireClient(le.player,{action='lobby',ok=false,message='전장 다시 선택',version=le.version})end
            break end end end
    elseif action=="leaders"then
        local rows=careers:leaders(true);return {ok=rows~=nil,leaders=rows}
    else ok=false;message="불가"end
    pushLobby();return {ok=ok,message=message,state=lobbySnapshot(id),teleport=teleport}
end
lobbyRequest.OnServerInvoke=function(p,action,value)
    local observedAt=os.clock()
    if type(action)~='string'or #action>32 then return {ok=false}end
    local actor=entries[p.UserId]
    if not actor then return {ok=false,busy=true}end
    actor.lobbyBudget=actor.lobbyBudget or {}
    local admitted,reason=require(pack.Core.LobbyRequestGate).take(actor.lobbyBudget,action,observedAt)
    if not admitted then return {ok=false,busy=reason=='busy',reason=reason}end
    if table.find({'joinField','join','play','again','customCreate','joinCode','rejoin'},action)then analytics:requested(p,'pvp')end
    local function invoke()
    local e=entries[p.UserId]
    local heavy=e and ({joinField=2,partyAnswer=2,join=2,play=2,again=2,customCreate=2,joinCode=2,hq=2,rejoin=2,replay=2,ranked=2,practice=1,spectate=1,ready=1,cancel=1,leaveParty=1,customUpdate=1,customReady=1,fieldReady=1,customStart=1,customLaunch=1,customTeam=1,selectMode=1,invite=1,accept=1,kick=1})[action]
    if action=='partyAnswer'then local ask=parties[p.UserId]and parties[p.UserId].ask;if not(type(value)=='table'and value.accept==true and ask and ask.id==value.id)then heavy=nil end end
    if not heavy then return lobbyHandle(p,action,value)end
    local cancelling=action=='cancel'or action=='leaveParty';local lock=cancelling and 'queueCancelBusy'or 'queueBusy'
    if e[lock]or not cancelling and e.queueCancelBusy or heavy==2 and os.clock()-(e.lastQueue or -math.huge)<1 then return {ok=false,message="다시 시도"}end
    local operation={};e[lock]=operation;if heavy==2 then e.lastQueue=os.clock()end
    local ok,result=pcall(lobbyHandle,p,action,value)
    if e[lock]==operation then e[lock]=nil end
    if not ok then warn('lobby',action,result);return {ok=false,message="다시 시도"}end
    return result
    end
    local result=invoke()
    analytics:lobby(p,action,result,parties[p.UserId],queue:status(p.UserId,os.clock()))
    if action~='read'then analytics:service(p,'queue_update',type(result)=='table'and result.ok==true,observedAt)end
    return result
end
if Run:IsStudio()then
    local launchQA=Instance.new('BindableFunction');launchQA.Name='FrontierLaunchQA';launchQA.Parent=game.ServerScriptService
    launchQA.OnInvoke=function(userId,kind,arg)
        local e=entries[userId];local p=user(userId);if not e or not p then return nil end
        if kind=='level'then
            assert(accounts.localMode,'Local Studio memory only')
            for n=1,40 do
                local view=accounts:snapshot(p).progress or {};if (view.level or 1)>=arg then break end
                local now=os.time();local day,week=Outgame.day(now),Outgame.week(now)
                assert(accounts:applyProgress(userId,{id='launch-qa-level-'..n,revision=1,mode='coop',map='world',humans=2,seconds=1800,cities=6,supports=12,peak=.4,outcome='won',time=now,final=true,days={[day]={seconds=1800,cities=6,finished=1}},weeks={[week]=1800},weeklyActions={[week]={cities=6,supports=12}},milestones={}}))
            end
        end
        local room=e.room;local view=accounts:snapshot(p).progress or {}
        local out={queued=queue.membership[userId]and queue.membership[userId].mode or nil,party=#group(userId).users,arriving=e.arriving==true,clan=p:GetAttribute('CommanderClan'),xp=view.xp,level=view.level,medals=view.medals,basics=view.basicsComplete==true}
        if room then
            out.room={key=tostring(room):sub(-8),casual=room.casual==true,intro=room.intro==true,practice=room.practice==true,single=room.single==true,daily=room.daily,ended=room.endedAt~=nil,phase=room.session.phase,humans=(function()local n=0;for _ in pairs(room.members)do n+=1 end;return n end)()}
            local other=kind=='allied'and entries[arg]
            if other then out.allied=other.room==room and room.session:friendly(e.faction,other.faction)==true end
        end
        return out
    end
end
queue:start({
    joinGuard=queueJoinGuard,
    trophyAllowed=function()return ranked:trophyAllowed()end,
    recoveryGuard=queueRecoveryGuard,
    noShow=function(id,matchId,time)return ranked:noShow(id,matchId,time)end,
    departing=function(ids)for _,uid in ipairs(ids)do waited(uid,'QueueWait',nil,'transfer')end;pcall(function()accounts.comeback:sortie(ids)end)end,
    failed=function(p)analytics:custom(p,'TransferFailed',nil,'pvp',1)end,
    hasLobby=function()for _,e in pairs(entries)do if not e.room or e.room.practice then return true end end;return false end,
    create=function(selection)
        local deadline=os.clock()+8
        for _,id in ipairs(selection.users or {})do while os.clock()<deadline do local p=user(id);local a=p and accounts:snapshot(p);if not a or a.ready or not a.loading then break end;task.wait(.1)end end
        return createRoom(selection,false)
    end,
    notify=function(id,message)local p=user(id);local e=entries[id];if p and e then results:FireClient(p,{action='lobby',ok=true,message=message,version=e.version});lobbyState:FireClient(p,lobbySnapshot(id))end end,
    claimed=function(id,rules,m,hint)local p=user(id);if p then bigMaps:arrive(p,rules);bigMaps.roster:arrive(p,hint,m)end end,
    arrival=function(id,waiting)local e=entries[id];if not waiting and user(id)then bigMaps.roster:leave(user(id))end;if e then e.arriving=waiting;if user(id)and not(e.room and not e.room.endedAt and not e.room.practice)then updates:FireClient(e.player,baseState(e))end end end,
})
soloTransfer=require(services.SoloTransfer).new(Config,{
    waiting=function(id,value)local e=entries[id];if e then e.arriving=value;if user(id)and not(e.room and not e.room.endedAt and not e.room.practice)then updates:FireClient(e.player,baseState(e))end end end,
    notify=function(id,message)local e=entries[id];local p=user(id);if e and p then results:FireClient(p,{action='lobby',ok=false,message=message,version=e.version})end end,
    create=function(id,ticket)
        local e=entries[id];if not e or e.room then return false end
        local player,version=e.player,e.version
        local goal=ticket.goal==true;local temporary=goal or ticket.quick==true
        if temporary then
            local deadline=os.clock()+10;local account
            repeat
                if entries[id]~=e or not user(id)then return false end
                account=accounts:snapshot(user(id));if not account.ready then task.wait(.1)end
            until account.ready or os.clock()>=deadline
            if not account.ready or entries[id]~=e or user(id)~=player or e.version~=version or e.room or e.loading then return false end
            e.settings=Outgame.copy(account.progress.single.settings);e.singleMap=account.progress.single.map;e.settingsTouched=true
        else
            local deadline=os.clock()+8
            while os.clock()<deadline and entries[id]==e and user(id)do local a=accounts:snapshot(user(id));if a.ready or not a.loading then break end;task.wait(.1)end
            if entries[id]~=e or user(id)~=player or e.version~=version or e.room or e.loading then return false end
            e.settings=Outgame.copy(ticket.settings);e.singleMap=ticket.map;e.settingsTouched=true
        end
        local daily=ticket.daily and require(pack.Core.DailyOperation).of(ticket.daily)
        local stage=ticket.campaign and Outgame.campaign.stage(ticket.campaign)
        return createRoom({users={id},teams={},mode='single',map=daily and daily.map or stage and stage.map or ticket.map,intro=ticket.intro,rewardMode=ticket.rewardMode,daily=daily or nil,campaign=stage and stage.id or nil,soloTransfer=true,goal=goal,quick=ticket.quick,resumeSettings=temporary and Outgame.copy(ticket.settings)or nil},true)
    end,
})
local world=Instance.new("Folder");world.Name="FrontierWorld";world.Parent=workspace
soloTransfer.telemetry=analytics
require(pack.Client.ToyLighting).apply()
local floor=Instance.new("Part");floor.Name="MapTable";floor.Size=Vector3.new(1800,4,1800);floor.Position=Vector3.new(0,Geometry.surfaceY-2,0);floor.Anchored=true;floor.Transparency=1;floor.Parent=world
task.spawn(function()local at=os.clock();Plaza.create(world,function(p,mode)local e=entries[p.UserId];if e and not e.room then local s=lobbySnapshot(p.UserId);if mode=="wardrobe"or mode=="records"then s.openPage=mode else s.openMode=mode end;lobbyState:FireClient(p,s)end end);workspace:SetAttribute("PlazaBuildSeconds",os.clock()-at)end)
local backdrop=Instance.new("Part");backdrop.Name="Backdrop";backdrop.Size=Vector3.new(2048,1,2048);backdrop.Position=Vector3.new(0,Geometry.surfaceY-7,0);backdrop.Anchored=true;backdrop.CanCollide=false;backdrop.CanTouch=false;backdrop.CanQuery=false;backdrop.Material=Enum.Material.SmoothPlastic;backdrop.Color=Color3.fromRGB(9,13,18);backdrop.Parent=world
local physics=game:GetService("PhysicsService");pcall(function()physics:RegisterCollisionGroup("FrontierCommanders")end);physics:CollisionGroupSetCollidable("FrontierCommanders","FrontierCommanders",false)
local function characterAdded(p,c)
    local root=c:WaitForChild("HumanoidRootPart",10);local hum=c:FindFirstChildOfClass("Humanoid");if not root or not hum or p.Parent~=Players or p.Character~=c then return end
    hum.WalkSpeed=34;hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,false);hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
    c:SetAttribute('ToyfrontBaseScale',c:GetScale());c:SetAttribute('ToyfrontGrowth',1)
    local function collision(o)if o:IsA("BasePart")then o.CollisionGroup="FrontierCommanders"end end
    for _,o in ipairs(c:GetDescendants())do collision(o)end;c.DescendantAdded:Connect(collision)
    local label=Instance.new("BillboardGui");label.Name="CommanderName";label.Adornee=root;label.Size=UDim2.fromOffset(170,30);label.StudsOffsetWorldSpace=Vector3.new(0,3.5,0);label.MaxDistance=500;label.Parent=c
    local text=Instance.new("TextLabel");text.AutoLocalize=false;text.AnchorPoint=Vector2.new(.5,.5);text.Position=UDim2.fromScale(.5,.5);text.Size=UDim2.fromOffset(0,24);text.AutomaticSize=Enum.AutomaticSize.X;text.BackgroundColor3=Color3.fromRGB(11,15,20);text.BackgroundTransparency=.25;text.BorderSizePixel=0;text.Font=Enum.Font.BuilderSansBold;text.Text=p.DisplayName;text.TextSize=13;text.TextColor3=Color3.fromRGB(238,242,246);text:SetAttribute("LocalizationSkip",true);text.Parent=label
    local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,8);pad.PaddingRight=UDim.new(0,8);pad.Parent=text;local edge=Instance.new("UIStroke");edge.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;edge.Color=Color3.fromRGB(38,50,65);edge.Parent=text
    local e=entries[p.UserId];local room=e and e.room;local spawned=room and room.session.spawned
    local tile=room and (room.single and room.session.spawnTile or spawned and spawned[e.faction]);placeCharacter(p,tile,room)
    hum.Died:Connect(function()task.delay(2,function()characters:request(p,c)end)end)
end
local function added(p)
    analytics:joined(p)
    local e=entries[p.UserId]
    if e and e.room and e.disconnectedAt and os.clock()-e.disconnectedAt<=Config.reconnectSeconds then analytics:flow(p,'match','rejoin',{elapsed_seconds=os.clock()-e.disconnectedAt,result='accepted'});e.player=p;e.disconnectedAt=nil;e.version=nextVersion();p:SetAttribute("FrontierRoom",e.room.id)
        if e.room.single and e.room.paused and e.room.pausedByLeave then e.room.paused=false;e.room.pausedByLeave=nil end
        if e.markedAway then
            e.markedAway=nil;local room=e.room;local s=room.session
            if not room.single and not room.endedAt and s:markDisconnected(e.faction,false) and room.replayLog then room.replayLog:add(s.sim.ticks,e.faction,'reconnect')end
        end
    else local a=accounts:snapshot(p);local saved=a.progress and a.progress.single
        e={player=p,settings=Outgame.copy(saved and saved.settings or defaults),singleMap=saved and saved.map or 'world',version=nextVersion()};entries[p.UserId]=e end
    local joined,join=pcall(function()return p:GetJoinData()end)
    if joined and type(join.LaunchData)=='string'and #join.LaunchData<256 then
        local decoded,launch=pcall(function()return game.HttpService:JSONDecode(join.LaunchData)end)
        if decoded and type(launch)=='table'and type(launch.commanderRoom)=='string'and launch.commanderRoom:match('^%x%x%x%x%x%x%x%x$')then e.inviteRoomCode=launch.commanderRoom end
        if decoded and type(launch)=='table'and finite(launch.party)then e.partyHost=launch.party end
    end
    local hop=joined and type(join.TeleportData)=='table'and join.TeleportData.party
    local hopId=joined and type(join.TeleportData)=='table'and join.TeleportData.hop
    e.hopId=type(hopId)=='string'and #hopId<=64 and hopId or nil
    if not e.partyHost and finite(hop)then e.partyHost=hop end
    if not e.partyHost and p.FollowUserId>0 then e.partyHost=p.FollowUserId end
    if e.partyHost==p.UserId or e.inviteRoomCode then e.partyHost=nil end
    if e.partyHost then
        local host=e.partyHost;e.partyHostUntil=os.clock()+600
        task.spawn(function()
            local ok,friend=pcall(function()return p:IsFriendsWith(host)end)
            if e.partyHost~=host then return end
            if ok and friend then e.partyFriend=true;joinFriend(p.UserId)
            elseif e.hopId then e.partyFriend='hop';e.partyHostUntil=os.clock()+60;joinFriend(p.UserId)
            else e.partyHost=nil end
        end)
    end
    local stats=Instance.new("Folder");stats.Name="leaderstats";stats.Parent=p;for _,name in ipairs({"점유율","병력","골드"})do local v=Instance.new("NumberValue");v.Name=name;v.Parent=stats end
    p.CharacterAdded:Connect(function(c)characterAdded(p,c)end);characters:request(p)
    local watching=joined and type(join.TeleportData)=='table'and join.TeleportData.superCommanderSpectate
    local world,together,leader=worldField:arrival(p)
    if world and not e.room then worldField.seat(p,e,together,leader)
    elseif type(watching)=='string'and #watching<=64 and not e.room then
        task.spawn(function()
            local target
            for _=1,10 do for _,r in ipairs(rooms)do if r.globalMatch==watching then target=r;break end end;if target or p.Parent~=Players then break end;task.wait(1)end
            local ok,message=false,'관전 경기 종료'
            if target and p.Parent==Players and not e.room then ok,message=observe(e,target)end
            if p.Parent==Players then results:FireClient(p,{action='lobby',ok=ok,message=message,version=e.version})end
        end)
    elseif not e.room and not soloTransfer:arrival(p)then queue:arrival(p)end
    task.spawn(function()careers:load(p.UserId);task.spawn(function()local paid=ranked:claim(p);if paid and p.Parent==Players then results:FireClient(p,{action='lobby',ok=true,message=string.format('지난 시즌 %s 랭크 보상 +%d 코인',require(pack.Core.RankedRules).bandName(paid.band),paid.coins)})end end);if p.Parent==Players then lobbyState:FireClient(p,lobbySnapshot(p.UserId));updates:FireClient(p,snapshot(e,true))end end)
    task.spawn(function()for attempt=1,3 do if rewards:recover(p.UserId)then break end;task.wait(attempt*2)end end)
end
pcall(function()workspace:SetAttribute("ServerReadySeconds",os.clock()-bootAt)end)
Players.PlayerAdded:Connect(added);for _,p in ipairs(Players:GetPlayers())do added(p)end
bigMaps.missing=function(p)local e=entries[p.UserId];if e and e.room and user(p.UserId)==p then updates:FireClient(p,snapshot(e,true))end end
Players.PlayerRemoving:Connect(function(p)
    characters:forget(p)
    analytics:leaving(p);badgeSent[p.UserId]=nil
    soloTransfer:leaving(p.UserId);liveMatches:leaving(p.UserId);worldField:leaving(p.UserId);bigMaps:leave(p);bigMaps.roster:leave(p)
    if entries[p.UserId]and entries[p.UserId].observer then unobserve(entries[p.UserId],true)end
    local e=entries[p.UserId];task.spawn(function()queue:cancel(p.UserId,os.clock(),true)end)
    local party=parties[p.UserId];if party then for i,id in ipairs(party.users)do if id==p.UserId then table.remove(party.users,i);break end end;party.ready={};parties[p.UserId]=nil;if #party.users==1 then parties[party.users[1]]=nil elseif #party.users>0 then party.leader=party.users[1]end end
    if e and e.room and e.room.single and not e.room.paused then e.room.paused=true;e.room.pausedByLeave=true end
    if e then if not e.disconnectedAt then e.disconnectedAt=os.clock()end;local pr=e.room and e.room.progress[p.UserId]
        if pr and e.room.intro and not pr.ended then pr.basicsComplete=true;pr:finish('forfeit',os.time(),true)end
        if pr then recordProgress(p.UserId,pr)end end
end)
local function finish(room)
    room.endedAt=os.clock()
    local s=room.session
    local before={};for id in pairs(room.members)do before[id]=(careers.profiles[id]or {}).rating or 1000 end
    for id,faction in pairs(room.members)do
        local p=s.sim.players[faction];local forfeited=s.resources[faction].forfeited==true
        local won=not forfeited and (s.winnerTeam and p.team==s.winnerTeam or s.winnerId==faction)
        if room.casual and os.time()-(room.joined[id]or room.startedAt)<Casual.winSeconds then won=false end
        local progress=room.progress[id];if progress then if room.intro then progress.basicsComplete=true end;progress:finish(won and 'won'or forfeited and 'forfeit'or 'lost',os.time(),true);recordProgress(id,progress)end
        if room.single then continue end
        local eligible=room.mode=="duel" and #s.roster==2 and os.time()-room.startedAt>=60
        local opponent=1000;for other in pairs(room.members)do if other~=id then opponent=before[other]end end
        local humans=0;for _ in pairs(room.members)do humans+=1 end
        local career={id=room.id,startedAt=room.startedAt,won=won==true,forfeited=forfeited,ranked=Config.rankedEnabled and room.mode=="duel",eligible=eligible,opponent=opponent,counted=(room.official or room.ranked~=nil or room.mode=="duel")and humans>=2}
        for k,v in pairs(ranked:result(room,id,won==true)or {})do career[k]=v end
        careers:record(id,career)
    end
    if room.clanwar then task.spawn(ranked.clanWarResult,ranked,room)end
    local log=room.replayLog
    if log and not log.overflow then
        local winner=s.winnerId and s.resources[s.winnerId]and s.resources[s.winnerId].name or nil
        local rows={};local seconds=os.time()-room.startedAt;local mode=LiveModel.mode(s)
        for faction,r in pairs(s.roster)do if r.userId and s.sim.players[faction].kind=='HUMAN'then
            local p=s.sim.players[faction];local won=not s.resources[faction].forfeited and (s.winnerTeam and p.team==s.winnerTeam or s.winnerId==faction)
            rows[r.userId]=ReplayLog.row(room.id,log.header,seconds,won and 'won'or 'lost',mode)
        end end
        replayStore:save(room.id,log:finish(s.sim.ticks,winner),rows)
        room.replayLog=nil
    end
end
local lobbyTimer=0
local function stepRoom(room,dt,now)
        if room.warming then return end
        local s=room.session
        local okA,errA=pcall(analytics.room,analytics,room,now);if not okA then warn('TOYFRONT telemetry room error',room.id,errA)end
        if s.phase=='spawn'and room.drop then DropService.step(room,now,function(id,tile)
            local p=room.session.roster and room.session.roster[id]and user(room.session.roster[id].userId)or room.single and user(next(room.members))
            if p then emit(room,p,'settle',tile)end
        end)
            if room.single and s.phase=='playing'then local p=user(next(room.members));if p then placeCharacter(p,s.spawnTile,room)end;sendRoom(room,true)end
        end
        if not room.single and not room.drop and s.phase=="spawn" and not room.allSpawned then
            local all=true;for id,faction in pairs(room.members)do local e=entries[id];if e and e.room==room and not s.spawned[faction]then all=false end end
            if all then room.allSpawned=true;room.spawnUntil=math.min(room.spawnUntil,now+Config.spawnCountdownSeconds)end
        end
        if s.phase=="spawn" and s.spawnStep and not room.replay and not room.intro and not room.paused and (not room.drop or room.drop.startAt)then
            room.spawnClock=(room.spawnClock or 0)+dt;local n=0
            while room.spawnClock>=.1 and n<5 do
                room.spawnClock-=.1;n+=1
                if room.replayLog then room.replayLog:add(s.sim.ticks,0,'spawnTick')end;s:spawnStep()
            end
            pushOwnership(room)
        end
        if not room.single and s.phase=="spawn" and now>=room.spawnUntil then if room.replayLog then room.replayLog:add(s.sim.ticks,0,'start')end;s:startBattle();participants(room,function(p,e)placeCharacter(p,s.spawned[e.faction],room)end);sendRoom(room,true)end
        if room.paused and room.pauseLimit and os.clock()>room.pauseLimit then room.paused=false;room.pauseLimit=nil;if room.pauseFrom then room.pauseSpent=(room.pauseSpent or 0)+os.clock()-room.pauseFrom;room.pauseFrom=nil end end
        if s.phase=="playing" and not room.paused and not room.awaitFirst then
            local speed=math.min(8,(room.replay and room.replay.speed or room.single and room.speed or 1)*GameSpeed.of(s.settings))
            room.accumulator=math.min(room.accumulator+dt*speed,.5*math.max(1,speed));local ticks=math.min(5*math.max(1,speed),math.floor(room.accumulator/.1))
            for _=1,ticks do if room.replay then ReplayLog.feed(room.replay.cursor,s,RoomCommands.replay)end;local c0=os.clock();s:step();PerfStats.add(room,'tick',os.clock()-c0);room.accumulator-=.1 end
            pushOwnership(room)
        end
        room.progressTimer+=dt
        for id,faction in pairs(room.members)do
            local e=entries[id];local pr=room.progress[id]
            local connected=e and e.room==room and not e.disconnectedAt and user(id)~=nil
            if not room.single and not room.endedAt and e and e.room==room and e.disconnectedAt and not e.markedAway and os.clock()-e.disconnectedAt>=Config.disconnectMarkSeconds then
                e.markedAway=true;if s:markDisconnected(faction,true) and room.replayLog then room.replayLog:add(s.sim.ticks,faction,'disconnect')end
            end
            pr:step(s,faction,math.min(dt,.5),os.time(),connected,room.paused)
            if (room.daily or room.campaign) and not pr.ended then pr.gameSeconds=math.floor(GameSpeed.seconds(s.settings,s.sim.ticks))end
            if connected then analytics:observe(e.player,pr,s.map.meta.key,pr.mode)end
            local guide=room.guides[id]
            if guide then
                guide:step(s,faction,room.paused)
                if (guide.stage=='done'and not room.intro or room.intro and (s.phase=='won'or s.phase=='lost'))and not pr.basicsComplete then pr.basicsComplete=true;recordProgress(id,pr)
                    if pr.unrecorded and room.intro and accounts:snapshot(e.player).ready then task.spawn(function()pcall(function()accounts:updateProgress(id,function(p)if p.outgame.basicsComplete then return nil end;p.outgame.basicsComplete=true;return p end)end)end)end
                end
            end
            local p=s.sim.players[faction]
            if pr.spawnedAt and not pr.ended and (p.tiles.size==0 or s.resources[faction].forfeited)then
                if room.intro then pr.basicsComplete=true end
                pcall(function()
                    local function who(by)local q=by and s.sim.players[by];return q and ({BOT='Tribe',NATION='Nation',HUMAN='Human'})[q.kind]or 'Other'end
                    local annexed=s.clusterRules and s.clusterRules.annexed and s.clusterRules.annexed[faction];local taken=s.fallenTo and s.fallenTo[faction]
                    local nuked=s.nukedAt and s.nukedAt[faction];nuked=nuked and s.sim.ticks-nuked<=30
                    pr.lostCause=s.resources[faction].forfeited and 'forfeit'or annexed and 'encircled'..who(annexed)or nuked and not taken and 'nuked'or taken and 'conquered'..who(taken)or 'lostLand'
                    local seat=room.drop and room.drop.players[faction];pr.landing=room.randomSpawn and 'random'or seat and seat.fallback and 'shifted'or seat and 'selected'or 'unknown'
                    pr.away=(e and e.markedAway)==true or s:away(faction)==true
                end)
                pr:finish(s.resources[faction].forfeited and 'forfeit'or 'lost',os.time(),room.single or room.endedAt~=nil);recordProgress(id,pr)
            elseif pr.dirty and room.progressTimer>=60 then recordProgress(id,pr)end
        end
        if room.progressTimer>=60 then room.progressTimer=0 end
        if s.winnerId and not room.endedAt then finish(room)end
        if room.casual and room.endedAt and not room.rolled and now>=room.endedAt+Config.resultSeconds then
            room.rolled=true;local ids={}
            for id in pairs(room.members)do local e=entries[id];if e and e.room==room and not e.disconnectedAt and user(id)then table.insert(ids,id)end end
            if #ids>0 then task.defer(function()local ok,why=joinCasual(ids);if not ok then warn('casual rollover',why)end end)end
        end
        room.display+=dt;if room.display>=.3 then
            local elapsed=room.display;room.display=0;sendRoom(room,false)
            participants(room,function(p,e)
                local c=p.Character;local faction=s.sim.players[e.faction]
                if c and c:GetAttribute('ToyfrontBaseScale')and faction then
                    local old=c:GetAttribute('ToyfrontGrowth')or 1
                    local target=CommanderScale.target(faction.tiles.size,s:landTiles(),faction.troops)
                    local scale=CommanderScale.approach(old,target,elapsed)
                    if math.abs(scale-old)>=.002 then c:SetAttribute('ToyfrontGrowth',scale)end
                    local step=math.floor((scale-1)*4+.001)
                    if step>(c:GetAttribute('ToyfrontGrowthStep')or 0)then c:SetAttribute('ToyfrontGrowthStep',step);emit(room,p,'grow')end
                end
            end)
        end
        participants(room,function(p,e)
            local c=p.Character;local r=c and c:FindFirstChild("HumanoidRootPart");local hum=c and c:FindFirstChildOfClass("Humanoid")
            local speed=room.paused and 0 or 34;if hum and hum.WalkSpeed~=speed then hum.WalkSpeed=speed end
            if r then local x,z=s.map.meta.width*Geometry.scale/2-1,s.map.meta.height*Geometry.scale/2-1;local at=r.Position;if math.abs(at.X)>x or math.abs(at.Z)>z or at.Y<Geometry.surfaceY-2 then r.CFrame=CFrame.new(math.clamp(at.X,-x,x),Geometry.surfaceY+4,math.clamp(at.Z,-z,z));r.AssemblyLinearVelocity=Vector3.zero end end
        end)
        if room.replay and not room.endedAt and s.sim.ticks>=(room.replay.endTick or 0)+600 then room.endedAt=now end
        local retained=room.replay~=nil and next(room.observers or {})~=nil;for id in pairs(room.members)do local e=entries[id];if e and e.room==room then
            if e.disconnectedAt and now-e.disconnectedAt>Config.reconnectSeconds then
                local pr=room.progress[id];if pr and not pr.ended then pr:finish('expired',os.time(),true);recordProgress(id,pr)end
                if room.casual then if not room.endedAt then s:handBack(e.faction)end;room.members[id]=nil
                elseif not room.single and not room.endedAt then if s:markDisconnected(e.faction,true) and room.replayLog then room.replayLog:add(s.sim.ticks,e.faction,'disconnect')end end
                e.room=nil;e.stateStream=nil;e.markedAway=nil else retained=true end
        end end
        if room.endedAt and now>=room.endedAt+Config.resultSeconds then observers(room,function(_,e)unobserve(e)end)end
        if not retained then
            for id,pr in pairs(room.progress)do if not pr.final then pr:finish(pr.outcome or 'serverStop',os.time(),true);recordProgress(id,pr)end end
            observers(room,function(_,e)unobserve(e)end)
            local k=table.find(rooms,room);if k then table.remove(rooms,k)end
        end
end
local rankedSeasonSeen=require(pack.Core.MonthlySeason).number(os.time())
local function lobbyTick(now)
        local sn=require(pack.Core.MonthlySeason).number(os.time())
        if sn~=rankedSeasonSeen then rankedSeasonSeen=sn
            for _,p in ipairs(Players:GetPlayers())do task.spawn(function()local paid=ranked:claim(p);if paid and p.Parent==Players then results:FireClient(p,{action='lobby',ok=true,message=string.format('지난 시즌 %s 랭크 보상 +%d 코인',require(pack.Core.RankedRules).bandName(paid.band),paid.coins)})end end)end
        end
        for id,e in pairs(entries)do
            if e.disconnectedAt and now-e.disconnectedAt>Config.reconnectSeconds and not e.room and not e.loading and not e.savingLobby and not user(id)then
                entries[id]=nil;invites[id]=nil;rewards.worker:stopRecovering(id)
                for _,offers in pairs(invites)do offers[id]=nil end
            end
        end
        for id,offers in pairs(invites)do
            for from,expires in pairs(offers)do if expires<=now or not user(from)then
                offers[from]=nil;local host=entries[from];local guest=user(id)
                if host and guest and user(from)then results:FireClient(host.player,{action='lobby',ok=false,message=string.format('%s님이 초대에 응답하지 않았어요',guest.DisplayName),version=host.version})end
            end end
            if not next(offers)then invites[id]=nil end
        end
        for id,e in pairs(entries)do if e.partyHost then joinFriend(id)end end
        careers:forgetDeparted(entries)
        replayStore:forgetDeparted(entries)
        liveMatches:sync(rooms)
        for _,e in pairs(entries)do if e.player.Parent==Players then matchChat:sync(e)end end
        matchChat:clean()
        for _,e in pairs(entries)do if not e.room and e.player.Character then local r=e.player.Character:FindFirstChild("HumanoidRootPart");if r and (r.Position.Y<PlazaLayout.y-3 or math.abs(r.Position.X-PlazaLayout.x)>PlazaLayout.width/2+4 or math.abs(r.Position.Z-PlazaLayout.z)>PlazaLayout.depth/2+4)then placeCharacter(e.player,nil,nil)end end end
        for _,mode in ipairs({"pvp","coop"})do if not full(false)then local selection=queue:take(mode,now);if selection then
            local ok,message=createRoom(selection,false);if not ok then for _,id in ipairs(selection.users)do local p=user(id);if p then results:FireClient(p,{action="lobby",ok=false,message=message})end end end
        end end end
        pushLobby()
end
local function quarantine(room,err)
    warn('TOYFRONT room closed after repeated errors',room.id,err)
    for id,pr in pairs(room.progress or {})do if not pr.final then pcall(function()pr:finish(pr.outcome or 'serverStop',os.time(),true);recordProgress(id,pr)end)end end
    for id in pairs(room.members or {})do local e=entries[id];if e and e.room==room then pcall(release,e,false);local p=user(id);if p then results:FireClient(p,{action='lobby',ok=false,message='경기 오류  기록 저장됨'})end end end
    observers(room,function(_,e)pcall(unobserve,e)end)
    local k=table.find(rooms,room);if k then table.remove(rooms,k)end
end
Run.Heartbeat:Connect(function(dt)
    local now=os.clock();lobbyTimer+=dt
    for i=#rooms,1,-1 do
        local room=rooms[i]
        if room and not shuttingDown then
            local ok,err=pcall(stepRoom,room,dt,now)
            if ok then room.faults=nil
            else
                room.faults=(room.faults or 0)+1;warn('TOYFRONT room step error',room.id,room.faults,err)
                if room.faults>=3 then quarantine(room,err)end
            end
        end
    end
    if lobbyTimer>=1 then
        lobbyTimer=0
        local ok,err=pcall(lobbyTick,now);if not ok then warn('TOYFRONT lobby tick error',err)end
        if worldField:hosting()and not shuttingDown then pcall(function()worldField:publish(worldField.rooms(),not full(false))end)end
    end
end)
require(services.OpsService).start({
    inMatch=function(p)local e=entries[p.UserId];return e~=nil and(e.room~=nil or e.loading==true or e.arriving==true)end,
    partyOf=function(p)return group(p.UserId)end,
    onHold=function(message)
        local seated={};for id,e in pairs(entries)do if queue.membership[id]and e.player.Parent==Players then seated[id]=e end end
        for id,e in pairs(seated)do if queue.membership[id]and e.player.Parent==Players then
            local ok=pcall(function()return queue:cancel(id,os.clock())end)
            if ok then analytics:queueExit(e.player,'cancelled')end
            if e.player.Parent==Players then results:FireClient(e.player,{action='lobby',ok=false,message=message,version=e.version})end
        end end
        pushLobby()
    end,
})
print("TOYFRONT MULTIPLAYER READY: independent rooms, 1-20 humans, teams/co-op, solo; ranked follows LiveConfig ranked")
require(services.CloseHook)(function()
    shuttingDown=true;characters:close()
    for _,room in ipairs(rooms)do for id,progress in pairs(room.progress)do
        if not progress.final then
            if not progress.ended and not room.intro and not room.endedAt then progress.voided=true end
            progress:finish('serverStop',os.time(),true);recordProgress(id,progress)
        end
    end end
    local deadline=os.clock()+24
    repeat rewards:pulse();task.wait(.25)until not next(rewards.pending)and not next(rewards.busy)and replayStore.pending==0 or os.clock()>=deadline
end)
