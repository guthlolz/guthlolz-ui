--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Gears_Namespace
local ns = select(2, ...)
local t_merge = ns.O.Table.MergeRecursive

--[[-----------------------------------------------------------------------------
Types
-------------------------------------------------------------------------------]]
--- Per-option override passed through AceConfig's `arg`
--- @class Gears_Ace3WidgetArg
--- @field layout? Gears_Ace3WidgetLayout

--- @class Gears_Ace3WidgetSize
--- @field width? number  @px
--- @field height? number @px

--- Tooltip BOTTOMLEFT offset from its context's TOPRIGHT
--- @class Gears_Ace3WidgetTooltip
--- @field x? number @px
--- @field y? number @px

--- @class Gears_Ace3WidgetLayout
--- @field row? Gears_Ace3WidgetSize @Height only; AceGUI sets the row width
--- @field label? Gears_Ace3WidgetSize
--- @field checkbox? Gears_Ace3WidgetSize
--- @field tooltip? Gears_Ace3WidgetTooltip

--[[-----------------------------------------------------------------------------
Defaults
-------------------------------------------------------------------------------]]
--- @type Gears_Ace3WidgetLayout
local DEFAULT_LAYOUT = {
  row = { height = 30 },
  label = { width = 150 },
  checkbox = { width = 30, height = 30 },
  tooltip = { x = 20, y = 20 },
}

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @see NamespaceObjects
local libName = 'Ace3WidgetConfig'

--- Shared by our AceGUI widgets so their rows line up
--- @class Gears_Ace3WidgetConfig
local o = {}; ns:register(libName, o)

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- @param widget AceGUIWidget
--- @return Gears_Ace3WidgetArg? @The option's AceConfig `arg`; nil if unset
local function ArgFor(widget)
  local option = widget:GetUserData('option')
  return option and option.arg
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- The option's `arg.layout` merged over the defaults
--- @param widget AceGUIWidget
--- @return Gears_Ace3WidgetLayout
function o:Layout(widget)
  local arg = ArgFor(widget)
  local override = type(arg) == 'table' and arg.layout or {}
  -- Merge into a copy; arg tables are shared across options
  return t_merge(DEFAULT_LAYOUT, t_merge(override, {}))
end
