local TextService=game:GetService("TextService")
local UI=require(script.Parent.Theme)
local FactionColors=require(script.Parent.FactionColors)
local Glyph=require(script.Parent.StructureGlyph)
local Catalog=require(script.Parent.BuildingCatalog)
local Honor=require(script.Parent.CommanderHonor)
local L=require(script.Parent.Localization)
local Glyphs=require(script.Parent.ActionGlyphs)
local Teams=require(script.Parent.TeamStandings)
local C=UI.colors
local M={};M.__index=M
M.ships={TransportShip=true,Warship=true,TradeShip=true}
local WIDTH=440
local catalog={};for _,b in ipairs(Catalog)do catalog[b.kind]=b end
local order={"City","Port","Factory","DefensePost","MissileSilo","SAMLauncher"}
local mobile={TransportShip="수송선",Warship="군함",TradeShip="무역선",Train="화물열차",AtomBomb="원자폭탄",HydrogenBomb="수소폭탄",MIRV="다탄두",MIRVWarhead="다탄두"}
local kinds={HUMAN="플레이어",NATION="AI 국가",BOT="봇"}
local violet=Color3.fromRGB(192,132,252)
local Right,Left=Enum.TextXAlignment.Right,Enum.TextXAlignment.Left
local function relation(f)
    if f.id==1 then return "나",C.accent end
    if f.teammate then return "팀",violet end
    if f.allied then return "동맹",C.good end
    if f.traitor then return "배신자",C.danger,true end
    return "적",C.danger
end
local function attitude(v)
    if v< -50 then return "적대",C.danger elseif v<0 then return "불신",C.gold elseif v<50 then return "중립",C.muted end
    return "우호",C.good
