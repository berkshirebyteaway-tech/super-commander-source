local M={};M.color=Color3.fromRGB(110,225,132)
local rows={
    '0000000000000000','1100000000000011','1110011111100111','1111110111111111',
    '1111101100111111','0111111000011110','0011110110111100','0001101101111000',
    '0000110111110000','0000011111100000','0000000111000000','0000000000000000',
}
function M.attach(parent)
    local old=parent:FindFirstChild('JoinedHands');if old then return old end
    local root=Instance.new('Frame');root.Name='JoinedHands';root.BackgroundTransparency=1;root.Size=UDim2.fromScale(1,1);root.ZIndex=parent.ZIndex+1
    for y,row in ipairs(rows)do
        local x=1
        while x<=#row do
            if row:sub(x,x)=='1'then
                local finish=x;while finish<#row and row:sub(finish+1,finish+1)=='1'do finish+=1 end
                local p=Instance.new('Frame');p.BorderSizePixel=0;p.BackgroundColor3=M.color;p.Position=UDim2.fromScale((x-1)/16,(y-1)/12);p.Size=UDim2.fromScale((finish-x+1)/16,1/12);p.ZIndex=root.ZIndex;p.Parent=root;x=finish+1
            else x+=1 end
        end
    end
    root.Parent=parent;return root
end
return M
