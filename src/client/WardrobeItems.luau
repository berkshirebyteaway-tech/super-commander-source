local UI=require(script.Parent.ToyUI)
local L=require(script.Parent.Localization)
local Icons=require(script.Parent.OutgameIcons)
local Preview=require(script.Parent.CollectionPreview)
local Wearable=require(script.Parent.WearablePreview)
local Reveal=require(script.Parent.SupplyReveal)
local C=require(script.Parent.Parent.Core.CosmeticCatalog)
local Supply=require(script.Parent.Parent.Core.SupplyCatalog)
local Defs=require(script.Parent.Parent.Core.CollectionDefinitions)
local Launch=require(script.Parent.Parent.Core.LaunchCommerce)
local Standards=require(script.Parent.Parent.Core.CommanderStandardRules)
local Halloween=require(script.Parent.Parent.Core.HalloweenEvent)
local M={}
local function step(name,data)local ok,T=pcall(require,script.Parent.TelemetryClient);if ok and T.step then pcall(T.step,'cosmetics',name,data)end end
M.tabs={{'commanderStandard','깃발'},{'territory','영토'},{'city','건물'},{'projectile','핵'},{'commanderTrail','트레일'},{'parachute','낙하산'},{'vehicle','탈것'},{'commanderOrder','지휘 연출'}}
local legacy={'arctic','copper'}
M.noneSlots={vehicle={desc='아무것도 타지 않고 걸어 다녀요'},commanderTrail={desc='지나간 자리에 아무것도 남기지 않아요'}}
function M.emptyPreview(parent)
    local f=UI.make('Frame',parent,{Name='NonePreview',BackgroundTransparency=1})
    local ring=UI.make('Frame',f,{Name='Ring',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(.42,.42),BackgroundTransparency=1});UI.make('UIAspectRatioConstraint',ring,{})
    UI.make('UICorner',ring,{CornerRadius=UDim.new(1,0)});UI.make('UIStroke',ring,{Color=UI.colors.muted,Thickness=2,Transparency=.3})
    local bar=UI.make('Frame',ring,{Name='Slash',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(1,0,0,2),Rotation=-45,BackgroundColor3=UI.colors.muted,BackgroundTransparency=.3,BorderSizePixel=0})
    return f
end
function M.standardGrade(level)return level>=100 and 'mythic'or level>=75 and 'legendary'or level>=30 and 'epic'or level>=5 and 'rare'or 'normal'end
M.notes={nuclear='로켓, 궤적, 폭발이 함께 바뀌어요',buildings='모든 건물에 적용돼요'}
local function text(p,name,value,x,y,w,h,size,color,align)
    local l=UI.label(p,name,value,size,color);UI.box(l,x,y,w,h);l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd
    if align then l.TextXAlignment=align end;return l
