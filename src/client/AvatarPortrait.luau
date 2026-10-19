local Players=game:GetService("Players")
local M={};local cache={}
function M.request(userId,callback)
    if type(userId)~="number" or userId<=0 then return end
    local entry=cache[userId]
    if entry then
        if entry.url then callback(entry.url) elseif entry.waiters then table.insert(entry.waiters,callback) end
        return
    end
    entry={waiters={callback}};cache[userId]=entry
    task.spawn(function()
        for attempt=1,3 do
            local ok,url,ready=pcall(function() return Players:GetUserThumbnailAsync(userId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
            if ok and ready and type(url)=="string" and url~="" then entry.url=url;break end
            if attempt<3 then task.wait(attempt*2) end
        end
        local callbacks=entry.waiters;entry.waiters=nil
        if entry.url then for _,cb in ipairs(callbacks) do cb(entry.url) end end
    end)
end
return M
