local Service=game:GetService("SoundService")
local Run=game:GetService("RunService")
local M={};local last={};local voices={};local queue={};local random=Random.new()
local AudioFocus=require(script.Parent.AudioFocus);local focus=AudioFocus.new()
local folder=Instance.new("Folder");folder.Name="ToySoundstage";folder.Parent=Service
local PSE={computerTone=9113462855,uiCluster=9120149503,relayBeeps=9125539780,distantBlast=9114362114,deepBoom=9125484367,metalClunk=9125665221,
    fallingBeeps=9125540235,dullPop=9119717950,graphicBeep=9114642723,toneBurst=9119834422,toneDing=9126073644,whoosh=9120708588,powerUp=9117884499,
    buzzyBeep=9113401879,generalQuarters=9119662239,jetWhoosh=9126010351,mortar=9116973350,subPop=9126009571,distantBoom=9125402735,
    bellDing=9126073001,subThump=9126009638,quindar=9117060347,coins=9125726281,fuzzyBeep=9113402326,powerDown=9117869243,highBeep=9119141871,
    sirenBlat=9119160366,powerUpRise=9117885256,bassDrum=9113343286,
    clothFlap=9113818304,bodyImpact=9113524242,spaceshipPass=9119414209,airMassPass=9114376735,
    radioKey=9120456889,hammer=9114756156,ratchet=9118046636}
