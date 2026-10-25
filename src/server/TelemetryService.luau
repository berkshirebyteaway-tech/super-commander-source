local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Http=game:GetService('HttpService')
local Analytics=game:GetService('AnalyticsService')
local Core=game.ReplicatedStorage.FrontierNative.Core
local Schema=require(Core.TelemetrySchema)
Schema.maps={};for _,map in ipairs(require(game.ReplicatedStorage.FrontierNative.Maps.MapLoader).catalog)do Schema.maps[map.key]=true end
local Model=require(Core.TelemetryModel)
local Release=require(Core.TelemetryRelease)
local Config=require(script.Parent.TelemetryConfig)
local Live=require(script.Parent.LiveConfig)
local M={};M.__index=M;M.build=Release.release
local singleton
local function guid()return Http:GenerateGUID(false)end
local function hash(s)
 local a,b=5381,2166136261
 for i=1,#s do local c=s:byte(i);a=(a*33+c)%4294967296;b=(bit32.bxor(b,c)*65599)%4294967296 end
 return string.format('%08x%08x',a,b)
end
M.key=hash
function M.actorKey(id)return hash(tostring(game.GameId)..':'..id)end
local projection={
 profile_load_result={'SC_LoadResult','operation','result'},boot_stage={'SC_LoadMs','stage','result','duration_ms'},
 visit_checkpoint={'SC_VisitCheckpoint','phase','checkpoint'},tutorial_exit={'SC_TutorialExit','stage','reason'},
 battlefield_impression={'SC_CardShown','entry','format'},battlefield_selected={'SC_CardSelected','entry','format'},
 lobby_choice_blocked={'SC_JoinBlocked','mode','reason'},queue_exit={'SC_QueueExit','mode','result'},
 party_action={'SC_PartyAction','verb','result'},party_match_summary={'SC_PartyArrival','party_size','result'},
 transfer_result={'SC_TransferResult','stage','result'},drop_landed={'SC_DropResult','spawn_style','result'},
 drop_render_ready={'SC_DropReadyMs','spawn_style','result','duration_ms'},
 nuclear_aim_ended={'SC_AimExit','kind','reason'},nuclear_resolved={'SC_NuclearOutcome','kind','result'},
 feature_available={'SC_FeatureAvailable','mode','feature'},feature_use={'SC_FeatureUsed','mode','feature'},
 player_outcome={'SC_PlayerOutcome','mode','outcome'},result_action={'SC_ResultAction','result','verb'},
 reward_commit_result={'SC_RewardResult','operation','result'},offer_impression={'SC_OfferShown','sku','result'},
 offer_selected={'SC_OfferSelected','sku','result'},purchase_prompt_result={'SC_PromptResult','sku','result'},
 ownership_verified={'SC_OwnershipVerified','sku','result'},benefit_used={'SC_BenefitUsed','benefit','result'},
 draw_result={'SC_DrawResult','sku','rarity'},unlock_granted={'SC_UnlockUsed','kind','result'},
 service_operation={'SC_ServiceResult','operation','result'},
}
local Native=require(Core.TelemetryNative)
M.projection=projection
local function field(v)return type(v)=='boolean'and (v and 'yes'or 'no')or tostring(v or 'unknown')end
function M.new()
 if singleton then return singleton end
 local self=setmetatable({sessions={},departed=setmetatable({},{__mode='k'}),records=Model.ring(Schema.rawLimit),nativeRecords=Model.ring(2048),rawQueues={Model.ring(512),Model.ring(1024),Model.ring(512),Model.ring(512)},
  queues={Model.ring(2048),Model.ring(2048),Model.ring(1024),Model.ring(1024)},errors=0,localMode=Run:IsStudio()or game.GameId==0,
  health={emitted=0,invalid=0,client_rejected=0,client_gaps=0,native_failed=0,native_skipped=0,native_overflow=0,raw_failed=0,raw_dropped=0},
  sequence=0,serverId=game.JobId~=''and game.JobId or guid(),globalBudget=Model.token(84,84/60,os.clock())},M)
 singleton=self
 local remote=Instance.new('RemoteEvent');remote.Name='Telemetry';remote.Parent=game.ReplicatedStorage.FrontierNative;self.remote=remote
 remote.OnServerEvent:Connect(function(p,packet)self:ingest(p,packet)end)
 task.spawn(function()while not self.closed do task.wait(1);self:pulse()end end)
 task.spawn(function()while not self.closed do task.wait(.1);self:drainNative()end end)
 if Config.rawEnabled and Config.rawEndpoint:match('^https://')and Config.secretName~=''and not self.localMode then
  self.rawEnabled=true;task.spawn(function()local last=os.clock()
   while not self.closed do task.wait(1)
    if self:rawPending()>=Config.batchSize or os.clock()-last>=Config.batchSeconds then last=os.clock();if Live.get('telemetryRaw')~=false then self:drainRaw()end end
   end end)
 end
 game:BindToClose(function()if not self.localMode then task.wait(24)end;self:close()end)
 self.names={};local function names()local t={};for _,q in ipairs(Players:GetPlayers())do t[q.Name:lower()]=q.Name;t[q.DisplayName:lower()]=q.DisplayName end;self.names=t end
 Players.PlayerAdded:Connect(names);Players.PlayerRemoving:Connect(function()task.defer(names)end);names()
 local pack=game.ReplicatedStorage.FrontierNative;pack:SetAttribute('TelemetryPerfSample',M.sample('telemetryPerf',Config.performanceSample))
 pcall(function()require(script.Parent.TelemetryWatch).start(self)end)
 return self
end
function M.sample(key,default)local ok,v=pcall(Live.get,key);v=ok and type(v)=='number'and v==v and v or default;return math.clamp(v,0,1)end
function M:session(p)
 if not p then return nil end
 local s=self.sessions[p];if s then return s end
 if self.closed or self.departed[p]or p.Parent~=Players then return nil end
 local now=os.clock();s={id=guid(),connection=guid(),actor=hash(tostring(game.GameId)..':'..p.UserId),at=now,phaseAt=now,phase='boot',phaseSeconds={},
  matches=0,context={},funnels={},nativeFunnelSent={},commands=Model.window(now),nativeCounts={},nativeAt=now,clientSeq=0,
  clientBudget=Model.token(Schema.clientBurst,Schema.clientRate,now),nativeBudget=Model.token(40,16/60,now),seen={},order=Model.ring(1024),
  matchServer=game.PrivateServerId~=''and game.PrivateServerOwnerId==0,detail=p.UserId%100<M.sample('telemetryDetail',Config.detailSample)*100,perf=p.UserId%100<M.sample('telemetryPerf',Config.performanceSample)*100}
 self.sessions[p]=s;self:emit(p,'visit_entered',{phase='boot'});self:funnel(p,'Entry','visit',s.id)
 return s
end
function M:joined(p)self:session(p)end
function M:context(p,values)
 local s=self:session(p);if not s then return end
 for _,k in ipairs({'match_id','party_id','join_attempt_id','transfer_id','purchase_attempt_id','map_key','ruleset_id','mode','version','human_count','ai_count','seat_cap','team_size','team_count','party_size','benefit_state','input_mode','viewport_bucket','locale'})do if values[k]~=nil then s.context[k]=values[k]end end
