local UI=require(script.Parent.ToyUI)
local K=require(script.Parent.SkinShopKit)
local Launch=require(script.Parent.Parent.Core.LaunchCommerce)
local Catalog=require(script.Parent.Parent.Core.SupplyCatalog)
local Rules=require(script.Parent.Parent.Core.SupplyRevealRules)
local Preview=require(script.Parent.CollectionPreview)
local Audio=require(script.Parent.ToyAudio)
local Telemetry=require(script.Parent.TelemetryClient)
local Cinematic=require(script.Parent.SupplyCinematic)
local M={};local current
local colors={normal=Color3.fromRGB(185,198,211),rare=Color3.fromRGB(80,165,255),epic=Color3.fromRGB(173,119,255),legendary=UI.colors.gold,mythic=Color3.fromRGB(157,242,235)}
M.colors=colors
local CENTER=Enum.TextXAlignment.Center
local categoryNames={};for _,c in ipairs(Launch.categories)do categoryNames[c.id]=c.name end
function M.close(keep)
    if keep~='keep'then Cinematic.stop()end
    if not current then return end
    Telemetry.emit('supply_reveal',{stage='closed',rarity=current.result.rarity,sku=current.result.kind,reason=current.skip and 'skipped'or 'closed',duration_ms=current.elapsed*1000,completed=current.finished==true})
    current.connection:Disconnect();current.input:Disconnect();current.gui:Destroy();current=nil
    for _,key in ipairs({'supplyDelivery','supplySeal','supply_normal','supply_rare','supply_epic','supply_legendary','supply_mythic'})do Audio.stop(key)end
end
local function againCost(result)
    if result.currency=='medals'or result.currency=='free'then return string.format('코인 %s',UI.commas(Launch.medalDrawCost))end
    if result.currency=='ticket'then return '뽑기권 1'end
