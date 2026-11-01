--- @alias LibTraceKit_HexColor-1.0 string|colorRGB @hex color value, i.e. '0056AA', 'EEFFEE'
--- @alias LibTraceKit_ColorFn-1.0 fun(string) : string
--- @alias TraceKit_MultiFunction-1.0 TraceKit-1.0 | fun(...) : void

--- [LibPrettyPrint](https://github.com/kapresoft/wow-addon-LibPrettyPrint/blob/main/README.md)
--- @alias LibTraceKit_Formatter-1.0 fun(...)

--[[-----------------------------------------------------------------------------
Library: LibTraceKit
-------------------------------------------------------------------------------]]
local MAJOR, MINOR = 'LibTraceKit-1.0', 2

--- @class LibTraceKit-1.0
local LibTraceKit = LibStub:NewLibrary(MAJOR, MINOR); if not LibTraceKit then return end

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]

local strupper = strupper or string.upper
local strtrim = strtrim or string.trim

local COLOR_FORMAT_RGB = COLOR_FORMAT_RGB or 'RRGGBB'
local DEFAULT_DELIM = '::'
local DEFAULT_COLOR = '42AFFA'


-- Lazy loaded event trace so that we don't need
-- to have dependency on Blizzard_EventTrace
--- @type EventTrace?
local eventTrace

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]

--- @private
--- @return number @decimal color val
local function ColorValueFromHex(str, index)
  return tonumber(str:sub(index, index + 1), 16) / 255
end

--- @private
--- @param hexColorRGB HexRGB | '565656' | 'efefef'
--- @return colorRGB?
local function ColorFromHexRGB(hexColorRGB)
  if #hexColorRGB == #COLOR_FORMAT_RGB then
    local r, g, b = ColorValueFromHex(hexColorRGB, 1),
      ColorValueFromHex(hexColorRGB, 3), ColorValueFromHex(hexColorRGB, 5)
    return CreateColor(r, g, b, 1)
  end
  return nil
end

--- ### Usage:
--- ```
--- local colorFn = cfn(PURE_BLUE_COLOR)
--- print(colorFn('Hello') -- prints in blue
--- -- OR
--- local colorFn = cfn('565656')
--- print(colorFn('Hello') -- prints in 0x565656 color
--- ```
--- @param colorRGB colorRGB | colorRGBA | LibTraceKit_HexColor-1.0 | '565656' | '33eeaa' | 'A Color object, or the hex RRGGBB color'
--- @return LibTraceKit_ColorFn-1.0
local function cfn(colorRGB)
  --- @type colorRGB?
  local c = type(colorRGB) == 'string' and ColorFromHexRGB(colorRGB) or colorRGB
  assertsafe(
    c and type(c.WrapTextInColorCode) == 'function',
    'Invalid Color <%s>. ColorFormatter:ColorFn(colorRGB): <colorRGB> should be a Color object or a hex string in RRGGBB format, i.e. \'0055ee\'',
    tostring(colorRGB)
  )
  return function (arg) return c:WrapTextInColorCode(tostring(arg)) end
end

--- @return LibTraceKit_Formatter-1.0
local function CreateFormatter()
  return LibPrettyPrint:Formatter({ show_all = true, depth_limit = 1 }) --[[@as LibTraceKit_Formatter-1.0 ]]
end

--- @return EventTrace?
local function GetEventTrace()
  if eventTrace then return eventTrace end
  if not EventTrace then return nil end
  eventTrace = EventTrace
  return eventTrace
end

--- @param namespace string             @The base name of the trace
--- @param tag string                   @An optional tag name
--- @param colorFn LibTraceKit_ColorFn-1.0  @The primary color function
--- @param delim string                 @Delimiter override; defaults to '::', i.e. 'NAMESPACE::TAG'
--- @param ... any
local function TraceKit_TraceFn(namespace, tag, colorFn, delim, ...)
  local evtt = GetEventTrace(); if not (evtt and evtt.LogEvent) then return end
  local n = namespace
  if type(tag) == 'string' then n = ('%s%s%s'):format(n, delim, tag) end
  evtt:LogEvent(colorFn(n), ...)
end

---@param str string
---@return boolean
local function Str_IsBlank(str)
  if str == nil then return true end
  if type(str) ~= "string" then return false end
  return not str:find("%S")
end

--- @param str string
--- @return boolean
local function Str_IsNotBlank(str) return Str_IsBlank(str) ~= true end

--[[-----------------------------------------------------------------------------
TraceKit
-------------------------------------------------------------------------------]]

