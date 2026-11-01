local addon, kns = ...

--[[-------------------------------------------------------------------
Blizzard Vars
---------------------------------------------------------------------]]
local strtrim = strtrim

--[[-------------------------------------------------------------------
Local Vars
---------------------------------------------------------------------]]
local GVM = LibStub('Kapresoft-GameVersionMixin-2-0')
local AceLib = LibStub('Kapresoft-AceLib-2-0')

--- @class Gears_Namespace : Kapresoft-GameVersionMixin-2-0, Kapresoft-AceLib-2-0
--- @field __db DatabaseObj
--- @field O NamespaceObjects
--- @field gameVersion GameVersion
--- @field EvenTracePrinter EventTracePrinter
--- @field private logHolder Gears_LogHolder
--- @field gears Gears_MainFrame
--- @field toggleButton ToggleButton
--- @field colorDef Kapresoft-ColorDefinition-2-0
--- @field private logName Name @The prefix for all logs and traces
--- @field private printer LibPrettyPrint_Printer
--- @field RegisterAnnouncement fun(self: Gears_Namespace, def: AnnouncementDef) @see Announcement/AnnouncementDialogMixin.lua
--- @field ShowAnnouncementByKey fun(self: Gears_Namespace, dbKey: string) @see Announcement/AnnouncementDialogMixin.lua
--- @field ShowNextUnseenAnnouncement fun(self: Gears_Namespace) @see Announcement/AnnouncementDialogMixin.lua
local ns = kns

Mixin(ns, GVM, AceLib)
ns.addon = addon
GEARS_NS = ns
ns.O = ns.O or {}

--- Matches *.toc SavedVariables definition
local DB_NAME = 'GEARS_DB'
ns.logName = strupper(ns.addon)

--- @type NamespaceObjects
local O = ns.O or {}
ns.O = O

--[[-------------------------------------------------------------------
Base Colors
---------------------------------------------------------------------]]
local colorFormatter = LibStub('Kapresoft-ColorFormatter-2-0')

local prefixColor, subPrefixColor, util2Color, errorColor = '59A3FA', '9CFF9C', 'FFE680', 'FF4444'
ns.colorDef = {
  primary = CreateColorFromRGBHexString(prefixColor),
  secondary = CreateColorFromRGBHexString(subPrefixColor),
  util2 = CreateColorFromRGBHexString(util2Color),
  error = CreateColorFromRGBHexString(errorColor),
}

--[[-----------------------------------------------------------------------------
Logger and Tracer
-------------------------------------------------------------------------------]]
ns.logHolder = {}; do
  local h = ns.logHolder
  local noop_fn = function() end
  --- These are noop loggers and tracers for non-dev releases
  h.printer, h.tracer = noop_fn, noop_fn
end

--[[-----------------------------------------------------------------------------
Type: Settings
Override in DeveloperSetup to enable
-------------------------------------------------------------------------------]]
--- @class Gears_Settings
--- @field developer boolean @if true: enables developer mode
--- @field enableSound boolean @if false: suppresses all sounds (use forcePlay to override)
local settings = { developer = false, enableSound = false }
ns.settings = settings

--- @return boolean
function ns:IsDev() return ns.settings.developer == true end

--[[-------------------------------------------------------------------
Logger Methods
---------------------------------------------------------------------]]
local function predicateFn() return ns:IsDev() end
do
  ns.fmt = LibPrettyPrint:Formatter({
    show_all = true,
    depth_limit = 3,
  })
  if not fmt then fmt = ns.fmt end

  ns.printer = LibPrettyPrint:Printer({
    prefix = ns.addon,
    prefix_color = '466EFF',
    sub_prefix_color = '9CFF9C',
    formatter = ns.fmt,
  }, predicateFn)
end

--[[-------------------------------------------------------------------
Kapresoft Modules
---------------------------------------------------------------------]]
do
  local obj = ns.O
  obj.Table = LibStub('Kapresoft-Table-2-0')
  obj.String = LibStub('Kapresoft-String-2-0')
end

