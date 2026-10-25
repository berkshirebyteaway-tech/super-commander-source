local M={}
M.PHONE_HUD=88
M.PHONE_SCALE=.82
M.PHONE_WIDE=.85
M.TOUCH_SCALE=.88
M.TOUCH_WIDE=.92
function M.tablet(w,h,touch)return touch==true and math.min(w,h)>=540 and math.max(w,h)>=900 end
function M.desk(w,h,touch)return not touch or M.tablet(w,h,touch)end
function M.phoneHudWidth(w)local s=M.PHONE_SCALE;return math.floor(math.min(w-16,math.max(560*M.PHONE_WIDE,w*.68/.92*M.PHONE_WIDE))/s)end
M.PC_SCALE=.75
M.PC_HUD=.67
M.PC_HUD_WIDE=.70
M.PC_TEXT=15
function M.pcScale(touch,w,h)return(w and M.desk(w,h,touch)or not touch)and M.PC_SCALE or 1 end
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
        local history=math.min(high,low-48)
        local camera={x=x,y=history-48}
        local row=high-52
        return {
            Menu={x=x,y=2},CameraShortcut=camera,EventLogButton={x=x,y=history},CommsShortcut={x=x,y=low},
            FavoriteEmojis={x=x-156,y=row},QuickMessages={x=x-104,y=row},MotionShortcut={x=x-52,y=row},
        }
    end
    if M.desk(w,h,touch)then
        local s=M.PC_SCALE;local size=math.floor(48*s+.5);local across=math.floor(56*s+.5);local down=math.floor(56*s+.5)
        local x=w-8-size;local y=math.max(80,h-down);local social=math.max(8,y-down)
        return {
            Menu={x=x,y=y},CameraShortcut={x=x-across,y=y},EventLogButton={x=x-across*2,y=y},
            FavoriteEmojis={x=x-across*2,y=social},QuickMessages={x=x-across,y=social},MotionShortcut={x=x,y=social},
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
