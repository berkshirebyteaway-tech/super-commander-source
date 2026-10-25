local K=require(script.Parent.Kit20)
local Sheet=require(script.Parent.MatchSheet)
local Catalog=require(script.Parent.Parent.Core.CommsCatalog)
local Favorites=require(script.Parent.Parent.Core.EmojiFavorites)
local Vip=require(script.Parent.Parent.Core.VipComms)
local L=require(script.Parent.Localization)
local VipLock=require(script.Parent.VipLock)
local Step=require(script.Parent.TelemetryStep)
local Tween=game:GetService('TweenService')
local C=K.colors
local M={}
local TOP=97

local function clear(o)for _,c in ipairs(o:GetChildren())do if not(c:IsA('UIPadding')or c:IsA('UICorner')or c:IsA('UIStroke')or c:IsA('UIGradient'))then c:Destroy()end end end
local function z(o,n)o.ZIndex=n;return o end
local function parts(self)
    if self.v20 then return self.v20 end
    local f=self.frame;local v={tabs={}};self.v20=v
    Sheet.head20(f,function()self:hide()end)
    for _,t in ipairs(self.TABS)do
        local b=K.make('TextButton',f,{Name='Tab20_'..t[1],Text='',AutoButtonColor=false,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=f.ZIndex+3})
        local l=z(K.text(b,'Label',t[2],14,C.muted,600,Enum.TextXAlignment.Center),b.ZIndex+1);l.Size=UDim2.fromScale(1,1)
        b.Activated:Connect(function()if t[1]~=self.mode or self.subject then require(script.Parent.ToyAudio).play('click')end;self:tab(t[1])end)
        v.tabs[t[1]]={button=b,label=l}
    end
    v.line=K.make('Frame',f,{Name='TabLine20',BackgroundColor3=C.accent,BorderSizePixel=0,ZIndex=f.ZIndex+4});K.round(v.line,2)
    for _,s in ipairs({self.people,self.groups})do s.ScrollBarThickness=0;s.ScrollingDirection=Enum.ScrollingDirection.X;s.BackgroundTransparency=1 end
    self.body.ScrollBarThickness=2;self.body.ScrollBarImageColor3=C.line;K.scrollPad(self.body,2)
    return v
end
local function head(self,v,r)
    local f=self.frame
    for _,o in ipairs({self.head.title,self.head.sub,self.head.close,self.underline,self.rule})do o.Visible=false end
    for _,b in pairs(self.tabs)do b.Visible=false end
    Sheet.placeHead20(f,r.w)
    local pad=r.fmt=='ph'and 8 or 10;local x=7
    for _,t in ipairs(self.TABS)do
        local tb=v.tabs[t[1]];local on=t[1]==self.mode
        local bw=K.width(L.text(t[2]),14,tb.label)+pad*2;K.box(tb.button,x,1,bw,47)
        tb.label.TextColor3=on and C.ink or C.muted;if K.fonts[on and 800 or 600]then tb.label.FontFace=K.fonts[on and 800 or 600]end
        if on then
            local goal=UDim2.fromOffset(x+8,45);v.line.Size=UDim2.fromOffset(bw-16,3)
            if v.lineMode and v.lineMode~=t[1]and not K.reduced then Tween:Create(v.line,TweenInfo.new(.16,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut),{Position=goal}):Play()else v.line.Position=goal end
            v.lineMode=t[1]
        end
        x+=bw
    end
end
local function pills(strip,items,current,pick)
    clear(strip);local x=0
    for i,it in ipairs(items)do
        local b,w=Sheet.chip20(strip,'Chip_'..(it.name or i),it.text,it.key==current or it.on==true,it.pad or 10,function()pick(it)end,it.skip)
        b:place(x,5,w,30);Sheet.fill20(b);b.button.ZIndex=strip.ZIndex+1
        x+=w+6
    end
    strip.CanvasSize=UDim2.fromOffset(math.max(0,x-6),0)
end
local function title(parent,name,text,y,lock,attr)
    local l=K.text(parent,name,text,12,C.muted,800);K.box(l,0,y+8,K.width(L.text(text),12,l)+4,20);l.ZIndex=parent.ZIndex+1
    if attr then l:SetAttribute(attr,true)end
    local chip
    if lock then chip=K.lock(parent,'VIP',l.Position.X.Offset+l.Size.X.Offset+4,y+8,11);chip.Name=name..'Vip';chip.ZIndex=parent.ZIndex+1;if attr then chip:SetAttribute(attr,true)end end
    return l,chip
