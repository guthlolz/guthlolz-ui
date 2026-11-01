local _, ns = ...
local oGlowClassic = ns.oGlowClassic

local argcheck = oGlowClassic.argcheck
local colorTable = ns.colorTable
local questBorderIntensity = 1
local borderIntensityOverrideAll = false
local borderIntensityAll = 1
local borderIntensityByColor = {}
local borderThickness = 1

local BORDER_INTENSITY_MIN = 0.2
local BORDER_INTENSITY_MAX = 1.0
local BORDER_THICKNESS_MIN = 0.6
local BORDER_THICKNESS_MAX = 1.4

local function clampBorderIntensity(value, fallback)
	if type(value) ~= "number" then
		return fallback or 1
	end

	if value < BORDER_INTENSITY_MIN then
		return BORDER_INTENSITY_MIN
	elseif value > BORDER_INTENSITY_MAX then
		return BORDER_INTENSITY_MAX
	end

	return value
end

local function getBorderIntensity(color)
	if borderIntensityOverrideAll then
		return clampBorderIntensity(borderIntensityAll, 1)
	end

	-- Keep quest behavior backward-compatible with existing slider/storage.
	if color == "quest" then
		return clampBorderIntensity(questBorderIntensity, 1)
	end

	if type(borderIntensityByColor) ~= "table" then
		return 1
	end

	local value = borderIntensityByColor[color]
	if value == nil and type(color) == "number" then
		value = borderIntensityByColor[tostring(color)]
	end

	return clampBorderIntensity(value, 1)
end

local function clampBorderThickness(value, fallback)
	if type(value) ~= "number" then
		return fallback or 1
	end

	if value < BORDER_THICKNESS_MIN then
		return BORDER_THICKNESS_MIN
	elseif value > BORDER_THICKNESS_MAX then
		return BORDER_THICKNESS_MAX
	end

	return value
end

local updateBorderSize = function(border, owner, frame, color)
	if not (border and owner and UIParent and UIParent.GetEffectiveScale and owner.GetEffectiveScale) then
		return
	end

	local uiScale = UIParent:GetEffectiveScale()
	local ownerScale = owner:GetEffectiveScale()

	if type(uiScale) ~= "number" or uiScale <= 0 or type(ownerScale) ~= "number" or ownerScale <= 0 then
		return
	end

	local scaleFix = uiScale / ownerScale

	local baseSize = 70
	if frame and frame.oGlowClassicIsBaganator and frame.GetWidth and frame.GetHeight then
		local w = frame:GetWidth()
		local h = frame:GetHeight()
		if type(w) == "number" and type(h) == "number" and w > 0 and h > 0 then
			baseSize = math.max(w, h) * 1.9
		end
	end

	local thickness = clampBorderThickness(borderThickness, 1)
	border:SetSize(baseSize * scaleFix * thickness, baseSize * scaleFix * thickness)
end

local createBorder = function(self, point)
	local bc = self.oGlowClassicBorder
	if(not bc) then
		local owner = self

		-- Some pipes pass textures instead of frames (e.g. TradeSkill reagent icons).
		-- Textures can't create other textures, so create the border on the nearest parent frame.
		if not (owner and owner.CreateTexture) then
			local parent = owner and owner.GetParent and owner:GetParent() or nil
			while parent and not parent.CreateTexture do
				parent = parent.GetParent and parent:GetParent() or nil
			end
			if parent and parent.CreateTexture then
				owner = parent
			else
				return nil
			end
		end

		if self.GetClipsChildren and self:GetClipsChildren() then
			local parent = self.GetParent and self:GetParent()
			if parent and parent.CreateTexture then
				if not self.oGlowClassicBorderFrame then
					local frame = CreateFrame("Frame", nil, parent)
					frame:SetFrameStrata(self:GetFrameStrata())
					frame:SetFrameLevel(self:GetFrameLevel() + 10)
					self.oGlowClassicBorderFrame = frame
				end
				owner = self.oGlowClassicBorderFrame
			end
		end

		bc = owner:CreateTexture(nil, 'OVERLAY', nil, 7)

		bc:SetTexture"Interface\\Buttons\\UI-ActionButton-Border"
		bc:SetBlendMode"ADD"
		bc:SetAlpha(.8)

		bc:SetPoint("CENTER", point or self)
		self.oGlowClassicBorder = bc

		updateBorderSize(bc, owner, self, nil)
	end

	return bc
end

