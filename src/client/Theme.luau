local M={}
M.colors={bg=Color3.fromRGB(11,15,20),panel=Color3.fromRGB(18,24,33),raised=Color3.fromRGB(24,33,44),line=Color3.fromRGB(38,50,65),ink=Color3.fromRGB(238,242,246),muted=Color3.fromRGB(138,151,168),accent=Color3.fromRGB(54,226,208),gold=Color3.fromRGB(245,196,81),danger=Color3.fromRGB(255,82,82),recruitmentGrow=Color3.fromRGB(85,214,163),recruitmentSlow=Color3.fromRGB(255,173,66),ocean=Color3.fromRGB(8,19,31),good=Color3.fromRGB(180,240,90),ice=Color3.fromRGB(191,239,255)}
local function face(family,weight)
    local ok,f=pcall(function()return Font.new("rbxasset://fonts/families/"..family..".json",weight or Enum.FontWeight.Bold)end)
    return ok and f or nil
end
M.fonts={display=face("Oswald",Enum.FontWeight.Bold),mono=face("BuilderMono",Enum.FontWeight.Bold) or face("RobotoMono",Enum.FontWeight.Bold)}
function M.display(o,mono)local f=mono and M.fonts.mono or M.fonts.display;if f then o.FontFace=f end;return o end
function M.make(class,parent,props)
    local o=Instance.new(class);for k,v in pairs(props or {}) do o[k]=v end;o.Parent=parent;return o
end
function M.corner(o,r) M.make("UICorner",o,{CornerRadius=UDim.new(0,(r and r>=40)and r or math.min(r or 3,3))});return o end
function M.stroke(o,color,thickness) return M.make("UIStroke",o,{Color=color or M.colors.line,Thickness=thickness or 1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
function M.panel(parent,name)
    local p=M.corner(M.make("Frame",parent,{Name=name,BackgroundColor3=M.colors.panel,BackgroundTransparency=.14,BorderSizePixel=0}),3)
    M.stroke(p,M.colors.line,1)
    return p
end
function M.fit(l,width,max,min)
    local TS=game:GetService('TextService');local size=max
    while size>min do
        local ok,v=pcall(function()return TS:GetTextSize(l.Text,size,l.Font,Vector2.new(4096,200)).X end)
        if not ok or v<=width then break end;size-=1
    end
    l.TextSize=size;return size
end
function M.label(parent,name,text,size,color)
    return M.make("TextLabel",parent,{Name=name,Text=text,TextSize=size or 16,Font=Enum.Font.BuilderSansMedium,TextColor3=color or M.colors.ink,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextWrapped=true,BorderSizePixel=0})
end
function M.button(parent,name,text,callback,primary)
    local b=M.corner(M.make("TextButton",parent,{Name=name,Text=text,TextSize=15,Font=Enum.Font.BuilderSansBold,TextColor3=primary and M.colors.bg or M.colors.ink,BackgroundColor3=primary and M.colors.accent or M.colors.raised,BorderSizePixel=0,AutoButtonColor=true,Active=true}),3)
    local face=M.corner(M.make('Frame',b,{Name='PressFeedback',Size=UDim2.fromScale(1,1),BackgroundColor3=M.colors.ice,BackgroundTransparency=1,BorderSizePixel=0,Active=false}),3);local tween
    local function fit()
        local pad=b:FindFirstChildOfClass('UIPadding')
        if pad then
            local l,r,t,d=pad.PaddingLeft.Offset,pad.PaddingRight.Offset,pad.PaddingTop.Offset,pad.PaddingBottom.Offset
            face.Position=UDim2.fromOffset(-l,-t);face.Size=UDim2.new(1,l+r,1,t+d)
        else face.Position=UDim2.new();face.Size=UDim2.fromScale(1,1)end
    end
    b.ChildAdded:Connect(function(c)if c:IsA('UIPadding')then fit();c.Changed:Connect(fit)end end)
    local function feedback(value)
        if tween then tween:Cancel()end
        local radius
        for _,o in ipairs(b:GetChildren())do if o:IsA('UICorner')then radius=o.CornerRadius end end
        if radius then face:FindFirstChildOfClass('UICorner').CornerRadius=radius end
        local alpha=value<1 and .86 or value>1 and .94 or 1
        if b:GetAttribute('Enabled')==false then alpha=1 end
        tween=game:GetService("TweenService"):Create(face,TweenInfo.new(.11,Enum.EasingStyle.Quad),{BackgroundTransparency=alpha});tween:Play()
    end
    b.MouseEnter:Connect(function()if b:GetAttribute("Enabled")~=false then feedback(1.015)end end)
    b.MouseLeave:Connect(function()feedback(1)end)
    b.InputBegan:Connect(function(i)if b:GetAttribute("Enabled")~=false and (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch)then feedback(.975)end end)
    b.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then feedback(1)end end)
    b:GetAttributeChangedSignal('Enabled'):Connect(function()if b:GetAttribute('Enabled')==false then feedback(1)end end)
    b.Activated:Connect(function() if b:GetAttribute("Enabled")~=false then require(script.Parent.ToyAudio).play("click");callback() end end);return b
end
function M.box(o,x,y,w,h) o.Position=UDim2.fromOffset(x,y);o.Size=UDim2.fromOffset(w,h);return o end
function M.enabled(b,enabled)
    b.Active=enabled;b.AutoButtonColor=enabled;b.TextTransparency=enabled and 0 or .5
    b:SetAttribute("Enabled",enabled)
end
function M.number(n)
    n=tonumber(n) or 0
    if n>=1e9 then return string.format("%.2fB",n/1e9) end
    if n>=1e6 then return string.format("%.2fM",n/1e6) end
    if n>=10000 then return string.format("%.1fK",n/1000) end
    if n>=1000 then return string.format("%.2fK",n/1000) end
    return tostring(math.floor(n))
end
M.scale=1
function M.logical(v) return v/M.scale end
function M.troops(n) return M.number((tonumber(n) or 0)/10) end
function M.commas(n)
    local s=tostring(n);local integer=s:match("^(%d+)") or s
    return (integer:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,",""))
end
return M
