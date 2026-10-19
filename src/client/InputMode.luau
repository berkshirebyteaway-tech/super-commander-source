local UIS=game:GetService("UserInputService")
local M={}
local mouseTypes={[Enum.UserInputType.MouseButton1]=true,[Enum.UserInputType.MouseButton2]=true,[Enum.UserInputType.MouseButton3]=true,[Enum.UserInputType.MouseWheel]=true,[Enum.UserInputType.MouseMovement]=true,[Enum.UserInputType.Keyboard]=true}
function M.fromPreferred(current,value)
    if typeof(value)=='EnumItem'then
        if value.Name=='Touch'then return true end
        if value.Name=='KeyboardAndMouse'then return false end
    end
    return current
end
local function initial()
    local ok,preferred=pcall(function()return UIS.PreferredInput end)
    if ok then local detected=M.fromPreferred(nil,preferred);if detected~=nil then return detected end end
    return UIS.TouchEnabled and not UIS.KeyboardEnabled
end
local touch=initial()
local changed=Instance.new("BindableEvent")
M.changed=changed.Event
function M.touch() return touch end
local function set(value)
    if value==touch then return end
    touch=value;changed:Fire(value)
end
function M.force(value) set(value==true) end
function M.next(current,inputType)
    if inputType==Enum.UserInputType.Touch then return true end
    if mouseTypes[inputType] then return false end
    return current
end
UIS.LastInputTypeChanged:Connect(function(t)
    if t==Enum.UserInputType.Keyboard and UIS:GetFocusedTextBox() then return end
    set(M.next(touch,t))
end)
pcall(function()
    UIS:GetPropertyChangedSignal('PreferredInput'):Connect(function()
        local ok,value=pcall(function()return UIS.PreferredInput end)
        if ok then set(M.fromPreferred(touch,value))end
    end)
end)
return M
