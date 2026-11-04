local K=require(script.Parent.Kit20)
local Step=require(script.Parent.TelemetryStep)
local Raster=require(script.Parent.RasterMap)
local Campaign=require(script.Parent.Parent.Core.CampaignRules)
local World=require(script.Parent.Parent.Core.CampaignWorld)
local Supply=require(script.Parent.Parent.Core.SupplyRules)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local C=K.colors
local M={}
M.gold=Color3.fromRGB(232,184,72)
local SLATE=Color3.fromRGB(92,108,132)
local EPIC=Color3.fromRGB(160,107,255)
local function now()local ok,t=pcall(function()return workspace:GetServerTimeNow()end);return ok and t or os.time()end
local atlas
function M.load()
    if atlas==nil then
        local ok,a=pcall(function()
            local data=require(script.Parent.Parent.Maps.Atlas_world);local n=data.width*data.height
            local index={};for i,r in ipairs(data.list)do index[r.name]=i end
            return {map={meta={width=data.width,height=data.height},terrain=Maps.unpack({data.terrain},n)},nations=Maps.unpack({data.nations},n),list=data.list,index=index}
        end)
        atlas=ok and a or false
    end
    return atlas or nil
end
local cache
local function owners(a,owned,gold)
    local key={};for n in pairs(owned)do table.insert(key,n)end;table.sort(key);local sig=table.concat(key,',')..'|'..table.concat(gold,',')
    if cache and cache.sig==sig then return cache.owners end
    local paint={};for i,r in ipairs(a.list)do paint[i]=owned[r.name]and 1 or 2+i end
    for _,n in ipairs(gold)do local i=a.index[n];if i and paint[i]~=1 then paint[i]=2 end end
    local out={};local buf=a.nations
    for t=0,buffer.len(buf)-1 do local i=buffer.readu8(buf,t);if i>0 then out[t]=paint[i]end end
    cache={sig=sig,owners=out};return out
end
local function chapterView(a,ch,aspect)
    local x0,y0,x1,y1=math.huge,math.huge,-math.huge,-math.huge
    for _,s in ipairs(Campaign.stages)do if s.chapter==ch then for _,n in ipairs(World.stages[s.id]or {})do
        local r=a.list[a.index[n]];if r then x0=math.min(x0,r.box[1]);y0=math.min(y0,r.box[2]);x1=math.max(x1,r.box[3]);y1=math.max(y1,r.box[4])end
    end end end
    if x0==math.huge then return nil end
    local w,h=(x1-x0+1)*1.25+20,(y1-y0+1)*1.25+20
    if w/h<aspect then w=h*aspect else h=w/aspect end
    return {x=(x0+x1)/2-w/2,y=(y0+y1)/2-h/2,w=w,h=h}
end
local function worldView(a,aspect)
    local mw,mh=a.map.meta.width,a.map.meta.height
    local h=mw/aspect;if h>=mh then local w=mh*aspect;if w<mw then w=mw end;return {x=(mw-w)/2,y=(mh-w/aspect)/2,w=w,h=w/aspect}end
    return {x=0,y=math.clamp(mh*.42-h/2,0,mh-h),w=mw,h=h}
