# Independent Legendary QA

Agent C tested the production model and profile transactions with Godot 4.6.3 on Linux. These are deterministic fixtures, not native Windows gameplay or subjective presentation evidence.

## Automated coverage

- `tests/legendary_qa.gd`: 20,798 checks, zero failures. All 20 definitions and positive integer reward weights; all four original icon/audio resources; exact Legendary probabilities; seeded reward replay; actual settlement, reload and reveal without duplicated stock; preserved old sixteen-item profiles and new stacks; atomic saved per-match Legendary budget, rebind/reload enforcement and malformed counter rejection.
- Real `MatchModel.tick` freeze tests at 0.1, 0.5, 1 and 4-second steps across all difficulties, normal Hunter and Reaper, including fractional expiry, ongoing bed economy, charged warnings, transformation and exposed-player pursuit.
- All three real Reaper special warnings can be sealed. Ordinary attacks, expired windows, invalid targets, transformation, death and pause fail without spending, cooldown or success animation. Special cooldowns remain and attacks restart.
- Automatic Heart uses real incoming damage on all five maps and three difficulties; nonlethal and invalid states do not spend; lethal interception spends exactly one, small simultaneous follow-up hits are shielded, finite expiry permits later destruction. Save failure cannot rescue or consume.
- Fortune grants exactly 500 Gold; real Hunter damage and attack interval become stronger; the next frame after expiry restores derived normal values; Legendary reuse and other Legendary types are blocked.
- `tests/legendary_combos.gd`: 140 checks, zero failures. Tests Heart with Shield/Barricade/Repair/Feather and First Aid; no same-hit automatic heal cascade; every ordered pair of different Legendary items; Frost plus Freeze and shared control recovery; subsequent ordinary/Reaper attack; Fortune plus three existing defenses.

The first QA run had three fixture failures: it applied an expiry-spanning item tick, then reused that frame's proportional curse fraction for a second direct Hunter tick. Corrected the fixture to advance item timers for the new frame before checking restored stats. The first combination run had three fixture failures: First Aid had legitimately triggered on an earlier Barricade-mitigated nonlethal hit; the corrected assertion compares First Aid's state before/after the later Heart interception. Initial logs are retained. Neither was a confirmed production defect.

## Matched balance scenarios

`tests/legendary_balance.gd`: 120 completed matches, zero invariant failures. Same seed 11, five maps, three difficulties, four policies with/without stock. No injected match currency. Stock fixture is four units of each of two types, constrained to at most one Legendary success. Paired permanent perks are identical: Pocket Change, Reinforced Frame or First Aid. XP fixtures are 0, 250, 3800 and 8000; XP 8000 alone is not asserted to satisfy Mythic gates.

| Difficulty | Baseline W/L | Items W/L |
|---|---:|---:|
| Normal | 20/0 | 20/0 |
| Long Night | 17/3 | 18/2 |
| Hell | 5/15 | 13/7 |

Pairs: Time Freeze + Repair, Reaper Seal + Shield, Guardian Heart + Barricade, Cursed Fortune + Feather. Legendary activations: Freeze 5, Seal 8, Heart 4, Fortune 15, total 32. Manual item activations total 114 (includes non-Legendary items, excludes automatic Heart/Feather). All matches terminate, resources stay finite/nonnegative, inventory stays nonnegative, movement stays bounded and Legendary successes never exceed one.

These policies demonstrate meaningful power with remaining Hell losses; they do not establish human win rates, all possible combinations or universal balance. All four Legendary items actually activated in the matrix. Raw scenario rows and summaries are in `balance-results.json` and `balance-final.log`.

## Limits

Root owns full existing regular/extended regression execution; D owns actual rendered/audio evidence. Native Windows input, human listening, subjective quality and human balance remain UNVERIFIED. No production defect remains known from C's tested scenarios.
