local UI=require(script.Parent.Theme)
local Avatar=require(script.Parent.AvatarPortrait)
local Icons=require(script.Parent.UIIcons)
local L=require(script.Parent.Localization)
local Colors=require(script.Parent.FactionColors)
local Flags=require(script.Parent.Flags)
local Honor=require(script.Parent.CommanderHonor)
local M={}
local function set(o,k,v)if o[k]~=v then o[k]=v end end
local function face(profile)
    local flagged=profile.Flag.Visible;local avatar=profile.Avatar
    set(avatar,'Visible',not flagged and avatar.Image~='')
    local bare=not flagged and not profile.NPC.Visible and not (avatar.Visible and avatar.IsLoaded)
    set(profile.Head,'Visible',bare);set(profile.Shoulders,'Visible',bare)
end
function M.color(id,ownColor,kind) return Colors.get(id,kind,ownColor)end
function M.new(parent,name)
    local root=UI.make("Frame",parent,{Name=name,Size=UDim2.fromOffset(142,44),AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1})
    local portrait=UI.make("Frame",root,{Name="Profile",Position=UDim2.fromOffset(0,6),Size=UDim2.fromOffset(28,28),BorderSizePixel=0});UI.corner(portrait,99);UI.stroke(portrait,UI.colors.ink,1)
    local head=UI.make("Frame",portrait,{Name="Head",Position=UDim2.fromScale(10/28,5/28),Size=UDim2.fromScale(8/28,9/28),BackgroundColor3=UI.colors.ink,BorderSizePixel=0});UI.corner(head,8)
    local body=UI.make("Frame",portrait,{Name="Shoulders",Position=UDim2.fromScale(6/28,15/28),Size=UDim2.fromScale(16/28,8/28),BackgroundColor3=UI.colors.ink,BorderSizePixel=0});UI.corner(body,6)
    local npc=Icons.create(portrait,"npc",28);npc.Name="NPC";npc.ZIndex=2
    local avatar=UI.make("ImageLabel",portrait,{Name="Avatar",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,ZIndex=3,Visible=false});UI.corner(avatar,99)
    avatar:GetPropertyChangedSignal("IsLoaded"):Connect(function() face(portrait) end)
    local title=UI.label(root,"Title","",14);title:SetAttribute('LocalizationSkip',true);UI.box(title,34,0,108,20);title.Font=Enum.Font.BuilderSansBold;title.TextTruncate=Enum.TextTruncate.AtEnd;title.TextWrapped=false;title.TextStrokeTransparency=0
    local troops=UI.label(root,"Troops","",14);UI.box(troops,34,22,108,20);troops.TextStrokeTransparency=0;troops.TextWrapped=false
    UI.make("Frame",portrait,{Name="Flag",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.66,.44),BackgroundTransparency=1,ZIndex=4,Visible=false})
    local state=UI.label(portrait,"State","",12,UI.colors.ink);UI.box(state,15,17,18,18);state.TextXAlignment=Enum.TextXAlignment.Center;state.BackgroundColor3=UI.colors.panel;state.BackgroundTransparency=.1;state.ZIndex=5;UI.corner(state,9);state.Visible=false
    return root
