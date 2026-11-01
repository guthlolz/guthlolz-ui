--- @type Gears_Namespace
local ns = select(2, ...)
local L = ns:GetLocale()

--[[-------------------------------------------------------------------
Blizzard Vars
---------------------------------------------------------------------]]
local C_GetEquipmentSetInfo = C_EquipmentSet.GetEquipmentSetInfo
local C_PickupEquipmentSet = C_EquipmentSet.PickupEquipmentSet
local C_ModifyEquipmentSet = C_EquipmentSet.ModifyEquipmentSet
local C_SaveEquipmentSet = C_EquipmentSet.SaveEquipmentSet

local CURRENTLY_EQUIPPED = CURRENTLY_EQUIPPED or L['Currently Equipped']

--[[-------------------------------------------------------------------
Local Vars
---------------------------------------------------------------------]]
local HelpTour = ns.O.HelpTour
local CHECKBOX_TEXTURE = [[Interface\Buttons\UI-CheckBox-Check]]
local TOOLTIP_DELAY = 0.01
local BULLET = '•'

local bulletFmt = ' %s %s: %s'
local c_white = ns:ColorFn('afafaf')
local c_blue = ns:ColorFn('71ABFF')
local c_green = ns:ColorFn('6EE6A0')
local c_yellow1 = ns:ColorFn('E6BF33')
local c_yellow = ns:ColorFn('FFE680')

--[[-------------------------------------------------------------------
Mixin
---------------------------------------------------------------------]]

--
--- @class EquipmentSetFrame : EquipmentSetMixin
--

--- @class EquipmentSetIconButton : Button
--- @field Checked Texture @Shown while the cursor holds a droppable icon

--- @class EquipmentSetMixin : Button, BackdropTemplate
--- @field GetID fun(self:EquipmentSetMixin) : number @The EquipmentSet Identifier
--- @field owner Gears_MainFrame
--- @field info EquipmentSetInfo
--- @field selected boolean
--- @field CheckMark Texture
--- @field IconButton EquipmentSetIconButton
--- @field DeleteButton Button
--- @field ChangeButton Button
--- @field private __used boolean?
Gears_EquipmentSetMixin = {}
local p, t = ns:log('EquipmentSetMixin')

local BACKDROP_WITH_BG = {
  bgFile = 'Interface\\Buttons\\WHITE8X8',
  edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
  edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
}
--[[-------------------------------------------------------------------
Support Functions
---------------------------------------------------------------------]]
--- Show an error message
--- @param msg string
local function ShowError(msg)
  assert(type(msg) == 'string', 'The msg param is a required string.')
  UIErrorsFrame:AddMessage(msg, 1.0, 0.1, 0.1)
end

--- @param id Identifier The equipmentSet ID
--- @return EquipmentSetDetails?
local function GetEquipmentSet(id)
  assert(type(id) == 'number', 'GetEquipmentSet(id): {id} is missing')

  local name, iconFileID, setID, isEquipped, numItems, numEquipped, numInInventory, numLost, numIgnored =
    C_GetEquipmentSetInfo(id)

  if not name then return nil end

  --- @type EquipmentSetDetails
  local eq = {
    name = name,
    iconID = iconFileID,
    id = setID,
    isEquipped = isEquipped,
    numItems = numItems,
    numEquipped = numEquipped,
    numInInventory = numInInventory,
    numLost = numLost,
    numIgnored = numIgnored,
  }
  return eq
end

--- @param id Identifier @The equipmentSet ID
--- @return boolean
local function IsFullyEquipped(id)
  local eqs = GetEquipmentSet(id)
  return eqs ~= nil and eqs.isEquipped
end

--- Keyed by GetCursorInfo() type; args are its other returns.
--- No 'equipmentset' entry: rows are drag sources themselves.
--- @type table<string, fun(id: number|string, arg2: any, arg3: any): IconIDOrPath?>
local cursorIconResolvers = {
  item = function(itemID) return C_Item.GetItemIconByID(itemID) end,
  spell = function(_, _, spellID) return (C_Spell.GetSpellTexture(spellID)) end,
  macro = function(index) return (select(2, GetMacroInfo(index))) end,
  mount = function(mountID) return (select(3, C_MountJournal.GetMountInfoByID(mountID))) end,
  battlepet = function(petID) return (select(9, C_PetJournal.GetPetInfoByPetID(petID))) end,
}

--- @return IconIDOrPath? @nil if the cursor holds nothing droppable
local function GetCursorIcon()
  local cursorType, id, arg2, arg3 = GetCursorInfo()
  local resolve = cursorType and cursorIconResolvers[cursorType]
  return resolve and resolve(id, arg2, arg3)
end

--- @type Frame?
local hookedPicker

local function UpdateAllDropTargetStates()
  ns.gears:ForEachEquipmentFrame(function(eqs) eqs:UpdateDropTargetState() end)
