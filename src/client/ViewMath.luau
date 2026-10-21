local M={}
function M.avoidRect(x,y,halfW,halfH,minX,maxX,minY,maxY,rect)
    x=math.clamp(x,minX,maxX);y=math.clamp(y,minY,maxY)
    local function clear(cx,cy)
        return cx+halfW<=rect.x-8 or cx-halfW>=rect.x+rect.w+8
            or cy+halfH<=rect.y-8 or cy-halfH>=rect.y+rect.h+8
    end
    if clear(x,y)then return x,y,true end
    local best,dist=nil,math.huge
    for _,p in ipairs({{rect.x-halfW-8,y},{rect.x+rect.w+halfW+8,y},{x,rect.y-halfH-8},{x,rect.y+rect.h+halfH+8}})do
        if p[1]>=minX and p[1]<=maxX and p[2]>=minY and p[2]<=maxY and clear(p[1],p[2])then
            local d=(p[1]-x)^2+(p[2]-y)^2;if d<dist then best=p;dist=d end
        end
    end
    if best then return best[1],best[2],true end
    return x,y,false
end
function M.contextRect(w,h,x,y,sw,sh,touch,bottom)
    local left=touch and x-sw/2 or x+18
    if left+sw>w-12 then left=x-sw-18 end
    local top=touch and y-sh-24 or y-40
    local maxTop=math.max(8,h-(bottom or 0)-sh-12)
    local minTop=math.min(64,maxTop)
    left=math.clamp(left,12,math.max(12,w-sw-12))
    top=math.clamp(top,minTop,maxTop)
    if touch and y>=top-16 and y<=top+sh+16 then
        if x-sw-24>=12 then left=x-sw-24
        elseif x+sw+24<=w-12 then left=x+24
        elseif y+24<=maxTop then top=y+24 end
    end
    if touch and left<152 and top+sh>h-180 then
        if w>=sw+176 then left=math.max(left,164)
        elseif h>=sh+254 then top=math.min(top,h-190-sh) end
    end
    return left,top
end
function M.dockLayout(w,h,touch)
    if touch then
        local short=h<400;local width=short and math.min(560,w-136)or math.min(460,w-16)
        local mainX=not short and w<500 and 124 or 0
        return {width=width,height=short and 96 or 144,stacked=not short,x=w-width-8,mainX=mainX}
    end
    local stacked=w<500
    local width=stacked and math.min(w-24,340,math.max(232,w-(touch and 146 or 24))) or math.min(touch and 520 or 560,w-(touch and 160 or 24))
    return {width=width,height=touch and (stacked and 170 or 122) or (stacked and 158 or 112),stacked=stacked,x=touch and w-width-12 or 12}
end
function M.portraitHUD(width,expanded)
    local offset=expanded and 100 or 0
    local pad=8;local row=44;local buildW=48
    local start=pad+buildW+6
    local goldW=62;local goldX=width-pad-goldW
    local rateW=88;local rateX=goldX-6-rateW
    local y1=offset+6;local y2=y1+row+6
    return {height=y2+48+6,offset=offset,menuInside=false,
        growth={x=rateX,y=y1,w=rateW,h=48},
        gold={x=goldX,y=y1,w=goldW,h=row},
        troops={x=start,y=y1+2,w=rateX-6-start,h=row-4},
        amount={x=pad,y=y2,w=40,h=48},
        slider={x=pad+44,y=y2,w=width-pad*2-44,h=48},
        surface=y2+48+2-offset,
        grid={x=pad,y=y1,w=0,h=0},
        palette={x=pad,y=expanded and 4 or y1,w=expanded and width-pad*2 or buildW,h=expanded and 92 or row}}
