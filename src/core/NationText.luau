local data=if script then require(script.Parent.NationNamesKoData)else require('./NationNamesKoData')
local M={}
local byWord={}
for en in pairs(data)do
    local first=en:match('^%w+')
    if first then local list=byWord[first]or {};byWord[first]=list;table.insert(list,en)end
end
for _,list in pairs(byWord)do table.sort(list,function(a,b)return #a>#b end)end
local cache,count={},0
function M.ko(s,names)
    if type(s)~='string'or s==''then return s end
    local whole=data[s]
    if whole then for _,name in ipairs(names or {})do if name==s then return s end end;return whole end
    if not s:find('%a%a')then return s end
    if cache[s]then return cache[s]end
    local out,i,n={},1,#s
    while i<=n do
        local start=s:find('[%w]',i)
        if not start then table.insert(out,s:sub(i));break end
        table.insert(out,s:sub(i,start-1))
        local word=s:match('^%w+',start)
        local list=start==1 or not s:sub(start-1,start-1):match('[%w]')
        list=list and not s:sub(1,start-1):match('%a[ ]*$')and byWord[word]
        local hit
        if list then for _,en in ipairs(list)do
            local stop=start+#en-1
            if s:sub(start,stop)==en and not s:sub(stop+1,stop+1):match('[%w]')and not s:sub(stop+1):match('^[ ]*%a')then
                local guarded=false
                for _,name in ipairs(names or {})do if name==en then guarded=true;break end end
                if not guarded then hit=en;break end
            end
        end end
        if hit then table.insert(out,data[hit]);i=start+#hit
        else local stop=s:find('[^%w]',start)or n+1;table.insert(out,s:sub(start,stop-1));i=stop end
    end
    local value=table.concat(out)
    if count>=2048 then cache={};count=0 end;cache[s]=value;count+=1
    return value
end
M.data=data
return M
