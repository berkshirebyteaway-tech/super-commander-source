local Players=game:GetService('Players')
local K=require(script.Parent.Kit20)
local Theme=require(script.Parent.Theme)
local C=K.colors
local M={}
local state={}
local function gui()
    if state.gui and state.gui.Parent then return state.gui,state.root end
    local pg=Players.LocalPlayer:WaitForChild('PlayerGui')
    local g=K.make('ScreenGui',pg,{Name='Pop20',ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=41,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
    local root=K.make('Frame',g,{Name='Root',BackgroundTransparency=1,BorderSizePixel=0})
    local s=K.make('UIScale',root,{Name='Scale'})
    local function fit()local sc=Theme.scale or 1;s.Scale=sc;root.Size=UDim2.fromOffset(g.AbsoluteSize.X/sc,g.AbsoluteSize.Y/sc)end
    g:GetPropertyChangedSignal('AbsoluteSize'):Connect(fit);fit()
    pcall(function()require(script.Parent.Localization).bind(g)end)
    state.gui,state.root=g,root
    return g,root
end
M.gui=gui
local function logical(v)return v/(Theme.scale or 1)end
function M.close(now)
    local cur=state.cur;state.cur=nil;if not cur then return end
    if cur.catch then cur.catch:Destroy()end
    if cur.onClose then pcall(cur.onClose)end
    if cur.scrim then task.delay(K.reduced and 0 or .08,function()if not state.cur or not state.cur.scrim then K.scrimShow('Scrim20',false,nil,.10)end end)end
    local p=cur.panel
    if now==true or not p or not p.Parent then if p then p:Destroy()end;return end
    K.leave(p,{dy=cur.kind=='lock'and 6 or 0,t=cur.kind=='lock'and .08 or .10},function()p:Destroy()end)
    local s=p:FindFirstChild('Pop20');if s and not K.reduced then game:GetService('TweenService'):Create(s,TweenInfo.new(.10,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Scale=.96}):Play()end
end
function M.closeOwner(owner)if state.cur and state.cur.owner==owner then M.close()end end
function M.watch(hub,page)
    if not hub.pop20Watch then
        hub.pop20Watch=hub.overlay:GetPropertyChangedSignal('Visible'):Connect(function()if not hub.overlay.Visible then M.close(true);hub.anim20=nil end end)
        hub.pop20Size=hub.root:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
            local p=hub.page;if (p=='shop'or p=='clan'or p=='supply')and hub.overlay.Visible and not hub.pop20Redraw then
                hub.pop20Redraw=true;task.defer(function()hub.pop20Redraw=nil;if hub.page==p then M.close(true);hub:drawPage()end end)end
        end)
    end
    if state.cur and state.cur.owner~=page then M.close(true)end
    local first=hub.anim20~=page;hub.anim20=page;return first
end
function M.isOpen(name)return state.cur~=nil and(name==nil or state.cur.name==name)end
local function catcher(root)
    local b=K.make('TextButton',root,{Name='Catch',Text='',BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Size=UDim2.fromScale(1,1),ZIndex=1})
    b.Activated:Connect(function()M.close()end)
    return b
end
function M.sheet(owner,name,w,h,build,onClose)
    M.close(true)
    local _,root=gui()
    local RW,RH=root.Size.X.Offset,root.Size.Y.Offset
    h=K.even(h);local full=h;w=K.even(math.min(w,RW-24));h=K.even(math.min(h,RH-16))
    K.scrim('Scrim20',.45,40);K.scrimShow('Scrim20',true,.45,.12)
    local catch=catcher(root)
    local p=K.panel(root,name or 'Sheet20','card',12);p.Active=true
    K.boxCentre(p,math.floor((RW-w)/2),math.floor((RH-h)/2),w,h)
    state.cur={owner=owner,name=name,panel=p,catch=catch,scrim=true,kind='sheet',onClose=onClose}
    local host=p
    if full>h then
        host=K.make('ScrollingFrame',p,{Name='Scroll',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ScrollBarThickness=3,ScrollBarImageColor3=C.line,
            ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.fromOffset(0,full)})
    end
    build(host,function()M.close()end,w,full)
    K.appear(p,{scaleFrom=.96,t=.16})
    return p
end
function M.primeTickets()
    local Launch=require(script.Parent.Parent.Core.LaunchCommerce);local L=require(script.Parent.Localization)
    local w=Launch.permanent.welcome;local colors,split={},{}
    for _,r in ipairs(Launch.rarityOrder)do local n=w[r]or 0
        if n>0 then for _=1,n do table.insert(colors,K.rarity[r])end;table.insert(split,L.text(Launch.rarityNames[r])..' '..n)end
    end
    return #colors,colors,table.concat(split,', ')
end
function M.lock(owner,anchor,text,link,onLink,color,extra)
    M.close(true)
    local g,root=gui()
    local fs=14;local pad=12;local col=color or C.prime
    local lw=K.width(text,fs);local kw=link and K.width(link,fs)+4+14 or 0
    local w=pad+lw+(link and 12+kw or 0)+pad;local h=40
    local icons=extra and extra.icons or {}
    if extra then
        local ew=#icons*15+(#icons>0 and 4 or 0)
        if extra.text then ew+=K.width(extra.text,13,{FontFace=K.fonts[800]})+6 end
        if extra.sub then ew+=K.width(extra.sub,12,{FontFace=K.fonts[600]})end
        w=math.max(w,pad+ew+pad);h=58
    end
    w=K.even(math.ceil(w)+1)
    local catch=catcher(root)
    local p=K.make('Frame',root,{Name='Lock20',BackgroundColor3=C.raised,BorderSizePixel=0,ZIndex=2,Active=true});K.round(p,8);K.stroke(p,C.line,1,0,true)
    local pos=Vector2.new(logical(anchor.AbsolutePosition.X-g.AbsolutePosition.X),logical(anchor.AbsolutePosition.Y-g.AbsolutePosition.Y))
    local size=Vector2.new(logical(anchor.AbsoluteSize.X),logical(anchor.AbsoluteSize.Y))
    local RW=root.Size.X.Offset
    local x=math.clamp(pos.X+size.X/2-w/2,8,math.max(8,RW-w-8));local y=pos.Y-h-6
    if y<8 then y=pos.Y+size.Y+6 end
    K.boxCentre(p,x,y,w,h)
    local top=extra and 2 or 0;local lh=extra and 32 or h
    local t=K.text(p,'Text',text,fs,C.ink,700);K.box(t,pad,top,lw+2,lh);t.ZIndex=3
    if link then
        local b=K.button(p,'Link',{kind='none',text=link,size=fs,weight=800},function()M.close();if onLink then onLink()end end)
        b:place(pad+lw+12,top,kw,lh);b:layoutContent('left',0);b.label.TextColor3=col
        local chev=K.icon(b.face,'chev',14,col,'Chev');K.box(chev,kw-14,(lh-14)/2,14,14)
    end
    if extra then
        local ex,ey,eh=pad,top+lh,18
        for i,c in ipairs(icons)do local ic=K.icon(p,'ticket',13,c,'Ticket'..i);ic.ZIndex=3;K.box(ic,ex,ey+math.floor((eh-13)/2),13,13);ex+=15 end
        if #icons>0 then ex+=4 end
        if extra.text then local a=K.text(p,'ExtraText',extra.text,13,C.ink,800);a.ZIndex=3;local aw=K.width(extra.text,13,a);K.box(a,ex,ey,aw+2,eh);ex+=aw+6 end
        if extra.sub then local s=K.text(p,'ExtraSub',extra.sub,12,C.muted,600);s.ZIndex=3;s:SetAttribute('LocalizationSkip',true);K.box(s,ex,ey,K.width(extra.sub,12,s)+2,eh)end
    end
    state.cur={owner=owner,name='lock',panel=p,catch=catch,kind='lock'}
    K.appear(p,{dy=6,scaleFrom=.96,t=.12})
    return p
end
return M
