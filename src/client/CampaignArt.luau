local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.HotbarIcons)
local M={}
local P={ocean=Color3.fromRGB(14,34,54),land=Color3.fromRGB(58,72,88),wall=Color3.fromRGB(24,31,41),me=Color3.fromRGB(54,226,208),
    enemy=Color3.fromRGB(255,82,82),ally=Color3.fromRGB(91,212,107),other=Color3.fromRGB(139,92,246),gold=Color3.fromRGB(245,196,81),
    warn=Color3.fromRGB(255,173,66),fallout=Color3.fromRGB(154,162,74),muted=Color3.fromRGB(138,151,168),ink=Color3.fromRGB(238,242,246),
    plain=Color3.fromRGB(46,106,74),mountain=Color3.fromRGB(122,93,74)}
M.colors=P
local Z={fill=1,line=2,pad=3,icon=4,text=5}
local function frame(f,name,x,y,w,h,color,alpha,z)
    local o=Instance.new('Frame');o.Name=name;o.BackgroundColor3=color;o.BackgroundTransparency=alpha or 0;o.BorderSizePixel=0
    o.Position=UDim2.fromOffset(x,y);o.Size=UDim2.fromOffset(math.max(0,w),math.max(0,h));o.ZIndex=z or Z.fill;o.Parent=f;return o
end
local function corner(o,r)local c=Instance.new('UICorner');c.CornerRadius=r and UDim.new(0,r)or UDim.new(.5,0);c.Parent=o;return o end
local function stroke(o,color,t,alpha)
    local s=Instance.new('UIStroke');s.Color=color;s.Thickness=t or 1;s.Transparency=alpha or 0;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=o;return o
end
local function area(f,name,x,y,w,h,color,alpha)return stroke(corner(frame(f,name,x,y,w,h,color,alpha or .55),6),color,1.5,.1)end
local function sea(f,w,h)return corner(frame(f,'Sea',0,0,w,h,P.ocean,0),8)end
local function disc(f,name,cx,cy,r,color,alpha,z)return corner(frame(f,name,cx-r,cy-r,r*2,r*2,color,alpha,z))end
local function ring(f,name,cx,cy,r,color,fill)local o=disc(f,name,cx,cy,r,color,fill or 1,Z.line);stroke(o,color,1.5,.15);return o end
local function line(f,name,x1,y1,x2,y2,color,t,alpha)
    local dx,dy=x2-x1,y2-y1
    local o=frame(f,name,0,0,math.sqrt(dx*dx+dy*dy),t or 2,color,alpha,Z.line);o.AnchorPoint=Vector2.new(.5,.5)
    o.Position=UDim2.fromOffset((x1+x2)/2,(y1+y2)/2);o.Rotation=math.deg(math.atan2(dy,dx));return o
end
local function arrow(f,name,x1,y1,x2,y2,color,t)
    t=t or 2;line(f,name,x1,y1,x2,y2,color,t)
    local a=math.atan2(y2-y1,x2-x1);local l=5+t*2
    for i,s in ipairs({-1,1})do local b=a+math.pi+s*.55;line(f,name..'Head'..i,x2,y2,x2+math.cos(b)*l,y2+math.sin(b)*l,color,t)end
end
local function route(f,name,x1,y1,x2,y2,lift,color,n)
    n=n or 10
    for i=0,n do local t=i/n;disc(f,name..i,x1+(x2-x1)*t,y1+(y2-y1)*t-lift*4*t*(1-t),1.6,color,0,Z.line)end
    return (x1+x2)/2,(y1+y2)/2-lift
end
local function cross(f,name,cx,cy,s,color)line(f,name..'A',cx-s,cy-s,cx+s,cy+s,color,3);line(f,name..'B',cx-s,cy+s,cx+s,cy-s,color,3)end
local function icon(f,key,cx,cy,size,color)
    local i=Icons.create(f,key:match('^[^#]+'),size,color);i.Name='Icon_'..key;i.AnchorPoint=Vector2.new(.5,.5);i.Position=UDim2.fromOffset(cx,cy);i.ZIndex=Z.icon
    for _,d in ipairs(i:GetDescendants())do if d:IsA('GuiObject')then d.ZIndex=Z.icon end end
    return i
