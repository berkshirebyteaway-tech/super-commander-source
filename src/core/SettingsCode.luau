local Rules=if script then require(script.Parent.CustomBattlefieldRules)else require('./CustomBattlefieldRules')
local M={prefix='SC1',maxLength=4096,maxBytes=2800}
local alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_'
local reverse={};for i=1,64 do reverse[alphabet:sub(i,i)]=i-1 end
local function hash(s)
    local h=2166136261;for i=1,#s do h=bit32.bxor(h,s:byte(i));h=(h%65536*16777619+(h//65536*16777619%65536)*65536)%2^32 end
    return string.format('%08X',h)
end
local function b64(s)
    local out={}
    for i=1,#s,3 do local a,b,c=s:byte(i,i+2);local v=a*65536+(b or 0)*256+(c or 0)
        for j=0,(c and 3 or b and 2 or 1)do local n=math.floor(v/2^(18-6*j))%64;table.insert(out,alphabet:sub(n+1,n+1))end
    end;return table.concat(out)
end
local function unb64(s)
    if #s%4==1 or #s>M.maxLength then return nil end
    local out={};local value,bits=0,0
    for i=1,#s do local n=reverse[s:sub(i,i)];if n==nil then return nil end
        value=value*64+n;bits+=6
        if bits>=8 then bits-=8;local shift=2^bits;table.insert(out,string.char(value//shift));value%=shift end
    end
    if value~=0 then return nil end
    local text=table.concat(out);if #text>M.maxBytes then return nil end;return text
end
local function pack(v,depth)
    assert(depth<=5,'depth')
    local t=type(v)
    if t=='boolean'then return v and 't'or 'f'end
    if t=='number'then assert(v==v and math.abs(v)<math.huge,'number');local s=string.format('%.17g',v);return 'n'..#s..':'..s end
    if t=='string'then return 's'..#v..':'..v end
    assert(t=='table','type');local keys={};for k in pairs(v)do table.insert(keys,k)end;assert(#keys<=64,'keys')
    if #v>0 then assert(#v==#keys,'array');local out={'a'..#v..':'};for _,x in ipairs(v)do table.insert(out,pack(x,depth+1))end;return table.concat(out)end
    table.sort(keys);local out={'o'..#keys..':'};for _,k in ipairs(keys)do assert(type(k)=='string','key');table.insert(out,pack(k,depth+1));table.insert(out,pack(v[k],depth+1))end;return table.concat(out)
end
local function unpack(text)
    local cursor=1
    local function length()
        local stop=text:find(':',cursor,true);assert(stop and stop-cursor<=4,'length')
        local digits=text:sub(cursor,stop-1);assert(digits:match('^%d+$'),'digits');local n=tonumber(digits);assert(n and n<=M.maxBytes,'bound');cursor=stop+1;return n
    end
    local read
    read=function(depth)
        assert(depth<=5 and cursor<=#text,'depth');local tag=text:sub(cursor,cursor);cursor+=1
        if tag=='t'then return true elseif tag=='f'then return false end
        if tag=='s'or tag=='n'then local n=length();assert(cursor+n-1<=#text,'truncated');local s=text:sub(cursor,cursor+n-1);cursor+=n
            if tag=='s'then return s end
            assert(n<=24,'number');local v=tonumber(s);assert(v and v==v and math.abs(v)<math.huge,'number');return v
        end
        assert(tag=='o'or tag=='a','tag');local n=length();assert(n<=64,'keys');local out={}
        for i=1,n do
            if tag=='a'then out[i]=read(depth+1)
            else local k=read(depth+1);assert(type(k)=='string'and #k<=64 and out[k]==nil,'key');out[k]=read(depth+1)end
        end;return out
    end
    local value=read(0);assert(cursor==#text+1,'trailing');return value
end
function M.encode(raw)
    local r,err=Rules.normalize(raw);if not r then return nil,err end
    r.visibility='invite'
    local ok,text=pcall(pack,r,0);if not ok or #text>M.maxBytes then return nil,'settings-code'end
    return M.prefix..'.'..b64(text)..'.'..hash(text)
end
function M.decode(code)
    if type(code)~='string'or #code>M.maxLength then return nil,'settings-code'end
    code=code:gsub('%s','');local body,checksum=code:match('^SC1%.([%w_-]+)%.([%x]+)$')
    if not body or #checksum~=8 then return nil,'settings-code'end
    local text=unb64(body);if not text or hash(text)~=checksum:upper()then return nil,'settings-code'end
    local ok,raw=pcall(unpack,text);if not ok then return nil,'settings-code'end
    local r,err=Rules.normalize(raw);if not r then return nil,err end;r.visibility='invite';return r
end
return M
