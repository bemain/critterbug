# Third-party and AI-generated assets

Every asset we did not make by hand is listed here. Steam requires the game to disclose AI-generated content, and
third-party assets must allow use in a commercial game.

## Third-party

| Asset | Path | Source | Licence | Added |
|---|---|---|---|---|
| Stylized Nature MegaKit (Standard), by Quaternius | `assets/Stylized Nature Megakit/` | https://quaternius.com/packs/stylizednaturemegakit.html | CC0 1.0 | 2026-01-26 (re-added 2026-11-20) |
| ProtonScatter 4.0, by HungryProton | `addons/proton_scatter/` | https://github.com/HungryProton/scatter | MIT (`addons/proton_scatter/LICENSE`) | 2026-01-26 (re-added 2026-11-20) |

The MegaKit excludes five textures that no model uses (`Leaf_Pine.png`, `Leaves_GiantPine_C.png`,
`Leaves_NormalTree.png`, `Leaves_TwistedTree.png` and `Rocks_Desert_Diffuse.png`). ProtonScatter excludes its
`demos/` and `tests/` folders and the unused Godot 3 preset dialogs in `src/stack/inspector_plugin/ui/presets/`. Its
two presets point at Megakit models instead of the removed demo assets.

## Made in-house

| Asset | Path | How | Added |
|---|---|---|---|
| Placeholder snail critter | `assets/critters/snail/snail.glb`, scene `src/world/critters/Snail.tscn` | Built by `assets/critters/snail/build_snail.py` in Blender 5.3. No AI-generated parts. | 2026-11-23 |

## AI-generated

| File | Model | Date | Notes |
|---|---|---|---|
| (none yet) | | | |
