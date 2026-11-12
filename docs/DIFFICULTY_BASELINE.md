# Phase 4A — pre-change difficulty investigation

Agent A inspected and ran the actual production game at **4c2f6b330a95df5fb1578483f627323fac011867** before any Phase4A production edits. The Godot process loaded the old scripts before the primary developer was released to edit them. Raw output: `/tmp/difficulty-baseline.log` (retain under evidence when finalizing).

`tests/difficulty_baseline.gd` is a reusable diagnostic, not a frozen copy of game rules. Future runs use the currently installed production configuration; the measurements below are specifically the captured pre-change run.

## Method

60 complete deterministic matches: five campaign maps/stages × Normal/Long Night × balanced, turret-first, economy-first, door-first, minimal and marksman strategies. Seed17; player Room2; default25 gold; no resource, damage, statistics or result injection. All five teammate survivors use production BotAI. Strategies buy only affordable buildings/upgrades with earned bed/generator resources. The marksman case equips exactly the existing3% damage perk through the normal model bonus configuration; it is not combined with other perks. Other cases are unboosted. Minimal builds nothing.

Balanced calls production BotAI. Turret-first buys five Needles early, then electricity/bed/door progression and fills remaining slots. Economy-first buys four amplifiers after sustainable prerequisites, then fills turrets. Door-first prioritizes door levels, including bed prerequisites, before filling turrets. Manual policies inspect actual door health and spend on legal repair/upgrades below35%HP. They decide every0.5seconds; production balanced decisions use the existing bot cadence. Simulation steps are0.1seconds and bounded to1200seconds.

All60 resolved; no invalid resources or Godot errors/warnings. Counts are simulation samples, not human win rates. Fixed room/seed and strong automatic teammates are deliberate diagnostic limits, not evidence that every human strategy wins every room.

## Measured outcomes

Each table row is five map samples. “No attack” means the player's door never lost HP. “Player share” is mean player's damage divided by total player+teammate damage, so a win can be visibly teammate-carried.

| Mode | Strategy | Wins / defeats | Mean seconds | No player attack | Player damage share |
| --- | --- | --- | --- | --- | --- |
| Normal | Balanced | 5 / 0 | 191.8 | 5 / 5 | 10.5% |
| Long Night | Balanced | 5 / 0 | 193.1 | 5 / 5 | 6.4% |
| Normal | Turret first | 5 / 0 | 177.2 | 1 / 5 | 42.9% |
| Long Night | Turret first | 5 / 0 | 186.8 | 1 / 5 | 47.9% |
| Normal | Economy first | 5 / 0 | 183.0 | 1 / 5 | 33.2% |
| Long Night | Economy first | 5 / 0 | 184.2 | 1 / 5 | 42.4% |
| Normal | Door first | 5 / 0 | 193.8 | 5 / 5 | 3.3% |
| Long Night | Door first | 5 / 0 | 194.5 | 5 / 5 | 2.6% |
| Normal | Marksman | 5 / 0 | 191.6 | 5 / 5 | 10.8% |
| Long Night | Marksman | 5 / 0 | 192.9 | 5 / 5 | 6.6% |
| Normal | Minimal | 0 / 5 | 81.7 | 0 / 5 | 0% |
| Long Night | Minimal | 0 / 5 | 71.7 | 0 / 5 | 0% |

Long Night genuinely punishes doing nothing sooner, but adds almost no challenge to the balanced/door policies in this sample. All50 active samples won. Balanced Long Night lasted just1.3seconds longer than Normal on average; it was not meaningfully different pressure. Many wins involved no player encounter at all.

## Root causes grounded in code and telemetry

