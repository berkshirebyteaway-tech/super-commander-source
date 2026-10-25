local UI=require(script.Parent.Theme)
local Style=require(script.Parent.HudStyle)
local Sheet=require(script.Parent.MatchSheet)
local Catalog=require(script.Parent.Parent.Core.CommsCatalog)
local Favorites=require(script.Parent.Parent.Core.EmojiFavorites)
local Vip=require(script.Parent.Parent.Core.VipComms)
local L=require(script.Parent.Localization)
local VipLock=require(script.Parent.VipLock)
local LockChip=require(script.Parent.LockChip)
local Step=require(script.Parent.TelemetryStep)
local C=UI.colors
local M={};M.__index=M
local function v2()local ok,H=pcall(require,script.Parent.Hud20);return ok and type(H)=='table'and H.ENABLED==true end
local Q20
local function q20()Q20=Q20 or require(script.Parent.QuickComms20);return Q20 end
M.RECENT=10
local TABS={{'messages','대화'},{'emoji','이모지'},{'chat','채팅'},{'motion','모션'}}
local GROUPS={{false,'전체'},{'작전 응답','응답'},{'인사','인사'},{'도움 요청','도움'},{'공격 제안','공격'},{'방어 제안','방어'},{'경고','경고'},{'작전 대화','작전'}}
local SCOPES={{'all','전체'},{'team','팀'},{'spectators','관전'}}
M.TABS=TABS;M.GROUPS=GROUPS;M.SCOPES=SCOPES
function M.new(parent,callbacks)
    local self=setmetatable({callbacks=callbacks,favorites={},mode='messages',recent={}},M)
    local f=Sheet.frame(parent,'QuickComms');self.frame=f;self.panel=parent
    self.head=Sheet.header(f,'소통',function()self:hide()end)
    self.tabs={};self.underline=UI.make('Frame',f,{Name='TabLine',BackgroundColor3=C.ink,BorderSizePixel=0,ZIndex=26})
    self.rule=UI.make('Frame',f,{Name='Rule',BackgroundColor3=Style.colors.line,BorderSizePixel=0,ZIndex=25})
    for _,t in ipairs(TABS)do
        local b=UI.button(f,'Tab_'..t[1],t[2],function()self:tab(t[1])end);b.BackgroundTransparency=1;b.TextSize=14;b.ZIndex=26;self.tabs[t[1]]=b
        local s=b:FindFirstChildOfClass('UIStroke');if s then s.Enabled=false end
    end
    local function strip(name)return UI.make('ScrollingFrame',f,{Name=name,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=0,ScrollBarImageTransparency=1,ScrollingDirection=Enum.ScrollingDirection.X,CanvasSize=UDim2.new(),ZIndex=25})end
    self.people=strip('Recipients');self.groups=strip('Groups')
    self.body=UI.make('ScrollingFrame',f,{Name='Body',BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.line,CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y,ZIndex=25})
    self.foot=UI.make('Frame',f,{Name='Footer',BackgroundTransparency=1,BorderSizePixel=0,ZIndex=25})
    return self
end
function M:hide()
    local closing=self.frame:GetAttribute('Moving20')=='out'
    if self.frame.Visible and not closing and not self.sentNow then Step.step('comms','quickClose',{item=self.mode,result='closed'})end
    self.sentNow=nil;self.subject=nil;self.editing=false;self.draft=nil;self.searching=false
    if v2()then Sheet.hide20(self.frame)else self.frame.Visible=false end
