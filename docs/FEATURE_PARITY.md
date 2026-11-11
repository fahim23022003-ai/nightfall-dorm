# Feature-by-feature parity checklist

Reference confidence for all original-game comparisons is **UNVERIFIED**. The requested reference pages were blocked by the cloud proxy. See [GAMEPLAY_REFERENCE.md](GAMEPLAY_REFERENCE.md) for access evidence. Implementation review below concerns the user's requested Nightfall Dorm contract, not proof of exact Haunted Dorm equivalence.

| Feature | Implementation status | Reviewed behavior and evidence | Haunted Dorm parity |
| --- | --- | --- | --- |
| Room selection | IMPLEMENTED | Six rooms, corridor movement/collision, free-room checks, claim and bed proximity; deterministic room-selection tests | UNVERIFIED |
| Sleeping economy | IMPLEMENTED | `RoomState.income_rate()` returns zero unless alive and sleeping; occupied-bed income tested | UNVERIFIED |
| Gold progression | IMPLEMENTED | Catalog bed rates/costs, higher levels, deductions, prerequisites; upgrade/resource tests | UNVERIFIED |
| Door defense | IMPLEMENTED | HP/max HP, attack damage, upgrade durability, manual/automatic repairs, intact-door protection, breach tests. Sleeping auto-locks door | UNVERIFIED |
| Upgrade progression | IMPLEMENTED | Separate gold/electricity checks, level caps, prerequisites, failed purchases preserve resources; deterministic tests | UNVERIFIED |
| Turrets | IMPLEMENTED | Two turret types, distance checks, cooldowns, actual hunter damage, upgrades and relay multiplier; range/cooldown/damage tests | UNVERIFIED |
| Electricity | IMPLEMENTED | Dynamo rate and independent balance, advanced purchase requirements; generation/spending tests | UNVERIFIED |
| Hunter AI | IMPLEMENTED | Catalog-configured growth/stats; DORMANT/SEEK/MOVE/ATTACK/BREACH/EXIT/DEAD FSM, corridor waypoints, occupied-room scoring, growth and retargeting; navigation/attack tests | UNVERIFIED |
| Survivor bots | IMPLEMENTED | Five bots claim vacant rooms, visibly approach their beds from their assigned doorways, then close doors, sleep, earn and spend on beds, doors, buildings and repairs. Gunner/engineer/economist/guard priorities differ. Autonomous behavior tested; initial corridor arrival is simplified to spawning at the assigned doorway | UNVERIFIED |
| Combat | IMPLEMENTED | Visible attack lines and door/hunter flash in renderer; model damage, door protection, elimination and support effects tested. Visual legibility is a separate audit | UNVERIFIED |
| Victory and defeat | IMPLEMENTED | Hunter death wins, breach/player elimination loses; deterministic tests and fixed-seed simulations reach both outcomes | UNVERIFIED |
| Overall match pacing | PARTIAL | 30-second preparation configurable. Final 12 seed/strategy combinations resolved in 46.1–81.7 seconds; 11 wins/1 loss. Passive player won 2/3 tested seeds through bot defenses; balance is an original first pass | UNVERIFIED |
| Six building functions | IMPLEMENTED | Needle turret, Arc turret, Dynamo, Repair station, Dream amplifier, Target relay each has a real effect and upgrade calculation; all six effects covered by tests | UNVERIFIED |
| Menu and controls | IMPLEMENTED | Start/how-to/settings/exit plus movement, interaction, tile selection, pause, result/restart/menu paths in scene scripts. See QA report for final scene results | Not a parity claim |

## Evidence scope

Reviewed production sources: `scripts/catalog.gd`, `room_state.gd`, `match_model.gd`, `hunter_state.gd`, `bot_ai.gd`, `game.gd`, and `interface.gd`.

Final executed regression evidence: [raw console log](evidence/qa-final.log), with 125 gameplay assertions and 11 scene checks passing, plus 12 deterministic simulations (11 victories, one defeat, zero unresolved). The final implementation includes visible bot door-to-bed approach, hunter EXIT routing through breached doorways, nonoverlapping bed/build positions, visible upgrade costs and the corrected sound slider. [QA_REPORT.md](QA_REPORT.md) records final command outputs and scope.
