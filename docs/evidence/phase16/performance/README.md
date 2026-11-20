# Phase 16 dense siege timing

Eight before/after pairs used Godot 4.6.3 at 1280×720 with OpenGL
Compatibility and Mesa llvmpipe 25.0.7 on an AMD EPYC 9V74 cloud VM.
The processes were interleaved, one native viewport at a time, with CPU
affinity 0–3 and two llvmpipe render workers. A short separate Room Rush
process ran on CPU 4 during part of the suite. The dummy X11 display
reported that V-Sync could not be changed. Software wall timing remains
sensitive to host scheduling. Native Windows and Intel UHD performance
remain unverified.

Each case advanced 24 warm-up and 120 timed frames through the real
Game processing and render path, with a fixed 1/24-second simulation step.
The capture prepared the same level, funding, legal building purchases
and closed defended room on both sides. A 15-role build roster was filled
out with paid Decoy Beacons. All 24, 40 or 60 centers were on-screen
at the start and end. Stalker samples recorded five launches and six
strikes each. Reaper samples used a real transformation, then a staged
doorway approach for the normal phase-two scythe sequence. They recorded
five launches and one actual scythe impact, with simultaneous repair
absorbing the net door HP change. This fixture had at most one projectile
at a time. [Reproduction tools](../../../../tools/phase16/README.md)

| Scene | Wall median ms | Wall p95 ms | Game update median ms | Median draw calls |
| --- | ---: | ---: | ---: | ---: |
| Stalker 24 Standard | 61.16 → 53.03 | 80.67 → 77.99 | 5.33 → 3.17 | 548 → 550 |
| Stalker 24 Low | 50.37 → 39.42 | 60.44 → 42.82 | 5.24 → 3.07 | 541 → 524 |
| Stalker 40 Standard | 67.58 → 60.79 | 79.92 → 81.68 | 6.26 → 3.58 | 580 → 582 |
| Stalker 40 Low | 63.39 → 42.07 | 85.11 → 52.78 | 6.47 → 3.84 | 573 → 525 |
| Stalker 60 Standard | 81.70 → 79.44 | 100.54 → 110.50 | 7.72 → 4.81 | 620 → 622 |
| Stalker 60 Low | 74.13 → 43.18 | 97.39 → 54.12 | 7.66 → 4.40 | 613 → 525 |
| Reaper 60 Standard | 80.51 → 79.92 | 109.81 → 108.45 | 7.71 → 4.33 | 660 → 661 |
| Reaper 60 Low | 74.01 → 41.71 | 103.12 → 52.06 | 7.76 → 4.29 | 618 → 527.5 |

Every pair matched geometry and initial and final gameplay SHA-256,
including room placements, wallets, RNG, Hunter damage, projectiles and
event history. Framebuffer SHA-256 changed with the preview visuals.
Standard p95 increased in two Stalker scenes. Every sampled median
remained above the 16.7 ms budget for 60 FPS. [Raw comparison](paired-comparison.json)

The separately instrumented Stalker 60 Low diagnostic measured median
UI update at 4.091 → 0.695 ms and its action list at 3.264 → 0.046 ms.
The world draw CPU span was 3.252 → 3.551 ms, including architecture
at 2.041 → 2.209 and building tiles at 1.125 → 1.231 ms. Rig submission
measured 0.126 → 0.131 ms. Weapon targeting measured 0.019 → 0.021 ms
at the tested projectile count. Diagnostic scopes are inclusive where
nested, and these two processes used different CPU affinities. The main
paired table uses uninstrumented measurements.
[Baseline spans](cpu-before/benchmark.json) · [Preview spans](cpu-after/benchmark.json)

The reference project is archived from `07b459be3ed0e9b0721464e73c2927f77e8cd9cd`.
The candidate was copied before timing, with `NIGHTFALL_PHASE16=1`.
The snapshot's base HEAD was `3615dcd`. The production file hashes also
record its in-progress changes at capture time.
[Candidate file manifest](candidate-source.sha256)

[Stalker 60 Low before](before/stalker-60-low/final-720.png) · [Stalker 60 Low after](after/stalker-60-low/final-720.png) · [Reaper 60 Low before](before/reaper-60-low/final-720.png) · [Reaper 60 Low after](after/reaper-60-low/final-720.png)
