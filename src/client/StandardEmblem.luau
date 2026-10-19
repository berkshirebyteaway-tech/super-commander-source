local Rules=require(script.Parent.Parent.Core.CommanderStandardRules)
local M={}
function M.create(parent,color,id)
    local frame=Instance.new('Frame');frame.Name='CommanderEmblem';frame.BackgroundTransparency=1;frame.Size=UDim2.fromScale(1,1);frame.Parent=parent
    for _,s in ipairs(Rules.emblem(id))do
        local p=Instance.new('Frame');p.Name='Stroke';p.AnchorPoint=Vector2.new(.5,.5);p.Position=UDim2.fromScale(s[1],s[2]);p.Size=UDim2.fromScale(s[3],s[4]);p.Rotation=s[5];p.BackgroundColor3=color or Color3.fromRGB(238,244,251);p.BorderSizePixel=0;p.Parent=frame
    end
    return frame
end
return M
