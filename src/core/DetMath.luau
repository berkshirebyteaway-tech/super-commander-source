-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. Luau adaptation, 2026-10-04.
local M = {}
local bits = buffer.create(8)
local LN2 = 0.6931471805599453
local LOG2E = 1.4426950408889634
local SQRT2 = 1.4142135623730951
local PI = 3.141592653589793
local PI_2 = 1.5707963267948966
local PI_4 = 0.7853981633974483
local TAN_PI_8 = 0.41421356237309503

function M.pow2(n)
    if n > 1023 then return math.huge end
    if n < -1022 then return 0 end
    buffer.writeu32(bits, 4, bit32.lshift(n + 1023, 20))
    buffer.writeu32(bits, 0, 0)
    return buffer.readf64(bits, 0)
end

function M.exp(x)
    if x > 709 then return math.huge end
    if x < -708 then return 0 end
    local n = math.floor(x * LOG2E + 0.5)
    local r = x - n * LN2
    local p = 1 + r * (1 + r * (1 / 2 + r * (1 / 6 + r * (1 / 24 + r * (1 / 120 + r * (1 / 720 + r * (1 / 5040 + r * (1 / 40320))))))))
    return p * M.pow2(n)
end

function M.log(x)
    if x <= 0 then return x == 0 and -math.huge or 0 / 0 end
    local e = 0
    if x < 2.2250738585072014e-308 then
        x = x * 18014398509481984
        e = -54
    end
    buffer.writef64(bits, 0, x)
    local hi = buffer.readu32(bits, 4)
    e = e + bit32.band(bit32.rshift(hi, 20), 0x7ff) - 1023
    buffer.writeu32(bits, 4, bit32.bor(bit32.band(hi, 0x000fffff), 0x3ff00000))
    local m = buffer.readf64(bits, 0)
    if m > SQRT2 then m = m * 0.5; e = e + 1 end
    local s = (m - 1) / (m + 1)
    local z = s * s
    local series = 1 + z * (1 / 3 + z * (1 / 5 + z * (1 / 7 + z * (1 / 9 + z * (1 / 11 + z * (1 / 13))))))
    return e * LN2 + 2 * s * series
end

function M.pow(x, y)
    if y == 0 or x == 1 then return 1 end
    if x == 0 then return y > 0 and 0 or math.huge end
    if x < 0 then return 0 / 0 end
    return M.exp(y * M.log(x))
end

local function atanUnit(z)
    local base = 0
    if z > TAN_PI_8 then base = PI_4; z = (z - 1) / (z + 1) end
    local w = z * z
    local series = 1 - w * (1 / 3 - w * (1 / 5 - w * (1 / 7 - w * (1 / 9 - w * (1 / 11 - w * (1 / 13 - w * (1 / 15 - w / 17)))))))
    return base + z * series
end

function M.atan2(y, x)
    if y == 0 then return x >= 0 and 0 or PI end
    if x == 0 then return y > 0 and PI_2 or -PI_2 end
    local ax = x < 0 and -x or x
    local ay = y < 0 and -y or y
    local a = ay <= ax and atanUnit(ay / ax) or PI_2 - atanUnit(ax / ay)
    if x < 0 then a = PI - a end
    return y < 0 and -a or a
end
return M
