# Deadhand — Card List (v1.0)

**Version:** 0.1
**Date:** 2026-06-15
**Status:** Draft — canonical source for card JSON generation
**Cross-references:** [`GDD.md`](../GDD.md) §3, §6 · [`TDD.md`](../TDD.md) §9

---

## 1. Header & Purpose

This document is the **canonical card list** for *Deadhand* v1.0. Every card the player can ever hold — number, face, Ace, Joker, Sting, item-reskin, Memory — is enumerated here in design form. Their JSON resources (per [`TDD.md`](../TDD.md) §9.1 / §9.2) will be generated from these tables. Equipment that does not enter the deck (Clothing) and the named Set bonuses are included for completeness because they are referenced by card-side mechanics.

This file is design content, not code. If a value, suit, or effect conflicts with the GDD, the GDD wins; open a ticket and amend this file. If the GDD is silent and this file resolves an ambiguity, the resolution is noted inline (look for *Resolved ambiguity:*).

Section numbers below match the GDD's where possible for easy cross-reference.

---

## 2. Number Cards — The Boring Backbone (36)

The starter deck (24 cards) is composed of **2–7 of each suit**. Cards **8–10** of each suit exist in the data set but enter the player's deck only through items, drinks, encounters, or unlocked starter variants.

Each number card contributes its full face value when its suit matches the task's primary suit; otherwise it contributes value ÷ 2, rounded down (GDD §4.1).

Several "raw" number cards have **item-reskinned variants** (§7). The variant is a *separate card resource* with its own id and flavor — the raw card still exists in the data set. Variants are noted in the **Variants** column.

### 2.1 Spades ♠ — Grit

| id | suit | rank | flavor | variants |
|---|---|---|---|---|
| `2_spades` | spades | 2 | "Light work. The kind that buries you slow." | — |
| `3_spades` | spades | 3 | "He swung three times and called it a day." | — |
| `4_spades` | spades | 4 | "Four hands on the rope. The fifth was the sheriff's." | — |
| `5_spades` | spades | 5 | "The pick wears smooth where the hands have been." | — |
| `6_spades` | spades | 6 | "A grave for the strong. Folks dig their own here." | — |
| `7_spades` | spades | 7 | "Heavy enough to feel. Not heavy enough to drop." | — |
| `8_spades` | spades | 8 | "Eight of spades, lying face-up in the road." | `item_old_revolver` |
| `9_spades` | spades | 9 | "Nine feet. One too deep, by Ann's measure." | `drink_whiskey_courage`, `sting_iron_in_the_teeth` |
| `10_spades` | spades | 10 | "Ten for them that bit. Coffin Ann said so." | `drink_bourbon_warmth` |

### 2.2 Hearts ♥ — Nerve

| id | suit | rank | flavor | variants |
|---|---|---|---|---|
| `2_hearts` | hearts | 2 | "She did not weep. That was the first sign." | — |
| `3_hearts` | hearts | 3 | "Three breaths before he drew. He counted them all." | — |
| `4_hearts` | hearts | 4 | "Four candles, always four. The fifth was Elise's." | — |
| `5_hearts` | hearts | 5 | "He held his ground. The other man did not." | — |
| `6_hearts` | hearts | 6 | "The widow on the porch nods. She does not wave." | `drink_sasparilla` |
| `7_hearts` | hearts | 7 | "A Sunday in a town that forgot the Sabbath." | `item_pocket_bible` |
| `8_hearts` | hearts | 8 | "Aces and eights. Folks know which is which." | — |
| `9_hearts` | hearts | 9 | "Stare him down. Don't blink. Not even for the wind." | — |
| `10_hearts` | hearts | 10 | "Coltrane was a good man. Past tense. Mose said so." | — |

### 2.3 Diamonds ♦ — Cunning

| id | suit | rank | flavor | variants |
|---|---|---|---|---|
| `2_diamonds` | diamonds | 2 | "A bent nail will open most doors in Deadhand." | — |
| `3_diamonds` | diamonds | 3 | "He counted the guards. Then he counted them twice." | — |
| `4_diamonds` | diamonds | 4 | "Four ledgers in the back room. Only one is true." | — |
| `5_diamonds` | diamonds | 5 | "The tinker came through last spring. Hasn't been back." | `item_snake_oil` *(see §7 note)* |
| `6_diamonds` | diamonds | 6 | "He smiled at the lie. He always does." | — |
| `7_diamonds` | diamonds | 7 | "The forger never signed his own name." | — |
| `8_diamonds` | diamonds | 8 | "Patient men own this town. The other kind hang in it." | — |
| `9_diamonds` | diamonds | 9 | "The lock gave first. The dog, second." | `item_lockpicks` |
| `10_diamonds` | diamonds | 10 | "Long con. Longer rope." | — |

