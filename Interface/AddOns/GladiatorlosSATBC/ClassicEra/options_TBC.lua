local GSA = GladiatorlosSA
local gsadb
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale("GladiatorlosSATBC", true) or AceLocale:GetLocale("GladiatorlosSA", true) or {}
if type(L) ~= "table" then L = {} end
local LSM = LibStub("LibSharedMedia-3.0")
local options_created = false -- ***** @


-- Compatibility: GetAddOnMetadata vs C_AddOns.GetAddOnMetadata (TBC-safe)
local function GSA_GetAddOnMetadata(addon, field)
    if type(GetAddOnMetadata) == "function" then
        return GetAddOnMetadata(addon, field)
    end
    if C_AddOns and type(C_AddOns.GetAddOnMetadata) == "function" then
        return C_AddOns.GetAddOnMetadata(addon, field)
    end
    return nil
end

-- Some files in older builds call this as a global
_G.GSA_GetAddOnMetadata = GSA_GetAddOnMetadata


local GSA_OUTPUT = {["MASTER"] = L["Master"],["SFX"] = L["SFX"],["AMBIENCE"] = L["Ambience"],["MUSIC"] = L["Music"],["DIALOG"] = L["Dialog"]}

--[[
function GSA:ShowConfig()
	for i=1,2 do InterfaceOptionsFrame_OpenToCategory(GSA_GetAddOnMetadata("GladiatorlosSATBC", "Title")) end -- ugly fix

end
]]

function GSA:ShowConfig2() -- ***** @
	if options_created == false then
		if (GSA_EXPANSION == L["EXPAC_SL"]) then
			self:OnOptionCreate()
		elseif (GSA_EXPANSION == L["EXPAC_TBC"]) then
			self:OnOptionCreate_TBC()
		elseif (GSA_EXPANSION == L["EXPAC_WLK"]) then
			self:OnOptionCreate_WLK()
		else
			self:OnOptionCreate()
		end
	end
	AceConfigDialog:Open("GladiatorlosSATBC")
end

function GSA:ChangeProfile()
	gsadb = self.db1.profile
	for k,v in GladiatorlosSA:IterateModules() do
		if type(v.ChangeProfile) == 'function' then
			v:ChangeProfile()
		end
	end
end

function GSA:AddOption(name, keyName)
    -- Ensure a root Blizzard Options category exists before adding children (TBC Classic safe)
    -- NOTE: In Classic clients, option creation can run more than once; AddToBlizOptions will error on duplicates.
    local ROOT_APP  = "GladiatorlosSATBC"
    local ROOT_NAME = "GladiatorlosSA TBC"

    _G.GSATBC_BlizRoot = _G.GSATBC_BlizRoot or nil

    if not _G.GSATBC_BlizRoot then
        local ok, panel = pcall(function()
            return AceConfigDialog:AddToBlizOptions(ROOT_APP, ROOT_NAME)
        end)
        if ok and panel then
            _G.GSATBC_BlizRoot = panel
        end
    end

    return AceConfigDialog:AddToBlizOptions(ROOT_APP, name, _G.GSATBC_BlizRoot, keyName)
end

