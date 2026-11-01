local addonName = ...

local Tracker = {}
_G.TBCA_BIS_Tracker = Tracker

local STATUS_ORDER = { "want", "upgrade", "have", "pass" }
local STATUS_LABELS = {
	want = "Want",
	upgrade = "Upgrade",
	have = "Have",
	pass = "Pass",
}

local STATUS_COLORS = {
	want = "ffffcc00",
	upgrade = "ff4da6ff",
	have = "ff33cc66",
	pass = "ff999999",
}

local STATUS_LETTERS = {
	want = "W",
	upgrade = "U",
	have = "H",
	pass = "P",
}

local SLOT_TO_EXPORT = {
	Head = "HEAD",
	Neck = "NECK",
	Shoulders = "SHOULDERS",
	Back = "BACK",
	Chest = "CHEST",
	Wrist = "WRIST",
	Hands = "HANDS",
	Waist = "WAIST",
	Legs = "LEGS",
	Feet = "FEET",
	Ring = "FINGER_1",
	Trinket = "TRINKET_1",
	["Main Hand"] = "MAIN_HAND",
	["Off Hand"] = "OFF_HAND",
	["One Hand"] = "MAIN_HAND",
	["Two Hand"] = "MAIN_HAND",
	Ranged = "RANGED",
}

local EXPORT_TO_SLOT = {
	HEAD = "Head",
	NECK = "Neck",
	SHOULDERS = "Shoulders",
	BACK = "Back",
	CHEST = "Chest",
	WRIST = "Wrist",
	HANDS = "Hands",
	WAIST = "Waist",
	LEGS = "Legs",
	FEET = "Feet",
	FINGER_1 = "Ring",
	FINGER_2 = "Ring",
	TRINKET_1 = "Trinket",
	TRINKET_2 = "Trinket",
	MAIN_HAND = "Main Hand",
	OFF_HAND = "Off Hand",
	RANGED = "Ranged",
}

local EQUIPPED_EXPORT_SLOTS = {
	{ slotID = 1, exportSlot = "HEAD" },
	{ slotID = 2, exportSlot = "NECK" },
	{ slotID = 3, exportSlot = "SHOULDERS" },
	{ slotID = 15, exportSlot = "BACK" },
	{ slotID = 5, exportSlot = "CHEST" },
	{ slotID = 9, exportSlot = "WRIST" },
	{ slotID = 10, exportSlot = "HANDS" },
	{ slotID = 6, exportSlot = "WAIST" },
	{ slotID = 7, exportSlot = "LEGS" },
	{ slotID = 8, exportSlot = "FEET" },
	{ slotID = 11, exportSlot = "FINGER_1" },
	{ slotID = 12, exportSlot = "FINGER_2" },
	{ slotID = 13, exportSlot = "TRINKET_1" },
	{ slotID = 14, exportSlot = "TRINKET_2" },
	{ slotID = 16, exportSlot = "MAIN_HAND" },
	{ slotID = 17, exportSlot = "OFF_HAND" },
	{ slotID = 18, exportSlot = "RANGED" },
}

local function msg(text)
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99TBCA_BIS Tracker|r: " .. tostring(text or ""))
	end
end

local function trim(text)
	return tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizeRealm()
	local realm = GetNormalizedRealmName and GetNormalizedRealmName() or GetRealmName()
	realm = tostring(realm or "Realm"):gsub("%s+", "")
	return realm ~= "" and realm or "Realm"
end

local function makeKey(name, realm, stamp)
	name = tostring(name or "List"):gsub("[^%w_%-]", "_")
	realm = tostring(realm or normalizeRealm()):gsub("[^%w_%-]", "_")
	return name .. "-" .. realm .. "-" .. tostring(stamp or time())
end

local function escapeJson(text)
	text = tostring(text or "")
	text = text:gsub("\\", "\\\\")
	text = text:gsub('"', '\\"')
	text = text:gsub("\n", "\\n")
	text = text:gsub("\r", "\\r")
	text = text:gsub("\t", "\\t")
	return text
end

local function decodeJsonString(text)
	text = tostring(text or "")
	text = text:gsub('\\"', '"')
	text = text:gsub("\\n", "\n")
	text = text:gsub("\\r", "\r")
	text = text:gsub("\\t", "\t")
	text = text:gsub("\\\\", "\\")
	return text
