local DEFAULT_SETTINGS = {
	settingsVersion = 6,
	maxPhase = 4,
	hitCapped = false,
	showPercent = true,
	showDropRates = false,
	minimap = false,
	minimapAngle = nil,
	showInspect = true,
	debugInspect = false,
	inspectMovable = false,
	simpleGearSetsEnabled = true,
	inspectPanelX = nil,
	inspectPanelY = nil,
}

local PHASE_4_FORCE_VERSION = 1

Unforvegan_BISDB = Unforvegan_BISDB or {}
local storedSettingsVersion = tonumber(Unforvegan_BISDB.settingsVersion) or 0
if storedSettingsVersion < DEFAULT_SETTINGS.settingsVersion then
	Unforvegan_BISDB.settingsVersion = DEFAULT_SETTINGS.settingsVersion
end
if Unforvegan_BISDB.simpleGearSetsEnabled == nil and Unforvegan_BISDB.simpleRackEnabled ~= nil then
	Unforvegan_BISDB.simpleGearSetsEnabled = Unforvegan_BISDB.simpleRackEnabled
end
for k, v in pairs(DEFAULT_SETTINGS) do
	if Unforvegan_BISDB[k] == nil then
		Unforvegan_BISDB[k] = v
	end
end

local function applyPhase4ForceMigration()
	local appliedVersion = tonumber(Unforvegan_BISDB.phase4ForcedMigrationVersion) or 0
	if appliedVersion >= PHASE_4_FORCE_VERSION then
		return false
	end
	Unforvegan_BISDB.maxPhase = DEFAULT_SETTINGS.maxPhase
	Unforvegan_BISDB.phase4ForcedMigrationVersion = PHASE_4_FORCE_VERSION
	Unforvegan_BISDB.settingsVersion = DEFAULT_SETTINGS.settingsVersion
	return true
end

local addonName, addonTable = ...
local iconpath = "Interface\\GLUES\\CHARACTERCREATE\\UI-CharacterCreate-Classes"
local iconCutoff = 6
local tooltipHooked = false
local minimapButton
local optionsPanel
local optionsCategoryID

local function iconOffset(col, row)
	local offsetString = (col * 64 + iconCutoff) .. ":" .. ((col + 1) * 64 - iconCutoff)
	return offsetString .. ":" .. (row * 64 + iconCutoff) .. ":" .. ((row + 1) * 64 - iconCutoff)
end

local function printBisMessage(msg)
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99TBCA_BIS|r: " .. tostring(msg or ""))
	end
end

local function getAddonVersion()
	if C_AddOns and C_AddOns.GetAddOnMetadata then
		return C_AddOns.GetAddOnMetadata(addonName, "Version") or "v5.0"
	end
	if GetAddOnMetadata then
		return GetAddOnMetadata(addonName, "Version") or "v5.0"
	end
	return "v5.0"
end

local function printLoadBanner()
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99[BiS]|r " .. tostring(getAddonVersion()) .. " by Unforvegan@DreamScythe")
	end
end

local function applyMinimapVisibility()
	if not minimapButton then
		return
	end
	if Unforvegan_BISDB.minimap then
		minimapButton:Show()
	else
		minimapButton:Hide()
	end
end

local function clampPhase(phase)
	phase = tonumber(phase) or DEFAULT_SETTINGS.maxPhase
	if phase < 1 then
		return 1
	end
	if phase > 5 then
		return 5
	end
	return phase
end

