-- inspect_score.lua
-- Shows a BiS score panel when inspecting another player.
-- Triggers on INSPECT_READY and InspectFrame:OnShow.
-- Spec detected via gear-match (no talent API used — more reliable in TBC Classic).

local SLOT_IDS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }

local SLOT_LABEL = {
	[1]  = "Head",      [2]  = "Neck",      [3]  = "Shoulder",
	[5]  = "Chest",     [6]  = "Waist",     [7]  = "Legs",
	[8]  = "Feet",      [9]  = "Wrist",     [10] = "Hands",
	[11] = "Ring 1",    [12] = "Ring 2",    [13] = "Trinket 1",
	[14] = "Trinket 2", [15] = "Back",      [16] = "Weapon",
	[17] = "Off Hand",  [18] = "Ranged",
}

-- Content readiness thresholds per phase.
-- % is measured against BiS for that phase, so thresholds reflect real gear requirements.
local CONTENT_TIERS = {
	[1] = {
		{ pct = 0,  label = "Heroics" },
		{ pct = 35, label = "Karazhan" },
		{ pct = 55, label = "Gruul / Mag" },
	},
	[2] = {
		{ pct = 0,  label = "Gruul / Mag" },
		{ pct = 40, label = "SSC / TK" },
	},
	[3] = {
		{ pct = 0,  label = "SSC / TK" },
		{ pct = 45, label = "BT / Hyjal" },
	},
	[4] = {
		{ pct = 0,  label = "BT / Hyjal" },
		{ pct = 50, label = "Sunwell" },
	},
	[5] = {
		{ pct = 0,  label = "Sunwell" },
	},
}

local SPEC_CLASS = {
	Arms = "WARRIOR", Fury = "WARRIOR", Prot  = "WARRIOR",
	Heal = "PALADIN", Tank = "PALADIN", Ret   = "PALADIN",
	BM   = "HUNTER",  SV   = "HUNTER",
	Rog  = "ROGUE",
	Holy = "PRIEST",  Shad = "PRIEST",
	Ele  = "SHAMAN",  Enh  = "SHAMAN",  Resto = "SHAMAN",
	Arc  = "MAGE",    Fire = "MAGE",
	Aff  = "WARLOCK", Dest = "WARLOCK",
	Owl  = "DRUID",   Cat  = "DRUID",   Tree  = "DRUID",   Bear = "DRUID",
}

local CLASS_TREE_SPECS = {
	WARRIOR = {
		[1] = { "Arms" },
		[2] = { "Fury" },
		[3] = { "Prot" },
	},
	PALADIN = {
		[1] = { "Heal" },
		[2] = { "Tank" },
		[3] = { "Ret" },
	},
	HUNTER = {
		[1] = { "BM" },
		[2] = {},
		[3] = { "SV" },
	},
	ROGUE = {
		[1] = {},
		[2] = {},
		[3] = {},
	},
	PRIEST = {
		[1] = {},
		[2] = { "Holy" },
		[3] = { "Shad" },
	},
	SHAMAN = {
		[1] = { "Ele" },
		[2] = { "Enh" },
		[3] = { "Resto" },
	},
	MAGE = {
		[1] = { "Arc" },
		[2] = { "Fire" },
		[3] = {},
	},
	WARLOCK = {
		[1] = { "Aff" },
		[2] = {},
		[3] = { "Dest" },
	},
	DRUID = {
		[1] = { "Owl" },
		[2] = { "Cat", "Bear" },
		[3] = { "Tree" },
	},
}

local UNSUPPORTED_TREE_FALLBACK = {
	WARLOCK = {
		[2] = "Dest",
	},
	PRIEST = {
		[1] = "Shad",
	},
	ROGUE = {
		[1] = "Rog",
		[2] = "Rog",
		[3] = "Rog",
	},
}

local inspectPanel = nil
local inspectedGUID = nil
local pendingInspectGUID = nil
local pendingRefresh = false
local pendingTimer  = 0
local REFRESH_DELAY = 0.05  -- quick first scan; retries cover slow inspect data
local INSPECT_RETRY_SECONDS = 3.0
local INSPECT_RETRY_INTERVAL = 0.2
local INSPECT_MIN_READY_SLOTS = 10
local inspectRetryUntil = 0
local scoreCacheByGUID = {}
local selfMode = false      -- true when showing for own CharacterFrame
local inspectHooksInstalled = false
local characterHooksInstalled = false
local scheduleRefresh = nil

-- ---------------------------------------------------------------
local function getSettings()
	local db = _G.Unforvegan_BISDB
	return {
		maxPhase    = (db and db.maxPhase  or 4),
		hitCapped   = (db and db.hitCapped or false),
		showInspect = (db and db.showInspect ~= false),
		debugInspect = (db and db.debugInspect == true),
		inspectMovable = (db and db.inspectMovable == true),
	}