1. **Difficulty is mostly a small stat multiplier.** Long Night adds15%HP/damage and5%speed, while retaining the same1.1second opening interval,45second level cadence,8second growth ramp,24second retarget timer and state behavior. Base HP is5000 and growth100 per level: only2% of base each45seconds. Stage modifiers likewise remain moderate. Permanent perks are only3–5% stat effects and cannot plausibly explain the difference by themselves.
2. **Door strength dominates target avoidance.** Target score adds doorHP×1.8: a level5 door alone contributes3240 score units, while estimated turret penalty caps at90 and repair at35. Upgrading a door therefore deters the hunter far more than a nuanced estimate of opportunity or danger. Balanced/door/marksman players were never attacked in all30 such samples across the two modes.
3. **Team attrition wins while the player is avoided.** Long Night balanced players supplied only6.4% of total damage on average; door-first only2.6%. The five autonomous teammates were doing nearly all the fighting. Stage5 hard door-first won236.1seconds with90 player damage and6865.2 teammate damage, without a player door hit. Increasing player turret costs would not address this root cause.
4. **Cross-room defenses are omitted from target evaluation.** Combat permits every living room's in-range turret to fire. Target scoring counts only turrets inside the candidate room, so a visually weak room can still expose the hunter to neighboring support. Long hotel corridors and varied room layouts make actual approach danger and navigation distance more meaningful than room-local DPS plus Euclidean distance.
5. **Commitment starts during travel.** `target_time` increases in MOVE, then ATTACK compares it to the retarget threshold. A long approach can consume the whole commitment before the hunter lands its first hit, causing a fresh encounter to be reconsidered almost immediately. Movement/retarget churn gives defenses time to scale and shoot, even with no hard navigation recovery detected.
6. **Repair and defense scale faster than early pressure.** Opening hard damage is25.3 per1.1seconds (about23HP/s). A basic repair station provides7HP/s; a paid repair restores70 for12gold. Bed income scales2→4→8→15→26G/s before economy amplifiers. Once developed, repeated repair can cheaply offset attrition while strong doors also discourage targeting. This favors sustained stalemates unless attack patterns create clear, timed resource/upgrade decisions.
The economy comparison is quantitative: a Needle rises from10DPS at level1 to54.4DPS at level4 (5.44×), while a fully ramped level5 old Long Night hunter deals about75.9doorHP/s. A level4 repair station supplies28HP/s;26G/s bed income can fund151.7HP/s worth of12G/70HP repair purchases before amplifier income, although real input/decision cadence limits execution. Generators grow1.5→6E/s over four levels; the4% electricity perk is small beside that progression. These are rate/budget comparisons, not an assertion that a policy perfectly converts every gold into healing.

7. **Extra slots amplify established economy, but are not sufficient evidence for global nerfs.** Turret/economy samples can fill10–16 positions, but baseline strategic wins also occur with six-type balanced builds and minimal player DPS. Earlier map probes show many distant pads cannot reach their own door with Needle range. Slot count is not equivalent to effective door DPS.

## Fair, bounded implementation recommendations

Keep Normal unchanged. Give Long Night/Hell their own configurable growth cadence, aggression, commitment, attack-pattern timing and target reassessment rather than only inflated HP. Measure attack commitment from arrival. Evaluate valid room opportunities with bounded decision-time calculations, accounting for actual path length and all defenses that reach the approach. Avoid rapid switching, player-owner bias, wall ignoring or teleportation.

A clearly telegraphed heavier siege strike/burst can pressure repetitive repair or unadapted turret spending while allowing preparation, upgrades and reaction. Reuse existing door damage/alert/audio events. Increase threat gradually, preserve a readable opening, and keep total damage mathematically traceable. Do not arbitrarily weaken every turret or erase expanded slots. Retain multiple viable earned-resource strategies and verify genuine wins/losses on every difficulty, with a responsive/reactive policy if ordinary balanced play cannot beat Hell.

Final tuning must be judged by new matched diagnostic and independent multi-map results; these pre-change win rates alone do not validate the new modes. Human feel, manual Windows play, fairness perception and broad beginner/expert balance remain unverified.
