local M={}
M.parts={{5,2,14,10,7},{3,9,18,3,1},{7,12,2,4,0},{15,12,2,4,0},{9,12,6,1,0},
    {8,15,8,3,1},{10,18,4,2,0},{3,19,8,4,1},{13,19,8,4,1},{7,20,10,3,0}}
function M.attach(label)
    local canvas=Instance.new('CanvasGroup');canvas.Name='SoldierGlyphCanvas'
    canvas.BackgroundTransparency=1;canvas.Size=UDim2.fromScale(1,1);canvas.Parent=label
    local parts={}
    for i,p in ipairs(M.parts)do
        local part=Instance.new('Frame');part.Name='SoldierPart'..i;part.BorderSizePixel=0
        part.Position=UDim2.fromScale(p[1]/24,p[2]/24);part.Size=UDim2.fromScale(p[3]/24,p[4]/24)
        part.BackgroundColor3=Color3.new(1,1,1);part.Parent=canvas
        if p[5]>0 then local c=Instance.new('UICorner');c.CornerRadius=UDim.new(p[5]/math.min(p[3],p[4]),0);c.Parent=part end
        parts[#parts+1]=part
    end
    local function paint()
        canvas.GroupColor3=label.ImageColor3;canvas.GroupTransparency=label.ImageTransparency;canvas.ZIndex=label.ZIndex
        for _,part in ipairs(parts)do part.ZIndex=label.ZIndex end
    end
    label:GetPropertyChangedSignal('ImageColor3'):Connect(paint)
    label:GetPropertyChangedSignal('ImageTransparency'):Connect(paint)
    label:GetPropertyChangedSignal('ZIndex'):Connect(paint);paint()
    label:SetAttribute('NativeGlyph',true)
end
return M
