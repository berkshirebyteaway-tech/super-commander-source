local Players=game:GetService('Players')
local UI=require(script.Parent.Theme)
local L=require(script.Parent.Localization)
local M={}
local gui,cover,ring,caption,spin,token
local function build()
    if gui and gui.Parent then return end
    gui=Instance.new('ScreenGui');gui.Name='TransitionVeil';gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.DisplayOrder=45;gui.Enabled=false;gui.AutoLocalize=false
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;require(script.Parent.FullBleed).watch(gui)
    cover=UI.make('TextButton',gui,{Name='Cover',Text='',AutoButtonColor=false,Size=UDim2.fromScale(1,1),BackgroundColor3=UI.colors.bg,BackgroundTransparency=.2,BorderSizePixel=0,Active=true,Selectable=false})
    ring=UI.make('ImageLabel',cover,{Name='Spinner',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,.5,-14),Size=UDim2.fromOffset(40,40),BackgroundTransparency=1})
    local face=UI.make('Frame',ring,{Name='Ring',Size=UDim2.fromScale(1,1),BackgroundTransparency=1});UI.corner(face,999)
    local line=UI.stroke(face,UI.colors.accent,3);line.Transparency=0
    UI.make('UIGradient',line,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.6,.15),NumberSequenceKeypoint.new(1,1)})})
    caption=UI.make('TextLabel',cover,{Name='Caption',AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,.5,18),Size=UDim2.new(1,-32,0,24),BackgroundTransparency=1,
        Font=Enum.Font.BuilderSansBold,TextSize=16,TextColor3=UI.colors.ink,Text=''})
    gui.Parent=Players.LocalPlayer:WaitForChild('PlayerGui')
end
function M.show(text,timeout)
    build();token=(token or 0)+1;local mine=token
    caption.Text=L.text(text or '이동 중…');gui.Enabled=true
    if not spin then local a=0;spin=game:GetService('RunService').Heartbeat:Connect(function(dt)a=(a+dt*360)%360;ring.Rotation=a end)end
    task.delay(timeout or 12,function()if token==mine then M.hide()end end)
end
function M.settle(seconds)local mine=token;task.delay(seconds or 3,function()if token==mine then M.hide()end end)end
function M.hide()
    token=(token or 0)+1
    if spin then spin:Disconnect();spin=nil end
    if gui then gui.Enabled=false end
end
function M.bind(ui)ui:GetAttributeChangedSignal('Phase'):Connect(function()if token then M.hide()end end);return M end
function M.shown()return gui~=nil and gui.Enabled end
function M.teleport(text)
    M.show(text,20)
    pcall(function()game:GetService('TeleportService'):SetTeleportGui(gui)end)
end
return M
