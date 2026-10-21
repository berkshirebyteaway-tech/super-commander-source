local Players=game:GetService("Players")
local G=require(script.Parent.Parent.Core.WorldGeometry)
local UI=require(script.Parent.Theme)
local Colors=require(script.Parent.FactionColors)
local L=require(script.Parent.Localization)
local Avatar=require(script.Parent.AvatarPortrait)
local Badge=require(script.Parent.BenefitBadge)
local Glyphs=require(script.Parent.ActionGlyphs)
local InputMode=require(script.Parent.InputMode)
local TextService=game:GetService("TextService")
local M={};M.__index=M
M.RING=3.5
local amber,lime=Color3.fromRGB(255,82,82),Color3.fromRGB(180,240,90)
function M.new(playerGui,flags)
    local self=setmetatable({gui=playerGui,flags=flags,tags={},rings={},folder=nil,clock=0},M)
    self.folder=Instance.new("Folder");self.folder.Name="CommanderRings";self.folder.Parent=workspace
    return self
end
local function make(class,parent,props) local o=Instance.new(class);for k,v in pairs(props)do o[k]=v end;o.Parent=parent;return o end
function M:tag(player)
    local t=self.tags[player]
    if t and t.gui.Parent then return t end
    local gui=make("BillboardGui",self.gui,{Name="CommanderTag_"..player.UserId,Size=UDim2.fromOffset(220,52),AlwaysOnTop=false,LightInfluence=0,MaxDistance=420,ResetOnSpawn=false})
    local plate=make("Frame",gui,{Name="Plate",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,0),Size=UDim2.fromOffset(0,34),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=UI.colors.bg,BackgroundTransparency=.18,BorderSizePixel=0})
    UI.corner(plate,2);local stroke=UI.stroke(plate,UI.colors.line,1)
    make("UIPadding",plate,{PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,9)})
    make("UIListLayout",plate,{FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder})
    local bar=make("Frame",plate,{Name="Signal",Size=UDim2.fromOffset(3,22),BorderSizePixel=0,LayoutOrder=0})
    local flag=make("Frame",plate,{Name="Flag",Size=UDim2.fromOffset(24,16),BorderSizePixel=0,LayoutOrder=1});UI.stroke(flag,Color3.new(0,0,0),1).Transparency=.5
    local code=make("TextLabel",flag,{Name="Code",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,TextSize=10,TextColor3=UI.colors.bg,AutoLocalize=false})
    local avatar=make("ImageLabel",plate,{Name="Avatar",Size=UDim2.fromOffset(24,24),BackgroundColor3=UI.colors.raised,BorderSizePixel=0,ScaleType=Enum.ScaleType.Crop,LayoutOrder=1,Visible=false})
    UI.corner(avatar,99);local avatarRing=UI.stroke(avatar,UI.colors.line,1.5)
    UI.display(code,true)
    local text=make("Frame",plate,{Name="Text",Size=UDim2.fromOffset(0,30),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,LayoutOrder=2})
    local name=make("TextLabel",text,{Name="Name",Size=UDim2.fromOffset(0,17),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,Font=Enum.Font.BuilderSansBold,TextSize=14,TextColor3=UI.colors.ink,TextXAlignment=Enum.TextXAlignment.Left,AutoLocalize=false})
    local troops=make("TextLabel",text,{Name="Troops",Position=UDim2.fromOffset(0,17),Size=UDim2.fromOffset(0,13),AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=1,TextSize=11,TextColor3=UI.colors.ice,TextXAlignment=Enum.TextXAlignment.Left,AutoLocalize=false})
    UI.display(troops,true)
    local troopMark=Glyphs.create(text,"troops",12,UI.colors.ice);if troopMark then troopMark.Position=UDim2.fromOffset(0,18);troops:SetAttribute("Indent",15)end
    for _,o in ipairs({code,name,troops})do o:SetAttribute("LocalizationSkip",true)end
    local status=make("TextLabel",plate,{Name="Status",Size=UDim2.fromOffset(0,20),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=amber,BorderSizePixel=0,Font=Enum.Font.BuilderSansBold,TextSize=11,TextColor3=UI.colors.bg,LayoutOrder=3,Visible=false})
    UI.corner(status,2);make("UIPadding",status,{PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6)})
    local benefit=Badge.create(plate);benefit.root.LayoutOrder=4
    t={gui=gui,plate=plate,stroke=stroke,bar=bar,flag=flag,code=code,avatar=avatar,avatarRing=avatarRing,text=text,name=name,troops=troops,troopMark=troopMark,status=status,benefit=benefit,padding=plate:FindFirstChildOfClass("UIPadding"),list=plate:FindFirstChildOfClass("UIListLayout")}
    self.tags[player]=t;return t
