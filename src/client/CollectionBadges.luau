local Rules=require(script.Parent.Parent.Core.CollectionInbox)
local UI=require(script.Parent.ToyUI)
local M={}
function M.place(button)
    local b=button:FindFirstChild('CollectionBadge');if not b then return end
    local status=b:GetAttribute('CollectionStatus');local dot=status=='action'
    local thumb=button:GetAttribute('ThumbTab')
    if thumb then local tw=button.Size.X.Offset
        b.AnchorPoint=Vector2.new(0,0);b.TextSize=9;b.Size=UDim2.fromOffset(dot and 7 or 24,dot and 7 or 13)
        b.Position=UDim2.new(0,math.floor(tw/2)+(dot and 9 or 4),0,-(button:FindFirstChildOfClass('UIPadding')and button:FindFirstChildOfClass('UIPadding').PaddingTop.Offset or 0)+(dot and 3 or 1))
    else b.AnchorPoint=Vector2.new(1,0);b.TextSize=13;b.Size=UDim2.fromOffset(dot and 7 or 38,dot and 7 or 18);b.Position=UDim2.new(1,-3,0,2)end
end
function M.badge(button,status)
    local b=button:FindFirstChild('CollectionBadge')
    if not b and not status then return end
    if not b then b=UI.label(button,'CollectionBadge','',13,UI.colors.bg);b.ZIndex=40;b.TextXAlignment=Enum.TextXAlignment.Center;b.Font=Enum.Font.BuilderSansBold;UI.corner(b,999)end
    if b:GetAttribute('CollectionStatus')==status then return end;b:SetAttribute('CollectionStatus',status)
    b.Visible=status~=nil
    if status then b.Text=status=='action'and ''or 'NEW';b.BackgroundTransparency=0;b.BackgroundColor3=status=='action'and UI.colors.danger or UI.colors.gold;M.place(button)end
end
local function snapshot(lobby)
    local account=lobby.account or {};local cached=lobby.collectionSnapshot
    if not cached or cached.account~=account or cached.seen~=account.collectionSeen then
        cached={account=account,seen=account.collectionSeen,inventory=Rules.inventory(account),status=Rules.status(account)}
        lobby.collectionSnapshot=cached;lobby.collectionScans=(lobby.collectionScans or 0)+1
    end
    return cached
end
function M.body(lobby)local b=lobby.collectionBody;return b and b.Parent and lobby.page=='wardrobe'and b or lobby.pageBody end
local function category(lobby)
    if lobby.page~='wardrobe'then return nil end
    local c=lobby.wardrobeTab or 'items';return c=='items'and 'items:'..(lobby.slot or 'commanderStandard')or c
end
function M.refresh(lobby)
    local cached=snapshot(lobby);local status=cached.status
    for _,key in ipairs({'wardrobe','shop'})do if lobby.navButtons[key]then M.badge(lobby.navButtons[key],status[key])end end
    if lobby.navButtons.missions then local G=require(script.Parent.GoalClaims);G.dot(lobby.navButtons.missions,G.count(lobby.account and lobby.account.progress)>0)end
    if lobby.page=='wardrobe'then for _,key in ipairs({'items','honors','motions'})do local b=lobby.pageBody:FindFirstChild('WardrobeTab_'..key);if b then M.badge(b,status[key])end end end
    local rows=lobby.collectionRows and lobby.collectionRows.Parent and lobby.collectionRows or lobby.pageBody
    if lobby.page=='wardrobe'then for _,b in ipairs(rows:GetChildren())do if b.Name:sub(1,5)=='Slot_'then local k=b.Name:sub(6);M.badge(b,status[(k=='honors'or k=='motions')and k or 'items:'..k])end end end
    local inventory=cached.inventory;local seen=lobby.account.collectionSeen or {}
    for _,b in ipairs(M.body(lobby):GetChildren())do local key=b:GetAttribute('CollectionKey');if key then M.badge(b,inventory[key]and not seen[key]and 'new'or nil)end end
end
function M.schedule(lobby)
    local current=category(lobby)
    if not current or not snapshot(lobby).status[current]then lobby.collectionDue=nil;return end
    lobby.collectionCategory=current;lobby.collectionDue=os.clock()+.5
    if lobby.collectionPending then return end
    lobby.collectionPending=true
    local function poll()
        if not lobby.frame.Parent or not lobby.frame.Visible or not lobby.collectionDue or category(lobby)~=lobby.collectionCategory then lobby.collectionPending=nil;return end
        local remaining=lobby.collectionDue-os.clock()
        if remaining>0 then task.delay(remaining,poll);return end
        local shop=lobby.callbacks.shop()
        if shop.busy then lobby.collectionDue=os.clock()+.25;task.delay(.25,poll);return end
        lobby.collectionPending=nil
        local keys={};local body=M.body(lobby);local top=body.AbsolutePosition.Y;local bottom=top+body.AbsoluteSize.Y
        local inventory=snapshot(lobby).inventory;local seen=lobby.account.collectionSeen or {};local wanted=lobby.collectionCategory
        for _,b in ipairs(body:GetChildren())do
            local id=b:GetAttribute('CollectionKey')
            if id and inventory[id]==wanted and not seen[id]and b.Visible and b.AbsolutePosition.Y>=top-2 and b.AbsolutePosition.Y+b.AbsoluteSize.Y<=bottom+2 then table.insert(keys,id);if #keys>=64 then break end end
        end
        if #keys>0 then
            local mine=table.clone(seen);for _,id in ipairs(keys)do mine[id]=true end;lobby.account.collectionSeen=mine;M.refresh(lobby)
            shop:run(function()shop:request('viewCollection',{category=wanted,keys=keys})end)
        end
    end
    task.delay(.5,poll)
end
function M.view(lobby)
    M.refresh(lobby)
    if not lobby.collectionScroll then lobby.collectionScroll=lobby.pageBody:GetPropertyChangedSignal('CanvasPosition'):Connect(function()M.schedule(lobby)end)end
    M.schedule(lobby)
end
return M
