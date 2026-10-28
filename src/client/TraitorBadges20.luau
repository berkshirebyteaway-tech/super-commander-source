local K=require(script.Parent.Kit20)
local X=require(script.Parent.Cards20)
local Theme=require(script.Parent.Theme)
local Config=require(script.Parent.Parent.Core.ConfigConstants)
local M={};M.__index=M
M.SCREEN=16;M.HZ=10;M.STEPS=120;M.TRACK=.75;M.GAP=4
local function duration()return (Config.traitorDuration or 300)*(Config.msPerTick or 100)/1000 end
local cache={}
local function sequence(step)
    local s=cache[step]
    if s then return s end
    local p=step/M.STEPS
    if p>=1 then s=NumberSequence.new(0)
    elseif p<=0 then s=NumberSequence.new(M.TRACK)
    else
        local c=math.clamp(1-p,.002,.998)
        s=NumberSequence.new({NumberSequenceKeypoint.new(0,M.TRACK),NumberSequenceKeypoint.new(c-.001,M.TRACK),NumberSequenceKeypoint.new(c,0),NumberSequenceKeypoint.new(1,0)})
    end
    cache[step]=s;return s
end
function M.new(layer)
    return setmetatable({layer=layer,badges={},spare={},done={}},M)
end
function M:make()
    local b=table.remove(self.spare)
    if b then return b end
    local root=K.make('Frame',self.layer,{Name='Traitor20',BackgroundColor3=X.DANGER_BG,BackgroundTransparency=.06,BorderSizePixel=0,AnchorPoint=Vector2.new(0,.5),ZIndex=4,Visible=false,Active=false})
    K.round(root,'pill')
    local stroke=K.stroke(root,K.colors.danger,2,0)
    local ring=K.make('UIGradient',stroke,{Name='Left20',Rotation=90})
    local icon=K.icon(root,'shieldBroken',10,K.colors.danger,'Shield');icon.ZIndex=5
    K.rememberRest(root)
    return {root=root,ring=ring,icon=icon}
end
function M:release(id)
    local b=self.badges[id];if not b then return end
    self.badges[id]=nil;b.root.Visible=false;b.fading=nil;b.step=nil;b.size=nil;b.x=nil;b.y=nil
    table.insert(self.spare,b)
end
function M:step(factions,plates,shown,tick,now)
    local badges=self.badges
    local scale=math.max(.25,Theme.scale or 1)
    local size=K.even(math.floor(M.SCREEN/scale+.5));local icon=math.max(8,K.even(math.floor(size*.62+.5)))
    local total=duration()
    local seen=self.seen or {};self.seen=seen;table.clear(seen)
    local done=self.done
    if tick then for _,f in ipairs(factions)do
        if f.id~=1 and f.traitor and f.traitorUntil and f.traitorUntil>tick and not f.eliminated then
            seen[f.id]=true
            local ends=now+(f.traitorUntil-tick)*(Config.msPerTick or 100)/1000
            local b=badges[f.id];local over=done[f.id]
            local fresh=(b==nil or b.fading~=nil)and(over==nil or ends>over+1)and(b==nil or ends>b.ends+1)
            if fresh then
                if b then self:release(f.id)end
                done[f.id]=nil;b=self:make();badges[f.id]=b;K.fade(b.root,true,0);b.ends=ends
            elseif b and not b.fading and math.abs(ends-b.ends)>.25 then b.ends=ends end
        end
    end end
    for id in pairs(done)do if not seen[id]then done[id]=nil end end
    for id,b in pairs(badges)do
        local plate=plates[id]
        if not b.fading and(not seen[id]or now>=b.ends)then
            b.fading=now+(K.reduced and .12 or .1);K.fade(b.root,false,.1)
        end
        if b.fading and now>=b.fading then self.done[id]=b.ends;self:release(id);continue end
        local up=plate~=nil and plate.Visible and shown[id]==true
        if b.root.Visible~=up then b.root.Visible=up end
        if not up then continue end
        if b.size~=size then
            b.size=size;b.root.Size=UDim2.fromOffset(size,size)
            K.box(b.icon,(size-icon)/2,(size-icon)/2,icon,icon)
        end
        local motion=plate:FindFirstChild('Motion');local s=motion and motion.Scale or 1
        local title=plate:FindFirstChild('Title')
        local w,h=plate.Size.X.Offset*s,plate.Size.Y.Offset*s
        local th=(title and title.Size.Y.Offset or plate.Size.Y.Offset/2)*s
        local right=w/2
        local nameW=plate:GetAttribute('NameTextWidth')
        if title and nameW then
            local tw=math.min(nameW,title.Size.X.Offset)
            local edge=title.TextXAlignment==Enum.TextXAlignment.Left and title.Position.X.Offset+tw or title.Position.X.Offset+(title.Size.X.Offset+tw)/2
            right=math.min(w/2,edge*s-w/2)
        end
        local x=math.floor(plate.Position.X.Offset+right+M.GAP+.5);local y=math.floor(plate.Position.Y.Offset-h/2+th/2+.5)
        if b.x~=x or b.y~=y then b.x=x;b.y=y;b.root.Position=UDim2.fromOffset(x,y)end
        if not b.fading and now>=(b.next or 0)then
            b.next=now+1/M.HZ
            local step=math.clamp(math.ceil((b.ends-now)/total*M.STEPS),0,M.STEPS)
            if step~=b.step then b.step=step;b.ring.Transparency=sequence(step)end
        end
    end
end
function M:reset()for id in pairs(self.badges)do self:release(id)end;table.clear(self.done)end
return M