local APM={electionSting=9042408957,electionFanfare=9042409054,electionEnd=9042409272,tuttiStabs=1846902219,villainy=1846902163,priceOfWar=111160276565128,runForth=9043511976}
local presets={
    supplyDelivery={PSE.jetWhoosh,.65,.15,.85,.2,2},supplySeal={PSE.metalClunk,.8,.12,.4,.2,2},
    supply_normal={PSE.toneDing,1,.12,.45,.2,2},supply_rare={PSE.bellDing,1.15,.16,.65,.2,2},
    supply_epic={PSE.powerUpRise,1.1,.18,1,.2,3},supply_legendary={APM.electionSting,1,.22,1.3,.2,3},
    supply_mythic={APM.electionFanfare,.95,.24,2,.2,3},collectionLegendary={PSE.bellDing,.85,.08,.7,5,1},collectionMythic={PSE.powerUpRise,.8,.09,1,5,1},
    dropExit={PSE.jetWhoosh,.72,.6,1.7,2,3},
    dropReveal={APM.electionSting,.9,.55,1.15,2,3},
    dropJets={PSE.spaceshipPass,1,.5,2.6,1.5,3},dropCloud={PSE.airMassPass,1.1,.45,1.4,2,2},
    dropDeploy={PSE.clothFlap,.75,.55,1.1,1,3},dropLand={PSE.bodyImpact,.8,.6,1.3,1,3},
    click={PSE.computerTone,1.15,1,.3,.18,0},
    orderTap={PSE.radioKey,1.05,1,.28,.06,1},
    attackLight={PSE.whoosh,1.12,1,.42,.12,2},
    attack={PSE.whoosh,1,1,.5,.12,2},
    attackHeavy={PSE.whoosh,.88,1,.7,.12,2},
    orderDrum={PSE.bassDrum,1.25,1,.5,.12,2},
    orderImpact={PSE.bassDrum,.95,1,1.1,.3,2},
    build={PSE.metalClunk,1.25,1,.38,.15,2},
    buildHammer={PSE.hammer,1.1,1,.45,.15,2},
    buildRatchet={PSE.ratchet,1,1,.5,.15,2},
    buildHeavy={PSE.metalClunk,.9,1,.5,.15,2},
    upgrade={PSE.powerUpRise,1.25,1,.6,.3,2},
    block={PSE.dullPop,1,1,.3,.18,0},
    capture={PSE.fallingBeeps,1,1,.3,1.2,1},
    pop={PSE.graphicBeep,1,1,.3,.12,0},
    combo={PSE.toneBurst,1,1,.6,.6,2},
    milestone={PSE.toneDing,1.18,.3,.6,2,3},
    grow={PSE.toneDing,1,1,.7,1.5,2},
    complete={PSE.powerUp,1,1,.9,.4,2},
    trade={PSE.coins,1,1,.6,2,0},
    incoming={PSE.buzzyBeep,1,1,.9,3,3},
    rocketWarning={PSE.generalQuarters,1,1,2.1,4,4},
    request={PSE.quindar,1,1,.6,2,2},
    allied={PSE.bellDing,1,1,1.2,1,3},
    allianceEnded={PSE.powerDown,1,1,1.2,1,2},
    betrayal={APM.villainy,1,1,2.6,2,4},
    conquest={APM.electionSting,1.05,1,1.6,1.5,3},
    countdown={PSE.highBeep,1,0.99,.4,.5,3},
    assault={PSE.sirenBlat,1,1,1.2,4,4},
    rankUp={PSE.powerUpRise,1,1,1.1,2,3},
    timeUp={PSE.bassDrum,1,1,2.5,5,4},
    eliminated={PSE.distantBoom,1,1,3,1.5,3},
    launch={PSE.jetWhoosh,1,1,1.4,.8,2},
    detonate={PSE.distantBlast,1,1,2.4,1,3},
    distant={PSE.distantBlast,.8,1,2.4,.5,1},
    nuke={PSE.deepBoom,1,1,4.2,3,4},
    stinger={PSE.deepBoom,1.05,1,3.2,8,5},
    confirm={PSE.relayBeeps,1,1,.41,.6,1},
    intercept={PSE.mortar,1,1,.7,.35,3},
    shell={PSE.subPop,1.1,0.46,.5,.25,0},
    error={PSE.fuzzyBeep,1,1,.4,.8,1},
    start={APM.tuttiStabs,1,1,3,2,3},
    victory={APM.electionFanfare,1,1,6,5,5},
    defeat={APM.priceOfWar,1,1,6,5,5},
}
local W,BD=PSE.whoosh,PSE.bassDrum
M.packs={
    A={orderTap={9125700102,.85,.3},attackLight={W,.85,.42},attack={W,.8,.5},attackHeavy={W,.72,.7},orderDrum={9113525643,.85,.5},orderImpact={9113437465,.8,1},
        build={PSE.metalClunk,.85,.4},buildHammer={PSE.hammer,.9,.45},buildRatchet={PSE.ratchet,.85,.5},buildHeavy={9119632615,.85,.6},upgrade={9119632615,.8,.7}},
    B={orderTap={9114725075,.9,.32},attackLight={W,.85,.42},attack={W,.8,.5},attackHeavy={W,.72,.7},orderDrum={BD,.95,.6},orderImpact={9039276121,.85,1.6},
        build={PSE.metalClunk,.85,.4},buildHammer={PSE.hammer,.9,.45},buildRatchet={9113104358,.9,.5},buildHeavy={BD,.8,.6},upgrade={9113104358,.8,.7}},
    C={orderTap={9125921140,.85,.28},attackLight={W,.85,.42},attack={1837831061,.95,.8},attackHeavy={1837831061,.85,1},orderDrum={BD,.9,.5},orderImpact={1839571500,.9,1.6},
        build={9116700611,.85,.45},buildHammer={PSE.hammer,.9,.45},buildRatchet={PSE.ratchet,.85,.5},buildHeavy={9116700611,.75,.6},upgrade={1841717931,.9,1.6}},
    D={orderTap={PSE.radioKey,.84,.3},attackLight={W,.9,.42},attack={W,.8,.5},attackHeavy={W,.72,.7},orderDrum={BD,1,.5},orderImpact={BD,.8,1.1},
        build={PSE.metalClunk,1,.4},buildHammer={PSE.hammer,.9,.45},buildRatchet={PSE.ratchet,.85,.5},buildHeavy={PSE.metalClunk,.75,.5},upgrade={PSE.powerUpRise,1,.6}},
}
M.pack='B'
local function usePack(name)
    for kind,o in pairs(M.packs[name]or {})do local c=presets[kind];if c then c[1]=o[1];c[2]=o[2];c[4]=o[3]end end
