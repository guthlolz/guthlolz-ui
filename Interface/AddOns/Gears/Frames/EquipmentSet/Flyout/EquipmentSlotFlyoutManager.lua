--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Gears_Namespace
local ns = select(2, ...)
local cfu = ns.O.CharacterFrameUtil
local Tbl_IsEmpty = ns.O.Table.IsEmpty

--[[-------------------------------------------------------------------
Blizzard Vars
---------------------------------------------------------------------]]
local C_GetIgnoredSlots = C_EquipmentSet and C_EquipmentSet.GetIgnoredSlots
local C_ClearIgnoredSlotsForSave = C_EquipmentSet and C_EquipmentSet.ClearIgnoredSlotsForSave

--[[-----------------------------------------------------------------------------
Module::EquipmentSlotFlyoutManager
-------------------------------------------------------------------------------]]
--- @see NamespaceObjects
local libName = 'EquipmentSlotFlyoutManager'

--- @class EquipmentSlotFlyoutManager : AceEvent-3.0, AceHook-3.0
local o = ns:AceEmbed({}, 'AceEvent-3.0', 'AceHook-3.0')
ns:register(libName, o)

local p, t = ns:log(libName)

--- @type table<SlotID, EquipmentSlotFlyout>
local flyoutsMap = {}

--[[-------------------------------------------------------------------
Support Functions
---------------------------------------------------------------------]]
--- @param flyout EquipmentSlotFlyout
--- @param slotID SlotID?
local function OnSlotEnter_ShowGameTooltip(flyout, slotID)
  local ofsx, ofsy = 0, 5
  slotID = slotID or flyout:SlotID()

  local owner = flyout
  local relAnchor = 'TOPRIGHT'
  if flyout.widget:IsExpanded() then
    ofsx, ofsy = 0, 2
    owner = flyout.Flyout
    relAnchor = 'BOTTOMRIGHT'
  end

  GameTooltip:SetOwner(owner, 'ANCHOR_NONE')
  GameTooltip:SetInventoryItem('player', slotID)
  GameTooltip:ClearAllPoints()
  GameTooltip:SetPoint('BOTTOMLEFT', owner, relAnchor, ofsx, ofsy)
  if ShoppingTooltip1 then ShoppingTooltip1:Hide() end
  if ShoppingTooltip2 then ShoppingTooltip2:Hide() end
  GameTooltip:Show()
end

--[[-----------------------------------------------------------------------------
Module::EquipmentSlotFlyoutManager (Methods)
-------------------------------------------------------------------------------]]

--- @param msg string
--- @param equipSetInfo EquipmentSetInfo
function o:OnEquipmentSetSelected(msg, equipSetInfo)
  self:EnableEquipmentSlots(true)
  C_ClearIgnoredSlotsForSave()
  self:ForEachEquipSetSlots(
    equipSetInfo.id,
    function(flyout, ignored) flyout.widget:SyncIgnoredState(ignored) end
  )
end

function o:CreateSlotFlyouts()
  local esfm = Gears_EquipmentSlotFlyoutMixin
  cfu:ForEachEquipmentSlot(function(s, btn, po)
    local flyout = esfm:Create(s, btn)
    flyoutsMap[flyout:GetID()] = flyout
    if not ns:HasBlizzEquipmentManager() then
      self:HookScript(btn, 'OnLeave', 'OnSlotLeave')
      btn:SetScript('OnEnter', function(b) self:OnSlotEnter(b) end)
    else
      self:OnEnterDynamic(btn)
      self:OnLeaveDynamic(btn)
    end
  end)
end

--- @param slotBtn BlizzCharacterSlotItemButton
--- @param ignoreAltKey boolean|nil Must set to false to ignore alt key press
function o:OnSlotEnter(slotBtn, ignoreAltKey)
  local slotID = slotBtn:GetID()
  self.__hoverSlotID = slotID
  local flyout = flyoutsMap[slotID]
  if not flyout then return end
  if ignoreAltKey ~= false and not IsAltKeyDown() then
    return OnSlotEnter_ShowGameTooltip(flyout)
  end

  if InCombatLockdown() then return OnSlotEnter_ShowGameTooltip(flyout, slotID) end

  if flyout.widget:IsExpanded() then
    OnSlotEnter_ShowGameTooltip(flyout, slotID)
    return
  end
  flyout.widget:SetInteractionMode(true)
  flyout.widget:OpenPopup()
  OnSlotEnter_ShowGameTooltip(flyout, slotID)
end

--- @param slotBtn BlizzCharacterSlotItemButton
function o:OnSlotLeave(slotBtn)
  GameTooltip:Hide()

  local slotID = slotBtn:GetID()
  local flyout = flyoutsMap[slotID]
  if InCombatLockdown() or not (IsAltKeyDown() and flyout) then return end
end

--- If gears is open, then use Gears Slots
--- @param btn BlizzCharacterSlotItemButton
function o:OnEnterDynamic(btn)
  local origOnEnter = btn:GetScript('OnEnter')
  if not origOnEnter then return end
  btn:SetScript('OnEnter', function(b)
    if ns.gears:IsShown() then
      self:OnSlotEnter(b)
    elseif origOnEnter then
      origOnEnter(b)
    end
  end)
