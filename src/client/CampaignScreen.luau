local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.OutgameIcons)
local Currency=require(script.Parent.CurrencyChip)
local Step=require(script.Parent.TelemetryStep)
local Campaign=require(script.Parent.Parent.Core.CampaignRules)
local Flow=require(script.Parent.Parent.Core.PlayFlow)
local Commands=require(script.Parent.Parent.Core.CommandPresentation)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local Raster=require(script.Parent.RasterMap)
local M={}
local C=UI.colors
local GOLD=Color3.fromRGB(232,184,72)
local FLAME=Color3.fromRGB(236,112,52)
local DIM=Color3.fromRGB(70,78,92)
local function label(parent,name,text,size,color,x,y,w,h,align)
    local l=UI.label(parent,name,text,size or 14,color or C.ink);UI.box(l,x,y,w,h)
    if align then l.TextXAlignment=align end;return l
end
local function regular(l)l.Font=Enum.Font.BuilderSansMedium;return l end
local function card(parent,name,x,y,w,h,fill)
    local p=UI.panel(parent,name);UI.box(p,x,y,w,h);p.BackgroundColor3=fill or C.panel;p.BackgroundTransparency=.04;return p
end
local function edge(p,color,thick)local s=p:FindFirstChildOfClass('UIStroke');if s then s.Color=color;s.Thickness=thick or 1;s.Transparency=0 end end
local function flames(parent,n,x,y,size)
    for i=1,5 do local f=UI.corner(UI.make('Frame',parent,{Name='Flame'..i,BackgroundColor3=i<=n and FLAME or DIM,BorderSizePixel=0}),2);UI.box(f,x+(i-1)*(size+3),y,size,size)end
end
local function code(id)return 'stage_'..tostring(id):gsub('%-','_')end
local function view(hub)return (hub.account.progress or {}).campaign or {stars={},total=0,chests=0,next=Campaign.stages[1].id}end
local function open(v,id)return Campaign.unlocked({campaign={stars=v.stars}},id)end
function M.start(hub,id)
    if hub.busy or hub.loading or Commands.soloLoading(hub)then return false end
    local decision=Flow.single(hub.data and hub.data.queue)
    local function go()Step.step('goals','campaignStart',{item=code(id)});hub:closePage();hub.callbacks.campaign(id)end
    if decision=='replace'then hub:request('cancel',nil,go);return true elseif decision~='moving'then go();return true end
    return false
end
local function nextChest(total)
    for _,c in ipairs(Campaign.chests)do if total<c.stars then return c end end
end
local function hero(hub,body,x,y,w,phone,v)
    local h=phone and 116 or 132
    local c=card(body,'CampaignHero',x,y,w,h,Color3.fromRGB(22,28,38))
    local ic=Icons.create(c,'campaign',phone and 44 or 64,GOLD);UI.box(ic,phone and 12 or 24,phone and 14 or (h-64)/2,phone and 44 or 64,phone and 44 or 64)
    local tx=phone and 68 or 108
    local bw=phone and 0 or 240
    UI.display(label(c,'Title','캠페인',phone and 22 or 30,C.ink,tx,phone and 8 or 18,w-tx-bw-24,phone and 28 or 40))
    label(c,'Stars',string.format('★ %d / %d',v.total or 0,Campaign.maxStars),phone and 16 or 18,GOLD,tx,phone and 38 or 60,200,24)
    local chest=nextChest(v.total or 0)
    local note=chest and string.format('별 %d개 상자까지 %d개',chest.stars,chest.stars-(v.total or 0))or '별 상자를 모두 열었어요'
    regular(label(c,'Chest',note,13,C.muted,tx,phone and 62 or 86,phone and w-tx-16 or w-tx-bw-120,20)).TextTruncate=Enum.TextTruncate.AtEnd
    if chest then Currency.create(c,'medal',chest.coins,phone and w-16-90 or tx+200,phone and 38 or 84,90,22)end
    local track=UI.corner(UI.make('Frame',c,{Name='ChestTrack',BackgroundColor3=C.raised,BorderSizePixel=0}),4);UI.box(track,tx,phone and 88 or 112,phone and w-tx-16 or w-tx-bw-48,6)
    local prev=0;for _,ch in ipairs(Campaign.chests)do if (v.total or 0)>=ch.stars then prev=ch.stars end end
    local ratio=chest and ((v.total or 0)-prev)/math.max(1,chest.stars-prev)or 1
    UI.corner(UI.make('Frame',track,{Name='Fill',BackgroundColor3=GOLD,BorderSizePixel=0,Size=UDim2.fromScale(math.clamp(ratio,0,1),1)}),4)
    if not phone then
        local s=Campaign.stage(v.next)or Campaign.stages[1]
        local go=UI.button(c,'Continue','',function()M.start(hub,s.id)end,true);UI.box(go,w-bw-24,(h-76)/2,bw,76)
        UI.display(label(go,'Action',(v.stars or {})[s.id]and '다시 출전'or '이어서 출전',20,C.bg,0,12,bw,26,Enum.TextXAlignment.Center))
        regular(label(go,'Stage',string.format('%s %s',s.id,s.name),13,C.bg,0,44,bw,20,Enum.TextXAlignment.Center))
        UI.enabled(go,open(v,s.id)and hub.account.ready==true and not hub.busy)
    end
    return y+h+(phone and 10 or 16)
