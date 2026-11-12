# Phase 3B map design and balance review

Agent A performed a bounded read-only production review and independent
paid-resource strategy probes. This is automated evidence, not human playtesting.
No prices, combat statistics, or production logic were changed by this review.

## Genuine layout differences

| Map | Geometry and tactical distinction | Pads |
| --- | --- | --- |
| Abandoned Student Dorm | Single joining hall, compact two-row room arrangement; introductory orientation | 12 |
| Haunted Hospital | Parallel halls with several crosslinks; smaller central rooms have fewer build positions | 10/12 |
| Forgotten Hotel | Long alternating guest-room corridor; rooms are narrow, neighboring defensive support is spread out | 10 |
| Underground Laboratory | Two vertical trunks joined into a loop, side-facing entries and rotated defensive arrangements | 12 |
| Cursed Mansion | Branched cross-hall arrangement and different-size rooms; large rooms offer utility space beyond immediate defensive range | 10/16 |

All map themes use different room coordinates and dimensions as well as hall
structure. Their visual decoration is audited separately by Agent D. Stage
modifiers still compose with the independently selected difficulty.

Expanded space does not equal the same number of effective door turrets.
Measured from each pad to that room's actual outside door approach, only 5–7
Needle pads (240-unit range) can reach that approach across these maps. Large
16-pad mansion rooms have only 5–6 such Needle positions; 12 of those pads can
reach with a 300-range Arc. Far positions therefore favor generators, economy,
repair/relay utilities or longer-range defenses. Actual moving-target combat can
differ from this static approach measurement; it is not an assertion that other
pads can never fire during a breach.

## Method and interpretation

`tests/maps_balance_probe.gd` uses the real MatchModel, seed 7, starting 25 gold,
no injected resources/damage/statistics, paid purchases and earned bed/generator
income. It compares existing BotAI balanced play, a five-Needle turret-first
policy, and four economy-building investments followed by turret filling, in
hospital and mansion rooms at both difficulties. Policy actions are bounded by
normal affordability and a half-second decision interval. Other survivors retain
production AI. A victory can be earned partly or entirely by teammates, so
player damage and room identity are recorded along with time and building count.

The independent QA matrix additionally covers all five maps and rooms with
balanced/passive policies and an alternative two-economy stacking policy for
hospital/mansion. That matrix's results must be considered separately from this
probe; repeated matches are not extra unique human strategies.

No arbitrary price increase or damage nerf is justified merely because a map has
more pads. Stronger purchases have opportunity costs: delayed bed/door upgrades,
electricity production, repair drain and unused turret range. Long corridor
transit and target avoidance can also change which survivor contributes damage.
These probes do not certify broad human balance or Windows performance.

## Measured results

The independent probe completed **72 matches, zero unresolved or invalid-resource
failures**, exit 0 with no Godot errors/warnings. Each row represents 12 matches
(six rooms × both difficulties); these are seed-7 samples.

| Map | Policy | Victories / defeats | Mean match seconds | Range seconds | Maximum buildings | Mean player damage |
| --- | --- | --- | --- | --- | --- | --- |
| Hospital | Balanced | 12 / 0 | 184.0 | 164.5–212.7 | 6 | 233.1 |
| Hospital | Turret first | 12 / 0 | 181.8 | 160.2–190.6 | 12 | 1338.0 |
| Hospital | Economy stack | 12 / 0 | 181.9 | 122.9–248.1 | 12 | 1576.6 |
| Mansion | Balanced | 12 / 0 | 170.4 | 158.5–192.9 | 6 | 599.5 |
| Mansion | Turret first | 12 / 0 | 167.6 | 155.4–184.5 | 16 | 987.2 |
| Mansion | Economy stack | 12 / 0 | 167.7 | 145.3–201.5 | 16 | 1166.6 |

The expanded policies fill genuinely paid 12/16 slots and increase damage when
encountered, but their average match-time advantage is approximately 2–3 seconds
in this sample, not an instant elimination. Economy stacking also produces a
wide result range, with a slow 248.1-second hospital match. Many hospital rooms
contribute zero direct damage because other survivors finish the hunter; this
is explicitly not a controlled solo-DPS benchmark. All active policies winning
means this small sample cannot measure win-rate improvement from extra slots.

The independent seed-11 QA matrix has 144 matches: balanced wins all 60 samples,
passive loses all 60, and a different paid two-economy stacking strategy wins
24 hospital/mansion samples. In that matrix stacking reduces mean hospital time
177.3→161.8 seconds and mansion time181.6→175.8 seconds. These are useful sampled
advantages, not proof of general human difficulty. A completely passive player
still loses on every map in those tested paths.

**Recommendation:** retain current prices and damage values for this phase.
No tested resource exploit, universal immediate-kill construction tactic or
unconditional passive victory was demonstrated. Preserve the extra space and
range tradeoffs, then gather Windows human-play data before balancing further.
Navigation correctness is verified by separate core/integration QA; this balance
review alone does not establish that every path is valid.
