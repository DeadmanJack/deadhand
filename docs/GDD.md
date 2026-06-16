# Deadhand — Game Design Document (GDD)

**Version:** 0.1
**Date:** 2026-06-15
**Status:** Draft
**Engine:** Godot 4.x
**Working Title:** *Deadhand*

---

## 1. Overview

### 1.1 Concept Statement
*Deadhand* is a single-player, card-driven dark-fantasy western roguelike set in the cursed 1800s Texas frontier town of **Deadhand, TX**. The player starts with $2, a battered deck, and one quiet goal: become powerful enough to end the mayor. Every action — robbing graves, dueling drifters, panning for gold, drinking at the saloon — is resolved by drawing cards from a deck that grows and corrupts as you play.

The feel sits between **Slay the Spire** (deckbuilding, run-based progression), **a tabletop D&D campaign** (skill checks, atmosphere, GM-narrated encounters), and **a vintage saloon card game** (suits, ranks, the gravity of a turned card).

### 1.2 Genre
- Deckbuilding roguelike
- Card-driven RPG / interactive fiction
- Inspired by: *Slay the Spire*, *Inscryption*, *West of Loathing*, *Disco Elysium* (tone), *Dark Souls* (storytelling), and the dog-eared D&D campaign your friend ran in middle school.

### 1.3 Platform
- Desktop (Windows, Linux, macOS) — primary
- Steam Deck — design target (Verified-quality controller support)
- Mobile — out of scope for v1.0

### 1.4 Target Audience
- Fans of *Slay the Spire*, *Inscryption*, *Hand of Fate*, *Card Crawl*
- Western and dark-fantasy readers (Cormac McCarthy, *Blood Meridian*, *Pretty Deadly* comics, *Weird West*)
- Players who want depth without 60-hour RPG commitments — a run is 30–60 minutes

