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
local V2=require(script.Parent.Hud20).ENABLED
if V2 then for _,k in ipairs({'Train','AtomBomb','HydrogenBomb','MIRV','MIRVWarhead'})do M.ships[k]=true end end
local K,X
local WIDTH=440
local catalog={};for _,b in ipairs(Catalog)do catalog[b.kind]=b end
local order={"City","Port","Factory","DefensePost","MissileSilo","SAMLauncher"}
local mobile={TransportShip="수송선",Warship="군함",TradeShip="무역선",Train="화물열차",AtomBomb="원자폭탄",HydrogenBomb="수소폭탄",MIRV="다탄두",MIRVWarhead="다탄두"}
local kinds={HUMAN="플레이어",NATION="AI 국가",BOT="부족"}
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
    if V2 then return self:show20(ctx)end
    local s,f,info,u=ctx.state,ctx.faction,ctx.info,ctx.unit
    if ctx.compact then u=nil end
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
        elseif s.attackTargets and s.attackTargets[tostring(f.id)]then status,dot=compact and "바로 공격 가능" or "클릭하면 공격",C.good
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
    if V2 then return self:chip20(u,f,false)end
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
    if V2 then return self:place20(x,y,viewW,viewH)end
    local w,h=self.width or WIDTH,self.height or 100
    local px=x+18;if px+w>viewW-8 then px=x-18-w end
    local py=y+16;if py+h>viewH-8 then py=y-16-h end
    self.frame.Position=UDim2.fromOffset(math.max(8,px),math.max(8,py));self.docked=false
end
local MET={
    pc={w=300,wmax=360,px=11,py=9,r1=28,r2=24,r3=22,bar=18,name=15,num=15,cap=12,icon=15,chip=20,ts=12,close=28,xi=16,group=16,bi=14,bnum=12,bgap=10,minName=96},
    ph={w=230,wmax=230,px=9,py=7,r1=24,r2=20,r3=20,bar=14,name=13,num=13,cap=11,icon=13,chip=18,ts=11,close=24,xi=14,group=10,bi=14,bnum=12,bgap=8,minName=64},
}
local function attitude20(a)
    if a< -50 then return '적대','enemy' elseif a<0 then return '불신','grey' elseif a<50 then return '중립','grey' end
    return '우호','grey'
end
local function rel20(f)
    if not f then return nil,'grey' end
    if f.id==1 then return '나','grey' end
    if f.teammate then return '팀','team' end
    if f.allied then return '동맹','ally' end
    return '적','enemy'
end
local function relColor20(f)
    if not f then return K.colors.line end
    if f.id==1 then return K.colors.accent end
    if f.teammate then return K.team end
    if f.allied then return K.colors.ally end
    return K.colors.danger
end
local function landShare(v)v=(v or 0)*100;return string.format(v>0 and v<.1 and '%.2f%%'or '%.1f%%',v)end
local function factionOf(s,id)for _,f in ipairs(s and s.factions or {})do if f.id==id then return f end end;return nil end
function M:tag20(name,icon)
    local c=K.make('Frame',self.frame,{Name=name,BorderSizePixel=0,ZIndex=self.frame.ZIndex+1,Visible=false});K.round(c,4)
    local st=K.stroke(c,K.colors.danger,1,.2,true);st.Enabled=false
    local l=K.text(c,'Text','',12,K.colors.muted,700,Enum.TextXAlignment.Center);l.Size=UDim2.fromScale(1,1);l.ZIndex=c.ZIndex+1
    l:SetAttribute('LocalizationSkip',true);l.TextTruncate=Enum.TextTruncate.None
    local i
    if icon and icon.orig then i=X.orig(c,icon.orig,12,K.colors.danger,'Icon')elseif icon and icon.kit then i=K.icon(c,icon.kit,12,K.colors.muted,'Icon')end
    if i then i.ZIndex=c.ZIndex+1 end
    return {frame=c,label=l,icon=i,stroke=st,iconKind=icon and(icon.orig and 'orig'or 'kit')}
