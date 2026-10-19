--!native
-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. Luau adaptation, 2026-10-04.
local R = {}
R.__index = R
local U32 = 4294967296
local function u32(n)
    if n ~= n or n == math.huge or n == -math.huge then return 0 end
    return (n < 0 and math.ceil(n) or math.floor(n)) % U32
end
local function signed(n) return n >= 2147483648 and n - U32 or n end
local function imul(a, b)
    local al, ah = a % 65536, math.floor(a / 65536)
    local bl, bh = b % 65536, math.floor(b / 65536)
    return (al * bl + ((ah * bl + al * bh) % 65536) * 65536) % U32
end
function R.new(seed)
    local h = u32(seed)
    local function split()
        h = (h + 0x9e3779b9) % U32
        local t = bit32.bxor(h, bit32.rshift(h, 16))
        t = imul(t, 0x21f0aaad)
        t = bit32.bxor(t, bit32.rshift(t, 15))
        t = imul(t, 0x735a2d97)
        return bit32.bxor(t, bit32.rshift(t, 15))
    end
    local self = setmetatable({ s0 = split(), s1 = split(), s2 = split(), s3 = split() }, R)
    for _ = 1, 12 do self:next() end
    return self
end
function R.fromState(state)
    return setmetatable({s0=u32(state[1]),s1=u32(state[2]),s2=u32(state[3]),s3=u32(state[4])},R)
end
function R:getState() return { signed(self.s0), signed(self.s1), signed(self.s2), signed(self.s3) } end
function R:next()
    local t = (self.s0 + self.s1 + self.s3) % U32
    self.s3 = (self.s3 + 1) % U32
    self.s0 = bit32.bxor(self.s1, bit32.rshift(self.s1, 9))
    self.s1 = (self.s2 + bit32.lshift(self.s2, 3)) % U32
    self.s2 = bit32.bor(bit32.lshift(self.s2, 21), bit32.rshift(self.s2, 11))
    self.s2 = (self.s2 + t) % U32
    return t / U32
end
function R:nextInt(min, max) return math.floor(self:next() * (math.floor(max) - math.floor(min))) + math.floor(min) end
function R:nextFloat(min, max) return self:next() * (max - min) + min end
function R:nextID()
    local n, out = math.floor(self:next() * 2821109907456), ""
    local alphabet = "0123456789abcdefghijklmnopqrstuvwxyz"
    for _ = 1, 8 do
        local digit = n % 36
        out = string.sub(alphabet, digit + 1, digit + 1) .. out
        n = math.floor(n / 36)
    end
    return out
end
function R:randElement(array)
    assert(#array > 0, "array must not be empty")
    return array[self:nextInt(0, #array) + 1]
end
function R:randFromSet(orderedValues)
    assert(#orderedValues > 0, "set must not be empty")
    return self:randElement(orderedValues)
end
function R:chance(odds) return self:nextInt(0, odds) == 0 end
function R:shuffleArray(array)
    local result = table.clone(array)
    for i = #result, 2, -1 do
        local j = self:nextInt(0, i) + 1
        result[i], result[j] = result[j], result[i]
    end
    return result
end
return R
