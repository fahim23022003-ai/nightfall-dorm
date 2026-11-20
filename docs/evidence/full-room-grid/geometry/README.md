# Room grid geometry verification

The focused model fixture covers all 30 authored map rooms and all six fixed-geometry legacy rooms. It checks the 15 building footprints in each quarter-turn, exact grid alignment, floor bounds, furniture and doorway exclusion, and valid occupancy beyond the old numbered slots. It pays for placements through the room's real purchase path using prepared wallets.

The expanded-layout matrix covers 342 combinations across the supported maps, starting expansion tiers and legacy expansion geometry. Each route connects the reserved doorway area to a bed approach and clears the cabinet and plant reservations.

The transaction scenarios exercise rotation and Undo, rejection for an active character, deterministic migration of paid structures, and complete rollback when a dense migration fails. The existing non-grid construction suite separately passed 1,397 checks. [Legacy verification log](legacy-spatial.log)

## Reproduce

```sh
godot --headless --path . --script res://tests/full_room_grid_geometry.gd
godot --headless --path . --script res://tests/spatial_construction.gd
```
