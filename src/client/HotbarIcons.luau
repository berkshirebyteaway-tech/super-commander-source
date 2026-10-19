-- CC BY-SA 4.0) drawn through one shared EditableImage per key. Structures reuse
local Structures=require(script.Parent.StructureGlyphPixels)
local Others=require(script.Parent.HotbarIconPixels)
local Native=require(script.Parent.StructureGlyph)
local M={}
local fallback={Warship='⚓',AtomBomb='☢',HydrogenBomb='☢',MIRV='✦',Gold='●',Soldier='♟',Sword='⚔',Alliance='↔',Traitor='!',Target='◎',Crown='♛',Transport='⛵',TradeShip='◆'}
local images={}
local function image(key)
    if images[key]==nil then
        local ok,img=pcall(function()
            local hex=Structures[key]or Others[key];if not hex then return nil end
            local editable=game:GetService('AssetService'):CreateEditableImage({Size=Vector2.new(48,48)})
            if not editable then return nil end
            local pixels=buffer.create(48*48*4)
            if #hex==48*48*2 then
                for i=0,48*48-1 do buffer.writeu32(pixels,i*4,bit32.bor(bit32.lshift(tonumber(string.sub(hex,i*2+1,i*2+2),16),24),0xffffff))end
            else for i=0,48*48-1 do buffer.writeu32(pixels,i*4,tonumber(string.sub(hex,i*8+1,i*8+8),16))end end
            editable:WritePixelsBuffer(Vector2.zero,Vector2.new(48,48),pixels);return editable
        end)
        images[key]=ok and img or false
    end
    return images[key]
end
M.image=image
function M.create(parent,key,size,color)
    local img=image(key)
    if img then
        local label=Instance.new('ImageLabel');label.Name='Icon_'..key;label.Size=UDim2.fromOffset(size,size);label.BackgroundTransparency=1
        label.ScaleType=Enum.ScaleType.Fit;label.ImageContent=Content.fromObject(img);label.ImageColor3=color or Color3.new(1,1,1);label.Parent=parent
        return label
    end
    if Structures[key]then
        local f=Instance.new('Frame');f.Name='Icon_'..key;f.Size=UDim2.fromOffset(size,size);f.BackgroundTransparency=1;f.Parent=parent
        Native.draw(f,key,color or Color3.new(1,1,1));return f
    end
    local t=Instance.new('TextLabel');t.Name='Icon_'..key;t.Size=UDim2.fromOffset(size,size);t.BackgroundTransparency=1;t.Text=fallback[key]or '?'
    t.TextScaled=true;t.Font=Enum.Font.BuilderSansBold;t.TextColor3=color or Color3.new(1,1,1);t:SetAttribute('LocalizationSkip',true);t.Parent=parent
    return t
end
function M.tint(icon,color)
    if icon:IsA('ImageLabel')then if icon.ImageColor3~=color then icon.ImageColor3=color end
    elseif icon:IsA('TextLabel')then icon.TextColor3=color
    elseif icon:GetAttribute('Ink')~=color then Native.paint(icon,color);icon:SetAttribute('Ink',color)end
end
return M
