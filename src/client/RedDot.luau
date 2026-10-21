local UI=require(script.Parent.ToyUI)
local M={SIZE=10,INSET=9}
local function pads(host)
    local p=host:FindFirstChildOfClass('UIPadding');if not p then return 0,0,0 end
    return p.PaddingLeft.Offset,p.PaddingTop.Offset,p.PaddingRight.Offset
end
function M.place(d)
    local host=d.Parent;if not host then return end
    local l,t,r=pads(host);local at=host:GetAttribute('RedDotAt')
    if typeof(at)=='Vector2'then d.Position=UDim2.fromOffset(at.X-l,at.Y-t)
    else d.Position=UDim2.new(1,r-M.INSET,0,M.INSET-t)end
end
function M.set(host,name,on)
    local d=host:FindFirstChild(name)
    if not on then if d then d.Visible=false end;return d end
    if not d then
        d=UI.make('Frame',host,{Name=name,AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(M.SIZE,M.SIZE),BackgroundColor3=UI.colors.danger,BorderSizePixel=0,ZIndex=math.max(40,host.ZIndex+2),Active=false})
        UI.corner(d,999);UI.stroke(d,UI.colors.bg,2);d:SetAttribute('AllowOverlap',true);d:SetAttribute('RedDot',true)
    end
    M.place(d);d.Visible=true;return d
end
function M.refresh(host)for _,c in ipairs(host:GetChildren())do if c:GetAttribute('RedDot')then M.place(c)end end end
function M.anchor(host,x,y,w,out)host:SetAttribute('RedDotAt',Vector2.new(math.floor(x+w+(out or 6)+.5),math.floor(y+1.5)));M.refresh(host)end
function M.onIcon(host,icon)
    local l,t=pads(host);M.anchor(host,l+icon.Position.X.Offset,t+icon.Position.Y.Offset,icon.Size.X.Offset,3)
end
return M