end
function M:lobby(p,action,result,party,status)
 if action=='read'then return end;local s=self:session(p);if not s then return end;local ok=type(result)=='table'and result.ok==true
 self:request(p,'lobby',action,result)
 local size=party and #party.users or 1
 if party and size>1 then party.analyticsId=party.analyticsId or guid();self:context(p,{party_id=party.analyticsId,party_size=size})else s.context.party_id=nil;self:context(p,{party_size=1})end
 if table.find({'invite','accept','decline','leave','kick','ready','leaveParty'},action)then
  self:emit(p,action=='ready'and 'party_ready_changed'or 'party_action',{verb=action=='leaveParty'and 'leave'or action,result=ok and 'accepted'or 'rejected',reason=ok and 'none'or Schema.reason(result and result.message),party_size=size})
 elseif table.find({'customTeam','team'},action)then self:emit(p,'team_change',{verb='team',result=ok and 'accepted'or 'rejected',party_size=size})end
 if table.find({'joinField','join','play','again','customCreate','joinCode','rejoin'},action)then
  self:emit(p,'party_entry_check',{result=ok and 'accepted'or 'rejected',party_size=size,reason=ok and 'none'or Schema.reason(result and result.message)})
  if not ok then self:emit(p,'lobby_choice_blocked',{result='rejected',reason=Schema.reason(result and result.message),party_size=size,mode=s.context.mode})end
 end
 if status then local key=tostring(status.phase)..':'..tostring(status.count)..':'..tostring(status.max)
  if key~=s.queueState then s.queueState=key;self:emit(p,'queue_state_changed',{stage='queue',result=status.phase=='recovering'and 'pending'or 'ready',human_count=status.count,seat_cap=status.max,elapsed_seconds=s.queueAt and os.clock()-s.queueAt or 0})end
 end
end
function M:emit(p,name,data,options)
 local clean=Schema.clean(name,data or {},options and options.client);if not clean then self.health.invalid+=1;return nil end
 if options and options.id then self.eventLedger=self.eventLedger or {};if not Model.once(self.eventLedger,options.id,8192)then return nil end end
 local s=p and self.sessions[p];self.sequence+=1
 local e={event_name=name,schema_version=Schema.version,event_id=options and options.id or self.serverId..':'..self.sequence,
  occurred_at_utc=DateTime.now().UnixTimestampMillis,sequence=self.sequence,server_id=self.serverId,place_version=game.PlaceVersion,release_id=Release.release,source_digest=Release.digest,
  environment=self.localMode and 'studio'or game.PrivateServerId~=''and 'private'or 'live',synthetic=self.localMode,
  source=options and options.client and 'client'or 'server',sample_rate=options and options.sample or 1,data=clean}
 if options and options.context then for k,v in pairs(options.context)do e[k]=v end end
 if s then e.actor_key=s.actor;e.visit_id=s.id;e.connection_id=s.connection;for k,v in pairs(s.context)do e[k]=v end end
 self.health.emitted+=1;Model.push(self.records,e)
 if self.rawEnabled then local q=self.rawQueues[Schema.events[name].priority+1];if q.count==q.capacity then self.health.raw_dropped+=1 end;Model.push(q,e)end
 if p and s and not(options and options.suppressProjection)then self:project(p,name,clean)end
 if name=='benefit_used'and s and s.paid and clean.sku and (clean.result=='ok'or clean.result=='accepted')and clean.benefit~='permanent_welcome'and clean.benefit~='daily_tickets'then self:benefit(p,clean.sku,clean.benefit)end
 return e
end
function M:project(p,name,clean)
 local s=self.sessions[p];if not s then return end
 for _,row in ipairs(Native.project(name,clean,s.context,projection[name]))do self:aggregate(p,row[1],row[2],row[3],row[4])end
end
function M:aggregate(p,name,value,a,b)
 local s=self.sessions[p];if not s then return end
 local key=name..'|'..field(a)..'|'..field(b);s.nativeCounts[key]=(s.nativeCounts[key]or 0)+value
end
function M:native(p,name,value,a,b,priority,extra)
 local s=self.sessions[p];if not s then return end
 local event={name=name,value=value,fields={CustomField01=Release.group,CustomField02=field(a),CustomField03=field(b)}}
 if extra then for k,v in pairs(extra)do event[k]=v end end
 if self.localMode then Model.push(self.nativeRecords,{actor_key=s.actor,event=event});return end
 if s.final and not event.funnel then self:sendNow(p,event);return end
 local q=self.queues[(priority or 1)+1]
 if q.count==q.capacity then self.health.native_overflow+=1;return end
 Model.push(q,{player=p,event=event,at=os.clock(),budget=s.nativeBudget,funnelState=s.nativeFunnelSent})
end
local function dispatch(player,e)
 return (pcall(function()
  if e.economy then Analytics:LogEconomyEvent(player,e.economy,e.currency or 'Medals',e.amount,e.balance,e.transaction,e.sku,e.fields)
  elseif e.progression then Analytics:LogProgressionCompleteEvent(player,'CommanderRank',e.level,e.levelName,e.fields)
  elseif e.onboarding then Analytics:LogOnboardingFunnelStepEvent(player,e.step,e.stepName,e.fields)
  elseif e.funnel then Analytics:LogFunnelStepEvent(player,e.funnel,e.sessionId,e.step,e.stepName,e.fields)
  else Analytics:LogCustomEvent(player,e.name,e.value,e.fields)end
 end))
end
function M:sendNow(p,e)
 if not Model.take(self.globalBudget,os.clock())then self.health.native_skipped+=1;return end
 if not dispatch(p,e)then self.errors+=1;self.health.native_failed+=1 end
end
function M:finalNative(p)
 if self.localMode then return end;local sent=0
 for _,q in ipairs(self.queues)do local keep={}
  while q.count>0 do local item=Model.pop(q)
   if item.player~=p then table.insert(keep,item)elseif not item.event.funnel and sent<48 then sent+=1;self:sendNow(p,item.event)else self.health.native_skipped+=1 end
  end
  for _,item in ipairs(keep)do Model.push(q,item)end
 end
end
function M:drainNative()
 local now=os.clock();self.globalBudget.capacity=84+14*#Players:GetPlayers();self.globalBudget.rate=self.globalBudget.capacity/60
 for index=4,1,-1 do local q=self.queues[index]
  for _=1,math.min(q.count,4)do local item=Model.pop(q)
   local fkey=item.event.funnel and item.event.funnel..':'..item.event.sessionId
   if item.player.Parent~=Players or now-item.at>300 or fkey and item.funnelState[fkey]==-1 then self.health.native_skipped+=1;if fkey then item.funnelState[fkey]=-1 end
   elseif fkey and not Model.funnelReady(item.funnelState,fkey,item.event.step)then Model.push(q,item)
   elseif item.budget.value+math.max(0,now-item.budget.at)*item.budget.rate>=1 and Model.take(self.globalBudget,now)then
    Model.take(item.budget,now);local e=item.event;local ok=dispatch(item.player,e)
    if fkey then item.funnelState[fkey]=ok and e.step or -1 end
    if not ok then self.errors+=1;self.health.native_failed+=1 end;return
   else Model.push(q,item)end
  end
 end
end
function M:drainRaw()
 if self.rawWorking or not self.rawEnabled or self:rawPending()==0 then return end;self.rawWorking=true
 local batch={};for index=4,1,-1 do local q=self.rawQueues[index];while q.count>0 and #batch<Config.batchSize do table.insert(batch,Model.pop(q))end end
 local body=Http:JSONEncode({schema_version=Schema.version,server_id=self.serverId,events=batch});local sent=false
 for attempt=1,Config.maxAttempts do
  local ok,result=pcall(function()return Http:RequestAsync({Url=Config.rawEndpoint,Method='POST',Headers={['Content-Type']='application/json',['Authorization']=Http:GetSecret(Config.secretName):AddPrefix('Bearer ')},Body=body})end)
  if ok and result.Success then sent=true;break end
  self.health.raw_failed+=1;if attempt<Config.maxAttempts then task.wait(attempt)end
 end
 if not sent then self.health.raw_dropped+=#batch end;self.rawWorking=false