local function applyBaganatorIconBorderOverride(frame, visible)
	if not (frame and frame.oGlowClassicIsBaganator) then
		return
	end

	local function hideAlphaRegion(region, key)
		if not (region and region.GetAlpha and region.SetAlpha) then
			return
		end

		local storeKey = "oGlowClassic_" .. key .. "_Alpha"

		if visible then
			if frame[storeKey] == nil then
				frame[storeKey] = region:GetAlpha()
			end
			region:SetAlpha(0)
		elseif frame[storeKey] ~= nil then
			region:SetAlpha(frame[storeKey])
			frame[storeKey] = nil
		end
	end

	local function hideBackdropBorderRegion(region, key)
		if not (region and region.GetBackdropBorderColor and region.SetBackdropBorderColor) then
			return
		end

		local storeKey = "oGlowClassic_" .. key .. "_BackdropBorderColor"

		if visible then
			if frame[storeKey] == nil then
				local r, g, b, a = region:GetBackdropBorderColor()
				frame[storeKey] = {r, g, b, a}
			end
			local r, g, b = region:GetBackdropBorderColor()
			region:SetBackdropBorderColor(r or 1, g or 1, b or 1, 0)
		elseif frame[storeKey] ~= nil then
			local saved = frame[storeKey]
			region:SetBackdropBorderColor(saved[1] or 1, saved[2] or 1, saved[3] or 1, saved[4] or 1)
			frame[storeKey] = nil
		end
	end

	local function hideBorderVisual(region, key)
		hideAlphaRegion(region, key)
		hideBackdropBorderRegion(region, key)
	end

	local function hideNamedBorderRegions(container, keyPrefix, skipKeys)
		if type(container) ~= "table" then
			return
		end

		for key, region in pairs(container) do
			if type(key) == "string" and not (skipKeys and skipKeys[key]) then
				local lowerKey = string.lower(key)
				local isBorder = string.find(lowerKey, "border", 1, true) or string.find(lowerKey, "edge", 1, true)
				local isQuestOverlay = string.find(lowerKey, "quest", 1, true) and (
					string.find(lowerKey, "overlay", 1, true) or
					string.find(lowerKey, "glow", 1, true) or
					string.find(lowerKey, "ring", 1, true) or
					string.find(lowerKey, "frame", 1, true)
				)
				if isBorder or isQuestOverlay then
					hideBorderVisual(region, keyPrefix .. "_" .. key)
				end
			end
		end
	end

	local function hideBorderLikeRegionsFromFrame(target, keyPrefix)
		if not (target and target.GetRegions) then
			return
		end

		local regionCount = select("#", target:GetRegions())
		for i = 1, regionCount do
			local region = select(i, target:GetRegions())
			if region and region ~= frame.oGlowClassicBorder then
				local shouldHide = false

				local name = region.GetName and region:GetName() or nil
				if type(name) == "string" then
					local lowerName = string.lower(name)
					if string.find(lowerName, "border", 1, true) or string.find(lowerName, "edge", 1, true) or string.find(lowerName, "quest", 1, true) then
						shouldHide = true
					end
				end

				if not shouldHide and region.GetAtlas then
					local atlas = region:GetAtlas()
					if type(atlas) == "string" then
						local lowerAtlas = string.lower(atlas)
						if string.find(lowerAtlas, "border", 1, true) or string.find(lowerAtlas, "edge", 1, true) or string.find(lowerAtlas, "quest", 1, true) then
							shouldHide = true
						end
					end
				end

				if not shouldHide and region.GetTexture then
					local texturePath = region:GetTexture()
					if type(texturePath) == "string" then
						local lowerTexturePath = string.lower(texturePath)
						if string.find(lowerTexturePath, "border", 1, true) or string.find(lowerTexturePath, "edge", 1, true) or string.find(lowerTexturePath, "quest", 1, true) then
							shouldHide = true
						end
					end
				end

				if shouldHide then
					hideBorderVisual(region, keyPrefix .. "_Region" .. tostring(i) .. "_" .. tostring(region))
				end
			end
		end
	end

	-- Blizzard-style border.
	hideBorderVisual(frame.IconBorder, "IconBorder")
	hideBorderVisual(frame.IconQuestTexture, "IconQuestTexture")
	hideBorderVisual(frame.QuestBorder, "QuestBorder")
	hideBorderVisual(frame.QuestIcon, "QuestIcon")
	hideBorderVisual(frame.IconOverlay, "IconOverlay")
	-- Some skins use button normal texture as border.
	hideBorderVisual(frame.NormalTexture, "NormalTexture")
	if frame.GetNormalTexture then
		hideBorderVisual(frame:GetNormalTexture(), "GetNormalTexture")
	end

	-- Baganator sometimes uses its own thin border textures.
	local bgr = frame.BGR
	if type(bgr) == "table" then
		hideBorderVisual(bgr.border, "BGR_border")
		hideBorderVisual(bgr.Border, "BGR_Border")
		hideBorderVisual(bgr.thinBorder, "BGR_thinBorder")
		hideBorderVisual(bgr.ThinBorder, "BGR_ThinBorder")
		hideBorderVisual(bgr.iconBorder, "BGR_iconBorder")
		hideBorderVisual(bgr.IconBorder, "BGR_IconBorder")
		hideBorderVisual(bgr.QuestBorder, "BGR_QuestBorder")
		hideBorderVisual(bgr.questBorder, "BGR_questBorder")
		hideBorderVisual(bgr.QuestOverlay, "BGR_QuestOverlay")
		hideBorderVisual(bgr.questOverlay, "BGR_questOverlay")
		hideBorderVisual(bgr.QuestIcon, "BGR_QuestIcon")
		hideBorderVisual(bgr.questIcon, "BGR_questIcon")
		hideNamedBorderRegions(bgr, "BGR", {
			border = true,
			Border = true,
			thinBorder = true,
			ThinBorder = true,
			iconBorder = true,
			IconBorder = true,
			QuestBorder = true,
			questBorder = true,
			QuestOverlay = true,
			questOverlay = true,
			QuestIcon = true,
			questIcon = true,
		})
		hideBorderLikeRegionsFromFrame(bgr, "BGRRegions")
	end

	-- Some skins attach border textures directly to the button.
	hideBorderVisual(frame.border, "border")
	hideBorderVisual(frame.Border, "Border")
	hideBorderVisual(frame.thinBorder, "thinBorder")
	hideBorderVisual(frame.ThinBorder, "ThinBorder")
	hideBorderVisual(frame.questBorder, "questBorder")
	hideBorderVisual(frame.QuestOverlay, "QuestOverlay")
	hideBorderVisual(frame.questOverlay, "questOverlay")
	hideBorderLikeRegionsFromFrame(frame, "FrameRegions")
