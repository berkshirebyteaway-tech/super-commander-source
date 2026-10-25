local M={};local cache={}
local function image(name)
    if cache[name]==nil then
        local ok,img=pcall(function()
            local data=require(script.Parent[name])
            local editable=game:GetService('AssetService'):CreateEditableImage({Size=Vector2.new(data.w,data.h)})
            if not editable then return nil end
            local pixels=buffer.create(data.w*data.h*4);local p,pal=0,data.palette
            for c,n in string.gmatch(data.pixels,'(%a)(%d*)')do
                local len,k=tonumber(n)or 1,string.byte(c)-97
                if k>0 then local col=pal[k];for j=p,p+len-1 do buffer.writeu32(pixels,j*4,col)end end
                p+=len
            end
            editable:WritePixelsBuffer(Vector2.zero,Vector2.new(data.w,data.h),pixels);return editable
        end)
        cache[name]=ok and img or false
    end
    return cache[name]
end
local function label(parent,name,source,w,h)
    local l=Instance.new('ImageLabel');l.Name=name;l.BackgroundTransparency=1;l.ScaleType=Enum.ScaleType.Fit
    l.Size=UDim2.fromOffset(w,h)
    local img=image(source)
    if img then l.ImageContent=Content.fromObject(img);l:SetAttribute('Available',true)
    else l.Visible=false;l:SetAttribute('Available',false)end
    l.Parent=parent;return l
end
function M.create(parent,size)return label(parent,'BrandMark','BrandMarkPixels',size or 40,size or 40)end
function M.commander(parent,height)local h=height or 300;return label(parent,'DoodleCommander','DoodleCommanderPixels',math.floor(h*512/743+.5),h)end
function M.available(label)return label~=nil and label:GetAttribute('Available')==true end
function M.word(o,stroke)
    pcall(function()o.Font=Enum.Font.LuckiestGuy end)
    local s=o:FindFirstChild('Ink')or Instance.new('UIStroke');s.Name='Ink';s.Color=Color3.fromRGB(10,8,6)
    s.Thickness=stroke or math.max(2,math.floor(o.TextSize*.1+.5));s.LineJoinMode=Enum.LineJoinMode.Round;s.Parent=o
    return o
end
return M
