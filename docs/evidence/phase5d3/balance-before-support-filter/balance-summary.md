# Phase 5D-3 independent gameplay/building audit

Agent A. Godot 4.6.3 Linux headless. No production edits, commits, pushes or
human/native Windows play. All output is confined to this phase; earlier evidence
and source helpers remain unchanged. Exact hashes are in `balance-manifest.json`.

## Final acceptance and source changes

- **10 unique earned-currency Endless cases /245 cleared waves**, zero currency,
  navigation, stock, use-cap or settlement integrity failures.
- **15 fresh-profile checkpoint load/resumes**, including genuine states at waves
  5/20/60 where reached; every serialized snapshot field and stock agrees with the
  persisted representation. Six target-limited cases close safely; two 30-wave
  all-building cases also close safely. Repeated safe exit grants no duplicate
  RM/XP. The two advanced cases end in actual defeat and settle normally.
- **16 campaign cases:** fourteen matched prepared strategies produce eleven
  victories/three defeats, plus two genuinely zero-XP/no-perk/no-stock Stage1
  Normal strategies both win. No win-rate target was forced.
- **15 controlled Hunter cases** span all five maps and all three archetypes,
  with Normal/Long Night/Hell cycled. Each visits 2–6 valid target rooms and uses
  real archetype mechanics. Minimum observed target-change gap is9.2s; none
  switches every frame. Navigation/displacement and actual warning-before-effect
  checks pass; transformed Hunter clears normal active abilities.

The raw initial matrix predates two small subsequent fixes. Only affected cases
were repeated: five Ravager controlled/six Ravager campaign cases after fixing
recovery on early doorway arrival, then one Hell Crusher controlled/two Hell
Crusher campaign cases after restoring Hell's charged cadence3 instead of4.
Every rotating Endless run includes Ravager, so all ten were refreshed once;
after the Hell-only correction just four Hell runs were refreshed. Final merged
records select those fresh affected rows and explicitly identify unchanged rows.
Old raw/pre-fix records are retained and are not counted as additional unique
acceptance scenarios. `balance-ai-final-results.json` records counters55,080,
18,363 and3,671 as separate gates, not an invented unique assertion sum.

## Actual AI mechanics and fairness

Source inspection and actual controller ticking confirm:

- **Crusher:** existing long-windup heavy/charged strikes remain; new Siege
  Pressure gives20% damage for4s after0.9s warning with20s cooldown. Recovery costs
  remain. Normal's new charged interval4 is intentional; Long Night4/Hell3 retain
  established difficulty cadence. No blanket HP/damage multiplication was used.
- **Stalker:** warned3s concealment gives15% approach speed and reduces turret
  acquisition range to80%, with15s cooldown; it is not just a sprite tint. Failed
  siege feints select and walk toward another legal room after commitment.
  First-strike warning and lower direct damage remain.
- **Ravager:** warned1.35s navigation dash uses1.65x speed,0.65s anticipation and
  0.7s recovery even if it reaches a doorway early. Existing three-strike rhythm
  and extra0.8s recovery remain; baseline combo intervals were not sped up.
- Target scoring includes existing valid routes, distance, durability, defensive
  threat and repairs, plus bounded failed-siege history and seeded tie variation.
  It retains commitment and cooldown instead of using random movement or wall
  crossing. The controlled fixture uses real map/controller ticks; its initial
  high-tier healed doors and seeded funds are explicitly artificial, not an
  economy or victory demonstration.
- Reaper clears these normal active abilities instead of stacking them. The
  ten earned runs contain60 actual Reaper waves, each with exactly one observed
  transformation and real special-attack events. Wave transitions create one
  intentional new Hunter; no accidental mid-encounter refill was observed.

Tactical mechanics do **not** automatically mean higher aggregate DPS. Windup,
recovery and traveling to another target cost time. The old matched fourteen
Phase6 policies had10 wins/4 defeats; this phase has11/3. The new Stalker defeats
one Hell Master plan that previously won; other target changes help some plans.
This evidence supports purposeful variety/counterplay, not a claim of universally
harder AI. Prepared automated Normal arms win3/3, Long Night5/5 and Hell3/6. Human
threat, enjoyment and approachability still need the owner's playtest. No further
timing/stat adjustment was justified by this bounded sample.

## Genuine Level10 reachability for every system

The two all-eight runs use actual spawn-to-room walking, claim/sleep, bed/Dynamo
production, paid purchases/upgrades/choices and real combat. No live currency,
HP, position, clock or wave is injected. Intermissions choose only genuine10%
intact-door repair, not free Gold/Electricity. Prepared Master/Mythic progression
and finite stored items are declared budgets; decisions occur every0.2s (1s for
three typical matrix arms), not human reaction measurements.