--- @class TraceKit-1.0
--- @field namespace string
--- @field tag string @An optional tag name
--- @field colorFn LibTraceKit_ColorFn-1.0 @The primary color function
--- @field delim string @Delimiter override; defaults to '::', i.e. 'NAMESPACE::TAG'
local TraceKit = {}
TraceKit.__index = TraceKit
TraceKit.__type = 'TraceKit'

--- @private
--- @param self TraceKit-1.0
TraceKit.__call = function (self, ...) self:LogEvent(...) end

--- @package
--- @param namespace string                                 @The namespace or identifier of the trace message
--- @param tag string?                                      @An optional tag name (Optional)
--- @param hexColor  (LibTraceKit_HexColor-1.0 | colorRGB)? @A hex color value if tag is provided, i.e. '0056AA', 'EEFFEE'; otherwise can be ommitted (Optional)
--- @param delim string?                                    @Delimiter override; defaults to '::', i.e. 'NAMESPACE::TAG' (Optional)
function TraceKit:__Init(namespace, tag, hexColor, delim)
  assertsafe(
    Str_IsNotBlank(namespace),
    'Invalid namespace: <%s>. TraceKit:__Init(namespace): <namespace> should be a non-empty string', tostring(namespace)
  )
  self.namespace = strupper(strtrim(namespace))
  if Str_IsNotBlank(tag) then self.tag = strupper(strtrim(tag)) end
  --- @type LibTraceKit_Formatter-1.0
  self.formatter = LibPrettyPrint:Formatter({ show_all = true, depth_limit = 1 })
  self.colorFn = cfn(hexColor or DEFAULT_COLOR)
  self.delim = Str_IsNotBlank(delim) and delim or DEFAULT_DELIM
end

--- This is a fluid function
--- @param tag string? @tag name
--- @return TraceKit_MultiFunction-1.0, LibTraceKit_Formatter-1.0
function TraceKit:WithTag(tag)
  assertsafe(
    type(tag) == 'string' and #strtrim(tag) > 0,
    'Invalid tag: <%s>. TraceKit:SetTag(tag): <tag> should be a non-empty string.', tostring(tag)
  )
  self.tag = strupper(strtrim(tag))
  return self, self.formatter
end

--- This is a fluid function
--- @return TraceKit_MultiFunction-1.0, LibTraceKit_Formatter-1.0
function TraceKit:WithNoTag()
  self.tag = nil
  return self, self.formatter
end

--- ## Usage
--- ```
--- -- Directly supports a 6-hex RGB color or a colorRGB* object:
--- WithColor('7ACFFB')
--- WithColor(RED_FONT_COLOR)
--- -- For ARGB or RGBA hex strings, build the color first:
--- WithColor(CreateColorFromHexString('ff7ACFFB'))    -- ARGB
--- WithColor(CreateColorFromRGBAHexString('7ACFFBff')) -- RGBA
--- ```
--- Acceptable types:  '00AAEE' or RED_FONT_COLOR, etc..
--- @param hexColor  (LibTraceKit_HexColor-1.0 | colorRGB)? @A hex color value if tag is provided, i.e. '0056AA', 'EEFFEE'; otherwise can be ommitted (Optional)
--- @return TraceKit_MultiFunction-1.0, LibTraceKit_Formatter-1.0
function TraceKit:WithColor(hexColor)
  self.colorFn = cfn(hexColor or DEFAULT_COLOR)
  return self, self.formatter
end

--- This is a fluid function
--- @param delim string? @Delimiter override; defaults to '::', i.e. 'NAMESPACE::TAG'
--- @return TraceKit_MultiFunction-1.0, LibTraceKit_Formatter-1.0
function TraceKit:WithDelimiter(delim)
  assertsafe(
    type(delim) == 'string', 'Invalid delim: <%s>. TraceKit:SetDelimiter(delim): <delim> should be a string.',
    tostring(delim)
  )
  self.delim = delim
  return self, self.formatter
end

--- This is a fluid function
--- @return TraceKit_MultiFunction-1.0, LibTraceKit_Formatter-1.0
function TraceKit:WithUnderscoreDelimiter()
  self.delim = '_'
  return self, self.formatter
end

--- @private
--- @param ... any
function TraceKit:LogEvent(...)
  TraceKit_TraceFn(self.namespace, self.tag, self.colorFn, self.delim, ...)
end