end
local function detail(hub,body,x,y,w,phone,v,stage)
    local ch=Campaign.chapter(stage.chapter);local mask=(v.stars or {})[stage.id]or 0;local unlocked=open(v,stage.id)
    local mapW=phone and w-24 or math.min(360,w*.36);local mapH=phone and 120 or 196
    local textX=phone and 12 or mapW+28;local textW=phone and w-24 or w-mapW-40
    local h=phone and mapH+(unlocked and 404 or 432)or 256
    local c=card(body,'CampaignStage',x,y,w,h)
    if stage.boss then edge(c,GOLD,2)elseif stage.event then edge(c,FLAME,2)end
    local f=UI.make('Frame',c,{Name='MapPreview',BackgroundColor3=C.ocean,BorderSizePixel=0,ClipsDescendants=true});UI.box(f,12,12,mapW,mapH);UI.corner(f,3)
    local r=Raster.new(f,192,100);r:setPreview(Maps.preview(stage.map));task.defer(function()if f.Parent then r:fit();r:draw()end end);f.Destroying:Once(function()r:destroy()end)
    local meta=Maps.meta(stage.map)
    local ty=phone and mapH+24 or 12
    local kind=stage.boss and '보스'or stage.event and '이벤트'or nil
    if kind then local pill=UI.pill(c,'Kind',kind,stage.boss and GOLD or FLAME);UI.box(pill,textX,ty+4,56,22)end
    local kx=kind and textX+64 or textX
    local chText=phone and (kind and string.format('%d장',ch.id)or string.format('%d장 %s',ch.id,ch.name))or string.format('%d장 %s  %s',ch.id,ch.name,stage.id)
    local chl=regular(label(c,'Chapter',chText,13,C.muted,kx,ty+4,textW-(kx-textX)-104,22));chl.TextWrapped=false;chl.TextTruncate=Enum.TextTruncate.AtEnd
    flames(c,ch.flames,textX+textW-96,ty+9,14)
    UI.display(label(c,'Name',stage.name,phone and 22 or 26,C.ink,textX,ty+28,textW,32))
    local rules=Campaign.rulesLine(stage)
    regular(label(c,'Rules',string.format('%s  %s',meta and meta.label or stage.map,rules),13,C.accent,textX,ty+62,textW,20)).TextTruncate=Enum.TextTruncate.AtEnd
    local brief=regular(label(c,'Brief',stage.brief,14,C.ink,textX,ty+84,textW,phone and 58 or 38));brief.TextWrapped=true;brief.TextYAlignment=Enum.TextYAlignment.Top
    local tip=regular(label(c,'Tip',string.format('요령  %s',stage.tip),13,C.muted,textX,ty+(phone and 144 or 122),textW,phone and 36 or 20));tip.TextWrapped=true;tip.TextYAlignment=Enum.TextYAlignment.Top
    local rows={{1,'승리'},{2,string.format('%d분 안에 승리',ch.minutes)},{4,stage.task.label}}
    local sy=ty+(phone and 244 or 150)
    local rowW=(not phone and sy+24>h-64)and textW-216 or textW
    for i,row in ipairs(rows)do
        local on=mask//row[1]%2==1
        local sx=phone and textX or textX+(i-1)*(rowW/3);local sw=phone and textW or rowW/3-8
        local yy=phone and sy+(i-1)*28 or sy
        label(c,'Star'..i,on and '★'or '☆',18,on and GOLD or C.muted,sx,yy,22,24)
        regular(label(c,'StarText'..i,row[2],13,on and C.ink or C.muted,sx+24,yy,sw-24,24)).TextTruncate=Enum.TextTruncate.AtEnd
    end
    local by=phone and sy+84 or h-60
    local first=mask%2==0
    if first then
        regular(label(c,'Reward','첫 클리어',13,C.muted,textX,by+12,80,24))
        Currency.create(c,'medal',ch.coins,textX+80,by+12,90,24);Currency.create(c,'xp',ch.xp,textX+176,by+12,90,24)
    end
    local bw=phone and textW or 200
    local go=UI.button(c,'Deploy','',function()M.start(hub,stage.id)end,true)
    UI.box(go,phone and textX or textX+textW-bw,phone and ty+184 or by,bw,48)
    if not unlocked then go.BackgroundColor3=C.raised end
    label(go,'Action',unlocked and (first and '출전'or '다시 출전')or '잠겨 있어요',18,unlocked and C.bg or C.muted,0,0,bw,48,Enum.TextXAlignment.Center)
    UI.enabled(go,unlocked and hub.account.ready==true and not hub.busy)
    if not unlocked then
        local need=ch.unlockStars and (v.total or 0)<ch.unlockStars and string.format('별 %d개가 필요해요',ch.unlockStars)or '앞 작전을 이기면 열려요'
        regular(label(c,'Locked',need,13,GOLD,phone and textX or textX+(first and 276 or 0),phone and by+40 or by+12,phone and textW or textW-bw-(first and 284 or 8),24)).TextTruncate=Enum.TextTruncate.AtEnd
    end
    return y+h+(phone and 12 or 16)
