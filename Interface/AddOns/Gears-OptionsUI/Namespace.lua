--[[-------------------------------------------------------------------
Namespace: Gears_OptionsUI_Namespace
---------------------------------------------------------------------]]
local addon, xns = ...

--- @class Gears_OptionsUI_Namespace
--- @field addon Name The addon name
--- @field private logHolder Gears_LogHolder
local ns = xns
ns.addon = addon
GEARS_OPTIONSUI_NS = ns

--[[-------------------------------------------------------------------
Logger and Tracer
---------------------------------------------------------------------]]
ns.fmt = LibPrettyPrint:Formatter({
  show_all = true,
  depth_limit = 3,
})

ns.printer = LibPrettyPrint:Printer({
  prefix = ns.addon,
  prefix_color = '466EFF',
  sub_prefix_color = '9CFF9C',
  formatter = ns.fmt,
})

ns.logHolder = {}; do
  local h = ns.logHolder
  local noop_fn = function() end
  --- These are noop loggers and tracers for non-dev releases
  h.printer, h.tracer = noop_fn, noop_fn
end

--[[-------------------------------------------------------------------
Namespace Methods
---------------------------------------------------------------------]]

--- Core Gears namespace, its module registry, and its locale.
--- #### Usage: `local cns, O, L = ns:cns()`
--- @return Gears_Namespace, NamespaceObjects, table<string, string>
function ns:cns() return GEARS_NS, GEARS_NS.O, GEARS_NS:GetLocale() end

--- Message Format:  Gears-OptionsUI::<Message>
--- @param message Name @The base message name; used for AceEvent messages
--- @return string
function ns:msg(message)
  assert(type(message) == 'string' and #message > 0, 'msg(message): {message} should be a string')
  return ('%s::%s'):format(self.addon, message)
end

--- Returns the print, delayed-print, tracer, formatted-tracer functions
--- ```
--- local p, t = ns:log('EventHandler')
--- ```
--- @see Developer/DeveloperSetup.lua
--- @param moduleName Name  @The module name or any general prefix
--- @return Gears_PrintFn
--- @return Gears_TraceFn
function ns:log(moduleName)
  local h = self.logHolder
  return h.printer(moduleName), h.tracer(moduleName)
end