end

local function playerCharacter()
	local localizedClass, classFile = UnitClass("player")
	local raceName, raceFile = UnitRace("player")
	local faction = UnitFactionGroup("player")
	return {
		name = UnitName("player") or "Unknown",
		realm = normalizeRealm(),
		level = UnitLevel("player") or 70,
		gameClass = classFile or localizedClass or "UNKNOWN",
		race = raceFile or raceName or "UNKNOWN",
		faction = faction or "UNKNOWN",
	}
end

function Tracker:EnsureDB()
	_G.TBCA_BIS_TrackerDB = _G.TBCA_BIS_TrackerDB or {}
	local db = _G.TBCA_BIS_TrackerDB
	db.version = db.version or 1
	db.lists = db.lists or {}
	if db.lootAlertEnabled == nil then
		db.lootAlertEnabled = true
	end
	if db.lootAlertSound == nil then
		db.lootAlertSound = true
	end
	return db
end

function Tracker:GetStatusLabels()
	return STATUS_LABELS, STATUS_COLORS
end

function Tracker:GetStatusLetter(status)
	return STATUS_LETTERS[status] or tostring(status or "")
end

function Tracker:GetActiveList()
	local db = self:EnsureDB()
	local active = db.activeList and db.lists[db.activeList]
	return active, db.activeList
end

