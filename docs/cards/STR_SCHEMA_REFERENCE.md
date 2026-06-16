# Slay-The-Robot Schema Reference

**Purpose:** Ground truth for Deadhand's TDD §9 rewrite and all mod-overlay authoring decisions.
**Source:** `vendor/slay-the-robot/` at commit `6feee71` ("Upgraded to Godot 4.6")
**Engine:** Godot 4.6.stable
**Date:** 2026-06-15

---

## 1. Prototype Data Classes

All prototype classes live in `data/prototype/`, extend `PrototypeData` (`data/PrototypeData.gd`), and use the prototype pattern: read-only templates in `Global._id_to_*` lookup tables; runtime copies via `get_prototype()`.

**Shared base (`PrototypeData`):**

| Field / API | Type | Default | Notes |
|---|---|---|---|
| `object_id` | `String` | `""` | Stable subtype ID (e.g. `card_modded_card`). Required for registration. |
| `object_uid` | `String` | `""` | Empty on template; generated on `get_prototype()`. Uses `Time.get_unix_time_from_system()` + `Time.get_ticks_msec()` — **not deterministic**. |
| `get_prototype(duplicate_sub_prototypes)` | method | — | Deep-copies `@export` fields; duplicates nested `PrototypeData`. |
| `generate_unique_id()` | static | — | Non-deterministic UID generation. |

Only `@export` properties serialize to/from JSON (`SerializableData.gd:7`).

### 1.1 CardData (`data/prototype/CardData.gd`)

**Extends:** `PrototypeData` · **class_name:** `CardData`

**Enums:**

| Enum | Values |
|---|---|
| `CARD_TYPES` | `ATTACK=0`, `SKILL=1`, `POWER=2`, `STATUS=3`, `CURSE=4` |
| `CARD_RARITIES` | `BASIC=0`, `COMMON=1`, `UNCOMMON=2`, `RARE=3`, `GENERATED=4` |

| Property | Type | Default | Notes |
|---|---|---|---|
| `parent_card` | `CardData` | `null` | Non-export; combat copy lineage. |
| `card_name` | `String` | `""` | Display name. |
| `card_description` | `String` | `""` | Rich-text body; `[card_value_name]` placeholders. |
| `card_texture_path` | `String` | `""` | External partial path via `FileLoader.load_texture`. |
| `card_keyword_object_ids` | `Array[String]` | `[]` | Keyword tooltip IDs. |
| `card_color_id` | `String` | `"color_green"` | Links to `ColorData`. |
| `card_energy_cost` | `int` | `1` | Base cost; shadowed by `*_until_*` fields. |
| `card_energy_cost_until_played` | `int` | `-1` | `-1` = no shadow. |
| `card_energy_cost_until_turn` | `int` | `-1` | |
| `card_energy_cost_until_combat` | `int` | `-1` | |
| `card_energy_cost_is_variable` | `bool` | `false` | X-cost: consumes all energy. |
| `card_energy_cost_variable_upper_bound` | `int` | `-1` | `-1` = no cap. |
| `card_first_shuffle_priority` | `int` | `0` | Shuffle bucket; positive = top. |
| `card_reshuffle_priority` | `int` | `0` | Same semantics on reshuffle. |
| `card_shuffle_weighting` | `float` | `1.0` | Must be > 0. |
| `card_type` | `int` | `ATTACK (0)` | See enum. |
| `card_rarity` | `int` | `COMMON (1)` | See enum. |
| `card_appears_in_card_packs` | `bool` | `true` | Filtered by `CardPackData`. |
| `card_play_destination` | `String` | `HandManager.DISCARD_PILE` | `DISCARD_PILE`, `EXHAUST_PILE`, `BANISH_PILE`. |
| `card_play_destination_strategy` | `int` | `PILE_INSERTION_STRATEGIES.TOP` | |
| `card_end_of_turn_destination` | `String` | `DISCARD_PILE` | |
| `card_end_of_turn_destination_strategy` | `int` | `TOP` | |
| `card_is_playable` | `bool` | `true` | |
| `card_is_ethereal` | `bool` | `false` | Exhaust at EOT if in hand. |
| `card_is_retained` | `bool` | `false` | |
| `card_requires_target` | `bool` | `true` | |
| `card_values` | `Dictionary` | `{}` | **Free-form extensibility dict.** Deadhand suit/rank/sting fields go here. |
| `card_description_preview_overrides` | `Array[Array]` | `[]` | Interceptor preview tuples. |
| `card_play_actions` | `Array[Dictionary]` | `[{}]` | Primary effect list. See §5. |
| `card_discard_actions` | `Array[Dictionary]` | `[]` | |
| `card_end_of_turn_actions` | `Array[Dictionary]` | `[]` | |
| `card_exhaust_actions` | `Array[Dictionary]` | `[]` | |
| `card_draw_actions` | `Array[Dictionary]` | `[]` | |
| `card_retain_actions` | `Array[Dictionary]` | `[]` | |
| `card_right_click_actions` | `Array[Dictionary]` | `[]` | |
| `card_initial_combat_actions` | `Array[Dictionary]` | `[]` | |
| `card_add_to_deck_actions` | `Array[Dictionary]` | `[]` | |
| `card_remove_from_deck_actions` | `Array[Dictionary]` | `[]` | |
| `card_transform_in_deck_actions` | `Array[Dictionary]` | `[]` | |
| `card_play_validators` | `Array[Dictionary]` | `[]` | Playability gates. |
| `card_glow_validators` | `Array[Dictionary]` | `[]` | Highlight gates. |
| `card_decorators` | `Dictionary[String, Dictionary]` | `{}` | Decorator ID → param dict. |
| `card_tags` | `Array[String]` | `[]` | Used by `ValidatorCardTag`. |
| `card_upgrade_amount` | `int` | `0` | |
| `card_upgrade_amount_max` | `int` | `1` | |
| `card_first_upgrade_property_changes` | `Dictionary` | `{}` | First upgrade only. |
| `card_first_upgrade_value_changes` | `Dictionary` | `{}` | |
| `card_upgrade_value_improvements` | `Dictionary[String, int]` | `{}` | Per-upgrade increments. |
| `card_unremovable_from_deck` | `bool` | `false` | Enforced by validators. |
| `card_untransformable_from_deck` | `bool` | `false` | |

