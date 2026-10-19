local UI=require(script.Parent.ToyUI)
local Tween=game:GetService('TweenService')
local M={}
local WHITE=Color3.new(1,1,1)
local function play(o,t,style,goal,info)
    local ok,tw=pcall(function()return Tween:Create(o,info or TweenInfo.new(t,style or Enum.EasingStyle.Quad,Enum.EasingDirection.Out),goal)end)
    if ok and tw then tw:Play()end
end
function M.create(parent,color,size)
    size=size or 18
    local gap=math.floor(size*.42+.5);local cell=math.floor(size*.74+.5);local pad=math.floor(size*.55+.5)
    local arrow=math.floor(size*.7);local ticketW=math.floor(size*1.5);local ticketH=math.floor(size*.92)
    local w=pad+5*size+4*gap+arrow+ticketW+pad;local h=size+math.floor(size*.62)
    local root=UI.corner(UI.make('CanvasGroup',parent,{Name='ShardGauge',BackgroundColor3=UI.colors.bg,BackgroundTransparency=.08,BorderSizePixel=0,Size=UDim2.fromOffset(w,h)}),99)
    UI.make('UIGradient',root,{Rotation=90,Color=ColorSequence.new(color:Lerp(UI.colors.bg,.72),UI.colors.bg:Lerp(Color3.new(),.35))})
    UI.stroke(root,color:Lerp(UI.colors.line,.35),1)
    local x0=pad+size/2
    local rail=UI.corner(UI.make('Frame',root,{Name='Rail',AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,x0,.5,0),Size=UDim2.fromOffset(4*(size+gap),math.max(2,math.floor(size*.16))),BackgroundColor3=color,BackgroundTransparency=.82,BorderSizePixel=0}),99)
    local fill=UI.corner(UI.make('Frame',rail,{Name='Fill',BackgroundColor3=WHITE,BorderSizePixel=0,Size=UDim2.fromScale(0,1)}),99)
    UI.make('UIGradient',fill,{Color=ColorSequence.new(color,color:Lerp(WHITE,.55))})
    local cells={}
    for i=1,5 do
        local cx=x0+(i-1)*(size+gap)
        local halo=UI.make('Frame',root,{Name='Halo'..i,AnchorPoint=Vector2.new(.5,.5),Rotation=45,Position=UDim2.new(0,cx,.5,0),Size=UDim2.fromOffset(cell+math.floor(size*.42),cell+math.floor(size*.42)),BackgroundColor3=color,BackgroundTransparency=1,BorderSizePixel=0})
        UI.corner(halo,math.max(2,math.floor(size*.12)))
        local slot=UI.make('Frame',root,{Name='Cell'..i,AnchorPoint=Vector2.new(.5,.5),Rotation=45,Position=UDim2.new(0,cx,.5,0),Size=UDim2.fromOffset(cell,cell),BackgroundColor3=UI.colors.bg,BorderSizePixel=0})
        UI.corner(slot,2)
        local edge=UI.stroke(slot,color:Lerp(UI.colors.line,.45),1.5)
        local core=UI.make('Frame',slot,{Name='Crystal',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromScale(0,0),BackgroundColor3=WHITE,BorderSizePixel=0})
        UI.make('UIGradient',core,{Rotation=45,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,color:Lerp(WHITE,.7)),ColorSequenceKeypoint.new(.49,color:Lerp(WHITE,.25)),ColorSequenceKeypoint.new(.51,color),ColorSequenceKeypoint.new(1,color:Lerp(Color3.new(),.35))})})
        local glint=UI.make('Frame',core,{Name='Glint',Position=UDim2.fromScale(.16,.16),Size=UDim2.fromScale(.26,.26),BackgroundColor3=WHITE,BackgroundTransparency=.1,BorderSizePixel=0})
        cells[i]={slot=slot,core=core,edge=edge,glint=glint,halo=halo}
    end
    local chevron=UI.make('TextLabel',root,{Name='Arrow',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(0,x0+4*(size+gap)+size/2+arrow/2,.5,-1),Size=UDim2.fromOffset(arrow,h),BackgroundTransparency=1,
        Text='›',Font=Enum.Font.BuilderSansBold,TextSize=math.floor(size*1.05),TextColor3=color:Lerp(UI.colors.line,.4),AutoLocalize=false})
    local tx=x0+4*(size+gap)+size/2+arrow
    local ticket=UI.corner(UI.make('Frame',root,{Name='Ticket',AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,tx,.5,0),Size=UDim2.fromOffset(ticketW,ticketH),BackgroundColor3=UI.colors.bg,BorderSizePixel=0}),3)
    local tedge=UI.stroke(ticket,color:Lerp(UI.colors.line,.3),1.5)
    local notch=math.max(4,math.floor(ticketH*.36))
    for _,ax in ipairs({0,1})do
        UI.corner(UI.make('Frame',ticket,{Name='Notch',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(ax,.5),Size=UDim2.fromOffset(notch,notch),BackgroundColor3=UI.colors.bg,BorderSizePixel=0,ZIndex=2}),99)
    end
    local stripe=UI.make('Frame',ticket,{Name='Stripe',AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.66,0,0,2),Size=UDim2.new(0,1,1,-4),BackgroundColor3=color,BackgroundTransparency=.2,BorderSizePixel=0})
    local star=UI.make('Frame',ticket,{Name='Star',AnchorPoint=Vector2.new(.5,.5),Rotation=45,Position=UDim2.fromScale(.34,.5),Size=UDim2.fromOffset(math.floor(ticketH*.34),math.floor(ticketH*.34)),BackgroundColor3=color:Lerp(UI.colors.line,.3),BorderSizePixel=0})
    return {root=root,cells=cells,fill=fill,ticket=ticket,ticketEdge=tedge,stripe=stripe,star=star,chevron=chevron,color=color,count=-1,width=w,height=h}
