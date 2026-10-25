local K=require(script.Parent.Kit20)
local S=require(script.Parent.Sheet20)
local Rows=require(script.Parent.SettingsRows)
local Theme=require(script.Parent.Theme)
local C=K.colors
local M={}
M.SIZE={solo={760,560},maps={960,580}}
local known=setmetatable({},{__mode='k'})
function M.bind(lobby)if lobby and lobby.pageBody then known[lobby.pageBody]=lobby end end
function M.lobbyFor(body)return body and known[body]end
function M.enabled()return require(script.Parent.Lobby20).ENABLED==true end

local function lift(lobby)
    local d=lobby.deployment;local q=lobby.data and lobby.data.queue
    if q and d and d.bar and d.bar.Visible then return (d.barHeight or 48)+8 end
    return 0
end
local function rect(page,W,H,fmt,bottom)
    if fmt=='pt'then return 0,0,W,H end
    if fmt=='ph'then return 12,8,W-24,H-16-bottom end
    local s=M.SIZE[page]or M.SIZE.solo
    local sw,sh=math.min(s[1],W-48),math.min(s[2],H-58-16-bottom)
    local sy=math.floor((H-sh)/2+20);sy=math.max(66,math.min(sy,H-bottom-8-sh))
    return math.floor((W-sw)/2),sy,sw,sh
end

function M.open(lobby,body,page)
    M.bind(lobby)
    local sc=Theme.scale or 1
    local W,H=lobby.root.AbsoluteSize.X/sc,lobby.root.AbsoluteSize.Y/sc
    local fmt=S.format(W,H);local pt,ph=fmt=='pt',fmt=='ph'
    local bottom=lift(lobby)
    local overlay=lobby.overlay
    local win={lobby=lobby,page=page,fmt=fmt,W=W,H=H,connections={}}
    function win.connect(signal,fn)local c=signal:Connect(fn);table.insert(win.connections,c);return c end
    local prev=lobby.setup20Win;lobby.setup20Win=win
    if prev then if prev.save then pcall(prev.save)end;if prev.root then prev.root:Destroy()end end
    local root=K.make('Frame',overlay,{Name='Setup20',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=3});win.root=root
    lobby.pageCard.Visible=false
    root.Destroying:Once(function()
        for _,c in ipairs(win.connections)do c:Disconnect()end
        if lobby.setup20Win==win then lobby.setup20Win=nil;lobby.pageCard.Visible=true end
    end)
    local function gone(keepShown)
        if lobby.setup20Win~=win then return end
        if win.save then pcall(win.save)end
        if not keepShown then lobby.setup20Shown=nil;lobby.setup20Scroll=nil end
        root:Destroy()
    end
    local marker=K.make('Frame',body,{Name='Setup20Marker',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromOffset(0,0),Visible=false})
    marker.Destroying:Once(function()gone(lobby.page==page)end)
    win.connect(overlay:GetPropertyChangedSignal('Visible'),function()if not overlay.Visible then gone(false)end end)
    win.connect(lobby.root:GetPropertyChangedSignal('AbsoluteSize'),function()
        if lobby.setup20Redraw then return end;lobby.setup20Redraw=true
        task.defer(function()lobby.setup20Redraw=nil;if lobby.setup20Win==win and lobby.page==page then lobby:drawPage()end end)
    end)
    local x,y,sw,sh=rect(page,W,H,fmt,bottom);win.sw,win.sh,win.cardX,win.cardY=sw,sh,x,y
    if pt then
        K.make('Frame',root,{Name='Page',BackgroundColor3=S.PAGE,BackgroundTransparency=.05,BorderSizePixel=0,Size=UDim2.fromScale(1,1),Active=true})
    else
        local outside=K.make('TextButton',root,{Name='Outside',Text='',BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Size=UDim2.fromScale(1,1),ZIndex=1})
        outside.Activated:Connect(function()if lobby.setup20Win==win and win.card:GetAttribute('Moving20')~='in'then lobby:back()end end)
    end
    local card=K.make('Frame',root,{Name='Card',BackgroundColor3=S.BG,BackgroundTransparency=pt and 1 or 0,BorderSizePixel=0,Active=true,ZIndex=2});win.card=card
    K.box(card,x,y,sw,sh)
    if not pt then
        K.round(card,8);K.stroke(card,C.line,1,0,true)
        K.make('TextButton',card,{Name='Catch',Text='',BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Size=UDim2.fromScale(1,1),ZIndex=0})
    end
    local pad=pt and 16 or ph and 12 or 24;local inset=pt and 0 or 1
    win.pad=pad;win.x=pad+inset;win.w=pt and W-32 or sw-2*(pad+inset)
    if pt then local _,b=S.band(H,bottom);win.bottom=b else win.bottom=sh-inset-pad end
    win.first=lobby.setup20Shown~=page;lobby.setup20Shown=page
    if win.first then K.appear(card,{dx=pt and 0 or 24,dy=pt and 24 or 0,t=pt and .16 or .18,noFade=true})end
    return win
end

