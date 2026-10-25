local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local UI=require(script.Parent.ToyUI)
local Rules=require(script.Parent.Parent.Core.OpsRules)
local Step=require(script.Parent.TelemetryStep)
local M={}
local started=false
local function now()local ok,t=pcall(function()return workspace:GetServerTimeNow()end);return ok and t or os.time()end
function M.start()
    if started then return M end;started=true
    local pack=script.Parent.Parent
    local me=Players.LocalPlayer
    local en=me.LocaleId:sub(1,2)~='ko'
    local gui=UI.make('ScreenGui',me:WaitForChild('PlayerGui'),{Name='OpsTopLine',ResetOnSpawn=false,DisplayOrder=40,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,AutoLocalize=false,Enabled=true})
    local line=UI.make('TextLabel',gui,{Name='Line',Text='',TextSize=14,Font=Enum.Font.BuilderSansBold,TextColor3=UI.colors.ink,BackgroundColor3=UI.colors.bg,BackgroundTransparency=.28,
        BorderSizePixel=0,AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,6),Size=UDim2.fromOffset(0,28),AutomaticSize=Enum.AutomaticSize.X,TextWrapped=false,
        TextTruncate=Enum.TextTruncate.AtEnd,Visible=false,Active=false,Selectable=false})
    UI.corner(line,3);local pad=UI.make('UIPadding',line,{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)})
    UI.make('UISizeConstraint',line,{MaxSize=Vector2.new(640,28)})
    local edge=UI.stroke(line,UI.colors.line,1)
    local dot=UI.make('Frame',line,{Name='Dot',BackgroundColor3=UI.colors.gold,BorderSizePixel=0,AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,-12+6,.5,0),Size=UDim2.fromOffset(6,6),Active=false})
    UI.corner(dot,40)
    local function fitWidth()local w=gui.AbsoluteSize.X;if w>0 then line.UISizeConstraint.MaxSize=Vector2.new(math.min(640,w-32),28)end end
    gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(fitWidth);fitWidth()
    local shown
    local function refresh()
        local t=now()
        local p={state=pack:GetAttribute('OpsState')or 'normal',closeAt=tonumber(pack:GetAttribute('OpsCloseAt')),reopenAt=tonumber(pack:GetAttribute('OpsReopenAt'))}
        if p.closeAt==0 then p.closeAt=nil end;if p.reopenAt==0 then p.reopenAt=nil end
        p.moveAt=tonumber(me:GetAttribute('OpsMoveAt'))
        if (p.state=='warn'or p.state=='gated')and not p.closeAt then p.state='normal'end
        local flash={text=pack:GetAttribute('OpsFlash')or '',textEn=pack:GetAttribute('OpsFlashEn')or '',untilAt=tonumber(pack:GetAttribute('OpsFlashUntil'))or 0}
        local text,kind=Rules.topLine(p,t,en,flash,pack:GetAttribute('OpsTicker'),pack:GetAttribute('OpsTickerEn'))
        line.Visible=text~=nil
        if text and line.Text~=text then line.Text=text end
        local loud=kind=='phase'or kind=='flash'
        dot.Visible=loud;pad.PaddingLeft=UDim.new(0,loud and 20 or 12);dot.Position=UDim2.new(0,(loud and -20 or -12)+8,.5,0);edge.Color=loud and UI.colors.gold:Lerp(UI.colors.line,.45)or UI.colors.line
        line.TextColor3=loud and UI.colors.ink or UI.colors.ink:Lerp(UI.colors.muted,.35)
        local key=kind and (kind..':'..(kind=='phase'and p.state or text))or nil
        if key~=shown then shown=key;if kind then Step.step('ops','topLine',{item=kind=='phase'and p.state or kind,result='shown'})end end
    end
    for _,name in ipairs({'OpsState','OpsCloseAt','OpsReopenAt','OpsFlash','OpsFlashUntil','OpsTicker','OpsTickerEn'})do pack:GetAttributeChangedSignal(name):Connect(refresh)end
    me:GetAttributeChangedSignal('OpsMoveAt'):Connect(refresh)
    task.spawn(function()while gui.Parent do pcall(refresh);task.wait(1)end end)
    local function open()if me:GetAttribute('OpsAdmin')==true then require(script.Parent.OpsConsole).toggle()end end
    task.spawn(function()local ev=pack:WaitForChild('OpsOpen',30);if ev then ev.OnClientEvent:Connect(open)end end)
    UIS.InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.F8 then open()end end)
    return M
end
return M
