local Players=game:GetService('Players');local Run=game:GetService('RunService')
local Rig=require(script.Parent.CommanderStandardRig)
local PoseBatch=require(script.Parent.RenderPoseBatch)
local Rules=require(script.Parent.Parent.Core.CommanderStandardRules)
local Evolution=require(script.Parent.Parent.Core.SupplyRevealRules)
local M={}
local function emoting(c)
    local hum=c:FindFirstChildOfClass('Humanoid');local animator=hum and hum:FindFirstChildOfClass('Animator');if not animator then return false end
    for _,t in ipairs(animator:GetPlayingAnimationTracks())do
        local pr=t.Priority;if t.IsPlaying and t.WeightCurrent>.3 and (pr==Enum.AnimationPriority.Action or pr==Enum.AnimationPriority.Action2 or pr==Enum.AnimationPriority.Action3 or pr==Enum.AnimationPriority.Action4)then return true end
    end
    return false
end
function M.watch(context)
    if M.started then return end;M.started=true
    local folder=Instance.new('Folder');folder.Name='CommanderStandards';folder.Parent=workspace
    local states={};local scan=0;local batch=PoseBatch.new()
    Run.RenderStepped:Connect(function(dt)
        scan+=dt
        if scan>=.25 then scan=0
            local Stage=require(script.Parent.LobbyStage)
            for _,p in ipairs(Players:GetPlayers())do
                local s=Stage.standFor(p);local c=s and s.clone or p.Character;local hand=c and(c:FindFirstChild('RightHand')or c:FindFirstChild('Right Arm'))
                local raw=p:GetAttribute('CommanderStandardStyle');local item=Rules.find(raw)
                local id=item and item.supply and raw or Rules.effective(raw,p:GetAttribute('CommanderLevel')or 1)
                local old=states[p]
                if old and(old.character~=c or old.id~=id)then old.rig:destroy();states[p]=nil;old=nil end
                if hand and not old then states[p]={character=c,hand=hand,id=id,rig=Rig.new(folder,id,Color3.fromRGB(54,226,208)),plant=0}end
                if states[p]then states[p].real=s and s.real or nil end
            end
        end
        local camera=workspace.CurrentCamera;if not camera then return end
        for p,v in pairs(states)do
            local c=v.character;local root=c:FindFirstChild('HumanoidRootPart');local torso=c:FindFirstChild('UpperTorso')or c:FindFirstChild('Torso')or root
            if not p.Parent or not c.Parent or not v.hand.Parent or not root or not torso then v.rig:destroy();states[p]=nil
            else
                local shown,color,share=context(p);local distance=(root.Position-camera.CFrame.Position).Magnitude
                local point=camera:WorldToViewportPoint(root.Position);local view=camera.ViewportSize
                local visible=shown and distance<300 and root.LocalTransparencyModifier<.99 and point.Z>0 and point.X>=-80 and point.X<=view.X+80 and point.Y>=-80 and point.Y<=view.Y+80
                if v.visible~=visible then v.visible=visible;v.lastAt=nil;v.rig.model.Parent=visible and folder or nil end
                if visible then
                    v.emote=emoting(v.real or c)
                    v.rig:recolor(color or Color3.fromRGB(54,226,208))
                    local at=root.Position;local last=v.lastAt;v.lastAt=at
                    local raw=last and dt>0 and (at-last).Magnitude<40 and Vector3.new(at.X-last.X,0,at.Z-last.Z).Magnitude/dt or 0
                    v.wind=(v.wind or raw)+(raw*(1-v.plant)+8*v.plant-(v.wind or raw))*(1-math.exp(-dt*6))
                    v.movingFor=raw>1 and(v.movingFor or 0)+dt or 0
                    local tier=v.rig.definition.tier or 0
                    local phase=tier==5 and(type(share)=='number'and Evolution.evolution(5,share,false)or math.min(3,1+math.floor(v.movingFor/.7)))or 1
                    local scale=math.clamp(root.Size.Y/2,.65,2)
                    local palm=v.hand.Name=='Right Arm'and v.hand.CFrame:PointToWorldSpace(Vector3.new(0,-v.hand.Size.Y*.42,0))or v.hand.Position
                    local grip=CFrame.new(palm)*torso.CFrame.Rotation
                    local hum=c:FindFirstChildOfClass('Humanoid');local drop=root.Size.Y/2+(hum and hum.RigType==Enum.HumanoidRigType.R15 and hum.HipHeight or 2)
                    local look=root.CFrame.LookVector;local ground=v.rig.series and CFrame.new(root.Position-Vector3.new(0,drop-.04,0))*CFrame.Angles(0,math.atan2(-look.X,-look.Z),0)
                    v.plant=math.clamp(v.plant+(v.emote and dt or -dt)*4,0,1)
                    if v.plant>0 then
                        local ground=root.CFrame*CFrame.new(1.7*scale,-drop+1*scale,.5*scale)*CFrame.Angles(.3,0,0)
                        local a=v.plant*v.plant*(3-2*v.plant);grip=grip:Lerp(CFrame.new(ground.Position)*ground.Rotation,a)
                    end
                    v.rig:step(grip,os.clock()+p.UserId%19,v.wind,scale,math.max(root.LocalTransparencyModifier,v.hand.LocalTransparencyModifier),batch,Players.LocalPlayer:GetAttribute('CommanderReducedEffects')==true,phase,ground)
                end
            end
        end
        batch:flush()
    end)
    Players.PlayerRemoving:Connect(function(p)local v=states[p];if v then v.rig:destroy();states[p]=nil end end)
end
return M
