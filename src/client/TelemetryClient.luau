local Pack=game.ReplicatedStorage:WaitForChild('FrontierNative')
local Schema=require(Pack.Core.TelemetrySchema)
Schema.maps={};for _,map in ipairs(require(Pack.Maps.MapLoader).catalog)do Schema.maps[map.key]=true end
local Model=require(Pack.Core.TelemetryModel)
local UIS=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local Auto=require(script.Parent.TelemetryAuto)
local M={queue=Model.ring(512),sequence=0,commands={},startedAt=os.clock(),phase='boot',seen={},order=Model.ring(1024)}
do local ok,locale=pcall(function()return game:GetService('LocalizationService').RobloxLocaleId end);M.locale=ok and Schema.enum('locale',locale:lower():match('^%a+'),'other')or 'other'end
local function input()
 local t=UIS:GetLastInputType();return t==Enum.UserInputType.Touch and 'touch'or t.Name:find('Gamepad',1,true)and 'gamepad'or 'mouse'
end
local function viewport()
 local camera=workspace.CurrentCamera;local v=camera and camera.ViewportSize or Vector2.zero
 return v.Y>v.X and 'portrait'or v.X<800 and 'small'or v.X<1400 and 'medium'or 'large'
end
function M.emit(name,data)
 data=table.clone(data or {});data.input_mode=input();data.viewport_bucket=viewport();data.phase=M.phase;data.locale=M.locale
 local clean=Schema.clean(name,data,true);if not clean then return false end
 M.sequence+=1;Model.push(M.queue,{name=name,data=clean,sequence=M.sequence})
 if name=='screen_viewed'and clean.screen then Auto.screenChanged(M,clean.screen)end
 return true
end
function M.ui(panel,control,data)
 local d=table.clone(data or {});d.panel=panel;d.control=control;d.screen=d.screen or Auto.screen;return M.emit('ui_click',d)
end
function M.step(area,step,data)
 local d=table.clone(data or {});d.area=Schema.enum('area',area,'other');d.step=step;return M.emit('flow_step',d)
end
function M.visible(o)
 while o and not o:IsA('PlayerGui')do if o:IsA('GuiObject')and not o.Visible or o:IsA('LayerCollector')and not o.Enabled then return false end;o=o.Parent end
 return o~=nil
end
function M.flush()
 if not M.remote or M.queue.count==0 then return end
 local batch={};for _=1,math.min(Schema.clientBatch,14)do local e=Model.pop(M.queue);if not e then break end;table.insert(batch,e)end
 M.remote:FireServer({events=batch})
end
function M.start()
 if M.started then return M end;M.started=true
 task.spawn(function()
  M.remote=Pack:WaitForChild('Telemetry',30)
  while M.started do task.wait(2);M.flush()end
 end)
 local me=game.Players.LocalPlayer
 local function sampled()local v=Pack:GetAttribute('TelemetryPerfSample');v=type(v)=='number'and v or .1;return Run:IsStudio()or me.UserId%100<v*100 end
 M.perf=sampled()
 pcall(function()Auto.start(M)end)
 task.spawn(function()
  local gui=me.PlayerGui:WaitForChild('FrontierNativeUI',30);if not gui then return end
  local bound=setmetatable({},{__mode='k'})
  local function bind(o)
   if o:IsA('GuiButton')and o.Parent and o.Parent.Name=='ResultActions'and not bound[o]then bound[o]=true;o.Activated:Connect(function()
    M.emit('result_action',{verb=o.Name=='Again'and 'again'or o.Name=='ChooseMode'and 'leave'or o.Name=='Spectate'and 'follow'or o.Name=='Share'and 'share'or o.Name=='Comrades'and 'invite'or o.Name=='Back'and 'cancel'or 'other',stage='selected',result=M.result or 'unknown',version=M.version})
    local c=o.Name=='Again'and M.campaign;if type(c)=='table'and type(c.id)=='string'then local id=c.next or c.id
     M.step('campaign',c.next and 'nextMission'or 'retryMission',{item='stage_'..tostring(id):gsub('%-','_'),result='selected',version=M.version})end
   end)end
  end
  gui.DescendantAdded:Connect(bind);for _,o in ipairs(gui:GetDescendants())do bind(o)end
 end)
 local function startPerf()
  if M.frames then return end
  local w=Model.window(os.clock())
  M.frames=Run.RenderStepped:Connect(function(dt)Model.histogram(w,Schema.frameBucket(dt*1000),dt*1000)end)
  task.spawn(function()while M.started do task.wait(30)
   local data={samples=0,sum_ms=w.sum,max_ms=w.max,window_seconds=os.clock()-w.at}
   for k,v in pairs(w.latency)do data[k]=v;data.samples+=v end
   M.emit('client_performance_window',data);w=Model.window(os.clock())
  end end)
 end
 if M.perf then startPerf()end
 Pack:GetAttributeChangedSignal('TelemetryPerfSample'):Connect(function()if not M.perf and sampled()then M.perf=true;startPerf()end end)
 return M
