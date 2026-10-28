local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local me=Players.LocalPlayer
local bootClocks={os.clock()}
local pack=game.ReplicatedStorage:WaitForChild("FrontierNative")
local UI=require(pack.Client.Theme)
local L=require(pack.Client.Localization)
local V=require(pack.Client.ViewMath)
local PlazaLayout=require(pack.Core.PlazaLayout)
local LobbyIntro=require(pack.Client.LobbyIntro)
local WorldView=require(pack.Client.WorldView)
require(pack.Client.MapPreload)
local VisualEffects=require(pack.Client.VisualEffects)
local CosmeticCatalog=require(pack.Core.CosmeticCatalog)
local Icons=require(pack.Client.UIIcons)
local BuildingModels=require(pack.Client.BuildingModels)
local BuildingCatalog=require(pack.Client.BuildingCatalog)
local armsUI={rules=require(pack.Core.UnitRules),commsCatalog=require(pack.Core.CommsCatalog)}
armsUI.telemetry=require(pack.Client.TelemetryClient).start()
armsUI.commands=require(pack.Core.CommandPresentation)
armsUI.input=require(pack.Client.InputMode)
armsUI.interaction=require(pack.Core.CommandInteraction)
armsUI.inputFlow=armsUI.interaction.new()
armsUI.recruitment=require(pack.Core.RecruitmentPresentation).new()
local BattleFeedback=require(pack.Client.BattleFeedback)
local DiplomacyInbox=require(pack.Client.DiplomacyInbox)
local FactionBadge=require(pack.Client.FactionBadge)
local Maps=require(pack.Maps.MapLoader)
local Terrain=require(pack.Core.Terrain)
local B=require(pack.Core.BigNat)
local command=pack:WaitForChild("Command")
local read=pack:WaitForChild("Read")
local previewRemote=pack:WaitForChild("Preview")
armsUI.experienceReady=pack:WaitForChild('ExperienceReady')
armsUI.experienceReady.OnClientEvent:Connect(function()armsUI.lobbyReadyReported=true end)
function armsUI.comrades(s)local list={};for _,f in ipairs(s and s.factions or {})do local pl=f.userId and f.userId~=me.UserId and Players:GetPlayerByUserId(f.userId);if pl then table.insert(list,pl)end end;return list end
function armsUI.games(p)local games=0;for _,st in pairs(p and p.stats or {})do games+=tonumber(st.games)or 0 end;return games end
function armsUI.rookie(p)return p~=nil and armsUI.games(p)==0 end
local C=UI.colors
local make,box,label,button=UI.make,UI.box,UI.label,UI.button
pcall(function()
    for _,kind in ipairs({Enum.CoreGuiType.PlayerList,Enum.CoreGuiType.Chat,Enum.CoreGuiType.Backpack,Enum.CoreGuiType.Health}) do game.StarterGui:SetCoreGuiEnabled(kind,false) end
end)
bootClocks[2]=os.clock()
me.PlayerGui.ScreenOrientation=Enum.ScreenOrientation.Sensor
local gui=make("ScreenGui",me.PlayerGui,{Name="FrontierNativeUI",DisplayOrder=5,IgnoreGuiInset=false,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
L.bind(gui)
require(pack.Client.FullBleed).watch(gui)
task.spawn(function()require(pack.Client.OpsOverlay).start()end)
task.spawn(function()local world=workspace:WaitForChild('FrontierWorld',30);local plaza=world and world:WaitForChild('DeskPlaza',30);if plaza then L.bind(plaza)end end)
armsUI.veil=require(pack.Client.TransitionVeil).bind(gui)
local root=make("Frame",gui,{Name="Main",Size=UDim2.fromScale(1,1),BorderSizePixel=0,BackgroundColor3=C.bg})
local uiScale=make("UIScale",root,{Scale=1})
local function screenSize() return root.AbsoluteSize/UI.scale end
local qaViewport=nil
local function applyScale()
    local v=workspace.CurrentCamera.ViewportSize
    local s=armsUI.input.touch() and 1 or math.clamp(math.floor(math.min(v.X/1366,v.Y/768)*20)/20,1,1.75)
    if qaViewport then s=math.min(v.X/qaViewport.X,v.Y/qaViewport.Y) end
    if s~=UI.scale or qaViewport then UI.scale=s;uiScale.Scale=s;gui:SetAttribute('UIScale',s)
        root.Size=qaViewport and UDim2.fromOffset(qaViewport.X,qaViewport.Y) or UDim2.fromScale(1/s,1/s)
    end
end
applyScale();workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(applyScale)
local loadingUI={}
do
    local loading=make("Frame",root,{Name="LoadingCover",Size=UDim2.fromScale(1,1),BackgroundColor3=C.bg,BackgroundTransparency=0,ZIndex=35,Active=true,Visible=false,ClipsDescendants=true})
    for i=1,23 do make("Frame",loading,{Name="GridV",Position=UDim2.fromScale(i/24,0),Size=UDim2.new(0,1,1,0),BackgroundColor3=C.line,BackgroundTransparency=.55,BorderSizePixel=0,ZIndex=35})end
    for i=1,11 do make("Frame",loading,{Name="GridH",Position=UDim2.fromScale(0,i/12),Size=UDim2.new(1,0,0,1),BackgroundColor3=C.line,BackgroundTransparency=.55,BorderSizePixel=0,ZIndex=35})end
    local brand=label(loading,"Brand","SUPER COMMANDER",14,C.accent);UI.display(brand);brand:SetAttribute("LocalizationSkip",true);brand.Position=UDim2.fromOffset(20,16);brand.Size=UDim2.fromOffset(240,22);brand.ZIndex=36
    local kicker=label(loading,"Kicker","출격 준비",14,C.accent);UI.display(kicker,true);kicker.AnchorPoint=Vector2.new(.5,.5);kicker.Position=UDim2.new(.5,0,.5,-58);kicker.Size=UDim2.new(1,-32,0,22);kicker.TextXAlignment=Enum.TextXAlignment.Center;kicker.ZIndex=36
    local title=label(loading,"Title","작전 지도를 펼치는 중…",40,C.ink);UI.display(title);title.AnchorPoint=Vector2.new(.5,.5);title.Position=UDim2.new(.5,0,.5,-18);title.Size=UDim2.new(1,-32,0,52);title.TextXAlignment=Enum.TextXAlignment.Center;title.ZIndex=36
    local track=make("Frame",loading,{Name="Track",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,.5,26),Size=UDim2.fromOffset(280,3),BackgroundColor3=C.line,BorderSizePixel=0,ZIndex=36,ClipsDescendants=true})
    local scan=make("Frame",track,{Name="Scan",Size=UDim2.new(.3,0,1,0),BackgroundColor3=C.accent,BorderSizePixel=0,ZIndex=37})
    local hint=label(loading,"Hint","지형과 각국 군대를 배치하는 중",14,C.muted);hint.AnchorPoint=Vector2.new(.5,.5);hint.Position=UDim2.new(.5,0,.5,58);hint.Size=UDim2.new(1,-32,0,40);hint.TextXAlignment=Enum.TextXAlignment.Center;hint.ZIndex=36
    loadingUI={frame=loading,title=title,scan=scan,hint=hint,clock=0,tip=0,tips={
        "같은 땅 두 번 탭 = 바로 공격",
        "앰버 테두리 = 적 미사일 사일로",
        "도시 1레벨 = 병력 상한 +25K",
        "라임색 칩 = 동맹",
        "멀리 보기 = 건물이 세력색 아이콘",
    }}
end
require(pack.Client.LoadHandoff).start(gui,loadingUI.frame,require(pack.Client.WaitingRoster).attach(loadingUI.frame))
local shop=nil
local state=nil
local multiplayerLobby
local movementControls
task.spawn(function()
    movementControls=require(me:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
    if multiplayerLobby and multiplayerLobby.single then movementControls:Disable()else movementControls:Enable()end
end)
local selectedMap="world"
local selectedTile,selectedUnit,hoveredUnit=nil,nil,nil
local action,fraction="inspect",.2
local chooseBuild
local owners={}
local factions,sortedFactions,factionMarkers={},{},{}
local ownershipRevision,currentVersion=0,-1
local currentMap=nil
local dirty,lastDraw=false,0
local eventsSeen,requestSerial,previewSerial=0,0,0
local pending={}
local inFlight=armsUI.inputFlow.requests;local selectionRevision=0;local lastDispatch=-1
local queuedPause=nil
local effects=VisualEffects.new()
task.spawn(function()local world=workspace:WaitForChild('FrontierWorld',30);local plaza=world and world:WaitForChild('DeskPlaza',30);if plaza then require(pack.Client.PlazaLife).start(plaza,function()return effects.reduced end)
    require(pack.Client.LobbyStage).attach(plaza,{menu=function()return state~=nil and state.phase=="menu"end,party=function()return multiplayerLobby and multiplayerLobby.data and multiplayerLobby.data.party end,reduced=function()return effects.reduced end})end end)
local preview=nil
local sheetMode=nil
local menuAnchor,hoveredTile=nil,nil
local tutorial=true
local mapCache={}
local layout,render,refreshContext,refreshSheet,refreshMarkers,openModal,closeModal,executePrimary,positionSheet
local refreshAttackAmount
local resumeCommand=nil
local function mapData(key,terrain,packed)
    if packed then table.clear(mapCache);mapCache[key]=Maps.fromPacked(key,packed);return mapCache[key]end
    if terrain or not mapCache[key]then
        table.clear(mapCache)
        mapCache[key]=terrain and Maps.fromTerrain(key,terrain)or Maps.load(key)
    end
    return mapCache[key]
end
local function affordable(cost) return state and state.player and cost and B.compare(B.fromString(state.player.gold),B.fromString(cost))>=0 end
local notices=require(pack.Core.NoticeFlow).new()
local showNotice
local noticeUI=require(pack.Client.NoticeToast).new(root,function(tile)if armsUI.focusTile then armsUI.focusTile(tile)end end,function()if notices:dismiss(os.clock())then showNotice()end end)
local toast=noticeUI.frame
showNotice=function()
    local n=notices.current;toast.Visible=n~=nil;if not n then return end
    local m=root:FindFirstChild('Modal');toast.ZIndex=m and m.Visible and 31 or toast.Parent==root and 29 or 17
    noticeUI:show(n,armsUI.input.touch())
end
local function notify(message,error,tile,queued)
    if notices:push(message,error,os.clock(),tile,queued)then showNotice()end
end
local function send(name,value,extra)
    if name=='comms'and armsUI.chat then armsUI.chat:send(value,extra);return end
    if name=='menu'and state and state.intro and multiplayerLobby then multiplayerLobby.skipIntro=true end
    local repeatable=name=='attack' or name=='transport'
    local key=name=="pause"and name or name..":"..tostring(value)..":"..tostring(extra);armsUI.keys=armsUI.keys or {}
    if not repeatable and armsUI.keys[key] then if name=="pause" then queuedPause=value elseif armsUI.interaction.labels[name]then notify("처리 중",false)end;return end
    if repeatable then
        local count=0;for _,r in pairs(inFlight)do if r.action==name then count+=1 end end
        if count>=6 or os.clock()-lastDispatch<.08 then return end
        lastDispatch=os.clock()
    end
    requestSerial+=1;local id=requestSerial;pending[name]=id;if not repeatable then armsUI.keys[key]=id end
    if armsUI.interaction.labels[name]then armsUI.firedAt=os.clock()end
    armsUI.inputFlow:track(id,{action=name,selection=selectionRevision,tile=selectedTile,mode=action,unit=selectedUnit and selectedUnit.id,anchor=menuAnchor,moving=armsUI.moving,version=state and state.version or 0},os.clock())
    local request=inFlight[id]
    if armsUI.closesRadial and armsUI.closesRadial[name]then
        request.restoreTile=type(extra)=='number'and table.find({'build','attack','transport','moveWarship','moveWarships'},name)and extra or selectedTile
        request.restoreOwner=request.restoreTile and owners[request.restoreTile]or 0
        local target=factions[request.restoreOwner];request.restoreAllied=target~=nil and target.allied==true
    end
    if armsUI.commandFeedback then
        local description=require(pack.Client.ActionReceipt).describe(name,value,extra,state,{owners=owners,anchor=menuAnchor,tile=selectedTile,route=armsUI.attackRoute,fraction=fraction,names=armsUI.rules and armsUI.rules.names,unitKind=selectedUnit and selectedUnit.kind,unitName=selectedUnit and armsUI.rules.names[selectedUnit.kind]})
        armsUI.commandFeedback:begin(id,name,state and state.version or 0,description,os.clock())
    end
    armsUI.telemetry.sent(id,name,state and state.version or 0)
    command:FireServer(name,value,extra,id,state and state.version or 0)
    if armsUI.closeRadial and armsUI.closesRadial[name]then task.defer(function()
        if request.selection~=selectionRevision then return end
        if armsUI.closeRadial()or name=='build'and action=='inspect'and not sheetMode then request.closedRevision=selectionRevision end
    end)end
    task.delay(8,function() if armsUI.keys[key]==id then armsUI.keys[key]=nil end;if armsUI.inputFlow:expire(id,os.clock())then if pending[name]==id then pending[name]=nil end
        if not armsUI.commandFeedback.current or armsUI.commandFeedback.current.id~=id then notify("응답 지연",true)end
        if refreshSheet then refreshSheet()end end end)
    return id
end
local mapDetails={}
for _,m in ipairs(Maps.catalog)do mapDetails[m.key]={m.label,m.description}end
local gamePanel=make("Frame",root,{Name="Game",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false})
local map=make("Frame",gamePanel,{Name="Map",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true})
armsUI.worldOverlay=require(pack.Client.WorldOverlay).new(me.PlayerGui,map)
gui.Destroying:Connect(function()armsUI.worldOverlay:destroy()end)
armsUI.commandFeedback=require(pack.Client.CommandFeedback).new(gamePanel,armsUI.inputFlow)
local renderer=WorldView.new(map);renderer.owners=owners
armsUI.nuclear=require(pack.Client.NuclearAim).new(gamePanel,renderer,{
    send=send,notify=notify,
    preview=function(kind,tile,version,up)return previewRemote:InvokeServer(kind,tile,version,{up=up})end,
    cancel=function()action='inspect';sheetMode=nil;selectedTile=nil;preview=nil;refreshContext()end,
    confirm=function()if armsUI.ghostMode()then armsUI.ghostClick(selectedTile)else armsUI.confirmCurrent()end end,aim=function(t)if armsUI.ghostMode()then armsUI.ghostHover(t)end end,
})
local battle=BattleFeedback.new(gamePanel,renderer,effects)
battle.frontLabels.layer=armsUI.worldOverlay.canvas
local commanders=require(pack.Client.CommanderTags).new(me:WaitForChild("PlayerGui"),require(pack.Client.Flags))
local Honor=require(pack.Client.CommanderHonor);Honor.start();require(pack.Client.CommanderGrowth).start();require(pack.Client.CommanderTrail).watch();require(pack.Client.CharacterMotion).start()
local function roomVisible(player)
    return state~=nil and (state.phase=="menu"and player:GetAttribute("FrontierRoom")==nil or state.roomId~=nil and player:GetAttribute("FrontierRoom")==state.roomId)
end
require(pack.Client.CommanderStandard).watch(function(player)
    if not roomVisible(player)or renderer.dropActive then return false end
    local Colors=require(pack.Client.FactionColors)
    if state.phase=='menu'then return true,Colors.self end
    for _,f in ipairs(state and state.factions or {})do if f.userId==player.UserId or f.id==1 and player==me and not state.observer then
        local own=Color3.fromRGB(table.unpack(require(pack.Core.CosmeticCatalog).get(state.cosmetics and state.cosmetics.territory or state.style).territory))
        return true,f.team~=nil and Colors.team(f.team,state.player and state.player.team)or Colors.get(f.id,f.kind,own),f.share
    end end
    return state and state.phase=='menu',Colors.self
end)
require(pack.Client.CommanderVehicle).watch(function(player)return roomVisible(player)and not renderer.dropActive end)
armsUI.feedback=require(pack.Client.PlayFeedback).new(gamePanel,renderer,effects)
armsUI.feedback.onGold=function(amount)armsUI.commandBar:goldGain(amount)end
armsUI.focusTile=function(tile)renderer:focusAt(tile,true)end;armsUI.feedback.onFocus=armsUI.focusTile
armsUI.renewal=require(pack.Client.AllianceRenewal).new(gamePanel,{send=function(...)return send(...)end,focus=function(tile)armsUI.focusTile(tile)end})
armsUI.audio=require(pack.Client.ToyAudio)
local inbox=DiplomacyInbox.new(gamePanel,send,function(id)armsUI.tactical:open(id)end);armsUI.inbox=inbox
armsUI.eventLog=require(pack.Client.EventLog).new(gamePanel,{focus=function(tile)armsUI.focusTile(tile)end})
armsUI.eventLog.onToggle=function()if layout then layout()end end
armsUI.chat=require(pack.Client.MatchComms).new(gamePanel,notify,function(tile)renderer:focusAt(tile,true)end,function(tile)return renderer:signalPoint(tile)end)
armsUI.chat.onEmoji=function(id,tile,text,userId)if tile then armsUI.bubbles=armsUI.bubbles or require(pack.Client.EmojiBubbles).new(renderer,effects.folder);armsUI.bubbles:show(id,tile,text,effects.reduced==true)end
    if userId then commanders:emoji(game.Players:GetPlayerByUserId(userId),text,effects.reduced==true)end end
armsUI.drop=require(pack.Client.SpawnDropView).new(gamePanel,renderer,armsUI.input.touch)
armsUI.quick=require(pack.Client.QuickComms).new(gamePanel,{send=send,model=armsUI.chat,account=function()return shop and shop.account end,save=function(list,done)
    if not shop or shop.busy or not shop.account.ready then notify('저장 실패',true);done(false);return end
    shop:run(function()local r=shop:request('preference','emojiFavorites',list);done(r and r.ok==true)end)
end})
armsUI.chat.openQuick=function(mode,id)
    local f=selectedTile and factions[owners[selectedTile]]
    if id==nil and f and f.id~=1 then id=f.id end
    sheetMode=nil;refreshSheet();armsUI.quick:open(mode,id);if layout then layout()end
end
armsUI.chat.onHistory=function()if armsUI.quick.frame.Visible and armsUI.quick.mode=='chat'then armsUI.quick:draw()end end
armsUI.tactical=require(pack.Client.TacticalPanel).new(gamePanel,{
    send=send,fraction=function()return fraction end,favorites=function()return armsUI.quick.favorites end,
    more=function(mode,id)armsUI.chat.openQuick(mode=='emojiPicker'and 'emoji'or 'messages',id)end,
    preview=function(id,tile,version)
        if not tile or owners[tile]~=id then tile=factions[id]and factions[id].labelTile end
        if not tile or owners[tile]~=id then return nil end
        local r=previewRemote:InvokeServer('context',tile,version);r.tile=tile;return r
    end,
    boat=function(id,tile)
        if not tile or owners[tile]~=id then notify('대상 선택',true);return end
        send('transport',fraction,tile)
    end,
})
armsUI.sheets=require(pack.Client.MatchSheet).new(gamePanel,armsUI,send);armsUI.sheets.relayout=function()if layout then layout()end end
local markerLayer=make("Frame",armsUI.worldOverlay.canvas,{Name="Markers",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ClipsDescendants=false,ZIndex=4})
local structureIcons=require(pack.Client.StructureIcons).new(markerLayer)
renderer.combined.railView.root.Parent=armsUI.worldOverlay.canvas;renderer.combined.railView.root.ZIndex=0
local qaStructures=nil
if RunService:IsStudio() then
    local qa=Instance.new("BindableFunction");qa.Name="FrontierClientQA";qa.Parent=me
    qa.OnInvoke=function(kind,value)
        if kind=="zoom" then renderer.overview=false;renderer.view.w=value;renderer:clamp();return renderer.view.w
        elseif kind=='focus'then renderer:focusAt(value);return true
        elseif kind=='view'then return {zoom=renderer.view.w,target=renderer.targetTile,yaw=renderer.yaw,tilt=renderer.tilt}
        elseif kind=="structures" then qaStructures=value;return value and #value or 0
        elseif kind=="viewport" then qaViewport=value;applyScale();task.wait();layout();return screenSize()
        elseif kind=="tap" then armsUI.qaTap(value);return true
        elseif kind=="spawnAuto" then send("spawn","auto");return true
        elseif kind=="glintsAll" then
            renderer.qaGlints=value and function(state,glint)
                local Glints=require(pack.Client.TerritoryGlints);local Catalog=require(pack.Core.CosmeticCatalog)
                local tops={Catalog.get('parallax_territory'),Catalog.get('solaris_territory'),Catalog.get('galaxy_territory')}
                for i,f in ipairs(state.factions or {})do if (f.share or 0)>0 then glint[f.id]=Glints.styleFor(tops[i%3+1],3,f.share)end end
                return glint
            end or nil
            return true end
        if kind=='lobby'and multiplayerLobby then
            local l=multiplayerLobby;local d=l.deployment
            if value and value.action=='open'then l:closePage();d:open(value.filter,value.id)
            elseif value and value.action=='select'then d.selected=value.id;d:render()
            elseif value and value.action=='solo'then l:openPage('solo');if value.start then require(pack.Client.DeploymentSetup).start(l)end
            elseif value and value.action=='page'then l:openPage(value.id)
            elseif value and value.action=='skin'then l.wardrobeTab='items';l.slot=value.id;l.wardrobePick=value.pick;l.skinMapView=value.map==true;l:drawPage()
            elseif value and value.action=='goalTab'then l.goalTab=value.id;l.pageBody.CanvasPosition=Vector2.zero;l:drawPage()
            elseif value and value.action=='room'then l:openPage('room')
            elseif value and value.action=='join'then d:join(value.id)
            elseif value and value.action=='suggested'then d:inspectSuggestion()
            elseif value and value.action=='cancel'then l:request('cancel')end
            if value and value.action=='dismissAutoLesson'then armsUI.autoLesson=true;l.skipIntro=true;l:refresh()end
            if value and value.action=='teams'and l.data and l.data.queue then l.teamRoster:open(l.data.queue)end
            return {filter=d.filter,selected=d.selected,page=l.page,fields=d.fields,queue=l.data and l.data.queue,soloCustomized=l.soloCustomized,firstLesson=l.firstLesson,accountLoading=l.account.loading,accountReady=l.account.ready}
        end
        if kind=='detail'then armsUI.tactical:open(value.id,value.tab,value.tile);return true end
        if kind=='signalVisual'then
            local ok=armsUI.chat.pings:add(2,{kind='signal',key=value.key,scope=value.scope},value.tile)
            armsUI.chat.pings:step();return {ok=ok,count=#armsUI.chat.pings.items}
        end
        if kind=='tile'then armsUI.qaSelectTile(value);return true end
        if kind=='inputState'then local count=0;for _ in pairs(inFlight)do count+=1 end;return {selection=selectionRevision,tile=selectedTile,mode=action,sheet=sheetMode,moving=armsUI.moving,pending=count,primary=armsUI.primary and armsUI.primary.Name,primaryEnabled=armsUI.primary and armsUI.primary.Active,feedback=armsUI.inputFlow:status(os.clock())}end
        if kind=='mapInformation'then return state and {phase=state.phase,version=state.version,paused=state.paused,player=state.player,operations=state.operations,guide=state.guide}end
        if kind=='drop'and armsUI.drop.active and type(value)=='table'then
            if typeof(value.move)=='Vector3' then armsUI.drop.qaMove=value.move end
            if value.stop then armsUI.drop.qaMove=nil end
            if value.land then armsUI.drop:landNow()end
            return true
        end
        if kind=='sheet'then local r=armsUI.sheets:qa(value);layout();return r end
        if kind=='modal'then armsUI.helpTab=value=='help'and armsUI.helpTab or value and value:match('^help:(%w+)')or armsUI.helpTab;if value then openModal(value:match('^(%w+)'))else closeModal()end;return true end
        if kind=='touch'then armsUI.input.force(value);armsUI.coach.dismissed=true;return armsUI.input.touch()end
        if kind=='cards'then
            local f=sortedFactions[2]or sortedFactions[1];armsUI.qaFake=value and {incoming={{from=f.id,name=f.name,created=state.tick,expires=state.tick+2400}},outgoing={}}or nil
            if not armsUI.qaWrap then armsUI.qaWrap=true;local real=inbox.update;inbox.update=function(i,st)if armsUI.qaFake then st=table.clone(st);st.diplomacy=armsUI.qaFake end;return real(i,st)end end
            for _,e in ipairs(type(value)=='table'and value or {})do armsUI.eventLog:add(e[1],e[2],e[3]and f.labelTile,state.tick,e[4])end
            layout();return true end
        if kind=='growth'then require(pack.Client.MatchBubble).growth(root,armsUI.growthBadge,armsUI.lastRecruitment,state.player);return true end
        if kind=='confirm'then armsUI.confirmCurrent();return true end
        if kind=='command'then send(value.action,value.value,value.extra);return true end
        if kind=='resultQA'then
            if value=='spectate'then closeModal();layout()
            elseif value=='next'then armsUI.spectator:select(1)
            elseif value=='previous'then armsUI.spectator:select(-1)
            elseif value=='result'then openModal('result')
            elseif value=='recap'then openModal('recap')end
            return {target=armsUI.spectator.targetId,visible=armsUI.spectator.frame.Visible,modal=modalMode}
        end
        if kind=='aim'then if value.kind then chooseBuild(value.kind)end;if value.tile then armsUI.nuclear:lock(value.tile)end;return armsUI.nuclear.plan end
    end
end
local nameTag=FactionBadge.new(markerLayer,"CountryLabel");nameTag.ZIndex=4
armsUI.identityLeader=make("Frame",markerLayer,{Name="CountryLeader",AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=C.ice,BackgroundTransparency=.42,BorderSizePixel=0,ZIndex=0,Visible=false})
nameTag.Troops.TextSize=16
armsUI.nameLayer=require(pack.Client.NameLayer).new(markerLayer)
local selection=make("Frame",markerLayer,{Name="Selection",Size=UDim2.fromOffset(30,30),AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1,Visible=false});UI.corner(selection,999);UI.stroke(selection,C.gold,2)
make("Frame",selection,{Name="Dot",Size=UDim2.fromOffset(4,4),Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=C.gold,BorderSizePixel=0})
local placement=make("Frame",markerLayer,{Name="BuildPreview",Size=UDim2.fromOffset(32,32),AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=C.accent,BackgroundTransparency=.65,Visible=false});UI.corner(placement,6);local placementStroke=UI.stroke(placement,C.accent,2)
armsUI.ghostTip=make("Frame",markerLayer,{Name="BuildGhostTip",AutomaticSize=Enum.AutomaticSize.XY,BackgroundColor3=C.bg,BackgroundTransparency=.15,BorderSizePixel=0,Visible=false,ZIndex=6});UI.corner(armsUI.ghostTip,4)
make("UIListLayout",armsUI.ghostTip,{FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,1)})
make("UIPadding",armsUI.ghostTip,{PaddingLeft=UDim.new(0,7),PaddingRight=UDim.new(0,7),PaddingTop=UDim.new(0,3),PaddingBottom=UDim.new(0,4)})
armsUI.ghostCost=label(armsUI.ghostTip,"Cost","",14,C.gold);armsUI.ghostCost.AutomaticSize=Enum.AutomaticSize.XY;armsUI.ghostCost.Size=UDim2.new();armsUI.ghostCost.TextWrapped=false;armsUI.ghostCost.Font=Enum.Font.BuilderSansBold;armsUI.ghostCost.ZIndex=7;armsUI.ghostCost.LayoutOrder=1
armsUI.ghostReason=label(armsUI.ghostTip,"Reason","",12,C.danger);armsUI.ghostReason.AutomaticSize=Enum.AutomaticSize.XY;armsUI.ghostReason.Size=UDim2.new();armsUI.ghostReason.TextWrapped=false;armsUI.ghostReason.ZIndex=7;armsUI.ghostReason.LayoutOrder=2
local range=make("Frame",markerLayer,{Name="DefenseRange",AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1,Visible=false});UI.corner(range,999);UI.stroke(range,C.gold,1)
local unitMarkers={}
local hud=UI.panel(gamePanel,"HUD");hud.ZIndex=10
local hudBrand=label(hud,"Brand","SUPER COMMANDER",16,C.accent);UI.display(hudBrand);hudBrand:SetAttribute("LocalizationSkip",true)
armsUI.growthBadge=button(hud,'Recruitment','',function()if state and state.player then require(pack.Client.MatchBubble).growth(root,armsUI.growthBadge,armsUI.lastRecruitment,state.player)end end);armsUI.growthBadge.BackgroundTransparency=1
armsUI.growthFace=make('Frame',armsUI.growthBadge,{Name='Face',BackgroundColor3=C.good,BackgroundTransparency=.82,BorderSizePixel=0});UI.corner(armsUI.growthFace,3)
armsUI.growthStroke=UI.stroke(armsUI.growthFace,C.good,1)
armsUI.growthArrow=label(armsUI.growthBadge,'Direction','→',20,C.good);armsUI.growthArrow.Font=Enum.Font.BuilderSansBold;armsUI.growthArrow.TextWrapped=false
armsUI.growthIcon=Icons.create(armsUI.growthBadge,'troops',18)
local statsTroopsSub=label(armsUI.growthBadge,"TroopsDetail","",18,C.good);statsTroopsSub.Font=Enum.Font.BuilderSansBold;statsTroopsSub.TextWrapped=false
local troopBar=make("Frame",hud,{Name="CapacityTrack",BackgroundColor3=C.raised,BorderSizePixel=0,ClipsDescendants=true,ZIndex=2});UI.corner(troopBar,3);UI.stroke(troopBar,C.line,1)
local statsTroops=label(troopBar,"Troops","",18);statsTroops.ZIndex=3
local troopFill=make("Frame",troopBar,{Name="Fill",Size=UDim2.fromScale(0,1),BackgroundColor3=C.accent,BorderSizePixel=0,ClipsDescendants=true,ZIndex=4});UI.corner(troopFill,3)
armsUI.filledTroops=label(troopFill,'TroopsFilled','',18,C.bg);armsUI.filledTroops.ZIndex=5
armsUI.troopWatermark=Icons.create(troopBar,'troops',30);armsUI.troopWatermark.ZIndex=2;armsUI.troopWatermark.ImageTransparency=.84
armsUI.filledWatermark=Icons.create(troopFill,'troops',30);armsUI.filledWatermark.ZIndex=4;armsUI.filledWatermark.ImageColor3=C.bg;armsUI.filledWatermark.ImageTransparency=.8
armsUI.troopFront=require(pack.Client.TroopFront).new(troopBar)
local statsGold=label(hud,"Gold","",19,C.gold)
local statsGoldSub=label(hud,"Income","",11,C.muted)
local troopIcon=Icons.create(hud,"troops",30)
local goldIcon=Icons.create(hud,"gold",30)
local statsLand=label(hud,"Land","",19)
local timerText=label(hud,"Time","",11,C.muted)
local pauseButton=button(hud,"Pause","메뉴",function() openModal(state and (state.phase=='won'or state.phase=='lost')and not state.observer and 'result'or 'pause') end)
pauseButton.BackgroundTransparency=1
armsUI.menuPlate=UI.panel(pauseButton,'MenuPlate');box(armsUI.menuPlate,8,8,28,28);armsUI.menuPlate.BackgroundColor3=C.raised;armsUI.menuPlate.BackgroundTransparency=0
for i=1,3 do make('Frame',armsUI.menuPlate,{Name='Bar'..i,BackgroundColor3=C.ink,BorderSizePixel=0,Position=UDim2.fromOffset(7,6+i*4),Size=UDim2.fromOffset(14,1)})end
armsUI.coach=require(pack.Client.FirstPlayGuide).new(gamePanel,renderer,{
    city=function()chooseBuild('City')end,
    skip=function()tutorial=false;if shop and not(state and state.unrecorded)then shop:run(function()shop:request('tutorial',false)end)end end,
    menu=function()send('menu')end,
    play=function(after)multiplayerLobby.skipIntro=true;multiplayerLobby:request('play',nil,after)end,
    praise=function(text)notify(text)end,
})
local guide=armsUI.coach.frame
armsUI.quickSpawn=button(gamePanel,"QuickSpawn","자동 배치로 빠른 시작",function()send("spawn","auto")end,true)
armsUI.quickSpawn.ZIndex=15;armsUI.quickSpawn.Visible=false;armsUI.quickSpawn.TextSize=16
local function home()
    renderer:follow();dirty=true
end
local controls=UI.panel(gamePanel,"Controls");controls.ZIndex=12
controls.BackgroundColor3=C.panel;controls.BackgroundTransparency=.07;UI.stroke(controls,C.line)
require(pack.Client.FullBleed).edge(controls)
hud.Parent=controls;hud.BackgroundTransparency=1;pauseButton.Parent=controls
local selectedInfo=label(controls,"SelectionInfo","",12,C.ink);selectedInfo.Font=Enum.Font.BuilderSansBold
local dispatchIcon=Icons.create(controls,"attack",18)
local dispatchSlider=make("TextButton",controls,{Name="DispatchSlider",Text="",BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Active=true})
local dispatchTrack=make("Frame",dispatchSlider,{Name="Track",BackgroundColor3=C.line,BorderSizePixel=0});UI.corner(dispatchTrack,3)
local dispatchFill=make("Frame",dispatchTrack,{Name="Fill",Size=UDim2.fromScale(0,1),BackgroundColor3=C.accent,BorderSizePixel=0});UI.corner(dispatchFill,3)
local dispatchKnob=make("Frame",dispatchTrack,{Name="Knob",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(0,.5),Size=UDim2.fromOffset(15,15),BackgroundColor3=C.accent,BorderSizePixel=0});UI.corner(dispatchKnob,999)
local dockDivider=make("Frame",controls,{Name="Divider",BackgroundColor3=C.line,BorderSizePixel=0})
local function refuseCost(kind)
    local cost=state and state.costs and tonumber(state.costs[kind]);local gold=state and state.player and tonumber(state.player.gold)
    if not(state and state.phase=="playing" and cost and gold and cost>gold)then return false end
    if armsUI.dock then armsUI.dock:deny(kind)end;armsUI.audio.play("error")
    notify("골드 부족",true);return true
end
armsUI.refuseCost=refuseCost
chooseBuild=function(kind)
    local prerequisite=state and armsUI.commands.prerequisite(state,kind)
    if prerequisite then armsUI.dock:deny(kind);armsUI.audio.play('error');notify(prerequisite,true);return end
    if refuseCost(kind)then return end
    selectionRevision+=1;armsUI.lastTap=nil
    armsUI.dockHover=nil
    armsUI.nuclear:stop();armsUI.sheets:closeAll()
    selectedUnit=nil;armsUI.moving=nil
    if armsUI.rules.nukes[kind]then action=kind;sheetMode=nil;selectedTile=nil;preview=nil;armsUI.nuclear:start(kind);refreshSheet();return end
    if selectedTile and currentMap then
        local land=Terrain.isLand(buffer.readu8(currentMap.terrain,selectedTile))
        if armsUI.rules.structures[kind] and owners[selectedTile]~=1 or kind=="Warship" and land or armsUI.rules.nukes[kind] and owners[selectedTile]==1 then selectedTile=nil end
    end
    action=kind;sheetMode="placement";preview=nil
    if armsUI.ghostMode()then selectedTile=nil;armsUI.ghostLast=nil;armsUI.ghostHover(renderer:tileAt(UIS:GetMouseLocation()-game:GetService("GuiService"):GetGuiInset()))end
    refreshContext()
end
armsUI.dock=require(pack.Client.CommandDock).new(controls,function(kind)if not armsUI.keepPalette then armsUI.paletteExpanded=false end;chooseBuild(kind)end)
armsUI.dock.onInspect=function(kind)if not armsUI.input.touch() then armsUI.dockHover=kind;if refreshSheet then refreshSheet()end end end
armsUI.modeBar=make("Frame",gamePanel,{Name="ActionGuidance",BackgroundColor3=C.panel,BackgroundTransparency=.08,BorderSizePixel=0,Visible=false,Active=true,ZIndex=10})
armsUI.modeTitle=label(armsUI.modeBar,"Title","",13,C.accent)
armsUI.modeHint=label(armsUI.modeBar,"Hint","",11,C.muted);armsUI.modeHint.TextWrapped=false;armsUI.modeHint.TextTruncate=Enum.TextTruncate.AtEnd
armsUI.modeCancel=button(armsUI.modeBar,"Cancel","×",function()selectionRevision+=1;armsUI.lastTap=nil;action="inspect";sheetMode=nil;selectedUnit=nil;preview=nil;previewSerial+=1;armsUI.moving=nil;refreshContext()end)
armsUI.modeAll=button(armsUI.modeBar,"AllWarships","모든 군함",function()armsUI.selectAllWarships()end);armsUI.modeAll.TextSize=12
armsUI.openPalette=function(group)
    selectionRevision+=1;armsUI.lastTap=nil
    armsUI.nuclear:stop()
    action="inspect";sheetMode=nil;preview=nil;selectedUnit=nil;armsUI.dock:setGroup(group);armsUI.paletteExpanded=true;refreshSheet();refreshMarkers()
end
armsUI.dock.onGroup=function(group,previous)
    if armsUI.input.touch() then armsUI.paletteExpanded=not armsUI.paletteExpanded or group~=previous end
    selectionRevision+=1;armsUI.lastTap=nil
    armsUI.nuclear:stop()
    action="inspect";sheetMode=nil;preview=nil;previewSerial+=1;refreshSheet();refreshMarkers()
end
armsUI.moving=nil
local quickCity=button(controls,"QuickCity","도시",function() chooseBuild("City") end)
local quickPost=button(controls,"QuickPost","요새",function() chooseBuild("DefensePost") end)
for _,b in ipairs({quickCity,quickPost}) do
    b.Text="";b.BackgroundColor3=C.raised;b:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0,3)
end
local quickCityPreview=BuildingModels.preview(quickCity,"City",CosmeticCatalog.get("classic"))
local quickPostPreview=BuildingModels.preview(quickPost,"DefensePost",CosmeticCatalog.get("classic"))
local quickCityText=label(quickCity,"Label","도시",11)
local quickPostText=label(quickPost,"Label","초소",11)
local rankButton=button(controls,"Ranks","순위",function() armsUI.sheets:open("ranks") end)
local helpButton=button(controls,"Help","도움말",function() openModal("help") end)
local function updateDispatch()
    local ratio=(fraction-.01)/.99
    dispatchFill.Size=UDim2.fromScale(ratio,1);dispatchKnob.Position=UDim2.fromScale(ratio,.5)
    gui:SetAttribute("DispatchPercent",math.floor(fraction*100+.5))
    if refreshAttackAmount then refreshAttackAmount() end
    selectedInfo.Text=math.floor(fraction*100+.5)..'%'
    if armsUI.commandBar then armsUI.commandBar:dispatch(fraction) end
end
local function setFraction(n)
    fraction=math.clamp(n,.01,1);updateDispatch()
end
armsUI.commandBar=require(pack.Client.CommandBar).new({controls=controls,hud=hud,growthBadge=armsUI.growthBadge,growthFace=armsUI.growthFace,growthArrow=armsUI.growthArrow,growthIcon=armsUI.growthIcon,
    statsTroopsSub=statsTroopsSub,troopBar=troopBar,statsTroops=statsTroops,filledTroops=armsUI.filledTroops,troopWatermark=armsUI.troopWatermark,filledWatermark=armsUI.filledWatermark,
    troopIcon=troopIcon,statsGold=statsGold,statsGoldSub=statsGoldSub,goldIcon=goldIcon,statsLand=statsLand,selectedInfo=selectedInfo,
    dispatchIcon=dispatchIcon,dispatchSlider=dispatchSlider,dispatchTrack=dispatchTrack,dispatchKnob=dispatchKnob,dockDivider=dockDivider,pauseButton=pauseButton,dock=armsUI.dock},setFraction)
local sliderInput=nil
local function slideAt(x) setFraction(armsUI.commandBar:fraction(x-dispatchTrack.AbsolutePosition.X,dispatchTrack.AbsoluteSize.X)) end
dispatchSlider.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then sliderInput=input;slideAt(input.Position.X) end
end)
UIS.InputChanged:Connect(function(input)
    if sliderInput and (input==sliderInput or sliderInput.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then slideAt(input.Position.X) end
end)
UIS.InputEnded:Connect(function(input) if input==sliderInput or input.UserInputType==Enum.UserInputType.MouseButton1 then sliderInput=nil end;if input.KeyCode==Enum.KeyCode.Space then renderer.spaceAt=nil;renderer:setAltView(false)end end)
UIS.WindowFocusReleased:Connect(function() sliderInput=nil end)
updateDispatch()
armsUI.orders=require(pack.Client.OperationsPanel).new(gamePanel,renderer,send,function()sheetMode=nil;action='inspect';preview=nil;refreshSheet();refreshMarkers()end)
local operations=armsUI.orders.frame
local function refreshOperations()
    if state then armsUI.orders:update(state,factions)end
end
local sheet=UI.panel(gamePanel,"ActionSheet");sheet.ZIndex=24;sheet.Visible=false
local sheetTitle=label(sheet,"Title","",19)
local sheetDetail=label(sheet,"Detail","",14,C.muted)
armsUI.closeSheet=function() selectionRevision+=1;armsUI.lastTap=nil;sheetMode=nil;action="inspect";preview=nil;refreshSheet();refreshMarkers() end
local sheetClose=button(sheet,"Close","×",armsUI.closeSheet);sheetClose.TextSize=22
armsUI.cameraGuard=require(pack.Client.MenuCameraGuard).new(renderer)
armsUI.openContextBuild=function()
    if selectedTile and currentMap and not Terrain.isLand(buffer.readu8(currentMap.terrain,selectedTile)) or selectedUnit and selectedUnit.kind=="Port" then chooseBuild("Warship") else armsUI.openPalette("build") end
end
local contextBuild=button(sheet,"OpenBuild","건설",armsUI.openContextBuild,true)
Icons.button(contextBuild,"build")
armsUI.swapGlyph=require(pack.Client.ActionGlyphs).swap
armsUI.contextBuildIcon=armsUI.swapGlyph(contextBuild:FindFirstChild("Icon_build"),"build")
armsUI.ring={};armsUI.ringIcons={}
for _,kind in ipairs({"City","Factory","Port","DefensePost","MissileSilo","SAMLauncher","Warship"})do
    local b=button(sheet,"Ring"..kind,"",function()armsUI.ringBuild(kind)end);b.Visible=false;b:SetAttribute("BuildKind",kind)
    armsUI.ring[kind]=b;armsUI.ringIcons[b]=require(pack.Client.HotbarIcons).create(b,kind,22)
end
armsUI.ring.Warship.TextColor3=C.bg
armsUI.ringBlock=function(kind)
    if not state or not selectedTile then return "" end
    local prerequisite=armsUI.commands.prerequisite(state,kind);if prerequisite then return prerequisite end
    local here=armsUI.buildables and armsUI.buildables[kind]
    if kind=="Warship"and not (armsUI.context and armsUI.context.warship)then return "항구 옆 바다 선택" end
    if here and not here.valid then return here.reason or "건설 불가" end
    if not affordable(state.costs[kind])then return "골드 부족" end
end
armsUI.ringBuild=function(kind)
    if not state or state.paused or not selectedTile then return end
    local why=armsUI.ringBlock(kind)
    if why=="골드 부족" then refuseCost(kind);return end
    if why then armsUI.audio.play("error");notify(why,true);return end
    send("build",kind,selectedTile)
end
local cityButton=button(sheet,"BuildCity","",function() if refuseCost("City")then return end;action="City";sheetMode="placement";preview=nil;refreshContext() end)
local postButton=button(sheet,"BuildPost","",function() if refuseCost("DefensePost")then return end;action="DefensePost";sheetMode="placement";preview=nil;refreshContext() end)
armsUI.rockets=button(sheet,"Rockets","로켓",function()armsUI.openPalette("arms")end)
armsUI.rocketIcon=armsUI.swapGlyph(Icons.create(armsUI.rockets,"attack",26),"rockets")
local cityPreview=BuildingModels.preview(cityButton,"City",CosmeticCatalog.get("classic"))
local postPreview=BuildingModels.preview(postButton,"DefensePost",CosmeticCatalog.get("classic"))
for _,b in ipairs({cityButton,postButton}) do b.TextXAlignment=Enum.TextXAlignment.Right;local pad=make("UIPadding",b,{PaddingLeft=UDim.new(0,60),PaddingRight=UDim.new(0,10)});b.TextSize=13 end
executePrimary=function()
    if not state or state.paused then return end
    if armsUI.nuclear.active then armsUI.nuclear:fire();return end
    if state.phase=="spawn" and selectedTile then send("spawn",selectedTile)
    elseif action=="moveWarship" and armsUI.moving and selectedTile then send(type(armsUI.moving)=="table" and "moveWarships" or "moveWarship",armsUI.moving,selectedTile)
        require(pack.Client.MoveMarker).mark(renderer,selectedTile,renderer.reducedEffects==true)
    elseif table.find(armsUI.rules.buildable,action) then if preview and preview.valid then send("build",action,selectedTile) end
    elseif selectedUnit and (selectedUnit.owner or 1)==1 and not selectedUnit.building then
        if selectedUnit.kind=="Warship" then armsUI.moving=selectedUnit.id;action="moveWarship";selectedUnit=nil;sheetMode=nil;notify("바다 선택");refreshSheet()
        elseif selectedUnit.kind=="TransportShip" then send("cancelTransport",selectedUnit.id)
        else send("upgrade",selectedUnit.id) end
    elseif selectedTile then
        local target=factions[owners[selectedTile]]
        if not (target and target.allied) then send("attack",fraction,selectedTile) end
    end
end
local confirmButton=button(sheet,"Confirm","",executePrimary,true)
armsUI.upgradeMax=button(sheet,"UpgradeMax","최대",function() if selectedUnit and not (state and state.paused) then send("upgrade",selectedUnit.id,"max") end end)
armsUI.transport=button(sheet,"Transport","⚓\n상륙",function() armsUI.primaryActions[armsUI.transport]() end)
local radialAttack=armsUI.swapGlyph(Icons.create(confirmButton,"attack",26),"attack")
local radialTransport=armsUI.swapGlyph(Icons.create(confirmButton,"transport",26),"transport")
local radialBuild=armsUI.swapGlyph(Icons.create(confirmButton,"build",26),"build")
refreshAttackAmount=function()
    if not state or sheetMode~="tile" or state.phase~="playing" or not selectedTile then return end
    if action=="moveWarship" then return end
    local tileByte=currentMap and buffer.readu8(currentMap.terrain,selectedTile);if tileByte and not Terrain.isLand(tileByte) then return end
    local owner=owners[selectedTile] or 0
    local target=factions[owner]
    if owner~=1 and not (target and target.allied) then
        confirmButton.Text=(armsUI.attackRoute=='transport' and "수송 공격\n" or "공격\n")..UI.troops(math.floor(state.player.troops*fraction))
        confirmButton:SetAttribute('ActionDescription',armsUI.attackRoute=='transport' and "해상 수송 공격" or "공격")
        confirmButton:SetAttribute('AttackRoute',armsUI.attackRoute)
        armsUI.transport.Text="수송\n"..UI.troops(math.floor(state.player.troops*fraction))
    end
end
local demolishButton=button(sheet,"Demolish","철거",function() if selectedUnit then openModal("demolish") end end)
local allianceButton=button(sheet,"Alliance","동맹 요청",function()
    local p=selectedTile and factions[owners[selectedTile]]
    if p and p.id~=1 then
        if p.allied then
            send("alliance","break",p.id)
            armsUI.closeRadial()
        elseif p.incomingRequest then send("alliance","accept",p.id) else send("alliance","request",p.id) end
    end
end)
local allianceIcon=label(allianceButton,"Link","",26,C.accent);allianceIcon.TextXAlignment=Enum.TextXAlignment.Center;require(pack.Client.AllianceGlyph).attach(allianceIcon);allianceIcon=armsUI.swapGlyph(allianceIcon,"alliance",C.accent)
local function radialSupport(kind)
    local p=selectedTile and factions[owners[selectedTile]]
    if p and p.allied then send("support",kind,p.id) end
end
local supportGold=button(sheet,"SupportGold","골드 지원",function() radialSupport("gold") end)
local supportTroops=button(sheet,"SupportTroops","병력 지원",function() radialSupport("troops") end)
local supportGoldIcon=armsUI.swapGlyph(Icons.create(supportGold,"gold",26),"gold",C.gold)
local supportTroopIcon=armsUI.swapGlyph(Icons.create(supportTroops,"troops",26),"troops")
armsUI.detail=button(sheet,'Details','상세',function()local f=selectedTile and factions[owners[selectedTile]];if f then sheetMode=nil;refreshSheet();armsUI.tactical:open(f.id)end end)
armsUI.signal=button(sheet,'Signals','소통',function()local f=selectedTile and factions[owners[selectedTile]];if f then sheetMode=nil;refreshSheet();armsUI.tactical:open(f.id,'signals',selectedTile)end end)
armsUI.emoji=button(sheet,'Emojis','이모지',function()local f=selectedTile and factions[owners[selectedTile]];if f then sheetMode=nil;refreshSheet();armsUI.tactical:open(f.id,'emoji')end end)
armsUI.detailIcon=label(armsUI.detail,'Glyph','≡',26,C.ink);armsUI.detailIcon.TextXAlignment=Enum.TextXAlignment.Center;armsUI.detailIcon=armsUI.swapGlyph(armsUI.detailIcon,'detail')
armsUI.signalIcon=make('Frame',armsUI.signal,{Name='SignalFlag',BackgroundTransparency=1,Size=UDim2.fromOffset(26,26)})
make('Frame',armsUI.signalIcon,{Name='Pole',Position=UDim2.fromScale(.2,.12),Size=UDim2.fromScale(.12,.8),BackgroundColor3=C.accent,BorderSizePixel=0})
make('Frame',armsUI.signalIcon,{Name='Flag',Position=UDim2.fromScale(.32,.12),Size=UDim2.fromScale(.55,.38),BackgroundColor3=C.accent,BorderSizePixel=0});armsUI.signalIcon=armsUI.swapGlyph(armsUI.signalIcon,'signal',C.accent)
armsUI.emojiIcon=label(armsUI.emoji,'Glyph','☺',26,C.gold);armsUI.emojiIcon.TextXAlignment=Enum.TextXAlignment.Center;armsUI.emojiIcon=armsUI.swapGlyph(armsUI.emojiIcon,'emoji',C.gold)
armsUI.transportGlyph=armsUI.swapGlyph(Icons.create(armsUI.transport,"transport",26),"transport")
armsUI.demolishIcon=armsUI.swapGlyph(Icons.create(demolishButton,"build",26),"demolish",C.danger);armsUI.demolishIcon.ImageColor3=C.danger
if armsUI.demolishIcon.Name~='Glyph_demolish' then make("Frame",armsUI.demolishIcon,{Name="Slash",Size=UDim2.new(1.2,0,0,3),Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),Rotation=-45,BackgroundColor3=C.danger,BorderSizePixel=0}) end
armsUI.radialTrack=make("Frame",sheet,{Name="RadialTrack",BackgroundTransparency=1,Visible=false,ZIndex=0});UI.corner(armsUI.radialTrack,999)
local trackLine=UI.stroke(armsUI.radialTrack,C.line,1.5);trackLine.Transparency=.35
armsUI.radialCore=make("Frame",sheet,{Name="RadialCore",BackgroundColor3=C.bg,BackgroundTransparency=.35,BorderSizePixel=0,Visible=false,ZIndex=0});UI.corner(armsUI.radialCore,999)
armsUI.radialScale=make("UIScale",sheet,{Name="RadialScale"})
local radialCaptions={}
local function radialCaption(btn)
    local cap=radialCaptions[btn]
    if cap then return cap end
    cap=label(btn,"Caption","",14);cap.TextWrapped=false;cap.TextTruncate=Enum.TextTruncate.AtEnd;cap.TextStrokeTransparency=1;cap.BackgroundColor3=C.bg;cap.BackgroundTransparency=.12;UI.corner(cap,3);cap.ZIndex=btn.ZIndex+1;cap.Visible=false
    local padding=make('UIPadding',cap,{});padding.PaddingLeft=UDim.new(0,4);padding.PaddingRight=UDim.new(0,4)
    local function sync()
        if btn==supportGold then cap.Text='골드'
        elseif btn==allianceButton then cap.Text=btn:GetAttribute('Breaking')==true and btn.Text or '동맹'
        elseif btn==armsUI.transport then cap.Text='수송'
        else cap.Text=(btn.Text:gsub("⚓%s*",""):gsub("\n"," "))end
    end
    btn:GetPropertyChangedSignal("Text"):Connect(sync);sync()
    btn:GetPropertyChangedSignal("TextTransparency"):Connect(function()
        if btn:GetAttribute("RadialHideText") and btn.TextTransparency~=1 then cap.TextTransparency=btn.TextTransparency;btn.TextTransparency=1 end
    end)
    radialCaptions[btn]=cap;return cap
