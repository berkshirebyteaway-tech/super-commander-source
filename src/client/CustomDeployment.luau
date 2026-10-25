local K=require(script.Parent.Kit20)
local S=require(script.Parent.Sheet20)
local Theme=require(script.Parent.Theme)
local pack=game.ReplicatedStorage.FrontierNative
local Rules=require(pack.Core.CustomBattlefieldRules)
local SettingsCode=require(pack.Core.SettingsCode)
local Challenges=require(pack.Core.CustomChallenges)
local Copy=require(pack.Core.BattlefieldRules)
local Options=require(pack.Core.MatchOptions)
local Flow=require(pack.Core.PlayFlow)
local L=require(script.Parent.Localization)
local Players=game:GetService('Players')
local C=K.colors
local M={}
local difficulties=Options.difficultyLabels
local Rows=require(script.Parent.SettingsRows)
local RuleRows=require(script.Parent.MatchRuleRows)
local function canLaunch(q)
    if not q or q.count<q.minimum then return false end
    for _,member in ipairs(q.members or {})do if member.userId~=q.hostUserId and not member.ready then return false end end
    return true
end
M.canLaunch=canLaunch
function M.begin(lobby,edit,mode)
    if edit then local q=lobby.data and lobby.data.queue;if not q or q.mode~='custom'or q.hostUserId~=Players.LocalPlayer.UserId then return end;lobby.customDraft=Copy.copy(q.rules);lobby.customEditRevision=q.revision;lobby.customEditing=true;lobby.customStep=2
    elseif mode or not lobby.customDraft or lobby.customEditing then lobby.customDraft=Rules.default(lobby.map,mode or 'coop');lobby.customEditing=false;lobby.customStep=1 end
    lobby:openPage('custom')
end
function M.party(lobby,challenge)
    local party=lobby.data and lobby.data.party
    if party and party.leader~=Players.LocalPlayer.UserId then return end
    lobby.customDraft=require(pack.Core.PartyPlay).coop(lobby.map,party,challenge)
    lobby.customEditing=false;lobby.customStep=3;lobby:openPage('custom')
end
function M.primary(lobby)
    if lobby.page=='customCode'then
        local rules=SettingsCode.decode(lobby.settingsImport and lobby.settingsImport.Text or '')
        if not rules then if lobby.settingsCodeError then lobby.settingsCodeError.Text='잘못된 코드'end;return end
        lobby.customDraft=rules;lobby.customStep=2;lobby.customEditing=false;lobby:openPage('custom')
    elseif lobby.page=='custom'then
        local draft=Copy.copy(lobby.customDraft)
        local action=lobby.customEditing and 'customUpdate'or 'customCreate'
        local value=lobby.customEditing and {revision=lobby.customEditRevision,rules=draft}or draft
        local function create()lobby:request(action,value,function()lobby.customDraft=nil;lobby.customEditing=false;lobby:openPage('room')end)end
        local q=lobby.data and lobby.data.queue
        if not lobby.customEditing and q then lobby:request('cancel',nil,create)else create()end
    elseif lobby.page=='customRules'then lobby:openPage('custom')
    elseif lobby.page=='joinCode'then lobby:request('joinCode',lobby.codeInput and lobby.codeInput.Text or '')
    elseif lobby.page=='room'then
        local q=lobby.data and lobby.data.queue;if not q or q.mode~='custom'then return end
        local host=q.hostUserId==Players.LocalPlayer.UserId;local othersReady=canLaunch(q)
        if host and not othersReady then return end
        local action=host and 'customLaunch'or 'customReady'
        lobby:request(action,{revision=q.revision})
    end
end
function M.secondary(lobby)
    if lobby.page=='customCode'or lobby.page=='customRules'then lobby:openPage('custom')
    elseif lobby.page=='custom'then lobby:back()
    elseif lobby.page=='room'then lobby:request('cancel',nil,function()lobby:closePage()end)end