end
local function cell(parent,name,text,x,y,w,h,locked,mark,fn,size)
    if locked then
        local b=K.make('TextButton',parent,{Name=name,Text='',AutoButtonColor=false,BackgroundColor3=C.raised,BackgroundTransparency=.5,BorderSizePixel=0,ZIndex=parent.ZIndex+1})
        K.round(b,8);K.box(b,x,y,w,h);b:SetAttribute('VipLocked',true)
        local l=K.text(b,'Label',text,size or 12,C.ink,700);l.TextTransparency=.55;l.ZIndex=b.ZIndex+1;K.box(l,10,0,w-20,h)
        b.Activated:Connect(fn);return {button=b,label=l,locked=true}
    end
    local b=K.button(parent,name,{kind='none',text=text,size=size or 13,weight=700},fn)
    b.face.BackgroundTransparency=0;b.face.BackgroundColor3=C.raised
    b:place(x,y,w,h);Sheet.fill20(b,10);b.button.ZIndex=parent.ZIndex+1
    if mark then
        b.label.Size=UDim2.new(1,-44,1,0)
        local ring=K.make('Frame',b.face,{Name='Target',BackgroundTransparency=1,BorderSizePixel=0,ZIndex=b.face.ZIndex+1});K.box(ring,w-10-14,(h-14)/2,14,14);K.round(ring,'pill');K.stroke(ring,C.accent,1.5,0,true)
        local dot=K.make('Frame',ring,{Name='Dot',BackgroundColor3=C.accent,BorderSizePixel=0,ZIndex=ring.ZIndex+1});K.box(dot,4,4,6,6);K.round(dot,'pill')
    end
    return b
end

function M.layout(self,w,h)
    local r=Sheet.rect20(w,h,false);local touch=Sheet.touch()
    Sheet.paint20(self.frame,r.portrait);Sheet.place20(self.frame,r);Sheet.motion20(self.frame)
    local changed=not self.r or self.r.w~=r.w or self.r.h~=r.h or self.touch~=touch or self.r.fmt~=r.fmt
    self.r=r;self.touch=touch
    if changed and self.frame.Visible then self:draw(true)end
end