end
local function wearing(a,slots,id)for _,s in ipairs(slots)do if (a.cosmetics and a.cosmetics[s]or C.default)~=id then return false end end;return true end
local function entries(hub,slot,shop)
    local a=hub.account;local p=a.progress or {};local out={}
    if slot=='commanderStandard'then
        local level=p.level or 1;local worn=a.commanderStandard or Standards.default
        for _,item in ipairs(Standards.items)do local id=item.id;local owned=Standards.owns(id,level)
            table.insert(out,{id=id,name=item.name,color=item.effect>0 and UI.colors.gold or UI.colors.accent,grade=item.effect>0 and '특수'or nil,owned=owned,worn=worn==id,level=item.level,rarity=M.standardGrade(item.level),
                lock=string.format(L.text('Lv. %d 해금'),item.level),key=owned and item.level>1 and 'standard:'..id or nil,
                desc=item.level>1 and string.format(L.text('Lv. %d 보상 깃발'),item.level)or '처음부터 쓰는 지휘관 깃발',
                preview=function(parent,hero)return Wearable.create(parent,'commanderStandard',id,{flagOnly=not hero})end,
                equip=function()shop:run(function()shop:request('commanderStandard',id)end)end})
        end
        for _,item in ipairs(Standards.series)do local id=item.id;local owned=a.billing and a.billing.owned and a.billing.owned[Standards.supplyId(id)]==true
            table.insert(out,{id=id,name=item.name,color=Reveal.colors[item.rarity],grade=Launch.rarityNames[item.rarity],owned=owned,worn=worn==id,rarity=item.rarity,supply=Standards.supplyId(id),
                lock='보급 상자에서 획득',key=owned and 'standard:'..id or nil,desc=item.desc,
                preview=function(parent,hero)return Wearable.create(parent,'commanderStandard',id,{flagOnly=not hero})end,
                equip=function()shop:run(function()shop:request('commanderStandard',id)end)end})
        end
        return out
    end
    local family=Defs.family(slot);local slots=family.slots;local loadout={};for _,s in ipairs(slots)do loadout[s]=C.default end
    local base={style=C.default,category=family.id,loadout=loadout}
    local role=slot=='city'and 'City'or nil;local note=M.notes[family.id]
    local function preview(item)return function(parent,hero)
        if family.id=='territory'and C.get(item.style).flat then return require(script.Parent.SkinMapScene).patch(parent,item)end
        if family.id=='buildings'and hero then
            local v=Preview.create(parent,item,{roles=require(script.Parent.BuildingModels).previewOrder});v.Name='BuildingRow'
            return v
        end
        return Preview.create(parent,item,{role=role})
    end end
    local none=M.noneSlots[family.id]
    table.insert(out,{id=C.default,name=none and '없음'or '기본',color=UI.colors.muted,owned=true,rarity='normal',item=not none and base or nil,none=none,worn=wearing(a,slots,C.default),desc=none and none.desc or '처음부터 가진 기본 외형',note=note,preview=not none and preview(base)or M.emptyPreview,
        equip=function()shop:equip(C.default,#slots>1 and slots or slots[1])end})
    for _,id in ipairs(legacy)do
        local mine={};for _,s in ipairs(slots)do if (a.owned or {})[id]or (p.ownedSlots or {})[s..':'..id]then table.insert(mine,s)end end
        if #mine>0 then local l={};for _,s in ipairs(slots)do l[s]=id end
            table.insert(out,{id=id,name=C.get(id).name,color=UI.colors.ice,owned=true,rarity='rare',item={style=id,category=family.id,loadout=l},worn=wearing(a,mine,id),desc='출시 기념 외형',key='skin:'..slot..':'..id,
                preview=preview({style=id,category=family.id,loadout=l}),equip=function()shop:equip(id,#mine>1 and mine or mine[1])end})
        end
    end
    local rank={normal=1,rare=2,epic=3,legendary=4,mythic=5};local items={}
    for i,item in ipairs(Supply.items)do if item.category==family.id then table.insert(items,{item=item,i=i})end end
    table.sort(items,function(x,y)local a,b=rank[x.item.rarity]or 0,rank[y.item.rarity]or 0;if a~=b then return a<b end;return x.i<y.i end)
    local now=workspace:GetServerTimeNow()
    local eventLive=Halloween.view(nil,now,script.Parent.Parent:GetAttribute('HalloweenEndsAt')).live
    for _,row in ipairs(items)do local item=row.item;local owned=a.billing and a.billing.owned and a.billing.owned[item.id]==true
    local limited=item.event==Halloween.id and not eventLive and Halloween.ended(now)
    if not item.event or owned or eventLive or limited then
        local style=C.get(item.style)
        table.insert(out,{id=item.style,name=item.name,color=Reveal.colors[item.rarity],grade=Launch.rarityNames[item.rarity],owned=owned,rarity=item.rarity,supply=not item.event and item.id or nil,item=item,worn=wearing(a,slots,item.style),
            lock=limited and '한정'or item.event and '멀티 5판으로 획득'or '보급 상자에서 획득',event=item.event,limited=limited or nil,desc=style.desc,note=note,key=owned and 'skin:'..slot..':'..item.style or nil,preview=preview(item),
            equip=function()shop:run(function()shop:request('equipSupply',item.id)end)end})
    end end
    return out
end
M.entries=entries
local function wornName(hub,slot)
    local a=hub.account
    if slot=='flag'then return a.flag and '국기'or '프로필'end
    if slot=='commanderStandard'then local item=Standards.find(a.commanderStandard or Standards.default);return item and item.name or '기본',UI.colors.muted end
    local id=a.cosmetics and a.cosmetics[slot]or C.default
    if id==C.default then return (slot=='vehicle'or slot=='commanderTrail')and '없음'or '기본',UI.colors.muted end
    local item;for _,v in ipairs(Supply.items)do if v.style==id then item=v end end
    return C.get(id).name,item and Reveal.colors[item.rarity]or UI.colors.ice
end
M.wornName=wornName
function M.tiles(hub,body,w,y)
    local short=hub.pageBody.AbsoluteSize.Y/require(script.Parent.Theme).scale<330
    local cols=w>=600 and #M.tabs or 5;local gap=6;local cw=(w-gap*(cols-1))/cols;local h=short and 48 or 56
    for i,t in ipairs(M.tabs)do
        local slot,label=t[1],t[2];local selected=hub.slot==slot
        local b=UI.button(body,'Slot_'..slot,'',function()hub.slot=slot;hub.wardrobePick=nil;hub.pageBody.CanvasPosition=Vector2.zero;hub:drawPage()end,selected)
        UI.box(b,(i-1)%cols*(cw+gap),y+math.floor((i-1)/cols)*(h+gap),cw,h)
        text(b,'Category',label,4,short and 7 or 13,cw-8,20,cw<70 and 13 or 15,selected and UI.colors.bg or UI.colors.ink,Enum.TextXAlignment.Center)
        local name,color=wornName(hub,slot)
        text(b,'Worn',name,4,short and 27 or 34,cw-8,16,11,selected and UI.colors.bg or color or UI.colors.muted,Enum.TextXAlignment.Center)
    end
    return y+math.ceil(#M.tabs/cols)*(h+gap)+6
end
local function heroPanel(hub,body,w,y,e,short)
    local h=short and 150 or 180
    local card=UI.corner(UI.make('Frame',body,{Name='WardrobeHero',BackgroundColor3=UI.colors.panel,BorderSizePixel=0}),6);UI.box(card,0,y,w,h)
    UI.stroke(card,e.color:Lerp(UI.colors.line,.4),e.grade and 1.5 or 1)
    UI.make('UIGradient',card,{Rotation=0,Color=ColorSequence.new(e.color:Lerp(UI.colors.bg,.7),UI.colors.panel)})
    local vw=math.floor(w*.5)
    if e.grade then local pool=UI.corner(UI.make('Frame',card,{Name='Spotlight',BackgroundColor3=e.color,BackgroundTransparency=.88,BorderSizePixel=0}),999);UI.box(pool,vw*.18,h*.74,vw*.64,h*.16)end
    local view=e.preview(card,true);UI.box(view,8,6,vw-8,h-12)
    local x=vw+12;local tw=w-x-14
    if e.grade then local g=UI.pill(card,'Grade',e.grade,e.color);UI.box(g,x,16,math.max(56,#e.grade*9+22),24);g.TextSize=13 end
    text(card,'Name',e.name,x,e.grade and 46 or 18,tw,34,short and 22 or 26,e.grade and e.color or UI.colors.ink)
    if not short then local d=text(card,'Desc',e.desc or '',x,e.grade and 80 or 56,tw,38,13,UI.colors.muted);d.TextWrapped=true;d.TextYAlignment=Enum.TextYAlignment.Top end
    if e.note and h-58-(e.grade and 118 or 94)>=0 then text(card,'Covers',e.note,x,h-80,tw,18,12,UI.colors.ice)end
    local by=h-58;local shop=hub.callbacks.shop()
    if e.worn then
        local b=UI.button(card,'Equip','✓  장착 중',function()end);UI.box(b,x,by,tw,46);UI.enabled(b,false);b.TextColor3=UI.colors.accent
    elseif e.owned then
        local b=UI.button(card,'Equip','장착',function()step('equip',{item=e.id});e.equip()end,true);UI.box(b,x,by,tw,46);b.TextSize=18;UI.enabled(b,not shop.busy)
    elseif e.lock=='보급 상자에서 획득'then
        local b=UI.button(card,'GetSupply','보급 상자에서 획득  ›',function()step('toShop',{item=e.id});hub:openPage('shop')end);UI.box(b,x,by,tw,46);b.TextColor3=UI.colors.gold
        local edge=b:FindFirstChildOfClass('UIStroke');if edge then edge.Color=UI.colors.gold:Lerp(UI.colors.line,.4)end
    else
        local b=UI.button(card,'Locked',e.lock or '잠김',function()end);UI.box(b,x,by,tw,46);UI.enabled(b,false)
    end
    return y+h+10
end
local function styleCard(b,e,selected)
    b.BackgroundColor3=selected and UI.colors.raised:Lerp(e.color,.12)or UI.colors.panel
    local edge=b:FindFirstChildOfClass('UIStroke');if edge then edge.Color=selected and UI.colors.accent or e.color:Lerp(UI.colors.line,.55);edge.Thickness=selected and 2.5 or 1 end
end
local function pick(hub,e)
    hub.wardrobePick=e.id;step('previewOpened',{item=e.id})
    local view=hub.wardrobeView;local hero=view and view.body==hub.pageBody and view.body:FindFirstChild('WardrobeHero')
    local card=view and view.cards[e.id]
    if not(hero and card and card.Parent)then hub:drawPage();return end
    if view.current==e then return end
    local old=view.current and view.cards[view.current.id];if old and old.Parent then styleCard(old,view.current,false)end
    styleCard(card,e,true);view.current=e
    hero:Destroy();heroPanel(hub,view.body,view.w,view.heroY,e,view.short)
end
local function itemCard(hub,body,e,selected,x,y,cw,ch)
    local b=UI.button(body,'Item_'..e.id,'',function()pick(hub,e)end)
    UI.box(b,x,y,cw,ch);b.AutoButtonColor=true;styleCard(b,e,selected)
    if e.key then b:SetAttribute('CollectionKey',e.key)end;b:SetAttribute('Owned',e.owned)
    UI.make('Frame',b,{Name='GradeStripe',BackgroundColor3=e.color,BorderSizePixel=0,Size=UDim2.new(1,0,0,3),BackgroundTransparency=e.grade and 0 or .5})
    local view=e.preview(b,false);UI.box(view,4,6,cw-8,ch-52)
    if not e.owned and view:IsA('ViewportFrame')then view.ImageColor3=Color3.fromRGB(214,219,226)end
    text(b,'Name',e.name,6,ch-46,cw-12,22,cw<100 and 12 or 14,e.owned and UI.colors.ink or UI.colors.muted,Enum.TextXAlignment.Center)
    local state=e.worn and '장착 중'or e.owned and (e.grade or '보유')or (e.grade or e.lock)
    local s=text(b,'State',state,6,ch-24,cw-12,18,11,e.worn and UI.colors.accent or e.color,Enum.TextXAlignment.Center)
    if not e.owned then UI.box(Icons.create(b,'lock',14,UI.colors.muted),6,10,14,14);s.TextTransparency=.25 end
    if e.worn then local tick=UI.pill(b,'Worn','✓',UI.colors.accent);UI.box(tick,cw-28,8,22,20);tick.TextSize=13 end
    return b
end
function M.draw(hub,body,w,y,shop)
    local slot=hub.slot
    local list=entries(hub,slot,shop)
    local pick=hub.wardrobePick;local current
    for _,e in ipairs(list)do if e.id==pick then current=e end end
    if not current then for _,e in ipairs(list)do if e.worn then current=e end end end
    current=current or list[1]
    local viewY=body.AbsoluteSize.Y/require(script.Parent.Theme).scale;local short=viewY<330
    local view={body=body,w=w,heroY=y,short=short,current=current,cards={}};hub.wardrobeView=view
    y=heroPanel(hub,body,w,y,current,short)
    local owned=0;for _,e in ipairs(list)do if e.owned then owned+=1 end end
    local only=hub.ownedOnly==true
    local f=UI.button(body,'OwnedOnly',(only and '☑  'or '☐  ')..'보유 중만',function()hub.ownedOnly=not only;step('ownedFilter',{value=only and 0 or 1});hub:drawPage()end,only);UI.box(f,0,y,124,36);f.TextSize=13
    text(body,'OwnedCount',string.format(L.text('보유 %d / %d'),owned,#list),136,y,140,36,13,UI.colors.muted)
    if slot~='commanderStandard'then
        local go=UI.button(body,'ToShop','보급 상자  ›',function()hub:openPage('shop')end);UI.box(go,w-128,y,128,36);go.TextSize=13;go.TextColor3=UI.colors.gold
    end
    y+=44
    local shown={};for _,e in ipairs(list)do if not only or e.owned then table.insert(shown,e)end end
    local cols=w>=640 and math.min(6,math.max(#shown,4))or w>=420 and 4 or 3;local gap=8;local cw=(w-gap*(cols-1))/cols;local ch=math.floor(math.clamp(cw*1.28,128,156))
    for i,e in ipairs(shown)do view.cards[e.id]=itemCard(hub,body,e,e==current,(i-1)%cols*(cw+gap),y+math.floor((i-1)/cols)*(ch+gap),cw,ch)end
    y+=math.ceil(#shown/cols)*(ch+gap)+6
    if slot=='commanderStandard'and hub.account.billing and hub.account.billing.testingAvailable then
        local test=UI.button(body,'TestStandardLevel','Studio Lv.100 테스트',function()shop:run(function()shop:request('standardTestLevel')end)end)
        UI.box(test,0,y,w,44);UI.enabled(test,not shop.busy and (hub.account.progress.level or 1)<100);y+=54
    end
    return y
end
return M