local function updateConfigUI()
	local v = clampPhase(Unforvegan_BISDB.maxPhase)
	local frame = optionsPanel
	if not frame then
		return
	end
	if frame.phaseButtons then
		for i = 1, 5 do
			local btn = frame.phaseButtons[i]
			if btn then
				if i == v then
					btn:LockHighlight()
				else
					btn:UnlockHighlight()
				end
			end
		end
	end
	if frame.hitcap then
		frame.hitcap:SetChecked(Unforvegan_BISDB.hitCapped)
	end
	if frame.percent then
		frame.percent:SetChecked(Unforvegan_BISDB.showPercent)
	end
	if frame.dropRates then
		frame.dropRates:SetChecked(Unforvegan_BISDB.showDropRates == true)
	end
	if frame.minimap then
		frame.minimap:SetChecked(Unforvegan_BISDB.minimap)
	end
	if frame.showInspect then
		frame.showInspect:SetChecked(Unforvegan_BISDB.showInspect ~= false)
	end
	if frame.inspectMovable then
		frame.inspectMovable:SetChecked(Unforvegan_BISDB.inspectMovable == true)
	end
	if frame.simpleGearSets then
		frame.simpleGearSets:SetChecked(Unforvegan_BISDB.simpleGearSetsEnabled ~= false)
	end
end

local function loadAddonByName(addon)
	if not addon or addon == "" then
		return false
	end
	if C_AddOns and C_AddOns.LoadAddOn then
		local ok = C_AddOns.LoadAddOn(addon)
		return ok and true or false
	elseif LoadAddOn then
		local ok = LoadAddOn(addon)
		return ok and true or false
	end
	return false
end

local function addonExists(addon)
	if not addon or addon == "" then
		return false
	end
	if C_AddOns and C_AddOns.GetAddOnInfo then
		local name = C_AddOns.GetAddOnInfo(addon)
		return name and true or false
	elseif GetAddOnInfo then
		local name = GetAddOnInfo(addon)
		return name and true or false
	end
	return false
end

local function resolveBisAtlasModule(AtlasLoot)
	local target = "AtlasLootClassic_TBCA_BIS"
	local loader = AtlasLoot and AtlasLoot.Loader
	if loader and type(loader.GetLootModuleList) == "function" then
		local list = loader:GetLootModuleList()
		local lookup = {}
		if list and list.custom then
			for i = 1, #list.custom do
				local name = list.custom[i] and list.custom[i].addonName
				if name then lookup[name] = true end
			end
		end
		if list and list.module then
			for i = 1, #list.module do
				local name = list.module[i] and list.module[i].addonName
				if name then lookup[name] = true end
			end
		end
		if lookup[target] then
			return target
		end
	end
	if addonExists(target) then
		return target
	end
	return nil
end

local function openAtlasLootBisTab()
	local AtlasLoot = _G.AtlasLoot
	if not AtlasLoot then
		loadAddonByName("AtlasLootClassic")
		AtlasLoot = _G.AtlasLoot
	end
	if not AtlasLoot or not AtlasLoot.GUI then
		printBisMessage("AtlasLoot is not available.")
		return
	end

	local targetModule = resolveBisAtlasModule(AtlasLoot)
	if not targetModule then
		printBisMessage("No AtlasLoot BiS module found.")
		return
	end

	if AtlasLoot.Loader and type(AtlasLoot.Loader.LoadModule) == "function" then
		local state = AtlasLoot.Loader:LoadModule(targetModule)
		if state == "MISSING" or state == "DISABLED" then
			printBisMessage("AtlasLootClassic_TBCA_BIS is not available.")
			return
		end
	end

	if AtlasLoot.db and AtlasLoot.db.GUI and AtlasLoot.db.GUI.selected then
		AtlasLoot.db.GUI.selected[2] = nil
		AtlasLoot.db.GUI.selected[3] = 1
		AtlasLoot.db.GUI.selected[4] = 1
		AtlasLoot.db.GUI.selected[5] = 0
		AtlasLoot.db.GUI.selected[1] = targetModule
	end

	local gui = AtlasLoot.GUI
	if gui.frame and gui.frame.moduleSelect and type(gui.frame.moduleSelect.SetSelected) == "function" then
		gui.frame.moduleSelect:SetSelected(targetModule)
	end

	if gui.frame and gui.frame.IsShown and not gui.frame:IsShown() then
		gui:Toggle()
	elseif not gui.frame then
		gui:Toggle()
	end

	if gui.frame and gui.frame.moduleSelect and type(gui.frame.moduleSelect.SetSelected) == "function" then
		gui.frame.moduleSelect:SetSelected(targetModule)
	end
end

