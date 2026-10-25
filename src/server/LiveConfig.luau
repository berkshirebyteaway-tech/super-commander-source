local Run=game:GetService('RunService')
local M={}
M.defaults={
    xpBoost=1,
    invites=true,
    groupPerk=true,
    badges=true,
    dailyOp=true,
    clans=true,
    ranked=true,
    rankedScreen=false,
    seasonScreen=false,
    sales=true,
    commsOpen=false,
    sale=true,
    saleEndsAt='',
    halloween=true,
    spectate=true,
    replays=true,
    bigMaps=true,
    notice='',
    noticeEn='',
    ticker='',
    tickerEn='',
    closeAt='',
    reopenAt='',
    maintenance=false,
    closeWarnMinutes=30,
    closeGateMinutes=10,
    softUpdate=true,
    updateMoveSeconds=45,
    seasonEnd='',
    telemetryDetail=.1,
    telemetryPerf=.1,
    telemetryRaw=true,
}
local snapshot
local missing={}
local function load()
    if Run:IsStudio()or game.GameId==0 then return end
    local ok,service=pcall(function()return game:GetService('ConfigService')end)
    if not ok or not service then return end
    local got,snap=pcall(function()return service:GetConfigAsync()end)
    if not got or not snap then return end
    snapshot=snap
    pcall(function()snap.UpdateAvailable:Connect(function()pcall(function()snap:Refresh()end);table.clear(missing);M.publish()end)end)
end
function M.get(key)
    local default=M.defaults[key]
    if snapshot and not missing[key]then
        local ok,value=pcall(function()return snapshot:GetValue(key)end)
        if not ok or value==nil then missing[key]=true end
        if ok and value~=nil and typeof(value)==typeof(default)then return value end
    end
    return default
end
function M.xpBoost()local v=M.get('xpBoost');return math.clamp(v==v and v or 1,1,3)end
function M.enabled(key)return M.get(key)~=false end
function M.salesOpen()
    local ok,Config=pcall(require,script.Parent.CommerceConfig)
    return ok and Config.purchasesEnabled==true and M.get('sales')==true and not Run:IsStudio()
end
function M.saleEndsAt(now)
    local Sale=require(game.ReplicatedStorage.FrontierNative.Core.LaunchSale)
    local ok,Config=pcall(require,script.Parent.CommerceConfig);if not ok then return nil end
    local any=Sale.saleId(Config.salePasses,'permanent')~=nil
    for kind in pairs(Config.saleProducts or {})do any=any or Sale.saleId(Config.saleProducts,kind)~=nil end
    local endsAt=Sale.endsAt(M.get('saleEndsAt'))
    if any and Sale.active(M.get('sale'),endsAt,now or os.time())then return endsAt end
    return nil
end
function M.publish()
    local pack=game.ReplicatedStorage:FindFirstChild('FrontierNative');if not pack then return end
    local function short(t)return utf8.len(t)and utf8.len(t)>80 and t:sub(1,utf8.offset(t,81)-1)or t end
    pack:SetAttribute('LiveNotice',short(M.get('notice')));pack:SetAttribute('LiveNoticeEn',short(M.get('noticeEn')))
    pack:SetAttribute('LiveXPBoost',M.xpBoost())
    pack:SetAttribute('LiveRankedScreen',M.get('rankedScreen')==true);pack:SetAttribute('LiveSeasonScreen',M.get('seasonScreen')==true)
    pack:SetAttribute('LaunchSaleEndsAt',M.salesOpen()and M.saleEndsAt()or 0)
    pack:SetAttribute('HalloweenEndsAt',require(pack.Core.HalloweenEvent).publishedEnd(M.get('halloween'),os.time()))
    pack:SetAttribute('VipCommsOpen',M.get('commsOpen')==true and not M.salesOpen()and not Run:IsStudio())
    require(pack.Core.SeasonRules).setEnd(M.get('seasonEnd'),os.time())
    require(pack.Core.BattlefieldRules).bigMaps=M.get('bigMaps')~=false
end
local started=false
function M.start()
    if started then return M end;started=true
    task.spawn(function()
        local ok,H=pcall(function()return require(game.ReplicatedStorage.FrontierNative.Core.HalloweenEvent)end);if not ok then return end
        for _,edge in ipairs({H.startsAt,H.endsAt})do local wait=edge-os.time();if wait>0 then task.wait(wait+1);M.publish()end end
    end)
    task.spawn(function()load();M.publish();while not snapshot and not(Run:IsStudio()or game.GameId==0)do task.wait(60);load();if snapshot then M.publish()end end end)
    return M
end
return M
