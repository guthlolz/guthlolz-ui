DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[ERF] EarlyCompat loaded|r")

-- EarlyCompat.lua
-- Loads before libs to prevent Classic PTR from erroring on retail-only events.

do
  local f = CreateFrame("Frame")
  local mt = getmetatable(f)
  local idx = mt and mt.__index

  if type(idx) == "table" and type(idx.RegisterEvent) == "function" and not idx.__ERF_EarlyCompatHooked then
    local orig = idx.RegisterEvent

    idx.RegisterEvent = function(self, event, ...)
      if event == "LEARNED_SPELL_IN_TAB" then
        -- Event doesn't exist on this client; ignore registration attempt.
        return
      end
      return orig(self, event, ...)
    end

    idx.__ERF_EarlyCompatHooked = true
  end
end
