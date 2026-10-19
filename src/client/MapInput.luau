local UIS=game:GetService("UserInputService")
local M={}
function M.bind(surface,renderer,callbacks)
    local pointers={};local mouse=nil;local pinch=nil;local moved=false
    local function pos(input) return Vector2.new(input.Position.X,input.Position.Y) end
    local function mousePosition() return UIS:GetMouseLocation()-game:GetService("GuiService"):GetGuiInset() end
    local function list() local r={};for _,v in pairs(pointers) do table.insert(r,v) end;return r end
    local function begin(input)
        if not callbacks.enabled() then return end
        if input.UserInputType==Enum.UserInputType.Touch then
            pointers[input]={at=pos(input),start=pos(input)};local a=list();moved=false
            if #a==2 then pinch={distance=(a[1].at-a[2].at).Magnitude};moved=true end
        elseif input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.MouseButton2 then
            local p=mousePosition();mouse={start=p,previous=p,right=input.UserInputType==Enum.UserInputType.MouseButton2};moved=false
        end
    end
    local function pan(delta)
        local v=renderer.view;local s=surface.AbsoluteSize
        v.x-=delta.X/s.X*v.w;v.y-=delta.Y/s.Y*v.h;renderer:clamp();callbacks.changed()
    end
    surface.InputBegan:Connect(begin)
    UIS.InputChanged:Connect(function(input)
        if not callbacks.enabled() then return end
        if input.UserInputType==Enum.UserInputType.Touch and pointers[input] then
            local p=pointers[input];local old=p.at;p.at=pos(input);local a=list()
            if #a==2 then
                moved=true;local d=(a[1].at-a[2].at).Magnitude
                if pinch and d>5 then
                    local center=(a[1].at+a[2].at)/2-surface.AbsolutePosition
                    renderer:zoom(pinch.distance/d,center.X/surface.AbsoluteSize.X,center.Y/surface.AbsoluteSize.Y);callbacks.changed()
                end
                pinch={distance=d}
            elseif #a==1 then
                if (p.at-p.start).Magnitude>8 then moved=true end
                if moved then pan(p.at-old) end
            end
        elseif input.UserInputType==Enum.UserInputType.MouseMovement then
            local p=mousePosition()
            if mouse then
                if (p-mouse.start).Magnitude>6 then moved=true end
                if moved or mouse.right then pan(p-mouse.previous) end;mouse.previous=p
            elseif callbacks.hover then callbacks.hover(renderer:tileAt(p),p) end
        elseif input.UserInputType==Enum.UserInputType.MouseWheel and renderer:tileAt(mousePosition()) and not callbacks.blocked(mousePosition()) then
            local p=mousePosition()-surface.AbsolutePosition
            renderer:zoom(input.Position.Z>0 and .8 or 1.25,p.X/surface.AbsoluteSize.X,p.Y/surface.AbsoluteSize.Y);callbacks.changed()
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.Touch and pointers[input] then
            local p=pointers[input];pointers[input]=nil
            if not moved and not pinch and callbacks.enabled() then callbacks.select(renderer:tileAt(p.at)) end
            if next(pointers)==nil then pinch=nil;moved=false end
        elseif mouse and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.MouseButton2) then
            if not mouse.right and not moved and callbacks.enabled() then callbacks.select(renderer:tileAt(mousePosition())) end;mouse=nil
        end
    end)
    UIS.WindowFocusReleased:Connect(function() mouse=nil;table.clear(pointers);pinch=nil;moved=false end)
end
return M