end
usePack(M.pack)
local fallback={
    supplyDelivery={'action_falling.ogg',.8,.1,.8,.2,2},supplySeal={'action_jump_land.mp3',.8,.08,.3,.2,2},
    supply_normal={'volume_slider.ogg',1,.09,.3,.2,2},supply_rare={'volume_slider.ogg',1.2,.1,.4,.2,2},
    supply_epic={'volume_slider.ogg',1.4,.12,.5,.2,3},supply_legendary={'volume_slider.ogg',1.6,.14,.7,.2,3},supply_mythic={'volume_slider.ogg',1.8,.16,1,.2,3},
    collectionLegendary={'volume_slider.ogg',.9,.07,.3,5,1},collectionMythic={'volume_slider.ogg',1.1,.08,.4,5,1},
    dropExit={"action_falling.ogg",.8,.15,1.7,2,3},
    dropReveal={"volume_slider.ogg",.8,.09,.4,2,3},
    dropJets={"action_falling.ogg",1.3,.1,1.2,1.5,3},dropCloud={"action_falling.ogg",1.6,.08,.8,2,2},
    dropDeploy={"action_jump_land.mp3",.6,.12,.4,1,3},dropLand={"action_jump_land.mp3",.5,.15,.5,1,3},
    block={"action_jump_land.mp3",2.7,.045,.15,.18,0},
    orderTap={"volume_slider.ogg",1.6,.1,.12,.06,1},attackLight={"action_falling.ogg",2.2,.08,.4,.12,2},attackHeavy={"action_falling.ogg",1.7,.12,.6,.12,2},
    orderDrum={"action_jump_land.mp3",.7,.1,.3,.12,2},orderImpact={"action_jump_land.mp3",.5,.16,.5,.3,2},
    buildHammer={"action_jump_land.mp3",1.9,.1,.3,.15,2},buildRatchet={"action_jump_land.mp3",2.3,.08,.3,.15,2},buildHeavy={"action_jump_land.mp3",1.2,.12,.35,.15,2},
    capture={"volume_slider.ogg",1.35,.065,.19,1.2,1},
    pop={"action_jump_land.mp3",2.6,.05,.12,.12,0},
    combo={"volume_slider.ogg",1.2,.09,.2,.6,2},
    milestone={"volume_slider.ogg",1.1,.13,.22,2,3},
    grow={"volume_slider.ogg",.9,.12,.2,1.5,2},
    complete={"action_jump_land.mp3",1.9,.17,.34,.4,2},
    trade={"volume_slider.ogg",1.8,.05,.13,2,0},
    incoming={"volume_slider.ogg",.8,.12,.18,3,3},
    rocketWarning={"volume_slider.ogg",.65,.15,.22,4,4},
    request={"volume_slider.ogg",1.15,.085,.18,2,2},
    allianceEnded={"volume_slider.ogg",.8,.085,.18,1,2},
    betrayal={PSE.subThump,1,.5,.8,2,4},
    assault={"volume_slider.ogg",.65,.15,.22,4,4},
    eliminated={"action_jump_land.mp3",.85,.09,.32,1.5,2},
    launch={"action_falling.ogg",2,.08,.5,.8,2},
    intercept={"action_jump_land.mp3",2.9,.08,.2,.35,3},
    shell={"action_jump_land.mp3",2.5,.055,.16,.25,0},
    error={"volume_slider.ogg",.65,.06,.12,.8,1},
    victory={"volume_slider.ogg",1,.16,.24,5,5},
    defeat={"volume_slider.ogg",.85,.11,.26,5,5},
}
local gains={click=.12,attack=.28,attackLight=.24,attackHeavy=.32,orderTap=.26,orderDrum=.18,orderImpact=.30,
    build=.26,buildHammer=.26,buildRatchet=.24,buildHeavy=.28,upgrade=.26,block=0,pop=0,combo=0,capture=.10,trade=0,
    milestone=.14,tiles=.12,grow=.14,complete=.22,incoming=.28,rocketWarning=.34,request=.20,allied=.20,allianceEnded=.20,
    betrayal=.36,countdown=.12,assault=.28,rankUp=.14,timeUp=.30,eliminated=.14,launch=.20,detonate=.30,distant=.14,conquest=.32,
    nuke=.34,stinger=.22,confirm=.14,intercept=.16,shell=0,error=.16,start=.26,victory=.36,defeat=.32,dropExit=.25,dropReveal=.22,dropJets=.24,dropCloud=.18,dropDeploy=.3,dropLand=.32}
