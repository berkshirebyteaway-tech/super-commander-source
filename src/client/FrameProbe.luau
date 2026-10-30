local M={on=false,stats={},latencyStats={},cap=20000}
local clock=os.clock
local open={}
local epoch=0
local function record(stats,name,ms)
    local s=stats[name];if not s then s={n=0,sum=0,max=0,samples={}};stats[name]=s end
    s.n+=1;s.sum+=ms;if ms>s.max then s.max=ms end
    if #s.samples<M.cap then table.insert(s.samples,ms)end
end
function M.start(name)
    debug.profilebegin(name)
    if M.on then open[name]=clock()end
end
function M.stop(name)
    debug.profileend()
    if not M.on then return end
    local t=open[name];if not t then return end
    open[name]=nil
    record(M.stats,name,(clock()-t)*1000)
end
function M.startLatency(name)
    if not M.on then return nil end
    return {name=name,at=clock(),epoch=epoch}
end
function M.stopLatency(token)
    if not token or token.at==nil then return end
    local at=token.at;token.at=nil
    if not M.on or token.epoch~=epoch then return end
    record(M.latencyStats,token.name,(clock()-at)*1000)
end
function M.reset()
    epoch+=1;table.clear(M.stats);table.clear(M.latencyStats);table.clear(open)
end
local function report(stats)
    local out={}
    for name,s in pairs(stats)do
        local list=table.clone(s.samples);table.sort(list)
        local function at(q)return #list>0 and list[math.max(1,math.ceil(#list*q))]or 0 end
        local over=0;for _,ms in ipairs(list)do if ms>4 then over+=1 end end
        out[name]={n=s.n,mean=s.n>0 and s.sum/s.n or 0,p95=at(.95),p99=at(.99),max=s.max,over4=over}
    end
    return out
end
function M.report()return report(M.stats)end
function M.latencyReport()return report(M.latencyStats)end
return M