end
function M:rawPending()local n=0;for _,q in ipairs(self.rawQueues)do n+=q.count end;return n end
function M:funnel(p,name,label,id)
 local s=self:session(p);if not s or not Schema.funnels[name]then return end;local key=name..':'..tostring(id or s.id);local f=s.funnels[key]
 if not f then
  if label~=Schema.funnels[name][1]then return end
  s.funnelOrder=s.funnelOrder or Model.ring(40);if s.funnelOrder.count==40 then s.funnels[Model.pop(s.funnelOrder)]=nil end;Model.push(s.funnelOrder,key)
  f={id=id or guid(),step=0};s.funnels[key]=f
 end
 local step=Schema.step(name,f.step,label);if not step then return end;f.step=step
 self:native(p,'',1,name,s.marker or 'unknown',3,M.funnelEvent(name,f.id,step,label))
end
function M.funnelEvent(name,id,step,label)return {funnel='SC_'..name..'_v1',sessionId=id,step=step,stepName=label,onboarding=name=='Onboarding'or nil}end
function M:journeyProfile(p,info)
 local s=self:session(p);if not s or type(info)~='table'then return end
 s.marker=s.marker or (info.new and 'new'or 'return');s.basics=info.basics==true;s.pvpGames=tonumber(info.pvpGames)or 0;s.profileKnown=true
 if s.onboarding or game.PrivateServerId~=''or not(info.new or s.pvpGames==0)then return end
 s.onboarding=guid()
 if s.basics then local key='Onboarding:'..s.onboarding;s.funnels[key]={id=s.onboarding,step=4};s.nativeFunnelSent['SC_Onboarding_v1:'..s.onboarding]=4
  s.funnelOrder=s.funnelOrder or Model.ring(40);if s.funnelOrder.count==40 then s.funnels[Model.pop(s.funnelOrder)]=nil end;Model.push(s.funnelOrder,key)
 else self:milestone(p,'join');if s.lobbyReadyAt then self:milestone(p,'lobby')end end
end
function M:milestone(p,label)
 local s=self.sessions[p];if not s then return end
 if s.onboarding then self:funnel(p,'Onboarding',label,s.onboarding)end
 if s.marker and Model.once(s,'journey:'..label)then self:flow(p,'journey',label,{item=s.marker,marker=s.marker})end
end
function M:phase(p,phase)
 local s=self:session(p);if not s or phase==s.phase then return end
 local now=os.clock();self:emit(p,'visit_phase_window',{phase=s.phase,elapsed_seconds=now-s.phaseAt,stage='closed'});s.phaseSeconds[s.phase]=(s.phaseSeconds[s.phase]or 0)+now-s.phaseAt;s.phase=phase;s.phaseAt=now
 if phase=='lobby'then self:campaignQuit(p,'left')end
end
function M:mark(p,name)
 local s=self:session(p)
 if not s then return end
 if name=='LobbyReady'then self:phase(p,'lobby');self:funnel(p,'Entry','interactive',s.id);s.lobbyReadyAt=s.lobbyReadyAt or os.clock();self:milestone(p,'lobby')
  if Model.once(s,'lobbyReady')then self:emit(p,'boot_stage',{stage='lobby_ready',result='ok',duration_ms=(os.clock()-s.at)*1000})end
 elseif name=='Settled'then self:phase(p,'playing')
 elseif name=='FirstCapture'and s.lesson then self:funnel(p,'Learning','capture',s.lesson)end
end
function M:requested(p,mode)
 local s=self:session(p);if not s then return end;self:flushCommands(p,true);s.context.join_attempt_id=guid();s.joinAt=os.clock();s.context.mode=Schema.enum('mode',mode)
 self:funnel(p,'Entry','requested',s.id);self:funnel(p,'PlayJoin','requested',s.context.join_attempt_id)
 if s.replay then self:funnel(p,'Replay','requested',s.replay)end
end
function M:queued(p,mode,partySize)
 local s=self:session(p);if not s then return end;if not s.joinAt then self:requested(p,mode)end;s.queueAt=os.clock()
 self:context(p,{mode=Schema.enum('mode',mode),party_size=partySize or 1});self:phase(p,'queue')
 self:emit(p,'queue_entered',{stage='seat',result='accepted',party_size=partySize or 1});self:funnel(p,'PlayJoin','seat',s.context.join_attempt_id);self:milestone(p,'queue')
end
function M:queueExit(p,result)
 local s=self:session(p);if not s or not s.queueAt then return end
 local seconds=os.clock()-s.queueAt;s.queueAt=nil;if result=='cancelled'then self:phase(p,'lobby')end;self:emit(p,'queue_exit',{result=result,elapsed_seconds=seconds,mode=s.context.mode});self:aggregate(p,'SC_QueueSeconds',seconds,s.context.mode,result)
end
function M:match(p,map,mode,room)
 local existing=self.sessions[p];if existing then existing.admitted=true end
 local s=self:session(p);if not s then return end;self:flushCommands(p,true);s.matches+=1;s.matchAt=os.clock();s.capture=false;s.combat=false;s.features={};s.available={};s.commandDetail=0;s.dropLogged=nil;s.landedLogged=nil;s.dropEndLogged=nil;s.playerWindowAt=nil;s.outcomeLogged=nil;s.lastOutcome=nil;s.dropCounts=nil;s.counted=nil;s.intro=room and room.intro
 local humans=0;if room then for _ in pairs(room.members or {})do humans+=1 end end
 self:context(p,{map_key=map,mode=Schema.enum('mode',mode),match_id=room and (room.globalMatch or room.id)or guid(),ruleset_id='OpenFront-e02eeba',human_count=room and room.analyticsHumans or (humans>0 and humans or 1)})
 self:emit(p,'match_admission_result',{result='accepted',human_count=s.context.human_count,intro=room and room.intro==true})
 pcall(function()local meta=room and room.session and room.session.map and room.session.map.meta
  self:flow(p,'match','start',{item=meta and meta.mapSize=='normal'and 'normal'or 'compact',map_key=map,mode=s.context.mode,human_count=s.context.human_count})
  local w=room and room.clanwar;if w then local n,size=w.count or 2,w.size or 2;self:flow(p,'clan','warStart',{item=Schema.code('c'..n..'_p'..size),total=n,party_size=size,value=size})end
 end)
 self:funnel(p,'PlayJoin','seat',s.context.join_attempt_id)
 self:funnel(p,'Entry','admitted',s.id);self:funnel(p,'PlayJoin','admitted',s.context.join_attempt_id)
 if s.replay then self:funnel(p,'Replay','admitted',s.replay)end;self:phase(p,'drop')
 s.joinAt=nil
 self:milestone(p,s.intro and 'opStart'or Native.realMatch(s.context.mode)and 'seated'or 'practice')
end
local function feature(action,kind)
 return action=='attack'and 'expansion'or action=='transport'and 'navy'or action=='build'and 'construction'or action=='support'and 'support'or action=='alliance'and 'diplomacy'
  or action=='nuclear'and (kind=='HydrogenBomb'and 'hydrogen'or kind=='MIRV'and 'mirv'or 'nuclear')or table.find({'comms','emoji','ping'},action)and 'signals'or nil
