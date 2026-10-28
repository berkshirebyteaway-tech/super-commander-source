local K=require(script.Parent.Kit20)
local L=require(script.Parent.Localization)
local C=K.colors
local M={}
local function touch()return require(script.Parent.InputMode).touch()end
local function inset()local v=0;pcall(function()v=game:GetService('GuiService'):GetGuiInset().Y/(require(script.Parent.Theme).scale or 1)end);return v end
function M.format(w,h)
    local t=touch()
    if not t or require(script.Parent.Parent.Core.InterfacePlacement).tablet(w,h,t)then return 'pc'end
    return h>w and 'pt'or 'ph'
end
local function motion(f)
    if f:GetAttribute('Motion20')then return end;f:SetAttribute('Motion20',true)
    f:GetPropertyChangedSignal('Visible'):Connect(function()
        if f.Visible then
            if f:GetAttribute('Moving20')~='in'then f:SetAttribute('Shown20',false);K.appear(f,{dy=8,t=.14})end
        elseif not K.reduced and f.Parent then
            local g=f:Clone();g.Name=f.Name..'Ghost';g.Parent=f.Parent;g.Visible=true;g.Active=false;g:SetAttribute('Moving20',nil);g:SetAttribute('Home20',f:GetAttribute('Home20')or f.Position)
            for _,o in ipairs(g:GetDescendants())do if o:IsA('GuiButton')then o.Active=false end end
            K.leave(g,{dy=8,t=.10},function()g:Destroy()end)
        end
    end)
end
local function parts(f)
    local v=f:FindFirstChild('Card20Parts')
    if v then return v end
    for _,s in ipairs(f:GetChildren())do if s:IsA('UIStroke')and s.Name~='Stroke20'then s.Enabled=false end end
    f.BackgroundColor3=Color3.fromRGB(12,17,24);f.BackgroundTransparency=.06;K.round(f,12);K.stroke(f,C.line,1,.1,true)
    v=K.make('Folder',f,{Name='Card20Parts'})
    local n=K.num(f,'Seconds20','',34,C.accent);n.ZIndex=f.ZIndex+2
    local t=K.text(f,'Title20','',16,C.ink,800);t.ZIndex=f.ZIndex+2
    local s=K.text(f,'Hint20','',12,C.muted,700);s.ZIndex=f.ZIndex+2
    local tag=K.text(f,'Team20','',13,C.ink,800);tag.ZIndex=f.ZIndex+2
    motion(f)
    return v
end
function M.card(f,info,w,h,v1)
    parts(f)
    for _,o in ipairs(v1 or {})do o.Visible=false end
    local fmt=M.format(w,h);local pc=fmt=='pc'
    local n,t,s,tag=f.Seconds20,f.Title20,f.Hint20,f.Team20
    local ns0=pc and 34 or 28
    local lead=15+(info.seconds and K.width('88',ns0,n)+14 or 0)
    local tw0=K.width(L.text(info.title or ''),16,t)+(info.team and K.width(L.text(info.team),13,tag)+12 or 0)
    local hw0=info.hint and info.hint~=''and K.width(L.text(info.hint),12,s)or 0
    local cw=math.clamp(math.ceil(lead+math.max(tw0,hw0)+18),180,pc and 320 or fmt=='ph'and 280 or w-24);local ch=57
    local y=(pc and 24 or fmt=='ph'and 52 or 110)-inset()
    local pos=UDim2.fromOffset(math.floor((w-cw)/2),math.floor(y))
    f.Size=UDim2.fromOffset(cw,ch);f:SetAttribute('Home20',pos);if f:GetAttribute('Moving20')==nil then f.Position=pos end
    local ns=ns0;n.TextSize=ns
    local x=15
    if info.seconds then
        n.Visible=true
        local was=tonumber(n:GetAttribute('Value'))
        if was~=info.seconds then
            n:SetAttribute('Value',info.seconds)
            K.roll(n,was,info.seconds,function(v)return tostring(math.floor(v+.5))end,nil,.2)
            if was and info.seconds<was and info.seconds<=3 and info.seconds>0 then require(script.Parent.ToyAudio).play('countdown',1,1.3)end
        end
        local nw=K.width(tostring(info.seconds),ns,n);K.box(n,x,math.floor((ch-ns)/2),nw+2,ns);x+=nw+12
    else n.Visible=false;n:SetAttribute('Value',nil)end
    t.Text=info.title or '';s.Text=info.hint or '';s.Visible=s.Text~=''
    local tw=K.width(L.text(t.Text),16,t)
    if s.Visible then K.box(t,x,11,math.min(tw+4,cw-x-12),19);K.box(s,x,32,cw-x-12,14)
    else K.box(t,x,0,math.min(tw+4,cw-x-12),ch)end
    local room=cw-12-(x+tw+12)
    tag.Visible=info.team~=nil and room>=48
    if tag.Visible then tag.Text=info.team;tag.TextColor3=info.teamColor or C.ink;K.box(tag,x+tw+12,s.Visible and 11 or 0,room,s.Visible and 19 or ch)end
    return fmt
end
function M.button(host,view,visible,enabled,w,h)
    local b=view.land20
    if not b then
        b=K.button(host,'Land20',{kind='pri',text='지금 내리기',size=18,weight=800},function()view:landNow('button')end)
        b.button.ZIndex=21;view.land20=b
    end
    b.button.Visible=visible
    if not visible then return end
    local fmt=M.format(w,h);local bw=fmt=='pc'and 220 or 200
    b:place(math.floor((w-bw)/2),h-(fmt=='pc'and 28 or fmt=='pt'and 24 or 14)-52,bw,52);require(script.Parent.MatchSheet).fill20(b)
    b:setEnabled(enabled)
end
return M
