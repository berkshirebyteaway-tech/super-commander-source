local UI=require(script.Parent.ToyUI)
local Theme=require(script.Parent.Theme)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local Highlights=require(script.Parent.Parent.Core.LobbyHighlights)
local PartyPlay=require(script.Parent.Parent.Core.PartyPlay)
local TeamFormat=require(script.Parent.Parent.Core.TeamFormat)
local L=require(script.Parent.Localization)
local Raster=require(script.Parent.RasterMap)
local Chips=require(script.Parent.TagChips)
local M={};M.__index=M
local order={'ffa','teams','custom'}
local names={ffa='공식 개인전',teams='공식 팀전',custom='커스텀'}
local colors={ffa=Color3.fromRGB(59,130,246),teams=Color3.fromRGB(139,92,246),custom=UI.colors.ice}
local function label(p,name,text,size,c)local o=UI.label(p,name,text,size,c);o.TextWrapped=false;o.TextTruncate=Enum.TextTruncate.AtEnd;return o end
local function customEntry(lobby)
    local party=lobby.data and lobby.data.party
    if party and #party.users>1 then
        if party.leader~=game.Players.LocalPlayer.UserId then if lobby.notify then lobby.notify('커스텀 방은 파티장이 만들어요',false)end else lobby.deployment.callbacks.partyCoop(false)end
    else lobby.deployment.callbacks.create()end
end
function M:paint(c,size)
    if size and c.dimensions==size then return end
    c.dimensions=size or c.dimensions
    if c.painting then return end;c.painting=true
    task.defer(function()
        c.painting=false
        if not c.map then return end
        if not(self.frame.Visible and self.lobby.frame.Visible and self.lobby.inMenu~=false)then c.dimensions=nil;return end
        c.raster:fit();c.raster:draw()
    end)
end
function M.new(lobby)
    local self=setmetatable({lobby=lobby,cards={}},M)
    self.frame=UI.make('ScrollingFrame',lobby.frame,{Name='LobbyFieldPreview',Active=true,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=UI.colors.line,ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.fromOffset(0,0)})
    for _,key in ipairs(order)do
        local c={};c.frame=UI.panel(self.frame,key);c.frame.BackgroundTransparency=.08
        c.strip=UI.make('Frame',c.frame,{Name='Strip',BorderSizePixel=0,BackgroundColor3=colors[key]})
        c.type=label(c.frame,'Type',names[key],14,colors[key]);c.type.Visible=false
        c.chips=UI.make('Frame',c.frame,{Name='Tags',BackgroundTransparency=1})
        c.count=label(c.frame,'Count','',14,UI.colors.ink);c.count.Font=Enum.Font.BuilderSansBold
        c.picture=UI.button(c.frame,'Map','',function()
            if c.field then lobby.deployment:open(c.field.kind,c.field.id);lobby:layout()
            elseif key=='custom'then customEntry(lobby)end
        end);c.picture.BackgroundColor3=UI.colors.ocean;c.picture.ClipsDescendants=true
        c.raster=Raster.new(c.picture,224,64)
        c.emptyIcon=label(c.picture,'EmptyIcon','+',32,UI.colors.muted);c.emptyIcon.Size=UDim2.fromScale(1,1);c.emptyIcon.TextXAlignment=Enum.TextXAlignment.Center
        c.title=label(c.frame,'Title','',18,UI.colors.ink);Theme.display(c.title)
        c.state=label(c.frame,'State','',14,UI.colors.muted)
        c.join=UI.button(c.frame,'Join','참가',function()
            local d=lobby.deployment
            if c.field then d:join(c.field.id)
            elseif key=='custom'then customEntry(lobby)
            else d:open('official');lobby:layout()end
        end);c.join.TextSize=14
        self.cards[key]=c
    end
    self.more=UI.button(self.frame,'More','전장 목록 보기',function()lobby.deployment:open('all');lobby:layout()end)
    self.solo=UI.button(self.frame,'Solo','혼자 하기',function()lobby.deployment.callbacks.solo()end)
    self.ranked=UI.button(self.frame,'Ranked','랭크전',function()lobby:openPage('ranked')end)
    self.friends=UI.button(self.frame,'Friends','파티',function()lobby:openPage('friends')end)
    return self
