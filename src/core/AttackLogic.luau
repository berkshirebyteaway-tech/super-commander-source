--!native
-- SPDX-License-Identifier: AGPL-3.0-only
-- © OpenFront and Contributors. Luau adaptation, 2026-10-04.
local D = if script then require(script.Parent.DetMath) else require("./DetMath")
local M = {}
local function within(value, min, max) return math.min(math.max(value, min), max) end
local LOG_TERRITORY = D.log(300000)
local sigmoidPages = {}
local function territorySigmoid(tiles)
    if tiles>=1 and tiles<=1048576 and tiles%1==0 then
        local index=(tiles-1)//256;local offset=((tiles-1)%256)*8
        local page=sigmoidPages[index]
        if not page then page=buffer.create(2048);sigmoidPages[index]=page end
        local hit=buffer.readf64(page,offset)
        if hit~=0 then return hit end
        local value=1 / (1 + D.exp(-2.5 * (D.log(tiles) - LOG_TERRITORY)))
        buffer.writef64(page,offset,value);return value
    end
    return 1 / (1 + D.exp(-2.5 * (D.log(tiles) - LOG_TERRITORY)))
end
function M.tile(terrain, attackTroops, attackerType, attackerTiles, defenderType, defenderTiles, defenderTroops, isTraitor, isDisconnectedTeammate, borderSize, defenderHasDefensePost, falloutRatio)
    local mag, tileCost
    if terrain == 0 then mag, tileCost = 80, 16.5
    elseif terrain == 1 then mag, tileCost = 100, 20
    elseif terrain == 2 then mag, tileCost = 120, 25
    elseif terrain == 4 then error("impassable terrain cannot be attacked")
    else error("terrain type not supported") end
    if defenderType ~= nil and defenderHasDefensePost then mag = mag * 5; tileCost = tileCost * 3 end
    if falloutRatio ~= nil then
        local fallout = 5 - falloutRatio * 2
        mag = mag * fallout
        tileCost = tileCost * fallout
    end
    if defenderType == nil then
        local tickBudget = borderSize * 2
        return mag / (attackerType == "BOT" and 10 or 5), 0, within((2000 * tileCost) / attackTroops, 5, 100) / tickBudget
    end
    if isDisconnectedTeammate then mag = 0 end
    if (attackerType == "HUMAN" or attackerType == "NATION") and defenderType == "BOT" then mag = mag * 0.7 end
    local attackerSigmoid = territorySigmoid(attackerTiles)
    local largeAttackerBonus = 1 - 0.7 * attackerSigmoid
    local largeDefenderBonus = 1 - 0.3 * territorySigmoid(defenderTiles)
    local traitorLossMod = isTraitor and 0.5 or 1
    local traitorCostMod = isTraitor and 0.8 or 1
    local defenderTroopLoss = defenderTroops / defenderTiles
    local troopRatio = defenderTroops / attackTroops
    local attackerTroopLoss = mag * traitorLossMod * within(troopRatio, 0.6, 2) * (0.463 * largeAttackerBonus * largeDefenderBonus + 0.0039 * defenderTroopLoss)
    local speedCost = (within(troopRatio, 0.82, 7.5) * within(troopRatio / 20, 1, 50)) / 8.55
    local largeAttackerSpeedBonus = 1 - 0.73 * attackerSigmoid
    return attackerTroopLoss, defenderTroopLoss, (speedCost * tileCost * largeAttackerSpeedBonus * largeDefenderBonus * traitorCostMod) / borderSize
end
function M.calculate(input)
    local attacker, defender = input.attacker, input.defender
    local loss, defenseLoss, fraction = M.tile(input.terrain, input.attackTroops, attacker.type, attacker.numTiles,
        defender and defender.type, defender and defender.numTiles, defender and defender.troops,
        defender and defender.isTraitor, defender and defender.isDisconnectedTeammate,
        input.borderSize, input.defenderHasDefensePost, input.falloutRatio)
    return {
        attackerTroopLoss = loss,
        defenderTroopLoss = defenseLoss,
        tickFraction = fraction,
    }
end
return M