end

-- Find the unit string matching a GUID using stable unit tokens only.
local function findUnitByGUID(guid)
	if not guid then return nil end
	local checks = { "mouseover", "target", "focus" }
	for i = 1, 4  do checks[#checks+1] = "party"  .. i end
	for i = 1, 40 do checks[#checks+1] = "raid"   .. i end
	for _, u in ipairs(checks) do
		if UnitExists(u) and UnitIsPlayer(u) and UnitGUID(u) == guid then
			return u
		end
	end
	return nil
end

-- Pick the best row for a spec/phase: highest score with p <= maxPhase
local function bestRow(rows, spec, maxPhase, hitCapped)
	local best, bestVal = nil, -1
	for _, row in ipairs(rows) do
		if row.s == spec and row.p <= maxPhase then
			local val = hitCapped and row.h or row.e
			if val > bestVal then bestVal = val; best = row end
		end
	end
	return best
end

-- Returns % for one item in a given spec, capped at 97 before bonuses.
local function calcSlotPct(itemID, spec, maxPhase, hitCapped)
	local data = _G.Unforvegan_BiSData
	if not data or not data.byItem or not data.baseline then return nil end
	local rows = data.byItem[itemID]
	if not rows then return nil end
	local row = bestRow(rows, spec, maxPhase, hitCapped)
	if not row then return nil end
	local val = hitCapped and row.h or row.e
	local bEntry = data.baseline[spec .. ":" .. row.sl]
	local arr = bEntry and (hitCapped and bEntry.mh or bEntry.m)
	local denom = arr and arr[maxPhase]
	if not denom or denom <= 0 or val <= 0 then return nil end
	return math.min(97, (val / denom) * 97)
end

local function detectGearSpec(unit, className, maxPhase, hitCapped, allowedSpecs)
	local data = _G.Unforvegan_BiSData
	if not data or not data.byItem then return nil end
	local counts = {}
	local totals = {}
	local allowed = nil
	if allowedSpecs and #allowedSpecs > 0 then
		allowed = {}
		for _, spec in ipairs(allowedSpecs) do
			allowed[spec] = true
		end
	end
	for _, sid in ipairs(SLOT_IDS) do
		local iid = GetInventoryItemID(unit, sid)
		if iid and iid > 0 then
			local rows = data.byItem[iid]
			if rows then
				for _, row in ipairs(rows) do
					if SPEC_CLASS[row.s] == className and row.p <= maxPhase and (not allowed or allowed[row.s]) then
						counts[row.s] = (counts[row.s] or 0) + 1
						totals[row.s] = (totals[row.s] or 0) + (hitCapped and row.h or row.e or 0)
					end
				end
			end
		end
	end
	local best, bestCnt, bestTotal = nil, 0, -1
	for spec, cnt in pairs(counts) do
		local total = totals[spec] or 0
		if cnt > bestCnt or (cnt == bestCnt and total > bestTotal) then
			bestCnt = cnt
			bestTotal = total
			best = spec
		end
	end
	return best
end

local function getActiveTalentGroupForUnit(unit)
	if type(GetActiveTalentGroup) ~= "function" then return nil end
	local inspect = unit ~= "player"
	local ok, group = pcall(GetActiveTalentGroup, inspect, false)
	if ok and type(group) == "number" and group > 0 then
		return group
	end
	ok, group = pcall(GetActiveTalentGroup, inspect)
	if ok and type(group) == "number" and group > 0 then
		return group
	end
	ok, group = pcall(GetActiveTalentGroup)
	if ok and type(group) == "number" and group > 0 then
		return group
	end
	return nil
end

local function getTalentTreeInfo(unit)
	if type(GetTalentTabInfo) ~= "function" then return nil end
	local inspect = unit ~= "player"
	local group = getActiveTalentGroupForUnit(unit) or 1
	local numTabs = 3
	if type(GetNumTalentTabs) == "function" then
		local ok, tabs = pcall(GetNumTalentTabs, inspect, false)
		if ok and type(tabs) == "number" and tabs > 0 then
			numTabs = tabs
		end
	end

	local info = { activeGroup = group, trees = {} }
	local bestTree, bestPoints = nil, -1
	for treeIndex = 1, numTabs do
		local ok, _, name, _, _, pointsSpent, _, previewPointsSpent = pcall(GetTalentTabInfo, treeIndex, inspect, false, group)
		if ok and name then
			local totalPoints = (tonumber(pointsSpent) or 0) + (tonumber(previewPointsSpent) or 0)
			info.trees[treeIndex] = {
				name = name,
				points = totalPoints,
			}
			if totalPoints > bestPoints then
				bestPoints = totalPoints
				bestTree = treeIndex
			end
		end
	end
	if not bestTree then return nil end
	info.activeTree = bestTree
	info.activeTreeName = info.trees[bestTree] and info.trees[bestTree].name or nil
	return info
end

local function getSupportedTalentFallbacks(className, talentInfo)
	local mapping = CLASS_TREE_SPECS[className]
	if not mapping then return nil end
	local bestPoints = -1
	local specs = {}
	for treeIndex, candidates in pairs(mapping) do
		if treeIndex ~= talentInfo.activeTree and candidates and #candidates > 0 then
			local tree = talentInfo.trees[treeIndex]
			local points = tree and tree.points or 0
			if points > bestPoints then
				bestPoints = points
				specs = {}
				for _, spec in ipairs(candidates) do
					specs[#specs + 1] = spec
				end
			elseif points == bestPoints and points > 0 then
				for _, spec in ipairs(candidates) do
					specs[#specs + 1] = spec
				end
			end
		end
	end
	if bestPoints <= 0 or #specs == 0 then
		return nil
	end
	return specs
end

local function buildFallbackNote(activeSpecName, scoreSpec)
	if not activeSpecName or not scoreSpec then return nil end
	return "Scored as: " .. scoreSpec
end

local function detectSpec(unit, className, maxPhase, hitCapped)
	local talentInfo = getTalentTreeInfo(unit)
	if talentInfo then
		local explicitFallback = UNSUPPORTED_TREE_FALLBACK[className]
		local explicitScoreSpec = explicitFallback and explicitFallback[talentInfo.activeTree] or nil
		if explicitScoreSpec then
			return explicitScoreSpec, talentInfo.activeTreeName or explicitScoreSpec, buildFallbackNote(talentInfo.activeTreeName, explicitScoreSpec)
		end

		local mapping = CLASS_TREE_SPECS[className]
		local candidates = mapping and mapping[talentInfo.activeTree] or nil
		if candidates and #candidates > 0 then
			if #candidates == 1 then
				return candidates[1], candidates[1], nil
			end
			local feralSpec = detectGearSpec(unit, className, maxPhase, hitCapped, candidates)
			if feralSpec then
				return feralSpec, feralSpec, nil
			end
		else
			local fallbackCandidates = getSupportedTalentFallbacks(className, talentInfo)
			local fallbackSpec = nil
			if fallbackCandidates and #fallbackCandidates == 1 then
				fallbackSpec = fallbackCandidates[1]
			elseif fallbackCandidates and #fallbackCandidates > 1 then
				fallbackSpec = detectGearSpec(unit, className, maxPhase, hitCapped, fallbackCandidates)
			end
			if not fallbackSpec then
				fallbackSpec = detectGearSpec(unit, className, maxPhase, hitCapped)
			end
			if fallbackSpec then
				return fallbackSpec, talentInfo.activeTreeName or fallbackSpec, buildFallbackNote(talentInfo.activeTreeName, fallbackSpec)
			end
			if talentInfo.activeTreeName then
				return nil, talentInfo.activeTreeName, nil
			end
		end
	end

	local gearSpec = detectGearSpec(unit, className, maxPhase, hitCapped)
	return gearSpec, gearSpec, nil
end

-- ---------------------------------------------------------------
local function getReadinessText(overallPct, maxPhase)
	local tiers = CONTENT_TIERS[maxPhase]
	if not tiers then return nil end
	local passed = {}
	for _, tier in ipairs(tiers) do
		if overallPct >= tier.pct then
			table.insert(passed, tier.label)
		end
	end
	if #passed == 0 then return nil end
	return "Pass: " .. table.concat(passed, " / ")
end

-- ---------------------------------------------------------------
-- Gem / enchant bonus model:
-- slotScore = (itemEPV / bisEPV) * 97 + enchantBonus + gemBonus
-- capped at 100
local ENCHANT_BONUS_PCT = 1.5
local GEM_BONUS_PCT = 0.5

-- Slots where a confirmed enchant grants +5%.
-- Rings included so Enchanting-only ring enchants are reflected.
local ENCHANTABLE = {
	[1]=true,   -- Head
	[3]=true,   -- Shoulder
	[5]=true,   -- Chest
	[7]=true,   -- Legs
	[8]=true,   -- Feet
	[9]=true,   -- Wrist
	[10]=true,  -- Hands
	[11]=true,  -- Ring 1
	[12]=true,  -- Ring 2
	[15]=true,  -- Back
	[16]=true,  -- Weapon
	[17]=true,  -- Off-Hand
}

-- Returns enchantID from an item link (0 = no enchant)
local function parseItemLinkFields(link)
	if type(link) ~= "string" then return nil end
	local itemString = link:match("|H(item:[^|]+)|h") or link:match("(item:[^|]+)")
	if not itemString then return nil end

	local fields = {}
	for field in string.gmatch(itemString .. ":", "([^:]*):") do
		fields[#fields + 1] = field
	end
	return fields
end

local function linkEnchantID(link)
	local fields = parseItemLinkFields(link)
	if not fields then return 0 end
	return tonumber(fields[3]) or 0
end

-- Returns the number of socketed gems found in the item link.
local function linkGemCount(link)
	local fields = parseItemLinkFields(link)
	if not fields then return 0 end

	local gemCount = 0
	for i = 4, 7 do
		local gemID = tonumber(fields[i]) or 0
		if gemID > 0 then
			gemCount = gemCount + 1
		end
	end

	return gemCount
end

local function cleanPayloadText(text)
	text = tostring(text or "")
	text = text:gsub("[;%|,@]", "")
	text = text:gsub("%s+", "")
	if text == "" then
		return "?"
	end
	return text
end

local function getUnitItemString(unit, slotID)
	local link = GetInventoryItemLink(unit, slotID)
	if type(link) ~= "string" then return "" end
	return link:match("|H(item:[^|]+)|h") or link:match("(item:[^|]+)") or ""
end

local function getUnitTalentSummary(unit)
	if unit ~= "player" or type(GetTalentTabInfo) ~= "function" then
		return ""
	end
	local group = getActiveTalentGroupForUnit("player") or 1
	local parts = {}
	for treeIndex = 1, 3 do
		local ok, _, name, _, _, pointsSpent, _, previewPointsSpent = pcall(GetTalentTabInfo, treeIndex, false, false, group)
		if ok and name then
			local points = (tonumber(pointsSpent) or 0) + (tonumber(previewPointsSpent) or 0)
			parts[#parts + 1] = cleanPayloadText(name) .. "=" .. tostring(points)
		end
	end
	return table.concat(parts, "/")
end

local function scoreUnitForRemote(unit)
	if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) then
		return nil
	end

	local settings = getSettings()
	local playerName, realm = UnitName(unit)
	local _, raceName = UnitRace(unit)
	local _, className = UnitClass(unit)
	if not className then return nil end
	className = className:upper()
	local scoreSpec, displaySpec = detectSpec(unit, className, settings.maxPhase, false)

	local rows = {}
	local totalPct = 0
	local scoredCount = 0
	for _, sid in ipairs(SLOT_IDS) do
		local itemID = GetInventoryItemID(unit, sid) or 0
		local pct = nil
		if itemID > 0 and scoreSpec then
			pct = calcSlotPct(itemID, scoreSpec, settings.maxPhase, false)
		end
		local scored = pct ~= nil
		pct = pct or 25
		if itemID > 0 then
			local link = GetInventoryItemLink(unit, sid)
			if ENCHANTABLE[sid] and linkEnchantID(link) > 0 then
				pct = math.min(100, pct + ENCHANT_BONUS_PCT)
			end
			local gemCount = linkGemCount(link)
			if gemCount > 0 then
				pct = math.min(100, pct + (gemCount * GEM_BONUS_PCT))
			end
		end
		totalPct = totalPct + pct
		if scored then
			scoredCount = scoredCount + 1
		end
		rows[#rows + 1] = {
			slotID = sid,
			itemID = itemID,
			itemString = getUnitItemString(unit, sid),
			pct = math.floor(pct + 0.5),
			scored = scored,
		}
	end

	return {
		name = playerName or UnitName("player") or "?",
		realm = realm or GetRealmName() or "",
		className = className,
		race = raceName or "",
		spec = displaySpec or scoreSpec or "?",
		talents = getUnitTalentSummary(unit),
		phase = settings.maxPhase,
		overall = math.floor((totalPct / 17) + 0.5),
		scored = scoredCount,
		rows = rows,
	}
end

_G.TBCA_BIS_BuildRemoteScoreSnapshot = scoreUnitForRemote

local function pctColor(pct)
	if pct >= 80 then return "|cFF44DD44"
	elseif pct >= 60 then return "|cFFFFCC22"
	else return "|cFFFF4444"
	end
end

local function readinessColor(pct)
	if pct >= 80 then return "|cFFFF8000"
	elseif pct >= 64 then return "|cFFA335EE"
	elseif pct >= 50 then return "|cFF0070DD"
	elseif pct >= 40 then return "|cFF1EFF00"
	else return "|cFF9D9D9D"
	end
end

local function buildPanel()
	if inspectPanel then return end

	local f = CreateFrame("Frame", "TBCA_BIS_InspectPanel", UIParent, "BackdropTemplate")
	f:SetWidth(165)
	f:SetHeight(200)
	f:SetFrameStrata("DIALOG")
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(false)
	f:RegisterForDrag("LeftButton")
	f:SetBackdrop({
		bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	f:SetBackdropColor(0.04, 0.04, 0.12, 0.96)
	f:SetBackdropBorderColor(0.25, 0.45, 0.8, 0.9)

	local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 1, 1)
	closeBtn:SetScript("OnClick", function() f:Hide() end)

	f:SetScript("OnDragStart", function(self)
		local db = _G.Unforvegan_BISDB
		if db and db.inspectMovable == true then
			self:StartMoving()
		end
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local db = _G.Unforvegan_BISDB
		if db and db.inspectMovable == true then
			db.inspectPanelX = self:GetLeft()
			db.inspectPanelY = self:GetTop()
		end
	end)

	f:Hide()

	local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -8)
	title:SetText("|cFF55AAFFBiS Score|r")
	f.titleText = title

	local specLine = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	specLine:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
	specLine:SetWidth(149)
	specLine:SetJustifyH("LEFT")
	f.specLine = specLine

	local overallLine = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	overallLine:SetPoint("TOPLEFT", specLine, "BOTTOMLEFT", 0, -5)
	f.overallLine = overallLine

	local statusLine = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	statusLine:SetPoint("TOPLEFT", overallLine, "BOTTOMLEFT", 0, -3)
	statusLine:SetWidth(149)
	statusLine:SetJustifyH("LEFT")
	statusLine:Hide()
	f.statusLine = statusLine

	local readyLine = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	readyLine:SetPoint("TOPLEFT", statusLine, "BOTTOMLEFT", 0, -3)
	readyLine:SetWidth(149)
	readyLine:SetJustifyH("LEFT")
	f.readyLine = readyLine

	local noteLine = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	noteLine:SetPoint("TOPLEFT", readyLine, "BOTTOMLEFT", 0, -4)
	noteLine:SetWidth(149)
	noteLine:SetJustifyH("LEFT")
	noteLine:SetJustifyV("TOP")
	noteLine:Hide()
	f.noteLine = noteLine

	local div = f:CreateTexture(nil, "ARTWORK")
	div:SetHeight(1)
	div:SetWidth(149)
	div:SetColorTexture(0.25, 0.45, 0.8, 0.4)
	div:SetPoint("TOPLEFT", readyLine, "BOTTOMLEFT", 0, -4)
	f.divider = div

	f.slotLines = {}
	for i = 1, 17 do
		local line = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		line:SetWidth(149)
		line:SetJustifyH("LEFT")
		if i == 1 then
			line:SetPoint("TOPLEFT", div, "BOTTOMLEFT", 0, -4)
		else
			line:SetPoint("TOPLEFT", f.slotLines[i - 1], "BOTTOMLEFT", 0, -1)
		end
		line:Hide()
		f.slotLines[i] = line
	end

	inspectPanel = f
end

local function getInspectFrameUnit()
	local frame = _G.InspectFrame
	if not frame or not frame:IsShown() then return nil end

	local unit = frame.unit
	if unit and UnitExists(unit) and UnitIsPlayer(unit) then
		return unit
	end

	return nil
end

local function getInspectRequestUnit()
	local unit = getInspectFrameUnit()
	if unit then
		return unit
	end

	if UnitExists("target") and UnitIsPlayer("target") then
		return "target"
	end

	return nil
end

local function captureInspectGUID()
	local unit = getInspectFrameUnit()
	if unit then
		return UnitGUID(unit)
	end

	if UnitExists("target") and UnitIsPlayer("target") then
		return UnitGUID("target")
	end

	return nil
end

local function canInspectUnit(unit)
	if not unit or not UnitExists(unit) or not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then
		return false
	end

	if type(CanInspect) ~= "function" then
		return true
	end

	local ok, allowed = pcall(CanInspect, unit, false)
	if ok then
		return allowed and true or false
	end

	ok, allowed = pcall(CanInspect, unit)
	return ok and allowed and true or false
end

local function requestInspectData()
	local unit = getInspectRequestUnit()
	if not canInspectUnit(unit) then
		return false
	end

	pendingInspectGUID = UnitGUID(unit)
	inspectedGUID = pendingInspectGUID
	inspectRetryUntil = (GetTime and GetTime() or 0) + INSPECT_RETRY_SECONDS
	NotifyInspect(unit)
	return true
end

local function resolveInspectUnit()
	local unit = getInspectFrameUnit()
	if unit then
		local guid = UnitGUID(unit)
		if guid and (not inspectedGUID or guid == inspectedGUID or guid == pendingInspectGUID) then
			return unit
		end
	end

	if inspectedGUID then
		return findUnitByGUID(inspectedGUID)
	end

	return nil
end

local function positionInspectPanel(settings)
	if not inspectPanel then return end
	settings = settings or getSettings()
	inspectPanel:SetMovable(settings.inspectMovable)
	inspectPanel:EnableMouse(settings.inspectMovable)

	inspectPanel:ClearAllPoints()
	if settings.inspectMovable and Unforvegan_BISDB and Unforvegan_BISDB.inspectPanelX and Unforvegan_BISDB.inspectPanelY then
		inspectPanel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", Unforvegan_BISDB.inspectPanelX, Unforvegan_BISDB.inspectPanelY)
	else
		local anchor = (selfMode and _G.CharacterFrame) or _G.InspectFrame
		if anchor and anchor:IsShown() then
			inspectPanel:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 5, 0)
		else
			inspectPanel:SetPoint("CENTER", UIParent, "CENTER", 300, 100)
		end
	end
end

local function showCachedOrLoading(unit, settings, stillRetrying)
	if not inspectPanel or selfMode then return false end
	local guid = unit and UnitGUID(unit) or inspectedGUID or pendingInspectGUID
	local cached = guid and scoreCacheByGUID[guid]

	if cached then
		inspectPanel.specLine:SetText((cached.playerName or "?") .. "  [" .. (cached.specLabel or "?") .. "]")
		inspectPanel.overallLine:SetText("EPV Gearscore:  " .. readinessColor(cached.overallPct or 0) .. tostring(cached.overallPct or 0) .. "%|r")
		inspectPanel.statusLine:SetText("|cFFAADDFFStatus: Cached - refreshing|r")
		inspectPanel.statusLine:Show()
		inspectPanel.readyLine:SetText("")
		inspectPanel.readyLine:Hide()
		inspectPanel.noteLine:SetText("|cFFAAAAAAShowing last known score while inspect data reloads.|r")
		inspectPanel.noteLine:Show()
		for i, line in ipairs(inspectPanel.slotLines) do
			line:SetText("")
			line:Hide()
		end
		inspectPanel.divider:SetShown(false)
		inspectPanel:SetHeight(8 + 16 + 3 + 14 + 5 + 16 + 3 + 14 + 4 + 28 + 8)
		positionInspectPanel(settings)
		inspectPanel:Show()
		return true
	end

	inspectPanel.specLine:SetText((unit and UnitName(unit) or "Player") .. "  [loading]")
	inspectPanel.overallLine:SetText(stillRetrying and "|cFFAAAAAAWaiting for inspect data...|r" or "|cFFFF7777Inspect data unavailable|r")
	inspectPanel.statusLine:SetText(stillRetrying and "|cFFFFFF99Status: Loading|r" or "|cFFFF7777Status: Unavailable|r")
	inspectPanel.statusLine:Show()
	inspectPanel.readyLine:SetText("")
	inspectPanel.readyLine:Hide()
	if stillRetrying then
		inspectPanel.noteLine:SetText("Raid inspect data can arrive late. Retrying briefly.")
	else
		inspectPanel.noteLine:SetText("Try inspecting again or move closer to the player.")
	end
	inspectPanel.noteLine:Show()
	for i, line in ipairs(inspectPanel.slotLines) do
		line:SetText("")
		line:Hide()
	end
	inspectPanel.divider:SetShown(false)
	inspectPanel:SetHeight(8 + 16 + 3 + 14 + 5 + 16 + 3 + 14 + 4 + 32 + 8)
	positionInspectPanel(settings)
	inspectPanel:Show()
	return true
end

local function doRefresh()
	if not inspectPanel then return end

	local settings = getSettings()
	if not settings.showInspect then
		inspectPanel:Hide()
		return
	end

	-- Determine unit: self (CharacterFrame) or inspected player
	local unit
	if selfMode then
		if not (_G.CharacterFrame and _G.CharacterFrame:IsShown()) then
			inspectPanel:Hide()
			return
		end
		unit = "player"
	else
		if not (_G.InspectFrame and _G.InspectFrame:IsShown()) then
			inspectPanel:Hide()
			return
		end
		unit = resolveInspectUnit()
	end
	if not unit then
		inspectPanel:Hide()
		return
	end

	local _, className = UnitClass(unit)
	if not className then
		inspectPanel:Hide()
		return
	end
	className = className:upper()

	local scoreSpec, displaySpec, fallbackNote = detectSpec(unit, className, settings.maxPhase, false)

	-- All 17 slots contribute equally; unscored/empty slots get a 25% baseline.
	-- Denominator is always 17.
	local results = {}
	local totalPct, count = 0, 0
	local availableSlots = 0

	for _, sid in ipairs(SLOT_IDS) do
		local iid = GetInventoryItemID(unit, sid)
		if iid and iid > 0 then
			availableSlots = availableSlots + 1
		end
		local pct = nil
		if iid and iid > 0 and scoreSpec then
			pct = calcSlotPct(iid, scoreSpec, settings.maxPhase, false)
		end
		local scored = pct ~= nil
		pct = pct or 25  -- 25% baseline for empty or unrecognised slots

		-- Apply gem/enchant bonus to any worn item, scored or not
		if iid and iid > 0 then
			local link = GetInventoryItemLink(unit, sid)
			if ENCHANTABLE[sid] and linkEnchantID(link) > 0 then
				pct = math.min(100, pct + ENCHANT_BONUS_PCT)
			end
			local gemCount = linkGemCount(link)
			if gemCount > 0 then
				pct = math.min(100, pct + (gemCount * GEM_BONUS_PCT))
			end
		end

		totalPct = totalPct + pct
		if scored then
			count = count + 1
			table.insert(results, { label = SLOT_LABEL[sid], pct = pct, scored = true })
		elseif iid and iid > 0 then
			-- Worn but not in BiS data — show in gray so bonuses are visible
			table.insert(results, { label = SLOT_LABEL[sid], pct = pct, scored = false })
		end
	end

	if not selfMode and availableSlots < INSPECT_MIN_READY_SLOTS then
		local now = GetTime and GetTime() or 0
		local stillRetrying = now > 0 and now < inspectRetryUntil
		showCachedOrLoading(unit, settings, stillRetrying)
		if stillRetrying then
			scheduleRefresh(INSPECT_RETRY_INTERVAL, false)
		end
		return
	end

	-- Sort weakest first
	table.sort(results, function(a, b) return a.pct < b.pct end)

	local playerName = UnitName(unit) or "?"
	local specLabel  = displaySpec or scoreSpec or "?"

	inspectPanel.specLine:SetText(playerName .. "  [" .. specLabel .. "]")

	-- Always divide by 17 (fixed denominator — one per gear slot)
	local overallPct = math.floor(totalPct / 17 + 0.5)
	if not selfMode then
		local guid = UnitGUID(unit)
		if guid then
			scoreCacheByGUID[guid] = {
				playerName = playerName,
				specLabel = specLabel,
				overallPct = overallPct,
				scoredCount = count,
				time = GetTime and GetTime() or 0,
			}
		end
	end
	local debugMode = settings.debugInspect
	local overallColor = debugMode and pctColor(overallPct) or readinessColor(overallPct)
	if debugMode then
		inspectPanel.overallLine:SetText("Overall:  " .. overallColor .. overallPct .. "%|r  (" .. count .. " scored)")
	else
		inspectPanel.overallLine:SetText("EPV Gearscore:  " .. overallColor .. overallPct .. "%|r")
	end
	inspectPanel.statusLine:SetText("|cff33ff99Status: Fresh|r")
	inspectPanel.statusLine:Show()
	local readyText = getReadinessText(overallPct, settings.maxPhase)

	if debugMode and readyText then
		inspectPanel.readyLine:SetText("|cFFAADDFF" .. readyText .. "|r")
		inspectPanel.readyLine:Show()
	elseif debugMode then
		inspectPanel.readyLine:SetText("")
		inspectPanel.readyLine:Hide()
	end
	if debugMode then
		if fallbackNote then
			inspectPanel.noteLine:SetText(fallbackNote)
			inspectPanel.noteLine:Show()
		else
			inspectPanel.noteLine:SetText("")
			inspectPanel.noteLine:Hide()
		end
	else
		inspectPanel.readyLine:SetText("")
		inspectPanel.readyLine:Hide()
		if fallbackNote then
			inspectPanel.noteLine:SetText(fallbackNote .. "\nColor indicates current-phase gear readiness.\nGear only; skill, buffs, consumes, and utility are not included.")
		else
			inspectPanel.noteLine:SetText("Color indicates current-phase gear readiness.\nGear only; skill, buffs, consumes, and utility are not included.")
		end
		inspectPanel.noteLine:Show()
	end

	-- Slot lines
	for i, line in ipairs(inspectPanel.slotLines) do
		local r = results[i]
		if debugMode and r then
			local displayPct = string.format("%.1f", r.pct)
			if r.scored then
				local c = pctColor(r.pct)
				line:SetText(c .. displayPct .. "%|r  " .. r.label)
			else
				-- Unscored (not in BiS data): gray, tilde prefix
				line:SetText("|cFF888888~" .. displayPct .. "%|r  " .. r.label)
			end
			line:Show()
		else
			line:SetText("")
			line:Hide()
		end
	end
	inspectPanel.divider:SetShown(debugMode)

	-- Resize panel
	local h
	if debugMode then
		-- Header: 8 top + 16 title + 3 + 14 specLine + 5 + 16 overallLine + 3 + 14 statusLine
		-- readyLine (when shown): + 3 + 14
		-- divider: + 4 + 1 + 4
		-- slots: lineCount * 14
		-- bottom: + 8
		local lineCount  = math.min(#results, 17)
		local readyExtra = readyText and 17 or 0
		local noteExtra = fallbackNote and 20 or 0
		h = 8 + 16 + 3 + 14 + 5 + 16 + 3 + 14 + readyExtra + noteExtra + 4 + 1 + 4 + (lineCount * 14) + 8
		if lineCount == 0 then h = 8 + 16 + 3 + 14 + 5 + 16 + 3 + 14 + readyExtra + noteExtra + 8 end
	else
		-- Compact default view: title, spec, score, explanatory note, bottom padding.
		h = 8 + 16 + 3 + 14 + 5 + 16 + 3 + 14 + 4 + (fallbackNote and 54 or 40) + 8
	end
	inspectPanel:SetHeight(h)
	positionInspectPanel(settings)

	inspectPanel:Show()
end

-- ---------------------------------------------------------------
-- Delay timer (OnUpdate pattern — works without C_Timer in TBC Classic)
local timerFrame = CreateFrame("Frame")
timerFrame:Hide()
timerFrame:SetScript("OnUpdate", function(self, elapsed)
	pendingTimer = pendingTimer - elapsed
	if pendingTimer <= 0 then
		self:Hide()
		pendingRefresh = false
		doRefresh()
	end
end)

function scheduleRefresh(delay, isSelf)
	selfMode      = isSelf or false
	pendingTimer  = delay or REFRESH_DELAY
	pendingRefresh = true
	timerFrame:Show()
end

local function ensureHooks()
	if _G.InspectFrame and not inspectHooksInstalled then
		inspectHooksInstalled = true
		_G.InspectFrame:HookScript("OnShow", function()
			selfMode = false
			timerFrame:Hide()
			pendingRefresh = false
			if inspectPanel then
				inspectPanel:Hide()
			end

			if requestInspectData() then
				scheduleRefresh(REFRESH_DELAY, false)
			else
				pendingInspectGUID = captureInspectGUID()
				inspectedGUID = pendingInspectGUID
				scheduleRefresh(0.1, false)
			end
		end)
		_G.InspectFrame:HookScript("OnHide", function()
			inspectedGUID = nil
			pendingInspectGUID = nil
			inspectRetryUntil = 0
			timerFrame:Hide()  -- cancel any pending refresh
			pendingRefresh = false
			if type(ClearInspectPlayer) == "function" then
				ClearInspectPlayer()
			end
			if inspectPanel then
				inspectPanel:Hide()
			end
		end)
	end

	if _G.CharacterFrame and not characterHooksInstalled then
		characterHooksInstalled = true
		_G.CharacterFrame:HookScript("OnShow", function()
			inspectedGUID = nil
			pendingInspectGUID = nil
			scheduleRefresh(0, true)  -- no delay needed for self
		end)
		_G.CharacterFrame:HookScript("OnHide", function()
			timerFrame:Hide()  -- cancel any pending refresh
			pendingRefresh = false
			if selfMode then
				inspectPanel:Hide()
			end
		end)
	end
end

-- ---------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("INSPECT_READY")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == "TBCA_BIS" then
			buildPanel()
			ensureHooks()
		elseif arg1 == "Blizzard_InspectUI" then
			ensureHooks()
			if _G.InspectFrame and _G.InspectFrame:IsShown() then
				selfMode = false
				timerFrame:Hide()
				pendingRefresh = false
				if inspectPanel then
					inspectPanel:Hide()
				end
				if requestInspectData() then
					scheduleRefresh(REFRESH_DELAY, false)
				else
					pendingInspectGUID = captureInspectGUID()
					inspectedGUID = pendingInspectGUID
					scheduleRefresh(0.1, false)
				end
			end
		end
		return
	elseif event == "INSPECT_READY" then
		if selfMode then return end
		if not (_G.InspectFrame and _G.InspectFrame:IsShown()) then return end
		local activeGUID = pendingInspectGUID or captureInspectGUID()
		if activeGUID and arg1 ~= activeGUID then return end

		pendingInspectGUID = arg1
		inspectedGUID = arg1
		scheduleRefresh(0, false)
	elseif event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_EQUIPMENT_CHANGED" then
		if _G.CharacterFrame and _G.CharacterFrame:IsShown() then
			scheduleRefresh(0, true)
		end
	end
end)
