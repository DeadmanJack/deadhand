# Deadhand — Technical Design Document (TDD)

**Version:** 0.1
**Date:** 2026-06-15
**Status:** Draft
**Engine:** Godot 4.4+
**Foundation:** [DesirePathGames / Slay-The-Robot](https://github.com/DesirePathGames/Slay-The-Robot) (MIT)
**See also:** [`GDD.md`](GDD.md), [`adr/0001-card-framework-choice.md`](adr/0001-card-framework-choice.md)

---

## 1. Purpose & Scope

This document defines the **technical architecture** of Deadhand. It is the source of truth for engineering decisions; the GDD is the source of truth for design decisions. When they conflict, the GDD wins on the *what* and the TDD wins on the *how*.

This TDD is intentionally written to be **agent-readable**. Subagents will be the primary implementers of Deadhand. Every section is structured so a subagent can be pointed at a single section and complete a self-contained piece of work.

---

## 2. Engineering Principles

These are non-negotiable. Every decision below derives from them.

1. **Modular black-box systems.** Every gameplay system is a module with an explicit public interface (inputs, outputs, signals emitted, state owned). Modules know nothing about each other's internals.
2. **Event-driven by default.** State changes are emitted as typed events on a central `EventBus`. Modules react to events, never reach across to call each other directly.
3. **Deterministic by construction.** All randomness flows through a seeded RNG owned by `RunState`. A run with the same seed and same input event log produces an identical outcome, frame to frame.
4. **Every event is logged.** The event log is a first-class artifact — it is the replay format, the debug format, the agent test transcript, and the bug report format. One log file = one fully-reproducible run.
5. **CLI-first testability.** Every gameplay decision the player can make from the GUI must also be makeable from a headless CLI. The GUI is a presentation layer over a deterministic core.
6. **Vocabulary discipline.** Internally we speak Slay-The-Robot's terms (see §4). Player-facing strings translate to Deadhand-speak in a single layer. Agents and code never mix the two.
7. **No premature framework rewrites.** We use Slay-The-Robot as-is until something concretely breaks. When something breaks, we extend or replace it in isolation, behind our own interfaces.

---

## 3. System Architecture — Black-Box Modules

Each module below is owned by a single autoload or system script. The "Inputs" column lists events the module consumes; the "Outputs" column lists events the module emits. Modules **never** call each other's methods directly except through this contract.

### 3.1 Module Inventory

| Module | Owns | Inputs (Events Consumed) | Outputs (Events Emitted) |
|---|---|---|---|
| **EventBus** | Pub/sub plumbing only | (all) | (all) |
| **EventLog** | The persistent ordered log of every event in a run | (all) — sniffs everything | `LogCommitted(event_id)` |
| **RNGService** | Seeded `RandomNumberGenerator`(s) per channel | `RNGRollRequested(channel, args)` | `RNGRolled(channel, result)` |
| **GameManager** | Top-level FSM (Title / InRun / GameOver / Replay) | UI events | `StateChanged(from, to)` |
| **RunState** | HP, money, day, phase, notoriety, deck, discard, hand, equipment | mutation events (below) | `RunStateChanged(field, old, new)` |
| **DeckManager** | Operations on RunState.deck/discard/hand | `DrawRequested`, `DiscardRequested`, `BurnRequested`, `AddCardRequested`, `ShuffleRequested` | `CardDrawn`, `CardDiscarded`, `CardBurned`, `CardAdded`, `DeckShuffled` |
| **ResolutionEngine** | Skill check + contested resolution math | `CheckStartRequested`, `CardPlayed`, `EncounterCommitted` | `CheckResolved(success, sum, dc)`, `ShotResolved`, `EncounterResolved` |
| **EncounterRunner** | Drives multi-shot contested encounters | `EncounterStartRequested`, `CardPlayed` | `EncounterStarted`, `RoundAdvanced`, `EncounterResolved` |
| **TaskRegistry** | Loaded TaskData resources, availability by Phase | `PhaseChanged`, `EquipmentChanged` | `TaskAvailabilityChanged` |
| **PhaseClock** | Day/Phase progression (M/A/E/N), forced rest | `ActionTaken`, `RestRequested` | `PhaseAdvanced`, `DayAdvanced`, `RestForced` |
| **NotorietyTracker** | The hidden notoriety stat & its thresholds | `NotorietyDeltaRequested`, `TaskResolved` | `NotorietyChanged`, `NotorietyThresholdCrossed` |
| **EconomyLedger** | All money in/out | `MoneyDeltaRequested` | `MoneyChanged` |
| **LootRoller** | Reward drops keyed off task/encounter outcome | `LootRollRequested(table_id)` | `LootRolled(items[])` |
| **NPCManager** | Mose, Coffin Ann state & one-liners | `NPCInteractionRequested` | `NPCLineEmitted`, `NPCStateChanged` |
| **SecretsTracker** | Hidden trigger evaluation (§6.4.2 GDD) | `RunStateChanged`, `PhaseAdvanced`, `EncounterResolved` | `HiddenTriggerFired(id)`, `JournalEntryUnlocked(id)` |
| **JournalManager** | Persistent meta-journal of discovered lore | `MemoryCardRevealed`, `JournalEntryUnlocked` | `JournalUpdated` |
| **SaveManager** | Persistent (meta) saves only — never per-run | `MetaUnlockPurchased`, `RunEnded` | `MetaSaved` |
| **AudioManager** | Music & SFX dispatch | gameplay events (read-only) | (none) |
| **ReplayPlayer** | Drives the game from a logged event file | (none — drives) | (re-emits original events) |

### 3.2 Module Contract — Format

Every module's source file begins with a header comment in this exact format:

```gdscript
# === MODULE: NotorietyTracker ===
# Purpose: Single source of truth for the player's Notoriety stat during a run.
# Owns:    int notoriety (0..20)
#
# Consumes events:
#   - NotorietyDeltaRequested(delta:int, reason:String)
#   - TaskResolved(task_id, success, ...)   # auto-applies task.notoriety_on_success
#
# Emits events:
#   - NotorietyChanged(old:int, new:int, reason:String)
#   - NotorietyThresholdCrossed(threshold:int, direction:String)
#
# Invariants:
#   - notoriety is clamped to [0, 20].
#   - Reaching 20 emits RunFailed(reason: "rope") on the same frame.
#
# Does NOT:
#   - Modify any other module's state.
#   - Display anything (UI is downstream of events).
#   - Make any random calls (no need).
```

A subagent given "extend NotorietyTracker to support faction-specific notoriety" should be able to do the work with only this header + the module's source file — no other context required.

### 3.3 Wiring Rules

- Modules subscribe to `EventBus` signals in their `_ready()`.
- Modules emit through `EventBus`, never via direct signal connection between modules.
- The **only** module allowed to mutate `RunState`'s exported fields is `RunState` itself, in response to events.
- UI scenes are pure subscribers — they read from `RunState` (or the relevant module) and re-render on events. UI never mutates game state.
- A module may expose **read-only query methods** (`get_*`, `is_*`, `can_*`) for UI and other modules to ask questions. Reads are free; writes go through events.

---

## 4. Vocabulary Mapping — Slay-The-Robot ↔ Deadhand

We use Slay-The-Robot's vocabulary in code, comments, and agent prompts. Deadhand vocabulary appears **only** in player-facing strings (UI labels, card flavor text, NPC lines). This keeps agents from confusing themselves and lets us update STR cleanly.

| Slay-The-Robot (Code) | Deadhand (Player-Facing) | Notes |
|---|---|---|
| `Card` | Card | No change |
| `Action` (on a card) | Effect / Rider | "Action" is too generic in Deadhand-speak |
| `Encounter` | Task **or** Encounter | Context: a player-initiated `Encounter` is a Task; a forced one is an Encounter |
| `Artifact` | Item / Clothing | All passive carried gear |
| `Consumable` | Drink **or** Item-with-charges | Drinks become Sting cards on purchase, so most "consumables" actually become deck cards |
| `Floor` / `Stage` | Day | Each in-game day is one STR "floor" |
| `Room` (in a floor) | Phase (M/A/E/N) | Each phase is one STR "room" |
| `Shop` | The Store / The Saloon menu | UI choice; same backend |
| `RestSite` | Rest (forced at end of Night) | We use STR's rest plumbing; the UI dresses it up |
| `Relic` | Equipment (Hat/Body/Boots) | Treat STR relics as our equipment slots |
| `StatusEffect` | Status (wound, intimidation, drunk, etc.) | Direct reuse |
| `EnemyIntent` | Opponent's coming play | We render this in contested encounters only |
| `RewardPool` | Loot Table | Used internally |

> **For agents:** When prompted, use the STR term. The translation layer is `scripts/ui/text/translations.gd` (or similar — see §7). Do not introduce a third vocabulary.

---

## 5. Event Bus & Event Log

### 5.1 EventBus

A single autoload, `EventBus`, exposes typed signals for every domain event. Signals are namespaced by domain (`card_drawn`, `phase_advanced`, etc.) and pass a single `EventPayload` resource with a typed payload per signal.

```gdscript
# scripts/autoloads/event_bus.gd
extends Node

signal card_drawn(payload: CardDrawnPayload)
signal card_played(payload: CardPlayedPayload)
signal card_discarded(payload: CardDiscardedPayload)
signal card_burned(payload: CardBurnedPayload)
signal check_resolved(payload: CheckResolvedPayload)
signal encounter_started(payload: EncounterStartedPayload)
signal shot_resolved(payload: ShotResolvedPayload)
signal encounter_resolved(payload: EncounterResolvedPayload)
signal phase_advanced(payload: PhaseAdvancedPayload)
signal day_advanced(payload: DayAdvancedPayload)
signal rest_forced(payload: RestForcedPayload)
signal notoriety_changed(payload: NotorietyChangedPayload)
signal notoriety_threshold_crossed(payload: NotorietyThresholdPayload)
signal money_changed(payload: MoneyChangedPayload)
signal loot_rolled(payload: LootRolledPayload)
signal hidden_trigger_fired(payload: HiddenTriggerPayload)
signal memory_card_revealed(payload: MemoryCardRevealedPayload)
signal journal_entry_unlocked(payload: JournalEntryPayload)
signal npc_line_emitted(payload: NPCLinePayload)
signal rng_rolled(payload: RNGRolledPayload)
signal run_ended(payload: RunEndedPayload)
# ... etc.
```

Each `*Payload` is a `Resource` with typed `@export` fields so the log can serialize and deserialize them losslessly.

### 5.2 EventLog

`EventLog` is an autoload that subscribes to **every** signal on `EventBus` and writes each event to an in-memory append-only log. At configurable intervals (every event in debug, every N events in release), it flushes the log to disk.

**Log format (JSONL on disk):**
```json
{"seq": 0,   "t_ms":     0, "type": "run_started",      "data": {"seed": 8675309, "starter_deck_id": "default"}}
{"seq": 1,   "t_ms":   120, "type": "phase_advanced",   "data": {"day": 1, "phase": "morning"}}
{"seq": 2,   "t_ms":  1530, "type": "card_drawn",       "data": {"card_id": "5_clubs", "to": "hand"}}
{"seq": 3,   "t_ms":  1538, "type": "card_drawn",       "data": {"card_id": "j_spades_bowie", "to": "hand"}}
{"seq": 4,   "t_ms":  3402, "type": "card_played",      "data": {"card_id": "j_spades_bowie", "in_check": "rob_grave"}}
{"seq": 5,   "t_ms":  3402, "type": "check_resolved",   "data": {"task": "rob_grave", "sum": 14, "dc": 11, "success": true}}
{"seq": 6,   "t_ms":  3500, "type": "loot_rolled",      "data": {"table": "rob_grave_basic", "items": ["locket_engraved_e", "money_5"]}}
{"seq": 7,   "t_ms":  3520, "type": "memory_card_revealed", "data": {"card_id": "memory_locket_1"}}
```

- **`seq`** — monotonic per-run sequence. The single ground truth ordering.
- **`t_ms`** — wall-clock milliseconds since `run_started`. For human debugging only; not used for ordering.
- **`type`** — the event name (matches EventBus signal name).
- **`data`** — the payload, serialized as JSON.

**Files written:**
- `user://logs/runs/<run_uuid>.jsonl` — full event log
- `user://logs/runs/<run_uuid>.meta.json` — seed, starter deck, version, agent info, timestamps

### 5.3 The "Agent Input Events" Subset

A small subset of events are **agent-authorable** — these are the decisions a player makes. Everything else is a derived consequence the engine produces.

| Agent-Authorable Event | Meaning |
|---|---|
| `choose_task(task_id)` | Player picks a task for the current Phase |
| `play_card(card_id)` | Player plays a card during a check or contested round |
| `commit_play()` | Player ends their selection for the round |
| `choose_rest(location)` | Player picks where to sleep |
| `buy(item_id)` | Player purchases at store/saloon |
| `choose_dialogue(option_id)` | Player picks an NPC response option |
| `confront_mayor()` | Player initiates the endgame |
| `ride_out()` | Player abandons the run |

The CLI test harness (§6) speaks exactly this vocabulary. Anything not in this list is engine-emitted and not directly authorable.

---

## 6. CLI Test Harness — Agent-Playable Game

### 6.1 Goal

An agent on the command line can play a complete Deadhand run from start to finish, observe the resulting event stream, and assert on outcomes. No GUI, no display, no human in the loop. This makes the gameplay logic **independently testable from rendering**, and lets us produce thousands of test runs cheaply.

### 6.2 Invocation

```bash
# Run a single deterministic scripted scenario
godot --headless --script scripts/cli/deadhand_cli.gd \
  -- --seed 8675309 \
     --starter default \
     --scenario tests/scenarios/rob_grave_first_run.yaml \
     --out /tmp/run.jsonl

# Run a scenario interactively (agent at the keyboard via stdin/stdout)
godot --headless --script scripts/cli/deadhand_cli.gd \
  -- --seed 8675309 --interactive
```

### 6.3 Protocol

The CLI is a line-oriented JSON protocol over stdin/stdout. Every line is one JSON object.

**Engine → Agent (stdout):**
- One JSON object per emitted event, identical schema to the EventLog format.
- A special `prompt` event signals "I'm waiting for an agent decision," carrying the legal actions:
  ```json
  {"type": "prompt", "agent_authorable": ["choose_task", "ride_out"], "legal_tasks": ["pan_for_gold", "fish", "duel_stranger"]}
  ```

**Agent → Engine (stdin):**
- One JSON object per decision:
  ```json
  {"action": "choose_task", "task_id": "fish"}
  ```

### 6.4 Scenario Files

A scenario file is a deterministic prerecorded set of inputs that can be replayed against the engine for regression tests:

```yaml
# tests/scenarios/rob_grave_first_run.yaml
name: "First-run grave rob with Locket reveal"
seed: 8675309
starter: default
expected_terminal_event: run_ended
expected_outcomes:
  - "loot_rolled.items contains locket_engraved_e"
  - "memory_card_revealed.card_id == memory_locket_1"
  - "money_changed.new >= 5"
actions:
  - choose_task: rob_grave
  - play_card: 7_hearts
  - play_card: 8_hearts
  - commit_play: {}
  - choose_rest: saloon_room
  # ... etc
```

A scenario passes if the actual event log matches the expected outcomes. Scenarios are **the regression test suite.**

### 6.5 Agent-Authored Scenario Generation

An agent can also generate scenarios from scratch:
- "Test that completing 3 grave robs in a row triggers the Empty Grave encounter."
- "Test that drinking 5 Whiskeys in one run triggers the Whiskey Ghost."
- "Test that all 4 Aces + Mayor confrontation goes to Phase 3."

Each generated scenario gets committed to `tests/scenarios/` and runs in CI. We aim for 100+ scenarios by v1.0, covering every named card, every hidden trigger, and every encounter.

### 6.6 Replay = Same Mechanism

`scripts/cli/replay.gd <run.jsonl>` replays an event log against the engine. If the log was produced by a real run with seed S, the replay produces an *identical* log starting from S. Any drift is a bug.

This is also how we render replays graphically: the GUI subscribes to events, the `ReplayPlayer` autoload re-emits the logged events on EventBus in order, and the UI renders them as if the player had just done them. **Replay watching is just a normal game session with a different input source.**

---

## 7. Project Layout

```
deadhand/
├── docs/                         # design + tech docs (this folder)
├── vendor/
│   └── slay-the-robot/           # vendored snapshot, version-pinned (§8)
├── game/                         # Godot project root
│   ├── project.godot
│   ├── scenes/
│   │   ├── ui/                   main_menu, run_setup, journal, saddlebag, hud
│   │   ├── town/                 town_map, location scenes
│   │   ├── encounters/           skill_check, contested, mayor phases
│   │   └── cards/                card visual scene (extends STR's Card)
│   ├── scripts/
│   │   ├── autoloads/            EventBus, EventLog, GameManager, RunState,
│   │   │                         DeckManager, ResolutionEngine, EncounterRunner,
│   │   │                         PhaseClock, NotorietyTracker, EconomyLedger,
│   │   │                         LootRoller, NPCManager, SecretsTracker,
│   │   │                         JournalManager, SaveManager, AudioManager,
│   │   │                         ReplayPlayer, RNGService
│   │   ├── systems/              non-autoload helpers (e.g., DeckTemplateExpander)
│   │   ├── payloads/             *Payload resource scripts (one per signal)
│   │   ├── cards/                card resource + behavior scripts
│   │   ├── ui/
│   │   │   └── text/             translations.gd (STR-term → Deadhand-term map)
│   │   ├── cli/                  deadhand_cli.gd, replay.gd, scenario_runner.gd
│   │   └── tests/                GUT test files
│   ├── data/                     all gameplay content as JSON (STR-style) or .tres
│   │   ├── cards/                one file per named card
│   │   ├── tasks/                one file per task
│   │   ├── encounters/           one file per encounter card
│   │   ├── items/                items, clothing, drinks
│   │   ├── npcs/                 Mose, Coffin Ann + their line pools
│   │   ├── secrets/              hidden trigger definitions
│   │   └── deck_templates/       opponent deck templates
│   └── tools/                    balancing CSV, scenario generators
└── tests/
    ├── scenarios/                YAML scenario files (§6.4)
    └── fixtures/                 reference event logs for regression
```

---

## 8. Slay-The-Robot Integration Plan

### 8.1 Vendoring Strategy

We **copy** Slay-The-Robot into `vendor/slay-the-robot/` at a pinned commit. Not a submodule.

**Rationale:**
- We will need to make small internal patches we control. A submodule encourages upstream-first thinking, but STR is a small framework — upstreaming is not our priority.
- A copy lets us diff-track our changes inside our own repo.
- STR's mod loader (see §8.5) gives us a non-invasive override path that *eliminates* most reasons we'd want to fork upstream files.

**Pinned version:** `6feee71acff1a8e26805aba3bc4440b1078cd7c7` ("Upgraded to Godot 4.6").

**Engine requirement:** Godot **4.6.stable**. STR uses typed `Dictionary[K,V]` syntax (4.4+) and declares `config/features=PackedStringArray("4.6")` in its `project.godot`. Godot 4.3 will not parse the autoloads.

A `vendor/slay-the-robot/VERSION_PIN.md` file records the upstream commit hash, the date we pulled it, the engine requirement, and any patches we've applied (file to be written after first clean headless import).

### 8.2 STR's Real Shape (Findings from Inspection)

Direct inspection of the vendored snapshot revealed the framework's actual structure. The following supersedes any assumptions written before the clone.

**Content is code-first, not JSON-first.**
- Card/Enemy/Artifact prototypes are authored in **GDScript** at `data/prototype/*.gd` (e.g., `CardData.gd extends PrototypeData`). The `@export` vars on these classes *are* the schema.
- Game content is registered in `autoload/GlobalProdDataGenerator.gd` (and `GlobalTestDataGenerator.gd` for demo content).
- JSON is an **export target** and an **input format for the mod loader** — not the primary authoring path.

**Central schema registry.** `autoload/Global.gd` has a single `SCHEMA` array listing every serializable class, its lookup table, and the external folder it loads from. New content classes register by appending one row.

**The real API surface is a triad:**
- `scripts/actions/` — `BaseAction` + `BaseAsyncAction` + categories (card_actions, combatant_actions, artifact_actions, world_generation_actions, world_interaction_actions, shop_actions, audio_actions, debug_actions, meta_actions, rewards, **custom_actions**)
- `scripts/action_interceptors/` — modify actions in-flight
- `scripts/validators/` — gate when actions can fire

Cards are mostly "data + lists of action dicts" pointing at these scripts. Deadhand gameplay distinctness is **expressed as new Actions, Validators, and Interceptors** — not as new card classes.

**Autoload count: 15.** Signals, Scenes, Scripts, FileLoader, Random, Global, GlobalTestDataGenerator, GlobalProdDataGenerator, ActionHandler, ActionGenerator, DebugLogger, HandManager, SoundManager, StatsHandler, + one more. This is a sizable global surface to inherit. **Coupling risk:** flagged.

**Mod loader has true script-override capability.** `external/mod_list.json` + each mod's `mod_script_file_paths` map external `.gd` files over upstream `res://...gd` files. This is the cleanest seam for non-invasive patching.

**Determinism is first-class.** `autoload/Random.gd` plus named RNG "tracks" — already designed for save-scum-resistant deterministic runs. Reuse directly for our event-log replay system (§5–6).

**No tests ship with STR.** No GUT, no `tests/`, no CI test workflows. `GlobalTestDataGenerator` is a runtime sample-data builder, not a test harness. **Action:** install GUT in `game/addons/gut/` as task #1 of TDD scaffolding.

**Project defaults to revisit:** renderer is `gl_compatibility` (fine for 2D), window is `1200×700` and **non-resizable** (Deadhand will need to revisit for Steam Deck + 1080p targets).

### 8.3 Content-Authoring Strategy — DECISION: Mod-Overlay JSON

We treat Deadhand as a **giant mod overlay** loaded by STR's mod loader, not as a fork of STR's `GlobalProdDataGenerator`.

**Decision: Option B (mod-overlay JSON).**

| Option | Author content via... | Pros | Cons |
|---|---|---|---|
| A: Code-first (upstream-style) | `GlobalProdDataGenerator.gd` editing | Matches upstream; expressive; type-checked at parse | Forks STR; harder to track Deadhand changes vs. STR updates; agents must edit GDScript instead of data files |
| **B: Mod-overlay JSON (chosen)** | `external/mods/deadhand/*.json` + a few `.gd` script overrides | Non-invasive; clean git diffs; agents can author JSON; ships as one folder; STR updates merge cleanly | One indirection (JSON → STR loader); slightly more verbose schemas |

This decision is reversible if we hit a wall — see §8.6 off-ramp.

**Practical consequences:**
- All Deadhand cards, tasks, encounters, items live under `external/mods/deadhand/` as JSON conforming to STR's `CardData` / `EncounterData` / `ArtifactData` property surfaces (the field names match the `@export` vars in `data/prototype/*.gd`).
- Deadhand-specific Actions (sting riders, contested-encounter operators, hidden-trigger probes) live as `.gd` files under our own `game/scripts/actions/deadhand/`, referenced from JSON by `res://` path — exactly like STR's `card_play_actions` format already supports.
- Where we need a behavior STR doesn't allow data-driven, we use the mod loader's **script override** (`mod_script_file_paths`) to monkey-patch the specific STR file. These overrides live in `external/mods/deadhand/script_overrides/` and are listed in our `VERSION_PIN.md`.
- Deadhand-specific data classes (e.g., `TaskData` if needed beyond STR's `EncounterData`) register into `Global.SCHEMA` via the mod loader's append mechanism, not by editing `Global.gd` directly.

### 8.4 What We Use As-Is

- **Card display and animation** — hand UI, draw/discard animations, focus-on-hover, click-to-select.
- **Pile / Hand / Discard containers.**
- **Action / Interceptor / Validator triad** — Deadhand-specific behaviors implemented as new Actions/Validators in our own folder.
- **Shop UI** — used for the Store and (with cosmetic skin) the Saloon.
- **Rest Site flow** — used for the forced end-of-Night rest.
- **Status effect framework** — we layer wounds, drunk, intimidation, etc. on top via new status-effect scripts.
- **Encounter runner (basic)** — for solo skill checks against an environment.
- **Reward pool / loot table** — extended with our own reward action types.
- **`autoload/Random.gd`** — directly reused as the seeded RNG for our `RNGService` module (§3.1). One RNG track per Deadhand domain (loot, encounter draw, hidden trigger evaluation, etc.).
- **Mod loader** — the entry point for everything Deadhand-specific. We do not boot STR's vanilla content in shipped builds.

### 8.5 What We Extend / Add (as Mod-Overlay Content)

| Surface | Our Addition |
|---|---|
| Card prototype fields (`card_values` dict) | Deadhand-specific fields: `suit`, `rank`, `is_sting`, `sting_rider_id`, `tags[]` |
| `scripts/actions/custom_actions/` | New Deadhand actions: `ActionDeadhandStingRider`, `ActionDeadhandWound`, `ActionDeadhandNotorietyDelta`, `ActionDeadhandRevealMemory`, `ActionDeadhandHiddenTriggerProbe`, etc. |
| `scripts/validators/` | New validators: `ValidatorPhaseIs`, `ValidatorEquipmentSetActive`, `ValidatorNotorietyAtLeast`, `ValidatorJournalEntryUnlocked` |
| Status effects | `wound`, `intimidation`, `drunk`, `cursed` |
| `Global.SCHEMA` (via mod loader) | `TaskData`, `MemoryCardData`, `HiddenTriggerData`, `JournalEntryData`, `SetBonusData` |
| Shop UI subclass | Saloon variant — purchase converts to a Sting card and shuffles into deck |
| Encounter runner | Subclass `ContestedEncounter` for 3-shot simultaneous-reveal duel mode (see §8.6) |

### 8.6 What We Replace

- **Contested Encounter Mode** — STR is PvE only. We author `ContestedEncounter` as a new encounter type. Uses STR's card UI but our own state machine (3-shot simultaneous reveal, bust line, wound track per side, mutual-shot rule). Implemented in `game/scripts/encounters/contested_encounter.gd`, registered into the encounter runner via Action overrides.
- **Time-of-Day / Phase System** — STR has linear floor/room progression. Our `PhaseClock` autoload (§3.1) replaces the floor-advance trigger with our 4-Phase day cycle. Each Phase consumes one "room" from STR's perspective.
- **Notoriety, Memory cards, Hidden triggers, Journal** — all Deadhand-original modules, sit alongside STR as new autoloads.

### 8.7 Integration Checkpoint Sequence

1. **[BLOCKER]** User installs Godot **4.6.stable** locally.
2. After install: `godot --headless --import` in `vendor/slay-the-robot/` until clean (initial run populates `.godot/` cache and fixes the icon/theme/UID warnings).
3. Confirm **STR demo runs cleanly** in editor and headless. Smoke test.
4. Install **GUT** in `game/addons/gut/`. Add a single passing dummy test. Wire into CI.
5. Author a **minimal Deadhand mod-overlay** with one card (5♣ "Watered Down"), one task ("Pan for Gold"), one shop entry. Load it via STR's mod loader. Confirm round-trip: JSON → in-game card → played → reward.
6. Add `EventBus` + `EventLog` autoloads on top of STR. Confirm every relevant STR event is captured in the log.
7. Add `ContestedEncounter` as a new encounter subtype. Test via CLI scenario against a Town Drunk template.
8. Add Sting card mechanics (`ActionDeadhandStingRider`). Test via CLI scenario buying & playing Whiskey.
9. Layer in remaining modules per §3.

### 8.8 If STR Doesn't Fit

If during integration we find STR fights us in ways the mod loader can't fix:
- **First retreat:** switch from Option B (mod-overlay) to Option A (fork & edit `GlobalProdDataGenerator`). +1 week.
- **Full retreat:** abandon STR for **chun92 / card-framework** (Godot 4.6, MIT, lighter). +2 weeks. Documented in ADR 0001.

This is a real off-ramp, not theater. We do not invest 3 weeks fighting STR's assumptions. A clean checkpoint at step 5 above (mod-overlay roundtrip working) is the go/no-go gate.

---

## 9. Data Schemas

> **⚠ Revision needed.** The JSON examples in this section were drafted **before** Slay-The-Robot was inspected and reflect a hypothetical schema. The actual `CardData` field surface lives at `vendor/slay-the-robot/data/prototype/CardData.gd` and uses STR's property names verbatim (e.g., `card_name`, `card_energy_cost`, `card_play_actions`, `card_values`). Our authoring format is the mod-overlay JSON shape demonstrated by `vendor/slay-the-robot/external/mods/example_mod/cards/card_modded_card.json`.
>
> **Action:** rewrite §9.1–§9.5 against STR's actual property surface as the first task after Godot 4.6 is installed and the demo imports cleanly. Until then, the examples below are **directionally correct for intent but wrong in field names** — treat them as design sketches, not specs.

### 9.1 Cards (JSON, STR-compatible)

```json
{
  "id": "j_spades_bowie",
  "display_name": "The Bowie",
  "suit": "spades",
  "rank": 11,
  "is_face": true,
  "is_ace": false,
  "is_sting": false,
  "value": 11,
  "actions": [
    {"id": "grit_bonus", "amount": 3},
    {"id": "duel_wound_on_win"}
  ],
  "tags": ["face", "weapon"],
  "flavor_text": "Found in the dirt under a hanged man.",
  "art_path": "res://game/art/cards/j_spades_bowie.png"
}
```

### 9.2 Sting Cards (JSON, extension)

```json
{
  "id": "drink_whiskey_courage",
  "display_name": "Whiskey Courage",
  "suit": "spades",
  "rank": 9,
  "is_sting": true,
  "value": 9,
  "tags": ["drink"],
  "sting_rider": {
    "id": "wound_at_eoe",
    "params": {"amount": 1, "timing": "end_of_encounter"}
  },
  "flavor_text": "Burns going down.",
  "art_path": "res://game/art/cards/drink_whiskey.png"
}
```

### 9.3 Tasks (JSON)

```json
{
  "id": "rob_grave",
  "display_name": "Rob a Grave",
  "location": "cemetery",
  "primary_suit": "hearts",
  "difficulty_class": 11,
  "available_phases": ["night"],
  "action_cost": 1,
  "rewards": {
    "money_min": 3,
    "money_max": 8,
    "loot_table_id": "rob_grave_basic",
    "notoriety_delta": 1
  },
  "failure_consequences": [
    {"id": "hp_loss", "amount": 1},
    {"id": "encounter_draw", "weight": 0.5}
  ],
  "flavor_text": "The soil here is loose. Recent work."
}
```

### 9.4 Encounters (JSON)

```json
{
  "id": "duel_stranger",
  "kind": "contested",
  "primary_suit": "hearts",
  "rounds": 3,
  "bust_line": 0,
  "opponent": {
    "deck_template_id": "drifter_basic",
    "wound_limit": 3,
    "hand_size": 5
  },
  "player_wound_limit": 3,
  "on_win": {"money_min": 5, "money_max": 15, "loot_table_id": "duel_win"},
  "on_lose": {"hp_loss": 2},
  "flavor_text": "He squares up before you finish your drink."
}
```

### 9.5 Deck Templates (Opponent decks)

```json
{
  "id": "drifter_basic",
  "size": 12,
  "composition": [
    {"suit_weights": {"hearts": 0.4, "spades": 0.3, "diamonds": 0.2, "clubs": 0.1}},
    {"rank_range": [2, 9]},
    {"face_card_count": 1, "face_pool": ["q_hearts_widow"]}
  ]
}
```

### 9.6 Hidden Triggers (JSON)

```json
{
  "id": "preacher_coat_cemetery_ghost",
  "conditions": [
    {"type": "equipped", "slot": "body", "item_id": "preacher_coat"},
    {"type": "phase", "phase": "night"},
    {"type": "location", "location": "cemetery"}
  ],
  "fires_at_most": "once_per_run",
  "on_fire": {
    "spawn_encounter": "whispering_ghost",
    "emit_line": "A ghost watches you from the headstones."
  },
  "journal_entry_id": "whispering_ghost_first"
}
```

---

## 10. Save System

### 10.1 Per-Run State (Volatile)

Never persisted. Lives in `RunState` only. Quitting mid-run abandons the run.

The event log **is** the per-run save in a sense — a player can technically reconstruct a mid-run state from it, but the in-game UI does not offer this as a "resume" feature. (We could add it later as an accessibility option — backlogged.)

### 10.2 Meta State (Persistent)

`user://save.tres` (Godot resource format, version-tagged):

```gdscript
class_name MetaSave extends Resource
@export var version: int = 1
@export var legacy_tokens: int = 0
@export var meta_unlocks: Array[StringName] = []
@export var journal_entries: Array[StringName] = []
@export var endings_reached: Dictionary = {}   # ending_id -> first_reached_at
@export var settings: SettingsData
@export var totals: Dictionary = {}            # runs, wins, deaths, etc.
```

### 10.3 Replay Files

`user://logs/runs/<uuid>.jsonl` + `<uuid>.meta.json` — see §5.2.

We keep the last 100 run logs by default, with the option to "pin" a run to prevent cleanup. Pinned runs and "interesting" runs (a first ending, a fastest win) are auto-flagged.

---

## 11. Open Questions (Engineering)

- [x] ~~Final Godot version pin — 4.4 (STR target) vs. 4.6 (latest stable).~~ **Resolved: 4.6.stable.** STR's pinned commit declares `config/features=PackedStringArray("4.6")` and uses typed `Dictionary[K,V]` syntax (4.4+). 4.6 is mandatory.
- [ ] Rewrite §9 JSON schemas against STR's real `CardData`/`EncounterData` property surface (see §9 warning). Blocker: Godot 4.6 install.
- [ ] Decide whether Deadhand-specific data classes register into `Global.SCHEMA` via mod loader append (option B, current lean) or by editing `Global.gd` directly (option A). Defer until Step 5 of §8.7 checkpoint sequence.
- [ ] EventLog flush cadence in release builds — per-event (safest, slow) vs. per-N-events (faster, lossier on crash). Default per-event for v1.0, revisit if perf bites.
- [ ] CLI scenario format — YAML (chosen) vs. JSON. YAML wins for human-write, but scenarios generated by agents might benefit from JSON. Plan: support both, YAML as primary.
- [ ] Save file encryption — none for v1.0 (it's a single-player game; cheaters cheat themselves).
- [ ] Steam Deck — Verified vs. Playable target. Aim for Verified.
- [ ] Determinism of UI — animations are time-based and not in the event log. Replays may have slightly different frame timing without functional drift. Acceptable.
- [ ] Multi-language support — out of scope for v1.0, but the `translations.gd` layer should be designed to be locale-pluggable from day one. (Backlogged item #X.)
- [ ] Whether to use Godot's `Resource` system or pure JSON for content. **Decision: JSON for STR-aligned content, `Resource` for engine-internal payloads.** Justification in §9.

---

## 12. Testing Strategy

### 12.1 Unit Tests (GUT)

- Each module has a dedicated test file in `scripts/tests/test_<module>.gd`.
- Tests are pure — they instantiate the module in isolation, fire events at it via a mock EventBus, and assert on emitted events.
- Goal: every public method and every event-handler has ≥1 test. No exceptions.

### 12.2 Scenario Tests (CLI)

- Every named card, named encounter, named hidden trigger has at least one CLI scenario.
- Every ending has at least one CLI scenario that reaches it.
- CI runs all scenarios on every commit (headless, parallelizable).

### 12.3 Replay Tests

- A small set of "golden" recorded runs in `tests/fixtures/`. CI replays each and asserts the event log matches byte-for-byte.
- This is our defense against non-determinism creeping in.

### 12.4 Coverage Targets

| Layer | Coverage Target |
|---|---|
| Module unit tests | 90% line coverage of `scripts/autoloads/` |
| Scenario tests | 100% of named cards, encounters, hidden triggers, endings |
| Replay tests | 5+ golden runs of varying length |

---

## 13. Performance Notes

- All card art baked at one canonical size (320×448 px), atlassed where possible.
- No physics. No 3D. No shaders beyond a parchment-grain overlay.
- Target: **60fps@1080p on a 2015-era integrated GPU**; **60fps@800p on Steam Deck native**.
- Memory budget: <300 MB resident at the deepest gameplay state.
- Cold-start to playable: <3 seconds.
- Event log writes are async (deferred), do not block the frame.

---

## 14. Tooling & Workflow

### 14.1 Subagent-First Development

Per the project owner's directive, the human (and the lead AI) act as overseers. Implementation work is delegated to subagents. Every module's TDD entry (§3) is structured so a fresh subagent with **only** the relevant section + GDD context can implement that module from scratch.

Standard subagent task template:

> **Task:** Implement `<module_name>` per `docs/TDD.md` §3.X.
> **Read first:** the module's section in §3, the events it consumes/emits in §5, and any data schemas in §9 that apply.
> **Constraints:** Module must conform to its black-box contract. Do not modify any other module. All state mutations flow through events.
> **Deliverable:** The module's autoload script + its GUT test file in `scripts/tests/`. CI must pass.

### 14.2 Code Review Pattern

When a subagent submits work, the overseer reviews against:
1. Does the module emit only the events listed in its contract? (no rogue emits)
2. Does it mutate only the state it owns?
3. Are all tests passing in CI?
4. Does the event log produced by the test scenario read sensibly?
5. Is the public surface area minimal?

### 14.3 Definition of Done (Per Module)

- [ ] Module's header comment matches the §3.2 template exactly
- [ ] All consumed events are subscribed in `_ready()`
- [ ] All emitted events appear in the EventLog during testing
- [ ] GUT tests cover all event handlers
- [ ] At least one CLI scenario exercises the module end-to-end
- [ ] No direct method calls to other modules (grep -r confirms)

---

## 15. Glossary

| Term | Meaning |
|---|---|
| **Black-box module** | A self-contained system with explicit event-based I/O and no internal cross-calls |
| **Sting card** | A card with both a value and a built-in rider effect, often a tradeoff |
| **Joker** | A pure curse card with no upside; only enters the deck via narrative/supernatural channels |
| **Memory card** | A one-shot lore card that auto-burns out of the deck after first reveal |
| **Hidden trigger** | A contextual interaction fired by a specific combination of state, not advertised on any card |
| **Phase** | One of four time-of-day slices per Day (Morning/Afternoon/Evening/Night) |
| **Scenario** | A deterministic recorded set of agent inputs + expected outcomes used for testing |
| **Golden run** | A full event log preserved as a regression test fixture |
| **STR** | Slay-The-Robot, our card-game framework foundation |

---

*TDD maintained by the Deadhand engineering team. Update as architectural decisions are finalized.*
