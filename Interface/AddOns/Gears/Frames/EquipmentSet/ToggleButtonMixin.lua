--- @type Gears_Namespace
local ns = select(2, ...)
local L = ns:GetLocale()
local cfu = ns.O.CharacterFrameUtil
local mgr = ns.O.EquipmentSlotFlyoutManager

--[[-------------------------------------------------------------------
Alias
---------------------------------------------------------------------]]
--- @alias ToggleButton ToggleButtonMixin | CheckButtonObj| AceEvent-3.0

--[[-------------------------------------------------------------------
Local Vars
---------------------------------------------------------------------]]
local TOGGLE_BUTTON_ICON = [[Interface\AddOns\Gears\Assets\gears-button-2b]]
local TOOLTIP_DELAY = 0.01
local c_white = ns:ColorFn('afafaf')
local c_yellow = ns:ColorFn('FFE680')
local c_gold = ns:ColorFn('FFD100')
local GLOW_NORMAL = { 0.2, 1.0, 0.4, 1.0 }
local GLOW_STICKY = { 1.0, 0.82, 0.0, 1.0 }

--- The equipment manager tab on advanced versions of wow like MoP, Retail, etc.
--- @type Frame
local PaperDollSidebarTab3 = PaperDollSidebarTab3

local libName = 'ToggleButton'
local p, t = ns:log(libName)

--- todo next: move ecs methods on it's own lua file? publish events on open/close

--[[-------------------------------------------------------------------
ToggleButtonMixin
---------------------------------------------------------------------]]
--- @class ToggleButtonMixin : CheckButton
--- @field Icon Texture
--- @field owner PaperDollFrame
--- @field private __ecsFrame Frame The ECS_StatsFrame (Extended Character Stats addon)
--- @field private __ecsButton Button The ECS_ToggleButton (Extended Character Stats addon)
--- @field private __blizzEquipHooked boolean
--- @field private __ecsOnClickHooked boolean
--- @field private __ecsToggleButtonHooked boolean
--- @field private __sticky boolean @Session only; cleared by any close
Gears_ToggleButtonMixin = ns:NewAceEvent()

local o = Gears_ToggleButtonMixin

--- Handles Clicks on the Original Blizz Equipment Gear tab
--- @param self ToggleButton
local function ToggleButtonMixin_BlizzEquipmentGearHook(self)
  if not PaperDollSidebarTab3 or self.__blizzEquipHooked then return end
  self.__blizzEquipHooked = true
  PaperDollSidebarTab3:HookScript('OnClick', function(btn) self:OnClick_BlizzEquipmentPanel() end)
end

function o:OnLoad()
  ns.toggleButton = self

  self:SetParent(PaperDollFrame)
  self.owner = PaperDollFrame

  -- green highlight
  local hl = self:GetHighlightTexture()
  hl:SetColorTexture(0.2, 1.0, 0.4, 0.25)
  hl:ClearAllPoints()
  hl:SetPoint('TOPLEFT', self, 'TOPLEFT', 3, -3)
  hl:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -3, 3)
  self:SetScale(0.9)

  self:__UpdateGlow()

  local icon = self:CreateTexture(nil, 'OVERLAY')
  icon:SetSize(28, 28)
  icon:SetPoint('CENTER', self)
  icon:SetTexture(TOGGLE_BUTTON_ICON)
  icon:SetDrawLayer('OVERLAY', 1)
  self.Icon = icon

  self:RegisterMessage(ns:msg('OnAfterInit'), 'OnAfterInit')
  self:RegisterMessage(ns:msg('ShowPaperDollFrame'), 'OnShowPaperDollFrame')

  self:Show()
end

--- Gears will be shown by default on PaperDollFrame::Open
--- @param evt Name
--- @param gearsMainFrame Gears_MainFrameMixin
function o:OnAfterInit(evt, gearsMainFrame)
  self.__ecsFrame, self.__ecsButton = ECS_StatsFrame, ECS_ToggleButton

  ToggleButtonMixin_BlizzEquipmentGearHook(self)

  self:UpdateVisibilityState(false)
end

--- @param self ToggleButtonMixin|ToggleButton
local function ToggleButtonMixin_ECS_ToggleButton_Hook(self)
  if not self.__ecsButton or self.__ecsToggleButtonHooked then return end
  self.__ecsButton:HookScript('OnClick', function(btn) self:OnClick_ECS_ToggleButton() end)
  self.__ecsToggleButtonHooked = true
