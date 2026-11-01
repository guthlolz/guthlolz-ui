local _, ns = ...
local oGlowClassic = ns.oGlowClassic

local frame = CreateFrame('Frame')
frame.name = 'oGlowClassic'
frame:Hide()

frame:SetScript('OnShow', function(self)
	self:CreateOptions()
	self:SetScript('OnShow', nil)
end)

local _BACKDROP = {
	bgFile = 'BackdropTemplate',
	edgeFile = 'BackdropTemplate',
	tile = true, tileSize = 8, edgeSize = 16,
	insets = {left = 2, right = 2, top = 2, bottom = 2}
}

local createCheckBox = function(parent)
	local check = CreateFrame('CheckButton', nil, parent)
	check:SetSize(16, 16)

	check:SetNormalTexture[[Interface\Buttons\UI-CheckBox-Up]]
	check:SetPushedTexture[[Interface\Buttons\UI-CheckBox-Down]]
	check:SetHighlightTexture[[Interface\Buttons\UI-CheckBox-Highlight]]
	check:SetCheckedTexture[[Interface\Buttons\UI-CheckBox-Check]]

	return check
end

function frame:CreateOptions()
	local title = ns.createFontString(self, 'GameFontNormalLarge')
	title:SetPoint('TOPLEFT', 16, -16)
	title:SetText('oGlowClassic')

	local subtitle = ns.createFontString(self)
	subtitle:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -8)
	subtitle:SetPoint('RIGHT', self, -32, 0)
	subtitle:SetText'Now with 30% less toxic radiation!'

	local scroll = CreateFrame("ScrollFrame", "oGlowClassicOptionsScrollFrame", self, "UIPanelScrollFrameTemplate")
	scroll:SetPoint('TOPLEFT', subtitle, 'BOTTOMLEFT', 0, -8)
	scroll:SetPoint("BOTTOMRIGHT", 0, 4)
	self.scroll = scroll

	local scrollBar = scroll.ScrollBar or _G[scroll:GetName() .. "ScrollBar"]
	if scrollBar then
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint('TOPRIGHT', self, -6, -68)
		scrollBar:SetPoint('BOTTOMRIGHT', self, -6, 10)
	end

	local scrollchild = CreateFrame("Frame", nil, scroll)
	scrollchild.rows = {}
	scrollchild:SetPoint('TOPLEFT', 0, 0)
	do
		local scrollBarWidth = (scrollBar and scrollBar:GetWidth()) or 16
		scrollchild:SetPoint('TOPRIGHT', -(scrollBarWidth + 6), 0)
	end
	scrollchild:SetHeight(1)
	self.scrollchild = scrollchild

	local filterFrame = CreateFrame('Frame', nil, self)
	filterFrame.rows = {}
	filterFrame:Hide()
	self.filterFrame = filterFrame

	scroll:SetScrollChild(scrollchild)
	scroll:EnableMouseWheel(true)

	scroll:SetVerticalScroll(0)

	self:refresh()

	local function updateScrollChildWidth()
		if not self.scroll or not self.scrollchild then return end
		local sb = self.scroll.ScrollBar or (self.scroll.GetName and _G[self.scroll:GetName() .. "ScrollBar"])
		local sbw = (sb and sb:GetWidth()) or 16
		local w = self.scroll:GetWidth() - sbw - 12
		if w > 0 then
			self.scrollchild:SetWidth(w)
		end
	end

	scroll:HookScript('OnShow', updateScrollChildWidth)
	scroll:HookScript('OnSizeChanged', updateScrollChildWidth)
	updateScrollChildWidth()
end

