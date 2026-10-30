local Players=game:GetService('Players')
local Service=game:GetService('LocalizationService')
local Core=require(script.Parent.Parent.Core.TextLocalization);local Nations=require(script.Parent.Parent.Core.NationText)
local M={};local translator;local override;local locale=Players.LocalPlayer.LocaleId
local bindings=setmetatable({},{__mode='k'});local names={};local cache={};local count=0
function M.addName(name)
    if type(name)=='string'and name~=''and not table.find(names,name)then table.insert(names,name);table.sort(names,function(a,b)return #a>#b end);cache={};count=0 end
end
for _,p in ipairs(Players:GetPlayers())do M.addName(p.DisplayName)end
Players.PlayerAdded:Connect(function(p)M.addName(p.DisplayName)end)
function M.nation(f)if not f then return '' end;return f.userId and f.name or M.text(f.name or '')end
local function specs(t)local out={};for c in t:gmatch('%%[%-+ #0]*%d*%.?%d*[%a%%]')do table.insert(out,c)end;return table.concat(out,'|')end
function M.text(source,context)
    if type(source)~='string'or source==''then return source end
    if locale:sub(1,2)=='ko'then return Nations.ko(source,names)end
    if not Core.hasKorean(source)then return source end
    if cache[source]then return cache[source]end
    local value=Core.translate(source,'en',names)
    if translator and not override and locale:sub(1,2)~='en'then local ok,t=pcall(function()return translator:Translate(context or game,value)end);if ok and type(t)=='string'and t~=''and specs(t)==specs(value)then value=t end end
    if count>=2048 then cache={};count=0 end;cache[source]=value;count+=1;return value
end
local function update(o,b)
    if o:GetAttribute('LocalizationSkip')then return end
    local value=M.text(b.source,o);b.output=value
    if o[b.property]~=value then o[b.property]=value end
end
local function attach(o,property)
    local list=bindings[o];if list and list[property]then return end
    if not list then list={};bindings[o]=list end
    local b={source=o[property],property=property};list[property]=b
    if o:IsA('GuiObject')then o.AutoLocalize=false end
    b.connection=o:GetPropertyChangedSignal(property):Connect(function()
        if o[property]==b.output then return end
        b.source=o[property];update(o,b)
    end)
    o.Destroying:Once(function()b.connection:Disconnect();bindings[o]=nil end)
    update(o,b)
end
function M.bind(root)
    local function add(o)
        if o:IsA('TextLabel')or o:IsA('TextButton')then attach(o,'Text')end
        if o:IsA('TextBox')then attach(o,'PlaceholderText')end
        if o:IsA('ProximityPrompt')then o.AutoLocalize=false;attach(o,'ActionText');attach(o,'ObjectText')end
    end
    for _,o in ipairs(root:GetDescendants())do add(o)end
    root.DescendantAdded:Connect(add)
end
local function stats(player)
    local function folder(o)
        if o.Name~='leaderstats'then return end
        local function value(v)if v:IsA('NumberValue')then attach(v,'Name')end end
        for _,v in ipairs(o:GetChildren())do value(v)end;o.ChildAdded:Connect(value)
    end
    for _,o in ipairs(player:GetChildren())do folder(o)end;player.ChildAdded:Connect(folder)
end
for _,player in ipairs(Players:GetPlayers())do stats(player)end;Players.PlayerAdded:Connect(stats)
local listeners={}
function M.onLocale(fn)table.insert(listeners,fn)end
function M.setLocale(value)
    override=value;locale=value or Players.LocalPlayer.LocaleId;cache={};count=0
    for o,list in pairs(bindings)do for _,b in pairs(list)do update(o,b)end end
    for _,fn in ipairs(listeners)do task.spawn(fn)end
end
function M.getLocale()return locale end
task.spawn(function()
    local ok,t=pcall(function()return Service:GetTranslatorForPlayerAsync(Players.LocalPlayer)end)
    if ok then translator=t;M.setLocale(override)end
end)
Players.LocalPlayer:GetPropertyChangedSignal('LocaleId'):Connect(function()M.setLocale(override)end)
Players.LocalPlayer:GetAttributeChangedSignal('ToyfrontLocale'):Connect(function()
    local value=Players.LocalPlayer:GetAttribute('ToyfrontLocale')
    if value==nil or value=='ko-kr'or value=='en-us'then M.setLocale(value)end
end)
return M
