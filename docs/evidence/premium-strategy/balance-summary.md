# Phase 5D-1 independent gameplay balance audit

Godot 4.6.3, Linux, 12 November 2026. Agent A owned only this harness and
`balance-*` evidence. Production changes went through Agent B. No commits or
pushes were made by A.

## Scope and budgets

The final evidence represents **150 live diagnostic matches**, plus separately
labelled controlled projectile fixtures. These are automated policy outcomes,
not human win rates or proof of universal balance.

The 108-case core is three archetypes × three difficulties × three requested room
traits × four branches. All five maps occur: Dorm/Hospital 24 cases each,
Hotel/Laboratory/Mansion 20 each. Map/stage rotation is identical within each
four-branch comparison. Seed, room-access policy, perks and item budget also
match within each comparison. Comparisons between archetypes or room traits
remain confounded by geometry/stage and target choices; aggregate counts cannot
rank their inherent strength.

Live matches use actual `move_player`, physical room entry before claiming,
legal sleep, elapsed ticks, earned income/electricity, paid upgrades and the
real specialization transaction. No Gold, electricity, HP, player/Hunter
positions or match time are injected. Legal upgrades and existing item effects
may restore HP. Walking and sleep consume preparation time. Nearest available
rooms of the requested trait are selected; no access failures occurred.

Prepared progressed profiles unlock the requested maps and perks. This stock
and progression are seeded test budgets, **not naturally earned inventory**:

- Core/reservation/contracts: Master, Dreamer + Last Light, four Shields and
  one automatic Guardian Heart, two equipped item slots, no stage bonus.
- No Legendary Help removes Heart from the loadout.
- Separate control arm: Mythic, Steady Aim + Reaper Slayer, four Frost Bombs
  and one Time Freeze, two slots, no stage bonus.

The core buys one weapon early and upgrades it incrementally, while following
one fixed support/economy policy. Twelve reservation probes instead save the
entire paid Level 10 weapon budget before construction. Twelve separate Arc
branch-first probes build modest economic infrastructure, then prioritize Level
5 before maximum economy. Nine control-item and nine contract matches complete
the sample. Gameplay RNG and reward RNG are explicitly seeded.

## Results and meaningful tradeoffs

| Final live sample | Victories / defeats | Interpretation |
| --- | --- | --- |
| Core Normal | 36 / 0 | Prepared policy can counter all sampled encounters |
| Core Long Night | 36 / 0 | Same disclosed budget; no human-rate inference |
| Core Hell | 29 / 7 | Policy/loadout weaknesses remain |
| Reservation | 12 / 0 | Some wins depend entirely on teammates |
| Mythic control | 6 / 3 | All three Hell cases die before transformation |
| Contracts | 9 / 0 | All objectives qualify and settle successfully |
| Arc branch-first | 12 / 0 | Both Arc choices actually reach Level 5 |

**Needle coverage versus damage now changes actual decisions.** Initial
same-range Needle comparisons reached Level 5 in 26 paired cases: Precision
finished faster in 19, Suppression in zero, seven ties. A reported this suspected
policy-specific dominance to B/root. B gave Precision 0.85 range (204 px), while
Suppression retains 240 px and its movement slow. A reran all 78 affected live
cases. Final paired finish times: Precision faster 13, Suppression faster five,
eight ties. This does not establish parity or universal balance.

Concrete final counterexample: seed 11, Ravager, Hell, Stage 1/Dorm, Power room
4, same Master budget and policy. Both weapons reach Level 6. Precision loses
at 167.3 s after four Shields and Heart; Suppression wins at 156.3 s after four
Shields, with Heart unused. In Normal/Dorm/Economy, Ravager Precision wins at
134.4 s versus Suppression at 115.8 s. Other cases still favor Precision.

**Arc requires an intentional investment policy.** Core Arc branches reach
Level 5 in only one paired case, with no specialized impacts there. This cannot
support a claim about their relative effectiveness. The additional branch-first
policy naturally reaches Level 5 in all 12 cases, at 123.4–152.6 s. Stalker,
Long Night, Stage 4, Economy room 2, seed 47 gives actual specialized damage:
Focused Discharge 1680 versus Storm Coil 1612.8; both win at 177.1 s. Many other
branch-first wins have no specialized player damage because the Hunter is
elsewhere or teammates finish it. These are availability evidence, not proof
that the weapon caused the victory.

**Level 10:** four of 12 reservation matches reach Needle 10, at 158.9 or 175.4 s.
Crusher/Hospital actual Level 10 impacts are Precision 837 and Suppression 1152
damage. Both Ravager/Laboratory Level 10 wins have zero player damage. No Arc
Level 10 is naturally reached by these bounded policies; that is not a claim
that Arc 10 is universally unreachable. Separate paid controlled fixtures cover
both Arc branches through 10.