### 2.4 Clubs ♣ — Luck

| id | suit | rank | flavor | variants |
|---|---|---|---|---|
| `2_clubs` | clubs | 2 | "A penny in the dust. Bend down or walk on." | `item_lucky_penny`, `sting_hangmans_penny` |
| `3_clubs` | clubs | 3 | "Three coins left in the dirt. He took two." | — |
| `4_clubs` | clubs | 4 | "Mose deals four. The fifth, he keeps." | — |
| `5_clubs` | clubs | 5 | "Watered down. Still counts toward a hand." | `drink_beer` |
| `6_clubs` | clubs | 6 | "A poor hand and a longer night." | `item_bone_dice` |
| `7_clubs` | clubs | 7 | "Lucky for some. The Drifter never said which." | `sting_drifters_coin_gambit` |
| `8_clubs` | clubs | 8 | "Four of a kind beats most things. Not this town." | — |
| `9_clubs` | clubs | 9 | "He drew once. Once was enough." | — |
| `10_clubs` | clubs | 10 | "Pot's too rich for an honest man. Mose's words." | — |

**Section total: 36 number cards.**

---

## 3. Face Cards (12)

Face cards are **named, illustrated, single-copy** ability cards. They are not in the starter deck; the player acquires each through a specific task, encounter, or item drop. Effect text is reproduced verbatim from GDD §3.4; source columns are the routes the player can acquire each in a run.

### 3.1 Spades ♠ — Grit

| id | rank | value | effect | source | flavor |
|---|---|---|---|---|---|
| `j_spades_bowie` | J | 11 | +3 to a Grit check. If you win, deal a wound to the opponent (contested only). | First acquisition of `item_old_revolver`; rare drop from Hold Up Stagecoach success. | "Found in the dirt under a hanged man." |
| `q_spades_hangmans_knot` | Q | 12 | Counts as 12 Grit. If played in a duel, opponent skips next round. | Drop from Bury for the Undertaker after a critical success; Coffin Ann sets it on the bar without a word. | "Thirteen turns of the rope. Ann always counts." |
| `k_spades_old_iron` | K | 13 | Counts as 13 Grit. Once per encounter, replays itself for free. | Rare drop from Mine the Old Shaft (critical success); drops with a note from the previous owner's pocket. | "Held by three sheriffs. Buried with the second." |

### 3.2 Hearts ♥ — Nerve

| id | rank | value | effect | source | flavor |
|---|---|---|---|---|---|
| `j_hearts_cold_stare` | J | 11 | +2 Nerve. Forces opponent to discard one card. | Drop from Duel a Stranger (first win); also dropped by certain bounty targets. | "He blinked first. He was the only one." |
| `q_hearts_widows_veil` | Q | 12 | +2 Nerve. Heal 1 wound after the encounter. | Drop from Rob a Grave at a wife-grave (Cemetery, night, ≥3 successful grave-robs). | "Three wives buried. Two she dug herself." |
| `k_hearts_preacher` | K | 13 | +3 Nerve. Cleanse one Joker from your deck if you win. | Drop from Visit the Church (success). Starting card for the **Widow** starter deck variant. | "He read scripture over a hole he wouldn't look in." |

### 3.3 Diamonds ♦ — Cunning

| id | rank | value | effect | source | flavor |
|---|---|---|---|---|---|
| `j_diamonds_picklock` | J | 11 | +2 Cunning. Reveals one of opponent's face-down cards. | First acquisition of `item_lockpicks`; alternate drop from Rob the Bank stage 1. | "Tumblers click for those who listen." |
| `q_diamonds_forged_letter` | Q | 12 | +2 Cunning. Lets you treat one off-suit card as Diamond this check. | Drop from Rob the Bank (vault loot, critical success). | "Signed in a hand the dead can no longer claim." |
| `k_diamonds_long_shadow` | K | 13 | +3 Cunning. Once per run, skip a contested encounter without losing rewards. | Drop from Hunt a Bounty on a high-tier (Notoriety ≥ 8) target. | "He walked the back streets. He never turned around." |

