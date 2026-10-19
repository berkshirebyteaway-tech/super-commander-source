local masks=require(script.Parent.OutgameIconPixels)
local M={};local cache={}
local function decode(hex,pixels)
    local i,p,n=1,0,#hex
    while i<=n and p<4096 do
        local c=string.byte(hex,i)
        if c==122 or c==121 then
            local run=tonumber(string.sub(hex,i+1,i+2),16)or 0;local px=c==122 and 0x00FFFFFF or 0xFFFFFFFF
            for _=1,math.min(run,4096-p)do buffer.writeu32(pixels,p*4,px);p+=1 end
            i+=3
        else
            buffer.writeu32(pixels,p*4,0x00FFFFFF+(tonumber(string.sub(hex,i,i+1),16)or 0)*0x1000000);p+=1;i+=2
        end
    end
end
local function image(key)
    if cache[key]==nil then
        local hex=masks[key]
        local ok,img=pcall(function()
            if not hex then return nil end
            local editable=game:GetService('AssetService'):CreateEditableImage({Size=Vector2.new(64,64)})
            if not editable then return nil end
            local pixels=buffer.create(64*64*4)
            decode(hex,pixels)
            editable:WritePixelsBuffer(Vector2.zero,Vector2.new(64,64),pixels);return editable
        end)
        cache[key]=ok and img or false
    end
    return cache[key]
end
function M.create(parent,key,size,color)
    local label=Instance.new('ImageLabel');label.Name='Icon';label.BackgroundTransparency=1;label.ScaleType=Enum.ScaleType.Fit
    label.Size=UDim2.fromOffset(size or 16,size or 16);label.ImageColor3=color or Color3.new(1,1,1)
    M.set(label,key);label.Parent=parent;return label
end
function M.set(label,key)
    if label:GetAttribute('IconKey')==key then return label end
    label:SetAttribute('IconKey',key)
    local img=key and image(key)
    if img then label.ImageContent=Content.fromObject(img);label.ImageTransparency=0;label:SetAttribute('Available',true)
    else label.ImageTransparency=1;label:SetAttribute('Available',false)end
    return label
end
function M.available(label)return label:GetAttribute('Available')==true end
return M
