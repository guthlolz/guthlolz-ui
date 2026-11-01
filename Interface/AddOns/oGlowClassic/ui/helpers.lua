local _, ns = ...
local oGlowClassic = ns.oGlowClassic

ns.createFontString = function(parent, template)
    local label = parent:CreateFontString(nil, nil, template or 'GameFontHighlight')
    label:SetJustifyH'LEFT'
    return label
end

do
    local function flushSettingsRegistrations()
        if not (Settings and SettingsPanel) then
            return
        end

        local queue = ns._settingsRegistrationQueue
        if queue and #queue > 0 then
            for i = 1, #queue do
                queue[i]()
            end
            wipe(queue)
        end

        if not ns.mainCategory then
            return
        end

        local subQueue = ns._settingsSubcategoryQueue
        if subQueue and #subQueue > 0 then
            for i = 1, #subQueue do
                subQueue[i]()
            end
            wipe(subQueue)
        end
    end

    ns.QueueSettingsRegistration = function(fn)
        if Settings and SettingsPanel then
            fn()
            return
        end

        if not ns._settingsRegistrationQueue then
            ns._settingsRegistrationQueue = {}
        end
        table.insert(ns._settingsRegistrationQueue, fn)
    end

    ns.QueueSettingsSubcategory = function(fn)
        if Settings and SettingsPanel and ns.mainCategory then
            fn()
            return
        end

        if not ns._settingsSubcategoryQueue then
            ns._settingsSubcategoryQueue = {}
        end
        table.insert(ns._settingsSubcategoryQueue, fn)
    end

    ns.FlushSettingsRegistrations = flushSettingsRegistrations

    oGlowClassic:RegisterEvent('ADDON_LOADED', function(self, event, addon)
        if addon == 'Blizzard_Settings' then
            flushSettingsRegistrations()
        end
    end)
end

ns.Hex = function(r, g, b)
    if type(r) == "table" then
        if r.r then
            r, g, b = r.r, r.g, r.b
        else
            r, g, b = unpack(r)
        end
    end
    return string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
end

do
    local OnEscapePressed = function(self)
        self:SetText(self.oldText)
        self:ClearFocus()
        self:update()
    end

    local OnEnterPressed = function(self)
        self:ClearFocus()
        self:update()
    end

    local OnEditFocusGained = function(self)
        self.oldText = self:GetText()
        self:SetText(self.oldText)
        self.newText = nil
    end

    local OnEditFocusLost = function(self)
        self.newText = nil
        self.oldText = nil
    end

    local OnTextChanged = function(self, userInput)
        if userInput then
            self.newText = self:GetText()
            self:update()
        end
    end

    local OnChar = function(self, key)
        local text = self:GetText()
        if self.validate and not self:validate(text) then
            local pos = self:GetCursorPosition() - 1
            self:SetText(self.newText or self.oldText)
            self:SetCursorPosition(pos)
        end
        self.newText = self:GetText()
    end

    ns.createEditBox = function(self)
        local editbox = CreateFrame('EditBox', nil, self)
        editbox:SetWidth(40)
        editbox:SetMaxLetters(5)
        editbox:SetAutoFocus(false)
        editbox:SetFontObject(GameFontHighlight)
        editbox:SetPoint('TOP', 0, -4)
        editbox:SetPoint('BOTTOM', 0, 0)

        local background = editbox:CreateTexture(nil, 'BACKGROUND')
        background:SetPoint('TOP', 0, -1)
        background:SetPoint'LEFT'
        background:SetPoint'RIGHT'
        background:SetPoint('BOTTOM', 0, 4)
        background:SetTexture(1, 1, 1, .05)

        editbox:SetScript('OnEscapePressed', OnEscapePressed)
        editbox:SetScript('OnEnterPressed', OnEnterPressed)
        editbox:SetScript('OnEditFocusGained', OnEditFocusGained)
        editbox:SetScript('OnEditFocusLost', OnEditFocusLost)
        editbox:SetScript('OnTextChanged', OnTextChanged)
        editbox:SetScript('OnChar', OnChar)

        return editbox
    end
end

do
    local OnClick = function(self)
        local r, g, b = self.r or 1, self.g or 1, self.b or 1
        local info = {
            r = r,
            g = g,
            b = b,
            swatchFunc = function()
                local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                self.r, self.g, self.b = newR, newG, newB
                self:GetNormalTexture():SetVertexColor(newR, newG, newB)

                if self.colorKey then
                    oGlowClassic:RegisterColor(self.colorKey, newR, newG, newB)
                end
            end,
            cancelFunc = function(prev)
                if prev then
                    local oldR, oldG, oldB = prev.r, prev.g, prev.b
                    self.r, self.g, self.b = oldR, oldG, oldB
                    self:GetNormalTexture():SetVertexColor(oldR, oldG, oldB)

                    if self.colorKey then
                        oGlowClassic:RegisterColor(self.colorKey, oldR, oldG, oldB)
                    end
                end
            end
        }

        ColorPickerFrame.previousValues = { r = r, g = g, b = b }
        ColorPickerFrame:SetupColorPickerAndShow(info)
    end

    ns.createColorSwatch = function(self, colorKey)
        local swatch = CreateFrame('Button', nil, self)
        swatch:SetSize(16, 16)

        local background = swatch:CreateTexture(nil, 'BACKGROUND')
        background:SetSize(14, 14)
        background:SetPoint'CENTER'
        background:SetTexture(.3, .3, .3)

        swatch:SetNormalTexture[[Interface\ChatFrame\ChatFrameColorSwatch]]
        swatch:SetScript('OnClick', OnClick)

        swatch.colorKey = colorKey

        -- Haal kleur uit DB of zet default
        local color = oGlowClassicDB.Colors[colorKey] or {1, 1, 1}
        swatch.r, swatch.g, swatch.b = color[1], color[2], color[3]
        swatch:GetNormalTexture():SetVertexColor(color[1], color[2], color[3])

        return swatch
    end
end
