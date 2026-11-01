-- TODO:
--  - Write a description.

local _E
local hook

local pipe = function(id)
	if type(GetTradeSkillItemLink) ~= "function"
		or type(GetTradeSkillNumReagents) ~= "function"
		or type(GetTradeSkillReagentItemLink) ~= "function" then
		return
	end
	local itemLink = GetTradeSkillItemLink(id)

	if(itemLink) then
		oGlowClassic:CallFilters('tradeskill', 'Border', TradeSkillSkillIcon, _E and itemLink)
	end

	for i=1, GetTradeSkillNumReagents(id) do
		local reagentFrame = _G['TradeSkillReagent' .. i .. 'IconTexture']
		local reagentLink = GetTradeSkillReagentItemLink(id, i)

		oGlowClassic:CallFilters('tradeskill', 'Border', reagentFrame, _E and reagentLink)
	end
end

local doHook = function()
	if(not hook and type(TradeSkillFrame_SetSelection) == "function") then
		hook = function(...)
			if(_E) then return pipe(...) end
		end

		hooksecurefunc('TradeSkillFrame_SetSelection', hook)
	end
end

local function ADDON_LOADED(self, event, addon)
	if(addon == 'Blizzard_TradeSkillUI') then
		doHook()
		self:UnregisterEvent(event, ADDON_LOADED)
	end
end

local update = function(self)
	local id = type(GetTradeSkillSelectionIndex) == "function" and GetTradeSkillSelectionIndex()
	if(id and C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded('Blizzard_TradeSkillUI')) then
		return pipe(id)
	end
end

local enable = function(self)
	_E = true

	if(C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_TradeSkillUI")) then
		doHook()
	else
		self:RegisterEvent("ADDON_LOADED", ADDON_LOADED)
	end
end

local disable = function(self)
	_E = nil

	self:UnregisterEvent('ADDON_LOADED', ADDON_LOADED)
end

oGlowClassic:RegisterPipe('tradeskill', enable, disable, update, 'Profession frame', nil)
