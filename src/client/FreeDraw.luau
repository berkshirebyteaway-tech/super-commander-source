local UI=require(script.Parent.ToyUI)
local M={}
local function now()local ok,t=pcall(function()return workspace:GetServerTimeNow()end);return ok and t or os.time()end
function M.ready(billing)return type(billing)=='table'and type(billing.freeDrawAt)=='number'and now()>=billing.freeDrawAt end
function M.dot(parent,on)
    require(script.Parent.TelemetryStep).change('dot:'..parent.Name,'shop','freeDrawDot',{item=require(script.Parent.TelemetryStep).code(parent.Name),result=on and 'shown'or 'closed'})
    return require(script.Parent.RedDot).set(parent,'FreeDrawDot',on==true)
end
return M