end
function M.update(root,f,ownColor,pixels,viewport)
    local font=pixels or (f.id==1 and 16 or 14);local tribe=f.kind=='BOT'
    local portrait=math.clamp(font*2,28,42);local offset=tribe and 0 or portrait+6
    local letters=utf8.len(f.name or '')or #(f.name or '')
    local width=math.min((viewport or 1000)-16,340,math.max(142,math.ceil(font*letters*.68)+offset))
    local height=math.ceil(font*2.6)
    local key=font..':'..width..':'..tostring(tribe)
    if root:GetAttribute('LabelLayout')~=key then
        root:SetAttribute('LabelLayout',key);root:SetAttribute('NamePixelSize',font)
        root.Size=UDim2.fromOffset(width,height)
        UI.box(root.Profile,0,(height-portrait)/2,portrait,portrait)
        UI.box(root.Title,offset,0,width-offset,height/2);UI.box(root.Troops,offset,height/2,width-offset,height/2)
        root.Title.TextSize=font;root.Troops.TextSize=font
        local align=tribe and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
        root.Title.TextXAlignment=align;root.Troops.TextXAlignment=align
    end
    local color=M.color(f.id,ownColor,f.kind);local outline=color:Lerp(Color3.new(0,0,0),.58)
    root.Profile.BackgroundColor3=outline
    local status=root.Profile.State;local combat=f.combatState
    status.Visible=combat~=nil or f.allied==true
    status.Text=combat and ((combat=="incoming" or combat=="attacking") and "!" or "⚔") or "↔"
    status.TextColor3=combat and ((combat=="incoming" or combat=="attacking") and UI.colors.danger or UI.colors.gold) or UI.colors.accent
    local userId=tonumber(f.userId) or 0
    local profile=root.Profile
    local tribe=f.kind=="BOT"
    profile.Visible=not tribe
    root:SetAttribute("Tribe",tribe)
    if tribe then
        root.Title.Text=L.text(f.name);root.Title.TextColor3=UI.colors.ink:Lerp(UI.colors.muted,.25);root.Title.TextStrokeColor3=UI.colors.bg;root.Title.TextStrokeTransparency=.1
        root.Troops.Text=UI.troops(f.troops);root.Troops.TextColor3=UI.colors.ink;root.Troops.TextStrokeColor3=UI.colors.bg;root.Troops.TextStrokeTransparency=.1
        return
    end
    root.Title.TextColor3=UI.colors.ink;root.Title.TextStrokeTransparency=0;root.Troops.TextStrokeTransparency=0
    local flagged=f.flag~=nil and Flags.apply(profile.Flag,f.flag)
    profile.Flag.Visible=flagged==true
    if flagged then profile.NPC.Visible=false;profile.Head.Visible=false;profile.Shoulders.Visible=false end
    if profile:GetAttribute("UserId")~=userId then
        profile:SetAttribute("UserId",userId);profile.Avatar.Image="";profile.Avatar.Visible=false
        profile.NPC.Visible=userId==0 and not flagged and profile.NPC:GetAttribute("Available")==true
        profile.Head.Visible=not profile.NPC.Visible and not flagged;profile.Shoulders.Visible=profile.Head.Visible
        Avatar.request(userId,function(url)
            if profile.Parent and profile:GetAttribute("UserId")==userId then profile.Avatar.Image=url;face(profile) end
        end)
    end
    face(profile)
    local honor=Honor.of(f);local ring=profile:FindFirstChildOfClass("UIStroke")
    if ring then ring.Color=honor and honor.plate and Honor.edge(honor.plate)or UI.colors.ink;ring.Thickness=honor and honor.plate and 2 or 1 end
    root.Title.Text=(f.userId and f.name or L.text(f.name))..(f.allied and L.text(" (동맹)")or "")
    root.Title.TextStrokeColor3=outline;root.Troops.TextStrokeColor3=outline
    root.Troops.Text=UI.troops(f.troops);root.Troops.TextColor3=color:Lerp(Color3.new(1,1,1),.9)
end
local function glyphs(text)
    local w=0
    for _,c in utf8.codes(text or '')do
        w+=c>=0x1100 and .94 or c==32 and .28 or (c>=48 and c<=57 or c>=65 and c<=90) and .6 or .52
    end
    return w
end
M.textWidth=glyphs
local widths,cached={},0
local function nameWidth(name,font)
    local key=font..'|'..name;local w=widths[key]
    if w then return w end
    local ok,v=pcall(function()return game:GetService('TextService'):GetTextSize(name,font,Enum.Font.BuilderSansBold,Vector2.new(4096,200)).X end)
    w=math.max(ok and v+2 or 0,glyphs(name)*font)
    if cached>=4000 then widths,cached={},0 end
    widths[key]=w;cached+=1;return w
