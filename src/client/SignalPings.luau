local UI=require(script.Parent.Theme)
local L=require(script.Parent.Localization)
local Icons=require(script.Parent.UIIcons)
local Layout=require(script.Parent.Parent.Core.SignalLayout)
local Overlays=require(script.Parent.OverlayLayout)
local M={};M.__index=M
local glyphs={attack='↑',defend='◇',gold='$',peace='↔',thanks='✓'}
local scopes={team='팀',allies='동맹',all='전체',player='상대'}
function M.new(parent,focus,project)
    local layer=UI.make('Frame',parent,{Name='MapSignals',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=18})
    return setmetatable({layer=layer,focus=focus,project=project,items={},serial=0},M)
end
function M:clear()
    for _,r in ipairs(self.items)do r.button:Destroy()end;self.items={}
end
function M:add(sender,meta,tile,now)
    if type(tile)~='number'or tile%1~=0 or tile<0 or meta.kind~='signal'or not scopes[meta.scope]or not(glyphs[meta.key]or meta.key=='troops')then return false end
    now=now or os.clock();local key=tostring(sender)..':'..meta.key..':'..tile..':'..meta.scope
    for _,r in ipairs(self.items)do if r.key==key then r.expires=now+3.5;r.count=math.min(99,r.count+1);r.caption.Text=L.text(scopes[meta.scope])..' ×'..r.count;return true end end
    while #self.items>=6 do table.remove(self.items,1).button:Destroy()end
    self.serial+=1
    local r={key=key,tile=tile,expires=now+3.5,count=1,scope=meta.scope}
    local color=meta.key=='defend'and UI.colors.danger or meta.key=='gold'and UI.colors.gold or meta.scope=='all'and UI.colors.ice or UI.colors.accent
    r.button=UI.button(self.layer,'Ping'..self.serial,'',function()self.focus(r.tile)end);r.button.BackgroundTransparency=1
    r.button.Size=UDim2.fromOffset(44,44);r.button.AnchorPoint=Vector2.new(.5,.5);r.button:SetAttribute('Tile',tile);r.button:SetAttribute('Scope',meta.scope)
    r.ring=UI.make('Frame',r.button,{Name='Ring',BackgroundColor3=UI.colors.bg,BackgroundTransparency=.2,BorderSizePixel=0,Size=UDim2.fromOffset(34,34),Position=UDim2.fromOffset(22,22),AnchorPoint=Vector2.new(.5,.5)})
    UI.corner(r.ring,999);r.stroke=UI.stroke(r.ring,color,1.5)
    if meta.key=='troops'then local icon=Icons.create(r.ring,'troops',20);UI.box(icon,7,7,20,20);icon.ImageColor3=color
    else local icon=UI.label(r.ring,'Kind',glyphs[meta.key],22,color);UI.box(icon,3,2,28,30);icon.TextXAlignment=Enum.TextXAlignment.Center end
    r.caption=UI.label(r.button,'Audience',L.text(scopes[meta.scope]),14,color);UI.box(r.caption,-18,-21,80,18);r.caption.TextXAlignment=Enum.TextXAlignment.Center
    r.heading=UI.label(r.button,'Heading','›',24,color);r.heading.AnchorPoint=Vector2.new(.5,.5);r.heading.Size=UDim2.fromOffset(12,20);r.heading.TextXAlignment=Enum.TextXAlignment.Center;r.heading.Visible=false
    r.button:SetAttribute('LocalizationSkip',true);table.insert(self.items,r);return true
end
function M:layout(w,h,obscured,bottomInset,topInset,rightInset)
    self.w=w;self.h=h;self.bottomInset=bottomInset or 160;self.topInset=topInset;self.rightInset=rightInset;self.obscured=obscured
    self.layer.Visible=not obscured
end
function M:step(now)
    now=now or os.clock()
    local points={}
    if self.project and self.w then for i,r in ipairs(self.items)do local p=self.project(r.tile);points[i]={x=p and p.X,y=p and p.Y}end end
    local positions=Layout.place(points,self.w or 0,self.h or 0,self.bottomInset,self.topInset,self.rightInset)
    local obstacles=table.clone(self.blocks or {})
    for i,point in ipairs(positions)do if point then
        local r={x=point.x-22,y=point.y-40,w=44,h=62};local occupied=false
        for _,b in ipairs(obstacles)do if Overlays.area(r,b)>0 then occupied=true;break end end
        if occupied then
            local b=Layout.bounds(self.w,self.h,self.bottomInset,self.topInset,self.rightInset)
            if b then
                local c=Overlays.place(r,self.w,self.h-(self.bottomInset or 160),obstacles)
                point.x,point.y=c.x+22,c.y+40;point.edge=true
                local goal=points[i];point.angle=math.atan2(goal.y-point.y,goal.x-point.x)
                r={x=c.x,y=c.y,w=44,h=62}
            end
        end
        table.insert(obstacles,r)
    end end
    for i=#self.items,1,-1 do
        local r=self.items[i]
        if now>=r.expires then r.button:Destroy();table.remove(self.items,i)
        elseif self.project and self.w then
            local point=positions[i];local visible=point~=false and point~=nil
            r.button.Visible=visible==true and not self.obscured
            if visible then
                r.button.Position=UDim2.fromOffset(point.x,point.y);r.stroke.Transparency=math.clamp(1-(r.expires-now)/3.5,.08,.8)
                r.heading.Visible=point.edge;r.button:SetAttribute('Offscreen',point.edge)
                if point.edge then local a=point.angle;r.heading.Position=UDim2.fromOffset(22+math.cos(a)*24,22+math.sin(a)*24);r.heading.Rotation=math.deg(a)end
                r.caption.Position=UDim2.fromOffset(math.clamp(point.x-40,6,math.max(6,self.w-86))-point.x+22,-21)
            end
        end
    end
end
return M