end
function M:refresh()
    local l=self.lobby;local d=l.deployment;if not d then return end
    local party=l.data and l.data.party;local own=l.data and l.data.queue and l.data.queue.field;local grouped=party and #party.users>1
    local selected=Highlights.select(d.fields,party,own);local elapsed=os.clock()-(d.updated or os.clock())
    local count=PartyPlay.available(d.fields,party,own)
    self.more.Text=d.directoryError and '전장 목록 보기'or grouped and string.format('함께 입장할 전장 (%d)',count)or string.format('전장 목록 (%d)',count)
    self.friends.Text=grouped and string.format('파티 %d/5',#party.users)or '파티'
    for _,key in ipairs(order)do local c=self.cards[key];local f=selected[key];c.field=f
        if f then require(script.Parent.TelemetryClient).card(c.frame,f,key=='ffa'and 1 or key=='teams'and 2 or 3,'home')end
        c.tags=f and Chips.tags(f)or Chips.tags({kind=key=='custom'and 'custom'or 'official',rules={mode=key}});Chips.render(c.chips,c.tags,c.chipW or 200,20)
        c.picture.Visible=true;c.raster.label.Visible=f~=nil;c.emptyIcon.Visible=f==nil;c.emptyIcon.Text=key=='custom'and '+'or '…'
        c.title.Text=f and ((Maps.meta(f.rules.map)or {}).label or f.rules.map)or key=='custom'and (grouped and '함께 협동'or '내 규칙으로 플레이')or '다른 전장 살펴보기'
        c.count.Text=f and string.format('%d/%d명',f.count,f.rules.maximum)or ''
        c.state.Text=f and (grouped and f.rules.mode=='ffa'and '같은 경기, 각자 경쟁'or f.remaining and string.format('%d초 후 출발',math.max(0,math.ceil(f.remaining-elapsed)))or '모집 중')or key=='custom'and '열린 방이 없어요'or grouped and '파티가 들어갈 전장 없음'or '모집 중인 전장 없음'
        c.state.TextColor3=f and f.remaining and UI.colors.accent or UI.colors.muted;if c.place then c.place()end
        c.join.Text=f and (l.data and l.data.queue and l.data.queue.field==f.id and (f.kind=='custom'and '방 보기'or '참가 중')or '참가')or key=='custom'and '+ 만들기'or '목록 보기'
        if not f and key=='custom'and grouped then c.join.Text=party.leader==game.Players.LocalPlayer.UserId and '협동 준비'or '준비'end
        UI.enabled(c.join,not l.busy and not l.loading and not d.directoryError)
        if f and c.map~=f.rules.map then c.map=f.rules.map;c.raster:setPreview(Maps.preview(c.map));self:paint(c)end
    end
end
function M:layoutRows(x,y,w,rowH,visible)
    self.frame.Visible=visible;self.rows=true;if not visible then return 0 end
    local gap=8;local total=#order*rowH+(#order-1)*gap
    UI.box(self.frame,x,y,w,total);self.frame.CanvasSize=UDim2.fromOffset(0,total);self.frame.ScrollingEnabled=false
    for _,b in ipairs({self.more,self.solo,self.ranked,self.friends})do b.Visible=false end
    self.selected=self.selected or 'ffa'
    local pw,ph=rowH>=56 and 72 or 52,rowH>=56 and 44 or 38
    for i,key in ipairs(order)do local c=self.cards[key]
        UI.box(c.frame,0,(i-1)*(rowH+gap),w,rowH);UI.box(c.strip,0,0,4,rowH)
        UI.box(c.picture,12,(rowH-ph)/2,pw,ph);c.picture.Active=false;c.picture:SetAttribute('AllowOverlap',true)
        local tx=12+pw+12
        c.chipW=w-tx-60;UI.box(c.chips,tx,rowH>=56 and 6 or 3,c.chipW,20)
        UI.box(c.title,tx,rowH>=56 and 28 or 22,math.min(170,w-tx-60),rowH>=56 and 26 or 22);c.title.TextSize=rowH>=56 and 16 or 14
        c.row={x=tx+math.min(170,w-tx-60)+6,y=rowH>=56 and 30 or 23,w=w-tx-math.min(170,w-tx-60)-60,h=22};c.state.TextSize=13
        c.place=function()
            local r=c.row;local w1=c.count.Text~=''and math.min(r.w*.5,game:GetService('TextService'):GetTextSize(L.text(c.count.Text),13,Enum.Font.BuilderSansBold,Vector2.new(1000,r.h)).X+2)or 0
            UI.box(c.count,r.x,r.y,w1,r.h);c.count.TextSize=13;UI.box(c.state,r.x+(w1>0 and w1+6 or 0),r.y,r.w-(w1>0 and w1+6 or 0),r.h)
        end;c.place()
        c.join.Visible=false
        if not c.pick then
            c.pick=UI.make('TextButton',c.frame,{Name='Pick',Text='',BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Size=UDim2.fromScale(1,1),ZIndex=c.frame.ZIndex+4})
            c.pick.Activated:Connect(function()require(script.Parent.ToyAudio).play('click');self:ask(key)end)
            c.check=UI.label(c.frame,'Check','✓',22,UI.colors.ink);c.check.TextXAlignment=Enum.TextXAlignment.Center;c.check:SetAttribute('LocalizationSkip',true)
            c.edge=c.frame:FindFirstChildOfClass('UIStroke')
        end
        c.pick.Visible=true;UI.box(c.check,w-44,0,36,rowH)
        if c.tags then Chips.render(c.chips,c.tags,c.chipW,20)end
        self:paint(c,'rows:'..w)
    end
    self:paintRows()
    return total
end
function M:paintRows()
    if not self.rows then return end
    for _,key in ipairs(order)do local c=self.cards[key];if c.edge then
        c.edge.Color=UI.colors.line;c.edge.Thickness=1;c.check.Visible=true;c.check.Text='›';c.check.TextColor3=UI.colors.muted
        c.frame.BackgroundColor3=colors[key]:Lerp(UI.colors.panel,.82);c.frame.BackgroundTransparency=.04
    end end
end
function M:ask(key)
    local l=self.lobby;local d=l.deployment;local c=self.cards[key];local f=c.field
    if not f then
        if key=='custom'then customEntry(l)else d:open('official');l:layout()end
        return
    end
    local mapName=(Maps.meta(f.rules.map)or {}).label or f.rules.map
    local elapsed=os.clock()-(d.updated or os.clock())
    local when=f.remaining and string.format('%d초 후 출발',math.max(0,math.ceil(f.remaining-elapsed)))or '모집 중'
    local mode=f.kind=='custom'and '커스텀'or f.rules.mode=='teams'and '공식 팀전'or '공식 개인전'
    require(script.Parent.LobbyConfirm).open(l,mode,string.format('%s  %d/%d명  %s\n빈자리는 AI 지휘관이 채워요. 참가할까요?',mapName,f.count,f.rules.maximum,when),'참가',function()d:join(f.id);l:closePage();l:layout()end,nil,f.rules.map)
end
function M:joinSelected()return false end
function M:leaveRows()
    if not self.rows then return end;self.rows=nil;self.frame.ScrollingEnabled=true
    for _,key in ipairs(order)do local c=self.cards[key];if c.pick then c.pick.Visible=false;c.check.Visible=false;c.picture.Active=true;c.picture:SetAttribute('AllowOverlap',nil);c.join.Visible=true;if c.edge then c.edge.Color=UI.colors.line;c.edge.Thickness=1 end end end
end
function M:layout(x,y,w,visible,portrait,short,maxHeight)
    self:leaveRows()
    self.frame.Visible=visible;if not visible then return end
    local ch=portrait and 92 or short and 140 or 170;local gap=8;local cols=portrait and 1 or 3;local cw=(w-gap*(cols-1))/cols
    local rows=portrait and 3 or 1;local bottom=rows*ch+(rows-1)*gap
    UI.box(self.frame,x,y,w,math.min(bottom+52,maxHeight or math.huge));self.frame.CanvasSize=UDim2.fromOffset(0,bottom+52)
    for i,key in ipairs(order)do local c=self.cards[key];UI.box(c.frame,(i-1)%cols*(cw+gap),(i-1)//cols*(ch+gap),cw,ch);UI.box(c.strip,0,0,cw,2)
        if portrait then
            UI.box(c.type,12,6,cw-112,20);c.chipW=cw-112;UI.box(c.chips,12,6,cw-112,20);UI.box(c.picture,12,30,76,52)
            local tx=98;UI.box(c.title,tx,30,cw-tx-100,24);UI.box(c.join,cw-92,36,80,44)
            c.row={x=tx,y=56,w=cw-tx-100,h=22}
        else
            UI.box(c.type,12,6,cw-24,20);c.chipW=cw-24;UI.box(c.chips,12,6,cw-24,20);UI.box(c.picture,12,short and 28 or 32,cw-24,short and 56 or 64)
            UI.box(c.title,12,short and 86 or 98,short and cw-108 or cw-24,short and 22 or 26);c.title.TextSize=short and 14 or 18
            c.row={x=12,y=short and 108 or ch-42,w=cw-108,h=short and 24 or 32};c.state.TextSize=14;c.state.TextWrapped=false
            UI.box(c.join,cw-88,ch-48,76,44)
        end
        UI.box(c.join,c.join.Position.X.Offset,c.join.Position.Y.Offset,c.join.Size.X.Offset,44)
        c.place=function()
            local r=c.row;if not r then return end
            local w1=c.count.Text~=''and math.min(r.w*.45,game:GetService('TextService'):GetTextSize(L.text(c.count.Text),14,Enum.Font.BuilderSansBold,Vector2.new(1000,r.h)).X+2)or 0;local x2=w1>0 and w1+8 or 0
            UI.box(c.count,r.x,r.y,w1,r.h);UI.box(c.state,r.x+x2,r.y,r.w-x2,r.h)
        end;c.place()
        if c.tags then Chips.render(c.chips,c.tags,c.chipW,20)end
        self:paint(c,'grid:'..cw)
    end
    local grouped=short and not portrait;self.friends.Visible=grouped
    local mw=math.floor(w*(grouped and .4 or .48));local sw=math.floor((w-mw-(grouped and 24 or 16))/(grouped and 3 or 2))
    UI.box(self.more,0,bottom+8,mw,44);UI.box(self.solo,mw+8,bottom+8,sw,44);UI.box(self.ranked,mw+16+sw,bottom+8,sw,44)
    if grouped then UI.box(self.friends,mw+24+sw*2,bottom+8,w-mw-24-sw*2,44)end
end
return M
