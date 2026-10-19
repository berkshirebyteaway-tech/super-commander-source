local G=require(script.Parent.ToyGeometry)
local Catalog=require(script.Parent.Parent.Core.CosmeticCatalog)
local Rules=require(script.Parent.Parent.Core.SupplyRevealRules)
local M={};local states=setmetatable({},{__mode='k'})
local function rgb(a)return Color3.fromRGB(table.unpack(a))end
local function part(parent,name,size,cf,color,glow)
    local p=G.block(parent,name,size,cf,color);p.CastShadow=false
    p.Material=glow and Enum.Material.Neon or Enum.Material.Metal;p.Reflectance=glow and 0 or .08
    p:SetAttribute('BaseTransparency',0);return p
end
local roleShape={
    vehicle={ring=1.65,lift=.02,top=.75,k=1},motion={ring=1.05,lift=.05,top=.7,k=1},territory={ring=1.05,lift=.05,top=.9,k=1},
    parachute={ring=1,lift=.22,top=.3,k=1.25,radius=1.9},nuclear={ring=1.12,lift=0,top=.55},impact={ring=1.05,lift=.05,top=.7},
    City={ring=1.18,lift=.04,top=2},
}
local function shapeFor(role,r)
    local shape=roleShape[role]or{ring=1.18,lift=.04,top=.5}
    return shape,shape.k or math.clamp(r/1.5,.42,2.2)
end
local function signature(add,tier,role,r,root,accent,trim)
    local shape,k=shapeFor(role,r)
    r=shape.radius or r
    local ringR=r*shape.ring
    local lift=shape.lift*k
    for _,side in ipairs({-1,1})do add('Ceramic',Vector3.new(.24*k,.12*k,r*.8),root*CFrame.new(side*r*.8,.08*k,0),trim,false)end
    if tier>=2 then
        for _,side in ipairs({-1,1})do
            add('Shoulder',Vector3.new(.3*k,.16*k,r*.86),root*CFrame.new(side*r*.92,.16*k,0),trim,false)
            add('Seam',Vector3.new(.06*k,.06*k,r*.74),root*CFrame.new(side*r*.92,.27*k,0),accent,true)
        end
    end
    if tier>=3 then
        local n=10
        for i=0,n-1 do
            add('Ring',Vector3.new(ringR*2*math.pi/n*.62,.06*k,.09*k),root*CFrame.Angles(0,i/n*math.pi*2,0)*CFrame.new(0,lift,-ringR),accent,true,1)
        end
    end
    if tier>=4 then
        local R=ringR*1.22;local n=14
        for i=0,n-1 do
            add('Halo',Vector3.new(R*2*math.pi/n*.7,.05*k,.07*k),root*CFrame.Angles(0,i/n*math.pi*2,0)*CFrame.new(0,lift+.14*k,-R),accent:Lerp(Color3.new(),.15),true,2)
        end
        for i=0,1 do add('Satellite',Vector3.one*.24*k,root*CFrame.Angles(0,i*math.pi,0)*CFrame.new(0,lift+.3*k,-R),accent,true,2).Shape=Enum.PartType.Ball end
    end
    if tier>=5 then
        local top=shape.top*k
        add('Prism',Vector3.new(.3*k,.9*k,.3*k),root*CFrame.new(0,top+.45*k,0)*CFrame.Angles(0,math.pi/4,0),accent,true,4,1)
        for _,side in ipairs({-1,1})do add('Prism',Vector3.new(.2*k,.6*k,.2*k),root*CFrame.new(side*r*.5,top+.25*k,0)*CFrame.Angles(0,math.pi/4,side*.32),accent,true,4,2)end
        for i=0,5 do
            add('Shard',Vector3.new(.1*k,.34*k,.1*k),root*CFrame.Angles(0,i/6*math.pi*2,0)*CFrame.new(0,top+.15*k,-ringR*.9)*CFrame.Angles(.35,0,0),trim,true,4,3)
        end
    end