end
local function density(t,compact,small)
    t.benefit.root.Visible=not compact and (t.benefit.key or 0)>0
    t.name.Visible=true;t.bar.Visible=not compact
    t.text.Visible=not compact
    t.plate.Visible=not compact or t.status.Visible
    t.flag.Visible=not compact and t.flagApplied==true;t.avatar.Visible=not compact and not t.flagApplied
    local indent=t.troops:GetAttribute("Indent")or 0
    if small then
        t.gui.Size=UDim2.fromOffset(200,34)
        t.plate.Size=UDim2.fromOffset(0,compact and 20 or 24);t.padding.PaddingLeft=UDim.new(0,6);t.padding.PaddingRight=UDim.new(0,6);t.list.Padding=UDim.new(0,5)
        t.bar.Size=UDim2.fromOffset(3,14);t.flag.Size=UDim2.fromOffset(20,13);t.avatar.Size=UDim2.fromOffset(18,18)
        t.name.TextSize=12;t.name.Size=UDim2.fromOffset(0,20);t.text.Size=UDim2.fromOffset(0,20)
        if t.nameText~=t.name.Text then t.nameText=t.name.Text;t.nameWidth=math.ceil(TextService:GetTextSize(t.name.Text,12,t.name.Font,Vector2.new(400,20)).X)end
        local x=(t.nameWidth or 0)+6
        t.troops.TextSize=11;t.troops.Position=UDim2.fromOffset(x+indent,4)
        if t.troopMark then t.troopMark.Size=UDim2.fromOffset(11,11);t.troopMark.Position=UDim2.fromOffset(x,5)end
        t.status.Size=UDim2.fromOffset(0,16);t.status.TextSize=10
    else
        t.gui.Size=UDim2.fromOffset(220,52)
        t.plate.Size=UDim2.fromOffset(0,compact and 24 or 34);t.padding.PaddingLeft=UDim.new(0,9);t.padding.PaddingRight=UDim.new(0,9);t.list.Padding=UDim.new(0,7)
        t.bar.Size=UDim2.fromOffset(3,22);t.flag.Size=UDim2.fromOffset(24,16);t.avatar.Size=UDim2.fromOffset(24,24)
        t.name.TextSize=14;t.name.Size=UDim2.fromOffset(0,17);t.text.Size=UDim2.fromOffset(0,30)
        t.troops.TextSize=11;t.troops.Position=UDim2.fromOffset(indent,17)
        if t.troopMark then t.troopMark.Size=UDim2.fromOffset(12,12);t.troopMark.Position=UDim2.fromOffset(0,18)end
        t.status.Size=UDim2.fromOffset(0,20);t.status.TextSize=11
    end
end
function M:setOwnTerritoryVisible(visible)
    self.ownTerritoryVisible=visible
    local t=self.tags[Players.LocalPlayer];if t then density(t,visible,InputMode.touch())end
