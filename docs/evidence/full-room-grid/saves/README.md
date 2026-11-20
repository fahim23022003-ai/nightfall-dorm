# Full-room grid save verification

Ordinary spatial checkpoints still use schema 2 and ruleset 5. Grid checkpoints use schema 3 and ruleset 6 with an explicit grid marker and a quarter-turn rotation on every placed building. A grid checkpoint restores its recorded layout and rotation without re-running the placement search. The grid preference applies to new rooms and migration from older rooms. A saved grid stays playable when the preference is switched off.

The save test starts from the repository's earned Endless wave 45 checkpoint. It exercises direct schema 1 migration and the same earned room re-encoded as schema 2. Both paths retain all 12 structures, selectors, instance identities, branches, cooldowns, spending, furniture anchors, door HP, RNG and NPC room state. The migrated room re-encodes, reloads with the preference off and continues to wave 46. The source checkpoint's hash is checked before and after.

A separate prepared profile uses normal model transactions to place 17 machines, including a building with a nonzero rotation. It completes a wave by actual turret fire and writes a profile through the regular checkpoint and backup flow. The reopened profile round-trips every encoded field. Malformed metadata, rotations and placements are rejected. Known damaged grid data can recover a compatible backup while preserving the damaged bytes. A deliberately impossible in-memory floor exercises failed-fit rollback without changing positions, funding, IDs or placement mode.

Run with Godot 4.6.3 from the repository root:

```sh
NIGHTFALL_FULL_ROOM_GRID=0 godot --headless --path . --script tests/full_room_grid_saves.gd
```

The test toggles the grid preference inside its own process and uses temporary profile copies. Related tests ran with the preference off.

| Gate | Passed | Failed |
| --- | ---: | ---: |
| [Grid migration, disk roundtrip and recovery](full_room_grid_saves.log) | 61 | 0 |
| [Endless replay](replay_endless.log) | 28,426 | 0 |
| [Legacy replay migration](replay_migration.log) | 190 | 0 |
| [Spatial saves and effects](spatial_saves_effects.log) | 179 | 0 |