--[[-----------------------------------------------------------------------------
Namespace: Methods
-------------------------------------------------------------------------------]]
local function Namespace_Methods()
  local AceLocaleUtil = LibStub('Kapresoft-AceLocaleUtil-2-0')

  local function IsNilOrBlank(v) return v == nil or strtrim(v) == '' end

  ns.sformat = string.format
  ns.settings = settings
  ns.MAX_CHARS_SET_NAME = 32

  function ns.TRUE() return true end
  function ns:AceLib() return AceLib end
  --- For non-enUS locales only; always registers with isDefault=false, silent=true.
  --- @see AceLocale-3.0.NewLocale
  --- @param locale string
  --- @return table<string, boolean|string>? locale Locale Table to add localizations to, or nil if the current locale is not required.
  function ns:NewLocale(locale) return ns:AceLocale():NewLocale(ns.addon, locale, false, true) end

  --- @param name Name The module name; see NamespaceObjects
  --- @param obj any The namespace object
  function ns:register(name, obj)
    assert(type(name) == 'string', 'ns:register(name, obj): {name} should be a string')
    assertsafe(
      type(obj) == 'table',
      'ns:register(name, obj): {obj} should be a obj/table but was: %s',
      type(obj)
    )
    O[name] = obj
    return obj
  end

  --- ### Usage:
  --- ```
  --- -- automatic casting provied there is an
  --- -- object with @class EquipmentSlotFlyoutManager
  --- local ESM = ns:obj('EquipmentSlotFlyoutManager')
  --- ```
  --- @generic T
  --- @param lib `T`
  --- @return table|T library
  function ns:obj(lib) return ns.O[lib] end

  --- Register a Namespace Module/Library, e.g. a dependent addon announcing its presence.
  --- @generic T
  --- @param libName string
  --- @param anyObj T
  --- @return T
  function ns:Register(libName, anyObj)
    assert(
      type(libName) == 'string' and #libName > 0,
      'Register(libName, obj): {libName} is required.'
    )
    ns.O[libName] = anyObj
    return anyObj
  end

  --- @param mainFrame Gears_MainFrame
  function ns:RegisterMainFrame(mainFrame) ns.gears = mainFrame end

  --- @param rgbHex RGBHex?     @Optional
  --- @return cfFn, colorRGBA?
  function ns:ColorFn(rgbHex) return colorFormatter:ColorFn(rgbHex) end

  --- ### Usage
  ---  ```
  ---  -- @returns 'Gears::OnPlayerLogin'
  ---  local message = ns:msg('OnPlayerLogin')
  ---  ```
  --- @param msgName Name @The base message name; used for AceEvent messages
  --- @return string
  function ns:msg(msgName)
    assert(not IsNilOrBlank(msgName), 'Message name is required.')
    return ('%s::%s'):format(ns.addon, msgName)
  end

  function ns:AddonUtil() return LibStub('Kapresoft-AddonUtil-2-0') end
  function ns:AddonInfoUtil() return LibStub('Kapresoft-AddonInfoUtil-2-0') end

  local addonInfoUtil__
  --- @return Kapresoft-AddonInfoUtil-2-0
  function ns:aiu()
    if not addonInfoUtil__ then addonInfoUtil__ = ns:AddonInfoUtil():New(ns.addon) end
    return addonInfoUtil__
  end

  --- @return string @e.g. "2026.9.8"
  function ns:GetVersion()
    local version = ns:aiu():GetVersion()
    return version
  end

  --- @return table<string, string>
  function ns:GetLocale() return AceLocaleUtil:GetLocale(ns.addon, true) or {} end

  --- >Safe wrapper for PlaySound.
  --- >Returns two results: willPlay:boolean, soundHandle:boolean
  --- [Documentation](https://warcraft.wiki.gg/wiki/API_PlaySound)
  --- ##### Example:
  --- ```
  --- local willPlay, soundHandle = PlaySound(...)
  --- ```
  --- @param soundKitID number
  --- @param forcePlay boolean?           @If true, plays even when enableSound is false
  --- @param channel SoundChannel?        @The default is 'Effects' or 'SFX' (both are same)
  --- @param forceNoDuplicates boolean?
  --- @param runFinishCallback boolean?
  --- @return boolean?, number?
  function ns:PlaySound(soundKitID, forcePlay, channel, forceNoDuplicates, runFinishCallback)
    if not soundKitID then return end
    if not ns.settings.enableSound and not forcePlay then return end
    return PlaySound(soundKitID, channel, forceNoDuplicates, runFinishCallback)
  end

  --- @boolean
  function ns:HasBlizzEquipmentManager()
    return PaperDollFrame and PaperDollSidebarTab1 and PaperDollFrame.EquipmentManagerPane
  end

  --- Equips the equipment set by ID. Does not play sounds or present UI;
  --- callers decide how to surface success/failure.
  --- @NotCombatSafe
  --- @param id Identifier @The equipmentSet ID
  --- @return boolean success
  --- @return 'combat'? reason @Present when success is false
  function ns:EquipEquipmentSet(id)
    if InCombatLockdown() then return false, 'combat' end
    if EquipmentManager_EquipSet then
      EquipmentManager_EquipSet(id)
    else
      C_EquipmentSet.UseEquipmentSet(id)
    end
    return true
  end

  --- @return EquipmentSlotFlyoutManager
  function ns:esfm() return ns.O.EquipmentSlotFlyoutManager end

  --[[--------------------------------------------------------
  Database
  ------------------------------------------------------------]]

  function ns:InitDatabase()
    self.__db = ns:AceDB():New(DB_NAME, ns.O.DatabaseSchema:GetDefaultDatabase())
  end
  --- @return DatabaseObj
  function ns:db() return self.__db end
  --- @return GlobalConfig
  function ns:g() return self:db()['global'] end
  --- @return ProfileConfig
  function ns:p() return self:db().profile end

  --[[-------------------------------------------------------------------
  Loggers/Tracers:: NoOp in Official Releases
                    This is overridden in DeveloperSetup
  ---------------------------------------------------------------------]]
  --- Returns the print, delayed-print, tracer, formatted-tracer functions
  --- ```
  --- local p, t = ns:log('EventHandler')
  --- ```
  --- @see DeveloperSetup.lua
  --- @param moduleName Name  @The module name or any general prefix
  --- @return Gears_PrintFn
  --- @return Gears_TraceFn
  function ns:log(moduleName)
    local h = self.logHolder
    return h.printer(moduleName), h.tracer(moduleName)
  end
end; Namespace_Methods()
