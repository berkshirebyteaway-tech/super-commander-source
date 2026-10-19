local UI=require(script.Parent.Theme)
local M={}
local GOLD=UI.colors.gold;local ICE=UI.colors.ice
function M.create(parent,height)
    local h=height or 18
    local root=UI.make('Frame',parent,{Name='BenefitBadge',Size=UDim2.fromOffset(h,h),BackgroundTransparency=1,Visible=false})
    local gem=UI.make('Frame',root,{Name='Permanent',Size=UDim2.fromOffset(h,h),BackgroundTransparency=1})
    local s=math.floor(h*.66+.5)
    local shield=UI.make('Frame',gem,{Name='Gem',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(s,s),Rotation=45,BackgroundColor3=GOLD,BorderSizePixel=0})
    UI.corner(shield,2);UI.stroke(shield,GOLD:Lerp(Color3.new(1,1,1),.45),1)
    UI.make('UIGradient',shield,{Rotation=-45,Color=ColorSequence.new(GOLD:Lerp(Color3.new(1,1,1),.35),GOLD:Lerp(Color3.new(),.18))})
    local c=math.max(3,math.floor(h*.24+.5))
    local cut=UI.make('Frame',gem,{Name='Star',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(c,c),Rotation=45,BackgroundColor3=UI.colors.bg,BorderSizePixel=0})
    local pw=math.floor(h*1.9+.5)
    local pill=UI.make('TextLabel',root,{Name='Club',Size=UDim2.fromOffset(pw,h),BackgroundColor3=ICE,BorderSizePixel=0,Text='VIP',TextColor3=UI.colors.bg,
        Font=Enum.Font.BuilderSansExtraBold,TextSize=math.max(9,math.floor(h*.62)),TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center})
    pill:SetAttribute('LocalizationSkip',true);UI.corner(pill,99)
    return {root=root,shield=shield,star=cut,ring=pill,gem=gem,height=h,pillWidth=pw}
end
function M.width(v)return v.root.Visible and v.root.Size.X.Offset or 0 end
function M.update(v,permanent,club)
    local key=(permanent==true and 1 or 0)+(club==true and 2 or 0)
    if v.key==key then return end;v.key=key
    v.root.Visible=key>0;v.gem.Visible=permanent==true;v.ring.Visible=club==true
    local x=permanent==true and v.height+3 or 0
    v.ring.Position=UDim2.fromOffset(x,0)
    v.root.Size=UDim2.fromOffset(math.max(1,(club==true and x+v.pillWidth or x-3)),v.height)
    v.root:SetAttribute('BenefitKind',key==3 and 'both'or key==2 and 'club'or key==1 and 'permanent'or 'none')
end
function M.caption(permanent,club)
    if permanent and club then return '커맨더 프라임과 VIP 클럽'end
    return permanent and '커맨더 프라임'or club and 'VIP 클럽'or ''
end
return M
