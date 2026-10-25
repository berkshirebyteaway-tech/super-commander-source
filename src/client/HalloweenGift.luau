local Players=game:GetService('Players')
local H=require(script.Parent.Parent.Core.HalloweenEvent)
local Catalog=require(script.Parent.Parent.Core.SupplyCatalog)
local M={}
M.key='skin:territory:'..H.style
local function step(name,data)require(script.Parent.TelemetryStep).step('event',name,data)end
function M.due(lobby)
    if M.shown then return false end
    local a=lobby.account;local owned=a and a.billing and a.billing.owned
    if not(owned and owned[H.itemId]==true)then return false end
    if a.collectionSeen and a.collectionSeen[M.key]then M.shown=true;return false end
    if lobby.page or lobby.busy or Players.LocalPlayer:GetAttribute('FrontierRoom')then return false end
    if require(script.Parent.SupplyCinematic).playing()or require(script.Parent.LobbyIntro).active then return false end
    return not require(script.Parent.Pop20).isOpen()
end
function M.check(lobby)
    if not M.due(lobby)then return end
    M.shown=true
    local item=Catalog.find(H.itemId);if not item then return end
    local K=require(script.Parent.Kit20);local Pop=require(script.Parent.Pop20);local Theme=require(script.Parent.Theme)
    local C=K.colors;local gold=K.rarity.legendary
    local sc=Theme.scale or 1;local W,Hh=lobby.root.AbsoluteSize.X/sc,lobby.root.AbsoluteSize.Y/sc
    local fmt=require(script.Parent.Lobby20).format(W,Hh)
    local pad=fmt=='pc'and 20 or 16;local w=fmt=='pt'and K.even(W-32)or fmt=='ph'and 340 or 380
    local artH=fmt=='ph'and 120 or 170;local bh=fmt=='ph'and 44 or 48;local fs=fmt=='ph'and 16 or 17
    local h=pad+26+12+artH+12+22+4+24+20+bh+pad
    local shop=lobby.callbacks.shop()
    step('halloweenGift',{item=H.style,result='shown'})
    local mine=table.clone(lobby.account.collectionSeen or {});mine[M.key]=true;lobby.account.collectionSeen=mine
    shop:run(function()shop:request('viewCollection',{category='items:territory',keys={M.key}})end)
    local decided=false
    Pop.sheet('halloween','HalloweenGift20',w,h,function(p,close,pw)
        local stroke=p:FindFirstChildOfClass('UIStroke');if stroke then stroke.Color=gold;stroke.Transparency=.2 end
        local y=pad
        local t=K.text(p,'Title','할로윈 이벤트로 획득했어요!',20,C.ink,800);t.TextXAlignment=Enum.TextXAlignment.Center;K.box(t,pad,y,pw-pad*2,26);y+=26+12
        local glow=K.make('Frame',p,{Name='Glow',BackgroundColor3=gold,BackgroundTransparency=.9,BorderSizePixel=0});K.round(glow,10);K.box(glow,pad,y,pw-pad*2,artH)
        local view=require(script.Parent.CollectionPreview).create(p,item);K.box(view,pad,y,pw-pad*2,artH);y+=artH+12
        local grade=K.chip(p,'Grade','전설','rarity',{color=gold,size=13,height=22})
        grade.Position=UDim2.fromOffset(math.floor((pw-grade.Size.X.Offset)/2),y);y+=22+4
        local n=K.text(p,'Name',item.name,18,gold,800);n.TextXAlignment=Enum.TextXAlignment.Center;K.box(n,pad,y,pw-pad*2,24);y+=24+20
        local bw=math.floor((pw-pad*2-10)/2)
        local b=K.button(p,'Close',{kind='plain',text='닫기',size=fs},function()if decided then return end;decided=true;step('halloweenGift',{item=H.style,result='closed'});close()end)
        b:place(pad,y,bw,bh)
        local a=K.button(p,'Equip',{kind='pri',text='장착',size=fs},function(btn)
            if decided then return end;decided=true;K.confirm(btn,true);step('halloweenGift',{item=H.style,result='accepted'})
            close();shop:run(function()shop:request('equipSupply',H.itemId)end)
        end)
        a:place(pad+bw+10,y,pw-pad*2-bw-10,bh)
    end,function()if not decided then decided=true;step('halloweenGift',{item=H.style,result='cancelled'})end end)
end
return M
