# Deadhand

Deadhand is a dark-fantasy western card-game roguelike set in the cursed 1800s
border town of Deadhand, TX. Runs are 30-60 minutes: a lone hunter walks a
fixed map, picks fights with branching cursed encounters, and tunes a small
deck of revolver shots, hex-iron tools, and ritual cards against a final
boss. This repository is currently pre-prototype: design docs plus a vendored
Slay-The-Robot snapshot used as a Godot 4 card-framework reference.

## Requirements

- Godot **4.6** (`godot4` binary on PATH). See `docs/README.md` "Engine
  Requirement" section.
- Python 3.10+ (reserved for future validators; not yet used).

## Repository Layout

- `docs/` - GDD, TDD, BACKLOG, ADRs, canonical card list
- `vendor/slay-the-robot/` - vendored STR card-engine reference (Godot 4.6,
  commit `6feee71`)
- `game/` - Godot 4.6 project root (lands during prototyping; not yet present)

## Run Slay-The-Robot Locally

The vendored STR project is a working reference for card-framework patterns
we intend to lift into `game/`. Useful invocations:

- Play STR: `godot4 --path vendor/slay-the-robot/`
- Open in editor: `godot4 -e --path vendor/slay-the-robot/`
- Headless import smoke: `godot4 --headless --path vendor/slay-the-robot/ --import`

## Documentation Map

- Game Design Document: `docs/GDD.md`
- Technical Design Document: `docs/TDD.md`
- Backlog: `docs/BACKLOG.md`
- ADRs: `docs/adr/`
- Canonical card list: `docs/cards/CARDS.md`
- Project notes / engine requirement: `docs/README.md`

## CI Gates

Primary CI (Forgejo Actions) currently runs:
- docs sanity check (markdown file inventory)
- Slay-The-Robot headless import smoke

Workflow file: `.forgejo/workflows/ci.yml`. When the `game/` Godot project
lands, this workflow will gain `--import`, `--script smoke_tests.gd`, and
`--export-release` steps mirroring the throw-fight project's CI.

GitHub is intended as a mirror target for this repo; Forgejo is the primary.
