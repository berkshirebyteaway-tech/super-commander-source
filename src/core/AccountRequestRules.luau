local M={}
function M.lane(action,value)
    if type(action)~='string'or #action>32 then return false end
    if action=='career'then
        if value~='plate'then return false end
        return true,'career:'..value
    end
    return true,action=='viewCollection'and 'view'or action=='ackVoided'and 'voided'or nil
end
return M
