local _, ns = ...
local oGlowClassic = ns.oGlowClassic

local argcheck = oGlowClassic.argcheck

local defaultColors = {
	quest = { 1, 0.82, 0 },
}

local colorTable = setmetatable(
	{},

	-- We mainly want to handle item quality coloring, so this acts as a fallback.
	-- The bonus of doing this is that we don't really have to make any updates to
	-- the add-on if any new item colors are added. It also caches unlike the old
	-- version.
    {__index = function(self, val)
        if type(val) ~= 'number' then
            return nil
        end

        local r, g, b = C_Item.GetItemQualityColor(val)
--         if not r then
--             r, g, b = 1, 1, 1
--         end

        rawset(self, val, {r, g, b})
        return self[val]
    end}
)

function oGlowClassic:RegisterColor(name, r, g, b)
	argcheck(name, 2, 'string', 'number')
	argcheck(r, 3, 'number')
	argcheck(g, 4, 'number')
	argcheck(b, 5, 'number')

	local color = rawget(colorTable, name)
	if(color) then
		color[1], color[2], color[3] = r, g, b
	else
		color = {r, g, b}
		rawset(colorTable, name, color)
	end

	oGlowClassicDB.Colors[name] = color

	return true
end

function oGlowClassic:ResetColor(name)
	argcheck(name, 2, 'string', 'number')

	oGlowClassicDB.Colors[name] = nil
	colorTable[name] = nil

	if type(name) == 'number' then
		return unpack(colorTable[name])
	end

	local default = defaultColors[name]
	if default then
		self:RegisterColor(name, unpack(default))
		return unpack(default)
	end

	return 1, 1, 1
end

ns.colorTable = colorTable
