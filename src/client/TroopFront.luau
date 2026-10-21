local M={};M.__index=M
M.ALPHA=.5
function M.committed(operations)
    local n=0
    for _,op in ipairs(operations or {})do
        if op.direction=='outgoing'and op.kind=='land'and not op.retreated and type(op.troops)=='number'then n+=math.max(0,op.troops)end
    end
    return n
end
function M.shares(troops,attacking,cap)
    local base=math.max(1,cap or 0)
    local home=math.clamp((troops or 0)/base,0,1)
    return home,math.clamp((attacking or 0)/base,0,1-home)
end
function M.new(track)
    local function part(name,z)
        local f=Instance.new('Frame');f.Name=name;f.BorderSizePixel=0;f.ZIndex=z;f.Visible=false;f.Parent=track;return f
    end
    local whole=part('AttackingFill',1);whole.BackgroundTransparency=M.ALPHA
    local corner=Instance.new('UICorner');corner.Parent=whole
    return setmetatable({frame=whole,corner=corner,cap=part('AttackingSeam',2),track=track},M)
end
local function endColor(fill)
    local g=fill:FindFirstChild('HudFill')
    if g and g.Enabled then local k=g.Color.Keypoints;return k[#k].Value end
    return fill.BackgroundColor3
end
function M:update(state,player)
    local attacking=player and M.committed(state.operations)or 0
    local home,away=M.shares(player and player.troops,attacking,player and player.cap)
    local f,cap=self.frame,self.cap;local fill=self.track:FindFirstChild('Fill')
    f.Visible=away>0 and fill~=nil;cap.Visible=f.Visible
    if f.Visible then
        local color=endColor(fill);local fc=fill:FindFirstChildOfClass('UICorner');local r=fc and fc.CornerRadius or UDim.new(0,0)
        f.BackgroundColor3=color;cap.BackgroundColor3=color;self.corner.CornerRadius=r
        f.Position=UDim2.fromScale(0,0);f.Size=UDim2.fromScale(home+away,1)
        local w=math.min(r.Offset,math.floor(home*self.track.Size.X.Offset))
        cap.Position=UDim2.new(home,-w,0,0);cap.Size=UDim2.new(0,w,1,0)
    end
    f:SetAttribute('Troops',attacking)
end
return M
