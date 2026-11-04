local M={}
M.cap=1000
M.bands={
    {below=300,wait={6,10}},
    {below=700,wait={8,14}},
    {below=math.huge,wait={12,18}},
}
M.newcomerGames=3;M.newcomerWait={4,7}
M.levels={
    {difficulty='Easy',pace=1.3},
    {difficulty='Easy',pace=1},
    {difficulty='Medium',pace=1.2},
    {difficulty='Medium',pace=1},
}
M.levelFloors={0,150,400,700}
M.recentSize=5
function M.baseLevel(t)
    local level=1;for i,floor in ipairs(M.levelFloors)do if (t or 0)>=floor then level=i end end
    return level
end
function M.adjust(level,recent)
    local list=type(recent)=='table'and recent or {}
    local wins=0;for i=math.max(1,#list-M.recentSize+1),#list do if list[i]==1 then wins+=1 end end
    if #list>=2 and list[#list]==0 and list[#list-1]==0 then level-=1
    elseif #list>=4 and wins>=4 then level+=1 end
    return math.clamp(level,1,#M.levels)
end
function M.wait(t,games,roll)
    local band=M.newcomerWait
    if (games or 0)>=M.newcomerGames then for _,b in ipairs(M.bands)do if (t or 0)<b.below then band=b.wait;break end end end
    return band[1]+math.floor((roll or 0)*(band[2]-band[1]+1))
end
M.first={'Sky','Mint','Blaze','Cocoa','Pixel','Nova','Frost','Lucky','Tiny','Shadow','Sunny','Turbo','Maple','Echo','Rocket','Berry','Storm','Neon','Cloud','Ember',
    'Swift','Lemon','Comet','Hazel','Iron','Jelly','Koi','Lava','Moss','Orbit','Peach','Quartz','River','Salty','Tango','Ultra','Velvet','Wild','Zippy','Bubble'}
M.second={'Fox','Tank','Wolf','Cat','Bean','Rider','Hawk','Ninja','Panda','Knight','Pilot','Bear','Duck','Shark','Ghost','Owl','Tiger','Bunny','Dragon','Chief',
    'Scout','Bolt','Falcon','Otter','Raven','Captain','Mango','Frog','Lion','Ranger','Pup','Comet','Star','Spark','Moon','Toast','Cookie','Waffle','Biscuit','Noodle'}
local function pick(list,roll)return list[math.clamp(math.floor(roll*#list)+1,1,#list)]end
function M.name(rolls)
    local a,b=pick(M.first,rolls[1]),pick(M.second,rolls[2])
    local n=math.floor(rolls[3]*1000)
    local style=math.floor(rolls[4]*6)
    if style==0 then return a..b
    elseif style==1 then return a..b..tostring(n%100)
    elseif style==2 then return string.lower(a)..'_'..string.lower(b)
    elseif style==3 then return a..'_'..b..tostring(n%10)
    elseif style==4 then return string.lower(a..b)..string.format('%02d',n%100)
    else return b..tostring(n)end
end
M.skins={{255,204,153},{234,184,146},{204,142,105},{175,148,131},{124,92,70},{86,66,54},{253,234,141},{248,248,248}}
M.cloth={{196,40,28},{13,105,172},{40,127,71},{27,42,53},{245,205,48},{255,148,148},{99,95,98},{17,17,17},{218,133,65},{180,128,255},{120,144,130},{248,248,248}}
M.wardrobe=if script then require(script.Parent.RankedAIWardrobe)else require('./RankedAIWardrobe')
M.chance={hair=.92,face=.85,top=.8,bottom=.8,hat=.35}
local function index(list,roll)return #list>0 and math.clamp(math.floor(roll*#list)+1,1,#list)or 0 end
local function piece(list,chance,roll)
    if #list==0 or roll>=chance then return 0 end
    return index(list,roll/chance)
end
function M.look(rolls)
    local shirt=index(M.cloth,rolls[2]);local pants=index(M.cloth,rolls[3])
    if pants==shirt then pants=pants%#M.cloth+1 end
    local w,c=M.wardrobe,M.chance
    return {skin=index(M.skins,rolls[1]),shirt=shirt,pants=pants,sleeve=rolls[4]<.5 and 1 or 0,
        hair=piece(w.hair,c.hair,rolls[5]),face=piece(w.faces,c.face,rolls[6]),top=piece(w.shirts,c.top,rolls[7]),
        bottom=piece(w.pants,c.bottom,rolls[8]),hat=piece(w.hats,c.hat,rolls[9])}
end
function M.shown(t,roll)
    return math.max(0,(t or 0)+math.floor((roll or .5)*71)-35)
end
function M.plan(record,rolls,options)
    options=options or {}
    if options.enabled==false then return nil end
    local t=type(record)=='table'and tonumber(record.t)or 0
    local cap=tonumber(options.cap)or M.cap
    if t>=cap then return nil end
    local games=type(record)=='table'and tonumber(record.games)or 0
    local level=M.adjust(M.baseLevel(t),type(record)=='table'and record.aiRecent or nil)
    local r={};for i=1,15 do r[i]=rolls()end
    return {after=M.wait(t,games,r[1]),level=level,name=M.name({r[2],r[3],r[4],r[5]}),t=M.shown(t,r[6]),
        look=M.look({r[7],r[8],r[9],r[10],r[11],r[12],r[13],r[14],r[15]}),key=tostring(math.floor(rolls()*2^31)),userId=-(1000000+math.floor(rolls()*8999999))}
end
function M.valid(p)
    if type(p)~='table'then return false end
    local function n(v,lo,hi)return type(v)=='number'and v==v and v>=lo and v<=hi end
    return n(p.after,0,120)and n(p.level,1,#M.levels)and p.level%1==0 and type(p.name)=='string'and #p.name>=3 and #p.name<=20
        and n(p.t,0,1e6)and type(p.look)=='table'and type(p.key)=='string'and #p.key<=16 and n(p.userId,-1e7,-1000000)and p.userId%1==0
end
function M.copy(p)
    if not M.valid(p)then return nil end
    local look={};for k,v in pairs(p.look)do if type(k)=='string'and #k<=8 and type(v)=='number'and v==v and v>=0 and v<=255 then look[k]=math.floor(v)end end
    return {after=p.after,level=p.level,name=p.name,t=math.floor(p.t),look=look,key=p.key,userId=p.userId}
end
function M.seat(p,seat)
    local level=M.levels[p.level]or M.levels[1]
    return {seat=seat,difficulty=level.difficulty,pace=level.pace,key=p.key}
end
function M.colors(look)
    local function c(list,i)local v=list[math.clamp(i or 1,1,#list)];return v[1],v[2],v[3]end
    return {skin={c(M.skins,look.skin)},shirt={c(M.cloth,look.shirt)},pants={c(M.cloth,look.pants)},sleeve=look.sleeve==1}
end
return M
