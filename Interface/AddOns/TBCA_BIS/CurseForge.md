# TBCA_BIS

Best-in-Slot scoring for TBC Classic Anniversary: tooltip integration, EPV Gear Score inspect panel, and AtlasLoot BiS browsing.

---

## What It Does

**BiS Tooltip**  
Hover any item and see its BiS rank, EPV score percentage, and which spec it belongs to for the active phase. Works on items in bags, on the ground, in the AH, and in chat links. Hit-cap and non-hit-cap values are shown according to your current mode.

**EPV Gear Score Panel**  
Open your Character frame or inspect another player and a score panel appears alongside it automatically. It shows:
- Player name and detected spec
- Overall EPV Gearscore (0-100%) across all 17 equipment slots
- Current-phase readiness label
- Readiness color band: gray -> green -> blue -> purple -> orange
- Gem and enchant bonuses from item-link detection
- A compact default display for shipping
- An optional detailed debug view via `/bis debug`

**AtlasLoot BiS Browser**  
Browse per-spec BiS lists inside AtlasLoot. Each item shows its BiS score badge directly on the button. Lists sort by score automatically. Hit-cap toggle and phase indicator are exposed directly in the AtlasLoot UI.

Each spec also includes a Gems / Enchants / Attachments page with recommended gems, major enchants, and faction-dependent options such as Aldor vs Scryers shoulder enchants.

---

## Phase System

Phases 1-5 map to TBC content tiers. Set your phase in the TBCA_BIS options panel or with `/bisphase 1` through `/bisphase 5`. All scoring, tooltips, and AtlasLoot lists filter to the selected phase. Items from earlier phases remain included when they are still BiS.

---

## Options

Open with `/bis` or `Esc -> Interface -> AddOns -> TBCA_BIS`.

- Phase selector (P1-P5 buttons)
- Hit-cap toggle
- Percent display toggle
- Minimap button show/hide
- Inspect debug mode toggle via slash command

---

## Slash Commands

| Command | Action |
|---|---|
| `/bis` | Open TBCA_BIS options panel |
| `/bis debug` | Toggle inspect debug mode |
| `/bis debug on` / `/bis debug off` | Force inspect debug mode on or off |
| `/bis atlas` | Open AtlasLoot on the BiS tab |
| `/bis on` / `/bis off` | Show or hide the minimap button |
| `/bisphase 1-5` | Set active phase |
| `/bishitcap` | Toggle hit-cap mode |
| `/bispercent` | Toggle percent display |
| `/bisstatus` | Print current settings to chat |

---

## Scoring Model

This addon uses an EPV-based gear model built around class, spec, and item stats in relation to that spec's BiS path for the selected TBC phase.

Unlike many other gearscore systems, this is not a simple item-level score. Item level alone can overrate gear that is wrong for the class, wrong for the spec, or wearing a high-level item that makes little practical sense for the role. This model is intended to avoid that by weighting gear in context.

The score is best used as a gear snapshot, not as a final judgment on the player.

Important:
- Do not treat this score as gospel.
- Skill, rotation, positioning, consumables, buffs, raid composition, and class utility are not included.
- A good player with a 50% score can still perform very well.
- A higher score only means the character is closer to current-phase gear targets, not that they will always play better.

---

## Packaging And License Note

`TBCA_BIS` itself is authored by Unforvegan [H] DreamScythe and distributed as **All Rights Reserved**.

This package also includes:
- a maintained `AtlasLootClassic` fork
- the `AtlasLootClassic_TBCA_BIS` integration module

Those AtlasLoot-derived folders remain **GPL v2** works with upstream attribution retained. They should not be relabeled as proprietary or all-rights-reserved just because they are bundled with `TBCA_BIS`.

If you install AtlasLoot separately, avoid duplicate or mismatched AtlasLoot copies at the same time.

---

## License

- `TBCA_BIS`: All Rights Reserved - `TBCA_BIS/LICENSE`
- `AtlasLootClassic`: GPL v2 - `AtlasLootClassic/LICENSE`
- `AtlasLootClassic_TBCA_BIS`: GPL v2 - `AtlasLootClassic_TBCA_BIS/LICENSE`
