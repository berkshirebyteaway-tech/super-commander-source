-- SPDX-License-Identifier: AGPL-3.0-only
local Badge=require(script.Parent.FactionBadge)
local Display=require(script.Parent.Parent.Core.MapPresentation)
local Probe=require(script.Parent.FrameProbe)
local M={};M.__index=M
M.NAME_SCALE_FACTOR=.4;M.NAME_SCALE_CAP=3;M.CULL=.004;M.MIN_FONT=13;M.MAX_FONT=32;M.LIMIT=96
M.SHIFTS={0,.95,-.95}
function M.font(size,pixelsPerTile)
    local base=math.max(1,math.floor(size or 0))
    local nameSize=math.max(4,math.floor(base*M.NAME_SCALE_FACTOR))
    local nameScale=math.min(base*.25,M.NAME_SCALE_CAP)
    return nameSize*nameScale*pixelsPerTile
end
function M.visible(font,viewportHeight)return font*.75>=M.CULL*viewportHeight end
M.KEEP=.8
function M.kept(font,viewportHeight)return font*.75>=M.CULL*M.KEEP*viewportHeight end
function M.new(layer)
    return setmetatable({layer=layer,plates={},dress={},shown={},spare={},motion={},leaving={}},M)
end
function M:reset()
    local keep={};local function release(p)
        p.Visible=false
        if #keep<24 then table.insert(keep,p)else p:Destroy()end
    end
    for _,p in pairs(self.plates)do release(p)end
    for _,p in ipairs(self.spare)do release(p)end
    self.plates={};self.spare=keep;self.dress={};self.shown={};self.spareShown={};self.motion={};self.leaving={}
end
M.LERP=10;M.SHIFT_LERP=20;M.APPEAR=.16;M.LEAVE=.2;M.REDRESS=.18
local function ease(m,now)
    local t=1-math.exp(-M.LERP*(now-m.t0))
    if t>.999 then return m.tx,m.ty,m.ts end
    return m.fx+(m.tx-m.fx)*t,m.fy+(m.ty-m.fy)*t,m.fs+(m.ts-m.fs)*t
end
function M.follow(motion,id,tile,size,width,now,reduced)
    local x,y,s=tile%width,math.floor(tile/width),size or 0
    local m=motion[id]
    if not m then m={fx=x,fy=y,fs=s,tx=x,ty=y,ts=s,t0=now};motion[id]=m;return x,y,s,m end
    if m.tx~=x or m.ty~=y or m.ts~=s then
        if reduced then m.fx,m.fy,m.fs=x,y,s else m.fx,m.fy,m.fs=ease(m,now)end
        m.tx,m.ty,m.ts,m.t0=x,y,s,now
    end
    local cx,cy,cs=ease(m,now);return cx,cy,cs,m
end
local function scaler(plate)
    local s=plate:FindFirstChild('Motion')
    if not s then s=Instance.new('UIScale');s.Name='Motion';s.Parent=plate end
    return s
end
local function fadeText(plate,alpha,base,tribe)
    local title,troops=plate:FindFirstChild('Title'),plate:FindFirstChild('Troops')
    local text=base+(1-base)*(1-alpha);local stroke=(tribe and .1 or 0)+base;stroke=stroke+(1-stroke)*(1-alpha)
    for _,l in ipairs({title,troops})do if l then l.TextTransparency=text;l.TextStrokeTransparency=stroke end end
end
function M.covered(blocks,pos,width,height,priority)
    for _,b in ipairs(blocks)do
        local dx,dy=math.abs(pos.X-b.x),math.abs(pos.Y-b.y)
        if priority then if dx<b.w/2 and dy<b.h/2 then return true end
        elseif dx<(b.w+width)/2 and dy<(b.h+height)/2 then return true end
    end
    return false
