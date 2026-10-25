local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local SoundService=game:GetService("SoundService")
local M={}
local rows={
    {"capture","Capture tick","repeat",{9119717950,9113880475}},
    {"pop","Front advance pop","repeat",{9113867159,9119834422}},
    {"block","Front clash","repeat",{9113880475,9125540235}},
    {"shell","Warship shell","repeat",{9116973350,9126009582}},
    {"click","Console click","repeat",{}},
    {"orderTap","Order press (instant)","event",{9120456673,9120458071}},
    {"attackLight","Attack 10%","event",{9126010351}},
    {"attackHeavy","Attack 50%+","event",{9126010351}},
    {"orderDrum","Attack 20% drum","event",{1846435399,1842312832}},
    {"orderImpact","Attack 50%+ impact","event",{1848272916,9039709283}},
    {"buildHammer","Build City/Port","event",{9114756497,9114755819}},
    {"buildRatchet","Build Factory/SAM/Ship","event",{9118045838,9118046124}},
    {"buildHeavy","Build Defense/Silo","event",{9125484367}},
    {"combo","Capture combo","event",{9113867159,9114642723}},
    {"grow","Troop cap growth","event",{9126073001,9119802009}},
    {"attack","Attack sent","event",{9120456889,9118018717}},
    {"build","Build order","event",{}},
    {"upgrade","Upgrade order","event",{9125665221,9117884499}},
    {"complete","Build complete","event",{9114285303,9117885256}},
    {"trade","Trade","event",{9125726282,9113848780}},
    {"request","Request received","event",{9126075967,9119141871}},
    {"confirm","Confirm","event",{}},
    {"error","Denied","event",{9113402327,9113402034}},
    {"allied","Alliance formed","event",{9119802009,9126073644}},
    {"allianceEnded","Alliance ended","event",{9126009638}},
    {"rankUp","Rank up","event",{9117884499,9126073001}},
    {"countdown","Last 10 s tick","event",{9113880475}},
    {"incoming","Attack warning","alarm",{9119160366,9113652301}},
    {"assault","Assault warning","alarm",{9113652301,9119662239}},
    {"rocketWarning","Rocket warning","alarm",{9119662934,9119662238}},
    {"launch","Launch","blast",{9125698566,9118593266}},
    {"intercept","Intercept","blast",{9126009571,9116973593}},
    {"distant","Someone else's nuke","blast",{}},
    {"detonate","Nuke (mine)","blast",{}},
    {"nuke","Hydrogen / MIRV","blast",{}},
    {"eliminated","Nation eliminated","blast",{9116973611,9126009582}},
    {"betrayal","Betrayal","sting",{9126009638}},
    {"conquest","Conquest","sting",{9126073644,9043511976}},
    {"milestone","Milestone","sting",{1846901962,9042409272}},
    {"start","Match start","sting",{9113343286,1841717931}},
    {"timeUp","Time up","sting",{1846902219}},
    {"stinger","Stinger","sting",{}},
    {"victory","Victory","sting",{1842180575,1842059783}},
    {"defeat","Defeat","sting",{115055593775910,1846887274}},
}
local targets={["repeat"]=90,event=150,alarm=190,blast=200,sting=170}
local colors={bg=Color3.fromRGB(11,15,20),panel=Color3.fromRGB(18,24,33),raised=Color3.fromRGB(24,33,44),ink=Color3.fromRGB(238,242,246),muted=Color3.fromRGB(138,151,168),accent=Color3.fromRGB(54,226,208),fail=Color3.fromRGB(245,196,81)}
local gui
local function make(class,parent,props)
    local o=Instance.new(class);for k,v in pairs(props)do o[k]=v end;o.Parent=parent;return o
end
local function text(parent,name,value,x,w,color)
    return make("TextLabel",parent,{Name=name,Text=value,Position=UDim2.fromOffset(x,0),Size=UDim2.new(0,w,1,0),BackgroundTransparency=1,TextColor3=color or colors.ink,Font=Enum.Font.GothamMedium,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left})
end
local function button(parent,name,value,x,w,fn)
    local b=make("TextButton",parent,{Name=name,Text=value,Position=UDim2.fromOffset(x,3),Size=UDim2.fromOffset(w,26),BackgroundColor3=colors.raised,TextColor3=colors.ink,Font=Enum.Font.GothamBold,TextSize=13,AutoButtonColor=true})
    make("UICorner",b,{CornerRadius=UDim.new(0,4)});b.Activated:Connect(fn);return b