end
function M.open(shop,result,again,settled)
    local item=result and Catalog.find(result.id);if not item then return end
    M.close(settled and 'keep');if game.Players.LocalPlayer:GetAttribute('FrontierRoom')then Telemetry.step('gacha','revealPath',{sku=result.kind,result='cancelled',reason='busy'});return end
    if not settled then
        local ok,started=pcall(Cinematic.play,shop,result,item,function()if not current then M.open(shop,result,again,true)end end)
        Telemetry.step('gacha','revealPath',{sku=result.kind,rarity=result.rarity,item=ok and started and 'cinematic'or 'card',result=ok and 'opened'or 'failed',reason=ok and (started and 'none'or 'fallback')or 'failed'})
        if ok and started then return end
        if not ok then Cinematic.stop()end
    end
    local color=K.rarity[result.rarity]or K.rarity.normal;local tier=Rules.rank[result.rarity]
    local gui=UI.make('ScreenGui',game.Players.LocalPlayer.PlayerGui,{Name='SupplyReveal',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=75,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
    pcall(function()gui.ScreenInsets=Enum.ScreenInsets.None end)
    require(script.Parent.Localization).bind(gui)
    local shade=UI.make('TextButton',gui,{Name='InputShield',Text='',Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(5,8,13),BackgroundTransparency=settled and 1 or .02,AutoButtonColor=false,BorderSizePixel=0})
    local panel=UI.make('Frame',shade,{Name='RevealCard',BackgroundTransparency=1,Size=UDim2.fromScale(1,1)})
    local burst=UI.make('Frame',panel,{Name='Burst',AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1,ZIndex=1})
    local glows={}
    for i=1,(tier>=5 and 18 or tier>=4 and 14 or tier>=3 and 10 or 8)do
        local ray=UI.make('Frame',burst,{Name='RevealRay',AnchorPoint=Vector2.new(.5,1),Position=UDim2.fromScale(.5,.5),BackgroundColor3=color,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=1})
        UI.make('UIGradient',ray,{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.55,.35),NumberSequenceKeypoint.new(1,.9)})});table.insert(glows,ray)
    end
    local halo=K.round(UI.make('Frame',burst,{Name='Glow',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BackgroundColor3=color,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=1}),999)
    local chip=K.round(UI.pill(panel,'Rarity','',color),14);chip.TextSize=15;chip.Font=K.heavy;chip.AnchorPoint=Vector2.new(.5,0);chip.Visible=false;chip.ZIndex=4
    local name=K.text(panel,'ItemName','보급 도착',0,0,10,10,32,UI.colors.ink,CENTER,K.heavy);name.AnchorPoint=Vector2.new(.5,0);name.ZIndex=4
    local sub=K.text(panel,'Sub','',0,0,10,10,15,UI.colors.ink:Lerp(UI.colors.muted,.3),CENTER);sub.AnchorPoint=Vector2.new(.5,0);sub.ZIndex=4
    local serial=K.text(panel,'Serial',result.serial or '',0,0,10,10,13,color,CENTER);serial.AnchorPoint=Vector2.new(.5,0);serial.Visible=false;serial.AutoLocalize=false;serial.ZIndex=4
    local pod,podContext=Preview.create(panel,nil,{pod=true,tier=tier,manual=true});pod.AnchorPoint=Vector2.new(.5,.5)
    local reward,context=Preview.create(panel,item,{manual=true});reward.AnchorPoint=Vector2.new(.5,.5);reward.Visible=false
    pod.ZIndex=3;reward.ZIndex=3
    local onMap=({territory=true,buildings=true,nuclear=true,parachute=true})[item.category]and require(script.Parent.SkinMapScene).create(panel,item)or nil
    if onMap then onMap.Name='MapReward';onMap.AnchorPoint=Vector2.new(.5,.5);onMap.Visible=false;onMap.ZIndex=3;K.round(onMap,12);UI.stroke(onMap,color,2)end
    local hint=K.text(panel,'SkipHint','탭하면 연출을 건너뛰어요',0,0,10,20,13,UI.colors.muted,CENTER);hint.AnchorPoint=Vector2.new(.5,1);hint.ZIndex=4
    local dup=K.round(UI.make('Frame',panel,{Name='Duplicate',AnchorPoint=Vector2.new(.5,0),BackgroundColor3=UI.colors.panel,BorderSizePixel=0,Visible=false,ZIndex=4}),8)
    UI.stroke(dup,color:Lerp(UI.colors.line,.4),1)
    local dupTitle=K.text(dup,'Title','이미 가진 외형이에요',14,6,10,22,15,UI.colors.ink,nil,K.heavy);dupTitle.ZIndex=5
    local dupLine=K.text(dup,'Line','',14,30,10,20,13,UI.colors.ink:Lerp(UI.colors.muted,.3));dupLine.ZIndex=5
    local dupCount=K.text(dup,'Count','',0,26,40,24,14,UI.colors.ink,Enum.TextXAlignment.Right,K.heavy);dupCount.ZIndex=5
    local gaugeFrame,setGauge
    local footer=UI.make('Frame',panel,{Name='ResultActions',AnchorPoint=Vector2.new(.5,0),BackgroundTransparency=1,Visible=false,ZIndex=4})
    local cost=againCost(result)
    local equip,retry,done
    equip=UI.button(footer,'Equip','바로 장착',function()
        shop:run(function()local r=shop:request('equipSupply',result.id);if r and r.ok and footer.Parent then
            if current and current.gui==gui then current.equipped=true end;equip.Text='장착했어요';UI.enabled(equip,false)
        end end)
    end,not result.duplicate)
    retry=UI.button(footer,'Again',cost and ('한 번 더 '..cost)or '한 번 더',function()M.close();again()end,result.duplicate)
    done=UI.button(footer,'Done','확인',M.close)
    for _,b in ipairs({equip,retry,done})do K.round(b,8);b.Font=K.heavy;b.ZIndex=5 end
    equip.Visible=not result.duplicate
    local reduced=(shop.account.preferences or {}).reducedEffects==true
    local function layout()
        local size=gui.AbsoluteSize.X>0 and gui.AbsoluteSize or workspace.CurrentCamera.ViewportSize
        local W,H=size.X,size.Y;local slim=H<420
        local top=slim and 26 or math.floor(H*.12)
        chip.Position=UDim2.fromOffset(W/2,top);chip.Size=UDim2.fromOffset(K.width(chip.Text~=''and chip.Text or '전설',15,K.heavy)+28,slim and 24 or 28)
        local ny=top+(slim and 26 or 36)
        name.Position=UDim2.fromOffset(W/2,ny);name.Size=UDim2.fromOffset(W-40,slim and 30 or 44);name.TextSize=slim and 22 or 32
        sub.Position=UDim2.fromOffset(W/2,ny+(slim and 30 or 46));sub.Size=UDim2.fromOffset(W-40,22)
        serial.Position=UDim2.fromOffset(W/2,ny+(slim and 50 or 70));serial.Size=UDim2.fromOffset(W-40,20)
        local bh=slim and 44 or 56;local bw=slim and 280 or 300
        local fh=result.duplicate and bh or bh+8+46
        local fy=H-(slim and 24 or math.floor(H*.12))-fh-(slim and 0 or 30)
        local dupH=result.duplicate and 52 or 0
        local vy=ny+(slim and 54 or 78);local vh=math.max(80,fy-(dupH>0 and dupH+12 or 0)-12-vy)
        for _,v in ipairs({pod,reward,onMap})do v.Position=UDim2.fromOffset(W/2,vy+vh/2);v.Size=UDim2.fromOffset(math.min(W-40,vh*1.6),vh)end
        burst.Position=UDim2.fromOffset(W/2,vy+vh/2);burst.Size=UDim2.fromOffset(10,10)
        local len=math.max(W,H)*.75
        for i,ray in ipairs(glows)do ray.Size=UDim2.fromOffset(i%2==0 and 26 or 14,len);ray.Rotation=i*360/#glows end
        halo.Size=UDim2.fromOffset(vh*1.2,vh*1.2)
        dup.Position=UDim2.fromOffset(W/2,fy-dupH-12);dup.Size=UDim2.fromOffset(bw,dupH)
        dupTitle.Size=UDim2.fromOffset(bw-28,22);dupLine.Size=UDim2.fromOffset(bw*.36,20);dupCount.Position=UDim2.fromOffset(bw-54,26)
        if gaugeFrame then UI.box(gaugeFrame,bw*.36+18,33,bw-bw*.36-18-60,7)end
        footer.Position=UDim2.fromOffset(W/2,fy);footer.Size=UDim2.fromOffset(bw,fh)
        if result.duplicate then local half=(bw-8)/2;UI.box(done,0,0,half,bh);UI.box(retry,half+8,0,half,bh)
        else UI.box(equip,0,0,bw,bh);local half=(bw-8)/2;UI.box(done,0,bh+8,half,46);UI.box(retry,half+8,bh+8,half,46)end
        for _,b in ipairs({equip,retry,done})do b.TextSize=b.Size.Y.Offset>=50 and 19 or 16 end
        hint.Position=UDim2.fromOffset(W/2,H-(slim and 8 or 24));hint.Size=UDim2.fromOffset(W,20)
    end
    if settled then for _,l in ipairs({name,sub,serial})do l.TextStrokeTransparency=.35 end;burst.Visible=false end
    layout()
    current={gui=gui,skip=settled==true,elapsed=0,result=result};local state=current;local lastPhase
    shade.Activated:Connect(function()if not footer.Visible then state.skip=true end end)
    Telemetry.emit('supply_reveal',{stage='opened',rarity=result.rarity,sku=result.kind})
    Audio.play('supplyDelivery',.8)
    state.connection=game:GetService('RunService').RenderStepped:Connect(function(dt)
        if not gui.Parent or game.Players.LocalPlayer:GetAttribute('FrontierRoom')then M.close();return end
        if state.viewport~=workspace.CurrentCamera.ViewportSize then state.viewport=workspace.CurrentCamera.ViewportSize;layout()end
        state.elapsed+=dt;local phase,p=Rules.phase(result.rarity,state.skip and 100 or state.elapsed,reduced)
        gui:SetAttribute('RevealPhase',phase);gui:SetAttribute('AwardedItem',result.id);gui:SetAttribute('AwardedGrade',result.rarity)
        if phase~=lastPhase then
            lastPhase=phase
            if phase=='seal'then Audio.play('supplySeal',.6)
            elseif phase=='reveal'or phase=='result'then
                if not state.heard then state.heard=true;Audio.play('supply_'..result.rarity,.8)end
            end
        end
        local show=phase=='reveal'or phase=='result';pod.Visible=not show and not settled;reward.Visible=show and not settled and not onMap
        if onMap then onMap.Visible=show end
        local energy=not reduced and show and (phase=='result'and .55 or math.sin(math.clamp((p-.63)/.37,0,1)*math.pi*.5)*.55)or 0
        for i,ray in ipairs(glows)do ray.BackgroundTransparency=1-energy*.5;ray.Rotation=i*360/#glows+state.elapsed*(tier>=5 and 6 or 3)
            if tier==5 then local f=(state.elapsed*.06+i/#glows)%1;ray.BackgroundColor3=color:Lerp(Color3.fromHSV(.82+.12*f,.35,1),.4)end end
        halo.BackgroundTransparency=1-energy*.18
        if show then
            local cat=categoryNames[item.category]or '외형'
            name.Text=result.name;chip.Text=Launch.rarityNames[result.rarity];chip.Visible=true
            sub.Text=cat..', '..(result.duplicate and '이미 가진 외형'or '새로 얻었어요')
            Preview.step(context,state.elapsed,math.min(3,1+math.floor((p-.63)*9)))
            local reveal=math.clamp((p-.63)/.37,0,1);reward.ImageTransparency=1-reveal
        else
            name.Text=phase=='delivery'and '보급 도착'or '봉인 해제';sub.Text=''
            podContext.model:PivotTo(CFrame.new(0,phase=='delivery'and (1-math.min(1,p/.24))^2*6 or 0,0)*CFrame.Angles(0,math.sin(state.elapsed)*.12,0))
            Preview.step(podContext,state.elapsed,1)
            if typeof(podContext.extra)=='Instance'then podContext.extra.CFrame=podContext.model:GetPivot()*CFrame.new(0,2.5+math.max(0,(p-.42)*9),0)end
        end
        if phase=='result'then
            if not state.finished then state.finished=true;Telemetry.emit('supply_reveal',{stage='outcome',rarity=result.rarity,sku=result.kind,reason=state.skip and 'skipped'or 'completed',duration_ms=state.elapsed*1000,completed=true,result=result.duplicate and 'duplicate'or 'granted'})
                Telemetry.step('gacha',result.duplicate and 'revealDuplicate'or 'revealNew',{sku=result.kind,rarity=result.rarity,item=require(script.Parent.TelemetryStep).code(result.id),duration_ms=state.elapsed*1000,reason=state.skip and 'skipped'or 'completed'})end
            footer.Visible=true;hint.Visible=false;serial.Visible=result.serial~=nil
            if result.duplicate and not state.dupShown then
                state.dupShown=true;dup.Visible=true
                if result.testing then dupLine.Text='중복 (테스트)'
                elseif result.currency=='medals'or result.currency=='free'then dupLine.Text=string.format('코인 +%d',result.medals or math.floor(Launch.medalDrawCost*.2))
                else
                    local fragments=shop.account.billing and shop.account.billing.fragments or {}
                    local count=result.refundTickets and 5 or math.clamp(result.fragmentCount or fragments[result.kind]or 1,1,5)
                    local boxGrade=Launch.tickets[result.kind]and Launch.tickets[result.kind].rarity
                    dupLine.Text=string.format('%s 조각 +1',boxGrade and Launch.rarityNames[boxGrade]or '보급');dupCount.Text=string.format('%d/5',count)
                    gaugeFrame,setGauge=K.gauge(dup,K.box[result.kind]or color,count-1,0,0,10,7);gaugeFrame.ZIndex=5;layout()
                    task.delay(reduced and 0 or .35,function()if setGauge and dup.Parent then setGauge(count,not reduced)
                        if result.refundTickets and dup.Parent then dupTitle.Text=string.format('조각 5개 → 뽑기권 %d장',result.refundTickets)end end end)
                end
            end
            UI.enabled(retry,not shop.busy);UI.enabled(equip,not state.equipped and not shop.busy)
        end
    end)
    state.input=game:GetService('UserInputService').InputBegan:Connect(function(input,handled)
        if handled then return end
        if input.KeyCode==Enum.KeyCode.Escape then M.close()
        elseif input.KeyCode==Enum.KeyCode.Space and footer.Visible==false then state.skip=true end
    end)
end
return M
