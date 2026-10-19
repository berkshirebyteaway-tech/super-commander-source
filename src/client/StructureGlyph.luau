local M={}
local shapes={
    City={{3,10,5,11},{10,4,5,17},{17,13,4,8},{3,21,18,2},{11,7,3,1},{11,11,3,1},{11,15,3,1}},
    DefensePost={{4,4,16,2},{3,5,2,10},{19,5,2,10},{3,16,11,2,35},{10,16,11,2,-35},{7,10,10,2},{11,8,2,6}},
    Port={{11,3,2,16},{8,3,8,2},{5,8,14,2},{4,16,9,2,38},{11,16,9,2,-38},{3,12,2,5},{19,12,2,5}},
    Factory={{5,3,14,3},{5,6,3,8},{16,6,3,8},{5,11,14,5},{5,17,7,2,-48},{12,17,7,2,48},{5,20,14,2}},
    MissileSilo={{9,6,6,12},{9,3,5,2,-50},{11,3,5,2,50},{5,16,6,2,-50},{13,16,6,2,50},{11,19,2,4},{10,11,4,2}},
    SAMLauncher={{3,3,7,2},{3,3,2,7},{14,3,7,2},{19,3,2,7},{3,19,7,2},{3,14,2,7},{14,19,7,2},{19,14,2,7},{6,11,12,2},{11,6,2,12}},
}
function M.draw(parent,kind,ink)
    parent:ClearAllChildren()
    for i,r in ipairs(shapes[kind]or {})do
        local p=Instance.new('Frame');p.Name='RoleMark'..i;p.BorderSizePixel=0;p.BackgroundColor3=ink;p.Rotation=r[5]or 0
        p.Position=UDim2.fromScale(r[1]/24,r[2]/24);p.Size=UDim2.fromScale(r[3]/24,r[4]/24);p.ZIndex=parent.ZIndex;p.Parent=parent
    end
    parent:SetAttribute('Kind',kind);parent:SetAttribute('NativeGlyph',true)
end
function M.paint(parent,ink)for _,p in parent:GetChildren()do p.BackgroundColor3=ink end end
return M
