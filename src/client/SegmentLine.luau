local TextService=game:GetService('TextService')
local UI=require(script.Parent.ToyUI)
local L=require(script.Parent.Localization)
local M={}
M.GAP=10
local chipWords={['개인전']=true,['팀전']=true,['협동']=true,['커스텀']=true,['특수']=true,['공식']=true}
local function split(s)
    local out={};for piece in (s..' / '):gmatch('(.-) / ')do if piece~=''then table.insert(out,piece)end end;return out
end
function M.apply(label,text,transparency,right)
    local holder=label:FindFirstChild('Segments')
    local pieces=split(text or '')
    if #pieces<2 then if holder then holder.Visible=false end;label.Text=text or '';return false end
    if not holder then holder=UI.make('Frame',label,{Name='Segments',BackgroundTransparency=1,Size=UDim2.fromScale(1,1)})end
    holder.Visible=true;label.Text=''
    local scale=require(script.Parent.Theme).scale
    local w=label.AbsoluteSize.X/scale;local h=label.AbsoluteSize.Y/scale;local size=label.TextSize;local color=label.TextColor3
    if w<1 then w=400 end
    local x=0;local full=false
    for i=1,math.max(#pieces,#holder:GetChildren())do
        local o=holder:FindFirstChild('Piece'..i);local p=pieces[i]
        if p then
            local chip=chipWords[p]==true;local bold=i==1 or chip
            local font=bold and Enum.Font.BuilderSansBold or Enum.Font.BuilderSansMedium
            local pw=TextService:GetTextSize(L.text(p),size,font,Vector2.new(1000,h)).X+(chip and 12 or 2)
            if not o then o=UI.label(holder,'Piece'..i,'',size,color);o.TextWrapped=false;UI.corner(o,3)end
            o.Text=p;o.Font=font;o.TextSize=size;o.TextColor3=color;o.TextTransparency=transparency or 0
            o.TextXAlignment=chip and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
            o.BackgroundColor3=color;o.BackgroundTransparency=chip and .85 or 1
            local fits=not full and x+pw<=w;full=not fits
            o.Visible=fits;if fits then UI.box(o,x,chip and math.max(0,(h-(size+6))/2)or 0,pw,chip and size+6 or h)end
            if fits then x+=pw+M.GAP end
        elseif o then o.Visible=false end
    end
    if right then
        local shift=math.max(0,w-(x-M.GAP))
        for _,o in ipairs(holder:GetChildren())do if o:IsA('GuiObject')and o.Visible then o.Position+=UDim2.fromOffset(shift,0)end end
    end
    return true
end
return M