end

--- The picker loads on demand, so hook it on first sight
--- @param picker Frame
local function HookIconPickerOnce(picker)
  if hookedPicker == picker then return end
  picker:HookScript('OnShow', UpdateAllDropTargetStates)
  picker:HookScript('OnHide', UpdateAllDropTargetStates)
  hookedPicker = picker
end

--- @return boolean
local function IsIconPickerShown()
  --- @type Frame
  local picker = LibIconPicker_IconSelector
  if not picker then return false end
  HookIconPickerOnce(picker)
  return picker:IsShown()
end

--- @param tt GameTooltip
--- @param id Identifier EquipmentSet ID
local function GameTooltip_AddEquipmentDetails(tt, id)
  local eqs = GetEquipmentSet(id)
  if eqs and eqs.isEquipped then tt:AddLine(c_green(CURRENTLY_EQUIPPED)) end
end

--- @param self EquipmentSetFrame
local function EquipmentSet_ShowTooltip(self)
  if GetCursorIcon() then return end
  C_Timer.After(TOOLTIP_DELAY, function()
    if not self:IsMouseOver() then return end

    local availableActions = c_blue(L['Available Actions']) .. ':'
    local leftClick = (bulletFmt):format(
      c_white(BULLET),
      c_yellow(L['Left-click']),
      c_white(L['Select'])
    )
    local doubleClick = (bulletFmt):format(
      c_white(BULLET),
      c_yellow(L['Double-click']),
      c_white(L['Equip'])
    )
    local drag = (bulletFmt):format(
      c_white(BULLET),
      c_yellow(L['Drag']),
      c_white(L['Drag to an action bar'])
    )
    local bottomText = c_white(L['Select a set to enable slot actions'])
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    local eqID = self:GetID()
    GameTooltip:SetEquipmentSet(eqID)
    GameTooltip_AddEquipmentDetails(GameTooltip, eqID)
    GameTooltip:AddLine(' ')
    GameTooltip:AddLine(availableActions)
    GameTooltip:AddLine(leftClick)
    GameTooltip:AddLine(doubleClick)
    GameTooltip:AddLine(drag)
    GameTooltip:AddLine(' ')
    GameTooltip:AddLine(c_green(L['Set Icon::TooltipHint']), nil, nil, nil, true)
    if not ns.gears:HasSelection() then
      GameTooltip:AddLine(' ')
      GameTooltip:AddLine(bottomText)
    end
    GameTooltip:Show()
  end)
end

--[[-------------------------------------------------------------------
Methods
---------------------------------------------------------------------]]

local o = Gears_EquipmentSetMixin
o.EquipmentSet = true

function o:OnLoad()
  BackdropTemplateMixin.OnBackdropLoaded(self)

  self:SetBackdrop(BACKDROP_WITH_BG)
  self:HideBorder()
  self:__OnLoadCheckMark()
  self:__OnLoadCreateDeleteButton()
  self:__OnLoadCreateChangeButton()
  if self:IsVisible() then self:OnShow() end
end

function o:OnShow()
  self:RegisterEvent('CURSOR_CHANGED')
  self:UpdateDropTargetState()
end
function o:OnHide() self:UnregisterEvent('CURSOR_CHANGED') end
function o:OnEvent() self:UpdateDropTargetState() end

function o:__OnLoadCreateDeleteButton()
  --- @class DeleteButton : Button, IconButton
  local btn = CreateFrame(
    'Button',
    '$parentDeleteButton',
    self,
    'Gears_DeleteButtonTemplate' --[[@as Template]]
  )
  btn.owner = self
  btn:SetFrameLevel(self:GetFrameLevel() + 2)
  btn:ClearAllPoints()
  btn:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -2, 2)
  btn:Hide()
end

function o:__OnLoadCreateChangeButton()
  --- @class ChangeButton : Button, IconButton
  local btn = CreateFrame(
    'Button',
    '$parentChangeButton',
    self,
    'Gears_ChangeButtonTemplate' --[[@as Template]]
  )
  btn.owner = self
  btn:SetFrameLevel(self:GetFrameLevel() + 2)
  btn:ClearAllPoints()
  btn:SetPoint('RIGHT', self.DeleteButton, 'LEFT', 4, 0)
  btn:Hide()
end

--- @private
function o:__OnLoadCheckMark()
  self.CheckMark:SetTexture(CHECKBOX_TEXTURE)
  self.CheckMark:SetVertexColor(1, 1, 1, 1)
  self.CheckMark:Hide()
end

function o:OnDragStart() C_PickupEquipmentSet(self:GetID()) end
--- Nothing to do here
function o:OnDragStop() end
function o:OnReceiveDrag() self:DropCursorIcon() end

function o:UpdateDropTargetState()
  self.IconButton.Checked:SetShown(GetCursorIcon() ~= nil and not IsIconPickerShown())
