local UI=require(script.Parent.Theme)
local M={}
local names={settled='정착',attack='출격',city='도시 완공',allied='동맹 체결',support='동료 지원',nuclear='핵 발사',underAttack='방어전',won='승리',lost='탈락',forfeit='기권',expired='연결 종료'}
local bombs={AtomBomb='원자폭탄',HydrogenBomb='수소폭탄',MIRV='다탄두'}
local function clock(seconds)return string.format('%02d:%02d',math.floor(seconds/60),math.floor(seconds%60))end
local ICON={settled={'k','map'},attack={'h','Sword'},city={'h','City'},allied={'h','Alliance'},support={'k','people'},nuclear={'h','AtomBomb'},
    underAttack={'h','Target'},won={'h','Crown'},lost={'k','x'},forfeit={'k','back'},expired={'k','clock'}}
local function draw20(parent,recap,width)
    local K=require(script.Parent.Kit20);local Hot=require(script.Parent.HotbarIcons);local C=K.colors
    local points=recap and recap.points or {};local events=recap and recap.events or {}
    local small=width<420;local x0=4;local cw=width-8
    local title=K.text(parent,'TerritoryTitle','영토 추이',small and 16 or 18,C.ink,800);K.box(title,x0,0,cw,28)
    local chartH=small and 104 or 132
    local chart=K.panel(parent,'TerritoryChart','card',10);K.box(chart,x0,36,cw,chartH);chart.ClipsDescendants=false
    K.stroke(chart,C.line,1,0,true)
    local peak,peakAt=0,1;for i,p in ipairs(points)do if p[2]>peak then peak=p[2];peakAt=i end end;local scale=math.max(.05,peak)
    local pad=12;local gw,gh=cw-pad*2,chartH-pad*2
    for i=1,3 do local g=K.make('Frame',chart,{Name='Grid',BackgroundColor3=C.line,BackgroundTransparency=.4,BorderSizePixel=0});K.box(g,pad,pad+math.floor(gh*i/4),gw,1)end
    local duration=points[#points]and points[#points][1]or 1
    local function at(p)return pad+p[1]/math.max(1,duration)*gw,pad+gh-p[2]/scale*gh end
    local previous
    for _,point in ipairs(points)do
        local x,y=at(point)
        if previous then local seg=K.line(chart,'Segment',previous.X,previous.Y,x,y,2,C.accent);seg.Name='Segment'end
        previous=Vector2.new(x,y)
    end
    if points[peakAt]and peak>0 then
        local px,py=at(points[peakAt])
        local dot=K.make('Frame',chart,{Name='Peak',AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=C.accent,BorderSizePixel=0});K.round(dot,'pill');K.stroke(dot,C.panel,2);K.box(dot,px,py,8,8)
        local share=string.format('%.1f%%',peak*100)
        local tag=K.num(chart,'PeakValue',share,12,C.accent,Enum.TextXAlignment.Left);local tw=K.width(share,12,tag)
        local tx=px+8;if tx+tw>cw-6 then tx=px-8-tw end
        K.box(tag,tx,math.max(2,py-18),tw+2,16)
    end
    local axis=K.text(parent,'TerritoryAxis',string.format('최대 %.1f%%  %s',peak*100,clock(duration)),12,C.muted,700);K.box(axis,x0,36+chartH+6,cw,18)
    axis.TextXAlignment=Enum.TextXAlignment.Right
    local start=K.num(parent,'TerritoryStart','00:00',12,C.dim);K.box(start,x0,36+chartH+6,60,18)
    local hy=36+chartH+34
    local heading=K.text(parent,'EventsTitle','주요 사건',small and 16 or 18,C.ink,800);K.box(heading,x0,hy,cw,28)
    local y=hy+36;local rows={}
    local rh=44
    for i,event in ipairs(events)do
        local nuke=event.kind=='nuclear'
        local row=K.make('Frame',parent,{Name='EventRow'..i,BackgroundColor3=C.panel,BorderSizePixel=0});K.round(row,8);K.stroke(row,nuke and C.danger or C.line,1,nuke and .5 or 0,true);K.box(row,x0,y,cw,rh)
        local time=K.num(row,'EventTime'..i,clock(event.seconds),13,C.muted);K.box(time,12,0,48,rh);time.Name='EventTime'..i
        local ink=nuke and C.danger or event.kind=='won'and C.accent or (event.kind=='lost'or event.kind=='forfeit'or event.kind=='expired')and C.muted or C.ink
        local ic=ICON[event.kind];local icon
        if ic then icon=ic[1]=='h'and Hot.create(row,ic[2],18,ink)or K.icon(row,ic[2],18,ink,'Icon');K.box(icon,64,(rh-18)/2,18,18)end
        local text=names[event.kind]or event.kind
        if nuke then text=text..' '..(bombs[event.value]or '')end
        local l=K.text(row,'Event'..i,text,14,ink,800);K.box(l,92,0,cw-104,rh)
        table.insert(rows,row);y+=rh+6
    end
    if #events==0 then local empty=K.text(parent,'Empty','첫 출격부터 기록이 남아요.',14,C.muted,700,Enum.TextXAlignment.Center);K.box(empty,x0,y,cw,44);y+=52 end
    parent.CanvasSize=UDim2.fromOffset(0,y+12)
    if not K.reduced then for i,o in ipairs(rows)do if i>6 then break end;K.appear(o,{dy=8,t=.14,delay=(i-1)*.03})end end
end
function M.draw(parent,recap,width)
    if require(script.Parent.Lobby20).ENABLED then draw20(parent,recap,width);return end
    local points=recap and recap.points or {};local events=recap and recap.events or {}
    local title=UI.label(parent,'TerritoryTitle','영토 추이',18);UI.box(title,4,0,width-8,28)
    local chart=UI.make('Frame',parent,{Name='TerritoryChart',BackgroundColor3=UI.colors.bg,BorderSizePixel=0,ClipsDescendants=true});UI.box(chart,4,36,width-8,112)
    local peak=0;for _,p in ipairs(points)do peak=math.max(peak,p[2])end;local scale=math.max(.05,peak)
    for i=1,3 do UI.make('Frame',chart,{Name='Grid',Position=UDim2.new(0,0,0,i*28),Size=UDim2.new(1,0,0,1),BackgroundColor3=UI.colors.line,BorderSizePixel=0})end
    local duration=points[#points]and points[#points][1]or 1
    local previous
    for _,point in ipairs(points)do
        local pos=Vector2.new(4+point[1]/math.max(1,duration)*(width-16),108-point[2]/scale*100)
        if previous then
            local delta=pos-previous;local line=UI.make('Frame',chart,{Name='Segment',AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=UI.colors.accent,BorderSizePixel=0,Rotation=math.deg(math.atan2(delta.Y,delta.X))})
            UI.box(line,(pos.X+previous.X)/2,(pos.Y+previous.Y)/2,delta.Magnitude,2)
        end
        previous=pos
    end
    local axis=UI.label(parent,'TerritoryAxis',string.format('최대 %.1f%%  %s',peak*100,clock(duration)),14,UI.colors.muted);UI.box(axis,4,150,width-8,24)
    local heading=UI.label(parent,'EventsTitle','주요 사건',18);UI.box(heading,4,184,width-8,28)
    local y=220
    for i,event in ipairs(events)do
        local time=UI.label(parent,'EventTime'..i,clock(event.seconds),14,UI.colors.muted);UI.box(time,4,y,56,30)
        local text=names[event.kind]or event.kind
        if event.kind=='nuclear'then text=text..' '..(bombs[event.value]or '')end
        local row=UI.label(parent,'Event'..i,text,16,event.kind=='nuclear'and UI.colors.danger or UI.colors.ink);UI.box(row,68,y,width-76,30);y+=38
    end
    if #events==0 then local empty=UI.label(parent,'Empty','첫 출격부터 기록이 남아요.',16,UI.colors.muted);UI.box(empty,4,y,width-8,50);y+=58 end
    parent.CanvasSize=UDim2.fromOffset(0,y+12)
end
return M
