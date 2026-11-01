local _, ns = ...
local L = {}
ns.L = setmetatable(L,{__index=function(table,key)
	local value = tostring(key)
	rawset(table,key,value)
	return key
end});

L["Hello World"] = "Hello World"
L["TooltipID options"] = "TooltipID options"
L["Show the following tooltip for this list:"] = "Show the following tooltip ID for this list:"
L["Reload UI to apply changes"] = "Reload UI to apply changes"