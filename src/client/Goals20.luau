local K=require(script.Parent.Kit20)
local Theme=require(script.Parent.Theme)
local Step=require(script.Parent.TelemetryStep)
local Claims=require(script.Parent.GoalClaims)
local Campaign=require(script.Parent.Parent.Core.CampaignRules)
local C=K.colors
local M={}
local FLAME=Color3.fromRGB(236,112,52);local FLAME_TEXT=Color3.fromRGB(242,154,98)
local NODE_BG=Color3.fromRGB(27,34,48);local NOW_BG=Color3.fromRGB(16,48,47)
local ACH_ICON={firstWin='deploy',games10='records',cities25='fields',peak50='map',coopWin='friends',pvpWin='marshal',streak7='daily',wins10='ranked',maps5='solo',games50='clan'}
local PERCENT={peak50=true}

local function view(hub)return (hub.account.progress or {}).campaign or {stars={},total=0,chests=0,next=Campaign.stages[1].id}end
local function unlocked(v,id)return Campaign.unlocked({campaign={stars=v.stars}},id)end
local function won(v,id)return (tonumber((v.stars or {})[id])or 0)%2==1 end
local function chapterStages(ch)local out={};for _,s in ipairs(Campaign.stages)do if s.chapter==ch then table.insert(out,s)end end;return out end
local function chapterState(v,ch)
    local list=chapterStages(ch);local all=true;local any=false
    for _,s in ipairs(list)do if not won(v,s.id)then all=false end;if unlocked(v,s.id)then any=true end end
    return all and 'done'or any and 'open'or 'lock'
end
local function nextChest(total)for _,c in ipairs(Campaign.chests)do if total<c.stars then return c end end end
local function chestProgress(total)
    local prev=0;for _,ch in ipairs(Campaign.chests)do if total>=ch.stars then prev=ch.stars end end
    local c=nextChest(total);if not c then return 1,nil,prev end
    return (total-prev)/math.max(1,c.stars-prev),c,prev
end
local function stars(parent,n,max,size,gap)
    local f=K.make('Frame',parent,{Name='Stars',BackgroundTransparency=1});gap=gap or 2
    for i=1,max or 3 do local on=i<=n;local s=K.icon(f,on and 'starFill'or 'star',size,on and C.gold or C.dim,'Star'..i);K.box(s,(i-1)*(size+gap),0,size,size)end
    f.Size=UDim2.fromOffset((max or 3)*(size+gap)-gap,size);return f
end
local function ratioText(parent,a,b,size)
    local f=K.make('Frame',parent,{Name='Ratio',BackgroundTransparency=1})
    local x=K.num(f,'A',a,size,C.ink);local y=K.num(f,'B',' / '..b,size,C.muted)
    local wa,wb=K.width(a,size,x),K.width(' / '..b,size,y)
    K.box(x,0,0,wa+1,size+8);K.box(y,wa,0,wb+1,size+8);f.Size=UDim2.fromOffset(wa+wb+1,size+8);return f,wa+wb
end

local function header(hub,root,W,fmt,tab,onPick,prevTab)
    local items={{'campaign','캠페인','campaign'},{'challenges','도전과제','medal'}}
    local seg=K.segment(root,'GoalTabs',items,prevTab or tab,onPick,{size=fmt=='pc'and 16 or fmt=='ph'and 13 or 14,iconSize=fmt=='pc'and 16 or fmt=='ph'and 14 or 15})
    if fmt=='pc'then seg:place(40,80,300,46)elseif fmt=='ph'then seg:place(16,54,196,34)else seg:place(16,68,343,40)end
    if prevTab and prevTab~=tab then seg:select(tab,true)end
    local p=hub.account.progress or {};local ach=false;for _,c in ipairs(Claims.list(p))do if c.source=='achievement'then ach=true end end
    local cell=seg.cells[2];if cell then local ds=fmt=='pc'and 10 or fmt=='ph'and 8 or 9;K.dot(cell.button,'Dot20',ach,cell.button.Size.X.Offset-8,8,ds)end
    return seg
