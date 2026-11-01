local _, addonTable = ...

addonTable.spells = {}
local function spells(textureId, enchantIds)
    for _, v in ipairs(enchantIds) do
        addonTable.spells[v] = textureId
    end
end

-- see https://wago.tools/db2/SpellItemEnchantment?build=1.15.1.53623 to find the enchantIds

---Poisons
spells(132274, { 22, 603 }) -- Crippling Poison
spells(132273, { 323, 324, 325, 623, 624, 625, 2641, 3768, 3769 }) -- Instant Poison
spells(132290, { 7, 8, 626, 627, 2630, 2642, 2643, 3770, 3771 }) -- Deadly Poison
spells(136066, { 23, 35, 643 }) -- Mind-Numbing Poison
spells(134197, { 703, 704, 705, 706, 2644, 3772, 3773 }) -- Wound Poison
spells(136093, { 2640, 3774 }) -- Anesthetic Poison
---Oils
spells(134879, { 7099 }) -- Blackfathom Mana Oil
spells(134711, { 2623 }) -- Minor Wizard Oil
spells(134725, { 2626 }) -- Lesser Wizard Oil
spells(134726, { 2627 }) -- Wizard Oil
spells(134727, { 2628 }) -- Brilliant Wizard Oil
spells(134767, { 2678 }) -- Superior wizard oil
spells(134878, { 2624 }) -- Minor Mana Oil
spells(134879, { 2625 }) -- Lesser Mana Oil
spells(134722, { 2629 }) -- Brilliant Mana Oil
spells(134723, { 2676, 2677 }) -- Superior Mana Oil
spells(134767, { 3299 }) -- Exceptional Wizard Oil
spells(134723, { 3298 }) -- Exceptional Mana Oil
spells(134723, { 3266 }) -- Righteous Weapon Coating
spells(134723, { 3265 }) -- Blessed Weapon Coating
---Warlock stuff
spells(134131, { 3615, 3616, 3617, 3618, 3619, 3620 }) -- Spellstone
spells(134085, { 3609, 3610, 3611, 3612, 3613, 3614, 3597 }) -- Firestone
---Shaman stuff
spells(136114, { 563, 564, 1783, 2638, 2639, 3014 }) -- Windfury Totem
spells(136018, { 283, 284, 525, 1669, 2636, 3785, 3786, 3787, 7569 }) -- Windfury Weapon
spells(136040, { 124, 285, 543, 1683, 2637 }) -- Flametongue Totem
spells(135814, { 5, 4, 3, 523, 1665, 1666, 2634, 3779, 3780, 3781, 7567 }) -- Flametongue Weapon
spells(135847, { 2, 12, 524, 1667, 1668, 2635, 3782, 3783, 3784, 7566 }) -- Frostbrand Weapon
spells(237575, { 3345, 3346, 3347, 3348, 3349, 3350, 6910, 6985 }) -- Earthliving Weapon
spells(136086, {
    29, 3021, 3022, 3023, --Rank1
    6, 3024, 3025, 3026, --Rank2
    1, 3027, 3028, 3029, --Rank3
    503, 3030, 3031, 3032, --Rank4
    1663, 3033, 3034, 3035, --Rank5
    683, 3036, 3037, 3038, --Rank6
    1664, 3039, 3040, 3041, 7568, --Rank7
    2632, 3042, 3043, 3044, --Rank8
    2633, 3018, 3019, 3020 --Rank9
}) -- Rockbiter weapon
--- Druid SOD
spells(132143, { 7141, 6858 }) -- Wild Strikes
--- Rogue SOD
spells(132100, { 7254 }) -- Sebacious Poison
spells(132098, { 7255 }) -- Numbing Poison
spells(132108, { 7256 }) -- Atrophic Poison
spells(135935, { 7651, 7542 }) -- Occult Poison
--- Misc
spells(134417, { 7098 }) -- Blackfathom Sharpening Stone
spells(135253, { 2712 }) -- Fel Sharpening Stone
spells(135254, { 2713 }) -- Adamantite Sharpening Stone
spells(135228, { 2506 }) -- Elemental Sharpening Stone
spells(135252, { 1643 }) -- Dense Sharpening Stone
spells(135248, { 40 }) -- Rough Sharpening Stone
spells(135249, { 2684 }) -- Consecrated Sharpening Stone
spells(135249, { 13 }) -- Coarse Sharpening Stone
spells(135251, { 483 }) -- Solid Sharpening Stone
spells(135250, { 14 }) -- Heavy Sharpening Stone
spells(135254, { 2713 }) -- Sharpen Blade
spells(134800, { 26 }) -- Frost Oil
spells(134803, { 25 }) -- Shadow Oil
spells(134426, { 2720 }) -- Greater Ward of Shielding
spells(134425, { 2719 }) -- Lesser Ward of Shielding
spells(132273, { 3102 }) -- Bloodboil Poison
spells(134799, { 42 }) -- Instant Toxin
spells(135260, { 2954 }) -- Fel Weightstone
spells(134806, { 3592 }) -- Blessed Wizard Oil
spells(134723, { 7650 }) -- Enchanted Repellent
--- Fishing
spells(134335, { 266, 95244, 87646 }) -- Aquadynamic Fish Attractor
spells(134440, { 264 }) -- Aquadynamic Fish Lens
spells(134335, { 265 }) -- Flesh Eating Worm
spells(134324, { 264 }) -- Nightcrawlers
spells(134335, { 266 }) -- Sharpened Fish Hook
spells(134335, { 263 }) -- Shiny Bauble
spells(237147, { 3868 }) -- Glow Worm
spells(254118, { 98849 }) -- Glass Fishing Bobber
spells(236553, { 99315 }) -- Corpse Worm Bait