end
function M:command(p,action,ok,message,id,version,started,kind,duplicateHint)
 local s=self:session(p);if not s then return end;action=Schema.action(action);local reason=ok and 'none'or Schema.reason(message)
 local duplicate
 if duplicateHint~=nil then duplicate=duplicateHint else duplicate=Model.sequence(s,version,id)==false end
 Model.count(s.commands,action..':'..(duplicate and 'duplicate'or ok and 'accepted'or 'rejected')..':'..reason..':'..Schema.enum('kind',kind,'other'))
 if duplicate then return end;s.commandDetail=(s.commandDetail or 0)+1
 local failureKey=action..':'..reason;s.rejectDetails=s.rejectDetails or {};s.rejectDetails[failureKey]=(s.rejectDetails[failureKey]or 0)+(ok and 0 or 1)
 if s.commandDetail<=10 or s.detail and ok or Schema.rare[action]and ok or not ok and s.rejectDetails[failureKey]<=3 then
  self:emit(p,'command_result',{action=action,result=ok and 'accepted'or 'rejected',reason=reason,command_id=type(id)=='number'and id or nil,version=version,duration_ms=math.max(0,(os.clock()-(started or os.clock()))*1000),kind=kind},
   {sample=(s.commandDetail<=10 or Schema.rare[action]or not ok)and 1 or Config.detailSample})
 end
 if ok then
  if action=='attack'or action=='build'or action=='transport'then self:funnel(p,'Entry','command',s.id);if s.lesson then self:funnel(p,'Learning','command',s.lesson)end end
  local f=feature(action,kind);s.features=s.features or {};s.available=s.available or {};if f and not s.features[f]then s.features[f]=true;self:emit(p,'feature_use',{feature=f,mode=s.context.mode,first_use=true,eligible=s.available[f]==true})end
  if action=='nuclear'then self:emit(p,'nuclear_launched',{kind=kind,result='accepted',command_id=id,version=version})end
  if action=='alliance'or action=='support'or action=='embargoAll'then self:flow(p,'match','diplomacy',{item=Schema.code(action..'_'..tostring(kind or 'other'))or action,result='accepted'})end
 end
end
function M:flushCommands(p,partial)
 local s=self.sessions[p];if not s then return end;local w=s.commands
 for key,count in pairs(s.commsCounts or {})do local kind,scope,stage,result=key:match('^(.-):(.-):(.-):(.*)$');self:emit(p,'communication_window',{comms_kind=kind,scope=scope,stage=stage,result=result,count=count,window_seconds=os.clock()-w.at,partial=partial==true})end;s.commsCounts={};s.commsDetails={}
 for key,count in pairs(w.counts)do local a,result,reason,kind=key:match('^(.-):(.-):(.-):(.*)$')
  self:emit(p,'command_window',{action=a,result=result,reason=reason,kind=kind,count=count,window_seconds=os.clock()-w.at,partial=partial==true})
  self:aggregate(p,result=='rejected'and 'SC_CommandRejected'or 'SC_CommandCount',count,a,result=='rejected'and reason or result)
 end
 s.commands=Model.window(os.clock());s.rejectDetails={};s.requests={}
 if partial or os.clock()-s.nativeAt>=Config.nativeFlushSeconds then
  for key,count in pairs(s.nativeCounts)do local name,a,b=key:match('^(.-)|(.-)|(.*)$');self:native(p,name,count,a,b,1)end
  s.nativeCounts={};s.nativeAt=os.clock()
 end
end
function M:communication(p,kind,scope,stage,ok,id)
 local s=self.sessions[p];if not s then return end
 if id then s.commsIds=s.commsIds or {};if not Model.once(s.commsIds,id,1024)then return end end
 kind=Schema.enum('comms_kind',kind,'other');scope=Schema.enum('scope',scope)
 local result=ok and (stage=='accepted'and 'accepted'or 'pending')or 'rejected';local key=kind..':'..scope..':'..stage..':'..result
 s.commsCounts=s.commsCounts or {};s.commsCounts[key]=(s.commsCounts[key]or 0)+1;s.commsDetails=s.commsDetails or {};s.commsDetails[key]=(s.commsDetails[key]or 0)+1
 if s.commsDetails[key]<=3 or stage=='accepted'then self:emit(p,'communication',{comms_kind=kind,scope=scope,stage=stage,result=result})end
 if ok and stage=='accepted'and s.features and not s.features.signals then s.features.signals=true;self:emit(p,'feature_use',{feature='signals',mode=s.context.mode,first_use=true})end
end
function M:dropInput(p,packet,accepted)
 local s=self.sessions[p];if not s then return end
 local w=s.dropCounts or {movement_count=0,dive_count=0,rally_count=0,count=0};s.dropCounts=w
 if accepted then w.count+=1
  if packet.kind=='move'and (packet.x~=0 or packet.y~=0)then w.movement_count+=1
  elseif packet.kind=='land'then w.dive_count+=1
  elseif packet.kind=='rally'then w.rally_count+=1;self:emit(p,'drop_rally',{stage='rally',result='accepted'})end
 end
end
function M:observe(p,pr,map,mode)
 if not pr then return end;local s=self:session(p);if not s then return end;mode=s.context.mode or mode
 if pr.spawnedAt and not s.combat then s.combat=true;self:phase(p,'playing');self:funnel(p,'Entry','combat',s.id);self:funnel(p,'PlayJoin','combat',s.context.join_attempt_id);if s.replay then self:funnel(p,'Replay','combat',s.replay)end end
 if pr.milestones.expand and not s.capture then s.capture=true;self:emit(p,'capture_observed',{stage='capture',elapsed_seconds=os.clock()-(s.matchAt or s.at),first_use=true});self:mark(p,'FirstCapture')end
 if pr.ended and Model.once(s,'outcome:'..pr.id..':'..tostring(pr.outcome)..':'..tostring(pr.final))then
  self:flushCommands(p,true);self:phase(p,'result')
  local data={outcome=Schema.enum('outcome',pr.outcome),mode=Schema.enum('mode',mode),elapsed_seconds=pr.seconds,revision=pr.revision,final=pr.final==true,correction=s.outcomeLogged==true}
  self:emit(p,'player_outcome',data,{suppressProjection=s.lastOutcome==pr.outcome});if s.intro then self:emit(p,'first_operation_outcome',data);self:flow(p,'tutorial','firstOpEnd',{item=data.outcome,value=pr.seconds})end;s.lastOutcome=pr.outcome;s.outcomeLogged=true
  if s.intro then s.basics=true;self:milestone(p,'opEnd')elseif Native.realMatch(s.context.mode)then if not s.counted then s.counted=true;s.pvpGames=(s.pvpGames or 0)+1 end;self:milestone(p,'result')end
  self:aggregate(p,'SC_MatchSeconds',pr.seconds,Schema.enum('mode',mode),Schema.enum('outcome',pr.outcome))
  if s.outcomeDetail~=pr then s.outcomeDetail=pr;pcall(self.matchSummary,self,p,pr,mode)end
 end
 if pr.spawnedAt and not pr.ended and (s.firstBuild~=pr or os.time()>=(s.idleCheckAt or 0))then pcall(function()local now=os.time()
  if s.firstBuild~=pr then for kind,n in pairs(pr.tactics.built)do if n>0 then s.firstBuild=pr;self:flow(p,'match','firstBuild',{kind=Schema.enum('kind',kind,'other'),item=Schema.code(kind),value=math.max(0,now-pr.spawnedAt),mode=Schema.enum('mode',mode)});break end end end
  if now>=(s.idleCheckAt or 0)then s.idleCheckAt=now+60;local idle=now-math.max(pr.lastAction or 0,pr.spawnedAt)
   if idle>=60 then self:flow(p,'match','idle',{idle_seconds=idle,value=idle,elapsed_seconds=now-pr.spawnedAt,mode=Schema.enum('mode',mode),result=idle>=180 and 'inactive'or 'active'})end
  end
 end)end
