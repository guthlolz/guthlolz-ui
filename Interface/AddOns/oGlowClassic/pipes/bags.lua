-- TODO:
--  - Prevent unnecessary double updates.
--  - Write a description.

local hook
local _E
local baganatorHooked
local baganatorBagOpenHooks

local pipe = function(self)
	if not (C_Container and C_Container.GetContainerItemLink) then
		return
	end

	if(oGlowClassic:IsPipeEnabled'bags') then
		local id = self:GetID()
		local name = self:GetName()
		local size = self.size
		for i=1, size do
			local bid = size - i + 1
			local slotFrame = _G[name .. 'Item' .. bid]
			local slotLink = C_Container.GetContainerItemLink(id, i)

			oGlowClassic:CallFilters('bags', 'Border', slotFrame, _E and slotLink)
		end
	end
end

-- Baganator integration (runs under the normal 'bags' pipe)
local function getBaganatorItemRef(button, passedLinkOrID)
	if passedLinkOrID then
		return passedLinkOrID
	end

	local bgr = button and button.BGR
	if not bgr then
		return nil
	end

	if bgr.itemLink then
		return bgr.itemLink
	end
	if bgr.itemID then
		return bgr.itemID
	end

	local itemInfo = bgr.itemInfo
	if type(itemInfo) == "table" then
		if itemInfo.itemLink then
			return itemInfo.itemLink
		end
		if itemInfo.itemID then
			return itemInfo.itemID
		end
	end

	return nil
end

local function updateBaganatorButton(button, passedLinkOrID, force)
	if not _E or not button then
		return
	end

	button.oGlowClassicIsBaganator = true

	local itemRef = getBaganatorItemRef(button, passedLinkOrID)
	if not itemRef then
		button.oGlowClassicLastItemLink = nil
		oGlowClassic:CallFilters('bags', 'Border', button, false)
		return
	end

	if not force and button.oGlowClassicLastItemLink == itemRef then
		return
	end
	button.oGlowClassicLastItemLink = itemRef

	oGlowClassic:CallFilters('bags', 'Border', button, itemRef)
end

local function scanExistingBaganatorButtons(force)
	if not (Baganator and Baganator.API and Baganator.API.Skins and Baganator.API.Skins.GetAllFrames) then
		return false
	end

	local frames = Baganator.API.Skins.GetAllFrames()
	if type(frames) ~= "table" then
		return false
	end

	for i = 1, #frames do
		local details = frames[i]
		if details and details.regionType == "ItemButton" and details.region then
			updateBaganatorButton(details.region, nil, force)
		end
	end

	return true
end

local function clearBaganatorButton(button)
	if not button then
		return
	end

	button.oGlowClassicLastItemLink = nil
	button.oGlowClassicIsBaganator = nil

	if button.oGlowClassicBorder then
		button.oGlowClassicBorder:Hide()
	end

	if button.IconBorder and button.oGlowClassicIconBorderAlpha ~= nil then
		button.IconBorder:SetAlpha(button.oGlowClassicIconBorderAlpha)
		button.oGlowClassicIconBorderAlpha = nil
	end
end

local function clearExistingBaganatorButtons()
	if not (Baganator and Baganator.API and Baganator.API.Skins and Baganator.API.Skins.GetAllFrames) then
		return
	end

	local frames = Baganator.API.Skins.GetAllFrames()
	if type(frames) ~= "table" then
		return
	end

	for i = 1, #frames do
		local details = frames[i]
		if details and details.regionType == "ItemButton" and details.region then
			clearBaganatorButton(details.region)
		end
	end
end

