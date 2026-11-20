# Full Room Grid preview

The grid preview builds on Phase 14F at `6d96a5f`. On Windows,
**Play Visual Preview.cmd** enables the grid and the Phase 14F visuals with
a dedicated test profile. **Play Reference Visuals.cmd** opens the original
visuals and placement flow with the previous test profile.

## Build and move

Claim an empty room, then use **E** at the bed. Press **B**, choose a machine,
and point inside your room. The mouse snaps to a 16-unit floor grid. Green
marks a legal placement and red shows the blocking reason. Press **Q** to
turn the footprint clockwise, or **Esc** to cancel. **P** shows the floor plan.
Select an installed machine and press **V** to reposition it during
preparation or Endless intermission. **Z** undoes the last safe move within
the same window. A move keeps the machine’s identity, upgrades, paid
investment and cooldown.

In the desktop preview, player Campaign and Endless rooms use all available
floor from the start. Endless starts with the former full-size player floor
at no charge. The doorway, bed and furniture retain their established
positions. Placement checks cover walls, furniture, the access lane, other
footprints and active characters. The model uses the existing movement,
targeting and paid transaction paths. Placed machines retain their established
traversal behavior. A directional floor notch indicates orientation on the
upright oblique artwork and turret barrels continue to track targets.

NPCs, the tutorial and authored Practice and Challenge layouts use their
existing rules. The regular launch also retains the previous placement flow.
The feature flag for testing the Godot project is `NIGHTFALL_FULL_ROOM_GRID=1`.

## Saved rooms

Older Endless checkpoints load under their original rules first. The preview
then tries a deterministic placement of every old machine on the complete
floor. A successful migration keeps the machine IDs, paid upgrades,
specializations, refunds, wallets and current run state. It records the original
and new positions of moved machines. If the complete layout cannot fit within
the migration search budget, the same checkpoint resumes with the old
placement system.

Grid saves record the orientation and physical anchor. The current build can
read them with the flag disabled. Use the separate launcher profiles to keep
the two test histories distinct. For a migration playtest, copy an old test
profile into the grid test profile with the game closed and keep the original.

[Windows playtest checklist](PHASE_14_FULL_ROOM_GRID_WINDOWS_CHECKLIST.md)