end
function M.state(s)
 if not s or s.ownershipOnly then return end
 local phase=s.phase=='menu'and (s.loading and 'boot'or 'lobby')or s.drop and s.drop.active and 'drop'or s.observer and 'spectate'or s.eliminated and 'spectate'or (s.phase=='won'or s.phase=='lost')and 'result'or 'playing'
 M.result=s.personalResult and s.personalResult.outcome or 'unknown';M.campaign=s.personalResult and s.personalResult.campaign
 if phase~=M.phase then M.phase=phase;M.emit('screen_viewed',{screen=phase=='playing'and 'game'or phase=='drop'and 'game'or phase=='boot'and 'lobby'or phase,result='shown',version=s.version})end
 if M.version~=s.version then
  if M.version then M.flush()end;M.version=s.version
 end
 if not M.readyAt and not s.loading then task.defer(function()
  if M.readyAt then return end;M.readyAt=os.clock();M.emit('boot_stage',{stage='client_ready',result='ok',duration_ms=(M.readyAt-M.startedAt)*1000})
  task.spawn(function()for _=1,60 do local v=game.Players.LocalPlayer:GetAttribute('LoadCoverStages');if type(v)=='string'then
   local loaded,total,ui,capped=v:match('^(%d+),(%d+),(%d),(%d)$');if total then local r=capped=='1'and 'timeout'or ui=='0'and 'failed'or 'ok';M.step('lobby','loadCover',{value=tonumber(total)/1000,duration_ms=tonumber(loaded),result=r});M.step('lobby','loadGame',{value=tonumber(loaded)/1000,result=r})end;return end;task.wait(.5)end end)
  task.spawn(function()for _=1,60 do local me=game.Players.LocalPlayer;local cover,ui=me:GetAttribute('LoadCoverClocks'),me:GetAttribute('LoadUiClocks');if type(cover)=='string'and type(ui)=='string'then
   local loaded,painted=cover:match('^([%d%.]+),([%d%.]+)$');local boot,modules,built,first=ui:match('^([%d%.]+),([%d%.]+),([%d%.]+),([%d%.]+)$')
   if loaded and boot then local t={tonumber(loaded),tonumber(boot),tonumber(modules),tonumber(built),tonumber(first),tonumber(painted)}
    for i,step in ipairs({'loadWait','loadCode','loadBuild','loadState','loadPaint'})do M.step('lobby',step,{value=math.max(0,t[i+1]-t[i])})end end;return end;task.wait(.5)end end)
 end)end
end
function M.sent(id,action,version)
 M.commands[id]={at=os.clock(),action=Schema.action(action),version=version}
 M.emit('action_flow',{stage='selected',action=Schema.action(action),command_id=id,version=version})
 task.delay(8,function()local r=M.commands[id];if r and r.version==version then M.commands[id]=nil;M.emit('command_feedback_seen',{action=r.action,command_id=id,version=version,result='timeout',reason='response_missing',duration_ms=(os.clock()-r.at)*1000})end end)
