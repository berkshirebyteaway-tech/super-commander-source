local Theme=require(script.Parent.Theme)
local Raster=require(script.Parent.RasterMap)
local Finish=require(script.Parent.MapFinish)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local UserInput=game:GetService("UserInputService")
local TextService=game:GetService("TextService")
local M={};M.__index=M
M.CATEGORIES={
    {id="featured",label="추천"},
    {id="all",label="전체"},
    {id="europe",label="유럽",groups={"europe"}},
    {id="asia",label="아시아",groups={"asia"}},
    {id="northamerica",label="북아메리카",groups={"north_america"}},
    {id="south",label="남미와 오세아니아",groups={"south_america","oceania"}},
    {id="africa",label="아프리카",groups={"africa"}},
    {id="world",label="세계와 대륙",groups={"world","continental","antarctica"}},
    {id="countries",label="국가",groups={"countries"}},
    {id="fantasy",label="가상과 우주",groups={"fictional","cosmic"}},
    {id="arcade",label="아케이드",groups={"arcade","tournament"}},
    {id="teams",label="팀전"},
}
M.IMAGES=24
local GAP,RAIL=10,184
local Left,Right,Center=Enum.TextXAlignment.Left,Enum.TextXAlignment.Right,Enum.TextXAlignment.Center
local order={};for i,m in ipairs(Maps.catalog)do order[m.key]=i end
local function featured(m)return (m.featuredRank or 0)>0 end
local function member(m,c)
    if c.id=="all"then return true end
    if c.id=="featured"then return featured(m)or m.isNew==true end
    if c.id=="teams"then return (m.teamCount or 0)>0 end
    for _,g in ipairs(m.groups or {})do if table.find(c.groups,g)then return true end end
    return false
end
local function before(a,b)
    local fa,fb=featured(a)and a.featuredRank or math.huge,featured(b)and b.featuredRank or math.huge
    if fa~=fb then return fa<fb end
    local wa,wb=a.rotationWeight or 0,b.rotationWeight or 0
    if wa~=wb then return wa>wb end
    return order[a.key]<order[b.key]
end
local K=require(script.Parent.Kit20)
local function click()require(script.Parent.ToyAudio).play("click")end
local function text(UI,parent,name,value,size,color,font,align)
    if UI==K then
        local t=K.text(parent,name,value,size,color,font==Enum.Font.BuilderSansBold and 800 or 700,align or Left);t:SetAttribute("Kit20",true);return t
    end
    local t=UI.label(parent,name,value,size,color);t.Font=font or Enum.Font.BuilderSansMedium
    t.TextWrapped=false;t.TextTruncate=Enum.TextTruncate.AtEnd;t.TextXAlignment=align or Left;return t
end
local function measure(t)
    if t:GetAttribute("Kit20")then return K.width(t.Text,t.TextSize,t)end
    return TextService:GetTextSize(t.Text,t.TextSize,t.Font,Vector2.new(1000,100)).X
