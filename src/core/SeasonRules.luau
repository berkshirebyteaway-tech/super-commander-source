local Monthly=if script then require(script.Parent.MonthlySeason)else require('./MonthlySeason')
local Period=if script then require(script.Parent.PeriodProgress)else require('./PeriodProgress')
local M={}
M.steps={{score=2000,coins=100},{score=4000,coins=100},{score=6000,coins=150},{score=8000,coins=150},{score=10000,coins=200},{score=12000,coins=300}}
M.tiers=#M.steps
M.tierXP=400
M.countSeconds=120
M.modes={single=true,pvp=true,coop=true}
M.seasons={
    {id=0,name='프리시즌',start=1791590400,finish=1793491200,tierXP=400,legacy={
        [10]={kind='plate',id='s0:p10',name='프리시즌 강철',color={96,112,132}},
        [20]={kind='plate',id='s0:p20',name='프리시즌 청록',color={40,180,170}},
        [30]={kind='plate',id='s0:p30',name='프리시즌 금장',color={232,184,72}},
    }},
}
M.names={[1]='프리시즌2'}
local generated={}
function M.get(n)
    if type(n)~='number'or n%1~=0 or n<0 then return nil end
    for _,x in ipairs(M.seasons)do if x.id==n then return x end end
    if n<1 then return nil end
    local g=generated[n];if g then return g end
    g={id=n,name=M.names[n]or string.format('시즌 %d',n),start=Monthly.start(n),finish=Monthly.finish(n),tierXP=M.tierXP,legacy={}}
    generated[n]=g;return g
end
local written={};for _,s in ipairs(M.seasons)do written[s.id]=s.finish end
function M.setEnd(text,now)
    local s;for _,x in ipairs(M.seasons)do if x.start<=(now or 0)then s=x end end;if not s then return false end
    local y,m,d=tostring(text or ''):match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
    local t=y and os.time({year=tonumber(y),month=tonumber(m),day=tonumber(d),hour=0,min=0,sec=0})
    local cap=s.id==0 and Monthly.start(1)or Monthly.finish(s.id)
    if not t or t<=s.start or t>cap then s.finish=written[s.id];return false end
    s.finish=t;return true
end
function M.at(time)
    time=time or 0
    for _,s in ipairs(M.seasons)do if time>=s.start and time<s.finish then return s end end
    local n=Monthly.number(time)
    if n>=1 then local s=M.get(n);if s and time>=s.start and time<s.finish then return s end end
    return nil
end
function M.reached(score)
    local n=0;for i,step in ipairs(M.steps)do if (score or 0)>=step.score then n=i end end;return n
end
local function current(p,s)
    local cur=Period.select(p,'season','seasonHistory','id',s.id,3,function()return {id=s.id,xp=0,tier=0,step=0}end)
    if not cur then return nil end
    if cur.step==nil then cur.step=0 end
    return cur
end
function M.add(p,xp,time)
    local s=M.at(time or 0);if not s or xp<=0 then return end
    local cur=current(p,s);if not cur then return end
    cur.xp+=xp
    local reached=M.reached(cur.xp)
    for i=cur.step+1,reached do p.medals+=M.steps[i].coins end
    cur.step=math.max(cur.step,reached);cur.tier=cur.step
end
function M.record(p,mode,won,seconds,time)
    if not M.modes[mode]or (seconds or 0)<M.countSeconds then return false end
    local s=M.at(time or 0);if not s then return false end
    local cur=current(p,s);if not cur then return false end
    cur.stats=type(cur.stats)=='table'and cur.stats or {}
    local row=cur.stats[mode]or {w=0,l=0};cur.stats[mode]=row
    if won then row.w+=1 else row.l+=1 end
    return true
end
function M.owned(p)
    local out={};if type(p.seasonRewards)~='table'then return out end
    for id in pairs(p.seasonRewards)do
        local n=type(id)=='string'and tonumber(id:match('^s(%d+):'))
        local s=n and M.get(n)
        if s then for _,r in pairs(s.legacy or {})do if r.id==id then out[id]=r end end end
    end
    return out
end
function M.view(p,now)
    local s=M.at(now);if not s then return nil end
    local cur=type(p.season)=='table'and p.season.id==s.id and p.season or {xp=0,step=0}
    local step=cur.step or 0
    local steps={};for i,v in ipairs(M.steps)do steps[i]={score=v.score,coins=v.coins,got=i<=step}end
    local nextStep=M.steps[step+1]
    local stats={};local wins,losses=0,0
    for mode in pairs(M.modes)do local r=type(cur.stats)=='table'and cur.stats[mode]or {w=0,l=0};stats[mode]={w=r.w or 0,l=r.l or 0};wins+=r.w or 0;losses+=r.l or 0 end
    return {id=s.id,name=s.name,xp=cur.xp,score=cur.xp,tier=step,tiers=M.tiers,steps=steps,stats=stats,wins=wins,losses=losses,
        finish=s.finish,daysLeft=math.max(0,math.ceil((s.finish-now)/86400)),
        next=nextStep and {tier=step+1,score=nextStep.score,coins=nextStep.coins,left=nextStep.score-cur.xp}or nil,
        tierXP=s.tierXP or M.tierXP,current=cur.xp}
end
return M
