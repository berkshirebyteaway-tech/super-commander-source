local M={}
M.parts={{7,5,8,7,0},{9,2,2,4,0},{4,11,16,2,0},{3,14,18,5,0},{3,14,5,5,-35},{16,14,5,5,35},{5,21,5,1,0},{12,21,7,1,0}}
function M.attach(label)
    local canvas=Instance.new('CanvasGroup');canvas.Name='TransportGlyphCanvas'
    canvas.BackgroundTransparency=1;canvas.Size=UDim2.fromScale(1,1);canvas.Parent=label
    local parts={}
    for i,p in ipairs(M.parts)do
        local part=Instance.new('Frame');part.Name='TransportPart'..i;part.BorderSizePixel=0
        part.Position=UDim2.fromScale(p[1]/24,p[2]/24);part.Size=UDim2.fromScale(p[3]/24,p[4]/24)
        part.Rotation=p[5];part.BackgroundColor3=Color3.new(1,1,1);part.Parent=canvas;parts[#parts+1]=part
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