end
local function measure(f,font,viewport)
    local tribe=f.kind=='BOT'
    local troopFont=math.max(12,math.floor(font*.86+.5))
    local portrait=not tribe and math.clamp(math.floor(font*1.12+.5),16,30)or 0
    local name=(f.userId and f.name or L.text(f.name or ''))
    local troops=UI.troops(f.troops or 0)
    local status=(f.combatState~=nil or f.allied==true or f.incomingRequest==true)and not tribe
    local dot=status and portrait==0 and math.max(8,math.floor(font*.7))or 0
    local shown=f.allied and name..L.text(" (동맹)")or name
    local textW=math.ceil(math.max(nameWidth(shown,font),glyphs(troops)*troopFont))+4
    local offset=portrait>0 and portrait+4 or dot>0 and dot+3 or 0
    local width=math.min((viewport or 1000)-16,offset+textW)
    return tribe,troopFont,portrait,name,troops,status,dot,offset,width,font..':'..width..':'..portrait..':'..dot..':plate'
end
function M.troops(root,f,font,viewport)
    font=math.floor(font+.5)
    local _,_,_,_,troops,_,_,_,_,key=measure(f,font,viewport)
    if root:GetAttribute('LabelLayout')~=key then return false end
    local label=root:FindFirstChild('Troops');if not label then return false end
    if label.Text~=troops then label.Text=troops end
    return true