end
function M.placeLabel(x,y,w,h,width,height,blocks)
    local hw,hh=w/2,h/2;local candidates={{x,y},{hw+4,hh+4},{width-hw-4,hh+4},{hw+4,height-hh-4},{width-hw-4,height-hh-4}}
    for _,r in ipairs(blocks)do
        table.insert(candidates,{x,r.y-hh-8});table.insert(candidates,{x,r.y+r.h+hh+8})
        table.insert(candidates,{r.x-hw-8,y});table.insert(candidates,{r.x+r.w+hw+8,y})
    end
    local bestX,bestY,bestScore,bestArea=x,y,math.huge,math.huge
    for _,p in ipairs(candidates)do
        local cx=math.clamp(p[1],hw+4,math.max(hw+4,width-hw-4))
        local cy=math.clamp(p[2],hh+4,math.max(hh+4,height-hh-4));local area=0
        for _,r in ipairs(blocks)do
            area+=math.max(0,math.min(cx+hw,r.x+r.w+4)-math.max(cx-hw,r.x-4))*math.max(0,math.min(cy+hh,r.y+r.h+4)-math.max(cy-hh,r.y-4))
        end
        local score=(cx-x)^2+(cy-y)^2
        if area<bestArea or area==bestArea and score<bestScore then bestX,bestY,bestScore,bestArea=cx,cy,score,area end
    end
    return bestX,bestY,bestArea==0
end
function M.actionGuide(x,y,width,operationWidth,operationHeight)
    local side=width-operationWidth-6>=200
    local guideWidth=side and width-operationWidth-6 or width
    return {x=x+(side and operationWidth+6 or 0),y=math.max(8,y-50),width=guideWidth,
        operationsY=math.max(8,y-operationHeight-(side and 6 or 56))}
end
function M.dispatchFraction(x,width)
    return math.clamp(math.floor(math.clamp(x/math.max(1,width),0,1)*99+1+.5),1,100)/100
end
function M.layout(width,height)
    local compact=width<600
    local short=height<500
    return {compact=compact,short=short,margin=compact and 12 or 24,
        header=short and 52 or 76,bottom=short and 72 or 92,
        panelWidth=math.min(336,width-24),buttonHeight=44}
end
function M.fit(width,height,aspect)
    local w=math.max(width,height*aspect)
    return {x=(width-w)/2,y=(height-w/aspect)/2,w=w,h=w/aspect}
end
function M.clamp(v,width,height,aspect)
    v.w=math.clamp(v.w,math.min(40,width),math.max(width,height*aspect))
    v.h=v.w/aspect
    v.x=math.clamp(v.x,-math.max(0,(v.w-width)/2),math.max(0,width-v.w))
    v.y=math.clamp(v.y,-math.max(0,(v.h-height)/2),math.max(0,height-v.h))
end
function M.zoom(v,factor,u,vv,width,height,aspect)
    local x,y=v.x+u*v.w,v.y+vv*v.h
    v.w*=factor;M.clamp(v,width,height,aspect)
    v.x=x-u*v.w;v.y=y-vv*v.h;M.clamp(v,width,height,aspect)
end
function M.tileAt(v,u,vv,width,height)
    if u<0 or vv<0 or u>=1 or vv>=1 then return nil end
    local x,y=math.floor(v.x+u*v.w),math.floor(v.y+vv*v.h)
    if x<0 or y<0 or x>=width or y>=height then return nil end
    return y*width+x
end
function M.ownerBoundary(owners,tile,width,height)
    local id=owners[tile];if not id or id==0 then return false end
    local x=tile%width
    return (x==0 or owners[tile-1]~=id) or (x==width-1 or owners[tile+1]~=id)
        or (tile<width or owners[tile-width]~=id) or (tile>=(height-1)*width or owners[tile+width]~=id)
end
function M.applyOwnership(owners,revision,s)
    if (s.ownershipRevision or 0)<revision then return revision,true end
    if s.owned then
        table.clear(owners);for _,t in ipairs(s.owned) do owners[t]=1 end
        for _,p in ipairs(s.factions or {}) do for _,t in ipairs(p.owned or {}) do owners[t]=p.id end end
        return s.ownershipRevision or 0,true
    end
    if (s.ownershipRevision or 0)<=revision then return revision,true end
    if s.baseRevision~=revision then return revision,false end
    for _,c in ipairs(s.captured or {}) do owners[c[1]]=c[2]~=0 and c[2] or nil end
    return s.ownershipRevision,true
end
return M
