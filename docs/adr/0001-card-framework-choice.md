# ADR 0001: Card Framework & Engine Selection

Date: 2026-06-15
Status: Accepted

## Context

Deadhand is a single-player, card-driven dark-fantasy western deckbuilder roguelike, targeted at a ~8–13 week launch (see `docs/GDD.md`). The card system is the entire game — picking the wrong foundation here is the single largest schedule risk.

Three real candidates were evaluated for the card-handling foundation, plus a meta-question of engine choice.

### Candidates Evaluated

#### 1. db0 / godot-card-game-framework (CGF)
- Godot 3.x. Last release v2.2.0 on **2022-06-05**.
- Community Godot 4 port (`godot4-conversion` branch, `menaechmi/godot-card-game-framework4`) is incomplete and effectively stalled. The maintainer has publicly acknowledged that a from-scratch rewrite would be more practical than completing the port.
- Licensed **AGPL-3.0** with a Steam-distribution addendum. The addendum permits Steam binary distribution but does not waive the copyleft source-disclosure obligation.
- Feature surface is far larger than Deadhand needs (targeting arrows, attachments, multiple hands, tokens with drawers, grid placement, full rules-enforcement scripting engine).

#### 2. DesirePathGames / Slay-The-Robot
- MIT license. GDScript on **Godot 4.4**.
- Built explicitly as a roguelike-deckbuilder framework (the README states this verbatim).
- Ships shops, rest sites, status effects, artifacts, and consumables out of the box.
- JSON-driven card data; most card effects are achievable without GDScript edits.
- Active: created Dec 2025, last push Jan 2026. 197 stars at evaluation time.

#### 3. chun92 / card-framework
- MIT license. GDScript on **Godot 4.6**.
- Lightweight card UI plumbing only — `Card`, `CardContainer` (with `Pile` and `Hand`), `CardFactory`, drag-and-drop, JSON data.
- Actively maintained (v1.4.0 released 2026-05-08). 304 stars.
- Less opinionated than Slay-The-Robot; provides UI primitives, leaves gameplay rules to the consumer.

### Engine Question

Unreal Engine was considered because the team has stronger Unreal familiarity. However:
- Deadhand has no requirement that benefits from Unreal's strengths (no 3D, no Lumen/Nanite/Niagara/Chaos use, no skeletal animation, no real-time physics).
- Unreal's costs are significant for this scope: build size (~200MB+ vs. Godot's ~50MB), more complex UMG plumbing for a hand of five cards, harder Steam Deck Verified targeting, slower agent-assisted iteration loops (no UE equivalent to GDScript's plain-text hot reload).
- No mature UE card-game framework comparable to Slay-The-Robot exists.

## Decision

Deadhand will be built on **Godot 4.4+** using **DesirePathGames / Slay-The-Robot** as the foundation.

- The Slay-The-Robot framework's shape (roguelike deckbuilder with shops, rests, status effects, artifacts) maps almost 1:1 to Deadhand's design (tasks ≈ encounters, items/clothing/drinks ≈ artifacts/consumables, contested encounters as a new mode added on top).
- MIT licensing keeps the commercial Steam release unencumbered.
- Engine compatibility (Godot 4.4) leaves the door open to upgrade to 4.6+ if needed.

CGF is rejected primarily on staleness + license fit, and secondarily on overbuilt scope.

Unreal is rejected for this title only; this ADR does not constrain engine choice for future projects.

## Consequences

### Positive
- Estimated 2–3 weeks saved on foundation work (deck/draw/discard/hand UI, shop screens, status-effect pipeline).
- JSON content pipeline matches the GDD's data-driven card definitions.
- MIT license clean for commercial release.
- Smaller engine footprint targets Steam Deck and low-end hardware well.

### Negative
- Slay-The-Robot's opinions (e.g., naming of "encounters," "actions," "artifacts") may not match Deadhand's vocabulary 1:1. Either adapt naming internally or accept the framework's terms.
- A new contested-encounter mode (simultaneous reveal, bust line) must be authored on top — Slay-The-Robot is primarily player-vs-environment, not duels.
- One additional dependency to track for Godot updates.

### Neutral
- Two NPCs and lore-card text are gameplay-level additions, neither helped nor hindered by framework choice.

## Follow-Up

- [x] Clone Slay-The-Robot and run its demo locally to confirm fit (timeboxed to 1 day).
  - Cloned to `vendor/slay-the-robot/` at commit `6feee71acff1a8e26805aba3bc4440b1078cd7c7` ("Upgraded to Godot 4.6").
  - **Headless import blocked:** requires Godot **4.6** (typed `Dictionary[K,V]` syntax is 4.4+). Local machine has 4.3.stable. User must install Godot 4.6 to proceed.
- [x] Identify the seams in Slay-The-Robot where Deadhand's contested encounter mode plugs in.
  - **API surface**: `scripts/actions/` (BaseAction + categories), `scripts/action_interceptors/`, `scripts/validators/`. Cards/enemies/artifacts are "data + lists of action dicts" pointing at these scripts.
  - **Plug point**: a new `scripts/encounters/ContestedEncounter.gd` extending STR's encounter runner, driven by our own state machine.
- [x] Document the framework's content authoring surface.
  - STR is **code-first**: content authored in GDScript in `autoload/GlobalProdDataGenerator.gd` and `data/prototype/*.gd`. JSON is an **exported artifact** (and an input for the mod loader).
  - **Decision**: Deadhand authors content via the **mod-overlay JSON path** (`external/mods/deadhand/`). See TDD §8.5.
- [x] Update GDD §15 (Technical Design) to reflect Slay-The-Robot as the foundation. (Stripped GDD §15 → pointer; full plan in TDD §8.)
- [x] Vendor the framework into the repo as a copied snapshot with a documented version tag.
  - Copied to `vendor/slay-the-robot/` (not submodule). Commit hash pinned above.
  - **Action item**: write `vendor/slay-the-robot/VERSION_PIN.md` once Godot 4.6 is installed and headless import is verified.

## New Action Items (Discovered During Vendoring)

- [ ] **BLOCKER**: User installs Godot 4.6.stable locally (drop binary into `~/.local/bin/` as `godot4`).
- [ ] After Godot 4.6 install: run `godot --headless --import` in `vendor/slay-the-robot/` to populate `.godot/` cache; confirm clean import.
- [ ] STR ships **no test framework**. Install GUT in our `game/addons/gut/` as task #1 of TDD scaffolding.
- [ ] **JSON schemas in TDD §9 need revision** — they were written before STR was inspected and assume a different shape. Real schema lives in `vendor/slay-the-robot/data/prototype/CardData.gd`. Revision tracked as TDD open question.
- [ ] Decide whether to add Deadhand-specific data classes to STR's central `Global.SCHEMA` registry (option A: tight integration) or keep Deadhand entirely in mod-overlay space (option B: clean separation). Current lean: option B.

## References

- GDD: `docs/GDD.md`
- Original brief: `docs/idea.txt`
- Slay-The-Robot: https://github.com/DesirePathGames/Slay-The-Robot
- chun92 / card-framework (fallback): https://github.com/chun92/card-framework
- db0 / godot-card-game-framework (rejected): https://github.com/db0/godot-card-game-framework
