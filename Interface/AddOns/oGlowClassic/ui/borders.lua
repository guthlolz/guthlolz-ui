local _, ns = ...
local oGlowClassic = ns.oGlowClassic

local frame = CreateFrame('Frame')
frame:Hide()
frame.name = 'Borders'
frame.parent = 'oGlowClassic'

local BORDER_INTENSITY_MIN = 0.2
local BORDER_INTENSITY_MAX = 1.0
local BORDER_INTENSITY_STEP = 0.05
local BORDER_THICKNESS_MIN = 0.6
local BORDER_THICKNESS_MAX = 1.4
local BORDER_THICKNESS_STEP = 0.05

local QUALITY_KEYS = {0, 1, 2, 3, 4, 5, 6, 7, 'quest'}

local function clampIntensity(value)
	if type(value) ~= "number" then
		return 1
	end

	if value < BORDER_INTENSITY_MIN then
		return BORDER_INTENSITY_MIN
	elseif value > BORDER_INTENSITY_MAX then
		return BORDER_INTENSITY_MAX
	end

	return value
end

local function steppedIntensity(value)
	local stepped = math.floor((value / BORDER_INTENSITY_STEP) + 0.5) * BORDER_INTENSITY_STEP
	return clampIntensity(stepped)
end

local function clampThickness(value)
	if type(value) ~= "number" then
		return 1
	end

	if value < BORDER_THICKNESS_MIN then
		return BORDER_THICKNESS_MIN
	elseif value > BORDER_THICKNESS_MAX then
		return BORDER_THICKNESS_MAX
	end

	return value
end

local function steppedThickness(value)
	local stepped = math.floor((value / BORDER_THICKNESS_STEP) + 0.5) * BORDER_THICKNESS_STEP
	return clampThickness(stepped)
end

local function getQualityLabel(key, questLabel)
	if key == "quest" then
		return questLabel
	end

	return _G['ITEM_QUALITY' .. key .. '_DESC'] or ('Quality ' .. tostring(key))
end

frame:SetScript('OnShow', function(self)
	self:CreateOptions()
	self:SetScript('OnShow', nil)
end)

