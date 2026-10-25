local SoundService=game:GetService('SoundService')
local TweenService=game:GetService('TweenService')
local M={}
M.tracks={
    9040113683,
    9046457633,
    1837777133,
    1837768494,
    1838627720,
}
M.queueTracks={
    1838627751,
    1838627903,
    9045941481,
}
M.calm={9042294906,9042294264,1837630213,1843024191,1843007799}
M.roll=1842251033
M.volume=.22;M.rollVolume=.3
local sound,roll,wanted,mode,order,index=nil,nil,false,'lobby',{},0
local function level()return M.volume*(SoundService:GetAttribute('ToyMusicVolume')or 1)end
local function silent()return SoundService:GetAttribute('ToySoundsMuted')==true or level()<=0 end
local function shuffle(list,keepFirst)
    order={};for i=1,#list do order[i]=i end
    for i=#order,(keepFirst and 3 or 2),-1 do local j=math.random(keepFirst and 2 or 1,i);order[i],order[j]=order[j],order[i] end
    index=0
end
local function list()return mode~='lobby'and M.queueTracks or M.tracks end
local function nextTrack()
    local tracks=list();if #tracks==0 then return end
    index+=1;if index>#order or #order~=#tracks then shuffle(tracks,false);index=1 end
    sound.SoundId='rbxassetid://'..tracks[order[index]]
end
local function fade(to,seconds,stopAfter)
    local tween=TweenService:Create(sound,TweenInfo.new(seconds,Enum.EasingStyle.Quad),{Volume=to});tween:Play()
    if stopAfter then tween.Completed:Once(function(state)if state==Enum.PlaybackState.Completed and not wanted then sound:Pause()end end)end
    return tween
end
local function apply()
    if not sound then return end
    local on=wanted and not silent()
    if on then
        if not sound.IsPlaying then if sound.IsPaused then sound:Resume()else sound:Play()end end
        fade(level(),2)
    elseif sound.IsPlaying then fade(0,1.2,true)end
end
local function create()
    sound=Instance.new('Sound');sound.Name='LobbyMusic';sound.Volume=0;sound.Looped=false;sound.Parent=SoundService
    sound.Ended:Connect(function()nextTrack();sound.TimePosition=0;task.defer(function()if wanted and not silent()and not sound.IsPlaying then sound.Volume=level();sound:Play()end end)end)
    shuffle(list(),mode=='lobby');nextTrack()
end
function M.set(on)
    on=on==true
    if on and not sound then if #M.tracks==0 then return end;create()end
    if on==wanted then return end
    wanted=on;apply()
end
function M.queue(key)
    local want=(key=='waiting'or key=='countdown'or key=='full')and 'queue'or key=='go'and 'go'or 'lobby'
    if want==mode then return end
    mode=want
    if want=='go'then M.go();return end
    if not sound then return end
    shuffle(list(),mode=='lobby')
    if wanted and not silent()and sound.IsPlaying then
        fade(0,.8).Completed:Once(function(state)
            if state~=Enum.PlaybackState.Completed or mode~=want then return end
            nextTrack();sound.TimePosition=0;sound:Play();fade(level(),1.2)
        end)
    else sound:Stop();nextTrack()end
end
function M.go()
    if sound and sound.IsPlaying then fade(0,1.5)end
    if silent()or not wanted then return end
    if not roll then roll=Instance.new('Sound');roll.Name='LobbyRoll';roll.SoundId='rbxassetid://'..M.roll;roll.Parent=SoundService end
    roll.Volume=M.rollVolume*(SoundService:GetAttribute('ToyMusicVolume')or 1);roll.TimePosition=0;roll:Play()
    task.delay(2.4,function()if roll.IsPlaying then TweenService:Create(roll,TweenInfo.new(.8),{Volume=0}):Play();task.delay(.8,function()roll:Stop()end)end end)
end
SoundService:GetAttributeChangedSignal('ToySoundsMuted'):Connect(function()
    if sound and SoundService:GetAttribute('ToySoundsMuted')then sound:Pause();sound.Volume=0;if roll then roll:Stop()end else apply()end
end)
SoundService:GetAttributeChangedSignal('ToyMusicVolume'):Connect(function()
    if not sound then return end
    if silent()then if sound.IsPlaying then sound:Pause()end;sound.Volume=0 else apply()end
end)
return M
