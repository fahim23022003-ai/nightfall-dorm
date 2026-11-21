# Phase 23A · Story target decisions

Baseline `3f9ec286d6f7006b85a9c0b4ee64b602b410738c`, Godot 4.6.3. The Phase 22.1 launcher enables Living Dorm, Player First, close-quarters procedural V2 and Story chapter encounters. Ordinary Story Hunters already use HunterSiegeStrategy and seeded Living Dorm choices in all three difficulties. The separate uses_tactical_sieges gate is false on Normal. Boss combat, tutorials, fixed maps and Endless have independent eligibility.

A controlled Normal opening used Story seed base 48031, an occupied door, a funded L1 Repair Station and a single physical strike. This setup measures the decision code, not match outcomes.

| Observation | Baseline |
| --- | ---: |
| Actual HP removed by a 20-point requested strike | 15.3147 |
| HP counted toward the Hunter's repair assessment | 0 |
| Estimated target cost at full HP, funded station | 7.1875 |
| Estimated cost after 0.01 HP damage, same station | 10.1465 |
| Recognized breach delay after all 40 landed HP were restored in 15 s | 0 |

The strike counter used the Hard/Hell-only gate. The predictor used immediate station output, which correctly idles when the door is full but misrepresents the next siege. A completely repaired attack window was discarded. Tactical exposure was computed only at the door, so a gun covering the corridor but out of range of the door had no bearing on approach choice. Smoke could change the real movement target without recording a corresponding tactical choice. These are observable mismatches between the decision inputs and the rules. There is no equivalent evidence here supporting changes to Hunter HP, ally damage, prices or rewards.
