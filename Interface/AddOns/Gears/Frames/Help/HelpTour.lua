--[[-----------------------------------------------------------------------------
HelpTour: the main frame's LibHelpTour controller.

Keeps the saved field the old help tip used (helpTipsDismissed), so existing
users don't see the tip again.
@see TourList.lua
-------------------------------------------------------------------------------]]
--- @type Gears_Namespace
local ns = select(2, ...)
local L = ns:GetLocale()
local TourList = ns.O.TourList
local HelpTourLib = LibStub('LibHelpTour-1.0')

ns.O.HelpTour = HelpTourLib:New({
  tours = TourList,
  dismissed = function() return ns:g().helpTipsDismissed end,
  getBaseline = function() return ns:g().tourBaseline end,
  setBaseline = function(baseline) ns:g().tourBaseline = baseline end,
  text = function(textKey) return L[textKey] end,
})
