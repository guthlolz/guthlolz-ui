local ADDON = ...

local SGS = {}
_G.TBCA_Simple_GearSets = SGS

local SLOT_ORDER = {
	1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 11, 12, 13, 14, 16, 17, 18,
}

local SLOT_LABELS = {
	[1] = "Head", [2] = "Neck", [3] = "Shoulder", [4] = "Shirt", [5] = "Chest",
	[6] = "Waist", [7] = "Legs", [8] = "Feet", [9] = "Wrist", [10] = "Hands",
	[11] = "Ring 1", [12] = "Ring 2", [13] = "Trinket 1", [14] = "Trinket 2",
	[15] = "Back", [16] = "Main Hand", [17] = "Off Hand", [18] = "Ranged", [19] = "Tabard",
}

local SLOT_NAMES = {
	[1] = "HeadSlot", [2] = "NeckSlot", [3] = "ShoulderSlot", [4] = "ShirtSlot",
	[5] = "ChestSlot", [6] = "WaistSlot", [7] = "LegsSlot", [8] = "FeetSlot",
	[9] = "WristSlot", [10] = "HandsSlot", [11] = "Finger0Slot", [12] = "Finger1Slot",
	[13] = "Trinket0Slot", [14] = "Trinket1Slot", [15] = "BackSlot",
	[16] = "MainHandSlot", [17] = "SecondaryHandSlot", [18] = "RangedSlot", [19] = "TabardSlot",
}

local EQUIP_LOCS = {
	INVTYPE_HEAD = { 1 },
	INVTYPE_NECK = { 2 },
	INVTYPE_SHOULDER = { 3 },
	INVTYPE_BODY = { 4 },
	INVTYPE_CHEST = { 5 },
	INVTYPE_ROBE = { 5 },
	INVTYPE_WAIST = { 6 },
	INVTYPE_LEGS = { 7 },
	INVTYPE_FEET = { 8 },
	INVTYPE_WRIST = { 9 },
	INVTYPE_HAND = { 10 },
	INVTYPE_FINGER = { 11, 12 },
	INVTYPE_TRINKET = { 13, 14 },
	INVTYPE_CLOAK = { 15 },
	INVTYPE_WEAPON = { 16, 17 },
	INVTYPE_WEAPONMAINHAND = { 16 },
	INVTYPE_WEAPONOFFHAND = { 17 },
	INVTYPE_2HWEAPON = { 16 },
	INVTYPE_SHIELD = { 17 },
	INVTYPE_HOLDABLE = { 17 },
	INVTYPE_RANGED = { 18 },
	INVTYPE_RANGEDRIGHT = { 18 },
	INVTYPE_THROWN = { 18 },
	INVTYPE_RELIC = { 18 },
}

local db, frame, charButton, charMenu, selectedSet, selectedSlot, draftSet, charStrip
local setRows, slotButtons, choiceRows = {}, {}, {}
local specFrame, lastTalentGroup, pendingTalentGroup, pendingSince
local GetCurrentSet, TryTalentAutomation
local charStripHideToken = 0

