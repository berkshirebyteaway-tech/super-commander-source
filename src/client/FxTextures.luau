local M={
    fire="rbxassetid://97834876863857",
    smoke="rbxassetid://87905981083929",
    dust="rbxassetid://112390213515393",
    ring="rbxassetid://105557135784934",
    burst="rbxassetid://137382990429793",
    scorch="rbxassetid://92168201833347",
    star="rbxassetid://134138521919676",
    glow="rbxassetid://139999256437305",
}
M.flipbook={fire=true,smoke=true,dust=true}
function M.has(...)for _,k in ipairs({...})do if not M[k]then return false end end;return true end
return M
