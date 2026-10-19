local M={};M.__index=M
function M.new()return setmetatable({characters={}},M)end
function M:hide(character)
    if self.characters[character]then return end
    local entry={parts={},connections={}};self.characters[character]=entry
    local function add(part)
        if part:IsA('BasePart')and entry.parts[part]==nil then entry.parts[part]=part.LocalTransparencyModifier;part.LocalTransparencyModifier=1 end
    end
    for _,part in ipairs(character:GetDescendants())do add(part)end
    entry.connections[1]=character.DescendantAdded:Connect(add)
    entry.connections[2]=character.DescendantRemoving:Connect(function(part)
        local original=entry.parts[part]
        if original~=nil then part.LocalTransparencyModifier=original;entry.parts[part]=nil end
    end)
end
function M:clear()
    for _,entry in pairs(self.characters)do
        for _,connection in ipairs(entry.connections)do connection:Disconnect()end
        for part,original in pairs(entry.parts)do if part.Parent then part.LocalTransparencyModifier=original end end
    end
    self.characters={}
end
return M