local function createOptionsPanel()
	if optionsPanel then
		return
	end

	local panel = CreateFrame("Frame", "UnforveganBIS_InterfaceOptionsPanel")
	panel.name = "TBCA_BIS"

	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("TBCA_BIS")

	local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetText("Tooltip and BiS display settings")

	-- Phase selector: 5 numbered buttons (1-5), LockHighlight on selected
	local phaseLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	phaseLabel:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -24)
	phaseLabel:SetText("Content Phase:")

	local phaseButtons = {}
	for i = 1, 5 do
		local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
		btn:SetSize(26, 22)
		if i == 1 then
			btn:SetPoint("LEFT", phaseLabel, "RIGHT", 10, 0)
		else
			btn:SetPoint("LEFT", phaseButtons[i - 1], "RIGHT", 2, 0)
		end
		btn:SetText(tostring(i))
		btn:SetScript("OnClick", function()
			Unforvegan_BISDB.maxPhase = i
			updateConfigUI()
		end)
		phaseButtons[i] = btn
	end
	panel.phaseButtons = phaseButtons

	local hitcap = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
	hitcap:SetPoint("TOPLEFT", phaseLabel, "BOTTOMLEFT", 0, -28)
	hitcap.Text:SetText("I am hit-capped (ignore extra hit on items)")
	hitcap:SetScript("OnClick", function(self)
		Unforvegan_BISDB.hitCapped = self:GetChecked() and true or false
		updateConfigUI()
	end)
	panel.hitcap = hitcap

	local percent = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
	percent:SetPoint("TOPLEFT", hitcap, "BOTTOMLEFT", 0, -12)
	percent.Text:SetText("Show % Upgrade in Tooltip")
	percent:SetScript("OnClick", function(self)
		Unforvegan_BISDB.showPercent = self:GetChecked() and true or false
		updateConfigUI()
	end)
	panel.percent = percent

	local dropRates = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
	dropRates:SetPoint("TOPLEFT", percent, "BOTTOMLEFT", 0, -12)
	dropRates.Text:SetText("Show TBCA drop rates in Tooltip")
	dropRates:SetScript("OnClick", function(self)
		Unforvegan_BISDB.showDropRates = self:GetChecked() and true or false
		updateConfigUI()
	end)
	panel.dropRates = dropRates

	local minimap = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
	minimap:SetPoint("TOPLEFT", dropRates, "BOTTOMLEFT", 0, -12)
	minimap.Text:SetText("Show Minimap Button")
	minimap:SetScript("OnClick", function(self)
		Unforvegan_BISDB.minimap = self:GetChecked() and true or false
		applyMinimapVisibility()
		updateConfigUI()
	end)
	panel.minimap = minimap

	local showInspectChk = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
	showInspectChk:SetPoint("TOPLEFT", minimap, "BOTTOMLEFT", 0, -12)
	showInspectChk.Text:SetText("Show BiS panel when inspecting players")
	showInspectChk:SetScript("OnClick", function(self)
		Unforvegan_BISDB.showInspect = self:GetChecked() and true or false
		updateConfigUI()
	end)
	panel.showInspect = showInspectChk

	local inspectMovableChk = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
	inspectMovableChk:SetPoint("TOPLEFT", showInspectChk, "BOTTOMLEFT", 0, -12)
	inspectMovableChk.Text:SetText("Allow BiS inspect panel to be moved")
	inspectMovableChk:SetScript("OnClick", function(self)
		Unforvegan_BISDB.inspectMovable = self:GetChecked() and true or false
		updateConfigUI()
	end)
	panel.inspectMovable = inspectMovableChk

	local simpleGearSetsChk = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
	simpleGearSetsChk:SetPoint("TOPLEFT", inspectMovableChk, "BOTTOMLEFT", 0, -12)
	simpleGearSetsChk.Text:SetText("Enable TBCA Simple GearSets")
	simpleGearSetsChk:SetScript("OnClick", function(self)
		Unforvegan_BISDB.simpleGearSetsEnabled = self:GetChecked() and true or false
		if _G.TBCA_Simple_GearSets_SetEnabled then
			_G.TBCA_Simple_GearSets_SetEnabled(Unforvegan_BISDB.simpleGearSetsEnabled)
		end
		updateConfigUI()
	end)
	panel.simpleGearSets = simpleGearSetsChk

	local openWindowButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
	openWindowButton:SetSize(220, 24)
	openWindowButton:SetPoint("TOPLEFT", simpleGearSetsChk, "BOTTOMLEFT", 4, -20)
	openWindowButton:SetText("Open AtlasLoot BiS Tab")
	openWindowButton:SetScript("OnClick", function()
		openAtlasLootBisTab()
	end)

	if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function" and type(Settings.RegisterAddOnCategory) == "function" then
		local category = Settings.RegisterCanvasLayoutCategory(panel, "TBCA_BIS")
		Settings.RegisterAddOnCategory(category)
		optionsCategoryID = (category and type(category.GetID) == "function") and category:GetID() or nil
	elseif type(InterfaceOptions_AddCategory) == "function" then
		InterfaceOptions_AddCategory(panel)
	end

	optionsPanel = panel
	updateConfigUI()
