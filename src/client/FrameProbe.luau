local M={on=false,stats={},cap=20000}
local clock=os.clock
local open={}
function M.start(name)
    debug.profilebegin(name)
    if M.on then open[name]=clock()end
end
function M.stop(name)
    debug.profileend()
    if not M.on then return end
    local t=open[name];if not t then return end
    open[name]=nil
    local ms=(clock()-t)*1000
    local s=M.stats[name];if not s then s={n=0,sum=0,max=0,samples={}};M.stats[name]=s end
    s.n+=1;s.sum+=ms;if ms>s.max then s.max=ms end
    if #s.samples<M.cap then table.insert(s.samples,ms)end
end
function M.reset()table.clear(M.stats);table.clear(open)end
function M.report()
    local out={}
    for name,s in pairs(M.stats)do
        local list=table.clone(s.samples);table.sort(list)
        local function at(q)return #list>0 and list[math.max(1,math.ceil(#list*q))]or 0 end
        local over=0;for _,ms in ipairs(list)do if ms>4 then over+=1 end end
        out[name]={n=s.n,mean=s.n>0 and s.sum/s.n or 0,p95=at(.95),p99=at(.99),max=s.max,over4=over}
    end
    return out
end
return M
