local Players=game:GetService('Players')
local K=require(script.Parent.Kit20)
local S=require(script.Parent.Sheet20)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local Rules=require(script.Parent.Parent.Core.OutgameRules)
local Records=require(script.Parent.Parent.Core.MatchRecords)
local C=K.colors
local M={}
local function pct(v)return string.format('%d%%',math.floor((v or 0)*100+.5))end
local function best(history)local b;for _,r in ipairs(history or {})do if type(r.place)=='number'and r.place>=1 then b=math.min(b or math.huge,r.place)end end;return b end
local function ago(t)return require(script.Parent.LiveWatchPage).ago(t,os.time())end
local function numbers(c,history,portrait)
    local top=best(history)
    if portrait then return {{'판',tostring(c.games or 0)},{'승리',tostring(c.wins or 0)},{'승률',pct(c.winRate)},{'최근 최고',top and string.format('%d위',top)or '–',gold=top~=nil,word=top~=nil}}end
    return {{'경기',tostring(c.games or 0)},{'승리',tostring(c.wins or 0),pct(c.winRate)},{'상위 10%',tostring(c.top10 or 0),pct(c.top10Rate)},{'최근 최고',top and string.format('%d위',top)or '–',gold=top~=nil,word=top~=nil}}
end
local function numberCard(parent,i,b,x,y,w,h,fmt)
    local pt,ph=fmt=='pt',fmt=='ph'
    local f=K.make('Frame',parent,{Name='Big_'..i,BackgroundColor3=C.panel,BorderSizePixel=0});K.round(f,10);K.box(f,x,y,w,h)
    local pad=pt and 12 or ph and 8 or 16;local py=pt and 10 or ph and 8 or 16
    local ls=pt and 12 or ph and 11 or 14;local vs=pt and 26 or ph and 22 or 40;local rs=ph and 11 or 15
    local l=K.text(f,'Label',b[1],ls,C.muted,700);K.box(l,pad,py,w-pad*2,ls+2)
    local v=K.num(f,'Value',b[2],vs,b.gold and C.gold or C.ink);local vw=K.width(b[2],vs,v)
    local vy=py+ls+2+(pt and 2 or ph and 0 or 4)
    if b.word then v.FontFace=K.fonts[800]or v.FontFace end
    K.box(v,pad,vy,vw+2,vs+(pt and 8 or 10))
    if b[3]then local r=K.num(f,'Rate',b[3],rs,C.muted);K.box(r,pad+vw+(ph and 6 or 8),vy+vs-rs-(ph and 0 or 2),80,rs+6)end
    return f
end
local function recentRow(parent,i,r,x,y,w,h,fmt)
    local pt,ph=fmt=='pt',fmt=='ph'
    local f=K.make('Frame',parent,{Name='Recent_'..i,BackgroundColor3=C.panel,BorderSizePixel=0});K.round(f,8);K.box(f,x,y,w,h)
    local won=r.place==1 or r.outcome=='won'and not r.place
    local placeText=r.place and string.format('#%d',r.place)or ({won='승리',lost='탈락',forfeit='기권'})[r.outcome]or '–'
    local fieldText=r.place and r.field and (pt and string.format('/%d',r.field)or string.format(' / %d',r.field))or ''
    local mode=Rules.modes[r.mode]or r.mode or ''
    local ps=pt and 16 or ph and 15 or 20;local fs=pt and 11 or ph and 11 or 14
    local function place(px,py,pw)
        local a=K.num(f,'Place',placeText,ps,won and C.gold or C.ink);local aw=K.width(placeText,ps,a);K.box(a,px,py,aw+1,ps+8)
        if not r.place then a.FontFace=K.fonts[800]or a.FontFace end
        if fieldText~=''then local b=K.num(f,'Field',fieldText,fs,C.muted);K.box(b,px+aw+(pt and 0 or 2),py+ps-fs-(pt and 0 or 1),pw-aw,fs+8)end
    end
    if pt then
        place(10,math.floor((h-ps-8)/2),56)
        local mapName=(Maps.meta(r.map or '')or {}).label or mode
        local n=K.text(f,'Map',mapName,14,C.ink,700);K.box(n,76,math.floor(h/2)-15,w-76-80,16)
        local m=K.text(f,'Mode',mode,11,C.muted,700);K.box(m,76,math.floor(h/2)+1,w-76-80,13)
        if r.xp then local a,aw=K.amount(f,'XP','xp','+'..tostring(r.xp),13,C.ink);K.box(a,w-10-aw,(h-13)/2,aw,13)end
        return f
    end
    local mw,mh=ph and 44 or 72,ph and 26 or 40;local pad=ph and 8 or 12
    local map=K.map(f,'Map',r.map,mw,mh,4);K.box(map,pad,(h-mh)/2,mw,mh)
    local tw=ph and 36 or 56;local pw=ph and 70 or 110;local g=ph and 10 or 16
    local t=K.text(f,'When',r.time and ago(r.time)or '',ph and 11 or 13,C.muted,600,Enum.TextXAlignment.Right);K.box(t,w-pad-tw-20,0,tw+20,h)
    place(w-pad-tw-g-pw,math.floor((h-ps-8)/2),pw)
    local m=K.text(f,'Mode',mode,ph and 12 or 15,C.ink,700);K.box(m,pad+mw+g,0,w-pad-tw-g-pw-g-(pad+mw+g),h)
    return f