end
function M:plate(id)
    local p=self.plates[id]
    if not p then
        p=table.remove(self.spare)
        if not p then Probe.start('Names.new');self.count=(self.count or 0)+1;p=Badge.new(self.layer,'Faction'..self.count);p.ZIndex=3;p.Visible=false;Probe.stop('Names.new')end
        self.plates[id]=p;self.dress[id]=nil
    end
    return p
end
local function changed(d,f,font,faded,width)
    return d.font~=font or d.faded~=faded or d.combat~=f.combatState or d.allied~=f.allied
        or d.request~=f.incomingRequest or d.away~=f.disconnected or d.flag~=f.flag or d.name~=f.name or d.width~=width
        or d.kind~=f.kind or d.userId~=f.userId
end
function M:update(args)
    local viewport,ppt=args.viewport,args.pixelsPerTile
    local count=0;local mouse=args.mouse;local now=args.now or os.clock();local reduced=args.reduced==true
    local dt=math.clamp(now-(self.lastNow or now),0,.1);self.lastNow=now
    local shown,previous=self.spareShown or {},self.shown;table.clear(shown)
    local motion,leaving=self.motion,self.leaving;local culled={}
    local bounds=args.bounds or {left=0,top=0,right=viewport.X,bottom=viewport.Y}
    local order=self.order or {};self.order=order;table.clear(order)
    for pass=1,3 do for _,f in ipairs(args.factions)do
        local first=f.id==args.selected or f.combatState~=nil
        if pass==1 and first or pass==2 and not first and previous[f.id] or pass==3 and not first and not previous[f.id]then table.insert(order,f)end
    end end
    for _,f in ipairs(order)do
        if f.id==1 or not f.labelTile or (f.tiles or 0)<=0 or f.eliminated then continue end
        local x,y,size,m=M.follow(motion,f.id,f.labelTile,f.labelSize,args.mapWidth,now,reduced)
        local raw=M.font(size,ppt)
        local priority=f.id==args.selected or f.combatState~=nil
        if not (if previous[f.id]then M.kept(raw,viewport.Y)else M.visible(raw,viewport.Y))and not priority then culled[f.id]=true;continue end
        local pos=args.projectXY(x,y)
        if pos.X<bounds.left-40 or pos.Y<bounds.top-20 or pos.X>bounds.right+40 or pos.Y>bounds.bottom+20 then continue end
        local plate=self:plate(f.id)
        raw=math.clamp(raw,M.MIN_FONT,M.MAX_FONT)
        local d=self.dress[f.id]
        local font=(d and d.font and math.abs(raw/d.font-1)<=M.REDRESS)and d.font or math.floor(raw+.5)
        local back=leaving[f.id];if back then leaving[f.id]=nil end
        if not previous[f.id]and not reduced then m.appear=back and now-M.APPEAR*back.alpha or now end
        local alpha=m.appear and math.min(1,(now-m.appear)/M.APPEAR)or 1
        if alpha>=1 then m.appear=nil end
        local scale=raw/font*(.85+.15*(1-(1-alpha)^2))
        local faded=false
        if mouse then
            local half=plate.Size.X.Offset*scale/2;local halfH=plate.Size.Y.Offset*scale/2
            faded=math.abs(mouse.X-pos.X)<half and math.abs(mouse.Y-pos.Y)<halfH
        end
        if d and d.troops~=(f.troops or 0)and not changed(d,f,font,faded,viewport.X)then
            Probe.start('Names.troops');if Badge.troops(plate,f,font,viewport.X)then d.troops=f.troops or 0 end;Probe.stop('Names.troops')
        end
        local dressed=false
        if not d or d.troops~=(f.troops or 0)or changed(d,f,font,faded,viewport.X)then
            Probe.start('Names.dress')
            d=d or {};self.dress[f.id]=d
            d.troops=f.troops or 0;d.font=font;d.faded=faded;d.combat=f.combatState;d.allied=f.allied;d.request=f.incomingRequest
            d.away=f.disconnected;d.flag=f.flag;d.name=f.name;d.width=viewport.X;d.kind=f.kind;d.userId=f.userId
            Badge.plate(plate,f,nil,font,viewport.X,faded);dressed=true
            Probe.stop('Names.dress')
        end
        if d.scale==nil or math.abs(d.scale-scale)>.002 then d.scale=scale;scaler(plate).Scale=scale end
        if alpha<1 or d.fading then fadeText(plate,alpha,faded and .55 or 0,f.kind=='BOT');d.fading=alpha<1
        elseif dressed then d.fading=nil end
        local pw,ph=plate.Size.X.Offset*raw/font,plate.Size.Y.Offset*raw/font;local placed,fallback,chosen=nil,nil,0
        local held=m.shift or 0
        for i=1,#M.SHIFTS+1 do
            local shift=if i==1 then 0 elseif i==2 then held else M.SHIFTS[i-1]
            if i>2 and shift==held or i==2 and held==0 then continue end
            local at=Vector2.new(pos.X,pos.Y+shift*ph)
            if args.blocks and M.covered(args.blocks,at,pw,ph,priority)then continue end
            if not fallback then fallback=at;chosen=shift end
            if Display.reserve(args.occupied,at.X,at.Y,pw,ph,2)then placed=at;chosen=shift;break end
        end
        if not placed and priority and fallback then placed=fallback;Display.claim(args.occupied,placed.X,placed.Y,pw,ph,2)end
        if not placed then continue end
        if reduced or not previous[f.id]or m.drawn==nil then m.drawn=chosen
        else m.drawn+=(chosen-m.drawn)*(1-math.exp(-M.SHIFT_LERP*dt))end
        if math.abs(m.drawn-chosen)<.01 then m.drawn=chosen end
        m.shift=chosen
        pos=Vector2.new(pos.X,pos.Y+m.drawn*ph)
        count+=1;shown[f.id]=true
        if d.x~=pos.X or d.y~=pos.Y then d.x=pos.X;d.y=pos.Y;plate.Position=UDim2.fromOffset(pos.X,pos.Y)end;if not plate.Visible then plate.Visible=true end
        if count>=M.LIMIT then break end
    end
    local alive=args.alive
    for id in pairs(previous)do
        if shown[id]then continue end
        local p=self.plates[id];local m=motion[id]
        local gone=alive and not alive[id]
        if p and p.Visible and m and not reduced and not leaving[id]and (culled[id]or gone or self:falling(args.factions,id))then
            leaving[id]={t0=now,alpha=1,scale=(self.dress[id]and self.dress[id].scale)or 1}
        elseif p and p.Visible and not leaving[id]then p.Visible=false end
    end
    for id,l in pairs(leaving)do
        local p=self.plates[id];local m=motion[id];local d=self.dress[id]
        l.alpha=1-(now-l.t0)/M.LEAVE
        if not p or not m or l.alpha<=0 then
            leaving[id]=nil;if p then p.Visible=false end
            if d then d.scale=nil;d.fading=true end
        else
            local x,y=ease(m,now);local pos=args.projectXY(x,y)
            pos=Vector2.new(pos.X,pos.Y+(m.drawn or 0)*p.Size.Y.Offset*l.scale)
            scaler(p).Scale=l.scale*(.8+.2*l.alpha);if d then d.scale=nil;d.fading=true end
            fadeText(p,l.alpha,d and d.faded and .55 or 0,d and d.kind=='BOT')
            p.Position=UDim2.fromOffset(pos.X,pos.Y);if d then d.x=pos.X;d.y=pos.Y end
        end
    end
    self.shown,self.spareShown=shown,previous
    if alive then for id,p in pairs(self.plates)do if not alive[id]and not leaving[id]then p.Visible=false;self.plates[id]=nil;self.dress[id]=nil;motion[id]=nil;table.insert(self.spare,p)end end end
    return count
end
function M:falling(factions,id)
    for _,f in ipairs(factions)do if f.id==id then return f.eliminated==true or (f.tiles or 0)<=0 or not f.labelTile end end
    return true
end
return M
