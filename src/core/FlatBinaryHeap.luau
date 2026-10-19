--!native
-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. Luau adaptation, 2026-10-04.
local H = {}
H.__index = H
local float = buffer.create(4)
local function f32(value) buffer.writef32(float,0,value); return buffer.readf32(float,0) end
function H.new(capacity) return setmetatable({pri={},tiles={},len=0,capacity=capacity or 1024},H) end
function H:size() return self.len end
function H:clear() self.len=0 end
function H:enqueue(tile,priority)
    if self.len == self.capacity then self.capacity=self.capacity * 2 end
    local i=self.len
    self.len=self.len + 1
    while i>0 do
        local parent=math.floor((i-1)/2)
        if priority >= self.pri[parent] then break end
        self.pri[i],self.tiles[i]=self.pri[parent],self.tiles[parent]
        i=parent
    end
    self.pri[i],self.tiles[i]=f32(priority),tile
end
function H:dequeue()
    assert(self.len>0,"heap empty")
    local top=self.tiles[0]
    self.len=self.len-1
    local lastPri,lastTile=self.pri[self.len],self.tiles[self.len]
    local i=0
    while true do
        local left=i*2+1
        if left>=self.len then break end
        local right=left+1
        local child=right<self.len and self.pri[right]<self.pri[left] and right or left
        if lastPri<=self.pri[child] then break end
        self.pri[i],self.tiles[i]=self.pri[child],self.tiles[child]
        i=child
    end
    self.pri[i],self.tiles[i]=lastPri,lastTile
    return top
end
function H:getState()
    local pri,tiles={},{}
    for i=0,self.len-1 do pri[i+1],tiles[i+1]=self.pri[i],self.tiles[i] end
    return {pri=pri,tiles=tiles,capacity=self.capacity}
end
function H.fromState(state)
    local h=H.new(state.capacity)
    for i,value in ipairs(state.pri) do h.pri[i-1]=f32(value) end
    for i,value in ipairs(state.tiles) do h.tiles[i-1]=value end
    h.len=#state.tiles
    return h
end
return H
