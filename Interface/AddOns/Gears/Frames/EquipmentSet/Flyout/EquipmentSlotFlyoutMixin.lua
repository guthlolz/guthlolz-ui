--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Gears_Namespace
local ns = select(2, ...)
local iu = ns.O.ItemUtil
local L = ns:GetLocale()

--[[-------------------------------------------------------------------
Backdrop
@see Modules/Flyout/EquipmentSlotFlyout.xml#Flyout
---------------------------------------------------------------------]]
GEARS_BACKDROP_TOAST_12_12 = {
  bgFile = 'Interface\\Buttons\\WHITE8X8',
  edgeFile = 'Interface\\FriendsFrame\\UI-Toast-Border',
  tile = true,
  tileEdge = true,
  tileSize = 12,
  edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

--[[-------------------------------------------------------------------
Blizzard Vars
---------------------------------------------------------------------]]
local C_IsSlotIgnoredForSave = C_EquipmentSet and C_EquipmentSet.IsSlotIgnoredForSave
local C_GetIgnoredSlots = C_EquipmentSet and C_EquipmentSet.GetIgnoredSlots
local C_PickupContainerItem = C_Container and C_Container.PickupContainerItem
local EquipCursorItem, GameTooltip_ShowCompareItem = EquipCursorItem, GameTooltip_ShowCompareItem
local MAINHANDSLOT, SECONDARYHANDSLOT, RANGEDSLOT = MAINHANDSLOT, SECONDARYHANDSLOT, RANGEDSLOT

local EQUIPPED_SLOT_LABEL = {
  [INVSLOT_MAINHAND] = MAINHANDSLOT,
  [INVSLOT_OFFHAND] = SECONDARYHANDSLOT,
}

-- blizz locales
local CURRENTLY_EQUIPPED = CURRENTLY_EQUIPPED or L['Currently Equipped']

--[[-------------------------------------------------------------------
Types
---------------------------------------------------------------------]]

--- @class FlyoutFrame : FlyoutFrameMixin @Flyout Container
--- @field PlaceInBagsButton PlaceInBagsSlotActionButton
--- @field IgnoreSlotButton IgnoreSlotActionButton
--- @field anim AnimationGroup
--- @field buttons Button[]
--- @field GetParent fun(self:FlyoutFrame) : EquipmentSlotFlyout

--[[-----------------------------------------------------------------------------
Module::EquipmentSlotFlyoutMixin
-------------------------------------------------------------------------------]]

local libName = 'EquipmentSlotFlyoutMixin'

--- @class EquipmentSlotFlyoutMixin : Button, AceEvent-3.0
--- @field TemplateName string
--- @field GetID fun(self:EquipmentSlotFlyoutMixin) : number @The equipment slot identifier
--- @field widget EquipmentSlotFlyoutWidget
--- @field Flyout FlyoutFrame @Flyout Container
--- @field Arrow Texture
--- @field GetParent fun(self:EquipmentSlotFlyoutMixin) : BlizzCharacterSlotItemButton
--- @see EquipmentSlotFlyoutManager.CreateSlotFlyouts()
Gears_EquipmentSlotFlyoutMixin = ns:NewAceEvent()

--
--- @class EquipmentSlotFlyout : EquipmentSlotFlyoutMixin
--

local p, t = ns:log(libName)

--[[-------------------------------------------------------------------
Support Functions
---------------------------------------------------------------------]]
local function inventorUtil() return ns.O.InventoryUtil end

--[[-----------------------------------------------------------------------------
Module::EquipmentSlotFlyoutMixin (Methods)
-------------------------------------------------------------------------------]]
local o = Gears_EquipmentSlotFlyoutMixin

--- @see EquipmentSlotFlyout.xml/GearsEquipmentSlotFlyoutTemplate
o.TemplateName = 'GearsEquipmentSlotFlyoutTemplate'

--[[-------------------------------------------------------------------
Mixin: EquipmentSlotFlyoutWidgetMixin
---------------------------------------------------------------------]]

--
--- @class EquipmentSlotFlyoutWidget : EquipmentSlotFlyoutWidgetMixin
--

--- @class EquipmentSlotFlyoutWidgetMixin
--- @field __interactionMode boolean Internal use for immediate interaction on flyouts
local w = {}; EquipmentSlotFlyoutWidgetMixin = w

--[[-----------------------------------------------------------------------------
Methods: EquipmentSlotFlyoutWidgetMixin
-------------------------------------------------------------------------------]]
local function EquipmentSlotFlyoutWidgetMixin_Methods()
  --- @param slotFlyout EquipmentSlotFlyout
  --- @param slotInfo InventorySlotInfo
  --- @param slotButton BlizzCharacterSlotItemButton
  function w:Init(slotFlyout, slotInfo, slotButton)
    self.frame = slotFlyout
    self.flyoutFrame = slotFlyout.Flyout
    self.info = slotInfo
    self.charSlotButton = slotButton
    self.expanded = false
    self.__interactionMode = nil
  end

  --- @return SlotID
  function w:SlotID() return self.frame:SlotID() end
  --- @return BlizzCharacterSlotItemButton
  function w:Slot() return self.charSlotButton end

  --- @return boolean
  function w:IsSlotShown() return self:Slot():IsShown() end
  --- @return boolean
  function w:IsGearsShown() return ns.gears:IsShown() end
  --- @param mode boolean
  function w:SetInteractionMode(mode) self.__interactionMode = mode end
  function w:IsInteractionMode() return self.__interactionMode == true end
  function w:ClearInteractionMode() self:SetInteractionMode(nil) end

  --- @return boolean
  function w:ShouldShowSlotGroup()
    return self:IsSlotShown() and ns.gears:HasSelection() and ns.gears:IsShown()
  end
  --- @param ignored boolean
  function w:SyncIgnoredState(ignored) self:isb().widget:SyncIgnoredState(ignored) end
  --- @return boolean
  function w:IsIgnored()
    local ignored = false
    ns.gears:WithSelectedEquipmentSet(function(sel)
      local slotID = self:SlotID()
      local ignoredSlots = C_GetIgnoredSlots(sel:GetIdentity())
      ignored = ignoredSlots and ignoredSlots[slotID]
    end)
    return ignored
  end

  --- @return boolean
  function w:IsIgnoredForSave() return C_IsSlotIgnoredForSave(self:SlotID()) end
  function w:GetIgnoreSlotButton() return self.flyoutFrame.IgnoreSlotButton end
  function w:isb() return self:GetIgnoreSlotButton() end
  --- @see EquipmentSlotFlyoutMixin.CreateSlotItems()
  --- @return boolean
  function w:CreateSlotItems() return self.frame:CreateSlotItems() end

  -- Shows and opens this slot's flyout for direct interaction
  function w:OpenPopup()
    self.expanded = true
    self:OpenPopupSound()
    self:ShowSlotGroup()
    self:ShowFlyoutActions()
  end

  --- Closes/Collapses the flyout button
  --- (not the top-most(parent) flyout button)
  ---@param resetSlot boolean Resets the slot group; default is false
  function w:ClosePopup(resetSlot, closeSound)
    self.expanded = false
    self:ClosePopupSound(closeSound)
    self:HideFlyoutActions()
    self:ShowExpandArrow()
    if not self:IsGearsShown() then self:HidePopup() end
    if resetSlot then self:ResetSlot() end
    self:ClearInteractionMode()
  end
  function w:ShowFlyoutActions()
    local hasActions = self:CreateSlotItems()
    self.frame.Flyout:PlayAnimation(hasActions)
    if not hasActions and not self:IsGearsShown() then self.frame:Hide() end
    self:ShowCollapseArrow()
    self:NotifyOpened()
  end
  function w:HidePopup()
    self.flyoutFrame:StopAnimation()
    self.frame:Hide()
  end
  --- For hand slots
  --- @return boolean
  function w:IsDownExpand()
    local slotID = self:SlotID()
    return slotID == INVSLOT_MAINHAND or slotID == INVSLOT_OFFHAND or slotID == INVSLOT_RANGED
  end
  function w:HideFlyoutActions() return self.frame.Flyout:Hide() end
  function w:NotifyOpened() self.frame:SendMessage(ns:msg('SlotOpened'), self:SlotID()) end
  --- Some equipment slots (e.g. CharacterAmmoSlot) are not
  --- applicable to the player's class and should be hidden.
  function w:ShowSlotGroup() self.frame:Show() end
  --- @return boolean
  function w:IsExpanded() return self.expanded == true end
  --- @return boolean
  function w:IsCollapsed() return not self:IsExpanded() end

  --- Example return value: 'LEFT', relativeTo, 'RIGHT', ofsx, ofsy
  --- @return AnchorPoint, Frame|Name, AnchorPoint, number, number
  function w:GetSlotAnchor()
    local ofsx, ofsy = -7, 0
    local relativeTo = self:Slot()
    if self:IsDownExpand() then return 'TOP', relativeTo, 'BOTTOM', 0, 10 end
    return 'LEFT', relativeTo, 'RIGHT', ofsx, ofsy
  end

  --- ###############################################
  --- Private Methods
  --- ###############################################

  -- hide ignore overlay if present (reset visual state)
  function w:ResetSlot()
    local slot = self:Slot()
    if slot and slot.ignoreSlotOverlay then slot.ignoreSlotOverlay:Hide() end
  end
  function w:ShowExpandArrow() -- ▶
    if self:IsDownExpand() then
      self.frame.Arrow:SetRotation(math.rad(180))
      return
    end
    self.frame.Arrow:SetRotation(math.rad(-90))
  end
  function w:ShowCollapseArrow() -- ◀
    if self:IsDownExpand() then
      self.frame.Arrow:SetRotation(math.rad(0))
      return
    end
    self.frame.Arrow:SetRotation(math.rad(90))
  end

  function w:OpenPopupSound()
    if self:IsInteractionMode() then return end
    ns:PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
  end
  --- We want to play sound only when clicking
  --- an opened slot and not in interactive mode.
  --- @param alwaysPlay boolean
  function w:ClosePopupSound(alwaysPlay)
    if alwaysPlay == false or self:IsInteractionMode() then return end
    ns:PlaySound(SOUNDKIT.IG_ABILITY_ICON_DROP)
  end

  --- ############################################
  --- Debug Methods Below
  --- ############################################
  function w:n() return self:Slot():GetName() end
  function w:ndbg() return ('%s::%s'):format(self.info.name, self.info.id, self:n()) end
end; EquipmentSlotFlyoutWidgetMixin_Methods()

--[[-----------------------------------------------------------------------------
FlyoutFrameMixin
-------------------------------------------------------------------------------]]

--- @class FlyoutFrameMixin : Frame, BackdropTemplate
local FlyoutFrameMixin = {}

local function FlyoutFrameMixin_Methods()
  local fo = FlyoutFrameMixin

  function fo:OnLoad()
    self:SetBackdropColor(0.34, 0.21, 0.13, 0.96)
    self:SetBackdropBorderColor(0.55, 0.65, 0.25, 1)
  end

  function fo:OnPlay()
    self:SetAlpha(0)
    self:Show()
  end

  function fo:OnFinished() self:SetAlpha(1) end

  function fo:AnchorForDownExpansion()
    self:ClearAllPoints()
    self:SetPoint('TOPLEFT', self:GetParent(), 'BOTTOMLEFT', -14, 8)
  end

  --- @param hasActions boolean|nil
  function fo:PlayAnimation(hasActions)
    self:StopAnimation()
    local flyout = self:GetParent().widget

    if hasActions and flyout:IsInteractionMode() then
      self:SetAlpha(1.0)
      self:Show()
      return
    end
    if not hasActions then return end

    self:Show()
    self.anim:Play()
  end

  function fo:StopAnimation()
    if self.anim:IsPlaying() then self.anim:Stop() end
    self:SetAlpha(1.0)
  end

  --- @return boolean
  function fo:HasVisibleActions()
    for _, btn in ipairs({ self.IgnoreSlotButton, self.PlaceInBagsButton }) do
      if btn:IsShown() then return true end
    end
    return false
  end
end; FlyoutFrameMixin_Methods()

--[[-------------------------------------------------------------------
EquipmentSlotFlyout: Methods
---------------------------------------------------------------------]]
--- @see EquipmentSlotFlyout.xml/GearsEquipmentSlotFlyoutTemplate/Scripts/OnLoad
function o:OnLoad()
  Mixin(self.Flyout, FlyoutFrameMixin)
  self.Flyout:OnLoad()

  self.Arrow:SetTexture(310765)
  self.Arrow:SetTexCoord(0.02, 0.98, 0.02, 0.48)
end

--- @return SlotID
function o:SlotID() return self:GetID() end
--- @return BlizzCharacterSlotItemButton
function o:Slot() return self.widget:Slot() end

--- @param slotInfo InventorySlotInfo
--- @param characterSlotButton BlizzCharacterSlotItemButton
--- @return EquipmentSlotFlyout
function o:Create(slotInfo, characterSlotButton)
  --- @type EquipmentSlotFlyout
  local slotFlyout = CreateFrame('Button', nil, characterSlotButton, self.TemplateName, slotInfo.id)
  local name = characterSlotButton:GetName() .. 'Flyout'
  slotFlyout:SetParentKey(name)
  slotFlyout.widget = CreateAndInitFromMixin(
    EquipmentSlotFlyoutWidgetMixin,
    slotFlyout,
    slotInfo,
    characterSlotButton
  )
  do
    --- @class Gears_BlizzCharacterSlotItemButton
    local gears = {}
    characterSlotButton.gears = gears
    function gears:GetFlyout() return characterSlotButton[name] end
  end

  slotFlyout:ApplyInitialState()
  slotFlyout:CreateActionButtons()
  slotFlyout:SetHeight(24)
  slotFlyout:ClearAllPoints()
  slotFlyout:SetPoint(slotFlyout.widget:GetSlotAnchor())

  slotFlyout:RegisterMessage(ns:msg('SlotOpened'), 'OnSlotOpened')
  slotFlyout:RegisterMessage(ns:msg('ShowPaperDollFrame'), 'OnShowPaperDollFrame')
  slotFlyout:RegisterMessage(ns:msg('SlotEnter'), 'OnSlotEnter')
  slotFlyout:RegisterMessage(ns:msg('EquipmentSetSelected'), 'OnEquipmentSetSelected')

  return slotFlyout
end

function o:ApplyInitialState()
  if not self.widget:IsDownExpand() then return end
  self.Flyout:AnchorForDownExpansion()

  self:Hide()
  self.widget:ShowExpandArrow()
  self.widget:HideFlyoutActions()
end

function o:CreateActionButtons()
  local flyout = self.widget.flyoutFrame
  flyout.buttons = {}

  --- @type Button @Include Button
  local placeInBagsBtn =
    CreateFrame('Button', nil, flyout, Gears_PlaceInBagsSlotActionButtonMixin.TemplateName)
  placeInBagsBtn:ClearAllPoints()
  placeInBagsBtn:SetPoint('LEFT', flyout, 'LEFT', 8, 0)
  flyout.PlaceInBagsButton = placeInBagsBtn
  table.insert(flyout.buttons, placeInBagsBtn)

  --- @type IgnoreSlotActionButton
  local ignoreSlotBtn =
    CreateFrame('Button', nil, flyout, Gears_IgnoreSlotActionButtonMixin.TemplateName)
  ignoreSlotBtn:ClearAllPoints()
  ignoreSlotBtn:SetPoint('LEFT', placeInBagsBtn, 'RIGHT', 1, 0)
  flyout.IgnoreSlotButton = ignoreSlotBtn
  table.insert(flyout.buttons, ignoreSlotBtn)

  local widthPadding = 16
  flyout:SetWidth(placeInBagsBtn:GetWidth() + ignoreSlotBtn:GetWidth() + widthPadding)
  flyout:SetHeight(flyout:GetHeight() + 4)
end

--- Creates buttons for each candidate items
--- using template GearsEquipmentSlotActionButtonTemplate
--- @return boolean true if there are slot items
function o:CreateSlotItems()
  local flyout = self.Flyout

  local slotID = self:SlotID()
  local hasItem = GetInventoryItemID('player', slotID) ~= nil

  -- 1. Clear existing dynamic buttons (keep first 2: Place + Ignore)
  for i = #flyout.buttons, 3, -1 do
    local btn = flyout.buttons[i]
    btn:Hide()
    btn:ClearAllPoints()
    flyout.buttons[i] = nil
  end

  local spacing = 2
  local totalWidth = 0

  if hasItem then
    -- include base buttons width
    flyout.PlaceInBagsButton:Show()
    totalWidth = totalWidth + flyout.PlaceInBagsButton:GetWidth()
  else
    flyout.PlaceInBagsButton:Hide()
  end

  if self.widget:IsGearsShown() and ns.gears:HasSelection() then
    flyout.IgnoreSlotButton:Show()
    totalWidth = totalWidth + flyout.IgnoreSlotButton:GetWidth()
  else
    flyout.IgnoreSlotButton:Hide()
  end

  local prev
  if flyout.IgnoreSlotButton:IsShown() then
    prev = flyout.IgnoreSlotButton
  elseif flyout.PlaceInBagsButton:IsShown() then
    prev = flyout.PlaceInBagsButton
  else
    prev = self.widget.flyoutFrame
  end

  flyout.IgnoreSlotButton:ClearAllPoints()

  if flyout.PlaceInBagsButton:IsShown() then
    flyout.IgnoreSlotButton:SetPoint('LEFT', flyout.PlaceInBagsButton, 'RIGHT', 1, 0)
  else
    flyout.IgnoreSlotButton:SetPoint('LEFT', flyout, 'LEFT', 8, 0)
  end

  local hasActions = flyout:HasVisibleActions()

  -- 2. Create item buttons
  inventorUtil():ForEachSlotItemCandidate(slotID, function(info, item)
    hasActions = true
    local infoRef = info
    --- @type Button
    local btn = CreateFrame(
      'Button',
      nil,
      flyout,
      'GearsEquipmentSlotActionButtonTemplate' --[[@as Template]]
    )
    btn:SetParentKey(('ItemButton%d'):format(#flyout.buttons + 1))
    if info.iconFileID then btn.Icon:SetTexture(info.iconFileID) end

    btn:ClearAllPoints()
    if prev == self.widget.flyoutFrame then
      btn:SetPoint('LEFT', prev, 'LEFT', 9, 0) -- first / only button
    else
      btn:SetPoint('LEFT', prev, 'RIGHT', spacing, 0) -- chained
    end
    table.insert(flyout.buttons, btn)

    prev = btn
    totalWidth = totalWidth + btn:GetWidth() + spacing

    local slotFlyout = self
    btn:SetScript('OnClick', function(self)
      if InCombatLockdown() then return end
      local pickedUp = false
      if infoRef.bagID and infoRef.slotIndex then
        C_PickupContainerItem(infoRef.bagID, infoRef.slotIndex)
        pickedUp = true
      elseif infoRef.equippedSlot then
        PickupInventoryItem(infoRef.equippedSlot)
        pickedUp = true
      end
      if not pickedUp then return end
      EquipCursorItem(slotFlyout:SlotID())
      slotFlyout.widget:ClosePopup()
    end)

    local c_white = ns:ColorFn('afafaf')

    btn:SetScript('OnEnter', function(self)
      GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
      GameTooltip:SetHyperlink(infoRef.hyperlink)
      local slotLabel = EQUIPPED_SLOT_LABEL[infoRef.equippedSlot]
      if slotLabel then GameTooltip:AddLine(c_white(CURRENTLY_EQUIPPED .. ' ') .. slotLabel) end
      GameTooltip:Show()
      GameTooltip_ShowCompareItem(GameTooltip)
    end)

    btn:SetScript('OnLeave', function() GameTooltip:Hide() end)
  end)

  -- 3. Resize flyout (horizontal growth)
  local padding = 16
  flyout:SetWidth(totalWidth + padding)

  return hasActions
end

--[[-------------------------------------------------------------------
Script Methods
@see EquipmentSlotFlyout.xml/GearsEquipmentSlotFlyoutTemplate
---------------------------------------------------------------------]]

--- @see EquipmentSlotFlyout.xml/GearsEquipmentSlotFlyoutTemplate/Scripts/OnEnter
function o:OnClick()
  if self.widget.expanded then return self.widget:ClosePopup(false, true) end
  self.widget:OpenPopup()
end

--- @see EquipmentSlotFlyout.xml/GearsEquipmentSlotFlyoutTemplate/Scripts/OnEnter
function o:OnEnter()
  self.Arrow:SetVertexColor(0.4, 0.95, 0.4, 1)
  self.Arrow:SetBlendMode('BLEND')
end

--- @see EquipmentSlotFlyout.xml/GearsEquipmentSlotFlyoutTemplate/Scripts/OnLeave
function o:OnLeave()
  self.Arrow:SetVertexColor(1, 1, 1, 1)
  self.Arrow:SetBlendMode('BLEND')
end

--[[-------------------------------------------------------------------
Event/Message Handlers
---------------------------------------------------------------------]]
function o:OnSlotOpened(evt, slotID)
  if self:SlotID() == slotID then return end
  -- close the other expanded flyouts
  self.widget:ClosePopup(false, false)
end

function o:OnSlotEnter(evt, slotID)
  if self:SlotID() == slotID then return end
  self.widget:ClosePopup(false, false)
end

function o:OnEquipmentSetSelected(evt, slotID) self.widget:ClosePopup(false, false) end

function o:OnShowPaperDollFrame()
  if not self.widget:ShouldShowSlotGroup() then
    self.widget:ClosePopup()
    return
  end
  self.widget:ShowSlotGroup()
end