end
function M.new(parent,onSelect,theme,lobby)
    local UI=theme or Theme;local C=UI.colors
    local self=setmetatable({selected="world",category="featured",query="",onSelect=onSelect,UI=UI,items={},cards={},tabs={},headers={},rasters={},spare={},queue={},connections={},alive=true},M)
    self.touch=require(script.Parent.InputMode).touch()
    if require(script.Parent.Lobby20).ENABLED then
        local W20=require(script.Parent.Setup20);local l=lobby or W20.lobbyFor(parent)
        if l then
            local win=W20.open(l,parent,"maps")
            W20.head(win,"지도 선택",l.backTo and function()l:back()end or nil,function()l.returnPage=nil;l:closePage()end)
            local host=K.make("Frame",win.card,{Name="MapHost",BackgroundTransparency=1,BorderSizePixel=0})
            K.box(host,win.x,win.top,win.w,win.bottom-win.top)
            self.v2={win=win,host=host};parent=host;C=K.colors
        end
    end
    local v2=self.v2~=nil;local T=v2 and K or UI
    self.T=T
    local f=UI.make("Frame",parent,{Name="MapBrowser",BackgroundTransparency=1,BorderSizePixel=0});self.frame=f
    local search
    if v2 then
        search=K.make("TextBox",f,{Name="Search",Text="",PlaceholderText="지도 이름 검색",ClearTextOnFocus=false,BackgroundColor3=C.bg,TextColor3=C.ink,PlaceholderColor3=C.muted,TextSize=14,BorderSizePixel=0,TextXAlignment=Left,ClipsDescendants=true})
        if K.fonts[700]then search.FontFace=K.fonts[700]end;K.round(search,8);K.stroke(search,C.line,1,0,true)
    else
        search=UI.corner(UI.make("TextBox",f,{Name="Search",Text="",PlaceholderText="지도 이름 검색",ClearTextOnFocus=false,BackgroundColor3=C.raised,TextColor3=C.ink,PlaceholderColor3=C.muted,TextSize=14,Font=Enum.Font.BuilderSansMedium,BorderSizePixel=0,TextXAlignment=Left,ClipsDescendants=true}),3)
        UI.stroke(search,C.line,1)
    end
    UI.make("UIPadding",search,{PaddingLeft=UDim.new(0,32),PaddingRight=UDim.new(0,36)});self.search=search
    self.lens=UI.make("Frame",f,{Name="SearchIcon",BackgroundTransparency=1,BorderSizePixel=0,ZIndex=2,Size=UDim2.fromOffset(16,16)})
    local ring=UI.make("Frame",self.lens,{Name="Ring",BackgroundTransparency=1,BorderSizePixel=0,ZIndex=2,Size=UDim2.fromOffset(11,11)})
    if v2 then K.round(ring,"pill");K.stroke(ring,C.muted,2)else UI.corner(ring,40);UI.stroke(ring,C.muted,2)end
    UI.make("Frame",self.lens,{Name="Handle",BackgroundColor3=C.muted,BorderSizePixel=0,ZIndex=2,Rotation=45,Position=UDim2.fromOffset(9,11),Size=UDim2.fromOffset(6,2)})
    if v2 then
        self.clear=K.make("TextButton",f,{Name="Clear",Text="",BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,ZIndex=2,Visible=false})
        local x=K.icon(self.clear,"x",14,C.muted,"Icon");x.AnchorPoint=Vector2.new(.5,.5);x.Position=UDim2.fromScale(.5,.5);x.ZIndex=3
        self.clear.Activated:Connect(function()click();search.Text=""end)
    else
        self.clear=UI.button(f,"Clear","×",function()search.Text=""end)
        self.clear.BackgroundTransparency=1;self.clear.TextColor3=C.muted;self.clear.TextSize=20;self.clear.ZIndex=2;self.clear.Visible=false
    end
    search:GetPropertyChangedSignal("Text"):Connect(function()
        local q=string.lower(search.Text)
        if q~=""and self.query==""and self.category=="featured"then self.category="all"end
        self.query=q;self:refresh(true)
    end)
    self.categories=UI.make("ScrollingFrame",f,{Name="Categories",BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=0,CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.Y})
    for _,c in ipairs(M.CATEGORIES)do
        local function pick()require(script.Parent.TelemetryStep).step("map_ui","mapCategory",{item=c.id});self.category=c.id;self:refresh(true)end
        local b,edge
        if v2 then
            b=K.make("TextButton",self.categories,{Name="Filter_"..c.id,Text="",BackgroundColor3=C.raised,BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false})
            K.round(b,8);edge=K.stroke(b,C.line,1,0,true);b.Activated:Connect(function()click();pick()end)
        else b=UI.button(self.categories,"Filter_"..c.id,"",pick);b.AutoButtonColor=false end
        local t={button=b,edge=edge,category=c,mark=UI.make("Frame",b,{Name="Mark",BackgroundColor3=C.accent,BorderSizePixel=0,Visible=false}),
            label=text(T,b,"Label",c.label,14,C.ink),count=v2 and K.num(b,"Count","",13,C.muted)or text(UI,b,"Count","",12,C.muted)}
        if v2 then K.round(t.mark,"pill");t.count:SetAttribute("Kit20",true)end
        table.insert(self.tabs,t)
    end
    self.railLine=UI.make("Frame",f,{Name="RailLine",BackgroundColor3=C.line,BorderSizePixel=0})
    self.grid=UI.make("ScrollingFrame",f,{Name="Grid",BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=v2 and 3 or 4,ScrollBarImageColor3=C.line,CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.Y})
    self.content=UI.make("Frame",self.grid,{Name="Content",BackgroundTransparency=1,BorderSizePixel=0})
    self.empty=text(T,self.grid,"Empty","검색 결과 없음",14,C.muted,nil,Center);self.empty.TextWrapped=true;self.empty.Visible=false
    table.insert(self.connections,self.grid:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        self:window();task.defer(function()if self.alive then self:window()end end)
    end))
    table.insert(self.connections,parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if self.alive and self.width then self:layout(self.width);if self.onLayout then self.onLayout()end end
    end))
    self:refresh();return self
