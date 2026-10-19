local M={}
M.order={'normal','rare','epic','legendary','mythic'}
M.rank={normal=1,rare=2,epic=3,legendary=4,mythic=5}
M.scripts={
    normal={{1,{1,1,1}}},
    rare={{.7,{1,2,2}},{.3,{1,1,2}}},
    epic={{.45,{3,3,3}},{.35,{1,2,3}},{.2,{1,1,2}}},
    legendary={{.35,{4,4,4}},{.4,{1,3,4}},{.25,{1,2,3}}},
    mythic={{.25,{5,5,5}},{.45,{4,4,4}},{.3,{1,3,4}}},
}
M.lampHold={.3,.5,.8,1.2}
M.lampStall={lamp=3,from=.7,to=.84,rate=.25}

M.doors=1.05
M.revealTotal={normal={2.5,.5},rare={3.5,.8},epic={5,1},legendary={8,1.5},mythic={13,2}}
M.reveal={};for k,v in pairs(M.revealTotal)do M.reveal[k]={v[1]-M.doors,v[2]}end
M.ladder={
    orbit={0,.35,math.pi,math.pi*1.25,math.pi*1.5},
    zoom={0,4,5,6,7},
    slowmo={0,0,.3,.4,.5},
    beam={0,.5,.5,.9,.9},
    coins={4,6,10,18,30},
}
M.from={beam=2,zoom=2,particles=3,vignette=3,slowmo=3,letterbox=4,goldPillar=4,shake=4,flare=4,
    aurora=5,crane=5,freeze=5,prismFlash=5,serial=5,shatter=5}
M.freeze=.8
M.budget={pc={0,20,60,150,250},phone={0,10,30,70,120}}
M.particles={
    {name='Sparks',from=3,pc=30,phone=14,life=1.8},
    {name='Motes',from=4,pc=38,phone=18,life=2.4},
    {name='Prism',from=5,pc=40,phone=20,life=2.4},
}
function M.particleLoad(tier,phone)
    local n=0;for _,e in ipairs(M.particles)do if tier>=e.from then n+=(phone and e.phone or e.pc)*e.life end end;return n
end
function M.features(tier)local out={};for k,v in pairs(M.from)do if tier>=v then out[k]=true end end;return out end
function M.unskippable(result)
    return result.sequence==1 or(M.rank[result.rarity]==5 and result.duplicate~=true)
end
function M.unit(key)
    local h=7
    for i=1,#key do h=(h*31+string.byte(key,i))%2147483647 end
    for _=1,3 do h=(h*48271)%2147483647 end
    return h/2147483647
end
function M.pick(rarity,key)
    local tier=M.rank[rarity]or 1;local list=M.scripts[M.order[tier]]
    local u=M.unit(tostring(key or ''));local sum=0;local chosen=list[#list]
    for _,s in ipairs(list)do sum+=s[1];if u<sum then chosen=s;break end end
    local b=chosen[2]
    local out={tier=tier,plane=b[1],chute=b[2],land=b[3],seals={},final=tier}
    for i=1,tier-1 do out.seals[i]=math.max(b[3],i+1)end
    out.escort=b[1]>=4;out.stealth=b[1]>=5;out.flare=b[3]>=4
    return out
end
M.boxTier={basic=1,epic=3,legendary=4,mythic=5}
function M.floor(s,kind)
    local b=math.min(M.boxTier[kind]or 1,s.final)
    if b<=1 then return s end
    local out={tier=s.tier,final=s.final,plane=math.max(s.plane,b),chute=math.max(s.chute,b),land=math.max(s.land,b),seals={}}
    for i,g in ipairs(s.seals)do out.seals[i]=math.max(g,b)end
    out.escort=out.plane>=4;out.stealth=out.plane>=5;out.flare=out.land>=4
    return out
end
M.mythicHue={lo=.80,hi=.92,satLo=.44,satHi=.60}
function M.mythicLight(f)
    f=f%1;local w=1-math.abs(2*f-1)
    return M.mythicHue.lo+(M.mythicHue.hi-M.mythicHue.lo)*w,M.mythicHue.satLo+(M.mythicHue.satHi-M.mythicHue.satLo)*(1-w)
end
function M.sequence(s)
    local seq={s.plane,s.chute,s.land};for _,v in ipairs(s.seals)do table.insert(seq,v)end
    table.insert(seq,s.final);return seq
end
function M.honest(s)
    local seq=M.sequence(s);local last=0
    for _,v in ipairs(seq)do if v<last or v>s.final then return false end;last=v end
    return #s.seals==s.final-1
end
return M