do
	local CheckBox_OnClick = function(self)
		local pipe = self:GetParent().pipe
		if(self:GetChecked()) then
			oGlowClassic:EnablePipe(pipe)
		else
			oGlowClassic:DisablePipe(pipe)
		end

		oGlowClassic:UpdatePipe(pipe)
	end

	local Filter_OnClick = function(self)
		local pipe = self:GetParent().pipe
		if(self:GetChecked()) then
			oGlowClassic:RegisterFilterOnPipe(pipe, self.name)
		else
			oGlowClassic:UnregisterFilterOnPipe(pipe, self.name)
		end

		oGlowClassic:UpdatePipe(pipe)
	end

	local Row_OnClick = function(self)
		self.owner.active = self

		local filterFrame = self.owner.filterFrame
		if not filterFrame then return end
		filterFrame.pipe = self.pipe

		filterFrame:Show()
		filterFrame:SetParent(self)

		filterFrame:ClearAllPoints()
		filterFrame:SetPoint('TOP', self.check, 'BOTTOM', 0, -2)
		filterFrame:SetPoint('LEFT', 16, 0)
		filterFrame:SetPoint('RIGHT', -16, 0)

		self:SetHeight(20 + filterFrame:GetHeight())

		for i = 1, #filterFrame do
			local filter = filterFrame[i]
			filter:SetChecked(nil)
			for name in oGlowClassic.IterateFiltersOnPipe(self.pipe) do
				filter:SetChecked(filter.name == name)
			end
		end

		do
			local rows = self.owner.scrollchild.rows
			local n = 1
			local row = rows[n]
			while row do
				if row ~= self.owner.active then
					row:SetBackdropBorderColor(.3, .3, .3)
					row:SetHeight(20)
				end
				n = n + 1
				row = rows[n]
			end
		end

		self.owner:UpdateScrollChildSize()
		self.owner.scroll:UpdateScrollChildRect()
	end

	local Row_OnEnter = function(self)
		self:SetBackdropBorderColor(.5, .9, .06)

		GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
		GameTooltip:SetText"Click for additional settings."
	end

	local Row_OnLeave = function(self)
		self:SetBackdropBorderColor(.3, .3, .3)

		GameTooltip_Hide()
	end

	local createRow = function(parent, i)
		local row = CreateFrame('Button', nil, parent, "BackdropTemplate")

		row:SetBackdrop(_BACKDROP)
		row:SetBackdropColor(.1, .1, .1, .5)
		row:SetBackdropBorderColor(.3, .3, .3)

		if(i == 1) then
			row:SetPoint('TOP', 0, -4)
		else
			row:SetPoint('TOP', parent.rows[i - 1], 'BOTTOM')
		end

		row:SetPoint('LEFT', 6, 0)
		row:SetPoint('RIGHT', -6, 0)
		row:SetHeight(20)

		row:SetScript('OnEnter', Row_OnEnter)
		row:SetScript('OnLeave', Row_OnLeave)
		row:SetScript('OnClick', Row_OnClick)

		local check = createCheckBox(row)
		check:SetPoint('LEFT', 10, 0)
		check:SetPoint('TOP', 0, -2)
		check:SetScript('OnClick', CheckBox_OnClick)
		row.check = check

		local label = ns.createFontString(row)
		label:SetPoint('LEFT', check, 'RIGHT', 5, -1)
		row.label = label

		table.insert(parent.rows, row)
		return row
	end

	function frame:UpdateScrollChildSize()
		local sChild = self.scrollchild
		if not sChild then return end

		local height = 8 -- top + bottom padding
		for i = 1, #sChild.rows do
			local row = sChild.rows[i]
			if row and row:IsShown() then
				height = height + row:GetHeight()
			end
		end

		sChild:SetHeight(height)
	end

	function frame:refresh()
		local sChild = self.scrollchild
		local filterFrame = self.filterFrame
		if not filterFrame then
			return
		end

		local filters = {}
		for name, type, desc in oGlowClassic.IterateFilters() do
			table.insert(filters, {name = name; type = type, desc = desc})
		end

		local numFilters = #filters
		local split = 2
		if(numFilters > 1) then
			split = math.floor(numFilters / 2) + (numFilters % 2) + 1
		end

		for i = 1, numFilters do
			local filter = filters[i]
			local check = filterFrame[i]
			if not check then
				check = createCheckBox(filterFrame)
				filterFrame[i] = check
			end

			check:ClearAllPoints()
			if(i == 1) then
				check:SetPoint('TOPLEFT', 0, -2)
			elseif(i == split) then
				check:SetPoint('TOP', 0, -2)
			else
				check:SetPoint('TOP', filterFrame[i - 1], 'BOTTOM')
			end

			check:SetScript('OnClick', Filter_OnClick)

			local label = check.label
			if not label then
				label = ns.createFontString(check)
				label:SetPoint('LEFT', check, 'RIGHT', 5, -1)
				check.label = label
			end
			label:SetText(filter.name)

			check.name = filter.name
			check.desc = filter.desc
			check.type = filter.type
			filterFrame[i] = check
			check:Show()
		end

		filterFrame:SetHeight(((split-1) * 16) + 18)
		filterFrame:Hide()

		local n = 1
		for pipe, active, name, desc in oGlowClassic.IteratePipes() do
			local row = sChild.rows[n] or createRow(sChild, n)

			row:SetBackdropBorderColor(.3, .3, .3)
			row:SetHeight(24)

			row.owner = self
			row.pipe = pipe
			row.check:SetChecked(active)
			row.label:SetText(name)
			row:Show()
			row:SetHeight(20)

			n = n + 1
		end

		for i = n, #sChild.rows do
			sChild.rows[i]:Hide()
		end

		if self.active and self.active:IsShown() then
			Row_OnClick(self.active)
		else
			self:UpdateScrollChildSize()
			self.scroll:UpdateScrollChildRect()
		end
	end
end

if Settings and SettingsPanel then
	ns.QueueSettingsRegistration(function()
		local category = Settings.RegisterCanvasLayoutCategory(frame, frame.name)
		Settings.RegisterAddOnCategory(category)
		ns.mainCategory = category
		ns.mainCategoryID = category.ID
		ns.FlushSettingsRegistrations()
	end)
elseif InterfaceOptions_AddCategory then
	InterfaceOptions_AddCategory(frame)
	ns.mainCategory = frame
end

SLASH_OGLOW_UI1 = '/oglow'
SlashCmdList['OGLOW_UI'] = function()
    if Settings and SettingsPanel then
		if not ns.mainCategory then
			ns.FlushSettingsRegistrations()
		end
		local categoryID = ns.mainCategoryID or (ns.mainCategory and ns.mainCategory.ID)
		if type(categoryID) == 'number' then
			Settings.OpenToCategory(categoryID)
		end
    else
        InterfaceOptionsFrame_OpenToCategory('oGlowClassic')
    end
end
