local UI=require(script.Parent.Theme)
local Icons=require(script.Parent.UIIcons)
local Tween=game:GetService("TweenService")
local Tracker=require(script.Parent.Parent.Core.FeedbackTracker)
local U=require(script.Parent.Parent.Core.UnitRules)
local M={};M.__index=M
local V2=require(script.Parent.Hud20).ENABLED
local K,X
function M.new(parent,renderer,effects)
    local layer=UI.make("Frame",parent,{Name="BattleFeedback",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=13})
    local self=setmetatable({layer=layer,renderer=renderer,effects=effects,seen={},markers={},incoming={},lastPulse=0,edges={}},M)
    for i=1,4 do
        local edge=UI.make("Frame",layer,{Name="WarningEdge"..i,BackgroundColor3=UI.colors.danger,BackgroundTransparency=1,BorderSizePixel=0})
        table.insert(self.edges,edge)
    end
    self.banner=UI.button(layer,"UnderAttack","",function()
        if self.incoming[1] and self.incoming[1].frontTile then renderer:focusAt(self.incoming[1].frontTile,true) end
    end)
    self.banner.BackgroundColor3=UI.colors.bg;self.banner.BackgroundTransparency=.1;self.banner.TextColor3=UI.colors.danger;self.banner.TextSize=14;self.banner.TextTruncate=Enum.TextTruncate.AtEnd;self.banner.Visible=false;local bs=self.banner:FindFirstChildOfClass("UIStroke")or UI.stroke(self.banner);bs.Color=UI.colors.danger
    self.troopsIcon=Icons.create(self.banner,'troops',20);UI.box(self.troopsIcon,-24,12,20,20);self.troopsIcon.ImageColor3=UI.colors.danger
    self.bannerPadding=UI.make('UIPadding',self.banner,{PaddingLeft=UDim.new(0,30),PaddingRight=UDim.new(0,6)})
    self.frontLabels=require(script.Parent.FrontlineTroops).new(layer,renderer)
    return self
