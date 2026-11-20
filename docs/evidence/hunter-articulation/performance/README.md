# Matched dense-room performance receipts

The before measurements use the archived `a71f3e3` production source and
the corrected fixture. The after measurements use the optimized preview.
All arms use the same renderer and matching gameplay digests. Each runs
150 measured active-combat frames after 24 warm-up frames with a legal
24-building room at 1280×720.

| Case | Before | After |
| --- | --- | --- |
| Stalker Standard | [Receipt](corrected-before/stalker-medium-1/benchmark.json) | [Receipt](final-after/stalker-medium-1/benchmark.json) |
| Stalker Low | [Receipt](corrected-before/stalker-low-1/benchmark.json) | [Receipt](final-after/stalker-low-1/benchmark.json) |
| Reaper Standard | [Receipt](corrected-before/reaper-medium-1/benchmark.json) | [Receipt](final-after/reaper-medium-1/benchmark.json) |
| Reaper Low | [Receipt](corrected-before/reaper-low-1/benchmark.json) | [Receipt](final-after/reaper-low-1/benchmark.json) |

Each folder includes the native rendered screenshot, active atlas path,
frame time and update samples, draw calls, engine memory counters and
capture log. The scene uses Mesa llvmpipe on Linux. This is distinct from
native Windows and Intel UHD performance.
[Measured results](../../../HUNTER_ARTICULATION.md#rendering-improvement)
