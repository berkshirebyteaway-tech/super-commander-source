local Players=game:GetService("Players")
local TextService=game:GetService("TextService")
local UI=require(script.Parent.Theme)
local L=require(script.Parent.Localization)
local Badge=require(script.Parent.BenefitBadge)
local Presentation=require(script.Parent.Parent.Core.OutgamePresentation)
local C=UI.colors
local M={}
local function player(who)
    if typeof(who)=="Instance"then return who:IsA("Player")and who or nil end
    if type(who)=="table"then
        if who.id==1 and who.userId==nil then return Players.LocalPlayer end
        who=who.userId
    end
    local id=tonumber(who);if not id then return nil end
    if id==Players.LocalPlayer.UserId then return Players.LocalPlayer end
    return Players:GetPlayerByUserId(id)
end
function M.of(who)
    local p=player(who);if not p then return nil end
    local level=p:GetAttribute("CommanderLevel");if type(level)~="number"then return nil end
    local plate=p:GetAttribute("CommanderPlate")
    return {level=level,plate=typeof(plate)=="Color3"and plate or nil,vip=p:GetAttribute('CommanderVIP')==true,permanent=p:GetAttribute('CommanderPermanent')==true,cosmeticTier=p:GetAttribute('CommanderCosmeticTier')or 0}
end
function M.line(h)return h and((h.permanent and L.text('커맨더 프라임')..'  'or '')..(h.vip and '◆ VIP  'or '')..string.format("Lv. %d",h.level))or""end
function M.edge(color)
    local lum=.299*color.R+.587*color.G+.114*color.B
    return lum<.3 and color:Lerp(C.ink,.35)or color
end
function M.ink(color)return(.299*color.R+.587*color.G+.114*color.B)>.6 and C.bg or C.ink end
function M.pill(name,color,pad)
    local parent=name.Parent;local plate=parent and parent:FindFirstChild(name.Name.."Plate")
    if not color or not name.Visible or name.Text==""then if plate then plate.Visible=false end;return end
    if not plate then
        plate=UI.make("Frame",parent,{Name=name.Name.."Plate",BorderSizePixel=0,ZIndex=math.max(1,name.ZIndex-1)})
        UI.corner(plate,3);UI.stroke(plate,color,1)
    end
    pad=pad or 5
    local box=name.Size;local size=TextService:GetTextSize(name.Text,name.TextSize,name.Font,Vector2.new(4096,4096))
    local w=math.min(size.X,box.X.Offset);local h=math.min(box.Y.Offset,math.ceil(name.TextSize*1.2)+4)
    local x=name.Position.X.Offset
    if name.TextXAlignment==Enum.TextXAlignment.Right then x+=box.X.Offset-w elseif name.TextXAlignment==Enum.TextXAlignment.Center then x+=(box.X.Offset-w)/2 end
    plate.Position=UDim2.fromOffset(x-pad,name.Position.Y.Offset+(box.Y.Offset-h)/2);plate.Size=UDim2.fromOffset(w+pad*2,h)
    plate.BackgroundColor3=color;plate.BackgroundTransparency=.76;local edge=plate:FindFirstChildOfClass("UIStroke");edge.Color=M.edge(color);edge.Transparency=.15;plate.Visible=true
end
function M.decorate(gui)
    local tag=gui:FindFirstChild("Honor");if tag then return tag end
    for _,o in ipairs(gui:GetChildren())do if o:IsA("TextLabel")then o.Visible=false end end
    gui.Size=UDim2.fromOffset(320,48)
    tag=UI.make("Frame",gui,{Name="Honor",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(120,38),BackgroundColor3=C.bg,BackgroundTransparency=.16,BorderSizePixel=0})
    UI.corner(tag,3);UI.stroke(tag,C.line,1)
    UI.make('UIScale',tag,{Name='DistanceScale',Scale=1})
    local level=UI.make("TextLabel",tag,{Name="Level",Position=UDim2.fromOffset(5,5),Size=UDim2.fromOffset(28,28),BackgroundColor3=C.raised,BorderSizePixel=0,Text="",TextSize=14,TextColor3=C.ink,Font=Enum.Font.BuilderSansBold,AutoLocalize=false})
    UI.corner(level,3);UI.display(level,true)
    local n=UI.make("TextLabel",tag,{Name="Commander",BackgroundTransparency=1,Font=Enum.Font.BuilderSansBold,TextSize=14,TextColor3=C.ink,TextXAlignment=Enum.TextXAlignment.Left,Text="",AutoLocalize=false})
    for _,o in ipairs({level,n})do o:SetAttribute("LocalizationSkip",true)end
    return tag
