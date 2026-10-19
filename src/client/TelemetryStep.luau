local M={seen={},last={}}
local T
local function get()
 if T==nil then local ok,v=pcall(function()return require(script.Parent.TelemetryClient)end);T=ok and v or false end
 return T
end
function M.code(v)
 if type(v)=='number'then v=tostring(v)end;if type(v)~='string'then return nil end
 local s=v:gsub('[^%w_]','_'):gsub('^[^%a]+',''):sub(1,40)
 return #s>=2 and s or nil
end
function M.step(area,step,data)local t=get();if t and t.step then pcall(t.step,area,step,data)end end
function M.ui(panel,control,data)local t=get();if t and t.ui then pcall(t.ui,panel,control,data)end end
function M.emit(name,data)local t=get();if t and t.emit then pcall(t.emit,name,data)end end
function M.once(key,area,step,data)if M.seen[key]then return end;M.seen[key]=true;M.step(area,step,data)end
function M.change(key,area,step,data)
 local d=data or {};local sig=tostring(d.result)..'|'..tostring(d.item)..'|'..tostring(d.value)
 if M.last[key]==sig then return end;M.last[key]=sig;M.step(area,step,d)
end
return M