### 3.4 Clubs ♣ — Luck

| id | rank | value | effect | source | flavor |
|---|---|---|---|---|---|
| `j_clubs_loaded_dice` | J | 11 | +2 Luck. Re-draw your hand. | Drop from Gamble at the Saloon (3rd consecutive win in a single run). | "Mose smiled the once. Folks still talk about it." |
| `q_clubs_lady_fortune` | Q | 12 | +3 Luck. Add a random Ace to your hand. | Critical-success drop from Gamble at the Saloon at $20+ stake. | "She kissed Hickok the night he laid them down." |
| `k_clubs_drifters_coin` | K | 13 | +2 Luck. Flip: heads = double reward, tails = double risk. | Drop from the hidden **Coyote** encounter (Wilderness, 3+ nights slept rough; GDD §6.4.2). | "Found at a crossroads. Gone before sunrise." |

**Section total: 12 face cards (3 per suit × 4 suits).**

---

## 4. Aces — The Dead Man's Hand (4)

The four Aces are wild (any value 1–14 of their suit) and each carries a unique on-play effect (GDD §3.5). Each Ace drops from exactly one **named encounter** — never from a shop, never from a routine task. Collecting all four in one run unlocks the Mayor's Phase 3 fight (GDD §10.2).

### 4.1 A♠ — Ace of Spades

| field | value |
|---|---|
| id | `a_spades_mayors_mark` |
| suit | spades |
| value rules | Wild 1–14 of any suit (player declares on play). |
| effect | When played, "burn" one card from your discard pile out of the run. |
| source encounter | **"The Sheriff's Last Stand."** Sheriff Coltrane drew on the Mayor on a quiet Tuesday. The town never spoke of it again. The card is in the dirt where he fell, face-up. |
| flavor | "He wore the Mayor's mark and called himself the law." |

### 4.2 A♥ — Ace of Hearts

| field | value |
|---|---|
| id | `a_hearts_widow_keepsake` |
| suit | hearts |
| value rules | Wild 1–14 of any suit. |
| effect | After playing, heal 2 wounds. |
| source encounter | **"The Widow on the Porch."** The Mayor's third wife stood up from her rocking chair, walked out onto the porch, and laid this card on the rail. She did not go back inside. |
| flavor | "He took her name and gave her this in its place." |

### 4.3 A♦ — Ace of Diamonds

| field | value |
|---|---|
| id | `a_diamonds_forgers_last_work` |
| suit | diamonds |
| value rules | Wild 1–14 of any suit. |
| effect | When played, draw 2 cards. |
| source encounter | **"The Hanged Forger."** A man in the Old Shaft, swung from a beam by his own neat handwriting. The card is folded into his vest pocket, signed on the back in a name that does not match his own. |
| flavor | "He could sign any name. His own took the longest." |

### 4.4 A♣ — Ace of Clubs

| field | value |
|---|---|
| id | `a_clubs_drifters_promise` |
| suit | clubs |
| value rules | Wild 1–14 of any suit. |
| effect | When played, the **next** reward this encounter is doubled. |
| source encounter | **"The Drifter at the Crossroads."** A stranger plays one hand at the Saloon, wins it, walks off into the dust without his coat. He leaves the Ace on the table, face-down. |
| flavor | "Heads or tails, he never said which way it landed." |

**Section total: 4 Aces.**

---

## 5. Jokers — The Pure Curses (2)

Jokers are pure curse cards: worth 0, never desirable, only acquired through narrative or supernatural channels (GDD §3.6). **Drinks NEVER add Jokers.** Drinks add Sting Cards (§6). This is a hard design rule — a player should never feel punished for visiting the saloon.

### 5.1 Red Joker — Grinning Fool

| field | value |
|---|---|
| id | `joker_grinning_fool` |
| value | 0 |
| effect | If drawn into hand during a contested encounter, opponent draws an extra card next round. |
| sources | Lose the **Whiskey Ghost** encounter (5+ whiskeys in a run); accept the **Pact, Freely Offered** encounter for HP→wild trade; equip `clothing_dead_mans_boots` (auto-adds one Red Joker at the start of each new day). |
| flavor | "Hung him by his bells. He's still smiling." |

### 5.2 Black Joker — Hangman's Smile

