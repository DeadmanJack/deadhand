# Vendor Version Pin: Slay-The-Robot

Date: 2026-06-15
Status: Pinned

## Upstream

- Repo: https://github.com/DesirePathGames/Slay-The-Robot
- Pinned commit: `6feee71acff1a8e26805aba3bc4440b1078cd7c7`

## Engine

- Required: **Godot 4.6.stable** (project.godot declares `config/features=PackedStringArray("4.6")` and uses typed `Dictionary[K,V]` syntax that requires Godot 4.4+).
- Verified against:

  ```
  4.6.stable.official.89cea1439
  ```

## Import Verification

Both ran cleanly under Godot 4.6.stable on Ubuntu 24.04 on 2026-06-15:

- `godot4 --headless --import` — no parse errors. Warnings about a stale `uid://nh32y87hcke5` pointing at `res://icon.svg` are emitted by the engine but auto-resolved to the text path; no action required.
- `godot4 --headless --quit-after 60` — all autoloads (`Scenes.gd`, `FileLoader.gd`, etc.) compile and initialize. The main scene loads. Only benign warnings remain (UID fallbacks, ObjectDB leak-at-exit notice, and a `missing_texture.png` "loaded as image file" note tied to `FileLoader`'s runtime asset loading path).

## Patches Applied

### 2026-06-15: GUT 9.6.0 test framework

- Patch: Installed GUT (Godot Unit Test) v9.6.0 at `addons/gut/`. Downloaded from `https://github.com/bitwes/Gut/archive/refs/tags/v9.6.0.tar.gz`.
- Files added:
  - `addons/gut/**` (entire GUT addon tree)
  - `tests/test_gut_smoke.gd` (two trivial passing assertions)
  - `.gutconfig.json` (test discovery config: `res://tests/`, prefix `test_`, exit on completion)
- Files modified:
  - `project.godot` — added `res://addons/gut/plugin.cfg` to `[editor_plugins] enabled` PackedStringArray
- Purpose: Test framework for Deadhand modules (see `docs/TDD.md` §14). Deadhand code runs in STR's project context as a mod overlay, so the addon must live inside the STR project, not the (deferred) `game/` overlay.
- Verified: `godot4 --headless --path . --import` (one-time class_name registration), then `godot4 --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_gut_smoke.gd -gexit` → `2/2 passed`, exit 0.