end
function M.map(parent,name,w,h,opts)
    local a=M.load();if not a then return nil end
    opts=opts or {}
    local p={campaign={stars=(opts.v and opts.v.stars)or {}}}
    local owned=World.owned(p);local goldId=opts.gold;local gold=goldId and World.stages[goldId]or {}
    local f=K.make(opts.tap and 'TextButton'or 'Frame',parent,{Name=name or 'WorldMap',BackgroundColor3=C.ocean,BorderSizePixel=0,ClipsDescendants=true,Size=UDim2.fromOffset(w,h)})
    if opts.tap then f.Text='';f.AutoButtonColor=false;f.Activated:Connect(opts.tap)end
    K.round(f,6)
    local rw=math.clamp(math.floor(w),64,480);local rh=math.clamp(math.floor(rw*h/math.max(1,w)),40,360)
    local r=Raster.new(f,rw,rh);r.owners=owners(a,owned,gold);r.affiliation={[1]=false,[2]=M.gold,neutral=SLATE}
    r:setPreview(a.map);f.Destroying:Once(function()r:destroy()end)
    local img=f:FindFirstChild('MapRaster');if img then K.round(img,6)end
    local first=gold[1]and a.list[a.index[gold[1]]]
    local mk
    if first then
        mk=K.make('Frame',f,{Name='StageMarker',BackgroundColor3=M.gold,BorderSizePixel=0,Visible=false,ZIndex=3});K.round(mk,'pill');K.stroke(mk,C.bg,2)
        local t=K.num(mk,'Id',goldId,12,C.bg,Enum.TextXAlignment.Center);t.Size=UDim2.fromScale(1,1);t.ZIndex=4
    end
    task.defer(function()
        if not f.Parent then return end
        local aspect=r:aspect()
        r.view=opts.focus and chapterView(a,opts.focus,aspect)or worldView(a,aspect);r:draw()
        if mk then
            local at=r:project(first.y*a.map.meta.width+first.x);local s=26
            K.box(mk,at.X-s/2,at.Y-s/2,s,s);mk.Visible=at.X>s/2 and at.Y>s/2 and at.X<w-s/2 and at.Y<h-s/2
        end
    end)
    return f
end
function M.tomorrow(parent,hub,right,y,h)
    local login=(hub.account.progress or {}).login or {}
    local claims=tonumber(login.claims)or 0
    local gift=claims+1==Supply.giftClaim
    local fs=h>=30 and 14 or 12;local is=h-12
    local chip=K.make('Frame',parent,{Name='Tomorrow',BackgroundColor3=C.bg,BackgroundTransparency=.12,BorderSizePixel=0,ZIndex=5});K.round(chip,'pill');K.stroke(chip,gift and EPIC or C.line,1)
    local x=8
    local clock=K.icon(chip,'clock',is,C.muted,'Clock');K.box(clock,x,(h-is)/2,is,is);clock.ZIndex=6;x+=is+5
    local tw=K.width('00:00:00',fs);local time=K.num(chip,'Left','00:00:00',fs,C.ink);K.box(time,x,0,tw+2,h);time.ZIndex=6;x+=tw+8
    if gift then local box=K.icon(chip,'chest',h-8,EPIC,'Gift');K.box(box,x,4,h-8,h-8);box.ZIndex=6;x+=h-8+8
    else
        local amt,aw=K.amount(chip,'Coins','coin','+'..tostring(tonumber(login.nextReward)or 0),fs,C.gold);K.box(amt,x,(h-fs)/2,aw,fs)
        for _,d in ipairs(amt:GetDescendants())do if d:IsA('GuiObject')then d.ZIndex=6 end end;amt.ZIndex=6;x+=aw+10
    end
    K.box(chip,right-x,y,x,h)
    local function paint()local left=math.max(0,math.floor((math.floor(now()/86400)+1)*86400-now()));time.Text=string.format('%02d:%02d:%02d',left//3600,left%3600//60,left%60)end
    paint();task.spawn(function()while chip.Parent do task.wait(1);if chip.Parent then paint()end end end)
    Step.once('tomorrowChip','goals','tomorrowChip',{item=gift and 'epicGift'or 'coins',result='shown'})
    return chip
end
function M.share(parent,v,x,y,size)
    local pct=World.percent({campaign={stars=(v and v.stars)or {}}})
    local t=K.text(parent,'WorldTitle','세계 정복',math.floor(size*.45),C.ink,800);K.box(t,x,y,200,math.floor(size*.6));t.ZIndex=5
    local n=K.num(parent,'WorldPercent',string.format('%d%%',pct),size,C.accent);n.TextTruncate=Enum.TextTruncate.None;K.box(n,x,y+math.floor(size*.55),math.max(K.width(string.format('%d%%',pct),size,n)+12,size*3),size+8);n.ZIndex=5
    Step.once('worldConquest','goals','worldConquest',{value=pct,result='shown'})
    return pct
end
return M
