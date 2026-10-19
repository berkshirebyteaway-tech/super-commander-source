local M={default='standard',envelope=Vector3.new(11.8,12.2,5.8)}
M.styles={standard={id='standard',material=Enum.Material.SmoothPlastic,trim=Color3.fromRGB(191,207,218),line=Color3.fromRGB(212,221,226),pattern='centerBand'}}
M.styles.arctic={id='arctic',material=Enum.Material.SmoothPlastic,trim=Color3.fromRGB(214,244,255),line=Color3.fromRGB(196,224,242),pattern='centerBand'}
M.styles.copper={id='copper',material=Enum.Material.SmoothPlastic,trim=Color3.fromRGB(214,170,116),line=Color3.fromRGB(210,191,161),pattern='centerBand'}
for id,s in pairs(require(script.Parent.Parent.Core.CosmeticCatalog).styles)do if s.category=='parachute'then
    M.styles[id]={id=id,material=Enum.Material.SmoothPlastic,trim=Color3.fromRGB(table.unpack(s.secondary)),line=Color3.fromRGB(table.unpack(s.accent)),pattern='centerBand',collection=s}
end end
function M.get(id)return M.styles[id]or M.styles[M.default]end
return M
