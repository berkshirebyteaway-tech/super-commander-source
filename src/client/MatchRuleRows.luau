-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. The original single-player and private-lobby options
local Rows=require(script.Parent.SettingsRows)
local pack=game.ReplicatedStorage.FrontierNative
local Options=require(pack.Core.MatchOptions)
local Units=require(pack.Core.UnitRules)
local Maps=require(pack.Maps.MapLoader)
local M={}
M.speeds={{'slow','느림'},{'normal','보통'},{'fast','빠름'},{'veryfast','아주 빠름'}}
local function nationsStep(v,d)
    local steps=Options.nationSteps;local i=table.find(steps,v)
    if not i then local n=Options.nextNations(v);i=table.find(steps,n)or 1;if d<0 then i-=1 end;return steps[(i-1)%#steps+1]end
    return steps[(i-1+d)%#steps+1]
end

local HEAD_ICON={['상대']='npc',['경제']='coin',['전투 규칙']='swords',['경기 시간']='clock',['지도']='map',['팀 지원']='people',['사용할 유닛']='target'}
local function rows20(fmt)
    local K=require(script.Parent.Kit20);local S=require(script.Parent.Sheet20);local C=K.colors
    local pt,ph=fmt=='pt',fmt=='ph'
    local R={fmt=fmt}
    local gap=pt and 0 or ph and 6 or 8
    local ctl=pt and 36 or ph and 34 or 40
    local function row(p,name,title,y,w,extra)
        local main,detail=title:match('^(.-) / (.+)$');main=main or title
        local h=(pt and (detail and 52 or 48) or ph and 44 or (detail and 56 or 52))+(extra or 0)
        local f=K.make('Frame',p,{Name=name..'Row',BackgroundColor3=C.panel,BackgroundTransparency=pt and 1 or 0,BorderSizePixel=0});K.box(f,0,y,w,h)
        if pt then local line=K.make('Frame',f,{Name='Line',BackgroundColor3=C.line,BackgroundTransparency=.4,BorderSizePixel=0});K.box(line,0,h-1,w,1)
        else K.round(f,8);K.stroke(f,C.line,1,0,true)end
        local pad=pt and 0 or ph and 10 or 16;local fs=pt and 14 or ph and 13 or 15
        local top=h-(extra or 0)
        local l=K.text(f,'Label',main,fs,C.ink,700);local d
        if detail then d=K.text(f,'Detail',detail,11,C.muted,700)end
        local function caption(right)
            local cw=math.max(20,right-pad-8)
            if d then K.box(l,pad,math.floor(top/2)-fs-1,cw,fs+3);K.box(d,pad,math.floor(top/2)+3,cw,14)else K.box(l,pad,0,cw,top)end
        end
        return f,h,caption,pad
    end
    local function square(parent,name,text,icon,fn)
        local b=K.button(parent,name,{kind='plain',text=if icon then nil else text,icon=icon,iconSize=16,size=18,weight=800},fn)
        if b.iconImage then b.iconColorFixed=true;b.iconImage.ImageColor3=C.ink end
        return b
    end
    function R.heading(p,title,y,w)
        if y>0 then y+=pt and 4 or 8 end
        return Rows.heading20(p,fmt,0,y,w,title,HEAD_ICON[title]or 'dot')
    end
    function R.toggle(p,name,title,value,y,w,apply,enabled)
        local f,h,caption,pad=row(p,name,title,y,w)
        local sw,sh,knob=pt and 46 or ph and 40 or 48,pt and 28 or ph and 22 or 26,pt and 22 or ph and 16 or 20
        local b=K.make('TextButton',f,{Name=name,Text='',BackgroundTransparency=1,AutoButtonColor=false,BorderSizePixel=0,Size=UDim2.fromScale(1,1)})
        b:SetAttribute('On',value==true)
        local s=S.switch(b,'Switch',value==true,sw,sh,knob,3);K.box(s.frame,w-(pt and 0 or pad)-sw,math.floor((h-sh)/2),sw,sh)
        caption(w-(pt and 0 or pad)-sw-8)
        if enabled==false then b.Active=false;s.frame.BackgroundTransparency=.5;s.knob.BackgroundTransparency=.5
        else b.Activated:Connect(function()require(script.Parent.ToyAudio).play('click');s.set(not value,true);apply(not value)end)end
        return y+h+gap
    end
    function R.numeric(p,name,title,value,y,w,lo,hi,apply)
        local f,h,caption,pad=row(p,name,title,y,w)
        local bw=pt and 36 or ph and 34 or 40;local iw=pt and 64 or ph and 60 or 76;local g=6
        local right=w-(pt and 0 or pad);local x=right-bw*2-iw-g*2;local cy=math.floor((h-ctl)/2)
        local input=K.make('TextBox',f,{Name=name,Text=tostring(value),ClearTextOnFocus=false,TextSize=pt and 15 or ph and 14 or 16,TextColor3=C.ink,BackgroundColor3=C.bg,BorderSizePixel=0,TextXAlignment=Enum.TextXAlignment.Center})
        if K.fonts.num then input.FontFace=K.fonts.num end
        input:SetAttribute('LocalizationSkip',true);K.round(input,8);K.stroke(input,C.line,1,0,true);K.box(input,x+bw+g,cy,iw,ctl)
        local function commit(n)
            if type(n)=='number'and n==n and n>=lo and n<=hi then
                if n~=value then value=n;apply(n)end
                if input.Parent then input.Text=tostring(value)end
            elseif input.Parent then input.Text=tostring(value)end
        end
        local minus=square(f,'Minus','−',nil,function()commit(math.max(lo,value-1))end);minus:place(x,cy,bw,ctl)
        local plus=square(f,'Plus','+',nil,function()commit(math.min(hi,value+1))end);plus:place(right-bw,cy,bw,ctl)
        input.FocusLost:Connect(function()local n=tonumber(input.Text);task.defer(commit,n)end)
        caption(x)
        return y+h+gap
    end
    function R.stepper(p,name,title,valueText,y,w,step)
        local f,h,caption,pad=row(p,name,title,y,w)
        local bw=pt and 36 or ph and 34 or 40;local vw=pt and 96 or ph and 92 or 120;local g=6
        local right=w-(pt and 0 or pad);local x=right-bw*2-vw-g*2;local cy=math.floor((h-ctl)/2)
        local v=K.text(f,name,valueText,pt and 14 or ph and 13 or 15,C.ink,800,Enum.TextXAlignment.Center);K.box(v,x+bw+g,cy,vw,ctl)
        local prev=square(f,'Prev',nil,'back',function()step(-1)end);prev:place(x,cy,bw,ctl)
        local nxt=square(f,'Next',nil,'chev',function()step(1)end);nxt:place(right-bw,cy,bw,ctl)
        caption(x)
        return y+h+gap
    end
    function R.choice(p,name,title,values,current,y,w,apply)
        local wide=w>=520;local sh=pt and 36 or ph and 32 or 38
        local extra=wide and 0 or sh+(pt and 10 or 8)
        local f,h,caption,pad=row(p,name,title,y,w,extra)
        local items={};for _,v in ipairs(values)do table.insert(items,{v[1],v[2]})end
        local seg=S.segment(f,'Choice',items,current,function(id)apply(id)end,{size=pt and 13 or ph and 12 or 13})
        local sw=wide and math.min(360,math.floor(w*.56))or w-(pt and 0 or pad*2)
        local sx=wide and w-pad-sw or (pt and 0 or pad);local sy=wide and math.floor((h-sh)/2)or h-sh-(pt and 10 or 8)
        seg:place(sx,sy,sw,sh)
        for i,c in ipairs(seg.cells)do local v=values[i];c.button.Name=name..'_'..tostring(v[1]);if v[1]==current then c.button:SetAttribute('Selected',true)end end
        caption(wide and sx or w-pad)
        f:SetAttribute('Wide',wide)
        return y+h+gap
    end
    return R
end
local function recommend20(p,id)
    local row=p:FindFirstChild('DifficultyRow');local b=row and row:FindFirstChild('Difficulty_'..id,true);if not b then return end
    local K=require(script.Parent.Kit20)
    local l=b:FindFirstChild('Label');if not l then return end
    local chip,cw,chh=K.chip(b,'Recommend','추천','accent',{size=11,height=18,icon=false});chip.ZIndex=l.ZIndex
    for _,o in ipairs(chip:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex=l.ZIndex end end
    local bw,bh=b.Size.X.Offset,b.Size.Y.Offset;local tw=K.width(l.Text,l.TextSize,l)
    if tw+5+cw>bw-6 then chip.Position=UDim2.fromOffset(bw-cw-3,-math.floor(chh/2));return end
    local x0=math.floor((bw-tw-5-cw)/2)
    K.box(l,x0,0,tw+2,bh);l.TextXAlignment=Enum.TextXAlignment.Left;chip.Position=UDim2.fromOffset(x0+tw+5,math.floor((bh-chh)/2))
end
local function format20(p)
    local gui=p:FindFirstAncestorOfClass('ScreenGui');local s=require(script.Parent.Theme).scale or 1
    local size=gui and gui.AbsoluteSize/s or Vector2.new(1366,768)
    return size.X<600 and 'pt'or size.Y<500 and 'ph'or 'pc'
end
function M.draw(p,w,y,ctx,sections)
    local s,set=ctx.s,ctx.set
    local v2=require(script.Parent.Lobby20).ENABLED and (ctx.v2==true or p:FindFirstChild('Pad20')~=nil)
    local R=v2 and rows20(ctx.fmt or format20(p))or Rows
    local function toggle(key,title,on)y=R.toggle(p,key,title,on,y,w,function(v)set(key,v)end)end
    for _,section in ipairs(sections)do
        if section=='opponents'then
            y=R.heading(p,'상대',y,w)
            y=R.choice(p,'Difficulty','AI 국가 난이도',Options.difficulties,s.difficulty or 'Medium',y,w,function(v)set('difficulty',v)end)
            if ctx.recommend and v2 then recommend20(p,ctx.recommend)
            else
                local row=ctx.recommend and p:FindFirstChild('DifficultyRow');local b=row and row:FindFirstChild('Difficulty_'..ctx.recommend)
                if b then local UI=require(script.Parent.ToyUI);local t=UI.label(b,'Recommend','추천',11,UI.colors.bg);t.TextWrapped=false
                    t.BackgroundColor3=UI.colors.accent;t.BackgroundTransparency=0;t.TextXAlignment=Enum.TextXAlignment.Center;UI.corner(t,3)
                    t.Position=UDim2.new(1,-38,0,-7);t.Size=UDim2.fromOffset(34,18)end
            end
            if not ctx.coop then y=R.stepper(p,'Nations','AI 국가 수',Options.nationsLabel(s.nations or 'default'),y,w,function(d)set('nations',nationsStep(s.nations or 'default',d))end)end
            y=R.numeric(p,'bots','중립 세력 수 / 0 ~ 400',s.bots or 0,y,w,0,400,function(n)set('bots',math.floor(n))end)
        elseif section=='economy'then
            y=R.heading(p,'경제',y+(v2 and 0 or 8),w)
            y=R.numeric(p,'startingGold','시작 골드',s.startingGold or 0,y,w,0,1e9,function(n)set('startingGold',math.floor(n))end)
            y=R.numeric(p,'goldMultiplier','골드 생산 배율',s.goldMultiplier or 1,y,w,.1,1000,function(n)set('goldMultiplier',n)end)
            toggle('infiniteGold','무한 골드',s.infiniteGold==true)
            toggle('infiniteTroops','무한 병력',s.infiniteTroops==true)
            toggle('instantBuild','즉시 건설',s.instantBuild==true)
        elseif section=='combat'then
            y=R.heading(p,'전투 규칙',y+(v2 and 0 or 8),w)
            if ctx.spawn then toggle('randomSpawn','랜덤 스폰',ctx.randomSpawn==true)end
            y=R.numeric(p,'spawnImmunityMinutes','평화 시간 / 분, 0은 기본 5초',math.floor((s.spawnImmunityDuration or 0)/600),y,w,0,10,function(n)set('spawnImmunityMinutes',math.floor(n))end)
            toggle('disableAlliances','동맹 끄기',s.disableAlliances==true)
            if not s.disableAlliances then y=R.numeric(p,'customAllianceDuration','동맹 유지 / 분',s.customAllianceDuration or 5,y,w,0,15,function(n)set('customAllianceDuration',math.floor(n))end)end
            toggle('disableNukes','핵무기 끄기',s.disableNukes==true)
            if not s.disableNukes then toggle('waterNukes','물로 변하는 폭발',s.waterNukes==true)end
        elseif section=='time'then
            y=R.heading(p,'경기 시간',y+(v2 and 0 or 8),w)
            y=R.numeric(p,'maxTimerValue','시간 제한 / 분, 0은 제한 없음',s.maxTimerValue or 0,y,w,0,120,function(n)set('maxTimerValue',math.floor(n))end)
            local overtime=s.overtime or {}
            toggle('overtimeEnabled','연장전',overtime.enabled==true)
            if overtime.enabled then y=R.numeric(p,'overtimeStartMinutes','연장전 시작 / 분',overtime.startMinutes or 30,y,w,1,120,function(n)set('overtimeStartMinutes',math.floor(n))end)end
            toggle('doomsdayClock','장기전 소모전',s.doomsdayClock==true)
            if s.doomsdayClock then y=R.choice(p,'DoomSpeed','소모전 속도',M.speeds,s.doomsdayClockSpeed or 'normal',y,w,function(v)set('doomsdayClockSpeed',v)end)end
        elseif section=='map'then
            if ctx.map and Maps.hasNormal(ctx.map)then
                y=R.heading(p,'지도',y+(v2 and 0 or 8),w)
                y=R.toggle(p,'mapSize','큰 지도 / 땅 4배',s.mapSize=='normal',y,w,function(on)set('mapSize',on and 'normal'or 'compact')end)
            end
        elseif section=='teams'then
            if ctx.teams then
                y=R.heading(p,'팀 지원',y+(v2 and 0 or 8),w)
                toggle('donateGold','골드 지원',s.donateGold~=false)
                toggle('donateTroops','병력 지원',s.donateTroops~=false)
            end
        elseif section=='units'then
            y=R.heading(p,'사용할 유닛',y+(v2 and 0 or 8),w)
            for _,kind in ipairs(Units.toggleable)do
                local off=s.disabledUnits and table.find(s.disabledUnits,kind)~=nil
                y=R.toggle(p,'Unit'..kind,Units.names[kind],not off,y,w,function()
                    local list=table.clone(s.disabledUnits or {});local at=table.find(list,kind);if at then table.remove(list,at)else table.insert(list,kind)end
                    set('disabledUnits',list)
                end)
            end
        end
    end
    return y
end
function M.applyCustom(r,key,value)
    local s=r.settings
    if key=='overtimeEnabled'then s.overtime={enabled=value,startMinutes=s.overtime and s.overtime.startMinutes or 30}
    elseif key=='overtimeStartMinutes'then s.overtime={enabled=s.overtime and s.overtime.enabled or false,startMinutes=value}
    elseif key=='spawnImmunityMinutes'then s.spawnImmunityDuration=value>=1 and value*600 or nil
    elseif key=='randomSpawn'then r.spawn=value and 'random'or 'select'
    elseif key=='mapSize'then s.mapSize=value=='normal'and 'normal'or nil
    elseif key=='disabledUnits'then s.disabledUnits=#value>0 and value or nil
    elseif key=='donateTroops'then s.donateTroops=value==false and false or nil
    else s[key]=value end
end
return M