end
local function badge(f,key,cx,cy,s,color)disc(f,'Pad_'..key,cx,cy,s*.66,P.wall,.08,Z.pad);return icon(f,key,cx,cy,s,color)end
local function text(f,name,s,cx,y,w,size,color)
    local l=UI.label(f,name,s,size or 12,color or P.ink);UI.box(l,cx-w/2,y,w,(size or 12)+4)
    l.TextXAlignment=Enum.TextXAlignment.Center;l.TextWrapped=false;l.ZIndex=Z.text;return l
end
local function chip(f,name,s,x,y,color)
    local l=text(f,name,s,x,y,48,12,color);l.BackgroundColor3=P.wall;l.BackgroundTransparency=.05;corner(l,5);return l
end
local function measure(h)local s=math.clamp(math.floor(h*.2),16,26);local mh=h-18;return s,mh,mh+2 end
local ART={}
function ART.ratio(f,w,h)
    local s,mh,ly=measure(h);local cw=(w-16)/2
    for i=1,2 do
        local x=(i-1)*(cw+16);local all=i==1
        area(f,'Me'..i,x,0,cw*.4,mh,P.me,all and .88 or .55);area(f,'Enemy'..i,x+cw*.6,0,cw*.4,mh,P.enemy)
        if all then arrow(f,'All',x+cw*.2,mh*.5,x+cw*.74,mh*.5,P.me,6)
        else for k,yy in ipairs({.25,.5,.75})do arrow(f,'Small'..k,x+cw*.3,mh*yy,x+cw*.68,mh*yy,P.me,2)end end
        text(f,'Label'..i,all and '국경이 비어요'or '작게 자주',x+cw/2,ly,cw,12,all and P.enemy or P.me)
    end
end
function ART.defense(f,w,h)
    local s,mh,ly=measure(h);local bx=w*.5
    area(f,'Me',0,0,bx-2,mh,P.me);area(f,'Enemy',bx+2,0,w-bx-2,mh,P.enemy)
    ring(f,'Range',bx-s,mh*.5,mh*.46,P.me,.85);badge(f,'DefensePost',bx-s,mh*.5,s,P.ink)
    for k,yy in ipairs({.22,.5,.78})do arrow(f,'Hit'..k,w*.92,mh*yy,bx+8,mh*(.5+(yy-.5)*.6),P.enemy,2)end
    text(f,'Post','방어 시설',bx*.5,ly,bx,12,P.muted);text(f,'Loss','병력 5배 손실',bx+(w-bx)/2,ly,w-bx,12,P.enemy)
end
local function rail(f,x1,x2,y)
    line(f,'Rail',x1,y,x2,y,P.muted,3)
    local n=math.floor((x2-x1)/10);for i=1,n-1 do line(f,'Tie'..i,x1+i*10,y-4,x1+i*10,y+4,P.muted,2,.3)end
end
local function train(f,x,y)for i=0,2 do corner(frame(f,'Car'..i,x+i*9,y-4,8,8,P.ink,0,Z.icon),2)end end
function ART.rail(f,w,h)
    local s,mh,ly=measure(h);local y=mh*.58
    area(f,'Me',0,0,w,mh,P.me,.7);rail(f,w*.14,w*.86,y);train(f,w*.62,y)
    badge(f,'City',w*.14,y,s,P.ink);badge(f,'Factory',w*.5,y,s,P.ink);badge(f,'City#2',w*.86,y,s,P.ink)
    text(f,'Gold','+1만',w*.86,y-s-18,60,14,P.gold)
    text(f,'CityA','도시',w*.14,ly,60,12,P.muted);text(f,'Factory','공장',w*.5,ly,60,12,P.muted);text(f,'CityB','도시',w*.86,ly,60,12,P.muted)
