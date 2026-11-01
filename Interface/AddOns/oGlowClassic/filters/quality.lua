local _, ns = ...
local oGlowClassic = ns.oGlowClassic
local colorTable = ns.colorTable
local threshold = 1
local questEnabled = true

local questCacheByItemID = {}

local function getLinkType(itemLink)
	if type(itemLink) ~= "string" then
		return nil
	end

	-- Full hyperlink: |Htype:data|h...
	local linkType = itemLink:match("|H([^:]+):")
	if linkType then
		return linkType
	end

	-- Raw link: type:data
	return itemLink:match("^([^:]+):")
end

local function getBattlePetQuality(itemLink)
	if type(itemLink) ~= "string" then
		return nil
	end

	local q = itemLink:match("|Hbattlepet:%d+:%d+:(%d+)")
	if not q then
		q = itemLink:match("^battlepet:%d+:%d+:(%d+)")
	end
	return q and tonumber(q) or nil
end

local function matchesQuestTooltipText(text, questItemText, startsQuestText)
	if not text then
		return false
	end

	if questItemText and text:find(questItemText, 1, true) then
		return true
	end
	if startsQuestText and text:find(startsQuestText, 1, true) then
		return true
	end

	-- Fallback for cases where globals aren't present/complete.
	if text == "Quest Item" or text == "Starts a Quest" or text == "This Item Begins a Quest" then
		return true
	end

	return false
end

local scanTooltip
local function getScanTooltip()
	if scanTooltip then
		return scanTooltip
	end

	if not (CreateFrame and UIParent) then
		return nil
	end

	scanTooltip = CreateFrame("GameTooltip", "oGlowClassicQuestScanTooltip", UIParent, "GameTooltipTemplate")
	scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	return scanTooltip
end

local function isQuestItemByTooltip(itemLink, itemID)
	local questItemText = _G.ITEM_BIND_QUEST
	local startsQuestText = _G.ITEM_STARTS_QUEST

	-- Non-item links (e.g. battle pets) can't be scanned via item tooltips and can't be quest items.
	if itemLink and getLinkType(itemLink) ~= "item" then
		return false
	end

	-- Modern clients: Tooltip info API.
	if C_TooltipInfo and (C_TooltipInfo.GetHyperlink or C_TooltipInfo.GetItemByID) then
		local tooltipInfo
		if itemLink and C_TooltipInfo.GetHyperlink then
			tooltipInfo = C_TooltipInfo.GetHyperlink(itemLink)
		elseif itemID and C_TooltipInfo.GetItemByID then
			tooltipInfo = C_TooltipInfo.GetItemByID(itemID)
		end

		if tooltipInfo and tooltipInfo.lines then
			local retrievingText = _G.RETRIEVING_ITEM_INFO
			for _, line in ipairs(tooltipInfo.lines) do
				local leftText = line and line.leftText
				local rightText = line and line.rightText
				if retrievingText and (leftText == retrievingText or rightText == retrievingText) then
					return nil
				end
				if matchesQuestTooltipText(leftText, questItemText, startsQuestText) or matchesQuestTooltipText(rightText, questItemText, startsQuestText) then
					return true
				end
			end

			return false
		end
	end

	-- Classic/older clients: scan via a hidden GameTooltip.
	local tt = getScanTooltip()
	if not (tt and tt.ClearLines and tt.SetOwner and tt.SetHyperlink and tt.NumLines) then
		return nil
	end

	tt:ClearLines()
	tt:SetOwner(UIParent, "ANCHOR_NONE")
	if itemLink then
		local ok = pcall(tt.SetHyperlink, tt, itemLink)
		if not ok then
			tt:Hide()
			return false
		end
	elseif itemID then
		local ok = pcall(tt.SetHyperlink, tt, "item:" .. itemID)
		if not ok then
			tt:Hide()
			return false
		end
	else
		return nil
	end

	local retrievingText = _G.RETRIEVING_ITEM_INFO
	local ttName = tt:GetName()
	for i = 1, tt:NumLines() do
		local leftRegion = ttName and _G[ttName .. "TextLeft" .. i]
		local rightRegion = ttName and _G[ttName .. "TextRight" .. i]
		local leftText = leftRegion and leftRegion.GetText and leftRegion:GetText()
		local rightText = rightRegion and rightRegion.GetText and rightRegion:GetText()

		if retrievingText and (leftText == retrievingText or rightText == retrievingText) then
			tt:Hide()
			return nil
		end

		if matchesQuestTooltipText(leftText, questItemText, startsQuestText) or matchesQuestTooltipText(rightText, questItemText, startsQuestText) then
			tt:Hide()
			return true
		end
	end

	tt:Hide()
	return false
end

