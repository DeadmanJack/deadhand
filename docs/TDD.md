# Deadhand — Technical Design Document (TDD)

**Version:** 0.1
**Date:** 2026-06-15
**Status:** Draft
**Engine:** Godot 4.4+
**Foundation:** [DesirePathGames / Slay-The-Robot](https://github.com/DesirePathGames/Slay-The-Robot) (MIT)
**See also:** [`GDD.md`](GDD.md), [`adr/0001-card-framework-choice.md`](adr/0001-card-framework-choice.md), [`adr/0002-deadhand-data-classes-in-global-schema.md`](adr/0002-deadhand-data-classes-in-global-schema.md)

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

We **copy** Slay-The-Robot into `vendor/slay-the-robot/` at a pinned commit. Not a submodule. This is a **one-time fork** — we will never re-merge upstream STR. All framework changes are tracked as patches in our repo.

**Rationale:**
- We will need to make small internal patches we control. A submodule encourages upstream-first thinking, but STR is a small framework — upstreaming is not our priority.
- A copy lets us diff-track our changes inside our own repo.
- STR's mod loader (see §8.5) gives us a non-invasive override path for content and script overrides; structural changes (new SCHEMA classes) are patched directly in `Global.gd` (see ADR 0002).

**Pinned version:** `6feee71acff1a8e26805aba3bc4440b1078cd7c7` ("Upgraded to Godot 4.6").

**Engine requirement:** Godot **4.6.stable**. STR uses typed `Dictionary[K,V]` syntax (4.4+) and declares `config/features=PackedStringArray("4.6")` in its `project.godot`. Godot 4.3 will not parse the autoloads.

`vendor/slay-the-robot/VERSION_PIN.md` is a **patch ledger**: upstream commit hash, pull date, engine requirement, and every file we have modified from the pinned snapshot (with rationale per patch).

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

**Autoload count: 13.** Signals, Scenes, Scripts, FileLoader, Random, Global, GlobalTestDataGenerator, ActionHandler, ActionGenerator, DebugLogger, HandManager, SoundManager, StatsHandler. (`GlobalProdDataGenerator` is registered but inactive — commented out in shipping config.) This is a sizable global surface to inherit. **Coupling risk:** flagged.

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
- Deadhand-specific data classes (`DeadhandTaskData`, `DeadhandContestedEncounterData`, etc.) register into `Global.SCHEMA` by **patching `Global.gd` directly** — the mod loader cannot append SCHEMA rows (see ADR 0002 and `docs/cards/STR_SCHEMA_REFERENCE.md` §3).

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
| `Global.SCHEMA` (patched in `Global.gd`) | `DeadhandTaskData`, `DeadhandContestedEncounterData`, `DeadhandHiddenTriggerData`, `DeadhandSetBonusData`, `DeadhandJournalEntryData` |
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

All Deadhand content is authored as STR mod-overlay JSON using the `{ "properties": { ... }, "patch_data": { } }` wrapper (see `docs/cards/STR_SCHEMA_REFERENCE.md` §4.4). Field names match `@export` vars on the prototype class verbatim. Deadhand-specific classes extend STR's base types and register in `Global.SCHEMA` via a patched `Global.gd` (ADR 0002).

**Class hierarchy summary:**

| Section | STR class | Extends | New? |
|---|---|---|---|
| §9.1–§9.3 | `CardData` | `PrototypeData` | No — reuse STR |
| §9.4 | `DeadhandTaskData` | `PrototypeData` | Yes |
| §9.5 | `DeadhandContestedEncounterData` | `PrototypeData` | Yes |
| §9.6 | `DeadhandHiddenTriggerData` | `SerializableData` | Yes |
| §9.7 | `DeadhandSetBonusData` | `SerializableData` | Yes |
| §9.8 | `DeadhandJournalEntryData` | `SerializableData` | Yes |
| §9.9 | `CardPackData` | `SerializableData` | No — reuse STR |

Memory cards are **not** a separate class — they are `CardData` with `card_tags: ["memory"]` and `ActionDeadhandRevealMemory` on `card_draw_actions`.

### 9.1 Cards (`CardData`)

Standard playing cards and named face cards. Poker identity (suit, rank, face/ace flags) lives in `card_values`; STR-native fields handle display and play plumbing.

| Deadhand concept | STR field | Notes |
|---|---|---|
| Stable ID | `object_id` | Required in JSON `properties` |
| Display name | `card_name` | |
| Flavor / mechanics text | `card_description` | `[value]` tokens read from `card_values` |
| Art | `card_texture_path` | External partial path via `FileLoader.load_texture` |
| Suit | `card_values["suit"]` | `"hearts"`, `"spades"`, `"diamonds"`, `"clubs"` |
| Rank | `card_values["rank"]` | `2`–`14` (11=J, 12=Q, 13=K, 14=A) |
| Face card | `card_values["is_face"]` | `bool` |
| Ace | `card_values["is_ace"]` | `bool` |
| Check value | `card_values["value"]` | Numeric contribution in skill checks |
| Sting flag | `card_values["is_sting"]` | `false` for standard cards |
| Tags | `card_tags` | e.g. `["face", "weapon"]` |
| Play effects | `card_play_actions` | Path-keyed action dicts (§9.2 for sting riders) |

```json
{
  "properties": {
    "object_id": "card_j_spades_bowie",
    "card_name": "The Bowie",
    "card_description": "Found in the dirt under a hanged man. [value] Grit when played in a Spades check.",
    "card_texture_path": "external/mods/deadhand/art/cards/j_spades_bowie.png",
    "card_type": 0,
    "card_rarity": 3,
    "card_energy_cost": 0,
    "card_requires_target": false,
    "card_appears_in_card_packs": false,
    "card_tags": ["face", "weapon"],
    "card_values": {
      "suit": "spades",
      "rank": 11,
      "value": 11,
      "is_face": true,
      "is_ace": false,
      "is_sting": false
    },
    "card_play_actions": [
      {
        "res://game/scripts/actions/deadhand/ActionDeadhandGritBonus.gd": {
          "amount": 3
        }
      }
    ]
  },
  "patch_data": {}
}
```

**Mod folder mapping:** `external/mods/deadhand/cards/` → `{ "class_name": "CardData", "table_name": "_id_to_card_data" }`.

### 9.2 Sting Cards (`CardData` + `card_tags: ["sting"]`)

Sting cards are ordinary `CardData` instances with `card_values["is_sting"]: true`, tag `"sting"`, and a custom Action on `card_play_actions` (or end-of-turn actions for delayed riders). There is no separate prototype class.

| Deadhand concept | STR field | Notes |
|---|---|---|
| Sting identity | `card_tags` | Must include `"sting"` |
| Sting flag | `card_values["is_sting"]` | `true` |
| Rider logic | `card_play_actions` | Custom Action script + param dict |
| Rider ID (optional) | `card_values["sting_rider_id"]` | For telemetry / set-bonus lookups |
| Drink tag | `card_tags` | e.g. `["sting", "drink"]` |

```json
{
  "properties": {
    "object_id": "card_drink_whiskey_courage",
    "card_name": "Whiskey Courage",
    "card_description": "Burns going down. +[value] in Spades checks. Wound at end of encounter.",
    "card_texture_path": "external/mods/deadhand/art/cards/drink_whiskey.png",
    "card_type": 1,
    "card_rarity": 1,
    "card_energy_cost": 0,
    "card_requires_target": false,
    "card_appears_in_card_packs": false,
    "card_tags": ["sting", "drink"],
    "card_values": {
      "suit": "spades",
      "rank": 9,
      "value": 9,
      "is_sting": true,
      "sting_rider_id": "wound_at_eoe"
    },
    "card_play_actions": [
      {
        "res://game/scripts/actions/deadhand/ActionDeadhandStingRider.gd": {
          "wound_amount": 1,
          "timing": "end_of_encounter"
        }
      }
    ]
  },
  "patch_data": {}
}
```

Purchasing a drink at the Saloon creates a sting card via shop Actions and shuffles it into the deck — same JSON shape, new `object_id`.

### 9.3 Memory Cards (`CardData` + `card_tags: ["memory"]`)

Memory cards are **not** a separate class. They are `CardData` with `card_tags: ["memory"]` and `ActionDeadhandRevealMemory` on **`card_draw_actions`** (fires when the card enters hand, before the player chooses to play it). The reveal Action unlocks journal entries and burns the card out of the deck.

| Deadhand concept | STR field | Notes |
|---|---|---|
| Memory identity | `card_tags` | Must include `"memory"` |
| Reveal on draw | `card_draw_actions` | `ActionDeadhandRevealMemory` |
| Journal link | Action param `journal_entry_id` | Passed in action value dict |
| One-shot burn | `card_play_destination` | `"EXHAUST_PILE"` or burn Action in draw handler |

```json
{
  "properties": {
    "object_id": "card_memory_locket_1",
    "card_name": "Engraved Locket",
    "card_description": "A locket, still warm. Something about the initials inside…",
    "card_texture_path": "external/mods/deadhand/art/cards/memory_locket.png",
    "card_type": 4,
    "card_rarity": 4,
    "card_energy_cost": 0,
    "card_requires_target": false,
    "card_appears_in_card_packs": false,
    "card_unremovable_from_deck": false,
    "card_tags": ["memory"],
    "card_values": {
      "suit": "hearts",
      "rank": 0,
      "value": 0,
      "is_sting": false
    },
    "card_draw_actions": [
      {
        "res://game/scripts/actions/deadhand/ActionDeadhandRevealMemory.gd": {
          "journal_entry_id": "journal_locket_engraved_e"
        }
      }
    ],
    "card_play_destination": "EXHAUST_PILE"
  },
  "patch_data": {}
}
```

### 9.4 Tasks (`DeadhandTaskData`)

Player-initiated skill checks during a Phase. Extends `PrototypeData`. Loaded from mod JSON into `Global._id_to_deadhand_task_data` (SCHEMA row added in patched `Global.gd`).

| Field | Type | Notes |
|---|---|---|
| `object_id` | `String` | Stable task ID (e.g. `task_rob_grave`) |
| `task_name` | `String` | Display name |
| `task_location_id` | `String` | Town location where task is offered |
| `task_primary_suit` | `String` | `"hearts"`, `"spades"`, `"diamonds"`, `"clubs"` |
| `task_difficulty_class` | `int` | DC for skill-check resolution |
| `task_available_phases` | `Array[String]` | e.g. `["morning", "night"]` |
| `task_action_cost` | `int` | Phase actions consumed (1 default) |
| `task_reward_money_min` | `int` | Inclusive min payout on success |
| `task_reward_money_max` | `int` | Inclusive max payout on success |
| `task_reward_loot_table_id` | `String` | Loot table for `LootRoller` |
| `task_notoriety_delta` | `int` | Applied on success via `NotorietyTracker` |
| `task_on_success_actions` | `Array[Dictionary]` | STR action list on success |
| `task_on_failure_actions` | `Array[Dictionary]` | STR action list on failure |
| `task_flavor_text` | `String` | Location/task picker description |

```json
{
  "properties": {
    "object_id": "task_rob_grave",
    "task_name": "Rob a Grave",
    "task_location_id": "location_cemetery",
    "task_primary_suit": "hearts",
    "task_difficulty_class": 11,
    "task_available_phases": ["night"],
    "task_action_cost": 1,
    "task_reward_money_min": 3,
    "task_reward_money_max": 8,
    "task_reward_loot_table_id": "loot_rob_grave_basic",
    "task_notoriety_delta": 1,
    "task_on_success_actions": [
      {
        "res://game/scripts/actions/deadhand/ActionDeadhandGrantTaskRewards.gd": {}
      }
    ],
    "task_on_failure_actions": [
      {
        "res://game/scripts/actions/deadhand/ActionDeadhandWound.gd": { "amount": 1 }
      },
      {
        "res://game/scripts/actions/deadhand/ActionDeadhandDrawEncounter.gd": {
          "encounter_id": "encounter_empty_grave",
          "weight": 0.5
        }
      }
    ],
    "task_flavor_text": "The soil here is loose. Recent work."
  },
  "patch_data": {}
}
```

**Mod folder mapping:** `external/mods/deadhand/tasks/` → `{ "class_name": "DeadhandTaskData", "table_name": "_id_to_deadhand_task_data" }`.

### 9.5 Contested Encounters (`DeadhandContestedEncounterData`)

Forced duel encounters — 3-round simultaneous reveal, bust line, per-side wound tracks. Extends `PrototypeData`. **Not** STR's PvE `EventData`/`EnemyData` flow.

| Field | Type | Notes |
|---|---|---|
| `object_id` | `String` | Stable encounter ID |
| `contested_name` | `String` | Display name |
| `contested_primary_suit` | `String` | Suit governing round resolution |
| `contested_rounds` | `int` | Usually `3` |
| `contested_bust_line` | `int` | Sum threshold; at or below = bust |
| `contested_player_wound_limit` | `int` | Player wounds before defeat |
| `contested_opponent_deck_template_id` | `String` | `CardPackData.object_id` for opponent draw pool |
| `contested_opponent_wound_limit` | `int` | Opponent wounds before player win |
| `contested_opponent_hand_size` | `int` | Cards opponent holds per round |
| `contested_on_win_actions` | `Array[Dictionary]` | Rewards on player victory |
| `contested_on_lose_actions` | `Array[Dictionary]` | Consequences on player defeat |
| `contested_flavor_text` | `String` | Pre-encounter description |

```json
{
  "properties": {
    "object_id": "encounter_duel_stranger",
    "contested_name": "Duel a Stranger",
    "contested_primary_suit": "hearts",
    "contested_rounds": 3,
    "contested_bust_line": 0,
    "contested_player_wound_limit": 3,
    "contested_opponent_deck_template_id": "pack_drifter_basic",
    "contested_opponent_wound_limit": 3,
    "contested_opponent_hand_size": 5,
    "contested_on_win_actions": [
      {
        "res://game/scripts/actions/deadhand/ActionDeadhandGrantContestedRewards.gd": {
          "money_min": 5,
          "money_max": 15,
          "loot_table_id": "loot_duel_win"
        }
      }
    ],
    "contested_on_lose_actions": [
      {
        "res://game/scripts/actions/deadhand/ActionDeadhandWound.gd": { "amount": 2 }
      }
    ],
    "contested_flavor_text": "He squares up before you finish your drink."
  },
  "patch_data": {}
}
```

**Mod folder mapping:** `external/mods/deadhand/encounters/` → `{ "class_name": "DeadhandContestedEncounterData", "table_name": "_id_to_deadhand_contested_encounter_data" }`.

### 9.6 Hidden Triggers (`DeadhandHiddenTriggerData`)

Contextual interactions evaluated by `SecretsTracker` (§3.1). Extends `SerializableData` (readonly template, not combat-mutable).

| Field | Type | Notes |
|---|---|---|
| `object_id` | `String` | Stable trigger ID |
| `trigger_conditions` | `Array[Dictionary]` | Predicate list (equipped item, phase, location, journal state, etc.) |
| `trigger_fires_at_most` | `String` | e.g. `"once_per_run"`, `"once_ever"`, `"unlimited"` |
| `trigger_on_fire_actions` | `Array[Dictionary]` | Actions when trigger fires (spawn encounter, grant item, etc.) |
| `trigger_emit_line` | `String` | NPC/narrator one-liner on fire |
| `trigger_journal_entry_id` | `String` | Optional journal unlock (`DeadhandJournalEntryData.object_id`) |

```json
{
  "properties": {
    "object_id": "trigger_preacher_coat_cemetery_ghost",
    "trigger_conditions": [
      { "type": "equipped", "slot": "body", "artifact_id": "artifact_preacher_coat" },
      { "type": "phase", "phase": "night" },
      { "type": "location", "location_id": "location_cemetery" }
    ],
    "trigger_fires_at_most": "once_per_run",
    "trigger_on_fire_actions": [
      {
        "res://game/scripts/actions/deadhand/ActionDeadhandStartContestedEncounter.gd": {
          "encounter_id": "encounter_whispering_ghost"
        }
      }
    ],
    "trigger_emit_line": "A ghost watches you from the headstones.",
    "trigger_journal_entry_id": "journal_whispering_ghost_first"
  },
  "patch_data": {}
}
```

**Mod folder mapping:** `external/mods/deadhand/secrets/` → `{ "class_name": "DeadhandHiddenTriggerData", "table_name": "_id_to_deadhand_hidden_trigger_data" }`.

### 9.7 Set Bonuses (`DeadhandSetBonusData`)

Equipment/card-tag combinations that grant passive effects when active. Evaluated when deck or equipment changes.

| Field | Type | Notes |
|---|---|---|
| `object_id` | `String` | Stable set ID |
| `set_name` | `String` | Display name in saddlebag UI |
| `set_required_artifact_ids` | `Array[String]` | All must be equipped |
| `set_required_card_tags` | `Array[String]` | Tags counted in deck + hand |
| `set_required_card_tag_min_count` | `int` | Minimum cards matching tags |
| `set_on_activate_actions` | `Array[Dictionary]` | Fired when set becomes active |
| `set_on_deactivate_actions` | `Array[Dictionary]` | Fired when set breaks |
| `set_discovery_line` | `String` | First-time activation flavor line |

```json
{
  "properties": {
    "object_id": "set_four_aces",
    "set_name": "Four Aces",
    "set_required_artifact_ids": [],
    "set_required_card_tags": ["ace"],
    "set_required_card_tag_min_count": 4,
    "set_on_activate_actions": [
      {
        "res://game/scripts/actions/deadhand/ActionDeadhandNotorietyDelta.gd": {
          "delta": -1,
          "reason": "four_aces_set"
        }
      }
    ],
    "set_on_deactivate_actions": [],
    "set_discovery_line": "Four aces. The deck feels heavier."
  },
  "patch_data": {}
}
```

**Mod folder mapping:** `external/mods/deadhand/sets/` → `{ "class_name": "DeadhandSetBonusData", "table_name": "_id_to_deadhand_set_bonus_data" }`.

### 9.8 Journal Entries (`DeadhandJournalEntryData`)

Persistent lore entries unlocked by memory cards, hidden triggers, or endings. Meta-persisted via `SaveManager` (§10.2).

| Field | Type | Notes |
|---|---|---|
| `object_id` | `String` | Stable journal entry ID |
| `journal_title` | `String` | Headline in journal UI |
| `journal_body` | `String` | Full lore text |
| `journal_unlock_source` | `String` | Provenance tag (`memory`, `trigger`, `ending`, etc.) |
| `journal_category` | `String` | UI grouping (e.g. `"people"`, `"places"`, `"supernatural"`) |

```json
{
  "properties": {
    "object_id": "journal_locket_engraved_e",
    "journal_title": "Engraved Locket",
    "journal_body": "Initials inside: E.M. The same initials on the headstone you dug up last night.",
    "journal_unlock_source": "memory",
    "journal_category": "people"
  },
  "patch_data": {}
}
```

**Mod folder mapping:** `external/mods/deadhand/journal/` → `{ "class_name": "DeadhandJournalEntryData", "table_name": "_id_to_deadhand_journal_entry_data" }`.

### 9.9 Opponent Decks (`CardPackData`)

Opponent draw pools for contested encounters. Reuses STR's `CardPackData` — explicit card IDs plus optional validators/filters. Referenced by `DeadhandContestedEncounterData.contested_opponent_deck_template_id`.

| Field | Type | Notes |
|---|---|---|
| `object_id` | `String` | Pack ID (e.g. `pack_drifter_basic`) |
| `card_pack_card_ids` | `Array[String]` | Explicit card `object_id`s in the pool |
| `card_pack_color_id` | `String` | Optional color filter (empty = any) |
| `card_pack_validators` | `Array[Dictionary]` | Additional `ValidatorCard*` gates |
| `exclude_non_standard_rarities` | `bool` | Usually `false` for opponent pools |
| `exclude_non_standard_types` | `bool` | Usually `false` for opponent pools |

```json
{
  "properties": {
    "object_id": "pack_drifter_basic",
    "card_pack_card_ids": [
      "card_2_hearts",
      "card_3_hearts",
      "card_4_hearts",
      "card_5_hearts",
      "card_6_hearts",
      "card_7_hearts",
      "card_8_hearts",
      "card_9_hearts",
      "card_2_spades",
      "card_3_spades",
      "card_q_hearts_widow"
    ],
    "card_pack_color_id": "",
    "card_pack_validators": [
      {
        "res://scripts/validators/ValidatorCardTag.gd": { "card_tag": "opponent_pool" }
      }
    ],
    "exclude_non_standard_rarities": false,
    "exclude_non_standard_types": false,
    "card_pack_displays_in_codex": false
  },
  "patch_data": {}
}
```

**Mod folder mapping:** `external/mods/deadhand/deck_templates/` → `{ "class_name": "CardPackData", "table_name": "_id_to_card_pack_data" }`.

> **Authoring note:** STR has no procedural suit/rank generator. Opponent pools are maintained as explicit `card_pack_card_ids` lists (or validator-filtered subsets of registered cards). The old TDD "composition / suit_weights" sketch is replaced by this model.

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
- [x] ~~Rewrite §9 JSON schemas against STR's real `CardData`/`EncounterData` property surface (see §9 warning). Blocker: Godot 4.6 install.~~ **Resolved:** §9 rewritten against `STR_SCHEMA_REFERENCE.md`; five new Deadhand classes in ADR 0002.
- [x] ~~Decide whether Deadhand-specific data classes register into `Global.SCHEMA` via mod loader append (option B, current lean) or by editing `Global.gd` directly (option A). Defer until Step 5 of §8.7 checkpoint sequence.~~ **Resolved:** Option C — patch `Global.gd` directly (ADR 0002). Mod loader cannot extend SCHEMA.
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
