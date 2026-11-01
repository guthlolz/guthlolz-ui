--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
--- @type Gears_Namespace
local ns = select(2, ...)
local Table = ns.O.Table
local tbl_DeepCopy = Table.DeepCopy

--[[-------------------------------------------------------------------
Type Definitions
---------------------------------------------------------------------]]
--  ================================================
--- @class DatabaseObj : AceDBObject-3.0
--- @field global GlobalConfig
--- @field profile ProfileConfig
--- @field char table?
--- @field realm table?
--- @field factionrealm table?

--  ================================================
--- @class GlobalConfig
--- @field schemaVersion number
--- @field isInitialShowComplete boolean @True after Gears has been shown once on first PaperDoll open; used to prevent auto-show on subsequent opens
--- @field announcementsShown table<string, boolean> @Keyed by announcement dbKey; true once that one-time announcement dialog has been shown
--- @field announceEquip boolean @When true, `/gears equip` prints an "Equipped:" chat message on success
--- @field helpTipsDismissed table<string, boolean> @Keyed by help tour step key; true once that step is closed or its action is done
--- @field tourBaseline number? @Feature-tour baseline; LibHelpTour saves it on first show, so new users skip older feature tours
--- @field actionBarEquippedSet boolean @When true, native action bar set buttons show equipped state

--  ================================================
--- @class ProfileConfig

--[[-----------------------------------------------------------------------------
Module::DatabaseSchema
-------------------------------------------------------------------------------]]

--- @see NamespaceObjects
local libName = 'DatabaseSchema'

--- @class DatabaseSchema
local o = {}; ns.O.DatabaseSchema = o
local p, t = ns:log(libName)
--[[-------------------------------------------------------------------
Default Database
---------------------------------------------------------------------]]
local DB_VERSION = 2

--- @type DatabaseObj
local DEFAULT_DB = {
  ['global'] = {
    schemaVersion = DB_VERSION,
    isInitialShowComplete = false,
    announcementsShown = {},
    announceEquip = true,
    helpTipsDismissed = {},
    actionBarEquippedSet = true,
  },
  ['profile'] = {},
  ['char'] = {},
}

--[[-----------------------------------------------------------------------------
Module::DatabaseSchema (Methods)
-------------------------------------------------------------------------------]]

--- @return DatabaseObj
function o:GetDefaultDatabase() return tbl_DeepCopy(DEFAULT_DB) end
