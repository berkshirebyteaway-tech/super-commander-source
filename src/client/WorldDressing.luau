local Geo=require(script.Parent.ToyGeometry)
local M={}
function M.plaza(parent,origin)
    local folder=Instance.new('Folder');folder.Name='ArchitecturalFinish';folder.Parent=parent
    local rgb=Color3.fromRGB
    local function part(name,size,pos,color)
        local p=Geo.part(folder,name,Vector3.new(unpack(size)),CFrame.new(origin+Vector3.new(unpack(pos))),color,'armor')
        p.Material=Enum.Material.Metal;p.Reflectance=.02;p.CastShadow=false;return p
    end
    for _,x in ipairs({-155,-108,108,155})do
        part('WallPier',{3.6,64,3.4},{x,32,-119},rgb(44,55,69))
        part('PierInset',{1.3,45,.20},{x,34,-117.15},rgb(17,24,32))
        part('PierFoot',{5.6,3,5},{x,1.5,-118.8},rgb(64,76,90))
        local strip=part('PierLight',{.18,21,.12},{x,41,-117},rgb(168,203,215));strip.Material=Enum.Material.Neon;strip.Transparency=.4
    end
    for _,x in ipairs({-62,0,62})do
        for _,dx in ipairs({-19,19})do
            part('DeploymentUpright',{1.1,32,2},{x+dx,16,-72.5},rgb(70,84,100))
            part('DeploymentFoot',{3,.35,5},{x+dx,.18,-72},rgb(39,49,62))
        end
        part('DeploymentLintel',{39,1.1,2},{x,32.1,-72.5},rgb(80,94,110))
        part('BayFloorInset',{36,.025,1.2},{x,.035,-27},rgb(49,64,79))
        part('BayFloorMark',{8,.028,.15},{x,.055,-26.5},rgb(125,151,166))
    end
    for _,x in ipairs({-103,103})do
        part('WalkwayInset',{.3,.025,120},{x,.035,4},rgb(65,78,94))
        for _,z in ipairs({-44,-4,36})do part('WalkwayMarker',{3,.03,.3},{x,.055,z},rgb(126,147,163))end
    end
    for _,side in ipairs({-1,1})do
        part('WallBelt',{1.6,1.4,316},{side*167.6,25.6,-10},rgb(58,70,86))
        for _,z in ipairs({-99,-57,-15,27,69})do
            part('SidePier',{3,60,3.4},{side*167.4,56,z},rgb(40,50,63))
            part('SidePierCap',{3.6,1.2,4.2},{side*167.2,86,z},rgb(64,76,90))
        end
        for _,z in ipairs({-78,-36,6,48})do
            part('BannerBay',{.6,30,19},{side*168.4,44,z},rgb(18,25,33))
            part('BannerBayFrame',{1.2,.8,20},{side*168.1,59.4,z},rgb(70,84,100))
            local lamp=part('BannerLamp',{.3,.25,15},{side*167.6,58.8,z},rgb(255,206,150));lamp.Material=Enum.Material.Neon;lamp.Transparency=.35
        end
    end
    part('BackBelt',{420,1.4,1.6},{0,50.9,-121.8},rgb(58,70,86))
    folder:SetAttribute('ArtVersion','CleanWarRoomFinish2');return folder
end
return M