end
function M.received(r)
 local sent=M.commands[r.requestId];if not sent or r.action~=sent.action then return end;M.commands[r.requestId]=nil
 M.emit('command_feedback_seen',{action=sent.action,command_id=r.requestId,version=sent.version,result=r.ok and 'accepted'or 'rejected',reason=r.ok and 'none'or Schema.reason(r.message),duration_ms=(os.clock()-sent.at)*1000})
end
function M.flow(stage,action)
 local key=stage..':'..tostring(action)..':'..tostring(M.version)
 if M.lastFlow==key then return end;M.lastFlow=key;M.emit('action_flow',{stage=stage,action=Schema.action(action),version=M.version})
end
function M.card(frame,field,position,entry)
 frame:SetAttribute('TelemetryCard',true)
 M.cards=M.cards or setmetatable({},{__mode='k'})
 local old=M.cards[frame]
 if old and old.field.id==field.id and old.entry==entry then old.field=field;old.position=position
 else M.cards[frame]={field=field,position=position,entry=entry}end
 if not M.cardWorker then M.cardWorker=true;task.spawn(function()while M.started do task.wait(.25)
  for f,item in pairs(M.cards)do if f.Parent then
   local visible=M.visible(f);local pos,size=f.AbsolutePosition,f.AbsoluteSize;local camera=workspace.CurrentCamera;local view=camera and camera.ViewportSize or Vector2.zero
   local left,top,right,bottom=math.max(0,pos.X),math.max(0,pos.Y),math.min(view.X,pos.X+size.X),math.min(view.Y,pos.Y+size.Y)
   local parent=f.Parent
   while visible and parent and parent:IsA('GuiObject')do
    if parent.ClipsDescendants or parent:IsA('ScrollingFrame')then local p,z=parent.AbsolutePosition,parent.AbsoluteSize;left=math.max(left,p.X);top=math.max(top,p.Y);right=math.min(right,p.X+z.X);bottom=math.min(bottom,p.Y+z.Y)end
    parent=parent.Parent
   end
   visible=visible and math.max(0,right-left)*math.max(0,bottom-top)>=size.X*size.Y*.5 and size.X*size.Y>0
   if visible then item.since=item.since or os.clock();local key='card:'..item.field.id..':'..item.entry
    if os.clock()-item.since>=1 and Model.once(M,key)then
     if item.offer then
      if Model.once(M,'offer:'..item.offer)then M.emit('offer_impression',{sku=item.offer,eligible=item.available,result=item.available and 'ready'or 'unavailable'})end
      M.step('commerce','offer',{sku=item.offer,origin=item.origin,result=item.result,reason=item.reason})
     else M.emit('battlefield_impression',{entry=item.entry,format=item.field.rules.mode=='teams'and 'team'or item.field.rules.mode=='coop'and 'coop'or 'ffa',position=item.position,eligible=true,version=M.version,field_id=item.field.id,map_key=item.field.rules.map})end
    end
   else item.since=nil end
  else M.cards[f]=nil end end
 end end)end
end
function M.offer(frame,sku,available,origin,billing)
 origin=Schema.enum('origin',origin,'other')
 M.card(frame,{id='offer-'..sku..'-'..origin,rules={mode='custom'}},0,'home');local c=M.cards[frame];c.offer=sku;c.available=available==true;c.origin=origin
 c.result,c.reason=M.offerState(billing,sku,available)
end
function M.offerState(billing,sku,available)return require(Pack.Core.TelemetryNative).offerState(billing,sku,available)end
function M.offerSeen(sku,origin,result,reason)
 origin=Schema.enum('origin',origin,'other');if not Model.once(M,'offerSeen:'..sku..':'..origin)then return end
 M.step('commerce','offer',{sku=sku,origin=origin,result=result,reason=reason})
end
return M
