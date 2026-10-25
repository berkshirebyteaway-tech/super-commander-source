local Players=game:GetService("Players")
local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.OutgameIcons)
local Career=require(script.Parent.Parent.Core.CareerRules)
local Loadout=require(script.Parent.Parent.Core.MotionLoadout)
local VipLock=require(script.Parent.VipLock)
local LockChip=require(script.Parent.LockChip)
local M={}
M.icons={wave='wave',point='point',cheer='cheer',laugh='laugh',dance1='dance',dance2='march',dance3='marshal'}
local current,running,ended
function M.stop()
    if running then running:Disconnect();running=nil end
    if ended then ended:Disconnect();ended=nil end
    local old=current;current=nil
    if old then pcall(function()old:Stop(.15)end);task.delay(.2,function()old:Destroy()end)end
end
Players.LocalPlayer.CharacterRemoving:Connect(M.stop)
function M.play(motion)
    local c=Players.LocalPlayer.Character;local hum=c and c:FindFirstChildOfClass('Humanoid')
    local animator=hum and hum:FindFirstChildOfClass('Animator');if not animator then require(script.Parent.TelemetryStep).step('character','motionPlay',{item=require(script.Parent.TelemetryStep).code(motion.id),result='failed',reason='not_loaded'});return false end
    local anim=Instance.new('Animation');anim.AnimationId='rbxassetid://'..motion.anim
    local ok,track=pcall(function()return animator:LoadAnimation(anim)end)
    anim:Destroy()
    if not ok or not track then require(script.Parent.TelemetryStep).step('character','motionPlay',{item=require(script.Parent.TelemetryStep).code(motion.id),result='failed',reason='failed'});return false end
    require(script.Parent.TelemetryStep).step('character','motionPlay',{item=require(script.Parent.TelemetryStep).code(motion.id),result='ok'})
    M.stop()
    track.Priority=Enum.AnimationPriority.Action;track:Play(.2);current=track
    running=hum.Running:Connect(function(speed)if speed>1 and current==track then M.stop()end end)
    ended=track.Stopped:Once(function()if current==track then M.stop()end end)
    return true
end
function M.draw(lobby,body,w,startY)
    lobby.pageTitle.Text=startY and '스킨'or '모션'
    local p=lobby.account and lobby.account.progress or {};local level=p.level or 1;local y=startY or 0
    local list=Loadout.copy((lobby.account.preferences or {}).motionLoadout,level);local shop=lobby.callbacks.shop()
    local club=VipLock.allows('motion')
    if club then local hint=UI.label(body,'Hint','장착 6  M 키',12,UI.colors.muted);UI.box(hint,4,y,w-8,20);y+=28 end
    local short=lobby.root.AbsoluteSize.Y/require(script.Parent.Theme).scale<500
    local cols=w>=300 and 3 or 2;local gap=8;local tw=math.floor((w-6-gap*(cols-1))/cols);local th=short and 112 or math.clamp(math.floor(tw*.85),136,144)
    local is,iy=short and 24 or 36,short and 8 or 14
    for i,m in ipairs(Career.motions)do
        local open=level>=m.level;local col,row=(i-1)%cols,(i-1)//cols;local playable=open and club
        local b=UI.button(body,'Motion_'..m.id,'',function()if open and not club then VipLock.open('motion',true)elseif open then M.play(m)end end,false)
        UI.box(b,2+col*(tw+gap),y+row*(th+gap),tw,th);UI.enabled(b,open)
        if open then b:SetAttribute('CollectionKey','motion:'..m.id)end
        b.BackgroundColor3=playable and UI.colors.raised or UI.colors.panel
        local edge=b:FindFirstChildOfClass('UIStroke');if edge then edge.Transparency=playable and 0 or .45 end
        local icon=Icons.create(b,M.icons[m.id]or 'reward',is,playable and UI.colors.accent or UI.colors.muted)
        UI.box(icon,math.floor((tw-is)/2),iy,is,is);if not playable and Icons.available(icon)then icon.ImageTransparency=.45 end
        local name=UI.label(b,'Name',m.name,14,playable and UI.colors.ink or UI.colors.muted)
        name.TextXAlignment=Enum.TextXAlignment.Center;name.TextWrapped=false;name.TextTruncate=Enum.TextTruncate.AtEnd;UI.box(name,6,iy+is+(playable and 10 or 4),tw-12,18)
        if playable then
            local selected=table.find(list,m.id)
            local equip=UI.button(body,'EquipMotion_'..m.id,selected and '해제'or '장착',function()
                local nextList=table.clone(list);if selected then table.remove(nextList,selected)elseif #nextList<Loadout.limit then table.insert(nextList,m.id)else require(script.Parent.TelemetryStep).step('cosmetics','motionEquip',{item=require(script.Parent.TelemetryStep).code(m.id),result='rejected',reason='capacity'});return end
                require(script.Parent.TelemetryStep).step('cosmetics','motionEquip',{item=require(script.Parent.TelemetryStep).code(m.id),result=selected and 'closed'or 'selected',count=#nextList})
                shop:run(function()shop:request('preference','motionLoadout',nextList)end)
            end,selected~=nil)
            UI.box(equip,2+col*(tw+gap)+4,y+row*(th+gap)+th-46,tw-8,44);UI.enabled(equip,not shop.busy and (selected~=nil or #list<Loadout.limit))
        end
        if not playable then
            local text,color;if open then text,color=LockChip.vip()else text,color=LockChip.level(m.level)end
            LockChip.create(b,text,color,math.floor((tw-LockChip.width(text))/2),th-28)
        end
    end
    y+=math.ceil(#Career.motions/cols)*(th+gap)
    body.CanvasSize=UDim2.fromOffset(0,y+4)
end
return M