end
function M.footer(lobby)
    local page=lobby.page;local q=lobby.data and lobby.data.queue;local b=lobby.custom20
    if page=='room'then require(script.Parent.CustomRoom20).footer(lobby);return end
    if not b or b.page~=page or not b.primary then return end
    if page=='custom'then
        b.primary:setText(lobby.customEditing and '규칙 저장'or q and '대기 취소 후 방 만들기'or '방 만들기')
        b.primary:setEnabled(not lobby.busy and not(q and (q.locked or q.phase=='transferring')))
    elseif page=='joinCode'then b.primary:setEnabled(not lobby.busy)end
end

local function frameFormat(lobby)
    local s=Theme.scale or 1;local W,H=lobby.root.AbsoluteSize.X/s,lobby.root.AbsoluteSize.Y/s
    return S.format(W,H),W,H
end
local function root(body)
    for _,o in ipairs(body:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
    return K.make('Frame',body,{Name='Page20',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromOffset(body.Size.X.Offset,body.Size.Y.Offset)})
end
local function bottomEdge(lobby,fmt,H,sh)
    if fmt~='pt'then return sh-(fmt=='ph'and 12 or 24)-1 end
    local lift=0;local d=lobby.deployment;local q=lobby.data and lobby.data.queue
    if q and d and d.bar and d.bar.Visible then lift=(d.barHeight or 48)+8 end
    local _,cb=S.band(H,lift);return cb
end
local function counts(mode,value)
    local list=mode=='coop'and {{2,'2'},{3,'3'},{4,'4'},{5,'5'}}or {{4,'4'},{8,'8'},{12,'12'},{20,'20'}}
    local lo,hi=mode=='teams'and 2 or 1,mode=='coop'and 5 or 20
    local preset=false;for _,v in ipairs(list)do if v[1]==value then preset=true end end
    table.insert(list,{'input',preset and ''or tostring(value or ''),input={min=lo,max=hi,width=64}})
    return list,preset and value or 'input'
end

local function create(lobby,body)
    lobby.customDraft=lobby.customDraft or Rules.default(lobby.map,'coop');local r=lobby.customDraft
    local fmt,_,H=frameFormat(lobby);local pt,ph=fmt=='pt',fmt=='ph'
    local sw,sh=body.Size.X.Offset,body.Size.Y.Offset;local page=root(body)
    local head=S.head(page,fmt,sw,lobby.customEditing and '규칙 바꾸기'or '방 만들기',function()lobby:back()end)
    local ms=pt and 40 or ph and 32 or 40
    local more=K.button(page,'More',{kind=pt and 'plain'or 'none',icon='more',iconSize=pt and 18 or ph and 16 or 18},function(b)
        local items={{text='상세 규칙',icon='settings',fn=function()lobby:openPage('customRules')end},{text='설정 코드',icon='code',fn=function()lobby:openPage('customCode')end}}
        if not lobby.customEditing then table.insert(items,{text='초대 코드로 참가',icon='invite',fn=function()lobby:openPage('joinCode')end})end
        if not lobby.customEditing and lobby.data and lobby.data.recentCustom then table.insert(items,{text='최근 방 다시 만들기',icon='restore',fn=function()lobby.customDraft=Copy.copy(lobby.data.recentCustom);lobby:drawPage();lobby:layout()end})end
        S.menu(lobby,b.button,items)
    end)
    more.faceStroke.Enabled=false;more.iconColorFixed=true;more.iconImage.ImageColor3=C.muted
    more:place(head.right-ms,head.y+(head.h-ms)/2,ms,ms)
    local p=pt and 16 or ph and 12 or 24;local inset=pt and 0 or 1
    local mx,my,mw,mh
    if pt then mx,my,mw,mh=16,114,sw-32,150 else local y0=ph and 46 or 72;mx,my=p+inset,y0+inset;mw=ph and 220 or 380;mh=sh-y0-p end
    local map=K.map(page,'MapSummary',r.map,mw,mh,pt and 8 or 10);K.box(map,mx,my,mw,mh);K.stroke(map,C.line,1,0,true)
    local fadeH=pt and 40 or ph and 54 or 80
    local fade=K.fadeBox(map,'Fade',Color3.fromRGB(8,10,14),0,.92,pt and 8 or 10);fade.Size=UDim2.new(1,0,0,fadeH);fade.Position=UDim2.new(0,0,1,-fadeH);fade.ZIndex=3
    local ns=pt and 15 or ph and 16 or 22
    local name=K.text(map,'Title',(require(pack.Maps.MapLoader).meta(r.map)or {}).label or r.map,ns,C.ink,800);name.ZIndex=4
    local bx=pt and 10 or ph and 10 or 16;local bb=pt and 0 or ph and 10 or 14
    local change
    if pt then
        change=K.button(map,'ChangeMap',{kind='none',text='바꾸기',size=13,weight=800},function()lobby.returnPage='custom';lobby:openPage('maps')end)
        change.label.TextColor3=C.accent;change.ink=C.accent
        local cw=K.width('바꾸기',13)+2+3+14;change:place(mw-10-cw,mh-40,cw,40)
        local chev=K.icon(change.face,'chev',14,C.accent,'Chev');K.box(chev,cw-14,13,14,14);change:layoutContent('left',0)
        K.box(name,10,mh-40,mw-30-cw,40)
    else
        local chH=ph and 30 or 36;local fs=ph and 12 or 14;local is=ph and 13 or 15
        local tw=K.width('바꾸기',fs);local cw=12+is+6+tw+2+12
        change=K.button(map,'ChangeMap',{kind='plain',icon='map',iconSize=is,text='바꾸기',size=fs,weight=800,gap=6},function()lobby.returnPage='custom';lobby:openPage('maps')end)
        change:place(mw-bx-cw,mh-bb-chH,cw,chH)
        K.box(name,bx,mh-bb-chH,mw-bx*2-cw-8,chH)
    end
    change.button.ZIndex=5
    local billing=lobby.account and lobby.account.billing;local publicOk=billing and billing.benefits and billing.benefits.publicCustom
    if not publicOk and r.visibility=='public'then r.visibility='invite'end
    local rx,rw,y
    if pt then rx,rw,y=16,sw-32,my+mh+12 else rx=mx+mw+(ph and 10 or 24);rw=sw-inset-p-rx;y=my end
    local ls=pt and 12 or ph and 11 or 13;local segH=pt and 40 or ph and 32 or 44;local segFs=pt and 13 or ph and 12 or 15
    local labelGap=pt and 6 or ph and 4 or 6
    local function rowSeg(key,title,items,value,pick,opts)
        local l=K.text(page,'Label_'..key,title,ls,C.muted,800);K.box(l,rx,y,rw,ls+2)
        local seg=S.segment(page,key,items,value,pick,{size=segFs,guard=opts and opts.guard,lockSize=11})
        seg:place(rx,y+ls+2+labelGap,rw,segH)
        y+=pt and 58 or segH+(ph and 22 or 30)
        return seg
    end
    rowSeg('Mode','모드',{{'ffa','개인전'},{'teams','팀전'},{'coop','협동'}},r.mode,function(v)
        r.mode=v;r.teamFormat=nil;r.minimum=v=='teams'and 2 or 1
        if v=='coop'then r.maximum=math.min(r.maximum,5)elseif r.maximum<4 then r.maximum=8 end
        r.teamCount=math.min(r.teamCount or 2,math.max(2,r.maximum));lobby:drawPage()end)
    local sizes,sizeOn=counts(r.mode,r.maximum)
    rowSeg('Maximum','인원',sizes,sizeOn,function(n)r.maximum=n;r.teamCount=math.min(r.teamCount or 2,math.max(2,n));lobby:drawPage()end)
    rowSeg('Difficulty','AI',Options.difficulties,r.settings.difficulty,function(v)r.settings.difficulty=v end)
    rowSeg('Visibility','공개',{{'invite','초대만'},{'public','공개',lock=not publicOk and 'VIP'or nil}},r.visibility,function(v)r.visibility=v end,{guard=function(v)
        if v=='public'and not publicOk then
            require(script.Parent.LobbyConfirm).open(lobby,'공개 모집','🔒 VIP 클럽  초대 코드 방은 무료','혜택 보기',function()lobby:openPage('benefits')end,'custom');return false end
        return true end})
    local bh=pt and 56 or ph and 44 or 60
    local by=pt and bottomEdge(lobby,fmt,H,sh)-bh or sh-1-p-bh
    local go=K.button(page,'StartSolo',{kind='pri',text='방 만들기',size=pt and 20 or ph and 16 or 20},function(b)K.confirm(b,true);M.primary(lobby)end)
    go:place(rx,by,rw,bh)
    lobby.custom20={page='custom',primary=go}
    M.footer(lobby)
end

local function rules(lobby,body)
    lobby.customDraft=lobby.customDraft or Rules.default(lobby.map,'coop');local r=lobby.customDraft;local s=r.settings
    local fmt,_,H=frameFormat(lobby);local pt,ph=fmt=='pt',fmt=='ph'
    local sw,sh=body.Size.X.Offset,body.Size.Y.Offset;local page=root(body)
    local head=S.head(page,fmt,sw,'상세 규칙',function()lobby:closePage()end,{back=function()lobby:openPage('custom')end})
    local p=pt and 16 or ph and 12 or 24;local inset=pt and 0 or 1;local x=p+inset;local w=pt and sw-32 or sw-2*x
    local tab=lobby.customRulesTab or 'room'
    local seg=S.segment(page,'RuleTabs',{{'room','방'},{'economy','상대와 경제'},{'special','특수 규칙'},{'match','경기 규칙'}},tab,function(v)lobby.customRulesTab=v;lobby:drawPage()end,{size=pt and 13 or ph and 12 or 14})
    local ty=head.y+head.h+(pt and 8 or ph and 6 or 10);seg:place(x,ty,w,pt and 40 or ph and 32 or 40)
    local bh=pt and 52 or ph and 40 or 52
    local by=pt and bottomEdge(lobby,fmt,H,sh)-bh or sh-1-p-bh
    local top=ty+(pt and 40 or ph and 32 or 40)+(ph and 8 or 12)
    local scroll=S.scroll(page,'Rules',x,top,w,by-(ph and 8 or 12)-top)
    local y=0
    local function redraw()lobby:drawPage();lobby:layout()end
    if tab=='room'then
        y=Rows.choice(scroll,'Spawn','스폰',{{'select','스폰 선택'},{'random','랜덤 스폰'}},r.spawn,y,w,function(v)r.spawn=v;lobby:drawPage()end)
        y=Rows.numeric(scroll,'Maximum','최대 참가 인원',r.maximum,y,w,r.mode=='teams'and 2 or 1,r.mode=='coop'and 5 or 20,function(n)r.maximum=math.floor(n);r.teamCount=math.min(r.teamCount,math.max(2,r.maximum));redraw()end)
        if r.mode=='coop'then
            local count=lobby.data and lobby.data.party and #lobby.data.party.users or r.maximum
            local values={};for _,e in ipairs(Challenges.entries)do table.insert(values,{e.id,string.format('%d vs %d / %s',count,math.ceil(count*e.ratio),L.text(difficulties[e.difficulty]))})end
            y=Rows.choice(scroll,'CoopChallenge','협동 도전',values,nil,y,w,function(id)lobby.customDraft=Challenges.apply(r,id,count)or r;redraw()end)
            y=Rows.numeric(scroll,'AiRatio','사람마다 상대할 AI 수',r.aiPerHuman,y,w,1,4,function(n)r.aiPerHuman=math.floor(n);r.aiCount=nil;redraw()end)
            if r.aiCount then y=Rows.numeric(scroll,'AiCount','고정 AI 총원',r.aiCount,y,w,1,400,function(n)r.aiCount=math.floor(n);redraw()end)end
            local ai=Flow.coopAI(r,0)
            local projection=r.aiCount and string.format(L.text('최대 %d명 vs AI %d명'),r.maximum,ai.maximum)or string.format(L.text('1~%d명 → AI %d~%d명'),r.maximum,ai.minimum,ai.maximum)
            local l=K.text(scroll,'AIProjection',projection,14,C.prime,700);K.box(l,8,y,w-16,32);y+=40
        elseif r.mode=='teams'then
            local pick=function(v)r.teamFormat=v~='count'and v or nil;redraw()end
            y=Rows.choice(scroll,'TeamFormatA','팀 구성',{{'count','팀 수'},{'Duos','듀오'},{'Trios','트리오'}},r.teamFormat or 'count',y,w,pick)
            y=Rows.choice(scroll,'TeamFormatB','팀 구성',{{'Quads','쿼드'},{'HumansVsNations','사람 대 국가'}},r.teamFormat or 'count',y,w,pick)
            if not r.teamFormat then y=Rows.numeric(scroll,'TeamCount','최대 팀 수 / 자동 배정',r.teamCount,y,w,2,math.min(10,r.maximum),function(n)r.teamCount=math.floor(n)end)end
            if r.teamFormat~='HumansVsNations'then y=Rows.choice(scroll,'TeamAssignment','팀 배정',{{'auto','자동 배정'},{'select','팀 직접 선택'}},r.teamAssignment or 'auto',y,w,function(v)r.teamAssignment=v;lobby:drawPage()end)end
        end
    else
        local ctx={s=s,map=r.map,coop=r.mode=='coop',teams=r.mode=='teams',set=function(key,value)RuleRows.applyCustom(r,key,value);lobby:drawPage()end}
        if tab=='economy'then y=RuleRows.draw(scroll,w,y,ctx,{'opponents','economy'})
        elseif tab=='special'then
            local roll=K.button(scroll,'RollSpecial',{kind='out',text='무작위 특수 규칙',size=15},function()Rules.rollSpecial(r,Random.new());lobby:drawPage()end)
            roll:place(2,y,w-4,48);y+=56
            local rolled=r.modifiers
            if rolled and #rolled>0 then local names={};for _,k in ipairs(rolled)do table.insert(names,Copy.modifierLabels[k])end;local l=K.text(scroll,'Rolled',table.concat(names,', '),14,C.prime,700);K.box(l,8,y,w-16,32);y+=40 end
            y=RuleRows.draw(scroll,w,y,ctx,{'combat','units'})
        else y=RuleRows.draw(scroll,w,y,ctx,{'time','map','teams'})end
    end
    S.canvas(scroll,y)
    local done=K.button(page,'StartSolo',{kind='pri',text='완료',size=pt and 18 or ph and 15 or 18},function()M.primary(lobby)end)
    done:place(x,by,w,bh)
    lobby.custom20={page='customRules',primary=done}
end

local function box(parent,name,text,placeholder,size,font,editable)
    local t=K.make('TextBox',parent,{Name=name,Text=text or '',PlaceholderText=placeholder or '',ClearTextOnFocus=false,TextEditable=editable~=false,TextSize=size,TextWrapped=true,
        TextColor3=C.ink,PlaceholderColor3=C.dim,BackgroundColor3=C.bg,BorderSizePixel=0,TextXAlignment=Enum.TextXAlignment.Left})
    if font then t.FontFace=font end
    K.round(t,8);K.stroke(t,C.line,1,0,true);K.make('UIPadding',t,{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)})
    t:SetAttribute('LocalizationSkip',true);return t
