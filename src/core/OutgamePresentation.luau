local M={side=14,top=6,bottom=8,scrollbar=6,goalTabs=60}
function M.width(absoluteWidth,scale,side)return math.max(1,absoluteWidth/scale-(side or M.side)*2-M.scrollbar)end
function M.inset(page)return (page=='shop'or page=='wardrobe')and M.side or 16 end
function M.nameScale(distance)return math.clamp(32/math.max(32,distance),.5,1)end
return M
