local _,ns = ...
local f = CreateFrame("Frame")
local loaded = false
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, ...)
    if event =="PLAYER_LOGIN" and ns.init and not loaded then
        loaded = true
        ns.init()
    end
end)