**Archetypes:** Crusher causes six core Hell defeats, so its slow approach does
not make it harmless under this policy. Ravager is counterable in 35/36 final
core samples, including the demonstrated Suppression counterexample above.
Stalker can still kill an underprepared control-loadout player at 46.9 s in
Stage 5 Hell, before any weapon. These findings do not rank archetypes across
different maps or establish that every room/loadout is winnable.

**Rooms:** each trait has victories and all retains its actual drawback.
Fortified 32/36, Power 35/36, Economy 34/36 core victories are descriptive only;
geometry, travel time, stage and bot targeting prevent an inherent trait ranking.
No universally safest/richest room or universally unwinnable trait is established.

**Reaper and finite control:** all six Normal/Long Night Mythic control matches
transform; they consume three or four Frost Bombs and one Freeze. Maximum
continuous observed freeze is 1.5 s. Reaper still inflicts 2–14 door-damage
strikes per case and the encounter resolves. All three Hell control-loadout
cases lose before transformation. This demonstrates a real defensive tradeoff,
not a permanent CC lock. Deep CC/Seal/Overdrive exploit coverage belongs to C.

**Contracts:** nine real settlements pay exactly 8/10/8 extra RM Cash for No
Legendary Help/Limited Defense/Iron Survivor. These restrictions add little
cost to a compatible one-weapon policy; they are optional milestones rather
than necessarily harder for every build. Catalog payouts are limited to one
claim per stage/difficulty/contract, 390 RM Cash over all 45 unique keys.
Duplicate/rollback/adversarial eligibility proof belongs to C; no repeated
same-key farming conclusion is inferred from these fresh-profile matches.

## Controlled combat, explicitly separate

These fixtures inject wallet, target HP, positions and time, then use real paid
upgrade/branch transactions and the projectile engine against a stationary
target. Hunter AI, movement, door pressure and economy are excluded. They show
weapon effects and coverage, **not natural balance, Reaper resistance or wins**.

| Level 10 fixed-target test, 20 seconds | Precision | Suppression | Focus | Storm |
| --- | ---: | ---: | ---: | ---: |
| Final Needle at 180 px | 4603.5 | 4032 | — | — |
| Final Needle at 220 px | 0 | 3960 | — | — |
| Unchanged Arc at 210 px | — | — | 9660 | 8870.4 |
| Unchanged Arc at 330 px | — | — | 0 | 8668.8 |

Both fixed normal/transformed states yield these same projectile totals without
the Mythic damage perk. Real paid investment is 1765 Gold/262 electricity per
Needle 10 and 8290/1306 per Arc 10, including specialization. `--check` reuses
eight final Needle fixtures and asserts the close-damage/220-px-coverage tradeoff
and paid Level 10 state. It is a regression check, not a balance score.

## Evidence, reproduction and limits

`balance-results.json` is the final **138-row composite**, with explicit source
provenance: fresh `balance-needle-results.json` (78 affected live cases), plus
60 unchanged Arc rows from `balance-results-before-range.json`. The 12 unchanged
Arc branch-first rows remain in `balance-arc-first-results.json`. No fresh full
150-case rerun after the Needle-only range change is claimed. Logs retain the
before-range full run, fresh Needle run, Arc-first run, pilots and controlled
fixtures. All final source executions exited 0 with zero harness integrity or
settlement failures and no Godot engine errors. Victories/defeats are not test
failures. Main/Arc combat rows were reproduced exactly when reward seeding was
fixed; only random cash values changed. The initial helper parse typo is
preserved as an explicitly transcribed tool-output log.

Run with writable XDG directories as in README:

```sh
godot --headless --path . --script tests/strategy_balance_audit.gd
godot --headless --path . --script tests/strategy_balance_audit.gd -- --arc-first
godot --headless --path . --script tests/strategy_balance_audit.gd -- --needle-only
godot --headless --path . --script tests/strategy_balance_audit.gd -- --controlled
godot --headless --path . --script tests/strategy_balance_audit.gd -- --check
```

Default reruns 138 live matches and overwrites `balance-results.json`; the
standalone result is then fresh rather than composite. `--arc-first` runs 12;
`--needle-only` runs 78. `--check` writes only `balance-check-results.json`,
preserving live evidence. Regular/legacy extended regressions are root-owned
and were not duplicated by A.

UNVERIFIED: native Windows, human difficulty/fun, human reaction times, universal
balance, all item/perk combinations, natural earning of the prepared profile
stock, and natural Arc 10 under this audit's policies. No known mechanical
failure remains in A's bounded tested paths. Further human playtesting should
focus on how often each weapon's coverage advantage matters and whether
compatible contracts feel meaningfully restrictive.