end
local function clock(ticks)local s=math.max(0,math.ceil(ticks/10));return string.format("%d:%02d",math.floor(s/60),s%60)end
local function share(v)v=(v or 0)*100;return string.format(v>=10 and "%.1f%%" or "%.2f%%",v)end
local function hex(c)return string.format("#%02X%02X%02X",math.floor(c.R*255+.5),math.floor(c.G*255+.5),math.floor(c.B*255+.5))end
function M.new(parent)
    local self=setmetatable({counts={},countsFor=nil},M)
    local f=UI.make("Frame",parent,{Name="Hover",BackgroundColor3=C.panel,BackgroundTransparency=.04,BorderSizePixel=0,Visible=false,ZIndex=16,Size=UDim2.fromOffset(WIDTH,100)})
    UI.corner(f,3);UI.stroke(f,C.line,1);self.frame=f
    self.edge=require(script.Parent.EdgeMask).fit(UI.make("Frame",f,{Name="RelationEdge",BorderSizePixel=0,BackgroundColor3=C.danger,Position=UDim2.fromOffset(0,0),Size=UDim2.new(0,3,1,0),ZIndex=17}))
    local function text(name,size,color,font,parent2)
        return UI.make("TextLabel",parent2 or f,{Name=name,Text="",TextSize=size,TextColor3=color,Font=font or Enum.Font.BuilderSansMedium,BackgroundTransparency=1,BorderSizePixel=0,TextXAlignment=Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=17})
    end
    self.unitIcon=UI.make("Frame",f,{Name="UnitIcon",BorderSizePixel=0,ZIndex=17});UI.corner(self.unitIcon,3)
    self.unitGlyph=UI.make("Frame",self.unitIcon,{Name="Glyph",BackgroundTransparency=1,Position=UDim2.fromOffset(4,4),Size=UDim2.new(1,-8,1,-8),ZIndex=18})
    self.unitName=text("UnitName",14,C.ink,Enum.Font.BuilderSansBold)
    self.unitRole=text("UnitRole",12,C.muted)
    self.unitState=text("UnitState",12,C.accent,Enum.Font.BuilderSansBold);self.unitState.TextXAlignment=Right
    self.unitRule=UI.make("Frame",f,{Name="UnitRule",BackgroundColor3=C.line,BorderSizePixel=0,ZIndex=17})
    self.swatch=UI.make("Frame",f,{Name="Swatch",BorderSizePixel=0,ZIndex=17});UI.corner(self.swatch,2)
    self.name=text("Name",15,C.ink,Enum.Font.BuilderSansBold)
    self.pill=UI.make("TextLabel",f,{Name="Relation",AnchorPoint=Vector2.new(1,0),AutomaticSize=Enum.AutomaticSize.X,Text="",TextSize=12,Font=Enum.Font.BuilderSansBold,TextColor3=C.danger,BackgroundColor3=C.danger,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=17})
    UI.corner(self.pill,3);self.pillStroke=UI.stroke(self.pill,C.danger,1);UI.make("UIPadding",self.pill,{PaddingLeft=UDim.new(0,7),PaddingRight=UDim.new(0,7)})
    self.sub=text("Kind",12,C.muted)
    self.teamDot=UI.make("Frame",f,{Name="TeamDot",BorderSizePixel=0,ZIndex=17,Visible=false,Size=UDim2.fromOffset(8,8)});UI.corner(self.teamDot,4)
    self.team=text("Team",12,C.ink,Enum.Font.BuilderSansBold);self.team.Visible=false
    self.capacity=UI.make('Frame',f,{Name='TroopCapacity',BackgroundColor3=C.raised,BorderSizePixel=0,ZIndex=16,ClipsDescendants=true});UI.corner(self.capacity,3)
    self.capacityFill=UI.make('Frame',self.capacity,{Name='Fill',BackgroundColor3=C.accent,BackgroundTransparency=.62,BorderSizePixel=0,Size=UDim2.fromScale(0,1),ZIndex=16});UI.corner(self.capacityFill,3)
    self.troops=text("Troops",13,C.ink,Enum.Font.BuilderSansBold);self.troops.TextXAlignment=Enum.TextXAlignment.Center;self.troops.ZIndex=18
    self.troopMark=Glyphs.create(f,"troops",14,C.ink);if self.troopMark then self.troopMark.ZIndex=18;self.troopMark.ImageTransparency=.15 end
    self.goldMark=Glyphs.create(f,"gold",15,C.gold)
    self.rows={}
    self.troops.TextTruncate=Enum.TextTruncate.None
    for i=1,2 do local k=text("Key"..i,12,C.muted);local v=text("Value"..i,13,C.ink,Enum.Font.BuilderSansBold);v.TextXAlignment=Left;v.TextTruncate=Enum.TextTruncate.None;self.rows[i]={key=k,value=v}end
    self.timers=text("Timers",12,C.ink,Enum.Font.BuilderSansBold);self.timers.RichText=true
    self.icons={}
    for _,kind in ipairs(order)do
        local g=UI.make("Frame",f,{Name="Count_"..kind,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=17,Size=UDim2.fromOffset(30,18)})
        local mark=UI.make("Frame",g,{Name="Glyph",BackgroundTransparency=1,Size=UDim2.fromOffset(13,13),Position=UDim2.fromOffset(0,2),ZIndex=18});Glyph.draw(mark,kind,C.muted)
        local n=text("Count",12,C.ink,Enum.Font.BuilderSansBold,g);n.Position=UDim2.fromOffset(15,0);n.Size=UDim2.fromOffset(15,18)
        self.icons[kind]={frame=g,count=n}
    end
    self.rule=UI.make("Frame",f,{Name="Rule",BackgroundColor3=C.line,BorderSizePixel=0,ZIndex=17})
    self.dot=UI.make("Frame",f,{Name="StatusDot",BorderSizePixel=0,ZIndex=17});UI.corner(self.dot,2)
    self.status=text("Status",12,C.ink)
    self.shipEdge=UI.make("Frame",f,{Name="ShipSwatch",BorderSizePixel=0,ZIndex=17,Visible=false});UI.corner(self.shipEdge,2)
    self.shipText=text("ShipText",13,C.ink,Enum.Font.BuilderSansBold);self.shipText.Visible=false
    self.shipMark=Glyphs.create(f,"troops",14,C.ink);if self.shipMark then self.shipMark.Name="ShipMark";self.shipMark.Visible=false end
    return self