end
local function width(label)return math.ceil(TextService:GetTextSize(label.Text,label.TextSize,label.Font,Vector2.new(4096,64)).X)+2 end
function M.fill(tag,p,h)
    local level,n=tag:FindFirstChild("Level"),tag:FindFirstChild("Commander")
    local unit=p:GetAttribute("CommanderClan");local shown=type(unit)=="string"and unit~=""and string.format("[%s] %s",unit,p.DisplayName)or p.DisplayName
    local key=shown.."|"..tostring(h and h.level)..'|'..tostring(h and h.vip)..'|'..tostring(h and h.permanent)..'|'..tostring(h and h.cosmeticTier)
    if tag:GetAttribute("Layout")~=key then
        tag:SetAttribute("Layout",key)
        n.Text=shown;level.Text=h and tostring(h.level)or ""
        level.Visible=h~=nil
        local x=h and 41 or 10;local height=30
        local wn=math.min(width(n),220)
        UI.box(n,x,0,wn,height)
        level.Position=UDim2.fromOffset(5,(height-28)/2)
        local old=tag:FindFirstChild('VIP');if old then old:Destroy()end
        local badge=tag:FindFirstChild('BenefitBadge')
        if badge then badge:Destroy()end
        local glyph=Badge.create(tag);Badge.update(glyph,h and h.permanent,h and h.vip)
        UI.box(glyph.root,x+wn+5,math.floor((height-18)/2),glyph.root.Size.X.Offset,18)
        local oldDot=tag:FindFirstChild('CosmeticGrade');if oldDot then oldDot:Destroy()end
        local hasGrade=h and (h.cosmeticTier or 0)>=3;local badgeWidth=glyph.root.Visible and Badge.width(glyph)+7 or 0
        if hasGrade then
            local color=({[3]=Color3.fromRGB(173,119,255),[4]=C.gold,[5]=Color3.fromRGB(157,242,235)})[h.cosmeticTier]
            local dot=UI.make('Frame',tag,{Name='CosmeticGrade',BackgroundColor3=color,BorderSizePixel=0});UI.corner(dot,40);UI.box(dot,x+wn+badgeWidth+5,math.floor(height/2)-3,6,6)
        end
        tag.Size=UDim2.fromOffset(x+wn+badgeWidth+(hasGrade and 14 or 0)+10,height)
    end
    if h then level.BackgroundColor3=h.plate or C.raised;level.TextColor3=h.plate and M.ink(h.plate)or C.ink end
    local edge=tag:FindFirstChildOfClass("UIStroke");edge.Color=h and h.plate and M.edge(h.plate)or C.line;edge.Thickness=h and h.plate and 1.5 or 1
end
local function honorLine(player,c)
    local billboard=c:FindFirstChild('CommanderName');if not billboard then return end
    local h=M.of(player);if not h then return end
    M.fill(M.decorate(billboard),player,h)
end
local function refresh(player)local c=player.Character;if c then pcall(honorLine,player,c);local old=c:FindFirstChild('CommanderBanner');if old then old:Destroy()end end end
function M.start()
    if M.started then return end;M.started=true
    M.watchers={};M.connections={};local generation=(M.generation or 0)+1;M.generation=generation
    local function watch(player)
        if M.watchers[player]then return end
        local links={};M.watchers[player]=links
        table.insert(links,player.CharacterAdded:Connect(function(c)c:WaitForChild('HumanoidRootPart',10);task.wait(.5);if M.generation==generation and M.watchers[player]then refresh(player)end end))
        for _,key in ipairs({'CommanderLevel','CommanderPlate','CommanderClan','CommanderVIP','CommanderPermanent','CommanderCosmeticTier'})do table.insert(links,player:GetAttributeChangedSignal(key):Connect(function()refresh(player)end))end
        refresh(player)
    end
    for _,p in ipairs(Players:GetPlayers())do watch(p)end
    table.insert(M.connections,Players.PlayerAdded:Connect(watch))
    if not M.localeHooked then M.localeHooked=true;L.onLocale(function()if M.started then for p in pairs(M.watchers or {})do refresh(p)end end end)end
    table.insert(M.connections,Players.PlayerRemoving:Connect(function(p)for _,c in ipairs(M.watchers[p]or {})do c:Disconnect()end;M.watchers[p]=nil end))
    local elapsed=0
    table.insert(M.connections,game:GetService('RunService').Heartbeat:Connect(function(dt)
        elapsed+=dt;if elapsed<.1 then return end;elapsed=0
        local camera=workspace.CurrentCamera;if not camera then return end
        local touch=require(script.Parent.InputMode).touch()
        for p in pairs(M.watchers)do
            local c=p.Character;local b=c and c:FindFirstChild('CommanderName');local root=c and c:FindFirstChild('HumanoidRootPart')
            local tag=b and b:FindFirstChild('Honor');local scale=tag and tag:FindFirstChild('DistanceScale')
            if b and b.Enabled and root and scale then scale.Scale=Presentation.nameScale((camera.CFrame.Position-root.Position).Magnitude)*(touch and .82 or 1)end
        end
    end))
    task.spawn(function()while M.generation==generation do task.wait(3);if M.generation~=generation then break end;for _,p in ipairs(Players:GetPlayers())do local c=p.Character;local b=c and c:FindFirstChild('CommanderName');if b and not b:FindFirstChild('Honor')then refresh(p)end end end end)
end
function M.stop()
    M.generation=(M.generation or 0)+1;M.started=false
    for _,links in pairs(M.watchers or {})do for _,c in ipairs(links)do c:Disconnect()end end;M.watchers={}
    for _,c in ipairs(M.connections or {})do c:Disconnect()end;M.connections={}
end
return M