| System | Normal Hospital Economy, seed11 | Hell Mansion Fortified, seed47 | Paid single-system1→10 cost, no coupon |
| --- | --- | --- | --- |
| Bed | Wave3 /219.8s, Lucid Dividend | Wave7 /377.6s, Dream Conductor |9155 Gold /952 Electricity |
| Door | Wave3 /231.8s, Cursed Bulwark | Wave7 /386.0s, Living Threshold |9955 Gold /950 Electricity |
| Dynamo | Wave2 /168.2s, Regulated Core | Wave4 /282.4s, Overcharge |2635 Gold /262 Electricity |
| Repair station | Wave8 /396.6s, Powered Sutures | Wave8 /422.6s, Careful Restoration |3505 Gold /697 Electricity |
| Dream amplifier | Wave4 /254.2s, Golden Reverie | Wave7 /394.6s, Conductive Dream |3940 Gold /610 Electricity |
| Target relay | Wave9 /467.2s, Focused Relay | Wave8 /433.0s, Cooling Relay |5680 Gold /958 Electricity |
| Needle | Wave1 /155.6s, Suppression | Wave9 /436.2s, Suppression |1765 Gold /262 Electricity |
| Arc | Wave11 /563.8s, Focused Discharge | Wave3 /263.2s, Storm Coil |8290 Gold /1306 Electricity |

All eight are complete by wave11/563.8s in Normal and wave9/436.2s in Hell. The
normal run uses no consumable at all; its four Shields/one Heart remain stored
at wave30. The Hell arm spends exactly four Frost and one Freeze across the run,
with at most one successful Legendary activation. Other matrix arms naturally
reach Precision Needle10, so both original weapon families/branches remain
represented. The two all-eight runs cover both choices of every new support and
structural specialization. The Normal30-wave arm receives no player-door hits because the Hunter favors
weaker teammate rooms, although its main Level10 Needle deals5389.9 actual damage.
The Hell30-wave arm receives130 player-door hits and its main Level10 Arc deals
375275.8 actual damage. Normal availability must not be mistaken for a universal
player-door stress test. Exact paid machine ledgers are in each reach row and
saved profile; built-in bed/door costs are sums of real upgrade charges, not sale
refund claims. Structural choices use the ordinary L5→6 upgrade charge and do not
add the machine25G/4E branch fee. Beds/doors retain their existing non-sale role.

Canonical independently reopened profiles:

- `balance-earned-all8-haunted_hospital-standard.json` (17,926 bytes).
- `balance-earned-all8-cursed_mansion-hell-alternative.json` (17,977 bytes).

These preserve actual funds, HP, elapsed time, owner/position and paid ledgers.
For GUI captures only, D may copy the profile and mark that isolated copy's
`tutorial_completed=true`; originals must remain byte-identical. They are
headless prepared-progression budgets, not a claim of naturally earned rank.

## Tradeoffs, economy and later pressure

Source-role integration and actual natural builds preserve meaningful bounded
choices: more income versus occupied-bed Electricity; stronger door/mitigation
versus repair efficiency; steady versus stronger power at an income cost; healing
versus ongoing power cost or cheaper manual repair; amplifier income versus
power; relay hit bonus versus range or firing interval. Generator/support
cross-modifiers are additive and clamped. Amplifier/relay late per-tier output
has diminishing linear growth. Bed power conversion uses base occupied-bed
income, not an unbounded reinvestment multiplier. All levels cap10 and room pad
counts remain finite. C independently covers exact accounting, coupons, refunds,
invalid purchases and migration; this A audit does not replace those tests.

A LOW UI ambiguity was identified during source review: structural choices
correctly charged full legacy price but displayed a coupon marker. C confirmed
it and B clarified machine-only coupon eligibility; no discount policy or price
was silently changed to make the tests pass.

A completed late economy becomes abundant: the Normal30-wave arm earns about
6.48million Gold over2859.5s; the passive advanced arm earns23.37million by actual
defeat. This is finite occupied-bed production in an already-completed build,
not a pause/save reward loop or infinite upgrade exploit. Currency remains
finite under the existing Endless1e12 cap. Late Gold scarcity is not established
by this audit and should not be claimed as a universal strategic limit.

Richness and tier10 do not guarantee invulnerability:

- The Normal all-eight plan stops all active actions from wave20 and loses during
  wave62 after61 clears,9690.4 model seconds. It receives36 actual player door
  hits during the terminal wave; the finite automatic Heart is spent once.
- The Hell alternative all-eight plan keeps paid repairs and finite control, but
  loses during wave53 after52 clears,5645.5s. It receives44 terminal-wave player
  door hits. No inventory refill or use-cap reset occurs.

These are legitimate outcomes, not failing tests or a prescribed defeat wave.
They do not establish human longevity, difficulty percentiles or endless-session
universality. No additional balance tuning is recommended solely from them.

## Stability, saves and limits

Across the ten final unique runs:245 clears,15 actual fresh loads/resumes and60
once-only Reaper waves. Cleared checkpoints have zero active projectiles. Highest
observed active counts are9 projectiles,21 combat records and128 presentation
records. Long engine object count stays1513; retained-row-inclusive static memory
is roughly25–27MB in these headless runs, with modest audit-row/cache growth rather
than an increasing entity count. These are finite Linux model observations,
not rendered FPS/hardware RAM benchmarks or proof of infinite-session stability.
The inherited final `checkpoint_bytes` field measures the closed/settled profile,
not active checkpoint size; canonical all-eight files above provide actual saved
intermission sizes. Recent-source and artifact hashes are preserved separately.

All accepted logs have exit0, no engine errors and zero harness failures. Earlier
pre-fix runs remain diagnostic evidence. Native Windows, physical inputs/audio,
subjective difficulty/AI intelligence, human reaction cadence, naturally earned
permanent rank/stock and subjective fun remain UNVERIFIED. Stop after Phase5D3.
