--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Gears_Namespace
local ns = select(2, ...)

--[[-------------------------------------------------------------------
Blizzard Vars
---------------------------------------------------------------------]]
local C_GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots
local C_GetContainerItemInfo = C_Container and C_Container.GetContainerItemInfo
local C_IsSpellKnown = C_SpellBook and C_SpellBook.IsSpellKnown or IsSpellKnown
local C_IsEquippableItem = C_Item and C_Item.IsEquippableItem or IsEquippableItem

local DUAL_WIELD_SPID = 674
--[[-------------------------------------------------------------------
Data Bags
---------------------------------------------------------------------]]
local EQUIP_LOC_TO_SLOT_MAP = {
  INVTYPE_HEAD = { INVSLOT_HEAD }, -- 1
  INVTYPE_NECK = { INVSLOT_NECK }, -- 2
  INVTYPE_SHOULDER = { INVSLOT_SHOULDER }, -- 3
  INVTYPE_BODY = { INVSLOT_BODY }, -- 4
  INVTYPE_CHEST = { INVSLOT_CHEST }, -- 5
  INVTYPE_ROBE = { INVSLOT_CHEST }, -- 5
  INVTYPE_WAIST = { INVSLOT_WAIST }, -- 6
  INVTYPE_LEGS = { INVSLOT_LEGS }, -- 7
  INVTYPE_FEET = { INVSLOT_FEET }, -- 8
  INVTYPE_WRIST = { INVSLOT_WRIST }, -- 9
  INVTYPE_HAND = { INVSLOT_HAND }, -- 10
  INVTYPE_FINGER = { INVSLOT_FINGER1, INVSLOT_FINGER2 }, -- 11, 12
  INVTYPE_TRINKET = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 }, -- 13, 14
  INVTYPE_CLOAK = { INVSLOT_BACK }, -- 15
  INVTYPE_WEAPONMAINHAND = { INVSLOT_MAINHAND }, -- 16
  INVTYPE_2HWEAPON = { INVSLOT_MAINHAND }, -- 16
  INVTYPE_WEAPON = { INVSLOT_MAINHAND, INVSLOT_OFFHAND }, -- 16, 17
  INVTYPE_WEAPONOFFHAND = { INVSLOT_OFFHAND }, -- 17
  INVTYPE_SHIELD = { INVSLOT_OFFHAND }, -- 17
  INVTYPE_HOLDABLE = { INVSLOT_OFFHAND }, -- 17
  INVTYPE_RANGED = { INVSLOT_RANGED }, -- 18
  INVTYPE_RANGEDRIGHT = { INVSLOT_RANGED }, -- 18
  INVTYPE_THROWN = { INVSLOT_RANGED }, -- 18
  INVTYPE_RELIC = { INVSLOT_RANGED }, -- 18
  INVTYPE_TABARD = { INVSLOT_TABARD }, -- 19
}

--[[-----------------------------------------------------------------------------
Module::InventoryUtil
-------------------------------------------------------------------------------]]

--- @see NamespaceObjects
local libName = 'InventoryUtil'

--- @class InventoryUtil
local o = {}; ns.O.InventoryUtil = o

local p, t = ns:log(libName)

--[[-------------------------------------------------------------------
Support Functions
---------------------------------------------------------------------]]
local function itemUtil() return ns.O.ItemUtil end

--- @return boolean
local function IsRangedEquipLoc(equipLoc)
  return equipLoc == 'INVTYPE_RANGED' or equipLoc == 'INVTYPE_RANGEDRIGHT'
end

--- @return boolean
local function RangedSlotMatches(slotID)
  -- If slot is ranged → always valid
  if slotID == INVSLOT_RANGED then return true end

  -- If slot is mainhand → only valid if runtime allows it
  if slotID == INVSLOT_MAINHAND then
    local rangedItem = GetInventoryItemID('player', INVSLOT_RANGED)
    return rangedItem == nil or rangedItem == 0
  end

  return false
end