**Key mutators:** `upgrade_card()`, `transform_card()`, `set_card_properties()`, `update_card_values()`, `improve_card_values()`, `add_card_tag()`, `add_card_decorator()`.

### 1.2 ArtifactData (`data/prototype/ArtifactData.gd`)

**Enums:** `ARTIFACT_RARITIES`: `BASIC=0`, `COMMON=1`, `UNCOMMON=2`, `RARE=3`, `BOSS=4`, `SHOP=5`, `EVENT=6`

| Property | Type | Default | Notes |
|---|---|---|---|
| `artifact_name` | `String` | `""` | |
| `artifact_description` | `String` | `""` | |
| `artifact_texture_path` | `String` | `"external/sprites/artifacts/artifact_white.png"` | |
| `artifact_script_path` | `String` | `"res://scripts/artifacts/BaseArtifact.gd"` | Runtime behavior script. |
| `artifact_interceptor_ids` | `Array[String]` | `[]` | |
| `artifact_counter` | `int` | `0` | Runtime; do not set in JSON. |
| `artifact_counter_max` | `int` | `1` | |
| `artifact_disabled` | `bool` | `false` | |
| `artifact_counter_reset_on_turn_start` | `int` | `-1` | `-1` = no reset. |
| `artifact_counter_reset_on_combat_end` | `int` | `-1` | |
| `artifact_counter_wraparound` | `bool` | `true` | |
| `artifact_color_id` | `String` | `"color_white"` | |
| `artifact_appears_in_artifact_packs` | `bool` | `true` | |
| `artifact_rarity` | `int` | `COMMON (1)` | |
| `artifact_max_counter_actions` | `Array[Dictionary]` | `[]` | On counter max. |
| `artifact_add_actions` / `remove_actions` / `right_click_actions` | `Array[Dictionary]` | `[]` | |
| `artifact_right_click_validators` | `Array[Dictionary]` | `[{VALIDATOR_PLAYER_TURN: {}}]` | |
| `artifact_first_turn_actions` / `turn_start_actions` / `turn_end_actions` / `end_of_combat_actions` | `Array[Dictionary]` | `[]` | |

**Mutators:** `set_artifact_counter()`, `increment_artifact_counter()`, `perform_artifact_actions()`, `set_artifact_disabled()`.

### 1.3 EnemyData (`data/prototype/EnemyData.gd`)

**Enums:** `ENEMY_TYPES`: `STANDARD=0`, `MINIBOSS=1`, `BOSS=2`

