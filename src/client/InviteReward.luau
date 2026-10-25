local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.OutgameIcons)
local M={}
local function commas(n)local s=tostring(math.floor(n or 0));local out=s:reverse():gsub('(%d%d%d)','%1,'):reverse();return (out:gsub('^,',''))end
function M.draw(parent,progress,w,y)
    local c=progress and progress.career;if not c or not c.recruitMedals then return y end
    local card=UI.panel(parent,'InviteReward');UI.box(card,2,y,w-10,60)
    local edge=card:FindFirstChildOfClass('UIStroke');if edge then edge.Color=UI.colors.gold;edge.Transparency=.5 end
    local cells={{'친구 초대',c.recruitMedals},{'같이 하기 매일',c.comradeMedals or 0},{'초대한 친구',nil,string.format('%d / %d',c.recruits or 0,c.recruitCap or 0)}}
    local cw=(w-10-24)/3
    for i,cell in ipairs(cells)do
        local x=12+(i-1)*cw
        local cap=UI.label(card,'Caption'..i,cell[1],12,UI.colors.muted);UI.box(cap,x,6,cw-6,20);cap.TextWrapped=false;cap.TextTruncate=Enum.TextTruncate.AtEnd
        local vx=x
        if cell[2]then local coin=Icons.create(card,'coin',18,UI.colors.gold);coin.Name='Coin'..i;UI.box(coin,x,30,18,18);if Icons.available(coin)then vx=x+22 else coin.Visible=false end end
        local text=cell[2]and (Icons.available(card:FindFirstChild('Coin'..i))and commas(cell[2])or string.format('+%s 코인',commas(cell[2])))or cell[3]
        local value=UI.label(card,'Value'..i,text,17,cell[2]and UI.colors.gold or UI.colors.ink);UI.box(value,vx,27,cw-(vx-x)-6,26);value.TextWrapped=false
        value.Font=Enum.Font.BuilderSansExtraBold;value.TextScaled=true;UI.make('UITextSizeConstraint',value,{MaxTextSize=17,MinTextSize=11});value:SetAttribute('LocalizationSkip',cell[2]~=nil and Icons.available(card:FindFirstChild('Coin'..i)))
    end
    return y+68
end
return M
