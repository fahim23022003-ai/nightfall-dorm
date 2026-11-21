# Close Quarters native comparison

The reference uses `767b151` with V2. The preview uses the production files
at `3b27f96` with the Close Quarters flag and V3. Both use Godot 4.6.3
OpenGL on Mesa llvmpipe in the Linux VM. Native Windows and Intel UHD
measurements remain pending.

## Same Hospital Labyrinth, same view scale

The paired images use seed **10358**, room **2**, a fixed 0.88 camera scale,
and the same relative room focus. The native room camera also selected
1.112128 in both versions. The room bounds remained 400 × 352 world units.
The same 790 × 477 logical-pixel HUD-free rectangle was sampled every six
pixels against actual corridor and room floor geometry. Uncovered sample
count fell from **6,590 to 4,445 of 10,560** (62.4% → 42.1%). This measures
the selected viewport region. Uncovered space includes intentional exterior
voids. It is separate from map-wide collision or walkability coverage.
[Before](before-hell/matched-focus.png) · [After](after-hell/matched-focus.png)

Of 91 outward rays from the actual room walls, the median distance before a
corridor was **158 → 10 world units**. The 95th percentile was **256 → 152**;
rays were capped at 256. The number of rays reaching a corridor within 16
units increased from **2 to 60**. Floor sampling and wall rays use the
authoritative map rectangles. The approach clip separately verifies legal
movement on the new surfaces. [Before receipt](before-hell/capture.json) ·
[After receipt](after-hell/capture.json)

- Normal, same camera scale. [Before](before-standard/matched-focus.png) · [After](after-standard/matched-focus.png)
- Hard, same camera scale. [Before](before-hard/matched-focus.png) · [After](after-hard/matched-focus.png)
- Full map overview. [Before](before-hell/overview.png) · [After](after-hell/overview.png)
- Default room camera. [Before 1280×720](before-hell/normal-focus.png) · [After 1280×720](after-hell/normal-focus.png) · [After 960×540](after-540/normal-focus.png) · [Actual 960×540 door strike](after-approach-540/real-door-contact.png)

## Continuous Godot gameplay

These are scripted native game runs with staged starting positions and
clocks where documented. Capture uses Movie Maker at 24 fps playback.
The approach camera is the normal gameplay focus. The Hall uses the
game's Hunter-follow camera.

- The two approach clips start at different legal corridor nodes on the same seed. The preview captured 36 visible, moving samples within 60 units of a wall, then a real turn onto the room portal and a door strike that lowered HP from 150 to 131.142. The script checked per-step legal visibility and speed during the approach. [V2 approach](before-approach/gameplay.mp4) · [V3 approach](after-approach/gameplay.mp4) · [V3 receipt](after-approach/capture.json)
- Room Rush starts all six bodies at the same exterior point. The scripted human travels into the nearby room and claims it at 0.125 s. Two NPCs physically claim in this 15-second clip, at 9.375 and 11.792 s. [Room Rush](after-rush/gameplay.mp4) · [Receipt](after-rush/capture.json)
- A prepared low-HP Stalker satisfies the existing retreat policy and takes the route to the East Hall. It starts recovery after 6.50 s and finishes at 14.50 s. HP rises from 2,132.10 to 3,198.15. At 15.96 s the Hunter has left the Hall center and resumed its combat route. [Hall retreat and return](after-hall/gameplay.mp4) · [Receipt](after-hall/capture.json)

## Dense gameplay timing

The two presets covered 24, 40 and 60 paid legal building placements
in the same Cursed Mansion siege. Every building center was on screen
at the start and end. Each case used 24 warm-up steps, then 120 sampled
frames at a fixed 1/24-second model step. The 12 runs were interleaved
on CPUs 0–3 with two llvmpipe workers. All six pairs matched the initial
and final gameplay hashes and recorded actual attacks, projectile
launches and damage. Nav query medians use the same six spawn/Hall
endpoints to the actual door, repeated five times.

| Buildings | Preset | Frame median ms | Frame p95 ms | Route query median ms |
| ---: | --- | ---: | ---: | ---: |
| 24 | Standard | 53.21 → 60.13 | 70.94 → 70.44 | 0.330 → 0.583 |
| 24 | Low | 40.69 → 41.77 | 54.34 → 56.30 | 0.310 → 0.575 |
| 40 | Standard | 61.21 → 72.92 | 76.02 → 95.34 | 0.311 → 0.573 |
| 40 | Low | 37.99 → 40.81 | 50.30 → 53.47 | 0.339 → 0.580 |
| 60 | Standard | 79.41 → 83.19 | 98.44 → 117.20 | 0.331 → 0.559 |
| 60 | Low | 41.91 → 44.07 | 52.84 → 61.62 | 0.333 → 0.608 |

V3 raised all six measured median frame times. Low at 60 buildings
increased by 2.16 ms median and 8.78 ms p95. Standard at 40 and 60
buildings had the largest p95 increases. These CPU-pinned
software-rendered measurements do not establish native Windows timings.
[Raw paired timing](performance/paired.json)

## Reproduce

Copy the new tools into an archived reference checkout if one is used.
The harness opens an isolated test profile for each capture. Run the
following from the repository on a real or dummy X11 display.

```sh
python tools/phase18/run_capture.py /absolute/project /absolute/output views --version 3
python tools/phase18/run_capture.py /absolute/project /absolute/movie-output approach --version 3 --movie
taskset -c 0-3 python tools/phase18/run_capture.py /absolute/project /absolute/timing-output measure --version 3 --buildings 60 --quality low
```
