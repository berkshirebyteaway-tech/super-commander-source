local options
if script then options=Instance.new('DataStoreGetOptions');options.UseCache=false else options={UseCache=false}end
local M={}
function M.read(store,key)return store:GetAsync(key,options)end
return M
