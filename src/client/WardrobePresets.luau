local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.OutgameIcons)
local M={}
local SLOTS,CHIP,GAP,LABEL=4,30,4,40
M.width=LABEL+SLOTS*(CHIP+GAP)-GAP
local function step(name,data)local ok,T=pcall(require,script.Parent.TelemetryClient);if ok and T.step then pcall(T.step,'cosmetics',name,data)end end
function M.draw(hub,body,x,y,h)
    local a=hub.account;local p=a.progress or {};local shop=hub.callbacks.shop()
    local open=a.billing and a.billing.benefits and a.billing.benefits.loadoutSlots or 2;local active=p.activeLoadout
    if type(active)~='number'or active>open then active=nil end
    local label=UI.label(body,'PresetLabel','프리셋',11,UI.colors.muted);UI.box(label,x,y,LABEL-4,h);label.TextXAlignment=Enum.TextXAlignment.Right
    for i=1,SLOTS do
        local index,locked=i,i>open;local saved=p.loadouts and p.loadouts[tostring(i)]~=nil
        local b=UI.button(body,'Preset'..i,locked and ''or tostring(i),function()
            if locked then step('presetLocked',{item='slot'..index,sku='permanent',result='unavailable'});hub:openPage('shop');return end
            if active==index or shop.busy then if shop.busy then step('presetPick',{item='slot'..index,result='rejected',reason='busy'})end;return end
            step('presetPick',{item='slot'..index,value=saved and 1 or 0,result='selected'});shop:run(function()shop:request('useLoadout',index)end)
        end,active==index)
        UI.box(b,x+LABEL+(i-1)*(CHIP+GAP),y,CHIP,h);b.TextSize=14
        if locked then UI.box(Icons.create(b,'lock',12,UI.colors.gold),CHIP/2-6,math.floor(h/2)-6,12,12);b.BackgroundTransparency=.55
        elseif not saved and active~=index then b.TextColor3=UI.colors.muted end
    end
end
return M