end

local function openOptionsPanel()
	createOptionsPanel()
	if Settings and type(Settings.OpenToCategory) == "function" and optionsCategoryID then
		Settings.OpenToCategory(optionsCategoryID)
	elseif type(InterfaceOptionsFrame_OpenToCategory) == "function" then
		InterfaceOptionsFrame_OpenToCategory(optionsPanel)
		InterfaceOptionsFrame_OpenToCategory(optionsPanel)
	end
end

-- Minimap button: angle-based ring positioning, angle persists in minimapAngle
local MINIMAP_RADIUS = 82

local function placeMinimapButtonOnRing(btn, angle)
	btn:ClearAllPoints()
	btn:SetPoint("CENTER", Minimap, "CENTER",
		MINIMAP_RADIUS * math.cos(angle),
		MINIMAP_RADIUS * math.sin(angle))
end

local function createMinimapButton()
	if minimapButton or not Minimap then
		return
	end

	local btn = CreateFrame("Button", "UnforveganBIS_MinimapButton", Minimap)
	btn:SetSize(32, 32)
	btn:SetFrameStrata("MEDIUM")
	btn:EnableMouse(true)
	btn:RegisterForDrag("LeftButton")
	btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local angle = Unforvegan_BISDB.minimapAngle or -(math.pi / 4)
	placeMinimapButtonOnRing(btn, angle)

	btn:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", function(self)
			local mx, my = Minimap:GetCenter()
			local cx, cy = GetCursorPosition()
			local uiScale = UIParent:GetEffectiveScale()
			cx, cy = cx / uiScale, cy / uiScale
			local a = math.atan2(cy - my, cx - mx)
			Unforvegan_BISDB.minimapAngle = a
			placeMinimapButtonOnRing(self, a)
		end)
	end)

	btn:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
	end)

	local icon = btn:CreateTexture(nil, "BACKGROUND")
	icon:SetSize(20, 20)
	icon:SetPoint("CENTER")
	icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
	btn.icon = icon

	local border = btn:CreateTexture(nil, "OVERLAY")
	border:SetSize(54, 54)
	border:SetPoint("TOPLEFT")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	btn.border = border

	-- Left-click opens options panel; right-click opens AtlasLoot BiS tab
	btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	btn:SetScript("OnClick", function(self, button)
		if button == "RightButton" then
			openAtlasLootBisTab()
		else
			openOptionsPanel()
		end
	end)

	minimapButton = btn
	applyMinimapVisibility()
end

local SPEC_TO_CLASS = {
	Aff = "WARLOCK",
	Dest = "WARLOCK",
	Arc = "MAGE",
	Fire = "MAGE",
	BM = "HUNTER",
	SV = "HUNTER",
	Bear = "DRUID",
	Cat = "DRUID",
	Owl = "DRUID",
	Tree = "DRUID",
	Ele = "SHAMAN",
	Enh = "SHAMAN",
	Resto = "SHAMAN",
	Rog = "ROGUE",
	Heal = "PALADIN",
	Shad = "PRIEST",
	Holy = "PRIEST",
	Tank = "PALADIN",
	Ret = "PALADIN",
	Arm = "WARRIOR",
	Arms = "WARRIOR",
	Prot = "WARRIOR",
	Fury = "WARRIOR",
}