end
local function code(lobby,body)
    local fmt,_,H=frameFormat(lobby);local pt,ph=fmt=='pt',fmt=='ph'
    local sw,sh=body.Size.X.Offset,body.Size.Y.Offset;local page=root(body)
    local head=S.head(page,fmt,sw,'설정 코드',function()lobby:closePage()end,{back=function()lobby:openPage('custom')end})
    local p=pt and 16 or ph and 12 or 24;local inset=pt and 0 or 1;local x=p+inset;local w=pt and sw-32 or sw-2*x
    local y=head.y+head.h+(ph and 6 or 12);local ls=pt and 12 or ph and 11 or 13;local tb=ph and 52 or 80
    local mono=Font.fromEnum(Enum.Font.Code)
    local l1=K.text(page,'ExportTitle','현재 설정 공유',ls,C.muted,800);K.box(l1,x,y,w,ls+2);y+=ls+2+6
    local ex=box(page,'SettingsExport',SettingsCode.encode(lobby.customDraft or Rules.default(lobby.map,'coop'))or '',nil,13,mono,false);K.box(ex,x,y,w,tb);y+=tb+(ph and 8 or 16)
    local l2=K.text(page,'ImportTitle','친구의 설정 불러오기',ls,C.muted,800);K.box(l2,x,y,w,ls+2);y+=ls+2+6
    lobby.settingsImport=box(page,'SettingsImport','','SC1.…',13,mono,true);K.box(lobby.settingsImport,x,y,w,tb);y+=tb+4
    lobby.settingsCodeError=K.text(page,'SettingsCodeError','',13,C.danger,700);K.box(lobby.settingsCodeError,x,y,w,20)
    local bh=pt and 52 or ph and 40 or 52;local by=pt and bottomEdge(lobby,fmt,H,sh)-bh or sh-1-p-bh
    local go=K.button(page,'StartSolo',{kind='pri',text='설정 적용',size=pt and 18 or ph and 15 or 18},function()M.primary(lobby)end)
    go:place(x,by,w,bh)
    lobby.custom20={page='customCode',primary=go}
