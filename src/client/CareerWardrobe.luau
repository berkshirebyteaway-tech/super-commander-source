local UI=require(script.Parent.ToyUI)
local L=require(script.Parent.Localization)
local M={}
function M.flush(hub)
    local pending=hub.honorPending;if not pending or next(pending)==nil then return end
    hub.honorPending=nil;hub.honorToken=(hub.honorToken or 0)+1
    local shop=hub.callbacks.shop()
    task.spawn(function()
        for kind,id in pairs(pending)do
            local r=shop:request('career',kind,id)
            if not(r and r.ok)then hub.notify('명판 저장 실패',true)end
        end
    end)
end
local function pick(hub,kind,id)
    pcall(function()require(script.Parent.TelemetryClient).step('cosmetics','plateWear')end)
    hub.honorPending=hub.honorPending or {};hub.honorPending[kind]=id
    hub.honorToken=(hub.honorToken or 0)+1;local token=hub.honorToken
    hub:drawPage()
    task.delay(3,function()if hub.honorToken==token then M.flush(hub)end end)
end
M.pick=pick
function M.draw(hub,body,w,y,shop)
    local p=hub.account.progress or {};local career=p.career;if not career then return y end
    local kind,key='plate','plates';local list=career.plates or {}
    local pending=hub.honorPending and hub.honorPending[kind]
    local worn=pending or career.equipped[kind]
    local heading=UI.label(body,'Heading_'..kind,L.text('명판')..' ('..#list..')',16);UI.box(heading,4,y,w-8,28);y+=34
    local choices={{id='',name=L.text('기본 명판')}}
    for _,item in ipairs(list)do table.insert(choices,item)end
    local cols=w>=480 and 2 or 1;local cw=(w-(cols-1)*8)/cols
    for i,item in ipairs(choices)do
        local selected=(worn or '')==item.id
        local b=UI.button(body,'Honor_'..kind..'_'..item.id,'',function()
            if not selected then pick(hub,kind,item.id)end
        end);UI.box(b,(i-1)%cols*(cw+8),y+math.floor((i-1)/cols)*64,cw,56)
        UI.stroke(b,selected and UI.colors.accent or UI.colors.line,selected and 2 or 1)
        if item.id~=''then b:SetAttribute('CollectionKey',key..':'..item.id)end
        local x=12
        if item.color then local c=item.color;local sw=UI.make('Frame',b,{Name='Color',BackgroundColor3=Color3.fromRGB(c[1],c[2],c[3]),BorderSizePixel=0});UI.box(sw,10,16,24,24);UI.corner(sw,3);x=44 end
        local label=UI.label(b,'Name',item.name or '',14);UI.box(label,x,7,cw-x-42,42);label.TextTruncate=Enum.TextTruncate.AtEnd;label.TextWrapped=false
        local check=UI.label(b,'Equipped',selected and '✓'or '',20,UI.colors.accent);UI.box(check,cw-36,12,24,32)
    end
    y+=math.ceil(#choices/cols)*64+16
    return y
end
return M