| Property | Type | Default | Notes |
|---|---|---|---|
| `enemy_name` | `String` | `""` | |
| `enemy_texture_path` | `String` | default sprite path | |
| `enemy_animation_id` | `String` | `""` | |
| `enemy_health` / `enemy_health_max` | `int` | `20` | |
| `enemy_health_max_random_lower` / `upper` | `int` | `20` / `25` | Randomized via `rng_enemy_health`. |
| `enemy_block` | `int` | `0` | Starting block turn 1. |
| `enemy_actions_on_death` | `Array[Dictionary]` | `[]` | |
| `enemy_type` | `int` | `STANDARD (0)` | |
| `enemy_is_minion` | `bool` | `false` | Minions optional for combat end. |
| `enemy_initial_status_effects` | `Dictionary[String, int]` | `{}` | Status ID → charges. |
| `enemy_intent_current_id` | `String` | `INTENT_INITIAL` | Runtime state. |
| `enemy_intents` | `Dictionary[String, EnemyIntentData]` | `{}` | Weighted intent graph. |
| `enemy_difficulty_to_enemy_modfiers` | `Dictionary` | `{}` | Difficulty-keyed property overrides. |

**Mutators:** `apply_enemy_difficulty_modifiers()`, `randomize_health()`, `cycle_next_intent_state()`, `add_intent_state()`, `add_health_bounds()`, `add_standard_animations()`.

### 1.4 PlayerData (`data/prototype/PlayerData.gd`)

Run-mutable prototype. Paired with `CharacterData` via `player_character_object_id`.

| Property | Type | Default | Notes |
|---|---|---|---|
| `player_character_object_id` | `String` | `""` | Links to `CharacterData`. |
| `player_health` / `player_health_max` | `int` | `50` | |
| `player_money` | `int` | `0` | |
| `player_energy_max` | `int` | `3` | `player_energy` is runtime-only. |
| `player_run_time` | `float` | `0.0` | |
| `player_values` | `Dictionary[String, Variant]` | `{}` | **Extensibility dict for mod/custom stats.** |
| `player_act` / `player_act_max` / `player_act_id` | `int`/`int`/`String` | `1`/`3`/`"act_1"` | `-1` act_max = endless. |
| `player_location_id` | `String` | `"location_0"` | |
| `location_id_to_location_data` | `Dict[String, LocationData]` | `{}` | Generated world map. |
| `player_shop_data` | `ShopData` | `null` | |
| `player_run_seed` | `int` | `0` | Seeds all RNG tracks. |
| `player_rng` | `Dictionary` | `{}` | Named `RandomNumberGenerator` tracks. |
| `player_event_pools` / `player_event_blacklisted_ids` | | | Event pool runtime state. |
| `player_run_stats` | `RunStatsData` | `null` | |
| `player_run_difficulty_level` | `int` | `0` | |
| `player_run_modifier_object_ids` | `Array[String]` | `[]` | |
| `player_available_rest_action_object_ids` | `Array[String]` | 5 defaults | |
| Reward/draft fields | various | see source | Card/artifact/consumable draft caches. |
| `player_deck` | `Array[CardData]` | `[]` | Permanent deck. |
| `player_artifact_uid_to_artifact_data` | `Dict` | `{}` | Owned artifacts. |
| Consumable slot fields | various | | 3 slots default. |

**Mutators:** `init()`, `add_money()`, `get_player_rng()`, `add_card_to_deck()`, `add_artifact()`, event pool methods, etc.

---

## 2. Other Data Classes (Abbreviated)

### 2.1 Readonly (`data/readonly/`)

All extend `SerializableData`. Loaded from JSON into `Global._id_to_*` tables.

