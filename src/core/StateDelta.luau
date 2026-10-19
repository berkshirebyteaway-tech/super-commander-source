--!native
local M={}
M.effectWindow=64
local SKIP={_d=true,_gone=true}

local function packCaptured(list)
    local b=buffer.create(#list*6)
    for i,v in ipairs(list)do buffer.writeu32(b,(i-1)*6,v[1]);buffer.writeu16(b,(i-1)*6+4,v[2])end
    return b
end
function M.unpackCaptured(b)
    local out=table.create(buffer.len(b)//6)
    for i=0,buffer.len(b)//6-1 do out[i+1]={buffer.readu32(b,i*6),buffer.readu16(b,i*6+4)}end
    return out
end
function M.packOwnership(packet)
    if type(packet.captured)=='table'and #packet.captured>0 then packet.capturedBuf=packCaptured(packet.captured);packet.captured=nil end
    return packet
end
function M.packChanges(changes,viewer,map)
    local b=buffer.create(#changes*6)
    for i,v in ipairs(changes)do
        local o=(i-1)*6;buffer.writeu32(b,o,v[1]);buffer.writeu16(b,o+4,if map then map(v[2],viewer)else v[2])
    end
    return b
end
function M.ownershipPacket(session,version,viewer,map)
    local changes=session.ownershipChanges
    local packet={ownershipOnly=true,version=version,ownershipRevision=session.ownershipRevision,baseRevision=session.baseRevision}
    if #changes>0 then packet.capturedBuf=M.packChanges(changes,viewer,map)else packet.captured={}end
    return packet
end
local function falloutSame(previous,list)
    if not previous or not list or #previous.list~=#list then return false end
    local same=true;for i,tile in ipairs(list)do if previous.list[i]~=tile then same=false;break end end
    if same then return true end
    local sum=0;for _,tile in ipairs(list)do sum+=tile end
    if sum~=previous.sum then return false,sum end
    if not previous.tiles then local tiles={};for _,tile in ipairs(previous.list)do tiles[tile]=true end;previous.tiles=tiles end
    for _,tile in ipairs(list)do if not previous.tiles[tile]then return false end end
    return true
end
local function rememberFallout(list,sum)
    if not list then return nil end
    if sum==nil then sum=0;for _,tile in ipairs(list)do sum+=tile end end
    return {list=table.clone(list),sum=sum}
end
local function snapshot(value)
    if type(value)~='table'then return value end
    local out={};for k,v in pairs(value)do out[k]=snapshot(v)end;return out
end
local function equal(a,b)
    if type(a)~='table'or type(b)~='table'then return a==b end
    for k,v in pairs(a)do if not equal(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end
    return true
end
local function diffList(previous,list)
    local out,map=table.create(#list),{}
    for _,item in ipairs(list)do
        local prev=previous and previous[item.id]
        if prev then
            local d={id=item.id,_d=true};local gone;local changed=false
            for k,v in pairs(item)do if not equal(prev[k],v)then changed=true;d[k]=snapshot(v)end end
            for k in pairs(prev)do if item[k]==nil then changed=true;gone=gone or {};table.insert(gone,k)end end
            d._gone=gone;table.insert(out,d)
            map[item.id]=changed and snapshot(item)or prev
        else table.insert(out,item);map[item.id]=snapshot(item)end
    end
    return out,map
end
local function remember(base,s)
    base.factions={};for _,f in ipairs(s.factions or {})do base.factions[f.id]=snapshot(f)end
    base.units={};for _,u in ipairs(s.units or {})do base.units[u.id]=snapshot(u)end
    base.railRevision=s.railRevision;base.terrainRevision=s.terrainRevision;base.fallout=rememberFallout(s.fallout)
    base.lastEffect=0;for _,e in ipairs(s.unitEffects or {})do base.lastEffect=math.max(base.lastEffect,e.id or 0)end
end
function M.encode(base,s,full,view)
    base.seq=(base.seq or 0)+1;s.stream=base.seq
    if type(s.captured)=='table'and #s.captured>0 then s.capturedBuf=packCaptured(s.captured);s.captured=nil end
    if full or base.version~=s.version or base.view~=view or not base.factions then base.version=s.version;base.view=view;remember(base,s);return s end
    s.delta=true
    if s.factions then s.factions,base.factions=diffList(base.factions,s.factions)end
    if s.units then s.units,base.units=diffList(base.units,s.units)end
    if s.railRevision~=nil and s.railRevision==base.railRevision then s.rails=nil else base.railRevision=s.railRevision end
    if s.terrainRevision~=nil and s.terrainRevision==base.terrainRevision then s.terrainChanges=nil else base.terrainRevision=s.terrainRevision end
    local sameFallout,sum=falloutSame(base.fallout,s.fallout);if sameFallout then s.fallout=nil else base.fallout=rememberFallout(s.fallout,sum)end
    if s.unitEffects then
        local fresh={};local last=base.lastEffect or 0
        for _,e in ipairs(s.unitEffects)do if (e.id or 0)>(base.lastEffect or 0)then table.insert(fresh,e);last=math.max(last,e.id)end end
        s.unitEffects=fresh;base.lastEffect=last
    end
    return s
end
local function rebuild(previous,list)
    local out,map=table.create(#list),{}
    for _,entry in ipairs(list)do
        local item
        if entry._d then
            local prev=previous and previous[entry.id];if not prev then return nil end
            item=table.clone(prev)
            for k,v in pairs(entry)do if not SKIP[k]then item[k]=v end end
            for _,k in ipairs(entry._gone or {})do item[k]=nil end
        else item=entry end
        table.insert(out,item);map[item.id]=table.clone(item)
    end
    return out,map
end
function M.decode(base,s)
    if s.capturedBuf then s.captured=M.unpackCaptured(s.capturedBuf);s.capturedBuf=nil end
    if not s.stream then return true end
    if not s.delta then
        base.version=s.version
        base.factions={};for _,f in ipairs(s.factions or {})do base.factions[f.id]=table.clone(f)end
        base.units={};for _,u in ipairs(s.units or {})do base.units[u.id]=table.clone(u)end
        base.rails=s.rails;base.terrainChanges=s.terrainChanges;base.fallout=s.fallout;base.effects=table.clone(s.unitEffects or {})
        return true
    end
    if base.version~=s.version or not base.factions then base.factions=nil;return false end
    if s.factions then local list,map=rebuild(base.factions,s.factions);if not list then base.factions=nil;return false end;s.factions=list;base.factions=map end
    if s.units then local list,map=rebuild(base.units,s.units);if not list then base.factions=nil;return false end;s.units=list;base.units=map end
    if s.rails==nil then s.rails=base.rails else base.rails=s.rails end
    if s.terrainChanges==nil then s.terrainChanges=base.terrainChanges else base.terrainChanges=s.terrainChanges end
    if s.fallout==nil then s.fallout=base.fallout else base.fallout=s.fallout end
    if s.unitEffects then
        local list=base.effects or {};for _,e in ipairs(s.unitEffects)do table.insert(list,e)end
        while #list>M.effectWindow do table.remove(list,1)end
        base.effects=list;s.unitEffects=table.clone(list)
    end
    return true
end
return M
