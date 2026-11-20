# Procedural Nightmare Maps V2.3 fair start review

Open the V2 overview with **M** before claiming a room in a Hard or Hell
Campaign. Click a vacant room to see its walk and Hunter travel estimates.
An estimated Hunter travel time of 10 seconds or less adds the amber
**Fast Hunter Route** warning. Travel is measured from spawn and assumes
the Hunter chooses that room first. The time of the first hit also depends
on the Hunter's windup and route.

The Hunter retains V2.2 productive sieges and defense-aware rerouting.
After a defensive diversion, the next siege comparison keeps the last
defended door's observed breach time as a floor. It still accounts for
travel and exposure when scoring that route. The floor stops applying if
the door has lost at least one current strike's worth of HP since the
departure. The decision can still favor a different reachable door.
This memory lives only in the Hard/Hell V2 Campaign first-form Hunter and
uses existing damage, repair, and route thresholds. Standard, Endless,
fixed and V1 maps retain their existing behavior and saves.

## Hell Labyrinth 10358, Room 2

The walked replays enter the room at 2.40s and start sleeping at 3.00s.
The map estimates seven seconds for a first Hunter approach. The player
starts with 25 Gold and zero Electricity. Preparation ends at 40s,
the first encounter is at 46.20s and the first strike is at 48.00s on the
ordinary openings. Early balanced and turret-first plans lose. Saving
straight through to Bed 3 or buying Bed 2 and covering the approach before
upgrading the door both win through normal transactions. In the first
policy, Bed 3 is paid at 31.05s, Door 2 at 36.45s, and the first of three
early Needles at 39.15s. At first strike the room has 267 door HP, about
23 Gold, and zero Electricity. Its first Needle covers 20 of 22 sampled approach points within 640 world
units of the door. It pays for its first repair at 50.85s. The long fight ends at 435.60s with 3,871 direct player damage to the Hunter.

Early Dynamo and door-first losses show the risk of committing capital too
soon, even when both plans can afford some repairs. The door-first plan
wins if the harness begins beside the bed, then loses after the ordinary
walk. The separate earned Gold Crate and Battery replay also wins. This
evidence supports keeping the opening route, economy, geometry, timing
and range rules.

[Outcome audit, including all changed winners and the three V2.2 reversals](evidence/nightmare-maps-v23/outcomes.md) ·
[Match receipts and reproduction](evidence/nightmare-maps-v23/matches/) ·
[Native Godot captures](evidence/nightmare-maps-v23/visuals/) ·
[Active combat benchmark](evidence/nightmare-maps-v23/performance/) ·
[Regression logs](evidence/nightmare-maps-v23/regressions/) ·
[Windows playtest instructions](FAIR_START_WINDOWS_PLAYTEST.md)