| Class | Key `@export` fields |
|---|---|
| `ActData` | `act_name`, `act_action_script_path`, event pool IDs, `act_next_act_ids`, music/background paths |
| `EventData` | `event_weighted_enemy_object_ids`, `event_initial_combat_actions`, `event_post_combat_actions`, `event_dialogue_object_id`, validators, ambience |
| `EventPoolData` | `event_pool_event_object_ids`, `event_pool_fallback_event_object_id` |
| `LocationData` (mutable, embedded) | `location_type` enum (`STARTING=0`…`REST_SITE=7`), `location_event_pool_object_id`, `location_initial_combat_actions`, map position |
| `CharacterData` | `character_player_id`, starting cards/artifacts/money/health/packs |
| `ConsumableData` | `consumable_actions`, `consumable_values`, `consumable_rarity` enum |
| `StatusEffectData` | `status_effect_script_path`, charge bounds, decay actions |
| `KeywordData` | keyword display + linked status |
| `CardPackData` / `ArtifactPackData` / `ConsumablePackData` | color filter, validators, explicit ID lists |
| `CardDecoratorData` | decorator action wrappers, property/value mutations |
| `ActionInterceptorData` | `action_interceptor_script_path`, `action_intercepted_action_paths`, priority |
| `RestActionData` | rest site option actions |
| `RunModifierData` | `run_modifier_modifier_script_path`, automatic flag |
| `RunStartOptionData` | run-start tradeoff actions |
| `ColorData` | energy icon texture paths |
| `AnimationData` | sprite frame sets |
| `DialogueData` | dialogue states/options (embedded `DialogueStateData`, `DialogueOptionData`) |
| `EnemyIntentData` (embedded) | intent display, next-intent weights, action payloads |
| `CustomUIData` | custom UI hooks |
| `CustomSignalData` | `custom_signal_is_stat`, `custom_signal_stat_name` — mod-friendly stat hooks |
| `ModData` / `ModListData` | mod loader metadata (§4) |

**No `EncounterData`, `TaskData`, `MemoryCardData`, `HiddenTriggerData`, or `JournalEntryData` exist in STR.**

### 2.2 Mutable (`data/mutable/`)

| Class | Role |
|---|---|
| `ShopData` | Shop inventory/prices; populated by `Random` + shop actions |
| `ProfileData` | Meta progression (persistent) |
| `UserSettingsData` | Settings |
| `RunStatsData` / `CombatStatsData` | Run/combat stat counters |
| `LocationData` | Per-run map nodes (see above) |

### 2.3 Filters (`data/filters/`)

| Class | Role |
|---|---|
| `CardFilter` | Chainable card queries; cached per `CardPackData` |
| `ArtifactFilter` | Same pattern for artifacts |
| `ConsumableFilter` | Same pattern for consumables |

Validators used inside filters: loaded dynamically via `load(path).new()`.

### 2.4 Non-data helper

| Class | Role |
|---|---|
| `CardPlayRequest` | Payload for card plays: target, energy, `card_values` copy, destination pile |

---

## 3. Global.SCHEMA Registry

Defined in `autoload/Global.gd:18-46`. `_generate_schema()` builds `CLASS_NAME_TO_CLASS` and `READ_ONLY_GETTER_SCHEMA` (`Global.gd:123-132`).

| class_name string | Script | Lookup table | External folder(s) |
|---|---|---|---|
| RestActionData | RestActionData | `_id_to_rest_action_data` | `rest_actions/` |
| StatusEffectData | StatusEffectData | `_id_to_status_data` | `status_effects/` |
| ConsumableData | ConsumableData | `_id_to_consumable_data` | `consumables/` |
| CardDecoratorData | CardDecoratorData | `_id_to_card_decorator_data` | `card_decorators/` |
| ActData | ActData | `_id_to_act_data` | `acts/` |
| EventData | EventData | `_id_to_event_data` | `events/` |
| EventPoolData | EventPoolData | `_id_to_event_pool_data` | `event_pools/` |
| DialogueData | DialogueData | `_id_to_dialogue_data` | `dialogue/` |
| ActionInterceptorData | ActionInterceptorData | `_id_to_action_interceptor_data` | `action_interceptors/` |
| ColorData | ColorData | `_id_to_color_data` | `colors/` |
| KeywordData | KeywordData | `_id_to_keyword_data` | `keywords/` |
| CharacterData | CharacterData | `_id_to_character_data` | `characters/` |
| AnimationData | AnimationData | `_id_to_animation_data` | `animations/` |
| RunModifierData | RunModifierData | `_id_to_run_modifier_data` | `run_modifiers/` |
| RunStartOptionData | RunStartOptionData | `_id_to_run_start_option_data` | `run_start_options/` |
| CardPackData | CardPackData | `_id_to_card_pack_data` | `card_packs/` |
| ArtifactPackData | ArtifactPackData | `_id_to_artifact_pack_data` | `artifact_packs/` |
| ConsumablePackData | ConsumablePackData | `_id_to_consumable_pack_data` | `consumable_packs/` |
| CustomUIData | CustomUIData | `_id_to_custom_ui_data` | `custom_ui/` |
| CustomSignalData | CustomSignalData | `_id_to_custom_signal_data` | `custom_signals/` |
| EnemyData | EnemyData | `_id_to_enemy_data` | `enemies/` |
| CardData | CardData | `_id_to_card_data` | `cards/` |
| ArtifactData | ArtifactData | `_id_to_artifact_data` | `artifacts/` |
| PlayerData | PlayerData | `_id_to_player_data` | `player/` |

