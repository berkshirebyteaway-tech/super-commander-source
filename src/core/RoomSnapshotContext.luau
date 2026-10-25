local Presentation=if script then require(script.Parent.CombatPresentation)else require('./CombatPresentation')
local M={};M.__index=M
function M.new(session)
    return setmetatable({session=session,fronts={},encoding={copies={},diffs={}}},M)
end
function M:front(sim,attack,offset)
    local byOffset=self.fronts[attack]
    if not byOffset then byOffset={};self.fronts[attack]=byOffset end
    local value=byOffset[offset]
    if value==nil then value=Presentation.front(sim,attack,offset)or false;byOffset[offset]=value end
    return value~=false and value or nil
end
function M:battlefronts(viewer,swap)
    local sim=self.session.sim;local out={};local count=0
    for pass=1,2 do
        for _,p in ipairs(sim.players)do for _,a in ipairs(p.outgoing)do
            local relevant=a.owner==viewer or a.target==viewer
            if a.target==0 or (pass==1)~=relevant then continue end
            local tile=self:front(sim,a,math.floor(sim.ticks/4)*13)
            if tile then
                count+=1;out[count]={id=a.id,tile=tile,owner=swap(a.owner),target=swap(a.target)}
                if count>=24 then return out end
            end
        end end
    end
    return out
end
function M:transports(viewer)
    if not self.transportByViewer then
        local groups={}
        local function add(id,u)
            if not id then return end
            local list=groups[id];if not list then list={};groups[id]=list end
            table.insert(list,u)
        end
        for _,u in ipairs(self.session.units)do if u.active and u.kind=='TransportShip'then
            add(u.owner,u);if u.target~=u.owner then add(u.target,u)end
        end end
        self.transportByViewer=groups
    end
    return self.transportByViewer[viewer]or {}
end
function M:unitsFor(owner)
    if not self.unitsByOwner then
        local groups={}
        for _,u in ipairs(self.session.units)do
            local id=u.owner or 1;local list=groups[id]
            if not list then list={};groups[id]=list end
            table.insert(list,u)
        end
        self.unitsByOwner=groups
    end
    return self.unitsByOwner[owner]or {}
end
function M:units(list,swap)
    local out=table.create(#list)
    for i,u in ipairs(list)do
        local owner=swap(u.owner or 1);local target=u.target and swap(u.target)or u.target
        if owner==u.owner and target==u.target then out[i]=u
        else local v=table.clone(u);v.owner=owner;if v.target then v.target=target end;out[i]=v end
    end
    return out
end
return M