end

--- @param btn BlizzCharacterSlotItemButton
function o:OnLeaveDynamic(btn)
  local origOnLeave = btn:GetScript('OnLeave')
  if not origOnLeave then return end
  btn:SetScript('OnLeave', function(b)
    if ns.gears:IsShown() then
      self:OnSlotLeave(b)
    elseif origOnLeave then
      origOnLeave(b)
    end
  end)
end

-- ALT released → close flyouts
function o:OnModifierStateChanged(evt, key, down)
  if ns:HasBlizzEquipmentManager() and not ns.gears:IsShown() then return end
  if key ~= 'LALT' and key ~= 'RALT' then return end
  if down == 1 then
    local mf = GetMouseFoci()
    --- @type BlizzCharacterSlotItemButton
    local s
    if mf and mf[1] then s = mf[1] end
    if s and s.gears then self:OnSlotEnter(s, true) end
    return
  end

  if not ns.gears:IsPaperDollFrameVisible() then return end
  self:ForEachFlyouts(function(flyout)
    --if flyout.widget:IsExpanded() then
    flyout.widget:ClosePopup(false, false)
    GameTooltip:Hide()
    --end
  end)
end

--- @param enable boolean
function o:EnableEquipmentSlots(enable)
  if enable then return self:ShowFlyouts() end
  self:HideFlyouts()
end

function o:ShowFlyouts()
  self:ForEachFlyouts(function(flyout) flyout.widget:ShowSlotGroup() end)
end

function o:HideFlyouts()
  if ns.gears:HasSelection() and ns.gears:IsShown() then return end
  self:ForEachFlyouts(function(flyout) flyout.widget:ClosePopup(true) end)
end

--- This method does not care about equipment set IDs
--- @param callbackFn fun(flyout:EquipmentSlotFlyout, slotBtn:BlizzCharacterSlotItemButton, ignored:boolean) : void | "'function(slotFlyout, slotBtn, ignored) end'"
--- @param filterFn fun(flyout:EquipmentSlotFlyout) : boolean | "'function(flyout) return true end'"
function o:ForEachFlyouts(callbackFn, filterFn)
  if Tbl_IsEmpty(flyoutsMap) or not callbackFn then return end

  local filter = filterFn or ns.TRUE
  for _, flyout in pairs(flyoutsMap) do
    if filter(flyout) then callbackFn(flyout) end
  end
end

--- @param ignored boolean
function o:SetAllSlotsIgnored(ignored)
  if not ns.gears:HasSelection() then return end
  self:ForEachFlyouts(
    function(flyout) flyout.widget:GetIgnoreSlotButton().widget:SyncIgnoredState(ignored) end
  )
  ns.gears:GetSaveButton():SetEnabled(true)
end

function o:IgnoreAllSlots() self:SetAllSlotsIgnored(true) end

function o:IncludeAllSlots() self:SetAllSlotsIgnored(false) end

--- Slots by EquipmentSetID
--- @param equipSetID EquipSetID
--- @param callbackFn fun(slotFlyout:EquipmentSlotFlyout, slotBtn:BlizzCharacterSlotItemButton, ignored:boolean) : void | "'function(slotFlyout, slotBtn, ignored) end'"
function o:ForEachEquipSetSlots(equipSetID, callbackFn)
  if not callbackFn then return end

  local ignoredSlots = C_GetIgnoredSlots(equipSetID)

  for _, slotFlyout in pairs(flyoutsMap) do
    local slotID = slotFlyout:GetID()
    local ignored = ignoredSlots and ignoredSlots[slotID]
    callbackFn(slotFlyout, ignored)
  end
end

--- Slots by EquipmentSetID
--- @param equipSetID EquipSetID
--- @param callbackFn fun(slotFlyout:EquipmentSlotFlyout, slotBtn:BlizzCharacterSlotItemButton) : void | "'function(slotFlyout, slotBtn) end'"
function o:ForEachEquipSetIgnoredSlots(equipSetID, callbackFn)
  self:ForEachEquipSetSlots(equipSetID, function(slotFlyout, ignored)
    if ignored and slotFlyout then callbackFn(slotFlyout) end
  end)
end

--[[-------------------------------------------------------------------
Event Handlers
---------------------------------------------------------------------]]
function o:OnEnterCombat()
  local btn = Gears_ToggleButton
  if not ns.gears:IsPaperDollFrameVisible() then return end
  if not btn:IsChecked() then
    self:HideFlyouts()
    return
  end
  btn:Click()
end

--[[-------------------------------------------------------------------
Callbacks
---------------------------------------------------------------------]]
o:RegisterEvent('PLAYER_REGEN_DISABLED', 'OnEnterCombat')
o:RegisterEvent('MODIFIER_STATE_CHANGED', 'OnModifierStateChanged')
o:RegisterMessage(ns:msg('EquipmentSetSelected'), 'OnEquipmentSetSelected')
