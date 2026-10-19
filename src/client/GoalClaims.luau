local UI=require(script.Parent.ToyUI)
local Rules=require(script.Parent.Parent.Core.OutgameRules)
local Currency=require(script.Parent.CurrencyChip)
local M={}
local function name(c)
    if c.source=='daily'then for _,m in ipairs(Rules.daily)do if m.id==c.id then return m.name end end;return '오늘의 목표'end
    if c.source=='weekly'then return '이번 주 목표'end
    if c.source=='achievement'then local id=tostring(c.id or ''):gsub('^a:','');for _,a in ipairs(Rules.achievementList)do if a.id==id then return a.name end end;return '업적'end
    return '보상'
end
M.name=name
function M.list(p)
    local out={};for key,c in pairs(type(p)=='table'and p.goalClaims or {})do table.insert(out,{key=key,source=c.source,id=c.id,xp=c.xp or 0,medals=c.medals or 0,name=name(c)})end
    table.sort(out,function(a,b)return a.key<b.key end);return out
end
function M.count(p)local n=0;for _ in pairs(type(p)=='table'and p.goalClaims or {})do n+=1 end;return n end
function M.pending(p,key)return type(p)=='table'and type(p.goalClaims)=='table'and p.goalClaims[key]~=nil end
function M.claim(hub,key)
    local shop=hub.callbacks.shop();if shop.busy then return end
    shop:run(function()
        local r=shop:request('claimGoal',key)
        if r and r.ok and r.claimed then
            pcall(function()require(script.Parent.ToyAudio).play('milestone')end)
            local parts={};if r.claimed.medals>0 then table.insert(parts,string.format('+%d 코인',r.claimed.medals))end;if r.claimed.xp>0 then table.insert(parts,string.format('+%d XP',r.claimed.xp))end
            if shop.notify then shop.notify(string.format('%s 받았어요',table.concat(parts,', ')),false)end
            require(script.Parent.TelemetryStep).step('lobby','goalClaim',{count=r.claimed.count,value=r.claimed.medals})
        end
        if hub.page=='missions'then hub:drawPage()end
    end)
end
function M.button(parent,name,label,fn)
    local b=UI.button(parent,name,label,fn,true);b.BackgroundColor3=UI.colors.gold;b.TextColor3=UI.colors.bg;return b
end
function M.dot(button,on)
    require(script.Parent.TelemetryStep).change('dot:'..button.Name,'goals','redDot',{item=require(script.Parent.TelemetryStep).code(button.Name),result=on and 'shown'or 'closed'})
    local d=button:FindFirstChild('ClaimDot')
    if not on then if d then d.Visible=false end;return end
    if not d then
        d=UI.make('Frame',button,{Name='ClaimDot',BackgroundColor3=Color3.fromRGB(255,82,82),BorderSizePixel=0,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-4,0,4),Size=UDim2.fromOffset(10,10),ZIndex=40})
        UI.corner(d,999);local s=Instance.new('UIStroke');s.Color=Color3.fromRGB(11,15,20);s.Thickness=2;s.Parent=d;d:SetAttribute('AllowOverlap',true)
    end
    d.Visible=true
end
function M.banner(hub,body,w,y)
    local p=hub.account.progress or {};local list=M.list(p);if #list==0 then return 0 end
    local xp,medals=0,0;for _,c in ipairs(list)do xp+=c.xp;medals+=c.medals end
    local card=UI.panel(body,'ClaimBanner');UI.box(card,0,y,w,76);card.BackgroundColor3=UI.colors.gold:Lerp(UI.colors.panel,.82)
    local stroke=card:FindFirstChildOfClass('UIStroke');if stroke then stroke.Color=UI.colors.gold end
    M.dot(card,true)
    local t=UI.label(card,'Title',string.format('받을 보상 %d개',#list),16,UI.colors.ink);UI.box(t,14,8,w-200,26);t.Font=Enum.Font.BuilderSansBold
    local cw=math.min(150,(w-200)/2)
    if medals>0 then Currency.create(card,'medal',medals,14,40,cw,26)end
    if xp>0 then Currency.create(card,'xp',xp,14+(medals>0 and cw+8 or 0),40,cw,26)end
    local b=M.button(card,'ClaimAll','모두 받기',function()M.claim(hub,'all')end);UI.box(b,w-150,16,136,44)
    UI.enabled(b,not hub.callbacks.shop().busy)
    return 86
end
return M
