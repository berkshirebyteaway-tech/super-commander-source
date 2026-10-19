local M={}
local function positive(n)return type(n)=='number'and n==n and n>0 and n<math.huge end
function M.format(info,kind,locale)
    if type(info)~='table'or info.IsForSale~=true then return nil end
    local robux=info.PriceInRobux
    if kind~='subscription'then return positive(robux)and tostring(robux)..' Robux'or nil end
    local display=type(info.DisplayPrice)=='string'and info.DisplayPrice or ''
    if display==''or display:match('^%s*[%d%.,]+%s*$')then
        if not positive(robux)then return nil end
        display=tostring(robux)..' Robux'
    end
    local period=type(info.DisplaySubscriptionPeriod)=='string'and info.DisplaySubscriptionPeriod or ''
    if period==''then
        local name=tostring(info.SubscriptionPeriod)
        local korean=type(locale)=='string'and locale:sub(1,2)=='ko'
        if name=='Month'or name=='Enum.SubscriptionPeriod.Month'then period=korean and '/월'or '/month'
        elseif name=='Year'or name=='Enum.SubscriptionPeriod.Year'then period=korean and '/년'or '/year'
        else return nil end
    end
    return display..period
end
return M
