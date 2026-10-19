local G=require(script.Parent.ToyGeometry)
local M={};local states=setmetatable({},{__mode='k'})
function M.apply(model,kind,style)
    local tier=style.tier or 0;if tier<4 then return end
    local trim=Color3.fromRGB(table.unpack(style.secondary));local body=Color3.fromRGB(table.unpack(style.primary)):Lerp(Color3.fromRGB(218,230,240),.2)
    local state={};states[model]=state
    local function block(name,size,cf,color,motion)
        local p=G.block(model,name,Vector3.new(table.unpack(size)),cf,color or trim);p.Material=Enum.Material.Metal;p.CastShadow=false
        if motion then table.insert(state,{part=p,home=cf,mode=motion})end;return p
    end
    local cf=CFrame.new
    if kind=='City'then
        block('RoleLegendarySkybridge',{2.45,.28,.5},cf(.15,2.1,-.67),trim)
        block('RoleLegendaryCivicArc',{.22,1.55,.4},cf(1.35,2.65,-.67)*CFrame.Angles(0,0,-.2),body)
        if tier>=5 then
            block('RoleMythicCivicCrown',{1.35,.16,.75},cf(-.6,4.5,-.55),trim)
            for _,s in ipairs({-1,1})do block('RoleMythicShutter'..s,{.18,.7,.65},cf(-.6+s*.68,4.03,-.55),body,'shutter')end
        end
    elseif kind=='DefensePost'then
        for _,s in ipairs({-1,1})do block('RoleLegendaryGateShield'..s,{.65,1.2,.38},cf(s*.62,1.2,1.9)*CFrame.Angles(0,0,-s*.12),body)end
        if tier>=5 then
            for _,s in ipairs({-1,1})do block('RoleMythicBastionWing'..s,{.75,.35,1.15},cf(s*1.75,1.7,1.35)*CFrame.Angles(0,s*.2,s*.1),trim,'shutter')end
        end
    elseif kind=='Port'then
        for _,s in ipairs({-1,1})do block('RoleLegendaryHarborGantry'..s,{.18,2.7,.22},cf(s*1.5,1.68,-.8),trim)end
        block('RoleLegendaryHarborCrossbeam',{3.3,.25,.3},cf(0,3.1,-.8),body)
        if tier>=5 then
            for _,s in ipairs({-1,1})do block('RoleMythicCargoTrolley'..s,{.5,.32,.5},cf(s*.9,3.38,-.8),trim,'trolley')end
        end
    elseif kind=='Factory'then
        block('RoleLegendaryRailCanopy',{3.75,.18,.86},cf(0,1.65,-1.12),body)
        for _,s in ipairs({-1,1})do block('RoleLegendaryPlatformArch'..s,{.2,1.3,.24},cf(s*1.75,1.02,-1.12)*CFrame.Angles(0,0,-s*.16),trim)end
        if tier>=5 then
            for _,s in ipairs({-1,1})do block('RoleMythicPantograph'..s,{.72,.09,.12},cf(.62+s*.28,1.5,.95)*CFrame.Angles(0,0,s*.5),trim,'pantograph')end
        end
    elseif kind=='MissileSilo'then
        for _,s in ipairs({-1,1})do block('RoleLegendaryLaunchDoors'..s,{.68,1.75,.2},cf(s*1.55,1.25,.45)*CFrame.Angles(0,0,-s*.2),body)end
        if tier>=5 then
            for _,s in ipairs({-1,1})do block('RoleMythicLaunchStrut'..s,{.16,2.4,.4},cf(s*1.8,1.7,-.55)*CFrame.Angles(0,0,-s*.12),trim,'shutter')end
        end
    elseif kind=='SAMLauncher'then
        for _,s in ipairs({-1,1})do block('RoleLegendaryRadarArray'..s,{.3,.9,1.1},cf(-1.05+s*.85,1.45,-.95)*CFrame.Angles(0,0,s*.2),body)end
        if tier>=5 then
            for _,s in ipairs({-1,1})do block('RoleMythicRadarPanel'..s,{.25,.65,1.35},cf(-1.05+s*1.1,2.5,-.95)*CFrame.Angles(0,0,s*.35),trim,'shutter')end
        end
    end
    model:SetAttribute('CollectionArchitecture',kind..':'..tier)
    model:SetAttribute('RoleKineticParts',#state)
end
function M.step(model,at,reduced,batch)
    if require(script.Parent.BuildingThemes).step(model,at,reduced,nil,batch)then return end
    local state=states[model];if not state or #state==0 then return end
    local pivot,scale=model:GetPivot(),model:GetScale()
    if reduced and state.lastReduced and state.lastPivot==pivot and state.lastScale==scale then return end
    state.lastReduced,state.lastPivot,state.lastScale=reduced,pivot,scale
    for i,item in ipairs(state)do
        if not item.part.Parent then continue end
        local cf=item.home
        if not reduced then local wave=math.sin(at*.7+i*.4)
            if item.mode=='trolley'then cf*=CFrame.new(wave*.18,0,0)
            elseif item.mode=='pantograph'then cf*=CFrame.new(0,wave*.035,0)
            else cf*=CFrame.Angles(0,0,wave*.035)end
        end
        local world=pivot*CFrame.new(cf.Position*scale)*(cf-cf.Position)
        if batch then batch:put(item.part,world)else item.part.CFrame=world end
    end
end
return M
