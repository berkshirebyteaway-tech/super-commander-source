local UI=require(script.Parent.ToyUI)
local Rules=require(script.Parent.Parent.Core.OutgameRules)
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
local function target(hub)
    local c=hub.profile and hub.profile:FindFirstChild('Coins20')
    if c and c.Visible and hub.profile.Visible then return c,c:FindFirstChild('Icon')end
    local m=hub.medals;if m and m.Visible then return m,nil end
end
local function fly(hub,from,medals)
    local K=require(script.Parent.Kit20);if K.reduced then return end
    local chip,icon=target(hub);local gui=chip and chip:FindFirstAncestorOfClass('ScreenGui');if not(from and gui)then return end
    local Tween=game:GetService('TweenService');local o=gui.AbsolutePosition
    local land=icon or chip;local a,b=from-o,land.AbsolutePosition+land.AbsoluteSize/2-o
    local size=24;local endScale=icon and math.max(.4,icon.AbsoluteSize.X/size)or .6
    local n=math.clamp(math.ceil(medals/25),1,6)
    for i=1,n do
        task.delay((i-1)*.04,function()
            local f=K.icon(gui,'coinGold',size,Color3.new(1,1,1),'ClaimFly');f.ZIndex=60;f.AnchorPoint=Vector2.new(.5,.5)
            f.Size=UDim2.fromOffset(size,size);f.Position=UDim2.fromOffset(a.X,a.Y)
            local s=K.make('UIScale',f,{Name='Fly'})
            local info=TweenInfo.new(.35,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut)
            Tween:Create(f,info,{Position=UDim2.fromOffset(b.X,b.Y)}):Play();Tween:Create(s,info,{Scale=endScale}):Play()
            task.delay(.35,function()f:Destroy();if i==n and chip.Parent then K.punch(chip,1.12,.14)end end)
        end)
    end
end
function M.claim(hub,key,button)
    local shop=hub.callbacks.shop();if shop.busy then return end
    local from=button and button.AbsolutePosition+button.AbsoluteSize/2
    shop:run(function()
        local r=shop:request('claimGoal',key)
        if r and r.ok and r.claimed then
            pcall(function()require(script.Parent.ToyAudio).play('milestone')end)
            if r.claimed.medals>0 then pcall(fly,hub,from,r.claimed.medals)end
            require(script.Parent.TelemetryStep).step('lobby','goalClaim',{count=r.claimed.count,value=r.claimed.medals})
        end
    end)
end
function M.button(parent,name,label,fn)
    local b=UI.button(parent,name,label,fn,true);b.BackgroundColor3=UI.colors.gold;b.TextColor3=UI.colors.bg;return b
end
function M.button20(parent,name,label,size,fn)
    local K=require(script.Parent.Kit20)
    local b=K.button(parent,name,{kind='none',text=label,size=size or 16},fn)
    b.face.BackgroundColor3=K.colors.gold;b.face.BackgroundTransparency=0;b.baseFill=K.colors.gold;b.baseAlpha=0
    b.ink=K.colors.bg;if b.label then b.label.TextColor3=K.colors.bg end
    return b
end
function M.dot(button,on)
    require(script.Parent.TelemetryStep).change('dot:'..button.Name,'goals','redDot',{item=require(script.Parent.TelemetryStep).code(button.Name),result=on and 'shown'or 'closed'})
    require(script.Parent.RedDot).set(button,'ClaimDot',on)
end
return M
