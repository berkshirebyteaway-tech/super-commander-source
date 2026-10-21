local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Messaging=game:GetService('MessagingService')
local pack=game.ReplicatedStorage:WaitForChild('FrontierNative')
local Rules=require(pack.Core.OpsRules)
local Live=require(script.Parent.LiveConfig)
local Config=require(script.Parent.OpsConfig)
local M={}
local TOPIC='SC-Ops-v1'
local studio=Run:IsStudio()
local live=not studio and game.GameId>0
local public=game.PrivateServerId==''
local startedAt=os.time()
local admins,checking={},{}
local deps
local state='normal'
local flash={text='',textEn='',untilAt=0}
local lastRequest={}
local maintenanceSince
local latest=game.PlaceVersion
local freeSince,hops,moving,failures={},{},{},{}

local function en(p)return p.LocaleId:sub(1,2)~='ko'end
local function audit(entry)
    entry.at=os.time();print('SC OPS',game:GetService('HttpService'):JSONEncode(entry))
    if not live then return end
    task.spawn(function()pcall(function()
        game:GetService('DataStoreService'):GetDataStore(Config.auditStore):UpdateAsync('log',function(old)
            old=type(old)=='table'and old or {};table.insert(old,1,entry);while #old>Config.auditKeep do table.remove(old)end;return old
        end)
    end)end)
end
function M.isAdmin(p)
    if studio then return true end
    local id=p.UserId
    if admins[id]~=nil then return admins[id]end
    if table.find(Config.adminIds,id)then admins[id]=true;return true end
    if checking[id]then return false end
    checking[id]=true
    local ok,rank=pcall(function()return p:GetRankInGroup(Config.groupId)end)
    checking[id]=nil
    if ok then admins[id]=type(rank)=='number'and rank>=Config.groupRank;return admins[id]end
    return false
end
local function isOutdated()
    if not live or Live.get('softUpdate')==false then return false end
    return Rules.outdated(game.PlaceVersion,latest)
end
local function liveCfg()
    return {closeAt=Live.get('closeAt'),reopenAt=Live.get('reopenAt'),maintenance=Live.get('maintenance'),
        closeWarnMinutes=Live.get('closeWarnMinutes'),closeGateMinutes=Live.get('closeGateMinutes')}
end
function M.phase()return Rules.phase(liveCfg(),os.time(),startedAt,isOutdated())end
function M.blocked(action,p)
    if not Rules.holds(state,action)then return nil end
    if state=='outdated'and p then
        if (hops[p.UserId]or 0)>=Rules.moveMaxHops then return nil end
        local since=os.time()-math.max(0,(tonumber(Live.get('updateMoveSeconds'))or Rules.moveSeconds)-5)
        freeSince[p.UserId]=math.min(freeSince[p.UserId]or since,since)
    end
    return Rules.heldMessage(state)
end
local function publish(p)
    pack:SetAttribute('OpsState',p.state);pack:SetAttribute('OpsCloseAt',p.closeAt or 0);pack:SetAttribute('OpsReopenAt',p.reopenAt or 0)
    pack:SetAttribute('OpsTicker',Rules.line(Live.get('ticker'))or '');pack:SetAttribute('OpsTickerEn',Rules.line(Live.get('tickerEn'))or '')
    pack:SetAttribute('OpsFlash',flash.text);pack:SetAttribute('OpsFlashEn',flash.textEn);pack:SetAttribute('OpsFlashUntil',flash.untilAt)
end
local function applyFlash(data)
    if type(data)~='table'then return end
    local text=Rules.line(data.text);local untilAt=tonumber(data.untilAt)
    if not text or not untilAt then flash={text='',textEn='',untilAt=0}else flash={text=text,textEn=Rules.line(data.textEn)or '',untilAt=untilAt}end
    publish(M.phase())
end
local function kickLocal(userId,message,messageEn)
    local p=Players:GetPlayerByUserId(userId);if not p then return false end
    p:Kick(en(p)and messageEn or message);return true
end
local function onMessage(message)
    local data=message.Data;if type(data)~='table'then return end
    if data.op=='version'then local v=tonumber(data.v);if v and v>latest then latest=v end
    elseif data.op=='flash'then applyFlash(data)
    elseif data.op=='kick'and type(data.userId)=='number'then kickLocal(data.userId,'운영자가 연결을 끊었어요.','You were disconnected by an operator.')end