### 1.5 Tone & Setting
- **Dark fantasy western.** Most of the cruelty is human; the supernatural lurks at the edges and only fully reveals itself near the end.
- **Morally gray.** The player is a thief and a killer. The mayor is worse. Almost everyone in Deadhand is compromised. There are no clean heroes.
- **Storytelling: Souls-style.** No cutscenes, no monologues. Story is delivered through:
  - One- or two-line flavor text on every card
  - Found items (locket, bent star, water-stained ledger, a child's drawing)
  - Newspaper-clipping cards that drop from tasks
  - Two cryptic NPCs who speak in fragments
- **Aesthetic:** 1800s engraved-playing-card art, sepia tones, ink-line illustration. Think bicycle deck plates, antique tarot, vintage wanted-poster typography. UI is brown leather, oil-lamp gold, blood red.

### 1.6 The "Deadhand"
The town's name carries a triple meaning the player slowly uncovers:
1. **The Dead Man's Hand** — aces and eights, the poker hand Wild Bill Hickok was holding when he was shot. A motif on signs, on the saloon floor, on the mayor's ring.
2. **Dead-hand rule** — legal term: control exerted by the dead over the living through binding contracts and entailments.
3. **A literal hand** — something old and cold, buried under the town, that grants favors in exchange for names whispered into the ground.

The mayor knows all three meanings. The player only learns the third one near the end.

---

## 2. Core Gameplay Loop

```
Start a run with $2 and a starter deck
  → Choose a task in Deadhand (mine, fish, rob, duel, etc.)
    → Draw a hand of 5 from your deck
      → Play cards to resolve a skill check (or contested encounter)
        → Win: money, items, lore, new deck cards
        → Lose: lose HP / lose money / lose Nerve / gain a curse card / go to jail
          → Spend rewards at the store / saloon / undertaker
            → Repeat until you have the wealth, gear, and grit to face the Mayor
              → Defeat the Mayor (or die / get hanged) → run ends
                → Carry a few legacy unlocks to the next run
```

**Run length target:** 30–60 minutes. Long enough to feel like a campaign, short enough to retry.

---

## 3. The Card System

### 3.1 The Player's Deck

The player has a single **personal deck** that persists for the duration of a run. It starts small and grows by acquiring items, clothing, and drinks.

#### Starter Deck (default; 24 cards)
- **2–7 of each suit** (24 number cards). Plain, weak, but reliable.
- No face cards. No Aces. No Jokers.

Subsequent runs may unlock alternative starter decks via meta-progression (see §11).

### 3.2 Card Types

| Type | Cards | Function |
|---|---|---|
| **Number cards** | 2–10 in four suits | Contribute their face value to a check when the suit matches the task. |
| **Face cards** | Jack, Queen, King | Each is a unique named ability card with both a numeric value and a special effect. |
| **Aces** | One per suit | Wild & powerful. Counts as any value 1–14 of its suit, OR triggers a "burn" effect (see §3.5). |
| **Jokers** | Black Joker, Red Joker | Curse cards. Add themselves to your hand against your will. Worth 0. Some have a malus when revealed. Acquired from drinks, bad encounters, and the supernatural. |
| **Item cards** | (deck-mixed) | Some items insert themselves directly into your deck as flavored re-skins of number/face cards (e.g., *Bone Dice* is a 6 of Clubs that says "It rattles like teeth."). |

### 3.3 Suits as Stats

Each suit maps to a primary stat. Tasks and encounters call for one (or more) of these.

| Suit | Stat | Used For |
|---|---|---|
| ♠ Spades | **Grit** | Combat, intimidation, manual labor, mining, breaking things. |
| ♥ Hearts | **Nerve** | Holding your ground in duels, withstanding fear, staring down the law, lying to a priest. |
| ♦ Diamonds | **Cunning** | Stealth, lockpicking, sleight-of-hand, deception, patience (fishing, stakeouts). |
| ♣ Clubs | **Luck** | Gambling, prospecting, scavenging, evading pursuit, supernatural events. |

### 3.4 The Face Cards

Face cards are **named, illustrated, single-copy** ability cards. The player acquires them by completing tasks and milestones — they are *not* in the starter deck. Each suit's face cards have thematic flavor.

Examples (full list lives in `docs/cards/CARDS.md` once written):

| Card | Value | Effect |
|---|---|---|
| **J♠ — The Bowie** | 11 | Adds +3 to a Grit check. If you win, deal a wound to the opponent (contested only). |
| **Q♠ — The Hangman's Knot** | 12 | Counts as 12 Grit. If played in a duel, opponent skips next round. |
| **K♠ — Old Iron** | 13 | Counts as 13 Grit. Once per encounter, replays itself for free. |
| **J♥ — The Cold Stare** | 11 | +2 Nerve. Forces opponent to discard one card. |
| **Q♥ — The Widow's Veil** | 12 | +2 Nerve. Heal 1 wound after the encounter. |
| **K♥ — The Preacher** | 13 | +3 Nerve. Cleanse one Joker from your deck if you win. |
| **J♦ — The Picklock** | 11 | +2 Cunning. Reveals one of opponent's face-down cards. |
| **Q♦ — The Forged Letter** | 12 | +2 Cunning. Lets you treat one off-suit card as Diamond this check. |
| **K♦ — Long Shadow** | 13 | +3 Cunning. Once per run, skip a contested encounter without losing rewards. |
| **J♣ — Loaded Dice** | 11 | +2 Luck. Re-draw your hand. |
| **Q♣ — Lady Fortune** | 12 | +3 Luck. Add a random Ace to your hand. |
| **K♣ — The Drifter's Coin** | 13 | +2 Luck. Flip: heads = double reward, tails = double risk. |

### 3.5 Aces — The Dead Man's Hand

The four Aces are the most powerful cards in the game and the most thematically loaded. Each one drops from a specific named encounter, never from a shop.

| Card | Effect |
|---|---|
| **A♠ — Ace of Spades** | The Mayor's mark. Wild value 1–14 of any suit. When played, "burn" one card from your discard pile out of the run. |
| **A♥ — Ace of Hearts** | The Widow's keepsake. Wild. After playing, heal 2 wounds. |
| **A♦ — Ace of Diamonds** | The Forger's last work. Wild. Draw 2 cards. |
| **A♣ — Ace of Clubs** | The Drifter's promise. Wild. The next reward is doubled. |

Collecting **all four Aces** in a single run is a prerequisite for unlocking the Mayor's true final phase (see §10).

### 3.6 Jokers — The Pure Curses

Jokers are **pure curse cards** — no upside, no gamble, only sting. Because they can never be "good play," they only enter the deck through narrative/supernatural channels, never through ordinary purchases. A player should never be punished for visiting the saloon.

**Sources (all rare and signaled):**
- Losing certain named encounters (the Whiskey Ghost, the Empty Grave, the Pact Offered)
- The Deadhand itself "rewarding" you in a bargain
- A small number of clearly-flagged choices ("Sign the ledger? +$20, but he keeps a piece of your hand.")

| Card | Effect |
|---|---|
| **Red Joker — Grinning Fool** | Worth 0. If drawn, opponent draws an extra card next round. |
| **Black Joker — Hangman's Smile** | Worth 0. When you hold it at end of encounter, take 1 wound. |

**Removal:** Jokers can be removed only by — winning at the Church (a hidden task), playing **K♥ The Preacher** after winning an encounter, or paying the Undertaker his price.

> **Design note:** Drinks and casual purchases that *used* to add Jokers now add **Sting Cards** (§3.7) — cards with both upside and downside baked into a single card. Pure Jokers are reserved for moments the player chose with eyes open.

### 3.7 Sting Cards — The Gambles

Sting Cards are the **Binding-of-Isaac-style tradeoff cards** — most of the time they help you, but they carry a rider that bites. They look like number or Ace cards in the UI (same shape, same suit, same readable value) but carry a tagged rider effect printed in red below the flavor text.

Sting cards come from:
- Saloon drinks (the most common source)
- Risky narrative choices ("Pocket the strange coin? Sure feels heavy.")
- Critical-failure rewards ("You missed — but the recoil knocked something loose. Take this.")
- A few specific items

| Sting Card (examples) | Value | Rider |
|---|---|---|
| **Whiskey Courage** | 9♠ | When played, take 1 wound at the *end* of the encounter. |
| **Bourbon Warmth** | 10♠ | When played, this card cannot be discarded by other effects for the rest of the encounter. (Mostly an upside, rare downside.) |
| **Laudanum Sleep** | Wild Ace (♥) | When played, skip drawing for one round. |
| **Cursed Whiskey** | 13♠ | When played, **burns itself out of the run** (one-shot). |
| **Snake Oil Vigor** | 5♦ | When played, the next card you reveal this encounter is at half value. |
| **The Drifter's Coin (gambit)** | 7♣ | When played, flip: heads = +5 to the check, tails = -3. |

**Rules of thumb for sting cards:**
1. The card is **always playable**. No "must skip" mechanics.
2. The rider is **always quantifiable** — the player can math whether it's worth it.
3. Sting cards **scale with synergies** (§6.4) — accumulating Drink-tagged cards in your deck unlocks a passive that softens drink stings.

> Sting cards are the design lever for "risk vs. reward" in the deck. Jokers are the design lever for "narrative consequence." Keep them separate.

---

## 4. Resolution Mechanics

### 4.1 Solo Skill Checks (D&D-Style)

Most tasks resolve as a **solo skill check**. The task lists:
- **A primary suit** (e.g., ♠ Grit)
- **A Difficulty Class (DC)** (e.g., 12)
- **Optional consequences for failure** (lose HP, gain a Joker, draw an encounter)

#### Resolution Flow
1. **Draw a hand of 5** from your deck (default; some clothing changes this).
2. **Play any number of cards** from your hand toward the check.
3. **Sum contribution:**
   - Cards of the **matching suit** contribute their full value.
   - **Off-suit number cards** contribute their value **÷ 2, rounded down**.
   - **Aces** contribute wild value of player's choice (1–14).
   - **Face cards** contribute their listed value and trigger their effect.
   - **Sting cards** (§3.7) contribute their printed value normally AND trigger their rider effect on play.
   - **Jokers** contribute 0 and may trigger their malus.
4. **Compare to DC:**
   - **Sum ≥ DC** → Success. Receive reward.
   - **Sum < DC** → Failure. Suffer consequence.
5. **Discard played cards** to the discard pile. Unplayed cards return to your hand for the next encounter, unless the task description says otherwise.

> **Design note:** There is no "bust" mechanic for solo checks — overshooting is fine. Bust matters only in contested encounters (§4.2). Overshooting *can*, however, trigger **Critical Success** at +5 over DC (see §4.3).

### 4.2 Contested Encounters

Used for: **duels, bank guards, bounty hunters, the Mayor's deputies, the Mayor himself.**

Each side has:
- A **hand of 5** (modifiable by clothing/items)
- A **wound track** (default 3 wounds = defeated; varies per opponent)
- A **deck profile** (the opponent's deck is generated from a template, e.g., "Town Drunk: 12 cards, mostly low Spades")

#### Round Structure
A contested encounter is fought over **3 "shots"** (or until one side reaches max wounds).

Each shot:
1. **Both players play 1 card face-down.**
2. **Reveal simultaneously.** (Some clothing makes the opponent reveal first; see §6.)
3. **Compare values, applying suit context.**
   - If a *primary suit* is declared for the encounter (e.g., a duel is ♥ Nerve), off-suit halves as in §4.1.
   - Higher value wins the shot. **Loser takes 1 wound.**
   - Ties: both take 1 wound. ("Mutual shot.")
4. **Face card and Ace effects trigger on reveal.**
5. **Draw back to hand size.**

After 3 shots, if neither side is at max wounds, the side with more wounds dealt to the other wins. Ties go to the defender.

#### Bust in Contested
Some special opponents (the Mayor) play with a "**bust line**" — if a side's combined revealed total across all 3 shots exceeds a threshold (e.g., 21), they bust and lose the encounter regardless of wound count. This forces meaningful card-economy choices in the climactic fight.

### 4.3 Critical Success / Critical Failure

- **Critical Success:** Beating a solo check by **+5 or more** grants a bonus reward (extra cash, a lore card, or a free item draw).
- **Critical Failure:** A *natural Joker* played alone, or a sum of **0**, triggers an encounter card draw (see §8) on top of the failure.

---

## 5. Tasks

Tasks are **player-initiated activities** chosen from the Deadhand town map. Each takes one **Action** (the player has 4 Actions per Day, one per Phase). Phase availability per task is listed in §7.1.

### 5.1 MVP Task List (12 total)

| # | Task | Location | Primary Suit | DC | Reward |
|---|---|---|---|---|---|
| 1 | **Pan for Gold** | Creek | ♠ Grit | 8 | $1–$4, sometimes a Nugget item card |
| 2 | **Mine the Old Shaft** | Hills | ♠ Grit | 12 | $4–$10, chance of cave-in (HP damage) |
| 3 | **Fish the Black Creek** | Creek | ♦ Cunning | 9 | $1–$3, occasionally a strange find (lore item) |
| 4 | **Rob a Grave** | Cemetery | ♥ Nerve | 11 | $3–$8 + grave goods (lore/items); +1 Notoriety |
| 5 | **Hold Up Stagecoach** | Outskirts road | ♠ Grit + contested | 13 / 3-wound | $8–$20, item drops; +2 Notoriety |
| 6 | **Rob the Bank** | Town Bank | ♦ Cunning *then* ♠ Grit (2-stage) | 14 / contested | $25–$50; +3 Notoriety; major item drops |
| 7 | **Duel a Stranger** | Saloon street | ♥ Nerve + contested | 3-wound | $5–$15 + dropped face card; +1 Notoriety |
| 8 | **Hunt a Bounty** | Sheriff's board | Varies (per target) | Varies | $10–$30 + faction reputation |
| 9 | **Gamble at the Saloon** | Saloon | ♣ Luck | 10 | Variable: lose stake or double it; rare item |
| 10 | **Drink at the Saloon** | Saloon | — | — | Adds a Drink card to your deck (boon + bane) |
| 11 | **Bury for the Undertaker** | Cemetery | ♠ Grit | 9 | $3–$6 + lore; chance to remove a Joker from deck |
| 12 | **Visit the Church** | Church | ♥ Nerve | 13 | Cleanse 1 Joker; or, on failure, gain 1 Joker |

### 5.2 Notoriety

A hidden stat that tracks how wanted you are. Above thresholds:
- **Notoriety 5+**: Random "Lawman" encounters interrupt tasks
- **Notoriety 10+**: Sheriff sends a bounty hunter (forced contested encounter)
- **Notoriety 15+**: Cannot enter the Bank or the Church without provoking a fight

Notoriety can be reduced by **paying off the sheriff** ($10 per point) — but the sheriff is corrupt and the money goes straight to the Mayor.

---

## 6. Items, Clothing & Drinks

All persistent rewards are **cards added to the player's deck** OR **equipped items**.

### 6.1 Deck-Mod Items (added directly to deck)

| Item | Effect on Deck |
|---|---|
| **Bone Dice** | Adds 6♣ "It rattles like teeth." |
| **Pocket Bible (well-thumbed)** | Adds 7♥ "The page is bookmarked at Lamentations." |
| **Old Revolver** | Adds 8♠ + Jack of Spades (The Bowie) on first acquisition |
| **Lockpicks** | Adds 9♦ + Jack of Diamonds (The Picklock) |
| **Lucky Penny** | Adds 2♣ "It came from a stranger's eyes." |
| **Snake Oil** | Adds 5♦ "Cures what the seller named." |
| **Locket (engraved 'E')** | Adds a unique **Memory card** (see below) |

#### Memory Cards (one-shot lore)
Several items add a **Memory** card to the deck. Memory cards are *not* a "flavored dud" — they are a deliberate, satisfying one-shot mechanic:

- **First time drawn:** reveal the card, show its lore snippet (1–3 lines), then **the card auto-burns out of the deck for the rest of the run.**
- The reveal is **free** — it does not consume your draw for the round (you immediately draw a replacement).
- The lore snippet is permanently added to the **Journal** (a meta-progression menu unlocked at 8 Legacy Tokens, see §11).
- A Memory card never appears in the same run twice. Once revealed, it is canon for that player forever.

> **Design note:** This means rare lore-bearing items are net-positive (one free draw + one journal entry) and never become deadweight. Players are rewarded for collecting them, not punished.

### 6.2 Clothing (equipped slots: Hat, Body, Boots)

Clothing **does not enter the deck**. It provides passive effects.

| Item | Slot | Effect |
|---|---|---|
| **Tattered Hat** | Hat | Starter. None. |
| **Cattleman's Hat** | Hat | +1 hand size in Grit-primary checks. |
| **Black Duster** | Body | Opponents have ½ value on Hearts cards against you (intimidation). |
| **Preacher's Coat** | Body | -1 Notoriety when entering Church. Heart cards in your hand: +1 value. |
| **Snakeskin Boots** | Boots | Once per encounter, swap a card with the top of your draw pile. |
| **Dead Man's Boots** | Boots | +1 max wound. Draws a Red Joker into your deck at the start of each new day. |

A **full set** (Hat + Body + Boots from the same "kit") grants a small set bonus (e.g., the "Outlaw Set" = +1 to all Grit checks, but +2 Notoriety per task).

### 6.3 Drinks (Saloon consumables that become deck cards)

Each drink is purchased once at the Saloon and immediately shuffled into your deck as a **Sting Card** (§3.7). The card itself carries both its upside and its rider — drinks never add separate Joker cards. Every drink is *potentially* worth it; how worth it depends on your deck and the encounter.

All Drink-origin cards carry the hidden **`drink`** tag, which feeds the Drinker synergy (§6.4).

| Drink | Cost | Card Added | Rider |
|---|---|---|---|
| **Beer** | $1 | 5♣ *"Watered down."* | None. |
| **Sasparilla** | $2 | 6♥ *"Nobody mocks you for it."* | None. |
| **Whiskey** | $3 | 9♠ *"Burns going down."* | When played, take 1 wound at end of encounter. |
| **Bourbon** | $4 | 10♠ *"Warms you."* | When played, cannot be discarded by other effects this encounter. |
| **Laudanum** | $5 | Wild Ace ♥ *"Sleep, dreamless."* | When played, skip drawing for one round. |
| **Cursed Whiskey** | $4 | 13♠ *"It tasted like grave dirt."* | One-shot: burns itself out of the run after play. |
| **The Bartender's Special** | $10 | Random Ace | When played, draw the **next** card face-down (you don't see it until reveal). Mose grins. |

> **Saloon flow:** A player can drink as many times as they can afford. The economy self-regulates — every drink fattens your deck (making average draws weaker per-card) even when the individual card is strong. Stacking drinks is a real choice.

### 6.4 Synergies & Hidden Triggers

Deadhand has two flavors of "synergy," both designed to **reward attention without punishing inattention**. A player who never notices these still wins the game. A player who does notice them gets a small, satisfying secret.

#### 6.4.1 Named Synergies (Set Bonuses)

Mechanical, deterministic, visible (the Saddlebag UI shows the bar filling). When all components are held/owned simultaneously, the passive activates. The named set is *not* mentioned on any card's flavor text — only revealed in the equipment menu once the player has at least one piece.

| Set | Components | Effect |
|---|---|---|
| **The Outlaw** | Cattleman's Hat + Black Duster + Snakeskin Boots | +1 wound limit; +2 Notoriety per successful task |
| **The Iron** | Old Revolver + J♠ The Bowie + Cattleman's Hat | All ♠ checks: +2 |
| **The Drinker** | 4+ cards in deck tagged `drink` | Drink-card riders are softened (e.g., Whiskey wound becomes "next encounter" rather than this one) |
| **The Gambler** | Lucky Penny + K♣ The Drifter's Coin + 3+ ♣ cards | Once per day, re-draw your hand for free |
| **The Mourner** | Preacher's Coat + Pocket Bible + Locket (engraved 'E') | Unlocks the **Whispering Ghost** hidden encounter at the Cemetery (see §6.4.2) |

Cap at 5 named sets in v1.0. Each is small, none are required.

#### 6.4.2 Hidden Triggers (Contextual Discoveries)

A small number of **contextual interactions** fire when a specific combination of {equipment, deck contents, location, time-of-day, run history} is true. These are **never mentioned in card flavor text** — they exist as rewards for players who pay attention to the world.

**Discovery feedback:** The first time any hidden trigger fires for a player, a single **diegetic line** appears in-world (typewriter text, single tone). No popup. No quest log. Examples:
- *"A ghost watches you from the headstones."*
- *"Something in your pocket grows warm."*
- *"The piano stops mid-song."*
- *"The locket is humming."*

The player learns over time that these lines are *signal* — something just happened. Successive triggers of the same hidden interaction are silent.

**Example hidden triggers (v1.0 target: ~8):**

| Trigger Condition | Effect |
|---|---|
| Enter Cemetery at Night wearing Preacher's Coat | **The Whispering Ghost** appears — a one-shot encounter offering an Ace ♥ in exchange for cleansing a Joker. |
| Carry Locket (engraved 'E') into Phase 2 of the Mayor fight | The Mayor starts at -1 wound (he hesitates). |
| Drink 5 Whiskeys in a single run | The **Whiskey Ghost** encounter triggers next time you sleep — fight your own reflection. |
| Visit Church during the Night phase | Cleanse all Jokers from your deck (the door is locked in daylight). |
| Reveal every newspaper Memory card across a single run | Final ending epilogue gains 2 additional lines. |
| Beat the Mayor with **only** ♣ Clubs cards in your final hand | Unlocks the **Drifter's Ending** (a meta-progression cosmetic title). |
| Sleep in the Wilderness 3+ nights in a single run | Encounter **The Coyote**, a one-time hidden NPC who trades you a unique card. |
| Hold 4 Aces at the start of a Day | Mose nods to you on your next saloon visit. (Pure flavor — but the player remembers it.) |

> **Full hidden trigger list** lives in a separate spoiler-sensitive doc, `docs/secrets/HIDDEN_TRIGGERS.md`, **not** to be referenced by player-facing strings.

#### 6.4.3 Why Hidden Triggers, Not Just More Set Bonuses

Set bonuses are *combinatorial puzzles* (collect 3 things). Hidden triggers are *attentive-play rewards* (do the right thing in the right place at the right time). The user explicitly called out the "Preacher's Coat in the graveyard → ghost" pattern as the feel target. Synergies are the floor; hidden triggers are the ceiling. v1.0 keeps both small and high-quality.

---

## 7. The Run Structure

### 7.1 Days & Phases

A run is broken into in-game **Days**. Each Day has four **Phases**:

| Phase | Window | Vibe |
|---|---|---|
| **Morning** | Civil society is awake | Banks open, sheriff alert, light is unforgiving |
| **Afternoon** | The town works | Mining, fishing, store hours, public spaces |
| **Evening** | Saloon hour | The saloon livens, sunset duels, fewer witnesses |
| **Night** | The dead time | Cemetery, hidden encounters, the church's true face |

#### Action Budget
- Each Phase allows **one Action** (a task or a travel-to-NPC interaction).
- Total: **4 Actions per Day** (down from the previous "8 soft budget" — a tighter, more deliberate pace).
- A few tasks are **multi-phase** (Rob the Bank, Mine the Old Shaft) and consume 2 Phases. The GDD task table marks these explicitly.
- **End of Night is a forced Rest** (see §7.2). The player does not choose to skip it.

#### Time-of-Day Restrictions

Each task is tagged with the Phases during which it is **available**. A task taken in the wrong Phase is grayed out in the location menu, with a small inline reason (*"Bank is closed."*).

| Task | Morning | Afternoon | Evening | Night |
|---|:---:|:---:|:---:|:---:|
| Pan for Gold | ✓ | ✓ | — | — |
| Mine the Old Shaft (2 phases) | ✓ | ✓ | — | — |
| Fish the Black Creek | ✓ | ✓ | ✓ | — |
| Rob a Grave | — | — | — | ✓ |
| Hold Up Stagecoach | ✓ | ✓ | ✓ | — |
| Rob the Bank (2 phases) | ✓ | ✓ | — | (Night Heist variant: ✓, ↑risk ↑reward) |
| Duel a Stranger | — | — | ✓ | — |
| Hunt a Bounty | ✓ | ✓ | ✓ | ✓ |
| Gamble at the Saloon | — | ✓ | ✓ | ✓ |
| Drink at the Saloon | — | ✓ | ✓ | ✓ |
| Bury for the Undertaker | — | ✓ | ✓ | ✓ |
| Visit the Church | ✓ | ✓ | — | (Night variant: cleanse ALL Jokers — see §6.4.2) |

> **Design note:** This is also a soft difficulty curve. Morning is safe but limited; Night is dangerous but holds the best rewards. A risk-averse player can win on day-jobs alone; an ambitious one chases the Night.

#### Inter-Phase Events
Between any two Phases, a **10% chance** of drawing an Encounter Card (§8). The chance rises to **30%** between Evening and Night.

### 7.2 Forced Rest at End of Night

After the Night Phase resolves, the player **must rest**. Choose where:

| Where | Cost | Effect |
|---|---|---|
| **Saloon Room** | $2 | Full HP recovery; small chance Mose drops a one-line gossip overnight |
| **Jail Cell** | Free | Full HP recovery; +1 Notoriety; lose Evening Encounter rewards |
| **Wilderness** | Free | Full HP recovery; draw **2 Evening Events**; chance of unique hidden trigger (§6.4.2) |
| **A friend's hayloft** | Hidden | Conditions undisclosed — but it's there |

### 7.3 Soft End Condition: The Bell

When the player accumulates **$50, at least 2 Aces, and a "Mayor's Token"** (drops from a single hidden task), the **church bell rings** at the start of the next day. The next sundown, the Mayor can be confronted.

The player can confront him earlier — but the Mayor's final phase locks out without all four Aces (see §10).

### 7.4 Run Failure

The run ends if:
- HP reaches 0 (death)
- Notoriety reaches 20 (hanged)
- The player chooses to "ride out" of Deadhand (cowardice ending)

On run end, accrued **Legacy Tokens** (1 per significant milestone hit) carry to the next run for meta-unlocks (§11).

---

## 8. Encounters (Event Cards)

Encounter cards are drawn at fixed beats: **start of each day**, **dusk**, **on critical failures**, **between any two tasks** (10% chance).

### 8.1 Sample Encounter Set (MVP: 20 cards)

| Encounter | Effect |
|---|---|
| **Lawman on the road** | ♥ Nerve DC 11. Fail = +2 Notoriety. Success = nothing. |
| **The drunk in the alley** | Initiate a contested duel (3 wounds). Win = $3. |
| **A stranger offers a deal** | Choose: take $5 and add 1 Joker, or refuse. |
| **The wind carries whispers** | Lore-only card. Reveals one line of mayor backstory. No mechanic. |
| **Old woman with a bundle** | $4 to buy "Locket (engraved 'E')." She doesn't say where she got it. |
| **A child watches you from the well** | Next ♥ Nerve check today is at DC +2. No other effect. |
| **You find a dead crow** | Add a single 1♣ "An omen, perhaps." to your discard pile. |
| **The undertaker has a private job** | Hidden task offered — burying a body that "wasn't supposed to come back." |
| **A storm rolls in** | Skip 1 Action this day. |
| **Camp visitors** | If sleeping in the wilderness: contested encounter with a low-tier outlaw. |
| **Faint smell of sulfur** | The Deadhand is closer than yesterday. Lore only. |
| **The piano stops mid-song** | The saloon empties. Bartender vanishes. Lore + you can't buy drinks for the rest of the day. |
| **A pact, freely offered** | Pay 1 HP. Receive a wild card of your choice. |
| **Wanted poster torn down** | Your Notoriety -1. Someone is on your side. |
| **A funeral procession passes** | All ♥ Nerve checks today at DC -1. The town remembers. |
| **The mayor's deputy nods at you** | If Notoriety ≥ 5, forced lawman fight. Otherwise: nothing. He just nods. |
| **An empty grave** | A grave you previously robbed is empty even of its dirt. You feel watched. Add 1 Joker. |
| **A song on the wind** | If you have any Heart Aces, draw a card. Otherwise, nothing. |
| **Coins in the dirt** | $1–$3 found. No check. |
| **Eight of Spades, lying face-up in the road** | The town remembers Hickok. Reveal: the Mayor's secret advances one step. |

---

## 9. NPCs

Two named NPCs. Both speak in fragments. Most of what they say is *not* repeated — listen the first time.

### 9.1 The Bartender (Mose)
- **Location:** The Saloon.
- **Function:** Sells drinks. Sells gossip (occasionally; once per day, a single one-liner about the Mayor or the town).
- **Tone:** Quiet, watchful, never blinks first.
- **Sample lines (one per visit):**
  - *"He don't drink. I serve him anyway."*
  - *"That hand on the floor — eight of spades, ace of spades. Don't look at it after dark."*
  - *"Sheriff before this one was named Coltrane. Folks said he was a good man. Past tense."*
  - *"Elise was somebody once. Ask the locket."*
- **Story role:** The closest thing to an ally. May offer a hidden task ("Settle the upstairs room — the man up there has been quiet too long") that pays in Aces.

### 9.2 The Undertaker (Coffin Ann)
- **Location:** The Cemetery.
- **Function:** Buys grave goods. Offers hidden tasks. Can remove a Joker from your deck for a steep price (a face card you own + $10).
- **Tone:** Practical, blunt, gallows-humored.
- **Sample lines:**
  - *"Six feet's the law. Eight's the custom. Ten's for them that bit."*
  - *"You bring me what they were holding. The dirt I keep."*
  - *"He's buried three wives. I dug two of 'em. Third one — he insisted. Personal touch."*
  - *"That hand under the church ain't a hand. Don't ask what it is. Ask what it wants."*

### 9.3 Non-Speaking "NPCs" (Shop UI Only)
- **Store Clerk** — silent. UI only.
- **Sheriff** — wordless. Posts bounties. Takes your money. The Mayor's man.

---

## 10. The Mayor — Final Boss

### 10.1 Approach
After the bell rings (§7.3), the player can confront the Mayor at sundown by entering the Town Hall.

### 10.2 Three Phases

#### Phase 1: The Deputies (Contested, 2v1)
- Two lawmen draw from a shared 18-card deck weighted toward ♠ Spades.
- Player wound limit: 4. Deputy combined wound limit: 5.
- Standard contested rules over 4 shots.

#### Phase 2: The Mayor (Contested, ♥ Nerve)
- The Mayor draws from a 20-card deck heavy in Hearts and Aces.
- Player wound limit: 3. Mayor wound limit: 4.
- **Bust line: 21.** Both sides bust if combined revealed totals exceed 21 across the encounter. This forces tight play.
- The Mayor *never plays a Joker.* If the player has Jokers in deck, they will appear.

#### Phase 3: The Deadhand (Only If Player Has All Four Aces)
If the player enters Phase 3 missing any Ace, the Mayor "wins by default" at the end of Phase 2 — the player has wounded him, but he survives. The town remains his. Run ends with the **"Half-Victory"** ending.

If all four Aces are held:
- The Mayor reveals what he is bound to. A black hand rises from under the Town Hall floor.
- A unique contested encounter: **player vs. the Deadhand itself.**
- The Deadhand's deck contains **only face cards and Aces, including stolen copies of any face cards the player has ever played.**
- Player wound limit: 5. Deadhand wound limit: 8.
- Bust line: 30.
- On victory: **"True Ending."** The town survives. The player rides out. A child in the street is heard humming a song the player never taught anyone.

### 10.3 Endings

| Ending | Trigger |
|---|---|
| **Half-Victory** | Beat the Mayor without all 4 Aces |
| **True Ending** | Beat the Deadhand |
| **Cowardice** | Voluntarily ride out of Deadhand |
| **The Rope** | Notoriety 20 |
| **The Dirt** | HP 0 |
| **The Bargain** *(hidden)* | Accept a specific late-game offer from the Deadhand (player becomes the new Mayor — unlocks alternate starter deck) |

---

## 11. Meta-Progression (Between Runs)

Light, optional, and never required to win. Inspired by *Hades* and *Inscryption*.

### 11.1 Legacy Tokens
Earned 1 per significant first-time milestone:
- First time hitting each task
- First time meeting each NPC
- First time finding each named item
- Each ending reached

### 11.2 Unlocks (Spent at the title-screen "Saddlebag")

| Cost | Unlock |
|---|---|
| 3 | Starter deck variant: **"The Prospector"** (Spades-heavy, +1 starting nugget) |
| 3 | Starter deck variant: **"The Drifter"** (Clubs-heavy, +1 starting drink) |
| 5 | Starter deck variant: **"The Widow"** (Hearts-heavy, starts with K♥ The Preacher) |
| 5 | Permanent +1 starting cash ($3 instead of $2) |
| 8 | Journal: a separate menu where lore fragments collected across all runs are preserved |
| 10 | New ending unlocked: **The Bargain** path becomes selectable |
| 12 | Starting card removal: begin runs with one weak card already burned out of deck |

> **Hard limit:** Meta-unlocks **never** add raw power. They add **options.** A new player and a 50-run veteran face the same Mayor.

---

## 12. Art Direction

### 12.1 Card Art
- **1800s engraved-playing-card style.** Single-color line art (sepia, faded indigo, oxblood red) on tinted parchment.
- Reference: Bicycle "Vintage 1800" deck, antique tarot (Etteilla, Sola Busca), 1860s woodcuts, vintage wanted posters.
- Every named card (face cards, Aces, items) has unique illustration.
- Number cards use **classical pip arrangements** with subtle illustrated borders unique per suit.
- Jokers: **the Grinning Fool** is a hanged jester; **the Hangman's Smile** is a noose tied into a smile.

### 12.2 Locations (Static Painted Backdrops)
Each Deadhand location is a single hand-painted scene shown when the location is "active." No animation required for MVP.
- The Saloon — interior, warm orange lamplight, piano in the corner
- The Cemetery — twilight, leaning headstones, the church steeple in the distance
- The Bank — mahogany, brass bars, a portrait of the Mayor on the wall
- The Creek — dawn fog, a single fishing pole in the dirt
- The Old Shaft — black cavern mouth, lantern light
- The Sheriff's Board — splintered wood, wanted posters layered three deep
- The Church — interior, single shaft of dust-light, an altar that looks wrong
- The Town Hall — exterior locked until the bell rings; interior unique to final fight

### 12.3 UI
- Brown leather background with stitched edges
- Oil-lamp-gold text and accents
- Blood-red highlights for danger / failure
- Typography: a slab serif for headers (Playbill / Clarendon family), a humanist serif for body
- Cards in hand: arranged in a fan, slight tilt; played cards slide to a center "table"
- Minimal animation: 80ms slide-in, 150ms reveal flip, that's it. No particle effects.

### 12.4 Color Palette (working)
- Parchment: `#E6D6B4`
- Ink: `#231A12`
- Sepia line: `#6B4A2B`
- Oil-lamp gold: `#C99A3D`
- Blood: `#7A1818`
- Bone: `#E2DCC8`

---

## 13. Audio Design

### 13.1 Music (4 tracks for MVP)
- **Town theme** — fingerpicked acoustic guitar, lonely whistle, slow shuffle
- **Saloon theme** — honky-tonk piano in another room, muffled
- **Tension** — sparse, dread-leaning strings; plays in cemetery and at dusk
- **The Mayor** — dirge with a single dissonant pump organ underneath

### 13.2 SFX (small but essential)
- Card draw (single paper slip)
- Card play (slap on wood table)
- Card reveal (sharp flip)
- Coin clink (variable pitch)
- Six-shooter (close + distant variants)
- Wound (low thud + sharp inhale)
- Death rattle (final defeat)
- Wind through wooden walls
- The Deadhand: not a sound effect. A **stop**. All ambient cuts out the instant the hand appears.

### 13.3 Voice
- **No spoken dialogue.** All NPC lines are text-only, rendered with a typewriter effect at ~30 cps. NPC text is accompanied by a single muted instrument tone per character (Mose = low piano note, Coffin Ann = bell).

---

## 14. Controls

### 14.1 Mouse + Keyboard (Primary)
| Action | Input |
|---|---|
| Select location | Click |
| Select card | Hover (highlights), Click (selects) |
| Play selected card | Click "Play" button or drag to table |
| End turn / commit play | Spacebar or "Commit" button |
| Cancel selection | Right-click or Escape |
| Pause | Escape |
| Open journal | J |
| Open deck inspector | D |

### 14.2 Gamepad (Steam Deck Target)
| Action | Input |
|---|---|
| Navigate locations / cards | D-pad or left stick |
| Select | A |
| Cancel / back | B |
| Open deck inspector | Y |
| Open journal | X |
| End turn / commit | Right trigger |
| Pause | Start |

All UI navigable without a pointer. No drag-to-play required (gamepad uses Select → Commit).

---

## 15. Technical Design

All engine, framework, architecture, schemas, event bus, replay/logging, CLI test harness, and the Slay-The-Robot integration plan live in [`TDD.md`](TDD.md). This GDD intentionally contains **no engine-specific decisions** — they belong in the technical doc so they can evolve without re-litigating the design.

Key technical commitments referenced by this GDD:
- **Engine:** Godot 4.4+
- **Foundation:** [DesirePathGames / Slay-The-Robot](https://github.com/DesirePathGames/Slay-The-Robot) (MIT) — see [`adr/0001-card-framework-choice.md`](adr/0001-card-framework-choice.md)
- **Determinism:** all randomness seeded; runs are fully replayable from event log
- **Modularity:** systems are black-box modules with explicit input/output contracts (TDD §3)
- **Testability:** a CLI harness lets agents play full runs from the terminal for automated scenario testing (TDD §6)

---

## 16. MVP Scope & Cut List

### 16.1 In Scope (Ship v1.0)
- 1 town (Deadhand) + Outskirts road (no real travel — locations are menu entries)
- 12 tasks
- 20 encounter cards
- ~60 named cards (16 face cards, 4 Aces, 2 Jokers, ~38 items)
- 6 clothing items (2 hats, 2 bodies, 2 boots) + 1 set bonus
- 7 drinks
- 2 NPCs (Mose, Coffin Ann)
- 3 endings (Half-Victory, True, Death) + 2 trivial endings (Cowardice, Rope)
- 4 starter deck variants (1 default + 3 unlockable)

### 16.2 Out of Scope for v1.0 (Wishlist)
- Travel to other towns
- Mounted gameplay / horse cards
- Seasonal/holiday events
- Steam Workshop / custom encounter cards
- Daily-seeded run with leaderboard
- More NPCs (the Preacher, the Schoolmarm, the Drifter who comes back)
- The Bargain ending fully fleshed (locked behind a single meta-unlock; v1.1)

### 16.3 If We Run Long, Cut These First (in order)
1. The Bargain ending — defer to v1.1
2. Two of the four starter deck variants
3. Notoriety system (replace with a simpler "wanted: yes/no")
4. Set bonuses on clothing
5. The Church task / Joker cleansing (Coffin Ann becomes the only path)
6. Phase 3 (Deadhand) — collapse into Mayor's final phase (still keeps "all 4 Aces" gating)

### 16.4 Target Timeline (Rough)
| Phase | Weeks | Output |
|---|---|---|
| Pre-production / prototyping | 1–2 | Card data structures, hand UI, solo skill check working end-to-end |
| Vertical slice | 2–3 | Saloon + Cemetery + Mining + 1 NPC + 1 contested encounter |
| Content expansion | 3–4 | All 12 tasks, all encounters, all named cards, clothing & drinks |
| Mayor + endings | 1–2 | All three phases, all endings, polish |
| Polish / balance | 1–2 | Audio pass, balance pass, achievements, controller polish |
| **Total** | **~8–13 weeks** | **v1.0** |

---

## 17. Open Questions / TBD (Design)

Items the *design* has not yet decided. Each will be resolved before or during prototyping. Engineering open questions live in `TDD.md` §11.

- [ ] Final value of "off-suit" cards in checks — half-rounded-down vs. zero contribution. Prototype both, A/B test feel.
- [ ] Whether unplayed cards persist between encounters within a Phase, or reshuffle each encounter. (Currently: persist.)
- [ ] Should the player be able to discard from hand voluntarily for a cost? (Currently: no.)
- [ ] Daily seeded runs with shared leaderboard — v1.1 candidate.
- [ ] Final pricing tier ($9.99 vs. $12.99 — both reasonable for a deckbuilder).
- [ ] Does the Sheriff have a name? (I think not. The town has erased it.)
- [ ] How many hidden triggers in v1.0 — currently targeting 8. Could float to 5 or 12 depending on art bandwidth.
- [ ] Should Hidden Trigger discovery notifications appear in the Journal once unlocked, or remain ephemeral?

---

## 18. Competitive Landscape

| Title | Overlaps With Deadhand | Where Deadhand Diverges |
|---|---|---|
| *Slay the Spire* | Deckbuilding roguelike, encounter loop, run length | Story is forefronted; not combat-only; western tone |
| *Inscryption* | Card-driven dark narrative | Inscryption is meta-horror; Deadhand is a straight period piece with quieter dread |
| *Hand of Fate 1/2* | Card-driven RPG, encounters as cards, town map | Hand of Fate has real-time combat; Deadhand is fully card-resolved |
| *West of Loathing* | Western tone, comedic flavor | Deadhand is not comedic; it is grim with gallows humor |
| *Weird West* | 1800s dark-fantasy west | Weird West is action-RPG; Deadhand is turn-based cards |
| *Reigns* | One-screen choice game | Reigns is binary swipes; Deadhand is full skill resolution |

**The gap Deadhand fills:** A *short, atmospheric, single-player deckbuilder where the cards are real playing cards and the resolution feels like a tabletop skill check, set in a Souls-style western that tells its story sideways through flavor text.*

---

## 19. Appendix: Pillars

If a design question can't be resolved, return to these.

1. **The cards are the game.** Every interaction is a card. Resist the urge to invent non-card systems.
2. **A turned card is heavy.** Slow reveals, single sounds, no particle storms.
3. **Story is whispered, not told.** No cutscenes, no monologues. The player is doing detective work the whole time.
4. **A run is a campaign.** 30–60 minutes from $2 to the Mayor. Not a 10-minute arcade run; not a 20-hour CRPG.
5. **The player is not a hero.** The player is *the lesser monster.* The town will not thank them.
6. **Ship lean.** Better to launch a 12-task game that's tight than a 40-task game that's not.

---

*GDD maintained by the Deadhand development team. Update as design decisions are finalized.*
