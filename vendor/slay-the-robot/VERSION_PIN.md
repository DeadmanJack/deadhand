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

### 2026-06-15: Deadhand data classes (W2-4)

- Patch: Added five Deadhand `SerializableData` / `PrototypeData` classes and registered them in `Global.SCHEMA`.
- Files added:
  - `data/prototype/DeadhandTaskData.gd`
  - `data/prototype/DeadhandContestedEncounterData.gd`
  - `data/readonly/DeadhandHiddenTriggerData.gd`
  - `data/readonly/DeadhandSetBonusData.gd`
  - `data/readonly/DeadhandJournalEntryData.gd`
  - `tests/test_deadhand_data_classes.gd`
- Files modified:
  - `autoload/Global.gd` — SCHEMA entries, lookup tables, and getters for all five classes
- Purpose: Wave 2 data layer for Deadhand tasks, contested encounters, hidden triggers, set bonuses, and journal entries.
- Verified: `godot4 --headless --path . --quit-after 60`, then GUT run of `tests/test_deadhand_data_classes.gd`.

### 2026-06-15: PrototypeData deterministic UID override (W2-3)

- Patch: `data/PrototypeData.gd` — `generate_unique_id()` checks `DeadhandRNGService.use_deterministic_uids` and delegates to `DeadhandRNGService.generate_uid_static()` before wall-clock logic.
- Files added:
  - `autoload/deadhand_rng_service.gd` — seeded per-track RNG service with deterministic UID generation.
  - `tests/test_deadhand_rng_service.gd` — GUT tests for seed replay, track isolation, and UID determinism.
- Purpose: Replace wall-clock UID generation with run-seed–deterministic IDs for replay-safe runs (see `docs/TDD.md` §3.1 RNGService). Autoload registration deferred to W2-5; static flag gates the PrototypeData patch until then.
- Verified: `godot4 --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_deadhand_rng_service.gd -gexit` → `3/3 passed`, exit 0.

### 2026-06-15: EventBus + EventLog (W2-2)

- Patch: Deadhand pub/sub and JSONL event log autoloads with typed payload resources.
- Files added:
  - `autoload/deadhand_event_bus.gd` — typed signals, emit helpers, STR `Signals.card_drawn` bridge
  - `autoload/deadhand_event_log.gd` — append-only JSONL to `user://logs/runs/<run_uuid>.jsonl`
  - `autoload/deadhand_payloads/*.gd` — Resource payloads with `to_dict()` / `from_dict()`
  - `tests/test_deadhand_event_bus.gd`, `tests/test_deadhand_event_log.gd`
- Note: Autoload scripts intentionally omit `class_name` (Godot 4 autoload name collision). Use `/root/DeadhandEventBus` etc.
- Verified: GUT runs for event bus and event log tests pass headlessly.

### 2026-06-15: Deadhand mod overlay + autoload registration (W2-5)

- Patch: Register Deadhand autoloads; mount `external/mods/deadhand/` mod with go/no-go smoke fixtures.
- Files added:
  - `external/mods/deadhand/mod_info.json`, `cards/test_5_clubs.json`, `tasks/test_pan_for_gold.json`
  - `tests/test_deadhand_mod_overlay.gd`
- Files modified:
  - `project.godot` — `[autoload]` entries for `DeadhandEventBus`, `DeadhandEventLog`, `DeadhandRNGService`
  - `external/mod_list.json` — enable deadhand mod at load_priority 100
  - `data/PrototypeData.gd` — preload-based RNGService hook (no `class_name` collision)
- Verified: `godot4 --headless --path . --quit-after 60` exit 0; full GUT suite 23/23 pass; mod card/task loaded; EventLog captures boot JSONL.

### 2026-06-15: ContestedEncounterRunner state machine (W3-3)

- Patch: Head-to-head contested encounter runner with 3-round simultaneous reveal, bust line, and wound tracking.
- Files added:
  - `scripts/deadhand/deadhand_contested_encounter_runner.gd` — RefCounted state machine (IDLE → IN_ROUND → RESOLVED)
  - `external/mods/deadhand/contested_encounters/encounter_town_drunk.json` — Town Drunk duel fixture
  - `tests/test_deadhand_contested_encounter_runner.gd` — deterministic seed-42 scenario + event sequence assertions
- Purpose: Wave 3 contested encounter module per TDD §8.6 / §9.5 and GDD §4.2. Emits `encounter_started`, `shot_resolved`, `encounter_resolved` via DeadhandEventBus; RNG track `rng_contested`.
- Verified: `godot4 --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_deadhand_contested_encounter_runner.gd -gexit` → `3/3 passed`, exit 0.