end

--- @param evt Name
--- @param gearsMainFrame Gears_MainFrameMixin
--- @param pdf PaperDollFrame
function o:OnShowPaperDollFrame(evt, gearsMainFrame, pdf)
  ToggleButtonMixin_BlizzEquipmentGearHook(self)
  ToggleButtonMixin_ECS_ToggleButton_Hook(self)

  local gs = ns:g()
  local isFirstTime = not gs.isInitialShowComplete

  self:UpdateVisibilityState(isFirstTime or self.__sticky == true)

  if isFirstTime then gs.isInitialShowComplete = true end
end

--- If Gears is shown, hide it
function o:OnClick_ECS_ToggleButton()
  if self:IsChecked() then self:Click() end
end

function o:OnClick()
  self.__sticky = self:IsChecked() and IsAltKeyDown()
  self:__UpdateGlow()
  self:UpdateVisibility()
end

--- @param visible boolean
function o:UpdateVisibilityState(visible)
  self:SetChecked(visible)
  self:UpdateVisibility()
end

function o:UpdateVisibility()
  GameTooltip:Hide()
  if self:IsChecked() then
    self:__ShowGears()
    return
  end
  self:__HideGears()
end

function o:OnEnter()
  self:SendMessage(ns:msg('SlotEnter'))
  if self:GetChecked() and not self.__sticky then return end

  C_Timer.After(TOOLTIP_DELAY, function()
    if not self:IsMouseOver() then return end
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    self:__SetTooltipText()
    GameTooltip:Show()
  end)
end

function o:__SetTooltipText()
  if self.__sticky then
    GameTooltip:SetText(c_gold(L['Kept open this session']))
    GameTooltip:AddLine(
      c_yellow(L['Left-click']) .. ': ' .. c_white(L['Close and stop keeping open'])
    )
    GameTooltip:AddLine(c_white(L['Resets on /reload']))
    return
  end
  GameTooltip:SetText(L['Open Gears Panel'], 1, 1, 1)
  GameTooltip:AddLine(c_yellow(L['Alt-click']) .. ': ' .. c_white(L['Keep open this session']))
end

function o:__UpdateGlow()
  local c = self.__sticky and GLOW_STICKY or GLOW_NORMAL
  self:GetCheckedTexture():SetVertexColor(unpack(c))
end

function o:OnLeave() GameTooltip:Hide() end

function o:IsChecked() return self:GetChecked() end

function o:__ShowGears()
  ns:PlaySound(SOUNDKIT.IG_MINIMAP_OPEN)
  ns.gears:Show()
  ns:esfm():EnableEquipmentSlots(true)
  self:__HideECS()

  self:__HideBlizzESManager()
end

--- Hides the Blizzard Equipment Manager UI by switching away from its sidebar tab.
--- This effectively hides the EquipmentSetManager slots when they are currently visible.
function o:__HideBlizzESManager()
  if not self:__BlizzEquipManagerIsShown() then return end
  PaperDollSidebarTab1:Click()
end

function o:__ShowBlizzESManager() end

function o:__HideGears()
  self.__sticky = false
  self:__UpdateGlow()
  ns:PlaySound(SOUNDKIT.IG_MINIMAP_CLOSE)
  ns.gears:HideGears()
  ns:esfm():EnableEquipmentSlots(false)

  self:__ShowBlizzESManager()
end

function o:__HideECS() return self.__ecsFrame and self.__ecsFrame:Hide() end

--- Hide 'Gears' panel if Blizz EquipmentSet Panel is shown
function o:OnClick_BlizzEquipmentPanel()
  if not self:IsChecked() then return end
  self:__HideGears()
  self:SetChecked(false)
end

function o:AnchorToPaperDoll()
  if not (EngravingFrame and RuneFrameControlButton) then return end

  --- @type CheckButton
  local anch = RuneFrameControlButton
  --- @type CheckButton
  local btn = Gears_ToggleButton
  btn:ClearAllPoints()
  btn:SetPoint('TOPRIGHT', anch, 'TOPLEFT', -2, 1)
end

--- @return Frame Container
function o:__GetBlizzEquipManager()
  return PaperDollFrame and PaperDollSidebarTab1 and PaperDollFrame.EquipmentManagerPane
end

--- @return boolean
function o:__BlizzEquipManagerIsShown()
  local em = self:__GetBlizzEquipManager()
  return em and em:IsShown()
end
