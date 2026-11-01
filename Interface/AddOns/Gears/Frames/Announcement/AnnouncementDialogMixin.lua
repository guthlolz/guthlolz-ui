--- @type Gears_Namespace
local ns = select(2, ...)

--[[-------------------------------------------------------------------
Blizzard Vars
---------------------------------------------------------------------]]
local BACKDROP_TOAST_12_12 = BACKDROP_TOAST_12_12

--[[-------------------------------------------------------------------
Local Vars
---------------------------------------------------------------------]]
--- @type table<string, AnnouncementDef>
local registry = {}
--- @type string[] @Registered dbKeys, in registration order
local registrationOrder = {}

--- Resolves `field` for the client's current locale, falling back to the
--- unsuffixed (enUS) value when no `field_<locale>` override is registered.
--- @param def AnnouncementDef
--- @param field 'title'|'content'
--- @return string
local function ResolveLocalized(def, field) return def[field .. '_' .. GetLocale()] or def[field] end

--[[-------------------------------------------------------------------
Types
---------------------------------------------------------------------]]
--- Self-contained, per-locale announcement content. `title`/`content` are the
--- default (English) text, used as a fallback. A locale-specific override is
--- provided by adding `title_<locale>`/`content_<locale>` fields, e.g.
--- `title_deDE`, `content_deDE` -- see `Announcements/ConsoleCommands.lua`.
--- @class AnnouncementDef
--- @field dbKey string @Unique key under global.announcementsShown; shown at most once per key
--- @field title string @Default/fallback title (enUS)
--- @field content string @Default/fallback content (enUS); may span multiple lines
--- @field width number? @Optional; defaults to the template's width (Gears_AnnouncementDialogTemplate) when omitted
--- @field height number? @Optional; defaults to the template's height when omitted

--[[-------------------------------------------------------------------
Mixin
---------------------------------------------------------------------]]
--- @class AnnouncementScrollChild : Frame
--- @field Body FontString

--- @class AnnouncementDialogFrame : Frame, BackdropTemplate
--- @field Title FontString
--- @field ScrollFrame ScrollFrame
--- @field OkButton Button
Gears_AnnouncementDialogMixin = {}
local o = Gears_AnnouncementDialogMixin

function o:OnLoad()
  BackdropTemplateMixin.OnBackdropLoaded(self)
  self:SetBackdrop(BACKDROP_TOAST_12_12)

  -- set scrollChild here to enable scrolling
  local scrollFrame = self.ScrollFrame
  scrollFrame:SetScrollChild(scrollFrame.ScrollChild)
end

-- Horizontal/vertical margin between the dialog's outer size and the
-- scroll viewport's size, as set on Gears_AnnouncementDialogTemplate.
local SCROLL_MARGIN_X = 60 -- 440 (dialog) - 380 (viewport)
local SCROLL_MARGIN_Y = 100 -- 280 (dialog) - 180 (viewport)

--- @param def AnnouncementDef
function o:Configure(def)
  self.Title:SetText(('%s: %s'):format(ns.addon, ResolveLocalized(def, 'title')))

  if def.width or def.height then
    local width = def.width or self:GetWidth()
    local height = def.height or self:GetHeight()
    self:SetSize(width, height)
    self.ScrollFrame:SetSize(width - SCROLL_MARGIN_X, height - SCROLL_MARGIN_Y)
  end

  --- @type AnnouncementScrollChild
  local scrollChild = self.ScrollFrame.ScrollChild
  -- Body's width tracks scrollChild via its TOPLEFT/TOPRIGHT anchors; no
  -- explicit width needed on Body itself.
  scrollChild:SetWidth(self.ScrollFrame:GetWidth())
  local body = scrollChild.Body
  local fontFile, fontSize, fontFlags = Gears_ConsoleMono:GetFont()
  body:SetFont(fontFile, fontSize, fontFlags)
  body:SetText(ResolveLocalized(def, 'content'))

  -- Size the scroll child to the wrapped text height so the scrollbar
  -- (auto-shown/hidden by UIPanelScrollFrameTemplate) only appears when needed.
  local viewportHeight = self.ScrollFrame:GetHeight()
  local contentHeight = math.max(body:GetStringHeight(), viewportHeight)
  scrollChild:SetHeight(contentHeight)
end

function o:OnClickOk() self:Hide() end

--- @param def AnnouncementDef
local function ShowDialog(def)
  --- @type AnnouncementDialogFrame
  local frame = CreateFrame('Frame', nil, UIParent, 'Gears_AnnouncementDialogTemplate')
  frame:Configure(def)
  frame:Show()
end

--[[-------------------------------------------------------------------
Namespace API
---------------------------------------------------------------------]]
--- Registers an announcement definition. Does not show it; the dialog is
--- shown when `ns:ShowNextUnseenAnnouncement()` picks it (first-registered,
--- still-unseen wins) or when explicitly requested via
--- `ns:ShowAnnouncementByKey(dbKey)`.
--- @param def AnnouncementDef
function ns:RegisterAnnouncement(def)
  assert(
    type(def) == 'table' and type(def.dbKey) == 'string',
    'RegisterAnnouncement(def): {def.dbKey} is required'
  )
  if not registry[def.dbKey] then registrationOrder[#registrationOrder + 1] = def.dbKey end
  registry[def.dbKey] = def
end

--- Shows a one-time announcement dialog by its registered `dbKey`.
--- A no-op if that key has already been shown once for this account,
--- or if no announcement was registered under that key.
--- @param dbKey string
function ns:ShowAnnouncementByKey(dbKey)
  local def = registry[dbKey]
  if not def then return end

  local shown = ns:g().announcementsShown
  if shown[dbKey] then return end
  shown[dbKey] = true

  ShowDialog(def)
end

--- Shows at most one announcement dialog: the first-registered announcement
--- (by `ns:RegisterAnnouncement` call order) that hasn't been shown yet for
--- this account. A no-op if every registered announcement has already been
--- shown. Any remaining unseen announcements are picked up naturally on a
--- future call (e.g. the player's next login) -- callers never need to name
--- a specific `dbKey` or track which announcements still need showing.
function ns:ShowNextUnseenAnnouncement()
  local shown = ns:g().announcementsShown
  for _, dbKey in ipairs(registrationOrder) do
    if not shown[dbKey] then
      shown[dbKey] = true
      ShowDialog(registry[dbKey])
      return
    end
  end
end
