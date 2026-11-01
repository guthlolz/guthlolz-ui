--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Gears_Namespace
local ns = select(2, ...)
local CONFIG = ns.O.Ace3WidgetConfig
local ACD = ns:AceConfigDialog()

--[[-----------------------------------------------------------------------------
New Instance
-------------------------------------------------------------------------------]]
--- @see NamespaceObjects
local libName = 'Ace3WidgetUtil'

--- Tooltip helpers for our AceGUI widgets
--- @class Gears_Ace3WidgetUtil
local o = {}; ns:register(libName, o)

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
--- @param widget AceGUIWidget
--- @param tooltip GameTooltip
--- @param context ScriptRegion
function o:AnchorTooltip(widget, tooltip, context)
  local offset = CONFIG:Layout(widget).tooltip
  tooltip:SetAnchorType('ANCHOR_NONE')
  tooltip:ClearAllPoints()
  tooltip:SetPoint('BOTTOMLEFT', context, 'TOPRIGHT', offset.x, offset.y)
end

--- Also moves AceConfigDialog's tooltip beside the context
--- @param widget AceGUIWidget
--- @param context ScriptRegion
function o:FireEnter(widget, context)
  widget:Fire('OnEnter')
  local tooltip = ACD.tooltip
  if not (tooltip:IsShown() and tooltip:GetOwner() == widget.frame) then return end
  self:AnchorTooltip(widget, tooltip, context)
end
