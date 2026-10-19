--!native
-- SPDX-License-Identifier: AGPL-3.0-only
local S = {}; S.__index = S
function S.new() return setmetatable({dense={},index={},size=0,revision=0},S) end
function S:has(v) return self.index[v] ~= nil end
function S:add(v)
    local index,dense=self.index,self.dense
    if index[v] then return end
    local n=#dense+1;dense[n]=v;index[v]=n;self.size+=1;self.revision+=1
end
local function compact(self)
    local dense,index=self.dense,self.index;local n=0
    for i=1,#dense do local v=dense[i]; if v~=false then n+=1; dense[n]=v; index[v]=n end end
    for i=#dense,n+1,-1 do dense[i]=nil end
end
function S:delete(v)
    local i=self.index[v]
    if i then
        self.dense[i]=false; self.index[v]=nil; self.size-=1;self.revision+=1
        if not self.walking then local holes=#self.dense-self.size; if holes>64 and holes>self.size then compact(self) end end
    end
end
function S:clear() if self.size>0 then self.revision+=1 end;table.clear(self.dense); table.clear(self.index); self.size=0 end
function S:forEach(fn)
    local i=1;local dense=self.dense
    self.walking=(self.walking or 0)+1
    while i<=#dense do local v=dense[i]; if v~=false then fn(v) end; i+=1 end
    self.walking-=1; if self.walking==0 then self.walking=nil end
end
function S:values() local out={};self:forEach(function(v) table.insert(out,v) end);return out end
return S
