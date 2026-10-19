local UI=require(script.Parent.ToyUI)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local L=require(script.Parent.Localization)
local TitleStyle=require(script.Parent.TitleStyle)
local Career=require(script.Parent.Parent.Core.CareerRules)
local M={}
function M.flush(hub)
    local pending=hub.honorPending;if not pending or next(pending)==nil then return end
    hub.honorPending=nil;hub.honorToken=(hub.honorToken or 0)+1
    local shop=hub.callbacks.shop()
    task.spawn(function()
        for kind,id in pairs(pending)do
            local r=shop:request('career',kind,id)
            if not(r and r.ok)then hub.notify('칭호 저장에 실패했어요. 다시 골라 주세요.',true)end
        end
    end)
end
local function pick(hub,kind,id)
    pcall(function()require(script.Parent.TelemetryClient).step('cosmetics',kind=='title'and (id=='none'and 'titleNone'or id==''and 'titleRank'or 'titleWear')or 'plateWear')end)
    hub.honorPending=hub.honorPending or {};hub.honorPending[kind]=id
    hub.honorToken=(hub.honorToken or 0)+1;local token=hub.honorToken
    hub:drawPage()
    task.delay(3,function()if hub.honorToken==token then M.flush(hub)end end)
end
function M.draw(hub,body,w,y,shop)
    local p=hub.account.progress or {};local career=p.career;if not career then return y end
    for _,group in ipairs({{'title','titles','칭호'},{'plate','plates','명판'}})do
        local kind,key,title=table.unpack(group);local list=career[key]or {}
        local pending=hub.honorPending and hub.honorPending[kind]
        local worn=pending or career.equipped[kind]
        local heading=UI.label(body,'Heading_'..kind,L.text(title)..' ('..#list..')',16);UI.box(heading,4,y,w-8,28);y+=34
        local choices=kind=='title'and {{id='none',name=L.text('없음')},{id='',name=L.text('계급 표시')..': '..L.text(p.title or '훈련병')}}or {{id='',name=L.text('기본 명판')}}
        local sorted=table.clone(list)
        if kind=='title'then table.sort(sorted,function(a,b)
            if (a.tier or 0)~=(b.tier or 0)then return (a.tier or 0)>(b.tier or 0)end
            local la,lb=tonumber(a.id:match('^lv:(%d+)$'))or 0,tonumber(b.id:match('^lv:(%d+)$'))or 0
            if la~=lb then return la>lb end;return a.id<b.id end)end
        for _,item in ipairs(sorted)do table.insert(choices,item)end
        local cols=w>=480 and 2 or 1;local cw=(w-(cols-1)*8)/cols
        for i,item in ipairs(choices)do
            local selected=(worn or '')==item.id
            local b=UI.button(body,'Honor_'..kind..'_'..item.id,'',function()
                if not selected then pick(hub,kind,item.id)end
            end);UI.box(b,(i-1)%cols*(cw+8),y+math.floor((i-1)/cols)*64,cw,56)
            local tier=kind=='title'and item.tier or 0;local tint=TitleStyle.color(tier)
            UI.stroke(b,selected and UI.colors.accent or tint and tint:Lerp(UI.colors.line,tier>=4 and .25 or .6)or UI.colors.line,selected and 2 or 1)
            if tier>=4 then
                local glow=UI.make('Frame',b,{Name='TierGlow',BackgroundColor3=tint,BorderSizePixel=0});UI.box(glow,0,0,cw,56);UI.corner(glow,3)
                UI.make('UIGradient',glow,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,tier>=5 and .7 or .78),NumberSequenceKeypoint.new(.75,1),NumberSequenceKeypoint.new(1,1)})})
            end
            if tint then local bar=UI.make('Frame',b,{Name='TierBar',BackgroundColor3=tint,BorderSizePixel=0});UI.box(bar,0,0,4,56)end
            if item.id~=''then b:SetAttribute('CollectionKey',key..':'..item.id)end
            local x=12
            if item.color then local c=item.color;local sw=UI.make('Frame',b,{Name='Color',BackgroundColor3=Color3.fromRGB(c[1],c[2],c[3]),BorderSizePixel=0});UI.box(sw,10,16,24,24);UI.corner(sw,3);x=44 end
            local meta=item.map and Maps.meta(item.map)
            local name=item.name or string.format(L.text(item.format or '%s'),meta and meta.label or item.map or '')
            local label=UI.label(b,'Name',name,tint and 16 or 14);UI.box(label,x,7,cw-x-42,tint and 26 or 42);label.TextTruncate=Enum.TextTruncate.AtEnd;label.TextWrapped=false
            if tint then
                TitleStyle.apply(label,tier)
                local grade=UI.label(b,'Tier',L.text(Career.titleTiers[tier]),11,tint);UI.box(grade,x,33,cw-x-42,16)
            end
            local check=UI.label(b,'Equipped',selected and '✓'or '',20,UI.colors.accent);UI.box(check,cw-36,12,24,32)
        end
        y+=math.ceil(#choices/cols)*64+16
    end
    return y
end
return M
