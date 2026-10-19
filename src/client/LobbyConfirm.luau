local UI=require(script.Parent.ToyUI)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local Raster=require(script.Parent.RasterMap)
local M={}
function M.open(lobby,title,description,confirm,callback,back,map)
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
    local cancel=UI.button(body,'Cancel','돌아가기',function()require(script.Parent.TelemetryStep).step('lobby','confirm',{item=require(script.Parent.TelemetryStep).code(c.back),result='cancelled'});if c.back then lobby:openPage(c.back)else lobby:closePage()end end);UI.box(cancel,2,y,(w-12)/2,48)
    local go=UI.button(body,'Confirm',c.label,function()
        if lobby.confirmation~=c then return end;lobby.confirmation=nil
        require(script.Parent.TelemetryStep).step('lobby','confirm',{item=require(script.Parent.TelemetryStep).code(c.back),result='accepted'})
        c.callback()
    end,true);UI.box(go,(w+8)/2,y,(w-12)/2,48)
    body.CanvasSize=UDim2.fromOffset(0,y+60)
end
return M