end
function M:update(state,factions)
    self.frontLabels:update(state)
    if self.version~=state.version then self.version=state.version;self.seen={};self.incoming={} end
    self.paused=state.paused or state.phase~="playing";self.incoming={};self.outgoing={};local fresh=false;local active={}
    self.factions=factions;self.myTroops=state.player and state.player.troops or 0
    for _,op in ipairs(state.operations or {}) do
        if op.direction=="outgoing" and not op.retreated and not op.retreating and op.frontTile then table.insert(self.outgoing,op) end
        if op.direction=="incoming" and not op.retreated and not op.retreating then
            table.insert(self.incoming,op)
            local key=(op.kind or "land")..op.id;active[key]=true
            if not self.seen[key] then
                local attacker=factions and factions[op.owner];local threat=Tracker.threat(op.troops,self.myTroops,attacker and attacker.kind)
                if threat~="minor" then fresh=fresh=="assault" and fresh or threat
                    if V2 and op.frontTile then self:wedge20(op.frontTile)end end
            end
        end
    end
    for _,u in ipairs(state.units or {}) do
        if u.owner~=1 and u.target==1 and (u.kind=="AtomBomb" or u.kind=="HydrogenBomb" or u.kind=="MIRV" or u.kind=="MIRVWarhead") then
            table.insert(self.incoming,{id=u.id,kind="nuclear",weapon=u.kind,owner=u.owner,troops=0,frontTile=u.targetTile})
            local key="nuclear"..u.id;active[key]=true;if not self.seen[key] then fresh="assault" end
        end
    end
    self.seen=active
    table.sort(self.incoming,function(a,b) if (a.kind=="nuclear")~=(b.kind=="nuclear") then return a.kind=="nuclear" end;return a.troops>b.troops end)
    table.sort(self.outgoing,function(a,b)return a.troops>b.troops end)
    self.layer:SetAttribute("IncomingCount",#self.incoming)
    self.layer:SetAttribute("LastIncomingId",self.incoming[1] and self.incoming[1].id or 0)
    self.clockWarning=state.doomsday~=nil and factions[1]~=nil and factions[1].doomed==true
    if self.clockWarning and not(self.incoming[1] and self.incoming[1].kind=="nuclear")then
        local p=factions[1];self.banner.Text=(p.rotted and "⚠ 영토가 붕괴하고 있어요" or "⚠ 소모전 경고").."  필요 영토 "..UI.number(state.doomsday.required)
    end
    self.rocket=self.incoming[1]~=nil and self.incoming[1].kind=="nuclear"
    if self.rocket then self.banner.Text="☢ 로켓 접근 중, 눌러서 목표 확인  ›" end
    self.fullWarning=self.banner.Text
    self.compactWarning=self.rocket and '로켓 접근'or '소모전 경고'
    self.troopsIcon.Visible=false
    self.bannerPadding.PaddingLeft=UDim.new(0,self.troopsIcon.Visible and (require(script.Parent.InputMode).touch()and 30 or 24)or 6)
    if fresh and V2 and os.clock()-self.lastPulse>2.5 then
        self.lastPulse=os.clock();self.layer:SetAttribute("AlertCount",(self.layer:GetAttribute("AlertCount") or 0)+1)
    elseif fresh and not self.effects.reduced and os.clock()-self.lastPulse>2.5 then
        self.lastPulse=os.clock()
        for _,edge in ipairs(self.edges) do
            edge.BackgroundTransparency=fresh=="assault" and .15 or .4
            Tween:Create(edge,TweenInfo.new(fresh=="assault" and 1.2 or .8),{BackgroundTransparency=1}):Play()
        end
        self.layer:SetAttribute("AlertCount",(self.layer:GetAttribute("AlertCount") or 0)+1)
    end
end
function M:layout(w,h,obscured,compact,nuclear)
    self.obscured=obscured or compact
    self.frontObscured=obscured or nuclear
    if V2 then return self:layout20(w,h,obscured)end
    self.banner.Visible=(self.rocket or self.clockWarning) and not obscured
    self.banner.Text=compact and self.compactWarning or self.fullWarning or ''
    self.banner:SetAttribute('Compact',compact==true)
    local touch=require(script.Parent.InputMode).touch()
    local bh=touch and 40 or 32;local icon=self.troopsIcon.Visible and (touch and 30 or 24)or 6
    local fit=game:GetService('TextService'):GetTextSize(require(script.Parent.Localization).text(self.banner.Text),14,self.banner.Font,Vector2.new(1000,bh)).X+icon+18
    local bw=math.min(touch and 320 or (w<900 and 188 or 356),w-24,math.max(140,fit))
    UI.box(self.troopsIcon,touch and -24 or -20,touch and 10 or 8,touch and 20 or 16,touch and 20 or 16)
    UI.box(self.banner,(w-bw)/2,h<500 and 8 or 70,bw,bh)
    UI.box(self.edges[1],0,0,w,4);UI.box(self.edges[2],0,h-4,w,4)
    UI.box(self.edges[3],0,0,4,h);UI.box(self.edges[4],w-4,0,4,h)
end
function M:band20()
    if self.b20 then return self.b20 end
    K=K or require(script.Parent.Kit20);X=X or require(script.Parent.Cards20)
    local b=self.banner;local z=b.ZIndex
    b.TextTransparency=1;b.AutoButtonColor=false;self.bannerPadding.PaddingLeft=UDim.new(0,0);self.bannerPadding.PaddingRight=UDim.new(0,0)
    b.BackgroundColor3=X.DANGER_BG;b.BackgroundTransparency=.06
    local old=b:FindFirstChildOfClass('UIStroke');if old then old:Destroy()end
    local v={stroke=K.stroke(b,K.colors.danger,1,.3,true),icons={}}
    v.title=K.text(b,'Title20','',15,K.colors.danger,900);v.title.ZIndex=z+1
    v.num=K.num(b,'Count20','',13,K.colors.danger);v.num.ZIndex=z+1;v.num.TextTruncate=Enum.TextTruncate.None
    v.chev=K.icon(b,'chev',14,K.colors.muted,'More20');v.chev.ZIndex=z+1
    self.b20=v
    X.watch(function(what)if what=='card'and self.w20 then self:layout20(self.w20,self.h20,self.hidden20,true)end end)
    return v
end
function M:layout20(w,h,obscured,animate)
    local v=self:band20();local b=self.banner;self.w20,self.h20,self.hidden20=w,h,obscured
    local fmt=X.fmt(w,h);local pc=fmt=='pc'
    local show=(self.rocket or self.clockWarning)==true and not obscured
    local bw,bh=pc and 380 or 220,pc and 40 or 26
    local x,y=math.floor((w-bw)/2+.5),X.bandTop(b.Parent and b.Parent.Parent,fmt)
    local nukes=0;for _,op in ipairs(self.incoming)do if op.kind=='nuclear'then nukes+=1 end end
    local text=self.rocket and '로켓 접근'or '소모전 경고';b.Text=text
    K.round(b,pc and 10 or 7)
    local key=self.rocket and 'AtomBomb'or 'Target'
    for k,i in pairs(v.icons)do i.Visible=k==key end
    local icon=v.icons[key];if not icon then icon=X.orig(b,key,18,K.colors.danger,'Icon20');icon.ZIndex=b.ZIndex+1;v.icons[key]=icon end
    local is,pad,gap=pc and 18 or 13,pc and 12 or 8,pc and 10 or 6;icon.Visible=true;K.box(icon,pad,math.floor((bh-is)/2),is,is)
    v.title.Text=text;v.title.TextSize=pc and 15 or 12
    v.num.Text=self.rocket and nukes>1 and '×'..nukes or '';v.num.TextSize=pc and 13 or 11
    local cs=pc and 14 or 11;K.box(v.chev,bw-pad-cs,math.floor((bh-cs)/2),cs,cs);v.chev.Visible=self.rocket==true
    local tx=pad+is+gap;local tw=X.width(require(script.Parent.Localization).text(text),v.title.TextSize,v.title)
    K.box(v.title,tx,0,tw+2,bh);local nw=v.num.Text~=''and X.width(v.num.Text,v.num.TextSize,v.num)or 0;v.num.Visible=nw>0;K.box(v.num,tx+tw+gap,0,nw+2,bh)
    b.Size=UDim2.fromOffset(bw,bh)
    if not v.drop then
        v.drop=K.make('NumberValue',b,{Name='Drop20',Value=0});v.shake=0
        v.write=function()if v.home then b.Position=v.home+UDim2.fromOffset(v.shake,-math.floor(v.drop.Value+.5))end end
        v.drop.Changed:Connect(v.write)
    end
    local from=v.home;v.home=UDim2.fromOffset(x,y)
    local was=b.Visible;b.Visible=show
    if show and not was then
        K.fade(b,false,0);K.fade(b,true,K.reduced and .12 or .14)
        if K.reduced then v.drop.Value=0;v.write()
        else
            v.drop.Value=12;v.write();Tween:Create(v.drop,TweenInfo.new(.14,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),{Value=0}):Play()
            local token=(v.token or 0)+1;v.token=token
            task.spawn(function()task.wait(.06);for _,dx in ipairs({4,-4,0})do if v.token~=token then return end;v.shake=dx;v.write();task.wait(.04)end end)
        end
    elseif show and animate and from and from~=v.home and not K.reduced then
        v.drop.Value=0;local moveFrom=from;local moveTo=v.home;v.home=nil
        local t=Tween:Create(b,TweenInfo.new(.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=moveTo});b.Position=moveFrom;t:Play()
        t.Completed:Once(function()v.home=moveTo end)
    elseif show then v.write()end
    X.setRocket(show)
    if show then X.setBand(true,y+bh)elseif was then X.setBand(false)end
    UI.box(self.edges[1],0,0,w,4);UI.box(self.edges[2],0,h-4,w,4);UI.box(self.edges[3],0,0,4,h);UI.box(self.edges[4],w-4,0,4,h)
end
function M:wedge20(tile)
    self.wedges20=self.wedges20 or {}
    if #self.wedges20>=3 then table.remove(self.wedges20,1)end
    table.insert(self.wedges20,{tile=tile,at=os.clock()})
end
function M:stepWedges20(w,h)
    K=K or require(script.Parent.Kit20)
    local list=self.wedges20 or {};local now=os.clock()
    self.wedgePool=self.wedgePool or {}
    local used=0
    for i=#list,1,-1 do local e=list[i];if now-e.at>.75 then table.remove(list,i)end end
    for _,e in ipairs(list)do
        local p=self.renderer:project(e.tile,.2,true)
        local bounds=self.renderer.annotationBounds or {left=0,top=0,right=w,bottom=h}
        local l,t,r,bo=bounds.left+22,bounds.top+22,bounds.right-22,bounds.bottom-22
        local off=p.X<bounds.left or p.Y<bounds.top or p.X>bounds.right or p.Y>bounds.bottom
        if off and not self.obscured then
            used+=1;local g=self.wedgePool[used]
            if not g then
                g=K.make('Frame',self.layer,{Name='EdgeWedge'..used,AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(30,30),BackgroundColor3=Color3.fromRGB(40,12,14),BackgroundTransparency=.06,BorderSizePixel=0,ZIndex=16,Active=false})
                K.round(g,'pill');K.stroke(g,UI.colors.danger,1,.3,true)
                local a=K.icon(g,'up',18,UI.colors.danger,'Arrow');a.AnchorPoint=Vector2.new(.5,.5);a.Position=UDim2.fromScale(.5,.5);a.ZIndex=17
                self.wedgePool[used]=g
            end
            local cx,cy=(l+r)/2,(t+bo)/2;local dx,dy=p.X-cx,p.Y-cy
            local k=math.min(dx~=0 and math.abs((dx>0 and r-cx or cx-l)/dx)or math.huge,dy~=0 and math.abs((dy>0 and bo-cy or cy-t)/dy)or math.huge)
            g.Position=UDim2.fromOffset(math.floor(cx+dx*k+.5),math.floor(cy+dy*k+.5));g.Arrow.Rotation=math.deg(math.atan2(dy,dx))+90
            if not g.Visible or g:GetAttribute('At')~=e.at then g:SetAttribute('At',e.at);g.Visible=true;K.fade(g,false,0);K.fade(g,true,K.reduced and .12 or .08)
                task.delay(.6,function()if g:GetAttribute('At')==e.at then K.fade(g,false,.15)end end)end
        end
    end
    for i=used+1,#self.wedgePool do local g=self.wedgePool[i];if g.Visible then g.Visible=false;g:SetAttribute('At',nil)end end
    self.wedgeShown=used
end
function M:step()
    local size=self.layer.AbsoluteSize/UI.scale;local w,h=size.X,size.Y
    if V2 and(self.wedges20 and #self.wedges20>0 or(self.wedgeShown or 0)>0)then self:stepWedges20(w,h)end
    for i=1,math.max(#self.markers,math.min(4,#self.incoming)) do
        local op=self.incoming[i];local marker=self.markers[i]
        if op and not marker then
            marker=UI.button(self.layer,"Frontline"..i,"!",function()
                local current=self.incoming[i];if current and current.frontTile then self.renderer:focusAt(current.frontTile,true) end
            end)
            marker.BackgroundColor3=UI.colors.bg;marker.BackgroundTransparency=.15;marker.TextColor3=UI.colors.danger;marker.TextSize=22;local ms=marker:FindFirstChildOfClass("UIStroke")or UI.stroke(marker);ms.Color=UI.colors.danger;ms.Thickness=1.5
            local arrow=UI.label(marker,"Direction","▼",14,UI.colors.danger);UI.box(arrow,12,-17,20,18);arrow.TextXAlignment=Enum.TextXAlignment.Center
            self.markers[i]=marker
        end
        if marker then
            marker.Visible=op~=nil and op.kind~='land'and op.frontTile~=nil and not self.obscured
            if marker.Visible then
                local size=op.kind=="nuclear" and 30 or op.kind=="transport" and 26 or 34;local half=size/2
                local point=self.renderer:project(op.frontTile,.2,true)
                local cx,cy=point.X,point.Y
                if op.kind=="nuclear" then local r=self:ringPixels(op)+half+6;cy=cy-r-half<124 and cy+r or cy-r end
                local x=math.clamp(cx-half,12,math.max(12,w-size-12))
                local y=math.clamp(cy-half,124,math.max(124,h-150))
                UI.box(marker,x,y,size,size);marker.TextSize=math.floor(size*.5)
                marker.Text=op.kind=="transport" and "⚓" or "!"
                UI.box(marker.Direction,half-10,-17,20,18)
                marker.Direction.Rotation=math.deg(math.atan2(point.Y-(y+half),point.X-(x+half)))-90
            end
        end
    end
    self:fronts(w,h)
end
function M:ringPixels(op)
    local map=self.renderer.map;if not map then return 0 end
    local _,outer=U.magnitude(op.weapon or "AtomBomb");local mw=map.meta.width
    local tx,ty=op.frontTile%mw,math.floor(op.frontTile/mw)
    local c=self.renderer:projectXY(tx,ty,.2,true)
    local r=0
    for _,d in ipairs({{0,-outer},{outer,0},{0,outer},{-outer,0}})do
        local p=self.renderer:projectXY(tx+d[1],ty+d[2],.2,true);if p.X>-1999 then r=math.max(r,math.abs(p.Y-c.Y))end
    end
    return r
end
function M:fronts(w,h)
    self.frontLabels:step(w,h,self.frontObscured,self.frontBlocks)
end
return M