end
function M:structures(s,id)
    if self.countsState~=s then self.countsState=s;self.counts={}
        for _,u in ipairs(s.units or {})do if catalog[u.kind]and not u.building and u.active~=false then
            local t=self.counts[u.owner]or {};self.counts[u.owner]=t;t[u.kind]=(t[u.kind]or 0)+1
        end end
    end
    return self.counts[id]
end
local function width(label,value)
    return TextService:GetTextSize(L.text(value),label.TextSize,label.Font,Vector2.new(400,40)).X+2
end
function M:show(ctx)
    local s,f,info,u=ctx.state,ctx.faction,ctx.info,ctx.unit
    local frame=self.frame;self.ownColor=ctx.ownColor
    self.shipEdge.Visible=false;self.shipText.Visible=false;if self.shipMark then self.shipMark.Visible=false end
    self.edge.Visible=true;self.swatch.Visible=true;self.name.Visible=true;self.troops.TextXAlignment=Enum.TextXAlignment.Center
    if not s or f and f.id==1 and not u or not f and not u and not(info and info.land and s.phase=="playing")then frame.Visible=false;return false end
    local compact=ctx.compact==true;local w=math.min(ctx.width or WIDTH,WIDTH);local x0=12;local y=compact and 8 or 6
    local showUnit=u~=nil and not compact
    for _,o in ipairs({self.unitIcon,self.unitName,self.unitRole,self.unitState,self.unitRule})do o.Visible=showUnit end
    if showUnit then
        local b=catalog[u.kind]
        self.unitIcon.BackgroundColor3=FactionColors.get(u.owner or 0,f and f.kind,ctx.ownColor)
        if self.unitKind~=u.kind then self.unitKind=u.kind;if b then Glyph.draw(self.unitGlyph,u.kind,C.bg)else self.unitGlyph:ClearAllChildren()end end
        self.unitName.Text=b and b.name or mobile[u.kind]or u.kind
        self.unitRole.Text=u.kind=="City"and not u.building and L.text("병력 상한 +")..UI.troops((u.level or 1)*250000)or b and b.role or (u.troops and u.troops>0 and string.format("병력 %s",UI.troops(u.troops)))or ""
        self.unitState.Text=u.building and "건설 중" or u.kind=="MissileSilo" and string.format("준비 %d/%d",u.readyMissiles or 0,u.level or 1)or b and "Lv."..(u.level or 1)or ""
        self.unitState.TextColor3=u.building and C.gold or C.accent
        local nw=width(self.unitName,self.unitName.Text);self.unitNeed=x0+30+nw+6+width(self.unitRole,self.unitRole.Text)+math.max(84,8+width(self.unitState,self.unitState.Text)+12)
        UI.box(self.unitIcon,x0,y,22,22);UI.box(self.unitName,x0+30,y,nw,22);UI.box(self.unitRole,x0+30+nw+6,y+1,math.max(0,w-x0-30-nw-6-84),20);UI.box(self.unitState,w-12-76,y+3,76,16)
        y+=27;UI.box(self.unitRule,x0,y,w-x0-12,1);y+=5
        if f and f.id==1 then
            for _,o in ipairs({self.unitRule,self.swatch,self.name,self.pill,self.sub,self.team,self.teamDot,self.capacity,self.troops,self.timers,self.dot,self.status,self.rule})do o.Visible=false end
            if self.goldMark then self.goldMark.Visible=false end;if self.troopMark then self.troopMark.Visible=false end
            for _,r in ipairs(self.rows)do r.key.Visible=false;r.value.Visible=false end
            for _,item in pairs(self.icons)do item.frame.Visible=false end
            self.edge.BackgroundColor3=C.accent
            local fit=math.clamp(math.ceil(self.unitNeed),140,w)
            if fit<w-4 and not ctx.fitted then local c=table.clone(ctx);c.width=fit;c.fitted=true;return self:show(c)end
            frame.Size=UDim2.fromOffset(w,34);frame.Visible=true;self.width=w;self.height=34
            return true
        end
    end
    y-=1
    local rel,relColor,filled
    if f then
        rel,relColor,filled=relation(f)
        if f.allied and not f.teammate and f.allianceExpires and s.tick then local left=f.allianceExpires-s.tick;rel=L.text(rel).." "..clock(left);if left<=300 then relColor=C.gold end end
        self.swatch.BackgroundColor3=FactionColors.get(f.id,f.kind,ctx.ownColor);self.name.Text=f.name or ""
        local honor=f.id~=1 and Honor.of(f);self.honor=honor
        self.sub.Text=f.id==1 and "내 영토" or honor and Honor.line(honor)or kinds[f.kind]or "플레이어"
    else
        self.swatch.BackgroundColor3=C.muted;self.name.Text="중립 땅";self.sub.Text=info and info.name or "";self.honor=nil
    end
    self.edge.BackgroundColor3=relColor or C.line
    self.pill.Visible=rel~=nil
    if rel then self.pill.Text=rel;self.pillStroke.Color=relColor;self.pill.BackgroundColor3=relColor;self.pill.BackgroundTransparency=filled and 0 or 1;self.pill.TextColor3=filled and C.bg or relColor end
    local right=w-12-(rel and width(self.pill,rel)+18 or 0)
    local team=Teams.of(f,s);self.team.Visible=team~=nil;self.teamDot.Visible=team~=nil
    if team then
        local tc=FactionColors.team(f.team,Teams.myTeam(s));local tw=width(self.team,team)
        self.team.Text=team;self.team.TextColor3=tc;self.teamDot.BackgroundColor3=tc
        right-=tw+14;UI.box(self.teamDot,right+2,y+7,8,8);UI.box(self.team,right+12,y,tw,22);right-=6
    end
    local kw=self.sub.Text~=""and math.min(120,width(self.sub,self.sub.Text))or 0
    self.sub.Visible=kw>0;self.sub.TextXAlignment=Right
    UI.box(self.swatch,x0,y+6,10,10);UI.box(self.name,x0+16,y,right-x0-16-kw-8,22);Honor.pill(self.name,self.honor and self.honor.plate)
    if kw>0 then UI.box(self.sub,right-kw-6,y+1,kw,20)end
    self.pill.Position=UDim2.fromOffset(w-12,y+2);self.pill.Size=UDim2.fromOffset(0,18);y+=23
    self.capacity.Visible=f~=nil;self.troops.Visible=f~=nil;if self.troopMark then self.troopMark.Visible=f~=nil end
    if self.goldMark then self.goldMark.Visible=false end
    for _,r in ipairs(self.rows)do r.key.Visible=false;r.value.Visible=false end
    local rx=x0
    if f then
        local barW=math.floor(math.min(150,(w-x0-12)*.42))
        UI.box(self.capacity,x0,y,barW,22);self.capacityFill.Size=UDim2.fromScale(math.clamp((f.troops or 0)/math.max(1,f.cap or f.troops or 1),0,1),1)
        self.troops.Text=UI.troops(f.troops)..(f.cap and " / "..UI.troops(f.cap)or "")
        if self.troopMark then UI.box(self.troopMark,x0+6,y+4,14,14);UI.box(self.troops,x0+20,y,barW-24,22)else UI.box(self.troops,x0+4,y,barW-8,22)end
        rx=x0+barW+10
        local gold,land=self.rows[1],self.rows[2]
        gold.value.Visible=true;gold.value.Text=UI.number(f.gold);gold.value.TextColor3=C.gold;local gw=width(gold.value,gold.value.Text)
        if self.goldMark then self.goldMark.Visible=true;UI.box(self.goldMark,rx,y+3,15,15);rx+=18
        else gold.key.Visible=true;gold.key.Text="골드";local kw=width(gold.key,"골드");UI.box(gold.key,rx,y,kw,22);rx+=kw+4 end
        UI.box(gold.value,rx,y,gw,22);rx+=gw+12
        land.key.Visible=true;land.value.Visible=true;land.key.Text="영토";land.value.Text=share(f.share);land.value.TextColor3=C.ink
        local kw,vw=width(land.key,"영토"),width(land.value,land.value.Text);UI.box(land.key,rx,y,kw,22);UI.box(land.value,rx+kw+4,y,vw,22);rx+=kw+4+vw+14
    end
    local rowStart=rx
    local status,dot
    if s.phase=="playing"then
        if u and f and f.id==1 then status=nil
        elseif not f then status,dot="클릭해서 확장",C.accent
        elseif f.id==1 then status,dot="클릭해서 건설",C.accent
        elseif f.teammate then status,dot="같은 팀 공격 불가",C.muted
        elseif f.allied then status,dot="동맹, 해제해야 공격",C.muted
        elseif s.attackTargets and s.attackTargets[tostring(f.id)]then status,dot=compact and "바로 공격 가능" or "바로 공격 가능, 한 번 더 클릭",C.good
        else status,dot="국경 밖, 해안이면 수송선",C.danger end
    end
    local chips={}
    if status then table.insert(chips,{L.text(status),dot==C.muted and C.muted or C.ink})end
    if f and f.id~=1 then
        if f.attitude~=nil and not f.allied then local t,color=attitude(f.attitude);table.insert(chips,{"AI "..L.text(t),color})end
        if f.traitor and f.traitorUntil and s.tick then table.insert(chips,{L.text("배신자").." "..clock(f.traitorUntil-s.tick),C.danger})end
        if f.embargoed or f.embargoedBy then table.insert(chips,{L.text("금수"),C.danger})end
    end
    local counts=f and self:structures(s,f.id)
    local n=0;if counts then for _,kind in ipairs(order)do if (counts[kind]or 0)>0 then n+=1 end end end
    local parts,plain={},{}
    for _,c in ipairs(chips)do table.insert(parts,string.format('<font color="%s">%s</font>',hex(c[2]),c[1]));table.insert(plain,c[1])end
    local words=#parts>0 and TextService:GetTextSize(table.concat(plain,", "),12,Enum.Font.BuilderSansBold,Vector2.new(1000,20)).X+4+(status and 12 or 0)or 0
    local strip=n*32
    local rowY,wordsY,stripY=y,y,y
    if f then
        local free=w-12-rx
        if words+strip+(words>0 and strip>0 and 6 or 0)>free then
            if strip<=free then wordsY=y+25 else wordsY=y+25;stripY=y+25;rx=x0 end
        end
        if wordsY~=rowY and stripY==rowY then rx=x0 end
    end
    local wordsX=wordsY==rowY and rx or x0
    local wordsRoom=w-12-wordsX-(stripY==wordsY and strip+6 or 0)
    if wordsY==stripY and words>0 and n>0 and words+strip+6>w-12-wordsX then stripY=wordsY+19;wordsRoom=w-12-wordsX end
    local sx=w-12-strip
    for _,kind in ipairs(order)do local item=self.icons[kind];local c=counts and counts[kind]or 0
        item.frame.Visible=n>0 and c>0
        if item.frame.Visible then item.count.Text=tostring(c);UI.box(item.frame,sx,stripY+(stripY==rowY and f and 2 or 0),30,18);sx+=32 end
    end
    local wy=wordsY+(wordsY==rowY and f and 2 or 0)
    self.rule.Visible=false;self.status.Visible=false;self.dot.Visible=status~=nil;self.timers.Visible=#parts>0
    if status then self.dot.BackgroundColor3=dot;UI.box(self.dot,wordsX,wy+6,6,6)end
    if #parts>0 then self.timers.Text=table.concat(parts,", ");UI.box(self.timers,wordsX+(status and 12 or 0),wy,wordsRoom-(status and 12 or 0),18)end
    local bottom=f and y+22 or y
    if #parts>0 then bottom=math.max(bottom,wordsY+(wordsY==rowY and f and 22 or 18))end
    if n>0 then bottom=math.max(bottom,stripY+(stripY==rowY and f and 22 or 18))end
    y=bottom+1
    if not compact and not ctx.fitted then
        local need=w-right+x0+16+width(self.name,self.name.Text)+8+(kw>0 and kw+6 or 0)+4
        if showUnit then need=math.max(need,self.unitNeed)end
        local one=rowStart+words+strip+(words>0 and strip>0 and 6 or 0)+12
        local two=math.max(rowStart-2,x0+words+strip+(words>0 and strip>0 and 6 or 0)+12)
        need=math.max(need,f and math.min(one,two)or one)
        local fit=math.clamp(math.ceil(need),200,w)
        if fit<w-4 then local c=table.clone(ctx);c.width=fit;c.fitted=true;return self:show(c)end
    end
    local pad=compact and 6 or 5
    frame.Size=UDim2.fromOffset(w,y+pad);frame.Visible=true;self.width=w;self.height=y+pad
    return true
