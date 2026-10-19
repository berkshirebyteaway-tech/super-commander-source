local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local ScriptContext=game:GetService('ScriptContext')
local LogService=game:GetService('LogService')
local Stats=game:GetService('Stats')
local Schema=require(game.ReplicatedStorage.FrontierNative.Core.TelemetrySchema)
local M={}
local categories={{'attempt to index nil','nil_index'},{'attempt to call','call_nil'},{'attempt to perform arithmetic','arithmetic'},{'attempt to compare','compare'},
 {'invalid argument','bad_argument'},{'is not a valid member','missing_member'},{'Infinite yield','infinite_yield'},{'Script timeout','script_timeout'},{'timed out','timeout'},{'timeout','timeout'},
 {'HTTP','http'},{'Http','http'},{'DataStore','datastore'},{'MemoryStore','memorystore'},{'Teleport','teleport'},{'stack overflow','stack'},{'Unable to cast','cast'},
 {'Failed to load','asset'},{'asset','asset'},{'Asset','asset'},{'deprecated','deprecated'}}
function M.category(message)
 local s=tostring(message or '')
 for _,row in ipairs(categories)do if s:find(row[1],1,true)then return row[2]end end
 return 'other'
end
function M.where(trace,message)
 for _,text in ipairs({tostring(trace or ''),tostring(message or '')})do
  local path,line=text:match('([%w_%.]+):(%d+)')
  if path then return Schema.code((path:match('([%w_]+)$')or ''):gsub('%d',''))or 'unknown',tonumber(line)end
 end
 return 'unknown',0
end
function M.signature(t,module,line,category)return t.key(module..':'..tostring(line)..':'..category):sub(1,8)end
function M.tag(message)local first=tostring(message or ''):match('^([%a][%w_]*)[%s:]');return first and #first<=20 and first:lower()==first and first or nil end
function M.start(t)
 if M.started then return end;M.started=true
 local errors,warnings,windowAt={},{},os.clock()
 ScriptContext.Error:Connect(function(message,trace,scr)
  local module,line=M.where(trace,message);local category=M.category(message);local sig=M.signature(t,module,line,category)
  local row=errors[sig]
  if row then row.count+=1;return end
  local n=0;for _ in pairs(errors)do n+=1 end;if n>=40 then t.health.invalid+=1;return end
  errors[sig]={module=module,line=line,category=category,count=1}
  t:emit(nil,'script_error',{side='server',module=module,line=line,category=category,sig=sig,count=1,detail=t:scrub(message)})
 end)
 LogService.MessageOut:Connect(function(message,kind)
  if kind~=Enum.MessageType.MessageWarning then return end
  local category=M.category(message);local tag=M.tag(message);if tag and category=='other'then category='game_warn'end
  local key=category..':'..(tag or '');local row=warnings[key]
  if row then row.count+=1 else warnings[key]={category=category,tag=tag,count=1,detail=t:scrub(message)}end
 end)
 local frames=0;Run.Heartbeat:Connect(function()frames+=1 end)
 task.spawn(function()while not t.closed do task.wait(60)
  local seconds=os.clock()-windowAt;windowAt=os.clock();local errorCount,warningCount=0,0
  for sig,row in pairs(errors)do errorCount+=row.count;if row.count>1 then t:emit(nil,'script_error',{side='server',module=row.module,line=row.line,category=row.category,sig=sig,count=row.count-1,window_seconds=seconds,partial=true})end end
  for _,row in pairs(warnings)do warningCount+=row.count;t:emit(nil,'server_warning_window',{side='server',category=row.category,tag=row.tag,count=row.count,detail=row.detail,window_seconds=seconds})end
  errors,warnings={},{}
  local memory=0;pcall(function()memory=Stats:GetTotalMemoryUsageMb()end)
  local kin,kout=0,0;pcall(function()kin=Stats.DataReceiveKbps;kout=Stats.DataSendKbps end)
  t:emit(nil,'server_health_window',{players=#Players:GetPlayers(),memory_mb=math.floor(memory),heartbeat_fps=frames/math.max(1,seconds),instances=Stats.InstanceCount,
   kbps_in=math.floor(kin),kbps_out=math.floor(kout),errors=errorCount,warnings=warningCount,window_seconds=seconds})
  frames=0
 end end)
end
return M