function frame:CreateOptions()
	local title = ns.createFontString(self, 'GameFontNormalLarge')
	title:SetPoint('TOPLEFT', 16, -16)
	title:SetText('oGlowClassic: Borders')

	local subtitle = ns.createFontString(self, 'GameFontNormalSmall')
	subtitle:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -8)
	subtitle:SetPoint('RIGHT', self, -24, 0)
	subtitle:SetText('Simple mode focuses on global controls. Enable advanced controls for per-quality tuning.')

	local advancedCheckbox = CreateFrame('CheckButton', nil, self, 'InterfaceOptionsCheckButtonTemplate')
	advancedCheckbox:SetPoint('TOPLEFT', subtitle, 'BOTTOMLEFT', 0, -12)
	advancedCheckbox.Text:SetText('Advanced controls')

	local overwriteCheckbox = CreateFrame('CheckButton', nil, self, 'InterfaceOptionsCheckButtonTemplate')
	overwriteCheckbox:SetPoint('TOPLEFT', advancedCheckbox, 'BOTTOMLEFT', 0, -8)
	overwriteCheckbox.Text:SetText('Overwrite all border intensities')

	local allScaleSlider = CreateFrame('Slider', 'oGlowClassicOptBordersAllScale', self, 'OptionsSliderTemplate')
	allScaleSlider:SetPoint('TOPLEFT', overwriteCheckbox, 'BOTTOMLEFT', 0, -24)
	allScaleSlider:SetWidth(280)
	allScaleSlider:SetMinMaxValues(BORDER_INTENSITY_MIN, BORDER_INTENSITY_MAX)
	allScaleSlider:SetValueStep(BORDER_INTENSITY_STEP)
	allScaleSlider:SetValue(1)
	if allScaleSlider.ObeyStepOnDrag then
		allScaleSlider:ObeyStepOnDrag(true)
	end
	if allScaleSlider.Low and allScaleSlider.Low.SetText then
		allScaleSlider.Low:SetText(('%.1fx'):format(BORDER_INTENSITY_MIN))
	end
	if allScaleSlider.High and allScaleSlider.High.SetText then
		allScaleSlider.High:SetText(('%.1fx'):format(BORDER_INTENSITY_MAX))
	end
	allScaleSlider.oGlowClassicLabelText = 'All border intensity'

	local thicknessSlider = CreateFrame('Slider', 'oGlowClassicOptBordersThickness', self, 'OptionsSliderTemplate')
	thicknessSlider:SetPoint('TOPLEFT', allScaleSlider, 'BOTTOMLEFT', 0, -30)
	thicknessSlider:SetWidth(280)
	thicknessSlider:SetMinMaxValues(BORDER_THICKNESS_MIN, BORDER_THICKNESS_MAX)
	thicknessSlider:SetValueStep(BORDER_THICKNESS_STEP)
	thicknessSlider:SetValue(1)
	if thicknessSlider.ObeyStepOnDrag then
		thicknessSlider:ObeyStepOnDrag(true)
	end
	if thicknessSlider.Low and thicknessSlider.Low.SetText then
		thicknessSlider.Low:SetText(('%.1fx'):format(BORDER_THICKNESS_MIN))
	end
	if thicknessSlider.High and thicknessSlider.High.SetText then
		thicknessSlider.High:SetText(('%.1fx'):format(BORDER_THICKNESS_MAX))
	end
	thicknessSlider.oGlowClassicLabelText = 'Border thickness'

	local resetButton = CreateFrame('Button', nil, self, 'UIPanelButtonTemplate')
	resetButton:SetSize(130, 22)
	resetButton:SetPoint('LEFT', thicknessSlider, 'RIGHT', 16, 0)
	resetButton:SetText('Reset to defaults')

	local questLabel = QUEST_ITEMS or ITEM_CLASS_QUESTITEM or 'Quest items'
	local slidersByKey = {}
	local isRefreshing = false
	local advancedHint = ns.createFontString(self, 'GameFontNormalSmall')
	advancedHint:SetPoint('TOPLEFT', thicknessSlider, 'BOTTOMLEFT', 0, -8)
	advancedHint:SetPoint('RIGHT', self, -24, 0)

	local advancedScroll = CreateFrame('ScrollFrame', 'oGlowClassicBordersAdvancedScrollFrame', self, 'UIPanelScrollFrameTemplate')
	advancedScroll:SetPoint('TOPLEFT', advancedHint, 'BOTTOMLEFT', 0, -8)
	advancedScroll:SetPoint('BOTTOMRIGHT', self, -24, 8)
	advancedScroll:EnableMouseWheel(true)

	local advancedContent = CreateFrame('Frame', nil, advancedScroll)
	advancedContent:SetPoint('TOPLEFT', 0, 0)
	advancedContent:SetHeight(1)
	advancedScroll:SetScrollChild(advancedContent)

	local function updateAdvancedContentWidth()
		local w = advancedScroll:GetWidth() - 28
		if w < 120 then
			w = 120
		end
		advancedContent:SetWidth(w)
	end
	advancedScroll:HookScript('OnShow', updateAdvancedContentWidth)
	advancedScroll:HookScript('OnSizeChanged', updateAdvancedContentWidth)

	advancedScroll:SetScript('OnMouseWheel', function(self, delta)
		local sb = self.ScrollBar or _G[self:GetName() .. 'ScrollBar']
		if not sb then
			return
		end
		local minVal, maxVal = sb:GetMinMaxValues()
		local nextVal = sb:GetValue() - (delta * 24)
		if nextVal < minVal then
			nextVal = minVal
		elseif nextVal > maxVal then
			nextVal = maxVal
		end
		sb:SetValue(nextVal)
	end)

	local function updateAllActivePipes()
		for pipe, active in oGlowClassic.IteratePipes() do
			if active then
				oGlowClassic:UpdatePipe(pipe)
			end
		end
	end

	local function ensureFilterSettings()
		if not oGlowClassicDB.FilterSettings then
			oGlowClassicDB.FilterSettings = {}
		end

		if type(oGlowClassicDB.FilterSettings.borderIntensityByColor) ~= "table" then
			oGlowClassicDB.FilterSettings.borderIntensityByColor = {}
		end

		return oGlowClassicDB.FilterSettings
	end

	local function updateSliderLabel(slider, value)
		if slider.Text and slider.Text.SetText then
			slider.Text:SetText(('%s: %.2fx'):format(slider.oGlowClassicLabelText or 'Border intensity', value))
		end
	end

		local function getIntensityForKey(filters, key)
			if key == "quest" then
				local v = 1
				if filters and type(filters.questBorderIntensity) == "number" then
					v = filters.questBorderIntensity
				elseif filters and type(filters.questBorderScale) == "number" then
					v = filters.questBorderScale
				end
			return clampIntensity(v)
		end

		local byColor = filters and filters.borderIntensityByColor
		local value = byColor and byColor[key]
		if value == nil and type(key) == "number" and type(byColor) == "table" then
			value = byColor[tostring(key)]
		end

		if value == nil and filters and type(filters.borderScaleByColor) == "table" then
			-- Back-compat with previous key naming.
			value = filters.borderScaleByColor[key]
			if value == nil and type(key) == "number" then
				value = filters.borderScaleByColor[tostring(key)]
			end
		end

		return clampIntensity(value)
	end

	local function setPerQualityEnabled(enabled)
		for _, key in ipairs(QUALITY_KEYS) do
			local slider = slidersByKey[key]
			if slider then
				slider:SetEnabled(enabled)
				slider:SetAlpha(enabled and 1 or 0.45)
			end
		end
	end

	local function AllScale_OnValueChanged(self, value)
		local stepped = steppedIntensity(value)
		updateSliderLabel(self, stepped)

		if isRefreshing then
			return
		end

		if math.abs(value - stepped) > 0.0001 then
			isRefreshing = true
			self:SetValue(stepped)
			isRefreshing = false
		end

		local filters = ensureFilterSettings()
		filters.borderIntensityAll = stepped

		oGlowClassic:CallOptionCallbacks()
		updateAllActivePipes()
	end

	local function Thickness_OnValueChanged(self, value)
		local stepped = steppedThickness(value)
		updateSliderLabel(self, stepped)

		if isRefreshing then
			return
		end

		if math.abs(value - stepped) > 0.0001 then
			isRefreshing = true
			self:SetValue(stepped)
			isRefreshing = false
		end

		local filters = ensureFilterSettings()
		filters.borderThickness = stepped

		oGlowClassic:CallOptionCallbacks()
		updateAllActivePipes()
	end

	local function PerQualityScale_OnValueChanged(self, value)
		local stepped = steppedIntensity(value)
		updateSliderLabel(self, stepped)

		if isRefreshing then
			return
		end

		if math.abs(value - stepped) > 0.0001 then
			isRefreshing = true
			self:SetValue(stepped)
			isRefreshing = false
		end

		local filters = ensureFilterSettings()
		if self.oGlowClassicColorKey == "quest" then
			-- Keep quest border slider in sync with the original quality setting.
			filters.questBorderIntensity = stepped
			filters.questBorderScale = stepped
		else
			filters.borderIntensityByColor[self.oGlowClassicColorKey] = stepped
		end

		oGlowClassic:CallOptionCallbacks()
		updateAllActivePipes()
	end

	local function Overwrite_OnClick(self)
		if isRefreshing then
			return
		end

		local filters = ensureFilterSettings()
		local checked = self:GetChecked() and true or false
		filters.borderIntensityOverrideAll = checked
		-- Keep legacy key in sync so old fallback paths do not override the new value.
		filters.borderScaleOverrideAll = checked

		frame:refresh()
		oGlowClassic:CallOptionCallbacks()
		updateAllActivePipes()
	end

	local function ResetDefaults_OnClick()
		if isRefreshing then
			return
		end

		local filters = ensureFilterSettings()
		filters.borderIntensityAdvanced = false
		filters.borderIntensityOverrideAll = false
		filters.borderScaleOverrideAll = false
		filters.borderIntensityAll = 1
		filters.borderScaleAll = 1
		filters.borderThickness = 1
		filters.questBorderIntensity = 1
		filters.questBorderScale = 1
		filters.borderIntensityByColor = {}
		filters.borderScaleByColor = {}

		frame:refresh()
		oGlowClassic:CallOptionCallbacks()
		updateAllActivePipes()
	end

	local function Advanced_OnClick(self)
		if isRefreshing then
			return
		end

		local filters = ensureFilterSettings()
		local advanced = self:GetChecked() and true or false
		filters.borderIntensityAdvanced = advanced

		frame:refresh()
		oGlowClassic:CallOptionCallbacks()
		updateAllActivePipes()
	end

	advancedCheckbox:SetScript('OnClick', Advanced_OnClick)
	advancedCheckbox:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
		GameTooltip:SetText('Enable per-quality border intensity controls.', nil, nil, nil, nil, 1)
	end)
	advancedCheckbox:SetScript('OnLeave', GameTooltip_Hide)

	overwriteCheckbox:SetScript('OnClick', Overwrite_OnClick)
	overwriteCheckbox:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
		GameTooltip:SetText('Use one slider value for every border quality.', nil, nil, nil, nil, 1)
	end)
	overwriteCheckbox:SetScript('OnLeave', GameTooltip_Hide)

	resetButton:SetScript('OnClick', ResetDefaults_OnClick)
	resetButton:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
		GameTooltip:SetText('Restore Borders settings to default values.', nil, nil, nil, nil, 1)
	end)
	resetButton:SetScript('OnLeave', GameTooltip_Hide)

	allScaleSlider:SetScript('OnValueChanged', AllScale_OnValueChanged)
	allScaleSlider:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
		GameTooltip:SetText('Global intensity multiplier for all borders.', nil, nil, nil, nil, 1)
	end)
	allScaleSlider:SetScript('OnLeave', GameTooltip_Hide)

	thicknessSlider:SetScript('OnValueChanged', Thickness_OnValueChanged)
	thicknessSlider:SetScript('OnEnter', function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
		GameTooltip:SetText('Controls border thickness/size without changing color intensity.', nil, nil, nil, nil, 1)
	end)
	thicknessSlider:SetScript('OnLeave', GameTooltip_Hide)

		local previousSlider = nil
		for i = 1, #QUALITY_KEYS do
			local key = QUALITY_KEYS[i]
			local slider = CreateFrame('Slider', nil, advancedContent, 'OptionsSliderTemplate')
			if i == 1 then
				slider:SetPoint('TOPLEFT', advancedContent, 'TOPLEFT', 0, -8)
			else
				slider:SetPoint('TOPLEFT', previousSlider, 'BOTTOMLEFT', 0, -28)
			end
			slider:SetPoint('RIGHT', advancedContent, 'RIGHT', -12, 0)
		slider:SetMinMaxValues(BORDER_INTENSITY_MIN, BORDER_INTENSITY_MAX)
		slider:SetValueStep(BORDER_INTENSITY_STEP)
		slider:SetValue(1)
		if slider.ObeyStepOnDrag then
			slider:ObeyStepOnDrag(true)
		end
		if slider.Low and slider.Low.SetText then
			slider.Low:SetText(('%.1fx'):format(BORDER_INTENSITY_MIN))
		end
		if slider.High and slider.High.SetText then
			slider.High:SetText(('%.1fx'):format(BORDER_INTENSITY_MAX))
		end

		slider.oGlowClassicColorKey = key
		slider.oGlowClassicLabelText = getQualityLabel(key, questLabel)
		slider:SetScript('OnValueChanged', PerQualityScale_OnValueChanged)
		slider:SetScript('OnEnter', function(self)
			GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
			GameTooltip:SetText('Intensity multiplier for this specific border quality.', nil, nil, nil, nil, 1)
		end)
		slider:SetScript('OnLeave', GameTooltip_Hide)

			slidersByKey[key] = slider
			previousSlider = slider
		end
		advancedContent:SetHeight((#QUALITY_KEYS - 1) * 28 + 8 + 20 + 16)
		updateAdvancedContentWidth()

	function frame:refresh()
		local filters = oGlowClassicDB and oGlowClassicDB.FilterSettings or {}
		local advanced = filters and filters.borderIntensityAdvanced == true
		local useAll = false
		if filters and type(filters.borderIntensityOverrideAll) == "boolean" then
			useAll = filters.borderIntensityOverrideAll
		elseif filters and type(filters.borderScaleOverrideAll) == "boolean" then
			-- Back-compat with previous key naming.
			useAll = filters.borderScaleOverrideAll
		end

		local allScale = nil
		if filters and type(filters.borderIntensityAll) == "number" then
			allScale = filters.borderIntensityAll
		elseif filters and type(filters.borderScaleAll) == "number" then
			-- Back-compat with previous key naming.
			allScale = filters.borderScaleAll
		end
		allScale = clampIntensity(allScale)
		local thickness = clampThickness(filters and filters.borderThickness)

		isRefreshing = true

		advancedCheckbox:SetChecked(advanced)
		overwriteCheckbox:SetChecked(useAll)
		overwriteCheckbox:SetEnabled(true)
		allScaleSlider:SetValue(allScale)
		updateSliderLabel(allScaleSlider, allScale)
		thicknessSlider:SetValue(thickness)
		updateSliderLabel(thicknessSlider, thickness)

		for i = 1, #QUALITY_KEYS do
			local key = QUALITY_KEYS[i]
			local slider = slidersByKey[key]
			local value = getIntensityForKey(filters, key)
			slider:SetValue(value)
			updateSliderLabel(slider, value)
		end

		if advanced then
			advancedHint:SetText('Disable "Overwrite all border intensities" to tune each quality separately.')
		else
			advancedHint:SetText('Simple mode hides per-quality controls. Enable advanced controls to edit each quality separately.')
		end

		advancedScroll:SetShown(advanced)
		setPerQualityEnabled(advanced and not useAll)
		if advanced then
			advancedScroll:SetVerticalScroll(0)
		end
		advancedScroll:UpdateScrollChildRect()
		isRefreshing = false
	end

	self:refresh()
end

if Settings and SettingsPanel then
	ns.QueueSettingsSubcategory(function()
		local subcategory = Settings.RegisterCanvasLayoutSubcategory(ns.mainCategory, frame, frame.name)
		Settings.RegisterAddOnCategory(subcategory)
	end)
elseif InterfaceOptions_AddCategory then
	InterfaceOptions_AddCategory(frame)
end
