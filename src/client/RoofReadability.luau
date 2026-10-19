local Geo=require(script.Parent.ToyGeometry)
local M={}
local ice=Color3.fromRGB(211,223,235)
local steel=Color3.fromRGB(172,184,198)
local glass=Color3.fromRGB(37,76,94)
function M.apply(model,kind,detailed)
    local function finish(name,color,metal)
        for _,p in ipairs(model:GetChildren())do if p:IsA('BasePart')and p.Name==name then
            p.Color=color;if metal then p.Material=Enum.Material.Metal;p.Reflectance=.02 end
        end end
    end
    local function top(part,name,sx,sz,color,angle)
        if not part or #model:GetChildren()>=32 then return end
        local p=Geo.part(model,name,Vector3.new(sx,.035,sz),CFrame.new(part.Position.X,part.Position.Y+part.Size.Y/2+.024,part.Position.Z)*CFrame.Angles(0,angle or 0,0),color,'armor')
        p.CastShadow=false
    end
    if kind=='City'then
        finish('TowerCap1',ice,true);finish('TowerCap2',steel,true);finish('TowerCap3',glass)
        finish('TowerCrown',ice:Lerp(steel,.3),true)
        if not detailed then for i,color in ipairs({ice,steel,glass})do
            local block=model:FindFirstChild('TowerBlock'..i)
            if block then top(block,'StrategicCityRoof'..i,block.Size.X,block.Size.Z,color)end
        end end
        if detailed then top(model:FindFirstChild('TowerCrown'),'RoofSkylight',.48,.48,glass)end
    elseif kind=='DefensePost'then
        finish('BastionCap',ice,true)
        finish('Wall',Color3.fromRGB(140,151,164));finish('Bastion',Color3.fromRGB(159,170,182))
        finish('BunkerCore',Color3.fromRGB(83,99,116),true)
        if not detailed then for _,p in ipairs(model:GetChildren())do if p.Name=='Bastion'then top(p,'StrategicBastionCap',.82,.82,ice,math.pi/4)end end end
        if detailed then top(model:FindFirstChild('TurretHead'),'FortRoofInset',.43,.43,glass,math.pi/4)end
    elseif kind=='Port'then
        finish('CraneBoom',Color3.fromRGB(241,185,63),true)
        finish('CranePortal',Color3.fromRGB(241,185,63),true);finish('CraneBoom2',Color3.fromRGB(241,185,63),true)
        finish('Basin',Color3.fromRGB(32,110,149))
        finish('Hull',Color3.fromRGB(73,99,120),true)
    elseif kind=='Factory'then
        finish('PlatformCanopy',Color3.fromRGB(51,77,94));finish('Locomotive',ice)
        finish('Rail',steel,true);finish('TrainCab',ice,true)
        top(model:FindFirstChild('TrainCab'),'RailCabGlass',.32,.42,glass)
    elseif kind=='MissileSilo'then
        finish('HazardRing',Color3.fromRGB(238,180,69))
        finish('RingInner',Color3.fromRGB(51,65,80))
        finish('ServiceTower',Color3.fromRGB(72,85,99),true)
        local collar=model:FindFirstChild('SiloCollar');if collar then collar.Color=ice end
        for _,p in ipairs(model:GetChildren())do if p:IsA('BasePart')and p.Name=='MissileFin'then p.Color=steel;p.Size=Vector3.new(.13,.55,.58)end end
    elseif kind=='SAMLauncher'then
        finish('RadarDish',ice,true);finish('RadarCabin',Color3.fromRGB(116,137,156),true)
        local dish=model:FindFirstChild('RadarDish')
        if dish and #model:GetChildren()<32 then
            local feed=Geo.ball(model,'RadarFeed',Vector3.one*.22,dish.CFrame*CFrame.new(0,.06,0),glass)
            feed.CastShadow=false;model:SetAttribute('RadarFeedOffset',CFrame.new(0,.06,0))
        end
        if detailed then top(model:FindFirstChild('RadarCabin'),'RadarRoofInset',.64,.52,glass)end
    end
    model:SetAttribute('RoofReadability','TopView3')
end
return M