end
function ART.allyRail(f,w,h)
    local s,mh,ly=measure(h);local y=mh*.58
    area(f,'Me',0,0,w*.6-2,mh,P.me,.7);area(f,'Ally',w*.6+2,0,w*.4-2,mh,P.ally)
    rail(f,w*.14,w*.86,y);train(f,w*.66,y)
    badge(f,'City',w*.14,y,s,P.ink);badge(f,'Factory',w*.42,y,s,P.ink);badge(f,'City#ally',w*.86,y,s,P.ink)
    text(f,'Home','+1만',w*.14,y-s-16,70,12,P.muted);text(f,'Away','+3만 5천',w*.86,y-s-18,90,15,P.gold)
    text(f,'Mine','내 도시',w*.14,ly,80,12,P.muted);text(f,'Theirs','동맹 도시',w*.86,ly,80,12,P.ally)
end
function ART.conquer(f,w,h)
    local s,mh,ly=measure(h)
    area(f,'Me',0,0,w*.46,mh,P.me);area(f,'Taken',w*.54,0,w*.46,mh,P.enemy,.82)
    for i,p in ipairs({{.66,.32},{.82,.5},{.68,.7}})do badge(f,'Gold#'..i,w*p[1],mh*p[2],s*.9,P.gold)end
    arrow(f,'Bring',w*.6,mh*.5,w*.3,mh*.5,P.gold,3)
    text(f,'All','골드 전부',w*.23,ly,w*.46,12,P.gold);text(f,'Conquer','정복',w*.77,ly,w*.46,12,P.enemy)
end
function ART.boat(f,w,h)
    local s,mh,ly=measure(h);sea(f,w,mh)
    area(f,'Me',0,0,w*.28,mh,P.me);area(f,'Island',w*.7,mh*.14,w*.25,mh*.72,P.land,.2)
    local mx,my=route(f,'Lane',w*.28,mh*.62,w*.7,mh*.5,mh*.16,P.ink)
    badge(f,'Transport',mx,my,s,P.me);ring(f,'Land',w*.7,mh*.5,s*.55,P.me)
    text(f,'Coast','해안',w*.14,ly,w*.28,12,P.muted);text(f,'Landing','상륙',w*.82,ly,w*.3,12,P.me)
end
function ART.trade(f,w,h)
    local s,mh=measure(h);sea(f,w,h)
    area(f,'Me',0,h*.3,w*.14,h*.44,P.me);area(f,'Near',w*.28,0,w*.14,h*.3,P.land,.2);area(f,'Far',w*.84,h*.5,w*.16,h*.5,P.land,.2)
    local px,py=w*.14,h*.52
    route(f,'NearLane',px,py,w*.35,h*.3,4,P.muted,6);route(f,'FarLane',px,py,w*.84,h*.72,-h*.08,P.gold,16)
    badge(f,'Port',px,py,s,P.ink);badge(f,'Port#near',w*.35,h*.3,s*.85,P.ink);badge(f,'Port#far',w*.84,h*.72,s*.85,P.ink)
    text(f,'Little','조금',w*.35+s*.9+16,h*.3-8,40,12,P.muted)
    icon(f,'Gold',w*.84-s*.2,h*.3,s*.8,P.gold);text(f,'Much','많이',w*.84+s*.9,h*.3-9,46,15,P.gold)
end
function ART.capture(f,w,h)
    local s,mh,ly=measure(h);sea(f,w,mh)
    area(f,'Me',0,0,w*.16,mh,P.me);badge(f,'Port',w*.08,mh*.5,s*.85,P.ink)
    ring(f,'Range',w*.42,mh*.58,mh*.38,P.me,.88);badge(f,'Warship',w*.42,mh*.62,s,P.me)
    icon(f,'TradeShip',w*.55,mh*.28,s*.85,P.enemy);arrow(f,'Turn',w*.62,mh*.28,w*.78,mh*.28,P.ink,2);icon(f,'TradeShip',w*.86,mh*.28,s*.85,P.me)
    text(f,'Mine','내 것',w*.86,ly,70,12,P.me)
