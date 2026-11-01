# BigDebuffs

## [v68](https://github.com/jordonwow/bigdebuffs/tree/v68) (2026-07-16)
[Full Changelog](https://github.com/jordonwow/bigdebuffs/compare/v67...v68) [Previous Releases](https://github.com/jordonwow/bigdebuffs/releases)

- Update LibDeflate dependency to use GitHub URL with latest tag  
- Remove StaticPopupDialogs from read\_globals and add it to globals  
- Disable mouse click events on BigDebuffs button during OnLoad (Fixes #931)  
- Add import/export for custom spells and overrides (#943)  
    Add a Spells > Import / Export sub-tab that lets players share their setup  
    as a single copy/paste string, serialized with AceSerializer and compressed  
    with LibDeflate (print-encoded, prefixed "!BD:1!" for versioning).  
    The export always includes custom spells, preset category re-categorizations  
    and preset ID replacements; the per-spell visibility/priority/size settings  
    are included only when "Include settings" is enabled. Import merges into the  
    current profile by default (same-ID entries overwritten, everything else  
    kept) or, with "Replace my spells", resets the profile first after a  
    confirmation. Field-level merge avoids wiping the importer's own settings  
    when a shared string only carries a category change.  
    The copy/paste boxes use standalone AceGUI windows rather than inline  
    options edit boxes, which go blank when AceConfigDialog recycles the widget  
    on a sub-tab switch.  