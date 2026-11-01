-- Gears-OptionsUI/Init.lua
local gears = GEARS; if not gears then return end

--- @type Gears_OptionsUI_Namespace
local ns = select(2, ...)
local p, t = ns:log()
local cns, O, L = ns:cns()

local AceConfig = cns:AceConfig()
local AceConfigDialog = cns:AceConfigDialog()
local ActionBarEquipmentSet = O.ActionBarEquipmentSet

local CONSOLE_COMMAND_OPTIONS = 'gears-options'
local DIALOG_WIDTH, DIALOG_HEIGHT = 600, 320

-- Wider than the widget default; fits the longer labels
--- @type Gears_Ace3WidgetArg
local GENERAL_ARG = { layout = { label = { width = 210 } } }

--[[-----------------------------------------------------------------------------
AddOn
-------------------------------------------------------------------------------]]
--- @class Gears_OptionsUI : AceAddon-3.0, AceEvent-3.0
local o = cns:AceAddon():NewAddon(ns.addon, 'AceEvent-3.0')
GEARS_OPTIONSUI = o

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- @return fun(): number @Returns the next option order on each call
local function Sequence()
  local n = 0
  return function()
    n = n + 1
    return n
  end
end

--- @param key string
--- @return fun(): any
local function GlobalGet(key)
  return function() return cns:g()[key] end
end

--- @param key string
--- @return fun(_, val: any)
local function GlobalSet(key)
  return function(_, val) cns:g()[key] = val end
end

--[[-----------------------------------------------------------------------------
Options Table
-------------------------------------------------------------------------------]]
--- @return AceConfig.OptionsTable
local function CreateOptions()
  local order = Sequence()
  return {
    type = 'group',
    name = ('%s v%s'):format(cns.addon, cns:GetVersion()),
    args = {
      general = {
        type = 'group',
        name = L['General'],
        desc = L['General::DESC'],
        order = order(),
        args = {
          announceEquip = {
            type = 'toggle',
            width = 'full',
            order = order(),
            dialogControl = 'Gears_SettingsCheckbox',
            arg = GENERAL_ARG,
            name = L['Announce Equip in Chat'],
            desc = L['Announce Equip in Chat::DESC'],
            get = GlobalGet('announceEquip'),
            set = GlobalSet('announceEquip'),
          },
          actionBarEquippedSet = {
            type = 'toggle',
            width = 'full',
            order = order(),
            dialogControl = 'Gears_SettingsCheckbox',
            arg = GENERAL_ARG,
            name = L['Equipped Set Indicator on Action Bars'],
            desc = L['Equipped Set Indicator on Action Bars::DESC'],
            get = GlobalGet('actionBarEquippedSet'),
            set = function(_, val)
              cns:g().actionBarEquippedSet = val
              ActionBarEquipmentSet:Refresh()
            end,
          },
        },
      },
    },
  }
end

function o:RegisterOptions()
  AceConfig:RegisterOptionsTable(cns.addon, CreateOptions(), { CONSOLE_COMMAND_OPTIONS })
  AceConfigDialog:AddToBlizOptions(cns.addon, cns.addon)
  AceConfigDialog:SetDefaultSize(cns.addon, DIALOG_WIDTH, DIALOG_HEIGHT)
end

function o:OnEnterCombat() AceConfigDialog:Close(cns.addon) end

--[[-------------------------------------------------------------------
Lifecycle Methods
---------------------------------------------------------------------]]
function o:OnInitialize() self:RegisterOptions() end
function o:OnEnable()
  self:RegisterEvent('PLAYER_REGEN_DISABLED', 'OnEnterCombat')
  self:SendMessage(ns:msg('OnEnable'), self)
end