function M.draw(self,preserveScroll)
    local r=self.r;if not r or Sheet.closing(self.frame)then return end
    local v=parts(self)
    local bodyScroll=preserveScroll and self.body.CanvasPosition
    local peopleScroll=preserveScroll and self.people.CanvasPosition
    local groupsScroll=preserveScroll and self.groups.CanvasPosition
    self.signature=self:contentSignature()
    local owner=self.callbacks.model
    local function giveBack()
        if not(owner and owner.input.Parent==self.foot)then return end
        K.fade(owner.input,true,0);K.fade(owner.sendButton,true,0)
        owner.input.Parent=owner.frame;owner.sendButton.Parent=owner.frame
    end
    giveBack()
    self.groups.Parent=self.frame
    for _,o in ipairs({self.body,self.foot,self.people,self.groups})do clear(o)end
    for _,o in ipairs(self.frame:GetChildren())do if o:GetAttribute('Transient')then o:Destroy()end end
    self.body.CanvasPosition=Vector2.zero
    head(self,v,r)
    local cw=r.w-26;local touch=self.touch;local by=0;local body=self.body;local footH=0
    local all=self:recipients()
    self.people.Visible=false;self.groups.Visible=false
    local function strip(s,y)s.Visible=true;K.box(s,13,y,cw,40);s.ZIndex=self.frame.ZIndex+2 end
    local function people(withAll)
        local items={};if withAll then table.insert(items,{key=0,text='전체',name='All'})end
        for _,f in ipairs(all)do table.insert(items,{key=f.id,text=L.nation(f),name=tostring(f.id),skip=true})end
        strip(self.people,54)
        pills(self.people,items,self.targetId,function(it)self.targetId=it.key;Step.step('comms','quickRecipient',{});self:draw()end)
    end
    if self.mode=='messages'and self.subject then
        local m=self.subject
        local back=K.button(self.frame,'SubjectBack',{kind='ghost',icon='back',iconSize=18,hit=40},function()self.subject=nil;self:draw()end)
        back:place(13,54,40,40);back.button:SetAttribute('Transient',true);back.button.ZIndex=self.frame.ZIndex+2
        local t=K.text(self.frame,'SubjectText',L.text(m.text),14,C.ink,800);K.box(t,59,54,cw-46,40);t.ZIndex=self.frame.ZIndex+2;t:SetAttribute('Transient',true);t:SetAttribute('LocalizationSkip',true)
        title(body,'Ask','어느 부대를 말할까요?',by);by+=32+4
        local half=(cw-6)/2;local ch=44
        for i,f in ipairs(all)do
            local b=cell(body,'Subject'..f.id,L.nation(f),(i-1)%2*(half+6),by+((i-1)//2)*(ch+6),half,ch,false,false,function()self:send(m.key,f.id)end)
            b.label:SetAttribute('LocalizationSkip',true);b.label.Position=UDim2.fromOffset(42,0);b.label.Size=UDim2.new(1,-52,1,0)
            local face=K.avatar(b.face,'Face',f.userId and f.userId>0 and f.userId or nil,24);K.box(face,10,(ch-24)/2,24,24);face.ZIndex=b.face.ZIndex+1
        end
        by+=math.max(0,math.ceil(#all/2)*(ch+6)-6)
    elseif self.mode=='messages'then
        people(false)
        if #all==0 then title(body,'NoRecipient','보낼 상대 없음',by);by+=32 end
        if VipLock.allows('quickChat')then
            local items={};for _,g in ipairs(self.GROUPS)do table.insert(items,{key=g[1]or false,text=g[2],name=g[2]})end
            if not touch then table.insert(items,{key='search',text='검색',name='Search'})end
            self.groups.Parent=body;self.groups.Visible=true;K.box(self.groups,0,by,cw,40);self.groups.ZIndex=body.ZIndex+1
            pills(self.groups,items,self.searching and 'search'or self.group or false,function(it)
                if it.key=='search'then self.searching=not self.searching else self.group=it.key or nil;self.searching=false end
                self:draw()
            end)
            by+=44
            if self.searching then
                local box=K.make('TextBox',body,{Name='Search',Text=self.query or '',PlaceholderText='문구 검색',ClearTextOnFocus=false,TextSize=13,TextColor3=C.ink,PlaceholderColor3=C.muted,BackgroundColor3=C.raised,BorderSizePixel=0,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=body.ZIndex+1})
                if K.fonts[700]then box.FontFace=K.fonts[700]end
                K.round(box,8);K.make('UIPadding',box,{PaddingLeft=UDim.new(0,12)});K.box(box,0,by,cw,40);by+=46
                box:GetPropertyChangedSignal('Text'):Connect(function()self.query=box.Text;task.defer(function()if self.frame.Visible and self.searching then self:phrases()end end)end)
            end
        end
        self.listTop=by;self:phrases();by=self.listBottom or by
    elseif self.mode=='emoji'then
        people(true)
        local free=VipLock.allows('emoji','😀')
        local cols=touch and math.max(4,math.floor((cw+6)/54))or 8;local gap=6
        local size=math.floor((cw-gap*(cols-1))/cols);local ch=touch and math.max(44,size)or math.min(44,size)
        local function grid(list,prefix,slots)
            local n=math.max(#list,slots or 0)
            for i=1,n do
                local e=list[i];local x=(i-1)%cols*(size+gap);local yy=by+((i-1)//cols)*(ch+gap)
                if e then
                    local locked=not VipLock.allows('emoji',e)and not self.editing
                    local function press()if self.editing then self.draft=Favorites.toggle(self.draft,e)or self.draft;self:draw()else self:send(e,nil,nil)end end
                    local b=cell(body,prefix..i,e,x,yy,size,ch,locked,false,press,22)
                    b.label:SetAttribute('LocalizationSkip',true);b.label.TextXAlignment=Enum.TextXAlignment.Center;b.label.Position=UDim2.new();b.label.Size=UDim2.fromScale(1,1)
                    if not locked then
                        b.button:SetAttribute('Send',not self.editing)
                        if self.editing and table.find(self.draft or {},e)then K.stroke(b.face,C.accent,2,0,true).Enabled=true end
                        if not self.editing then b:setEnabled(self:allowed()==true)end
                    end
                else
                    local slot=K.dashBox(body,prefix..'Empty'..i,C.line,0,8);K.box(slot,x,yy,size,ch);slot.ZIndex=body.ZIndex+1
                end
            end
            by+=math.ceil(n/cols)*(ch+gap)-gap
        end
        local favs=self.editing and self.draft or self.favorites
        title(body,'FavTitle','즐겨찾기',by)
        local edit=K.button(body,'EditFavorites',{kind='ghost',text=self.saving and '저장 중…'or self.editing and '저장'or '편집',size=13,weight=800,hit=36},function()
            if self.saving then return end
            if not self.editing then self.draft=Favorites.copy(self.favorites);self.editing=true;self:draw();return end
            self.saving=true;local draft=self.draft;self:draw()
            self.callbacks.save(Favorites.copy(draft),function(ok)
                self.saving=false;Step.step('comms','favSave',{result=ok and 'ok'or 'failed',count=#draft})
                if ok and self.draft==draft then self.editing=false;self.draft=nil end
                if self.frame.Visible then self:draw()end
            end)
        end)
        edit.label.TextColor3=C.accent;edit:place(cw-64,by+4,64,28);Sheet.fill20(edit);edit.label.TextXAlignment=Enum.TextXAlignment.Right
        by+=32+4
        if #favs>0 or self.editing then grid(favs,'Fav',touch and 0 or cols);by+=4 end
        title(body,'FreeTitle','외교',by);by+=32+4;grid(Vip.freeEmojis,'Free');by+=4
        title(body,'AllTitle','전체',by,not free);by+=32+4
        local rest={};for _,e in ipairs(Catalog.emojis)do if not Vip.freeEmoji(e)then table.insert(rest,e)end end
        grid(rest,'Emoji')
    elseif self.mode=='chat'then
        local model=self.callbacks.model
        local shown={};for _,sc in ipairs(self.SCOPES)do if model:channelName(sc[1])~=nil then table.insert(shown,sc)end end
        if #shown==0 then shown={self.SCOPES[1]}end
        local seg=K.segment(self.frame,'Scopes',shown,model.scope,function(id)model.scope=id;Step.step('comms','chatScope',{item=id});self:draw()end,{size=13})
        seg:place(13,57,math.min(84*#shown,cw),34);seg.frame:SetAttribute('Transient',true);seg.frame.ZIndex=self.frame.ZIndex+2
        local lines={};for _,h in ipairs(model.history)do if h.scope==model.scope or h.scope=='player'or h.scope=='allies'then table.insert(lines,h)end end
        local phone=r.fmt=='ph';local rowH=phone and 30 or 44
        for i,h in ipairs(lines)do
            local yy=by;by+=rowH+4
            local face=K.avatar(body,'Face'..i,h.userId and h.userId>0 and h.userId or nil,24);K.box(face,0,yy+(phone and 3 or 2),24,24);face.ZIndex=body.ZIndex+1
            local n=K.text(body,'Name'..i,h.me and '나'or h.name,13,h.me and C.accent or C.ink,800);n.ZIndex=body.ZIndex+1;n:SetAttribute('LocalizationSkip',not h.me)
            local tw=math.min(K.width(h.me and L.text('나')or h.name,13,n)+2,cw*.45);K.box(n,32,yy,tw,phone and rowH or 20)
            local x=38+tw
            if h.tag then local tag,gw=K.chip(body,'Tag'..i,h.tag,'muted',{size=11,height=20,icon=false});tag.Position=UDim2.fromOffset(x,yy+(phone and (rowH-20)/2 or 0));tag.ZIndex=body.ZIndex+1;x+=gw+6 end
            local t=K.text(body,'Text'..i,h.text,13,C.ink,500);t.ZIndex=body.ZIndex+1;t:SetAttribute('LocalizationSkip',h.tag==nil)
            if phone then K.box(t,x,yy,cw-x,rowH)else K.box(t,32,yy+20,cw-32,22)end
        end
        if #lines==0 then title(body,'Empty','대화 없음',by);by+=32 end
        local ih=touch and 44 or 40;footH=ih+8
        if VipLock.allows('text')then
            local input,go=model.input,model.sendButton
            input.Parent=self.foot;input.ZIndex=self.foot.ZIndex+1;input.BackgroundColor3=C.raised;input.BackgroundTransparency=0;K.round(input,8)
            for _,s in ipairs(input:GetChildren())do if s:IsA('UIStroke')then s.Enabled=false end end
            K.box(input,0,4,cw-ih-6,ih);input.PlaceholderText='메시지 입력';input.TextSize=13;if K.fonts[700]then input.FontFace=K.fonts[700]end
            if not input:FindFirstChildOfClass('UIPadding')then K.make('UIPadding',input,{PaddingLeft=UDim.new(0,12)})end;input.TextXAlignment=Enum.TextXAlignment.Left
            go.Parent=self.foot;go.ZIndex=self.foot.ZIndex+1;go.BackgroundColor3=C.accent;go.BackgroundTransparency=0;go.TextColor3=C.bg;K.round(go,8);K.box(go,cw-ih,4,ih,ih);go.TextSize=18
            for _,s in ipairs(go:GetChildren())do if s:IsA('UIStroke')then s.Enabled=false end end
        else
            local row=K.make('Frame',self.foot,{Name='VipText',BackgroundColor3=C.raised,BackgroundTransparency=.5,BorderSizePixel=0,ZIndex=self.foot.ZIndex+1});K.round(row,8);K.box(row,0,4,cw,ih)
            local l=K.text(row,'Text','메시지 입력',13,C.ink,700);l.TextTransparency=.55;K.box(l,12,0,cw-80,ih);l.ZIndex=row.ZIndex+1
            local chip,cwid,chh=K.lock(row,'VIP',0,0,11);chip.Position=UDim2.fromOffset(cw-12-cwid,math.floor((ih-chh)/2));chip.ZIndex=row.ZIndex+1
        end
        task.defer(function()if self.body.Parent then self.body.CanvasPosition=Vector2.new(0,math.max(0,self.body.CanvasSize.Y.Offset-self.body.AbsoluteSize.Y/(require(script.Parent.Theme).scale or 1)))end end)
    else
        local Career=require(script.Parent.Parent.Core.CareerRules);local Loadout=require(script.Parent.Parent.Core.MotionLoadout)
        local Motions=require(script.Parent.MotionsPage)
        local a=self.callbacks.account and self.callbacks.account()or {};local level=(a.progress or {}).level or 1
        local club=VipLock.allows('motion')
        title(body,'MotionTitle','모션',by,not club);by+=32+4
        local slots={};for _,id in ipairs(Loadout.copy((a.preferences or {}).motionLoadout,level))do table.insert(slots,{m=Loadout.find(id)})end
        for _,m in ipairs(Career.motions)do if m.level>level and #slots<6 then table.insert(slots,{m=m,locked=true})end end
        while #slots<6 do table.insert(slots,{})end
        local gap=6;local sw=(cw-gap*2)/3;local sh=r.fmt=='pc'and 112 or 96;local is=r.fmt=='pc'and 34 or 28
        for i,sl in ipairs(slots)do
            local x=(i-1)%3*(sw+gap);local yy=by+((i-1)//3)*(sh+gap);local m=sl.m
            if not m then
                local d=K.dashBox(body,'Motion'..i,C.line,0,8);K.box(d,x,yy,sw,sh);d.ZIndex=body.ZIndex+1
                local plus=K.icon(d,'plus',20,C.muted,'Plus');K.box(plus,(sw-20)/2,(sh-20)/2,20,20)
            else
                local faint=sl.locked or not club
                local b=cell(body,'Motion'..i,'',x,yy,sw,sh,faint,false,function()
                    if sl.locked then return end
                    if not club then return VipLock.open('motion',false,self.lastCell)end
                    Step.step('character','motionWheel',{item=Step.code(m.id),value=i});Motions.play(m);self:hide()
                end)
                local host=b.face or b.button;host:SetAttribute('Motion',m.id)
                b.button.InputBegan:Connect(function()self.lastCell=b.button end)
                local name=K.text(host,'Name',m.name,13,C.ink,800,Enum.TextXAlignment.Center);name.ZIndex=host.ZIndex+2;K.box(name,6,sh-30,sw-12,20)
                if faint then name.TextTransparency=.55 end
                if sl.locked then
                    local chip,lw=K.lock(host,'Lv.'..m.level,0,0,11);chip.Position=UDim2.fromOffset(math.floor((sw-lw)/2),math.floor(sh/2-26));chip.ZIndex=host.ZIndex+2
                else
                    local icon=K.icon(host,Motions.icons[m.id]or 'reward',is,C.ink,'Icon');K.box(icon,(sw-is)/2,math.floor(sh/2-is/2-12),is,is);icon.ZIndex=host.ZIndex+2
                    if faint then icon.ImageTransparency=.55 end
                end
            end
        end
        by+=2*(sh+gap)-gap
    end
    if self.mode~='chat'then giveBack()end
    K.box(self.foot,13,r.h-8-footH,cw,footH);self.foot.ZIndex=self.frame.ZIndex+2
    local top=(self.mode=='chat')and 99 or TOP
    K.box(self.body,11,top,cw+4,r.h-top-8-footH);self.body.ZIndex=self.frame.ZIndex+1
    if self.mode~='messages'or self.subject then body.CanvasSize=UDim2.fromOffset(0,by+6)end
    if bodyScroll and self.mode~='chat'then self.body.CanvasPosition=bodyScroll end
    if peopleScroll then self.people.CanvasPosition=peopleScroll end
    if groupsScroll then self.groups.CanvasPosition=groupsScroll end
end

function M.phrases(self)
    local body=self.body;local r=self.r;if not r then return end
    local cw=r.w-26;local half=(cw-6)/2
    for _,o in ipairs(body:GetChildren())do if o:GetAttribute('Phrase')then o:Destroy()end end
    local by=self.listTop or 0;local q=self.query and self.searching and self.query:lower():gsub('^%s+',''):gsub('%s+$','')or ''
    local can=self:allowed()==true
    local function list(items,prefix,h)
        for i,m in ipairs(items)do
            local col=(i-1)%2;local yy=by+((i-1)//2)*(h+6)
            local locked=not VipLock.allows('quickChat',{key=m.key})
            local b;b=cell(body,prefix..m.key,L.text(m.text),col*(half+6),yy,half,locked and 40 or h,locked,m.requiresTarget and not locked,function()
                if locked then return VipLock.open('quickChat',false,b and b.button)end
                if not can then return end
                if m.requiresTarget then self.subject=m;Step.step('comms','quickSubject',{item=Step.code(m.key)});self:draw()else self:send(m.key,nil,b and b.button)end
            end,locked and 12 or 13)
            b.button:SetAttribute('Phrase',true);b.label:SetAttribute('LocalizationSkip',true)
            if not locked then b.button:SetAttribute('Send',true);b:setEnabled(can)end
        end
        if #items>0 then by+=math.ceil(#items/2)*(h+6)-6 end
    end
    local recent={};for _,key in ipairs(self.recent)do for _,m in ipairs(Catalog.messages)do if m.key==key then table.insert(recent,m)end end end
    local found={};for _,m in ipairs(Catalog.messages)do if (not self.group or m.group==self.group)and (q==''or m.text:lower():find(q,1,true)or L.text(m.text):lower():find(q,1,true))then table.insert(found,m)end end
    if VipLock.allows('quickChat')then
        if q==''and #recent>0 and not self.group then title(body,'RecentTitle','최근 보낸 문구',by,false,'Phrase');by+=32+4;list(recent,'Recent_',44);by+=4;title(body,'AllTitle','모든 문구',by,false,'Phrase');by+=32+4 end
        list(found,'Message_',44)
    else
        local free,rest={},{};for _,m in ipairs(found)do table.insert(Vip.freePhrases[m.key]and free or rest,m)end
        list(free,'Message_',44);by+=4
        title(body,'VipQuickChat','빠른 대화',by,#rest>0,'Phrase');by+=32+4
        list(rest,'Message_',40)
    end
    if #found==0 then title(body,'Empty','결과 없음',by,false,'Phrase');by+=32;Step.change('quickSearch','comms','quickSearchEmpty',{result='unavailable'})end
    self.listBottom=by;body.CanvasSize=UDim2.fromOffset(0,by+6)
end
return M
