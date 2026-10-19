local M={}
function M.show(lobby,void)
    local Step=require(script.Parent.TelemetryStep)
    Step.step('lobby','voidNotice',{result='shown'})
    task.spawn(function()local shop=lobby.callbacks.shop and lobby.callbacks.shop();if shop then shop:request('ackVoided',void.id)end end)
    require(script.Parent.LobbyConfirm).open(lobby,'업데이트가 나왔어요!',void.paid==true and '이전에 진행하던 경기는 결과 기록에 반영되지 않았어요. 플레이한 만큼 XP와 코인은 드렸어요. 불편을 드려 죄송해요.'or '이전에 진행하던 경기는 결과 기록에 반영되지 않았어요. 불편을 드려 죄송해요.','확인',function()lobby:closePage()end)
end
return M
