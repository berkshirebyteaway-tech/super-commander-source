local UI=require(script.Parent.ToyUI)
local M={}
local function now()local ok,t=pcall(function()return workspace:GetServerTimeNow()end);return ok and t or os.time()end
function M.ready(billing)return type(billing)=='table'and type(billing.freeDrawAt)=='number'and now()>=billing.freeDrawAt end
function M.dot(parent,on,x,y,size)
    require(script.Parent.TelemetryStep).change('dot:'..parent.Name,'shop','freeDrawDot',{item=require(script.Parent.TelemetryStep).code(parent.Name),result=on and 'shown'or 'closed'})
    local d=parent:FindFirstChild('FreeDrawDot')
    if not d then
        size=size or 10
        d=UI.corner(UI.make('Frame',parent,{Name='FreeDrawDot',AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(size,size),BackgroundColor3=UI.colors.danger,BorderSizePixel=0,ZIndex=parent.ZIndex+2,Active=false}),999)
        UI.stroke(d,UI.colors.bg,1.5)
    end
    if x then d.Position=UDim2.fromOffset(x,y)end
    d.Visible=on==true;return d
end
return M
