local K=require(script.Parent.Kit20)
local M={}
function M.create(parent,name,size,color)
    local root=K.make('Frame',parent,{Name=name or 'Trophy',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromOffset(size,size)})
    local function part(n,x,y,w,h,r,outline)
        local p=K.make('Frame',root,{Name=n,BackgroundColor3=color,BackgroundTransparency=outline and 1 or 0,BorderSizePixel=0})
        K.box(p,x*size,y*size,w*size,h*size);K.round(p,math.max(1,math.floor(r*size)))
        if outline then K.stroke(p,color,math.max(1,math.floor(size*.1)),0,true)end
    end
    part('Left',.04,.14,.3,.36,.12,true);part('Right',.66,.14,.3,.36,.12,true)
    part('Cup',.23,.08,.54,.54,.18);part('Stem',.43,.52,.14,.28,.02);part('Foot',.25,.8,.5,.12,.04)
    return root
end
function M.tint(root,color)
    for _,o in ipairs(root:GetDescendants())do
        if o:IsA('Frame')then o.BackgroundColor3=color elseif o:IsA('UIStroke')then o.Color=color end
    end
end
return M