end
function M:matchSummary(p,pr,mode)
 local m=Schema.enum('mode',mode);local outcome=Schema.enum('outcome',pr.outcome);local alive=pr.spawnedAt and (pr.ended and pr.time or os.time())-pr.spawnedAt or 0
 self:flow(p,'match','placement',{item=outcome,result=outcome=='won'and 'won'or outcome=='forfeit'and 'forfeit'or 'lost',position=pr.place,total=pr.total,value=pr.place,
  level=math.floor((pr.peak or 0)*1000),amount=math.floor((pr.currentShare or 0)*1000),elapsed_seconds=pr.seconds,mode=m})
 if outcome~='won'then local idle=pr.spawnedAt and math.max(0,(pr.time or os.time())-math.max(pr.lastAction or 0,pr.spawnedAt))or nil
  self:flow(p,'match','eliminated',{item=type(pr.lostCause)=='string'and pr.lostCause or outcome,active=pr.triedExpansion==true,last_attack=pr.lastKind=='attack',away=pr.away==true,
   spawn_style=Schema.enum('spawn_style',pr.landing),idle_seconds=idle,human_count=pr.humans,result=outcome=='forfeit'and 'forfeit'or 'lost',reason=outcome=='forfeit'and 'manual'or 'territory',position=pr.place,total=pr.total,value=alive,elapsed_seconds=alive,level=math.floor((pr.peak or 0)*1000),mode=m})end
 for kind,n in pairs(pr.tactics.built or {})do if n>0 then self:flow(p,'match','built',{item=Schema.code(kind),kind=Schema.enum('kind',kind,'other'),value=n,mode=m})end end
 for _,key in ipairs({'nukes','transports','upgrades','alliances','intercepts','countriesConquered','warships'})do local n=pr.tactics[key];if type(n)=='number'and n>0 then self:flow(p,'match','tactic',{item=key,value=n,mode=m})end end
 local minShare=pr.tactics.minShare;if outcome=='won'and type(minShare)=='number'and (pr.peak or 0)>0 and minShare<=0.05 then self:flow(p,'match','comeback',{value=math.floor(minShare*1000),level=math.floor(pr.peak*1000),mode=m,result='won'})end
end
function M:ingest(p,packet)
 local s=self:session(p)
 if not s then return end
 if type(packet)~='table'or type(packet.events)~='table'or #packet.events>Schema.clientBatch or not Model.take(s.clientBudget,os.clock(),#packet.events+1)then self.health.client_rejected+=1;return end
 for _,row in ipairs(packet.events)do
  if type(row)~='table'or type(row.sequence)~='number'or row.sequence%1~=0 or row.sequence<=s.clientSeq or row.sequence>s.clientSeq+10000 then self.health.client_rejected+=1;continue end
  local data=Schema.clean(row.name,row.data,true);if not data then self.health.client_rejected+=1;continue end
  self:guard(data)
  if row.name=='battlefield_impression'or row.name=='battlefield_selected'then
   local f=self.resolveField and self.resolveField(p,data.field_id)
   if f then data.map_key=f.rules.map;data.format=f.rules.mode=='teams'and 'team'or f.rules.mode=='coop'and 'coop'or 'ffa';data.human_count=f.count;data.seat_cap=f.rules.maximum
   else data.field_id=nil;data.map_key=nil end
  end
  if row.name=='client_performance_window'and not(s.perf or self.localMode)then continue end
  if row.sequence>s.clientSeq+1 then self.health.client_gaps+=row.sequence-s.clientSeq-1 end;s.clientSeq=row.sequence
  if data.input_mode then s.context.input_mode=data.input_mode end;if data.viewport_bucket then s.context.viewport_bucket=data.viewport_bucket end;if data.locale then s.context.locale=data.locale end;if row.name=='device_profile'and data.device_class then s.context.device_class=data.device_class end
  self:emit(p,row.name,data,{client=true,sample=row.name=='client_performance_window'and not self.localMode and Config.performanceSample or 1})
  if row.name=='command_feedback_seen'and data.duration_ms then self:aggregate(p,'SC_InputLatencyBucket',1,data.input_mode,Schema.latencyBucket(data.duration_ms))end
  if row.name=='client_performance_window'then for _,bucket in ipairs({'le16','le33','le50','le100','gt100'})do if data[bucket]then self:aggregate(p,'SC_ClientFrameBucket',data[bucket],data.phase,bucket)end end end
  if row.name=='screen_viewed'and data.screen then s.lastScreen=data.screen end
  if row.name=='flow_step'and data.area=='lobby'and (data.step=='introStart'or data.step=='intro')then s.introOpen=data.step=='introStart'end
  if row.name=='boot_stage'and data.stage=='client_ready'then s.clientReady=true;self:funnel(p,'Entry','interactive',s.id)
  elseif row.name=='tutorial_started'then s.lesson=guid();self:funnel(p,'Learning','shown',s.lesson)
  elseif row.name=='tutorial_step'and data.stage=='grow'and s.lesson then self:funnel(p,'Learning','grow',s.lesson)
  elseif row.name=='result_viewed'then s.replay=guid();self:funnel(p,'Replay','shown',s.replay)
  elseif row.name=='purchase_prompt_result'and data.result=='opened'and s.checkout and data.sku==s.checkoutSku then self:funnel(p,'Checkout','opened',s.checkout);if s.checkoutOwnership then self:funnel(p,'Checkout','ownership',s.checkout);self:funnel(p,'Checkout','benefit',s.checkout)end end
 end
end
function M:guard(data)
 for key in pairs(Schema.ids)do local v=data[key];if v and self.names and self.names[v:lower()]then data[key]='item'end end
 if data.detail then data.detail=self:scrub(data.detail)end
end
function M:scrub(text)
 text=tostring(text):gsub('Players%.[^%.%s:]+','Players.?'):gsub('"[^"]*"','"?"'):gsub("'[^']*'","'?'")
 for _,name in pairs(self.names or {})do if #name>=3 then text=text:gsub(name:gsub('%p','%%%0'),'?')end end
 return text:sub(1,200)
end
function M:prepareTransfer(p,key)
 local s=self:session(p);if not s then return end;s.context.transfer_id=guid();self:phase(p,'transfer');self:emit(p,'transfer_started',{stage='sending',result='pending'})
 local record={visit_id=s.id,join_attempt_id=s.context.join_attempt_id,transfer_id=s.context.transfer_id,party_id=s.context.party_id,party_size=s.context.party_size,matches=s.matches,elapsed=os.clock()-s.at,at=DateTime.now().UnixTimestampMillis,entry=s.funnels['Entry:'..s.id],actor=s.actor}
 record.flows={}
 for _,pair in ipairs({{'Entry',s.id},{'PlayJoin',s.context.join_attempt_id},{'Replay',s.replay},{'Onboarding',s.onboarding}})do
  if pair[2]then local f=s.funnels[pair[1]..':'..pair[2]];if f then
   table.insert(record.flows,{name=pair[1],id=f.id,step=f.step,sent=math.max(0,s.nativeFunnelSent['SC_'..pair[1]..'_v1:'..f.id]or 0)})
  end end
 end
 record.replay=s.replay;record.marker=s.marker;record.onboarding=s.onboarding
 if not self.localMode then task.spawn(function()
  local at=os.clock();local ok=pcall(function()game:GetService('MemoryStoreService'):GetHashMap('SuperCommanderTelemetryTransfers_v1'):SetAsync(hash(key..':'..p.UserId),record,180)end);self:service(p,'teleport',ok,at)
 end)end;return record
