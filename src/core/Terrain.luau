--!native
-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. Luau adaptation, 2026-10-04.
local M = {}
M.Type = { Plains=0, Highland=1, Mountain=2, Ocean=3, Impassable=4 }
function M.isLand(byte) return bit32.band(byte, 128) ~= 0 end
function M.isOcean(byte) return bit32.band(byte, 32) ~= 0 end
function M.isShoreline(byte) return bit32.band(byte, 64) ~= 0 end
function M.magnitude(byte) return bit32.band(byte, 31) end
function M.isImpassable(byte) return M.isLand(byte) and M.magnitude(byte) == 31 end
function M.cost(byte) return M.magnitude(byte) < 10 and 2 or 1 end
function M.terrainType(byte)
    if M.isLand(byte) then
        local magnitude = M.magnitude(byte)
        if magnitude >= 31 then return 4 end
        if magnitude < 10 then return 0 end
        if magnitude < 20 then return 1 end
        return 2
    end
    return 3
end
function M.neighbors(ref, width, height)
    local out, x = {}, ref % width
    if ref >= width then table.insert(out, ref - width) end
    if ref < (height - 1) * width then table.insert(out, ref + width) end
    if x ~= 0 then table.insert(out, ref - 1) end
    if x ~= width - 1 then table.insert(out, ref + 1) end
    return out
end
function M.neighbors8(ref, width, height)
    local out, x = {}, ref % width
    local hasN, hasS = ref >= width, ref < (height - 1) * width
    if x ~= 0 then
        if hasN then table.insert(out, ref - 1 - width) end
        table.insert(out, ref - 1)
        if hasS then table.insert(out, ref - 1 + width) end
    end
    if hasN then table.insert(out, ref - width) end
    if hasS then table.insert(out, ref + width) end
    if x ~= width - 1 then
        if hasN then table.insert(out, ref + 1 - width) end
        table.insert(out, ref + 1)
        if hasS then table.insert(out, ref + 1 + width) end
    end
    return out
end
return M