end
local function tagWidth(t,text,ts)return X.width(text,ts,t.label)+12+(t.icon and ts+3 or 0)end
local LOOK={
    grey=function()return K.colors.raised,1,nil,K.colors.muted end,
    enemy=function()return K.colors.danger,0,K.colors.danger,X.DANGER_INK end,
    traitor=function()return K.colors.danger,.18,nil,X.DANGER_INK end,
    ally=function()return K.colors.ally,.14,nil,K.colors.ally end,
    team=function()return K.team,.14,nil,K.team end,
}
local function setRest(o,prop,value)
    if o[prop]~=value then o[prop]=value end
    if o:GetAttribute('Rest20_'..prop)~=nil and o:GetAttribute('Rest20_'..prop)~=value then o:SetAttribute('Rest20_'..prop,value)end
end
local function paintTag(t,text,look,x,y,h,ts)
    local bg,alpha,line,ink=LOOK[look]()
    t.frame.Visible=true;t.label.Text=text;t.label.TextSize=ts;t.label.TextColor3=ink;t.frame.BackgroundColor3=bg
    setRest(t.frame,'BackgroundTransparency',1-alpha)
    t.stroke.Enabled=line~=nil;if line then t.stroke.Color=line;setRest(t.stroke,'Transparency',.2)end
    local tw=X.width(text,ts,t.label);local w=tagWidth(t,text,ts)
    if t.icon then
        if t.iconKind=='orig'then X.tint(t.icon,ink)else t.icon.ImageColor3=ink end
        K.box(t.icon,6,math.floor((h-ts)/2),ts,ts);K.box(t.label,6+ts+3,0,tw+2,h)
    else K.box(t.label,6,0,tw+2,h)end
    K.box(t.frame,x,y,w,h);return w