end
function ART.ally(f,w,h)
    local s,mh,ly=measure(h)
    area(f,'Ally',0,0,w*.3,mh,P.ally);area(f,'Me',w*.31,0,w*.37,mh,P.me);area(f,'Enemy',w*.69,0,w*.31,mh,P.enemy)
    badge(f,'Alliance',w*.305,mh*.5,s,P.ally)
    for k,yy in ipairs({.32,.68})do arrow(f,'Push'..k,w*.5,mh*yy,w*.8,mh*yy,P.me,3)end
    text(f,'Safe','안심',w*.3,ly,80,12,P.ally);text(f,'Focus','집중',w*.66,ly,80,12,P.me)
end
function ART.embargo(f,w,h)
    local s,mh,ly=measure(h);sea(f,w,mh)
    area(f,'Me',0,0,w*.2,mh,P.me);area(f,'Enemy',w*.8,0,w*.2,mh,P.enemy)
    route(f,'Lane',w*.12,mh*.5,w*.88,mh*.5,mh*.12,P.muted,14)
    badge(f,'Port',w*.12,mh*.5,s,P.ink);badge(f,'Port#enemy',w*.88,mh*.5,s,P.ink)
    local t=icon(f,'TradeShip',w*.34,mh*.38,s*.8,P.muted);if t:IsA('ImageLabel')then t.ImageTransparency=.4 end;cross(f,'Cut',w*.5,mh*.38,s*.42,P.enemy)
    text(f,'Cut','교역 끊기',w*.5,ly,100,12,P.ink);text(f,'Income','수입 ↓',w*.88,ly,70,12,P.enemy)
end
function ART.traitor(f,w,h)
    local s,mh,ly=measure(h)
    area(f,'Me',0,0,w*.44,mh,P.me);area(f,'Traitor',w*.46,0,w*.54,mh,P.enemy)
    badge(f,'Traitor',w*.76,mh*.5,s*1.1,P.warn);chip(f,'Clock','30초',w*.92,4,P.warn)
    for k,yy in ipairs({.25,.5,.75})do arrow(f,'In'..k,w*.3,mh*yy,w*.6,mh*yy,P.me,3)end
    text(f,'Half','방어 절반',w*.73,ly,w*.5,12,P.enemy)
end
local function blast(f,name,cx,cy,r)disc(f,name,cx,cy,r,P.fallout,.45,Z.line);ring(f,name..'Edge',cx,cy,r,P.warn)end
function ART.nuke(f,w,h)
    local s,mh,ly=measure(h)
    area(f,'Me',0,mh*.3,w*.26,mh*.7,P.me);area(f,'Enemy',w*.56,mh*.3,w*.44,mh*.7,P.enemy)
    badge(f,'MissileSilo',w*.12,mh*.62,s,P.ink);icon(f,'City',w*.68,mh*.5,s*.8,P.ink);icon(f,'City#2',w*.9,mh*.82,s*.8,P.ink)
    local tx,ty=w*.8,mh*.66;local mx,my=route(f,'Arc',w*.12,mh*.62,tx,ty,mh*.55,P.ink,14)
    icon(f,'AtomBomb',mx,my,s,P.warn);blast(f,'Blast',tx,ty,mh*.24)
    text(f,'Fallout','낙진',tx,ly,80,12,P.fallout)
end
function ART.sam(f,w,h)
    local s,mh,ly=measure(h)
    area(f,'Me',0,0,w*.56,mh,P.me);badge(f,'City',w*.16,mh*.62,s,P.ink);badge(f,'SAMLauncher',w*.32,mh*.5,s,P.ink)
    local r=mh*.44;ring(f,'Range',w*.32,mh*.5,r,P.me,.88)
    local hx,hy=w*.32+r*.8,mh*.5-r*.6
    route(f,'Incoming',w*.95,mh*.08,hx,hy,-2,P.enemy,8);icon(f,'AtomBomb',w*.95-s*.2,mh*.12+s*.3,s*.85,P.enemy)
    cross(f,'Hit',hx,hy,s*.3,P.warn);text(f,'Intercept','요격',hx+s*1.2,hy-8,60,12,P.warn)
