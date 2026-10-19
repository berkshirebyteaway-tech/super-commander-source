local UI=require(script.Parent.Theme)
local M={}
local ok,atlas=pcall(require,script.Parent.FlagAtlas)
M.atlas=ok and atlas or nil
local function plate(frame)
    local p=frame:FindFirstChild("FlagPlate")
    if not p then
        p=UI.make("TextLabel",frame,{Name="FlagPlate",Size=UDim2.fromScale(1,1),BackgroundColor3=UI.colors.ink,BorderSizePixel=0,TextColor3=UI.colors.bg,TextSize=10,ZIndex=(frame.ZIndex or 1)+4,AutoLocalize=false})
        p:SetAttribute("LocalizationSkip",true);UI.display(p,true);UI.corner(p,2)
    end
    return p
end
local function image(frame)
    local i=frame:FindFirstChild("FlagImage")
    if not i then i=UI.make("ImageLabel",frame,{Name="FlagImage",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Stretch,ZIndex=(frame.ZIndex or 1)+5});UI.corner(i,2)end
    return i
end
function M.apply(frame,code)
    local p=frame:FindFirstChild("FlagPlate");local i=frame:FindFirstChild("FlagImage")
    if type(code)~="string" or code=="" then if p then p.Visible=false end;if i then i.Visible=false end;return false end
    local a=M.atlas;local index=a and a.index[code]
    if index then
        i=image(frame);i.Visible=true;i.Image=a.image;i.ImageRectSize=a.cell
        i.ImageRectOffset=Vector2.new(index%a.columns*a.cell.X,math.floor(index/a.columns)*a.cell.Y)
        if p then p.Visible=false end
    else
        p=plate(frame);p.Visible=true;p.Text=string.upper(code)
        if i then i.Visible=false end
    end
    return true
end
return M
