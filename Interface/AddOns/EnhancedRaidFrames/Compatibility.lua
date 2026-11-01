-- Compatibility.lua
-- Small wrappers to smooth over API differences between Classic branches.

ERF_Compat = ERF_Compat or {}

-- Group size helpers (some branches differ)
function ERF_Compat.GetGroupSize()
  if IsInRaid and IsInRaid() then
    return GetNumGroupMembers and GetNumGroupMembers() or (GetNumRaidMembers and GetNumRaidMembers()) or 0
  end
  return GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
end

-- Aura scan wrapper:
-- Returns aura info in a predictable way by using UnitAura if available.
function ERF_Compat.UnitAura(unit, index, filter)
  if UnitAura then
    return UnitAura(unit, index, filter)
  end
  -- Extremely old fallback (unlikely you’ll need this)
  return nil
end