**Public API (selected):** `register_rod()`, `get_*_data()` per type, `get_card_data_from_prototype()`, `start_run()` / `end_run()`, `validate()`, pack cache getters, location/shop helpers. **No signals on `Global` itself** — signals live on `Signals` autoload.

### Schema extension via mod loader?

**No.** There is no runtime API to append rows to `SCHEMA`. Adding a new data class requires:
1. New `*.gd` with `class_name` extending `SerializableData` or `PrototypeData`
2. Manual edit of `Global.SCHEMA` (`Global.gd:16-17` warning)
3. Regenerate `external/data/mod_info.json` via `FileLoader._generate_base_mod_data()` (one-time utility)
4. Add folder mapping in Deadhand's `mod_info.json`

Mods can only load JSON into **existing** `class_name` / `table_name` pairs (`FileLoader.gd:237-238`).

---

## 4. Mod Loader Contract

### 4.1 Load order (`Global._ready()`)

1. `_generate_schema()` + `SerializableData.build_serializable_script_cache()`
2. `FileLoader.load_profile()` / `load_user_settings()`
3. **`GlobalTestDataGenerator.generate_test_data()`** — code-first test content
4. `GlobalProdDataGenerator` — **commented out** in shipping config
5. **`FileLoader.load_read_only_data()`** — mod JSON overlays/patches
6. `Signals.register_all_custom_signals()`, pack caches, animations

Mods load **after** test data generation; same `object_id` **patches** existing table entries (`FileLoader.gd:258-268`).

### 4.2 `external/mod_list.json`

JSON patch wrapper:

```json
{
  "properties": {
    "object_id": "mod_list",
    "mod_load_data": {
      "<folder_path>/": { "enabled": true, "load_priority": 0 }
    }
  },
  "patch_data": {}
}
```

| Field | Type | Notes |
|---|---|---|
| `mod_load_data` keys | `String` | Partial directory paths (see §4.3) |
| `enabled` | `bool` | Skip if false |
| `load_priority` | `int` | Lower loads first; higher priority wins on ID collision |

Sorted by `ModListData.get_sorted_enabled_mod_folder_list()` (`ModListData.gd:19-33`).

Base game entry: `"external/"` → loads `external/mod_info.json` (which points at `external/data/*`).

### 4.3 Mod folder path resolution

**Can mods live outside `external/mods/`? YES.**

Paths are **partial paths** prefixed by `FileLoader._EXTERNAL_FILE_PREFIX`:
- Editor/debug: `res://` + path (`FileLoader.gd:67-69`)
- Exported build: `<exe_dir>/` + path (`FileLoader.gd:72-74`)

Any folder under the project root works if listed in `mod_list.json`. Convention uses `external/mods/<name>/` but `external/data/` (base game) and arbitrary paths like `game/deadhand/` are equally valid.

`load_json(mod_base_directory, "mod_info.json")` resolves to `_EXTERNAL_FILE_PREFIX + mod_base_directory + "mod_info.json"`.

Asset loaders (`load_texture`, `load_audio`) also accept `is_absolute=true` for OS-absolute paths (`FileLoader.gd:96-99`), but **mod folder loading does not use absolute paths**.

### 4.4 `mod_info.json` (`ModData`)

| Property | Type | Purpose |
|---|---|---|
| `mod_name` / `mod_author` / `mod_description` | `String` | Display metadata |
| `mod_version` / `mod_game_version` | `Dictionary` | Semver structs |
| `mod_dependency_mod_ids` | `Array[String]` | Ordering hints (validation TODO) |
| `mod_folder_to_load_data` | `Dictionary` | Folder → loader config |
| `mod_script_file_paths` | `Dict[String, String]` | External `.gd` → `take_over_path` target |

**`mod_folder_to_load_data` entry:**

```json
"external/mods/deadhand/cards/": {
  "class_name": "CardData",
  "table_name": "_id_to_card_data"
}
```

Every JSON file in that folder is loaded; filename arbitrary. Format:

```json
{ "properties": { "object_id": "...", ... }, "patch_data": {} }
```

**Read path:** `load_json` → `set_serializable_properties_from_json_patch()` → store in `Global[table_name][object_id]`.

### 4.5 `mod_script_file_paths`