end
local function radialIcon(btn)
    local icon=if armsUI.ringIcons[btn] then armsUI.ringIcons[btn] elseif btn==confirmButton then (radialTransport.Visible and radialTransport or radialAttack.Visible and radialAttack or radialBuild.Visible and radialBuild or nil)
        elseif btn==allianceButton then allianceIcon elseif btn==cityButton then cityPreview elseif btn==postButton then postPreview
        elseif btn==demolishButton then armsUI.demolishIcon elseif btn==supportGold then supportGoldIcon elseif btn==supportTroops then supportTroopIcon
        elseif btn==armsUI.transport then armsUI.transportGlyph elseif btn==contextBuild then armsUI.contextBuildIcon elseif btn==armsUI.rockets then armsUI.rocketIcon
        elseif btn==armsUI.detail then armsUI.detailIcon elseif btn==armsUI.signal then armsUI.signalIcon elseif btn==armsUI.emoji then armsUI.emojiIcon else nil
    if icon and icon:GetAttribute("Available")==false then return nil end
    return icon
end
local radialShown=false
local function radialPop(from)
    armsUI.radialScale.Scale=1
    if effects.reduced then return end
    local line=armsUI.radialTrack:FindFirstChildOfClass('UIStroke');if not line then return end
    if armsUI.radialTween then armsUI.radialTween:Cancel()end
    line.Transparency=.8
    armsUI.radialTween=game:GetService("TweenService"):Create(line,TweenInfo.new(.16,Enum.EasingStyle.Quad),{Transparency=.35});armsUI.radialTween:Play()
