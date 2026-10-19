local UI=require(script.Parent.Theme)
local Layout=require(script.Parent.Parent.Core.DropMarkerLayout)
local M={};M.__index=M
function M.new(parent)
    local root=UI.make('Frame',parent,{Name='DropSquad',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=23,Active=false})
    return setmetatable({root=root,markers={}},M)
end
function M:clear()self.root:ClearAllChildren();self.markers={}end
function M:step(people,positions,camera,touch,mini,visible)
    local size=self.root.AbsoluteSize/UI.scale;local origin=self.root.AbsolutePosition;local live={};local order={};local placed={}
    for id,p in pairs(people)do if not p.mine and positions[id]then table.insert(order,id)end end
    table.sort(order,function(a,b)return people[a].index<people[b].index end)
    for _,id in ipairs(order)do local p=people[id]
        live[id]=true;local m=self.markers[id]
        if not m then
            local f=UI.make('Frame',self.root,{Name='Party_'..id,Size=UDim2.fromOffset(26,26),AnchorPoint=Vector2.new(.5,.5),BorderSizePixel=0,BackgroundColor3=UI.colors.bg,BackgroundTransparency=.12,ZIndex=23})
            UI.corner(f,99);local edge=UI.stroke(f,UI.colors.ice,1.5)
            local label=UI.label(f,'Number','',14,UI.colors.ice);label.Size=UDim2.fromScale(1,1);label.TextXAlignment=Enum.TextXAlignment.Center;label.ZIndex=24;label.Font=Enum.Font.BuilderSansBold;label:SetAttribute('LocalizationSkip',true)
            local arrow=UI.label(f,'Direction','▲',11,UI.colors.ice);arrow.Size=UDim2.fromOffset(16,12);arrow.Position=UDim2.fromOffset(5,-12);arrow.TextXAlignment=Enum.TextXAlignment.Center;arrow.ZIndex=24;arrow:SetAttribute('LocalizationSkip',true)
            m={frame=f,label=label,arrow=arrow,edge=edge};self.markers[id]=m
        end
        local point=camera:WorldToScreenPoint(positions[id]+Vector3.new(0,7,0))
        local at=Layout.place((point.X-origin.X)/UI.scale,(point.Y-origin.Y)/UI.scale,point.Z,size.X,size.Y,touch,mini)
        local offscreen,angle=at.offscreen,at.angle
        for _,previous in ipairs(placed)do if math.abs(at.x-previous.x)<28 and math.abs(at.y-previous.y)<28 then
            at=Layout.place(at.x+30,at.y,1,size.X,size.Y,touch,mini)
            if math.abs(at.x-previous.x)<28 then at=Layout.place(at.x,at.y+30,1,size.X,size.Y,touch,mini)end
        end end
        table.insert(placed,at)
        at.offscreen=offscreen;at.angle=angle
        m.frame.Visible=visible;m.frame.Position=UDim2.fromOffset(at.x,at.y);m.label.Text=tostring(p.index)
        local color=p.allied and UI.colors.ice or UI.colors.muted
        m.label.TextColor3=color;m.edge.Color=color;m.arrow.TextColor3=color;m.arrow.Visible=at.offscreen;m.arrow.Rotation=at.angle
    end
    for id,m in pairs(self.markers)do if not live[id]then m.frame:Destroy();self.markers[id]=nil end end
end
function M:destroy()self:clear();self.root:Destroy()end
return M
