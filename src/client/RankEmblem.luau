local UI=require(script.Parent.ToyUI)
local M={}
local order={bronze=1,silver=2,gold=3,platinum=4,diamond=5,master=6,legend=7,unranked=0}
M.colors={
    unranked=Color3.fromRGB(96,108,124),bronze=Color3.fromRGB(176,112,72),silver=Color3.fromRGB(176,188,204),gold=Color3.fromRGB(232,184,72),
    platinum=Color3.fromRGB(88,206,196),diamond=Color3.fromRGB(110,150,255),master=Color3.fromRGB(196,110,255),legend=Color3.fromRGB(255,214,120),
}
function M.color(tier)return M.colors[tier]or M.colors.unranked end
local function lift(c,k)return c:Lerp(Color3.new(1,1,1),k)end
local function sink(c,k)return c:Lerp(Color3.new(0,0,0),k)end
local function diamond(parent,name,size,cx,cy,color,alpha,z)
    local f=UI.make('Frame',parent,{Name=name,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(cx,cy),Size=UDim2.fromOffset(size,size),Rotation=45,
        BackgroundColor3=color,BackgroundTransparency=alpha or 0,BorderSizePixel=0,ZIndex=z or 1})
    UI.make('UICorner',f,{CornerRadius=UDim.new(0,math.max(2,size//10))})
    return f
end
local function gradient(f,a,b,rotation)
    return UI.make('UIGradient',f,{Color=ColorSequence.new(a,b),Rotation=rotation or 90})
end
function M.create(parent,name,size,tier,division)
    local root=UI.make('Frame',parent,{Name=name or 'RankEmblem',BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromOffset(size,size)})
    root:SetAttribute('Tier',tier or 'unranked')
    local lv=order[tier]or 0;local c=M.color(tier);local mid=size/2;local z=root.ZIndex
    if lv>=3 then
        local halo=diamond(root,'Halo',size*.78,mid,mid,c,.72,z);gradient(halo,lift(c,.3),c,0)
    end
    if lv>=4 then
        for i,dx in ipairs({-1,1})do local wing=diamond(root,'Wing'..i,size*.28,mid+dx*size*.36,mid+size*.04,lift(c,.15),.05,z+1);gradient(wing,lift(c,.45),sink(c,.25),dx*45+90)end
    end
    if lv>=6 then
        for i,dx in ipairs({-.2,0,.2})do local p=diamond(root,'Crown'..i,size*(dx==0 and .2 or .15),mid+dx*size,mid-size*.38+(dx==0 and 0 or size*.04),lift(c,.35),0,z+1);gradient(p,Color3.new(1,1,1),c,90)end
    end
    local body=diamond(root,'Body',size*.6,mid,mid+size*.03,c,0,z+2);gradient(body,lift(c,.35),sink(c,.35),135)
    UI.make('UIStroke',body,{Color=lift(c,.55),Thickness=math.max(1,size//32),Transparency=lv==0 and .5 or .1})
    if lv>=2 then
        local facet=diamond(root,'Facet',size*.4,mid,mid+size*.03,sink(c,.15),0,z+3);gradient(facet,sink(c,.05),sink(c,.45),315)
    end
    if lv>=5 then
        local shine=diamond(root,'Shine',size*.16,mid-size*.12,mid-size*.1,Color3.new(1,1,1),.35,z+4)
    end
    if lv>=7 then
        local g=body:FindFirstChildOfClass('UIGradient')
        g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,236,170)),ColorSequenceKeypoint.new(.35,Color3.fromRGB(255,150,210)),ColorSequenceKeypoint.new(.7,Color3.fromRGB(140,200,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,214,120))})
    end
    local label=UI.make('TextLabel',root,{Name='Division',BackgroundTransparency=1,Text=division or (lv==0 and '?' or ''),TextColor3=Color3.new(1,1,1),TextStrokeTransparency=.55,
        Font=Enum.Font.BuilderSansBold,TextSize=math.max(10,math.floor(size*.24)),Size=UDim2.fromScale(1,1),Position=UDim2.fromOffset(0,size*.03),ZIndex=z+5})
    UI.display(label,true);label.AutoLocalize=false
    return root
end
return M
