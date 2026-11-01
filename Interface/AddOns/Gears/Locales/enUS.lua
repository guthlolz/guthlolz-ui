--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Gears_Namespace
local ns = select(2, ...)
local p, t = ns:log('Locale_enUS')

local L = ns:AceLocale():NewLocale(ns.addon, 'enUS', true, true)
if not L then return end

--[[-------------------------------------------------------------------
Locale Values
---------------------------------------------------------------------]]
L['Set Name'] = true
L['Currently Equipped'] = true
L['Left-click'] = true
L['Double-click'] = true
L['Drag'] = true
L['Available Actions'] = true
L['Select'] = true
L['Equip'] = true
L['Drag to an action bar'] = true
L['Set Icon::TooltipHint'] = "Drag and drop onto this set's icon to change it."
L['Set Icon::HelpTip'] = "Drag and drop onto any set's icon to change it."
L['Equip While Combat'] = 'Equipment sets cannot be changed during combat.'

L['Open Gears Panel'] = true
L['Alt-click'] = true
L['Keep open this session'] = true
L['Kept open this session'] = true
L['Close and stop keeping open'] = true
L['Resets on /reload'] = true
L['Create a new equipment set'] = true
L['New Equipment Set'] = true
L['LibIconPicker Missing'] =
  'This feature requires LibIconPicker.|nPlease make sure LibIconPicker is installed and enabled, then reload the UI.'

L['Available commands:'] = true
L['displays the addon info'] = true
L['equips the named or indexed equipment set'] = true
L['Usage'] = true
L['No such equipment set with name or index'] = true
L['Equipped:'] = true
L['Already Equipped:'] = true
L['shows the currently equipped set, if any'] = true
L['No equipment set is currently equipped'] = true
L['lists all equipment sets'] = true
L['No equipment sets found'] = true
L['Equipment Sets:'] = true
L['equipped'] = true

--[[-------------------------------------------------------------------
New Locale Items Below (Needs translation)
---------------------------------------------------------------------]]
L['Select a set to enable slot actions'] = 'Select a set to enable slot actions'
L['Include Slot'] = true
L['Include Slot::DESC'] = 'Include this slot when saving the equipment set'
L['Ignore Slot'] = true
L['Ignore Slot::DESC'] = 'Exclude this slot when saving the equipment set'
L['Place item in bags'] = true
L['Place item in bags::DESC'] = 'Moves equipped item to first available bag slot'
L['Shift-Click'] = true
L['Ignore All Slots'] = true
L['Include All Slots'] = true
L['General'] = true
L['General::DESC'] = 'Settings shared by all your characters'
L['Announce Equip in Chat'] = true
L['Announce Equip in Chat::DESC'] =
  'Prints a confirmation message in the chat window when using /gears equip'
L['opens the Gears options panel'] = true
L['Equipped Items'] = true
L['In Bags'] = true
L['Missing'] = true
L['Equipped Set Indicator on Action Bars'] = true
L['Equipped Set Indicator on Action Bars::DESC'] =
  "Outlines an equipment set's action bar button when the whole set is equipped, and adds equipped, in-bag and missing counts to its tooltip"
