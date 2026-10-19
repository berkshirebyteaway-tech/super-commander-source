--!native
local M={}
M.window=600
function M.add(owner,key,seconds)
    local all=owner.perf;if not all then all={};owner.perf=all end
    local r=all[key];if not r then r={n=0,i=0,max=0,sum=0,samples=table.create(M.window,0)};all[key]=r end
    r.n+=1;r.sum+=seconds;if seconds>r.max then r.max=seconds end
    r.i=r.i%M.window+1;r.samples[r.i]=seconds
end
function M.summary(owner,reset)
    local out={}
    for key,r in pairs(owner.perf or {})do
        local list=table.clone(r.samples);local filled=math.min(r.n,M.window);table.sort(list,function(a,b)return a>b end)
        local function at(q)if filled==0 then return 0 end;return list[math.max(1,math.ceil(filled*(1-q)))]*1000 end
        out[key]={count=r.n,avg=r.n>0 and r.sum/r.n*1000 or 0,p50=at(.5),p95=at(.95),p99=at(.99),max=r.max*1000}
    end
    if reset then owner.perf=nil end
    return out
end
return M
