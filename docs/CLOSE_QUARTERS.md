# Nightfall Dorm Close Quarters Preview

Extract the Windows x64 ZIP and run **Play Close Quarters Preview.cmd**.
Start a fresh Story or Endless match to use version 3 geometry. Use
**Play Weapon Feedback Preview.cmd** to compare the previous generator
on a new match. Both launchers use the existing Living Nightmare profile.
Persisted layouts keep their original version when reopened.

The generator retains the ten V2 street plans and all five themes. The
room, original doorway spur, spawn points and Haunted Halls are held
fixed. Local 72-unit passages follow each exterior envelope, with an
8-unit gap from the outer wall wherever the original street does not
already meet it. Actor clearance leaves 48 units for survivor movement.
Recesses within irregular footprints retain their original shape. Each
passage joins the original street at connected nodes. Where a back street
exists it also connects to the opposite side.

The original camera scale and bounds policy remain in use. Compare with
the same room, zoom and seed. The new floors and lights follow saved
navigation surfaces. No changes were made to damage, health or movement
speed. Native Windows and Intel UHD tests require the target device.

## Matched results

- Across 200 layouts and 20,805 exterior wall samples, median floor gap
  fell from 156 to 8 units. The p95 fell from at least 400 to 8 units.
  The ray metric starts at sampled occupied exterior walls and caps at
  400. It excludes interior recesses. All 25,351 structural assertions
  passed, including both actor clearances on encoded lanes, approach and
  Hall reachability, seed determinism and versioned JSON round trips.
- All 35 Room Rush pairs started at identical attempt spawns and reached
  all five physical claims. Median fifth claim was 40.25 → 38.75 seconds,
  p95 remained 60.25 seconds, and the original Spine seed 8649 remained
  at 50.00 seconds. Median NPC travel fell from 2,315 to 2,275 units.
  Player and NPC speed budgets are unchanged.
- All 70 Story runs settled and reopened. Wins went 23/35 → 22/35.
  Hard and Hell counts were unchanged. In the Standard Branching case,
  the same spawn and Room 4 remained in use, but the room fell at 210.60
  seconds whereas the baseline killed the Hunter at 234.15 seconds.
  The preview Hunter had 528.92 HP left. Hall visits totaled 16 per arm.
- In Hell Hospital Labyrinth seed 10358 Room 2, the first door strike
  moved from 48.00 to 47.10 seconds. Both previous item-free strategies,
  saving for Bed 3 and building early crossfire, won again. The player
  reached bed in 3.00 seconds in both arms. The ordinary approach-fire
  and Frost plans still lost. Standard and Hard Bed 3 also won in both
  arms. These scripted policies cannot establish human difficulty.

[Model receipts and regressions](evidence/phase18/model/) · [Windows package receipt](evidence/phase18/windows/)

## Gameplay and performance

The same Hospital Labyrinth viewport at the same zoom changed from
62.4% to 42.1% uncovered in the sampled area. The approach footage shows
the Hunter walking alongside the wall, turning and striking the door.
The recordings also show Room Rush and a full Haunted Hall recovery and
return. [Native footage, matched views and measurements](evidence/close-quarters/native/)

Six native Linux llvmpipe pairs used 24, 40 and 60 legal machines in
Standard and Low. Their combat digests matched. At 60 machines, the
Standard median/p95 went from 79.41/98.44 to 83.20/117.20 ms. Low went
from 41.91/52.84 to 44.07/61.62 ms. The preview therefore remains opt-in.
Some recesses and the larger gaps between macro neighborhoods remain
intentional. [Raw results](evidence/close-quarters/native/performance/paired.json)
