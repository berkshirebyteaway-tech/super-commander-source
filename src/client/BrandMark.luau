local data=require(script.Parent.BrandMarkPixels)
local M={};local cache
local function image()
    if cache==nil then
        local ok,img=pcall(function()
            local n=data.size;local editable=game:GetService('AssetService'):CreateEditableImage({Size=Vector2.new(n,n)})
            if not editable then return nil end
            local pixels=buffer.create(n*n*4);local hex,i,p,len,total=data.pixels,1,0,#data.pixels,n*n
            while i<=len and p<total do
                if string.byte(hex,i)==122 then p+=tonumber(string.sub(hex,i+1,i+2),16)or 0;i+=3
                else buffer.writeu32(pixels,p*4,tonumber(string.sub(hex,i,i+7),16)or 0);p+=1;i+=8 end
            end
            editable:WritePixelsBuffer(Vector2.zero,Vector2.new(n,n),pixels);return editable
        end)
        cache=ok and img or false
    end
    return cache
end
function M.create(parent,size)
    local label=Instance.new('ImageLabel');label.Name='BrandMark';label.BackgroundTransparency=1;label.ScaleType=Enum.ScaleType.Fit
    label.Size=UDim2.fromOffset(size or 40,size or 40)
    local img=image()
    if img then label.ImageContent=Content.fromObject(img);label:SetAttribute('Available',true)
    else label.Visible=false;label:SetAttribute('Available',false)end
    label.Parent=parent;return label
end
function M.available(label)return label~=nil and label:GetAttribute('Available')==true end
return M