end
local function join(lobby,body)
    local fmt=frameFormat(lobby);local pt,ph=fmt=='pt',fmt=='ph'
    local sw,sh=body.Size.X.Offset,body.Size.Y.Offset;local page=root(body)
    local head=S.head(page,fmt,sw,'초대 코드',function()lobby:back()end)
    local p=pt and 16 or ph and 12 or 24;local inset=pt and 0 or 1;local x=p+inset;local w=pt and sw-32 or sw-2*x
    local y=head.y+head.h+(ph and 10 or 16)
    lobby.codeInput=box(page,'Code',lobby.inviteCode or '','XXXXXXXX',ph and 24 or 32,K.fonts.num,true)
    lobby.codeInput.TextXAlignment=Enum.TextXAlignment.Center;lobby.codeInput.TextColor3=C.prime;lobby.codeInput.TextWrapped=false
    K.box(lobby.codeInput,x,y,w,ph and 52 or 64)
    local bh=pt and 52 or ph and 44 or 56;local by=pt and y+(ph and 52 or 64)+16 or sh-1-p-bh
    local go=K.button(page,'StartSolo',{kind='pri',text='방 참가',size=pt and 18 or ph and 16 or 18},function(b)K.confirm(b,true);M.primary(lobby)end)
    go:place(x,by,w,bh)
    lobby.custom20={page='joinCode',primary=go}
    M.footer(lobby)
end

function M.draw(lobby,p,_)
    local page=lobby.page;lobby.customTimer=nil
    if page=='room'then require(script.Parent.CustomRoom20).draw(lobby,p);return end
    if page=='customCode'then code(lobby,p)
    elseif page=='joinCode'then join(lobby,p)
    elseif page=='customRules'then rules(lobby,p)
    else create(lobby,p)end
    lobby.first20=nil
end
return M