for _,list in ipairs({presets,fallback})do for kind,c in pairs(list)do if gains[kind]then c[3]=math.min(c[3],gains[kind])end end end
local melodies={grow={1,1.33,1.78},combo={1,1.5},milestone={1,1.5},eliminated={1.5,1.25,1},complete={1,1.25,1.5},allied={1,1.25,1.5},request={1,1.3},incoming={1,1},rocketWarning={1,1,1},start={1,1.25,1.5},victory={1,1.25,1.5,2},defeat={1,.85,.67}}
local function content(file) return type(file)=="number" and "rbxassetid://"..file or "rbxasset://sounds/"..file end
M.configuredPresets={};for kind,c in pairs(presets)do M.configuredPresets[kind]=table.freeze(table.clone(c))end;table.freeze(M.configuredPresets)
task.spawn(function()
    local assets={};local added={};local failed={}
    for _,list in ipairs({presets,fallback})do for _,c in pairs(list)do if not added[c[1]]then
        added[c[1]]=true;local sound=Instance.new('Sound');sound.Name='Preload';sound.SoundId=content(c[1]);sound.Parent=folder;table.insert(assets,sound)
    end end end
    pcall(function()game:GetService("ContentProvider"):PreloadAsync(assets,function(id,status) if status==Enum.AssetFetchStatus.Failure then failed[id]=true end end)end)
    for _,sound in ipairs(assets)do if sound.IsLoaded then failed[sound.SoundId]=nil end;sound:Destroy()end
    for kind,c in pairs(presets) do if failed[content(c[1])] and fallback[kind] then presets[kind]=fallback[kind] end end
    local count=0;for _ in pairs(failed) do count+=1 end;folder:SetAttribute("FailedAssets",count)
end)
for i=1,8 do local sound=Instance.new("Sound");sound.Name="Voice"..i;sound.Parent=folder;voices[i]={sound=sound,untilTime=0,priority=-1} end
local function note(c,pitch,volume,kind,layered)
    local now=os.clock();local voice
    if c[6]<=2 then local soft=0;for _,v in ipairs(voices)do if now<v.untilTime and v.priority<=2 then soft+=1 end end;if soft>=(layered and 6 or 2) then return end end
    for _,v in ipairs(voices) do if now>=v.untilTime then voice=v;break elseif v.priority<c[6] and (not voice or v.priority<voice.priority) then voice=v end end
    if not voice then return end
    local sound=voice.sound;sound:Stop();sound.SoundId=content(c[1]);sound.PlaybackSpeed=c[2]*pitch;sound.Volume=c[3]*volume*(Service:GetAttribute("ToySoundsVolume") or 1);sound:SetAttribute("Cue",kind);sound.TimePosition=0
    voice.startedAt=now;voice.untilTime=now+c[4];voice.fade=c[4]>1.5 and .6 or .05;voice.priority=c[6];voice.volume=sound.Volume;sound.Volume=0;sound:Play()
    folder:SetAttribute("LastCue",kind);folder:SetAttribute("CueCount",(folder:GetAttribute("CueCount") or 0)+1)
end
function M.reset()
    focus:reset();M.lastSoft=nil
    table.clear(queue);table.clear(last)
    for _,v in ipairs(voices) do v.sound:Stop();v.untilTime=0 end
end
function M.stop(kind)
    for i=#queue,1,-1 do if queue[i].kind==kind then table.remove(queue,i)end end
    for _,v in ipairs(voices)do if v.sound:GetAttribute('Cue')==kind then v.sound:Stop();v.untilTime=0 end end