end
local function campaignTotals(hub,root,W,fmt,v)
    local total=v.total or 0;local ratio,chest=chestProgress(total)
    local right=fmt=='pc'and W-40 or W-16;local y=fmt=='pc'and 80 or fmt=='ph'and 54 or 116;local h=fmt=='pc'and 46 or fmt=='ph'and 34 or 24
    local ns=fmt=='pc'and 20 or 15;local is=fmt=='pc'and 18 or 15;local gap=fmt=='pc'and 14 or 8
    local lbl=fmt=='pt'and(chest and string.format('%d/%d',total-(select(3,chestProgress(total))),chest.stars-(select(3,chestProgress(total))))or '✓')or(chest and tostring(chest.stars)or '✓')
    local lw=K.width(lbl,fmt=='pc'and 14 or 12)
    local bw=fmt=='pc'and 120 or fmt=='ph'and 60 or 96;local cs=fmt=='pc'and 20 or 16
    local x=right-lw
    local l=K.num(root,'ChestNext',lbl,fmt=='pc'and 14 or 12,C.muted);K.box(l,x,y,lw+1,h)
    x-=8+bw;local bar=K.fillBar(root,'ChestBar',{p=ratio,fill=C.gold,track=C.raised});K.box(bar.frame,x,y+(h-6)/2,bw,6)
    x-=8+cs;local chestIcon=K.icon(root,'chest',cs,C.gold,'Chest');K.box(chestIcon,x,y+(h-cs)/2,cs,cs)
    if fmt~='pt'then
        x-=fmt=='pc'and 14 or 8;local sep=K.make('Frame',root,{Name='Sep',BackgroundColor3=C.line,BorderSizePixel=0});K.box(sep,x,y+h*.15,1,h*.7)
        x-=gap
        local r,rw=ratioText(root,tostring(total),tostring(Campaign.maxStars),ns);x-=rw;K.box(r,x,y+(h-ns-8)/2,rw+1,ns+8)
        x-=8+is;local st=K.icon(root,'starFill',is,C.gold,'Star');K.box(st,x,y+(h-is)/2,is,is)
    else
        local st=K.icon(root,'starFill',15,C.gold,'Star');K.box(st,16,y+(h-15)/2,15,15)
        local r,rw=ratioText(root,tostring(total),tostring(Campaign.maxStars),15);K.box(r,39,y+(h-23)/2,rw+1,23)
    end
end

local function chapterRow(hub,root,W,fmt,v,shown,redraw)
    local y=fmt=='pc'and 142 or fmt=='ph'and 98 or 148
    for i,ch in ipairs(Campaign.chapters)do
        local state=chapterState(v,ch.id);local on=ch.id==shown;local lock=state=='lock'
        local b=K.button(root,'Chapter'..ch.id,{kind='none',r=8},function(btn)
            if lock then K.refuse(btn);return end
            if hub.campaignChapter~=ch.id then hub.campaignChapter=ch.id
                local list=chapterStages(ch.id);local pick=list[1];for _,s in ipairs(list)do if not won(v,s.id)and unlocked(v,s.id)then pick=s;break end end
                hub.campaignPick=pick and pick.id;Step.step('goals','campaignChapter',{item='chapter_'..ch.id});redraw()end
        end)
        b.face.BackgroundColor3=on and C.accent or C.panel;b.face.BackgroundTransparency=on and(fmt=='pc'and .9 or .88)or 0;b.baseFill=b.face.BackgroundColor3;b.baseAlpha=b.face.BackgroundTransparency
        b.faceStroke.Enabled=true;b.faceStroke.Color=on and C.accent or C.line;b.faceStroke.Thickness=on and 2 or 1;b.faceStroke.Transparency=0;b.baseStroke=b.faceStroke.Color
        local f=b.face
        if fmt=='pc'then
            local cw=(W-80-6*8)/7;b:place(40+(i-1)*(cw+8),y,cw,50)
            local n=K.num(f,'No',tostring(ch.id),22,lock and C.dim or on and C.accent or C.ink);K.box(n,13,9,20,32)
            local nm=K.text(f,'Name',ch.name,13,lock and C.muted or C.ink,700);K.box(nm,13+K.width(tostring(ch.id),22,n)+10,0,cw-(13+K.width(tostring(ch.id),22,n)+10)-34,50)
            if state=='done'then local c=K.icon(f,'check',16,C.gold,'Done');K.box(c,cw-29,17,16,16)
            elseif lock then local c=K.icon(f,'lock',14,C.dim,'Lock');K.box(c,cw-28,18,14,14)end
            if lock then for _,o in ipairs({f})do o.BackgroundTransparency=1-(1-o.BackgroundTransparency)*.55 end;b.faceStroke.Transparency=.45 end
        elseif fmt=='ph'then
            b.minHit=40;b:place(16+(i-1)*40,y,34,34)
            if lock then local c=K.icon(f,'lock',13,C.dim,'Lock');K.box(c,10.5,10.5,13,13)
            else local n=K.num(f,'No',tostring(ch.id),14,C.ink,Enum.TextXAlignment.Center);K.box(n,0,0,34,34)end
            if state=='done'then local d=K.make('Frame',f,{Name='Done',BackgroundColor3=C.gold,BorderSizePixel=0});K.round(d,'pill');K.stroke(d,C.bg,2);K.box(d,25,-3,12,12);d.ZIndex=f.ZIndex+3 end
        else
            local cw=(343-6*6)/7;b:place(16+(i-1)*(cw+6),y,cw,44)
            if lock then local c=K.icon(f,'lock',15,C.dim,'Lock');K.box(c,(cw-15)/2,14.5,15,15)
            elseif state=='done'then local n=K.num(f,'No',tostring(ch.id),16,C.ink,Enum.TextXAlignment.Center);K.box(n,0,7,cw,18);local c=K.icon(f,'check',11,C.gold,'Done');K.box(c,(cw-11)/2,26,11,11)
            else local n=K.num(f,'No',tostring(ch.id),18,on and C.accent or C.ink,Enum.TextXAlignment.Center);K.box(n,0,0,cw,44)end
        end
    end
    local ch=Campaign.chapter(shown)
    if fmt=='ph'then local t=K.text(root,'ChapterName',string.format('%d장 %s',ch.id,ch.name),14,C.ink,800);K.box(t,16+7*40+4,y,112,34)
    elseif fmt=='pt'then local t=K.text(root,'ChapterName',string.format('%d장 %s',ch.id,ch.name),14,C.ink,800);K.box(t,16,198,300,18)end
