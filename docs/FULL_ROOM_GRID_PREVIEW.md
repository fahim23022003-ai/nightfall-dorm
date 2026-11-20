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

## Verification

- **11,274 geometry checks** cover all 30 authored rooms, six legacy rooms,
  342 expanded layouts, typed footprints, turns and path clearance. **727
  model checks** exercised paid placement, rotation, move, undo, upgrades,
  specialization and refunds. [Geometry](evidence/full-room-grid/geometry/README.md) · [Engine logs](evidence/full-room-grid/regressions/)
- **61 save checks** cover migration of the earned wave-45 profile,
  continuing into wave 46, a 17-building disk roundtrip, compatible backup
  recovery and failed-fit rollback. [Migration evidence](evidence/full-room-grid/saves/README.md)
- All **60 transaction cases** matched prices, upgrade debits and refunds
  across the checkpoint, fallback and grid preview. Six earned simulations
  retained their sampled outcomes, with different combat exposure possible
  when the grid opens new positions. [Economy and simulation QA](evidence/full-room-grid/qa/README.md)
- Nine 720p viewport captures and a 233-frame film show native input,
  rejection feedback, same-instance moves and 24 paid structures under
  live Phase 14F combat. **209 checks** passed. The urgent warning and door
  HP remain visible. Some dense placements cover secondary room-trait text.
  [Screenshots and video](evidence/full-room-grid/visuals/README.md)

| Matched 16 buildings, 720p | Checkpoint median / p95 | Grid median / p95 |
| --- | ---: | ---: |
| Standard | 43.82 / 54.73 ms | 41.56 / 56.57 ms |
| Low | 39.16 / 47.78 ms | 37.51 / 46.80 ms |

The 82-building stress fixture with the planning overlay open measured
67.36 / 78.46 ms on Standard and 65.30 / 80.36 ms on Low. These values are
software-rendered Mesa llvmpipe measurements at 1280×720. Native Windows,
Intel UHD frame rates and human playtest approval remain pending.

The Windows x64 ZIP was exported from source `90d4748`. ZIP CRC, PE x64
and embedded pack integrity passed. Linux Godot loaded the embedded pack
and passed **77 base**, **384 Preview** and **381 Reference** checks,
including all 248 cardinal assets. [Windows archive receipt and pack logs](evidence/full-room-grid/windows/)