--- ### Usage:
--- ```
--- local colorFn = TraceKit.CreateColorFunction(PURE_BLUE_COLOR)
--- print(colorFn('Hello') -- prints in blue
--- -- OR
--- local colorFn = TraceKit.CreateColorFunction('565656')
--- print(colorFn('Hello') -- prints in 0x565656 color
--- ```
---
--- @param colorRGB colorRGB | colorRGBA | LibTraceKit_HexColor-1.0 | '565656' | 'fc565656' | 'A Color object, or the hex RRGGBB color'
--- @return LibTraceKit_ColorFn-1.0
function TraceKit.CreateColorFunction(colorRGB) return cfn(colorRGB) end

--- An alternative way to construct a TraceKit that returns only a trace function (not TraceKit-1.0)
--- To set delim without tag/hexColor, pass nil for the args you want to skip: CreateTraceFunction('ns', nil, nil, '.')
---
--- @param namespace string                   @The namespace or identifier of the trace message
--- @param tag string?                        @An optional tag name (Optional)
--- @param hexColor LibTraceKit_HexColor-1.0? @A hex color value if tag is provided, i.e. '0056AA', 'EEFFEE'; otherwise can be ommitted (Optional)
--- @param delim string?                      @Delimiter override; defaults to '::', i.e. 'NAMESPACE::TAG' (Optional)
--- @overload fun(namespace: string): TraceKit_MultiFunction-1.0, LibTraceKit_Formatter-1.0
--- @overload fun(namespace: string, tag:string): TraceKit_MultiFunction-1.0, LibTraceKit_Formatter-1.0
--- @overload fun(namespace: string, tag:string, hexColor: LibTraceKit_HexColor-1.0): TraceKit_MultiFunction-1.0, LibTraceKit_Formatter-1.0
--- @return fun(...), LibTraceKit_Formatter-1.0
function LibTraceKit.CreateTraceFunction(namespace, tag, hexColor, delim)
  assertsafe(
    Str_IsNotBlank(namespace),
    'Invalid namespace: <%s>. LibTraceKit.CreateTraceFunction(namespace): <namespace> should be a non-empty string', tostring(namespace)
  )
  local tfn = function(...)
    TraceKit_TraceFn(strupper(namespace),
      Str_IsNotBlank(tag) and strupper(tag) or nil,
      cfn(hexColor or DEFAULT_COLOR),
      delim or DEFAULT_DELIM, ...)
  end
  return tfn, CreateFormatter()
end

--[[-----------------------------------------------------------------------------
LibTraceKit
-------------------------------------------------------------------------------]]

--- ### Usage:
--- ```
--- local t, fmt = LibTraceKit:New('libtracekit', '29FFEF')
--- -- OR
--- local t, fmt = LibTraceKit:New('libtracekit')
---                   :WithTag('Main'):WithUnderscoreDelimiter()
--- -- OR
--- local t, fmt = LibTraceKit:New('libtracekit')
---                   :WithTag('EventHandler')
---                   :WithDelimiter('$')
--- -- OR
--- local t, fmt = LibTraceKit:New('libtracekit', 'EventHandler', ORANGE_THREAT_COLOR, '_')
--- ```
---   
--- @param namespace string                   @The namespace or identifier of the trace message
--- @param tag string?                        @An optional tag name (Optional)
--- @param hexColor LibTraceKit_HexColor-1.0? @A hex color value if tag is provided, i.e. '0056AA', 'EEFFEE'; otherwise can be ommitted (Optional)
--- @param delim string?                      @Delimiter override; defaults to '::', i.e. 'NAMESPACE::TAG' (Optional)
--- @overload fun(namespace: string): TraceKit_MultiFunction-1.0, LibTraceKit_Formatter-1.0
--- @overload fun(namespace: string, tag:string): TraceKit_MultiFunction-1.0, LibTraceKit_Formatter-1.0
--- @overload fun(namespace: string, tag:string, hexColor: LibTraceKit_HexColor-1.0): TraceKit_MultiFunction-1.0, LibTraceKit_Formatter-1.0
--- @return TraceKit_MultiFunction-1.0, LibTraceKit_Formatter-1.0
function LibTraceKit:New(namespace, tag, hexColor, delim)
  assertsafe(type(namespace) == 'string', 'LibTraceKit:New(namespace): <namespace> should be a string.')

  --- @type TraceKit-1.0
  local tk = setmetatable({}, TraceKit)
  tk:__Init(namespace, tag, hexColor, delim)

  return tk, tk.formatter
end

local watcher = CreateFrame('Frame')
watcher:RegisterEvent('ADDON_LOADED')
watcher:SetScript('OnEvent', function (self, event, addonName)
  if addonName == 'Blizzard_EventTrace' then
    GetEventTrace(); self:UnregisterEvent('ADDON_LOADED')
  end
end)
