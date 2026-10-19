local UI=require(script.Parent.Theme)
local Gui=game:GetService('GuiService')
local M={};M.__index=M
function M.new(playerGui,surface)
    local gui=UI.make('ScreenGui',playerGui,{Name='FrontierWorldAnnotations',DisplayOrder=4,ResetOnSpawn=false,
        ScreenInsets=Enum.ScreenInsets.None,ClipToDeviceSafeArea=false,SafeAreaCompatibility=Enum.SafeAreaCompatibility.None,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
    local root=UI.make('Frame',gui,{Name='Canvas',BackgroundTransparency=1,ClipsDescendants=false,Size=UDim2.fromScale(1,1)})
    local scale=UI.make('UIScale',root,{Scale=1})
    local canvas=UI.make('Frame',root,{Name='MapCoordinates',BackgroundTransparency=1,ClipsDescendants=false})
    return setmetatable({gui=gui,root=root,scale=scale,canvas=canvas,surface=surface},M)
end
function M:sync(visible)
    self.gui.Enabled=visible==true
    local inset=Gui:GetGuiInset();local screenOrigin=self.surface.AbsolutePosition+inset
    local size=self.surface.AbsoluteSize;local s=UI.scale
    local viewport=workspace.CurrentCamera.ViewportSize
    local origin=self.surface.AbsolutePosition-self.root.AbsolutePosition
    local key=tostring(origin)..':'..tostring(size)..':'..tostring(viewport)..':'..s
    if self.key~=key then
        self.key=key;self.scale.Scale=s;self.root.Size=UDim2.fromScale(1/s,1/s)
        UI.box(self.canvas,origin.X/s,origin.Y/s,size.X/s,size.Y/s)
        self.bounds={left=-screenOrigin.X/s,top=-screenOrigin.Y/s,right=(viewport.X-screenOrigin.X)/s,bottom=(viewport.Y-screenOrigin.Y)/s}
    end
    return self.bounds
end
function M:destroy()self.gui:Destroy()end
return M