end
function ART.mirv(f,w,h)
    local s,mh,ly=measure(h)
    area(f,'Enemy',0,mh*.48,w,mh*.52,P.enemy);badge(f,'MIRV',w*.5,s*.75,s,P.warn)
    for i=1,7 do local x=w*(.08+(i-1)*.14);local y=mh*(i%2==0 and .66 or .82)
        route(f,'Split'..i,w*.5,s*1.4,x,y,0,P.warn,5);blast(f,'Hit'..i,x,y,math.max(5,mh*.09))end
    text(f,'Wide','한꺼번에 여러 곳',w*.5,ly,w,12,P.warn)
end
function ART.support(f,w,h)
    local s,mh,ly=measure(h)
    area(f,'Me',0,0,w*.4,mh,P.me);area(f,'Mate',w*.6,0,w*.4,mh,P.ally)
    arrow(f,'Troops',w*.3,mh*.3,w*.7,mh*.3,P.ink,2);arrow(f,'Gold',w*.3,mh*.7,w*.7,mh*.7,P.gold,2)
    badge(f,'Soldier',w*.5,mh*.3,s,P.ink);badge(f,'Gold',w*.5,mh*.7,s,P.gold)
    text(f,'Me','나',w*.2,ly,60,12,P.me);text(f,'Mate','전우',w*.8,ly,60,12,P.ally)
end
function ART.peace(f,w,h)
    local s,mh=measure(h);local by=mh*.56;local cut=w*.44
    corner(frame(f,'Peace',0,by,cut-2,10,P.me,.1),5);corner(frame(f,'After',cut+2,by,w-cut-2,10,P.muted,.55),5)
    badge(f,'City',w*.08,by-s,s,P.ink);badge(f,'Factory',w*.21,by-s,s,P.ink)
    icon(f,'AtomBomb',w*.35,by-s,s*.85,P.muted);cross(f,'NoNuke',w*.35,by-s,s*.4,P.enemy);badge(f,'AtomBomb#later',w*.72,by-s,s,P.enemy)
    text(f,'First','처음 4분',cut/2,by+16,cut,12,P.me);text(f,'Then','핵 가능',cut+(w-cut)/2,by+16,w-cut,12,P.enemy)
end
function ART.fleet(f,w,h)
    local s,mh=measure(h);sea(f,w,h)
    area(f,'Me',0,0,w*.7,h*.24,P.me);badge(f,'Port#a',w*.18,h*.12,s*.85,P.ink);badge(f,'Port#b',w*.52,h*.12,s*.85,P.ink)
    for i=1,5 do icon(f,'Warship#'..i,w*(.12+(i-1)*.15),h*(.5+(i%2)*.24),s*1.4,P.me)end
    chip(f,'Double','골드 2배',w-30,h*.06,P.gold).Size=UDim2.fromOffset(58,16)
end
function ART.blockade(f,w,h)
    local s=measure(h);sea(f,w,h);local t=h*.2
    area(f,'North',0,0,w,t,P.land,.25);area(f,'South',0,h-t,w,t,P.land,.25);area(f,'West',0,0,w*.12,h,P.land,.25)
    area(f,'MeN',w*.2,0,w*.24,t,P.me);area(f,'MeS',w*.56,h-t,w*.26,t,P.me);area(f,'MeW',0,h*.35,w*.12,h*.3,P.me)
    badge(f,'Port#n',w*.32,t,s*.8,P.ink);badge(f,'Port#s',w*.69,h-t,s*.8,P.ink);badge(f,'Port#w',w*.12,h*.5,s*.8,P.ink)
    icon(f,'Warship',w*.45,h*.5,s*1.4,P.me);icon(f,'Warship#2',w*.62,h*.42,s*1.4,P.me);icon(f,'Warship#enemy',w*.88,h*.5,s*1.2,P.enemy)
