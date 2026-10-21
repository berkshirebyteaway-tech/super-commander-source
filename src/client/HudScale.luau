local UI=require(script.Parent.Theme)
local M={};M.__index=M
M.SCALE=.65
M.TOUCH=.60
M.TEXT=10
M.POPUP=.70
M.INFO={'Toast','NetLink','HeadsUp','CommandFeedback','SignalFeed','Hover'}
M.CARDS={'AllianceRenewal','DiplomacyInbox','Operations','BattleFeedback/UnderAttack','Guide','ActionGuidance'}
M.MOUSE={'DiplomacyPeek','EventLog','MatchChatWindow','QuickComms','TacticalPanel','MatchSheet','NuclearAim'}
function M.new(panel)
    return setmetatable({panel=panel,items={},watched=setmetatable({},{__mode='k'}),w=0,h=0},M)
end
local function slide(at,size,screen,s)
    local c=at+size/2
    if c>screen*.55 then return size*(1-s)elseif c>screen*.45 then return size*(1-s)/2 end
    return 0
end
function M:place(o)
    local it=self.items[o];if not it or it.busy then return end
    local base=it.base;local s=it.scale
    local x,y=base.X.Offset,base.Y.Offset
    local dx,dy=0,0
    if s<1 and o.Size.X.Scale==0 and o.Size.Y.Scale==0 and o.AnchorPoint==Vector2.zero then
        dx=o:GetAttribute('HudLeft')and 0 or math.floor(slide(x,o.Size.X.Offset,self.w,s)+.5);dy=math.floor(slide(y,o.Size.Y.Offset,self.h,s)+.5)
    end
    it.busy=true;o.Position=UDim2.new(base.X.Scale,x+dx,base.Y.Scale,y+dy);it.written=o.Position;it.busy=false
end
function M:track(o,s)
    local it=self.items[o]
    if not it then
        it={o=o,base=o.Position,scale=1};self.items[o]=it
        o:GetPropertyChangedSignal('Position'):Connect(function()
            if it.busy or o.Position==it.written then return end
            local p,w=o.Position,it.written
            it.base=UDim2.new(w and p.X==w.X and it.base.X or p.X,w and p.Y==w.Y and it.base.Y or p.Y);self:place(o)
        end)
        o:GetPropertyChangedSignal('Size'):Connect(function()if it.scale<1 then self:place(o)end end)
        o.DescendantAdded:Connect(function(d)if it.scale<1 then task.defer(function()self:floor(d,it)end)end end)
        o.AncestryChanged:Connect(function()if o.Parent then self:track(o,it.want)end end)
    end
    it.want=s;if not o:IsDescendantOf(self.panel)then s=1 end
    if it.scale==s then return end
    it.scale=s
    local u=o:FindFirstChild('HudScale')or UI.make('UIScale',o,{Name='HudScale'});u.Scale=s
    self:text(o,it)
    self:place(o)
end
local TextService=game:GetService('TextService')
local function fits(d,size,boxW,boxH)
    local wrap=d.TextWrapped
    local ok,v=pcall(function()return TextService:GetTextSize(d.ContentText and d.ContentText~=''and d.ContentText or d.Text,size,d.Font,Vector2.new(wrap and boxW or 10000,10000))end)
    return ok and v.X<=boxW+1 and (not wrap or v.Y<=boxH+1)
end
function M:floor(d,it)
    if not(d:IsA('TextLabel')or d:IsA('TextButton')or d:IsA('TextBox'))then return end
    if d.TextScaled then
        local c=d:FindFirstChildOfClass('UITextSizeConstraint');if not c then return end
        local design=c:GetAttribute('HudMax')or c.MaxTextSize
        local target=it.scale<1 and math.max(design,math.ceil(M.TEXT/it.scale))or design
        c:SetAttribute('HudMax',target~=design and design or nil);c.MaxTextSize=target
        return
    end
    local s=it.scale;local design=d:GetAttribute('HudText')or d.TextSize
    local target=design
    if s<1 then
        local o=it.o;local k=o.Size.X.Offset>0 and o.AbsoluteSize.X/o.Size.X.Offset or (UI.scale or 1)*s
        local boxW,boxH=d.AbsoluteSize.X/k,d.AbsoluteSize.Y/k
        for size=math.ceil(M.TEXT/s),design+1,-1 do if boxW>0 and fits(d,size,boxW,boxH)then target=size;break end end
    end
    self.writing=d
    if target~=design then d:SetAttribute('HudText',design)else d:SetAttribute('HudText',nil)end
    if d.TextSize~=target then d.TextSize=target end
    self.writing=nil;d:SetAttribute('HudWrote',d.TextSize)
    if not self.watched[d]then self.watched[d]=true
        d:GetPropertyChangedSignal('TextSize'):Connect(function()
            if self.writing==d or d:GetAttribute('HudWrote')==d.TextSize then return end
            d:SetAttribute('HudText',nil);if it.scale<1 then self:floor(d,it)end
        end)
        d:GetPropertyChangedSignal('Text'):Connect(function()if it.scale<1 or d:GetAttribute('HudText')then self:floor(d,it)end end)
    end
end
function M:text(o,it)
    for _,d in ipairs(o:GetDescendants())do self:floor(d,it)end
end
function M:apply(w,h,touch)
    local moved=self.w~=w or self.h~=h;self.w,self.h=w,h
    local function each(names,s)
        for _,name in ipairs(names)do local o=self.panel
            for part in string.gmatch(name,'[^/]+')do o=o and o:FindFirstChild(part)end
            if o and o:IsA('GuiObject')then local was=self.items[o];self:track(o,s);if moved and was then self:place(o)end
                if was and s<1 and o.Visible then self:text(o,self.items[o])end end
        end
    end
    local Placement=require(script.Parent.Parent.Core.InterfacePlacement)
    if Placement.desk(w,h,touch)then touch=false end
    each(M.INFO,touch and M.TOUCH or M.POPUP);each(M.CARDS,touch and 1 or M.POPUP);each(M.MOUSE,touch and 1 or M.SCALE)
end
return M
