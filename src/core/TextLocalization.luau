local rows=if script then require(script.Parent.LocalizationData)else require('./LocalizationData')
local M={};local exact,trie,formats={},{},{}
local function escape(s)return (s:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])','%%%1'))end
local function parse(s)
    local parts={};local i=1;local literal=''
    while i<=#s do
        if s:sub(i,i+1)=='%%'then literal..='%';i+=2
        else local token=s:sub(i):match('^%%[-+ #0]*%d*%.?%d*[sdfiug]')
            if token then
                table.insert(parts,{literal=literal});literal=''
                table.insert(parts,{argument=true,numeric=token:sub(-1)~='s'});i+=#token
            else literal..=s:sub(i,i);i+=1 end
        end
    end
    table.insert(parts,{literal=literal});return parts
end
for _,r in ipairs(rows)do
    exact[r[1]]=r[2]
    local parts=parse(r[1]);local n,pattern=0,'^'
    for _,p in ipairs(parts)do if p.argument then n+=1;pattern..=p.numeric and '([%d%.%+%-]+)'or '(.-)'else pattern..=escape(p.literal)end end
    if n>0 then table.insert(formats,{source=r[1],pattern=pattern..'$',parts=parse(r[2]),lines=r[1]:find('\n',1,true)~=nil})
    elseif #r[1]>0 then local node=trie;for i=1,#r[1]do local b=r[1]:byte(i);node[b]=node[b]or {};node=node[b]end;node.value=r[2];node.source=r[1] end
end
table.sort(formats,function(a,b)return #a.source>#b.source end)
local function fragments(s,names)
    local out={};local i=1
    while i<=#s do
        local protected
        for _,name in ipairs(names or {})do if #name>0 and s:sub(i,i+#name-1)==name then protected=name;break end end
        if protected then table.insert(out,protected);i+=#protected
        else
            local node=trie;local at=i;local value,last
            while at<=#s and node[s:byte(at)]do node=node[s:byte(at)];at+=1;if node.value~=nil then value=node.value;last=at end end
            if value~=nil then table.insert(out,value);i=last else table.insert(out,s:sub(i,i));i+=1 end
        end
    end;return table.concat(out)
end
local function translate(s,names,depth)
    if depth>0 and names and table.find(names,s)then return s end
    if exact[s]~=nil then return exact[s]end
    local multi=s:find('\n',1,true)~=nil
    if depth<=2 then for _,f in ipairs(formats)do if f.lines or not multi then local args={s:match(f.pattern)};if #args>0 then
        local out={};local n=0
        for _,p in ipairs(f.parts)do if p.argument then n+=1;table.insert(out,translate(args[n]or '',names,depth+1))else table.insert(out,p.literal)end end
        return table.concat(out)
    end end end end
    if multi then local out={};for line in (s..'\n'):gmatch('(.-)\n')do table.insert(out,translate(line,names,depth))end;return table.concat(out,'\n')end
    return fragments(s,names)
end
function M.translate(source,locale,names)
    if type(source)~='string'or locale:sub(1,2)=='ko'then return source end
    return translate(source,names,0)
end
function M.hasKorean(s)for _,c in utf8.codes(s)do if c>=0xAC00 and c<=0xD7A3 then return true end end;return false end
return M