end
local function radialEcho(fired)
    if effects.reduced or not armsUI.radialTrack.Visible then return end
    local s=armsUI.radialTrack.AbsoluteSize.X/UI.scale;if s<2 then return end
    local echo=make("Frame",gamePanel,{Name="RadialEcho",AnchorPoint=Vector2.new(.5,.5),Position=sheet.Position,Size=UDim2.fromOffset(s,s),BackgroundTransparency=1,ZIndex=sheet.ZIndex})
    UI.corner(echo,999);local line=UI.stroke(echo,fired and C.accent or C.line,fired and 3 or 2);line.Transparency=fired and .1 or .3
    local info=TweenInfo.new(fired and .26 or .14,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
    local TS=game:GetService("TweenService")
    TS:Create(echo,info,{Size=UDim2.fromOffset(s*(fired and 1.35 or .55),s*(fired and 1.35 or .55))}):Play()
    TS:Create(line,info,{Transparency=1}):Play()
    task.delay(info.Time+.05,function() echo:Destroy() end)
end
sheet:GetPropertyChangedSignal("Visible"):Connect(function()
    local radial=sheetMode=="tile" or sheetMode=="unit" or sheetMode=="placement"
    if sheet.Visible and radial then radialPop(.55);radialShown=true
    elseif not sheet.Visible and radialShown then radialShown=false;radialEcho(armsUI.firedAt~=nil and os.clock()-armsUI.firedAt<.4) end
end)
armsUI.radialPop=radialPop
armsUI.closesRadial={attack=true,transport=true,support=true,alliance=true,upgrade=true,cancelTransport=true,build=true,moveWarship=true,moveWarships=true}
armsUI.closeRadial=function()
    if not sheet.Visible or not (sheetMode=="tile" or sheetMode=="unit" or sheetMode=="placement")then return end
    selectionRevision+=1;armsUI.lastTap=nil;armsUI.breakArmed=nil
    sheetMode=nil;selectedUnit=nil;selectedTile=nil;preview=nil;previewSerial+=1;if action~="moveWarship"then action="inspect"end
    gui:SetAttribute("SelectedTile",nil);refreshSheet();refreshMarkers();return true
end
armsUI.primaryActions={[confirmButton]=executePrimary,[armsUI.transport]=function()if armsUI.context and armsUI.context.transportFull then return notify("수송선 3/3",true)end;if selectedTile then send("transport",fraction,selectedTile)end end,[supportTroops]=function()radialSupport("troops")end,[contextBuild]=armsUI.openContextBuild}
armsUI.ring20=require(pack.Client.RadialLayout20).new({sheet=sheet,renderer=renderer,guard=armsUI.cameraGuard,notify=notify,anchor=function(v)if v then menuAnchor=v;positionSheet()end;return menuAnchor end,
    confirm=confirmButton,alliance=allianceButton,gold=supportGold,troops=supportTroops,transport=armsUI.transport,rockets=armsUI.rockets,detail=armsUI.detail,signal=armsUI.signal,emoji=armsUI.emoji})
armsUI.primaryActions[armsUI.ring.Warship]=function()armsUI.ringBuild("Warship")end
armsUI.primaryButton=function()
    if confirmButton.Visible and not armsUI.confirmDanger then return confirmButton end
    if armsUI.transport.Visible and armsUI.transport:GetAttribute('Enabled')~=false then return armsUI.transport end
    if supportTroops.Visible then return supportTroops end
    if contextBuild.Visible then return contextBuild end
    if armsUI.ring.Warship.Visible then return armsUI.ring.Warship end
end
armsUI.confirmCurrent=function()
    if armsUI.nuclear.active then armsUI.nuclear:fire()
    elseif sheet.Visible and armsUI.primary and armsUI.primary.Visible and armsUI.primary.Active then armsUI.ring20:press(armsUI.primary,armsUI.primaryActions[armsUI.primary])end
end
local hoverCard=require(pack.Client.HoverCard).new(gamePanel);local hover=hoverCard.frame;hoverCard.onClose=armsUI.closeSheet
armsUI.ranks=require(pack.Client.Leaderboard).new(gamePanel,{focus=function(f)if f.labelTile then renderer:focusAt(f.labelTile,true);dirty=true end end,more=function()armsUI.sheets:open("ranks")end,changed=function()task.defer(layout)end})
armsUI.spawnCountdown=require(pack.Client.SpawnCountdown).new(gamePanel)
require(pack.Client.NetLink).new(gamePanel,pack:WaitForChild("State"))
armsUI.matchStatus=require(pack.Client.MatchStatus).new(gamePanel,{speed=function(v)send("speed",v)end,notify=function(m,warning)notify(m,warning);armsUI.eventLog:add(m,warning,nil,state and state.tick)end})
local modal=make("Frame",root,{Name="Modal",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.34,Visible=false,Active=true,ZIndex=30})
local modalCard=UI.panel(modal,"Card");UI.stroke(modalCard)
modalCard.BackgroundTransparency=.04
local modalTitle=label(modalCard,"Title","",23)
local modalClose=button(modalCard,"Close","×",function() closeModal() end)
armsUI.modalBack=button(modalCard,"Back","←",function()openModal("pause")end)
armsUI.modalSize=function(mode)local s=screenSize();return math.min(({help=760,feedback=560,leave=440,demolish=440,pause=s.Y<500 and 640 or 500})[mode]or 520,s.X-24)end
local modalBody=make("ScrollingFrame",modalCard,{Name="Body",BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=C.line,ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.fromOffset(0,0)})
armsUI.resultActions=make('Frame',modalCard,{Name='ResultActions',BackgroundTransparency=1,Visible=false})
local modalMode=nil
local pauseOwned=false
armsUI.styleModal=function()
    local toy=state and (state.phase=='menu'or state.phase=='won'or state.phase=='lost')
    local palette=toy and require(pack.Client.ToyUI).colors or C
    modalCard.BackgroundColor3=palette.panel;modalTitle.TextColor3=palette.ink;modalClose.BackgroundColor3=palette.raised;modalClose.TextColor3=palette.ink
    if toy then for _,v in ipairs(modalCard:GetDescendants())do
        if v:IsA('TextLabel')or v:IsA('TextButton')or v:IsA('TextBox')then
            v.TextColor3=v.TextColor3==C.gold and palette.gold or v.TextColor3==C.muted and palette.muted or v.TextColor3==C.danger and palette.danger or palette.ink
            if v:IsA('TextButton')or v:IsA('TextBox')then
                local primary=v.BackgroundColor3==C.accent;v.BackgroundColor3=primary and palette.accent or palette.raised
                if primary then v.TextColor3=palette.bg end
            end
        elseif v:IsA('UIStroke')then v.Color=palette.line end
    end end
end
local function clearModal() armsUI.resultView=nil;for _,o in ipairs(modalBody:GetChildren()) do o:Destroy() end;for _,o in ipairs(armsUI.resultActions:GetChildren())do o:Destroy()end;armsUI.resultActions.Visible=false end
local function modalLabel(name,text,y,h,color,size)
    local l=label(modalBody,name,text,size or 15,color);l.Position=UDim2.fromOffset(4,y);l.Size=UDim2.new(1,-14,0,h);return l
end
local function modalButton(name,text,y,fn,primary)
    local b=button(modalBody,name,text,fn,primary);b.Position=UDim2.fromOffset(4,y);b.Size=UDim2.new(1,-14,0,48);return b
end
closeModal=function()
    modal.Visible=false;modalMode=nil
    if pauseOwned then pauseOwned=false;send("pause",false) end
end
modal.InputBegan:Connect(function(i)
    if(i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch)and(modalMode=='pause'or modalMode=='feedback'or modalMode=='help')then
        local p,s=modalCard.AbsolutePosition,modalCard.AbsoluteSize;if i.Position.X<p.X or i.Position.Y<p.Y or i.Position.X>p.X+s.X or i.Position.Y>p.Y+s.Y then closeModal()end
    end
end)
local settingsTab="기본"
local function renderSettings()
    clearModal();modalTitle.Text="내 게임의 규칙"
    local s=state and state.settings or {};local width=math.max(240,modalBody.AbsoluteSize.X/UI.scale)
    for i,tab in ipairs({"기본","경제","규칙"})do
        local b=button(modalBody,"Tab_"..tab,tab,function()settingsTab=tab;modalBody.CanvasPosition=Vector2.zero;renderSettings()end,settingsTab==tab)
        box(b,4+(i-1)*(width-8)/3,0,(width-20)/3,44)
    end
    local y=58
    local function heading(text,description)
        modalLabel("Heading"..y,text,y,28,nil,17);y+=32
        if description then modalLabel("Hint"..y,description,y,20,C.muted,12);y+=24 end
    end
    local function inputRow(key,title,description,currentValue)
        heading(title,description)
        local input=make("TextBox",modalBody,{Name=key,Position=UDim2.new(0,4,0,y),Size=UDim2.new(1,-106,0,44),Text=tostring(currentValue or s[key] or (key=="goldMultiplier"and 1 or 0)),ClearTextOnFocus=false,Font=Enum.Font.BuilderSansMedium,TextSize=16,TextColor3=C.ink,BackgroundColor3=C.raised,BorderSizePixel=0});UI.corner(input,8)
        local apply=button(modalBody,key.."Apply","적용",function()local n=tonumber(input.Text);if not n then notify("숫자만",true);return end;send("setting",key,n)end)
        apply.Position=UDim2.new(1,-92,0,y);apply.Size=UDim2.fromOffset(80,44);y+=64
    end
    local function toggle(key,title,description,value)
        local enabled=value;if enabled==nil then enabled=s[key]==true end
        local l=modalLabel(key.."Title",title,y,44,nil,16);l.Size=UDim2.new(1,-112,0,44)
        local b=button(modalBody,"Setting_"..key,enabled and "켜짐"or "꺼짐",function()send("setting",key,not enabled)end,enabled)
        b.Position=UDim2.new(1,-92,0,y);b.Size=UDim2.fromOffset(80,44);y+=48
        if description then modalLabel(key.."Hint",description,y,20,C.muted,12);y+=28 else y+=12 end
    end
    if settingsTab=="기본"then
        heading("빠른 프리셋")
        for i,p in ipairs({{"learn","첫 연습"},{"standard","기본"},{"sandbox","자유 건설"}})do
            local b=button(modalBody,"Preset_"..p[1],p[2],function()send("preset",p[1])end);box(b,4+(i-1)*(width-8)/3,y,(width-20)/3,44);b.TextSize=12
        end;y+=64
        heading("AI 국가 난이도")
        for i,p in ipairs({{"Easy","쉬움"},{"Medium","보통"},{"Hard","어려움"},{"Impossible","불가능"}})do local b=button(modalBody,"Difficulty_"..p[1],p[2],function()send("setting","difficulty",p[1])end,s.difficulty==p[1]);box(b,4+(i-1)*(width-8)/4,y,(width-32)/4,44)end;y+=52
        modalLabel("DifficultyHelp",({Easy="병력 상한 50%",Medium="병력 상한 75%",Hard="병력 상한 100%",Impossible="병력 상한 125%"})[s.difficulty or "Medium"],y,36,C.muted,13);y+=52
        modalButton("NationToggle",s.nations=="disabled"and "AI 국가: 꺼짐"or "AI 국가: 지도 기본",y,function()send("setting","nations",s.nations=="disabled"and "default"or "disabled")end);y+=56
        modalLabel("NationInfo",mapDetails[selectedMap][1]..", AI 국가 "..#Maps.meta(selectedMap).nations,y,44,C.muted,12);y+=60
        if Maps.hasNormal(selectedMap)then
            local big=s.mapSize=="normal"
            modalButton("MapSizeToggle",big and "지도 크기: 큰 지도"or "지도 크기: 기본",y,function()send("setting","mapSize",big and "compact"or "normal")end);y+=56
            modalLabel("MapSizeInfo","땅 4배",y,36,C.muted,12);y+=52
        end
        inputRow("bots","중립 세력 수","0 ~ 400")
    elseif settingsTab=="경제"then
        inputRow("startingGold","시작 골드","0 ~ 1,000,000,000")
        inputRow("goldMultiplier","골드 생산 배율","0.1 ~ 1000배")
        toggle("infiniteGold","무한 골드")
        toggle("infiniteTroops","무한 병력")
        toggle("instantBuild","즉시 건설")
        toggle("waterNukes","물로 변하는 폭발")
        toggle("disableNukes","핵무기 끄기")
        toggle("doomsdayClock","장기전 소모전","10분부터 최소 점유율 상승")
        if s.doomsdayClock then
            heading("소모전 진행 속도")
            for i,p in ipairs({{"slow","느림"},{"normal","보통"},{"fast","빠름"},{"veryfast","아주 빠름"}}) do
                local b=button(modalBody,"ClockSpeed_"..p[1],p[2],function()send("setting","doomsdayClockSpeed",p[1])end,(s.doomsdayClockSpeed or "normal")==p[1])
                box(b,4+(i-1)*(width-8)/4,y,(width-24)/4,44);b.TextSize=12
            end;y+=56
        end
        toggle("disableAlliances","동맹 끄기")
    else
        inputRow("customAllianceDuration","동맹 유지 시간","1 ~ 15분, 0 = 끔")
        inputRow("maxTimerValue","경기 시간 제한","1 ~ 120분, 0 = 무제한")
        local overtime=s.overtime or {}
        toggle("overtimeEnabled","연장전",nil,overtime.enabled==true)
        inputRow("overtimeStartMinutes","연장전 시작 시간","1 ~ 120분, 이후 매분 -2%p",overtime.startMinutes or 30)
        toggle("randomSpawn","랜덤 스폰")
        inputRow("spawnImmunityMinutes","평화 시간","0 ~ 10분, 0 = 5초",math.floor((s.spawnImmunityDuration or 0)/600))
        heading("사용할 유닛")
        for i,kind in ipairs(armsUI.rules.toggleable)do
            local off=s.disabledUnits and table.find(s.disabledUnits,kind)~=nil
            local b=button(modalBody,"Unit_"..kind,armsUI.rules.names[kind],function()
                local list=table.clone(s.disabledUnits or {});local at=table.find(list,kind);if at then table.remove(list,at)else table.insert(list,kind)end;send("setting","disabledUnits",list)end,not off)
            box(b,4+((i-1)%2)*(width-8)/2,y,(width-16)/2,44);b.TextSize=13;if i%2==0 or i==#armsUI.rules.toggleable then y+=52 end
        end
    end
    modalBody.CanvasSize=UDim2.fromOffset(0,y+8)
    armsUI.styleModal()
end
openModal=function(mode)
    armsUI.sheets:closeAll();require(pack.Client.MatchBubble).close()
    local W=armsUI.modalSize(mode)-32;local Menu=require(pack.Client.MatchMenu)
    if mode~=modalMode then modalBody.CanvasPosition=Vector2.zero end
    if mode=="pause" and state and state.phase~="menu" and not state.multiplayer then pauseOwned=true;if not state.paused then send("pause",true) end end
    if mode~=modalMode then pcall(armsUI.telemetry.step,'match','modal',{item=mode})end
    modalMode=mode;modal.Visible=true;hover.Visible=false;clearModal()
    if mode=="settings" then renderSettings()
    elseif mode=="credits" then
        modalTitle.Text="크레딧과 라이선스"
        modalLabel("Copyright","© OpenFront and Contributors",0,42,nil,17)
        do local l=modalLabel("SourceCode","수정 소스: github.com/berkshirebyteaway-tech/super-commander-source",40,18,C.muted,13);l.TextWrapped=false;l.TextScaled=true;make("UITextSizeConstraint",l,{MaxTextSize=13,MinTextSize=8})end
        modalLabel("Sources","OpenFront의 코드를 Roblox / Luau용으로 수정해 이식했습니다. OpenFront 공식 작품이 아닙니다.\n\n코드: GNU AGPL v3 + 원작 추가 조건\n지도, 건물, 유닛, 메뉴 아이콘: OpenFront, CC BY-SA 4.0\n원본 Compact 지도 데이터를 보존하고 3D 표시를 적용했습니다.",60,190,C.muted,14)
        modalLabel("Links","원작: https://github.com/openfrontio/OpenFrontIO\n지도 라이선스: https://creativecommons.org/licenses/by-sa/4.0/\n코드 라이선스: https://www.gnu.org/licenses/agpl-3.0.html\n\nSUPER COMMANDER by Berkshire Byteaway\n코드와 지도는 각 라이선스에 따라 사용합니다.",265,210,C.muted,13)
        modalBody.CanvasSize=UDim2.fromOffset(0,490)
    elseif mode=='recap'then
        modalTitle.Text='작전 분석'
        require(pack.Client.RecapView).draw(modalBody,state.personalResult and state.personalResult.recap,math.max(240,modalBody.AbsoluteSize.X/UI.scale))
        armsUI.resultActions.Visible=true;button(armsUI.resultActions,'Back','결과로 돌아가기',function()openModal('result')end,true)
    elseif mode=="help" then
        modalTitle.Text="플레이 방법"
        Menu.help({body=modalBody,width=W,short=screenSize().Y<500,tab=armsUI.helpTab,touch=armsUI.input.touch(),style=state and state.style,inLobby=state.phase=='menu',
            setTab=function(t)armsUI.helpTab=t;modalBody.CanvasPosition=Vector2.zero;openModal('help')end,
            guide=function()tutorial=true;armsUI.coach.dismissed=false;closeModal();task.delay(.2,function()send(state.phase=='menu'and 'learn'or 'guide')end)end})
    elseif mode=="feedback" then
        modalTitle.Text="설정";local a=shop and shop.account or {}
        Menu.settings({body=modalBody,width=W,shop=shop,prefs=a.preferences,ready=a.ready==true,lobby=state.phase=='menu',language=me:GetAttribute('ToyfrontLocale'),play=armsUI.audio.play,
            setLanguage=function(v)me:SetAttribute('ToyfrontLocale',v~='auto'and v or nil);if shop and a.ready==true then shop:run(function()shop:request('preference','language',v)end)end;openModal('feedback')end,credits=function()openModal('credits')end,redraw=function()openModal('feedback')end})
    elseif mode=="pause" then
        modalTitle.Text="경기 메뉴"
        Menu.draw({body=modalBody,state=state,width=W,compact=screenSize().Y<500,rulesOpen=armsUI.rulesOpen,inboxCount=inbox.count,altView=renderer.altView,act={
            resume=closeModal,guide=function()openModal("help")end,settings=function()openModal("feedback")end,ranks=function()closeModal();armsUI.sheets:open("ranks")end,
            diplomacy=function()closeModal();armsUI.sheets:open("diplomacy")end,world=function()closeModal();renderer:fit();dirty=true end,home=function()closeModal();home()end,
            affiliation=function()renderer:setAltView(not renderer.altView);closeModal();dirty=true end,hostPause=function()send("pause",not state.paused);closeModal()end,
            leave=function()openModal("leave")end,toggleRules=function()armsUI.rulesOpen=not armsUI.rulesOpen;openModal("pause")end}})
    elseif mode=="leave" then
        modalTitle.Text="경기에서 나갈까요?"
        Menu.confirm(modalBody,W,state and state.intro and "" or state and state.clanwar and "패배  클랜전 점수 감소" or state and state.ranked and "패배  랭크 점수 감소" or "기권  2분 넘으면 보상 절반","계속하기",closeModal,"나가기",function() pauseOwned=false;modal.Visible=false;modalMode=nil;armsUI.veil.show("로비로 이동 중…");send("menu") end,{"Cancel","ConfirmLeave"})
    elseif mode=="demolish" then
        modalTitle.Text="건물을 철거할까요?";local id=selectedUnit and selectedUnit.id
        Menu.confirm(modalBody,W,selectedUnit and selectedUnit.kind=="City" and "30초 뒤 철거  환불 없음  병력 상한 줄어듦" or "30초 뒤 철거  환불 없음","취소",closeModal,"철거",function() if id then send("delete",id) end;closeModal() end,{"Cancel","ConfirmDelete"})
    elseif mode=='comrades'then
        modalTitle.Text='함께한 지휘관';local y=0
        modalLabel('Hint','같이 싸운 지휘관에게 친구 요청을 보내거나 파티로 초대해 다음 판도 함께해요.',0,40,C.muted,14);y=48
        for _,pl in ipairs(armsUI.comrades(state))do
            local friend=modalButton('Friend'..pl.UserId,pl.DisplayName..'님에게 친구 요청',y,function()pcall(function()game.StarterGui:SetCore('PromptSendFriendRequest',pl)end)end,true);friend.Size=UDim2.new(.6,-11,0,48);friend.TextWrapped=true
            local invite=modalButton('Party'..pl.UserId,'파티 초대',y,function()multiplayerLobby:request('invite',pl.UserId)end);invite.Position=UDim2.new(.6,-3,0,y);invite.Size=UDim2.new(.4,-11,0,48);y+=56
        end
        armsUI.resultActions.Visible=true;button(armsUI.resultActions,'Back','결과로 돌아가기',function()openModal('result')end,true)
        modalBody.CanvasSize=UDim2.fromOffset(0,y)
    elseif mode=="result" then
        armsUI.resultSeen=true
        local compact=screenSize().Y<500
        armsUI.resultCompact=compact
        armsUI.resultView=require(pack.Client.ResultView).new(modalBody,compact,function()openModal('recap')end,function()task.defer(layout)end)
        local view=armsUI.resultView:update(state,math.max(240,modalBody.AbsoluteSize.X/UI.scale))
        modalTitle.Text=view.title
        armsUI.resultActions.Visible=true
        local party=multiplayerLobby and multiplayerLobby.data and multiplayerLobby.data.party
        if not view.retryIntro and not view.nextStage and (state.casual or state.intro)and party and #party.users>1 and party.leader~=me.UserId then view.again='파티장과 함께 준비'end
        button(armsUI.resultActions,'Again',view.again,function()armsUI.veil.show('전장 준비 중…')
            local now=require(pack.Core.ResultPresentation).view(state)
            if now.retryIntro or now.nextStage then multiplayerLobby:request('again',nil,function()pauseOwned=false;modal.Visible=false;modalMode=nil end)
            elseif state.intro then multiplayerLobby.skipIntro=true;multiplayerLobby.pendingDeployment='quick';send('menu');pauseOwned=false;modal.Visible=false;modalMode=nil;multiplayerLobby:closePage()
            elseif state.casual then multiplayerLobby:request('play',nil,function()pauseOwned=false;modal.Visible=false;modalMode=nil end)
            elseif state.multiplayer then
                if state.queueMode=='custom'then multiplayerLobby.pendingCustom=state.customRules else multiplayerLobby.pendingDeployment=true end
                pauseOwned=false;modal.Visible=false;modalMode=nil;send('menu')
            else multiplayerLobby:request('again',nil,function()pauseOwned=false;modal.Visible=false;modalMode=nil end)end
        end,true)
        button(armsUI.resultActions,'ChooseMode','로비',function()
            armsUI.veil.show('로비로 이동 중…');local function menu()pauseOwned=false;modal.Visible=false;modalMode=nil;send('menu')end
            if multiplayerLobby and state.intro then multiplayerLobby.skipIntro=true end
            if multiplayerLobby then multiplayerLobby:leaveResult(menu)else menu()end
        end)
        if view.continuing then button(armsUI.resultActions,'Spectate','관전하기',function()closeModal()end)end
        if armsUI.comrades(state)[1]then button(armsUI.resultActions,'Comrades','함께한 지휘관',function()openModal('comrades')end)end
        local Invite=require(pack.Client.FriendInviteCard);Invite.open=function()if multiplayerLobby then multiplayerLobby:invite(nil,'result')end end
        Invite.button(button,armsUI.resultActions,state.personalResult)
        button(armsUI.resultActions,'Share','결과 공유',function()
            pcall(function()
                local capture=game:GetService('CaptureService')
                capture:CaptureScreenshot(function(content)
                    pcall(function()capture:PromptShareCapture(content,game:GetService('HttpService'):JSONEncode({party=me.UserId}),function()end,function()end)end)
                end)
            end)
        end)
    end
    armsUI.styleModal()
    layout()
end
armsUI.spectator=require(pack.Client.SpectatorBar).new(root,{result=function()openModal('result')end,watch=function(id)send('watch',id)end,leave=function()send('menu')end,speed=function(v)send('replaySpeed',v)end,focus=function(tile,force)if force or renderer.targetTile~=nil then renderer:focusAt(tile,true)end end})
local function getUnit(tile,pos)
    if not tile or not currentMap or not state then return nil end
    if pos then
        local id=structureIcons:hit((pos-map.AbsolutePosition)/UI.scale,armsUI.input.touch())
        if id then for _,u in ipairs(state.units or {})do if u.id==id then return u end end end
    end
    local best,dist=nil,math.huge
    for _,u in ipairs(state.units or {}) do
        if pos then
            local localPos=(pos-map.AbsolutePosition)/UI.scale
            local projected=renderer:project(u.tile,2)
            local pixels=(projected-localPos).Magnitude
            if pixels<(armsUI.input.touch() and 26 or 18) and pixels<dist then best=u;dist=pixels end
        end
        local dx,dy=u.tile%currentMap.meta.width-tile%currentMap.meta.width,math.floor(u.tile/currentMap.meta.width)-math.floor(tile/currentMap.meta.width)
        local d=dx*dx+dy*dy;local radius=math.clamp(renderer.view.w/math.max((map.AbsoluteSize/UI.scale).X,1)*22,2,12)
        if not pos and d<radius*radius and d<dist then best=u;dist=d end
    end
    return best
end
local function terrainInfo(tile)
    if not tile or not currentMap then return nil end
    local b=buffer.readu8(currentMap.terrain,tile);local kind=Terrain.terrainType(b)
    return {kind=kind,name=({[0]="평지",[1]="고지대",[2]="산악",[3]="바다",[4]="통과 불가"})[kind],land=Terrain.isLand(b) and not Terrain.isImpassable(b),owned=owners[tile]==1,owner=owners[tile] or 0}
end
local function queryPreview()
    previewSerial+=1
    if armsUI.ghostMode()then if selectedTile then armsUI.ghostQuery(selectedTile)end;return end
    if not selectedTile or not table.find(armsUI.rules.buildable,action) or not state then preview=nil;return end
    local serial=previewSerial;local tile,kind,version=selectedTile,action,state.version;preview=nil
    task.delay(.12,function()
        if serial~=previewSerial then return end
        local ok,r=pcall(function() return previewRemote:InvokeServer(kind,tile,version) end)
        if serial~=previewSerial or selectedTile~=tile or action~=kind or not state or state.version~=version then return end
        preview=ok and r or {valid=false,reason="위치 확인 실패"}
        refreshSheet();refreshMarkers()
    end)
end
armsUI.ghostMode=function()
    return not armsUI.input.touch() and sheetMode=="placement" and table.find(armsUI.rules.buildable,action)~=nil and not armsUI.rules.nukes[action]
end
armsUI.ghostQuery=function(tile)
    armsUI.ghostWant=tile
    if armsUI.ghostBusy then return end;armsUI.ghostBusy=true
    task.spawn(function()
        local retries=0
        while true do
            local wait=.1-(os.clock()-(armsUI.ghostAt or 0));if wait>0 then task.wait(wait)end
            local t=armsUI.ghostWant;armsUI.ghostWant=nil
            if not t or not state or not armsUI.ghostMode()then break end
            local kind,version=action,state.version;armsUI.ghostAt=os.clock()
            local ok,r=pcall(function()return previewRemote:InvokeServer(kind,t,version)end)
            if ok and type(r)=="table"and not r.valid and (r.retry or r.reason=="위치 확인 필요")and retries<3 then
                retries+=1;if armsUI.ghostWant==nil then armsUI.ghostWant=t end;continue
            end
            retries=0
            if armsUI.ghostMode()and action==kind and selectedTile==t then
                preview=ok and r or {valid=false,reason="위치 확인 실패"};armsUI.previewTile=t;armsUI.ghostLast=preview
                refreshSheet();refreshMarkers()
            elseif ok and type(r)=="table"and action==kind then armsUI.nuclear:railHint(kind,r) end
        end
        armsUI.ghostBusy=false
    end)
end
armsUI.ghostHover=function(tile)
    hover.Visible=false
    if not tile or tile==selectedTile then return end
    selectedTile=tile;armsUI.previewTile=nil
    preview=require(pack.Client.BuildSnap).guess(action,tile,state,owners,currentMap,armsUI.rules,terrainInfo(tile),affordable)
    armsUI.ghostQuery(tile);refreshMarkers()
end
armsUI.ghostClick=function(tile,secondary)
    if not armsUI.ghostMode()then return false end
    local kind=action
    local function leave()action="inspect";sheetMode=nil;selectedTile=nil;preview=nil;previewSerial+=1;armsUI.ghostWant=nil;armsUI.ghostLast=nil;refreshContext()end
    if secondary or not tile then leave();return true end
    if armsUI.previewTile==tile and preview and not preview.guess and not preview.valid then
        armsUI.audio.play("error");notify(preview.reason or "건설 불가",true);leave();return true
    end
    if refuseCost(kind)then leave();return true end
    send("build",kind,tile);if armsUI.shiftHeld()then armsUI.ghostLast=nil;return true end;leave();return true
end
armsUI.queryContext=function()
    armsUI.contextSerial=(armsUI.contextSerial or 0)+1;local serial=armsUI.contextSerial
    armsUI.context=nil;armsUI.buildables=nil
    if not state or state.phase~="playing" or not selectedTile or sheetMode~="tile" then return end
    local tile,version=selectedTile,state.version;local G=require(pack.Client.ContextGuess)
    if owners[tile]==1 then
        armsUI.buildables=G.buildables(state,tile,owners,currentMap,armsUI.rules,armsUI.interaction.ringKinds)
        task.spawn(function()
            for _=1,3 do
                local ok,r=pcall(function()return previewRemote:InvokeServer("buildables",tile,version)end)
                if serial~=armsUI.contextSerial or selectedTile~=tile or sheetMode~="tile" then return end
                if ok and type(r)=="table"and r.City then armsUI.buildables=r;refreshSheet();return end
                task.wait(.1)
            end
        end)
        return
    end
    armsUI.context=G.context(state,tile,owners[tile],terrainInfo(tile),armsUI.rules)
    task.spawn(function()
        if serial~=armsUI.contextSerial then return end
        local ok,r=pcall(function()return previewRemote:InvokeServer("context",tile,version)end)
        if serial~=armsUI.contextSerial or selectedTile~=tile or not state or state.version~=version or sheetMode~="tile" then return end
        if ok and r.attack~=nil then armsUI.context=r;G.remember(owners[tile],r)end;refreshSheet()
    end)
end
refreshMarkers=function()armsUI.markersWanted=true end
armsUI.drawMarkers=function()
    armsUI.markersWanted=false
    if not currentMap or not state or state.phase=="menu" then return end
    renderer.readabilityUnit=selectedUnit and selectedUnit.id or hoveredUnit
    armsUI.nuclear.action=action;armsUI.nuclear.preview=preview;armsUI.nuclear.selected=selectedUnit;armsUI.nuclear.hovered=hoveredUnit
    local P=armsUI.probe;P.start('M.nuclear');armsUI.nuclear:draw();P.stop('M.nuclear');P.start('M.structures')
    local okIcons,iconError=pcall(structureIcons.update,structureIcons,qaStructures and {units=qaStructures,tick=state.tick,factions=state.factions} or state,renderer,map.AbsoluteSize/UI.scale,armsUI.factionKinds or {},Color3.fromRGB(table.unpack(CosmeticCatalog.get(state.style).territory)),state.phase=="spawn",selectedUnit and selectedUnit.id)
    if not okIcons and armsUI.iconError~=iconError then armsUI.iconError=iconError;warn('StructureIcons: '..tostring(iconError))end
    P.stop('M.structures')
    local p=state.player;nameTag.Visible=p.labelTile~=nil;armsUI.identityLeader.Visible=false
    if p.labelTile then
        local NL=armsUI.nameLayer;local lx,ly,ls=NL.follow(NL.motion,'own',p.labelTile,p.labelSize,renderer.map.meta.width,os.clock(),effects.reduced)
        local pos=renderer:projectXY(lx,ly);local anchor=pos;local size=map.AbsoluteSize/UI.scale
        local bounds=armsUI.worldOverlay.bounds or {left=0,top=0,right=size.X,bottom=size.Y}
        nameTag.Visible=pos.X>=bounds.left and pos.Y>=bounds.top and pos.X<=bounds.right and pos.Y<=bounds.bottom
        if armsUI.identitySource~=p then
            armsUI.identitySource=p;armsUI.ownIdentity=table.clone(p)
            local watched=state.observer and factions[1]
            if state.observer then armsUI.ownIdentity.userId=watched and watched.userId;armsUI.ownIdentity.name=watched and watched.name or p.name
            else armsUI.ownIdentity.userId=me.UserId;armsUI.ownIdentity.name=me.DisplayName end
        end
        local identity=armsUI.ownIdentity
        local font=math.clamp(NL.font(ls,size.X/(renderer.liveW or renderer.view.w)),armsUI.input.touch()and 16 or 18,NL.MAX_FONT)
        local plateKey=armsUI.ownPlate or {};armsUI.ownPlate=plateKey;font=math.floor(font+.5)
        if plateKey.identity~=identity or plateKey.font~=font or plateKey.width~=size.X or plateKey.style~=state.style then
            plateKey.identity=identity;plateKey.font=font;plateKey.width=size.X;plateKey.style=state.style
            FactionBadge.plate(nameTag,identity,Color3.fromRGB(table.unpack(CosmeticCatalog.get(state.style).territory)),font,size.X)
        end
        local x,y=pos.X,pos.Y
        nameTag.Position=UDim2.fromOffset(x,y)
        if plateKey.troops~=p.troops then plateKey.troops=p.troops;nameTag:SetAttribute('OwnTerritory',true);nameTag:SetAttribute('Troops',p.troops)end
        local center=Vector2.new(x,y);local delta=center-anchor
        local outside=math.max(math.abs(delta.X)/(nameTag.Size.X.Offset/2),math.abs(delta.Y)/(nameTag.Size.Y.Offset/2))
        if nameTag.Visible and outside>1.3 then
            local finish=center-delta/outside;local line=finish-anchor
            if line.Magnitude>12 then
                local leader=armsUI.identityLeader;leader.Visible=true;leader.Position=UDim2.fromOffset((anchor.X+finish.X)/2,(anchor.Y+finish.Y)/2)
                leader.Size=UDim2.fromOffset(line.Magnitude,1);leader.Rotation=math.deg(math.atan2(line.Y,line.X))
            end
        end
    end
    commanders:setOwnTerritoryVisible(nameTag.Visible)
    local display=require(pack.Core.MapPresentation);local occupied=display.occupancy(64,armsUI.labelGrid);armsUI.labelGrid=occupied;local markerCount=0
    if nameTag.Visible then display.reserve(occupied,nameTag.Position.X.Offset,nameTag.Position.Y.Offset,nameTag.Size.X.Offset,nameTag.Size.Y.Offset,6)end
    local selectedOwner=selectedTile and owners[selectedTile]
    if armsUI.labelSource~=sortedFactions or armsUI.labelSelection~=selectedOwner then
        armsUI.labelSource=sortedFactions;armsUI.labelSelection=selectedOwner
        armsUI.orderedLabels=table.clone(sortedFactions)
        table.sort(armsUI.orderedLabels,function(a,b)return display.labelPriority(a,b,selectedOwner)end)
    end
    local viewport=map.AbsoluteSize/UI.scale;local mouse=nil
    if not armsUI.input.touch() then mouse=(UIS:GetMouseLocation()-game:GetService('GuiService'):GetGuiInset()-map.AbsolutePosition)/UI.scale end
    battle.frontBlocks={}
    if nameTag.Visible then local pos=(nameTag.AbsolutePosition-gamePanel.AbsolutePosition)/UI.scale;local size=nameTag.AbsoluteSize/UI.scale
        table.insert(battle.frontBlocks,{x=pos.X+size.X/2,y=pos.Y+size.Y/2,w=size.X,h=size.Y})end
    P.start('M.names');armsUI.nameLayer:update({factions=armsUI.orderedLabels,viewport=viewport,bounds=armsUI.worldOverlay.bounds,pixelsPerTile=viewport.X/(renderer.liveW or renderer.view.w),projectXY=function(x,y)return renderer:projectXY(x,y)end,mapWidth=renderer.map.meta.width,reduced=effects.reduced,selected=selectedOwner,occupied=occupied,mouse=mouse,blocks=battle.frontBlocks,tick=state.tick,pick=armsUI.drop.active});P.stop('M.names')
    selection.Visible=selectedTile~=nil
    if selectedTile then local p2=renderer:project(selectedTile);selection.Position=UDim2.fromOffset(p2.X,p2.Y) end
    placement.Visible=preview~=nil and preview.tile~=nil and (armsUI.rules.structures[action]==true)
    if placement.Visible then local p2=renderer:project(preview.tile);placement.Position=UDim2.fromOffset(p2.X,p2.Y);placementStroke.Color=preview.valid and C.accent or C.danger;placement.BackgroundColor3=placementStroke.Color end
    local defenseTile=(action=="DefensePost" and preview and preview.tile) or (selectedUnit and selectedUnit.kind=="DefensePost" and selectedUnit.tile)
    range.Visible=defenseTile~=nil and defenseTile~=false
    if range.Visible then local p2=renderer:project(defenseTile);range.Position=UDim2.fromOffset(p2.X,p2.Y);range.Size=UDim2.fromOffset(60/renderer.view.w*(map.AbsoluteSize/UI.scale).X,60/renderer.view.h*(map.AbsoluteSize/UI.scale).Y) end
    renderer:setPlacement(preview,action,defenseTile or nil);range.Visible=false;placement.Visible=false
    do local tip=armsUI.ghostTip;tip.Visible=armsUI.ghostMode()and preview~=nil and preview.tile~=nil
        if tip.Visible then
            local p2=renderer:project(preview.tile);tip.Position=UDim2.fromOffset(p2.X+16,p2.Y+12)
            local cost=state.costs[action]or "0";local rich=affordable(cost)
            armsUI.ghostCost.Text=(armsUI.rules.names[action]or action)..(preview.upgrade and " 업그레이드"or "").."  "..UI.number(cost);armsUI.ghostCost.TextColor3=rich and C.gold or C.danger
            armsUI.ghostReason.Text=not preview.valid and preview.reason or "";armsUI.ghostReason.Visible=armsUI.ghostReason.Text~=""
        end
    end
    for _,m in pairs(unitMarkers) do m.root.Visible=false end
    for _,u in ipairs(state.units or {}) do
        local wanted=sheetMode~="unit" and ((selectedUnit~=nil and selectedUnit.id==u.id) or hoveredUnit==u.id and not hoverCard.ships[u.kind])
        if not wanted then continue end
        local m=unitMarkers[u.id]
        if not m then
            local f=UI.panel(markerLayer,"Unit"..u.id);f.Size=UDim2.fromOffset(80,26);f.AnchorPoint=Vector2.new(.5,1);UI.stroke(f,C.gold)
            local text=label(f,"Name","",13,C.gold);text.Position=UDim2.fromOffset(8,0);text.Size=UDim2.new(1,-16,0,20);text.TextXAlignment=Enum.TextXAlignment.Center;text.TextTruncate=Enum.TextTruncate.None;text.TextWrapped=false
            local track=make("Frame",f,{Name="ProgressTrack",Position=UDim2.new(0,8,0,19),Size=UDim2.new(1,-16,0,3),BackgroundColor3=C.line,BorderSizePixel=0})
            local fill=make("Frame",track,{Name="Progress",Size=UDim2.fromScale(1,1),BackgroundColor3=C.gold,BorderSizePixel=0})
            m={root=f,text=text,track=track,fill=fill};unitMarkers[u.id]=m
        end
        local pp=renderer:project(u.tile,(structureIcons.roofHeight[u.kind] or 3.6)+1.1);m.root.Position=UDim2.fromOffset(pp.X,pp.Y)
        m.root.Visible=true
        m.text.Text=(armsUI.rules.names[u.kind] or u.kind)..(u.troops and " "..UI.troops(u.troops) or u.health and " "..u.health or " "..u.level)
        m.track.Visible=u.building or u.deleteAt~=nil
        if u.deleteAt then m.text.Text="철거 "..math.max(0,math.ceil((u.deleteAt-state.tick)/10)).."초";m.fill.BackgroundColor3=C.danger;m.fill.Size=UDim2.fromScale(math.clamp((u.deleteAt-state.tick)/300,0,1),1)
        elseif u.building then m.text.Text..=" 건설";m.fill.BackgroundColor3=C.gold;m.fill.Size=UDim2.fromScale(math.clamp(1-(u.remaining or 0)/math.max(1,u.duration or 1),0,1),1) end
        if not u.building and not u.deleteAt and u.readyMissiles~=nil then m.text.Text=(u.kind=='MissileSilo'and '사일로'or '방공')..' '..u.readyMissiles..'/'..u.level;m.track.Visible=true;m.fill.BackgroundColor3=C.accent;m.fill.Size=UDim2.fromScale(u.readyMissiles/math.max(1,u.level),1)end
        if u.health and u.maxHealth then m.track.Visible=true;m.fill.BackgroundColor3=u.health<u.maxHealth and C.danger or C.accent;m.fill.Size=UDim2.fromScale(math.clamp(u.health/math.max(1,u.maxHealth),0,1),1)end
        if not m.track.Visible and not(selectedUnit~=nil and selectedUnit.id==u.id)then m.root.Visible=false;continue end
        local tw=game:GetService("TextService"):GetTextSize(m.text.Text,13,m.text.Font,Vector2.new(400,40)).X
        m.root.Size=UDim2.fromOffset(math.max(64,math.ceil(tw)+20),m.track.Visible and 26 or 22)
    end
end
refreshSheet=function()
    armsUI.telemetry.flow(sheetMode and 'opened'or 'closed',action)
    if not state or state.phase=="menu" then sheet.Visible=false;return end
    if not sheetMode and sheet.Visible then armsUI.ring20:close()end
    sheet.Visible=sheetMode~=nil;sheet:SetAttribute('Ring20',nil)
    for _,b in ipairs({cityButton,postButton,confirmButton,demolishButton,allianceButton,contextBuild,supportGold,supportTroops,armsUI.transport,armsUI.rockets,armsUI.detail,armsUI.signal,armsUI.emoji,armsUI.upgradeMax}) do b.Visible=false end
    for _,b in pairs(armsUI.ring)do b.Visible=false end
    armsUI.dock:update(state,action)
    local dockHelp=armsUI.dockHover and sheetMode==nil and not armsUI.nuclear.active
    renderer:highlightKind(dockHelp and armsUI.rules.structures[armsUI.dockHover] and armsUI.dockHover or nil)
    if armsUI.dock.bar then dockHelp=false end
    armsUI.modeBar.Visible=dockHelp~=nil and dockHelp~=false or sheetMode=="placement" or action=="moveWarship" or sheetMode=="unit" and selectedUnit~=nil
    armsUI.modeCancel.Visible=not dockHelp
    local fleet=0;if action=="moveWarship"then for _,u in ipairs(state.units or {})do if u.kind=="Warship"and (u.owner or 1)==1 and not u.building then fleet+=1 end end end
    armsUI.modeAll.Visible=action=="moveWarship"and fleet>1 and type(armsUI.moving)~="table"
    do local bw,allWidth=armsUI.modeBar.Size.X.Offset,armsUI.modeAll.Visible and 84 or 0
        box(armsUI.modeTitle,8,0,bw-62-allWidth,21);box(armsUI.modeHint,8,21,bw-62-allWidth,23);box(armsUI.modeAll,bw-48-allWidth,0,80,44) end
    armsUI.dock.frame.Visible=true
    if armsUI.modeBar.Visible then
        armsUI.modeTitle.Text=(action=="moveWarship"and type(armsUI.moving)=="table"and string.format("군함 %d척 이동",#armsUI.moving)or armsUI.rules.names[action] or "군함 이동")..(state.costs[action] and "  "..UI.number(state.costs[action]).." 골드" or "")
        armsUI.modeHint.Text=armsUI.ghostMode()and (preview and not preview.valid and preview.reason or "건설 위치  Shift 연속  X 취소") or preview and (preview.valid and "● 눌러 확정" or preview.reason) or (selectedTile and sheetMode=="placement" and "배치 조건 확인 중…" or action=="moveWarship" and "바다 선택" or armsUI.rules.nukes[action] and "목표 선택" or action=="Warship" and "항구 옆 바다 선택" or "내 땅 선택")
        armsUI.modeHint.TextColor3=preview and not preview.valid and C.danger or C.muted
        if sheetMode=="unit" and selectedUnit then
            local u=selectedUnit;armsUI.modeTitle.Text=(armsUI.rules.names[u.kind] or u.kind).." 레벨 "..u.level
            armsUI.modeHint.Text=u.building and ("건설 중 "..math.ceil((u.remaining or 0)/10).."초 남음") or armsUI.rules.describe(u,state.costs,UI.number,UI.troops):match("^[^\n]+") or ""
        end
        if dockHelp then
            local kind=armsUI.dockHover;local index=table.find(armsUI.rules.buildable,kind)
            armsUI.modeTitle.Text='['..tostring(index%10)..'] '..armsUI.rules.names[kind]..': '..UI.number(state.costs[kind]or 0)
            armsUI.modeHint.Text=armsUI.commands.hint(state,kind);armsUI.modeHint.TextColor3=armsUI.commands.prerequisite(state,kind)and C.danger or C.muted
        end
    end
    confirmButton.BackgroundColor3=C.accent;armsUI.confirmDanger=false
    if armsUI.refreshGuide then armsUI.refreshGuide()end
    if not sheetMode then if layout then layout() end;return end
    local info=terrainInfo(selectedTile)
    if armsUI.context and info and state.attackTargets then armsUI.context.attack=state.attackTargets[tostring(info.owner)]==true end
    armsUI.attackRoute=sheetMode=='tile' and armsUI.context and armsUI.context.attackRoute or nil
    if sheetMode=="build" then
        sheetTitle.Text="영토를 성장시키세요";sheetDetail.Text="건물 선택 → 내 땅 선택 → 건설"
        cityButton.Visible=true;postButton.Visible=true
        cityButton.Text="도시"..(armsUI.input.touch() and "" or " [C]").."   "..UI.number(state.costs.City).." 골드\n병력 상한 +25,000 / 레벨"
        postButton.Text="요새"..(armsUI.input.touch() and "" or " [V]").."   "..UI.number(state.costs.DefensePost).." 골드\n반경 30칸의 방어 강화"
        UI.enabled(cityButton,state.phase=="playing");UI.enabled(postButton,state.phase=="playing")
    elseif sheetMode=="placement" then
        sheet.Visible=selectedTile~=nil and preview~=nil and preview.valid==true and not armsUI.ghostMode()
        sheetTitle.Text=(armsUI.rules.names[action] or "군함 이동")
        local price=state.costs[action] or "0"
        sheetDetail.Text="비용 "..UI.number(price).." 골드\n"..(preview and preview.reason or armsUI.rules.nukes[action] and "목표 선택" or action=="Warship" and "항구 옆 바다 선택" or "내 땅 선택")
        confirmButton.Visible=true;confirmButton.Text=(armsUI.rules.nukes[action] and "발사" or "건설").."\n"..UI.number(price);UI.enabled(confirmButton,preview~=nil and preview.valid and affordable(price) and not state.paused)
    elseif sheetMode=="unit" and selectedUnit then
        local u=selectedUnit;sheetTitle.Text=(armsUI.rules.names[u.kind] or u.kind).." 레벨 "..u.level
        if u.deleteAt then sheetDetail.Text="철거까지 "..math.max(0,math.ceil((u.deleteAt-state.tick)/10)).."초  환불 없음"
        elseif u.building then sheetDetail.Text="건설 중 약 "..string.format("%.1f",((u.remaining or 0)+1)/10).."초"
        else
            sheetDetail.Text=armsUI.rules.describe(u,state.costs,UI.number,UI.troops)
            if armsUI.rules.upgradable[u.kind] and (u.owner or 1)==1 then confirmButton.Visible=true;confirmButton.Text="강화";UI.enabled(confirmButton,affordable(state.costs[u.kind]) and not state.paused)
                armsUI.upgradeMax.Visible=true;UI.enabled(armsUI.upgradeMax,affordable(state.costs[u.kind]) and not state.paused)
            elseif u.kind=="Warship" or u.kind=="TransportShip" then confirmButton.Visible=true;confirmButton.Text=u.kind=="Warship" and "이동" or "복귀";UI.enabled(confirmButton,not state.paused and not u.retreating) end
            demolishButton.Visible=(u.owner or 1)==1 and armsUI.rules.structures[u.kind]==true;demolishButton.Text=(state.deleteAvailableIn or 0)>0 and "철거 "..math.ceil(state.deleteAvailableIn).."초 후" or "철거"
            UI.enabled(demolishButton,(state.deleteAvailableIn or 0)<=0 and not state.paused)
            if u.owner==1 and u.kind=="Port" then contextBuild.Visible=true;contextBuild.Text="군함" end
            if u.owner==1 and u.kind=="MissileSilo" then armsUI.rockets.Visible=true end
        end
    elseif sheetMode=="tile" then
        if state.phase=="spawn" then
            sheetTitle.Text="시작 위치 선택"
            local movable=state.spawned and state.multiplayer and not state.randomSpawn
            sheetDetail.Text=info and (info.land and info.name or "시작 불가 지형") or "육지 선택"
            confirmButton.Visible=true;confirmButton.Text=movable and "여기로 옮기기" or state.spawned and "준비 완료" or "정착";UI.enabled(confirmButton,info~=nil and info.land and (not state.spawned or movable))
        elseif info and info.owned then
            local p=state.player;sheetTitle.Text=p.name.."의 영토"
            sheetDetail.Text=string.format("병력 %s / %s\n골드 %s",UI.troops(p.troops),UI.troops(p.cap),UI.number(p.gold))
            sheetDetail.Text="건물을 선택하면 이 위치의 건설 조건을 확인해요."
            for _,kind in ipairs(armsUI.interaction.ringKinds)do
                local b=armsUI.ring[kind];b.Visible=not armsUI.rules.disabled(state.settings,kind);b.Text=UI.number(state.costs[kind]or 0)
            end
        elseif info and info.land and info.owner~=0 then
            local f=factions[info.owner]
            sheetTitle.Text=f and f.name or "다른 세력"
            sheetDetail.Text=f and string.format("병력 %s  골드 %s\n영토 %.2f%%%s",UI.troops(f.troops),UI.number(f.gold),f.share*100,f.traitor and "  배신자" or "") or ""
            confirmButton.Visible=f~=nil and not f.allied and armsUI.context and (armsUI.context.attack or armsUI.context.transport and armsUI.attackRoute=='transport')==true or false;confirmButton.Text='공격';UI.enabled(confirmButton,f~=nil and not state.paused)
            armsUI.detail.Visible=f~=nil;armsUI.signal.Visible=f~=nil;armsUI.emoji.Visible=false
            if f and f.allied then
                confirmButton.Visible=false
                allianceButton.Visible=true;allianceButton:SetAttribute('Breaking',true);allianceButton.Text='동맹 파기';UI.enabled(allianceButton,not state.paused)
                supportGold.Visible=true;supportTroops.Visible=true
                local wait=f.donationAvailableIn or 0
                local gold=state.diplomacy and state.diplomacy.defaultGold or "0"
                local troops=math.min(state.diplomacy and state.diplomacy.defaultTroops or 0,math.max(0,f.cap-f.troops))
                supportGold.Text=wait>0 and ("골드 지원\n"..math.ceil(wait).."초") or ("골드 지원\n"..UI.number(gold))
                supportTroops.Text=wait>0 and ("병력 지원\n"..math.ceil(wait).."초") or ("병력 지원\n"..UI.troops(troops))
                UI.enabled(supportGold,f.canDonateGold and tonumber(gold)>0 and not state.paused)
                UI.enabled(supportTroops,f.canDonateTroops and troops>=1 and not state.paused)
            else
                allianceButton.Visible=not state.settings.disableAlliances and state.settings.customAllianceDuration~=0;allianceButton:SetAttribute('Breaking',false);allianceButton.Text=f and (f.incomingRequest and "동맹 수락" or f.requested and "응답 대기" or "동맹 요청") or "동맹 요청"
                UI.enabled(allianceButton,f~=nil and not f.requested and not state.paused)
            end
        elseif info and info.land then
            sheetTitle.Text="중립 영토 "..info.name
            sheetDetail.Text="보낼 병력 "..UI.troops(state.player.troops*fraction).."\n국경 전체에서 주변 중립 땅으로 확장"
            confirmButton.Visible=armsUI.context~=nil and armsUI.context.attack==true;confirmButton.Text="공격";UI.enabled(confirmButton,not state.paused)
        elseif info and action=="moveWarship" then confirmButton.Visible=true;confirmButton.Text="군함 이동";UI.enabled(confirmButton,not state.paused)
        elseif info and not info.land and (state.naval and (state.costs.Warship~=nil)) then
            if armsUI.context and armsUI.context.warship and not armsUI.rules.disabled(state.settings,"Warship")then
                local b=armsUI.ring.Warship;b.Visible=true;b.Text="군함\n"..UI.number(state.costs.Warship);UI.enabled(b,not state.paused)
            end
        end
        if state.phase=="playing" and info and info.land and info.owner~=1 and armsUI.context then
            local full=armsUI.context.transportFull==true;armsUI.transport.Visible=armsUI.context.transport==true or full;armsUI.transport.Text="수송\n"..(full and"3/3"or UI.troops(math.floor(state.player.troops*fraction)));UI.enabled(armsUI.transport,not state.paused and not full);armsUI.transport.Active=not state.paused
            armsUI.rockets.Visible=armsUI.context.rockets==true
            local f=factions[info.owner];if f or info.owner==0 then armsUI.ring20:fill(state,f,armsUI.context,armsUI.attackRoute)end
        end
    end
    if state.phase=='lost'or state.phase=='won'then
        for _,b in ipairs({cityButton,postButton,confirmButton,demolishButton,allianceButton,contextBuild,supportGold,supportTroops,armsUI.transport,armsUI.rockets,armsUI.signal,armsUI.emoji,armsUI.upgradeMax})do b.Visible=false end
        for _,b in pairs(armsUI.ring)do b.Visible=false end
    end
    local actionable=false
    for _,b in ipairs({cityButton,postButton,confirmButton,demolishButton,allianceButton,contextBuild,supportGold,supportTroops,armsUI.transport,armsUI.rockets,armsUI.detail,armsUI.signal,armsUI.emoji,armsUI.upgradeMax}) do if b.Visible then actionable=true;break end end
    if not actionable then for _,b in pairs(armsUI.ring)do if b.Visible then actionable=true;break end end end
    if (sheetMode=="tile"or sheetMode=="unit")and not actionable then sheet.Visible=false end
    refreshAttackAmount()
    local name=sheetMode=='placement'and 'build'or sheetMode=='unit'and selectedUnit and selectedUnit.kind~='Warship'and (selectedUnit.kind=='TransportShip'and 'cancelTransport'or 'upgrade')or state.phase=='spawn'and 'spawn'or action=='moveWarship'and 'moveWarship'
    if name and pending[name]and confirmButton.Visible and(name~='build'or armsUI.keys and armsUI.keys['build:'..tostring(action)..':'..tostring(selectedTile)])then confirmButton.Text='요청 중…';UI.enabled(confirmButton,false)end
    if layout then layout() end
end
refreshContext=function()
    if not state or state.phase=="menu" then return end
    updateDispatch()
    if table.find(armsUI.rules.buildable,action) then queryPreview() end
    refreshSheet();refreshMarkers()
end
inbox.showDeferred=function()
    armsUI.nuclear:stop();selectionRevision+=1;armsUI.lastTap=nil
    action='inspect';sheetMode=nil;selectedTile=nil;selectedUnit=nil;preview=nil;previewSerial+=1;hover.Visible=false;refreshContext()
end
local function selectTile(tile,pos,secondary)
    if armsUI.drop.active then if not secondary then armsUI.drop:pick(tile,tile and owners[tile])end;return end
    if armsUI.nuclear.active then armsUI.nuclear:click(tile,secondary);return end
    armsUI.sheets:outside()
    if armsUI.ghostClick(tile,secondary)then return end
    if not armsUI.input.touch()and(armsUI.closeRadial()or secondary and action=="moveWarship"and armsUI.moving)then armsUI.telemetry.step('match','menuClosed',{result=secondary and'right'or'left',item=armsUI.moving and'move'or'ring'});armsUI.moving=nil;action="inspect";refreshContext();return end
    if pos and not secondary and not sheet.Visible and action=="inspect"and not armsUI.input.touch()and not getUnit(tile,pos)and require(pack.Client.ClickAttack).pick(state,terrainInfo(tile),factions[owners[tile]],owners[tile])then send("attack",fraction,tile);return end
    if not armsUI.input.touch()then require(pack.Client.RightClickStep).note(state,secondary)end
    if pos and action=="inspect"then local u=getUnit(tile,pos);if not(u and(u.owner or 1)==1)then tile=require(pack.Client.TapSnap).land(tile,(pos-map.AbsolutePosition)/UI.scale,currentMap,renderer,owners,armsUI.input.touch())or tile end end
    local last=armsUI.lastTap
    local target=factions[owners[tile]]
    local hitInfo=tile and terrainInfo(tile)
    local candidate={tile=tile,kind=hitInfo and hitInfo.kind,owner=owners[tile]or 0,allied=target and target.allied or false,unit=nil,mode=action,x=pos and pos.X,y=pos and pos.Y}
    local under=tile and getUnit(tile,pos);candidate.unit=under and under.id
    if last and sheet.Visible and sheetMode=="tile" and armsUI.primary and armsUI.primary.Visible and armsUI.primary.Active
        and armsUI.interaction.sameTarget(last,candidate) then
        armsUI.ring20:press(armsUI.primary,armsUI.primaryActions[armsUI.primary])
        if sheet.Visible then armsUI.radialPop(.9) end;return
    end
    local wasOpen=sheet.Visible
    selectionRevision+=1
    local info=tile and terrainInfo(tile)
    if not info or info.kind==4 then
        selectedTile=nil;selectedUnit=nil;hoveredTile=nil;hover.Visible=false;sheetMode=nil;action="inspect";preview=nil;previewSerial+=1
        gui:SetAttribute("SelectedTile",nil);refreshSheet();refreshMarkers();return
    end
    selectedUnit=if table.find(armsUI.rules.buildable,action) or action=="moveWarship" then nil else getUnit(tile,pos)
    if selectedUnit and(selectedUnit.owner or 1)~=1 and info.land then selectedUnit=nil end
    selectedTile=selectedUnit and selectedUnit.tile or tile;gui:SetAttribute("SelectedTile",selectedTile)
    local f=factions[owners[selectedTile]];armsUI.selectedRelation={owner=owners[selectedTile]or 0,allied=f and f.allied or false}
    if action=="moveWarship" and not info.land and armsUI.moving then
        send(type(armsUI.moving)=="table" and "moveWarships" or "moveWarship",armsUI.moving,tile);action="inspect";sheetMode=nil;armsUI.moving=nil;selectedUnit=nil;refreshContext();return
    end
    if table.find(armsUI.rules.buildable,action) then sheetMode="placement"
    elseif action=="moveWarship" then selectedUnit=nil;sheetMode="tile"
    else action="inspect";sheetMode=selectedUnit and (selectedUnit.owner or 1)==1 and "unit" or "tile" end
    armsUI.lastTap={tile=selectedTile,kind=terrainInfo(selectedTile).kind,owner=owners[selectedTile]or 0,allied=f and f.allied or false,unit=selectedUnit and selectedUnit.id,mode=action,x=pos and pos.X,y=pos and pos.Y}
    menuAnchor=pos and (pos-gamePanel.AbsolutePosition)/UI.scale or renderer:project(selectedTile);hoveredTile=selectedTile
    hover.Visible=false
    armsUI.queryContext()
    refreshContext()
    if wasOpen and sheet.Visible then armsUI.radialPop(.8) end
end
armsUI.qaTap=function(p) selectTile(renderer:tileAt(p),p) end
armsUI.qaSelectTile=function(t)local p=renderer:project(t);selectTile(t,p*UI.scale+map.AbsolutePosition)end
local function blocked(pos)
    if armsUI.motionWheel and armsUI.motionWheel.frame.Visible or require(pack.Client.MatchBubble).frame and not require(pack.Client.MatchBubble).passive then return true end
    for _,f in pairs({armsUI.motionShortcut,armsUI.cameraShortcut,pauseButton})do
        if f.Visible then local p,s=f.AbsolutePosition,f.AbsoluteSize;if pos.X>=p.X and pos.X<p.X+s.X and pos.Y>=p.Y and pos.Y<p.Y+s.Y then return true end end
    end
    local radial=sheetMode=="tile" or sheetMode=="unit" or sheetMode=="placement"
    if sheet.Visible and radial then for _,b in ipairs(sheet:GetChildren())do if b:IsA('TextButton')and b.Visible then
        local p,s=b.AbsolutePosition,b.AbsoluteSize;if pos.X>=p.X and pos.X<p.X+s.X and pos.Y>=p.Y and pos.Y<p.Y+s.Y then return true end
    end end end
    for _,f in ipairs({hud,controls,sheet,guide,operations,armsUI.orders.peek,armsUI.modeBar,inbox.panel,inbox.peek,battle.banner,armsUI.tactical.frame,armsUI.quick.frame,armsUI.chat.quickButton,armsUI.chat.emojiButton,armsUI.chat.frame,armsUI.chat.button,armsUI.chat.feed,armsUI.nuclear.bar,armsUI.nuclear.card,armsUI.ranks.frame,armsUI.eventLog.panel,armsUI.eventLog.button,armsUI.renewal.panel,armsUI.sheets.frame,armsUI.spectator.frame,armsUI.matchStatus.frame,armsUI.matchStatus.heads}) do
        if f.Visible and not(f==sheet and radial)then local p,s=f.AbsolutePosition,f.AbsoluteSize;if pos.X>=p.X and pos.X<p.X+s.X and pos.Y>=p.Y and pos.Y<p.Y+s.Y then return true end end
    end
    return modal.Visible
end
armsUI.mapInput={
    enabled=function() return gamePanel.Visible and not modal.Visible and not armsUI.drop.introActive end,
    blocked=blocked,changed=function() dirty=true;hover.Visible=false end,select=selectTile,
    wheel=function(z)if not armsUI.shiftHeld()then return false end;setFraction(armsUI.commandBar:wheel(fraction,z));return true end,
    hover=function(tile,pos)
        hoveredUnit=nil;armsUI.lastHover={tile,pos}
        if armsUI.drop.active or armsUI.input.touch() or not tile or not state then return end
        if blocked(pos) then if not sheet.Visible then hover.Visible=false end;return end
        if armsUI.nuclear.active then armsUI.nuclear:hover(tile);hover.Visible=false;return end
        if armsUI.ghostMode()then armsUI.ghostHover(tile);return end
        hoveredTile=tile
        local unit=getUnit(tile,pos);hoveredUnit=unit and unit.id or nil
        local p=unit and factions[unit.owner] or factions[owners[tile]]
        local size=gamePanel.AbsoluteSize/UI.scale
        if unit and hoverCard.ships[unit.kind] then if hoverCard:showShip(unit,p)and pos then local at=(pos-gamePanel.AbsolutePosition)/UI.scale;hoverCard:place(at.X,at.Y,size.X,size.Y)end;return end
        if hoverCard:show({state=state,faction=p,info=terrainInfo(tile),unit=unit,width=size.X-16,ownColor=Color3.fromRGB(table.unpack(CosmeticCatalog.get(state.style).territory))}) then
            hoverCard:dock(size.X,8)
        end
    end,
};renderer:bind(armsUI.mapInput)
positionSheet=function()
    if not sheet.Visible then return end
    local w,h=screenSize().X,screenSize().Y
    if sheetMode=="tile" or sheetMode=="unit" or sheetMode=="placement" then
        local point=menuAnchor or Vector2.new(w/2,h/2);local x,y=point.X,point.Y
        sheet.AnchorPoint=Vector2.new(.5,.5)
        sheet.Position=UDim2.fromOffset(x,y)
        armsUI.commandFeedback:layout(w,h,x)
        return
    end
    sheet.AnchorPoint=Vector2.zero
    local sw,sh=sheet.Size.X.Offset,sheet.Size.Y.Offset
    local bottom=controls.Visible and controls.Size.Y.Offset+12 or 0
    local point=selectedTile and renderer:project(selectedTile,selectedUnit and 2 or .1) or Vector2.new(w/2,h-bottom-12)
    local x,y=V.contextRect(w,h,point.X,point.Y,sw,sh,armsUI.input.touch(),bottom)
    if not selectedTile then x=(w-sw)/2 end
    sheet.Position=UDim2.fromOffset(x,y)
end
layout=function()
    local w,h=screenSize().X,screenSize().Y;if w<1 or h<1 then return end
    if multiplayerLobby then if multiplayerLobby.frame.Visible then multiplayerLobby:layout();armsUI.lobbyStale=false else armsUI.lobbyStale=true end end
    local l=V.layout(w,h);local m=l.margin
    armsUI.commandFeedback:layout(w,h)
    gui:SetAttribute("Layout",l.compact and "compact" or "wide")
    armsUI.coach:layout(screenSize())
    local touch=armsUI.input.touch()
    local small=l.compact or touch
    local dock=V.dockLayout(w,h,touch)
    armsUI.dock.bar=armsUI.commandBar:fits(w,touch,h)
    local fullX,fullW=dock.x,dock.width
    if touch and not armsUI.dock.bar and not armsUI.commandBar:phoneFits(w,h,touch)then local P=require(pack.Core.InterfacePlacement);dock=table.clone(dock);dock.width=math.floor(dock.width*P.TOUCH_WIDE/P.TOUCH_SCALE)end
    local mainX=dock.mainX or 0
    local narrowPhone=mainX>0 and dock.width-mainX<212
    local resourceLayout=require(pack.Core.RecruitmentPresentation).layout(dock.width-mainX+(narrowPhone and 44 or 0),touch)
    local cw,controlsX=dock.width,dock.x
    local shortPhone=touch and h<400
    local portrait=touch and mainX>0 and not shortPhone
    local portraitLayout=portrait and V.portraitHUD(cw,armsUI.paletteExpanded)or nil;armsUI.portraitGrid=portraitLayout and portraitLayout.grid
    armsUI.keepPalette=portrait or touch and not require(pack.Core.InterfacePlacement).phone(w,h,touch)
    armsUI.dock.compact=touch and not armsUI.paletteExpanded
    armsUI.dock.grid=portrait and armsUI.paletteExpanded
    local dockWidth=cw-mainX-16;local dockHeight=armsUI.dock:height(dockWidth,touch)
    local bottomHeight=shortPhone and armsUI.dock.compact and 96 or 8+resourceLayout.flowHeight+4+(touch and 44 or 36)+4+dockHeight+8
    if portraitLayout then bottomHeight=portraitLayout.height end
    box(controls,controlsX,h-bottomHeight-8,cw,bottomHeight)
    controls.Visible=state~=nil and state.phase~="menu"
    controls.BackgroundTransparency=.12
    controls:FindFirstChildOfClass('UIStroke').Enabled=not touch
    if not armsUI.dispatchSurface then armsUI.dispatchSurface=make('Frame',controls,{Name='DispatchSurface',BackgroundColor3=C.panel,BackgroundTransparency=.12,BorderSizePixel=0,ZIndex=0});UI.corner(armsUI.dispatchSurface,3)end
    armsUI.dispatchSurface.Visible=false
    hudBrand.Visible=false;statsLand.Visible=false;statsGoldSub.Visible=false;statsTroopsSub.Visible=true;selectedInfo.Visible=false;helpButton.Visible=false
    quickCity.Visible=false;quickPost.Visible=false;rankButton.Visible=false;timerText.Visible=false
    local dockY=bottomHeight-dockHeight-8
    local rowTop=shortPhone and armsUI.dock.compact and not resourceLayout.stacked and 2 or 8
    if shortPhone and armsUI.dock.compact then dockY=rowTop+resourceLayout.flowHeight+4 end
    armsUI.dock:layout(mainX+8,dockY,dockWidth,touch)
    pauseButton.Parent=controls;box(pauseButton,cw-52,8,44,44);pauseButton.TextSize=22
    if narrowPhone then pauseButton.Parent=gamePanel;box(pauseButton,w-52,8,44,44)end
    local resources=resourceLayout
    box(hud,8+mainX,rowTop,cw-mainX-64,resources.height)
    box(armsUI.growthBadge,resources.growth.x,resources.growth.y,resources.growth.w,resources.growth.h)
    box(armsUI.growthFace,0,6,resources.growth.w,32)
    if touch and resources.plate then
    elseif touch then
        box(armsUI.growthFace,0,4,resources.growth.w,24)
        box(armsUI.growthIcon,2,10,12,12);box(armsUI.growthArrow,14,2,10,28)
        box(statsTroopsSub,24,2,resources.growth.w-25,28)
    elseif resources.stacked then
        box(armsUI.growthArrow,4,3,18,20);box(armsUI.growthIcon,6,24,14,14)
        box(statsTroopsSub,24,6,resources.growth.w-28,32)
    else
        box(armsUI.growthIcon,5,13,18,18);box(armsUI.growthArrow,26,6,14,32)
        box(statsTroopsSub,44,6,resources.growth.w-48,32)
    end
    statsTroopsSub.TextSize=touch and 16 or 18;statsTroopsSub.TextXAlignment=Enum.TextXAlignment.Center
    local tr=resources.troops
    box(troopBar,tr.x,tr.y,tr.w,tr.h);troopIcon.Visible=false
    box(armsUI.troopWatermark,3,1,30,30);box(armsUI.filledWatermark,3,1,30,30)
    for _,number in ipairs({statsTroops,armsUI.filledTroops})do
        box(number,4,0,tr.w-8,tr.h);number.TextSize=touch and 16 or 18;number.TextWrapped=false;number.BackgroundTransparency=1;number.TextXAlignment=Enum.TextXAlignment.Center;number.Font=Enum.Font.BuilderSansBold
    end
    local gr=resources.gold
    goldIcon.Visible=not resources.stacked and not touch
    box(goldIcon,gr.x,13,18,18);box(statsGold,gr.x+(goldIcon.Visible and 20 or 0),0,gr.w-(goldIcon.Visible and 20 or 0),44)
    statsGold.TextSize=touch and 13 or 14;statsGold.TextWrapped=false;statsGold.TextXAlignment=Enum.TextXAlignment.Center
    armsUI.commandBar:touchPlates(touch and resources.plate and resources)
    local dispatchY=rowTop+resources.flowHeight+4;local dispatchH=touch and 44 or 36;local dispatchX=mainX+8
    dispatchIcon.Visible=false
    box(dispatchSlider,dispatchX,dispatchY,cw-dispatchX-12,dispatchH)
    dispatchKnob.Size=UDim2.fromOffset(touch and 18 or 14,touch and 18 or 14)
    if shortPhone and armsUI.dock.compact then
        box(dispatchSlider,132,dispatchY,cw-144,44)
    end
    box(armsUI.dispatchSurface,mainX+8,dispatchY,cw-mainX-16,44)
    if not armsUI.resourceSurface then armsUI.resourceSurface=make('Frame',controls,{Name='ResourceSurface',BackgroundColor3=C.panel,BackgroundTransparency=.12,BorderSizePixel=0,ZIndex=0});UI.corner(armsUI.resourceSurface,3)end
    armsUI.resourceSurface.Visible=portrait and not require(pack.Client.Hud20).ENABLED
    if portraitLayout then
        local r=portraitLayout
        box(hud,0,0,cw,bottomHeight)
        box(armsUI.resourceSurface,mainX+4,r.offset,cw-mainX-8,r.surface)
        box(armsUI.growthBadge,r.growth.x,r.growth.y,r.growth.w,r.growth.h)
        box(armsUI.growthFace,0,4,r.growth.w,36)
        box(armsUI.growthIcon,3,16,12,12);box(armsUI.growthArrow,16,8,13,28);armsUI.growthArrow.TextSize=16;box(statsTroopsSub,30,8,r.growth.w-33,28)
        box(troopBar,r.troops.x,r.troops.y,r.troops.w,r.troops.h)
        for _,number in ipairs({statsTroops,armsUI.filledTroops})do box(number,4,0,r.troops.w-8,r.troops.h)end
        armsUI.commandBar:goldChip(r.gold.x,r.gold.y+6,r.gold.w,32)
        pauseButton.Parent=r.menuInside and controls or gamePanel;box(pauseButton,r.menuInside and cw-52 or w-52,r.menuInside and r.offset+4 or 8,44,44)
        box(dispatchSlider,r.slider.x,r.slider.y,r.slider.w,r.slider.h)
        box(armsUI.dispatchSurface,r.slider.x-4,r.slider.y,cw-r.slider.x-4,44)
        armsUI.dock:layout(r.palette.x,r.palette.y,r.palette.w,true)
        dockDivider.Visible=false
    end
    do local d=dispatchSlider;local r=armsUI.commandBar:presetsIn(d.Position.X.Offset,d.Position.Y.Offset,d.Size.X.Offset,d.Size.Y.Offset,touch,nil,portrait);box(d,r.x,r.y,r.w,r.h)
        local share=d.Visible and not portrait and r.w>=140;selectedInfo.Visible=share
        if share then selectedInfo.Parent=controls;box(d,r.x,r.y,r.w-46,r.h);box(selectedInfo,r.x+r.w-44,r.y,44,r.h);selectedInfo.TextSize=14;selectedInfo.TextXAlignment=Enum.TextXAlignment.Center end
    end
    box(dispatchTrack,8,dispatchH/2-2,dispatchSlider.Size.X.Offset-16,4)
    dockDivider.Visible=not armsUI.dock.compact and not portrait;box(dockDivider,8,dockY-3,cw-16,1)
    updateDispatch()
    hud:SetAttribute('ResourcesStacked',resources.stacked);controls:SetAttribute('MobileHeight',touch and bottomHeight or 0)
    do local bar=armsUI.commandBar:place(w,h,touch);if bar then cw,controlsX,bottomHeight=bar.width,bar.x,bar.height;updateDispatch()
        elseif touch then controlsX,cw,bottomHeight=armsUI.commandBar:shrink(fullX,fullW,cw,bottomHeight,h);controls:SetAttribute('MobileHeight',bottomHeight)end end
    controls:SetAttribute('CommandBar',armsUI.commandBar.wide)
    local hasFractions=false
    local catalog=cityButton.Visible and postButton.Visible
    local sw=math.min(catalog and 320 or 264,w-24);local sh=(catalog or hasFractions) and 208 or 182
    local ow=math.min(touch and 232 or 248,cw);local oh=touch and (l.short and 40 or 80) or (l.short and 44 or 96)
    operations.Visible=(operations:GetAttribute('OrderCount')or 0)>0;armsUI.orders.peek.Visible=false
    box(operations,controlsX,math.max(64,controls.Position.Y.Offset-oh-6),ow,oh)
    local guidance=V.actionGuide(controlsX,controls.Position.Y.Offset,cw,ow,oh)
    box(armsUI.modeBar,guidance.x,guidance.y,guidance.width,44)
    if shortPhone and armsUI.dock.compact and armsUI.modeBar.Visible then
        box(armsUI.modeBar,12,8,math.min(224,w/2-24),44)
    end
    local allWidth=armsUI.modeAll.Visible and 84 or 0
    box(armsUI.modeTitle,8,0,armsUI.modeBar.Size.X.Offset-62-allWidth,21);box(armsUI.modeHint,8,21,armsUI.modeBar.Size.X.Offset-62-allWidth,23)
    box(armsUI.modeAll,armsUI.modeBar.Size.X.Offset-48-allWidth,0,80,44)
    box(armsUI.modeCancel,armsUI.modeBar.Size.X.Offset-48,0,44,44)
    if armsUI.modeBar.Visible then box(operations,controlsX,guidance.operationsY,ow,oh)end
    if l.short and sheet.Visible then box(operations,8,64,math.min(196,w-16),44)end
    sheet.Size=UDim2.fromOffset(sw,sh);positionSheet()
    box(sheetTitle,12,8,sw-66,32);sheetTitle.TextSize=16;box(sheetClose,sw-50,4,44,44);box(sheetDetail,12,46,sw-24,catalog and 24 or hasFractions and 44 or 70);sheetDetail.TextSize=13
    if catalog then box(cityButton,12,76,sw-24,58);box(postButton,12,142,sw-24,58)
    else box(cityButton,12,sh-63,sw-24,49) end
    cityPreview.Position=UDim2.fromOffset(-56,-3);postPreview.Position=UDim2.fromOffset(-56,-3)
    local split=(demolishButton.Visible or allianceButton.Visible) and confirmButton.Visible
    box(confirmButton,12,sh-61,split and sw-138 or sw-24,49);box(demolishButton,split and sw-117 or 12,sh-61,split and 105 or sw-24,49)
    box(allianceButton,sw-117,sh-61,105,49)
    box(contextBuild,12,sh-61,sw-24,49)
    local radial=sheetMode=="tile" or sheetMode=="unit" or sheetMode=="placement"
    sheet.BackgroundTransparency=radial and 1 or .12
    sheet:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0,radial and 999 or 3)
    local sheetLine=sheet:FindFirstChildOfClass("UIStroke");if sheetLine then sheetLine.Enabled=not radial end
    sheetTitle.Visible=not radial;sheetDetail.Visible=not radial
    radialTransport.Visible=radial and sheetMode=='tile' and armsUI.attackRoute=='transport'
    radialAttack.Visible=radial and not radialTransport.Visible and state and (sheetMode=="tile" and state.phase~="spawn" or sheetMode=="placement" and armsUI.rules.nukes[action])
    radialBuild.Visible=radial and not radialAttack.Visible and not radialTransport.Visible;allianceIcon.Visible=radial
    armsUI.transportGlyph.Visible=radial;armsUI.demolishIcon.Visible=radial and armsUI.demolishIcon:GetAttribute("Available")~=false
    armsUI.radialTrack.Visible=radial;armsUI.radialCore.Visible=radial
    local ringButtons={confirmButton,allianceButton,cityButton,postButton,demolishButton,supportGold,supportTroops,armsUI.transport,contextBuild,armsUI.rockets,armsUI.detail,armsUI.signal,armsUI.emoji,armsUI.upgradeMax}
    if radial then
        local short=l.short or l.compact
        local geometry=armsUI.interaction.radialGeometry(w,h)
        local size,big,radius,diameter=geometry.size,geometry.big,geometry.radius,geometry.diameter;local center=diameter/2
        sheet.Size=UDim2.fromOffset(diameter,diameter)
        box(armsUI.radialTrack,center-radius,center-radius,radius*2,radius*2)
        box(armsUI.radialCore,center-big/2-5,center-big/2-5,big+10,big+10)
        local closeSize=size;local diagonal=radius*math.sqrt(.5)
        box(sheetClose,center+diagonal-closeSize/2,center-diagonal-closeSize/2,closeSize,closeSize);sheetClose:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(1,0);sheetClose.TextSize=short and 15 or 18
        armsUI.primary=armsUI.primaryButton();local primary=armsUI.primary~=armsUI.transport and armsUI.primary or nil
        if primary==supportTroops and state and selectedTile then
            local f=factions[owners[selectedTile]];local wait=f and f.donationAvailableIn or 0
            local amount=math.min(state.diplomacy and state.diplomacy.defaultTroops or 0,math.max(0,f and f.cap-f.troops or 0))
            supportTroops.Text=wait>0 and ('대기\n'..math.ceil(wait)..'초')or ('병력 지원\n'..UI.troops(amount))
        end
        armsUI.radialCore.Visible=primary~=nil and primary.Visible
        local slots={}
        local fit=require(pack.Client.RadialFit)
        local blocks=fit.rects({hover,controls,hud,armsUI.modeBar,guide,operations,battle.banner,inbox.peek,armsUI.matchStatus.frame,armsUI.ranks.frame,pauseButton,armsUI.cameraShortcut,armsUI.motionShortcut,armsUI.eventLog.button,armsUI.chat.quickButton,armsUI.chat.emojiButton},gamePanel.AbsolutePosition,UI.scale)
        local fixed=sheetMode=="tile" and sheet:GetAttribute('Ring20')
        for _,slot in ipairs(fixed and armsUI.ring20:plan(fixed,geometry,menuAnchor or Vector2.new(w/2,h/2),blocks,w,h,selectedTile,selectionRevision) or armsUI.detail.Visible and armsUI.interaction.factionSlots or armsUI.interaction.landSlots)do
            local btn=sheet:FindFirstChild(slot[1]);if btn then table.insert(slots,{btn,slot[2],slot[3]})end
        end
        if sheetMode=="unit" then for _,slot in ipairs(slots) do if slot[1]==contextBuild or slot[1]==armsUI.rockets then slot[2]=1;slot[3]=0 end end end
        if not fixed then
            local turned=fit.turn(slots,primary,menuAnchor or Vector2.new(w/2,h/2),radius,size,Vector2.new(math.sqrt(.5),-math.sqrt(.5)),blocks,w,h,armsUI.transport)
            box(sheetClose,center+turned.X*radius-closeSize/2,center+turned.Y*radius-closeSize/2,closeSize,closeSize)
            local empty=sheet:FindFirstChild('Empty20');if empty then empty.Visible=false end
        end
        cityButton.Text="도시";postButton.Text="요새";if sheetMode=="unit" and confirmButton:GetAttribute('Enabled')~=false then confirmButton.Text=selectedUnit and selectedUnit.kind=="Warship" and "이동" or selectedUnit and selectedUnit.kind=="TransportShip" and "복귀" or "강화" end
        cityPreview.Visible=true;postPreview.Visible=true
        local capSize=short and 11 or 12;local cw,ch=size,14
        for _,slot in ipairs(slots) do
            local btn,dx,dy=slot[1],slot[2],slot[3]
            local isPrimary=btn==primary;local s=isPrimary and big or armsUI.interaction.minorSlots[btn.Name]and geometry.minor or size
            if isPrimary then box(btn,center-big/2,center-big/2,big,big)
            else box(btn,center+dx*radius-s/2,center+dy*radius-s/2,s,s) end
            btn:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(1,0);btn.TextXAlignment=Enum.TextXAlignment.Center
            if isPrimary then btn.BackgroundColor3=C.accent elseif btn~=confirmButton then btn.BackgroundColor3=C.raised end
            if not btn:FindFirstChildOfClass("UIStroke") then local outline=UI.stroke(btn,C.line,1);outline.Transparency=.45 end
            local stroke=btn:FindFirstChildOfClass("UIStroke");stroke.Thickness=isPrimary and 2 or 1;stroke.Color=isPrimary and C.ink or C.line
            local enabled=btn:GetAttribute("Enabled")~=false
            local icon=radialIcon(btn);local iconOnly=not isPrimary and icon~=nil
            local cap=radialCaption(btn);cap.Visible=iconOnly;cap.TextSize=capSize;cap.TextTransparency=enabled and 0 or .5
            box(cap,0,s-17,s-4,14);cap.TextXAlignment=Enum.TextXAlignment.Center;cap.BackgroundTransparency=1
            local capPadding=cap:FindFirstChildOfClass('UIPadding');if capPadding then capPadding.PaddingLeft=UDim.new(0,1);capPadding.PaddingRight=UDim.new(0,1)end
            btn:SetAttribute("RadialHideText",iconOnly)
            btn.TextTransparency=iconOnly and 1 or (enabled and 0 or .5)
            local pad=btn:FindFirstChildOfClass("UIPadding") or make("UIPadding",btn,{})
            pad.PaddingLeft=UDim.new(0,2);pad.PaddingRight=UDim.new(0,2)
            if isPrimary then
                local ts=short and 12 or 13;local bottom=short and 5 or 7;local lines=string.find(btn.Text,'\n',1,true)and 2 or 1
                btn.TextSize=ts;btn.LineHeight=.95;btn.TextYAlignment=Enum.TextYAlignment.Bottom;pad.PaddingBottom=UDim.new(0,bottom)
                local room=big-bottom-math.ceil(lines*ts*.95)-4
                if icon then local iw=math.max(14,math.min(geometry.bigIcon,room-4));box(icon,(big-iw)/2,math.max(3,(room-iw)/2+1),iw,iw) end
            else
                btn.TextSize=14;btn.LineHeight=1;btn.TextYAlignment=Enum.TextYAlignment.Center;pad.PaddingBottom=UDim.new(0,0)
                if icon then local iw=math.min(geometry.icon,s-21);box(icon,(s-iw)/2-2,3,iw,iw) end
            end
            if icon then
                local fade=enabled and 0 or .5
                if icon:IsA("TextLabel") then icon.TextSize=math.floor(icon.Size.Y.Offset*.8);icon.TextTransparency=fade;icon.TextYAlignment=Enum.TextYAlignment.Center
                elseif icon:IsA("ImageLabel") or icon:IsA("ViewportFrame") then icon.ImageTransparency=fade end
                if icon==radialTransport then icon.ImageColor3=isPrimary and C.bg or C.ink end
                if string.sub(icon.Name,1,6)=='Glyph_' then icon.ImageColor3=isPrimary and C.bg or icon:GetAttribute('Tint') or C.ink end
            end
        end
        do local breaking=allianceButton.Visible and allianceButton:GetAttribute('Breaking')==true
            radialCaption(allianceButton).TextColor3=breaking and C.danger or C.ink;if allianceIcon:IsA('TextLabel')then allianceIcon.TextColor3=breaking and C.danger or C.accent else allianceIcon.ImageColor3=breaking and C.danger or C.accent end end
        for _,kind in ipairs(armsUI.interaction.ringKinds)do if armsUI.ring[kind].Visible then box(sheetClose,center-size/2,center-size/2,size,size);break end end
        for kind,b in pairs(armsUI.ring)do if b.Visible then
            local blocked=armsUI.ringBlock(kind)~=nil;local cap=radialCaption(b);local icon=armsUI.ringIcons[b]
            if b~=primary then cap.TextColor3=blocked and C.danger or C.gold;cap.Font=Enum.Font.BuilderSansBold end
            if icon:IsA("ImageLabel")then icon.ImageTransparency=blocked and .55 or 0;if b==primary then icon.ImageColor3=C.bg end end
        end end
        positionSheet()
    else
        for _,btn in ipairs(ringButtons) do
            btn:SetAttribute("RadialHideText",false);btn.TextTransparency=btn:GetAttribute("Enabled")==false and .5 or 0
            local cap=radialCaptions[btn];if cap then cap.Visible=false end
        end
        for _,btn in ipairs({confirmButton,allianceButton,cityButton,postButton,demolishButton,sheetClose}) do btn:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0,3);btn.TextYAlignment=Enum.TextYAlignment.Center;local pad=btn:FindFirstChildOfClass("UIPadding");if pad then pad.PaddingBottom=UDim.new(0,0) end end
        cityPreview.Visible=true;postPreview.Visible=true;cityPreview.Size=UDim2.fromOffset(52,52);postPreview.Size=UDim2.fromOffset(52,52)
        cityPreview.ImageTransparency=0;postPreview.ImageTransparency=0
        for _,btn in ipairs({cityButton,postButton}) do btn.TextXAlignment=Enum.TextXAlignment.Right;local pad=btn:FindFirstChildOfClass("UIPadding");if pad then pad.PaddingLeft=UDim.new(0,60);pad.PaddingRight=UDim.new(0,10) end end
    end
    local inspectWidth=math.min(440,w-16)
    local inspected=hoveredTile and factions[owners[hoveredTile]]
    armsUI.inspect=sheet.Visible and (inspected or selectedUnit and hoveredTile and require(pack.Client.Hud20).ENABLED) and function()
        if hoverCard:show({state=state,faction=hoveredTile and factions[owners[hoveredTile]],info=terrainInfo(hoveredTile),unit=selectedUnit,compact=true,width=inspectWidth,ownColor=Color3.fromRGB(table.unpack(CosmeticCatalog.get(state.style).territory))})then hoverCard:dock(w,8)end
    end or nil
    if armsUI.inspect then armsUI.inspect()end
    if l.short and sheet.Visible and not require(pack.Client.Hud20).ENABLED then hover.Visible=false end
    if modal.Visible and require(pack.Client.Hud20).ENABLED then hover.Visible=false;sheet.Visible=false end
    local inset=touch and math.max(0,-root.AbsolutePosition.Y)/UI.scale or 0
    local mw=armsUI.modalSize(modalMode);local mh=math.min(660,h-24-inset)
    if modalMode=='result'and armsUI.resultView and h>=500 and not armsUI.resultView.detailsExpanded then
        armsUI.resultView:update(state,mw-32)
        mh=math.min(mh,math.max(360,modalBody.CanvasSize.Y.Offset+(touch and 220 or 212)))
    end
    local short=h<500;local top=short and 52 or 68;local fit=table.find({'pause','feedback','help','leave','demolish'},modalMode)~=nil
    if fit then mh=math.min(h-16-inset,modalBody.CanvasSize.Y.Offset+top+16)end
    local back=fit and (modalMode=='feedback'or modalMode=='help')and state~=nil and state.phase~='menu';armsUI.modalBack.Visible=back
    local cs=touch and 48 or 44
    box(modalCard,(w-mw)/2,inset+(h-inset-mh)/2,mw,mh);box(armsUI.modalBack,16,short and 2 or 12,cs,cs);box(modalTitle,back and 74 or 20,short and 2 or 12,mw-136,cs);box(modalClose,mw-cs-14,short and 2 or 12,cs,cs);box(modalBody,16,top,mw-32,mh-top-8)
    modalTitle.Font=Enum.Font.BuilderSansBold;modalTitle.TextSize=short and 20 or 22
    require(pack.Client.MatchMenu).frame20({card=modalCard,title=modalTitle,close=modalClose,body=modalBody,modal=modal,mode=modalMode,state=state,w=w,h=h})
    if armsUI.resultActions.Visible and (modalMode=='recap'or modalMode=='comrades')then
        box(modalBody,16,68,mw-32,mh-100-cs);box(armsUI.resultActions,16,mh-16-cs,mw-32,cs);box(armsUI.resultActions.Back,0,0,mw-32,cs)
    elseif armsUI.resultActions.Visible and modalMode=='result'then
        local ah=require(pack.Client.ResultView).layoutActions(armsUI.resultActions,mw-32,cs,h<500)
        if h<500 then box(modalBody,16,top,mw-32,mh-top-16-ah)else box(modalBody,16,68,mw-32,mh-100-ah)end
        box(armsUI.resultActions,16,mh-(h<500 and 8 or 16)-ah,mw-32,ah)
        if armsUI.resultCompact~=(h<500)and not armsUI.resultRelayout then
            armsUI.resultRelayout=true
            task.defer(function()
                armsUI.resultRelayout=false
                if modal.Visible and modalMode=='result'then modalBody.CanvasPosition=Vector2.zero;openModal('result')end
            end)
        end
    end
    if armsUI.resultView and modalMode=='result'then armsUI.resultView:update(state,mw-32)end
    if armsUI.spectator then
        armsUI.spectator:update(state,modal.Visible or armsUI.sheets:any() or armsUI.nuclear.active)
        armsUI.spectator:layout(w)
        if armsUI.spectator.frame.Visible then hover.Visible=false end
    end
    controls.Visible=state~=nil and state.phase~='menu'and not armsUI.drop.active and not(state.multiplayer and state.phase=='lost'and not state.matchEnded)
    armsUI.resultUp=modal.Visible and modalMode=='result'and require(pack.Client.Hud20).ENABLED;if armsUI.resultUp then controls.Visible=false;operations.Visible=false end
    local dropMenu
    if armsUI.drop.active and currentMap then
        dropMenu=require(pack.Client.DropLayout).of(w,h,touch,currentMap.meta.width,currentMap.meta.height).menu
        pauseButton.Parent=gamePanel;box(pauseButton,dropMenu.x,dropMenu.y,44,44)
    else
        pauseButton.Parent=gamePanel
        local menu=require(pack.Core.InterfacePlacement).shortcuts(w,h,touch).Menu
        box(pauseButton,menu.x,menu.y,44,44)
    end
    if armsUI.motionShortcut then
        armsUI.motionShortcut.Visible=state and state.phase=='playing'and not modal.Visible and not armsUI.drop.active
        require(pack.Client.CornerShortcut).place(armsUI.motionShortcut,w,h,{x=pauseButton.Position.X.Offset+(pauseButton.Parent==controls and controls.Position.X.Offset or 0),y=pauseButton.Position.Y.Offset+(pauseButton.Parent==controls and controls.Position.Y.Offset or 0),w=44},touch,4)
    end
    if armsUI.cameraShortcut then
        armsUI.cameraShortcut.Visible=state and state.phase~='menu'and not modal.Visible and not armsUI.drop.introActive
        local menu=dropMenu or {x=pauseButton.Position.X.Offset,y=pauseButton.Position.Y.Offset,w=44}
        if dropMenu then menu.drop=true end
        require(pack.Client.CornerShortcut).place(armsUI.cameraShortcut,w,h,menu,touch,armsUI.drop.active and 1 or 5)
    end
    battle:layout(w,h,modal.Visible or armsUI.sheets:any(),sheet.Visible or inbox.request~=nil or armsUI.nuclear.active,armsUI.nuclear.active)
    armsUI.feedback:layout(w,h,armsUI.feedback:covered(modal.Visible or armsUI.sheets:any(),sheet.Visible or inbox.request~=nil or hover.Visible or #battle.incoming>0),
        armsUI.ranks.frame.Visible and (armsUI.ranks.compact and {chipBottom=52} or {left=w-require(pack.Client.Leaderboard).WIDTH-12}) or nil)
    inbox:layout(w,h,modal.Visible,false,sheet.Visible or armsUI.nuclear.active)
    armsUI.renewal:layout(w,h,modal.Visible or armsUI.nuclear.active,#battle.incoming>0)
    armsUI.tactical:layout(w,h)
    armsUI.quick:layout(w,h);armsUI.sheets:layout(w,h,touch)
    do
        noticeUI:place(require(pack.Core.InterfacePlacement).notice(w,h),w,h,touch)
    end
    armsUI.ranks:layout(w,h,state~=nil and not armsUI.drop.active and (state.phase=='playing'or state.phase=='spawn'or state.multiplayer and state.phase=='lost'and not state.matchEnded)and not modal.Visible and not(armsUI.sheets:any()and(h>=500 and w>=900 or require(pack.Core.InterfacePlacement).phone(w,h,touch)))and not((touch or w<900)and armsUI.spectator.frame.Visible),touch)
    armsUI.matchStatus:layout(w,h,state~=nil and not armsUI.drop.active and not modal.Visible and not armsUI.nuclear.active and not(armsUI.spectator.frame.Visible and (touch or w<900 or h<500)),touch or w<900 or h<500)
    armsUI.nuclear:layout(w,h,controls.Position.Y.Offset)
    local aimCovered=armsUI.sheets:any() or modal.Visible
    armsUI.nuclear.bar.Visible=armsUI.nuclear.active==true and not aimCovered
    armsUI.nuclear.overlay.Visible=not aimCovered
    armsUI.eventLog:layout(w,h,state~=nil and state.phase~='menu'and state.phase~='spawn'and not modal.Visible and not(armsUI.spectator.frame.Visible and touch),
        {x=pauseButton.Position.X.Offset+(pauseButton.Parent==controls and controls.Position.X.Offset or 0),y=pauseButton.Position.Y.Offset+(pauseButton.Parent==controls and controls.Position.Y.Offset or 0),w=pauseButton.Size.X.Offset},touch)
    armsUI.chat:layout(w,h,sheet.Visible or modal.Visible or armsUI.sheets:any(),bottomHeight+10+(armsUI.nuclear.active and h>=500 and 128 or 0),
        {x=pauseButton.Position.X.Offset+(pauseButton.Parent==controls and controls.Position.X.Offset or 0),y=pauseButton.Position.Y.Offset+(pauseButton.Parent==controls and controls.Position.Y.Offset or 0),w=pauseButton.Size.X.Offset},touch,
        math.max(96,hover.Visible and hoverCard.docked~=false and hover.Position.Y.Offset+hover.Size.Y.Offset+44 or 0,armsUI.nuclear.active and h<500 and 156 or 0),
        armsUI.ranks.frame.Visible and not armsUI.ranks.compact and w-armsUI.ranks.frame.Position.X.Offset or 0,
        sheet.Visible or modal.Visible or armsUI.sheets:any())
    if armsUI.sheets:any()then hover.Visible=false end;armsUI.sheets:cards(w,h,modal.Visible)
    if armsUI.tray then local g=portrait and armsUI.portraitGrid;local t=armsUI.trayGrid or {};armsUI.trayGrid=t
        if g then t.x,t.y,t.w,t.h,t.open=controls.Position.X.Offset+g.x,controls.Position.Y.Offset+g.y,g.w,g.h,armsUI.paletteExpanded end
        armsUI.tray:layout(w,h,touch,state~=nil and not modal.Visible,sheet.Visible,portrait and controls.Position.Y.Offset or nil,g and t or nil)end
    if armsUI.hudScale then armsUI.hudScale:apply(w,h,touch)end
    if armsUI.resolveOverlays then armsUI.resolveOverlays()end
    if currentMap then renderer:clamp();dirty=true;refreshMarkers() end
end
armsUI.resolveOverlays=function()
    if not gamePanel.Visible then return end
    local w,h=screenSize().X,screenSize().Y;local blocks={};local O=require(pack.Client.OverlayLayout)
    local function rectangle(o)
        return {x=o.Position.X.Offset-o.Size.X.Offset*o.AnchorPoint.X,y=o.Position.Y.Offset-o.Size.Y.Offset*o.AnchorPoint.Y,w=o.Size.X.Offset,h=o.Size.Y.Offset}
    end
    local function fixed(o)if o and o.Visible then table.insert(blocks,rectangle(o))end end
    for _,o in ipairs({controls,armsUI.ranks.frame,armsUI.matchStatus.frame,armsUI.matchStatus.speedPill,hoverCard.docked~=false and hover or controls,guide,operations,armsUI.modeBar,armsUI.nuclear.bar,battle.banner,armsUI.eventLog.panel,armsUI.chat.frame,armsUI.chat.feed,armsUI.eventLog.button,armsUI.chat.quickButton,armsUI.chat.emojiButton})do fixed(o)end
    if sheet.Visible then
        if sheetMode=='tile'or sheetMode=='unit'or sheetMode=='placement'then
            local box=rectangle(sheet)
            for _,b in ipairs(sheet:GetChildren())do if b:IsA('GuiButton')and b.Visible then local r=rectangle(b);r.x+=box.x;r.y+=box.y;table.insert(blocks,r)end end
        else fixed(sheet)end
    end
    local key={w,h,tostring(inbox.panel.Visible),tostring(inbox.peek.Visible),tostring(armsUI.renewal.panel.Visible),tostring(toast.Visible),tostring(armsUI.commandFeedback.frame.Visible),armsUI.commandFeedback.current and armsUI.commandFeedback.current.id or 0,armsUI.commandFeedback.current and armsUI.commandFeedback.current.phase or ''}
    for _,r in ipairs(blocks)do table.insert(key,string.format('%.1f,%.1f,%.1f,%.1f',r.x,r.y,r.w,r.h))end
    key=table.concat(key,'|')
    if armsUI.overlayKey==key then return end;armsUI.overlayKey=key
    fixed(inbox.panel);fixed(armsUI.renewal.panel)
    fixed(inbox.peek)
    fixed(toast)
    armsUI.commandFeedback:layout(w,h,nil,blocks)
    if armsUI.commandFeedback.frame.Visible then fixed(armsUI.commandFeedback.frame)end
    toast.Visible=notices.current~=nil and not(inbox.panel.Visible or armsUI.renewal.panel.Visible or armsUI.commandFeedback.frame.Visible or modal.Visible or armsUI.sheets:any())
    armsUI.chat.pings.blocks=blocks
end
local resyncing=false
render=function(s)
    if not bootClocks[4]then bootClocks[4]=os.clock();pcall(function()me:SetAttribute("LoadUiClocks",string.format("%.3f,%.3f,%.3f,%.3f",bootClocks[1],bootClocks[2],bootClocks[3]or bootClocks[4],bootClocks[4]))end)end
    if type(s)~='table'or s.busy then return end
    armsUI.stateStream=armsUI.stateStream or {}
    if not require(pack.Core.StateDelta).decode(armsUI.stateStream,s)then
        if not resyncing then resyncing=true;task.spawn(function() local ok,full=pcall(function() return read:InvokeServer() end);resyncing=false;if ok then render(full) end end)end
        return
    end
    for _,f in ipairs(s.factions or {})do if f.userId then L.addName(f.name)end end
    if s.ownershipOnly then
        if not state or s.version~=currentVersion then return end
        armsUI.probe.start('Snap.own')
        local synchronized
        armsUI.feedback:capture(s,owners,ownershipRevision)
        ownershipRevision,synchronized=V.applyOwnership(owners,ownershipRevision,s)
        if synchronized then renderer:updateOwnership(s)
        elseif not resyncing then
            resyncing=true;task.spawn(function() local ok,full=pcall(function() return read:InvokeServer() end);resyncing=false;if ok then render(full) end end)
        end
        armsUI.probe.stop('Snap.own')
        return
    end
    if state and (s.version<state.version or s.version==state.version and (s.tick or 0)<(state.tick or 0)) then return end
    if state and s.version==state.version and s.snapshotSerial and state.snapshotSerial and s.snapshotSerial<state.snapshotSerial then return end
    local previous=state;state=s;armsUI.telemetry.state(s)
    local liveUnits={};for _,u in ipairs(s.units or {})do liveUnits[u.id]=true end
    for id,m in pairs(unitMarkers)do if not liveUnits[id]then m.root:Destroy();unitMarkers[id]=nil end end
    if not previous or previous.version~=s.version then table.clear(pending);armsUI.inputFlow:reset();armsUI.commandFeedback:reset();armsUI.lastTap=nil;selectionRevision+=1;hoveredTile=nil;hover.Visible=false end
    if not previous or previous.version~=s.version then armsUI.commsSeen=0;armsUI.nameLayer:reset()end
    if resumeCommand and not s.paused and s.phase=="playing" then
        local c=resumeCommand;resumeCommand=nil;local version=s.version
        task.delay(.15,function() if state and state.version==version and not state.paused then send(c.action or "alliance",c.kind,c.id) end end)
    end
    if previous and previous.multiplayer and s.phase=="menu" and multiplayerLobby then multiplayerLobby.single=false;modal.Visible=false;modalMode=nil end
    gamePanel.Visible=s.phase~="menu"
    toast.Parent=gamePanel.Visible and gamePanel or root;toast.ZIndex=modal.Visible and 31 or toast.Parent==root and 29 or 17
    if multiplayerLobby then multiplayerLobby:setGameState(s);multiplayerLobby:setScreen(s.phase=="menu" and not LobbyIntro.active) end
    if movementControls and (not previous or previous.phase=="menu"or s.phase=="menu") then
        if s.phase=="menu" and (multiplayerLobby and multiplayerLobby.single or require(pack.Client.LobbyStage).attached)then movementControls:Disable()else movementControls:Enable()end
    end
    root.BackgroundTransparency=1
    root.LoadingCover.Visible=s.loading==true
    renderer.enabled=gamePanel.Visible
    renderer.folder.Parent=gamePanel.Visible and workspace or nil
    require(pack.Client.ToyLighting).lobby(s.phase=="menu")
    require(pack.Client.ToyAudio).ambience(s.phase=="menu");require(pack.Client.LobbyMusic).set(s.phase=="menu")
    if s.phase=="menu"then
        local camera=workspace.CurrentCamera;local hum=me.Character and me.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.CameraOffset=Vector3.zero end
        if not LobbyIntro.active and not require(pack.Client.LobbyShowcase).active and not require(pack.Client.LobbyStage).attached then
            camera.CameraType=Enum.CameraType.Custom;camera.CameraSubject=hum;camera.FieldOfView=60
            me.CameraMinZoomDistance=PlazaLayout.minZoom;me.CameraMaxZoomDistance=PlazaLayout.maxZoom
        end
        if not previous or previous.phase~="menu"or armsUI.introPending then
            local target=Vector3.new(PlazaLayout.x,PlazaLayout.y+4.5,PlazaLayout.z+PlazaLayout.spawnZ)
            local finalCF=CFrame.lookAt(target+Vector3.new(0,6.6,25.1),target)
            if require(pack.Client.LobbyStage).attached then finalCF=require(pack.Client.LobbyStage).shot();target=require(pack.Client.LobbyStage).focus().Position end
            local function land()
                if require(pack.Client.LobbyStage).attached then require(pack.Client.LobbyStage).take();armsUI.lobbyLanded=armsUI.lobbyLanded or os.clock();return end
                camera.CameraType=Enum.CameraType.Custom;camera.CameraSubject=me.Character and me.Character:FindFirstChildOfClass("Humanoid") or hum
                me.CameraMaxZoomDistance=26;me.CameraMinZoomDistance=26
                camera.CFrame=finalCF;camera.Focus=CFrame.new(target);armsUI.lobbyLanded=armsUI.lobbyLanded or os.clock()
                task.delay(.3,function()if state and state.phase=="menu"then me.CameraMinZoomDistance=PlazaLayout.minZoom;me.CameraMaxZoomDistance=PlazaLayout.maxZoom end end)
            end
            if s.loading then armsUI.introPending=true;land()
            elseif not effects.reduced and not LobbyIntro.played and hum and not(multiplayerLobby and multiplayerLobby.account and multiplayerLobby.account.ready and next(multiplayerLobby.account.progress and multiplayerLobby.account.progress.history or {},next(multiplayerLobby.account.progress and multiplayerLobby.account.progress.history or {}))~=nil)then armsUI.introPending=nil
                if multiplayerLobby then multiplayerLobby.frame.Visible=false end
                LobbyIntro.play(root,me.DisplayName,finalCF,CFrame.new(target),function()
                    land();if multiplayerLobby and state and state.phase=="menu"then multiplayerLobby:setScreen(true)end
                end)
            else armsUI.introPending=nil;LobbyIntro.played=hum;land() end
        end
    elseif me.Character then local hum=me.Character:FindFirstChildOfClass('Humanoid');if hum then hum.CameraOffset=Vector3.zero end end
    gui:SetAttribute("Phase",s.phase);gui:SetAttribute("Map",s.map or selectedMap);gui:SetAttribute("RenderedTick",s.tick or 0)
    if s.phase=="menu" then
        if armsUI.drop.active then armsUI.drop:clear()end
        armsUI.spectator:update(s,true)
        armsUI.feedback:update(s,{})
        armsUI.tactical:update(s,{});armsUI.chat:update(s,{});armsUI.quick:update(s,{});armsUI.sheets:update(s);armsUI.nuclear:stop()
        sheetMode=nil;action="inspect";selectedTile=nil;selectedUnit=nil;hover.Visible=false;resumeCommand=nil
        if modalMode=="settings" then renderSettings() end
        if armsUI.sticksOff then armsUI.sticksOff=false;game:GetService('GuiService').TouchControlsEnabled=true end
        return
    end
    if currentVersion~=s.version then
        root.LoadingCover.Visible=true
        local packed=require(pack.Client.MapPreload).resolve(s);if packed==false then return end
        local function refetch(result,err)
            local key=tostring(s.version)..result;if armsUI.mapPrepareSeen~=key then armsUI.mapPrepareSeen=key
                pcall(armsUI.telemetry.step,'match','mapPrepare',{result=result});if err then warn('MapPrepare: '..tostring(err))end end
            if not resyncing then resyncing=true;task.spawn(function() local ok,full=pcall(function() return read:InvokeServer() end);resyncing=false;if ok then render(full) end end)end
        end
        if packed==nil and s.mapTerrain==nil then refetch('pending');return end
        local built;local ok,err=pcall(function()
            built=table.clone(mapData(s.map,s.mapTerrain,packed));built.terrain=buffer.fromstring(buffer.tostring(built.terrain));renderer:setMap(built)
        end)
        if not ok then refetch('failed',err);return end
        currentVersion=s.version;require(pack.Client.ContextGuess).reset();currentMap=built
        table.clear(owners);ownershipRevision=0;selectedTile=nil;selectedUnit=nil;preview=nil;previewSerial+=1;sheetMode=nil;action="inspect";eventsSeen=0;armsUI.eventLog:reset()
        for _,v in pairs(unitMarkers) do v.root:Destroy() end;unitMarkers={};renderer:fit();dirty=true
        if modal.Visible and (modalMode=="result" or modalMode=="recap" or modalMode=="comrades") then pauseOwned=false;modal.Visible=false;modalMode=nil end
        if s.casual and s.phase=="playing" and s.player and s.player.labelTile then
            local tile=s.player.labelTile;task.defer(function()renderer:focusAt(tile);dirty=true end)
            notify("내 나라, 옆 땅을 눌러 공격")
        end
    end
    renderer:setStyle(s.cosmetics and s.cosmetics.territory or s.style);renderer:setState(s)
    armsUI.drop:update(s)
    local oldRevision=ownershipRevision;local synchronized
    armsUI.feedback:capture(s,owners,ownershipRevision)
    ownershipRevision,synchronized=V.applyOwnership(owners,ownershipRevision,s)
    if synchronized then renderer:updateOwnership(s) end
    if oldRevision~=ownershipRevision then dirty=true end
    if not synchronized and not resyncing then
        resyncing=true;task.spawn(function() local ok,full=pcall(function() return read:InvokeServer() end);resyncing=false;if ok then render(full) end end)
    end
    if previous and previous.phase=="spawn" and s.phase=="playing" and s.player.labelTile then
        renderer:follow();dirty=true;sheetMode=nil;selectedTile=nil
    end
    local p=s.player
    factions={};sortedFactions=table.clone(s.factions or {p})
    for _,f in ipairs(sortedFactions) do factions[f.id]=f end
    if s.phase~="playing"then armsUI.smallWarned=nil elseif not armsUI.smallWarned and not s.observer and (s.tick or 0)>=120 and factions[1]and(factions[1].tiles or 100)<100 then armsUI.smallWarned=true
        if armsUI.input.touch()then require(pack.Client.MatchBubble).hint(root,armsUI.growthBadge,"땅 100칸 미만","한 번에 다 뺏겨요")
        else notify("땅 100칸 미만, 한 번에 다 뺏겨요",true,s.player and s.player.labelTile)end end
    do local off=armsUI.input.touch()and(s.phase=="spawn"or s.phase=="playing"or s.phase=="lost"or s.phase=="won")
        if armsUI.sticksOff~=off then armsUI.sticksOff=off;game:GetService('GuiService').TouchControlsEnabled=not off end end
    armsUI.tactical:update(s,factions);armsUI.chat:update(s,factions);armsUI.quick:update(s,factions)
    armsUI.nuclear:update(s,currentMap,owners,action,preview,selectedUnit,hoveredUnit)
    if hover.Visible and not hoverCard.leaving and os.clock()>(armsUI.hoverNext or 0)then armsUI.hoverNext=os.clock()+.25
        if sheet.Visible then if armsUI.inspect then armsUI.inspect()end elseif armsUI.lastHover and not armsUI.input.touch()then armsUI.mapInput.hover(table.unpack(armsUI.lastHover))end end
    if sheetMode=='tile'and selectedTile and armsUI.selectedRelation then
        local old=armsUI.selectedRelation;local f=factions[owners[selectedTile]]
        local owner=owners[selectedTile]or 0
        if old.owner~=owner or old.allied~=(f and f.allied or false)then
            selectedTile=nil;sheetMode=nil;selectionRevision+=1;armsUI.selectedRelation=nil;hover.Visible=false
            if owner~=1 then notify(old.owner~=owner and '주인 변경, 다시 선택'or '관계 변경, 다시 선택')end
        end
    end
    armsUI.factionKinds={};for id,f in pairs(factions) do armsUI.factionKinds[id]=f.kind end
    armsUI.feedback:update(s,factions)
    table.sort(sortedFactions,function(a,b) return a.tiles>b.tiles or a.tiles==b.tiles and a.id<b.id end)
    refreshOperations()
    inbox:update(s);armsUI.renewal:update(s);battle:update(s,factions)
    commanders:update(s,roomVisible,#battle.incoming,Color3.fromRGB(table.unpack(CosmeticCatalog.get(s.style).territory)))
    pauseButton.Text=(s.phase=='lost'or s.phase=='won')and '결과'or '';armsUI.menuPlate.Visible=s.phase~='lost'and s.phase~='won'
    statsTroops.Text=UI.troops(p.troops).." / "..UI.troops(p.cap);armsUI.filledTroops.Text=statsTroops.Text
    local recruitment=armsUI.recruitment:update(s)
    armsUI.lastRecruitment=recruitment
    statsTroopsSub.Text=require(pack.Core.RecruitmentPresentation).rateText(recruitment.rate,UI.troops);armsUI.growthArrow.Text=recruitment.arrow
    local recruitmentColor=recruitment.tone=='falling'and C.recruitmentSlow or recruitment.tone=='rising'and C.recruitmentGrow or C.muted
    statsTroopsSub.TextColor3=recruitmentColor;armsUI.growthArrow.TextColor3=recruitmentColor;armsUI.growthStroke.Color=recruitmentColor;armsUI.growthFace.BackgroundColor3=require(pack.Client.HudStyle).colors.chip
    armsUI.growthIcon.ImageColor3=recruitmentColor
    armsUI.growthBadge:SetAttribute('Trend',recruitment.tone);armsUI.growthBadge:SetAttribute('Rate',recruitment.rate);armsUI.growthBadge:SetAttribute('RawRate',recruitment.rawRate)
    troopFill.Size=UDim2.fromScale(math.clamp(p.troops/math.max(1,p.cap),0,1),1);armsUI.troopFront:update(s,p)
    statsGold.Text=UI.number(p.gold);statsGoldSub.Text="+"..UI.number(p.income).."/초"
    armsUI.dock:update(s,action)
    quickCityText.Text="도시"..(armsUI.input.touch() and "" or " [C]").."\n"..UI.number(s.costs.City)
    quickPostText.Text="요새"..(armsUI.input.touch() and "" or " [V]").."\n"..UI.number(s.costs.DefensePost)
    for _,b in ipairs({quickCity,quickPost}) do UI.enabled(b,s.phase=="playing" and not s.paused) end
    updateDispatch()
    statsLand.Text=string.format("%.2f%% 영토",p.share*100)
    timerText.Text=(s.paused and "일시정지 " or "")..string.format("%02d:%02d",math.floor(s.tick/600),math.floor(s.tick/10)%60)
    local territory=Color3.fromRGB(table.unpack(CosmeticCatalog.get(s.style).territory))
    armsUI.commandBar:update(s,territory);armsUI.ranks:update(s,sortedFactions,territory);armsUI.sheets:update(s,factions,sortedFactions);armsUI.feedback:ranked(not s.observer and armsUI.ranks.mineAt or nil,armsUI.ranks.alive and #armsUI.ranks.alive);armsUI.matchStatus:update(s)
    if selectedUnit then
        local id=selectedUnit.id;selectedUnit=nil;for _,u in ipairs(s.units) do if u.id==id then selectedUnit=u;break end end
        if not selectedUnit and sheetMode=="unit" then sheetMode=nil end
    end
    if armsUI.refreshGuide then armsUI.refreshGuide()end
    for _,e in ipairs(s.events or {}) do if e.id>eventsSeen then
        eventsSeen=e.id
        local covered=(e.kind=="building" and not string.find(e.message,"철거",1,true)) or e.kind=="donation" or e.kind=="intercept" or string.find(e.message,"측과 동맹을 맺었어요",1,true) or string.find(e.message,"측이 동맹을 깼어요",1,true) or e.kind=="rejected" and string.find(e.message,"30초 방어 약화",1,true)
        local tile=e.tile;if not tile then for _,f in pairs(factions)do if f.name and f.labelTile and #f.name>0 and string.sub(e.message,1,#f.name)==f.name then tile=f.labelTile;break end end end
        if e.kind~="info" and not covered then notify(e.message,e.kind=="error" or e.kind=="rejected" or e.kind=="loss",tile)end
        if e.kind~="info" and e.kind~="error" then armsUI.eventLog:add(e.message,e.kind=="rejected" or e.kind=="loss",tile,s.tick,e.kind)end
        if (e.kind=="rejected" or e.kind=="loss")and previous then armsUI.audio.play("error")end
    end end
    for _,e in ipairs(s.comms and s.comms.events or {})do if e.id>(armsUI.commsSeen or 0)then armsUI.commsSeen=e.id;if e.from~=1 then local sender=factions[e.from];local target=e.target and factions[e.target]
                if e.kind=="emoji"and sender and sender.labelTile then
                    armsUI.chat.onEmoji(e.from,sender.labelTile,e.text)
                    if e.to~=1 then continue end
                end
                local line=(sender and sender.name or "지휘관").."  "..e.text..(target and " : "..target.name or "");notify(line,false,(target or sender or {}).labelTile);armsUI.eventLog:add(line,false,(target or sender or {}).labelTile,s.tick);if previous then armsUI.audio.play("request")end end end end
    if (s.phase=="won" or s.phase=="lost") and not s.observer and (not previous or previous.phase~=s.phase or s.matchEnded and not previous.matchEnded) then
        if not previous or previous.phase~=s.phase then local function land(p)require(pack.Client.ResultCelebration).play(p or root,state,effects.reduced)end
            if not require(pack.Client.VictoryCinematic).play(renderer,s,effects.reduced,land,function()openModal("result")end)then land()end end
        if not require(pack.Client.VictoryCinematic).active then openModal("result")end end
    if modalMode=='result'and armsUI.resultView then
        local view=armsUI.resultView:update(s,math.max(240,modalBody.AbsoluteSize.X/UI.scale));modalTitle.Text=view.title
    end
    armsUI.spectator:update(s,modal.Visible or armsUI.sheets:any() or armsUI.nuclear.active)

    refreshSheet();refreshMarkers()
    gui:SetAttribute("OwnedTiles",p.tiles);gui:SetAttribute("OwnershipRevision",ownershipRevision)
end
shop=require(pack.Client.Storefront).new(function(account)
    if multiplayerLobby then multiplayerLobby:setAccount(account);selectedMap=multiplayerLobby.map end
    if account.progress then tutorial=account.progress.tutorial~=false end
    if account.preferences then
        armsUI.quick:setFavorites(account.preferences.emojiFavorites)
        local lite=require(pack.Client.AutoLite);effects.reduced=account.preferences.reducedEffects;effects.lite=lite.active;renderer.liteEffects=lite.active
        lite.start(function()effects.lite=true;renderer.liteEffects=true end)
        me:SetAttribute('CommanderReducedEffects',effects.reduced==true)
        effects.flashes=account.preferences.mapFlashes~=false
        effects.particles.flashes=effects.flashes
        renderer.reducedEffects=effects.reduced;armsUI.matchStatus.reduced=effects.reduced==true
        renderer.cameraShake=account.preferences.cameraShake~=false;renderer.mapFlashes=effects.flashes
        require(pack.Client.HudOpacity).apply(gamePanel,account.preferences.hudOpacity)
        game:GetService("SoundService"):SetAttribute("ToySoundsMuted",account.preferences.soundsMuted);game:GetService("SoundService"):SetAttribute("ToySoundsVolume",account.preferences.sfxVolume or 1);game:GetService("SoundService"):SetAttribute("ToyMusicVolume",account.preferences.musicVolume or 1)
    end
    if state and account.cosmetics and (state.controller==0 or state.controller==me.UserId) then
        state.cosmetics=account.cosmetics;state.style=account.cosmetics.territory
        renderer:setStyle(state.style);if state.phase~="menu" and state.version==currentVersion then renderer:setState(state) end
    end
end,notify,function() if modal.Visible and (modalMode=="cosmetics" or modalMode=="feedback") then openModal(modalMode) end;if multiplayerLobby and multiplayerLobby.page then multiplayerLobby:drawPage()end end)
multiplayerLobby=require(pack.Client.MultiplayerLobby).new(root,notify,{
    single=function(key)selectedMap=key;send('start',key)end,
    goal=function(key)selectedMap=key;send('start',key,'goal')end,
    quick=function(d)closeModal();send('quick',d)end,
    daily=function()closeModal();send('daily')end,
    campaign=function(id)closeModal();send('campaign',id)end,
    map=function(key)selectedMap=key;multiplayerLobby:request('map',key)end,
    mode=function()end,
    learn=function()closeModal();send('learn')end,
    practice=function()closeModal();send('practiceSolo')end,
    restore=function()shop:run(function()shop:request('restore')end)end,
    shop=function()return shop end,
    rules=function()selectedMap=multiplayerLobby.map;openModal('settings')end,
    setting=function(key,value)send('setting',key,value)end,
    settings=function()openModal('feedback')end,
    motions=function()if armsUI.motionWheel then armsUI.motionWheel:toggle()end end,
    help=function()openModal('help')end,
    credits=function()openModal('credits')end,
})
multiplayerLobby:setAccount(shop.account)
require(pack.Client.VipLock).bind(root,function()return shop end,function()return multiplayerLobby end,function()return state~=nil and state.phase~='menu'end)
armsUI.motionWheel=require(pack.Client.MotionWheel).new(root,function()return shop.account end,function()return state~=nil and not modal.Visible and not armsUI.drop.active and not (state.loading or armsUI.nuclear.active or armsUI.quick.frame.Visible or armsUI.chat.frame.Visible or armsUI.tactical.frame.Visible)and (state.phase=='menu'and not multiplayerLobby.page or state.phase=='playing'and not state.observer)end)
armsUI.motionShortcut=require(pack.Client.CornerShortcut).new(gamePanel,'MotionShortcut','M','motion',function()armsUI.motionWheel:toggle()end,'모션');require(pack.Client.VipLock).badge(armsUI.motionShortcut,'motion')
armsUI.resetCamera=function()renderer.yaw=0;renderer.tilt=math.rad(89.9);renderer.dropZoom=1;renderer.smoothDistance=nil end
armsUI.cameraShortcut=require(pack.Client.CornerShortcut).new(gamePanel,'CameraShortcut','Home','camera',armsUI.resetCamera,'시점 정렬 (Home)')
armsUI.tray=require(pack.Client.ShortcutTray).new(gamePanel,pauseButton,armsUI)
armsUI.hudScale=require(pack.Client.HudScale).new(gamePanel)
armsUI.refreshGuide=function()
    if not state then return end
    local info=selectedTile and terrainInfo(selectedTile)
    armsUI.coach:update(state,tutorial,{primary=confirmButton,troops=armsUI.growthBadge,trend=armsUI.lastRecruitment,action=action,sheet=sheet.Visible,enemyLand=info and info.land and owners[selectedTile]~=1,hudTop=controls.Visible and controls.Position.Y.Offset or nil,blocked=armsUI.drop.active or modal.Visible or armsUI.sheets:any() or armsUI.nuclear.active})
    local quick=armsUI.quickSpawn
    quick.Visible=state.phase=="spawn"and not armsUI.drop.active and not(state.guide and state.guide.intro)and not modal.Visible
    local left=state.spawnRemaining and state.spawnRemaining>0 and state.spawnRemaining or nil
    quick.Text=state.spawned and (state.allSpawned and string.format("모두 골랐어요, %d초 후 시작",left or 0) or string.format("다른 지휘관 기다리는 중 %d초",left or 0))or left and string.format("%d초 뒤 자동 배치",left)or "자동 배치로 빠른 시작"
    UI.enabled(quick,not state.spawned)
    armsUI.spawnCountdown:update(state,screenSize())
    if quick.Visible then local qw=math.min(300,screenSize().X-24);box(quick,(screenSize().X-qw)/2,math.max(60,controls.Position.Y.Offset-58),qw,48)end
end
task.spawn(function()
    while gui.Parent do
        local seen=armsUI.avatarSeen or setmetatable({},{__mode='k'});armsUI.avatarSeen=seen
        for _,player in ipairs(Players:GetPlayers()) do if player~=me and player.Character then
            local visible=roomVisible(player)and not renderer.dropActive;local key=tostring(visible)..':'..tostring(state and state.phase)
            local last=seen[player.Character]
            if last and last.key==key and os.clock()-last.at<5 then continue end
            seen[player.Character]={key=key,at=os.clock()}
            for _,part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.LocalTransparencyModifier=visible and 0 or 1
                elseif part:IsA("BillboardGui") then part.Enabled=visible==true and not (part.Name=="CommanderName" and state.phase~="menu") end
            end
        end end
        task.wait(.5)
    end
end)
pack:WaitForChild("Result").OnClientEvent:Connect(function(r)
    armsUI.telemetry.received(r)
    if state and r.version and r.version~=state.version then return end
    local request=armsUI.inputFlow:complete(r,state and state.version,os.clock())
    if request and pending[r.action]==r.requestId then pending[r.action]=nil end
    if armsUI.keys and r.requestId then for k,v in pairs(armsUI.keys)do if v==r.requestId then armsUI.keys[k]=nil end end end
    armsUI.nuclear:result(r)
    inbox:result(r)
    armsUI.commandFeedback:result(r,state and state.version,os.clock())
    if not r.ok then armsUI.audio.play("error");armsUI.veil.hide() end
    if r.ok and (r.action=="transport" or r.action=="moveWarship" or r.action=="cancelTransport" or r.action=="support") then armsUI.audio.play("attack") end
    if r.action=="pause" and queuedPause~=nil then local value=queuedPause;queuedPause=nil;task.delay(.12,function() send("pause",value) end) end
    if (not r.ok and not require(pack.Client.ActionReceipt).accepts(armsUI.commandFeedback.current,r,state and state.version)or r.action=="setting"or r.action=="preset"or r.action=='lobby')and r.message then notify(r.message,not r.ok) end
    if r.ok and r.action=='invite'and r.from and multiplayerLobby then require(pack.Client.InviteToast).show(multiplayerLobby,r) end
    if request and state.phase=='playing'and not modal.Visible and not armsUI.nuclear.active then
        local owner=request.restoreTile and (owners[request.restoreTile]or 0);local f=factions[owner]
        if require(pack.Client.ActionReceipt).canRestore(request,r,selectionRevision,state.version,armsUI.commandFeedback.current and armsUI.commandFeedback.current.id,owner,f and f.allied)then
            selectionRevision+=1;selectedTile=request.restoreTile;selectedUnit=nil;action=request.mode;menuAnchor=request.anchor;armsUI.moving=request.moving
            if request.unit then for _,u in ipairs(state.units or {})do if u.id==request.unit then selectedUnit=u;break end end end
            sheetMode=table.find(armsUI.rules.buildable,action)and 'placement'or selectedUnit and 'unit'or 'tile'
            armsUI.selectedRelation={owner=owner,allied=f and f.allied or false};gui:SetAttribute('SelectedTile',selectedTile)
            preview=nil;previewSerial+=1;refreshContext();if sheetMode=='tile'then armsUI.queryContext()end
        end
    end
    local sameSelection=armsUI.interaction.sameSelection(request,selectionRevision,selectedTile,action,selectedUnit and selectedUnit.id)
    if r.ok and sameSelection and table.find({'build','spawn','upgrade','alliance','support','moveWarship','cancelTransport'},r.action)then action="inspect";sheetMode=nil;preview=nil;previewSerial+=1;refreshSheet();refreshMarkers() end
    if not r.ok and request and request.selection==selectionRevision and request.tile==selectedTile then
        if r.action=='moveWarship'and action=='inspect'and not sheetMode then action=request.mode;armsUI.moving=request.moving;menuAnchor=request.anchor;sheetMode='tile' end
        if r.action=='build'and sameSelection then queryPreview()end
        refreshSheet();refreshMarkers()
    elseif request then refreshSheet()end
end)
function armsUI.shiftHeld()return UIS:IsKeyDown(Enum.KeyCode.LeftShift)or UIS:IsKeyDown(Enum.KeyCode.RightShift)end
function armsUI.ownerUnderCursor()
    local point=UIS:GetMouseLocation()-game:GetService('GuiService'):GetGuiInset()
    if blocked(point)then return nil end
    local tile=renderer:tileAt(point);local id=tile and owners[tile];return id and id~=0 and id~=1 and factions[id]or nil
end
function armsUI.autoUpgrade()
    local point=UIS:GetMouseLocation()-game:GetService('GuiService'):GetGuiInset()
    if not state or state.phase~="playing" or state.paused or not currentMap or blocked(point)then return end
    local tile=renderer:tileAt(point);if not tile then return end
    local width=currentMap.meta.width;local gold=tonumber(state.player and state.player.gold)or 0
    local best,bestD,short,shortD=nil,math.huge,nil,math.huge
    for _,u in ipairs(state.units or {})do
        if (u.owner or 1)==1 and armsUI.rules.upgradable[u.kind] and not u.building and u.active~=false then
            local dx,dy=u.tile%width-tile%width,math.floor(u.tile/width)-math.floor(tile/width);local d=dx*dx+dy*dy
            if d<=225 then
                if (tonumber(state.costs and state.costs[u.kind])or 0)<=gold then if d<bestD then best,bestD=u,d end
                elseif d<shortD then short,shortD=u,d end
            end
        end
    end
    if short and shortD<bestD then if armsUI.refuseCost then armsUI.refuseCost(short.kind)end;return end
    if best then send("upgrade",best.id);armsUI.audio.play("click")end
end
function armsUI.selectAllWarships()
    local list={};for _,u in ipairs(state and state.units or {})do if u.kind=="Warship"and (u.owner or 1)==1 and not u.building then table.insert(list,u.id)end end
    if #list==0 then notify("군함 없음");return end
    armsUI.nuclear:stop();armsUI.moving=#list==1 and list[1]or list;action="moveWarship";selectedUnit=nil;sheetMode=nil
    notify(string.format("군함 %d척  바다 선택",#list));refreshSheet()
end
UIS.InputBegan:Connect(function(input,processed)
    if processed or UIS:GetFocusedTextBox() or not gamePanel.Visible then return end
    if input.KeyCode==Enum.KeyCode.Home and not modal.Visible then armsUI.resetCamera();return end
    if input.UserInputType==Enum.UserInputType.MouseButton3 and not modal.Visible then armsUI.autoUpgrade();return end
    if input.KeyCode==Enum.KeyCode.P then if modal.Visible then closeModal() else openModal(state and (state.phase=='won'or state.phase=='lost')and not state.observer and 'result'or 'pause') end
    elseif modal.Visible then return
    elseif armsUI.drop.active then if input.KeyCode==Enum.KeyCode.Q or input.KeyCode==Enum.KeyCode.E then renderer:zoom(input.KeyCode==Enum.KeyCode.E and .83 or 1/.83)end;return
    elseif armsUI.motionWheel.frame.Visible then return
    elseif armsUI.sheets:key(input,armsUI.shiftHeld()) then return
    elseif table.find({Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four,Enum.KeyCode.Five,Enum.KeyCode.Six,Enum.KeyCode.Seven,Enum.KeyCode.Eight,Enum.KeyCode.Nine,Enum.KeyCode.Zero},input.KeyCode) then
        chooseBuild(armsUI.rules.buildable[table.find({Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four,Enum.KeyCode.Five,Enum.KeyCode.Six,Enum.KeyCode.Seven,Enum.KeyCode.Eight,Enum.KeyCode.Nine,Enum.KeyCode.Zero},input.KeyCode)])
    elseif input.KeyCode==Enum.KeyCode.C or input.KeyCode==Enum.KeyCode.V then
        chooseBuild(input.KeyCode==Enum.KeyCode.C and "City" or "DefensePost")
    elseif input.KeyCode==Enum.KeyCode.Q or input.KeyCode==Enum.KeyCode.E then renderer:zoom(input.KeyCode==Enum.KeyCode.E and .83 or 1/.83)
    elseif (input.KeyCode==Enum.KeyCode.G or input.KeyCode==Enum.KeyCode.B) and state and state.phase=="playing" then
        local point=UIS:GetMouseLocation()-game:GetService('GuiService'):GetGuiInset()
        if blocked(point)then return end
        local tile=renderer:tileAt(point);local info=tile and terrainInfo(tile)
        if not info or not info.land or info.impassable then return end
        if input.KeyCode==Enum.KeyCode.B then if owners[tile]~=1 then send("transport",fraction,tile)end
        else send("attack",fraction,owners[tile]~=1 and tile or nil)end
    elseif input.KeyCode==Enum.KeyCode.Space and state and state.phase~="menu" then local at=os.clock();renderer.spaceAt=at;task.delay(.4,function()if renderer.spaceAt==at and UIS:IsKeyDown(Enum.KeyCode.Space)then renderer:setAltView(true)end end)
    elseif input.KeyCode==Enum.KeyCode.F and armsUI.shiftHeld() and state and state.phase=="playing" then armsUI.selectAllWarships()
    elseif input.KeyCode==Enum.KeyCode.F then armsUI.confirmCurrent()
    elseif input.KeyCode==Enum.KeyCode.R and armsUI.shiftHeld() and state and state.phase=="playing" then send("retaliate",fraction)
    elseif input.KeyCode==Enum.KeyCode.R and state and state.phase=='playing'then
        local f=armsUI.ownerUnderCursor();armsUI.chat:messages(f and f.id)
    elseif input.KeyCode==Enum.KeyCode.Z and state and state.phase=='playing'then
        local f=armsUI.ownerUnderCursor();armsUI.chat.openQuick('emoji',f and f.id or 0)
    elseif (input.KeyCode==Enum.KeyCode.K or input.KeyCode==Enum.KeyCode.L and armsUI.shiftHeld()) and state and state.phase=="playing" then
        local f=armsUI.ownerUnderCursor();if not f then return end
        if input.KeyCode==Enum.KeyCode.L then if f.allied then send("alliance","break",f.id)end
        elseif f.allied then send("alliance","extend",f.id)elseif f.incomingRequest then send("alliance","accept",f.id)else send("alliance","request",f.id)end
    elseif input.KeyCode==Enum.KeyCode.U then if armsUI.nuclear.active and armsUI.nuclear.kind~="MIRV" then armsUI.nuclear.up=not armsUI.nuclear.up;armsUI.nuclear:recalculate(true)end
    elseif (input.KeyCode==Enum.KeyCode.Comma or input.KeyCode==Enum.KeyCode.Period) and state and not state.multiplayer and state.phase=="playing" then
        local steps={.5,1,2,4};local i=table.find(steps,state.speed or 1)or 2
        send("speed",steps[math.clamp(i+(input.KeyCode==Enum.KeyCode.Period and 1 or -1),1,#steps)])
    elseif input.KeyCode==Enum.KeyCode.X then
        selectionRevision+=1;armsUI.lastTap=nil
        armsUI.nuclear:stop()
        action="inspect";sheetMode=nil;preview=nil;selectedTile=nil;selectedUnit=nil;previewSerial+=1;refreshContext()
    elseif input.KeyCode==Enum.KeyCode.T then
        local steps=require(pack.Client.CommandBar).PRESETS;local index=(table.find(steps,fraction) or 1)%#steps+1
        setFraction(steps[index])
    elseif input.KeyCode==Enum.KeyCode.L then armsUI.sheets:open("ranks")
    elseif input.KeyCode==Enum.KeyCode.Y and state and state.phase=='playing'then
        local f=selectedTile and factions[owners[selectedTile]]
        if f and f.id~=1 then sheetMode=nil;refreshSheet();armsUI.tactical:open(f.id,'signals',selectedTile)end
    elseif input.KeyCode==Enum.KeyCode.H then home() end
end)
root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() layout() end)
armsUI.input.changed:Connect(function() hover.Visible=false;applyScale();layout();refreshContext();dirty=true end)
armsUI.probe=require(pack.Client.FrameProbe)
RunService:BindToRenderStep('HUD',202,function(dt)
    local P=armsUI.probe;P.start('HUD')
    if armsUI.motionWheel then armsUI.motionWheel:step()end
    if notices:step(os.clock())then showNotice()end
    if armsUI.lobbyStale and multiplayerLobby and multiplayerLobby.frame.Visible then armsUI.lobbyStale=false;multiplayerLobby:layout()end
    if armsUI.markersWanted and not gamePanel.Visible then armsUI.drawMarkers()end
    if commanders.active and (not state or state.phase=="menu") then commanders:update(state,roomVisible,0) end
    P.start('HUD.commanders');commanders:step(dt,effects.reduced);P.stop('HUD.commanders')
    if loadingUI.frame and loadingUI.frame.Visible then
        local LU=loadingUI;LU.clock+=dt
        LU.scan.Position=UDim2.fromScale((LU.clock*.6)%1.3-.3,0)
        if LU.tip==0 or LU.clock-LU.tip>3 then LU.tip=LU.clock;LU.hint.Text=LU.tips[math.floor(LU.clock/3)%#LU.tips+1] end
        local key=state and (state.loadingMap or state.phase~='menu'and state.map)
        local meta=key and Maps.meta(key)
        LU.title.Text=meta and meta.label or "작전 지도를 펼치는 중…";gui:SetAttribute('LoadingMap',meta and L.text(meta.label)or nil)
    end
    if not armsUI.lobbyReadyReported and state and state.phase=='menu'and not state.loading and not LobbyIntro.active and multiplayerLobby and multiplayerLobby.frame.Visible and os.clock()-(armsUI.lobbyReadySent or -1e9)>2 then
        armsUI.lobbyReadySent=os.clock();armsUI.experienceReady:FireServer(state.version)
    end
    if not armsUI.autoLesson and armsUI.lobbyReadyReported and state and state.phase=='menu'and not state.loading and armsUI.lobbyLanded and os.clock()-math.max(armsUI.lobbyLanded,multiplayerLobby and multiplayerLobby.readyAt or 0)<20 and not LobbyIntro.active
        and multiplayerLobby and multiplayerLobby.frame.Visible and not multiplayerLobby.busy and not multiplayerLobby.page and not(multiplayerLobby.deployment and multiplayerLobby.deployment.expanded)and multiplayerLobby.firstLesson and not (multiplayerLobby.data and (multiplayerLobby.data.queue or multiplayerLobby.data.inviteRoomCode or multiplayerLobby.data.partyHost))and armsUI.rookie(multiplayerLobby.account.progress)
        and next(multiplayerLobby.account.progress.history or {})==nil and not modal.Visible and not armsUI.sheets:any()and not(multiplayerLobby.home and multiplayerLobby.home.listOpen)then
        armsUI.autoLesson=true;pcall(armsUI.telemetry.step,'tutorial','autoLesson',{result='opened'})
        task.delay(.4,function()if state and state.phase=='menu'and multiplayerLobby.firstLesson and not multiplayerLobby.busy and not multiplayerLobby.page and not(multiplayerLobby.deployment and multiplayerLobby.deployment.expanded)and not(multiplayerLobby.data and multiplayerLobby.data.queue)and not modal.Visible then send('learn')end end)
    end
    if armsUI.resultSeen and state and state.phase=='menu'and not state.loading and multiplayerLobby and multiplayerLobby.frame.Visible and multiplayerLobby.account.ready then
        armsUI.resultSeen=false
        local games=armsUI.games(multiplayerLobby.account.progress);local party=multiplayerLobby.data and multiplayerLobby.data.party
        if not armsUI.favoriteAsked and games==5 then armsUI.favoriteAsked=true
            task.delay(1.5,function()pcall(function()game:GetService('AvatarEditorService'):PromptSetFavorite(game.PlaceId,Enum.AvatarItemType.Asset,true)end)end)
        elseif not armsUI.notifyAsked and party and #party.users>1 then armsUI.notifyAsked=true
            task.spawn(function()local service=game:GetService('ExperienceNotificationService')
                local ok,can=pcall(function()return service:CanPromptOptInAsync()end);if ok and can then task.wait(1.5);pcall(function()service:PromptOptIn()end)end end)
        end
    end
    if not gamePanel.Visible and me.Character then
        local hum=me.Character:FindFirstChildOfClass('Humanoid');local body=me.Character:FindFirstChild('HumanoidRootPart')
        if hum and body then
            hum.CameraOffset=Vector3.zero
        end
    end
    P.start('HUD.overlay');renderer.annotationBounds=armsUI.worldOverlay:sync(gamePanel.Visible);P.stop('HUD.overlay')
    if gamePanel.Visible then
        armsUI.commandFeedback:step(modal.Visible or armsUI.sheets:any())
        armsUI.resolveOverlays()
        root.LoadingCover.Visible=not renderer:isReady()or(state~=nil and state.phase~="menu"and state.version~=currentVersion)
        if dirty and os.clock()-lastDraw>.12 then dirty=false;lastDraw=os.clock();renderer:draw() end
        P.start('HUD.markers');armsUI.drawMarkers();P.stop('HUD.markers')
        if armsUI.cameraGuard:step(sheet.Visible and (sheetMode=="tile" or sheetMode=="unit"),selectedTile,selectionRevision)then armsUI.closeSheet()end
        positionSheet()
        P.start('HUD.battle');battle:step();P.stop('HUD.battle')
armsUI.matchStatus:step(modal.Visible or armsUI.nuclear.active,false)
        armsUI.chat:step()
        armsUI.drop:step(dt,modal.Visible)
        pauseButton.Visible=not armsUI.drop.introActive and armsUI.tray.menuShown~=false
        armsUI.feedback.obscured=armsUI.feedback:covered(modal.Visible or armsUI.sheets:any(),sheet.Visible or inbox.request~=nil or hover.Visible or #battle.incoming>0)
        P.start('HUD.feedback');armsUI.feedback:step(dt);P.stop('HUD.feedback')
        if os.clock()-(armsUI.guideAt or 0)>.1 then armsUI.guideAt=os.clock();armsUI.refreshGuide()end
        armsUI.coach:stepFrame(effects.reduced)
    end
    P.stop('HUD')
end)
pack:WaitForChild("VisualEvent").OnClientEvent:Connect(function(e) effects:receive(e) end)
layout()
pack:WaitForChild("State").OnClientEvent:Connect(function(v)armsUI.probe.start("Snapshot");render(v);armsUI.probe.stop("Snapshot")end)
require(pack.Client.MapStuck).attach(root.LoadingCover,{inMatch=function()return state~=nil and state.phase~="menu"end,retry=function()task.spawn(function()local ok,f=pcall(read.InvokeServer,read);if ok then render(f)end end)end,lobby=function()armsUI.veil.show("로비로 이동 중…");send("menu")end})
bootClocks[3]=os.clock()
task.spawn(function() local ok,s=pcall(function() return read:InvokeServer() end);if ok then render(s) else notify("서버 연결 실패",true) end end)
