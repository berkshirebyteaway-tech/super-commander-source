local M={};M.__index=M
function M.new()return setmetatable({parts={},frames={},indices={}},M)end
function M:put(part,cf)
    local index=self.indices[part]
    if not index then index=#self.parts+1;self.indices[part]=index;self.parts[index]=part end
    self.frames[index]=cf
end
function M:get(part)local index=self.indices[part];return index and self.frames[index]or part.CFrame end
function M:clear()table.clear(self.parts);table.clear(self.frames);table.clear(self.indices)end
function M:flush()
    if #self.parts>0 then workspace:BulkMoveTo(self.parts,self.frames,Enum.BulkMoveMode.FireCFrameChanged)end
    self:clear()
end
return M
