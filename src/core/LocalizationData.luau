local out={}
for _,row in ipairs(if script then require(script.Parent.LocalizationData_1)else require('./LocalizationData_1'))do table.insert(out,row)end
for _,row in ipairs(if script then require(script.Parent.LocalizationData_2)else require('./LocalizationData_2'))do table.insert(out,row)end
return out