end
function M.set(v,n,animate)
    n=math.clamp(math.floor(n),0,5)
    local color=v.color
    for i,c in ipairs(v.cells)do
        local on=i<=n
        if animate and on and i>v.count then
            c.core.Size=UDim2.fromScale(1.8,1.8);play(c.core,.34,Enum.EasingStyle.Back,{Size=UDim2.fromScale(.78,.78)})
            c.halo.BackgroundTransparency=.2;play(c.halo,.6,nil,{BackgroundTransparency=.78})
        else c.core.Size=on and UDim2.fromScale(.78,.78)or UDim2.fromScale(0,0);c.halo.BackgroundTransparency=on and .78 or 1 end
        c.slot.BackgroundColor3=on and color:Lerp(UI.colors.bg,.55)or UI.colors.bg
        c.edge.Color=on and color:Lerp(WHITE,.5)or color:Lerp(UI.colors.line,.45)
        local nextSlot=i==n+1
        c.edge.Transparency=0
        if nextSlot then play(c.edge,.9,nil,{Transparency=.65},TweenInfo.new(.9,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true))
        else play(c.edge,.01,nil,{Transparency=0})end
    end
    local f=n<=1 and 0 or (n-1)/4
    if animate then play(v.fill,.3,nil,{Size=UDim2.fromScale(f,1)})else v.fill.Size=UDim2.fromScale(f,1)end
    local full=n>=5
    if not full then v.ticketEdge.Transparency=0;play(v.ticketEdge,.01,nil,{Transparency=0})end
    v.ticket.BackgroundColor3=full and color or UI.colors.bg;v.ticketEdge.Color=full and color:Lerp(WHITE,.6)or color:Lerp(UI.colors.line,.3)
    v.star.BackgroundColor3=full and WHITE or color:Lerp(UI.colors.line,.3);v.stripe.BackgroundColor3=full and WHITE or color
    v.chevron.TextColor3=full and color:Lerp(WHITE,.4)or color:Lerp(UI.colors.line,.4)
    if animate and full and v.count<5 then
        local s=v.ticket.Size;v.ticket.Size=UDim2.fromOffset(s.X.Offset*1.4,s.Y.Offset*1.4)
        play(v.ticket,.4,Enum.EasingStyle.Back,{Size=s})
        play(v.ticketEdge,.7,nil,{Transparency=.5},TweenInfo.new(.7,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true))
    end
    v.count=n
end
function M.cellCenter(v,i)local s=v.cells[math.clamp(i,1,5)].slot;return s.AbsolutePosition+s.AbsoluteSize/2 end
return M
