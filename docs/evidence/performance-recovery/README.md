# Emergency performance preview
Matched Linux Godot 4.6.3 runs use llvmpipe, 1280×720, the same legal 24 machines and a live Stalker on the same V3 map. These samples isolate renderer cost using the prior footprint version in both builds. The visual changes are specific to Low, except offscreen machine culling, which also applies to Standard.

| Run | Median frame ms | p95 ms | Median draw calls |
| --- | ---: | ---: | ---: |
| d65de44 | 36.72 | 46.30 | 336 |
| Optimized Low | 34.68 | 44.39 | 236 |
| Optimized Low repeat | 33.98 | 39.79 | 236 |

The three runs recorded five launches, six Hunter strikes and 870.209 Hunter HP loss. Each finished with zero benchmark assertion failures. Simplifying decorative work alone reduced draw calls but did not improve frame time in its first intermediate sample. The final pass also removed the second floor draw in each visible generated room strip. Low retains the gun, flight path, impact, damage numbers and articulated models. The optimized launcher requests a 960×540 window to reduce pixel workload further. The 1280×720 measurements above do not establish the owner's Windows frame rate or the P0 root cause.

[Before](before.png) · [After](final.png) · [Playtest and F10 diagnostic](../../BUILDING_SCALE.md)
