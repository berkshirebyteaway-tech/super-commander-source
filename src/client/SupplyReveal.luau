local UI=require(script.Parent.ToyUI)
local K=require(script.Parent.Kit20)
local Theme=require(script.Parent.Theme)
local Art=require(script.Parent.Art20)
local Launch=require(script.Parent.Parent.Core.LaunchCommerce)
local Catalog=require(script.Parent.Parent.Core.SupplyCatalog)
local Rules=require(script.Parent.Parent.Core.SupplyRevealRules)
local Families=require(script.Parent.Parent.Core.CollectionDefinitions).familyNames
local Preview=require(script.Parent.CollectionPreview)
local Audio=require(script.Parent.ToyAudio)
local Telemetry=require(script.Parent.TelemetryClient)
local Cinematic=require(script.Parent.SupplyCinematic)
local GuiService=game:GetService('GuiService')
local M={};local current
local colors={normal=Color3.fromRGB(185,198,211),rare=Color3.fromRGB(80,165,255),epic=Color3.fromRGB(173,119,255),legendary=UI.colors.gold,mythic=Color3.fromRGB(157,242,235)}
M.colors=colors
local C=K.colors
local categoryNames={};for _,c in ipairs(Launch.categories)do categoryNames[c.id]=c.name end
local LIGHT={normal=.6,rare=.8,epic=1,legendary=1.2,mythic=1.4}
local SIZES={
    pc={m=24,pad=20,w=400,title=24,body=15,chip=13,chipH=24,pri=56,priFs=20,sec=48,secFs=17,dup=52,artMin=140,artMax=300},
    pt={m=16,pad=16,w=360,title=20,body=14,chip=12,chipH=22,pri=48,priFs=17,sec=44,secFs=15,dup=48,artMin=120,artMax=300},
    ph={m=12,pad=14,w=600,title=18,body=13,chip=12,chipH=22,pri=44,priFs=16,sec=36,secFs=14,dup=44,artMin=120,artMax=280},
}
function M.close(keep)
    if keep~='keep'then Cinematic.stop()end
    if not current then return end
    Telemetry.emit('supply_reveal',{stage='closed',rarity=current.result.rarity,sku=current.result.kind,reason=current.skip and 'skipped'or 'closed',duration_ms=current.elapsed*1000,completed=current.finished==true})
    for part,was in pairs(current.hidden or {})do if part.Parent then part.LocalTransparencyModifier=was end end
    current.connection:Disconnect();current.input:Disconnect();current.gui:Destroy();current=nil
    for _,key in ipairs({'supplyDelivery','supplySeal','supply_normal','supply_rare','supply_epic','supply_legendary','supply_mythic'})do Audio.stop(key)end
end
local function againCost(result)
    if result.currency=='medals'or result.currency=='free'then return string.format('코인 %s',UI.commas(Launch.medalDrawCost))end
    if result.currency=='ticket'then return '뽑기권 1'end
end
local function safeArea()
    local view=workspace.CurrentCamera.ViewportSize
    local ok,a=pcall(function()return GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)end)
    if ok and a and a.Max.X>a.Min.X and a.Max.Y>a.Min.Y then return a.Min,a.Max-a.Min end
    local ok2,tl=pcall(function()return (GuiService:GetGuiInset())end);local top=ok2 and tl.Y or 0
    return Vector2.new(0,top),Vector2.new(view.X,math.max(1,view.Y-top))
