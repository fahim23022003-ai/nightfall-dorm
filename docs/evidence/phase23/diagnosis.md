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

## Corrections verified on the preview path

The ordinary Story scorer charges for the portion of each reachable AStar approach inside existing weapon ranges. It reuses the paths returned by the distance query. The predicted damage uses the weapon's current stats and elemental matchup. The estimate uses the graph's normal route. An actual approach may take a bounded alternative lane, and a moving target may leave range before a shot lands. Estimates never generate damage.

At contact, the observer starts a fresh window. It counts actual main-Hunter damage at the selected door, including spells, after the model applies mitigation. A paid door tier adds capacity once. The observer subtracts that capacity gain when estimating recurring repair. A funded station on an intact door can now deter an approach. A repair erasing an entire window can earn a switch if there is a materially better route. The original two-hit finish rule, archetype commitment windows, seeded choice among comparable options and dedicated Reaper decisions still apply.

After a completed Hall visit that interrupted movement, the previous destination competes again under the same memory penalty as other recent selections. On the Phase 22.1 Normal L6 Zigzag seed 2717961, Room 6 was selected at 236.70s, the Hunter retreated to the west Hall at 247.20s, finished healing at 265.20s and then excluded Room 6 before scoring the options. Teammates killed the Hunter at 294.45s while the passive player remained untouched. In the final candidate it returned to Room 6, landed 150 door damage, and the passive player lost at 286.35s.

In a controlled matched layout all six Hunters selected the same favorable first door. Their estimated approach costs and minimum siege commitments differed. The existing Hard commitment windows ranged from 11.2s for the Ravager to 22.4s for the Crusher. A weapon covering only transit increased risk for all six. Swapping the human and an NPC with equal physical defenses, gear and inactive inventory produced identical candidate scores and choices. [Six-archetype decision receipts](decisions.json)
