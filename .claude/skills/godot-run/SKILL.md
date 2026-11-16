---
name: godot-run
description: Compile-check, run, or launch this Godot project from the shell. Use after editing any .gd, .tscn or .tres file to verify it compiles, or when asked to run, start, or smoke-test the game.
---

# Running Godot in critterbug

`godot.sh` (next to this file) wraps the Godot 4.6 editor binary and passes `--path <repo root>` for you. Extra arguments go straight to Godot. Run it from anywhere in the repo.

The default binary is the Mono build installed by the Godots flatpak. It crashes on the host, outside the sandbox, so always go through `godot.sh` and never call the binary directly. If `GODOT` is set, `godot.sh` runs that binary on the host instead.

## Compile-check every script

```bash
.claude/skills/godot-run/godot.sh check
```

This compiles every `.gd` file outside `addons/` with autoloads and `class_name` globals registered. It exits 1 and prints `FAILED: res://...` for each broken script, with Godot's `SCRIPT ERROR:` lines above giving the cause. Run it after every GDScript change. Running it is done when it exits 0.

Use this check rather than `--check-only --script`. That mode does not register autoloads, so it reports `Identifier not found` for names like `Songs`.

## Smoke-test the game headless

```bash
.claude/skills/godot-run/godot.sh --headless --quit-after 300
```

This runs the main scene for 300 frames and then exits. Runtime errors appear as `SCRIPT ERROR:` or `ERROR:` lines. To reach a specific scene, add `res://path/to/Scene.tscn` as the last argument.

## Baseline noise

Both commands print these lines on a healthy tree. They are not regressions:

- `ObjectDB instances leaked at exit`
- `N resources still in use at exit`
- `Note.tscn:154 - Parse Error: [ext_resource] referenced non-existent resource at: res://src/song_track/note.gd`, only from `check`. It comes from the cyclic preload between `note.gd` and `Note.tscn`.

Anything else is new. Compare against a run on the parent commit before you attribute it to your change.

## Launch with a window

```bash
.claude/skills/godot-run/godot.sh            # play the game
.claude/skills/godot-run/godot.sh --editor   # open the editor
```

Run these in the background. They block until the window closes.