local function getBaselineEntry(row)
	local baseline = Unforvegan_BiSData and Unforvegan_BiSData.baseline
	if not baseline or not row then
		return nil
	end
	local spec = row.s or ""
	local slot = row.sl or ""
	if spec == "" or slot == "" then
		return nil
	end
	return baseline[spec .. ":" .. slot]
end

local function getBaseline(row, maxPhase, hitCapped)
	local entry = getBaselineEntry(row)
	local arr = entry and (hitCapped and entry.mh or entry.m)
	if not arr then
		return nil
	end
	return arr[maxPhase]
end

local function getValue(row, hitCapped)
	if hitCapped then
		return row.h or 0
	end
	return row.e or 0
end

local function formatLine(row, settings)
	local spec = row.s or "?"
	local slot = row.sl or ""
	local phase = row.p or 0
	local rank = row.r or 0
	local phaseRank = "P" .. phase .. "-R" .. rank

	local left = spec
	if slot ~= "" then
		left = left .. " " .. slot
	end
	left = left .. " " .. phaseRank

	if not settings.showPercent then
		return left, ""
	end

	local num = row.e or 0
	local denom = getBaseline(row, settings.maxPhase, false)
	if not denom or denom <= 0 or num <= 0 then
		return left, "n/a"
	end

	local pct = (num / denom) * 100
	local pctRounded = math.floor(pct + 0.5)
	local right = tostring(pctRounded) .. "%"

	local hepv = row.h or num
	if hepv ~= num then
		local hitPct = math.floor(((num - hepv) / denom) * 100 + 0.5)
		if hitPct > 0 then
			right = right .. "  |cFF888888[" .. tostring(hitPct) .. "%]|r"
		end
	end

	return left, right
end

local function sortRows(a, b)
	local ca = SPEC_TO_CLASS[a.s] or "ZZZ"
	local cb = SPEC_TO_CLASS[b.s] or "ZZZ"
	if ca ~= cb then
		return ca < cb
	end
	local sa = a.s or ""
	local sb = b.s or ""
	if sa ~= sb then
		return sa < sb
	end
	local ra = a.r or 0
	local rb = b.r or 0
	if ra ~= rb then
		return ra < rb
	end
	local pa = a.p or 0
	local pb = b.p or 0
	if pa ~= pb then
		return pa < pb
	end
	local sla = a.sl or ""
	local slb = b.sl or ""
	return sla < slb
end

local SOURCE_TYPE_LABELS = {
	[0] = "NPC",
	[1] = "Object",
	[2] = "Item",
	[3] = "Quest",
	[4] = "Zone",
	[5] = "Vendor",
}

local function formatDropChance(chance)
	local percent = (tonumber(chance) or 0) / 100
	if percent >= 1 then
		return ("%.2f%%"):format(percent)
	end
	return ("%.3f%%"):format(percent)
end

