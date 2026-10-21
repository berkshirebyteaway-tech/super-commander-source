local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.OutgameIcons)
local Rules=require(script.Parent.Parent.Core.OutgameRules)
local Records=require(script.Parent.Parent.Core.MatchRecords)
local M={}
local C=UI.colors
local function text(parent,name,value,x,y,w,h,size,color)local l=UI.label(parent,name,value,size or 14,color);UI.box(l,x,y,w,h);l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd;return l end
local function pct(v)return string.format('%d%%',math.floor((v or 0)*100+.5))end
local function clock(s)s=math.floor(s or 0);return string.format('%d:%02d',s//60,s%60)end
local CELLS={{'troops','사용한 병력','friends'},{'conquered','점령한 국가','ranked'},{'built','지은 건물','fields'},{'nukes','사용한 핵','deploy'},
    {'warships','소환한 군함','watch'},{'gold','번 골드','reward'},{'alliances','맺은 동맹','friends'},{'intercepts','요격한 미사일','marshal'}}
local STYLE={{'expansion','확장'},{'build','건설'},{'diplomacy','외교'},{'naval','해군'},{'nuke','핵'}}
local MODE_COLOR={single=C.accent,pvp=C.peach,coop=C.lilac,custom=C.muted}
local function tabs(hub,body,list,key,y,w,draw)
    local tw=(w-(#list-1)*6)/#list
    for i,v in ipairs(list)do
        local on=hub[key]==v[1]
        local b=UI.button(body,'Tab_'..key..'_'..v[1],v[2],function()hub[key]=v[1];draw()end,on);UI.box(b,(i-1)*(tw+6),y,tw,48)
        if on then b.BackgroundColor3=C.ink;b.TextColor3=C.bg end
    end
    return 56
end
function M.draw(hub,body,w,y,p)
    local redraw=function()hub:drawPage()end
    local phone=w<520
    local data=p.records or Records.view({})
    local styleName=hub.recordOther and '플레이 스타일'or '내 스타일'
    hub.recordTab=hub.recordTab or 'all';hub.recordSection=hub.recordSection or 'totals';hub.recordAvg=hub.recordAvg or false
    y+=tabs(hub,body,{{'all','전체'},{'public','공개 게임'},{'ranked','랭크전'}},'recordTab',y,w,redraw)
    local c=data[hub.recordTab]or data.all
    local big={{'판수',tostring(c.games),nil,'끝까지 마친 경기'},{'승리',tostring(c.wins),pct(c.winRate),'개인전 1위, 팀전 팀 승리'},
        {'상위 10%',tostring(c.top10),pct(c.top10Rate),'참가자 수 대비 상위 10%'},{'평균 생존',clock(c.avgSeconds),nil,'한 판에 머문 시간'}}
    local cols=phone and 2 or 4;local bw=(w-(cols-1)*8)/cols;local bh=phone and 92 or 104
    for i,b in ipairs(big)do
        local card=UI.panel(body,'Big_'..i);UI.box(card,(i-1)%cols*(bw+8),y+math.floor((i-1)/cols)*(bh+8),bw,bh)
        text(card,'Label',b[1],12,8,bw-24,20,13,C.muted)
        local v=text(card,'Value',b[2],12,28,bw-24,36,phone and 26 or 30,i==2 and C.accent or C.ink);UI.display(v);v.TextWrapped=false
        if b[3]then local s=text(card,'Rate',b[3],bw-74,34,62,24,15,C.gold);s.TextXAlignment=Enum.TextXAlignment.Right end
        text(card,'Rule',b[4],12,bh-26,bw-24,18,13,C.muted)
    end
    y+=math.ceil(#big/cols)*(bh+8)+8
    local function section(id)return not phone or hub.recordSection==id end
    if phone then y+=tabs(hub,body,{{'totals','누적 기록'},{'style',styleName},{'recent','최근 경기'}},'recordSection',y,w,redraw)end
    if section('totals')then
        local segW=phone and 76 or 88
        local head=text(body,'TotalsHead','누적 기록',2,y+4,w-segW*2-12,32,18,C.ink);head.Font=Enum.Font.BuilderSansBold
        for i,v in ipairs({{false,'누적'},{true,'판당 평균'}})do
            local on=hub.recordAvg==v[1]
            local b=UI.button(body,i==1 and 'AvgToggle_total'or 'AvgToggle',v[2],function()if hub.recordAvg~=v[1]then hub.recordAvg=v[1];redraw()end end,on)
            UI.box(b,w-segW*(3-i),y,segW,40);b.TextSize=13
            if on then b.BackgroundColor3=C.ink;b.TextColor3=C.bg end
        end
        y+=50
        local tc=phone and 2 or 4;local tw=(w-(tc-1)*8)/tc
        for i,cell in ipairs(CELLS)do
            local card=UI.panel(body,'Total_'..cell[1]);UI.box(card,(i-1)%tc*(tw+8),y+math.floor((i-1)/tc)*84,tw,76)
            UI.box(Icons.create(card,cell[3],22,C.accent),12,12,22,22)
            text(card,'Name',cell[2],42,10,tw-50,22,13,C.muted)
            local n=c[cell[1]]or 0;if hub.recordAvg then n=c.games>0 and n/c.games or 0 end
            local shown=cell[1]=='troops'and UI.number(math.floor(n/10))or hub.recordAvg and (n>=10 and UI.number(math.floor(n))or string.format('%.1f',n))or UI.number(math.floor(n))
            local v=text(card,'Value',shown,42,34,tw-50,32,22,C.ink);UI.display(v)
        end
        y+=math.ceil(#CELLS/tc)*84+8
        local bh2=text(body,'BestHead','최고 기록',2,y,w,32,18,C.ink);bh2.Font=Enum.Font.BuilderSansBold;y+=40
        local best=data.best or {};local list={{'최대 영토',pct(best.peak)},{'한 판 최다 점령',string.format('%d개국',best.conquered or 0)},{'최다 동시 군함',string.format('%d척',best.fleet or 0)}}
        local bcw=(w-16)/3
        for i,b in ipairs(list)do
            local card=UI.panel(body,'Best_'..i);UI.box(card,(i-1)*(bcw+8),y,bcw,72)
            text(card,'Name',b[1],12,8,bcw-24,20,13,C.muted);local v=text(card,'Value',b[2],12,30,bcw-24,32,22,C.gold);UI.display(v)
        end
        y+=82
    end
    if section('style')then
        local st=c.style or Records.style(c)
        local sh=text(body,'StyleHead',styleName,2,y,w-160,32,18,C.ink);sh.Font=Enum.Font.BuilderSansBold
        if st.name then local badge=UI.pill(body,'StyleBadge',st.name,C.accent);UI.box(badge,w-150,y+2,148,28)end
        y+=42
        local labelW=56;local barW=w-labelW-70
        for i,s in ipairs(STYLE)do
            local ratio=(st.bars and st.bars[s[1]])or 0
            text(body,'StyleName_'..s[1],s[2],2,y,labelW,24,14,C.ink)
            local track=UI.make('Frame',body,{Name='StyleTrack_'..s[1],BackgroundColor3=C.raised,BorderSizePixel=0});UI.corner(track,3);UI.box(track,labelW+6,y+6,barW,12)
            local fill=UI.make('Frame',track,{Name='Fill',BackgroundColor3=s[1]==st.type and C.accent or C.ice,BorderSizePixel=0,Size=UDim2.fromScale(math.clamp(ratio/2,0,1),1)});UI.corner(fill,3)
            UI.make('Frame',track,{Name='Average',BackgroundColor3=C.ink,BorderSizePixel=0,Position=UDim2.new(.5,-1,0,-3),Size=UDim2.new(0,2,1,6),ZIndex=3})
            local val=text(body,'StyleValue_'..s[1],string.format('x%.1f',ratio),labelW+barW+12,y,56,24,13,C.muted);val.TextXAlignment=Enum.TextXAlignment.Right
            y+=32
        end
        text(body,'StyleNote',c.games>0 and (hub.recordOther and '흰 선 = 평균 지휘관, 가장 높은 막대가 이 지휘관의 유형'or '흰 선 = 평균 지휘관, 가장 높은 막대가 내 유형')or hub.recordOther and '아직 마친 경기가 없어요'or '경기를 마치면 내 스타일이 나타나요',2,y,w,22,13,C.muted);y+=32
    end
    if section('recent')then
        local rh=text(body,'RecentHead','최근 경기',2,y,w,32,18,C.ink);rh.Font=Enum.Font.BuilderSansBold;y+=40
        local shown=0
        for _,r in ipairs(p.history or {})do
            local fits=hub.recordTab=='all'or hub.recordTab=='ranked'and r.ranked or hub.recordTab=='public'and not r.ranked and (r.mode=='pvp'or r.mode=='coop')
            if fits and shown<5 then shown+=1
                local row=UI.panel(body,'Recent_'..shown);UI.box(row,0,y,w,64)
                require(script.Parent.EdgeMask).fit(UI.make('Frame',row,{Name='Mode',BackgroundColor3=MODE_COLOR[r.mode]or C.muted,BorderSizePixel=0,Size=UDim2.new(0,4,1,0)}))
                local place=r.place and r.field and string.format('#%d / %d',r.place,r.field)or ({won='승리',lost='탈락',forfeit='기권'})[r.outcome]or '—'
                local pl=text(row,'Place',place,16,8,110,28,20,r.outcome=='won'and C.gold or C.ink);UI.display(pl)
                text(row,'Mode',Rules.modes[r.mode]or r.mode,16,38,110,20,13,C.muted)
                if r.top10 then local chip=UI.pill(row,'Top10','상위 10%',C.gold);UI.box(chip,128,phone and 36 or 18,76,phone and 22 or 26);chip.TextSize=13 end
                local detail=string.format('점령 %d  병력 %s',r.conquered or 0,UI.number(math.floor((r.troops or 0)/10)))
                local dx=phone and 128 or 212
                local d=text(row,'Detail',detail,dx,8,w-dx-12,24,14,C.ink);d.TextXAlignment=Enum.TextXAlignment.Right
                local t=text(row,'When',string.format('%d분',math.floor((r.seconds or 0)/60)),212,34,w-224,20,13,C.muted);t.TextXAlignment=Enum.TextXAlignment.Right
                y+=72
            end
        end
        if shown==0 then local e=text(body,'RecentEmpty','아직 기록 없음',2,y,w,40,15,C.muted);e.TextXAlignment=Enum.TextXAlignment.Center;y+=48 end
    end
    return y
end
return M