local function hookBaganatorIfAvailable()
	if baganatorHooked then
		return
	end

	if not (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Baganator")) then
		return
	end

	if Baganator and Baganator.API and Baganator.API.Skins and Baganator.API.Skins.RegisterListener then
		Baganator.API.Skins.RegisterListener(function(details)
			if not oGlowClassic:IsPipeEnabled('bags') then
				return
			end
			if details and details.regionType == "ItemButton" and details.region then
				updateBaganatorButton(details.region)
			end
		end)
	end

	if hooksecurefunc then
		hooksecurefunc("SetItemButtonQuality", function(button, quality, itemLinkOrID)
			if not oGlowClassic:IsPipeEnabled('bags') then
				return
			end
			if button and button.BGR ~= nil then
				updateBaganatorButton(button, itemLinkOrID)
			end
		end)
	end

	baganatorHooked = true

	if C_Timer and C_Timer.After then
		C_Timer.After(0, function()
			if not scanExistingBaganatorButtons(true) and Baganator and Baganator.API and Baganator.API.RequestItemButtonsRefresh then
				Baganator.API.RequestItemButtonsRefresh()
			end
			scanExistingBaganatorButtons(true)
		end)
		C_Timer.After(0.2, function() scanExistingBaganatorButtons(true) end)
		C_Timer.After(1, function() scanExistingBaganatorButtons(true) end)
	else
		scanExistingBaganatorButtons(true)
	end
end

local function hookBaganatorBagOpenFunctions()
	if baganatorBagOpenHooks or not hooksecurefunc then
		return
	end

	local function onOpen()
		if not oGlowClassic:IsPipeEnabled('bags') then
			return
		end
		hookBaganatorIfAvailable()
		if C_Timer and C_Timer.After then
			C_Timer.After(0, function() scanExistingBaganatorButtons(true) end)
			C_Timer.After(0.2, function() scanExistingBaganatorButtons(true) end)
		else
			scanExistingBaganatorButtons(true)
		end
	end

	if type(ToggleBackpack) == "function" then
		hooksecurefunc("ToggleBackpack", onOpen)
	end
	if type(OpenAllBags) == "function" then
		hooksecurefunc("OpenAllBags", onOpen)
	end
	if type(ToggleAllBags) == "function" then
		hooksecurefunc("ToggleAllBags", onOpen)
	end
	if type(ToggleBag) == "function" then
		hooksecurefunc("ToggleBag", onOpen)
	end

	baganatorBagOpenHooks = true
end

local update = function(self)
	local frame = _G['ContainerFrame1']
	local i = 2
	while(frame and frame.size) do
		pipe(frame)
		frame = _G['ContainerFrame' .. i]
		i = i + 1
	end

	-- Option changes (colors/intensity/filter settings) should apply immediately to
	-- currently visible Baganator buttons, even when item links did not change.
	hookBaganatorIfAvailable()
	if not scanExistingBaganatorButtons(true) and Baganator and Baganator.API and Baganator.API.RequestItemButtonsRefresh then
		Baganator.API.RequestItemButtonsRefresh()
		if C_Timer and C_Timer.After then
			C_Timer.After(0, function() scanExistingBaganatorButtons(true) end)
		end
	end
end

local ADDON_LOADED = function(self, event, addon)
	if addon == "Baganator" then
		hookBaganatorIfAvailable()
		if C_Timer and C_Timer.After then
			C_Timer.After(0, function() scanExistingBaganatorButtons(true) end)
			C_Timer.After(0.2, function() scanExistingBaganatorButtons(true) end)
		else
			scanExistingBaganatorButtons(true)
		end
	end
end

local enable = function(self)
	_E = true

	if(not hook and type(ContainerFrame_Update) == "function") then
		hooksecurefunc("ContainerFrame_Update", pipe)
		hook = true
	end

	self:RegisterEvent('ADDON_LOADED', ADDON_LOADED)
	hookBaganatorBagOpenFunctions()
	hookBaganatorIfAvailable()
	if baganatorHooked then
		scanExistingBaganatorButtons(true)
	end
end

local disable = function(self)
	_E = nil
	clearExistingBaganatorButtons()
	self:UnregisterEvent('ADDON_LOADED', ADDON_LOADED)
end

oGlowClassic:RegisterPipe('bags', enable, disable, update, 'Bag containers', nil)
