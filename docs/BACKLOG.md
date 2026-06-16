# Deadhand — Backlog (Scope-Creep Parking Lot)

**Status:** Living document
**Purpose:** Capture good ideas that are *not* v1.0. The lead AI is responsible for refusing to do these during v1.0 production and pushing them here instead.

---

## How This List Works

- Every entry has a **trigger condition** for when we'd actually do it. If there's no trigger, it doesn't belong here — it belongs deleted.
- Entries are sorted by "if we have time during v1.0 polish, *maybe*" → "post-launch v1.1" → "v2.0 or never."
- Each entry is one bullet. If it grows past 3 lines, it's a feature spec, not a backlog item.
- Cite the source: was it the GDD's own scope discussion, a chat suggestion, or an engineering "we noticed during prototyping"?

---

## Tier A — Late v1.0 Polish (Only If Schedule Allows)

| ID | Item | Trigger | Source |
|---|---|---|---|
| A1 | One additional NPC (the Preacher) with 4 one-liners | Vertical slice ships by week 5 with budget to spare | GDD §16.2 |
| A2 | One additional named synergy (#6 of 5) — "The Penitent" | Schedule comfortable in week 8 | GDD §6.4 |
| A3 | Additional Memory cards (10 → 15) for richer Journal | Art budget under | GDD §6.1 |
| A4 | Notoriety paint-on effect on the world (wanted posters appear) | After UI polish complete | GDD §5.2 |
| A5 | Saloon ambient pianist sprite, animated | Audio pass complete and looking thin | GDD §13 |

## Tier B — v1.1 (First Post-Launch Patch, 4–6 Weeks Out)

| ID | Item | Trigger | Source |
|---|---|---|---|
| B1 | **Daily seeded run** with shared seed-of-the-day | Steam launch stable; analytics show retention need | GDD §17 |
| B2 | Steam **Leaderboards** for fastest win, lowest notoriety | After B1 lands | GDD §17 |
| B3 | **The Bargain ending** fully fleshed out | Player engagement metrics show 50%+ completed True Ending | GDD §10.3 |
| B4 | 5 additional **Hidden Triggers** (8 → 13) | Community asks for more secrets | GDD §6.4.2 |
| B5 | Steam **Trading Cards** + backgrounds | Standard Steam roadmap milestone | (Throw Fight precedent) |
| B6 | **Mid-run save/resume** (currently a roguelike — quitting abandons) | Accessibility feedback warrants it | TDD §10.1 |
| B7 | Two more **starter deck variants** (5 → 7) | If new players struggle to vary their builds | GDD §11.2 |

## Tier C — v2.0 or Never

| ID | Item | Trigger | Source |
|---|---|---|---|
| C1 | Travel to **neighboring towns** (e.g., the dead railhead at Coltrane's Crossing) | Sales support a full content expansion | GDD §16.2 |
| C2 | **Mounted gameplay / horse cards** | C1 happens (you need somewhere to ride to) | GDD §16.2 |
| C3 | **Seasonal events** (Halloween, Day of the Dead) | Live ops budget exists | GDD §16.2 |
| C4 | **Steam Workshop** support for custom encounter cards | Modder community organically forms | GDD §16.2 |
| C5 | Multiplayer / Async PvP (mail your opponent a duel) | Far-future, almost certainly never | GDD §16.2 |
| C6 | **Multi-language** localization | Sales justify the translation budget | TDD §11 |

---

## Explicitly Rejected (Will Not Do)

These have been considered and rejected. They go here so we don't re-litigate them.

- **Real-time combat** — Deadhand is fully turn-based card-resolved. Pillar #1.
- **Procedurally generated quests** — every encounter is hand-authored for tone. Procgen of one-liners would gut the writing.
- **Voice acting** — typewriter text + per-character instrument tone is the deliberate aesthetic.
- **3D camera or 3D backdrops** — 1800s engraved card aesthetic is the look.
- **"Resource gathering" mini-games** beyond cards — Pillar #1: the cards are the game.
- **Crafting system** — items already give cards. Crafting is a card sink that adds complexity without adding fun.
- **Card upgrades** (Slay-the-Spire-style +) — overlaps with sting cards/face cards already. Would dilute the playing-card aesthetic.
- **Random world map generation** — Deadhand is one town. The town is the world.

---

## Process Notes

1. When someone (including the project owner) suggests something during a chat, the default response is: "Adding to BACKLOG.md, tier X, trigger Y." Not yes, not no — parked with criteria.
2. At the end of each milestone, we review Tier A items. If we made it on schedule, we pick up at most 1–2 Tier A items before locking the milestone.
3. If a v1.0 item is ever cut, we move it here with a "Cut From v1.0" tag, not deleted, so v1.1 planning has the option.
4. This list is **read** during the weekly scope-check. If we're behind, we cut a v1.0 item to this list. If we're ahead, we pull a Tier A item up.

---

*Maintained by the project lead / lead AI. Submit changes via PR; do not edit during active development sprints without explicit scope review.*