end
function ART.alone(f,w,h)
    local s,mh,ly=measure(h)
    area(f,'West',0,0,w*.3,mh,P.enemy);area(f,'East',w*.7,0,w*.3,mh,P.enemy);area(f,'North',w*.32,0,w*.36,mh*.24,P.enemy)
    area(f,'Me',w*.32,mh*.28,w*.36,mh*.72,P.me)
    badge(f,'DefensePost#w',w*.33,mh*.64,s*.85,P.ink);badge(f,'DefensePost#e',w*.67,mh*.64,s*.85,P.ink);badge(f,'DefensePost#n',w*.5,mh*.29,s*.85,P.ink)
    icon(f,'Alliance',w*.5,mh*.66,s,P.muted);cross(f,'NoAlly',w*.5,mh*.66,s*.42,P.enemy)
    text(f,'None','동맹 없음',w*.5,ly,100,12,P.enemy)
end
function ART.combo(f,w,h,lesson)
    local s,mh,ly=measure(h);local chain=lesson and lesson.chain or {};local n=#chain;if n==0 then return end
    local cw=w/n;local cy=mh*.5;s=math.min(s*1.2,cw*.45)
    for i,c in ipairs(chain)do
        local cx=cw*(i-.5)
        corner(frame(f,'Cell'..i,cx-s*.85,cy-s*.85,s*1.7,s*1.7,P.wall,.05,Z.pad),10)
        icon(f,c[1],cx,cy,s,i==n and P.me or c[1]=='Gold'and P.gold or P.ink)
        text(f,'Label'..i,c[2],cx,ly,cw,12,i==n and P.me or P.muted)
        if c[3]=='+'then text(f,'Plus'..i,'+',cx-cw/2,cy-10,20,16,P.muted)
        elseif c[3]then arrow(f,'To'..i,cx-cw+s*.95,cy,cx-s*.95,cy,P.muted,2)end
    end
end
function ART.waterNuke(f,w,h)
    local s,mh,ly=measure(h);sea(f,w,mh)
    area(f,'Me',0,mh*.46,w,mh*.54,P.me)
    badge(f,'City',w*.16,mh*.72,s,P.ink);badge(f,'SAMLauncher',w*.32,mh*.72,s,P.ink)
    local tx,ty=w*.7,mh*.62;disc(f,'NewSea',tx,ty,mh*.3,P.ocean,0,Z.line);ring(f,'Edge',tx,ty,mh*.3,P.warn)
    route(f,'Fall',w*.95,0,tx,ty-mh*.16,-2,P.enemy,6);icon(f,'AtomBomb',w*.92,s*.6,s*.85,P.enemy)
    text(f,'Sea','바다가 돼요',tx,ly,110,12,P.ink)
end
function ART.samStack(f,w,h)
    local s,mh,ly=measure(h)
    area(f,'Me',w*.18,0,w*.64,mh,P.me,.7);badge(f,'City',w*.5,mh*.62,s,P.ink)
    for i,p in ipairs({{.38,.7},{.62,.7},{.5,.34}})do ring(f,'Range'..i,w*p[1],mh*p[2],mh*.34,P.me,.92);badge(f,'SAMLauncher#'..i,w*p[1],mh*p[2],s*.8,P.ink)end
    for i,p in ipairs({{.08,.12,.3,.28},{.92,.12,.7,.28},{.92,.82,.74,.72}})do
        route(f,'Bomb'..i,w*p[1],mh*p[2],w*p[3],mh*p[4],0,P.enemy,5);cross(f,'Hit'..i,w*p[3],mh*p[4],s*.25,P.warn)end
    text(f,'Stack','겹쳐 두기',w*.5,ly,100,12,P.me)
end
function ART.threeWay(f,w,h)
    local s,mh,ly=measure(h)
    area(f,'Red',0,0,w*.4,mh*.5,P.enemy);area(f,'Violet',w*.6,0,w*.4,mh*.5,P.other,.75);area(f,'Me',w*.25,mh*.58,w*.5,mh*.42,P.me)
    arrow(f,'RedHit',w*.32,mh*.22,w*.66,mh*.22,P.enemy,2);arrow(f,'VioletHit',w*.68,mh*.34,w*.34,mh*.34,P.other,2)
    badge(f,'Sword',w*.5,mh*.28,s*.85,P.ink);arrow(f,'Mine',w*.62,mh*.7,w*.8,mh*.4,P.me,3)
    text(f,'Gap','틈',w*.88,mh*.56,60,13,P.me)