end
function M:alive(f)return f and f.id~=1 and (f.tiles or 0)>0 and not f.eliminated end
function M:open(mode,id)
    local s=self.state;if not s or s.phase=='menu'then return end
    local over=s.phase~='playing'or s.eliminated
    if over and mode~='chat'then mode='chat'end
    self.mode=mode or 'messages';self.subject=nil;self.editing=false;self.draft=nil;self.searching=false
    if id and id~=0 and self:alive(self.factions and self.factions[id])then self.targetId=id
    elseif self.mode=='emoji'then self.targetId=id==0 and 0 or self.targetId or 0 end
    if self.mode=='messages'and not self:alive(self.factions and self.factions[self.targetId])then self.targetId=self:recipients()[1]and self:recipients()[1].id or nil end
    if not self.frame.Visible or self.frame:GetAttribute('Moving20')=='out'then Step.step('comms','quickOpen',{item=self.mode,value=#self.favorites})end
    if v2()then Sheet.show20(self.frame)else self.frame.Visible=true end;self:draw()
end
function M:tab(mode)
    if mode==self.mode and not self.subject then return end
    Step.step('comms','quickTab',{item=mode})
    if mode=='messages'and self.targetId==0 then self.targetId=nil end
    self:open(mode,self.targetId)
end
function M:setFavorites(value)self.favorites=Favorites.copy(value);if self.frame.Visible and not self.editing then self:draw()end end
function M:recipients()
    local list={};for _,f in pairs(self.factions or {})do if self:alive(f)then table.insert(list,f)end end
    table.sort(list,function(a,b)return a.share==b.share and a.id<b.id or a.share>b.share end);return list
end
function M:allowed()
    local s=self.state;local f=self.factions and self.factions[self.targetId]
    return s and s.phase=='playing'and not s.paused and not s.eliminated and s.player and s.player.tiles>0
        and (self.mode=='emoji'and self.targetId==0 or self:alive(f))
end
function M:contentSignature()
    local ids={};for _,f in pairs(self.factions or {})do if self:alive(f)then table.insert(ids,f.id)end end
    table.sort(ids)
    return self.mode..','..tostring(self:allowed())..','..table.concat(ids,',')
end
function M:update(state,factions)
    local old=self.state;self.state=state;self.factions=factions
    if state.phase=='menu'or old and old.version~=state.version then self.targetId=nil;self:hide();return end
    if not self.frame.Visible or self.frame:GetAttribute('Moving20')=='out'then return end
    if (state.phase~='playing'or state.eliminated)and self.mode~='chat'then self:open('chat');return end
    if self.targetId and self.targetId~=0 and not self:alive(factions[self.targetId])then self.targetId=nil;self:draw(true);return end
    if self:contentSignature()~=self.signature then self:draw(true)end
end
function M:send(key,subject,anchor)
    local kind=self.mode=='emoji'and 'emoji'or 'quickChat'
    if not VipLock.allows(kind,kind=='emoji'and key or {key=key})then return VipLock.open(kind,false,anchor)end
    if not self:allowed()then return end
    local target=self.targetId;self.sentNow=true
    Step.step('comms','quickSend',{item=kind=='emoji'and 'emoji'or Step.code(key),reason=self.query and self.query~=''and 'manual'or 'none'})
    if kind~='emoji'then local r=self.recent;local at=table.find(r,key);if at then table.remove(r,at)end;table.insert(r,1,key);if #r>M.RECENT then table.remove(r)end end
    self:hide()
    self.callbacks.send('comms',kind,{target=target,value=kind=='emoji'and key or {key=key,target=subject}})
end
local function clear(o)for _,c in ipairs(o:GetChildren())do if not c:IsA('UIStroke')and not c:IsA('UICorner')then c:Destroy()end end end
function M:chips(strip,items,current,pick,touch)
    clear(strip);local x=0;local h=touch and 48 or 36
    for i,it in ipairs(items)do
        local text=it.text;local face=it.face
        local tw=math.ceil(game:GetService('TextService'):GetTextSize(L.text(text),13,Enum.Font.BuilderSansBold,Vector2.new(400,40)).X)
        local cw=math.max(touch and 56 or 44,tw+(face~=nil and 44 or 24))
        local b=Sheet.chip(strip,'Chip_'..(it.name or i),face~=nil and ''or text,function()pick(it)end,it.key==current or it.on,touch);UI.box(b,x,0,cw,h)
        if face~=nil then
            local pill=b.Pill;Sheet.face(pill,face,22,4,((touch and 34 or 30)-22)/2)
            local l=pill.Text;l.Text=text;l.TextXAlignment=Enum.TextXAlignment.Left;UI.box(l,30,0,cw-36,touch and 34 or 30);l:SetAttribute('LocalizationSkip',it.skip==true)
        end
        x+=cw+8
    end
    strip.CanvasSize=UDim2.fromOffset(x,0)
end
local function chip(b,text,color,x,y)
    local c=LockChip.create(b,text,color,x,y);c.ZIndex=b.ZIndex+2
    for _,o in ipairs(c:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=b.ZIndex+3 end end
    return c
end
local function cell(parent,name,text,x,y,w,h,fn,locked,mark)
    local b=UI.button(parent,name,text,fn);UI.box(b,x,y,w,h);b.TextSize=14;b.TextWrapped=true;b.TextXAlignment=Enum.TextXAlignment.Left;b.ZIndex=parent.ZIndex+1
    b.BackgroundColor3=Style.colors.chip;Style.round(b,6);Style.line(b,Style.colors.line,1)
    local cw=LockChip.width(LockChip.vip())
    UI.make('UIPadding',b,{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,locked and cw+14 or mark and 30 or 10)})
    if locked then b.TextColor3=C.muted;b.TextTransparency=.45;if w<220 then b.TextSize=12 end;b.BackgroundTransparency=.5;b:SetAttribute('VipLocked',true);chip(b,'VIP',C.vip,w-12-8-cw,(h-LockChip.height)/2)
    elseif mark then local ring=UI.make('Frame',b,{Name='Target',BackgroundTransparency=1,ZIndex=b.ZIndex+1});UI.box(ring,w-12-24,(h-14)/2,14,14);Style.round(ring,7);Style.line(ring,Sheet.SKY,1.5)
        local dot=UI.make('Frame',ring,{Name='Dot',BackgroundColor3=Sheet.SKY,BorderSizePixel=0,ZIndex=b.ZIndex+2});UI.box(dot,4,4,6,6);Style.round(dot,3)end
    return b
end
function M:draw(preserveScroll)
    if not self.r then return end
    if v2()then return q20().draw(self,preserveScroll)end
    local bodyScroll=preserveScroll and self.body.CanvasPosition
    local peopleScroll=preserveScroll and self.people.CanvasPosition
    local groupsScroll=preserveScroll and self.groups.CanvasPosition
    self.signature=self:contentSignature()
    local touch,r=self.touch,self.r;local w=r.w-32;local phone=r.phone
    local owner=self.callbacks.model
    if owner and owner.input.Parent==self.foot then owner.input.Parent=owner.frame;owner.sendButton.Parent=owner.frame end
    for _,o in ipairs({self.body,self.foot})do clear(o)end
    for _,o in ipairs(self.frame:GetChildren())do if o:GetAttribute('Transient')then o:Destroy()end end
    self.body.CanvasPosition=Vector2.zero
    self.head.title.Visible=not phone;self.head.sub.Visible=false
    local top=Sheet.placeHeader(self.head,r.w,touch)
    local tabY=phone and 2 or top-4;local tabH=touch and 48 or 40;local tabW=((phone and r.w-60 or r.w)-24)/4
    for i,t in ipairs(TABS)do
        local b=self.tabs[t[1]];UI.box(b,12+(i-1)*tabW,tabY,tabW,tabH);local on=t[1]==self.mode
        b.TextColor3=on and C.ink or C.muted;b.Font=on and Enum.Font.BuilderSansBold or Enum.Font.BuilderSansMedium
        if on then UI.box(self.underline,12+(i-1)*tabW+tabW*.22,tabY+tabH-3,tabW*.56,2)end
    end
    local y=tabY+tabH+(phone and 4 or 8);UI.box(self.rule,0,tabY+tabH,r.w,1)
    local all=self:recipients()
    self.people.Visible=false;self.groups.Visible=false
    local function chipsRow(strip,items,current,pick)
        strip.Visible=true;UI.box(strip,16,y,w,touch and 48 or 36);self:chips(strip,items,current,pick,touch);y+=(touch and 48 or 36)+6
    end
    local function people(withAll)
        local items={};if withAll then table.insert(items,{key=0,text='전체',name='All'})end
        for _,f in ipairs(all)do table.insert(items,{key=f.id,text=L.nation(f),face=f.userId or 0,name=tostring(f.id),skip=true})end
        if #items>0 then chipsRow(self.people,items,self.targetId,function(it)self.targetId=it.key;Step.step('comms','quickRecipient',{});self:draw()end)end
    end
    local footH=0
    local bw=w;local by=0;local body=self.body
    local function row(h)local yy=by;by+=h;return yy end
    if self.mode=='messages'and not self.subject and #all==0 then
        Sheet.caption(body,'NoRecipient','보낼 상대 없음',0,row(28),bw)
    end
    if self.mode=='messages'and self.subject then
        local m=self.subject
        local back=UI.button(self.frame,'SubjectBack','←',function()self.subject=nil;self:draw()end)
        back.BackgroundColor3=Style.colors.chip;Style.round(back,8);Style.line(back,Style.colors.line,1);UI.box(back,16,y,touch and 48 or 36,touch and 48 or 36);back.ZIndex=26
        back:SetAttribute('Transient',true)
        local t=UI.label(self.frame,'SubjectText',L.text(m.text),15);t.Font=Enum.Font.BuilderSansBold;t.TextWrapped=false;t.TextTruncate=Enum.TextTruncate.AtEnd;UI.box(t,16+(touch and 56 or 44),y,w-(touch and 56 or 44),touch and 48 or 36);t.ZIndex=26;t:SetAttribute('Transient',true)
        y+=(touch and 48 or 36)+6
        Sheet.caption(body,'Ask','어느 부대를 말할까요?',0,row(28),bw)
        local cw=(bw-8)/2;local ch=touch and 48 or 44
        for i,f in ipairs(self:recipients())do
            local col=(i-1)%2;local yy=by+((i-1)//2)*(ch+8)
            local b=cell(body,'Subject'..f.id,'',col*(cw+8),yy,cw,ch,function()self:send(m.key,f.id)end)
            local face=Sheet.face(b,f.userId,24,-2,(ch-24)/2);face.ZIndex=b.ZIndex+1
            local n=UI.label(b,'Name',L.nation(f),14);n.Font=Enum.Font.BuilderSansBold;n.TextWrapped=false;n.TextTruncate=Enum.TextTruncate.AtEnd;UI.box(n,30,0,cw-12-40,ch);n.ZIndex=b.ZIndex+1;n:SetAttribute('LocalizationSkip',true)
        end
        by+=math.ceil(#self:recipients()/2)*(ch+8)
    elseif self.mode=='messages'then
        local items={}
        if phone then
            local f=self.factions and self.factions[self.targetId]
            table.insert(items,{key='who',text=f and L.nation(f) or '받는 대상',face=f and (f.userId or 0)or nil,name='Recipient',skip=f~=nil,on=true})
        else people(false)end
        for _,g in ipairs(GROUPS)do table.insert(items,{key=g[1]or false,text=g[2],name=g[2]})end
        if not touch then table.insert(items,{key='search',text='검색',name='Search'})end
        local pickGroup=function(it)
            if it.key=='who'then self.picking=not self.picking
            elseif it.key=='search'then self.searching=not self.searching;self.picking=false
            else self.group=it.key or nil;self.searching=false;self.picking=false end
            self:draw()
        end
        chipsRow(self.groups,items,self.searching and 'search'or self.group or false,pickGroup)
        if self.picking then
            Sheet.caption(body,'PickTitle','받는 대상',0,row(28),bw)
            local cw=(bw-8)/2;local ch=48
            for i,f in ipairs(all)do
                local b=cell(body,'Pick'..f.id,'',(i-1)%2*(cw+8),by+((i-1)//2)*(ch+8),cw,ch,function()self.targetId=f.id;self.picking=false;self:draw()end)
                Sheet.face(b,f.userId,24,-2,(ch-24)/2).ZIndex=b.ZIndex+1
                local n=UI.label(b,'Name',L.nation(f),14);n.Font=Enum.Font.BuilderSansBold;n.TextWrapped=false;n.TextTruncate=Enum.TextTruncate.AtEnd;UI.box(n,30,0,cw-52,ch);n.ZIndex=b.ZIndex+1;n:SetAttribute('LocalizationSkip',true)
                if f.id==self.targetId then Style.line(b,C.ink,2)end
            end
            by+=math.ceil(#all/2)*(ch+8);body.CanvasSize=UDim2.fromOffset(0,by+4)
        end
        if self.searching then
            local box=UI.make('TextBox',body,{Name='Search',Text=self.query or '',PlaceholderText='문구 검색',ClearTextOnFocus=false,Font=Enum.Font.BuilderSansMedium,TextSize=14,TextColor3=C.ink,PlaceholderColor3=C.muted,BackgroundColor3=Style.colors.chip,BorderSizePixel=0,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=26})
            Style.round(box,6);Style.line(box,Style.colors.line,1);UI.make('UIPadding',box,{PaddingLeft=UDim.new(0,12)});UI.box(box,0,row(48),bw,40)
            box:GetPropertyChangedSignal('Text'):Connect(function()self.query=box.Text;task.defer(function()if self.frame.Visible and self.searching then self:phrases()end end)end)
        end
        if not self.picking then self.listTop=by;self:phrases();by=self.listBottom or by end
    elseif self.mode=='emoji'then
        people(true)
        local free=VipLock.allows('emoji','😀')
        local cols=touch and math.max(4,math.floor((bw+6)/54))or 8;local gap=touch and 6 or 6;local size=(bw-gap*(cols-1))/cols;local ch=touch and math.max(48,size)or math.min(44,size)
        local function grid(list,prefix,favSlots)
            local n=math.max(#list,favSlots or 0)
            for i=1,n do
                local e=list[i];local x=(i-1)%cols*(size+gap);local yy=by+((i-1)//cols)*(ch+gap)
                if e then
                    local locked=not VipLock.allows('emoji',e)
                    local b=UI.button(body,prefix..i,e,function()end);UI.box(b,x,yy,size,ch);b.TextSize=22;b.ZIndex=26;b.BackgroundColor3=Style.colors.chip;Style.round(b,8)
                    local picked=self.editing and table.find(self.draft or {},e)~=nil
                    Style.line(b,picked and C.ink or Style.colors.line,picked and 2 or 1)
                    if locked and not self.editing then b.TextTransparency=.7;b.BackgroundTransparency=.5;b:SetAttribute('VipLocked',true)end
                    b:SetAttribute('Send',not self.editing)
                    b.Activated:Connect(function()
                        if self.editing then self.draft=Favorites.toggle(self.draft,e)or self.draft;self:draw()else self:send(e,nil,b)end
                    end)
                else
                    local slot=UI.make('Frame',body,{Name=prefix..'Empty'..i,BackgroundTransparency=1,ZIndex=26});UI.box(slot,x,yy,size,ch);Style.round(slot,8);Style.line(slot,Style.colors.line,1,.2)
                end
            end
            by+=math.ceil(n/cols)*(ch+gap)+6
        end
        local favs=self.editing and self.draft or self.favorites
        local none=#favs==0 and not self.editing
        local tight=phone and none
        Sheet.caption(body,'FavTitle','즐겨찾기',0,by,bw-80).Visible=not tight
        local edit=UI.button(body,'EditFavorites',self.saving and '저장 중…'or self.editing and '저장'or '편집',function()
            if self.saving then return end
            if not self.editing then self.draft=Favorites.copy(self.favorites);self.editing=true;self:draw();return end
            self.saving=true;local draft=self.draft;self:draw()
            self.callbacks.save(Favorites.copy(draft),function(ok)
                self.saving=false;Step.step('comms','favSave',{result=ok and 'ok'or 'failed',count=#draft})
                if ok and self.draft==draft then self.editing=false;self.draft=nil end
                if self.frame.Visible then self:draw()end
            end)
        end)
        edit.BackgroundTransparency=1;edit.TextColor3=Sheet.SKY;edit.TextSize=14;edit.TextXAlignment=Enum.TextXAlignment.Right;UI.box(edit,bw-80,by-(touch and 13 or 6),80,touch and 48 or 34);edit.ZIndex=26
        local s=edit:FindFirstChildOfClass('UIStroke');if s then s.Enabled=false end
        if tight then
            local n=#Vip.freeEmojis;edit.TextXAlignment=Enum.TextXAlignment.Center;edit.BackgroundTransparency=0;edit.BackgroundColor3=Style.colors.chip;Style.round(edit,8)
            UI.box(edit,n%cols*(size+gap),by+(n//cols)*(ch+gap),size,ch);grid(Vip.freeEmojis,'Free')
            if n%cols==0 then by+=ch+gap end
        else
            by+=touch and 38 or 28
            if not none then grid(favs,'Fav',touch and 0 or 8)end
            Sheet.caption(body,'FreeTitle','외교',0,row(28),bw);grid(Vip.freeEmojis,'Free')
        end
        Sheet.caption(body,'AllTitle','전체',0,by,60)
        if not free then
            local c=LockChip.create(body,'VIP',C.vip,40,by+1);c.ZIndex=26;for _,o in ipairs(c:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=27 end end
        end
        by+=touch and 38 or 28
        local rest={};for _,e in ipairs(Catalog.emojis)do if not Vip.freeEmoji(e)then table.insert(rest,e)end end
        grid(rest,'Emoji')
    elseif self.mode=='chat'then
        local model=self.callbacks.model;local seg=UI.make('Frame',self.frame,{Name='Scopes',BackgroundColor3=Style.colors.chip,BorderSizePixel=0,ZIndex=26});seg:SetAttribute('Transient',true)
        local shown={};for _,sc in ipairs(SCOPES)do if model:channelName(sc[1])~=nil then table.insert(shown,sc)end end
        if #shown==0 then shown={SCOPES[1]}end
        local sh=touch and 48 or 34;local sw=math.min(80*#shown,bw);UI.box(seg,16,y,sw,sh+4);Style.round(seg,8);Style.line(seg,Style.colors.line,1);y+=sh+12
        for i,sc in ipairs(shown)do
            local on=model.scope==sc[1]
            local b=UI.button(seg,'Scope_'..sc[1],sc[2],function()model.scope=sc[1];Step.step('comms','chatScope',{item=sc[1]});self:draw()end);UI.box(b,2+(i-1)*(sw-4)/#shown,2,(sw-4)/#shown-2,sh);b.TextSize=14;b.ZIndex=27;Style.round(b,6)
            b.BackgroundColor3=on and Style.colors.cell:Lerp(C.ink,.12)or Style.colors.chip;b.BackgroundTransparency=on and 0 or 1;b.TextColor3=on and C.ink or C.muted
            local st=b:FindFirstChildOfClass('UIStroke');if st then st.Enabled=false end
        end
        local lines={};for _,h in ipairs(model.history)do if h.scope==model.scope or h.scope=='player'or h.scope=='allies'then table.insert(lines,h)end end
        local rowH=phone and 30 or 44
        for i,h in ipairs(lines)do
            local yy=row(rowH+4)
            Sheet.face(body,h.userId,24,0,yy+(phone and 3 or 2))
            local n=UI.label(body,'Name'..i,h.me and '나'or h.name,13,h.me and C.accent or Sheet.SKY);n.Font=Enum.Font.BuilderSansBold;n.TextWrapped=false;n.ZIndex=26;n:SetAttribute('LocalizationSkip',not h.me)
            local tw=math.min(n.TextBounds.X+2,bw*.45);UI.box(n,34,yy,tw,phone and rowH or 20)
            local x=38+tw
            if h.tag then local tag=UI.label(body,'Tag'..i,h.tag,12,C.muted);tag.TextXAlignment=Enum.TextXAlignment.Center;tag.TextWrapped=false;tag.BackgroundColor3=Style.colors.chip;tag.BackgroundTransparency=0;Style.round(tag,9);Style.line(tag,Style.colors.line,1);tag.ZIndex=26
                local gw=math.max(54,tag.TextBounds.X+16);UI.box(tag,x,yy+(phone and (rowH-20)/2 or 1),gw,20);x+=gw+6 end
            local t=UI.label(body,'Text'..i,h.text,13,C.ink);t.TextWrapped=false;t.TextTruncate=Enum.TextTruncate.AtEnd;t.ZIndex=26;t:SetAttribute('LocalizationSkip',h.tag==nil)
            if phone then UI.box(t,x,yy,bw-x,rowH)else UI.box(t,34,yy+20,bw-34,22)end
        end
        if #lines==0 then Sheet.caption(body,'Empty','대화 없음',0,row(28),bw)end
        local ih=touch and 48 or 44;footH=ih+8
        if VipLock.allows('text')then
            local input,go=model.input,model.sendButton
            input.Parent=self.foot;input.ZIndex=26;input.BackgroundColor3=Style.colors.chip;Style.round(input,8);Style.line(input,Style.colors.line,1);UI.box(input,0,4,w-ih-8,ih);input.PlaceholderText='메시지 입력'
            if not input:FindFirstChildOfClass('UIPadding')then UI.make('UIPadding',input,{PaddingLeft=UDim.new(0,12)})end;input.TextXAlignment=Enum.TextXAlignment.Left
            go.Parent=self.foot;go.ZIndex=26;Style.round(go,8);UI.box(go,w-ih,4,ih,ih);go.TextSize=20
        else
            local m=model;if m.input.Parent==self.foot then m.input.Parent=m.frame;m.sendButton.Parent=m.frame end
            Sheet.banner(self.foot,'VipText','채팅 입력은 VIP',4,w,ih)
        end
        task.defer(function()if self.body.Parent then self.body.CanvasPosition=Vector2.new(0,math.max(0,self.body.CanvasSize.Y.Offset-self.body.AbsoluteSize.Y/UI.scale))end end)
    else
        local Career=require(script.Parent.Parent.Core.CareerRules);local Loadout=require(script.Parent.Parent.Core.MotionLoadout)
        local Motions=require(script.Parent.MotionsPage);local Icons=require(script.Parent.OutgameIcons)
        local a=self.callbacks.account and self.callbacks.account()or {};local level=(a.progress or {}).level or 1
        local club=VipLock.allows('motion')
        if not club then Sheet.banner(body,'VipMotion','모션은 VIP',row(touch and 56 or 48),bw,40)end
        local slots={};for _,id in ipairs(Loadout.copy((a.preferences or {}).motionLoadout,level))do table.insert(slots,{m=Loadout.find(id)})end
        for _,m in ipairs(Career.motions)do if m.level>level and #slots<6 then table.insert(slots,{m=m,locked=true})end end
        while #slots<6 do table.insert(slots,{})end
        local gap=8;local cw=(bw-gap*2)/3;local ch=phone and 64 or 116
        for i,sl in ipairs(slots)do
            local x=(i-1)%3*(cw+gap);local yy=by+((i-1)//3)*(ch+gap);local m=sl.m
            local b=UI.button(body,'Motion'..i,'',function()
                if not m or sl.locked then return end
                if not club then return VipLock.open('motion',false,self.lastCell)end
                Step.step('character','motionWheel',{item=Step.code(m.id),value=i});Motions.play(m);self:hide()
            end);UI.box(b,x,yy,cw,ch);b.ZIndex=26;b.BackgroundColor3=Style.colors.chip;Style.round(b,8)
            b.InputBegan:Connect(function()self.lastCell=b end)
            local empty=not m or sl.locked;Style.line(b,Style.colors.line,1,empty and .2 or 0);if empty then b.BackgroundTransparency=1 end
            local is=phone and 22 or 34
            local lock=sl.locked and {LockChip.level(m.level)}or m and not club and {LockChip.vip()}
            local icon=not sl.locked and m and Icons.create(b,Motions.icons[m.id]or 'reward',is,club and C.ink or C.muted)
            local label=UI.label(b,'Name',m and m.name or '비어 있음',13,(m and club and not sl.locked)and C.ink or C.muted)
            label.TextXAlignment=Enum.TextXAlignment.Center;label.TextWrapped=false;label.TextTruncate=Enum.TextTruncate.AtEnd;label.ZIndex=27;label.Font=Enum.Font.BuilderSansBold
            if lock then local lw=LockChip.width(lock[1]);chip(b,lock[1],lock[2],(cw-lw)/2,phone and 6 or (ch-LockChip.height)/2-14)end
            if icon then icon.ZIndex=27;icon.Visible=club;UI.box(icon,(cw-is)/2,phone and 6 or (ch-is)/2-14,is,is)
            elseif not lock then local plus=UI.label(b,'Plus','+',20,C.muted);plus.TextXAlignment=Enum.TextXAlignment.Center;plus.ZIndex=27;UI.box(plus,0,phone and 2 or ch/2-30,cw,28)end
            UI.box(label,6,phone and ch-28 or ch-34,cw-12,22)
        end
        by+=2*(ch+gap)
    end
    local model=self.callbacks.model
    if self.mode~='chat'and model and model.input.Parent==self.foot then model.input.Parent=model.frame;model.sendButton.Parent=model.frame end
    UI.box(self.foot,16,r.h-8-footH,w,footH)
    UI.box(self.body,16,y,w+6,r.h-y-10-footH)
    if self.mode~='messages'or self.subject then body.CanvasSize=UDim2.fromOffset(0,by+4)end
    if bodyScroll and self.mode~='chat'then self.body.CanvasPosition=bodyScroll end
    if peopleScroll then self.people.CanvasPosition=peopleScroll end
    if groupsScroll then self.groups.CanvasPosition=groupsScroll end
    if self.state then for _,b in ipairs(body:GetDescendants())do if b:IsA('GuiButton')and b:GetAttribute('Send')and not b:GetAttribute('VipLocked')then UI.enabled(b,self:allowed()==true)end end end
end
function M:phrases()
    if v2()then return q20().phrases(self)end
    local body=self.body;local w=self.r.w-32;local touch=self.touch
    for _,o in ipairs(body:GetChildren())do if o:GetAttribute('Phrase')then o:Destroy()end end
    local by=self.listTop or 0;local q=self.query and self.searching and self.query:lower():gsub('^%s+',''):gsub('%s+$','')or ''
    local cw=(w-8)/2;local ch=touch and 48 or 44;local can=self:allowed()==true
    local function caption(text)local l=Sheet.caption(body,'Caption'..by,text,0,by,w);l:SetAttribute('Phrase',true);by+=26 end
    local function list(items,prefix)
        for i,m in ipairs(items)do
            local col=(i-1)%2;local yy=by+((i-1)//2)*(ch+8)
            local locked=not VipLock.allows('quickChat',{key=m.key})
            local b;b=cell(body,prefix..m.key,L.text(m.text),col*(cw+8),yy,cw,ch,function()
                if locked then return VipLock.open('quickChat',false,b)end
                if not can then return end
                if m.requiresTarget then self.subject=m;Step.step('comms','quickSubject',{item=Step.code(m.key)});self:draw()else self:send(m.key,nil,b)end
            end,locked,m.requiresTarget);b:SetAttribute('Phrase',true);b:SetAttribute('Send',true);b:SetAttribute('LocalizationSkip',true)
            if not locked then UI.enabled(b,can)end
        end
        by+=math.ceil(#items/2)*(ch+8)
    end
    local recent={};for _,key in ipairs(self.recent)do for _,m in ipairs(Catalog.messages)do if m.key==key then table.insert(recent,m)end end end
    if q==''and #recent>0 and not self.group then caption('최근 보낸 문구');list(recent,'Recent_');caption('모든 문구')end
    local found={};for _,m in ipairs(Catalog.messages)do if (not self.group or m.group==self.group)and (q==''or m.text:lower():find(q,1,true)or L.text(m.text):lower():find(q,1,true))then table.insert(found,m)end end
    if VipLock.allows('quickChat')then list(found,'Message_')
    else
        local free,rest={},{};for _,m in ipairs(found)do table.insert(Vip.freePhrases[m.key]and free or rest,m)end
        list(free,'Message_')
        local b=Sheet.banner(body,'VipQuickChat','빠른 대화는 VIP',by,w,40);b:SetAttribute('Phrase',true);by+=48
        list(rest,'Message_')
    end
    if #found==0 then caption('결과 없음');Step.change('quickSearch','comms','quickSearchEmpty',{result='unavailable'})end
    self.listBottom=by;body.CanvasSize=UDim2.fromOffset(0,by+4)
end
function M:layout(w,h)
    if v2()then return q20().layout(self,w,h)end
    local touch=Sheet.touch();self.controls=self.controls or self.panel:FindFirstChild('Controls')
    local r=Sheet.rect(w,h,touch,self.controls and self.controls.Visible and self.controls.Position.Y.Offset or nil)
    UI.box(self.frame,r.x,r.y,r.w,r.h)
    local changed=not self.r or self.r.w~=r.w or self.r.h~=r.h or self.touch~=touch
    self.r=r;self.touch=touch
    if changed and self.frame.Visible then self:draw(true)end
end
return M