end
local function nodePoints(W,H,fmt,n)
    local pts={}
    if fmt=='pt'then local top,bot=248,411
        for i=1,n do pts[i]=Vector2.new(i%2==0 and W*.66 or W*.34,top+(bot-top)*((i-1)/math.max(1,n-1)))end
    else
        local pl,pr=fmt=='pc'and 40 or 16,fmt=='pc'and 900 or 412;local ptop,pbot=fmt=='pc'and 230 or 150,fmt=='pc'and H-40 or H-14
        local pw=pr-pl
        for i=1,n do pts[i]=Vector2.new(pl+pw*((i-1)+.5)/n,ptop+(pbot-ptop)*((i-1)%2==1 and .62 or .30))end
    end
    return pts
end
local function fillEdge(holder,node,sound)
    local segs={};local k=1;while holder:FindFirstChild('Seg'..k)do table.insert(segs,holder:FindFirstChild('Seg'..k));k+=1 end
    for _,s in ipairs(segs)do s.BackgroundTransparency=1 end
    for i,s in ipairs(segs)do task.delay(.4*i/#segs,function()if s.Parent then s.BackgroundTransparency=0 end end)end
    task.delay(.4,function()
        if node and node.face.Parent then local s=node.scale;if node.pressTween then node.pressTween:Cancel()end;s.Scale=1.1
            node.pressTween=game:GetService('TweenService'):Create(s,TweenInfo.new(.14,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1});node.pressTween:Play()end
        if sound and holder.Parent then require(script.Parent.ToyAudio).play('milestone')end
    end)
end
local function stagePath(hub,root,W,H,fmt,v,list,pickId,onPick,newly)
    local pts=nodePoints(W,H,fmt,#list)
    local layer=K.make('Frame',root,{Name='Path',BackgroundTransparency=1,Size=UDim2.fromScale(1,1)})
    local thick=fmt=='pc'and 4 or 3
    local fills={}
    for i=1,#list-1 do
        local a,b=pts[i],pts[i+1];local gold=won(v,list[i].id)
        local c1,c2
        if fmt=='pt'then local my=(a.Y+b.Y)/2;c1,c2=Vector2.new(a.X,my),Vector2.new(b.X,my)else local mx=(a.X+b.X)/2;c1,c2=Vector2.new(mx,a.Y),Vector2.new(mx,b.Y)end
        local fresh=gold and newly and newly[list[i].id]and not K.reduced
        if not gold or fresh then K.curve(layer,'Edge'..i..(fresh and 'Was'or ''),a,c1,c2,b,thick,C.muted,.65,true,fmt=='pt'and 9 or 10)end
        if gold then local e=K.curve(layer,'Edge'..i,a,c1,c2,b,thick,C.gold,0,false);if fresh then table.insert(fills,{e,i+1})end end
    end
    local nodeButtons={}
    local nh=fmt=='pc'and 88 or fmt=='ph'and 54 or 40
    for i,s in ipairs(list)do
        local p=pts[i];local boss=s.boss==true;local isWon=won(v,s.id);local open=unlocked(v,s.id);local lock=not open
        local now=s.id==pickId
        local size=boss and(fmt=='pt'and 48 or math.floor(nh*1.18+.5))or nh
        if size%2==1 then size+=1 end
        local ring=(now and C.accent)or boss and C.gold or isWon and C.gold or C.line
        local b=K.button(root,'Stage_'..s.id,{kind='none',r='pill',hit=fmt=='pc'and 44 or 40},function(btn)if lock and not boss then K.refuse(btn)end;onPick(s.id)end)
        b.face.BackgroundColor3=now and NOW_BG or lock and C.panel or NODE_BG;b.face.BackgroundTransparency=0;b.baseFill=b.face.BackgroundColor3;b.baseAlpha=0
        b.faceStroke.Enabled=true;b.faceStroke.Color=ring;b.faceStroke.Thickness=(now or boss)and 3 or 2;b.faceStroke.Transparency=(isWon and not now and not boss)and .3 or 0;b.baseStroke=ring
        b:place(p.X-size/2,p.Y-size/2,size,size);nodeButtons[i]=b
        if now then
            local halo=K.make('Frame',root,{Name='Halo_'..s.id,BackgroundColor3=C.accent,BackgroundTransparency=.85,BorderSizePixel=0,ZIndex=b.button.ZIndex-1});K.round(halo,'pill')
            local hs=size+(fmt=='pt'and 10 or 12);K.box(halo,p.X-hs/2,p.Y-hs/2,hs,hs)
        end
        local f=b.face
        if lock and not boss then local ls=fmt=='pc'and 22 or fmt=='ph'and 16 or 15;local ic=K.icon(f,'lock',ls,C.dim,'Lock');K.box(ic,(size-ls)/2,(size-ls)/2,ls,ls);b.face.BackgroundTransparency=.4;b.faceStroke.Transparency=.4
        elseif boss then local cs=fmt=='pc'and 30 or 20;local ic=K.icon(f,'crown',cs,C.gold,'Crown');K.box(ic,(size-cs)/2,(size-cs)/2,cs,cs)
        else local t=K.num(f,'Id',s.id,fmt=='pc'and 24 or fmt=='ph'and 16 or 13,now and C.accent or C.ink,Enum.TextXAlignment.Center);K.box(t,0,0,size,size)end
        local r=size/2
        if fmt=='pt'then
            local left=i%2==0
            if isWon then local st=stars(root,Campaign.count((v.stars or {})[s.id]),3,11,2);local sw=st.Size.X.Offset;K.box(st,left and p.X-r-8-sw or p.X+r+8,p.Y-6,sw,11)
            elseif boss or s.event then local chip,cw=K.chip(root,'Kind_'..s.id,boss and '보스'or '이벤트',boss and 'gold'or 'muted',{size=11,height=18,icon=false,border=false})
                if not boss then chip.BackgroundColor3=FLAME;chip.BackgroundTransparency=.85;chip.Text.TextColor3=FLAME end
                K.box(chip,left and p.X-r-8-cw or p.X+r+8,p.Y-9,cw,18)end
        else
            local y=p.Y+r+(fmt=='pc'and 8 or 4)
            if isWon then local ss=fmt=='pc'and 15 or 11;local st=stars(root,Campaign.count((v.stars or {})[s.id]),3,ss,2);local sw=st.Size.X.Offset;K.box(st,p.X-sw/2,y,sw,ss);y+=ss+(fmt=='pc'and 4 or 2)end
            if fmt=='pc'then
                local nm=K.text(root,'Name_'..s.id,s.name,14,lock and C.muted or C.ink,700,Enum.TextXAlignment.Center);K.box(nm,p.X-80,y,160,16);y+=20
                if boss or s.event then local chip,cw=K.chip(root,'Kind_'..s.id,boss and '보스'or '이벤트',boss and 'gold'or 'muted',{size=12,height=20,icon=false,border=false})
                    if not boss then chip.BackgroundColor3=FLAME;chip.BackgroundTransparency=.85;chip.Text.TextColor3=FLAME_TEXT end
                    K.box(chip,p.X-cw/2,y,cw,20)end
            end
        end
    end
    for i,f in ipairs(fills)do fillEdge(f[1],nodeButtons[f[2]],i==1)end
end
local function stageCard(hub,root,W,H,fmt,v,s)
    local ch=Campaign.chapter(s.chapter);local mask=(v.stars or {})[s.id]or 0;local open=unlocked(v,s.id);local first=mask%2==0
    local x,y,w,h,pad
    if fmt=='pc'then x,y,w,h,pad=940,228,W-940-40,H-228-40,20 elseif fmt=='ph'then x,y,w,h,pad=420,98,W-420-12,H-98-10,10 else x,y,w,h,pad=12,445,351,156,13 end
    local card=K.panel(root,'StageCard','card',8);K.box(card,x,y,w,h)
    local mapW=fmt=='pt'and 72 or w-pad*2;local mapH=fmt=='pc'and 200 or fmt=='ph'and 78 or 72
    local map=K.map(card,'Map',s.map,mapW,mapH,6);K.box(map,pad,pad,mapW,mapH)
    local tx=fmt=='pt'and pad+mapW+10 or pad;local ty=fmt=='pt'and pad or pad+mapH+(fmt=='pc'and 16 or 8)
    local ns=fmt=='pc'and 24 or fmt=='ph'and 16 or 18
    local id=K.num(card,'Id',s.id,ns,C.accent);local iw=K.width(s.id,ns,id);K.box(id,tx,ty,iw+1,ns+12)
    local nm=K.text(card,'Name',s.name,ns,C.ink,800);K.box(nm,tx+iw+(fmt=='pc'and 10 or 8),ty,w-tx-iw-pad-10,ns+12)
    local rows={{1,'승리'},{2,fmt=='ph'and string.format('%d분 안에',ch.minutes)or string.format('%d분 안에 승리',ch.minutes)},{4,s.task and s.task.label or ''}}
    local rs=fmt=='pc'and 15 or 12;local step=fmt=='pc'and 28 or 18;local ry=ty+ns+12+(fmt=='pc'and 16 or 6)
    if fmt=='pt'then ry=ty+ns+12+4;step=16 end
    for i,r in ipairs(rows)do
        local got=mask//r[1]%2==1;local is=fmt=='pc'and 17 or fmt=='ph'and 13 or 12
        local ic=K.icon(card,got and 'starFill'or 'star',is,C.gold,'Star'..i);K.box(ic,tx,ry+(i-1)*step+1,is,is)
        local t=K.text(card,'Cond'..i,r[2],rs,i==3 and C.ink or C.muted,i==3 and 800 or 600);K.box(t,tx+is+(fmt=='pc'and 10 or 6),ry+(i-1)*step,w-tx-is-pad-10,rs+4)
    end
    local bh=fmt=='pc'and 64 or fmt=='ph'and 44 or 48;local by=h-pad-bh;if fmt=='pt'then by=99 end
    local ax=pad
    if first then
        local as=fmt=='pc'and 16 or fmt=='ph'and 13 or 14
        local cf,cw=K.amount(card,'Coins','coin','+'..tostring(ch.coins),as,C.gold);K.box(cf,ax,by+(bh-as)/2,cw,as);ax+=cw+(fmt=='pc'and 10 or 10)
        if fmt~='ph'then local xf,xw=K.amount(card,'XP','xp','+'..tostring(ch.xp),as,C.ink);K.box(xf,ax,by+(bh-as)/2,xw,as);ax+=xw+10 end
        ax+=fmt=='pc'and 2 or 0
    end
    local bx=fmt=='pt'and 126-x or ax;local bw=fmt=='pt'and 224 or w-pad-bx
    if fmt=='pc'and not first then bx=pad;bw=w-pad*2 end
    if open then
        local go=K.button(card,'Deploy',{kind='pri',text=first and '출전'or '다시 출전',size=fmt=='pc'and 22 or fmt=='ph'and 17 or 20},function(b)
            K.confirm(b,true);require(script.Parent.CampaignScreen).start(hub,s.id)end)
        go:place(bx,by,bw,bh)
        go:setEnabled(hub.account.ready==true and not hub.busy)
    else
        local prev=Campaign.stages[s.index-1]
        local need=ch.unlockStars and (v.total or 0)<ch.unlockStars and string.format('★ %d/%d',v.total or 0,ch.unlockStars)or prev and string.format('%s 승리',prev.id)or '잠김'
        local cs=fmt=='pc'and 16 or 13;local chh=fmt=='pc'and 32 or 26
        local chip,chw=K.chip(card,'Lock',need,'muted',{size=cs,height=chh,icon='lock'})
        K.box(chip,bx+(bw-chw)/2,by+(bh-chh)/2,chw,chh)
    end
    return card
end
local function drawCampaign(hub,root,W,H,fmt)
    local v=view(hub)
    hub.campaignPick=Campaign.stage(hub.campaignPick)and hub.campaignPick or v.next
    local pick=Campaign.stage(hub.campaignPick)or Campaign.stages[1]
    hub.campaignChapter=hub.campaignChapter or pick.chapter
    if pick.chapter~=hub.campaignChapter then local list=chapterStages(hub.campaignChapter);pick=list[1]or pick;hub.campaignPick=pick.id end
    local content=K.make('Frame',root,{Name='Campaign',BackgroundTransparency=1,Size=UDim2.fromScale(1,1)})
    local function redraw()hub:drawPage()end
    campaignTotals(hub,content,W,fmt,v)
    chapterRow(hub,content,W,fmt,v,hub.campaignChapter,redraw)
    local list=chapterStages(hub.campaignChapter)
    local cardHolder={}
    local function onPick(id)
        if hub.campaignPick==id then return end
        hub.campaignPick=id;Step.step('goals','campaignPick',{item='stage_'..tostring(id):gsub('%-','_')})
        redraw()
    end
    local seen=hub.campaignWonSeen;local newly={};local now={};local count=0
    for _,s in ipairs(Campaign.stages)do if won(v,s.id)then now[s.id]=true;if seen and not seen[s.id]then newly[s.id]=true;count+=1 end end end
    if count>1 then newly={}end
    if (hub.account.progress or {}).campaign~=nil then hub.campaignWonSeen=now end
    stagePath(hub,content,W,H,fmt,v,list,pick.id,onPick,newly)
    cardHolder.card=stageCard(hub,content,W,H,fmt,v,pick)
    Step.once('campaignView','goals','campaignView',{value=v.total or 0})
    return content
end

local function achTotals(root,W,fmt,list)
    local done,left=0,0;for _,a in ipairs(list)do if a.done then done+=1 else left+=a.medals end end
    local y=fmt=='pc'and 80 or fmt=='ph'and 54 or 116;local h=fmt=='pc'and 46 or fmt=='ph'and 34 or 24
    local ns=fmt=='pc'and 20 or 15
    if fmt=='pt'then
        local r,rw=ratioText(root,tostring(done),tostring(#list),15);K.box(r,16,y+(h-23)/2,rw+1,23)
        local cf,cw=K.amount(root,'Left','coin',Theme.commas(left),13,C.muted);K.box(cf,W-16-cw,y+(h-13)/2,cw,13)
        local bar=K.fillBar(root,'Done',{p=done/math.max(1,#list),fill=C.gold});K.box(bar.frame,16+rw+10,y+(h-6)/2,W-16-cw-10-(16+rw+10),6)
        return
    end
    local right=fmt=='pc'and W-40 or W-16;local x=right
    local cs=fmt=='pc'and 16 or 13
    local cf,cw=K.amount(root,'Left','coin',Theme.commas(left),cs,C.gold);x-=cw;K.box(cf,x,y+(h-cs)/2,cw,cs)
    local bw=fmt=='pc'and 180 or 70;x-=(fmt=='pc'and 14 or 8)+bw;local bar=K.fillBar(root,'Done',{p=done/math.max(1,#list),fill=C.gold});K.box(bar.frame,x,y+(h-6)/2,bw,6)
    local r,rw=ratioText(root,tostring(done),tostring(#list),ns);x-=(fmt=='pc'and 14 or 8)+rw;K.box(r,x,y+(h-ns-8)/2,rw+1,ns+8)
end
local function opened(hub,key)return hub.goalsOpen~=nil and hub.goalsOpen[key]==true end
local function drawChallenges(hub,root,W,H,fmt,stagger)
    local p=hub.account.progress or {};local list=p.achievementList or {};local shop=hub.callbacks.shop()
    local content=K.make('Frame',root,{Name='Challenges',BackgroundTransparency=1,Size=UDim2.fromScale(1,1)})
    achTotals(content,W,fmt,list)
    local order=table.clone(list)
    table.sort(order,function(a,b)if a.medals~=b.medals then return a.medals<b.medals end;if a.target~=b.target then return a.target<b.target end;return a.id<b.id end)
    local open,claim,done={},{},{}
    for _,a in ipairs(order)do if Claims.pending(p,'a:'..a.id)then table.insert(claim,a)elseif a.done then table.insert(done,a)else table.insert(open,a)end end
    local cw,cx,y0,foldH,rungH,gap,curH,railX
    if fmt=='pc'then cw=740;cx=math.floor((W-cw)/2);y0=200;foldH,rungH,gap,curH=40,52,10,176;railX=cx-34
    elseif fmt=='ph'then cw=520;cx=math.floor((W-cw)/2)+20;y0=100;foldH,rungH,gap,curH=30,36,6,118;railX=cx-22
    else cw=343;cx=16;y0=156;foldH,rungH,gap,curH=34,48,8,200 end
    local scroll=K.make('ScrollingFrame',content,{Name='Tower',BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.line,ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.fromOffset(0,0)})
    local bottom=fmt=='pt'and 601 or H-(fmt=='pc'and 24 or 8)
    K.box(scroll,0,y0-6,W,bottom-(y0-6))
    local oy=y0-6
    local y=y0;local nodes={};local rows={}
    local function fold(key,text,icon,gold)
        local b=K.button(scroll,'Fold_'..key,{kind='none',r=8},function()hub.goalsOpen=hub.goalsOpen or {};hub.goalsOpen[key]=not opened(hub,key);Step.step('goals','fold',{item=key,result=opened(hub,key)and 'opened'or 'closed'});hub:drawPage()end)
        b:place(cx,y-oy,cw,foldH);table.insert(rows,{b.button})
        local d=K.dashBox(b.face,'Dash',gold and C.gold or C.line,gold and .55 or 0,8,1);d.Size=UDim2.fromOffset(cw,foldH)
        local fs=fmt=='pc'and 14 or 12;local is=fmt=='pc'and 16 or 14
        local t=K.text(b.face,'Text',text,fs,gold and C.gold or C.muted,fmt=='pt'and 700 or 800);local tw=K.width(text,fs,t)
        local ic=K.icon(b.face,icon,is,gold and C.gold or C.muted,'Icon')
        local x0=math.floor((cw-is-8-tw)/2);K.box(ic,x0,(foldH-is)/2,is,is);K.box(t,x0+is+8,0,tw+2,foldH)
        table.insert(nodes,{y=y+foldH/2,color=gold and C.gold or C.line,size=8});y+=foldH+gap
    end
    local function rung(a,dim)
        local c=K.panel(scroll,'Rung_'..a.id,'card',8);K.box(c,cx,y-oy,cw,rungH);table.insert(rows,{c})
        local is=fmt=='pc'and 22 or fmt=='ph'and 16 or 18;local pad=fmt=='pc'and 18 or 12
        local ic=K.icon(c,'medal',is,C.muted,'Icon');K.box(ic,pad+1,(rungH-is)/2,is,is)
        local fs=fmt=='pc'and 16 or fmt=='ph'and 13 or 14;local cs=fmt=='pc'and 15 or fmt=='ph'and 12 or 13
        local af,aw=K.amount(c,'Coins','coin',tostring(a.medals),cs,dim and C.muted or C.gold);K.box(af,cw-pad-aw-1,(rungH-cs)/2,aw,cs)
        local nm=K.text(c,'Name',a.name,fs,C.ink,700);K.box(nm,pad+is+12,0,cw-pad-is-12-aw-pad-12,rungH)
        if dim then c.BackgroundTransparency=.5;nm.TextTransparency=.5;ic.ImageTransparency=.5;af.Value.TextTransparency=.5;af.Icon.ImageTransparency=.5;c.Stroke20.Transparency=.5 end
        table.insert(nodes,{y=y+rungH/2,color=dim and C.dim or C.ink,alpha=dim and 0 or .5,size=10});y+=rungH+gap
    end
    local function current(a)
        local ratio=a.target>0 and math.min(1,a.progress/a.target)or 0
        local x=cx-(fmt=='pt'and 4 or 6);local w=cw+(fmt=='pt'and 8 or 12);local h=curH
        local c=K.make('Frame',scroll,{Name='Current_'..a.id,BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0});K.round(c,12);K.box(c,x,y-oy,w,h)
        K.make('UIGradient',c,{Rotation=fmt=='pt'and 70 or 45,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(18,51,50)),ColorSequenceKeypoint.new(.6,Color3.fromRGB(18,26,36)),ColorSequenceKeypoint.new(1,Color3.fromRGB(18,26,36))})})
        K.stroke(c,C.accent,2,0,true)
        local row={c};table.insert(rows,row)
        if fmt~='pt'then local halo=K.make('Frame',scroll,{Name='Halo',BackgroundColor3=C.accent,BackgroundTransparency=.92,BorderSizePixel=0,ZIndex=c.ZIndex-1});K.round(halo,18);K.box(halo,x-6,y-oy-6,w+12,h+12);table.insert(row,halo)end
        local pad=fmt=='pc'and 24 or 14;local ms=fmt=='pc'and 112 or fmt=='ph'and 72 or 64
        local ringY=fmt=='pt'and 14 or (h-ms)/2
        local ring=K.ring(c,'Ring',ms,ratio,C.accent,6,C.raised);K.box(ring,pad,ringY,ms,ms)
        local inner=K.make('Frame',ring,{Name='Inner',BackgroundColor3=C.gold,BackgroundTransparency=.86,BorderSizePixel=0});K.round(inner,'pill')
        local isz=math.floor(ms*.56+.5);K.box(inner,(ms-isz)/2,(ms-isz)/2,isz,isz)
        if fmt=='pt'then inner.BackgroundTransparency=1 end
        local icz=math.floor(ms*(fmt=='pt'and .44 or .3)+.5);local ic=K.icon(ring,ACH_ICON[a.id]or 'medal',icz,C.gold,'Icon');K.box(ic,(ms-icz)/2,(ms-icz)/2,icz,icz)
        local tx=pad+ms+(fmt=='pc'and 24 or fmt=='ph'and 14 or 12);local rightW=fmt=='pc'and 160 or fmt=='ph'and 104 or 0
        local ns=fmt=='pc'and 26 or fmt=='ph'and 18 or 20;local ds=fmt=='pc'and 15 or fmt=='ph'and 12 or 13
        local ty=fmt=='pc'and 26 or fmt=='ph'and 16 or 27
        local nm=K.text(c,'Name',a.name,ns,C.ink,800);K.box(nm,tx,ty,w-tx-rightW-pad-16,ns+5)
        local dt=K.text(c,'Detail',a.detail,ds,C.muted,600);K.box(dt,tx,ty+ns+(fmt=='pc'and 11 or 7),w-tx-rightW-pad-16,ds+3)
        local pct=PERCENT[a.id];local vt=pct and string.format('%d%% / %d%%',a.progress,a.target)or string.format('%d / %d',a.progress,a.target)
        local vs=fmt=='pc'and 17 or fmt=='ph'and 13 or 14
        local vl=K.num(c,'Value',vt,vs,C.ink,Enum.TextXAlignment.Right);local vw=K.width(vt,vs,vl)
        local barH=fmt=='pc'and 9 or fmt=='ph'and 7 or 8
        local bx=fmt=='pt'and pad or tx;local by=fmt=='pc'and 107 or fmt=='ph'and 70 or 105
        local barW=(fmt=='pt'and w-pad*2 or w-tx-rightW-pad-16)-vw-10
        local bar=K.fillBar(c,'Progress',{p=ratio,fill=C.accent});K.box(bar.frame,bx,by,barW,barH)
        K.box(vl,bx+barW+10,by+barH/2-(vs+8)/2,vw+1,vs+8)
        local as=fmt=='pc'and 22 or fmt=='ph'and 16 or 20
        local af,aw=K.amount(c,'Reward','coin','+'..tostring(a.medals),as,C.gold)
        local bh=fmt=='pc'and 60 or fmt=='ph'and 44 or 52
        local go=K.button(c,'Go',{kind='pri',text='출전',size=fmt=='pc'and 21 or fmt=='ph'and 17 or 20},function(b)K.confirm(b,true);Step.step('goals','towerGo',{item=a.id});hub:closePage()end)
        if fmt=='pt'then K.box(af,pad,h-pad-bh+(bh-as)/2,aw,as);go:place(pad+aw+12,h-pad-bh,w-pad*2-aw-12,bh)
        else K.box(af,w-pad-aw,pad,aw,as);go:place(w-pad-rightW,h-pad-bh,rightW,bh)end
        table.insert(nodes,{y=y+h/2,color=C.accent,size=16,halo=true});y+=h+(fmt=='pc'and 12 or 8)
    end
    local function claimRung(a)
        local c=K.panel(scroll,'Claim_'..a.id,'card',8);K.box(c,cx,y-oy,cw,rungH+8);table.insert(rows,{c});c.BackgroundColor3=Color3.fromRGB(44,38,20);K.stroke(c,C.gold,2,0,true)
        local is=fmt=='pc'and 22 or 18;local ic=K.icon(c,'medal',is,C.gold,'Icon');K.box(ic,16,(rungH+8-is)/2,is,is)
        local nm=K.text(c,'Name',a.name,fmt=='pc'and 16 or 14,C.ink,700);K.box(nm,16+is+12,0,cw-16-is-12-120,rungH+8)
        local bh=fmt=='ph'and 36 or 44
        local b;b=Claims.button20(c,'ClaimAchievement','받기',fmt=='pc'and 17 or 15,function()Step.step('goals','claim',{item=a.id});Claims.claim(hub,'a:'..a.id,b.button)end)
        b:place(cw-100,(rungH+8-bh)/2,88,bh);if shop.busy then b:setEnabled(false)end
        table.insert(nodes,{y=y+(rungH+8)/2,color=C.gold,size=10});y+=rungH+8+gap
    end
    local farFrom=fmt=='pc'and 3 or 2
    if #open>farFrom then
        fold('achUp',string.format('%d칸 더',#open-farFrom),'up',false)
        if opened(hub,'achUp')then for i=#open,farFrom+1,-1 do rung(open[i],true)end end
    end
    if fmt=='pc'and open[3]then rung(open[3],true)end
    if open[2]then rung(open[2],false)end
    if open[1]then current(open[1])end
    for _,a in ipairs(claim)do claimRung(a)end
    if #open==0 and #claim==0 and #list>0 then
        local c=K.panel(scroll,'TowerTop','card',8);K.box(c,cx,y-oy,cw,64);table.insert(rows,{c});c.BackgroundColor3=Color3.fromRGB(44,38,20);K.stroke(c,C.gold,2,0,true)
        local chip,chw,chh=K.chip(c,'Done','완료','gold',{size=16,height=30,icon='check',border=false});K.box(chip,(cw-chw)/2,(64-chh)/2,chw,chh);y+=64+gap
    end
    if #done>0 then
        fold('achDone',string.format('깬 칸 %d개',#done),'check',true)
        if opened(hub,'achDone')then for i=#done,1,-1 do rung(done[i],false)end end
    end
    if fmt~='pt'and #nodes>1 then
        local top,bot=nodes[1].y,nodes[#nodes].y
        local line=K.make('Frame',scroll,{Name='Rail',BackgroundColor3=C.line,BorderSizePixel=0});K.box(line,railX,top-oy,2,bot-top)
        for i,n in ipairs(nodes)do
            if n.halo then local h=K.make('Frame',scroll,{Name='RailHalo'..i,BackgroundColor3=C.accent,BackgroundTransparency=.8,BorderSizePixel=0});K.round(h,'pill');K.box(h,railX+1-12,n.y-oy-12,24,24)end
            local d=K.make('Frame',scroll,{Name='RailDot'..i,BackgroundColor3=n.color,BackgroundTransparency=n.alpha or 0,BorderSizePixel=0});K.round(d,'pill');K.box(d,railX+1-n.size/2,n.y-oy-n.size/2,n.size,n.size)
        end
    end
    scroll.CanvasSize=UDim2.fromOffset(0,y-oy+8)
    if stagger then for i=1,math.min(6,#rows)do for _,o in ipairs(rows[i])do K.appear(o,{dy=8,t=.14,delay=(i-1)*.03,style=Enum.EasingStyle.Quad})end end end
    return content
end

function M.draw(hub,body,shop)
    for _,o in ipairs(body:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
    local root,W,H,fmt=K.screenRoot(hub,body,'Goals20')
    hub.goalTab=hub.goalTab or require(script.Parent.GoalsScreen).defaultTab(hub)
    if not ({campaign=1,challenges=1})[hub.goalTab]then hub.goalTab='challenges'end
    local screen=hub.goalTab=='campaign'and 'campaign'or 'goals';if hub.goalScreen~=screen then hub.goalScreen=screen;Step.emit('screen_viewed',{screen=screen,result='shown'})end
    local prev=hub.goalsShownTab;hub.goalsShownTab=hub.goalTab
    header(hub,root,W,fmt,hub.goalTab,function(key)if hub.goalTab~=key then hub.goalTab=key;Step.step('goals','tab',{item=key});hub:drawPage()end end,prev)
    if not hub.goals20Closed and hub.overlay then hub.goals20Closed=hub.overlay:GetPropertyChangedSignal('Visible'):Connect(function()if not hub.overlay.Visible then hub.goals20Fresh=nil end end)end
    local fresh=hub.goals20Fresh==nil;hub.goals20Fresh=false
    local content=hub.goalTab=='campaign'and drawCampaign(hub,root,W,H,fmt)or drawChallenges(hub,root,W,H,fmt,fresh and not(prev and prev~=hub.goalTab))
    if prev and prev~=hub.goalTab then K.appear(content,{dx=hub.goalTab=='challenges'and 24 or -24,t=.16})end
    Step.once('goalsView:'..hub.goalTab,'goals','view',{item=hub.goalTab})
    if not hub.goals20Resize then hub.goals20Resize=hub.root:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
        if hub.page=='missions'and not hub.goals20Redraw then hub.goals20Redraw=true;task.defer(function()hub.goals20Redraw=nil;if hub.page=='missions'then hub:drawPage()end end)end end)end
end
return M