function Tracker:GetLists()
	local db = self:EnsureDB()
	local rows = {}
	for key, list in pairs(db.lists) do
		rows[#rows + 1] = { key = key, list = list }
	end
	table.sort(rows, function(a, b)
		local ac = tonumber(a.list.updatedAt or a.list.createdAt or 0) or 0
		local bc = tonumber(b.list.updatedAt or b.list.createdAt or 0) or 0
		if ac ~= bc then
			return ac > bc
		end
		return tostring(a.list.name or a.key) < tostring(b.list.name or b.key)
	end)
	return rows
end

function Tracker:SetActiveList(key)
	local db = self:EnsureDB()
	if key and db.lists[key] then
		db.activeList = key
		self:NotifyChanged()
		return true
	end
	return false
end

function Tracker:DeleteList(key)
	local db = self:EnsureDB()
	key = key or db.activeList
	local list = key and db.lists[key]
	if not list then
		return false
	end

	local deletedName = list.name or key
	db.lists[key] = nil
	if db.activeList == key then
		db.activeList = nil
		local lists = self:GetLists()
		if lists[1] then
			db.activeList = lists[1].key
		end
	end
	self:NotifyChanged()
	msg("Deleted list: " .. tostring(deletedName))
	return true
end

function Tracker:CreateList(name, phase, character)
	local db = self:EnsureDB()
	character = character or playerCharacter()
	local now = time()
	local list = {
		name = trim(name) ~= "" and trim(name) or ((character.name or "Character") .. " BiS"),
		phase = tonumber(phase) or (_G.Unforvegan_BISDB and _G.Unforvegan_BISDB.maxPhase) or 4,
		character = character,
		items = {},
		createdAt = now,
		updatedAt = now,
		source = "TBCA_BIS",
	}
	local key = makeKey(character.name or list.name, character.realm, now)
	db.lists[key] = list
	db.activeList = key
	self:NotifyChanged()
	msg("Created active list: " .. list.name)
	return list, key
end

function Tracker:GetOrCreateActiveList()
	local list, key = self:GetActiveList()
	if list then
		return list, key
	end
	return self:CreateList(nil, nil, playerCharacter())
end

function Tracker:GetItemStatus(itemID, listKey)
	itemID = tonumber(itemID)
	if not itemID then
		return nil
	end
	local db = self:EnsureDB()
	local list = listKey and db.lists[listKey] or self:GetActiveList()
	local entry = list and list.items and list.items[itemID]
	return entry and entry.status, entry, list
end

function Tracker:GetItemListStatuses(itemID)
	itemID = tonumber(itemID)
	if not itemID then
		return {}
	end

	local rows = {}
	local lists = self:GetLists()
	for i = 1, #lists do
		local list = lists[i].list
		local entry = list and list.items and list.items[itemID]
		if entry and entry.status then
			rows[#rows + 1] = {
				listKey = lists[i].key,
				listName = list.name or lists[i].key,
				status = entry.status,
				label = STATUS_LABELS[entry.status] or entry.status,
				letter = STATUS_LETTERS[entry.status] or tostring(entry.status),
				updatedAt = entry.updatedAt or list.updatedAt or list.createdAt or 0,
			}
		end
	end
	return rows
end

function Tracker:SetItemStatus(itemID, status, slotKey, itemName)
	itemID = tonumber(itemID)
	if not itemID then
		return nil
	end
	if status ~= "want" and status ~= "upgrade" and status ~= "have" and status ~= "pass" then
		status = nil
	end
	local list = self:GetOrCreateActiveList()
	if status then
		local _, link = GetItemInfo(itemID)
		list.items[itemID] = list.items[itemID] or {}
		list.items[itemID].id = itemID
		list.items[itemID].name = itemName or (link and link:match("%[(.-)%]")) or list.items[itemID].name
		list.items[itemID].slot = slotKey or list.items[itemID].slot
		list.items[itemID].status = status
		list.items[itemID].updatedAt = time()
	else
		list.items[itemID] = nil
	end
	list.updatedAt = time()
	self:NotifyChanged()
	return status
end

function Tracker:CycleItemStatus(itemID, slotKey, itemName)
	local current = self:GetItemStatus(itemID)
	local nextStatus = "want"
	for i = 1, #STATUS_ORDER do
		if current == STATUS_ORDER[i] then
			nextStatus = STATUS_ORDER[i + 1]
			break
		end
	end
	return self:SetItemStatus(itemID, nextStatus, slotKey, itemName)
end

function Tracker:ClearItemStatus(itemID)
	return self:SetItemStatus(itemID, nil)
end

function Tracker:NotifyChanged()
	if _G.TBCA_BIS_Tracker_RefreshAtlasLootMarkers then
		_G.TBCA_BIS_Tracker_RefreshAtlasLootMarkers()
	end
end

local function parseFirstString(block, key)
	local value = block and block:match('"' .. key .. '"%s*:%s*"(.-)"')
	return value and decodeJsonString(value) or nil
end

local function parseFirstNumber(block, key)
	local value = block and block:match('"' .. key .. '"%s*:%s*(%-?%d+)')
	return value and tonumber(value) or nil
end

function Tracker:ImportThatsMyBis(text, targetKey)
	text = tostring(text or "")
	if trim(text) == "" then
		return nil, "Paste a ThatsMyBIS export first."
	end

	local charBlock = text:match('"character"%s*:%s*{%s*(.-)%s*}%s*,%s*"items"') or ""
	local character = {
		name = parseFirstString(charBlock, "name") or (UnitName("player") or "Unknown"),
		realm = normalizeRealm(),
		level = parseFirstNumber(charBlock, "level") or 70,
		gameClass = parseFirstString(charBlock, "gameClass") or "UNKNOWN",
		race = parseFirstString(charBlock, "race") or "UNKNOWN",
		faction = parseFirstString(charBlock, "faction") or "UNKNOWN",
	}

	local db = self:EnsureDB()
	local importedName = parseFirstString(text, "name") or (character.name .. " BiS")
	local importedPhase = parseFirstNumber(text, "phase")
	local list, key, mode
	if targetKey and db.lists[targetKey] then
		key = targetKey
		list = db.lists[targetKey]
		list.name = importedName
		list.phase = importedPhase or list.phase or 4
		list.character = character
		list.items = {}
		list.source = "ThatsMyBIS"
		list.updatedAt = time()
		db.activeList = key
		mode = "overwritten"
	else
		list, key = self:CreateList(importedName, importedPhase, character)
		list.source = "ThatsMyBIS"
		mode = "created"
	end
	local itemsBlock = text:match('"items"%s*:%s*%[(.-)%]%s*,%s*"consumables"') or text:match('"items"%s*:%s*%[(.*)%]')
	local imported = 0
	if itemsBlock then
		for itemBlock in itemsBlock:gmatch("{(.-)}") do
			local itemID = parseFirstNumber(itemBlock, "id")
			if itemID then
				local slot = EXPORT_TO_SLOT[parseFirstString(itemBlock, "slot") or ""] or parseFirstString(itemBlock, "slot")
				list.items[itemID] = {
					id = itemID,
					name = parseFirstString(itemBlock, "name"),
					slot = slot,
					status = "want",
					updatedAt = time(),
				}
				imported = imported + 1
			end
		end
	end
	list.updatedAt = time()
	self:NotifyChanged()
	return key, imported, mode
end

function Tracker:ExportThatsMyBis()
	local list = self:GetActiveList()
	if not list then
		return ""
	end
	local character = list.character or playerCharacter()
	local lines = {}
	lines[#lines + 1] = "{"
	lines[#lines + 1] = '  "name": "' .. escapeJson(list.name or "TBCA_BIS") .. '",'
	lines[#lines + 1] = '  "phase": ' .. tostring(tonumber(list.phase) or 4) .. ","
	lines[#lines + 1] = '  "character": {'
	lines[#lines + 1] = '    "name": "' .. escapeJson(character.name or "Unknown") .. '",'
	lines[#lines + 1] = '    "level": ' .. tostring(tonumber(character.level) or 70) .. ","
	lines[#lines + 1] = '    "gameClass": "' .. escapeJson(character.gameClass or "UNKNOWN") .. '",'
	lines[#lines + 1] = '    "race": "' .. escapeJson(character.race or "UNKNOWN") .. '",'
	lines[#lines + 1] = '    "faction": "' .. escapeJson(character.faction or "UNKNOWN") .. '"'
	lines[#lines + 1] = "  },"
	lines[#lines + 1] = '  "items": ['

	local items = {}
	for itemID, entry in pairs(list.items or {}) do
		if entry and entry.status ~= "pass" then
			items[#items + 1] = entry
		end
	end
	table.sort(items, function(a, b)
		return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
	end)
	for i = 1, #items do
		local entry = items[i]
		local comma = i < #items and "," or ""
		lines[#lines + 1] = '    { "name": "' .. escapeJson(entry.name or "") .. '", "id": ' .. tostring(entry.id) .. ', "slot": "' .. escapeJson(SLOT_TO_EXPORT[entry.slot or ""] or entry.slot or "UNKNOWN") .. '" }' .. comma
	end
	lines[#lines + 1] = "  ],"
	lines[#lines + 1] = '  "consumables": [],'
	lines[#lines + 1] = '  "buffs": [],'
	lines[#lines + 1] = '  "talents": [],'
	lines[#lines + 1] = '  "points": [],'
	lines[#lines + 1] = '  "stats": {},'
	lines[#lines + 1] = '  "exportOptions": { "buffs": true, "talents": true }'
	lines[#lines + 1] = "}"
	return table.concat(lines, "\n")
end

function Tracker:ExportEquippedThatsMyBis()
	local character = playerCharacter()
	local phase = (_G.Unforvegan_BISDB and _G.Unforvegan_BISDB.maxPhase) or 4
	local lines = {}
	lines[#lines + 1] = "{"
	lines[#lines + 1] = '  "name": "' .. escapeJson((character.name or "Character") .. " Current Equipped") .. '",'
	lines[#lines + 1] = '  "phase": ' .. tostring(tonumber(phase) or 4) .. ","
	lines[#lines + 1] = '  "character": {'
	lines[#lines + 1] = '    "name": "' .. escapeJson(character.name or "Unknown") .. '",'
	lines[#lines + 1] = '    "level": ' .. tostring(tonumber(character.level) or 70) .. ","
	lines[#lines + 1] = '    "gameClass": "' .. escapeJson(character.gameClass or "UNKNOWN") .. '",'
	lines[#lines + 1] = '    "race": "' .. escapeJson(character.race or "UNKNOWN") .. '",'
	lines[#lines + 1] = '    "faction": "' .. escapeJson(character.faction or "UNKNOWN") .. '"'
	lines[#lines + 1] = "  },"
	lines[#lines + 1] = '  "items": ['

	local rows = {}
	for i = 1, #EQUIPPED_EXPORT_SLOTS do
		local slot = EQUIPPED_EXPORT_SLOTS[i]
		local itemID = GetInventoryItemID and GetInventoryItemID("player", slot.slotID)
		if itemID then
			local link = GetInventoryItemLink and GetInventoryItemLink("player", slot.slotID)
			local name = link and link:match("%[(.-)%]") or GetItemInfo(itemID) or ""
			rows[#rows + 1] = {
				id = itemID,
				name = name,
				slot = slot.exportSlot,
			}
		end
	end

	for i = 1, #rows do
		local entry = rows[i]
		local comma = i < #rows and "," or ""
		lines[#lines + 1] = '    { "name": "' .. escapeJson(entry.name or "") .. '", "id": ' .. tostring(entry.id) .. ', "slot": "' .. escapeJson(entry.slot or "UNKNOWN") .. '" }' .. comma
	end
	lines[#lines + 1] = "  ],"
	lines[#lines + 1] = '  "consumables": [],'
	lines[#lines + 1] = '  "buffs": [],'
	lines[#lines + 1] = '  "talents": [],'
	lines[#lines + 1] = '  "points": [],'
	lines[#lines + 1] = '  "stats": {},'
	lines[#lines + 1] = '  "exportOptions": { "buffs": true, "talents": true }'
	lines[#lines + 1] = "}"
	return table.concat(lines, "\n"), #rows
end

function Tracker:FindSavedItems(query)
	query = trim(query)
	if query == "" then
		return {}
	end
	local wantedID = tonumber(query)
	local wantedText = string.lower(query)
	local results = {}
	local db = self:EnsureDB()
	for key, list in pairs(db.lists or {}) do
		for itemID, entry in pairs(list.items or {}) do
			local name = tostring(entry.name or "")
			if (wantedID and tonumber(itemID) == wantedID) or (not wantedID and string.find(string.lower(name), wantedText, 1, true)) then
				results[#results + 1] = {
					listKey = key,
					listName = list.name or key,
					character = list.character and list.character.name or nil,
					itemID = tonumber(itemID),
					itemName = name,
					slot = entry.slot,
					status = entry.status,
				}
			end
		end
	end
	table.sort(results, function(a, b)
		if a.listName ~= b.listName then
			return a.listName < b.listName
		end
		return (a.itemID or 0) < (b.itemID or 0)
	end)
	return results
end

function Tracker:PrintFindResults(query)
	local rows = self:FindSavedItems(query)
	if #rows == 0 then
		msg("No saved list entries found for " .. tostring(query) .. ".")
		return
	end
	msg("Saved list matches for " .. tostring(query) .. ":")
	for i = 1, math.min(#rows, 12) do
		local row = rows[i]
		local status = STATUS_LABELS[row.status] or row.status or "Unmarked"
		local owner = row.character and (" / " .. row.character) or ""
		msg(tostring(row.itemID) .. " " .. tostring(row.itemName or "") .. " - " .. tostring(row.listName) .. owner .. " - " .. status)
	end
	if #rows > 12 then
		msg("+" .. tostring(#rows - 12) .. " more matches.")
	end
end

function Tracker:BuildListSummary()
	local list = self:GetActiveList()
	if not list then
		return "No active list."
	end

	local rows = {}
	for itemID, entry in pairs(list.items or {}) do
		if entry then
			local name = entry.name
			if not name or name == "" then
				name = GetItemInfo(tonumber(itemID)) or ("item:" .. tostring(itemID))
			end
			rows[#rows + 1] = {
				itemID = tonumber(itemID) or 0,
				name = name,
				slot = entry.slot or "",
				status = entry.status or "",
			}
		end
	end

	table.sort(rows, function(a, b)
		if a.status ~= b.status then
			local order = { want = 1, upgrade = 2, have = 3, pass = 4 }
			return (order[a.status] or 99) < (order[b.status] or 99)
		end
		if a.slot ~= b.slot then
			return a.slot < b.slot
		end
		return a.name < b.name
	end)

	local lines = {
		tostring(list.name or "Active list"),
		"Character: " .. tostring(list.character and list.character.name or "Unknown"),
		"Phase: " .. tostring(list.phase or "?"),
		"Items: " .. tostring(#rows),
		"",
	}

	local lastStatus
	for i = 1, #rows do
		local row = rows[i]
		if row.status ~= lastStatus then
			lastStatus = row.status
			lines[#lines + 1] = (STATUS_LABELS[lastStatus] or "Unmarked") .. ":"
		end
		local slot = row.slot ~= "" and (" [" .. row.slot .. "]") or ""
		lines[#lines + 1] = "  " .. tostring(row.itemID) .. " - " .. tostring(row.name) .. slot
	end

	return table.concat(lines, "\n")
end

local function createTextFrame(title, buttonText, initialText, onAccept)
	local template = _G.BackdropTemplateMixin and "BackdropTemplate" or nil
	local frame = CreateFrame("Frame", nil, UIParent, template)
	frame:SetSize(560, 420)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	if frame.SetBackdrop then
		frame:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 8, right = 8, top = 8, bottom = 8 },
		})
	end
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	local header = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	header:SetPoint("TOPLEFT", 18, -16)
	header:SetText(title)

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -5, -5)

	local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 18, -44)
	scroll:SetPoint("BOTTOMRIGHT", -34, 54)

	local edit = CreateFrame("EditBox", nil, scroll)
	edit:SetMultiLine(true)
	edit:SetAutoFocus(true)
	edit:SetFontObject(ChatFontNormal)
	edit:SetSize(500, 320)
	edit:SetText(initialText or "")
	if initialText and initialText ~= "" then
		edit:HighlightText()
	end
	edit:SetScript("OnEscapePressed", function() frame:Hide() end)
	scroll:SetScrollChild(edit)
	frame.editBox = edit

	local accept = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	accept:SetSize(110, 24)
	accept:SetPoint("BOTTOMRIGHT", -18, 18)
	accept:SetText(buttonText)
	accept:SetScript("OnClick", function()
		if onAccept then
			onAccept(edit:GetText() or "")
		end
		frame:Hide()
	end)

	frame:Show()
	edit:SetFocus()
	return frame
end

local function getImportTargets()
	local targets = {
		{ key = nil, text = "New List" },
	}
	local lists = Tracker:GetLists()
	for i = 1, #lists do
		local list = lists[i].list
		local char = list.character or {}
		local owner = char.name and (" - " .. char.name) or ""
		targets[#targets + 1] = {
			key = lists[i].key,
			text = tostring(list.name or lists[i].key) .. owner .. " (overwrite)",
		}
	end
	return targets
end

local function createImportFrame()
	local template = _G.BackdropTemplateMixin and "BackdropTemplate" or nil
	local frame = CreateFrame("Frame", nil, UIParent, template)
	frame:SetSize(560, 440)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	if frame.SetBackdrop then
		frame:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 8, right = 8, top = 8, bottom = 8 },
		})
	end
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	local header = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	header:SetPoint("TOPLEFT", 18, -16)
	header:SetText("Import ThatsMyBIS JSON")

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -5, -5)

	local targetKey = nil
	local targetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	targetButton:SetSize(250, 24)
	targetButton:SetPoint("TOPLEFT", 18, -42)
	targetButton:SetText("Target: New List")

	local menuFrame = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
	local function setTarget(key, text)
		targetKey = key
		targetButton:SetText("Target: " .. tostring(text or "New List"))
	end
	targetButton:SetScript("OnClick", function(self)
		local targets = getImportTargets()
		if EasyMenu then
			local menu = {}
			for i = 1, #targets do
				local target = targets[i]
				menu[#menu + 1] = {
					text = target.text,
					checked = target.key == targetKey,
					func = function()
						setTarget(target.key, target.text)
					end,
				}
			end
			EasyMenu(menu, menuFrame, self, 0, 0, "MENU", 2)
			return
		end

		local nextIndex = 1
		for i = 1, #targets do
			if targets[i].key == targetKey then
				nextIndex = i + 1
				break
			end
		end
		if nextIndex > #targets then
			nextIndex = 1
		end
		setTarget(targets[nextIndex].key, targets[nextIndex].text)
	end)

	local hint = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	hint:SetPoint("LEFT", targetButton, "RIGHT", 8, 0)
	hint:SetText("Existing target will be replaced")

	local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 18, -74)
	scroll:SetPoint("BOTTOMRIGHT", -34, 54)

	local edit = CreateFrame("EditBox", nil, scroll)
	edit:SetMultiLine(true)
	edit:SetAutoFocus(true)
	edit:SetFontObject(ChatFontNormal)
	edit:SetSize(500, 300)
	edit:SetScript("OnEscapePressed", function() frame:Hide() end)
	scroll:SetScrollChild(edit)

	local accept = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	accept:SetSize(110, 24)
	accept:SetPoint("BOTTOMRIGHT", -18, 18)
	accept:SetText("Import")
	accept:SetScript("OnClick", function()
		local key, importedOrError, mode = Tracker:ImportThatsMyBis(edit:GetText() or "", targetKey)
		if key then
			msg("Imported " .. tostring(importedOrError or 0) .. " items (" .. tostring(mode or "created") .. ").")
			frame:Hide()
		else
			msg(importedOrError or "Import failed.")
		end
	end)

	frame:Show()
	edit:SetFocus()
	return frame
end

function Tracker:OpenImport()
	createImportFrame()
end

function Tracker:OpenExport()
	local text = self:ExportThatsMyBis()
	if text == "" then
		msg("No active list to export.")
		return
	end
	createTextFrame("Export ThatsMyBIS JSON", "Close", text, nil)
end

function Tracker:OpenExportEquipped()
	local text, count = self:ExportEquippedThatsMyBis()
	if not count or count == 0 then
		msg("No equipped items found to export.")
		return
	end
	createTextFrame("Export Current Equipped JSON", "Close", text, nil)
end

function Tracker:OpenListView()
	createTextFrame("Active TBCA_BIS List", "Close", self:BuildListSummary(), nil)
end

function Tracker:OpenFind()
	createTextFrame("Find Saved Item", "Find", "", function(text)
		self:PrintFindResults(text)
	end)
end

local function playLootAlertSound()
	local sound = (SOUNDKIT and (SOUNDKIT.RAID_WARNING or SOUNDKIT.READY_CHECK or SOUNDKIT.ALARM_CLOCK_WARNING_3)) or 8959
	if PlaySound then
		local ok = pcall(PlaySound, sound, "Master")
		if not ok then
			pcall(PlaySound, sound)
		end
	end
end

local function showLootAlertNotice(text)
	if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo and ChatTypeInfo.RAID_WARNING then
		RaidNotice_AddMessage(RaidWarningFrame, text, ChatTypeInfo.RAID_WARNING)
	elseif UIErrorsFrame and UIErrorsFrame.AddMessage then
		UIErrorsFrame:AddMessage(text, 1, 0.82, 0, 1)
	end
end

local function summarizeLootAlertRows(rows)
	local shown = {}
	local parts = {}
	for i = 1, #rows do
		local row = rows[i]
		if row.status == "want" or row.status == "upgrade" then
			local key = tostring(row.listName or row.listKey or "?") .. ":" .. tostring(row.status)
			if not shown[key] then
				shown[key] = true
				parts[#parts + 1] = tostring(row.listName or row.listKey or "?") .. " - " .. tostring(row.letter or row.label or row.status)
			end
		end
	end
	return parts
end

local lastLootAlertKey, lastLootAlertTime

local function handleLootAlertMessage(text)
	local db = Tracker:EnsureDB()
	if not db.lootAlertEnabled then
		return
	end

	text = tostring(text or "")
	local seenItems = {}
	for link, itemIDText in text:gmatch("(|c%x+|Hitem:(%d+):.-|h%[.-%]|h|r)") do
		local itemID = tonumber(itemIDText)
		if itemID and not seenItems[itemID] then
			seenItems[itemID] = true
			local rows = Tracker:GetItemListStatuses(itemID)
			local matches = summarizeLootAlertRows(rows)
			if #matches > 0 then
				local now = GetTime and GetTime() or time()
				local alertKey = tostring(itemID) .. ":" .. table.concat(matches, ",")
				if alertKey ~= lastLootAlertKey or (now - (lastLootAlertTime or 0)) > 2 then
					lastLootAlertKey = alertKey
					lastLootAlertTime = now
					local chatText = link .. " is on your lists: " .. table.concat(matches, ", ")
					msg("|cffffcc00Loot Alert|r: " .. chatText)
					showLootAlertNotice("TBCA_BIS Loot Alert: " .. (link:match("%[(.-)%]") or ("item " .. itemID)))
					if db.lootAlertSound then
						playLootAlertSound()
					end
				end
			end
		end
	end
end

function Tracker:TestLootAlert(itemID)
	itemID = tonumber(itemID)
	if not itemID then
		msg("Use /bistracker testloot itemID")
		return
	end
	local link = select(2, GetItemInfo(itemID))
	if not link then
		link = "|cffffffff|Hitem:" .. itemID .. ":0:0:0:0:0:0:0:0|h[item " .. itemID .. "]|h|r"
	end
	handleLootAlertMessage("You receive loot: " .. link .. ".")
end

local lootAlertFrame = CreateFrame("Frame")
lootAlertFrame:RegisterEvent("CHAT_MSG_LOOT")
lootAlertFrame:SetScript("OnEvent", function(_, _, text)
	handleLootAlertMessage(text)
end)

SLASH_TBCABISTRACKER1 = "/bistracker"
SLASH_TBCABISTRACKER2 = "/tbis"
SlashCmdList.TBCABISTRACKER = function(input)
	input = trim(input)
	local cmd, rest = input:match("^(%S*)%s*(.-)$")
	cmd = string.lower(cmd or "")
	if cmd == "import" then
		Tracker:OpenImport()
	elseif cmd == "export" then
		Tracker:OpenExport()
	elseif cmd == "exportequipped" or cmd == "equipped" then
		Tracker:OpenExportEquipped()
	elseif cmd == "list" or cmd == "view" then
		if _G.TBCA_BIS_OpenTrackerListPage then
			_G.TBCA_BIS_OpenTrackerListPage()
		else
			Tracker:OpenListView()
		end
	elseif cmd == "new" then
		Tracker:CreateList(rest ~= "" and rest or nil)
	elseif cmd == "delete" or cmd == "del" then
		if not Tracker:DeleteList() then
			msg("No active list to delete.")
		end
	elseif cmd == "want" or cmd == "upgrade" or cmd == "up" or cmd == "have" or cmd == "pass" then
		if cmd == "up" then cmd = "upgrade" end
		local itemID = tonumber(rest)
		if itemID then
			Tracker:SetItemStatus(itemID, cmd)
			msg(STATUS_LABELS[cmd] .. " set for item " .. itemID .. ".")
		else
			msg("Use /bistracker " .. cmd .. " itemID")
		end
	elseif cmd == "clear" then
		local itemID = tonumber(rest)
		if itemID then
			Tracker:ClearItemStatus(itemID)
			msg("Cleared item " .. itemID .. ".")
		else
			msg("Use /bistracker clear itemID")
		end
	elseif cmd == "lootalert" or cmd == "loot" then
		local db = Tracker:EnsureDB()
		rest = string.lower(trim(rest))
		if rest == "on" or rest == "1" then
			db.lootAlertEnabled = true
		elseif rest == "off" or rest == "0" then
			db.lootAlertEnabled = false
		else
			db.lootAlertEnabled = not db.lootAlertEnabled
		end
		msg("Loot Alert " .. (db.lootAlertEnabled and "enabled" or "disabled") .. ".")
	elseif cmd == "lootsound" then
		local db = Tracker:EnsureDB()
		rest = string.lower(trim(rest))
		if rest == "on" or rest == "1" then
			db.lootAlertSound = true
		elseif rest == "off" or rest == "0" then
			db.lootAlertSound = false
		else
			db.lootAlertSound = not db.lootAlertSound
		end
		msg("Loot Alert sound " .. (db.lootAlertSound and "enabled" or "disabled") .. ".")
	elseif cmd == "testloot" then
		Tracker:TestLootAlert(rest)
	else
		local list = Tracker:GetActiveList()
		if list then
			msg("Active list: " .. tostring(list.name) .. ". Commands: list, import, export, new, delete, want, upgrade, have, pass, clear, lootalert, lootsound, testloot.")
		else
			msg("No active list. Use /bistracker new, /bistracker import, or mark an AtlasLoot item.")
		end
	end
end
