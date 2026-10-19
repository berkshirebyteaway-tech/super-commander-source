local UI=require(script.Parent.ToyUI)
local Rules=require(script.Parent.Parent.Core.OutgameRules)
local C=require(script.Parent.Parent.Core.CosmeticCatalog)
local Models=require(script.Parent.BuildingModels)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local Flags=require(script.Parent.Flags)
local Icons=require(script.Parent.OutgameIcons)
local M={}
local Currency=require(script.Parent.CurrencyChip)
local Claims=require(script.Parent.GoalClaims)
local function rewards(parent,x,y,w,xp,medals)
    Currency.create(parent,'xp',xp,x,y,w*.5-3,24)
    Currency.create(parent,'medal',medals,x+w*.5+3,y,w*.5-3,24)
end
local function text(parent,name,value,x,y,w,h,size,color)local l=UI.label(parent,name,value,size or 14,color);UI.box(l,x,y,w,h);return l end
local function bar(parent,name,x,y,w,ratio)
    local track=UI.corner(UI.make('Frame',parent,{Name=name,BackgroundColor3=UI.colors.raised,BorderSizePixel=0}),5);UI.box(track,x,y,w,8)
    UI.corner(UI.make('Frame',track,{Name='Fill',BackgroundColor3=UI.colors.accent,BorderSizePixel=0,Size=UDim2.fromScale(math.clamp(ratio,0,1),1)}),5)
end
function M.draw(hub,body,w)
    local a=hub.account;local p=a.progress or {};local shop=hub.callbacks.shop();local y=0
    local function heading(value,icon)local l=text(body,'Heading'..y,value,icon and 30 or 2,y,icon and w-28 or w,32,18)
        if icon then UI.box(Icons.create(body,icon,20,UI.colors.accent),2,y+6,20,20)end;y+=40;return l end
    local function action(name,title,fn,primary)local b=UI.button(body,name,title,fn,primary);UI.box(b,2,y,w-4,46);y+=54;UI.enabled(b,a.ready==true and not shop.busy);return b end
    if not a.ready then
        text(body,'Loading',a.loading and '기록을 불러오는 중…'or '기록 불러오기 실패',8,8,w-16,50,16);y=70
        local retry=action('Restore','다시 불러오기',function()shop:run(function()shop:request('restore')end)end,true);UI.enabled(retry,not shop.busy)
        body.CanvasSize=UDim2.fromOffset(0,y);return
    end
    if hub.page=='missions'then
        require(script.Parent.GoalsScreen).draw(hub,body,shop);return
    elseif hub.page=='records'then
        heading('Lv. '..tostring(p.level or 1)..'  '..(p.title or '훈련병')..(p.titleText and p.titleText~=''and p.titleText~=p.title and '  / '..p.titleText or ''),'xp')
        text(body,'XP',p.nextXP==0 and '최고 레벨 / '..UI.number(p.xp)..' XP'or (p.nextRankName and string.format('%s / %s XP / 다음 %s (Lv%d)',UI.number(p.currentXP or 0),UI.number(p.nextXP or 100),p.nextRankName,p.nextRankLevel)or (UI.number(p.currentXP or 0)..' / '..UI.number(p.nextXP or 100)..' XP')),4,y,w,24,12,UI.colors.muted);y+=32
        bar(body,'XPProgress',4,y,w-8,p.nextXP==0 and 1 or (p.currentXP or 0)/math.max(1,p.nextXP or 100));y+=24
        y=require(script.Parent.RecordsView).draw(hub,body,w,y,p)
        text(body,'RecordNote',a.localMode and 'Studio 연습 기록 / 정지 시 초기화'or '작전할수록 레벨 업',2,y,w,34,13,UI.colors.muted);y+=42
    elseif hub.page=='wardrobe'then
        require(script.Parent.SkinScreen).draw(hub,body,shop);return
    end
    body.CanvasSize=UDim2.fromOffset(0,y+8)
end
return M
