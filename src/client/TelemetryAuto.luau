local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local GuiService=game:GetService('GuiService')
local ScriptContext=game:GetService('ScriptContext')
local LogService=game:GetService('LogService')
local Stats=game:GetService('Stats')
local A={screen='lobby'}
local generic={}
for s in ('Frame TextButton ImageButton TextLabel ImageLabel Button Btn Holder Content Contents Body Row Rows List Grid Container Inner Main Root Panel Page Box Card Item Slot Wrap Wrapper Background Bg Shadow Stroke Pad Padding Layout Scroll ScrollingFrame Template Clone Hit Hitbox Click Area Bar Top Bottom Left Right Center Middle Header Footer Group Line Cell Tile Icon Label Text Title Hover Glow Fill Face Base Front Back Overlay Shade'):gmatch('%S+')do generic[s]=true end
local names={}
local function refreshNames()local t={};for _,p in ipairs(Players:GetPlayers())do t[p.Name:lower()]=true;t[p.DisplayName:lower()]=true end;names=t end
function A.code(name)
 if type(name)~='string'then return nil end
 local s=name:gsub('%d',''):gsub('[^%w_]','')
 if #s<2 or #s>40 or not s:match('^%a')or names[s:lower()]then return nil end
 return s
end
function A.describe(button)
 local gui=button:FindFirstAncestorWhichIsA('LayerCollector')
 local list,panel;local o=button.Parent
 while o and o~=gui do
  if not list and o:IsA('ScrollingFrame')then list=A.code(o.Name)or 'list'end
  if not panel and not generic[o.Name]and not o:IsA('ScrollingFrame')then panel=A.code(o.Name)end
  o=o.Parent
 end
 local control=A.code(button.Name)
 if list then control=control and not generic[control]and control or 'item'elseif not control or generic[control]then control=button.Parent and not generic[button.Parent.Name]and A.code(button.Parent.Name)or control or 'button'end
 return {gui=gui and A.code(gui.Name)or 'gui',panel=panel or (gui and A.code(gui.Name))or 'gui',control=control,list=list}
end
local categories={{'attempt to index nil','nil_index'},{'attempt to call','call_nil'},{'attempt to perform arithmetic','arithmetic'},{'attempt to compare','compare'},
 {'invalid argument','bad_argument'},{'is not a valid member','missing_member'},{'Infinite yield','infinite_yield'},{'Script timeout','script_timeout'},{'timed out','timeout'},
 {'HTTP','http'},{'Teleport','teleport'},{'stack overflow','stack'},{'Unable to cast','cast'},{'Failed to load','asset'},{'asset','asset'},{'Asset','asset'},{'Sound','asset'},
 {'Animation','asset'},{'Image','asset'},{'mesh','asset'},{'deprecated','deprecated'}}
function A.category(message)local s=tostring(message or '');for _,row in ipairs(categories)do if s:find(row[1],1,true)then return row[2]end end;return 'other'end
function A.where(trace,message)
 for _,text in ipairs({tostring(trace or ''),tostring(message or '')})do
  local path,line=text:match('([%w_%.]+):(%d+)')
  if path then return A.code(path:match('([%w_]+)$'))or 'unknown',tonumber(line)end
 end
 return 'unknown',0
end
function A.scrub(text)
 text=tostring(text):gsub('Players%.[^%.%s:]+','Players.?'):gsub('"[^"]*"','"?"'):gsub("'[^']*'","'?'")
 for _,p in ipairs(Players:GetPlayers())do for _,n in ipairs({p.Name,p.DisplayName})do if #n>=3 then text=text:gsub(n:gsub('%p','%%%0'),'?')end end end
 return text:gsub('%c',' '):sub(1,200)
end
local function sig(module,line,category)
 local s=module..':'..tostring(line)..':'..category;local a=5381;for i=1,#s do a=(a*33+s:byte(i))%4294967296 end;return string.format('%08x',a)