end
function M:build20()
    if self.v then return self.v end
    K=K or require(script.Parent.Kit20);X=X or require(script.Parent.Cards20)
    local f=self.frame;local v={}
    self.v=v
    for _,o in ipairs(f:GetChildren())do if o:IsA('GuiObject')then o.Visible=false elseif o:IsA('UIStroke')then o:Destroy()end end
    f.BackgroundColor3=X.GLASS;f.BackgroundTransparency=.06;f.BorderSizePixel=0
    K.stroke(f,K.colors.line,1,.1,true)
    v.edge=K.make('UIGradient',f,{Name='Edge20',Enabled=false})
    local z=f.ZIndex+1
    v.bar=K.make('Frame',f,{Name='Band20',BorderSizePixel=0,ZIndex=z});K.round(v.bar,'pill')
    v.name=K.text(f,'Name20','',15,K.colors.ink,800);v.name.ZIndex=z
    v.kind=self:tag20('Kind20');v.rel=self:tag20('Relation20');v.team=self:tag20('Team20')
    v.trait=self:tag20('Traitor20',{orig='Traitor'});v.embargo=self:tag20('Embargo20',{kit='embargo'})
    v.close=K.make('TextButton',f,{Name='Close20',Text='',BackgroundTransparency=1,AutoButtonColor=false,ZIndex=z+1})
    v.x=K.icon(v.close,'x',16,K.colors.muted,'X');v.x.ZIndex=z+2
    v.close.Activated:Connect(function()require(script.Parent.ToyAudio).play('click');if self.onClose then self.onClose()end;self:conceal(true)end)
    v.groups={}
    for i,key in ipairs({'troops','gold','land'})do
        local icon=key=='troops'and X.orig(f,'Soldier',15,K.colors.ink,'Troops20')
            or K.icon(f,key=='gold'and 'coinGold'or 'map',15,key=='gold'and Color3.new(1,1,1)or K.colors.muted,key=='gold'and 'Gold20'or 'Land20')
        icon.ZIndex=z
        local n=K.num(f,'Value'..i..'_20','',15,key=='gold'and K.colors.gold or K.colors.ink);n.ZIndex=z;n.TextTruncate=Enum.TextTruncate.None
        v.groups[i]={icon=icon,num=n}
    end
    v.cap=K.num(f,'Cap20','',12,K.colors.muted);v.cap.ZIndex=z;v.cap.TextTruncate=Enum.TextTruncate.None
    v.builds={}
    for _,kind in ipairs(order)do
        local icon=X.orig(f,kind,14,K.colors.muted,'Count20_'..kind);icon.ZIndex=z
        local n=K.num(f,'CountValue20_'..kind,'',12,K.colors.ink);n.ZIndex=z;n.TextTruncate=Enum.TextTruncate.None
        table.insert(v.builds,{kind=kind,icon=icon,num=n})
    end
    v.more=K.num(f,'CountMore20','',12,K.colors.muted);v.more.ZIndex=z;v.more.TextTruncate=Enum.TextTruncate.None
    v.uName=K.text(f,'UnitName20','',12,K.colors.ink,800);v.uName.ZIndex=z
    v.uRole=K.text(f,'UnitRole20','',12,K.colors.muted,700);v.uRole.ZIndex=z
    v.uState=K.num(f,'UnitState20','',12,K.colors.accent,Enum.TextXAlignment.Right);v.uState.ZIndex=z
    v.rule=K.make('Frame',f,{Name='Rule20',BackgroundColor3=K.colors.line,BorderSizePixel=0,ZIndex=z})
    v.sq=K.make('Frame',f,{Name='Owner20',BorderSizePixel=0,ZIndex=z});K.round(v.sq,2)
    v.cName=K.text(f,'ChipName20','',12,K.colors.ink,800);v.cName.ZIndex=z;v.cName.TextTruncate=Enum.TextTruncate.None
    v.cTroop=X.orig(f,'Soldier',12,K.colors.ink,'ChipTroops20');v.cTroop.ZIndex=z
    v.cNum=K.num(f,'ChipValue20','',12,K.colors.ink);v.cNum.ZIndex=z;v.cNum.TextTruncate=Enum.TextTruncate.None
    v.hp=K.fillBar(f,'Hull20',{p=1,fill=K.colors.good,track=K.colors.raised});v.hp.frame.ZIndex=z
    v.star=K.icon(f,'starFill',11,K.colors.gold,'Star20');v.star.ZIndex=z
    v.vet=K.num(f,'Veteran20','',11,K.colors.gold);v.vet.ZIndex=z;v.vet.TextTruncate=Enum.TextTruncate.None
    v.card={v.bar,v.name,v.close,v.rule,v.uName,v.uRole,v.uState,v.kind.frame,v.rel.frame,v.team.frame,v.trait.frame,v.embargo.frame,v.cap,v.more}
    for _,g in ipairs(v.groups)do table.insert(v.card,g.icon);table.insert(v.card,g.num)end
    for _,g in ipairs(v.builds)do table.insert(v.card,g.icon);table.insert(v.card,g.num)end
    v.chip={v.sq,v.cName,v.cTroop,v.cNum,v.hp.frame,v.star,v.vet}
    for _,o in ipairs(v.card)do o.Visible=false end;for _,o in ipairs(v.chip)do o.Visible=false end
    f:GetPropertyChangedSignal('Visible'):Connect(function()if not f.Visible then self.leaving=false;self.lingering=false;X.setCard(false)end end)
    return v
end
function M:mode20(mode)
    local v=self.v
    for _,o in ipairs(v.card)do o.Visible=false end;for _,o in ipairs(v.chip)do o.Visible=false end
    if v.glyph then v.glyph.Visible=false end
    v.mode=mode
    K.round(self.frame,mode=='card'and 12 or 6)
    if mode=='card'then v.edge.Enabled=false;self.frame.BackgroundColor3=X.GLASS end
end
function M:unitLine20(u,b,x0,right)
    local v=self.v;local f=self.frame
    if v.glyphKind~=u.kind then if v.glyph then v.glyph:Destroy()end;v.glyphKind=u.kind;v.glyph=X.orig(f,u.kind,16,K.colors.ink,'UnitGlyph20');v.glyph.ZIndex=f.ZIndex+1 end
    v.glyph.Visible=true;K.box(v.glyph,x0,4,16,16)
    local role=u.kind=='City'and not u.building and L.text('병력 상한 +')..UI.troops((u.level or 1)*250000)or b.role or ''
    local state=u.building and '건설 중'or u.kind=='MissileSilo'and string.format('%d/%d',u.readyMissiles or 0,u.level or 1)or 'Lv.'..(u.level or 1)
    v.uName.Visible=true;v.uName.Text=b.name;v.uRole.Visible=role~='';v.uRole.Text=role
    v.uState.Visible=true;v.uState.Text=state;v.uState.TextColor3=u.building and K.colors.muted or K.colors.accent
    if u.building then if K.fonts[800]then v.uState.FontFace=K.fonts[800]end else if K.fonts.num then v.uState.FontFace=K.fonts.num end end
    local nw=X.width(b.name,12,v.uName);local rw=role~=''and X.width(role,12,v.uRole)or 0;local sw=X.width(state,12,v.uState)
    local x=x0+16+6
    K.box(v.uName,x,0,nw+2,24);x+=nw+6
    if right then K.box(v.uState,right-sw-2,0,sw+2,24);K.box(v.uRole,x,0,math.max(0,right-sw-12-x),24)
    else K.box(v.uRole,x,0,rw+2,24)end
    return x0+16+6+nw+6+(rw>0 and rw+12 or 6)+sw
