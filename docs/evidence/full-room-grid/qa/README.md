# Full Room Grid gameplay and render QA

The comparison checkpoint is `6d96a5f2254f788641f5bc100ca63520adf2a362`. The final render series used the game scripts in `90d4748`.

## Earned model cases

Six fixed-seed cases use current balance and the same purchase priorities. Standard, Hard and Hell each appear in Campaign and Endless. The harness claims a selected room, stages the player at their bed and uses the real model actions to sleep, build and upgrade. The player starts with the normal wallet and has no perks, items, injected resources, or advanced waves. Simulations stop at a Campaign result, first Endless wave clear, defeat, or the 320-second bound.

Grid-off matched the checkpoint exactly for all tracked simulation fields apart from wall-clock timing. Both variants recorded two Campaign victories, one Campaign defeat and three first-wave Endless clears. Grid-on changes legal weapon placements and removes paid expansion, so combat and resource spending differed in some individual cases. Both currencies stayed finite and nonnegative. The full ledger matched both wallets every sampled tick within 0.011. All six grid cases had zero Hunter navigation recoveries. The JSON records the legacy `tile_count()` accessor for context. The grid does not use that accessor as a construction limit. The small fixed-seed sample checks rule integrity and representative outcomes.

## Transactions

A separate prepared-wallet fixture tests each of the 15 placeable building roles in Campaign and Endless with both legacy v1 and current v2 balance. It compares quoted prices, charged gold and Electricity, actual Level 2 upgrade debit, invested cost, and credited sale refunds. Occupied geometry and repeated sale attempts must preserve the wallet. The fixture pays for a Dynamo prerequisite where required. These transactions isolate unit costs from earning and survival times. All 60 cases produced identical amounts across the checkpoint, grid-off and grid-on, with 725 checks passing in each configuration.

## Rendering

Timing uses real Godot Compatibility frames at 1280×720. Both matched cases stage the same 15 Level 10 roles and a separate Level 1 Needle. The Full Room Grid uses different valid positions to fit the typed footprints. Both configurations use prepared resources and the same frozen seed-67 Endless room. The optional stress case adds paid Level 1 Decoys beyond the former 16-building limit and leaves the planning overlay visible. Stress measures added buildings and the overlay together. The harness updates presentation with 30 warm-up and 240 timed frames, then saves a screenshot outside the timed measurement.

| Matched 16 structures | Checkpoint median / p95 | Grid median / p95 |
| --- | ---: | ---: |
| Standard | 43.82 / 54.73 ms | 41.56 / 56.57 ms |
| Low | 39.16 / 47.78 ms | 37.51 / 46.80 ms |

The separate 82-structure stress room with the planning overlay open measured 67.36 / 78.46 ms in Standard and 65.30 / 80.36 ms in Low. Those are median / p95 frame times. Godot estimated 147.04 MB rendering memory at the checkpoint, 153.53 MB with the matched grid and 153.63 MB in the stress case. The first set of measurements overlapped two CPU-heavy test processes and a route correction. The table uses a later serial run on unchanged production scripts.

The display is Linux Xorg dummy with Mesa llvmpipe. Native Windows and Intel UHD timing remains open.

## Reproduce

Use a fresh profile path per run. Set `NIGHTFALL_FULL_ROOM_GRID=0` for fallback or `1` for the opt-in feature. The output paths must be absolute.

```sh
export XDG_DATA_HOME="$(mktemp -d)"
godot --headless --path . --audio-driver Dummy \
  -s tools/full_room_grid/check_full_room_match.gd -- /tmp/grid-earned.json
godot --headless --path . --audio-driver Dummy \
  -s tools/full_room_grid/check_grid_transactions.gd -- /tmp/grid-transactions.json
NIGHTFALL_VISUAL_REBIRTH=1 godot --path . --resolution 1280x720 --audio-driver Dummy --disable-vsync \
  -s tools/full_room_grid/measure_grid_density.gd -- /tmp/grid-standard medium matched
```

Use `low` for Low and `stress` to measure the larger opt-in layout. Extract a clean checkpoint tree with `git archive`, import it, point `--path` to the archive and pass the absolute path to the same harness. Keep all render timing processes serial.
