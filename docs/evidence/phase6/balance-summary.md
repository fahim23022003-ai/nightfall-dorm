# Phase 6 bounded independent gameplay/economy audit

Agent A; 12 November 2026; Godot 4.6.3 Linux headless. No production edits,
commits, pushes, Windows execution or human play. Source/artifact hashes and
accepted counts are in `balance-source-manifest.json`.

## Fresh accepted evidence

- Eight actual earned-currency Endless runs: **222 cleared waves**, zero
  integrity, currency-ledger, stock, movement or settlement failures.
- **12 actual fresh-profile load/resumes** at cleared waves 5/20/60. Every
  serialized snapshot field and inventory value agrees with persisted state.
  Each run safely exits through the real API, then rejects a repeated exit
  without changing RM Cash or XP: eight exit and eight duplication checks.
- Fourteen prepared campaign matches: **10 victories / 4 defeats**, all valid
  terminal settlements and no harness failures.
- Two additional Stage 1 Normal runs with genuinely **zero XP, no equipped perks,
  no stored/equipped items and no seeded campaign records** both win.
- Accepted three engine logs have exit 0 and no errors or warnings. Old phase
  evidence remains unchanged; all new output is under this phase's folder.

These are fresh runs, not relabelled Phase 5D-1/5D-2 results. Existing older
130-wave/39-run and 150-match audits supply prior context only.

## Scope, budgets and reproducibility

The new harnesses derive the established earned-currency diagnostic policies
from `endless_balance_audit.gd` and `strategy_balance_audit.gd`. All live runs
walk from real map spawn through valid navigation, claim rooms, sleep and earn
Gold/Electricity through actual bed/Dynamo ticks. Buildings and branches use real
paid transactions; sales retain actual separate Gold/Electricity ledgers. Live
HP, positions, currency, clocks and wave indices are never injected. Only the
actual one-time 10% intact-door intermission repair is used, not free cash/power.

Prepared Master budgets use Dreamer/Last Light and four Shields/one Heart.
Separate Mythic control budgets use Steady Aim/Reaper Slayer and four Frost/one
Time Freeze. These are finite seeded progression/item budgets, **not naturally
earned inventory or human skill**. There is no item replenishment. Typical means
one-second diagnostic decisions; optimized means 0.2-second decisions, including
fast paid repair. Campaign policies decide every 0.5s and upgrade when affordable.
Neither label represents measured human reactions or win probabilities.

The zero-XP beginner cases explicitly remove those budgets and use the ordinary
next archetype for their fresh profile. They remain scripted policies, not
proof that every first-time player will win.

## Early/mid and difficulty observations

Six Endless cases cover all five maps, three difficulties, three traits and four
branches, pairing each difficulty with both slower/faster decision policies.
Each clears 12 waves and earns Level 10. The two long arms also reach paid
Level 10. Four of eight have actual Level 10 impacts; four establish availability
only because the Hunter fights teammates elsewhere. Do not present those four
as the player's tower causing every clear.

| Fresh Endless case | L10 first reached | Actual weapon investment | L10 impact damage |
| --- | --- | --- | --- |
| Dorm Normal Precision, 1s | Wave 5 / 230.1s | 1765G / 262E | 0 (availability only) |
| Hospital Long Night Suppression, 1s | Wave 1 / 208.1s | 1765G / 262E | 0 (availability only) |
| Hotel Hell Focus, 1s | Wave 5 / 307.1s | 8290G / 1306E | 0 (availability only) |
| Laboratory Normal Storm, 0.2s | Wave 4 / 237.3s | 8290G / 1306E | 40910.4 |
| Mansion Long Night Precision, 0.2s | Wave 2 / 175.9s | 1765G / 262E | 0 (availability only) |
| Dorm Hell Suppression, 0.2s | Wave 3 / 203.5s | 1765G / 262E | 170417.8 |
| Mansion Normal Focus, 85 waves | Wave 4 / 241.7s | 8290G / 1306E | 11308393.0 |
| Mansion Hell Storm, 65 waves | Wave 2 / 223.9s | 8290G / 1306E | 7794713.3 |

The prepared nine-case campaign core covers every archetype/difficulty with
rotated maps, traits and branches. Normal goes 3/0, Long Night 3/0, Hell 2/1.
Two additional Long Night Arc branch-first plans both reach Level 5, transform
the Reaper and win at 152.3s. Four branches and all five maps occur across the
campaign and Endless sample. This is a bounded representative matrix, not the
full Cartesian product or independent ranking of archetype/trait strength.