end

local borderDisplay = function(frame, color)
	if(color) then
		local bc = createBorder(frame)
		if not bc then
			return nil
		end
		updateBorderSize(bc, bc:GetParent() or frame, frame, color)
		local rgb = colorTable[color]

		if(rgb) then
			bc:SetVertexColor(rgb[1], rgb[2], rgb[3])
			local intensity = getBorderIntensity(color)
			-- Keep ADD, but remap intensity so lower values stay visible.
			bc:SetBlendMode("ADD")
			bc:SetAlpha(.8 * math.sqrt(intensity))
			bc:Show()
			applyBaganatorIconBorderOverride(frame, true)
		end

		return true
	elseif(frame.oGlowClassicBorder) then
		frame.oGlowClassicBorder:Hide()
		applyBaganatorIconBorderOverride(frame, false)
	end
end

oGlowClassic:RegisterOptionCallback(function(db)
	local filters = db and db.FilterSettings
	if filters and type(filters.questBorderIntensity) == "number" then
		questBorderIntensity = filters.questBorderIntensity
	elseif filters and type(filters.questBorderScale) == "number" then
		-- Back-compat: previously this value was stored as "scale".
		questBorderIntensity = filters.questBorderScale
	else
		questBorderIntensity = 1
	end

	if filters and type(filters.borderIntensityOverrideAll) == "boolean" then
		borderIntensityOverrideAll = filters.borderIntensityOverrideAll
	elseif filters and type(filters.borderScaleOverrideAll) == "boolean" then
		-- Back-compat with previous "scale" key naming.
		borderIntensityOverrideAll = filters.borderScaleOverrideAll
	else
		borderIntensityOverrideAll = false
	end

	if filters and type(filters.borderIntensityAll) == "number" then
		borderIntensityAll = clampBorderIntensity(filters.borderIntensityAll, 1)
	elseif filters and type(filters.borderScaleAll) == "number" then
		-- Back-compat with previous "scale" key naming.
		borderIntensityAll = clampBorderIntensity(filters.borderScaleAll, 1)
	else
		borderIntensityAll = 1
	end

	if filters and type(filters.borderIntensityByColor) == "table" then
		borderIntensityByColor = filters.borderIntensityByColor
	elseif filters and type(filters.borderScaleByColor) == "table" then
		-- Back-compat with previous "scale" key naming.
		borderIntensityByColor = filters.borderScaleByColor
	else
		borderIntensityByColor = {}
	end

	if filters and type(filters.borderThickness) == "number" then
		borderThickness = clampBorderThickness(filters.borderThickness, 1)
	else
		borderThickness = 1
	end
end)

oGlowClassic:RegisterDisplay('Border', borderDisplay)
