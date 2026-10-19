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
function M.new(layer)
    return setmetatable({layer=layer,plates={},dress={},shown={},spare={}},M)
end
function M:reset()
    local keep={};local function release(p)
        p.Visible=false
        if #keep<24 then table.insert(keep,p)else p:Destroy()end
    end
    for _,p in pairs(self.plates)do release(p)end
    for _,p in ipairs(self.spare)do release(p)end
    self.plates={};self.spare=keep;self.dress={};self.shown={};self.spareShown={}
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
    local count=0;local mouse=args.mouse
    local shown,previous=self.spareShown or {},self.shown;table.clear(shown)
    local bounds=args.bounds or {left=0,top=0,right=viewport.X,bottom=viewport.Y}
    for _,f in ipairs(args.factions)do
        if f.id==1 or not f.labelTile or (f.tiles or 0)<=0 or f.eliminated then continue end
        local font=M.font(f.labelSize,ppt)
        local priority=f.id==args.selected or f.combatState~=nil
        if not M.visible(font,viewport.Y)and not priority then continue end
        local pos=args.project(f.labelTile)
        if pos.X<bounds.left-40 or pos.Y<bounds.top-20 or pos.X>bounds.right+40 or pos.Y>bounds.bottom+20 then continue end
        local plate=self:plate(f.id)
        font=math.floor(math.clamp(font,M.MIN_FONT,M.MAX_FONT)+.5)
        local faded=false
        if mouse then
            local half=plate.Size.X.Offset/2;local halfH=plate.Size.Y.Offset/2
            faded=math.abs(mouse.X-pos.X)<half and math.abs(mouse.Y-pos.Y)<halfH
        end
        local d=self.dress[f.id]
        if d and d.troops~=(f.troops or 0)and not changed(d,f,font,faded,viewport.X)then
            Probe.start('Names.troops');if Badge.troops(plate,f,font,viewport.X)then d.troops=f.troops or 0 end;Probe.stop('Names.troops')
        end
        if not d or d.troops~=(f.troops or 0)or changed(d,f,font,faded,viewport.X)then
            Probe.start('Names.dress')
            d=d or {};self.dress[f.id]=d
            d.troops=f.troops or 0;d.font=font;d.faded=faded;d.combat=f.combatState;d.allied=f.allied;d.request=f.incomingRequest
            d.away=f.disconnected;d.flag=f.flag;d.name=f.name;d.width=viewport.X;d.kind=f.kind;d.userId=f.userId
            Badge.plate(plate,f,nil,font,viewport.X,faded)
            Probe.stop('Names.dress')
        end
        local pw,ph=plate.Size.X.Offset,plate.Size.Y.Offset;local placed,fallback=nil,nil
        for _,shift in ipairs(M.SHIFTS)do
            local at=Vector2.new(pos.X,pos.Y+shift*ph)
            if args.blocks and M.covered(args.blocks,at,pw,ph,priority)then continue end
            fallback=fallback or at
            if Display.reserve(args.occupied,at.X,at.Y,pw,ph,2)then placed=at;break end
        end
        if not placed and priority and fallback then placed=fallback;Display.claim(args.occupied,placed.X,placed.Y,pw,ph,2)end
        if not placed then continue end
        pos=placed
        count+=1;shown[f.id]=true
        if d.x~=pos.X or d.y~=pos.Y then d.x=pos.X;d.y=pos.Y;plate.Position=UDim2.fromOffset(pos.X,pos.Y)end;if not plate.Visible then plate.Visible=true end
        if count>=M.LIMIT then break end
    end
    for id in pairs(previous)do
        if not shown[id]then local p=self.plates[id];if p and p.Visible then p.Visible=false end end
    end
    self.shown,self.spareShown=shown,previous
    local alive=args.alive
    if alive then for id,p in pairs(self.plates)do if not alive[id]then p.Visible=false;self.plates[id]=nil;self.dress[id]=nil;table.insert(self.spare,p)end end end
    return count
end
return M
