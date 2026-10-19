local M={}
function M.attach(pack,getSession,publish)
    if not game:GetService("RunService"):IsStudio() then return end
    local scenario=Instance.new("BindableFunction");scenario.Name="StudioScenarios";scenario.Parent=pack
    scenario.OnInvoke=function(kind,id)
        local session=getSession();assert(session and session.phase=="playing","Start a game before running a scenario")
        assert(session.sim.players[id] and id~=1,"Supply an existing opponent ID")
        local ok,message
        if kind=="incomingAlliance" then ok,message=session:allianceCommand(id,1,"request")
        elseif kind=="incomingAttack" then ok,message=session:attack(id,1,.5)
        else error("Unknown Studio scenario") end
        if ok then session:step();publish(true) end
        return {ok=ok,message=message}
    end
end
return M
