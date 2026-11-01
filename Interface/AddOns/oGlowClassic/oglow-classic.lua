local title, ns = ...
local oGlowClassic = ns.oGlowClassic

local _VERSION = C_AddOns.GetAddOnMetadata("oGlowClassic", "Version")

local argcheck = oGlowClassic.argcheck

local print = function(...) print("|cff33ff99oGlowClassic:|r ", ...) end
local error = function(...) print("|cffff0000Error:|r "..string.format(...)) end

local pipesTable = ns.pipesTable
local filtersTable = ns.filtersTable
local displaysTable = ns.displaysTable

local numFilters = 0

local optionCallbacks = {}
local activeFilters = ns.activeFilters

local upgradePath = {
	[0] = function(db)
		db.FilterSettings = {}
		db.Colors = {}
		db.version = 1
	end,
	[1] = function(db)
		db.EnabledPipes = db.EnabledPipes or {}
		db.EnabledFilters = db.EnabledFilters or {}

		db.version = 2
	end
}

local upgradeDB = function(db)
	local version = db.version
	if(upgradePath[version]) then
		repeat
			upgradePath[version](db)
			version = version + 1
		until not upgradePath[version]
	end
end

local ADDON_LOADED = function(self, event, addon)
	if(addon == 'oGlowClassic') then
		if(not oGlowClassicDB) then
			oGlowClassicDB = {
				version = 2,
				EnabledPipes = {},
				EnabledFilters = {},

				FilterSettings = {},
				Colors = {},
			}

			for pipe in next, pipesTable do
				self:EnablePipe(pipe)

				for filter in next, filtersTable do
					self:RegisterFilterOnPipe(pipe, filter)
				end
			end
		else
			upgradeDB(oGlowClassicDB)

			for name, color in next, oGlowClassicDB.Colors do
				oGlowClassic:RegisterColor(name, unpack(color))
			end

			for pipe in next, oGlowClassicDB.EnabledPipes do
				self:EnablePipe(pipe)

				for filter, enabledPipes in next, oGlowClassicDB.EnabledFilters do
					if(enabledPipes[pipe]) then
						self:RegisterFilterOnPipe(pipe, filter)
						break
					end
				end
			end
		end

		if not oGlowClassicDB.Colors.quest then
			oGlowClassic:RegisterColor('quest', 1, 0.82, 0)
		end

		self:CallOptionCallbacks()

        print("v" .. _VERSION .. " loaded.")
	end
end

--[[ General API ]]

function oGlowClassic:CallFilters(pipe, frame, ...)
	argcheck(pipe, 2, 'string')
	argcheck(frame, 3, 'string')

	if(not pipesTable[pipe]) then return nil, 'Pipe does not exist.' end

	local display = frame
	local targetFrame = select(1, ...)
	if not targetFrame then
		return nil, 'Frame is required.'
	end

	-- Store last call for async filters to re-run later.
	do
		targetFrame.oGlowClassicLastCall = {
			pipe = pipe,
			display = display,
			args = { select(2, ...) },
		}
	end

	local ref = activeFilters[pipe] and activeFilters[pipe][display]
	if ref then
		if(not displaysTable[display]) then return nil, 'Display does not exist.' end

		for i=1,#ref do
			local func = ref[i][2]

			-- drop out of the loop if we actually do something nifty on a frame.
			if(displaysTable[display](targetFrame, func(targetFrame, select(2, ...)))) then break end
		end
	end
end

function oGlowClassic:RefreshFrame(frame)
	if not frame then
		return nil, "Frame is required."
	end

	local last = frame.oGlowClassicLastCall
	if not last or not last.pipe or not last.display then
		return nil, "No stored call."
	end

	if last.args and type(last.args) == "table" then
		local _unpack = unpack or table.unpack
		return self:CallFilters(last.pipe, last.display, frame, _unpack(last.args))
	end

	return self:CallFilters(last.pipe, last.display, frame)
end

function oGlowClassic:RegisterOptionCallback(func)
	argcheck(func, 2, 'function')

	table.insert(optionCallbacks, func)
end

function oGlowClassic:CallOptionCallbacks()
	for _, func in next, optionCallbacks do
		func(oGlowClassicDB)
	end
end

oGlowClassic:RegisterEvent('ADDON_LOADED', ADDON_LOADED)

oGlowClassic.argcheck = argcheck

oGlowClassic.version = _VERSION
_G.oGlowClassic = oGlowClassic