end
function M.telemetry()
    local highest=-1;for _,n in ipairs(queue)do highest=math.max(highest,n.config[6])end
    return {queued=#queue,highestQueued=highest,active=folder:GetAttribute('ActiveVoices')or 0,lastCue=folder:GetAttribute('LastCue'),cueCount=folder:GetAttribute('CueCount')or 0}
end
function M.has(kind) return presets[kind]~=nil end
function M.play(kind,strength,pitch,layered)
    local c=presets[kind];local now=os.clock()
    if kind=='orderTap'and not M.packLogged then M.packLogged=true;pcall(function()require(script.Parent.TelemetryStep).step('match','orderSound',{item='pack_'..tostring(M.pack)})end)end
    if gains[kind]==0 or not c or Service:GetAttribute("ToySoundsMuted") or now-(last[kind] or -1e9)<c[5] then return end
    if not layered then
        if not focus:admit(kind,c[6],now)then return end
        if c[6]<=2 and now-(M.lastSoft or -1e9)<.16 then return end
        if c[6]<=2 then M.lastSoft=now end
    end
    last[kind]=now;strength=math.clamp(strength or 1,0,1);pitch=math.clamp(pitch or 1,.5,2)
    if c[6]>=4 then for i=#queue,1,-1 do if queue[i].config[6]<c[6]then table.remove(queue,i)end end end
    local motif=type(c[1])=="string" and melodies[kind]
    if motif then
        for i,step in ipairs(motif) do
            if #queue>=16 then break end
            local tone=table.clone(c);tone[1]="volume_slider.ogg"
            table.insert(queue,{at=now+(i-1)*(kind=="combo" and .07 or .14),config=tone,pitch=step*pitch,strength=strength,kind=kind})
        end
        if kind=="complete" or kind=="eliminated" then note(c,pitch,strength,kind) end
    else note(c,(kind=="block" or kind=="pop") and random:NextNumber(.94,1.06)*pitch or pitch,strength,kind,layered) end
end
local intent,streak={},{n=0,at=-1e9,kind=''}
local tools={City='buildHammer',Port='buildHammer',DefensePost='buildHeavy',MissileSilo='buildHeavy',SAMLauncher='buildRatchet',Factory='buildRatchet',Warship='buildRatchet'}
local function vary(kind)
    local now=os.clock();if streak.kind==kind and now-streak.at<1.5 then streak.n=math.min(streak.n+1,6)else streak.n=0 end
    streak.kind=kind;streak.at=now;return random:NextNumber(.96,1.04)*(1+streak.n*.025)
end
function M.press(action,description)
    intent[action]={ratio=description and description.ratio,building=description and description.icon}
    M.play('orderTap',1,random:NextNumber(.95,1.05),true)
end
local gesture
local function hitDelay(kind,again)
    if gesture==nil then
        local core=script.Parent.Parent:FindFirstChild('Core');local m=core and core:FindFirstChild('CommandGesture')
        local ok,g=pcall(function()return m and require(m)end);gesture=ok and g or false
    end
    local k=gesture and gesture.kinds and gesture.kinds[kind];if not k then return 0 end
    return math.max(0,(k.flash or 0)-(again and k.jab or 0))
end
local function at(delay,kind,strength,pitch)
    if delay<=.01 then M.play(kind,strength,pitch,true)else task.delay(delay,M.play,kind,strength,pitch,true)end
end
function M.order(kind)
    local pitch=vary(kind);local i=intent[kind]or {};local hit=hitDelay(kind,streak.n>0)
    if kind=='attack'then
        local share=i.ratio or .2
        if share<.15 then M.play('attackLight',1,pitch,true)
        elseif share<.4 then M.play('attack',1,pitch,true);at(hit,'orderDrum',1,pitch)
        else M.play('attackHeavy',1,pitch,true);at(hit,'orderImpact',1,pitch)end
    elseif kind=='build'then at(hit,tools[i.building]or 'buildHammer',1,pitch);at(hit,'build',.6,pitch)
    elseif kind=='upgrade'then M.play('upgrade',1,pitch,true);at(hit,'build',.5,pitch*1.15)
    else M.play(kind)end
end
local ambience
function M.ambience(on)
    if not ambience then
        ambience=Instance.new("Sound");ambience.Name="HQAmbience";ambience.SoundId="rbxassetid://9112839511";ambience.Looped=true;ambience.Volume=0;ambience.PlaybackSpeed=.8;ambience.Parent=folder
    end
    local want=on==true and not Service:GetAttribute("ToySoundsMuted")
    if want and not ambience.Playing then ambience:Play() end
    if not want and not ambience.Playing then return end
    local tween=game:GetService("TweenService"):Create(ambience,TweenInfo.new(1.2),{Volume=want and .05 or 0});tween:Play()
    if not want then tween.Completed:Once(function() if ambience.Volume<=.001 then ambience:Stop() end end) end
end
Service:GetAttributeChangedSignal("ToySoundsMuted"):Connect(function()
    if Service:GetAttribute("ToySoundsMuted") then M.reset();if ambience then ambience:Stop();ambience.Volume=0 end end
end)
Run.Heartbeat:Connect(function()
    local now=os.clock();local count=0
    for i=#queue,1,-1 do local n=queue[i];if now>=n.at then if not AudioFocus.stale(now,n.at,n.config[6])then note(n.config,n.pitch,n.strength,n.kind)end;table.remove(queue,i) end end
    local priority=-1
    for _,v in ipairs(voices)do if v.untilTime>now then priority=math.max(priority,v.priority)end end
    for _,v in ipairs(voices) do
        local left=v.untilTime-now
        if left<=0 then if v.sound.Playing then v.sound:Stop() end
        else count+=1;v.sound.Volume=v.volume*math.min(1,(now-(v.startedAt or now))/.035)*math.min(1,left/(v.fade or .05))*(priority>=4 and v.priority<=2 and .2 or priority>=3 and v.priority<=1 and .35 or 1) end
    end
    folder:SetAttribute("ActiveVoices",count)
    folder:SetAttribute('QueuedNotes',#queue);folder:SetAttribute('HighestPriority',priority)
end)
M.presets=presets
function M.usePack(name)if M.packs[name]then M.pack=name;usePack(name)end end
if Run:IsStudio() and Run:IsClient() then
    local function audition() if workspace:GetAttribute("SoundAudition")==true then require(script.Parent.SoundAudition).open(M) end end
    workspace:GetAttributeChangedSignal("SoundAudition"):Connect(audition);task.defer(audition)
end
return M
