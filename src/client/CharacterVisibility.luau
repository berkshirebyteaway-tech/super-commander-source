local M={};M.__index=M
function M.new()return setmetatable({characters={},nextOthers=0},M)end
function M:hide(character)
    if self.characters[character]then return end
    local entry={parts={},connections={}};self.characters[character]=entry
    local function add(part)
        if entry.parts[part]~=nil then return end
        if part:IsA('BasePart')or part:IsA('Decal')then entry.parts[part]=part.LocalTransparencyModifier;part.LocalTransparencyModifier=1 end
    end
    for _,part in ipairs(character:GetDescendants())do add(part)end
    entry.connections[1]=character.DescendantAdded:Connect(add)
    entry.connections[2]=character.DescendantRemoving:Connect(function(part)
        local original=entry.parts[part]
        if original~=nil then part.LocalTransparencyModifier=original;entry.parts[part]=nil end
    end)
end
local function enforce(entry)
    for part in pairs(entry.parts)do if part.LocalTransparencyModifier~=1 then part.LocalTransparencyModifier=1 end end
end
function M:step(now,own)
    local mine=own and self.characters[own];if mine then enforce(mine)end
    if now<self.nextOthers then return end
    self.nextOthers=now+.25
    for character,entry in pairs(self.characters)do if character~=own then enforce(entry)end end
end
function M:clear()
    for _,entry in pairs(self.characters)do
        for _,connection in ipairs(entry.connections)do connection:Disconnect()end
        for part,original in pairs(entry.parts)do if part.Parent then part.LocalTransparencyModifier=original end end
    end
    self.characters={};self.nextOthers=0
end
return M
