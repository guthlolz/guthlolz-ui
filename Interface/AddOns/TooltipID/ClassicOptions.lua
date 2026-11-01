local _, ns = ...
local L = ns.L

local panel = CreateFrame("Frame", "TooltipID options", UIParent)
panel.name = "TooltipID by OverCraft"

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText(L["TooltipID options"])

local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
description:SetText(L["Show the following tooltip for this list:"])

local inset = CreateFrame("Frame", nil, panel, "InsetFrameTemplate3")
inset:SetPoint("TOPLEFT", description, "BOTTOMLEFT", -4, -8)
inset:SetSize(620, 400)

local scrollFrame = CreateFrame("ScrollFrame", nil, inset, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 6, -6)
scrollFrame:SetPoint("BOTTOMRIGHT", -28, 6)

local scrollChild = CreateFrame("Frame")
scrollChild:SetSize(580, 1)
scrollFrame:SetScrollChild(scrollChild)

local function reloadUIOptions()
    local function createCheckbox(k, last, first)
        if TooltipID_GlobalSettings.idTable[k] == nil then
            TooltipID_GlobalSettings.idTable[k] = true
        end
        
        local checkbox = CreateFrame(
            "CheckButton",
            "TooltipIDCheckbox_" .. tostring(k),
            scrollChild,
            "InterfaceOptionsCheckButtonTemplate"
        )
        
        if first then
            checkbox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
            first = false
        else
            checkbox:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -8)
        end
        
        checkbox.Text:SetText(tostring(k))
        checkbox:SetChecked(TooltipID_GlobalSettings.idTable[k])
        
        checkbox:SetScript("OnClick", function(self)
            TooltipID_GlobalSettings.idTable[k] = self:GetChecked()
            PlaySound(self:GetChecked() and 856 or 857)
        end)
        
        return checkbox, first
    end

    local last
    local first = true
    local extraTypes = {
        itemID = true,
        spellID = true,
        UnitAura = true,
        UnitBuff = true,
        UnitDebuff = true,
    }

    -- if Enum and Enum.TooltipDataType then
    --     for k, v in pairs(Enum.TooltipDataType) do
    --         last, first = createCheckbox(k, last, first)
    --     end
    -- end

    for k, v in pairs(extraTypes) do
        last, first = createCheckbox(k, last, first)
    end
    
    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetSize(240, 24)
    btn:SetText(L["Reload UI to apply changes"])
    btn:SetPoint("TOPLEFT", inset, "BOTTOMLEFT", 4, -12)

    btn:SetScript("OnClick", function()
        ReloadUI()
    end)
end

if InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
else
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
end

local f = CreateFrame("Frame")
local load_once = true
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if load_once then
            local initTable = {}
            initTable["idTable"] = {}
            -- initTable["idTable"]["CreatureID"] = true
            TooltipID_GlobalSettings = TooltipID_GlobalSettings or initTable
            -- for k, v in pairs(initTable["idTable"]) do
            --     if TooltipID_GlobalSettings["idTable"][k] == nil then
            --         TooltipID_GlobalSettings["idTable"][k] = v
            --     end
            -- end
            reloadUIOptions()
            load_once = false
        end
    end
end)