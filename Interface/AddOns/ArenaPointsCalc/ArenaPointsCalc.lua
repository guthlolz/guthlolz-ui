-- ============================================================
--  ArenaPointsCalc — TBC Anniversary Season 1
--  Two-way calculator: rating → points, points → rating.
--  Click the PTS/WEEK box to type a target and get the needed
--  rating. Click YOU RECEIVE to target a total across all brackets.
-- ============================================================

local ADDON_NAME = "ArenaPointsCalc"

local MULTIPLIER    = { ["2v2"] = 0.76, ["3v3"] = 0.88, ["5v5"] = 1.00 }
local BRACKET_ORDER = { "2v2", "3v3", "5v5" }
local BRACKET_COLOR = {
    ["2v2"] = { r=0.88, g=0.44, b=0.19 },
    ["3v3"] = { r=0.19, g=0.63, b=0.88 },
    ["5v5"] = { r=0.37, g=0.75, b=0.37 },
}
local BRACKET_INDEX = { ["2v2"] = 1, ["3v3"] = 2, ["5v5"] = 3 }

-- ─── Blizzard formula (Official Feb 18 2026) ─────────────────
local function CalcBase(rating)
    if not rating or rating <= 0 then return 0 end
    return ((1651.94 - 475) / (1 + 2500000 * math.exp(-0.009 * rating)) + 475) * 1.5
end

local function CalcPoints(rating, mult)
    return math.ceil(CalcBase(rating) * mult)
end

-- ─── Reverse: given a target points value and multiplier,
--     binary-search for the minimum rating that yields >= target pts.
--     Returns nil if unreachable (>3000 rating needed).
local function CalcRatingForPoints(targetPts, mult)
    if targetPts <= 0 then return 0 end
    -- Max possible points at rating 3000
    if CalcPoints(3000, mult) < targetPts then return nil end
    local lo, hi = 0, 3000
    for _ = 1, 30 do  -- 30 iterations is more than enough precision
        local mid = math.floor((lo + hi) / 2)
        if CalcPoints(mid, mult) >= targetPts then
            hi = mid
        else
            lo = mid + 1
        end
    end
    -- hi is now the minimum rating that hits targetPts
    -- verify it's exact (floor might mean we overshoot by 1)
    if CalcPoints(hi, mult) == targetPts then
        return hi
    elseif CalcPoints(hi, mult) > targetPts then
        -- walk down to find exact match
        while hi > 0 and CalcPoints(hi - 1, mult) >= targetPts do
            hi = hi - 1
        end
        return hi
    end
    return hi
end

-- ─── Colour helpers ──────────────────────────────────────────
local function Gold(t)   return "|cffF0C060"..t.."|r" end
local function Dim(t)    return "|cff6a5a3a"..t.."|r" end
local function Green(t)  return "|cff80c080"..t.."|r" end
local function Grey(t)   return "|cff888888"..t.."|r" end
local function Cyan(t)   return "|cff60d0d0"..t.."|r" end

ArenaPointsCalcDB = ArenaPointsCalcDB or {}

local ui        = {}
local mainFrame = nil

-- ─── Live data ───────────────────────────────────────────────
local function GetLiveRating(bracket)
    local idx = BRACKET_INDEX[bracket]
    if not idx then return nil end
    if GetPersonalRatedInfo then
        local rating = GetPersonalRatedInfo(idx)
        if rating and rating > 0 then
            return rating
        end
    end
    local bracketSize = tonumber(bracket:match("(%d+)"))
    for slot = 1, 3 do
        if GetArenaTeamInfo then
            local name, size, rating2 = GetArenaTeamInfo(slot)
            if size and size == bracketSize and rating2 and rating2 > 0 then
                return rating2
            end
        end
    end
    return nil
end

local function FetchAllRatings()
    local results = {}
    for _, bracket in ipairs(BRACKET_ORDER) do
        results[bracket] = { rating = GetLiveRating(bracket) }
    end
    return results
