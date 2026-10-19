local M={}
M.prefixes={"북부","남부","동부","서부","고원","해안","사막","설원","초원","협곡","강변","분지","산악","평야","삼림","만안","반도","내륙","국경","도서"}
M.toys={"민병대","자치령","의용군","수비대","연맹","공국","자유시","결사대","부족","연합","경비대","유격대","방위군","성채","교역소","개척지","정착촌","순찰대","보루","전초기지"}
function M.name(index,seed)
    local hash=0;for i=1,#tostring(seed or '')do hash=(hash*31+string.byte(tostring(seed or ''),i))%400 end
    local n=((index-1)*137+hash)%400
    return M.prefixes[n%20+1].." "..M.toys[math.floor(n/20)+1]
end
M.localColor={116,108,94}
M.localShades={{116,108,94},{104,98,86},{126,118,102},{96,92,82},{134,126,110},{110,104,96},{122,114,98},{100,96,90}}
return M
