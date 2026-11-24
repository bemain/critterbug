# Third-party and AI-generated assets

Every asset we did not make by hand is listed here. Steam requires the game to disclose AI-generated content, and
third-party assets must allow use in a commercial game.

## Third-party

| Asset | Path | Source | Licence | Added |
|---|---|---|---|---|
| Stylized Nature MegaKit (Standard), by Quaternius | `assets/Stylized Nature Megakit/` | https://quaternius.com/packs/stylizednaturemegakit.html | CC0 1.0 | 2026-01-26 (re-added 2026-11-20) |
| ProtonScatter 4.0, by HungryProton | `addons/proton_scatter/` | https://github.com/HungryProton/scatter | MIT (`addons/proton_scatter/LICENSE`) | 2026-01-26 (re-added 2026-11-20) |
| Dialogue Manager 3.10.4, by Nathan Hoad | `addons/dialogue_manager/` | https://github.com/nathanhoad/godot_dialogue_manager (tag v3.10.4, the last release for Godot 4.6) | MIT (`addons/dialogue_manager/LICENSE`) | 2026-11-23 |

The MegaKit excludes five textures that no model uses (`Leaf_Pine.png`, `Leaves_GiantPine_C.png`,
`Leaves_NormalTree.png`, `Leaves_TwistedTree.png` and `Rocks_Desert_Diffuse.png`). ProtonScatter excludes its
`demos/` and `tests/` folders and the unused Godot 3 preset dialogs in `src/stack/inspector_plugin/ui/presets/`. Its
two presets point at Megakit models instead of the removed demo assets.

Dialogue Manager is the `addons/dialogue_manager/` folder of that tag; the repository's `examples/` and `tests/`
folders, outside it, are not included. Its two C# files (`DialogueManager.cs` and
`example_balloon/ExampleBalloon.cs`) are left out, since the game is GDScript. The game's balloon,
`src/ui/dialogue/`, is a copy of the add-on's example balloon, so updating the add-on doesn't overwrite it.

## Made in-house

| Asset | Path | How | Added |
|---|---|---|---|
| Placeholder snail critter | `assets/critters/snail/snail.glb`, scene `src/world/critters/Snail.tscn` | Built by `assets/critters/snail/build_snail.py` in Blender 5.3. No AI-generated parts. | 2026-11-23 |

## AI-generated

| File | Model | Date | Notes |
|---|---|---|---|
| (none yet) | | | |