end

-- =====================================================================
--  BUILD UI
-- =====================================================================
local function BuildUI()

    local f = CreateFrame("Frame", "APCMainFrame", UIParent, "BackdropTemplate")
    f:SetSize(310, 310)   -- slightly taller to fit pts editboxes
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        ArenaPointsCalcDB.pos = { point=point, relPoint=relPoint, x=x, y=y }
    end)

    if ArenaPointsCalcDB.pos then
        local p = ArenaPointsCalcDB.pos
        f:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    else
        f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 760, -104)
    end

    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true, tileSize=32, edgeSize=26,
        insets={ left=8, right=8, top=8, bottom=8 },
    })
    f:SetBackdropColor(0.04, 0.03, 0.07, 0.97)
    f:SetBackdropBorderColor(0.6, 0.48, 0.18, 0.9)

    -- Gold accent bar
    local topBar = f:CreateTexture(nil, "ARTWORK")
    topBar:SetColorTexture(0.78, 0.61, 0.24, 0.7)
    topBar:SetSize(270, 1)
    topBar:SetPoint("TOP", f, "TOP", 0, -12)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.ttf", 15, "OUTLINE")
    title:SetPoint("TOP", topBar, "BOTTOM", 0, -5)
    title:SetText(Gold("Arena Points Calculator"))
    title:SetShadowColor(0, 0, 0, 1)
    title:SetShadowOffset(1, -1)

    local sub = f:CreateFontString(nil, "OVERLAY")
    sub:SetFont("Fonts\\FRIZQT__.ttf", 9, "")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -1)
    sub:SetTextColor(0.45, 0.4, 0.28, 1)
    sub:SetText("Season 3  |  drag to move")

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local statusLbl = f:CreateFontString(nil, "OVERLAY")
    statusLbl:SetFont("Fonts\\FRIZQT__.ttf", 8, "")
    statusLbl:SetPoint("TOP", sub, "BOTTOM", 0, -1)
    statusLbl:SetJustifyH("CENTER")
    statusLbl:SetText("")
    ui.statusLbl = statusLbl

    local sep1 = f:CreateTexture(nil, "ARTWORK")
    sep1:SetColorTexture(0.78, 0.61, 0.24, 0.25)
    sep1:SetSize(278, 1)
    sep1:SetPoint("TOP", statusLbl, "BOTTOM", 0, -4)

    -- ── Columns ───────────────────────────────────────────────
    ui.ratingBoxes  = {}   -- EditBox: rating input
    ui.ptsBoxes     = {}   -- EditBox: points input (reverse mode)
    ui.pointFrames  = {}   -- Frame wrapping the pts editbox
    ui.modeFlags    = {}   -- true = pts→rating mode for this bracket

    local colW   = 82
    local colGap = 8
    local totalW = colW * 3 + colGap * 2
    local startX = -(totalW / 2) + (colW / 2)

    -- forward-declare so closures can reference it
    local Recalculate

    for i, bracket in ipairs(BRACKET_ORDER) do
        local mult = MULTIPLIER[bracket]
        local c    = BRACKET_COLOR[bracket]
        local cx   = startX + (i - 1) * (colW + colGap)

        ui.modeFlags[bracket] = false  -- start in normal (rating→pts) mode

        -- Header
        local hdr = f:CreateFontString(nil, "OVERLAY")
        hdr:SetFont("Fonts\\MORPHEUS.ttf", 13, "OUTLINE")
        hdr:SetPoint("TOP", sep1, "BOTTOM", cx, -8)
        hdr:SetTextColor(c.r, c.g, c.b, 1)
        hdr:SetText(bracket)

        local mTag = f:CreateFontString(nil, "OVERLAY")
        mTag:SetFont("Fonts\\FRIZQT__.ttf", 8, "")
        mTag:SetPoint("TOP", hdr, "BOTTOM", 0, -1)
        mTag:SetTextColor(0.48, 0.43, 0.28, 1)
        mTag:SetText(("x%.2f"):format(mult))

        local uline = f:CreateTexture(nil, "ARTWORK")
        uline:SetColorTexture(c.r, c.g, c.b, 0.6)
        uline:SetSize(colW - 4, 1)
        uline:SetPoint("TOP", mTag, "BOTTOM", 0, -3)

        -- ── RATING label + editbox ────────────────────────────
        local rLbl = f:CreateFontString(nil, "OVERLAY")
        rLbl:SetFont("Fonts\\FRIZQT__.ttf", 8, "")
        rLbl:SetPoint("TOP", uline, "BOTTOM", 0, -5)
        rLbl:SetTextColor(0.55, 0.5, 0.32, 1)
        rLbl:SetText("RATING")

        local rEB = CreateFrame("EditBox", "APCRating_"..bracket, f, "InputBoxTemplate")
        rEB:SetSize(colW - 10, 20)
        rEB:SetPoint("TOP", rLbl, "BOTTOM", 0, -2)
        rEB:SetAutoFocus(false)
        rEB:SetNumeric(true)
        rEB:SetMaxLetters(4)
        rEB:SetFont("Fonts\\FRIZQT__.ttf", 13, "OUTLINE")
        rEB:SetTextColor(0.95, 0.88, 0.65, 1)
        rEB:SetJustifyH("CENTER")
        if ArenaPointsCalcDB[bracket] then
            rEB:SetText(tostring(ArenaPointsCalcDB[bracket]))
        end
        rEB.bracket = bracket
        rEB:SetScript("OnTextChanged", function(self)
            if ui.modeFlags[self.bracket] then return end  -- pts mode driving
            ArenaPointsCalcDB[self.bracket] = tonumber(self:GetText())
            if Recalculate then Recalculate() end
        end)
        rEB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        rEB:SetScript("OnEnterPressed",  function(self) self:ClearFocus() end)
        ui.ratingBoxes[bracket] = rEB

        -- Games played label (hidden — not shown to players)
        local gLbl = f:CreateFontString(nil, "OVERLAY")
        gLbl:SetFont("Fonts\\FRIZQT__.ttf", 8, "")
        gLbl:SetPoint("TOP", rEB, "BOTTOM", 0, -2)
        gLbl:Hide()

        -- ── PTS/WEEK box (click to enter target pts) ──────────
        local pFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
        pFrame:SetSize(colW - 4, 42)
        pFrame:SetPoint("TOP", rEB, "BOTTOM", 0, -6)
        pFrame:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile=true, tileSize=8, edgeSize=8,
            insets={ left=2, right=2, top=2, bottom=2 },
        })
        pFrame:SetBackdropColor(0, 0, 0, 0.55)
        pFrame:SetBackdropBorderColor(c.r, c.g, c.b, 0.3)
        pFrame:EnableMouse(true)
        ui.pointFrames[bracket] = pFrame

        -- Points EditBox inside pFrame (hidden until clicked)
        local pEB = CreateFrame("EditBox", "APCPts_"..bracket, pFrame, "InputBoxTemplate")
        pEB:SetSize(colW - 18, 18)
        pEB:SetPoint("CENTER", pFrame, "CENTER", 0, 4)
        pEB:SetAutoFocus(false)
        pEB:SetNumeric(true)
        pEB:SetMaxLetters(4)
        pEB:SetFont("Fonts\\FRIZQT__.ttf", 13, "OUTLINE")
        pEB:SetJustifyH("CENTER")
        pEB:Hide()
        pEB.bracket = bracket

        -- Points display label (shown when not editing)
        local pVal = pFrame:CreateFontString(nil, "OVERLAY")
        pVal:SetFont("Fonts\\MORPHEUS.ttf", 14, "OUTLINE")
        pVal:SetPoint("CENTER", pFrame, "CENTER", 0, 4)
        pVal:SetTextColor(c.r, c.g, c.b, 1)
        pVal:SetText("-")
        ui.ptsBoxes[bracket] = { eb=pEB, lbl=pVal }

        local pLab = pFrame:CreateFontString(nil, "OVERLAY")
        pLab:SetFont("Fonts\\FRIZQT__.ttf", 7, "")
        pLab:SetPoint("BOTTOM", pFrame, "BOTTOM", 0, 4)
        pLab:SetTextColor(0.38, 0.34, 0.22, 1)
        pLab:SetText("PTS/WEEK")

        -- Tooltip hint on hover
        pFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("|cffF0C060Click to set target points|r", 1, 1, 1, 1, true)
            GameTooltip:AddLine("Type a points goal to find the\nrating needed in this bracket.", 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        pFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- Click the pts frame → switch to reverse mode
        pFrame:SetScript("OnMouseDown", function(self)
            local b = bracket
            ui.modeFlags[b] = true
            -- colour the border cyan to signal reverse mode
            local cc = BRACKET_COLOR[b]
            pFrame:SetBackdropBorderColor(0.4, 0.9, 0.9, 0.9)
            pVal:Hide()
            pEB:Show()
            pEB:SetTextColor(0.4, 0.9, 0.9, 1)  -- cyan text in reverse mode
            -- pre-fill with current pts value so user sees what they're editing
            local currentPts = tonumber(pVal:GetText()) or ""
            pEB:SetText(tostring(currentPts))
            pEB:SetFocus()
            pEB:HighlightText()
        end)

        -- Reverse editbox logic
        pEB:SetScript("OnTextChanged", function(self)
            if not ui.modeFlags[bracket] then return end
            local targetPts = tonumber(self:GetText())
            if targetPts and targetPts > 0 then
                local neededRating = CalcRatingForPoints(targetPts, MULTIPLIER[bracket])
                local ratingEB = ui.ratingBoxes[bracket]
                if neededRating then
                    ratingEB:SetText(tostring(neededRating))
                    ratingEB:SetTextColor(0.4, 0.9, 0.9, 1)  -- cyan = reverse-driven
                    -- Show actual points that rating yields, not the typed target
                    local actualPts = CalcPoints(neededRating, MULTIPLIER[bracket])
                    pVal:SetText(tostring(actualPts))
                    pVal:SetTextColor(0.4, 0.9, 0.9, 1)
                else
                    ratingEB:SetText("3000+")
                    ratingEB:SetTextColor(0.9, 0.4, 0.4, 1)
                    pVal:SetText("!max")
                    pVal:SetTextColor(0.9, 0.4, 0.4, 1)
                end
            else
                ui.ratingBoxes[bracket]:SetText("")
                ui.ratingBoxes[bracket]:SetTextColor(0.95, 0.88, 0.65, 1)
                pVal:SetText("-")
                local cc = BRACKET_COLOR[bracket]
                pVal:SetTextColor(cc.r, cc.g, cc.b, 1)
            end
            -- Update the total summary without re-triggering the pts boxes
            if Recalculate then Recalculate(true) end
        end)

        -- Escape or Enter exits reverse mode cleanly
        local function exitReverseMode(self)
            self:ClearFocus()
            self:Hide()
            ui.ptsBoxes[bracket].lbl:Show()
            ui.modeFlags[bracket] = false
            ui.ratingBoxes[bracket]:SetTextColor(0.95, 0.88, 0.65, 1)
            local cc = BRACKET_COLOR[bracket]
            pFrame:SetBackdropBorderColor(cc.r, cc.g, cc.b, 0.8)
            if Recalculate then Recalculate() end
        end
        pEB:SetScript("OnEscapePressed", exitReverseMode)
        pEB:SetScript("OnEnterPressed",  exitReverseMode)
        pEB:SetScript("OnEditFocusLost", function(self)
            if ui.modeFlags[bracket] then exitReverseMode(self) end
        end)
    end

    -- ── Divider above summary ─────────────────────────────────
    local sep2 = f:CreateTexture(nil, "ARTWORK")
    sep2:SetColorTexture(0.78, 0.61, 0.24, 0.25)
    sep2:SetSize(278, 1)
    sep2:SetPoint("BOTTOM", f, "BOTTOM", 0, 68)

    -- ── YOU RECEIVE row ───────────────────────────────────────
    local recvLbl = f:CreateFontString(nil, "OVERLAY")
    recvLbl:SetFont("Fonts\\FRIZQT__.ttf", 9, "")
    recvLbl:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 52)
    recvLbl:SetTextColor(0.55, 0.5, 0.32, 1)
    recvLbl:SetText("YOU RECEIVE:")
    ui.recvLbl = recvLbl  -- store so AutoFill can reset it

    -- Clickable total label (switches to editbox for global reverse)
    local totalLbl = f:CreateFontString(nil, "OVERLAY")
    totalLbl:SetFont("Fonts\\MORPHEUS.ttf", 16, "OUTLINE")
    totalLbl:SetPoint("LEFT", recvLbl, "RIGHT", 6, 0)
    totalLbl:SetTextColor(0.94, 0.75, 0.24, 1)
    totalLbl:SetText("-")
    ui.totalLabel = totalLbl

    -- Invisible button over the YOU RECEIVE total for click detection
    local totalBtn = CreateFrame("Button", nil, f)
    totalBtn:SetSize(80, 22)
    totalBtn:SetPoint("LEFT", recvLbl, "RIGHT", 4, 0)
    totalBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("|cffF0C060Click to set points target|r", 1,1,1,1, true)
        GameTooltip:AddLine("Fill all brackets with the rating\nneeded to reach this points total.", 0.8,0.8,0.8, true)
        GameTooltip:Show()
    end)
    totalBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Global target points EditBox (replaces the YOU RECEIVE number)
    local totalEB = CreateFrame("EditBox", "APCTotalEB", f, "InputBoxTemplate")
    totalEB:SetSize(70, 20)
    totalEB:SetPoint("LEFT", recvLbl, "RIGHT", 6, 0)
    totalEB:SetAutoFocus(false)
    totalEB:SetNumeric(true)
    totalEB:SetMaxLetters(4)
    totalEB:SetFont("Fonts\\MORPHEUS.ttf", 15, "OUTLINE")
    totalEB:SetTextColor(0.4, 0.9, 0.9, 1)
    totalEB:SetJustifyH("LEFT")
    totalEB:Hide()
    ui.totalEB = totalEB

    totalBtn:SetScript("OnClick", function()
        recvLbl:SetText("POINTS GOAL:")
        totalLbl:Hide()
        totalEB:Show()
        totalEB:SetFocus()
        -- Pre-fill with current total
        local cur = totalLbl:GetText():gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
        totalEB:SetText(cur ~= "-" and cur or "")
        totalEB:HighlightText()
    end)

    totalEB:SetScript("OnTextChanged", function(self)
        local targetPts = tonumber(self:GetText())
        if not targetPts or targetPts <= 0 then return end
        -- Fill all three bracket rating boxes with the needed rating for this target
        for _, bracket in ipairs(BRACKET_ORDER) do
            local neededRating = CalcRatingForPoints(targetPts, MULTIPLIER[bracket])
            local rEB = ui.ratingBoxes[bracket]
            ui.modeFlags[bracket] = true
            if neededRating then
                rEB:SetText(tostring(neededRating))
                rEB:SetTextColor(0.4, 0.9, 0.9, 1)
                -- Show actual points that rating yields, not the typed target
                local actualPts = CalcPoints(neededRating, MULTIPLIER[bracket])
                ui.ptsBoxes[bracket].lbl:SetText(tostring(actualPts))
            else
                rEB:SetText("3000+")
                rEB:SetTextColor(0.9, 0.4, 0.4, 1)
                ui.ptsBoxes[bracket].lbl:SetText("!max")
            end
        end
        totalLbl:SetText("|cff40d0d0"..targetPts.."|r")
    end)

    -- Fully revert to YOU RECEIVE (Escape or Refresh)
    local function exitTotalModeRevert(self)
        self:ClearFocus()
        self:Hide()
        recvLbl:SetText("YOU RECEIVE:")
        totalLbl:Show()
        -- Clear the goal-driven ratings and restore normal mode
        for _, bracket in ipairs(BRACKET_ORDER) do
            ui.modeFlags[bracket] = false
            ui.ratingBoxes[bracket]:SetText("")
            ui.ratingBoxes[bracket]:SetTextColor(0.95, 0.88, 0.65, 1)
            ui.ptsBoxes[bracket].lbl:SetText("-")
            local cc = BRACKET_COLOR[bracket]
            ui.pointFrames[bracket]:SetBackdropBorderColor(cc.r, cc.g, cc.b, 0.25)
        end
        totalLbl:SetText("-")
        ui.bestLabel:SetText("")
    end
    ui.exitTotalModeRevert = exitTotalModeRevert

    -- Confirm with Enter: keep POINTS GOAL label, just lose focus
    local function exitTotalModeConfirm(self)
        self:ClearFocus()
        self:Hide()
        -- Keep label as POINTS GOAL since the goal is still active
        recvLbl:SetText("POINTS GOAL:")
        totalLbl:Show()
    end

    totalEB:SetScript("OnEscapePressed", exitTotalModeRevert)
    totalEB:SetScript("OnEnterPressed",  exitTotalModeConfirm)

    -- Refresh button: always exit goal mode first, then autofill
    local refreshBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    refreshBtn:SetSize(62, 18)
    refreshBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 46)
    refreshBtn:SetText("Refresh")
    refreshBtn:GetFontString():SetFont("Fonts\\FRIZQT__.ttf", 9, "")
    refreshBtn:SetScript("OnClick", function()
        -- If in goal mode, revert it fully before pulling live data
        if totalEB:IsShown() then
            ui.exitTotalModeRevert(totalEB)
        end
        if ui.AutoFill then ui.AutoFill() end
    end)

    local bestLbl = f:CreateFontString(nil, "OVERLAY")
    bestLbl:SetFont("Fonts\\FRIZQT__.ttf", 8, "")
    bestLbl:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 36)
    bestLbl:SetTextColor(0.45, 0.4, 0.26, 1)
    bestLbl:SetText("")
    ui.bestLabel = bestLbl

    -- Mode hint line
    local hintLbl = f:CreateFontString(nil, "OVERLAY")
    hintLbl:SetFont("Fonts\\FRIZQT__.ttf", 8, "")
    hintLbl:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 22)
    hintLbl:SetTextColor(0.38, 0.34, 0.22, 1)
    hintLbl:SetText(Dim("Click pts box or total to reverse-calculate"))
    ui.hintLbl = hintLbl

    local noteLbl = f:CreateFontString(nil, "OVERLAY")
    noteLbl:SetFont("Fonts\\FRIZQT__.ttf", 8, "")
    noteLbl:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 10)
    noteLbl:SetTextColor(0.38, 0.34, 0.22, 1)
    noteLbl:SetText("10+ games required")
    ui.noteLabel = noteLbl

    -- =================================================================
    --  RECALCULATE
    --  skipPtsUpdate=true when called from inside the pts editbox
    --  so we don't clobber what the user is actively typing
    -- =================================================================
    Recalculate = function(skipPtsUpdate)
        local best = { bracket=nil, points=-1 }

        for _, bracket in ipairs(BRACKET_ORDER) do
            local rEB  = ui.ratingBoxes[bracket]
            if not rEB then return end
            local rating = tonumber(rEB:GetText())
            local pts    = (rating and rating > 0)
                           and CalcPoints(rating, MULTIPLIER[bracket])
                           or nil

            if not skipPtsUpdate then
                local pEntry = ui.ptsBoxes[bracket]
                if not ui.modeFlags[bracket] then
                    -- Normal mode: update the display label
                    pEntry.lbl:SetText(pts and tostring(pts) or "-")
                    local cc = BRACKET_COLOR[bracket]
                    pEntry.lbl:SetTextColor(cc.r, cc.g, cc.b, 1)
                    ui.pointFrames[bracket]:SetBackdropBorderColor(
                        cc.r, cc.g, cc.b, pts and 0.8 or 0.25)
                end
            end

            if pts and pts > best.points then
                best.points  = pts
                best.bracket = bracket
            end
        end

        if best.bracket then
            if not totalEB:IsShown() then
                totalLbl:SetText(Gold(tostring(best.points)))
            end
            ui.bestLabel:SetText(Dim("* best from "..best.bracket.." bracket"))
        else
            if not totalEB:IsShown() then
                totalLbl:SetText("-")
            end
            ui.bestLabel:SetText("")
        end
    end

    ui.Recalculate = Recalculate

    -- =================================================================
    --  AUTO-FILL
    -- =================================================================
    ui.AutoFill = function()
        -- Exit any reverse modes first
        for _, bracket in ipairs(BRACKET_ORDER) do
            ui.modeFlags[bracket] = false
            ui.ratingBoxes[bracket]:SetTextColor(0.95, 0.88, 0.65, 1)
            local pEB2 = ui.ptsBoxes[bracket].eb
            if pEB2:IsShown() then
                pEB2:Hide()
                ui.ptsBoxes[bracket].lbl:Show()
            end
        end
        -- Always reset the YOU RECEIVE label in case we were in goal mode
        if ui.recvLbl then ui.recvLbl:SetText("YOU RECEIVE:") end

        local data   = FetchAllRatings()
        local filled = 0
        for _, bracket in ipairs(BRACKET_ORDER) do
            local d   = data[bracket]
            local rEB = ui.ratingBoxes[bracket]
            if d.rating and d.rating > 0 then
                rEB:SetText(tostring(d.rating))
                ArenaPointsCalcDB[bracket] = d.rating
                filled = filled + 1
            end
        end
        ui.statusLbl:SetText(
            filled > 0
            and Green("* Live data: "..filled.." bracket(s) loaded")
            or  Grey("No team data — enter ratings manually"))
        Recalculate()
    end

    mainFrame = f
    Recalculate()
    f:Hide()
