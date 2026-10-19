local M={}
M.PHONE_HUD=98
M.PHONE_SCALE=.92
function M.phoneHudWidth(w)local s=M.PHONE_SCALE;return math.min(math.floor((w-16)/s),math.max(560,math.floor(w*.68/s)))end
function M.phone(w,h,touch)return touch==true and h<500 and w>h and w>=560 end
function M.shortcuts(w,h,touch)
    if M.phone(w,h,touch)then
        local x=w-54;local hudRight=math.ceil((w+M.phoneHudWidth(w)*M.PHONE_SCALE)/2)+4
        local high,low=h-M.PHONE_HUD,h-50
        if x<hudRight then
            local comms=high-4-48
            return {
                Menu={x=x,y=2},CameraShortcut={x=x,y=comms-96},EventLogButton={x=x,y=comms-48},CommsShortcut={x=x,y=comms},
                FavoriteEmojis={x=x-156,y=comms},QuickMessages={x=x-104,y=comms},MotionShortcut={x=x-52,y=comms},
            }
        end
        local camera=x-52>=hudRight and {x=x-52,y=low}or {x=x,y=high-48}
        local row=high-52
        return {
            Menu={x=x,y=2},CameraShortcut=camera,EventLogButton={x=x,y=high},CommsShortcut={x=x,y=low},
            FavoriteEmojis={x=x-156,y=row},QuickMessages={x=x-104,y=row},MotionShortcut={x=x-52,y=row},
        }
    end
    if not touch then
        local x=w-56;local y=math.max(80,h-72);local social=math.max(8,y-72)
        return {
            Menu={x=x,y=y},CameraShortcut={x=x-56,y=y},EventLogButton={x=x-112,y=y},
            FavoriteEmojis={x=x-112,y=social},QuickMessages={x=x-56,y=social},MotionShortcut={x=x,y=social},
        }
    end
    local x=w-52
    local y=h-52-(h<400 and 144 or 152)
    if h>=500 and w-8-460-8-52-96>=160 then x,y=w-8-460-8-52,h-52 end
    y=math.max(60,y)
    local social=math.max(8,y-52)
    return {
        Menu={x=x,y=y},CameraShortcut={x=x-48,y=y},EventLogButton={x=x-96,y=y},
        FavoriteEmojis={x=x-96,y=social},QuickMessages={x=x-48,y=social},MotionShortcut={x=x,y=social},
    }
end
function M.notice(w,h)
    local width=math.min(280,w-24)
    return {x=w<900 and h<500 and 12 or w-width-12,y=h<500 and 60 or 248,w=width,h=48}
end
function M.command(w,h)
    return {x=12,y=h<500 and 60 or 120,w=math.min(280,w-24),h=88}
end
return M
