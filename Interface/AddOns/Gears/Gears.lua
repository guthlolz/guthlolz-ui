--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]

--- @type Gears_Namespace
local ns = select(2, ...)
local p, t = ns:log('AddOn')

local L = ns:GetLocale()
local cu1 = ns:ColorFn(ns.colorDef.util2)
local errFn = ns:ColorFn(ns.colorDef.error)

--- @type { cmd: string, desc: string }[] @Available slash commands, in display order
local slashCommands = {
  { cmd = 'info', desc = L['displays the addon info'] },
  { cmd = 'equip <index-or-name>', desc = L['equips the named or indexed equipment set'] },
  { cmd = 'status', desc = L['shows the currently equipped set, if any'] },
  { cmd = 'list', desc = L['lists all equipment sets'] },
}

local dependentAddOns = { 'Gears-OptionsUI' }

--- Resolves an equipment set by its 1-based display index or its name (case-insensitive).
--- @param indexOrName string
--- @return EquipmentSetInfo?
local function FindEquipmentSet(indexOrName)
  local asIndex = tonumber(indexOrName)
  local needle = indexOrName:lower()
  local found
  ns.gears:ForEachEquipment(function(info)
    if asIndex and info.index == asIndex then
      found = info
    elseif not asIndex and info.name:lower() == needle then
      found = info
    end
  end)
  return found
end

--- Finds the equipment set that is currently fully equipped, if any.
--- @return EquipmentSetInfo?
local function FindEquippedSet()
  local found
  ns.gears:ForEachEquipment(function(info)
    local _, _, _, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(info.id)
    if isEquipped then found = info end
  end)
  return found
end

--[[-----------------------------------------------------------------------------
AddOn
-------------------------------------------------------------------------------]]

--- @class Gears : AceAddon-3.0, AceEvent-3.0, AceBucket-3.0, AceConsole-3.0
local A = ns:AceAddon():NewAddon(ns.addon, 'AceEvent-3.0', 'AceBucket-3.0', 'AceConsole-3.0')
GEARS = A

--- @type Gears
local a = A

--[[-------------------------------------------------------------------
Lifecycle Methods
---------------------------------------------------------------------]]
function a:OnInitialize()
  ns:InitDatabase()
  for _, addonName in ipairs(dependentAddOns) do
    self:RegisterMessage(addonName .. '::OnEnable', 'OnReadyDependentAddOn')
  end
  self:RegisterChatCommand('gears', 'OnSlashCommand')
end
function a:OnEnable() end
function a:OnDisable() end

--- @param evt EventName
--- @param addon AceAddon
function a:OnReadyDependentAddOn(evt, addon) ns:Register(addon:GetName(), addon) end

--[[-------------------------------------------------------------------
Addon Methods
---------------------------------------------------------------------]]
function a:PrintSlashCommandHelp()
  self:Print(L['Available commands:'])
  for _, c in ipairs(slashCommands) do
    self:Print(('  %s - %s'):format(cu1(c.cmd), c.desc))
  end
  if ns.O[dependentAddOns[1]] then
    self:Print(('  %s - %s'):format(cu1('options'), L['opens the Gears options panel']))
  end
end

function a:PrintEquipUsage()
  self:Print(('%s: %s'):format(L['Usage'], cu1('/gears equip <index-or-name>')))
end

--- @param nameOrIndex string
function a:EquipEquipmentSet(nameOrIndex)
  if not nameOrIndex or nameOrIndex == '' then
    self:PrintEquipUsage()
    return
  end

  local eqs = FindEquipmentSet(nameOrIndex)
  if not eqs then
    self:Print(errFn(('%s: %s'):format(L['No such equipment set with name or index'], nameOrIndex)))
    return
  end

  local _, _, _, isEquipped = C_EquipmentSet.GetEquipmentSetInfo(eqs.id)
  if isEquipped then
    if ns:g().announceEquip then
      self:Print(('%s %s (#%d)'):format(L['Already Equipped:'], cu1(eqs.name), eqs.index))
    end
    return
  end

  local success, reason = ns:EquipEquipmentSet(eqs.id)
  if not success and reason == 'combat' then
    self:Print(errFn(L['Equip While Combat']))
    return
  end

  if ns:g().announceEquip then
    self:Print(('%s %s (#%d)'):format(L['Equipped:'], cu1(eqs.name), eqs.index))
  end
end

function a:PrintStatus()
  local eqs = FindEquippedSet()
  if not eqs then
    self:Print(L['No equipment set is currently equipped'])
    return
  end
  self:Print(('%s %s (#%d)'):format(L['Equipped:'], cu1(eqs.name), eqs.index))
end

function a:PrintList()
  local equipped = FindEquippedSet()
  local equippedId = equipped and equipped.id

  local lines = {}
  local count = ns.gears:ForEachEquipment(function(info)
    local line = ('  #%d %s'):format(info.index, cu1(info.name))
    if info.id == equippedId then line = ('%s %s'):format(line, ('(%s)'):format(L['equipped'])) end
    lines[#lines + 1] = line
  end)

  if count == 0 then
    self:Print(L['No equipment sets found'])
    return
  end

  self:Print(L['Equipment Sets:'])
  for _, line in ipairs(lines) do
    self:Print(line)
  end
end

function a:OpenOptions()
  if not ns.O[dependentAddOns[1]] then
    self:PrintSlashCommandHelp()
    return
  end
  ns:AceConfigDialog():Open(ns.addon)
end

--- @param input string
function a:OnSlashCommand(input)
  local cmd, rest = input:match('^(%S*)%s*(.-)$')
  if cmd == 'info' then
    self:Print(ns:aiu():GetInfoSlashCommandText())
  elseif cmd == 'equip' then
    self:EquipEquipmentSet(rest)
  elseif cmd == 'status' then
    self:PrintStatus()
  elseif cmd == 'list' then
    self:PrintList()
  elseif cmd == 'options' then
    self:OpenOptions()
  else
    self:PrintSlashCommandHelp()
  end
end

--[[-------------------------------------------------------------------
Event Hooks
---------------------------------------------------------------------]]
function a:OnAddOnReady(evt, isInitialLogin, isReloadingUi)
  self:SendMessage(ns:msg('ADDON_READY'), isInitialLogin, isReloadingUi)

  if not isInitialLogin then return end

  C_Timer.After(2, function() ns:ShowNextUnseenAnnouncement() end)
end; a:RegisterEvent('PLAYER_ENTERING_WORLD', 'OnAddOnReady')