end

-- =====================================================================
--  EVENTS
-- =====================================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

local initialFillDone = false

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        ArenaPointsCalcDB = ArenaPointsCalcDB or {}
    end
    if event == "PLAYER_ENTERING_WORLD" then
        initialFillDone = false
        C_Timer.After(1, function()
            if not mainFrame then BuildUI() end
            C_Timer.After(1, function()
                if ui.AutoFill and not initialFillDone then
                    initialFillDone = true
                    ui.AutoFill()
                end
            end)
        end)
    end
end)

-- =====================================================================
--  HOOK: show/hide with PvP tab
-- =====================================================================
C_Timer.After(3, function()
    if PVPFrame then
        PVPFrame:HookScript("OnShow", function()
            if mainFrame then mainFrame:Show() end
        end)
        PVPFrame:HookScript("OnHide", function()
            if mainFrame then mainFrame:Hide() end
        end)
    end
end)

-- =====================================================================
--  SLASH  /apc
-- =====================================================================
SLASH_ARENACALC1 = "/apc"
SlashCmdList["ARENACALC"] = function()
    if not mainFrame then BuildUI(); mainFrame:Show(); return end
    if mainFrame:IsShown() then
        mainFrame:Hide()
        print(Gold("[ArenaCalc]").." Hidden — type /apc to reopen.")
    else
        mainFrame:Show()
    end
end

print(Gold("[ArenaCalc]").." Loaded! Open your PvP tab or type "..Gold("/apc").." to toggle.")
