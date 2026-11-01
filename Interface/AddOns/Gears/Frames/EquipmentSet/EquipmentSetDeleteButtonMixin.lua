--- @type Gears_Namespace
local ns = select(2, ...)
--[[-------------------------------------------------------------------
Blizzard Vars
---------------------------------------------------------------------]]
local C_DeleteEquipmentSet = C_EquipmentSet.DeleteEquipmentSet
local DELETE = DELETE
local GEARS_CONFIRM_DELETE_EQUIPMENT_SET = 'GEARS_CONFIRM_DELETE_EQUIPMENT_SET'

--[[-------------------------------------------------------------------
Local Vars
---------------------------------------------------------------------]]
local p = ns:log('EquipmentSetDeleteButtonMixin')

--- @param dlg Frame @The static popup frame
--- @param equipmentSetID Identifier
local function Delete_OnAccept(dlg, equipmentSetID)
  C_DeleteEquipmentSet(equipmentSetID)
  ns:esfm():HideFlyouts()
end

--[[-------------------------------------------------------------------
Support Functions
---------------------------------------------------------------------]]
StaticPopupDialogs[GEARS_CONFIRM_DELETE_EQUIPMENT_SET] = {
  text = _G['CONFIRM_DELETE_EQUIPMENT_SET'],
  button1 = YES,
  button2 = NO,
  hideOnEscape = 1,
  timeout = 0,
  exclusive = 1,
  whileDead = 1,
  OnAccept = Delete_OnAccept,
  OnCancel = function(dlg, data) end,
}

--[[-------------------------------------------------------------------
Mixin
---------------------------------------------------------------------]]

--
--- @class EquipmentSetDeleteButton : EquipmentSetDeleteButtonMixin
--

--- @class EquipmentSetDeleteButtonMixin : Button
--- @field owner EquipmentSetFrame
--- @field DeleteButton boolean
Gears_EquipmentSetDeleteButtonMixin = {}

--[[-------------------------------------------------------------------
Methods
---------------------------------------------------------------------]]

local o = Gears_EquipmentSetDeleteButtonMixin
o.DeleteButton = true

function o:OnLoad()
  IconButtonMixin.OnLoad(self)
  self.tooltipText = DELETE
  -- baseline (dimmed)
  self.Icon:SetAlpha(0.4)
  self.onClickHandler = function()
    local id, name = self.owner:GetIdentity()
    StaticPopup_Show(GEARS_CONFIRM_DELETE_EQUIPMENT_SET, name, nil, id)
  end
end

function o:OnEnter()
  IconButtonMixin.OnEnter(self)
  self.owner:ShowBorderOnHover()
end

function o:OnLeave()
  IconButtonMixin.OnLeave(self)
  self.owner:HideBorder()
  self.owner:HideActionButtonsIfMouseOut()
end