end
function ART.islands(f,w,h)
    local s=measure(h);sea(f,w,h);local iw,ih=w*.28,h*.34
    area(f,'Me',w*.04,h*.06,iw,ih,P.me);area(f,'Red',w*.68,h*.06,iw,ih,P.enemy);area(f,'Violet',w*.04,h*.6,iw,ih,P.other,.7);area(f,'Orange',w*.68,h*.6,iw,ih,P.warn,.7)
    disc(f,'Mate',w*.14,h*.3,4,P.ally,0,Z.icon)
    local mx,my=route(f,'LaneMe',w*.32,h*.16,w*.68,h*.16,h*.06,P.me,10);route(f,'LaneMate',w*.32,h*.32,w*.68,h*.32,-h*.04,P.ally,10)
    badge(f,'Transport',mx,my,s*.85,P.me);text(f,'Together','함께',w*.5,h*.42,60,12,P.ally)
end
function ART.focus(f,w,h)
    local s,mh,ly=measure(h);local b=math.min(mh*.2,w*.08)
    local tx,ty=w*.74,mh*.5
    for i=1,4 do local y=mh*(i-.5)/4;area(f,'Us'..i,w*.04,y-b/2,b,b,i==1 and P.me or P.ally,.4);arrow(f,'Hit'..i,w*.04+b+4,y,tx-b*.7,ty,i==1 and P.me or P.ally,2)end
    for i=1,6 do local col=(i-1)%2;local row=math.floor((i-1)/2);local x=w*(.74+col*.14);local y=mh*(.18+row*.32)
        if not(col==0 and row==1)then area(f,'Them'..i,x-b/2,y-b/2,b,b,P.enemy)end end
    area(f,'Target',tx-b/2,ty-b/2,b,b,P.enemy,.15);icon(f,'Target',tx,ty,b*.9,P.ink)
    text(f,'Same','같은 적',tx,ly,90,12,P.enemy)
end
function ART.teamNuke(f,w,h)
    local s,mh,ly=measure(h)
    area(f,'Me',0,0,w*.22,mh,P.me);area(f,'Mate',w*.22,0,w*.2,mh,P.ally);area(f,'Enemy',w*.6,0,w*.4,mh,P.enemy)
    ring(f,'Range',w*.2,mh*.5,mh*.34,P.me,.9);badge(f,'SAMLauncher',w*.2,mh*.5,s,P.ink)
    route(f,'Incoming',w*.62,mh*.2,w*.3,mh*.26,mh*.1,P.enemy,6);cross(f,'Hit',w*.3,mh*.26,s*.25,P.warn)
    badge(f,'MissileSilo',w*.82,mh*.62,s,P.ink);icon(f,'Target',w*.82,mh*.62,s*1.5,P.warn)
    local mx,my=route(f,'Arc',w*.3,mh*.78,w*.8,mh*.56,mh*.35,P.ink,10);icon(f,'AtomBomb',mx,my,s*.8,P.me)
    text(f,'Silo','적 기지',w*.82,ly,90,12,P.enemy)
end
function ART.rush(f,w,h)
    local s=measure(h);sea(f,w,h)
    area(f,'Island',w*.08,h*.12,w*.84,h*.76,P.land,.25)
    for i,p in ipairs({{.14,.2},{.8,.22},{.16,.66},{.78,.66}})do area(f,'Nation'..i,w*p[1],h*p[2],w*.08,h*.16,P.enemy)end
    for i,p in ipairs({{.3,.24},{.62,.22},{.3,.64},{.64,.66},{.24,.44},{.72,.44}})do area(f,'Tribe'..i,w*p[1],h*p[2],w*.06,h*.13,P.muted,.45)end
    area(f,'Me',w*.45,h*.4,w*.1,h*.2,P.me,.2)
    for i,p in ipairs({{.36,.32},{.64,.32},{.36,.68},{.66,.7}})do arrow(f,'Grab'..i,w*.5,h*.5,w*p[1],h*p[2],P.me,2)end
    chip(f,'Clock','3분',28,6,P.warn)
