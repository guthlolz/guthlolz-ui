--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Gears_Namespace
local ns = select(2, ...)

--[[-------------------------------------------------------------------
Blizzard Vars
---------------------------------------------------------------------]]
local C_GetItemInfoInstant = C_Item and C_Item.GetItemInfoInstant
local C_GetItemInfo = C_Item and C_Item.GetItemInfo

--[[-----------------------------------------------------------------------------
Module::ItemUtil
-------------------------------------------------------------------------------]]
--- @see NamespaceObjects
local libName = 'ItemUtil'

--- @class ItemUtil
local o = {}; ns.O.ItemUtil = o
local p, t = ns:log(libName)

--[[-----------------------------------------------------------------------------
Module::ItemUtil (Methods)
-------------------------------------------------------------------------------]]
--- @param itemIdentifier ItemIdentifier
--- @return ItemInfoDetails
function o:GetItem(itemIdentifier)
  assert(
    type(itemIdentifier) == 'string' or type(itemIdentifier) == 'number',
    'GetItem(itemIdentifier):: {itemIdentifier} should be a name, id or link'
  )

  local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expacID, setID, isCraftingReagent =
    C_GetItemInfo(itemIdentifier)

  local itemID = C_GetItemInfoInstant(itemIdentifier)

  --- @type ItemInfoDetails
  local itemInfo = {
    id = itemID,
    name = itemName,
    link = itemLink,
    icon = itemTexture,
    quality = itemQuality,
    level = itemLevel,
    minLevel = itemMinLevel,
    type = itemType,
    subType = itemSubType,
    stackCount = itemStackCount,
    equipLoc = itemEquipLoc,
    classID = classID,
    subclassID = subclassID,
    bindType = bindType,
    isCraftingReagent = isCraftingReagent,
  }
  return itemInfo
end

--- @param itemLink ItemLink
--- @return ItemID
function o:GetItemIDByLink(itemLink)
  local itemID = C_GetItemInfoInstant(itemLink)
  return itemID
end

--- @param slotID SlotID
--- @return ItemID?, ItemLink?
function o:GetItemBySlotID(slotID)
  local itemLink, itemID
  itemLink = GetInventoryItemLink('player', slotID)
  if itemLink then itemID = self:GetItemIDByLink(itemLink) end
  return itemID, itemLink
end
