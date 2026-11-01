v5.0 (2026-10-23)

- Enabled Phase 4 content after the Burning Crusade Classic Anniversary Zul'Aman release.
- Changed the default/live phase to Phase 4 across TBCA_BIS and AtlasLoot, with a one-time migration for existing profiles.
- Corrected the Shadow Priest BiS weapon enchant from Sunfire to Soulfrost (`27982`).
- Advanced all 19 manifests in the 11-folder BIS package to `v5.0` for TBC Anniversary `2.5.6` (`Interface 20506`).

v4.9 (2026-09-12)

- Added the complete Phase 3 Vindicator pendant family correction, including item `35319` in the Phase 3 neck calculations for affected specs.
- Upgraded all AtlasLoot class/spec colored-gem recommendations for Phase 3-5 while preserving the original Phase 1-2 rare gems and existing meta gems.
- Corrected Rogue agility gem recommendations and the Thick Dawnstone defense-rating description.
- Added `Save Equipped` and `/sgs saveequipped <name>` to TBCA Simple GearSets.
- Added the currently worn item to each selected gear-slot choice list, pinned first and marked `(Equipped)`.
- Advanced all 19 manifests in the 11-folder BIS package to `v4.9` for TBC Anniversary `2.5.6` (`Interface 20506`).

v4.8 (2026-08-25)

- Advanced the 11-folder BIS package from the prior `v4.7` release line to `v4.8` for TBC Anniversary `2.5.6` (`Interface 20506`).
- Moved editable CSVs and offline generators into `ADDONS-DEV-REFERENCES/BIS-addon` so live add-on folders remain shipping sources.
- Added a unified release definition and `SHIPZIP` workflow for exact 11-folder `BIS4.8.zip` builds.
- Retired `ADDONS-FOR-REFERENCE-ONLY` as an active data/context source.
- Excluded the separate Remote module from the active package and cleaned its stale commands from core documentation.
- Split `TBCA_LittleThings` from the BIS package so it remains a separate optional addon.
- Changed the default/live content phase from Phase 2 to Phase 3, synchronized AtlasLoot's initial BiS phase selection, and marked Phase 3 content active in AtlasLoot.
- Added a dedicated one-time Phase 3 saved-settings migration so profiles already touched by an earlier 4.5 draft no longer remain on Phase 2.
- Moved the forced Phase 3 migration to `PLAYER_ENTERING_WORLD` with numeric marker `phase3ForcedMigrationVersion = 1`; it now forces Phase 3 exactly once after SavedVariables are live.

v4.0.0 (2026-03-07)

*   Confirmed packaging and licensing boundaries:
    *   `TBCA_BIS` remains authored by Unforvegan \[H\] DreamScythe and is distributed as All Rights Reserved.
    *   `AtlasLootClassic` and `AtlasLootClassic_*` folders are now a fork that is prepacked with this addon and remain GPL v2 derivatives with upstream attribution retained, contineuos credit to **Lag123**.
*   Added a better EPV-based gear score model that evaluates gear by class, spec, and stat value instead of relying on item level alone.
*   Added a compact inspect gear score panel for self and inspected players, with a separate `/bis debug` mode for detailed slot-by-slot testing.
*   Improved score handling for gems, enchants, current-phase readiness, and spec detection from equipped gear.
*   Improved the UI and general presentation:
    *   cleaner default inspect output
    *   updated options flow under `Esc -> Interface -> AddOns -> TBCA_BIS`
    *   improved minimap and AtlasLoot integration
*   Modernized parts of the addon and AtlasLoot integration to use newer API-safe patterns and simpler runtime lookups.
*   Removed legacy tooltip/config code and unused bundled library baggage no longer needed by the active addon.
*   Updated AtlasLoot BiS presentation with better sorting, clearer score display, phase controls, and gems/enchants support.
*   Fixed inspect refresh behavior so manual inspect works more reliably and no longer depends on other tooltip/inspect addons.

v3.3 (2026-03-05)

- Added a new AtlasLoot `Gems / Enchants / Attachments` page for each supported spec in `AtlasLootClassic_TBCA_BIS`.
- New page includes recommended meta/red/blue/yellow gems plus major gear enchants in one place.
- Added phase-aware generation for the new gems/enchants data so recommendations appear correctly across TBC content phases.
- Added explicit Aldor/Scryers handling for shoulder enchants so both options are shown clearly with faction requirement text.
- Added support for head, shoulder, legs, rings, weapon, cloak, chest, bracer, glove, boot, shield, and other relevant enchant slots where applicable.
- Corrected multiple gems/enchant IDs and normalized generated output for more reliable AtlasLoot display.
- Previous versions did not include this gems/enchants feature at all.

v3.1 (2026-02-26)

- Added Blizzard options registration for `TBCA_BIS` under `Esc -> Options/Interface -> AddOns`.
- Fixed `/bis` so the config window opens on first command (no double command required).
- Added `/bis options` / `/bis menu` to open the Blizzard AddOns options panel directly.
- Updated options button action to open AtlasLoot on the `AtlasLootClassic_TBCA_BIS` module/tab.
- Added `/bis atlas` shortcut to open AtlasLoot directly on the TBCA_BIS tab.
- Removed `AtlasLootClassic_TBCA_BISUX` fallback from the TBCA_BIS AtlasLoot opener path.
- Added safe AtlasLoot selection reset before opening TBCA_BIS tab to avoid stale module/content crashes.
- Distribution note: this package includes a maintained `AtlasLootClassic` GPL v2 fork and a GPL v2 `AtlasLootClassic_TBCA_BIS` integration module, both with upstream attribution retained.
- Packaging note: AtlasLoot can still be installed/updated separately or used from this pack; avoid duplicate/mismatched copies to prevent conflicts.

- Corrected item phase coverage for `21869` (Frozen Shadoweave Shoulders) so Phase 1 now appears where intended (matching boots behavior expectation).
- Added AtlasLoot TBCA_BIS runtime sorting by BiS percentage scores (normal vs hit-capped mode) using shared TBCA_BIS data.
- Added AtlasLoot TBCA_BIS hit-cap status display in header (`[Hit Cap: ON/OFF]`) for quick visibility.
- Added AtlasLoot TBCA_BIS `HC: ON/OFF` toggle button that writes directly to `Unforvegan_BISDB.hitCapped` and refreshes list ordering immediately.
- Positioned the AtlasLoot hit-cap toggle after the search box for cleaner layout.
- Added `TBCA_BIS` as an optional dependency for AtlasLoot TBCA_BIS integration.

v3.0

- Regenerated AtlasLoot BiS tables from the unified source and fixed healer mapping (`Resto` -> `Shaman Restoration`).
- Corrected item phase coverage for `21870` (Shadoweave boots) so it appears across intended phases for Shadow Priest (P1, P2, P3 visibility fix).

v2.9.*

- Reworked BiS tooltip system to use unified CSV-generated data (EPV + HitCap/NoHitCap).
- Added phase-aware filtering with in-game controls (`/bisphase`, UI toggles).
- Fixed tooltip stability so normal bag tooltips are no longer suppressed.
- Updated default behavior: settings window hidden on login/reload; minimap button hidden by default.
- Repositioned BiS minimap button away from default queue/dungeon finder overlap.
- Fixed AtlasLoot module loading by using `AtlasLootClassic_` module naming convention.