end
function ART.randomDrop(f,w,h)
    local s,mh,ly=measure(h)
    area(f,'Plain',0,0,w*.5,mh,P.plain,.35);area(f,'Mountain',w*.5,0,w*.3,mh,P.mountain,.35)
    corner(frame(f,'Water',w*.8,0,w*.2,mh,P.ocean,0),6)
    for i,p in ipairs({{.14,.3},{.62,.7},{.9,.28}})do ring(f,'Maybe'..i,w*p[1],mh*p[2],s*.6,P.muted);text(f,'Q'..i,'?',w*p[1],mh*p[2]-9,20,14,P.muted)end
    area(f,'Me',w*.36-s*.5,mh*.5-s*.5,s,s,P.me,.15);ring(f,'Look',w*.36,mh*.5,mh*.42,P.me)
    text(f,'Look','주변 먼저',w*.36,ly,110,12,P.me)
end
function ART.doomsday(f,w,h)
    local s,mh,ly=measure(h);local n=8;local cw=w/n
    local mine={.34,.42,.5,.56,.6,.62,.63,.63}
    for i=1,n do
        local need=.1*i;local ok=mine[i]>=need;local x=(i-1)*cw
        corner(frame(f,'Bar'..i,x+cw*.18,mh*(1-mine[i]),cw*.64,mh*mine[i],ok and P.me or P.enemy,ok and .35 or .25),3)
        line(f,'Need'..i,x+2,mh*(1-need),x+cw-2,mh*(1-need),P.warn,2)
        if i>1 then line(f,'Step'..i,x+1,mh*(1-need+.1),x+1,mh*(1-need),P.warn,2)end
    end
    text(f,'Need','지켜야 할 땅',w*.25,mh*.04,110,12,P.warn);text(f,'Drain','병력 빠짐',w-cw,ly,cw*2,12,P.enemy)
end
function ART.chokepoint(f,w,h)
    local s,mh,ly=measure(h);local gap=s*1.1
    area(f,'Me',0,0,w*.38,mh,P.me);area(f,'Enemy',w*.62,0,w*.38,mh,P.enemy)
    corner(frame(f,'WallN',w*.38,0,w*.24,mh*.5-gap/2,P.wall,0),4);corner(frame(f,'WallS',w*.38,mh*.5+gap/2,w*.24,mh*.5-gap/2,P.wall,0),4)
    frame(f,'Pass',w*.38,mh*.5-gap/2,w*.24,gap,P.me,.6)
    badge(f,'DefensePost',w*.5,mh*.5,s*.9,P.ink)
    for k,yy in ipairs({.25,.5,.75})do arrow(f,'Push'..k,w*.94,mh*yy,w*.64,mh*(.5+(yy-.5)*.4),P.enemy,2)end
    text(f,'Pass','길목',w*.5,ly,80,12,P.ink)
end
function ART.continent(f,w,h)
    local s,mh,ly=measure(h);sea(f,w,mh)
    area(f,'Home',w*.02,mh*.08,w*.36,mh*.84,P.me,.4)
    local cols={P.enemy,P.other,P.warn,P.enemy,P.other,P.enemy}
    for i=1,6 do local col=(i-1)%3;local row=math.floor((i-1)/3);area(f,'Rival'..i,w*(.62+col*.12),mh*(.1+row*.42),w*.11,mh*.38,cols[i],.5)end
    local mx,my=route(f,'Cross',w*.38,mh*.6,w*.62,mh*.5,mh*.2,P.ink,9);badge(f,'Transport',mx,my,s,P.me)
    text(f,'Hold','굳히기',w*.2,ly,w*.36,12,P.me);text(f,'Cross','건너기',w*.5,ly,90,12,P.ink)
end
function M.has(key)return type(key)=='string'and ART[key]~=nil end
function M.draw(key,f,w,h,lesson)
    local fn=M.has(key)and ART[key];if not fn then return false end
    fn(f,w,h,lesson);return true
end
return M