end
function M:card(m)
    local c=self.cards[m.key];if c then return c end
    local UI=self.UI;local C=UI.colors
    c={key=m.key}
    local function pick()self.selected=m.key;self:refreshSelection();self.onSelect(m.key)end
    if self.v2 then return self:card20(m,c,pick)end
    local b=UI.button(self.content,"Map_"..m.key,"",pick)
    b.BackgroundColor3=C.raised;c.button=b;c.stroke=UI.stroke(b,C.line,1)
    c.picture=UI.corner(UI.make("Frame",b,{Name="Preview",BackgroundColor3=C.ocean,BorderSizePixel=0,ClipsDescendants=true}),3)
    c.title=text(UI,b,"Title",m.label,15,C.ink,Enum.Font.BuilderSansBold)
    c.detail=text(UI,b,"Detail",#(m.nations or {})>0 and string.format("라이벌 %d명",#m.nations)or m.description or "",12,C.muted)
    local function badge(name,value,bg,ink)
        local t=text(UI,c.picture,name,value,11,ink,Enum.Font.BuilderSansBold,Center);t.BackgroundTransparency=0;t.BackgroundColor3=bg;t.ZIndex=2;UI.corner(t,2);return t
    end
    c.new=m.isNew and badge("New","NEW",C.accent,C.bg)or nil
    c.teams=(m.teamCount or 0)>0 and badge("Teams",string.format("%d팀",m.teamCount),C.panel,C.ice)or nil
    if c.teams then c.teams.BackgroundTransparency=.15 end
    c.check=badge("Selected","✓",C.accent,C.bg);c.check.TextSize=13
    self.cards[m.key]=c;self:refreshSelection()
    return c
end
function M:card20(m,c,pick)
    local C=K.colors
    local b=K.make("TextButton",self.content,{Name="Map_"..m.key,Text="",BackgroundColor3=C.panel,BorderSizePixel=0,AutoButtonColor=false})
    K.round(b,8);c.button=b;c.stroke=K.stroke(b,C.line,1,0,true)
    b.Activated:Connect(function()click();pick()end)
    b.MouseEnter:Connect(function()if self.selected~=c.key then c.stroke.Color=C.muted end end)
    b.MouseLeave:Connect(function()if self.selected~=c.key then c.stroke.Color=C.line end end)
    c.picture=K.make("Frame",b,{Name="Preview",BackgroundColor3=C.ocean,BorderSizePixel=0,ClipsDescendants=true});K.round(c.picture,6)
    c.title=text(K,b,"Title",m.label,15,C.ink,Enum.Font.BuilderSansBold)
    c.detail=text(K,b,"Detail",#(m.nations or {})>0 and string.format("라이벌 %d명",#m.nations)or m.description or "",12,C.muted)
    if m.isNew then local chip,w=K.chip(c.picture,"New","NEW","accent",{size=11,height=18,filled=true,icon=false});chip.ZIndex=2;c.new,c.newW=chip,w end
    if (m.teamCount or 0)>0 then
        local chip,_,_,l=K.chip(c.picture,"Teams",string.format("%d팀",m.teamCount),nil,{size=11,height=18,icon=false});chip.ZIndex=2;l.TextColor3=C.ice;c.teams=chip
    end
    local check=K.make("Frame",c.picture,{Name="Selected",BackgroundColor3=C.accent,BorderSizePixel=0,ZIndex=2,Size=UDim2.fromOffset(20,20)});K.round(check,"pill")
    local mark=K.icon(check,"check",12,C.bg,"Icon");K.box(mark,4,4,12,12);mark.ZIndex=3;c.check=check
    self.cards[m.key]=c;self:refreshSelection()
    return c
end
function M:refreshSelection()
    local C=self.UI.colors
    for key,c in pairs(self.cards)do local on=key==self.selected;c.stroke.Color=on and C.accent or C.line;c.stroke.Thickness=on and 2 or 1;c.check.Visible=on end
end
function M:refresh(reset)
    local UI=self.UI;local C=UI.colors;local q=self.query
    local matches,counts={},{}
    for _,c in ipairs(M.CATEGORIES)do counts[c.id]=0 end
    for _,m in ipairs(Maps.catalog)do
        if q==""or string.find(string.lower(m.label.." "..(m.englishName or "").." "..m.key),q,1,true)then
            table.insert(matches,m);for _,c in ipairs(M.CATEGORIES)do if member(m,c)then counts[c.id]+=1 end end
        end
    end
    local current=M.CATEGORIES[2];for _,c in ipairs(M.CATEGORIES)do if c.id==self.category then current=c end end;self.category=current.id
    local items={}
    local function shelf(header,list)
        if #list==0 then return end;table.sort(list,before)
        if header then table.insert(items,{header=header})end;for _,m in ipairs(list)do table.insert(items,{map=m})end
    end
    if current.id=="featured"then
        local top,new={},{};for _,m in ipairs(matches)do if featured(m)then table.insert(top,m)elseif m.isNew then table.insert(new,m)end end
        shelf("대표 지도",top);shelf("새 지도",new)
    else local list={};for _,m in ipairs(matches)do if member(m,current)then table.insert(list,m)end end;shelf(nil,list)end
    self.items=items;self.rects=nil;self.visibleCount=0;for _,item in ipairs(items)do if item.map then self.visibleCount+=1 end end
    for _,t in ipairs(self.tabs)do
        local on=t.category.id==self.category;t.on=on;t.count.Text=tostring(counts[t.category.id])
        if self.v2 then local face=K.fonts[on and 800 or 700];if face then t.label.FontFace=face end
        else t.label.Font=on and Enum.Font.BuilderSansBold or Enum.Font.BuilderSansMedium end
        t.empty=counts[t.category.id]==0
    end
    self.clear.Visible=q~="";self.empty.Visible=#items==0
    if q~=""then require(script.Parent.TelemetryStep).change("mapSearch","map_ui","search",{result=#items==0 and "unavailable"or "shown",value=#items})end
    if reset then self.grid.CanvasPosition=Vector2.zero end
    if self.width then self:layout(self.width)end;if self.onLayout then self.onLayout()end
end
function M:layout(width,short)
    local UI=self.UI;local C=UI.colors;local v2=self.v2
    if short~=nil then self.short=short end
    if v2 then width=v2.host.Size.X.Offset end
    self.width=width
    local parentHeight=self.frame.Parent and self.frame.Parent.AbsoluteSize.Y/Theme.scale or 0
    local height=math.floor(parentHeight>0 and math.max(self.short and 200 or 280,parentHeight)or 420)
    if v2 then height=v2.host.Size.Y.Offset end
    local row=self.touch and 44 or 38;local rail=width>=600;local gx,gy
    if rail then
        UI.box(self.search,0,0,RAIL,44);self.categories.ScrollingDirection=Enum.ScrollingDirection.Y;UI.box(self.categories,0,52,RAIL,height-52)
        local y=0
        for _,t in ipairs(self.tabs)do
            t.label.TextSize=14;if measure(t.label)>RAIL-60 then t.label.TextSize=12 end
            UI.box(t.button,0,y,RAIL,row);UI.box(t.mark,0,8,3,row-16);UI.box(t.label,14,0,RAIL-60,row);UI.box(t.count,RAIL-44,0,32,row)
            t.count.TextXAlignment=Right;t.mark.Visible=t.on
            t.button.BackgroundColor3=C.raised;t.button.BackgroundTransparency=t.on and 0 or 1
            if t.edge then t.edge.Enabled=false end
            t.label.TextColor3=t.empty and not t.on and C.muted or C.ink;t.count.TextColor3=t.on and C.accent or C.muted
            y+=row+2
        end
        self.categories.CanvasSize=UDim2.fromOffset(0,y);self.railLine.Visible=true;UI.box(self.railLine,RAIL+7,0,1,height)
        gx,gy=RAIL+15,0
    else
        UI.box(self.search,0,0,width,44);self.categories.ScrollingDirection=Enum.ScrollingDirection.X;UI.box(self.categories,0,52,width,row)
        local x=0
        for _,t in ipairs(self.tabs)do
            t.label.TextSize=14;local lw,cw=measure(t.label),measure(t.count);local w=math.ceil(14+lw+6+cw+14)
            UI.box(t.button,x,0,w,row);UI.box(t.label,14,0,lw+2,row);UI.box(t.count,14+lw+6,0,cw+2,row)
            t.count.TextXAlignment=Left;t.mark.Visible=false
            if v2 then
                t.button.BackgroundTransparency=t.on and 0 or 1;t.button.BackgroundColor3=C.raised
                t.edge.Enabled=true;t.edge.Color=t.on and C.accent or C.line
                t.label.TextColor3=t.on and C.ink or t.empty and C.muted or C.ink;t.count.TextColor3=t.on and C.accent or C.muted
            else
                t.button.BackgroundTransparency=0;t.button.BackgroundColor3=t.on and C.accent or C.raised
                t.label.TextColor3=t.on and C.bg or t.empty and C.muted or C.ink;t.count.TextColor3=t.on and C.bg or C.muted
            end
            x+=w+6
        end
        self.categories.CanvasSize=UDim2.fromOffset(math.max(0,x-6),0);self.railLine.Visible=false
        gx,gy=0,52+row+10
    end
    local sx,sy=self.search.Position.X.Offset,self.search.Position.Y.Offset;local sw=self.search.Size.X.Offset
    UI.box(self.lens,sx+12,sy+15,16,16)
    if v2 then UI.box(self.clear,sx+sw-44,sy,44,44)else UI.box(self.clear,sx+sw-40,sy+2,38,40)end
    local gw,gh=width-gx,height-gy;UI.box(self.grid,gx,gy,gw,gh)
    local inner=gw-12;local cols=inner>=640 and 4 or inner>=420 and 3 or 2
    local cw=math.floor((inner-(cols-1)*GAP)/cols);local ph=math.floor(cw*(self.short and .48 or .56));local ch=ph+56
    local rects,y,col,headers={},0,0,0
    for i,item in ipairs(self.items)do
        if item.header then
            if col>0 then y+=ch+GAP;col=0 end
            headers+=1;local h=self.headers[headers]
            if not h then h={label=text(self.T,self.content,"Shelf"..headers,"",13,C.muted,Enum.Font.BuilderSansBold),line=UI.make("Frame",self.content,{Name="ShelfLine"..headers,BackgroundColor3=C.line,BorderSizePixel=0})};self.headers[headers]=h end
            h.label.Text=item.header;h.label.Visible=true;h.line.Visible=true
            local tw=measure(h.label);UI.box(h.label,2,y,tw+4,28);UI.box(h.line,tw+16,y+14,math.max(0,inner-tw-16),1)
            rects[i]={x=0,y=y,w=inner,h=28};y+=34
        else
            rects[i]={x=col*(cw+GAP),y=y,w=cw,h=ch};col+=1;if col==cols then col=0;y+=ch+GAP end
        end
    end
    if col>0 then y+=ch+GAP end
    for i=headers+1,#self.headers do self.headers[i].label.Visible=false;self.headers[i].line.Visible=false end
    local shown={}
    for i,item in ipairs(self.items)do
        if item.map then
            local c=self:card(item.map);local r=rects[i];shown[c]=true;UI.box(c.button,r.x,r.y,r.w,r.h)
            if c.width~=cw then
                c.width=cw;c.drawn=false;UI.box(c.picture,6,6,cw-12,ph)
                UI.box(c.title,10,ph+12,cw-20,20);UI.box(c.detail,10,ph+32,cw-20,16)
                if v2 then
                    if c.new then c.new.Position=UDim2.fromOffset(6,6)end
                    if c.teams then c.teams.Position=UDim2.fromOffset(c.new and 6+c.newW+4 or 6,6)end
                    c.check.Position=UDim2.fromOffset(cw-12-26,6)
                else
                    if c.new then UI.box(c.new,6,6,38,18)end
                    if c.teams then UI.box(c.teams,c.new and 48 or 6,6,math.max(30,math.ceil(measure(c.teams))+12),18)end
                    UI.box(c.check,cw-12-28,6,22,18)
                end
            end
        end
    end
    for _,c in pairs(self.cards)do c.button.Visible=shown[c]==true end
    local contentHeight=math.max(0,y-GAP);UI.box(self.content,2,2,inner,contentHeight);self.grid.CanvasSize=UDim2.fromOffset(0,contentHeight+4)
    UI.box(self.empty,16,24,math.max(0,gw-32),60)
    self.rects=rects;self.viewHeight=gh;self.cardHeight=ch
    self.height=height;self.frame.Size=UDim2.fromOffset(width,height)
    self:window()
    return height
end
function M:scrollTop()return math.max(0,(self.grid.AbsolutePosition.Y-self.content.AbsolutePosition.Y)/Theme.scale)end
function M:window()
    if not self.rects then return end
    local top=self:scrollTop();local margin=self.cardHeight or 150;local bottom=top+(self.viewHeight or 0)
    local want,keep={},{}
    for i,item in ipairs(self.items)do
        local r=self.rects[i]
        local c=item.map and self.cards[item.map.key]
        if c and r.y+r.h>top-margin and r.y<bottom+margin then table.insert(want,c);keep[c]=true end
    end
    for _,c in ipairs(want)do
        if c.raster and c.drawn==false then self:enqueue(c)
        elseif not c.raster then
            local r=table.remove(self.spare)
            if not r then
                if #self.rasters<M.IMAGES then r=Raster.new(c.picture,128,72);table.insert(self.rasters,r)
                else for _,other in pairs(self.cards)do if other.raster and not keep[other]then r=other.raster;other.raster=nil;other.drawn=nil;break end end end
            end
            if r then r.parent=c.picture;r.label.Parent=c.picture;r.label.Visible=false;c.raster=r;c.drawn=false;self:enqueue(c)
                if self.v2 and r.label:IsA("ImageLabel")then K.round(r.label,6)end end
        end
    end
    self:pump()
end
function M:enqueue(c)if not c.queued then c.queued=true;table.insert(self.queue,c)end end
function M:pump()
    if self.pumping or #self.queue==0 then return end;self.pumping=true
    task.spawn(function()
        while self.alive and #self.queue>0 do
            local started=os.clock()
            repeat
                local c=table.remove(self.queue,1);c.queued=false
                if c.raster and c.drawn==false then
                    local r,map=c.raster,Maps.preview(c.key);local corner=buffer.readu8(map.terrain,0)
                    r.outside=Finish.base[bit32.band(corner,128)==0 and corner or 63];c.picture.BackgroundColor3=r.outside
                    r:setMap(map);r:fit();r:draw();r.label.Visible=true;c.drawn=true
                end
            until #self.queue==0 or os.clock()-started>.004
            task.wait()
        end
        self.pumping=false
    end)
end
function M:destroy()
    self.alive=false
    for _,c in ipairs(self.connections)do c:Disconnect()end
    for _,r in ipairs(self.rasters)do r:destroy()end
    self.frame:Destroy()
end
return M