end
function M:ring(player)
    local r=self.rings[player]
    if r and r.part.Parent then return r end
    local part=make("Part",self.folder,{Name="Ring_"..player.UserId,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Transparency=1,Size=Vector3.new(M.RING,.05,M.RING)})
    local surface=make("SurfaceGui",part,{Face=Enum.NormalId.Top,CanvasSize=Vector2.new(100,100),LightInfluence=0,AlwaysOnTop=true})
    local fill=make("Frame",surface,{Name="Fill",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.86,.86),BackgroundTransparency=.82,BorderSizePixel=0})
    make("UICorner",fill,{CornerRadius=UDim.new(.5,0)})
    local edge=make("UIStroke",fill,{Thickness=7,Transparency=.15})
    local pulse=make("Frame",surface,{Name="Pulse",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.86,.86),BackgroundTransparency=1,BorderSizePixel=0})
    make("UICorner",pulse,{CornerRadius=UDim.new(.5,0)});local wave=make("UIStroke",pulse,{Thickness=4,Transparency=1})
    r={part=part,fill=fill,edge=edge,pulse=pulse,wave=wave};self.rings[player]=r;return r
end
function M:update(state,visible,incoming,ownColor)
    self.state=state;self.visible=visible;self.incoming=incoming or 0
    local inMatch=state~=nil and state.phase~="menu";self.active=inMatch
    local byUser={}
    for _,f in ipairs(state and state.factions or {})do if f.userId then byUser[tonumber(f.userId)]=f end end
    for _,player in ipairs(Players:GetPlayers())do
        local c=player.Character;local root=c and c:FindFirstChild("HumanoidRootPart")
        local f=player==Players.LocalPlayer and state and state.player or byUser[player.UserId]
        local show=inMatch and not(state.drop and state.drop.active)and root~=nil and f~=nil and (player==Players.LocalPlayer or visible(player))
        local server=c and c:FindFirstChild("CommanderName")
        if server then if inMatch then server.Enabled=false elseif player==Players.LocalPlayer then server.Enabled=true end end
        if not show then
            local t=self.tags[player];if t then t.gui.Enabled=false end
            local r=self.rings[player];if r then r.part.Parent=nil end
            continue
        end
        local mine=player==Players.LocalPlayer
        local color=Colors.get(mine and 1 or f.id,f.kind,mine and ownColor or nil)
        local t=self:tag(player);t.gui.Enabled=true;t.gui.Adornee=root
        t.bar.BackgroundColor3=color;t.flag.BackgroundColor3=color
        local applied=self.flags and f.flag and self.flags.apply(t.flag,f.flag)
        t.flagApplied=applied==true
        t.flag.Visible=applied==true;t.code.Visible=false
        t.avatar.Visible=not applied;t.avatarRing.Color=color
        if not applied and t.avatar:GetAttribute("UserId")~=player.UserId then
            local avatar,userId=t.avatar,player.UserId;avatar:SetAttribute("UserId",userId)
            Avatar.request(userId,function(url) if avatar.Parent and avatar:GetAttribute("UserId")==userId then avatar.Image=url end end)
        end
        t.name.Text=player.DisplayName
        Badge.update(t.benefit,player:GetAttribute('CommanderPermanent'),player:GetAttribute('CommanderVIP'))
        t.troops.Text=t.troops:GetAttribute("Indent")and UI.troops(f.troops or 0)or string.format(L.text("병력 %s"),UI.troops(f.troops or 0))
        local combat=f.combatState;local state_
        if mine then state_=self.incoming>0 and "incoming" or nil
        elseif combat=="incoming" or combat=="attacking" then state_="incoming" elseif combat then state_="fighting" elseif f.allied then state_="allied" end
        t.status.Visible=state_~=nil
        t.status.Text=L.text(state_=="incoming" and (mine and "피격" or "공격 중") or state_=="fighting" and "교전" or state_=="allied" and "동맹" or "")
        t.status.BackgroundColor3=state_=="allied" and lime or state_=="fighting" and UI.colors.ink or amber
        t.stroke.Color=state_=="incoming" and amber or mine and color or UI.colors.line
        t.state=state_
        density(t,mine and self.ownTerritoryVisible==true,InputMode.touch())
        local r=self:ring(player);r.part.Parent=self.folder;r.color=color;r.state=state_
        r.fill.BackgroundColor3=color;r.edge.Color=state_=="incoming" and amber or state_=="allied" and lime or mine and UI.colors.ice or color
    end
    for player,t in pairs(self.tags)do if player.Parent~=Players then t.gui:Destroy();self.tags[player]=nil end end
    for player,r in pairs(self.rings)do if player.Parent~=Players then r.part:Destroy();self.rings[player]=nil end end