Maps external script → existing `res://` path for `ResourceLoader.take_over_path()` (`FileLoader.gd:223-229`, `ModData.gd:37-42`).

| Mapping | Effect |
|---|---|
| `"external/mod/foo.gd": "res://scripts/.../Foo.gd"` | Override upstream script |
| `"external/mod/new.gd": ""` | Load external script as new resource |

**Limitations:**
- Overrides affect future `load()` calls only; autoloads already initialized are not re-run
- Cannot override `class_name` registration itself — only script bodies
- Cannot add autoloads
- Example mod override uses `Logger.log_line` but framework uses `DebugLogger` — example override would error at runtime (`example_mod/scripts/ActionDebugLog.gd:5`)

### 4.6 What mods can/cannot do

| Capability | Supported? |
|---|---|
| Add/patch JSON instances of existing SCHEMA classes | **Yes** |
| Override existing `.gd` scripts | **Yes** |
| Add new Action/Validator/Interceptor `.gd` referenced by path | **Yes** (no registry) |
| Register new SCHEMA data classes | **No** (edit `Global.gd`) |
| Add autoloads | **No** |
| Replace `GlobalTestDataGenerator` output entirely | **Partial** — patch by `object_id` only |

---

## 5. Action / Validator / Interceptor System

### 5.1 BaseAction (`scripts/actions/BaseAction.gd`)

| Surface | Purpose |
|---|---|
| `init(parent, card_play_request, targets, values, parent_action)` | Constructor |
| `perform_action()` | **Override** — effect logic after `_intercept_action()` |
| `perform_async_action()` | Async completion; emit `action_async_finished` |
| `is_async_action()` / `is_instant_action()` / `is_action_short_circuited()` | Handler hints |
| `get_action_value(key, default)` | Hierarchy: action values → `CardPlayRequest.card_values` → `CardData.card_values` → defaults |
| `_intercept_action()` | Runs interceptor chain; returns `ActionInterceptorProcessor[]` |
| `TARGET_OVERRIDES` enum | Retargeting (`SELECTED_TARGETS`, `RANDOM_ENEMY`, etc.) |

**BaseAsyncAction:** cache interceptors between sync setup and async completion.

### 5.2 Action JSON reference format

Every action list is `Array[Dictionary]`. Each dictionary has **one key** = script path:

```json
"card_play_actions": [
  { "res://scripts/actions/debug_actions/ActionDebugLog.gd": { "log_message": "hello" } }
]
```

Instantiation (`ActionGenerator.gd:9-24`):

```
load(action_path) → .new() → init(combatant, card_play_request, targets, values, parent)
```

**No registration table.** New actions need only a `.gd` file and a path string. Mods may ship actions under `external/` and reference by `res://` after `take_over_path`, or place scripts in the project tree.

**Category folders (representative samples):**

| Folder | Example | Role |
|---|---|---|
| `card_actions/card_play_actions/` | `ActionCardPlay.gd` | Intercept-only sentinel; not executed |
| `card_actions/cardset_actions/` | `ActionAddCardsToDeck.gd` | Bulk card mutations |
| `combatant_actions/` | `ActionAttackGenerator.gd` | Damage pipeline |
| `artifact_actions/` | `ActionChangeArtifactCharge.gd` | Artifact counters |
| `world_generation_actions/` | `ActionGenerateAct.gd` | Procedural map |
| `world_interaction_actions/` | `ActionOpenChest.gd` | Non-combat interactions |
| `shop_actions/` | `ActionShopPopulateItems.gd` | Shop generation |
| `rewards/` | `ActionGrantRewards.gd` | Post-combat rewards |
| `audio_actions/` | music/SFX actions | |
| `debug_actions/` | `ActionDebugLog.gd` | Console logging |
| `meta_actions/` | run-level actions | |
| `custom_actions/` | `ActionEmitCustomSignal.gd` | Custom stat signals |

### 5.3 Validators (`scripts/validators/BaseValidator.gd`)

| Surface | Purpose |
|---|---|
| `_validation(card_data, action, values)` | **Override** — return bool |
| `validate(...)` | Wrapper; supports `invert_validation` flag |

Referenced from card/event JSON:

```json
"card_play_validators": [
  { "res://scripts/validators/ValidatorPlayerTurn.gd": {} }
]
```

Loaded via `Global.validate()` → `load(path).new().validate()` (`Global.gd:681-693`). **Dynamic discovery** — no registry.

### 5.4 Interceptors

**Data:** `ActionInterceptorData` JSON defines which action script paths are intercepted and which `BaseActionInterceptor` script runs.

