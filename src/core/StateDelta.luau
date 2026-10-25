--!native
local M={}
local nextEpoch=0
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
local function snapshot(value,copies)
    if type(value)~='table'then return value end
    if copies and copies[value]then return copies[value]end
    local out={};for k,v in pairs(value)do out[k]=snapshot(v,copies)end
    if copies then copies[value]=out end;return out
end
local function equal(a,b)
    if a==b then return true end
    if type(a)~='table'or type(b)~='table'then return a==b end
    for k,v in pairs(a)do if not equal(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end
    return true
end
local function ordering(canonical,list,key)
    local index={};for i,v in ipairs(canonical)do index[key and v[key]or v]=i end
    local runs={};local same=true
    for i,v in ipairs(list)do
        local at=index[key and v[key]or v];if at~=i then same=false end
        local n=#runs
        if n>0 and runs[n-1]+runs[n]==at then runs[n]+=1 else table.insert(runs,at);table.insert(runs,1)end
    end
    if same then return nil end
    local packed=buffer.create(#runs*4)
    for i,v in ipairs(runs)do buffer.writeu32(packed,(i-1)*4,v)end
    return packed
end
local function reorder(list,runs)
    if not runs then return list end
    local packed=type(runs)=='buffer'
    if not packed and type(runs)~='table'then return nil end
    local n=packed and buffer.len(runs)//4 or #runs
    if packed and buffer.len(runs)%8~=0 or n%2~=0 then return nil end
    local out,seen={},{}
    for i=1,n,2 do
        local first,count
        if packed then first,count=buffer.readu32(runs,(i-1)*4),buffer.readu32(runs,i*4)
        else first,count=runs[i],runs[i+1]end
        if type(first)~='number'or type(count)~='number'or first%1~=0 or count%1~=0 or first<1 or count<1 or first+count-1>#list then return nil end
        for j=first,first+count-1 do if seen[j]then return nil end;seen[j]=true;table.insert(out,list[j])end
    end
    return #out==#list and out or nil
end
local function listPatch(previous,list,key)
    if not previous or not list or previous==list then return nil end
    if #previous==0 then return #list>0 and {put=snapshot(list),remove={}}or nil end
    local old,now={},{}
    for _,v in ipairs(previous)do old[key and v[key]or v]=v end
    for _,v in ipairs(list)do now[key and v[key]or v]=v end
    local put,remove,canonical={},{},{}
    for _,v in ipairs(previous)do
        local id=key and v[key]or v
        if now[id]==nil then table.insert(remove,id)else table.insert(canonical,now[id])end
    end
    for _,v in ipairs(list)do
        local id=key and v[key]or v
        if old[id]==nil then table.insert(put,snapshot(v));table.insert(canonical,v)
        elseif key and not equal(old[id],v)then table.insert(put,snapshot(v))end
    end
    local order=ordering(canonical,list,key)
    if #put==0 and #remove==0 and not order then return nil end
    return {put=put,remove=remove,order=order}
end
local function applyList(previous,patch,key)
    if not previous or type(patch)~='table'or type(patch.put)~='table'or type(patch.remove)~='table'then return nil end
    local old,put,remove={},{},{}
    for _,v in ipairs(previous)do old[key and v[key]or v]=v end
    for _,id in ipairs(patch.remove)do if old[id]==nil or remove[id]then return nil end;remove[id]=true end
    for _,v in ipairs(patch.put)do
        local id=key and type(v)=='table'and v[key]or (not key and v)
        if type(id)~='number'or id~=id or put[id]~=nil or remove[id]then return nil end
        put[id]=v
    end
    local out={}
    for _,v in ipairs(previous)do local id=key and v[key]or v;if not remove[id]then table.insert(out,put[id]or v)end end
    for _,v in ipairs(patch.put)do if old[key and v[key]or v]==nil then table.insert(out,v)end end
    return reorder(out,patch.order)
end
local immutableLists=setmetatable({},{__mode='k'})
local railPatches=setmetatable({},{__mode='k'})
local falloutPatches=setmetatable({},{__mode='k'})
local function retain(list)
    if not list then return nil end
    if immutableLists[list]then return list end
    if table.isfrozen(list)then
        local safe=true
        for _,v in ipairs(list)do if type(v)=='table'and (not table.isfrozen(v)or type(v.tiles)=='table'and not table.isfrozen(v.tiles))then safe=false;break end end
        if safe then immutableLists[list]=true;return list end
    end
    return snapshot(list)
end
local function patchFor(previous,list,key)
    if not immutableLists[previous]or not immutableLists[list]then return listPatch(previous,list,key)end
    local cache=key and railPatches or falloutPatches;local row=cache[previous]
    if not row then row=setmetatable({},{__mode='k'});cache[previous]=row end
    local patch=row[list]
    if patch==nil then patch=listPatch(previous,list,key)or false;row[list]=patch end
    return patch or nil
end

local function diffList(previous,list,reuse)
    local out,map=table.create(#list),{}
    for _,item in ipairs(list)do
        local prev=previous and previous[item.id]
        local cached=reuse and prev and reuse.diffs[prev];cached=cached and cached[item]
        if cached then table.insert(out,cached.wire);map[item.id]=cached.base;continue end
        if prev then
            local d={id=item.id,_d=true};local gone;local changed=false
            for k,v in pairs(item)do if not equal(prev[k],v)then changed=true;d[k]=snapshot(v,reuse and reuse.copies)end end
            for k in pairs(prev)do if item[k]==nil then changed=true;gone=gone or {};table.insert(gone,k)end end
            d._gone=gone;table.insert(out,d)
            map[item.id]=changed and snapshot(item,reuse and reuse.copies)or prev
            if reuse then local row=reuse.diffs[prev];if not row then row={};reuse.diffs[prev]=row end;row[item]={wire=d,base=map[item.id]}end
        else table.insert(out,item);map[item.id]=snapshot(item,reuse and reuse.copies)end
    end
    return out,map
end
local function remember(base,s,reuse)
    base.factions={};for _,f in ipairs(s.factions or {})do base.factions[f.id]=snapshot(f,reuse and reuse.copies)end
    base.units={};for _,u in ipairs(s.units or {})do base.units[u.id]=snapshot(u,reuse and reuse.copies)end
    base.railRevision=s.railRevision;base.terrainRevision=s.terrainRevision;base.rails=retain(s.rails);base.fallout=retain(s.fallout)
    base.lastEffect=0;for _,e in ipairs(s.unitEffects or {})do base.lastEffect=math.max(base.lastEffect,e.id or 0)end
end
function M.encode(base,s,full,view,reuse)
    base.seq=(base.seq or 0)+1;s.stream=base.seq
    if type(s.captured)=='table'and #s.captured>0 then s.capturedBuf=packCaptured(s.captured);s.captured=nil end
    if full or base.version~=s.version or base.view~=view or not base.factions then
        nextEpoch+=1;base.epoch=nextEpoch;s.streamEpoch=base.epoch
        base.version=s.version;base.view=view;remember(base,s,reuse);return s
    end
    s.streamEpoch=base.epoch;s.delta=true;s.deltaBase=base.seq-1
    if s.factions then s.factions,base.factions=diffList(base.factions,s.factions,reuse)end
    if s.units then s.units,base.units=diffList(base.units,s.units,reuse)end
    if s.rails and base.rails then
        if base.rails~=s.rails then local next=retain(s.rails);s.railPatch=patchFor(base.rails,next,'id');base.rails=next end
        s.rails=nil
    else base.rails=retain(s.rails)end
    base.railRevision=s.railRevision
    if s.terrainRevision~=nil and s.terrainRevision==base.terrainRevision then s.terrainChanges=nil else base.terrainRevision=s.terrainRevision end
    if s.fallout and base.fallout then
        if base.fallout~=s.fallout then local next=retain(s.fallout);s.falloutPatch=patchFor(base.fallout,next);base.fallout=next end
        s.fallout=nil
    else base.fallout=retain(s.fallout)end
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
local function publish(base,s)
    if s.ownershipOnly then return end
    if s.rails then
        if equal(base.publishedRails,s.rails)then s.rails=base.publishedRails end
        base.publishedRails=s.rails
    end
    if s.fallout then
        if equal(base.publishedFallout,s.fallout)then s.fallout=base.publishedFallout end
        base.publishedFallout=s.fallout
    end
end

function M.decode(base,s)
    if s.capturedBuf then s.captured=M.unpackCaptured(s.capturedBuf);s.capturedBuf=nil end
    if not s.stream then publish(base,s);return true end
    if base.version and (s.version<base.version or s.version==base.version and
        ((s.snapshotSerial and base.serial and s.snapshotSerial<=base.serial)or
        (s.streamEpoch and base.epoch and s.streamEpoch<base.epoch)or
        (not s.snapshotSerial and (not s.streamEpoch or s.streamEpoch==base.epoch)and s.stream<=(base.seq or 0))))then return false end
    if not s.delta then
        base.version=s.version;base.seq=s.stream;base.serial=s.snapshotSerial;base.epoch=s.streamEpoch
        s.rails=equal(base.rails,s.rails)and base.rails or snapshot(s.rails)
        s.fallout=equal(base.fallout,s.fallout)and base.fallout or snapshot(s.fallout)
        publish(base,s)
        base.factions={};for _,f in ipairs(s.factions or {})do base.factions[f.id]=table.clone(f)end
        base.units={};for _,u in ipairs(s.units or {})do base.units[u.id]=table.clone(u)end
        base.rails=s.rails;base.terrainChanges=s.terrainChanges;base.fallout=s.fallout;base.effects=table.clone(s.unitEffects or {})
        s.streamEpoch=nil;return true
    end
    if base.version~=s.version or not base.factions or
        (s.deltaBase~=nil and s.deltaBase~=base.seq)or
        (s.streamEpoch~=nil and s.streamEpoch~=base.epoch)then base.factions=nil;return false end
    local rails=s.rails or base.rails;local fallout=s.fallout or base.fallout
    if s.railPatch then rails=applyList(base.rails,s.railPatch,'id');if not rails then base.factions=nil;return false end
    elseif s.rails and equal(base.rails,s.rails)then rails=base.rails end
    if s.falloutPatch then fallout=applyList(base.fallout,s.falloutPatch);if not fallout then base.factions=nil;return false end
    elseif s.fallout and equal(base.fallout,s.fallout)then fallout=base.fallout end
    if s.factions then local list,map=rebuild(base.factions,s.factions);if not list then base.factions=nil;return false end;s.factions=list;base.factions=map end
    if s.units then local list,map=rebuild(base.units,s.units);if not list then base.factions=nil;return false end;s.units=list;base.units=map end
    s.rails=rails;s.fallout=fallout;publish(base,s)
    base.rails=s.rails
    if s.terrainChanges==nil then s.terrainChanges=base.terrainChanges else base.terrainChanges=s.terrainChanges end
    base.fallout=s.fallout
    if s.unitEffects then
        local list=base.effects or {};for _,e in ipairs(s.unitEffects)do table.insert(list,e)end
        while #list>M.effectWindow do table.remove(list,1)end
        base.effects=list;s.unitEffects=table.clone(list)
    end
    base.seq=s.stream;base.serial=s.snapshotSerial
    s.deltaBase=nil;s.streamEpoch=nil;s.railPatch=nil;s.falloutPatch=nil
    return true
end
return M
