local UI=require(script.Parent.Theme)
local M={}
local names={settled='정착',attack='출격',city='도시 완공',allied='동맹 체결',support='동료 지원',nuclear='핵 발사',underAttack='방어전',won='승리',lost='탈락',forfeit='기권',expired='연결 종료'}
local function clock(seconds)return string.format('%02d:%02d',math.floor(seconds/60),math.floor(seconds%60))end
function M.draw(parent,recap,width)
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
        if event.kind=='nuclear'then text=text..' '..(({AtomBomb='원자폭탄',HydrogenBomb='수소폭탄',MIRV='다탄두'})[event.value]or '')end
        local row=UI.label(parent,'Event'..i,text,16,event.kind=='nuclear'and UI.colors.danger or UI.colors.ink);UI.box(row,68,y,width-76,30);y+=38
    end
    if #events==0 then local empty=UI.label(parent,'Empty','첫 출격부터 기록이 남아요.',16,UI.colors.muted);UI.box(empty,4,y,width-8,50);y+=58 end
    parent.CanvasSize=UDim2.fromOffset(0,y+12)
end
return M
