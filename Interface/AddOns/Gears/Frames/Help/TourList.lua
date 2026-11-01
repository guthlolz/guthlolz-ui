--[[-----------------------------------------------------------------------------
TourList: every help tour, in priority order.

Tours without `since` are always eligible (the welcome tour). Feature tours
set `since` one past the highest in use, so only users who installed before
it see them. Step keys must be unique across all tours.
@see HelpTour.lua
-------------------------------------------------------------------------------]]
--- @type Gears_Namespace
local ns = select(2, ...)

--- @type LibHelpTour_Tour[]
ns.O.TourList = {
  {
    id = 'welcome',
    targetId = 'MainFrame',
    steps = {
      {
        -- Old tip's key: users who closed it won't see it again
        key = 'SetIconDrag',
        textKey = 'Set Icon::HelpTip',
        --- @param f Gears_MainFrame
        anchor = function(f) return f:FirstSetIcon() end,
      },
    },
  },
}
