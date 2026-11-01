--[[-----------------------------------------------------------------------------
Namespace
-------------------------------------------------------------------------------]]

--- @type Gears
GEARS = {}
--- @type Gears_Namespace
GEARS_NS = {}

--- @type Gears_OptionsUI
GEARS_OPTIONSUI = {}
--- @type Gears_OptionsUI_Namespace
GEARS_OPTIONSUI_NS = {}

--- @class NamespaceObjects
--- @field ActionBarEquipmentSet ActionBarEquipmentSet
--- @field Ace3WidgetConfig Gears_Ace3WidgetConfig
--- @field Ace3WidgetUtil Gears_Ace3WidgetUtil
--- @field GameVersion GameVersion
--- @field HelpTour LibHelpTour_Controller
--- @field TourList LibHelpTour_Tour[]
--- @field LibIconPickerUtil LibIconPickerUtil
--- @field CharacterFrameUtil CharacterFrameUtil
--- @field DatabaseSchema DatabaseSchema
--- @field EquipmentSlotFlyoutManager EquipmentSlotFlyoutManager
--- @field InventoryUtil InventoryUtil
--- @field ItemUtil ItemUtil
--- @field Table Kapresoft-Table-2-0
--- @field String Kapresoft-String-2-0

--- @class Gears_LogHolder
--- @field printer fun(moduleName:Name) : Gears_PrintFn    @A simple logger function
--- @field tracer fun(moduleName:Name)  : Gears_TraceFn    @A simple trace function

--- @alias Gears_PrintFn LibPrettyPrint_PrintFn @Printer function that outputs plain values to Blizzard Trace UI (like print)
--- @alias Gears_TraceFn fun(...: any) : void   @Printer function that outputs plain values to Blizzard Trace UI (like print)

--[[-------------------------------------------------------------------
This file only for emmyLua and is not included in the deploy.
---------------------------------------------------------------------]]
--- @type ToggleButton
Gears_ToggleButton = {}

--- @type Gears_MainFrame
Gears_MainFrame = {}

--- @type Frame
PaperDollFrame = {}

--[[-------------------------------------------------------------------
InventorySlotInfo
---------------------------------------------------------------------]]
--- @class InventorySlotInfo
--- @field name Name The slot name
--- @field id number @See [InventorySlotID](https://warcraft.wiki.gg/wiki/InventorySlotID)
--- @field iconID IconIDOrPath
--- @field checkRelic boolean

--- @class BlizzCharacterSlotItemButton : Button
--- @field ignoreSlotOverlay Texture
--- @field popoutButton Button
--- @field gears Gears_BlizzCharacterSlotItemButton

--[[-------------------------------------------------------------------
Aliases
---------------------------------------------------------------------]]
--- @alias EquipSetID number @The EquipmentSet Identifier
--- @alias SlotID number @The equipment slot ID
