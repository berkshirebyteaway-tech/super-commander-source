local Terrain=if script then require(script.Parent.Terrain)else require('./Terrain')
local M={};M.__index=M
function M.new()
    return setmetatable({stage='settle',attacks=0,progress=0},M)
end
function M:command(action,tiles)
    if action=='attack'and self.stage~='done'then
        self.attacks+=1
        if self.attacks==1 then self.firstTiles=tiles end
        if self.attacks==2 then self.secondTiles=tiles end
    end
end
function M:observe(p)
    if self.stage=='done'or p.paused or p.phase~='playing'or p.tiles<=0 then return end
    if self.stage=='settle'then self.stage='expand';self.initialTiles=p.tiles;self.targetTile=nil end
    if self.attacks>0 then
        self.lowTroops=math.min(self.lowTroops or p.troops,p.troops)
        if p.troops>=self.lowTroops+math.max(5,self.lowTroops*.01)then self.grown=true end
        if p.tiles>=(self.firstTiles or self.initialTiles)+12 and not self.expanded then
            self.expanded=true;self.expandedAt=p.tick;self.stage='grow'
        end
        if self.expanded and p.tick-self.expandedAt>=20 and (self.grown or p.troops>=p.cap)then self.stage='done' end
    end
    self.progress=({settle=0,expand=1,grow=2,again=3,done=4})[self.stage]
end
function M:step(s,id,paused)
    local p=s.sim.players[id];self:observe({phase=s.phase,tiles=p.tiles.size,troops=p.troops,cap=s:maxTroops(id),tick=s.sim.ticks,paused=paused})
end
function M:target(s,id)
    if self.stage=='done'or self.stage=='grow'then return nil end
    local function free(t)return t>=0 and t<s.map.meta.width*s.map.meta.height and s.sim:owner(t)==0 and Terrain.isLand(s.sim.terrain[t+1])and not Terrain.isImpassable(s.sim.terrain[t+1])end
    local function rival(t)
        local owner=s.sim:owner(t)
        return owner~=0 and owner~=id and s.sim.players[owner]~=nil and Terrain.isLand(s.sim.terrain[t+1])and not Terrain.isImpassable(s.sim.terrain[t+1])and not s:friendly(id,owner)and not s:protectedTarget(id,owner)
    end
    if self.targetTile and (free(self.targetTile)or self.stage~='settle'and rival(self.targetTile))then return self.targetTile end
    local p=s.sim.players[id];local w,h=s.map.meta.width,s.map.meta.height
    if self.stage=='settle'and p and p.spawnTile and p.tiles.size>0 then return p.spawnTile end
    if self.stage=='settle'then
        local cx,cy=math.floor(w/2),math.floor(h/2)
        for r=0,math.max(w,h),4 do
            for dx=-r,r,4 do for _,dy in ipairs({-r,r})do
                local x,y=cx+dx,cy+dy;local t=y*w+x
                if x>12 and y>12 and x<w-12 and y<h-12 and free(t)and free(t-8)and free(t+8)and free(t-8*w)and free(t+8*w)then self.targetTile=t;return t end
            end end
        end
    else
        local best,distance;local origin=p.spawnTile or 0
        for _,t in ipairs(p.tiles:values())do for _,n in ipairs(s.sim:neighbors(t))do if free(n)then
            local dx,dy=n%w-origin%w,math.floor(n/w)-math.floor(origin/w)
            local d=dx*dx+dy*dy;if not distance or d>distance then best=n;distance=d end
        end end end
        if not best then
            local weakest=math.huge
            for _,t in ipairs(p.tiles:values())do for _,n in ipairs(s.sim:neighbors(t))do if rival(n)then
                local troops=s.sim.players[s.sim:owner(n)].troops
                if troops<weakest then best=n;weakest=troops end
            end end end
        end
        self.targetTile=best;return best
    end
    return nil
end
function M:view(s,id,intro)
    local target=self:target(s,id)
    return {stage=self.stage,progress=self.progress,target=target,targetOwner=target and s.sim:owner(target)or nil,intro=intro==true}
end
return M
