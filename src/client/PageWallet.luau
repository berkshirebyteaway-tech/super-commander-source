local UI=require(script.Parent.ToyUI)
local Icons=require(script.Parent.OutgameIcons)
local M={}
function M.clear(hub)if hub.pageWallet then hub.pageWallet:Destroy();hub.pageWallet=nil end end
function M.show(hub,entries)
    M.clear(hub)
    local card=hub.pageCard;local pw=card.Size.X.Offset
    local frame=UI.make('Frame',card,{Name='PageWallet',BackgroundTransparency=1});hub.pageWallet=frame
    local x=0;local widths={}
    for i,e in ipairs(entries)do widths[i]=math.max(84,28+#UI.number(e.value)*9+18)end
    local total=0;for _,w in ipairs(widths)do total+=w+6 end
    UI.box(frame,pw-62-total,10,total,38)
    for i,e in ipairs(entries)do
        local chip=UI.corner(UI.make('Frame',frame,{Name='Wallet_'..(e.name or e.icon),BackgroundColor3=UI.colors.bg,BackgroundTransparency=.15,BorderSizePixel=0}),19)
        UI.stroke(chip,(e.color or UI.colors.gold):Lerp(UI.colors.line,.45),1);UI.box(chip,x,0,widths[i],38)
        UI.box(Icons.create(chip,e.icon,20,e.color or UI.colors.gold),10,9,20,20)
        local v=UI.label(chip,'Value',UI.number(e.value),16,e.color or UI.colors.gold);UI.box(v,34,0,widths[i]-42,38);v.TextWrapped=false
        x+=widths[i]+6
    end
    local title=hub.pageTitle;if title then title.Size=UDim2.fromOffset(math.max(120,pw-62-total-title.Position.X.Offset-8),title.Size.Y.Offset)end
    return frame
end
return M
