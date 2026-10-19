local sources={troops=require(script.Parent.IconPixels_soldier),gold=require(script.Parent.IconPixels_gold),attack=require(script.Parent.IconPixels_attack),build=require(script.Parent.IconPixels_build),npc=require(script.Parent.IconPixels_npc)}
local M={};local cache={}
function M.create(parent,key,size)
    if key=='transport' then
        local label=Instance.new('ImageLabel');label.Name='Icon_transport';label.Size=UDim2.fromOffset(size,size)
        label.BackgroundTransparency=1;label.Parent=parent;require(script.Parent.TransportGlyph).attach(label)
        label:SetAttribute('Available',true);return label
    end
    if cache[key]==nil then
        local ok,img=pcall(function()
            local image=game:GetService("AssetService"):CreateEditableImage({Size=Vector2.new(64,64)})
            if not image then return nil end
            local pixels=buffer.create(64*64*4);local hex=sources[key]
            for i=0,4095 do buffer.writeu32(pixels,i*4,tonumber(string.sub(hex,i*8+1,i*8+8),16)) end
            image:WritePixelsBuffer(Vector2.zero,Vector2.new(64,64),pixels);return image
        end)
        cache[key]=ok and img or false
    end
    local label=Instance.new("ImageLabel");label.Name="Icon_"..key;label.Size=UDim2.fromOffset(size,size);label.BackgroundTransparency=1;label.ScaleType=Enum.ScaleType.Fit
    if cache[key] then label.ImageContent=Content.fromObject(cache[key])
    elseif key=='troops' then require(script.Parent.SoldierGlyph).attach(label)
    else label.Visible=false end
    label:SetAttribute("Available",cache[key]~=false or key=='troops');label.Parent=parent;return label
end
function M.button(button,key)
    local image=M.create(button,key,28);image.Position=UDim2.new(0,0,0.5,-14)
    local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,8);pad.PaddingRight=UDim.new(0,4);pad.Parent=button
    button.TextXAlignment=Enum.TextXAlignment.Right
    return image
end
return M
