local UI=require(script.Parent.Theme)
local Icons=require(script.Parent.OutgameIcons)
local Step=require(script.Parent.TelemetryStep)
local L=require(script.Parent.Localization)
local TextService=game:GetService('TextService')
local M={}
local C=UI.colors
local function commas(n)local s=tostring(math.floor(n or 0));local out=s:reverse():gsub('(%d%d%d)','%1,'):reverse();return (out:gsub('^,',''))end
M.commas=commas
function M.press(kind)
    Step.step('social','inviteAsk',{result='tapped',item=kind})
    if M.open then M.open()end
end
function M.button(make,actions,pr)
    local b=make(actions,'Invite','',function()local a=pr and pr.invite;M.press(a and a.first and 'first'or 'daily')end)
    local label=UI.label(b,'Label','친구 초대',13,C.gold);label.Font=Enum.Font.BuilderSansExtraBold;label.TextWrapped=false
    label.TextXAlignment=Enum.TextXAlignment.Center;label.AnchorPoint=Vector2.new(0,.5)
    local coin=Icons.create(b,'coin',16,C.gold);coin.Name='Coin';coin.AnchorPoint=Vector2.new(0,.5)
    local amount=UI.label(b,'Amount','',13,C.gold);amount.Font=Enum.Font.BuilderSansExtraBold;amount.TextWrapped=false;amount.AnchorPoint=Vector2.new(0,.5)
    amount:SetAttribute('LocalizationSkip',true)
    M.set(b,pr and pr.invite);return b
end
function M.set(b,invite)
    b:SetAttribute('Ask',invite~=nil)
    local amount=b:FindFirstChild('Amount');if amount then amount.Text=invite and commas(invite.coins)or ''end
end
function M.slot(actions)
    local invite,share=actions:FindFirstChild('Invite'),actions:FindFirstChild('Share')
    local ask=invite and invite:GetAttribute('Ask')==true
    if invite then invite.Visible=ask end;if share then share.Visible=not ask end
    return ask and invite or share
end
function M.fit(b,size,bw)
    local label,coin,amount=b:FindFirstChild('Label'),b:FindFirstChild('Coin'),b:FindFirstChild('Amount')
    if not(label and coin and amount)then return end
    local icon=Icons.available(coin);coin.Visible=icon
    local n=tonumber((amount.Text:gsub('%D','')))
    if n then amount.Text=icon and commas(n)or L.text(string.format('+%s 코인',commas(n)))end
    local function width(l)l.TextSize=size;return TextService:GetTextSize(L.text(l.Text),size,l.Font,Vector2.new(1000,40)).X end
    local lw,aw=width(label),width(amount);local cw=icon and 16+4 or 0
    local total=lw+6+cw+aw;local x=math.max(4,math.floor((bw-total)/2))
    label.Position=UDim2.new(0,x,.5,-1);label.Size=UDim2.fromOffset(lw,24)
    coin.Position=UDim2.new(0,x+lw+6,.5,-1);coin.Size=UDim2.fromOffset(16,16)
    amount.Position=UDim2.new(0,x+lw+6+cw,.5,-1);amount.Size=UDim2.fromOffset(aw,24)
end
return M
