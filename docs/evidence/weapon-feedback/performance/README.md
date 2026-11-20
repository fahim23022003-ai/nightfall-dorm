# Live combat timing

Eight interleaved pairs ran in the native Godot 4.6.3 game scene at
1280×720 with Mesa llvmpipe on Linux. The dummy X11 runs used CPU affinity
0–3 and two llvmpipe render workers. The driver reported that V-Sync
could not be changed. The test renders 24 warm-up and 120 measured
updates at a fixed 1/24-second simulation step. Timings are wall time to
the rendered frame. Software rendering and host scheduling affect the
tails. Native Windows and Intel UHD were unavailable.

The same map, prepared siege, legal build positions and combat state
were used in every pair. `NIGHTFALL_WEAPON_FEEDBACK=0` uses the previous
presentation. `1` uses the new one. Geometry, launch and contact history,
HP, placements and wallet digests matched. The timed samples
recorded 37–42 shots and at most eight simultaneous in-flight projectiles.
The settings test separately aggregates a burst of 60 receipts.

| Machines | Standard median / p95 ms | Low median / p95 ms |
| --- | --- | --- |
| 10 | 43.50 / 55.20 → 43.18 / 55.41 | 38.32 / 47.72 → 35.70 / 46.95 |
| 24 | 54.05 / 65.22 → 52.81 / 69.17 | 46.16 / 60.24 → 47.12 / 67.03 |
| 40 | 61.40 / 73.11 → 62.20 / 75.53 | 51.99 / 61.97 → 52.39 / 69.48 |
| 60 | 82.68 / 105.75 → 77.21 / 103.53 | 59.19 / 73.23 → 57.97 / 75.23 |

At 60 machines on Low, the median game update went from 6.24 to 6.26 ms,
median draw calls from 587 to 581, engine static memory from 152.07 to
152.31 MiB and the renderer's estimated graphics memory from 117.07 to
117.31 MiB. Medians stayed within 1.3 ms at six of the eight settings
except for the 10 Low and 60 Standard decreases. Several p95 values
increased, including 40 Low by 7.51 ms. These runs demonstrate the cost
under this software workload and cannot establish a native FPS target.

[Paired summary](../paired-performance.json) · [Raw benchmark receipts](raw/) · [60 Standard before](60-standard-before.png) · [60 Standard after](60-standard-after.png) · [60 Low before](60-low-before.png) · [60 Low after](60-low-after.png)

For a local reproduction, start a real desktop Godot session and use a
separate `XDG_DATA_HOME`. Set the Phase 16, Living Nightmare, Survivor
Rebirth, Visual Rebirth, Full Room Grid and Procedural Maps V2 flags, and
run this once with weapon feedback at `0`, then with `1`. Replace `low`
with `medium` for Standard and choose `10`, `24`, `40` or `60`.

```sh
NIGHTFALL_PHASE16=1 NIGHTFALL_LIVING_NIGHTMARE=1 NIGHTFALL_SURVIVOR_REBIRTH=1 \
  NIGHTFALL_VISUAL_REBIRTH=1 NIGHTFALL_FULL_ROOM_GRID=1 NIGHTFALL_PROCEDURAL_MAPS_V2=1 \
  NIGHTFALL_WEAPON_FEEDBACK=1 godot --path . --resolution 1280x720 \
  --audio-driver Dummy --disable-vsync --script tools/weapon_feedback/capture.gd \
  -- /tmp/nightfall-weapon-bench low 60 mixed bench
```