end
function M.plate(root,f,ownColor,font,viewport,faded)
    font=math.floor(font+.5)
    local tribe,troopFont,portrait,name,troops,status,dot,offset,width,key=measure(f,font,viewport)
    local height=math.ceil(font*1.12+troopFont*1.08)
    if root:GetAttribute('LabelLayout')~=key then
        root:SetAttribute('LabelLayout',key);root:SetAttribute('NamePixelSize',font)
        root:SetAttribute('NameTextWidth',nameWidth(f.allied and name..L.text(" (동맹)")or name,font))
        root.Size=UDim2.fromOffset(width,height)
        root.Profile.Visible=portrait>0
        if portrait>0 then
            UI.box(root.Profile,0,math.max(0,(font*1.12-portrait)/2),portrait,portrait)
            root.Profile.Flag.Size=UDim2.fromScale(.66,.44)
            root.Profile.NPC.Size=UDim2.fromScale(1,1)
            UI.box(root.Profile.State,portrait*.57,portrait*.64,math.max(12,portrait*.58),math.max(12,portrait*.58));root.Profile.State.TextSize=math.max(10,math.floor(portrait*.45))
        end
        UI.box(root.Title,offset,0,width-offset,math.floor(font*1.12));UI.box(root.Troops,offset,math.floor(font*1.12),width-offset,height-math.floor(font*1.12))
        root.Title.TextSize=font;root.Troops.TextSize=troopFont
        root.Title.TextXAlignment=portrait>0 and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center;root.Troops.TextXAlignment=root.Title.TextXAlignment
        local chip=root:FindFirstChild('StatusDot')
        if dot>0 then
            if not chip then chip=UI.label(root,'StatusDot','',10,UI.colors.bg);chip.TextXAlignment=Enum.TextXAlignment.Center;chip.BackgroundTransparency=0;chip.Font=Enum.Font.BuilderSansBold;chip:SetAttribute('LocalizationSkip',true);UI.corner(chip,99)end
            UI.box(chip,0,(font*1.12-dot)/2,dot,dot);chip.TextSize=math.max(8,math.floor(dot*.8))
        end
        if chip then chip.Visible=dot>0 end
    end
    root:SetAttribute('Tribe',tribe)
    local color=M.color(f.id,ownColor,f.kind);local outline=color:Lerp(Color3.new(0,0,0),.58)
    local combat=f.combatState
    local stateText=combat and ((combat=='incoming'or combat=='attacking')and '!'or '⚔')or f.allied and '🤝'or f.incomingRequest and '?'or ''
    local stateColor=combat and ((combat=='incoming'or combat=='attacking')and UI.colors.danger or UI.colors.gold)or f.allied and Color3.fromRGB(110,225,132) or UI.colors.ink
    local fade=faded and .55 or 0
    local away=root:FindFirstChild('Away')
    if f.disconnected and not tribe then
        if not away then
            away=UI.label(root,'Away','Zzz',12,Color3.fromRGB(4,156,220));away.Font=Enum.Font.BuilderSansBold;away.TextXAlignment=Enum.TextXAlignment.Center
            away.TextWrapped=false;away.TextStrokeTransparency=0;away.TextStrokeColor3=UI.colors.bg;away:SetAttribute('LocalizationSkip',true)
        end
        local size=math.max(10,math.floor(font*.85+.5));local w=root.Size.X.Offset
        UI.box(away,0,-size-1,w,size);set(away,'TextSize',size);set(away,'TextTransparency',fade);set(away,'Visible',true)
    elseif away then set(away,'Visible',false)end
    if tribe then
        set(root.Title,'Text',name);set(root.Title,'TextColor3',UI.colors.ink:Lerp(UI.colors.muted,.25));set(root.Title,'TextStrokeColor3',UI.colors.bg)
        set(root.Troops,'Text',troops);set(root.Troops,'TextColor3',UI.colors.ink);set(root.Troops,'TextStrokeColor3',UI.colors.bg)
        set(root.Title,'TextTransparency',fade);set(root.Troops,'TextTransparency',fade)
        set(root.Title,'TextStrokeTransparency',.1+fade);set(root.Troops,'TextStrokeTransparency',.1+fade)
        return
    end
    set(root.Title,'Text',name);set(root.Troops,'Text',troops)
    set(root.Title,'TextColor3',UI.colors.ink);set(root.Troops,'TextColor3',color:Lerp(Color3.new(1,1,1),.9))
    set(root.Title,'TextStrokeColor3',outline);set(root.Troops,'TextStrokeColor3',outline)
    set(root.Title,'TextTransparency',fade);set(root.Troops,'TextTransparency',fade)
    set(root.Title,'TextStrokeTransparency',fade);set(root.Troops,'TextStrokeTransparency',fade)
    local chip=root:FindFirstChild('StatusDot')
    if chip and chip.Visible then set(chip,'Text',stateText);set(chip,'BackgroundColor3',stateColor);set(chip,'BackgroundTransparency',fade)end
    if portrait==0 then return end
    local profile=root.Profile;set(profile,'BackgroundColor3',outline)
    local s=profile.State;set(s,'Visible',status)
    local hands=require(script.Parent.AllianceGlyph).attach(s);hands.Visible=f.allied==true and combat==nil
    if status then set(s,'Text',hands.Visible and ''or stateText);set(s,'TextColor3',stateColor)end
    local flagged=f.flag~=nil and Flags.apply(profile.Flag,f.flag)
    set(profile.Flag,'Visible',flagged==true)
    if flagged then profile.NPC.Visible=false;profile.Head.Visible=false;profile.Shoulders.Visible=false end
    local userId=tonumber(f.userId)or 0
    if profile:GetAttribute('UserId')~=userId then
        profile:SetAttribute('UserId',userId);profile.Avatar.Image='';profile.Avatar.Visible=false
        profile.NPC.Visible=userId==0 and not flagged and profile.NPC:GetAttribute('Available')==true
        profile.Head.Visible=not profile.NPC.Visible and not flagged;profile.Shoulders.Visible=profile.Head.Visible
        Avatar.request(userId,function(url)
            if profile.Parent and profile:GetAttribute('UserId')==userId then profile.Avatar.Image=url;face(profile) end
        end)
    end
    face(profile)
    local honor=Honor.of(f);local ring=profile:FindFirstChildOfClass('UIStroke')
    if ring then set(ring,'Color',honor and honor.plate and Honor.edge(honor.plate)or UI.colors.ink);set(ring,'Thickness',honor and honor.plate and 2 or 1)end
end
return M
