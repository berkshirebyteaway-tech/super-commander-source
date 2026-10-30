local Players=game:GetService("Players")
local M={};local cache={};local RETRY_AFTER=30
local function deliver(callback,url)
    local ok,why=pcall(callback,url)
    if not ok then warn('AvatarPortrait callback failed: '..tostring(why))end
end
function M.request(userId,callback)
    if type(userId)~="number" or userId<=0 then return end
    local entry=cache[userId]
    if entry then
        if entry.url then deliver(callback,entry.url);return end
        if entry.waiters then table.insert(entry.waiters,callback);return end
        if os.clock()<entry.retryAt then return end
    end
    entry={waiters={callback}};cache[userId]=entry
    task.spawn(function()
        for attempt=1,3 do
            local ok,url,ready=pcall(function() return Players:GetUserThumbnailAsync(userId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
            if ok and ready and type(url)=="string" and url~="" then entry.url=url;break end
            if attempt<3 then task.wait(attempt*2) end
        end
        local callbacks=entry.waiters;entry.waiters=nil
        if not entry.url then entry.retryAt=os.clock()+RETRY_AFTER;return end
        for _,cb in ipairs(callbacks) do deliver(cb,entry.url) end
    end)
end
return M