local function addDropRateTip(tooltip, itemId)
	local sources = _G.TBCA_BIS_DropRates and _G.TBCA_BIS_DropRates[itemId]
	if not sources or #sources == 0 then
		return
	end

	tooltip:AddDoubleLine("TBCA drop estimate", "Source", 0.35, 0.85, 1, 0.55, 0.55, 0.55)

	local maxSources = math.min(#sources, 4)
	for i = 1, maxSources do
		local source = sources[i]
		local label = source.n
		if not label or label == "" then
			label = (SOURCE_TYPE_LABELS[source.t] or "Source") .. " " .. tostring(source.id or "?")
		end
		tooltip:AddDoubleLine(label, formatDropChance(source.c), 0.82, 0.9, 1, 0.3, 1, 0.45)
	end

	if #sources > maxSources then
		tooltip:AddLine(("Plus %d more recorded sources."):format(#sources - maxSources), 0.55, 0.55, 0.55, true)
	end
end

local function addTrackerListStatusTip(tooltip, itemId)
	local tracker = _G.TBCA_BIS_Tracker
	if not tracker or type(tracker.GetItemListStatuses) ~= "function" then
		return false
	end

	local statuses = tracker:GetItemListStatuses(itemId)
	if not statuses or #statuses == 0 then
		return false
	end

	local maxRows = math.min(#statuses, 5)
	for i = 1, maxRows do
		local row = statuses[i]
		local listName = tostring(row.listName or "Saved list")
		if #listName > 32 then
			listName = listName:sub(1, 31) .. "."
		end
		tooltip:AddDoubleLine("Wishlist status", listName .. " - " .. tostring(row.letter or ""), 0.35, 1, 0.65, 1, 1, 1)
	end
	if #statuses > maxRows then
		tooltip:AddLine(("Plus %d more saved list matches."):format(#statuses - maxRows), 0.55, 0.55, 0.55, true)
	end
	return true
end

local function buildExtraTip(tooltip, rows, itemId)
	if not rows or #rows == 0 then
		return
	end

	local r, g, b = .9, .8, .5
	local settings = Unforvegan_BISDB
	settings.maxPhase = clampPhase(settings.maxPhase)

	tooltip:AddLine(" ", r, g, b)
	tooltip:AddDoubleLine(
		("BiS Phase %d"):format(settings.maxPhase),
		("P%d-Rank  Score [Hit]"):format(settings.maxPhase),
		r, g, b,
		0.55, 0.55, 0.55
	)

	local filtered = {}
	for _, row in ipairs(rows) do
		if row.p and row.p == settings.maxPhase then
			table.insert(filtered, row)
		end
	end

	table.sort(filtered, sortRows)

	for _, row in ipairs(filtered) do
		local left, right = formatLine(row, settings)
		local class = SPEC_TO_CLASS[row.s]
		local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
		local classfontstring = ""

		if class and CLASS_ICON_TCOORDS then
			local coords = CLASS_ICON_TCOORDS[class]
			classfontstring = "|T" .. iconpath .. ":14:14:::256:256:" .. iconOffset(coords[1] * 4, coords[3] * 4) .. "|t "
		end

		if color then
			tooltip:AddDoubleLine(classfontstring .. left, right, color.r, color.g, color.b, 1, 1, 1)
		else
			tooltip:AddDoubleLine(classfontstring .. left, right, 1, 1, 1, 1, 1, 1)
		end
	end

	if itemId and settings.showDropRates == true then
		addDropRateTip(tooltip, itemId)
	end
	if itemId then
		addTrackerListStatusTip(tooltip, itemId)
	end

	tooltip:AddLine(" ", r, g, b)
end

local function onTooltipSetItem(tooltip, itemLink, quantity)
	if not itemLink and tooltip and tooltip.GetItem then
		_, itemLink = tooltip:GetItem()
	end
	if not itemLink then
		return
	end

	local itemString = string.match(itemLink, "item[%-?%d:]+")
	if not itemString then
		return
	end

	local itemId = tonumber(({ string.split(":", itemString) })[2])
	if not itemId then
		return
	end

	if Unforvegan_BiSData and Unforvegan_BiSData.byItem then
		local rows = Unforvegan_BiSData.byItem[itemId]
		if rows then
			buildExtraTip(tooltip, rows, itemId)
			return
		end
	end
	if addTrackerListStatusTip(tooltip, itemId) then
		tooltip:AddLine(" ", .9, .8, .5)
	end
end

local function safeOnTooltipSetItem(...)
	pcall(onTooltipSetItem, ...)
	return nil
end

local eventframe = CreateFrame("FRAME", addonName .. "Events")

local function onEvent(self, event, arg)
	if event == "PLAYER_ENTERING_WORLD" then
		eventframe:UnregisterEvent("PLAYER_ENTERING_WORLD")
		local phaseMigrated = applyPhase4ForceMigration()
		if phaseMigrated then
			updateConfigUI()
		end
		printLoadBanner()
		if not tooltipHooked then
			tooltipHooked = true
			local tooltips = { GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2 }
			for _, tt in ipairs(tooltips) do
				if tt and tt.HookScript then
					tt:HookScript("OnTooltipSetItem", safeOnTooltipSetItem)
				end
			end
		end

		createMinimapButton()
		createOptionsPanel()
	end
end

eventframe:RegisterEvent("PLAYER_ENTERING_WORLD")
eventframe:SetScript("OnEvent", onEvent)

local function printStatus()
	local s = Unforvegan_BISDB
	DEFAULT_CHAT_FRAME:AddMessage(
		("BiS settings: maxPhase=%d, iAmHitCapped=%s, showPercent=%s, debugInspect=%s, inspectMovable=%s, simpleGearSets=%s"):format(
			tonumber(s.maxPhase) or DEFAULT_SETTINGS.maxPhase,
			s.hitCapped and "Y" or "N",
			s.showPercent and "Y" or "N",
			s.debugInspect and "Y" or "N",
			s.inspectMovable and "Y" or "N",
			s.simpleGearSetsEnabled ~= false and "Y" or "N"
		)
	)
end

SLASH_BIS1 = "/bis"
function SlashCmdList.BIS(msg)
	msg = (msg or ""):lower()
	if msg == "on" then
		Unforvegan_BISDB.minimap = true
		applyMinimapVisibility()
		return
	elseif msg == "off" then
		Unforvegan_BISDB.minimap = false
		applyMinimapVisibility()
		return
	elseif msg == "atlas" then
		openAtlasLootBisTab()
		return
	elseif msg == "debug" then
		Unforvegan_BISDB.debugInspect = not Unforvegan_BISDB.debugInspect
		printBisMessage("Inspect debug mode " .. (Unforvegan_BISDB.debugInspect and "enabled" or "disabled"))
		return
	elseif msg == "debug on" or msg == "debug 1" or msg == "debug true" then
		Unforvegan_BISDB.debugInspect = true
		printBisMessage("Inspect debug mode enabled")
		return
	elseif msg == "debug off" or msg == "debug 0" or msg == "debug false" then
		Unforvegan_BISDB.debugInspect = false
		printBisMessage("Inspect debug mode disabled")
		return
	end

	openOptionsPanel()
end

SLASH_BISPHASE1 = "/bisphase"
function SlashCmdList.BISPHASE(msg)
	local n = tonumber(msg)
	if not n then
		printStatus()
		return
	end
	Unforvegan_BISDB.maxPhase = clampPhase(n)
	updateConfigUI()
	printStatus()
end

SLASH_BISHITCAP1 = "/bishitcap"
function SlashCmdList.BISHITCAP(msg)
	msg = (msg or ""):lower()
	if msg == "on" or msg == "1" or msg == "true" then
		Unforvegan_BISDB.hitCapped = true
	elseif msg == "off" or msg == "0" or msg == "false" then
		Unforvegan_BISDB.hitCapped = false
	else
		Unforvegan_BISDB.hitCapped = not Unforvegan_BISDB.hitCapped
	end
	updateConfigUI()
	printStatus()
end

SLASH_BISPERCENT1 = "/bispercent"
function SlashCmdList.BISPERCENT(msg)
	msg = (msg or ""):lower()
	if msg == "on" or msg == "1" or msg == "true" then
		Unforvegan_BISDB.showPercent = true
	elseif msg == "off" or msg == "0" or msg == "false" then
		Unforvegan_BISDB.showPercent = false
	else
		Unforvegan_BISDB.showPercent = not Unforvegan_BISDB.showPercent
	end
	updateConfigUI()
	printStatus()
end

SLASH_BISSTATUS1 = "/bisstatus"
function SlashCmdList.BISSTATUS()
	printStatus()
end

-- Expose for LoD modules (e.g. AtlasLootClassic_TBCA_BIS/runtime.lua)
TBCA_BIS_OpenOptions = openOptionsPanel