end
local function broadcast(data)
    onMessage({Data=data})
    if not live then return true end
    return pcall(function()Messaging:PublishAsync(TOPIC,data)end)
end
local function maintenanceSweep(p)
    if p.state~='maintenance'then maintenanceSince=nil;return end
    maintenanceSince=maintenanceSince or os.clock()
    local now=os.time()
    for _,player in ipairs(Players:GetPlayers())do
        local known=studio or admins[player.UserId]~=nil
        local inMatch=deps.inMatch and deps.inMatch(player)
        local joinedAt=player:GetAttribute('OpsJoinedAt')or 0
        local grace=os.clock()-math.max(maintenanceSince,public and 0 or joinedAt)>=Rules.graceSeconds or public and joinedAt>=maintenanceSince
        if known and not inMatch and grace and not M.isAdmin(player)then player:Kick(Rules.kickMessage(p,now,en(player)))end
    end
end
local function teleportGroup(players,leader)
    local options=Instance.new('TeleportOptions')
    local count=0;for _,pl in ipairs(players)do count=math.max(count,hops[pl.UserId]or 0)end
    options:SetTeleportData({party=#players>1 and leader or nil,hop=#players>1 and game:GetService('HttpService'):GenerateGUID(false)or nil,opsMove=count+1})
    for _,pl in ipairs(players)do moving[pl.UserId]=os.time()end
    local ok,err=pcall(function()game:GetService('TeleportService'):TeleportAsync(game.PlaceId,players,options)end)
    if not ok then warn('SC OPS move failed',err);for _,pl in ipairs(players)do moving[pl.UserId]=nil;failures[pl.UserId]=(failures[pl.UserId]or 0)+1;freeSince[pl.UserId]=os.time()end end
    print('SC OPS move',#players,ok)
end
local function moveSweep()
    if state~='outdated'then
        for _,pl in ipairs(Players:GetPlayers())do if pl:GetAttribute('OpsMoveAt')~=nil then pl:SetAttribute('OpsMoveAt',nil)end end
        table.clear(freeSince);return
    end
    local now=os.time();local delay=tonumber(Live.get('updateMoveSeconds'))or Rules.moveSeconds
    local seen={}
    for _,pl in ipairs(Players:GetPlayers())do
        local id=pl.UserId
        if not seen[id]then
            local party=deps.partyOf and deps.partyOf(pl)or {leader=id,users={id}}
            local members,group={},{}
            for _,uid in ipairs(party.users or {id})do
                local m=Players:GetPlayerByUserId(uid)
                if m and not seen[uid]then seen[uid]=true
                    if moving[uid]and now-moving[uid]>60 then moving[uid]=nil;failures[uid]=(failures[uid]or 0)+1;freeSince[uid]=now end
                    local inMatch=deps.inMatch and deps.inMatch(m)or false
                    if inMatch then freeSince[uid]=nil elseif not freeSince[uid]then freeSince[uid]=now end
                    local h=(failures[uid]or 0)>=3 and Rules.moveMaxHops or hops[uid]
                    table.insert(members,{id=uid,inMatch=inMatch,freeSince=freeSince[uid],hops=h});group[uid]=m
                end
            end
            local plan=Rules.planMove(members,now,delay)
            for _,uid in ipairs(plan.stay)do group[uid]:SetAttribute('OpsMoveAt',-1)end
            for _,m in ipairs(members)do if m.inMatch then group[m.id]:SetAttribute('OpsMoveAt',nil)end end
            local due={}
            for _,uid in ipairs(plan.ids)do
                group[uid]:SetAttribute('OpsMoveAt',plan.at)
                if plan.at and now>=plan.at and not moving[uid]then table.insert(due,group[uid])end
            end
            if #due>0 then teleportGroup(due,party.leader or id)end
        end
    end
end
local function announce()
    if live then pcall(function()Messaging:PublishAsync(TOPIC,{op='version',v=game.PlaceVersion})end)end
end
local function playerRow(p)return {id=p.UserId,name=p.Name,display=p.DisplayName,inMatch=deps.inMatch and deps.inMatch(p)or false}end
local function lookup(query)
    local id=tonumber(query)
    if not id then
        if type(query)~='string'or #query<3 or #query>20 or query:find('[^%w_]')then return {ok=false,message='이름이나 유저 번호를 확인해 주세요.'}end
        local ok,v=pcall(function()return Players:GetUserIdFromNameAsync(query)end)
        if not ok or not v then return {ok=false,message='그 이름의 유저를 찾지 못했어요.'}end
        id=v
    end
    if id<1 or id%1~=0 then return {ok=false,message='이름이나 유저 번호를 확인해 주세요.'}end
    local okName,name=pcall(function()return Players:GetNameFromUserIdAsync(id)end)
    if not okName then return {ok=false,message='그 번호의 유저를 찾지 못했어요.'}end
    local row={id=id,name=name,here=Players:GetPlayerByUserId(id)~=nil,history={}}
    local okPages,pages=pcall(function()return Players:GetBanHistoryAsync(id)end)
    if okPages and pages then
        local okPage,page=pcall(function()return pages:GetCurrentPage()end)
        if okPage then for i=#page,math.max(1,#page-4),-1 do local h=page[i]
            table.insert(row.history,{ban=h.Ban==true,duration=h.Duration,start=tostring(h.StartTime),reason=tostring(h.DisplayReason or ''),note=tostring(h.PrivateReason or '')})
        end end
    else row.historyUnavailable=true end
    return {ok=true,user=row}
end
local function status(p)
    local ph=M.phase();local now=os.time()
    local list={};for _,player in ipairs(Players:GetPlayers())do table.insert(list,playerRow(player))end
    table.sort(list,function(a,b)return a.name:lower()<b.name:lower()end)
    return {ok=true,state=ph.state,manual=ph.manual==true,closeAt=ph.closeAt,reopenAt=ph.reopenAt,now=now,
        closeText=Rules.kstText(ph.closeAt),reopenText=Rules.kstText(ph.reopenAt),
        rawClose=Live.get('closeAt'),rawReopen=Live.get('reopenAt'),ticker=Live.get('ticker'),
        flash=flash.untilAt>now and flash.text or '',flashUntil=flash.untilAt,
        players=list,server=public and 'HQ'or 'match',job=game.JobId:sub(1,8),version=game.PlaceVersion,latest=latest,live=live}
end
local handlers={}
handlers.status=function(p)return status(p)end
handlers.lookup=function(_,args)return lookup(type(args)=='table'and args.query)end
handlers.kick=function(p,args)
    local id=type(args)=='table'and tonumber(args.userId)
    if not id then return {ok=false,message='유저를 먼저 찾아 주세요.'}end
    if id==p.UserId then return {ok=false,message='나 자신은 내보낼 수 없어요.'}end
    local here=kickLocal(id,'운영자가 연결을 끊었어요.','You were disconnected by an operator.')
    if not here then broadcast({op='kick',userId=id})end
    audit({op='kick',by=p.UserId,userId=id})
    return {ok=true,message=here and '이 서버에서 내보냈어요.'or '모든 서버에 내보내기를 보냈어요.'}
end
handlers.ban=function(p,args)
    if type(args)~='table'then return {ok=false}end
    local id=tonumber(args.userId)
    if id==p.UserId then return {ok=false,message='나 자신은 정지할 수 없어요.'}end
    local cfg,why=Rules.banConfig(id,args.duration,args.reason,args.note);if not cfg then return {ok=false,message=why}end
    local ok,err=pcall(function()Players:BanAsync(cfg)end)
    audit({op='ban',by=p.UserId,userId=id,duration=args.duration,reason=args.reason,ok=ok})
    if not ok then return {ok=false,message=studio and 'Studio에서는 정지를 걸 수 없어요. 실서버에서 해 주세요.'or '정지하지 못했어요. 잠시 뒤 다시 해 주세요.',detail=tostring(err)}end
    return {ok=true,message=string.format('%s 정지했어요. 접속 중이면 바로 나가요.',Rules.banLabel[args.duration])}
end
handlers.unban=function(p,args)
    local id=type(args)=='table'and tonumber(args.userId)
    if not id then return {ok=false,message='유저를 먼저 찾아 주세요.'}end
    local ok,err=pcall(function()Players:UnbanAsync({UserIds={id},ApplyToUniverse=true})end)
    audit({op='unban',by=p.UserId,userId=id,ok=ok})
    if not ok then return {ok=false,message='정지를 풀지 못했어요. 잠시 뒤 다시 해 주세요.',detail=tostring(err)}end
    return {ok=true,message='정지를 풀었어요.'}
end
handlers.flash=function(p,args)
    if type(args)~='table'then return {ok=false}end
    local mins=tonumber(args.minutes)
    if args.clear==true then broadcast({op='flash',text='',untilAt=0});audit({op='flashClear',by=p.UserId});return {ok=true,message='공지를 내렸어요.'}end
    local text=Rules.line(args.text);if not text then return {ok=false,message='공지 문구를 적어 주세요.'}end
    if not mins or mins<1 or mins>Rules.flashMaxMinutes then return {ok=false,message='보여 줄 시간을 골라 주세요.'}end
    local ok=broadcast({op='flash',text=text,textEn=Rules.line(args.textEn)or '',untilAt=os.time()+math.floor(mins)*60})
    audit({op='flash',by=p.UserId,text=text,minutes=mins})
    return {ok=true,message=ok and string.format('모든 서버 맨 위에 %d분 동안 보여요.',math.floor(mins))or '이 서버에만 보냈어요. 다른 서버는 연결을 확인 중이에요.'}
end
local function request(p,action,args)
    if not M.isAdmin(p)then return {ok=false}end
    local now=os.clock();if now-(lastRequest[p.UserId]or 0)<.3 then return {ok=false,message='잠시 뒤 다시 해 주세요.'}end
    lastRequest[p.UserId]=now
    local h=type(action)=='string'and handlers[action];if not h then return {ok=false}end
    local ok,result=pcall(h,p,args)
    if not ok then warn('SC OPS request failed',action,result);return {ok=false,message='처리하지 못했어요. 잠시 뒤 다시 해 주세요.'}end
    return result
end
function M.start(d)
    if deps then return M end
    deps=d or {}
    local req=Instance.new('RemoteFunction');req.Name='OpsRequest';req.Parent=pack
    req.OnServerInvoke=request
    local open=Instance.new('RemoteEvent');open.Name='OpsOpen';open.Parent=pack
    Players.PlayerAdded:Connect(function(p)
        p:SetAttribute('OpsJoinedAt',os.clock())
        local okJoin,join=pcall(function()return p:GetJoinData()end)
        local moved=okJoin and type(join)=='table'and type(join.TeleportData)=='table'and tonumber(join.TeleportData.opsMove)
        if moved and moved>=1 and moved<=10 then hops[p.UserId]=math.floor(moved)end
        task.spawn(function()
            local admin=M.isAdmin(p);if p.Parent~=Players then return end
            if admin then p:SetAttribute('OpsAdmin',true)end
            local ph=M.phase()
            if ph.state=='maintenance'and public and not admin then p:Kick(Rules.kickMessage(ph,os.time(),en(p)))end
        end)
    end)
    for _,p in ipairs(Players:GetPlayers())do task.spawn(function()if M.isAdmin(p)then p:SetAttribute('OpsAdmin',true)end end)end
    Players.PlayerRemoving:Connect(function(p)local id=p.UserId;admins[id]=nil;lastRequest[id]=nil;freeSince[id]=nil;hops[id]=nil;moving[id]=nil;failures[id]=nil end)
    game:GetService('TeleportService').TeleportInitFailed:Connect(function(p,why)
        if not moving[p.UserId]then return end
        moving[p.UserId]=nil;failures[p.UserId]=(failures[p.UserId]or 0)+1;freeSince[p.UserId]=os.time()
        warn('SC OPS move init failed',p.UserId,why)
    end)
    task.spawn(function()pcall(function()
        local chat=game:GetService('TextChatService')
        local cmd=Instance.new('TextChatCommand');cmd.Name='SCOpsCommand';cmd.PrimaryAlias='/ops';cmd.SecondaryAlias='/운영'
        cmd.Triggered:Connect(function(source)local p=Players:GetPlayerByUserId(source.UserId);if p and M.isAdmin(p)then open:FireClient(p)end end)
        cmd.Parent=chat:FindFirstChild('TextChatCommands')or chat
    end)end)
    if live then task.spawn(function()
        pcall(function()Messaging:SubscribeAsync(TOPIC,onMessage)end)
        while true do announce();task.wait(300)end
    end)end
    task.spawn(function()
        while true do
            local ok,err=pcall(function()
                local ph=M.phase()
                local was=state;state=ph.state
                publish(ph)
                if Rules.holds(state,'joinField')and not Rules.holds(was,'joinField')and deps.onHold then task.spawn(deps.onHold,Rules.heldMessage(state))end
                maintenanceSweep(ph)
                moveSweep()
            end)
            if not ok then warn('SC OPS tick',err)end
            task.wait(2)
        end
    end)
    return M
end
return M