end
function M:acceptTransfer(p,key,record)
 task.spawn(function()
  if not record and not self.localMode then for _=1,3 do
   local ok,value=pcall(function()return game:GetService('MemoryStoreService'):GetHashMap('SuperCommanderTelemetryTransfers_v1'):GetAsync(hash(key..':'..p.UserId))end)
   if ok and value then record=value;break end;task.wait(.5)
  end end
  local s=self.sessions[p];if not s then return end
  if type(record)=='table'and record.actor==s.actor and type(record.visit_id)=='string'and type(record.at)=='number'and DateTime.now().UnixTimestampMillis-record.at<180000 then
   if not Model.once(s,'relinked:'..tostring(record.transfer_id))then return end
   local provisional=s.id;s.id=record.visit_id;s.context.join_attempt_id=record.join_attempt_id;s.context.transfer_id=record.transfer_id;s.context.party_id=record.party_id;s.context.party_size=record.party_size;s.matches=s.matches+(record.matches or 0);s.at=os.clock()-(record.elapsed or 0)-math.max(0,DateTime.now().UnixTimestampMillis-record.at)/1000
   if record.flows then
    for _,f in ipairs(record.flows)do if Schema.funnels[f.name]and type(f.id)=='string'and type(f.step)=='number'and f.step>=1 and f.step<=#Schema.funnels[f.name]then
     s.funnels[f.name..':'..f.id]={id=f.id,step=f.step}
     local sent=math.clamp(f.sent or 0,0,f.step);s.nativeFunnelSent['SC_'..f.name..'_v1:'..f.id]=sent
     for step=sent+1,f.step do self:native(p,'',1,f.name,record.marker or s.marker or 'unknown',3,M.funnelEvent(f.name,f.id,step,Schema.funnels[f.name][step]))end
    end end
   elseif record.entry then s.funnels['Entry:'..s.id]=record.entry end
   s.replay=record.replay;if record.marker=='new'or record.marker=='return'then s.marker=record.marker end;if type(record.onboarding)=='string'then s.onboarding=record.onboarding end
   if s.admitted then self:funnel(p,'Entry','admitted',s.id);self:funnel(p,'PlayJoin','admitted',s.context.join_attempt_id);if s.replay then self:funnel(p,'Replay','admitted',s.replay)end end
   if s.combat then self:funnel(p,'Entry','combat',s.id);self:funnel(p,'PlayJoin','combat',s.context.join_attempt_id);if s.replay then self:funnel(p,'Replay','combat',s.replay)end end
   self:emit(p,'visit_relinked',{stage='arrived',result='ok'},{context={previous_visit_id=provisional}})
   local ms=math.max(0,DateTime.now().UnixTimestampMillis-record.at);self:emit(p,'transfer_result',{stage='arrived',result='accepted',duration_ms=ms});self:aggregate(p,'SC_TransferMs',ms,'arrived','accepted')
  else self:emit(p,'transfer_result',{stage='arrived',result='unknown',reason='missing'})end
 end)
