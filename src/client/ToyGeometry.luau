local Assets=game:GetService("AssetService")
local Run=game:GetService("RunService")
local M={templates={},meshes={},diagnostics={}}
local function meshTemplate(kind)
    local mesh=Assets:CreateEditableMesh();if not mesh then return end
    local positions={}
    local function vertex(p)local id=mesh:AddVertex(p);positions[id]=p;return id end
    local function face(a,b,c)
        local normal=(positions[b]-positions[a]):Cross(positions[c]-positions[a]).Unit
        local f=mesh:AddTriangle(a,b,c);local n=mesh:AddNormal(normal);mesh:SetFaceNormals(f,{n,n,n})
    end
    if kind:match('^standard%d+$')then
        local Rules=require(script.Parent.Parent.Core.CommanderStandardRules)
        local item=Rules.items[tonumber(kind:match('%d+'))]
        local function point(x,y,z,a,cx,cy)return Vector3.new(cx+x*math.cos(a)-y*math.sin(a),cy+x*math.sin(a)+y*math.cos(a),z)end
        for _,s in ipairs(Rules.emblem(item.id))do
            local cx,cy=(s[1]-.5)*1.22,(.5-s[2])*1.18;local a=-math.rad(s[5]);local w,h=s[3]*1.22/2,s[4]*1.18/2
            for _,z in ipairs({-.006,.006})do
                local a1=vertex(point(-w,-h,z,a,cx,cy));local b=vertex(point(w,-h,z,a,cx,cy));local c=vertex(point(w,h,z,a,cx,cy));local d=vertex(point(-w,h,z,a,cx,cy))
                face(a1,b,c);face(a1,c,d)
            end
        end
    elseif kind=="dish"then
        local rings={}
        for _,r in ipairs({.025,.22,.38,.5})do
            local ids={};for i=0,23 do local a=i/24*math.pi*2;table.insert(ids,vertex(Vector3.new(math.cos(a)*r,r*r*1.7-.2,math.sin(a)*r)))end;table.insert(rings,ids)
        end
        for j=1,#rings-1 do for i=1,24 do local n=i%24+1;face(rings[j][i],rings[j+1][n],rings[j+1][i]);face(rings[j][i],rings[j][n],rings[j+1][n])end end
    else
        local rings={};local profiles=kind=="key"and {{-.5,.97},{-.4,1},{.30,.86},{.46,.77},{.5,.70}}or kind=="board"and {{-.5,.996},{-.35,1},{.35,1},{.5,.996}}or {{-.5,.90},{-.35,1},{.35,1},{.5,.90}}
        for _,profile in ipairs(profiles)do
            local ids={};local radius=kind=="board"and .014 or kind=="armor"and .055 or .15;local scale=profile[2]
            for corner=0,3 do
                local angle=corner*math.pi/2;local cx=math.cos(angle+math.pi/4)*(.5-radius)*math.sqrt(2);local cz=math.sin(angle+math.pi/4)*(.5-radius)*math.sqrt(2)
                local steps=kind=="armor"and 1 or 5
                for k=0,steps do local a=angle+k/steps*math.pi/2;table.insert(ids,vertex(Vector3.new((cx+math.cos(a)*radius)*scale,profile[1],(cz+math.sin(a)*radius)*scale)))end
            end
            table.insert(rings,ids)
        end
        local count=#rings[1]
        for j=1,#rings-1 do for i=1,count do local n=i%count+1;face(rings[j][i],rings[j+1][i],rings[j+1][n]);face(rings[j][i],rings[j+1][n],rings[j][n])end end
        local bottom=vertex(Vector3.new(0,-.5,0));local top=vertex(Vector3.new(0,.5,0))
        for i=1,count do local n=i%count+1;face(bottom,rings[1][i],rings[1][n]);face(top,rings[#rings][n],rings[#rings][i])end
    end
    local content=Content.fromObject(mesh)
    local result,static=Assets:CreateDataModelContentAsync(content)
    if result~=Enum.CreateContentResult.Success then mesh:Destroy();error(tostring(result))end
    content=static
    local p=Assets:CreateMeshPartAsync(content,{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Automatic})
    p.DoubleSided=kind=="dish"or kind:match('^standard%d+$')~=nil;p.Size=Vector3.one;M.templates[kind]=p;mesh:Destroy()
end
local kinds={"soft","key","dish","board","armor"}
for i=1,8 do table.insert(kinds,'standard'..i)end
if Run:IsClient()then
    local library=script.Parent.Parent:WaitForChild("ToyMeshLibrary",20)
    for _,kind in ipairs(kinds)do
        local p=library and library:WaitForChild(kind,5)
        if p and p:IsA("MeshPart")then M.templates[kind]=p end
        M.diagnostics[kind]=M.templates[kind]and "shared mesh"or "fallback"
    end
else
    local library=Instance.new("Folder");library.Name="ToyMeshLibrary"
    for _,kind in ipairs(kinds)do
        local ok,err=pcall(meshTemplate,kind)
        if not ok then M.templates[kind]=nil end
        M.diagnostics[kind]=M.templates[kind]and "mesh"or tostring(err or "memory budget")
        local p=M.templates[kind]or Instance.new("Folder");p.Name=kind;p.Parent=library
    end
    library.Parent=script.Parent.Parent
end
function M.part(parent,name,size,cf,color,shape)
    local template=M.templates[shape or "soft"]
    local p=template and template:Clone()or Instance.new("Part")
    p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=Enum.Material.SmoothPlastic
    p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=true;p.Parent=parent
    return p
end
function M.block(parent,name,size,cf,color)
    local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=true;p.Parent=parent;return p
end
function M.ball(parent,name,size,cf,color)local p=M.block(parent,name,size,cf,color);p.Shape=Enum.PartType.Ball;return p end
function M.cylinder(parent,name,radius,height,cf,color)
    local p=M.block(parent,name,Vector3.new(height,radius*2,radius*2),cf*CFrame.Angles(0,0,math.pi/2),color);p.Shape=Enum.PartType.Cylinder;return p
end
function M.rod(parent,name,a,b,radius,color)
    local mid=(a+b)/2;local up=(b-a).Unit;local axis=math.abs(up:Dot(Vector3.yAxis))>.95 and Vector3.xAxis or Vector3.yAxis
    local right=up:Cross(axis).Unit;return M.cylinder(parent,name,radius,(b-a).Magnitude,CFrame.fromMatrix(mid,right,up,right:Cross(up)),color)
end
function M.label(part,text,color,face,size)
    local gui=Instance.new("SurfaceGui");gui.Name="ToyPrint";gui.Face=face or Enum.NormalId.Front;gui.CanvasSize=Vector2.new(384,192);gui.MaxDistance=180;gui.LightInfluence=.25;gui.Parent=part
    local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text;t.Font=Enum.Font.BuilderSansBold;t.TextSize=size or 72;t.TextColor3=color;t.Parent=gui;return gui
end
function M.shadow(parent,x,z,radius)
    local p=M.cylinder(parent,"ContactShadow",radius,.025,CFrame.new(x,.025,z),Color3.fromRGB(37,64,71));p.Transparency=.78;p.CastShadow=false;p:SetAttribute("BaseTransparency",.78);return p
end
return M
