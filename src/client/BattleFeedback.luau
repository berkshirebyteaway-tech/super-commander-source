local UI=require(script.Parent.Theme)
local Icons=require(script.Parent.UIIcons)
local Tween=game:GetService("TweenService")
local Tracker=require(script.Parent.Parent.Core.FeedbackTracker)
local M={};M.__index=M
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
    self.paused=state.paused or state.phase~="playing";self.incoming={};self.outgoing={};local total=0;local fresh=false;local active={}
    self.factions=factions;self.myTroops=state.player and state.player.troops or 0
    for _,op in ipairs(state.operations or {}) do
        if op.direction=="outgoing" and not op.retreated and not op.retreating and op.frontTile then table.insert(self.outgoing,op) end
        if op.direction=="incoming" and not op.retreated and not op.retreating then
            table.insert(self.incoming,op);total+=op.troops
            local key=(op.kind or "land")..op.id;active[key]=true
            if not self.seen[key] then
                local attacker=factions and factions[op.owner];local threat=Tracker.threat(op.troops,self.myTroops,attacker and attacker.kind)
                if threat~="minor" then fresh=fresh=="assault" and fresh or threat end
            end
        end
    end
    for _,u in ipairs(state.units or {}) do
        if u.owner~=1 and u.target==1 and (u.kind=="AtomBomb" or u.kind=="HydrogenBomb" or u.kind=="MIRV" or u.kind=="MIRVWarhead") then
            table.insert(self.incoming,{id=u.id,kind="nuclear",owner=u.owner,troops=0,frontTile=u.targetTile})
            local key="nuclear"..u.id;active[key]=true;if not self.seen[key] then fresh="assault" end
        end
    end
    self.seen=active
    table.sort(self.incoming,function(a,b) if (a.kind=="nuclear")~=(b.kind=="nuclear") then return a.kind=="nuclear" end;return a.troops>b.troops end)
    table.sort(self.outgoing,function(a,b)return a.troops>b.troops end)
    self.layer:SetAttribute("IncomingCount",#self.incoming)
    self.layer:SetAttribute("LastIncomingId",self.incoming[1] and self.incoming[1].id or 0)
    self.clockWarning=state.doomsday~=nil and factions[1]~=nil and factions[1].doomed==true
    if self.clockWarning and #self.incoming==0 then
        local p=factions[1];self.banner.Text=(p.rotted and "⚠ 영토가 붕괴하고 있어요" or "⚠ 소모전 경고").."  필요 영토 "..UI.number(state.doomsday.required)
    end
    if #self.incoming>0 then
        local attacker=factions[self.incoming[1].owner]
        self.banner.Text=#self.incoming>1 and string.format("%d개 전선에서 공격받는 중  %s  ›",#self.incoming,UI.troops(total))or string.format("%s 공격 중  %s  ›",attacker and attacker.name or "적",UI.troops(total))
        if self.incoming[1].kind=="nuclear" then self.banner.Text="☢ 로켓 접근 중, 눌러서 목표 확인  ›" end
    end
    self.fullWarning=self.banner.Text
    self.compactWarning=self.incoming[1]and self.incoming[1].kind=='nuclear'and '로켓 접근'or #self.incoming>0 and (UI.troops(total)..' ↓')or '소모전 경고'
    self.troopsIcon.Visible=#self.incoming>0 and self.incoming[1].kind~='nuclear'
    self.bannerPadding.PaddingLeft=UDim.new(0,self.troopsIcon.Visible and (require(script.Parent.InputMode).touch()and 30 or 24)or 6)
    if fresh and not self.effects.reduced and os.clock()-self.lastPulse>2.5 then
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
    self.banner.Visible=(#self.incoming>0 or self.clockWarning) and not obscured
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
function M:step()
    local size=self.layer.AbsoluteSize/UI.scale;local w,h=size.X,size.Y
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
                local size=op.kind=="nuclear" and 44 or op.kind=="transport" and 26 or 34;local half=size/2
                local point=self.renderer:project(op.frontTile,.2,true)
                local x=math.clamp(point.X-half,12,math.max(12,w-size-12))
                local y=math.clamp(point.Y-half,124,math.max(124,h-150))
                UI.box(marker,x,y,size,size);marker.TextSize=math.floor(size*.5)
                marker.Text=op.kind=="transport" and "⚓" or "!"
                UI.box(marker.Direction,half-10,-17,20,18)
                marker.Direction.Rotation=math.deg(math.atan2(point.Y-(y+half),point.X-(x+half)))-90
            end
        end
    end
    self:fronts(w,h)
end
function M:fronts(w,h)
    self.frontLabels:step(w,h,self.frontObscured,self.frontBlocks)
end
return M
