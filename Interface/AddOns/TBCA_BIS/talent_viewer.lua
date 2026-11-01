-- talent_viewer.lua
-- Inline talent tree viewer overlaid on AtlasLoot's content frame.
-- Renders a recommended BiS talent build using GetTalentInfo() (current class only).
-- Open with: _G.TBCA_OpenTalentViewer(specKey, buildIdx, parentFrame)
-- Hide with: _G.TBCA_HideTalentViewer()

-- ── Build data ────────────────────────────────────────────────────────────────
-- specKey must match keys used in AtlasLootClassic_TBCA_BIS/talents.lua.
-- string = wowhead talent-calc: trees separated by "-", each char = pts in order.
_G.TBCA_TALENT_BUILDS = _G.TBCA_TALENT_BUILDS or {}
local TALENT_BUILDS = _G.TBCA_TALENT_BUILDS

-- ── Layout constants (tuned for AtlasLoot ItemFrame ~560×450) ─────────────────
local BTN    = 40
local GAP    = 3
local CELL   = BTN + GAP   -- 43
local COLS   = 4
local ROWS   = 9
local TREE_W = COLS * CELL - GAP   -- 169
local TREE_H = ROWS * CELL - GAP   -- 384
local TSEP   = 12   -- gap between trees
local MX     = 9    -- horizontal margin
local TY_OFF = 38   -- y from frame top where tree area begins

