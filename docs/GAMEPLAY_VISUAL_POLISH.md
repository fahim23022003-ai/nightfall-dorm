# Gameplay visual audit and polish

IMPLEMENTED: one focused presentation pass on Godot 4.6.3, branch `work`, starting at `ec082f17f8e49d67ba2b6ba0838d415c37e83ad4`. The polished main menu is unchanged.

## Three findings and fixes

1. Selected machines were easy to lose against the room floor; successful upgrades were understated. Existing selection and level-event rendering now uses restrained gold corner brackets, a brief gold ring and UPGRADED text. No additional event system or gameplay changes.
2. Expanded rooms repeated large L10 MAX banners, pip rows and branch markers. Compact numeric badges reduce duplication while retaining prestige crowns and branch identity. Ward strength is grouped beneath the existing door HP display.
3. Incoming physical and magic damage was difficult to distinguish. Existing floating numbers now label PHYSICAL in amber and MAGIC in purple, with contrast backings, separate bounded aggregation lanes and Reduced Effects support. Existing local impact flash, shake and cracks remain.

Essential layout corrections move sideways Lab HP labels away from Hunter faces and place staggered typed feedback within visible bounds. No AI, combat formulas, prices, building stats, rewards, expansion progression or save formats changed. Hash evidence confirms 124 other script/UID files, including menu and gameplay logic, are byte-identical to the starting commit.

## TESTED

- Godot 4.6.3 import and launch succeeded.
- Focused gate: **50 checks, 0 failures**. Real GUI selection and paid upgrade; exact resource deductions; failed upgrade does not restart success feedback; actual physical/magic HP calculations; separate aggregation, 12-number cap and expiry; Reduced Effects; presentation leaves model/RNG unchanged; real 16-slot expansion; checkpoint roundtrip; isolated profile bytes preserved; opposite horizontal Lab doors remain clear of Hunter/HP labels and screen edges.
- Independent after-capture gate: **15 checks, 0 failures**, successful engine exit. All seven screenshots inspected. No new panel clipping found at 1280×720 or 1920×1080.
- Initial test fixture omitted UI refresh while deliberately disabling Game processing, leaving its button disabled. Fixture corrected; product behavior was not altered to satisfy it. Initial diagnostic retained alongside passing evidence.
- No entire regression suite, exports, new dependencies or gameplay rebalance.

## Real rendered evidence

[Before captures](evidence/gameplay-visual-polish/before/) and [after captures](evidence/gameplay-visual-polish/after/) contain raw Godot PNGs, manifests and logs. Five scenes are 1280×720; the sixth is 1920×1080. Extra 02b records the actual successful upgrade pulse. Source/image hashes are preserved.

| File | Actual scene |
|---|---|
| 01-early-normal-720.png | Normal preparation, player bed/door/machines and bottom toolbar |
| 02-selected-upgrade-720.png | Selected Dynamo with existing contextual upgrade panel |
| 02b-successful-upgrade-720.png | Paid Level 2 upgrade, gold pulse and UPGRADED cue |
| 03-physical-combat-720.png | Crusher contact, PHYSICAL −26.4, actual door HP 146/173 |
| 04-earned-endless-sixteen-720.png | Restored genuinely earned wave-45, 16-slot expanded room |
| 05-magical-combat-720.png | Phantom Witch, MAGIC −15.56, actual door HP 2055/2070 |
| 06-early-normal-1080.png | Full 1920×1080 HUD view |

These are real engine renders from isolated profiles and controlled automated setups, not an uninterrupted human playthrough. Early/combat setups use temporary demonstration wallets and seating through game APIs. Late Endless restores a read-only copy of the genuinely earned checkpoint `docs/evidence/gameplay-overhaul/balance/earned-cursed_mansion.json`; canonical checkpoint data and user saves are preserved. Magic after-capture waits for a positive incoming magic-damage event; baseline magic framing showed outgoing burn and was less informative. No generated or composited gameplay images.

## UNVERIFIED / remaining weaknesses

Native Windows execution and subjective beginner usability remain UNVERIFIED. Linux engine checks and screenshot inspection do not constitute human playtest approval. Dense late-game crowns/branch artwork and clustered arriving NPC names remain visually busy; zoomed-out world labels remain small. Those existing weaknesses are outside this bounded three-fix pass. No required screenshot scenario remains incomplete.

Commit identity is the Git commit containing this report; push is verified separately by comparing remote `work` to local HEAD. No release, main-branch merge, new build or future phase.