end
function M:show20(ctx)
    local s,f,info,u=ctx.state,ctx.faction,ctx.info,ctx.unit
    local v=self:build20()
    if not s then self:conceal();return false end
    if u and M.ships[u.kind]then self.ownColor=ctx.ownColor or self.ownColor;return self:chip20(u,factionOf(s,u.owner)or f,true)end
    local b=u and catalog[u.kind]
    if f and f.id==1 and not b or not f and not b and not(info and info.land and s.phase=='playing')then self:conceal();return false end
    local vw,vh=X.size(self.frame.Parent);local fmt=X.fmt(vw,vh);local m=MET[fmt=='pc'and 'pc'or 'ph']
    local w=fmt=='pt'and math.floor(vw-24)or m.w
    if fmt=='pt'then local panel=self.frame.Parent;local b=panel and panel:FindFirstChild('Hamburger20')
        if b and b.Visible then local _,bottom=X.clock(panel,fmt);if bottom+6<b.Position.Y.Offset+b.Size.Y.Offset then w=math.min(w,math.floor(b.Position.X.Offset-8-12))end end
    end
    self.ownColor=ctx.ownColor;local compact=ctx.compact==true
    local key=(b and 'u'..tostring(u.id)or '')..(f and 'f'..f.id or 'n')
    local frame=self.frame
    if b and f and f.id==1 then
        self:mode20('line')
        local need=self:unitLine20(u,b,9,nil)+8
        w=math.clamp(math.ceil(need),120,m.w);self:unitLine20(u,b,9,w-8)
        X.edge(frame,K.colors.accent,3,X.GLASS,1,w)
        frame.Size=UDim2.fromOffset(w,24);self.width,self.height=w,24
        self:swap20(key);return true
    end
    self:mode20('card')
    local mine=f and f.id==1
    local ts=m.ts
    local rel,relLook=rel20(f)
    local relText=rel and L.text(rel)
    if f and f.allied and not f.teammate and f.allianceExpires and s.tick then relText=L.text('동맹')..' '..clock(f.allianceExpires-s.tick)end
    local tags={}
    local team=f and Teams.of(f,s)
    if team then table.insert(tags,{t=v.team,text=L.text(team),look='team'})
    else
        local kindText,kindLook=nil,'grey'
        if f and f.kind=='NATION'then
            kindText=L.text('AI 국가')
            if f.attitude~=nil and not f.allied and not mine and not f.teammate then local t,look=attitude20(f.attitude);relText,relLook=L.text(t),look end
        elseif f and f.kind=='BOT'then kindText=L.text('부족')
        elseif not f and info and info.name and info.name~=''then kindText=L.text(info.name)end
        if kindText then table.insert(tags,{t=v.kind,text=kindText,look=kindLook})end
    end
    if relText and not(team and f.teammate)then table.insert(tags,{t=v.rel,text=relText,look=relLook})end
    local name=f and(f.name or '')or '중립 땅'
    v.name.TextSize=m.name
    local fullName=X.width(L.text(name),m.name,v.name)
    local chipsW=0;for _,tg in ipairs(tags)do tg.w=tagWidth(tg.t,tg.text,ts);chipsW+=8+tg.w end
    local closeW=compact and m.close+4 or 0
    local need=m.px+3+8+fullName+chipsW+closeW+m.px
    local values,widths,capText,capW,row2
    if f then
        values={UI.troops(f.troops),UI.number(f.gold),landShare(f.share)}
        capText=f.cap and f.cap>0 and '/ '..UI.troops(f.cap)or nil
        widths={};row2=m.px
        for i,g in ipairs(v.groups)do g.num.TextSize=m.num;widths[i]=X.width(values[i],m.num,g.num);row2+=m.icon+5+widths[i]+(i<3 and m.group or 0)end
        v.cap.TextSize=m.cap;capW=capText and X.width(capText,m.cap,v.cap)or 0
        need=math.max(need,row2+(capText and 4+capW or 0)+m.px)
    end
    local facts={}
    local left=f and f.traitor and not mine and f.traitorUntil and s.tick and f.traitorUntil-s.tick or 0
    if v.traitFor and(not f or v.traitFor~=f.id)then v.traitFor=nil end
    if left>0 then
        if v.traitFading then v.traitFading=nil;K.fade(v.trait.frame,true,0)end
        v.traitFor=f.id;v.traitText=L.text('배신자')..' '..L.text(string.format('%d초',math.ceil(left/10)))
        table.insert(facts,{t=v.trait,text=v.traitText,look='traitor'})
    elseif f and v.traitFor==f.id and v.traitText then
        if not v.traitFading then v.traitFading=os.clock()+.1;K.fade(v.trait.frame,false,.1)end
        if os.clock()<v.traitFading then table.insert(facts,{t=v.trait,text=v.traitText,look='traitor'})else v.traitFor=nil end
    end
    if f and not mine and(f.embargoed or f.embargoedBy)then table.insert(facts,{t=v.embargo,text=L.text('금수'),look='grey'})end
    local items={}
    local counts=f and not mine and self:structures(s,f.id)
    for _,bd in ipairs(v.builds)do local c=counts and counts[bd.kind]or 0;if c>0 then bd.num.TextSize=m.bnum;local t=tostring(c);table.insert(items,{bd=bd,text=t,w=X.width(t,m.bnum,bd.num)})end end
    local row3=#facts>0 or #items>0
    if row3 then
        local r=m.px
        for i,fc in ipairs(facts)do fc.w=tagWidth(fc.t,fc.text,ts);r+=(i>1 and 8 or 0)+fc.w end
        for i,it in ipairs(items)do if i<=5 then r+=((#facts>0 or i>1)and m.bgap or 0)+m.bi+3+it.w end end
        if #items>5 then v.more.TextSize=m.bnum;r+=m.bgap+X.width('+'..(#items-5),m.bnum,v.more)end
        need=math.max(need,r+m.px)
    end
    local top=0
    if b then need=math.max(need,self:unitLine20(u,b,m.px,nil)+m.px)end
    if fmt~='pt'then w=math.clamp(math.ceil(need),m.w,m.wmax)end
    if b then self:unitLine20(u,b,m.px,w-m.px);v.rule.Visible=true;K.box(v.rule,m.px,24,w-m.px*2,1);top=25 end
    local y1=top+m.py
    v.bar.Visible=true;v.bar.BackgroundColor3=f and FactionColors.get(f.id,f.kind,ctx.ownColor)or K.colors.muted
    K.box(v.bar,m.px,y1+math.floor((m.r1-m.bar)/2),3,m.bar)
    local right=w-m.px-closeW
    v.name.Visible=true;v.name.Text=name
    local x=m.px+3+8
    local nw=math.max(24,math.min(fullName,right-x-chipsW))
    K.box(v.name,x,y1,nw+2,m.r1);x+=nw
    local cy=y1+math.floor((m.r1-m.chip)/2)
    for _,tg in ipairs(tags)do x+=8;x+=paintTag(tg.t,tg.text,tg.look,x,cy,m.chip,ts)end
    v.close.Visible=compact
    if compact then local cx,cyy=w-m.px-m.close/2,y1+m.r1/2;K.box(v.close,cx-18,cyy-18,36,36);K.box(v.x,18-m.xi/2,18-m.xi/2,m.xi,m.xi)end
    local bottom=y1+m.r1
    if f then
        local y2=bottom
        local group=m.group
        if capText and row2+4+capW>w-m.px then group=math.min(group,6);if row2-2*(m.group-group)+4+capW>w-m.px then capText=nil;group=m.group end end
        x=m.px
        for i,g in ipairs(v.groups)do
            g.icon.Visible=true;g.num.Visible=true;g.num.Text=values[i]
            K.box(g.icon,x,y2+math.floor((m.r2-m.icon)/2),m.icon,m.icon);x+=m.icon+5
            K.box(g.num,x,y2,widths[i]+2,m.r2);x+=widths[i]
            if i==1 and capText then v.cap.Visible=true;v.cap.Text=capText;x+=4;K.box(v.cap,x,y2+1,capW+2,m.r2);x+=capW end
            x+=group
        end
        bottom=y2+m.r2
    end
    if row3 then
        local ry=bottom;x=m.px;local any=false
        for _,fc in ipairs(facts)do
            if any then x+=8 end
            x+=paintTag(fc.t,fc.text,fc.look,x,ry+math.floor((m.r3-m.chip)/2),m.chip,ts);any=true
        end
        local shown=0
        for i,it in ipairs(items)do
            local step=(any and m.bgap or 0)+m.bi+3+it.w
            local rest=#items-i
            local moreW=rest>0 and m.bgap+X.width('+'..rest,m.bnum,v.more)or 0
            if shown>=5 or x+step+moreW>w-m.px then break end
            if any then x+=m.bgap end
            local bd=it.bd
            bd.icon.Visible=true;K.box(bd.icon,x,ry+math.floor((m.r3-m.bi)/2),m.bi,m.bi);x+=m.bi+3
            bd.num.Visible=true;bd.num.Text=it.text;K.box(bd.num,x,ry,it.w+2,m.r3);x+=it.w;any=true;shown+=1
        end
        local hidden=#items-shown
        if hidden>0 then
            v.more.TextSize=m.bnum;v.more.Text='+'..hidden;local mw=X.width(v.more.Text,m.bnum,v.more)
            if any then x+=m.bgap end;v.more.Visible=true;K.box(v.more,x,ry,mw+2,m.r3)
        end
        bottom=ry+m.r3
    end
    local h=bottom+m.py
    frame.Size=UDim2.fromOffset(w,h);self.width,self.height=w,h
    self:swap20(key);return true
end
function M:chip20(u,f,docked)
    local v=self:build20()
    if not u or not M.ships[u.kind]then self:conceal();return false end
    local vw,vh=X.size(self.frame.Parent);local fmt=X.fmt(vw,vh)
    self:mode20('chip')
    local relColor=relColor20(f)
    local name=L.text(mobile[u.kind]or u.kind)
    if fmt~='pc'and f and f.id~=1 then name=name..', '..L.nation(f)end
    local x=9
    v.sq.Visible=true;v.sq.BackgroundColor3=FactionColors.get(u.owner or 0,f and f.kind,self.ownColor);K.box(v.sq,x,6,8,8);x+=8+6
    v.cName.Visible=true;v.cName.Text=name;v.cName:SetAttribute('LocalizationSkip',true)
    local nw=X.width(name,12,v.cName);K.box(v.cName,x,0,nw+2,20);x+=nw
    if u.kind=='TransportShip'then
        x+=6;v.cTroop.Visible=true;K.box(v.cTroop,x,4,12,12);x+=12+6
        local t=UI.troops(u.troops or 0);v.cNum.Visible=true;v.cNum.Text=t;local tw=X.width(t,12,v.cNum);K.box(v.cNum,x,0,tw+2,20);x+=tw
    elseif u.kind=='Warship'then
        x+=6;local r=math.clamp((u.health or 0)/math.max(1,u.maxHealth or u.health or 1),0,1)
        v.hp.frame.Visible=true;K.box(v.hp.frame,x,8,24,4);v.hp:setColors(r>.5 and K.colors.good or r>.25 and K.colors.gold or K.colors.danger);v.hp:set(r);x+=24
        local vet=u.veterancy or 0
        if vet>0 then x+=6;v.star.Visible=true;K.box(v.star,x,4,11,11);x+=11+2;v.vet.Visible=true;v.vet.Text=tostring(vet);local tw=X.width(v.vet.Text,11,v.vet);K.box(v.vet,x,0,tw+2,20);x+=tw end
    end
    local w=x+8
    X.edge(self.frame,relColor,3,X.GLASS,1,w)
    self.frame.Size=UDim2.fromOffset(w,20);self.width,self.height=w,20
    self:swap20('c'..tostring(u.id))
    return true
end
function M:swap20(key)
    local f=self.frame
    if key~=self.shownKey and f.Visible and not self.leaving and self.shownMode=='top'and not K.reduced then
        for _,o in ipairs(f:GetChildren())do if o:IsA('GuiObject')and o.Visible and o.Name~='Close20'then K.fade(o,false,0);K.fade(o,true,.08)end end
    end
    self.shownKey=key
end
function M:moveTo(x,y,mode)
    local f=self.frame;local home=UDim2.fromOffset(math.floor(x+.5),math.floor(y+.5))
    local fresh=not f.Visible or self.leaving or self.shownMode~=mode
    self.hideToken=(self.hideToken or 0)+1;self.leaving=false;self.lingering=false;self.shownMode=mode
    if fresh then
        f.Visible=true;K.fade(f,false,0)
        local t=mode=='cursor'and .06 or .10
        if self.moveTween then self.moveTween:Cancel();self.moveTween=nil end
        if mode=='top'and not K.reduced then
            f.Position=home-UDim2.fromOffset(0,4)
            self.moveTween=game:GetService('TweenService'):Create(f,TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=home});self.moveTween:Play()
        else f.Position=home end
        K.fade(f,true,t)
    elseif self.home~=home then
        if self.moveTween then self.moveTween:Cancel();self.moveTween=nil end;f.Position=home
    end
    self.home=home
end
function M:conceal(now)
    local f=self.frame
    if not f.Visible or self.leaving or(self.lingering and not now)then return end
    if not self.v then f.Visible=false;return end
    local token=(self.hideToken or 0)+1;self.hideToken=token
    local cursor=self.shownMode=='cursor'
    local function go()
        if self.hideToken~=token or not f.Visible then return end
        self.lingering=false;self.leaving=true
        local t=cursor and .06 or .10;K.fade(f,false,t)
        task.delay(K.reduced and .12 or t,function()if self.hideToken==token and self.leaving then f.Visible=false;self.leaving=false end end)
    end
    if now or cursor then go()else self.lingering=true;task.delay(.25,go)end
end
function M:place20(x,y,vw,vh)
    local w,h=self.width or 100,self.height or 20
    local px=x+18;if px+w>vw-8 then px=x-18-w end
    local py=y+16;if py+h>vh-8 then py=y-16-h end
    self.docked=false;X.setCard(false)
    self:moveTo(math.max(8,px),math.max(8,py),'cursor')
end
function M:dock20(viewW)
    local v=self:build20();local panel=self.frame.Parent
    local vw,vh=X.size(panel);local fmt=X.fmt(vw,vh)
    local w,h=self.width or 300,self.height or 70
    local x=(fmt=='pt'and v.mode=='card')and 12 or math.floor((vw-w)/2+.5)
    local y
    if v.mode=='chip'and fmt=='pt'then y=(X.clock(panel,fmt))+4
    elseif fmt=='pt'then local _,bottom=X.clock(panel,fmt)
        local chip=panel and panel:FindFirstChild('CampaignTask20');if chip and chip.Visible then bottom=math.max(bottom,chip.Position.Y.Offset+chip.Size.Y.Offset)end
        local guide=panel and panel:FindFirstChild('Guide');if guide and guide:IsA('GuiObject')and guide.Visible then
            local s=(panel.AbsoluteSize.X>0 and X.size(panel))and panel.AbsoluteSize.X/X.size(panel)or 1
            bottom=math.max(bottom,(guide.AbsolutePosition.Y+guide.AbsoluteSize.Y-panel.AbsolutePosition.Y)/s)end
        y=bottom+6
    else y=X.y(fmt=='pc'and 12 or v.mode=='chip'and 10 or 8)end
    self.docked=true
    self:moveTo(x,y,'top')
    X.setCard(true,y+h)
end
function M:dock(viewW,top)
    if V2 then return self:dock20(viewW)end
    self.frame.Position=UDim2.fromOffset(math.floor((viewW-(self.width or WIDTH))/2),top or 8);self.docked=true
end
function M:hide()if V2 then self:conceal(true)else self.frame.Visible=false end end
return M
