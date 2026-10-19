local M={}
function M.current(service,player,account,players)
    return account~=nil and not service.closing and not account.departed
        and player.Parent==players and service.accounts[player]==account
end
return M