| field | value |
|---|---|
| id | `joker_hangmans_smile` |
| value | 0 |
| effect | When held in hand at the end of an encounter, take 1 wound. |
| sources | Lose at **Visit the Church** (Morning/Afternoon); draw the **Empty Grave** encounter after robbing a specific cemetery plot; sign the ledger in the **A Stranger Offers a Deal** encounter (+$5, +1 Joker). |
| flavor | "The knot does the work. The man does the laughing." |

**Removal paths** (re-stated from GDD §3.6 for designer convenience — these are not card data, but the cards' removal options must be representable):
- Win at the Church (Night-only hidden task) → cleanse all Jokers.
- Play `k_hearts_preacher` after winning an encounter → cleanse one Joker.
- Pay Coffin Ann (one face card you own + $10) → remove one Joker.

**Section total: 2 Jokers.**

---

## 6. Sting Cards — Drink-Origin and Other Tradeoffs (12)

Sting cards (GDD §3.7) are tradeoff cards: a real, playable number/Ace value with a tagged **rider** effect that fires on play. Mechanical text below is exact and parseable. All Drink-origin cards carry the hidden `drink` tag (GDD §6.3) which feeds the **Drinker** synergy (§11.3).

Sting cards are always playable. The rider is always quantifiable.

### 6.1 Drink-Origin Sting Cards (7)

| id | display name | suit | rank | value | rider | tags | source | flavor |
|---|---|---|---|---|---|---|---|---|
| `drink_beer` | Beer | clubs | 5 | 5 | *(none)* | `drink` | Saloon, $1. | "Watered down. Still counts toward a hand." |
| `drink_sasparilla` | Sasparilla | hearts | 6 | 6 | *(none)* | `drink` | Saloon, $2. | "Nobody mocks you for it." |
| `drink_whiskey_courage` | Whiskey Courage | spades | 9 | 9 | When played, take 1 wound at the **end of encounter**. (Softened by `set_drinker` to "end of next encounter.") | `drink` | Saloon, $3. | "Burns going down." |
| `drink_bourbon_warmth` | Bourbon Warmth | spades | 10 | 10 | When played, this card cannot be discarded by other effects for the rest of the encounter. | `drink` | Saloon, $4. | "Warms you. Most of the way." |
| `drink_laudanum_sleep` | Laudanum Sleep | hearts | 14 *(wild ace)* | wild 1–14 | When played, skip drawing for one round. | `drink`, `wild_ace` | Saloon, $5. | "Sleep. Dreamless." |
| `drink_cursed_whiskey` | Cursed Whiskey | spades | 13 | 13 | One-shot. When played, this card is burned out of the run after resolving. | `drink` | Saloon, $4 (only stocked some nights). | "It tasted like grave dirt." |
| `drink_bartenders_special` | The Bartender's Special | *random* | 14 *(wild ace)* | wild 1–14 | When played, draw the next card **face-down**; its value is not revealed until played. | `drink`, `wild_ace` | Saloon, $10. Mose grins. | "He didn't ask what was in it. Mose didn't say." |

> *Resolved ambiguity:* Beer and Sasparilla have no rider but are still represented as Sting Cards (per GDD §6.3's blanket statement that every drink enters the deck as a Sting Card). Their `sting_rider` field is `null` in JSON. This keeps the `drink` tag attached so Drinker synergy counts them.

### 6.2 Non-Drink Sting Cards (5)

These are sting cards that come from risky narrative choices, critical-failure rewards, and a few specific items. They are lore-consistent with the GDD's listed sources (GDD §3.7: "Risky narrative choices," "Critical-failure rewards," "A few specific items").

| id | display name | suit | rank | value | rider | tags | source | flavor |
|---|---|---|---|---|---|---|---|---|
| `sting_snake_oil_vigor` | Snake Oil Vigor | diamonds | 5 | 5 | When played, the next card you reveal this encounter is at **half value, rounded down.** | `item`, `snake_oil` | Acquired via `item_snake_oil` (the tinker's wagon, store consumable). See §7 note. | "Cures what the seller named." |
| `sting_drifters_coin_gambit` | The Drifter's Coin (Gambit) | clubs | 7 | 7 | When played, flip a coin: heads = +5 to the check, tails = −3. | `narrative`, `coin` | Risky narrative choice: "Pocket the strange coin?" appears after the Drifter-at-the-Crossroads encounter. | "Sure feels heavy in the pocket." |
| `sting_hangmans_penny` | The Hangman's Penny | clubs | 2 | 2 | When played, +1 Notoriety this run. | `narrative` | Risky narrative choice: kicking a coin out of the dirt at the gallows on the way past. | "Bend down or walk on. He bent down." |
| `sting_iron_in_the_teeth` | Iron in the Teeth | spades | 9 | 9 | In a contested encounter, if you win the shot the loser takes **2 wounds** instead of 1; if you lose the shot, **you** take 2 wounds instead of 1. | `narrative` | Critical-failure reward from Mine the Old Shaft ("You missed — but the recoil knocked something loose. Take this.") | "Bit down on it. Couldn't say why." |
| `sting_strangers_promise` | A Stranger's Promise | clubs | 14 *(wild ace)* | wild 1–14 | When played, add a `joker_grinning_fool` to your discard pile. *(Only sting card in the game that adds a Joker — the player chose this with eyes open.)* | `narrative`, `wild_ace` | Acquired from accepting the **A Pact, Freely Offered** encounter at the cost of 1 HP. | "He paid HP for it. He didn't ask the rest." |

> *Resolved ambiguity:* `sting_strangers_promise` is the *only* sting card that adds a Joker. The GDD treats this as a narrative-channel acquisition (§3.6), not a "drink" channel, so the design rule "drinks never add Jokers" remains intact. The card is explicitly flagged so JSON consumers can apply the correct UI treatment.

**Section total: 12 sting cards** (7 drink + 5 non-drink). The "~10–12" target in the deliverable is met at the upper bound.

---

## 7. Item-Reskin Cards (7)

Items in GDD §6.1 add a card to the deck. Most are flavored reskins of a "raw" number card; one (the Locket) adds a Memory card (§8). Item-reskins are *separate card resources* with their own ids; the raw number card still exists.

| id | functions as | item that adds it | source flavor | flavor |
|---|---|---|---|---|
| `item_bone_dice` | 6♣ (clubs, rank 6, value 6) | **Bone Dice** | Loot table: Rob a Grave; rare Mine drop. | "It rattles like teeth." |
| `item_pocket_bible` | 7♥ (hearts, rank 7, value 7) | **Pocket Bible (well-thumbed)** | Loot table: Rob a Grave at a preacher's plot; church reward on first success. | "The page is bookmarked at Lamentations." |
| `item_old_revolver` | 8♠ (spades, rank 8, value 8). Also unlocks `j_spades_bowie` into the deck on the **first** acquisition in a run. | **Old Revolver** | Loot table: Hold Up Stagecoach; Sheriff's Board reward for a high-tier bounty. | "Six chambers. Five rounds." |
| `item_lockpicks` | 9♦ (diamonds, rank 9, value 9). Also unlocks `j_diamonds_picklock` into the deck on the **first** acquisition in a run. | **Lockpicks** | Loot table: Rob the Bank stage 1; Coffin Ann's back-of-shop. | "Cleaner work than a crowbar. Quieter." |
| `item_lucky_penny` | 2♣ (clubs, rank 2, value 2) | **Lucky Penny** | Loot table: Gamble at the Saloon (low tier); the **Coins in the Dirt** encounter. | "It came from a stranger's eyes." |
| `item_snake_oil` | 5♦ — *delivered as `sting_snake_oil_vigor`* (see §6.2). The base item shuffles the **sting** version into the deck, not a plain 5♦. | **Snake Oil** | Store purchase ($3); the tinker's wagon when it returns. | "Cures what the seller named." |
| `item_locket` | *Memory card.* Adds `memory_locket_elise` (§8). Does **not** function as a number card. | **Locket (engraved 'E')** | Encounter: **Old Woman with a Bundle** ($4); rare drop from a wife-grave. | "Engraved E. Light as a moth." |

> *Resolved ambiguity:* The GDD lists "Snake Oil" in §6.1 as a plain 5♦ reskin *and* lists "Snake Oil Vigor" in §3.7 as a sting card example. This file resolves the inconsistency by treating the Snake Oil item as delivering the **sting** version of the card (`sting_snake_oil_vigor`). The "plain" 5♦ remains available as the raw `5_diamonds` from the starter deck. JSON generation should *not* produce two near-identical 5♦ resources.

**Section total: 7 item-reskin cards** (6 number-card reskins + 1 Memory-card item).

---

## 8. Memory Cards (5)

Memory cards (GDD §6.1, sub-section) are one-shot lore cards. The first time drawn: reveal, show the lore snippet, **free draw replacement**, then burn out of the deck for the rest of the run. The snippet is permanently added to the **Journal** (meta-progression unlock, GDD §11). Memory cards never appear twice in the same run.

In JSON, Memory cards carry `is_memory: true` (extension to the §9.1 schema; TDD §9.1 reserves `tags` for this — these cards will be tagged `memory`).

### 8.1 `memory_locket_elise`

| field | value |
|---|---|
| id | `memory_locket_elise` |
| source item | `item_locket` (Locket, engraved 'E') |
| lore snippet | "A daguerreotype the size of a thumbnail. A young woman, dark hair, one earring missing. On the back, scratched with a pin: ELISE — TUESDAY." |
| journal entry unlocked | *journal/elise_01* — "Whoever Elise was, somebody loved her enough to carry her on Tuesdays." |

### 8.2 `memory_coltranes_star`

| field | value |
|---|---|
| id | `memory_coltranes_star` |
| source item | **Bent Star** (drops from Rob a Grave at the old sheriff's plot, Cemetery, Night) |
| lore snippet | "Six points, one bent. The pin is brown with old blood. No name engraved — none was needed." |
| journal entry unlocked | *journal/coltrane_01* — "Mose said the sheriff before this one was a good man. Past tense." |

### 8.3 `memory_three_wives`

| field | value |
|---|---|
| id | `memory_three_wives` |
| source item | **Water-Stained Newspaper** (encounter drop: alternate path of *Old Woman with a Bundle*; Bank vault loot) |
| lore snippet | "Three weddings in the *Deadhand Banner*, ten years apart. The same groom each time. Different brides. The print blurs on the third announcement, as if it had been wet when it was set." |
| journal entry unlocked | *journal/wives_01* — "He buried three. Coffin Ann dug two of them. The third, he insisted on himself." |

### 8.4 `memory_childs_drawing`

| field | value |
|---|---|
| id | `memory_childs_drawing` |
| source item | **A Child's Drawing** (drops from Rob a Grave at a small grave) |
| lore snippet | "Stick figures of a town. Stick figures of people. Beneath the church, drawn larger than any person, a hand — fingers spread, reaching up." |
| journal entry unlocked | *journal/drawing_01* — "Even the children knew. They were told not to draw it. One of them did." |

### 8.5 `memory_ledger_page`

| field | value |
|---|---|
| id | `memory_ledger_page` |
| source item | **Water-Stained Ledger Page** (Rob the Bank vault loot; alternate drop from the Mayor's office in the True Ending path) |
| lore snippet | "Names in a careful hand. Beside each, a date and a single word: ENTERED. Some names are crossed out. None have been added in twenty years." |
| journal entry unlocked | *journal/ledger_01* — "Whatever the dead signed, the living are still paying on." |

**Section total: 5 Memory cards.**

---

## 9. Clothing (6)

Clothing does **not** enter the deck (GDD §6.2). It is equipped to one of three slots (Hat, Body, Boots) and provides a passive. Each item is listed here with its id and **set membership** (which named synergy in §11 it belongs to, if any).

| id | display name | slot | set membership | effect | source | flavor |
|---|---|---|---|---|---|---|
| `clothing_tattered_hat` | Tattered Hat | hat | *(none — starter)* | None. Cosmetic. | Starter equipment. | "It came with the head it was on." |
| `clothing_cattlemans_hat` | Cattleman's Hat | hat | `set_outlaw`, `set_iron` | +1 hand size in Grit-primary checks. | Store: $12. | "Wide brim. Keeps the sun and the sheriff at bay." |
| `clothing_black_duster` | Black Duster | body | `set_outlaw` | Opponents have ½ value on Hearts cards against you (intimidation). | Store: $20. Or drop from a bounty target. | "Heavy on the shoulders. Heavier on the room." |
| `clothing_preachers_coat` | Preacher's Coat | body | `set_mourner` | −1 Notoriety when entering the Church. Heart cards in your hand: +1 value. | Drop from Visit the Church (critical success, Morning). | "Black wool, salt-stained at the cuffs." |
| `clothing_snakeskin_boots` | Snakeskin Boots | boots | `set_outlaw` | Once per encounter, swap one card in your hand with the top of your draw pile. | Drop from Hold Up Stagecoach; Saloon back-room ($18). | "He didn't kill the snake. He found it dead." |
| `clothing_dead_mans_boots` | Dead Man's Boots | boots | *(none)* | +1 max wound. Draws a `joker_grinning_fool` into your deck at the start of each new day. | Drop from Coffin Ann (sold for $25 — she warns you twice). | "They walked a man into the ground once already." |

**Section total: 6 clothing items.**

---

## 10. Drinks (7)

Each drink is purchased once at the Saloon and immediately shuffled into the deck as a Sting Card (§6.1). This table is the canonical reference for the Drinks card-creation rules; the resulting sting card data lives in §6.1.

| id | display name | cost | sting card created | rider effect (re-stated) |
|---|---|---|---|---|
| `drink_def_beer` | Beer | $1 | `drink_beer` (5♣) | None. |
| `drink_def_sasparilla` | Sasparilla | $2 | `drink_sasparilla` (6♥) | None. |
| `drink_def_whiskey` | Whiskey | $3 | `drink_whiskey_courage` (9♠) | When played, take 1 wound at end of encounter. |
| `drink_def_bourbon` | Bourbon | $4 | `drink_bourbon_warmth` (10♠) | When played, cannot be discarded by other effects this encounter. |
| `drink_def_laudanum` | Laudanum | $5 | `drink_laudanum_sleep` (Wild Ace ♥) | When played, skip drawing for one round. |
| `drink_def_cursed_whiskey` | Cursed Whiskey | $4 | `drink_cursed_whiskey` (13♠) | One-shot. Burns itself out of the run after play. |
| `drink_def_bartenders_special` | The Bartender's Special | $10 | `drink_bartenders_special` (random wild Ace) | When played, draw the next card face-down. |

**Section total: 7 drinks.**

---

## 11. Sets — Named Synergies (5)

Named synergies from GDD §6.4.1. Each set activates when all components are simultaneously held (clothing equipped, items owned, deck cards present). Activation is mechanical and visible in the Saddlebag UI; the **discovery feedback line** below is the single diegetic line shown the first time the set activates for a player (per the GDD's discovery convention in §6.4.2).

### 11.1 `set_outlaw`

| field | value |
|---|---|
| id | `set_outlaw` |
| name | The Outlaw |
| components | `clothing_cattlemans_hat` + `clothing_black_duster` + `clothing_snakeskin_boots` |
| effect | +1 wound limit; +2 Notoriety per successful task. |
| discovery feedback line | *"The town watches you walk. It doesn't look away."* |

### 11.2 `set_iron`

| field | value |
|---|---|
| id | `set_iron` |
| name | The Iron |
| components | `item_old_revolver` (owned, at least one in deck) + `j_spades_bowie` (in deck) + `clothing_cattlemans_hat` (equipped) |
| effect | All ♠ checks: +2. |
| discovery feedback line | *"The weight of the gun settles. So does the room."* |

### 11.3 `set_drinker`

| field | value |
|---|---|
| id | `set_drinker` |
| name | The Drinker |
| components | 4 or more cards in deck tagged `drink` (counted across sting cards from §6.1). |
| effect | Drink-card riders are softened. Specifically: `drink_whiskey_courage` wound triggers at *end of next encounter* instead of this one; `drink_laudanum_sleep` "skip drawing" applies for half a round (skip 1 card, not the full draw). |
| discovery feedback line | *"Mose pours one without being asked."* |

### 11.4 `set_gambler`

| field | value |
|---|---|
| id | `set_gambler` |
| name | The Gambler |
| components | `item_lucky_penny` (in deck) + `k_clubs_drifters_coin` (in deck) + 3 or more ♣ cards (any source). |
| effect | Once per day, re-draw your hand for free. |
| discovery feedback line | *"The cards lean toward your hand. They always have."* |

### 11.5 `set_mourner`

| field | value |
|---|---|
| id | `set_mourner` |
| name | The Mourner |
| components | `clothing_preachers_coat` (equipped) + `item_pocket_bible` (in deck) + `item_locket` (owned, Memory revealed *or* not). |
| effect | Unlocks the **Whispering Ghost** hidden encounter at the Cemetery (per GDD §6.4.2: enter Cemetery at Night wearing the Preacher's Coat → ghost offers Ace ♥ for cleansing a Joker). |
| discovery feedback line | *"The locket grows warm against your chest."* |

**Section total: 5 sets.**

---

## 12. Quick-Reference Summary

| Category | Count |
|---|---|
| Number cards | 36 |
| Face cards | 12 |
| Aces | 4 |
| Jokers | 2 |
| Sting cards (drink + others) | 12 |
| Item-reskin cards | 7 |
| Memory cards | 5 |
| **Cards total** | **78** |
| Clothing | 6 |
| Sets | 5 |

> Cards-total = 36 + 12 + 4 + 2 + 12 + 7 + 5 = **78** discrete card resources. Item-reskin cards re-use the value of an existing raw number card but are separate resources (different id, different flavor, sometimes different rider). The GDD's MVP-scope estimate of "~60 named cards" (§16.1) refers to **named, illustrated** cards — face cards (12) + Aces (4) + Jokers (2) + sting cards (12) + item-reskins (7) + Memory cards (5) = **42 named cards** — well inside the §16.1 envelope. Plain 2–10 number cards are not "named" in that sense.

---

## Appendix A — Resolved Ambiguities & Designer Notes

For the JSON-generation pass and any later balance work, the following GDD ambiguities have been resolved in this file:

1. **Snake Oil dual-listing.** GDD §6.1 lists Snake Oil as a plain 5♦ reskin; §3.7 lists "Snake Oil Vigor" as a sting card. Resolution: the Snake Oil **item** delivers the sting version (`sting_snake_oil_vigor`). The plain 5♦ remains the raw `5_diamonds`. One item, one card, one resource. See §6.2 and §7.
2. **Beer and Sasparilla as sting cards without riders.** GDD §6.3 calls every drink a sting card, but Beer/Sasparilla have no rider. Resolution: they are sting cards with `sting_rider: null` in JSON. The `drink` tag is preserved so they count toward the Drinker synergy (§11.3). See §6.1 note.
3. **Wild-Ace value for `drink_laudanum_sleep` and `drink_bartenders_special`.** GDD §6.3 lists "Wild Ace ♥" and "Random Ace" as the *card type*. Resolution: in JSON, both use `rank: 14` with `is_ace: true` and a wild-value action. The Bartender's Special uses a deterministic-seeded random suit at acquisition time so the run remains replayable from the event log (TDD determinism commitment, GDD §15).
4. **Face-card-as-starting-card for the Widow starter variant.** GDD §11.2 says the Widow variant "starts with K♥ The Preacher." Resolution: this is reflected in §3.2 as a source path for `k_hearts_preacher`. No separate card resource is needed — same id, alternate starting deck.
5. **`sting_strangers_promise` is the only sting card that adds a Joker.** This is consistent with GDD §3.6 ("Jokers ... only enter the deck through narrative/supernatural channels, never through ordinary purchases"). The Stranger's Promise is a narrative-channel card. The rule "drinks never add Jokers" is preserved.

## Appendix B — Deliberately Omitted

The following items live in the GDD but are **not** card resources and are therefore not enumerated here:

- **Encounter cards** (GDD §8). These have their own JSON schema (TDD §9.4) and live in `docs/cards/ENCOUNTERS.md` once written. The 20 MVP encounters are referenced *as sources* throughout this file but are not card resources themselves.
- **Tasks** (GDD §5). Separate schema (TDD §9.3). Tasks are reward sources, not cards.
- **Opponent deck templates** (TDD §9.5). Cards are real; the templates that compose opponent decks are not.
- **Hidden triggers** (GDD §6.4.2, TDD §9.6). These live in `docs/secrets/HIDDEN_TRIGGERS.md` per the GDD's spoiler convention.
- **The Mayor's deck** (GDD §10.2). Composed from existing card resources at runtime per his Phase 2 deck template; no unique cards required for the Mayor himself.
- **The Deadhand's deck** (GDD §10.2 Phase 3). Composed from "only face cards and Aces, including stolen copies of any face cards the player has ever played" — entirely runtime-assembled, no unique cards.
- **Newspaper / lore-only encounter cards** (e.g., *The Wind Carries Whispers*). These are encounter resources, not deck cards, even though they read like cards in flavor.
- **Variant *raw* number cards for each item-reskin.** The item-reskin (e.g., `item_bone_dice`) is a single card resource; the underlying `6_clubs` is not duplicated for each item. The variants column in §2 is bookkeeping, not additional resources.

---

*End of CARDS.md v0.1. When the GDD changes, this file should be updated in the same PR.*
