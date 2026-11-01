local _,ns = ...

local function AddIDLine(tooltip, id, idType)
    if id then
        tooltip:AddLine(string.format("|cffffcc00%sID:|r %d", idType, id))
        tooltip:Show()
    end
end

function ns.init()
    -- print("Loaded retail")
    if type(TooltipDataProcessor) ~= "table" then return end
    if type(TooltipDataProcessor.AddTooltipPostCall) ~= "function" then return end
    if type(Enum) ~= "table" or type(Enum.TooltipDataType) ~= "table" then return end
    for k, v in pairs(Enum.TooltipDataType)do
        if TooltipID_GlobalSettings and TooltipID_GlobalSettings.idTable and TooltipID_GlobalSettings.idTable[k] then
            TooltipDataProcessor.AddTooltipPostCall(v, function(tooltip, data)
                -- print("data proc3ssor")
                -- for x,y in pairs(data) do
                --     print(k, x, y)
                -- end
                if data and data.id then
                    AddIDLine(tooltip, data.id, k)
                elseif data and data.guid and k=="Unit" then --obsoleto TooltipID_GlobalSettings["idTable"]["CreatureID"]
                    local ok, creatureID = pcall(C_CreatureInfo.GetCreatureID, data.guid)
                    if ok and creatureID then
                        AddIDLine(tooltip, creatureID, k)
                    end
                    
                    --nota data.guid es una string protegida, no pasa nada en mundo abierto, y es buena forma de sacar el id
                    --pero si es en instancia, probado en dung con seguidores, entonces tira error secure.
                    --fix

                    -- if TooltipID_GlobalSettings["idTable"]["CreatureID"] then
                    --     local inInstance, instanceType = IsInInstance()
                    --     if inInstance then
                    --         return
                    --     end

                    --     local guid = data.guid
                    --     if type(guid) ~= "string" then return end

                    --     -- Type-ServerID-InstanceID-ZoneUID-MapUID-CreatureID-SpawnUID
                    --     local parts = { strsplit("-", guid) }
                    --     if #parts ~= 7 then return end

                    --     local creatureType = parts[1]
                    --     local serverID     = parts[2]
                    --     local instanceID   = parts[3]
                    --     local zoneUID      = parts[4]
                    --     local mapUID       = parts[5]
                    --     local creatureID   = parts[6]
                    --     local spawnUID     = parts[7]
                    --     -- Validar que los campos numéricos sean números, ojo que spawnUID tiene letras
                    --     if not tonumber(creatureID)then
                    --         return
                    --     end

                    --     AddIDLine(tooltip, creatureID, creatureType)
                    -- end
                end
            end)
        end
    end

    -- secure error en combate, desapareció después de la v12.0.1
    -- Enum.TooltipDataType.UnitAura
    -- Enum.TooltipDataType.Aura
    -- Enum.TooltipDataType.Buff
    -- Enum.TooltipDataType.Debuff

    -- hooksecurefunc(GameTooltip, "SetUnitAura", function(self, unit, index, filter)
    --     -- En combate NO tocar tooltip
    --     -- if InCombatLockdown() then return end

    --     -- if not unit or not index then return end
    --     print(filter)

    --     local auraData, info

    --     if filter and filter:find("HELPFUL") then
    --         auraData = C_UnitAuras.GetBuffDataByIndex(unit, index)
    --         info = "BuffID"
    --     elseif filter and filter:find("HARMFUL") then
    --         auraData = C_UnitAuras.GetDebuffDataByIndex(unit, index)
    --         info = "DebuffID"
    --     else
    --         auraData = C_UnitAuras.GetAuraDataByIndex(unit, index)
    --         info = "UnitAuraID"
    --     end

    --     if not auraData or not auraData.spellId then return end

    --     self:AddLine("|cffffcc00"..info..":|r " .. auraData.spellId)
    --     self:Show()
    -- end)

end