--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Gears_Namespace
local ns = select(2, ...)
local L = ns:GetLocale()

local overlayTex = [[interface\addons\gears\assets\ignored-state-v1]]
local includeTex = [[interface\addons\gears\assets\include-v1.tga]]
local ignoreTex = [[interface\addons\gears\assets\ignore-v1.tga]]

--[[-------------------------------------------------------------------
Blizzard Vars
---------------------------------------------------------------------]]
local C_IsSlotIgnoredForSave = C_EquipmentSet and C_EquipmentSet.IsSlotIgnoredForSave
local C_IgnoreSlotForSave = C_EquipmentSet and C_EquipmentSet.IgnoreSlotForSave
local C_UnignoreSlotForSave = C_EquipmentSet and C_EquipmentSet.UnignoreSlotForSave
local C_GetIgnoredSlots = C_EquipmentSet and C_EquipmentSet.GetIgnoredSlots

--[[-----------------------------------------------------------------------------
Module::EquipmentSlotActionButtonMixin
-------------------------------------------------------------------------------]]

--- @see NamespaceObjects
local libName = 'IgnoreSlotActionButtonMixin'

--- @class IgnoreSlotActionButtonMixin : Button
--- @field TemplateName string
--- @field widget IgnoreSlotActionButtonWidget
--- @field Icon Texture
--- @field GetParent fun(self:IgnoreSlotActionButtonMixin) : FlyoutFrame
local S = {}; Gears_IgnoreSlotActionButtonMixin = S
--- @see EquipmentSlotFlyout.xml/Button[@name='Gears_IgnoreSlotActionButtonTemplate']
S.TemplateName = 'Gears_IgnoreSlotActionButtonTemplate'

--
--- @class IgnoreSlotActionButton : IgnoreSlotActionButtonMixin
--

local p, t = ns:log(libName)

--[[-------------------------------------------------------------------
Mixin: IgnoreSlotActionButtonWidgetMixin
---------------------------------------------------------------------]]

--- @class IgnoreSlotActionButtonWidgetMixin
--- @field frame IgnoreSlotActionButton
--- @field slotFlyout EquipmentSlotFlyout
local IgnoreSlotActionButtonWidgetMixin = {}

--
--- @class IgnoreSlotActionButtonWidget : IgnoreSlotActionButtonWidgetMixin
--

--[[-------------------------------------------------------------------
Methods: IgnoreSlotActionButtonWidgetMixin
---------------------------------------------------------------------]]
local function IgnoreSlotActionButtonWidgetMixin_Methods()
  local w = IgnoreSlotActionButtonWidgetMixin

  --- @param frame IgnoreSlotActionButton
  --- @param slotFlyout EquipmentSlotFlyout
  function w:Init(frame, slotFlyout)
    self.frame = frame
    self.slotFlyout = slotFlyout
    self:SetupTooltip()
  end

  --- @return SlotID
  function w:SlotID() return self.slotFlyout:GetID() end

  --- @return BlizzCharacterSlotItemButton
  function w:Slot() return self.slotFlyout:Slot() end

  --- Hierarchy: IgnoreSlotActionButton/Flyout (Frame)/EquipmentSlotFlyout (Button)
  --- @see EquipmentSlotFlyoutMixin#CreateActionButtons
  --- @return EquipmentSlotFlyout
  function w:SlotFlyout() return self.slotFlyout end

  --- @return EquipmentSlotFlyoutWidget
  function w:SlotFlyoutW() return self.slotFlyout.widget end

  --- @param ignored boolean
  function w:UpdateActionTexture(ignored)
    local tex = ignored and includeTex or ignoreTex
    self.frame.Icon:SetTexture(tex)
    self:UpdateCharItemSlotIgnoredOverlay(ignored)
  end

  --- @param ignored boolean
  function w:SyncIgnoredState(ignored)
    local fnc = ignored and C_IgnoreSlotForSave or C_UnignoreSlotForSave
    fnc(self:SlotID())
    self:UpdateActionTexture(ignored)
  end

  --- @param ignored boolean
  function w:UpdateCharItemSlotIgnoredOverlay(ignored)
    local fn = ignored and 'Show' or 'Hide'
    local overlay = self:GetIgnoreOverlay()
    overlay[fn](overlay)
  end

  --- @return boolean
  function w:IsIgnored() return self:SlotFlyoutW():IsIgnored() end

  --- ignored but not yet saved
  --- @return boolean
  function w:IsSlotIgnoredForSave() return C_IsSlotIgnoredForSave(self:SlotID()) end

  function w:UnignoreSlotForSave() C_UnignoreSlotForSave(self:SlotID()) end

  function w:IgnoreSlotForSave() C_IgnoreSlotForSave(self:SlotID()) end

  --- @return Texture?
  function w:GetIgnoreOverlay() return self:Slot().ignoreSlotOverlay end

  function w:SetupTooltip()
    local c_white = ns:ColorFn('afafaf')

    self.frame:SetScript('OnEnter', function(btn)
      GameTooltip:SetOwner(btn, 'ANCHOR_RIGHT')
      local ignored = self:IsSlotIgnoredForSave()
      local localeText = ignored and 'Include Slot' or 'Ignore Slot'
      local allLocaleText = ignored and 'Include All Slots' or 'Ignore All Slots'
      GameTooltip:SetText(L[localeText])
      GameTooltip:AddLine(c_white(L[localeText .. '::DESC']))
      GameTooltip:AddLine(' ')
      GameTooltip:AddLine(c_white(L['Shift-Click'] .. ': ' .. L[allLocaleText]))
      GameTooltip:Show()
    end)
    self.frame:SetScript('OnLeave', function() GameTooltip:Hide() end)
  end
