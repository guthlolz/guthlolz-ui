--- @type Gears_Namespace
local ns = select(2, ...)

--[[-------------------------------------------------------------------
Types
---------------------------------------------------------------------]]
--- @class SlotItemButton : Button  @Slot items - Examples: CharacterNeckSlot, CharacterChestSlot, etc...
--- @field GetID fun():Identifier   @The slot ID
--- @field popoutButton? Button     @Only on versions with Blizz Equipment Managers

--[[-------------------------------------------------------------------
Local Vars
---------------------------------------------------------------------]]
local strsub, pcall = strsub, pcall
local PaperDollItemsFrame, GetInventorySlotInfo = PaperDollItemsFrame, GetInventorySlotInfo

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]

--- @param slotItemButton Button
--- @return InventorySlotInfo?
local function GetSlotInfo(slotItemButton)
  local slotName = strsub(slotItemButton:GetName(), 10)
  --- @type InventorySlotInfo
  local ok, result = pcall(function()
    -- removes 'Character' in 'Character[SlotName]'
    local slot, icon, checkRelic = GetInventorySlotInfo(slotName)
    return { name = slotName, id = slot, iconID = icon, checkRelic = checkRelic }
  end)
  if not ok then return nil end

  return result
end

--[[-------------------------------------------------------------------
New Library
---------------------------------------------------------------------]]
--- @class CharacterFrameUtil
local o = {}; ns.O.CharacterFrameUtil = o
local p, t = ns:log('CharacterFrameUtil')

--- See Also:: PaperDollFrame.xml # Frame/PaperDollItemsFrame
--- @param callbackFn fun(info:InventorySlotInfo, btn:BlizzCharacterSlotItemButton, po:ButtonObj) | "function(info, btn, po) end"
function o:ForEachEquipmentSlot(callbackFn)
  local pdif = PaperDollItemsFrame
  if not (pdif and GetInventorySlotInfo) then return end

  --- @type table<number, SlotItemButton>
  local children = { pdif:GetChildren() }

  for _, slotItemButton in ipairs(children) do
    local slotID = slotItemButton:GetID()
    if slotID ~= 0 then -- CharacterAmmoSlot can't be ignored
      local parentName = slotItemButton:GetParent():GetName()
      if parentName == 'PaperDollItemsFrame' then
        local slotInfo = GetSlotInfo(slotItemButton)
        -- slotItemButton has a popoutButton
        if slotInfo then callbackFn(slotInfo, slotItemButton, slotItemButton.popoutButton) end
      end
    end
  end
end
