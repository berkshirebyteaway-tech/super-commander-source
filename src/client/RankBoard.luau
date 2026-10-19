local UI=require(script.Parent.ToyUI)
local Emblem=require(script.Parent.RankEmblem)
local Theme=require(script.Parent.Theme)
local M={}
local C=UI.colors
local podium={Color3.fromRGB(245,196,81),Color3.fromRGB(206,216,228),Color3.fromRGB(214,146,92)}
local function skip(o)o.AutoLocalize=false;o:SetAttribute('LocalizationSkip',true);return o end
function M.row(parent,r,x,y,w,h)
    local mine=r.self==true
    local line=UI.panel(parent,'Row'..tostring(r.rank or 0));line.BackgroundColor3=mine and C.raised or C.panel;line.BackgroundTransparency=mine and 0 or .25;UI.box(line,x,y,w,h)
    local stroke=line:FindFirstChildOfClass('UIStroke');if mine then stroke.Color=C.accent;stroke.Thickness=1.5 end
    local top=r.rank and podium[r.rank]
    if top then UI.make('Frame',line,{Name='Podium',BackgroundColor3=top,BorderSizePixel=0,Size=UDim2.new(0,3,1,0)})end
    local n=skip(UI.label(line,'Rank',r.rank and tostring(r.rank)or '—',r.rank and r.rank<=3 and 20 or 16,top or C.muted));UI.display(n,true)
    n.TextXAlignment=Enum.TextXAlignment.Center;UI.box(n,8,0,36,h)
    local left=50
    if r.userId and tonumber(r.userId)and tonumber(r.userId)>0 then
        local face=UI.make('ImageLabel',line,{Name='Avatar',BackgroundColor3=C.bg,BorderSizePixel=0,Image='rbxthumb://type=AvatarHeadShot&id='..tostring(r.userId)..'&w=150&h=150'})
        UI.corner(face,40);UI.box(face,left,6,h-12,h-12);left+=h-4
    end
    if r.tier then local e=Emblem.create(line,'Emblem',h-12,r.tier,nil);UI.box(e,left,6,h-12,h-12);left+=h-4 end
    local valueW=math.min(130,math.floor(w*.3))
    local name=skip(UI.label(line,'Name',r.name or '지휘관',15,mine and C.accent or C.ink));name.TextWrapped=false;name.TextTruncate=Enum.TextTruncate.AtEnd
    UI.box(name,left,r.sub and 4 or 0,w-left-valueW-12,r.sub and h*.55 or h)
    if r.sub then local s=skip(UI.label(line,'Sub',r.sub,12,C.muted));s.TextWrapped=false;s.TextTruncate=Enum.TextTruncate.AtEnd;UI.box(s,left,h*.52,w-left-valueW-12,h*.42)end
    local v=UI.label(line,'Value',r.valueLabel or Theme.commas(r.value or 0)..' RP',15,top or C.ink)
    v.TextXAlignment=Enum.TextXAlignment.Right;v.TextWrapped=false;UI.display(v,true);UI.box(v,w-valueW-12,0,valueW,h)
    return line
end
function M.draw(parent,box,rows,opts)
    opts=opts or {};local h=opts.rowHeight or 44;local y=box.y
    if #rows==0 then
        local e=UI.label(parent,'BoardEmpty',opts.empty or '아직 순위에 오른 지휘관이 없어요',14,C.muted);e.TextXAlignment=Enum.TextXAlignment.Center;UI.box(e,box.x,y,box.w,48);y+=56
    else
        for _,r in ipairs(rows)do M.row(parent,r,box.x,y,box.w,h);y+=h+6 end
    end
    if opts.me then
        local sep=UI.make('Frame',parent,{Name='MeGap',BackgroundColor3=C.line,BorderSizePixel=0});UI.box(sep,box.x+12,y+2,box.w-24,1);y+=10
        M.row(parent,opts.me,box.x,y,box.w,h);y+=h+6
    end
    return y-box.y
end
return M
