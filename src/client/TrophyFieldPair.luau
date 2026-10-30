local K=require(script.Parent.Kit20)
local C=K.colors
local M={}
function M.paint(view,f,x,y,w,h,fmt,elapsed)
    if view.paintSplit then
        local gap=fmt=='pt'and 6 or fmt=='ph'and 5 or 10
        local sp=view:paintSplit(f,fmt,0,w*2+gap,h,elapsed)
        sp.ranked.frame.Visible=false
        K.box(sp.frame,x,y,w,h);K.box(sp.world.frame,0,0,w,h)
        if not view.trophyWorldRow or view.trophyWorldRow.press.button~=sp.frame then
            view.trophyWorldRow={press={button=sp.frame}}
        end
        return sp.frame
    end
    local row=view.trophyWorldRow
    if not row then
        row={};view.trophyWorldRow=row
        row.press=K.button(view.list,'TrophyWorldPair',{kind='out',hit=48},function()view:join('world')end)
        row.plate=K.make('Frame',row.press.face,{Name='Plate',BackgroundColor3=C.accent,BorderSizePixel=0});K.round(row.plate,6)
        row.icon=K.icon(row.plate,'globe',22,C.bg)
        row.title=K.text(row.press.face,'Title','난입전',14,C.ink,800)
        row.value=K.num(row.press.face,'Players','',12,C.muted)
        row.dot=K.make('Frame',row.press.face,{Name='Dot',BackgroundColor3=C.accent,BorderSizePixel=0});K.round(row.dot,'pill')
    end
    local text,on,plain,mine=view:action(f)
    row.press.button.Visible=true;row.press:place(x,y,w,h);row.press:setEnabled(on)
    local size=30;K.box(row.plate,10,math.floor((h-size)/2),size,size);K.box(row.icon,4,4,22,22)
    K.box(row.title,50,math.floor(h/2)-23,w-58,24)
    local n=f.count or 0;local remaining=math.max(0,math.ceil((f.remaining or 0)-elapsed))
    row.value.Text=(not plain and not mine)and text or tostring(n)..'/'..tostring(f.rules.maximum)..(f.remaining and '  '..string.format('%d:%02d',remaining//60,remaining%60)or '')
    row.dot.Visible=n>0;K.box(row.dot,50,math.floor(h/2)+9,5,5);K.box(row.value,n>0 and 61 or 50,math.floor(h/2),w-(n>0 and 69 or 58),24)
    local function depth(o,z)if o.ZIndex~=z then o.ZIndex=z end;for _,c in ipairs(o:GetChildren())do if c:IsA('GuiObject')then depth(c,z+1)end end end
    depth(row.press.button,3)
    return row.press.button
end
return M