end
function M.apply(model,style,role,origin,radius)
    local tier=style.tier;if not tier then return end
    if not model.PrimaryPart then model.WorldPivot=CFrame.identity end
    local accent=rgb(style.accent);local trim=rgb(style.secondary)
    local root=origin or CFrame.new(0,.4,0);local r=radius or 1.7
    local state={style=style,tier=tier,root=root,parts={},phase=1};states[model]=state
    local function add(name,size,cf,color,glow,mode,phase)
        local p=part(model,'Collection_'..name,size,cf,color,glow)
        local item={part=p,home=cf,mode=mode or 0,color=color,phase=phase or 1}
        table.insert(state.parts,item);return p
    end
    signature(add,tier,role,r,root,accent,trim);state.signature=true
    if tier>=4 then local light=Instance.new('PointLight');light.Name='CollectionLight';light.Color=accent;light.Range=3;light.Brightness=.4;light.Shadows=false;light.Parent=state.parts[1].part;state.light=light end
    model:SetAttribute('CollectionTier',tier);model:SetAttribute('CollectionStyle',style.id)
    model:SetAttribute('CollectionRole',role);model:SetAttribute('CollectionMotion',tier>=5 and 4 or tier>=4 and 3 or tier>=3 and 1 or 0)
    model:SetAttribute('CollectionPhases',tier==5 and 3 or 1);model:SetAttribute('CollectionParticles',0)
    model:SetAttribute('CollectionGeometry',#state.parts)
    M.step(model,0,true,1)
    return state
end
function M.step(model,at,reduced,phase,batch)
    local state=states[model];if not state then return end
    phase=math.clamp(phase or state.phase,1,state.tier==5 and 3 or 1);state.phase=phase
    local pivot=model:GetPivot();local root=state.root
    local scale=model:GetScale();local hidden=model:GetAttribute('CollectionHidden')==true;local building=model:GetAttribute('Building')==true
    if (reduced or state.tier<3)and state.lastPivot==pivot and state.lastScale==scale and state.lastPhase==phase and state.lastHidden==hidden and state.lastBuilding==building and state.lastReduced==reduced then return end
    local moved=state.lastPivot~=pivot or state.lastScale~=scale or state.lastPhase~=phase or state.lastReduced~=reduced
    state.lastPivot=pivot;state.lastScale=scale;state.lastPhase=phase;state.lastHidden=hidden;state.lastBuilding=building;state.lastReduced=reduced
    if state.light then state.light.Enabled=not reduced and not hidden and not state.lightOff end
    local inverse=root:Inverse();local fade=building and .55 or 0
    for i,item in ipairs(state.parts)do
        local p=item.part;if not p.Parent then continue end
        local cf=item.home;local mode=item.mode
        local still=reduced or mode==0
        if not reduced then
            if mode==1 then cf=root*CFrame.Angles(0,at*.55,0)*inverse*cf
            elseif mode==2 then cf=root*CFrame.Angles(0,-at*.32,0)*inverse*cf*CFrame.new(0,math.sin(at*1.4)*.05,0)
            elseif mode==3 then cf=root*CFrame.Angles(0,at*.8,0)*inverse*cf*CFrame.new(0,math.sin(at*2+i)*.12,0)
            elseif mode==4 then cf=root*CFrame.Angles(0,-at*.24,0)*inverse*cf*CFrame.new(0,math.sin(at*1.7+i)*.08,0)end
        end
        if state.tier==5 and mode==4 then
            local hue=.45+.47*(.5+.5*math.sin((at*.055+i*.07)*math.pi*2))
            p.Color=reduced and rgb(state.style.accent)or state.signature and Color3.fromHSV(hue,.72,.92)or rgb(state.style.accent):Lerp(Color3.fromHSV(hue,.65,.85),.6)
            cf=root*CFrame.new((cf.Position-root.Position)*(.84+phase*.09))*(cf-cf.Position)
        end
        local base=item.base;if base==nil then base=p:GetAttribute('BaseTransparency')or 0;item.base=base end
        local alpha=(item.phase>phase or hidden)and 1 or math.max(base,fade)
        if math.abs(p.Transparency-alpha)>1e-4 then p.Transparency=alpha end
        if moved or not still then
            local world=pivot*(CFrame.new(cf.Position*scale)*(cf-cf.Position))
            if batch then batch:put(p,world)else p.CFrame=world end
        end
    end
    if model:GetAttribute('CollectionPhase')~=phase then model:SetAttribute('CollectionPhase',phase)end
end
function M.phase(style,share,danger)return Rules.evolution(style.tier,share,danger)end
function M.light(model,on)
    local state=states[model];if not state or not state.light then return end
    state.lightOff=not on;if not on then state.light.Enabled=false
    else state.light.Enabled=state.lastReduced==false and state.lastHidden~=true end
end
function M.sound(style)
    if style.tier and style.tier>=4 then require(script.Parent.ToyAudio).play(style.tier==5 and 'collectionMythic'or 'collectionLegendary',.55)end
end
local eagleStamp={'.....#.....','#...###...#','##..#.#..##','###.###.###','.#########.','..#######..','...#####...','..#.###.#..','.#...#...#.'}
local function territoryMotif(model,style,fill,add)
    local motif=style.motif;local light,dark=fill:Lerp(Color3.new(1,1,1),.34),fill:Lerp(Color3.new(),.38)
    local accent,trim=rgb(style.accent),rgb(style.secondary);local y=.066
    if style.flat then
        local Pattern=require(script.Parent.TerritoryCollection);local t=Pattern.texture(motif);local spec=Pattern.spec(style,1)
        if not t or not spec then return nil end
        local step=math.max(1,t.w//16);local cell=4.6/16
        for j=0,15 do local i=0
            local function code(n)return buffer.readu8(t.buf,((j*step)%t.h)*t.w+(n*step)%t.w)end
            while i<16 do
                local c=code(i);local i1=i
                while i1<15 and code(i1+1)==c do i1+=1 end
                if c>0 and spec.k[c]and spec.k[c]>0 then add('Flat',Vector3.new((i1-i+1)*cell,.03,cell),CFrame.new((i+i1)/2*cell-2.3+cell/2,y,j*cell-2.3+cell/2),fill:Lerp(spec.to[c],math.min(1,spec.k[c]*1.6)))end
                i=i1+1
            end
        end
        return nil
    end
    if motif=='grid'then
        for i=-2,2 do local w=i==0 and .07 or .035
            add('Grid',Vector3.new(w,.03,4.7),CFrame.new(i*.8,y,0),light);add('Grid',Vector3.new(4.7,.03,w),CFrame.new(0,y,i*.8),light)
        end
    elseif motif=='camo'then
        local t=require(script.Parent.TerritoryCollection).texture('camo');local tones={dark,fill:Lerp(Color3.new(),.18),fill:Lerp(Color3.new(1,1,1),.2)}
        for j=0,11 do local i=0
            while i<12 do
                local code=buffer.readu8(t.buf,(j*4)*t.w+i*4);local i1=i
                while i1<11 and buffer.readu8(t.buf,(j*4)*t.w+(i1+1)*4)==code do i1+=1 end
                if code>0 then add('Camo',Vector3.new((i1-i+1)*.4,.03,.4),CFrame.new((i+i1)/2*.4-2.2,y,j*.4-2.2),tones[code])end
                i=i1+1
            end
        end
    elseif motif=='hex'then
        local plate=fill:Lerp(Color3.new(1,1,1),.24)
        for k=-1,5 do
            local a=k*math.pi/3+math.pi/6;local c=k<0 and CFrame.new(0,y+.01,0)or CFrame.new(math.cos(a)*1.47,y+.01,math.sin(a)*1.47)
            for r=0,2 do add('HexPlate',Vector3.new(.66,.05,.66*math.sqrt(3)),c*CFrame.Angles(0,r*math.pi/3,0),plate)end
        end
        for k=0,5 do local a=k*math.pi/3;add('HexNode',Vector3.new(.12,.08,.12),CFrame.new(math.cos(a)*.8,y+.03,math.sin(a)*.8),accent,true)end
    elseif motif=='eagle'then
        for _,c in ipairs({-1.6,1.6,-3.2,3.2})do add('Diagonal',Vector3.new(.03,.03,math.sqrt(2)*(4.7-math.abs(c))),CFrame.new(c/2,y,-c/2)*CFrame.Angles(0,math.pi/4,0),accent:Lerp(fill,.45))end
        for row,line in ipairs(eagleStamp)do local i=1
            while i<=#line do
                if line:sub(i,i)=='#'then local i1=i;while line:sub(i1+1,i1+1)=='#'do i1+=1 end
                    add('Eagle',Vector3.new((i1-i+1)*.2,.06,.2),CFrame.new(((i+i1)/2-6)*.2,y+.02,(row-5)*.2),row==1 and trim or accent)
                    i=i1+1
                else i+=1 end
            end
        end
    elseif motif=='stars'then
        local violet=Color3.fromRGB(206,184,255)
        for b=1,2 do for k=0,3 do
            local z=(b==1 and -1.05 or 1.1);local pa=Vector3.new(-2.2+k*1.1,y,z+(k%2==0 and -.32 or .32)*(b==1 and 1 or -1));local pb=Vector3.new(-1.1+k*1.1,y,z-(k%2==0 and -.32 or .32)*(b==1 and 1 or -1))
            local p=add('Aurora',Vector3.new(.24,.02,(pb-pa).Magnitude+.1),CFrame.lookAt((pa+pb)/2,pb),b==2 and violet or accent,true,b)
            p.Transparency=.5;p:SetAttribute('BaseTransparency',.5)
        end end
        local stars={{-1.7,-1.5,.28,1},{-.6,-1.95,.2,2},{.9,-1.6,.26,1},{1.85,-.5,.18,3},{1.5,1.35,.28,1},{.35,1.85,.2,2},{-1.2,1.15,.24,1},{-1.95,.1,.17,3},{-.3,-1.05,.16,3}}
        for _,l in ipairs({{1,2},{2,3},{3,4},{4,5},{5,6},{6,7},{7,8},{8,1},{2,9}})do
            local a,b=stars[l[1]],stars[l[2]];local pa,pb=Vector3.new(a[1],y+.02,a[2]),Vector3.new(b[1],y+.02,b[2])
            local p=add('Link',Vector3.new(.035,.02,(pb-pa).Magnitude),CFrame.lookAt((pa+pb)/2,pb),trim,true,math.max(a[4],b[4]))
            p.Transparency=.35;p:SetAttribute('BaseTransparency',.35)
        end
        for _,s in ipairs(stars)do add('Star',Vector3.one*s[3],CFrame.new(s[1],y+.06,s[2]),trim,true,s[4]).Shape=Enum.PartType.Ball end
    else
        return require(script.Parent.TerritoryVolume).slab(motif,{add=add,fill=fill,accent=accent,trim=trim,base=rgb(style.primary or style.accent),y=y})
    end
end
local animators=setmetatable({},{__mode='k'})
local sharedStep=M.step
function M.step(model,at,reduced,phase,batch)
    sharedStep(model,at,reduced,phase,batch)
    local a=animators[model];if not a then return end
    if model:GetAttribute('CollectionHidden')==true then a.pivot=nil;return end
    local pivot,scale,ph=model:GetPivot(),model:GetScale(),states[model].phase
    if reduced then
        if a.pivot==pivot and a.scale==scale and a.phase==ph then return end
        a.pivot,a.scale,a.phase=pivot,scale,ph;at=0
    else a.pivot=nil end
    a.fn(at,ph,function(p,cf)local world=pivot*CFrame.new(cf.Position*scale)*(cf-cf.Position);if batch then batch:put(p,world)else p.CFrame=world end end)
end
function M.territory(style,ownerColor)
    local model=Instance.new('Model');model.Name='TerritorySeal'
    local fill=ownerColor:Lerp(Color3.fromRGB(34,42,54),.4)
    local land=G.block(model,'Land',Vector3.new(4.8,.1,4.8),CFrame.identity,fill);land.CastShadow=false
    local motif={}
    local function add(name,size,cf,color,glow,phase)
        local p=part(model,'Motif_'..name,size,cf,color,glow);if not glow then p.Material=Enum.Material.SmoothPlastic end
        table.insert(motif,{part=p,home=cf,mode=0,color=color,phase=phase or 1});return p
    end
    local animate=territoryMotif(model,style,fill,add)
    local tier=style.tier or 1
    if tier>=2 then for i=0,3 do local a=i*math.pi/2
        local edge=G.block(model,'Frontier',Vector3.new(4.9,.06,.09),CFrame.Angles(0,a,0)*CFrame.new(0,.08,-2.43),rgb(style.accent));edge.Material=Enum.Material.Neon;edge.CastShadow=false
    end end
    if tier>=3 then for i=0,3 do local a=i*math.pi/2+math.pi/4
        local post=G.block(model,'FrontierPost',Vector3.new(.18,.36,.18),CFrame.Angles(0,a,0)*CFrame.new(0,.2,-3.43),rgb(style.secondary));post.Material=Enum.Material.Metal;post.CastShadow=false
    end end
    model.WorldPivot=CFrame.identity
    local state=M.apply(model,style,'territory',CFrame.new(0,.12,0),1.55)
    if state then
        for _,item in ipairs(motif)do table.insert(state.parts,item)end
        if animate then animators[model]={fn=animate}end
        state.lastPivot=nil;M.step(model,0,true,1)
    end
    return model
end
function M.trailDisplay(style)return require(script.Parent.TrailThemes).display(style)end
return M