-- ── Wowhead string helpers ────────────────────────────────────────────────────
local function parseTalentString(str)
	local trees = {}
	local startPos = 1
	local len = str and #str or 0

	if len == 0 then
		return trees
	end

	for i = 1, len do
		if str:sub(i, i) == "-" then
			trees[#trees + 1] = str:sub(startPos, i - 1)
			startPos = i + 1
		end
	end
	trees[#trees + 1] = str:sub(startPos)

	return trees
end

local function strToPoints(s)
	local pts = {}
	for i = 1, #s do pts[#pts + 1] = tonumber(s:sub(i, i)) or 0 end
	return pts
end

local talentOrderCache = {}

local function getTalentOrder(tabIdx)
	local cached = talentOrderCache[tabIdx]
	if cached then
		return cached
	end

	local ordered = {}
	local numTalents = GetNumTalents and GetNumTalents(tabIdx) or 0
	for talIdx = 1, numTalents do
		local talName, icon, tier, col, _, maxRank = GetTalentInfo(tabIdx, talIdx)
		if talName and tier and col then
			ordered[#ordered + 1] = {
				index = talIdx,
				tier = tier,
				col = col,
				name = talName,
				icon = icon,
				maxRank = maxRank,
			}
		end
	end

	table.sort(ordered, function(a, b)
		if a.tier ~= b.tier then
			return a.tier < b.tier
		end
		if a.col ~= b.col then
			return a.col < b.col
		end
		return a.index < b.index
	end)

	talentOrderCache[tabIdx] = ordered
	return ordered
end

-- ── Button pool ───────────────────────────────────────────────────────────────
local pool       = {}
local activeBtns = {}

local function recycleAll()
	for _, b in ipairs(activeBtns) do
		b:Hide()
		b:ClearAllPoints()
		b:SetScript("OnEnter", nil)
		b:SetScript("OnLeave", nil)
		pool[#pool + 1] = b
	end
	wipe(activeBtns)
end

local function getBtn(parent)
	local b = table.remove(pool)
	if not b then
		b = CreateFrame("Button", nil, parent)
		b:SetSize(BTN, BTN)

		local plate = b:CreateTexture(nil, "BACKGROUND")
		plate:SetTexture("Interface\\Buttons\\WHITE8X8")
		plate:SetPoint("TOPLEFT", b, "TOPLEFT", 2, -2)
		plate:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
		plate:SetVertexColor(0, 0, 0, 0.5)
		b.plate = plate

		local slot = b:CreateTexture(nil, "BACKGROUND")
		slot:SetTexture("Interface\\Buttons\\UI-Quickslot2")
		slot:SetAllPoints(b)
		b.slot = slot

		local icon = b:CreateTexture(nil, "BORDER")
		icon:SetPoint("TOPLEFT",     b, "TOPLEFT",     2, -2)
		icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		b.icon = icon

		local hl = b:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints(b)
		hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
		hl:SetBlendMode("ADD")

		local rankBg = b:CreateTexture(nil, "ARTWORK")
		rankBg:SetTexture("Interface\\Buttons\\WHITE8X8")
		rankBg:SetVertexColor(0, 0, 0, 0.85)
		rankBg:SetSize(24, 12)
		rankBg:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 2, 0)
		b.rankBg = rankBg

		local rank = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		rank:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 3, -1)
		rank:SetJustifyH("RIGHT")
		b.rank = rank
	end
	return b
end

-- ── Viewer state ──────────────────────────────────────────────────────────────
local viewer      = nil
local curSpec     = nil
local curBuildIdx = 1

-- ── Render ────────────────────────────────────────────────────────────────────
local function renderBuild()
	if not viewer or not curSpec then return end
	local builds = TALENT_BUILDS[curSpec]
	if not builds or not builds[curBuildIdx] then return end
	local build = builds[curBuildIdx]

	recycleAll()

	local treePtStrings = parseTalentString(build.string)
	local ptArrays = {}
	for i, s in ipairs(treePtStrings) do ptArrays[i] = strToPoints(s) end

	local numTabs = GetNumTalentTabs and GetNumTalentTabs() or 0
	for tabIdx = 1, numTabs do
		local tabName, _, _, bgFile = GetTalentTabInfo(tabIdx)
		local ptArray = ptArrays[tabIdx] or {}
		local orderedTalents = getTalentOrder(tabIdx)
		local treeX   = MX + (tabIdx - 1) * (TREE_W + TSEP)

		local bg = viewer.treeBgs[tabIdx]
		if bg and bgFile and bgFile ~= "" then
			bg:SetTexture(bgFile)
			bg:SetTexCoord(0.025, 0.975, 0.025, 0.925)
		end

		local lbl = viewer.treeLabels[tabIdx]
		if lbl and tabName then lbl:SetText(tabName) end

		for orderIdx = 1, #orderedTalents do
			local talentData = orderedTalents[orderIdx]
			local talName = talentData.name
			local icon = talentData.icon
			local tier = talentData.tier
			local col = talentData.col
			local maxRank = talentData.maxRank
			if talName and tier and col and tier >= 1 and col >= 1 then
				local pts = ptArray[orderIdx] or 0
				local btn = getBtn(viewer.treeArea)
				activeBtns[#activeBtns + 1] = btn

				local bx = treeX + (col - 1) * CELL
				local by = -((tier - 1) * CELL)
				btn:SetPoint("TOPLEFT", viewer.treeArea, "TOPLEFT", bx, by)
				btn:Show()

				if icon then
					btn.icon:SetTexture(icon)
					if pts > 0 then
						btn.icon:SetDesaturated(false)
						btn.icon:SetAlpha(1.0)
						btn.plate:SetVertexColor(0, 0, 0, 0.4)
						btn.slot:SetVertexColor(1, 1, 1)
					else
						btn.icon:SetDesaturated(true)
						btn.icon:SetAlpha(0.9)
						btn.plate:SetVertexColor(0, 0, 0, 0.7)
						btn.slot:SetVertexColor(1, 1, 1)
					end
				end

				if pts > 0 then
					btn.rankBg:Show()
					btn.rank:SetText(pts .. "/" .. (maxRank or "?"))
					btn.rank:SetTextColor(1, 0.82, 0)
				else
					btn.rankBg:Hide()
					btn.rank:SetText("")
				end

				local tN, tPts, tMax = talName, pts, (maxRank or "?")
				btn:SetScript("OnEnter", function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:AddLine(tN, 1, 1, 1)
					if tPts > 0 then
						GameTooltip:AddLine("Recommended: " .. tPts .. "/" .. tMax, 0.2, 1, 0.2, true)
					else
						GameTooltip:AddLine("Not used in this build", 0.55, 0.55, 0.55, true)
					end
					GameTooltip:Show()
				end)
				btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
			end
		end
	end

	viewer.buildLabel:SetText((build.title or build.name) .. "  |cFF888888(" .. build.source .. ")|r")
end

-- ── Frame creation (lazy) ─────────────────────────────────────────────────────
local function createViewer(parentFrame)
	if not parentFrame then
		return nil
	end

	local numTabs = GetNumTalentTabs and GetNumTalentTabs() or 3

	local f = CreateFrame("Frame", "TBCA_TalentViewer", parentFrame, "BackdropTemplate")
	f:SetAllPoints(parentFrame)
	f:SetFrameStrata("HIGH")
	f:SetFrameLevel((parentFrame and parentFrame:GetFrameLevel() or 0) + 10)
	f:EnableMouse(true)   -- block clicks from passing through to frames below
	f:Hide()

	f:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		tile = true, tileSize = 32,
	})
	f:SetBackdropColor(0, 0, 0, 0.93)

	-- build name label at top
	local buildLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	buildLabel:SetPoint("TOPLEFT",  f, "TOPLEFT",  MX, -10)
	buildLabel:SetPoint("TOPRIGHT", f, "TOPRIGHT", -MX, -10)
	buildLabel:SetJustifyH("LEFT")
	f.buildLabel = buildLabel

	-- tree area
	local treeArea = CreateFrame("Frame", nil, f)
	treeArea:SetPoint("TOPLEFT",     f, "TOPLEFT",     MX,  -TY_OFF)
	treeArea:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -MX,  10)
	f.treeArea   = treeArea
	f.treeBgs    = {}
	f.treeLabels = {}

	for tabIdx = 1, numTabs do
		local treeX = (tabIdx - 1) * (TREE_W + TSEP)

		local panel = CreateFrame("Frame", nil, treeArea, "BackdropTemplate")
		panel:SetPoint("TOPLEFT",     treeArea, "TOPLEFT",  treeX,          0)
		panel:SetPoint("BOTTOMRIGHT", treeArea, "TOPLEFT",  treeX + TREE_W, -TREE_H)
		panel:SetBackdrop({
			bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		panel:SetBackdropColor(0.03, 0.03, 0.08, 1)
		panel:SetBackdropBorderColor(0.38, 0.38, 0.58, 0.95)

		local bg = panel:CreateTexture(nil, "BACKGROUND")
		bg:SetPoint("TOPLEFT",     panel, "TOPLEFT",     3,  -3)
		bg:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -3,  3)
		bg:SetAlpha(0.28)
		f.treeBgs[tabIdx] = bg

		local lbl = treeArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		lbl:SetPoint("BOTTOM", panel, "TOP", 0, 3)
		lbl:SetTextColor(0.9, 0.85, 0.5)
		f.treeLabels[tabIdx] = lbl

		if tabIdx < numTabs then
			local div = f:CreateTexture(nil, "ARTWORK")
			div:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
			div:SetVertexColor(0.25, 0.25, 0.4, 0.6)
			div:SetSize(1, TREE_H + 20)
			div:SetPoint("TOPLEFT", treeArea, "TOPLEFT",
				treeX + TREE_W + math.floor(TSEP / 2), 0)
		end
	end

	viewer = f
	return f
end

-- ── Public API ────────────────────────────────────────────────────────────────
function _G.TBCA_OpenTalentViewer(specKey, buildIdx, parentFrame)
	if not TALENT_BUILDS[specKey] then return end
	if not parentFrame then return end
	if not viewer then
		viewer = createViewer(parentFrame)
	elseif viewer:GetParent() ~= parentFrame then
		viewer:SetParent(parentFrame)
		viewer:ClearAllPoints()
		viewer:SetAllPoints(parentFrame)
		viewer:SetFrameLevel((parentFrame:GetFrameLevel() or 0) + 10)
	end
	if not viewer then return end

	curSpec      = specKey
	curBuildIdx  = buildIdx or 1

	renderBuild()
	viewer:Show()
	viewer:Raise()
end

function _G.TBCA_HideTalentViewer()
	if viewer then viewer:Hide() end
end
