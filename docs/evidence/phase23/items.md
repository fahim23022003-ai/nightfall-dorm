# Phase 23 · Item counterplay

A new Normal Story profile earned 39 RM Cash by winning Level 1 in 336.1 seconds. The human policy dealt 2,232 damage and five teammates dealt 6,287.9. Each Hard comparison started from a copy of that saved wallet, used the same Story seed 434184, physically entered Room 4 on attempt 2, and equipped either zero items or one Shop purchase. The policy spent its earned resources at most once per 1.5 seconds. All nine matches reached production settlement. All 45 NPC final wallets reconciled against their Gold and Electricity ledgers.

| Separate matched Hard pairs | Measured effect |
|---|---|
| Repair, 18 RM | Restored 172.5 HP and saved 48 Gold in total spending. Both sides lost at 367.2s. |
| Gold, 16 RM | The 150 Gold advanced the first paid Dynamo from 139.9s to 55.8s. Both sides lost at 367.2s. |
| Battery, 16 RM | Granted 80 Electricity. Both sides spent 66 Electricity, dealt 2,538 player damage and lost at 367.2s. Power was not the constraint on this opening. |
| Radar, 12 RM | An approach-aware policy held back its door purchase until Radar identified its own room or the door took damage. Activation at 48.3s expired well before first damage at 343.8s. Both sides lost at 350.8s. |

An independent world, selected before inspecting its outcomes, used Story seed 671109. A first Normal defeat earned 14 RM and a subsequent Normal victory earned 40 RM. In Hard Room 6, the policy without an item lost at 217.2s. A Battery extended survival to 394.2s and raised actual player damage from 3,276 to 5,040. A Gold Crate advanced the Dynamo from 105.1s to 42.0s and extended survival to 368.9s. A Repair Kit restored 75 HP. Radar brought the paid door upgrade forward from 61.5s to 51.0s, ahead of the first blow at 60.7s. Both the Repair and Radar pairs retained the same final outcome and duration. All eight item pairs across both seeds ended in defeat on both arms.

A separate imminent-approach fixture made the same Radar policy respond to live information and pay for a door upgrade before contact. Door HP rose from 172.5 to 345. Radar supplied information and the player supplied the Gold.

## Matched combat windows

Hunter location, threat timing and low door HP were arranged to isolate each opportunity. The four Shop items used actual purchases. For higher rarities the fixture supplied one unit of diagnostic stock, then used normal equip, validation, consumption and combat. Results here measure item function over a short window.

| Item | Without item | With item |
|---|---:|---:|
| Shield · door HP after two seconds | 144.59 | 172.50 |
| Decoy · door HP after two seconds | 144.59 | 172.50 |
| Smoke · door HP after two seconds | 144.59 | 172.50, Hunter redirected |
| Time Freeze · door HP after two seconds | 144.59 | 172.50 |
| Frost · displacement over 1.5 seconds | 106.3 units | 63.8 units |
| Overdrive · actual Needle damage in ten seconds | 99 from 12 launches | 135 from 16 launches |
| Guardian Heart · door HP after lethal hit | 0 | 25.875 with a temporary shield |
| Reaper Seal · door HP after telegraphed Scythe Slash | 137.4 | 172.5, cast interrupted |

Two further windows used the actual north Hall retreat, route and recovery channel. Ghost Decoy interrupted healing and consumed one stock. Shadow Smoke consumed one stock, left the Hunter in the channel and allowed the next 0.05-second heal from 2,446.625 to 2,454.213 HP. Smoke remains a room-priority tool during recovery. The existing Decoy diversion remains a deliberate counter.

Across 19 complete Story matches, all 95 NPC wallets reconciled. The AI teammates bought from earned budgets. Normal used the established investment sequence. Hard and Hell reacted to sieges, favored physical coverage near their own doors and varied counters by profile. Only the human received equipped rank bonuses. The two worlds produced different returns for the same opening purchases. The sample covers early Story and does not estimate endgame item win rates.

Run from the project directory with Godot 4.6.3. This uses temporary profiles and the Windows preview's gameplay flags.

```sh
godot --headless --path . --script res://tests/phase23_items.gd -- /tmp/nightfall-phase23-items.json
godot --headless --path . --script res://tests/phase23_items.gd -- /tmp/nightfall-phase23-items-independent.json --independent
```

The two runs passed 161 and 91 assertions. Four existing Godot suites passed with 11,203 item checks, 7,988 advanced-item checks, 27 combination checks and 221 chapter encounter checks.

[Primary receipts and per-room contributions](items.json) · [Independent world receipts](items-independent.json)