end; IgnoreSlotActionButtonWidgetMixin_Methods()

--[[-----------------------------------------------------------------------------
Module::EquipmentSlotActionButtonMixin (Methods)
-------------------------------------------------------------------------------]]
local o = Gears_IgnoreSlotActionButtonMixin

function o:OnLoad()
  --- @type EquipmentSlotFlyout
  local slotFlyoutBtn = self:GetParent():GetParent()
  --- @type BlizzCharacterSlotItemButton
  local charItemSlot = slotFlyoutBtn:Slot()

  self:SetParentKey('IgnoreSlotActionButton')
  self.Icon:SetTexture(ignoreTex)

  --- @type Texture
  local overlay = charItemSlot:CreateTexture(nil, 'OVERLAY', nil, 7)
  overlay:SetTexture(overlayTex)

  local icon = charItemSlot.icon or charItemSlot.IconTexture
  overlay:SetScale(0.5)
  overlay:SetPoint('CENTER', icon, 'CENTER', 0, -3)

  overlay:SetAlpha(0.75)
  overlay:Hide()
  charItemSlot.ignoreSlotOverlay = overlay

  self.widget = CreateAndInitFromMixin(IgnoreSlotActionButtonWidgetMixin, self, slotFlyoutBtn)
end

function o:OnClick()
  if InCombatLockdown() then return end

  ns:PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
  if not ns.gears:HasSelection() then return end

  if IsShiftKeyDown() then
    local esfm = ns:esfm()
    local ignoreAll = not self.widget:IsSlotIgnoredForSave()
    if ignoreAll then
      esfm:IgnoreAllSlots()
    else
      esfm:IncludeAllSlots()
    end
    self.widget:SlotFlyoutW():ClosePopup()
    return
  end

  local ignored = self:ToggleState()
  self.widget:UpdateActionTexture(ignored)
  ns.gears:GetSaveButton():SetEnabled(true)

  local trace = false
  if trace then
    Gears_MainFrame:WithSelectedEquipmentSet(function(sel)
      local ignoredSlots = C_GetIgnoredSlots(sel.info.id)
      for slotID, ignoredSlot in pairs(ignoredSlots) do
        if C_IsSlotIgnoredForSave(slotID) then
          t('OnClick::IgnoredForSave', sel:__GetDebugName(), 'slotID=', slotID)
        end
      end
    end)
  end

  self.widget:SlotFlyoutW():ClosePopup()
end

--- @return boolean The new ignored-for-save state
function o:ToggleState()
  local wx = self.widget

  if wx:IsSlotIgnoredForSave() then
    wx:UnignoreSlotForSave()
  else
    wx:IgnoreSlotForSave()
  end

  return wx:IsSlotIgnoredForSave()
end

--- Hierarchy: IgnoreSlotActionButton/Flyout (Frame)/EquipmentSlotFlyout (Button)
--- @see EquipmentSlotFlyoutMixin.CreateActionButtons()
--- @return EquipmentSlotFlyout
function o:SlotFlyout() return self:GetParent():GetParent() end
