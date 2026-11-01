local _, addonTable = ...

local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local textures = {}
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded

local function createTexture(aura)
    local icon = aura.Icon
    if not icon then
        return
    end

    local layer, sublayer = icon:GetDrawLayer()

    local texture = aura:CreateTexture(nil, layer or "BACKGROUND", nil, (sublayer and (sublayer + 1)) or 3)
    texture:SetAllPoints(icon)
    texture:SetMask("Interface\\AddOns\\TemporaryWeaponEnchant\\images\\mask")

    local fontString = aura:CreateFontString(nil, "OVERLAY")
    fontString:SetFontObject("SystemFont_Outline_Small")

    if IsAddOnLoaded("Lorti-UI-Classic") or (IsAddOnLoaded("RougeUI") and RougeUI.Lorti) then
        fontString:SetPoint("TOPRIGHT", aura, "TOPRIGHT", 0, 0)
    else
        fontString:SetPoint("BOTTOMRIGHT", aura, "BOTTOMRIGHT", 0, 0)
    end

    fontString:SetText("")
    texture.fontString = fontString

    return texture
end

------------------------------
--- Blizzard
------------------------------

local function UpdateTemporaryEnchantmentBuffs(BuffFrame, ...)
    local RETURNS_PER_ITEM = 4
    local auraFrames = { BuffFrame.AuraContainer:GetChildren() }
    local numItems = 3
    local auraIndex = 1

    for itemIndex = numItems, 1, -1 do
        local hasEnchant, _, charges, enchantID = select(RETURNS_PER_ITEM * (itemIndex - 1) + 1, ...)

        if hasEnchant and enchantID and addonTable.spells[enchantID] then
            local auraFrame = auraFrames[auraIndex]
            if auraFrame and auraFrame.Icon then
                if not textures[auraFrame] then
                    local tex = createTexture(auraFrame)
                    if tex then
                        textures[auraFrame] = tex
                    else
                        textures[auraFrame] = nil
                    end
                end

                local tex = textures[auraFrame]
                if tex then
                    tex:SetTexture(addonTable.spells[enchantID])
                    tex.fontString:SetText(charges and charges > 0 and charges or "")
                    tex:Show()
                end
            end
            auraIndex = auraIndex + 1
        end
    end

    for i = auraIndex, #auraFrames do
        local tex = textures[auraFrames[i]]
        if tex then
            tex:SetTexture(nil)
            tex.fontString:SetText("")
            tex:Hide()
        end
    end
end

------------------------------
--- Elv- and TukUI
------------------------------

if (IsAddOnLoaded("ElvUI")) then
    local E = unpack(ElvUI):GetModule('Auras')
    local oldFunc = E.UpdateTempEnchant
    E.UpdateTempEnchant = function(self, button, index, expiration)
        oldFunc(self, button, index, expiration)
        local is2 = string.match(button:GetName(), '2$')
        local is1 = string.match(button:GetName(), '1$')
        local hasMainHandEnchant, _, _, mainHandEnchantID, hasOffHandEnchant, _, _, offHandEnchantID = GetWeaponEnchantInfo()
        if is1 and hasMainHandEnchant and addonTable.spells[mainHandEnchantID] then
            button.texture:SetTexture(addonTable.spells[mainHandEnchantID])
        end
        if is2 and hasOffHandEnchant and addonTable.spells[offHandEnchantID] then
            button.texture:SetTexture(addonTable.spells[offHandEnchantID])
        end
    end
elseif IsAddOnLoaded("TukUI") then
    local T = Tukui:unpack()
    local oldFunc = T.Auras.UpdateTempEnchant
    T.Auras.UpdateTempEnchant = function(self, slot)
        oldFunc(self, slot)
        local hasMainHandEnchant, _, _, mainHandEnchantID, hasOffHandEnchant, _, _, offHandEnchantID = GetWeaponEnchantInfo()
        if slot == 16 and hasMainHandEnchant and addonTable.spells[mainHandEnchantID] then
            self.Icon:SetTexture(addonTable.spells[mainHandEnchantID])
        elseif slot ~= 16 and hasOffHandEnchant and addonTable.spells[offHandEnchantID] then
            self.Icon:SetTexture(addonTable.spells[offHandEnchantID])
        end
    end
else
    hooksecurefunc(BuffFrame, "UpdateTemporaryEnchantmentBuffs", UpdateTemporaryEnchantmentBuffs)
end
