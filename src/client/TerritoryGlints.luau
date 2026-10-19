local G=require(script.Parent.Parent.Core.WorldGeometry)
local M={}
M.rate={[4]=3.2,[5]=7}
M.life={[4]=1.4,[5]=1.15}
M.maxPerFrame=2
M.totalRate=16
M.texture='rbxasset://textures/particles/sparkles_main.dds'
local WHITE=Color3.new(1,1,1)
local function rgb(a,f)return a and Color3.fromRGB(a[1],a[2],a[3])or f end
function M.new(folder)
    local anchor=Instance.new('Part');anchor.Name='TerritoryGlints';anchor.Anchored=true;anchor.CanCollide=false;anchor.CanQuery=false
    anchor.CanTouch=false;anchor.CastShadow=false;anchor.Transparency=1;anchor.Size=Vector3.one*.1;anchor.Parent=folder
    return {anchor=anchor,emitters={},owners={},debt={},box=nil,boxAge=1,scale=1,rng=Random.new(1018)}
end
local function emitter(g,id,s)
    local e=g.emitters[id]
    if e and e.key==s.key then return e end
    if e then e.att:Destroy()end
    local att=Instance.new('Attachment');att.Name='Glint'..tostring(id);att.Parent=g.anchor
    local p=Instance.new('ParticleEmitter');p.Texture=M.texture;p.Rate=0;p.LightEmission=1;p.LightInfluence=0;p.Brightness=s.tier>=5 and 3 or 2.2
    p.Lifetime=NumberRange.new(M.life[s.tier]*.85,M.life[s.tier]*1.15);p.Speed=NumberRange.new(0);p.LockedToPart=false
    p.Orientation=Enum.ParticleOrientation.FacingCamera;p.Rotation=NumberRange.new(0,360);p.RotSpeed=NumberRange.new(-40,40)
    p.ZOffset=.5;p.Shape=Enum.ParticleEmitterShape.Box;p.EmissionDirection=Enum.NormalId.Top
    p.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.05),NumberSequenceKeypoint.new(.7,.25),NumberSequenceKeypoint.new(1,1)})
    if s.tier>=5 then
        p.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,s.secondary),ColorSequenceKeypoint.new(.45,s.accent:Lerp(WHITE,.4)),ColorSequenceKeypoint.new(1,s.accent)})
    else p.Color=ColorSequence.new(s.accent:Lerp(WHITE,.3),s.accent)end
    p.Parent=att
    e={att=att,p=p,key=s.key,size=0};g.emitters[id]=e;return e
end
local function size(e,s,scale)
    local peak=(s.tier>=5 and 1.9 or 1.35)*scale
    if math.abs(peak-e.size)<.08*peak then return end
    e.size=peak
    e.p.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,peak*.25),NumberSequenceKeypoint.new(.35,peak),NumberSequenceKeypoint.new(1,peak*.3)})
end
M.maxOwners=10
function M.setOwners(g,styles)
    local n=0;for _ in pairs(styles)do n+=1 end
    if n>M.maxOwners then
        local list={};for id,s in pairs(styles)do table.insert(list,{id=id,s=s})end
        table.sort(list,function(a,b)if a.s.tier~=b.s.tier then return a.s.tier>b.s.tier end;if (a.s.share or 0)~=(b.s.share or 0)then return (a.s.share or 0)>(b.s.share or 0)end;return tostring(a.id)<tostring(b.id)end)
        styles={};for i=1,M.maxOwners do styles[list[i].id]=list[i].s end
    end
    g.owners=styles
    for id,e in pairs(g.emitters)do if not styles[id]then e.att:Destroy();g.emitters[id]=nil;g.debt[id]=nil end end
    for id,s in pairs(styles)do emitter(g,id,s)end
end
local function viewBox(camera,width,height)
    local vp=camera.ViewportSize;local half=Vector2.new(width,height)*G.scale/2
    local minX,minZ,maxX,maxZ=math.huge,math.huge,-math.huge,-math.huge
    for _,f in ipairs({{0,0},{1,0},{0,1},{1,1},{.5,.5}})do
        local ray=camera:ViewportPointToRay(vp.X*f[1],vp.Y*f[2])
        local dy=ray.Direction.Y;local hit
        if dy<-1e-3 then hit=ray.Origin+ray.Direction*((G.surfaceY-ray.Origin.Y)/dy)
        else hit=ray.Origin+Vector3.new(ray.Direction.X,0,ray.Direction.Z).Unit*1e4 end
        minX=math.min(minX,hit.X);maxX=math.max(maxX,hit.X);minZ=math.min(minZ,hit.Z);maxZ=math.max(maxZ,hit.Z)
    end
    minX=math.max(minX,-half.X);maxX=math.min(maxX,half.X);minZ=math.max(minZ,-half.Y);maxZ=math.min(maxZ,half.Y)
    if minX>=maxX or minZ>=maxZ then return nil end
    return {x=minX,z=minZ,w=maxX-minX,h=maxZ-minZ}
end
function M.step(g,dt,camera,width,height,owners,reduced)
    if reduced or not next(g.owners)or not camera then return end
    g.boxAge+=dt
    if g.boxAge>=.25 then
        g.boxAge=0;g.box=viewBox(camera,width,height)
        local focus=camera.Focus.Position;g.scale=math.clamp((camera.CFrame.Position-focus).Magnitude/34,.7,3)
    end
    local box=g.box;if not box then return end
    local emitted=0
    local sum=0;for _,s in pairs(g.owners)do sum+=(M.rate[s.tier]or 0)+(s.tier>=5 and 3*((s.phase or 1)-1)or 0)end
    local share=math.min(1,M.totalRate/math.max(sum,1))*math.clamp(2.2/g.scale,.35,1)
    for id,s in pairs(g.owners)do
        local rate=((M.rate[s.tier]or 0)+(s.tier>=5 and 3*((s.phase or 1)-1)or 0))*share
        local debt=math.min((g.debt[id]or 0)+rate*dt,2);g.debt[id]=debt
        while debt>=1 and emitted<M.maxPerFrame do
            debt-=1;emitted+=1
            for _=1,5 do
                local x=box.x+g.rng:NextNumber()*box.w;local z=box.z+g.rng:NextNumber()*box.h
                local tile=G.toTile(x,z,width,height)
                if tile and owners[tile]==id then
                    local e=emitter(g,id,s);size(e,s,g.scale)
                    local wx,wy,wz=G.toWorld(tile,width,height)
                    e.att.WorldPosition=Vector3.new(wx,wy+.12,wz);e.p:Emit(1)
                    break
                end
            end
        end
        g.debt[id]=debt
    end
end
function M.styleFor(style,phase,share)
    local s={tier=style.tier or 0,accent=rgb(style.accent,Color3.fromRGB(255,207,91)),secondary=rgb(style.secondary,WHITE),phase=phase,share=share}
    s.key=tostring(style.id)..':'..s.tier;return s
end
function M.destroy(g)if g.anchor then g.anchor:Destroy()end;g.emitters={};g.owners={}end
return M
