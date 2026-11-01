local _, ns = ...
local oGlowClassic = ns.oGlowClassic

local colorTable = ns.colorTable

local frame = CreateFrame('Frame')
frame:Hide()
frame.name = 'Colors'
frame.parent = 'oGlowClassic'

frame:SetScript('OnShow', function(self)
	self:CreateOptions()
	self:SetScript('OnShow', nil)
end)

function frame:CreateOptions()
	local title = ns.createFontString(self, 'GameFontNormalLarge')
	title:SetPoint('TOPLEFT', 16, -16)
	title:SetText'oGlowClassic: Colors'

	local questLabel = QUEST_ITEMS or ITEM_CLASS_QUESTITEM or 'Quest items'

	local backdrop = {
		bgFile = [[Interface\ChatFrame\ChatFrameBackground]], tile = true, tileSize = 16,
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
		insets = {left = 4, right = 4, top = 4, bottom = 4},
	}

	local box = CreateFrame('Frame', nil, self, "BackdropTemplate")
	box:SetBackdrop(backdrop)
	box:SetBackdropColor(.1, .1, .1, .5)
	box:SetBackdropBorderColor(.3, .3, .3, 1)

	box:SetPoint('TOPLEFT', title, 0, -32)
	box:SetPoint'LEFT'
	box:SetPoint('RIGHT', -30, 0)

	local boxTitle = ns.createFontString(self)
	boxTitle:SetPoint('BOTTOMLEFT', box, 'TOPLEFT', 8, 0)
	boxTitle:SetText('Item colors')
	box.title = boxTitle

	local bTitle = ns.createFontString(self)
	bTitle:SetPoint('BOTTOMRIGHT', box, 'TOPRIGHT', -35 - 16 - 5, 0)
	bTitle:SetWidth(40)
	bTitle:SetText'Blue'
	bTitle:SetJustifyH'CENTER'
	box.bTitle = bTitle

	local gTitle = ns.createFontString(self)
	gTitle:SetPoint('RIGHT', bTitle, 'LEFT', -5, 0)
	gTitle:SetWidth(40)
	gTitle:SetText'Green'
	gTitle:SetJustifyH'CENTER'
	box.gTitle = gTitle

	local rTitle = ns.createFontString(self)
	rTitle:SetPoint('RIGHT', gTitle, 'LEFT', -5, 0)
	rTitle:SetWidth(40)
	rTitle:SetText'Red'
	rTitle:SetJustifyH'CENTER'
	box.rTitle = rTitle

	local Swatch_Update = function(self, update, r, g, b)
		local row = self:GetParent()
		self:GetNormalTexture():SetVertexColor(r, g, b)
		row.nameLabel:SetTextColor(r, g, b)

		row.swatch.r = r
		row.swatch.g = g
		row.swatch.b = b

		row.redLabel:SetNumber(math.floor(r * 255 + .5))
		row.greenLabel:SetNumber(math.floor(g * 255 + .5))
		row.blueLabel:SetNumber(math.floor(b * 255 + .5))

		if(update) then
			oGlowClassic:RegisterColor(row.id, r, g, b)
		end
	end

	local Swatch_Ok = function()
		Swatch_Update(box.colorPicker, true, ColorPickerFrame:GetColorRGB())
	end

	local Swatch_Cancel = function()
		Swatch_Update(box.colorPicker, true, ColorPicker_GetPreviousValues())
	end

	local Label_Update = function(self)
		local row = self:GetParent()

		local r = row.redLabel:GetNumber() / 255
		local g = row.greenLabel:GetNumber() / 255
		local b = row.blueLabel:GetNumber() / 255

		Swatch_Update(row.swatch, true, r, g, b)
	end

	local Label_Validate = function(self)
		if(self:GetNumber() > 255) then
			return
		end

		return true
	end

	local Reset_OnClick = function(self)
		local row = self:GetParent()
		Swatch_Update(row.swatch, nil, oGlowClassic:ResetColor(row.id))

		for pipe, active, name, desc in oGlowClassic.IteratePipes() do
			if(active) then
				oGlowClassic:UpdatePipe(pipe)
			end
		end
	end

	local Reset_OnEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(RESET)
	end

	local rows = {}
	local rowsById = {}

	local function createRow(id, prevRow)
		local row = CreateFrame('Button', nil, box, "BackdropTemplate")

		row:SetBackdrop(backdrop)
		row:SetBackdropBorderColor(.3, .3, .3)
		row:SetBackdropColor(.1, .1, .1, .5)

		if(not prevRow) then
			row:SetPoint('TOP', 0, -8)
		else
			row:SetPoint('TOP', prevRow, 'BOTTOM')
		end
		row:SetPoint('LEFT', 6, 0)
		row:SetPoint('RIGHT', -25, 0)
		row:SetHeight(24)

		local swatch = ns.createColorSwatch(row, id)
		swatch:SetPoint('RIGHT', -10, 0)

		swatch.swatchFunc = Swatch_Ok
		swatch.cancelFunc = Swatch_Cancel

		row.swatch = swatch

		local blueLabel = ns.createEditBox(row)
		blueLabel:SetPoint('RIGHT', swatch, 'LEFT', -5, 0)
		blueLabel:SetJustifyH'CENTER'

		blueLabel:SetNumeric(true)
		blueLabel.update = Label_Update
		blueLabel.validate = Label_Validate

		row.blueLabel = blueLabel

		local greenLabel = ns.createEditBox(row)
		greenLabel:SetPoint('RIGHT', blueLabel, 'LEFT', -5, 0)
		greenLabel:SetJustifyH'CENTER'

		greenLabel:SetNumeric(true)
		greenLabel.update = Label_Update
		greenLabel.validate = Label_Validate

		row.greenLabel = greenLabel

		local redLabel = ns.createEditBox(row)
		redLabel:SetPoint('RIGHT', greenLabel, 'LEFT', -5, 0)
		redLabel:SetJustifyH'CENTER'

		redLabel:SetNumeric(true)
		redLabel.update = Label_Update
		redLabel.validate = Label_Validate

		row.redLabel = redLabel

		local nameLabel= ns.createFontString(row)
		nameLabel:SetPoint('LEFT', 10, 0)
		nameLabel:SetPoint('TOP', 0, -4)
		nameLabel:SetPoint'BOTTOM'
		nameLabel:SetJustifyH'LEFT'
		row.nameLabel = nameLabel

		local reset = CreateFrame("Button", nil, row)
		reset:SetSize(16, 16)
		reset:SetPoint('LEFT', row, 'RIGHT')

		reset:SetNormalTexture[[Interface\Buttons\UI-Panel-MinimizeButton-Up]]
		reset:SetPushedTexture[[Interface\Buttons\UI-Panel-MinimizeButton-Down]]
		reset:SetHighlightTexture[[Interface\Buttons\UI-Panel-MinimizeButton-Highlight]]

		reset:SetScript("OnClick", Reset_OnClick)
		reset:SetScript("OnEnter", Reset_OnEnter)
		reset:SetScript("OnLeave", GameTooltip_Hide)
		row.reset = reset

		row.id = id

		table.insert(rows, row)
		rowsById[id] = row

		return row
	end

	for i=0, 7 do
		createRow(i, rows[#rows])
	end
	createRow('quest', rows[#rows])

	box.rows = rows
	box:SetHeight(#rows * 24 + 16)

	function frame:refresh()
		for i=0, 7 do
			local r, g, b = unpack(colorTable[i])
			local row = rowsById[i]
			row.nameLabel:SetText(_G['ITEM_QUALITY' .. i .. '_DESC'])
			Swatch_Update(row.swatch, false, r, g, b)
		end

		local row = rowsById.quest
		row.nameLabel:SetText(questLabel)

		local color = rawget(colorTable, 'quest') or { 1, 0.82, 0 }
		Swatch_Update(row.swatch, false, unpack(color))
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
