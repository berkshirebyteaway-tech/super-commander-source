return function(fn)
    if not pcall(function()game:BindToClose(fn)end)then task.spawn(fn)end
end
