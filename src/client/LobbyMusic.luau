local SoundService=game:GetService('SoundService')
local TweenService=game:GetService('TweenService')
local M={}
M.tracks={
    9042294906,
    9042294264,
    1837630213,
    1843024191,
    1843007799,
}
M.volume=.22
local sound,wanted,order,index=nil,false,{},0
local function shuffle()
    order={};for i=1,#M.tracks do order[i]=i end
    for i=#order,2,-1 do local j=math.random(i);order[i],order[j]=order[j],order[i] end
    index=0
end
local function nextTrack()
    if #M.tracks==0 then return end
    index+=1;if index>#order then shuffle();index=1 end
    sound.SoundId='rbxassetid://'..M.tracks[order[index]]
end
local function fade(to,seconds,stopAfter)
    local tween=TweenService:Create(sound,TweenInfo.new(seconds,Enum.EasingStyle.Quad),{Volume=to});tween:Play()
    if stopAfter then tween.Completed:Once(function(state)if state==Enum.PlaybackState.Completed and not wanted then sound:Pause()end end)end
end
local function apply()
    if not sound then return end
    local on=wanted and not SoundService:GetAttribute('ToySoundsMuted')
    if on then
        if not sound.IsPlaying then if sound.IsPaused then sound:Resume()else sound:Play()end end
        fade(M.volume,2)
    elseif sound.IsPlaying then fade(0,1.2,true)end
end
function M.set(on)
    on=on==true
    if on and not sound then
        if #M.tracks==0 then return end
        sound=Instance.new('Sound');sound.Name='LobbyMusic';sound.Volume=0;sound.Looped=false;sound.Parent=SoundService
        sound.Ended:Connect(function()nextTrack();if wanted and not SoundService:GetAttribute('ToySoundsMuted')then sound.Volume=M.volume;sound:Play()end end)
        shuffle();nextTrack()
    end
    if on==wanted then return end
    wanted=on;apply()
end
SoundService:GetAttributeChangedSignal('ToySoundsMuted'):Connect(function()
    if sound and SoundService:GetAttribute('ToySoundsMuted')then sound:Pause();sound.Volume=0 else apply()end
end)
return M