end
local function ease(u,inward)u=math.clamp(u,0,1);if inward then return u*u end;return 1-(1-u)*(1-u)end
function M.open(shop,result,again,settled)
    local item=result and Catalog.find(result.id);if not item then return end
    M.close(settled and 'keep');if game.Players.LocalPlayer:GetAttribute('FrontierRoom')then Telemetry.step('gacha','revealPath',{sku=result.kind,result='cancelled',reason='busy'});return end
    if not settled then
        local ok,started=pcall(Cinematic.play,shop,result,item,function()if not current then M.open(shop,result,again,true)end end)
        Telemetry.step('gacha','revealPath',{sku=result.kind,rarity=result.rarity,item=ok and started and 'cinematic'or 'card',result=ok and 'opened'or 'failed',reason=ok and (started and 'none'or 'fallback')or 'failed'})
        if ok and started then return end
        if not ok then Cinematic.stop()end
    end
    local color=K.rarity[result.rarity]or K.rarity.normal;local tier=Rules.rank[result.rarity]or 1
    local dup=result.duplicate==true
    local reduced=K.reduced or (shop.account.preferences or {}).reducedEffects==true
    local gui=K.make('ScreenGui',game.Players.LocalPlayer.PlayerGui,{Name='SupplyReveal',ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=75,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
    pcall(function()gui.ScreenInsets=Enum.ScreenInsets.None;gui.ClipToDeviceSafeArea=false end)
    require(script.Parent.Localization).bind(gui)
    local shade=K.make('TextButton',gui,{Name='InputShield',Text='',Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(4,7,11),BackgroundTransparency=settled and 1 or .06,AutoButtonColor=false,BorderSizePixel=0})
    local root=K.make('Frame',shade,{Name='Safe20',BackgroundTransparency=1,BorderSizePixel=0})
    local rootScale=K.make('UIScale',root,{Name='Scale'})
    local function measure()
        local min,size=safeArea();local s=Theme.scale or 1;local RW,RH=size.X/s,size.Y/s
        return min,s,RW,RH,RW<600 and 'pt'or RH<500 and 'ph'or 'pc'
    end
    local z0=SIZES[select(5,measure())]
    local mapLook=({territory=true,buildings=true,nuclear=true,parachute=true})[item.category]==true
    local withArt=not settled or mapLook
    local card=K.make('Frame',root,{Name='RevealCard',BackgroundTransparency=1,BorderSizePixel=0,ZIndex=3})
    local back=K.panel(card,'Back','card',12);back.AnchorPoint=Vector2.new(.5,.5);back.ZIndex=1
    local content=K.make('Frame',card,{Name='Face',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=2})
    local artBox,artGlow,reward,context,onMap
    if withArt then
        artBox=K.make('Frame',content,{Name='Art',BackgroundColor3=C.raised,BorderSizePixel=0,ZIndex=1});K.round(artBox,10)
        artGlow=Art.glow(artBox,'Glow',color,.3);artGlow.Size=UDim2.fromScale(1,.86);artGlow.Position=UDim2.fromScale(0,.07)
        if mapLook then onMap=require(script.Parent.SkinMapScene).create(content,item);onMap.Name='MapReward';onMap.ZIndex=2;K.round(onMap,8)
        else reward,context=Preview.create(content,item,{manual=true});reward.Name='Reward';reward.ZIndex=2;reward.ImageTransparency=settled and 0 or 1 end
    end
    local chipR=K.chip(content,'Rarity',Launch.rarityNames[result.rarity]or '','rarity',{color=color,filled=true,size=z0.chip,height=z0.chipH})
    local chipT=K.chip(content,'Tag',dup and '중복'or '새 외형',dup and 'muted'or 'accent',{size=z0.chip,height=z0.chipH})
    local name=K.text(content,'ItemName',result.name or item.name or '',z0.title,C.ink,900)
    local fam=K.text(content,'Family',Families[item.category]or categoryNames[item.category]or '외형',z0.body,C.muted,700)
    local serial=result.serial and K.num(content,'Serial',result.serial,math.max(11,z0.body-2),color)or nil
    if serial then serial.AutoLocalize=false end
    local dupBox,dupLine,dupCount,bar,coin,count
    if dup then
        dupBox=K.panel(content,'Duplicate','raised',8)
        if result.testing then dupLine=K.text(dupBox,'Line','중복 (테스트)',z0.body,C.ink,800)
        elseif result.currency=='medals'or result.currency=='free'then
            coin=K.amount(dupBox,'Coins','coin','+'..UI.commas(result.medals or math.floor(Launch.medalDrawCost*.2)),z0.body+2,C.gold)
        else
            local fragments=shop.account.billing and shop.account.billing.fragments or {}
            count=result.refundTickets and 5 or math.clamp(result.fragmentCount or fragments[result.kind]or 1,1,5)
            local boxGrade=Launch.tickets[result.kind]and Launch.tickets[result.kind].rarity
            dupLine=K.text(dupBox,'Line',string.format('%s 조각 +1',boxGrade and Launch.rarityNames[boxGrade]or '보급'),z0.body,C.ink,800)
            dupCount=K.num(dupBox,'Count',string.format('%d/5',count),z0.body+1,C.ink,Enum.TextXAlignment.Right)
            bar=K.fillBar(dupBox,'Pieces',{p=(count-1)/5,fill=boxGrade and K.rarity[boxGrade]or color,track=C.bg})
        end
    end
    local footer=K.make('Frame',card,{Name='ResultActions',BackgroundTransparency=1,BorderSizePixel=0,Visible=false,ZIndex=3})
    local cost=againCost(result)
    local equip,retry,done
    if not dup then
        equip=K.button(footer,'Equip',{kind='pri',text='장착',size=z0.priFs},function()
            if not current or current.gui~=gui or current.equipped then return end
            shop:run(function()local r=shop:request('equipSupply',result.id);if r and r.ok and footer.Parent then
                if current and current.gui==gui then current.equipped=true end;K.confirm(equip,true);equip:setText('장착 중');equip:setEnabled(false)
            end end)
        end)
    end
    retry=K.button(footer,'Again',{kind=dup and 'pri'or 'out',text=cost and ('한 번 더 '..cost)or '한 번 더',size=dup and z0.priFs or z0.secFs},function()M.close();again()end)
    done=K.button(footer,'Done',{kind='plain',text='확인',size=dup and z0.priFs or z0.secFs},function()M.close()end)
    local crate,crateView,crateCtx,crateScale,lid,aura,auraScale,core
    if not settled then
        aura=Art.glow(root,'Light',color,0);aura.AnchorPoint=Vector2.new(.5,.5);aura.ZIndex=1;auraScale=K.make('UIScale',aura,{Name='Light20'})
        if tier>=4 then core=Art.glow(root,'LightCore',Color3.new(1,1,1),0);core.AnchorPoint=Vector2.new(.5,.5);core.ZIndex=2 end
        crate=K.make('Frame',root,{Name='Crate',AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=4})
        crateScale=K.make('UIScale',crate,{Name='Pop20'})
        crateView,crateCtx=Preview.create(crate,nil,{crate=result.kind,manual=true,fill=.85,direction=Vector3.new(-.42,.5,-1).Unit,name='CrateView'})
        crateView.Size=UDim2.fromScale(1,1);crateView.ImageTransparency=1;crateView.ZIndex=1
        lid=Art.glow(crate,'LidLight',color,0);lid.AnchorPoint=Vector2.new(.5,.5);lid.Position=UDim2.fromScale(.5,.3);lid.Size=UDim2.fromScale(.9,.4);lid.ZIndex=2
        back.Visible=false
    end
    local tm
    if settled then tm=nil
    elseif reduced then tm={inn=.12,s0=.12,s1=.12,lid=.12,s2=.3,flip=.12,s3=.42,s4=.42,light=.3}
    else tm={inn=.16,s0=.16,s1=.46,lid=.2,s2=.66,flip=.24,s3=.9,s4=1.02,light=LIGHT[result.rarity]or .6}end
    local mid=tm and tm.s2+(reduced and 0 or tm.flip/2)
    local L={}
    local function layout()
        local min,s,RW,RH,fmt=measure();local z=SIZES[fmt]
        root.Position=UDim2.fromOffset(min.X,min.Y);root.Size=UDim2.fromOffset(RW,RH);rootScale.Scale=s
        local side=fmt=='ph'and withArt
        local chipH=chipR.Size.Y.Offset
        local nameH,famH,serH=z.title+8,z.body+6,serial and z.body+2 or 0
        local infoH=chipH+8+nameH+2+famH+serH+(dup and 10+z.dup or 0)
        local actH=dup and z.pri or z.pri+8+z.sec
        local w=K.even(math.min(RW-z.m*2,withArt and z.w or 420));local h,ax,ay,aw,ah,cx,cw,iy
        if side then
            h=K.even(math.min(RH-z.m*2,math.max(z.pad*2+infoH+16+actH,300)))
            ah=h-z.pad*2;aw=math.min(ah,math.floor(w*.42));ax,ay=z.pad,z.pad
            cx=z.pad+aw+16;cw=w-cx-z.pad;iy=z.pad
        else
            local fixed=z.pad*2+infoH+16+actH
            ah=withArt and math.clamp(RH-z.m*2-fixed-12,z.artMin,z.artMax)or 0
            h=K.even(fixed+(withArt and ah+12 or 0))
            ax,ay,aw=z.pad,z.pad,w-z.pad*2;cx,cw=z.pad,w-z.pad*2;iy=z.pad+(withArt and ah+12 or 0)
        end
        local x=math.floor((RW-w)/2);local y=withArt and math.floor((RH-h)/2)or RH-z.m-h
        K.boxCentre(card,x,y,w,h);if card:GetAttribute('Home20')then K.rehome(card)end
        L.w,L.h=w,h;back.Position=UDim2.fromOffset(w/2,h/2);if not tm then back.Size=UDim2.fromOffset(w,h)end
        if artBox then K.box(artBox,ax,ay,aw,ah);if reward then K.box(reward,ax+4,ay+4,aw-8,ah-8)end;if onMap then K.box(onMap,ax+4,ay+4,aw-8,ah-8)end end
        local al=side and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
        local rw,tw=chipR.Size.X.Offset,chipT.Size.X.Offset;local rx=side and cx or cx+math.floor((cw-rw-6-tw)/2)
        K.box(chipR,rx,iy,rw,chipH);K.box(chipT,rx+rw+6,iy,tw,chipH)
        local ny=iy+chipH+8
        name.TextXAlignment=al;K.box(name,cx,ny,cw,nameH);K.fit(name,cw,z.title,math.max(14,z.title-6))
        fam.TextSize=z.body;fam.TextXAlignment=al;K.box(fam,cx,ny+nameH+2,cw,famH)
        local dy=ny+nameH+2+famH
        if serial then serial.TextSize=math.max(11,z.body-2);serial.TextXAlignment=al;K.box(serial,cx,dy,cw,serH);dy+=serH end
        if dupBox then
            K.box(dupBox,cx,dy+10,cw,z.dup)
            if bar then K.box(dupLine,12,5,cw-24-60,20);dupLine.TextSize=z.body;K.box(dupCount,cw-12-56,5,56,20);K.box(bar.frame,12,z.dup-11,cw-24,6)
            elseif coin then K.box(coin,12,math.floor((z.dup-coin.Size.Y.Offset)/2),coin.Size.X.Offset,coin.Size.Y.Offset)
            elseif dupLine then K.box(dupLine,12,0,cw-24,z.dup)end
        end
        K.box(footer,cx,h-z.pad-actH,cw,actH);if footer:GetAttribute('Home20')then K.rehome(footer)end
        local half=math.floor((cw-8)/2)
        local function fs(b,n)if b.label then b.label.TextSize=n end end
        if dup then fs(done,z.priFs);fs(retry,z.priFs);done:place(0,0,half,z.pri);retry:place(cw-half,0,half,z.pri)
        else fs(equip,z.priFs);equip:place(0,0,cw,z.pri);fs(done,z.secFs);fs(retry,z.secFs);done:place(0,z.pri+8,half,z.sec);retry:place(cw-half,z.pri+8,half,z.sec)end
        if crate then
            L.cs=K.even(math.min(320,math.min(w,h)*.8));L.cx,L.cy=x+w/2,y+h/2
            local as=K.even(L.cs*(1.25+.1*tier));aura.Position=UDim2.fromOffset(L.cx,L.cy);aura.Size=UDim2.fromOffset(as,as)
            if core then local c2=K.even(L.cs*.8);core.Position=UDim2.fromOffset(L.cx,L.cy);core.Size=UDim2.fromOffset(c2,c2)end
        end
    end
    if tm then K.fade(content,false,0);if reduced then K.fade(back,false,0)end end
    layout()
    if settled then K.appear(card,{scaleFrom=.96,t=.16})end
    current={gui=gui,skip=settled==true,elapsed=0,result=result};local state=current
    if settled and mapLook then
        local char=game.Players.LocalPlayer.Character;current.hidden={}
        if char then for _,p in ipairs(char:GetDescendants())do if p:IsA('BasePart')or p:IsA('Decal')then current.hidden[p]=p.LocalTransparencyModifier;p.LocalTransparencyModifier=1 end end end
    end
    shade.Activated:Connect(function()if not footer.Visible then state.skip=true end end)
    Telemetry.emit('supply_reveal',{stage='opened',rarity=result.rarity,sku=result.kind})
    local auraA,lidA,coreA=.3+.1*tier,.45+.08*tier,tier>=5 and .5 or .35
    local function light(t)
        if not tm then return 0 end
        local u=t-tm.s1;local life=tm.light;if u<=0 or u>=life then return 0 end
        if u<tm.lid then return ease(u/tm.lid)end
        local fall=life*.4;if u<life-fall then return 1 end
        return 1-ease((u-(life-fall))/fall,true)
    end
    local function refresh()retry:setEnabled(not shop.busy);if equip then equip:setEnabled(not state.equipped and not shop.busy)end end
    local function drive(t,instant)
        if tm and not state.sealed and t>=tm.s0 then state.sealed=true;if not instant then Audio.play('supplySeal',.6)end end
        local e=light(t)
        if crate then
            local gone=reduced and tm.s2+tm.flip or mid
            if t>=gone then crate.Visible=false
            else
                local a=ease(t/tm.inn);local dx,roll,yaw,out=0,0,0,0
                if reduced then if t>=tm.s2 then out=ease((t-tm.s2)/tm.flip)end
                else
                    crateScale.Scale=.96+.04*a
                    if t>=tm.s0 and t<tm.s1 then local u=(t-tm.s0)/(tm.s1-tm.s0);local wave=math.sin(u*math.pi*6)*(1-u);dx=wave*(4+tier);roll=wave*.06 end
                    if t>=tm.s2 then out=ease((t-tm.s2)/(tm.flip/2),true);yaw=out*math.pi/2 end
                end
                crateView.ImageTransparency=math.max(1-a,out);lid.ImageTransparency=1-lidA*e*(1-out)
                crate.Size=UDim2.fromOffset(L.cs,L.cs);crate.Position=UDim2.fromOffset(L.cx+math.floor(dx+.5),L.cy)
                crateCtx.model:PivotTo(crateCtx.base*CFrame.Angles(0,yaw,roll));Preview.step(crateCtx,t,1)
            end
            aura.ImageTransparency=1-auraA*e;if not reduced then auraScale.Scale=.85+(.1+.04*tier)*e end
            if core then core.ImageTransparency=1-coreA*e end
        end
        if tm and t>=mid then
            local ft=reduced and .12 or tm.flip/2
            back.Visible=true;back.Size=UDim2.fromOffset(reduced and L.w or math.max(2,K.even(L.w*ease((t-mid)/ft))),L.h)
            if not state.faced then state.faced=true;K.fade(content,true,instant and 0 or ft);if reduced then K.fade(back,true,instant and 0 or ft)end
                if not state.heard then state.heard=true;Audio.play('supply_'..result.rarity,.8)end end
            if reward then reward.ImageTransparency=1-ease((t-mid)/ft)end
        end
        if onMap then onMap.Visible=not tm or t>=mid end
        if context and (not tm or t>=mid)then Preview.step(context,t,tm and 1+math.floor(math.clamp((t-tm.s2)/.6,0,1)*2)or 3)end
        if not state.edged and t>=(tm and tm.s3 or 0)then state.edged=true
            local st=back:FindFirstChild('Stroke20');if st then st.Color=color;st.Thickness=2 end
            if not instant and not reduced then K.punch(card,tier>=4 and 1.06 or 1.04,.14)end
        end
        if t>=(tm and tm.s4 or 0)then
            if not state.finished then state.finished=true
                Telemetry.emit('supply_reveal',{stage='outcome',rarity=result.rarity,sku=result.kind,reason=state.skip and 'skipped'or 'completed',duration_ms=state.elapsed*1000,completed=true,result=dup and 'duplicate'or 'granted'})
                Telemetry.step('gacha',dup and 'revealDuplicate'or 'revealNew',{sku=result.kind,rarity=result.rarity,item=require(script.Parent.TelemetryStep).code(result.id),duration_ms=state.elapsed*1000,reason=state.skip and 'skipped'or 'completed'})
                if not state.heard then state.heard=true;Audio.play('supply_'..result.rarity,.8)end
                refresh()
                if instant then footer.Visible=true else K.appear(footer,{dy=reduced and 0 or 8,t=.16})end
                if bar then task.delay((reduced or instant)and 0 or .35,function()if dupBox.Parent then bar:set(count/5,not reduced)
                    if result.refundTickets then dupLine.Text=string.format('뽑기권 +%d',result.refundTickets)end end end)end
            end
            refresh()
        end
    end
    state.connection=game:GetService('RunService').RenderStepped:Connect(function(dt)
        if not gui.Parent or game.Players.LocalPlayer:GetAttribute('FrontierRoom')then M.close();return end
        local view=workspace.CurrentCamera.ViewportSize
        if state.viewport~=view or state.scale~=Theme.scale then state.viewport=view;state.scale=Theme.scale;layout()end
        state.elapsed+=dt;local t=state.skip and 99 or state.elapsed
        local phase=not tm and 'result'or t<tm.s1 and 'delivery'or t<tm.s2 and 'seal'or t<tm.s4 and 'reveal'or 'result'
        gui:SetAttribute('RevealPhase',phase);gui:SetAttribute('AwardedItem',result.id);gui:SetAttribute('AwardedGrade',result.rarity)
        drive(t,state.skip)
    end)
    state.input=game:GetService('UserInputService').InputBegan:Connect(function(input,handled)
        if handled then return end
        if input.KeyCode==Enum.KeyCode.Escape then M.close()
        elseif input.KeyCode==Enum.KeyCode.Space and footer.Visible==false then state.skip=true end
    end)
end
return M
