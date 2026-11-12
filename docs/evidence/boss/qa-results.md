# Independent Agent C boss QA

`tests/boss_qa.gd`: **6,699 checks, zero failures** after the production range
lookup correction. `qa-edges-final.log` records the final passing rerun; `qa-final.log` retains
the earlier 6,655-check passing milestone. The earlier
`qa-range.log` preserves two confirmed failures: equal-valued turret dictionaries
caused `find_key` to reuse the wrong building pad when evaluating range. Iterating
actual tile keys fixes both false-positive and false-negative Surge selection.

Final targeted edge regressions also verify real sleep actions during transformation
on all five maps, deferred physical exit and exactly one completion event; immediate
Surge suppression/vulnerability cleanup after displacement (exactly 10 HP lost to a
10-damage hit); and no boss interruption recovery imposed on ordinary idle Hunters.
These cases pass after the primary developer's state-transition and recovery fixes.

Focused fixtures cover five maps and three modes, explicitly enabling the boss
on introductory maps for compatibility. They check normal starts and campaign
stage gating; one entity/one transformation; exact unchanged transition HP;
finite animation and navigation; every ability's warning, cooldown, damage or
suppression; actual floating damage; turret impacts; repairs during suppression;
interrupted/invalid targets; death during transformation; exposed-player handling;
global targetless warnings; terminal cleanup; reset; and once-only campaign XP
and persisted stage progression. Large fixture resources are **not balance data**.

`tests/boss_matrix.gd -- --hell-rooms`: **30 earned-resource matches, 14 wins /
16 losses, zero resource, navigation, duplicate transformation or unresolved
failures**. Fourteen matches transformed, with twelve boss victories. The two
other victories were introductory stage 1, where encounters remain disabled.
Final evidence: `matrix-hell-final.log` and `matrix-hell.json`. The range correction
did not change these probe results. The original pre-correction evidence is
retained separately as `matrix-hell-initial.log` / `.json`.

These probes use a deterministic proactive economy/repair policy, Dreamer perk,
seed 11, 0.1-second ticks, normal starting resources, and one legal action attempt
every 0.5 seconds. No injected resource grants or boss HP changes.

| Eligible boss stage | Winning room numbers | Encounter outcome evidence |
| --- | --- | --- |
| Hospital (2) | 1, 2, 6 | Reaper defeated |
| Hotel (3) | 1, 3, 4, 5, 6 | Reaper defeated |
| Laboratory (4) | 1, 2 | Reaper defeated |
| Mansion (5) | 1, 2 | Reaper defeated |

These are finite simulation outcomes, **not human win rates**. They demonstrate
an earned-resource winning strategy on every eligible boss map, not that every
room, strategy, timing or seed is beatable. Native Windows and subjective audio/
fear are outside this headless QA evidence. The primary agent owns the broader
regression wrapper and final matched 60-run comparison; consult its retained
log and the Phase 4B report for those final results.