function M.head(win,title,onBack,onClose)
    local pt,ph=win.fmt=='pt',win.fmt=='ph'
    local card=win.card
    local y=pt and 66 or ph and 9 or 15;local rh=pt and 40 or ph and 30 or 40
    local ts=pt and 18 or ph and 16 or 18;local bs=pt and 40 or ph and 32 or 40;local is=pt and 18 or ph and 16 or 20
    local x0,right=win.x,win.x+win.w
    local lobby=win.lobby
    if not pt and win.cardY+y<(lobby.topbarHeight or 0)then x0=math.max(x0,(lobby.topbarLeft or 12)-win.cardX)end
    if onBack then
        local b=S.iconButton(card,'Back','back',bs,is,onBack);b:place(x0,y+(rh-bs)/2,bs,bs);x0+=bs+8
    end
    if onClose then
        local c=S.iconButton(card,'Close','x',bs,is,onClose);c:place(right-bs,y+(rh-bs)/2,bs,bs);right-=bs+(pt and 8 or 10)
    end
    local t=K.text(card,'Title',title,ts,C.ink,800);K.box(t,x0,y,math.max(20,right-x0),rh)
    win.top=y+rh+(pt and 8 or ph and 8 or 12)
    return t
end

function M.scroll(win,name,bottomY)
    local s=S.scroll(win.card,name,win.x,win.top,win.w,math.max(40,bottomY-win.top))
    local lobby,page=win.lobby,win.page
    win.save=function()lobby.setup20Scroll={page=page,pos=s.CanvasPosition}end
    return s
end
function M.restore(win,s)
    local keep=win.lobby.setup20Scroll
    if keep and keep.page==win.page then
        s.CanvasPosition=keep.pos
        task.defer(function()if s.Parent then s.CanvasPosition=keep.pos end end)
    end
end

function M.footer(win,onPrimary,onSecondary)
    local lobby=win.lobby;local pt,ph=win.fmt=='pt',win.fmt=='ph'
    local bh=pt and 52 or ph and 44 or 56;local fs=pt and 18 or ph and 16 or 20
    local by=win.bottom-bh
    local src,prev=lobby.soloStart,lobby.pageSecondary
    local go=K.button(win.card,'StartSolo',{kind='pri',text=src.Text,size=fs},function(b)K.confirm(b,true);onPrimary()end)
    local back=K.button(win.card,'Previous',{kind='plain',text=prev.Text,size=pt and 15 or ph and 14 or 16},function()onSecondary()end)
    local function sync()
        local two=prev.Visible;local bw=pt and 110 or ph and 110 or 132
        back.button.Visible=two;back:setText(prev.Text)
        if two then back:place(win.x,by,bw,bh);go:place(win.x+bw+8,by,win.w-bw-8,bh)else go:place(win.x,by,win.w,bh)end
        go:setText(src.Text)
        local on=src:GetAttribute('Enabled')~=false
        go:setKind(on and 'pri'or 'dis');go:setEnabled(on,true)
    end
    sync()
    win.connect(src:GetPropertyChangedSignal('Text'),sync)
    win.connect(src:GetAttributeChangedSignal('Enabled'),sync)
    win.connect(prev:GetPropertyChangedSignal('Visible'),sync)
    win.connect(prev:GetPropertyChangedSignal('Text'),sync)
    win.primary=go
    return by-(ph and 8 or 12)
end

function M.heading(parent,fmt,title,icon,y,w)
    if y>0 then y+=fmt=='pt'and 4 or 8 end
    return Rows.heading20(parent,fmt,0,y,w,title,icon or 'dot')
end
function M.stepper(parent,fmt,name,title,valueText,y,w,step)
    local pt,ph=fmt=='pt',fmt=='ph'
    local h=pt and 48 or ph and 44 or 52;local ctl=pt and 36 or ph and 34 or 40
    local f=K.make('Frame',parent,{Name=name..'Row',BackgroundColor3=C.panel,BackgroundTransparency=pt and 1 or 0,BorderSizePixel=0});K.box(f,0,y,w,h)
    if pt then local line=K.make('Frame',f,{Name='Line',BackgroundColor3=C.line,BackgroundTransparency=.4,BorderSizePixel=0});K.box(line,0,h-1,w,1)
    else K.round(f,8);K.stroke(f,C.line,1,0,true)end
    local pad=pt and 0 or ph and 10 or 16;local fs=pt and 14 or ph and 13 or 15
    local bw=pt and 36 or ph and 34 or 40;local vw=pt and 96 or ph and 92 or 120;local g=6
    local right=w-pad;local x=right-bw*2-vw-g*2;local cy=math.floor((h-ctl)/2)
    local l=K.text(f,'Label',title,fs,C.ink,700);K.box(l,pad,0,math.max(20,x-pad-8),h)
    local v=K.text(f,name,valueText,pt and 14 or ph and 13 or 15,C.ink,800,Enum.TextXAlignment.Center);K.box(v,x+bw+g,cy,vw,ctl)
    local function square(n,icon,d)
        local b=K.button(f,n,{kind='plain',icon=icon,iconSize=16},function()step(d)end)
        b.iconColorFixed=true;b.iconImage.ImageColor3=C.ink;return b
    end
    square('Prev','back',-1):place(x,cy,bw,ctl)
    square('Next','chev',1):place(right-bw,cy,bw,ctl)
    return y+h+(pt and 0 or ph and 6 or 8)
end
return M