**Runtime:** `BaseActionInterceptor.process_action_interception(processor, preview_mode)` → `CONTINUE|STOPPED|REJECTED`.

Example: `InterceptorDamageIncrease.gd` reads status charges, shadows `damage` value.

Interceptors are **data-registered** (via JSON into `_id_to_action_interceptor_data`), not code-registered. Mods add new `ActionInterceptorData` JSON files.

### 5.5 Card play call path (summary)

```
Hand click → HandManager.add_card_to_play_queue()
  → _perform_card_plays() → _play_card()
  → ActionGenerator.generate_card_play() [intercept-only]
  → ActionGenerator.create_actions(..., card_play_actions)
  → ActionHandler.add_actions([ActionCardPlayEnd] + play_actions)
  → each action.perform_action()
```

---

## 6. Round-Trip Worked Example

**File:** `external/mods/example_mod/cards/card_modded_card.json`

### JSON → CardData mapping

| JSON key | CardData field | Value in example |
|---|---|---|
| `object_id` | `object_id` | `"card_modded_card"` |
| `card_name` | `card_name` | `"Example Modded Card"` |
| `card_description` | `card_description` | flavor text |
| `card_play_actions` | `card_play_actions` | `[{ActionDebugLog.gd: {}}]` |
| `card_type` | `card_type` | `1` = SKILL |
| `card_rarity` | `card_rarity` | `3` = RARE |
| `card_requires_target` | `card_requires_target` | `false` |
| `card_energy_cost` | `card_energy_cost` | `1` |
| `card_values` | `card_values` | `{}` |

**Invalid/stale keys in example (not on CardData):** `card_exhausts`, `card_listeners` — ignored or error on `set()`; use `card_play_destination` for exhaust behavior.

### Omitted properties → defaults

Not set in example → defaults apply: `card_play_destination=DISCARD_PILE`, `card_tags=[]`, `card_decorators={}`, shuffle priorities `0`, `card_shuffle_weighting=1.0`, all empty action arrays, upgrade dicts empty, `card_is_playable=true`, etc.

### `card_play_actions` execution trace

1. Player clicks card → `HandManager._play_card()` (`HandManager.gd:394-439`)
2. `ActionGenerator.create_actions(..., card_play_actions)` loads `res://scripts/actions/debug_actions/ActionDebugLog.gd`
3. If mod enabled with script override, external `ActionDebugLog.gd` replaced via `take_over_path` **before** any loads
4. `ActionHandler` runs `perform_action()`
5. Framework `ActionDebugLog.gd:4-12`: intercept → read `log_message` (default `""`) → `DebugLogger.log_line(...)`

Mod override (`example_mod/scripts/ActionDebugLog.gd:5`) calls nonexistent `Logger.log_line` — broken unless fixed.

---

## 7. TDD §9 Cross-Reference Mapping

### 7.1 Cards (§9.1)

| TDD §9 placeholder | STR real field | Notes |
|---|---|---|
| `id` | `object_id` | Required in JSON `properties` |
| `display_name` | `card_name` | |
| `flavor_text` | `card_description` | STR merges mechanics + flavor in one field |
| `art_path` | `card_texture_path` | External partial path |
| `suit` | `card_values["suit"]` | No native field |
| `rank` | `card_values["rank"]` | |
| `is_face` / `is_ace` | `card_values[...]` | |
| `value` | `card_values["value"]` | Also usable in `[value]` description tokens |
| `tags` | `card_tags` | Native `Array[String]` |
| `actions` (id-based) | `card_play_actions` (path-based) | Completely different shape |
| `actions[].id` | Action script path key | e.g. `res://scripts/actions/custom_actions/ActionDeadhandStingRider.gd` |
| — | `card_energy_cost` | STR action-point analog (not Deadhand phase action cost) |
| — | `card_type`, `card_rarity` | STR enums required for pack filtering |

### 7.2 Sting cards (§9.2)

| TDD §9 placeholder | STR real field | Notes |
|---|---|---|
| `is_sting` | `card_values["is_sting"]` | |
| `sting_rider.id` | `card_play_actions` or `card_values["sting_rider_id"]` | Rider logic = custom Action |
| `sting_rider.params` | Action value dict in `card_play_actions` | |
| All base card fields | Same as §7.1 | Sting is not a separate class |

### 7.3 Tasks (§9.3)