--- @param slotID SlotID
--- @param item ItemInfoDetails
--- @return boolean
local function CanEquipInHandSlot(slotID, item)
  -- general equip check (class/level/etc)
  if not C_IsEquippableItem(item.id) then return false end

  -- 🔑 mainhand / offhand rules
  if slotID == INVSLOT_OFFHAND then
    local equipLoc = item.equipLoc

    -- offhand-only items are fine
    if
      equipLoc == 'INVTYPE_WEAPONOFFHAND'
      or equipLoc == 'INVTYPE_SHIELD'
      or equipLoc == 'INVTYPE_HOLDABLE'
    then
      return true
    end

    -- 1H weapon → requires dual wield
    if equipLoc == 'INVTYPE_WEAPON' then
      return IsDualWielding() or C_IsSpellKnown(DUAL_WIELD_SPID) -- fallback
    end

    return false
  end

  -- mainhand always OK for valid weapons
  if slotID == INVSLOT_MAINHAND then return true end

  return true
end

--- @param slotID SlotID
--- @param item ItemInfoDetails
--- @return boolean
local function SlotMatches(slotID, item)
  if not item then return false end
  local equipLoc = item.equipLoc
  if not CanEquipInHandSlot(slotID, item) then return false end

  if IsRangedEquipLoc(equipLoc) then return RangedSlotMatches(slotID) end

  -- thrown remains strictly ranged
  if equipLoc == 'INVTYPE_THROWN' then return slotID == INVSLOT_RANGED end

  local slots = EQUIP_LOC_TO_SLOT_MAP[equipLoc]
  if not slots then return false end

  for _, s in ipairs(slots) do
    if s == slotID then return true end
  end

  return false
end

--[[-----------------------------------------------------------------------------
Module::InventoryUtil (Methods)
-------------------------------------------------------------------------------]]

--- @param slotID SlotID
--- @param callbackFn fun(info:ContainerItemDetails, item:ItemInfoDetails) : void
function o:ForEachSlotItemCandidate(slotID, callbackFn)
  self:ForEachBagItemMatchingSlot(slotID, callbackFn)
  self:ForEachEquippedItem(slotID, callbackFn)
end

--- @param slotID SlotID
--- @param callbackFn fun(info:ContainerItemDetails, item:ItemInfoDetails) : void
function o:ForEachBagItemMatchingSlot(slotID, callbackFn)
  local it = itemUtil()
  self:ForEachBagItem(function(info)
    local link = info.hyperlink
    if C_IsEquippableItem(link) then
      local item = it:GetItem(link)
      if item and SlotMatches(slotID, item) then callbackFn(info, item) end
    end
  end)
end

--- @class ContainerItemDetails : ContainerItemInfo
--- @field equippedSlot number

--- @param slotID SlotID @The target slot ID
--- @param callback fun(info:ContainerItemDetails, item:ItemInfoDetails)
function o:ForEachEquippedItem(slotID, callback)
  local it = itemUtil()
  for eqSlotID = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
    if eqSlotID ~= slotID then
      local link = GetInventoryItemLink('player', eqSlotID)
      if link then
        local item = it:GetItem(link)
        if item and SlotMatches(slotID, item) then
          --- @type ContainerItemDetails
          local info = {
            hyperlink = link,
            itemID = item.id,
            iconFileID = GetInventoryItemTexture('player', eqSlotID),
            equippedSlot = eqSlotID,
          }
          callback(info, item)
        end
      end
    end
  end
end

--- @param slotID SlotID
--- @return ItemInfoDetails[] Available @items that matches the slot
function o:GetAvailableSlotItems(slotID)
  local items = {}
  self:ForEachSlotItemCandidate(slotID, function(info, item) table.insert(items, item) end)
  return items
end

--- @param callback fun(info:ContainerItemDetails) : void
function o:ForEachBagItem(callback)
  for bag = 0, NUM_BAG_SLOTS do
    local numSlots = C_GetContainerNumSlots(bag)
    for slot = 1, numSlots do
      --- @type ContainerItemDetails
      local info = C_GetContainerItemInfo(bag, slot)
      if info and info.hyperlink then
        info.bagID = bag
        info.slotIndex = slot
        -- info.equippedSlot will be nil since it's in the bag
        callback(info)
      end
    end
  end
end
