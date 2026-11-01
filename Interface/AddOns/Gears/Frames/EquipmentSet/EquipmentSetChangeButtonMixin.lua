--- @type Gears_Namespace
local ns = select(2, ...)
local L = ns:GetLocale()

--[[-------------------------------------------------------------------
Local Vars
---------------------------------------------------------------------]]
local LibIconPickerUtil = ns.O.LibIconPickerUtil
local C_ModifyEquipmentSet = C_EquipmentSet.ModifyEquipmentSet

--[[-------------------------------------------------------------------
Mixin
---------------------------------------------------------------------]]

--
--- @class EquipmentSetChangeButton : EquipmentSetChangeButtonMixin
--

--- @class EquipmentSetChangeButtonMixin : Button, IconButtonMixin
--- @field owner EquipmentSetFrame
--- @field ChangeButton boolean
Gears_EquipmentSetChangeButtonMixin = {}
local p, t = ns:log('EquipmentSetChangeButtonMixin')

--[[-------------------------------------------------------------------
Methods
---------------------------------------------------------------------]]

local o = Gears_EquipmentSetChangeButtonMixin
o.ChangeButton = true

function o:OnLoad()
  IconButtonMixin.OnLoad(self)
  self.tooltipText = EQUIPMENT_SET_EDIT
  -- baseline (dimmed)
  self.Icon:SetAlpha(0.4)
  self.onClickHandler = function() self:ShowPicker() end
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

--- @return Name?
function o:GetEquipmentSetName()
  local info = self.owner.info
  return info and info.name
end

function o:ShowPicker()
  local id, name, icon = self.owner:GetIdentity()
  local opt = {
    icon = icon,
    showTextInput = true,
    textInput = { label = L['Set Name'] .. ':', value = name, max = ns.MAX_CHARS_SET_NAME },
  }
  LibIconPickerUtil:Get(function(lip)
    lip:Open(function(sel)
      if not sel.textInputValue then return end
      C_ModifyEquipmentSet(self.owner:GetID(), sel.textInputValue, sel.icon)
    end, opt)
  end)
end