end
local shipParts={RelationEdge=true,ShipSwatch=true,ShipText=true,ShipMark=true,Troops=true}
function M:showShip(u,f)
    local frame=self.frame
    if not u or not M.ships[u.kind] then frame.Visible=false;return false end
    for _,o in ipairs(frame:GetChildren())do if o:IsA("GuiObject")and not shipParts[o.Name]then o.Visible=false end end
    if self.troopMark then self.troopMark.Visible=false end
    local rel,relColor=nil,C.line;if f then rel,relColor=relation(f)end
    self.edge.Visible=true;self.edge.BackgroundColor3=relColor
    self.shipEdge.Visible=true;self.shipEdge.BackgroundColor3=FactionColors.get(u.owner or 0,f and f.kind,self.ownColor)
    local name=L.text(mobile[u.kind]);local count=UI.troops(u.troops or 0);local carry=u.kind=="TransportShip"
    self.shipText.Visible=true;self.shipText.Text=name.."  "..count;self.shipText.TextTruncate=Enum.TextTruncate.None
    local x=12;UI.box(self.shipEdge,x,9,8,8);x+=14
    local nw=width(self.shipText,name.."  ")
    if not carry then self.troops.Visible=false;self.shipText.Text=name;local tw=width(self.shipText,name);UI.box(self.shipText,x,0,tw,26);x+=tw
    elseif self.shipMark then
        self.shipText.Text=name;UI.box(self.shipText,x,0,nw,26);x+=nw
        self.shipMark.Visible=true;UI.box(self.shipMark,x,6,14,14);x+=17
        self.troops.Visible=true;self.troops.Text=count;self.troops.TextXAlignment=Left;local cw=width(self.troops,count);UI.box(self.troops,x,0,cw,26);x+=cw
    else local tw=width(self.shipText,self.shipText.Text);UI.box(self.shipText,x,0,tw,26);x+=tw end
    local w=x+10;frame.Size=UDim2.fromOffset(w,26);frame.Visible=true;self.width=w;self.height=26
    return true
end
function M:place(x,y,viewW,viewH)
    local w,h=self.width or WIDTH,self.height or 100
    local px=x+18;if px+w>viewW-8 then px=x-18-w end
    local py=y+16;if py+h>viewH-8 then py=y-16-h end
    self.frame.Position=UDim2.fromOffset(math.max(8,px),math.max(8,py));self.docked=false
end
function M:dock(viewW,top)
    self.frame.Position=UDim2.fromOffset(math.floor((viewW-(self.width or WIDTH))/2),top or 8);self.docked=true
end
function M:hide()self.frame.Visible=false end
return M
