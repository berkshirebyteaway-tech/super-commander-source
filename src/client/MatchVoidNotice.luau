local M={}
function M.show(lobby,void)
    local Step=require(script.Parent.TelemetryStep)
    Step.step('lobby','voidNotice',{result='shown'})
    task.spawn(function()local shop=lobby.callbacks.shop and lobby.callbacks.shop();if shop then shop:request('ackVoided',void.id)end end)
    local Confirm=require(script.Parent.LobbyConfirm)
    local ok,v2=pcall(function()return require(script.Parent.Lobby20).ENABLED end)
    if ok and v2==true then
        Confirm.window(lobby,{title='업데이트로 경기 종료',line=void.paid==true and '전적 미반영, XP와 코인 지급'or '전적 미반영',label='확인',cancel=false,callback=function()end})
        return
    end
    Confirm.open(lobby,'업데이트가 나왔어요!',void.paid==true and '이전에 진행하던 경기는 결과 기록에 반영되지 않았어요. 플레이한 만큼 XP와 코인은 드렸어요. 불편을 드려 죄송해요.'or '이전에 진행하던 경기는 결과 기록에 반영되지 않았어요. 불편을 드려 죄송해요.','확인',function()lobby:closePage()end)
end
return M
