local B={};local BASE=10000000
local function trim(a) while #a>1 and a[#a]==0 do table.remove(a) end;return a end
function B.fromString(s)
    assert(type(s)=="string" and s:match("^%d+$"),"Invalid nonnegative integer")
    local a={};for i=#s,1,-7 do table.insert(a,tonumber(s:sub(math.max(1,i-6),i))) end;return trim(a)
end
function B.fromNumber(n)
    assert(n>=0 and n<=9007199254740991 and n%1==0,"Integer outside exact number range")
    return B.fromString(string.format("%.0f",n))
end
function B.toString(a)
    local s=tostring(a[#a]);for i=#a-1,1,-1 do s..=string.format("%07d",a[i]) end;return s
end
function B.compare(a,b)
    if #a~=#b then return #a<#b and -1 or 1 end
    for i=#a,1,-1 do if a[i]~=b[i] then return a[i]<b[i] and -1 or 1 end end;return 0
end
function B.add(a,b)
    local out,carry={},0
    for i=1,math.max(#a,#b) do local n=(a[i] or 0)+(b[i] or 0)+carry;out[i]=n%BASE;carry=math.floor(n/BASE) end
    if carry>0 then table.insert(out,carry) end;return out
end
function B.subtract(a,b)
    assert(B.compare(a,b)>=0,"Negative BigNat result")
    local out,borrow={},0
    for i=1,#a do local n=a[i]-(b[i] or 0)-borrow;borrow=n<0 and 1 or 0;out[i]=n+borrow*BASE end;return trim(out)
end
function B.divideSmall(a,n)
    assert(n>=1 and n<=10000000 and n%1==0)
    local out,remain={},0
    for i=#a,1,-1 do local v=remain*BASE+a[i];out[i]=math.floor(v/n);remain=v%n end
    return trim(out),remain
end
return B
