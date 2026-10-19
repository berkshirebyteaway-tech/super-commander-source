local M={};M.__index=M
function M.new()return setmetatable({},M)end
function M.rateText(rate,formatTroops)
    local value=tonumber(rate)or 0
    return (value<0 and '-'or '+')..formatTroops(math.abs(value))..'/s'
end
function M:update(s)
    local p=s.player or {}
    local rate=tonumber(p.growthTrendRate)or tonumber(p.growth)or 0
    if rate~=rate or math.abs(rate)==math.huge then rate=0 end
    local identity=tostring(s.version)..':'..tostring(s.controller)..':'..tostring(p.userId or p.id)
    local reset=self.identity~=identity
    if reset then self.identity=identity;self.rate=nil;self.direction=0 end
    local held=s.paused or s.awaitFirst==true
    if not held then
        if self.rate~=nil and rate~=self.rate then self.direction=rate>self.rate and 1 or -1 end
        self.rate=rate
    end
    local stopped=held or s.phase~='playing' or (p.tiles or 0)==0
    local loss=(tonumber(p.growth)or 0)<0
    return {rate=tonumber(p.growth)or 0,rawRate=rate,direction=self.direction,
        tone=stopped and 'idle'or (loss or self.direction==-1)and 'falling'or 'rising',
        arrow=stopped and 'Ⅱ'or loss and '↓'or self.direction==1 and '↑'or self.direction==-1 and '↓'or '→'}
end
function M.layout(width,touch)
    if touch and width<310 then
        local available=width-64
        return {stacked=true,height=64,flowHeight=64,
            growth={x=0,y=0,w=math.min(96,available-60),h=44},gold={x=available-54,y=0,w=54,h=32},
            troops={x=0,y=32,w=available,h=28}}
    end
    if touch and width>=310 then
        local available=width-64;local growth=96;local gold=width>=420 and 64 or 54
        return {stacked=false,height=44,flowHeight=44,plate={y=6,h=32},
            growth={x=0,y=0,w=growth,h=44},gold={x=available-gold,y=0,w=gold,h=44},
            troops={x=growth+6,y=6,w=available-growth-gold-12,h=32}}
    end
    local available=width-70
    local stacked=available<300
    local growth=stacked and math.min(100,available-62)or 136
    local gold=stacked and 54 or 80
    return {stacked=stacked,height=stacked and 76 or 44,flowHeight=stacked and 76 or 32,
        growth={x=0,y=0,w=growth,h=44},gold={x=available-gold,y=0,w=gold,h=44},
        troops={x=stacked and 0 or growth+8,y=stacked and 44 or 6,
            w=stacked and available or available-growth-gold-16,h=32}}
end
function M.touchRows(width,shortCompact)
    local r=M.layout(width,true)
    local top=shortCompact and 2 or 8
    local dispatchY=top+r.flowHeight+4
    return {resourcesY=top,dispatchY=dispatchY,dispatchH=44,
        height=shortCompact and 96 or nil,
        plateGap=dispatchY-(top+(r.plate and r.plate.y+r.plate.h or r.height))}
end
return M