The Hell Crusher/Focus Master policy loses at 126.1s despite four Shields and one
Heart. All three separate Hell Mythic-control policies lose before Reaper at
46.9/128.7/131.2s: reactive boss-control stock does not solve a weak opening.
These are legitimate difficulty outcomes, not failed assertions or reasons to
silently weaken Hell. Different economy/coverage/early-item choices matter.

Two fresh no-progression Normal/Crusher runs win at 133.7s (Precision) and
137.7s (Suppression), reaching Level 6 and dealing actual specialized damage.
This supports baseline mechanical viability without claiming beginner usability
has been human-tested. No target win percentage was imposed.

## Long runs, real pressure and resource safety

Mansion Fortified Focus clears **85 waves / 3060.6 active model seconds**; Mansion
Power Hell Storm clears **65 / 1946.2s**. Both reload actual checkpoints at 5/20/60
and continue with the saved paid state/resources. There are 66 genuine milestone
Reaper waves across all eight runs. Each transition uses the real one-Hunter
controller. No illegal movement, negative/nonfinite wallet, ledger drift or
more than one Legendary activation occurs.

For Normal waves 60–85 the minimum recorded door HP is 1128.6, with 205 observed
player hits and 333 paid repairs. Hell waves 60–65 bottom at 806.5, with 51 hits
and 180 paid repairs. Hell uses exactly four Frost and one Freeze for the entire
run. The fast policy is meaningful active counterplay, **not evidence that a
human can maintain this repair cadence indefinitely**. Prior phase passive
fortress defeat at 77 remains prior evidence; this phase does not rerun it.

Engine objects stay **1512** throughout each run's wave-60+ samples. Static
memory rises 96,336 bytes over Normal 60–85 and 32,128 over Hell 60–65; these
figures include deliberately retained audit result dictionaries and are not
isolated production allocations. Overall peaks are eight active projectiles,
19 combat records and 128 presentation records; every cleared wave has zero
active projectiles. Finite samples show bounded entities/events and stable
headless object counts, not a Windows FPS or infinite-session guarantee.

The output field `checkpoint_bytes` is inherited from the old harness but now
measured **after the new safe exit**: 2,687–2,758 bytes of closed profile. It is
not the active checkpoint size and must not be reported as such. Prior 5D-2
approximately 18KB active-save evidence is not newly measured here. C owns the
fresh broader interrupted-save/transaction sizing tests.

## Failures, resolution and recommendation

Initial new resume assertions compared binary in-memory doubles directly with
JSON-decimal and Vector2-float32 reconstructions. Values printed identically but
legitimate decimal round trips differ at binary precision. A subsequent raw
JSON-string comparison also detected int/float notation rather than a gameplay
change. `balance-endless-initial*`, `balance-resume-probe.log`,
`balance-endless-position-roundtrip*` and `balance-endless-type-serialization.log`
preserve these failed harness attempts. They are **test representation defects**,
not production save failures.

The accepted comparison serializes both snapshots, parses both persisted
representations and uses the existing exact recursive numeric comparison. No
field is excluded, no epsilon is introduced, and inventory is also checked.
After correction all eight full runs pass and all 12 resumed states continue to
real combat. Only the affected Endless audit was rerun; accepted campaign tests
were not needlessly repeated.

**No confirmed production defect or justified numerical balance change was found
in this bounded audit.** Retain current prices, bounded wave escalation,
archetype counterplay and item limits. Human Windows testers should specifically
assess early Hell defense, identifying why control items do not rescue an early
breach, Arc investment pacing, branch coverage, and late repair workload.

UNVERIFIED: human fun/difficulty/repair cadence, acquisition of prepared stock,
native Windows, physical controls, hardware FPS, subjective art/audio and every
possible build/item/perk combination. Root/C/D own release, broader regression,
input/save adversarial checks and rendering/audio. A stops after this audit.

## Reproduction

Use writable XDG directories as in README, then:

```sh
godot --headless --path . --script tests/phase6_balance_campaign.gd
godot --headless --path . --script tests/phase6_balance_campaign.gd -- --beginner
godot --headless --path . --script tests/phase6_balance_endless.gd
```
