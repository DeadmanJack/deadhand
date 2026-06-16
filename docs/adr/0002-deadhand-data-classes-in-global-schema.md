# ADR 0002: Deadhand Data Classes in Global.SCHEMA

Date: 2026-06-15
Status: Accepted

## Context

Deadhand authors gameplay content as STR mod-overlay JSON (TDD §8.3, Option B). STR's `FileLoader` deserializes JSON into lookup tables keyed by `class_name` / `table_name` pairs registered in `Global.SCHEMA` (`vendor/slay-the-robot/autoload/Global.gd`).

Inspection of the vendored STR snapshot (commit `6feee71`, documented in `docs/cards/STR_SCHEMA_REFERENCE.md`) established:

- **`Global.SCHEMA` is hardcoded.** `_generate_schema()` builds class maps from a fixed array; there is no runtime API to append rows.
- **The mod loader loads JSON instances of existing classes only.** `mod_info.json` folder entries must reference a `class_name` already present in `SCHEMA`. Mods cannot register new prototype types.
- **STR has no first-class types for Deadhand concepts.** No `TaskData`, `EncounterData`, `MemoryCardData`, `HiddenTriggerData`, `JournalEntryData`, or contested-duel schema. Tasks, hidden triggers, journal entries, and set bonuses cannot be modeled cleanly with `EventData`/`EnemyData`/`player_values` alone without losing type safety and agent-readable specs.

Three options were considered:

| Option | Approach | Outcome |
|---|---|---|
| A | Keep everything in mod-overlay space using `card_values` / `player_values` hacks | No SCHEMA fork; schemas become implicit and untyped; agents must infer shape from Actions |
| B | Register new classes via mod loader append | **Not possible** — STR provides no append mechanism (`STR_SCHEMA_REFERENCE.md` §3) |
| **C** | Add five Deadhand classes + SCHEMA rows by patching `Global.gd` | Typed `@export` fields, JSON round-trip, explicit TDD §9 specs |

Additionally, the project owner has committed to a **one-time STR fork** — we vendored STR into `vendor/slay-the-robot/` and will **never re-merge upstream**. Patch surface in `Global.gd` is acceptable; merge cost is zero.

Memory cards do **not** require a new class: they are `CardData` with `card_tags: ["memory"]` and `ActionDeadhandRevealMemory` on `card_draw_actions` (TDD §9.3).

## Decision

**Option C:** Register five new Deadhand data classes in `Global.SCHEMA` by patching `vendor/slay-the-robot/autoload/Global.gd` directly. Each patch is recorded in `vendor/slay-the-robot/VERSION_PIN.md`.

### New classes

| Class | Extends | Lookup table | Content folder |
|---|---|---|---|
| `DeadhandTaskData` | `PrototypeData` | `_id_to_deadhand_task_data` | `external/mods/deadhand/tasks/` |
| `DeadhandContestedEncounterData` | `PrototypeData` | `_id_to_deadhand_contested_encounter_data` | `external/mods/deadhand/encounters/` |
| `DeadhandHiddenTriggerData` | `SerializableData` | `_id_to_deadhand_hidden_trigger_data` | `external/mods/deadhand/secrets/` |
| `DeadhandSetBonusData` | `SerializableData` | `_id_to_deadhand_set_bonus_data` | `external/mods/deadhand/sets/` |
| `DeadhandJournalEntryData` | `SerializableData` | `_id_to_deadhand_journal_entry_data` | `external/mods/deadhand/journal/` |

Prototype scripts live under `vendor/slay-the-robot/data/prototype/deadhand/` (or equivalent path listed in VERSION_PIN). Field definitions match TDD §9.4–§9.8 and the Wave 2 locked schema list.

Cards, sting cards, memory cards, and opponent deck templates continue to use existing STR classes (`CardData`, `CardPackData`) — no new card prototype.

## Consequences

### Positive

- **Clean type safety:** Each Deadhand concept has `@export` fields, a `class_name`, and a TDD §9 JSON example agents can copy verbatim.
- **Mod-overlay authoring preserved:** Content still ships as JSON under `external/mods/deadhand/`; only the SCHEMA registry and prototype scripts are fork-patched.
- **No upstream merge cost:** One-time fork stance means `Global.gd` edits do not block future STR pulls — there will be none.
- **Agent-readable specs:** Subagents implement `TaskRegistry`, `SecretsTracker`, `JournalManager`, etc. against explicit types instead of parsing ad-hoc dicts.

### Negative

- **Fork surface:** Every STR snapshot change to `Global.gd` or `PrototypeData` hierarchy must be manually reconciled — mitigated by never re-merging and documenting patches in VERSION_PIN.
- **Vendor directory edits:** Violates "pure mod overlay" ideal from TDD §8.3 Option B marketing; structural extension is unavoidable given STR's SCHEMA rigidity.
- **Implementation work:** Five new `.gd` prototype files, SCHEMA rows, lookup getters on `Global`, and `mod_info.json` folder mappings — owned by Wave 2 vendor patch tasks, not this ADR alone.

### Neutral

- Actions, Validators, and Interceptors remain dynamically loaded by path — no registry change.
- `CardData` / `CardPackData` JSON authoring is unchanged; see `STR_SCHEMA_REFERENCE.md` §7 for field mapping.

## Follow-Up

- [ ] Add five prototype scripts under `vendor/slay-the-robot/data/prototype/deadhand/`.
- [ ] Patch `Global.gd`: SCHEMA rows, lookup tables, `get_deadhand_*_data()` helpers.
- [ ] Regenerate `external/data/mod_info.json` base entries if required by `FileLoader._generate_base_mod_data()`.
- [ ] Wire `mod_info.json` in Deadhand mod with folder → class/table mappings (TDD §9.4–§9.8).
- [ ] Record all vendor file edits in `VERSION_PIN.md`.

## References

- TDD §8 (integration plan), §9 (data schemas)
- `docs/cards/STR_SCHEMA_REFERENCE.md` — ground truth for STR fields and SCHEMA limitations
- ADR 0001 — STR selected as foundation; mod-overlay JSON for content
- `vendor/slay-the-robot/autoload/Global.gd` — SCHEMA registry (to be patched)
- Project stance: **never re-merge upstream STR** (TDD §8.1)
