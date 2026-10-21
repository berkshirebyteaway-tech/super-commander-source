local M={}
M.levels={1,.75,.5,.25}
M.BASE='HudBaseAlpha'
local ROOM=.33
local tracked=setmetatable({},{__mode='k'})
local factor,root,added=1,nil,nil
local writing=false
local wrote=setmetatable({},{__mode='k'})
function M.valid(v)return v==1 or v==.75 or v==.5 or v==.25 end
function M.faded(base,f)if f>=1 then return base end;return 1-(1-base)*f end
local function dark(c)return c.R+c.G+c.B<.45 end
local function solid(o)
    while o and o~=root do if o:GetAttribute('HudSolid')then return true end;o=o.Parent end
    return false
end
local function surface(o)
    if not o:IsA('Frame')or o:IsA('ScrollingFrame')then return false end
    if o:GetAttribute(M.BASE)==nil and (o.BackgroundTransparency>=.99 or not dark(o.BackgroundColor3))then return false end
    if solid(o)then return false end
    local cam=workspace.CurrentCamera;local v=cam and cam.ViewportSize or Vector2.new(1,1)
    local a=o.AbsoluteSize;return a.X*a.Y<ROOM*v.X*v.Y
end
local function paint(o)
    local base=o:GetAttribute(M.BASE)
    if base==nil then base=o.BackgroundTransparency;o:SetAttribute(M.BASE,base)end
    local v=M.faded(base,factor);writing=true;o.BackgroundTransparency=v;writing=false;wrote[o]=o.BackgroundTransparency
end
local function track(o)
    if tracked[o]or not surface(o)then return end
    paint(o)
    tracked[o]=o:GetPropertyChangedSignal('BackgroundTransparency'):Connect(function()
        if writing or wrote[o]==o.BackgroundTransparency then return end
        o:SetAttribute(M.BASE,o.BackgroundTransparency);if factor<1 then paint(o)end
    end)
end
local function release()
    for o,c in pairs(tracked)do
        c:Disconnect();local base=o:GetAttribute(M.BASE)
        if base~=nil then writing=true;o.BackgroundTransparency=base;writing=false;o:SetAttribute(M.BASE,nil)end;wrote[o]=nil
    end
    table.clear(tracked)
end
function M.apply(hud,value)
    local f=M.valid(value)and value or 1
    if hud==root and f==factor then return end
    if root~=hud then release();if added then added:Disconnect();added=nil end;root=hud end
    factor=f
    if factor>=1 then release();if added then added:Disconnect();added=nil end;return end
    for o in pairs(tracked)do paint(o)end
    for _,o in ipairs(hud:GetDescendants())do track(o)end
    if not added then added=hud.DescendantAdded:Connect(function(o)if o:IsA('Frame')then task.defer(function()if o.Parent and factor<1 then track(o)end end)end end)end
end
return M
