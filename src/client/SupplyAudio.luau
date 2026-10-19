local Service=game:GetService('SoundService')
local Run=game:GetService('RunService')
local M={}
local ids={
    toneDing=9126073644,bellDing=9126073001,powerUpRise=9117885256,metalClunk=9125665221,subThump=9126009638,
    deepBoom=9125484367,jetWhoosh=9126010351,whoosh=9120708588,powerDown=9117869243,graphicBeep=9114642723,
    computerTone=9113462855,electionSting=9042408957,electionFanfare=9042409054,
}
local folder;local voices={};local pending={};local connection
local function stepVoices()
    local now=os.clock()
    for i=#pending,1,-1 do local n=pending[i];if now>=n.at then table.remove(pending,i);n.play()end end
    local busy=#pending>0
    for _,v in ipairs(voices)do
        local left=v.untilTime-now
        if left<=0 then if v.sound.Playing then v.sound:Stop()end
        else busy=true;v.sound.Volume=v.volume*math.min(1,(now-v.started)/.03)*math.min(1,left/v.fade)end
    end
    if not busy and connection then connection:Disconnect();connection=nil end
end
local function ensure()
    if not(folder and folder.Parent)then
        folder=Instance.new('Folder');folder.Name='SupplyScore';folder.Parent=Service;voices={}
        for i=1,8 do local s=Instance.new('Sound');s.Name='Voice'..i;s.Parent=folder;voices[i]={sound=s,untilTime=0,started=0,volume=0,fade=.05}end
    end
    if not connection then connection=Run.Heartbeat:Connect(stepVoices)end
end
local function voice(id,pitch,volume,length)
    if Service:GetAttribute('ToySoundsMuted')then return end
    ensure();local now=os.clock();local v
    for _,c in ipairs(voices)do if now>=c.untilTime then v=c;break end end
    if not v then v=voices[1];for _,c in ipairs(voices)do if c.untilTime<v.untilTime then v=c end end end
    local s=v.sound;s:Stop();s.SoundId='rbxassetid://'..ids[id];s.PlaybackSpeed=pitch;s.TimePosition=0
    v.volume=volume*(Service:GetAttribute('ToySoundsVolume')or 1);v.started=now;v.untilTime=now+length;v.fade=length>1.2 and .5 or .08
    s.Volume=0;s:Play()
end
local function layers(list)
    ensure();local now=os.clock()
    for _,l in ipairs(list)do
        if l[1]<=0 then voice(l[2],l[3],l[4],l[5])
        else table.insert(pending,{at=now+l[1],play=function()voice(l[2],l[3],l[4],l[5])end})end
    end
end
local triad={1,1.26,1.5,2}
local lampChime={
    {{0,'toneDing',.9,.3,.6}},
    {{0,'bellDing',1,.34,.8}},
    {{0,'bellDing',1.12,.36,.9},{.06,'toneDing',1.5,.18,.6}},
    {{0,'bellDing',1.26,.38,1},{.06,'toneDing',1.68,.22,.7}},
    {{0,'bellDing',1.5,.4,1.2},{.05,'toneDing',2,.22,.8},{.1,'bellDing',1,.28,1}},
}
local reveal={
    {{0,'toneDing',1,.45,.9}},
    {{0,'bellDing',1,.45,1.2},{.12,'toneDing',1.5,.3,.9}},
    {{0,'powerUpRise',1.05,.38,1.1},{.35,'bellDing',1.12,.45,1.3},{.5,'bellDing',1.68,.3,1}},
    {{0,'electionSting',1,.5,1.5},{0,'subThump',.8,.45,.9}},
    {{0,'electionFanfare',.95,.55,2.4},{0,'deepBoom',.85,.45,1.8},{.1,'powerUpRise',1.2,.3,1.2}},
}
for i,step in ipairs(triad)do
    if i<=3 then table.insert(reveal[4],{.5+(i-1)*.12,'bellDing',step,.32,.9})end
    table.insert(reveal[5],{.7+(i-1)*.12,'bellDing',step,.34,1.1})
end
function M.ready()
    local stage=Service:FindFirstChild('ToySoundstage')
    return not(stage and(stage:GetAttribute('FailedAssets')or 0)>0)
end
function M.cue(name,grade,index)
    if not M.ready()then return false end
    grade=math.clamp(grade or 1,1,5)
    if name=='request'then layers({{0,'computerTone',1,.32,.3},{.12,'computerTone',1.25,.28,.3}})
    elseif name=='flyover'then layers({{0,'jetWhoosh',.72,.5,2.2}})
    elseif name=='chute'then layers({{0,'whoosh',.8,.4,.9}})
    elseif name=='landing'then
        local l={{0,'metalClunk',.8,.5,.6},{0,'subThump',.9,.48,.8}}
        if grade>=3 then table.insert(l,{.04,'deepBoom',1.25,.28,1.2})end
        if grade>=5 then table.insert(l,{.08,'deepBoom',.9,.32,1.6})end
        layers(l)
    elseif name=='lamp'then
        local l={{0,'metalClunk',1+(index or 1)*.1,.3,.25}}
        for _,c in ipairs(lampChime[grade])do table.insert(l,{c[1]+.03,c[2],c[3],c[4],c[5]})end
        layers(l)
    elseif name=='upgrade'then layers({{.08,'powerUpRise',.9+grade*.08,.3,.9}})
    elseif name=='open'then layers({{0,'metalClunk',.62,.45,.7},{.05,'whoosh',1.1,.25,.6}})
    elseif name=='reveal'then layers(reveal[grade])
    elseif name=='sink'then layers({{0,'powerDown',.75,.22,.9}})
    elseif name=='serial'then layers({{0,'graphicBeep',1.3,.28,.3}})
    elseif name=='shatter'then layers({{0,'metalClunk',1.7,.42,.4},{.03,'bellDing',2,.3,.9},{.06,'powerUpRise',1.35,.32,1.1}})
    elseif name=='freeze'then layers({{0,'deepBoom',.7,.48,1.8},{0,'subThump',.7,.4,.9},{.05,'bellDing',.75,.3,1.4}})
    elseif name=='coins'then
        local l={};for i=1,math.min(index or 6,8)do table.insert(l,{.32+(i-1)*.07,'toneDing',1.5+i*.06,.14,.25})end
        table.insert(l,{.32+math.min(index or 6,8)*.07,'bellDing',1.5,.26,.7});layers(l)
    elseif name=='drive'then layers({{0,'whoosh',.65,.22,.8}})
    elseif name=='impact'then layers({{0,'deepBoom',1.05,.4,1.6},{0,'subThump',.85,.36,.8}})
    else return false end
    return true
end
function M.stop()
    table.clear(pending)
    for _,v in ipairs(voices)do v.untilTime=0;v.sound:Stop()end
end
return M