local function Print(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99TBCA GearSets|r: " .. tostring(msg or ""))
	end
end

local function IsEnabled()
	if Unforvegan_BISDB and Unforvegan_BISDB.simpleGearSetsEnabled == false then
		return false
	end
	return true
end

function _G.TBCA_Simple_GearSets_IsEnabled()
	return IsEnabled()
end

local function GetCharKey()
	local name = UnitName("player") or "Unknown"
	local realm = GetRealmName() or "Realm"
	return realm .. "-" .. name
end

local function EnsureDB()
	TBCASimpleGearSetsDB = TBCASimpleGearSetsDB or {}
	TBCASimpleGearSetsDB.characters = TBCASimpleGearSetsDB.characters or {}
	local key = GetCharKey()
	TBCASimpleGearSetsDB.characters[key] = TBCASimpleGearSetsDB.characters[key] or {}
	db = TBCASimpleGearSetsDB.characters[key]
	db.sets = db.sets or {}
	db.triggers = db.triggers or {}
	db.ui = db.ui or {}
	return db
end

local function GetBagSlots(bag)
	if C_Container and C_Container.GetContainerNumSlots then
		return C_Container.GetContainerNumSlots(bag) or 0
	end
	return GetContainerNumSlots and GetContainerNumSlots(bag) or 0
end

local function GetBagLink(bag, slot)
	if C_Container and C_Container.GetContainerItemLink then
		return C_Container.GetContainerItemLink(bag, slot)
	end
	return GetContainerItemLink and GetContainerItemLink(bag, slot) or nil
end

local function UseBagItem(bag, slot)
	if C_Container and C_Container.UseContainerItem then
		C_Container.UseContainerItem(bag, slot)
	elseif UseContainerItem then
		UseContainerItem(bag, slot)
	end
end

local function PickupBagItem(bag, slot)
	if C_Container and C_Container.PickupContainerItem then
		C_Container.PickupContainerItem(bag, slot)
		return true
	elseif PickupContainerItem then
		PickupContainerItem(bag, slot)
		return true
	end
	return false
end

local function EquipBagItemToSlot(bag, slot, slotID)
	if not bag or not slot then return false end
	if not slotID or not EquipCursorItem then
		UseBagItem(bag, slot)
		return true
	end
	if GetCursorInfo and GetCursorInfo() then
		Print("Clear your cursor before equipping a gear set.")
		return false
	end
	if not PickupBagItem(bag, slot) then
		UseBagItem(bag, slot)
		return true
	end
	if GetCursorInfo and not GetCursorInfo() then
		return false
	end
	EquipCursorItem(slotID)
	return true
end

local function GetItemID(link)
	if not link then return nil end
	return tonumber(tostring(link):match("item:(%d+)"))
end

local function GetItemString(link)
	if not link then return nil end
	return tostring(link):match("|H(item:[^|]+)|h") or tostring(link):match("^(item:[^|]+)")
end

local function GetLinkFromItemString(itemString)
	if not itemString or itemString == "" then return nil end
	return select(2, GetItemInfo(itemString)) or ("|cffffffff|H" .. itemString .. "|h[" .. itemString .. "]|h|r")
end

local function GetSlotTexture(slotID, itemString)
	if itemString and itemString ~= "" then
		local icon = select(10, GetItemInfo(itemString))
		if icon then return icon end
	end
	local _, texture = GetInventorySlotInfo(SLOT_NAMES[slotID] or "")
	return texture or "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
end

local function ItemCanUseSlot(link, slotID)
	if not link then return false end
	local equipLoc = select(9, GetItemInfo(link))
	local slots = equipLoc and EQUIP_LOCS[equipLoc]
	if not slots then return false end
	for _, sid in ipairs(slots) do
		if sid == slotID then return true end
	end
	return false
end

local function ScanChoices(slotID, includeEquipped)
	local out, seen = {}, {}
	if includeEquipped then
		local link = GetInventoryItemLink("player", slotID)
		-- An item already worn in this exact slot is valid even if GetItemInfo
		-- has not finished caching its equip-location metadata yet.
		if link then
			local itemString = GetItemString(link)
			local key = itemString or link
			if key then
				seen[key] = true
				out[#out + 1] = {
					link = link,
					itemString = itemString,
					id = GetItemID(link) or 0,
					equipped = true,
				}
			end
		end
	end
	for bag = 0, 4 do
		for slot = 1, GetBagSlots(bag) do
			local link = GetBagLink(bag, slot)
			if link and ItemCanUseSlot(link, slotID) then
				local itemString = GetItemString(link)
				local key = itemString or link
				if key and not seen[key] then
					seen[key] = true
					out[#out + 1] = { link = link, itemString = itemString, bag = bag, slot = slot, id = GetItemID(link) or 0 }
				end
			end
		end
	end
	table.sort(out, function(a, b)
		if a.equipped ~= b.equipped then return a.equipped and true or false end
		local qa = select(3, GetItemInfo(a.link)) or 0
		local qb = select(3, GetItemInfo(b.link)) or 0
		if qa ~= qb then return qa > qb end
		return tostring(a.link) < tostring(b.link)
	end)
	return out
end

local function Snapshot()
	local slots = {}
	for _, slotID in ipairs(SLOT_ORDER) do
		local link = GetInventoryItemLink("player", slotID)
		slots[tostring(slotID)] = GetItemString(link) or ""
	end
	return slots
end

local function CopySlots(slots)
	local out = {}
	for key, value in pairs(slots or {}) do
		out[tostring(key)] = value or ""
	end
	return out
end

local function CreateDraftFromSet(name)
	EnsureDB()
	local source = name and db.sets[name]
	if source then
		selectedSet = name
		draftSet = {
			name = name,
			sourceName = name,
			slots = CopySlots(source.slots),
			isDraft = true,
		}
	else
		selectedSet = nil
		draftSet = {
			name = "Unsaved Gear Set",
			slots = Snapshot(),
			isDraft = true,
		}
	end
	return draftSet
end

local function SortedSetNames()
	local names = {}
	for name in pairs((EnsureDB()).sets) do names[#names + 1] = name end
	table.sort(names, function(a, b) return tostring(a):lower() < tostring(b):lower() end)
	return names
end

local function FindBagItem(itemString)
	if not itemString or itemString == "" then return nil end
	local wantID = GetItemID(itemString)
	for bag = 0, 4 do
		for slot = 1, GetBagSlots(bag) do
			local link = GetBagLink(bag, slot)
			if link then
				local str = GetItemString(link)
				if str == itemString or (wantID and GetItemID(link) == wantID) then
					return bag, slot
				end
			end
		end
	end
	return nil
end

local function SetTriggerForSet(setName, trigger)
	EnsureDB()
	for key, owner in pairs(db.triggers) do
		if owner == setName then db.triggers[key] = nil end
	end
	if trigger == "spec1" or trigger == "spec2" then
		db.triggers[trigger] = setName
	end
end

local function GetTriggerForSet(setName)
	EnsureDB()
	if db.triggers.spec1 == setName then return "spec1" end
	if db.triggers.spec2 == setName then return "spec2" end
	return "none"
end

local function EquipSlots(slots, label)
	if not IsEnabled() then
		Print("Enable TBCA Simple GearSets in TBCA_BIS options first.")
		return
	end
	if InCombatLockdown and InCombatLockdown() then
		Print("Cannot equip while in combat.")
		return
	end
	for _, slotID in ipairs(SLOT_ORDER) do
		local itemString = slots and slots[tostring(slotID)]
		if itemString and itemString ~= "" then
			local equipped = GetItemString(GetInventoryItemLink("player", slotID))
			if equipped ~= itemString then
				local bag, slot = FindBagItem(itemString)
				if bag and slot then
					EquipBagItemToSlot(bag, slot, slotID)
				end
			end
		end
	end
	Print("Equipping " .. tostring(label or "gear set") .. ".")
end

local function EquipSet(setName)
	EnsureDB()
	local set = db.sets[setName]
	if not set then return end
	EquipSlots(set.slots, setName)
end

local function OpenSetMenu(anchor)
	EnsureDB()
	if not EasyMenu then
		SGS.Toggle()
		return
	end
	if not charMenu then
		charMenu = CreateFrame("Frame", "TBCASimpleGearSetsSetMenu", UIParent, "UIDropDownMenuTemplate")
	end
	local menu = {
		{ text = "TBCA Simple GearSets", isTitle = true, notCheckable = true },
	}
	local names = SortedSetNames()
	if #names == 0 then
		menu[#menu + 1] = { text = "No saved sets", disabled = true, notCheckable = true }
	else
		for _, name in ipairs(names) do
			local setName = name
			menu[#menu + 1] = {
				text = setName,
				notCheckable = true,
				func = function()
					EquipSet(setName)
				end,
			}
		end
	end
	menu[#menu + 1] = { text = "Open Manager", notCheckable = true, func = SGS.Toggle }
	EasyMenu(menu, charMenu, anchor, 0, 0, "MENU")
end

local function SaveSlots(name, slots, message)
	EnsureDB()
	name = tostring(name or ""):match("^%s*(.-)%s*$")
	if name == "" then return end
	db.sets[name] = db.sets[name] or {}
	db.sets[name].name = name
	db.sets[name].slots = CopySlots(slots or {})
	selectedSet = name
	CreateDraftFromSet(name)
	Print((message or "Saved ") .. name .. ".")
end

local function SaveCurrent(name)
	local working = GetCurrentSet()
	SaveSlots(name, (working and working.slots) or Snapshot())
end

local function SaveEquipped(name)
	SaveSlots(name, Snapshot(), "Saved equipped gear as ")
end

local function DeleteSet(name)
	EnsureDB()
	if not name or not db.sets[name] then return end
	db.sets[name] = nil
	for key, owner in pairs(db.triggers) do
		if owner == name then db.triggers[key] = nil end
	end
	if selectedSet == name then selectedSet = nil end
	Print("Deleted " .. name .. ".")
end

local function SetSlot(setName, slotID, itemString)
	EnsureDB()
	if draftSet and (setName == draftSet.name or setName == draftSet.sourceName) then
		draftSet.slots = draftSet.slots or {}
		draftSet.slots[tostring(slotID)] = itemString or ""
		return
	end
	local set = db.sets[setName]
	if not set then return end
	set.slots = set.slots or {}
	set.slots[tostring(slotID)] = itemString or ""
end

GetCurrentSet = function()
	EnsureDB()
	if draftSet then
		return draftSet
	end
	if selectedSet and db.sets[selectedSet] then return CreateDraftFromSet(selectedSet) end
	local names = SortedSetNames()
	selectedSet = names[1]
	if selectedSet and db.sets[selectedSet] then
		return CreateDraftFromSet(selectedSet)
	end
	return CreateDraftFromSet(nil)
end

local function ButtonText(btn, text)
	if btn and btn.SetText then btn:SetText(text or "") end
end

local function CreateButton(parent, text, w, h)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(w, h)
	b:SetText(text)
	return b
end

local function HideCharacterStrip()
	charStripHideToken = charStripHideToken + 1
	if charStrip then
		charStrip.hovering = false
		charStrip.slotHovering = false
		charStrip:Hide()
	end
end

local function ScheduleHideCharacterStrip()
	charStripHideToken = charStripHideToken + 1
	local token = charStripHideToken
	if not C_Timer or not C_Timer.After then
		if charStrip and not charStrip.hovering and not charStrip.slotHovering then charStrip:Hide() end
		return
	end
	C_Timer.After(0.18, function()
		if token == charStripHideToken and charStrip and not charStrip.hovering and not charStrip.slotHovering then
			charStrip:Hide()
		end
	end)
end

local function EnsureCharacterStrip()
	if charStrip then return charStrip end
	charStrip = CreateFrame("Frame", "TBCASimpleGearSetsCharacterStrip", UIParent, "BackdropTemplate")
	charStrip:SetFrameStrata("TOOLTIP")
	charStrip:SetFrameLevel(2000)
	charStrip:SetSize(1, 44)
	charStrip:SetClampedToScreen(true)
	charStrip:EnableMouse(true)
	charStrip.hovering = false
	charStrip.slotHovering = false
	charStrip:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	charStrip:SetBackdropColor(0, 0, 0, 0.95)
	charStrip.buttons = {}
	charStrip:SetScript("OnEnter", function(self)
		self.hovering = true
		charStripHideToken = charStripHideToken + 1
	end)
	charStrip:SetScript("OnLeave", function(self)
		self.hovering = false
		ScheduleHideCharacterStrip()
	end)
	charStrip:Hide()
	return charStrip
end

local function ShowCharacterSlotChoices(anchor, slotID, silent)
	if not IsEnabled() then return end
	local choices = ScanChoices(slotID)
	if #choices == 0 then
		if not silent then Print("No bag items for " .. (SLOT_LABELS[slotID] or "slot") .. ".") end
		return
	end
	local strip = EnsureCharacterStrip()
	charStripHideToken = charStripHideToken + 1
	strip.slotHovering = true
	for _, btn in ipairs(strip.buttons) do btn:Hide() end
	local count = math.min(#choices, 12)
	strip:SetSize(8 + (count * 38), 44)
	strip:ClearAllPoints()
	strip:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 8, 0)
	strip:Show()
	if strip:GetRight() and UIParent:GetRight() and strip:GetRight() > UIParent:GetRight() - 10 then
		strip:ClearAllPoints()
		strip:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -8, 0)
	end
	if strip:GetBottom() and UIParent:GetBottom() and strip:GetBottom() < UIParent:GetBottom() + 10 then
		strip:ClearAllPoints()
		strip:SetPoint("BOTTOMLEFT", anchor, "TOPRIGHT", 8, 0)
	end
	for i = 1, count do
		local btn = strip.buttons[i]
		if not btn then
			btn = CreateFrame("Button", nil, strip)
			btn:SetSize(34, 34)
			btn.icon = btn:CreateTexture(nil, "ARTWORK")
			btn.icon:SetAllPoints()
			btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
			btn:SetScript("OnEnter", function(self)
				strip.hovering = true
				charStripHideToken = charStripHideToken + 1
				if self.link then
					local stripCenter = strip:GetCenter() or 0
					local screenCenter = (UIParent:GetWidth() or 0) / 2
					GameTooltip:SetOwner(self, "ANCHOR_NONE")
					GameTooltip:ClearAllPoints()
					if stripCenter >= screenCenter then
						GameTooltip:SetPoint("TOPRIGHT", strip, "TOPLEFT", -8, 0)
					else
						GameTooltip:SetPoint("TOPLEFT", strip, "TOPRIGHT", 8, 0)
					end
					GameTooltip:SetHyperlink(self.link)
					GameTooltip:Show()
				end
			end)
			btn:SetScript("OnLeave", function()
				strip.hovering = false
				GameTooltip:Hide()
				ScheduleHideCharacterStrip()
			end)
			strip.buttons[i] = btn
		end
		local choice = choices[i]
		btn:SetPoint("LEFT", strip, "LEFT", 5 + ((i - 1) * 38), 0)
		btn.link = choice.link
		btn.icon:SetTexture(select(10, GetItemInfo(choice.link)) or "Interface\\Icons\\INV_Misc_QuestionMark")
		btn:SetScript("OnClick", function(self)
			if InCombatLockdown and InCombatLockdown() then
				Print("Cannot equip while in combat.")
				return
			end
			EquipBagItemToSlot(choice.bag, choice.slot, slotID)
			strip:Hide()
		end)
		btn:Show()
	end
end

local function RefreshChoices()
	if not frame then return end
	local set = GetCurrentSet()
	frame.choiceTitle:SetText(selectedSlot and (SLOT_LABELS[selectedSlot] .. " Choices") or "Item Choices")
	for _, row in ipairs(choiceRows) do row:Hide() end
	if not selectedSlot then
		frame.choiceHint:SetText("Select a slot.")
		return
	end
	frame.choiceHint:SetText("")
	local choices = ScanChoices(selectedSlot, true)
	for i = 1, math.min(#choices, 12) do
		local row = choiceRows[i]
		if not row then
			row = CreateFrame("Button", nil, frame.choicePanel)
			row:SetSize(220, 28)
			row.icon = row:CreateTexture(nil, "ARTWORK")
			row.icon:SetSize(22, 22)
			row.icon:SetPoint("LEFT", 2, 0)
			row.text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
			row.text:SetPoint("RIGHT", -4, 0)
			row.text:SetJustifyH("LEFT")
			row:SetScript("OnEnter", function(self)
				if self.link then
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:SetHyperlink(self.link)
					GameTooltip:Show()
				end
			end)
			row:SetScript("OnLeave", function() GameTooltip:Hide() end)
			choiceRows[i] = row
		end
		local choice = choices[i]
		row:SetPoint("TOPLEFT", frame.choicePanel, "TOPLEFT", 8, -34 - ((i - 1) * 30))
		row.link = choice.link
		row.itemString = choice.itemString
		row.icon:SetTexture(select(10, GetItemInfo(choice.link)) or "Interface\\Icons\\INV_Misc_QuestionMark")
		local choiceName = (choice.link and choice.link:match("|h%[(.-)%]|h")) or ("item:" .. tostring(choice.id))
		if choice.equipped then choiceName = choiceName .. " |cff80ff80(Equipped)|r" end
		row.text:SetText(choiceName)
		row:SetScript("OnClick", function(self)
			if set and selectedSlot then
				SetSlot(set.name, selectedSlot, self.itemString)
				SGS.Refresh()
			end
		end)
		row:Show()
	end
	if #choices == 0 then
		frame.choiceHint:SetText("No bag items for this slot.")
	else
		frame.choiceHint:SetText("")
	end
end

local function RefreshSlots()
	if not frame then return end
	local set = GetCurrentSet()
	for _, slotID in ipairs(SLOT_ORDER) do
		local btn = slotButtons[slotID]
		if btn then
			local itemString = set and set.slots and set.slots[tostring(slotID)] or ""
			local link = GetLinkFromItemString(itemString)
			btn.icon:SetTexture(GetSlotTexture(slotID, itemString))
			btn.name:SetText(SLOT_LABELS[slotID] or tostring(slotID))
			btn.item:SetText(link and (link:match("|h%[(.-)%]|h") or itemString) or "Empty")
			if selectedSlot == slotID then
				btn:SetBackdropBorderColor(1, 0.82, 0, 1)
			else
				btn:SetBackdropBorderColor(0.1, 0.45, 0.9, 0.8)
			end
		end
	end
end

local function RefreshSets()
	if not frame then return end
	local names = SortedSetNames()
	for _, row in ipairs(setRows) do row:Hide() end
	for i = 1, math.min(#names, 12) do
		local row = setRows[i]
		if not row then
			row = CreateButton(frame.setPanel, "", 145, 22)
			setRows[i] = row
		end
		local name = names[i]
		row:SetPoint("TOPLEFT", frame.setPanel, "TOPLEFT", 8, -34 - ((i - 1) * 25))
		row:SetText(name)
		row:SetScript("OnClick", function()
			CreateDraftFromSet(name)
			selectedSlot = selectedSlot or 1
			SGS.Refresh()
		end)
		if name == selectedSet then row:LockHighlight() else row:UnlockHighlight() end
		row:Show()
	end
	frame.emptySets:SetShown(#names == 0)
end

local function RefreshAutomation()
	if not frame then return end
	local set = GetCurrentSet()
	local triggerName = set and (set.sourceName or set.name)
	local trigger = triggerName and GetTriggerForSet(triggerName) or "none"
	local canAutomate = (triggerName and db and db.sets and db.sets[triggerName]) and true or false
	frame.autoNone:SetChecked(trigger == "none")
	frame.autoPrimary:SetChecked(trigger == "spec1")
	frame.autoSecondary:SetChecked(trigger == "spec2")
	frame.autoNone:SetEnabled(canAutomate and true or false)
	frame.autoPrimary:SetEnabled(canAutomate and true or false)
	frame.autoSecondary:SetEnabled(canAutomate and true or false)
end

function SGS.Refresh()
	if not frame then return end
	local set = GetCurrentSet()
	frame.title:SetText("TBCA Simple GearSets")
	frame.activeName:SetText(set and set.name or "Unsaved Gear Set")
	RefreshSets()
	RefreshSlots()
	RefreshChoices()
	RefreshAutomation()
end

local function CreateSlot(parent, slotID, x, y)
	local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
	btn:SetSize(154, 36)
	btn:SetPoint("TOPLEFT", x, y)
	btn:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	btn:SetBackdropColor(0, 0, 0, 0.92)
	btn:SetBackdropBorderColor(0.1, 0.45, 0.9, 0.8)
	btn.icon = btn:CreateTexture(nil, "ARTWORK")
	btn.icon:SetSize(28, 28)
	btn.icon:SetPoint("LEFT", 5, 0)
	btn.name = btn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	btn.name:SetPoint("TOPLEFT", btn.icon, "TOPRIGHT", 6, -2)
	btn.item = btn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	btn.item:SetPoint("TOPLEFT", btn.name, "BOTTOMLEFT", 0, -2)
	btn.item:SetPoint("RIGHT", -4, 0)
	btn.item:SetJustifyH("LEFT")
	btn:SetScript("OnClick", function()
		selectedSlot = slotID
		SGS.Refresh()
	end)
	btn:SetScript("OnEnter", function(self)
		local set = GetCurrentSet()
		local itemString = set and set.slots and set.slots[tostring(slotID)]
		if itemString and itemString ~= "" then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetHyperlink(itemString)
			GameTooltip:Show()
		end
	end)
	btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
	slotButtons[slotID] = btn
	return btn
end

local function CreateManager()
	if frame then return end
	frame = CreateFrame("Frame", "TBCASimpleGearSetsFrame", UIParent, "BackdropTemplate")
	frame:SetSize(820, 520)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 10, right = 10, top = 10, bottom = 10 },
	})
	frame:Hide()

	frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	frame.title:SetPoint("TOP", 0, -18)
	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -7, -7)

	frame.setPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.setPanel:SetSize(170, 405)
	frame.setPanel:SetPoint("TOPLEFT", 18, -55)
	frame.setPanel:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
	frame.setPanel:SetBackdropColor(0, 0, 0, 0.9)
	local setsTitle = frame.setPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	setsTitle:SetPoint("TOPLEFT", 8, -10)
	setsTitle:SetText("Saved Sets")
	frame.emptySets = frame.setPanel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
	frame.emptySets:SetPoint("TOPLEFT", 10, -40)
	frame.emptySets:SetText("No sets yet.")

	frame.activeName = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	frame.activeName:SetPoint("TOPLEFT", 210, -58)

	local leftX, rightX, topY, stepY = 210, 375, -88, -40
	for i, slotID in ipairs(SLOT_ORDER) do
		local col = (i <= 9) and leftX or rightX
		local row = (i <= 9) and i or (i - 9)
		CreateSlot(frame, slotID, col, topY + ((row - 1) * stepY))
	end

	frame.choicePanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.choicePanel:SetSize(235, 405)
	frame.choicePanel:SetPoint("TOPRIGHT", -18, -55)
	frame.choicePanel:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
	frame.choicePanel:SetBackdropColor(0, 0, 0, 0.9)
	frame.choiceTitle = frame.choicePanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	frame.choiceTitle:SetPoint("TOPLEFT", 8, -10)
	frame.choiceHint = frame.choicePanel:CreateFontString(nil, "ARTWORK", "GameFontDisable")
	frame.choiceHint:SetPoint("TOPLEFT", 8, -40)

	local save = CreateButton(frame, "Save", 105, 23)
	save:SetPoint("BOTTOMLEFT", 22, 24)
	save:SetScript("OnClick", function()
		StaticPopup_Show("TBCA_SIMPLE_GEARSETS_SAVE")
	end)
	local equip = CreateButton(frame, "Equip", 70, 23)
	equip:SetPoint("LEFT", save, "RIGHT", 8, 0)
	equip:SetScript("OnClick", function()
		local set = GetCurrentSet()
		if set then EquipSlots(set.slots, set.name) end
	end)
	local delete = CreateButton(frame, "Delete", 70, 23)
	delete:SetPoint("LEFT", equip, "RIGHT", 8, 0)
	delete:SetScript("OnClick", function()
		local set = GetCurrentSet()
		if set then DeleteSet(set.name); SGS.Refresh() end
	end)
	local clearSlot = CreateButton(frame, "Clear Slot", 78, 23)
	clearSlot:SetPoint("LEFT", delete, "RIGHT", 8, 0)
	clearSlot:SetScript("OnClick", function()
		local set = GetCurrentSet()
		if set and selectedSlot then SetSlot(set.name, selectedSlot, ""); SGS.Refresh() end
	end)
	local newDraft = CreateButton(frame, "New Draft", 82, 23)
	newDraft:SetPoint("BOTTOMLEFT", 22, 52)
	newDraft:SetScript("OnClick", function()
		draftSet = { name = "Unsaved Gear Set", slots = Snapshot(), isDraft = true }
		selectedSet = nil
		selectedSlot = selectedSlot or 1
		SGS.Refresh()
	end)
	local saveEquipped = CreateButton(frame, "Save Equipped", 112, 23)
	saveEquipped:SetPoint("LEFT", newDraft, "RIGHT", 8, 0)
	saveEquipped:SetScript("OnClick", function()
		StaticPopup_Show("TBCA_SIMPLE_GEARSETS_SAVE_EQUIPPED")
	end)

	local function AutoCheck(label, x, key)
		local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
		cb:SetPoint("BOTTOMLEFT", x, 22)
		cb:SetHitRectInsets(0, -55, 0, 0)
		cb.label = cb:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		cb.label:SetPoint("LEFT", cb, "RIGHT", -2, 1)
		cb.label:SetText(label)
		cb:SetScript("OnClick", function()
			local set = GetCurrentSet()
			local triggerName = set and (set.sourceName or set.name)
			if triggerName and db and db.sets and db.sets[triggerName] then
				SetTriggerForSet(triggerName, key)
			else
				Print("Save this gear set before assigning Primary or Secondary.")
			end
			SGS.Refresh()
		end)
		return cb
	end
	frame.autoNone = AutoCheck("Manual", 430, "none")
	frame.autoPrimary = AutoCheck("Primary", 510, "spec1")
	frame.autoSecondary = AutoCheck("Secondary", 595, "spec2")
end

function SGS.Toggle()
	if not IsEnabled() then
		Print("Enable TBCA Simple GearSets in TBCA_BIS options first.")
		return
	end
	EnsureDB()
	CreateManager()
	if frame:IsShown() then
		frame:Hide()
	else
		selectedSlot = selectedSlot or 1
		GetCurrentSet()
		frame:Show()
		SGS.Refresh()
	end
end

function SGS.Hide()
	if frame then frame:Hide() end
end

function _G.TBCA_Simple_GearSets_SetEnabled(enabled)
	Unforvegan_BISDB = Unforvegan_BISDB or {}
	Unforvegan_BISDB.simpleGearSetsEnabled = enabled and true or false
	if not enabled then SGS.Hide() end
	if charButton then charButton:SetShown(enabled and true or false) end
end

StaticPopupDialogs["TBCA_SIMPLE_GEARSETS_SAVE"] = {
	text = "Save gear set as:",
	button1 = "Save",
	button2 = "Cancel",
	hasEditBox = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	OnShow = function(self)
		local editBox = self.editBox or self.EditBox or (self.GetEditBox and self:GetEditBox())
		if editBox then
			local name = (draftSet and (draftSet.sourceName or draftSet.name)) or selectedSet or "New Set"
			if name == "Unsaved Gear Set" then name = "New Set" end
			editBox:SetText(name)
			editBox:HighlightText()
			editBox:SetFocus()
		end
	end,
	OnAccept = function(self)
		local editBox = self.editBox or self.EditBox or (self.GetEditBox and self:GetEditBox())
		SaveCurrent(editBox and editBox:GetText() or "New Set")
		SGS.Refresh()
	end,
	EditBoxOnEnterPressed = function(self)
		SaveCurrent(self:GetText())
		self:GetParent():Hide()
		SGS.Refresh()
	end,
}

StaticPopupDialogs["TBCA_SIMPLE_GEARSETS_SAVE_EQUIPPED"] = {
	text = "Save currently equipped gear as:",
	button1 = "Save",
	button2 = "Cancel",
	hasEditBox = true,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	OnShow = function(self)
		local editBox = self.editBox or self.EditBox or (self.GetEditBox and self:GetEditBox())
		if editBox then
			editBox:SetText(selectedSet or "Equipped Set")
			editBox:HighlightText()
			editBox:SetFocus()
		end
	end,
	OnAccept = function(self)
		local editBox = self.editBox or self.EditBox or (self.GetEditBox and self:GetEditBox())
		SaveEquipped(editBox and editBox:GetText() or "Equipped Set")
		SGS.Refresh()
	end,
	EditBoxOnEnterPressed = function(self)
		SaveEquipped(self:GetText())
		self:GetParent():Hide()
		SGS.Refresh()
	end,
}

local function CreateCharacterButton()
	if charButton or not CharacterFrame or not PaperDollFrame then return end
	charButton = CreateFrame("Button", "TBCASimpleGearSetsCharacterButton", PaperDollFrame, "UIPanelButtonTemplate")
	charButton:SetSize(26, 26)
	charButton:SetPoint("TOPRIGHT", PaperDollFrame, "TOPRIGHT", -65, -45)
	charButton:SetFrameLevel((PaperDollFrame:GetFrameLevel() or 1) + 10)
	local icon = charButton:CreateTexture(nil, "ARTWORK")
	icon:SetSize(18, 18)
	icon:SetPoint("CENTER")
	icon:SetTexture((GetItemIcon and GetItemIcon(31339)) or "Interface\\Icons\\INV_Misc_QuestionMark")
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	charButton:RegisterForClicks("AnyUp")
	charButton:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			OpenSetMenu(self)
		else
			SGS.Toggle()
		end
	end)
	charButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText("TBCA Simple GearSets", 1, 1, 1)
		GameTooltip:AddLine("Left-click: open manager", 0.9, 0.9, 0.9)
		GameTooltip:AddLine("Right-click: switch saved set", 0.9, 0.9, 0.9)
		GameTooltip:AddLine("Alt-click a character slot for quick item choices", 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)
	charButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
	charButton:SetShown(IsEnabled())
end

local function HookCharacterSlots()
	if not CharacterFrame or CharacterFrame.__tbcaSimpleGearSetsSlotsHooked then return end
	CharacterFrame.__tbcaSimpleGearSetsSlotsHooked = true
	for _, slotID in ipairs(SLOT_ORDER) do
		local slotName = SLOT_NAMES[slotID]
		local button = slotName and _G["Character" .. slotName]
		if button and button.HookScript then
			button:HookScript("OnLeave", function()
				if charStrip then
					charStrip.slotHovering = false
					ScheduleHideCharacterStrip()
				end
			end)
			button:HookScript("OnMouseUp", function(self, mouseButton)
				if mouseButton == "LeftButton" and IsAltKeyDown and IsAltKeyDown() then
					ShowCharacterSlotChoices(self, slotID)
				end
			end)
			button:HookScript("OnHide", HideCharacterStrip)
		end
	end
	if PaperDollFrame and PaperDollFrame.HookScript then
		PaperDollFrame:HookScript("OnHide", HideCharacterStrip)
	end
end

local function GetTalentGroup()
	if GetActiveTalentGroup then
		local ok, group = pcall(GetActiveTalentGroup)
		if ok then return group end
	end
	return nil
end

local function ScheduleTalentAutomation(delay)
	if not C_Timer or not C_Timer.After then return end
	C_Timer.After(delay or 0.6, function()
		if TryTalentAutomation then TryTalentAutomation() end
	end)
end

TryTalentAutomation = function()
	if not IsEnabled() then return end
	if not pendingTalentGroup then return end
	if InCombatLockdown and InCombatLockdown() then return end
	if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return end
	if GetTime and (GetTime() - pendingSince) < 0.4 then
		ScheduleTalentAutomation(0.6)
		return
	end
	EnsureDB()
	local key = pendingTalentGroup == 2 and "spec2" or "spec1"
	local setName = db.triggers[key]
	pendingTalentGroup = nil
	if setName then EquipSet(setName) end
end

local function NoteTalentGroupChange()
	local group = GetTalentGroup()
	if group and group ~= lastTalentGroup then
		lastTalentGroup = group
		pendingTalentGroup = group
		pendingSince = GetTime and GetTime() or 0
		ScheduleTalentAutomation(0.6)
		ScheduleTalentAutomation(1.5)
	end
end

specFrame = CreateFrame("Frame")
specFrame:RegisterEvent("PLAYER_LOGIN")
specFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
specFrame:RegisterEvent("ADDON_LOADED")
specFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
specFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
specFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
specFrame:SetScript("OnEvent", function(_, event)
	if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
		EnsureDB()
		CreateCharacterButton()
		HookCharacterSlots()
		lastTalentGroup = lastTalentGroup or GetTalentGroup()
		TryTalentAutomation()
		return
	end
	if event == "ACTIVE_TALENT_GROUP_CHANGED" then
		NoteTalentGroupChange()
		TryTalentAutomation()
	elseif event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_REGEN_ENABLED" then
		NoteTalentGroupChange()
		TryTalentAutomation()
	end
end)

SLASH_TBCA_SIMPLE_GEARSETS1 = "/tbcasets"
SLASH_TBCA_SIMPLE_GEARSETS2 = "/sgs"
SlashCmdList.TBCA_SIMPLE_GEARSETS = function(msg)
	msg = tostring(msg or ""):match("^%s*(.-)%s*$")
	if msg ~= "" and msg:lower():match("^saveequipped%s+") then
		SaveEquipped(msg:match("^%S+%s+(.+)$"))
		if frame and frame:IsShown() then SGS.Refresh() end
		return
	end
	if msg ~= "" and msg:lower():match("^save%s+") then
		SaveCurrent(msg:match("^%S+%s+(.+)$"))
		if frame and frame:IsShown() then SGS.Refresh() end
		return
	end
	SGS.Toggle()
end