end
function A.start(T)
 if A.started then return end;A.started=true;refreshNames()
 Players.PlayerAdded:Connect(refreshNames);Players.PlayerRemoving:Connect(function()task.defer(refreshNames)end)
 local me=Players.LocalPlayer
 task.defer(function()
  local view=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.zero;local short=math.min(view.X,view.Y)
  local class=GuiService:IsTenFootInterface()and 'console'or UIS.TouchEnabled and not UIS.KeyboardEnabled and (short<500 and 'phone'or 'tablet')or UIS.KeyboardEnabled and 'desktop'or 'unknown'
  local quality=0;pcall(function()quality=UserSettings():GetService('UserGameSettings').SavedQualityLevel.Value end)
  T.emit('device_profile',{device_class=class,touch=UIS.TouchEnabled,keyboard=UIS.KeyboardEnabled,gamepad=UIS.GamepadEnabled,quality=quality})
 end)
 local bound=setmetatable({},{__mode='k'});local last,lastAt=nil,0
 local function bind(o)
  if not o:IsA('GuiButton')or bound[o]then return end;bound[o]=true
  o.Activated:Connect(function()
   local d=A.describe(o);local key=d.panel..'/'..d.control
   if key==last and os.clock()-lastAt<.25 then return end;last,lastAt=key,os.clock()
   d.screen=A.screen;T.emit('ui_click',d)
  end)
 end
 task.spawn(function()
  local gui=me:WaitForChild('PlayerGui',30);if not gui then return end
  gui.DescendantAdded:Connect(bind);for _,o in ipairs(gui:GetDescendants())do bind(o)end
 end)
 local lastInput,idleFrom,focused=os.clock(),nil,true
 local function closeIdle(reason)
  if idleFrom then local seconds=os.clock()-idleFrom;idleFrom=nil
   T.emit('idle_window',{screen=A.screen,idle_seconds=seconds,duration_ms=seconds*1000,reason=reason,focused=focused})
  end
 end
 local keys,gestures={},{}
 UIS.InputBegan:Connect(function(input,processed)
  if input.UserInputType==Enum.UserInputType.MouseMovement then return end
  lastInput=os.clock();closeIdle('none')
  if not processed and input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode~=Enum.KeyCode.Unknown then local k=input.KeyCode.Name;keys[k]=(keys[k]or 0)+1 end
 end)
 UIS.InputChanged:Connect(function(input,processed)if not processed and input.UserInputType==Enum.UserInputType.MouseWheel then gestures.wheel=(gestures.wheel or 0)+1 end end)
 for name,signal in pairs({pinch=UIS.TouchPinch,pan=UIS.TouchPan,rotate=UIS.TouchRotate})do
  signal:Connect(function(_,_,_,state,processed)if not processed and state==Enum.UserInputState.Begin then gestures[name]=(gestures[name]or 0)+1 end end)
 end
 local mode
 UIS.LastInputTypeChanged:Connect(function(t)
  local m=t==Enum.UserInputType.Touch and 'touch'or t.Name:find('Gamepad',1,true)and 'gamepad'or (t==Enum.UserInputType.Keyboard or t.Name:find('Mouse',1,true))and 'mouse'or nil
  if m and mode and m~=mode then T.step('input','modeSwitch',{item=m,screen=A.screen})end;mode=m or mode
 end)
 UIS.WindowFocusReleased:Connect(function()closeIdle('closed');focused=false end)
 UIS.WindowFocused:Connect(function()focused=true;lastInput=os.clock()end)
 task.spawn(function()while A.started do task.wait(5)
  if focused and not idleFrom and os.clock()-lastInput>=30 then idleFrom=lastInput end
 end end)
 A.closeIdle=closeIdle
 local errors,warnings={},{}
 ScriptContext.Error:Connect(function(message,trace)
  local module,line=A.where(trace,message);local category=A.category(message);local key=sig(module,line,category)
  local row=errors[key];if row then row.count+=1;return end
  local n=0;for _ in pairs(errors)do n+=1 end;if n>=20 then return end
  errors[key]={module=module,line=line,category=category,count=1}
  T.emit('client_error',{side='client',module=module,line=line,category=category,sig=key,count=1,screen=A.screen,detail=A.scrub(message)})
 end)
 LogService.MessageOut:Connect(function(message,kind)
  if kind~=Enum.MessageType.MessageWarning then return end
  local category=A.category(message);local row=warnings[category]
  if row then row.count+=1 else warnings[category]={count=1,detail=A.scrub(message)}end
 end)
 local frames=0;Run.RenderStepped:Connect(function()frames+=1 end)
 task.spawn(function()local at=os.clock()
  while A.started do task.wait(60)
   local seconds=os.clock()-at;at=os.clock()
   for key,row in pairs(errors)do if row.count>1 then T.emit('client_error',{side='client',module=row.module,line=row.line,category=row.category,sig=key,count=row.count-1,partial=true,window_seconds=seconds})end end
   for category,row in pairs(warnings)do T.emit('client_warning_window',{category=category,count=row.count,detail=row.detail,window_seconds=seconds})end
   errors,warnings={},{}
   for k,n in pairs(keys)do T.step('input','hotkey',{item=k,count=n,value=n})end;keys={}
   for k,n in pairs(gestures)do T.step('map_ui','gesture',{item=k,count=n,value=n})end;gestures={}
   local ping,memory=0,0;pcall(function()ping=me:GetNetworkPing()*1000 end);pcall(function()memory=Stats:GetTotalMemoryUsageMb()end)
   T.emit('client_health_window',{fps=frames/math.max(1,seconds),frames=frames,ping_ms=math.floor(ping),memory_mb=math.floor(memory),window_seconds=seconds,focused=focused})
   frames=0
  end
 end)
end
function A.screenChanged(T,screen)
 if screen==A.screen then return end
 if A.closeIdle then A.closeIdle('replaced')end
 local now=os.clock()
 if A.screenAt then T.emit('screen_dwell',{screen=A.screen,duration_ms=(now-A.screenAt)*1000})end
 A.screen=screen;A.screenAt=now
end
return A