| TDD §9 placeholder | STR real field | Notes |
|---|---|---|
| `id` | `EventData.object_id` or `LocationData.location_id` | **No TaskData** |
| `display_name` | `EventData` has no name field | Use `card_values` on linked event or Deadhand-only class |
| `location` | `LocationData.location_type` + map position | |
| `primary_suit` | `card_values` on event or custom Action | |
| `difficulty_class` | `card_values` / custom Action | STR uses combat stats, not DC |
| `available_phases` | **None** | Deadhand `PhaseClock` module |
| `action_cost` | **None** (or STR energy in combat) | |
| `rewards` | `event_post_combat_actions` | e.g. `ActionGrantRewards` |
| `notoriety_delta` | `player_values` or custom Action | |
| `failure_consequences` | `event_post_combat_actions` on loss path | Requires custom encounter flow |

### 7.4 Encounters (§9.4)

| TDD §9 placeholder | STR real field | Notes |
|---|---|---|
| `id` | `EventData.object_id` | **No EncounterData** |
| `kind: "contested"` | **None** | STR is PvE turn-based |
| `opponent.deck_template_id` | **None** | Opponents use `EnemyData` intent graphs |
| `rounds`, `bust_line`, `wound_limit` | **None** | Deadhand `ContestedEncounter` module |
| `primary_suit` | `card_values` / custom | |
| `on_win` / `on_lose` | `event_post_combat_actions` | Split by custom Actions |

### 7.5 Deck templates (§9.5)

| TDD §9 placeholder | STR real field | Notes |
|---|---|---|
| `id` | `CardPackData.object_id` | Partial analog |
| `composition` / suit weights | `CardPackData` validators + explicit IDs | No procedural suit/rank generator |
| `size` | `CardFilter` result count | Draft actions specify counts |

### 7.6 Hidden triggers (§9.6)

| TDD §9 placeholder | STR real field | Notes |
|---|---|---|
| `id` | **None** | Requires new class + SCHEMA edit, or `player_values` + custom Actions |
| `conditions[]` | **None** | Approximate with `EventData.event_pool_validator_data` for events only |
| `on_fire` | Custom Actions / `CustomSignalData` | Partial hook only |
| `journal_entry_id` | **None** | Deadhand-only |

**Deadhand-specific types requiring SCHEMA fork:** `TaskData`, `MemoryCardData`, `HiddenTriggerData`, `JournalEntryData`, `SetBonusData` (TDD §8.5) — store in `card_values`/`player_values` short-term, or extend `Global.gd`.

---

## 8. Surprises & Determinism Hazards

### 8.1 Contradictions vs TDD §8.2 / §8.3

| TDD claim | Reality |
|---|---|
| "Register into Global.SCHEMA via mod loader append mechanism" (§8.3) | **False.** SCHEMA is hardcoded; mods only load instances. |
| "EncounterData property surface" (§8.5, §9.4) | **No such class.** Use `EventData` + `EnemyData`. |
| "15 autoloads" (§8.2) | **13** in `project.godot` autoload section. |
| "GlobalProdDataGenerator primary content" | **Test generator runs; prod generator commented out** (`Global.gd:174-179`). |
| Mod-overlay replaces vanilla content | Mods **patch** test-generated data unless matching `object_id` removed upstream. |
| Example mod is copy-paste safe | Contains invalid keys (`card_exhausts`) and broken `Logger` reference. |

### 8.2 Architectural rigidity

- **EventBus:** STR uses `Signals` autoload with 40+ typed signals — not pub/sub EventBus. Deadhand EventBus sits alongside, must bridge manually.
- **Phase/time:** STR progress = `LocationData` floors/acts, not day/phases.
- **Contested duels:** No simultaneous-reveal mode; requires new encounter runner.
- **Autoloads:** Cannot be added via mod loader.

### 8.3 Determinism hazards

| Location | Issue |
|---|---|
| `PrototypeData.generate_unique_id()` | `Time.get_unix_time_from_system()`, `Time.get_ticks_msec()` |
| `ValidatorRNG.gd:12` | `rng.randf()` without named track in some paths |
| Most gameplay RNG | Correctly uses `Global.player_data.get_player_rng("rng_*")` |
| `Random.gd` | Centralized helpers on named tracks — **reuse for Deadhand replay** |
| Event log `t_ms` in TDD | STR has no equivalent seq log; build on top |

**Safe pattern:** All Deadhand randomness through seeded `player_rng` tracks; never call bare `randf()`/`randi()` in gameplay code.

---

*End of reference. Target: TDD §9 rewrite (Wave 2).*
