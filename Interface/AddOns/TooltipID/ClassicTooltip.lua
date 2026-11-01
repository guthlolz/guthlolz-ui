local _, ns = ...

local function AddIDToTooltip(tooltip, id, idType)
    if not id or not tooltip then return end
    tooltip:AddLine(string.format("|cffffcc00%sID:|r %d", idType, id))
    tooltip:Show()
end

function ns.init()
    if GameTooltip and GameTooltip.HookScript then
        if TooltipID_GlobalSettings.idTable["itemID"] then
            GameTooltip:HookScript("OnTooltipSetItem", function(self)
                local _, link = self:GetItem()
                if link then
                    local itemID = tonumber(string.match(link, "item:(%d+):"))
                    AddIDToTooltip(self, itemID, "Item")
                end
            end)
        end
        if TooltipID_GlobalSettings.idTable["spellID"] then
            GameTooltip:HookScript("OnTooltipSetSpell", function(self)
                if self.GetSpell then
                    local spellID = select(2, self:GetSpell())
                    AddIDToTooltip(self, spellID, "Spell")
                end
            end)
        end
    end

    if type(UnitAura) == "function" then
        if TooltipID_GlobalSettings.idTable["UnitAura"] then
            hooksecurefunc(GameTooltip, "SetUnitAura", function(self, unit, index, filter)
                local _, _, _, _, _, _, _, _, _, spellID = UnitAura(unit, index, filter)
                AddIDToTooltip(self, spellID, "Aura")
            end)
        end
    end

    if type(UnitBuff) == "function" then
        if TooltipID_GlobalSettings.idTable["UnitBuff"] then
            hooksecurefunc(GameTooltip, "SetUnitBuff", function(self, unit, index, filter)
                local _, _, _, _, _, _, _, _, _, spellID = UnitBuff(unit, index, filter)
                AddIDToTooltip(self, spellID, "Buff")
            end)
        end
    end

    if type(UnitDebuff) == "function" then
        if TooltipID_GlobalSettings.idTable["UnitDebuff"] then
            hooksecurefunc(GameTooltip, "SetUnitDebuff", function(self, unit, index, filter)
                local _, _, _, _, _, _, _, _, _, spellID = UnitDebuff(unit, index, filter)
                AddIDToTooltip(self, spellID, "Debuff")
            end)
        end
    end
end