local function setOption(info, value)
	local name = info[#info]
	gsadb[name] = value
	if value then
		PlaySoundFile("Interface\\Addons\\"..gsadb.path_menu.."\\"..name..".ogg",gsadb.output_menu);
	end
	GSA:CanTalkHere()
end

local function getOption(info)
	local name = info[#info]
	return gsadb[name]
end


-- TBC Classic: provide a safe MakeCustomOption implementation.
-- Some upstream builds relied on retail-era helper methods which are missing in TBC.
-- This builds a minimal, functional UI entry for a custom alert and refreshes AceConfig.
if type(GSA.MakeCustomOption) ~= 'function' then
    function GSA:MakeCustomOption(key)
        if not key or not gsadb or type(gsadb.custom) ~= 'table' then return end
        local entry = gsadb.custom[key]
        if type(entry) ~= 'table' then return end
        if not self.options or not self.options.args or not self.options.args.custom or not self.options.args.custom.args then return end

        self.options.args.custom.args[key] = {
            type = 'group',
            inline = true,
            name = key,
            order = (entry.order or 0) + 10,
            args = {
                spellid = {
                    type = 'input',
                    name = L["spellid"] or "Spell ID",
                    width = 'half',
                    get = function() return tostring(entry.spellid or "") end,
                    set = function(_, v)
                        local n = tonumber(v)
                        entry.spellid = n
                    end,
                },
                soundfilepath = {
                    type = 'input',
                    name = L["file path"] or "Custom File Path",
                    width = 'full',
                    get = function() return tostring(entry.soundfilepath or "") end,
                    set = function(_, v)
                        entry.soundfilepath = tostring(v or "")
                    end,
                },
                test = {
                    type = 'execute',
                    name = L["Test"] or "Test",
                    width = 'half',
                    func = function()
                        if entry.soundfilepath and entry.soundfilepath ~= "" then
                            local channel = gsadb.output_menu or "Master"
                            -- Normalize common stored values (e.g. "MASTER") to Classic tokens.
                            if type(channel) == "string" then
                                local up = string.upper(channel)
                                if up == "MASTER" then channel = "Master"
                                elseif up == "SFX" then channel = "SFX"
                                elseif up == "MUSIC" then channel = "Music"
                                elseif up == "AMBIENCE" then channel = "Ambience"
                                elseif up == "DIALOG" then channel = "Dialog" end
                            end
                            PlaySoundFile(entry.soundfilepath, channel)
                        end
                    end,
                },
                remove = {
                    type = 'execute',
                    name = L["Remove"] or "Delete",
                    width = 'half',
                    confirm = true,
                    func = function()
                        gsadb.custom[key] = nil
                        self.options.args.custom.args[key] = nil
                        if AceConfigRegistry and AceConfigRegistry.NotifyChange then
                            AceConfigRegistry:NotifyChange("GladiatorlosSATBC")
                        end
                    end,
                },
            },
        }

        if AceConfigRegistry and AceConfigRegistry.NotifyChange then
            AceConfigRegistry:NotifyChange("GladiatorlosSATBC")
        end
    end
end
local function spellOption(order, spellID, ...)
	local spellname, _, icon = GetSpellInfo(spellID)
	if (spellname ~= nil) then
		return {
			type = 'toggle',
			name = "\124T" .. icon .. ":24\124t" .. spellname,
			desc = function()
				return GetSpellLink(spellID) or ("SpellID: " .. tostring(spellID))
			end, -- https://i.imgur.com/ChzUb.jpg
						order = order,
		}
	else
		GSA.log("spell id: " .. spellID .. " is invalid")
		return {
			type = 'toggle',
			name = "Unknown Spell; ID:" .. spellID,
			order = order,
		}
	end
end


local function listOption(spellList, listType, ...)
	local args = {}
	for k, v in pairs(spellList) do
		local GSA_SpellName = GSA.spellList[listType][v]
		if GSA_SpellName then
			rawset (args, GSA_SpellName, spellOption(k, v))
			GameTooltip:Hide()
		else
		end
	end
	return args
end

function GladiatorlosSA:OnOptionCreate_TBC()
    if self._options_created_tbc or _G.GSATBC_OptionsCreated then return end
    self._options_created_tbc = true
    _G.GSATBC_OptionsCreated = true
	print("Loading TBC")
	gsadb = self.db1.profile
	options_created = true -- ***** @
	self.options = {
		type = "group",
		name = GSA_GetAddOnMetadata("GladiatorlosSATBC", "Title") or "GladiatorlosSA TBC",
		childGroups = "tab", -- modern tabbed layout in AceConfigDialog
		args = {
			general = {
				type = 'group',
				name = L["General"],
				desc = L["General options"],
				set = setOption,
				get = getOption,
				order = 1,
				args = {
					enableArea = {
						type = 'group',
						inline = true,
						name = L["Enable area"],
						order = 1,
						args = {
							all = {
								type = 'toggle',
								name = L["Anywhere"],
								desc = L["Alert works anywhere"],
								order = 10,
							},
							--onlyflagged = {
							--	type = 'toggle',
							--	name = L["OnlyIfPvPFlagged"],
							--	desc = L["OnlyIfPvPFlaggedDesc"],
							--	disabled = function() return not gsadb.field or gsadb.all end,
							--	order = 20,
							--},
							NewLine1 = {
								type= 'description',
								order = 30,
								name= '',
							},
							arena = {
								type = 'toggle',
								name = L["Arena"],
								desc = L["Alert only works in arena"],
								disabled = function() return gsadb.all end,
								order = 40,
							},
							battleground = {
								type = 'toggle',
								name = L["Battleground"],
								desc = L["Alert only works in BG"],
								disabled = function() return gsadb.all end,
								order = 50,
							},
							epicbattleground = {
								type = 'toggle',
								name = L["epicbattleground"],
								desc = L["epicbattlegroundDesc"],
								disabled = function() return gsadb.all end,
								order = 60,
							},
							NewLine2 = {
								type= 'description',
								order = 70,
								name= '',
							},
							field = {
								type = 'toggle',
								name = L["World"],
								desc = L["Alert works anywhere else then anena, BG, dungeon instance"],
								disabled = function() return gsadb.all end,
								order = 80,
							},
						},
					},
					voice = {
						type = 'group',
						inline = true,
						name = L["Voice config"],
						order = 2,
						args = {
							path = {
								type = 'select',
								name = L["Default / Female voice"],
								desc = L["Select the default voice pack of the alert"],
								values = self.GSA_LANGUAGE,
								order = 1,
							},
							volumn = {
								type = 'range',
								max = 1,
								min = 0,
								step = 0.1,
								name = L["Master Volume"],
								desc = L["adjusting the voice volume(the same as adjusting the system master sound volume)"],
								set = function (info, value) SetCVar ("Sound_MasterVolume",tostring (value)) end,
								get = function () return tonumber (GetCVar ("Sound_MasterVolume")) end,
								order = 6,
							},
						},
					},
					advance = {
						type = 'group',
						inline = true,
						name = L["Advance options"],
						order = 3,
						args = {
							smartDisable = {
								type = 'toggle',
								name = L["Smart disable"],
								desc = L["Disable addon for a moment while too many alerts comes"],
								order = 1,
							},
							throttle = {
								type = 'range',
								max = 5,
								min = 0,
								step = 0.1,
								name = L["Throttle"],
								desc = L["The minimum interval of each alert"],
								disabled = function() return not gsadb.smartDisable end,
								order = 2,
							},
							NewLineOutput = {
								type= 'description',
								order = 3,
								name= '',
							},
							outputUnlock = {
								type = 'toggle',
								name = L["Change Output"],
								desc = L["Unlock the output options"],
								order = 8,
								confirm = true,
								confirmText = L["Are you sure?"],
							},
							output_menu = {
								type = 'select',
								name = L["Output"],
								desc = L["Select the default output"],
								values = GSA_OUTPUT,
								order = 10,
								disabled = function() return not gsadb.outputUnlock end,
							},
						},
					},
				},
			},
			spells = {
				type = 'group',
				name = L["Abilities"],
				desc = L["Abilities options"],
				set = setOption,
				get = getOption,
				childGroups = "tab",
				order = -2,
				args = {
				menu_voice = {
						type = 'group',
						inline = true,
						name = L["Voice menu config"], 
						order = -3,
						args = {
							path_menu = {
								type = 'select',
								name = L["Choose a test voice pack"],
								desc = L["Select the menu voice pack alert"], 
								values = self.GSA_LANGUAGE,
								order = 1,
							},
						},
				},
				spellGeneral = {
						type = 'group',
						name = L["Disable options"],
						desc = L["Disable abilities by type"],
						inline = true,
						order = -2,
						args = {
							aruaApplied = {
								type = 'toggle',
								name = L["Disable Buff Applied"],
								desc = L["Check this will disable alert for buff applied to hostile targets"],
								order = 1,
							},
							aruaRemoved = {
								type = 'toggle',
								name = L["Disable Buff Down"],
								desc = L["Check this will disable alert for buff removed from hostile targets"],
								order = 2,
							},
							castStart = {
								type = 'toggle',
								name = L["Disable Spell Casting"],
								desc = L["Chech this will disable alert for spell being casted to friendly targets"],
								order = 3,
							},
							castSuccess = {
								type = 'toggle',
								name = L["Disable special abilities"],
								desc = L["Check this will disable alert for instant-cast important abilities"],
								order = 4,
							},
							interrupt = {
								type = 'toggle',
								name = L["Disable friendly interrupt"],
								desc = L["Check this will disable alert for successfully-landed friendly interrupting abilities"],
								order = 6,
							},
							interruptedfriendly = {
								type = 'toggle',
								name = L["FriendlyInterrupted"],
								desc = L["FriendlyInterruptedDesc"],
								order = 7,
							},
						},
					},
					spellAuraApplied = {
						type = 'group',
						--inline = true,
						name = L["Buff Applied"],
						disabled = function() return gsadb.aruaApplied end,
						order = 1,
						args = {
							aonlyTF = {	-- AuraApplied
								type = 'toggle',
								name = L["Target and Focus Only"],
								desc = L["Alert works only when your current target or focus gains the buff effect or use the ability"],
								order = 10,
							},
							drinking = { -- AuraApplied 
								type = 'toggle',
								name = L["Alert Drinking"],
								desc = L["In arena, alert when enemy is drinking"],
								order = 20,
							},
							generalaura = { --AuraApplied
								type = 'group',
								inline = true,
								name = L["General Abilities"],
								order = 30,					      		
								args = listOption({5530,195901,214027,34709,44055},"auraApplied"),
							},

							dispelkickback = { -- AuraApplied
								type = 'group',
								inline = true,
								name = L["DispelKickback"],
								order = 40,
								args = listOption({87204,196364},"auraApplied"),
							},
							druid = { -- AuraApplied
								type = 'group',
								inline = true,
								name = L["Druid"],
								order = 70,
								args = listOption({5229,2893,29166,22812,9846,26999,27009,27006,17116},"auraApplied"),
							},
							hunter = { -- AuraApplied
								type = 'group',
								inline = true,
								name = L["Hunter"],
								order = 80,
								args = listOption({3045,19577,19263,19574,14311},"auraApplied"),
							},
							mage = { -- AuraApplied
								type = 'group',
								inline = true,
								name = L["Mage"],
								order = 90,
								args = listOption({33946,33944,27128,32796,27131,12043,12042,11129,12472,33405,12355},"auraApplied"),
							},
							paladin = { -- AuraApplied
								type = 'group',
								inline = true,
								name = L["Paladin"],
								order = 110,
								args = listOption({1044,5573,10278,31895,1020,27158,31892,31801,27155,27166,27160,31884,27148,20216,20375,20170,31842},"auraApplied"),
							},
							priest	= { -- AuraApplied
								type = 'group',
								inline = true,
								name = L["Priest"],
								order = 120,
								args = listOption({2651,6346,25441,33206,10060,14751,15286,552},"auraApplied"),
							},
							rogue = { -- AuraApplied
								type = 'group',
								inline = true,
								name = L["Rogue"],
								order = 130,
								args = listOption({26669,31224,14177,13750,1833,11297,26884},"auraApplied"),
							},
							shaman	= { -- AuraApplied
								type = 'group',
								inline = true,
								name = L["Shaman"],
								order = 140,
								args = listOption({16166,30823,16188},"auraApplied"),
							},
							warlock	= { -- AuraApplied
								type = 'group',
								inline = true,
								name = L["Warlock"],
								order = 150,
								args = listOption({132,28610,18288},"auraApplied"),
							},
							warrior	= { -- AuraApplied
								type = 'group',
								inline = true,
								name = L["Warrior"],
								order = 160,
								args = listOption({2457,71,2458,2687,871,18499,1719,23920,12292,12975},"auraApplied"),
							},
						},
					},
					spellAuraRemoved = {
						type = 'group',
						--inline = true,
						name = L["Buff Down"],
						disabled = function() return gsadb.aruaRemoved end,
						order = 2,
						args = {
							ronlyTF = { -- AuraRemoved
								type = 'toggle',
								name = L["Target and Focus Only"],
								desc = L["Alert works only when your current target or focus gains the buff effect or use the ability"],
								order = 10,
							},
							generalauradown = { --AuraRemoved
								type = 'group',
								inline = true,
								name = L["General Abilities"],
								order = 30,
								args = listOption({44055},"auraRemoved"),
							},
							druid = { -- AuraRemoved
								type = 'group',
								inline = true,
								name = L["Druid"],
								order = 60,
								args = listOption({29166},"auraRemoved"),
							},
							hunter = { -- AuraRemoved
								type = 'group',
								inline = true,
								name = L["Hunter"],
								order = 70,
								args = listOption({19263},"auraRemoved"),
							},
							mage = { -- AuraRemoved
								type = 'group',
								inline = true,
								name = L["Mage"],
								order = 80,
								args = listOption({12042,11129,12472},"auraRemoved"),
							},
							paladin = { -- AuraRemoved
								type = 'group',
								inline = true,
								name = L["Paladin"],
								order = 100,
								args = listOption({25771,5573,10278,1020,27148,20216},"auraRemoved"),
							},
							priest	= { -- AuraRemoved
								type = 'group',
								inline = true,
								name = L["Priest"],
								order = 110,
								args = listOption({2651,6346,25441,15286,33206,10060,14751},"auraRemoved"),
							},
							rogue = { -- AuraRemoved
								type = 'group',
								inline = true,
								name = L["Rogue"],
								order = 120,
								args = listOption({26669,31224},"auraRemoved"),
							},
							shaman	= { -- AuraRemoved
								type = 'group',
								inline = true,
								name = L["Shaman"],
								order = 130,
								args = listOption({30823},"auraRemoved"),
							},
--[[							warlock = { -- AuraRemoved
								type = 'group',
								inline = true,
								name = L["Warlock"],
								order = 140,
								args = listOption({},"auraRemoved"),
							},]]
							warrior	= { -- AuraRemoved
								type = 'group',
								inline = true,
								name = L["Warrior"],
								order = 150,
								args = listOption({871,1719,23920,12292,12975},"auraRemoved"),
							},
						},
					},
					spellCastStart = {
						type = 'group',
						--inline = true,
						name = L["Spell Casting"],
						disabled = function() return gsadb.castStart end,
						order = 2,
						args = {
							conlyTF = { -- CastStart
								type = 'toggle',
								name = L["Target and Focus Only"],
								desc = L["Alert works only when your current target or focus gains the buff effect or use the ability"],
								order = 1,
							},
							resurrection = { -- CastStart
								type = 'toggle',
								name = L["Resurrection"],
								desc = L["Resurrection_Desc"],
								order = 20,
							},
--[[							bigHeal = { -- CastStart
								type = 'toggle',
								name = L["BigHeal"],
								desc = L["BigHeal_Desc"],
								order = 30,
							},]]
							druid = { -- CastStart
								type = 'group',
								inline = true,
								name = L["Druid"],
								order = 60,
								args = listOption({2637,18658,26989,33786},"castStart"),
							},
							hunter = { -- CastStart
								type = 'group',
								inline = true,
								name = L["Hunter"],
								order = 70,
								args = listOption({27065,982,14327},"castStart"),
							},
							mage = { -- CastStart
								type = 'group',
								inline = true,
								name = L["Mage"],
								order = 80,
								args = listOption({12826,12051},"castStart"),
							},
							paladin = { -- CastStart
								type = 'group',
								inline = true,
								name = L["Paladin"],
								order = 100,
								args = listOption({10326},"castStart"),
							},
							priest	= { -- CastStart
								type = 'group',
								inline = true,
								name = L["Priest"],
								order = 110,
								args = listOption({10912,25380,32375},"castStart"),
							},
							--rogue = { -- CastStart
							--	type = 'group',
							--	inline = true,
							--	name = L["Rogue"],
							--	order = 120,
							--	args = listOption({},"castStart"),
							--},
--[[							shaman	= { -- CastStart
								type = 'group',
								inline = true,
								name = L["Shaman"],
								order = 130,
								args = listOption({},"castStart"),
							},]]
							warlock	= { -- CastStart
								type = 'group',
								inline = true,
								name = L["Warlock"],
								order = 140,
								args = listOption({30146,1122,6215,17928,30405,18647,30414,29893,27220,30908,30545},"castStart"),
							},
--[[							warrior = { -- CastStart
								type = 'group',
								inline = true,
								name = L["Warrior"],
								order = 150,
								args = listOption({},"castStart"),
							},]]
						},
					},
					spellCastSuccess = {
						type = 'group',
						--inline = true,
						name = L["Special Abilities"],
						disabled = function() return gsadb.castSuccess end,
						order = 3,
						args = {
							sonlyTF = { -- CastSuccess
								type = 'toggle',
								name = L["Target and Focus Only"],
								desc = L["Alert works only when your current target or focus gains the buff effect or use the ability"],
								order = 10,
							},
							class = { -- CastSuccess
								type = 'toggle',
								name = L["PvP Trinketed Class"],
								desc = L["Also announce class name with trinket alert when hostile targets use PvP trinket in arena"],
								--disabled = function() return not gsadb.trinket end,
								order = 13,
							},
							success = { -- CastSuccess
								type = 'toggle',
								name = L["CastingSuccess"],
								desc = L["CastingSuccess_Desc"],
								--disabled = function() return gsadb.castStart end,
								order = 15,
							},
							connected = { -- CastSuccess
								type = 'toggle',
								name = L["Connected"],
								desc = L["Connected_Desc"],
								--disabled = function() return gsadb.castStart end,
								order = 17,
							},

							tbcAnniversaryRacials = { -- CastSuccess
								type = 'group',
								inline = true,
								name = "TBC Anniversary Racials",
								order = 28,
								args = listOption({20549,7744,20594,28730,25046}, "castSuccess"),
							},

--[[							cure = { -- CastSuccess
								type = 'toggle',
								name = L["DPSDispel"],
								desc = L["DPSDispel_Desc"],
								order = 20,
							},]]
--[[							dispel = { -- CastSuccess
								type = 'toggle',
								name = L["HealerDispel"],
								desc = L["HealerDispel_Desc"],
								order = 24,
							},]]
--[[							purge = { -- CastSuccess
								type = 'toggle',
								name = L["Purge"],
								desc = L["PurgeDesc"],
								order = 26,
							},]]
--[[							general = { -- CastSuccess
								type = 'group',
								inline = true,
								name = L["General Abilities"],
								order = 30,
								args = listOption({},"castSuccess"),
							},]]
--[[							enemyInterrupts = { -- CastSuccess
								type = 'group',
								inline = true,
								name = L["EnemyInterrupts"],
								order = 35,
								args = listOption({},"castSuccess"),
							},]]
							druid = { -- CastSuccess
								type = 'group',
								inline = true,
								name = L["Druid"],
								order = 70,
								args = listOption({8946,2782,8983,9913,33357,26993,33831,26983,18562},"castSuccess"),
							},
							hunter = { -- CastSuccess
								type = 'group',
								inline = true,
								name = L["Hunter"],
								order = 80,
								args = listOption({5116,1543,14325,14311,34490,23989,27068,19503,27019},"castSuccess"),
							},
							mage = { -- CastSuccess
								type = 'group',
								inline = true,
								name = L["Mage"],
								order = 90,
								args = listOption({475,1953,2139,45438,27088,66,30449,11113,11958,31687},"castSuccess"),
							},
							paladin = { -- CastSuccess
								type = 'group',
								inline = true,
								name = L["Paladin"],
								order = 110,
								args = listOption({20271,1152,4987,10308,27154,33072,20066},"castSuccess"),
							},
							priest	= { -- CastSuccess
								type = 'group',
								inline = true,
								name = L["Priest"],
								order = 120,
								args = listOption({32548,528,988,10890,34433,25467,44047,32996,15487},"castSuccess"),
							},
							rogue = { -- CastSuccess
								type = 'group',
								inline = true,
								name = L["Rogue"],
								order = 130,
								args = listOption({2094,8643,8696,11305,1787,26889,38764,38768,14278,14185,36554},"castSuccess"),
							},
							shaman	= { -- CastSuccess
								type = 'group',
								inline = true,
								name = L["Shaman"],
								order = 140,
								args = listOption({2484,526,8143,2870,8166,8177,8012,25454,8170,2062,2894,2825,16190},"castSuccess"),
							},
--[[							shamanTotems	= { -- CastSuccess
								type = 'group',
								inline = true,
								name = L["ShamanTotems"],
								order = 141,
								args = listOption({},"castSuccess"),
							},]]
							warlock = { -- CastSuccess
								type = 'group',
								inline = true,
								name = L["Warlock"],
								order = 150,
								args = listOption({27223},"castSuccess"),
							},
							warrior	= { -- CastSuccess
								type = 'group',
								inline = true,
								name = L["Warrior"],
								order = 160,
								args = listOption({676,5246,6554,29704,11578,25275,3411,12328,12809},"castSuccess"),
							},
						},
					},
				},
			},
			custom = {
				type = 'group',
				name = L["Custom"],
				desc = L["Custom Spell"],
				--set = function(info, value) local name = info[#info] gsadb.custom[name] = value end,
				--get = function(info) local name = info[#info]	return gsadb.custom[name] end,
				order = 4,
				args = {
					newalert = {
						type = 'execute',
						name = L["New Sound Alert"],
						desc = (rawget(L, "Create a new custom sound alert entry.") or "Create a new custom sound alert entry."),
						order = -1,
						func = function()
							-- Ensure table exists
							if type(gsadb.custom) ~= "table" then gsadb.custom = {} end

							-- Pick a unique name each time so the button never locks itself
							local baseName = L["New Sound Alert"]
							local name = baseName
							local n = 1
							while gsadb.custom[name] do
								n = n + 1
								name = string.format("%s (%d)", baseName, n)
							end

							gsadb.custom[name] = {
								name = name,
								soundfilepath = "Interface\\AddOns\\GladiatorlosSATBC\\Voice_Custom\\Will-Demo.ogg",
								sourceuidfilter = "any",
								destuidfilter = "any",
								eventtype = {
									SPELL_CAST_SUCCESS = true,
									SPELL_CAST_START = false,
									SPELL_AURA_APPLIED = false,
									SPELL_AURA_REMOVED = false,
									SPELL_INTERRUPT = false,
								},
								sourcetypefilter = COMBATLOG_FILTER_EVERYTHING,
								desttypefilter = COMBATLOG_FILTER_EVERYTHING,
								order = 0,
							}

							-- Build the options UI entry if supported
							if type(self.MakeCustomOption) == "function" then
								self:MakeCustomOption(name)
							end
						end,
						disabled = function() return false end,
												},
										},
								},
							},
	}
	if gsadb and type(gsadb.custom)=='table' and type(self.MakeCustomOption)=='function' then
		for k in pairs(gsadb.custom) do
			self:MakeCustomOption(k)
		end
	end
	-- Add Profiles tab inside the same panel (modern layout)
	self.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db1)
	self.options.args.profiles.name = L["Profiles"] or "Profiles"
	self.options.args.profiles.order = 99

	AceConfig:RegisterOptionsTable("GladiatorlosSATBC", self.options)

	-- Register ONE Blizzard Options panel only (no child categories).
	-- This avoids Classic-era parent-category and duplicate-registration errors.
	if not _G.GSATBC_BlizRoot then
		local ok, panel = pcall(function()
			return AceConfigDialog:AddToBlizOptions("GladiatorlosSATBC", "GladiatorlosSA TBC")
		end)
		if ok and panel then
			_G.GSATBC_BlizRoot = panel
		end
	end

	options_created = true
	_G.GSATBC_OptionsCreated = true
end