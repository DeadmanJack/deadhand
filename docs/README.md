# Deadhand — Documentation Index

A dark-fantasy western card-game roguelike. 1800s. You start with $2 and a battered deck. The mayor needs to die.

## For Anyone Picking This Up (Humans or Agents)

Read in this order:

1. [`idea.txt`](idea.txt) — the original brief, captured 2026-06-15. Tone & spirit.
2. [`GDD.md`](GDD.md) — Game Design Document. **What we're making.** Pure design — no tech.
3. [`TDD.md`](TDD.md) — Technical Design Document. **How we're building it.** Agents implementing modules read this.
4. [`BACKLOG.md`](BACKLOG.md) — Scope-creep parking lot. Things we deliberately are *not* doing in v1.0.
5. [`adr/`](adr/) — Architecture Decision Records. One file per major irreversible decision.
6. [`cards/CARDS.md`](cards/CARDS.md) — Canonical card list. Source of truth for the eventual JSON resources.

## Authoring Rules

- **GDD is design**, **TDD is engineering.** Do not put engine names, signal names, file paths, or autoload names in the GDD. Do not put suit names, card names, or encounter flavor text in the TDD.
- **Add to BACKLOG, don't expand v1.0.** If a new idea won't ship in 8–13 weeks, it goes to `BACKLOG.md` with a trigger condition.
- **ADRs are append-only.** When a decision changes, write ADR N+1 superseding the old one. Don't edit ADRs in place.
- **Spoiler hygiene:** Hidden triggers, secret backstory beats, and Memory card lore live in `secrets/` (gitignored or access-controlled later). They never appear in card flavor text.
- **Vocabulary:** Code and TDD use Slay-The-Robot vocabulary (Encounter, Action, Artifact). GDD and player-facing strings use Deadhand vocabulary (Task, Effect, Item). The mapping table lives in TDD §4.

## Engine Requirement

**Godot 4.6.stable** is required. The vendored Slay-The-Robot framework uses typed `Dictionary[K,V]` syntax (4.4+) and declares `4.6` in its `project.godot`. Godot 4.3 will *not* parse the autoloads.

Install location: `~/.local/bin/godot4` (or wherever your PATH expects it).

## Status (as of 2026-06-15)

- [x] GDD v0.1 drafted
- [x] TDD v0.1 drafted with modules + event bus + CLI harness + STR integration plan
- [x] ADR 0001: Slay-The-Robot chosen as framework foundation
- [x] BACKLOG.md established
- [x] Slay-The-Robot vendored at `vendor/slay-the-robot/` (commit `6feee71`, `VERSION_PIN.md` written, nested `.git/` and `.github/` removed per snapshot vendoring policy)
- [x] Godot **4.6.stable** installed at `~/.local/bin/godot4` (previous 4.3 backed up as `godot4_4.3`)
- [x] STR imports cleanly under 4.6 (headless `--import` and `--quit-after 60` both pass; only benign UID-fallback warnings)
- [x] CARDS.md drafted (78 cards + 6 clothing + 5 sets; ambiguities resolved in Appendix A)
- [x] Root `.gitignore` written
- [ ] GUT test framework installed in `game/addons/gut/`
- [ ] First mod-overlay roundtrip (one card, one task, one shop entry) — go/no-go gate
- [ ] Rewrite TDD §9 JSON schemas against STR's real `CardData` property surface
- [ ] Vertical slice scaffolded
