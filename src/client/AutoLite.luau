local M={active=false,threshold=22,window=10}
function M.slow(samples,threshold,window)
    if #samples<window then return false,0 end
    local sum=0;for i=#samples-window+1,#samples do sum+=samples[i] end
    local avg=sum/window;return avg<threshold,avg
end
function M.start(apply)
    if M.started then return end;M.started=true
    local Players,Run,UIS=game:GetService("Players"),game:GetService("RunService"),game:GetService("UserInputService")
    local me=Players.LocalPlayer;local frames,focused,samples=0,true,{}
    Run.RenderStepped:Connect(function()frames+=1 end)
    UIS.WindowFocusReleased:Connect(function()focused=false end)
    UIS.WindowFocused:Connect(function()focused=true end)
    task.spawn(function()
        while not M.active do
            frames=0;task.wait(1)
            if focused and me:GetAttribute("FrontierRoom")~=nil then
                table.insert(samples,frames);if #samples>M.window then table.remove(samples,1)end
                local slow,avg=M.slow(samples,M.threshold,M.window)
                if slow then M.active=true;pcall(apply)
                    require(script.Parent.TelemetryStep).step('perf','autoLite',{value=math.floor(avg),item=UIS.TouchEnabled and 'touch'or 'mouse',result='ok'})end
            else table.clear(samples)end
        end
    end)
end
return M
