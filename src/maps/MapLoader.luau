local Catalog=if script then require(script.Parent.Catalog) else require("./Catalog")
local M={catalog=Catalog}
local byKey={};for _,m in ipairs(Catalog)do byKey[m.key]=m end
function M.meta(key)
    return byKey[key]
end
local B64={};do local a="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";for i=1,64 do B64[string.byte(a,i)]=i-1 end end
local function base64(parts:{string}):(buffer,number)
    local total=0;for _,s in ipairs(parts)do total+=#s end
    local out=buffer.create(total//4*3);local o=0
    for _,s in ipairs(parts)do
        assert(#s%4==0,"Invalid map base64")
        for i=1,#s,4 do
            local a,b,c,d=string.byte(s,i,i+3)
            local va,vb=B64[a],B64[b];assert(va and vb,"Invalid map base64")
            local n=va*262144+vb*4096
            if d==61 then
                if c==61 then buffer.writeu8(out,o,n//65536);o+=1
                else n+=B64[c]*64;buffer.writeu8(out,o,n//65536);buffer.writeu8(out,o+1,n//256%256);o+=2 end
            else
                n+=B64[c]*64+B64[d]
                buffer.writeu8(out,o,n//65536);buffer.writeu8(out,o+1,n//256%256);buffer.writeu8(out,o+2,n%256);o+=3
            end
        end
    end
    return out,o
end
local LBASE={3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,67,83,99,115,131,163,195,227,258}
local LEXTRA={0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0}
local DBASE={1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577}
local DEXTRA={0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13}
local ORDER={17,18,19,1,9,8,10,7,11,6,12,5,13,4,14,3,15,2,16}
local function huffman(lengths:{number},first:number,n:number)
    local counts=table.create(16,0);local offs=table.create(16,0);local symbols=table.create(n,0)
    for i=first,first+n-1 do local l=lengths[i];if l>0 then counts[l]+=1 end end
    local sum=0;for l=1,15 do offs[l]=sum;sum+=counts[l] end
    for i=0,n-1 do local l=lengths[first+i];if l>0 then offs[l]+=1;symbols[offs[l]]=i end end
    return {counts=counts,symbols=symbols}
end
local fixedLit,fixedDist
do
    local l=table.create(320,0)
    for i=1,144 do l[i]=8 end;for i=145,256 do l[i]=9 end;for i=257,280 do l[i]=7 end;for i=281,288 do l[i]=8 end
    for i=289,318 do l[i]=5 end
    fixedLit=huffman(l,1,288);fixedDist=huffman(l,289,30)
end
local function inflate(src:buffer,srcLen:number,outLen:number):buffer
    local out=buffer.create(outLen);local op=0;local pos=0;local bits=0;local nbits=0
    local function need(n)
        while nbits<n do
            local b=if pos<srcLen then buffer.readu8(src,pos)else 0;pos+=1
            bits+=bit32.lshift(b,nbits);nbits+=8
        end
    end
    local function take(n)
        if n==0 then return 0 end
        need(n);local v=bit32.extract(bits,0,n);bits=bit32.rshift(bits,n);nbits-=n;return v
    end
    local function decode(t)
        local counts,cur,sum,len=t.counts,0,0,0
        repeat
            if nbits==0 then need(1)end
            cur=cur*2+bit32.band(bits,1);bits=bit32.rshift(bits,1);nbits-=1
            len+=1;if len>15 then error("Invalid map code")end
            local c=counts[len];sum+=c;cur-=c
        until cur<0
        return t.symbols[sum+cur+1]
    end
    local final
    repeat
        final=take(1)==1;local kind=take(2)
        if kind==0 then
            take(nbits%8);local len=take(16);local inv=take(16)
            assert(bit32.bxor(len,inv)==65535,"Invalid map block")
            for _=1,len do buffer.writeu8(out,op,take(8));op+=1 end
        else
            local lit,dist=fixedLit,fixedDist
            if kind==2 then
                local hlit,hdist,hclen=take(5)+257,take(5)+1,take(4)+4
                local cl=table.create(19,0);for i=1,hclen do cl[ORDER[i]]=take(3)end
                local clt=huffman(cl,1,19);local lengths=table.create(hlit+hdist,0);local i=1
                while i<=hlit+hdist do
                    local sym=decode(clt)
                    if sym<16 then lengths[i]=sym;i+=1
                    else
                        local value,count=0,0
                        if sym==16 then assert(i>1,"Invalid map lengths");value=lengths[i-1];count=3+take(2)
                        elseif sym==17 then count=3+take(3)else count=11+take(7)end
                        for _=1,count do lengths[i]=value;i+=1 end
                    end
                end
                lit=huffman(lengths,1,hlit);dist=huffman(lengths,hlit+1,hdist)
            elseif kind~=1 then error("Invalid map block")end
            while true do
                local sym=decode(lit)
                if sym<256 then buffer.writeu8(out,op,sym);op+=1
                elseif sym==256 then break
                else
                    local li=sym-256;local len=LBASE[li]+take(LEXTRA[li])
                    local di=decode(dist)+1;local d=DBASE[di]+take(DEXTRA[di])
                    assert(d<=op and op+len<=outLen,"Invalid map data")
                    if d==1 then buffer.fill(out,op,buffer.readu8(out,op-1),len)
                    elseif d>=len then buffer.copy(out,op,out,op-d,len)
                    else for k=0,len-1 do buffer.writeu8(out,op+k,buffer.readu8(out,op-d+k))end end
                    op+=len
                end
            end
        end
    until final
    assert(op==outLen,"Incomplete map")
    return out
end
local function expand(parts:{string},length:number):buffer
    local packed,size=base64(parts)
    return inflate(packed,size,length)
end
local previewCache={}
function M.preview(key)
    local cached=previewCache[key]
    if cached then return {meta={width=cached.meta.width,height=cached.meta.height},terrain=buffer.fromstring(buffer.tostring(cached.terrain))} end
    local previews=if script then require(script.Parent.PreviewCatalog)else require("./PreviewCatalog")
    for _,p in ipairs(previews)do if p.key==key then
        local packed=if script then require(script.Parent[p.module])else require("./"..p.module)
        local preview={meta={width=p.width,height=p.height},terrain=expand({packed},p.width*p.height)}
        previewCache[key]=preview;return M.preview(key)
    end end
    error("Unknown map preview")
end
function M.hasNormal(key) local m=M.meta(key);return m~=nil and m.normal~=nil end
M.storeSource=nil
function M.stored(key) local m=M.meta(key);return m~=nil and m.normal~=nil and m.normal.store~=nil end
local function partCount(meta) return if meta.store then meta.store.parts else #meta.modules end
local sized={}
function M.sized(key,size)
    local m=M.meta(key)
    if m==nil or size~="normal" or m.normal==nil then return m end
    local c=sized[key];if c and c.base==m then return c.meta end
    local n=m.normal;local meta=table.clone(m)
    local function double(list) local out={};for i,v in ipairs(list or {}) do local x=table.clone(v);if x.x then x.x*=2;x.y*=2 end;out[i]=x end;return out end
    meta.width=n.width;meta.height=n.height;meta.landTiles=n.landTiles;meta.modules=n.modules;meta.store=n.store;meta.bytes=n.bytes;meta.fnv32=n.fnv32;meta.sha256=nil
    meta.spawnAreas=n.spawnAreas;meta.nations=double(m.nations);meta.additionalNations=double(m.additionalNations);meta.customTribes=double(m.customTribes)
    meta.mini={width=m.width,height=m.height,modules=m.modules,fnv32=m.fnv32}
    meta.mapSize="normal";meta.normal=nil
    sized[key]={base=m,meta=meta};return meta
end
function M.fromTerrain(key,terrain)
    local meta=M.meta(key);assert(meta,'Unknown map')
    if typeof(terrain)=='buffer'and meta.normal and buffer.len(terrain)==meta.normal.width*meta.normal.height then meta=M.sized(key,"normal")end
    assert(typeof(terrain)=='buffer'and buffer.len(terrain)==meta.width*meta.height,'Invalid selected map terrain')
    return {meta=meta,terrain=buffer.fromstring(buffer.tostring(terrain))}
end
function M.fromPacked(key,parts)
    local meta=M.sized(key,"normal");assert(meta and meta.mapSize=="normal",'Unknown map')
    assert(type(parts)=='table'and #parts==partCount(meta),'Invalid selected map terrain')
    for _,p in ipairs(parts)do assert(type(p)=='string','Invalid selected map terrain')end
    return {meta=meta,terrain=expand(parts,meta.width*meta.height)}
end
function M.loadMini(meta)
    local mini=meta and meta.mini;assert(mini,"Map has no minimap")
    local directory=script and (game:GetService('RunService'):IsServer()and game:GetService('ServerStorage'):FindFirstChild('FrontierMapData')or script.Parent)
    local parts={}
    for _,name in ipairs(mini.modules) do table.insert(parts,if script then require(directory[name]) else require("./"..name))end
    return expand(parts,mini.width*mini.height)
end
function M.normalParts(key)
    local meta=M.sized(key,"normal");if not meta or meta.mapSize~="normal" then return nil end
    if meta.store then return if M.storeSource then (M.storeSource(meta)) else nil end
    local directory=script and game:GetService('ServerStorage'):FindFirstChild('FrontierMapData')
    local parts={}
    for _,name in ipairs(meta.modules) do table.insert(parts,if script then require(directory[name]) else require("./"..name))end
    return parts
end
function M.expandChecked(meta,parts)
    assert(type(parts)=='table'and #parts==partCount(meta),'Invalid map parts')
    local terrain=expand(parts,meta.width*meta.height)
    local hash=2166136261
    for i=0,buffer.len(terrain)-1 do
        local n=bit32.bxor(hash,buffer.readu8(terrain,i))
        hash=((n%65536)*403+(((n//65536*403+(n%65536)*256)%65536)*65536))%4294967296
    end
    assert(hash==meta.fnv32,'Map parts do not match the catalog')
    return terrain
end
function M.load(key,size)
    local meta=M.sized(key,size)
    assert(meta,"Unknown map")
    local directory=script and (game:GetService('RunService'):IsServer()and game:GetService('ServerStorage'):FindFirstChild('FrontierMapData')or script.Parent)
    local parts={}
    local terrain
    if meta.store then
        local stored,checked
        if M.storeSource then stored,checked=M.storeSource(meta)end
        parts=assert(stored,"Map store unavailable");terrain=checked and buffer.fromstring(buffer.tostring(checked))
    else for _,name in ipairs(meta.modules) do table.insert(parts,if script then require(directory[name]) else require("./"..name))end end
    local map={meta=meta,terrain=terrain or expand(parts,meta.width*meta.height),packed=if meta.mapSize=="normal" then parts else nil}
    if meta.mini and (not script or game:GetService('RunService'):IsServer()) then
        map.mini={terrain=M.loadMini(meta),width=meta.mini.width,height=meta.mini.height}
    end
    return map
end
return M
