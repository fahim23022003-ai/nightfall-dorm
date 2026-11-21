# Emergency performance preview
Matched Linux Godot 4.6.3 runs use llvmpipe, 1280×720, the same legal 24 machines and a live Stalker on the same V3 map. These samples isolate renderer cost using the prior footprint version in both builds. The visual changes are specific to Low, except offscreen machine culling, which also applies to Standard.

| Run | Median frame ms | p95 ms | Median draw calls |
| --- | ---: | ---: | ---: |
| d65de44 | 36.72 | 46.30 | 336 |
| Optimized Low | 34.68 | 44.39 | 236 |
| Optimized Low repeat | 33.98 | 39.79 | 236 |

The three runs recorded five launches, six Hunter strikes and 870.209 Hunter HP loss. Each finished with zero benchmark assertion failures. Simplifying decorative work alone reduced draw calls but did not improve frame time in its first intermediate sample. The final pass also removed the second floor draw in each visible generated room strip. Low retains the gun, flight path, impact, damage numbers and articulated models. The optimized launcher requests a 960×540 window to reduce pixel workload further. The 1280×720 measurements above do not establish the owner's Windows frame rate or the P0 root cause.

[Before](before.png) · [After](final.png) · [Playtest and F10 diagnostic](../../BUILDING_SCALE.md)

In the separate legal seven-machine enlarged-grid fixture, Low measured
45.26/55.69 ms median/p95 at 1280×720 and 31.35/41.06 ms at 960×540.
Both runs fired five shots and removed 140 Hunter HP. This measures
resolution cost within the new build. The earlier Phase 18.1 practical
720p Low sample was faster at 37.57/45.40 ms. The tests were recorded in
different sessions, so practical 720p speedup has not been established.
Matched 24-machine p99 was 50.66 ms before and 46.89/43.13 ms afterward.
The cache stayed at 7.74 MiB of pixel payload. Godot static memory was
essentially unchanged and reported video memory rose by about 1.84 MiB.

Seven headless regression suites passed. A separate Linux diagnostics
probe verified default Low in a fresh isolated profile and produced a
local report with frame and stage statistics. Linux could not open the
report folder from the headless shell. Windows folder opening awaits playtest.

[Low combat clip](low-needle-combat.mp4) · [960×540 receipt](practical-960.json) ·
[1280×720 receipt](practical-1280.json) · [Regression logs](regressions/)

The Hunter draws an articulated pose through a batched triangle submission.
The directional textures are at most 512×676 and the rig cache holds at
most 16 atlases. They are not the first demonstrated bottleneck in these
samples. A 16-bit art conversion has not been applied. The practical Low
launcher, the diagnostic launcher and the prior preview launchers are
included in the ZIP. The package contains the source revision recorded in
the [Windows export receipt](windows-artifact.json).

## Phase comparison

The Phase 18.1 checkpoint was run with each feature bundle on the same
Linux host at 1280×720 Low. Phase 16 and Weapon Feedback share the same
V2 geometry and gameplay hashes. Close Quarters switches to V3. The
24-machine cases had identical shot, strike and health-loss totals.

| Bundle | Machines | Median / p95 (ms) | Median draw calls |
| --- | ---: | ---: | ---: |
| Phase 16 | 24 | 37.93 / 43.23 | 524 |
| + Weapon Feedback | 24 | 37.39 / 46.52 | 517 |
| + Close Quarters (cached) | 24 | 36.04 / 47.95 | 336 |
| Original footprints (V3 with cache) | 7 | 49.43 / 59.53 | 609 |
| Enlarged footprints (V3 with cache) | 7 | 51.06 / 67.11 | 609 |

The last two runs use a separate seven-machine fixture so both builds
can place the same machine mix legally. Each fired five shots and did
140 HP damage. Building Scale produced the largest measured p95 increase
in its pair, despite unchanged draw submissions. Weapon Feedback also
increased p95 in the equal-geometry pair while median improved slightly.
The earlier Phase 18 before/after comparison captured a dense Standard
p95 regression at corridor introduction. Its Phase 18.1 cache improved
that 60-machine Standard p95 substantially. These results establish
individual costs in these Linux workloads, and leave the cause of the
owner's much larger Windows lag open.

[Phase receipts](phase-comparison/) · [Original corridor report](../close-quarters/phase181/README.md)