end
local function content(file) return type(file)=="number" and "rbxassetid://"..file or "rbxasset://sounds/"..file end
local function play(id,pitch,volume,duration)
    local s=make("Sound",SoundService,{Name="AuditionVoice",SoundId=content(id),PlaybackSpeed=pitch,Volume=volume})
    s:Play();task.delay(duration,function()s:Stop();s:Destroy()end)
end
local function measure(id,pitch,duration)
    local s=make("Sound",SoundService,{Name="AuditionMeter",SoundId=content(id),PlaybackSpeed=pitch,Volume=1})
    local t0=os.clock();while not s.IsLoaded and os.clock()-t0<6 do task.wait() end
    local length=tonumber(s.TimeLength) or 0
    if not s.IsLoaded or length<=0 then s:Destroy();return {failed=true} end
    s:Play()
    local stop=os.clock()+math.min(duration,length/pitch,3);local sum,n,peak=0,0,0
    while os.clock()<stop do task.wait();local l=tonumber(s.PlaybackLoudness) or 0;if l>1 then sum+=l;n+=1 end;peak=math.max(peak,l) end
    s:Stop();s:Destroy();task.wait(.15)
    return {length=length,mean=n>0 and sum/n or 0,peak=peak,failed=n==0 or nil}
end
function M.open(audio)
    local player=Players.LocalPlayer;if not player or gui and gui.Parent then return end
    local presets=audio.presets;local configured=audio.configuredPresets or presets
    gui=make("ScreenGui",player:WaitForChild("PlayerGui"),{Name="SoundAudition",ResetOnSpawn=false,DisplayOrder=200,IgnoreGuiInset=true})
    local panel=make("Frame",gui,{Name="Panel",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-12,0,12),Size=UDim2.new(0,520,1,-24),BackgroundColor3=colors.bg,BackgroundTransparency=.04})
    make("UICorner",panel,{CornerRadius=UDim.new(0,8)})
    local head=make("Frame",panel,{Name="Head",Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,32),BackgroundTransparency=1})
    text(head,"Title","Sound audition · Studio only",0,230,colors.accent)
    local status=text(make("Frame",panel,{Name="StatusRow",Position=UDim2.fromOffset(12,40),Size=UDim2.new(1,-24,0,20),BackgroundTransparency=1}),"Status","A = current. Click to hear and pick. − / + changes volume.",0,496,colors.muted)
    local list=make("ScrollingFrame",panel,{Name="Rows",Position=UDim2.fromOffset(8,64),Size=UDim2.new(1,-16,1,-72),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()})
    make("UIListLayout",list,{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)})
    local state={}
    for i,r in ipairs(rows) do
        local c=configured[r[1]]
        if c then
            local row=make("Frame",list,{Name=r[1],LayoutOrder=i,Size=UDim2.new(1,-8,0,32),BackgroundColor3=colors.panel})
            local s={kind=r[1],tier=r[3],ids={c[1]},pick=1,volume=c[3],pitch=c[2],duration=c[4],buttons={},loud={}}
            for _,id in ipairs(r[4]) do table.insert(s.ids,id) end
            text(row,"Label",r[2],8,150);text(row,"Tier",r[3],156,50,colors.muted)
            local volume=text(row,"Volume",string.format("%.2f",s.volume),356,40)
            s.note=text(row,"Loudness","",430,80,colors.muted)
            local function refresh(apply)
                for j,b in ipairs(s.buttons) do b.BackgroundColor3=j==s.pick and colors.accent or colors.raised;b.TextColor3=j==s.pick and colors.bg or colors.ink end
                volume.Text=string.format("%.2f",s.volume)
                if apply then local cue=table.clone(configured[s.kind]);cue[1]=s.ids[s.pick];cue[3]=s.volume;presets[s.kind]=cue end
            end
            for j,id in ipairs(s.ids) do
                s.buttons[j]=button(row,"Pick"..j,string.char(64+j),206+(j-1)*40,36,function()
                    s.pick=j;refresh(true);play(id,s.pitch,s.volume*(SoundService:GetAttribute("ToySoundsVolume")or 1),s.duration)
                end)
            end
            button(row,"Quieter","−",330,24,function()s.volume=math.max(.05,math.floor(s.volume*.8*100+.5)/100);refresh(true)end)
            button(row,"Louder","+",398,24,function()s.volume=math.min(1,math.floor(s.volume*1.25*100+.5)/100);refresh(true)end)
            refresh(false);table.insert(state,s)
        end
    end
    local music=require(script.Parent.LobbyMusic);local preview
    local sets={{"Lobby",music.tracks},{"Queue",music.queueTracks},{"Old calm",music.calm},{"Roll",{music.roll}}}
    local order=#rows
    for _,set in ipairs(sets)do for j,id in ipairs(set[2])do
        order+=1;local row=make("Frame",list,{Name="Music"..id,LayoutOrder=order,Size=UDim2.new(1,-8,0,32),BackgroundColor3=colors.panel})
        text(row,"Label",set[1].." "..j.." · "..id,8,240,j==1 and set[1]=="Lobby"and colors.accent or colors.ink)
        button(row,"Play","Play",256,60,function()
            if not preview then preview=make("Sound",SoundService,{Name="AuditionMusic"})end
            preview:Stop();preview.SoundId="rbxassetid://"..id;preview.Volume=music.volume*2;preview.TimePosition=set[1]=="Roll"and 0 or 20;preview:Play()
            local mine=preview.SoundId;task.delay(30,function()if preview and preview.SoundId==mine then preview:Stop()end end)
        end)
        button(row,"Stop","Stop",320,60,function()if preview then preview:Stop()end end)
    end end
    local function result()
        local picks,lines={},{}
        for _,s in ipairs(state) do
            local id=s.ids[s.pick];local l=s.loud[s.pick]
            picks[s.kind]={id=id,volume=s.volume,original=s.ids[1],candidates=s.ids,pitch=s.pitch,duration=s.duration,tier=s.tier,loudness=s.loud,recommended=l and not l.failed and math.clamp(targets[s.tier]/l.mean,.1,1)or nil}
            table.insert(lines,string.format("%-14s %s @ %.2f%s",s.kind,type(id)=="number" and tostring(id) or "built-in "..tostring(id),s.volume,l and (l.failed and "  FAILED" or string.format("  loud %.0f → suggest %.2f",l.mean,l.mean>0 and math.clamp(targets[s.tier]/l.mean,.1,1) or s.volume)) or ""))
        end
        local json=Http:JSONEncode(picks);print("SOUND_AUDITION "..json);gui:SetAttribute("Result",json)
        return table.concat(lines,"\n")
    end
    local measuring=false
    button(head,"Measure","Measure all",236,96,function()
        if measuring then return end;measuring=true
        local total,done,failed=0,0,0;for _,s in ipairs(state) do total+=#s.ids end
        for _,s in ipairs(state) do
            for j,id in ipairs(s.ids) do
                status.Text=string.format("Measuring %d / %d · %s %s",done+1,total,s.kind,string.char(64+j))
                local m=measure(id,s.pitch,s.duration);s.loud[j]=m;done+=1;if m.failed then failed+=1 end
            end
            local l=s.loud[s.pick];s.note.Text=l and (l.failed and "failed" or string.format("%.0f→%.2f",l.mean,l.mean>0 and math.clamp(targets[s.tier]/l.mean,.1,1) or s.volume)) or ""
            s.note.TextColor3=l and l.failed and colors.fail or colors.muted
        end
        status.Text=string.format("Measured %d sounds · %d failed or silent",done,failed);gui:SetAttribute("Measured",done);gui:SetAttribute("Failed",failed);measuring=false
        result()
    end)
    local sheet
    button(head,"Result","Result",336,70,function()
        if sheet then sheet:Destroy();sheet=nil;return end
        sheet=make("TextBox",panel,{Name="ResultText",Position=UDim2.fromOffset(8,64),Size=UDim2.new(1,-16,1,-72),BackgroundColor3=colors.panel,TextColor3=colors.ink,Font=Enum.Font.Code,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ClearTextOnFocus=false,TextEditable=false,MultiLine=true,TextWrapped=false,Text=result(),ZIndex=5})
    end)
    if audio.packs then
        status.Size=UDim2.new(0,290,1,0);status.TextTruncate=Enum.TextTruncate.AtEnd
        local packRow=make("Frame",panel,{Name="Packs",Position=UDim2.fromOffset(300,40),Size=UDim2.fromOffset(208,22),BackgroundTransparency=1})
        for i,name in ipairs({"A","B","C","D"})do button(packRow,"Pack"..name,"Order "..name,(i-1)*52,48,function()audio.usePack(name);status.Text="Order pack "..name.." in use. Give an order in the match."end)end
    end
    button(head,"Close","Close",410,86,function()if preview then preview:Destroy()end;gui:Destroy()end)
end
return M
