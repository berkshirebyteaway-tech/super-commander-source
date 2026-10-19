local M={}
function M.of(w,h,touch,mapWidth,mapHeight)
    local aspect=mapWidth/math.max(1,mapHeight)
    local mw=math.min(touch and 144 or 192,w*.28)
    local mh=math.min(mw/aspect,touch and math.max(56,h-168)or 120);mw=mh*aspect
    local mini={x=w-mw-20,y=12,w=mw+8,h=mh+8}
    local width=math.min(touch and 260 or 390,w-(touch and 148 or 24))
    local panel={x=touch and w-width-12 or (w-width)/2,y=h-(touch and 88 or 80),w=width,h=touch and 76 or 64}
    return {panel=panel,mini=mini,menu={x=w-56,y=touch and mini.y+mini.h+8 or h-56,w=44,h=44},title={x=12,y=touch and 4 or 6,w=width-24,h=touch and 22 or 25},land={x=width-108,y=touch and 26 or 10,w=96,h=44},hint={x=12,y=touch and 27 or 34,w=width-120,h=touch and 42 or 24}}
end
return M
