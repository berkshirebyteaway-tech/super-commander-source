local TextService=game:GetService("TextService")
local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.OutgameIcons)
local M={}
M.height=20
function M.vip()return 'VIP',UI.colors.vip end
function M.level(level)return string.format('Lv.%d',level),UI.colors.muted end
function M.width(text)return TextService:GetTextSize(text,11,Enum.Font.BuilderSansBold,Vector2.new(400,40)).X+30 end
function M.create(parent,text,color,x,y)
    local w=M.width(text)
    local chip=UI.make('Frame',parent,{Name='Lock',BackgroundColor3=UI.colors.bg,BackgroundTransparency=.15,BorderSizePixel=0});UI.corner(chip,3)
    UI.box(chip,x,y,w,M.height);UI.stroke(chip,color,1).Transparency=.55
    local lock=Icons.create(chip,'lock',12,color);UI.box(lock,7,4,12,12)
    local tag=UI.label(chip,'Text',text,11,color);tag.TextWrapped=false;tag:SetAttribute('LocalizationSkip',true);UI.box(tag,23,0,w-26,M.height)
    return chip
end
return M
