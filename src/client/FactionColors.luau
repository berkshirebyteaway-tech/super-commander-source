local Identity=require(script.Parent.Parent.Core.ToyIdentity)
local Variants=require(script.Parent.Parent.Core.TeamColorVariants)
local Shades=require(script.Parent.Parent.Core.TeamMateShades)
local M={};local cache={}
M.self=Color3.fromRGB(54,226,208)
M.palette={}
for i,c in ipairs({
    {236,72,153},{245,158,11},{59,130,246},{163,230,53},{250,215,225},{100,140,110},{133,77,14},{124,58,237},
    {150,130,150},{200,200,140},{230,150,100},{80,200,120},{125,211,252},{240,171,252},{170,190,180},{252,211,77},
    {48,178,180},{190,150,130},{179,136,255},{217,70,239},{204,204,255},{230,130,180},{200,160,110},{134,239,172},
    {100,160,80},{210,210,100},{140,180,140},{202,225,255},{180,170,140},{140,150,180},{180,130,180},{140,180,220},
    {190,170,100},{251,146,60},{230,180,80},{230,180,180},{234,179,8},{82,183,136},{170,190,100},{150,110,190},
    {202,138,4},{180,100,230},{210,160,200},{180,160,180},{130,170,190},{130,180,170},{210,100,160},{52,211,153},
    {132,204,22},{79,70,229},{96,165,250},{147,197,253},{100,180,230},{210,140,80},{255,204,229},{130,200,130},
    {74,222,128},{56,189,248},{34,197,94},{233,213,255},{160,190,160},{16,185,129},{120,160,200},{180,210,120},
    {170,140,190},{244,114,182},{168,85,247},{220,220,255},{160,120,160},{160,180,140},{251,191,36},{147,51,234},
    {190,92,251},{192,132,252},{170,150,170},{99,202,253}
})do M.palette[i]=Color3.fromRGB(c[1],c[2],c[3])end
local tribe={}
for i,shade in ipairs(Identity.localShades)do tribe[i]=Color3.fromRGB(table.unpack(shade))end
M.teamPalette={
    Color3.fromRGB(59,130,246),Color3.fromRGB(245,158,11),Color3.fromRGB(139,92,246),Color3.fromRGB(132,204,22),
    Color3.fromRGB(244,114,182),Color3.fromRGB(56,189,248),Color3.fromRGB(214,194,154),
}
M.mateColor=Color3.fromRGB(45,212,191)
local teamOf,teamBase,teamPool,teamKeys,teamSeen,teamMatch,teamMine={},{},{},{},{},nil,nil
function M.setTeams(factions,myTeam,match)
    local changed=false
    local mine=myTeam~=nil and tostring(myTeam)or nil
    if match~=teamMatch or mine~=teamMine then teamMatch=match;teamMine=mine;teamOf,teamBase,teamPool,teamKeys,teamSeen={},{},{},{},{};changed=true end
    local fresh={};local teams={}
    for _,f in ipairs(factions or {})do if (f.team==nil or f.kind=='BOT')and teamOf[f.id]then teamOf[f.id]=nil;teamKeys[f.id]=nil;changed=true end end
    for _,f in ipairs(factions or {})do if f.team~=nil and f.kind~='BOT'and teamKeys[f.id]~=tostring(f.team)..':'..tostring(f.userId or f.matchId or f.id)then
        table.insert(fresh,f);teams[tostring(f.team)]=true
    end end
    if #fresh==0 then return changed end
    local order={};for t in pairs(teams)do if not teamBase[t]then table.insert(order,t)end end;table.sort(order)
    for _,t in ipairs(order)do
        if t==mine then teamBase[t]=M.self;teamPool[t]=1
        else local n=0;for k,_ in pairs(teamBase)do if k~=mine then n+=1 end end;local i=n%#M.teamPalette+1;teamBase[t]=M.teamPalette[i];teamPool[t]=i+1 end
    end
    for _,f in ipairs(fresh)do local t=tostring(f.team);local key=tostring(f.userId or f.matchId or f.id)
        teamKeys[f.id]=t..':'..key;teamSeen[t]=teamSeen[t]or{};teamSeen[t][key]=true
    end
    for t in pairs(teams)do
        local keys={};for k in pairs(teamSeen[t])do table.insert(keys,k)end;table.sort(keys)
        local rank={};for i,k in ipairs(keys)do rank[k]=i end
        local shades=Shades[teamPool[t]]
        for id,tk in pairs(teamKeys)do local at=string.find(tk,':',1,true);if string.sub(tk,1,at-1)==t then
            local key=string.sub(tk,at+1);local rgb=shades[rank[key]]or Variants.get(teamPool[t],key)
            teamOf[id]=Color3.fromRGB(table.unpack(rgb))
        end end
    end
    return true
end
function M.team(team,myTeam)
    if team~=nil and team==myTeam then return M.self end
    return teamBase[tostring(team)]or Color3.fromRGB(138,151,168)
end
function M.get(id,kind,own)
    if teamOf[id]then return teamOf[id]end
    if id==1 then return own or M.self end
    if kind=='BOT'then return tribe[(id*5)%#tribe+1]end
    if not cache[id]then
        local n=#M.palette;local base=M.palette[(id-2)%n+1];local cycle=math.floor((id-2)/n)%3
        cache[id]=cycle==0 and base or cycle==1 and base:Lerp(Color3.new(1,1,1),.12) or base:Lerp(Color3.new(0,0,0),.12)
    end
    return cache[id]
end
return M
