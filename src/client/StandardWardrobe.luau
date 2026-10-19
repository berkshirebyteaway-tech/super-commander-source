local UI=require(script.Parent.ToyUI)
local L=require(script.Parent.Localization)
local Rules=require(script.Parent.Parent.Core.CommanderStandardRules)
local Preview=require(script.Parent.WearablePreview)
local M={}
function M.draw(hub,body,w,y,shop)
    local a=hub.account;local level=a.progress and a.progress.level or 1
    local worn=a.commanderStandard or Rules.default;local selected=hub.standardPreview or worn
    local heading=UI.label(body,'StandardHint',string.format(L.text('레벨 %d / 플레이로 해금'),level),13,UI.colors.muted);UI.box(heading,2,y,w-4,24);y+=32
    local cols=w>=480 and 3 or 2;local cw=(w-(cols-1)*8)/cols
    for i,item in ipairs(Rules.items)do
        local unlocked=Rules.owns(item.id,level)
        local b=UI.button(body,'Standard_'..item.id,'',function()hub.standardPreview=item.id;hub:drawPage()end,selected==item.id)
        UI.box(b,(i-1)%cols*(cw+8),y+math.floor((i-1)/cols)*154,cw,146)
        if unlocked then b:SetAttribute('CollectionKey','standard:'..item.id)end
        b.BackgroundColor3=UI.colors.raised;local edge=b:FindFirstChildOfClass('UIStroke')or UI.stroke(b);edge.Color=selected==item.id and UI.colors.accent or UI.colors.line;edge.Thickness=selected==item.id and 2 or 1
        local preview=Preview.create(b,'commanderStandard',item.id);UI.box(preview,2,2,cw-4,90)
        local name=UI.label(b,'Name',item.name,12);name.TextTruncate=Enum.TextTruncate.AtEnd;UI.box(name,8,94,cw-16,24)
        local state=UI.label(b,'Unlock',worn==item.id and '장착 중'or unlocked and '보유'or string.format(L.text('Lv. %d 해금'),item.level),11,unlocked and UI.colors.accent or UI.colors.muted);UI.box(state,8,119,cw-16,19)
        if item.effect>0 then local chip=UI.label(b,'Effect','✦',13,UI.colors.gold);UI.box(chip,cw-25,8,18,20)end
        b:SetAttribute('Unlocked',unlocked);b:SetAttribute('UnlockLevel',item.level)
    end
    y+=math.ceil(#Rules.items/cols)*154+6
    local definition=Rules.find(selected)or Rules.items[1];local unlocked=Rules.owns(selected,level)
    local equip=UI.button(body,'EquipStandard',worn==selected and '장착 중'or unlocked and '장착'or string.format(L.text('Lv. %d 해금'),definition.level),function()
        if unlocked and worn~=selected and not shop.busy then shop:run(function()shop:request('commanderStandard',selected)end)end
    end,true);UI.box(equip,2,y,w-4,46);UI.enabled(equip,a.ready==true and unlocked and worn~=selected and not shop.busy)
    y+=58
    if a.billing and a.billing.testingAvailable then
        local test=UI.button(body,'TestStandardLevel','Studio Lv.100 테스트',function()shop:run(function()shop:request('standardTestLevel')end)end)
        UI.box(test,2,y,w-4,44);UI.enabled(test,not shop.busy and level<100);y+=54
    end
    body.CanvasSize=UDim2.fromOffset(0,y+8)
end
return M