end

function M.page(hub,body,p)
    for _,o in ipairs(body:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
    local root,W,H,fmt=K.screenRoot(hub,body,'Page20')
    local first=hub.first20=='records';hub.first20=nil
    local pt,ph=fmt=='pt',fmt=='ph'
    local data=p.records or Records.view({});local c=data.all or {}
    local me=Players.LocalPlayer
    local history=p.history or {}
    local ratio=(p.nextXP==0)and 1 or (tonumber(p.currentXP)or 0)/math.max(1,tonumber(p.nextXP)or 100)
    local rows={}
    if pt then
        local top=68
        local av=K.avatar(root,'Avatar',me.UserId,44,C.accent,2);K.box(av,16,top,44,44)
        local n=K.text(root,'Name',me.DisplayName,17,C.ink,800);n:SetAttribute('LocalizationSkip',true);K.box(n,70,top+1,W-70-16-48,20)
        local lv=K.num(root,'Level',string.format('Lv %d',p.level or 1),13,C.muted);K.box(lv,70,top+23,80,18)
        local bw=math.floor((W-32-8)/2);local by=top+56
        for i,b in ipairs(numbers(c,history,true))do numberCard(root,i,b,16+((i-1)%2)*(bw+8),by+((i-1)//2)*72,bw,64,fmt)end
        local ry=by+64*2+8+20
        local hd=K.text(root,'RecentHead','최근 경기',13,C.muted,800);K.box(hd,16,ry,200,15)
        local lift=0;local d=hub.deployment;if hub.data and hub.data.queue and d and d.bar and d.bar.Visible then lift=(d.barHeight or 48)+8 end
        local _,cb=S.band(H,lift)
        local list=S.scroll(root,'Recent',16,ry+24,W-32,cb-ry-24)
        local y=0
        for i,r in ipairs(history)do table.insert(rows,recentRow(list,i,r,0,y,W-32,48,fmt));y+=54 end
        if #history==0 then local e=K.text(list,'RecentEmpty','아직 기록 없음',14,C.muted,700,Enum.TextXAlignment.Center);K.box(e,0,8,W-32,40);y=56 end
        S.canvas(list,y);S.stagger(rows,first)
        return
    end
    local L,top=ph and 16 or 40,ph and 54 or 80;local R=L
    local pw=ph and 190 or 340
    local card=K.make('Frame',root,{Name='Profile',BackgroundColor3=C.panel,BorderSizePixel=0});K.round(card,10)
    local cp=ph and 12 or 24;local avS=ph and 60 or 112
    local av=K.avatar(card,'Avatar',me.UserId,avS,C.accent,2);K.box(av,(pw-avS)/2,cp,avS,avS)
    local ny=cp+avS+(ph and 8 or 18)
    local ns=ph and 15 or 22
    local name=K.text(card,'Name',me.DisplayName,ns,C.ink,800,Enum.TextXAlignment.Center);name:SetAttribute('LocalizationSkip',true);K.box(name,8,ny,pw-16,ns+4)
    local cy=ny+ns+4+(ph and 6 or 12)
    local tag=me:GetAttribute('CommanderClan');local chipH=ph and 18 or 22;local items={}
    if tag then local t=K.num(card,'Clan','['..tostring(tag)..']',ph and 12 or 15,C.muted);t:SetAttribute('LocalizationSkip',true);table.insert(items,{t,K.width(t.Text,t.TextSize,t)+2})end
    if me:GetAttribute('CommanderPermanent')==true then local ch,cw=K.chip(card,'Prime','프라임','prime',{size=11,height=chipH,icon='marshal'});table.insert(items,{ch,cw})end
    if me:GetAttribute('CommanderVIP')==true then local ch,cw=K.chip(card,'Vip','VIP','vip',{size=11,height=chipH,icon='vip'});table.insert(items,{ch,cw})end
    local total=0;for i,it in ipairs(items)do total+=it[2]+(i>1 and 6 or 0)end
    local x=math.floor((pw-total)/2)
    for _,it in ipairs(items)do it[1].Position=UDim2.fromOffset(x,cy);if it[1]:IsA('TextLabel')then it[1].Size=UDim2.fromOffset(it[2],chipH)end;x+=it[2]+6 end
    local ly=cy+(#items>0 and chipH or 0)+(ph and 10 or 22)
    local lvs=ph and 13 or 16
    local lv=K.num(card,'Level',string.format('Lv %d',p.level or 1),lvs,C.ink);local lvw=K.width(lv.Text,lvs,lv);K.box(lv,cp,ly,lvw+2,lvs+6)
    local bar=K.fillBar(card,'XP',{p=ratio,fill=C.accent,track=C.raised});K.box(bar.frame,cp+lvw+(ph and 8 or 10),ly+math.floor((lvs+6-6)/2),pw-cp*2-lvw-(ph and 8 or 10),6)
    local ch=ly+lvs+6+cp
    K.box(card,L,top,pw,ch)
    local rx=L+pw+(ph and 10 or 24);local rw=W-rx-R;local g=ph and 6 or 12;local bw=math.floor((rw-g*3)/4);local bh=ph and 62 or 104
    for i,b in ipairs(numbers(c,history,false))do numberCard(root,i,b,rx+(i-1)*(bw+g),top,i==4 and rw-3*(bw+g)or bw,bh,fmt)end
    local ry=top+bh+(ph and 10 or 20)
    local hd=K.text(root,'RecentHead','최근 경기',ph and 12 or 14,C.muted,800);K.box(hd,rx,ry,200,ph and 14 or 16)
    local lt=ry+(ph and 20 or 28);local rh=ph and 36 or 56;local rg=ph and 4 or 8
    local list=S.scroll(root,'Recent',rx,lt,rw,H-(ph and 8 or 24)-lt)
    local y=0
    for i,r in ipairs(history)do table.insert(rows,recentRow(list,i,r,0,y,rw,rh,fmt));y+=rh+rg end
    if #history==0 then local e=K.text(list,'RecentEmpty','아직 기록 없음',15,C.muted,700,Enum.TextXAlignment.Center);K.box(e,0,8,rw,40);y=56 end
    S.canvas(list,y);S.stagger(rows,first)
end

function M.draw(_hub,body,w,y,p)
    local data=p.records or Records.view({});local c=data.all or {}
    local phone=w<520;local fmt=phone and 'ph'or 'pc'
    local cols=phone and 2 or 4;local g=phone and 8 or 12;local bw=math.floor((w-g*(cols-1))/cols);local bh=phone and 72 or 104
    for i,b in ipairs(numbers(c,p.history,false))do numberCard(body,i,b,(i-1)%cols*(bw+g),y+math.floor((i-1)/cols)*(bh+g),bw,bh,fmt)end
    y+=math.ceil(4/cols)*(bh+g)+(phone and 4 or 8)
    local hd=K.text(body,'RecentHead','최근 경기',phone and 13 or 14,C.muted,800);K.box(hd,0,y,200,18);y+=28
    local shown=0
    for _,r in ipairs(p.history or {})do if shown<5 then shown+=1;recentRow(body,shown,r,0,y,w,phone and 44 or 56,fmt);y+=(phone and 44 or 56)+8 end end
    if shown==0 then local e=K.text(body,'RecentEmpty','아직 기록 없음',15,C.muted,700,Enum.TextXAlignment.Center);K.box(e,0,y,w,40);y+=48 end
    return y
end
return M