local function isQuestItem(itemLinkOrID)
	if not itemLinkOrID then
		return false
	end

	local itemLink = type(itemLinkOrID) == "string" and itemLinkOrID or nil
	local itemID = type(itemLinkOrID) == "number" and itemLinkOrID or nil
	if itemLink and getLinkType(itemLink) ~= "item" then
		return false
	end

	-- Fast path: item info instant classification.
	if C_Item and C_Item.GetItemInfoInstant then
		local classID = select(6, C_Item.GetItemInfoInstant(itemLinkOrID))
		if classID ~= nil then
			local questClass = (Enum and Enum.ItemClass and Enum.ItemClass.Questitem) or _G.LE_ITEM_CLASS_QUESTITEM
			if questClass ~= nil and classID == questClass then
				return true
			end
		end
	end

	-- Cache by itemID when possible to avoid repeated tooltip scans.
	if not itemID and itemLink and C_Item and C_Item.GetItemInfoInstant then
		itemID = select(1, C_Item.GetItemInfoInstant(itemLink))
	end

	if itemID and questCacheByItemID[itemID] ~= nil then
		return questCacheByItemID[itemID]
	end

	local isQuest = isQuestItemByTooltip(itemLink, itemID)
	if itemID and isQuest ~= nil then
		questCacheByItemID[itemID] = isQuest
	end
	return isQuest
end

local function normalizeItemLink(itemLinkOrID)
	if not itemLinkOrID then
		return nil
	end

	if type(itemLinkOrID) == "string" then
		-- Sometimes callers pass an itemID as a string.
		local asNumber = tonumber(itemLinkOrID)
		if asNumber and not itemLinkOrID:find(":") then
			itemLinkOrID = asNumber
		else
			return itemLinkOrID
		end
	end

	if type(itemLinkOrID) == "number" then
		return itemLinkOrID
	end

	return nil
end

local function getCachedItemQuality(itemRef)
	if not itemRef then
		return nil
	end

	if C_Item and C_Item.GetItemInfo then
		local itemName, itemLink, itemQuality = C_Item.GetItemInfo(itemRef)
		return itemQuality
	end

	if type(GetItemInfo) == "function" then
		local itemName, itemLink, itemQuality = GetItemInfo(itemRef)
		return itemQuality
	end

	return nil
end

local function scheduleRefreshAfterLoad(slot, itemRef)
	if not (slot and Item and (Item.CreateFromItemLink or Item.CreateFromItemID)) then
		return
	end

	if type(itemRef) == "string" and getLinkType(itemRef) == "battlepet" then
		return
	end

	if slot.oGlowClassicQualityLoadPending then
		return
	end
	slot.oGlowClassicQualityLoadPending = true

	local item
	if type(itemRef) == "number" then
		if Item.CreateFromItemID then
			item = Item:CreateFromItemID(itemRef)
		elseif Item.CreateFromItemLink then
			item = Item:CreateFromItemLink("item:" .. itemRef)
		end
	elseif type(itemRef) == "string" then
		if Item.CreateFromItemLink then
			local ok, created = pcall(Item.CreateFromItemLink, Item, itemRef)
			item = ok and created or nil
		end
	end

	if not (item and not item:IsItemEmpty()) then
		slot.oGlowClassicQualityLoadPending = nil
		return
	end

	item:ContinueOnItemLoad(function()
		slot.oGlowClassicQualityLoadPending = nil
		if not (oGlowClassic and oGlowClassic.RefreshFrame) then
			return
		end

		-- Defer refresh to avoid re-entrancy into Blizzard's Item callback dispatch
		-- (can cause a C stack overflow on Classic clients).
		if C_Timer and C_Timer.After then
			C_Timer.After(0, function()
				if oGlowClassic and oGlowClassic.RefreshFrame then
					oGlowClassic:RefreshFrame(slot)
				end
			end)
		else
			oGlowClassic:RefreshFrame(slot)
		end
	end)
end

local qualityFunc = function(slot, ...)
	local bestQuality = -1
	local hasQuestItem = false
	local missingInfo = false

	for i = 1, select('#', ...) do
		local itemRef = normalizeItemLink(select(i, ...))
		if itemRef then
			-- Battle pets in bags use "battlepet:" links which are not item links in some clients.
			-- They still have a quality value we can use for coloring (3rd field in the link).
			if type(itemRef) == "string" and getLinkType(itemRef) == "battlepet" then
				local petQuality = getBattlePetQuality(itemRef)
				if petQuality ~= nil then
					bestQuality = math.max(bestQuality, petQuality)
				end
			else
			if questEnabled and not hasQuestItem and rawget(colorTable, 'quest') then
				local isQuest = isQuestItem(itemRef)
				if isQuest == true then
					hasQuestItem = true
				elseif isQuest == nil then
					missingInfo = true
					scheduleRefreshAfterLoad(slot, itemRef)
				end
			end

			local q = getCachedItemQuality(itemRef)
			if q ~= nil then
				bestQuality = math.max(bestQuality, q)
			else
				missingInfo = true
				scheduleRefreshAfterLoad(slot, itemRef)
			end
			end
		end
	end

	if questEnabled and hasQuestItem and rawget(colorTable, 'quest') then
		return 'quest'
	end

	if bestQuality > threshold then
		return bestQuality
	end

	-- If we don't have enough info yet, return nil for now and refresh later.
	if missingInfo then
		return nil
	end
end

oGlowClassic:RegisterOptionCallback(function(db)
    local filters = db.FilterSettings
    if filters and filters.quality then
        threshold = filters.quality
    else
        threshold = 1
    end

    questEnabled = not (filters and filters.questItems == false)
end)

oGlowClassic:RegisterFilter(
    'Quality border',
    'Border',
    qualityFunc,
    [[Adds a border to the icons, indicating the quality the items have.]]
)
