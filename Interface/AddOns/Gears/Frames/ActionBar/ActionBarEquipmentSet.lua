--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Gears_Namespace
local ns = select(2, ...)
local L = ns:GetLocale()

--[[-------------------------------------------------------------------
Types
---------------------------------------------------------------------]]
--- @class Gears_ActionBarSetState
--- @field isEquipped boolean
--- @field numItems number
--- @field numEquipped number
--- @field numInInventory number @Set items sitting in the bags
--- @field numLost number        @Set items the player no longer has

--[[-------------------------------------------------------------------
Blizzard Vars
---------------------------------------------------------------------]]
local C_GetEquipmentSetID = C_EquipmentSet.GetEquipmentSetID
local C_GetEquipmentSetInfo = C_EquipmentSet.GetEquipmentSetInfo

--[[-----------------------------------------------------------------------------
Module::ActionBarEquipmentSet
-------------------------------------------------------------------------------]]
--- @see NamespaceObjects
local libName = 'ActionBarEquipmentSet'

--- Equipped-state outline and tooltip lines for equipment sets
--- placed on Blizzard's native action bars.
--- @class ActionBarEquipmentSet : AceEvent-3.0, AceBucket-3.0
local o = ns:AceEmbed({}, 'AceEvent-3.0', 'AceBucket-3.0')
ns:register(libName, o)

local p, t = ns:log(libName)

-- Kept off the buttons so secure frames stay untouched
--- @type table<Button, Texture>
local outlines = {}

local redFn = ns:ColorFn('FF0F0A')

--[[-------------------------------------------------------------------
Support Functions
---------------------------------------------------------------------]]
--- @return boolean
local function IsEnabled() return ns:g().actionBarEquippedSet == true end

--- @return Button[]
local function NativeButtons() return ActionBarButtonEventsFrame.frames end

--- @param action number?
--- @return Gears_ActionBarSetState? @nil unless the slot holds an equipment set
local function GetSetState(action)
  if not action then return nil end
  local actionType, setName = GetActionInfo(action)
  if actionType ~= 'equipmentset' then return nil end

  local id = C_GetEquipmentSetID(setName)
  if not id then return nil end

  local _, _, _, isEquipped, numItems, numEquipped, numInInventory, numLost =
    C_GetEquipmentSetInfo(id)
  return {
    isEquipped = isEquipped,
    numItems = numItems,
    numEquipped = numEquipped,
    numInInventory = numInInventory,
    numLost = numLost,
  }
end

--- Mirrors Blizzard's equipped-item border art, in Gears' color.
--- @param button Button
--- @return Texture? @nil if the button has no Blizzard border to mirror
local function CreateOutline(button)
  local border = button.Border
  if not border then return nil end

  local outline = button:CreateTexture(nil, 'OVERLAY', nil, 7)
  local atlas = border:GetAtlas()
  if atlas then
    outline:SetAtlas(atlas)
  else
    outline:SetTexture(border:GetTexture())
  end
  outline:SetBlendMode(border:GetBlendMode())
  outline:SetAllPoints(border)
  outline:SetVertexColor(ns.colorDef.primary:GetRGB())
  outlines[button] = outline
  return outline
end

--- @param button Button
local function UpdateOutline(button)
  local state = IsEnabled() and GetSetState(button.action)
  local shown = state and state.isEquipped or false
  local outline = outlines[button]
  if not outline and shown then outline = CreateOutline(button) end
  if outline then outline:SetShown(shown) end
end

--- @param state Gears_ActionBarSetState
local function AddPartialLines(state)
  local tip = GameTooltip
  local count = redFn(('%d/%d'):format(state.numEquipped, state.numItems))
  tip:AddLine(('%s: %s'):format(L['Equipped Items'], count))
  if state.numInInventory > 0 then
    tip:AddLine(('%s: %d'):format(L['In Bags'], state.numInInventory))
  end
  if state.numLost > 0 then
    tip:AddLine(('%s: %d'):format(L['Missing'], state.numLost), RED_FONT_COLOR:GetRGB())
  end
end

--- @param button Button
local function AddTooltipLines(button)
  if GameTooltip:GetOwner() ~= button then return end
  local state = IsEnabled() and GetSetState(button.action)
  if not state then return end

  if state.isEquipped then
    GameTooltip:AddLine(L['Currently Equipped'], GREEN_FONT_COLOR:GetRGB())
  else
    AddPartialLines(state)
  end
  GameTooltip:Show()
end

--[[-------------------------------------------------------------------
Module Methods
---------------------------------------------------------------------]]
function o:Refresh()
  for _, button in ipairs(NativeButtons()) do
    UpdateOutline(button)
  end
end

--- @private
function o:HookButtons()
  for _, button in ipairs(NativeButtons()) do
    hooksecurefunc(button, 'Update', UpdateOutline)
    hooksecurefunc(button, 'SetTooltip', AddTooltipLines)
  end
end

--[[-------------------------------------------------------------------
Event Handlers
---------------------------------------------------------------------]]
function o:OnInit()
  self:HookButtons()
  self:Refresh()

  -- Same refresh triggers as MainFrame:InitEquipmentSet()
  self:RegisterBucketEvent('PLAYER_EQUIPMENT_CHANGED', 0.01, 'Refresh')
  self:RegisterEvent('EQUIPMENT_SETS_CHANGED', 'Refresh')
  self:RegisterEvent('PORTRAITS_UPDATED', 'Refresh')
  self:RegisterBucketEvent('BAG_UPDATE_DELAYED', 0.2, 'Refresh')
end

--[[-------------------------------------------------------------------
Callbacks
---------------------------------------------------------------------]]
o:RegisterMessage(ns:msg('OnInit'), 'OnInit')