end

--- Sets the cursor's icon as the set icon when dropped on IconButton
--- @return boolean @true if the icon was changed
function o:DropCursorIcon()
  if not self.IconButton:IsMouseOver() then return false end
  local icon = GetCursorIcon()
  if not icon then return false end

  local id, name = self:GetIdentity()
  C_ModifyEquipmentSet(id, name, icon)
  ClearCursor()
  HelpTour:CompleteStep('SetIconDrag')
  return true
end

--- Show check-mark if fully equipped.
--- The `callbackFn` is optional.
--- @param callbackFn nil|fun(isFullyEquipped:boolean) | "function(isFullyEquipped) end"
function o:UpdateFullyEquippedState(callbackFn)
  local equipped = IsFullyEquipped(self:GetID())
  if equipped then
    self.CheckMark:Show()
  else
    self.CheckMark:Hide()
  end
  if callbackFn then callbackFn(equipped) end
end

function o:OnMouseDown()
  if self:DropCursorIcon() then return end
  ns.gears:SelectEquipmentSet(self)
end

function o:OnEnter()
  EquipmentSet_ShowTooltip(self)

  if not self.selected then self:ShowBorderOnHover() end

  --- When we hover over to another EquipmentSetFrame,
  --- hide other EquipmentSet specific action buttons
  self.owner:ForEachEquipmentFrame(
    function(otherEQS) otherEQS:HideActionButtons() end,
    function(eqsInfo) return self:GetID() ~= eqsInfo.id end
  )

  self:ShowActionButtons()
end

function o:OnLeave()
  GameTooltip:Hide()
  self:HideActionButtonsIfMouseOut()
  if self.selected == true then return end
  self:HideBorder()
end

--- @NotCombatSafe
function o:OnDoubleClick() self:EquipGear() end

function o:ShowActionButtons()
  if GetCursorInfo() then return end
  self.DeleteButton:Show()
  self.ChangeButton:Show()
end
function o:HideActionButtons()
  self.DeleteButton:Hide()
  self.ChangeButton:Hide()
end
--- The buttons sit inside the row; moving onto one keeps them
function o:HideActionButtonsIfMouseOut()
  if self:IsMouseOver() then return end
  self:HideActionButtons()
end

--- @NotCombatSafe
function o:EquipGear()
  if ns:IsMists() then
    ns:PlaySound(SOUNDKIT.IG_BACKPACK_OPEN, true)
  else
    ns:PlaySound(SOUNDKIT.PUT_DOWN_SMALL_CHAIN, true)
    C_Timer.After(0.2, function() ns:PlaySound(SOUNDKIT.IG_BACKPACK_OPEN, true) end)
  end

  local success, reason = ns:EquipEquipmentSet(self:GetID())
  if not success and reason == 'combat' then ShowError(L['Equip While Combat']) end
end

function o:SaveGear()
  ns:PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
  local id = self:GetID()
  C_SaveEquipmentSet(id, self.info.icon)
  --__Trace_SaveGear(self)
  ns.gears:WithSelectedEquipmentSet(function(sel)
    if sel:GetID() == id then ns.gears:UpdateActionsEnabledState(false) end
  end)
end

---@param info EquipmentSetInfo
function o:SetInfo(info)
  assert(type(info) == 'table', 'SetInfo(info): {info} is missing')
  self.info = info
  self:SetID(info.id)
end

--- Select the equipment set.
--- This is not the same as 'equipped' state.
--- @param selected boolean
function o:SetSelected(selected)
  assert(type(selected) == 'boolean', 'Expected SetSelected(selected:boolean)')

  ns:PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
  self.selected = selected
  if self.selected then
    self:ShowAsSelectedBorder()
    return
  end
  self:HideBorder()
end

function o:ShowBorderOnHover()
  if self.selected or GetCursorInfo() then return end
  self:SetBackdropColor(1.0, 0.9, 0.2, 0.05)
  self:SetBackdropBorderColor(1.0, 0.82, 0.0, 0.9)
end

function o:HideBorder()
  if self.selected then return end
  self:SetBackdropColor(0, 0, 0, 0)
  self:SetBackdropBorderColor(0, 0, 0, 0)
end

function o:ShowAsSelectedBorder()
  self:SetBackdropColor(1, 1, 1, 0.1)
  self:SetBackdropBorderColor(1.0, 0.82, 0.0, 0.9)
end

--- The EquipmentSet ID
--- @return Identifier?, Name?, IconIDOrPath?
function o:GetIdentity()
  local info = self.info
  if not info then return nil end
  return info.id, info.name, info.icon
end

--- @return Name
function o:GetEquipmentSetName()
  local info = self.info
  return info and info.name
end

--- @return Name
function o:__GetDebugName() return ('%s::%s'):format(self.info.name, self.info.id) end
