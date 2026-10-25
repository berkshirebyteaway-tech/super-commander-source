local P=require(script.Parent.PlazaLayout)
local M={}
M.origin=Vector3.new(P.x,P.y,P.z)
M.wallRadius=50;M.height=46
M.dais=Vector3.new(0,.38,13.5)
M.pads={
    {pos=Vector3.new(-5.3,.28,12),yaw=-14},{pos=Vector3.new(5.3,.28,12),yaw=14},
    {pos=Vector3.new(-10,.28,10),yaw=-20},{pos=Vector3.new(10,.28,10),yaw=20},
}
M.globe=Vector3.new(0,8.7,0);M.globeRadius=3
M.shots={
    wide={pos=Vector3.new(0,15.5,44.5),look=Vector3.new(0,3.8,8),fov=33,aspect=16/9},
    tall={pos=Vector3.new(0,17.5,52.5),look=Vector3.new(0,5,8),fov=57,aspect=9/16},
}
M.balconyY=6.45
M.balconyRows={44.6,46.9,48.6}
M.balconyArcs={{14,60},{120,166}}
M.balconyStep=2.9
M.balconyShown=24
function M.world(v)return M.origin+v end
local slots
function M.balconySlot(n)
    if not slots then
        slots={}
        for _,r in ipairs(M.balconyRows)do
            local step=math.deg(M.balconyStep/r);local row={}
            for _,arc in ipairs(M.balconyArcs)do
                local a=arc[1]+step/2;while a<=arc[2]-step/2+1e-6 do table.insert(row,a);a+=step end
            end
            table.sort(row,function(x,y)return math.abs(x-90)<math.abs(y-90)end)
            for _,a in ipairs(row)do table.insert(slots,{r=r,a=a})end
        end
    end
    local s=slots[n];if not s then return nil end
    local a=math.rad(s.a);local p=Vector3.new(math.cos(a)*s.r,M.balconyY,-math.sin(a)*s.r)
    return CFrame.lookAt(M.world(p),M.world(Vector3.new(0,M.balconyY,0)))
end
function M.balconyCount()M.balconySlot(1);return #slots end
M.meshes={
    L2_Dais={id='rbxassetid://71649959249877',size=Vector3.new(6.8,.38,6.8)},
    L2_DaisRing={id='rbxassetid://119038480618666',size=Vector3.new(5.26,.06,5.26)},
    L2_Pad={id='rbxassetid://131039579590067',size=Vector3.new(3.5,.28,3.5)},
    L2_PadRing={id='rbxassetid://134426328747149',size=Vector3.new(2.68,.04,2.68)},
    L2_Table={id='rbxassetid://98828081234134',size=Vector3.new(10.8,3.11,10.8)},
    L2_TableGlass={id='rbxassetid://100420918952148',size=Vector3.new(10,.05,10)},
    L2_TableTrim={id='rbxassetid://113883194281555',size=Vector3.new(10.92,.08,10.92)},
    L2_Lens={id='rbxassetid://100403686559298',size=Vector3.new(2.2,.12,2.2)},
    L2_Globe={id='rbxassetid://75589693911639',size=Vector3.new(6,6,6)},
    L2_Orbit={id='rbxassetid://116890469193801',size=Vector3.new(7,.02,7)},
    L2_GlobeDots={id='rbxassetid://101153093538969',size=Vector3.new(5.862,5.467,5.782),offset=Vector3.new(.081,.278,.117)},
    L2_Wall={id='rbxassetid://119746562889375',size=Vector3.new(101.2,46,67.906)},
    L2_Fin={id='rbxassetid://109870651244542',size=Vector3.new(.9,46,2.2)},
    L2_Balcony={id='rbxassetid://92679661350733',size=Vector3.new(97.412,.9,43.271)},
    L2_Rail={id='rbxassetid://103927115886103',size=Vector3.new(84.56,.18,36.781)},
    L2_RailGlass={id='rbxassetid://75720484061992',size=Vector3.new(84.371,1.05,36.678)},
    L2_BalconyLight={id='rbxassetid://119515850691476',size=Vector3.new(84.272,.1,36.642)},
    L2_BackRim={id='rbxassetid://114115187041920',size=Vector3.new(94.075,.08,40.903)},
    L2_FloorSeamA={id='rbxassetid://119956086371538',size=Vector3.new(19.08,.01,19.08)},
    L2_FloorSeamB={id='rbxassetid://134570153139795',size=Vector3.new(34.08,.01,34.08)},
}
return M
