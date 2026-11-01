# Unforvegan_BIS

Tooltip extension for BiS data (TBC Classic Anniversary build), driven by a precomputed CSV export converted to a Lua table.

## Features
- O(1) lookup by `ItemID`
- Phase-aware display (filters to selected `maxPhase`)
- Phase 3 default shared with the AtlasLoot BiS selector
- Hit-capped toggle
- Percentage toggle
- Minimap button + small config window
- Saved-list tracking plus ThatsMyBIS-style import/export
- Slash commands for fast changes

## Files
- `Data/BiSData.lua`: generated from CSV (do not edit by hand)
- `tools/csv_to_lua.py`: offline converter
- `ADDONS-DEV-REFERENCES/BIS-addon/data/`: canonical source CSVs

## Build

Offline sources and generators live in `ADDONS-DEV-REFERENCES/BIS-addon`.

Warning: Retained 4.3 item/talent CSVs do not fully reproduce the current 4.9 runtime data. Preserve the shipped Lua baseline until those sources are reconciled. See `BIS-addon_2026-08-25_Context.md`.

## Settings
- Config window: `/bis`
- Interface AddOns panel: `Esc -> Interface -> AddOns -> TBCA_BIS` or `/bis options`
- Minimap button: `/bis on` (show), `/bis off` (hide)
- Max Phase: dropdown in the window or `/bisphase 1` to `/bisphase 5`
- HitCapped: checkbox or `/bishitcap` (`on|off`)
- Show Percent: checkbox or `/bispercent` (`on|off`)
- Status: `/bisstatus`

## Slash Commands
- `/bis` toggle config window
- `/bis options` or `/bis menu` open Interface AddOns panel
- `/bis on` show minimap button
- `/bis off` hide minimap button
- `/bisphase 1` to `/bisphase 5`
- `/bishitcap` or `/bishitcap on|off`
- `/bispercent` or `/bispercent on|off`
- `/bisstatus`
- `/bistracker equipped` or AtlasLoot Lists menu -> `Export Current Equipped` exports currently worn gear as ThatsMyBIS-style JSON

## Notes
- WoW cannot read CSV at runtime; the Lua data file must be generated offline.
- The displayed rows are filtered to `GamePhase == maxPhase`.