end
M.EMOJI_SECONDS=2
function M:emoji(player,text,reduced)
    local t=player and self.tags[player];local c=player and player.Character;local root=c and c:FindFirstChild("HumanoidRootPart")
    if self.bubbles and self.bubbles[player]then self.bubbles[player]:Destroy();self.bubbles[player]=nil end
    if not t or not t.gui.Enabled or not root or type(text)~="string"then return false end
    local b=make("BillboardGui",self.gui,{Name="CommanderEmoji_"..player.UserId,Adornee=root,Size=UDim2.fromOffset(36,32),SizeOffset=Vector2.new(0,.9),
        StudsOffsetWorldSpace=t.gui.StudsOffsetWorldSpace,AlwaysOnTop=true,LightInfluence=0,MaxDistance=t.gui.MaxDistance,ResetOnSpawn=false})
    local card=make("Frame",b,{Name="Card",Size=UDim2.fromScale(1,1),BackgroundColor3=UI.colors.bg,BackgroundTransparency=.12,BorderSizePixel=0});UI.corner(card,3);UI.stroke(card,UI.colors.line,1)
    local label=make("TextLabel",card,{Name="Emoji",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text=text,TextSize=20,Font=Enum.Font.BuilderSans,AutoLocalize=false})
    label:SetAttribute("LocalizationSkip",true)
    local scale=make("UIScale",card,{Scale=reduced and 1 or .6})
    if not reduced then game:GetService("TweenService"):Create(scale,TweenInfo.new(.2,Enum.EasingStyle.Back),{Scale=1}):Play()end
    self.bubbles=self.bubbles or {};self.bubbles[player]=b
    task.delay(M.EMOJI_SECONDS,function()if self.bubbles[player]==b then self.bubbles[player]=nil end;b:Destroy()end)
    return true
end
function M:showing(player)
    local t=self.tags[player];local c=player.Character;local root=c and c:FindFirstChild("HumanoidRootPart")
    if not t or not t.gui.Enabled or not root then return false end
    local camera=workspace.CurrentCamera;local _,inView=camera:WorldToViewportPoint(root.Position)
    return inView and (camera.CFrame.Position-root.Position).Magnitude<t.gui.MaxDistance*.9
end
function M:step(dt,reduced)
    self.clock+=dt
    for player,r in pairs(self.rings)do
        local c=player.Character;local root=c and c:FindFirstChild("HumanoidRootPart")
        if r.part.Parent and root then
            local growth=c:GetAttribute("ToyfrontGrowth")or 1;local t=self.tags[player]
            if r.growth~=growth or r.tag~=t then
                r.growth=growth;r.tag=t;local size=M.RING*growth;r.part.Size=Vector3.new(size,.05,size)
                if t then t.gui.StudsOffsetWorldSpace=Vector3.new(0,3.2*growth+1.2,0) end
            end
            local at=root.Position
            if r.at~=at then r.at=at;r.part.CFrame=CFrame.new(at.X,G.surfaceY+.08,at.Z)end
            if r.state=="incoming" and not reduced then
                local phase=(self.clock*1.4)%1;r.calm=false
                r.pulse.Size=UDim2.fromScale(.86+.14*phase,.86+.14*phase);r.wave.Color=amber;r.wave.Transparency=.2+.8*phase
            elseif not r.calm then r.calm=true;r.wave.Transparency=1 end
        end
    end
end
return M
