local GuiService=game:GetService('GuiService')
local M={}
function M.start(gui,cover,roster)
    local function publish()gui:SetAttribute('Loading',cover.Visible)end
    cover:GetPropertyChangedSignal('Visible'):Connect(publish);publish()
    local brand=gui.Parent and gui.Parent:FindFirstChild('FrontierLoading')
    local card=brand and brand:FindFirstChild('Cover')
    if not card or not roster or brand:GetAttribute('Lifting')then return roster end
    local host=Instance.new('Frame');host.Name='RosterHost';host.BackgroundTransparency=1;host.BorderSizePixel=0;host.ZIndex=5
    local scale=Instance.new('UIScale');scale.Parent=host
    local function fit()
        local s=gui:GetAttribute('UIScale');s=type(s)=='number'and s>0 and s or 1
        local inset=GuiService:GetGuiInset()
        scale.Scale=s;host.Position=UDim2.fromOffset(inset.X,inset.Y);host.Size=UDim2.new(1/s,-inset.X/s,1/s,-inset.Y/s)
    end
    fit();gui:GetAttributeChangedSignal('UIScale'):Connect(fit);host.Parent=card
    local base={}
    for _,name in ipairs({'Column','Tip','Copyright'})do local o=card:FindFirstChild(name);if o then base[o]={o.Position,o.Size,o.Visible}end end
    local hosted=true
    local function place()
        for o,b in pairs(base)do o.Position,o.Size,o.Visible=b[1],b[2],b[3]end
        local f=roster.frame
        if not hosted or not f.Visible then return end
        local a=card.AbsoluteSize;local p=f.AbsolutePosition-card.AbsolutePosition
        if p.X>a.X*.4 then
            local w=math.max(200,p.X-16)
            for o in pairs(base)do o.Position=UDim2.new(0,math.floor(w/2)+8,o.Position.Y.Scale,o.Position.Y.Offset);o.Size=UDim2.new(0,w-16,o.Size.Y.Scale,o.Size.Y.Offset)end
        else
            local column,tip,line=card:FindFirstChild('Column'),card:FindFirstChild('Tip'),card:FindFirstChild('Copyright')
            if column then column.Position=UDim2.new(.5,0,0,math.floor(p.Y/2))end
            if tip then tip.Visible=false end
            if line then line.Position=UDim2.new(.5,0,0,math.floor(p.Y)-4)end
        end
    end
    for _,prop in ipairs({'Visible','AbsolutePosition','AbsoluteSize'})do roster.frame:GetPropertyChangedSignal(prop):Connect(place)end
    local function leave()
        if not hosted then return end
        hosted=false;place();roster:host(nil);host:Destroy()
    end
    brand:GetAttributeChangedSignal('Lifting'):Connect(leave)
    brand.AncestryChanged:Connect(function()if not brand.Parent then leave()end end)
    roster:host(host)
    return roster
end
return M
