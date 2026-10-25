local UI=require(script.Parent.ToyUI)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local Raster=require(script.Parent.RasterMap)
local M={}
local function step(c,result)local S=require(script.Parent.TelemetryStep);S.step('lobby','confirm',{item=S.code(c.back),result=result})end
local function v2()local ok,on=pcall(function()return require(script.Parent.Lobby20).ENABLED end);return ok and on==true end
function M.window(lobby,o)
    local K=require(script.Parent.Kit20);local Pop=require(script.Parent.Pop20);local Theme=require(script.Parent.Theme)
    local C=K.colors
    local sc=Theme.scale or 1;local W,H=lobby.root.AbsoluteSize.X/sc,lobby.root.AbsoluteSize.Y/sc
    local fmt=require(script.Parent.Lobby20).format(W,H)
    local pad=fmt=='pc'and 20 or 16;local w=fmt=='pt'and K.even(W-32)or fmt=='ph'and 340 or 380
    local iw=math.min(w,W-24)-pad*2
    local lineFs=14;local lineH=0
    if o.line and o.line~=''then
        local n=0;for part in (o.line..'\n'):gmatch('(.-)\n')do n+=math.max(1,math.ceil(K.width(part,lineFs)/math.max(1,iw)))end
        lineH=n*19
    end
    local mapH=o.map and(fmt=='pc'and 150 or 110)or 0
    local bh=fmt=='ph'and 44 or 48;local fs=fmt=='ph'and 16 or 17
    local h=pad+26+(mapH>0 and 12+mapH or 0)+(lineH>0 and 8+lineH or 0)+20+bh+pad
    local decided=false
    Pop.sheet(lobby.page or 'confirm','Confirm20',w,h,function(p,close,pw)
        local y=pad
        local t=K.text(p,'Title',o.title or '',20,C.ink,800);K.box(t,pad,y,pw-pad*2,26);y+=26
        if mapH>0 then y+=12;local m=K.map(p,'MapPreview',o.map,pw-pad*2,mapH,8);m.Position=UDim2.fromOffset(pad,y);y+=mapH end
        if lineH>0 then
            y+=8
            local d=K.text(p,'Description',o.line,lineFs,C.muted,600);d.TextWrapped=true;d.TextTruncate=Enum.TextTruncate.None;d.TextYAlignment=Enum.TextYAlignment.Top
            K.box(d,pad,y,pw-pad*2,lineH);y+=lineH
        end
        y+=20
        local function go(b)
            if decided then return end;decided=true;K.confirm(b,true);if o.accepted then o.accepted()end;close();o.callback()
        end
        if o.cancel==false then
            local a=K.button(p,'Confirm',{kind='pri',text=o.label,size=fs},go);a:place(pad,y,pw-pad*2,bh)
        else
            local bw=math.floor((pw-pad*2-10)/2)
            local b=K.button(p,'Cancel',{kind='plain',text=o.cancel or '취소',size=fs},function()
                if decided then return end;decided=true;close();if o.onCancel then o.onCancel()end end)
            b:place(pad,y,bw,bh)
            local a=K.button(p,'Confirm',{kind='pri',text=o.label,size=fs},go);a:place(pad+bw+10,y,pw-pad*2-bw-10,bh)
        end
    end,function()
        if not decided then decided=true;if o.dismissed then o.dismissed()end end
    end)
end
function M.open(lobby,title,description,confirm,callback,back,map)
    if v2()then
        local c={back=back or lobby.page};lobby.confirmation=nil
        M.window(lobby,{title=title,line=description,label=confirm,map=map,callback=callback,
            accepted=function()step(c,'accepted')end,dismissed=function()step(c,'cancelled')end,
            onCancel=function()step(c,'cancelled');if c.back and c.back~=lobby.page then lobby:openPage(c.back)end end})
        return
    end
    lobby.confirmation={title=title,description=description,label=confirm,callback=callback,back=back or lobby.page,map=map}
    lobby:openPage('confirm')
end
function M.draw(lobby,body,w)
    local c=lobby.confirmation;if not c then lobby:closePage();return end
    lobby.pageTitle.Text=c.title;local y=0
    local view=body.Size.Y.Offset>0 and body.Size.Y.Offset or 400
    local descH=view<360 and 52 or 72
    if c.map then
        local mapH=math.clamp(view-14-(descH+12)-48-4,64,150)
        local f=UI.make('Frame',body,{Name='MapPreview',BackgroundColor3=UI.colors.ocean,BorderSizePixel=0,ClipsDescendants=true});UI.box(f,2,y,w-4,mapH)
        local r=Raster.new(f,192,100);r:setPreview(Maps.preview(c.map));task.defer(function()if f.Parent then r:fit();r:draw()end end);f.Destroying:Once(function()r:destroy()end)
        y+=mapH+12
    end
    local t=UI.label(body,'Description',c.description,16);t.TextWrapped=true;UI.box(t,8,y,w-16,descH);y+=descH+12
    local cancel=UI.button(body,'Cancel','돌아가기',function()step(c,'cancelled');if c.back then lobby:openPage(c.back)else lobby:closePage()end end);UI.box(cancel,2,y,(w-12)/2,48)
    local go=UI.button(body,'Confirm',c.label,function()
        if lobby.confirmation~=c then return end;lobby.confirmation=nil
        step(c,'accepted')
        c.callback()
    end,true);UI.box(go,(w+8)/2,y,(w-12)/2,48)
    body.CanvasSize=UDim2.fromOffset(0,y+60)
end
return M