end
local function stageCard(hub,parent,v,stage,x,y,w,h,picked)
    local mask=(v.stars or {})[stage.id]or 0;local unlocked=open(v,stage.id)
    local b=UI.button(parent,'Stage_'..stage.id,'',function()
        if hub.campaignPick~=stage.id then hub.campaignPick=stage.id;Step.step('goals','campaignPick',{item=code(stage.id)});hub.campaignScrollTop=true;hub:drawPage()end
    end,false)
    UI.box(b,x,y,w,h);b.BackgroundColor3=picked and C.raised:Lerp(C.ink,.14)or C.panel
    edge(b,picked and C.ink or stage.boss and GOLD or stage.event and FLAME or C.line,picked and 2 or 1)
    label(b,'Id',stage.id,13,unlocked and C.muted or DIM,10,6,60,18)
    if stage.boss or stage.event then label(b,'Kind',stage.boss and '보스'or '이벤트',12,stage.boss and GOLD or FLAME,w-70,6,60,18,Enum.TextXAlignment.Right)end
    local name=label(b,'Name',stage.name,15,unlocked and C.ink or DIM,10,24,w-20,22);name.TextWrapped=false;name.TextTruncate=Enum.TextTruncate.AtEnd
    if unlocked then label(b,'Stars',Campaign.starText(mask),15,mask>0 and GOLD or C.muted,10,h-26,w-20,20)
    else local ic=Icons.create(b,'lock',16,DIM);UI.box(ic,10,h-24,16,16)end
    return b
end
function M.draw(hub,body,x,w,y,phone)
    local v=view(hub)
    hub.campaignPick=Campaign.stage(hub.campaignPick)and hub.campaignPick or v.next
    local stage=Campaign.stage(hub.campaignPick)
    y=hero(hub,body,x,y,w,phone,v)
    y=detail(hub,body,x,y,w,phone,v,stage)
    local cols=phone and 2 or 5;local gap=phone and 8 or 12;local cw=(w-gap*(cols-1))/cols;local chH=phone and 76 or 84
    for _,ch in ipairs(Campaign.chapters)do
        local got=0;for _,s in ipairs(Campaign.stages)do if s.chapter==ch.id then got+=Campaign.count((v.stars or {})[s.id])end end
        local rw=phone and 150 or 200
        local ct=UI.display(label(body,'Chapter'..ch.id,string.format('%d장 %s',ch.id,ch.name),18,C.ink,x,y,w-rw,28));ct.TextWrapped=false;ct.TextScaled=true;UI.make('UITextSizeConstraint',ct,{MaxTextSize=18,MinTextSize=11})
        flames(body,ch.flames,x+w-(phone and 140 or 190),y+9,12)
        label(body,'ChapterStars'..ch.id,string.format('★ %d/15',got),14,got>0 and GOLD or C.muted,x+w-(phone and 62 or 110),y,phone and 62 or 110,28,Enum.TextXAlignment.Right)
        y+=34
        if ch.unlockStars and (v.total or 0)<ch.unlockStars then
            local lk=regular(label(body,'ChapterLock'..ch.id,string.format('별 %d개를 모으면 열려요. 지금 %d개예요.',ch.unlockStars,v.total or 0),13,C.muted,x,y-4,w,20));lk.TextWrapped=false;lk.TextScaled=true;UI.make('UITextSizeConstraint',lk,{MaxTextSize=13,MinTextSize=10});y+=20
        end
        local i=0
        for _,s in ipairs(Campaign.stages)do if s.chapter==ch.id then
            stageCard(hub,body,v,s,x+(i%cols)*(cw+gap),y+(i//cols)*(chH+gap),cw,chH,s.id==stage.id);i+=1
        end end
        y+=math.ceil(i/cols)*(chH+gap)+12
    end
    Step.once('campaignView','goals','campaignView',{value=v.total or 0})
    return y
end
return M