end
function M:room(room,now)
 if now<(room.analyticsNext or 0)then return end;room.analyticsNext=now+1
 local session=room.session;local sim=session.sim;local humans,ai,neutral=0,0,0
 for _,p in ipairs(sim.players)do if p.kind=='HUMAN'then humans+=1 elseif p.kind=='BOT'then neutral+=1 else ai+=1 end end
 if not room.analyticsCreated then
  room.analyticsCreated=true
  local system=session.unitSystem;local original=system.effect
  system.effect=function(unitSystem,kind,tile,owner,extra)
   original(unitSystem,kind,tile,owner,extra)
   if kind=='detonate'or kind=='intercept'then
    local actor;for uid,faction in pairs(room.members)do if faction==owner then actor=Players:GetPlayerByUserId(uid);break end end
    self:emit(actor,'nuclear_resolved',{kind=extra and extra.weapon or 'other',result=kind=='intercept'and 'intercepted'or 'detonated',stage=kind=='intercept'and 'warning'or 'outcome'},
     {context={match_id=room.globalMatch or room.id,map_key=session.map.meta.key}})
   end
  end
  self:emit(nil,'room_created',{human_count=humans,ai_count=ai,neutral_count=neutral,mode=Schema.enum('mode',room.mode)},{id='room:'..room.id..':created',context={match_id=room.globalMatch or room.id,map_key=session.map.meta.key}})
 end
 if room.analyticsPhase~=session.phase then room.analyticsPhase=session.phase;self:emit(nil,'room_status_changed',{phase=session.phase=='spawn'and 'drop'or session.phase=='playing'and 'playing'or 'result',human_count=humans},{context={match_id=room.globalMatch or room.id,map_key=session.map.meta.key}})end
 local counts={};for _,u in ipairs(session.units)do if u.active~=false and not u.building then counts[u.owner]=counts[u.owner]or {};counts[u.owner][u.kind]=(counts[u.owner][u.kind]or 0)+1 end end
 for uid,faction in pairs(room.members)do local p=Players:GetPlayerByUserId(uid);local s=p and self.sessions[p]
  if s then
   s.features=s.features or {};s.available=s.available or {}
   local party=self.resolveParty and self.resolveParty(p)
   if party and #party.users>1 then
    party.analyticsId=party.analyticsId or s.context.party_id or guid();self:context(p,{party_id=party.analyticsId,party_size=#party.users})
    if party.leader==uid then local arrived=0;for _,member in ipairs(party.users)do if room.members[member]and Players:GetPlayerByUserId(member)then arrived+=1 end end
     self:emit(p,'party_match_summary',{party_size=#party.users,ready_count=arrived,result=arrived==#party.users and 'accepted'or 'pending'},{id='party:'..party.analyticsId..':'..room.id..':'..arrived})
    end
   end
   self:context(p,{match_id=room.globalMatch or room.id,human_count=humans,ai_count=ai})
   local own=counts[faction]or {};local eligibility={expansion=session.phase=='playing',construction=session.phase=='playing',navy=(own.Port or 0)>0,trade=(own.Port or 0)>0,railway=(own.Factory or 0)>0,nuclear=(own.MissileSilo or 0)>0,hydrogen=(own.MissileSilo or 0)>0,mirv=(own.MissileSilo or 0)>0,diplomacy=not session.settings.disableAlliances,signals=true,support=humans>1,defense=(own.SAMLauncher or 0)>0}
   for f,eligible in pairs(eligibility)do if eligible and not s.available[f]then s.available[f]=true;self:emit(p,'feature_available',{feature=f,mode=s.context.mode,eligible=true})end end
   for _,pair in ipairs({{'trade','TradeShip'},{'railway','Train'}})do if (own[pair[2]]or 0)>0 and not s.features[pair[1]]then s.features[pair[1]]=true;self:emit(p,'feature_use',{feature=pair[1],mode=s.context.mode,stage='status',first_use=true})end end
   local drop=room.drop;local seat=drop and drop.players[faction]
   if seat then
    if not s.dropLogged then s.dropLogged=true;self:emit(p,'drop_started',{spawn_style=drop.random and 'random'or 'selected',human_count=humans});if not s.intro then self:milestone(p,'drop')end end
    if seat.landed and seat.committed and not s.landedLogged then s.landedLogged=true;self:emit(p,'drop_landed',{spawn_style=drop.random and 'random'or 'selected',result='ok',reason=seat.fallback and 'fallback'or drop.random and 'random'or 'manual',elapsed_seconds=drop.startAt and now-drop.startAt or 0,fallback=seat.fallback==true})end
    if drop.finished and not s.dropEndLogged then s.dropEndLogged=true;self:emit(p,'drop_ended',{result='ok',human_count=humans});if s.dropCounts then self:emit(p,'drop_input_window',s.dropCounts);s.dropCounts=nil end end
   end
   if now>=(s.playerWindowAt or 0)then s.playerWindowAt=now+60;local player=sim.players[faction]
    local cap=session:maxTroops(faction)
    self:emit(p,'match_player_window',{tiles=player.tiles.size,troops=player.troops,cap=cap,growth_ratio=player.troops/math.max(1,cap),growth_per_second=require(Core.EconomyRules).troopIncrease(session.settings,session:economyPlayer(faction))*10,gold=require(Core.BigNat).toString(session:getGold(faction)),incoming=#(player.incoming or {}),outgoing=#(player.outgoing or {}),tick=sim.ticks,simulation_seconds=sim.ticks/10,paused=room.paused==true,elapsed_seconds=now-(s.matchAt or now)})
   end
  end
 end
 if now>=(room.analyticsWindowAt or 0)then
  room.analyticsWindowAt=now+60;self:emit(nil,'match_room_window',{human_count=humans,ai_count=ai,neutral_count=neutral,units=#session.units,tick=sim.ticks,simulation_seconds=sim.ticks/10,paused=room.paused==true},{id='room:'..room.id..':window:'..math.floor(now/60),context={match_id=room.globalMatch or room.id,map_key=session.map.meta.key}})
  local r=room.perf and room.perf.tick
  if r then local n=math.min(600,r.n-(room.analyticsTickN or 0));room.analyticsTickN=r.n;local w=Model.window(now)
   for i=0,n-1 do local ms=r.samples[(r.i-i-1)%600+1]*1000;Model.histogram(w,Schema.frameBucket(ms),ms)end
   local data={samples=n,sum_ms=w.sum,max_ms=w.max,window_seconds=60};for k,v in pairs(w.latency)do data[k]=v end
   self:emit(nil,'server_performance_window',data,{context={match_id=room.globalMatch or room.id,map_key=session.map.meta.key}})
  end
 end
 if room.endedAt and not room.analyticsOutcome then room.analyticsOutcome=true;pcall(self.matchEnd,self,room);self:emit(nil,'match_outcome',{result='complete',human_count=humans,elapsed_seconds=os.time()-room.startedAt},{id='room:'..room.id..':outcome',context={match_id=room.globalMatch or room.id,map_key=session.map.meta.key}})end
end
function M:service(p,operation,ok,started,attempts)self:emit(p,'service_operation',{operation=operation,result=ok and 'ok'or 'failed',duration_ms=(os.clock()-started)*1000,attempts=attempts or 1})end
function M:account(p,a,started)
 self:session(p);self:context(p,{benefit_state=a.owned.permanent and a.clubStatus and a.clubStatus.active and 'both'or a.owned.permanent and 'permanent'or a.clubStatus and a.clubStatus.active and 'club'or 'free'})
 self:emit(p,'profile_load_result',{result=a.ready and 'ok'or 'failed',operation='profile_load',duration_ms=(os.clock()-started)*1000,reason=a.ready and 'none'or Schema.reason(a.error)})
end
function M:matchEnd(room)
 local session=room.session;local sim=session.sim;local w=session.winnerId and sim.players[session.winnerId]
 local humans,ai=0,0;for _,q in ipairs(sim.players)do if q.kind=='HUMAN'then humans+=1 elseif q.kind~='BOT'then ai+=1 end end
 local winner=not w and 'none'or w.kind=='HUMAN'and 'human'or 'ai'
 for uid in pairs(room.members)do local p=Players:GetPlayerByUserId(uid);if p and self.sessions[p]then
  self:flow(p,'match','end',{item=winner,result=Schema.code(session.winReason)or 'none',format=session.winnerTeam and 'team'or 'ffa',mode=Schema.enum('mode',room.mode),human_count=humans,ai_count=ai,simulation_seconds=sim.ticks/10,value=room.startedAt and os.time()-room.startedAt or 0,map_key=session.map.meta.key})
 end end
end
function M:economy(p,delta,balance,transaction,sku,currency)
 if delta==0 then return end;self:session(p);sku=Schema.enum('sku',sku,'other');currency=currency=='Tickets'and 'Tickets'or currency=='Shards'and 'Shards'or 'Medals'
 self:emit(p,'economy_transaction',{amount=delta,balance=balance,currency=currency,sku=sku,result='granted'})
 self:native(p,'',1,'economy',sku,3,{economy=delta>0 and Enum.AnalyticsEconomyFlowType.Source or Enum.AnalyticsEconomyFlowType.Sink,amount=math.abs(delta),balance=balance,transaction=transaction,sku=sku,currency=currency})
end
function M:progression(p,level)
 self:session(p);self:emit(p,'level_reached',{level=level,result='granted'});self:native(p,'',1,'level','complete',3,{progression=true,level=level,levelName='Level '..level})
end
function M:custom(p,name,map,mode,value)
 if name=='TransferFailed'then self:emit(p,'transfer_result',{stage='sending',result='failed',reason='network'})
 elseif name=='QueueJoined'then self:queued(p,mode)
 elseif name=='QueueWait'then self:queueExit(p,'accepted')
 elseif name=='QueueCancelled'then self:queueExit(p,'cancelled')
 elseif name=='DailyOpStarted'then self:emit(p,'daily_op',{stage='start',result='accepted',map_key=map,mode=Schema.enum('mode',mode)})
 elseif name=='DailyOpCleared'then self:emit(p,'daily_op',{stage='outcome',result='complete',map_key=map,outcome=Schema.enum('outcome',mode)})
 elseif name=='ClanJoined'then self:emit(p,'clan_action',{verb='join',result='accepted'});self:flow(p,'clan','join',{result='accepted'})
 elseif name=='ClanCreated'then self:emit(p,'clan_action',{verb='create',result='accepted'});self:flow(p,'clan','create',{result='accepted'})
 elseif name=='ClanAttend'then self:emit(p,'clan_action',{verb='attend',result='accepted'});self:flow(p,'clan','attend',{item=Schema.code(map)or 'free',value=value,result='granted'});if map=='extra'then self:benefit(p,'clanAttend','extra')end
 elseif name=='ClanLeft'or name=='ClanKicked'or name=='ClanPromoted'or name=='ClanEmblem'then local verb=name=='ClanLeft'and 'leave'or name=='ClanKicked'and 'kick'or name=='ClanEmblem'and 'update'or 'promote'
  self:emit(p,'clan_action',{verb=verb,result='accepted'});self:flow(p,'clan',name=='ClanEmblem'and 'emblem'or verb,{result='accepted'})
 elseif name=='ClanRejected'then self:emit(p,'clan_action',{verb=Schema.enum('verb',mode,'other'),result='rejected',reason=Schema.reason(map)});self:flow(p,'clan','rejected',{item=Schema.code(type(map)=='string'and map:gsub('%-','_')or nil),verb=Schema.enum('verb',mode=='joinId'and 'join'or mode=='buyExtra'and 'attend'or mode,'other'),result='rejected'})
 elseif name=='ClanWar'then local r=(map=='won'or mode=='won')and 'won'or 'lost';self:emit(p,'clan_action',{verb='war',result=r});self:flow(p,'clan','warResult',{result=r,value=value})
 elseif name=='FirstCombatOrder'then self:emit(p,'flow_step',{area='match',step='firstOrder',result='accepted',map_key=map,mode=Schema.enum('mode',mode),value=type(value)=='number'and value>=0 and value or nil})end
end
function M:request(p,channel,action,result,value)
 if action=='read'or not p then return end;local s=self.sessions[p];if not s then return end;local ok=type(result)=='table'and result.ok==true
 local message=type(result)=='table'and result.message
 local item=({billingPurchase=true,equipSupply=true,exchange=true,career=true,mode=true})[action]and Schema.code(value)or action=='supplyDraw'and type(value)=='table'and Schema.code(value.kind)or nil
 local data={channel=channel,request=Schema.code(action)or 'other',item=item,result=ok and 'accepted'or 'rejected',reason=ok and 'none'or Schema.reason(message),sig=not ok and message and hash(tostring(message)):sub(1,8)or nil}
 s.requests=s.requests or {};local key=data.request..':'..data.result;s.requests[key]=(s.requests[key]or 0)+1
 if s.requests[key]<=20 then self:emit(p,'request_result',data)else self:project(p,'request_result',data)end
end
function M:flow(p,area,step,data)
 local d=table.clone(data or {});d.area=Schema.enum('area',area,'other');d.step=Schema.code(step)or 'other';self:emit(p,'flow_step',d)
 local s=p and self.sessions[p];if not s then return end
 if d.area=='commerce'and d.step=='receipt'and d.result=='granted'and d.sku then s.paid=s.paid or {};s.paid[d.sku]=true
 elseif d.area=='goals'and d.step=='goalClaim'and d.result=='granted'then self:milestone(p,'claim')end
 if d.area=='campaign'then if d.step=='start'then self:campaignQuit(p,'cancelled');s.campaign={item=d.item,at=os.clock()}elseif d.step=='campaignEnd'then s.campaign=nil end end
end
function M:campaignQuit(p,result)
 local s=p and self.sessions[p];local c=s and s.campaign;if not c then return end
 s.campaign=nil;self:flow(p,'campaign','quit',{item=c.item,value=os.clock()-c.at,result=result,phase=s.phase})
end
function M:benefit(p,sku,item)
 local s=p and self.sessions[p];if not(s and s.paid and s.paid[sku])or s.paid[sku]=='used'then return end
 s.paid[sku]='used';self:flow(p,'commerce','benefit',{sku=sku,item=Schema.code(item),result='ok',first_use=true})
end
function M:flowUser(userId,area,step,data)
 local p=type(userId)=='number'and Players:GetPlayerByUserId(userId);if p then self:flow(p,area,step,data)end
end
function M:flowOnce(p,key,area,step,data)
 local s=p and self.sessions[p];if not s then return end;s.flowOnce=s.flowOnce or {}
 if s.flowOnce[key]then return end;s.flowOnce[key]=true;self:flow(p,area,step,data)
end
function M:rejected()end
function M:watchInbox(name,worker)
 task.spawn(function()local last=0;while not self.closed do task.wait(60);local value=worker.metrics.failures;if value>last then self:emit(nil,'service_operation',{operation=name=='RewardInbox'and 'reward_inbox'or 'career_inbox',result='failed',count=value-last});last=value end end end)
end
function M:pulse()
 local now=os.clock();for p,s in pairs(self.sessions)do
  if now-s.commands.at>=60 then self:flushCommands(p,false)end
  local keep={};for key,f in pairs(s.funnels)do local name=key:match('^(.-):');keep['SC_'..name..'_v1:'..f.id]=true end
  for key in pairs(s.nativeFunnelSent)do if not keep[key]then s.nativeFunnelSent[key]=nil end end
  for _,row in ipairs({{60,'1m'},{300,'5m'},{900,'15m'},{1800,'30m'},{3600,'60m'}})do if now-s.at>=row[1]and Model.once(s,'checkpoint:'..row[2])then self:emit(p,'visit_checkpoint',{phase=s.phase,checkpoint=row[2],elapsed_seconds=now-s.at,matches=s.matches})end end
 end
 if now>=(self.healthAt or 0)then self.healthAt=now+60;pcall(function()game.ReplicatedStorage.FrontierNative:SetAttribute('TelemetryPerfSample',M.sample('telemetryPerf',Config.performanceSample))end);local data=table.clone(self.health);data.stage='flush';data.count=self.health.emitted;data.dropped=self.health.raw_dropped+self.health.native_overflow;data.retention_evictions=self.records.lost;data.result=self.rawEnabled and 'active'or 'inactive';self:emit(nil,'telemetry_health',data)
  local carrier=Players:GetPlayers()[1];local last=self.healthSent or {};self.healthSent=table.clone(self.health)
  if carrier then for _,k in ipairs({'native_skipped','native_failed','native_overflow','invalid','client_rejected'})do local d=(self.health[k]or 0)-(last[k]or 0);if d>0 then self:aggregate(carrier,'SC_TelemetryHealth',d,k,'server')end end end
 end
end
function M:queueState(p,status)
 local s=self.sessions[p];if not s or not status then return end
 local key=tostring(status.phase)..':'..tostring(status.count)..':'..tostring(status.max)
 if key~=s.queueState then s.queueState=key;self:emit(p,'queue_state_changed',{stage='queue',result=status.phase=='recovering'and 'pending'or 'ready',human_count=status.count,seat_cap=status.max,elapsed_seconds=s.queueAt and os.clock()-s.queueAt or 0})end
end
function M:leaving(p)
 local s=self.sessions[p];if not s then return end;local journey,where,seconds=Native.exitStage(s,os.clock())
 self:campaignQuit(p,'closed');self:finalNative(p);s.final=true;if s.queueAt then self:queueExit(p,'left')end
 self:emit(p,'visit_phase_window',{phase=s.phase,elapsed_seconds=os.clock()-s.phaseAt,partial=true,stage='closed'})
 if s.phase~='transfer'then pcall(function()
  self:flow(p,'lobby','exit',{item=s.lastScreen or 'none',phase=s.phase,value=os.clock()-s.at,count=s.matches})
  if journey=='preLobby'or journey=='arrival'then self:flow(p,'lobby','loadExit',{item=journey..'_'..where,value=os.clock()-s.at})end
  local x=self.exitState and self.exitState(p);if x then self:flow(p,'goals','exitBacklog',{count=x.count,value=x.value,available=x.available,result=x.count>0 and 'pending'or 'complete'})end
 end)end
 self:emit(p,s.phase=='transfer'and 'connection_closed'or 'visit_closed',{phase=s.phase,reason=s.phase=='transfer'and 'none'or 'disconnected',elapsed_seconds=os.clock()-s.at,matches=s.matches,journey=journey,where=where,journey_seconds=seconds,marker=s.marker});self:flushCommands(p,true);self.departed[p]=true;self.sessions[p]=nil
end
function M:close()
 if self.closed then return end;for p in pairs(self.sessions)do self:leaving(p)end
 self:emit(nil,'telemetry_health',{stage='shutdown',result='closed',count=self.health.emitted,dropped=self.health.raw_dropped+self.health.native_overflow});self.closed=true
 if self.rawEnabled then local deadline=os.clock()+5;repeat self:drainRaw()until self:rawPending()==0 or self.rawWorking or os.clock()>=deadline end
end
function M:diagnostic()
 return {schema=Schema.version,release=Release,records=Model.array(self.records),native=Model.array(self.nativeRecords),health=table.clone(self.health),retained=self.records.count,retention_evictions=self.records.lost,rawEnabled=self.rawEnabled==true,rawPending=self:rawPending(),localMode=self.localMode,errors=self.errors}
end
return M
